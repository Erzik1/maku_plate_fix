-- Původní funkci si uložíme pod novým názvem, abychom se vyhnuli cyklickému volání
local originalGetVehicleNumberPlateText = GetVehicleNumberPlateText

-- Override funkce GetVehicleNumberPlateText
GetVehicleNumberPlateText = function(vehicle)
    -- Získáme text SPZ z původní funkce
    local plate = originalGetVehicleNumberPlateText(vehicle)
    
    -- Pokud je SPZ prázdná, načteme hodnotu ze statebagu
    if plate:gsub('%s+', '') == '' then
        local statebag = Entity(vehicle).state.plate
        if statebag ~= nil then
            plate = statebag
        end
    end

    return plate
end
