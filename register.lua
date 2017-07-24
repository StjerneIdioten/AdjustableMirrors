local metadata = {
"## Interface:FS15 1.1.0.0 RC12",
"## Title: adjustableMirror (R)",
"## Notes: Mouse adjustableMirror (registration)",
"## Author: Marhu",
"## Version: 1.0.2",
"## Date: 11.11.2014",
"## Web: http://marhu.net"
}

adjustableMirror_Register = {};

if SpecializationUtil.specializations['adjustableMirror'] == nil then
    SpecializationUtil.registerSpecialization('adjustableMirror', 'adjustableMirror', g_currentModDirectory .. 'core.lua')
end

function adjustableMirror_Register:loadMap(name)

	print("Adjustable Mirrors will now be added to vehicles")

	local numVehicleTypes = 0;
	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		if SpecializationUtil.hasSpecialization(Steerable, v.specializations)then 
			if not SpecializationUtil.hasSpecialization(adjustableMirror, v.specializations) then
				table.insert(v.specializations, SpecializationUtil.getSpecialization("adjustableMirror"));
				numVehicleTypes = numVehicleTypes + 1;
			end
		end;
	end;

	--[[

	--]]
	g_i18n.globalI18N.texts["adjustableMirror_ADJUSTMIRROR"] = g_i18n:getText("adjustableMirror_ADJUSTMIRROR");
	--- Log Info ---
	local function autor() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Author: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	local function name() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Title: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	local function version() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Version: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	local function support() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Web: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
	print(string.format("Script %s v%s by %s registered in %d vehicleTypes Support on %s",(name()),(version()),(autor()),numVehicleTypes,(support())));
	
end;

function adjustableMirror_Register:ValueChanged()
end;
function adjustableMirror_Register:deleteMap()
end;
function adjustableMirror_Register:mouseEvent(posX, posY, isDown, isUp, button)
end;
function adjustableMirror_Register:keyEvent(unicode, sym, modifier, isDown)
end;
function adjustableMirror_Register:update(dt)
end;
function adjustableMirror_Register:draw()
end;

addModEventListener(adjustableMirror_Register);