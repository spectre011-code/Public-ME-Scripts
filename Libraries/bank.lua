local ScriptName = "Bank Toolbox"
local Author = "Spectre011"
local ScriptVersion = "1.2.0"
local ReleaseDate = "02-05-2025"
local DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0.0 - 02-05-2025
    - Initial release.
v1.0.1 - 02-05-2025
    - Forgot to add changelog.
v1.0.2 - 02-05-2025
    - Renamed some functions to be more similar to other ME functions.
v1.0.3 - 02-05-2025
    - More renames.
    - Removed empty lines.
v1.0.4 - 04-05-2025
    - Edited credits variables to be local to prevent some funny interactions with my other scripts.
    - Added functions: 
        BANK:GetTransferTab()
        BANK:SetTransferTab()
        BANK:PresetSettingsIsOpen()
        BANK:PresetSettingsOpen()
        BANK:PresetSettingsReturnToBank()
        BANK:PresetSettingsGetSelectedPreset()
        BANK:PresetSettingsSelectPreset()
        BANK:PresetSettingsGetInventory()
        BANK:PresetSettingsGetEquipment()
        BANK:PrintInventory()
    - Edited relevant functions to check for transfer/preset tabs.
    - Edited some prints to be more descriptive.
v1.0.5 - 06-05-2025
    - Functions now use : instead of .
    - Modified tables to be inside the BANK table.
    - Modified functions to use the tables with the atribute self.
    - Modified functions BANK:PresetSettingsGetEquipment() and BANK:PresetSettingsGetInventory() to include the item name.
    - Added function BANK:PresetSettingsGetCheckBox().
    - Added function BANK:PresetSettingsSetCheckBox().
    - Renamed some functions to be more descriptive of their class.
    - Reordered function by class:
        General bank
        Deposit box
        Collection box
        Preset settings
v1.0.6 - 08-05-2025
    - Fixed VB read in BANK:GetOpenedTab().
    - Fixed VB read in BANK:GetQuantitySelected().
    - Fixed typos in BANK:WithdrawToBoB() and BANK:Withdraw().
    - Fixed typos for Head Guard in BANK:Open().
    - Added Head Guard to BANK:LoadLastPreset().
v1.0.7 - 19-05-2025
    - BANK:Contains() and BANK:InventoryContains() now accepts number and table.
    - Added functions:
        BANK:ContainsAny()
        BANK:InventoryContainsAny()
        BANK:EquipmentContains()
        BANK:EquipmentContainsAny()
v1.0.8 - 07-06-2025
    - Added functions:
        BANK:Withdraw1()
        BANK:Withdraw5()
        BANK:Withdraw10()
        BANK:WithdrawX()
        BANK:WithdrawAll()
        BANK:Deposit1()
        BANK:Deposit5()
        BANK:Deposit10()
        BANK:DepositX()
        BANK:DepositAll()
v1.0.9 - 14-06-2025
    - Change some functions params descriptions to remove warnings.
    - Added functions:
        BANK:IsPINOpen()
        BANK:EnterPIN()
        BANK:GetTotalSpaces()
        BANK:GetUsedSpaces()
        BANK:GetFreeSpaces()
        BANK:GetItemAmount()
        BANK:InventoryGetItemAmount()
        BANK:EquipmentGetItemAmount()        
        BANK:DepositBoxContains()
        BANK:DepositBoxGetSlot()
        BANK:DepositBoxDeposit1()
        BANK:DepositBoxDeposit5()
        BANK:DepositBoxDeposit10()
        BANK:DepositBoxDepositAll2()  
        BANK:Close()      
        BANK:DepositBoxClose()
        BANK:CollectionBoxClose()
v1.0.10 - 25-06-2025
    - Added functions:
        BANK:WoodBoxDepositLogs()
        BANK:WoodBoxDepositWoodSpirits()
        BANK:OreBoxDepositOres()
        BANK:OreBoxDepositStoneSpirits()
v1.0.11 - 26-06-2025
    - Added function:
        BANK:SoilBoxDepositSoil()
v1.1.0 - 06-08-2025
    - Added bank table BANK.Banks
    - Added function:
        GetNearestBank()
    - Changed functions BANK:Open(), BANK:LoadLastPreset() and BANK:CollectionBoxOpen() to use the nearest bank.
v1.2.0 - 99-99-2025
    - Added banks:
        Emerald Benedict
        Gundai
        Dead man's chest
]]

local API = require("api")

local BANK = {}

BANK.Banks = {
    {Name = "Gundai", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "NPC"},
    {Name = "Banker", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "NPC"},
    {Name = "Head Guard", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "NPC"},
    {Name = "Gnome Banker", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "NPC"},
    {Name = "Emerald Benedict", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "NPC"},

    {Name = "Counter", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "Object"},
    {Name = "Bank chest", OpenAction = "Use", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "Object"},
    {Name = "Bank booth", OpenAction = "Bank", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "Object"},    
    {Name = "Dead man's chest", OpenAction = "Use", LoadLastPresetAction = "Load Last Preset from", CollectionBoxAction = "Collect", InteractType = "Object"}
}

BANK.Interfaces = {}

BANK.Interfaces.PIN = { 
    { 759,5,-1,0 } 
}

BANK.Interfaces.BankSpaces = {
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,230,-1,0 }, { 517,231,-1,0 }, { 517,245,-1,0 }, { 517,246,-1,0 }, { 517,249,-1,0 } }, --Used space
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,230,-1,0 }, { 517,231,-1,0 }, { 517,245,-1,0 }, { 517,246,-1,0 }, { 517,250,-1,0 } } --Total space
}

BANK.Interfaces.DepositBoxSlots = {
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,0,0 } }, --slot 1
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,1,0 } }, --slot 2
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,2,0 } }, --slot 3
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,3,0 } }, --slot 4
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,4,0 } }, --slot 5
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,5,0 } }, --slot 6
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,6,0 } }, --slot 7
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,7,0 } }, --slot 8
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,8,0 } }, --slot 9
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,9,0 } }, --slot 10
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,10,0 } }, --slot 11
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,11,0 } }, --slot 12
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,12,0 } }, --slot 13
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,13,0 } }, --slot 14
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,14,0 } }, --slot 15
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,15,0 } }, --slot 16
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,16,0 } }, --slot 17
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,17,0 } }, --slot 18
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,18,0 } }, --slot 19
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,19,0 } }, --slot 20
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,20,0 } }, --slot 21
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,21,0 } }, --slot 22
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,22,0 } }, --slot 23
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,23,0 } }, --slot 24
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,24,0 } }, --slot 25
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,25,0 } }, --slot 26
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,26,0 } }, --slot 27
    { { 11,16,-1,0 }, { 11,18,-1,0 }, { 11,19,-1,0 }, { 11,19,27,0 } } --slot 28
} 

BANK.Interfaces.CollectionBoxSlots = { -- https://imgur.com/WN60RRo. 
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,15,-1,0 }, { 109,14,-1,0 }, { 109,14,1,0 } }, -- Slot 1
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,15,-1,0 }, { 109,14,-1,0 }, { 109,14,3,0 } }, -- Slot 2

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,21,-1,0 }, { 109,12,-1,0 }, { 109,12,1,0 } }, -- Slot 3
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,21,-1,0 }, { 109,12,-1,0 }, { 109,12,3,0 } }, -- Slot 4

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,22,-1,0 }, { 109,10,-1,0 }, { 109,10,1,0 } }, -- Slot 5
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,22,-1,0 }, { 109,10,-1,0 }, { 109,10,3,0 } }, -- Slot 6

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,23,-1,0 }, { 109,7,-1,0 }, { 109,7,1,0 } }, -- Slot 7
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,23,-1,0 }, { 109,7,-1,0 }, { 109,7,3,0 } }, -- Slot 8

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,24,-1,0 }, { 109,4,-1,0 }, { 109,4,1,0 } }, -- Slot 9
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,24,-1,0 }, { 109,4,-1,0 }, { 109,4,3,0 } }, -- Slot 10

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,25,-1,0 }, { 109,1,-1,0 }, { 109,1,1,0 } }, -- Slot 11
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,25,-1,0 }, { 109,1,-1,0 }, { 109,1,3,0 } }, -- Slot 12

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,26,-1,0 }, { 109,62,-1,0 }, { 109,62,1,0 } }, -- Slot 13
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,26,-1,0 }, { 109,62,-1,0 }, { 109,62,3,0 } }, -- Slot 14

    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,27,-1,0 }, { 109,67,-1,0 }, { 109,67,1,0 } }, -- Slot 15
    { { 109,37,-1,0 }, { 109,39,-1,0 }, { 109,27,-1,0 }, { 109,67,-1,0 }, { 109,67,3,0 } } -- Slot 16
}

BANK.Interfaces.PresetSettings = {}

BANK.Interfaces.PresetSettings.Inventory = { 
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,0,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,1,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,2,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,3,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,4,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,5,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,6,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,7,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,8,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,9,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,10,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,11,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,12,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,13,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,14,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,15,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,16,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,17,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,18,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,19,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,20,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,21,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,22,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,23,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,24,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,25,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,26,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,277,-1,0 }, { 517,280,-1,0 }, { 517,280,27,0 } }
}

BANK.Interfaces.PresetSettings.Equipment = {
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,0,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,1,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,2,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,3,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,4,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,5,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,7,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,9,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,10,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,12,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,13,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,14,0 } },
    { { 517,0,-1,0 }, { 517,2,-1,0 }, { 517,153,-1,0 }, { 517,261,-1,0 }, { 517,262,-1,0 }, { 517,281,-1,0 }, { 517,283,-1,0 }, { 517,284,-1,0 }, { 517,286,-1,0 }, { 517,290,-1,0 }, { 517,290,17,0 } }
}

BANK.Items = {}

BANK.Items.OreBoxes = {
    44779, -- Bronze
    44781, -- Iron
    44783, -- Steel
    44785, -- Mithril
    44787, -- Adamant
    44789, -- Rune
    44791, -- Orikalkum
    44793, -- Necronium
    44795, -- Bane
    44797, -- Elder rune
    57172 -- Primal
}

BANK.Items.WoodBoxes = {
    54895, -- Wood
    54897, -- Oak
    54899, -- Willow
    54901, -- Teak
    54903, -- Maple
    54905, -- Acadia
    54907, -- Mahogany
    54909, -- Yew
    54911, -- Magic
    54913, -- Elder
    58253 -- Eternal magic
}

