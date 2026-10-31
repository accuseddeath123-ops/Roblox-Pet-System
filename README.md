# Roblox Pet System

A Roblox Lua pet system featuring pet hatching, inventory management, equipping, pet followers, and data saving.

## Features

- 🥚 Hatch pets using in-game coins
- 🐶 Multiple pets: Dog, Cat, and Dragon
- 🎲 Weighted pet rarity chances
- 🎒 Pet inventory system
- ⭐ Equip the pet with the highest multiplier
- 🐾 Pets follow the player
- 💾 DataStore saving and loading
- ⏱️ Hatch cooldown to prevent spam
- 🥚 Physical egg with ProximityPrompt
- 🔔 RemoteEvents for client-server communication

## Pet Stats

| Pet | Chance | Multiplier |
|---|---:|---:|
| Dog | 50% | 1.2x |
| Cat | 35% | 1.5x |
| Dragon | 15% | 2x |

## Installation

1. Place the main script in `ServerScriptService`.
2. Make sure the required RemoteEvents exist in `ReplicatedStorage`.
3. Add a part named `PetEgg` to `Workspace` if using the physical egg.
4. Enable Studio Access to API Services for DataStore testing.

## Technologies

- Roblox Luau
- Roblox DataStoreService
- RemoteEvents
- ProximityPrompt
- RunService

## Author

Created as a Roblox scripting project.
