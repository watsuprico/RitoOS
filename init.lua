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
else
  Platform = 0 -- safe bet, ComputerCraft
  error("Unsupported platform.")
end


local BootConfig = {
  ['Platform'] = Platform,
  ['LuaVersion'] = _G._VERSION,
}

if Platform == 1 then
  -- open computers

  local gpu = component.list("gpu")()
  local screen = component.list("screen")()


  function clearScreen()
    local gpu = component.list("gpu")()
    if gpu then
      gpu = component.proxy(gpu)
      local w, h = gpu.getResolution()
      gpu.fill(1, 1, w, h, " ")
    end
  end

  local function tableToString(tbl)
    local result = "{"
    local isFirst = true

    for k, v in pairs(tbl) do
      if not isFirst then
        result = result .. ", "
      end

      if type(k) == "number" then
        result = result .. "[" .. k .. "]"
      else
        result = result .. k
      end

      result = result .. " = "

      if type(v) == "table" then
        result = result .. tableToString(v)
      else
        result = result .. tostring(v)
      end

      isFirst = false
    end

    result = result .. "}"
    return result
  end

  local cx, cy = 1, 1
  function writeOutput(text)
    if (text == nil) then
      text = "\n"
    end
    if (type(text) == "table") then
      text = tableToString(text)
    end
    text = tostring(text)
    local gpu = component.list("gpu")()
    if gpu then
      gpu = component.proxy(gpu)
      local w, h = gpu.getResolution()

      if text == "\n" then
        cx = 1
        cy = cy + 1
      end

      local lines = {}
      for line in text:gmatch("[^\n]*") do
        table.insert(lines, line)
      end
      for _, line in ipairs(lines) do
        for char in line:gmatch(".") do
          if cx > w then
            cx = 1
            cy = cy + 1
          elseif cy > h then
            gpu.copy(1, 2, w, h - 1, 0, -1)
            gpu.fill(1, h, w, 1, " ")
            cy = h
          end

          gpu.set(cx, cy, char)
          cx = cx + 1
        end
        if _ < #lines-1 then
          cx = 1
          cy = cy + 1
        end
      end
    end
  end
  function p(text)
    writeOutput(text)
  end

  function readInput()
    local line = ""
    while true do
      local event, idk, key = coroutine.yield()
      if event == "key_up" then
        if key == 13 then
          break
        end
        if (key>31 and key < 127) then          
          line = line .. string.char(key)
          writeOutput(string.char(key))
        elseif (key == 8) then
          if (#line > 0) then
            line = string.sub(line, 0, #line-1)
            cx = cx - 1
            gpu.set(cx, cy, " ")
          end
        end
      end
    end
    writeOutput()
    return line
  end
  read = readInput -- eh

  local function runLuaCode(code)
    if (code == "r") then
      computer.shutdown(true)
    end
    local sandbox = {}
    setmetatable(sandbox, { __index = _G })
    local chunk, err = load(code, "LUA-CODE", "t", sandbox)
    if chunk then
      local success, result = pcall(chunk)
      if success then
        if result ~= nil then
          writeOutput(tostring(result))
        else
          writeOutput("\nOK.")
        end
      else
        writeOutput("\nRuntime Error: " .. tostring(result))
      end
    else
      writeOutput("\nSyntax Error: " .. tostring(err))
    end
  end


  if gpu and screen then
    gpu = component.proxy(gpu)
    gpu.bind(screen)
    -- gpu.setResolution(25, 10)
    gpu.fill(1, 1, 80, 25, " ")

    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.set(37, 11, "RitoOS")
    gpu.setForeground(0x555555)
    gpu.set(33, 13, "Project Hudson")
    gpu.setForeground(0xFFFFFF)

    local loadfile = load([[return function(file)
      local pc,cp = computer or package.loaded.computer, component or package.loaded.component
      local addr, invoke = pc.getBootAddress(), cp.invoke
      local handle, reason = invoke(addr, "open", file)
      assert(handle, reason)
      local buffer = ""
      repeat
        local data, reason = invoke(addr, "read", handle, math.huge)
        assert(data or not reason, reason)
        buffer = buffer .. (data or "")
      until not data
      invoke(addr, "close", handle)
      return load(buffer, "=" .. file, "bt", _G)
    end]], "=loadfile", "bt", _G)()
    BootConfig.LoadFile = loadfile
    local ok, err = pcall(function() loadfile("/System/Boot/SecureBoot.lua")(BootConfig) end)
    for i=1,10 do computer.beep(500-(i*15), 0) end
    if not ok then
      if err ~= nil then
        writeOutput("\nRuntime Error: ")
        writeOutput(err)
      else
        writeOutput("\nFailed to boot!")
      end
    else
      writeOutput("\nEND OF BOOT!")
    end


    writeOutput("\nPress any key.")
    while true do
      local event, _, _, _, _, key = computer.pullSignal()
      if event == "key_down" then
        break
      end
    end
  else
    error("GPU or screen component not found!")
  end

  -- gpu.fill(1, 1, 80, 25, " ") -- Clear the screen before exiting
  gpu.setForeground(0xffffff)




  -- clearScreen()
  writeOutput("\n\n--REPL mode--\n")

  while true do
    writeOutput("> ")
    local input = readInput()
    runLuaCode(input)
    writeOutput("\n")
  end
end