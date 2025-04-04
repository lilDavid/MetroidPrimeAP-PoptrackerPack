-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_ITEM_TRACKING = true
AUTOTRACKER_ENABLE_LOCATION_TRACKING = not IS_ITEMS_ONLY
AUTOTRACKER_ENABLE_LEVEL_TRACKING = not IS_ITEMS_ONLY
AUTOTRACKER_ENABLE_DEBUG_LOGGING = ENABLE_DEBUG_LOG
AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP = AUTOTRACKER_ENABLE_DEBUG_LOGGING
-------------------------------------------------------
print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
print("Enable Location Tracking:    ", AUTOTRACKER_ENABLE_LOCATION_TRACKING)
print("Enable Level Tracking:    ", AUTOTRACKER_ENABLE_LEVEL_TRACKING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
    print("Enable Debug Logging:        ", AUTOTRACKER_ENABLE_DEBUG_LOGGING)
    print("Enable AP Debug Logging:        ", AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP)
end
print("---------------------------------------------------------------------")
print("")

ScriptHost:LoadScript("scripts/autotracking/archipelago.lua")
ScriptHost:LoadScript("scripts/autotracking/uat.lua")
