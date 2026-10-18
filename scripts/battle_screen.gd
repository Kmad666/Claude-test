class_name BattleScreen
extends Control
## Pokemon-style battle overlay: foe up top, hero below, a message box, and four move buttons.

signal finished(result: int)
signal _move_picked(idx: int)

var battle: Battle
var auto := false

var arena: Control
var hero_icon: ShapeIcon
var foe_icon: ShapeIcon
var hero_info: PanelContainer
var foe_info: PanelContainer
var hero_bar: ProgressBar
var foe_bar: ProgressBar
var hero_hp_label: Label
var foe_hp_label: Label
var log_label: Label
var moves_grid: GridContainer
var last_hero_hp := 0
var last_foe_hp := 0


## Call before adding to the tree.
func setup(player: Dictionary, foe: Dictionary, is_auto: bool) -> void:
	battle = Battle.new(player, foe, Game.rng)
	auto = is_auto
	last_hero_hp = battle.hero_hp
	last_foe_hp = battle.mon_hp


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	var wrap := UI.margin(col, 20)
	UI.full_rect(wrap)
	add_child(wrap)

	arena = Control.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.custom_minimum_size = Vector2(0, 560)
	arena.resized.connect(_layout_arena)
	col.add_child(arena)

	var foe_data := battle.monster
	foe_icon = ShapeIcon.new(foe_data["shape"], foe_data["color"], 230)
	arena.add_child(foe_icon)
	var hero_data: Dictionary = Data.CLASSES[_hero_class()]
	hero_icon = ShapeIcon.new(hero_data["shape"], hero_data["color"], 250)
	arena.add_child(hero_icon)

	foe_info = _info_panel(battle.mon_name)
	foe_bar = foe_info.get_meta("bar")
	foe_hp_label = foe_info.get_meta("hp")
	arena.add_child(foe_info)
	hero_info = _info_panel(battle.hero_name)
	hero_bar = hero_info.get_meta("bar")
	hero_hp_label = hero_info.get_meta("hp")
	arena.add_child(hero_info)

	var log_panel := UI.panel()
	log_panel.custom_minimum_size = Vector2(0, 150)
	log_label = UI.label("", 30)
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	log_panel.add_child(log_label)
	col.add_child(log_panel)

	moves_grid = GridContainer.new()
	moves_grid.columns = 2
	moves_grid.custom_minimum_size = Vector2(0, 236)
	moves_grid.add_theme_constant_override("h_separation", 12)
	moves_grid.add_theme_constant_override("v_separation", 12)
	col.add_child(moves_grid)

	_update_bars(false)
	_run()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.99, 0.94, 0.82))
	if arena == null:
		return
	var origin := arena.position + Vector2(20, 20)
	var a := arena.size
	draw_rect(Rect2(origin, Vector2(a.x, a.y * 0.5)), Color(0.62, 0.86, 0.97))
	draw_rect(Rect2(origin + Vector2(0, a.y * 0.5), Vector2(a.x, a.y * 0.5)), Color(0.60, 0.85, 0.45))
	_platform(origin + Vector2(a.x * 0.72, a.y * 0.40), a.x * 0.26)
	_platform(origin + Vector2(a.x * 0.26, a.y * 0.90), a.x * 0.30)


func _platform(c: Vector2, rx: float) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var ang := TAU * i / 32.0
		pts.append(c + Vector2(cos(ang) * rx, sin(ang) * rx * 0.28))
	draw_colored_polygon(pts, Color(0.45, 0.68, 0.32))


func _layout_arena() -> void:
	if foe_icon == null or hero_icon == null or foe_info == null or hero_info == null:
		return
	var a := arena.size
	foe_icon.size = foe_icon.custom_minimum_size
	foe_icon.position = Vector2(a.x * 0.72, a.y * 0.33) - foe_icon.size / 2.0
	hero_icon.size = hero_icon.custom_minimum_size
	hero_icon.position = Vector2(a.x * 0.26, a.y * 0.78) - hero_icon.size / 2.0
	foe_info.position = Vector2(0, 10)
	foe_info.size = Vector2(a.x * 0.52, 0)
	hero_info.size = Vector2(a.x * 0.52, 0)
	hero_info.position = Vector2(a.x * 0.48, a.y * 0.58)
	queue_redraw()


