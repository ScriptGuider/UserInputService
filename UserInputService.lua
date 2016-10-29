-- @author ScriptGuider
-- @author Narrev
-- UserInputService wrapper

-- Services
local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Client
local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

-- Pseudo Objects
local Signal = {}
Signal.__index = Signal

-- Optimize
local Connect = InputService.InputBegan.Connect
local Heartbeat = RunService.Heartbeat
local Wait = Heartbeat.Wait

local find = string.find
local remove = table.remove

local Disconnector = {
	Disconnect = function(self)
		local func = self.func
		local Connections = self.Connections
		for a = 1, #Connections do
			if Connections[a] == func then
				remove(Connections, a)
			end
		end
	end
}
Disconnector.__index = Disconnector

local function newSignal()
	return setmetatable({Connections = {}}, Signal)
end

function Signal:Connect(func)
	if not func then error("Connect(nil)", 2) end
	local Connections = self.Connections
	Connections[#Connections + 1] = func
	return setmetatable({Connections = Connections; func = func}, Disconnector)
end

function Signal:Disconnect()
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a] = nil
	end
end

function Signal:Wait()
	repeat until self.Go or not Wait(Heartbeat)
	self.Go = false
end

local function FireSignal(self, ...)
	self.Go = true
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a](...)
	end
end

Signal.Fire = FireSignal
Signal.Press = FireSignal

-- Library & Input
local RegisteredKeys = {}
local Keys  = {}
local Mouse = {__newindex = PlayerMouse}

function Keys:__index(v)
	assert(type(v) == "string", "Table Keys should be indexed by a string")
	local Key = {
		KeyUp = newSignal();
		KeyDown = newSignal();
	}
	self[v] = Key
	RegisteredKeys[v] = true
	return Key
end

function Mouse:__index(v)
	local Mickey = PlayerMouse[v]
	if type(v) == "string" and find(tostring(Mickey), "Signal") then
		local Stored = newSignal()
		rawset(self, v, Stored)
		Connect(Mickey, function(...)
			return FireSignal(Stored, ...)
		end)
		return Stored
	else
		return Mickey or error(Mickey .. " is not a valid member of PlayerMouse")
	end
end

local function KeyInputHandler(KeyEvent)
	local RegisteredKeys = RegisteredKeys
	return function(KeyName, processed)
		if not processed then
			KeyName = KeyName.KeyCode.Name
			if RegisteredKeys[KeyName] then
				FireSignal(Keys[KeyName][KeyEvent])
			end
		end
	end
end

Connect(InputService.InputBegan, KeyInputHandler("KeyDown")) -- InputBegan listener
Connect(InputService.InputEnded, KeyInputHandler("KeyUp")) -- InputEnded listener

local Input = {
	__newindex = InputService;
	CreateEvent = newSignal; -- Create a new event signal
	Keys = setmetatable(Keys, Keys);
	Mouse = setmetatable(Mouse, Mouse);
}

function Input:__index(i)
	local Variable = InputService[i] or error(i .. " is not a valid member of UserInputService")
	if type(Variable) == "function" then
		local func = Variable
		function Variable(...) -- We need to wrap functions to mimic ":" syntax
			return func(InputService, select(2, ...))
		end
	end
	return Variable
end

return setmetatable(Input, Input)
