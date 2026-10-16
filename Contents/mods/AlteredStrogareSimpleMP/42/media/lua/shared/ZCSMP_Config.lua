ZCSMP = ZCSMP or {}
ZCSMP.Config = ZCSMP.Config or {}

ZCSMP.Config.ModId = "StrogareSimpleMP"
ZCSMP.Config.CommandModule = "ZCSMP"
ZCSMP.Config.ModDataKey = "ZCSMP_Category"
ZCSMP.Config.TargetBuild = "42.20"
ZCSMP.Config.Defaults = ZCSMP.Config.Defaults or {
    SortRadius = 30,
    MaxSortRadius = 30,
    SortFloorRange = 2,
    MaxSortFloorRange = 2,
    IncludeOtherFloors = true,
    IncludeVehicleContainers = true,
    AllowVehicleSorting = true,
    MaxItemsPerSort = 500,
    AdminOnly = false,
    DebugMode = false,
    Language = "auto",
}

local function clamp(value, defaultValue, minValue, maxValue)
    local number = tonumber(value) or defaultValue
    if number < minValue then return minValue end
    if number > maxValue then return maxValue end
    return number
end

local function asBoolean(value, defaultValue)
    if value == true or value == false then return value end
    if value == 1 or value == "true" or value == "1" then return true end
    if value == 0 or value == "false" or value == "0" then return false end
    return defaultValue
end

function ZCSMP.Config.ResetToDefaults()
    for key, value in pairs(ZCSMP.Config.Defaults) do
        ZCSMP.Config[key] = value
    end
end

function ZCSMP.Config.ApplySandboxOptions()
    ZCSMP.Config.ResetToDefaults()
    local root = SandboxVars
    local strogareNested = root and root.Strogare or nil
    local legacyNested = root and root.ZCSMP or nil
    if not root and not strogareNested and not legacyNested then return end

    local function option(name)
        if strogareNested and strogareNested[name] ~= nil then return strogareNested[name] end
        if legacyNested and legacyNested[name] ~= nil then return legacyNested[name] end
        if root and root["Strogare_" .. name] ~= nil then return root["Strogare_" .. name] end
        if root and root["ZCSMP_" .. name] ~= nil then return root["ZCSMP_" .. name] end
        return nil
    end

    ZCSMP.Config.SortRadius = clamp(option("SortRadius"), ZCSMP.Config.SortRadius, 0, ZCSMP.Config.MaxSortRadius)
    ZCSMP.Config.SortFloorRange = clamp(option("SortFloorRange"), ZCSMP.Config.SortFloorRange, 0, ZCSMP.Config.MaxSortFloorRange)
    ZCSMP.Config.MaxItemsPerSort = clamp(option("MaxItemsPerSort"), ZCSMP.Config.MaxItemsPerSort, 1, 5000)
    ZCSMP.Config.IncludeOtherFloors = asBoolean(option("IncludeOtherFloors"), ZCSMP.Config.IncludeOtherFloors)
    ZCSMP.Config.IncludeVehicleContainers = asBoolean(option("IncludeVehicleContainers"), ZCSMP.Config.IncludeVehicleContainers)
    ZCSMP.Config.AllowVehicleSorting = asBoolean(option("AllowVehicleSorting"), ZCSMP.Config.AllowVehicleSorting)
    ZCSMP.Config.AdminOnly = asBoolean(option("AdminOnly"), ZCSMP.Config.AdminOnly)
    ZCSMP.Config.DebugMode = asBoolean(option("DebugMode"), ZCSMP.Config.DebugMode)

    local language = option("Language")
    if language == 2 or language == "en" or language == "English" then
        ZCSMP.Config.Language = "en"
    elseif language == 3 or language == "ru" or language == "Russian" then
        ZCSMP.Config.Language = "ru"
    else
        ZCSMP.Config.Language = "auto"
    end
end

ZCSMP.Config.ApplySandboxOptions()

ZCSMP.Config.Categories = {
    "Food",
    "Medical",
    "Weapons",
    "Ammo",
    "Tools",
    "Materials",
    "Clothing",
    "Books",
    "Electronics",
    "Vehicle",
    "Farming",
    "Cooking",
    "Trash",
    "Other",
    "FoodUnperishable", --[[ done ]]
    "WoodMaterials", --[[ done ]]
    "MetalMaterials", --[[ done ]]
    "Paint", --[[ might be done ]]
    "NailsAndScrews", --[[ done ]]
    "Rifle",  --[[ done ]]
    "Pistol", --[[ done ]]
    "Shotgun", --[[ done ]]
    "Magazine", --[[ done ]]
    "WeaponParts", --[[ might be done ]]
    "Entertainment", --[[ might be done ]]
    "Container", --[[ might be done ]]
    "Accessory",  --[[ might be done ]]
    "ProtectiveGear",
    "Furniture",  --[[ might be done ]]
    "WaterContainer", --[[ done ]]
    "Fuel",  --[[ done ]]
}

