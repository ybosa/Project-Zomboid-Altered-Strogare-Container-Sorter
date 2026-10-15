ZCSMP = ZCSMP or {}
ZCSMP.ItemCategories = ZCSMP.ItemCategories or {}

local displayCategoryMap = {
    food = "Food",
    firstaid = "Medical",
    wound = "Medical",
    bandage = "Medical",
    ammo = "Ammo",
    explosives = "Ammo",
    weapon = "Weapons",
    weaponcrafted = "Weapons",
    toolweapon = "Tools",
    sportsweapon = "Weapons",
    householdweapon = "Weapons",
    junkweapon = "Weapons",
    materialweapon = "Materials",
    cookingweapon = "Cooking",
    clothing = "Clothing",
    accessory = "Clothing",
    protectivegear = "Clothing",
    bag = "Clothing",
    container = "Clothing",
    ears = "Clothing",
    malebody = "Clothing",
    femalebody = "Clothing",
    literature = "Books",
    skillbook = "Books",
    cartography = "Books",
    electronics = "Electronics",
    communications = "Electronics",
    lightsource = "Electronics",
    vehiclemaintenance = "Vehicle",
    gardening = "Farming",
    gardeningweapon = "Farming",
    fishing = "Farming",
    cooking = "Cooking",
    watercontainer = "Cooking",
    household = "Cooking",
    material = "Materials",
    reciperesource = "Books",
    paint = "Materials",
    animalpart = "Materials",
    camping = "Tools",
    tool = "Tools",
    furniture = "Materials",
    junk = "Trash",
    zeddmg = "Trash",
}

local function normalize(value)
    return string.lower(tostring(value or "")):gsub("[%s_%-%./:]", "")
end

local function containsAny(value, needles)
    if not value or not needles then return false end
    local lower = string.lower(tostring(value))
    for _, needle in ipairs(needles) do
        if string.find(lower, string.lower(needle), 1, true) then return true end
    end
    return false
end

local function safeMethod(item, methodName)
    if not item or not item[methodName] then return nil end
    local ok, result = pcall(function() return item[methodName](item) end)
    if ok then return result end
    return nil
end

local function getTypeText(item)
    if not item then return "" end
    local fullType = safeMethod(item, "getFullType") or ""
    local itemType = safeMethod(item, "getType") or ""
    local displayCategory = safeMethod(item, "getDisplayCategory") or ""
    local category = safeMethod(item, "getCategory") or ""
    local name = safeMethod(item, "getName") or ""
    local bodyLocation = safeMethod(item, "getBodyLocation") or ""
    local equipLocation = safeMethod(item, "canBeEquipped") or ""
    return table.concat({ fullType, itemType, displayCategory, category, name, bodyLocation, equipLocation }, " ")
end

local function isType(item, className)
    return item ~= nil and instanceof ~= nil and instanceof(item, className)
end


local function isClothingLike(item)
    if isType(item, "Clothing") then return true end
    if safeMethod(item, "IsClothing") == true then return true end
    local bodyLocation = safeMethod(item, "getBodyLocation")
    if bodyLocation and tostring(bodyLocation) ~= "" and tostring(bodyLocation) ~= "nil" then return true end
    if safeMethod(item, "IsInventoryContainer") == true then
        local equipLocation = safeMethod(item, "canBeEquipped")
        if equipLocation and tostring(equipLocation) ~= "" and tostring(equipLocation) ~= "nil" then return true end
    end
    return false
end

local function fromDisplayCategory(item)
    local displayCategory = safeMethod(item, "getDisplayCategory")
    local mapped = displayCategoryMap[normalize(displayCategory)]
    if mapped then return mapped end
    return nil
end

local farmingSupplyNeedles = { "SeedPacket", "SeedBag", "Seed", "Seeds", "Fertilizer", "Compost", "FishingRod", "FishingLine", "FishingTackle", "FishingHook" }
local ammoSupplyNeedles = { "Ammo", "Bullets", "Shells", "GunMagazine", "MagazineAmmo", "Rounds", "Cartridge", "Ammocase", "9mm", "ShotgunShell", "RifleRound" }
local medicalSupplyNeedles = { "SutureNeedle", "Suture", "Bandage", "Pills", "Antibiotics", "Disinfectant", "AlcoholWipes", "Splint", "FirstAid", "Tweezers", "Scalpel", "Medical", "Wound", "Poultice" }
local vehicleSupplyNeedles = { "CarBattery", "BatteryCharger", "SparkPlug", "LugWrench", "Jack", "GasCan", "EngineParts", "Tire", "Brake", "Suspension", "Muffler", "Windshield", "Mechanic" }
local cookingSupplyNeedles = { "KitchenKnife" }
local bookNeedles = { "Book", "Newspaper", "Journal", "Map", "Recipe", "Magazine", "Literature", "Notebook", "SheetPaper", "SkillBook", "Comic", "RecipeResource" }
local toolNeedles = { "Tool", "Hammer", "Screwdriver", "Saw", "Wrench", "Crowbar", "Shovel", "PickAxe", "Pickaxe", "Torch", "BlowTorch", "Welding", "Jack", "LugWrench", "Needle", "Scissors", "FishingRod", "Trap", "Camping", "Lantern", "AxeStone", "HandAxe", "WoodAxe" }
local weaponNeedles = { "Gun", "Rifle", "Pistol", "Shotgun", "Axe", "Knife", "Spear", "Machete", "BaseballBat", "Weapon", "Blade", "Club", "Sledgehammer", "Katana", "Bow", "Crossbow" }

