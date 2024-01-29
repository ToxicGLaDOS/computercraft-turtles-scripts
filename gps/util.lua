require ".non-gps.util"

local modem_item = "computercraft:wireless_modem_advanced"
local compass_item = "minecraft:compass"

function oppositeSide(side)
	if side == "left" then
		return "right"
	elseif side == "right" then
		return "left"
	else
		error(string.format("Bad side, expected 'left' or 'right', got %s", side))
	end
end

function equip(side)
	if side == "left" then
		turtle.equipLeft()
	elseif side == "right" then
		turtle.equipRight()
	else
		error(string.format("Bad side, expected 'left' or 'right', got %s", side))
	end
end

--- Initalize the state of the turtle
---@return boolean Whether initalizaion was successful.
function init()
  local initial_selected = turtle.getSelectedSlot()
  local success, error_message = initPosition()
  if not success then
    error(error_message)
    return false
  end

  success, error_message = initFacing()
  if not success then
    error(error_message)
    return false
  end

  turtle.select(initial_selected)

  return true
end

--- Initalize the position of the turtle.
---@return boolean Whether initalizaion was successful.
---@return string Error message. Empty string if initalizaion was successful.
function initPosition()
  local item_found, modem_position = findItemInInventory(modem_item)

  if item_found then
    turtle.select(modem_position)
    equip("left")
    local x,y,z = gps.locate()
    equip("left")
    -- Could be nil because the gps constellation isn't set up right
    if x == nil then
      return false, "GPS constellation isn't set up right"
    end

    data.position = {x=x, y=y, z=z}
  else
    if peripheral.getType("left") == "modem" or peripheral.getType("right") == "modem" then
      local x,y,z = gps.locate()
      if x == nil then
        return false, "GPS constellation isn't set up right"
      end
      data.position = {x=x, y=y, z=z}
    else
      return false, "No modem in inventory or equipped"
    end
  end

  return true, ""
end

--- Initalize the direction the turtle is facing.
-- The turtle must have a compass in it's inventory
-- or equipped.
---@return boolean Whether initalizaion was successful.
---@return string Error message. Empty string if initalizaion was successful.
function initFacing()
  local item_found, compass_position = findItemInInventory(compass_item)

  if item_found then
    turtle.select(compass_position)
    equip("left")
    data.facing = peripheral.call("left", "getFacing")
    -- Equip again to reequip whatever was in that hand before
    equip("left")
  else
    if peripheral.getType("left") == "compass" then
      data.facing = peripheral.call("left", "getFacing")
    elseif peripheral.getType("right") == "compass" then
      data.facing = peripheral.call("right", "getFacing")
    else
      return false, "No compass in inventory or equipped"
    end
  end

  return true, ""
end

