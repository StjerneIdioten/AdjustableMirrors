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
AdjustableMirrors.dir = g_currentModDirectory; -- Maybe rename to modDirectory

--#######################################################################################
--### Check if certain things are present before going further with the mod, 
--### runs when entering the savegame.
--#######################################################################################
function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

--#######################################################################################
--### New in FS19. Used to register all of the event listeners. In FS17 you just had to 
--### have the functions present. But now you need to register the ones you need aswell
--### And it looks like this function is run upon each vehicletype getting loaded.
--#######################################################################################
function AdjustableMirrors.registerEventListeners(vehicleType)
	FS_Debug.info("registerEventListeners")
	for _,n in pairs( { "onLoad", "onPostLoad", "saveToXMLFile", "onUpdate", "onUpdateTick", "onReadStream", "onWriteStream", "onRegisterActionEvents", "onEnterVehicle"} ) do
		SpecializationUtil.registerEventListener(vehicleType, n, AdjustableMirrors)
	end
end

--#######################################################################################
--### Runs when a vehicle with the specialization is loaded
--#######################################################################################
function AdjustableMirrors:onLoad(savegame)
	FS_Debug.info("onLoad" .. FS_Debug.getIdentity(self))

	--DebugUtil.printTableRecursively(self.spec_enterable.cameras, " - ", 0, 1)

	self.mirror_is_adjustable = false
	self.mirror_has_been_adjusted = false
	self.mirror_adjusting = false
	self.max_rotation = math.rad(20)

	self.mirrors_adjusted = {}
	local idx = 1
	local function addMirror(mirror)
		FS_Debug.info("Adding adjustable mirror #" .. idx .. FS_Debug.getIdentity(self))
		self.mirrors_adjusted[idx] = {}
		self.mirrors_adjusted[idx].node = mirror
		self.mirrors_adjusted[idx].rotation_org = {getRotation(self.mirrors_adjusted[idx].node)}
		self.mirrors_adjusted[idx].translation_org = {getTranslation(self.mirrors_adjusted[idx].node)}
		self.mirrors_adjusted[idx].base = createTransformGroup("Base")
		self.mirrors_adjusted[idx].x0 = 0
		self.mirrors_adjusted[idx].y0 = 0
		self.mirrors_adjusted[idx].x1 = createTransformGroup("x1")
		self.mirrors_adjusted[idx].x2 = createTransformGroup("x2")
		self.mirrors_adjusted[idx].y1 = createTransformGroup("y1")
		self.mirrors_adjusted[idx].y2 = createTransformGroup("y2")
		link(getParent(self.mirrors_adjusted[idx].node), self.mirrors_adjusted[idx].base)
		link(self.mirrors_adjusted[idx].base, self.mirrors_adjusted[idx].x1)
		link(self.mirrors_adjusted[idx].x1, self.mirrors_adjusted[idx].x2)
		link(self.mirrors_adjusted[idx].x2, self.mirrors_adjusted[idx].y1)
		link(self.mirrors_adjusted[idx].y1, self.mirrors_adjusted[idx].y2)
		link(self.mirrors_adjusted[idx].y2, self.mirrors_adjusted[idx].node)
		setTranslation(self.mirrors_adjusted[idx].base,unpack(self.mirrors_adjusted[idx].translation_org))
		setRotation(self.mirrors_adjusted[idx].base,unpack(self.mirrors_adjusted[idx].rotation_org))
		setTranslation(self.mirrors_adjusted[idx].x1,0,0,-0.25)
		setTranslation(self.mirrors_adjusted[idx].x2,0,0,0.5)
		setTranslation(self.mirrors_adjusted[idx].y1,-0.14,0,0)
		setTranslation(self.mirrors_adjusted[idx].y2,0.28,0,0)
		setTranslation(self.mirrors_adjusted[idx].node,-0.14,0,-0.25)
		setRotation(self.mirrors_adjusted[idx].node,0,0,0)
		DebugUtil.printTableRecursively(self.mirrors_adjusted[idx], " - ", 0, 1)
		idx = idx + 1
	end

	if self.spec_enterable.mirrors and self.spec_enterable.mirrors[1] then
		FS_Debug.info("This vehicle has mirrors" .. FS_Debug.getIdentity(self))
		for i = 1, table.getn(self.spec_enterable.mirrors) do
			local children_count = getNumOfChildren(self.spec_enterable.mirrors[i].node)
			if children_count > 0 then
				for j = children_count, 1, -1 do
					addMirror(getChildAt(self.spec_enterable.mirrors[i].node, j-1))
				end
			else
				addMirror(self.spec_enterable.mirrors[i].node)
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
--### 
--#######################################################################################
function AdjustableMirrors:saveToXMLFile(xmlFile, key)
	FS_Debug.info("saveToXMLFile - F: " .. xmlFile .. ", K: " .. key .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### This runs on each frame of the game. So if your framerate is a 100 fps, then this
--### runs a 100 times per second. The dt argument supplies the the frametime since the
--### last frame. So use this to make your code not be framerate dependent.
--#######################################################################################
function AdjustableMirrors:onUpdate(dt)
	--FS_Debug.info("onUpdate" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self))
end

--#######################################################################################
--### Same as onUpdate, but it only updates with the network ticks. 
--#######################################################################################
function AdjustableMirrors:onUpdateTick(dt)
	--FS_Debug.info("onUpdateTick" .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self))
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
	--DebugUtil.printTableRecursively(self.spec_enterable.mirrors, " - ", 0, 2)
	--DebugUtil.printTableRecursively(self:getActiveCamera(), " - ", 0, 0)
end

--#######################################################################################
--### I think this updates the list of actions currently available? So what is shown in
--### the input area hud. Basically which buttons you can press to trigger stuff
--#######################################################################################
function AdjustableMirrors:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	FS_Debug.info("onRegisterActionEvents " .. tostring(isSelected) .. ", " .. tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. FS_Debug.getIdentity(self))
	
	--Actions are only relevant if the function is run clientside
	if not self.isClient then
		return
	end
end

--#######################################################################################
--### Called when a registered action is takin place. So for example a keyboard input or
--### something like that.
--#######################################################################################
function AdjustableMirrors:onActionCall(actionName, keyStatus, arg4, arg5, arg6)
	FS_Debug.info("onActionCall - " .. actionName .. ", keyStatus: " .. keyStatus .. FS_Debug.getIdentity(self))
	FS_Debug.info("onActionCall arg4 - " .. arg4, 1)
	FS_Debug.info("onActionCall arg5 - " .. arg5, 1)
	FS_Debug.info("onActionCall arg6 - " .. arg6, 1)
	return
end
