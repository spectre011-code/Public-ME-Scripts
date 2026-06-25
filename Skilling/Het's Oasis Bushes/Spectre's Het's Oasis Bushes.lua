ScriptName = "Het's Oasis Bushes"
Author = "Spectre011"
ScriptVersion = "2.1.2"
ReleaseDate = "22-03-2025"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0 - 22-03-2025
    - Initial release.
v1.1 - 22-03-2025
    - Added UTILS:antiIdle()
v1.2 - 23-03-2025
    - Changed metrics to track only golden roses
    - Added API.LogDrop to track golden roses
v2.0.0 - 31-03-2025
    - Adopted SemVer 
    - Changed Discord variable name to DiscordHandle
v2.1.0 - 03-07-2025
    - Added compost option
    - Fixed metrics
v2.1.1 - 03-07-2025
    - Added API.SetMaxIdleTime(5)
v2.1.2 - 05-07-2025
    - Added 3 attempts to find the bush
]]

local API = require("api")
local Slib = require("slib")
local BANK = require("bank")
API.SetMaxIdleTime(5)
math.randomseed(os.time())

--------------------START GUI STUFF--------------------
local CurrentStatus = "Starting"
local TempSelection = nil
local SetBushOption = "None"
local SetCompostOption = "None"
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

local function AddComboBox(name, text, options)
    ComboBox = API.CreateIG_answer()
    ComboBox.box_name = text
    ComboBox.stringsArr = options
    ComboBox.box_size = FFPOINT.new(400, 0, 0)
    UIComponents[GetComponentAmount() + 1] = {name, ComboBox, "ComboBox"}
end

local function AddCheckbox(name, text)
    CheckBox = API.CreateIG_answer()
    CheckBox.box_name = text
    UIComponents[GetComponentAmount() + 1] = {name, CheckBox, "CheckBox"}
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
    AddLabel("Author/Version", ScriptName .. " v" .. ScriptVersion .. " by " .. Author, ImColor.new(238, 230, 0))
    local CompostOptions = {"- none - ", "Compost", "Supercompost", "Ultracompost"}
    AddComboBox("CompostComboBox", "Compost", CompostOptions)
    local BushOptions = {"- none - ", "Rose", "Iris", "Hydrangea", "Hollyhock"}
    AddComboBox("BushesComboBox", "Bushes", BushOptions)
    
    AddLabel("Status", "Status: " .. CurrentStatus, ImColor.new(238, 230, 0))
end

local function SetBushComboBoxOption()
    TempSelection = GetComponentValue("BushesComboBox") or TempSelection
    if TempSelection == "- none -" then SetBushOption = "None" end
    if TempSelection == "Rose" then SetBushOption = "Rose" end
    if TempSelection == "Iris" then SetBushOption = "Iris" end
    if TempSelection == "Hydrangea" then SetBushOption = "Hydrangea" end
    if TempSelection == "Hollyhock" then SetBushOption = "Hollyhock" end
end

local function SetCompostComboBoxOption()
    TempSelection = GetComponentValue("CompostComboBox") or SetCompostOption
    if TempSelection == "- none -" then SetCompostOption = "None" end
    if TempSelection == "Compost" then SetCompostOption = 6032 end
    if TempSelection == "Supercompost" then SetCompostOption = 6034 end
    if TempSelection == "Ultracompost" then SetCompostOption = 43966 end
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
local MetricsTable = {
    {"-", "-"}
}

local startTime = os.time() 
local counter = 0
local lastUpdateTime = os.time()
local updateFrequency = 0
local ReasonToStop = "None"

local function formatRunTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function calcIncreasesPerHour()
    local runTimeInHours = (os.time() - startTime) / 3600
    if runTimeInHours > 0 then
        return counter / runTimeInHours
    else
        return 0
    end
end

local function calcAverageIncreaseTime()
    if counter > 0 then
        return (os.time() - startTime) / counter
    else
        return 0
    end
end

function Tracking()
    counter = counter + 1 
    local runTime = os.time() - startTime
    local increasesPerHour = calcIncreasesPerHour() 
    local avgIncreaseTime = calcAverageIncreaseTime() 

    MetricsTable[1] = {"Thanks for using my script!"}
    MetricsTable[2] = {" "}
    MetricsTable[3] = {"Total Run Time", formatRunTime(runTime)}
    MetricsTable[4] = {"Total golden roses", tostring(counter)}
    MetricsTable[5] = {"Golden roses per Hour", string.format("%.2f", increasesPerHour)}
    MetricsTable[6] = {"Average golden rose time (s)", string.format("%.2f", avgIncreaseTime)}
    MetricsTable[7] = {"-----", "-----"}
    MetricsTable[8] = {"Script's Name:", ScriptName}
    MetricsTable[9] = {"Author:", Author}
    MetricsTable[10] = {"Version:", ScriptVersion}
    MetricsTable[11] = {"Release Date:", ReleaseDate}
    MetricsTable[12] = {"Discord:", DiscordHandle}
    MetricsTable[13] = {"Reason to stop:", ReasonToStop}
