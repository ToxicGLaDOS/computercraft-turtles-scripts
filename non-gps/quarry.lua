local json = require "json"
local util = require "util"

if data.size == nil then
	width = tonumber(arg[1])
	length = tonumber(arg[2])
	if width <= 0 then
		error("Invalid width")
	elseif length <= 0 then
		error("Invalid length")
	end
	data.size = {width=width, length=length}
end

NORTH = 0
EAST = 1
SOUTH = 2
WEST = 3

MINING_STRIP = 0
CHANGING_LANES = 1
RETURNING_HOME = 2
REBASING = 3
DONE = 4

BEDROCK_NOT_FOUND = 0
BEDROCK_BELOW = 1
BEDROCK_FORWARD = 2
BEDROCK_ABOVE = 3

defaultState(MINING_STRIP)

-- A full inventory worth of digging * 2 as a little buffer
min_acceptable_fuel_level = 64 * 16 * 2

-- The last value per layer of our x position is either 0 or data.size - 1
final_z = (data.size.length - 1) * (data.size.width % 2)

function copyPosition()
	return {x=data.position.x, y=data.position.y, z=data.position.z}
end

if data.bedrock_found == nil then
	data.bedrock_found = false
end

-- Returns whether you should continue doing what you were doing or not
-- Basically a bad way to tell MINING_STRIP to not move forward
function checkForBedrock()
	local success, block_data = turtle.inspectUp()
	if success and block_data.name == "minecraft:bedrock" then
		local above_bedrock = copyPosition()
		above_bedrock.y = above_bedrock.y + 2
		data.previous_position = above_bedrock
		-- This case is too hard to deal with correctly
		-- So we just give up and rebase then move back to
		-- just above the bedrock
		changeState(REBASING)
		return false
	end

	local success, block_data = turtle.inspect()
	if success and block_data.name == "minecraft:bedrock" then
		moveUp()
		-- Exit early for efficency
		return true
	end

	local success, block_data = turtle.inspectDown()
	if success and block_data.name == "minecraft:bedrock" then
		data.bedrock_found = true
	end
	return true
end

function isBedrockBelow()
	local success, block_data = turtle.inspectDown()
	if success and block_data.name == "minecraft:bedrock" then
		return true
	end
	return false
end

function advanceForward()
	-- Double digs are for falling blocks
	turtle.dig()
	turtle.dig()
	turtle.digUp()
	turtle.digDown()
	local should_move = checkForBedrock()
	if should_move then
		moveForward()
	end
end

while true do
	if data.state ~= REBASING and turtle.getFuelLevel() < min_acceptable_fuel_level then
		data.previous_position = copyPosition()
		changeState(REBASING)
	end

	if data.state ~= REBASING and not hasEmptySlot() then
		data.previous_position = copyPosition()
		changeState(REBASING)
	end

	if data.position.z == final_z and data.position.x == data.size.width - 1 then
		turtle.digUp()
		turtle.digDown()
		changeState(RETURNING_HOME)
	end


	if data.state == MINING_STRIP then
		if data.facing == NORTH then
			if data.position.z < data.size.length - 1 then
				advanceForward()
			elseif data.position.z == data.size.length - 1 then
				turnRight()
				changeState(CHANGING_LANES)
			end
		elseif data.facing == EAST then
			if data.position.z == data.size.length - 1 then
				turtle.digUp()
				turtle.digDown()
				turnRight()
			elseif data.position.z == 0 then
				turtle.digUp()
				turtle.digDown()
				turnLeft()
			else
				error("Bad state while facing EAST")
			end
		elseif data.facing == SOUTH then
			if data.position.z > 0 then
				advanceForward()
			elseif data.position.z == 0 then
				turnLeft()
				changeState(CHANGING_LANES)
			end
		end
	elseif data.state == CHANGING_LANES then
		if data.facing == EAST then
			advanceForward()
			changeState(MINING_STRIP)
		end
	elseif data.state == RETURNING_HOME then
		if data.position.z ~= 0 then
			if data.facing ~= SOUTH then
				turnLeft()
			else
				moveForward()
			end
		else
			if data.position.x ~= 0 then
				if data.facing ~= WEST then
					turnRight()
				else
					moveForward()
				end
			else
				if data.facing ~= NORTH then
					turnRight()
				elseif not data.bedrock_found then
					if data.old_level == nil then
						data.old_level = data.position.y
					end
					while data.position.y > data.old_level - 3  and not isBedrockBelow() do
						turtle.digDown()
						moveDown()
					end
					data.old_level = nil
					changeState(MINING_STRIP)
				elseif data.position.y < 0 then
					moveUp()
				else
					changeState(DONE)
				end
			end
		end
	elseif data.state == REBASING then
		if data.position.x ~= 0 then
			if data.facing ~= WEST then
				turnLeft()
			else
				moveForward()
			end
		elseif data.position.z ~= 0 then
			if data.facing ~= SOUTH then
				turnLeft()
			else
				moveForward()
			end
		elseif data.position.y < 0 then
				moveUp()	
		else
			while data.facing ~= SOUTH do
				turnLeft()
			end
			-- We're facing SOUTH and at 0,0,0 here so we can just work sequentially

			-- Deposit everything
			for i=1,16 do
				turtle.select(i)
				local success, err = turtle.drop()
				if not success and err == "No space for items" then
					error("Deposit chest is full. Empty it and start program again")
				end
			end

			while turtle.getFuelLevel() < turtle.getFuelLimit() do
				while data.facing ~= WEST do
					turnRight()
				end

				local success = turtle.suck()
				if not success then
					break
				end
				local slot = findItemInInventory("minecraft:charcoal")

				if slot == 0 then
					error("Couldn't find charcoal. Perhaps fuel chest has wrong items in it?")
				end
				turtle.select(slot)
				turtle.refuel()
			end

			local slot = findItemInInventory("minecraft:charcoal")
			if slot ~= 0 then
				turtle.select(slot)
				turtle.drop()
			end

			while data.facing ~= NORTH do
				turnRight()
			end


			writeLog(string.format("Returning to y=%s", data.previous_position.y))
			while data.position.y > data.previous_position.y do
				turtle.digDown()
				moveDown()
			end
			writeLog(string.format("Returning to z=%s", data.previous_position.z))
			while data.position.z < data.previous_position.z do
				-- Dig just in case an enderman placed a block or something
				turtle.dig()
				turtle.dig()
				moveForward()
			end
			turnRight()

			writeLog(string.format("Returning to x=%s", data.previous_position.x))
			while data.position.x < data.previous_position.x do
				turtle.dig()
				turtle.dig()
				moveForward()
			end

			if data.position.x % 2 == 0 then
				-- Face NORTH
				turnLeft()
			else
				-- Face SOUTH
				turnRight()
			end

			changeState(MINING_STRIP)
		end
	elseif data.state == DONE then
		print("Done!")
		break
	end
end


