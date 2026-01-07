## Global class for sending/receiving signals, and handling processing of Stickey input system
extends Node

const KEYBOARD_INDEX: int = Stickey.KEYBOARD_INDEX
const MAX_INPUT_TYPES: int = Stickey.MAX_INPUT_TYPES
const MAX_INPUT_MASK_BITS: int = Stickey.MAX_INPUT_MASK_BITS

## Internal bitmask values for use with [member _key_to_axis_mask]
enum _StickBit {
	L_UP = 1,
	L_DOWN = 2,
	L_LEFT = 4,
	L_RIGHT = 8,
	R_UP = 16,
	R_DOWN = 32,
	R_LEFT = 64,
	R_RIGHT = 128
	}
## Joypad sticks
enum Stick {
	NONE = -1,
	LEFT = 0,
	RIGHT = 1,
	}

## Threshold for registering trigger as full button press (not deadzone).
## Value loaded from [ProjectSettings] on [method _init].
var trigger_press_threshold: float
## Threshold for registering trigger release.
## Value loaded from [ProjectSettings] on [method _init].
var trigger_release_threshold: float
## Mouse sensitivity when translated to stick axis.
## Value loaded from [ProjectSettings] on [method _init].
var mouse_sensitivity: float
## Decay for smoothing mouse movement (higher number results in quicker slow down).
## Value loaded from [ProjectSettings] on [method _init].
var mouse_decay: float
## Clamps fast mouse movement to this value (relative to max joystick movement of 1.0).
## Value loaded from [ProjectSettings] on [method _init].
var mouse_clamp: float
## When true keyboard device has been used more recently than [member keyboard_shared_device]
var is_keyboard_primary: bool = false
## Raw mouse motion
var mouse_raw := Vector2.ZERO
## Stick to translate mouse motion too
var mouse_stick: Stick = Stick.NONE
## Bitmask used internally for mapping keyboard to stick axis
var _key_to_axis_mask: int

## Emitted when device is connected
signal device_connected(index: int)
## Emitted when device is disconnected
signal device_disconnected(index: int)
## Emitted when [member keyboard_shared_device] swaps between keyboard and gamepad as current device
signal primary_device_changed(is_keyboard: bool)

func _init() -> void:
	trigger_press_threshold = ProjectSettings.get_setting("stickey_input/joystick/trigger/press_threshold", 0.5)
	trigger_release_threshold = ProjectSettings.get_setting("stickey_input/joystick/trigger/release_threshold", 0.7)
	StickeyDevice.left_stick_deadzone = ProjectSettings.get_setting("stickey_input/joystick/left_stick/deadzone", 0.05)
	StickeyDevice.right_stick_deadzone = ProjectSettings.get_setting("stickey_input/joystick/right_stick/deadzone", 0.05)
	StickeyDevice.trigger_deadzone = ProjectSettings.get_setting("stickey_input/joystick/trigger/deadzone", 0.3)
	mouse_sensitivity = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/sensitivity", 0.1)
	mouse_decay = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/decay_rate", 20.0)
	mouse_clamp = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/max_speed", 7.0)
	StickeyDevice.input_history_buffer_size = ProjectSettings.get_setting("stickey_input/general/input_history/buffer_frames", 60)
	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "Web":
			Stickey.devices[KEYBOARD_INDEX] = StickeyDevice.new(KEYBOARD_INDEX, &"Keyboard")
			is_keyboard_primary = Input.get_connected_joypads().is_empty()
		"Android", "iOS":
			Stickey.devices[KEYBOARD_INDEX] = StickeyDevice.new(KEYBOARD_INDEX, &"Handheld")
			is_keyboard_primary = Input.get_connected_joypads().is_empty()
		_:
			## This would be for custom console builds
			push_warning("OS not currently accounted for by Stickey Manager")
	_initialize_default_mappings()
	Input.joy_connection_changed.connect(_joy_connection_changed)
	for n in Stickey.MAX_INPUT_MASK_BITS:
		var path: String = "%s/%s"%[
		"stickey_input/input_nicknames",
		Stickey.get_input_type_string(n).replace("-", "").validate_filename().to_snake_case()
		]
		var value: String = ProjectSettings.get_setting(path, "")
		if !value.is_empty():
			if Stickey.input_nicknames.has(value):
				push_warning("Duplicate input nicknames '%s'!"%value)
			else:
				Stickey.input_nicknames.set(value, n)

