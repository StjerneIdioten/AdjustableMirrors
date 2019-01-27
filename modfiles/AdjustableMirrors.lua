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
--Modwide version, should be set in AdjustableMirrors_Register.lua
AdjustableMirrors.version = "Unspecified Version"

--#######################################################################################
--### Check if certain things are present before going further with the mod, 
--### runs when entering the savegame.
--### This mod handles the checks in AdjustableMirrors_Register.lua so there are no 
--### specialization checks here
--#######################################################################################
function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

--#######################################################################################
--### Can be used to expose a function directly into the self object. So fx. making it so
--### you could call a function directly by writing self:function(arg1, arg2) instead of 
--### specialization.function(self, arg1, arg2) I don't know why you would do that though
--### since this might actually clutter stuff instead of keeping things neat inside of
--### the self.spec_specializationName table
--#######################################################################################
function AdjustableMirrors.registerFunctions(vehicleType)
	FS_Debug.info("registerFunctions")
end

--#######################################################################################
--### New in FS19. Used to register all of the event listeners. In FS17 you just had to 
--### have the functions present. But now you need to register the ones you need aswell
--### And it looks like this function is run upon each vehicletype getting loaded.
--#######################################################################################
function AdjustableMirrors.registerEventListeners(vehicleType)
	FS_Debug.info("registerEventListeners")
	--Table holding all the events, makes it a bit easier to read the code
	local events = { "onLoad", 
					  "onPostLoad", 
					  "saveToXMLFile", 
					  "onUpdate", 
					  "onUpdateTick", 
					  "onDraw", 
					  "onReadStream", 
					  "onWriteStream", 
					  "onRegisterActionEvents", 
					  "onEnterVehicle", 
					  "onLeaveVehicle", 
					  "onCameraChanged"}
	--Register the events we want our spec to react to. Make sure that you have functions with the same name
	--defined as the this list
	for _,event in pairs(events) do
		SpecializationUtil.registerEventListener(vehicleType, event, AdjustableMirrors)
	end
end

