-- UAT example pack by black_sliver
-- autotracking.lua

-- For this demo we named the item codes and location section identical to the game variables.
-- Note that codes and variable names are case sensitive.
--
-- The return value of :ReadVariable can be anything, so we check the type and
-- * for toggles accept nil, false, integers <= 0 and empty strings as `false`
-- * for consumables everything that is not a number will be 0
-- * for progressive toggles we expect json [bool,number] or [number,number]
-- * for chests this is left as an exercise for the reader
-- Alternatively try-catch (pcall) can be used to handle unexpected values.

ScriptHost:LoadScript("scripts/autotracking/uat/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/uat/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/uat/variable_mapping.lua")

local updateToggles = function(store, vars)
    print("updateToggles")
    for _, var in ipairs(vars) do
        local item_name = UAT_ITEM_MAPPING[var]
        local o = Tracker:FindObjectForCode(item_name)
        local val = store:ReadVariable(var)
        ---@cast o JsonItem
        if type(val) == "number" then o.Active = val > 0
        elseif type(val) == "string" then o.Active = val ~= ""
        else o.Active = not(not val)
        end
        print(var .. " = " .. tostring(val) .. " -> " .. tostring(o.Active))
    end
end

local updateConsumables = function(store, vars)
    print("updateConsumables")
    for _, var in ipairs(vars) do
        local item_name = UAT_ITEM_MAPPING[var]
        local o = Tracker:FindObjectForCode(item_name)
        local val = store:ReadVariable(var)
        ---@cast o JsonItem
        if type(val) == "number" then o.AcquiredCount = val
        else o.AcquiredCount = 0
        end
        print(var .. " = " .. tostring(val) .. " -> " .. o.AcquiredCount)
    end
end

local updateProgressiveToggles = function(store, vars)
    print("updateProgressiveToggles")
    for _, var in ipairs(vars) do
        local item_name = UAT_ITEM_MAPPING[var]
        local o = Tracker:FindObjectForCode(item_name)
        local val = store:ReadVariable(var)
        ---@cast o JsonItem
        if type(val) == "number" then
            o.Active = val > 0
            o.CurrentStage = val
        else
            o.Active = false
        end
        print(var .. " = " .. tostring(val) .. " -> " .. tostring(o.Active) .. "," .. o.CurrentStage)
    end
end

local artifacts = {}

local updateArtifacts = function(store, vars)
    print("updateArtifacts")
    for _, var in ipairs(vars) do
        local val = store:ReadVariable(var)
        artifacts[var] = type(val) == "number" and val > 0 or type(val) == "boolean" and val
        print(var .. " = " .. tostring(val) .. " -> " .. artifacts[var])
    end
    local o = Tracker:FindObjectForCode("Artifacts")
    if o == nil then return end
    o.AcquiredCount = 0
    for _, acquired in pairs(artifacts) do
        if acquired then
            o.AcquiredCount = o.AcquiredCount + 1
        end
    end
end

local updateLocations = function(store, vars)
    print("updateLocations")
    for _, var in ipairs(vars) do
        local mapped_name = UAT_LOCATION_MAPPING[var]
        if mapped_name == nil then
            print(var .. ": Did not map to location name")
        else
            local o = Tracker:FindObjectForCode(mapped_name)
            local val = store:ReadVariable(var)
            -- If the pickup isn't already checked then set it
            if o ~= nil and o.AvailableChestCount ~= 0 and val then
                o.AvailableChestCount = 0
                print(var .. " = " .. tostring(val) .. " -> " .. mapped_name)
            end
        end
    end
end

local updateVariables = function(store, vars)
    for _, var in ipairs(vars) do
        local val = store:ReadVariable(var)
        local fn = UAT_VARIABLE_MAPPING[var]
        if fn then
            local result = fn(var, val)
            print(var .. " = " .. tostring(val) .. " -> " .. tostring(result))
        end
    end
end

