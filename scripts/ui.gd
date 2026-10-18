class_name UI
extends RefCounted
## Shared colors and widget builders for a bright storybook look.

const INK := Color(0.11, 0.14, 0.25)
const PAPER := Color(1.0, 0.98, 0.92)
const SKY := Color(0.55, 0.82, 0.95)
const GOLD := Color(1.0, 0.80, 0.15)
const ACTION := Color(0.98, 0.45, 0.20)
const SUPPORT := Color(0.15, 0.68, 0.62)
const BLUE := Color(0.25, 0.50, 0.96)


static func box(color: Color, radius: int = 20, border: int = 0, border_color: Color = INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = border_color
	sb.set_content_margin_all(14)
	return sb


static func button(text: String, color: Color = BLUE, font_size: int = 32) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 92)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", box(color, 22, 4))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.12), 22, 4))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.2), 22, 4))
	b.add_theme_stylebox_override("hover_pressed", box(color.darkened(0.2), 22, 4))
	b.add_theme_stylebox_override("disabled", box(Color(0.70, 0.70, 0.74), 22, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.95, 0.95, 0.95))
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 8)
	return b


static func label(
	text: String, font_size: int = 30, color: Color = INK,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	return l


static func panel(color: Color = PAPER, border: int = 4) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, 22, border))
	return p


static func margin(child: Control, px: int) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, px)
	m.add_child(child)
	return m


static func hp_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 24)
	var bg := box(Color(0.82, 0.82, 0.86), 12, 3)
	bg.set_content_margin_all(0)
	var fill := box(Color(0.25, 0.80, 0.40), 12, 0)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func set_bar_color(bar: ProgressBar) -> void:
	var ratio := bar.value / maxf(1.0, bar.max_value)
	var color := Color(0.25, 0.80, 0.40)
	if ratio < 0.25:
		color = Color(0.92, 0.25, 0.25)
	elif ratio < 0.5:
		color = Color(0.98, 0.75, 0.15)
	var fill := box(color, 12, 0)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)


static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
