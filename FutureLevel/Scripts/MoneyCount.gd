extends Panel





func _process(delta: float) -> void:
	%Money.text = "$ %d" % GameManager.game_cash
