--[[

	RIT System API

	Version 1.0

]]


local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object!")
end
local oc = Internal.Platform == "oc" and true or false



local ipairs = Internal.Native.ipairs;
local pairs = Internal.Native.pairs;
local type = Internal.Native.type;
local setmetatable = Internal.Native.setmetatable;
local getmetatable = Internal.Native.getmetatable;

local Logger = {}


Internal.Log = {
	["Handles"] = {},
}

Internal.CodeX = {
	["Hashes"] = {
		--[[
		["userID"] = {
			IHP = "",
			salt = "",
		},
		]]
	},
	["Sessions"] = { -- Tasks, windows, users, key all stored in here
		["System"] = {
			--[[
			["example_task_id"] = {
				name = "Minesweeper Game",
				term = term_obj -- This CAN be a reference to the 'control' window from the DWM
				key = "" -- Task key
				threads = { -- Coroutines
					[0] = coroutine 1 -- Main thread
				}

				path = "/Apps/Minesweeper/" -- The path to the folder of the executable
				executable = "minesweeper.rap" -- The name of the program executable (under path)

				executableHash = "" -- Hash of the executable
				executableSignature = "" -- The signature of the hash

				appPackage = true -- RitoOS App Package?
			},
			]]
		},
	}
}

Internal.SecureMachineKey = Internal.FileSystem.ReadAllBytes("/System/Vault/SecureMachineKey")
if Internal.SecureMachineKey == nil or Internal.SecureMachineKey == "" then
	Internal.SecureMachineKey = ""
	math.randomseed(0)
	math.randomseed((math.random()+1)*os.time())
	for i=0, 2048 do
		Internal.SecureMachineKey = Internal.SecureMachineKey .. string.char(math.random(1,255))
	end
	Internal.FileSystem.WriteAllBytes("/System/Vault/SecureMachineKey", Internal.SecureMachineKey)
end

-- This creates the system key (system key is used by programs to request system level access to APIs)
Internal.RuntimeKey = ""
-- math.randomseed(math.random(1,10000) + (os.time() .. os.day())) -- Set system 'randomness'
for i=1, 2048 do
	Internal.RuntimeKey=Internal.RuntimeKey..string.char(math.random(1,255))
end





-- Clear log files
local function initilizeLog(location)
	if (Internal.FileSystem.Exists(location) and Internal.FileSystem.GetSize(location) <= 75000) then -- only if the file is not that big. this is ~1500 lines?
		Internal.FileSystem.Copy(location, location..".previous", true) -- Copy the previous log in case it's needed later
	end
	Internal.Log.Handles[location] = Internal.FileSystem.Open(location,"w")
	Internal.Log.Handles[location].WriteLine("["..os.clock().."] <> Bonjour!")
	Internal.Log.Handles[location].Flush()
end
initilizeLog("/System/Logs/System.log") -- Read the name
initilizeLog("/System/Logs/Applications.log") -- Applications will log to this file


-- System API
System = {}

System.Localization = {
	["SupportedLanguages"] = {},
	["Languages"] = {}, -- Loaded languages
}

System.Version = {
	type = "version",
	Major = 0,
	Minior = 0,
	Build = 1,
}

System.Errors = {
	["LogNameNotPermitted"] = "Log name is not permitted",
	["LanguageNotSupported"] = "That language is not supported"
}


function System.GetPlatform()
	return "RitoOS", {
		["Version"] = System.Version,
		["Hardware"] = Internal.Platform == "oc" and "OpenComputers" or "ComputerCraft",
		["HardwareCode"] = Internal.Platform,
	};
end


--[[
	Add some FileSystem helpers
]]
System.FileSystem = Internal.FileSystem

-- Removes leading slash
function System.FileSystem.RemoveLeadingSlash(path)
	if string.sub(path,0,1) == "/" then
		return string.sub(path,2,string.len(path))
	else
		return path
	end
end

