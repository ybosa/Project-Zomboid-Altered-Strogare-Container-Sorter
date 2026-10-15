ZCSMP = ZCSMP or {}
ZCSMP.Storage = ZCSMP.Storage or {}

local function log(message)
    print("[ZCSMP] " .. tostring(message or "nil"))
end

local function warn(message)
    print("[ZCSMP] WARN: " .. tostring(message or "nil"))
end

local function debugLog(message)
    if ZCSMP.Config and ZCSMP.Config.DebugMode then
        print("[ZCSMP] DEBUG: " .. tostring(message or "nil"))
    end
end

local function getModDataKey()
    return ZCSMP.Config and ZCSMP.Config.ModDataKey or "ZCSMP_Category"
end

local function safeCall(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function clampNumber(value, defaultValue, minValue, maxValue)
    local number = tonumber(value) or defaultValue
    if number < minValue then return minValue end
    if number > maxValue then return maxValue end
    return number
end

local function getContainerObject(container)
    if not container then return nil end
    if container.getContainingItem and container:getContainingItem() then return container:getContainingItem() end
    if container.getParent and container:getParent() then return container:getParent() end
    return nil
end

local function getVehiclePartForContainer(container)
    if not container or not container.getParent or not container.getType then return nil end
    local parent = container:getParent()
    if not parent or not parent.getPartById then return nil end
    return parent:getPartById(container:getType())
end

local function isVehicleContainer(container)
    return getVehiclePartForContainer(container) ~= nil
end

local function getContainerCategoryKey(container)
    local key = getModDataKey()
    local part = getVehiclePartForContainer(container)
    if part and part.getId then
        return key .. ":vehicle:" .. tostring(part:getId())
    end
    return key
end

local function refreshVehiclePartContainer(container)
    local part = getVehiclePartForContainer(container)
    if not part or not part.getItemContainer or not part.setContainerContentAmount then return end
    safeCall(function()
        local itemContainer = part:getItemContainer()
        local weight = itemContainer and itemContainer.getCapacityWeight and itemContainer:getCapacityWeight() or 0
        part:setContainerContentAmount(weight)
    end)
    local vehicle = part.getVehicle and part:getVehicle() or nil
    if vehicle and vehicle.transmitPartItem then
        safeCall(function() vehicle:transmitPartItem(part) end)
    end
end

local function addVehiclePartContainers(result, vehicle)
    if not vehicle or not vehicle.getPartCount then return end
    for i = 0, vehicle:getPartCount() - 1 do
        local part = nil
        if vehicle.getPartByIndex then
            part = vehicle:getPartByIndex(i)
        elseif vehicle.getPartById then
            part = vehicle:getPartById(i)
        end
        local container = part and part.getItemContainer and part:getItemContainer() or nil
        if container then
            local key = "vehicle:" .. tostring(vehicle) .. ":" .. tostring(part.getId and part:getId() or i)
            if not result[key] then result[key] = container end
        end
    end
end

local function getDefaultVehicleContainer(vehicle)
    if not vehicle then return nil end
    local partIds = { "TruckBed", "TruckBedOpen", "Trunk", "GloveBox" }
    if vehicle.getPartById then
        for _, partId in ipairs(partIds) do
            local part = vehicle:getPartById(partId)
            local container = part and part.getItemContainer and part:getItemContainer() or nil
            if container then return container end
        end
    end
    if vehicle.getPartCount then
        for i = 0, vehicle:getPartCount() - 1 do
            local part = vehicle.getPartByIndex and vehicle:getPartByIndex(i) or nil
            local container = part and part.getItemContainer and part:getItemContainer() or nil
            if container then return container end
        end
    end
    return nil
end

function ZCSMP.Storage.GetContainerFromObject(worldObject)
    if not worldObject then return nil end
    if worldObject.getContainer and worldObject:getContainer() then return worldObject:getContainer() end
    if worldObject.getItemContainer and worldObject:getItemContainer() then return worldObject:getItemContainer() end
    if worldObject.getPartCount then return getDefaultVehicleContainer(worldObject) end
    if worldObject.getVehiclePart then
        local part = worldObject:getVehiclePart()
        if part and part.getItemContainer then return part:getItemContainer() end
    end
    return nil
end

function ZCSMP.Storage.GetContainerRef(container)
    local part = getVehiclePartForContainer(container)
    if part and part.getVehicle and part.getId then
        local vehicle = part:getVehicle()
        if vehicle and vehicle.getX and vehicle.getY then
            return {
                kind = "vehicle",
                x = math.floor(vehicle:getX()),
                y = math.floor(vehicle:getY()),
                z = math.floor(vehicle.getZ and vehicle:getZ() or 0),
                partId = part:getId(),
            }
        end
    end

    local obj = getContainerObject(container)
    local square = obj and obj.getSquare and obj:getSquare() or nil
    if not obj or not square or not square.getObjects then return nil end
    local objects = square:getObjects()
    local objectIndex = -1
    if objects then
        for i = 0, objects:size() - 1 do
            if objects:get(i) == obj then objectIndex = i; break end
        end
    end
    if objectIndex < 0 then return nil end
    return {
        kind = "object",
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        objectIndex = objectIndex,
        containerType = container.getType and tostring(container:getType()) or nil,
    }
end

local function getVehicleAtSquare(square)
    if not square then return nil end
    if square.getVehicleContainer then
        local vehicle = square:getVehicleContainer()
        if vehicle then return vehicle end
    end
    if square.getMovingObjects then
        local moving = square:getMovingObjects()
        if moving then
            for i = 0, moving:size() - 1 do
                local obj = moving:get(i)
                if obj and obj.getPartCount then return obj end
            end
        end
    end
    return nil
end

function ZCSMP.Storage.ResolveContainerRef(ref)
    if not ref or not ref.x or not ref.y or not ref.z then return nil end
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare and cell:getGridSquare(ref.x, ref.y, ref.z) or nil
    if not square then return nil end

    if ref.kind == "vehicle" then
        local vehicle = getVehicleAtSquare(square)
        local part = vehicle and vehicle.getPartById and vehicle:getPartById(ref.partId) or nil
        return part and part.getItemContainer and part:getItemContainer() or nil
    end

    local objects = square.getObjects and square:getObjects() or nil
    if not objects then return nil end
    local obj = objects:get(tonumber(ref.objectIndex) or -1)
    if not obj then return nil end
    return ZCSMP.Storage.GetContainerFromObject(obj)
end

local function getContainerModData(container)
    if not container then return nil, nil end
    local obj = getContainerObject(container)
    if obj and obj.getModData then return obj:getModData(), obj end
    if container.getModData then return container:getModData(), nil end
    return nil, obj
end

function ZCSMP.Storage.GetCategory(container)
    local data = getContainerModData(container)
    if not data then return nil end
    return data[getContainerCategoryKey(container)]
end

function ZCSMP.Storage.AssignCategory(container, category)
    if not container or not category then return false end
    local data, obj = getContainerModData(container)
    if not data then return false end
    data[getContainerCategoryKey(container)] = category
    if obj and obj.transmitModData then obj:transmitModData() end
    log("assigned category=" .. tostring(category))
    return true
end

function ZCSMP.Storage.ClearCategory(container)
    if not container then return false end
    local data, obj = getContainerModData(container)
    if not data then return false end
    data[getContainerCategoryKey(container)] = nil
    if obj and obj.transmitModData then obj:transmitModData() end
    log("cleared category")
    return true
end

local function addContainer(result, container, explicitKey)
    if not container then return end
    local key = explicitKey or tostring(container)
    if result[key] then return end
    result[key] = container
end

local function addSquareContainers(result, square)
    local objects = square and square.getObjects and square:getObjects() or nil
    if objects then
        for i = 0, objects:size() - 1 do
            addContainer(result, ZCSMP.Storage.GetContainerFromObject(objects:get(i)))
        end
    end
    if not ZCSMP.Config or ZCSMP.Config.IncludeVehicleContainers ~= false then
        addVehiclePartContainers(result, getVehicleAtSquare(square))
    end
end

function ZCSMP.Storage.FindNearbyContainers(playerObj, radius)
    local result = {}
    if not playerObj then return result end
    local defaultRadius = (ZCSMP.Config and ZCSMP.Config.SortRadius) or 30
    local maxRadius = (ZCSMP.Config and ZCSMP.Config.MaxSortRadius) or 30
    radius = clampNumber(radius or defaultRadius, defaultRadius, 0, maxRadius)
    local defaultFloorRange = 0
    if not ZCSMP.Config or ZCSMP.Config.IncludeOtherFloors ~= false then
        defaultFloorRange = (ZCSMP.Config and ZCSMP.Config.SortFloorRange) or 2
    end
    local maxFloorRange = (ZCSMP.Config and ZCSMP.Config.MaxSortFloorRange) or 2
    local floorRange = clampNumber(defaultFloorRange, defaultFloorRange, 0, maxFloorRange)
    local cell = getCell and getCell() or nil
    local square = playerObj.getSquare and playerObj:getSquare() or nil
    if not cell or not square then return result end
    local px, py, pz = square:getX(), square:getY(), square:getZ()
    local minZ = math.max(0, pz - floorRange)
    local maxZ = pz + floorRange
    for z = minZ, maxZ do
        for x = px - radius, px + radius do
            for y = py - radius, py + radius do
                addSquareContainers(result, cell:getGridSquare(x, y, z))
            end
        end
    end
    local count = 0
    for _ in pairs(result) do count = count + 1 end
    log("nearby scan radius=" .. tostring(radius) .. " floorRange=" .. tostring(floorRange) .. " containers=" .. tostring(count))
    return result
end

local function addReasonCount(result, field, category)
    if not result or not field then return end
    category = tostring(category or "Unknown")
    result[field] = result[field] or {}
    result[field][category] = (result[field][category] or 0) + 1
end

local function formatReasonCounts(counts)
    if not counts then return nil end
    local parts = {}
    local seen = {}
    for _, category in ipairs(ZCSMP.Config and ZCSMP.Config.Categories or {}) do
        local count = counts[category]
        if count and count > 0 then
            parts[#parts + 1] = tostring(category) .. " x" .. tostring(count)
            seen[category] = true
        end
    end
    for category, count in pairs(counts) do
        if not seen[category] and count and count > 0 then
            parts[#parts + 1] = tostring(category) .. " x" .. tostring(count)
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
end

function ZCSMP.Storage.GetNearbyCategorySummary(playerObj)
    local nearby = ZCSMP.Storage.FindNearbyContainers(playerObj, ZCSMP.Config and ZCSMP.Config.SortRadius or nil)
    local counts = {}
    local total = 0
    for _, container in pairs(nearby or {}) do
        local playerInventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
        if container and container ~= playerInventory then
            if not (isVehicleContainer(container) and (not ZCSMP.Config or ZCSMP.Config.AllowVehicleSorting ~= true)) then
                local category = ZCSMP.Storage.GetCategory(container)
                if category then
                    counts[category] = (counts[category] or 0) + 1
                    total = total + 1
                end
            end
        end
    end
    return { total = total, categories = counts, text = formatReasonCounts(counts) }
end

local function getItemsSnapshot(container)
    local result = {}
    local items = container and container.getItems and container:getItems() or nil
    if not items then return result end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then result[#result + 1] = item end
    end
    return result
end

local function isPlayerInventory(container, playerObj)
    return container and playerObj and playerObj.getInventory and container == playerObj:getInventory()
end

local function isEquippedByPlayer(item, playerObj)
    if not item or not playerObj then return false end
    if playerObj.getPrimaryHandItem and item == playerObj:getPrimaryHandItem() then return true end
    if playerObj.getSecondaryHandItem and item == playerObj:getSecondaryHandItem() then return true end
    if playerObj.isEquipped and playerObj:isEquipped(item) then return true end
    return false
end

local function containsItem(container, item)
    return container and item and container.contains and container:contains(item)
end

local function removeItem(container, item)
    if not container or not item then return false end
    local ok = false
    if container.DoRemoveItem then ok = pcall(function() container:DoRemoveItem(item) end) end
    if (not ok or containsItem(container, item)) and container.Remove then ok = pcall(function() container:Remove(item) end) end
    if (not ok or containsItem(container, item)) and container.RemoveItem then ok = pcall(function() container:RemoveItem(item) end) end
    return ok and not containsItem(container, item)
end

local function syncRemove(container, item)
    if sendRemoveItemFromContainer then safeCall(function() sendRemoveItemFromContainer(container, item) end) end
    if container and container.setDrawDirty then safeCall(function() container:setDrawDirty(true) end) end
end

local function syncAdd(container, item)
    if sendAddItemToContainer then safeCall(function() sendAddItemToContainer(container, item) end) end
    if container and container.setDrawDirty then safeCall(function() container:setDrawDirty(true) end) end
end
local function getItemDebugText(item)
    if not item then return "nil" end
    local values = {}
    local function add(label, methodName)
        if item[methodName] then
            local value = safeCall(function() return item[methodName](item) end)
            if value and tostring(value) ~= "" then values[#values + 1] = label .. "=" .. tostring(value) end
        end
    end
    add("fullType", "getFullType")
    add("type", "getType")
    add("display", "getDisplayCategory")
    add("category", "getCategory")
    add("name", "getName")
    return table.concat(values, ";")
end

local function appendSample(result, key, item, category)
    if not result or not key then return end
    local countKey = key .. "Count"
    result[countKey] = (result[countKey] or 0) + 1
    if result[countKey] > 8 then return end
    local sample = "[" .. tostring(category or "nil") .. "] " .. getItemDebugText(item)
    result[key] = result[key] and (result[key] .. " || " .. sample) or sample
end


local function getItemWeight(item)
    if not item then return 0 end
    local weight = nil
    if item.getActualWeight then weight = safeCall(function() return item:getActualWeight() end) end
    if weight == nil and item.getUnequippedWeight then weight = safeCall(function() return item:getUnequippedWeight() end) end
    if weight == nil and item.getWeight then weight = safeCall(function() return item:getWeight() end) end
    return tonumber(weight) or 0
end

local function containerHasRoomFor(playerObj, container, item)
    if not container or not item then return false end
    if container.hasRoomFor then
        local ok, result = pcall(function() return container:hasRoomFor(playerObj, item) end)
        if ok and result ~= nil then return result == true end
        ok, result = pcall(function() return container:hasRoomFor(item) end)
        if ok and result ~= nil then return result == true end
        ok, result = pcall(function() return container:hasRoomFor(playerObj, getItemWeight(item)) end)
        if ok and result ~= nil then return result == true end
        ok, result = pcall(function() return container:hasRoomFor(getItemWeight(item)) end)
        if ok and result ~= nil then return result == true end
    end
    if container.getCapacity and container.getCapacityWeight then
        local capacity = tonumber(safeCall(function() return container:getCapacity() end))
        local current = tonumber(safeCall(function() return container:getCapacityWeight() end))
        if capacity and current then return current + getItemWeight(item) <= capacity end
    end
    if container.getEffectiveCapacity and container.getCapacityWeight then
        local capacity = tonumber(safeCall(function() return container:getEffectiveCapacity(playerObj) end))
        local current = tonumber(safeCall(function() return container:getCapacityWeight() end))
        if capacity and current then return current + getItemWeight(item) <= capacity end
    end
    return true
end

local function transferItem(item, source, target, playerObj)
    if not item or not source or not target or source == target then return false, "invalid" end
    if not containsItem(source, item) or not target.AddItem then return false, "invalid" end
    if not containerHasRoomFor(playerObj, target, item) then return false, "full" end

    if not removeItem(source, item) then return false, "remove" end
    syncRemove(source, item)

    local ok = pcall(function() target:AddItem(item) end)
    if not ok or not containsItem(target, item) then
        safeCall(function() source:AddItem(item) end)
        syncAdd(source, item)
        return false, "add"
    end

    syncAdd(target, item)
    refreshVehiclePartContainer(source)
    refreshVehiclePartContainer(target)
    return true, nil
end

function ZCSMP.Storage.SortContainers(playerObj, nearby, explicitSources)
    local result = { moved = 0, skipped = 0, failed = 0, targets = 0, targetContainers = 0, sources = 0, processed = 0, limited = false, other = 0, missingTarget = 0, fullDestination = 0 }
    local maxItems = (ZCSMP.Config and tonumber(ZCSMP.Config.MaxItemsPerSort)) or 500
    local targets = {}
    local sources = {}
    for _, container in pairs(nearby or {}) do
        if container and not isPlayerInventory(container, playerObj) then
            if isVehicleContainer(container) and (not ZCSMP.Config or ZCSMP.Config.AllowVehicleSorting ~= true) then
                result.skipped = result.skipped + 1
            else
                local category = ZCSMP.Storage.GetCategory(container)
                if category then
                    if not targets[category] then
                        targets[category] = {}
                        result.targetCategories = result.targetCategories and (result.targetCategories .. "," .. tostring(category)) or tostring(category)
                    end
                    targets[category][#targets[category] + 1] = container
                    result.targetContainers = result.targetContainers + 1
                end
            end
        end
    end
    for _, container in ipairs(explicitSources or {}) do
        if container and not isPlayerInventory(container, playerObj) and not ZCSMP.Storage.GetCategory(container) then
            if not isVehicleContainer(container) or (ZCSMP.Config and ZCSMP.Config.AllowVehicleSorting == true) then
                sources[#sources + 1] = container
            else
                result.skipped = result.skipped + 1
            end
        end
    end
    for _ in pairs(targets) do result.targets = result.targets + 1 end
    result.sources = #sources
    log("sort started targets=" .. tostring(result.targets) .. " targetContainers=" .. tostring(result.targetContainers) .. " categories=" .. tostring(result.targetCategories or "none") .. " sources=" .. tostring(result.sources))
    for _, source in ipairs(sources) do
        for _, item in ipairs(getItemsSnapshot(source)) do
            if item and not isEquippedByPlayer(item, playerObj) then
                if maxItems > 0 and result.processed >= maxItems then
                    result.limited = true
                    result.skipped = result.skipped + 1
                else
                    result.processed = result.processed + 1
                    local category = ZCSMP.ItemCategories and ZCSMP.ItemCategories.GetCategory and ZCSMP.ItemCategories.GetCategory(item) or nil
                    local targetList = category and targets[category] or nil
                    local usedOther = false
                    if (not targetList) and targets["Other"] then
                        targetList = targets["Other"]
                        usedOther = true
                    end
                    if targetList then
                        local moved = false
                        local attempted = false
                        local fullOnly = false
                        local transferFailed = false
                        for _, target in ipairs(targetList) do
                            if target and source ~= target then
                                attempted = true
                                local ok, reason = transferItem(item, source, target, playerObj)
                                if ok then
                                    moved = true
                                    break
                                elseif reason == "full" then
                                    fullOnly = true
                                else
                                    transferFailed = true
                                end
                            end
                        end
                        if moved then
                            result.moved = result.moved + 1
                            if usedOther then result.other = result.other + 1 end
                        elseif attempted then
                            if fullOnly and not transferFailed then
                                result.fullDestination = result.fullDestination + 1
                                addReasonCount(result, "fullCategories", category)
                                appendSample(result, "fullSamples", item, category)
                            else
                                result.failed = result.failed + 1
                                addReasonCount(result, "failedCategories", category)
                                appendSample(result, "failedSamples", item, category)
                            end
                        else
                            result.skipped = result.skipped + 1
                        end
                    else
                        result.missingTarget = result.missingTarget + 1
                        addReasonCount(result, "missingCategories", category or "Unknown")
                        appendSample(result, "missingSamples", item, category)
                        result.skipped = result.skipped + 1
                    end
                end
            end
        end
    end
    log("sort finished moved=" .. tostring(result.moved) .. " skipped=" .. tostring(result.skipped) .. " failed=" .. tostring(result.failed) .. " fullDestination=" .. tostring(result.fullDestination) .. " other=" .. tostring(result.other) .. " missingTarget=" .. tostring(result.missingTarget) .. " processed=" .. tostring(result.processed))
    result.missingCategoriesText = formatReasonCounts(result.missingCategories)
    result.fullCategoriesText = formatReasonCounts(result.fullCategories)
    result.failedCategoriesText = formatReasonCounts(result.failedCategories)
    if result.missingSamples then debugLog("missing samples: " .. tostring(result.missingSamples)) end
    if result.fullSamples then debugLog("full samples: " .. tostring(result.fullSamples)) end
    if result.failedSamples then debugLog("failed samples: " .. tostring(result.failedSamples)) end
    return result
end

function ZCSMP.Storage.SortFromContainer(playerObj, sourceContainer)
    if not playerObj or not sourceContainer then
        warn("missing player or source container")
        return { moved = 0, skipped = 0, failed = 1, targets = 0, sources = 0 }
    end
    local nearby = ZCSMP.Storage.FindNearbyContainers(playerObj, ZCSMP.Config.SortRadius)
    return ZCSMP.Storage.SortContainers(playerObj, nearby, { sourceContainer })
end

function ZCSMP.Storage.SortNearby(playerObj)
    if not playerObj then
        warn("missing player")
        return { moved = 0, skipped = 0, failed = 1, targets = 0, sources = 0 }
    end
    return ZCSMP.Storage.SortContainers(playerObj, ZCSMP.Storage.FindNearbyContainers(playerObj, ZCSMP.Config.SortRadius), {})
end
