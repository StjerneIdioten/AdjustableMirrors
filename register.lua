local metadata = {
"## Interface:FS17 1.0.0.0",
"## Title: AdjustableMirrors (R)",
"## Notes: Mouse adjustableMirrors (registration)",
"## Author: StjerneIdioten - Original 2015 Version by Marhu",
"## Version: 1.1.5",
"## Date: 21.02.2018",
"## Web: https://github.com/StjerneIdioten"
}

SpecializationUtil.registerSpecialization('adjustableMirrors', 'AdjustableMirrors', g_currentModDirectory .. 'core.lua')

adjustableMirrors_Register = {};

function adjustableMirrors_Register:loadMap(name)
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
	
end;

function adjustableMirrors_Register:ValueChanged()
end;
function adjustableMirrors_Register:deleteMap()
end;
function adjustableMirrors_Register:mouseEvent(posX, posY, isDown, isUp, button)
end;
function adjustableMirrors_Register:keyEvent(unicode, sym, modifier, isDown)
end;
function adjustableMirrors_Register:update(dt)
end;
function adjustableMirrors_Register:draw()
end;

addModEventListener(adjustableMirrors_Register);