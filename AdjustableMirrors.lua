--
-- AdjustableMirrors
--
-- Description: Main class for Adjustable Mirrors
--
-- Copyright (c) StjerneIdioten, 2024

AdjustableMirrors = {}
--Modwide version, should be set in AdjustableMirrors_Register.lua
AdjustableMirrors.version = "Unspecified Version"
AdjustableMirrors.modName = "None"
AdjustableMirrors.TEXT_COLOR = {0.5, 1, 0.5, 1}  -- RGBA


function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end


function AdjustableMirrors.registerFunctions(vehicleType)
	g_AMDebug.info("registerFunctions")
end


function AdjustableMirrors.registerEventListeners(vehicleType)
	g_AMDebug.info("registerEventListeners")
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

	for _,event in pairs(events) do
		SpecializationUtil.registerEventListener(vehicleType, event, AdjustableMirrors)
	end
end


function AdjustableMirrors:onLoad(savegame)
	g_AMDebug.info("onload" .. g_AMDebug.getIdentity(self))
	self.spec_adjustableMirrors = self[("spec_%s.adjustableMirrors"):format(AdjustableMirrors.modName)]
	local spec = self.spec_adjustableMirrors

	spec.has_usable_mirrors = false

	if g_dedicatedServerInfo ~= nil then
		g_AMDebug.info("This vehicle is loaded on a dedicated server and therefor does not have mirrors" .. g_AMDebug.getIdentity(self))
		spec.has_usable_mirrors = false
	elseif g_gameSettings:getValue("maxNumMirrors") < 1 then
		g_AMDebug.info("This vehicle is loaded on a client that does not have mirrors enabled" .. g_AMDebug.getIdentity(self))
		spec.has_usable_mirrors = false
	elseif not self.spec_enterable.mirrors or not self.spec_enterable.mirrors[1] then
		g_AMDebug.info("This vehicle does not have mirrors" .. g_AMDebug.getIdentity(self))
		spec.has_usable_mirrors = false
	else
		g_AMDebug.info("This vehicle has usable mirrors" .. g_AMDebug.getIdentity(self))
		spec.has_usable_mirrors = true
	end
end


