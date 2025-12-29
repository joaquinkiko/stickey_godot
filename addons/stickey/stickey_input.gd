extends Node

const KEYBOARD_INDEX: int = -1
const MAX_INPUT_TYPES: int = 64

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
	var input_history: PackedInt32Array
	## Current index in [member input_history]
	var input_history_index: int = 0
	
	func _to_string() -> String: return "%s (%s)"%[display_name, index]
	## Returns debug info on current inputs
	func get_debug_input() -> String:
		return "LS:%s RS:%s LT:%s RT:%s B:%s"%[
			get_l_stick(), get_r_stick(), get_l_trigger(), get_r_trigger(), pressed_mask
			]
	## Returns true if input is currently being pressed
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
		if length <= StickeyInputManager.left_stick_deadzone: return Vector2.ZERO
		if normalized:
			return l_stick_raw.normalized() * clampf((length - StickeyInputManager.left_stick_deadzone) / (1.0 - StickeyInputManager.left_stick_deadzone), 0, 1)
		else:
			return l_stick_raw
	## Returns right stick direction
	func get_r_stick(normalized := true) -> Vector2:
		var length := r_stick_raw.length()
		if length <= StickeyInputManager.right_stick_deadzone: return Vector2.ZERO
		if normalized:
			return r_stick_raw.normalized() * clampf((length - StickeyInputManager.right_stick_deadzone) / (1.0 - StickeyInputManager.right_stick_deadzone), 0, 1)
		else:
			return r_stick_raw
	## Returns left trigger pressure
	func get_l_trigger() -> float:
		if l_trigger_raw <= StickeyInputManager.trigger_deadzone: return 0
		else: return l_trigger_raw
	## Returns right trigger pressure
	func get_r_trigger() -> float:
		if r_trigger_raw <= StickeyInputManager.trigger_deadzone: return 0
		else: return r_trigger_raw
	## Applies vibration to gamepad
	func rumble(weak_magnitude: float = 0.5, strong_magnitude: float = 0.3, length: float = 0.1) -> void:
		if index < 0: return
		Input.start_joy_vibration(index, weak_magnitude, strong_magnitude, length)
	## Access input mask from [param frames_ago]. Returns 0 if older than input history
	func get_old_input_mask(frames_ago: int) -> int:
		frames_ago = clampi(frames_ago, 1, StickeyInputManager.input_history_buffer_size - 1)
		return input_history[(input_history_index - frames_ago + StickeyInputManager.input_history_buffer_size) % StickeyInputManager.input_history_buffer_size]
	## Returns true if input was pressed within [param frames_ago].
	func was_pressed(input: InputType, frames_ago: int = 1) -> bool:
		frames_ago = clampi(frames_ago, 1, StickeyInputManager.input_history_buffer_size)
		for i in (frames_ago + 1):
			if (get_old_input_mask(i + 1) & (1 << input) == 0) && (get_old_input_mask(i) & (1 << input) != 0):
				return true
		return false
	## Returns true if input was released within [param frames_ago].
	func was_released(input: InputType, frames_ago: int = 1) -> bool:
		frames_ago = clampi(frames_ago, 1, StickeyInputManager.input_history_buffer_size)
		for i in (frames_ago + 1):
			if (get_old_input_mask(i + 1) & (1 << input) != 0) && (get_old_input_mask(i) & (1 << input) == 0):
				return true
		return false
	## Return true if input was just pressed this past frame
	func was_just_pressed(input: InputType) -> bool:
		return (get_old_input_mask(1) & (1 << input) == 0) && (pressed_mask & (1 << input) != 0)
	## Return true if input was just released this past frame
	func was_just_released(input: InputType) -> bool:
		return (get_old_input_mask(1) & (1 << input) != 0) && (pressed_mask & (1 << input) == 0)
	## Returns true if input is pressed, and has been pressed for at least [param frame_count] frames
	func was_held_for(input: InputType, frame_count: int = 1) -> bool:
		frame_count = clampi(frame_count, 1, StickeyInputManager.input_history_buffer_size)
		if !is_pressed(input): return false
		for i in range(1, frame_count + 1):
			if get_old_input_mask(i) & (1 << input) == 0:
				return false
		return true
	## Returns number of times pressed within last [param frame_count] frames
	func get_times_pressed(input: InputType, frame_count: int = 1) -> int:
		var count: int = 0
		frame_count = clampi(frame_count, 1, StickeyInputManager.input_history_buffer_size)
		for i in (frame_count + 1):
			if (get_old_input_mask(i + 1) & (1 << input) == 0) && (get_old_input_mask(i) & (1 << input) != 0):
				count += 1
		return count
	## Returns [Texture2D] for texture path based on input type, or null if path can't be found.
	## This uses Project Setting "stickey_input/general/icons/base_path" as the base directory,
	## device type as sub directory (typically "keyboard", "xbox", "switch", "playstation", or "generic",
	## but this can also be snake_case version of device's SDL name such as "ps_4_controller").
	## Initially this will use [ResourceLoader], but it will also attempt to load manually as an [ImageTexture].
	func get_texture(texture_path: String) -> Texture2D:
		if !texture_path.is_valid_filename(): return null
		var base_path: String = ProjectSettings.get_setting("stickey_input/general/icons/base_path", "res://")
		if !DirAccess.dir_exists_absolute(base_path): return null
		var device_path: String
		if DirAccess.dir_exists_absolute("%s/%s"%[base_path, display_name.to_snake_case()]):
			device_path = display_name.to_snake_case()
		else:
			match type:
				GamepadType.KEYBOARD: device_path = "keyboard"
				GamepadType.XBOX: device_path = "xbox"
				GamepadType.SWITCH: device_path = "switch"
				GamepadType.PLAYSTATION: device_path = "playstation"
				GamepadType.STEAMDECK: device_path = "steam_deck"
				_: device_path = "generic"
		if !DirAccess.dir_exists_absolute("%s/%s"%[base_path, device_path]): device_path = "generic"
		if ResourceLoader.exists("%s/%s/%s"%[base_path, device_path, texture_path], "Texture2D"):
			return ResourceLoader.load("%s/%s/%s"%[base_path, device_path, texture_path], "Texture2D")
		elif FileAccess.file_exists("%s/%s/%s"%[base_path, device_path, texture_path]):
			for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
				if texture_path.get_extension() == extension:
					var raw_image := Image.load_from_file("%s/%s/%s"%[base_path, device_path, texture_path])
					return ImageTexture.create_from_image(raw_image)
		return null
	## Shorthand of [method get_texture] to load texture "device" (intended as image of device)
	func get_device_icon() -> Texture2D:
		var output: Texture2D
		for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
			output = get_texture("%s.%s"%["device", extension])
			if output != null: break
		return output
	## Uses [method get_texture] to get image of input binding
	func get_input_icon(input: InputType) -> Texture2D:
		var output: Texture2D
		var input_string: String
		if type == StickeyInputManager.GamepadType.KEYBOARD:
			if StickeyInputManager.keyboard_mappings.values().has(input):
				var key: Key = StickeyInputManager.keyboard_mappings.find_key(input)
				input_string = OS.get_keycode_string(key)
			elif StickeyInputManager.mouse_mappings.keys().has(input):
				var button: MouseButton = StickeyInputManager.mouse_mappings.find_key(input)
				match button:
					MOUSE_BUTTON_LEFT: input_string = "mouse_left"
					MOUSE_BUTTON_RIGHT: input_string = "mouse_right"
					MOUSE_BUTTON_MIDDLE: input_string = "mouse_middle"
					MOUSE_BUTTON_WHEEL_UP : input_string = "mouse_wheel_up"
					MOUSE_BUTTON_WHEEL_DOWN: input_string = "mouse_wheel_down"
					MOUSE_BUTTON_WHEEL_LEFT: input_string = "mouse_wheel_left"
					MOUSE_BUTTON_WHEEL_RIGHT: input_string = "mouse_wheel_right"
					MOUSE_BUTTON_XBUTTON1: input_string = "mouse_xbutton_1"
					MOUSE_BUTTON_XBUTTON2: input_string = "mouse_xbutton_2"
					_: input_string = "mouse"
			else: input_string = "unmapped"
		else:
			if StickeyInputManager.joy_remappings.has(input): input = StickeyInputManager.joy_remappings[input]
			input_string = StickeyInputManager.get_input_type_string(input)
		for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
			output = get_texture("%s.%s"%[
				input_string.validate_filename().to_snake_case(), 
				extension]
				)
			if output != null: break
		return output
	## Returns string representing input binding's name based on device type and mappings.
	## Returns empty string if input is unmapped.
	func get_input_string(input: InputType) -> String:
		var output: Texture2D
		var input_string: String
		if type == StickeyInputManager.GamepadType.KEYBOARD:
			if StickeyInputManager.keyboard_mappings.values().has(input):
				var key: Key = StickeyInputManager.keyboard_mappings.find_key(input)
				return OS.get_keycode_string(key)
			elif StickeyInputManager.mouse_mappings.keys().has(input):
				var button: MouseButton = StickeyInputManager.mouse_mappings.find_key(input)
				match button:
					MOUSE_BUTTON_LEFT: input_string = "Mouse Left"
					MOUSE_BUTTON_RIGHT: input_string = "Mouse Right"
					MOUSE_BUTTON_MIDDLE: input_string = "Mouse Middle"
					MOUSE_BUTTON_WHEEL_UP : input_string = "Mouse Wheel Up"
					MOUSE_BUTTON_WHEEL_DOWN: input_string = "Mouse Wheel Down"
					MOUSE_BUTTON_WHEEL_LEFT: input_string = "Mouse Wheel Left"
					MOUSE_BUTTON_WHEEL_RIGHT: input_string = "Mouse Wheel Right"
					MOUSE_BUTTON_XBUTTON1: input_string = "Mouse Extra 1"
					MOUSE_BUTTON_XBUTTON2: input_string = "Mouse Extra 2"
					_: input_string = "Mouse Button"
			else: return ""
		else:
			if StickeyInputManager.joy_remappings.has(input): input = StickeyInputManager.joy_remappings[input]
			return StickeyInputManager.get_input_type_string(input, type)
		return ""

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
	L_STICK_UP = 56,		# Pseudo button for left stick axis Y (not recorded to input mask)
	L_STICK_DOWN = 57,		# Pseudo button for left stick axis Y (not recorded to input mask)
	L_STICK_LEFT = 58,		# Pseudo button for left stick axis X (not recorded to input mask)
	L_STICK_RIGHT = 59,		# Pseudo button for left stick axis X (not recorded to input mask)
	R_STICK_UP = 60,		# Pseudo button for right stick axis Y (not recorded to input mask)
	R_STICK_DOWN = 61,		# Pseudo button for right stick axis Y (not recorded to input mask)
	R_STICK_LEFT = 62,		# Pseudo button for right stick axis X (not recorded to input mask)
	R_STICK_RIGHT = 63,		# Pseudo button for right stick axis X (not recorded to input mask)
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
	KEYBOARD,
	GENERIC,
	XBOX,
	SWITCH,
	PLAYSTATION,
	STEAMDECK
	}

