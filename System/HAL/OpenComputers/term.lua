--[[

	RitoOS
		Project Hudson


	Terminal compatibility layer for OpenComptuers: provides a `term` and `color` API that is similar to ComputerCraft's
	`term` and `colors` (along with `colours`) is automatically injected in `_G` and `Internal.Native`

]]

local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object!")
end


gpu = Internal.GetDriver("Graphics").GetBootGPU()



local function checkArg(n, have, ...)
	have = type(have)
	local function check(want, ...)
		if not want then
			return false
		else
			return have == want or check(...)
		end
	end
	if not check(...) then
		local msg = string.format("bad argument #%d (%s expected, got %s)", n, table.concat({...}, " or "), have)
		error(msg, 3)
	end
end

local function RGBToHex(r, g, b)
	local function toHex(value)
		value = math.floor(value * 255 + 0.5)  -- Scale the value and round to the nearest integer
		return string.format("%02X", value)    -- Convert the value to a two-digit hexadecimal string
	end

	local red = toHex(r)
	local green = toHex(g)
	local blue = toHex(b)

	return red .. green .. blue  -- Combine the hexadecimal color components
end
local function hexToRGB(hex)
	if (type(hex) == "number") then
		hex = string.format("%X", hex)
	end
	hex = hex:gsub("#", "")  -- Remove the "#" symbol if present

	print(hex)

	-- Extract the individual color components
	local red = tonumber(hex:sub(1, 2), 16) / 255
	local green = tonumber(hex:sub(3, 4), 16) / 255
	local blue = tonumber(hex:sub(5, 6), 16) / 255

	return red, green, blue
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
	white = 0,
	orange = 1,
	magenta = 2,
	lightBlue = 3,
	yellow = 4,
	lime = 5,
	pink = 6,
	gray = 7,
	lightGray = 8,
	cyan = 9,
	purple = 10,
	blue = 11,
	brown = 12,
	green = 13,
	red = 14,
	black = 15
}

local nativePalette = copy(palette)
for name, index in pairs(colors) do
	gpu.setPaletteColor(index, palette[name])
end



-- Term
local term = {
	
}

-- Palette data
-- Get the default palette value for a color.
function term.nativePaletteColor(index)
	for i, color in pairs(nativePalette) do
		if (index == i) then
			return hexToRGB(color)
		end
	end
end

-- Get the current palette for a specific color.
function term.getPaletteColor(color)
	if (color > 16) then
		color = math.log(color, 2)
	end
	return hexToRGB(gpu.getPaletteColor(color))
end

-- Set the palette for a specific color.
function term.setPaletteColor(index, r, g, b)
	local color = r

	if (type(r) == "number" and type(g) == "number" and type(b) == "number") then
		if r < 0 then r = 0 end
		if r > 1 then r = 1 end
		if g < 0 then g = 0 end
		if g > 1 then g = 1 end
		if b < 0 then b = 0 end
		if b > 1 then b = 1 end

		color = RGBToHex(r, g, b)
	end

	gpu.setPaletteColor(index, color)
end



local cursorPosX, cursorPosY = 1, 1
-- Get the size of the terminal.
function term.getSize()
	return gpu.maxResolution()
end


-- Write text at the current cursor position, moving the cursor to the end of the text.
function term.write(text)
	gpu.set(cursorPosX, cursorPosY, text)

	local maxWidth, maxHeight = term.getSize()
	cursorPosX = cursorPosX + #text
	if (cursorPosX > maxWidth) then
		cursorPosX = 1
		cursorPosY = cursorPosY + 1
	else
		cursorPosY = cursorPosY + 1
	end

	if (cursorPosY > maxHeight) then
		term.scroll(1)
	end
end

-- Move all positions up (or down) by y pixels.
function term.scroll(y)
	local maxWidth, maxHeight = term.getSize()
	gpu.copy(1, 2, maxWidth, maxHeight - (y), 0, -y)
	gpu.fill(1, maxHeight, maxWidth, 1, " ")
end

-- Get the position of the cursor.
function term.getCursorPos()
	return cursorPosX, cursorPosY
end

-- Set the position of the cursor.
function term.setCursorPos(x, y)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	cursorPosX = x
	cursorPosY = y
end

-- Clears the terminal, filling it with the current background color.
function term.clear()
	local maxWidth, maxHeight = term.getSize()
	gpu.fill(1,1,maxWidth,maxHeight, " ")
end

-- Clears the line the cursor is currently on, filling it with the current background color.
function term.clearLine()
	local maxWidth, maxHeight = term.getSize()
	gpu.fill(1, cursorPosY, maxWidth, 1, " ")
end
-- Return the color that new text will be written as.
function term.getTextColor()
	return gpu.getForeground()
end

-- Set the color that new text will be written as.
function term.setTextColor(color)
	if (color > 16) then
		color = math.log(color, 2)
	end
	gpu.setForeground(color, true)
end

-- Return the current background color.
function term.getBackgroundColour()
	return term.getBackgroundColour()
end

-- Return the current background color.
function term.getBackgroundColor()
	return gpu.getBackground()
