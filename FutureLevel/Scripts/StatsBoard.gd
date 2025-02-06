extends LineEdit


@onready var popup_panel: PopupPanel = $".."
@onready var http_request: HTTPRequest = $"../../../HTTPRequest"
@onready var upload: Sprite2D = $"../Upload"
@onready var fill_text: TouchScreenButton = $FillText
@onready var name_input: LineEdit = %SendName

var adjectives = ["Quantum", "Synthetic", "Digital", "Neural", "Cybernetic", "Augmented", "Hyper", "Meta", "Virtual", "Holo", "Infra", "Autonomous", "Biometric", "Hacked", "Encrypted", "Glitched", "Optimized", "Parallel", "Void"]
var nouns = ["Protocol", "Cipher", "Grid", "Matrix", "Bot", "AI", "Code", "Drone", "Mainframe", "Algorithm", "Module", "Nexus", "Gateway", "Proxy", "Patch", "Core", "Kernel", "Terminal", "Synth", "Chip", "Datastream", "Firewall", "Echo", "Pulse", "Node", "Fragment", "Avatar", "Uplink", "Archive", "Command"]
var proper_nouns = ["Zephyr", "Nyx", "Orion", "Vex", "Echelon", "Aegis", "Solace", "Vector", "Oblivion", "Phobos", "Zer0", "Xypher", "Omicron", "Apollo", "Nebula", "Zypherion", "Seraphim", "Cronus", "Sypher", "Hyperion"]
var titles = ["Operative", "Sentinel", "Architect", "Overseer", "Technomancer", "Recon", "CipherMaster", "DataRunner", "NetGhost", "SynthLord", "Neural Engineer", "Quantum Analyst", "CyberSmith", "GridWalker", "Augmenter", "Protocol Enforcer", "Bytecaster", "Firewall Engineer", "Echo Specialist", "Mainframe Operator"]



func _ready() -> void:
	name_input.focus_mode = Control.FOCUS_ALL
	name_input.focus_entered.connect(_on_focus)  # Correct signal connection
	popup_panel.popup_window = true
	popup_panel.transient = true

func _on_focus() -> void:
	virtual_keyboard_enabled = true
	name_input.text_submitted.connect(_on_text_submitted)  # Handle Enter key

func _on_randimize_pressed() -> void:
	var random_choice = randi() % 3
	if random_choice == 0:
		var random_adjective = adjectives[randi() % adjectives.size()]
		var random_noun = nouns[randi() % nouns.size()]
		name_input.text = random_adjective + " " + random_noun
	elif random_choice == 1:
		var random_proper_noun = proper_nouns[randi() % proper_nouns.size()]
		var random_title = titles[randi() % titles.size()]
		name_input.text = random_proper_noun + " " + random_title
	else:
		var random_adjective = adjectives[randi() % adjectives.size()]
		var random_proper_noun = proper_nouns[randi() % proper_nouns.size()]
		name_input.text = random_adjective + " " + random_proper_noun

func _on_upload_button_pressed() -> void:
	GameManager.player_name = name_input.text
	GameManager.send_stats(http_request)
	%AudioStreamPlayer2D.play()
	upload.modulate = Color(0.5, 0.5, 0)
	await get_tree().create_timer(0.5).timeout
	upload.modulate = Color(1, 1, 1)
	await get_tree().create_timer(0.5).timeout
	_on_close_pressed()

func _on_text_submitted(new_text: String) -> void:
	GameManager.player_name = new_text
	name_input.virtual_keyboard_enabled = false
	DisplayServer.virtual_keyboard_hide()
	GameManager.send_stats(http_request)
	_on_close_pressed()

func _on_close_pressed() -> void:
	name_input.virtual_keyboard_enabled = false
	popup_panel.popup_hide

func _on_fill_text_pressed() -> void:
	name_input.grab_focus()
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			_on_text_submitted(name_input.text)  # Submit on Enter
		elif event.keycode == KEY_ESCAPE:  # Android back button
			DisplayServer.virtual_keyboard_hide()
			name_input.virtual_keyboard_enabled = false
			popup_panel.hide()