func _process(delta: float) -> void:
	if mouse_raw != Vector2.ZERO && Input.get_last_mouse_screen_velocity() != Vector2.ZERO:
		mouse_raw = mouse_raw.lerp(Vector2.ZERO, delta * mouse_decay)
		if mouse_raw.is_equal_approx(Vector2.ZERO): mouse_raw = Vector2.ZERO
		match mouse_stick:
			Stick.LEFT:
				_update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, mouse_raw.x)
				_update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, mouse_raw.y)
			Stick.RIGHT:
				_update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, mouse_raw.x)
				_update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, mouse_raw.y)

func _physics_process(delta: float) -> void:
	for device: StickeyDevice in Stickey.devices.values():
		device.update_input_history()

func _notification(what: int) -> void:
	# On focus lost, reset inputs
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Stickey.stop_all_rumble()
		for index in Stickey.devices.keys():
			_update_axis(index, Stickey.AxisType.L_STICK_X, 0)
			_update_axis(index, Stickey.AxisType.L_STICK_Y, 0)
			_update_axis(index, Stickey.AxisType.R_STICK_X, 0)
			_update_axis(index, Stickey.AxisType.R_STICK_Y, 0)
			for input in Stickey.MAX_INPUT_MASK_BITS:
				if Stickey.devices[index].is_pressed(input):
					_update_button(index, input, false)
		if Stickey.devices.has(KEYBOARD_INDEX):
			_key_to_axis_mask = 0
			mouse_raw = Vector2.ZERO

func _joy_connection_changed(index: int, connected: bool) -> void:
	if connected:
		var device := StickeyDevice.new(index, Input.get_joy_name(index))
		Stickey.devices[index] = device
		device_connected.emit(index)
		print("Device connected: %s (%s)"%[device.display_name, index])
		if Stickey.keyboard_shared_device == index && is_keyboard_primary:
			is_keyboard_primary = false
			primary_device_changed.emit(false)
	else:
		device_disconnected.emit(index)
		print("Device disconnected: %s (%s)"%[Stickey.devices[index].display_name, index])
		if Stickey.keyboard_shared_device == index && !is_keyboard_primary:
			is_keyboard_primary = true
			primary_device_changed.emit(true)
		Stickey.devices.erase(index)

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	match event.get_class():
		"InputEventKey": _input_key(event)
		"InputEventMouseButton": _input_mouse_button(event)
		"InputEventMouseMotion": _input_mouse_motion(event)
		"InputEventJoypadButton": _input_joypad_button(event)
		"InputEventJoypadMotion": _input_joypad_motion(event)

