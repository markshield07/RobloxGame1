# 99 Storms — Map & Level Design Document

## Overview

Stormhaven is a cursed coastal town on a rocky peninsula. The map is designed with **concentric danger zones** — the town center (lighthouse) is safest, and danger increases as players move outward toward unexplored zones. The total playable area is approximately **2048 x 2048 studs** at launch, expanding to **4096 x 4096** with all zones unlocked.

---

## Map Layout (Bird's Eye View)

```
                    N
                    |
    ┌───────────────┼───────────────┐
    │           THE CLIFFS          │
    │        (Unlock: Storm 30)     │
    │    ┌──────────────────┐       │
    │    │  Abandoned Mine  │       │
    │    └──────────────────┘       │
    │          Cliff Face           │
    ├───────────────────────────────┤
    │                               │
    │   ┌─────────┐  RESIDENTIAL    │
    │   │ Church  │    HILL         │
    │   └─────────┘                 │
    │  ┌──────┐  ┌──────────────┐   │
    │  │Houses│  │  MAIN STREET │   │
W ──┤  └──────┘  │  Blacksmith  │   ├── E
    │            │  Gen. Store  │   │
    │   ★ LIGHTHOUSE  │  Tavern    │   │
    │   (Central Hub) │  Clinic    │   │
    │            └──────────────┘   │
    │                               │
    │   ┌──────────────────────┐    │
    │   │   HARBOR DISTRICT    │    │
    │   │  Pier · Fish Market  │    │
    │   │  Boathouse · Dock    │    │
    │   └──────────┬───────────┘    │
    │              │                │
    ├──────────────┼────────────────┤
    │     Rocky Shore · Beach       │
    │     Sea Caves · Tidal Flats   │
    │         Shipwreck Cove        │
    ├──────────────┼────────────────┤
    │              │                │
    │     ═══ OCEAN ════            │
    │                               │
    │  🏝 Lighthouse    🏝 Coral    │
    │     Islands         Island    │
    │  (Unlock: Storm 50)           │
    │                               │
    │  🏝 Crab        🏝 Treasure  │
    │     Island         Island     │
    │                               │
    │     ═══ DEEP OCEAN ════       │
    │                               │
    │      🌀 THE MAELSTROM 🌀      │
    │      (Unlock: Storm 75)       │
    │                               │
    └───────────────────────────────┘
                    |
                    S

    ← THE MARSHLANDS (West, Unlock: Storm 15)
      Foggy wetlands, Witch's Shack, Old Pete
```

---

## District Details

### 1. The Lighthouse (Central Hub)

**Elevation:** Highest point in town (60 studs above sea level)
**Dimensions:** 30 x 30 stud platform

```
         ┌─────┐
         │LIGHT│  ← Beacon (top floor)
         │HOUSE│  ← Telescope (2nd floor)
         │     │  ← Storm Forge (1st floor)
    ┌────┴─────┴────┐
    │  Lighthouse    │  ← Fuel storage (ground)
    │  Plateau       │  ← Storm Log terminal
    │                │  ← Community campfire
    └────────────────┘
         Cliff edge
```

**Key Features:**
- The lighthouse beam rotates 360° and defines the safe zone radius
- Storm Forge crafting station (unlocked with lighthouse upgrade)
- Storm Log terminal — tracks all storm history, patterns, and stats
- Telescope — lets players scout approaching storms and see farther
- Community campfire — morale boost zone, cooking spot
- Fuel storage — where players deposit lighthouse fuel

**Design Notes:**
- Path from town to lighthouse is a winding cliffside trail with handrails
- During storms, the path becomes dangerous (wind push, slippery)
- The lighthouse interior is cozy — warm lighting, wooden floors, maps on walls
- The beacon light visually sweeps across the town during storms

---

### 2. Harbor District (Starting Area)

**Elevation:** Sea level (0-5 studs)
**Dimensions:** 200 x 150 studs
**Flood Risk:** HIGH (first area to flood during tsunamis)

