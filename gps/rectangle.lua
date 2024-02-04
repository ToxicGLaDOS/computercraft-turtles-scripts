require ".gps.util"
local line = require ".gps.line"

local function selectBuildItem()
  local selected_item = turtle.getItemDetail()
  if selected_item ~= data.rectangle_build_item then
    local success, slot = findItemInInventory(data.rectangle_build_item)
    if not success then
      return false, "No build item"
    end
  end

  return true, ""
end

local function init_rectangle()
  if data.rectangle == nil then
    local selected_item = turtle.getItemDetail()
    if selected_item == nil then
      error("Rectangle needs the build item selected upon startup")
    end

    data.rectangle = {
      initial_position = copyPosition(data.position),
      initial_facing = data.facing,
      build_item = selected_item.name
    }
    saveData()
  end
end


---Calculates with side of the rectangle we're working on
---@param xsize integer
---@param zsize integer
---@return integer
local function calculate_side(xsize, zsize)
  local json = require(".json")
  local positionDelta = subtractPosition(data.position, data.rectangle.initial_position)

  print(json.encode(positionDelta))
  positionDelta = changeVectorReferenceFromNorth(positionDelta, data.rectangle.initial_facing)
  print(json.encode(positionDelta))

  if math.abs(positionDelta.x) == 0 and math.abs(positionDelta.z) ~= zsize - 1 then
    -- 1st line
    return 1
  elseif math.abs(positionDelta.z) == zsize - 1 and math.abs(positionDelta.x) ~= xsize - 1 then
    -- 2nd line
    return 2
  elseif math.abs(positionDelta.x) == xsize - 1 and math.abs(positionDelta.z) ~= 0 then
    -- 3rd line
    return 3
  elseif math.abs(positionDelta.z) == 0 and math.abs(positionDelta.x) ~= 0 then
    -- 4th line
    return 4
  else
    error("Turtle isn't on the rectangle")
  end
end

local function rectangle(xsize, zsize)
  init_rectangle()

  local success, slot = findItemInInventory(data.rectangle.build_item)
  if not success then
    return false, "No build item"
  end
  turtle.select(slot)

  local error_message

  local side = calculate_side(xsize, zsize)

  if side == 1 then
    success, error_message = line(zsize)
    if not success then
      return false, error_message
    end
    side = calculate_side(xsize, zsize)
  end


  if side == 2 then
    -- One turn right from our initial direction
    faceDirection(rightDirection(data.rectangle.initial_facing))

    success, error_message = line(xsize)
    if not success then
      return false, error_message
    end
    side = calculate_side(xsize, zsize)
  end


  if side == 3 then
    -- Two turns right from our initial direction (i.e. backwards)
    faceDirection(rightDirection(rightDirection(data.rectangle.initial_facing)))

    success, error_message = line(zsize)
    if not success then
      return false, error_message
    end
    side = calculate_side(xsize, zsize)
  end


  if side == 4 then
    -- One turn left from our initial direction (i.e. backwards)
    faceDirection(leftDirection(data.rectangle.initial_facing))

    success, error_message = line(xsize)
    if not success then
      return false, error_message
    end
  end

  faceDirection(data.rectangle.initial_facing)

  data.rectangle = nil
  saveData()

  return true, ""
end



-- https://stackoverflow.com/questions/67579662/detect-whether-script-was-imported-or-executed-in-lua
if pcall(debug.getlocal, 4, 1) then
  -- We get here when this file is imported by another module
  -- with the require() function
  return rectangle
else
  -- We get here when this file is executed directly from the command line

  local xsize_arg, zsize_arg = ...

  if xsize_arg == nil or zsize_arg == nil then
    error("Usage: rectangle x z")
  end

  xsize_arg = tonumber(xsize_arg)
  zsize_arg = tonumber(zsize_arg)

  init()
  success, error_message = rectangle(xsize_arg, zsize_arg)
  if not success then
    print(error_message)
  end
end
