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

function print(...)
	local printedLinesCount = 0
	local limit = select("#", ...)
	for n = 1, limit do
		local s = tostring(select(n, ...))
		if n < limit then
			s = s .. "\t"
		end
		printedLinesCount = (printedLinesCount or 0) + (term.write(s) or 0)
	end
	printedLinesCount = printedLinesCount + term.write("\n")
	return printedLinesCount
end


if not Internal.Debug then
	_G.colors = colors
	_G.colours = colors
	_G.write = write
	_G.print = print
end

Internal.Native.colors = copy(colors)
Internal.Native.colours = Internal.Native.colors