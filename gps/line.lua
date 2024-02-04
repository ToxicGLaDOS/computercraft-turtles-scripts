require ".gps.util"

local function init_line()
  if data.line == nil then
    local selected_item = turtle.getItemDetail()
    if selected_item == nil then
      error("Line needs the build item selected upon startup")
    end

    data.line = {
      initial_position = copyPosition(data.position),
      initial_facing = data.facing,
      build_item = selected_item.name
    }

    saveData()
  end
end

local function selectBuildItem()
  local selected_item = turtle.getItemDetail()
  -- I think this has a bug cuz selected_item is a table and build_item is a string?
  if selected_item ~= data.line.build_item then
    local success, slot = findItemInInventory(data.line.build_item)
    if not success then
      return false, "No build item"
    end
  end

  return true, ""
end

local function line(length)
  if data.line == nil then
    init_line()
  else
    -- How much we've moved since we started
    local positionDelta = subtractPosition(data.position, data.line.initial_position)
    if data.line.initial_facing == EAST or data.line.initial_facing == WEST then
      length = length - math.abs(positionDelta.x)
    else
      length = length - math.abs(positionDelta.z)
    end

    print(length)
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
