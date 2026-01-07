@tool
extends EditorPlugin

const SETTING_BASE_NAME := "stickey_input"
const SETTING_NAME_TRIGGER_PRESS_THRESHOLD := "stickey_input/joystick/trigger/press_threshold"
const SETTING_VALUE_TRIGGER_PRESS_THRESHOLD := 0.50
const SETTING_NAME_TRIGGER_RELEASE_THRESHOLD := "stickey_input/joystick/trigger/release_threshold"
const SETTING_VALUE_TRIGGER_RELEASE_THRESHOLD := 0.70
const SETTING_NAME_LEFT_STICK_DEADZONE := "stickey_input/joystick/left_stick/deadzone"
const SETTING_VALUE_LEFT_STICK_DEADZONE := 0.05
const SETTING_NAME_RIGHT_STICK_DEADZONE := "stickey_input/joystick/right_stick/deadzone"
const SETTING_VALUE_RIGHT_STICK_DEADZONE := 0.05
const SETTING_NAME_TRIGGER_DEADZONE := "stickey_input/joystick/trigger/deadzone"
const SETTING_VALUE_TRIGGER_DEADZONE := 0.30
const SETTING_NAME_MOUSE_SENSITIVITY := "stickey_input/keyboard_and_mouse/mouse/sensitivity"
const SETTING_VALUE_MOUSE_SENSITIVITY := 0.10
const SETTING_NAME_MOUSE_DECAY := "stickey_input/keyboard_and_mouse/mouse/decay_rate"
const SETTING_VALUE_MOUSE_DECAY := 20.0
const SETTING_NAME_MOUSE_CLAMP :=  "stickey_input/keyboard_and_mouse/mouse/max_speed"
const SETTING_VALUE_MOUSE_CLAMP := 7.0
const SETTING_NAME_INPUT_HISTORY_BUFFER_SIZE := "stickey_input/general/input_history/buffer_frames"
const SETTING_VALUE_INPUT_HISTORY_BUFFER_SIZE := 60
const SETTING_NAME_CONFIG_FILE_SECTION := "stickey_input/general/serialization/section_key"
const SETTING_VALUE_CONFIG_FILE_SECTION := "InputMappings"
const SETTING_NAME_CONFIG_FILE_PATH := "stickey_input/general/serialization/user_mappings_path"
const SETTING_VALUE_CONFIG_FILE_PATH := "user://input_mappings.cfg"
const SETTING_NAME_GLYPHS_BASE_PATH := "stickey_input/general/glyph/base_path"
const SETTING_VALUE_GLYPHS_BASE_PATH := "res://addons/stickey/default_glyphs"
const SETTING_NAME_INPUT_NICKNAME_BASE := "stickey_input/input_nicknames"
const SETTING_NAME_DEFAULT_BINDINGS_KEYS_BASE := "stickey_input/default_bindings/keyboard"
const SETTING_NAME_DEFAULT_BINDINGS_MOUSE_BASE := "stickey_input/default_bindings/mouse"
const SETTING_NAME_MOUSE_MOTION_CONTROL := "stickey_input/default_bindings/general/mouse_motion_input"
const SETTING_VALUE_MOUSE_MOTION_CONTROL := 1
const SETTING_HINT_MOUSE_MOTION_CONTROL := "None:-1,Left Stick:0,Right Stick:1"