```
    ┌──────────────────────────────────────┐
    │                                      │
    │  ┌──────────┐    ┌──────────────┐    │
    │  │Harborma- │    │  Fish Market  │    │
    │  │ster's    │    │  (NPC Shop)   │    │
    │  │Office    │    └──────────────┘    │
    │  │(Quest    │                        │
    │  │ Board)   │    ┌──────────────┐    │
    │  └──────────┘    │  Boathouse   │    │
    │                  │  (Boat       │    │
    │                  │   Storage)   │    │
    │                  └──────┬───────┘    │
    │                         │            │
    ├─────────────────────────┼────────────┤
    │▓▓▓▓▓▓▓▓▓ THE PIER ▓▓▓▓▓│▓▓▓▓▓▓▓▓▓▓▓│
    │▓  Fishing spots (3)     │  Dock     ▓│
    │▓  Lobster traps         │  (boats)  ▓│
    │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
    │                                      │
    │  ~~~ WATER LINE ~~~                  │
    └──────────────────────────────────────┘
```

**Key Features:**
- **The Pier** extends 80 studs into the water with 3 fishing spots
- **Fish Market** — NPC trader who buys fish and sells basic supplies
- **Harbormaster's Office** — quest board, world map, storm log excerpt
- **Boathouse** — boat storage, basic repair bench
- **Dock** — where player boats are moored, departure point for ocean travel
- Lobster traps along the pier (daily resource generation)
- Starting resource crates scattered around (tutorial resources)

**Design Notes:**
- This is the first area players see — it should feel inviting but slightly eerie
- Abandoned fishing nets, overturned boats, scattered supplies tell the story
- The pier creaks and sways during storms — atmospheric sound design
- During tsunamis, this entire district floods — players MUST evacuate uphill

---

### 3. Main Street

**Elevation:** 10-15 studs above sea level
**Dimensions:** 250 x 100 studs
**Flood Risk:** MODERATE (floods in severe tsunamis only)

```
    ┌─────────────────────────────────────────┐
    │                                         │
    │  COBBLESTONE ROAD (Main Street)         │
    │  ════════════════════════════════        │
    │                                         │
    │  ┌────────┐ ┌────────┐ ┌────────────┐   │
    │  │General │ │Black-  │ │  Town Hall  │   │
    │  │Store   │ │smith   │ │  (Community │   │
    │  │(NPC)   │ │(Anvil) │ │   Chest)    │   │
    │  └────────┘ └────────┘ └────────────┘   │
    │                                         │
    │  ┌────────┐ ┌────────┐ ┌────────────┐   │
    │  │Tavern  │ │Clinic  │ │  Garage     │   │
    │  │(Stove, │ │(Medical│ │  (Vehicle   │   │
    │  │Jukebox)│ │ Table) │ │   Parts)    │   │
    │  └────────┘ └────────┘ └────────────┘   │
    │                                         │
    │  Street lamps (light sources at night)  │
    │  Benches, planters, mailboxes           │
    └─────────────────────────────────────────┘
```

**Key Features:**
- **General Store** — NPC shop, basic supplies, rotating inventory
- **Blacksmith** — Anvil crafting station (requires restoration: 20 wood, 15 stone, 10 iron)
- **Town Hall** — Community chest for shared resources, town upgrade board, donation board
- **Tavern** — Stove crafting station, jukebox (morale boost), NPC rumors
- **Clinic** — Medical Table crafting station, respawn point, healing zone
- **Garage** — fuel cans, scrap metal, vehicle parts for boat upgrades
- Street lamps that players can repair for nighttime visibility

**Design Notes:**
- Main Street is the "cozy core" — this should feel like a real small town
- Each building has unique interior decoration and ambient sounds
- Buildings start partially damaged — windows broken, doors hanging
- Restoring buildings transforms them visually (boarded windows → glass, debris cleared)
- The cobblestone road has puddles that reflect lightning during storms

---

### 4. Residential Hill

**Elevation:** 20-40 studs above sea level
**Dimensions:** 300 x 200 studs
**Flood Risk:** LOW

