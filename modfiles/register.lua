--
-- AdjustableMirrors
--
-- Description: Register the mod with FS
--
-- Name: AdjustableMirrors
--
-- Copyright (c) StjerneIdioten, 2024


local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"

source(Utils.getFilename("AdjustableMirrors.lua", modDirectory))
source(Utils.getFilename("AdjustMirrorsEvent.lua", modDirectory))
source(Utils.getFilename("AMDebug.lua", modDirectory))

local modDesc = loadXMLFile("modDesc", modDirectory .. "modDesc.xml")
g_AMDebug.mod_name = getXMLString(modDesc, "modDesc.title.en")
g_AMDebug.log_level_max = 1

AdjustableMirrors.modName = modName
AdjustableMirrors.version = getXMLString(modDesc, "modDesc.version")

local function initSpecialization(manager)
	if manager.typeName == "vehicle" then
		g_AMDebug.info("Running spec function: " .. modName .. " : " .. modDirectory)
		g_specializationManager:addSpecialization("adjustableMirrors", "AdjustableMirrors", Utils.getFilename("AdjustableMirrors.lua", modDirectory), nil)
		
		for typeName, typeDef in pairs(g_vehicleTypeManager:getTypes()) do
			if typeDef ~= nil and typeName ~= "locomotive" and typeName ~= "conveyorBelt" and typeName ~= "pickupConveyorBelt" then
				if SpecializationUtil.hasSpecialization(Drivable, typeDef.specializations) and 
					SpecializationUtil.hasSpecialization(Motorized, typeDef.specializations) and
					SpecializationUtil.hasSpecialization(Enterable, typeDef.specializations) then
						g_AMDebug.info("Attached specialization '" .. modName .. ".adjustableMirrors" .. "' to vehicleType '" .. tostring(typeName) .. "'")
						g_vehicleTypeManager:addSpecialization(typeName, modName .. ".adjustableMirrors")
				end
			end
		end
	end
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, initSpecialization)