-- Removes '..'
function System.FileSystem.Strip(f) -- Used in the GetAPI/getLang
	f=f or ""
	f = f:gsub("\\","/")	
	f = f:gsub("%.%./","/")
	f = f:gsub("/%.%.","/")
	f = f:gsub("//","/")
	
	if f:match("//") ~= nil and f:match("%.%./") ~= nil or f:match("/%.%.") ~= nil then
		f = Internal.strip(f)
	end

	return f
end

--[[

	Common helpers

]]

--[[

	Asserts an argument (have) is of one of the types provided by (...).
	If the argument is not one of the correct types, an error is thrown: "bad argument n (* or * expected, got *)"

	n specifies the argument number

]]
function System.CheckArgument(n, have, ...)
	have = type(have)
	local function check(want, ...)
		if not want then
			return false
		else
			return have == want or check(...)
		end
	end
	if not check(...) then
		local msg = string.format("bad argument #%d (%s expected, got %s)", tostring(n), table.concat({...}, " or "), have)
		error(msg, 3)
	end
end


System.Table = table
--[[
	Inserts a value into a table if the value is not already there.
]]
function System.Table.InsertUniqueValue(t, value)
	for _, v in ipairs(tbl) do
		if v == value then
			return  -- Value already exists, no need to insert
		end
	end
	Internal.Native.table.insert(tbl, value)  -- Insert the value if it doesn't already exist
end

--[[
	Protects the original contents of the table by making them read-only, but allowing new content to be added.
	Prevents existing data from being modified or removed.
]]
function System.Table.Protect(original)
	local writeable = {} -- Table to store new values
	local proxy = {} -- proxy table, what's handed back

	-- Recursive function to handle nested tables
	local function make_readonly(t)
		if type(t) ~= 'table' then
			return t
		end

		local writeable = {}
		local proxy = {}
		local mt = {
			__index = function(_, k)
				if writeable[k] ~= nil then
					return writeable[k]
				else
					return make_readonly(t[k])
				end
			end,
			__newindex = function(_, k, v)
				if t[k] == nil then
					writeable[k] = v
				end
			end
		}
		Internal.Native.setmetatable(proxy, mt)
		return proxy
	end

	return make_readonly(original)
end
--[[
	Makes a table read-only without the ability to add new keys.
]]
function System.Table.Seal(original)
	local writeable = {} -- Table to store new values
	local proxy = {} -- proxy table, what's handed back

	-- Recursive function to handle nested tables
	local function make_readonly(t)
		if type(t) ~= 'table' then
			return t
		end

		local writeable = {}
		local proxy = {}
		local mt = {
			__index = function(_, k)
				return make_readonly(t[k])
			end,
			__newindex = function(_, k, v) end
		}
		Internal.Native.setmetatable(proxy, mt)
		return proxy
	end

	return make_readonly(original)
end

function System.Table.Copy(t)
	function copy(obj, seen)
		if type(obj) ~= 'table' then return obj end
		if seen and seen[obj] then return seen[obj] end
		local s = seen or {}
		local res = setmetatable({}, getmetatable(obj))
		s[obj] = res
		for k, v in pairs(obj) do
			if k~="_G" or k~="_ENV" then
				res[copy(k, s)] = copy(v, s)
			end
		end
		return res
	end
	return copy(t)
end

function System.Table.ZeroOut(t)
	local function zeroOut(tbl)
		for k,v in ipairs(tbl) do
			if (type(v) == "table") then
				zeroOut(v)
			end
			v = nil
		end
	end

	zeroOut(t)
end

