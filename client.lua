local Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

local selling = false
local saleCompleted = false
local itemForSale = nil
local globalBlip ={}  -- Initialize as nil for proper checking
local hasItems = true
local pos1 = nil  -- Initialize as nil until a position is assigned

-- Debug printing function
function devPrint(message)
    if Config.devMode then
        print("Server Debug: " .. message)
    end
end

-- Helper Function to Check Allowed Ped Type
function isPedTypeAllowed(pedType)
    for _, allowedType in ipairs(Config.AllowedPedTypes) do
        if pedType == allowedType then
            return true
        end
    end
    return false
end

--[[function GetPedType(ped)
    return Citizen.InvokeNative(0xFF059E1E4C01E63C, ped, Citizen.ResultAsInteger())
end]]--

function IsEntityFrozen(entity)
    return Citizen.InvokeNative(0x083D497D57B7400F, entity)
end

function IsEntityInsideBuiding()
    return Citizen.InvokeNative(0x083D497D57B7400F)
end


-- Function to play the animation using Citizen.InvokeNative
function playSellCompleteAnimation(entity)
    Citizen.InvokeNative(0xB31A277C1AC7B7FF, entity, 0, 0, -1457020913, 1, 1, 0, 0)
end

-- Set up interaction prompt group and register the 'H' key for interaction
local PromptGroup1 = BccUtils.Prompts:SetupPromptGroup()
local InteractPrompt = PromptGroup1:RegisterPrompt(_U('Negotiate'), BccUtils.Keys["MOUSE1"], 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })

-- Function to attempt selling items to NPC
local function attemptSellToNPC(ped, player)
    oldped = ped
    SetEntityAsMissionEntity(ped)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, true)

    if hasItems then
        TriggerServerEvent('bcc-sellNpc:reportAlert')
        local random = math.random(1, 12)
        
        if random == 3 or random == 7 or random == 11 or random == 5 then
            Core.NotifyObjective(_U('npcRejectOffer'), 4000)
            selling = false
            playSellCompleteAnimation(player)

            SetPedAsNoLongerNeeded(ped)
        else
            pos1 = GetEntityCoords(ped)
            playSellCompleteAnimation(player)
            playSellCompleteAnimation(ped)
            Citizen.Wait(2000)
            Core.NotifyObjective(_U('npcAcceptOffer'), 4000)
            TriggerServerEvent('bcc-sellNpc:itemsForSelling')
            Citizen.Wait(2000)
            SetPedAsNoLongerNeeded(ped)
            selling = true
        end
    else
        Core.NotifyLeft(_U('saleUnsuccessful'), _U('dontHaveItems'), "scoretimer_textures", "scoretimer_generic_cross", 3000, "red")
        selling = false
        SetPedAsNoLongerNeeded(ped)
    end
end


RegisterNetEvent('bcc-sellNpc:updateHasItems')
AddEventHandler('bcc-sellNpc:updateHasItems', function(hasInventoryItems)
    hasItems = hasInventoryItems
end)

Citizen.CreateThread(function()
    while true do
        Wait(5000)
        TriggerServerEvent('bcc-sellNpc:checkInventory')
    end
end)

Citizen.CreateThread(function()
    local inRange = false
    while true do
        local sleep = 1000
        local player = PlayerPedId()
        local playerLoc = GetEntityCoords(player)
        local handle, ped = FindFirstPed()
        local success

        repeat
            success, ped = FindNextPed(handle)
            local pos = GetEntityCoords(ped)
            local distance = #(playerLoc - pos)

            if hasItems and not IsPedInAnyVehicle(ped) and not IsPedDeadOrDying(ped) and not IsPedAPlayer(ped)
                and not IsEntityAttached(ped) and not IsEntityFrozen(ped) and not IsInteriorScene() then
                local pedType = GetPedType(ped)
                if isPedTypeAllowed(pedType) and ped ~= oldped then
                    currentped = ped

                    if distance < 4 then
                        sleep = 0
                        if IsControlPressed(0, BccUtils.Keys["G"]) then
                            if not inRange then
                                PromptGroup1:ShowGroup(_U('aproachNpc'))
                                inRange = true
                            end
                        end

                        if inRange and InteractPrompt:HasCompleted() then
                            attemptSellToNPC(ped, player)
                        end
                    else
                        inRange = false
                    end
                end
            end
        until not success
        EndFindPed(handle)
        Wait(sleep)
    end
end)

