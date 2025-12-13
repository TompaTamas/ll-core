-- Cutscene Props and Vehicle Management
local cutsceneProps = {}
local cutsceneVehicles = {}

-- PROPS
function SpawnCutsceneProp(propData)
    local model = GetHashKey(propData.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    
    local coords = propData.coords or vector3(0, 0, 0)
    local rotation = propData.rotation or vector3(0, 0, 0)
    
    local prop = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityRotation(prop, rotation.x, rotation.y, rotation.z, 2, true)
    
    if propData.freeze then
        FreezeEntityPosition(prop, true)
    end
    
    if propData.dynamic then
        SetEntityDynamic(prop, true)
    else
        SetEntityDynamic(prop, false)
    end
    
    if propData.collision ~= nil then
        SetEntityCollision(prop, propData.collision, propData.collision)
    end
    
    if propData.visible ~= nil then
        SetEntityVisible(prop, propData.visible, false)
    end
    
    -- Store prop reference
    table.insert(cutsceneProps, {
        entity = prop,
        data = propData
    })
    
    LL.Log("Cutscene prop spawned: " .. (propData.name or propData.model), "success")
    
    return prop
end

function DeleteCutsceneProp(prop)
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
        
        -- Remove from storage
        for i, propData in ipairs(cutsceneProps) do
            if propData.entity == prop then
                table.remove(cutsceneProps, i)
                break
            end
        end
        
        LL.Log("Cutscene prop deleted", "info")
    end
end

function MovePropToPosition(prop, coords, rotation)
    if DoesEntityExist(prop) then
        SetEntityCoords(prop, coords.x, coords.y, coords.z, false, false, false, false)
        
        if rotation then
            SetEntityRotation(prop, rotation.x, rotation.y, rotation.z, 2, true)
        end
    end
end

function AttachPropToEntity(prop, entity, boneIndex, offset, rotation)
    if DoesEntityExist(prop) and DoesEntityExist(entity) then
        AttachEntityToEntity(
            prop, entity, boneIndex,
            offset.x, offset.y, offset.z,
            rotation.x, rotation.y, rotation.z,
            false, false, false, false, 2, true
        )
        
        LL.Log("Prop attached to entity", "info")
    end
end

function DetachProp(prop)
    if DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        LL.Log("Prop detached", "info")
    end
end

function CleanupAllCutsceneProps()
    for _, propData in ipairs(cutsceneProps) do
        if DoesEntityExist(propData.entity) then
            DeleteEntity(propData.entity)
        end
    end
    
    cutsceneProps = {}
    
    LL.Log("All cutscene props cleaned up", "info")
end

-- VEHICLES
function SpawnCutsceneVehicle(vehicleData)
    local model = GetHashKey(vehicleData.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    
    local coords = vehicleData.coords or vector3(0, 0, 0)
    local heading = vehicleData.heading or 0.0
    
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, false, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, false, true, true)
    
    -- Apply colors if provided
    if vehicleData.colors then
        SetVehicleColours(vehicle, vehicleData.colors.primary or 0, vehicleData.colors.secondary or 0)
    end
    
    -- Apply mods if provided
    if vehicleData.mods then
        ApplyVehicleMods(vehicle, vehicleData.mods)
    end
    
    -- Apply extras if provided
    if vehicleData.extras then
        ApplyVehicleExtras(vehicle, vehicleData.extras)
    end
    
    if vehicleData.locked then
        SetVehicleDoorsLocked(vehicle, 2)
    end
    
    if vehicleData.freeze then
        FreezeEntityPosition(vehicle, true)
    end
    
    -- Store vehicle reference
    table.insert(cutsceneVehicles, {
        entity = vehicle,
        data = vehicleData
    })
    
    LL.Log("Cutscene vehicle spawned: " .. (vehicleData.name or vehicleData.model), "success")
    
    return vehicle
end

function ApplyVehicleMods(vehicle, mods)
    SetVehicleModKit(vehicle, 0)
    
    for modType, modValue in pairs(mods) do
        local modTypeNum = tonumber(modType)
        local modValueNum = tonumber(modValue)
        
        if modTypeNum and modValueNum then
            SetVehicleMod(vehicle, modTypeNum, modValueNum, false)
        end
    end
    
    LL.Log("Vehicle mods applied", "info")
end

function ApplyVehicleExtras(vehicle, extras)
    for extraId, enabled in pairs(extras) do
        local extraIdNum = tonumber(extraId)
        if extraIdNum then
            SetVehicleExtra(vehicle, extraIdNum, not enabled)
        end
    end
end

function DeleteCutsceneVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        
        -- Remove from storage
        for i, vehData in ipairs(cutsceneVehicles) do
            if vehData.entity == vehicle then
                table.remove(cutsceneVehicles, i)
                break
            end
        end
        
        LL.Log("Cutscene vehicle deleted", "info")
    end
end

function MoveVehicleToPosition(vehicle, coords, heading)
    if DoesEntityExist(vehicle) then
        SetEntityCoords(vehicle, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(vehicle, heading)
        SetVehicleOnGroundProperly(vehicle)
    end
end

function SetVehicleDoors(vehicle, doorIndex, open)
    if DoesEntityExist(vehicle) then
        if open then
            SetVehicleDoorOpen(vehicle, doorIndex, false, false)
        else
            SetVehicleDoorShut(vehicle, doorIndex, false)
        end
    end
end

function SetVehicleLights(vehicle, state)
    if DoesEntityExist(vehicle) then
        SetVehicleLights(vehicle, state)
    end
end

function SetVehicleSiren(vehicle, enabled)
    if DoesEntityExist(vehicle) then
        SetVehicleSiren(vehicle, enabled)
    end
end

function CleanupAllCutsceneVehicles()
    for _, vehData in ipairs(cutsceneVehicles) do
        if DoesEntityExist(vehData.entity) then
            DeleteEntity(vehData.entity)
        end
    end
    
    cutsceneVehicles = {}
    
    LL.Log("All cutscene vehicles cleaned up", "info")
end

-- Cleanup all entities
function CleanupAllCutsceneEntities()
    CleanupAllCutsceneProps()
    CleanupAllCutsceneVehicles()
end

function GetCutscenePropByIndex(index)
    if cutsceneProps[index] then
        return cutsceneProps[index].entity
    end
    return nil
end

function GetCutsceneVehicleByIndex(index)
    if cutsceneVehicles[index] then
        return cutsceneVehicles[index].entity
    end
    return nil
end

function GetAllCutsceneProps()
    return cutsceneProps
end

function GetAllCutsceneVehicles()
    return cutsceneVehicles
end

-- Exports
exports('SpawnCutsceneProp', SpawnCutsceneProp)
exports('DeleteCutsceneProp', DeleteCutsceneProp)
exports('MovePropToPosition', MovePropToPosition)
exports('AttachPropToEntity', AttachPropToEntity)
exports('DetachProp', DetachProp)
exports('CleanupAllCutsceneProps', CleanupAllCutsceneProps)

exports('SpawnCutsceneVehicle', SpawnCutsceneVehicle)
exports('DeleteCutsceneVehicle', DeleteCutsceneVehicle)
exports('MoveVehicleToPosition', MoveVehicleToPosition)
exports('SetVehicleDoors', SetVehicleDoors)
exports('SetVehicleLights', SetVehicleLights)
exports('SetVehicleSiren', SetVehicleSiren)
exports('ApplyVehicleMods', ApplyVehicleMods)
exports('CleanupAllCutsceneVehicles', CleanupAllCutsceneVehicles)

exports('CleanupAllCutsceneEntities', CleanupAllCutsceneEntities)
exports('GetCutscenePropByIndex', GetCutscenePropByIndex)
exports('GetCutsceneVehicleByIndex', GetCutsceneVehicleByIndex)
exports('GetAllCutsceneProps', GetAllCutsceneProps)
exports('GetAllCutsceneVehicles', GetAllCutsceneVehicles)