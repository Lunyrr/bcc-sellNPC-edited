local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()

-- State Variables
local selling = false
local saleCompleted = false
local saleProcessing = false
local itemForSale = nil
local hasItems = true
local targetPed = nil
local currentPlayer = nil
local globalBlip = nil
local interactedNPCs = {} -- Store NPCs that have already been interacted with
local currentlySelling = false -- Guard for currentlySelling event
local sellLimit = 0
local lawEnforcementOnline = false

-- Add at the top with other state variables
local interactionResetTime = 300000 -- 5 minutes in milliseconds

-- Debug Printing Function
local function devPrint(message)
    if Config.devMode then
        print("^1[DEBUG]^0: " .. tostring(message))
    end
end

-- Helper Function: Check Allowed Ped Type
local function isPedTypeAllowed(pedType)
    for _, allowedType in ipairs(Config.AllowedPedTypes) do
        if pedType == allowedType then
            return true
        end
    end
    return false
end

-- Helper Function: Check if NPC has already been interacted with
local function hasInteractedWithNPC(ped)
    if NetworkGetEntityIsNetworked(ped) then
        local pedId = NetworkGetNetworkIdFromEntity(ped)
        return interactedNPCs[pedId] == true
    else
        return false
    end
end

-- Helper Function: Mark NPC as interacted
local function markNPCAsInteracted(ped)
    if not NetworkGetEntityIsNetworked(ped) then
        NetworkRegisterEntityAsNetworked(ped)
    end
    local pedId = NetworkGetNetworkIdFromEntity(ped)
    interactedNPCs[pedId] = true
end

-- Helper Function: Play selling animation
local function playSellAnimation(entity)
    Citizen.InvokeNative(0xB31A277C1AC7B7FF, entity, 0, 0, -1457020913, 1, 1, 0, 0)
end

-- Interaction Prompt Setup
local PromptGroup1 = BccUtils.Prompts:SetupPromptGroup()
local InteractPrompt = PromptGroup1:RegisterPrompt(_U('Negotiate'), BccUtils.Keys["ENTER"], 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })

local function attemptSellToNPC(player, ped)
    if selling then
        devPrint("Already selling, ignoring duplicate attempt.")
        return
    end

    -- Check sell limit if feature is enabled
    if Config.SellLimitNoLawEnabled and not lawEnforcementOnline and sellLimit >= Config.MaxSellsWithoutLaw then
        Core.NotifyObjective(_U('sellLimitReached'), 4000)
        SetPedAsNoLongerNeeded(ped)
        return
    end

    SetEntityAsMissionEntity(ped)
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)

    if hasInteractedWithNPC(ped) then
        Core.NotifyObjective(_U('alreadyInteractedWithNpc'), 4000)
        SetPedAsNoLongerNeeded(ped)
        return
    end

    selling = true

    if hasItems then
        devPrint("Starting interaction with NPC for selling.")
        TriggerServerEvent('bcc-sellNpc:itemsForSelling')
        TriggerServerEvent('bcc-sellNpc:reportAlert', itemForSale)

        Citizen.SetTimeout(100, function()
            if not itemForSale or not itemForSale.name then
                devPrint("Error: itemForSale is nil or invalid. Aborting sale.")
                selling = false
                SetPedAsNoLongerNeeded(ped)
                return
            end

            local rejectionChance = math.random(1, 12)
            if rejectionChance % 3 == 0 then
                Core.NotifyObjective(_U('npcRejectOffer'), 4000)
            else
                playSellAnimation(player)
                playSellAnimation(ped)
                Citizen.Wait(2000)
                Core.NotifyObjective(_U('npcAcceptOffer'), 4000)

                -- Update sell limit if feature is enabled and no law enforcement
                if Config.SellLimitNoLawEnabled and not lawEnforcementOnline then
                    sellLimit = sellLimit + 1
                    devPrint("Local sell limit increased to: " .. sellLimit)
                end

                TriggerServerEvent('bcc-sellNpc:moneyFromSelling', itemForSale)
                markNPCAsInteracted(ped)
                devPrint("Sale completed for item: " .. itemForSale.name)
            end

            selling = false
            SetPedAsNoLongerNeeded(ped)
        end)
    else
        Core.NotifyLeft(_U('saleUnsuccessful'), _U('dontHaveItems'), "scoretimer_textures", "scoretimer_generic_cross", 3000, "red")
        selling = false
        SetPedAsNoLongerNeeded(ped)
    end
end

-- Job Check Events
RegisterNetEvent('bcc-sellNpc:jobCheckPassed')
AddEventHandler('bcc-sellNpc:jobCheckPassed', function()
    if currentPlayer and targetPed then
        attemptSellToNPC(currentPlayer, targetPed)
    else
        Core.NotifyLeft(_U('saleUnsuccessful'), _U('dontHaveItems'), "scoretimer_textures", "scoretimer_generic_cross", 3000, "red")
    end
end)

RegisterNetEvent('bcc-sellNpc:jobCheckFailed')
AddEventHandler('bcc-sellNpc:jobCheckFailed', function(reason)
    Core.NotifyObjective(reason, 4000)
    selling = false
    SetPedAsNoLongerNeeded(targetPed)
end)

-- Update Inventory
RegisterNetEvent('bcc-sellNpc:updateHasItems')
AddEventHandler('bcc-sellNpc:updateHasItems', function(hasInventoryItems)
    hasItems = hasInventoryItems
end)

