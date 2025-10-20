local Config = require 'config'

-- Debug print helper
local function Dbg(...)
    if Config.Debug then print("[brx_diceroll]", ...) end
end

-- Cooldown tracker to prevent double-triggers
local useCooldown = {}

-- Store active dice globally so players who walk up can see them
local activeDiceGlobal = {} -- { [uniqueId] = { netIds, results, sides, playerName, coords, endTime } }

-- Export function for ox_inventory to call when dice items are used
exports('useDice', function(event, item, inventory, slot, data)
    local source = inventory.id
    
    -- Check cooldown (prevent double-triggers within 500ms)
    local now = GetGameTimer()
    if useCooldown[source] and (now - useCooldown[source]) < 500 then
        Dbg("Ignoring duplicate call (cooldown)")
        return false
    end
    useCooldown[source] = now
    
    Dbg("Player", source, "used", item.name)
    
    -- Get dice configuration from item metadata or defaults based on item name
    local metadata = item.metadata or {}
    local defaults = Config.DiceDefaults[item.name] or {dices = Config.MinDices, sides = Config.MinSides}
    
    local dices = tonumber(metadata.dices) or defaults.dices
    local sides = tonumber(metadata.sides) or defaults.sides
    
    -- Pass the dice config to the client to play anim & trigger roll
    TriggerClientEvent('brx_diceroll:Client:OnUseDice', source, {dices = dices, sides = sides})
    
    return true
end)

-- 2) Optional: slash command to open the roll UI
if Config.UseCommand then
    RegisterCommand(Config.ChatCommand, function(source, args)
        TriggerClientEvent('brx_diceroll:Client:OpenRollMenu', source)
    end, false)
end

-- 3) Client calls this after its animation finishes
RegisterNetEvent('brx_diceroll:Server:DoRoll', function(dices, sides)
    local src = source

    -- Clamp & validate
    dices = math.tointeger(dices) or Config.MinDices
    sides = math.tointeger(sides) or Config.MinSides
    dices = math.min(math.max(dices, Config.MinDices), Config.MaxDices)
    sides = math.min(math.max(sides, Config.MinSides), Config.MaxSides)

    Dbg("Rolling", src, dices, "d", sides)

    -- Get player name
    local player = exports.qbx_core:GetPlayer(src)
    local playerName = "Unknown"
    if player then
        playerName = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
    end

    -- Perform the roll
    local results = {}
    for i = 1, dices do
        table.insert(results, math.random(1, sides))
    end

    -- Send to the roller to spawn physical dice and get network IDs
    TriggerClientEvent('brx_diceroll:Client:SpawnDice', src, playerName, results, sides)
end)

-- Client sends back the network IDs of spawned dice so nearby players can track them
RegisterNetEvent('brx_diceroll:Server:BroadcastDice', function(diceNetIds, results, sides)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))
    
    -- Get player name
    local player = exports.qbx_core:GetPlayer(src)
    local playerName = "Unknown"
    if player then
        playerName = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
    end
    
    -- Store dice globally
    local uniqueId = string.format("%s_%s", src, GetGameTimer())
    activeDiceGlobal[uniqueId] = {
        netIds = diceNetIds,
        results = results,
        sides = sides,
        playerName = playerName,
        coords = coords,
        endTime = os.time() + Config.ShowTime
    }
    
    -- Remove after ShowTime
    SetTimeout(Config.ShowTime * 1000, function()
        activeDiceGlobal[uniqueId] = nil
    end)
    
    -- Send dice network IDs to nearby players (excluding the roller)
    for _, pid in ipairs(GetPlayers()) do
        if tonumber(pid) ~= src then
            local ped = GetPlayerPed(pid)
            if DoesEntityExist(ped) then
                local dist = #(coords - GetEntityCoords(ped))
                if dist <= Config.MaxDistance then
                    TriggerClientEvent(
                        'brx_diceroll:Client:ShowDiceFromNetwork',
                        pid,
                        diceNetIds,
                        results,
                        sides,
                        playerName
                    )
                end
            end
        end
    end
end)

-- Client requests active dice when they move into range
RegisterNetEvent('brx_diceroll:Server:RequestActiveDice', function()
    local src = source
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    -- Send all active dice that are in range
    for _, diceData in pairs(activeDiceGlobal) do
        if os.time() < diceData.endTime then
            local dist = #(playerCoords - diceData.coords)
            if dist <= Config.MaxDistance then
                TriggerClientEvent(
                    'brx_diceroll:Client:ShowDiceFromNetwork',
                    src,
                    diceData.netIds,
                    diceData.results,
                    diceData.sides,
                    diceData.playerName
                )
            end
        end
    end
end)
