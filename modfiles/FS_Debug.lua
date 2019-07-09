--#######################################################################################
--### Create the table holding all of the debugger.
--### MAX_LOG_LEVEL: Log levels  higher than this value, wont be output
--### modName: The mod name that gets prepended in console
--#######################################################################################
FS_Debug = {}

FS_Debug.log_level_max = 3
FS_Debug.mod_name = "Unspecified Modname"

--#######################################################################################
--### Base function for creating the properly formatted log output in the form of:
--### TimeStamp [modName][logLevel][prefix][message]
--### TimeStamp: Is in miliseconds since the game was loaded
--### modName: Modname supplied for the script, should be fetched from the moddesc
--### logLevel: Supplied log level to change severity, default is 0 which is the lowest
--### prefix: A little prefix to indicate error type f.eks. "info", "warning", "Error"
--### message: The log message
--#######################################################################################
function FS_Debug._log(log_level, log_prefix,...)
    log_level = log_level or 0 -- default value for log level
    if  log_level <= FS_Debug.log_level_max then
        local txt = ""
        for idx = 1,select("#", ...) do
            txt = txt .. tostring(select(idx, ...))
        end
        print(string.format("%7ums [%s]", (g_currentMission ~= nil and g_currentMission.time or 0), FS_Debug.mod_name) .. "[" .. FS_Debug.log_level_max .. "]" .. log_prefix .. " " .. txt)
    end
end

--#######################################################################################
--### Function with prefix=Debug
--#######################################################################################
function FS_Debug.debug(message, log_level)
    log_level = log_level or 3
	FS_Debug._log(log_level, "[Debug]", message)
end

--#######################################################################################
--### Function with prefix=Info
--#######################################################################################
function FS_Debug.info(message, log_level)
    log_level = log_level or 2
	FS_Debug._log(log_level, "[Info]", message)
end

--#######################################################################################
--### Function with prefix=Warning
--#######################################################################################
function FS_Debug.warning(message, log_level)
    log_level = log_level or 1
	FS_Debug._log(log_level, "[Warning]", message)
end

--#######################################################################################
--### Function with prefix=Error
--#######################################################################################
function FS_Debug.error(message, log_level)
    log_level = log_level or 0
	FS_Debug._log(log_level, "[Error]", message)
end

--#######################################################################################
--### Function for getting relevant info out of the "self" object, which should be 
--### supplied
--#######################################################################################
function FS_Debug.getIdentity(obj)
    return " (name: " .. obj:getFullName() .. ", rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end

function FS_Debug:args_to_txt(...)
    local args = { ... }
    local txt = ""
    local i, v
    for i, v in ipairs(args) do
        if i > 1 then
        txt = txt .. ", "
        end
        txt = txt .. i .. ": " .. tostring(v)
    end

    return(txt)
end