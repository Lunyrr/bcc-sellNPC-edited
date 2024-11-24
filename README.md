# BCC Sell NPC

> NPC Selling Script for RedM

This script allows players to interact with NPCs in RedM to sell items.

## Features

- **NPC Selling Interaction**: Players can approach NPCs and attempt to sell specific items if available.
- **Exterior-Only Sales**: Selling to NPCs is only possible if the NPC is outside of interior locations.
- **Randomized Acceptance**: NPCs may randomly accept or reject offers.
- **Inventory and Currency Management**: Uses inventory functions to check items and reward players upon successful sales.
- **Blip and Notification System**: Alerts and map blips are managed for easy player guidance.
- **Law Alert System**: Alerts are sent to law enforcement when a sale is detected, showing GPS coordinates and placing a blip on the map for a limited duration.
- **Not inside an interior:** The NPC must be in an exterior location (not inside an interior) for selling to be allowed. 
- **Interactive Animations**: Both the player and NPC perform animations during the selling interaction, enhancing realism and immersion.
- **Law Enforcement Dependency**: Configurable system to limit sales when no law enforcement is online.
- **Anti-Exploit Measures**: Prevents multiple interactions with the same NPC and includes sell limits.
- **Job Restrictions**: Certain jobs can be restricted from selling items.

## Usage
- **Approach an NPC**: The script will detect nearby NPCs that meet allowed ped type.
- **Press ENTER**: When within range, press "B" key and after press "ENTER" to initiate the selling interaction.
- **Complete Transaction**: If the NPC accepts the offer, items will be removed from the player's inventory, and currency will be added.
- **Law Enforcement**: Sales may be limited or restricted when no law enforcement is online (configurable).

## Configuration

In the **`config.lua`** file, you can customize the following:

- **Allowed NPC Types**: Specify which ped types can be approached for selling.
- **Items for Sale**: Define items that players can sell, along with prices.
- **Blip Settings**: Customize the map blip details such as label, sprite, scale, and color.
- **Law Alert Settings**: Customize the alert details for law enforcement, including blip duration, label, and coordinates shown.
- **Law Enforcement Settings**:
  - Enable/disable sell limits when no law enforcement is online
  - Set maximum number of sales allowed without law enforcement
  - Configure required number of law enforcement online
- **Job Restrictions**:
  - Define jobs that cannot participate in selling
  - Set required jobs for the selling system to function

## Requirements
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)

## Installation
1. Make sure dependencies are installed/updated and ensured before this script
2. Add `bcc-sellNPC` folder to your resources folder
3. Add `ensure bcc-sellNPC` to your resources.cfg
4. Configure the settings in `config.lua` to match your server's needs
5. Restart server

## Support
- Need more help? Join the bcc discord here: https://discord.gg/VrZEEpBgZJ
- For support, please open an issue on the GitHub repository or contact the development team.
