extends Node2D
## Starter scene: a bouncing ball. Tap anywhere to send it there and change its color.

const RADIUS := 48.0
const SPEED := 420.0

var ball_pos := Vector2(360, 640)
var velocity := Vector2(260, -340)
var ball_color := Color(1.0, 0.55, 0.2)
var taps := 0

var label := Label.new()


func _ready() -> void:
	label.position = Vector2(24, 24)
	label.add_theme_font_size_override("font_size", 36)
	add_child(label)
	_update_label()


func _process(delta: float) -> void:
	var area := get_viewport_rect().size
	ball_pos += velocity * delta
	if ball_pos.x < RADIUS or ball_pos.x > area.x - RADIUS:
		velocity.x = -velocity.x
		ball_pos.x = clampf(ball_pos.x, RADIUS, area.x - RADIUS)
	if ball_pos.y < RADIUS or ball_pos.y > area.y - RADIUS:
		velocity.y = -velocity.y
		ball_pos.y = clampf(ball_pos.y, RADIUS, area.y - RADIUS)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Touches arrive as mouse clicks (Godot emulates mouse from touch by default).
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var target := click.position
		velocity = (target - ball_pos).normalized() * SPEED
		ball_color = Color.from_hsv(randf(), 0.7, 1.0)
		taps += 1
		_update_label()


func _draw() -> void:
	draw_rect(get_viewport_rect(), Color(0.08, 0.09, 0.14))
	draw_circle(ball_pos, RADIUS, ball_color)


func _update_label() -> void:
	label.text = "Hello, Boss!\nTaps: %d" % taps
