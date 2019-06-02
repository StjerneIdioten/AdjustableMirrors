local myName = "AdjustableMirrors_Event"

AdjustableMirrors_Event = {}
AdjustableMirrors_Event_mt = Class(AdjustableMirrors_Event, Event)
InitEventClass(AdjustableMirrors_Event, "AdjustableMirrors_Event")

function AdjustableMirrors_Event:emptyNew()
    FS_Debug.info(myName .. ": emptyNew()")
    local self = Event:new(AdjustableMirrors_Event_mt)
    self.className = "AdjustableMirrors_Event"
    return self
end

function AdjustableMirrors_Event:new(vehicle, ...)
    FS_Debug.info(myName .. ": new()")
    local args = { ... }
    local self = AdjustableMirrors_Event:emptyNew()
    self.vehicle = vehicle
    self.vehicle.data = { unpack(args) }
    FS_Debug.info(myName .. ": elements in data: " .. #self.vehicle.data)
    return self
end

function AdjustableMirrors_Event:readStream(streamID, connection)
    FS_Debug.info(myName .. ": readStream() - " .. streamID)
    self.vehicle = NetworkUtil.readNodeObject(streamID)
    local numbOfMirrors = streamReadInt8(streamID)

    local spec = self.vehicle.spec_AdjustableMirrors
    DebugUtil.printTableRecursively(spec, '-', 0, 2)

    FS_Debug.info(myName .. ": number of mirrors: " .. numbOfMirrors)
    FS_Debug.info(myName .. ": Spec mirror count: " .. #spec.mirrors)

    for i=1,numbOfMirrors do
        spec.mirrors[i] = {}
        spec.mirrors[i].x0 = streamReadFloat32(streamID)
        spec.mirrors[i].y0 = streamReadFloat32(streamID)
        FS_Debug.info(myName .. ": Mirror" .. i .. " x0:" .. spec.mirrors[i].x0 .. " y0:" .. spec.mirrors[i].y0)
    end

    if not connection:getIsServer() then
        FS_Debug.info(myName .. ": broadcasting event")
        --generate array
        local data = {}
        data[1] = numbOfMirrors
        for i=1,data[1] do
            data[i*2] = spec.mirrors[i].x0
            data[i*2+1] = spec.mirrors[i].y0
            FS_Debug.info(myName .. ": Mirror" .. i)
            FS_Debug.info(myName .. ": x0:" .. data[i*2])
            FS_Debug.info(myName .. ": y0:" .. data[i*2+1])
        end
        g_server:broadcastEvent(AdjustableMirrors_Event:new(self.vehicle, unpack(data)), nil, connection)
    end

    if g_server == nil then
        FS_Debug.info(myName .. ": This should be on receiving clients")
        for i=1, #spec.mirrors do
            FS_Debug.info(myName .. ": Mirror" .. i .. " x0:" .. spec.mirror[i].x0 .. " y0:" .. spec.mirror[i].y0)
            AdjustableMirrors.setMirrors(self.vehicle, spec.mirror[i], spec.mirror[i].x0, spec.mirror[i].y0)
        end
    end
end

function AdjustableMirrors_Event:writeStream(streamID, connection)
    FS_Debug.info(myName .. ": writeStream() - " .. streamID)
    NetworkUtil.writeNodeObject(streamID, self.vehicle)
    streamWriteInt8(streamID, self.vehicle.data[1])

    --FS_Debug.info(myName .. ": elements in data: " .. #self.vehicle.data)
    --FS_Debug.info(myName .. ": elements 1: " .. self.vehicle.data[1])

    for i=2,self.vehicle.data[1]*2+1 do
        streamWriteFloat32(streamID, self.vehicle.data[i])
        FS_Debug.info(myName .. ": Written data: " .. self.vehicle.data[i])
    end
end

function AdjustableMirrors_Event:sendEvent(vehicle)
    FS_Debug.info(myName .. ": sendEvent()")

    local spec = vehicle.spec_AdjustableMirrors

    --generate array
    local data = {}
    data[1] = #spec.mirrors
    for i=1,data[1] do
         data[i*2] = spec.mirrors[i].x0
         data[i*2+1] = spec.mirrors[i].y0
         FS_Debug.info(myName .. ": Mirror" .. i .. " x0:" .. data[i*2] .. " y0:" .. data[i*2+1])
    end

    if g_server ~= nil then
        --If it is actually the server sending out the event, in case of an non-dedicated server host
        FS_Debug.info(myName .. ": g_server:broadcastEvent()")
        g_server:broadcastEvent(AdjustableMirrors_Event:new(vehicle, unpack(data)), nil, nil, vehicle)
    else
        --If it is a client sending the event
        FS_Debug.info(myName .. ": g_client:getServerConnection():sendEvent()")
        g_client:getServerConnection():sendEvent(AdjustableMirrors_Event:new(vehicle, unpack(data)))
    end
end
