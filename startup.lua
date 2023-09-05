local args = {...}

-- We don't do much here other than start the "boot" file
--[[
	We need a few things from this file:

	1) No unsafe code.
		Under ZERO (0) circumstances can any code in this file be "broken"
		We need this file to 'contain' the user and prevent them from accessing the CraftOS shell. (no matter what)
		Therefore all code contained here MUST be safe.

	2) Capture OS level error.
		In order to prevent user escape, we need to capture any 'error()' calls from the system or attempts to break free
		So if, lets say, 'Boot.lua' or 'CodeX.lua' errors out, we want to go ahead and notify the user and shutdown the system.

		Boot.lua has its own BSOD, so we don't need to be fancy here.

		(We ARE the last BSOD)

	3) Be short and simple.
		This file needs to be light weight and simple. By keeping it simple it lowers the risk of unsafe code hiding in the program.
		(Also we're not actually doing much here, so there is NO reason this file should exceed 7kb.)

]]

local debug = true


if computer ~= nil and component ~= nil then
	Platform = 1 -- OpenComputers
	-- this is the wrong file!
	error("Unsupported platform.")
else
	Platform = 0 -- safe bet, ComputerCraft
end


local BootConfig = {
	['Platform'] = Platform,
	['LuaVersion'] = _G._VERSION,
}

if Platform == 0 then
	-- If CraftOS

	local nativeShutdown = os.shutdown
	local pullEventRaw = os.pullEventRaw
	-- os.pullEvent = os.pullEventRaw

	BootConfig.LoadFile = loadfile

	if term == nil then
		if print then
			print("boot_failed: term_nil")
			nativeShutdown();
			return;
		elseif write then
			write("boot_failed: term_nil")
			nativeShutdown();
			return;
		end
		return;
	end


	term.native().setBackgroundColor(colors.gray)
	term.native().clear()

	-- term.redirect(window.create(term.native(), 28, 9, 1, 38, true)); -- Testing


	local shutdown = os.shutdown;
	local t = term.current();
	local s = sleep;
	local str = string;
	local p = function(msg)
		local width,height = t.getSize()
		local x,y = t.getCursorPos()

		local pLine = function(str) -- Print a string, wrap text
			local x,y = t.getCursorPos()
			local x,y = x-1,y
			while true do
				if string.len(str)>width-x then
					local a, b = str:sub(1,width-x), str:sub(width-x+1,#str)
					str = b
					t.write(a)
					y=y+1
					t.setCursorPos(1,y)
				else
					s(0)
					t.write(str)
					t.setCursorPos(1,y+1)
					break
				end
			end
		end

		while true do
			if msg~=nil and msg~="" then
				local nL = msg:find("\n")
				if nL then
					pLine(msg:sub(1,nL))
					msg = msg:sub(nL+1,#msg)
				else
					pLine(msg)
					break
				end
			else
				break;
			end
			s(0)
		end 
	end

	local maxX,maxY = t.getSize()
	local header = "[!]"


	local safe,eErr = pcall(function() -- Last chance
		local ok, err = pcall(function()
			t.setBackgroundColor(colors.black)
			t.clear()
			local midX,midY = (maxX/2), maxY/2

			-- Put any code here.
			if maxX<25 or maxY<9 then
				p(header.." size required: x>25, y>9. Terminal too small to boot, must use required size.");
				-- Halt.
				s(5)
				pullEventRaw("key_up");
				shutdown();
			else
				t.setCursorPos(midX-3, midY-1)
				t.setTextColor(colors.white)
				t.write("RitoOS")
				t.setCursorPos(1,1)
			end

			BootConfig.LoadFile("/System/Boot/SecureBoot.lua")(BootConfig) -- boot
		end)

		if not ok then
			if not debug then
				t.setBackgroundColor(colors.black)
				t.clear()
				t.setCursorPos(1,1)
				local index = string.find(err,":") or 0
			end

			if t.isColor() then t.setTextColor(colors.red) else t.setTextColor(colors.white) end
			p(header.."Critical error encountered while booting.\n\nPlease inform the manufacture of this error:\n"..tostring(err or "nil"))

			if not debug then
				coroutine.yield()
				shutdown()
			end
		else
			if not debug then
				t.setBackgroundColor(colors.black)
				if not debug then t.clear() end
				if t.isColor() then t.setTextColor(colors.orange) else t.setTextColor(colors.white) end
				t.setCursorPos(1,1)
				p(header.."Completed boot sequence")
			end
			if not debug then
				s(5)
				shutdown()
			end
		end
	end)

	if not safe then
		if p then
			p("Critical system error occurred, system crashed.")
			p()
			if eErr then
				p(eErr)
			end
			p()
			p("Press any key to shutdown.")
			coroutine.yield()
			if nativeShutdown then
				nativeShutdown()
			end
			while true do p() end -- Loop
		end
		nativeShutdown()
		while true do p() end
	end
end