if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    ScriptHost:AddVariableWatch("toggles", {
        "inventory/Scan Visor",
        "inventory/Morph Ball Bomb",
        "inventory/Flamethrower",
        "inventory/Thermal Visor",
        "inventory/Charge Beam",
        "inventory/Super Missile",
        "inventory/Grapple Beam",
        "inventory/X-Ray Visor",
        "inventory/Ice Spreader",
        "inventory/Space Jump Boots",
        "inventory/Morph Ball",
        "inventory/Boost Ball",
        "inventory/Spider Ball",
        "inventory/Gravity Suit",
        "inventory/Varia Suit",
        "inventory/Phazon Suit",
        "inventory/Wavebuster",
    }, updateToggles)
    ScriptHost:AddVariableWatch("consumables", {
        "inventory/Missile",
        "inventory/Power Bomb",
        "inventory/Energy Tank",
    }, updateConsumables)
    ScriptHost:AddVariableWatch("artifacts", {
        "inventory/Artifact of Truth",
        "inventory/Artifact of Strength",
        "inventory/Artifact of Elder",
        "inventory/Artifact of Wild",
        "inventory/Artifact of Lifegiver",
        "inventory/Artifact of Warrior",
        "inventory/Artifact of Chozo",
        "inventory/Artifact of Nature",
        "inventory/Artifact of Sun",
        "inventory/Artifact of World",
        "inventory/Artifact of Spirit",
        "inventory/Artifact of Newborn",
    }, updateArtifacts)
    ScriptHost:AddVariableWatch("progressive", {
        "inventory/Power Beam",
        "inventory/Ice Beam",
        "inventory/Wave Beam",
        "inventory/Plasma Beam",
    }, updateProgressiveToggles)
