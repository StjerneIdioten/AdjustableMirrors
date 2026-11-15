--
-- AdjustableMirrors
--
-- Description: Event send when mirror updates need to be synched
--
-- Copyright (c) StjerneIdioten, 2024

AMAdjustMirrorsEvent = {}
local myName = "AMAdjustMirrorsEvent"
local AMAdjustMirrorsEvent_mt = Class(AMAdjustMirrorsEvent, Event)
InitEventClass(AMAdjustMirrorsEvent, myName)


function AMAdjustMirrorsEvent.emptyNew()
    g_AMDebug.info(myName .. ": emptyNew()")
    return Event.new(AMAdjustMirrorsEvent_mt)
end


function AMAdjustMirrorsEvent.new(vehicle)
    g_AMDebug.info(myName .. ": new()")
    local self = AMAdjustMirrorsEvent.emptyNew()
    self.vehicle = vehicle
    return self
end


function AMAdjustMirrorsEvent:readStream(streamID, connection)
    g_AMDebug.info(myName .. ": readStream() - " .. streamID)
    self.vehicle = NetworkUtil.readNodeObject(streamID)
    local spec = self.vehicle.spec_adjustableMirrors
    local numbOfMirrors = streamReadInt8(streamID) -- Sends number of mirrors, since dedicated servers don't have that information
    g_AMDebug.info(myName .. ": Number of mirrors received is " .. numbOfMirrors .. ", local has " .. #spec.mirrors .. " mirrors" .. g_AMDebug.getIdentity(self.vehicle))

    -- If local has fewer mirrors than the stream (e.g. dedicated server), create entries so we can store the data
    if #spec.mirrors < numbOfMirrors then
        g_AMDebug.info(myName .. ": Local has fewer mirrors, extending to " .. numbOfMirrors .. g_AMDebug.getIdentity(self.vehicle))
        for idx = #spec.mirrors + 1, numbOfMirrors do
            spec.mirrors[idx] = {}
        end
    end

    -- Always consume all stream data to keep the stream in sync
    local applyCount = math.min(#spec.mirrors, numbOfMirrors)
    for idx = 1, numbOfMirrors do
        local x0 = streamReadFloat32(streamID)
        local y0 = streamReadFloat32(streamID)
        if idx <= applyCount then
            local mirror = spec.mirrors[idx]
            if mirror ~= nil and mirror.x1 ~= nil then
                AdjustableMirrors.setMirror(self.vehicle, idx, x0, y0)
            else
                g_AMDebug.info(myName .. ": Storing data for mirror " .. idx .. " (no transform groups, server-side)" .. g_AMDebug.getIdentity(self.vehicle))
                mirror.x0 = x0
                mirror.y0 = y0
            end
        end
    end

    -- If local has more mirrors than the stream sent, send a full update so the server gets all mirror data
    if #spec.mirrors > numbOfMirrors then
        g_AMDebug.info(myName .. ": Local has " .. #spec.mirrors .. " mirrors but stream only had " .. numbOfMirrors .. ", sending full update" .. g_AMDebug.getIdentity(self.vehicle))
        if g_server ~= nil then
            g_server:broadcastEvent(AMAdjustMirrorsEvent.new(self.vehicle), nil, nil, self.vehicle)
        else
            g_client:getServerConnection():sendEvent(AMAdjustMirrorsEvent.new(self.vehicle))
        end
    end

    if not connection:getIsServer() then
        g_AMDebug.info(myName .. ": broadcasting event")
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if g_dedicatedServer == nil then
        g_AMDebug.info(myName .. ": Client received update from server")
    end
end


function AMAdjustMirrorsEvent:writeStream(streamID, connection)
    g_AMDebug.info(myName .. ": writeStream() - " .. streamID)
    local spec = self.vehicle.spec_adjustableMirrors
    NetworkUtil.writeNodeObject(streamID, self.vehicle)
    g_AMDebug.info(myName .. ": Number of mirrors sent is " .. #spec.mirrors)
    streamWriteInt8(streamID, #spec.mirrors)
    for idx, mirror in ipairs(spec.mirrors) do
        g_AMDebug.info(myName .. "Sending data for mirror " .. idx .. ": (x0, " .. mirror.x0 .. ", " .. mirror.y0 .. ")")
        streamWriteFloat32(streamID, mirror.x0)
        streamWriteFloat32(streamID, mirror.y0)
    end
end


function AMAdjustMirrorsEvent.sendEvent(vehicle)
    g_AMDebug.info(myName .. ": sendEvent()")
    if g_server ~= nil then
        g_AMDebug.info(myName .. ": g_server:broadcastEvent()")
        g_server:broadcastEvent(AMAdjustMirrorsEvent.new(vehicle), nil, nil, vehicle)
    else
        g_AMDebug.info(myName .. ": g_client:getServerConnection():sendEvent()")
        g_client:getServerConnection():sendEvent(AMAdjustMirrorsEvent.new(vehicle))
    end
end
