-- @author ScriptGuider
-- @author Narrev
-- UserInputService wrapper

-- Services
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Client
local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

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
local Keys  = {}
local Mouse = {}
local Scope = {}
local KeyEvents = {}
local MouseEvents = {}
local Input = {
	Keys = setmetatable(Keys, Keys);
	Mouse = setmetatable(Mouse, Mouse);
	__newindex = InputService;
	CreateEvent = newSignal; -- Create a new event signal
}

-- Convert text to KeyCode values
function Keys:__index(v)
	if type(v) == "string" then
		local KeyCode = Enum.KeyCode[v]
		local KeyValue = KeyCode.Value
		local Key = KeyEvents[KeyValue]

		if not Key then
			KeyEvents[KeyValue] = {
				KeyUp = newSignal();
				KeyDown = newSignal();
			}
			Key = KeyEvents[KeyValue]
		end
		return Key
	end
end

function Mouse:__index(v)
	if type(v) == "string" and pcall(function() local _ = PlayerMouse[v].connect end) then
		local Stored = MouseEvents[v]
		if not Stored then
			MouseEvents[v] = newSignal()
			Stored = MouseEvents[v]
			PlayerMouse[v]:connect(function(...)
				Stored:Fire(Scope, ...)
			end)
		end
		return Stored
	end
end

-- Return the player mouse
function Input:GetMouse()
	return PlayerMouse
end

local function InputHandler(KeyEvent)
	return function(InputObject)
		local KeyCode   = InputObject.KeyCode
		local KeyInput  = KeyEvents[KeyCode.Value]

		if KeyInput then
			KeyInput[KeyEvent]:Fire(Scope)
		end
	end
end

InputService.InputBegan:connect(InputHandler("KeyUp")) -- InputBegan listener
InputService.InputEnded:connect(InputHandler("KeyDown")) -- InputEnded listener

function Input:__index(i)
	local Variable = InputService[i]
	if Variable then
		if type(Variable) == "function" then
			local func = Variable
			function Variable(...)
				return func(InputService, ...)
			end
		end
		return Variable
	else
		error(Variable .. " is not a valid member of UserInputService")
	end
end

return setmetatable(Input, Input)
