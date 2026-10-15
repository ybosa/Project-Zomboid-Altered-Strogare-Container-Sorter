require "ISUI/ISContextMenu"

ZCSMP = ZCSMP or {}
ZCSMP.Client = ZCSMP.Client or {}

local function log(message)
    print("[ZCSMP][CLIENT] " .. tostring(message or "nil"))
end

local function getPlayer(playerIndex)
    return getSpecificPlayer and getSpecificPlayer(playerIndex or 0) or nil
end

local function say(playerIndex, message)
    local playerObj = getPlayer(playerIndex)
    if playerObj and playerObj.Say then playerObj:Say(tostring(message or "")) else log(message) end
end

local function getFirstContainer(worldObjects)
    if not worldObjects or not ZCSMP.Storage then return nil end
    for _, object in ipairs(worldObjects) do
        local container = ZCSMP.Storage.GetContainerFromObject(object)
        if container then return container end
        if type(object) == "table" then
            container = ZCSMP.Storage.GetContainerFromObject(object.object or object.obj)
            if container then return container end
        end
    end
    return nil
end

local function sendCommand(playerIndex, command, args)
    local playerObj = getPlayer(playerIndex)
    if isClient and isClient() then
        sendClientCommand(playerObj, ZCSMP.Config.CommandModule, command, args or {})
    elseif ZCSMP.Server and ZCSMP.Server.HandleCommand then
        return ZCSMP.Server.HandleCommand(command, playerObj, args or {})
    elseif command == "SortFromContainer" and ZCSMP.Storage and ZCSMP.Storage.SortFromContainer and ZCSMP.Storage.ResolveContainerRef then
        local container = ZCSMP.Storage.ResolveContainerRef((args or {}).ref)
        return ZCSMP.Storage.SortFromContainer(playerObj, container)
    elseif command == "AssignCategory" and ZCSMP.Storage and ZCSMP.Storage.ResolveContainerRef then
        local container = ZCSMP.Storage.ResolveContainerRef((args or {}).ref)
        if container then
            return { ok = ZCSMP.Storage.AssignCategory(container, (args or {}).category) }
        end
    elseif command == "ClearCategory" and ZCSMP.Storage and ZCSMP.Storage.ResolveContainerRef then
        local container = ZCSMP.Storage.ResolveContainerRef((args or {}).ref)
        if container then
            return { ok = ZCSMP.Storage.ClearCategory(container) }
        end
    elseif command == "ShowNearbyCategories" and ZCSMP.Storage and ZCSMP.Storage.GetNearbyCategorySummary then
        return ZCSMP.Storage.GetNearbyCategorySummary(playerObj)
    end
end

local function assignCategory(container, category, playerIndex)
    local ref = ZCSMP.Storage.GetContainerRef(container)
    if not ref then
        say(playerIndex, ZCSMP.T("assignFailed"))
        return
    end
    sendCommand(playerIndex or 0, "AssignCategory", { ref = ref, category = category })
    say(playerIndex or 0, string.format(ZCSMP.T("assigned"), tostring(category)))
end

local function saySortDetails(playerIndex, result)
    if not result then return end
    if result.missingCategoriesText then say(playerIndex or 0, string.format(ZCSMP.T("sortDetailsMissing"), result.missingCategoriesText)) end
    if result.fullCategoriesText then say(playerIndex or 0, string.format(ZCSMP.T("sortDetailsFull"), result.fullCategoriesText)) end
    if result.failedCategoriesText then say(playerIndex or 0, string.format(ZCSMP.T("sortDetailsFailed"), result.failedCategoriesText)) end
end

local function saySortResult(playerIndex, result)
    if result then
        local key = result.limited and "sortLimited" or "sortDone"
        say(playerIndex or 0, string.format(ZCSMP.T(key), result.processed or 0, result.moved or 0, result.missingTarget or 0, result.fullDestination or 0, result.failed or 0, result.other or 0))
        saySortDetails(playerIndex or 0, result)
    else
        say(playerIndex or 0, ZCSMP.T("sortRequested"))
    end
end

