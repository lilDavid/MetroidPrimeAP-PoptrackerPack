-- this is an example/ default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via thier ids
-- it will also load the AP slot data in the global SLOT_DATA, keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
ScriptHost:LoadScript("scripts/autotracking/ap/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/option_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/trick_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/level_mapping.lua")

if Highlight then
    HINT_STATUS_MAPPING = {
        [20] = Highlight.Avoid,
        [40] = Highlight.None,
        [10] = Highlight.NoPriority,
        [0] = Highlight.Unspecified,
        [30] = Highlight.Priority,
    }
else
    HINT_STATUS_MAPPING = {}
end

CUR_INDEX = -1
SLOT_DATA = nil
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

local AUTOTRACKER_CONNECTED = 3
local AP_TEAM_NONE = -1

ForceUpdateTab = false

function getDataStorageKey(key)
    local player = Archipelago.PlayerNumber
    local team = Archipelago.TeamNumber

    if AutoTracker:GetConnectionState("AP") ~= AUTOTRACKER_CONNECTED
        or team == nil or team == AP_TEAM_NONE
        or player == nil
    then
        print("Tried to call getDataStorageKey while not connected to AP server")
        return nil
    end

    return string.format("%s_%s_%s", key, team, player)
end

function onClear(slot_data)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
    end
    SLOT_DATA = slot_data
    CUR_INDEX = -1
    -- reset locations
    for _, v in pairs(AP_LOCATION_MAPPING) do
        if v[1] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing location %s", v[1]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[1]:sub(1, 1) == "@" then
                    obj.AvailableChestCount = obj.ChestCount
                    if obj.Highlight then
                        obj.Highlight = Highlight.None
                    end
                else
                    obj.Active = false
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: could not find object for code %s", v[1]))
            end
        end
    end
    -- reset items
    for _, v in pairs(AP_ITEM_MAPPING) do
        if v[1] and v[2] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing item %s of type %s", v[1], v[2]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[2] == "toggle" then
                    obj.Active = false
                elseif v[2] == "progressive" or v[2] == "togglebeam" or v[2] == "progressivebeam" then
                    obj.CurrentStage = 0
                    obj.Active = false
                elseif v[2] == "consumable" then
                    obj.AcquiredCount = 0
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown item type %s for code %s", v[2], v[1]))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: could not find object for code %s", v[1]))
            end
        end
    end
    LOCAL_ITEMS = {}
    GLOBAL_ITEMS = {}

    -- reset options
    for k, v in pairs(AP_SLOT_DATA_MAPPING) do
        local obj
        local default
        local name
        if type(v) == "string" then
            name = v
            default = nil
        else
            name = v["name"]
            if not name and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: 'name' field required for %s", k))
            end
            default = v["default"]
        end
        obj = Tracker:FindObjectForCode(name)
        if obj then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing setting %s", name))
            end
            if default then
                obj.CurrentStage = default
            else
                obj.CurrentStage = 0
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onClear: unknown option %s", name))
        end
    end
    for _, v in pairs(AP_TRICK_MAPPING) do
        local obj = Tracker:FindObjectForCode(v)
        obj.CurrentStage = 1
        print(string.format("onClear: setting trick %s to default", v))
    end

    if SLOT_DATA == nil then return end

    local data_storage_keys = { getDataStorageKey("_read_hints"), getDataStorageKey("metroidprime_level") }
    Archipelago:SetNotify(data_storage_keys)
    Archipelago:Get(data_storage_keys)

    -- set options
    for k, v in pairs(SLOT_DATA) do
        local option = AP_SLOT_DATA_MAPPING[k]
        if type(v) == "boolean" then
            if v then v = 1 else v = 0 end
        end
        local key, value
        if type(option) == "string" then
            key = option
            if type(v) == "number" then
                value = v
            end
        elseif type(option) == "table" then
            key = option["name"]
            if type(v) == "number" then
                value = v + (option["offset"] or 0)
            elseif option["mapping"] ~= nil and option["mapping"][v] ~= nil then
                value = option["mapping"][v]
            end
        end
        if key ~= nil then
            local obj = Tracker:FindObjectForCode(key)
            if obj ~= nil and value ~= nil then
                obj.CurrentStage = value
            end
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                if obj == nil then
                    print(string.format("onClear: unknown option %s", k))
                elseif value == nil then
                    print(string.format("onClear: unknown option and value %s: %s", k, v))
                else
                    print(string.format("onClear: setting option %s to %s", key, value))
                end
            end
        end
    end
    local trick_deny_list = SLOT_DATA["trick_deny_list"]
    if trick_deny_list ~= nil then
        for _, trick_name in ipairs(trick_deny_list) do
            local trick_id = AP_TRICK_MAPPING[trick_name]
            if trick_id == nil then
                if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown trick %s", trick_name))
                end
            else
                local obj = Tracker:FindObjectForCode(trick_id)
                obj.CurrentStage = 0
                if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: denying trick %s", trick_name))
                end
            end
        end
    end
    local trick_allow_list = SLOT_DATA["trick_allow_list"]
    if trick_allow_list ~= nil then
        for _, trick_name in ipairs(trick_allow_list) do
            local trick_id = AP_TRICK_MAPPING[trick_name]
            if trick_id == nil then
                if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown trick %s", trick_name))
                end
            else
                local obj = Tracker:FindObjectForCode(trick_id)
                obj.CurrentStage = 2
                if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: allowing trick %s", trick_name))
                end
            end
        end
    end
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
    end
    if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
        return
    end
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local v = AP_ITEM_MAPPING[item_id]
    if not v then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: could not find item mapping for id %s", item_id))
        end
        return
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: code: %s, type %s", v[1], v[2]))
    end
    if not v[1] then
        return
    end
    local obj = Tracker:FindObjectForCode(v[1])
    if obj then
        if v[2] == "toggle" then
            obj.Active = true
        elseif v[2] == "progressive" then
            if obj.Active then
                obj.CurrentStage = obj.CurrentStage + 1
            else
                obj.Active = true
            end
        elseif v[2] == "consumable" then
            obj.AcquiredCount = obj.AcquiredCount + obj.Increment
        elseif v[2] == "togglebeam" then
            local progbeams = Tracker:FindObjectForCode("ProgressiveBeams")
            -- If Progressive Beam Upgrades is on, ingore normal versions
            if progbeams and progbeams.CurrentStage == 0 then
                obj.Active = true
                obj.CurrentStage = 1
            end
        elseif v[2] == "progressivebeam" then
            local progbeams = Tracker:FindObjectForCode("ProgressiveBeams")
            -- If Progressive Beam Upgrades is off, ignore progressive versions
            if progbeams and progbeams.CurrentStage == 1 then
                if obj.Active then
                    obj.CurrentStage = obj.CurrentStage + 1
                else
                    obj.Active = true
                end
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: unknown item type %s for code %s", v[2], v[1]))
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: could not find object for code %s", v[1]))
    end
    -- track local items via snes interface
    if is_local then
        if LOCAL_ITEMS[v[1]] then
            LOCAL_ITEMS[v[1]] = LOCAL_ITEMS[v[1]] + 1
        else
            LOCAL_ITEMS[v[1]] = 1
        end
    else
        if GLOBAL_ITEMS[v[1]] then
            GLOBAL_ITEMS[v[1]] = GLOBAL_ITEMS[v[1]] + 1
        else
            GLOBAL_ITEMS[v[1]] = 1
        end
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
        print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
    end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onLocation: %s, %s", location_id, location_name))
    end
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return
    end
    local v = AP_LOCATION_MAPPING[location_id]
    if not v and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
    end
    if not v[1] then
        return
    end
    local obj = Tracker:FindObjectForCode(v[1])
    if obj then
        if v[1]:sub(1, 1) == "@" then
            obj.AvailableChestCount = obj.AvailableChestCount - 1
        else
            obj.Active = true
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onLocation: could not find object for code %s", v[1]))
    end
