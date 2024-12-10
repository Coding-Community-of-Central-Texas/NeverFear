extends Panel





func _process(_delta: float) -> void:
	%Money.text = "$ %d" % GameManager.game_cash
