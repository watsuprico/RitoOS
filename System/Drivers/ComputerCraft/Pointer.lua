--[[

	RitoOS Pointer Driver
		(Mouse, Touch)

]]

local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object")
end

if (Internal.Platform ~= "cc") then
	error("Unsupported platform.");
end


local PointerDriver = {};
local History = {};

local function handleEvent(...)
	local event = {...}
	if (event == nil) then
		return;
	end

	local currentTime = System.Uptime();
	local function getDelay(time)
		return currentTime-time;
	end

	local holdDuration = 0;
	local eventName = event[1];
	local isTouch = false;
	local primaryMouseButton = 1; -- todo: pull from configuration

	if (History == nil) then History = {} end

	local mouseEvent = "";
	local mouseCode = event[2];
	local mouseX = event[3];
	local mouseY = event[4];
	if (eventName == "monitor_touch") then
		-- good lord.
		--[[
			Find relative monitor position,
			translate the coordinates,
			determine if dragging

			also, convert the event to what is needed
		]]
	else
		mouseEvent = eventName;
	end

	-- down, up, drag, scroll
	-- print(mouseCode, mouseX, mouseY)
	local ok, err = pcall(function()
		if (mouseEvent == "mouse_down") then
			Internal.System.EventEmitter.Emit("MouseDown", mouseCode, mouseX, mouseY);
			-- CC Compatibility
			Internal.System.EventEmitter.Emit("mouse_click", mouseCode, mouseX, mouseY);
		
		elseif (mouseEvent == "mouse_up") then
			Internal.System.EventEmitter.Emit("MouseUp", mouseCode, mouseX, mouseY);
			-- CC Compatibility
			Internal.System.EventEmitter.Emit("mouse_up", mouseCode, mouseX, mouseY);
		
		elseif (mouseEvent == "mouse_drag") then
			Internal.System.EventEmitter.Emit("MouseDrag", mouseCode, mouseX, mouseY);
			-- CC Compatibility
			Internal.System.EventEmitter.Emit("mouse_drag", mouseCode, mouseX, mouseY);
		
		elseif (mouseEvent == "mouse_scroll") then
			Internal.System.EventEmitter.Emit("MouseScroll", mouseCode, mouseX, mouseY);
			-- CC Compatibility
			Internal.System.EventEmitter.Emit("mouse_scroll", mouseCode, mouseX, mouseY);
		end
	end)
end


function PointerDriver.Main()
	-- Entry point
	Internal.SysEvents.AddEventListener("mouse_down", function(...) handleEvent("mouse_down", ...) end)
	Internal.SysEvents.AddEventListener("mouse_up", function(...) handleEvent("mouse_up", ...) end)
	Internal.SysEvents.AddEventListener("mouse_drag", function(...) handleEvent("mouse_drag", ...) end)
	Internal.SysEvents.AddEventListener("mouse_scroll", function(...) handleEvent("mouse_scroll", ...) end)
	Internal.SysEvents.AddEventListener("monitor_touch", function(...) handleEvent("monitor_touch", ...) end)
end

return PointerDriver