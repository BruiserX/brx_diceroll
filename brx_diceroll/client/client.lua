local RollDice = require 'config'
local globalPlayerPedId = cache.ped 


RegisterNetEvent('RollDice:Client:OpenRollMenu', function()
    local input = lib.inputDialog('Roll Dice', {
        { type = 'number', label = 'Number of Dice', default = 1, min = RollDice.MinDices, max = RollDice.MaxDices },
        { type = 'number', label = 'Sides per Die', default = 6, min = RollDice.MinSides, max = RollDice.MaxSides }
    })

    if not input then return end

    local dices = tonumber(input[1])
    local sides = tonumber(input[2])

    if not dices or not sides then return end

    TriggerServerEvent("RollDice:Server:Event", dices, sides)
end)

RegisterNetEvent("RollDice:Client:Roll", function(sourceId, maxDistance, rollTable, sides, location)
    local rollString = CreateRollString(rollTable, sides)

    if location.x == 0.0 and location.y == 0.0 and location.z == 0.0 then
        location = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(sourceId)))
    end

    if GetPlayerServerId(PlayerId()) == sourceId then
        DiceRollAnimation()
    end

    ShowRoll(rollString, sourceId, maxDistance, location)
end)

---@param rollTable number[]
---@param sides number
---@return string
function CreateRollString(rollTable, sides)
    local text = ""
    local total = 0

    for k, roll in ipairs(rollTable) do
        total += roll
        text = text .. ("Die %d: %d/%d\n"):format(k, roll, sides)
    end

    text = text .. ("Total: %d"):format(total)
    return text
end

function DiceRollAnimation()
    lib.requestAnimDict("anim@mp_player_intcelebrationmale@wank")
    TaskPlayAnim(globalPlayerPedId, "anim@mp_player_intcelebrationmale@wank", "wank", 8.0, -8.0, -1, 49, 0, false, false, false)
    Wait(2400)
    ClearPedTasks(globalPlayerPedId)
end

local activeDisplays = {}

---@param text string
---@param sourceId number
---@param maxDistance number
---@param location vector3
function ShowRoll(text, sourceId, maxDistance, location)
    local coords = GetEntityCoords(cache.ped)
    local dist = #(location - coords)

    if dist < maxDistance then
        if activeDisplays[sourceId] then return end
        activeDisplays[sourceId] = true

        local displayTime = RollDice.ShowTime * 1000
        local baseZ = location.z + RollDice.Offset - 1.25
        local serverPed = GetPlayerPed(GetPlayerFromServerId(sourceId))

        CreateThread(function()
            local start = GetGameTimer()
            while GetGameTimer() - start < displayTime do
                Wait(0)
                local currentCoords = GetEntityCoords(serverPed)
                local i = 0
                for line in text:gmatch("[^\r\n]+") do
                    DrawText3D(currentCoords.x, currentCoords.y, baseZ + (i * 0.15), line)
                    i += 1
                end
            end
            activeDisplays[sourceId] = nil
        end)
    end
end


function DrawText3D(x, y, z, text)
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 215)

    local lineHeight = 0.025
    local boxWidth = 0.0
    for i = 1, #lines do
        local line = lines[i]
        local lineWidth = string.len(line) / 370
        if lineWidth > boxWidth then boxWidth = lineWidth end
    end

    -- Draw background once for all lines
    local totalHeight = (#lines * lineHeight) + 0.01
    DrawRect(_x, _y + 0.0125, boxWidth + 0.02, totalHeight, 0, 0, 0, 120)

    -- Draw lines
    for i, line in ipairs(lines) do
        SetTextEntry("STRING")
        AddTextComponentString(line)
        DrawText(_x, _y + ((i - 1) * lineHeight) - (totalHeight / 2) + 0.01)
    end
end


CreateThread(function()
    while true do
        Wait(60000)
        collectgarbage("collect")
    end
end)