end
--------------------END METRICS STUFF--------------------
local IDS = {
    Bushes = {
        Rose = {
            Bare = 122504,
            Budding = 122505,
            Blooming = 122506,
            Harvestable = 122507,
            Coord = { x = 3357, y = 3257, z = 0 }
        },
        Iris = {
            Bare = 122508,
            Budding = 122509,
            Blooming = 122510,
            Harvestable = 122511,
            Coord = { x = 3386, y = 3257, z = 0 }
        },
        Hydrangea = {
            Bare = 122512,
            Budding = 122513,
            Blooming = 122514,
            Harvestable = 122515,
            Coord = { x = 3387, y = 3207, z = 0 }
        },
        Hollyhock = {
            Bare = 122516,
            Budding = 122517,
            Blooming = 122518,
            Harvestable = 122519,
            Coord = { x = 3353, y = 3218, z = 0 }
        }
    },
    Anomalies = {
        Scarab = 28671, --TYPE 1
        Gas = 7620 --TYPE 4
    },
    Flowers = {
        Roses        = 52807,
        Irises       = 52808,
        Hydrangeas   = 52809,
        Hollyhocks   = 52810,
        GoldenRoses  = 52811
    },
    Compost = {
        Compost = 6032,
        Supercompost = 6034,
        Ultracompost = 43966
    },
    Bucket = 1925
}

local function MoveToAdjacentBushTile(coord)
    -- Guard against nil table or missing fields
    if not coord or not coord.x or not coord.y or not coord.z then
        Slib:Info("[MoveToAdjacentBushTile] Invalid coordinate table supplied.")
        return false
    end

    -- Define the four cardinal offsets around the bush
    local offsets = {
        { x =  1, y =  0 }, -- East
        { x = -1, y =  0 }, -- West
        { x =  0, y =  1 }, -- North
        { x =  0, y = -1 }  -- South
    }

    -- Randomly pick one of the offsets
    local randomIndex = math.random(1, #offsets)
    local chosenOffset = offsets[randomIndex]

    -- Calculate the destination tile
    local destX = coord.x + chosenOffset.x
    local destY = coord.y + chosenOffset.y
    local destZ = coord.z -- floor level remains unchanged

    -- Debug information
    Slib:Info(string.format(
        "[MoveToAdjacentBushTile] Moving to tile (%d, %d, %d) adjacent to bush (%d, %d, %d)",
        destX, destY, destZ, coord.x, coord.y, coord.z))

    -- Perform the movement using Slib's path-finding utility
    return Slib:MoveTo(destX, destY, destZ)
end

local function GetBushID()
    if not SetBushOption or SetBushOption == "None" then
        Slib:Info("No bush selected, returning 0")
        return 0
    end

    local bushData = IDS.Bushes[SetBushOption]

    local stageIds = {
        bushData.Harvestable,
        bushData.Blooming,
        bushData.Budding,
        bushData.Bare
    }

    -- Try to find the bush object up to 3 times
    for attempt = 1, 3 do
        local obj = Slib:FindObj(stageIds, 15, 0)
        if obj and obj.Id then
            Slib:Info("Bush found on attempt " .. attempt .. ", returning " .. obj.Id)
            return obj.Id
        end
        
        if attempt < 3 then
            Slib:Info("Bush not found on attempt " .. attempt .. ", retrying...")
            Slib:RandomSleep(1000, 2000, "ms") -- Small delay between attempts
        end
    end

    -- Nothing found after 3 attempts
    Slib:Info("No bush found after 3 attempts, returning 0")
    ReasonToStop = "No bush found"
    return 0
end

local function HandleGasCloud()
    Slib:Info("Handling gas cloud")
    UpdateStatus("Handling gas cloud")
    API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{GetBushID()},50)
    Slib:RandomSleep(7000, 10000, "ms")
end

