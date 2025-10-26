# 🧭 Spectre's Hard Clue Solver

A Lua automation script designed to solve **Hard Clue Scrolls** in RuneScape.

---

## ⚙️ Requirements

Before running the script, ensure the following setup:

### 🔓 General Setup
- All **Lodestones** unlocked  
- Start on **Ancient Spellbook**  
- **Inventory**, **Equipment**, and **Emotes** tabs visible  
- All **Hard Hidey Holes** built and filled  
- **No equipment** worn at startup  

---

## 📚 Required Libraries

Make sure these libraries are located in your `Lua_Scripts` directory:
  
-	[Slib](https://github.com/spectre011-code/Public-ME-Scripts/blob/main/Libraries/slib.lua)
-	[Dead Lodestones](https://me.deadcod.es/lodestones)
-	[Higgins PuzzleModule](https://placeholder.com)

---

## 🧠 Ability Bars

### 🗡️ Combat Bar
- Any **Revolution (Revo)** bar suitable for combat

### ✨ Teleportation & Utility Bar
Include the following spells and items (ensure proper order if required by your setup):

- Lunar Book Swap  
- Western Kharazi Teleport  
- Annakarl Teleport  
- Drakan’s Medallion  
- Arch Journal  
- Ectophial  
- Standard Book Swap  
- Trollheim Teleport  
- Wars Retreat Teleport  
- Attuned Crystal Seed  
- Luck of the Dwarves  
- Wicked Hood  

---

## 🎒 Inventory Setup

Make sure your inventory includes these items before starting:

| Item | Notes |
|------|-------|
| Charos Clue Carrier | Must contain a Hard Clue |
| Hard Clue | Required for solving |
| Weapon | For combat steps |
| Spade | For digging clues |
| Ectophial | For Ectofuntus teleport |
| Arch Journal | For Archaeology teleports |
| Attuned Crystal Seed | For teleporting to Prifddinas |
| Luck of the Dwarves | Required for certain clues |
| Wicked Hood | For Runecrafting-related teleports |
| Drakan’s Medallion | For Morytania teleports |
| Puzzle Box Skipping Ticket | Optional (required if not using Higgins API solver) |
| Super Restore | For restoring Prayer and stats |
| Meerkat Pouches | For scan clue assistance |
| **Runes:** |  |
| • Cosmic |  |
| • Astral |  |
| • Blood |  |
| • Law |  |
| • Time |  |
| • Fire |  |

---

## 🧩 Notes

- If you are not using the **Higgins API Puzzle Solver**, ensure you have enough **Puzzle Skipping Tickets**.  
- If you dont want or are unable to complete a specific step, there is a DestroyClue() function that you can place instead of the solving code.
- This script assumes you can reach the steps location, there are no checks for that.
- I encourage you to write different pathing for the steps and share them with the community. Tag if you need help with that.
---

## 💬 Credits

Developed by **Spectre**
For RuneScape automation and Lua scripting enthusiasts.  
