-- Utils

function has(item, n)
    local count = Tracker:ProviderCountForCode(item)
    if n == nil then
        n = 1
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

function can_power_beam()
    return has_any({"PowerBeam", "ProgressivePowerBeam"})
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

function can_missile()
    if has("MainMissile") then
        return has("MissileLauncher")
    end
    return has("MissileExpansion")
end

function can_super_missile()
    return can_power_beam()
        and can_missile()
        and (has_all({"ChargeBeam", "SuperMissile"})
            or has("ProgressivePowerBeam", 3))
end

function can_wave_beam()
    return has_any({"WaveBeam", "ProgressiveWaveBeam"})
end

function can_ice_beam()
    return has_any({"IceBeam", "ProgressiveIceBeam"})
end

function can_plasma_beam()
    return has_any({"PlasmaBeam", "ProgressivePlasmaBeam"})
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

function can_xray(hard_required)
    if hard_required then
        return has("XRayVisor")
    elseif has("RemoveXRayRequirements") then
        return true
    end
    return has("XRayVisor")
end

function can_thermal(hard_required)
    if hard_required then
        return has("ThermalVisor")
    elseif has("RemoveThermalRequirements") then
        return true
    end
    return has("ThermalVisor")
end

function can_move_underwater()
    return has("GravitySuit")
end

function can_charge_beam(required_beam)
    if required_beam then
        local progressive_beam = "Progressive" .. required_beam
        return has_all({"ChargeBeam", required_beam}) or has(progressive_beam, 2)
    end

    -- If no beam is required, check for Charge Beam or 2 of any progressive beam
    if has("ChargeBeam") then
        return true
    end
    for _, beam in {"PowerBeam", "WaveBeam", "IceBeam", "PlasmaBeam"} do
        if has("Progressive" .. beam, 2) then
            return true
        end
    end
    return false
end

function can_scan()
    return has("ScanVisor")
end

function can_heat()
    -- Varia required despite setting to make Gravity and Phazon work?
    return has("VariaSuit")
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
    if has("CombatLogicNone") then
        return true
    elseif has("CombatLogicMinimal") then
        return has_energy_tanks(minimal_tanks) and (can_charge_beam() or not requires_charge_beam)
    elseif has("CombatLogicNormal") then
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
    if has("CombatLogicNone") then
        return true
    elseif has("CombatLogicMinimal") then
        return can_plasma_beam() or can_power_beam() or can_wave_beam()
    elseif has("CombatLogicNormal") then
        return has_energy_tanks(3) and (can_charge_beam() and (can_plasma_beam() or can_power_beam()))
    end
end

function can_combat_omega_pirate()
    return can_combat_generic(6, 3)
end

function can_combat_flaaghra()
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
    if has("CombatLogicNone") then
        return true
    elseif has("CombatLogicMinimal") then
        return can_power_beam()
    elseif has("CombatLogicNormal") then
        return can_charge_beam("PowerBeam") and can_power_beam() and can_xray(true)
    end
end


-- Regions

function can_access_elevators()
    if has("PreScanElevators") then
        return true
    end
    return can_scan()
end


-- Data/ChozoRuins

function can_exit_ruined_shrine()
    return can_morph_ball() or can_space_jump()
end

function can_climb_sun_tower()
    return can_spider() and can_super_missile() and can_bomb()
end

function can_climb_tower_of_light()
    return (can_missile() and has("MissileExpansion", 8) and can_space_jump())
end


-- Data/TallonOverworld

function can_crashed_frigate()
    return (can_bomb() and can_space_jump() and can_wave_beam() and can_move_underwater() and can_thermal())
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