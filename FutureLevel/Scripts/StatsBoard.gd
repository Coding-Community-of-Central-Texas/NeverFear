extends LineEdit

@onready var name_input = %SendName  # LineEdit node for entering name
@onready var popup_panel: PopupPanel = $".."
@onready var http_request: HTTPRequest = $"../../../HTTPRequest"
@onready var upload: Sprite2D = $"../Upload"


var adjectives = ["Quantum", "Synthetic", "Digital", "Neural", "Cybernetic", "Augmented", "Hyper", "Meta", "Virtual", "Holo", "Infra", "Autonomous", "Biometric", "Hacked", "Encrypted", "Glitched", "Optimized", "Parallel", "Void"]
var nouns = ["Protocol", "Cipher", "Grid", "Matrix", "Bot", "AI", "Code", "Drone", "Mainframe", "Algorithm", "Module", "Nexus", "Gateway", "Proxy", "Patch", "Core", "Kernel", "Terminal", "Synth", "Chip", "Datastream", "Firewall", "Echo", "Pulse", "Node", "Fragment", "Avatar", "Uplink", "Archive", "Command"]
var proper_nouns = ["Zephyr", "Nyx", "Orion", "Vex", "Echelon", "Aegis", "Solace", "Vector", "Oblivion", "Phobos", "Zer0", "Xypher", "Omicron", "Apollo", "Nebula", "Zypherion", "Seraphim", "Cronus", "Sypher", "Hyperion"]
var titles = ["Operative", "Sentinel", "Architect", "Overseer", "Technomancer", "Recon", "CipherMaster", "DataRunner", "NetGhost", "SynthLord", "Neural Engineer", "Quantum Analyst", "CyberSmith", "GridWalker", "Augmenter", "Protocol Enforcer", "Bytecaster", "Firewall Engineer", "Echo Specialist", "Mainframe Operator"]

func _on_randimize_pressed() -> void:
	var random_choice = randi() % 3  # Pick between 3 naming styles

	if random_choice == 0:
		# Adjective + Noun (e.g., "Quantum Cipher")
		var random_adjective = adjectives[randi() % adjectives.size()]
		var random_noun = nouns[randi() % nouns.size()]
		name_input.text = random_adjective + " " + random_noun

	elif random_choice == 1:
		# Proper Noun + Title (e.g., "Zephyr Sentinel")
		var random_proper_noun = proper_nouns[randi() % proper_nouns.size()]
		var random_title = titles[randi() % titles.size()]
		name_input.text = random_proper_noun + " " + random_title

	else:
		# Adjective + Proper Noun (e.g., "Glitched Orion")
		var random_adjective = adjectives[randi() % adjectives.size()]
		var random_proper_noun = proper_nouns[randi() % proper_nouns.size()]
		name_input.text = random_adjective + " " + random_proper_noun

func _on_upload_button_pressed() -> void:
	GameManager.player_name = name_input.text  # Set global player name
	GameManager.send_stats(http_request)  # Send stats
	%AudioStreamPlayer2D.play()
	upload.modulate = Color(0.5, 0.5, 0)  # Set to red
	await get_tree().create_timer(0.5).timeout  # Wait for 0.5 seconds
	upload.modulate = Color(1, 1, 1)

func _on_close_pressed() -> void:
	popup_panel.visible = false
