extends Node

const KEYBOARD_INDEX: int = -1
const TRIGGER_PRESS_THRESHOLD: float = 0.7 # Should not be >= 1.0
const TRIGGER_RELEASE_THRESHOLD: float = 0.5 # Should not be <= 0.0
const STICK_INPUT_THRESHOLD: float = 0.0001 # Should not be <= 0.0
const STICK_DEADZONE: float = 0.05 # Should not be < 0.0
const TRIGGER_DEADZONE: float = 0.3 # Should not be < 0.0
const MOUSE_SENSITIVITY: float = 0.3 # Should be > 0.0
const MOUSE_DECAY: float = 10.0 # Should be > 0.0
const MOUSE_CLAMP: float = 5.0 # Should be >= 1.0
const SLOW_KEYBOARD_AXIS_MODIFIER = 0.5 # Should be > 0 and < 1
const INPUT_HISTORY_BUFFER_SIZE: int = 60 # Should be >= 1
const CONFIG_FILE_SECTION: StringName = &"InputMappings"

## Represents a connected device
class StickeyDevice extends RefCounted:
	## Device input index
	var index: int
	## Device display name
	var display_name: StringName
	## Gamepad type
	var type: GamepadType
	
	## Pressed input mask
	var pressed_mask: int = 0
	## Raw left stick direction
	var l_stick_raw := Vector2.ZERO
	## Raw right stick direction
	var r_stick_raw := Vector2.ZERO
	## Raw left trigger pressure
	var l_trigger_raw: float = 0.0
	## Raw right trigger pressure
	var r_trigger_raw: float = 0.0
	## Buffer of [member pressed_mask] sorted by physics process frame they were captured in
	var input_history: Dictionary[int,int] = {0:0}
	
	func _to_string() -> String: return "%s (%s)"%[display_name, index]
	## Returns debug info on current inputs
	func get_debug_input() -> String:
		return "LS:%s RS:%s LT:%s RT:%s B:%s"%[
			get_l_stick(), get_r_stick(), get_l_trigger(), get_r_trigger(), pressed_mask
			]
	## Returns true if input is pressed
	func is_pressed(input: InputType) -> bool:
		match input:
			InputType.L_STICK_UP: return l_stick_raw.x < 0
			InputType.L_STICK_DOWN: return l_stick_raw.x > 0
			InputType.L_STICK_LEFT: return l_stick_raw.y < 0
			InputType.L_STICK_RIGHT: return l_stick_raw.y > 0
			InputType.R_STICK_UP: return r_stick_raw.x < 0
			InputType.R_STICK_DOWN: return r_stick_raw.x > 0
			InputType.R_STICK_LEFT: return r_stick_raw.y < 0
			InputType.R_STICK_RIGHT: return r_stick_raw.y > 0
			_: return pressed_mask & (1 << input) != 0
	## Returns left stick direction
	func get_l_stick(normalized := true) -> Vector2:
		var length := l_stick_raw.length()
		if length <= STICK_DEADZONE: return Vector2.ZERO
		if normalized:
			return l_stick_raw.normalized()
		else:
			return l_stick_raw
	## Returns right stick direction
	func get_r_stick(normalized := true) -> Vector2:
		var length := r_stick_raw.length()
		if length <= STICK_DEADZONE: return Vector2.ZERO
		if normalized:
			return r_stick_raw.normalized()
		else:
			return r_stick_raw
	## Returns left trigger pressure
	func get_l_trigger() -> float:
		if l_trigger_raw <= TRIGGER_DEADZONE: return 0
		else: return l_trigger_raw
	## Returns right trigger pressure
	func get_r_trigger() -> float:
		if r_trigger_raw <= TRIGGER_DEADZONE: return 0
		else: return r_trigger_raw
	## Applies vibration to gamepad
	func rumble(weak_magnitude: float = 0.5, strong_magnitude: float = 0.3, length: float = 0.1) -> void:
		if index < 0: return
		Input.start_joy_vibration(index, weak_magnitude, strong_magnitude, length)
	## Returns input mask from [param frames_ago] physics process frames. 
	## If older than buffer history, returns 0.
	func get_old_input_mask(frames_ago: int) -> int:
		var search_frame: int = Engine.get_physics_frames() - frames_ago
		if input_history.has(search_frame): return input_history[search_frame]
		var keys := input_history.keys()
		if keys[keys.size() - 1] < search_frame: return input_history[keys[keys.size() - 1]]
		elif keys[0] > search_frame: return 0
		var result: int = 0
		for i in keys.size():
			if i > search_frame: break
			result = input_history[keys[i]]
		return result
	## Gives the age of the oldest physics frame in the [member input_history] buffer.
	## Returns -1 if no current input history.
	func get_age_of_history() -> int:
		return Engine.get_physics_frames() - input_history.keys()[0]
	## Checks if input was pressed [param frames_ago] physics process frames.
	## Doesn't work for detecting stick directions.
	func was_pressed(input: InputType, frames_ago: int) -> bool:
		if input > 31: return false
		return get_old_input_mask(frames_ago) & (1 << input) != 0
	## Checks if input was released from pressed state [param frames_ago] physics process frames.
	## Doesn't work for detecting stick directions.
	func was_released(input: InputType, frames_ago: int) -> bool:
		if input > 31: return false
		var was_pressed: bool = false
		for i in frames_ago:
			if was_pressed:
				was_pressed = was_pressed(input, i)
			elif !was_pressed(input, i): return true
		return false
	## Returns true if input was pressed for [param frames_ago] physics process frames.
	## Doesn't work for detecting stick directions.
	func was_held(input: InputType, frames_ago: int) -> bool:
		if input > 31: return false
		for i in frames_ago:
			if !was_pressed(input, i): return false
		return true

