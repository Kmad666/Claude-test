extends Node
## Global state for one match. Registered as the "Game" autoload.

const ROUNDS := 8
const CROWN_COST := 20
const BOARD_SIZE := 24
const START_COINS := 10

var players: Array[Dictionary] = []
var spaces: Array[String] = []
var shrine_index := 0
var round_num := 1
## Headless self-test: every choice is made automatically and time runs fast.
var autoplay := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	autoplay = OS.get_cmdline_user_args().has("--autoplay")


func new_game(human_class: String) -> void:
	players.clear()
	players.append(_make_player("You", human_class, true))
	for cls in Data.CLASS_ORDER:
		if cls != human_class:
			players.append(_make_player("Bot " + cls, cls, false))
	round_num = 1
	_build_board()


func is_auto(p: Dictionary) -> bool:
	return autoplay or not p["human"]


func class_data(p: Dictionary) -> Dictionary:
	return Data.CLASSES[p["cls"]]


func stat_bonus(p: Dictionary, stat: String) -> int:
	return int(class_data(p)["stats"][stat])


func add_coins(p: Dictionary, amount: int) -> int:
	var before: int = p["coins"]
	p["coins"] = maxi(0, before + amount)
	return int(p["coins"]) - before


func pick_monster() -> Dictionary:
	var tier := clampi((round_num - 1) / 3, 0, 2)
	var pool: Array[Dictionary] = []
	for m in Data.MONSTERS:
		if m["tier"] == tier or m["tier"] == tier - 1:
			pool.append(m)
	return pool[rng.randi_range(0, pool.size() - 1)]


func pick_event() -> Dictionary:
	return Data.EVENTS[rng.randi_range(0, Data.EVENTS.size() - 1)]


func move_shrine() -> void:
	var next := shrine_index
	while next == shrine_index or next == 0:
		next = rng.randi_range(1, BOARD_SIZE - 1)
	shrine_index = next


func standings() -> Array[Dictionary]:
	var ranked: Array[Dictionary] = players.duplicate()
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["crowns"] != b["crowns"]:
			return a["crowns"] > b["crowns"]
		return a["coins"] > b["coins"]
	)
	return ranked


func _make_player(player_name: String, cls: String, human: bool) -> Dictionary:
	return {
		"name": player_name, "cls": cls, "human": human,
		"pos": 0, "coins": START_COINS, "crowns": 0,
	}


func _build_board() -> void:
	var pattern: Array[String] = ["coin", "battle", "coin", "event", "hazard", "coin", "event", "battle"]
	spaces.clear()
	for i in BOARD_SIZE:
		spaces.append(pattern[i % pattern.size()])
	spaces.shuffle()
	spaces[0] = "start"
	shrine_index = 0
	move_shrine()
