## Represents a unique input device
class_name StickeyDevice extends RefCounted

const KEYBOARD_INDEX: int = Stickey.KEYBOARD_INDEX
const MAX_INPUT_TYPES: int = Stickey.MAX_INPUT_TYPES
const MAX_INPUT_MASK_BITS: int = Stickey.MAX_INPUT_MASK_BITS

## Number of physics frames to store input history for.
## Value loaded from [ProjectSettings] on [method _init].
static var input_history_buffer_size: int
## Left stick deadzone.
## Value loaded from [ProjectSettings] on [method _init].
static var left_stick_deadzone: float
## Right stick deadzone.
## Value loaded from [ProjectSettings] on [method _init].
static var right_stick_deadzone: float
## Trigger deadzone (not to be confused with [member trigger_press_threshold].
## Value loaded from [ProjectSettings] on [method _init].
static var trigger_deadzone: float

## Device input index (set during initialization)
var index: int:
	get: return _index
	set(value): push_warning("Cannot directly set 'index'")
var _index: int
## Device display name (set during initialization)
var display_name: StringName:
	get: return _display_name
	set(value): push_warning("Cannot directly set 'display_name'")
var _display_name: StringName
## Gamepad type (set during initialization)
var type: Stickey.DeviceType:
	get: return _type
	set(value): push_warning("Cannot directly set 'type'")
var _type: int

## Raw left stick direction
var l_stick_raw := Vector2.ZERO
## Raw right stick direction
var r_stick_raw := Vector2.ZERO
## Raw left trigger pressure
var l_trigger_raw: float = 0.0
## Raw right trigger pressure
var r_trigger_raw: float = 0.0

## Pressed input mask (set via [method set_input_mask])
var pressed_mask: int:
	get: return _pressed_mask
	set(value): push_warning("Cannot directly set 'pressed_mask'")
var _pressed_mask: int = 0
## Buffer of previous [member pressed_mask] frames (set via [member update_input_history])
var input_history: PackedInt32Array:
	get: return _input_history
	set(value): push_warning("Cannot directly set 'input_history'")
var _input_history: PackedInt32Array
## Current index in [member input_history] (set via [member update_input_history])
var input_history_index: int:
	get: return _input_history_index
	set(value): push_warning("Cannot directly set 'input_history_index'")
var _input_history_index: int = 0

func _init(init_index: int, init_display_name: StringName) -> void:
	_index = init_index
	_display_name = init_display_name
	if display_name == &"Keyboard" || display_name == &"Handheld":  _type = Stickey.DeviceType.KEYBOARD
	if display_name.contains("Xbox"): _type = Stickey.DeviceType.XBOX
	elif display_name.contains("Switch"): _type = Stickey.DeviceType.SWITCH
	elif display_name.contains("PS"): _type = Stickey.DeviceType.PLAYSTATION
	elif display_name.contains("Steam Deck"): _type = Stickey.DeviceType.STEAMDECK
	else: _type = Stickey.DeviceType.GENERIC
	_input_history.resize(input_history_buffer_size)

func _to_string() -> String: return "%s (%s)"%[display_name, index]

## Returns debug info on current inputs
func get_debug_input() -> String:
	return "LS:%s RS:%s LT:%s RT:%s B:%s"%[
		get_l_stick(), get_r_stick(), get_l_trigger(), get_r_trigger(), _pressed_mask
		]

## Used internaly to update input history every physics frame. 
## Only use manually if you know what you're doing.
func update_input_history() -> void:
	_input_history_index = (_input_history_index + 1) % input_history_buffer_size
	_input_history[_input_history_index] = _pressed_mask

## Updates mask for [member pressed_mask] with input and state,
## ignoring inputs larger than [member MAX_INPUT_MASK_BITS]
func set_input_mask(input: Stickey.InputType, pressed: bool) -> void:
	if input >= MAX_INPUT_MASK_BITS: return
	var bit := 1 << int(input)
	if pressed: _pressed_mask |= bit
	else: _pressed_mask &= ~bit

## Access input mask from [param frames_ago]. Returns 0 if older than input history
func get_old_input_mask(frames_ago: int) -> int:
	frames_ago = clampi(frames_ago, 1, input_history_buffer_size - 1)
	return input_history[(input_history_index - frames_ago + input_history_buffer_size) % input_history_buffer_size]

