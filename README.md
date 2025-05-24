# BCC Sell NPC Modified

> NPC Selling Script for RedM

This script allows players to interact with NPCs in RedM to sell items.

## Added Features

- **Item based transaction, you can now set it to where you can recieve items instead of money so you can give the players dirty money or things like that!**

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