func _run() -> void:
	await get_tree().process_frame
	_layout_arena()
	await _say(["A wild %s appears!" % battle.mon_name])
	while not battle.is_over():
		var idx: int
		if auto:
			await _pause(0.4)
			idx = battle.bot_pick()
		else:
			log_label.text = "What will %s do?" % battle.hero_name
			_show_moves()
			idx = await _move_picked
			_clear_moves()
		var lines := battle.use_move(idx)
		_update_bars(true)
		await _say(lines)
		if battle.is_over():
			break
		lines = battle.monster_turn()
		_update_bars(true)
		await _say(lines)

	var result := battle.result()
	match result:
		Battle.WIN:
			await _say(["The %s was defeated!" % battle.mon_name])
		Battle.LOSE:
			await _say(["%s fainted..." % battle.hero_name])
	if auto:
		await _pause(0.6)
	else:
		var b := UI.button("Continue", UI.BLUE)
		b.pressed.connect(func() -> void: _move_picked.emit(-1))
		moves_grid.columns = 1
		moves_grid.add_child(b)
		await _move_picked
	finished.emit(result)


func _show_moves() -> void:
	_clear_moves()
	moves_grid.columns = 2
	for i in battle.moves.size():
		var m := battle.moves[i]
		var color := UI.ACTION if m["kind"] == "attack" else UI.SUPPORT
		var b := UI.button("%s\n%s" % [m["name"], battle.describe(i)], color, 26)
		b.custom_minimum_size = Vector2(0, 112)
		b.disabled = not battle.can_use(i)
		b.pressed.connect(func() -> void: _move_picked.emit(i))
		moves_grid.add_child(b)


func _clear_moves() -> void:
	for child in moves_grid.get_children():
		child.queue_free()


func _say(lines: Array[String]) -> void:
	for line in lines:
		log_label.text = line
		await _pause(0.9)


func _pause(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _update_bars(animate: bool) -> void:
	hero_bar.max_value = battle.hero_max
	foe_bar.max_value = battle.mon_max
	hero_hp_label.text = "HP %d / %d" % [battle.hero_hp, battle.hero_max]
	foe_hp_label.text = "HP %d / %d" % [battle.mon_hp, battle.mon_max]
	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(hero_bar, "value", float(battle.hero_hp), 0.35)
		tw.tween_property(foe_bar, "value", float(battle.mon_hp), 0.35)
		tw.finished.connect(func() -> void:
			UI.set_bar_color(hero_bar)
			UI.set_bar_color(foe_bar)
		)
		if battle.mon_hp < last_foe_hp:
			_shake(foe_icon)
		if battle.hero_hp < last_hero_hp:
			_shake(hero_icon)
	else:
		hero_bar.value = battle.hero_hp
		foe_bar.value = battle.mon_hp
	last_hero_hp = battle.hero_hp
	last_foe_hp = battle.mon_hp


func _shake(icon: Control) -> void:
	var base := icon.position
	var tw := create_tween()
	tw.tween_property(icon, "modulate", Color(1, 0.45, 0.45), 0.06)
	for _k in 3:
		tw.tween_property(icon, "position", base + Vector2(14, 0), 0.04)
		tw.tween_property(icon, "position", base - Vector2(14, 0), 0.04)
	tw.tween_property(icon, "position", base, 0.04)
	tw.tween_property(icon, "modulate", Color.WHITE, 0.1)


func _info_panel(title: String) -> PanelContainer:
	var panel := UI.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(UI.label(title, 30))
	var bar := UI.hp_bar()
	box.add_child(bar)
	var hp := UI.label("", 22, UI.INK.lightened(0.25))
	box.add_child(hp)
	panel.set_meta("bar", bar)
	panel.set_meta("hp", hp)
	return panel


func _hero_class() -> String:
	for p in Game.players:
		if p["name"] == battle.hero_name:
			return p["cls"]
	return "Warrior"