--#######################################################################################
--### Runs when a vehicle with the specialization is loaded. Usefull if you want to
--### fx. expose something that other mods should be able to use in their own onPostLoad
--#######################################################################################
function AdjustableMirrors:onLoad(savegame)
	FS_Debug.info("onload" .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### Runs when a vehicle with the specialization has been loaded. Useful if you need to 
--### use some values, that has to be loaded from the savegame first.
--#######################################################################################
function AdjustableMirrors:onPostLoad(savegame)
	FS_Debug.info("onPostLoad" .. FS_Debug.getIdentity(self))
	--Quick reference to the specialization, where we should keep all of our variables
	local spec = self.spec_AdjustableMirrors
	--Are we allowed to adjust the mirrors
	spec.mirror_adjustment_enabled = false
	--Maximum rotation value, for capping the rotation of the mirrors
	spec.max_rotation = math.rad(20)
	--How much we should add to the rotation each time a keypress is detected
	spec.mirror_adjustment_step_size = 0.001
	--Table for holding all of the ID's returned when registering the action events in onRegisterActionEvents
	spec.event_IDs = {}
	--Table for holding all of the new adjustment mirrors
	spec.mirrors = {}

	--#######################################################################################
	--### Used for adding new adjustable mirrors. They require some more transform groups to
	--### be able to be rotated. This ned structure allows for tilt and pan of the mirror
	--### without it going through the mirror arm structure of the model.
	--#######################################################################################
	local idx = 1
	local function addMirror(mirror)
		FS_Debug.info("Adding adjustable mirror #" .. idx .. FS_Debug.getIdentity(self))
		spec.mirrors[idx] = {}
		spec.mirrors[idx].node = mirror
		spec.mirrors[idx].rotation_org = {getRotation(spec.mirrors[idx].node)}
		spec.mirrors[idx].translation_org = {getTranslation(spec.mirrors[idx].node)}
		spec.mirrors[idx].base = createTransformGroup("Base")
		spec.mirrors[idx].x0 = 0
		spec.mirrors[idx].y0 = 0
		spec.mirrors[idx].x1 = createTransformGroup("x1")
		spec.mirrors[idx].x2 = createTransformGroup("x2")
		spec.mirrors[idx].y1 = createTransformGroup("y1")
		spec.mirrors[idx].y2 = createTransformGroup("y2")
		link(getParent(spec.mirrors[idx].node), spec.mirrors[idx].base)
		link(spec.mirrors[idx].base, spec.mirrors[idx].x1)
		link(spec.mirrors[idx].x1, spec.mirrors[idx].x2)
		link(spec.mirrors[idx].x2, spec.mirrors[idx].y1)
		link(spec.mirrors[idx].y1, spec.mirrors[idx].y2)
		link(spec.mirrors[idx].y2, spec.mirrors[idx].node)
		setTranslation(spec.mirrors[idx].base,unpack(spec.mirrors[idx].translation_org))
		setRotation(spec.mirrors[idx].base,unpack(spec.mirrors[idx].rotation_org))
		setTranslation(spec.mirrors[idx].x1,0,0,-0.25)
		setTranslation(spec.mirrors[idx].x2,0,0,0.5)
		setTranslation(spec.mirrors[idx].y1,-0.14,0,0)
		setTranslation(spec.mirrors[idx].y2,0.28,0,0)
		setTranslation(spec.mirrors[idx].node,-0.14,0,-0.25)
		setRotation(spec.mirrors[idx].node,0,0,0)
		idx = idx + 1
	end

	--If the mirror actually has mirrors, since the specialization checks don't account for this
	if self.spec_enterable.mirrors and spec.spec_enterable.mirrors[1] then
		spec.mirror_index = 1
		FS_Debug.info("This vehicle has mirrors" .. FS_Debug.getIdentity(self))
		for i = 1, table.getn(spec.spec_enterable.mirrors) do
			addMirror(spec.spec_enterable.mirrors[i].node)
		end
	end

	--If there was a savegame file to load things from
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".AdjustableMirrors"
		--Load in the modversion saved in the savegame file
		local savegameVersion = getXMLString(xmlFile, key .. "#version")
		if savegameVersion == nil then
			FS_Debug.info("No savegame data present, defaults are used for mirrors" .. FS_Debug.getIdentity(self))
		elseif savegameVersion ~= AdjustableMirrors.version then
			FS_Debug.warning("Savegame data is from mod version " .. savegameVersion .. " while the current mod is version " .. AdjustableMirrors.version .. " therefore mirrors are reset to defaults" .. FS_Debug.getIdentity(self))
		else
			FS_Debug.info("Loading savegame mirror settings" .. FS_Debug.getIdentity(self))
			for idx, mirror in ipairs(spec.mirrors) do
				local x0 = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".mirror" .. idx .. "#x0"), 0) --Just in case someone has tampered with the savegame file
				local y0 = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".mirror" .. idx .. "#y0"), 0) --Just in case someone has tampered with the savegame file
				FS_Debug.debug("x0: " .. x0 .. ", y0: " .. y0 .. FS_Debug.getIdentity(self))
				AdjustableMirrors.setMirrors(self, mirror, x0, y0)
			end
		end
	end
end

--#######################################################################################
--### Called when saving ingame. The xmlfile is the savegame file and the key already
--### contains the specialization name. DO NOT try to nest more than one tag! So
--### basically you are only allowed to have one '.' in the key you save your data
--### under. If you try to further group your stuff by making subgroups, then you will
--### get weird errors on load of the savegame files. Which to me points to that the xml
--### loading functions can only handle 5 nested xml tags. Since the saving works fine if 
--### you try to do more and it will show up properly in the vehichles.xml file.
--#######################################################################################
function AdjustableMirrors:saveToXMLFile(xmlFile, key)
	FS_Debug.info("saveToXMLFile - File: " .. xmlFile .. ", Key: " .. key .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors
	setXMLString(xmlFile, key .. "#version", AdjustableMirrors.version)

	for idx, mirror in ipairs(spec.mirrors) do
		setXMLFloat(xmlFile, key .. ".mirror" .. idx .. "#x0", mirror.x0)
		setXMLFloat(xmlFile, key .. ".mirror" .. idx .. "#y0", mirror.y0)
	end

end

--#######################################################################################
--### This runs on each frame of the game. So if your framerate is a 100 fps, then this
--### runs a 100 times per second. The dt argument supplies the the frametime since the
--### last frame. So use this to make your code not be framerate dependent.
--#######################################################################################
function AdjustableMirrors:onUpdate(dt, isActiveForInput, isSelected)
	FS_Debug.debug("onUpdate" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self), 5)
