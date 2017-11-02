local modemPort = 1337
--------------------------------
local modem = peripheral.find("modem")
if not modem then
	error("We need a Modem", 0)
end
modem.open(1337)

local manipulator = peripheral.find("manipulator")
if not manipulator then
	error("We need a manipulator", 0)
end
if manipulator.hasModule("plethora:chat") == false then
	error("We need the chat module", 0)
end
clock = true
if manipulator.hasModule("minecraft:clock") == false then
	clock = false
end

manipulator.capture("getTime()")
--Main Loop
parallel.waitForAny(
	function()
		while true do
			local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
			if event == "modem_message" then
				print("The message was: "..message)
				manipulator.tell(message)
			end
		end
	end,
	function()
		while true do
			local event, message, pattern = os.pullEvent("chat_capture")
			if message == "getTime()" and clock then
				local day = manipulator.getDay()
				local gameTime = manipulator.getTime()
        			local hours = (gameTime - (gameTime % 1000)) / 1000 + 6 --0 equals 6:00
        			local minutes = math.floor((gameTime % 1000) * 60 / 1000)
        			if hours >= 24 then
            				hours = hours - 24
        			end
 
       	 			if hours == 0 then 
					hours = 24 
				end
				
				if (string.len(minutes) < 2) then
					minutes = "0" .. minutes
				end
 
        			local finaltime = hours .. ":" .. minutes;
				manipulator.tell("It's " .. finaltime .. " on the " .. day + 1 .. ". day.")
			end
		end
	end
)
