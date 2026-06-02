extends Panel





func _process(_delta: float) -> void:
	%Money.text = " %s" % GameManager.format_cash(GameManager.game_cash)
