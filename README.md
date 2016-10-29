#UserInputService
This module is table wrapper designed to make interacting with UserInput easier and more readable.
This module allows you to connect functions to certain events without the need
to actually call the UserInputService, or compare any Enum codes to input
objects. This is both faster to reference, and considerably more readable
to the writer.

##API
```javascript
class UserInputService
	Properties

		table/PlayerMouse Mouse
//			returns the LocalPlayer's Mouse with added API (demonstrated below)

		table Keys
//			Similar to Mouse, you can access Keys from this table
```
##Key events

Key events are stored inside a table called "Keys", which you can access directly
from the module. Once you've accessed this table, you can index it for any input type that exists
in the KeyCode Enum element. For example, if you wanted to create an event for
the key "Q", you'd simply write that:

```lua
local UserInputService = require(UserInputServiceModule)
local Keys = UserInputService.Keys
local QDown = Keys.Q.KeyDown

local QPress = Q:Connect(function()
	print("Q was pressed")
end)

-- Manual Fire
Q:Press() -- Same as Q:Fire()

Q:Disconnect() -- disconnect everything binded to Q.KeyDown
QPress:Disconnect() -- disconnect one connection

-- Wait until the player presses
Q:Wait()
```
Each key has a "KeyUp" and "KeyDown" event that comes with it. So you can't just
connect the key to an event, you must specify if the event will fire on KeyUp
or on KeyDown.

Note: KeyUp and KeyDown events do not involve the deprecated methods of PlayerMouse.

## Mouse events
Mouse events remain the same as just creating them normally on the real
PlayerMouse object. For example, creating a Button1Down event would be
done like so:

```lua
local UserInputService = require(UserInputServiceModule)
local Mouse = UserInputService.Mouse
local Button1Down = Mouse.Button1Down

local LeftClick = Button1Down:Connect(function()
	print("Button was clicked")
end)

-- And of course you could fire it manually, since it returns a custom event
Button1Down:Fire()

Button1Down:Disconnect() -- Disconnect all connections binded to this event
LeftClick:Disconnect() -- Disconnect the one connection

Button1Down:Wait() -- Wait for the Event to happen
```
