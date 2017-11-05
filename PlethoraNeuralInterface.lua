--CONFIG lel
-- Mobs to Search for when using Mob Scanner/Aimbot in format "Creeper"
local mobNames = { "Creeper", "Skeleton", "Zombie" } 

-- Ore to search for when using the Ore Scanner in format "minecraft:diamond_ore"
local oreNames = { "minecraft:diamond_ore", "minecraft:emerald_ore" }

-- Method to notify the player; Options: "modem", "chatModule", "printOnly"
local preferredMethod = "modem"

-- Port for the Modem to use
local modemPort = 1337

-- Format of postions in notifications Options: "relativeXYZ", "relativeDirection"
local notificationPosStyle = "relativeDirection"

--KEYS:
local launchUpKey = {}
launchUpKey.key = keys.e
launchUpKey.keyname = "E"
local launchDirectionKey = {}
launchDirectionKey.key = keys.f
launchDirectionKey.keyname = "F"
local mobScanKey = {}
mobScanKey.key = keys.numPad9
mobScanKey.keyname = "NumPad9"
local useSpamKey = {}
useSpamKey.key = keys.numPad8
useSpamKey.keyname = "NumPad8"
local aimbotKey = {}
aimbotKey.key = keys.numPad7
aimbotKey.keyname = "NumPad7"
local noFallKey = {}
noFallKey.key = keys.numPad6
noFallKey.keyname = "NumPad6"
local hoverKey = {}
hoverKey.key = keys.numPad5
hoverKey.keyname = "NumPad5"
local oreScanKey = {}
oreScanKey.key = keys.numPad4
oreScanKey.keyname = "NumPad4"

---------------------------------------------------
local modules = peripheral.find("neuralInterface")
if not modules then
	error("Must have a neural interface", 0)
end

if preferredMethod == "modem" then
	--Modem
	modem = peripheral.find("modem")
	if not modem then
		error("Must have a modem", 0)
	end
	modem.open(modemPort)
	if modem.isOpen(modemPort) == false then
		error("Can't open Port", 0)
	end
elseif preferredMethod == "chatModule" then
	--Chat Module
	if not modules.hasModule("plethora:chat", 0) then
		error("Must have a Chat Module", 0)
	end
end

local hasSensor = true
local hasKinetic = true
local hasScanner = true
local hasIntrospection = true

if not modules.hasModule("plethora:sensor", 0) then hasSensor = false end
if not modules.hasModule("plethora:kinetic", 0) then hasKinetic = false end
if not modules.hasModule("plethora:scanner", 0) then hasScanner = false end
if not modules.hasModule("plethora:introspection", 0) then hasIntrospection = false end

 
--Bools
local meta = {}

local mobscan = {}
mobscan.enabled = false
mobscan.name = "Mob Scanner"
mobscan.event = "mobscan"

local use = {}
use.enabled = false
use.name = "Use Spam"
use.event = "use"

local aimbot = {}
aimbot.enabled = false
aimbot.name = "Aimbot"
aimbot.event = "aimbot"

local nofall = {}
nofall.enabled = false
nofall.name = "No Fall"
nofall.event = "nofall"

local orescan = {}
orescan.enabled = false
orescan.name = "Ore Scanner"
orescan.event = "orescan"

local hover = {}
hover.enabled = false
hover.name = "Hover"
hover.event = "hover"
 

local mobLookup = {}
for i = 1, #mobNames do
	mobLookup[mobNames[i]] = true
end

local oreLookup = {}
for i = 1, #oreNames do
	oreLookup[oreNames[i]] = true
end

--Helper Functions
function tell(message)
	if message then
		print(message)
		if preferredMethod == "modem" then
			modem.transmit(modemPort, modemPort + 1, message)
			sleep(0.01)
		elseif preferredMethod == "chatModule" then
			modules.tell(message)
		end
	end
end

local function toggle(array)
	array.enabled = not array.enabled
	tell(array.name .. " was set to " .. tostring(array.enabled))
	if array.enabled then 
		os.queueEvent(array.event)
	end
end

local function getDirection(array)
	local pos = {}
	if notificationPosStyle == "relativeDirection" then
		if array.x < 0 then
			pos.x = "West: "
		else
			pos.x = "East: "
		end
		pos.y = ", Height: "
		if array.z < 0 then
			pos.z = ", North: "
		else
			pos.z = ", South: "
		end
	else --If relativeXYZ just return the normal values
		pos.x = "X: "
		pos.y = ", Y: "
		pos.z = ", Z: "
	end
	return pos
end

