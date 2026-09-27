DEBUG = false
ENABLE_DEBUG_LOG = DEBUG
IS_ITEMS_ONLY = Tracker.ActiveVariantUID == "var_itemsonly"

Tracker:AddItems("items/items.json")
Tracker:AddItems("items/options.json")
Tracker:AddItems("items/elevators.json")
Tracker:AddItems("items/doors.json")
Tracker:AddItems("items/tracker_options.json")

if not IS_ITEMS_ONLY then
    Tracker:AddMaps("maps/maps.json")

    Tracker:AddLocations("locations/door_types.json")
    Tracker:AddLocations("locations/rules.json")
    Tracker:AddLocations("locations/chozo.json")
    Tracker:AddLocations("locations/phen.json")
    Tracker:AddLocations("locations/tallon.json")
    Tracker:AddLocations("locations/mines.json")
    Tracker:AddLocations("locations/magmoor.json")
    Tracker:AddLocations("locations/maps.json")
    Tracker:AddLocations("locations/blast_shields.json")

    ScriptHost:AddWatchForCode("SplitMapWatcher", "SplitMap", function(code)
        if Tracker:ProviderCountForCode(code) > 0 then
            Tracker:AddLayouts("layouts/maps_split.json")
        else
            Tracker:AddLayouts("layouts/maps.json")
        end
    end)
    Tracker:AddLayouts("layouts/maps.json")
    Tracker:AddLayouts("layouts/tricks.json")
    Tracker:AddLayouts("layouts/tracker_options.json")
end

Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")
Tracker:AddLayouts("layouts/options.json")

ScriptHost:LoadScript("scripts/utils.lua")

ScriptHost:LoadScript("scripts/options/goal.lua")
ScriptHost:LoadScript("scripts/options/requiredmains.lua")
ScriptHost:LoadScript("scripts/options/progressivebeams.lua")

if not IS_ITEMS_ONLY then
    ScriptHost:LoadScript("scripts/options/tricks.lua")

    ScriptHost:LoadScript("scripts/logic/logic.lua")
    ScriptHost:LoadScript("scripts/logic/door_data.lua")
    ScriptHost:LoadScript("scripts/logic/blast_shield_rando.lua")
end

if PopVersion and PopVersion >= "0.18.0" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
end
