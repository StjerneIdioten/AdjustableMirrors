--
-- AdjustableMirrors
--
-- Author: StjerneIdioten
-- Description: Allows people to adjust the vehicle mirrors
--
-- Name: adjustableMirrors
--
-- Copyright (c) StjerneIdioten, 2021

---@type string directory of the mod
local modDirectory = g_currentModDirectory or ""
---@type string name of the mod
local modName = g_currentModName or "unknown"

source(Utils.getFilename("AdjustableMirrors.lua", modDirectory))
source(Utils.getFilename("AdjustMirrorsEvent.lua", modDirectory))
source(Utils.getFilename("AMDebug.lua", modDirectory))

g_adjustableMirrors = {}

--Fetch some variables from the moddesc file, to be used when writing out load statements
local modDesc = loadXMLFile("modDesc", modDirectory .. "modDesc.xml")
g_adjustableMirrors.version = getXMLString(modDesc, "modDesc.version")
AdjustableMirrors.version = g_adjustableMirrors.version
AdjustableMirrors.modName = modName
g_adjustableMirrors.author = getXMLString(modDesc, "modDesc.author")
g_adjustableMirrors.title = getXMLString(modDesc, "modDesc.title.en")

g_AMDebug.mod_name = g_adjustableMirrors.title
g_AMDebug.log_level_max = 3

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