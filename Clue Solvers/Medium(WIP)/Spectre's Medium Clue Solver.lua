ScriptName = "Medium Clue Solver"
Author = "Spectre011"
ScriptVersion = "1.0.0"
ReleaseDate = "99-99-9999"
DiscordHandle = "not_spectre011"
--PRESET: 

--[[
Changelog:
v1.0.0 - 99-99-9999
    - Initial release.
]]

local API = require("api")
local UTILS = require("utils")
local LODESTONES = require("lodestones")

--------------------START GUI STUFF--------------------
local CurrentStatus = "Starting"
local ReasonForStopping = "Manual Stop."
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

local function GetComponentValue(componentName)
    local componentArr = GetComponentByName(componentName)
    local componentKind = componentArr[3]
    local component = componentArr[2]

    if componentKind == "Label" then
        return component.string_value
    elseif componentKind == "CheckBox" then
        return component.return_click
    elseif componentKind == "ComboBox" and component.string_value ~= "None" then
        return component.string_value
    elseif componentKind == "ListBox" and component.string_value ~= "None" then
        return component.string_value
    end

    return nil
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
    AddBackground("Background", 0.85, 1, ImColor.new(15, 13, 18, 255))
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

--------------------START METRICS STUFF--------------------
local MetricsTable = {}
local StartTime = os.time()
local Counter = 0

local function FormatRunTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function Tracking() -- This is what should be called at the end of every cycle
    Counter = Counter + 1
    local runTime = os.time() - StartTime
    local itemsPerHour = runTime > 0 and (Counter / runTime * 3600) or 0
    local avgTime = Counter > 0 and (runTime / Counter) or 0
    
    MetricsTable = {
        {"Thanks for using my script!"},
        {" "},
        {"Total Run Time", FormatRunTime(runTime)},
        {"Total Clue Scrolls", tostring(Counter)},
        {"Clue Scrolls per Hour", string.format("%.1f", itemsPerHour)},
        {"Average Time per Scroll (s)", string.format("%.1f", avgTime)},
        {"-----", "-----"},
        {"Script Name:", ScriptName or "N/A"},
        {"Author:", Author or "N/A"},
        {"Version:", ScriptVersion or "N/A"},
        {"Release Date:", ReleaseDate or "N/A"},
        {"Discord:", DiscordHandle or "N/A"}
    }
end
--------------------END METRICS STUFF--------------------
local IdleCycles = 0
local IsFirstStep = false
local ClueStepId = 0
local Naked = true
local Control = nil -- idk yet
local ChallengeScrollIds = {
    2842,
    2844,
    2846,
    2850,
    2852,
    2854,
    7275,
    7277,
    7279,
    7281,
    7283,
    7285,
    33285,
    33287,
    33289,
    33291,
    33293
}

local function Dig()
    return API.DoAction_Inventory1(952,0,1,API.OFF_ACT_GeneralInterface_route)
end

local function KhazardTeleport()
    return API.DoAction_Inventory1(50558,0,1,API.OFF_ACT_GeneralInterface_route)
end

local function IsPlayerAtCoords(x, y, z)
    local coord = API.PlayerCoord()
    if x == coord.x and y == coord.y and z == coord.z then
        return true
    else
        return false
    end
end

local function IsPlayerAtZCoords(z)
    local coord = API.PlayerCoord()
    if z == coord.z then
        return true
    else
        return false
    end
end

local function IsPlayerInArea(x, y, z, radius)
    local coord = API.PlayerCoord()
    local dx = math.abs(coord.x - x)
    local dy = math.abs(coord.y - y)
    if dx <= radius and dy <= radius and coord.z == z then
        return true
    else
        return false
    end
end

local function MoveTo(X, Y, Z, WalkTolerance, AreaTolerance)   
    while API.Read_LoopyLoop() and not IsPlayerInArea(X, Y, Z, (WalkTolerance + AreaTolerance)) do
        if not API.IsPlayerMoving_(API.GetLocalPlayerName()) then
            print("Not moving. Walking...")
            API.DoAction_WalkerW(WPOINT.new(X + math.random(-WalkTolerance, WalkTolerance),Y + math.random(-WalkTolerance, WalkTolerance),Z))
        end
        UTILS.randomSleep(300)
    end
    return true
end

local function Bool1Check(ObjID)
    local objects = API.GetAllObjArray1({ObjID}, 75, {12})
    if objects and #objects > 0 then
        for _, object in ipairs(objects) do
            if object.Bool1 == 1 then 
                return true
            end
        end
    end
    return false
end

local function IsDialogBoxOpen()
    return API.VB_FindPSett(2874, 1, 0).state == 12
end

