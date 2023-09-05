local args = {...}
local BootConfig = args[1]

if (BootConfig == nil or type(BootConfig) ~= "table") then
	error("Missing BootConfig!")
end

if BootConfig.Platform == 0 then
	-- ComputerCraft
	if command or turtle then
		term.clear();
		print("Hudson is not yet compatible with your computer type.");
		os.pulleventRaw("");
		os.shutdown();
	end
end

if (_G.IsRitoOS == true) then
	if (Application ~= nil) then
		if (type(Application.Exit) == "function") then
			Application.Exit(0, "Cannot run RitoOS within RitoOS!")
		end
	end
	error("Cannot run RitoOS within RitoOS!")
	return
end

IsRitoOS = true
_G.IsRitoOS = true


-- Internal "class"
Internal = {
	["BootConfig"] = BootConfig,
	["debug"] = true,

	["BootLoaderVersion"] = {
		type = "version",
		Major = 0,
		Minor = 1,
		Build = 0,
	},

	["DeveloperMode"] = true,
	["Language"] = "en-US",

	["Native"] = {}, -- Native APIs
	
	["FileSystem"] = {
		["ExposeCompatibilityLayer"] = debug -- exposes the ComputerCraft FS abstraction functions (creates fs.isDir() which calls fs.IsDirectory() .. etc)
	},
}

local oc = BootConfig.Platform == 1 and true or false
Internal.Platform = oc and "oc" or "cc"
local debug = Internal.debug


Internal.BootConfig.DoFile = function(filePath)
	local program, reason = Internal.BootConfig.LoadFile(filePath)
	if program then
		local result = table.pack(pcall(function() return program(Internal) end))
		if result[1] then
			return table.unpack(result, 2, result.n)
		else
			error(result[2])
		end
	else
		error(reason)
	end
end



--[[

	Step 1: copy native functions

]]

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

for k,v in pairs(_G) do
	if k~="_ENV" and k~="Internal" then
		Internal.Native[k]=copy(v)
	end
end

local writeStatus = function(message)
	if not debug then return end

	if oc then
		Internal.Native.writeOutput(message)
		Internal.Native.writeOutput()
	else
		Internal.Native.print(message)
	end
end

if oc then
	-- Copy "native"
	Internal.Native.loadfile = Internal.BootConfig.LoadFile

	sleep = function(seconds) -- quick and dirty
		if (type(seconds) ~= "number") then
			seconds = 0
		end

		if (seconds <= 0) then
			seconds = 0.0001
		end

		local startTime = Internal.Native.computer.uptime()
		while Internal.Native.computer.uptime() - startTime < seconds do
			Internal.Native.computer.pullSignal(seconds - (computer.uptime() - startTime))
		end
	end
end

-- remove for security/safety
if not debug then
	for k,v in pairs(_G) do
		if type(v) == "table" and (k~="System" and k~="RIT" and not "_ENV") then
			-- writeStatus("Deleting _G[" .. k .. "]")
			_G[k]=nil;
		end
	end
end



--[[

	Step 2: Setup Holtin dummy functions
]]
-- to:do



--[[

	Step 3: load FileSystem

]]
local fsFunc, err = Internal.BootConfig.LoadFile("/System/Boot/HFS.lua");
if not fsFunc then
	if err ~= nil then
		error(err)
	else
		error("Failed to load FileSystem.")
	end
else
	writeStatus("Loading FileSystem...")
	Internal.FileSystem = fsFunc(Internal)
	writeStatus("FileSystem loaded")
end

-- Mount
if oc then
	writeStatus("Mounting: " .. Internal.Native.computer.getBootAddress() .. " to \"/\"")
	Internal.FileSystem.Mount(Internal.FileSystem.GetOpenComputersDriveComponent(Internal.Native.computer.getBootAddress()), "/")
