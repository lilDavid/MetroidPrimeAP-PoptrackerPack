-- This script is used with the GameCube UAT Bridge program to autotrack Metroid Prime using UAT.
-- See the repository at https://github.com/lilDavid/GameCube-UAT-Bridge for details.

-- Setting this to false improves performance if you're not autotracking locations
local LOCATION_TRACKING = true

local WORLD_STATE_SIZE = 24

local GAME_STATE_POINTER = 0x805A8C40
local CSTATE_MANAGER = 0x8045A1A8
local CPLAYER_VTABLE = 0x803D96E8


local LEVEL_MAPPING = {
    [361692695] = "Frigate Orpheon",
    [972217896] = "Tallon Overworld",
    [2214002543] = "Chozo Ruins",
    [1056449404] = "Magmoor Caverns",
    [2831049361] = "Phendrana Drifts",
    [2980859237] = "Phazon Mines",
    [3241871825] = "Impact Crater",
    [332894565] = "End of Game",
}


local ITEM_ID_MAPPING = {
    ["Power Beam"] = 0,
    ["Ice Beam"] = 1,
    ["Wave Beam"] = 2,
    ["Plasma Beam"] = 3,
    ["Missile"] = 4,
    ["Scan Visor"] = 5,
    ["Morph Ball Bomb"] = 6,
    ["Power Bomb"] = 7,
    ["Flamethrower"] = 8,
    ["Thermal Visor"] = 9,
    ["Charge Beam"] = 10,
    ["Super Missile"] = 11,
    ["Grapple Beam"] = 12,
    ["X-Ray Visor"] = 13,
    ["Ice Spreader"] = 14,
    ["Space Jump Boots"] = 15,
    ["Morph Ball"] = 16,
    ["Combat Visor"] = 17,
    ["Boost Ball"] = 18,
    ["Spider Ball"] = 19,
    ["Power Suit"] = 20,
    ["Gravity Suit"] = 21,
    ["Varia Suit"] = 22,
    ["Phazon Suit"] = 23,
    ["Energy Tank"] = 24,
    ["Wavebuster"] = 28,
    ["Artifact of Truth"] = 29,
    ["Artifact of Strength"] = 30,
    ["Artifact of Elder"] = 31,
    ["Artifact of Wild"] = 32,
    ["Artifact of Lifegiver"] = 33,
    ["Artifact of Warrior"] = 34,
    ["Artifact of Chozo"] = 35,
    ["Artifact of Nature"] = 36,
    ["Artifact of Sun"] = 37,
    ["Artifact of World"] = 38,
    ["Artifact of Spirit"] = 39,
    ["Artifact of Newborn"] = 40,
}


