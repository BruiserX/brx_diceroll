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

RegisterNetEvent('brx_diceroll:Server:DoRoll', function(dices, sides)
    local src = source

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

    -- Load model and request collision
    local model = GetHashKey(Config.DiceProp)
    RequestModel(model)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        Dbg("Failed to load model:", Config.DiceProp)
        return
    end
    
    Wait(100) -- Allow collision to load

    -- Spawn dice
    local diceNetIds = {}
    for i, result in ipairs(results) do
        local offset = vec3(
            forward.x * 0.8 + math.random(-30, 30) / 100,
            forward.y * 0.8 + math.random(-30, 30) / 100,
            0.05
        )
        
        local dice = CreateObjectNoOffset(model, coords.x + offset.x, coords.y + offset.y, coords.z + offset.z, true, true, false)
        
        if DoesEntityExist(dice) then
            local throwDir = vec3(
                forward.x + math.random(-30, 30) / 100,
                forward.y + math.random(-30, 30) / 100,
                0.3
            )
            
            ApplyForceToEntity(dice, 1,
                throwDir.x * Config.ThrowForce,
                throwDir.y * Config.ThrowForce,
                throwDir.z * Config.ThrowForce,
                math.random(-100, 100) / 100,
                math.random(-100, 100) / 100,
                math.random(-100, 100) / 100,
                0, false, true, true, false, true
            )
            
            diceNetIds[#diceNetIds + 1] = {netId = NetworkGetNetworkIdFromEntity(dice), result = result}
            
            SetTimeout(Config.ShowTime * 1000, function()
                if DoesEntityExist(dice) then DeleteEntity(dice) end
            end)
        end
    end
    
    SetModelAsNoLongerNeeded(model)
    Wait(100) -- Allow networking

    -- Store and broadcast
    local uniqueId = ("%s_%s"):format(src, GetGameTimer())
    activeDiceGlobal[uniqueId] = {
        netIds = diceNetIds,
        results = results,
        sides = sides,
        coords = coords,
        endTime = os.time() + Config.ShowTime
    }
    
    SetTimeout(Config.ShowTime * 1000, function()
        activeDiceGlobal[uniqueId] = nil
    end)

    for _, pid in ipairs(GetPlayers()) do
        local otherPed = GetPlayerPed(tonumber(pid))
        if DoesEntityExist(otherPed) and #(coords - GetEntityCoords(otherPed)) <= Config.MaxDistance then
            TriggerClientEvent('brx_diceroll:Client:ShowDiceFromNetwork', tonumber(pid), diceNetIds, results, sides)
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