else
	writeStatus("Mounting: \"/\" to \"/\"")
	Internal.FileSystem.Mount("/", "/") -- Mounts the root to .. the root
	if debug then
		writeStatus("Mounting \"/rom\" to \"/rom\"")
		Internal.FileSystem.Mount("/rom", "/rom") -- Mount rom
	end
end
-- set
fs = Internal.FileSystem
if oc then
	Internal.Native.fs = copy(fs) -- although, probably shouldn't be using that!
end

-- Machine id
local machineId = Internal.FileSystem.ReadAllText("/System/Vault/MachineId")
if (machineId == nil) then
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	local machineId = string.gsub(template, '[xy]', function (c)
        local r = math.random(0, 0xf)
        local v = (c == 'x') and r or (r % 4 + 8)
        return string.format('%x', v)
    end)
	Internal.FileSystem.WriteAllText("/System/Vault/MachineId", machineId)
end
Internal.MachineId = machineId

-- LoadFile
Internal.BootConfig.LoadFile = function(filename, mode, env)
    -- Support the previous `loadfile(filename, env)` form instead.
    if type(mode) == "table" and env == nil then
        mode, env = nil, mode
    end

    local function checkArg(n, have, ...)
		have = type(have)
		local function check(want, ...) if not want then return false else return have == want or check(...) end end
		if not check(...) then
			local msg = string.format("bad argument #%d (%s expected, got %s)", n, table.concat({...}, " or "), have)
			error(msg, 3)
		end
	end

    checkArg(1, filename, "string")
    checkArg(2, mode, "string", "nil")
    checkArg(3, env, "table", "nil")

    local fileHandle, err = Internal.FileSystem.Open(filename, "r")
    if not fileHandle then return nil, err end
    local func, err = load(fileHandle.readAll(), "@/" .. Internal.FileSystem.Canonical(filename), mode, env)
    fileHandle.close()
    return func, err
end
Internal.Native.loadfile = Internal.BootConfig.LoadFile




--[[
	
	Step 4: Load and apply boot options

]]
-- This sets the language (and debugging mode ( debugging mode will allow for possible root :^) ))
if Internal.FileSystem.Exists("/System/Boot/Options") then
	local optionsHandle = fs.open("/System/Boot/Options","r")
	local F = {}
	pcall(function() F = textutils.unserialize(optionsHandle.readAll() or "{}") end) -- todo: custom file scheme to not use textutils
	optionsHandle.close()
	if F then
		Internal.Language = F.Language or "en-US"
		Internal.DeveloperMode = F.DeveloperMode or Internal.DeveloperMode
	end
end



--[[

	Step 5: Load device drivers

]]
-- Load drivers
local platformName = "ComputerCraft"
if oc then
	platformName = "OpenComputers"
end

local driversPath = "/System/Drivers/" .. platformName .. "/"
Internal.DriverStore = {}
local LoadedDrivers = {}
if (Internal.FileSystem.Exists(driversPath)) then
	for _,file in pairs(Internal.FileSystem.list(driversPath)) do
		local driverName = Internal.FileSystem.GetName(file)
		if (string.sub(driverName, -4) == ".lua") then
			driverName = string.sub(driverName, 1, -5)
		end
		driverName = string.lower(driverName)

		local driverPath = Internal.FileSystem.Combine(driversPath, file)
		if debug then
			writeStatus("Loading driver " .. driverName .. " from: " .. driverPath)
		end

		local driverChunk, err = Internal.BootConfig.LoadFile(driverPath)
		if not driverChunk then
			if err then
				error("!Failed to load driver " .. driverName .. "(" .. tostring(err) .. ")")
			else
				error("!Failed to load driver " .. driverName)
			end
		else
			Internal.DriverStore[driverName] = driverChunk(Internal)
			table.insert(LoadedDrivers, driverName)
		end
	end
else
	writeStatus("No drivers to load.")
end
local dStore = Internal.DriverStore
function Internal.GetDriver(name) -- for god knows why YOU MUST use that function to get the driver!
	return dStore[string.lower(name or "")]
end


