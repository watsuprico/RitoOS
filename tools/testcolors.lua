--test colors
while true do
for k in pairs(colors) do
	if type(colors[k]) == "number" then
		term.setBackgroundColor(colors[k])
		term.clear()
		term.setCursorPos(1, 1)
		term.write(k .. ": " .. tostring(colors[k]))
		-- System.EventEmitter.Pull("keydown")
		sleep(1)
		term.write("TICK")
	end
end
end
term.setBackgroundColor(colors.black)
term.setCursorPos(1, 1)
term.write("done")