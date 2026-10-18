class_name ShopScreen
extends Control
## Shop overlay: buy consumables and permanent gear with coins.

signal finished

var player: Dictionary
var auto := false
var offers: Array[Dictionary] = []
var coins_label: Label
var note: Label
var list: VBoxContainer


## Call before adding to the tree.
func setup(p: Dictionary, is_auto: bool) -> void:
	player = p
	auto = is_auto
	offers = Game.shop_offers(p)


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.11, 0.14, 0.25, 0.55)
	UI.full_rect(shade)
	add_child(shade)

	var panel := UI.panel(UI.PAPER, 6)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var wrap := UI.margin(panel, 22)
	UI.full_rect(wrap)
	add_child(wrap)

	col.add_child(UI.label("Wandering Merchant", 44, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	coins_label = UI.label("", 30, UI.INK, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(coins_label)
	note = UI.label("", 24, UI.INK.lightened(0.25), HORIZONTAL_ALIGNMENT_CENTER, true)
	col.add_child(note)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(list)

	var leave := UI.button("Leave Shop", UI.BLUE, 32)
	leave.pressed.connect(func() -> void: finished.emit())
	col.add_child(leave)
	_refresh()

	if auto:
		_auto_shop()


func _auto_shop() -> void:
	await get_tree().create_timer(0.6).timeout
	var bought := Game.bot_shop(player, offers)
	note.text = "Bought: " + (", ".join(bought) if not bought.is_empty() else "nothing")
	_refresh()
	if Game.autoplay:
		_check_layout()
	await get_tree().create_timer(1.0).timeout
	finished.emit()


func _refresh() -> void:
	coins_label.text = "You have %d coins   |   Lv %d" % [player["coins"], player["level"]]
	for child in list.get_children():
		child.queue_free()
	for offer in offers:
		list.add_child(_offer_button(offer))


func _offer_button(offer: Dictionary) -> Button:
	var permanent: bool = offer["kind"] != "item"
	var color := UI.SUPPORT if permanent else UI.BLUE
	var b := UI.button("%s  -  %d coins\n%s" % [offer["name"], offer["price"], offer["desc"]], color, 24)
	b.custom_minimum_size = Vector2(0, 100)
	b.disabled = int(player["coins"]) < int(offer["price"])
	b.pressed.connect(func() -> void:
		if Game.buy(player, offer):
			note.text = "Bought %s!" % offer["name"]
			if offer["kind"] != "item":
				offers.erase(offer)
			else:
				offer["desc"] = "%s (have %d)" % [Data.ITEMS[offer["key"]]["desc"], Game.item_count(player, offer["key"])]
			_refresh()
	)
	return b


## Self-test: the Leave button must be on screen.
func _check_layout() -> void:
	var leave := list.get_parent().get_child(list.get_parent().get_child_count() - 1) as Control
	if leave.get_global_rect().end.y > get_viewport_rect().end.y + 1.0:
		printerr("LAYOUT ERROR: shop runs off the bottom of the screen")
