# Basic Combat

A configurable combat script for the MemoryError (RS3). Pick which
NPCs to fight and in what order, auto-loot drops, and keep your HP, prayer and
buffs topped up — all from a single ImGui window.

**Author:** Spectre011 · **Discord:** not_spectre011

---

## Features

- **Targeting** — build a list of NPCs to kill, with three modes:
  - **List order** — nearest NPC of the topmost listed name that is around
  - **Closest** — nearest NPC matching any listed name
  - **Random** — nearest NPC of a randomly picked listed name

  In every mode, anything already attacking you is dealt with first.
- **NPC scanner** — one click fills a dropdown with the NPCs around you, so you
  never have to type names.
- **Strykewyrms** — add the wyrm itself and the script investigates the matching
  mound to spawn it. Mound types are told apart by id, so it won't spawn the
  wrong one.
- **Looting** — add ground loot by item id; it only loots between fights.
- **Sustain** — Excalibur, food, Elven Shard and prayer potions, each with a
  toggle and adjustable trigger percentages.
- **Buff upkeep** — tick the buffs to maintain: overloads, aggression, weapon
  poison, luck potions, aspects, powders and every incense stick.
- **Support mode** — with an empty target list the script attacks nothing and
  just buffs, loots and heals.
- **Housekeeping** — anti-idle, auto retaliate forced on while hunting (and
  restored on exit), and an automatic stop when nothing has been fought for two
  minutes.
- **Settings persist** — everything you configure is saved and restored on the
  next run.

---

## Requirements

- [slib.lua](https://github.com/spectre011-code/Public-ME-Scripts/blob/main/Libraries/slib.lua) in your `Lua_Scripts` folder

## Installation

1. Download `Spectre's Basic Combat.lua`.
2. Place it in `Lua_Scripts`, keeping the filename unchanged — the script writes
   your settings back into itself and looks for that exact path.
3. Launch it from the client's script list.

## Usage

| Tab | What it does |
|-----|--------------|
| **Combat** | **Refresh** to scan, pick an NPC, **Add** it. Reorder with the arrows, remove with **x**. The button above the list cycles the targeting mode. |
| **Loot** | Enter an item id and **Add**. |
| **Options** | Sustain toggles, HP/prayer trigger levels, and buffs to keep up. |

**Start** begins, **Pause** holds, **Stop Script** exits. Closing the window also
stops the script.

Stand where your targets are, with any food, potions and buff items in your
inventory.

## Configuration

Timings, ranges and the fixed Excalibur/Elven Shard trigger levels live in the
`Config` table at the top of the script. Everything you set in the GUI saves
automatically — no manual editing needed.