end

-- Set the current background color.
function term.setBackgroundColor(color)
	if (color > 16) then
		color = math.log(color, 2)
	end
	gpu.setBackground(color, true)
end

-- Determine if this terminal supports color.
function term.isColor()
	if (gpu.getDepth() > 1) then
		return true
	else
		return false
	end
end

-- Writes text to the terminal with the specific foreground and background colors.
function term.blit(text, textColor, backgroundColor)
	if text == nil then
	text = ""
	end

	local oldBackground, backgroundIsPalette = gpu.getBackground()
	local oldForeground, foregroundIsPalette = gpu.getForeground()

	local textLen = string.len(text)
	local textColorLen = string.len(textColor)
	local backgroundColorLen = string.len(backgroundColor)

	-- Iterate over each character of the text
	local textLength = #text
	for i = 1, textLength do
		local char = text:sub(i, i)
		local charTextColor = tonumber(textColor:sub(i, i), 16)
		local charBackgroundColor = tonumber(backgroundColor:sub(i, i), 16)

		gpu.setBackground(charBackgroundColor, true)
		gpu.setForeground(charTextColor, true)
		term.write(char)
	end

	gpu.setBackground(oldBackground, backgroundIsPalette)
	gpu.setForeground(oldForeground, foregroundIsPalette)
end

local currentTerminal = term
-- Redirects terminal output to a monitor, a window, or any other custom terminal object.
function term.redirect(target)
	currentTerminal = target
end

-- Returns the current terminal object of the computer.
function term.current()
	return currentTerminal
end

-- Get the native terminal object of the current computer.
function term.native()
	return copy(term)
end



-- cc with the extra 'u'

-- Get the default palette value for a color.
function term.nativePaletteColour(colour)
	return term.nativePaletteColour(colour)
end
-- Get the current palette for a specific color.
function term.getPaletteColour(colour)
	return term.getPaletteColor(colour)
end
-- Set the palette for a specific color.
function term.setPaletteColour(...)
	term.setPaletteColor(...)
end
-- Return the color that new text will be written as.
function term.getTextColour()
	return term.getTextColor()
end
-- Set the color that new text will be written as.
function term.setTextColour(colour)
	term.setTextColor(colour)
end
-- Set the current background color.
function term.setBackgroundColour(colour)
	term.setBackgroundColor(colour)
end
-- Determine if this terminal supports color.
function term.isColour()
	return term.isColor()
end
-- For compatibility
function term.getCursorBlink()
	return false
end
-- Does nothing, for compatibility
function term.setCursorBlink(blink)
end



function write(text)
	-- text = text ~= nil and text or ""
    checkArg(1, text, "string", "number")

    local maxWidth, maxHeight = term.getSize()
    local cursorPosX, cursorPosY = term.getCursorPos()

    local printedLinesCount = 0
    local function newLine()
        if cursorPosY + 1 <= maxHeight then
            term.setCursorPos(1, cursorPosY + 1)
        else
            term.setCursorPos(1, maxHeight)
            term.scroll(1)
        end
        cursorPosX, cursorPosY = term.getCursorPos()
        printedLinesCount = printedLinesCount + 1
    end

    -- Print the line with proper word wrapping
    text = tostring(text)
    while #text > 0 do
        local whitespace = string.match(text, "^[ \t]+")
        if whitespace then
            -- Print whitespace
            term.write(whitespace)
            cursorPosX, cursorPosY = term.getCursorPos()
            text = string.sub(text, #whitespace + 1)
        end

        local newline = string.match(text, "^\n")
        if newline then
            -- Print newlines
            newLine()
            text = string.sub(text, 2)
        end

        local text = string.match(text, "^[^ \t\n]+")
        if text then
            text = string.sub(text, #text + 1)
            if #text > maxWidth then
                -- Print a multiline word
                while #text > 0 do
                    if cursorPosX > maxWidth then
                        newLine()
                    end

                    term.write(text)
                    text = string.sub(text, maxWidth - cursorPosX + 2)
                    cursorPosX, cursorPosY = term.getCursorPos()
                end
            else
                -- Print a word normally
                if cursorPosX + #text - 1 > maxWidth then
                    newLine()
                end

                term.write(text)
                cursorPosX, cursorPosY = term.getCursorPos()
            end
        end
    end

    return printedLinesCount
end

function print(...)
	local printedLinesCount = 0
	local limit = select("#", ...)
	for n = 1, limit do
		local s = tostring(select(n, ...))
		if n < limit then
			s = s .. "\t"
		end
		printedLinesCount = printedLinesCount + write(s)
	end
	printedLinesCount = printedLinesCount + write("\n")
	return printedLinesCount
end

if not Internal.Debug then
	_G.term = term
	_G.colors = colors
	_G.colours = colors
	_G.write = write
	_G.print = print
end

Internal.Native.term = copy(term)
Internal.Native.colors = copy(colors)
Internal.Native.colours = Internal.Native.colors

Internal.Native.write = copy(write)
Internal.Native.print = copy(print)