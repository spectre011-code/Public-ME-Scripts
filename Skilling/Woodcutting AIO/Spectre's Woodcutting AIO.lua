-- Title: Spectre011's Woodcutting AIO
-- Author: Spectre011
-- Description: Cuts trees
-- Version: 1.0.0
-- Category: Woodcutting

ScriptName = "Spectre's Woodcutting AIO"
Author = "Spectre011"
ScriptVersion = "1.0.0"
ReleaseDate = "28-06-2025"
DiscordHandle = "not_spectre011"

local API = require("api")
local Slib = require("Woodcutting AIO.modules.slib")
local FUNC = require("Woodcutting AIO.modules.func")
local PROC = require("Woodcutting AIO.modules.proc")

--------------------START GUI STUFF--------------------
local CurrentStatus = "Starting"
local cycles = 0
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

API.SetMaxIdleTime(7)
API.Write_fake_mouse_do(false)
while (API.Read_LoopyLoop()) do
    if not API.CacheEnabled then
        print("Cache is not enabled. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if (API.ScriptRuntime()/60) > tonumber(CONFIG.MaxTime) then
        print("Script runtime is greater than max time. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if API.GetSkillByName("WOODCUTTING").level >= tonumber(CONFIG.MaxLevel) then
        print("Woodcutting level is greater than max level. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end
    
    if IsFirstRun then
        CurrentState = States.STARTING
        IsFirstRun = false
    end

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
        print("Error. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    else
        if CurrentState then
            print("Unknown state: " .. CurrentState .. ". Halting script.")
            API.Write_LoopyLoop(false)
            goto continue
        else
            print("CurrentState is nil. Halting script.")
            API.Write_LoopyLoop(false)
            goto continue
        end
    end

    
    ::continue::
    Slib:Sleep(300, "ms")
    collectgarbage("collect")
    --API.Write_LoopyLoop(false)
end