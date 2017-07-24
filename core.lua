local metadata = {
"## Interface:FS17 1.0.0.0",
"## Title: AdjustableMirrors (C)",
"## Notes: Mouse adjustable Mirrors (Core)",
"## Author: Marhu - Converted to FS17 by StjerneIdioten",
"## Version: 1.1.5",
"## Date: 24.07.2017",
"## Web: http://marhu.net - https://github.com/StjerneIdioten"
}
 
AdjustableMirrors = {};
AdjustableMirrors.dir = g_currentModDirectory;

function AdjustableMirrors.prerequisitesPresent(specializations)
    return true
end;

function AdjustableMirrors:load(xmlFile)

	for i, camera in ipairs(self.cameras) do
		if camera.isInside then
			camera.Mirror_org_mouseEvent = camera.mouseEvent;
			camera.mouseEvent = function(cam, posX, posY, isDown, isUp, button)
				if not cam.MirrorAdjust then
					camera.Mirror_org_mouseEvent(cam, posX, posY, isDown, isUp, button)
				end
			end
		end;
    end;

	self.MirrorAdjustable = false
	self.MirrorAdjust = false;
	self.maxRot = math.rad(20);
	
	self.adjustMirror = {}
	local num = 1
	local function addMirror(mirror)
		self.adjustMirror[num] = {}
		self.adjustMirror[num].node = mirror;
		self.adjustMirror[num].OrgRot = {getRotation(self.adjustMirror[num].node)}
		self.adjustMirror[num].OrgTrans = {getTranslation(self.adjustMirror[num].node)}
		self.adjustMirror[num].base = createTransformGroup("Base")
		self.adjustMirror[num].x0 = 0
		self.adjustMirror[num].y0 = 0
		self.adjustMirror[num].x1 = createTransformGroup("x1")
		self.adjustMirror[num].x2 = createTransformGroup("x2")
		self.adjustMirror[num].y1 = createTransformGroup("y1")
		self.adjustMirror[num].y2 = createTransformGroup("y2")
		link(getParent(self.adjustMirror[num].node),self.adjustMirror[num].base)
		link(self.adjustMirror[num].base, self.adjustMirror[num].x1)
		link(self.adjustMirror[num].x1, self.adjustMirror[num].x2)
		link(self.adjustMirror[num].x2, self.adjustMirror[num].y1)
		link(self.adjustMirror[num].y1, self.adjustMirror[num].y2)
		link(self.adjustMirror[num].y2, self.adjustMirror[num].node)
		setTranslation(self.adjustMirror[num].base,unpack(self.adjustMirror[num].OrgTrans))
		setRotation(self.adjustMirror[num].base,unpack(self.adjustMirror[num].OrgRot))
		setTranslation(self.adjustMirror[num].x1,0,0,-0.25)
		setTranslation(self.adjustMirror[num].x2,0,0,0.5)
		setTranslation(self.adjustMirror[num].y1,-0.14,0,0)
		setTranslation(self.adjustMirror[num].y2,0.28,0,0)
		setTranslation(self.adjustMirror[num].node,-0.14,0,-0.25)
		setRotation(self.adjustMirror[num].node,0,0,0)
		num = num + 1
	end
	
	if self.mirrors and self.mirrors[1] then
		for i = 1, table.getn(self.mirrors) do

			print("Checking: ")
			--print(string.format("\t%s",(self.mirrors[i].node)))
		
			local numChildren = getNumOfChildren(self.mirrors[i].node);
			if numChildren > 0 then
				for j=numChildren,1,-1 do
					addMirror(getChildAt(self.mirrors[i].node, j-1));
				end
			else
				addMirror(self.mirrors[i].node);
			end;

		end;
	end;

end;

function AdjustableMirrors:delete()
	
end;

function AdjustableMirrors:mouseEvent(posX, posY, isDown, isUp, button)
	
	---[[

	if self.MirrorAdjustable == true then
	
		if isDown and button == 1 then
			self.MirrorAdjust = true;
		elseif isUp and button == 1 then
			self.MirrorAdjust = false;
		end;
		
		if isDown and button == 2 then
			if self.mirrors and self.mirrors[1] and not getVisibility(self.mirrors[1]) then
				local g = getfenv(0)
				g.g_rearMirrorsAvailable = true;
				g.g_settingsRearMirrors = true;
				for i=1,table.getn(g_currentMission.vehicles) do
					if g_currentMission.vehicles[i].mirrors and g_currentMission.vehicles[i].mirrors[1] then
						g_currentMission.vehicles[i].mirrorAvailable = true;
					end;
				end;
			end;
		end;
		
		self.cameras[self.camIndex].MirrorAdjust = self.MirrorAdjust;
	
		if self.MirrorAdjust then
			local movex = 0
			local movey = 0
		
			if InputBinding.wrapMousePositionEnabled then
				movex = InputBinding.mouseMovementX
				movey = InputBinding.mouseMovementY
			else
				movex = InputBinding.mouseMovementX
				movey = InputBinding.mouseMovementY
			end;
			local MirrorSelect 
			for i=1,table.getn(self.adjustMirror) do
				local x,y,z = getWorldTranslation(self.adjustMirror[i].base);
				x,y,z = project(x,y,z);
				if x >= 0.4 and x <= 0.6 then
					if y >= 0.4 and y <= 0.6 then
						if z <= 1 then
							MirrorSelect = i	
							break;
						end;
					end;
				end;
			end;
			if MirrorSelect ~= nil then
				self.adjustMirror[MirrorSelect].x0 = math.min(self.maxRot,math.max(-self.maxRot,self.adjustMirror[MirrorSelect].x0 + movey))
				self.adjustMirror[MirrorSelect].y0 = math.min(self.maxRot,math.max(-self.maxRot,self.adjustMirror[MirrorSelect].y0 + movex))
				setRotation(self.adjustMirror[MirrorSelect].x1,math.min(0,self.adjustMirror[MirrorSelect].x0),0,0);
				setRotation(self.adjustMirror[MirrorSelect].x2,math.max(0,self.adjustMirror[MirrorSelect].x0),0,0);
				setRotation(self.adjustMirror[MirrorSelect].y1,0,0,math.max(0,self.adjustMirror[MirrorSelect].y0));
				setRotation(self.adjustMirror[MirrorSelect].y2,0,0,math.min(0,self.adjustMirror[MirrorSelect].y0));
			end
		end
	else
		self.cameras[self.camIndex].MirrorAdjust = false
	end

	--]]