## Threshold for registering trigger as full button press (not deadzone).
## Value loaded from [ProjectSettings] on [method _init].
var trigger_press_threshold: float
## Threshold for registering trigger release.
## Value loaded from [ProjectSettings] on [method _init].
var trigger_release_threshold: float
## Left stick deadzone.
## Value loaded from [ProjectSettings] on [method _init].
var left_stick_deadzone: float
## Right stick deadzone.
## Value loaded from [ProjectSettings] on [method _init].
var right_stick_deadzone: float
## Trigger deadzone (not to be confused with [member trigger_press_threshold].
## Value loaded from [ProjectSettings] on [method _init].
var trigger_deadzone: float
## Mouse sensitivity when translated to stick axis.
## Value loaded from [ProjectSettings] on [method _init].
var mouse_sensitivity: float
## Decay for smoothing mouse movement (higher number results in quicker slow down).
## Value loaded from [ProjectSettings] on [method _init].
var mouse_decay: float
## Clamps fast mouse movement to this value (relative to max joystick movement of 1.0).
## Value loaded from [ProjectSettings] on [method _init].
var mouse_clamp: float
## Number of physics frames to store input history for.
## Value loaded from [ProjectSettings] on [method _init].
var input_history_buffer_size: int

## Connected devices, including keyboard
var devices: Dictionary[int, StickeyDevice]
## Device index to share keyboard input with-- use -1 to not share
var keyboard_shared_device: int = 0
## When true keyboard device has been used more recently than [member keyboard_shared_device]
var is_keyboard_primary: bool = false
## Raw mouse motion
var mouse_raw := Vector2.ZERO
## Stick to translate mouse motion too
var mouse_stick: Stick = Stick.RIGHT
## Key mappings for inputs
var keyboard_mappings: Dictionary[Key, InputType]
## Mouse button mappings for inputs
var mouse_mappings: Dictionary[MouseButton, InputType]
## Remappings for joy buttons
var joy_remappings: Dictionary[JoyButton, InputType]

