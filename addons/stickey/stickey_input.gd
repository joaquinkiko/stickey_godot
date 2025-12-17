extends Node

const KEYBOARD_INDEX: int = -1
const TRIGGER_PRESS_THRESHOLD: float = 0.7 # Should not be >= 1.0
const TRIGGER_RELEASE_THRESHOLD: float = 0.5 # Should not be <= 0.0
const STICK_INPUT_THRESHOLD: float = 0.001 # Should not be <= 0.0
const STICK_DEADZONE: float = 0.3 # Should not be < 0.0
const TRIGGER_DEADZONE: float = 0.3 # Should not be < 0.0
const MOUSE_SENSITIVITY: float = 0.3 # Should be > 0.0
const MOUSE_DECAY: float = 10.0 # Should be > 0.0
const MOUSE_CLAMP: float = 5.0 # Should be >= 1.0
const SLOW_KEYBOARD_AXIS_MODIFIER = 0.5 # Should be > 0 and < 1

## Represents a connected device
class StickeyDevice extends RefCounted:
	## Device input index
	var index: int
	## Device display name
	var display_name: StringName
	## Pressed input mask
	var pressed_mask: int
	## Raw left stick direction
	var l_stick_raw: Vector2
	## Raw right stick direction
	var r_stick_raw: Vector2
	## Raw left trigger pressure
	var l_trigger_raw: float
	## Raw right trigger pressure
	var r_trigger_raw: float
	
	## Returns true if input is pressed
	func is_pressed(input: InputType) -> bool:
		return pressed_mask & (1 << input) != 0
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

## Button inputs
enum InputType {
	NONE = -1,
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
	L_TRIGGER = 30, 		# Pseudo button for left trigger axis
	R_TRIGGER = 31, 		# Pseudo button for right trigger axis
}
## Axis inputs
enum AxisType {
	NONE = -1,
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

## Connected devices, including keyboard
var devices: Dictionary[int, StickeyDevice]
## Device index to share keyboard input with-- use -1 to not share
var keyboard_shared_device: int = 0
## Raw mouse motion
var mouse_raw := Vector2.ZERO
## Stick to translate mouse motion too
var mouse_stick: Stick = Stick.RIGHT
## Stick to translate WASD keys too
var wasd_stick: Stick = Stick.LEFT
## Stick to translate directional keys too
var directional_keys_stick: Stick = Stick.NONE
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
			# Handle keyboard mapped axis
			match event.keycode:
				# Handle WASD mapped axis
				KEY_W, KEY_A, KEY_S, KEY_D:
					if wasd_stick != Stick.NONE:
						match event.keycode:
							KEY_W:
								match wasd_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, -int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, -int(event.pressed))
							KEY_S:
								match wasd_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, int(event.pressed))
							KEY_A:
								match wasd_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, -int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, -int(event.pressed))
							KEY_D:
								match wasd_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, int(event.pressed))
						return
				# Handle directional key mapped axis
				KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
					if directional_keys_stick != Stick.NONE:
						match event.keycode:
							KEY_UP:
								match directional_keys_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, -int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, -int(event.pressed))
							KEY_DOWN:
								match directional_keys_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, int(event.pressed))
							KEY_LEFT:
								match directional_keys_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, -int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, -int(event.pressed))
							KEY_RIGHT:
								match directional_keys_stick:
									Stick.LEFT:
										_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, int(event.pressed))
									Stick.RIGHT:
										_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, int(event.pressed))
						return
			# Handle mapped input events
			if keyboard_mappings.has(event.keycode):
				_update_button(KEYBOARD_INDEX, keyboard_mappings[event.keycode], event.pressed)
				return
		"InputEventMouseButton":
			if mouse_mappings.has(event.button_index):
				_update_button(KEYBOARD_INDEX, mouse_mappings[event.button_index], event.pressed)
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
	
	mouse_mappings[MouseButton.MOUSE_BUTTON_LEFT] = InputType.L_TRIGGER
	mouse_mappings[MouseButton.MOUSE_BUTTON_RIGHT] = InputType.R_TRIGGER
	
	mouse_mappings[MouseButton.MOUSE_BUTTON_WHEEL_UP] = InputType.UP_DIRECTION
	mouse_mappings[MouseButton.MOUSE_BUTTON_WHEEL_DOWN] = InputType.DOWN_DIRECTION

## Updates device [member StickeyDevice.pressed_mask]
func _update_button(device: int, input: InputType, pressed: bool) -> void:
	var bit := 1 << int(input)
	if pressed: devices[device].pressed_mask |= bit
	else: devices[device].pressed_mask &= ~bit
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
