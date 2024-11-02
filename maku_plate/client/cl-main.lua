local inventory = exports.ox_inventory

-- Funkce pro nalezení nejbližšího vozidla
function getClosestVehicleToPlayer(plyPos, radius)
    local retval, statusCode = nil, 'unk'
    local vehicle = GetClosestVehicle(plyPos.x, plyPos.y, plyPos.z, radius or CLOSEST_VEHICLE_RANGE, 0, 23)
    if vehicle then
        retval = vehicle
        statusCode = 'found_vehicle'
    end
    return retval, statusCode
end

-- Kontrola zda je zdroj aktivní
function isResourcePresent(resourceName)
    local state = GetResourceState(resourceName)
    return state == 'started' or state == 'starting'
end

-- Sundání SPZ
local function takeOff(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('maku_plate:server:takeoff', netId)
end

AddEventHandler('maku_plate:client:takeoff', takeOff)
exports('takeOff', takeOff)

-- Nasazení SPZ
local function putOn(vehicle, plate)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('maku_plate:server:puton', netId, plate)
end

AddEventHandler('maku_plate:client:puton', putOn)
exports('putOn', putOn)

-- Využití předmětu pro nasazení SPZ
exports('itemUsage', function(data, slot)
    local vehicle, statusCode = getClosestVehicleToPlayer(GetEntityCoords(PlayerPedId()))
    if DoesEntityExist(vehicle) then
        if statusCode == 'found_vehicle' then
            putOn(vehicle, slot.metadata.plate)
        end
    else
        print('^1[error]^0 no vehicle found (itemUsage)')
    end
end)

-- Nastavení ox_target pro sundání SPZ
if isResourcePresent('ox_target') then
    local target = exports.ox_target

    Citizen.CreateThread(function()
        target:addGlobalVehicle({
            {
                label = "Sundat SPZ", -- Text tlačítka
                name = 'takeoffplate', -- Název akce
                icon = 'fa-solid fa-tarp', -- Ikona
                distance = 3.0, -- Maximální vzdálenost
                canInteract = function(vehicle, distance, coords, name, bone)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    return plate ~= '' and plate ~= 'NO_PLATE'
                end,
                onSelect = function(data)
                    takeOff(data.entity)
                end
            }
        })
    end)

    -- Odebrání akce při vypnutí zdroje
    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        target:removeGlobalVehicle('takeoffplate')
    end)
else
    RegisterCommand('plate', function(source, args, raw)
        local plyPed = PlayerPedId()
        local plyPos = GetEntityCoords(plyPed)
        local vehicle, statusCode = getClosestVehicleToPlayer(plyPos)
        if DoesEntityExist(vehicle) then
            takeOff(vehicle)
        else
            print('^1[error]^0 no vehicle found (command)')
        end
    end, false)
end