function System.Table.FromHex(str)
	if (#str % 2 ~= 0) then
		error("Odd length string, not a valid hex string.");
	end
	local final = {};
	local index = 1;
	for i=1, #str/2 do
		local segment = str:sub(index,index+1);
		table.insert(final, tonumber(segment, 16));
		index=index+2;
	end
	return final;
end


-- Returns the epoch
function System.Epoch(locale)
	if (oc) then
		return Internal.Native.computer.uptime()
	else
		return Internal.Native.os.epoch(locale)
	end
end

--[[

	Returns the number of seconds the system has been running.
]]
function System.Uptime()
	local now = System.Epoch("utc");
	return (now - Internal.BootTime) / 1000;
end



--[[

	Power control (shutdown, restart, hibernate*)

	* Hibernate will *hopefully* be implemented at some point, although I wouldn't hold my breath for that.
]]


local function internalPower(isRestart, cause, delay)
	local reason = "unknown"
	delay = type(delay) == "number" and delay or 0
	delay = delay > 120 and 120 or delay
	delay = delay < 0 and 0 or delay

	if (type(cause) == "string") then
		cause = Internal.Native.string.lower(cause)
		if (cause == "shutdown" or cause == "restart" or cause == "system" or cause == "user" or cause == "application" or cause == "unknown") then
			reason = cause
		end
	end

	Logger.Info("System is " .. (isRestart and "restarting! " or "shutting down! ") .. "Reason? " .. tostring(reason) .. " - delay: " .. tostring(delay))
	pcall(function() -- wrapped in a pcall in the event something bad happens we still want the machine to shutdown.
		Internal.SysEvents.Emit("system_shutdown", {
			["Reason"] = reason,
			["GraceDuration"] = delay,
			["WillRestart"] = isRestart
		}) -- this will be fired synchronously...so we can't actually enforce that grace period ... but attempts were made!
		System.EventEmitter.PullRaw(nil, delay) -- wait X seconds, this also releases control back to the system scheduler
		
		-- So anyway, I started blasting
		for i, session in pairs(Internal.Sessions) do
			if (session ~= nil and type(session.Logout) == "function") then
				Logger.Info("Logging out user (".. (isRestart and "restarting" or "shutting down") .."): " .. (session.Username ~= nil and tostring(session.Username) or "unknown_user!"))
				session:Logout("system", delay)
			end
		end
	end)


	-- Clean up, shutdown activities
	pcall(function()
		Internal.FileSystem.WriteAllText("/System/Boot/BN","")

		-- Goodbye!
		Logger.Info("Fin!")
	end)


	if (oc) then
		Internal.Native.computer.shutdown(isRestart)
	else
		if (isRestart) then
			Internal.Native.os.reboot()
		end

		Internal.Native.os.shutdown()
	end
end


--[[
	Logs out all users and shuts down the computer.

	First the "system_shutdown" event is fired (to all users and even if restarting), we wait `delay` seconds, then one-by-one the users are logged out via `Session:Logout()`.
	Afterwards, the system cleans up and then calls the platform's shutdown.

	Delay is the number of seconds to wait after the "system_shutdown" event is fired and we being to log users off. It is also used in `Session:Logout()`.
]]
function System.Shutdown(cause, delay)
	internalPower(false, cause, delay)
end

function System.Restart(cause, delay)
	internalPower(true, cause, delay)
end





--[[

	Logging

]]

-- Setup logging
function System.GetLog(name, key) -- "Name" is the program (or whatever) is requesting the handle. For example, when CodeX calls System.GetLogHandle, it's "Name" is "CodeX"
	System.CheckArgument(1, name, "string")

	local log = {
		["Name"] = name,
	}

	local Location = "/System/Logs/Applications.log"
	if key and key == Internal.RuntimeKey then
		Location = "/System/Logs/System.log"
	end

	if name == "System" and Location ~= "/System/Logs/System.log" then
		return nil, System.Errors.LogNameNotPermitted
	end

	local function internalLog(State, Message)
		local logLine = ("["..System.Uptime().."]["..State.."] "..name.." | "..Message.."\n")
		pcall(function()
			Internal.Log.Handles[Location].Write(logLine)
			Internal.Log.Handles[Location].Flush()
			if Internal.Terms.Log then
				Internal.Terms.Log.Write(logLine)
			end
		end)
	end

	log.Info = function(msg) internalLog("Info", msg) end
	log.Alert = function(msg) internalLog("Alert", msg) end
	log.Warn = function(msg) internalLog("Warn",msg) end
	log.Error = function(msg) internalLog("Error",msg) end

	return log
end

Logger = System.GetLog("System", Internal.RuntimeKey)


--[[
	Returns an API table

	unique: boolean - returns a unique copy of the API from the FileSystem rather than cache. Dangerous, could result in memory leak if not disposed of properly.
]]
function System.GetAPI(name, unique)
	System.CheckArgument(1, name, "string")

	Logger.Info("Getting API: "..name)
	name = Internal.FileSystem.Strip(name)
	name = string.lower(name)

	local apis = Internal.FileSystem.List("/System/RIT/")
	local apiNameWithCasing = ""
	local fileExists = false
	for _,fileName in ipairs(apis) do
		if (string.lower(fileName) == name..".api") then
			apiNameWithCasing = string.sub(fileName, 0, #fileName-4)
			fileExists = true
		end
	end

	if (type(System[apiNameWithCasing]) == "table" and not unique)then
		return System[apiNameWithCasing]
	end
	
	local apiPath = "/System/RIT/"..apiNameWithCasing..".api"
	if fileExists then
		local apiFileHandle,err = Internal.Native.loadfile(apiPath)
		if apiFileHandle == nil then
			Logger.Error("Error loading "..name.."\n\tError: "..err)
		elseif type(apiFileHandle) == "function" then
			Logger.Info(name .. " loaded from disk successfully")
			local api = apiFileHandle(Internal)
			if not unique then
				System[apiNameWithCasing] = System.Table.Seal(api);
				if (apiNameWithCasing == "Crypto") then
					-- add the RandomGenerator and ECC
					api.RandomGenerator = System.GetAPI("RandomGenerator");
					api.ECC = System.GetAPI("ECC");
					System[apiNameWithCasing] = System.Table.Seal(api);
				end
				return System[apiNameWithCasing]
			else
				return System.Table.Seal(api)
			end
		end
	else
		Logger.Error("Error loading " .. name .. "\n\tError: no such file")
	end
end




--[[

	Localization

]]

-- Localization
local languageFiles = {};
if Internal.FileSystem.IsDirectory("/System/Localization") then
	languageFiles = Internal.FileSystem.List("/System/Localization")
end
for i,fileName in ipairs(languageFiles) do
	if (string.sub(fileName, -5) == ".lang") then
		-- Supported
		languageName = string.lower(string.sub(fileName, 0, #fileName-5))
		table.insert(System.Localization.SupportedLanguages, languageName)
	end
end

-- Language string table
function System.Localization.GetLanguage(language)
	if type(System.Localization.Languages[language]) == "table" then
		return System.Localization.Languages[language]
	end

	if language == "" or language == nil then
		language = Internal.Language
	end

	local Supported = System.Localization.SupportedLanguages[string.lower(language)]
	
	if not Supported then
		return nil, System.Errors.LanguageNotSupported
	end
	local handle = Internal.FileSystem.Open("/System/Localization/"..language..".lang", "r")
	if (handle == nil) then return nil end
	local contents = handle.readAll()
	handle.close()
	System.Localization.Languages[language] = System.Table.Seal(System.JSON.Unserialize(contents))
	return System.Localization.Languages[language]
end
local _ = System.Localization.GetLanguage() -- Loads a language table into memory for the system to use. (Available to all system processes)






--[[

	Configuration

]]
-- Set Configuration API
Internal.RCF = System.GetAPI("RCF", Internal.RuntimeKey)
System.GetConfig = function(config, key)
	return Internal.RCF("/System/Configuration/"..config, key)
end



-- Kernel loaded.
Logger.Info("System API loaded.")

_G.System = System
Internal.System = System
return Internal