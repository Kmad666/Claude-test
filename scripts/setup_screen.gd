class_name SetupScreen
extends Control
## Title screen: pick your hero class.

signal class_chosen(cls: String)

var mode_buttons := {}
var mode_hint: Label
var col: VBoxContainer


func _ready() -> void:
	UI.full_rect(self)
	col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	var wrap := UI.margin(col, 28)
	UI.full_rect(wrap)
	add_child(wrap)

	col.add_child(UI.label("Wildwood Party", 62, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 14)
	col.add_child(modes)
	for m in [Game.MODE_CROWNS, Game.MODE_HUNT]:
		var b := UI.button(Game.MODE_NAMES[m], UI.BLUE, 28)
		b.pressed.connect(_set_mode.bind(m))
		modes.add_child(b)
		mode_buttons[m] = b
	mode_hint = UI.label("", 24, UI.INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	col.add_child(mode_hint)
	_set_mode(Game.mode)

	col.add_child(UI.label("Choose your hero", 32, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	for cls in Data.CLASS_ORDER:
		col.add_child(_card(cls))


func _card(cls: String) -> Button:
	var data: Dictionary = Data.CLASSES[cls]
	var tint: Color = data["color"]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 168)
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

	row.add_child(ShapeIcon.new(data["shape"], tint, 132))
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


func _set_mode(m: String) -> void:
	Game.mode = m
	for key in mode_buttons:
		var b: Button = mode_buttons[key]
		var on: bool = key == m
		var color := UI.ACTION if on else Color(0.62, 0.70, 0.82)
		b.add_theme_stylebox_override("normal", UI.box(color, 22, 6 if on else 3))
		b.add_theme_stylebox_override("hover", UI.box(color.lightened(0.1), 22, 6 if on else 3))
	if m == Game.MODE_HUNT:
		mode_hint.text = "Team up against roaming mini-bosses. The final blow earns a Trophy."
	else:
		mode_hint.text = "Race around the board and buy Crowns near the moving shrine."


## Self-test: every hero card must be fully on screen.
func check_layout() -> void:
	var last := col.get_child(col.get_child_count() - 1) as Control
	if last.get_global_rect().end.y > get_viewport_rect().end.y + 1.0:
		printerr("LAYOUT ERROR: setup screen runs off the bottom (", last.get_global_rect(), ")")
