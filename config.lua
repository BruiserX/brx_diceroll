Config = {}

Config.Debug = false

Config.DiceItems = { -- Add any dice you want here, must match the items you add to inventory
    'diamond_dice',
    'wooden_dice',
    'death_dice',
    'god_dice'
}

-- Default dice configurations for each item (if no metadata is provided)
Config.DiceDefaults = {
    diamond_dice = { dices = 2, sides = 6 },
    wooden_dice = { dices = 1, sides = 6 },
    god_dice = { dices = 1, sides = 100 }
--Dice that use the roll menu dont need to be defined here
}

Config.UseCommand = false --Use command or not.
Config.ChatCommand = "roll" --Command name.
Config.RollCooldown = 3000 -- Cooldown between rolls in milliseconds (3000 = 3 seconds)

--Dice options for Roll Menu
Config.MinDices = 1 -- Minimum amount of dice to roll Must be atleast 1
Config.MaxDices = 3 -- Max amount of dices you can roll at one instance. Default is 3.

Config.MinSides = 2  -- Minimum amount of sides on a dice. Default is 6.
Config.MaxSides = 1000 -- Max amount of sides on a dice. Default is 20. 

--Dice Display options
Config.MaxDistance = 7.0 -- Distance players can see the dice rolls
Config.ShowTime = 7 -- Time in seconds before dice despawn
Config.DiceProp = 'ate_dice_b' -- Dice prop model (ate_dice_a (Oversized dice) or ate_dice_b (Normal dice))
Config.ThrowForce = 0.6 -- Force applied when throwing dice
Config.DUIHeight = 0.3 -- Height above dice to draw DUI (in meters)


return Config  