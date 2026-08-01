ScriptName = "Basic Combat"
Author = "Spectre011"
ScriptVersion = "1.0.1"
ReleaseDate = "01-08-2026"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0.0 - 01-08-2026
    - Initial release.
v1.0.1 - 01-08-2026
    - Loot now work on all times instead of just when idling.
]]

local API = require("api")
local Slib = require("slib")

math.randomseed(os.time())

-- #region Config -----------------------------------------------------------
-- Tunables. Edit these to change behaviour without touching the logic below.
local Config = {
    ScanRange = 50,            -- Tile distance to include an NPC when scanning
    AttackRange = 50,          -- Tile distance to attack a priority target
    MaxPriorityEntries = 20,   -- Cap on the priority list size
    LoopMinSleep = 200,        -- Main loop min sleep (ms)
    LoopMaxSleep = 400,        -- Main loop max sleep (ms)
    AttackMinSleep = 500,      -- Post-attack min sleep (ms)
    AttackMaxSleep = 900,      -- Post-attack max sleep (ms)
    LootRange = 20,            -- Tile distance / radius to loot ground items
    LootMinSleep = 400,        -- Post-loot min sleep (ms)
    LootMaxSleep = 700,        -- Post-loot max sleep (ms)
    MoundMinSleep = 1200,      -- Post-investigate min sleep (ms), the wyrm takes a moment
    MoundMaxSleep = 1800,      -- Post-investigate max sleep (ms)
    NoTargetTimeout = 120,     -- Stop the script after this many seconds with no target

    -- Sustain. Excalibur and Elven Shard use fixed levels; food and prayer
    -- potions use the Options tab sliders, which start at these defaults.
    ExcaliburPercent = 55,        -- Use Excalibur when HP% at or below this
    ElvenShardPercent = 60,       -- Use Elven Shard when prayer% at or below this
    DefaultHealthPercent = 50,    -- Eat food when HP% at or below this
    DefaultPrayerPercent = 50,    -- Drink a prayer potion when prayer% at or below this
    ExcaliburCooldown = 300,      -- Excalibur enhanced-heal cooldown (seconds)
    PrayerPotionCooldown = 2,     -- Min seconds between prayer potion sips
    BuffUpkeepInterval = 5,       -- Seconds between buff upkeep checks
    SustainWarnInterval = 30,     -- Min seconds between repeated sustain warnings

    -- Anti-idle
    AntiIdleMinSeconds = 180,     -- Earliest idle-prevention press
    AntiIdleMaxSeconds = 420,     -- Latest idle-prevention press

    RetaliateToggleCooldown = 2,  -- Min seconds between auto retaliate toggle attempts
}

-- Sustain item / ability ids.
local ExcaliburIds = { 35, 8280, 14632, 36619, 36620 } -- all Excalibur variants
local ElvenShardId = 43358
local EatFoodAbilityId = 1601
-- Every Super Restore dose plus the blessed flask. Add any other prayer
-- restoring potion ids here.
local PrayerPotionIds = { 23399, 23401, 23403, 23405, 23407, 23409, 3024, 3026, 3028, 3030, 48680 }

-- Buff names accepted by Slib:BuffUpKeep, grouped for the Options tab. These
-- strings must match Slib exactly - an unknown name is rejected at runtime.
local BuffGroups = {
    {
        Name = "Potions",
        Buffs = { "Aggression", "Luck Potion", "Overload", "Weapon Poison" },
    },
    {
        Name = "Aspects",
        Buffs = { "Animate Dead", "Darkness", "Penance", "Temporal Anomaly", "Vampyrism" },
    },
    {
        Name = "Powders",
        Buffs = {
            "Powder of Burials", "Powder of Defense", "Powder of Item Protection",
            "Powder of Penance", "Powder of Protection", "Powder of Pulverising",
        },
    },
    {
        Name = "Incense Sticks",
        Buffs = {
            "Avantoe", "Bloodweed", "Cadantine", "Dwarf Weed", "Fellstalk", "Guam",
            "Harralander", "Irit", "Kwuarm", "Lantadyme", "Marrentill", "Ranarr",
            "Snapdragon", "Spirit Weed", "Tarromin", "Toadflax", "Torstol", "Wergali",
        },
    },
}

local ExcaliburModeVarbit = 54934
local ExcaliburWieldMode = 1     -- Wield mode   -> inventory option 2
local ExcaliburWieldOption = 2
local ExcaliburDefaultOption = 1 -- Default mode -> inventory option 1

local Strykewyrms = {
    ["Jungle strykewyrm"] = { WyrmId = 9467,  MoundId = 9466 },
    ["Desert strykewyrm"] = { WyrmId = 9465,  MoundId = 9464 },
    ["Ice strykewyrm"]    = { WyrmId = 9463,  MoundId = 9462 },
    ["Lava strykewyrm"]   = { WyrmId = 20630, MoundId = 2417 },
}
local MoundName = "Mound"
local MoundAction = "Investigate"
local NpcObjectType = 1
local AttackActionCode = 0x2a -- "Attack", used by the DoAction_NPC fallback

-- Targeting modes, cycled by the button on the Combat tab.
local TargetModes = { "list", "closest", "random" }
local TargetModeLabels = {
    list    = "Target: List order",
    closest = "Target: Closest",
    random  = "Target: Random",
}

-- Auto retaliate. The varbit reads 0 while it is ENABLED and non-zero while it
-- is disabled. There is no setter, only a toggle on the combat settings tab.
local AutoRetaliateVarbit = 42166
local AutoRetaliateOnValue = 0

-- ReadTargetInfo99().Target_Name reports this placeholder when the player has no
-- target. An empty string means the player is in combat without having targeted
-- anything itself, which happens when an NPC opens on the player.
local IdleTargetName = "Tap to find target"
-- #endregion

-- #region Theme ------------------------------------------------------------
-- Colours as {r, g, b} floats (0-1) for ImGui style pushes.
local Theme = {
    Bg       = { 0.09, 0.06, 0.15 },
    Title    = { 0.18, 0.11, 0.30 },
    Frame    = { 0.20, 0.14, 0.32 },
    Accent   = { 0.58, 0.35, 0.90 },
    AccentHi = { 0.72, 0.50, 1.00 },
    Good     = { 0.55, 0.45, 0.90 },
    Bad      = { 0.85, 0.35, 0.70 },
    Text     = { 0.93, 0.90, 0.98 },
    Muted    = { 0.64, 0.58, 0.75 },
}
-- #endregion

