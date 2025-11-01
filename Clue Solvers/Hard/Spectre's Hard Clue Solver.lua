ScriptName = "Hard Clue Solver"
Author = "Spectre011"
ScriptVersion = "0.0.0"
ReleaseDate = "99-99-9999"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v9.9.9 - 99-99-9999
    - Initial release.
]]

local API = require("api")
local Slib = require("slib")
local LODESTONES = require("lodestones")
local PuzzleModule = require("PuzzleModule")

Slib._writeToFile = true
UsePuzzleSolverAPI = false
APIKey = "YOURKEYHERE"

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
        end
    end
end

local function CreateGUI()
    AddBackground("Background", 0.85, 1, ImColor.new(15, 13, 18, 255))
    AddLabel("Author/Version", ScriptName .. " v" .. ScriptVersion .. " by " .. Author, ImColor.new(238, 230, 0))
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
local MetricsTable = {
    {"-", "-"}
}

local startTime = os.time() 
local counter = 0
local lastUpdateTime = os.time()
local updateFrequency = 0
local ReasonForStopping = "Manual Stop."

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

function Tracking() -- This is what should be called at the end of every cycle
    counter = counter + 1 
    local runTime = os.time() - startTime
    local increasesPerHour = calcIncreasesPerHour() 
    local avgIncreaseTime = calcAverageIncreaseTime() 

    MetricsTable[1] = {"Thanks for using my script!"}
    MetricsTable[2] = {" "}
    MetricsTable[3] = {"Total Run Time", formatRunTime(runTime)}
    MetricsTable[4] = {"Total Clues Solved", tostring(counter)}
    MetricsTable[5] = {"Clues per Hour", string.format("%.2f", increasesPerHour)}
    MetricsTable[6] = {"Average Clue Time (s)", string.format("%.2f", avgIncreaseTime)}
    MetricsTable[7] = {"Reason for Stopping:", ReasonForStopping}
    MetricsTable[8] = {"-----", "-----"}
    MetricsTable[9] = {"Script's Name:", ScriptName}
    MetricsTable[10] = {"Author:", Author}
    MetricsTable[11] = {"Version:", ScriptVersion}
    MetricsTable[12] = {"Release Date:", ReleaseDate}
    MetricsTable[13] = {"Discord:", DiscordHandle}    
end
--------------------END METRICS STUFF--------------------

--------------------START VARIABLES STUFF--------------------
local ClueStepId = 999999
local IdleCycles = 0
local FirstStep = true
local Retries = 1
local StoreHHItems = false
local IsFirstRun = true

local HHItems = {
    ["Adamant 2h sword"] = 45511,
    ["Amulet of glory"] = 1704,
    ["Amulet of power"] = 1731,
    ["Blue dragonhide chaps"] = 2493,
    ["Blue dragonhide body"] = 2499,
    ["Blue dragonhide vambraces"] = 2487,
    ["Bronze platelegs"] = 1075,
    ["Diamond ring"] = 1643,
    ["Elemental shield"] = 2890,
    ["Fire battlestaff"] = 1393,
    ["Iron pickaxe"] = 1267,
    ["Iron platebody"] = 1115,
    ["Iron square shield"] = 1175,
    ["Mithril platelegs"] = 45487,
    ["Mud pie"] = 7170,
    ["Ring of life"] = 2570,
    ["Rune full helm"] = 45539,
    ["Rune hatchet"] = 1359,
    ["Rune platebody"] = 45543,
    ["Rune warhammer"] = 45532,
    ["Splitbark helm"] = 3385
}

local OtherIDsNeededForStuff = {
    ["Spade"] = 952,
    ["LOTD"] = 39812,
    ["AttunedCrystalSeed"] = 39784,
    ["DrakansMedallion"] = 21576,
    ["PuzzleBoxSkip"] = 33505,
    ["SuperRestores"] = {23399, 23401, 23403, 23405, 23407, 23409, 3024, 3026, 3028, 3030},
    ["Meerkat"] = 19622,
    ["MeerkatScroll"] = 19621,
    ["WickedHood"] = 22332,
    ["StandardSpellbookSwap"] = 35018,
    ["LunarSpellbookSwap"] = 35014,
    ["WesternKharaziTeleport"] = 1779,
    ["TrollheimTeleport"] = 35032,
    ["ArchaeologyJournal"] = 49429,
    ["Ectophial"] = 4251,
    ["WarsTeleport"] = 35042,
    ["AnnakarlTeleport"] = 25913
}

local ChallengeScrolls = {
    7269, --answer is 6
    7271, --answer is 13
    7273 -- answer is 33
}

local StepItems = {}
local PossibleWeapons = {
    55480, --Omni guard
    55484, --Augmented Omni guard
    55502, --Death guard t10
    55504, --Death guard t20
    55508, --Death guard t30
    55512, --Death guard t40
    55516, --Death guard t50
    55520, --Death guard t60
    55524, --Death guard t70
    55528, --Augmented Death guard t70
    55532, --Death guard t80
    55536, --Augmented Death guard t80
    55540, --Death guard t90
    55544, --Augmented Death guard t90
    59354, --Devourer's Guard
    59356  --Augmented Devourer's Guard
}

local Wizards = {
    "Cabbagemancer",
    "Bandosian wild mage",
    "Armadylean shaman",
    "Zamorak wizard",
    "Saradomin wizard",
    "Guthix wizard",
    "Double agent"
}

local Emotes = {
    ["No"] = 1,
    ["Bow"] = 2,
    ["Angry"] = 3,
    ["Think"] = 4,
    ["Wave"] = 5,
    ["Shrug"] = 6,
    ["Cheer"] = 7,
    ["Beckon"] = 8,
    ["Laugh"] = 9,
    ["Jump For Joy"] = 10,
    ["Yawn"] = 11,
    ["Dance"] = 12,
    ["Jig"] = 13,
    ["Twirl"] = 14,
    ["Headbang"] = 15,
    ["Cry"] = 16,
    ["Blow Kiss"] = 17,
    ["Panic"] = 18,
    ["Raspberry"] = 19,
    ["Clap"] = 20,
    ["Salute"] = 21,
    ["Idea"] = 28,
}

local Interfaces = {
    ["Teleports"] = { { 720, 2, -1, 0 }, { 720, 17, -1, 2 } },
    ["SpiritTree"] = { { 1145, 1, -1, 0 } },
    ["ChatOptions"] = { { 1188, 5, -1, -1}, { 1188, 3, -1, 5}, { 1188, 3, 14, 3} },
    ["CharterMap"] = { { 95,23,-1,0 } },
    ["MagicCarpet"] = { {1928,6,-1,0}, {1928,21,-1,0} },
    ["ClueScroll"] = { { 345,9,-1,0 }, { 345,10,-1,0 } },
    ["CharosClueCarrier"] = { { 151,0,-1,0 }, { 151,1,-1,0 } }
}

local DialogOptions = {
    "Yes, and don't ask me again",
    "Okay"
}

local SkipCombatSteps = { --Steps that you get attacked by random shit
    2723,
    2725,
    2727,
    2731,
    2733,
    2735,
    2737,
    2741,
    2743,
    2745,
    2747,
    2786,
    2788,
    3525,
    3532,
    3534,
    3556,
    3558,
    7260,
    7262
}
--------------------END VARIABLES STUFF--------------------

--------------------START FUNCTIONS STUFF--------------------
local function RecurringSafetyChecks()
    --Start safety checks
    if not API.CacheEnabled then
        Slib:Error("Cache is not enabled. Halting script.")
        ReasonForStopping = "Cache is not enabled."
        API.Write_LoopyLoop(false)
        return false
    end

    if not API.IsCacheLoaded() then
        Slib:Error("Cache is not loaded. Halting script.")
        ReasonForStopping = "Cache is not loaded."
        API.Write_LoopyLoop(false)
        return false
    end

    if API.GetGameState2() ~= 3 then
        Slib:Error("Not in game. Halting script.")
        ReasonForStopping = "Not in game."
        API.Write_LoopyLoop(false)
        return false
    end

    --Emotes tab open check
    if API.VB_FindPSettinOrder(3158, 1).state ~= 1 then
        Slib:Error("Emotes tab not visible. Halting script.")
        ReasonForStopping = "Emotes tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end

    --Equipment tab open check
    if not Equipment:IsOpen() then
        Slib:Error("Equipment tab not visible. Halting script.")
        ReasonForStopping = "Equipment tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end

    --Inventory tab open check
    if not Inventory:IsOpen() then
        Slib:Error("Inventory tab not visible. Halting script.")
        ReasonForStopping = "Inventory tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end

    --Spade check
    if not Inventory:Contains(OtherIDsNeededForStuff["Spade"]) then
        Slib:Error("Spade not found in inventory. Halting script.")
        ReasonForStopping = "Spade not found in inventory."
        API.Write_LoopyLoop(false)
        return false
    end

    --Meerkats check
    if Familiars:GetName() ~= "Meerkats" and not Inventory:Contains(19622) then
        Slib:Error("Familiar not summoned and no pouches in inventory. Halting script.")
        ReasonForStopping = "Familiar not summoned and no pouches in inventory."
        API.Write_LoopyLoop(false)
        return false
    end

    --Auto retaliate check
    if API.GetVarbitValue(42166) ~= 1 then
        Slib:Error("Auto retaliate enabled. Halting script.")
        ReasonForStopping = "Auto retaliate enabled."
        API.Write_LoopyLoop(false)
        return false
    end

    --End safety checks
    return true
end

local function OnlyOnceSafetyChecks()
    --Spellbook check
    if Slib:GetSpellBook() ~= "Ancient" then
        Slib:Error("Not on ancient spellbook. Halting script.")
        ReasonForStopping = "Not on ancient spellbook."
        API.Write_LoopyLoop(false)
        return false
    end

    --Weapon check
    local HasWeapon = false
    for i = 1, #PossibleWeapons do
        if Inventory:Contains(PossibleWeapons[i]) then
            HasWeapon = true
            break
        end
    end

    if not HasWeapon then 
        Slib:Error("No weapon found")
        ReasonForStopping = "No Weapon found"
        return false
    end

    return true
end