## Button inputs
enum InputType {
	SOUTH = 0, 				# Bottom face button / Xbox: A Button
	EAST = 1, 				# Right face button / Xbox: B Button
	WEST = 2, 				# Left face button / Xbox: X Button
	NORTH = 3, 				# Top face button / Xbox: Y Button
	BACK = 4,
	GUIDE = 5,
	START = 6,
	L_STICK = 7,
	R_STICK = 8,
	L_SHOULDER = 9,
	R_SHOULDER = 10,
	UP_DIRECTION = 11,		# Directional pad up
	DOWN_DIRECTION = 12,	# Directional pad down
	LEFT_DIRECTION = 13,	# Directional pad left
	RIGHT_DIRECTION = 14,	# Directional pad right
	MISC_1 = 15, 			# Share, Microphone, Capture button
	PADDLE_1 = 16, 			# Upper right paddle
	PADDLE_2 = 17, 			# Upper left paddle
	PADDLE_3 = 18, 			# Lower right paddle
	PADDLE_4 = 19, 			# Lower left paddle
	TOUCH_PAD = 20, 		# Playstation touchpad
	MISC_2 = 21, 			# SDL3 button, not currently used by Godot Input!
	MISC_3 = 22, 			# SDL3 button, not currently used by Godot Input!
	MISC_4 = 23, 			# SDL3 button, not currently used by Godot Input!
	MISC_5 = 24, 			# SDL3 button, not currently used by Godot Input!
	MISC_6 = 25, 			# SDL3 button, not currently used by Godot Input!
	MISC_7 = 26,			# Non-gamepad accessible button
	MISC_8 = 27,			# Non-gamepad accessible button
	MISC_9 = 28,			# Non-gamepad accessible button
	MISC_10 = 29,			# Non-gamepad accessible button
	L_TRIGGER = 30, 		# Pseudo button for left trigger axis
	R_TRIGGER = 31, 		# Pseudo button for right trigger axis
	L_STICK_UP = 60,		# Pseudo button for left stick axis Y (not recorded to input mask)
	L_STICK_DOWN = 61,		# Pseudo button for left stick axis Y (not recorded to input mask)
	L_STICK_LEFT = 62,		# Pseudo button for left stick axis X (not recorded to input mask)
	L_STICK_RIGHT = 63,		# Pseudo button for left stick axis X (not recorded to input mask)
	R_STICK_UP = 64,		# Pseudo button for right stick axis Y (not recorded to input mask)
	R_STICK_DOWN = 65,		# Pseudo button for right stick axis Y (not recorded to input mask)
	R_STICK_LEFT = 66,		# Pseudo button for right stick axis X (not recorded to input mask)
	R_STICK_RIGHT = 67,		# Pseudo button for right stick axis X (not recorded to input mask)
	}
## Axis inputs
enum AxisType {
	L_STICK_X = 0,
	L_STICK_Y = 1,
	R_STICK_X = 2,
	R_STICK_Y = 3,
	L_TRIGGER = 4,
	R_TRIGGER = 5,
	}