RegisterNetEvent('bcc-sellNpc:currentlySelling')
AddEventHandler('bcc-sellNpc:currentlySelling', function(item)
    hasItems = true
    selling = true
    itemForSale = item
    devPrint("Sale started for item:", itemForSale.name, "with price:", itemForSale.price)
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if selling and hasItems and pos1 then  -- Check pos1 is not nil
            local playerLoc = GetEntityCoords(PlayerPedId())
            local distance = GetDistanceBetweenCoords(pos1.x, pos1.y, pos1.z, playerLoc.x, playerLoc.y, playerLoc.z, true)

            if distance > 6 then
                Core.NotifyObjective(_U('tooFarAway'), 4000)
                selling = false
                SetEntityAsMissionEntity(oldped)
                SetPedAsNoLongerNeeded(oldped)
            else
                saleCompleted = true
                selling = false
                SetEntityAsMissionEntity(oldped)
                SetPedAsNoLongerNeeded(oldped)
                TriggerServerEvent('bcc-sellNpc:moneyFromSelling', itemForSale)
            end
        end
    end
end)

-- Reset and Check for New Inventory on Client Side
Citizen.CreateThread(function()
    while true do
        Wait(2000)
        if not saleCompleted and not hasItems then
            TriggerServerEvent('bcc-sellNpc:itemsForSelling')
        end
    end
end)

RegisterNetEvent('bcc-sellNpc:cancelSelling')
AddEventHandler('bcc-sellNpc:cancelSelling', function()
    saleCompleted = false
    hasItems = false
    selling = false
    devPrint("No items available to sell.")
end)

RegisterNetEvent('bcc-sellNpc:doneSelling')
AddEventHandler('bcc-sellNpc:doneSelling', function()
    saleCompleted = false
    hasItems = false
    itemForSale = nil
    Core.NotifyLeft(_U('saleUnsuccessful'), _U('dontHaveItems'), "scoretimer_textures", "scoretimer_generic_cross", 3000, "red")
end)

RegisterNetEvent('bcc-sellNpc:alertsNotify')
AddEventHandler('bcc-sellNpc:alertsNotify', function(data)
    devPrint("Received notification: " .. data.message)
    Core.NotifyLeft(data.message, "", "scoretimer_textures", "scoretimer_generic_cross", 5000)

    if data.x and data.y and data.z then
        if globalBlip then
            BccUtils.Blips:RemoveBlip(globalBlip.rawblip)
        end

        globalBlip = BccUtils.Blips:SetBlip(data.blipLabel, data.blipSprite, data.blipScale, data.x, data.y, data.z)
        
        SetTimeout(data.blipDuration, function()
            if globalBlip then
                BccUtils.Blips:RemoveBlip(globalBlip.rawblip)
                globalBlip = {}
            end
        end)

        if data.useGpsRoute then
            StartGpsMultiRoute(GetHashKey("COLOR_RED"), true, true)
            AddPointToGpsMultiRoute(data.x, data.y, data.z)
            SetGpsMultiRouteRender(true)

            SetTimeout(data.gpsRouteDuration or data.blipDuration, function()
                ClearGpsMultiRoute()
                SetGpsMultiRouteRender(false)
                devPrint("GPS route cleared.")
            end)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and globalBlip then
        BccUtils.Blips:RemoveBlip(globalBlip.rawblip)
        globalBlip = {}
        devPrint("Blip removed as resource is stopping.")
    end
end)
