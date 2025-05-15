local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"

-- Directement inclure les scripts
source(modDirectory .. "AdjustableMirrors.lua")
source(modDirectory .. "AdjustMirrorsEvent.lua")
source(modDirectory .. "AMDebug.lua")

-- Lire les infos depuis modDesc
local modDesc = loadXMLFile("modDesc", modDirectory .. "modDesc.xml")
g_AMDebug.mod_name = getXMLString(modDesc, "modDesc.title.en")
g_AMDebug.log_level_max = 1

AdjustableMirrors.modName = modName
AdjustableMirrors.version = getXMLString(modDesc, "modDesc.version")

-- Enregistrement de la spécialisation
local function initSpecialization(typeManager)
    if typeManager.typeName == "vehicle" then
        g_AMDebug.info("Running spec function: " .. modName .. " : " .. modDirectory)
        g_specializationManager:addSpecialization(
            "adjustableMirrors",
            "AdjustableMirrors",
            modDirectory .. "AdjustableMirrors.lua"
        )

        for typeName, typeDef in pairs(g_vehicleTypeManager:getTypes()) do
            if typeDef ~= nil and typeName ~= "locomotive" and typeName ~= "conveyorBelt" and typeName ~= "pickupConveyorBelt" then
                if typeDef.specializationsByName["drivable"]
                    and typeDef.specializationsByName["motorized"]
                    and typeDef.specializationsByName["enterable"] then

                    g_AMDebug.info("Attached specialization '" .. modName .. ".adjustableMirrors' to vehicleType '" .. tostring(typeName) .. "'")
                    g_vehicleTypeManager:addSpecialization(typeName, modName .. ".adjustableMirrors")
                end
            end
        end
    end
end

-- Enregistrement via TypeManager
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, initSpecialization)
