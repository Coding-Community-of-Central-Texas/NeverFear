extends Control

@export_file("*.tscn") var target_scene_path := "res://Scenes/HubWorld.tscn"
@export var minimum_display_time := 2.5
@export var progress_ease := 8.0
@export var use_threaded_loading := true

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var percent_label: Label = %PercentLabel
@onready var status_label: Label = %StatusLabel
@onready var tick_container: HBoxContainer = %TickContainer
@onready var edge_glow: ColorRect = %EdgeGlow
@onready var pulse: ColorRect = %Pulse
@onready var bar_fx: Control = %BarFx
@onready var bar_shell: Panel = $HudPanel/BarShell
@onready var continue_button: TouchScreenButton = $HudPanel/TouchScreenProgress

var _elapsed := 0.0
var _threaded_progress := 0.0
var _displayed_progress := 0.0
var _loaded_scene: PackedScene
var _load_complete := false
var _transition_started := false
var _waiting_for_input := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.visible = false
	var pressed_callback := Callable(self, "_on_continue_pressed")
	if not continue_button.pressed.is_connected(pressed_callback):
		continue_button.pressed.connect(pressed_callback)
	_build_segment_ticks()
	if use_threaded_loading:
		_start_threaded_load()
	_update_progress_ui(0.0)


func _process(delta: float) -> void:
	if _waiting_for_input:
		return

	_elapsed += delta
	_poll_threaded_load()
	_update_displayed_progress(delta)
	_update_progress_ui(_displayed_progress)

	if _load_complete and not _transition_started and _elapsed >= minimum_display_time and _displayed_progress >= 0.995:
		_show_continue_prompt()


func _start_threaded_load() -> void:
	var error := ResourceLoader.load_threaded_request(target_scene_path)
	if error != OK:
		push_warning("LoadScreen: threaded load failed to start for %s. Falling back to blocking load." % target_scene_path)
		_loaded_scene = load(target_scene_path)
		_load_complete = _loaded_scene != null


func _poll_threaded_load() -> void:
	if not use_threaded_loading:
		_threaded_progress = min(0.96, _elapsed / minimum_display_time)
		status_label.text = _status_for_progress(_threaded_progress)
		if _elapsed >= minimum_display_time:
			_threaded_progress = 1.0
			_load_complete = true
			status_label.text = "system ready"
		return

	if _load_complete:
		return

	var progress := []
	var status := ResourceLoader.load_threaded_get_status(target_scene_path, progress)

	if progress.size() > 0:
		_threaded_progress = clampf(progress[0], _threaded_progress, 1.0)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			status_label.text = _status_for_progress(_threaded_progress)
		ResourceLoader.THREAD_LOAD_LOADED:
			_threaded_progress = 1.0
			_loaded_scene = ResourceLoader.load_threaded_get(target_scene_path)
			_load_complete = _loaded_scene != null
			status_label.text = "system ready"
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("LoadScreen: failed to load %s" % target_scene_path)
			_loaded_scene = load(target_scene_path)
			_threaded_progress = 1.0
			_load_complete = _loaded_scene != null


func _update_displayed_progress(delta: float) -> void:
	var target_progress: float = _threaded_progress

	if _load_complete:
		if _elapsed < minimum_display_time:
			target_progress = min(0.97, max(target_progress, _elapsed / minimum_display_time * 0.97))
		else:
			target_progress = 1.0
	else:
		var ambient_progress: float = min(0.86, _elapsed / minimum_display_time * 0.86)
		target_progress = max(target_progress, ambient_progress)

	_displayed_progress = lerpf(_displayed_progress, target_progress, min(1.0, delta * progress_ease))


func _update_progress_ui(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)
	progress_bar.value = progress * progress_bar.max_value
	percent_label.text = "%03d%%" % roundi(progress * 100.0)

	var fill_width: float = bar_fx.size.x * progress
	edge_glow.visible = fill_width > 6.0
	edge_glow.position.x = clampf(fill_width - edge_glow.size.x * 0.5, 0.0, max(0.0, bar_fx.size.x - edge_glow.size.x))

	pulse.visible = fill_width > 48.0
	if pulse.visible:
		var sweep_width: float = max(fill_width + pulse.size.x, pulse.size.x)
		pulse.position.x = fposmod(_elapsed * 360.0, sweep_width) - pulse.size.x

	for index in range(tick_container.get_child_count()):
		var tick := tick_container.get_child(index) as ColorRect
		if tick == null:
			continue
		var tick_progress := float(index + 1) / float(tick_container.get_child_count())
		tick.color = Color(0.82, 0.98, 1.0, 0.88) if tick_progress <= progress else Color(0.25, 0.7, 0.9, 0.2)


func _build_segment_ticks() -> void:
	for child in tick_container.get_children():
		child.queue_free()

	for index in range(24):
		var tick := ColorRect.new()
		tick.custom_minimum_size = Vector2(3.0, 38.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.color = Color(0.25, 0.7, 0.9, 0.2)
		tick_container.add_child(tick)


func _status_for_progress(progress: float) -> String:
	if progress < 0.25:
		return "waking systems"
	if progress < 0.5:
		return "syncing level data"
	if progress < 0.75:
		return "charging hypercore"
	if progress < 0.98:
		return "finalizing"
	return "system ready"


func _show_continue_prompt() -> void:
	_waiting_for_input = true
	bar_shell.visible = false
	edge_glow.visible = false
	pulse.visible = false
	continue_button.visible = true
	status_label.text = "tap to continue"


func _on_continue_pressed() -> void:
	if not _waiting_for_input or _transition_started:
		return

	_transition_to_loaded_scene()


func _transition_to_loaded_scene() -> void:
	_transition_started = true
	if _loaded_scene != null:
		get_tree().change_scene_to_packed(_loaded_scene)
		return

	var error := get_tree().change_scene_to_file(target_scene_path)
	if error != OK:
		push_error("LoadScreen: failed to change scene to %s" % target_scene_path)