## Joypad sticks
enum Stick {
	NONE = -1,
	LEFT = 0,
	RIGHT = 1,
	}
## Helper to determine type of device for UI
enum GamepadType {
	GENERIC,
	XBOX,
	SWITCH,
	PLAYSTATION,
	}

## Connected devices, including keyboard
var devices: Dictionary[int, StickeyDevice]
## Device index to share keyboard input with-- use -1 to not share
var keyboard_shared_device: int = 0
## Raw mouse motion
var mouse_raw := Vector2.ZERO
## Stick to translate mouse motion too
var mouse_stick: Stick = Stick.RIGHT
## Key mappings for inputs
var keyboard_mappings: Dictionary[Key, InputType]
## Mouse button mappings for inputs
var mouse_mappings: Dictionary[MouseButton, InputType]

## Emitted when device is connected
signal device_connected(index: int)
## Emitted when device is disconnected
signal device_disconnected(index: int)

func _init() -> void:
	devices[KEYBOARD_INDEX] = StickeyDevice.new()
	devices[KEYBOARD_INDEX].index = KEYBOARD_INDEX
	devices[KEYBOARD_INDEX].display_name = &"Keyboard"
	_initialize_default_keyboard_mappings()
	Input.joy_connection_changed.connect(_joy_connection_changed)

func _joy_connection_changed(index: int, connected: bool) -> void:
	if connected:
		var device := StickeyDevice.new()
		device.index = index
		device.display_name = Input.get_joy_name(index)
		if device.display_name.contains("Xbox"): device.type = GamepadType.XBOX
		elif device.display_name.contains("Switch"): device.type = GamepadType.SWITCH
		elif device.display_name.contains("PS"): device.type = GamepadType.PLAYSTATION
		else: device.type = GamepadType.GENERIC
		devices[index] = device
		device_connected.emit(index)
		print("Device connected: %s (%s)"%[device.display_name, index])
	else:
		device_disconnected.emit(index)
		print("Device disconnected: %s (%s)"%[devices[index].display_name, index])
		devices.erase(index)

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	match event.get_class():
		"InputEventKey":
			if keyboard_mappings.has(event.keycode):
				_update_button(KEYBOARD_INDEX, keyboard_mappings[event.keycode], event.pressed)
				match keyboard_mappings[event.keycode]:
					InputType.L_TRIGGER: _update_axis(KEYBOARD_INDEX, AxisType.L_TRIGGER, float(event.pressed))
					InputType.R_TRIGGER: _update_axis(KEYBOARD_INDEX, AxisType.R_TRIGGER, float(event.pressed))
					InputType.L_STICK_UP: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, -float(event.pressed))
					InputType.L_STICK_DOWN: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, float(event.pressed))
					InputType.L_STICK_LEFT: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, -float(event.pressed))
					InputType.L_STICK_RIGHT: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, float(event.pressed))
					InputType.R_STICK_UP: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, -float(event.pressed))
					InputType.R_STICK_DOWN: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, float(event.pressed))
					InputType.R_STICK_LEFT: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, -float(event.pressed))
					InputType.R_STICK_RIGHT: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, float(event.pressed))
				return
		"InputEventMouseButton":
			if mouse_mappings.has(event.button_index):
				_update_button(KEYBOARD_INDEX, mouse_mappings[event.button_index], event.pressed)
				match mouse_mappings[event.button_index]:
					InputType.L_TRIGGER: _update_axis(KEYBOARD_INDEX, AxisType.L_TRIGGER, float(event.pressed))
					InputType.R_TRIGGER: _update_axis(KEYBOARD_INDEX, AxisType.R_TRIGGER, float(event.pressed))
					InputType.L_STICK_UP: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, -float(event.pressed))
					InputType.L_STICK_DOWN: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, float(event.pressed))
					InputType.L_STICK_LEFT: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, -float(event.pressed))
					InputType.L_STICK_RIGHT: _update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, float(event.pressed))
					InputType.R_STICK_UP: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, -float(event.pressed))
					InputType.R_STICK_DOWN: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, float(event.pressed))
					InputType.R_STICK_LEFT: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, -float(event.pressed))
					InputType.R_STICK_RIGHT: _update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, float(event.pressed))
		"InputEventMouseMotion":
			mouse_raw = event.relative * MOUSE_SENSITIVITY
			mouse_raw = mouse_raw.clampf(-MOUSE_CLAMP, MOUSE_CLAMP)
			match mouse_stick:
				Stick.LEFT:
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, mouse_raw.y)
				Stick.RIGHT:
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, mouse_raw.y)
		"InputEventJoypadButton":
			if !Input.get_connected_joypads().has(event.device): return
			_update_button(event.device, event.button_index, event.pressed)
		"InputEventJoypadMotion":
			if !Input.get_connected_joypads().has(event.device): return
			_update_axis(event.device, event.axis, event.axis_value)
			# Update button masks
			match event.axis:
				JOY_AXIS_TRIGGER_LEFT:
					if devices[event.device].is_pressed(InputType.L_TRIGGER):
						if event.axis_value < TRIGGER_RELEASE_THRESHOLD:
							_update_button(event.device, InputType.L_TRIGGER, false)
					elif event.axis_value > TRIGGER_PRESS_THRESHOLD:
						_update_button(event.device, InputType.L_TRIGGER, true)
				JOY_AXIS_TRIGGER_RIGHT:
					if devices[event.device].is_pressed(InputType.R_TRIGGER):
						if event.axis_value < TRIGGER_RELEASE_THRESHOLD:
							_update_button(event.device, InputType.R_TRIGGER, false)
					elif event.axis_value > TRIGGER_PRESS_THRESHOLD:
						_update_button(event.device, InputType.R_TRIGGER, true)

