--#######################################################################################
--### Get relevant libraries used in the registry face. Anything included here will also
--### be available to the other scripts included. So AdjustableMirrors will have access
--### to FS_Debug. This file is referenced in the moddesc and is the first thing FS runs
--### when it starts loading in the savegame and mods. It is the entrypoint of the mod.
--### And all code in this file only runs, when the mod is loaded. So it only runs once
--### as opposed to the code in AdjustableMirrors.lua, which will be run once for each
--### vehichle the specialization is inserted into.
--#######################################################################################
source(Utils.getFilename("AdjustableMirrors.lua", g_currentModDirectory))
source(Utils.getFilename("FS_Debug.lua", g_currentModDirectory))

AdjustableMirrors_Register = {};
AdjustableMirrors_Register.modDirectory = g_currentModDirectory;

--Fetch some variables from the moddesc file, to be used when writing out load statements
local modDesc = loadXMLFile("modDesc", g_currentModDirectory .. "modDesc.xml")
AdjustableMirrors_Register.version = getXMLString(modDesc, "modDesc.version")
AdjustableMirrors_Register.author = getXMLString(modDesc, "modDesc.author")
AdjustableMirrors_Register.title = getXMLString(modDesc, "modDesc.title.en")
FS_Debug.mod_name = AdjustableMirrors_Register.title
FS_Debug.log_level_max = 1

--#######################################################################################
--### This isn't a seperate function per say, but it is responsible for checking if the
--### AdjustableMirrors class was includeded properly and is accessible. And then it goes
--### through the registered vehicletypes and checks if they meet certain criteria like
--### being drivable, before adding the AdjustableMirrors specialization.
--#######################################################################################
if g_specializationManager:getSpecializationByName("AdjustableMirrors") == nil then
	if AdjustableMirrors == nil then
		FS_Debug.error("Unable to find specialization '" .. "AdjustableMirrors" .. "'");
	else
		for i, typeDef in pairs(g_vehicleTypeManager.vehicleTypes) do
			if typeDef ~= nil and i ~= "locomotive" then
				local isDrivable = false
				local isEnterable = false
				local hasMotor = false
				for name, spec in pairs(typeDef.specializationsByName) do
					if name == "drivable" then
						isDrivable = true
					elseif name == "motorized" then
						hasMotor = true
					elseif name == "enterable" then
						isEnterable = true
					end
				end
				if isDrivable and isEnterable and hasMotor then
					FS_Debug.info("Attached specialization " .. "'" .. "AdjustableMirrors" .. "'" .. "to vehicleType '" .. tostring(i) .. "'")
					typeDef.specializationsByName["AdjustableMirrors"] = AdjustableMirrors
					table.insert(typeDef.specializationNames, "AdjustableMirrors")
					table.insert(typeDef.specializations, AdjustableMirrors)
				end
			end
		end
	end
end

--#######################################################################################
--### If anything special has to happen after the register of the mod, then this function 
--### runs when the map is loading. For example if we wanted to check how many vehicles
--### the specialization was attached to.
--#######################################################################################
function AdjustableMirrors_Register:loadMap(name)
	print("Loaded " .. self.title .. " version " .. self.version .. " made by " .. self.author);
end;

--#######################################################################################
--### Runs when the map is deleted. Which only happens when exiting to the menu. If using 
--### alt+f4 to quit the game or anything similar. Then this will not run.
--#######################################################################################
function AdjustableMirrors_Register:deleteMap()
	print("Unloaded " .. self.title .. " version " .. self.version .. " made by " .. self.author);
end;

--#######################################################################################
--### Adds eventlisteners for any specified events. We don't really have any for the 
--### register script apart from the map load stuff. Which just outputs a little message
--### to the console/log
--#######################################################################################
addModEventListener(AdjustableMirrors_Register);