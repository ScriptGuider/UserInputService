-- @author ScriptGuider
-- @author Narrev
-- UserInputService wrapper

-- Services
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Client
local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

-- Pseudo Objects
local Signal = {}
Signal.__index = Signal

local disconnectmt = {
	disconnect = function()
		self.signal:disconnect()
		self.scope = nil
		self.connections[signal] = nil
	end
}
disconnectmt.__index = disconnectmt

local function newSignal()
	-- Generate Signal
	return setmetatable({
		BindData = true;
		connections = {};
		BindableEvent = Instance.new("BindableEvent");
	}, Signal)
end

function Signal:connect(func)
	if not func then error("connect(nil)", 2) end
	local scope = {}

	local signal = self.BindableEvent.Event:connect(function()
		func(scope, unpack(self.BindData))
	end)

	local connections = self.connections
	connections[signal] = true

	return setmetatable({
		signal = signal;
		scope = scope;
		connections = connections;
	}, disconnectmt)
end

function Signal:disconnect()
	local connections = self.connections
	for connection, _ in next, connections do
		connection:disconnect()
		connections[connection] = nil
	end
	-- Deconstruct table?
	self.BindData, self, connections = self.BindableEvent:Destroy()
end

function Signal:wait()
	self.BindableEvent.Event:wait()
	local BindData = self.BindData
	assert(BindData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
	return unpack(BindData)
end

function Signal:Fire(...)
	self.BindData = {...}
	self.BindableEvent:Fire()
end

-- Library & Input
local RegisteredKeys = {}
local Keys  = {}
local Mouse = {__newindex = PlayerMouse}
local Scope = {}
local Input = {
	Keys = setmetatable(Keys, Keys);
	Mouse = setmetatable(Mouse, Mouse);
	__newindex = InputService;
	CreateEvent = newSignal; -- Create a new event signal
}

function Keys:__index(v)
	assert(type(v) == "string", "Table Keys should be indexed by a string")
	Key = {
		KeyUp = newSignal();
		KeyDown = newSignal();
	}
	self[v] = Key
	RegisteredKeys[v] = true
	return Key
end

function Mouse:__index(v)
	local Mickey = PlayerMouse[v]
	if type(v) == "string" and pcall(function() local _ = Mickey.connect end) then
		local Stored = newSignal()
		self[v] = Stored
		local Scope = Scope
		Mickey:connect(function(...)
			Stored:Fire(Scope, ...)
		end)

		return Stored
	else
		return Mickey or error(Mickey .. " is not a valid member of PlayerMouse")
	end
end

local function KeyInputHandler(KeyEvent)
	local Scope = Scope
	local RegisteredKeys = RegisteredKeys
	return function(KeyName, processed)
		if not processed then
			KeyName = KeyName.KeyCode.Name
			if RegisteredKeys[KeyName] then
				Keys[KeyName][KeyEvent]:Fire(Scope)
			end
		end
	end
end

InputService.InputBegan:connect(KeyInputHandler("KeyUp")) -- InputBegan listener
InputService.InputEnded:connect(KeyInputHandler("KeyDown")) -- InputEnded listener

function Input:__index(i)
	local Variable = InputService[i] or error(Variable .. " is not a valid member of UserInputService")
	if type(Variable) == "function" then
		local func = Variable
		function Variable(...) -- We need to wrap functions to mimic ":" syntax
			return func(InputService, select(2, ...))
		end
	end
	return Variable
end

return setmetatable(Input, Input)
