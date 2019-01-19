FS_Debug= {}

FS_Debug.MIN_LOG_LEVEL = 0

function FS_Debug._log(log_level,log_prefix,...)
    log_level = log_level or 0 -- default value for log level
    if  FS_Debug.MIN_LOG_LEVEL >= 0 and log_level >= FS_Debug.MIN_LOG_LEVEL then
        local txt = ""
        for idx = 1,select("#", ...) do
            txt = txt .. tostring(select(idx, ...))
        end
        print(string.format("%7ums [Adjustable Mirrors]", (g_currentMission ~= nil and g_currentMission.time or 0)) .. "[" .. tostring(log_level) .. "]" .. log_prefix .. " " .. txt);
    end
end

function FS_Debug.debug(message, log_level)
	FS_Debug._log(log_level, "[Debug]", message)
end

function FS_Debug.info(message, log_level)
	FS_Debug._log(log_level, "[Info]", message)
end

function FS_Debug.warning(message, log_level)
	FS_Debug._log(log_level, "[Warning]", message)
end

function FS_Debug.error(message, log_level)
	FS_Debug._log(log_level, "[Error]", message)
end
