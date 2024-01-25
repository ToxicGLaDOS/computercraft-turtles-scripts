local json = require "json"

write_log = false

if fs.exists("data") then
	local f = fs.open("data", "r")
	data = json.decode(f.readAll())
else
	data = {facing = 0, position = {x = 0, y = 0, z = 0}}
end

function defaultState(state)
	if data.state == nil then
		data.state = state
	end
end

function findItemInInventory(item_name)
	for i=1,16 do
		details = turtle.getItemDetail(i)
		if details ~= nil then
			if details.name == item_name then
				return i
			end
		end
	end

	return 0
end

function find_biggest_item_stack(item_name)
	max = 0
	slot = 0
	for i=1,16 do
		details = turtle.getItemDetail(i)
		count = turtle.getItemCount(i)
		if details ~= nil and details.name == item_name and count > max then
			max = count
			slot = i
		end
	end

	return slot
end


function saveData()
	local f = fs.open("data", "w")
	f.write(json.encode(data))
	f.close()
end

function moveForward()
	if data.facing == NORTH then
		data.position.z = data.position.z + 1
	elseif data.facing == EAST then
		data.position.x = data.position.x + 1
	elseif data.facing == SOUTH then
		data.position.z = data.position.z - 1
	elseif data.facing == WEST then
		data.position.x = data.position.x - 1
	end
	saveData()
	writeLog("Moving forward")
	turtle.forward()
	writeLog("Moved forward")	
end

function moveBack()
	if data.facing == NORTH then
		data.position.z = data.position.z - 1
	elseif data.facing == EAST then
		data.position.x = data.position.x - 1
	elseif data.facing == SOUTH then
		data.position.z = data.position.z + 1
	elseif data.facing == WEST then
		data.position.x = data.position.x + 1
	end
	saveData()
	writeLog("Moving backward")
	turtle.back()
	writeLog("Moved backward")	
end


function moveDown()
	data.position.y = data.position.y - 1
	saveData()
	writeLog("Moving down")
	turtle.down()
	writeLog("Moved down")
end

function moveUp()
	data.position.y = data.position.y + 1
	saveData()
	writeLog("Moving up")
	turtle.up()
	writeLog("Moved up")
end


function turnRight()
	if data.facing == NORTH then
		data.facing = EAST
	elseif data.facing == EAST then
		data.facing = SOUTH
	elseif data.facing == SOUTH then
		data.facing = WEST
	elseif data.facing == WEST then
		data.facing = NORTH
	end
	saveData()
	writeLog("Turning right")
	turtle.turnRight()
	writeLog("Turned right")
end


function turnLeft()
	if data.facing == NORTH then
		data.facing = WEST
	elseif data.facing == EAST then
		data.facing = NORTH
	elseif data.facing == SOUTH then
		data.facing = EAST
	elseif data.facing == WEST then
		data.facing = SOUTH
	end
	saveData()
	writeLog("Turning left")
	turtle.turnLeft()
	writeLog("Turned left")
end

function findNonfullStack(item)
	for i=1,16 do
		detail = turtle.getItemDetail(i)
		if detail ~= nil and detail.name == item then
			remaining_space = turtle.getItemSpace(i)
			if remaining_space > 0 then
				return i
			end
		end
	end

	return 0
end

function needsConsolidation(item)
	non_full_stack_found = 0
	for i=1,16 do
		detail = turtle.getItemDetail(i)
		if detail ~= nil and detail.name == item then
			space_remaining = turtle.getItemSpace(i)
			if space_remaining > 0 then
				if not non_full_stack_found then
					non_full_stack_found = i
				else
					return true, non_full_stack_found, i
				end
			end
		end
	end

	return false, 0, 0
end

function findConsolidatabileSlotsWithItem(item)
	slots = {}
	for i=1,16 do
		detail = turtle.getItemDetail(i)
		remaining_space = turtle.getItemSpace(i)
		if detail.name == item and remaining_space > 0 then
			table.insert(slots, i)
		end
	end

	return slots
end

function consolidateInventory()
	items = {}
	for i=1,16 do
		detail = turtle.getItemDetail(i)
		if detail ~= nil then
			-- Just set the value to something so we can check for it's existence
			items[detail.name] = true
		end
	end

	for item_name, _ in pairs(items) do
		success, into_stack, other_stack = needsConsolidation(item_name)
		if success then
			turtle.select(other_stack)
			turtle.transferTo(into_stack)
		end
	end

	first_spot = {}
	for i=1,16 do
		detail = turtle.getItemDetail(i)
		if detail ~= nil then
			if first_spot[i] == nil then
				first_spot[detail.name] = i
			else
				turtle.select(i)
				-- Fails if it couldn't move _ALL_ items
				success = turtle.transferTo(first_spot[detail.name])
			end
		end
	end
end

function changeState(new_state)
	writeLog(string.format("Changing state to %s", new_state))
	data.state = new_state
	saveData()
	writeLog(string.format("Changed state to %s", new_state))
end

function writeLog(message)
	if write_log == true then
		local h = fs.open("log", "a")
		h.writeLine(message)
		h.close()
	else
		print(message)
	end
end

function hasEmptySlot()
	for i=1,16 do
		local amount = turtle.getItemCount(i)
		if amount == 0 then
			return true
    end		
	end

	return false
end

