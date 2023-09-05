local args = {...}

local varDump = fs.open("/tools/MEMDUMP", "w")

local function val_to_str(v, indent)
  local res = ""
  local indentStr = string.rep(" ", indent or 0)
  if type(v) == "string" then
    v = string.gsub(v, "\n", "\\n")
    if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
      res = "'" .. v .. "'"
    else
      res = '"' .. string.gsub(v, '"', '\\"') .. '"'
    end
  elseif type(v) == "table" then
    res = table.tostring(v, (indent or 0) + 1)
  else
    res = tostring(v)
  end
  return res
end

function table.tostring(tbl, indent)
  local result = {}
  local indentStr = string.rep(" ", (indent or 1)-1 or 0)
  local lines = 0
  for k, v in pairs(tbl) do
    if k ~= "Native" then
        local keyStr = val_to_str(k)
        local valStr = val_to_str(v, (indent or 0) + 1)
        table.insert(result, indentStr .. "[" .. keyStr .. "] = " .. valStr)
        lines = lines + 1

        if (lines>43) then
            varDump.write("\n\n--hard break on " .. k .. " inside table " .. tostring(tbl))
            break -- nah something wrong here
        end
    end
  end
  return "{\n" .. table.concat(result, ",\n") .. "\n" .. string.rep(" ", (indent or 3)-3 or 0) .. "}"
end

local tab = {}
if args[1] ~= nil then
  tab = args or {}
else
  tab = _G
end

local hits = 0
for k, v in pairs(tab) do
  if k ~= "MD" and k ~= "_ENV" and k ~= "_G" and k ~= "fs" and k ~= "utf8" and k then
    hits = hits + 1

    local t = type(v)
    local valStr = val_to_str(v)
    -- print(k)
    varDump.write("\n\nVar: \"" .. tostring(k) .. "\"\nType: \"" .. t .. "\"\nValue: " .. valStr)
    varDump.flush()
    -- print("--dumped")

    if hits > 20 then
        print("==max hits, reopening==")
        varDump.flush()
        varDump.close()
        varDump = fs.open("/tools/MEMDUMP", "a")
        hits = 0
    end

  end
end


varDump.close()