local Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

local discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar)

-- Debug printing function
function devPrint(message)
    if Config.devMode then
        print("^1[DEV MODE] ^4" .. message)
    end
end

-- Event to check for items every time it’s triggered, with no `itemFound` persistence
RegisterServerEvent('bcc-sellNpc:itemsForSelling')
AddEventHandler('bcc-sellNpc:itemsForSelling', function()
    local _source = source
    local Character = Core.getUser(_source).getUsedCharacter

    if not Character then return end

    local foundItem = nil

    -- Always loop through the items in `Config.itemsForSell`
    for _, itemForSell in ipairs(Config.itemsForSell) do
        local itemCount = exports.vorp_inventory:getItemCount(_source, nil, itemForSell.name)

        if itemCount and itemCount > 0 then
            foundItem = itemForSell
            TriggerClientEvent('bcc-sellNpc:currentlySelling', _source, foundItem)  -- Notify client with the item
            return  -- Exit once an item is found
        end
    end

    -- Notify if no items are available for sale after checking the inventory
    TriggerClientEvent('bcc-sellNpc:cancelSelling', _source)
end)


-- Event to process payment after sale completion
RegisterServerEvent('bcc-sellNpc:moneyFromSelling')
AddEventHandler('bcc-sellNpc:moneyFromSelling', function(itemForSale)
    local _source = source
    local Character = Core.getUser(_source).getUsedCharacter

    if not Character then
        devPrint("Error: Character not found.")
        return
    end

    local itemCount = exports.vorp_inventory:getItemCount(_source, nil, itemForSale.name)

    if itemForSale and itemCount > 0 then
        -- Deduct one item and add money
        exports.vorp_inventory:subItem(_source, itemForSale.name, 1, {})
        Character.addCurrency(0, itemForSale.price)

        -- Prepare the Discord message with player and transaction details
        local playerName = Character.firstname .. " " .. Character.lastname
        local playerId = Character.identifier
        devPrint("Sale completed. Player received $".. itemForSale.price)
        local saleMessage = "**NPC Sale Report**\n"
                          .. "Player: " .. playerName .. "\n"
                          .. "Player Identifier: " .. playerId .. "\n"
                          .. "Item Sold: " .. itemForSale.name .. "\n"
                          .. "Amount Earned: $" .. itemForSale.price

        -- Send the message to Discord
        discord:sendMessage(saleMessage)
        Core.NotifyAvanced(_source, _U('saleSuccessful').. "\n" .. _U('youReceived').. itemForSale.price, "inventory_items", "money_billstack", 3000, "green")
    else
        -- Trigger client event to notify of successful sale completion
        TriggerClientEvent('bcc-sellNpc:doneSelling', _source)
        devPrint("Error: Item missing or invalid for sale.")
    end
end)


RegisterServerEvent('bcc-sellNpc:checkInventory')
AddEventHandler('bcc-sellNpc:checkInventory', function()
    local _source = source
    local hasInventoryItems = false

    -- Check if the player has items to sell in inventory
    for _, item in ipairs(Config.itemsForSell) do
        local itemCount = exports.vorp_inventory:getItemCount(_source, nil, item.name)
        if itemCount and itemCount > 0 then
            hasInventoryItems = true
            break
        end
    end

    -- Notify client with the result
    TriggerClientEvent('bcc-sellNpc:updateHasItems', _source, hasInventoryItems)
end)

function CheckJob(src, alertType)
    local user = Core.getUser(src)
    if not user then
        devPrint("No user found for source " .. tostring(src))
        return false
    end

    local character = user.getUsedCharacter
    if not character then
        devPrint("No character data available for source " .. tostring(src))
        return false
    end

    local alertConfig = Config.alertPermissions[alertType]
    if not alertConfig then
        devPrint("No alert configuration found for alert type: " .. tostring(alertType))
        return false
    end

    if not character.job or not character.jobGrade then
        devPrint("Job or job grade data missing for source: " .. tostring(src))
        return false
    end

    -- Check job eligibility and grade within the allowed range
    local jobConfig = alertConfig.allowedJobs[character.job]
    if jobConfig then
        local jobGrade = tonumber(character.jobGrade)
        if jobGrade >= jobConfig.minGrade and jobGrade <= jobConfig.maxGrade then
            return true
        else
            devPrint("User does not meet job grade requirements for alert type: " .. tostring(alertType) .. " with job: " .. character.job .. " at grade: " .. character.jobGrade)
            return false
        end
    else
        devPrint("Job " .. tostring(character.job) .. " not permitted for alert type: " .. tostring(alertType))
        return false
    end
end


-- Helper function to check if a value is in a table (for job checking)
function table.includes(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Server-side function to alert users about specific events and include location data
function AlertJob(alertType, message, coords)
    local alertConfig = Config.alertPermissions[alertType]
    if not alertConfig then
        devPrint("Alert configuration missing for type: " .. alertType)
        return
    end

    local users = Core.getUsers()
    for _, user in pairs(users) do
        if user and CheckJob(user.source, alertType) then
            TriggerClientEvent('bcc-sellNpc:alertsNotify', user.source, {
                message = message,
                notificationType = "alert",
                x = coords.x,
                y = coords.y,
                z = coords.z,
                blipSprite = alertConfig.blipSettings.blipSprite,
                blipScale = alertConfig.blipSettings.blipScale,
                blipColor = alertConfig.blipSettings.blipColor,
                blipLabel = alertConfig.blipSettings.blipLabel,
                blipDuration = alertConfig.blipSettings.blipDuration,
                gpsRouteDuration = alertConfig.blipSettings.gpsRouteDuration,  --- Newly added
                useGpsRoute = true
            })
        else
            devPrint("User does not match job requirements for " .. alertType .. ": " .. user.source)
        end
    end
end

-- Server-side event to report a bug
RegisterServerEvent('bcc-sellNpc:reportAlert')
AddEventHandler('bcc-sellNpc:reportAlert', function()
    local src = source
    local pos = GetEntityCoords(GetPlayerPed(src))
    devPrint("Illegal report by : " .. src .. " at position: X:" .. pos.x .. " Y:" .. pos.y .. " Z:" .. pos.z) -- Debugging print

    -- Trigger the alert for the job with details
    AlertJob("illegalReport", _U('sellToNpcReport'), {x = pos.x, y = pos.y, z = pos.z})
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-sellNPC')
