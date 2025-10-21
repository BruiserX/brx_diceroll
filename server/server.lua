local Config = require 'config'

-- Seed random number generator for better randomization
math.randomseed(os.time() + GetGameTimer())

-- Debug print helper
local function Dbg(...)
    if Config.Debug then print("[brx_diceroll]", ...) end
end

-- Cooldown trackers
local useCooldown = {}
local rollCooldown = {}

-- Use global statebag to store active dice
GlobalState.activeDice = {}

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

    -- Roll the dice (with better randomization)
    local results = {}
    for i = 1, dices do
        -- Add small delay and extra randomization to prevent identical results
        math.randomseed(os.time() + GetGameTimer() + i * src)
        math.random() -- Discard first result for better randomization
        results[i] = math.random(1, sides)
    end

    -- Generate unique ID for this roll
    local uniqueId = string.format("%s_%s", src, GetGameTimer())
    
    -- Send roll data to roller to spawn and show
    TriggerClientEvent('brx_diceroll:Client:SpawnAndShowDice', src, uniqueId, results, sides, coords, heading)
    
    -- Broadcast to all nearby players (excluding roller)
    for _, pid in ipairs(GetPlayers()) do
        if tonumber(pid) ~= src then
            local ped = GetPlayerPed(pid)
            if DoesEntityExist(ped) then
                local dist = #(coords - GetEntityCoords(ped))
                if dist <= Config.MaxDistance then
                    TriggerClientEvent('brx_diceroll:Client:SpawnAndShowDice', pid, uniqueId, results, sides, coords, heading)
                end
            end
        end
    end
    
    -- Store in global statebag for late arrivals
    local currentDice = GlobalState.activeDice or {}
    
    currentDice[uniqueId] = {
        results = results,
        sides = sides,
        coords = vector3(coords.x, coords.y, coords.z),
        heading = heading,
        endTime = GetGameTimer() + (Config.ShowTime * 1000)
    }
    
    GlobalState.activeDice = currentDice
    
    -- Remove from statebag after ShowTime
    SetTimeout(Config.ShowTime * 1000, function()
        local updatedDice = GlobalState.activeDice or {}
        updatedDice[uniqueId] = nil
        GlobalState.activeDice = updatedDice
    end)
end)