local LOCATION_MAPPING = {
    ["Chozo Ruins"] = {
        [0x0002012D] = "Main Plaza/Half-Pipe",
        [0x00020132] = "Main Plaza/Grapple Ledge",
        [0x0002006B] = "Main Plaza/Tree",
        [0x00020159] = "Main Plaza/Locked Door",
        [0x00080077] = "Ruined Fountain",
        [0x00090028] = "Ruined Shrine/Plated Beetle",
        [0x00090069] = "Ruined Shrine/Half-Pipe",
        [0x0009006E] = "Ruined Shrine/Lower Tunnel",
        [0x000B003E] = "Vault",
        [0x000C002D] = "Training Chamber",
        [0x00100004] = "Ruined Nursery",
        [0x00120004] = "Training Chamber Access",
        [0x001400EE] = "Magma Pool",
        [0x00150336] = "Tower of Light",
        [0x001B001A] = "Tower Chamber",
        [0x001C002F] = "Ruined Gallery/Missile Wall",
        [0x001C0061] = "Ruined Gallery/Tunnel",
        [0x001E0173] = "Transport Access North",
        [0x00200058] = "Gathering Hall",
        [0x002401DD] = "Hive Totem",
        [0x002528EF] = "Sunchamber/Flaahgra",
        [0x00253094] = "Sunchamber/Ghosts",
        [0x00260009] = "Watery Hall Access",
        [0x00290086] = "Watery Hall/Scan Puzzle",
        [0x002927E7] = "Watery Hall/Underwater",
        [0x002D0023] = "Dynamo/Lower",
        [0x002D00AE] = "Dynamo/Spider Track",
        [0x00300037] = "Burn Dome/Missile",
        [0x0030278B] = "Burn Dome/Incinerator Drone",
        [0x00310063] = "Furnace/Spider Tracks",
        [0x0031000C] = "Furnace/Inside Furnace",
        [0x003402DF] = "Hall of the Elders",
        [0x003502C9] = "Crossway",
        [0x00390004] = "Elder Chamber",
        [0x003D0004] = "Antechamber",
    },
    ["Phendrana Drifts"] = {
        [0x0002016F] = "Phendrana Shorelines/Behind Ice",
        [0x00020177] = "Phendrana Shorelines/Spider Track",
        [0x00080258] = "Chozo Ice Temple",
        [0x000928EE] = "Ice Ruins West",
        [0x000A00AC] = "Ice Ruins East/Behind Ice",
        [0x000A0192] = "Ice Ruins East/Spider Track",
        [0x000E0059] = "Chapel of the Elders",
        [0x000F022D] = "Ruined Courtyard",
        [0x001000E3] = "Phendrana Canyon",
        [0x001801CC] = "Quarantine Cave",
        [0x00190514] = "Research Lab Hydra",
        [0x001B0012] = "Quarantine Monitor",
        [0x001E02F7] = "Observatory",
        [0x001F00A6] = "Transport Access",
        [0x002704D0] = "Control Tower",
        [0x0028011D] = "Research Core",
        [0x00290188] = "Frost Cave",
        [0x003303E1] = "Research Lab Aether/Tank",
        [0x00330412] = "Research Lab Aether/Morph Track",
        [0x00350021] = "Gravity Chamber/Underwater",
        [0x0035012D] = "Gravity Chamber/Grapple Ledge",
        [0x003600AA] = "Storage Cave",
        [0x0037001A] = "Security Cave",
    },
    ["Tallon Overworld"] = {
        [0x00000085] = "Landing Site",
        [0x0004000E] = "Alcove",
        [0x000801FC] = "Frigate Crash Site",
        [0x000D00C7] = "Overgrown Cavern",
        [0x000F00FE] = "Root Cave",
        [0x001001D5] = "Artifact Temple",
        [0x00130137] = "Transport Tunnel B",
        [0x00140016] = "Arbor Chamber",
        [0x001B0116] = "Cargo Freight Lift to Deck Gamma",
        [0x001E02ED] = "Biohazard Containment",
        [0x00230054] = "Hydro Access Tunnel",
        [0x0025000E] = "Great Tree Chamber",
        [0x00270037] = "Life Grove Tunnel",
        [0x002A0022] = "Life Grove/Start",
        [0x002A0235] = "Life Grove/Underwater Spinner",
    },
    ["Phazon Mines"] = {
        [0x00020234] = "Main Quarry",
        [0x00050188] = "Security Access A",
        [0x00090005] = "Storage Depot B",
        [0x000C0027] = "Storage Depot A",
        [0x000D0341] = "Elite Research/Phazon Elite",
        [0x000D04F2] = "Elite Research/Laser",
        [0x000F008E] = "Elite Control Access",
        [0x0012010E] = "Ventilation Shaft",
        [0x00130767] = "Phazon Processing Center",
        [0x001600A8] = "Processing Center Access",
        [0x001A04B9] = "Elite Quarters",
        [0x001B04B2] = "Central Dynamo",
        [0x001F0206] = "Metroid Quarantine B",
        [0x002005EB] = "Metroid Quarantine A",
        [0x00240128] = "Fungal Hall B",
        [0x00270080] = "Phazon Mining Tunnel",
        [0x00280103] = "Fungal Hall Access",
    },
    ["Magmoor Caverns"] = {
        [0x0004287D] = "Lava Lake",
        [0x0006010D] = "Triclops Pit",
        [0x00080010] = "Storage Cavern",
        [0x000A0044] = "Transport Tunnel A",
        [0x000B0038] = "Warrior Shrine",
        [0x000C0029] = "Shore Tunnel",
        [0x000E01DB] = "Fiery Shores/Morph Track",
        [0x000E0240] = "Fiery Shores/Warrior Shrine Tunnel",
        [0x00150020] = "Plasma Processing",
        [0x0017028F] = "Magmoor Workstation",
    }
}


local metroid_prime_interface = ScriptHost:CreateGameInterface()
metroid_prime_interface.Name = "Metroid Prime"
metroid_prime_interface.Version = "0-00"

local relay_trackers = nil

metroid_prime_interface.VerifyFunc = function(self)
    local game_id, revision = table.unpack(GameCube:Read({
        {GameCube.GameIDAddress, 6},
        {GameCube.GameIDAddress + 7, "u8"}
    }))
    return game_id == "GM8E01" and revision == 0
end

