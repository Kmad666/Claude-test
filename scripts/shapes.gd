class_name Shapes
extends RefCounted
## Placeholder art: simple outlined shapes, optionally with a cute face.


static func points(kind: String, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match kind:
		"square":
			var h := r * 0.82
			pts.append(c + Vector2(-h, -h))
			pts.append(c + Vector2(h, -h))
			pts.append(c + Vector2(h, h))
			pts.append(c + Vector2(-h, h))
		"triangle":
			var shifted := c + Vector2(0, r * 0.15)
			for i in 3:
				pts.append(shifted + Vector2.from_angle(-PI / 2 + TAU * i / 3.0) * r * 1.1)
		"diamond":
			for i in 4:
				pts.append(c + Vector2.from_angle(-PI / 2 + TAU * i / 4.0) * r)
		"hexagon":
			for i in 6:
				pts.append(c + Vector2.from_angle(TAU * i / 6.0) * r)
		"star":
			for i in 10:
				var radius := r if i % 2 == 0 else r * 0.48
				pts.append(c + Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * radius)
		_:
			for i in 32:
				pts.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
	return pts


static func draw(
	ci: CanvasItem, kind: String, c: Vector2, r: float, fill: Color,
	outline: Color = UI.INK, width: float = 4.0, face: bool = false
) -> void:
	var pts := points(kind, c, r)
	ci.draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, outline, width, true)
	if face:
		var eye_y := c.y + r * 0.02
		for side in [-1.0, 1.0]:
			var eye := Vector2(c.x + side * r * 0.26, eye_y)
			ci.draw_circle(eye, r * 0.12, outline)
			ci.draw_circle(eye + Vector2(r * 0.04, -r * 0.04), r * 0.045, Color.WHITE)
		ci.draw_arc(c + Vector2(0, r * 0.2), r * 0.14, 0.3, PI - 0.3, 12, outline, maxf(2.0, width * 0.6))