## Returns left stick direction, accounting for normalization and deadzones
func get_l_stick() -> Vector2:
	var length := l_stick_raw.length()
	if length <= left_stick_deadzone: return Vector2.ZERO
	return l_stick_raw.normalized() * clampf((length - left_stick_deadzone) / (1.0 - left_stick_deadzone), 0, 1)

## Returns right stick direction, accounting for normalization and deadzones
func get_r_stick() -> Vector2:
	var length := r_stick_raw.length()
	if length <= right_stick_deadzone: return Vector2.ZERO
	return r_stick_raw.normalized() * clampf((length - right_stick_deadzone) / (1.0 - right_stick_deadzone), 0, 1)

## Returns left trigger pressure, accounting for deadzones
func get_l_trigger() -> float:
	if l_trigger_raw <= trigger_deadzone: return 0
	else: return l_trigger_raw

## Returns right trigger pressure, accounting for deadzones
func get_r_trigger() -> float:
	if r_trigger_raw <= trigger_deadzone: return 0
	else: return r_trigger_raw

## Applies vibration to gamepad
func rumble(weak_magnitude: float = 0.5, strong_magnitude: float = 0.3, length: float = 0.1) -> void:
	if type == Stickey.DeviceType.KEYBOARD:
		Input.vibrate_handheld(
			int(length * 1000),
			(strong_magnitude * 0.75) + (weak_magnitude * 0.25)
		)
		if Stickey.devices.has(Stickey.keyboard_shared_device):
			Stickey.devices[Stickey.keyboard_shared_device].rumble(
				weak_magnitude,
				strong_magnitude,
				length
			)
	else:
		Input.start_joy_vibration(index, weak_magnitude, strong_magnitude, length)

## Returns true if input is currently being pressed
func is_pressed(input: Stickey.InputType) -> bool:
	match input:
		Stickey.InputType.L_STICK_UP: return l_stick_raw.x < 0
		Stickey.InputType.L_STICK_DOWN: return l_stick_raw.x > 0
		Stickey.InputType.L_STICK_LEFT: return l_stick_raw.y < 0
		Stickey.InputType.L_STICK_RIGHT: return l_stick_raw.y > 0
		Stickey.InputType.R_STICK_UP: return r_stick_raw.x < 0
		Stickey.InputType.R_STICK_DOWN: return r_stick_raw.x > 0
		Stickey.InputType.R_STICK_LEFT: return r_stick_raw.y < 0
		Stickey.InputType.R_STICK_RIGHT: return r_stick_raw.y > 0
		_: return _pressed_mask & (1 << input) != 0

## Returns true if input was pressed within [param frames_ago].
func was_pressed(input: Stickey.InputType, frames_ago: int = 1) -> bool:
	frames_ago = clampi(frames_ago, 1, input_history_buffer_size)
	for i in (frames_ago + 1):
		if (get_old_input_mask(i + 1) & (1 << input) == 0) && (get_old_input_mask(i) & (1 << input) != 0):
			return true
	return false

## Returns true if input was released within [param frames_ago].
func was_released(input: Stickey.InputType, frames_ago: int = 1) -> bool:
	frames_ago = clampi(frames_ago, 1, input_history_buffer_size)
	for i in (frames_ago + 1):
		if (get_old_input_mask(i + 1) & (1 << input) != 0) && (get_old_input_mask(i) & (1 << input) == 0):
			return true
	return false

## Return true if input was just pressed this past frame
func was_just_pressed(input: Stickey.InputType) -> bool:
	return (get_old_input_mask(1) & (1 << input) == 0) && (_pressed_mask & (1 << input) != 0)

## Return true if input was just released this past frame
func was_just_released(input: Stickey.InputType) -> bool:
	return (get_old_input_mask(1) & (1 << input) != 0) && (_pressed_mask & (1 << input) == 0)

## Returns true if input is pressed, and has been pressed for at least [param frame_count] frames
func was_held_for(input: Stickey.InputType, frame_count: int = 1) -> bool:
	frame_count = clampi(frame_count, 1, input_history_buffer_size)
	if !is_pressed(input): return false
	for i in range(1, frame_count + 1):
		if get_old_input_mask(i) & (1 << input) == 0:
			return false
	return true