## Loads [ConfigFile] with input mappings at the path of Project Setting "stickey_input/general/serialization/user_mappings_path"
## or loads default bindings from project settings if this [ConfigFile] cannot be found.
func _initialize_default_mappings() -> void:
	var mouse_motion_setting: int = ProjectSettings.get_setting("stickey_input/default_bindings/general/mouse_motion_input", Stick.RIGHT)
	match mouse_motion_setting:
		Stick.NONE, Stick.LEFT, Stick.RIGHT: mouse_stick = mouse_motion_setting
	var path: String = ProjectSettings.get_setting("stickey_input/general/serialization/user_mappings_path", "user://input_mappings.cfg")
	if FileAccess.file_exists(path):
		var config_file := ConfigFile.new()
		var err := config_file.load(path)
		if err == OK:
			Stickey.deserialize_input_mappings(config_file)
			return
		else: printerr("Unable to load user input mappings: %s"%error_string(err))
	Stickey.keyboard_mappings.clear()
	Stickey.mouse_mappings.clear()
	for n in Stickey.InputType.values():
		var default_keyboard: int = -1
		match n:
			Stickey.InputType.SOUTH: default_keyboard = KEY_SPACE
			Stickey.InputType.EAST: default_keyboard = KEY_E
			Stickey.InputType.WEST: default_keyboard = KEY_Q
			Stickey.InputType.NORTH: default_keyboard = KEY_R
			Stickey.InputType.BACK: default_keyboard = KEY_TAB
			Stickey.InputType.START: default_keyboard = KEY_ESCAPE
			Stickey.InputType.L_STICK_PRESS: default_keyboard = KEY_SHIFT
			Stickey.InputType.R_STICK_PRESS: default_keyboard = KEY_ALT
			Stickey.InputType.L_SHOULDER: default_keyboard = KEY_C
			Stickey.InputType.R_SHOULDER: default_keyboard = KEY_V
			Stickey.InputType.UP_DIRECTION: default_keyboard = KEY_UP
			Stickey.InputType.DOWN_DIRECTION: default_keyboard = KEY_DOWN
			Stickey.InputType.LEFT_DIRECTION: default_keyboard = KEY_LEFT
			Stickey.InputType.RIGHT_DIRECTION: default_keyboard = KEY_RIGHT
			Stickey.InputType.PADDLE_1: default_keyboard = KEY_F
			Stickey.InputType.PADDLE_2: default_keyboard = KEY_T
			Stickey.InputType.PADDLE_3: default_keyboard = KEY_G
			Stickey.InputType.PADDLE_4: default_keyboard = KEY_X
			Stickey.InputType.TOUCH_PAD: default_keyboard = KEY_Z
			Stickey.InputType.MISC_2: default_keyboard = KEY_1
			Stickey.InputType.MISC_3: default_keyboard = KEY_2
			Stickey.InputType.MISC_4: default_keyboard = KEY_3
			Stickey.InputType.MISC_5: default_keyboard = KEY_4
			Stickey.InputType.MISC_6: default_keyboard = KEY_5
			Stickey.InputType.MISC_7: default_keyboard = KEY_6
			Stickey.InputType.MISC_8: default_keyboard = KEY_7
			Stickey.InputType.MISC_9: default_keyboard = KEY_8
			Stickey.InputType.MISC_10: default_keyboard = KEY_9
			Stickey.InputType.L_STICK_UP: default_keyboard = KEY_W
			Stickey.InputType.L_STICK_DOWN: default_keyboard = KEY_S
			Stickey.InputType.L_STICK_LEFT: default_keyboard = KEY_A
			Stickey.InputType.L_STICK_RIGHT: default_keyboard = KEY_D
		var default_mouse: int = -1
		match n:
			Stickey.InputType.R_STICK_PRESS: default_mouse = MOUSE_BUTTON_MIDDLE
			Stickey.InputType.UP_DIRECTION: default_mouse = MOUSE_BUTTON_WHEEL_UP
			Stickey.InputType.DOWN_DIRECTION: default_mouse = MOUSE_BUTTON_WHEEL_DOWN
			Stickey.InputType.LEFT_DIRECTION: default_mouse = MOUSE_BUTTON_WHEEL_LEFT
			Stickey.InputType.RIGHT_DIRECTION: default_mouse = MOUSE_BUTTON_WHEEL_RIGHT
			Stickey.InputType.L_TRIGGER: default_mouse = MOUSE_BUTTON_RIGHT
			Stickey.InputType.R_TRIGGER: default_mouse = MOUSE_BUTTON_LEFT
		var setting_path: String = "%s/%s"%[
		"stickey_input/default_bindings/keyboard",
		Stickey.get_input_type_string(n).replace("-", "").validate_filename().to_snake_case()
		]
		var setting_value: int = ProjectSettings.get_setting(setting_path, default_keyboard)
		if setting_value != -1:
			if Stickey.keyboard_mappings.has(setting_value):
				push_warning("Keyboard mapping '%s' assigned to multiple inputs!"%OS.get_keycode_string(n))
			Stickey.keyboard_mappings[setting_value] = n
		setting_path = "%s/%s"%[
		"stickey_input/default_bindings/mouse",
		Stickey.get_input_type_string(n).replace("-", "").validate_filename().to_snake_case()
		]
		setting_value = ProjectSettings.get_setting(setting_path, default_mouse)
		if setting_value != -1:
			if Stickey.keyboard_mappings.has(setting_value):
				var mouse_string: String
				match n:
					MOUSE_BUTTON_LEFT: mouse_string = "Mouse Button Left"
					MOUSE_BUTTON_RIGHT: mouse_string = "Mouse Button Right"
					MOUSE_BUTTON_MIDDLE: mouse_string = "Mouse Button Middle"
					MOUSE_BUTTON_WHEEL_UP: mouse_string = "Mouse Wheel Up"
					MOUSE_BUTTON_WHEEL_DOWN: mouse_string = "Mouse Wheel Down"
					MOUSE_BUTTON_WHEEL_LEFT: mouse_string = "Mouse Wheel Left"
					MOUSE_BUTTON_WHEEL_RIGHT: mouse_string = "Mouse Wheel Right"
					MOUSE_BUTTON_XBUTTON1: mouse_string = "Mouse Extra Button 1"
					MOUSE_BUTTON_XBUTTON2: mouse_string = "Mouse Extra Button 2"
				push_warning("Mouse mapping '%s' assigned to multiple inputs!"%mouse_string)
			Stickey.mouse_mappings[setting_value] = n

