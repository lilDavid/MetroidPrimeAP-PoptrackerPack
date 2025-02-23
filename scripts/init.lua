DEBUG = true
ENABLE_DEBUG_LOG = true
IS_ITEMS_ONLY = Tracker.ActiveVariantUID == "var_itemsonly"

ScriptHost:LoadScript("scripts/utils.lua")
ScriptHost:LoadScript("scripts/progressivebeams.lua")
ScriptHost:LoadScript("scripts/logic/logic.lua")

Tracker:AddItems("items/items.json")
Tracker:AddItems("items/options.json")
Tracker:AddItems("items/tricks.json")
Tracker:AddItems("items/elevators.json")
Tracker:AddItems("items/doors.json")
Tracker:AddItems("items/tracker_options.json")

Tracker:AddMaps("maps/maps.json")

Tracker:AddLocations("locations/door_types.json")
Tracker:AddLocations("locations/rules.json")
Tracker:AddLocations("locations/chozo.json")
Tracker:AddLocations("locations/phen.json")
Tracker:AddLocations("locations/tallon.json")
Tracker:AddLocations("locations/mines.json")
Tracker:AddLocations("locations/magmoor.json")
Tracker:AddLocations("locations/maps.json")

Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/maps.json")
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")
Tracker:AddLayouts("layouts/options.json")
Tracker:AddLayouts("layouts/tracker_options.json")

if PopVersion and PopVersion >= "0.18.0" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
end