## Emitted when device is connected
signal device_connected(index: int)
## Emitted when device is disconnected
signal device_disconnected(index: int)
## Emitted when [member keyboard_shared_device] swaps between keyboard and gamepad as current device
signal primary_device_changed(is_keyboard: bool)

func _init() -> void:
	trigger_press_threshold = ProjectSettings.get_setting("stickey_input/joystick/trigger/press_threshold", 0.5)
	trigger_release_threshold = ProjectSettings.get_setting("stickey_input/joystick/trigger/release_threshold", 0.7)
	left_stick_deadzone = ProjectSettings.get_setting("stickey_input/joystick/left_stick/deadzone", 0.05)
	right_stick_deadzone = ProjectSettings.get_setting("stickey_input/joystick/right_stick/deadzone", 0.05)
	trigger_deadzone = ProjectSettings.get_setting("stickey_input/joystick/trigger/deadzone", 0.3)
	mouse_sensitivity = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/sensitivity", 0.3)
	mouse_decay = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/decay_rate", 10.0)
	mouse_clamp = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/max_speed", 5.0)
	input_history_buffer_size = ProjectSettings.get_setting("stickey_input/general/input_history/buffer_frames", 60)
	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "Web":
			connect_keyboard_device()
			is_keyboard_primary = Input.get_connected_joypads().is_empty()
		"Android", "iOS":
			pass ## Eventually this is where we could initialize touch screen input?
		_:
			pass ## This would be unaccounted for custom console builds
	Input.joy_connection_changed.connect(_joy_connection_changed)