local function GetClueStepId()
    if Inventory:Contains(42008) then
        UpdateStatus("Opening clue")
        Slib:Info("Opening clue")
        API.DoAction_Inventory1(42008, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open sealed clue
        Tracking()
        Slib:RandomSleep(600, 1200, "ms")
        FirstStep = true
    end

    local ScrollBox = Inventory:GetItem("Scroll box (hard)")
    if #ScrollBox > 0 then
        UpdateStatus("Opening scroll box")
        Slib:Info("Opening scroll box")
        API.DoAction_Inventory1(ScrollBox[1].id, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open scroll box
        Slib:RandomSleep(600, 1200, "ms")
    end

    local Clue = Inventory:GetItem("Clue scroll (hard)")
    if #Clue > 0 then
        local clueId = Clue[1].id

        -- Only proceed if the clue ID exists in our ClueSteps table
        if ClueSteps[clueId] then
            UpdateStatus("Solving step " .. clueId)
            Slib:Info("Step: ".. clueId)
            if FirstStep then
                API.DoAction_Inventory1(clueId,0,1,API.OFF_ACT_GeneralInterface_route) -- Open clue so jamflex thinks we are organic
                Slib:RandomSleep(900, 1200, "ms")
                API.DoAction_Interface(0x24,0xffffffff,1,345,13,-1,API.OFF_ACT_GeneralInterface_route) --Close clue scroll interface
                FirstStep = false
                Retries = 1
                StepItems = {0}
            end
            
            return clueId
        else
            Slib:Warn("Unknown clue step ID: " .. clueId .. " - skipping")
            return 999999
        end
    end

    Slib:Info("No scroll found")
    return 999999
end

local function HasSlidePuzzle()
    local Puzzlebox = Inventory:GetItem("Puzzle box (hard)")
    if #Puzzlebox > 0 then
        return true
    end
    return false
end

local function SolveSlidePuzzle()
    if UsePuzzleSolverAPI then
        local PuzzleBox = Inventory:GetItem("Puzzle box (hard)")
        if #PuzzleBox > 0 then
            UpdateStatus("Opening Puzzle Box")
            Slib:Info("Opening Puzzle Box")
            API.DoAction_Inventory1(PuzzleBox[1].id, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open puzzle box
            Slib:SleepUntil(function()
                return PuzzleModule.isPuzzleOpen()
            end, 6, 100)
            Slib:RandomSleep(600, 1200, "ms")
        end
        if PuzzleModule.isPuzzleOpen() then
            local PuzzleState = PuzzleModule.extractPuzzleState()
    
            if PuzzleState then
                local Success = PuzzleModule.solvePuzzle(PuzzleState, APIKey)
            end
        end

    else        
        if Inventory:Contains(OtherIDsNeededForStuff["PuzzleBoxSkip"]) then
            API.DoAction_Inventory1(OtherIDsNeededForStuff["PuzzleBoxSkip"],0,1,API.OFF_ACT_GeneralInterface_route)
        else
            Slib:Error("No puzzle box skips. Halting script.")
            ReasonForStopping = "No puzzle box skips."
            API.Write_LoopyLoop(false)
            return false
        end 
    end   
end

local function EquipItems(Items)
    --In combat check is necessary for emote steps that require no items equipped
    if API.LocalPlayer_IsInCombat_() then
        return
    end

    local EquippedItems = API.Container_Get_all(94)
    
    if EquippedItems then
        for I = 1, #EquippedItems do
            local EquippedItem = EquippedItems[I]
            if EquippedItem and EquippedItem.item_id and EquippedItem.item_id >= 0 then
                local ShouldKeep = false
                for _, DesiredItem in pairs(Items) do
                    if EquippedItem.item_id == DesiredItem then
                        ShouldKeep = true
                        break
                    end
                end
                if not ShouldKeep then
                    Equipment:Unequip(EquippedItem.item_id)
                    Slib:RandomSleep(100, 300, "ms")
                end
            end
        end
    end

    while API.Read_LoopyLoop() and not Equipment:ContainsAll(Items) do
        for _, Item in pairs(Items) do
            if not Equipment:Contains(Item) and not Inventory:Contains(Item) then
                Slib:Error("Item " .. Item .. " not found in Equipment or Inventory")
                ReasonForStopping = "Item " .. Item .. " not found in Equipment or Inventory"
                API.Write_LoopyLoop(false)
                return false
            end
            if not Equipment:Contains(Item) then
                Inventory:Equip(Item)
                Slib:RandomSleep(100, 300, "ms")
            end
        end
    end
    
    Slib:RandomSleep(100, 300, "ms")
    Slib:Info("Equipped items")
    return true
end

local function EquipWeapon()
    local EquippedWeapon = false
    for _, weapon in pairs(PossibleWeapons) do
        if Equipment:Contains(weapon) then
            EquippedWeapon = true
            break
        elseif not Equipment:Contains(weapon) and Inventory:Contains(weapon) then
            Inventory:Equip(weapon)
            EquippedWeapon = true
            break
        end
    end
    Slib:RandomSleep(100, 300, "ms")
    Slib:Info("Equipped weapon: " .. tostring(EquippedWeapon))
    return EquippedWeapon
end

local function AttackWizards()
    local WizardToAttack = nil
    local Interacting = API.ReadLpInteracting()
    --local Interacting = API.OthersInteractingWithLpNPC(false, 1)[1]
    local Objs = API.GetAllObjArrayInteract_str(Wizards, 20, {1})

    if Objs and #Objs > 0 then
        for i = 1, #Objs do
            if Objs[i] and Objs[i].Id then
                WizardToAttack = Objs[i].Name
                EquipWeapon()
                if Interacting then
                    if Interacting.Name ~= WizardToAttack then
                        Interact:NPC(WizardToAttack, "Attack", 20)
                    end
                end
                break
            end
        end
    else
        return
    end
    
end

local function Emote(EmoteName)
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,590,11,Emotes[EmoteName],API.OFF_ACT_GeneralInterface_route)
end

local function InterfaceIsOpen(interfaceName)
    return #API.ScanForInterfaceTest2Get(true, Interfaces[interfaceName]) > 0
end

local function DialogBoxIsOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    if VB1 == 12 then
        return true
    else
        return false
    end
end

local function HasOption()
    local option = API.ScanForInterfaceTest2Get(false, Interfaces["ChatOptions"])

    if #option > 0 and #option[1].textids > 0 then
        return option[1].textids
    end

    return false
end

local function OptionSelector(options)
    for i, optionText in ipairs(options) do
        local optionNumber = tonumber(API.Dialog_Option(optionText))
        if optionNumber and optionNumber > 0 then
            local keyCode = 0x30 + optionNumber
            API.KeyboardPress2(keyCode, 60, 100)
            API.RandomSleep2(400,300,600)
            return true
        end
    end
    return false
end

local function TypingBoxOpenIsOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    local VB2 = tonumber(API.VB_FindPSettinOrder(2873).state)
    if VB1 == 10 or VB2 == 10 then
        return true
    else
        return false
    end
end

local function HasScrolls()
    local StoredScrolls = tonumber(API.GetVarbitValue(25412))
    local InventoryScrolls = tonumber(Inventory:GetItemAmount(OtherIDsNeededForStuff["MeerkatScroll"]))

    if Inventory:Contains(OtherIDsNeededForStuff["MeerkatScroll"]) and StoredScrolls < 100 then
        API.DoAction_Interface(0xffffffff,0xffffffff,1,662,78,-1,API.OFF_ACT_GeneralInterface_route) --Store meerkat scrolls
    end

    if StoredScrolls + InventoryScrolls > 0 then
        return true
    else
        return false
    end
end

local function SpellbookSwap(BookName)
    if BookName == "Standard" then
        if not Slib:CanCastAbility(OtherIDsNeededForStuff["StandardSpellbookSwap"]) then
            Slib:Error("Standard spellbook swap not found or not available in ability bar. Halting script.")
            ReasonForStopping = "Standard spellbook swap not found or not available in ability bar."
            API.Write_LoopyLoop(false)
            return
        end
        local StandardSpellbookSwap = API.GetABs_id(OtherIDsNeededForStuff["StandardSpellbookSwap"])
        API.DoAction_Ability_Direct(StandardSpellbookSwap, 1, API.OFF_ACT_GeneralInterface_route)
    elseif BookName == "Lunar" then
        if not Slib:CanCastAbility(OtherIDsNeededForStuff["LunarSpellbookSwap"]) then
            Slib:Error("Lunar spellbook swap not found or not available in ability bar. Halting script.")
            ReasonForStopping = "Lunar spellbook swap not found or not available in ability bar."
            API.Write_LoopyLoop(false)
            return
        end
        local LunarSpellbookSwap = API.GetABs_id(OtherIDsNeededForStuff["LunarSpellbookSwap"])
        API.DoAction_Ability_Direct(LunarSpellbookSwap, 1, API.OFF_ACT_GeneralInterface_route)
    else
        Slib:Error("Invalid spellbook name. Halting script.")
        ReasonForStopping = "Invalid spellbook name."
        API.Write_LoopyLoop(false)
        return
    end
end

local function BarrowsTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["DrakansMedallion"]) then
        Slib:Error("Drakans medallion not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Drakans medallion not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3563, 3315, 0, 20) then
        return
    end

    local DrakansMedallion = API.GetABs_id(OtherIDsNeededForStuff["DrakansMedallion"])
    API.DoAction_Ability_Direct(DrakansMedallion, 1, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
    if InterfaceIsOpen("Teleports") then
        Slib:TypeText("1") --Barrows teleport in drakans medallion teleport interface
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(3563, 3315, 0, 20)
        end, 6, 100)
    end   
    Slib:RandomSleep(1000, 2000, "ms") 
end

local function GETeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["LOTD"]) then
        Slib:Error("LOTD not found or not available in ability bar. Halting script.")
        ReasonForStopping = "LOTD not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3163, 3463, 0, 20) then
        return
    end

    local AbLOTD = API.GetABs_id(OtherIDsNeededForStuff["LOTD"])
    API.DoAction_Ability_Direct(AbLOTD, 7, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
    if InterfaceIsOpen("Teleports") then 
        Slib:TypeText("2") --GE option in lotd menu
    end
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3163, 3463, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function KeldagrimTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["LOTD"]) then
        Slib:Error("LOTD not found or not available in ability bar. Halting script.")
        ReasonForStopping = "LOTD not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(2857, 10198, 0, 20) then
        return
    end

    local AbLOTD = API.GetABs_id(OtherIDsNeededForStuff["LOTD"])
    API.DoAction_Ability_Direct(AbLOTD, 7, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
    if InterfaceIsOpen("Teleports") then 
        Slib:TypeText("3") --Keldagrim option in lotd menu
    end
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2857, 10198, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function MiscellaniaTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["LOTD"]) then
        Slib:Error("LOTD not found or not available in ability bar. Halting script.")
        ReasonForStopping = "LOTD not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(2857, 10198, 0, 20) then
        return
    end

    local AbLOTD = API.GetABs_id(OtherIDsNeededForStuff["LOTD"])
    API.DoAction_Ability_Direct(AbLOTD, 7, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
    if InterfaceIsOpen("Teleports") then 
        Slib:TypeText("1") --Miscellania option in lotd menu
    end
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2857, 10198, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function WarsTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["WarsTeleport"]) then
        Slib:Error("Wars teleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Wars teleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3294, 10127, 0, 20) then
        return
    end

    local WarsTeleport = API.GetABs_id(OtherIDsNeededForStuff["WarsTeleport"])
    API.DoAction_Ability_Direct(WarsTeleport, 1, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3294, 10127, 0, 20)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function WickedHoodTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["WickedHood"]) then
        Slib:Error("Wicked hood not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Wicked hood not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3109, 3156, 3, 10) then
        return
    end

    local WickedHood = API.GetABs_id(OtherIDsNeededForStuff["WickedHood"])
    API.DoAction_Ability_Direct(WickedHood, 3, API.OFF_ACT_GeneralInterface_route) --RC Guild
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3109, 3156, 3, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function CrystalSeedLletyaTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["AttunedCrystalSeed"]) then
        Slib:Error("Attuned crystal seed not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Attuned crystal seed not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(2331, 3171, 0, 20) then
        return
    end

    local AttunedCrystalSeed = API.GetABs_id(OtherIDsNeededForStuff["AttunedCrystalSeed"])
    API.DoAction_Ability_Direct(AttunedCrystalSeed, 3, API.OFF_ACT_GeneralInterface_route) --Lletya
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2331, 3171, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function TrollheimTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["TrollheimTeleport"]) then
        Slib:Error("Trollheim teleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Trollheim teleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(2882, 3666, 0, 20) then
        return
    end

    SpellbookSwap("Standard")
    Slib:RandomSleep(200, 600, "ms")
    local TrollheimTeleport = API.GetABs_id(OtherIDsNeededForStuff["TrollheimTeleport"])
    API.DoAction_Ability_Direct(TrollheimTeleport, 1, API.OFF_ACT_GeneralInterface_route)
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2882, 3666, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function WesternKharaziTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["WesternKharaziTeleport"]) then
        Slib:Error("Western kharazi teleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Western kharazi teleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(2803, 2918, 0, 20) then
        return
    end

    SpellbookSwap("Lunar")
    Slib:RandomSleep(200, 600, "ms")
    local WesternKharaziTeleport = API.GetABs_id(OtherIDsNeededForStuff["WesternKharaziTeleport"])
    API.DoAction_Ability_Direct(WesternKharaziTeleport, 1, API.OFF_ACT_GeneralInterface_route)
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2803, 2918, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function ArchaeologyJournalTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["ArchaeologyJournal"]) then
        Slib:Error("Archaeology journal not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Archaeology journal not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3336, 3378, 0, 20) then
        return
    end

    local ArchaeologyJournal = API.GetABs_id(OtherIDsNeededForStuff["ArchaeologyJournal"])
    API.DoAction_Ability_Direct(ArchaeologyJournal, 7, API.OFF_ACT_GeneralInterface_route) --Archaeology journal
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3336, 3378, 0, 3)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
    
end

local function EctophialTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["Ectophial"]) then
        Slib:Error("Ectophial not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Ectophial not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if not Slib:IsPlayerInArea(3658, 3523, 0, 20) then
        local Ectophial = API.GetABs_id(OtherIDsNeededForStuff["Ectophial"])
        API.DoAction_Ability_Direct(Ectophial, 1, API.OFF_ACT_GeneralInterface_route)
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(3658, 3523, 0, 10)
        end, 20, 100)
    end
