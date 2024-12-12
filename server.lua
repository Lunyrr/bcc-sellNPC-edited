local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()

local discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar)
-- Add these at the top with your other state variables
local sellLimits = {}
local maxSellsWithoutLaw = 3 -- You can move this to Config file later

-- Debug printing function
function devPrint(message)
    if Config.devMode then
        print("^1[DEV MODE] ^4" .. tostring(message))
    end
end

-- Helper function to check if a job is in a specific group
local function isJobInGroup(jobName, jobGroup)
    for _, groupJob in ipairs(jobGroup) do
        if groupJob == jobName then
            return true
        end
    end
    return false
end

-- Helper function to dynamically check job requirements
local function isJobAllowed(jobName, jobGroups)
    for _, group in pairs(jobGroups) do
        devPrint("Checking job group: " .. json.encode(group))
        for _, allowedJob in ipairs(group) do
            devPrint("Matching " .. tostring(jobName) .. " with " .. tostring(allowedJob))
            if jobName == allowedJob then
                return true
            end
        end
    end
    return false
end

RegisterServerEvent('bcc-sellNpc:itemsForSelling')
AddEventHandler('bcc-sellNpc:itemsForSelling', function()
    local _source = source
    local user = Core.getUser(_source)
    if not user then
        devPrint("Error: User not found for source " .. _source)
        return
    end

    local Character = user.getUsedCharacter
    if not Character then
        devPrint("Error: Character not found for source " .. _source)
        return
    end

    local foundItem = nil

    for _, itemForSell in ipairs(Config.itemsForSell) do
        local itemCount = exports.vorp_inventory:getItemCount(_source, nil, itemForSell.name)
        if itemCount and itemCount > 0 then
            foundItem = itemForSell
            break
        end
    end

    if foundItem then
        devPrint("Server: Sending item to client: " .. foundItem.name)
        TriggerClientEvent('bcc-sellNpc:currentlySelling', _source, foundItem)
    else
        devPrint("Server: No items found for sale.")
        TriggerClientEvent('bcc-sellNpc:cancelSelling', _source)
    end
end)

local activeSales = {}
RegisterServerEvent('bcc-sellNpc:moneyFromSelling')
AddEventHandler('bcc-sellNpc:moneyFromSelling', function(itemForSale)
    local _source = source
    devPrint("moneyFromSelling event triggered")

    -- Check if itemForSale is valid
    if not itemForSale or not itemForSale.name then
        devPrint("Error: Invalid itemForSale received from client.")
        TriggerClientEvent('bcc-sellNpc:doneSelling', _source)
        return
    end

    -- Prevent multiple triggers for the same player
    if activeSales[_source] then
        devPrint("Sale already in progress for player " .. _source)
        return
    end
    activeSales[_source] = true -- Mark sale as in progress

    devPrint("moneyFromSelling event triggered for player " .. _source)
    local user = Core.getUser(_source)
    if not user then
        activeSales[_source] = nil -- Reset sale status
        return
    end

    local Character = user.getUsedCharacter
    if not Character then
        activeSales[_source] = nil -- Reset sale status
        return
    end

    local itemCount = exports.vorp_inventory:getItemCount(_source, nil, itemForSale.name)
    if itemCount and itemCount > 0 then
        exports.vorp_inventory:subItem(_source, itemForSale.name, 1, {})
        Character.addCurrency(0, itemForSale.price)

        local playerName = Character.firstname .. " " .. Character.lastname
        local playerId = Character.identifier
        local saleMessage = "**NPC Sale Report**\n"
            .. "Player: " .. playerName .. "\n"
            .. "Player Identifier: " .. playerId .. "\n"
            .. "Item Sold: " .. itemForSale.name .. "\n"
            .. "Amount Earned: $" .. itemForSale.price

        discord:sendMessage(saleMessage)
        Core.NotifyAvanced(
            _source,
            _U('saleSuccessful') .. "\n" .. _U('youReceived') .. itemForSale.price,
            "inventory_items",
            "money_billstack",
            3000,
            "green"
        )
        -- After successful sale, update the sell limit if no law enforcement is online
        local lawEnforcementOnline = false
        for _, playerId in ipairs(GetPlayers()) do
            local otherUser = Core.getUser(playerId)
            if otherUser then
                local otherCharacter = otherUser.getUsedCharacter
                if otherCharacter and isJobInGroup(otherCharacter.job, Config.RequiredJobs.Jobs) then
                    lawEnforcementOnline = true
                    break
                end
            end
        end

        if not lawEnforcementOnline then
            sellLimits[_source] = (sellLimits[_source] or 0) + 1
            devPrint("Updated sell limit for player " .. _source .. " to " .. sellLimits[_source])
        end
    else
        devPrint("Error: Item missing or invalid for sale.")
        TriggerClientEvent('bcc-sellNpc:doneSelling', _source)
    end

    -- Reset the active sale status
    activeSales[_source] = nil
end)

-- Event to check inventory for sellable items
RegisterServerEvent('bcc-sellNpc:checkInventory')
AddEventHandler('bcc-sellNpc:checkInventory', function()
    local _source = source
    local hasInventoryItems = false

    for _, item in ipairs(Config.itemsForSell) do
        local itemCount = exports.vorp_inventory:getItemCount(_source, nil, item.name)
        if itemCount and itemCount > 0 then
            hasInventoryItems = true
            break
        end
    end

    TriggerClientEvent('bcc-sellNpc:updateHasItems', _source, hasInventoryItems)
end)