-- ##################################
-- #                                #
-- #     GENERAL BANK FUNCTIONS     #
-- #                                #
-- ##################################

-- Returns the nearest bank's name, open action, load preset action, collection box action, and interact type.
---@return table | false -- {name, OpenAction, LoadLastPresetAction, CollectionBoxAction, InteractType} or false
local function GetNearestBank()
    local BankNames = {}
    for _, bank in ipairs(BANK.Banks) do
        table.insert(BankNames, bank.Name)
    end
    
    local AllBanks = API.GetAllObjArrayInteract_str(BankNames, 50, {0, 1, 12})
    
    if not AllBanks or #AllBanks == 0 then
        return false
    end
    
    local NearestBank = nil
    local ShortestDistance = math.huge
    
    for _, bank in ipairs(AllBanks) do
        if bank.Distance and bank.Distance < ShortestDistance then
            ShortestDistance = bank.Distance
            NearestBank = bank
        end
    end
    
    if not NearestBank then
        return false
    end

    for _, BankData in ipairs(BANK.Banks) do
        if BankData.Name == NearestBank.Name then
            print("[BANK] Nearest bank found:", BankData.Name)
            return {
                name = BankData.Name,
                OpenAction = BankData.OpenAction,
                LoadLastPresetAction = BankData.LoadLastPresetAction,
                CollectionBoxAction = BankData.CollectionBoxAction,
                InteractType = BankData.InteractType
            }
        end
    end

    return false
end

-- Check if Bank interface is open.
---@return boolean
function BANK:IsOpen()
    if API.VB_FindPSettinOrder(2874, 0).state == 24 then
        print("[BANK] Bank interface open.")
        return true
    else
        print("[BANK] Bank interface is not open.")
        return false
    end
end

-- Attempts to open your bank using the nearest bank. Requires cache enabled https://imgur.com/5I9a46V.
---@return boolean
function BANK:Open()
    print("[BANK] Opening nearest bank:")
    local NearestBank = GetNearestBank()
    
    if not NearestBank then
        print("[BANK] No bank found nearby or no matching bank in configuration.")
        return false
    end

    local success = false
    
    if NearestBank.InteractType == "NPC" then
        success = Interact:NPC(NearestBank.name, NearestBank.OpenAction, 50)
    elseif NearestBank.InteractType == "Object" then
        success = Interact:Object(NearestBank.name, NearestBank.OpenAction, 50)
    end
    
    if success then
        print("[BANK] " .. NearestBank.name .. " succeeded.")
        return true
    end
    
    print("[BANK] Could not interact with " .. NearestBank.name)
    return false
end

-- Attempts to close the bank interface.
---@return boolean
function BANK:Close()
    if BANK:IsOpen() then
        print("[BANK] Closing bank.")
        return API.DoAction_Interface(0x24,0xffffffff,1,517,318,-1,API.OFF_ACT_GeneralInterface_route)
    else
        print("[BANK] Bank not open.")
        return false
    end    
end

-- Attempts to load the last bank preset using the nearest bank. Requires cache enabled https://imgur.com/5I9a46V.
---@return boolean
function BANK:LoadLastPreset()
    print("[BANK] Loading last preset from nearest bank:")
    local NearestBank = GetNearestBank()
    
    if not NearestBank then
        print("[BANK] No bank found nearby or no matching bank in configuration.")
        return false
    end

    local success = false
    
    if NearestBank.InteractType == "NPC" then
        success = Interact:NPC(NearestBank.name, NearestBank.LoadLastPresetAction, 50)
    elseif NearestBank.InteractType == "Object" then
        success = Interact:Object(NearestBank.name, NearestBank.LoadLastPresetAction, 50)
    end
    
    if success then
        print("[BANK] " .. NearestBank.name .. " succeeded.")
        return true
    end
    
    print("[BANK] Could not load preset from " .. NearestBank.name)
    return false
end

-- Check if PIN interface is open.
---@return boolean
function BANK:IsPINOpen()
    local pin = API.ScanForInterfaceTest2Get(true, self.Interfaces.PIN)
    if #pin > 0 then
        print("[BANK] Bank PIN interface open.")
        return true
    else
        print("[BANK] Bank PIN interface is not open.")
        return false
    end
end

-- Insets the bank pin.
---@param digit1 number
---@param digit2 number
---@param digit3 number
---@param digit4 number
---@return boolean
function BANK:EnterPIN(digit1, digit2, digit3, digit4)
    local digits = {digit1, digit2, digit3, digit4}

    if not BANK:IsPINOpen() then
        print("[BANK] PIN interface is not open.")
        return false
    end

    for i, digit in ipairs(digits) do
        if type(digit) ~= "number" then
            print("[BANK] Error: Digit " .. i .. " must be a number, got " .. type(digit))
            return false
        end
        if digit < 0 or digit > 9 or digit ~= math.floor(digit) then
            print("[BANK] Error: Digit " .. i .. " must be an integer between 0-9, got " .. tostring(digit))
            return false
        end
    end  
    
    print("[BANK] Entering PIN: " .. digit1 .. digit2 .. digit3 .. digit4)
    for i, digit in ipairs(digits) do
        if i <= 3 then
            local interface_id = digit * 5 + 10
            API.DoAction_Interface(0xffffffff,0xffffffff,1,759,interface_id,-1,API.OFF_ACT_GeneralInterface_route)
        else
            local interface_id = digit + 5
            API.DoAction_Interface(0xffffffff,0xffffffff,0,13,interface_id,-1,API.OFF_ACT_GeneralInterface_Choose_option)
        end
        print("[BANK] Entered digit " .. i .. ": " .. digit)
        API.RandomSleep2(1000, 1000, 1000)
    end

    API.RandomSleep2(500, 750, 1000)
    
    return true
end

-- Get the total number of spaces in the bank.
---@return number
function BANK:GetTotalSpaces()
    local TotalSpace = API.ScanForInterfaceTest2Get(false, self.Interfaces.BankSpaces[2])
    local CleanText = string.gsub(TotalSpace[1].textids, ",", "")
    local SpaceCount = tonumber(CleanText)
    
    if not SpaceCount then
        print("[BANK] Error: Could not convert space text to number: " .. tostring(CleanText))
        return 0
    end
    
    print("[BANK] Total spaces: " .. tostring(SpaceCount))
    return SpaceCount
end

-- Get the total number of items in the bank.
---@return number
function BANK:GetUsedSpaces()
    local TotalItems = API.ScanForInterfaceTest2Get(false, self.Interfaces.BankSpaces[1])    
    local CleanText = string.gsub(TotalItems[1].textids, ",", "")
    local ItemCount = tonumber(CleanText)
    
    if not ItemCount then
        print("[BANK] Error: Could not convert items text to number: " .. tostring(CleanText))
        return 0
    end
    
    print("[BANK] Total items: " .. tostring(ItemCount))
    return ItemCount
end

-- Get the total number of free spaces in the bank.
---@return number
function BANK:GetFreeSpaces()
    local TotalSpaces = BANK:GetTotalSpaces()
    local TotalItems = BANK:GetUsedSpaces()    
    local FreeSpaces = TotalSpaces - TotalItems
    
    print("[BANK] Free spaces calculation: " .. TotalSpaces .. " - " .. TotalItems .. " = " .. FreeSpaces)
    return FreeSpaces
end

-- Checks if item is equipped.
---@param ItemID number
---@return boolean
function BANK:IsEquipped(ItemID)
    if type(ItemID) ~= "number" then
        print("[BANK] Error: Expected a number, got "..tostring(ItemID).." ("..type(ItemID)..")")
        return false
    end
    local Items = API.Container_Get_all(94)
    local FoundItem = false

    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or there are none.")
        return false
    end

    for _, item in ipairs(Items) do
        if item.item_id and item.item_id == ItemID and item.item_stack > 0 then
            FoundItem = true
        end
    end

    if FoundItem then
        print("[BANK] Item ID: "..ItemID.." found in equipment.")
    else
        print("[BANK] Item ID: "..ItemID.." not found in equipment.")
    end

    return FoundItem
end

-- Checks if bank has item(s).
---@param ItemID number|table
---@return boolean
function BANK:Contains(ItemID)
    local itemIds = {}
    
    -- Handle single number input
    if type(ItemID) == "number" then
        table.insert(itemIds, ItemID)
    -- Handle table input
    elseif type(ItemID) == "table" then
        for _, id in pairs(ItemID) do
            if type(id) == "number" then
                table.insert(itemIds, id)
            else
                print("[BANK] Error: Expected a table of numbers, got a table containing "..tostring(id).." ("..type(id)..").")
                return false
            end
        end
    else
        print("[BANK] Error: Expected a number or table of numbers, got "..tostring(ItemID).." ("..type(ItemID)..").")
        return false
    end
    
    local Items = API.Container_Get_all(95)
    local foundItems = {}
    
    if not Items or #Items == 0 then
        print("[BANK] Could not read bank items or there are none.")
        return false
    end

    for _, id in ipairs(itemIds) do
        foundItems[id] = false
    end
    
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 and foundItems[item.item_id] ~= nil then
            foundItems[item.item_id] = true
        end
    end

    local allFound = true
    local someFound = false
    local resultMessage = "[BANK] Item search results:"
    
    for _, id in ipairs(itemIds) do
        if foundItems[id] then
            resultMessage = resultMessage.."\n- ID: "..id.." FOUND."
            someFound = true
        else
            resultMessage = resultMessage.."\n- ID: "..id.." NOT FOUND."
            allFound = false
        end
    end
    
    print(resultMessage)

    return allFound
end

-- Checks if bank has any of the requested item(s).
---@param ItemID number|table
---@return boolean
function BANK:ContainsAny(ItemID)
    local itemIds = {}
    
    -- Handle single number input
    if type(ItemID) == "number" then
        table.insert(itemIds, ItemID)
    -- Handle table input
    elseif type(ItemID) == "table" then
        for _, id in pairs(ItemID) do
            if type(id) == "number" then
                table.insert(itemIds, id)
            else
                print("[BANK] Error: Expected a table of numbers, got a table containing "..tostring(id).." ("..type(id)..").")
                return false
            end
        end
    else
        print("[BANK] Error: Expected a number or table of numbers, got "..tostring(ItemID).." ("..type(ItemID)..").")
        return false
    end
    
    local Items = API.Container_Get_all(95)
    
    if not Items or #Items == 0 then
        print("[BANK] Could not read bank items or there are none.")
        return false
    end

    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            for _, id in ipairs(itemIds) do
                if item.item_id == id then
                    print("[BANK] Item ID: "..id.." found in BANK.")
                    return true
                end
            end
        end
    end
    
    print("[BANK] None of the requested items found in BANK.")
    return false
