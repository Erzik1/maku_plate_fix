local inventory = exports.ox_inventory

-- Serverový event pro sundání SPZ
RegisterNetEvent('maku_plate:server:takeoff', function(netId)
    local source = source

    if not inventory:CanCarryItem(source, 'vehicle_plate') then
        print('^1[error]^0 inventory full, cannot take off plate')
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local plate = GetVehicleNumberPlateText(vehicle)
    if plate == '' or plate == 'NO_PLATE' then
        print('^1[error]^0 plate not found on vehicle')
        return
    end

    local playerPed = GetPlayerPed(source)
    if DoesEntityExist(GetVehiclePedIsIn(playerPed)) then
        print('^1[error]^0 player is in vehicle')
        return
    end

    startProgressbar('Sundaváš poznávací značku', 5000, source)
    while getProgressbarStatus(source) == true do
        Citizen.Wait(500)
    end

    if getProgressbarStatus(source) == ABORTED_PROGRESSBAR then
        print('^1[error]^0 progressbar aborted')
        return
    end
    clearProgressbar(source)

    -- Uložení SPZ do statebagu a nastavení na prázdný text pro skrytí
    Entity(vehicle).state.plate = plate
    SetVehicleNumberPlateText(vehicle, '')  -- Tímto se SPZ skryje, ale zachováváme ji v statebagu

    inventory:AddItem(source, 'vehicle_plate', 1, {
        plate = plate,
        description = plate
    })
end)

-- Serverový event pro nasazení SPZ
RegisterNetEvent('maku_plate:server:puton', function(netId, plate)
    local source = source

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    local statebagPlate = Entity(vehicle).state.plate
    if statebagPlate ~= plate then
        print('^1[error]^0 plate mismatch, statebag: ' .. statebagPlate .. ', plate: ' .. plate)
        return
    end

    local playerPed = GetPlayerPed(source)
    if DoesEntityExist(GetVehiclePedIsIn(playerPed)) then
        print('^1[error]^0 player is in vehicle')
        return
    end

    local items = inventory:GetInventoryItems(source)
    local found = false
    for _, item in pairs(items) do
        if item.name == 'vehicle_plate' and item.metadata ~= nil and item.metadata.plate == plate then
            found = true
            break
        end
    end
    if not found then
        print('^1[error]^0 item not found in inventory')
        return
    end

    startProgressbar('Nasazuješ poznávací značku', 5000, source)
    while getProgressbarStatus(source) == true do
        Citizen.Wait(500)
    end

    if getProgressbarStatus(source) == ABORTED_PROGRESSBAR then
        print('^1[error]^0 progressbar aborted')
        return
    end
    clearProgressbar(source)

    local success = inventory:RemoveItem(source, 'vehicle_plate', 1, {
        plate = plate,
        description = plate
    })
    if success then
        SetVehicleNumberPlateText(vehicle, statebagPlate)  -- Vložíme zpět původní SPZ
    else
        print('^1[error]^0 failed to remove item from inventory')
    end
end)
