Config = {}

Config.Debug = false

Config.DiceItems = { -- Add any dice you want here, must match the items you add to inventory
    'diamond_dice',
    'wooden_dice',
    'god_dice'
}

-- Default dice configurations for each item (if no metadata is provided)
Config.DiceDefaults = {
    diamond_dice = { dices = 2, sides = 6 },
    wooden_dice = { dices = 1, sides = 6 },
    god_dice = { dices = 1, sides = 100 }
}

Config.UseCommand = true --Use command or not.
Config.ChatCommand = "roll" --Command name.
Config.ChatPrefix = "SYSTEM" --This is the chat prefix. If they type a wrong number or invalid one then it will say that SYSTEM has messaged them, just try it.

--Dice options for Roll Menu
Config.MinDices = 1 -- Minimum amount of dice to roll Must be atleast 1
Config.MaxDices = 3 -- Max amount of dices you can roll at one instance. Default is 3.

Config.MinSides = 2  -- Minimum amount of sides on a dice. Default is 6.
Config.MaxSides = 1000 -- Max amount of sides on a dice. Default is 20. 

--Dice Display options
Config.MaxDistance = 7.0 -- Distance players can see the dice rolls
Config.ShowTime = 7 -- Time in seconds before dice despawn
Config.DiceProp = 'hei_prop_heist_box' -- Dice prop model (small cube-like props: prop_rub_cage_01a, prop_tennis_ball, prop_cs_box_clothes)
Config.ThrowForce = 0.6 -- Force applied when throwing dice
Config.DUIHeight = 0.5 -- Height above dice to draw DUI (in meters)


return Config  