end

function onDataStorageUpdate(key, value, old_value)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onDataStorageUpdate: %s, %s, %s", key, value, old_value))
    end
    if key == getDataStorageKey("_read_hints") then
        updateHints(value)
    elseif key == getDataStorageKey("metroidprime_level") then
        if value == old_value and not ForceUpdateTab then return end
        updateMap(value)
        ForceUpdateTab = false
    end
end

function updateHints(hints)
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then return end
    for _, hint in ipairs(hints) do
        if hint.finding_player == Archipelago.PlayerNumber then
            updateHint(hint)
        end
    end
end

function updateHint(hint)
    -- get the highlight enum value for the hint status
    local hint_status = hint.status
    local highlight_code = nil
    if hint_status then
        highlight_code = HINT_STATUS_MAPPING[hint_status]
    end

    if not highlight_code then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status, hint.location))
        end
        -- try to "recover" by checking hint.found (older AP versions without hint.status)
        if hint.found == true then
            highlight_code = Highlight.None
        elseif hint.found == false then
            highlight_code = Highlight.Unspecified
        else
            return
        end
    end

    -- get the location mapping for the location id
    local mapping_entry = AP_LOCATION_MAPPING[hint.location]
    if not mapping_entry then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("updateHint: could not find location mapping for id %s", hint.location))
        end
        return
    end
    for _, location_code in pairs(mapping_entry) do
        -- skip hosted items, they don't support Highlight
        if location_code and location_code:sub(1, 1) == "@" then
            -- find the location object
            local obj = Tracker:FindObjectForCode(location_code)
            -- check if we got the location and if it supports Highlight
            if obj and obj.Highlight then
                obj.Highlight = highlight_code
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print(string.format("updateHint: could update section %s (obj doesn't support Highlight)", location_code))
            end
        end
    end
end

function updateMap(value)
    if not has("AutoTab") then return end
    local level = AP_LEVEL_MAPPING[value]
    if not level then return end
    Tracker:UiHint("ActivateTab", level)
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    Archipelago:AddLocationHandler("location handler", onLocation)
end
if AUTOTRACKER_ENABLE_LEVEL_TRACKING then
    Archipelago:AddRetrievedHandler("retrieved handler", onDataStorageUpdate)
    Archipelago:AddSetReplyHandler("set reply handler", onDataStorageUpdate)
end
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)

ScriptHost:AddWatchForCode("Auto tab update", "AutoTab", function() ForceUpdateTab = true end)