local function HandleScarab()
    Slib:Info("Trying to shoo the Scarab")
    UpdateStatus("Handling scarab")
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{IDS.Anomalies.Scarab},50)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function HarvestBush()
    Slib:Info("Trying to harvest bush")
    UpdateStatus("Harvesting bush")
    API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{GetBushID()},50)
    Slib:RandomSleep(3000, 7000, "ms")
end

local function UseCompost()
    Slib:Info("Using compost")
    UpdateStatus("Using compost")
    API.DoAction_DontResetSelection()
    API.DoAction_Inventory1(SetCompostOption,0,0,API.OFF_ACT_Bladed_interface_route)
    Slib:RandomSleep(200, 600, "ms")
    API.DoAction_DontResetSelection()
    API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{GetBushID()},50)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function IsBushBare()
    local currentId = GetBushID()
    if currentId == 0 then
        return false
    end

    for _, bushData in pairs(IDS.Bushes) do
        if currentId == bushData.Bare then
            return true
        end
    end

    return false
end

local function CheckForAnomalies()
    local scarabObjects = API.GetAllObjArray1({IDS.Anomalies.Scarab}, 10, {1})
    local gasCloudObjects = API.GetAllObjArray1({IDS.Anomalies.Gas}, 10, {4})

    if #scarabObjects > 0 then
        HandleScarab()
        return
    end


    if #gasCloudObjects > 0 then
        HandleGasCloud()
        return
    end
end

local UsedCompost = false
local GoldenRoses = Inventory:GetItemAmount(IDS.Flowers.GoldenRoses)
Slib:Info("Starting with Golden Roses: " .. GoldenRoses)

local StageID = 1
local StageDescriptions = {
    [1] = "Stage 1: Moving to Bushes",
    [2] = "Stage 2: Harvesting Bushes",
    [3] = "Stage 3: Banking"
}

local stageFunctions = {
    [1] = function()
        Slib:Info("Stage 1: " .. StageDescriptions[StageID])
        UpdateStatus("Moving to bushes")
        if SetBushOption == "None" then
            Slib:Info("No bush selected, skipping...")
            return
        elseif SetBushOption == "Rose" then
            if not Slib:IsPlayerInArea(IDS.Bushes.Rose.Coord.x, IDS.Bushes.Rose.Coord.y, IDS.Bushes.Rose.Coord.z, 5) then
                Slib:Info("Player not in area, moving to bushes...")
                MoveToAdjacentBushTile(IDS.Bushes.Rose.Coord)
                if Slib:IsPlayerInArea(IDS.Bushes.Rose.Coord.x, IDS.Bushes.Rose.Coord.y, IDS.Bushes.Rose.Coord.z, 5) then
                    StageID = 2
                end
            else
                Slib:Info("Player near rose bush, skipping...")
                StageID = 2
            end

        elseif SetBushOption == "Iris" then
            if not Slib:IsPlayerInArea(IDS.Bushes.Iris.Coord.x, IDS.Bushes.Iris.Coord.y, IDS.Bushes.Iris.Coord.z, 5) then
                Slib:Info("Player not in area, moving to bushes...")
                MoveToAdjacentBushTile(IDS.Bushes.Iris.Coord)
                if Slib:IsPlayerInArea(IDS.Bushes.Iris.Coord.x, IDS.Bushes.Iris.Coord.y, IDS.Bushes.Iris.Coord.z, 5) then
                    StageID = 2
                end
            else
                Slib:Info("Player near iris bush, skipping...")
                StageID = 2
            end

        elseif SetBushOption == "Hydrangea" then
            if not Slib:IsPlayerInArea(IDS.Bushes.Hydrangea.Coord.x, IDS.Bushes.Hydrangea.Coord.y, IDS.Bushes.Hydrangea.Coord.z, 5) then
                Slib:Info("Player not in area, moving to bushes...")
                MoveToAdjacentBushTile(IDS.Bushes.Hydrangea.Coord)
                if Slib:IsPlayerInArea(IDS.Bushes.Hydrangea.Coord.x, IDS.Bushes.Hydrangea.Coord.y, IDS.Bushes.Hydrangea.Coord.z, 5) then
                    StageID = 2
                end
            else
                Slib:Info("Player near hydrangea bush, skipping...")
                StageID = 2
            end

        elseif SetBushOption == "Hollyhock" then
            if not Slib:IsPlayerInArea(IDS.Bushes.Hollyhock.Coord.x, IDS.Bushes.Hollyhock.Coord.y, IDS.Bushes.Hollyhock.Coord.z, 5) then
                Slib:Info("Player not in area, moving to bushes...")
                MoveToAdjacentBushTile(IDS.Bushes.Hollyhock.Coord)
                if Slib:IsPlayerInArea(IDS.Bushes.Hollyhock.Coord.x, IDS.Bushes.Hollyhock.Coord.y, IDS.Bushes.Hollyhock.Coord.z, 5) then
                    StageID = 2
                end
            else
                Slib:Info("Player near hollyhock bush, skipping...")
                StageID = 2
            end
        end        
    end,

    [2] = function()
        Slib:Info("Stage 2: " .. StageDescriptions[StageID])
        UpdateStatus("Harvesting bush")

        if IsBushBare() and UsedCompost == false then
            UseCompost()
            UsedCompost = true
        else
            UsedCompost = false
        end

        if SetCompostOption ~= "None" and not Inventory:Contains(SetCompostOption) then
            Slib:Info("No compost in inventory, rebanking...")
            StageID = 3
            return
        end

        HarvestBush()
    end,

    [3] = function()
        Slib:Info("Stage 3: " .. StageDescriptions[StageID])
        UpdateStatus("Banking")
        Slib:MoveTo(3382, 3269, 0)
        BANK:Open()
        Slib:SleepUntil(function()
            return BANK:IsOpen()
        end, 10, 100)
        BANK:SetNoteMode(false)
        Slib:RandomSleep(100, 2000, "ms")
        BANK:DepositAll(IDS.Bucket)
        Slib:RandomSleep(100, 2000, "ms")
        if not BANK:Contains(SetCompostOption) then
            Slib:Info("No compost in bank, exiting...")
            ReasonToStop = "No compost in bank"
            API.Write_LoopyLoop(false)
            return
        end
        Slib:RandomSleep(100, 2000, "ms")
        BANK:Withdraw10(SetCompostOption)
        Slib:RandomSleep(100, 2000, "ms")
        BANK:Withdraw10(SetCompostOption)
        StageID = 1
    end
}

