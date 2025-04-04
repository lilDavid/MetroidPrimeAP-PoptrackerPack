VARIABLE_MAPPING = {
    ["Current Area"] = function(name, value)
        local level = value
        if not level then return nil end
        local auto_tab = Tracker:FindObjectForCode("AutoTab")
        if auto_tab == nil  or not auto_tab.Active then return nil end
        Tracker:UiHint("ActivateTab", level)
        return level
    end,
}