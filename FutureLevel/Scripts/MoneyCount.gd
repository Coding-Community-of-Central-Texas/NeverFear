extends Panel


@onready var money_count: Label = $MoneyCount




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$MoneyCount.text = "$ %6d" % GameManager.game_cash