--[[

	Step 6: Load abstraction layer

]]
local halPath = "/System/HAL/" .. platformName .. "/"
Internal.DriverStore = {}
if (Internal.FileSystem.Exists(halPath)) then
	for _,file in pairs(Internal.FileSystem.list(halPath)) do
		local halFileName = Internal.FileSystem.GetName(file)
		if (string.sub(halFileName, -4) == ".lua") then
			halFileName = string.sub(halFileName, 1, -5)
		end
		halFileName = string.lower(halFileName)

		local halFilePath = Internal.FileSystem.Combine(halPath, file)
		if debug then
			writeStatus("Loading abstraction " .. halFileName .. " from: " .. halFilePath)
		end

		local ok, err = pcall(function() Internal.BootConfig.DoFile(halFilePath) end)
		if not ok then
			if err then
				writeStatus("!Failed to abstraction layer " .. halFileName .. "(" .. tostring(err) .. ")")
			else
				writeStatus("!Failed to load driver " .. halFileName)
			end
		end
	end
else
	writeStatus("No HAL folder.")
end



--[[

	Step 7: Draw boot screen

]]
-- a basic boot screen
local function drawBootScreen(termObject)
	termObject.setBackgroundColor(colors.black)
	if not debug then
		termObject.clear()
	end
	local X,Y = Internal.Native.term.getSize();
	local midX,midY = (X/2),(Y/2)
	termObject.setCursorPos((X/2)-3, (Y/2)-1)
	termObject.setTextColor(colors.white)
	termObject.write("RitoOS");
	termObject.setCursorPos(midX-7,midY+1)
	termObject.setTextColor(colors.lightGray)
	termObject.write("Project Hudson")
	termObject.setCursorPos(1, 1)

	if Internal.DeveloperMode then
		termObject.setTextColor(colors.red)
		termObject.write("developer mode")
		termObject.setTextColor(colors.white)
	end
end
-- drawBootScreen(Internal.Native.term)



--[[

	Step 8: Load RIT System API

]]
Internal.BootConfig.DoFile("/System/RIT/System.lua") -- calls System.lua (which setups RIT) while providing Internal
Log = System.GetLog("Boot", Internal.RuntimeKey)
Log.Info("Loading RIT APIs")

