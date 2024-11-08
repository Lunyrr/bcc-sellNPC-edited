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

## Usage
- **Approach an NPC**: The script will detect nearby NPCs that meet allowed ped type.
- **Press ENTER**: When within range, press "G" key and after right click to initiate the selling interaction.
- **Complete Transaction**: If the NPC accepts the offer, items will be removed from the player's inventory, and currency will be added.

## Configuration

In the **`config.lua`** file, you can customize the following:

- **Allowed NPC Types**: Specify which ped types can be approached for selling.
- **Items for Sale**: Define items that players can sell, along with prices.
- **Blip Settings**: Customize the map blip details such as label, sprite, scale, and color.
- **Law Alert Settings**: Customize the alert details for law enforcement, including blip duration, label, and coordinates shown.

## Requirements
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)


## Installation
1. Make sure dependencies are installed/updated and ensured before this script
2. Add `bcc-sellNPC` folder to your resources folder
3. Add `ensure bcc-sellNPC` to your resources.cfg
4. Restart server