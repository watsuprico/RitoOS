--[[
    Pulled from CC-Tweaked, very slight modifications to get it working with RitoOS.
    https://github.com/cc-tweaked/CC-Tweaked/blob/mc-1.20.x/projects/core/src/main/resources/data/computercraft/lua/rom/apis/paintutils.lua

    See the following for copyright information:
]]--

-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
--
-- SPDX-License-Identifier: LicenseRef-CCPL

--- Utilities for drawing more complex graphics, such as pixels, lines and
-- images.
--
-- @module paintutils
-- @since 1.45

local paintUtils = {}

local function expect(n, have, ...)
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

local function drawPixelInternal(xPos, yPos)
    term.setCursorPos(xPos, yPos)
    term.write(" ")
end

local tColourLookup = {}
for n = 1, 16 do
    tColourLookup[string.byte("0123456789abcdef", n, n)] = 2 ^ (n - 1)
end

local function parseLine(tImageArg, sLine)
    local tLine = {}
    for x = 1, sLine:len() do
        tLine[x] = tColourLookup[string.byte(sLine, x, x)] or 0
    end
    table.insert(tImageArg, tLine)
end

-- Sorts pairs of startX/startY/endX/endY such that the start is always the min
local function sortCoords(startX, startY, endX, endY)
    local minX, maxX, minY, maxY

    if startX <= endX then
        minX, maxX = startX, endX
    else
        minX, maxX = endX, startX
    end

    if startY <= endY then
        minY, maxY = startY, endY
    else
        minY, maxY = endY, startY
    end

    return minX, maxX, minY, maxY
end

--- Parses an image from a multi-line string
--
-- @tparam string image The string containing the raw-image data.
-- @treturn table The parsed image data, suitable for use with
-- @{paintutils.drawImage}.
-- @since 1.80pr1
function paintUtils.parseImage(image)
    expect(1, image, "string")
    local tImage = {}
    for sLine in (image .. "\n"):gmatch("(.-)\n") do
        parseLine(tImage, sLine)
    end
    return tImage
end

--- Loads an image from a file.
--
-- You can create a file suitable for being loaded using the `paint` program.
--
-- @tparam string path The file to load.
--
-- @treturn table|nil The parsed image data, suitable for use with
-- @{paintutils.drawImage}, or `nil` if the file does not exist.
-- @usage Load an image and draw it.
--
--     local image = paintutils.loadImage("data/example.nfp")
--     paintutils.drawImage(image, term.getCursorPos())
function paintUtils.loadImage(path)
    expect(1, path, "string")

    if fs.exists(path) then
        local file = io.open(path, "r")
        local sContent = file:read("*a")
        file:close()
        return parseImage(sContent)
    end
    return nil
end

--- Draws a single pixel to the current term at the specified position.
--
-- Be warned, this may change the position of the cursor and the current
-- background colour. You should not expect either to be preserved.
--
-- @tparam number xPos The x position to draw at, where 1 is the far left.
-- @tparam number yPos The y position to draw at, where 1 is the very top.
-- @tparam[opt] number colour The @{colors|color} of this pixel. This will be
-- the current background colour if not specified.
function paintUtils.drawPixel(xPos, yPos, colour)
    expect(1, xPos, "number")
    expect(2, yPos, "number")
    expect(3, colour, "number", "nil")

    if colour then
        term.setBackgroundColor(colour)
    end
    return drawPixelInternal(xPos, yPos)
end

--- Draws a straight line from the start to end position.
--
-- Be warned, this may change the position of the cursor and the current
-- background colour. You should not expect either to be preserved.
--
-- @tparam number startX The starting x position of the line.
-- @tparam number startY The starting y position of the line.
-- @tparam number endX The end x position of the line.
-- @tparam number endY The end y position of the line.
-- @tparam[opt] number colour The @{colors|color} of this pixel. This will be
-- the current background colour if not specified.
-- @usage paintutils.drawLine(2, 3, 30, 7, colors.red)
function paintUtils.drawLine(startX, startY, endX, endY, colour)
    expect(1, startX, "number")
    expect(2, startY, "number")
    expect(3, endX, "number")
    expect(4, endY, "number")
    expect(5, colour, "number", "nil")

    startX = math.floor(startX)
    startY = math.floor(startY)
    endX = math.floor(endX)
    endY = math.floor(endY)

    if colour then
        term.setBackgroundColor(colour)
    end
    if startX == endX and startY == endY then
        drawPixelInternal(startX, startY)
        return
    end

    local minX = math.min(startX, endX)
    local maxX, minY, maxY
    if minX == startX then
        minY = startY
        maxX = endX
        maxY = endY
    else
        minY = endY
        maxX = startX
        maxY = startY
    end

    -- TODO: clip to screen rectangle?

    local xDiff = maxX - minX
    local yDiff = maxY - minY

    if xDiff > math.abs(yDiff) then
        local y = minY
        local dy = yDiff / xDiff
        for x = minX, maxX do
            drawPixelInternal(x, math.floor(y + 0.5))
            y = y + dy
        end
    else
        local x = minX
        local dx = xDiff / yDiff
        if maxY >= minY then
            for y = minY, maxY do
                drawPixelInternal(math.floor(x + 0.5), y)
                x = x + dx
            end
        else
            for y = minY, maxY, -1 do
                drawPixelInternal(math.floor(x + 0.5), y)
                x = x - dx
            end
        end
    end
