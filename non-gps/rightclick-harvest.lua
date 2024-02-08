-- This script the turtle to start in the bottom left of your farming area

local success, util = pcall(require, ".non-gps.util")

if not success then
  local err = util
  h = fs.open("error.txt", "w")
  h.write(err)
  h.close()
  error("Failed to get utils")
end

size = 10

HARVESTING = 0
RETURNING_HOME = 1

util.defaultState(HARVESTING)

function suckallDown()
  while turtle.suckDown() do end
end

function harvesting()
  -- If we miss this timer by not calling os.pullEvent
  -- before the event fires then we'll be stuck forever
  if data.position.x == 0 and data.position.z == 0 then
    -- Items despawn after 5 minutes, but we want some padding
    -- so that we don't miss any items if this harvest takes longer
    -- than the previous one.
    os.startTimer(60 * 4.5)
  end

  if data.position.x == size - 1 then
    if size % 2 == 0 and data.position.z == 0 then
      turtle.placeDown()
      suckallDown()
      util.changeState(RETURNING_HOME)
      return
    elseif size % 2 == 1 and data.position.z == size - 1 then
      turtle.placeDown()
      suckallDown()
      util.changeState(RETURNING_HOME)
      return
    end
  end

  if data.facing == EAST then
    if data.position.x % 2 == 0 then
      if data.position.z == size - 1 then
        turtle.placeDown()
        suckallDown()
        util.moveForward()
      elseif data.position.z == 0 then
        util.turnLeft()
      end
    elseif data.position.x % 2 == 1 then
      if data.position.z == size - 1 then
        util.turnRight()
      elseif data.position.z == 0 then
        turtle.placeDown()
        suckallDown()
        util.moveForward()
      end
    end
  elseif data.facing == NORTH and data.position.z == size - 1 then
    util.turnRight()
  elseif data.facing == SOUTH and data.position.z == 0 then
    util.turnLeft()
  elseif data.facing == NORTH or data.facing == SOUTH then
    -- placeDown() is a right click, but you need to have an item
    -- in the selected slot
    turtle.placeDown()
    suckallDown()
    util.moveForward()
  end
end

function returning_home()
  if data.position.z ~= 0 then
    while data.facing ~= SOUTH do
      util.turnRight()
    end
    util.moveForward()
  elseif data.position.x ~= 0 then
    while data.facing ~= WEST do
      util.turnRight()
    end
    util.moveForward()
  else
    while data.facing ~= WEST do
      util.turnLeft()
    end

    -- Drop everything but the first item
    for i=2,16 do
      turtle.select(i)
      turtle.drop()
    end

    if turtle.getFuelLevel() < size * size * 3 then
      util.turnLeft()
      turtle.suck()
      for i=2,16 do
        turtle.select(i)
        turtle.refuel()
      end
      util.turnRight()
    end

    util.turnRight()

    util.changeState(HARVESTING)

    local tiles = size * size
    local time_per_tile = 0.6
    local item_despawn = 60 * 5
    -- We want to sleep as long as possible but not
    -- let the items despawn. The bigger the plot, the more time
    -- it takes to harvest everything, so the less we have to sleep
    local sleep_time = item_despawn - tiles * time_per_tile
    if sleep_time < 0 then
      sleep_time = 0
    end

    print("Waiting for timer to expire")
    os.pullEvent("timer")
    --print(string.format("Sleeping for %s seconds", sleep_time))
    --os.sleep(sleep_time)
  end
end

while true do
  turtle.select(1)
  if turtle.getItemCount(turtle.getSelectedSlot()) == 0 then
    print("Item required in slot 1")
  elseif data.state == HARVESTING then
    harvesting()
  elseif data.state == RETURNING_HOME then
    returning_home()
  else
    print(string.format("Invalid state %s", data.state))
  end
end