end

local function AnnakarlTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["AnnakarlTeleport"]) then
        Slib:Error("AnnakarlTeleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "AnnakarlTeleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if not Slib:IsPlayerInArea(3658, 3523, 0, 20) then
        local AnnakarlTeleport = API.GetABs_id(OtherIDsNeededForStuff["AnnakarlTeleport"])
        API.DoAction_Ability_Direct(AnnakarlTeleport, 1, API.OFF_ACT_GeneralInterface_route)
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(3286, 3887, 0, 10)
        end, 20, 100)
    end
end

local function ShouldSkipCombat()
    for _, step in pairs(SkipCombatSteps) do
        if ClueStepId == step then
            return true
        end
    end
    return false
end

local function DestroyClue()
    API.DoAction_Inventory1(ClueStepId,0,8,API.OFF_ACT_GeneralInterface_route2) --Destroy clue
    Slib:RandomSleep(1200, 1800, "ms")
    Slib:TypeText("y")
    Slib:RandomSleep(1200, 1800, "ms")
    API.DoAction_Inventory1(47836,0,1,API.OFF_ACT_GeneralInterface_route) --Open Charos' clue carrier
    Slib:RandomSleep(1200, 1800, "ms")
    if InterfaceIsOpen("CharosClueCarrier") then
        local Container = API.Container_Get_all(860)
        local Slot = 0
        local FoundSlot = false

        for i, clue in ipairs(Container) do
            if clue.item_id and clue.item_id == 42008 then
                Slot = clue.item_slot
                FoundSlot = true
                break
            end
        end

        if FoundSlot then 
            API.DoAction_Interface(0xffffffff,0xa418,1,151,14,Slot,API.OFF_ACT_GeneralInterface_route)
            Slib:RandomSleep(600, 1200, "ms")
            return true
        end
    end
    Slib:RandomSleep(600, 1200, "ms")
    return false
end
--------------------END FUNCTIONS STUFF--------------------

