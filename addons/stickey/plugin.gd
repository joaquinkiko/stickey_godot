@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("StickeyInputManager", "stickey_input.gd")
	add_autoload_singleton("StickeyPlayerManager", "stickey_player.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("StickeyInputManager")
	remove_autoload_singleton("StickeyPlayerManager")


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
