-- Title: Spectre011's Woodcutting AIO
-- Author: Spectre011
-- Description: Cuts trees
-- Version: 1.4.0
-- Category: Woodcutting

ScriptName = "Spectre's Woodcutting AIO"
Author = "Spectre011"
ScriptVersion = "1.4.0"
ReleaseDate = "11-07-2026"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0.0 - 28-06-2025
    - Initial release.
v1.1.0 - 06-07-2025
    - Added wood box support.
    - Fully implemented GOTE recharging support(500 and 2000 charges).
    - Added log pile bank logic.
    - Fixed PROC:HandleAtTreesState() to not crash the script if FUNC:GetBestTree() returns nil.
    - Added API.DoRandomEvents() to the main loop.
    - Changed API.GetSkillByName() to API.GetSkillsTableSkill(16) so ME can read the skill level without needing the tab open.
v1.1.1 - 06-07-2025
    - Added FUNC:GetWoodBoxHexIdAndSlot() to return the correct hex ID and slot to empty the wood box into the bank.
    - Modified PROC:HandleAtBankState() to empty the wood box into the bank.
v1.1.2 - 06-07-2025
    - Fixed PROC:HandleAtBankState() juju, perfect juju and perfect plus logic.
v1.2.0 - 15-07-2025
    - Added Lumberjack's Intuition support.
    - Added Guthix Memorial bank logic.
    - Updated Slib to v1.0.2
    - Changed print statements to Slib logging functions.
v1.2.1 - 25-07-2025
    - Fixed an Aura issue where the script would get stuck if the player had no aura resets.
v1.3.0 - 21-09-2025
    - Updated BANK and Slib to latest versions.
v1.3.1 - 29-01-2026
    - Updated the burthorpe bank after jagex changed it to a bank chest instead of a gnome banker
v1.3.2 - 07-06-2026
    - Removed require config from func.lua
v1.4.0 - 11-07-2026
    - Updated Slib to v1.0.14.
    - Updated lodestones library (new interface component IDs and fixed coordinates).
    - Removed aura support completely.
    - Replaced Slib:CheckIncenseStick() calls with Slib:BuffUpKeep() (removed in Slib v1.0.13).
    - Fixed sharpening stone, imbued bird feed and lumberjack's courage buff checks spamming
      the item when the buff was already active (buff IDs were tables, Buffbar_GetIDstatus needs numbers).
    - Rewrote crystalize: proper spell selection with DoAction_DontResetSelection(),
      requirement checks (Ancient spellbook + 6 water/fire/chaos/soul runes) and
      a randomized 30s recast timer that occasionally lets the buff lapse.
    - Added Light Form support when crystalize is active (with CanCastAbility guard).
    - Fixed crystalize cast being cancelled by the cut click that followed it.
    - Fixed tree hopping when a floor highlight was present (target tree is now sticky
      until it dies; always picks the closest tree on a fresh pick).
    - Added human-like breaks (micro-breaks every 15-40 min, occasional long breaks).
    - Randomized the main loop tick (200-600ms instead of fixed 300ms).
    - Replaced API.SetMaxIdleTime() with an inlined anti-idle that also runs during breaks.
]]

local API = require("api")
local Slib = require("Woodcutting AIO.modules.slib")
local FUNC = require("Woodcutting AIO.modules.func")
local PROC = require("Woodcutting AIO.modules.proc")

--------------------START GUI STUFF--------------------
local CurrentStatus = "Starting"
local UIComponents = {}
local function GetComponentAmount()
    local amount = 0
    for i,v in pairs(UIComponents) do
        amount = amount + 1
    end
    return amount
end

local function GetComponentByName(componentName)
    for i,v in pairs(UIComponents) do
        if v[1] == componentName then
            return v;
        end
    end
end

local function AddBackground(name, widthMultiplier, heightMultiplier, colour)
    widthMultiplier = widthMultiplier or 1
    heightMultiplier = heightMultiplier or 1
    colour = colour or ImColor.new(15, 13, 18, 255)
    Background = API.CreateIG_answer();
    Background.box_name = "Background" .. GetComponentAmount();
    Background.box_start = FFPOINT.new(30, 0, 0)
    Background.box_size = FFPOINT.new(400 * widthMultiplier, 20 * heightMultiplier, 0)
    Background.colour = colour
    UIComponents[GetComponentAmount() + 1] = {name, Background, "Background"}
end

local function AddLabel(name, text, colour)
    colour = colour or ImColor.new(255, 255, 255)
    Label = API.CreateIG_answer()
    Label.box_name = "Label" .. GetComponentAmount()
    Label.colour = colour;
    Label.string_value = text
    UIComponents[GetComponentAmount() + 1] = {name, Label, "Label"}
end

local function GUIDraw()
    for i=1,GetComponentAmount() do
        local componentKind = UIComponents[i][3]
        local component = UIComponents[i][2]
        if componentKind == "Background" then
            component.box_size = FFPOINT.new(component.box_size.x, 25 * GetComponentAmount(), 0)
            API.DrawSquareFilled(component)
        elseif componentKind == "Label" then
            component.box_start = FFPOINT.new(40, 10 + ((i - 2) * 25), 0)
            API.DrawTextAt(component)
        elseif componentKind == "CheckBox" then
            component.box_start = FFPOINT.new(40, ((i - 2) * 25), 0)
            API.DrawCheckbox(component)
        elseif componentKind == "ComboBox" then
            component.box_start = FFPOINT.new(40, ((i - 2) * 25), 0)
            API.DrawComboBox(component, false)
        elseif componentKind == "ListBox" then
            component.box_start = FFPOINT.new(40, 10 + ((i - 2) * 25), 0)
            API.DrawListBox(component, false)
        end
    end