-- Add a new thread to handle reset
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(interactionResetTime)
        interactedNPCs = {}
        devPrint("Reset NPC interaction tracking")
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local player = PlayerPedId()
        local playerLoc = GetEntityCoords(player)
        local handle, ped = FindFirstPed()
        local success

        repeat
            success, ped = FindNextPed(handle)
            if success and isPedTypeAllowed(GetPedType(ped)) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped) and #(playerLoc - GetEntityCoords(ped)) < 2.0 then
                if ped ~= targetPed and not selling then
                    sleep = 0
                    if IsControlPressed(0, BccUtils.Keys["B"]) then
                        PromptGroup1:ShowGroup(_U('aproachNpc'))
                    end
        
                    if InteractPrompt:HasCompleted() then
                        if hasInteractedWithNPC(ped) then
                            Core.NotifyObjective(_U('alreadyInteractedWithNpc'), 4000)
                        else
                            currentPlayer = player
                            targetPed = ped
                            TriggerServerEvent('bcc-sellNPC:JobCheck')
                        end
                    end
                end
            end
        until not success

        EndFindPed(handle)
        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent('bcc-sellNpc:currentlySelling')
AddEventHandler('bcc-sellNpc:currentlySelling', function(item)
    if currentlySelling then
        devPrint("Currently selling already in progress, ignoring.")
        return
    end

    currentlySelling = true

    if not item or not item.name then
        devPrint("Error: Invalid item received in currentlySelling.")
        currentlySelling = false
        return
    end

    -- Properly assign itemForSale
    itemForSale = item
    devPrint("currentlySelling: itemForSale assigned with " .. item.name .. " at price " .. item.price)

    Citizen.SetTimeout(5000, function()
        currentlySelling = false
    end)
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if selling and hasItems and targetPed and not saleProcessing then
            local playerLoc = GetEntityCoords(PlayerPedId())
            local pedLoc = GetEntityCoords(targetPed)

            if DoesEntityExist(targetPed) then
                local distance = #(playerLoc - pedLoc)
                if distance > 6.0 then
                    Core.NotifyObjective(_U('tooFarAway'), 4000)
                    selling = false
                    saleProcessing = false
                    SetPedAsNoLongerNeeded(targetPed)
                    targetPed = nil
                elseif not saleCompleted then
                    saleProcessing = true
                    saleCompleted = true
                    selling = false

                    if itemForSale and itemForSale.name then
                        TriggerServerEvent('bcc-sellNpc:moneyFromSelling', itemForSale)
                        devPrint("Sale completed for item: " .. itemForSale.name)
                    else
                        devPrint("Error: itemForSale is nil or invalid.")
                    end

                    SetPedAsNoLongerNeeded(targetPed)
                    targetPed = nil
                end
            else
                devPrint("Target NPC no longer exists.")
                selling = false
                saleProcessing = false
                targetPed = nil
            end
        end
    end
end)

-- Cancel Selling
RegisterNetEvent('bcc-sellNpc:cancelSelling')
AddEventHandler('bcc-sellNpc:cancelSelling', function()
    saleCompleted = false
    hasItems = false
    selling = false
    devPrint("No items available to sell.")
end)

-- Sale Complete
RegisterNetEvent('bcc-sellNpc:doneSelling')
AddEventHandler('bcc-sellNpc:doneSelling', function()
    saleCompleted = true
    hasItems = false
    itemForSale = nil
    Core.NotifyLeft(_U('saleUnsuccessful'), _U('dontHaveItems'), "scoretimer_textures", "scoretimer_generic_cross", 3000, "red")
end)

-- Handle alert notifications
RegisterNetEvent('bcc-sellNpc:alertsNotify')
AddEventHandler('bcc-sellNpc:alertsNotify', function(data)
    devPrint("Received notification: " .. data.message)
    Core.NotifyLeft(data.message, "", "scoretimer_textures", "scoretimer_generic_cross", 5000)

    if data.x and data.y and data.z then
        if globalBlip then
            RemoveBlip(globalBlip)
        end
        local globalBlip = Citizen.InvokeNative(0x45f13b7e0a15c880, 1247852480, data.x, data.y, data.z, 64.0)
        --globalBlip = BccUtils.Blips:SetBlip(data.blipLabel, data.blipSprite, data.blipScale, data.x, data.y, data.z)
        ---globalBlip = BccUtils.Blips:SetRadius(-1282792512, 64.0, )


        SetTimeout(data.blipDuration, function()
            if globalBlip then
                RemoveBlip(globalBlip)
            end
        end)
    end
end)

-- Add these event handlers
RegisterNetEvent('bcc-sellNpc:updateLawStatus')
AddEventHandler('bcc-sellNpc:updateLawStatus', function(hasLawOnline)
    if Config.SellLimitNoLawEnabled then
        lawEnforcementOnline = hasLawOnline
        if hasLawOnline then
            sellLimit = 0 -- Reset limit when law enforcement comes online
            devPrint("Law enforcement online - sell limits reset")
        end
    end
end)

RegisterNetEvent('bcc-sellNpc:updateSellLimit')
AddEventHandler('bcc-sellNpc:updateSellLimit', function(currentLimit)
    if Config.SellLimitNoLawEnabled then
        sellLimit = currentLimit
        devPrint("Sell limit updated to: " .. sellLimit)
    end
end)

-- Clean up blips on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and globalBlip then
        RemoveBlip(globalBlip)
        devPrint("Blip removed on resource stop.")
    end
end)