```
    ┌──────────────────────────────────────────┐
    │                                          │
    │      ┌──────────┐                        │
    │      │Watchtower│  (Tallest building)     │
    │      │ House    │  Radio antenna          │
    │      └──────────┘                        │
    │                                          │
    │  ┌──────────┐  ┌──────────┐              │
    │  │ Workshop │  │  Garden  │              │
    │  │  House   │  │  House   │  Farm plots  │
    │  └──────────┘  └──────────┘              │
    │                                          │
    │  ┌──────────┐  ┌──────────┐              │
    │  │  Cliff   │  │  Cellar  │              │
    │  │  House   │  │  House   │              │
    │  └──────────┘  └──────────┘              │
    │                                          │
    │  ┌────────────┐  ┌───────────────┐       │
    │  │  Seaside   │  │   Church      │       │
    │  │  Cottage   │  │   + Graveyard │       │
    │  └────────────┘  └───────────────┘       │
    │                                          │
    │  Winding paths, picket fences, gardens   │
    └──────────────────────────────────────────┘
```

**Claimable Houses:**

| House | Elevation | Advantage | Vulnerability | Interior |
|-------|-----------|-----------|---------------|----------|
| Cliff House | 40 studs | Best visibility, high ground | Extreme wind exposure | Open floor plan, large windows |
| Cellar House | 20 studs (+ underground) | Underground shelter, flood-proof | Can cave in during earthquakes | Cozy basement, root cellar |
| Garden House | 25 studs | 4 farming plots, greenhouse frame | Exposed garden destroyed in hurricanes | Rustic kitchen, seed storage |
| Watchtower House | 35 studs + 15 tower | Radio antenna (comms), tallest | Lightning magnet | Narrow, vertical, radio room at top |
| Workshop House | 25 studs | Pre-built workbench + anvil | Fire risk from indoor forge | Workshop floor, tool racks |
| Seaside Cottage | 8 studs | Private dock, fishing bonus | First residential to flood | Nautical decor, boat-themed |

**Church:**
- Healing aura in a 20-stud radius when restored
- Bell tower provides 45-second storm early warning (vs. standard 60s siren)
- Graveyard behind church — ghost encounters at night, rare ectoplasm drops
- Stained glass windows glow during storms (visual landmark)

---

### 5. The Rocky Shore

**Elevation:** 0-5 studs (sea level, tidal variation)
**Dimensions:** 400 x 100 studs (wraps around the peninsula)
**Flood Risk:** EXTREME

```
    ═══════════════════════════════════════
    ROCKY SHORE (wraps around town perimeter)
    ═══════════════════════════════════════

    Section A: Tide Pools (East)
    ┌─────────────────────────┐
    │  🪨 🪨  ○ ○  🪨 🪨      │  ○ = tide pools
    │     ○  🪨  ○     🪨     │  🪨 = rocks
    │  🪨    ○  🪨  ○  🪨     │  Resources: shellfish,
    │                         │  seaweed, copper
    └─────────────────────────┘

    Section B: Sandy Beach (South)
    ┌─────────────────────────┐
    │  ～～～～～～～～～～～～～ │  Driftwood, turtle nests
    │  . . . . . . . . . . . │  Buried treasure (random)
    │  Sand  Sand  Sand  Sand │  Crab spawns
    └─────────────────────────┘

    Section C: Sea Caves (Southwest)
    ┌─────────────────────────┐
    │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
    │  ▓  Cave Entrance    ▓  │  Accessible at LOW TIDE only
    │  ▓  (floods at high  ▓  │  Rare minerals, crab shells
    │  ▓   tide!)          ▓  │  Danger: drowning if tide rises
    │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
    └─────────────────────────┘

    Section D: Shipwreck Cove (West)
    ┌─────────────────────────┐
    │     ⛵ (half-sunken     │  Scrap metal, rope, cloth
    │        ship)            │  Waterlogged crates
    │  Scattered debris       │  Advanced resources at depth
    │  Underwater exploration │  Reef sharks patrol
    └─────────────────────────┘
```

**Tidal Mechanic:**
- Water level oscillates on a 4-minute cycle during calm periods
- Low tide: sea caves accessible, tide pools exposed, more beach area
- High tide: caves flood (deadly), beach shrinks, shore creatures spawn
- During tsunamis: EVERYTHING floods up to 10+ studs above normal