end

-- Get the amount of the requested item in the bank.
---@param ItemID number
---@return number|boolean
function BANK:GetItemAmount(ItemID)
    if type(ItemID) ~= "number" then
        print("[BANK] Error: Expected a number for ItemID, got " .. type(ItemID))
        return false
    end
    
    local Items = API.Container_Get_all(95)
    local amount = 0

    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 and item.item_id == ItemID then
            amount = amount + item.item_stack
            print("[BANK] Found stack of " .. item.item_stack .. " (total: " .. amount .. ")")
        end
    end
    
    if amount > 0 then
        print("[BANK] Total amount of item ID " .. ItemID .. ": " .. amount)
    else
        print("[BANK] Item ID " .. ItemID .. " not found in bank.")
    end
    
    return amount
end

-- Checks if inventory has item(s).
---@param ItemID number|table
---@return boolean
function BANK:InventoryContains(ItemID)
    local itemIds = {}
    
    -- Handle single number input
    if type(ItemID) == "number" then
        table.insert(itemIds, ItemID)
    -- Handle table input
    elseif type(ItemID) == "table" then
        for _, id in pairs(ItemID) do
            if type(id) == "number" then
                table.insert(itemIds, id)
            else
                print("[BANK] Error: Expected a table of numbers, got a table containing "..tostring(id).." ("..type(id)..").")
                return false
            end
        end
    else
        print("[BANK] Error: Expected a number or table of numbers, got "..tostring(ItemID).." ("..type(ItemID)..").")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    local foundItems = {}
    
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or there are none.")
        return false
    end

    for _, id in ipairs(itemIds) do
        foundItems[id] = false
    end

    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 and foundItems[item.item_id] ~= nil then
            foundItems[item.item_id] = true
        end
    end

    local allFound = true
    local resultMessage = "[BANK] Item search results:"
    
    for _, id in ipairs(itemIds) do
        if foundItems[id] then
            resultMessage = resultMessage.."\n- ID: "..id.." FOUND."
        else
            resultMessage = resultMessage.."\n- ID: "..id.." NOT FOUND."
            allFound = false
        end
    end
    
    print(resultMessage)
    
    return allFound
end

-- Get the amount of the requested item in the inventory.
---@param ItemID number
---@return number|boolean
function BANK:InventoryGetItemAmount(ItemID)
    if type(ItemID) ~= "number" then
        print("[BANK] Error: Expected a number for ItemID, got " .. type(ItemID))
        return false
    end
    
    local Items = API.Container_Get_all(93)
    local amount = 0

    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 and item.item_id == ItemID then
            amount = amount + item.item_stack
            print("[BANK] Found stack of " .. item.item_stack .. " (total: " .. amount .. ")")
        end
    end
    
    if amount > 0 then
        print("[BANK] Total amount of item ID " .. ItemID .. ": " .. amount)
    else
        print("[BANK] Item ID " .. ItemID .. " not found in inventory.")
    end
    
    return amount
end

-- Checks if inventory has any of the requested item(s).
---@param ItemID number|table
---@return boolean
function BANK:InventoryContainsAny(ItemID)
    local itemIds = {}
    
    -- Handle single number input
    if type(ItemID) == "number" then
        table.insert(itemIds, ItemID)
    -- Handle table input
    elseif type(ItemID) == "table" then
        for _, id in pairs(ItemID) do
            if type(id) == "number" then
                table.insert(itemIds, id)
            else
                print("[BANK] Error: Expected a table of numbers, got a table containing "..tostring(id).." ("..type(id)..").")
                return false
            end
        end
    else
        print("[BANK] Error: Expected a number or table of numbers, got "..tostring(ItemID).." ("..type(ItemID)..").")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or there are none.")
        return false
    end

    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            for _, id in ipairs(itemIds) do
                if item.item_id == id then
                    print("[BANK] Item ID: "..id.." found in inventory.")
                    return true
                end
            end
        end
    end

    print("[BANK] None of the requested items found in inventory.")
    return false
end

-- Checks if equipment has item(s).
---@param ItemID number|table
---@return boolean
function BANK:EquipmentContains(ItemID)
    local itemIds = {}
    
    -- Handle single number input
    if type(ItemID) == "number" then
        table.insert(itemIds, ItemID)
    -- Handle table input
    elseif type(ItemID) == "table" then
        for _, id in pairs(ItemID) do
            if type(id) == "number" then
                table.insert(itemIds, id)
            else
                print("[BANK] Error: Expected a table of numbers, got a table containing "..tostring(id).." ("..type(id)..").")
                return false
            end
        end
    else
        print("[BANK] Error: Expected a number or table of numbers, got "..tostring(ItemID).." ("..type(ItemID)..").")
        return false
    end
    
    local Items = API.Container_Get_all(94)
    local foundItems = {}
    
    if not Items or #Items == 0 then
        print("[BANK] Could not read equipment items or there are none.")
        return false
    end

    for _, id in ipairs(itemIds) do
        foundItems[id] = false
    end
    
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 and foundItems[item.item_id] ~= nil then
            foundItems[item.item_id] = true
        end
    end
    
    local allFound = true
    local resultMessage = "[BANK] Item search results:"
    
    for _, id in ipairs(itemIds) do
        if foundItems[id] then
            resultMessage = resultMessage.."\n- ID: "..id.." FOUND."
        else
            resultMessage = resultMessage.."\n- ID: "..id.." NOT FOUND."
            allFound = false
        end
    end
    
    print(resultMessage)
    
    return allFound
end

-- Checks if equipment has any of the requested item(s).
---@param ItemID number|table
---@return boolean
function BANK:EquipmentContainsAny(ItemID)
    local itemIds = {}
    
    -- Handle single number input
    if type(ItemID) == "number" then
        table.insert(itemIds, ItemID)
    -- Handle table input
    elseif type(ItemID) == "table" then
        for _, id in pairs(ItemID) do
            if type(id) == "number" then
                table.insert(itemIds, id)
            else
                print("[BANK] Error: Expected a table of numbers, got a table containing "..tostring(id).." ("..type(id)..").")
                return false
            end
        end
    else
        print("[BANK] Error: Expected a number or table of numbers, got "..tostring(ItemID).." ("..type(ItemID)..").")
        return false
    end
    
    local Items = API.Container_Get_all(94)
    
    if not Items or #Items == 0 then
        print("[BANK] Could not read equipment items or there are none.")
        return false
    end
    
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            for _, id in ipairs(itemIds) do
                if item.item_id == id then
                    print("[BANK] Item ID: "..id.." found in equipment.")
                    return true
                end
            end
        end
    end

    print("[BANK] None of the requested items found in equipment.")
    return false
end

-- Get the amount of the requested item in equipment.
---@param ItemID number
---@return number|boolean
function BANK:EquipmentGetItemAmount(ItemID)
    if type(ItemID) ~= "number" then
        print("[BANK] Error: Expected a number for ItemID, got " .. type(ItemID))
        return false
    end
    
    local Items = API.Container_Get_all(94)
    local amount = 0

    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 and item.item_id == ItemID then
            amount = amount + item.item_stack
            print("[BANK] Found stack of " .. item.item_stack .. " (total: " .. amount .. ")")
        end
    end
    
    if amount > 0 then
        print("[BANK] Total amount of item ID " .. ItemID .. ": " .. amount)
    else
        print("[BANK] Item ID " .. ItemID .. " not found in equipment.")
    end
    
    return amount
end

-- Get the player tab opened in the bank(Inventory, Equipment or Beast of burden).
---@return number|boolean
function BANK:GetOpenedTab()
    local VB = API.VB_FindPSettinOrder(6680).state & 0x3
    if VB == 0 then
        print("[BANK] Inventory tab is opened.")
        return 1
    elseif VB == 1 then
        print("[BANK] Beast of burden tab is opened.")
        return 2
    elseif VB == 2 then
        print("[BANK] Equipment tab is opened.")
        return 3
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:GetOpenedTab()")
        local var = API.VB_FindPSettinOrder(6680)
        print("--------------------------")
        print("state: " .. var.state)
        print("addr: " .. var.addr)
        print("indexaddr_orig: " .. var.indexaddr_orig)
        print("id: " .. var.id)
        print("--------------------------")
        return false
    end
end

