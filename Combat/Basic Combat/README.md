# Basic Combat

A simple, configurable combat script for the MemoryError (RS3) Lua client. Scan
nearby NPCs, build a priority kill order, auto-loot drops, and keep yourself
alive with HP/prayer sustain — all from a clean ImGui interface.

**Author:** Spectre011 · **Discord:** not_spectre011

---

## Features

- **Priority targeting** — pick which NPCs to kill and in what order. The script
  always engages the highest-priority NPC in range, and moves on the moment the
  current target dies (no re-clicking corpses).
- **Nearby NPC scanner** — one click populates a dropdown with every NPC around
  you, so you never have to type names.
- **Reorderable kill list** — move entries up/down or remove them at any time.
- **Ground looting** — add items by **id or name** (partial name matches add
  every match at once). Loots only while idle, so it never drags you out of a
  fight.
- **Sustain options**
  - **Excalibur** — heals HP (supports all Excalibur variants, respects the
    enhanced-heal cooldown).
  - **Eat Food** — eats when HP is low and food is in the inventory.
  - **Elven Shard** — restores prayer.
- **Persistent config** — your priority list, loot list, and sustain toggles are
  saved automatically and restored the next time you run the script.

---

## Requirements

- The **MemoryError** RS3 Lua client.
- `api.lua` and `slib.lua` present in your `Lua_Scripts` folder (standard client
  setup).

## Installation

1. Download `Spectre's Basic Combat.lua`.
2. Place it in your `Lua_Scripts` folder.
3. Launch it from the client's script list.

## Usage

The window has three tabs:

| Tab | What it does |
|-----|--------------|
| **Combat** | **Refresh** to scan nearby NPCs, pick one from the dropdown, **Add** it to the kill priority. Reorder with the arrows, remove with **x**. |
| **Loot** | Type an item **id or name** and **Add**. A partial name adds every match. |
| **Options** | Toggle HP sustain (Excalibur / Eat Food) and prayer sustain (Elven Shard). |

Press **Start** to begin, **Pause** to hold, **Stop Script** to exit.

Start in range of the NPCs you want to fight, with any sustain items in your
inventory / on your action bars.

## Configuration

Common tuning values live in the `Config` table at the top of the script
(scan/attack range, loop timings, sustain HP/prayer thresholds). Your in-game
choices (priority, loot, sustain toggles) are saved automatically — no manual
editing needed.

---