---

### 6. The Marshlands (Unlock: Storm 15)

**Elevation:** -2 to 3 studs (below sea level in places)
**Dimensions:** 400 x 300 studs
**Access:** West path from Residential Hill
**Atmosphere:** Perpetual fog, murky water, twisted dead trees

```
    ┌──────────────────────────────────────────┐
    │  ░░░░░░░░ FOG ░░░░░░░░░░░░░░░░░░░░░    │
    │                                          │
    │  ～water～  🌿  ～water～  🌿  ～water～  │
    │                                          │
    │  Boardwalk paths (safe to walk on)       │
    │  ═══════╗                                │
    │         ║   ┌──────────────┐             │
    │         ╠═══│ Witch's Shack│             │
    │         ║   │ (Special     │             │
    │         ║   │  Crafting)   │             │
    │         ║   └──────────────┘             │
    │         ║                                │
    │         ╠═══ Pete's Fishing Shack        │
    │         ║    (Rescue Mission #1)         │
    │         ║                                │
    │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    │
    │                                          │
    │  🐍 Snake spawns in tall grass           │
    │  🐸 Frogs near water edges               │
    │  👁 Marsh Lurkers in deep water           │
    └──────────────────────────────────────────┘
```

**Key Features:**
- **Perpetual fog** — visibility is always reduced here (10-15 studs)
- **Boardwalk paths** — safe wooden walkways through the swamp
- **Deep water** — stepping off the boardwalk into water risks Marsh Lurker ambush
- **Witch's Shack** — unique crafting station (Witch's Cauldron) for potions
- **Pete's Fishing Shack** — Rescue Mission #1 location
- **Herb gathering** — rare herbs grow only here
- **Frog/snake spawns** — frog legs and snake venom for crafting

**Design Notes:**
- Sound design is critical — frogs croaking, water dripping, distant splashes
- Lantern/flare usage is essential — can't navigate without light
- The boardwalk occasionally has broken sections — players must jump or repair
- Fireflies provide faint ambient light (visual only, not functional)

---

### 7. The Cliffs (Unlock: Storm 30)

**Elevation:** 40-80 studs above sea level
**Dimensions:** 300 x 250 studs
**Access:** North path from Residential Hill (steep climb)

```
    ┌──────────────────────────────────────────┐
    │  CLIFF TOP (80 studs)                    │
    │  ┌──────────────────────────────┐        │
    │  │     Seabird Nesting Area     │        │
    │  │     (Feathers, Eggs)         │        │
    │  │     Cliff Eagle Nest ← Tame  │        │
    │  └──────────────────────────────┘        │
    │                                          │
    │  CLIFF FACE (40-80 studs)                │
    │  ╔══════════════════════════════╗        │
    │  ║  Climbing Routes (3)        ║        │
    │  ║  · Beginner (wide ledges)   ║        │
    │  ║  · Intermediate (rope req)  ║        │
    │  ║  · Expert (pickaxe req)     ║        │
    │  ║                             ║        │
    │  ║  Ore deposits on cliff face ║        │
    │  ║  Iron / Copper / Rare       ║        │
    │  ╚══════════════════════════════╝        │
    │                                          │
    │  MINE ENTRANCE (50 studs)                │
    │  ┌──────────────────────────────┐        │
    │  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │        │
    │  │ ▓  Abandoned Mine          ▓ │        │
    │  │ ▓  Level 1: Iron Veins     ▓ │        │
    │  │ ▓  Level 2: Copper Veins   ▓ │        │
    │  │ ▓  Level 3: Crystal Cave   ▓ │ ← Marina│
    │  │ ▓  (Cave Bats + Rock Elem) ▓ │        │
    │  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │        │
    │  └──────────────────────────────┘        │
    └──────────────────────────────────────────┘
```

**Key Features:**
- **Climbing mechanic** — players scale cliff face using ledges, ropes, and pickaxes
- **3 climbing routes** of increasing difficulty with better ore deposits
- **Seabird nesting area** — feathers (crafting), eggs (food), Cliff Eagle (taming)
- **Abandoned Mine** — 3 levels deep, progressively more dangerous
  - Level 1: Iron veins, cave bats (flee from light)
  - Level 2: Copper veins, more bats, some rock elementals
  - Level 3: Crystal cave (rare minerals), Rock Elementals, Marina's rescue location
