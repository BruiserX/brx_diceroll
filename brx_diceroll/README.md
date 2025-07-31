# 🎲 RollDice Script for QBox (ox_lib + ox_inventory)

A flexible, configurable dice-rolling system for FiveM servers using `ox_lib` and `ox_inventory`.  
Supports:

- ✅ Slash command menu (`/roll`)
- ✅ Multiple usable dice items with metadata (`dices`, `sides`, `uses`)
- ✅ Configurable 3D text display
- ✅ Optional durability tracking

---

## 🔧 Requirements

- [ox_lib](https://overextended.dev/ox_lib/)
- [ox_inventory](https://overextended.dev/ox_inventory/)
- [qbx_core](https://github.com/qbcore-framework/qbx-core)

---

## 🧠 Features

- 🎲 Roll dice using a slash command **menu**
- 🎯 Use **custom items** to roll preset dice (e.g. 2d20, 3d6)
- 🧮 Fully **configurable limits** (min/max sides & dices)
- ♻️ Optional **limited-use dice items** (`uses = 5`)
- 🗣️ Shows animated 3D roll results nearby

---

## 📦 Installation

1. Drop the resource into your `resources/` folder
2. Add to your `server.cfg`:

## Items
3. Register your dice items inside `ox_inventory/data/items.lua`:
```lua
['diamond_dice'] = {
		label = 'Diamond Dice',
		weight =50,
		stack = false,
		close = true,
		consume = 0.05, --20 uses
		description = 'Rolls 2d20',
		metadata = {
			dices = 2,
			sides = 20,
		}
	},
['wooden_dice'] = {
    label = 'Wooden Dice',
    weight = 50,
    stack = true,
    close = true,
    consume = 0.1, -- 10 uses
    description = 'Rolls 1d6',
    metadata = {
        dices = 1,
        sides = 6
    }
},
```