local function getPosition(array)
	local pos = {}
	if notificationPosStyle == "relativeDirection" then
		if array.x < 0 then
			pos.x = array.x * -1
		else
			pos.x = array.x
		end
		pos.y = array.y
		if array.z < 0 then
			pos.z = array.z * -1
		else
			pos.z = array.z
		end
		return pos
	else --If relativeXYZ just return the normal values
		return array
	end
	return array
end

local function look(entity)
	local x, y, z = entity.x, entity.y, entity.z
	local pitch = -math.atan2(y, math.sqrt(x * x + z * z))
	local yaw = math.atan2(-x, z)

	modules.look(math.deg(yaw), math.deg(pitch))
end

local function distance(mob)
	local a = mob.x^2 + mob.y^2 + mob.z^2
	return math.sqrt(a)
end

local function findNearest(array)
	local nearestMob = array[1]
	if #array > 1 then
		for i=2, #array do
			if (distance(array[i]) < distance(nearestMob)) then
				nearestMob = array[i]
			end
		end
	end
	return nearestMob
end

local function clearScreen()
	term.setBackgroundColor(colours.black)  -- Set the background colour to black.
	term.clear()                            -- Paint the entire display with the current background colour.
	term.setCursorPos(1,1)                  -- Move the cursor to the top left position.
end
 