- **Fall damage** is a real threat — falling from cliff face = major damage or death

---

### 8. The Lighthouse Islands (Unlock: Storm 50)

**Dimensions:** 600 x 600 stud ocean zone with 4 islands
**Access:** Boat required (rowboat minimum, sailboat recommended)

```
    ┌──────────────────────────────────────────┐
    │                                          │
    │  ～～～ OPEN OCEAN ～～～                  │
    │                                          │
    │     🏝 Crab Island         🏝 Coral     │
    │     (50x50 studs)          Island       │
    │     Giant crabs            (40x40)      │
    │     Chitin armor           Underwater   │
    │     resources              cave, coral  │
    │                            resources    │
    │                                          │
    │         🏝 Lighthouse Island            │
    │         (80x80 studs)                   │
    │         Ruined Second Lighthouse        │
    │         Captain Briggs (Rescue #3)      │
    │         Strategic high ground            │
    │                                          │
    │                  🏝 Treasure Island      │
    │                  (30x30 studs)           │
    │                  Buried pirate loot      │
    │                  Trapped/guarded         │
    │                                          │
    │  ～～～～～～～～～～～～～～～～～～～～    │
    │        🦈 Reef Sharks patrol             │
    │        🐢 Sea Turtles (tameable)        │
    └──────────────────────────────────────────┘
```

**Island Details:**

**Crab Island:**
- Dominated by Giant Crabs — territorial, stun attack
- Chitin drops for crafting crab armor (high durability, slow)
- Central resource node with iron + rare minerals
- Small campfire spot for temporary safe zone

**Coral Island:**
- Mostly underwater exploration — diving mechanic
- Coral resources for advanced crafting
- Underwater cave with air pockets — rare loot
- Sea Turtle spawns (tameable ocean mount)

**Lighthouse Island:**
- Largest island, has the Ruined Second Lighthouse
- Captain Briggs' wrecked ship on the north shore
- Requires significant resources to repair the lighthouse
- Once repaired, creates a second safe zone covering the ocean area

**Treasure Island:**
- Smallest island, appears simple
- Buried treasure requires shovel (craftable)
- Guarded by traps and a mini-boss (Cursed Pirate ghost)
- Contains unique legendary weapon and Storm Crystal cache

---

### 9. The Maelstrom (Unlock: Storm 75)

**Dimensions:** 400 x 400 stud ocean zone
**Access:** Storm Vessel required, both lighthouses must be active
**Atmosphere:** Dark churning waters, constant lightning, debris fields

```
    ┌──────────────────────────────────────────┐
    │                                          │
    │  ⚡ ～～ CHURNING OCEAN ～～ ⚡          │
    │                                          │
    │     🌀 Whirlpool         ⚡              │
    │     (Avoid or be                         │
    │      pulled under)    Debris Field       │
    │                       (Resources but     │
    │  ⚡                    dangerous)         │
    │                                          │
    │         🌀 Whirlpool                     │
    │                                          │
    │     ┌─────────────────────┐              │
    │     │                     │              │
    │     │    THE EYE          │ ← Calm center│
    │     │    (100x100 studs)  │              │
    │     │                     │              │
    │     │  Elara's Prison     │ ← Rescue #4 │
    │     │  Ritual Circle      │              │
    │     │  Storm Crystal      │              │
    │     │  Deposits           │              │
    │     │                     │              │
    │     └─────────────────────┘              │
    │                                          │
    │  🐙 Leviathan tentacles                  │
    │  ⚡ Lightning Eels                       │
    │  🦈 Storm Sharks                         │
    └──────────────────────────────────────────┘
```

**Key Features:**
- **Navigation challenge** — whirlpools pull boats off course, must steer around
- **Boat HP drain** — constant storm damage to vessel, must keep repairing
- **Debris fields** — floating wreckage has resources but also hides creatures
- **The Eye** — calm center of the maelstrom, where Elara is imprisoned
- **Leviathan** — massive tentacles emerge from water, must be avoided or fought
- **The Tempest is visible here** — its face fills the entire sky, watching

