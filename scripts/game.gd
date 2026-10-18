extends Node
## Global state for one match. Registered as the "Game" autoload.

const ROUNDS := 8
const CROWN_COST := 20
const BOARD_SIZE := 24
const START_COINS := 10
const BOSS_COUNT := 2
const BOSS_TURNS := 6

const MODE_CROWNS := "crowns"
const MODE_HUNT := "hunt"
const MODE_NAMES := {MODE_CROWNS: "Crown Collector", MODE_HUNT: "Monster Hunt"}

var mode := MODE_CROWNS
## Monster Hunt: roaming mini-bosses. Each is {name, shape, color, hp, max, atk, pos}.
var bosses: Array[Dictionary] = []
var bosses_defeated := 0

var players: Array[Dictionary] = []
var spaces: Array[String] = []
var shrine_index := 0
var round_num := 1
## Headless self-test: every choice is made automatically and time runs fast.
var autoplay := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	var args := OS.get_cmdline_user_args()
	autoplay = args.has("--autoplay")
	if args.has("--mode=hunt"):
		mode = MODE_HUNT


func new_game(human_class: String) -> void:
	players.clear()
	players.append(_make_player("You", human_class, true))
	for cls in Data.CLASS_ORDER:
		if cls != human_class:
			players.append(_make_player("Bot " + cls, cls, false))
	round_num = 1
	_build_board()
	bosses.clear()
	bosses_defeated = 0
	if mode == MODE_HUNT:
		for _k in BOSS_COUNT:
			bosses.append(_new_boss())


func is_hunt() -> bool:
	return mode == MODE_HUNT


func score_name() -> String:
	return "Trophies" if is_hunt() else "Crowns"


func score(p: Dictionary) -> int:
	return int(p["trophies"]) if is_hunt() else int(p["crowns"])


func boss_at(pos: int) -> Dictionary:
	for b in bosses:
		if b["pos"] == pos:
			return b
	return {}


## Replace a defeated boss with a fresh, slightly tougher one somewhere else.
func respawn_boss(old: Dictionary) -> Dictionary:
	bosses_defeated += 1
	var idx := bosses.find(old)
	var fresh := _new_boss()
	if idx >= 0:
		bosses[idx] = fresh
	return fresh


func _new_boss() -> Dictionary:
	var used: Array[String] = []
	for b in bosses:
		used.append(b["name"])
	var pool: Array[Dictionary] = []
	for b in Data.BOSSES:
		if not used.has(b["name"]):
			pool.append(b)
	var base: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var hp: int = int(base["hp"]) + bosses_defeated * 6
	var boss := base.duplicate()
	boss["max"] = hp
	boss["hp"] = hp
	boss["atk"] = int(base["atk"]) + bosses_defeated / 2
	boss["tier"] = 2
	boss["pos"] = _free_boss_spot()
	return boss


func _free_boss_spot() -> int:
	for _attempt in 50:
		var spot := rng.randi_range(2, BOARD_SIZE - 1)
		var taken := false
		for b in bosses:
			if b["pos"] == spot:
				taken = true
		for p in players:
			if p["pos"] == spot:
				taken = true
		if not taken:
			return spot
	return BOARD_SIZE / 2


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
		if score(a) != score(b):
			return score(a) > score(b)
		return a["coins"] > b["coins"]
	)
	return ranked


func _make_player(player_name: String, cls: String, human: bool) -> Dictionary:
	return {
		"name": player_name, "cls": cls, "human": human,
		"pos": 0, "coins": START_COINS, "crowns": 0, "trophies": 0,
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