--Open the specified player tab inside the bank(1 = Inventory, 2 = Beast of burden and 3 = Equipment).
---@param tabID number
---@return boolean
function BANK:OpenTab(tabID)
    print("[BANK] Opening tab: "..tostring(tabID)..".")
    if type(tabID) ~= "number" then
        print("[BANK] Error: Expected a number, got "..tostring(tabID).." ("..type(tabID)..")")
        return false
    end
    
    if tabID < 1 or tabID > 3 then
        print("[BANK] Error: Can only accept numbers 1 to 3, you passed: "..tostring(tabID))
        return false
    end

    if tabID == 1 then
        if BANK:GetOpenedTab() == 1 then
            print("[BANK] Inventory tab already open. No action needed.")
            return true
        else
            print("[BANK] Opening inventory tab.")
            API.DoAction_Interface(0x24,0xffffffff,1,517,56,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    elseif tabID == 2 then
        if BANK:GetOpenedTab() == 2 then
            print("[BANK] Beast of burden tab already open. No action needed.")
            return true
        else
            print("[BANK] Opening Beast of burden tab.")
            API.DoAction_Interface(0x24,0xffffffff,1,517,64,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    elseif tabID == 3 then
        if BANK:GetOpenedTab() == 3 then
            print("[BANK] Equipment tab open. No action needed.")
            return true
        else
            print("[BANK] Opening Equipment tab.")
            API.DoAction_Interface(0x24,0xffffffff,1,517,60,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:OpenTab()")
        print("--------------------------")
        print("Value passed: "..tostring(tabID))
        print("Return GetOpenedTab(): "..tostring(BANK:GetOpenedTab()))
        print("--------------------------")
        return false
    end
end

-- Get transfer or preset tab. 0 = transfer and 1 = preset.
---@return number|boolean
function BANK:GetTransferTab()
    local VB = API.VB_FindPSettinOrder(6680).state >> 12
    if VB == 0 then
        print("[BANK] Bank is showing transfer.")
        return 0
    elseif VB == 1 then
        print("[BANK] Bank is showing preset.")
        return 1
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:GetTransferTab()")
        print("--------------------------")
        print("VB Value: "..tostring(VB))
        print("--------------------------")
        return false
    end
end

-- Set transfer or preset tab. 0 = transfer and 1 = preset.
---@param number number
---@return boolean
function BANK:SetTransferTab(number)
    if tonumber(number) == 0 then
        if BANK:GetTransferTab() ~= 0 then
            print("[BANK] Opening transfer tab.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,151,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            return true
        end
    elseif tonumber(number) == 1 then
        if BANK:GetTransferTab() ~= 1 then
            print("[BANK] Opening preset tab.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,152,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            return true
        end
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:SetTransferTab()")
        print("--------------------------")
        print("VB Value: "..tostring(number))
        print("--------------------------")
        return false
    end
end

-- Retrieves the currently selected quantity option from the interface.
---@return number|string|boolean
function BANK:GetQuantitySelected()
    local VB = API.VB_FindPSettinOrder(8958).state & 0x7

    if VB == 2 then
        print("[BANK] Current quantity selected: 1")
        return 1
    elseif VB == 3 then
        print("[BANK] Current quantity selected: 5")
        return 5
    elseif VB == 4 then
        print("[BANK] Current quantity selected: 10")
        return 10
    elseif VB == 5 then
        local XValue = API.VB_FindPSettinOrder(111).state
        print("[BANK] Current quantity selected: X (Custom Value: " .. tostring(XValue) .. ")")
        return "X"
    elseif VB == 7 then
        print("[BANK] Current quantity selected: All")
        return "All"
    elseif VB == 0 then
        print("[BANK] Could not read selected quantity.")
        return false
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:GetQuantitySelected()")
        local var = API.VB_FindPSettinOrder(8958)
        print("--------------------------")
        print("state: " .. var.state)
        print("addr: " .. var.addr)
        print("indexaddr_orig: " .. var.indexaddr_orig)
        print("id: " .. var.id)
        print("--------------------------")
        return false
    end
    
    return false
end

-- Set the quantity to transfer. Valid inputs are: 1, 5, 10, "All", or "X".
---@param Qtitty number|string
---@return boolean
function BANK:SetQuantity(Qtitty)
    if type(Qtitty) ~= "number" and type(Qtitty) ~= "string" then
        print("[BANK] Error: Invalid input type. Expected number or string, got: "..type(Qtitty))
        return false
    end

    if type(Qtitty) == "number" then
        if Qtitty ~= 1 and Qtitty ~= 5 and Qtitty ~= 10 then
            print("[BANK] Error: Number quantity must be 1, 5, or 10. Got: "..tostring(Qtitty))
            return false
        end
    end
    
    if type(Qtitty) == "string" then
        local lowerQtitty = Qtitty:lower()
        if lowerQtitty ~= "all" and lowerQtitty ~= "x" then
            print("[BANK] Error: String quantity must be 'All' or 'X'. Got: "..Qtitty)
            return false
        end
    end

    BANK:SetTransferTab(0)

    if Qtitty == 1 then
        if BANK:GetQuantitySelected() ~= 1 then
            print("[BANK] Transfer quantity set to 1.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,93,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Transfer quantity already set to 1. No action needed.")
            return true
        end
    elseif Qtitty == 5 then
        if BANK:GetQuantitySelected() ~= 5 then
            print("[BANK] Transfer quantity set to 5.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,96,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Transfer quantity already set to 5. No action needed.")
            return true
        end
    elseif Qtitty == 10 then        
        if BANK:GetQuantitySelected() ~= 10 then
            print("[BANK] Transfer quantity set to 10.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,99,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Transfer quantity already set to 10. No action needed.")
            return true
        end
    elseif Qtitty == "All" then
        if BANK:GetQuantitySelected() ~= "All" then
            print("[BANK] Transfer quantity set to All.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,103,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Transfer quantity already set to All. No action needed.")
            return true
        end
    elseif Qtitty == "X" then
        if BANK:GetQuantitySelected() ~= "X" then
            print("[BANK] Transfer quantity set to X.")
            API.DoAction_Interface(0x2e,0xffffffff,1,517,106,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Transfer quantity already set to X. No action needed.")
            return true
        end
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:SetQuantity()")
        print("--------------------------")
        print("Value passed: "..tostring(Qtitty))
        print("Type passed: "..type(Qtitty))
        print("Return GetQuantitySelected(): "..tostring(BANK:GetQuantitySelected()))
        print("Return GetXQuantity(): "..tostring(BANK:GetXQuantity()))
        print("--------------------------")
        return false
    end    
end

-- Retrieves the currently X quantity value from the VB.
---@return number
function BANK:GetXQuantity()
    local XValue = API.VB_FindPSettinOrder(111).state
    print("[BANK] X value: "..tostring(XValue))
    return XValue
end

-- Set the X quantity to transfer. 
---@param Qtitty number
---@return boolean
function BANK:SetXQuantity(Qtitty)
    print("[BANK] Setting X quantitty to: "..tostring(Qtitty))
    if type(Qtitty) ~= "number" then
        print("[BANK] Error: Expect number, received: "..tostring(type(Qtitty)))
        return false
    end

    if Qtitty <= 0 then
        print("[BANK] Error: Quantity must be positive, received: "..tostring(Qtitty))
        return false
    end

    if BANK:GetXQuantity() == Qtitty then
        print("[BANK] X quantity already set to "..tostring(Qtitty)..".")
        return true
    end
    
    BANK:SetTransferTab(0)

    API.DoAction_Interface(0xffffffff,0xffffffff,1,517,114,-1,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1000, 1000, 1000)

    local digits = tostring(Qtitty)
    for i = 1, #digits do
        local char = digits:sub(i, i)
        API.KeyboardPress2(string.byte(char), 40, 60)
        API.RandomSleep2(200,200,200)
    end
    
    API.KeyboardPress2(0x0D, 50, 80)
    API.RandomSleep2(500, 600, 700)
    
    return true
end

-- Checks if bank is set to note mode.
---@return boolean
function BANK:IsNoteModeEnabled()
    local VB = API.VB_FindPSettinOrder(160).state

    if VB == 0 then
        print("[BANK] Withdraw as note is disabled.")
        return false
    elseif VB == 1 then
        print("[BANK] Withdraw as note is enabled.")
        return true
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: IsNoteModeEnabled()")
        local var = API.VB_FindPSettinOrder(160)
        print("--------------------------")
        print("state: " .. var.state)
        print("addr: " .. var.addr)
        print("indexaddr_orig: " .. var.indexaddr_orig)
        print("id: " .. var.id)
        print("--------------------------")
        return false
    end
end

-- Set withdraw mode. True = note and false = item.
---@param boolean boolean
---@return boolean
function BANK:SetNoteMode(boolean)
    if type(boolean) ~= "boolean" then
        print("[BANK] Error: Expected a boolean, got "..tostring(boolean).." ("..type(boolean)..")")
        return false
    end

    if boolean == true then
        if BANK:IsNoteModeEnabled() then
            print("[BANK] Note mode already enabled. No action needed.")
            return true
        else
            print("[BANK] Enabling note mode.")
            API.DoAction_Interface(0xffffffff,0xffffffff,1,517,127,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    elseif boolean == false then
        if not BANK:IsNoteModeEnabled() then
            print("[BANK] Note mode already disabled. No action needed.")
            return true
        else
            print("[BANK] Disabling note mode.")
            API.DoAction_Interface(0xffffffff,0xffffffff,1,517,127,-1,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:SetNoteMode()")
        print("--------------------------")
        print("Value passed: "..tostring(boolean))
        print("Return IsNoteModeEnabled(): "..tostring(BANK:IsNoteModeEnabled()))
        print("--------------------------")
        return false
    end
end

-- Get preset page. Page 1 = (1 -> 9), page 2 = (10 -> 18).
---@return number|boolean
function BANK:GetPresetPage()
    local VB = API.VB_FindPSettinOrder(9932).state >> 15
    if VB == 0 then
        print("[BANK] Bank is showing page 1, presets 1 to 9.")
        return 1
    elseif VB == 1 then
        print("[BANK] Bank is showing page 2, presets 10 to 18.")
        return 2
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:GetPresetPage()")
        print("--------------------------")
        print("VB Value: "..tostring(VB))
        print("--------------------------")
        return false
    end
end

-- Sets the bank preset page to the specified number (1 or 2).
---@param number number
---@return boolean
function BANK:SetPresetPage(number)
    if type(number) ~= "number" then
        print("[BANK] Error: Expected a number, got "..tostring(number).." ("..type(number)..")")
        return false
    end

    BANK:SetTransferTab(1)

    if number == 1 then
        if BANK:GetPresetPage() == 1 then
            print("[BANK] Preset page already 1. No action needed.")
            return true
        else
            print("[BANK] Changing preset page to 1.")
            API.DoAction_Interface(0x24,0xffffffff,1,517,119,100,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    elseif number == 2 then
        if BANK:GetPresetPage() == 2 then
            print("[BANK] Preset page already 2. No action needed.")
            return true
        else
            print("[BANK] Changing preset page to 2.")
            API.DoAction_Interface(0x24,0xffffffff,1,517,119,100,API.OFF_ACT_GeneralInterface_route)
            return true
        end
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:SetPresetPage()")
        print("--------------------------")
        print("Value passed: "..tostring(number))
        print("Return GetPresetPage(): "..tostring(BANK:GetPresetPage()))
        print("--------------------------")
        return false
    end
end

-- Saves the current bank preset to the specified preset slot (1-18).
---@param number number
---@return boolean
function BANK:SavePreset(number)
    if type(number) ~= "number" then
        print("[BANK] Error: Expected a number, got "..tostring(number).." ("..type(number)..")")
        return false
    end
    
    if number < 1 or number > 18 then
        print("[BANK] Error: Can only save to presets 1 to 18, you passed: "..tostring(number))
        return false
    end

    BANK:SetTransferTab(1)

    local slot = number
    if slot < 10 then
        BANK:SetPresetPage(1)
        API.RandomSleep2(200, 200, 200)
        print("[BANK] Saving preset number: "..tostring(number))
        API.DoAction_Interface(0xffffffff,0xffffffff,2,517,119,slot,API.OFF_ACT_GeneralInterface_route)
        return true
    else
        slot = slot - 9
        BANK:SetPresetPage(2)
        API.Sleep_tick(1)
        API.RandomSleep2(200, 200, 200)
        print("[BANK] Saving preset number: "..tostring(number))
        API.DoAction_Interface(0xffffffff,0xffffffff,2,517,119,slot,API.OFF_ACT_GeneralInterface_route)
        return true
    end

    return false
end

-- Saves the current beast of burden's preset.
---@return boolean
function BANK:SaveSummonPreset()
    print("[BANK] Saving beast of burden preset")
    BANK:SetTransferTab(1)
    return API.DoAction_Interface(0xffffffff,0xffffffff,2,517,119,10,API.OFF_ACT_GeneralInterface_route)
end

-- Loads the specified preset (1-18).
---@param number number
---@return boolean
function BANK:LoadPreset(number)
    if type(number) ~= "number" then
        print("[BANK] Error: Expected a number, got "..tostring(number).." ("..type(number)..")")
        return false
    end
    
    if number < 1 or number > 18 then
        print("[BANK] Error: Can only load to presets 1 to 18, you passed: "..tostring(number))
        return false
    end

    local slot = number
    if slot < 10 then
        BANK:SetPresetPage(1)
        API.RandomSleep2(200, 200, 200)
        print("[BANK] Loading preset number: "..tostring(number))
        API.DoAction_Interface(0x24,0xffffffff,1,517,119,slot,API.OFF_ACT_GeneralInterface_route)
        return true
    else
        slot = slot - 9
        BANK:SetPresetPage(2)
        API.Sleep_tick(1)
        API.RandomSleep2(200, 200, 200)
        print("[BANK] Loading preset number: "..tostring(number))
        API.DoAction_Interface(0x24,0xffffffff,1,517,119,slot,API.OFF_ACT_GeneralInterface_route)
        return true
    end

    return false
end

-- Loads the beast of burden's preset.
---@return boolean
function BANK:LoadSummonPreset()
    print("[BANK] Loading beast of burden preset")
    BANK:SetTransferTab(1)
    return API.DoAction_Interface(0x24,0xffffffff,1,517,119,10,API.OFF_ACT_GeneralInterface_route)
end

-- Empty your backpack into your bank.
---@return boolean
function BANK:DepositInventory()
    print("[BANK] Depositing inventory.")
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,39,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Empty the items you are wearing into the bank.
---@return boolean
function BANK:DepositEquipment()
    print("[BANK] Depositing equipment.")
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,42,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Empty your beast of burden's inventory into your bank.
---@return boolean
function BANK:DepositSummon()
    print("[BANK] Depositing beast of burden's inventory.")
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,45,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Empty your money pouch into MY bank.
---@return boolean
function BANK:DepositMoneyPouch()
    print("[BANK] Depositing all your money.")
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,48,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Withdraws item(s) from your bank. The amount is set with BANK:SetQuantity(Qtitty).
---@param ItemID number|table
---@return boolean
function BANK:Withdraw(ItemID)
    BANK:OpenTab(1)
    local Items = API.Container_Get_all(95)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local ItemIDHex = string.format("0x%X", ItemID)
        local slot = nil

        if not BANK:Contains(ItemID) then
            return false
        end

        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end

        if slot then
            print("[BANK] Withdrawing item: "..tostring(ItemID)..".")
            API.DoAction_Interface(0xffffffff,ItemIDHex,1,517,202,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Could not find slot for item: "..tostring(ItemID)..".")
            return false
        end
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Withdraw(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Withdraw. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Withdraws 1x item(s) from your bank.
---@param ItemID number|table
---@return boolean
function BANK:Withdraw1(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(95)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:Contains(ItemID) then
            print("[BANK] Item not found in bank: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 1  -- First option (1)
        elseif currentQuantity == 5 then
            option = 2  -- Second option (1)
        elseif currentQuantity == 10 then
            option = 2  -- Second option (1)
        elseif currentQuantity == "X" then
            option = 2  -- Second option (1)
        elseif currentQuantity == "All" then
            option = 2  -- Second option (1)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Withdrawing 1x item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,202,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Withdraw1(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Withdraw1. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Withdraws 5x item(s) from your bank.
---@param ItemID number|table
---@return boolean
function BANK:Withdraw5(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(95)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:Contains(ItemID) then
            print("[BANK] Item not found in bank: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 3  -- Second option (5)
        elseif currentQuantity == 5 then
            option = 1  -- First option (5)
        elseif currentQuantity == 10 then
            option = 3  -- Third option (5)
        elseif currentQuantity == "X" then
            option = 3  -- Third option (5)
        elseif currentQuantity == "All" then
            option = 3  -- Third option (5)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Withdrawing 5x item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,202,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Withdraw5(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Withdraw5. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Withdraws 10x item(s) from your bank.
---@param ItemID number|table
---@return boolean
function BANK:Withdraw10(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(95)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:Contains(ItemID) then
            print("[BANK] Item not found in bank: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 4  -- Third option (10)
        elseif currentQuantity == 5 then
            option = 4  -- Third option (10)
        elseif currentQuantity == 10 then
            option = 1  -- First option (10)
        elseif currentQuantity == "X" then
            option = 4  -- Fourth option (10)
        elseif currentQuantity == "All" then
            option = 4  -- Fourth option (10)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Withdrawing 10x item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,202,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Withdraw10(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Withdraw10. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Withdraws X amount of item(s) from your bank.
---@param ItemID number|table
---@return boolean
function BANK:WithdrawX(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(95)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:Contains(ItemID) then
            print("[BANK] Item not found in bank: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 5  -- Fourth option (X)
        elseif currentQuantity == 5 then
            option = 5  -- Fourth option (X)
        elseif currentQuantity == 10 then
            option = 5  -- Fourth option (X)
        elseif currentQuantity == "X" then
            option = 1  -- First option (X)
        elseif currentQuantity == "All" then
            option = 5  -- Fifth option (X)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Withdrawing X amount of item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,202,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:WithdrawX(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for WithdrawX. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Withdraws All of item(s) from your bank.
---@param ItemID number|table
---@return boolean
function BANK:WithdrawAll(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(95)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:Contains(ItemID) then
            print("[BANK] Item not found in bank: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        local route = nil
        
        if currentQuantity == 1 then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == 5 then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == 10 then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == "X" then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == "All" then
            option = 1  -- First option (All)
            route = API.OFF_ACT_GeneralInterface_route
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Withdrawing all of item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,202,slot,route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:WithdrawAll(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for WithdrawAll. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits item(s) into your bank. The amount is set with BANK:SetQuantity(Qtitty).
---@param ItemID number|table
---@return boolean
function BANK:Deposit(ItemID)
    BANK:OpenTab(1)
    local Items = API.Container_Get_all(93)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local ItemIDHex = string.format("0x%X", ItemID)
        local slot = nil

        if not BANK:InventoryContains(ItemID) then
            return false
        end

        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end

        if slot then
            print("[BANK] Depositing item: "..tostring(ItemID)..".")
            API.DoAction_Interface(0xffffffff,ItemIDHex,1,517,15,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Could not find slot for item: "..tostring(ItemID)..".")
            return false
        end
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Deposit(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositItem. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits 1x item(s) into your bank.
---@param ItemID number|table
---@return boolean
function BANK:Deposit1(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(93)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:InventoryContains(ItemID) then
            print("[BANK] Item not found in inventory: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 1  -- First option (1)
        elseif currentQuantity == 5 then
            option = 2  -- Second option (1)
        elseif currentQuantity == 10 then
            option = 2  -- Second option (1)
        elseif currentQuantity == "X" then
            option = 2  -- Second option (1)
        elseif currentQuantity == "All" then
            option = 2  -- Second option (1)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Depositing 1x item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,15,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Deposit1(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Deposit1. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits 5x item(s) into your bank.
---@param ItemID number|table
---@return boolean
function BANK:Deposit5(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(93)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:InventoryContains(ItemID) then
            print("[BANK] Item not found in inventory: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 3  -- Second option (5)
        elseif currentQuantity == 5 then
            option = 1  -- First option (5)
        elseif currentQuantity == 10 then
            option = 3  -- Third option (5)
        elseif currentQuantity == "X" then
            option = 3  -- Third option (5)
        elseif currentQuantity == "All" then
            option = 3  -- Third option (5)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Depositing 5x item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,15,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Deposit5(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Deposit5. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits 10x item(s) into your bank.
---@param ItemID number|table
---@return boolean
function BANK:Deposit10(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(93)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:InventoryContains(ItemID) then
            print("[BANK] Item not found in inventory: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 4  -- Third option (10)
        elseif currentQuantity == 5 then
            option = 4  -- Third option (10)
        elseif currentQuantity == 10 then
            option = 1  -- First option (10)
        elseif currentQuantity == "X" then
            option = 4  -- Fourth option (10)
        elseif currentQuantity == "All" then
            option = 4  -- Fourth option (10)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Depositing 10x item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,15,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Deposit10(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for Deposit10. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits X amount of item(s) into your bank.
---@param ItemID number|table
---@return boolean
function BANK:DepositX(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(93)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:InventoryContains(ItemID) then
            print("[BANK] Item not found in inventory: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        
        if currentQuantity == 1 then
            option = 5  -- Fourth option (X)
        elseif currentQuantity == 5 then
            option = 5  -- Fourth option (X)
        elseif currentQuantity == 10 then
            option = 5  -- Fourth option (X)
        elseif currentQuantity == "X" then
            option = 1  -- First option (X)
        elseif currentQuantity == "All" then
            option = 5  -- Fifth option (X)
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Depositing X amount of item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,15,slot,API.OFF_ACT_GeneralInterface_route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:DepositX(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositX. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits All of item(s) into your bank.
---@param ItemID number|table
---@return boolean
function BANK:DepositAll(ItemID)
    BANK:OpenTab(1)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local Items = API.Container_Get_all(93)
        local ItemIDHex = string.format("0x%X", ItemID)
        
        if not BANK:InventoryContains(ItemID) then
            print("[BANK] Item not found in inventory: "..tostring(ItemID))
            return false
        end
        
        local slot = nil
        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end
        
        if not slot then
            print("[BANK] Could not find slot for item: "..tostring(ItemID))
            return false
        end
        
        local currentQuantity = BANK:GetQuantitySelected()
        local option = nil
        local route = nil
        
        if currentQuantity == 1 then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == 5 then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == 10 then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == "X" then
            option = 7  -- Sixth option (All)
            route = API.OFF_ACT_GeneralInterface_route2
        elseif currentQuantity == "All" then
            option = 1  -- First option (All)
            route = API.OFF_ACT_GeneralInterface_route
        else
            print("[BANK] Unknown quantity setting: "..tostring(currentQuantity))
            return false
        end
        
        print("[BANK] Depositing all of item: "..tostring(ItemID))
        API.DoAction_Interface(0xffffffff,ItemIDHex,option,517,15,slot,route)
        return true
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:DepositAll(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositAll. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposits logs from wood boxes in inventory.
---@return boolean
function BANK:WoodBoxDepositLogs()
    if not BANK:IsOpen() then
        print("[BANK] Bank interface is not open.")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or inventory is empty.")
        return false
    end
    
    local woodBoxesFound = {}
    local success = true
    
    -- Find all wood boxes in inventory
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            for _, woodBoxId in ipairs(self.Items.WoodBoxes) do
                if item.item_id == woodBoxId then
                    table.insert(woodBoxesFound, {
                        id = item.item_id,
                        slot = item.item_slot,
                        stack = item.item_stack
                    })
                    print("[BANK] Found wood box ID: " .. item.item_id .. " in slot " .. item.item_slot)
                    break
                end
            end
        end
    end
    
    if #woodBoxesFound == 0 then
        print("[BANK] No wood boxes found in inventory.")
        return false
    end
    
    print("[BANK] Found " .. #woodBoxesFound .. " wood box(es). Depositing logs...")
    
    -- Deposit logs from each wood box found
    for _, woodBox in ipairs(woodBoxesFound) do
        local ItemIDHex = string.format("0x%X", woodBox.id)
        
        -- Use the "Deposit logs" option (option 8) on the wood box
        print("[BANK] Depositing logs from wood box ID: " .. woodBox.id)
        local result = API.DoAction_Interface(0xffffffff, ItemIDHex, 8, 517, 15, woodBox.slot, API.OFF_ACT_GeneralInterface_route2)
        
        if not result then
            print("[BANK] Failed to deposit logs from wood box ID: " .. woodBox.id)
            success = false
        end
    end
    
    if success then
        print("[BANK] Successfully deposited logs from all wood boxes.")
    else
        print("[BANK] Some wood box log deposits may have failed.")
    end
    
    return success
end

-- Deposits wood spirits from wood boxes in inventory.
---@return boolean
function BANK:WoodBoxDepositWoodSpirits()
    if not BANK:IsOpen() then
        print("[BANK] Bank interface is not open.")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or inventory is empty.")
        return false
    end
    
    local woodBoxesFound = {}
    local success = true
    
    -- Find all wood boxes in inventory
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            -- Check if this item ID is in our wood boxes table
            for _, woodBoxId in ipairs(self.Items.WoodBoxes) do
                if item.item_id == woodBoxId then
                    table.insert(woodBoxesFound, {
                        id = item.item_id,
                        slot = item.item_slot,
                        stack = item.item_stack
                    })
                    print("[BANK] Found wood box ID: " .. item.item_id .. " in slot " .. item.item_slot)
                    break
                end
            end
        end
    end
    
    if #woodBoxesFound == 0 then
        print("[BANK] No wood boxes found in inventory.")
        return false
    end
    
    print("[BANK] Found " .. #woodBoxesFound .. " wood box(es). Depositing wood spirits...")
    
    -- Deposit wood spirits from each wood box found
    for _, woodBox in ipairs(woodBoxesFound) do
        local ItemIDHex = string.format("0x%X", woodBox.id)
        
        -- Use the "Deposit wood spirits" option (option 9) on the wood box
        print("[BANK] Depositing wood spirits from wood box ID: " .. woodBox.id)
        local result = API.DoAction_Interface(0xffffffff, ItemIDHex, 9, 517, 15, woodBox.slot, API.OFF_ACT_GeneralInterface_route2)
        
        if not result then
            print("[BANK] Failed to deposit wood spirits from wood box ID: " .. woodBox.id)
            success = false
        end
    end
    
    if success then
        print("[BANK] Successfully deposited wood spirits from all wood boxes.")
    else
        print("[BANK] Some wood box wood spirit deposits may have failed.")
    end
    
    return success
end

-- Deposits ore from ore boxes in inventory.
---@return boolean
function BANK:OreBoxDepositOres()
    if not BANK:IsOpen() then
        print("[BANK] Bank interface is not open.")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or inventory is empty.")
        return false
    end
    
    local oreBoxesFound = {}
    local success = true
    
    -- Find all ore boxes in inventory
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            -- Check if this item ID is in our ore boxes table
            for _, oreBoxId in ipairs(self.Items.OreBoxes) do
                if item.item_id == oreBoxId then
                    table.insert(oreBoxesFound, {
                        id = item.item_id,
                        slot = item.item_slot,
                        stack = item.item_stack
                    })
                    print("[BANK] Found ore box ID: " .. item.item_id .. " in slot " .. item.item_slot)
                    break
                end
            end
        end
    end
    
    if #oreBoxesFound == 0 then
        print("[BANK] No ore boxes found in inventory.")
        return false
    end
    
    print("[BANK] Found " .. #oreBoxesFound .. " ore box(es). Depositing ore...")
    
    -- Deposit ore from each ore box found
    for _, oreBox in ipairs(oreBoxesFound) do
        local ItemIDHex = string.format("0x%X", oreBox.id)
        
        -- Use the "Deposit ore" option (option 8) on the ore box
        print("[BANK] Depositing ore from ore box ID: " .. oreBox.id)
        local result = API.DoAction_Interface(0xffffffff, ItemIDHex, 8, 517, 15, oreBox.slot, API.OFF_ACT_GeneralInterface_route2)
        
        if not result then
            print("[BANK] Failed to deposit ore from ore box ID: " .. oreBox.id)
            success = false
        end
    end
    
    if success then
        print("[BANK] Successfully deposited ore from all ore boxes.")
    else
        print("[BANK] Some ore box ore deposits may have failed.")
    end
    
    return success
end

-- Deposits stone spirits from ore boxes in inventory.
---@return boolean
function BANK:OreBoxDepositStoneSpirits()
    if not BANK:IsOpen() then
        print("[BANK] Bank interface is not open.")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or inventory is empty.")
        return false
    end
    
    local oreBoxesFound = {}
    local success = true
    
    -- Find all ore boxes in inventory
    for _, item in ipairs(Items) do
        if item.item_id and item.item_stack > 0 then
            -- Check if this item ID is in our ore boxes table
            for _, oreBoxId in ipairs(self.Items.OreBoxes) do
                if item.item_id == oreBoxId then
                    table.insert(oreBoxesFound, {
                        id = item.item_id,
                        slot = item.item_slot,
                        stack = item.item_stack
                    })
                    print("[BANK] Found ore box ID: " .. item.item_id .. " in slot " .. item.item_slot)
                    break
                end
            end
        end
    end
    
    if #oreBoxesFound == 0 then
        print("[BANK] No ore boxes found in inventory.")
        return false
    end
    
    print("[BANK] Found " .. #oreBoxesFound .. " ore box(es). Depositing stone spirits...")
    
    -- Deposit stone spirits from each ore box found
    for _, oreBox in ipairs(oreBoxesFound) do
        local ItemIDHex = string.format("0x%X", oreBox.id)
        
        -- Use the "Deposit stone spirits" option (option 9) on the ore box
        print("[BANK] Depositing stone spirits from ore box ID: " .. oreBox.id)
        local result = API.DoAction_Interface(0xffffffff, ItemIDHex, 9, 517, 15, oreBox.slot, API.OFF_ACT_GeneralInterface_route2)
        
        if not result then
            print("[BANK] Failed to deposit stone spirits from ore box ID: " .. oreBox.id)
            success = false
        end
    end
    
    if success then
        print("[BANK] Successfully deposited stone spirits from all ore boxes.")
    else
        print("[BANK] Some ore box stone spirit deposits may have failed.")
    end
    
    return success
end

-- Deposits soil from soil box in inventory.
---@return boolean
function BANK:SoilBoxDepositSoil()
    if not BANK:IsOpen() then
        print("[BANK] Bank interface is not open.")
        return false
    end
    
    local Items = API.Container_Get_all(93)
    if not Items or #Items == 0 then
        print("[BANK] Could not read inventory items or inventory is empty.")
        return false
    end

    local soilBoxId = 49538 -- Soil box item ID

    -- Find the soil box in inventory
    for _, item in ipairs(Items) do
        if item.item_id and item.item_id == soilBoxId and item.item_stack > 0 then
            API.DoAction_Interface(0xffffffff, 0xc182, 9, 517, 15, item.item_slot, API.OFF_ACT_GeneralInterface_route2)
            
            print("[BANK] Deposited soil from soil box")
            return true
        end
    end

    print("[BANK] No soil box found in inventory.")
    return false 
end

-- Equips an item from your bank.
---@param ItemID number
---@return boolean
function BANK:Equip(ItemID)
    local Items = API.Container_Get_all(95)
    BANK:OpenTab(3)

    local ItemIDHex = string.format("0x%X", ItemID)
    local slot = nil

    if not BANK:Contains(ItemID) then
        return false
    end

    for i, item in ipairs(Items) do
        if item.item_id and item.item_id == ItemID then
            slot = item.item_slot
            break
        end
    end

    if slot then
        print("[BANK] Equipping item: "..tostring(ItemID)..".")
        API.DoAction_Interface(0xffffffff,ItemIDHex,1,517,202,slot, API.OFF_ACT_GeneralInterface_route)
        return true
    else
        print("[BANK] Could not find slot for item: "..tostring(ItemID)..".")
        return false
    end
end

-- Withdraws item(s) from your bank to your beast of burden. The amount is set with BANK:SetQuantity(Qtitty).
---@param ItemID number|table
---@return boolean
function BANK:WithdrawToBoB(ItemID)
    BANK:OpenTab(2)
    local Items = API.Container_Get_all(95)
    local success = true
    
    -- Handle single item case
    if type(ItemID) == "number" then
        local ItemIDHex = string.format("0x%X", ItemID)
        local slot = nil

        if not BANK:Contains(ItemID) then
            return false
        end

        for i, item in ipairs(Items) do
            if item.item_id and item.item_id == ItemID then
                slot = item.item_slot
                break
            end
        end

        if slot then
            print("[BANK] Withdrawing item: "..tostring(ItemID).." to beast of burden.")
            API.DoAction_Interface(0xffffffff,ItemIDHex,1,517,202,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Could not find slot for item: "..tostring(ItemID)..".")
            return false
        end
        
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:Withdraw(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for WithdrawToBoB. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- #################################
-- #                               #
-- #     DEPOSIT BOX FUNCTIONS     #
-- #                               #
-- #################################

-- Check if Deposit box interface is open.
---@return boolean
function BANK:DepositBoxIsOpen()
    if API.VB_FindPSettinOrder(2874, 0).state == 69 then
        print("[BANK] Deposit box interface open.")
        return true
    else
        print("[BANK] Deposit box interface is not open.")
        return false
    end
end

-- Attempts to open a deposit box. Requires cache enabled https://imgur.com/5I9a46V.
---@return boolean
function BANK:DepositBoxOpen()
    print("[BANK] Opening Deposit box.")
    if Interact:Object("Deposit box", "Deposit", 50) then
        return true
    end

    print("[BANK] Could not interact with any Deposit box.")
    return false
end

-- Attempts to close the deposit box interface.
---@return boolean
function BANK:DepositBoxClose()
    if BANK:DepositBoxIsOpen() then
        print("[BANK] Closing deposit box.")
        return API.DoAction_Interface(0x24,0xffffffff,1,11,23,-1,API.OFF_ACT_GeneralInterface_route)
    else
        print("[BANK] Deposit box not open.")
        return false
    end    
end

-- Check if a specific item is in the deposit box.
---@param ItemID number
---@return boolean
function BANK:DepositBoxContains(ItemID)
    local FoundItem = false
    for i = 1, 28 do
        local slot = API.ScanForInterfaceTest2Get(false, self.Interfaces.DepositBoxSlots[i])[1]
        if slot.itemid1 and slot.itemid1 == itemID then
            FoundItem = true
        end
    end

    if FoundItem then
        print("[BANK] Item ID: "..itemID.." found.")
    else
        print("[BANK] Item ID: "..itemID.." not found.")
    end

    return FoundItem
end

-- Get the slot of a specific item in the deposit box (0-27).
---@param ItemID number
---@return number|boolean
function BANK:DepositBoxGetSlot(ItemID)
    for i = 1, 28 do
        local slot = API.ScanForInterfaceTest2Get(false, self.Interfaces.DepositBoxSlots[i])[1]
        if slot.itemid1 and slot.itemid1 == ItemID then
            print("[BANK] Item ID: "..ItemID.." found in slot: "..(i)..".")
            return i - 1
        end
    end

    print("[BANK] Item ID: "..ItemID.." not found.")
    return false
end

-- Empty your backpack into a deposit box.
---@return boolean
function BANK:DepositBoxDepositInventory()
    print("[BANK] Depositing inventory in deposit box.")
    return API.DoAction_Interface(0x24,0xffffffff,1,11,5,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Empty the items you are wearing into a deposit box.
---@return boolean
function BANK:DepositBoxDepositEquipment()
    print("[BANK] Depositing equipment in deposit box.")
    return API.DoAction_Interface(0x24,0xffffffff,1,11,11,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Empty your beast of burden's inventory into a deposit box.
---@return boolean
function BANK:DepositSummonDepositBox()
    print("[BANK] Depositing beast of burden's inventory into a deposit box.")
    return API.DoAction_Interface(0x24,0xffffffff,1,11,11,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Empty your money pouch into a deposit box.
---@return boolean
function BANK:DepositBoxDepositMoneyPouch()
    print("[BANK] Depositing all your money into a deposit box.")
    return API.DoAction_Interface(0x24,0xffffffff,1,11,14,-1,API.OFF_ACT_GeneralInterface_route)
end

-- Attempts to deposit-all in a deposit box. Requires cache enabled https://imgur.com/5I9a46V.
---@return boolean
function BANK:DepositBoxDepositAll()
    print("[BANK] Depositing-All in a deposit box.")
    if Interact:Object("Deposit box", "Deposit-All", 50) then
        return true
    end

    print("[BANK] Could not interact with any Deposit box.")
    return false
end

-- Deposit 1 of a specific item(s) into a deposit box.
---@param ItemID number|table
---@return boolean
function BANK:DepositBoxDeposit1(ItemID)
    -- Handle single item case
    if type(ItemID) == "number" then     
        local ItemIDHex = string.format("0x%X", ItemID)  
        local slot = BANK:DepositBoxGetSlot(ItemID)     

        if slot then
            print("[BANK] Depositing 1 of item: "..ItemID.." into deposit box.")
            API.DoAction_Interface(0xffffffff,ItemIDHex,1,11,19,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Item ID: "..ItemID.." not found in deposit box interface.")
            return false
        end
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        local success = true
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:DepositBoxDeposit1(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositBoxDeposit1. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposit 5 of a specific item(s) into a deposit box.
---@param ItemID number|table
---@return boolean
function BANK:DepositBoxDeposit5(ItemID)
    -- Handle single item case
    if type(ItemID) == "number" then     
        local ItemIDHex = string.format("0x%X", ItemID)  
        local slot = BANK:DepositBoxGetSlot(ItemID)     

        if slot then
            print("[BANK] Depositing 5 of item: "..ItemID.." into deposit box.")
            API.DoAction_Interface(0xffffffff,ItemIDHex,2,11,19,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Item ID: "..ItemID.." not found in deposit box interface.")
            return false
        end
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        local success = true
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:DepositBoxDeposit5(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositBoxDeposit5. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposit 10 of a specific item(s) into a deposit box.
---@param ItemID number|table
---@return boolean
function BANK:DepositBoxDeposit10(ItemID)
    -- Handle single item case
    if type(ItemID) == "number" then     
        local ItemIDHex = string.format("0x%X", ItemID)  
        local slot = BANK:DepositBoxGetSlot(ItemID)     

        if slot then
            print("[BANK] Depositing 10 of item: "..ItemID.." into deposit box.")
            API.DoAction_Interface(0xffffffff,ItemIDHex,3,11,19,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Item ID: "..ItemID.." not found in deposit box interface.")
            return false
        end
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        local success = true
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:DepositBoxDeposit10(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositBoxDeposit10. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- Deposit ALL of a specific item(s) into a deposit box.
---@param ItemID number|table
---@return boolean
function BANK:DepositBoxDepositAll2(ItemID)
    -- Handle single item case
    if type(ItemID) == "number" then     
        local ItemIDHex = string.format("0x%X", ItemID)  
        local slot = BANK:DepositBoxGetSlot(ItemID)     

        if slot then
            print("[BANK] Depositing ALL of item: "..ItemID.." into deposit box.")
            API.DoAction_Interface(0xffffffff,ItemIDHex,4,11,19,slot,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            print("[BANK] Item ID: "..ItemID.." not found in deposit box interface.")
            return false
        end
    -- Handle table of items case
    elseif type(ItemID) == "table" then
        local success = true
        for _, id in ipairs(ItemID) do
            local currentSuccess = BANK:DepositBoxDepositAll2(id)
            if not currentSuccess then
                success = false
            end
        end
        return success
    else
        print("[BANK] Invalid input type for DepositBoxDepositAll2. Expected number or table, got "..type(ItemID))
        return false
    end
end

-- ####################################
-- #                                  #
-- #     COLLECTION BOX FUNCTIONS     #
-- #                                  #
-- ####################################

-- Check if Collect interface is open.
---@return boolean
function BANK:ColletionBoxIsOpen()
    if API.VB_FindPSettinOrder(2874, 0).state == 18 then
        print("[BANK] Collect interface open.")
        return true
    else
        print("[BANK] Collect interface is not open.")
        return false
    end 
end

-- Attempts to open your collection box using the listed options. Requires cache enabled https://imgur.com/5I9a46V.
---@return boolean
function BANK:ColletionBoxOpen()
    print("[BANK] Opening collection box from nearest bank:")
    local NearestBank = GetNearestBank()
    
    if not NearestBank then
        print("[BANK] No bank found nearby or no matching bank in configuration.")
        return false
    end



    local success = false
    
    if NearestBank.InteractType == "NPC" then
        success = Interact:NPC(NearestBank.name, NearestBank.CollectionBoxAction, 50)
    elseif NearestBank.InteractType == "Object" then
        success = Interact:Object(NearestBank.name, NearestBank.CollectionBoxAction, 50)
    end
    
    if success then
        print("[BANK] " .. NearestBank.name .. " succeeded.")
        return true
    end
    
    print("[BANK] Could not open collection box from " .. NearestBank.name)
    return false
end

-- Attempts to close the collection box interface.
---@return boolean
function BANK:CollectionBoxClose()
    if BANK:ColletionBoxIsOpen() then
        print("[BANK] Closing collection box.")
        return API.DoAction_Interface(0x24,0xffffffff,1,109,42,-1,API.OFF_ACT_GeneralInterface_route)
    else
        print("[BANK] Collection box not open.")
        return false
    end
end

-- Check if there are items to collect.
---@return boolean
function BANK:ColletionBoxHasItems()
    local FoundItem = false

    for i = 1, 16 do
        local slot = API.ScanForInterfaceTest2Get(false, self.Interfaces.CollectionBoxSlots[i])[1]
        if slot.itemid1 and slot.itemid1 ~= -1 then
            FoundItem = true
        end
    end

    if FoundItem then
        print("[BANK] There is at least one item to collect.")
    else
        print("[BANK] There are no items to collect.")
    end

    return FoundItem
end

-- Check if there is a specific item to collect.
---@param itemID number
---@return boolean
function BANK:ColletionBoxContains(itemID)
    local FoundItem = false

    for i = 1, 16 do
        local slot = API.ScanForInterfaceTest2Get(false, self.Interfaces.CollectionBoxSlots[i])[1]
        if slot.itemid1 and slot.itemid1 == itemID then
            FoundItem = true
        end
    end

    if FoundItem then
        print("[BANK] Item ID: "..itemID.." found.")
    else
        print("[BANK] Item ID: "..itemID.." not found.")
    end

    return FoundItem
end

-- Collects all to inventory from Collect interface.
---@return boolean
function BANK:ColletionBoxCollectToInventory()
    if BANK:HasItemsToCollect() then
        print("[BANK] Collecting all to inventory.")
        API.DoAction_Interface(0x24,0xffffffff,1,109,55,-1,API.OFF_ACT_GeneralInterface_route) 
        return true
    else
        print("[BANK] There are no items to collect.")
        return false        
    end    
end

-- Collects all to bank from Collect interface.
---@return boolean
function BANK:ColletionBoxCollectToBank()
    if BANK:HasItemsToCollect() then
        print("[BANK] Collecting all to BANK:")
        API.DoAction_Interface(0x24,0xffffffff,1,109,47,-1,API.OFF_ACT_GeneralInterface_route)
        return true
    else
        print("[BANK] There are no items to collect.")
        return false        
    end
end

-- #####################################
-- #                                   #
-- #     PRESET SETTINGS FUNCTIONS     #
-- #                                   #
-- #####################################

-- Check if preset settings interface is open.
---@return boolean
function BANK:PresetSettingsIsOpen()
    local VB = API.VB_FindPSettinOrder(6680).state >> 20

    if VB == 0 then
        print("[BANK] Preset settings interface is not open.")
        return false
        
    elseif VB == 1 then
        print("[BANK] Preset settings interface is open.")
        return true
    else
        print("[BANK] Something went horribly wrong here. Send me a screenshot of the console on Discord: not_spectre011.")
        print("Function: BANK:PresetSettingsIsOpen()")
        local var = API.VB_FindPSettinOrder(6680)
        print("--------------------------")
        print("state: " .. var.state)
        print("addr: " .. var.addr)
        print("indexaddr_orig: " .. var.indexaddr_orig)
        print("id: " .. var.id)
        print("--------------------------")
        return false
    end
end

-- Open preset settings interface.
---@return boolean
function BANK:PresetSettingsOpen()
    if not BANK:PresetSettingsIsOpen() then
        print("[BANK] Opening preset settings.")
        API.DoAction_Interface(0x24,0xffffffff,1,517,119,0,API.OFF_ACT_GeneralInterface_route)
        return true
    else
        print("[BANK] Preset settings interface is already open.")
        return true
    end
    return false
end

-- Returns to bank.
---@return boolean
function BANK:PresetSettingsReturnToBank()
    if BANK:PresetSettingsIsOpen() then
        print("[BANK] Return to BANK:")
        API.DoAction_Interface(0xffffffff,0xffffffff,1,517,86,-1,API.OFF_ACT_GeneralInterface_route)
        return true
    else
        print("[BANK] Bank interface already open.")
        return true
    end
    return false
end

-- Returns selected preset from the preset settings interface.
---@return number|boolean
function BANK:PresetSettingsGetSelectedPreset()
    if not BANK:PresetSettingsIsOpen() then
        print("[BANK] Preset settings interface is not open. Open it first with BANK:PresetSettingsOpen()")
        return false
    end

    local VB = API.VB_FindPSettinOrder(9932).state
    print("[BANK] Selected preset: "..VB)
    return tonumber(VB)
end

-- Select a preset (1-19). 19 is beast of burden.
---@param preset number
---@return boolean
function BANK:PresetSettingsSelectPreset(preset)
    if type(preset) ~= "number" then
        print("[BANK] Invalid preset type. Expected a number, got " .. type(preset))
        return false
    end

    local slot = tonumber(preset)
    if not slot or slot < 1 or slot > 19 then
        print("[BANK] Invalid preset number. Must be between 1 and 19, got " .. tostring(preset))
        return false
    end

    if BANK:PresetSettingsIsOpen() then
        print("[BANK] Selecting preset " .. slot .. ".")
        API.DoAction_Interface(0xffffffff,0xffffffff,1,517,268,slot,-1,API.OFF_ACT_GeneralInterface_route)
        return true
    else
        print("[BANK] Preset settings interface is not open. Open it first with BANK:PresetSettingsOpen().")
        return false
    end
end

---Get the itemID of all inventory slots inside the preset settings interface.
---@return table|boolean
function BANK:PresetSettingsGetInventory()
    local inventory = {}

    for i = 1, 28 do
        local slot = API.ScanForInterfaceTest2Get(false, self.Interfaces.PresetSettings.Inventory[i])[1]
        if slot and slot.itemid1 then
            table.insert(inventory, { index = i, itemid1 = slot.itemid1, textitem = slot.textitem })
        end
    end

    if #inventory == 0 then
        return false
    end

    return inventory
end

---Get the itemID of all equipment slots inside the preset settings interface.
---@return table|boolean
function BANK:PresetSettingsGetEquipment()
    local equipment = {}

    for i = 1, 13 do
        local slot = API.ScanForInterfaceTest2Get(false, self.Interfaces.PresetSettings.Equipment[i])[1]
        if slot and slot.itemid1 then
            table.insert(equipment, { index = i, itemid1 = slot.itemid1, textitem = slot.textitem })
        end
    end

    if #equipment == 0 then
        return false
    end

    return equipment
end

---Checks if a specific checkbox is enabled in the bank preset settings. Valid options are "Inventory", "Equipment", or "Summon".
---@param option string
---@return boolean|nil
function BANK:PresetSettingsGetCheckBox(option)
    if type(option) ~= "string" then
        print("[BANK] Error: Expected a string for 'option', got " .. type(option))
        return nil
    end

    if option == "Inventory" then
        local VB = (tonumber(API.VB_FindPSettinOrder(4338).state) >> 22) & 1
        if VB == 0 then
            print("[BANK] Inventory CheckBox Enabled.")
            return true
        elseif VB == 1 then
            print("[BANK] Inventory CheckBox Disabled.")
            return false
        else
            print("[BANK] Inventory CheckBox Unknown.")
            return nil
        end
    elseif option == "Equipment" then
        local VB = (tonumber(API.VB_FindPSettinOrder(4338).state) >> 23) & 1
        if VB == 0 then
            print("[BANK] Equipment CheckBox Enabled.")
            return true
        elseif VB == 1 then
            print("[BANK] Equipment CheckBox Disabled.")
            return false
        else
            print("[BANK] Equipment CheckBox Unknown.")
            return nil
        end        
    elseif option == "Summon" then
        local VB = (tonumber(API.VB_FindPSettinOrder(4915).state)) & 1
        if VB == 0 then
            print("[BANK] Summon CheckBox Disabled.")
            return false
        elseif VB == 1 then
            print("[BANK] Summon CheckBox Enabled.")
            return true
        else
            print("[BANK] Summon CheckBox Unknown.")
            return nil
        end
    else
        print("[BANK] Invalid option: '" .. option .. "'. Accepted values are: Inventory, Equipment, or Summon.")
        return nil
    end
    
end

---Set a specific checkbox to be enaled or disabled in the bank preset settings. Valid options are "Inventory", "Equipment", or "Summon".
---@param option string
---@param state boolean
---@return boolean|nil
function BANK:PresetSettingsSetCheckBox(option, state)
    if type(option) ~= "string" then
        print("[BANK] Error: Expected a string for 'option', got " .. type(option))
        return nil
    end

    if type(state) ~= "boolean" then
        print("[BANK] Error: Expected a boolean for 'state', got " .. type(state))
        return nil
    end

    if option == "Inventory" then
        local CheckBox = BANK:PresetSettingsGetCheckBox("Inventory")
        if state then
            if not CheckBox then
                print("[BANK] Enabling inventory checkbox.")
                API.DoAction_Interface(0xffffffff,0xffffffff,1,517,296,-1,API.OFF_ACT_GeneralInterface_route)
                return true
            elseif CheckBox then
                print("[BANK] Inventory checkbox already enabled. No action needed.")
                return true
            else
                print("BANK:PresetSettingsGetCheckBox() returned nil.")
                return false
            end
        elseif not state then
            if CheckBox then
                print("[BANK] Disabling inventory checkbox.")
                API.DoAction_Interface(0xffffffff,0xffffffff,1,517,296,-1,API.OFF_ACT_GeneralInterface_route)
                return true
            elseif not CheckBox then
                print("[BANK] Inventory checkbox already disabled. No action needed.")
                return true
            else
                print("[BANK] BANK:PresetSettingsGetCheckBox() returned nil.")
                return false
            end
        else
            print("[BANK] State invalid: " .. tostring(state))
            return false
        end
    
    elseif option == "Equipment" then
        local CheckBox = BANK:PresetSettingsGetCheckBox("Equipment")
        if state then
            if not CheckBox then
                print("[BANK] Enabling equipment checkbox.")
                API.DoAction_Interface(0xffffffff,0xffffffff,1,517,298,-1,API.OFF_ACT_GeneralInterface_route)
                return true
            elseif CheckBox then
                print("[BANK] Equipment checkbox already enabled. No action needed.")
                return true
            else
                print("[BANK] BANK:PresetSettingsGetCheckBox() returned nil.")
                return false
            end
        elseif not state then
            if CheckBox then
                print("[BANK] Disabling equipment checkbox.")
                API.DoAction_Interface(0xffffffff,0xffffffff,1,517,298,-1,API.OFF_ACT_GeneralInterface_route)
                return true
            elseif not CheckBox then
                print("[BANK] Equipment checkbox already disabled. No action needed.")
                return true
            else
                print("[BANK] BANK:PresetSettingsGetCheckBox() returned nil.")
                return false
            end
        else
            print("[BANK] State invalid: " .. tostring(state))
            return false
        end
    
    elseif option == "Summon" then
        local CheckBox = BANK:PresetSettingsGetCheckBox("Summon")
        if state then
            if not CheckBox then
                print("[BANK] Enabling summon checkbox.")
                API.DoAction_Interface(0xffffffff,0xffffffff,1,517,300,-1,API.OFF_ACT_GeneralInterface_route)
                return true
            elseif CheckBox then
                print("[BANK] Summon checkbox already enabled. No action needed.")
                return true
            else
                print("BANK:PresetSettingsGetCheckBox() returned nil.")
                return false
            end
        elseif not state then
            if CheckBox then
                print("[BANK] Disabling summon checkbox.")
                API.DoAction_Interface(0xffffffff,0xffffffff,1,517,300,-1,API.OFF_ACT_GeneralInterface_route)
                return true
            elseif not CheckBox then
                print("[BANK] Summon checkbox already disabled. No action needed.")
                return true
            else
                print("[BANK] BANK:PresetSettingsGetCheckBox() returned nil.")
                return false
            end
        else
            print("[BANK] State invalid: " .. tostring(state))
            return false
        end
    else
        print("[BANK] Unknown option: " .. tostring(option))
        return false
    end
end

---Prints the data from BANK:PresetSettingsGetInventory() and BANK:PresetSettingsGetEquipment().
---@param data table
---@return boolean
function BANK:PresetSettingsPrintData(data)
    print("Contents:")
    for _, item in ipairs(data) do
        print(string.format("Slot %02d: Item ID = %d Name: %s", item.index, item.itemid1, item.textitem))
    end
    return true
end

return BANK