ClueSteps = {
    [1234] = function()
        if 1 == 2 then

        elseif 1 == 2 then

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [2722] = function()
        if LODESTONES.FORT_FORINTHRY.IsAtLocation() then
            Interact:Object("Crate", "Search", 20)
        else
            LODESTONES.FORT_FORINTHRY.Teleport()
        end
    end,

    [2723] = function()
        if Slib:IsPlayerAtCoords(3058, 3883, 0) then
            Familiars:CastSpecialAttack()

        elseif LODESTONES.WILDERNESS.IsAtLocation() then
            Slib:MoveTo(Slib:RandomNumber(3002, 3, 3), Slib:RandomNumber(3852, 3, 3), 0)
            Slib:MoveTo(3058, 3883, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2725] = function()
        if Slib:IsPlayerAtCoords(2987, 3963, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(2987, 3963, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2727] = function()
        if Slib:IsPlayerAtCoords(3159, 3959, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3159, 3959, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2729] = function()
        if Slib:IsPlayerAtCoords(3189, 3963, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3189, 3963, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2731] = function()
        if Slib:IsPlayerInArea(3286, 3887, 0, 10) then
            if Slib:IsPlayerAtCoords(3290, 3889, 0) then
                Familiars:CastSpecialAttack()
            else
                Slib:MoveTo(3290, 3889, 0)
            end

        else
            AnnakarlTeleport()
        end
    end,

    [2733] = function()
        if Slib:IsPlayerInArea(3140, 3804, 0, 2) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3140, 3804, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2735] = function()
        if Slib:IsPlayerInArea(2946, 3819, 0, 2) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(2946, 3819, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2737] = function()
        if Slib:IsPlayerInArea(3013, 3846, 0, 2) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3006, 3850, 0, 2) then
            if Slib:FindObj2(1558, 50, 0, 3008, 3850, 2) ~= nil then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(3013, 3846, 0)
            end            

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3006, 1, 1), Slib:RandomNumber(3850, 1, 1), 0)

        else
            WarsTeleport()
            Slib:RandomSleep(600, 1800, "ms")
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2739] = function()
        if Slib:IsPlayerAtCoords(3039, 3960, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3039, 3960, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2741] = function()
        if Slib:IsPlayerInArea(3244, 3792, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3244, 3792, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2743] = function()
        if Slib:IsPlayerInArea(3249, 3739, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3249, 3739, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2745] = function()
        if Slib:IsPlayerInArea(2967, 3689, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(2967, 3689, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2747] = function()
        if Slib:IsPlayerInArea(3091, 3571, 0, 1) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3086, 3565, 0, 1) then
            Slib:MoveTo(3091, 3571, 0)

        elseif Slib:IsPlayerInArea(3086, 3561, 0, 1) then
            Interact:Object("Rocks", "Climb", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3086, 3561, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2773] = function()
        if Slib:IsPlayerInArea(3218, 9617, 0, 2) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3208, 9616, 0, 5) then
            Slib:MoveTo(3218, 9617, 0)

        elseif Slib:IsPlayerInArea(3210, 3216, 0, 5) then
            Interact:Object("Trapdoor", "Climb-down", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3233, 3221, 0, 20) then
            Slib:MoveTo(3210, 3216, 0)

        else
            LODESTONES.LUMBRIDGE.Teleport()
        end
    end,

    [2774] = function()
        if Slib:IsPlayerAtCoords(3089, 3469, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(3089, 3469, 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2776] = function()
        if Slib:IsPlayerAtCoords(3192, 9825, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3190, 9834, 0, 10) then
            Slib:MoveTo(3192, 9825, 0)

        elseif Slib:IsPlayerInArea(3188, 3433, 0, 10) then
            if Slib:FindObj2(24376, 50, 12, 3188, 3433, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Staircase", "Climb-down", 20)
            end
        
        elseif Slib:IsPlayerInArea(3163, 3462, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3186, 1, 1), Slib:RandomNumber(3433, 1, 1), 0)
        else
            GETeleport()
        end
    end,

    [2778] = function()
        if Slib:IsPlayerInArea(3011, 3215, 0, 20) then
            Interact:NPC("Gerrant", "Talk to", 20)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [2780] = function()
        if Slib:IsPlayerAtCoords(3084, 3257, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3105, 3298, 0, 20) then
            Slib:MoveTo(3084, 3257, 0)

        else
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
        end
    end,

    [2782] = function()
        if Slib:IsPlayerInArea(3205, 3209, 1, 20) then
            if not Interact:Object("Drawers", "Open", 20) then
                Interact:Object("Drawers", "Search", 20)
            end

        elseif Slib:IsPlayerInArea(3207, 3210, 0, 2) then
            Interact:Object("Staircase", "Climb-up", 10)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3233, 3221, 0, 20)  then
            Slib:MoveTo(Slib:RandomNumber(3207, 1, 1), Slib:RandomNumber(3210, 1, 1), 0)

        else
            LODESTONES.LUMBRIDGE.Teleport()
        end
    end,

    [2783] = function()
        if Slib:IsPlayerAtCoords(2599, 3266, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(2599, 3266, 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [2785] = function()
        if Slib:IsPlayerInArea(3165, 3307, 2, 10) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3167, 3300, 0, 5) then
            if Slib:FindObj2(45966, 10, 12, 3167, 3303, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Ladder", "Climb-top", 20)
                IdleCycles = 15
            end

        elseif Slib:IsPlayerInArea(3233, 3221, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3167, 1, 1), Slib:RandomNumber(3300, 1, 1), 0)

        else
            LODESTONES.LUMBRIDGE.Teleport()
        end
    end,

    [2786] = function()
        if Slib:IsPlayerInArea(3235, 3673, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3235, 3673, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2788] = function()
        DestroyClue() --Too deep in the wilderness in the middle of aggressive things
    end,

    [2790] = function()
        if Slib:IsPlayerAtCoords(3161, 9904, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3212, 9897, 0, 1) then
            Slib:MoveTo(3161, 9904, 0)

        elseif Slib:IsPlayerInArea(3211, 9900, 0, 2) then
            Interact:Object("Spiderweb", "Pass", 20)

        elseif Slib:IsPlayerInArea(3236, 9866, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(3211, 1, 1), Slib:RandomNumber(9900, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3238, 3459, 0, 3) then
            if Slib:FindObj2(881, 10, 12, 3237, 3458, 2).Bool1 == 0 then
                Interact:Object("Manhole", "Open", 20)
            else
                Interact:Object("Manhole", "Climb-down", 20)
            end

        elseif Slib:IsPlayerInArea(3163, 3464, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3238, 1, 1), Slib:RandomNumber(3459, 1, 1), 0)

        else
            GETeleport()
        end
    end,

    [2792] = function()
        if Slib:IsPlayerInArea(3233, 3221, 0, 20) then
            local Hans = API.ReadAllObjectsArray({1}, {0}, "Hans")
            if Hans and #Hans > 0 then
                if Hans[1].Distance < 20 then
                    API.DoAction_NPC__Direct(0x2c, API.OFF_ACT_InteractNPC_route, Hans[1])
                    IdleCycles = 5
                else
                    Slib:Info("Hans is too far away. Waiting for him to move closer...")
                    IdleCycles = 15
                end
            else
                Slib:Info("Hans not found. Waiting for him to appear...")
                IdleCycles = 15
            end
        else
            LODESTONES.LUMBRIDGE.Teleport()
        end
    end,

    [2793] = function()
        if Slib:IsPlayerInArea(3058, 3484, 0, 10) then
            Interact:NPC("Abbot Langley", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(3067, 3502, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3058, 1, 1), Slib:RandomNumber(3484, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2794] = function()
        if HasSlidePuzzle() then
            Interact:NPC("Oziach", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(3068, 3513, 0, 2) and Slib:FindObj2(37123, 50, 12, 3068, 3513, 1).Bool1 == 1 then
            Interact:NPC("Oziach", "Talk-to", 20)

        elseif Slib:IsPlayerAtCoords(3067, 3505, 0) then
            if Slib:FindObj2(37123, 50, 12, 3068, 3513, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:NPC("Oziach", "Talk-to", 20)
            end

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [2796] = function()
        if Slib:IsPlayerInArea(3209, 3472, 0, 10) then
            if Slib:FindObj2(15536, 10, 12, 3207, 3472, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:NPC("Sir Prysin", "Talk-to", 20)
            end

        elseif Slib:IsPlayerInArea(3163, 3462, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3209, 1, 1), Slib:RandomNumber(3472, 1, 1), 0)

        else
            GETeleport()
        end
    end,

    [2797] = function()
        if Slib:IsPlayerInArea(3219, 3428, 0, 20) then
            Interact:NPC("Wilough", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(3163, 3463, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3219, 1, 1), Slib:RandomNumber(3428, 1, 1), 0)

        else
            GETeleport()
        end
    end,

    [2799] = function()
        if Slib:IsPlayerInArea(2957, 3515, 0, 3) then
            Interact:NPC("General Bentnoze", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2957, 3510, 0, 3) then
            if Slib:FindObj2(77969, 10, 12, 2957, 3511, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2957, 1, 1), Slib:RandomNumber(3513, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2967, 3403, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2957, 1, 1), Slib:RandomNumber(3510, 1, 1), 0)

        else
            LODESTONES.FALADOR.Teleport()
        end
    end,

    [3520] = function()
        if Slib:IsPlayerAtCoords(2616, 3077, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 30) then
            Slib:MoveTo(2616, 3077, 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [3522] = function()
        if Slib:IsPlayerAtCoords(2488, 3308, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2556, 3300, 0, 2) then
            Slib:MoveTo(2488, 3308, 0)


        elseif Slib:IsPlayerInArea(2559, 3299, 0, 2) then
            Interact:Object("Ardougne wall door", "Open", 20)

        elseif Slib:IsPlayerInArea(2582, 3318, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2559, 1, 1), Slib:RandomNumber(3299, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2582, 1, 1), Slib:RandomNumber(3318, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [3524] = function()
        if Slib:IsPlayerInArea(2459, 3182, 0, 2) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 30) then
            Slib:MoveTo(Slib:RandomNumber(2459, 1, 1), Slib:RandomNumber(3182, 1, 1), 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [3525] = function()
        if Slib:IsPlayerAtCoords(3027, 3629, 0) then
            if Interact:Object("Crate", "Search", 20) then
                Slib:RandomSleep(1000, 2000, "ms")
                WarsTeleport()
            end

        elseif Slib:IsPlayerAtCoords(3034, 3631, 0) then
            if Slib:FindObj2(64833, 10, 12, 3033, 3632, 3).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(3027, 3629, 0)
            end

        elseif Slib:IsPlayerAtCoords(3035, 3628, 0) or Slib:IsPlayerAtCoords(3034, 3628, 0) then
            if Slib:FindObj2(64831, 10, 12, 3035, 3628, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(3034, 3631, 0)
            end

        elseif Slib:IsPlayerAtCoords(3032, 3626, 0) then
            if Slib:FindObj2(64831, 10, 12, 3033, 3626, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:WalkToCoordinates(3035, 3628, 0)
                IdleCycles = 5
            end

        elseif Slib:IsPlayerAtCoords(3025, 3626, 0) then
            if Slib:FindObj2(64831, 10, 12, 3025, 3626, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(3032, 3626, 0)
            end

        elseif Slib:IsPlayerAtCoords(3023, 3629, 0) then
            if Slib:FindObj2(64831, 10, 12, 3023, 3628, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(3025, 3626, 0)
            end

        elseif Slib:IsPlayerInArea(3020, 3632, 0, 3) then
            if Slib:FindObj2(64833, 10, 12, 3021, 3632, 3).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(3023, 3629, 0)
            end

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3020, 1, 1), Slib:RandomNumber(3632, 1, 1), 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [3526] = function()
        if Slib:IsPlayerInArea(2883, 3667, 0, 10) then
            if Slib:IsPlayerAtCoords(2884, 3667, 0) then
                Familiars:CastSpecialAttack()
            else 
                Slib:MoveTo(2884, 3667, 0)
            end

        else
            TrollheimTeleport()
        end
    end,

    [3528] = function()
        if Slib:IsPlayerAtCoords(2848, 3684, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2880, 3670, 0, 10) then
            Slib:MoveTo(2848,3684,0)
            
        else

            TrollheimTeleport()
        end
    end,

    [3530] = function()
        if Slib:IsPlayerAtCoords(2763, 2974, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2790, 2979, 0, 2) then
            Slib:MoveTo(2763, 2974, 0)

        elseif Slib:IsPlayerInArea(2796, 2979, 0, 2) then
            Interact:Object("Rocks", "Climb", 20)

        elseif Slib:IsPlayerInArea(2761, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2796, 1, 1), Slib:RandomNumber(2979, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [3532] = function()
        if Slib:IsPlayerAtCoords(2775, 2891, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2805, 2918, 0, 10) then
            Slib:MoveTo(2775, 2891, 0)

        else
            WesternKharaziTeleport()
        end
    end,

    [3534] = function()
        if Slib:IsPlayerAtCoords(2838, 2914, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2803, 2918, 0, 5) then
            Slib:MoveTo(2838, 2914, 0)

        else
            WesternKharaziTeleport()
        end
    end,

    [3536] = function()
        if Slib:IsPlayerAtCoords(2950, 2902, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2950, 2914, 0 ,3) then
            Slib:WalkToCoordinates(2950, 2902, 0)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2950, 2918, 0, 3) then
            Interact:Object("Climbable vine", "Climb", 20)

        elseif Slib:IsPlayerInArea(2955, 2940, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2950, 1, 1), Slib:RandomNumber(2918, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2955, 2943, 0, 10) then
            Interact:Object("Climbable vine", "Climb", 20)

        elseif Slib:IsPlayerInArea(2802, 2946, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2955, 1, 1), Slib:RandomNumber(2943, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2762, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2802, 1, 1), Slib:RandomNumber(2946, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [3538] = function()
        if Slib:IsPlayerAtCoords(2961, 3024, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3001, 3032, 0, 10) then
            Slib:MoveTo(2961, 3024, 0)

        elseif InterfaceIsOpen("CharterMap") then            
            API.DoAction_Interface(0xffffffff,0xffffffff,1,95,26,-1,API.OFF_ACT_GeneralInterface_route) --Shipyard
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(3036, 3191, 0, 5) then
            Interact:NPC("Trader Crewmember", "Charter", 20)

        elseif Slib:IsPlayerInArea(3011, 3215, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3036, 1, 1), Slib:RandomNumber(3191, 1, 1), 0)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [3540] = function()
        if Slib:IsPlayerAtCoords(2924, 2963, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2925, 2951, 0, 3) then
            Slib:MoveTo(2924, 2963, 0)

        elseif Slib:IsPlayerInArea(2924, 2946, 0, 5) then
            Interact:Object("Stepping stones", "Cross", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2802, 2946, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2924, 1, 1), Slib:RandomNumber(2946, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2762, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2802, 1, 1), Slib:RandomNumber(2946, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [3542] = function()
        if Slib:IsPlayerAtCoords(3440, 3341, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3440, 3331, 0, 3) then
            Slib:MoveTo(3440, 3341, 0)

        elseif Slib:IsPlayerInArea(3431, 3328, 0, 5) then
            Interact:Object("Bridge", "Jump", 20)

        elseif Slib:IsPlayerInArea(3444, 3459, 0, 5) then
            Interact:Object("Gate", "Quick travel", 20)

        elseif Slib:IsPlayerInArea(3517, 3515, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3444, 1, 1), Slib:RandomNumber(3459, 1, 1), 0)

        else
            LODESTONES.CANIFIS.Teleport()
        end
    end,

    [3544] = function()
        if Slib:IsPlayerAtCoords(3441, 3419, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3444, 3455, 0, 2) then
            Slib:MoveTo(3441, 3419, 0)

        elseif Slib:IsPlayerInArea(3444, 3459, 0, 2) then
            Interact:Object("Gate", "Open", 20)

        elseif Slib:IsPlayerInArea(3517, 3515, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3444, 1, 1), Slib:RandomNumber(3459, 1, 1), 0)

        else
            LODESTONES.CANIFIS.Teleport()
        end
    end,

    [3546] = function()
        if Slib:IsPlayerAtCoords(2542, 3032, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2530, 3029, 0, 2) then
            Slib:MoveTo(2542, 3032, 0)

        elseif Slib:IsPlayerInArea(2530, 3025, 0, 2) then
            Interact:Object("Gap", "Jump-over", 20)

        elseif Slib:IsPlayerInArea(2509, 3012, 0, 3) then
            Slib:MoveTo(2530, 3025, 0)

        elseif Slib:IsPlayerInArea(2501, 3013, 0, 6) then
            Interact:Object("Battlement", "Climb-over", 20)

        elseif Slib:IsPlayerInArea(2502, 3062, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2501, 1, 1), Slib:RandomNumber(3013, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2505, 3062, 0, 3) then
            Interact:Object("City gate", "Open", 20)

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2505, 1, 1), Slib:RandomNumber(3062, 1, 1), 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [3548] = function()
        if Slib:IsPlayerAtCoords(2580, 3029, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2576, 3029, 0, 2) then
            Slib:WalkToCoordinates(2580, 3029, 0)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2500, 2987, 0, 5) then
            Interact:Object("Cave entrance", "Enter", 20)

        elseif Slib:IsPlayerInArea(2564, 3001, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2500, 2, 2), Slib:RandomNumber(2987, 2, 2), 0)
            
        elseif Slib:IsPlayerInArea(2529, 3094, 0, 30) then
            Slib:MoveTo(Slib:RandomNumber(2564, 2, 2), Slib:RandomNumber(3001, 2, 2), 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [3550] = function()
        Slib:Error("If you are seeing this message, it means that I have made a mistake.")
        Slib:Error("I thought step 3550 didnt exist but it actually does.")
        Slib:Error("Ping me on discord so I can code this step.")
        ReasonForStopping = "Clue step 3550 actually exists and Im stupid"
        API.Write_LoopyLoop(false)
    end,

    [3552] = function()
        if Slib:IsPlayerAtCoords(3168, 3041, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3214, 2954, 0, 20) then
            Slib:MoveTo(3168, 3041, 0)

        else
            LODESTONES.BANDIT_CAMP.Teleport()
        end
    end,

    [3554] = function()
        if Slib:IsPlayerAtCoords(3360, 3243, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3324, 3247, 0, 5) then
            Slib:MoveTo(3360, 3243, 0)

        elseif Slib:IsPlayerInArea(3297, 3184, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3324, 1, 1), Slib:RandomNumber(3247, 1, 1), 0)

        else
            LODESTONES.AL_KHARID.Teleport()
        end
    end,

    [3556] = function()
        if Slib:IsPlayerInArea(3034, 3805, 0, 2) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3034, 3805, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [3558] = function()
        if Slib:IsPlayerAtCoords(3285, 3943, 0) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3285, 3943, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [3560] = function()
        if Slib:IsPlayerAtCoords(2209, 3161, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2202, 3169, 0, 2) then
            Slib:MoveTo(2209, 3161, 0)

        elseif Slib:IsPlayerInArea(2199, 3169, 0, 2) then
            Interact:Object("Sticks", "Pass", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2188, 3171, 0, 2) then
            Slib:MoveTo(2199, 3169, 0)

        elseif Slib:IsPlayerInArea(2188, 3168, 0, 2) then
            API.DoAction_Object_r(0x39,API.OFF_ACT_GeneralObject_route0,{3998},50,WPOINT.new(2187,3169,0),5)--Enter Dense Forest
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2188, 3165, 0, 2) then
            API.DoAction_Object_r(0x39,API.OFF_ACT_GeneralObject_route0,{3939},50,WPOINT.new(2187,3166,0),5) --Enter Dense Forest
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2188, 3160, 0, 3) then
            Interact:Object("Dense forest", "Enter", 20)
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2142, 3121, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2188, 1, 1), Slib:RandomNumber(3160, 1, 1), 0)

        elseif InterfaceIsOpen("CharterMap") then
            API.DoAction_Interface(0xffffffff,0xffffffff,1,95,23,-1,API.OFF_ACT_GeneralInterface_route) --Port Tyras
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(3036, 3191, 0, 5) then
            Interact:NPC("Trader Crewmember", "Charter", 20)

        elseif Slib:IsPlayerInArea(3011, 3215, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3036, 1, 1), Slib:RandomNumber(3191, 1, 1), 0)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [3562] = function()
        if Slib:IsPlayerAtCoords(2181, 3206, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2181, 3208, 0, 3) then
            Slib:WalkToCoordinates(2181, 3206, 0)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2181, 3212, 0, 3) then
            Interact:Object("Sticks", "Pass", 20)

        elseif Slib:IsPlayerInArea(2209, 3205, 0, 3) then
            Slib:MoveTo(2181, 3212, 0)

        elseif Slib:IsPlayerInArea(2313, 9656, 0, 10) then --Fell in hole
            Interact:Object("Protruding rocks", "Climb", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2209, 3198, 0, 5) then
            Interact:Object("Leaves", "Jump", 20)

        elseif Slib:IsPlayerInArea(2254, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2209, 1, 1), Slib:RandomNumber(3198, 1, 1), 0)

        else
            LODESTONES.TIRANNWN.Teleport()
        end
    end,

    [3564] = function()
        if Slib:IsPlayerInArea(2185, 3283, 1, 10) then
            Interact:NPC("Lord Iorwerth", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2208, 3360, 1, 20) then            
            Slib:MoveTo(Slib:RandomNumber(2185, 1, 1), Slib:RandomNumber(3283, 1, 1), 1)

        else
            LODESTONES.PRIFDDINAS.Teleport()
        end
    end,

    [3566] = function()
        if Slib:IsPlayerInArea(3357, 3346, 0, 10) then
            Interact:NPC("Examiner", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3336, 3378, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3357, 1, 1), Slib:RandomNumber(3346, 1, 1), 0)

        else
            ArchaeologyJournalTeleport()
        end
    end,

    [3568] = function()
        if Slib:IsPlayerInArea(3130, 2797, 0, 10) then
            Interact:NPC("Hamid", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3150, 2786, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3130, 1, 1), Slib:RandomNumber(2797, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3192, 2715, 0, 5) then
            Interact:Object("Shifting tombs", "Travel Worker District", 20)

        elseif Slib:IsPlayerInArea(3216, 2716, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3192, 1, 1), Slib:RandomNumber(2715, 1, 1), 0)

        else
            LODESTONES.MENAPHOS.Teleport()
        end
    end,

    [3570] = function()
        if Slib:IsPlayerInArea(2848, 3495, 1, 10) then
            Interact:NPC("Captain Bleemadge", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2825, 3524, 1, 5) then
            Slib:MoveTo(Slib:RandomNumber(2848, 1, 1), Slib:RandomNumber(3495, 1, 1), 1)

        elseif Slib:IsPlayerInArea(2855, 3505, 0, 5) then
            Interact:Object("Cave", "Enter", 20)

        elseif Slib:IsPlayerInArea(2878, 3442, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2855, 1, 1), Slib:RandomNumber(3505, 1, 1), 0)

        else
            LODESTONES.TAVERLEY.Teleport()
        end
    end,

    [3572] = function()
        if 1 == 2 then

        elseif Slib:IsPlayerInArea(2701, 3407, 1, 3) then
            Interact:Object("Bookcase", "Search", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2701, 3407, 0, 5) then
            Interact:Object("Ladder", "Climb-up", 20)

        elseif Slib:IsPlayerInArea(2702, 3399, 0, 1) then
            if Slib:FindObj2(1530, 10, 12, 2702, 3401, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Ladder", "Climb-up", 20)
                IdleCycles = 15
            end

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(2702, 3400, 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [3573] = function()
        if Slib:IsPlayerInArea(2521, 3494, 1, 5) then
            Interact:Object("Boxes", "Search", 20)

        elseif Slib:IsPlayerInArea(2525, 3495, 0, 2) then
            if Slib:FindObj2(1533, 10, 12, 2525, 3495, 13).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            elseif Slib:IsPlayerInArea(2521, 3494, 0, 3) then
                Interact:Object("Ladder", "Climb-up", 20)
                IdleCycles = 15
            else
                Interact:Object("Ladder", "Climb-up", 20)
                IdleCycles = 15
            end

        elseif Slib:IsPlayerInArea(2529, 3494, 0, 5) then
            if Slib:FindObj2(1551, 10, 12, 2528, 3495, 13).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(2525, 3495, 0)
            end

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2529, 1, 1), Slib:RandomNumber(3494, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [3574] = function()
        if Slib:IsPlayerInArea(2575, 3465, 0, 10) then
            Interact:Object("Boxes", "Search", 20)

        elseif Slib:IsPlayerInArea(2567, 3457, 0, 2) then
            Slib:MoveTo(Slib:RandomNumber(2575, 1, 1), Slib:RandomNumber(3465, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2567, 3454, 0, 2) then
            Interact:Object("Gate", "Open", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2567, 1, 1), Slib:RandomNumber(3454, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [3575] = function()
        if Slib:IsPlayerInArea(2490, 3488, 1, 5) then
            Interact:NPC("Heckel Funch", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2466, 3494, 1, 5) then
            Slib:MoveTo(Slib:RandomNumber(2490, 1, 1), Slib:RandomNumber(3488, 1, 1), 1)

        elseif Slib:IsPlayerInArea(2466, 3494, 2, 20) then
            API.DoAction_Object1(0x35,API.OFF_ACT_GeneralObject_route2,{69271},50) --Climb down ladder

        elseif Slib:IsPlayerInArea(2466, 3494, 3, 20) then
            API.DoAction_Object_r(0x35,API.OFF_ACT_GeneralObject_route0,{107377},50,WPOINT.new(2466,3495,0),5) --Climb down Ladder

        elseif Slib:IsPlayerInArea(2466, 3494, 0, 2) then
            Interact:Object("Ladder", "Climb-up", 20) --Sometimes it goes to the top floor?
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2465, 3489, 0, 2) then
            Interact:Object("Tree Door", "Open", 20)
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2465, 1, 1), Slib:RandomNumber(3489, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3187, 3507, 0, 10) then
            Interact:Object("Spirit tree", "Teleport", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("SpiritTree")
            end, 6, 100)
            IdleCycles = 5
            if InterfaceIsOpen("SpiritTree") then
                Slib:TypeText("2") --Tree gnome stronghold option
            end
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(3163, 3465, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3187, 1, 1), Slib:RandomNumber(3507, 1, 1), 0)
        else
            GETeleport()
        end
    end,

    [3577] = function()
        if Slib:IsPlayerInArea(2474, 3427, 0, 10) then
            Interact:NPC("Gnome trainer", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2474, 1, 1), Slib:RandomNumber(3427, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3187, 3507, 0, 10) then
            Interact:Object("Spirit tree", "Teleport", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("SpiritTree")
            end, 6, 100)
            IdleCycles = 5
            if InterfaceIsOpen("SpiritTree") then
                Slib:TypeText("2") --Tree gnome stronghold option
            end
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(3162, 3466, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3187, 1, 1), Slib:RandomNumber(3507, 1, 1), 0)

        else
            GETeleport()
        end
    end,

    [3579] = function()
        DestroyClue() --CBA coding banking
    end,

    [3580] = function()
        if Slib:IsPlayerAtCoords(2832, 9586, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2857, 9569, 0, 5) then
            Slib:MoveTo(2832, 9586, 0)

        elseif Slib:IsPlayerInArea(2856, 3166, 0, 5) then
            Interact:Object("Rocks", "Climb-down", 20)

        elseif Slib:IsPlayerInArea(2814, 3182, 0, 5) then
            if Slib:FindObj2(24369, 10, 12, 2816, 3182, 3).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2856, 1, 1), Slib:RandomNumber(3166, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2761, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2814, 1, 1), Slib:RandomNumber(3182, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [7239] = function()
        if Slib:IsPlayerAtCoords(3021, 3911, 0) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3021, 3911, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [7241] = function()
        if Slib:IsPlayerAtCoords(2722, 3339, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2692, 3351, 0, 5) then
            Slib:MoveTo(2722, 3339, 0)

        elseif LODESTONES.ARDOUGNE.IsAtLocation() then
            Slib:MoveTo(Slib:RandomNumber(2692, 2, 2), Slib:RandomNumber(3351, 2, 2), 0) --Intermediary walk to avoid getting stuck in pof since jagex code is shit
            
        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [7243] = function()
        if Slib:IsPlayerAtCoords(2591, 3880, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2581, 3845, 0, 5) then
            Slib:MoveTo(2591, 3880, 0)

        elseif Slib:IsPlayerInArea(2630, 3691, 0, 20) then
            Interact:NPC("Sailor", "Travel-Miscellania", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2713, 3677, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2630, 1, 1), Slib:RandomNumber(3691, 1, 1), 0)

        else
            LODESTONES.FREMENNIK_PROVINCE.Teleport()
        end
    end,

    [7245] = function()
        if Slib:IsPlayerAtCoords(3489, 3288, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3561, 3315, 0, 20) then
            Slib:MoveTo(3489, 3288, 0)

        else
            BarrowsTeleport()
        end
    end,

    [7247] = function()
        if Slib:IsPlayerInArea(2835, 2992, 0, 5) then
            Interact:Object("Bookcase", "Search", 20)

        elseif Slib:IsPlayerInArea(2834, 2951, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2835, 1, 1), Slib:RandomNumber(2992, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2775, 3211, 0, 5) then
            Interact:Object("Travel cart", "Pay-fare", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2761, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2775, 1, 1), Slib:RandomNumber(3211, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [7248] = function()
        if Slib:IsPlayerInArea(3176, 2987, 0, 10) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3214, 2954, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3176, 1, 1), Slib:RandomNumber(2987, 1, 1), 0)

        else
            LODESTONES.BANDIT_CAMP.Teleport()
        end
    end,

    [7249] = function()
        if Slib:IsPlayerInArea(3094, 3150, 0, 5) then
            Interact:Object("Bookcase", "Search", 20)

        elseif Slib:IsPlayerInArea(3103, 3156, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3094, 1, 1), Slib:RandomNumber(3150, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3109, 3156, 3, 10) then
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route1,{79776},50) --Beam > Bottom floor
            IdleCycles = 15

        else
            WickedHoodTeleport()
        end
    end,

    [7250] = function()
        if Slib:IsPlayerInArea(2716, 9888, 0, 1) then
            Slib:MoveTo(2723,9890,0)
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerAtCoords(2710, 3496, 0) then
            Interact:Object("Staircase", "Climb-down", 20)

        elseif Slib:IsPlayerInArea(2710, 3495, 0, 2) then
            Interact:Object("Odd-looking wall", "Open", 20)

        elseif LODESTONES.SEERS_VILLAGE.IsAtLocation() then
            Slib:MoveTo(Slib:RandomNumber(2710, 1, 1), Slib:RandomNumber(3494, 1, 1), 0)

        else
            LODESTONES.SEERS_VILLAGE.Teleport()
        end
    end,

    [7251] = function()
        if Slib:IsPlayerInArea(3041, 9822, 0, 2) then
            Interact:Object("Mine cart", "Search", 10)

        elseif Slib:IsPlayerInArea(3018, 9850, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(3041, 1, 1), Slib:RandomNumber(9822, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3016, 3448, 0, 5) then
            Interact:Object("Ladder", "Climb-down", 20)

        elseif LODESTONES.FALADOR.IsAtLocation() then
            Slib:MoveTo(Slib:RandomNumber(3016, 2, 2), Slib:RandomNumber(3448, 2, 2), 0)
        else
            LODESTONES.FALADOR.Teleport()
        end
    end,

    [7252] = function()
        if Slib:IsPlayerInArea(2578, 9581, 0, 5) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(2587, 9573, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2578, 1, 1), Slib:RandomNumber(9581, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2574, 9500, 0, 5) then
            Interact:Object("Chaos altar", "Pray-at", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2580, 9512, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2574, 1, 1), Slib:RandomNumber(9500, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2580, 9520, 0, 3) then
            Interact:Object("Balancing ledge", "Walk-across", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2568, 9525, 0, 5) then
            Slib:MoveTo(2580, 9520, 0)

        elseif Slib:IsPlayerInArea(2570, 3120, 0, 2) then
            Interact:Object("Staircase", "Climb-down", 20)
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2569, 3116, 0, 3) then
            if Slib:FindObj2(733, 10, 12, 2570, 3118, 4).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2570, 1, 1), Slib:RandomNumber(3120, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2575, 3112, 0, 2) then
            Slib:MoveTo(Slib:RandomNumber(2569, 1, 1), Slib:RandomNumber(3116, 1, 1), 0)            

        elseif Slib:IsPlayerInArea(2575, 3107, 0, 2) then
            Interact:Object("Underwall tunnel", "Climb-under", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 20) then
            Slib:MoveTo(2575, 3107, 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [7253] = function()
        if Slib:IsPlayerInArea(3479, 3090, 0, 5) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3304, 3114, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(3479, 1, 1),Slib:RandomNumber(3090, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3304, 3122, 0, 5) then
            Interact:Object("Shantay Pass", "Go-through", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(3310, 3163, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3304, 2, 2), Slib:RandomNumber(3122, 2, 2), 0)

        elseif Slib:IsPlayerInArea(3297, 3184, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3310, 2, 2), Slib:RandomNumber(3163, 2, 2), 0)

        else
            LODESTONES.AL_KHARID.Teleport()
        end
    end,

    [7254] = function()
        if Slib:IsPlayerInArea(2672, 3418, 0, 5) then
            Interact:Object("Haystack", "Search", 20)

        elseif Slib:IsPlayerInArea(2659, 3437, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2672, 1, 1), Slib:RandomNumber(3418, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2656, 3440, 0, 5) then
            Interact:Object("Guild door", "Open", 20)

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2656, 1, 1), Slib:RandomNumber(3440, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [7255] = function()
        if Slib:IsPlayerInArea(2561, 3322, 0, 2) then
            if Slib:FindObj2(34530, 10, 12, 2561, 3323, 2).Bool1 == 0 then
                --Open Drawer
                API.DoAction_Object_r(0x31,API.OFF_ACT_GeneralObject_route0,{34530},50,WPOINT.new(2561,3323,0),5)
            else
                --Search Drawer
                API.DoAction_Object2(0x38,API.OFF_ACT_GeneralObject_route0,{34531},50,WPOINT.new(2561,3323,0))
            end

        elseif Slib:IsPlayerInArea(2565, 3320, 0, 1) then
            if Slib:FindObj2(34807, 10, 12, 2564, 3320, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(2561, 3322, 0)
            end

        elseif Slib:IsPlayerInArea(2565, 3316, 0, 2) then
            if Slib:FindObj2(34807, 10, 12, 2565, 3317, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(2565, 3320, 0)
            end

        elseif Slib:IsPlayerInArea(2582, 3318, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2565, 1, 1), Slib:RandomNumber(3316, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2582, 1, 1), Slib:RandomNumber(3318, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [7256] = function()
        if Slib:IsPlayerAtCoords(2339, 3311, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2386, 3333, 0, 1) then
            Slib:MoveTo(2339,3311,0)

        elseif Slib:IsPlayerInArea(2386, 3337, 0, 3) then
            Interact:Object("Huge Gate", "Enter", 20)
            IdleCycles = 10

        elseif LODESTONES.EAGLES_PEAK.IsAtLocation() then
            Slib:MoveTo(Slib:RandomNumber(2386, 2, 2), Slib:RandomNumber(3337, 2, 2), 0)

        else
            LODESTONES.EAGLES_PEAK.Teleport()
        end
    end,

    [7258] = function()
        if Slib:IsPlayerAtCoords(3139, 2969, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3214, 2954, 0, 20)  then
            Slib:MoveTo(3139, 2969, 0)

        else
            LODESTONES.BANDIT_CAMP.Teleport()
        end
    end,

    [7260] = function()
        if Slib:IsPlayerInArea(2970, 3749, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3009, 3652, 0, 10) then
            Slib:MoveTo(2970, 3749, 0)

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3009, 2, 2), Slib:RandomNumber(3652, 2, 2), 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [7262] = function()
        if Slib:IsPlayerInArea(3113, 3602, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3113, 3602, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [7264] = function()
        if Slib:IsPlayerInArea(3305, 3692, 0, 1) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3305, 3692, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [7266] = function()
        if Slib:IsPlayerAtCoords(2712, 3732, 0) then
            Familiars:CastSpecialAttack()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(2712, 3677, 0, 20) then
            Slib:MoveTo(2712, 3732, 0)

        else
            LODESTONES.FREMENNIK_PROVINCE.Teleport()
        end
    end,

    [7268] = function()
        --Challenge scroll
        if Slib:IsPlayerInArea(2407, 3496, 0, 10) and Inventory:Contains(ChallengeScrolls[1]) then
            if TypingBoxOpenIsOpen() then 
                Slib:TypeText("6")
                IdleCycles = 5
                API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
            elseif DialogBoxIsOpen() then
                Slib:TypeText(" ")
                IdleCycles = 5
            else
                Interact:NPC("Gnome Coach", "Talk to", 20)
                Slib:SleepUntil(function()
                    return TypingBoxOpenIsOpen() or DialogBoxIsOpen()
                end, 6, 100)
                IdleCycles = 5
            end
        
        elseif Slib:IsPlayerInArea(2407, 3496, 0, 30) then
            Interact:NPC("Gnome Coach", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2407, 1, 1), Slib:RandomNumber(3496, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3187, 3506, 0, 10) then
            Interact:Object("Spirit tree", "Teleport", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("SpiritTree")
            end, 6, 100)
            IdleCycles = 5
            if InterfaceIsOpen("SpiritTree") then 
                Slib:TypeText("2") --Tree gnome stronghold option
            end
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3162, 3462, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3187, 2, 2), Slib:RandomNumber(3506, 2, 2), 0)

        else
            GETeleport()
        end
    end,

    [7270] = function()
        --Challenge scroll
        if Slib:IsPlayerInArea(2526, 3162, 1, 10) and Inventory:Contains(ChallengeScrolls[2]) then
            if TypingBoxOpenIsOpen() then 
                Slib:TypeText("13")
                IdleCycles = 5
                API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
            elseif DialogBoxIsOpen() then
                Slib:TypeText(" ")
                IdleCycles = 5
            else
                Interact:NPC("Bolkoy", "Talk-to", 20)
                Slib:SleepUntil(function()
                    return TypingBoxOpenIsOpen() or DialogBoxIsOpen()
                end, 6, 100)
                IdleCycles = 5
            end
        end

        --Clue scroll
        if Slib:IsPlayerInArea(2526, 3162, 1, 20) then
            Interact:NPC("Bolkoy", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2526, 3160, 0, 3) then
            Interact:Object("Ladder", "Climb-up", 20)

        elseif Slib:IsPlayerInArea(2542, 3169, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2526, 1, 1), Slib:RandomNumber(3160, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3186, 3506, 0, 10) then
            Interact:Object("Spirit tree", "Teleport", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("SpiritTree")
            end, 6, 100)
            IdleCycles = 5
            if InterfaceIsOpen("SpiritTree") then 
                Slib:TypeText("1") --Gnome village option
            end
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3163, 3463, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3186, 2, 2), Slib:RandomNumber(3506, 2, 2), 0)

        else
            GETeleport()

        end
    end,

    [7272] = function()
        --Challenge scroll
        if Slib:IsPlayerInArea(2807, 3192, 0, 10) and Inventory:Contains(ChallengeScrolls[3]) then
            if TypingBoxOpenIsOpen() then 
                Slib:TypeText("33")
                IdleCycles = 5
                API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
            elseif DialogBoxIsOpen() then
                Slib:TypeText(" ")
                IdleCycles = 5
            else
                Interact:NPC("Cap'n Izzy No-Beard", "Talk to", 20)
                Slib:SleepUntil(function()
                    return TypingBoxOpenIsOpen() or DialogBoxIsOpen()
                end, 6, 100)
                IdleCycles = 5
            end
        end

        --Clue scroll
        if Slib:IsPlayerInArea(2807, 3192, 0, 10) then
            Interact:NPC("Cap'n Izzy No-Beard", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2761, 3147, 0, 20) then
            Slib:MoveTo(2807, 3192, 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [10234] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Bronze platelegs"]
        StepItems[2] = HHItems["Iron platebody"]
        StepItems[3] = HHItems["Blue dragonhide vambraces"]

        if StoreHHItems then
            Interact:Object("Rock (hidey-hole)", "Fill", 20)
            IdleCycles = 10
            StoreHHItems = false

        elseif Slib:IsPlayerAtCoords(3239, 3612, 0) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1200, "ms")
            Emote("Shrug")
            Slib:RandomSleep(600, 1200, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Inventory:Contains(StepItems) then
            Slib:WalkToCoordinates(3239, 3612, 0)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3244, 3610, 0, 10) and not Inventory:Contains(StepItems) then
            Interact:Object("Rock (hidey-hole)", "Take items", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3244, 3610, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [10236] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Elemental shield"]
        StepItems[2] = HHItems["Blue dragonhide chaps"]
        StepItems[3] = HHItems["Rune warhammer"]

        if StoreHHItems then
            Interact:Object("Crate (hidey-hole)", "Fill", 20)
            IdleCycles = 20
            StoreHHItems = false

        elseif Slib:IsPlayerAtCoords(2585, 3423, 0) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1000, "ms")
            Emote("Raspberry")
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Slib:IsPlayerInArea(2586, 3421, 0, 3) then
            Interact:Object("Crate (hidey-hole)", "Take items", 20)

        elseif Slib:IsPlayerInArea(2614, 3388, 0, 2) then
            Slib:MoveTo(2586, 3421, 0)

        elseif Slib:IsPlayerInArea(2614, 3385, 0, 3) then
            Interact:Object("Gate", "Open", 20)

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2614, 1, 1), Slib:RandomNumber(3385, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [10238] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Blue dragonhide body"]
        StepItems[2] = HHItems["Blue dragonhide vambraces"]

        if StoreHHItems then
           Interact:Object("Crate (hidey-hole)", "Fill", 20)
           IdleCycles = 15
           StoreHHItems = false
        elseif Slib:IsPlayerInArea(2512, 3639, 2, 3) then
            EquipItems(StepItems)
            Slib:RandomSleep(1200, 1800, "ms")
            Emote("Bow")
            Slib:RandomSleep(1200, 1800, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Slib:IsPlayerAtCoords(2505, 3641, 2) then
            Interact:Object("Crate (hidey-hole)", "Take items", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2509, 3637, 0, 2) then
            Interact:Object("Staircase", "Climb-top", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2509, 3633, 0, 3) then
            Interact:Object("Doorway", "Walk-through", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2594, 3608, 0, 4) then
            Slib:MoveTo(Slib:RandomNumber(2509, 1, 1), Slib:RandomNumber(3633, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2608, 3614, 0, 5) then
            Interact:Object("Broken bridge", "Cross", 20)

        elseif Slib:IsPlayerInArea(2712, 3677, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2608, 1, 1), Slib:RandomNumber(3614, 1, 1), 0)

        else
            LODESTONES.FREMENNIK_PROVINCE.Teleport()
        end
    end,

    [10240] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems = {}        

        if Slib:IsPlayerAtCoords(3612, 3488, 0) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1000, "ms")
            Emote("Panic")
            Slib:RandomSleep(600, 1000, "ms")
            Interact:NPC("Uri", "Talk to", 20)

        elseif LODESTONES.CANIFIS.IsAtLocation() then
            Slib:MoveTo(3612, 3488, 0)
            
        else
            LODESTONES.CANIFIS.Teleport()
        end
    end,

    [10242] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Ring of life"]
        StepItems[2] = HHItems["Amulet of glory"]
        StepItems[3] = HHItems["Adamant 2h sword"]

        if StoreHHItems then
            Interact:Object("Crate (hidey-hole)", "Fill", 20)
            IdleCycles = 20
            StoreHHItems = false

        elseif Slib:IsPlayerAtCoords(3295, 2782, 0) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1000, "ms")
            Emote("Dance")
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Inventory:Contains(StepItems) then
            Slib:MoveTo(3295, 2782, 0)

        elseif Slib:IsPlayerInArea(3308, 2785, 0, 10) then
            Interact:Object("Crate (hidey-hole)", "Take items", 20)

        elseif Slib:IsPlayerInArea(3266, 2729, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3309, 1, 1), Slib:RandomNumber(2785, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3238, 2729, 0, 10) then
            Interact:NPC("Coenus", "Go to Sophanem", 20) --Maisa morphs to Coenus behind the scenes
            --Interact:NPC("Maisa", "Go to Sophanem", 20) --Doesn't work
            --API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{24661},50) 
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(3216, 2716, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3238, 2, 2), Slib:RandomNumber(2729, 2, 2), 0)

        else
            LODESTONES.MENAPHOS.Teleport()
        end
    end,

    [10234] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Bronze platelegs"]
        StepItems[2] = HHItems["Iron platebody"]
        StepItems[3] = HHItems["Blue dragonhide vambraces"]

        if StoreHHItems then
            Interact:Object("Rock (hidey-hole)", "Fill", 20)
            IdleCycles = 10
            StoreHHItems = false

        elseif Slib:IsPlayerAtCoords(3239, 3612, 0) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1200, "ms")
            Emote("Shrug")
            Slib:RandomSleep(600, 1200, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Inventory:Contains(StepItems) then
            Slib:WalkToCoordinates(3239, 3612, 0)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3244, 3610, 0, 10) and not Inventory:Contains(StepItems) then
            Interact:Object("Rock (hidey-hole)", "Take items", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3244, 3610, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [10244] = function()
        DestroyClue() -- Middle of aggressive mobs in the wilderness
    end,

    [10246] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end
        
        StepItems[1] = HHItems["Diamond ring"]
        StepItems[2] = HHItems["Amulet of power"]

        if StoreHHItems then
            Interact:Object("Log (hidey-hole)", "Fill", 20)
            IdleCycles = 10
            StoreHHItems = false

        elseif Slib:IsPlayerAtCoords(2913, 3167, 0) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1000, "ms")
            Emote("Salute")
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Inventory:Contains(StepItems) then
            Slib:WalkToCoordinates(2913, 3167, 0)
            IdleCycles = 3

        elseif Slib:IsPlayerInArea(2914, 3156, 0, 10) and not Inventory:Contains(StepItems) then
            Interact:Object("Log (hidey-hole)", "Take items", 20)
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2956, 3146, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2914, 1, 1), Slib:RandomNumber(3156, 1, 1), 0)

        elseif LODESTONES.PORT_SARIM.IsAtLocation() then
            Interact:NPC("Captain Tobias", "Pay fare", 50)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [10248] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Fire battlestaff"]
        StepItems[2] = HHItems["Blue dragonhide chaps"]
        StepItems[3] = HHItems["Rune full helm"]

        if StoreHHItems then
            Interact:Object("Rock (hidey-hole)", "Fill", 20)
            IdleCycles = 20
            StoreHHItems = false

        elseif Slib:IsPlayerInArea(2795, 3671, 0, 3) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1200, "ms")
            Emote("Laugh")
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Inventory:ContainsAll(StepItems) then
            Slib:MoveTo(2795, 3671, 0)

        elseif Slib:IsPlayerInArea(2789, 3669, 0, 3) then
            Interact:Object("Rock (hidey-hole)", "Take items", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2762, 3653, 0, 2) then
            Slib:MoveTo(Slib:RandomNumber(2789, 1, 1), Slib:RandomNumber(3669, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2757, 3652, 0, 3) then
            Interact:Object("Rockslide", "Climb-over", 20)

        elseif Slib:IsPlayerInArea(2712, 3677, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2757, 1, 1), Slib:RandomNumber(3652, 1, 1), 0)

        else
            LODESTONES.FREMENNIK_PROVINCE.Teleport()
        end
    end,

    [10250] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Mithril platelegs"]
        StepItems[2] = HHItems["Ring of life"]
        StepItems[3] = HHItems["Rune hatchet"]
        
        if StoreHHItems then
            Interact:Object("Rock (hidey-hole)", "Fill", 20)
            IdleCycles = 20
            StoreHHItems = false

        elseif Slib:IsPlayerInArea(2849, 3493, 1, 3) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1000, "ms")
            Emote("Panic")
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
                IdleCycles = 5
                StoreHHItems = true
                StepItems = {}
            end

        elseif Slib:IsPlayerInArea(2845, 3494, 1, 5) and Inventory:ContainsAll(StepItems) then
            Slib:MoveTo(Slib:RandomNumber(2849, 1, 1), Slib:RandomNumber(3493, 1, 1), 1)            

        elseif Slib:IsPlayerInArea(2845, 3494, 1, 3) then
            Interact:Object("Rock (hidey-hole)", "Take items", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2825, 3524, 1, 5) then
            Slib:MoveTo(Slib:RandomNumber(2845, 1, 1), Slib:RandomNumber(3494, 1, 1), 1)

        elseif Slib:IsPlayerInArea(2855, 3505, 0, 5) then
            Interact:Object("Cave", "Enter", 20)

        elseif Slib:IsPlayerInArea(2871, 3427, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2855, 1, 1), Slib:RandomNumber(3505, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2878, 3442, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2871, 1, 1), Slib:RandomNumber(3427, 1, 1), 0)

        else
            LODESTONES.TAVERLEY.Teleport()
        end
    end,

    [10252] = function()
        if API.LocalPlayer_IsInCombat_() then
            return
        end

        StepItems[1] = HHItems["Splitbark helm"]
        StepItems[2] = HHItems["Mud pie"]
        StepItems[3] = HHItems["Rune platebody"]

        if StoreHHItems then
            Interact:Object("Potted plant (hidey-hole)", "Fill", 20)
            IdleCycles = 20
            StoreHHItems = false

        elseif Slib:IsPlayerInArea(2852, 2953, 0, 2) then
            EquipItems(StepItems)
            Slib:RandomSleep(600, 1000, "ms") 
            Emote("Blow Kiss")
            Slib:RandomSleep(600, 1000, "ms") 
            local Uri = API.GetAllObjArray1({5143}, 20, {1})
            if Uri and #Uri > 0 then
                --Multiple actions because sometimes one work and sometimes the other and I dont understand why
                API.DoAction_NPC(0x2c,API.OFF_ACT_InteractNPC_route2,{Uri[1].Id},50) 
                Slib:RandomSleep(600, 1000, "ms")
                API.DoAction_NPC(0x2c,API.OFF_ACT_InteractNPC_route,{Uri[1].Id},50)
                Slib:RandomSleep(600, 1000, "ms") 
                Interact:NPC("Uri", "Talk to", 20)
                Slib:RandomSleep(600, 1000, "ms")
                IdleCycles = 10
                StoreHHItems = true
                StepItems = {}
            end
            

        elseif Inventory:ContainsAll(StepItems) then
            Slib:MoveTo(2852, 2953, 0)            

        elseif Slib:IsPlayerInArea(2855, 2954, 0, 5) then
            Interact:Object("Potted plant (hidey-hole)", "Take items", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2834, 2951, 0, 5) then
            Slib:MoveTo(2855, 2954, 0)

        elseif Slib:IsPlayerInArea(2775, 3211, 0, 5) then
            Interact:Object("Travel cart", "Pay-fare", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2761, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2775, 1, 1), Slib:RandomNumber(3211, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [13044] = function()
        if Slib:IsPlayerInArea(3154, 3923, 0, 5) then
            if Slib:IsPlayerAtCoords(3154, 3923, 0) then
                Familiars:CastSpecialAttack()
            else
                Slib:WalkToCoordinates(3154, 3923, 0)
                IdleCycles = 5
            end

        elseif Slib:IsPlayerInArea(3091, 3475, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            LODESTONES.EDGEVILLE.Teleport()
        end
    end,

    [13010] = function()
        if Slib:IsPlayerInArea(2904, 10207, 0, 1) then
            Interact:NPC("Riki the sculptor's model", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2906, 10199, 0, 2) then
            if Slib:FindObj2(6110, 10, 12, 2906, 10200, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
                IdleCycles = 5
            else
                Interact:NPC("Riki the sculptor's model", "Talk to", 20)
            end

        elseif Slib:IsPlayerInArea(2872, 10233, 0, 10)  then
            Slib:MoveTo(Slib:RandomNumber(2906, 1, 1), Slib:RandomNumber(10199, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2858, 10200, 0, 20)  then
            Slib:MoveTo(Slib:RandomNumber(2872, 1, 1), Slib:RandomNumber(10233, 1, 1), 0)

        else
            KeldagrimTeleport()
        end
    end,

    [13012] = function()
        if HasSlidePuzzle() then
            Interact:NPC("Ramara du Croissant", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2336, 3675, 0, 2) and Slib:FindObj2(14923, 10, 12, 2337, 3675, 1).Bool1 == 1 then
            Interact:NPC("Ramara du Croissant", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2336, 3675, 0, 2) then
            if Slib:FindObj2(14923, 10, 12, 2337, 3675, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
                IdleCycles = 5
            else
                Interact:NPC("Ramara du Croissant", "Talk-to", 20)
            end

        elseif Slib:IsPlayerInArea(2344, 3663, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2336, 1, 1), Slib:RandomNumber(3675, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2344, 3655, 0, 2) then
            Interact:Object("Colony gate", "Open", 10)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2344, 3648, 0, 3) then
            Interact:Object("Hole", "Enter", 10)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2366, 3479, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2344, 2, 2), Slib:RandomNumber(3648, 2, 2), 0)

        else
            LODESTONES.EAGLES_PEAK.Teleport()
        end
    end,

    [13014] = function()
        if HasSlidePuzzle() then
            Interact:NPC("Professor Onglewip", "Talk-to", 50)

        elseif Slib:IsPlayerInArea(3103, 3156, 0, 5) then
            Interact:NPC("Professor Onglewip", "Talk-to", 50)

        elseif Slib:IsPlayerInArea(3109, 3156, 3, 10) then
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route1,{79776},50) --Beam > Bottom floor

        else
            WickedHoodTeleport()
        end
    end,

    [13016] = function()
        if Slib:IsPlayerInArea(3427, 2927, 0, 10) then
            Interact:NPC("Shiratti the Custodian", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(3400, 2918, 0, 5) then
            Slib:MoveTo(3427, 2927, 0)

        elseif Slib:IsPlayerInArea(3304, 3114, 0, 5) then
            Interact:NPC("Rug merchant", "Travel", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("MagicCarpet")
            end, 10, 100)
            Slib:RandomSleep(600, 1000, "ms")
            if InterfaceIsOpen("MagicCarpet") then
                Slib:TypeText("4") --Nardah option
                Slib:SleepUntil(function()
                    return Slib:FindObj2(3020, 50, 1, 3401, 2918, 0) ~= nil
                end, 15, 100)
                Slib:RandomSleep(6000, 10000, "ms")
                IdleCycles = 10
            end            

        elseif Slib:IsPlayerInArea(3304, 3122, 0, 5) then
            Interact:Object("Shantay Pass", "Go-through", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(3310, 3163, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3304, 2, 2), Slib:RandomNumber(3122, 2, 2), 0)

        elseif Slib:IsPlayerInArea(3297, 3184, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3310, 2, 2), Slib:RandomNumber(3163, 2, 2), 0)

        else
            LODESTONES.AL_KHARID.Teleport()
        end
    end,

    [13018] = function()
        if HasSlidePuzzle() then
            Interact:NPC("Trader Stan", "Talk-To", 10)

        elseif Slib:IsPlayerInArea(3033, 3192, 0, 3) then
            Interact:NPC("Trader Stan", "Talk-To", 10)

        elseif Slib:IsPlayerInArea(3011, 3215, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3033, 1, 1), Slib:RandomNumber(3192, 1, 1), 0)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [13020] = function()
        if Slib:IsPlayerInArea(2444, 3052, 0, 20) then
            Interact:NPC("Uglug Nar", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2444, 2, 2), Slib:RandomNumber(3052, 2, 2), 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [13022] = function()
        if Slib:IsPlayerInArea(2387, 4473, 0, 3) then
            Interact:NPC("Fairy Nuff", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2387, 4468, 0, 2) then
            if Slib:FindObj2(52474, 10, 12, 2387, 4469, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2387, 1, 1), Slib:RandomNumber(4472, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2452, 4473, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2387, 1, 1), Slib:RandomNumber(4468, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3199, 3169, 0, 10) then
            Interact:Object("Door", "Teleport Zanaris", 20)
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(3233, 3221, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3199, 2, 2), Slib:RandomNumber(3169, 2, 2), 0)

        else
            LODESTONES.LUMBRIDGE.Teleport()
        end
    end,

    [13024] = function()
        if HasSlidePuzzle() then
            Interact:NPC("Cam the Camel", "Talk-to", 10)

        elseif Slib:IsPlayerInArea(3284, 3232, 0, 20) then
            Interact:NPC("Cam the Camel", "Talk-to", 10)

        elseif Slib:IsPlayerInArea(3297, 3184, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3284, 1, 1), Slib:RandomNumber(3232, 1, 1), 0)

        else
            LODESTONES.AL_KHARID.Teleport()
        end
    end,

    [13026] = function()
        if Slib:IsPlayerInArea(2875, 9880, 0, 50) then
            Interact:NPC("Captain Ninto", "Talk to", 50)

        elseif Slib:IsPlayerInArea(2882, 3459, 0, 5) then
            Interact:Object("Cave", "Enter", 20)

        elseif Slib:IsPlayerInArea(2878, 3442, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2882, 2, 2), Slib:RandomNumber(3459, 2, 2), 0)

        else
            LODESTONES.TAVERLEY.Teleport()
        end
    end,

    [13028] = function()
        if Slib:IsPlayerInArea(2660, 3292, 0, 1) or Slib:IsPlayerInArea(2658, 3292, 0, 1) or Slib:IsPlayerInArea(2656, 3292, 0, 1)then
            Interact:NPC("Zenesha", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2660, 3295, 0, 3) then
            if Slib:FindObj2(34807, 10, 12, 2660, 3294, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:NPC("Zenesha", "Talk to", 20)
                IdleCycles = 20
            end

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2660, 1, 1), Slib:RandomNumber(3295, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [13030] = function()
        if Slib:IsPlayerInArea(2594, 9486, 0, 20) then
            Interact:NPC("Wizard Frumscone", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(2586, 3088, 0, 2) then
            if Interact:Object("Ladder", "Climb-down", 20) then
                Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(2594, 9486, 0, 20)
                end, 20, 100)
            end

        elseif Slib:IsPlayerInArea(2583, 3088, 0, 2) then
            Interact:Object("Magic guild door", "Open", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2583, 1, 1), Slib:RandomNumber(3088, 1, 1), 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [13032] = function()
        --Check if Blood Runs Deep quest is completed
        if API.GetVarbitValue(10871) < 147 then --If quest not completed the princess will be in another castle mario
            DestroyClue()
            return
        else
            if Slib:IsPlayerInArea(2506, 3860, 1, 20) then
                Interact:NPC("Queen Sigrid", "Talk-to", 20)

            else
                MiscellaniaTeleport()
            end
        end
    end,

    [13034] = function()
        if Slib:IsPlayerInArea(3363, 3503, 0, 20) then
            Interact:NPC("Odd Old Man", "Talk-to", 20)

        elseif Slib:IsPlayerInArea(3298, 3525, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3363, 2, 2), Slib:RandomNumber(3503, 2, 2), 0)

        else
            LODESTONES.FORT_FORINTHRY.Teleport()
        end
    end,

    [13036] = function()
        if Slib:IsPlayerAtCoords(2133, 5162, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerAtCoords(2120, 5099, 0) then
            Slib:MoveTo(2133, 5162, 0)

        elseif Slib:IsPlayerAtCoords(2120, 5098, 0) then
            Interact:Object("Gate", "Open", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2152, 5088, 0, 5) then
            Slib:MoveTo(2120, 5098, 0)

        elseif Slib:IsPlayerInArea(2149, 5089, 1, 5) then
            Interact:Object("Wooden Stair", "Climb-down", 20)

        elseif Slib:IsPlayerInArea(2162, 5114, 1, 5) then
            Slib:MoveTo(2149, 5089, 1)

        elseif Slib:IsPlayerInArea(3680, 3536, 0, 5) then
            Interact:NPC("Pirate Pete", "Quick travel", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3659, 3522, 0, 5) then
            Slib:MoveTo(3680, 3536, 0)            

        else
            EctophialTeleport()
        end
    end,

    [13038] = function()
        if Slib:IsPlayerAtCoords(2519, 3594, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2490, 3522, 0, 3) then
            Slib:MoveTo(2519, 3594, 0)

        elseif Slib:IsPlayerInArea(2486, 3513, 0, 5) then
            Interact:Object("Tree", "Climb", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2486, 1, 1), Slib:RandomNumber(3513, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3187, 3506, 0, 10) then
            Interact:Object("Spirit tree", "Teleport", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("SpiritTree")
            end, 6, 100)
            IdleCycles = 5
            if InterfaceIsOpen("SpiritTree") then 
                Slib:TypeText("2") --Tree gnome stronghold option
            end
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3162, 3462, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3187, 2, 2), Slib:RandomNumber(3506, 2, 2), 0)

        else
            GETeleport()
        end
    end,

    [13040] = function()
        if Slib:IsPlayerInArea(2668, 3243, 1, 20) then
            Interact:Object("Drawers", "Search", 20)

        elseif Slib:IsPlayerInArea(2663, 3240, 0, 3) then
            if Slib:FindObj2(126965, 10, 12, 2665, 3240, 6).Bool1 == 0 then
                Interact:Object("Large door", "Open", 20)
            else
                Interact:Object("Stairs", "Climb up", 20)
            end

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2663, 1, 1), Slib:RandomNumber(3240, 1, 1), 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [13041] = function()
        if Slib:IsPlayerInArea(2340, 3185, 0, 3) then
            Interact:Object("Crate", "Search", 10)
            
        elseif Slib:IsPlayerInArea(2330, 3172, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2340, 1, 1), Slib:RandomNumber(3185, 1, 1), 0)

        else
            CrystalSeedLletyaTeleport()
        end
    end,

    [13042] = function()
        if Slib:IsPlayerInArea(2969, 2974, 0, 1) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2925, 2951, 0, 3) then
            Slib:MoveTo(2969, 2974, 0)

        elseif Slib:IsPlayerInArea(2924, 2946, 0, 5) then
            Interact:Object("Stepping stones", "Cross", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2802, 2946, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2924, 1, 1), Slib:RandomNumber(2946, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2762, 3147, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2802, 1, 1), Slib:RandomNumber(2946, 1, 1), 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [13046] = function()
        if Slib:IsPlayerAtCoords(3395, 2917, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(3400, 2918, 0, 5) then
            Slib:MoveTo(3395, 2917, 0)

        elseif Slib:IsPlayerInArea(3304, 3114, 0, 5) then
            Interact:NPC("Rug merchant", "Travel", 20)
            Slib:SleepUntil(function()
                return InterfaceIsOpen("MagicCarpet")
            end, 10, 100)
            Slib:RandomSleep(600, 1000, "ms")
            if InterfaceIsOpen("MagicCarpet") then
                Slib:TypeText("4") --Nardah option
                Slib:SleepUntil(function()
                    return Slib:FindObj2(3020, 50, 1, 3401, 2918, 0) ~= nil
                end, 15, 100)
                Slib:RandomSleep(6000, 10000, "ms")
                IdleCycles = 10
            end            

        elseif Slib:IsPlayerInArea(3304, 3122, 0, 5) then
            Interact:Object("Shantay Pass", "Go-through", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(3310, 3163, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3304, 2, 2), Slib:RandomNumber(3122, 2, 2), 0)

        elseif Slib:IsPlayerInArea(3297, 3184, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3310, 2, 2), Slib:RandomNumber(3163, 2, 2), 0)

        else
            LODESTONES.AL_KHARID.Teleport()
        end
    end,

    [13048] = function()
        if Slib:IsPlayerInArea(2645, 3664, 0, 5) then
            if Slib:FindObj2(4247, 10, 12, 2645, 3663, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Crate", "Search", 20)
            end

        elseif Slib:IsPlayerInArea(2712, 3677, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2645, 1, 1), Slib:RandomNumber(3664, 1, 1), 0)

        else
            LODESTONES.FREMENNIK_PROVINCE.Teleport()
        end
    end,

    [13049] = function()
        if Slib:IsPlayerInArea(2993, 3687, 0, 2) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(2993, 3687, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [33269] = function()
        if Slib:IsPlayerAtCoords(2632, 3407, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2634, 3348, 0, 20) then
            Slib:MoveTo(2632, 3407, 0)

        else
            LODESTONES.ARDOUGNE.Teleport()
        end
    end,

    [33272] = function()
        if Slib:IsPlayerAtCoords(2895, 3398, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2878, 3442, 0, 20) then
            Slib:MoveTo(2895, 3398, 0)

        else
            LODESTONES.TAVERLEY.Teleport()
        end
    end,

    [33275] = function()
        if Slib:IsPlayerAtCoords(2888, 3044, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2761, 3147, 0, 20) then
            Slib:MoveTo(2888, 3044, 0)

        else
            LODESTONES.KARAMJA.Teleport()
        end
    end,

    [33278] = function()
        if Slib:IsPlayerAtCoords(2603, 3063, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2534, 3061, 0, 5) then
            Slib:MoveTo(2603, 3063, 0)

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2534, 1, 1), Slib:RandomNumber(3061, 1, 1), 0)

        else
            LODESTONES.YANILLE.Teleport()
        end
    end,

    [33281] = function()
        if Slib:IsPlayerAtCoords(2363, 3461, 0) then
            Familiars:CastSpecialAttack()

        elseif Slib:IsPlayerInArea(2366, 3479, 0, 20) then
            Slib:MoveTo(2363, 3461, 0)

        else
            LODESTONES.EAGLES_PEAK.Teleport()
        end
    end,

    [999999] = function()
        --This is here to prevent crashing if no clue is found
        Slib:Warn("No clue found; Maybe lag? Sleeping. This is attempt " .. Retries .. "/5.")
        Slib:RandomSleep(1000, 3000, "ms")
        Retries = Retries + 1
        if Retries > 5 then
            Slib:Error("Retries greater than 5. Exiting.")
            ReasonForStopping = "Retries greater than 5."
            API.Write_LoopyLoop(false)
            return
        end
    end
}

