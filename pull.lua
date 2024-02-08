url = "http://blackolivepineapple.pizza:5002"
files = {"pull.lua", "non-gps/logging.lua", "non-gps/util.lua", "non-gps/quarry.lua", "non-gps/rightclick-harvest.lua", "json.lua", "gps/util.lua", "gps/rectangle.lua", "gps/walls.lua", "gps/line.lua", "non-gps/logging2.lua"}

for index, file_name in pairs(files) do
	resp = http.get(string.format("%s/%s", url, file_name))
	if resp == nil then
		error("Couldn't connect to server")
	end
	h = fs.open(file_name, "w")
	h.write(resp.readAll())
	h.close()
end

