class_name MinigameScreen
extends Control
## End-of-round minigames. The human plays by tapping; bots get simulated scores.

signal finished

const KINDS: Array[String] = ["targets", "timing", "quickdraw"]
const PRIZES: Array[int] = [8, 5, 3, 1]
const PLACES: Array[String] = ["1st", "2nd", "3rd", "4th"]
const TARGET_TIME := 10.0

const INFO := {
	"targets": ["Target Tap", "Tap the targets before they vanish! 10 seconds."],
	"timing": ["Timing Bar", "Tap to stop the marker in the gold zone. 3 tries, faster each time."],
	"quickdraw": ["Quick Draw", "Wait for TAP!, then tap as fast as you can. Too early scores zero. 3 rounds."],
}

var kind := "targets"
var auto := false
var scores := {}

var area: Control
var title: Label
var info: Label
var status: Label
var actions: HBoxContainer

var state := "intro"
var tap_flag := false
var elapsed := 0.0
var hits := 0
var targets: Array[Dictionary] = []
var pops: Array[Dictionary] = []
var marker := 0.0
var draw_phase := "wait"

signal _button_pressed


func setup(minigame: String) -> void:
	kind = minigame
	auto = Game.autoplay


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.99, 0.93, 0.78)
	UI.full_rect(bg)
	add_child(bg)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	var wrap := UI.margin(col, 22)
	UI.full_rect(wrap)
	add_child(wrap)

	col.add_child(UI.label("MINIGAME!", 30, UI.ACTION.darkened(0.2), HORIZONTAL_ALIGNMENT_CENTER))
	title = UI.label(INFO[kind][0], 52, UI.INK, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(title)
	info = UI.label(INFO[kind][1], 26, UI.INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	col.add_child(info)
	status = UI.label("", 34, UI.INK, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(status)

	area = Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 560)
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	area.clip_contents = true
	area.draw.connect(_draw_area)
	area.gui_input.connect(_on_area_input)
	col.add_child(area)

	actions = HBoxContainer.new()
	actions.custom_minimum_size = Vector2(0, 92)
	col.add_child(actions)
	_run()


func _run() -> void:
	await get_tree().process_frame
	if Game.autoplay:
		_check_layout()
	if auto:
		await _pause(1.0)
	else:
		await _button("Start!")
	for n in ["3", "2", "1"]:
		status.text = n
		await _pause(0.5)
	status.text = "GO!"

	var human_score := 0
	match kind:
		"targets":
			human_score = await _play_targets()
		"timing":
			human_score = await _play_timing()
		"quickdraw":
			human_score = await _play_quickdraw()
	state = "done"
	area.queue_redraw()

	for p in Game.players:
		scores[p["name"]] = human_score if p["human"] else _bot_score()
	var ranked: Array[Dictionary] = Game.players.duplicate()
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return scores[a["name"]] > scores[b["name"]])
	var lines: Array[String] = []
	for i in ranked.size():
		var p := ranked[i]
		var prize: int = PRIZES[mini(i, PRIZES.size() - 1)]
		Game.add_coins(p, prize)
		lines.append("%s  %s: %d pts  +%d coins" % [PLACES[i], p["name"], scores[p["name"]], prize])
	title.text = "Results"
	status.text = ""
	info.text = "\n".join(lines)
	if auto:
		await _pause(1.5)
	else:
		await _button("Continue")
	finished.emit()


# ---------------------------------------------------------------- target tap

func _play_targets() -> int:
	state = "targets"
	elapsed = 0.0
	hits = 0
	var next_spawn := 0.0
	while elapsed < TARGET_TIME:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		elapsed += dt
		if elapsed >= next_spawn:
			next_spawn += 0.6
			_spawn_target()
		for t in targets.duplicate():
			var age: float = elapsed - float(t["born"])
			if auto and age >= float(t["auto_at"]):
				_hit(t)
			elif age > float(t["life"]):
				targets.erase(t)
		for pop in pops.duplicate():
			if elapsed - float(pop["born"]) > 0.3:
				pops.erase(pop)
		status.text = "Hits: %d    Time: %.1f" % [hits, maxf(0.0, TARGET_TIME - elapsed)]
		area.queue_redraw()
	targets.clear()
	return hits


func _spawn_target() -> void:
	var r := 52.0
	var sz := area.size
	var pos := Vector2(Game.rng.randf_range(r, maxf(r, sz.x - r)), Game.rng.randf_range(r, maxf(r, sz.y - r)))
	var shapes: Array[String] = ["circle", "star", "diamond", "hexagon"]
	targets.append({
		"pos": pos, "born": elapsed, "life": Game.rng.randf_range(0.9, 1.3),
		"shape": shapes[Game.rng.randi_range(0, shapes.size() - 1)],
		"color": Color.from_hsv(Game.rng.randf(), 0.65, 1.0),
		"auto_at": Game.rng.randf_range(0.3, 0.7) if Game.rng.randf() < 0.75 else 99.0,
	})


func _hit(t: Dictionary) -> void:
	targets.erase(t)
	hits += 1
	pops.append({"pos": t["pos"], "born": elapsed})


# ---------------------------------------------------------------- timing bar

func _play_timing() -> int:
	state = "timing"
	var total := 0
	for attempt in 3:
		var speed := 1.0 + attempt * 0.45
		var t := 0.0
		tap_flag = false
		var auto_at := Game.rng.randf_range(0.6, 2.4)
		while not tap_flag and t < 6.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			marker = sin(t * speed * PI)
			if auto and t >= auto_at:
				tap_flag = true
			area.queue_redraw()
		var points := int(round((1.0 - absf(marker)) * 100.0)) if tap_flag else 0
		total += points
		status.text = "Try %d: %d points!" % [attempt + 1, points]
		await _pause(0.9)
	return total


# ---------------------------------------------------------------- quick draw

func _play_quickdraw() -> int:
	state = "quickdraw"
	var total := 0
	for round_i in 3:
		tap_flag = false
		draw_phase = "wait"
		status.text = "Wait for it..."
		area.queue_redraw()
		var wait := Game.rng.randf_range(1.2, 3.0)
		var t := 0.0
		var early := false
		while t < wait:
			await get_tree().process_frame
			t += get_process_delta_time()
			if tap_flag:
				early = true
				break
		var points := 0
		if early:
			draw_phase = "early"
			status.text = "Too early!"
		else:
			draw_phase = "go"
			status.text = "TAP!"
			area.queue_redraw()
			tap_flag = false
			var rt := 0.0
			var auto_at := Game.rng.randf_range(0.22, 0.45)
			while not tap_flag and rt < 1.5:
				await get_tree().process_frame
				rt += get_process_delta_time()
				if auto and rt >= auto_at:
					tap_flag = true
			if tap_flag:
				var ms := int(rt * 1000.0)
				points = maxi(0, 1000 - ms)
				status.text = "%d ms!" % ms
			else:
				status.text = "Too slow!"
			draw_phase = "done"
		area.queue_redraw()
		total += points
		await _pause(1.0)
	return total


# ---------------------------------------------------------------- shared

func _bot_score() -> int:
	match kind:
		"targets":
			return Game.rng.randi_range(6, 13)
		"timing":
			return Game.rng.randi_range(40, 95) + Game.rng.randi_range(35, 90) + Game.rng.randi_range(30, 85)
		_:
			var total := 0
			for _i in 3:
				if Game.rng.randf() > 0.1:
					total += 1000 - Game.rng.randi_range(260, 520)
			return total


func _on_area_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT or auto:
		return
	match state:
		"targets":
			for i in range(targets.size() - 1, -1, -1):
				var t := targets[i]
				if click.position.distance_to(t["pos"]) <= 60.0:
					_hit(t)
					break
		"timing", "quickdraw":
			tap_flag = true


func _draw_area() -> void:
	var sz := area.size
	area.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.62, 0.86, 0.97))
	area.draw_rect(Rect2(Vector2.ZERO, sz), UI.INK, false, 4.0)
	var font := ThemeDB.fallback_font
	match state:
		"targets":
			for t in targets:
				var age: float = elapsed - float(t["born"])
				var left := clampf(1.0 - age / float(t["life"]), 0.0, 1.0)
				Shapes.draw(area, t["shape"], t["pos"], 46, t["color"], UI.INK, 4.0, true)
				area.draw_arc(t["pos"], 56, -PI / 2, -PI / 2 + TAU * left, 32, UI.INK, 5.0, true)
			for pop in pops:
				var k := (elapsed - float(pop["born"])) / 0.3
				area.draw_arc(pop["pos"], 46 + k * 40.0, 0, TAU, 32, Color(1, 1, 1, 1.0 - k), 6.0, true)
		"timing":
			var bar := Rect2(Vector2(30, sz.y / 2 - 40), Vector2(sz.x - 60, 80))
			area.draw_rect(bar, UI.PAPER)
			var zone_w := bar.size.x * 0.12
			area.draw_rect(Rect2(Vector2(bar.get_center().x - zone_w / 2, bar.position.y), Vector2(zone_w, 80)), UI.GOLD)
			area.draw_rect(bar, UI.INK, false, 4.0)
			var x := bar.get_center().x + marker * bar.size.x / 2.0
			area.draw_line(Vector2(x, bar.position.y - 24), Vector2(x, bar.end.y + 24), UI.ACTION, 10.0)
		"quickdraw":
			var c := sz / 2.0
			var colors := {"wait": Color(0.93, 0.27, 0.27), "go": Color(0.20, 0.78, 0.40), "early": Color(0.6, 0.6, 0.65), "done": Color(0.25, 0.52, 0.97)}
			var words := {"wait": "WAIT", "go": "TAP!", "early": "OOPS", "done": "NICE"}
			area.draw_circle(c, minf(sz.x, sz.y) * 0.36, colors[draw_phase])
			area.draw_arc(c, minf(sz.x, sz.y) * 0.36, 0, TAU, 48, UI.INK, 6.0, true)
			var word: String = words[draw_phase]
			area.draw_string_outline(font, c + Vector2(-sz.x / 2, 34), word, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 96, 16, UI.INK)
			area.draw_string(font, c + Vector2(-sz.x / 2, 34), word, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 96, UI.PAPER)


func _button(text: String) -> void:
	var b := UI.button(text, UI.ACTION, 34)
	b.pressed.connect(func() -> void: _button_pressed.emit())
	actions.add_child(b)
	await _button_pressed
	b.queue_free()


func _pause(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check_layout() -> void:
	if actions.get_global_rect().end.y > get_viewport_rect().end.y + 1.0:
		printerr("LAYOUT ERROR: minigame buttons are off screen")
	if area.size.y < 300.0:
		printerr("LAYOUT ERROR: minigame play area squashed: ", area.size)
