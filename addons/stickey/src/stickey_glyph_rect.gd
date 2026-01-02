## Displays [TextureRect] based for specific input glyph
class_name StickeyGlyphRect extends TextureRect

## Input to display
var input: Stickey.InputType:
	get: return _input
	set(value):
		_input = value
		update_glyph()
## Input to display
@export
var _input: Stickey.InputType

## Input type (use Automatic to use [member device_source] to determine type
var device_type: Stickey.DeviceType:
	get: return _type
	set(value):
		_type = value
		update_glyph()
## Input type (use Automatic to use [member device_source] to determine type
@export
var _type: Stickey.DeviceType = Stickey.DeviceType.AUTOMATIC

@export_group("Automatic Settings")

## Device index if using Automatic for [member device_type]
var device_source: int:
	get: return _device_source
	set(value):
		_device_source = value
		update_glyph()
## Device index if using Automatic for [member device_type]
@export_enum("Keyboard:%s"%Stickey.KEYBOARD_INDEX,
	"Primary Device:0",
	"2nd Device:1",
	"3rd Device:2",
	"4th Device:3",
	"5th Device:4",
	"6th Device:5",
	"7th Device:6",
	"8th Device:7",
	)
var _device_source: int = 0

## When using [member device_type] automatic, auto switch based on primary device
var auto_switch_primary: bool:
	get: return _device_source
	set(value):
		_auto_switch_primary = value
		update_glyph()
## When using [member device_type] automatic, auto switch based on primary device
@export
var _auto_switch_primary: bool = true

func _ready() -> void:
	StickeyManager.device_connected.connect(_device_connected)
	StickeyManager.device_disconnected.connect(_device_disconnected)
	StickeyManager.primary_device_changed.connect(_primary_device_changed)
	update_glyph()

func _device_connected(index: int) -> void:
	update_glyph()

func _device_disconnected(index: int) -> void:
	update_glyph()

func _primary_device_changed(is_keyboard: bool) -> void:
	update_glyph()

## Updates currently displayed glyph. Typically called automatically
func update_glyph() -> void:
	var index := device_source
	if device_type == Stickey.DeviceType.AUTOMATIC:
		if index == Stickey.keyboard_shared_device && StickeyManager.is_keyboard_primary:
			index = Stickey.KEYBOARD_INDEX
		elif index == Stickey.KEYBOARD_INDEX && !StickeyManager.is_keyboard_primary:
			index = Stickey.keyboard_shared_device
	if device_type == Stickey.DeviceType.AUTOMATIC && Stickey.devices.has(index):
		texture = Stickey.devices[index].get_input_glyph(input)
	else:
		texture = Stickey.get_input_glyph(input, device_type)
