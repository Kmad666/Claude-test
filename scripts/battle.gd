class_name Battle
extends RefCounted
## Turn-based battle rules with no UI. Used by the battle screen and to simulate bot fights.

const MAX_TURNS := 12
const WIN := 1
const DRAW := 0
const LOSE := -1

var hero_name := ""
var hero_hp := 0
var hero_max := 0
var moves: Array[Dictionary] = []
var uses: Array[int] = []
var guard := false
var buff := false

var monster: Dictionary
var mon_name := ""
var mon_hp := 0
var mon_max := 0
var mon_atk := 0
var weak := false
var poison_turns := 0
var poison_dmg := 0

var turn := 0
var fled := false
var rng: RandomNumberGenerator


func _init(player: Dictionary, foe: Dictionary, random: RandomNumberGenerator) -> void:
	var data: Dictionary = Data.CLASSES[player["cls"]]
	hero_name = player["name"]
	hero_max = data["hp"]
	hero_hp = hero_max
	for m in data["moves"]:
		moves.append(m)
		uses.append(int(m.get("uses", -1)))
	monster = foe
	mon_name = foe["name"]
	mon_max = foe["hp"]
	mon_hp = mon_max
	mon_atk = foe["atk"]
	rng = random


func can_use(idx: int) -> bool:
	return uses[idx] != 0


func describe(idx: int) -> String:
	var m := moves[idx]
	var text := ""
	match m["kind"]:
		"attack":
			text = "PWR %d  |  %d%%" % [m["power"], m["acc"]]
		"heal":
			text = "Heal %d HP" % m["amount"]
		"guard":
			text = "Halve next hit"
		"buff":
			text = "Next attack x1.5"
		"weaken":
			text = "Foe's next hit x0.5"
		"poison":
			text = "%d dmg for 3 turns" % m["power"]
	if uses[idx] >= 0:
		text += "  (%d left)" % uses[idx]
	return text


func use_move(idx: int) -> Array[String]:
	turn += 1
	var m := moves[idx]
	var out: Array[String] = ["%s used %s!" % [hero_name, m["name"]]]
	if uses[idx] > 0:
		uses[idx] -= 1
	match m["kind"]:
		"attack":
			if _hits(m["acc"]):
				var dmg: int = m["power"]
				if buff:
					dmg = int(ceil(dmg * 1.5))
					buff = false
				if rng.randf() < 0.1:
					dmg *= 2
					out.append("A critical hit!")
				mon_hp = maxi(0, mon_hp - dmg)
				out.append("The %s took %d damage." % [mon_name, dmg])
			else:
				out.append("It missed!")
		"heal":
			var before := hero_hp
			hero_hp = mini(hero_max, hero_hp + int(m["amount"]))
			out.append("Recovered %d HP." % (hero_hp - before))
		"guard":
			guard = true
			out.append("Guard is up!")
		"buff":
			buff = true
			out.append("The next attack is blessed!")
		"weaken":
			if _hits(m["acc"]):
				weak = true
				out.append("The %s is chilled and weakened!" % mon_name)
			else:
				out.append("It missed!")
		"poison":
			if _hits(m["acc"]):
				poison_turns = 3
				poison_dmg = m["power"]
				out.append("The %s is poisoned!" % mon_name)
			else:
				out.append("It missed!")
	return out


func monster_turn() -> Array[String]:
	var out: Array[String] = []
	if poison_turns > 0:
		poison_turns -= 1
		mon_hp = maxi(0, mon_hp - poison_dmg)
		out.append("Poison stings the %s for %d." % [mon_name, poison_dmg])
		if mon_hp == 0:
			return out
	out.append("The %s attacks!" % mon_name)
	if _hits(85):
		var dmg := mon_atk + rng.randi_range(0, 2)
		if weak:
			dmg = maxi(1, int(dmg * 0.5))
		if guard:
			dmg = maxi(1, int(dmg * 0.5))
			out.append("The guard softens the blow.")
		hero_hp = maxi(0, hero_hp - dmg)
		out.append("It hits %s for %d damage." % [hero_name, dmg])
	else:
		out.append("But it missed!")
	weak = false
	guard = false
	if turn >= MAX_TURNS and not is_over():
		fled = true
		out.append("The %s loses interest and wanders off." % mon_name)
	return out


func is_over() -> bool:
	return hero_hp <= 0 or mon_hp <= 0 or fled


func result() -> int:
	if mon_hp <= 0:
		return WIN
	if hero_hp <= 0:
		return LOSE
	return DRAW


## Simple AI for bots (and the self-test): heal when low, sometimes use a support move, else attack.
func bot_pick() -> int:
	var heal_idx := -1
	var attacks: Array[int] = []
	var support: Array[int] = []
	for i in moves.size():
		if not can_use(i):
			continue
		match moves[i]["kind"]:
			"heal":
				heal_idx = i
			"attack":
				attacks.append(i)
			"poison":
				if poison_turns == 0:
					support.append(i)
			"buff":
				if not buff:
					support.append(i)
			_:
				support.append(i)
	if heal_idx >= 0 and hero_hp < hero_max * 0.45:
		return heal_idx
	if not support.is_empty() and rng.randf() < 0.25:
		return support[rng.randi_range(0, support.size() - 1)]
	return attacks[rng.randi_range(0, attacks.size() - 1)]


func simulate() -> int:
	while not is_over():
		use_move(bot_pick())
		if is_over():
			break
		monster_turn()
	return result()


func _hits(accuracy: int) -> bool:
	return rng.randi_range(1, 100) <= accuracy