ZCSMP.Lang = ZCSMP.Lang or {}
ZCSMP.Lang.en = {
    assignMenu = "Strogare: Assign Storage Category",
    sortNearby = "Strogare: Sort Nearby Containers",
    sortThisContainer = "Strogare: Sort This Container",
    currentCategory = "Strogare: Category: %s",
    clearCategory = "Strogare: Clear Category",
    assigned = "Assigned: %s",
    cleared = "Category cleared.",
    clearFailed = "Could not clear category.",
    sourceIsDestination = "This container has a category. Clear it before using it as a source.",
    assignFailed = "Could not assign category.",
    sortRequested = "Sorting requested.",
    sortDone = "Sorted: processed %d, moved %d, no target %d, full %d, failed %d, Other %d.",
    sortLimited = "Sorted: processed %d, moved %d, no target %d, full %d, failed %d, Other %d. Limit reached, run sorting again if needed.",
    sortFailed = "Sorting failed.",
    showNearbyCategories = "Strogare: Show Nearby Categories",
    nearbyCategories = "Nearby storage: %s",
    nearbyCategoriesEmpty = "No categorized storage found nearby.",
    sortDetailsMissing = "No destination: %s",
    sortDetailsFull = "Full destination: %s",
    sortDetailsFailed = "Transfer failed: %s",
}
ZCSMP.Lang.ru = {
    assignMenu = "\083\116\114\111\103\097\114\101\058\032\208\189\208\176\208\183\208\189\208\176\209\135\208\184\209\130\209\140\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\142",
    sortNearby = "\083\116\114\111\103\097\114\101\058\032\209\129\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\176\209\130\209\140\032\209\128\209\143\208\180\208\190\208\188",
    sortThisContainer = "\083\116\114\111\103\097\114\101\058\032\209\129\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\176\209\130\209\140\032\209\141\209\130\208\190\209\130\032\208\186\208\190\208\189\209\130\208\181\208\185\208\189\208\181\209\128",
    currentCategory = "\083\116\114\111\103\097\114\101\058\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\143\058\032\037\115",
    clearCategory = "\083\116\114\111\103\097\114\101\058\032\208\190\209\135\208\184\209\129\209\130\208\184\209\130\209\140\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\142",
    assigned = "\208\157\208\176\208\183\208\189\208\176\209\135\208\181\208\189\208\190\058\032\037\115",
    cleared = "\208\154\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\143\032\208\190\209\135\208\184\209\137\208\181\208\189\208\176\046",
    clearFailed = "\208\157\208\181\032\209\131\208\180\208\176\208\187\208\190\209\129\209\140\032\208\190\209\135\208\184\209\129\209\130\208\184\209\130\209\140\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\142\046",
    sourceIsDestination = "\208\163\032\209\141\209\130\208\190\208\179\208\190\032\208\186\208\190\208\189\209\130\208\181\208\185\208\189\208\181\209\128\208\176\032\208\189\208\176\208\183\208\189\208\176\209\135\208\181\208\189\208\176\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\143\046\032\208\158\209\135\208\184\209\129\209\130\208\184\209\130\208\181\032\208\181\208\181\032\208\191\208\181\209\128\208\181\208\180\032\209\129\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\186\208\190\208\185\032\208\184\208\183\032\208\189\208\181\208\179\208\190\046",
    assignFailed = "\208\157\208\181\032\209\131\208\180\208\176\208\187\208\190\209\129\209\140\032\208\189\208\176\208\183\208\189\208\176\209\135\208\184\209\130\209\140\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\209\142\046",
    sortRequested = "\208\161\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\186\208\176\032\208\183\208\176\208\191\209\128\208\190\209\136\208\181\208\189\208\176\046",
    sortDone = "\208\161\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\186\208\176\058\032\208\191\209\128\208\190\208\178\208\181\209\128\208\181\208\189\208\190\032\037\100\044\032\208\191\208\181\209\128\208\181\208\189\208\181\209\129\208\181\208\189\208\190\032\037\100\044\032\208\189\208\181\209\130\032\209\134\208\181\208\187\208\184\032\037\100\044\032\208\183\208\176\208\191\208\190\208\187\208\189\208\181\208\189\208\190\032\037\100\044\032\208\190\209\136\208\184\208\177\208\190\208\186\032\037\100\044\032\208\178\032\208\159\209\128\208\190\209\135\208\181\208\181\032\037\100\046",
    sortLimited = "\208\161\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\186\208\176\058\032\208\191\209\128\208\190\208\178\208\181\209\128\208\181\208\189\208\190\032\037\100\044\032\208\191\208\181\209\128\208\181\208\189\208\181\209\129\208\181\208\189\208\190\032\037\100\044\032\208\189\208\181\209\130\032\209\134\208\181\208\187\208\184\032\037\100\044\032\208\183\208\176\208\191\208\190\208\187\208\189\208\181\208\189\208\190\032\037\100\044\032\208\190\209\136\208\184\208\177\208\190\208\186\032\037\100\044\032\208\178\032\208\159\209\128\208\190\209\135\208\181\208\181\032\037\100\046\032\208\148\208\190\209\129\209\130\208\184\208\179\208\189\209\131\209\130\032\208\187\208\184\208\188\208\184\209\130\044\032\208\183\208\176\208\191\209\131\209\129\209\130\208\184\209\130\208\181\032\208\181\209\137\208\181\032\209\128\208\176\208\183\032\208\191\209\128\208\184\032\208\189\208\181\208\190\208\177\209\133\208\190\208\180\208\184\208\188\208\190\209\129\209\130\208\184\046",
    sortFailed = "\208\161\208\190\209\128\209\130\208\184\209\128\208\190\208\178\208\186\208\176\032\208\189\208\181\032\209\131\208\180\208\176\208\187\208\176\209\129\209\140\046",
    showNearbyCategories = "\083\116\114\111\103\097\114\101\058\032\208\191\208\190\208\186\208\176\208\183\208\176\209\130\209\140\032\208\186\208\176\209\130\208\181\208\179\208\190\209\128\208\184\208\184\032\209\128\209\143\208\180\208\190\208\188",
    nearbyCategories = "\208\165\209\128\208\176\208\189\208\184\208\187\208\184\209\137\208\176\032\209\128\209\143\208\180\208\190\208\188\058\032\037\115",
    nearbyCategoriesEmpty = "\208\157\208\176\208\183\208\189\208\176\209\135\208\181\208\189\208\189\209\139\208\181\032\209\133\209\128\208\176\208\189\208\184\208\187\208\184\209\137\208\176\032\209\128\209\143\208\180\208\190\208\188\032\208\189\208\181\032\208\189\208\176\208\185\208\180\208\181\208\189\209\139\046",
    sortDetailsMissing = "\208\157\208\181\209\130\032\208\189\208\176\208\183\208\189\208\176\209\135\208\181\208\189\208\184\209\143\058\032\037\115",
    sortDetailsFull = "\208\151\208\176\208\191\208\190\208\187\208\189\208\181\208\189\208\190\058\032\037\115",
    sortDetailsFailed = "\208\158\209\136\208\184\208\177\208\186\208\176\032\208\191\208\181\209\128\208\181\208\189\208\190\209\129\208\176\058\032\037\115",
}

function ZCSMP.GetLanguage()
    if ZCSMP.Config and ZCSMP.Config.ApplySandboxOptions then ZCSMP.Config.ApplySandboxOptions() end
    local configured = ZCSMP.Config and ZCSMP.Config.Language or "auto"
    if configured == "en" or configured == "ru" then return configured end

    local gameLanguage = nil
    if Translator and Translator.getLanguage then
        local ok, language = pcall(function() return Translator.getLanguage() end)
        if ok and language and language.name then
            local okName, name = pcall(function() return language:name() end)
            if okName then gameLanguage = tostring(name or "") end
        elseif ok and language then
            gameLanguage = tostring(language)
        end
    end

    gameLanguage = tostring(gameLanguage or ""):lower()
    if gameLanguage == "ru" or gameLanguage == "russian" or gameLanguage:find("russian", 1, true) then
        return "ru"
    end
    return "en"
end

function ZCSMP.T(key)
    local lang = ZCSMP.GetLanguage and ZCSMP.GetLanguage() or "en"
    local tableForLang = ZCSMP.Lang[lang] or ZCSMP.Lang.en
    return tableForLang[key] or ZCSMP.Lang.en[key] or tostring(key)
end