func _joy_connection_changed(index: int, connected: bool) -> void:
	if connected:
		var device := StickeyDevice.new()
		device.index = index
		device.display_name = Input.get_joy_name(index)
		if device.display_name.contains("Xbox"): device.type = GamepadType.XBOX
		elif device.display_name.contains("Switch"): device.type = GamepadType.SWITCH
		elif device.display_name.contains("PS"): device.type = GamepadType.PLAYSTATION
		elif device.display_name.contains("Steam Deck"): device.type = GamepadType.STEAMDECK
		else: device.type = GamepadType.GENERIC
		device.input_history.resize(input_history_buffer_size)
		devices[index] = device
		device_connected.emit(index)
		print("Device connected: %s (%s)"%[device.display_name, index])
		if keyboard_shared_device == index && is_keyboard_primary:
			is_keyboard_primary = false
			primary_device_changed.emit(false)
	else:
		device_disconnected.emit(index)
		print("Device disconnected: %s (%s)"%[devices[index].display_name, index])
		if keyboard_shared_device == index && !is_keyboard_primary:
			is_keyboard_primary = true
			primary_device_changed.emit(true)
		devices.erase(index)

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	match event.get_class():
		"InputEventKey":
			if !devices.has(KEYBOARD_INDEX): return
			if !is_keyboard_primary:
				is_keyboard_primary = true
				primary_device_changed.emit(true)
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
			if !devices.has(KEYBOARD_INDEX): return
			if !is_keyboard_primary:
				is_keyboard_primary = true
				primary_device_changed.emit(true)
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
			if !devices.has(KEYBOARD_INDEX): return
			if !is_keyboard_primary:
				is_keyboard_primary = true
				primary_device_changed.emit(true)
			mouse_raw = event.relative * mouse_sensitivity
			mouse_raw = mouse_raw.clampf(-mouse_clamp, mouse_clamp)
			match mouse_stick:
				Stick.LEFT:
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, mouse_raw.y)
				Stick.RIGHT:
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, mouse_raw.y)
		"InputEventJoypadButton":
			if !Input.get_connected_joypads().has(event.device): return
			if event.device == keyboard_shared_device && is_keyboard_primary:
				is_keyboard_primary = false
				primary_device_changed.emit(false)
			if joy_remappings.has(event.button_index):
				_update_button(event.device, joy_remappings[event.button_index], event.pressed)
			else:
				_update_button(event.device, event.button_index, event.pressed)
		"InputEventJoypadMotion":
			if !Input.get_connected_joypads().has(event.device): return
			if event.device == keyboard_shared_device && is_keyboard_primary:
				is_keyboard_primary = false
				primary_device_changed.emit(false)
			_update_axis(event.device, event.axis, event.axis_value)
			# Update button masks
			match event.axis:
				JOY_AXIS_TRIGGER_LEFT:
					if devices[event.device].is_pressed(InputType.L_TRIGGER):
						if event.axis_value < trigger_release_threshold:
							_update_button(event.device, InputType.L_TRIGGER, false)
					elif event.axis_value > trigger_press_threshold:
						_update_button(event.device, InputType.L_TRIGGER, true)
				JOY_AXIS_TRIGGER_RIGHT:
					if devices[event.device].is_pressed(InputType.R_TRIGGER):
						if event.axis_value < trigger_release_threshold:
							_update_button(event.device, InputType.R_TRIGGER, false)
					elif event.axis_value > trigger_press_threshold:
						_update_button(event.device, InputType.R_TRIGGER, true)