end

local function CreateGUI()
    AddBackground("Background", 1, 1, ImColor.new(15, 13, 18, 255))
    AddLabel("Author/Version", ScriptName .. " v" .. ScriptVersion .. " - " .. Author, ImColor.new(238, 230, 0))
    AddLabel("Status", "Status: " .. CurrentStatus, ImColor.new(238, 230, 0))
end

local function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    local statusLabel = GetComponentByName("Status")
    if statusLabel then
        statusLabel[2].string_value = "Status: " .. CurrentStatus
    end
end

CreateGUI()
GUIDraw()
--------------------END GUI STUFF--------------------

local States = {
    STARTING = "STARTING",
    AT_TREES = "AT_TREES",
    MOVING_TO_TREES = "MOVING_TO_TREES",
    MOVING_TO_BANK = "MOVING_TO_BANK",
    AT_BANK = "AT_BANK",
    ERROR = "ERROR",
}

local CurrentState = "STARTING"
local IsFirstRun = true

--Anti-idle based on UTILS:antiIdle() from utils.lua (by Dead), inlined to avoid the import.
--Fires PIdle2 at a random point between 60% and 90% of the 5 minute idle timeout.
local MaxIdleTimeMinutes = 5
local AfkTimer = os.time()
local NextAntiIdleIn = math.random((MaxIdleTimeMinutes * 60) * 0.6, (MaxIdleTimeMinutes * 60) * 0.9)

local function AntiIdle()
    if os.difftime(os.time(), AfkTimer) > NextAntiIdleIn then
        API.PIdle2()
        AfkTimer = os.time()
        NextAntiIdleIn = math.random((MaxIdleTimeMinutes * 60) * 0.6, (MaxIdleTimeMinutes * 60) * 0.9)
        return true
    end
    return false
end

--Human-like breaks: micro-break every 15-40 minutes, occasionally a long one
local function RollNextBreakTime()
    return os.time() + math.random(15 * 60, 40 * 60)
end

local function RollBreakDuration()
    if math.random(100) <= 15 then
        return math.random(5 * 60, 15 * 60) --long break (5-15 min)
    end
    return math.random(30, 180) --micro break (30s-3min)
end

local NextBreakTime = RollNextBreakTime()

API.Write_fake_mouse_do(false)
while (API.Read_LoopyLoop()) do
    if not API.CacheEnabled then
        Slib:Error("Cache is not enabled. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if (API.ScriptRuntime()/60) > tonumber(CONFIG.MaxTime) then
        Slib:Warn("Script runtime is greater than max time. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if API.GetSkillsTableSkill(16) >= tonumber(CONFIG.MaxLevel) then
        Slib:Warn("Woodcutting level is greater than max level. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end
    
    if IsFirstRun then
        CurrentState = States.STARTING
        IsFirstRun = false
    end

    if CurrentState == States.AT_TREES and os.time() >= NextBreakTime then
        local BreakDuration = RollBreakDuration()
        Slib:Info("Taking a break for " .. BreakDuration .. " seconds.")
        UpdateStatus("Taking a break")
        local BreakEnd = os.time() + BreakDuration
        while API.Read_LoopyLoop() and os.time() < BreakEnd do
            AntiIdle() --keep the client from logging out during long breaks
            Slib:Sleep(500, "ms")
        end
        NextBreakTime = RollNextBreakTime()
        goto continue
    end

    AntiIdle()
    API.DoRandomEvents()
    if CurrentState == States.STARTING then
        UpdateStatus("Starting")
        CurrentState = PROC:HandleStartingState(CONFIG)
    elseif CurrentState == States.AT_TREES then
        UpdateStatus("At Trees")
        CurrentState = PROC:HandleAtTreesState(CONFIG)
    elseif CurrentState == States.MOVING_TO_TREES then
        UpdateStatus("Moving to Trees")
        CurrentState = PROC:HandleMovingToTreesState(CONFIG)
    elseif CurrentState == States.MOVING_TO_BANK then
        UpdateStatus("Moving to Bank")
        CurrentState = PROC:HandleMovingToBankState(CONFIG)
    elseif CurrentState == States.AT_BANK then
        UpdateStatus("At Bank")
        CurrentState = PROC:HandleAtBankState(CONFIG)
    elseif CurrentState == States.ERROR then
        Slib:Error("Error. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    else
        if CurrentState then
            Slib:Error("Unknown state: " .. CurrentState .. ". Halting script.")
            API.Write_LoopyLoop(false)
            goto continue
        else
            Slib:Error("CurrentState is nil. Halting script.")
            API.Write_LoopyLoop(false)
            goto continue
        end
    end
    
    ::continue::
    Slib:RandomSleep(200, 600, "ms")
    collectgarbage("collect")
end
