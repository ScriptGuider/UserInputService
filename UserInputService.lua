-- @author Narrev
-- @original ScriptGuider
-- UserInputService wrapper

-- Services
local GetService = game.GetService
local InputService = GetService(game, "UserInputService")
local RunService = GetService(game, "RunService")
local StarterGui = GetService(game, "StarterGui")
local Players = GetService(game, "Players")

-- Optimize
local Connect = InputService.InputBegan.Connect
local Heartbeat = RunService.Heartbeat
local Wait = Heartbeat.Wait
local SetCore = StarterGui.SetCore
local GetChildren = game.GetChildren

local time = os.time
local find = string.find
local remove = table.remove
local error, type, select, setmetatable, rawset, tostring = error, type, select, setmetatable, rawset, tostring

-- Client
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PlayerMouse = Player:GetMouse()

-- Pseudo Objects
local Disconnector = {}
Disconnector.__index = Disconnector

function Disconnector:Disconnect()
	local func = self.func
	local Connections = self.Connections
	for a = 1, #Connections do
		if Connections[a] == func then
			remove(Connections, a)
		end
	end
end

local function ConnectSignal(self, func)
	if not func then error("Connect(nil)", 2) end
	local Connections = self.Connections
	Connections[#Connections + 1] = func
	return setmetatable({Connections = Connections; func = func}, Disconnector)
end

local function DisconnectSignal(self)
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a] = nil
	end
end

local function WaitSignal(self)
	local Connection
	Connection = ConnectSignal(self, function()
		Connection = DisconnectSignal(Connection)
	end)
	repeat until not Connection or not Wait(Heartbeat)
end

local function FireSignal(self, ...)
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a](...)
	end
end

local Signal = {
	Wait = WaitSignal;
	Fire = FireSignal;
	Press = FireSignal;
	Connect = ConnectSignal;
	Disconnect = DisconnectSignal;
}
Signal.__index = Signal

local function newSignal()
	return setmetatable({Connections = {}}, Signal)
end

-- Library & Input
local RegisteredKeys = {}
local Keys  = {}
local Mouse = {__newindex = PlayerMouse}
local Key = {}

function Key:__index(i)
	return self.KeyUp[i]
end

function Keys:__index(v)
	assert(type(v) == "string", "Table Keys should be indexed by a string")
	local Connections = setmetatable({
		KeyUp = newSignal();
		KeyDown = newSignal();
	}, Key)
	self[v] = Connections
	RegisteredKeys[v] = true
	return Connections
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
	local RegisteredKeys, FireSignal, Keys = RegisteredKeys, FireSignal, Keys
	return function(KeyName, processed)
		if not processed then
			KeyName = KeyName.KeyCode.Name
			if RegisteredKeys[KeyName] then
				FireSignal(Keys[KeyName][KeyEvent])
			end
		end
	end
end

local Enabled = false
local TimeAbsent = time() + 10
local WelcomeBack = newSignal()
local PlayerGuiBackup = Player:FindFirstChild("PlayerGuiBackup")
local NameDisplayDistance = Player.NameDisplayDistance
local HealthDisplayDistance = Player.HealthDisplayDistance
local Input = {
	AbsentThreshold = 14;
	CreateEvent = newSignal; -- Create a new event signal
	WelcomeBack = WelcomeBack;
	__newindex = InputService;
	Keys = setmetatable(Keys, Keys);
	Mouse = setmetatable(Mouse, Mouse);
}

if not PlayerGuiBackup then
	PlayerGuiBackup = Instance.new("Folder", Player)
	PlayerGuiBackup.Name = "GuiBackup"
end

local function WindowFocusReleased()
	TimeAbsent = time()
end

local function WindowFocused()
	local TimeAbsent = time() - TimeAbsent
	if TimeAbsent > Input.AbsentThreshold then
		FireSignal(WelcomeBack, TimeAbsent)
	end
end

local function HideGui()
	if not Enabled then
		Enabled = true
		InputService.MouseIconEnabled = false
		SetCore(StarterGui, "TopbarEnabled", false)
		Player.HealthDisplayDistance = 0
		Player.NameDisplayDistance = 0
		local Guis = GetChildren(PlayerGui)
		for a = 1, #Guis do
			local Gui = Guis[a]
			if Gui.ClassName == "ScreenGui" then
				Gui.Parent = PlayerGuiBackup
			end
		end
	else
		Enabled = false
		InputService.MouseIconEnabled = true
		SetCore(StarterGui, "TopbarEnabled", true)
		Player.HealthDisplayDistance = HealthDisplayDistance
		Player.NameDisplayDistance = NameDisplayDistance
		local Guis = GetChildren(PlayerGuiBackup)
		for a = 1, #Guis do
			Guis[a].Parent = PlayerGuiBackup
		end
	end
end

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

Connect(InputService.InputBegan, KeyInputHandler("KeyDown")) -- InputBegan listener
Connect(InputService.InputEnded, KeyInputHandler("KeyUp")) -- InputEnded listener
Connect(InputService.WindowFocusReleased, WindowFocusReleased)
Connect(InputService.WindowFocused, WindowFocused)
ConnectSignal(Keys.Underscore.KeyDown, HideGui)

return setmetatable(Input, Input)
