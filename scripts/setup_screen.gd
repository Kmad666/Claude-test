class_name SetupScreen
extends Control
## Title screen: pick your hero class.

signal class_chosen(cls: String)


func _ready() -> void:
	UI.full_rect(self)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	var wrap := UI.margin(col, 28)
	UI.full_rect(wrap)
	add_child(wrap)

	col.add_child(UI.label("Wildwood Party", 66, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UI.label("Choose your hero", 32, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	for cls in Data.CLASS_ORDER:
		col.add_child(_card(cls))


func _card(cls: String) -> Button:
	var data: Dictionary = Data.CLASSES[cls]
	var tint: Color = data["color"]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 190)
	b.add_theme_stylebox_override("normal", UI.box(UI.PAPER, 26, 4))
	b.add_theme_stylebox_override("hover", UI.box(UI.PAPER.darkened(0.04), 26, 4))
	b.add_theme_stylebox_override("pressed", UI.box(tint.lightened(0.55), 26, 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var row := HBoxContainer.new()
	UI.full_rect(row)
	row.offset_left = 18
	row.offset_right = -18
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	row.add_child(ShapeIcon.new(data["shape"], tint, 150))
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	info.add_child(UI.label(cls, 42))
	info.add_child(UI.label(data["blurb"], 26, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
	var stats: Dictionary = data["stats"]
	var line := "HP %d   STR %d  DEX %d  INT %d  WIS %d" % [
		data["hp"], stats["STR"], stats["DEX"], stats["INT"], stats["WIS"]
	]
	info.add_child(UI.label(line, 22, UI.INK.lightened(0.35)))

	b.pressed.connect(func() -> void: class_chosen.emit(cls))
	return b