func _process(delta: float) -> void:
	if Input.get_last_mouse_velocity() == Vector2.ZERO && mouse_raw != Vector2.ZERO:
		mouse_raw = mouse_raw.move_toward(Vector2.ZERO, MOUSE_DECAY * MOUSE_CLAMP * delta)
		match mouse_stick:
				Stick.LEFT:
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, mouse_raw.y)
				Stick.RIGHT:
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, mouse_raw.y)

## Set default keyboard mappings
func _initialize_default_keyboard_mappings() -> void:
	keyboard_mappings[KEY_SPACE] = InputType.SOUTH
	keyboard_mappings[KEY_E] = InputType.EAST
	keyboard_mappings[KEY_Q] = InputType.WEST
	keyboard_mappings[KEY_F] = InputType.NORTH
	
	keyboard_mappings[KEY_TAB] = InputType.BACK
	keyboard_mappings[KEY_ESCAPE] = InputType.START
	
	keyboard_mappings[KEY_UP] = InputType.UP_DIRECTION
	keyboard_mappings[KEY_1] = InputType.UP_DIRECTION
	keyboard_mappings[KEY_DOWN] = InputType.DOWN_DIRECTION
	keyboard_mappings[KEY_3] = InputType.DOWN_DIRECTION
	keyboard_mappings[KEY_LEFT] = InputType.LEFT_DIRECTION
	keyboard_mappings[KEY_4] = InputType.LEFT_DIRECTION
	keyboard_mappings[KEY_RIGHT] = InputType.RIGHT_DIRECTION
	keyboard_mappings[KEY_2] = InputType.RIGHT_DIRECTION
	
	keyboard_mappings[KEY_ALT] = InputType.L_SHOULDER
	keyboard_mappings[KEY_CTRL] = InputType.R_SHOULDER
	
	keyboard_mappings[KEY_C] = InputType.L_STICK
	keyboard_mappings[KEY_V] = InputType.R_STICK
	
	keyboard_mappings[KEY_P] = InputType.MISC_1
	keyboard_mappings[KEY_Z] = InputType.PADDLE_1
	keyboard_mappings[KEY_X] = InputType.PADDLE_2
	keyboard_mappings[KEY_B] = InputType.PADDLE_3
	keyboard_mappings[KEY_N] = InputType.PADDLE_4
	keyboard_mappings[KEY_T] = InputType.TOUCH_PAD
	
	keyboard_mappings[KEY_5] = InputType.MISC_2
	keyboard_mappings[KEY_6] = InputType.MISC_3
	keyboard_mappings[KEY_7] = InputType.MISC_4
	keyboard_mappings[KEY_8] = InputType.MISC_5
	keyboard_mappings[KEY_9] = InputType.MISC_6
	
	mouse_mappings[MOUSE_BUTTON_LEFT] = InputType.L_TRIGGER
	mouse_mappings[MOUSE_BUTTON_RIGHT] = InputType.R_TRIGGER
	
	mouse_mappings[MOUSE_BUTTON_WHEEL_UP] = InputType.UP_DIRECTION
	mouse_mappings[MOUSE_BUTTON_WHEEL_DOWN] = InputType.DOWN_DIRECTION
	
	keyboard_mappings[KEY_W] = InputType.L_STICK_UP
	keyboard_mappings[KEY_A] = InputType.L_STICK_LEFT
	keyboard_mappings[KEY_S] = InputType.L_STICK_DOWN
	keyboard_mappings[KEY_D] = InputType.L_STICK_RIGHT

