# Wildwood Party — Feature Roadmap

The living feature list for the Godot version. Updated as features ship.

**Play:** https://kmad666.github.io/Claude-test/

## Done

### Core
- [x] Cloud pipeline: every push builds with Godot, play-tests a full bot game of every mode, checks the layout fits a phone screen, then publishes to the web
- [x] Phone-first portrait layout, abstract-shape placeholder art
- [x] 1 human + 3 bots, each player with their own token color
- [x] 8-round board loop with dice, hopping tokens, and a live scoreboard

### Classes
- [x] Warrior (square): tough and hard-hitting
- [x] Mage (triangle): fragile, big damage
- [x] Rogue and Cleric removed until they can be differentiated and balanced

### Board
- [x] Spaces: coins (+), thorns (-), skill-check events (?), battles (!), shops ($)
- [x] D&D-style skill checks: d20 + stat vs a target number, with natural 20 bonus
- [x] 8 events (rope bridge, sphinx riddle, fairy circle, etc.)

### Battles
- [x] Pokémon-style screen: foe up top, hero below, HP bars, 4 class moves + Potion
- [x] Attacks, guard, heal, weaken, buff effects; crits and misses
- [x] 6 regular monsters in 3 difficulty tiers that scale with the round

### Modes
- [x] **Crown Collector**: buy Crowns (15 coins) within one space of a moving shrine
- [x] **Monster Hunt**: 2 roaming mini-bosses with shared damage, ambushes, Trophies for the final blow, tougher respawns

### Progression
- [x] XP and levels (Lv 1–5): +3 max HP and +1 attack power per level
- [x] Shop: Potion, Whetstone, Lucky Charm, Swift Boots, Sturdy Armor, stat gear
- [x] Coin rerolls for low movement rolls and failed skill checks
- [x] Bots shop, level up, and reroll

### Minigames (after every round)
- [x] Target Tap, Timing Bar, Quick Draw (prizes 8 / 5 / 3 / 1 coins)

## Up next (suggested order)

1. [ ] **Class identity**: a once-per-game board ability per class (e.g. Warrior shoves a boss, Mage teleports), so classes differ outside battle too
2. [ ] **Re-add Rogue and Cleric** once they have a clear role (e.g. Rogue = coin theft and speed, Cleric = support and healing others)
3. [ ] **Economy pass**: players still end with 30–40 spare coins; tune prices and rewards
4. [ ] **Pass-and-play**: 2–4 humans sharing one phone
5. [ ] **Juice**: sound effects, floating "+3 coins" numbers, screen shake, a proper title screen
6. [ ] **More minigames**: memory flip, tap race, dodge, etc.

## Later

- [ ] **Demon King's March**: linear co-op campaign ending in a final boss
- [ ] **Kingdom Siege**: team PvP campaign
- [ ] **Online multiplayer** (2–4 players)
- [ ] **Android app** build alongside the web version
- [ ] **Random board events** (weather, shrine moves, wandering merchants)
- [ ] **Settings**: number of rounds, number of bots, game speed
- [ ] **Real art**: bright storybook look (Paper Mario vibe), chibi characters, once the game plays well
