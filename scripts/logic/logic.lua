-- Utils

function has(item, n)
    local obj = Tracker:FindObjectForCode(item)
    if obj == nil then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("has: unrecognized item %s", item))
        end
        return false
    end
    if n == nil then
        n = 1
    end
    local count
    if obj.Type == "progressive" then
        count = obj.CurrentStage
    elseif obj.Type == "consumable" then
        count = obj.AcquiredCount
    elseif obj.Active then
        count = 1
    else
        count = 0
    end
    return (count >= tonumber(n))
end

function has_all(items)
    for _, item in ipairs(items) do
        if not has(item) then
            return false
        end
    end
    return true
end

function has_any(items)
    for _, item in ipairs(items) do
        if has(item) then
            return true
        end
    end
    return false
end

function trick(id, difficulty)
    local trick_item = Tracker:FindObjectForCode(id)
    if trick_item == nil then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("trick: unrecognized id %s", id))
        end
        return false
    end
    if trick_item.CurrentStage == 0 then return false end
    if trick_item.CurrentStage == 2 then return true end
    return has("Tricks", tonumber(difficulty))
end


-- Logic

function has_required_artifact_count()
    local requirement = Tracker:ProviderCountForCode("RequiredArtifacts")
    local count = Tracker:ProviderCountForCode("Artifacts")
    return (tonumber(count) >= tonumber(requirement))
end

function can_boost()
    return has_all({"MorphBall", "BoostBall"})
end

function can_bomb()
    return has_all({"MorphBall", "Bombs"})
end

function can_beam(beam)
    return has(beam)
end

function can_power_beam()
    return can_beam("PowerBeam")
end

function can_power_bomb()
    if has("MainPowerBomb") then
        return has_all({"MorphBall", "PowerBomb"})
    end
    return has_all({"MorphBall", "PowerBombExpansion"})
end

function can_spider()
    return has_all({"MorphBall", "SpiderBall"})
end

function can_missile(expansions)
    if expansions == nil or expansions < 1 then expansions = 1 end
    local count = 5 * expansions
    if has("MainMissile") then
        return has("MissileLauncher") and has("MissileExpansion", count - 1)
    end
    return has("MissileExpansion", count)
end

function can_super_missile()
    local beam_requirement
    if has("ProgressiveBeams") then beam_requirement = has("PowerBeam", 3)
    else beam_requirement = has_all({"ChargeBeam", "SuperMissile"}) end
    return can_power_beam() and can_missile() and beam_requirement
end

function can_wave_beam()
    return can_beam("WaveBeam")
end

function can_ice_beam()
    return can_beam("IceBeam")
end

function can_plasma_beam()
    return can_beam("PlasmaBeam")
end

function can_melt_ice()
    return can_plasma_beam()
end

function can_grapple()
    return has("GrappleBeam")
end

function can_space_jump()
    return has("SpaceJump")
end

function can_morph_ball()
    return has("MorphBall")
end

function can_xray(requirement)
    if requirement == nil then
        requirement = 0
    else
        requirement = tonumber(requirement)
    end
    local remove_xray_reqs = Tracker:FindObjectForCode("RemoveXRayRequirements").CurrentStage
    if has("XRayVisor") then return AccessibilityLevel.Normal end
    if requirement == 2 then return AccessibilityLevel.None end
    if remove_xray_reqs > requirement then return AccessibilityLevel.Normal end
    return AccessibilityLevel.SequenceBreak
end

function can_thermal(requirement)
    if requirement == nil then
        requirement = 0
    else
        requirement = tonumber(requirement)
    end
    local remove_thermal_reqs = Tracker:FindObjectForCode("RemoveThermalRequirements").CurrentStage
    if has("ThermalVisor") then return AccessibilityLevel.Normal end
    if requirement == 2 then return AccessibilityLevel.None end
    if remove_thermal_reqs > requirement then return AccessibilityLevel.Normal end
    return AccessibilityLevel.SequenceBreak
end

function can_move_underwater()
    return has("GravitySuit")
end

function can_charge_beam(required_beam)
    if required_beam then
        if has("ProgressiveBeams") then return has(required_beam, 2)
        else return has_all({"ChargeBeam", required_beam}) end
    end

    -- If no beam is required, check for Charge Beam or 2 of any progressive beam
    if has("ProgressiveBeams") then
        for _, beam in ipairs({"PowerBeam", "WaveBeam", "IceBeam", "PlasmaBeam"}) do
            if has(beam, 2) then return true end
        end
    end
    return has("ChargeBeam")
end