func _enable_plugin() -> void:
	add_autoload_singleton("StickeyManager", "src/stickey_manager.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("StickeyManager")


func _enter_tree() -> void:
	if !ProjectSettings.has_setting(SETTING_NAME_TRIGGER_PRESS_THRESHOLD):
		ProjectSettings.set_setting(SETTING_NAME_TRIGGER_PRESS_THRESHOLD, SETTING_VALUE_TRIGGER_PRESS_THRESHOLD)
	ProjectSettings.set_initial_value(SETTING_NAME_TRIGGER_PRESS_THRESHOLD, SETTING_VALUE_TRIGGER_PRESS_THRESHOLD)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_TRIGGER_PRESS_THRESHOLD,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.01,1.0"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_TRIGGER_RELEASE_THRESHOLD):
		ProjectSettings.set_setting(SETTING_NAME_TRIGGER_RELEASE_THRESHOLD, SETTING_VALUE_TRIGGER_RELEASE_THRESHOLD)
	ProjectSettings.set_initial_value(SETTING_NAME_TRIGGER_RELEASE_THRESHOLD, SETTING_VALUE_TRIGGER_RELEASE_THRESHOLD)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_TRIGGER_RELEASE_THRESHOLD,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,0.99"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_LEFT_STICK_DEADZONE):
		ProjectSettings.set_setting(SETTING_NAME_LEFT_STICK_DEADZONE, SETTING_VALUE_LEFT_STICK_DEADZONE)
	ProjectSettings.set_initial_value(SETTING_NAME_LEFT_STICK_DEADZONE, SETTING_VALUE_LEFT_STICK_DEADZONE)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_LEFT_STICK_DEADZONE,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,0.5"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_RIGHT_STICK_DEADZONE):
		ProjectSettings.set_setting(SETTING_NAME_RIGHT_STICK_DEADZONE, SETTING_VALUE_RIGHT_STICK_DEADZONE)
	ProjectSettings.set_initial_value(SETTING_NAME_RIGHT_STICK_DEADZONE, SETTING_VALUE_RIGHT_STICK_DEADZONE)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_RIGHT_STICK_DEADZONE,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,0.5"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_TRIGGER_DEADZONE):
		ProjectSettings.set_setting(SETTING_NAME_TRIGGER_DEADZONE, SETTING_VALUE_TRIGGER_DEADZONE)
	ProjectSettings.set_initial_value(SETTING_NAME_TRIGGER_DEADZONE, SETTING_VALUE_TRIGGER_DEADZONE)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_TRIGGER_DEADZONE,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,0.99"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_MOUSE_SENSITIVITY):
		ProjectSettings.set_setting(SETTING_NAME_MOUSE_SENSITIVITY, SETTING_VALUE_MOUSE_SENSITIVITY)
	ProjectSettings.set_initial_value(SETTING_NAME_MOUSE_SENSITIVITY, SETTING_VALUE_MOUSE_SENSITIVITY)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_MOUSE_SENSITIVITY,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.01,1.0,or_greater"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_MOUSE_DECAY):
		ProjectSettings.set_setting(SETTING_NAME_MOUSE_DECAY, SETTING_VALUE_MOUSE_DECAY)
	ProjectSettings.set_initial_value(SETTING_NAME_MOUSE_DECAY, SETTING_VALUE_MOUSE_DECAY)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_MOUSE_DECAY,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "10.0,40.0,or_greater"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_MOUSE_CLAMP):
		ProjectSettings.set_setting(SETTING_NAME_MOUSE_CLAMP, SETTING_VALUE_MOUSE_CLAMP)
	ProjectSettings.set_initial_value(SETTING_NAME_MOUSE_CLAMP, SETTING_VALUE_MOUSE_CLAMP)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_MOUSE_CLAMP,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1.0,10.0,or_greater"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_INPUT_HISTORY_BUFFER_SIZE):
		ProjectSettings.set_setting(SETTING_NAME_INPUT_HISTORY_BUFFER_SIZE, SETTING_VALUE_INPUT_HISTORY_BUFFER_SIZE)
	ProjectSettings.set_initial_value(SETTING_NAME_INPUT_HISTORY_BUFFER_SIZE, SETTING_VALUE_INPUT_HISTORY_BUFFER_SIZE)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_INPUT_HISTORY_BUFFER_SIZE,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,120,or_greater"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_CONFIG_FILE_SECTION):
		ProjectSettings.set_setting(SETTING_NAME_CONFIG_FILE_SECTION, SETTING_VALUE_CONFIG_FILE_SECTION)
	ProjectSettings.set_initial_value(SETTING_NAME_CONFIG_FILE_SECTION, SETTING_VALUE_CONFIG_FILE_SECTION)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_CONFIG_FILE_SECTION,
		"type": TYPE_STRING
	})
	if !ProjectSettings.has_setting(SETTING_NAME_CONFIG_FILE_PATH):
		ProjectSettings.set_setting(SETTING_NAME_CONFIG_FILE_PATH, SETTING_VALUE_CONFIG_FILE_PATH)
	ProjectSettings.set_initial_value(SETTING_NAME_CONFIG_FILE_PATH, SETTING_VALUE_CONFIG_FILE_PATH)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_CONFIG_FILE_PATH,
		"type": TYPE_STRING,
		"hint": TYPE_STRING
	})
	if !ProjectSettings.has_setting(SETTING_NAME_GLYPHS_BASE_PATH):
		ProjectSettings.set_setting(SETTING_NAME_GLYPHS_BASE_PATH, SETTING_VALUE_GLYPHS_BASE_PATH)
	ProjectSettings.set_initial_value(SETTING_NAME_GLYPHS_BASE_PATH, SETTING_VALUE_GLYPHS_BASE_PATH)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_GLYPHS_BASE_PATH,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR
	})
	if !ProjectSettings.has_setting(SETTING_NAME_MOUSE_MOTION_CONTROL):
		ProjectSettings.set_setting(SETTING_NAME_MOUSE_MOTION_CONTROL, SETTING_VALUE_MOUSE_MOTION_CONTROL)
	ProjectSettings.set_initial_value(SETTING_NAME_MOUSE_MOTION_CONTROL, SETTING_VALUE_MOUSE_MOTION_CONTROL)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_MOUSE_MOTION_CONTROL,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": SETTING_HINT_MOUSE_MOTION_CONTROL
	})
	for n in Stickey.MAX_INPUT_MASK_BITS:
		_add_setting_input_nickname(n)
	for n in Stickey.InputType.values():
		_add_setting_default_binding_keyboard(n)
		_add_setting_default_binding_mouse(n)

func _add_setting_input_nickname(input : Stickey.InputType) -> void:
	var path: String = "%s/%s"%[
		SETTING_NAME_INPUT_NICKNAME_BASE,
		Stickey.get_input_type_string(input).replace("-", "").validate_filename().to_snake_case()
		]
	if !ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, "")
	ProjectSettings.set_initial_value(path, "")
	ProjectSettings.add_property_info({
		"name": path,
		"type": TYPE_STRING
	})