API.Write_fake_mouse_do(false)
while API.Read_LoopyLoop() do
    if IsFirstRun then
        if not OnlyOnceSafetyChecks() then
            API.Write_LoopyLoop(false)
            break
        end
        IsFirstRun = false
    end

    if not RecurringSafetyChecks() then
        API.Write_LoopyLoop(false)
        break
    end
    
    --Start skip checks
    if IdleCycles > 0 then
        Slib:Info("Idle cycles greater than 0. Skipping cycle.")
        goto continue
    elseif API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        Slib:Info("Player moving. Skipping cycle.")
        IdleCycles = 2
        goto continue
    elseif DialogBoxIsOpen() then
        if HasOption() then
            Slib:Info("Dialog box open. Has option. Selecting option.")
            OptionSelector(DialogOptions)
        else
            Slib:Info("Dialog box open. Sending spacebar and skipping cycle.")
            API.KeyboardPress2(0x20, 40, 60)
            goto continue
        end
    end
    --End skip checks

    --Death Check
    if Slib:FindObj(27299, 50, 1) ~= nil then
        Slib:Error("You dead, consider destroying the clue for step: " .. ClueStepId)
        ReasonForStopping = "Dead. Consider destroying the clue for step: " .. ClueStepId
        API.Write_LoopyLoop(false)
    end

    --Stuck in clue interface check
    if InterfaceIsOpen("ClueScroll") then
        API.DoAction_Interface(0x24,0xffffffff,1,345,13,-1,API.OFF_ACT_GeneralInterface_route) --Close clue scroll interface
    end

    --Wizard combat check
    if API.LocalPlayer_IsInCombat_() and not ShouldSkipCombat() then
        Slib:Info("Player in combat. Checking for wizard.")
        AttackWizards()
    end
    
    --Familiar check
    if Familiars:HasFamiliar() and Familiars:GetName() ~= "Meerkats" then
        Slib:Error("Familiar is not a meerkat. Exiting.")
        ReasonForStopping = "Familiar is not a meerkat."
        API.Write_LoopyLoop(false)
        goto continue
    elseif not Familiars:HasFamiliar() or Familiars:GetTimeRemaining() < 5 then
        if Inventory:ContainsAny(OtherIDsNeededForStuff["SuperRestores"]) then
            API.DoAction_Inventory2(OtherIDsNeededForStuff["SuperRestores"], 0, 1, API.OFF_ACT_GeneralInterface_route) --Drink super restore
            Slib:RandomSleep(600, 3000, "ms")
            API.DoAction_Inventory1(OtherIDsNeededForStuff["Meerkat"],0,1,API.OFF_ACT_GeneralInterface_route) --Summon meerkats
            Slib:RandomSleep(1200, 1800, "ms")
        else
            Slib:Error("No super restore found in inventory to renew familiar.")
            ReasonForStopping = "No super restore found in inventory to renew familiar."
            API.Write_LoopyLoop(false)
            goto continue
        end
    end    

    if not HasScrolls() then
       Slib:Error("No meerkat scrolls found. Exiting.")
       ReasonForStopping = "No meerkat scrolls found."
       API.Write_LoopyLoop(false)
       goto continue
    end

    --Slide puzzle check
    if HasSlidePuzzle() then
        SolveSlidePuzzle()
    end

    if not StoreHHItems then      
        ClueStepId = GetClueStepId()
    end

    Slib:Info("Clue step id: " .. ClueStepId)
    ClueSteps[ClueStepId]() 

    ::continue::
    IdleCycles = IdleCycles - 1
    StepItems = {}
    Slib:RandomSleep(200, 400, "ms")    
    collectgarbage("collect")
end

API.Write_LoopyLoop(false)
MetricsTable[7] = {"Reason for Stopping:", ReasonForStopping}
API.DrawTable(MetricsTable)
Slib:Info("----------//----------")
Slib:Info("Script Name: " .. ScriptName)
Slib:Info("Author: " .. Author)
Slib:Info("Version: " .. ScriptVersion)
Slib:Info("Release Date: " .. ReleaseDate)
Slib:Info("Discord: " .. DiscordHandle)
Slib:Info("----------//----------")
