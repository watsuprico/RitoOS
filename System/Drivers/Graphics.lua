--[[

	RitoOS
		Graphics driver

]]

local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object!")
end
-- Is OpenComputer?
local oc = Internal.Platform == "oc" and true or false

local Graphics = {}
local GraphicsDisplay = {}
GraphicsDisplay.__index = GraphicsDisplay

local function checkArg(n, have, ...)
	have = Internal.Native.type(have)
	local function check(want, ...)
		if not want then
			return false
		else
			return have == want or check(...)
		end
	end
	if not check(...) then
		local msg = Internal.Native.string.format("bad argument #%d (%s expected, got %s)", n, table.concat({...}, " or "), have)
		Internal.Native.error(msg, 3)
	end
end



local palette = { -- mapping
	white = 0xF0F0F0,
	orange = 0xF2B233,
	magenta = 0xE57FD8,
	lightBlue = 0x99B2F2,
	yellow = 0xDEDE6C,
	lime = 0x7FCC19,
	pink = 0xF2B2CC,
	gray = 0x4C4C4C,
	lightGray = 0x999999,
	cyan = 0x4C99B2,
	purple = 0xB266E5,
	blue = 0x3366CC,
	brown = 0x7F664C,
	green = 0x57A64E,
	red = 0xCC4C4C,
	black = 0x111111
}

-- Color API
local colors = {
	white = 1,
	orange = 2,
	magenta = 4,
	lightBlue = 8,
	yellow = 16,
	lime = 32,
	pink = 64,
	gray = 128,
	lightGray = 256,
	cyan = 512,
	purple = 1024,
	blue = 2048,
	brown = 4096,
	green = 8192,
	red = 16384,
	black = 32768
}
local nativePalette = copy(palette)


local gpu = {}
if oc then
	-- This resets the primary screen
	local screen = Internal.Native.component.list('screen', true)()
	for address in Internal.Native.component.list('screen', true) do
		if #Internal.Native.component.invoke(address, 'getKeyboards') > 0 then -- set to screen with keyboard
			screen = address
			break
		end
	end
	Internal.BootConfig.BootScreen = screen
	gpu = Internal.Native.component.list("gpu", true)()
	if gpu and screen then
		gpu = Internal.Native.component.proxy(gpu)
		gpu.bind(screen)
		-- w, h = gpu.maxResolution()
		-- gpu.setResolution(w, h)
		-- gpu.setBackground(0x111111)
		-- gpu.setForeground(0xBFBFBF)
		-- gpu.fill(1, 1, w, h, " ")

		if (gpu.maxDepth() >= 4) then
			gpu.setDepth(4) -- 16 colors (ComputerCraft compatibility)
		end
	end
else
	gpu = term.native()
end


-- Static methods
function Graphics.GetPrimaryDisplay()
	return gpu
end

function Graphics.RGBToHex(r, g, b)
	local function toHex(value)
		value = math.floor(value * 255 + 0.5)  -- Scale the value and round to the nearest integer
		return string.format("%02X", value)    -- Convert the value to a two-digit hexadecimal string
	end

	local red = toHex(r)
	local green = toHex(g)
	local blue = toHex(b)

	return red .. green .. blue  -- Combine the hexadecimal color components
end
function Graphics.HexToRGB(hex)
	if (type(hex) == "number") then
		hex = string.format("%X", hex)
	end
	hex = hex:gsub("#", "")  -- Remove the "#" symbol if present

	-- Extract the individual color components
	local red = tonumber(hex:sub(1, 2), 16) / 255
	local green = tonumber(hex:sub(3, 4), 16) / 255
	local blue = tonumber(hex:sub(5, 6), 16) / 255

	return red, green, blue
end




-- set the palette
if (oc) then
	for name, index in pairs(colors) do
		gpu.setPaletteColor(math.log(index,2), palette[name])
	end
else
	for name, index in pairs(colors) do
		gpu.setPaletteColor(index, palette[name])
	end
end


-- "Class"

--[[
	Initializes a new "graphics" display
	@param {gpu} screen - GPU object to output to.
	@return {Graphics}
]]
function Graphics.New(screen)
	local self = Internal.Native.setmetatable({}, GraphicsDisplay)
	self.GPU = screen
	self.Cursor = {["X"] = 0, ["Y"] = 0}

	return self
end

function GraphicsDisplay:GetNativeAPI()
	return self.GPU
end





-- Modifying colors (on screen)

-- Palette data
-- Get the default palette value for a color.
function GraphicsDisplay:GetNativePaletteColor(color)
	checkArg(1, color, "number")
	for i, color in pairs(nativePalette) do
		if (color == i) then
			return hexToRGB(color)
		end
	end
end

-- Get the current palette for a specific color.
function GraphicsDisplay:GetPaletteColor(color)
	checkArg(1, color, "number")
	if (color > 16) then
		color = math.log(color, 2)
	end
	if (oc) then
		return hexToRGB(self.GPU.getPaletteColor(color))
	else
		return self.GPU.getPaletteColor(color)
	end
end

-- color is the index, r can be red (0-1) or a hex color, g and b are green/blue (0-1).
function GraphicsDisplay:SetPaletteColor(color, r, g, b)
	checkArg(1, color, "number")
	if (oc) then
		if (type(r) == "number" and type(g) == "number" and type(b) == "number") then
			if r < 0 then r = 0 end
			if r > 1 then r = 1 end
			if g < 0 then g = 0 end
			if g > 1 then g = 1 end
			if b < 0 then b = 0 end
			if b > 1 then b = 1 end

			r = RGBToHex(r, g, b)
		end
		self.GPU.setPaletteColor(color, r)
	else
		if (type(r) == "string") then
			r, g, b = HexToRGB()
		end
		self.GPU.setPaletteColor(color, r, g, b)
	end
