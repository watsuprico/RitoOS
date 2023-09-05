--[[

	RitoOS


	OpenComputer graphics driver

]]

local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object!")
end
if Internal.Platform ~= "oc" then
	error("Unsupported platform.")
end


local screen = Internal.Native.component.list('screen', true)()
for address in Internal.Native.component.list('screen', true) do
	if #Internal.Native.component.invoke(address, 'getKeyboards') > 0 then
		screen = address
		break
	end
end
Internal.BootConfig.BootScreen = screen
gpu = Internal.Native.component.list("gpu", true)()
if gpu and screen then
	gpu = Internal.Native.component.proxy(gpu)
	gpu.bind(screen)
	w, h = gpu.maxResolution()
	gpu.setResolution(w, h)
	gpu.setBackground(0x000000)
	gpu.setForeground(0xFFFFFF) -- you MUST set this!
	-- gpu.fill(1, 1, w, h, " ")

	if (gpu.maxDepth() >= 4) then
		gpu.setDepth(4) -- 16 colors (ComputerCraft compatibility)
	end
end


local Graphics = {}

function Graphics.GetBootGPU()
	return gpu
end

function Graphics.Test()
	term.write("---Testing---")
end


return Graphics