end
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    ScriptHost:AddVariableWatch("locations", {
        "pickups/Chozo Ruins/Main Plaza/Half-Pipe",
        "pickups/Chozo Ruins/Main Plaza/Grapple Ledge",
        "pickups/Chozo Ruins/Main Plaza/Tree",
        "pickups/Chozo Ruins/Main Plaza/Locked Door",
        "pickups/Chozo Ruins/Ruined Fountain",
        "pickups/Chozo Ruins/Ruined Shrine/Plated Beetle",
        "pickups/Chozo Ruins/Ruined Shrine/Half-Pipe",
        "pickups/Chozo Ruins/Ruined Shrine/Lower Tunnel",
        "pickups/Chozo Ruins/Vault",
        "pickups/Chozo Ruins/Training Chamber",
        "pickups/Chozo Ruins/Ruined Nursery",
        "pickups/Chozo Ruins/Training Chamber Access",
        "pickups/Chozo Ruins/Magma Pool",
        "pickups/Chozo Ruins/Tower of Light",
        "pickups/Chozo Ruins/Tower Chamber",
        "pickups/Chozo Ruins/Ruined Gallery/Missile Wall",
        "pickups/Chozo Ruins/Ruined Gallery/Tunnel",
        "pickups/Chozo Ruins/Transport Access North",
        "pickups/Chozo Ruins/Gathering Hall",
        "pickups/Chozo Ruins/Hive Totem",
        "pickups/Chozo Ruins/Sunchamber/Flaahgra",
        "pickups/Chozo Ruins/Sunchamber/Ghosts",
        "pickups/Chozo Ruins/Watery Hall Access",
        "pickups/Chozo Ruins/Watery Hall/Scan Puzzle",
        "pickups/Chozo Ruins/Watery Hall/Underwater",
        "pickups/Chozo Ruins/Dynamo/Lower",
        "pickups/Chozo Ruins/Dynamo/Spider Track",
        "pickups/Chozo Ruins/Burn Dome/Missile",
        "pickups/Chozo Ruins/Burn Dome/Incinerator Drone",
        "pickups/Chozo Ruins/Furnace/Spider Tracks",
        "pickups/Chozo Ruins/Furnace/Inside Furnace",
        "pickups/Chozo Ruins/Hall of the Elders",
        "pickups/Chozo Ruins/Crossway",
        "pickups/Chozo Ruins/Elder Chamber",
        "pickups/Chozo Ruins/Antechamber",
        "pickups/Phendrana Drifts/Phendrana Shorelines/Behind Ice",
        "pickups/Phendrana Drifts/Phendrana Shorelines/Spider Track",
        "pickups/Phendrana Drifts/Chozo Ice Temple",
        "pickups/Phendrana Drifts/Ice Ruins West",
        "pickups/Phendrana Drifts/Ice Ruins East/Behind Ice",
        "pickups/Phendrana Drifts/Ice Ruins East/Spider Track",
        "pickups/Phendrana Drifts/Chapel of the Elders",
        "pickups/Phendrana Drifts/Ruined Courtyard",
        "pickups/Phendrana Drifts/Phendrana Canyon",
        "pickups/Phendrana Drifts/Quarantine Cave",
        "pickups/Phendrana Drifts/Research Lab Hydra",
        "pickups/Phendrana Drifts/Quarantine Monitor",
        "pickups/Phendrana Drifts/Observatory",
        "pickups/Phendrana Drifts/Transport Access",
        "pickups/Phendrana Drifts/Control Tower",
        "pickups/Phendrana Drifts/Research Core",
        "pickups/Phendrana Drifts/Frost Cave",
        "pickups/Phendrana Drifts/Research Lab Aether/Tank",
        "pickups/Phendrana Drifts/Research Lab Aether/Morph Track",
        "pickups/Phendrana Drifts/Gravity Chamber/Underwater",
        "pickups/Phendrana Drifts/Gravity Chamber/Grapple Ledge",
        "pickups/Phendrana Drifts/Storage Cave",
        "pickups/Phendrana Drifts/Security Cave",
        "pickups/Tallon Overworld/Landing Site",
        "pickups/Tallon Overworld/Alcove",
        "pickups/Tallon Overworld/Frigate Crash Site",
        "pickups/Tallon Overworld/Overgrown Cavern",
        "pickups/Tallon Overworld/Root Cave",
        "pickups/Tallon Overworld/Artifact Temple",
        "pickups/Tallon Overworld/Transport Tunnel B",
        "pickups/Tallon Overworld/Arbor Chamber",
        "pickups/Tallon Overworld/Cargo Freight Lift to Deck Gamma",
        "pickups/Tallon Overworld/Biohazard Containment",
        "pickups/Tallon Overworld/Hydro Access Tunnel",
        "pickups/Tallon Overworld/Great Tree Chamber",
        "pickups/Tallon Overworld/Life Grove Tunnel",
        "pickups/Tallon Overworld/Life Grove/Start",
        "pickups/Tallon Overworld/Life Grove/Underwater Spinner",
        "pickups/Phazon Mines/Main Quarry",
        "pickups/Phazon Mines/Security Access A",
        "pickups/Phazon Mines/Storage Depot B",
        "pickups/Phazon Mines/Storage Depot A",
        "pickups/Phazon Mines/Elite Research/Phazon Elite",
        "pickups/Phazon Mines/Elite Research/Laser",
        "pickups/Phazon Mines/Elite Control Access",
        "pickups/Phazon Mines/Ventilation Shaft",
        "pickups/Phazon Mines/Phazon Processing Center",
        "pickups/Phazon Mines/Processing Center Access",
        "pickups/Phazon Mines/Elite Quarters",
        "pickups/Phazon Mines/Central Dynamo",
        "pickups/Phazon Mines/Metroid Quarantine B",
        "pickups/Phazon Mines/Metroid Quarantine A",
        "pickups/Phazon Mines/Fungal Hall B",
        "pickups/Phazon Mines/Phazon Mining Tunnel",
        "pickups/Phazon Mines/Fungal Hall Access",
        "pickups/Magmoor Caverns/Lava Lake",
        "pickups/Magmoor Caverns/Triclops Pit",
        "pickups/Magmoor Caverns/Storage Cavern",
        "pickups/Magmoor Caverns/Transport Tunnel A",
        "pickups/Magmoor Caverns/Warrior Shrine",
        "pickups/Magmoor Caverns/Shore Tunnel",
        "pickups/Magmoor Caverns/Fiery Shores/Morph Track",
        "pickups/Magmoor Caverns/Fiery Shores/Warrior Shrine Tunnel",
        "pickups/Magmoor Caverns/Plasma Processing",
        "pickups/Magmoor Caverns/Magmoor Workstation",
    }, updateLocations)
end
if AUTOTRACKER_ENABLE_LEVEL_TRACKING then
    ScriptHost:AddVariableWatch("variables", {
        "Current Area"
    }, updateVariables)
end
