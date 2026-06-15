extends Node

const MAX_POOLED_NUMBERS := 96

var _inactive_numbers: Array[Label] = []
var _active_tweens: Dictionary = {}
var _number_lifecycle_id := 0

func display_number(value: int, position: Vector2, is_critical: bool = false):
	var number := _get_number()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.visible = true
	number.scale = Vector2.ONE
	number.process_mode = Node.PROCESS_MODE_INHERIT
	if number.label_settings == null:
		number.label_settings = LabelSettings.new()
	
	var color = "#FFF"
	if is_critical:
		color = "#B22"
	if value == 0:
		color = "#FFF8"
		
	
	number.label_settings.font_color = color
	number.label_settings.font_size = 35 
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 6 
	
	if number.get_parent() == null:
		add_child(number)

	number.reset_size()
	_number_lifecycle_id += 1
	var lifecycle_id := _number_lifecycle_id
	number.set_meta("damage_number_lifecycle_id", lifecycle_id)

	await get_tree().process_frame
	if not is_instance_valid(number):
		return
	if int(number.get_meta("damage_number_lifecycle_id", -1)) != lifecycle_id:
		return

	number.pivot_offset = Vector2(number.size / 2)
	
	if _active_tweens.has(number):
		var old_tween: Tween = _active_tweens[number]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	var tween = get_tree().create_tween()
	_active_tweens[number] = tween
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y, 0.5
		).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
			number, "scale", Vector2.ZERO, 0.25
		).set_ease(Tween.EASE_IN).set_delay(0.5)
	await tween.finished
	if not is_instance_valid(number):
		return
	if int(number.get_meta("damage_number_lifecycle_id", -1)) == lifecycle_id:
		_return_number(number)

func _get_number() -> Label:
	while not _inactive_numbers.is_empty():
		var number: Label = _inactive_numbers.pop_back() as Label
		if number != null and is_instance_valid(number):
			return number

	return Label.new()

func _return_number(number: Label) -> void:
	if number == null or not is_instance_valid(number):
		return

	_active_tweens.erase(number)
	number.visible = false
	number.text = ""
	number.scale = Vector2.ONE
	number.process_mode = Node.PROCESS_MODE_DISABLED

	if _inactive_numbers.size() < MAX_POOLED_NUMBERS:
		_inactive_numbers.append(number)
	else:
		number.queue_free()
