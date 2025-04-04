VARIABLE_MAPPING = {
    ["Current Area"] = function(name, value)
        local level = value
        if not level then return nil end
        Tracker:UiHint("ActivateTab", level)
        return level
    end,
}