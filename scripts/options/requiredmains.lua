function AddRequiredMainWatcher(require_main_code, launcher_code, expansion_code, launcher_ammo)
    local require_launcher = Tracker:FindObjectForCode(require_main_code)
    local launcher = Tracker:FindObjectForCode(launcher_code)
    local expansion = Tracker:FindObjectForCode(expansion_code)
    if require_launcher == nil or launcher == nil or expansion == nil then
        if ENABLE_DEBUG_LOG then
            print(string.format("Invalid code %s, %s, or %s"), require_main_code, launcher_code, expansion_code)
        end
        return nil
    end

    local option_watcher_name = "RequiredMains" .. require_main_code
    local launcher_watcher_name = "RequiredMains" .. launcher_code
    local expansion_watcher_name = "RequiredMains" .. expansion_code

    local option_status = nil
    local launcher_status = launcher.Active
    local ammo_count = expansion.AcquiredCount

    local function launcher_watcher(_)
        if launcher.Active == launcher_status then return end
        launcher_status = launcher.Active
        if launcher.Active then expansion.AcquiredCount = expansion.AcquiredCount + launcher_ammo
        else expansion.AcquiredCount = expansion.AcquiredCount - launcher_ammo end
    end

    local function expansion_watcher(_)
        if ammo_count == 0 and expansion.AcquiredCount > 0 then
            expansion.AcquiredCount = launcher_ammo
        end
        if ammo_count >= launcher_ammo and expansion.AcquiredCount < launcher_ammo then
            expansion.AcquiredCount = 0
        end
        ammo_count = expansion.AcquiredCount

        launcher_status = ammo_count > 0
        launcher.Active = launcher_status
    end

    local function option_watcher(_)
        if (require_launcher.CurrentStage > 0) == option_status then return end
        option_status = require_launcher.CurrentStage > 0
        if require_launcher.CurrentStage > 0 then
            ScriptHost:RemoveWatchForCode(expansion_watcher_name)
            ScriptHost:AddWatchForCode(launcher_watcher_name, launcher_code, launcher_watcher)
        else
            ScriptHost:RemoveWatchForCode(launcher_watcher_name)
            ScriptHost:AddWatchForCode(expansion_watcher_name, expansion_code, expansion_watcher)
            expansion_watcher()
        end
    end

    ScriptHost:AddWatchForCode(option_watcher_name, require_main_code, option_watcher)
    option_watcher()

    return option_watcher_name
end

AddRequiredMainWatcher("RequiredMissileLauncher", "MissileLauncher", "MissileExpansion", 5)
AddRequiredMainWatcher("RequiredPBLauncher", "PowerBomb", "PowerBombExpansion", 4)
