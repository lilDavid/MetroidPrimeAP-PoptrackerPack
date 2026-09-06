function BeamWatcher(combo_code)
    return function(code)
        local progressivebeams = Tracker:FindObjectForCode("ProgressiveBeams")
        local beam = Tracker:FindObjectForCode(code)
        local combo = Tracker:FindObjectForCode(combo_code)
        if progressivebeams == nil then
            return
        end
        if beam == nil then
            return
        end
        if combo == nil then
            return
        end

        if progressivebeams.Active then
            combo.Active = beam.CurrentStage == 3
        else
            if beam.CurrentStage > 1 then
                beam.CurrentStage = 1
            end
        end
    end
end

function ChargeComboWatcher(beam_code)
    return function(code)
        local progressivebeams = Tracker:FindObjectForCode("ProgressiveBeams")
        local beam = Tracker:FindObjectForCode(beam_code)
        local combo = Tracker:FindObjectForCode(code)
        if progressivebeams == nil or not progressivebeams.Active then
            return
        end
        if beam == nil then
            return
        end
        if combo == nil then
            return
        end

        if combo.Active and beam.CurrentStage < 3 then
            beam.CurrentStage = 3
        end
        if not combo.Active and beam.CurrentStage == 3 then
            beam.CurrentStage = 2
        end
    end
end

ScriptHost:AddWatchForCode("ProgPower", "PowerBeam", BeamWatcher("SuperMissile"))
ScriptHost:AddWatchForCode("ProgWave", "WaveBeam", BeamWatcher("Wavebuster"))
ScriptHost:AddWatchForCode("ProgIce", "IceBeam", BeamWatcher("IceSpreader"))
ScriptHost:AddWatchForCode("ProgPlasma", "PlasmaBeam", BeamWatcher("Flamethrower"))

ScriptHost:AddWatchForCode("ProgSupers", "SuperMissile", ChargeComboWatcher("PowerBeam"))
ScriptHost:AddWatchForCode("ProgBuster", "WaveBuster", ChargeComboWatcher("WaveBeam"))
ScriptHost:AddWatchForCode("ProgSpreader", "IceSpreader", ChargeComboWatcher("IceBeam"))
ScriptHost:AddWatchForCode("ProgFlamethrower", "Flamethrower", ChargeComboWatcher("PlasmaBeam"))
