--#######################################################################################
--### This seperate class is used for sending network events between server and clients. 
--### When a client joins the server the onReadStream and onWriteStream functions from
--### then main script is used. But in any other case, when data is supposed to be 
--### synchronized, this class will be used.
--#######################################################################################

--#######################################################################################
--### A little diagram explaining what happens when a client sends an event.
--#######################################################################################
--### Client 1:
--###   sendEvent()
--###   g_client:getServerConnection:sendEvent()
--###   new()
--###   writeStream()
--###                                                       Server:
--###                                                           emptyNew()
--###                                                           readStream()
--###                                                           g_server:broadcastEvent()
--###                                                           new()
--###                                                           writeStream()
--### Client 2:
--###   emptyNew()
--###   readStream()
--#######################################################################################

local myName = "AdjustMirrorsEvent"

AdjustMirrorsEvent = {}
AdjustMirrorsEvent_mt = Class(AdjustMirrorsEvent, Event)
InitEventClass(AdjustMirrorsEvent, "AdjustMirrorsEvent")

--#######################################################################################
--### This creates an empty event class with nothing but the minimum requirements for a 
--### class.
--#######################################################################################
function AdjustMirrorsEvent.emptyNew()
    g_AMDebug.info(myName .. ": emptyNew()")
    local self = Event.new(AdjustMirrorsEvent_mt)
    self.className = "AdjustMirrorsEvent"
    return self
end

--#######################################################################################
--### Creates an event class with supplied arguments and a reference to the vehicle 
--### object so that we can access data from the mod and vehicle in general.
--#######################################################################################
function AdjustMirrorsEvent.new(vehicle, ...)
    g_AMDebug.info(myName .. ": new()")
    -- Get the arguments into an array
    local args = { ... }
    -- Create a new event
    local self = AdjustMirrorsEvent.emptyNew()
    -- Save the reference to the vehicle itself
    self.vehicle = vehicle
    -- Populate a datastructure with the data supplied
    self.vehicle.data = { unpack(args) }
    return self
end

--#######################################################################################
--### This runs when either the server or a client receives the update event
--#######################################################################################
function AdjustMirrorsEvent:readStream(streamID, connection)
    g_AMDebug.info(myName .. ": readStream() - " .. streamID)
    --The first object sent in the update event is the vehicle object itself.
    self.vehicle = NetworkUtil.readNodeObject(streamID)

    --Then comes the number of mirrors
    local numbOfMirrors = streamReadInt8(streamID)

    local spec = self.vehicle.spec_adjustableMirrors
    local mirrorData = {}

    --Read in the new mirror values
    for idx=1,numbOfMirrors do
        mirrorData[idx] = {streamReadFloat32(streamID), streamReadFloat32(streamID)}
        
        --The server is only guaranteed to have the mirror array, and not necessarily any mirrors in it.
        if g_dedicatedServerInfo ~= nil then
            spec.mirrors[idx] = {}
        end
        
    end

    --If the entity we are connected to is not the server, then we are currently running the function on the server
    --and the server should rebroadcast the update to all of the other clients.
    if not connection:getIsServer() then
        g_AMDebug.info(myName .. ": broadcasting event")
        --generate array of mirror data
        --local data = {}
        --data[1] = numbOfMirrors
        --for idx=1,data[1] do
        --    data[idx*2] = mirrorData[idx][1]
        --    data[idx*2+1] = mirrorData[idx][2]
        --end
        --Broadcast the mirror data to all other clients.
        --g_server:broadcastEvent(AdjustMirrorsEvent.new(self.vehicle, unpack(data)), false, connection, self.vehicle)
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    --Update mirrors, setMirror function handles the difference between server and client
    for idx, mirror in ipairs(spec.mirrors) do
        AdjustableMirrors.setMirror(self.vehicle, idx, mirrorData[idx][1], mirrorData[idx][2])
    end

    if g_dedicatedServerInfo == nil then
        g_AMDebug.info(myName .. ": Client received update from server")
    end
end

--#######################################################################################
--### Used by both server and client to write out the data that should be updated.
--### It should happen either after a broadcast event or a client->server send event.
--#######################################################################################
function AdjustMirrorsEvent:writeStream(streamID, connection)
    g_AMDebug.info(myName .. ": writeStream() - " .. streamID)
    --Synch the vehicle
    NetworkUtil.writeNodeObject(streamID, self.vehicle)
    --Send the number of mirrors as the first data value
    streamWriteInt8(streamID, self.vehicle.data[1])
    
    --Send x0 and y0 for each mirror
    for i=2,self.vehicle.data[1]*2+1 do
        streamWriteFloat32(streamID, self.vehicle.data[i])
    end
end

--#######################################################################################
--### This is used in the main class to actually trigger the synchronization event. So 
--### this is the function to be used in the main class, when you want to update the 
--### mirrors serverwide.
--#######################################################################################
function AdjustMirrorsEvent.sendEvent(vehicle)
    g_AMDebug.info(myName .. ": sendEvent()")

    local spec = vehicle.spec_adjustableMirrors

    --generate array of the mirror data
    local data = {}
    data[1] = #spec.mirrors
    for i=1,data[1] do
         data[i*2] = spec.mirrors[i].x0
         data[i*2+1] = spec.mirrors[i].y0
    end

    --If this is the server itself triggering the event (In the case of a non-dedicated server) then
    --we should just broadcast to the clients directly.
    if g_server ~= nil then
        g_AMDebug.info(myName .. ": g_server:broadcastEvent()")
        g_server:broadcastEvent(AdjustMirrorsEvent.new(vehicle, unpack(data)), nil, nil, vehicle)
    else
        --If it is a client sending the event, then it should just be sent to the server and then it
        --makes sure to broadcast it to the rest of the clients.
        g_AMDebug.info(myName .. ": g_client:getServerConnection():sendEvent()")
        g_client:getServerConnection():sendEvent(AdjustMirrorsEvent.new(vehicle, unpack(data)))
    end
end
