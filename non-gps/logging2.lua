local util = require ".non-gps.util"

local sapling_name = "minecraft:birch_sapling"
local log_name = "minecraft:birch_log"


local function init_logging()
  if data.logging == nil then
    data.logging = {
      initial_position=util.copyPosition(data.position),
      initial_facing=data.facing
    }
  end

  if data.position.x < 0 then
    local success, block = turtle.inspectDown()
    -- If the furnace is below us then we don't want to break it
    if success and block.name == "minecraft:furnace" then
      util.gotoX(data.logging.initial_position.x, true)
      util.gotoZ(data.logging.initial_position.z, true)
      util.gotoY(data.logging.initial_position.y + 1, true)
    -- Going back this way ensures we don't break the furnace
    -- unless it's right below us, which we handled in the
    -- above branch
    else
      util.gotoY(data.logging.initial_position.y + 1, true)
      util.gotoX(data.logging.initial_position.x, true)
      util.gotoZ(data.logging.initial_position.z, true)
    end
  -- The normal case where we restart during the logging
  -- process. We might be harvesting a tree though, so
  -- we want to return to the normal level.
  else
    util.gotoY(data.logging.initial_position.y + 1, true)
  end

  return true,""
end

local function logging(xsize, zsize)
  local success, error_message = init_logging()
  if not success then
    return false, error_message
  end

  -- If xsize is even then we'll be at the far end (z=zsize-1)
  -- otherwise we'll be at the close end (z=0)
  local final_z = (xsize % 2) * (-zsize + 1)
  while true do
    if data.position.x == xsize - 1 and data.position.z == final_z then
      -- Return home
      util.gotoPosition({
        x=data.logging.initial_position.x,
        y=data.logging.initial_position.y + 1,
        z=data.logging.initial_position.z
      }, true)
    -- If we're at the start with logs then we need to deposit
    elseif data.position.x == 0 and data.position.z == 0 and util.findItemInInventory(log_name) then
      util.faceDirection(util.leftDirection(data.logging.initial_facing))
      turtle.dig()
      util.moveForward()

      local slot
      -- Grab the charcoal out (if any)
      turtle.suckUp()

      turtle.dig()
      util.moveForward()
      turtle.digUp()
      util.moveUp()

      -- Face the furnace
      util.faceDirection(util.rightDirection(data.logging.initial_facing))

      -- Deposit charcoal into fuel slot
      success, slot = util.findItemInInventory("minecraft:charcoal")
      if success then
        turtle.select(slot)
        turtle.drop()
      end

      turtle.digUp()
      util.moveUp()
      turtle.dig()
      util.moveForward()

      -- Deposit logs into furnace
      success, slot = util.findItemInInventory(log_name)
      if success then
        turtle.select(slot)
        turtle.dropDown()
      end

      turtle.dig()
      util.moveForward()

      -- Refuel
      if turtle.getFuelLevel() < xsize * zsize * 3 then
        success, slot = util.findItemInInventory("minecraft:charcoal")
        if success then
          turtle.select(slot)
          turtle.refuel()
        end
      end

      -- Drop excess items into chest
      success, slot = util.findItemInInventory(sapling_name)
      util.faceDirection(util.oppositeDirection(data.logging.initial_facing))
      util.moveDown()
      for i=1,16 do
        if i ~= slot then
          turtle.select(i)
          turtle.drop()
        end
      end

      util.gotoY(data.logging.initial_position.y + 1, true)
    else
      if data.position.x % 2 == 0 then
        -- If we're at the end of the column
        -- remember minecraft has negative z for north
        if data.position.z == -zsize + 1 then
          util.faceDirection(util.rightDirection(data.logging.initial_facing))
          turtle.dig()
          util.moveForward()
          turtle.suckDown()
        else
          util.faceDirection(data.logging.initial_facing)
          turtle.dig()
          util.moveForward()
          turtle.suckDown()
        end
      else
        if data.position.z == 0 then
          util.faceDirection(util.rightDirection(data.logging.initial_facing))
          turtle.dig()
          util.moveForward()
          turtle.suckDown()
        else
          util.faceDirection(util.oppositeDirection(data.logging.initial_facing))
          turtle.dig()
          util.moveForward()
          turtle.suckDown()
        end
      end

      -- If we're under a tree then mine the whole tree
      local _, block = turtle.inspectUp()
      while block.name == log_name do
        turtle.digUp()
        util.moveUp()
        _, block = turtle.inspectUp()
      end

      util.gotoY(data.logging.initial_position.y + 1, true)

      -- Check if tree spot
      if data.position.x % 3 == 2 and data.position.z % 3 == 1 then
        local slot
        _, block = turtle.inspectDown()
        if block.name ~= sapling_name then
          turtle.digDown()
          success, slot = util.findItemInInventory(sapling_name)
          if success then
            turtle.select(slot)
            turtle.placeDown()
          end
        end
      end
    end
  end
end


-- https://stackoverflow.com/questions/67579662/detect-whether-script-was-imported-or-executed-in-lua
if pcall(debug.getlocal, 4, 1) then
  -- We get here when this file is imported by another module
  -- with the require() function
  return logging
else
  -- We get here when this file is executed directly from the command line

  local xsize_arg, zsize_arg = ...

  if xsize_arg == nil or zsize_arg == nil then
    error("Usage: logging x z")
  end

  xsize_arg = tonumber(xsize_arg)
  zsize_arg = tonumber(zsize_arg)

  success, error_message = logging(xsize_arg, zsize_arg)
  if not success then
    print(error_message)
  end
end