end

--#######################################################################################
--### Same as onUpdate, but it only updates with the network ticks. 
--#######################################################################################
function AdjustableMirrors:onUpdateTick(dt)
	FS_Debug.debug("onUpdateTick" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self), 5)
end

--#######################################################################################
--### Used for updating drawn stuff like GUI elements
--#######################################################################################
function AdjustableMirrors:onDraw()
	FS_Debug.debug("onDraw" .. FS_Debug.getIdentity(self), 5)
	local spec = self.spec_AdjustableMirrors

	if spec.mirror_adjustment_enabled == true then
		--This is a bit of a crude way to do it, since you aren't really supposed to use debug functions for anything else than debug stuff
		--I will change this at some point, but for now it works fine for the purpose of showing the currently selected mirror
		DebugUtil.drawDebugNode(spec.mirrors[spec.mirror_index].node, "This Mirror")
	end
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
--### that are available to be used for the vehicle.
--### isSelected: true if the current implement/vehicle is selected. This value is always
--### false on a tractor, but will be true on fx. a harvester when it is selected instead 
--### of the header.
--### isOnActiveVehicle: Used to determine if the implement is currently attached to
--### the active vehicle.
--#######################################################################################
function AdjustableMirrors:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	FS_Debug.info("onRegisterActionEvents, selected: " .. tostring(isSelected) .. ", activeVehicle: " .. tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors
	--Actions are only relevant if the function is run clientside
	if not self.isClient then
		return
	end
	--Actions should only be registered if we are on and in control of the vehicle
	if isOnActiveVehicle and self:getIsControlled() then
		-- InputBinding.registerActionEvent(g_inputBinding, actionName, object, functionForTriggerEvent, triggerKeyUp, triggerKeyDown, triggerAlways, isActive)

		-- Register AdjustMirrors action, with the active value to be based on whether or not the camera is inside when we switched
		local _, eventID = g_inputBinding:registerActionEvent(InputAction.AM_AdjustMirrors, self, AdjustableMirrors.onActionAdjustMirrors, false, true, false, self:getActiveCamera().isInside)
		spec.event_IDs[InputAction.AM_AdjustMirrors] = eventID
		
		--Actions that have to do with moving the mirrors around
		local actions_adjust = { InputAction.AM_TiltUp, InputAction.AM_TiltDown, InputAction.AM_TiltLeft, InputAction.AM_TiltRight }

		--Keep the adjustment action events grouped, since they will be toggled on/off at the same time
		spec.event_IDs.adjustment = {}

		-- Register SwitchMirror action, this one is only based on a single keypress and not a continues keypress like the rest of the adjustment actions
		local _, eventID = g_inputBinding:registerActionEvent(InputAction.AM_SwitchMirror, self, AdjustableMirrors.onActionSwitchMirror, false, true, false, false)
		spec.event_IDs.adjustment[InputAction.AM_SwitchMirror] = eventID

		-- Register the rest of the adjustment actions
		for _,actionName in pairs(actions_adjust) do
			local _, eventID = g_inputBinding:registerActionEvent(actionName, self, AdjustableMirrors.onActionAdjustmentCall, false, true, true, false)	
			spec.event_IDs.adjustment[actionName] = eventID
		end
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
	--Toggles the adjustment actions
	AdjustableMirrors.updateAdjustmentEvents(self)
end

--#######################################################################################
--### Callback for the SwitchMirror action
--#######################################################################################
function AdjustableMirrors:onActionSwitchMirror(actionName, keyStatus)
	FS_Debug.info("onActionSwitchMirror - " .. actionName .. ", keyStatus: " .. keyStatus .. FS_Debug.getIdentity(self))
	local spec = self.spec_AdjustableMirrors
	
	--Selected the next mirror or loop around to the first one if the last one was selected
	if spec.mirror_index == #spec.mirrors then
		spec.mirror_index = 1
	else
		spec.mirror_index = spec.mirror_index + 1
	end

	FS_Debug.debug("new value of mirror_index: " .. spec.mirror_index)
end

--#######################################################################################
--### Update the event prompts for the adjustment events. If state is nothing, then the
--### function just toggles the state. 
--#######################################################################################
function AdjustableMirrors:updateAdjustmentEvents(state)
	FS_Debug.info("updateAdjustmentEvents - state: " .. tostring(Utils.getNoNil(state, "Nil")))
	local spec = self.spec_AdjustableMirrors
	--If 'state' was supplied then use that, and if not then act as a toggle
	spec.mirror_adjustment_enabled = Utils.getNoNil(state, not spec.mirror_adjustment_enabled)

	if (spec.event_IDs ~= nil) and (spec.event_IDs.adjustment ~= nil) then
		for _, eventID in pairs(spec.event_IDs.adjustment) do
			g_inputBinding:setActionEventActive(eventID, spec.mirror_adjustment_enabled )
			g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_VERY_HIGH)
		end
	end
