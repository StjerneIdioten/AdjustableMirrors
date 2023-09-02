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

AMAdjustMirrorsEvent = {}
local myName = "AMAdjustMirrorsEvent"
local AMAdjustMirrorsEvent_mt = Class(AMAdjustMirrorsEvent, Event)

InitEventClass(AMAdjustMirrorsEvent, myName)

--#######################################################################################
--### This creates an empty event class with nothing but the minimum requirements for a 
--### class.
--#######################################################################################
function AMAdjustMirrorsEvent.emptyNew()
    g_AMDebug.info(myName .. ": emptyNew()")
    local self = Event.new(AMAdjustMirrorsEvent_mt)
    return self
end

--#######################################################################################
--### Creates an event class with supplied arguments and a reference to the vehicle 
--### object so that we can access data from the mod and vehicle in general.
--#######################################################################################
function AMAdjustMirrorsEvent.new(vehicle)
    g_AMDebug.info(myName .. ": new()")
    -- Create a new event
    local self = AMAdjustMirrorsEvent.emptyNew()
    -- Save the reference to the vehicle itself
    self.vehicle = vehicle
    return self
end

--#######################################################################################
--### This runs when either the server or a client receives the update event
--#######################################################################################
function AMAdjustMirrorsEvent:readStream(streamID, connection)
    g_AMDebug.info(myName .. ": readStream() - " .. streamID)
    --The first object sent in the update event is the vehicle object id
    self.vehicle = NetworkUtil.readNodeObject(streamID)
    local spec = self.vehicle.spec_adjustableMirrors
   
    --Then comes the number of mirrors (Because the server doesn't have this information)
    local numbOfMirrors = streamReadInt8(streamID)
    g_AMDebug.info(myName .. ": Number of mirrors received is " .. numbOfMirrors)
    if #spec.mirrors ~= numbOfMirrors then
        g_AMDebug.info(myName .. ": Dedicated server does not have mirrors")
        for idx=1,numbOfMirrors do
            g_AMDebug.info(myName .. ": Initialising empty mirror " .. idx)
            spec.mirrors[idx] = {}
        end
    end

    --Read in the new mirror values
    --Update mirrors, setMirror function handles the difference between server and client
    for idx, mirror in ipairs(spec.mirrors) do
        g_AMDebug.info(myName .. "Receiving data for mirror " .. idx)
        AdjustableMirrors.setMirror(self.vehicle, idx, streamReadFloat32(streamID), streamReadFloat32(streamID))
    end

    --If the entity we are connected to is not the server, then we are currently running the function on the server
    --and the server should rebroadcast the update to all of the other clients.
    if not connection:getIsServer() then
        g_AMDebug.info(myName .. ": broadcasting event")
        --Broadcast the mirror data to all other clients.
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end
    if g_dedicatedServer == nil then
        g_AMDebug.info(myName .. ": Client received update from server")
    end

end

--#######################################################################################
--### Used by both server and client to write out the data that should be updated.
--### It should happen either after a broadcast event or a client->server send event.
--#######################################################################################
function AMAdjustMirrorsEvent:writeStream(streamID, connection)
    g_AMDebug.info(myName .. ": writeStream() - " .. streamID)
    local spec = self.vehicle.spec_adjustableMirrors
    --Synch the vehicle
    NetworkUtil.writeNodeObject(streamID, self.vehicle)
    g_AMDebug.info(myName .. ": Number of mirrors sent is " .. #spec.mirrors)
    streamWriteInt8(streamID, #spec.mirrors)
    for idx, mirror in ipairs(spec.mirrors) do
        g_AMDebug.info(myName .. "Sending data for mirror " .. idx .. ": (x0, " .. mirror.x0 .. ", " .. mirror.y0 .. ")")
        streamWriteFloat32(streamID, mirror.x0)
        streamWriteFloat32(streamID, mirror.y0)
    end
end

--#######################################################################################
--### This is used in the main class to actually trigger the synchronization event. So 
--### this is the function to be used in the main class, when you want to update the 
--### mirrors serverwide.
--#######################################################################################
function AMAdjustMirrorsEvent.sendEvent(vehicle)
    g_AMDebug.info(myName .. ": sendEvent()")

    --If this is the server itself triggering the event (In the case of a non-dedicated server) then
    --we should just broadcast to the clients directly.
    if g_server ~= nil then
        g_AMDebug.info(myName .. ": g_server:broadcastEvent()")
        g_server:broadcastEvent(AMAdjustMirrorsEvent.new(vehicle), nil, nil, vehicle)
    else
        --If it is a client sending the event, then it should just be sent to the server and then it
        --makes sure to broadcast it to the rest of the clients.
        g_AMDebug.info(myName .. ": g_client:getServerConnection():sendEvent()")
        g_client:getServerConnection():sendEvent(AMAdjustMirrorsEvent.new(vehicle))
    end
end