## Updates device [member StickeyDevice.pressed_mask]
func _update_button(device: int, input: InputType, pressed: bool) -> void:
	if input > 31: return
	var bit := 1 << int(input)
	if pressed: devices[device].pressed_mask |= bit
	else: devices[device].pressed_mask &= ~bit
	# Update buffer histroy
	devices[device].input_history[Engine.get_physics_frames()] = devices[device].pressed_mask
	if devices[device].input_history.size() > INPUT_HISTORY_BUFFER_SIZE:
		devices[device].input_history.erase(devices[device].input_history.keys()[0])
	# Send keyboard input to gamepad
	if device == KEYBOARD_INDEX && keyboard_shared_device >= 0 && devices.has(keyboard_shared_device):
		_update_button(keyboard_shared_device, input, pressed)

## Updates device axis values
func _update_axis(device: int, axis: AxisType, value: float) -> void:
	match axis:
		AxisType.L_STICK_X, AxisType.L_STICK_Y, AxisType.R_STICK_X, AxisType.R_STICK_Y:
			if abs(value) < STICK_INPUT_THRESHOLD: value = 0
	match axis:
		AxisType.L_STICK_X:
			devices[device].l_stick_raw.x = value
		AxisType.L_STICK_Y:
			devices[device].l_stick_raw.y = value
		AxisType.R_STICK_X:
			devices[device].r_stick_raw.x = value
		AxisType.R_STICK_Y:
			devices[device].r_stick_raw.y = value
		AxisType.L_TRIGGER:
			devices[device].l_trigger_raw = value
		AxisType.R_TRIGGER:
			devices[device].r_trigger_raw = value
	if device == KEYBOARD_INDEX && keyboard_shared_device >= 0 && devices.has(keyboard_shared_device):
		_update_axis(keyboard_shared_device, axis, value)

## Stop vibrations on all devices
func stop_all_rumble() -> void:
	for joypad in Input.get_connected_joypads(): Input.stop_joy_vibration(joypad)

## Returns string for [enum InputType]
func get_input_type_string(input: InputType) -> String:
	match input:
		InputType.SOUTH: return "South"
		InputType.EAST: return "East"
		InputType.WEST: return "West"
		InputType.NORTH: return "North"
		InputType.BACK: return "Back"
		InputType.GUIDE: return "Guide"
		InputType.START: return "Start"
		InputType.L_STICK: return "Left Stick"
		InputType.R_STICK: return "Right Stick"
		InputType.L_SHOULDER: return "Left Shoulder"
		InputType.R_SHOULDER: return "Right Shoulder"
		InputType.UP_DIRECTION: return "D-Pad Up"
		InputType.DOWN_DIRECTION: return "D-Pad Down"
		InputType.LEFT_DIRECTION: return "D-Pad Left"
		InputType.RIGHT_DIRECTION: return "D-Pad Right"
		InputType.MISC_1: return "Misc 1"
		InputType.PADDLE_1: return "Paddle 1"
		InputType.PADDLE_2: return "Paddle 2"
		InputType.PADDLE_3: return "Paddle 3"
		InputType.PADDLE_4: return "Paddle 4"
		InputType.TOUCH_PAD: return "Touch Pad"
		InputType.MISC_2: return "Misc 2"
		InputType.MISC_3: return "Misc 3"
		InputType.MISC_4: return "Misc 4"
		InputType.MISC_5: return "Misc 5"
		InputType.MISC_6: return "Misc 6"
		InputType.MISC_7: return "Misc 7"
		InputType.MISC_8: return "Misc 8"
		InputType.MISC_9: return "Misc 9"
		InputType.MISC_10: return "Misc 10"
		InputType.L_TRIGGER: return "Left Trigger"
		InputType.R_TRIGGER: return "Right Trigger"
		_: return "Invalid"

