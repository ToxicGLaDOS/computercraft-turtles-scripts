local rectangle = require ".gps.rectangle"
require ".gps.util"

local function init_cuboid()
  if data.cuboid == nil then
    data.cuboid = {
      initial_position=copyPosition(data.position),
      initial_facing=data.facing
    }
    saveData()
    while turtle.detect() do
      turtle.dig()
    end

    -- This means the cube starts one block
    -- in front of the turtles initial position
    -- We do this so that the turtle has a clear path
    -- back to the chest to restock
    moveForward()
  end
end

local function north_or_south(direction)
  if direction == NORTH or direction == SOUTH then
    return true
  else
    return false
  end
end

local function build_rectangle(xsize, zsize)
  local success, error_message = rectangle(xsize, zsize)
  local out_of_build_item = error_message == "No build item"

  if out_of_build_item then
    local stop_position = copyPosition(data.position)
    data.cuboid.stop_position = stop_position
    -- Return home
    -- We return in this order so we don't
    -- have to break anything we put down on this layer
    if north_or_south(data.cuboid.initial_facing) then
      gotoZ(data.cuboid.initial_position.z, true)
      gotoX(data.cuboid.initial_position.x, true)
      gotoY(data.cuboid.initial_position.y, true)
    else
      gotoX(data.cuboid.initial_position.x, true)
      gotoZ(data.cuboid.initial_position.z, true)
      gotoY(data.cuboid.initial_position.y, true)
    end

    -- Fill up on build items
    faceDirection(oppositeDirection(data.cuboid.initial_facing))
    local chest = peripheral.find("inventory")
    if chest == nil then
      print(string.format("No chest in front of turtle to grab more %s.", data.rectangle.build_item))
      return false, "No chest to restock"
    end
    local chest_name = peripheral.getName(chest)


    print("Waiting for " .. data.rectangle.build_item)
    -- This outer while loop is basically a retry so we wait
    -- until we can pick up more build items
    while not findItemInInventory(data.rectangle.build_item) do
      while hasEmptySlot() and move_item_to_slot_one(chest_name, data.rectangle.build_item) do
        turtle.suck()
      end
    end

    gotoY(data.cuboid.stop_position.y, true)
    gotoX(data.cuboid.stop_position.x, true)
    gotoZ(data.cuboid.stop_position.z, true)
    data.cuboid.stop_position = nil
    saveData()

    -- Recursive call to resume building the rectangle
    -- Doing this recursively menas that we can run out of build items
    -- many times on the same rectangle and still finish
    print("Recursively calling build_rectangle")
    build_rectangle(xsize, zsize)
  end
end

local function cuboid(xsize, ysize, zsize)
  init_cuboid()

  -- If there's a stop position then we must have been trying
  -- to return home to restock on items or refuel but we don't know
  -- if we already got our items or not so we just assume we did and
  -- move back to the stop position. If this ends up not being true
  -- then we'll get an error from rectangle() anyways and run back
  -- home anyways!
  if data.cuboid.stop_position ~= nil then
    print("Returning to stop position")
    if north_or_south(data.cuboid.initial_facing) then
      gotoY(data.cuboid.stop_position.y, true)
      gotoX(data.cuboid.stop_position.x, true)
      gotoZ(data.cuboid.stop_position.z, true)
    else
      gotoY(data.cuboid.stop_position.y, true)
      gotoZ(data.cuboid.stop_position.z, true)
      gotoX(data.cuboid.stop_position.x, true)
    end

    data.cuboid.stop_position = nil
    saveData()
  end

  local num_completed_layers = data.position.y - data.cuboid.initial_position.y
  local remaining_layers = ysize - num_completed_layers

  for i=1,remaining_layers do
    build_rectangle(xsize, zsize)
    -- We don't want to move up after the last rectangle
    print(string.format("i: %s, remaining_layers: %s", i, remaining_layers))
    if i ~= remaining_layers then
      moveUp()
    end
  end
end

-- https://stackoverflow.com/questions/67579662/detect-whether-script-was-imported-or-executed-in-lua
if pcall(debug.getlocal, 4, 1) then
  -- We get here when this file is imported by another module
  -- with the require() function
  return cuboid
else
  -- We get here when this file is executed directly from the command line

  local xsize_arg, ysize_arg, zsize_arg = ...

  if xsize_arg == nil or ysize_arg == nil or zsize_arg == nil then
    error("Usage: rectangle <x> <y> <z>")
  end

  xsize_arg = tonumber(xsize_arg)
  ysize_arg = tonumber(ysize_arg)
  zsize_arg = tonumber(zsize_arg)

  init()
  success, error_message = cuboid(xsize_arg, ysize_arg, zsize_arg)
  if not success then
    print(error_message)
  else
    print("Done!")
  end
end