local function IsTypingBoxOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    local VB2 = tonumber(API.VB_FindPSettinOrder(2873).state)
    print("VB1: " .. VB1)
    print("VB2: " .. VB2)
    if VB1 == 10 or VB2 == 10 then
        return true
    else
        return false
    end
end

local function PressSpace()
    return API.KeyboardPress2(0x20, 40, 60), API.RandomSleep2(400,300,600)
end

local function GetClueStepId()
    if Inventory:Contains(42007) then
        UpdateStatus("Opening clue")
        print("Opening clue")
        API.DoAction_Inventory1(42007, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open clue
        UTILS.randomSleep(2000)
        IsFirstStep = true
    end

    --This need to be checked before normal scrolls
    for _, scrollId in ipairs(ChallengeScrollIds) do
        if Inventory:Contains(scrollId) then
            UpdateStatus("Solving step " .. scrollId)
            print("Step: ".. scrollId)
            return scrollId
        end
    end

    local clue = Inventory:GetItem("Clue scroll (medium)")
    if #clue > 0 then
        UpdateStatus("Solving step " .. clue[1].id)
        print("Step: ".. clue[1].id)
        return clue[1].id
    end

    print("No scroll found")
    return nil
end

local function ReqCheck()
    UpdateStatus("Checking requirements")
    --Emotes tab open check
    if API.VB_FindPSettinOrder(3158, 1).state ~= 1 then
        print("REASON FOR STOPPING: Emotes tab not visible.")
        ReasonForStopping = "Emotes tab not visible."
        API.Write_LoopyLoop(false)
        return
    end

    --Equipment tab open check
    if not Equipment:IsOpen() then
        print("REASON FOR STOPPING: Equipment tab not visible.")
        ReasonForStopping = "Equipment tab not visible."
        API.Write_LoopyLoop(false)
        return
    end

    --Inventory tab open check
    if not Inventory:IsOpen() then
        print("REASON FOR STOPPING: Inventory tab not visible.")
        ReasonForStopping = "Inventory tab not visible."
        API.Write_LoopyLoop(false)
        return
    end

    --Spade check
    if not Inventory:Contains(952) then
        print("REASON FOR STOPPING: Spade not found in inventory.")
        ReasonForStopping = "Spade not found in inventory."
        API.Write_LoopyLoop(false)
        return
    end

    --Khazard teleport check
    if not Inventory:Contains(50558) then
        print("REASON FOR STOPPING: Khazard teleport not found in inventory.")
        ReasonForStopping = "Khazard teleport not found in inventory."
        API.Write_LoopyLoop(false)
        return
    end

    --Rope check
    if not Inventory:Contains(954) then
        print("REASON FOR STOPPING: Rope not found in inventory.")
        ReasonForStopping = "Rope not found in inventory."
        API.Write_LoopyLoop(false)
        return
    end
end

local ClueSteps = {
    [1234] = function()
        --Step goes here
    end,
    [2801] = function()
        if IsPlayerAtCoords(3137, 3253, 0) then
            Dig()
            IsFirstStep = true
        elseif LODESTONES.DRAYNOR_VILLAGE.IsAtLocation() then
            MoveTo(3137, 3253, 0, 0, 0)
        else
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
        end
    end,
    [2803] = function()
        if IsPlayerAtCoords(2679, 3110, 0) then
            Dig()
            IsFirstStep = true
        elseif IsPlayerInArea(2635, 3168, 0, 10) then
            MoveTo(2679, 3110, 0, 0, 0)
        else
            KhazardTeleport()
            IdleCycles = 2
        end
    end,
    [2805] = function()
        if IsPlayerAtCoords(2697, 3207, 0) then
            Dig()
            IsFirstStep = true
        elseif IsPlayerInArea(2710, 3211, 0, 5) then
            Interact:Object("Ropeswing", "Swing-on", 10)
        elseif IsPlayerAtCoords(2704, 3209, 0) then
            MoveTo(2697, 3207, 0, 0, 0)
        else
            LODESTONES.KARAMJA.Teleport()
            MoveTo(2710, 3211, 0, 2, 5)
        end
    end,
    [2807] = function()
        if IsPlayerAtCoords(2377, 3368, 0) then
            Dig()
            IsFirstStep = true
        else
            LODESTONES.EAST_ARDOUGNE.Teleport()
            MoveTo(2377, 3368, 0, 0, 1)
        end
    end,
    [2809] = function()
        if IsPlayerAtCoords(2478, 3156, 0) then
            Dig()
            IsFirstStep = true
        else
            LODESTONES.YANILLE.Teleport()
            MoveTo(2478, 3156, 0, 0, 1)
        end
    end,
    [2811] = function()
        if IsPlayerAtCoords(2512, 3467, 0) then
            Dig()
            IsFirstStep = true
        elseif IsPlayerAtCoords(2513, 3468, 0) then
            MoveTo(2512, 3467, 0, 0, 0)
        elseif IsPlayerInArea(2512, 3481, 0, 3) then
            API.DoAction_Inventory1(954,0,0,API.OFF_ACT_Bladed_interface_route) --Select Rope
            UTILS.randomSleep(100)
            API.DoAction_Object2(0x24,API.OFF_ACT_GeneralObject_route00,{ 1996 },50,WPOINT.new(2512,3468,0)) --Use rope on rock
            IdleCycles = 30
        elseif IsPlayerInArea(2513, 3495, 0, 3) then
            Interact:Object("Gate", "Open", 5)
            UTILS.randomSleep(2000)
            Interact:Object("Log raft", "Board", 5)
        elseif IsPlayerInArea(2528, 3495, 0, 2) then
            Interact:Object("Gate", "Open", 5)
            UTILS.randomSleep(1000)
            MoveTo(2513, 3495, 0, 1, 3)
        else
            LODESTONES.ARDOUGNE.Teleport()
            MoveTo(2528, 3495, 0, 1, 3)
        end
    end,
    [2813] = function()
        if IsPlayerAtCoords(2643, 3252, 0) then
            Dig()
            IsFirstStep = true
        elseif IsPlayerInArea(2635, 3168, 0, 10) then
            MoveTo(2643, 3252, 0, 0, 0)
        else
            KhazardTeleport()
            IdleCycles = 2
        end
    end,
    [2815] = function()
        -- Requires secret passage to be unlocked from Crandor side
        if IsPlayerAtCoords(2848, 3297, 0) then
            Dig()
            IsFirstStep = true
        elseif IsPlayerInArea(2834, 3258, 0, 3) then
            MoveTo(2848, 3297, 0, 0, 0)
        elseif IsPlayerInArea(2833, 9658, 0, 10) then
            Interact:Object("Climbing rope", "Climb", 10)
        elseif IsPlayerAtCoords(2836, 9600, 0) then
            MoveTo(2833, 9658, 0, 3, 5)
        elseif IsPlayerAtCoords(2836, 9599, 0) then
            Interact:Object("Wall", "Open", 5)
        elseif IsPlayerInArea(2855, 9569, 0, 10) then
            MoveTo(2836, 9599, 0, 0, 0)
        elseif IsPlayerInArea(2856, 3167, 0, 10) then
            Interact:Object("Rocks", "Climb-down", 5)
        elseif IsPlayerInArea(2816, 3182, 0, 5) then
            if not Bool1Check(24369) then --Is gate closed?
                Interact:Object("Gate", "Open", 5)
            end
            MoveTo(2856, 3167, 0, 2, 5)
        else
            LODESTONES.KARAMJA.Teleport()
            MoveTo(2816, 3182, 0, 2, 5)
        end
    end,
    [2817] = function()
        if IsPlayerAtCoords(2849, 3034, 0) then
            Dig()
            IsFirstStep = true
        else
            LODESTONES.KARAMJA.Teleport()
            MoveTo(2849, 3034, 0, 0, 0)
        end
    end,
}


API.Write_fake_mouse_do(false)
while API.Read_LoopyLoop() do
    ReqCheck()

    --Start skip checks
    if IdleCycles > 0 then
        print("Idle cycles greater than 0. Skipping cycle.")
        goto continue
    end

    if API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        print("Player moving. Skipping cycle.")
        goto continue
    end 

    if API.LocalPlayer_IsInCombat_() then
        print("Player in combat. Skipping cycle.")
        goto continue
    end

    if IsDialogBoxOpen() then
        print("Player in dialog. Sending spacebar.")
        PressSpace()
        goto continue
    end
    --End skip checks

    if Naked then -- Used to stop script from solving new steps until the items from emote steps are deposited back into hidey-hole
        ClueStepId = GetClueStepId()
    end

    if ClueStepId then
        if ClueSteps[ClueStepId] then
            ClueSteps[ClueStepId]()
        else
            print("REASON FOR STOPPING: No procedure found for clue step " .. tostring(ClueStepId))
            ReasonForStopping = "No procedure found for clue step " .. tostring(ClueStepId)
            API.Write_LoopyLoop(false)
        end
    end    

    ::continue::
    UTILS.randomSleep(300)
    IdleCycles = IdleCycles - 1
    collectgarbage("collect")
end

API.Write_LoopyLoop(false)
API.DrawTable(MetricsTable)
print("----------//----------")
print("Script Name: " .. ScriptName)
print("Author: " .. Author)
print("Version: " .. ScriptVersion)
print("Release Date: " .. ReleaseDate)
print("Discord: " .. DiscordHandle)
print("----------//----------")
print("Reason for Stopping: " .. ReasonForStopping)