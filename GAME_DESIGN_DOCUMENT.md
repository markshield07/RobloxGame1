# 99 Storms — Game Design Document

## One-Line Pitch
**Survive 99 supernatural storms in a cursed coastal town — fortify buildings, craft weather-defying gear, hunt between storms, and uncover why The Tempest won't let you leave.**

---

## Table of Contents
1. [Game Overview](#1-game-overview)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [The Setting — Stormhaven](#3-the-setting--stormhaven)
4. [Storm System](#4-storm-system)
5. [The Antagonist — The Tempest](#5-the-antagonist--the-tempest)
6. [Classes](#6-classes)
7. [Base Building & Fortification](#7-base-building--fortification)
8. [Crafting System](#8-crafting-system)
9. [Rescue Missions](#9-rescue-missions)
10. [Exploration & Biomes](#10-exploration--biomes)
11. [Creatures & Taming](#11-creatures--taming)
12. [Progression & Difficulty Scaling](#12-progression--difficulty-scaling)
13. [Multiplayer & Social Systems](#13-multiplayer--social-systems)
14. [Monetization](#14-monetization)
15. [Content Creator Features](#15-content-creator-features)
16. [Update Roadmap](#16-update-roadmap)
17. [Technical Requirements](#17-technical-requirements)

---

## 1. Game Overview

| Detail | Value |
|--------|-------|
| **Title** | 99 Storms |
| **Platform** | Roblox |
| **Genre** | Survival Horror / Base Building / Co-op |
| **Players** | 1–5 (co-op) |
| **Target Audience** | Ages 9+ (family-friendly horror) |
| **Session Length** | 30–90 minutes per session, ~15–25 hours full playthrough |
| **Win Condition** | Survive 99 storms and rescue 4 missing townspeople |
| **Inspiration** | 99 Nights in the Forest, The Long Dark, Stardew Valley, Don't Starve |

### Narrative Hook
You and your crew arrive in **Stormhaven**, a once-thriving coastal town, to investigate why it was abandoned overnight. Within hours, you discover the answer: The town is cursed. A sentient supernatural storm — **The Tempest** — has claimed the town as its domain and will not let anyone leave. Every cycle, The Tempest sends increasingly violent storms. Your only chance of survival is to fortify the town, find the four missing townspeople who hold the secret to breaking the curse, and endure 99 storms until the curse can be shattered.

### Why This Concept Works
- **Weather as the antagonist** is visually spectacular and mechanically rich — every storm type plays differently
- **Coastal town setting** is underused in Roblox — offers boats, fishing, lighthouses, piers, and ocean exploration
- **"Cozy between storms"** creates emotional contrast — players feel safe and productive between storms, then terrified during them
- **Variety of storm types** keeps every session fresh — no two storms feel the same
- **Town restoration** gives a visible sense of progress — the town looks better over time

---

## 2. Core Gameplay Loop

```
┌─────────────────────────────────────────────────────────┐
│                    THE CALM (Daytime)                     │
│  Gather resources → Craft items → Fortify buildings       │
│  Explore the coast → Fish & farm → Trade with NPCs       │
│  Repair storm damage → Recruit companions → Prepare       │
└───────────────────────────┬─────────────────────────────┘
                            │
                    Storm Warning Siren
                            │
┌───────────────────────────▼─────────────────────────────┐
│                   THE STORM (Nighttime)                   │
│  Hunker down → Defend base → Fight storm creatures        │
│  Manage resources → Protect rescued townspeople           │
│  Survive The Tempest's assault → Rescue teammates         │
└───────────────────────────┬─────────────────────────────┘
                            │
                     Storm Clears
                            │
┌───────────────────────────▼─────────────────────────────┐
│                  THE AFTERMATH (Dawn)                     │
│  Assess damage → Collect storm drops → Scavenge debris    │
│  Discover new areas revealed by storm → Heal & regroup    │
└─────────────────────────────────────────────────────────┘
```

### Timing
- **The Calm** lasts ~8 minutes (in-game daytime)
- **Storm Warning** is a 60-second siren warning before each storm
- **The Storm** lasts ~5 minutes (intensity and duration scale with progression)
- **The Aftermath** lasts ~2 minutes (brief scavenging window)
- **Total cycle:** ~15 minutes per storm cycle

### The Campfire Equivalent — The Lighthouse
The **Lighthouse** is the central safe zone. Its beam repels storm creatures and The Tempest within a radius. Players must keep the lighthouse fueled with oil, coal, or later electricity. If the lighthouse goes dark during a storm, there is no safe zone. Upgrading the lighthouse extends its protective radius and unlocks new capabilities.

**Lighthouse Levels:**
| Level | Fuel | Radius | Bonus |
|-------|------|--------|-------|
| 1 | Oil lanterns | 15 studs | Basic light |
| 2 | Coal furnace | 25 studs | Reveals nearby storm creatures |
| 3 | Gas generator | 40 studs | Slows storm creatures in radius |
| 4 | Electric grid | 60 studs | Damages storm creatures + weather radar |
| 5 | Storm Crystal | 80 studs | Weakens The Tempest itself |

---

## 3. The Setting — Stormhaven

Stormhaven is a medium-sized coastal New England-style town situated on a rocky peninsula. The aesthetic is **weathered, nautical, and atmospheric** — think clapboard houses, cobblestone streets, a fishing pier, a lighthouse on the cliff, lobster traps, foghorns, and seagulls.

### Town Districts

#### Harbor District (Starting Area)
- **The Pier** — fishing spot, boat crafting, dock storage
- **Fish Market** — NPC trader, cooking station
- **Harbormaster's Office** — quest board, map, storm log
- **Boathouse** — boat storage, raft building
- Starting resources are abundant but buildings are damaged

#### Main Street
- **General Store** — NPC shop, basic supplies
- **Blacksmith** — weapon/tool crafting
- **Town Hall** — community chest, town upgrade board
- **Clinic** — healing, medical crafting
- **Tavern** — food crafting, NPC rumors/hints, jukebox

#### Residential Hill
- **Houses (6)** — can be claimed as personal bases, each with different advantages
  - **Cliff House** — high ground, good visibility, wind-exposed
  - **Cellar House** — underground shelter, flood-resistant
  - **Garden House** — farming plots, greenhouse potential
  - **Watchtower House** — tallest building, radio antenna
  - **Workshop House** — pre-built crafting stations
  - **Seaside Cottage** — dock access, fishing bonus
- **Church** — healing aura zone, bell tower (early warning)
- **Graveyard** — ghost encounters, rare crafting materials

#### The Lighthouse (Central Hub)
- Located on the highest cliff point overlooking the town
- Safe zone when fueled and lit
- Upgradable (see lighthouse levels above)
- Contains the Storm Log — tracks storm history and patterns
- Telescope for scouting approaching storms

#### The Coast (Surrounding Area)
- **Rocky Shore** — scavenging, tide pools, crab catching
- **Sandy Beach** — turtle nests, driftwood, buried treasure
- **Sea Caves** — accessible at low tide, dangerous at high tide, rare resources
- **Tidal Flats** — clam digging, shallow water fishing
- **Shipwreck Cove** — sunken ship exploration, waterlogged loot

### Beyond Stormhaven (Unlockable Zones)

#### The Marshlands (Storm 15+)
- Foggy wetlands south of town
- Home to frogs, snakes, and the Marsh Lurker
- Contains the **Witch's Shack** — special crafting recipes
- One missing townsperson is here: **Old Pete the Fisherman**

#### The Cliffs (Storm 30+)
- Treacherous cliff faces north of town
- Seabird nesting (feathers for crafting), cliff mining (iron, copper)
- Contains the **Abandoned Mine** — deep resource node, dangerous
- One missing townsperson is here: **Marina the Biologist**

#### The Lighthouse Islands (Storm 50+)
- Small islands accessible only by boat
- Each island has unique resources and dangers
- Contains the **Ruined Second Lighthouse** — key to weakening The Tempest
- One missing townsperson is here: **Captain Briggs**

#### The Maelstrom (Storm 75+)
- The open ocean zone where The Tempest's power is strongest
- Accessible only with a fully upgraded boat
- Whirlpools, sea monsters, floating debris
- Contains **The Tempest's Eye** — the source of the curse
- Final missing townsperson: **Elara the Storm Witch** (she caused the curse accidentally)

---

## 4. Storm System

The storm system is the core differentiator. **No two storms are the same.** Each cycle randomly selects a storm type (weighted by progression), and storm intensity scales with the storm number.

### Storm Types

#### Thunderstorm (Common — Storms 1+)
- Heavy rain reduces visibility
- **Lightning strikes** target the highest points — don't stand on rooftops!
- Lightning can start fires on wooden structures
- Lightning rods (craftable) redirect strikes safely and generate electricity
- **Storm creatures:** Thunder Crabs — electrified crabs that swarm in packs

#### Hurricane (Uncommon — Storms 10+)
- Extreme wind pushes players and objects
- **Structural damage** — unfortified buildings lose walls/roofs
- Flying debris deals damage to players caught outside
- Sandbags and storm shutters are critical
- **Storm creatures:** Wind Wraiths — ghostly figures riding the wind

#### Fog Storm (Common — Storms 5+)
- Near-zero visibility — can't see more than 5 studs ahead
- **Sound-based gameplay** — listen for creature footsteps, use bells/alarms
- Players can get lost and separated easily
- Flares and lanterns are essential
- **Storm creatures:** Fog Phantoms — silent, appear right behind you

#### Hailstorm (Uncommon — Storms 20+)
- Hailstones deal constant AOE damage to anyone outside
- **Roof integrity matters** — damaged roofs let hail through
- Ice accumulation slows movement outdoors
- Warm clothing and covered pathways are key
- **Storm creatures:** Frost Wolves — pack hunters that freeze players on bite

#### Tornado (Rare — Storms 35+)
- A visible tornado funnel moves through the town
- **Destroys anything in its path** — structures, trees, vehicles
- Players caught in it are thrown and take massive damage
- Underground shelters are the only guaranteed safety
- **Storm creatures:** Storm Elementals — swirling debris entities

#### Tsunami Warning (Rare — Storms 45+)
- Rising water levels flood lower areas of town
- **Vertical survival** — get to high ground or drown
- Boats become essential for movement
- After the wave, scavenge flooded buildings for waterlogged resources
- **Storm creatures:** Tide Horrors — deep-sea creatures swept in by the wave

#### Blood Storm (Very Rare — Storms 60+)
- The sky turns red, rain is crimson
- **All storm creature types spawn simultaneously**
- The Tempest itself is visible in the clouds
- Lighthouse beam turns red — reduced effectiveness
- Maximum intensity — this is the endgame challenge

#### The Tempest's Wrath (Boss Storm — Every 25th Storm)
- The Tempest directly attacks the town
- Combines elements of ALL storm types
- The Tempest manifests physically and must be damaged to end the storm
- Surviving earns unique "Storm Crystal" crafting materials

### Storm Intensity Scaling

| Storm Range | Intensity | Duration | Creature Count | Special |
|-------------|-----------|----------|----------------|---------|
| 1–10 | Mild | 3 min | Low | Tutorial storms |
| 11–25 | Moderate | 4 min | Medium | Multi-type combos start |
| 26–50 | Severe | 5 min | High | Rare storms unlock |
| 51–75 | Extreme | 6 min | Very High | Blood storms possible |
| 76–99 | Catastrophic | 7 min | Maximum | Multiple storms per cycle |

---

## 5. The Antagonist — The Tempest

The Tempest is not a single creature but a **sentient weather system** — an atmospheric entity that controls all storms over Stormhaven. It is simultaneously the environment, the enemy, and the atmosphere.

### Visual Design
- During storms, The Tempest is visible as a **massive swirling face in the clouds** — two glowing eyes and a howling mouth made of lightning and wind
- Its expression changes based on intensity — calm curiosity early on, furious rage in late game
- Lightning flashes briefly illuminate its full form spanning the entire sky
- It speaks through **wind sounds** — moaning, howling, whispering. Players near the coast can hear it "talking"

### Behavior Phases

**Phase 1 (Storms 1–25): The Watcher**
- The Tempest observes. Storms are relatively mild.
- Occasionally, players hear whispers on the wind
- The face in the clouds is barely visible — just two faint glowing points
- It's learning the players' patterns

**Phase 2 (Storms 26–50): The Hunter**
- Storms become targeted — lightning strikes near players specifically
- The Tempest's face is clearly visible during storms
- It begins sending storms that counter player strategies (built underground? Flooding. Built high? Wind.)
- Wind whispers become audible words: "Leave... leave... mine..."

**Phase 3 (Storms 51–75): The Destroyer**
- Storms are devastating and frequent
- The Tempest physically manifests tendrils of cloud/lightning that reach into buildings
- It specifically targets the lighthouse and rescued townspeople
- Speaks clearly: "You cannot break what I have claimed."

**Phase 4 (Storms 76–99): The Desperate**
- The curse is weakening as players rescue townspeople
- The Tempest becomes erratic — storms are unpredictable and layered
- It tries to bargain with players through wind speech
- The final confrontation at Storm 99 requires entering The Maelstrom

### The Tempest's Possessed
During storms, The Tempest can **possess** town objects and NPCs:
- **Possessed Weathervanes** — spin wildly, shoot lightning bolts
- **Possessed Boats** — ram the pier autonomously
- **Possessed Scarecrows** — come alive and attack
- **Possessed Bell Tower** — rings deafeningly, stunning nearby players
- **Possessed Townspeople (NPCs)** — temporary, must be "cleansed" not killed

---

## 6. Classes

One default class is free. Premium classes cost Robux via gamepasses.

### Weatherman (Free Default Class)
*"I can feel it in the air..."*

| Ability | Description |
|---------|-------------|
| **Storm Sense** | Can see storm type 30 seconds before the warning siren |
| **Weather Resistance** | 15% reduced damage from all weather effects |
| **Barometer Craft** | Can craft a barometer that shows storm intensity |
| **Wind Reader** | Movement speed less affected by wind |

**Playstyle:** The balanced generalist. Good at everything, master of nothing. The storm prediction gives the team critical preparation time.

### Captain (Premium — 349 Robux)
*"The sea is in my blood."*

| Ability | Description |
|---------|-------------|
| **Master Sailor** | Boats move 40% faster, can sail in storms |
| **Net Fisher** | Fishing catches are doubled |
| **Sea Legs** | Immune to knockback from waves/wind |
| **Anchor Down** | Can create a temporary safe zone on any boat during storms |

**Playstyle:** The explorer and provider. Dominates ocean content — island exploration, fishing, boat combat. Essential for reaching The Lighthouse Islands and The Maelstrom.

### Builder (Premium — 349 Robux)
*"This town will stand."*

| Ability | Description |
|---------|-------------|
| **Fortify** | Structures built have 50% more health |
| **Quick Repair** | Repairs structures 3x faster |
| **Blueprint Vision** | Can see structural weak points on any building |
| **Storm Shelter** | Can build emergency underground shelters anywhere |

**Playstyle:** The defensive backbone. Their structures survive storms that destroy everyone else's. Essential for late-game when storms become devastating.

### Keeper (Premium — 349 Robux)
*"The light must never go out."*

| Ability | Description |
|---------|-------------|
| **Lighthouse Bond** | Lighthouse beam is 25% wider when Keeper is inside |
| **NPC Whisperer** | Townspeople NPCs give better trades and more hints |
| **Town Management** | Can assign NPCs to automated tasks (fishing, farming, repairs) |
| **Beacon Craft** | Can craft portable beacons that create mini safe zones |

**Playstyle:** The support/management class. Turns Stormhaven into a functioning community. Their NPC management creates an "idle game within the game" that's deeply satisfying.

### Stormchaser (Premium — 499 Robux)
*"Into the eye."*

| Ability | Description |
|---------|-------------|
| **Storm Harvest** | Collects Storm Crystals from the environment during storms |
| **Lightning Rod** | Can absorb lightning strikes to charge storm-powered weapons |
| **Tempest Taunt** | Can draw The Tempest's attention away from structures/allies |
| **Eye of the Storm** | Brief invulnerability during the peak of any storm |

**Playstyle:** The aggressive, high-risk class. Goes OUT into storms instead of hiding. Provides the team's best combat resources (Storm Crystals) but must survive the deadliest conditions to do it. This is the "content creator" class — their gameplay is inherently dramatic.

---

## 7. Base Building & Fortification

Unlike 99 Nights where you build from scratch, **99 Storms gives you an existing town to restore and fortify.** This is both easier to start with and more emotionally rewarding — you're rebuilding something.

### Building Mechanics

#### Claiming a Building
- Players can claim one of 6 houses as their personal base
- Each house has unique pre-built advantages (see Town Districts)
- Claimed houses get a player nameplate and customizable interior

#### Fortification System
Every building has structural integrity tracked per-wall:
- **Wooden Boards** (Tier 1) — cheap, fast, low durability
- **Reinforced Planks** (Tier 2) — moderate cost and durability
- **Metal Shutters** (Tier 3) — expensive, high durability, blocks visibility
- **Storm Glass** (Tier 4) — very expensive, high durability, see-through
- **Storm Crystal Barriers** (Tier 5) — endgame, regenerates between storms

#### Storm-Specific Defenses
| Defense | Counters | Crafting Tier |
|---------|----------|---------------|
| Lightning Rods | Thunderstorms | Early |
| Sandbags | Flooding / Tsunamis | Early |
| Storm Shutters | Hurricane winds | Mid |
| Heated Floors | Hailstorm ice | Mid |
| Underground Bunker | Tornados | Mid-Late |
| Elevated Walkways | Flooding | Mid |
| Fog Horns | Fog storms (reveals creatures) | Mid |
| Storm Crystal Walls | All storm types | Late |

#### Town Restoration
Beyond personal bases, players can restore shared town buildings:
- **Repair the Blacksmith** → unlocks metal crafting
- **Repair the Clinic** → unlocks medical crafting + respawn point
- **Repair the General Store** → NPC restocks supplies
- **Repair the Tavern** → food crafting + NPC hints
- **Repair the Church** → healing aura zone + bell tower early warning
- **Repair the Dock** → boat crafting + ocean access

Each restoration costs resources and takes time but permanently improves the town for all players.

---

## 8. Crafting System

### Crafting Stations

| Station | Location | Unlocks |
|---------|----------|---------|
| **Workbench** | Starting (Harbormaster's) | Basic tools, wooden items |
| **Anvil** | Blacksmith (repair required) | Metal tools, weapons |
| **Stove** | Tavern (repair required) | Cooked food, stews |
| **Medical Table** | Clinic (repair required) | Bandages, medicine, antidotes |
| **Storm Forge** | Lighthouse (upgrade required) | Storm Crystal items |
| **Boat Workshop** | Dock (repair required) | Boats, rafts, fishing gear |
| **Witch's Cauldron** | Marshlands | Potions, enchantments |

### Resource Types

**Basic Resources (found everywhere):**
- Wood (from driftwood, broken buildings, trees)
- Stone (from rocky shore, cliff mining)
- Rope (from fishing nets, plant fiber)
- Cloth (from buildings, sail scraps)
- Scrap Metal (from wrecked cars, buildings)

**Food Resources:**
- Fish (fishing — many varieties with different effects)
- Clams/Crabs/Lobster (shore gathering)
- Berries/Herbs (foraging in marshlands)
- Eggs (seabird nests on cliffs)
- Vegetables (farming — post garden restoration)

**Advanced Resources:**
- Iron Ore (cliff mining)
- Copper Wire (scavenging electronics)
- Oil/Fuel (from the garage, sunken ship)
- Glass (from windows, sand smelting)
- Storm Crystals (dropped by The Tempest, storm creatures, Stormchaser harvest)

### Key Craftable Items

**Tools:**
- Fishing Rod → Upgraded Rod → Deep Sea Rod
- Pickaxe → Iron Pickaxe → Storm Pickaxe
- Hammer → Reinforced Hammer → Storm Hammer (repairs faster)
- Lantern → Spotlight → Fog Piercer

**Weapons:**
- Driftwood Club → Iron Sword → Storm Blade
- Slingshot → Crossbow → Storm Bow (lightning arrows)
- Harpoon → Barbed Harpoon → Storm Harpoon
- Flare Gun → Signal Cannon → Storm Cannon

**Survival:**
- Raincoat (weather resistance)
- Rubber Boots (flood immunity)
- Storm Goggles (fog visibility)
- Insulated Jacket (hail resistance)
- Lightning Vest (storm crystal — absorbs one lightning strike)

**Food/Medical:**
- Fish Stew (hunger + warmth)
- Clam Chowder (hunger + slow heal)
- Herbal Tea (fear reduction)
- Bandage → Medical Kit → Storm Salve (heals + weather cure)
- Antivenom (marsh creature poison cure)

---

## 9. Rescue Missions

Each of the 4 missing townspeople is in a different zone, requires reaching a certain storm count to access, and has a unique rescue quest.

### Rescue 1: Old Pete the Fisherman (Storm 15+)
**Location:** Marshlands — trapped in his fishing shack surrounded by Marsh Lurkers
**Quest:** Navigate the foggy marshlands, find Pete's shack, clear the Marsh Lurkers, and escort him back to town
**Challenge:** The marshlands are perpetually foggy, and Marsh Lurkers are ambush predators
**Reward:** Pete joins the town as a fishing NPC — provides daily fish supplies and teaches advanced fishing recipes
**Lore:** Pete reveals that Elara the Storm Witch was trying to protect the town with a weather ritual, but something went wrong

### Rescue 2: Marina the Biologist (Storm 30+)
**Location:** The Cliffs — trapped in the Abandoned Mine after a cave-in
**Quest:** Scale the cliffs, enter the mine, clear the cave-in, and fight off cave creatures to reach Marina
**Challenge:** The mine is dark, structurally unstable, and home to aggressive cave bats and rock elementals
**Reward:** Marina joins as a crafting NPC — unlocks advanced medical recipes and creature knowledge (taming bonuses)
**Lore:** Marina reveals that The Tempest is not evil — it's a corrupted guardian spirit. Elara's ritual was supposed to summon a protector.

### Rescue 3: Captain Briggs (Storm 50+)
**Location:** The Lighthouse Islands — shipwrecked on a remote island
**Quest:** Build/upgrade a boat capable of ocean travel, navigate to the islands, find Briggs' wrecked ship, and help him repair the Ruined Second Lighthouse
**Challenge:** Ocean travel during calm periods is tense — storms can start while you're at sea. The islands have unique dangers (giant crabs, whirlpools)
**Reward:** Briggs joins as a sailing NPC — provides boat upgrades and unlocks The Maelstrom navigation. The Second Lighthouse, once repaired, creates a second safe zone.
**Lore:** Briggs reveals that two lighthouses working together can weaken The Tempest enough to confront it directly. He also reveals Elara is alive — in The Maelstrom's eye.

### Rescue 4: Elara the Storm Witch (Storm 75+)
**Location:** The Maelstrom — trapped in the eye of the permanent ocean storm
**Quest:** Sail into The Maelstrom with both lighthouses active, navigate whirlpools and sea monsters, reach the eye, and help Elara reverse the ritual
**Challenge:** The Tempest throws everything it has at you — this is the most dangerous rescue
**Reward:** Elara breaks the curse. She joins the town and begins the final ritual. The last 24 storms are The Tempest's desperate final assault.
**Lore:** Elara explains the ritual can be reversed but it takes 24 storms of channeling — players must protect her for the final 24 storms.

### The Final Storm (Storm 99)
- Elara completes the counter-ritual
- The Tempest physically manifests as a colossal humanoid storm entity
- All players must fight it together using Storm Crystal weapons
- The town's defenses, NPCs, tamed animals, and both lighthouses all contribute
- Defeating The Tempest breaks the curse — the sun rises for the first time
- **Ending cutscene:** The town is restored, the seas are calm, the sky is clear. Credits roll showing the town rebuilding.
- **Post-game:** Players can continue in "Endless Storm" mode with randomized escalating difficulty + leaderboards

---

## 10. Exploration & Biomes

### Stormhaven (Main Town)
- **Aesthetic:** New England coastal — grey shingles, white trim, cobblestone
- **Weather during calm:** Overcast, sea breeze, gulls crying
- **Resources:** Wood, scrap metal, cloth, basic food
- **Danger level:** Low during calm, moderate during storms

### The Rocky Shore
- **Aesthetic:** Tide pools, jagged rocks, crashing waves
- **Unique mechanic:** Tide cycle — some areas only accessible at low tide
- **Resources:** Stone, shellfish, seaweed, copper deposits
- **Danger:** Rip currents, aggressive crabs, slippery surfaces

### The Marshlands (Unlock: Storm 15)
- **Aesthetic:** Foggy bayou, twisted trees, murky water
- **Unique mechanic:** Permanent fog — must use lanterns/flares
- **Resources:** Herbs, rare plants, frog legs, snake venom
- **Creatures:** Marsh Lurkers, swamp snakes, poisonous frogs
- **Special location:** Witch's Shack (unique crafting)

### The Cliffs (Unlock: Storm 30)
- **Aesthetic:** Dramatic sea cliffs, nesting seabirds, mine entrance
- **Unique mechanic:** Vertical climbing — fall damage is real
- **Resources:** Iron ore, copper, feathers, eggs, rare minerals
- **Creatures:** Cliff Eagles (tameable), Rock Elementals, Cave Bats
- **Special location:** Abandoned Mine (deep resource node)

### The Lighthouse Islands (Unlock: Storm 50)
- **Aesthetic:** Small rocky islands, each with a unique feature
- **Unique mechanic:** Requires boat — ocean travel between islands
- **Islands:**
  - **Crab Island** — giant crab territory, chitin for armor
  - **Coral Island** — underwater cave, rare coral resources
  - **Lighthouse Island** — the Ruined Second Lighthouse
  - **Treasure Island** — buried pirate loot, trapped
- **Creatures:** Giant Crabs, Sea Turtles (tameable), Reef Sharks

### The Maelstrom (Unlock: Storm 75)
- **Aesthetic:** Dark churning ocean, lightning-lit chaos, debris fields
- **Unique mechanic:** Boat health constantly drains, must keep repairing
- **Resources:** Storm Crystals (abundant), Abyssal materials
- **Creatures:** Leviathan tentacles, Storm Sharks, Lightning Eels
- **Special location:** The Eye — where Elara is trapped

---

## 11. Creatures & Taming

### Hostile Creatures

**Storm Creatures (appear during storms):**
| Creature | Storm Type | Behavior |
|----------|-----------|----------|
| Thunder Crabs | Thunderstorm | Electrified swarm, shocking melee |
| Wind Wraiths | Hurricane | Float on wind, divebomb players |
| Fog Phantoms | Fog Storm | Silent stalkers, appear behind you |
| Frost Wolves | Hailstorm | Pack hunters, freeze bite |
| Storm Elementals | Tornado | Swirling debris, AOE damage |
| Tide Horrors | Tsunami | Deep-sea nightmares, emerge from water |
| Possessed Objects | Any storm | The Tempest animates town objects |

**Zone Creatures (always present in their zones):**
| Creature | Zone | Behavior |
|----------|------|----------|
| Marsh Lurkers | Marshlands | Ambush predator, pulls players underwater |
| Swamp Snakes | Marshlands | Venomous, hides in tall grass |
| Rock Elementals | Cliffs/Mine | Slow, heavy hitters, guard ore deposits |
| Cave Bats | Mine | Swarm in darkness, flee from light |
| Giant Crabs | Lighthouse Islands | Territorial, pinch stun |
| Reef Sharks | Ocean | Patrol waters, attack boats |

### Tameable Creatures

| Creature | Location | Taming Method | Benefit |
|----------|----------|---------------|---------|
| Seagull | Town | Bread crumbs | Scout — reveals map areas |
| Crab | Rocky Shore | Fish bait | Gatherer — auto-collects shellfish |
| Dog | Town (stray) | Meat + patience | Companion — warns of creatures, fights |
| Cat | Town (stray) | Fish + patience | Mouser — reduces pest damage to food stores |
| Cliff Eagle | Cliffs | Raw meat at nest | Air scout — reveals storm type early |
| Sea Turtle | Islands | Seaweed | Ocean mount — safe water travel |
| Dolphin | Ocean | Fish from boat | Ocean escort — scouts underwater, fights sharks |
| Storm Hawk | The Maelstrom | Storm Crystal bait | Combat pet — lightning attacks |

**Taming Mechanic:** Craft a **Whistle** (basic tool) to begin taming. Approach creatures slowly, offer their preferred food, and wait. Higher-level creatures require upgraded whistles and multiple feeding sessions. The Keeper class has taming bonuses.

---

## 12. Progression & Difficulty Scaling

### Storm Milestones

| Storm # | Event | Unlock |
|---------|-------|--------|
| 1 | Tutorial Storm | Basic mechanics introduction |
| 5 | Fog storms begin | Lantern crafting available |
| 10 | Hurricane storms begin | Metal crafting unlocked |
| 15 | Marshlands accessible | Witch's Shack, Old Pete rescue |
| 20 | Hailstorms begin | Insulated gear crafting |
| 25 | **BOSS: Tempest's Wrath #1** | Storm Crystal crafting unlocked |
| 30 | Cliffs accessible | Mine, Marina rescue |
| 35 | Tornado storms begin | Underground bunker crafting |
| 45 | Tsunami storms begin | Advanced boat crafting |
| 50 | **BOSS: Tempest's Wrath #2** | Lighthouse Islands, Captain Briggs rescue |
| 60 | Blood storms begin | Storm Crystal weapons |
| 75 | **BOSS: Tempest's Wrath #3** | The Maelstrom, Elara rescue |
| 76–98 | Elara's counter-ritual | Defend Elara, escalating storms |
| 99 | **FINAL BOSS: The Tempest** | Win condition |

### Difficulty Modifiers (Multiplayer Scaling)
| Players | Creature HP | Creature Count | Storm Duration | Resource Spawns |
|---------|-------------|----------------|----------------|-----------------|
| 1 | 100% | 100% | 100% | 100% |
| 2 | 130% | 120% | 100% | 115% |
| 3 | 160% | 150% | 110% | 130% |
| 4 | 200% | 180% | 110% | 150% |
| 5 | 250% | 200% | 120% | 170% |

### Fear / Morale System
Instead of a sanity meter, 99 Storms uses a **Morale** system:
- Morale drops during storms (faster with worse storms)
- Morale drops when buildings are destroyed, teammates go down, or the lighthouse flickers
- Morale increases during calm periods, when eating cooked food, sitting by fires, playing the jukebox in the tavern, petting tamed animals
- Low morale = slower movement, reduced crafting speed, screen desaturation
- Zero morale = "Panic" state — controls become inverted for 10 seconds, screen shakes

---

## 13. Multiplayer & Social Systems

### Co-op Structure
- **Party Size:** 1–5 players
- **Matchmaking:** Private lobbies (invite code) or public matchmaking
- **Difficulty:** Scales with player count (see above)
- **Shared Progress:** Town restorations and rescues persist for the session
- **Individual Progress:** Each player keeps their class, personal chest, and tamed creatures

### Social Features
- **Proximity Voice Chat** — hear nearby players, wind distorts voice during storms
- **Emote Wheel** — wave, point, thumbs up, panic, celebrate
- **Photo Mode** — pause and frame screenshots (town builds, storm moments, group poses)
- **Town Board** — post messages, coordinate strategies, leave notes
- **Jukebox** — play music in the tavern, boosts morale for everyone nearby
- **Cooking Together** — multiple players at the stove cook a "feast" that gives team buffs

### Cooperative Mechanics
- **Shared Building** — anyone can contribute to town restoration
- **Buddy Rescue** — downed players can be revived by teammates
- **Resource Sharing** — community chest in Town Hall for shared resources
- **Signal Flares** — craftable item that marks your location for teammates
- **Division of Labor** — classes are designed so a balanced team (Captain + Builder + Keeper + Stormchaser) covers all needs

---

## 14. Monetization

### Philosophy
**Fair and generous.** All core content is free. Paid content is convenience, cosmetic, or alternative playstyles. Never pay-to-win.

### Revenue Streams

#### Class Gamepasses (One-Time Purchase)
| Class | Price | Justification |
|-------|-------|---------------|
| Captain | 349 Robux | Alternative playstyle |
| Builder | 349 Robux | Alternative playstyle |
| Keeper | 349 Robux | Alternative playstyle |
| Stormchaser | 499 Robux | Premium playstyle, most dramatic |

#### Storm Pass (Seasonal — 30 days)
- 449 Robux per season
- 30 tiers of cosmetic rewards
- Exclusive weather effects for player (rainbow aura, sparkle rain)
- Exclusive building skins (neon shutters, crystal walls)
- Exclusive weapon skins (lightning effects, ocean glow)
- XP boost for pass progression (NOT gameplay advantage)

#### Cosmetic Shop (Rotating Daily)
- **Character Skins:** Raincoat colors, hat styles, boots, goggles
- **Building Skins:** Different wall textures, roof styles, door designs
- **Weapon Skins:** Visual effects on weapons (no stat changes)
- **Pet Skins:** Costumes for tamed animals (tiny raincoat for dog, pirate hat for seagull)
- **Emotes:** Unique animations (umbrella spin, lightning dance)
- Price range: 49–199 Robux per item

#### Premium Currency: Storm Coins
- Purchased with Robux (100 Storm Coins = 99 Robux)
- Used ONLY in the cosmetic shop
- Can also be earned slowly through gameplay (daily challenges, storm milestones)
- Never used for gameplay advantages

#### Donation Board
- In-game donation board in Town Hall
- Players can donate Robux to the "Town Fund"
- Donators get a plaque on the board with their name
- Cosmetic-only recognition — no gameplay benefits

---

## 15. Content Creator Features

### Why 99 Storms Is Built for Content

1. **Weather destruction is visually spectacular** — tornado ripping through town, tsunami flooding streets, lightning striking buildings = cinematic footage every single storm

2. **Jump scares from Fog Phantoms** — appearing behind players in zero visibility = reaction content gold

3. **The Tempest's face in the sky** — terrifying visual that's instantly recognizable in thumbnails

4. **Town before/after** — showing a destroyed town vs. a fully restored one = satisfying transformation content

5. **Boss storms every 25 levels** — natural "episode" structure for YouTube series

6. **Storm variety** — every session looks different because storm types are randomized

7. **The rescue quests** — each one is a self-contained adventure with a climax

8. **Class showcases** — "I played as Stormchaser for 99 Storms" = video concept

9. **Co-op chaos** — 5 players panicking during a tornado = hilarious group content

10. **The final boss** — The Tempest manifesting as a colossal storm entity = epic finale content

### Built-In Creator Tools
- **Photo Mode** — pause, free camera, filters, frames
- **Replay System** — rewatch the last storm from multiple angles
- **Storm Log** — records stats (storms survived, buildings destroyed, creatures defeated) for end-of-session summaries
- **Cinematic Camera** — slow-motion toggle during boss storms
- **Screenshot Sharing** — export to Roblox feed with game watermark

---

## 16. Update Roadmap

### Pre-Launch
- Core survival loop (storms, building, crafting)
- Harbor District + Main Street
- Thunderstorm + Fog Storm + Hurricane
- Weatherman class (free)
- 2 tameable creatures (Dog, Seagull)
- Storms 1–25 progression

### Launch (Week 1)
- Full game: Storms 1–99
- All 5 classes
- All 4 rescue missions
- All storm types
- All zones (Marshlands, Cliffs, Islands, Maelstrom)
- 8 tameable creatures
- Storm Pass Season 1

### Week 2 Update — "The Deep"
- Underwater exploration expansion (diving gear)
- New craftable: Diving Suit, Underwater Lantern
- New zone: Sunken Village (submerged section of old Stormhaven)
- New creature: Anglerfish (tameable underwater scout)

### Week 3 Update — "The Festival"
- Limited-time event: Storm Festival
- NPC carnival setup in town during calm periods
- Mini-games: Ring toss, strength test, fishing contest
- Exclusive festival cosmetics
- Festival food recipes with unique buffs

### Week 4 Update — "The Lighthouse Keeper's Journal"
- Lore expansion: find journal pages throughout the world
- Each page reveals backstory of Stormhaven and The Tempest
- Completing the journal unlocks a secret boss encounter
- New crafting recipes hidden in journal entries

### Month 2+ — Ongoing
- New storm types (acid rain, meteor shower, sandstorm)
- New zones (forest inland, mountain peak)
- New classes (Marine, Inventor)
- Seasonal events (Halloween haunted storms, Winter frost storms)
- Community-voted features
- Competitive mode: "Storm Speedrun" — fastest 99-storm completion leaderboard

---

## 17. Technical Requirements

### Roblox Studio Setup
- **Framework:** Rojo for file syncing (Roblox Studio ↔ VS Code)
- **Language:** Luau (Roblox's Lua variant)
- **Architecture:** Client-Server with RemoteEvents/RemoteFunctions
- **Data Storage:** Roblox DataStoreService for player progression
- **Networking:** Optimized for 5-player sessions with weather particle effects

### Performance Targets
- **Target FPS:** 60 FPS on mid-range devices
- **Max Part Count:** <50,000 active parts at any time
- **Weather Effects:** Particle-based with LOD scaling
- **Draw Distance:** Dynamic based on storm type (reduced in fog/rain)
- **Memory Budget:** <500MB client-side

### Key Technical Systems
1. **Storm Generation System** — weighted random selection + intensity scaling
2. **Structural Integrity System** — per-wall HP tracking for all buildings
3. **Dynamic Weather Renderer** — rain, fog, wind, lightning, hail particle systems
4. **AI Director** — manages creature spawning, The Tempest behavior, difficulty pacing
5. **Tidal System** — water level changes for shore/flood mechanics
6. **Building Placement System** — snap-based fortification with validation
7. **NPC Management System** — townspeople AI, trading, task assignment
8. **Progression Manager** — storm count, milestones, unlocks, save/load

### Project Structure
```
src/
├── client/           -- Client-side scripts
│   ├── UI/           -- All GUI elements
│   ├── Weather/      -- Weather visual effects
│   ├── Camera/       -- Camera systems (photo mode, cinematic)
│   └── Input/        -- Player input handling
├── server/           -- Server-side scripts
│   ├── Storm/        -- Storm generation & management
│   ├── Building/     -- Structure placement & integrity
│   ├── Creatures/    -- AI, spawning, taming
│   ├── Crafting/     -- Recipe management & validation
│   ├── Progression/  -- Save/load, milestones, unlocks
│   ├── NPCs/         -- Townspeople AI & trading
│   └── Multiplayer/  -- Session management, scaling
├── shared/           -- Shared modules (client & server)
│   ├── Config/       -- Game constants, balance numbers
│   ├── Types/        -- Type definitions
│   └── Utils/        -- Shared utility functions
└── assets/           -- Referenced asset IDs and metadata
```

---

*This document is the foundation for 99 Storms. Each section can be expanded into detailed implementation specs as development progresses.*