-- #region State ------------------------------------------------------------
local State = {
    Running = false,             -- Is the combat loop actively attacking
    StartTime = os.time(),       -- For runtime display
    ScannedNpcs = { "None" },    -- Names shown in the Refresh combo (written by main thread)
    ComboIndex = 0,              -- Currently selected combo index (0-based, ImGui convention)
    Priority = {},               -- Ordered list of names (index 1 = highest priority)
    TargetMode = "list",         -- One of TargetModes: list order, closest, or random
    LastTarget = "-",            -- Last NPC name we issued an attack on (display only)
    LastAttackedId = 0,          -- Unique id (AllObject.Unique_Id) of the last NPC attacked
    Loot = {},                   -- Loot list: array of { Id = number, Name = string }
    LootInput = "",              -- Current text of the loot id input box
    Sustain = {                  -- Sustain toggles (set from the Options tab)
        Excalibur = false,       -- Heal HP with Excalibur
        EatFood = false,         -- Heal HP by eating food
        ElvenShard = false,      -- Restore prayer with Elven Shard
        PrayerPotion = false,    -- Restore prayer by drinking a prayer potion
    },
    Thresholds = {               -- Adjustable percent levels (Options tab)
        Health = Config.DefaultHealthPercent, -- Eat food
        Prayer = Config.DefaultPrayerPercent, -- Drink a prayer potion
    },
    Buffs = {},                  -- Map of buff name -> true for buffs to keep up
    ExcaliburLastUsed = -300,    -- os.clock() of last Excalibur use (cooldown tracking)
    PrayerPotionLastUsed = 0,    -- os.clock() of last prayer potion sip
    LastBuffUpkeep = 0,          -- os.clock() of the last buff upkeep check
    LastExcaliburWarn = 0,       -- os.clock() of the last "no Excalibur" warning
    LastTargetSeen = os.time(),  -- Last time a target was attacked or being fought
    IdleTime = os.time(),        -- Last time the idle-prevention press ran
    NextIdleDelay = 0,           -- Seconds to wait before the next idle press
    RetaliateWasOn = nil,        -- Auto retaliate setting captured at startup, for restore
    LastRetaliateToggle = 0,     -- os.clock() of the last auto retaliate toggle
    StopQueued = false,          -- True once the window close button queued a stop
    Actions = {},                -- Queue of intents from the GUI thread, drained by main loop
}

State.NextIdleDelay = math.random(Config.AntiIdleMinSeconds, Config.AntiIdleMaxSeconds)

