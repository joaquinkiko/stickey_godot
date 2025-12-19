@tool
extends EditorPlugin

const SETTING_BASE_NAME := "stickey_input"
const SETTING_NAME_TRIGGER_PRESS_THRESHOLD := "%s/joystick/trigger/press_threshold"%SETTING_BASE_NAME
const SETTING_VALUE_TRIGGER_PRESS_THRESHOLD := 0.50
const SETTING_NAME_TRIGGER_RELEASE_THRESHOLD := "%s/joystick/trigger/release_threshold"%SETTING_BASE_NAME
const SETTING_VALUE_TRIGGER_RELEASE_THRESHOLD := 0.70
const SETTING_NAME_LEFT_STICK_DEADZONE := "%s/joystick/left_stick/deadzone"%SETTING_BASE_NAME
const SETTING_VALUE_LEFT_STICK_DEADZONE := 0.05
const SETTING_NAME_RIGHT_STICK_DEADZONE := "%s/joystick/right_stick/deadzone"%SETTING_BASE_NAME
const SETTING_VALUE_RIGHT_STICK_DEADZONE := 0.05
const SETTING_NAME_TRIGGER_DEADZONE := "%s/joystick/trigger/deadzone"%SETTING_BASE_NAME
const SETTING_VALUE_TRIGGER_DEADZONE := 0.30
const SETTING_NAME_MOUSE_SENSITIVITY := "%s/mouse/sensitivity"%SETTING_BASE_NAME
const SETTING_VALUE_MOUSE_SENSITIVITY := 0.30
const SETTING_NAME_MOUSE_DECAY := "%s/mouse/decay_rate"%SETTING_BASE_NAME
const SETTING_VALUE_MOUSE_DECAY := 10.0
const SETTING_NAME_MOUSE_CLAMP := "%s/mouse/max_speed"%SETTING_BASE_NAME
const SETTING_VALUE_MOUSE_CLAMP := 5.0
const SETTING_NAME_INPUT_HISTORY_BUFFER_SIZE := "%s/general/input_history/buffer_frames"%SETTING_BASE_NAME
const SETTING_VALUE_INPUT_HISTORY_BUFFER_SIZE := 60
const SETTING_NAME_CONFIG_FILE_SECTION := "%s/general/serialization/section_key"%SETTING_BASE_NAME
const SETTING_VALUE_CONFIG_FILE_SECTION := "InputMappings"

func _enable_plugin() -> void:
	add_autoload_singleton("StickeyInputManager", "stickey_input.gd")
	add_autoload_singleton("StickeyPlayerManager", "stickey_player.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("StickeyInputManager")
	remove_autoload_singleton("StickeyPlayerManager")


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
		"hint_string": "0.01,2.0,or_greater"
	})
	if !ProjectSettings.has_setting(SETTING_NAME_MOUSE_DECAY):
		ProjectSettings.set_setting(SETTING_NAME_MOUSE_DECAY, SETTING_VALUE_MOUSE_DECAY)
	ProjectSettings.set_initial_value(SETTING_NAME_MOUSE_DECAY, SETTING_VALUE_MOUSE_DECAY)
	ProjectSettings.add_property_info({
		"name": SETTING_NAME_MOUSE_DECAY,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1.0,20.0,or_greater"
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
