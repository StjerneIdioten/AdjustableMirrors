--#######################################################################################

AdjustableMirrors = {};
--AdjustableMirrors.sendNumBits = 7; --Used for multiplayer sync stuff
AdjustableMirrors.dir = g_currentModDirectory; -- Maybe rename to modDirectory

--#######################################################################################

function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

--#######################################################################################

function AdjustableMirrors.registerEventListeners(vehicleType)
	FS_Debug.info("Registering Event Listeners")
	for _,n in pairs( { "onLoad", "onPostLoad", "saveToXMLFile", "onUpdate", "onUpdateTick", "onReadStream", "onWriteStream", "onRegisterActionEvents", "onEnterVehicle"} ) do
		SpecializationUtil.registerEventListener(vehicleType, n, AdjustableMirrors)
	end
end

function AdjustableMirrors:onLoad(savegame)
	FS_Debug.info("On load")
end

function AdjustableMirrors:onPostLoad(savegame)
	FS_Debug.info("On post load")
end

function AdjustableMirrors:saveToXMLFile(xmlFile, key)
	FS_Debug.info("Save to xml")
end

function AdjustableMirrors:onUpdate(dt)
	--print("-->Adjustable Mirrors on update ")
end

function AdjustableMirrors:onUpdateTick(dt)
	--print("-->Adjustable Mirrors on update tick ")
end

function AdjustableMirrors:onReadStream(streamId, connection)
	FS_Debug.info("On read stream ")
end

function AdjustableMirrors:onWriteStream(streamId, connection)
	FS_Debug.info("On write stream ")
end

function AdjustableMirrors:onEnterVehicle(streamId, connection)
	FS_Debug.info("On enter vehicle ")
end

function AdjustableMirrors:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	FS_Debug.info("onRegisterActionEvents " .. tostring(isSelected) .. ", " .. tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient))
end