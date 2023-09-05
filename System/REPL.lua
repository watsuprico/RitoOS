--[[

	RitoOS Shell

]]

Session.EventEmitter.AddEventListener("logout", function()
	print("REPL::Logout->fired!")
	while true do
		term.write("m")
		sleep(0)
	end
end)

term.setCursorPos(1,1)
term.setTextColor(colors.white)
term.setBackgroundColor(colors.gray)
term.clear()
term.write("RitoOS REPL shell")

local chunkNumber = 1
local function runLuaCode(code)
	local sandbox = {}
	setmetatable(sandbox, { __index = _G })
	local chunk, err = load(code, "=lua["..chunkNumber.."]", "t", sandbox)
	if chunk then
		local success, result = pcall(chunk)
		if success then
			if result ~= nil then
				print(tostring(result))
			else
				print("\nOK.")
			end
		else
			print("\nRuntime Error: " .. tostring(result))
		end
	else
		print("\nSyntax Error: " .. tostring(err))
	end
end


local history = {}
while true do
    term.write("> ")

    local input = read(nil, {
    	["History"] = history,
    	["PredictionFunction"] = predict,
    	["PlaceHolder"] = true
    });
    if input:match("%S") and history[#history] ~= input then
        table.insert(history, input)
    end

    if not pcall(function() runLuaCode(input) end) then
    	print("Error")
    end
end