## Handles [InputEvent] for keyboard
func _input_key(event: InputEventKey) -> void:
	if !Stickey.devices.has(Stickey.KEYBOARD_INDEX): return
	if !is_keyboard_primary:
		is_keyboard_primary = true
		primary_device_changed.emit(true)
	if Stickey.keyboard_mappings.has(event.keycode):
		_update_button(Stickey.KEYBOARD_INDEX, Stickey.keyboard_mappings[event.keycode], event.pressed)
		match Stickey.keyboard_mappings[event.keycode]:
			Stickey.InputType.L_TRIGGER: _update_axis(Stickey.KEYBOARD_INDEX, Stickey.AxisType.L_TRIGGER, float(event.pressed))
			Stickey.InputType.R_TRIGGER: _update_axis(Stickey.KEYBOARD_INDEX, Stickey.AxisType.R_TRIGGER, float(event.pressed))
			Stickey.InputType.L_STICK_UP:
				_update_key_axis(event.pressed, Stickey.AxisType.L_STICK_Y, _StickBit.L_UP, _StickBit.L_DOWN, -1)
			Stickey.InputType.L_STICK_DOWN:
				_update_key_axis(event.pressed, Stickey.AxisType.L_STICK_Y, _StickBit.L_DOWN, _StickBit.L_UP, 1)
			Stickey.InputType.L_STICK_LEFT:
				_update_key_axis(event.pressed, Stickey.AxisType.L_STICK_X, _StickBit.L_LEFT, _StickBit.L_RIGHT, -1)
			Stickey.InputType.L_STICK_RIGHT:
				_update_key_axis(event.pressed, Stickey.AxisType.L_STICK_X, _StickBit.L_RIGHT, _StickBit.L_LEFT, 1)
			Stickey.InputType.R_STICK_UP:
				_update_key_axis(event.pressed, Stickey.AxisType.R_STICK_Y, _StickBit.R_UP, _StickBit.R_DOWN, -1)
			Stickey.InputType.R_STICK_DOWN:
				_update_key_axis(event.pressed, Stickey.AxisType.R_STICK_Y, _StickBit.R_DOWN, _StickBit.R_UP, 1)
			Stickey.InputType.R_STICK_LEFT:
				_update_key_axis(event.pressed, Stickey.AxisType.R_STICK_X, _StickBit.R_LEFT, _StickBit.R_RIGHT, -1)
			Stickey.InputType.R_STICK_RIGHT:
				_update_key_axis(event.pressed, Stickey.AxisType.R_STICK_X, _StickBit.R_RIGHT, _StickBit.R_LEFT, 1)

## Handles [InputEvent] for mouse buttons
func _input_mouse_button(event: InputEventMouseButton) -> void:
	if !Stickey.devices.has(Stickey.KEYBOARD_INDEX): return
	if !is_keyboard_primary:
		is_keyboard_primary = true
		primary_device_changed.emit(true)
	if Stickey.mouse_mappings.has(event.button_index):
		_update_button(Stickey.KEYBOARD_INDEX, Stickey.mouse_mappings[event.button_index], event.pressed)
		match Stickey.mouse_mappings[event.button_index]:
			Stickey.InputType.L_TRIGGER: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_TRIGGER, float(event.pressed))
			Stickey.InputType.R_TRIGGER: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_TRIGGER, float(event.pressed))
			Stickey.InputType.L_STICK_UP: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, -float(event.pressed))
			Stickey.InputType.L_STICK_DOWN: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, float(event.pressed))
			Stickey.InputType.L_STICK_LEFT: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, -float(event.pressed))
			Stickey.InputType.L_STICK_RIGHT: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, float(event.pressed))
			Stickey.InputType.R_STICK_UP: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, -float(event.pressed))
			Stickey.InputType.R_STICK_DOWN: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, float(event.pressed))
			Stickey.InputType.R_STICK_LEFT: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, -float(event.pressed))
			Stickey.InputType.R_STICK_RIGHT: _update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, float(event.pressed))

