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

ScriptHost:AddWatchForCode("Settings handler", "*", function(code)
	local progressive_beams = Tracker:FindObjectForCode("ProgressiveBeams")
	local required_missile_launcher = Tracker:FindObjectForCode("RequiredMissileLauncher")
	local required_pb_launcher = Tracker:FindObjectForCode("RequiredPBLauncher")
	local charge_beam = Tracker:FindObjectForCode("ChargeBeam")
	local missile_launcher = Tracker:FindObjectForCode("MissileLauncher")
	local missile_expansion = Tracker:FindObjectForCode("MissileExpansion")
	local pb_launcher = Tracker:FindObjectForCode("PowerBomb")
	local pb_expansion = Tracker:FindObjectForCode("PowerBombExpansion")

    -- deactivate the charge beam icon if progressive beam is on
    if progressive_beams then
        local chargebeam = Tracker:FindObjectForCode("ChargeBeam")
        if chargebeam then
            if progressive_beams.CurrentStage == 1 then
                chargebeam.Icon = nil
            else
                chargebeam.Icon = "images/items/chargebeam.png:@disabled"
            end
        end
    end

    -- detect if required missile launcher is on and activate the missile launcher icon
    if required_missile_launcher and required_missile_launcher.CurrentStage == 0 then
        if missile_launcher and missile_expansion then
            missile_launcher.Active = missile_expansion.AcquiredCount > 0
        end
    end

    -- detect if required power bomb launcher is on and activate the power bomb launcher icon
    if required_pb_launcher and required_pb_launcher.CurrentStage == 0 then
        if pb_launcher and pb_expansion then
            pb_launcher.Active = pb_expansion.AcquiredCount > 0
        end
    end
end)

-- loads the AP autotracking code
ScriptHost:LoadScript("scripts/autotracking/archipelago.lua")