local function ExecuteStage(StageID)
    if stageFunctions[StageID] then
        stageFunctions[StageID]()
    else
        Slib:Info("Invalid stage ID: " .. tostring(StageID))
    end
end

API.Write_fake_mouse_do(false)
while API.Read_LoopyLoop() do
    if API.CacheEnabled == false then
        Slib:Info("Cache is disabled. Exiting...")
        ReasonToStop = "Cache is disabled"
        API.Write_LoopyLoop(false)
        goto continue
    end

    Slib:Info("--------------------------------")
    Slib:Info("Configs:")
    Slib:Info("Bush: " .. SetBushOption)
    Slib:Info("Compost: " .. SetCompostOption)
    Slib:Info("UsedCompost: " .. tostring(UsedCompost))
    Slib:Info("IsBushBare: " .. tostring(IsBushBare()))
    Slib:Info("BushID: " .. GetBushID())
    Slib:Info("GoldenRoses: " .. GoldenRoses)
    Slib:Info("StageID: " .. StageID)
    Slib:Info("--------------------------------")

    GUIDraw()
    SetBushComboBoxOption()
    SetCompostComboBoxOption()

    -- Bush selected check
    if SetBushOption == "None" then
        Slib:Info("No bush selected, skipping...")
        goto continue
    end

    CheckForAnomalies()

    -- Player animating check
    if API.IsPlayerAnimating_(API.GetLocalPlayerName(), 20) then
        Slib:Info("Player animating. Skipping cycle.")
        goto continue
    end

    -- Player moving check
    if API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        Slib:Info("Player moving. Skipping cycle.")
        goto continue
    end

    ExecuteStage(StageID)

    if Inventory:GetItemAmount(IDS.Flowers.GoldenRoses) ~= GoldenRoses then
        local Difference = Inventory:GetItemAmount(IDS.Flowers.GoldenRoses) - GoldenRoses
        Slib:Info("Roses harvested: " .. Difference)
        for i = 1, Difference do
            Tracking()
            Slib:RandomSleep(300, 1000, "ms")
        end
        GoldenRoses = Inventory:GetItemAmount(IDS.Flowers.GoldenRoses)
    end

    ::continue::
    Slib:RandomSleep(300, 1000, "ms")
    collectgarbage("collect")
end

API.Write_LoopyLoop(false)
API.DrawTable(MetricsTable)
Slib:Info("----------//----------")
Slib:Info("Script Name: " .. ScriptName)
Slib:Info("Author: " .. Author)
Slib:Info("Version: " .. ScriptVersion)
Slib:Info("Release Date: " .. ReleaseDate)
Slib:Info("Discord: " .. DiscordHandle)
Slib:Info("----------//----------")