## Handles [InputEvent] for mouse motion
func _input_mouse_motion(event: InputEventMouseMotion) -> void:
	if !Stickey.devices.has(KEYBOARD_INDEX): return
	mouse_raw = event.screen_relative * mouse_sensitivity
	mouse_raw = mouse_raw.clampf(-mouse_clamp, mouse_clamp)
	match mouse_stick:
		Stick.LEFT:
			_update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, mouse_raw.x)
			_update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, mouse_raw.y)
		Stick.RIGHT:
			_update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, mouse_raw.x)
			_update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, mouse_raw.y)

## Handles [InputEvent] for joy buttons
func _input_joypad_button(event: InputEventJoypadButton) -> void:
	if !Input.get_connected_joypads().has(event.device): return
	if event.device == Stickey.keyboard_shared_device && is_keyboard_primary:
		is_keyboard_primary = false
		primary_device_changed.emit(false)
	if Stickey.joy_remappings.has(event.button_index):
		_update_button(event.device, Stickey.joy_remappings[event.button_index], event.pressed)
	else:
		_update_button(event.device, int(event.button_index), event.pressed)

## Handles [InputEvent] for joy axes
func _input_joypad_motion(event: InputEventJoypadMotion) -> void:
	if !Input.get_connected_joypads().has(event.device): return
	if event.device == Stickey.keyboard_shared_device && is_keyboard_primary:
		is_keyboard_primary = false
		primary_device_changed.emit(false)
	_update_axis(event.device, int(event.axis), event.axis_value)
	# Update button masks
	match event.axis:
		JOY_AXIS_TRIGGER_LEFT:
			if Stickey.devices[event.device].is_pressed(Stickey.InputType.L_TRIGGER):
				if event.axis_value < trigger_release_threshold:
					_update_button(event.device, Stickey.InputType.L_TRIGGER, false)
			elif event.axis_value > trigger_press_threshold:
				_update_button(event.device, Stickey.InputType.L_TRIGGER, true)
		JOY_AXIS_TRIGGER_RIGHT:
			if Stickey.devices[event.device].is_pressed(Stickey.InputType.R_TRIGGER):
				if event.axis_value < trigger_release_threshold:
					_update_button(event.device, Stickey.InputType.R_TRIGGER, false)
			elif event.axis_value > trigger_press_threshold:
				_update_button(event.device, Stickey.InputType.R_TRIGGER, true)

## Updates device [member StickeyDevice.pressed_mask]
func _update_button(device: int, input: Stickey.InputType, pressed: bool) -> void:
	Stickey.devices[device].set_input_mask(input, pressed)
	# Send keyboard input to gamepad
	if device == KEYBOARD_INDEX && Stickey.keyboard_shared_device >= 0 && Stickey.devices.has(Stickey.keyboard_shared_device):
		_update_button(Stickey.keyboard_shared_device, input, pressed)

## Updates device axis values
func _update_axis(device: int, axis: Stickey.AxisType, value: float) -> void:
	match axis:
		Stickey.AxisType.L_STICK_X, Stickey.AxisType.L_STICK_Y, Stickey.AxisType.R_STICK_X, Stickey.AxisType.R_STICK_Y:
			if abs(value) < 1e-4: value = 0
	match axis:
		Stickey.AxisType.L_STICK_X:
			Stickey.devices[device].l_stick_raw.x = value
		Stickey.AxisType.L_STICK_Y:
			Stickey.devices[device].l_stick_raw.y = value
		Stickey.AxisType.R_STICK_X:
			Stickey.devices[device].r_stick_raw.x = value
		Stickey.AxisType.R_STICK_Y:
			Stickey.devices[device].r_stick_raw.y = value
		Stickey.AxisType.L_TRIGGER:
			Stickey.devices[device].l_trigger_raw = value
		Stickey.AxisType.R_TRIGGER:
			Stickey.devices[device].r_trigger_raw = value
	if device == KEYBOARD_INDEX && Stickey.keyboard_shared_device >= 0 && Stickey.devices.has(Stickey.keyboard_shared_device):
		_update_axis(Stickey.keyboard_shared_device, axis, value)

## Quick function for handling [member _key_to_axis_mask] value and updating axis 
func _update_key_axis(pressed: bool, axis: Stickey.AxisType, dir_bit: int, inv_dir_bit: int, multiplier: float) -> void:
	if pressed:
		_key_to_axis_mask |= dir_bit
		_update_axis(KEYBOARD_INDEX, axis, int(!_key_to_axis_mask & inv_dir_bit) * multiplier)
	else:
		_key_to_axis_mask &= ~dir_bit
		_update_axis(KEYBOARD_INDEX, axis, int(_key_to_axis_mask & inv_dir_bit) * -multiplier)