end

--#######################################################################################
--### Called when one of the adjustment actions take place
--#######################################################################################
function AdjustableMirrors:onActionAdjustmentCall(actionName, keyStatus, arg4, arg5, arg6)
	FS_Debug.info("onActionAdjustmentCall - " .. actionName .. ", keyStatus: " .. keyStatus .. FS_Debug.getIdentity(self), 4)
	local spec = self.spec_AdjustableMirrors

	--Get a reference to the currently selected mirror
	local mirror = spec.mirrors[spec.mirror_index]

	--Adjust the mirror depending on which of the adjustment events was called
	if actionName == "AM_TiltUp" then
		AdjustableMirrors.setMirrors(self, mirror, mirror.x0 - spec.mirror_adjustment_step_size, mirror.y0)
	elseif actionName == "AM_TiltDown" then
		AdjustableMirrors.setMirrors(self, mirror, mirror.x0 + spec.mirror_adjustment_step_size, mirror.y0)
	elseif actionName == "AM_TiltLeft" then
		AdjustableMirrors.setMirrors(self, mirror, mirror.x0, mirror.y0 - spec.mirror_adjustment_step_size)
	elseif actionName == "AM_TiltRight" then
		AdjustableMirrors.setMirrors(self, mirror, mirror.x0, mirror.y0 + spec.mirror_adjustment_step_size)
	end
end

--#######################################################################################
--### Used to update the mirror from new values of x0 and y0
--#######################################################################################
function AdjustableMirrors:setMirrors(mirror, new_x0, new_y0)
	FS_Debug.debug("setMirrors" .. FS_Debug.getIdentity(self), 4)
	local spec = self.spec_AdjustableMirrors

	--Clamps the rotation of the mirrors between -max_rotation and rotation
	mirror.x0 = math.min(spec.max_rotation,math.max(-spec.max_rotation, new_x0))
	mirror.y0 = math.min(spec.max_rotation,math.max(-spec.max_rotation, new_y0))
	--Set the rotations of the individual joints to accomodate the special adjustment pattern.
	--The mirrors hinges at the top or bottom, left or right. Depending on which edge hits the
	--Mirror arm where the mirror is attached
	setRotation(mirror.x1,math.min(0,mirror.x0),0,0);
	setRotation(mirror.x2,math.max(0,mirror.x0),0,0);
	setRotation(mirror.y1,0,0,math.max(0,mirror.y0));
	setRotation(mirror.y2,0,0,math.min(0,mirror.y0));
end