## Returns string for [enum AxisType]
func get_axis_type_string(axis: AxisType) -> String:
	match axis:
		AxisType.L_STICK_X: return "Left Stick X"
		AxisType.L_STICK_Y: return "Left Stick Y"
		AxisType.R_STICK_X: return "Right Stick X"
		AxisType.R_STICK_Y: return "Right Stick Y"
		AxisType.L_TRIGGER: return "Left Trigger"
		AxisType.R_TRIGGER: return "Right Trigger"
		_: return "Invalid"

## Creates a [ConfigFile] for serializing input bindings.
## This can later be loaded with [method deserialize_input_mappings].
func serialize_input_mappings() -> ConfigFile:
	var bindings: Dictionary[InputType, PackedStringArray]
	for key in keyboard_mappings:
		if !bindings.has(keyboard_mappings[key]): bindings[keyboard_mappings[key]] = []
		bindings[keyboard_mappings[key]].append(OS.get_keycode_string(key))
	for button in mouse_mappings:
		if !bindings.has(mouse_mappings[button]): bindings[mouse_mappings[button]] = []
		match button:
			MOUSE_BUTTON_LEFT: bindings[mouse_mappings[button]].append("MouseLeft")
			MOUSE_BUTTON_RIGHT: bindings[mouse_mappings[button]].append("MouseRight")
			MOUSE_BUTTON_MIDDLE: bindings[mouse_mappings[button]].append("MouseMiddle")
			MOUSE_BUTTON_WHEEL_UP: bindings[mouse_mappings[button]].append("MouseWheelUp")
			MOUSE_BUTTON_WHEEL_DOWN: bindings[mouse_mappings[button]].append("MouseWheelDown")
			MOUSE_BUTTON_WHEEL_LEFT: bindings[mouse_mappings[button]].append("MouseWheelLeft")
			MOUSE_BUTTON_WHEEL_RIGHT: bindings[mouse_mappings[button]].append("MouseWheelRight")
			MOUSE_BUTTON_XBUTTON1: bindings[mouse_mappings[button]].append("MouseExtra1")
			MOUSE_BUTTON_XBUTTON2: bindings[mouse_mappings[button]].append("MouseExtra2")
			_: bindings[mouse_mappings[button]].append("MouseUnknown")
	var output := ConfigFile.new()
	for input in bindings.keys():
		output.set_value(CONFIG_FILE_SECTION, get_input_type_string(input), bindings[input])
	return output

## Deserializes input bindings from a [ConfigFile].
## This will overwrite [member keyboard_mappings] and [member mouse_mappings].
func deserialize_input_mappings(config: ConfigFile) -> void:
	keyboard_mappings.clear()
	mouse_mappings.clear()
	var bindings: Dictionary[InputType, PackedStringArray]
	for key in config.get_section_keys(CONFIG_FILE_SECTION):
		var key_type: int = -1
		for input in 32:
			if get_input_type_string(input) == key:
				key_type = input
				break
		if key_type == -1: continue
		bindings[key_type] = config.get_value(CONFIG_FILE_SECTION, key, []) as PackedStringArray
	for input in bindings.keys():
		for n in bindings[input].size():
			if bindings[input][n].begins_with("Mouse"):
				match bindings[input][n]:
					"MouseLeft": mouse_mappings[MOUSE_BUTTON_LEFT] = input
					"MouseRight": mouse_mappings[MOUSE_BUTTON_RIGHT] = input
					"MouseMiddle": mouse_mappings[MOUSE_BUTTON_MIDDLE] = input
					"MouseWheelUp": mouse_mappings[MOUSE_BUTTON_WHEEL_UP] = input
					"MouseWheelDown": mouse_mappings[MOUSE_BUTTON_WHEEL_DOWN] = input
					"MouseWheelLeft": mouse_mappings[MOUSE_BUTTON_WHEEL_LEFT] = input
					"MouseWheelRight": mouse_mappings[MOUSE_BUTTON_WHEEL_RIGHT] = input
					"MouseExtra1": mouse_mappings[MOUSE_BUTTON_XBUTTON1] = input
					"MouseExtra2": mouse_mappings[MOUSE_BUTTON_XBUTTON2] = input
					_: mouse_mappings[MOUSE_BUTTON_NONE] = input
			else:
				keyboard_mappings[OS.find_keycode_from_string(bindings[input][n])] = input