---

## Elevation Map Summary

```
80 studs ─── Cliff Top (seabird nests)
70 studs ─── Upper Cliffs
60 studs ─── ★ LIGHTHOUSE (central hub)
50 studs ─── Mine Entrance
40 studs ─── Cliff House, Lower Cliffs
35 studs ─── Watchtower House
25 studs ─── Workshop/Garden/Cellar Houses
20 studs ─── Church, Residential Hill
15 studs ─── Main Street
10 studs ─── Upper Harbor
 8 studs ─── Seaside Cottage
 5 studs ─── Pier, Beach
 0 studs ─── SEA LEVEL (Rocky Shore, Tide Pools)
-2 studs ─── Marshlands (below sea level in places)

FLOOD ZONES:
  Tsunami Minor (Storm 45-60): Floods to 8 studs → Harbor + Seaside Cottage
  Tsunami Major (Storm 60-75): Floods to 15 studs → + Main Street
  Tsunami Extreme (Storm 75+): Floods to 20 studs → + Residential Hill base
```

---

## Lighting & Atmosphere by Area

| Area | Ambient Light | Fog | Sound Profile |
|------|--------------|-----|---------------|
| Lighthouse | Warm orange glow | None | Wind, beacon hum, fire crackle |
| Harbor | Cool blue-grey | Light sea mist | Waves, seagulls, creaking wood |
| Main Street | Warm streetlamp pools | None | Wind chimes, distant waves |
| Residential | Soft warm from windows | None | Birds, rustling leaves, wind |
| Rocky Shore | Natural daylight | Sea spray | Crashing waves, crab clicks |
| Marshlands | Dim green-grey | HEAVY | Frogs, dripping, squelching |
| Cliffs | Bright, exposed | Wind-blown | Seabirds, howling wind, echoes |
| Islands | Tropical bright | None | Ocean, tropical birds |
| Maelstrom | Dark purple-blue | Storm clouds | Thunder, roaring waves, Tempest voice |

---

## Resource Distribution

| Resource | Primary Location | Secondary Location |
|----------|-----------------|-------------------|
| Wood | Harbor (driftwood), Residential (trees) | Marshlands (dead trees) |
| Stone | Rocky Shore, Cliffs | Harbor (cobblestone) |
| Rope | Harbor (fishing nets), Cliffs (vines) | Marshlands (fiber) |
| Cloth | Main Street (buildings), Harbor (sails) | Residential (curtains) |
| Scrap Metal | Main Street (buildings), Garage | Harbor (ships) |
| Iron Ore | Cliffs (mine), Rocky Shore (deposits) | — |
| Copper Wire | Main Street (electronics), Garage | Cliffs (mine L2) |
| Glass | Main Street (windows), Rocky Shore (sand) | — |
| Oil/Fuel | Garage, Harbor (ship fuel) | Shipwreck Cove |
| Storm Crystals | Lighthouse (forge), Stormchaser harvest | Maelstrom (abundant) |
| Herbs | Marshlands (primary) | Garden House (farmed) |
| Fish | Harbor Pier, Rocky Shore | Islands (deep sea) |
| Shellfish | Rocky Shore (tide pools) | Islands (coral) |
| Feathers | Cliffs (seabird nests) | — |
| Rare Minerals | Cliffs (mine L3) | Islands (coral cave) |

---

## Spawn Points & Safe Zones

**Player Spawn:** Harbormaster's Office (Harbor District)
**Respawn Points:**
1. Harbormaster's Office (default)
2. Claimed House bed (if bed crafted)
3. Clinic (if restored)
4. Second Lighthouse (if repaired, Storm 50+)

**Safe Zones (during storms):**
1. Lighthouse beam radius (scales with level)
2. Church healing aura (if restored)
3. Portable Beacons (Keeper class craft)
4. Captain's boat anchor (Captain class ability)
5. Underground bunkers (Builder class craft)
6. Second Lighthouse (if repaired)
