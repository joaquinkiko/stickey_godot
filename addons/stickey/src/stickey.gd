## Core static class for SticKey input handling
class_name Stickey

## Device index for keyboard device
const KEYBOARD_INDEX: int = -1
## Total possible input types
const MAX_INPUT_TYPES: int = 64
## Total inputs present in 32-bit int mask
const MAX_INPUT_MASK_BITS: int = 32
## ERROR value for unknown [enum InputType]
const UNKNOWN_INPUT_VALUE: int = -1

## Button inputs
enum InputType {
	SOUTH = 0, 				# Bottom face button / Xbox: A Button
	EAST = 1, 				# Right face button / Xbox: B Button
	WEST = 2, 				# Left face button / Xbox: X Button
	NORTH = 3, 				# Top face button / Xbox: Y Button
	BACK = 4,
	GUIDE = 5,
	START = 6,
	L_STICK_PRESS = 7,
	R_STICK_PRESS = 8,
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
## Helper to determine type of device for UI
enum DeviceType {
	AUTOMATIC = -2, # Used by [StickeyGlyphRect]
	KEYBOARD = -1,
	GENERIC = 0,
	XBOX = 1,
	SWITCH = 2,
	PLAYSTATION = 3,
	STEAMDECK = 4
	}

## Connected devices, including keyboard
static var devices: Dictionary[int, StickeyDevice]
## Device index to share keyboard input with-- use -1 to not share
static var keyboard_shared_device: int = 0
## Key mappings for inputs
static var keyboard_mappings: Dictionary[Key, InputType]
## Mouse button mappings for inputs
static var mouse_mappings: Dictionary[MouseButton, InputType]
## Remappings for joy buttons
static var joy_remappings: Dictionary[JoyButton, InputType]
## Short-hand names for [enum InputType] values
static var input_nicknames: Dictionary[StringName, InputType]

## Stop vibrations on all devices
static func stop_all_rumble() -> void:
	for joypad in Input.get_connected_joypads(): Input.stop_joy_vibration(joypad)

## Returns string for [enum InputType] and [enum DeviceType].
## Returns "Unknown" if can't find string for input and device combo.
static func get_input_type_string(input: InputType, device_type: DeviceType = DeviceType.GENERIC) -> String:
	match device_type:
		DeviceType.XBOX:
			match input:
				InputType.SOUTH: return "A"
				InputType.EAST: return "B"
				InputType.WEST: return "X"
				InputType.NORTH: return "Y"
				InputType.BACK: return "View"
				InputType.GUIDE: return "Home"
				InputType.START: return "Menu"
				InputType.L_STICK_PRESS: return "Left Stick Press"
				InputType.R_STICK_PRESS: return "Right Stick Press"
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
		DeviceType.PLAYSTATION:
			match input:
				InputType.SOUTH: return "Cross"
				InputType.EAST: return "Circle"
				InputType.WEST: return "Square"
				InputType.NORTH: return "Triangle"
				InputType.BACK: return "Share"
				InputType.GUIDE: return "Home"
				InputType.START: return "Options"
				InputType.L_STICK_PRESS: return "L3"
				InputType.R_STICK_PRESS: return "R3"
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
		DeviceType.SWITCH:
			match input:
				InputType.SOUTH: return "B"
				InputType.EAST: return "A"
				InputType.WEST: return "Y"
				InputType.NORTH: return "X"
				InputType.BACK: return "-"
				InputType.START: return "+"
				InputType.L_STICK_PRESS: return "R Stick Press"
				InputType.R_STICK_PRESS: return "L Stick Press"
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
		DeviceType.KEYBOARD: pass
		DeviceType.STEAMDECK:
			match input:
				InputType.SOUTH: return "A"
				InputType.EAST: return "B"
				InputType.WEST: return "X"
				InputType.NORTH: return "Y"
				InputType.BACK: return "View"
				InputType.GUIDE: return "Steam"
				InputType.START: return "Menu"
				InputType.L_STICK_PRESS: return "L3"
				InputType.R_STICK_PRESS: return "R3"
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
				InputType.L_STICK_PRESS: return "Left Stick Press"
				InputType.R_STICK_PRESS: return "Right Stick Press"
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
static func get_axis_type_string(axis: AxisType) -> String:
	match axis:
		AxisType.L_STICK_X: return "Left Stick X"
		AxisType.L_STICK_Y: return "Left Stick Y"
		AxisType.R_STICK_X: return "Right Stick X"
		AxisType.R_STICK_Y: return "Right Stick Y"
		AxisType.L_TRIGGER: return "Left Trigger"
		AxisType.R_TRIGGER: return "Right Trigger"
		_: return "Invalid"

## Returns [Texture2D] for texture path based on input type, or null if path can't be found.
## This uses Project Setting "stickey_input/general/glyph/base_path" as the base directory,
## device type as sub directory (typically "keyboard", "xbox", "switch", "playstation", "generic", etc...
## but this can also be snake_case version of device's SDL name such as "ps_4_controller").
## Initially this will use [ResourceLoader], but it will also attempt to load manually as an [ImageTexture].
static func get_glyph(texture_path: String, device_type: DeviceType, override_path: String = "") -> Texture2D:
	if !texture_path.is_valid_filename(): return null
	var base_path: String = ProjectSettings.get_setting("stickey_input/general/glyph/base_path", "res://addons/stickey/default_glyphs")
	if !DirAccess.dir_exists_absolute(base_path): return null
	var device_path: String
	if !override_path.is_empty() && DirAccess.dir_exists_absolute("%s/%s"%[base_path, override_path]):
		device_path = override_path
	else:
		match device_type:
			Stickey.DeviceType.KEYBOARD: device_path = "keyboard"
			Stickey.DeviceType.XBOX: device_path = "xbox"
			Stickey.DeviceType.SWITCH: device_path = "switch"
			Stickey.DeviceType.PLAYSTATION: device_path = "playstation"
			Stickey.DeviceType.STEAMDECK: device_path = "steam_deck"
			_: device_path = "generic"
	## If resource cannot be found for specific device, fallback in searching "generic" sub-directory
	if !ResourceLoader.exists("%s/%s/%s"%[base_path, device_path, texture_path], "Texture2D") && !FileAccess.file_exists("%s/%s/%s"%[base_path, device_path, texture_path]):
		if device_type == Stickey.DeviceType.KEYBOARD:
			device_path = "%s.%s"%["unknown", texture_path.get_extension()]
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
static func get_device_glyph(device_type: DeviceType, override_path: String = "") -> Texture2D:
	var output: Texture2D
	for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
		output = get_glyph("%s.%s"%["device", extension], device_type, override_path)
		if output != null: break
	return output

## Uses [method get_texture] to get image of input binding
static func get_input_glyph(input: Stickey.InputType, device_type: DeviceType, override_path: String = "") -> Texture2D:
	var output: Texture2D
	var input_string: String
	if device_type == Stickey.DeviceType.KEYBOARD:
		if keyboard_mappings.values().has(input):
			var key: Key
			if keyboard_mappings.find_key(input) != null:
				key = keyboard_mappings.find_key(input)
			else: key = KEY_UNKNOWN
			input_string = OS.get_keycode_string(key)
		elif mouse_mappings.values().has(input):
			var button: MouseButton
			if mouse_mappings.find_key(input) != null:
				button = Stickey.mouse_mappings.find_key(input)
			else: MOUSE_BUTTON_NONE
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
				_: input_string = "unknown"
		else: input_string = "unknown"
	else:
		if joy_remappings.has(input): input = Stickey.joy_remappings[input]
		input_string = Stickey.get_input_type_string(input)
	for extension: String in ["png", "svg", "jpg", "jpeg", "webp"]:
		output = get_glyph(
			"%s.%s"%[input_string.remove_chars("-").validate_filename().to_snake_case(), extension],
			device_type,
			override_path
			)
		if output != null: break
	return output

## Creates a [ConfigFile] for serializing input bindings.
## This can later be loaded with [method deserialize_input_mappings].
static func serialize_input_mappings() -> ConfigFile:
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
static func deserialize_input_mappings(config: ConfigFile) -> void:
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
static func rebind_key(key: Key, input: InputType) -> void:
	keyboard_mappings[key] = input

## Helps rebind mouse mappings
static func rebind_mouse(mouse_button: MouseButton, input: InputType) -> void:
	mouse_mappings[mouse_button] = input

## Helps rebind joy remappings
static func rebind_joy(joy_button: JoyButton, input: InputType) -> void:
	joy_remappings[joy_button] = input

## Safely retrieve [enum InputType] from [member input_nicknames],
## or returns [member UNKNOWN_INPUT_VALUE] if cannot retrieve
static func get_input(nickname: String) -> InputType:
	return input_nicknames.get(nickname, UNKNOWN_INPUT_VALUE)
