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
ScriptHost:LoadScript("scripts/autotracking/uat/variable_mapping.lua")

local updateToggles = function(store, vars)
    print("updateToggles")
    for _, var in ipairs(vars) do
        local item_name = ITEM_MAPPING[var]
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
        local item_name = ITEM_MAPPING[var]
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
        local o = Tracker:FindObjectForCode(var)
        local val = store:ReadVariable(var)
        ---@cast o JsonItem
        if type(val) == "table" and type(val[2]) == "number" then
            if type(val[1]) == "number" then o.Active = val[1]>0
            else o.Active = not(not val[1])
            end
            o.CurrentStage = val[2]
        else
            o.Active = false
        end
        print(var .. " = " .. tostring(val) .. " -> " .. tostring(o.Active) .. "," .. o.CurrentStage)
    end
end

local updateArtifacts = function(store, vars)
    print("updateProgressiveToggles")
    local o = Tracker:FindObjectForCode("Artifacts")
    if o == nil then return end
    o.AcquiredCount = 0
    for _, var in ipairs(vars) do
        local val = store:ReadVariable(var)
        local result = "+0"
        if type(val) == "number" and val > 0 or type(val) == "boolean" and val then
            o.AcquiredCount = o.AcquiredCount + 1
            result = "+1"
        end
        print(var .. " = " .. tostring(val) .. " -> " .. result)
    end
end

local updateLocations = function(store, vars)
    print("updateLocations")
    -- if the variable is not named the same as the location
    -- you'll have to map them to actual section names
    -- if you use one boolean per chest
    -- you'll have to sum them up or remember the old value
    for _, var in ipairs(vars) do
        local o = Tracker:FindObjectForCode("@"..var) -- grab section
        local val = store:ReadVariable(var)
        ---@cast o LocationSection
        o.AvailableChestCount = o.ChestCount - val -- in this case val = that many chests are looted
    end
end

local updateVariables = function(store, vars)
    for _, var in ipairs(vars) do
        local val = store:ReadVariable(var)
        local fn = VARIABLE_MAPPING[var]
        if fn then
            local result = fn(var, val)
            print(var .. " = " .. tostring(val) .. " -> " .. tostring(result))
        end
    end
end

ScriptHost:AddVariableWatch("toggles", {
    "inventory/power_beam",
    "inventory/ice_beam",
    "inventory/wave_beam",
    "inventory/plasma_beam",
    "inventory/scan_visor",
    "inventory/morph_ball_bomb",
    "inventory/flamethrower",
    "inventory/thermal_visor",
    "inventory/charge_beam",
    "inventory/super_missile",
    "inventory/grapple_beam",
    "inventory/xray_visor",
    "inventory/ice_spreader",
    "inventory/space_jump_boots",
    "inventory/morph_ball",
    "inventory/boost_ball",
    "inventory/spider_ball",
    "inventory/gravity_suit",
    "inventory/varia_suit",
    "inventory/phazon_suit",
    "inventory/wavebuster",
}, updateToggles)
ScriptHost:AddVariableWatch("consumables", {
    "inventory/missile_expansion",
    "inventory/power_bomb_expansion",
    "inventory/energy_tank",
}, updateConsumables)
ScriptHost:AddVariableWatch("artifacts", {
    "inventory/artifacts/truth",
    "inventory/artifacts/strength",
    "inventory/artifacts/elder",
    "inventory/artifacts/wild",
    "inventory/artifacts/lifegiver",
    "inventory/artifacts/warrior",
    "inventory/artifacts/chozo",
    "inventory/artifacts/nature",
    "inventory/artifacts/sun",
    "inventory/artifacts/world",
    "inventory/artifacts/spirit",
    "inventory/artifacts/newborn",
}, updateArtifacts)
-- ScriptHost:AddVariableWatch("progressive", {"c"}, updateProgressiveToggles)
-- ScriptHost:AddVariableWatch("locations", {"Example Location 1/Example Section 1"}, updateLocations)
ScriptHost:AddVariableWatch("variables", {
    "current_world"
}, updateVariables)
