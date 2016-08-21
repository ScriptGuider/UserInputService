-- @author ScriptGuider
-- @author Narrev
-- UserInputService wrapper

-- Services
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Client
local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

-- Library & Input
local Keys  = {};
local Mouse = {};
local Scope = {};
local Input = {
	Keys = Keys;
	Mouse = Mouse;
	__newindex = InputService;
}

local KeyEvents = {}
local MouseEvents = {}

-- Helper function
local function CreateEvent()
	local this = {}
	local connections = {}

	local BindData
	local BindableEvent = Instance.new("BindableEvent")

	function this:connect(func)
		if not func then error("connect(nil)", 2) end
		local scope = {}

		local signal = BindableEvent.Event:connect(function()
			func(scope, unpack(BindData))
		end)

		connections[signal] = true
		local new = {}
		function new:disconnect()
			signal:disconnect()
			scope = nil
			connections[signal] = nil
		end
		return new
	end

	function this:disconnect()
		for connection, _ in next, connections do
			connection:disconnect()
			connections[connection] = nil
		end
		-- Deconstruct table?
		BindData, this, connections = BindableEvent:Destroy()
	end

	function this:wait()
		BindableEvent.Event:wait()
		assert(BindData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		return unpack(BindData)
	end

	-- Bypasses object cloning
	function this:Fire(...)
		BindData = {...}
		BindableEvent:Fire()
	end

	return this
end

-- Convert text to KeyCode values
function Keys:__index(v)
	if type(v) == "string" then
		local KeyCode = Enum.KeyCode[v]
		local KeyValue = KeyCode.Value
		local Key = KeyEvents[KeyValue]

		if not Key then
			KeyEvents[KeyValue] = {
				KeyUp   = CreateEvent();
				KeyDown = CreateEvent();
			}
			Key = KeyEvents[KeyValue]
		end
		return Key
	end
end

function Mouse:__index(v)
	if type(v) == "string" and pcall(function() local _ = Mouse[v].connect end) then
		local Stored = MouseEvents[v]
		if not Stored then
			MouseEvents[v] = CreateEvent()
			Stored = MouseEvents[v]
			Mouse[v]:connect(function(...)
				Stored:Fire(Scope, ...)
			end)
		end
		return Stored
	end
end

setmetatable(Keys, Keys)
setmetatable(Mouse, Mouse)

-- Create a new event signal
Input.CreateEvent = CreateEvent

-- Return the player mouse
function Input:GetMouse()
	return PlayerMouse
end

-- Input began listener
InputService.InputBegan:connect(function(InputObject)
	local KeyCode   = InputObject.KeyCode
	local KeyInput  = KeyEvents[KeyCode.Value]

	if KeyInput then
		KeyInput.KeyDown:Fire(Scope)
	end
end)

-- Input ended listener
InputService.InputEnded:connect(function(InputObject)
	local KeyCode   = InputObject.KeyCode
	local KeyInput  = KeyEvents[KeyCode.Value]

	if KeyInput then
		KeyInput.KeyUp:Fire(Scope)
	end
end)

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
