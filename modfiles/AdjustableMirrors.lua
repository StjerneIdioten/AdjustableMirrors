--#######################################################################################
--### Create the table holding all of the info from the mod. Although we do have access  
--### to anything created in the table for the AdjustableMirrors_Register.lua file aswell
--### which is something I suppose the giants engine is doing for us. So if I at any 
--### point use something without importing/initializing it first. Chances are that has 
--### already happened in the register file. An example is the FS_Debug library.
--### And remember that anything in this file is run on a per instance basis. So fx.
--### onLoad will run for as many times as there are vehicles with the specialization.
--#######################################################################################
AdjustableMirrors = {};
--AdjustableMirrors.sendNumBits = 7; --Used for multiplayer sync stuff
--AdjustableMirrors.dir = g_currentModDirectory; -- Maybe rename to modDirectory

--#######################################################################################
--### Check if certain things are present before going further with the mod, 
--### runs when entering the savegame.
--### This mod handles the checks in AdjustableMirrors_Register.lua so there are no spec
--### checks here
--#######################################################################################
function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

--#######################################################################################
--### Can be used to expose a function directly into the self object. So fx. making it so
--### you could call a function directly by writing self:function(arg1, arg2) instead of 
--### specialization.function(self, arg1, arg2) I don't know why you would do that though
--### since this might actually clutter stuff instead of keeping things neat instead of
--### the self.spec_specializationName table
--#######################################################################################
function AdjustableMirrors.registerFunctions(vehicleType)
	FS_Debug.info("registerFunctions")
	--SpecializationUtil.registerFunction(vehicleType, "updateAdjustmentEvents", AdjustableMirrors.updateAdjustmentEvents)
end

--#######################################################################################
--### New in FS19. Used to register all of the event listeners. In FS17 you just had to 
--### have the functions present. But now you need to register the ones you need aswell
--### And it looks like this function is run upon each vehicletype getting loaded.
--#######################################################################################
function AdjustableMirrors.registerEventListeners(vehicleType)
	FS_Debug.info("registerEventListeners")
	for _,n in pairs( { "onLoad", "onPostLoad", "saveToXMLFile", "onUpdate", "onUpdateTick", "onReadStream", "onWriteStream", "onRegisterActionEvents", "onEnterVehicle", "onLeaveVehicle", "onCameraChanged"} ) do
		SpecializationUtil.registerEventListener(vehicleType, n, AdjustableMirrors)
	end
end