end

function GraphicsDisplay:IsColor()
	if (oc) then
		return self.GPU.getDepth() > 1
	else
		return self.GPU.isColor()
	end
end


function GraphicsDisplay:SetTextColor(color)
	checkArg(1, color, "number")
	if (color > 16) then
		color = math.log(color, 2)
	end
	if (oc) then
		self.GPU.setForeground(color, true)
	else
		self.GPU.setTextColor(color)
	end
end

function GraphicsDisplay:GetTextColor()
	if (oc) then
		return self.GPU.getForeground()
	else
		return self.GPU.getTextColor()
	end
end

function GraphicsDisplay:SetBackgroundColor(color)
	checkArg(1, color, "number")
	if (oc) then
		if (color > 16) then
			color = math.log(color, 2)
		end
		self.GPU.setBackground(color, true)
	else
		self.GPU.setBackgroundColor(color)
	end
end

function GraphicsDisplay:GetBackgroundColor()
	if (oc) then
		return self.GPU.getBackground()
	else
		return self.GPU.getBackgroundColor()
	end
end


-- Manipulation
function GraphicsDisplay:Clear()
	if (oc) then
		local maxWidth, maxHeight = self:GetSize()
		self.GPU.fill(1,1, maxWidth, maxHeight, " ")
	else
		self.GPU.clear()
	end
end

function GraphicsDisplay:ClearLine()
	if (oc) then
		local maxWidth, maxHeight = self:GetSize()
		self.GPU.fill(1, self.Cursor.Y, maxWidth, 1, " ")
	else
		self.GPU.clearLine()
	end
end



-- Cursor/Size

function GraphicsDisplay:GetSize()
	if (oc) then
		return self.GPU.getResolution()
	else
		return self.GPU.getSize()
	end
end

-- Cursor

function GraphicsDisplay:GetCursorPos()
	if (oc) then
		return self.Cursor.X, self.Cursor.Y
	end
	return self.GPU.getCursorPos()
end

function GraphicsDisplay:SetCursorPos(x, y)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	self.Cursor = {["X"] = x, ["Y"] = y}
	if (not oc) then
		self.GPU.setCursorPos(x,y)
	end
end

-- Scroll the display up (+) or down (-)
function GraphicsDisplay:Scroll(y)
	checkArg(1, y, "number")
	if (oc) then
		local maxWidth, maxHeight = self.GPU.getResolution()
		self.GPU.copy(1, 2, maxWidth, maxHeight - (y), 0, -y)
		self.GPU.fill(1, maxHeight, maxWidth, 1, " ")
	else
		self.GPU.scroll(y)
	end
end


-- Text
function GraphicsDisplay:Blit(text, textColor, backgroundColor)
	if (oc) then
		local oldBackgroundColor, backgroundIsPalette = self.GPU.getBackground()
		local oldForegroundColor, foregroundIsPalette = self.GPU.getForeground()
		self:Write(text)
		self.GPU.setBackground(oldBackgroundColor, backgroundIsPalette)
		self.GPU.setForeground(oldForegroundColor, foregroundIsPalette)
	else
		self.GPU.blit(text, textColor, backgroundColor)
	end
end

function GraphicsDisplay:Write(text, x, y)
	checkArg(1, text, "string")
	checkArg(2, x, "nil", "number")
	checkArg(3, y, "nil", "number")

	local maxWidth, maxHeight = self:GetSize()
	local newX = math.min(maxWidth, (x or self.Cursor.X)+#text)

	if (oc) then
		self.GPU.set(x or self.Cursor.X, y or self.Cursor.Y, text)
		self.Cursor.X = newX
	else
		local oldX, oldY = 0,0
		if (type(x) == "number" and type(y) == "number") then
			oldX, oldY = self:GetCursorPos()
			self:SetCursorPos(x, y)
		end
		
		self.GPU.write(text)

		if (type(x) == "number" and type(y) == "number") then
			self:SetCursorPos(newX, oldY)
		end
	end
end



-- Higher level

function GraphicsDisplay:WriteText(text, wrap)
	checkArg(1, text, "string", "number")
	text = Internal.Native.tostring(text)

	local maxWidth, maxHeight = self:GetSize()
	local cursorX, cursorY = self:GetCursorPos()

	local function pushLine(str)
		if (oc) then
			self.GPU.set(cursorX, cursorY, str)
			return;
		else
			self.GPU.write(str)
			return;
		end
	end


	if (not wrap) then
		pushLine(text)
	else
		-- word wrap
		local lines = {}

		for i = 1, #text do
			local char = text:sub(i,i)
			local currentLine = lines[linesPrinted]
			local newLine = (char == "\\" and (#text>=i+1 and text:sub(i+1,i+1) == "n")) -- new line
			if (#currentLine >= maxWidth) or newLine then
				-- wrap/new line
				linesPrinted = linesPrinted + 1;
				i = i + 1 -- skip that n
			else
				lines[linesPrinted] = currentLine .. char
			end
		end

		local startingIndex = 0
		if (#lines > maxHeight) then
			startingIndex = maxHeight-#lines -- don't waste time scrolling!
			cursorY = 1
		end

		-- we have our lines, push them out
		for i = startingIndex, #lines do
			if (oc) then
				self.GPU.set(cursorX, cursorY, lines[i])
			else
				self:SetCursorPos(cursorX, cursorY)
				self.GPU.write(lines[i])
			end

			if (i ~= #lines) then
				cursorX = 1
				cursorY = cursorY + 1
			else
				cursorX = #lines[i]
			end
		end
	end
end


function Graphics.GetPrimaryDisplayInstance()
	return Graphics.New(Graphics.GetPrimaryDisplay())
end


function Graphics.Main()
	-- driver entry point
end

return Graphics