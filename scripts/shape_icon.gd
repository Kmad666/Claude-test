class_name ShapeIcon
extends Control
## A Control that draws one placeholder shape, for use inside UI layouts.

var kind := "circle"
var color := Color.WHITE
var face := true


func _init(shape_kind: String = "circle", fill: Color = Color.WHITE, min_size: float = 64.0, has_face: bool = true) -> void:
	kind = shape_kind
	color = fill
	face = has_face
	custom_minimum_size = Vector2(min_size, min_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.42
	Shapes.draw(self, kind, size / 2.0, r, color, UI.INK, maxf(3.0, r * 0.07), face)
