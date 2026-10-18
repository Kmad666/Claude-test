class_name ResultsScreen
extends Control
## Final standings and a play-again button.

signal play_again

const PLACES: Array[String] = ["1st", "2nd", "3rd", "4th"]


func _ready() -> void:
	UI.full_rect(self)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	var wrap := UI.margin(col, 28)
	UI.full_rect(wrap)
	add_child(wrap)

	var ranked := Game.standings()
	var winner := ranked[0]
	var headline := "You win!" if winner["human"] else "%s wins!" % winner["name"]
	col.add_child(UI.label("Final Standings", 54, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UI.label(headline, 40, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))

	for i in ranked.size():
		var p := ranked[i]
		var data := Game.class_data(p)
		var panel := UI.panel(Color(1.0, 0.95, 0.75) if i == 0 else UI.PAPER)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		panel.add_child(row)
		row.add_child(UI.label(PLACES[i], 36))
		row.add_child(ShapeIcon.new(data["shape"], data["color"], 90))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UI.label(p["name"], 32))
		info.add_child(UI.label("%d Crowns   %d Coins" % [p["crowns"], p["coins"]], 26, UI.INK.lightened(0.25)))
		col.add_child(panel)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var again := UI.button("Play Again", UI.ACTION, 36)
	again.pressed.connect(func() -> void: play_again.emit())
	col.add_child(again)

	if Game.autoplay:
		for i in ranked.size():
			var p := ranked[i]
			print("%s %s (%s): %d crowns, %d coins" % [PLACES[i], p["name"], p["cls"], p["crowns"], p["coins"]])
		print("AUTOPLAY_DONE")
		get_tree().quit(0)
