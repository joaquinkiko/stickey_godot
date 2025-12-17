# SticKey Godot

Advanced input manager

This plugin is designed for **[Godot 4.5+](https://godotengine.org/download)**

## TODO:
- Don't call button pressed every frame that axis is updated
- Project settings for constants
- Keyboard default bindings project settings
- Mouse scroll doesn't currently work
- Coyote time press (pressed in last x-frames/seconds)
- Keyboard bindings serializing / deserializing
- Gamepad alternate mappings (translate button to different button)
- Axis modifiers (invert-Y, slow axis movement)
- Simulated input for remote devices / serialize and deserialize input over network
- Last input source (keyboard or shared gamepad) plus signal
- Force stop all rumble function
- Reset / clear settings function
- List action keybindings function
- Controller icons: gamepad / button / 
- Keyboard and mouse icons
- Get action icon(s)
- Get action input key/button display name
- Extend to max of 32 input actions
- Pause input reading per device
- Control mouse with gamepad
- Gamepad based typing pop-up
- Steam input / remote play support
- Automatic cursor display / hide / locking
- Don't accept input while not in focus
- Touch based input / vibration
- Disable keyboard for non PC devices
- Key rebinding helper (Max alternative bindings per action, should swap old action, should allow WASD)
- Add/remove player
- Assign devices to players
- signal if player disconnects device
- Reassign controller to player
- Per player color
- Modify input color by player color
- Player display name for debug logging