--#######################################################################################
--### Runs when a vehicle with the specialization is loaded
--#######################################################################################
function AdjustableMirrors:onLoad(savegame)
	FS_Debug.info("onLoad" .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors

	spec.mirror_is_adjustable = false
	spec.mirror_has_been_adjusted = false
	spec.mirror_adjusting = false
	spec.max_rotation = math.rad(20)
	spec.event_IDs = {}

	spec.mirrors_adjusted = {}
	local idx = 1
	local function addMirror(mirror)
		FS_Debug.info("Adding adjustable mirror #" .. idx .. FS_Debug.getIdentity(self))
		spec.mirrors_adjusted[idx] = {}
		spec.mirrors_adjusted[idx].node = mirror
		spec.mirrors_adjusted[idx].rotation_org = {getRotation(spec.mirrors_adjusted[idx].node)}
		spec.mirrors_adjusted[idx].translation_org = {getTranslation(spec.mirrors_adjusted[idx].node)}
		spec.mirrors_adjusted[idx].base = createTransformGroup("Base")
		spec.mirrors_adjusted[idx].x0 = 0
		spec.mirrors_adjusted[idx].y0 = 0
		spec.mirrors_adjusted[idx].x1 = createTransformGroup("x1")
		spec.mirrors_adjusted[idx].x2 = createTransformGroup("x2")
		spec.mirrors_adjusted[idx].y1 = createTransformGroup("y1")
		spec.mirrors_adjusted[idx].y2 = createTransformGroup("y2")
		link(getParent(spec.mirrors_adjusted[idx].node), spec.mirrors_adjusted[idx].base)
		link(spec.mirrors_adjusted[idx].base, spec.mirrors_adjusted[idx].x1)
		link(spec.mirrors_adjusted[idx].x1, spec.mirrors_adjusted[idx].x2)
		link(spec.mirrors_adjusted[idx].x2, spec.mirrors_adjusted[idx].y1)
		link(spec.mirrors_adjusted[idx].y1, spec.mirrors_adjusted[idx].y2)
		link(spec.mirrors_adjusted[idx].y2, spec.mirrors_adjusted[idx].node)
		setTranslation(spec.mirrors_adjusted[idx].base,unpack(spec.mirrors_adjusted[idx].translation_org))
		setRotation(spec.mirrors_adjusted[idx].base,unpack(spec.mirrors_adjusted[idx].rotation_org))
		setTranslation(spec.mirrors_adjusted[idx].x1,0,0,-0.25)
		setTranslation(spec.mirrors_adjusted[idx].x2,0,0,0.5)
		setTranslation(spec.mirrors_adjusted[idx].y1,-0.14,0,0)
		setTranslation(spec.mirrors_adjusted[idx].y2,0.28,0,0)
		setTranslation(spec.mirrors_adjusted[idx].node,-0.14,0,-0.25)
		setRotation(spec.mirrors_adjusted[idx].node,0,0,0)
		--DebugUtil.printTableRecursively(spec.mirrors_adjusted[idx], " - ", 0, 1)
		idx = idx + 1
	end

	if self.spec_enterable.mirrors and spec.spec_enterable.mirrors[1] then
		FS_Debug.info("This vehicle has mirrors" .. FS_Debug.getIdentity(self))
		for i = 1, table.getn(spec.spec_enterable.mirrors) do
			local children_count = getNumOfChildren(spec.spec_enterable.mirrors[i].node)
			if children_count > 0 then
				for j = children_count, 1, -1 do
					addMirror(getChildAt(spec.spec_enterable.mirrors[i].node, j-1))
				end
			else
				addMirror(spec.spec_enterable.mirrors[i].node)
			end
		end
	end

end

--#######################################################################################
--### Runs when a vehicle with the specialization has been loaded. Useful if you need to 
--### use some values, that has to be loaded from the savegame first.
--#######################################################################################
function AdjustableMirrors:onPostLoad(savegame)
	FS_Debug.info("onPostload" .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### Called when saving ingame. The xmlfile is the savegame file and the key already
--### contains the specialization name
--#######################################################################################
function AdjustableMirrors:saveToXMLFile(xmlFile, key)
	FS_Debug.info("saveToXMLFile - File: " .. xmlFile .. ", Key: " .. key .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### This runs on each frame of the game. So if your framerate is a 100 fps, then this
--### runs a 100 times per second. The dt argument supplies the the frametime since the
--### last frame. So use this to make your code not be framerate dependent.
--#######################################################################################
function AdjustableMirrors:onUpdate(dt, isActiveForInput, isSelected)
	FS_Debug.info("onUpdate" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self), 3)
end

--#######################################################################################
--### Same as onUpdate, but it only updates with the network ticks. 
--#######################################################################################
function AdjustableMirrors:onUpdateTick(dt)
	FS_Debug.info("onUpdateTick" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self), 3)
end

--#######################################################################################
--### This is where the client receives data, when it joins the server. Use this to
--### get data on the initial join and synch the states between client and server.
--#######################################################################################
function AdjustableMirrors:onReadStream(streamId, connection)
	FS_Debug.info("onReadStream - " .. streamId .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### This is run on the server when a client joins. Use this to supply initial synch
--### data with the client.
--#######################################################################################
function AdjustableMirrors:onWriteStream(streamId, connection)
	FS_Debug.info("onWriteStream - " .. streamId .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### This is run when someone enters the vehicle.
--#######################################################################################
function AdjustableMirrors:onEnterVehicle()
	FS_Debug.info("onEnterVehicle" .. FS_Debug.getIdentity(self))
	--DebugUtil.printTableRecursively(self:getActiveCamera(), " - ", 0, 0)
end

--#######################################################################################
--### This is run when someone leaves the vehicle.
--#######################################################################################
function AdjustableMirrors:onLeaveVehicle()
	FS_Debug.info("onLeaveVehicle" .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### This function is called when the vehicle state is changed. Fx. when switching to
--### the vehicle or switching implements. It is used to register the current actions
--### that are available to be used for the vehicle
--#######################################################################################
function AdjustableMirrors:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	FS_Debug.info("onRegisterActionEvents, selected: " .. tostring(isSelected) .. ", activeVehicle: " .. tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors
	--Actions are only relevant if the function is run clientside
	if not self.isClient then
		return
	end

	if isOnActiveVehicle and self:getIsControlled() then
		-- InputBinding.registerActionEvent(g_inputBinding, actionName, object, functionForTriggerEvent, triggerKeyUp, triggerKeyDown, triggerAlways, isActive)

		-- Register AdjustMirrors action, with the active value to be based on whether or not the camera is inside when we switched
		local _, eventID = g_inputBinding:registerActionEvent(InputAction.AM_AdjustMirrors, self, AdjustableMirrors.onActionAdjustMirrors, false, true, false, self:getActiveCamera().isInside)
		spec.event_IDs[InputAction.AM_AdjustMirrors] = eventID

		--Actions that have to do with moving the mirrors around
		local actions_adjust = { InputAction.AM_TiltUp, InputAction.AM_TiltDown, InputAction.AM_TiltLeft, InputAction.AM_TiltRight }

		--Register the adjustment actions
		spec.event_IDs.adjustment = {}
		for _,actionName in pairs(actions_adjust) do
			local _, eventID = g_inputBinding:registerActionEvent(actionName, self, AdjustableMirrors.onActionAdjustmentCall, false, true, true, false)	
			spec.event_IDs.adjustment[actionName] = eventID
		end
		
		--g_inputBinding:setActionEventActive(self.event_IDs[InputAction.AM_AdjustMirrors], true)
		--g_inputBinding:setActionEventTextVisibility(self.event_IDs[InputAction.AM_AdjustMirrors], true)
	end
end

--#######################################################################################
--### Callback for the onCameraChanged event, which is triggered when the active camera
--### is changed. This event is fx. raised by the Enterable specialization in the
--### setActiveCameraIndex function.
--#######################################################################################
function AdjustableMirrors:onCameraChanged(activeCamera, camIndex)
	FS_Debug.info("onCameraChanged - camIndex: " .. camIndex .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors

	local eventID = spec.event_IDs[InputAction.AM_AdjustMirrors]

	if activeCamera.isInside then 
		--Enable the Adjustable Mirror action, to show it when inside the cabin
		g_inputBinding:setActionEventActive(eventID, true)
	else
		--Disable the Adjustable Mirror action, to not show it when outside the cabin view.
		g_inputBinding:setActionEventActive(eventID, false)
	end

	--Disable the adjustment actions, just in case they were enabled when changing camera.
	AdjustableMirrors.updateAdjustmentEvents(self,false);
end

--#######################################################################################
--### Callback for the AdjustMirrors action
--#######################################################################################
function AdjustableMirrors:onActionAdjustMirrors(actionName, keyStatus)
	FS_Debug.info("onActionAdjustMirrors - " .. actionName .. ", keyStatus: " .. keyStatus .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors
	AdjustableMirrors.updateAdjustmentEvents(self);
end

--#######################################################################################
--### Update the event prompts for the adjustment events. If state is nothing, then the
--### function just toggles the state. 
--#######################################################################################
function AdjustableMirrors:updateAdjustmentEvents(state)
	FS_Debug.info("updateAdjustmentEvents - state: " .. tostring(Utils.getNoNil(state, "Nil")))
	local spec = self.spec_AdjustableMirrors
	spec.mirror_adjusting = Utils.getNoNil(state, not spec.mirror_adjusting)

	if (spec.event_IDs ~= nil) and (spec.event_IDs.adjustment ~= nil) then
		for _, eventID in pairs(spec.event_IDs.adjustment) do
			g_inputBinding:setActionEventActive(eventID, spec.mirror_adjusting )
			g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_VERY_HIGH)
		end
	end
end

--#######################################################################################
--### Called when one of the adjustment actions take place
--#######################################################################################
function AdjustableMirrors:onActionAdjustmentCall(actionName, keyStatus, arg4, arg5, arg6)
	FS_Debug.info("onActionAdjustmentCall - " .. actionName .. ", keyStatus: " .. keyStatus .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors
	--FS_Debug.info("onActionCall arg4 - " .. arg4, 1)
	--FS_Debug.info("onActionCall arg5 - " .. arg5, 1)
	--FS_Debug.info("onActionCall arg6 - " .. arg6, 1)
	return
end