func _add_setting_default_binding_keyboard(input : Stickey.InputType) -> void:
	var path: String = "%s/%s"%[
		SETTING_NAME_DEFAULT_BINDINGS_KEYS_BASE,
		Stickey.get_input_type_string(input).replace("-", "").validate_filename().to_snake_case()
		]
	var enum_hint: String = "Unassigned:-1"
	var key_values: PackedInt32Array
	for n in range(KEY_SPACE, KEY_QUOTELEFT): key_values.append(n)
	for n in range(KEY_ESCAPE, KEY_F12): key_values.append(n)
	for n in range(KEY_BRACELEFT, KEY_ASCIITILDE): key_values.append(n)
	for n in key_values:
		enum_hint = "%s,%s:%s"%[enum_hint,
		OS.get_keycode_string(n).replace(":", "").replace(",", ""),
		n
		]
	var default_value: int = -1
	match input:
		Stickey.InputType.SOUTH: default_value = KEY_SPACE
		Stickey.InputType.EAST: default_value = KEY_E
		Stickey.InputType.WEST: default_value = KEY_Q
		Stickey.InputType.NORTH: default_value = KEY_R
		Stickey.InputType.BACK: default_value = KEY_TAB
		Stickey.InputType.START: default_value = KEY_ESCAPE
		Stickey.InputType.L_STICK_PRESS: default_value = KEY_SHIFT
		Stickey.InputType.R_STICK_PRESS: default_value = KEY_ALT
		Stickey.InputType.L_SHOULDER: default_value = KEY_C
		Stickey.InputType.R_SHOULDER: default_value = KEY_V
		Stickey.InputType.UP_DIRECTION: default_value = KEY_UP
		Stickey.InputType.DOWN_DIRECTION: default_value = KEY_DOWN
		Stickey.InputType.LEFT_DIRECTION: default_value = KEY_LEFT
		Stickey.InputType.RIGHT_DIRECTION: default_value = KEY_RIGHT
		Stickey.InputType.PADDLE_1: default_value = KEY_F
		Stickey.InputType.PADDLE_2: default_value = KEY_T
		Stickey.InputType.PADDLE_3: default_value = KEY_G
		Stickey.InputType.PADDLE_4: default_value = KEY_X
		Stickey.InputType.TOUCH_PAD: default_value = KEY_Z
		Stickey.InputType.MISC_2: default_value = KEY_1
		Stickey.InputType.MISC_3: default_value = KEY_2
		Stickey.InputType.MISC_4: default_value = KEY_3
		Stickey.InputType.MISC_5: default_value = KEY_4
		Stickey.InputType.MISC_6: default_value = KEY_5
		Stickey.InputType.MISC_7: default_value = KEY_6
		Stickey.InputType.MISC_8: default_value = KEY_7
		Stickey.InputType.MISC_9: default_value = KEY_8
		Stickey.InputType.MISC_10: default_value = KEY_9
		Stickey.InputType.L_STICK_UP: default_value = KEY_W
		Stickey.InputType.L_STICK_DOWN: default_value = KEY_S
		Stickey.InputType.L_STICK_LEFT: default_value = KEY_A
		Stickey.InputType.L_STICK_RIGHT: default_value = KEY_D
	if !ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, default_value)
	ProjectSettings.set_initial_value(path, default_value)
	ProjectSettings.add_property_info({
		"name": path,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": enum_hint
	})

func _add_setting_default_binding_mouse(input : Stickey.InputType) -> void:
	var path: String = "%s/%s"%[
		SETTING_NAME_DEFAULT_BINDINGS_MOUSE_BASE,
		Stickey.get_input_type_string(input).replace("-", "").validate_filename().to_snake_case()
		]
	var enum_hint: String = "Unassigned:-1"
	for n in range(MOUSE_BUTTON_LEFT, MOUSE_BUTTON_XBUTTON2):
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
		enum_hint = "%s,%s:%s"%[enum_hint, mouse_string, n]
	var default_value: int = -1
	match input:
		Stickey.InputType.R_STICK_PRESS: default_value = MOUSE_BUTTON_MIDDLE
		Stickey.InputType.UP_DIRECTION: default_value = MOUSE_BUTTON_WHEEL_UP
		Stickey.InputType.DOWN_DIRECTION: default_value = MOUSE_BUTTON_WHEEL_DOWN
		Stickey.InputType.LEFT_DIRECTION: default_value = MOUSE_BUTTON_WHEEL_LEFT
		Stickey.InputType.RIGHT_DIRECTION: default_value = MOUSE_BUTTON_WHEEL_RIGHT
		Stickey.InputType.L_TRIGGER: default_value = MOUSE_BUTTON_RIGHT
		Stickey.InputType.R_TRIGGER: default_value = MOUSE_BUTTON_LEFT
	if !ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, default_value)
	ProjectSettings.set_initial_value(path, default_value)
	ProjectSettings.add_property_info({
		"name": path,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": enum_hint
	})
