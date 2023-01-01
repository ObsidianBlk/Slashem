extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal stats_loaded(info)
signal run_completed(player_died)
signal run_kills_changed(amount)
signal run_time_changed(remaining, total)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CONFIG_SECTION : String = "Statistics"
const MAX_STORED_RUNS : int = 10

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _runs : int = 0
var _abandoned : int = 0
var _deaths : int = 0
var _kills : int = 0
var _best_runs : Array = []

var _run_timer : SceneTreeTimer = null
var _active_run : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _physics_process(_delta : float) -> void:
	if _run_timer != null and not _active_run.is_empty():
		run_time_changed.emit(_run_timer.time_left, _active_run.time_run)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _FinalizeRun() -> void:
	if not _active_run.is_empty():
		_kills += _active_run.kills
		var search_method : Callable = func(a, b):
			var a_success : bool = a.time_run <= a.time_survived
			var b_success : bool = b.time_run <= b.time_survived
			if a_success and not b_success:
				return true
			elif a_success == b_success:
				return a.kills > b.kills
			return false
		var idx = _best_runs.bsearch_custom(_active_run, search_method, true)
		if idx >= 0:
			_best_runs.insert(idx, _active_run)
			if _best_runs.size() > MAX_STORED_RUNS:
				_best_runs.pop_back()
		_active_run = {}

func _LoadValFromConfig(cfg : ConfigFile, key : String, type : int) -> bool:
	if cfg.has_section_key(CONFIG_SECTION, key):
		var v = cfg.get_value(CONFIG_SECTION, key)
		if typeof(v) == type:
			match key:
				"runs":
					_runs = v
				"abandoned":
					_abandoned = v
				"deaths":
					_deaths = v
				"kills":
					_kills = v
				_:
					return false
			return true
	printerr("ERROR: Statistic key \"%s\" missing or invalid."%[key])
	return false

func _LoadBestFromConfig(cfg : ConfigFile) -> bool:
	if cfg.has_section_key(CONFIG_SECTION, "best"):
		var best = cfg.get_value(CONFIG_SECTION, "best")
		if typeof(best) != TYPE_ARRAY:
			printerr("ERROR: Statistic key \"best\" invalid type.")
			return false
		
		_best_runs.clear()
		for item in best:
			var prop_missing : bool = false
			for prop in [["time_run", TYPE_FLOAT], ["time_survived", TYPE_FLOAT], ["kills", TYPE_INT]]:
				if not prop[0] in item:
					printerr("WARNING: Statistic's best run list item missing required property. Skipping.")
					prop_missing = true
					break
				if typeof(item[prop[0]]) != prop[1]:
					printerr("WARNING: Statistic's best run list item property \"%s\" type invalid."%[prop[0]])
					prop_missing = true
					break
			if prop_missing:
				continue
			_best_runs.append({
				"time_run" : item["time_run"],
				"time_survived": item["time_survived"],
				"kills": item["kills"]
			})
			
	return true

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reset_statistics() -> void:
	_runs = 0
	_abandoned = 0
	_deaths = 0
	_kills = 0
	_best_runs.clear()
	stats_loaded.emit(get_stats())

func save_to_config(cfg : ConfigFile) -> void:
	cfg.set_value(CONFIG_SECTION, "runs", _runs)
	cfg.set_value(CONFIG_SECTION, "abandoned", _abandoned)
	cfg.set_value(CONFIG_SECTION, "deaths", _deaths)
	cfg.set_value(CONFIG_SECTION, "kills", _kills)
	cfg.set_value(CONFIG_SECTION, "best", _best_runs)

func load_from_config(cfg : ConfigFile) -> void:
	if not cfg.has_section(CONFIG_SECTION):
		printerr("WARNING: Config missing %s section. Statistics not loaded."%[CONFIG_SECTION])
		return
	if not _LoadBestFromConfig(cfg):
		return
	if not _LoadValFromConfig(cfg, "runs", TYPE_INT):
		return
	if not _LoadValFromConfig(cfg, "abandoned", TYPE_INT):
		return
	if not _LoadValFromConfig(cfg, "deaths", TYPE_INT):
		return
	if _LoadValFromConfig(cfg, "kills", TYPE_INT):
		stats_loaded.emit(get_stats())


func start_run(duration : float) -> void:
	if duration > 0.0 and _run_timer == null:
		_runs += 1
		_active_run = {
			"time_run" : duration,
			"time_survived": 0.0,
			"kills": 0
		}
		run_kills_changed.emit(0)
		_run_timer = get_tree().create_timer(duration)
		_run_timer.timeout.connect(_on_run_timedout)

func abandon_run() -> void:
	if not _active_run.is_empty():
		if _run_timer != null:
			_run_timer.timeout.disconnect(_on_run_timedout)
			_run_timer = null
		_abandoned += 1

func player_died() -> void:
	if not _active_run.is_empty():
		if _run_timer != null:
			_run_timer.timeout.disconnect(_on_run_timedout)
			_active_run.time_survived = _active_run.time_run - _run_timer.time_left
			_run_timer = null
		_deaths += 1
		_FinalizeRun()
		run_completed.emit(true)

func mob_killed() -> void:
	if not _active_run.is_empty():
		_active_run.kills += 1
		#_kills += 1
		run_kills_changed.emit(_active_run.kills)

func get_stats() -> Dictionary:
	var bests : Array = []
	for item in _best_runs:
		bests.append({
			"time_run": item.time_run,
			"time_survived": item.time_survived,
			"kills": item.kills
		})
	return {
		"runs": _runs,
		"abandoned": _abandoned,
		"deaths": _deaths,
		"kills": _kills,
		"bests": bests
	}

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_run_timedout() -> void:
	_run_timer = null
	_active_run.time_survived = _active_run.time_run
	_FinalizeRun()
	run_completed.emit(false)


