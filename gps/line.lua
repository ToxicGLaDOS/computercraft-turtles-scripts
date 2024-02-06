require ".gps.util"

local function init_line()
  if data.line == nil then
    local selected_item = turtle.getItemDetail()
    if selected_item == nil then
      return false, "No build item"
    end

    data.line = {
      initial_position = copyPosition(data.position),
      initial_facing = data.facing,
      build_item = selected_item.name
    }

    saveData()
  end

  return true, ""
end

local function selectBuildItem()
  local selected_item = turtle.getItemDetail()

  if selected_item ~= nil then
    selected_item = selected_item.name
  end

  if selected_item ~= data.line.build_item then
    local success, slot = findItemInInventory(data.line.build_item)
    if success then
      turtle.select(slot)
    else
      return false, "No build item"
    end
  end

  return true, ""
end

local function line(length)
  if data.line == nil then
    local success, error_message = init_line()
    if not success then
      return false, error_message
    end
  else
    -- How much we've moved since we started
    local positionDelta = subtractPosition(data.position, data.line.initial_position)
    if data.line.initial_facing == EAST or data.line.initial_facing == WEST then
      length = length - math.abs(positionDelta.x)
    else
      length = length - math.abs(positionDelta.z)
    end
  end

  for i=1,length do
    local success, error_message = selectBuildItem()
    if not success then
      return false, error_message
    end
    turtle.digDown()
    success, error_message = turtle.placeDown()
    if not success then
      return false, error_message
    end
    while turtle.detect() do
      turtle.dig()
    end

    if i ~= length then
      moveForward()
    end
  end

  data.line = nil
  saveData()

  return true, ""
end

-- https://stackoverflow.com/questions/67579662/detect-whether-script-was-imported-or-executed-in-lua
if pcall(debug.getlocal, 4, 1) then
  -- We get here when this file is imported by another module
  -- with the require() function
  return line
else
  -- We get here when this file is executed directly from the command line

  local length = ...

  if length == nil then
    error("Usage: line <length>")
  end

  length = tonumber(length)

  init()
  success, error_message = line(length)
  if not success then
    print(string.format("Error: %s", error_message))
  end
end
