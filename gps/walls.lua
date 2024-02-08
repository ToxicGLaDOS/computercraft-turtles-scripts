-- This script creates 4 walls with a given width, height, and length
--
-- This script requires that the turtle starts with the item you want to build
-- out of selected, and because it depends on the gps utils it needs a modem,
-- a compass, and a functioning gps constellation.
--
-- There are also a few optional things that the turtle will interact with if present.
-- If the turtle runs out of building materials it will return too where the script
-- was started and look for a chest behind it to get more items from.
-- When the turtle tries to get more items it also drops off non-build items
-- to the left of where the script was started. This happens whether or not
-- an inventory is present, so put a chest there if you want to keep the items
-- that the turtle digs up along the way.

local rectangle = require ".gps.rectangle"
local util = require ".gps.util"

KEEP_IN_INVENTORY = {"computercraft:wireless_modem_advanced",
  "minecraft:compass",
  "minecraft:diamond_pickaxe"
}


local function selectBuildItem()
  local selected_item = turtle.getItemDetail()

  if selected_item ~= nil then
    selected_item = selected_item.name
  end

  if selected_item ~= data.walls.build_item then
    local success, slot = util.findItemInInventory(data.walls.build_item)
    if success then
      turtle.select(slot)
    else
      return false, "No build item"
    end
  end

  return true, ""
end

local function contains(list, x)
	for _, v in ipairs(list) do
		if v == x then return true end
	end
	return false
end

local function init_walls()
  local selected_item = turtle.getItemDetail()
  if selected_item == nil then
    return false, "No build item"
  end

  if data.walls == nil then
    data.walls = {
      initial_position=copyPosition(data.position),
      initial_facing=data.facing,
      build_item = selected_item.name
    }
    util.saveData()
    while turtle.detect() do
      turtle.dig()
    end

    -- This means the cube starts one block
    -- in front of the turtles initial position
    -- We do this so that the turtle has a clear path
    -- back to the chest to restock
    util.moveForward()
  end

  return true, ""
end

local function north_or_south(direction)
  if direction == NORTH or direction == SOUTH then
    return true
  else
    return false
  end
end


local function build_rectangle(xsize, zsize)
  selectBuildItem()
  local success, error_message = rectangle(xsize, zsize)
  local out_of_build_item = error_message == "No build item"

  if out_of_build_item then
    local stop_position = util.copyPosition(data.position)
    data.walls.stop_position = stop_position
    -- Return home
    -- We return in this order so we don't
    -- have to break anything we put down on this layer
    if north_or_south(data.walls.initial_facing) then
      util.gotoZ(data.walls.initial_position.z, true)
      util.gotoX(data.walls.initial_position.x, true)
      util.gotoY(data.walls.initial_position.y, true)
    else
      util.gotoX(data.walls.initial_position.x, true)
      util.gotoZ(data.walls.initial_position.z, true)
      util.gotoY(data.walls.initial_position.y, true)
    end


    -- Drop all non build items
    util.faceDirection(util.leftDirection(data.walls.initial_facing))
    for i=1,16 do
      local item_details = turtle.getItemDetail(i)
      if item_details ~= nil and item_details.name ~= data.walls.build_item and not contains(KEEP_IN_INVENTORY, item_details.name) then
        turtle.select(i)
        turtle.drop()
      end
    end

    -- Fill up on build items
    util.faceDirection(util.oppositeDirection(data.walls.initial_facing))
    local chest = peripheral.find("inventory")
    if chest == nil then
      print(string.format("No chest in front of turtle to grab more %s.", data.walls.build_item))
      return false, "No chest to restock"
    end
    local chest_name = peripheral.getName(chest)


    print("Waiting for " .. data.walls.build_item)
    -- This outer while loop is basically a retry so we wait
    -- until we can pick up more build items
    while not util.findItemInInventory(data.walls.build_item) do
      while util.hasEmptySlot() and util.move_item_to_slot_one(chest_name, data.walls.build_item) do
        turtle.suck()
      end
    end

    util.gotoY(data.walls.stop_position.y, true)
    util.gotoX(data.walls.stop_position.x, true)
    util.gotoZ(data.walls.stop_position.z, true)
    data.walls.stop_position = nil
    util.saveData()

    -- Recursive call to resume building the rectangle
    -- Doing this recursively menas that we can run out of build items
    -- many times on the same rectangle and still finish
    print("Recursively calling build_rectangle")
    build_rectangle(xsize, zsize)
  end
end

local function walls(xsize, ysize, zsize)
  local success, error_message = init_walls()
  if not success then
    return false, error_message
  end

  -- If there's a stop position then we must have been trying
  -- to return home to restock on items or refuel but we don't know
  -- if we already got our items or not so we just assume we did and
  -- move back to the stop position. If this ends up not being true
  -- then we'll get an error from rectangle() anyways and run back
  -- home anyways!
  if data.walls.stop_position ~= nil then
    print("Returning to stop position")
    if north_or_south(data.walls.initial_facing) then
      util.gotoY(data.walls.stop_position.y, true)
      util.gotoX(data.walls.stop_position.x, true)
      util.gotoZ(data.walls.stop_position.z, true)
    else
      util.gotoY(data.walls.stop_position.y, true)
      util.gotoZ(data.walls.stop_position.z, true)
      util.gotoX(data.walls.stop_position.x, true)
    end

    data.walls.stop_position = nil
    util.saveData()
  end

  local num_completed_layers = data.position.y - data.walls.initial_position.y
  local remaining_layers = ysize - num_completed_layers

  for i=1,remaining_layers do
    build_rectangle(xsize, zsize)
    -- We don't want to move up after the last rectangle
    print(string.format("i: %s, remaining_layers: %s", i, remaining_layers))
    if i ~= remaining_layers then
      util.dig_up_all()
      util.moveUp()
    end
  end

  return true, ""
end

-- https://stackoverflow.com/questions/67579662/detect-whether-script-was-imported-or-executed-in-lua
if pcall(debug.getlocal, 4, 1) then
  -- We get here when this file is imported by another module
  -- with the require() function
  return walls
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
  success, error_message = walls(xsize_arg, ysize_arg, zsize_arg)
  if not success then
    print(error_message)
  else
    print("Done!")
  end
end
