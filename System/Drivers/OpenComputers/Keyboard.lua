--[[
	
	RitoOS

	OpenComputers Keyboard Driver


]]

local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object!")
end
if Internal.Platform ~= "oc" then
	error("Unsupported platform.")
end




local KeyboardDriver = {}
local History = {}

local Modifiers = {
	["Ctrl"] = false,
	["Shift"] = false,
	["Alt"] = false,
	["ScrollLock"] = false, -- for funnsies
}

local function setModifier(keyCode, enable)
	if (type(keyCode) ~= "number") then return end
	enable = enable == true and true or false


	if (System.Keyboard.GetKeyCode("leftShift") == keyCode or System.Keyboard.GetKeyCode("rightShift") == keyCode) then
		Modifiers.Shift = enable
	elseif (System.Keyboard.GetKeyCode("leftCtrl") == keyCode or System.Keyboard.GetKeyCode("rightCtrl") == keyCode) then
		Modifiers.Ctrl = enable
	elseif (System.Keyboard.GetKeyCode("leftAlt") == keyCode or System.Keyboard.GetKeyCode("rightAlt") == keyCode) then
		Modifiers.Alt = enable
	elseif (System.Keyboard.GetKeyCode("scrollLock") == keyCode) then
		Modifiers.ScrollLock = enable
	end
end


local function handleEvent(...)
	local event = {...}
	if (event == nil) then
		return
	end

	local currentTime = System.Uptime();
	local function getDelay(time)
		return currentTime-time;
	end

	local eventName = event[1];
	local holdDuration = 0;

	if (History == nil) then History = {} end

	local keyEvent = ""
	local keyCode = event[4];
	if (eventName == "key_down" or eventName == "key_up") then
		local keyCodeString = tostring(keyCode);
		if (eventName == "key_down") then
			-- down and hold events

			setModifier(keyCode, true)

			if (History[keyCodeString] == nil) then
				History[keyCodeString] = {
					["LastUp"] = nil,
					["LastDown"] = nil,
					["HoldStartTime"] = nil,
				};
			end

			if (History[keyCodeString].LastDown ~= nil) then
				-- being held
				keyEvent = "hold";

				if (History[keyCodeString].HoldStartTime == nil) then
					-- just starting being held
					History[keyCodeString].HoldStartTime = currentTime;
				else
					holdDuration = getDelay(History[keyCodeString].HoldStartTime);
				end
			else
				-- just pressed
				History[keyCodeString].LastDown = currentTime;
				keyEvent = "down";
			end

		-- end key
		elseif (eventName == "key_up") then
			if (System.Keyboard.GetKeyCode("scrollLock") ~= keyCode) then -- Do not unset the scroll lock if the release it. It's a toggle, not if being pressed!
				setModifier(keyCode, false);
			end

			if (History[keyCodeString] == nil) then
				History[keyCodeString] = {
					["LastUp"] = nil,
					["LastDown"] = nil,
					["HoldStartTime"] = nil,
				};
			end
			History[keyCodeString].LastDown = nil;
			History[keyCodeString].LastUp = currentTime;

			if (History[keyCodeString].HoldStartTime ~= nil) then
				-- released
				keyEvent = "holdRelease";
				holdDuration = getDelay(History[keyCodeString].HoldStartTime);
				History[keyCodeString].HoldStartTime = nil;
			else
				keyEvent = "up";
			end
		end
		
	elseif (eventName == "paste") then
		keyEvent = "paste";
	end

	local ok, err = pcall(function()
		if (keyEvent == "down") then
			Internal.System.EventEmitter.Emit("KeyDown", keyCode, Modifiers);
			-- CC compatibility
			Internal.System.EventEmitter.Emit("key", keyCode, false);

			-- Character?
			if (event[3] ~= 0) then
				-- Character pressed, send it too
				Internal.System.EventEmitter.Emit("Keyboard_Character", string.char(event[3]), Modifiers);
				-- CC compatibility
				Internal.System.EventEmitter.Emit("char", string.char(event[3]));
			end

		elseif (keyEvent == "hold") then
			Internal.System.EventEmitter.Emit("KeyHold", keyCode, Modifiers, holdDuration);
			-- CC compatibility
			Internal.System.EventEmitter.Emit("key", keyCode, true);

		elseif (keyEvent == "holdRelease") then
			Internal.System.EventEmitter.Emit("KeyHoldReleased", keyCode, Modifiers, holdDuration);
			-- CC compatibility
			Internal.System.EventEmitter.Emit("key_up", keyCode);

		elseif (keyEvent == "up") then
			Internal.System.EventEmitter.Emit("KeyUp", keyCode, Modifiers);
			-- CC compatibility
			Internal.System.EventEmitter.Emit("key_up", keyCode);

		elseif (keyEvent == "paste") then
			Internal.System.EventEmitter.Emit("Keyboard_Paste", event[3], Modifiers);
			-- CC compatibility
			Internal.System.EventEmitter.Emit("paste", keyCode);
		end
	end)

	if not ok then writeOutput(err) end
end

function KeyboardDriver.Main()
	-- Entry point
	Internal.SysEvents.AddEventListener("char", function(...) handleEvent("char", ...) end)
	Internal.SysEvents.AddEventListener("key_down", function(...) handleEvent("key_down", ...) end)
	Internal.SysEvents.AddEventListener("key_up", function(...) handleEvent("key_up", ...) end)
	Internal.SysEvents.AddEventListener("clipboard", function(...) handleEvent("paste", ...) end)
end

return KeyboardDriver