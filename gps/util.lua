position = nil
facing = nil
UNKNOWN = "UNKNOWN"

modem_item = "computercraft:wireless_modem_advanced"
compass_item = "minecraft:compass"

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


-- To call this the turtle needs to have a compass and an ender modem
-- somewhere, they can be equipped or not
function init(left_peripheral, right_peripheral)
	if left_peripheral == modem_item then
		local modem_side = "left"
		success, slot = findItemInInventory(modem_item)
		if not success then
			error("Couldn't find modem")
		end
		turtle.select(slot)
		turtle.equipLeft()
	elseif right_peripheral == modem_item then
		local modem_side = "right"
	else
		if peripheral.getType("left") == "modem" then
			-- modem_side is the side we're going to use to
			-- swap peripherals for the init
			local modem_side = "left"
		elseif peripheral.getType("right") == "modem" then
			local modem_side = "right"
		else
			success, slot = findItemInInventory("computercraft:wireless_modem_advanced")
			if not success then
				error("Couldn't find modem")
			end
			local modem_side = "left"
			turtle.select(slot)
			turtle.equipLeft()
		end
	end
	local compass_side = oppositeSide(modem_side)

	local x,y,z = gps.locate()
	position = {x=x, y=y, z=z}

	

	if peripheral.getType(compass_side) ~= "compass" then
		-- Then it has to be in our inventory otherwise error
		success, slot = findItemInInventory("minecraft:compass")
		if not success then
			error("Couldn't find compass")
		end

		turtle.select(slot)
		equip(compass_side)
	end

	facing = peripheral.call(compass_side, "getFacing")

	-- Now we have modem and compass on opposite sides
	-- Everything else should be in inventory until we equip it

	if left_peripheral ~= "computercraft:wireless_modem_advanced" and \
		left_peripheral ~= "minecraft:compass" then
		success, slot = findItemInInventory(left_peripheral)
		if not success then
			error(string.format("Couldn't find left peripheral '%s'", left_peripheral))
		end

		turtle.select(slot)
		turtle.equipLeft()
	end

	if right_peripheral ~= "computercraft:wireless_modem_advanced" and \
		right_peripheral ~= "minecraft:compass" then
		if not success then
			error(string.format("Couldn't find right peripheral '%s'", right_peripheral))
		end

		turtle.select(slot)
		turtle.equipRight()
	end

	if left_peripheral == "computercraft:wireless_modem_advanced" and modem_side == "right" then
		error("Modem got on wrong side, I don't want to handle this case")
	end
	

end

function initPosition()

end

function initHeading()
end

