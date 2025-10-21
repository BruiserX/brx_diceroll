# 🎲 BRX Dice Roll - Advanced Dice System for QBox

A modern, feature-rich dice rolling system for FiveM QBox servers with physical dice props, animated rolls, and stylish UI.

## ✨ Features

- 🎲 **Physical Dice Props** - Dice are thrown as physical objects with realistic physics
- 🎨 **Modern NUI** - Clean, styled UI with orange borders and black background
- 📍 **3D Attached UI** - Results display above the physical dice in world space
- 🎬 **Smooth Animations** - Player performs throwing animation synced with dice spawn
- 👥 **Multiplayer Ready** - All nearby players see dice rolls
- 📏 **Distance-Based** - Only visible within configurable range (default 7m)
- ⚙️ **Highly Configurable** - Customize dice types, limits, props, display, and cooldowns
- 🎯 **Item-Based Rolling** - Use custom dice items with durability tracking
- 💬 **Command Support** - Optional `/roll` command with input dialog
- 🔄 **Auto-Cleanup** - Dice automatically despawn after configured time
- ⏱️ **Spam Protection** - Configurable cooldown prevents roll spamming
- 📤 **Export Functions** - Use dice items or open roll menu from other resources

---

## 🔧 Requirements

- [QBox Core (qbx_core)](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [Custom Dice Props by atenea03](https://github.com/atenea03/Dice) - Optional but recommended for best visual quality

---

## 📦 Installation

### 1. Add Resource
Place the `brx_diceroll` folder in your `resources/[brx]/` directory

### 2. Add to server.cfg
```cfg
ensure brx_diceroll
```

### 3. Configure Items in ox_inventory
Add dice items to `ox_inventory/data/items.lua`:

```lua
['diamond_dice'] = {
    label = 'Diamond Dice',
    weight = 50,
    stack = false,
    close = true,
    consume = 0.05, -- 20 uses (1/20 = 0.05)
    rarity = 'rare',
    description = 'Rolls 2d6',
    server = {
        export = 'brx_diceroll.useDice',
    },
},

['wooden_dice'] = {
    label = 'Wooden Dice',
    weight = 50,
    stack = true,
    close = true,
    consume = 0.1, -- 10 uses
    rarity = 'uncommon',
    description = 'Rolls 1d6',
    server = {
        export = 'brx_diceroll.useDice',
    },
},

['god_dice'] = {
    label = 'God Dice',
    weight = 50,
    stack = false,
    close = true,
    consume = 0.01, -- 100 uses
    rarity = 'legendary',
    description = 'Rolls 1d100',
    server = {
        export = 'brx_diceroll.useDice',
    },
},

--This dice opens the roll menu
['death_dice'] = {
	label = 'Death Dice',
	weight = 50,
	stack = false,
	close = true,
	degrade = 1440, -- 24 hours
	decay = true
	rarity = 'Legendary',
	description = 'Rolls customn sidded sided die',
	server = {
		export = 'brx_diceroll.openRollMenu',
	},
},
```

### 4. Configure Dice Defaults
Edit `config.lua` to set default roll configurations:

```lua
Config.DiceDefaults = {
    diamond_dice = { dices = 2, sides = 6 },
    wooden_dice = { dices = 1, sides = 6 },
    god_dice = { dices = 1, sides = 100 }
}
```

---

## ⚙️ Configuration

Edit `config.lua` to customize behavior:

### Debug Mode
```lua
Config.Debug = false -- Enable debug prints
```

### Dice Items
```lua
Config.DiceItems = {
    'diamond_dice',
    'wooden_dice',
    'death_dice'
}
```

### Command Settings
```lua
Config.UseCommand = true -- Enable/disable /roll command
Config.ChatCommand = "roll" -- Command name
Config.RollCooldown = 3000 -- Cooldown between rolls in milliseconds (3000 = 3 seconds)
```

### Roll Limits
```lua
Config.MinDices = 1 -- Minimum dice to roll
Config.MaxDices = 3 -- Maximum dice to roll Not Recommended to go over 5 since you are spawning props
Config.MinSides = 2 -- Minimum sides per die
Config.MaxSides = 1000 -- Maximum sides per die
```

### Display Settings
```lua
Config.MaxDistance = 7.0 -- Viewing distance in meters
Config.ShowTime = 10 -- Seconds that the UI will display the Results
Config.DiceProp = 'ate_dice_b' -- Dice prop model (ate_dice_a = oversized, ate_dice_b = normal)
Config.ThrowForce = 0.6 -- Physics force when throwing Recommend no more than 1.0
Config.DUIHeight = 0.3 -- UI height above dice (meters)
```

#### Custom Dice Props
This script uses custom optimized dice props by [atenea03](https://github.com/atenea03/Dice):
- **Download**: [Get the dice props here](https://github.com/atenea03/Dice)
- **Models**: 
  - `ate_dice_a` - Oversized dice (more visible) Goofy large but have fun
  - `ate_dice_b` - Normal sized dice (recommended)
- **Installation**: 
  1. Download and place the `ate_dice` resource in your resources folder
  3. Add `ensure ate_dice` to your server.cfg **before** `ensure brx_diceroll`

**Alternative Props**: If you don't want to use custom props, you can use default GTA props:
- `prop_tennis_ball` - Tennis ball
- `hei_prop_heist_box` - Small box
- Any other small prop model

---

## 🎮 Usage

### Using Dice Items
1. Add dice items to your inventory
2. Use the item from your inventory
3. Watch the roll animation and see the results!

### Using /roll Command
1. Type `/roll` in chat
2. Enter number of dice (1-3)
3. Enter number of sides per die (2-1000)
4. Watch the roll animation and see the results!

### Viewing Results
- Dice roll with realistic physics for 2 seconds before results show
- Results appear as UI elements floating above the physical dice props
- Only visible to players within 7 meters (configurable)
- Automatically disappear after ShowTime + 2 seconds (configurable)
- UI appears after dice settle for a natural feel

---

## 🎨 UI Customization

The UI is built with HTML/CSS and can be customized in `web/dice-ui.html`:

### Current Styling
- Black background with 75% opacity
- Orange (#ffa500) borders
- 18px white text with shadow
- Rounded corners (8px)
- Centered above dice props

### Modify Appearance
Edit the `.dice-ui` class in `dice-ui.html` to change:
- Background color/opacity
- Border color/thickness
- Font size/style
- Padding/sizing
- Border radius

---

## 🔄 How It Works

### Roll Flow
1. **Player triggers roll** (via item or command)
2. **Cooldown check** (prevents spam within configured time)
3. **Animation plays** 
4. **Dice spawn** at 1.8s (during throwing motion for natural feel)
5. **Server generates results** (random numbers based on dice config)
6. **Physical dice roll** (client-side props with physics for 2 seconds)
7. **UI displays results** (appears after dice settle)
8. **Auto-cleanup** (dice and UI removed after ShowTime + 2s)

### Multiplayer Sync
- **Results**: Server-synced for all players (everyone sees the same numbers)
- **Dice Physics**: Client-side spawning for smooth performance (slight visual variation is normal)
- **Roller**: Sees dice immediately with full physics
- **Nearby players**: See dice spawn at the same location with same results
- **Distance check**: Only visible within MaxDistance range


---

## 🛠️ Technical Details

### Client-Side Spawning
- Dice are spawned client-side for optimal performance (no networking delays or freezes)
- Server sends roll results and coordinates to all nearby players
- Each client independently spawns dice at the same position
- Result numbers are server-synced and identical for all players

### Performance
- Efficient render loop using World3dToScreen2d
- Distance checks to hide UI when too far
- Automatic cleanup prevents entity buildup
- Configurable cooldown prevents spam and animation overlap

### Dependencies
- `ox_lib` for animations, models, and input dialogs
- `ox_inventory` for item system and durability
- `qbx_core` for player data and character info

---

## 🐛 Troubleshooting

### Dice not appearing
- Ensure `Config.DiceProp` is a valid prop model
- Check F8 console for model loading errors
- Verify ate_dice resource is started if using Athena's Dice prop



### Animation not playing
- Make sure animation dictionary loads successfully
- Check F8 console for any errors
- Verify ox_lib is installed and updated

### Items not working
- Verify `server.export` is set correctly in ox_inventory items.lua
  - Use `brx_diceroll.useDice` for auto-roll items
  - Use `brx_diceroll.openRollMenu` for menu items
- Ensure dice item names match `Config.DiceItems`
- Check `Config.DiceDefaults` has entries for your items

## 📤 Exports

### useDice (Auto-Roll)
Use in item configuration to automatically roll with predefined settings:
```lua
server = {
    export = 'brx_diceroll.useDice',
}
```

### openRollMenu (Custom Roll)
Use in item configuration to open the roll menu dialog:
```lua
server = {
    export = 'brx_diceroll.openRollMenu',
}
```

---

## 📝 Credits

**Author**: BruiserX  
**Framework**: QBox  
**Dice Props**: [atenea03 - Custom Dice Models](https://github.com/atenea03/Dice)  
**Version**: 1.1.0  
**License**: MIT

### Special Thanks
- **[atenea03](https://github.com/atenea03/Dice)** - For the custom optimized dice prop models (150 polygons, 2 models)

