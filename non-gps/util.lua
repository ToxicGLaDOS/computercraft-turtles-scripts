local json = require ".json"

NORTH = "north"
EAST = "east"
SOUTH = "south"
WEST = "west"

write_log = false

if fs.exists("data") then
	local f = fs.open("data", "r")
	data = json.decode(f.readAll())
else
	data = {facing = "north", position = {x = 0, y = 0, z = 0}}
end

function positionEqual(p1, p2)
  if p1.x ~= p2.x then
    return false
  elseif p1.y ~= p2.y then
    return false
  elseif p1.z ~= p2.z then
    return false
  end

  return true
end

function defaultState(state)
	if data.state == nil then
		data.state = state
	end
end

function leftDirection()
  if data.facing == NORTH then
    return WEST
  elseif data.facing == EAST then
    return NORTH
  elseif data.facing == SOUTH then
    return EAST
  elseif data.facing == WEST then
    return SOUTH
  end
end

function rightDirection()
  if data.facing == NORTH then
    return EAST
  elseif data.facing == EAST then
    return SOUTH
  elseif data.facing == SOUTH then
    return WEST
  elseif data.facing == WEST then
    return NORTH
  end
end

function faceDirection(direction)
  if direction ~= NORTH and direction ~= EAST and direction ~= SOUTH and direction ~= WEST then
    error(string.format("Invalid direction, \"%s\". Expected one of %s, %s, %s, %s", direction, NORTH, EAST, SOUTH, WEST))
  end

  if data.facing ~= direction then
    if direction == leftDirection() then
      turnLeft()
    elseif direction == rightDirection() then
      turnRight()
    else
      turnRight()
      turnRight()
    end
  end
end

---Move the turtle to a certain x value.
---@param x integer The x value to go to.
---@param dig boolean Whether to dig to get to the desired position or not.
---@return boolean Whether the movement was successful.
---@return string Error message if any. Empty string if movement was successful.
function gotoX(x, dig)
  print(x, data.position.x)
  if x ~= data.position.x then
    local delta = x - data.position.x
    if delta > 0 then
      faceDirection(EAST)
    else
      faceDirection(WEST)
    end
    print(delta)
    for _ = 1,math.abs(delta) do
      if dig then
        while turtle.detect() do
          turtle.dig()
        end
      end
      local success, error_message = moveForward()
      if not success then
        return false, error_message
      end
    end
  end

  assert(data.position.x == x, string.format("gotoX failed. Turtle is at x value %s expected x value %s", data.position.x, x))
  return true, ""
end

---Move the turtle to a certain z value.
---@param z integer The z value to go to.
---@param dig boolean Whether to dig to get to the desired position or not.
---@return boolean Whether the movement was successful.
---@return string Error message if any. Empty string if movement was successful.
function gotoZ(z, dig)
  if z ~= data.position.z then
    local delta = z - data.position.z
    -- For some reason minecraft has north pointed
    -- toward negative Z and south pointed toward positive Z
    if delta > 0 then
      faceDirection(SOUTH)
    else
      faceDirection(NORTH)
    end
    for _ = 1,math.abs(delta) do
      if dig then
        while turtle.detect() do
          turtle.dig()
        end
      end
      local success, error_message = moveForward()
      if not success then
        return false, error_message
      end
    end
  end

  assert(data.position.z == z, string.format("gotoZ failed. Turtle is at z value %s expected z value %s", data.position.z, z))
  return true, ""
end


---Move the turtle to a certain y value.
---@param y integer The y value to go to.
---@param dig boolean Whether to dig to get to the desired position or not.
---@return boolean Whether the movement was successful.
---@return string Error message if any. Empty string if movement was successful.
function gotoY(y, dig)

  if y ~= data.position.y then
    local delta = y - data.position.y
    local movementFunction = nil
    local digFunction = nil
    local detectFunction = nil

    if delta > 0 then
      movementFunction = moveUp
      digFunction = turtle.digUp
      detectFunction = turtle.detectUp
    else
      movementFunction = moveDown
      digFunction = turtle.digDown
      detectFunction = turtle.detectDown
    end

    for _ = 1,math.abs(delta) do
      if dig then
        while detectFunction() do
          digFunction()
        end
      end
      local success, error_message = movementFunction()
      if not success then
        return false, error_message
      end
    end
  end

  assert(data.position.y == y, string.format("gotoY failed. Turtle is at y value %s expected y value %s", data.position.y, y))
  return true, ""
end

---Move the turtle to a certain position.
---@param position table The position value to go to.
---@param dig boolean Whether to dig to get to the desired position or not.
---@return boolean Whether the movement was successful.
---@return string Error message if any. Empty string if movement was successful.
function gotoPosition(position, dig)
  local success, error_message = gotoX(position.x, dig)
  if not success then
    return false, error_message
  end

  success, error_message = gotoZ(position.z, dig)
  if not success then
    return false, error_message
  end
  success, error_message = gotoY(position.y, dig)
  if success then
    return false, error_message
  end

  assert(positionEqual(data.position, position), string.format("gotoPosition ended at %s expected %s", data.position, position))
  return true, ""
end

function findItemInInventory(item_name)
	for i=1,16 do
		details = turtle.getItemDetail(i)
		if details ~= nil then
			if details.name == item_name then
				return true, i
			end
		end
	end

	return false, nil
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
		data.position.z = data.position.z - 1
	elseif data.facing == EAST then
		data.position.x = data.position.x + 1
	elseif data.facing == SOUTH then
		data.position.z = data.position.z + 1
	elseif data.facing == WEST then
		data.position.x = data.position.x - 1
	end
	saveData()
	return turtle.forward()
end

function moveBack()
	if data.facing == NORTH then
		data.position.z = data.position.z + 1
	elseif data.facing == EAST then
		data.position.x = data.position.x - 1
	elseif data.facing == SOUTH then
		data.position.z = data.position.z - 1
	elseif data.facing == WEST then
		data.position.x = data.position.x + 1
	end
	saveData()
	return turtle.back()
end


function moveDown()
	data.position.y = data.position.y - 1
	saveData()
	return turtle.down()
end

function moveUp()
	data.position.y = data.position.y + 1
	saveData()
	return turtle.up()
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
	turtle.turnRight()
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
	turtle.turnLeft()
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