-- Enqueue an intent from the render/GUI thread for the main loop to process.
-- Payload is whatever that action needs: a list index, or the loot id text.
local function QueueAction(Kind, Payload)
    State.Actions[#State.Actions + 1] = { Kind = Kind, Payload = Payload }
end
-- #endregion

-- #region Persistence ------------------------------------------------------
-- User settings are stored inline in this same file, between the two markers
-- below. SaveConfig rewrites that block on disk, so the next run has SavedConfig
-- already populated by the time the file is loaded. This keeps the script a
-- single self-contained file with no external settings file.
-- The block is generated - do not edit it by hand.
--@@CONFIG_START
local SavedConfig = {["Priority"]={},["Loot"]={[1]={["Id"]=39814,["Name"]="Hazelmere's signet ring"}},["Sustain"]={["ElvenShard"]=false,["PrayerPotion"]=false,["EatFood"]=false,["Excalibur"]=false},["TargetMode"]="list",["Thresholds"]={["Health"]=25,["Prayer"]=25},["Buffs"]={}}
--@@CONFIG_END

local ScriptPath = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\Spectre's Basic Combat.lua"
local ConfigStartMarker = "--@@CONFIG_START"
local ConfigEndMarker = "--@@CONFIG_END"

-- Serialize a value (number/boolean/string/table) to a Lua literal string.
local function Serialize(Value)
    local T = type(Value)
    if T == "number" or T == "boolean" then
        return tostring(Value)
    elseif T == "string" then
        return string.format("%q", Value)
    elseif T == "table" then
        local Parts = {}
        for Key, Val in pairs(Value) do
            local KeyStr
            if type(Key) == "number" then
                KeyStr = "[" .. Key .. "]"
            else
                KeyStr = "[" .. string.format("%q", Key) .. "]"
            end
            Parts[#Parts + 1] = KeyStr .. "=" .. Serialize(Val)
        end
        return "{" .. table.concat(Parts, ",") .. "}"
    end
    return "nil"
end

-- Rewrite the inline config block in this script file with the current config.
local function SaveConfig()
    local File = io.open(ScriptPath, "r")
    if not File then
        Slib:Warn("[Config] Could not open script file to save config")
        return
    end
    local Content = File:read("*a")
    File:close()

    local StartPos = Content:find(ConfigStartMarker, 1, true)
    local EndPos = Content:find(ConfigEndMarker, 1, true)
    if not StartPos or not EndPos then
        Slib:Warn("[Config] Config markers missing, cannot save")
        return
    end

    local Data = {
        Priority = State.Priority,
        TargetMode = State.TargetMode,
        Loot = State.Loot,
        Sustain = State.Sustain,
        Thresholds = State.Thresholds,
        Buffs = State.Buffs,
    }
    local NewBlock = ConfigStartMarker .. "\nlocal SavedConfig = " .. Serialize(Data) .. "\n" .. ConfigEndMarker
    local NewContent = Content:sub(1, StartPos - 1) .. NewBlock .. Content:sub(EndPos + #ConfigEndMarker)

    local Out = io.open(ScriptPath, "w")
    if not Out then
        Slib:Warn("[Config] Could not open script file for writing")
        return
    end
    Out:write(NewContent)
    Out:close()
end

-- Copy SavedConfig into State, ignoring anything malformed so a damaged block
-- cannot stop the script from starting.
local function LoadConfig()
    if type(SavedConfig) ~= "table" then
        return
    end
    if type(SavedConfig.Priority) == "table" then
        State.Priority = SavedConfig.Priority
    end
    -- The label lookup doubles as validation, so an unknown mode keeps the default.
    if TargetModeLabels[SavedConfig.TargetMode] then
        State.TargetMode = SavedConfig.TargetMode
    end
    if type(SavedConfig.Loot) == "table" then
        State.Loot = SavedConfig.Loot
    end
    if type(SavedConfig.Sustain) == "table" then
        State.Sustain.Excalibur = SavedConfig.Sustain.Excalibur == true
        State.Sustain.EatFood = SavedConfig.Sustain.EatFood == true
        State.Sustain.ElvenShard = SavedConfig.Sustain.ElvenShard == true
        State.Sustain.PrayerPotion = SavedConfig.Sustain.PrayerPotion == true
    end
    if type(SavedConfig.Thresholds) == "table" then
        State.Thresholds.Health = tonumber(SavedConfig.Thresholds.Health) or State.Thresholds.Health
        State.Thresholds.Prayer = tonumber(SavedConfig.Thresholds.Prayer) or State.Thresholds.Prayer
    end
    if type(SavedConfig.Buffs) == "table" then
        State.Buffs = SavedConfig.Buffs
    end
    Slib:Info("[Config] Loaded saved settings")
end
-- #endregion

-- #region Helpers ----------------------------------------------------------
local function FormatRuntime()
    local Elapsed = os.time() - State.StartTime
    local Hours = math.floor(Elapsed / 3600)
    local Minutes = math.floor((Elapsed % 3600) / 60)
    local Seconds = Elapsed % 60
    return string.format("%02d:%02d:%02d", Hours, Minutes, Seconds)
end

local function PriorityContains(Name)
    for _, Existing in ipairs(State.Priority) do
        if Existing == Name then return true end
    end
    return false
end

-- Only a live target whose name is on the priority list counts as busy. An
-- unlisted attacker must not block the NPCs the user actually asked for.
local function IsReadyToAttack()
    local Target = API.ReadTargetInfo99(true)
    if Target == nil then
        return false
    end
    if Target.Target_Name == IdleTargetName then
        return true
    end
    if Target.Hitpoints ~= nil and Target.Hitpoints <= 0 then
        return true
    end
    return not PriorityContains(Target.Target_Name)
end

-- Press the idle-prevention key on a random interval so a quiet session (no
-- targets, or paused) is not logged out for inactivity.
local function AntiIdle()
    if os.difftime(os.time(), State.IdleTime) < State.NextIdleDelay then
        return
    end

    API.PIdle2()
    State.IdleTime = os.time()
    State.NextIdleDelay = math.random(Config.AntiIdleMinSeconds, Config.AntiIdleMaxSeconds)
    Slib:Info("[AntiIdle] Idle prevention triggered")
end

-- Is this NPC a live, attackable candidate?
local function IsValidNpc(Mob)
    return Mob ~= nil
        and Mob.Id ~= nil and Mob.Id ~= 0
        and Mob.Name ~= nil and Mob.Name ~= ""
        and Mob.Life ~= nil and Mob.Life > 0
end
-- #endregion

-- #region Auto retaliate ---------------------------------------------------
-- The script forces auto retaliate on while it has targets to attack, and puts
-- the player's original setting back on exit. With an empty priority list it
-- leaves the setting alone entirely.
local function IsAutoRetaliateOn()
    return API.GetVarbitValue(AutoRetaliateVarbit) == AutoRetaliateOnValue
end

local function ToggleAutoRetaliate()
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1430, 59, -1, API.OFF_ACT_GeneralInterface_route)
    State.LastRetaliateToggle = os.clock()
end

-- Record the player's setting once at startup so it can be put back on exit.
-- Skipped when logged out, where the varbit would read a meaningless value.
local function RememberAutoRetaliate()
    if not API.PlayerLoggedIn() then
        Slib:Warn("[Retaliate] Not logged in, auto retaliate will not be managed")
        return
    end

    State.RetaliateWasOn = IsAutoRetaliateOn()
    Slib:Info("[Retaliate] Auto retaliate was " .. (State.RetaliateWasOn and "on" or "off"))
end

-- Throttled because the varbit takes a moment to update after a toggle.
local function EnforceAutoRetaliate()
    if State.RetaliateWasOn == nil then return end
    -- Nothing is being attacked, so leave the setting as the player had it
    -- rather than dragging them into fights.
    if #State.Priority == 0 then return end
    if IsAutoRetaliateOn() then return end
    if os.clock() - State.LastRetaliateToggle < Config.RetaliateToggleCooldown then return end

    Slib:Info("[Retaliate] Turning auto retaliate on")
    ToggleAutoRetaliate()
end

-- Put auto retaliate back the way we found it. Runs once, after the main loop.
local function RestoreAutoRetaliate()
    if State.RetaliateWasOn == nil then return end
    if not API.PlayerLoggedIn() then
        Slib:Warn("[Retaliate] Not logged in, cannot restore auto retaliate")
        return
    end
    if State.RetaliateWasOn == IsAutoRetaliateOn() then return end

    Slib:Info("[Retaliate] Restoring auto retaliate to " .. (State.RetaliateWasOn and "on" or "off"))
    ToggleAutoRetaliate()
end
-- #endregion

-- #region NPC scanning -----------------------------------------------------
-- Reads every NPC around the player, annotates Distance, filters to
-- valid/alive/in-range, sorted nearest first. Main thread only.
local function ScanNearbyNpcs()
    local All = API.ReadAllObjectsArray({ NpcObjectType }, {}, {})
    local Result = {}

    if All == nil then
        return Result
    end

    local PlayerPos = API.PlayerCoordfloat()
    for _, Mob in ipairs(All) do
        Mob.Distance = API.Math_DistanceF(Mob.Tile_XYZ, PlayerPos)
        if IsValidNpc(Mob) and Mob.Distance <= Config.ScanRange then
            table.insert(Result, Mob)
        end
    end

    table.sort(Result, function(A, B) return A.Distance < B.Distance end)
    return Result
end

-- Find the nearest mound of a given type. Mounds are inert NPCs, so they can
-- have no life and would be dropped by the ScanNearbyNpcs filters.
local function FindMound(MoundId, Range)
    return Slib:FindObj(MoundId, Range, NpcObjectType)
end

-- Refresh: scan and rebuild the combo list with distinct names.
local function RefreshNpcList()
    local Mobs = ScanNearbyNpcs()
    local Names = {}
    local Seen = {}

    for _, Mob in ipairs(Mobs) do
        -- Mounds are never a target themselves: the script investigates them to
        -- spawn a wyrm. Listing them would make it ambiguous which entry to add,
        -- so only the wyrm name (added below) is offered.
        if Mob.Name ~= MoundName and not Seen[Mob.Name] then
            Seen[Mob.Name] = true
            Names[#Names + 1] = Mob.Name
        end
    end

    -- An unspawned strykewyrm is invisible to the scan, so offer its name
    -- whenever the matching mound is nearby - otherwise it could never be added
    -- to the priority list.
    for WyrmName, Entry in pairs(Strykewyrms) do
        if not Seen[WyrmName] and FindMound(Entry.MoundId, Config.ScanRange) ~= nil then
            Seen[WyrmName] = true
            Names[#Names + 1] = WyrmName
        end
    end

    if #Names == 0 then
        Names = { "None" }
    end

    State.ScannedNpcs = Names
    if State.ComboIndex >= #Names then
        State.ComboIndex = 0
    end
    Slib:Info(string.format("[Refresh] Found %d nearby NPC name(s)", #Names))
end
-- #endregion

-- #region Priority list (main thread) --------------------------------------
local function SelectedNpcName()
    return State.ScannedNpcs[State.ComboIndex + 1]
end

local function AddToPriority()
    local Name = SelectedNpcName()
    if Name == nil or Name == "" or Name == "None" then
        Slib:Warn("[Priority] No valid NPC selected to add")
        return
    end
    if #State.Priority >= Config.MaxPriorityEntries then
        Slib:Warn("[Priority] List is full (" .. Config.MaxPriorityEntries .. " max)")
        return
    end
    if PriorityContains(Name) then
        Slib:Warn("[Priority] '" .. Name .. "' already in list")
        return
    end
    State.Priority[#State.Priority + 1] = Name
    Slib:Info("[Priority] Added '" .. Name .. "' at position " .. #State.Priority)
end

local function RemoveAt(Index)
    if Index and State.Priority[Index] then
        local Removed = table.remove(State.Priority, Index)
        Slib:Info("[Priority] Removed '" .. tostring(Removed) .. "'")
    end
end

local function MoveUp(Index)
    if Index and Index > 1 and State.Priority[Index] then
        State.Priority[Index], State.Priority[Index - 1] = State.Priority[Index - 1], State.Priority[Index]
    end
end

local function MoveDown(Index)
    if Index and State.Priority[Index] and State.Priority[Index + 1] then
        State.Priority[Index], State.Priority[Index + 1] = State.Priority[Index + 1], State.Priority[Index]
    end
end

local function ClearPriority()
    State.Priority = {}
    Slib:Info("[Priority] Cleared list")
end

local function ToggleRunning()
    State.Running = not State.Running
    Slib:Info(State.Running and "[Combat] Started" or "[Combat] Paused")
end

-- Step to the next targeting mode, wrapping back to the first.
local function CycleTargetMode()
    local Current = 1
    for Index, Mode in ipairs(TargetModes) do
        if Mode == State.TargetMode then
            Current = Index
            break
        end
    end

    State.TargetMode = TargetModes[(Current % #TargetModes) + 1]
    Slib:Info("[Priority] Targeting mode: " .. State.TargetMode)
end

-- Resolve an item id to its id and display name via Item:Get.
-- Returns nil when the input is not a number or no item matches.
local function ResolveItem(Input)
    local Id = tonumber(Input)
    if Id == nil or Id <= 0 then
        return nil
    end

    local Ok, Data = pcall(function() return Item:Get(Id) end)
    if Ok and Data ~= nil and Data.id ~= nil and Data.id > 0 then
        local Name = (Data.name ~= nil and Data.name ~= "") and Data.name or "Unknown"
        return Data.id, Name
    end

    return nil
end

local function LootContains(Id)
    for _, Entry in ipairs(State.Loot) do
        if Entry.Id == Id then return true end
    end
    return false
end

local function AddLoot(Input)
    if Input == nil or Input == "" then
        Slib:Warn("[Loot] No item id entered")
        return
    end

    local Id, Name = ResolveItem(Input)
    if Id == nil then
        Slib:Warn("[Loot] No item found for id '" .. tostring(Input) .. "'")
        return
    end
    if LootContains(Id) then
        Slib:Warn("[Loot] Item " .. Id .. " (" .. Name .. ") already in list")
        return
    end

    State.Loot[#State.Loot + 1] = { Id = Id, Name = Name }
    Slib:Info("[Loot] Added " .. Id .. " (" .. Name .. ")")
end

local function RemoveLootAt(Index)
    if Index and State.Loot[Index] then
        local Removed = table.remove(State.Loot, Index)
        Slib:Info("[Loot] Removed " .. Removed.Id .. " (" .. Removed.Name .. ")")
    end
end

local function ClearLoot()
    State.Loot = {}
    Slib:Info("[Loot] Cleared list")
end

-- Action kinds that change saved config, so the file is rewritten after them.
local ConfigChangingActions = {
    add = true, remove = true, up = true, down = true, clear = true,
    lootadd = true, lootremove = true, lootclear = true, savesettings = true,
    togglemode = true,
}

-- Drain the GUI action queue. Runs at the top of every main loop iteration.
local function ProcessActions()
    local Dirty = false
    while #State.Actions > 0 do
        local Action = table.remove(State.Actions, 1)
        local Kind = Action.Kind
        if Kind == "refresh" then
            RefreshNpcList()
        elseif Kind == "add" then
            AddToPriority()
        elseif Kind == "remove" then
            RemoveAt(Action.Payload)
        elseif Kind == "up" then
            MoveUp(Action.Payload)
        elseif Kind == "down" then
            MoveDown(Action.Payload)
        elseif Kind == "clear" then
            ClearPriority()
        elseif Kind == "lootadd" then
            AddLoot(Action.Payload)
        elseif Kind == "lootremove" then
            RemoveLootAt(Action.Payload)
        elseif Kind == "lootclear" then
            ClearLoot()
        elseif Kind == "togglemode" then
            CycleTargetMode()
        elseif Kind == "toggle" then
            ToggleRunning()
        elseif Kind == "stop" then
            Slib:Info("[Script] Stop pressed")
            API.Write_LoopyLoop(false)
        end

        if ConfigChangingActions[Kind] then
            Dirty = true
        end
    end

    if Dirty then
        SaveConfig()
    end
end
-- #endregion

-- #region Combat -----------------------------------------------------------
-- Can this scanned NPC be attacked right now? Excludes the NPC we just attacked
-- by unique id, because its Life can still read > 0 during the death animation
-- and we would re-click the same corpse.
local function IsAttackable(Mob)
    return Mob.Distance <= Config.AttackRange
        and Mob.Unique_Id ~= State.LastAttackedId
end

-- The NPC currently attacking the player, if it is one we are allowed to hit.
-- Matched back to the scan by unique id so it carries a Distance and has already
-- passed the scan filters.
local function FindAggressor(Candidates)
    local Attackers = API.OthersInteractingWithLpNPC(true, 0)
    if Attackers == nil then
        return nil
    end

    for _, Attacker in ipairs(Attackers) do
        for _, Mob in ipairs(Candidates) do
            if Mob.Unique_Id == Attacker.Unique_Id
                and IsAttackable(Mob)
                and PriorityContains(Mob.Name) then
                return Mob
            end
        end
    end
    return nil
end

-- Every listed NPC of a given name, nearest first.
local function CandidatesNamed(Candidates, Name)
    local Matches = {}
    for _, Mob in ipairs(Candidates) do
        if IsAttackable(Mob) and Mob.Name == Name then
            Matches[#Matches + 1] = Mob
        end
    end
    return Matches
end

-- Build the attack order, best target first:
--   list    -> nearest NPC of the topmost listed name that is present
--   closest -> nearest NPC matching any listed name
--   random  -> nearest NPC of a randomly chosen listed name
-- Candidates arrive sorted nearest first, so preserving their order is what
-- makes each mode pick the nearest. In every mode an NPC already attacking the
-- player is promoted to the front.
local function OrderTargets(Candidates)
    local Targets = {}

    if State.TargetMode == "closest" then
        for _, Mob in ipairs(Candidates) do
            if IsAttackable(Mob) and PriorityContains(Mob.Name) then
                Targets[#Targets + 1] = Mob
            end
        end

    elseif State.TargetMode == "random" then
        -- Randomise the name, not the NPC: collect the listed names that are
        -- actually present, pick one, then take that name's NPCs nearest first.
        local Available = {}
        local Seen = {}
        for _, Mob in ipairs(Candidates) do
            if IsAttackable(Mob) and PriorityContains(Mob.Name) and not Seen[Mob.Name] then
                Seen[Mob.Name] = true
                Available[#Available + 1] = Mob.Name
            end
        end

        if #Available > 0 then
            Targets = CandidatesNamed(Candidates, Available[math.random(#Available)])
        end

    else -- list order
        for _, WantedName in ipairs(State.Priority) do
            for _, Mob in ipairs(CandidatesNamed(Candidates, WantedName)) do
                Targets[#Targets + 1] = Mob
            end
        end
    end

    local Aggressor = FindAggressor(Candidates)
    if Aggressor ~= nil then
        -- Pull it out of wherever the mode placed it so it is not listed twice.
        for Index, Mob in ipairs(Targets) do
            if Mob.Unique_Id == Aggressor.Unique_Id then
                table.remove(Targets, Index)
                break
            end
        end
        table.insert(Targets, 1, Aggressor)
    end

    return Targets
end

-- Spawn a strykewyrm by investigating the mound of its type. Returns true if an
-- investigate was sent.
local function InvestigateMound(WyrmName)
    local Entry = Strykewyrms[WyrmName]
    if Entry == nil then
        return false
    end

    local Mound = FindMound(Entry.MoundId, Config.AttackRange)
    if Mound == nil then
        return false
    end

    Slib:Info(string.format("[Combat] Investigating mound %d for %s (dist=%.1f)",
        Entry.MoundId, WyrmName, Mound.Distance))

    -- Interact matches by name and every mound is called "Mound", so the tile of
    -- the mound we identified by id is what pins down the right type. The range
    -- is measured against the player, so it matches the normal attack range.
    local MoundTile = WPOINT.new(math.floor(Mound.Tile_XYZ.x), math.floor(Mound.Tile_XYZ.y), Mound.Floor)

    if Interact:NPC(MoundName, MoundAction, MoundTile, Config.AttackRange) then
        Slib:RandomSleep(Config.MoundMinSleep, Config.MoundMaxSleep, "ms")
        API.WaitUntilMovingEnds()
        return true
    end

    Slib:Warn("[Combat] Investigate failed for the " .. WyrmName .. " mound")
    return false
end

-- Attack the best target from the scan, using the selected targeting mode.
local function AttackByPriority()
    if #State.Priority == 0 then
        return false
    end

    if not IsReadyToAttack() then
        return false
    end

    local Candidates = ScanNearbyNpcs()

    -- Stop excluding the last attacked NPC once it is gone from the scan,
    -- otherwise the exclusion never clears and an area with a single spawn
    -- stalls after the first kill.
    if State.LastAttackedId ~= 0 then
        local StillPresent = false
        for _, Mob in ipairs(Candidates) do
            if Mob.Unique_Id == State.LastAttackedId then
                StillPresent = true
                break
            end
        end
        if not StillPresent then
            State.LastAttackedId = 0
        end
    end

    for _, Mob in ipairs(OrderTargets(Candidates)) do
        Slib:Info(string.format("[Combat] Attacking %s (Id=%s, uid=%s, dist=%.1f)",
            Mob.Name, tostring(Mob.Id), tostring(Mob.Unique_Id), Mob.Distance))
        local TargetTile = WPOINT.new(math.floor(Mob.Tile_XYZ.x), math.floor(Mob.Tile_XYZ.y), Mob.Floor)

        -- Interact resolves the action from the NPC definition looked up by
        -- name. For some NPCs that lookup yields no action offset and the call
        -- silently does nothing, so fall back to an id search over the live
        -- object list, which does not need the definition.
        local Sent = Interact:NPC(Mob.Name, "Attack", TargetTile, Config.AttackRange)
        if not Sent then
            Sent = API.DoAction_NPC(AttackActionCode, API.OFF_ACT_AttackNPC_route,
                { Mob.Id }, Config.AttackRange)
        end

        if Sent then
            State.LastTarget = Mob.Name
            State.LastAttackedId = Mob.Unique_Id
            Slib:RandomSleep(Config.AttackMinSleep, Config.AttackMaxSleep, "ms")
            API.WaitUntilMovingEnds()
            return true
        end
        Slib:Warn("[Combat] Attack call failed for " .. Mob.Name)
    end

    -- Nothing alive to attack. A listed strykewyrm has to be spawned from its
    -- mound before it can be fought, so try that next.
    for _, WantedName in ipairs(State.Priority) do
        if Strykewyrms[WantedName] and InvestigateMound(WantedName) then
            return true
        end
    end

    return false
end

-- Loot the configured item ids off the ground around the player.
local function LootGround()
    if #State.Loot == 0 then
        return false
    end

    local Ids = {}
    for _, Entry in ipairs(State.Loot) do
        Ids[#Ids + 1] = Entry.Id
    end

    local Ok = API.DoAction_Loot_o(Ids, Config.LootRange, API.PlayerCoordfloat(), Config.LootRange)
    if Ok then
        Slib:Info("[Loot] Looting nearby items")
        Slib:RandomSleep(Config.LootMinSleep, Config.LootMaxSleep, "ms")
    end
    return Ok
end

-- Heal with the first Excalibur variant held in the inventory. Which inventory
-- option triggers the heal depends on the item's in-game mode setting.
local function HealWithExcalibur()
    if not State.Sustain.Excalibur then return end
    if API.GetHPrecent() > Config.ExcaliburPercent then return end
    if os.clock() - State.ExcaliburLastUsed < Config.ExcaliburCooldown then return end

    local WieldMode = API.GetVarbitValue(ExcaliburModeVarbit) == ExcaliburWieldMode
    local Option = WieldMode and ExcaliburWieldOption or ExcaliburDefaultOption

    for _, Id in ipairs(ExcaliburIds) do
        if Inventory:Contains(Id) then
            -- Only start the cooldown if the click was actually sent.
            if API.DoAction_Inventory1(Id, 0, Option, API.OFF_ACT_GeneralInterface_route) then
                State.ExcaliburLastUsed = os.clock()
                Slib:Info("[Sustain] Used Excalibur (" .. Id .. ") in "
                    .. (WieldMode and "wield" or "default") .. " mode")
            end
            return
        end
    end

    -- Throttled, or it repeats every loop iteration for as long as HP stays low.
    if os.clock() - State.LastExcaliburWarn >= Config.SustainWarnInterval then
        State.LastExcaliburWarn = os.clock()
        Slib:Warn("[Sustain] No Excalibur found in the inventory")
    end
end

local function EatFood()
    if not State.Sustain.EatFood then return end
    if API.GetHPrecent() > State.Thresholds.Health then return end

    -- UseAbilityById returns false when the ability is missing, disabled or on
    -- its food cooldown, so only log an eat that actually happened.
    if Inventory:HasFood() and Slib:UseAbilityById(EatFoodAbilityId) then
        Slib:Info("[Sustain] Ate food")
    end
end

-- The shard applies a cooldown debuff while it is spent, which is what stops it
-- being used again too soon.
local function RestorePrayer()
    if not State.Sustain.ElvenShard then return end
    if API.GetPrayPrecent() > Config.ElvenShardPercent then return end

    if Inventory:Contains(ElvenShardId) and not Slib:HasDebuff(ElvenShardId) then
        if API.DoAction_Inventory1(ElvenShardId, 0, 1, API.OFF_ACT_GeneralInterface_route) then
            Slib:Info("[Sustain] Used Elven Shard")
        end
    end
end

local function DrinkPrayerPotion()
    if not State.Sustain.PrayerPotion then return end
    if API.GetPrayPrecent() > State.Thresholds.Prayer then return end
    -- Prayer% takes a tick to update, so without this several doses get sipped.
    if os.clock() - State.PrayerPotionLastUsed < Config.PrayerPotionCooldown then return end

    if Inventory:ContainsAny(PrayerPotionIds) then
        if API.DoAction_Inventory2(PrayerPotionIds, 0, 1, API.OFF_ACT_GeneralInterface_route) then
            State.PrayerPotionLastUsed = os.clock()
            Slib:Info("[Sustain] Drank a prayer potion")
        end
    end
end

-- Keep the selected buffs up. Throttled so Slib:BuffUpKeep (which reads the buff
-- bar and can drink potions) is not called on every loop iteration.
local function UpkeepBuffs()
    if os.clock() - State.LastBuffUpkeep < Config.BuffUpkeepInterval then return end

    local Names = {}
    for _, Group in ipairs(BuffGroups) do
        for _, Name in ipairs(Group.Buffs) do
            if State.Buffs[Name] then
                Names[#Names + 1] = Name
            end
        end
    end
    if #Names == 0 then return end

    State.LastBuffUpkeep = os.clock()
    Slib:BuffUpKeep(Names)
end

-- Stop the script and log out when nothing has been fought for a while, which
-- means the spot is empty or nothing here matches the priority list. The timer
-- only runs while actually hunting, so being paused or having an empty priority
-- list never counts against it.
local function CheckNoTargetTimeout(FoundTarget)
    if not State.Running or #State.Priority == 0 or FoundTarget then
        State.LastTargetSeen = os.time()
        return
    end

    if os.difftime(os.time(), State.LastTargetSeen) < Config.NoTargetTimeout then
        return
    end

    Slib:Warn(string.format("[Script] No target for %d seconds, stopping", Config.NoTargetTimeout))
    State.Running = false
    API.Write_LoopyLoop(false)
    Slib:Lobby()
end

-- Run all enabled sustain checks. Each is a no-op when its toggle is off.
local function Sustain()
    HealWithExcalibur()
    EatFood()
    RestorePrayer()
    DrinkPrayerPotion()
    UpkeepBuffs()
end
-- #endregion

-- #region GUI (render thread) ----------------------------------------------
-- Runs on the ImGui render callback, concurrently with the main loop. Nothing
-- here touches the game or mutates lists: it reads State and queues actions.
local function ColoredText(Color, Text)
    ImGui.TextColored(Color[1], Color[2], Color[3], 1.0, Text)
end

local function PushWindowStyle()
    ImGui.PushStyleColor(ImGuiCol.WindowBg, Theme.Bg[1], Theme.Bg[2], Theme.Bg[3], 0.96)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, Theme.Title[1], Theme.Title[2], Theme.Title[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, Theme.Frame[1], Theme.Frame[2], Theme.Frame[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 0.7)
    ImGui.PushStyleColor(ImGuiCol.Button, Theme.Frame[1], Theme.Frame[2], Theme.Frame[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, Theme.AccentHi[1], Theme.AccentHi[2], Theme.AccentHi[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.Header, Theme.Frame[1], Theme.Frame[2], Theme.Frame[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 0.8)
    ImGui.PushStyleColor(ImGuiCol.Separator, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 0.4)
    ImGui.PushStyleColor(ImGuiCol.Tab, Theme.Frame[1], Theme.Frame[2], Theme.Frame[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.TabHovered, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.TabActive, Theme.Accent[1], Theme.Accent[2], Theme.Accent[3], 0.8)
    ImGui.PushStyleColor(ImGuiCol.CheckMark, Theme.AccentHi[1], Theme.AccentHi[2], Theme.AccentHi[3], 1.0)
    ImGui.PushStyleColor(ImGuiCol.Text, Theme.Text[1], Theme.Text[2], Theme.Text[3], 1.0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 12, 10)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 7, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 6)
end

-- Counts must match the pushes in PushWindowStyle above.
local function PopWindowStyle()
    ImGui.PopStyleVar(4)
    ImGui.PopStyleColor(16)
end

local function DrawStatus()
    if not State.Running then
        ColoredText(Theme.Bad, "Paused")
    elseif #State.Priority == 0 then
        -- No targets listed: buffs, loot and sustain only.
        ColoredText(Theme.Good, "Running (support)")
    else
        ColoredText(Theme.Good, "Running")
    end
    ImGui.SameLine(0, 12)
    ColoredText(Theme.Muted, "Runtime " .. FormatRuntime())
    ImGui.SameLine(0, 12)
    ColoredText(Theme.Muted, "Last: " .. State.LastTarget)
end

local function DrawScanControls()
    ImGui.SeparatorText("Nearby NPCs")

    if ImGui.Button("Refresh", 90, 26) then
        QueueAction("refresh")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Scan for NPCs near the player")
    end
    ImGui.SameLine(0, 8)

    ImGui.PushItemWidth(150)
    local Changed, NewIndex = ImGui.Combo("##npccombo", State.ComboIndex, State.ScannedNpcs)
    if Changed then
        State.ComboIndex = NewIndex
    end
    ImGui.PopItemWidth()

    ImGui.SameLine(0, 8)
    if ImGui.Button("Add", 60, 26) then
        QueueAction("add")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Add selected NPC to the priority list.\n"
            .. "For strykewyrms add the wyrm itself - the script investigates\n"
            .. "the matching mound to spawn it.")
    end
end

local function DrawPriorityList()
    ImGui.SeparatorText("Kill Priority")

    local ModeLabel = TargetModeLabels[State.TargetMode] or TargetModeLabels.list
    if ImGui.Button(ModeLabel .. "###targetmode", 180, 24) then
        QueueAction("togglemode")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Click to cycle targeting mode.\n"
            .. "List order: nearest NPC of the topmost listed name that is around.\n"
            .. "Closest: nearest NPC matching any listed name.\n"
            .. "Random: nearest NPC of a randomly picked listed name.\n"
            .. "All modes hit whatever is already attacking you first.")
    end
    ImGui.Spacing()

    if #State.Priority == 0 then
        ColoredText(Theme.Muted, "Empty - nothing will be attacked.")
        ColoredText(Theme.Muted, "Running like this still buffs, loots and heals.")
    else
        for Index, Name in ipairs(State.Priority) do
            ImGui.PushID(Index)
            ColoredText(Theme.AccentHi, string.format("%d.", Index))
            ImGui.SameLine(0, 6)
            ImGui.Text(Name)

            if Strykewyrms[Name] then
                ImGui.SameLine(0, 6)
                ColoredText(Theme.Muted, "(from mound)")
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip("Spawned by investigating its mound, then attacked.\n"
                        .. "Add only the wyrm - the mound is handled automatically.")
                end
            end

            ImGui.SameLine(0, 12)
            if ImGui.ArrowButton("up", 2) then   -- 2 = Up
                QueueAction("up", Index)
            end
            ImGui.SameLine(0, 4)
            if ImGui.ArrowButton("down", 3) then -- 3 = Down
                QueueAction("down", Index)
            end
            ImGui.SameLine(0, 8)
            if ImGui.SmallButton("x") then
                QueueAction("remove", Index)
            end
            ImGui.PopID()
        end

        ImGui.Spacing()
        if ImGui.Button("Clear List", 100, 24) then
            QueueAction("clear")
        end
    end
end

local function DrawLootControls()
    ImGui.SeparatorText("Add Loot Item")

    ImGui.PushItemWidth(150)
    local Changed, NewText = ImGui.InputTextWithHint("##lootinput", "Item id", State.LootInput)
    if Changed then
        State.LootInput = NewText
    end
    ImGui.PopItemWidth()

    ImGui.SameLine(0, 8)
    if ImGui.Button("Add##lootadd", 60, 26) then
        QueueAction("lootadd", State.LootInput)
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Add an item to the loot list by id")
    end
end

local function DrawLootList()
    ImGui.SeparatorText("Loot Items")

    if #State.Loot == 0 then
        ColoredText(Theme.Muted, "Empty. Enter an item id, then Add.")
    else
        for Index, Entry in ipairs(State.Loot) do
            ImGui.PushID("loot" .. Index)
            ColoredText(Theme.AccentHi, tostring(Entry.Id))
            ImGui.SameLine(0, 8)
            ImGui.Text(tostring(Entry.Name))

            ImGui.SameLine(0, 12)
            if ImGui.SmallButton("x") then
                QueueAction("lootremove", Index)
            end
            ImGui.PopID()
        end

        ImGui.Spacing()
        if ImGui.Button("Clear Loot", 100, 24) then
            QueueAction("lootclear")
        end
    end
end

-- A checkbox bound to a Sustain toggle, saving the config when it changes.
local function SustainCheckbox(Label, Key, Tooltip)
    local Changed, Value = ImGui.Checkbox(Label, State.Sustain[Key])
    if Changed then
        State.Sustain[Key] = Value
        QueueAction("savesettings")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip(Tooltip)
    end
end

-- A percent slider bound to a Thresholds value. The config is only saved once
-- the drag ends, otherwise the file would be rewritten on every frame.
local function ThresholdSlider(Label, Key)
    ImGui.PushItemWidth(140)
    local Changed, Value = ImGui.SliderInt(Label, State.Thresholds[Key], 1, 99, "%d%%")
    if Changed then
        State.Thresholds[Key] = Value
    end
    if ImGui.IsItemDeactivatedAfterEdit() then
        QueueAction("savesettings")
    end
    ImGui.PopItemWidth()
end

local function DrawOptions()
    ImGui.SeparatorText("Health")

    SustainCheckbox("Excalibur", "Excalibur",
        "Heal with Excalibur when HP is at or below " .. Config.ExcaliburPercent .. "% (fixed)")
    SustainCheckbox("Eat Food", "EatFood", "Eat food when HP is at or below the level below")
    ThresholdSlider("Food HP##healthpct", "Health")

    ImGui.SeparatorText("Prayer")

    SustainCheckbox("Elven Shard", "ElvenShard",
        "Restore prayer with an Elven Shard when prayer is at or below " .. Config.ElvenShardPercent .. "% (fixed)")
    SustainCheckbox("Prayer Potion", "PrayerPotion", "Drink a prayer potion when prayer is at or below the level below")
    ThresholdSlider("Potion prayer##prayerpct", "Prayer")

    ImGui.SeparatorText("Buffs to keep up")

    ImGui.BeginChild("##bufflist", 0, 200, 1)
    for _, Group in ipairs(BuffGroups) do
        ImGui.SeparatorText(Group.Name)
        for _, Name in ipairs(Group.Buffs) do
            local Changed, Value = ImGui.Checkbox(Name, State.Buffs[Name] == true)
            if Changed then
                -- Store nil instead of false so the saved config stays compact.
                State.Buffs[Name] = Value or nil
                QueueAction("savesettings")
            end
        end
    end
    ImGui.EndChild()
end

local function DrawControls()
    ImGui.Separator()

    local StartLabel = State.Running and "Pause" or "Start"
    local Color = State.Running and Theme.Bad or Theme.Good
    ImGui.PushStyleColor(ImGuiCol.Button, Color[1] * 0.7, Color[2] * 0.7, Color[3] * 0.7, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, Color[1], Color[2], Color[3], 1.0)
    if ImGui.Button(StartLabel .. "###toggle", 130, 30) then
        QueueAction("toggle")
    end
    ImGui.PopStyleColor(2)

    ImGui.SameLine(0, 10)
    if ImGui.Button("Stop Script", 130, 30) then
        QueueAction("stop")
    end
end

local function DrawGui()
    ImGui.SetNextWindowSize(340, 0, ImGuiCond.Always)
    ImGui.SetNextWindowPos(60, 60, ImGuiCond.FirstUseEver)

    PushWindowStyle()
    -- This Begin overload returns two values: open is false on the frame the
    -- title bar X is clicked, visible is false while the window is collapsed.
    local Open, Visible = ImGui.Begin(
        ScriptName .. " v" .. ScriptVersion .. " by " .. Author .. "###SpectreBasicCombat", true)
    if Visible then
        local Ok, Err = pcall(function()
            DrawStatus()
            ImGui.Spacing()

            if ImGui.BeginTabBar("##maintabs") then
                if ImGui.BeginTabItem("Combat") then
                    ImGui.Spacing()
                    DrawScanControls()
                    DrawPriorityList()
                    ImGui.EndTabItem()
                end
                if ImGui.BeginTabItem("Loot") then
                    ImGui.Spacing()
                    DrawLootControls()
                    DrawLootList()
                    ImGui.EndTabItem()
                end
                if ImGui.BeginTabItem("Options") then
                    ImGui.Spacing()
                    DrawOptions()
                    ImGui.EndTabItem()
                end
                ImGui.EndTabBar()
            end

            DrawControls()
        end)
        if not Ok then
            ImGui.TextColored(1.0, 0.3, 0.3, 1.0, "GUI error: " .. tostring(Err))
        end
    end
    ImGui.End()
    PopWindowStyle()

    -- Closing the window stops the script. Queued once so a slow shutdown does
    -- not pile up duplicate stop actions.
    if not Open and not State.StopQueued then
        State.StopQueued = true
        QueueAction("stop")
    end
end
-- #endregion

-- #region Main loop --------------------------------------------------------
-- Load saved config before the render callback starts reading State.
LoadConfig()

-- The client keeps render callbacks across script runs, so a stale one from a
-- previous run would draw a second window on top of this one.
if type(ClearRender) == "function" then
    ClearRender()
end

if type(DrawImGui) == "function" then
    DrawImGui(function()
        DrawGui()
    end)
end

API.Write_LoopyLoop(true)
RefreshNpcList()
RememberAutoRetaliate()
Slib:Info("[Script] " .. ScriptName .. " v" .. ScriptVersion .. " started")

while API.Read_LoopyLoop() do
    -- GUI actions are safe to drain at any time; everything below this point
    -- touches the game, so it is skipped while logged out. The loop stays alive
    -- so the script picks straight back up on reconnect.
    ProcessActions()

    if not API.PlayerLoggedIn() then
        Slib:RandomSleep(Config.LoopMinSleep, Config.LoopMaxSleep, "ms")
        goto continue
    end

    API.DoRandomEvents()
    AntiIdle()
    EnforceAutoRetaliate()

    if State.Running then
        -- Runs mid-combat too, so heals are never held up by the attack logic.
        Sustain()

        -- Looting runs mid-combat too. Only skipped on the tick an attack was
        -- just sent, so the loot walk does not cancel the approach to it.
        local Attacked = AttackByPriority()
        local Idle = IsReadyToAttack()
        if not Attacked then
            LootGround()
        end

        -- Landing an attack, or already being locked in a fight, both count as
        -- having a target.
        CheckNoTargetTimeout(Attacked or not Idle)
    else
        CheckNoTargetTimeout(false)
    end

    Slib:RandomSleep(Config.LoopMinSleep, Config.LoopMaxSleep, "ms")
    ::continue::
end

-- Leave the player's settings as we found them.
RestoreAutoRetaliate()
Slib:Info("[Script] " .. ScriptName .. " stopped")
-- #endregion
