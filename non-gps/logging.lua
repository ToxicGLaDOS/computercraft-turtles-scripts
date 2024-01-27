-- This script expects a furnace with at least one charcoal in the fuel slot
-- 2 up and 1 left from the start position of the turtle and a
-- chest 2 up and 1 behind from the start position of the turtle
-- The turtle should also start with at least one sapling in it's inventory
-- more will make things go faster, but one should be enough to kick start it

local util = require "util"

size = 17

sapling_name = "minecraft:birch_sapling"
log_name = "minecraft:birch_log"

PLANTING = 0
CHANGING_LANES = 1
RETURNING_HOME = 2
CUTTING_TREE = 3
DEPOSITING = 4

defaultState(PLANTING)

final_z = (size - 1) * (size % 2)

function plant_move()
	slot = findItemInInventory(sapling_name)
	if slot ~= 0 then
		turtle.select(slot)
		if data.position.x % 3 == 2 and data.position.z % 3 == 2 then
			turtle.placeDown()
		end
	end
	turtle.suckDown()
	turtle.dig()
	moveForward()
end

function planting()
	success, block_info = turtle.inspectDown()
	if success and block_info.name == log_name then
		changeState(CUTTING_TREE)
	elseif data.position.z == final_z and data.position.x == size - 1 then
		changeState(RETURNING_HOME)
	elseif data.facing == NORTH then
		if data.position.z < size - 1 then
			plant_move()
		elseif data.position.z == size - 1 then
			changeState(CHANGING_LANES)
			turnRight()
		end
	elseif data.facing == EAST then
		if data.position.z == size - 1 then
			turnRight()
		elseif data.position.z == 0 then
			turnLeft()
		else
			error("Bad state while facing EAST")
		end
	elseif data.facing == SOUTH then
		if data.position.z > 0 then
			plant_move()
		elseif data.position.z == 0 then
			changeState(CHANGING_LANES)
			turnLeft()
		end
	end
end

function changing_lanes()
	if data.facing == EAST then
		if data.position.x % 3 == 2 and data.position.z % 3 == 2 then
			turtle.placeDown()
		end
		turtle.suckDown()
		turtle.dig()
		changeState(PLANTING)
		moveForward()
	end
end

function returning_home()
	if data.position.z ~= 0 then
		if data.facing ~= SOUTH then
			turnLeft()
		else
			turtle.dig()
			moveForward()
		end
	else
		if data.position.x ~= 0 then
			if data.facing ~= WEST then
				turnRight()
			else
				turtle.dig()
				turtle.suckDown()
				moveForward()
			end
		else
			changeState(DEPOSITING)
		end
	end
end

function cutting_tree()
	success, block_info = turtle.inspectUp()
	if success then
		turtle.digUp()
		moveUp()
	elseif data.position.y > 1 then
		turtle.digDown()
		moveDown()
	else
		turtle.digDown()
		--turtle.placeDown()
		changeState(PLANTING)
	end
end

function depositing()
	if data.position.z == 0 and data.position.x == 0 and data.facing == 3 then
		moveForward()
		turtle.suckUp()
		if turtle.getFuelLevel() < 5 * size * size then
			slot = findItemInInventory("minecraft:charcoal")
			if slot ~= 0 then
				turtle.select(slot)
				turtle.refuel()
			end
		end
		moveForward()
		turtle.digUp()
		moveUp()
		turtle.digUp()
		moveUp()
		turnLeft()
		turnLeft()
		turtle.dig()
		moveForward()
		
		slot = findItemInInventory("minecraft:birch_log")
		if slot ~= 0 then
			turtle.select(slot)
			turtle.dropDown()
		end
		turtle.dig()
		moveForward()
		turtle.digDown()
		moveDown()
		turnLeft()
		turnLeft()

		-- Deposit into fuel slot of furnace
		slot = findItemInInventory("minecraft:charcoal")
		if slot ~= 0 then
			turtle.select(slot)
			turtle.drop()
		end
		turnLeft()

		-- Deposit into chest
		slot = findItemInInventory("minecraft:charcoal")
		while slot ~= 0 do
			turtle.select(slot)
			turtle.drop()
			slot = findItemInInventory("minecraft:charcoal")
		end

		-- Deposit into chest
		max_saplings_slot = find_biggest_item_stack(sapling_name)
		for i=1,16 do
			detail = turtle.getItemDetail(i)
			if detail ~= nil and i ~= max_saplings_slot and detail.name == sapling_name then
				turtle.select(i)
				turtle.drop()
			end
		end

		-- Deposit into chest
		slot = findItemInInventory("minecraft:stick")
		while slot ~= 0 do
			turtle.select(slot)
			turtle.drop()
			slot = findItemInInventory("minecraft:stick")
		end

		-- Deposit into chest
		slot = findItemInInventory(log_name)
		while slot ~= 0 do
			turtle.select(slot)
			turtle.drop()
			slot = findItemInInventory(log_name)
		end

		turnLeft()
		turnLeft()
		moveDown()
		changeState(PLANTING)
		os.sleep(60)
	else
		-- TODO: Return to 0,1,0 without breaking furnaces or chests
		if data.position.y == 1 then
			while data.facing ~= 1 do
				trunLeft()
			end
			while data.position.x ~= 0 do
				moveForward()
			end
		while data.facing ~= 0 do
				turnRight()
			end
		elseif data.position.y == 2 then
			turtle.digUp()
			moveUp()
		elseif data.position.y == 3 then
			while data.facing ~= 1 do
				turnLeft()
			end
			while data.position.x ~= 0 do
				moveForward()
			end
			moveDown()
			moveDown()
			turnLeft()
			changeState(PLANTING)
		else
			error("Unhandled condition when recovering from reboot")
		end
	end
end

while true do
	if data.position.y < 1 then
		moveUp()
	elseif data.state == PLANTING then
		planting()
	elseif data.state == CHANGING_LANES then
		changing_lanes()
	elseif data.state == RETURNING_HOME then
		returning_home()
	elseif data.state == CUTTING_TREE then
		cutting_tree()
	elseif data.state == DEPOSITING then
		depositing()
	end
end
