--test colors
for k in pairs(colors) do
	if type(colors[k]) == "number" then
		term.setBackgroundColor(colors[k])
		term.clear()
		print(k)
		os.pullEvent("key")
	end
end
term.setBackgroundColor(colors.black)
print("Done")