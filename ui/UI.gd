extends CanvasLayer


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal game_start_requested()
signal quit_requested()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var initial_menu : StringName = &""


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	call_deferred("show_menu", initial_menu)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : StringName) -> void:
	for child in get_children():
		if child.has_method(&"show_if_named"):
			child.show_if_named(menu_name)

func hide_menus() -> void:
	show_menu(&"")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_main_menu_game_start_requested():
	game_start_requested.emit()

func _on_main_menu_quit_requested():
	quit_requested.emit()
