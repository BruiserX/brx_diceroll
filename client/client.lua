local Config = require 'config'

-- 1) When the server says "use the dice now," run this:
RegisterNetEvent('brx_diceroll:Client:OnUseDice', function(metadata)
    local ped = cache.ped
    
    if not ped or ped == 0 then
        return
    end
    
    -- Read metadata or fall back to min values
    local dices = tonumber(metadata.dices) or Config.MinDices
    local sides = tonumber(metadata.sides) or Config.MinSides

    -- Play roll animation - wait for it to load
    local animDict = "anim@mp_player_intcelebrationmale@wank"
    lib.requestAnimDict(animDict, 5000)
    
    if not HasAnimDictLoaded(animDict) then
        -- Animation failed to load, still do the roll
        TriggerServerEvent('brx_diceroll:Server:DoRoll', dices, sides)
        return
    end
    
    TaskPlayAnim(
      ped,
      animDict, "wank",
      8.0, -8.0,
      2400,   -- anim length in ms
      49, 0, false, false, false
    )
    
    -- Wait for anim to finish
    Wait(2400)
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)

    -- Now ask server to do the roll
    TriggerServerEvent('brx_diceroll:Server:DoRoll', dices, sides)
end)

-- 2) If you’re exposing a slash command UI:
RegisterNetEvent('brx_diceroll:Client:OpenRollMenu', function()
    local input = lib.inputDialog('Roll Dice', {
        { type = 'number', label = 'Number of Dice', default = 1, min = Config.MinDices, max = Config.MaxDices },
        { type = 'number', label = 'Sides per Die', default = 6, min = Config.MinSides, max = Config.MaxSides }
    })
    if not input then return end

    -- Re-use the exact same workflow as item‐use:
    local dices = tonumber(input[1])
    local sides = tonumber(input[2])
    if not dices or not sides then return end

    -- Trigger the OnUseDice handler locally
    TriggerEvent('brx_diceroll:Client:OnUseDice', { dices = dices, sides = sides })
end)

-- 3) Spawn physical dice with DUI showing results
local activeDice = {}

-- Periodically request active dice in range (for players who walk up after dice are thrown)
CreateThread(function()
    while true do
        Wait(1000) -- Check every second
        TriggerServerEvent('brx_diceroll:Server:RequestActiveDice')
    end
end)

-- Render loop to show NUI attached to dice
CreateThread(function()
    while true do
        Wait(0)

        local playerCoords = GetEntityCoords(cache.ped)

        for _, diceData in ipairs(activeDice) do
            if DoesEntityExist(diceData.entity) then
                local coords = GetEntityCoords(diceData.entity)
                local distance = #(playerCoords - coords)
                
                -- Only show UI if within max distance
                if distance <= Config.MaxDistance then
                    local displayCoords = vector3(coords.x, coords.y, coords.z + Config.DUIHeight)

                    -- Convert 3D world position to screen coordinates
                    local onScreen, screenX, screenY = World3dToScreen2d(displayCoords.x, displayCoords.y, displayCoords.z)

                    if onScreen then
                        -- Send to NUI with proper screen coordinates
                        SendNUIMessage({
                            action = 'showDice',
                            diceId = diceData.entity,
                            result = diceData.result,
                            screenX = screenX * 100, -- Convert to percentage
                            screenY = screenY * 100  -- Convert to percentage
                        })
                    else
                        -- Hide if not on screen
                        SendNUIMessage({
                            action = 'removeDice',
                            diceId = diceData.entity
                        })
                    end
                else
                    -- Hide if too far
                    SendNUIMessage({
                        action = 'removeDice',
                        diceId = diceData.entity
                    })
                end
            end
        end
    end
end)


-- Event for nearby players to display UI for networked dice
RegisterNetEvent('brx_diceroll:Client:ShowDiceFromNetwork', function(diceNetIds, rollTable, sides)
    for i, diceData in ipairs(diceNetIds) do
        CreateThread(function()
            local netId = diceData.netId
            local result = diceData.result
            
            -- Wait for the entity to be networked (retry mechanism)
            local dice = nil
            local attempts = 0
            while attempts < 50 do -- Try for up to 2.5 seconds
                dice = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(dice) then
                    break
                end
                Wait(50)
                attempts = attempts + 1
            end
            
            if DoesEntityExist(dice) then
                -- Check if this dice is already in activeDice (prevent duplicates)
                local alreadyExists = false
                for _, existingDice in ipairs(activeDice) do
                    if existingDice.entity == dice then
                        alreadyExists = true
                        break
                    end
                end
                
                if not alreadyExists then
                    table.insert(activeDice, {
                        entity = dice,
                        result = result,
                        sides = sides,
                        startTime = GetGameTimer()
                    })
                    
                    -- Clean up after ShowTime (UI only, don't delete the entity)
                    SetTimeout(Config.ShowTime * 1000, function()
                        -- Remove from NUI
                        SendNUIMessage({
                            action = 'removeDice',
                            diceId = dice
                        })
                        
                        -- Remove from activeDice table
                        for idx, diceData in ipairs(activeDice) do
                            if diceData.entity == dice then
                                table.remove(activeDice, idx)
                                break
                            end
                        end
                    end)
                end
            else
                print("[brx_diceroll] Failed to get networked dice entity:", netId)
            end
        end)
    end
end)
