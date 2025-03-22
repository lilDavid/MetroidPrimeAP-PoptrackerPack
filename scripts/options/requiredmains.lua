function OptionWatcher(require_main_code, launcher_code, expansion_code)
    return function(_)
        local require_launcher = Tracker:FindObjectForCode(require_main_code)
        local launcher = Tracker:FindObjectForCode(launcher_code)
        local expansion = Tracker:FindObjectForCode(expansion_code)
        if require_launcher == nil or launcher == nil or expansion == nil then return end

        if require_launcher.CurrentStage == 0 then
            launcher.Active = expansion.AcquiredCount > 0
        end
    end
end

local MissileWatcher = OptionWatcher("RequiredMissileLauncher", "MissileLauncher", "MissileExpansion")
ScriptHost:AddWatchForCode("RequireMainMissile", "RequiredMissileLauncher", MissileWatcher)
ScriptHost:AddWatchForCode("RequireMainMissileLauncher", "MissileLauncher", MissileWatcher)
ScriptHost:AddWatchForCode("RequireMainMissileExpansion", "MissileExpansion", MissileWatcher)

local PowerBombWatcher = OptionWatcher("RequiredPBLauncher", "PowerBomb", "PowerBombExpansion")
ScriptHost:AddWatchForCode("RequireMainPowerBomb", "RequiredPBLauncher", PowerBombWatcher)
ScriptHost:AddWatchForCode("RequireMainPowerBombLauncher", "PowerBomb", PowerBombWatcher)
ScriptHost:AddWatchForCode("RequireMainPowerBombExpansion", "PowerBombExpansion", PowerBombWatcher)
