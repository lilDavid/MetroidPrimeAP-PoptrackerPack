-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via their ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
ScriptHost:LoadScript("scripts/autotracking/ap/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/option_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/trick_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/ap/level_mapping.lua")

-- used for hint tracking to quickly map hint status to a value from the Highlight enum
HINT_STATUS_MAPPING = {}
if Highlight then
    HINT_STATUS_MAPPING = {
        [20] = Highlight.Avoid,
        [40] = Highlight.None,
        [10] = Highlight.NoPriority,
        [0] = Highlight.Unspecified,
        [30] = Highlight.Priority,
    }
end

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

local AUTOTRACKER_CONNECTED = 3
local AP_SLOT_NONE = -1

-- get a data storage key for the current player
-- returns nil when not connected to AP
function getDataStorageKey(key)
    if
        AutoTracker:GetConnectionState("AP") ~= AUTOTRACKER_CONNECTED or
        Archipelago.TeamNumber == nil or Archipelago.TeamNumber == AP_SLOT_NONE or
        Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == AP_SLOT_NONE
    then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print("Tried to call getDataStorageKey while not connected to AP server")
        end
        return nil
    end
    return string.format("%s_%s_%s", key, Archipelago.TeamNumber, Archipelago.PlayerNumber)
end

function getHintDataStorageKey()
    return getDataStorageKey("_read_hints")
end

function getAreaDataStorageKey()
    return getDataStorageKey("metroidprime_level")
end

-- reset an item to its initial state
function resetItem(item_code, item_type)
    local obj = Tracker:FindObjectForCode(item_code)
    if obj then
        item_type = item_type or obj.Type
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
        end
        if item_type == "toggle" or item_type == "toggle_badged" then
            obj.Active = false
        elseif item_type == "progressive" or item_type == "progressive_toggle" or item_type == "togglebeam" or item_type == "progressivebeam" or item_type == "bombs" then
            obj.CurrentStage = 0
            obj.Active = false
        elseif item_type == "consumable" then
            obj.AcquiredCount = 0
        elseif item_type == "custom" then
            -- your code for your custom lua items goes here
        elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("resetItem: tried to reset static item %s", item_code))
        elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format(
                "resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
                "Please use the respective left/right toggle item codes instead.", item_code))
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("resetItem: could not find item object for code %s", item_code))
    end
end

-- advance the state of an item
function incrementItem(item_code, item_type, multiplier)
    local obj = Tracker:FindObjectForCode(item_code)
    if obj then
        item_type = item_type or obj.Type
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
        end
        if item_type == "toggle" or item_type == "toggle_badged" then
            obj.Active = true
        elseif item_type == "progressive" or item_type == "progressive_toggle" then
            if obj.Active then
                obj.CurrentStage = obj.CurrentStage + 1
            else
                obj.Active = true
            end
        elseif item_type == "bombs" then
            if multiplier == nil then
                obj.CurrentStage = obj.CurrentStage + 1
            elseif obj.CurrentStage < multiplier then
                obj.CurrentStage = multiplier
            end
        elseif item_type == "consumable" then
            obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
        elseif item_type == "togglebeam" then
            local progbeams = Tracker:FindObjectForCode("ProgressiveBeams")
            -- If Progressive Beam Upgrades is on, ingore normal versions
            if progbeams and progbeams.CurrentStage == 0 then
                obj.Active = true
                obj.CurrentStage = 1
            end
        elseif item_type == "progressivebeam" then
            local progbeams = Tracker:FindObjectForCode("ProgressiveBeams")
            -- If Progressive Beam Upgrades is off, ignore progressive versions
            if progbeams and progbeams.Active then
                if obj.Active then
                    obj.CurrentStage = obj.CurrentStage + 1
                else
                    obj.Active = true
                end
            end
        elseif item_type == "custom" then
            -- your code for your custom lua items goes here
        elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("incrementItem: tried to increment static item %s", item_code))
        elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format(
                "incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
                "Please use the respective left/right toggle item codes instead.", item_code))
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("incrementItem: could not find object for code %s", item_code))
    end
end