-- Start Main Loop
parallel.waitForAny(
	--- This loop just pulls user input. It handles a couple of function keys, as well as
	--- setting the "hover" field to true/false.
	function()
		while true do
			local event, key = os.pullEvent("key")
			if key == launchUpKey.key then
				if hasKinetic then
					modules.launch(0, -90, 3)
				else
					tell("No Kinetic Module installed; Feature Disabled")
				end
			elseif key == launchDirectionKey.key then
			   if hasKinetic then
					modules.launch(meta.yaw, meta.pitch, 3)
				else
					tell("No Kinetic Module installed; Feature Disabled")
				end
			elseif key == mobScanKey.key then
				if hasSensor then
					toggle(mobscan)
				else
					tell("No Entity Sensor installed; Feature Disabled")
				end
			elseif key == useSpamKey.key then
				if hasKinetic then
					toggle(use)
				else
					tell("No Kinetic Module installed; Feature Disabled")
				end
			elseif key == aimbotKey.key then
				if hasSensor and hasKinetic then
					toggle(aimbot)
				else
					tell("Feature needs to have Kinetic Module and Entity Sensor installed; Feature Disabled")
				end
			elseif key == noFallKey.key then
				if hasKinetic and hasScanner and hasIntrospection then
					toggle(nofall)
				else
					tell("Feature needs to have Kinetic-, Introspection Module and Block Scanner installed; Feature Disabled")
				end
			elseif key == hoverKey.key then
				if hasKinetic and hasIntrospection then
					toggle(hover)
				else
					tell("Feature needs to have Kinetic and Introspection Module installed; Feature Disabled")
				end
			elseif key == oreScanKey.key then
				if hasScanner then
					toggle(orescan)
				else
					tell("No Block Scanner installed; Feature Disabled")
				end
			end
		end
	end,
	function() -- Update Meta Data
		while true do
			if (hasIntrospection) then
				meta = modules.getMetaOwner()
			end
		end
	end,
	function() --Mob Scanner
		while true do
			if mobscan.enabled then
				local mobs = modules.sense()
 
				local candidates = {}
				for i = 1, #mobs do
					local mob = mobs[i]
					if mobLookup[mob.name] then
						candidates[#candidates + 1] = mob
					end
				end
 
				if #candidates > 0 then
					if #candidates > 3 then
						local mobString = candidates[1].name
						for i=2, #candidates do
							mobString = mobString .. ", " .. candidates[i].name
						end
						if (string.len(mobString) > 70) then mobString = "Too many Mobs" end
						tell(tostring(#candidates) .. " Mobs found near you: " .. mobString)
					else
						for i=1, #candidates do
							local mob = candidates[i]
							if mob.y < 5 and mob.y > -5 then
								local pos = getDirection(mob)
								local mobpos = getPosition(mob)
								tell("Mob Scanner | " .. i .. ": " .. mob.name .. " found at " .. pos.x .. mobpos.x .. pos.y .. mobpos.y .. pos.z .. mobpos.z)
							end
						end
					end
				end
				sleep(2)
			else
				os.pullEvent(mobscan.event)
			end
		end
	end,
	function() -- Use Spam
		while true do
			if use.enabled then
				if (modules.use(1,"main") == false) then
					tell("No Block to use")
					use = false
					tell("Use Spam was set to " .. tostring(use))
				end
				sleep(0.5)
			else
				os.pullEvent(use.event)
			end
		end
	end,
	function() --Aimbot
		while true do
			if aimbot.enabled then
				local mobs = modules.sense()
 
				local candidates = {}
				for i = 1, #mobs do
					local mob = mobs[i]
					if mobLookup[mob.name] then
						candidates[#candidates + 1] = mob
					end
				end

				if #candidates > 0 then
					local mob = findNearest(candidates)
					look(mob)
					sleep(0.2)
				end
			else
				os.pullEvent(aimbot.event)
			end
		end
	end,
	function() -- No Fall
		while true do
			if nofall.enabled then
				local blocks = modules.scan()
				for y = 0, -8, -1 do
					-- Scan from the current block downwards
					local block = blocks[1 + (8 + (8 + y)*17 + 8*17^2)]
					if block.name ~= "minecraft:air" then
						if meta.motionY < -0.3 then
							-- If we're moving slowly, then launch ourselves up
							modules.launch(0, -90, math.min(4, meta.motionY / -0.5))
						end
					break
					end
				end
			else
				os.pullEvent(nofall.event)
			end
		end
	end,
	function() -- Hover
		while true do
			if hover.enabled then
				-- We calculate the required motion we need to take
				local mY = meta.motionY
				mY = (mY - 0.138) / 0.8

				-- If it is sufficiently large then we fire ourselves in that direction.
				if mY > 0.5 or mY < 0 then
					local sign = 1
					if mY < 0 then sign = -1 end
					modules.launch(0, 90 * sign, math.min(4, math.abs(mY)))
				else
					sleep(0)
				end
			else
				os.pullEvent(hover.event)
			end
		end
	end,
	function() -- Ore Scanner
		while true do
			if orescan.enabled then
				local ores = modules.scan()
 
				local candidates = {}
				for i = 1, #ores do
					local ore = ores[i]
					if oreLookup[ore.name] then
						candidates[#candidates + 1] = ore
					end
				end
 
				if #candidates > 0 then
					for i=1, #candidates do
						local ore = candidates[i]
						local pos = getDirection(ore)
						local orepos = getPosition(ore)
						tell("Ore Scanner | " .. i .. ": " .. ore.name .. " found at " .. pos.x .. orepos.x .. pos.y .. orepos.y .. pos.z .. orepos.z)
					end
				else
					tell("Ore Scanner | No Ores found")
				end
				orescan.enabled = false
			else
				os.pullEvent(orescan.event)
			end
		end
	end,
	function() -- Show Text 
		while true do
			clearScreen()
			--Launch
			if (hasKinetic) then
				term.setTextColor(colors.green)
				print("Launch Upwards: Press " .. launchUpKey.keyname .. ".")
				print("Launch in Direction: Press " .. launchDirectionKey.keyname .. ".")
			else
				term.setTextColor(colors.red)
				print("Launch Upwards: Needs Kinetic Module.")
				print("Launch in Direction: Needs Kinetic Module.")
			end
			--Mob Scanner
			if (hasSensor) then
				term.setTextColor(colors.green)
				print("Toggle Mob Scanner: Press " .. mobScanKey.keyname .. ".")
			else
				term.setTextColor(colors.red)
				print("Toggle Mob Scanner: Needs Entity Sensor.")
			end
			--Use Spam
			if (hasKinetic) then
				term.setTextColor(colors.green)
				print("Toggle Use Spam: Press " .. useSpamKey.keyname .. ".")
			else
				term.setTextColor(colors.red)
				print("Toggle Use Spam: Needs Kinetic Module.")
			end
			--Aimbot
			if (hasKinetic and hasSensor) then
				term.setTextColor(colors.green)
				print("Toggle Aimbot: Press " .. aimbotKey.keyname .. ".")
			else
				term.setTextColor(colors.red)
				print("Toggle Aimbot: Needs Kinetic Module and Entity Sensor.")
			end
			--NoFall
			if (hasKinetic and hasScanner and hasIntrospection) then
				term.setTextColor(colors.green)
				print("Toggle No Fall Damage: Press " .. noFallKey.keyname .. ".")
			else
				term.setTextColor(colors.red)
				print("Toggle No Fall Damage: Needs Kinetic Module, Block Scanner and Introspection Module.")
			end
			--Hoever
			if (hasKinetic and hasIntrospection) then
				term.setTextColor(colors.green)
				print("Toggle Hover: Press " .. hoverKey.keyname .. ".")
			else
				term.setTextColor(colors.red)
				print("Toggle Hover: Needs Kinetic- and Introspection Module.")
			end
			--Block Scan
			if (hasScanner) then
				term.setTextColor(colors.green)
				print("Activate Ore Scan: Press " .. oreScanKey.keyname)
			else
				term.setTextColor(colors.red)
				print("Activate Ore Scan: Needs Block Scanner.")
			end
			--sleep
			sleep(5)
		end
	end
)
