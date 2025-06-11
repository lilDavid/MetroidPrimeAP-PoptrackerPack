local function can_open_door_color(area, color)
    if color == "AnyBeam" then return true end
    if color == "Missile" then return can_missile() or has("BlastShieldRando") end
    local location = Tracker:FindObjectForCode("@doors/" .. area .. "/" .. color)
    if not location then
        if ENABLE_DEBUG_LOG then print("can_open_door_color: unrecognized color " .. tostring(color) .. " for " .. tostring(area)) end
        return false
    end
    return location.AccessibilityLevel == AccessibilityLevel.Normal
end

local BLAST_SHIELD_STATES = {
    { ["name"] = "Unknown", ["img"] = "missile", ["can_open"] = function() return false end, ["disabled"] = true },
    { ["name"] = "No blast shield", ["img"] = "blue", ["can_open"] = function() return true end },
    { ["name"] = "Bomb", ["img"] = "bombshield", ["can_open"] = can_bomb },
    { ["name"] = "Power Bomb", ["img"] = "powerbomb", ["can_open"] = can_power_bomb },
    { ["name"] = "Missile", ["img"] = "missile", ["can_open"] = can_missile },
    { ["name"] = "Charge Beam", ["img"] = "charge", ["can_open"] = can_charge_beam },
    { ["name"] = "Super Missile", ["img"] = "supers", ["can_open"] = can_super_missile },
    { ["name"] = "Wavebuster", ["img"] = "wavebuster", ["can_open"] = function () return can_charge_combo("WaveBeam") end },
    { ["name"] = "Ice Spreader", ["img"] = "spreader", ["can_open"] = function () return can_charge_combo("IceBeam") end },
    { ["name"] = "Flamethrower", ["img"] = "flamethrower", ["can_open"] = function () return can_charge_combo("PlasmaBeam") end },
    { ["name"] = "Disabled", ["img"] = "blue", ["can_open"] = function () return false end, ["disabled"] = true },
}

local blast_shield_items = {}

local function create_blast_shield_item(area, source, destination, forward_type, reverse_type)
    local item_code = "BlastShield|" .. area .. "|" .. source .. "|" .. destination
    local reverse_code = "BlastShield|" .. area .. "|" .. destination .. "|" .. source
    local scout_code = "UnknownDoor|" .. area .. "|" .. source .. "|" .. destination
    local reverse_scout_code = "UnknownDoor|" .. area .. "|" .. destination .. "|" .. source
    if blast_shield_items[item_code] ~= nil then return blast_shield_items[item_code] end
    if blast_shield_items[reverse_code] ~= nil then return blast_shield_items[item_code] end

    if reverse_type == nil then reverse_type = forward_type end

    local item = ScriptHost:CreateLuaItem()
    item.ItemState = {}
    item.CanProvideCodeFunc = function(self, code)
        return code == item_code or code == reverse_code or code == scout_code or code == reverse_scout_code
    end
    item.ProvidesCodeFunc = function(self, code)
        if not self:CanProvideCodeFunc(code) then return false end
        if code == scout_code or code == reverse_scout_code then return self:Get("stage") == 1 end
        if not BLAST_SHIELD_STATES[self:Get("stage")]["can_open"]() then return false end
        if code == reverse_code then return can_open_door_color(area, reverse_type) end
        return can_open_door_color(area, forward_type)
    end
    item.PropertyChangedFunc = function(self, key, value)
        if key ~= "stage" then return end
        while value > #BLAST_SHIELD_STATES do
            value = value - #BLAST_SHIELD_STATES
        end
        while value <= 0 do
            value = value + #BLAST_SHIELD_STATES
        end

        self.ItemState["stage"] = value
        local shield_entry = BLAST_SHIELD_STATES[value]
        self.Name = shield_entry["name"]
        self.Icon = ImageReference:FromPackRelativePath("images/doors/" .. shield_entry["img"] .. ".png")
        if shield_entry["disabled"] then self.IconMods = "@disabled" else self.IconMods = "" end
    end
    item.OnLeftClickFunc = function(self)
        self:Set("stage", self:Get("stage") + 1)
    end
    item.OnRightClickFunc = function(self)
        self:Set("stage", self:Get("stage") - 1)
    end
    item.OnMiddleClickFunc = function(self)
        self:Set("stage", 2)
    end
    item.SaveFunc = function(self) return self:Get("stage") end
    item.LoadFunc = function(self, data) self:Set("stage", data) end
    item:Set("stage", 1)

    blast_shield_items[item_code] = item
    blast_shield_items[reverse_code] = item
    return item
end

local function sortedpairs(mapping)
    local keys = {}
    for k, _ in pairs(mapping) do table.insert(keys, k) end
    table.sort(keys)
    local i = 0
    return function ()
        i = i + 1
        if keys[i] ~= nil then return keys[i], mapping[keys[i]] end
    end
end

for area, doors in sortedpairs(MISSILE_DOORS) do
    for door, _ in sortedpairs(doors) do
        local _, _, source, destination = string.find(door, "([^|]+)|([^|]+)")
        create_blast_shield_item(area, source, destination, "Missile")
    end
end

for area, doors in sortedpairs(MIX_IT_UP_DOORS) do
    for door, lock in sortedpairs(doors) do
        local _, _, source, destination = string.find(door, "([^|]+)|([^|]+)")
        create_blast_shield_item(area, source, destination, lock[1], lock[2])
    end
end

function can_open(area, source, destination)
    local missile_door_list = MISSILE_DOORS[area]
    local mixitup_door_list = MIX_IT_UP_DOORS[area]
    if missile_door_list == nil or mixitup_door_list == nil then
        if ENABLE_DEBUG_LOG then print("can_open: unrecognized area " .. area) end
        return true
    end

    local missile_door = missile_door_list[source .. "|" .. destination]
    if missile_door == nil then missile_door = missile_door_list[destination .. "|" .. source] end
    local mixitup_door = mixitup_door_list[source .. "|" .. destination]
    if mixitup_door ~= nil then
        mixitup_door = mixitup_door[1]
    else
        mixitup_door = mixitup_door_list[destination .. "|" .. source]
        if mixitup_door ~= nil then
            if mixitup_door[2] == nil then mixitup_door = mixitup_door[1] else mixitup_door = mixitup_door[2] end
        end
    end
    if missile_door == nil and mixitup_door == nil then
        if ENABLE_DEBUG_LOG then
            print("can_open: unrecognized door in " .. area .. " from " .. source .. " to " .. destination)
        end
        return true
    end

    if has("BlastShieldRando", 2) then
        if mixitup_door == nil then return true end
        local code = "BlastShield|" .. area .. "|" .. source .. "|" .. destination
        return Tracker:ProviderCountForCode(code) > 0
    end

    if has("BlastShieldRando", 1) then
        if missile_door == nil then return can_open_door_color(area, mixitup_door) end
        local code = "BlastShield|" .. area .. "|" .. source .. "|" .. destination
        return Tracker:ProviderCountForCode(code) > 0
    end

    if missile_door then return can_missile() end
    return can_open_door_color(area, mixitup_door)
end
