local metadata = {
"## Interface:FS19 1.0.0.0",
"## Title: AdjustableMirrors (R)",
"## Notes: Mouse adjustableMirrors (registration)",
"## Author: StjerneIdioten - Original 2015 Version by Marhu",
"## Version: 1.0.0",
"## Date: 19.01.2019",
"## Web: https://github.com/StjerneIdioten"
}

--source(Utils.getFileName("fs_debug.lua", g_currentModDirectory))
source(Utils.getFilename("AdjustableMirrors.lua", g_currentModDirectory))
source(Utils.getFilename("FS_Debug.lua", g_currentModDirectory))

AdjustableMirrors_Register = {};
AdjustableMirrors_Register.modDirectory = g_currentModDirectory;

local modDesc = loadXMLFile("modDesc", g_currentModDirectory .. "modDesc.xml");
AdjustableMirrors_Register.version = getXMLString(modDesc, "modDesc.version");
AdjustableMirrors_Register.author = getXMLString(modDesc, "modDesc.author");
AdjustableMirrors_Register.title = getXMLString(modDesc, "modDesc.title.en");

if g_specializationManager:getSpecializationByName("AdjustableMirrors") == nil then
	if AdjustableMirrors == nil then
		FS_Debug.error("Unable to find specialization 'AdjustableMirrors'");
	else
		FS_Debug.debug("Found specialization 'AdjustableMirrors'");
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
					FS_Debug.info("Attached specialization 'AdjustableMirrors' to vehicleType '" .. tostring(i) .. "'")
					typeDef.specializationsByName["AdjustableMirrors"] = AdjustableMirrors
					table.insert(typeDef.specializationNames, "AdjustableMirrors")
					table.insert(typeDef.specializations, AdjustableMirrors)
				end
			end
		end
	end
end

--#######################################################################################

function AdjustableMirrors_Register:loadMap(name)
	print("Loaded " .. self.title .. " version " .. self.version .. " made by " .. self.author);

	--[[
	local numVehicleTypes = 0;
	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		if SpecializationUtil.hasSpecialization(Steerable, v.specializations)then 
			if not SpecializationUtil.hasSpecialization(adjustableMirror, v.specializations) then
				table.insert(v.specializations, SpecializationUtil.getSpecialization("adjustableMirrors"));
				numVehicleTypes = numVehicleTypes + 1;
			end
		end;
	end;

	--g_i18n.globalI18N.texts["adjustableMirrors_ADJUSTMIRRORS"] = g_i18n:getText("adjustableMirrors_ADJUSTMIRRORS");
	
	--- Log Info ---
	local function autor() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Author: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	local function name() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Title: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	local function version() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Version: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	local function support() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Web: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	print(string.format("Script %s v%s by %s registered in %d vehicleTypes Support on %s",(name()),(version()),(autor()),numVehicleTypes,(support())));
	]]
end;

--#######################################################################################

function AdjustableMirrors_Register:deleteMap()
	print("Unloaded " .. self.title .. " version " .. self.version .. " made by " .. self.author);
end;

--#######################################################################################

function AdjustableMirrors_Register:mouseEvent(posX, posY, isDown, isUp, button)
end;

--#######################################################################################

function AdjustableMirrors_Register:keyEvent(unicode, sym, modifier, isDown)
end;

--#######################################################################################

function AdjustableMirrors_Register:update(dt)
end;

--#######################################################################################

addModEventListener(AdjustableMirrors_Register);