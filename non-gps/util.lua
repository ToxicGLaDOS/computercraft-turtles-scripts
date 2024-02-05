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

-- Taken from fatboychummy: https://github.com/cc-tweaked/CC-Tweaked/discussions/1552#discussioncomment-6664168
--- Find an item in a chest, given the chest's position and item name.
---@param item_list itemList The list of items in the chest.
---@param item_name string The name of the item to find.
---@return integer? The slot number of the item, or nil if not found.
local function find_item(item_list, item_name)
  for slot, item in pairs(item_list) do
    if item.name == item_name then
      return slot
    end
  end
  return nil
end

--- Find the first empty slot in a chest.
---@param item_list itemList The list of items in the chest.
---@param size integer The size of the chest.
---@return integer? slot The slot number of the first empty slot, or nil if none are empty.
local function find_empty_slot(item_list, size)
  for slot = 1, size do
    if not item_list[slot] then
      return slot
    end
  end
  return nil
end

--- Move an item from one slot to another in a given inventory.
---@param inventory_name string The name of the inventory to move items in.
---@param from_slot integer The slot to move from.
---@param to_slot integer The slot to move to.
local function move_item_stack(inventory_name, from_slot, to_slot)
  return peripheral.call(inventory_name, "pushItems", inventory_name, from_slot, nil, to_slot)
end

--- Move a specific item to slot one, moving other items out of the way if needed.
---@param chest_name string The name of the chest to search.
---@param item_name string The name of the item to find.
---@return boolean success Whether or not the item was successfully moved to slot one (or already existed there)
function move_item_to_slot_one(chest_name, item_name)
  local list = peripheral.call(chest_name, "list")
  local size = peripheral.call(chest_name, "size")
  local slot = find_item(list, item_name)

  -- If the item didn't exist, or is already in the first slot, we're done.
  if not slot then
    return false
  end
  if slot == 1 then
    return true
  end

  -- If an item is blocking the first slot (we already know it's not the one we want), we need to move it.
  if list[1] then
    local empty_slot = find_empty_slot(list, size)

    -- If there are no empty slots, we can't move the item.
    if not empty_slot then
      printError("No empty slots")
      return false
    end

    -- Move the item to the first empty slot.
    if not move_item_stack(chest_name, 1, empty_slot) then
      printError("Failed to move item to slot " .. empty_slot)
      return false
    end
  end

  -- Move the item to slot 1.
  if not move_item_stack(chest_name, slot, 1) then
    printError("Failed to move item to slot 1")
    return false
  end

  return true
end

function copyPosition(position)
	return {x=position.x, y=position.y, z=position.z}
end

function subtractPosition(p1, p2)
  return {x=p1.x-p2.x, y=p1.y-p2.y, z=p1.z-p2.z}
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

function oppositeDirection(direction)
  if direction == NORTH then
    return SOUTH
  elseif direction == EAST then
    return WEST
  elseif direction == SOUTH then
    return NORTH
  elseif direction == WEST then
    return EAST
  end
end

function leftDirection(direction)
  if direction == NORTH then
    return WEST
  elseif direction == EAST then
    return NORTH
  elseif direction == SOUTH then
    return EAST
  elseif direction == WEST then
    return SOUTH
  end
end

function rightDirection(direction)
  if direction == NORTH then
    return EAST
  elseif direction == EAST then
    return SOUTH
  elseif direction == SOUTH then
    return WEST
  elseif direction == WEST then
    return NORTH
  end
end

---Rotates a vector 90 degrees clockwise ignoring the y value
---@param vector table
function rotateVector90Clockwise(vector)
  -- This looks weird, but I'm pretty sure it's correct
  -- Remeber that north in minecraft is negative Z.
  -- {0,  0, -1} -> {1,  0,  0} north becomes east
  -- {1,  0,  0} -> {0,  0,  1} east becomes south
  -- {0,  0,  1} -> {-1, 0,  0} south becomes west
  -- {-1, 0,  0} -> {0,  0, -1} west becomes north
  return {x=-vector.z, y=vector.y, z=vector.x}
end

---Changes the frame of reference of a vector to be north
-- This is useful if a vector was calculated using relative
-- directions, but you want to put it into global directions.
-- For instance, if you are facing east and move forward
-- 10 blocks you've moved by {0, 0, -10} (remember minecraft has negative Z pointing north)
-- but if you want to know how much you've moved in the global coordinates
-- you need to rotate the vector from relative to east, to relative to north.
-- In this case you've moved {10, 0, 0} in the world coordinates
---@param vector any
---@param reference any
---@return any
function changeVectorReferenceToNorth(vector, reference)
  if reference == NORTH then
    return vector
  elseif reference == EAST then
    return rotateVector90Clockwise(vector)
  elseif reference == SOUTH then
    return rotateVector90Clockwise(rotateVector90Clockwise(vector))
  elseif reference == WEST then
    return rotateVector90Clockwise(rotateVector90Clockwise(rotateVector90Clockwise(vector)))
  end
end

function changeVectorReferenceFromNorth(vector, reference)
  if reference == NORTH then
    return vector
  elseif reference == EAST then
    return rotateVector90Clockwise(rotateVector90Clockwise(rotateVector90Clockwise(vector)))
  elseif reference == SOUTH then
    return rotateVector90Clockwise(rotateVector90Clockwise(vector))
  elseif reference == WEST then
    return rotateVector90Clockwise(vector)
  end
end

function faceDirection(direction)
  if direction ~= NORTH and direction ~= EAST and direction ~= SOUTH and direction ~= WEST then
    error(string.format("Invalid direction, \"%s\". Expected one of %s, %s, %s, %s", direction, NORTH, EAST, SOUTH, WEST))
  end

  if data.facing ~= direction then
    if direction == leftDirection(data.facing) then
      turnLeft()
    elseif direction == rightDirection(data.facing) then
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
  if x ~= data.position.x then
    local delta = x - data.position.x
    if delta > 0 then
      faceDirection(EAST)
    else
      faceDirection(WEST)
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

---Get the item slot for a given item in turtle inventory
---@param item_name string
---@return boolean success Whether the item was found in the turtle's inventory.
---@return integer|nil slot The slot of the item if found.
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