local function clearCategory(container, playerIndex)
    local ref = ZCSMP.Storage.GetContainerRef(container)
    if not ref then
        say(playerIndex, ZCSMP.T("clearFailed"))
        return
    end
    local result = sendCommand(playerIndex or 0, "ClearCategory", { ref = ref })
    if result and result.ok then
        say(playerIndex or 0, ZCSMP.T("cleared"))
    elseif result then
        say(playerIndex or 0, result.reason or ZCSMP.T("clearFailed"))
    else
        say(playerIndex or 0, ZCSMP.T("cleared"))
    end
end

local function sortThisContainer(container, playerIndex)
    local ref = ZCSMP.Storage.GetContainerRef(container)
    if not ref then
        say(playerIndex, ZCSMP.T("sortFailed"))
        return
    end
    local result = sendCommand(playerIndex or 0, "SortFromContainer", { ref = ref })
    saySortResult(playerIndex or 0, result)
end

local function showNearbyCategories(playerIndex)
    local result = sendCommand(playerIndex or 0, "ShowNearbyCategories", {})
    if result then
        if result.text and result.total and result.total > 0 then
            say(playerIndex or 0, string.format(ZCSMP.T("nearbyCategories"), result.text))
        else
            say(playerIndex or 0, ZCSMP.T("nearbyCategoriesEmpty"))
        end
    else
        say(playerIndex or 0, ZCSMP.T("sortRequested"))
    end
end

local function onServerCommand(module, command, args)
    if module ~= ZCSMP.Config.CommandModule then return end
    args = args or {}
    if command == "SortResult" then
        local key = args.limited and "sortLimited" or "sortDone"
        local text = string.format(ZCSMP.T(key), args.processed or 0, args.moved or 0, args.missingTarget or 0, args.fullDestination or 0, args.failed or 0, args.other or 0)
        say(0, text)
        saySortDetails(0, args)
        log(text)
        log("details targets=" .. tostring(args.targets or 0) .. " targetContainers=" .. tostring(args.targetContainers or 0) .. " sources=" .. tostring(args.sources or 0) .. " processed=" .. tostring(args.processed or 0) .. " other=" .. tostring(args.other or 0) .. " missingTarget=" .. tostring(args.missingTarget or 0) .. " fullDestination=" .. tostring(args.fullDestination or 0))
        if ZCSMP.Config and ZCSMP.Config.DebugMode then
            if args.missingSamples then log("missing samples: " .. tostring(args.missingSamples)) end
            if args.fullSamples then log("full samples: " .. tostring(args.fullSamples)) end
            if args.failedSamples then log("failed samples: " .. tostring(args.failedSamples)) end
        end
    elseif command == "NearbyCategoriesResult" then
        if args.text and args.total and args.total > 0 then
            say(0, string.format(ZCSMP.T("nearbyCategories"), args.text))
        else
            say(0, ZCSMP.T("nearbyCategoriesEmpty"))
        end
    elseif command == "SortFailed" then
        say(0, args.reason or ZCSMP.T("sortFailed"))
    end
end

function ZCSMP.Client.OnFillWorldObjectContextMenu(playerIndex, context, worldObjects, test)
    if test or not context or not worldObjects then return end
    local container = getFirstContainer(worldObjects)
    if not container then return end

    local category = ZCSMP.Storage.GetCategory(container)
    if category then
        context:addOption(string.format(ZCSMP.T("currentCategory"), tostring(category)), nil, nil)
        context:addOption(ZCSMP.T("clearCategory"), container, clearCategory, playerIndex)
    end

    context:addOption(ZCSMP.T("showNearbyCategories"), nil, showNearbyCategories, playerIndex)

    local assignOption = context:addOption(ZCSMP.T("assignMenu"), nil, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(assignOption, submenu)
    for _, category in ipairs(ZCSMP.Config.Categories or {}) do
        submenu:addOption(tostring(category), container, assignCategory, category, playerIndex)
    end

    if not category then
        context:addOption(ZCSMP.T("sortThisContainer"), container, sortThisContainer, playerIndex)
    end
end

if Events and Events.OnFillWorldObjectContextMenu and not ZCSMP.Client.contextRegistered then
    Events.OnFillWorldObjectContextMenu.Add(ZCSMP.Client.OnFillWorldObjectContextMenu)
    ZCSMP.Client.contextRegistered = true
    log("context menu registered")
end

if Events and Events.OnServerCommand and not ZCSMP.Client.serverCommandRegistered then
    Events.OnServerCommand.Add(onServerCommand)
    ZCSMP.Client.serverCommandRegistered = true
    log("server command listener registered")
end