function AdjustableMirrors:onPostLoad(savegame)
	g_AMDebug.info("onPostLoad" .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	spec.mirrors = {}
	spec.max_rotation = math.rad(20)
	if g_server ~= nil then
		if g_dedicatedServerInfo ~= nil then
			g_AMDebug.info("Dedi server")
		else
			g_AMDebug.info("Listen server")
		end
	else 
		g_AMDebug.info("This should be a client")
	end

	if spec.has_usable_mirrors then
		g_AMDebug.info("Initialization stuff, when we have mirrors")
		spec.mirror_index = 1
		spec.mirror_adjustment_enabled = false
		spec.mirrors_have_been_adjusted = false
		spec.mirror_adjustment_step_size = 0.001
		spec.event_IDs = {}

		-- Define new mirrors that allows for pan/tilt without clipping the mirror holder
		local idx = 1
		local function addMirror(mirror)
			g_AMDebug.info("Adding adjustable mirror #" .. idx .. g_AMDebug.getIdentity(self))
			spec.mirrors[idx] = {}
			spec.mirrors[idx].mirror_ref = mirror
			spec.mirrors[idx].rotation_org = {getRotation(spec.mirrors[idx].mirror_ref.node)}
			spec.mirrors[idx].translation_org = {getTranslation(spec.mirrors[idx].mirror_ref.node)}
			spec.mirrors[idx].base = createTransformGroup("Base")
			spec.mirrors[idx].x0 = 0
			spec.mirrors[idx].y0 = 0
			spec.mirrors[idx].x1 = createTransformGroup("x1")
			spec.mirrors[idx].x2 = createTransformGroup("x2")
			spec.mirrors[idx].y1 = createTransformGroup("y1")
			spec.mirrors[idx].y2 = createTransformGroup("y2")
			link(getParent(spec.mirrors[idx].mirror_ref.node), spec.mirrors[idx].base)
			link(spec.mirrors[idx].base, spec.mirrors[idx].x1)
			link(spec.mirrors[idx].x1, spec.mirrors[idx].x2)
			link(spec.mirrors[idx].x2, spec.mirrors[idx].y1)
			link(spec.mirrors[idx].y1, spec.mirrors[idx].y2)
			link(spec.mirrors[idx].y2, spec.mirrors[idx].mirror_ref.node)
			setTranslation(spec.mirrors[idx].base,unpack(spec.mirrors[idx].translation_org))
			setRotation(spec.mirrors[idx].base,unpack(spec.mirrors[idx].rotation_org))
			setTranslation(spec.mirrors[idx].x1,0,0,-0.25)
			setTranslation(spec.mirrors[idx].x2,0,0,0.5)
			setTranslation(spec.mirrors[idx].y1,-0.14,0,0)
			setTranslation(spec.mirrors[idx].y2,0.28,0,0)
			setTranslation(spec.mirrors[idx].mirror_ref.node,-0.14,0,-0.25)
			setRotation(spec.mirrors[idx].mirror_ref.node,0,0,0)
			idx = idx + 1
		end
		for i = 1, #spec.spec_enterable.mirrors do
			addMirror(spec.spec_enterable.mirrors[i])
		end
	end

	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		g_AMDebug.debug("Savegame Key: " .. savegame.key)
		g_AMDebug.debug("Mod name: " .. Utils.getNoNil(AdjustableMirrors.modName, "Nil"))
		local key = savegame.key .. "." .. AdjustableMirrors.modName .. '.adjustableMirrors'
		g_AMDebug.debug("Full key: " .. key)
		local savegameVersion = xmlFile:getString(key .. "#version")
		if savegameVersion == nil then
			g_AMDebug.info("No savegame data present, defaults are used for mirrors" .. g_AMDebug.getIdentity(self))
		elseif savegameVersion ~= AdjustableMirrors.version then
			g_AMDebug.warning("Savegame data is from mod version " .. savegameVersion .. " while the current mod is version " .. AdjustableMirrors.version .. " therefore mirrors are reset to defaults" .. g_AMDebug.getIdentity(self))
		else
			g_AMDebug.info("Loading savegame mirror settings" .. g_AMDebug.getIdentity(self))
			local idx = 1
			while true do
				local position = xmlFile:getVector(key .. ".mirror" .. idx .. "#position", nil, 2)
				if position == nil then
					g_AMDebug.info("Found " .. idx - 1 .. " mirrors" .. g_AMDebug.getIdentity(self))
					break
				else
					g_AMDebug.debug("x0: " .. position[1] .. ", y0: " .. position[2] .. g_AMDebug.getIdentity(self))
					
					AdjustableMirrors.setMirror(self, idx, unpack(position))
					idx = idx + 1
				end
			end
		end
	end
end


function AdjustableMirrors:saveToXMLFile(xmlFile, key)
	g_AMDebug.info("saveToXMLFile - File: " .. tostring(xmlFile.filename) .. ", Key: " .. key .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	xmlFile:setString(key .. "#version", AdjustableMirrors.version)

	for idx, mirror in ipairs(spec.mirrors) do
		g_AMDebug.info("saving mirror" .. idx .. ", x0: " .. mirror.x0 .. ", y0: " .. mirror.y0)
		xmlFile:setVector(key .. ".mirror" .. idx .. "#position", {mirror.x0, mirror.y0}, 2)
		g_AMDebug.info("saved mirror")
	end
end


function AdjustableMirrors:onUpdate(dt, isActiveForInput, isSelected)
	g_AMDebug.debug("onUpdate" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. g_AMDebug.getIdentity(self), 5)
end


function AdjustableMirrors:onUpdateTick(dt)
	g_AMDebug.debug("onUpdateTick" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. g_AMDebug.getIdentity(self), 5)
end


function AdjustableMirrors:onDraw()
	g_AMDebug.debug("onDraw" .. g_AMDebug.getIdentity(self), 5)
	local spec = self.spec_adjustableMirrors

	if spec.mirror_adjustment_enabled == true then
		local x, y, z = getWorldTranslation(spec.mirrors[spec.mirror_index].mirror_ref.node)
		Utils.renderTextAtWorldPosition(x, y, z, g_i18n:getText("info_AM_SelectedMirror"), getCorrectTextSize(0.012), 0, self.TEXT_COLOR)
	end
end


function AdjustableMirrors:onReadStream(streamID, connection)
	g_AMDebug.info("onReadStream - " .. streamID .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	local numbOfMirrors = streamReadInt8(streamID) 
	if numbOfMirrors > 0 then
		g_AMDebug.info("Server has mirror data for " .. numbOfMirrors .. " mirrors")
		local mirrorData = {}
		for idx = 1, numbOfMirrors, 1 do
			mirrorData[idx] = {streamReadFloat32(streamID), streamReadFloat32(streamID)}
		end
		for idx, mirror in ipairs(spec.mirrors) do
			AdjustableMirrors.setMirror(self, idx, mirrorData[idx][1], mirrorData[idx][2])
		end
	else
		g_AMDebug.info("No mirror data stored on server for this vehicle")
	end
end


function AdjustableMirrors:onWriteStream(streamID, connection)
	g_AMDebug.info("onWriteStream - " .. streamID .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	g_AMDebug.info("mirrors stored on server: " .. #spec.mirrors)
	streamWriteInt8(streamID, #spec.mirrors)
	for idx, mirror in ipairs(spec.mirrors) do
		g_AMDebug.info("mirror" .. idx .. " x0:" .. mirror.x0 .. " y0:" .. mirror.y0)
		streamWriteFloat32(streamID, mirror.x0)
		streamWriteFloat32(streamID, mirror.y0)
	end
end


function AdjustableMirrors:onEnterVehicle()
	g_AMDebug.info("onEnterVehicle" .. g_AMDebug.getIdentity(self))
end


function AdjustableMirrors:onLeaveVehicle()
	g_AMDebug.info("onLeaveVehicle" .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	if spec.mirrors_have_been_adjusted then
		g_AMDebug.info("Mirrors have changed, sending update event")
		AMAdjustMirrorsEvent.sendEvent(self)
		spec.mirrors_have_been_adjusted = false
	end
end


function AdjustableMirrors:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	g_AMDebug.info("onRegisterActionEvents, selected: " .. tostring(isSelected) .. ", activeVehicle: " .. tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	if spec.has_usable_mirrors then
		if isOnActiveVehicle and self:getIsControlled() then
			local _, eventID = g_inputBinding:registerActionEvent(InputAction.AM_AdjustMirrors, self, AdjustableMirrors.onActionAdjustMirrors, false, true, false, self:getActiveCamera().isInside)
			spec.event_IDs[InputAction.AM_AdjustMirrors] = eventID
			
			local actions_adjust = { InputAction.AM_TiltUp, InputAction.AM_TiltDown, InputAction.AM_TiltLeft, InputAction.AM_TiltRight }
			spec.event_IDs.adjustment = {}

			local _, eventID = g_inputBinding:registerActionEvent(InputAction.AM_SwitchMirror, self, AdjustableMirrors.onActionSwitchMirror, false, true, false, false)
			spec.event_IDs.adjustment[InputAction.AM_SwitchMirror] = eventID

			for _,actionName in pairs(actions_adjust) do
				local _, eventID = g_inputBinding:registerActionEvent(actionName, self, AdjustableMirrors.onActionAdjustmentCall, false, true, true, false)	
				spec.event_IDs.adjustment[actionName] = eventID
			end
		end
	end
end


function AdjustableMirrors:onCameraChanged(activeCamera, camIndex)
	g_AMDebug.info("onCameraChanged - camIndex: " .. camIndex .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	if spec.has_usable_mirrors then
		local eventID = spec.event_IDs[InputAction.AM_AdjustMirrors]
		if activeCamera.isInside  then 
			g_inputBinding:setActionEventActive(eventID, true)
		else
			g_inputBinding:setActionEventActive(eventID, false)
		end
		AdjustableMirrors.updateAdjustmentEvents(self,false)
	end
end


function AdjustableMirrors:onActionAdjustMirrors(actionName, keyStatus)
	g_AMDebug.info("onActionAdjustMirrors - " .. actionName .. ", keyStatus: " .. keyStatus .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	AdjustableMirrors.updateAdjustmentEvents(self)
end


function AdjustableMirrors:onActionSwitchMirror(actionName, keyStatus)
	g_AMDebug.info("onActionSwitchMirror - " .. actionName .. ", keyStatus: " .. keyStatus .. g_AMDebug.getIdentity(self))
	local spec = self.spec_adjustableMirrors
	if spec.mirror_index == #spec.mirrors then
		spec.mirror_index = 1
	else
		spec.mirror_index = spec.mirror_index + 1
	end
	g_AMDebug.info("new value of mirror_index: " .. spec.mirror_index)
end


function AdjustableMirrors:updateAdjustmentEvents(state)
	g_AMDebug.info("updateAdjustmentEvents - state: " .. tostring(Utils.getNoNil(state, "Nil")))
	local spec = self.spec_adjustableMirrors
	spec.mirror_adjustment_enabled = Utils.getNoNil(state, not spec.mirror_adjustment_enabled)
	if (spec.event_IDs ~= nil) and (spec.event_IDs.adjustment ~= nil) then
		for _, eventID in pairs(spec.event_IDs.adjustment) do
			g_inputBinding:setActionEventActive(eventID, spec.mirror_adjustment_enabled )
			g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_VERY_HIGH)
		end
	end
end


function AdjustableMirrors:onActionAdjustmentCall(actionName, keyStatus, arg4, arg5, arg6)
	g_AMDebug.info("onActionAdjustmentCall - " .. actionName .. ", keyStatus: " .. keyStatus .. g_AMDebug.getIdentity(self), 4)
	local spec = self.spec_adjustableMirrors
	spec.mirrors_have_been_adjusted = true
	local mirror = spec.mirrors[spec.mirror_index]

	if actionName == "AM_TiltDown" then
		AdjustableMirrors.setMirror(self, spec.mirror_index, mirror.x0 - spec.mirror_adjustment_step_size, mirror.y0)
	elseif actionName == "AM_TiltUp" then
		AdjustableMirrors.setMirror(self, spec.mirror_index, mirror.x0 + spec.mirror_adjustment_step_size, mirror.y0)
	elseif actionName == "AM_TiltLeft" then
		AdjustableMirrors.setMirror(self, spec.mirror_index, mirror.x0, mirror.y0 - spec.mirror_adjustment_step_size)
	elseif actionName == "AM_TiltRight" then
		AdjustableMirrors.setMirror(self, spec.mirror_index, mirror.x0, mirror.y0 + spec.mirror_adjustment_step_size)
	end
end


function AdjustableMirrors:setMirror(mirror_idx, new_x0, new_y0)
	g_AMDebug.debug("setMirror" .. g_AMDebug.getIdentity(self), 4)
	local spec = self.spec_adjustableMirrors
	if spec.mirrors[mirror_idx] == nil then
		spec.mirrors[mirror_idx] = {}
	end

	local mirror = spec.mirrors[mirror_idx]
	mirror.x0 = math.min(spec.max_rotation,math.max(-spec.max_rotation, new_x0))
	mirror.y0 = math.min(spec.max_rotation,math.max(-spec.max_rotation, new_y0))

	if spec.has_usable_mirrors then
		setRotation(mirror.x1,math.min(0,mirror.x0),0,0)
		setRotation(mirror.x2,math.max(0,mirror.x0),0,0)
		setRotation(mirror.y1,0,0,math.max(0,mirror.y0))
		setRotation(mirror.y2,0,0,math.min(0,mirror.y0))
	end
end
