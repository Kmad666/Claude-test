class_name BoardScreen
extends Control
## The party board: turn order, dice, movement, spaces, the Crown Shrine, and the round loop.

signal game_over
signal _chosen(idx: int)

const TOKEN_OFFSETS: Array[Vector2] = [Vector2(-15, -15), Vector2(15, -15), Vector2(-15, 15), Vector2(15, 15)]

var board: BoardView
var round_label: Label
var message: Label
var actions: HBoxContainer
var tokens: Array[Token] = []
var hud_panels: Array[PanelContainer] = []
var hud_stats: Array[Label] = []
var hud_names: Array[Label] = []
var current := 0


func _ready() -> void:
	UI.full_rect(self)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	var wrap := UI.margin(col, 18)
	UI.full_rect(wrap)
	add_child(wrap)

	round_label = UI.label("", 30, UI.INK, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(round_label)
	col.add_child(_build_hud())

	board = BoardView.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 520)
	col.add_child(board)

	var msg_panel := UI.panel()
	msg_panel.custom_minimum_size = Vector2(0, 170)
	message = UI.label("", 28, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_panel.add_child(message)
	col.add_child(msg_panel)

	actions = HBoxContainer.new()
	actions.custom_minimum_size = Vector2(0, 92)
	actions.add_theme_constant_override("separation", 14)
	col.add_child(actions)

	for i in Game.players.size():
		var p := Game.players[i]
		var data := Game.class_data(p)
		var t := Token.new(data["shape"], p["color"])
		board.add_child(t)
		tokens.append(t)
	board.layout_changed.connect(_place_tokens)

	_refresh_hud()
	_run()


# ---------------------------------------------------------------- game loop

func _run() -> void:
	await get_tree().process_frame
	_place_tokens()
	if Game.autoplay:
		_check_layout()
	await _intro()
	while Game.round_num <= Game.ROUNDS:
		_refresh_hud()
		board.set_center("", "Round %d" % Game.round_num)
		for i in Game.players.size():
			current = i
			_refresh_hud()
			await _take_turn(i)
		if Game.is_hunt():
			await _move_bosses()
		await _minigame()
		Game.round_num += 1
	board.set_center("", "")
	_say("The final round is over!")
	await _pause(1.2)
	game_over.emit()


func _take_turn(i: int) -> void:
	var p := Game.players[i]
	var auto := Game.is_auto(p)
	_say("%s's turn." % p["name"])
	var boots := false
	if auto:
		await _pause(0.7)
		boots = Game.use_item(p, "boots")
	else:
		var opts: Array[String] = ["Roll the die!"]
		if Game.item_count(p, "boots") > 0:
			opts.append("Swift Boots (2 dice)")
		var pick: int = await _choose(opts, [UI.ACTION, UI.SUPPORT])
		if pick == 1:
			boots = Game.use_item(p, "boots")

	var steps: int = await _roll_movement(p, boots)
	board.set_center(str(steps), "%s moves" % p["name"])
	var blocked := {}
	var shrine_done := false
	for _step in steps:
		p["pos"] = (int(p["pos"]) + 1) % Game.BOARD_SIZE
		await _hop(i)
		if Game.is_hunt():
			blocked = Game.boss_at(int(p["pos"]))
			if not blocked.is_empty():
				break
		elif not shrine_done and Game.near_shrine(int(p["pos"])):
			shrine_done = true
			await _visit_shrine(p)
	board.set_center("", "Round %d" % Game.round_num)
	if blocked.is_empty():
		await _resolve_space(p)
	else:
		_say("%s runs into the %s!" % [p["name"], blocked["name"]])
		await _pause(1.0)
		await _boss_battle(p, blocked)
	_refresh_hud()
	await _pause(0.9)


func _roll_movement(p: Dictionary, boots: bool) -> int:
	if boots:
		_say("%s laces up the Swift Boots!" % p["name"])
		var a: int = await _roll_die(6)
		var b: int = await _roll_die(6)
		board.set_center(str(a + b), "%d + %d" % [a, b])
		await _pause(0.6)
		return a + b
	var steps: int = await _roll_die(6)
	if steps <= 3 and int(p["coins"]) >= Game.REROLL_COST:
		var reroll := false
		if Game.is_auto(p):
			reroll = steps <= 2 and int(p["coins"]) >= 12
		else:
			_say("You rolled a %d. Pay %d coins to reroll?" % [steps, Game.REROLL_COST])
			var pick: int = await _choose(["Move %d" % steps, "Reroll (%d coins)" % Game.REROLL_COST], [UI.ACTION, UI.BLUE])
			reroll = pick == 1
		if reroll:
			Game.add_coins(p, -Game.REROLL_COST)
			_refresh_hud()
			_say("%s pays %d coins to reroll!" % [p["name"], Game.REROLL_COST])
			steps = await _roll_die(6)
	return steps


func _visit_shrine(p: Dictionary) -> void:
	if p["coins"] < Game.CROWN_COST:
		_say("%s passes the Crown Shrine but needs %d coins." % [p["name"], Game.CROWN_COST])
		await _pause(1.0)
		return
	var buy := true
	if Game.is_auto(p):
		_say("%s reaches the Crown Shrine!" % p["name"])
		await _pause(0.8)
	else:
		_say("The Crown Shrine! Buy a Crown for %d coins?" % Game.CROWN_COST)
		var pick: int = await _choose(["Buy Crown", "Not now"], [UI.GOLD.darkened(0.15), UI.BLUE])
		buy = pick == 0
	if buy:
		Game.add_coins(p, -Game.CROWN_COST)
		p["crowns"] = int(p["crowns"]) + 1
		Game.move_shrine()
		board.queue_redraw()
		_refresh_hud()
		_say("%s claims a Crown! The shrine vanishes to another spot." % p["name"])
		await _pause(1.3)


func _resolve_space(p: Dictionary) -> void:
	var kind: String = Game.spaces[int(p["pos"])]
	match kind:
		"coin", "start":
			Game.add_coins(p, 3)
			_say("%s finds 3 coins." % p["name"])
		"hazard":
			var lost := -Game.add_coins(p, -3)
			_say("Thorns! %s drops %d coins." % [p["name"], lost])
		"event":
			await _skill_check(p)
		"battle":
			await _battle(p)
		"shop":
			await _shop(p)
	_refresh_hud()


func _shop(p: Dictionary) -> void:
	if p["human"]:
		_say("A wandering merchant waves you over.")
		var screen := ShopScreen.new()
		screen.setup(p, Game.autoplay)
		add_child(screen)
		await screen.finished
		screen.queue_free()
		_say("You leave the shop.")
	else:
		var bought := Game.bot_shop(p, Game.shop_offers(p))
		if bought.is_empty():
			_say("%s browses the shop but buys nothing." % p["name"])
		else:
			_say("%s buys %s." % [p["name"], ", ".join(bought)])
	_refresh_hud()
	await _pause(1.0)


func _skill_check(p: Dictionary) -> void:
	var ev := Game.pick_event()
	var stat: String = ev["stat"]
	var bonus := Game.stat_bonus(p, stat)
	var dc: int = ev["dc"]
	_say("%s\n%s\n%s check: d20 + %d, need %d." % [ev["title"], ev["text"], stat, bonus, dc])
	if Game.is_auto(p):
		await _pause(1.4)
	else:
		await _choose(["Roll d20"], [UI.ACTION])
	var roll: int = await _roll_die(20)
	var total := roll + bonus
	board.set_center(str(total), "%d + %d %s" % [roll, bonus, stat])
	if roll != 20 and total < dc and int(p["coins"]) >= Game.REROLL_COST:
		var reroll := false
		if Game.is_auto(p):
			reroll = int(p["coins"]) >= 12 and total + 3 < dc
		elif total + 3 < dc or Game.item_count(p, "charm") == 0:
			_say("%d vs %d. Failed! Pay %d coins to reroll?" % [total, dc, Game.REROLL_COST])
			var pick: int = await _choose(["Accept", "Reroll (%d coins)" % Game.REROLL_COST], [UI.BLUE, UI.ACTION])
			reroll = pick == 1
		if reroll:
			Game.add_coins(p, -Game.REROLL_COST)
			_refresh_hud()
			roll = await _roll_die(20)
			total = roll + bonus
			board.set_center(str(total), "%d + %d %s" % [roll, bonus, stat])
	if roll != 20 and total < dc and total + 3 >= dc and Game.use_item(p, "charm"):
		total += 3
		board.set_center(str(total), "Lucky Charm +3!")
		_say("The Lucky Charm glows!")
		await _pause(1.0)
	if roll == 20:
		Game.add_coins(p, 10)
		_say("Natural 20! %s +10 coins." % ev["win"])
	elif total >= dc:
		Game.add_coins(p, 6)
		_say("Success! %s +6 coins." % ev["win"])
	else:
		var lost := -Game.add_coins(p, -3)
		_say("Failed. %s -%d coins." % [ev["lose"], lost])
	await _pause(1.6)
	board.set_center("", "Round %d" % Game.round_num)


func _battle(p: Dictionary) -> void:
	var foe := Game.pick_monster()
	_say("A wild %s blocks %s's path!" % [foe["name"], p["name"]])
	await _pause(1.0)
	var result: int
	if p["human"]:
		var screen := BattleScreen.new()
		screen.setup(p, foe, Game.autoplay)
		add_child(screen)
		result = await screen.finished
		screen.queue_free()
	else:
		result = Battle.new(p, foe, Game.rng).simulate()
	var reward := 5 + int(foe["tier"]) * 3
	var xp := 2
	match result:
		Battle.WIN:
			xp = 6 + int(foe["tier"]) * 3
			Game.add_coins(p, reward)
			_say("%s defeats the %s! +%d coins, +%d XP." % [p["name"], foe["name"], reward, xp])
		Battle.LOSE:
			var lost := -Game.add_coins(p, -4)
			_say("%s is knocked out by the %s. -%d coins, +%d XP." % [p["name"], foe["name"], lost, xp])
		_:
			xp = 3
			_say("The %s wanders off. +%d XP." % [foe["name"], xp])
	_refresh_hud()
	await _pause(1.2)
	await _award_xp(p, xp)


# ---------------------------------------------------------------- monster hunt

func _minigame() -> void:
	var kind: String = MinigameScreen.KINDS[Game.rng.randi_range(0, MinigameScreen.KINDS.size() - 1)]
	_say("Minigame time!")
	await _pause(0.8)
	var screen := MinigameScreen.new()
	screen.setup(kind)
	add_child(screen)
	await screen.finished
	screen.queue_free()
	_refresh_hud()


func _intro() -> void:
	if Game.is_hunt():
		_say("Monster Hunt! Mini-bosses roam the board. Run into one to fight it. Damage sticks, and the final blow earns a Trophy.")
	else:
		_say("Crown Collector! Pass within one space of the gold star with %d coins to buy a Crown. Most Crowns wins." % Game.CROWN_COST)
	await _pause(2.5)


func _move_bosses() -> void:
	_say("The monsters are on the move...")
	await _pause(0.8)
	for boss in Game.bosses.duplicate():
		var steps := Game.rng.randi_range(1, 3)
		for _step in steps:
			boss["pos"] = (int(boss["pos"]) + 1) % Game.BOARD_SIZE
			board.queue_redraw()
			await _pause(0.25)
		for i in Game.players.size():
			var p := Game.players[i]
			if p["pos"] == boss["pos"] and Game.bosses.has(boss):
				current = i
				_refresh_hud()
				_say("The %s ambushes %s!" % [boss["name"], p["name"]])
				await _pause(1.0)
				await _boss_battle(p, boss)


func _boss_battle(p: Dictionary, boss: Dictionary) -> void:
	var start_hp: int = boss["hp"]
	var fight: Battle
	if p["human"]:
		var screen := BattleScreen.new()
		screen.setup(p, boss, Game.autoplay)
		add_child(screen)
		await screen.finished
		fight = screen.battle
		screen.queue_free()
	else:
		fight = Battle.new(p, boss, Game.rng)
		fight.simulate()
	var dealt := start_hp - fight.mon_hp
	boss["hp"] = fight.mon_hp
	var bounty := dealt / 2
	Game.add_coins(p, bounty)
	if fight.mon_hp <= 0:
		p["trophies"] = int(p["trophies"]) + 1
		Game.add_coins(p, 10)
		var fresh := Game.respawn_boss(boss)
		board.queue_redraw()
		_refresh_hud()
		_say("%s slays the %s! A Trophy and %d coins! A %s appears elsewhere..." % [p["name"], boss["name"], bounty + 10, fresh["name"]])
	elif fight.hero_hp <= 0:
		var lost := -Game.add_coins(p, -4)
		_say("%s dealt %d damage (+%d coins) but was knocked out. -%d coins." % [p["name"], dealt, bounty, lost])
	else:
		_say("%s dealt %d damage (+%d coins). The %s has %d HP left." % [p["name"], dealt, bounty, boss["name"], boss["hp"]])
	board.queue_redraw()
	_refresh_hud()
	await _pause(1.6)
	await _award_xp(p, dealt / 2 + (10 if fight.mon_hp <= 0 else 2))


func _award_xp(p: Dictionary, amount: int) -> void:
	var gained := Game.add_xp(p, amount)
	_refresh_hud()
	if gained > 0:
		board.set_center("Lv %d" % p["level"], "LEVEL UP!")
		_say("%s reached Level %d! Max HP and attack power are up." % [p["name"], p["level"]])
		await _pause(1.6)
		board.set_center("", "Round %d" % Game.round_num)


# ---------------------------------------------------------------- helpers

## Self-test: the board and the action buttons must fit on screen.
func _check_layout() -> void:
	var screen := get_viewport_rect()
	if actions.get_global_rect().end.y > screen.end.y + 1.0:
		printerr("LAYOUT ERROR: action buttons are off screen (", actions.get_global_rect(), " vs ", screen, ")")
	if board.size.y < 300.0:
		printerr("LAYOUT ERROR: board is squashed to ", board.size)
	for panel in hud_panels:
		if panel.get_global_rect().end.x > screen.end.x + 1.0:
			printerr("LAYOUT ERROR: scoreboard runs off the right edge: ", panel.get_global_rect())
		if panel.size.y > 160.0:
			printerr("LAYOUT ERROR: scoreboard panel too tall: ", panel.size)

func _say(text: String) -> void:
	message.text = text


func _pause(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _choose(options: Array[String], colors: Array[Color]) -> int:
	for child in actions.get_children():
		child.queue_free()
	for i in options.size():
		var b := UI.button(options[i], colors[i] if i < colors.size() else UI.BLUE)
		b.pressed.connect(func() -> void: _chosen.emit(i))
		actions.add_child(b)
	var picked: int = await _chosen
	for child in actions.get_children():
		child.queue_free()
	return picked


func _roll_die(sides: int) -> int:
	var result := Game.rng.randi_range(1, sides)
	for k in 9:
		board.set_center(str(Game.rng.randi_range(1, sides)), "d%d" % sides)
		await _pause(0.06)
	board.set_center(str(result), "d%d" % sides)
	await _pause(0.5)
	return result


func _hop(i: int) -> void:
	var t := tokens[i]
	var target := _token_target(i)
	var mid := (t.position + target) / 2.0 + Vector2(0, -28)
	var tw := create_tween()
	tw.tween_property(t, "position", mid, 0.09)
	tw.tween_property(t, "position", target, 0.09)
	await tw.finished


func _token_target(i: int) -> Vector2:
	var p := Game.players[i]
	return board.space_pos(int(p["pos"])) + TOKEN_OFFSETS[i % TOKEN_OFFSETS.size()]


func _place_tokens() -> void:
	for i in tokens.size():
		tokens[i].position = _token_target(i)


func _build_hud() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for p in Game.players:
		var data := Game.class_data(p)
		var panel := UI.panel()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		row.add_child(ShapeIcon.new(data["shape"], p["color"], 64))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		row.add_child(info)
		var name_label := UI.label(p["name"], 24)
		info.add_child(name_label)
		hud_names.append(name_label)
		var stats := UI.label("", 22, UI.INK.lightened(0.25))
		info.add_child(stats)
		grid.add_child(panel)
		hud_panels.append(panel)
		hud_stats.append(stats)
	return grid


func _refresh_hud() -> void:
	round_label.text = "%s  |  Round %d / %d" % [Game.MODE_NAMES[Game.mode], mini(Game.round_num, Game.ROUNDS), Game.ROUNDS]
	for i in Game.players.size():
		var p := Game.players[i]
		hud_stats[i].text = "Coins %d   %s %d" % [p["coins"], Game.score_name(), Game.score(p)]
		hud_names[i].text = "%s  Lv%d" % [p["name"], p["level"]]
		var active := i == current
		var border_color := UI.GOLD.darkened(0.2) if active else UI.INK
		var bg := Color(1.0, 0.95, 0.75) if active else UI.PAPER
		hud_panels[i].add_theme_stylebox_override("panel", UI.box(bg, 22, 6 if active else 3, border_color))
		tokens[i].z_index = 2 if active else 1
		tokens[i].scale = Vector2.ONE * (1.2 if active else 1.0)