local function HandleInventory(store, player_state_address)
    local inventory_table_address = player_state_address + 40
    local read_list = {}
    local variables = {}
    for name, id in pairs(ITEM_ID_MAPPING) do
        table.insert(read_list, {inventory_table_address + 8 * id + 4, "u32"})
        table.insert(variables, name)
    end
    local result = GameCube:Read(read_list)
    for i, var in ipairs(variables) do
        store:WriteVariable("inventory/" .. var, result[i])
    end
end

local function UpdateRelayCache()
    if relay_trackers == nil then
        relay_trackers = {}
        -- Get vector<g_GameState.x88_worldState>
        local world_state_array = GameCube:ReadSingle(GAME_STATE_POINTER, "u32", 0x94)
        local read_list = {}
        for i = 0, 7 do
            local world_state = world_state_array + i * WORLD_STATE_SIZE
            -- Get WorldState.x0_mvlId
            read_list[2 * i + 1] = {world_state, "u32"}
            read_list[2 * i + 2] = {world_state + 8, "u32", 0}
        end
        local result = GameCube:Read(read_list)
        for i = 0, 6 do
            local mlvl = result[2 * i + 1]
            if mlvl == nil then
                print("mlvl " .. i .. " was nil")
                relay_trackers = nil
                return
            end
            local world = LEVEL_MAPPING[mlvl]
            if world == nil then
                print("mlvl " .. i .. " == " .. mlvl .. " which does not correspond to a world")
                relay_trackers = nil
                return
            end
            local address = result[2 * i + 2]
            if address == nil then
                print("address" .. tostring(i) .. " was nil")
                relay_trackers = nil
                return
            end
            relay_trackers[world] = {
                -- Get WorldState.x8_mailbox.x0_relays - Array of memory relays active in the world
                ["address"] = address,
                ["count"] = 0,
                ["memory_relays"] = {},
            }
        end
    end

    local count_read_list = {}
    local tracker_list = {}
    for _, relay_tracker in pairs(relay_trackers) do
        -- WorldState.x8_mailbox.x0_relays.size()
        table.insert(count_read_list, { relay_tracker["address"], "u32" })
        table.insert(tracker_list, relay_tracker)
    end
    local tracker_value_read_list = {}
    local result = GameCube:Read(count_read_list)
    for i, relay_tracker in ipairs(tracker_list) do
        local count = result[i]
        if count == nil then
            print("relay tracker @ " .. relay_tracker["address"] .. "returned nil count")
            relay_trackers = nil
            return
        end
        relay_tracker["count"] = count
        -- WorldState.x8_mailbox.x0_relays content
        if relay_tracker["count"] ~= 0 then
            for i = 0, relay_tracker["count"] do
                table.insert(tracker_value_read_list, {relay_tracker["address"] + 4 + i * 4, "u32"})
            end
        end
    end
    local result = GameCube:Read(tracker_value_read_list)
    local i = 1
    for _, relay_tracker in ipairs(tracker_list) do
        for j = 1, relay_tracker["count"] do
            local value = result[i]
            if value == nil then
                print("relay tracker @ " .. relay_tracker["address"] .. "had nil value")
                relay_trackers = nil
                return
            end
            value = value & 0x00FFFFFF
            relay_tracker["memory_relays"][j] = value
            i = i + 1
        end
    end
end

local function HandleCheckedLocations(store)
    if relay_trackers == nil then return end

    for world, relays in pairs(LOCATION_MAPPING) do
        for idx, pickup in pairs(relays) do
            local relay_tracker = relay_trackers[world]
            local result = false
            for i, relay in pairs(relay_tracker["memory_relays"]) do
                if relay == idx then
                    result = true
                end
            end
            store:WriteVariable("pickups/" .. world .. "/" .. pickup, result)
        end
    end
end

metroid_prime_interface.GameWatcher = function(self, store)
    local player_vtable, world_id, player_state_address = table.unpack(GameCube:Read({
        {CSTATE_MANAGER + 0x84C, "u32", 0},
        {GAME_STATE_POINTER, "u32", 0x84},
        {CSTATE_MANAGER + 0x8B8, "u32", 0},
    }))

    local world = LEVEL_MAPPING[world_id]
    store:WriteVariable("Current Area", world)

    local in_game = player_vtable == CPLAYER_VTABLE and world ~= nil
    if not in_game then
        relay_trackers = nil
        return
    end

    if player_state_address then
        HandleInventory(store, player_state_address)
    end

    if LOCATION_TRACKING then
        UpdateRelayCache()
        HandleCheckedLocations(store)
    end
end

ScriptHost:AddGameInterface("MetroidPrime-lilDavid", metroid_prime_interface)
