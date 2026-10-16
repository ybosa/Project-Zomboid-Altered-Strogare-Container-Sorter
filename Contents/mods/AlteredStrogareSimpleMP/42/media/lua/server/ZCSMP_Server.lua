ZCSMP = ZCSMP or {}
ZCSMP.Server = ZCSMP.Server or {}

local function log(message)
    print("[ZCSMP][SERVER] " .. tostring(message or "nil"))
end

local function sendResult(playerObj, command, args)
    if isClient and isClient() then return end
    if sendServerCommand and playerObj then
        sendServerCommand(playerObj, ZCSMP.Config.CommandModule, command, args or {})
    end
end

local function isValidCategory(category)
    if not category then return false end
    for _, value in ipairs(ZCSMP.Config.Categories or {}) do
        if value == category then return true end
    end
    return false
end

local function isPlayerAllowed(playerObj)
    if not ZCSMP.Config or not ZCSMP.Config.AdminOnly then return true end
    if not playerObj or not playerObj.getAccessLevel then return false end
    local level = tostring(playerObj:getAccessLevel() or ""):lower()
    return level == "admin" or level == "moderator" or level == "overseer"
end

function ZCSMP.Server.HandleCommand(command, playerObj, args)
    if ZCSMP.Config and ZCSMP.Config.ApplySandboxOptions then ZCSMP.Config.ApplySandboxOptions() end
    if not isPlayerAllowed(playerObj) then
        sendResult(playerObj, "SortFailed", { reason = "Sorting is restricted on this server" })
        return { failed = 1, reason = "Sorting is restricted on this server" }
    end

    args = args or {}

    if command == "AssignCategory" then
        if not isValidCategory(args.category) then
            sendResult(playerObj, "SortFailed", { reason = "Invalid category" })
            return { failed = 1, reason = "Invalid category" }
        end
        local container = ZCSMP.Storage.ResolveContainerRef(args.ref)
        if not container or not ZCSMP.Storage.AssignCategory(container, args.category) then
            sendResult(playerObj, "SortFailed", { reason = ZCSMP.T("assignFailed") })
            return { failed = 1, reason = ZCSMP.T("assignFailed") }
        end
        log("assigned category=" .. tostring(args.category))
        return { ok = true }
    end

    if command == "ClearCategory" then
        local container = ZCSMP.Storage.ResolveContainerRef(args.ref)
        if not container or not ZCSMP.Storage.ClearCategory(container) then
            sendResult(playerObj, "SortFailed", { reason = ZCSMP.T("clearFailed") })
            return { failed = 1, reason = ZCSMP.T("clearFailed") }
        end
        log("cleared category")
        return { ok = true }
    end

    if command == "SortFromContainer" then
        local source = ZCSMP.Storage.ResolveContainerRef(args.ref)
        if not source then
            local result = { moved = 0, skipped = 0, failed = 1, targets = 0, sources = 0, reason = ZCSMP.T("sortFailed") }
            sendResult(playerObj, "SortFailed", { reason = result.reason })
            return result
        end
        if ZCSMP.Storage.GetCategory(source) then
            local result = { moved = 0, skipped = 0, failed = 1, targets = 0, sources = 0, reason = ZCSMP.T("sourceIsDestination") }
            sendResult(playerObj, "SortFailed", { reason = result.reason })
            return result
        end
        local result = ZCSMP.Storage.SortFromContainer(playerObj, source)
        sendResult(playerObj, "SortResult", result)
        return result
    end

    if command == "SortNearby" then
        local result = ZCSMP.Storage.SortNearby(playerObj)
        sendResult(playerObj, "SortResult", result)
        return result
    end

    if command == "ShowNearbyCategories" then
        local result = ZCSMP.Storage.GetNearbyCategorySummary(playerObj)
        sendResult(playerObj, "NearbyCategoriesResult", result)
        return result
    end
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= ZCSMP.Config.CommandModule then return end
    ZCSMP.Server.HandleCommand(command, playerObj, args or {})
end

if Events and Events.OnClientCommand and not ZCSMP.Server.clientCommandRegistered then
    Events.OnClientCommand.Add(onClientCommand)
    ZCSMP.Server.clientCommandRegistered = true
    log("client command listener registered")
end