## Returns number of times pressed within last [param frame_count] frames
func get_times_pressed(input: Stickey.InputType, frame_count: int = 1) -> int:
	var count: int = 0
	frame_count = clampi(frame_count, 1, input_history_buffer_size)
	for i in (frame_count + 1):
		if (get_old_input_mask(i + 1) & (1 << input) == 0) && (get_old_input_mask(i) & (1 << input) != 0):
			count += 1
	return count

## Returns [Texture2D] for texture path based on input type, or null if path can't be found.
## This uses Project Setting "stickey_input/general/glyph/base_path" as the base directory,
## device type as sub directory (typically "keyboard", "xbox", "switch", "playstation", or "generic",
## but this can also be snake_case version of device's SDL name such as "ps_4_controller").
## Initially this will use [ResourceLoader], but it will also attempt to load manually as an [ImageTexture].
func get_glyph(texture_path: String) -> Texture2D:
	if !texture_path.is_valid_filename(): return null
	var base_path: String = ProjectSettings.get_setting("stickey_input/general/glyph/base_path", "res://")
	if !DirAccess.dir_exists_absolute(base_path): return null
	var device_path: String
	if DirAccess.dir_exists_absolute("%s/%s"%[base_path, display_name.to_snake_case()]):
		device_path = display_name.to_snake_case()
	else:
		match type:
			Stickey.DeviceType.KEYBOARD: device_path = "keyboard"
			Stickey.DeviceType.XBOX: device_path = "xbox"
			Stickey.DeviceType.SWITCH: device_path = "switch"
			Stickey.DeviceType.PLAYSTATION: device_path = "playstation"
			Stickey.DeviceType.STEAMDECK: device_path = "steam_deck"
			_: device_path = "generic"
	## If resource cannot be found for specific device, fallback in searching "generic" sub-directory
	if !ResourceLoader.exists("%s/%s/%s"%[base_path, device_path, texture_path], "Texture2D") && !FileAccess.file_exists("%s/%s/%s"%[base_path, device_path, texture_path]):
		device_path = "generic"
	if ResourceLoader.exists("%s/%s/%s"%[base_path, device_path, texture_path], "Texture2D"):
		return ResourceLoader.load("%s/%s/%s"%[base_path, device_path, texture_path], "Texture2D")
	elif FileAccess.file_exists("%s/%s/%s"%[base_path, device_path, texture_path]):
		for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
			if texture_path.get_extension() == extension:
				var raw_image := Image.load_from_file("%s/%s/%s"%[base_path, device_path, texture_path])
				return ImageTexture.create_from_image(raw_image)
	return null

## Shorthand of [method get_texture] to load texture "device" (intended as image of device)
func get_device_glyph() -> Texture2D:
	var output: Texture2D
	for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
		output = get_glyph("%s.%s"%["device", extension])
		if output != null: break
	return output

## Uses [method get_texture] to get image of input binding
func get_input_glyph(input: Stickey.InputType) -> Texture2D:
	var output: Texture2D
	var input_string: String
	if type == Stickey.DeviceType.KEYBOARD:
		if Stickey.keyboard_mappings.values().has(input):
			var key: Key = Stickey.keyboard_mappings.find_key(input)
			input_string = OS.get_keycode_string(key)
		elif Stickey.mouse_mappings.keys().has(input):
			var button: MouseButton = Stickey.mouse_mappings.find_key(input)
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
		if Stickey.joy_remappings.has(input): input = Stickey.joy_remappings[input]
		input_string = Stickey.get_input_type_string(input)
	for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
		output = get_glyph("%s.%s"%[
			input_string.remove_chars("-").validate_filename().to_snake_case(), 
			extension]
			)
		if output != null: break
	return output

## Returns string representing input binding's name based on device type and mappings.
## Returns empty string if input is unmapped.
func get_input_string(input: Stickey.InputType) -> String:
	var output: Texture2D
	var input_string: String
	if type == Stickey.DeviceType.KEYBOARD:
		if Stickey.keyboard_mappings.values().has(input):
			var key: Key = Stickey.keyboard_mappings.find_key(input)
			return OS.get_keycode_string(key)
		elif Stickey.mouse_mappings.keys().has(input):
			var button: MouseButton = Stickey.mouse_mappings.find_key(input)
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
		if Stickey.joy_remappings.has(input): input = Stickey.joy_remappings[input]
		return Stickey.get_input_type_string(input, type)
	return ""
