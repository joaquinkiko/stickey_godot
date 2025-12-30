extends Node

const KEYBOARD_INDEX = Stickey.KEYBOARD_INDEX

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


## Emitted when device is connected
signal device_connected(index: int)
## Emitted when device is disconnected
signal device_disconnected(index: int)
## Emitted when [member keyboard_shared_device] swaps between keyboard and gamepad as current device
signal primary_device_changed(is_keyboard: bool)

func _init() -> void:
	Stickey.trigger_press_threshold = ProjectSettings.get_setting("stickey_input/joystick/trigger/press_threshold", 0.5)
	Stickey.trigger_release_threshold = ProjectSettings.get_setting("stickey_input/joystick/trigger/release_threshold", 0.7)
	Stickey.left_stick_deadzone = ProjectSettings.get_setting("stickey_input/joystick/left_stick/deadzone", 0.05)
	Stickey.right_stick_deadzone = ProjectSettings.get_setting("stickey_input/joystick/right_stick/deadzone", 0.05)
	Stickey.trigger_deadzone = ProjectSettings.get_setting("stickey_input/joystick/trigger/deadzone", 0.3)
	Stickey.mouse_sensitivity = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/sensitivity", 0.1)
	Stickey.mouse_decay = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/decay_rate", 20.0)
	Stickey.mouse_clamp = ProjectSettings.get_setting("stickey_input/keyboard_and_mouse/mouse/max_speed", 7.0)
	Stickey.input_history_buffer_size = ProjectSettings.get_setting("stickey_input/general/input_history/buffer_frames", 60)
	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "Web":
			Stickey.connect_keyboard_device(&"Keyboard")
			Stickey.is_keyboard_primary = Input.get_connected_joypads().is_empty()
		"Android", "iOS":
			Stickey.connect_keyboard_device(&"Handheld")
			Stickey.is_keyboard_primary = Input.get_connected_joypads().is_empty()
		_:
			pass ## This would be unaccounted for custom console builds
	Stickey._initialize_default_mappings()
	Input.joy_connection_changed.connect(_joy_connection_changed)