end

--- Draws the outline of a box on the current term from the specified start
-- position to the specified end position.
--
-- Be warned, this may change the position of the cursor and the current
-- background colour. You should not expect either to be preserved.
--
-- @tparam number startX The starting x position of the line.
-- @tparam number startY The starting y position of the line.
-- @tparam number endX The end x position of the line.
-- @tparam number endY The end y position of the line.
-- @tparam[opt] number colour The @{colors|color} of this pixel. This will be
-- the current background colour if not specified.
-- @usage paintutils.drawBox(2, 3, 30, 7, colors.red)
function paintUtils.drawBox(startX, startY, endX, endY, nColour)
    expect(1, startX, "number")
    expect(2, startY, "number")
    expect(3, endX, "number")
    expect(4, endY, "number")
    expect(5, nColour, "number", "nil")

    startX = math.floor(startX)
    startY = math.floor(startY)
    endX = math.floor(endX)
    endY = math.floor(endY)

    if nColour then
        term.setBackgroundColor(nColour) -- Maintain legacy behaviour
    else
        nColour = term.getBackgroundColour()
    end
    local colourHex = colours.toBlit(nColour)

    if startX == endX and startY == endY then
        drawPixelInternal(startX, startY)
        return
    end

    local minX, maxX, minY, maxY = sortCoords(startX, startY, endX, endY)
    local width = maxX - minX + 1

    for y = minY, maxY do
        if y == minY or y == maxY then
            term.setCursorPos(minX, y)
            term.blit((" "):rep(width), colourHex:rep(width), colourHex:rep(width))
        else
            term.setCursorPos(minX, y)
            term.blit(" ", colourHex, colourHex)
            term.setCursorPos(maxX, y)
            term.blit(" ", colourHex, colourHex)
        end
    end
end

--- Draws a filled box on the current term from the specified start position to
-- the specified end position.
--
-- Be warned, this may change the position of the cursor and the current
-- background colour. You should not expect either to be preserved.
--
-- @tparam number startX The starting x position of the line.
-- @tparam number startY The starting y position of the line.
-- @tparam number endX The end x position of the line.
-- @tparam number endY The end y position of the line.
-- @tparam[opt] number colour The @{colors|color} of this pixel. This will be
-- the current background colour if not specified.
-- @usage paintutils.drawFilledBox(2, 3, 30, 7, colors.red)
function paintUtils.drawFilledBox(startX, startY, endX, endY, nColour)
    expect(1, startX, "number")
    expect(2, startY, "number")
    expect(3, endX, "number")
    expect(4, endY, "number")
    expect(5, nColour, "number", "nil")

    startX = math.floor(startX)
    startY = math.floor(startY)
    endX = math.floor(endX)
    endY = math.floor(endY)

    if nColour then
        term.setBackgroundColor(nColour) -- Maintain legacy behaviour
    else
        nColour = term.getBackgroundColour()
    end
    local colourHex = colours.toBlit(nColour)

    if startX == endX and startY == endY then
        drawPixelInternal(startX, startY)
        return
    end

    local minX, maxX, minY, maxY = sortCoords(startX, startY, endX, endY)
    local width = maxX - minX + 1

    for y = minY, maxY do
        term.setCursorPos(minX, y)
        term.blit((" "):rep(width), colourHex:rep(width), colourHex:rep(width))
    end
end

--- Draw an image loaded by @{paintutils.parseImage} or @{paintutils.loadImage}.
--
-- @tparam table image The parsed image data.
-- @tparam number xPos The x position to start drawing at.
-- @tparam number yPos The y position to start drawing at.
function paintUtils.drawImage(image, xPos, yPos)
    expect(1, image, "table")
    expect(2, xPos, "number")
    expect(3, yPos, "number")
    for y = 1, #image do
        local tLine = image[y]
        for x = 1, #tLine do
            if tLine[x] > 0 then
                term.setBackgroundColor(tLine[x])
                drawPixelInternal(x + xPos - 1, y + yPos - 1)
            end
        end
    end
end

_G.paintutils = paintUtils