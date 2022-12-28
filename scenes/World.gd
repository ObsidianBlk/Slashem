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
@onready var _score : Control = $HUD/Score
@onready var _death_screen : Control = $HUD/DeathScreen

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
		_ui.visible = false
		_hud.visible = true
		_player.visible = true
		_LoadLevel(DEFAULT_LEVEL_PATH)
		_effects.fade_in(TRANSITION_TIME, func(): get_tree().paused = false)

func _UpdateConfig() -> void:
	Statistics.save_to_config(config)
	config.save(CONFIG_PATH)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_ghost_killed() -> void:
	Statistics.mob_killed()
	_score.add_score(1)

func _on_player_killed():
	Statistics.player_died()
	_death_screen.visible = true
	_UpdateConfig()

func _on_game_completed() -> void:
	_UpdateConfig()
	get_tree().paused = true

func _on_game_start_requested():
	if not _game_active:
		_game_active = true
		_effects.fade_out(TRANSITION_TIME, _PrepareGame)

func _on_quit_requested():
	_UpdateConfig()
	get_tree().quit()