-- apply everything needed from slot_data, called from onClear
function applySlotData(slot_data)
    -- set options
    for key, option_data in pairs(AP_SLOT_DATA_MAPPING) do
        local option
        if type(option_data) == "string" then
            option = { code = option_data }
        else
            if option_data.code then
                option = option_data
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("applySlotData: 'code' field required for %s", key))
            end
        end
        if option then
            local obj = Tracker:FindObjectForCode(option.code)
            if obj then
                local value = slot_data[key]
                if value ~= nil then
                    if type(value) == "boolean" then
                        if value then
                            value = 1
                        else
                            value = 0
                        end
                    end
                    if type(value) == "number" then
                        value = value + (option.offset or 0)
                    elseif option.mapping and option.mapping[value] then
                        value = option.mapping[value]
                    end
                    if obj.Type == "toggle" then
                        local active = value and value ~= 0
                        obj.Active = active
                        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                            print(string.format("applySlotData: setting option %s to %s", option.code, active))
                        end
                    elseif obj.Type == "progressive" then
                        obj.CurrentStage = value
                        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                            print(string.format("applySlotData: setting option %s to %s", option.code, value))
                        end
                    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                        print(string.format("applySlotData: could not set option %s of type %s", option.code, obj.Type))
                    end
                else
                    if option.default then
                        obj.Active = true
                        obj.CurrentStage = option.default
                        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                            print(string.format("applySlotData: setting option %s to default %s", option.code,
                                option.default))
                        end
                    else
                        obj.Active = false
                        obj.CurrentStage = 0
                        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                            print(string.format("applySlotData: setting option %s to default inactive", option.code))
                        end
                    end
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("applySlotData: unknown option %s", option.code))
            end
        end
    end

    -- set trick allow/deny lists
    local trick_name_mapping = {}

    local trick_deny_list = slot_data["trick_deny_list"]
    if trick_deny_list ~= nil then
        for _, trick_name in ipairs(trick_deny_list) do
            trick_name_mapping[trick_name] = TrickSetting.DENY
        end
    end
    -- allows take priority over denies
    local trick_allow_list = slot_data["trick_allow_list"]
    if trick_allow_list ~= nil then
        for _, trick_name in ipairs(trick_allow_list) do
            trick_name_mapping[trick_name] = TrickSetting.ALLOW
        end
    end
    -- deduplicate unrecognized tricks
    local trick_settings = {}
    for trick_name, setting in pairs(trick_name_mapping) do
        local item_code = AP_TRICK_MAPPING[trick_name]
        if item_code then
            trick_settings[item_code] = setting
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("applySlotData: unknown trick %s", trick_name))
        end
    end
    for _, item_code in pairs(AP_TRICK_MAPPING) do
        local obj = Tracker:FindObjectForCode(item_code)
        if obj then
            local setting = trick_settings[item_code] or TrickSetting.USE_GLOBAL
            obj.CurrentStage = setting
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("applySlotData: setting trick %s to %s", item_code, setting))
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("applySlotData: unknown trick code %s", item_code))
        end
    end
end

-- called right after an AP slot is connected
function onClear(slot_data)
    -- use bulk update to pause logic updates until we are done resetting all items/locations
    Tracker.BulkUpdate = true
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
    end
    CUR_INDEX = -1
    -- reset locations
    for _, location_table in pairs(AP_LOCATION_MAPPING) do
        local location_code = location_table[1]
        if location_code then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing location %s", location_code))
            end
            if location_code:sub(1, 1) == "@" then
                local obj = Tracker:FindObjectForCode(location_code)
                if obj then
                    obj.AvailableChestCount = obj.ChestCount
                    if obj.Highlight then
                        obj.Highlight = Highlight.None
                    end
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: could not find location object for code %s", location_code))
                end
            else
                -- reset hosted item
                local item_type = location_table[2]
                resetItem(location_code, item_type)
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onClear: skipping location_table with no location_code"))
        end
    end
    -- reset items
    for _, item_table in pairs(AP_ITEM_MAPPING) do
        local item_code, item_type = table.unpack(item_table)
        if item_code then
            resetItem(item_code, item_type)
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onClear: skipping item_table with no item_code"))
        end
    end
    applySlotData(slot_data)
    LOCAL_ITEMS = {}
    GLOBAL_ITEMS = {}
    local data_storage_keys = { getHintDataStorageKey(), getAreaDataStorageKey() }
    Archipelago:SetNotify(data_storage_keys)
    Archipelago:Get(data_storage_keys)
    Tracker.BulkUpdate = false
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
    CUR_INDEX = index
    local item_table = AP_ITEM_MAPPING[item_id]
    if not item_table then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: could not find item mapping for id %s", item_id))
        end
        return
    end
    local item_code, item_type, multiplier = table.unpack(item_table)
    multiplier = multiplier or 1
    if item_code then
        incrementItem(item_code, item_type, multiplier)
        -- keep track which items we touch are local and which are global
        if is_local then
            if LOCAL_ITEMS[item_code] then
                LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
            else
                LOCAL_ITEMS[item_code] = 1
            end
        else
            if GLOBAL_ITEMS[item_code] then
                GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
            else
                GLOBAL_ITEMS[item_code] = 1
            end
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onClear: skipping item_table with no item_code"))
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
    local location_table = AP_LOCATION_MAPPING[location_id]
    if not location_table then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onLocation: could not find location mapping for id %s", location_id))
        end
        return
    end
    local location_code = location_table[1]
    if location_code then
        local obj = Tracker:FindObjectForCode(location_code)
        if obj then
            if location_code:sub(1, 1) == "@" then
                obj.AvailableChestCount = obj.AvailableChestCount - 1
            else
                -- increment hosted item
                local item_type = location_table[2]
                incrementItem(location_code, item_type)
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onLocation: could not find object for code %s", location_code))
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onLocation: skipping location_table with no location_code"))
    end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
            item_player))
    end
    -- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onBounce: %s", dump_table(json)))
    end
    -- your code goes here
