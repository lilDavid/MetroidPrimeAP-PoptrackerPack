VARIABLE_MAPPING = {
    ["current_world"] = function(name, value)
        local level = LEVEL_MAPPING[value]
        if not level then return nil end
        Tracker:UiHint("ActivateTab", level)
        return level
    end,
}