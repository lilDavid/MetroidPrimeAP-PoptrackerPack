TrickSetting = {
    DENY = -1,
    USE_GLOBAL = 0,
    ALLOW = 1,
}

TrickDifficulty = {
    EASY = 1,
    MEDIUM = 2,
    HARD = 3,
}

local global_difficulty = Tracker:FindObjectForCode("Tricks")

local difficulty_images = {
    [TrickDifficulty.EASY] = ImageReference:FromPackRelativePath("images/options/trick-easy.png"),
    [TrickDifficulty.MEDIUM] = ImageReference:FromPackRelativePath("images/options/trick-medium.png"),
    [TrickDifficulty.HARD] = ImageReference:FromPackRelativePath("images/options/trick-hard.png"),
}
local difficulty_images_green = {
    [TrickDifficulty.EASY] = ImageReference:FromPackRelativePath("images/options/trick-easy-green.png"),
    [TrickDifficulty.MEDIUM] = ImageReference:FromPackRelativePath("images/options/trick-medium-green.png"),
    [TrickDifficulty.HARD] = ImageReference:FromPackRelativePath("images/options/trick-hard-green.png"),
}
local setting_texts = {
    [TrickSetting.DENY] = "Denied",
    [TrickSetting.USE_GLOBAL] = "Using global trick setting",
    [TrickSetting.ALLOW] = "Allowed",
}

function TrickItem(name, difficulty, codes)
    local data = {
        name = name,
        difficulty = difficulty,
        codes = codes,
        item = ScriptHost:CreateLuaItem(),
    }

    data.item.Icon = ImageReference:FromPackRelativePath("images/options/helmet.png")
    data.item.ItemState = { setting = TrickSetting.USE_GLOBAL }

    function data.item.CanProvideCodeFunc(self, code)
        for _, id in ipairs(codes) do
            if id == code then return true end
        end
        return false
    end

    function data.item.ProvidesCodeFunc(self, code)
        if not self:CanProvideCodeFunc(code) then return false end
        if data.item.ItemState.setting >= TrickSetting.ALLOW then return true end
        if data.item.ItemState.setting <= TrickSetting.DENY then return false end
        if not difficulty then return data.item.ItemState.setting ~= TrickSetting.DENY end
        if not global_difficulty then return false end
        return global_difficulty.CurrentStage >= difficulty
    end

    function data.UpdateGfx(self)
        local mods = {}
        if self.item.ItemState.setting ~= TrickSetting.ALLOW then
            table.insert(mods, "@disabled")
        end
        if difficulty then
            if global_difficulty and global_difficulty.CurrentStage >= difficulty then
                table.insert(mods, "overlay|" .. difficulty_images_green[difficulty])
            else
                table.insert(mods, "overlay|" .. difficulty_images[difficulty])
            end
        end
        if self.item.ItemState.setting == TrickSetting.DENY then
            table.insert(mods, "overlay|" .. ImageReference:FromPackRelativePath("images/options/trick-denied.png"))
        end
        self.item.IconMods = table.concat(mods, ",")

        if difficulty then
            self.item.Name = setting_texts[self.item.ItemState.setting] or "Error"
        elseif self.item.ItemState.setting == TrickSetting.DENY then
            self.item.Name = "Don't show"
        else
            self.item.Name = "Show as sequence break"
        end
    end

    local max = TrickSetting.ALLOW
    if not difficulty then max = TrickSetting.USE_GLOBAL end

    function data.item.OnLeftClickFunc(self)
        if self.ItemState.setting >= max then return end
        self.ItemState.setting = self.ItemState.setting + 1
        data:UpdateGfx()
    end

    function data.item.OnRightClickFunc(self)
        if self.ItemState.setting <= TrickSetting.DENY then return end
        self.ItemState.setting = self.ItemState.setting - 1
        data:UpdateGfx()
    end

    function data.SetState(self, state)
        if type(state) ~= "number" then state = TrickSetting.USE_GLOBAL end
        if state >= max then state = max end
        if state <= TrickSetting.DENY then state = TrickSetting.DENY end

        self.item.ItemState.setting = state
        self:UpdateGfx()
    end

    function data.item.LoadFunc(self, data)
        data.ItemState = {}
        data:SetState(data.setting)
    end

    function data.item.SaveFunc(self)
        return { setting = self.ItemState.setting }
    end

    data:UpdateGfx()

    return data
end

ScriptHost:AddWatchForCode("TrickDifficulty", "Tricks", function(_)
    for _, trick in ipairs(AP_TRICKS) do
        trick:UpdateGfx()
    end
end)