end

-- called whenever Archipelago:Get returns data from the data storage or
-- whenever a subscribed to (via Archipelago:SetNotify) key in data storgae is updated
-- oldValue might be nil (always nil for "_read" prefixed keys and via retrieved handler (from Archipelago:Get))
function onDataStorageUpdate(key, value, old_value)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onDataStorageUpdate: %s, %s, %s", key, value, old_value))
    end
    if key == getHintDataStorageKey() then
        onHintsUpdate(value)
    elseif key == getAreaDataStorageKey() then
        if value == old_value then
            return
        end
        updateMap(value)
    end
end

-- called whenever the hints key in data storage updated
-- NOTE: this should correctly handle having multiple mapped locations in a section.
--       if you only map sections 1 to 1 you can simplfy this. for an example see
--       https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/archipelago.lua
function onHintsUpdate(hints)
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return
    end
    -- get all new highlight values per section
    local sections_to_update = {}
    for _, hint in ipairs(hints) do
        -- we only care about hints in our world
        if hint.finding_player == Archipelago.PlayerNumber then
            updateHint(hint, sections_to_update)
        end
    end
    -- update the sections
    for location_code, highlight_code in pairs(sections_to_update) do
        -- find the location object
        local obj = Tracker:FindObjectForCode(location_code)
        -- check if we got the location and if it supports Highlight
        if obj and obj.Highlight then
            obj.Highlight = highlight_code
        end
    end
end

-- update section highlight based on the hint
function updateHint(hint, sections_to_update)
    -- get the highlight enum value for the hint status
    local hint_status = hint.status
    local highlight_code = nil
    if hint_status then
        highlight_code = HINT_STATUS_MAPPING[hint_status]
    end
    if not highlight_code then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status,
                hint.location))
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
    local location_table = AP_LOCATION_MAPPING[hint.location]
    if not location_table then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("updateHint: could not find location mapping for id %s", hint.location))
        end
        return
    end
    local location_code = location_table[1]
    -- skip hosted items, they don't support Highlight
    if location_code and location_code:sub(1, 1) == "@" then
        -- see if we already set a Highlight for this section
        local existing_highlight_code = sections_to_update[location_code]
        if existing_highlight_code then
            -- make sure we only replace None or "increase" the highlight but never overwrite with None
            -- this so sections with mulitple mapped locations show the "highest" Highlight and
            -- only show no Highlight when all hints are found
            if existing_highlight_code == Highlight.None or (existing_highlight_code < highlight_code and highlight_code ~= Highlight.None) then
                sections_to_update[location_code] = highlight_code
            end
        else
            sections_to_update[location_code] = highlight_code
        end
    end
end

function updateMap(value)
    if not has("AutoTab") then
        return
    end
    local level = AP_LEVEL_MAPPING[value]
    if not level then
        return
    end
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
Archipelago:AddRetrievedHandler("retrieved handler", onDataStorageUpdate)
Archipelago:AddSetReplyHandler("set reply handler", onDataStorageUpdate)
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)
