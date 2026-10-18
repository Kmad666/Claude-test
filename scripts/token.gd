class_name Token
extends Node2D
## A player's game piece on the board.

var kind := "circle"
var color := Color.WHITE


func _init(shape_kind: String, fill: Color) -> void:
	kind = shape_kind
	color = fill


func _draw() -> void:
	draw_circle(Vector2(0, 4), 26, Color(0, 0, 0, 0.18))
	draw_circle(Vector2.ZERO, 26, Color.WHITE)
	Shapes.draw(self, kind, Vector2.ZERO, 20, color, UI.INK, 3.0, true)
