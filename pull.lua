url = "http://blackolivepineapple.pizza:5001"
files = {"pull.lua", "non-gps/logging.lua", "non-gps/util.lua", "non-gps/quarry.lua", "json.lua"}

for index, file_name in pairs(files) do
	resp = http.get(string.format("%s/%s", url, file_name))
	if resp == nil then
		error("Couldn't connect to server")
	end
	h = fs.open(file_name, "w")
	h.write(resp.readAll())
	h.close()
end

