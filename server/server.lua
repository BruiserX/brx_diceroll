local Config = require 'config'

-- Debug print helper
local function Dbg(...)
    if Config.Debug then print("[brx_diceroll]", ...) end
end

-- Cooldown trackers
local useCooldown = {}
local rollCooldown = {}

-- Store active dice globally so players who walk up can see them
local activeDiceGlobal = {} -- { [uniqueId] = { netIds, results, sides, coords, endTime } }

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

-- Export function to open roll menu (can be called from other resources)
exports('openRollMenu', function(event, item, inventory, slot, data)
    local source = inventory.id
    TriggerClientEvent('brx_diceroll:Client:OpenRollMenu', source)
    return true
end)

-- 2) Optional: slash command to open the roll UI
if Config.UseCommand then
    RegisterCommand(Config.ChatCommand, function(source, args)
        TriggerClientEvent('brx_diceroll:Client:OpenRollMenu', source)
    end, false)
end

RegisterNetEvent('brx_diceroll:Server:DoRoll', function(dices, sides)
    local src = source

    -- Check cooldown to prevent spam
    local now = GetGameTimer()
    if rollCooldown[src] and (now - rollCooldown[src]) < Config.RollCooldown then
        return
    end
    rollCooldown[src] = now

    -- Validate input
    dices = math.min(math.max(math.tointeger(dices) or Config.MinDices, Config.MinDices), Config.MaxDices)
    sides = math.min(math.max(math.tointeger(sides) or Config.MinSides, Config.MinSides), Config.MaxSides)

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = vec2(-math.sin(math.rad(heading)), math.cos(math.rad(heading)))

    -- Roll the dice
    local results = {}
    for i = 1, dices do
        results[i] = math.random(1, sides)
    end

    -- Send roll data to client to spawn and show
    TriggerClientEvent('brx_diceroll:Client:SpawnAndShowDice', src, results, sides, coords, heading)
    
    -- Broadcast to nearby players
    for _, pid in ipairs(GetPlayers()) do
        if tonumber(pid) ~= src then
            local otherPed = GetPlayerPed(tonumber(pid))
            if DoesEntityExist(otherPed) and #(coords - GetEntityCoords(otherPed)) <= Config.MaxDistance then
                TriggerClientEvent('brx_diceroll:Client:SpawnAndShowDice', tonumber(pid), results, sides, coords, heading)
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
                TriggerClientEvent('brx_diceroll:Client:ShowDiceFromNetwork', src, diceData.netIds, diceData.results, diceData.sides)
            end
        end
    end
end)