local function isFarmingSupply(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "gardening" then return true end
    return containsAny(text, farmingSupplyNeedles)
end

local function isAmmoSupply(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "ammo" or displayCategory == "explosives" then return true end
    return containsAny(text, ammoSupplyNeedles)
end

local function isMedicalSupply(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "firstaid" or displayCategory == "wound" or displayCategory == "bandage" then return true end
    return containsAny(text, medicalSupplyNeedles)
end

local function isVehicleSupply(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "vehiclemaintenance" then return true end
    return containsAny(text, vehicleSupplyNeedles)
end

local function isCookingSupply(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "cooking" or displayCategory == "cookingweapon" or displayCategory == "watercontainer" or displayCategory == "household" then return true end
    return containsAny(text, cookingSupplyNeedles)
end

local function isBookLike(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "reciperesource" or displayCategory == "literature" or displayCategory == "skillbook" then return true end
    return containsAny(text, bookNeedles)
end

local function isToolLike(item, text)
    local displayCategory = normalize(safeMethod(item, "getDisplayCategory"))
    if displayCategory == "tool" or displayCategory == "toolweapon" or displayCategory == "camping" then return true end
    return containsAny(text, toolNeedles)
end

function ZCSMP.ItemCategories.GetCategory(item)
    if not item then return nil end

    if isType(item, "Food") or safeMethod(item, "IsFood") == true then return "Food" end
    if isClothingLike(item) then return "Clothing" end

    local text = getTypeText(item)
    if isFarmingSupply(item, text) then return "Farming" end
    if isAmmoSupply(item, text) then return "Ammo" end
    if isMedicalSupply(item, text) then return "Medical" end
    if isVehicleSupply(item, text) then return "Vehicle" end
    if isCookingSupply(item, text) then return "Cooking" end

    local mapped = fromDisplayCategory(item)
    if mapped then return mapped end

    if isBookLike(item, text) then return "Books" end
    if isToolLike(item, text) then return "Tools" end

    if isType(item, "HandWeapon") then return "Weapons" end

    if containsAny(text, { "Seed", "Fertilizer", "Compost", "GardeningSpray", "WateringCan", "Trowel", "Hoe", "Garden", "Farming" }) then return "Farming" end
    if containsAny(text, ammoSupplyNeedles) then return "Ammo" end
    if containsAny(text, medicalSupplyNeedles) then return "Medical" end
    if containsAny(text, weaponNeedles) then return "Weapons" end
    if containsAny(text, { "Material", "Plank", "Nails", "Screws", "SheetMetal", "MetalBar", "MetalPipe", "Log", "Concrete", "Wire", "DuctTape", "Glue", "Twine", "Rope", "Thread", "Yarn", "Leather", "Denim", "Cotton", "Scrap", "Paint", "Tarp", "Burlap", "Charcoal", "Clay", "Brick", "Stone", "Glass" }) then return "Materials" end
    if containsAny(text, { "Clothing", "Shirt", "TShirt", "Trousers", "Pants", "Jacket", "Shoes", "Boots", "Socks", "Hat", "Cap", "Beanie", "Gloves", "Vest", "Helmet", "Bag", "Backpack", "Satchel", "Duffel", "Mask", "Glasses", "Goggles", "Scarf", "Tie", "Dress", "Skirt", "Suit", "Apron", "Underwear", "LongJohns", "Bra", "Briefs", "Bikini", "Swimsuit", "Belt", "Holster", "FannyPack", "Purse", "Wallet", "Poncho", "Hoodie", "Sweater", "Jumper", "Coat", "Robe", "Overalls", "Watch", "Necklace", "Ring", "Bracelet", "Earring" }) then return "Clothing" end
    if containsAny(text, { "Electronics", "Radio", "Walkie", "Remote", "Battery", "Generator", "LightBulb", "Amplifier", "Headphones", "Camera", "Phone", "TV", "Speaker", "Microphone", "Receiver", "Transmitter", "Antenna", "AlarmClock", "Digital" }) then return "Electronics" end
    if containsAny(text, { "Vehicle", "Car", "Engine", "Trunk" }) or containsAny(text, vehicleSupplyNeedles) then return "Vehicle" end
    if containsAny(text, { "Cooking", "Pot", "Pan", "Bowl", "Mug", "KitchenKnife", "Spoon", "Fork", "Plate", "RollingPin", "CanOpener", "Saucepan", "Kettle", "Skillet", "Griddle", "RoastingPan", "Baking", "Thermos", "Bottle", "Cup" }) then return "Cooking" end
    if containsAny(text, { "Trash", "Junk", "Garbage", "Empty", "Broken", "RippedSheetsDirty", "Dirt", "Corpse", "ZedDmg", "Rotten", "Burnt" }) then return "Trash" end

    return nil
end