func _joy_connection_changed(index: int, connected: bool) -> void:
	if connected:
		var device := StickeyDevice.new()
		device.index = index
		device.display_name = Input.get_joy_name(index)
		if device.display_name.contains("Xbox"): device.type = Stickey.DeviceType.XBOX
		elif device.display_name.contains("Switch"): device.type = Stickey.DeviceType.SWITCH
		elif device.display_name.contains("PS"): device.type = Stickey.DeviceType.PLAYSTATION
		elif device.display_name.contains("Steam Deck"): device.type = Stickey.DeviceType.STEAMDECK
		else: device.type = Stickey.DeviceType.GENERIC
		device.input_history.resize(Stickey.input_history_buffer_size)
		Stickey.devices[index] = device
		device_connected.emit(index)
		print("Device connected: %s (%s)"%[device.display_name, index])
		if Stickey.keyboard_shared_device == index && Stickey.is_keyboard_primary:
			Stickey.is_keyboard_primary = false
			primary_device_changed.emit(false)
	else:
		device_disconnected.emit(index)
		print("Device disconnected: %s (%s)"%[Stickey.devices[index].display_name, index])
		if Stickey.keyboard_shared_device == index && !Stickey.is_keyboard_primary:
			Stickey.is_keyboard_primary = true
			primary_device_changed.emit(true)
		Stickey.devices.erase(index)

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	match event.get_class():
		"InputEventKey":
			if !Stickey.devices.has(Stickey.KEYBOARD_INDEX): return
			if !Stickey.is_keyboard_primary:
				Stickey.is_keyboard_primary = true
				primary_device_changed.emit(true)
			if Stickey.keyboard_mappings.has(event.keycode):
				Stickey._update_button(Stickey.KEYBOARD_INDEX, Stickey.keyboard_mappings[event.keycode], event.pressed)
				match Stickey.keyboard_mappings[event.keycode]:
					Stickey.InputType.L_TRIGGER: Stickey._update_axis(Stickey.KEYBOARD_INDEX, Stickey.AxisType.L_TRIGGER, float(event.pressed))
					Stickey.InputType.R_TRIGGER: Stickey._update_axis(Stickey.KEYBOARD_INDEX, Stickey.AxisType.R_TRIGGER, float(event.pressed))
					Stickey.InputType.L_STICK_UP:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.L_STICK_Y, _StickBit.L_UP, _StickBit.L_DOWN, -1)
					Stickey.InputType.L_STICK_DOWN:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.L_STICK_Y, _StickBit.L_DOWN, _StickBit.L_UP, 1)
					Stickey.InputType.L_STICK_LEFT:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.L_STICK_X, _StickBit.L_LEFT, _StickBit.L_RIGHT, -1)
					Stickey.InputType.L_STICK_RIGHT:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.L_STICK_X, _StickBit.L_RIGHT, _StickBit.L_LEFT, 1)
					Stickey.InputType.R_STICK_UP:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.R_STICK_Y, _StickBit.R_UP, _StickBit.R_DOWN, -1)
					Stickey.InputType.R_STICK_DOWN:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.R_STICK_Y, _StickBit.R_DOWN, _StickBit.R_UP, 1)
					Stickey.InputType.R_STICK_LEFT:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.R_STICK_X, _StickBit.R_LEFT, _StickBit.R_RIGHT, -1)
					Stickey.InputType.R_STICK_RIGHT:
						Stickey._update_key_axis(event.pressed, Stickey.AxisType.R_STICK_X, _StickBit.R_RIGHT, _StickBit.R_LEFT, 1)
		"InputEventMouseButton":
			if !Stickey.devices.has(Stickey.KEYBOARD_INDEX): return
			if !Stickey.is_keyboard_primary:
				Stickey.is_keyboard_primary = true
				primary_device_changed.emit(true)
			if Stickey.mouse_mappings.has(event.button_index):
				Stickey._update_button(Stickey.KEYBOARD_INDEX, Stickey.mouse_mappings[event.button_index], event.pressed)
				match Stickey.mouse_mappings[event.button_index]:
					Stickey.InputType.L_TRIGGER: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_TRIGGER, float(event.pressed))
					Stickey.InputType.R_TRIGGER: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_TRIGGER, float(event.pressed))
					Stickey.InputType.L_STICK_UP: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, -float(event.pressed))
					Stickey.InputType.L_STICK_DOWN: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, float(event.pressed))
					Stickey.InputType.L_STICK_LEFT: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, -float(event.pressed))
					Stickey.InputType.L_STICK_RIGHT:Stickey. _update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, float(event.pressed))
					Stickey.InputType.R_STICK_UP: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, -float(event.pressed))
					Stickey.InputType.R_STICK_DOWN: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, float(event.pressed))
					Stickey.InputType.R_STICK_LEFT: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, -float(event.pressed))
					Stickey.InputType.R_STICK_RIGHT: Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, float(event.pressed))
		"InputEventMouseMotion":
			if !Stickey.devices.has(KEYBOARD_INDEX): return
			if !Stickey.is_keyboard_primary:
				Stickey.is_keyboard_primary = true
				primary_device_changed.emit(true)
			Stickey.mouse_raw = event.screen_relative * Stickey.mouse_sensitivity
			Stickey.mouse_raw = Stickey.mouse_raw.clampf(-Stickey.mouse_clamp, Stickey.mouse_clamp)
			match Stickey.mouse_stick:
				Stickey.Stick.LEFT:
					Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, Stickey.mouse_raw.x)
					Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, Stickey.mouse_raw.y)
				Stickey.Stick.RIGHT:
					Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, Stickey.mouse_raw.x)
					Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, Stickey.mouse_raw.y)
		"InputEventJoypadButton":
			if !Input.get_connected_joypads().has(event.device): return
			if event.device == Stickey.keyboard_shared_device && Stickey.is_keyboard_primary:
				Stickey.is_keyboard_primary = false
				primary_device_changed.emit(false)
			if Stickey.joy_remappings.has(event.button_index):
				Stickey._update_button(event.device, Stickey.joy_remappings[event.button_index], event.pressed)
			else:
				Stickey._update_button(event.device, event.button_index, event.pressed)
		"InputEventJoypadMotion":
			if !Input.get_connected_joypads().has(event.device): return
			if event.device == Stickey.keyboard_shared_device && Stickey.is_keyboard_primary:
				Stickey.is_keyboard_primary = false
				primary_device_changed.emit(false)
			Stickey._update_axis(event.device, event.axis, event.axis_value)
			# Update button masks
			match event.axis:
				JOY_AXIS_TRIGGER_LEFT:
					if Stickey.devices[event.device].is_pressed(Stickey.InputType.L_TRIGGER):
						if event.axis_value < Stickey.trigger_release_threshold:
							Stickey._update_button(event.device, Stickey.InputType.L_TRIGGER, false)
					elif event.axis_value > Stickey.trigger_press_threshold:
						Stickey._update_button(event.device, Stickey.InputType.L_TRIGGER, true)
				JOY_AXIS_TRIGGER_RIGHT:
					if Stickey.devices[event.device].is_pressed(Stickey.InputType.R_TRIGGER):
						if event.axis_value < Stickey.trigger_release_threshold:
							Stickey._update_button(event.device, Stickey.InputType.R_TRIGGER, false)
					elif event.axis_value > Stickey.trigger_press_threshold:
						Stickey._update_button(event.device, Stickey.InputType.R_TRIGGER, true)

func _notification(what: int) -> void:
	# On focus lost, reset inputs
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for index in Stickey.devices.keys():
			Stickey._update_axis(index, Stickey.AxisType.L_STICK_X, 0)
			Stickey._update_axis(index, Stickey.AxisType.L_STICK_Y, 0)
			Stickey._update_axis(index, Stickey.AxisType.R_STICK_X, 0)
			Stickey._update_axis(index, Stickey.AxisType.R_STICK_Y, 0)
			for input in Stickey.MAX_INPUT_MASK_BITS:
				if Stickey.devices[index].is_pressed(input):
					Stickey._update_button(index, input, false)
		if Stickey.devices.has(KEYBOARD_INDEX):
			Stickey._key_to_axis_mask = 0
			Stickey.mouse_raw = Vector2.ZERO

func _process(delta: float) -> void:
	if Stickey.mouse_raw != Vector2.ZERO && Input.get_last_mouse_screen_velocity() != Vector2.ZERO:
		Stickey.mouse_raw = Stickey.mouse_raw.lerp(Vector2.ZERO, delta * Stickey.mouse_decay)
		if Stickey.mouse_raw.is_equal_approx(Vector2.ZERO): Stickey.mouse_raw = Vector2.ZERO
		match Stickey.mouse_stick:
			Stickey.Stick.LEFT:
				Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_X, Stickey.mouse_raw.x)
				Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.L_STICK_Y, Stickey.mouse_raw.y)
			Stickey.Stick.RIGHT:
				Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_X, Stickey.mouse_raw.x)
				Stickey._update_axis(KEYBOARD_INDEX, Stickey.AxisType.R_STICK_Y, Stickey.mouse_raw.y)

func _physics_process(delta: float) -> void:
	for device: StickeyDevice in Stickey.devices.values():
		device.input_history_index = (device.input_history_index + 1) % Stickey.input_history_buffer_size
		device.input_history[device.input_history_index] = device.pressed_mask
