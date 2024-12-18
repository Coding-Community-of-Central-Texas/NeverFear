extends Panel





func _process(_delta: float) -> void:
	%Money.text = "$ %06d" % GameManager.game_cash