-- Modify your existing JobCheck function to include the sell limit check
RegisterServerEvent('bcc-sellNPC:JobCheck')
AddEventHandler('bcc-sellNPC:JobCheck', function()
    local src = source
    local user = Core.getUser(src)

    if not user then
        devPrint("User not found for source: " .. tostring(src))
        TriggerClientEvent('bcc-sellNpc:jobCheckFailed', src, _U('userNotFound'))
        return
    end

    local Character = user.getUsedCharacter
    if not Character then
        devPrint("Character data missing for source: " .. tostring(src))
        TriggerClientEvent('bcc-sellNpc:jobCheckFailed', src, _U('characterNotFound'))
        return
    end

    local UserJob = Character.job

    -- Check if the player's job is prohibited
    if Config.NoSellJobsEnable and isJobInGroup(UserJob, Config.NoSellJobs) then
        devPrint("User has a prohibited job: " .. UserJob)
        Core.NotifyObjective(src, _U('NotAllowed'), 4000)
        TriggerClientEvent('bcc-sellNpc:jobCheckFailed', src, _U('NotAllowed'))
        return
    end

    -- Check for law enforcement online
    local lawEnforcementOnline = false
    local availableJobs = 0

    if Config.RequiredJobEnble and Config.RequiredJobs.Amount > 0 then
        for _, playerId in ipairs(GetPlayers()) do
            local otherUser = Core.getUser(playerId)
            if otherUser then
                local otherCharacter = otherUser.getUsedCharacter
                if otherCharacter and isJobInGroup(otherCharacter.job, Config.RequiredJobs.Jobs) then
                    availableJobs = availableJobs + 1
                    lawEnforcementOnline = true
                end
            end
        end

        -- Check sell limit if no law enforcement is online
        if not lawEnforcementOnline then
            sellLimits[src] = sellLimits[src] or 0
            if sellLimits[src] >= maxSellsWithoutLaw then
                local errorMsg = _U('sellLimitReached') -- Add this to your locale file
                devPrint("Sell limit reached for player: " .. src)
                Core.NotifyObjective(src, errorMsg, 4000)
                TriggerClientEvent('bcc-sellNpc:jobCheckFailed', src, errorMsg)
                return
            end
        end

        if availableJobs < Config.RequiredJobs.Amount then
            local errorMsg = _U('notEnoughOfficers') ..
            Config.RequiredJobs.Amount .. _U('officerAvaiable') .. availableJobs
            devPrint("Not enough required jobs online. Needed: " ..
            Config.RequiredJobs.Amount .. ", Found: " .. availableJobs)
            Core.NotifyObjective(src, errorMsg, 4000)
            TriggerClientEvent('bcc-sellNpc:jobCheckFailed', src, errorMsg)
            return
        end
    end

    -- Job check passed
    devPrint("Job check passed for source: " .. tostring(src))
    TriggerClientEvent('bcc-sellNpc:jobCheckPassed', src)
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
            devPrint("User does not meet job grade requirements for alert type: " ..
            tostring(alertType) .. " with job: " .. character.job .. " at grade: " .. character.jobGrade)
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

function AlertJob(alertType, message, coords)
    local alertConfig = Config.alertPermissions[alertType]
    if not alertConfig then
        devPrint("Alert configuration missing for type: " .. alertType)
        return
    end

    local users = Core.getUsers()
    for _, user in pairs(users) do
        if user and CheckJob(user.source, alertType) then
            devPrint("Sending alert to user: " ..
            user.source .. " at coords: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)

            TriggerClientEvent('bcc-sellNpc:alertsNotify', user.source, {
                message = message,
                notificationType = "alert",
                x = coords.x,
                y = coords.y,
                z = coords.z,
                blipSprite = alertConfig.blipSettings.blipSprite or 1,        -- Default value for sprite
                blipScale = alertConfig.blipSettings.blipScale or 1.0,        -- Default value for scale
                blipColor = alertConfig.blipSettings.blipColor or 1,          -- Default color
                blipLabel = alertConfig.blipSettings.blipLabel or "Alert",
                blipDuration = alertConfig.blipSettings.blipDuration or 5000, -- Default duration
                gpsRouteDuration = alertConfig.blipSettings.gpsRouteDuration or 5000,
                useGpsRoute = alertConfig.blipSettings.useGpsRoute or false
            })
            --else
            --devPrint("User does not match job requirements for " .. alertType .. ": " .. user.source)
        end
    end
end

-- Server-side event to report a bug
RegisterServerEvent('bcc-sellNpc:reportAlert')
AddEventHandler('bcc-sellNpc:reportAlert', function()
    local src = source
    local pos = GetEntityCoords(GetPlayerPed(src))
    if itemForSale.isIllegal then
        devPrint("Illegal report by : " .. src .. " at position: X:" .. pos.x .. " Y:" .. pos.y .. " Z:" .. pos.z) -- Debugging print

        -- Trigger the alert for the job with details
        AlertJob("illegalReport", _U('sellToNpcReport'), { x = pos.x, y = pos.y, z = pos.z })
    end
end)

-- Version check
BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-sellNPC')
