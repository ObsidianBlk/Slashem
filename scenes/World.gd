extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TRANSITION_TIME : float = 1.0
const CONFIG_PATH : String = "user://slashem.config"
const DEFAULT_LEVEL_PATH : String = "res://scenes/Levels/Level_001.tscn"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var config : ConfigFile = ConfigFile.new()
var _level : Node2D = null
var _game_active : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ui : CanvasLayer = $UI
@onready var _hud : CanvasLayer = $HUD
@onready var _effects : CanvasLayer = $EffectLayer
@onready var _player : Node2D = $Player

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ui.visible = true
	_hud.visible = false
	Statistics.run_completed.connect(_on_game_completed)
	if config.load(CONFIG_PATH) == OK:
		Statistics.load_from_config(config)
	get_tree().paused = true

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _LoadLevel(path : String) -> void:
	var LevelScene : PackedScene = load(path)
	if LevelScene != null:
		_level = LevelScene.instantiate()
		if _level != null and _level.has_method(&"get_player_start"):
			_ui.add_sibling(_level)
			call_deferred("_UpdatePlayerLocation")

func _UpdatePlayerLocation() -> void:
	if _level != null:
		_player.global_position = _level.get_player_start()

func _PrepareGame() -> void:
	if _level == null:
		var finalize : Callable = func():
			Statistics.start_run(90.0)
			_game_active = false
			get_tree().paused = false
		_ui.visible = false
		_hud.visible = true
		_player.visible = true
		_LoadLevel(DEFAULT_LEVEL_PATH)
		_effects.fade_in(TRANSITION_TIME, finalize)

func _ClearOutGame() -> void:
	remove_child(_level)
	_level.queue_free()
	_level = null
	_hud.visible = false
	_ui.visible = true
	_ui.show_menu(&"StatsMenu")
	_player.visible = false
	_effects.fade_in(TRANSITION_TIME)

func _UpdateConfig() -> void:
	Statistics.save_to_config(config)
	config.save(CONFIG_PATH)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_ghost_killed() -> void:
	Statistics.mob_killed()

func _on_game_completed(_player_died : bool) -> void:
	_UpdateConfig()
	get_tree().paused = true
	_effects.fade_out(TRANSITION_TIME, _ClearOutGame)

func _on_ui_request_sent(info : Dictionary):
	if &"request" in info:
		match info[&"request"]:
			&"start_game":
				if not _game_active:
					_game_active = true
					_effects.fade_out(TRANSITION_TIME, _PrepareGame)
			&"quit_game":
				_UpdateConfig()
				get_tree().quit()