local filesInAPIDirectory = Internal.FileSystem.List("/System/RIT/")
for _, fileName in ipairs(filesInAPIDirectory) do
	local apiName = string.sub(fileName, 0, #fileName-4)
	if (string.sub(fileName, -4) == ".api") and System[apiName] == nil then
		-- probably an api
		pcall(function()
			writeStatus("Loading API " .. apiName);
			local _ = System.GetAPI(apiName)
		end)
	end
end




--[[

	Step 10: Setup ViewPorts (similar to CC's `window`)


	 Native
	   |
 S-OS-----Current
  |			 |
  Secure     OS
  Stuff       |--> User Term (System output) --> User Sessions
  			  |--> Logs
]]

-- Setup the OS's window
Internal.ViewPorts = {}

-- -- Create the OS window (drawn on the current term)
-- Internal.Terms["OS"] = Internal.Native.window.create(Internal.Native.term.current(),1,1,Internal.Terms.Width,Internal.Terms.Height,true)
-- -- Create the Secure OS window (drawn on the native term)
-- Internal.Terms["SecureOS"] = Internal.Native.window.create(Internal.Native.term.native(),1,1,Internal.Terms.Width,Internal.Terms.Height,false)
-- -- Create the Log OS window (drawn on the OS term)
-- Internal.Terms["Logs"] = Internal.Native.window.create(Internal.Terms["OS"], 1,1, Internal.Terms.Width,Internal.Terms.Height, false)
-- -- User space term (drawn on the OS term)
-- Internal.Terms["User"] = Internal.Native.window.create(Internal.Terms["OS"], 1,1, Internal.Terms.Width,Internal.Terms.Height, true)

-- Internal.Terms["Current"] = Internal.Terms["User"]

-- Internal.Terms["SecureOS"].setBackgroundColor(colors.red)
-- Internal.Terms["SecureOS"].clear()


-- Now the windows are setup, draw the boot screen
--[[
local midX,midY = (Internal.Terms.Width/2),(Internal.Terms.Height/2)
Internal.ViewPorts["OS"].setBackgroundColor(colors.black)
Internal.ViewPorts["OS"].clear()
Internal.ViewPorts["OS"].setCursorPos(midX-3, midY-1)
Internal.ViewPorts["OS"].setTextColor(colors.white)
Internal.ViewPorts["OS"].write("RitoOS")
Internal.ViewPorts["OS"].setCursorPos(midX-7,midY+1)
Internal.ViewPorts["OS"].setTextColor(colors.lightGray)
Internal.ViewPorts["OS"].write("Project Hudson")
]]



--[[

	Step 11: Redraw the screen, again :)

]]
-- temp
drawBootScreen(Internal.Native.term)
-- sleep(1);



--[[

	Step 12: Load CodeX in, enter main message handler

]]
-- Main OS loop :-> push hardware events to drivers :-> [drivers then] push events to System.EventEmitter, which pushes to individual Sessions

--[[

							these act as translators! --\									added by processes --\-- these don't necessarily exist, but they do run first!
														|														 |
														V 														 v

										|-------> network driver  --->\									|-----> listener
										|-------> keyboard driver ---> \								|-----> listener
	CC/OC -- #EVENT# --> this handler --|-------> graphics driver --->  |----> System.EventEmitter ---> |-----> listener
										|-------> mouse driver    ---> /				v				|-----> listener
										|-------> redstone driver --->/					|				|-----> listener
																						|
																						^
																				System Scheduler
																		   (waiting for *any* event)
																		Using System.EventEmitter.Pull()
]]
-- Setup EventEmitter
Internal.SysEvents = System.GetAPI("EventEmitter", true) -- unique copy
-- Internal.SysEvents.DoNotPush = true

-- get the drivers to hook
for _, driverName in ipairs(LoadedDrivers) do
	local driver = Internal.GetDriver(driverName)
	if (type(driver) == "table") then
		if (type(driver.Main) == "function") then
			Log.Info("Calling main function for driver " .. driverName)
			local driverOk, driverErr = pcall(function() driver.Main() end)
			if (not driverOk) then
				if driverErr then
					Log.Error("Driver crashed! Driver: " .. driverName .. "\n\nError: " .. tostring(driverErr))
				else
					Log.Error("Driver crashed, unknown error! Driver: " .. driverName)
				end
			else
				Log.Info(driverName .. "'s Main() successfully ran.")
			end
		end
	end
end


local protectedEvents = { -- protected means only the active session receives the event. (so if a user is not physically active, they cannot see these events, like key presses)
	"keydown",
	"key", -- cc
	"keyhold",
	"keyholdreleased",
	"keyup",
	"key_up", -- cc
	"keyboard_character",
	"char", -- cc
	"paste"
}

-- Add event handler to scheduler
--[[

	The event handler

	-- this might need to be pulled out?

]]
SchedulerHandleEvent = function(...)
	local event = {...}
	if type(Internal.Sessions) ~= "table" then
		Internal.Sessions = {}
		return;
	end

	local protectedEvent = false
	for _,protectedEventName in pairs(protectedEvents) do
		-- event[1] will likely work, however..
		-- event[2] may be the actual even name _if_ event[1] is the EventEmitter's id
		-- the more "proper" way to do this may be checking if event[1] is an EventEmitter's id, and if it is then checking event[2].

		if (event[1] == protectedEventName or event[2] == protectedEventName) then
			protectedEvent = true
		end
	end

	if Internal.CodeX.LockoutSessions then
		return true
	end

	for i, session in pairs(Internal.Sessions) do
		-- valid session? is the session active _or_ is the event not "protected"?
		if (session ~= nil) and (session.Username == Internal.CodeX.ActiveSession or not protectedEvent) then
			local ok, err = pcall(function() session:HandleEvent(System.Table.unpack(event)) end)
			if not ok then
				if err then
					error("Critical error while handling scheduler event!\n\nError: "..tostring(err))
				else
					-- oh god ,,, probably should crash -> protect data
					error("Critical error while handling scheduler event!")
				end
			end
		end
	end
	return true
end



-- Setup system threads

Internal.CodeXThread = coroutine.create(function() -- someone will uh get this, right?
	Log.Info("Calling CodeX.Initial()");
	local ok, err = pcall(function() System.CodeX.Initial(); end)
	-- local ok, err = pcall(function() System.CodeX.DrawLogin(nil, true); end)
	if not ok then
		print("CodeX error: " .. tostring(err))
		error(err)
	end
end)

-- "thread"
Internal.SchedulerThread = coroutine.create(function()
	local sysEvent = {}
	while true do
		sysEvent = {coroutine.yield()};
		-- print(sysEvent[1])
		-- if (sysEvent[1] == System.EventEmitter.Id) then
			-- Internal.System.Table.remove(sysEvent, 1)
			if not Internal.CodeX.LockOutSession then
				local k, e = pcall(function() SchedulerHandleEvent(Internal.System.Table.unpack(sysEvent)) end)
				if not k then
					print(e)
				end
			end
		-- end
		local status = coroutine.resume(Internal.CodeXThread, System.Table.unpack(sysEvent))
	end
end)


-- first "push"
coroutine.resume(Internal.SchedulerThread, {})
coroutine.resume(Internal.CodeXThread, {})

Log.Info("SysEvent id: " .. Internal.SysEvents.Id)
Log.Info("SystemEventEmitter id: " .. Internal.System.EventEmitter.Id)

local scrollPrimed = false
local coreOkay, coreError = pcall(function()
	while true do
		local hardwareEvent = {}
		local hardwareEventTemp = ""
		if oc then
			hardwareEvent = {Internal.Native.computer.pullSignal()}
		else
			hardwareEvent = {Internal.Native.os.pullEventRaw()}
			if (hardwareEvent ~= nil and hardwareEvent[1] == "key" and (hardwareEvent[2]>=32 and hardwareEvent[2]<=126)) then -- yeah it's ROUGH, so what
				-- dumb bug fix for keyboard driver (CC).
				-- the driver takes too long to process, screws up with the char event (which happens INSTANTLY after the key event!)
				hardwareEventTemp = {Internal.Native.os.pullEventRaw("char")}
				-- print(table.unpack(hardwareEvent))
				-- print(table.unpack(hardwareEventTemp))
			end
		end

		if debug and hardwareEvent[1]:len() < 15 then
			if ((oc and hardwareEvent[1] == "touch") or (not oc and hardwareEvent[1] == "mouse_click")) and scrollPrimed then
				-- bye bye
				error("999::HALT-scrollPrimed")

			elseif (oc and hardwareEvent[1] == "scroll") or (not oc and hardwareEvent[1] == "mouse_scroll") then
				scrollPrimed = true
			else
				scrollPrimed = false
			end
		end

		Internal.SysEvents.Emit(System.Table.unpack(hardwareEvent))
		local status = coroutine.resume(Internal.SchedulerThread, System.Table.unpack(hardwareEvent)) -- yeah....
		-- Internal.System.EventEmitter.Emit(System.Table.unpack(hardwareEvent))
		if (type(hardwareEventTemp) == "table") then
			Internal.SysEvents.Queue(System.Table.unpack(hardwareEventTemp))
			local status = coroutine.resume(Internal.SchedulerThread, System.Table.unpack(hardwareEventTemp)) -- yeah....
		end
		if (status == "dead") then
			error("00::HALT")
		end
	end
end)

if (not coreOkay) then
	error("01::CORE_HANDLER_ERROR ->| " .. tostring(coreError or "!unknown"))
else
	-- what?
	error("00::HALT")
end