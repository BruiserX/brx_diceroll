local Config = require 'config'

function DebugPrint(...)
    if Config.Debug then
        print("[DEBUG]", ...)
    end
end

--- ox_inventory server-side item callback
--- @param event    string    "usingItem" | "usedItem" | "buying"
--- @param item     table     the item being used
--- @param inventory table     inventory data, contains .id = source
--- @param slot     number    slot index (unused here)
--- @param data     any       extra data (optional)
function UseDiceItem(event, item, inventory, slot, data)
    local src = inventory.id

    -- When the player *starts* using the item, just allow it
    if event == 'usingItem' then
        return true
    end

    -- Only roll on the *actual* use completion
    if event == 'usedItem' then
        local dices = tonumber(item.metadata?.dices) or Config.DefaultDices or 1
        local sides = tonumber(item.metadata?.sides) or Config.DefaultSides or 6

        dices = math.min(math.max(dices, Config.MinDices), Config.MaxDices)
        sides = math.min(math.max(sides, Config.MinSides), Config.MaxSides)

        DebugPrint(('[Dice] %s used %s (%d x d%d)'):format(
            GetPlayerName(src) or 'Unknown',
            item.name or 'nil',
            dices, sides
        ))

        RollDice_ServerEvent(src, dices, sides)
    end
end
exports('UseDiceItem', UseDiceItem)

--- Shared dice rolling logic (used by item or slash command)
---@param src number
---@param dices number
---@param sides number
function RollDice_ServerEvent(src, dices, sides)
    dices = tonumber(dices) or 1
    sides = tonumber(sides) or 6

    -- Clamp + validate
    if dices < Config.MinDices or dices > Config.MaxDices
    or sides < Config.MinSides or sides > Config.MaxSides then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.ChatPrefix,
            description = ('Invalid input. Max %s dice and %s sides.'):format(Config.MaxDices, Config.MaxSides),
            type = 'error'
        })
        return
    end

    -- Roll
    local results = {}
    for i = 1, dices do
        results[#results + 1] = math.random(1, sides)
    end

    local coords = GetEntityCoords(GetPlayerPed(src))
    TriggerClientEvent("brx_diceroll:Client:Roll", -1, src, Config.MaxDistance, results, sides, coords)

    local playerName = GetPlayerName(src) or 'Unknown'
    DebugPrint(('[Dice] %s rolled %d x d%d'):format(playerName, dices, sides))
end

-- From client: slash menu or manual roll
RegisterNetEvent("brx_diceroll:Server:Event", function(dices, sides)
    RollDice_ServerEvent(source, dices, sides)
end)

-- Optional slash command
if Config.UseCommand then
    RegisterCommand(Config.ChatCommand, function(source)
        TriggerClientEvent("brx_diceroll:Client:OpenRollMenu", source)
    end, false)
end
    
