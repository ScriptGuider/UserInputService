#UserInputService
This module is table wrapper designed to make interacting with UserInput easier and more readable.
This module allows you to connect functions to certain events without the need
to actually call the UserInputService, or compare any Enum codes to input
objects. This is both faster to reference, and considerably more readable
to the writer.

##API
```javascript
class UserInputService
  table CreateEvent()
//	Returns a Custom Event that imitates ROBLOX's BindableEvents, giving you the ability to connect, disconnect,
//	wait, and fire the custom event whenever you want.

PlayerMouse GetMouse()
//  Returns the LocalPlayer's PlayerMouse object

```
##Key events

Key events are stored inside a table called "Keys", which you can access directly
from the module. Once you've accessed this table, you can index it for any input type that exists
in the KeyCode Enum element. For example, if you wanted to create an event for
the key "Q", you'd simply write that:

```lua
local UserInputService = require(UserInputServiceModule)
local Keys = UserInputService.Keys
local Q = Keys.Q

local QPress = Q.KeyDown:connect(function()
	print("Q was pressed")
end)

-- Manual fire
Q.KeyDown:Fire()

Q.KeyDown:disconnect() -- disconnect everything binded to Q.KeyDown
QPress:disconnect() -- disconnect one connection

-- Wait until the player presses
Q.KeyDown:wait()
```
Each key has a "KeyUp" and "KeyDown" event that comes with it. So you can't just
connect the key to an event, you must specify if the event will fire on KeyUp
or on KeyDown.

Note: KeyUp and KeyDown events do not involve the deprecated methods of PlayerMouse.

##Mouse events
Mouse events remain the same as just creating them normally on the real
PlayerMouse object. For example, creating a Button1Down event would be
done like so:

```lua
local UserInputService = require(UserInputServiceModule)
local Mouse = UserInputService.Mouse

local LeftClick = Mouse.Button1Down:connect(function()
	print("Button was clicked")
end)

-- And of course you could fire it manually, since it returns a custom event
Mouse.Button1Down:Fire()

Mouse.Button1Down:disconnect() -- Disconnect all connections binded to this event
LeftClick:disconnect() -- Disconnect the one connection

Mouse.Button1Down:wait() -- Wait for the Event to happen
```
