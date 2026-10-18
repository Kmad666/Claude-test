class_name Data
extends RefCounted
## Static game content: hero classes, monsters, and skill-check events.

## Each player gets their own token color; the class decides the shape.
static var PLAYER_COLORS: Array[Color] = [
	Color(0.93, 0.30, 0.32), Color(0.30, 0.52, 0.98), Color(0.20, 0.75, 0.45), Color(0.98, 0.76, 0.20),
]

static var CLASS_ORDER: Array[String] = ["Warrior", "Mage"]

static var CLASSES: Dictionary = {
	"Warrior": {
		"shape": "square",
		"color": Color(0.93, 0.30, 0.32),
		"hp": 30,
		"stats": {"STR": 4, "DEX": 1, "INT": 0, "WIS": 1},
		"blurb": "Tough and hard-hitting.",
		"moves": [
			{"name": "Slash", "kind": "attack", "power": 6, "acc": 95},
			{"name": "Heavy Blow", "kind": "attack", "power": 11, "acc": 65},
			{"name": "Shield Up", "kind": "guard"},
			{"name": "Second Wind", "kind": "heal", "amount": 9, "uses": 1},
		],
	},
	"Mage": {
		"shape": "triangle",
		"color": Color(0.30, 0.52, 0.98),
		"hp": 22,
		"stats": {"STR": 0, "DEX": 1, "INT": 4, "WIS": 2},
		"blurb": "Fragile, but packs a punch.",
		"moves": [
			{"name": "Firebolt", "kind": "attack", "power": 8, "acc": 90},
			{"name": "Arcane Blast", "kind": "attack", "power": 14, "acc": 60},
			{"name": "Frost Hex", "kind": "weaken", "acc": 90},
			{"name": "Mana Shield", "kind": "guard"},
		],
	},
}

static var MONSTERS: Array[Dictionary] = [
	{"name": "Slime", "shape": "circle", "color": Color(0.55, 0.88, 0.40), "hp": 14, "atk": 3, "tier": 0},
	{"name": "Goblin", "shape": "triangle", "color": Color(0.60, 0.72, 0.28), "hp": 18, "atk": 4, "tier": 0},
	{"name": "Dire Wolf", "shape": "diamond", "color": Color(0.58, 0.58, 0.70), "hp": 22, "atk": 5, "tier": 1},
	{"name": "Skeleton", "shape": "square", "color": Color(0.92, 0.90, 0.82), "hp": 20, "atk": 6, "tier": 1},
	{"name": "Ogre", "shape": "hexagon", "color": Color(0.80, 0.55, 0.35), "hp": 30, "atk": 7, "tier": 2},
	{"name": "Wyvern", "shape": "star", "color": Color(0.70, 0.35, 0.85), "hp": 26, "atk": 8, "tier": 2},
]

static var BOSSES: Array[Dictionary] = [
	{"name": "Minotaur", "shape": "square", "color": Color(0.62, 0.36, 0.22), "hp": 40, "atk": 6},
	{"name": "Hydra", "shape": "star", "color": Color(0.20, 0.62, 0.55), "hp": 46, "atk": 5},
	{"name": "Cyclops", "shape": "circle", "color": Color(0.85, 0.60, 0.45), "hp": 44, "atk": 7},
	{"name": "Manticore", "shape": "triangle", "color": Color(0.90, 0.40, 0.25), "hp": 38, "atk": 8},
	{"name": "Basilisk", "shape": "diamond", "color": Color(0.45, 0.70, 0.20), "hp": 42, "atk": 7},
	{"name": "Chimera", "shape": "hexagon", "color": Color(0.80, 0.30, 0.55), "hp": 48, "atk": 6},
]

static var EVENTS: Array[Dictionary] = [
	{
		"title": "Rope Bridge", "stat": "DEX", "dc": 12,
		"text": "A rickety rope bridge sways over a ravine.",
		"win": "You dance across and find a dropped purse!",
		"lose": "You slip! Coins tumble into the ravine.",
	},
	{
		"title": "Stuck Boulder", "stat": "STR", "dc": 12,
		"text": "A boulder blocks the mouth of a hidden cave.",
		"win": "You heave it aside. Treasure inside!",
		"lose": "It won't budge, and you pull a muscle.",
	},
	{
		"title": "Riddling Sphinx", "stat": "INT", "dc": 13,
		"text": "A sphinx demands the answer to a riddle.",
		"win": "Correct! The sphinx pays up.",
		"lose": "Wrong! The sphinx charges a fee.",
	},
	{
		"title": "Wounded Traveler", "stat": "WIS", "dc": 11,
		"text": "A traveler lies hurt beside the road.",
		"win": "You patch them up. They reward you!",
		"lose": "Your clumsy bandaging costs you supplies.",
	},
	{
		"title": "Locked Chest", "stat": "DEX", "dc": 13,
		"text": "A heavy chest with a tricky lock.",
		"win": "Click! The lock gives way.",
		"lose": "A needle trap! You pay for a healer.",
	},
	{
		"title": "Tavern Arm-Wrestle", "stat": "STR", "dc": 13,
		"text": "A burly dwarf challenges you for a wager.",
		"win": "You slam their arm down. Pay up, dwarf!",
		"lose": "Thud. You lose the wager.",
	},
	{
		"title": "Ancient Runes", "stat": "INT", "dc": 12,
		"text": "Glowing runes cover a forgotten door.",
		"win": "You decipher them. The door opens to gold!",
		"lose": "The runes zap you and scatter your coins.",
	},
	{
		"title": "Fairy Circle", "stat": "WIS", "dc": 12,
		"text": "Mushrooms ring a patch of shimmering grass.",
		"win": "The fairies like your manners. A gift!",
		"lose": "The fairies play a prank on your purse.",
	},
]


static var ITEMS: Dictionary = {
	"potion": {"name": "Potion", "price": 5, "desc": "Heal 12 HP in battle"},
	"whetstone": {"name": "Whetstone", "price": 6, "desc": "+3 attack power next battle"},
	"charm": {"name": "Lucky Charm", "price": 6, "desc": "Auto +3 to save a failed check"},
	"boots": {"name": "Swift Boots", "price": 4, "desc": "Roll 2 dice on one turn"},
}

static var STAT_GEAR: Dictionary = {
	"STR": "Iron Gauntlets", "DEX": "Swift Gloves", "INT": "Sage's Tome", "WIS": "Holy Charm",
}
