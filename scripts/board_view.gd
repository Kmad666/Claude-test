class_name BoardView
extends Control
## Draws the looping board path, its spaces, the Crown Shrine, and the center dice display.

signal layout_changed

var positions := PackedVector2Array()
var center_text := ""
var center_sub := ""


func _ready() -> void:
	resized.connect(_layout)
	_layout()


func space_pos(i: int) -> Vector2:
	if positions.is_empty():
		return size / 2.0
	return positions[i % positions.size()]


func set_center(text: String, sub: String = "") -> void:
	center_text = text
	center_sub = sub
	queue_redraw()


static func space_color(kind: String) -> Color:
	match kind:
		"coin":
			return Color(0.25, 0.52, 0.97)
		"hazard":
			return Color(0.93, 0.27, 0.27)
		"event":
			return Color(0.66, 0.34, 0.95)
		"battle":
			return Color(0.98, 0.50, 0.12)
		_:
			return Color(0.15, 0.75, 0.40)


static func space_glyph(kind: String) -> String:
	match kind:
		"coin":
			return "+"
		"hazard":
			return "-"
		"event":
			return "?"
		"battle":
			return "!"
		_:
			return "GO"


func _layout() -> void:
	positions.clear()
	var inset := 46.0
	var rect := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	var perimeter := 2.0 * (rect.size.x + rect.size.y)
	for i in Game.BOARD_SIZE:
		var d := perimeter * i / float(Game.BOARD_SIZE)
		var p: Vector2
		if d < rect.size.x:
			p = rect.position + Vector2(d, 0)
		elif d < rect.size.x + rect.size.y:
			p = rect.position + Vector2(rect.size.x, d - rect.size.x)
		elif d < 2.0 * rect.size.x + rect.size.y:
			p = rect.position + Vector2(rect.size.x - (d - rect.size.x - rect.size.y), rect.size.y)
		else:
			p = rect.position + Vector2(0, rect.size.y - (d - 2.0 * rect.size.x - rect.size.y))
		positions.append(p)
	queue_redraw()
	layout_changed.emit()


func _draw() -> void:
	if positions.is_empty():
		return
	var font := ThemeDB.fallback_font
	# Grass field and road.
	draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color(0.55, 0.82, 0.42))
	draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), UI.INK, false, 4.0)
	var loop := positions.duplicate()
	loop.append(positions[0])
	draw_polyline(loop, Color(0.96, 0.87, 0.62), 44.0, true)

	for i in positions.size():
		var kind: String = Game.spaces[i]
		var c := positions[i]
		draw_circle(c + Vector2(0, 4), 27, Color(0, 0, 0, 0.18))
		draw_circle(c, 27, space_color(kind))
		draw_arc(c, 27, 0, TAU, 32, UI.INK, 4.0, true)
		var glyph := space_glyph(kind)
		var fs := 22 if glyph == "GO" else 34
		draw_string(font, c + Vector2(-27, fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_CENTER, 54, fs, Color.WHITE)

	if Game.is_hunt():
		for boss in Game.bosses:
			_draw_boss(boss, font)
	else:
		# Crown Shrine, nudged toward the middle of the board.
		var shrine := positions[Game.shrine_index]
		var inward := (size / 2.0 - shrine).normalized() * 58.0
		Shapes.draw(self, "star", shrine + inward, 26, UI.GOLD, UI.INK, 4.0)

	# Center: dice result or round banner.
	var mid := size / 2.0
	if center_text != "":
		var at := Vector2(0, mid.y + 40)
		draw_string_outline(font, at, center_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 120, 18, UI.INK)
		draw_string(font, at, center_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 120, UI.PAPER)
	if center_sub != "":
		var at_sub := Vector2(0, mid.y + 100)
		draw_string_outline(font, at_sub, center_sub, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, 8, UI.PAPER)
		draw_string(font, at_sub, center_sub, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, UI.INK)


## A mini-boss sits just inside the ring next to its space, with a name and HP bar.
func _draw_boss(boss: Dictionary, font: Font) -> void:
	var spot := positions[int(boss["pos"]) % positions.size()]
	var c := spot + (size / 2.0 - spot).normalized() * 74.0
	draw_line(spot, c, UI.INK, 4.0, true)
	draw_circle(c + Vector2(0, 6), 38, Color(0, 0, 0, 0.2))
	Shapes.draw(self, boss["shape"], c, 36, boss["color"], UI.INK, 5.0, true)
	var w := 84.0
	var ratio := clampf(float(boss["hp"]) / maxf(1.0, float(boss["max"])), 0.0, 1.0)
	var bar := Rect2(c + Vector2(-w / 2.0, -58), Vector2(w, 12))
	draw_rect(bar, Color(0.85, 0.85, 0.88))
	draw_rect(Rect2(bar.position, Vector2(w * ratio, 12)), Color(0.92, 0.25, 0.25))
	draw_rect(bar, UI.INK, false, 2.0)
	var at := c + Vector2(-70, -66)
	draw_string_outline(font, at, boss["name"], HORIZONTAL_ALIGNMENT_CENTER, 140, 20, 6, UI.PAPER)
	draw_string(font, at, boss["name"], HORIZONTAL_ALIGNMENT_CENTER, 140, 20, UI.INK)