func _process(delta: float) -> void:
	if Input.get_last_mouse_velocity() == Vector2.ZERO && mouse_raw != Vector2.ZERO:
		mouse_raw = mouse_raw.move_toward(Vector2.ZERO, mouse_decay * mouse_clamp * delta)
		match mouse_stick:
				Stick.LEFT:
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.L_STICK_Y, mouse_raw.y)
				Stick.RIGHT:
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_X, mouse_raw.x)
					_update_axis(KEYBOARD_INDEX, AxisType.R_STICK_Y, mouse_raw.y)

func _physics_process(delta: float) -> void:
	for device: StickeyDevice in devices.values():
		device.input_history_index = (device.input_history_index + 1) % input_history_buffer_size
		device.input_history[device.input_history_index] = device.pressed_mask

## Adds keyboard device. This is typically done automatically on initialization, 
## and shouldn't need to be recalled unless keyboard was manually disconnected.
func connect_keyboard_device() -> void:
	devices[KEYBOARD_INDEX] = StickeyDevice.new()
	devices[KEYBOARD_INDEX].index = KEYBOARD_INDEX
	devices[KEYBOARD_INDEX].display_name = &"Keyboard"
	devices[KEYBOARD_INDEX].type = GamepadType.KEYBOARD
	devices[KEYBOARD_INDEX].input_history.resize(input_history_buffer_size)
	_initialize_default_keyboard_mappings()

## Loads [ConfigFile] with input mappings at the path of Project Setting "stickey_input/general/serialization/default_mappings_path"
func _initialize_default_keyboard_mappings() -> void:
	var path: String = ProjectSettings.get_setting("stickey_input/general/serialization/default_mappings_path", "res://addons/stickey/default_mappings.cfg")
	if !FileAccess.file_exists(path): return
	var config_file := ConfigFile.new()
	var err := config_file.load(path)
	if err == OK: deserialize_input_mappings(config_file)
	else: printerr("Unable to deserialize input mappings: %s"%error_string(err))

## Updates device [member StickeyDevice.pressed_mask]
func _update_button(device: int, input: InputType, pressed: bool) -> void:
	if input > 31: return
	var bit := 1 << int(input)
	if pressed: devices[device].pressed_mask |= bit
	else: devices[device].pressed_mask &= ~bit
	# Send keyboard input to gamepad
	if device == KEYBOARD_INDEX && keyboard_shared_device >= 0 && devices.has(keyboard_shared_device):
		_update_button(keyboard_shared_device, input, pressed)

## Updates device axis values
func _update_axis(device: int, axis: AxisType, value: float) -> void:
	match axis:
		AxisType.L_STICK_X, AxisType.L_STICK_Y, AxisType.R_STICK_X, AxisType.R_STICK_Y:
			if abs(value) < 1e-4: value = 0
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

