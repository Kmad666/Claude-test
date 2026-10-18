extends Node
## Global state for one match. Registered as the "Game" autoload.

const ROUNDS := 8
const CROWN_COST := 20
const BOARD_SIZE := 24
const START_COINS := 10
const BOSS_COUNT := 2
const BOSS_TURNS := 6

const MAX_LEVEL := 5
## XP needed to go from level N to N+1 is XP_LEVELS[N].
const XP_LEVELS: Array[int] = [0, 10, 24, 42, 64]
const HP_PER_LEVEL := 3
const GEAR_PRICE := 12
const ARMOR_HP := 4
const MAX_GEAR := 3
const REROLL_COST := 3
const POTION_HEAL := 12

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
	return int(class_data(p)["stats"][stat]) + int(p["gear"][stat])


# ---------------------------------------------------------------- progression

func max_hp(p: Dictionary) -> int:
	return int(class_data(p)["hp"]) + (int(p["level"]) - 1) * HP_PER_LEVEL + int(p["armor"]) * ARMOR_HP


func power_bonus(p: Dictionary) -> int:
	return int(p["level"]) - 1


## Adds XP and returns how many levels were gained.
func add_xp(p: Dictionary, amount: int) -> int:
	p["xp"] = int(p["xp"]) + amount
	var gained := 0
	while int(p["level"]) < MAX_LEVEL and int(p["xp"]) >= XP_LEVELS[int(p["level"])]:
		p["level"] = int(p["level"]) + 1
		gained += 1
	return gained


func xp_to_next(p: Dictionary) -> int:
	var lvl := int(p["level"])
	return 0 if lvl >= MAX_LEVEL else XP_LEVELS[lvl] - int(p["xp"])


func item_count(p: Dictionary, key: String) -> int:
	return int(p["items"][key])


func use_item(p: Dictionary, key: String) -> bool:
	if item_count(p, key) <= 0:
		return false
	p["items"][key] = item_count(p, key) - 1
	return true


# ---------------------------------------------------------------- shop

## What a shop offers this visit: all consumables, Armor, and one random stat upgrade.
func shop_offers(p: Dictionary) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for key in Data.ITEMS:
		var item: Dictionary = Data.ITEMS[key]
		offers.append({
			"kind": "item", "key": key, "name": item["name"], "price": item["price"],
			"desc": "%s (have %d)" % [item["desc"], item_count(p, key)],
		})
	if int(p["armor"]) < MAX_GEAR:
		offers.append({
			"kind": "armor", "key": "armor", "name": "Sturdy Armor", "price": GEAR_PRICE,
			"desc": "+%d max HP, permanent" % ARMOR_HP,
		})
	var stats: Array[String] = []
	for stat in Data.STAT_GEAR:
		if int(p["gear"][stat]) < MAX_GEAR:
			stats.append(stat)
	if not stats.is_empty():
		var stat := stats[rng.randi_range(0, stats.size() - 1)]
		offers.append({
			"kind": "stat", "key": stat, "name": Data.STAT_GEAR[stat], "price": GEAR_PRICE,
			"desc": "+1 %s for skill checks, permanent" % stat,
		})
	return offers


func buy(p: Dictionary, offer: Dictionary) -> bool:
	var price: int = offer["price"]
	if int(p["coins"]) < price:
		return false
	add_coins(p, -price)
	match offer["kind"]:
		"item":
			p["items"][offer["key"]] = item_count(p, offer["key"]) + 1
		"armor":
			p["armor"] = int(p["armor"]) + 1
		"stat":
			p["gear"][offer["key"]] = int(p["gear"][offer["key"]]) + 1
	return true


## Bots keep a reserve for Crowns, then buy gear first and a spare potion.
func bot_shop(p: Dictionary, offers: Array[Dictionary]) -> Array[String]:
	var bought: Array[String] = []
	var reserve := 0 if is_hunt() else CROWN_COST
	for offer in offers:
		var wanted := false
		match offer["kind"]:
			"armor", "stat":
				wanted = true
			"item":
				wanted = offer["key"] == "potion" and item_count(p, "potion") == 0
		if wanted and int(p["coins"]) - int(offer["price"]) >= reserve:
			if buy(p, offer):
				bought.append(offer["name"])
	return bought


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
		"level": 1, "xp": 0, "armor": 0,
		"items": {"potion": 1, "whetstone": 0, "charm": 0, "boots": 0},
		"gear": {"STR": 0, "DEX": 0, "INT": 0, "WIS": 0},
	}


func _build_board() -> void:
	var pattern: Array[String] = [
		"coin", "battle", "coin", "event", "hazard", "shop",
		"coin", "event", "battle", "coin", "hazard", "shop",
	]
	spaces.clear()
	for i in BOARD_SIZE:
		spaces.append(pattern[i % pattern.size()])
	spaces.shuffle()
	spaces[0] = "start"
	shrine_index = 0
	move_shrine()
