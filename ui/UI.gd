extends CanvasLayer


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal request_sent(info)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var initial_menu : StringName = &""


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for child in get_children():
		if child.has_signal("menu_change_requested"):
			child.connect("menu_change_requested", show_menu)
		if child.has_signal("request_sent"):
			child.connect("request_sent", _on_request_sent)
	call_deferred("show_menu", initial_menu)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reshow_initial_menu() -> void:
	if initial_menu != "":
		show_menu(initial_menu)

func show_menu(menu_name : StringName) -> void:
	for child in get_children():
		if child.has_method(&"show_if_named"):
			child.show_if_named(menu_name)

func hide_menus() -> void:
	show_menu(&"")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_request_sent(info : Dictionary) -> void:
	request_sent.emit(info)