## Returns string for [enum InputType] and [enum GamepadType].
## Returns "Unknown" if can't find string for input and device combo.
func get_input_type_string(input: InputType, device_type: GamepadType = GamepadType.GENERIC) -> String:
	match device_type:
		GamepadType.XBOX:
			match input:
				InputType.SOUTH: return "A"
				InputType.EAST: return "B"
				InputType.WEST: return "X"
				InputType.NORTH: return "Y"
				InputType.BACK: return "View"
				InputType.GUIDE: return "Home"
				InputType.START: return "Menu"
				InputType.L_STICK: return "Left Stick"
				InputType.R_STICK: return "Right Stick"
				InputType.L_SHOULDER: return "Left Bumper"
				InputType.R_SHOULDER: return "Right Bumper"
				InputType.UP_DIRECTION: return "D-Pad Up"
				InputType.DOWN_DIRECTION: return "D-Pad Down"
				InputType.LEFT_DIRECTION: return "D-Pad Left"
				InputType.RIGHT_DIRECTION: return "D-Pad Right"
				InputType.MISC_1: return "Share"
				InputType.PADDLE_1: return "P1"
				InputType.PADDLE_2: return "P2"
				InputType.PADDLE_3: return "P3"
				InputType.PADDLE_4: return "P4"
				InputType.L_TRIGGER: return "Left Trigger"
				InputType.R_TRIGGER: return "Right Trigger"
				InputType.L_STICK_UP: return "Left Stick Up"
				InputType.L_STICK_DOWN: return "Left Stick Down"
				InputType.L_STICK_LEFT: return "Left Stick Left"
				InputType.L_STICK_RIGHT: return "Left Stick Right"
				InputType.R_STICK_UP: return "Right Stick Up"
				InputType.R_STICK_DOWN: return "Right Stick Down"
				InputType.R_STICK_LEFT: return "Right Stick Left"
				InputType.R_STICK_RIGHT: return "Right Stick Right"
		GamepadType.PLAYSTATION:
			match input:
				InputType.SOUTH: return "Cross"
				InputType.EAST: return "Circle"
				InputType.WEST: return "Square"
				InputType.NORTH: return "Triangle"
				InputType.BACK: return "Share"
				InputType.GUIDE: return "Home"
				InputType.START: return "Options"
				InputType.L_STICK: return "L3"
				InputType.R_STICK: return "R3"
				InputType.L_SHOULDER: return "L1"
				InputType.R_SHOULDER: return "R1"
				InputType.UP_DIRECTION: return "D-Pad Up"
				InputType.DOWN_DIRECTION: return "D-Pad Down"
				InputType.LEFT_DIRECTION: return "D-Pad Left"
				InputType.RIGHT_DIRECTION: return "D-Pad Right"
				InputType.MISC_1: return "Microphone"
				InputType.TOUCH_PAD: return "Touch Pad"
				InputType.L_TRIGGER: return "L2"
				InputType.R_TRIGGER: return "R2"
				InputType.L_STICK_UP: return "L Stick Up"
				InputType.L_STICK_DOWN: return "L Stick Down"
				InputType.L_STICK_LEFT: return "L Stick Left"
				InputType.L_STICK_RIGHT: return "L Stick Right"
				InputType.R_STICK_UP: return "R Stick Up"
				InputType.R_STICK_DOWN: return "R Stick Down"
				InputType.R_STICK_LEFT: return "R Stick Left"
				InputType.R_STICK_RIGHT: return "R Stick Right"
		GamepadType.SWITCH:
			match input:
				InputType.SOUTH: return "B"
				InputType.EAST: return "A"
				InputType.WEST: return "Y"
				InputType.NORTH: return "X"
				InputType.BACK: return "-"
				InputType.START: return "+"
				InputType.L_STICK: return "R Stick"
				InputType.R_STICK: return "L Stick"
				InputType.L_SHOULDER: return "L"
				InputType.R_SHOULDER: return "R"
				InputType.UP_DIRECTION: return "D-Pad Up"
				InputType.DOWN_DIRECTION: return "D-Pad Down"
				InputType.LEFT_DIRECTION: return "D-Pad Left"
				InputType.RIGHT_DIRECTION: return "D-Pad Right"
				InputType.MISC_1: return "Capture"
				InputType.L_TRIGGER: return "ZL"
				InputType.R_TRIGGER: return "ZR"
				InputType.L_STICK_UP: return "L Stick Up"
				InputType.L_STICK_DOWN: return "L Stick Down"
				InputType.L_STICK_LEFT: return "L Stick Left"
				InputType.L_STICK_RIGHT: return "L Stick Right"
				InputType.R_STICK_UP: return "R Stick Up"
				InputType.R_STICK_DOWN: return "R Stick Down"
				InputType.R_STICK_LEFT: return "R Stick Left"
				InputType.R_STICK_RIGHT: return "R Stick Right"
		GamepadType.KEYBOARD: pass
		GamepadType.STEAMDECK:
			match input:
				InputType.SOUTH: return "A"
				InputType.EAST: return "B"
				InputType.WEST: return "X"
				InputType.NORTH: return "Y"
				InputType.BACK: return "View"
				InputType.GUIDE: return "Steam"
				InputType.START: return "Menu"
				InputType.L_STICK: return "L3"
				InputType.R_STICK: return "R4"
				InputType.L_SHOULDER: return "L1"
				InputType.R_SHOULDER: return "R1"
				InputType.UP_DIRECTION: return "D-Pad Up"
				InputType.DOWN_DIRECTION: return "D-Pad Down"
				InputType.LEFT_DIRECTION: return "D-Pad Left"
				InputType.RIGHT_DIRECTION: return "D-Pad Right"
				InputType.MISC_1: return "Quick Access"
				InputType.PADDLE_1: return "L4"
				InputType.PADDLE_2: return "R4"
				InputType.PADDLE_3: return "L5"
				InputType.PADDLE_4: return "R5"
				InputType.L_TRIGGER: return "L2"
				InputType.R_TRIGGER: return "R2"
				InputType.L_STICK_UP: return "Left Stick Up"
				InputType.L_STICK_DOWN: return "Left Stick Down"
				InputType.L_STICK_LEFT: return "Left Stick Left"
				InputType.L_STICK_RIGHT: return "Left Stick Right"
				InputType.R_STICK_UP: return "Right Stick Up"
				InputType.R_STICK_DOWN: return "Right Stick Down"
				InputType.R_STICK_LEFT: return "Right Stick Left"
				InputType.R_STICK_RIGHT: return "Right Stick Right"
		_:
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
				InputType.L_STICK_UP: return "Left Stick Up"
				InputType.L_STICK_DOWN: return "Left Stick Down"
				InputType.L_STICK_LEFT: return "Left Stick Left"
				InputType.L_STICK_RIGHT: return "Left Stick Right"
				InputType.R_STICK_UP: return "Right Stick Up"
				InputType.R_STICK_DOWN: return "Right Stick Down"
				InputType.R_STICK_LEFT: return "Right Stick Left"
				InputType.R_STICK_RIGHT: return "Right Stick Right"
	return "Unknown"

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
	var bindings: Dictionary[InputType, Array]
	for key in keyboard_mappings.keys():
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
	for button in joy_remappings:
		if !bindings.has(joy_remappings[button]): bindings[joy_remappings[button]] = []
		bindings[joy_remappings[button]].append("JoyButton%s"%button)
	var output := ConfigFile.new()
	for input in bindings.keys():
		output.set_value(
			ProjectSettings.get_setting("stickey_input/general/serialization/section_key", "InputMappings"),
			get_input_type_string(input).to_pascal_case(),
			bindings[input]
			)
	return output