function can_charge_combo(required_beam)
    if not can_missile(2) or not can_charge_beam(required_beam) then
        return false
    end

    if required_beam == "WaveBeam" then
        return can_missile(3) and has("Wavebuster")
    end
    if required_beam == "IceBeam" then
        return has("IceSpreader")
    end
    if required_beam == "PlasmaBeam" then
        return can_missile(3) and has("Flamethrower")
    end
end

function can_scan()
    return has("ScanVisor")
end

function can_heat()
    if has("NonVariaHeatDamage") then
        return has("VariaSuit")
    end
    return has_any({"VariaSuit", "GravitySuit", "PhazonSuit"})
end

function can_phazon()
    return has("PhazonSuit")
end

function has_energy_tanks(n)
    return has("EnergyTank", n)
end

function can_infinite_speed()
    return can_boost() and can_bomb()
end

function can_defeat_sheegoth()
    return can_bomb() or can_missile() or can_power_bomb() or can_power_beam()
end

function can_backwards_lower_mines()
    return has("BackwardsLowerMines")
end

function has_power_bomb_count(required_count)
    local count = Tracker:ProviderCountForCode("PowerBombExpansion")
    if has("MainPowerBomb") then
        count = count + 4
    end
    return (count >= tonumber(required_count))
end


-- LogicCombat

function can_combat_generic(normal_tanks, minimal_tanks, requires_charge_beam)
    if requires_charge_beam == nil then
        requires_charge_beam = true
    end
    if has("CombatLogic", 2) then
        return true
    elseif has("CombatLogic", 1) then
        return has_energy_tanks(minimal_tanks) and (can_charge_beam() or not requires_charge_beam)
    else
        return has_energy_tanks(normal_tanks) and (can_charge_beam() or not requires_charge_beam)
    end
end

function can_combat_mines()
    return can_combat_generic(5, 3)
end

function can_combat_labs()
    return has_any({"StartingRoomEastTower", "StartingRoomSaveStationB"}) or can_combat_generic(1, 0, false)
end

function can_combat_thardus()
    -- Require charge and plasma or power for thardus on normal
    if has_any({"StartingRoomQuarantineMonitor", "StartingRoomSaveStationB"}) then
        return can_plasma_beam() or can_power_beam() or can_wave_beam()
    end
    if has("CombatLogic", 2) then
        return true
    elseif has("CombatLogic", 1) then
        return can_plasma_beam() or can_power_beam() or can_wave_beam()
    else
        return has_energy_tanks(3) and (can_charge_beam() and (can_plasma_beam() or can_power_beam()))
    end
end

function can_combat_omega_pirate()
    return can_combat_generic(6, 3)
end

function can_combat_flaahgra()
    return has("StartingRoomSunchamberLobby")
        or can_combat_generic(2, 1, false)
end

function can_combat_ridley()
    return can_combat_generic(8, 8)
end

function can_combat_prime()
    return can_combat_generic(8, 5)
end

function can_combat_ghosts()
    if has("CombatLogic", 2) then
        return true
    elseif has("CombatLogic", 1) then
        return can_power_beam()
    else
        return can_charge_beam("PowerBeam") and can_power_beam()
            and can_xray(1) == AccessibilityLevel.Normal
    end
end

function can_combat_beam_pirates(beam)
    if has("CombatLogic", 1) then
        return true
    end
    return has(beam)
end


-- Regions

function can_access_elevators()
    if has("PreScanElevators") then
        return true
    end
    return can_scan()
end


-- Data/ChozoRuins

function can_climb_sun_tower()
    return can_spider() and can_super_missile() and can_bomb()
end

function can_climb_tower_of_light()
    return (can_missile() and has("MissileExpansion", 8) and can_space_jump())
end


-- Data/TallonOverworld

function can_crashed_frigate_front()
    if not (can_morph_ball() and can_wave_beam() and (can_move_underwater() or can_space_jump())) then
        return AccessibilityLevel.None
    end
    return can_thermal()
end

function can_crashed_frigate()
    if not (can_bomb() and can_space_jump() and can_move_underwater()) then
        return AccessibilityLevel.None
    end
    return can_crashed_frigate_front()
end

function can_crashed_frigate_backwards()
    return (can_space_jump() and can_move_underwater() and can_bomb())
end


-- Data/PhendranaDrifts

function _can_reach_top_of_ruined_courtyard()
    return ((can_boost() and can_bomb() and can_scan()) or can_spider()) and can_space_jump()
end

function _can_climb_observatory_via_puzzle()
    return can_boost() and can_bomb() and can_space_jump() and can_scan()
end
