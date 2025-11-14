ScriptName = "Unf Potion Maker"
Author = "Spectre011"
ScriptVersion = "1.0.1"
ReleaseDate = "24-02-2025"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0.0 - 24-02-2025
    - Initial release.
v1.0.0 - 14-11-2025
    - Renamed Discord variable to DiscordHandle
]]

local API = require("api")
local SpectreUtils = require("spectre")

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

--------------------START END TABLE STUFF--------------------
local EndTable = {
    {"-"}
}
EndTable[1] = {"Thanks for using my script!"}
EndTable[2] = {" "}
EndTable[3] = {"Script Name: ".. ScriptName}
EndTable[4] = {"Author: ".. Author}
EndTable[5] = {"Version: ".. ScriptVersion}
EndTable[6] = {"Release Date: ".. ReleaseDate}
EndTable[7] = {"Discord: ".. DiscordHandle}
--------------------END END TABLE STUFF--------------------

local PossibleCleanHerbs = {
    Guam =          249,
    Marrentill =    251,
    Tarromin =      253,
    Harralander =   255,
    Ranarr =        257,
    Irit =          259,
    Avantoe =       261,
    Kwuarm =        263,
    Cadantine =     265,
    Dwarfweed =     267,
    Torstol =       269,
    Lantadyme =     2481,
    Toadflax =      2998,
    Snapdragon =    3000,
    SpiritWeed =    12172,
    Fellstalk =     21624,
    Wergali =       14854,
    Bloodweed =     37953,
    Arbuck =        48211
}

local IDS = {
    Herb = 0,
    VialOfWater = 227
}

local function GetHerb()
    print("Entering function GetHerb().")
    for herbName, herbID in pairs(PossibleCleanHerbs) do
        if Inventory:Contains(herbID) then
            print("Found herb: " .. herbName .. " (ID: " .. herbID .. ")")
            return herbID
        end
    end
    print("No herb found in inventory.")
    return 0
end

local function LoadLastPreset()
    print("Trying Banker:")
    if Interact:NPC("Banker", "Load Last Preset from", 10) then
        print("Banker succeded.")
        return true
    else
        print("Banker failed.")
    end

    print("Trying Bank chest:")
    if Interact:Object("Bank chest", "Load Last Preset from", 10) then
        print("Bank chest succeded.")
        return true
    else
        print("Bank chest failed.")
    end

    print("Trying Bank booth")
    if Interact:Object("Bank booth", "Load Last Preset from", 10) then
        print("Bank booth succeded.")
        return true
    else
        print("Bank booth failed.")
    end

    print("Trying Counter")
    if Interact:Object("Counter", "Load Last Preset from", 10) then
        print("Counter succeded.")
        return true
    else
        print("Counter failed.")
    end

    return false
end

local stageID = 1
local StageDescriptions = {
    [1] = "Stage 1: Checking Step",
    [2] = "Stage 2: Crafting Potion",
    [3] = "Stage 3: Rebanking"
}

local stageFunctions = {
    [1] = function()
        print("Stage 1: Checking Step")
        UpdateStatus("Checking Step")
        print("Getting Herb ID...")
        IDS.Herb = GetHerb()
        print("Herb ID: " .. tostring(IDS.Herb))
    
        if not Inventory:Contains(IDS.VialOfWater) then
            print("Vial of Water not found in inventory. Moving to Stage 3.")
            stageID = 3
            return
        end
    
        if IDS.Herb == 0 then
            print("No valid Herb found. Moving to Stage 3.")
            stageID = 3
        else
            print("Valid Herb found. Moving to Stage 2.")
            stageID = 2
        end
    end,
    
    [2] = function()
        print("Stage 2: Crafting Potion")
        UpdateStatus("Crafting Potion")
        print("Using Herb on Vial of Water...")
        Inventory:UseItemOnItem(IDS.Herb, IDS.VialOfWater)
    
        local startTime = os.time()
        local timeout = 3
        print("Waiting for crafting interface to open (max 3 seconds)...")
        while API.Read_LoopyLoop() and API.VB_FindPSett(2874, 1, 0).state ~= 1310738 do -- Crafting interface
            if os.time() - startTime >= timeout then
                print("Timeout reached while waiting for crafting interface. Proceeding...")
                break
            end
            SpectreUtils.Sleep(0.1)
        end
    
        SpectreUtils.Sleep(0.2)
        print("Pressing spacebar to confirm crafting...")
        API.KeyboardPress2(0x20, 40, 60)
        SpectreUtils.Sleep(2)
    
        local startTime2 = os.time()
        local timeout2 = 20
        print("Waiting for crafting to complete (max 20 seconds)...")
        while API.Read_LoopyLoop() and Inventory:Contains(IDS.Herb) and Inventory:Contains(IDS.VialOfWater) do
            if os.time() - startTime2 >= timeout2 then
                print("Timeout reached while waiting for crafting to complete. Proceeding...")
                break
            end
            if not API.isProcessing() then
                print("Processing window closed.")
                break
            end
            SpectreUtils.Sleep(0.1)
        end
    
        print("Crafting process complete.")
        print("Moving to Stage 3.")
        stageID = 1
    end,

    [3] = function()
        print("Stage 3: Rebanking")
        UpdateStatus("Rebanking")
        print("Attempting to load last preset...")
    
        if not LoadLastPreset() then
            print("Unable to rebank. Exiting script.")
            API.Write_LoopyLoop(false)
            return
        end
    
        local startTime = os.time()
        local timeout = 10
        local hasVialOfWater = false
        local hasHerb = false
    
        print("Waiting for rebank to complete (max 10 seconds)...")
    
        while API.Read_LoopyLoop() do
            hasVialOfWater = Inventory:Contains(IDS.VialOfWater)
            hasHerb = false

            for herbName, herbID in pairs(PossibleCleanHerbs) do
                if Inventory:Contains(herbID) then
                    hasHerb = true
                    print("Found herb: " .. herbName .. " (ID: " .. herbID .. ")")
                    break
                end
            end
    
            if hasVialOfWater and hasHerb then
                print("Rebank successful. Vials of water and herbs found in inventory.")
                break
            end

            if os.time() - startTime >= timeout then
                if not hasVialOfWater and not hasHerb then
                    print("Rebank failed. No vials of water and no herbs found in inventory.")
                elseif not hasVialOfWater then
                    print("Rebank failed. No vials of water found in inventory.")
                elseif not hasHerb then
                    print("Rebank failed. No herbs found in inventory.")
                end
                API.Write_LoopyLoop(false)
                break
            end
    
            SpectreUtils.Sleep(0.1)
        end
    
        print("Moving back to Stage 1.")
        stageID = 1
    end
}

local function executeStage(stageID)
    if stageFunctions[stageID] then
        stageFunctions[stageID]()
    else
        print("Invalid stage ID: " .. tostring(stageID))
    end
end

Write_fake_mouse_do(false)
while (API.Read_LoopyLoop()) do    
    executeStage(stageID)
    collectgarbage("collect")
end

API.Write_LoopyLoop(false)
API.DrawTable(EndTable)
print("----------//----------")
print("Script Name: " .. ScriptName)
print("Author: " .. Author)
print("Version: " .. ScriptVersion)
print("Release Date: " .. ReleaseDate)
print("Discord: " .. DiscordHandle)
print("----------//----------")