## Deserializes input bindings from a [ConfigFile].
## This will overwrite [member keyboard_mappings] and [member mouse_mappings].
func deserialize_input_mappings(config: ConfigFile) -> void:
	keyboard_mappings.clear()
	mouse_mappings.clear()
	var bindings: Dictionary[InputType, PackedStringArray]
	for key in config.get_section_keys(ProjectSettings.get_setting("stickey_input/general/serialization/section_key", "InputMappings")):
		var key_type: int = -1
		for input in MAX_INPUT_TYPES:
			if get_input_type_string(input).to_pascal_case() == key:
				key_type = input
				break
		if key_type == -1: continue
		bindings[key_type] = config.get_value(
			ProjectSettings.get_setting("stickey_input/general/serialization/section_key", "InputMappings"),
			key,
			[]
			) as PackedStringArray
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
			elif bindings[input][n].begins_with("JoyButton"):
				var value := bindings[input][n].trim_prefix("JoyButton")
				if value.is_valid_int(): joy_remappings[value.to_int()] = input
			else:
				var value := OS.find_keycode_from_string(bindings[input][n])
				if value != KEY_UNKNOWN: keyboard_mappings[OS.find_keycode_from_string(bindings[input][n])] = input

## Helps rebind keyboard mappings
func rebind_key(key: Key, input: InputType) -> void:
	keyboard_mappings[key] = input

## Helps rebind mouse mappings
func rebind_mouse(mouse_button: MouseButton, input: InputType) -> void:
	mouse_mappings[mouse_button] = input

## Helps rebind joy remappings
func rebind_joy(joy_button: JoyButton, input: InputType) -> void:
	joy_remappings[joy_button] = input
