require ".gps.util"

local function rectangle(xsize, zsize)
  if data.rectangle_initial_position == nil then
    data.rectangle_initial_position = {x=data.position.x, y=data.position.y, z=data.position.z}
    data.rectangle_initial_facing = data.facing
  else
    gotoPosition(data.rectangle_initial_position, true)
    faceDirection(data.rectangle_initial_facing)
  end

  moveUp()

  for _=1,zsize-1 do
    turtle.placeDown()
    moveForward()
  end

  turnRight()

  for _=1,xsize-1 do
    turtle.placeDown()
    moveForward()
  end

  turnRight()

  for _=1,zsize-1 do
    turtle.placeDown()
    moveForward()
  end

  turnRight()

  for _=1,xsize-1 do
    turtle.placeDown()
    moveForward()
  end

  turnRight()

  data.rectangle_initial_position = nil
  data.rectangle_initial_facing = nil
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

  init()
  rectangle(xsize_arg, zsize_arg)
end