end;

function AdjustableMirrors:keyEvent(unicode, sym, modifier, isDown)
end;

---[[

function AdjustableMirrors:readUpdateStream(streamId, timestamp, connection)
    if not connection:getIsServer() then
		
	end;
end;
 
function AdjustableMirrors:writeUpdateStream(streamId, connection, dirtyMask)
    if connection:getIsServer() then
      
    end;
end;
 
function AdjustableMirrors:getSaveAttributesAndNodes(nodeIdent)

	local attributes = "";
    local nodes = "";
			  
	for i=1,table.getn(self.adjustMirror) do
		if i > 1 then nodes = nodes.."\n"; end;
		nodes = nodes.. nodeIdent..'<mirror'..i..' rotx="'..self.adjustMirror[i].x0..'" roty="'..self.adjustMirror[i].y0..'" />';
	end
		
    return attributes,nodes;

end

function AdjustableMirrors:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)

	

	if not resetVehicles then
		for i=1, table.getn(self.adjustMirror) do
			local mirrorKey = key..".mirror"..i;
			self.adjustMirror[i].x0 = Utils.getNoNil(getXMLFloat(xmlFile, mirrorKey .. "#rotx"), self.adjustMirror[i].x0);
			self.adjustMirror[i].y0 = Utils.getNoNil(getXMLFloat(xmlFile, mirrorKey .. "#roty"), self.adjustMirror[i].y0);
			setRotation(self.adjustMirror[i].x1,math.min(0,self.adjustMirror[i].x0),0,0);
			setRotation(self.adjustMirror[i].x2,math.max(0,self.adjustMirror[i].x0),0,0);
			setRotation(self.adjustMirror[i].y1,0,0,math.max(0,self.adjustMirror[i].y0));
			setRotation(self.adjustMirror[i].y2,0,0,math.min(0,self.adjustMirror[i].y0));
		end;
	end;
		
	return BaseMission.VEHICLE_LOAD_OK;

	

end

--]]

function AdjustableMirrors:update(dt)

	---[[

	if self.isEntered and self.isClient and self:getIsActiveForInput(false) and self.cameras[self.camIndex].isInside then
		if InputBinding.hasEvent(InputBinding.AdjustableMirrors_ADJUSTMIRROR) then
			if self.mirrors and self.mirrors[1] then
				self.MirrorAdjustable = not self.MirrorAdjustable;
				InputBinding.MirrorAdjustable = self.MirrorAdjustable;
			end;
		end;
	elseif self.MirrorAdjustable or self.MirrorAdjust then
		self.MirrorAdjustable = false;
		self.MirrorAdjust = false;
		InputBinding.MirrorAdjustable = false;
	end
	
	--]]

end;

function AdjustableMirrors:updateTick(dt)	

end;

function AdjustableMirrors:draw()

	if self.MirrorAdjustable then
	g_currentMission:addHelpButtonText(g_i18n:getText("adjustableMirrors_ADJUSTMIRRORS"), InputBinding.adjustableMirrors_ADJUSTMIRRORS, nil, GS_PRIO_VERY_HIGH);
	end
end;

---[[

function AdjustableMirrors:onEnter()
	
	self.MirrorAdjustable = false;
	self.MirrorAdjust = false;
	InputBinding.MirrorAdjustable = false;
	for i=1,table.getn(self.cameras) do
		self.cameras[i].MirrorAdjust = nil
	end

end;


function AdjustableMirrors:onLeave()

	self.MirrorAdjustable = false;
	self.MirrorAdjust = false;
	InputBinding.MirrorAdjustable = false;
	for i=1,table.getn(self.cameras) do
		self.cameras[i].MirrorAdjust = nil
	end

end;



local org_InputBinding_isAxisZero = InputBinding.isAxisZero
InputBinding.isAxisZero = function(v)
	if InputBinding.MirrorAdjustable then v = nil end;
	return v == nil or math.abs(v) < 0.0001;
end

--]]

--- Log Info ---
local function autor() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Author: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
local function name() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Title: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
local function version() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Version: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
local function support() for i=1,table.getn(metadata) do local _,n=string.find(metadata[i],"## Web: ");if n then return (string.sub (metadata[i], n+1)); end;end;end;
print(string.format("Script %s v%s by %s loaded! Support on %s",(name()),(version()),(autor()),(support())));