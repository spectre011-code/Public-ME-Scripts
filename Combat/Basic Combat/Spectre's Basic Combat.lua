ScriptName = "Basic Combat"
Author = "Spectre011"
ScriptVersion = "1.0.0"
ReleaseDate = "24-07-2026"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0 - 24-07-2026
    - Initial release.
]]

local API = require("api")
local Slib = require("slib")

math.randomseed(os.time())

-- #region Config -----------------------------------------------------------
-- Tunables. Edit these to change behaviour without touching the logic below.
local Config = {
    ScanRange = 50,            -- Tile distance to include an NPC when scanning
    AttackRange = 50,          -- Tile distance to attack a priority target
    MaxPriorityEntries = 12,   -- Cap on the priority list size
    LoopMinSleep = 200,        -- Main loop min sleep (ms)
    LoopMaxSleep = 600,        -- Main loop max sleep (ms)
    AttackMinSleep = 500,      -- Post-attack min sleep (ms)
    AttackMaxSleep = 900,      -- Post-attack max sleep (ms)
    LootRange = 20,            -- Tile distance / radius to loot ground items
    LootMinSleep = 400,        -- Post-loot min sleep (ms)
    LootMaxSleep = 700,        -- Post-loot max sleep (ms)

    -- Sustain
    HealHpThreshold = 50,      -- Use Excalibur when HP% at or below this
    EatHpThreshold = 50,       -- Eat food when HP% at or below this
    PrayerThreshold = 50,      -- Use Elven Shard when prayer% at or below this
    ExcaliburCooldown = 300,   -- Excalibur enhanced-heal cooldown (seconds)
}

-- Sustain item / ability ids.
local ExcaliburIds = { 35, 8280, 14632, 36619, 36620 } -- all Excalibur variants
local ElvenShardId = 43358
local EatFoodAbilityId = 1601

-- ReadTargetInfo99() states seen while testing (Target_Name + Hitpoints):
--   "Tap to find target"       -> idle, no target       -> free to attack
--   "" (empty), Hitpoints 0    -> just killed, settling  -> free to retarget
--   <npc name>, Hitpoints > 0  -> actively fighting      -> do NOT attack
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
    LastTarget = "-",            -- Last NPC name we issued an attack on (display only)
    LastAttackedId = 0,          -- Unique id (AllObject.Unique_Id) of the last NPC attacked
    Loot = {},                   -- Loot list: array of { Id = number, Name = string }
    LootInput = "",              -- Current text of the loot input box (id or name)
    Sustain = {                  -- Sustain toggles (set from the Options tab)
        Excalibur = false,       -- Heal HP with Excalibur
        EatFood = false,         -- Heal HP by eating food
        ElvenShard = false,      -- Restore prayer with Elven Shard
    },
    ExcaliburLastUsed = -300,    -- os.clock() of last Excalibur use (cooldown tracking)
    Actions = {},                -- Queue of intents from the GUI thread, drained by main loop
}

-- Enqueue an intent from the render/GUI thread for the main loop to process.
local function QueueAction(Kind, Index)
    State.Actions[#State.Actions + 1] = { Kind = Kind, Index = Index }
end
-- #endregion

-- #region Persistence ------------------------------------------------------
-- Config (priority list, loot list, sustain toggles) is stored inline in this
-- same script file, between the two markers below. SaveConfig rewrites that
-- block; on the next run SavedConfig is already populated when the file loads.
-- The block is auto-generated - do not edit it by hand.
--@@CONFIG_START
local SavedConfig = {}
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
        Loot = State.Loot,
        Sustain = State.Sustain,
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

-- Apply the inline SavedConfig (already loaded with the file) into State.
local function LoadConfig()
    if type(SavedConfig) ~= "table" then
        return
    end
    if type(SavedConfig.Priority) == "table" then
        State.Priority = SavedConfig.Priority
    end
    if type(SavedConfig.Loot) == "table" then
        State.Loot = SavedConfig.Loot
    end
    if type(SavedConfig.Sustain) == "table" then
        State.Sustain.Excalibur = SavedConfig.Sustain.Excalibur == true
        State.Sustain.EatFood = SavedConfig.Sustain.EatFood == true
        State.Sustain.ElvenShard = SavedConfig.Sustain.ElvenShard == true
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

-- True when the player is free to engage a new NPC:
--   * idle placeholder            -> no target, attack the next priority NPC
--   * current target at 0 hp      -> it is dead/dying, move on to a different NPC
-- Any real name with hp > 0 means we are still fighting and must be skipped.
local function IsReadyToAttack()
    local Target = API.ReadTargetInfo99(true)
    if Target == nil then
        return false
    end
    if Target.Target_Name == IdleTargetName then
        return true
    end
    return Target.Hitpoints ~= nil and Target.Hitpoints <= 0
end

-- Is this NPC a live, attackable candidate?
local function IsValidNpc(Mob)
    return Mob ~= nil
        and Mob.Id ~= nil and Mob.Id ~= 0
        and Mob.Name ~= nil and Mob.Name ~= ""
        and Mob.Life ~= nil and Mob.Life > 0
end
-- #endregion

-- #region NPC scanning -----------------------------------------------------
-- Reads every NPC around the player, annotates Distance, filters to
-- valid/alive/in-range, sorted nearest first. Main thread only.
local function ScanNearbyNpcs()
    local All = API.ReadAllObjectsArray({ 1 }, {}, {})
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

-- Refresh: scan and rebuild the combo list with distinct names.
local function RefreshNpcList()
    local Mobs = ScanNearbyNpcs()
    local Names = {}
    local Seen = {}

    for _, Mob in ipairs(Mobs) do
        if not Seen[Mob.Name] then
            Seen[Mob.Name] = true
            Names[#Names + 1] = Mob.Name
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

local function PriorityContains(Name)
    for _, Existing in ipairs(State.Priority) do
        if Existing == Name then return true end
    end
    return false
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

-- Resolve a loot input (id or name) to a list of { Id, Name } matches.
-- Numeric input is a single item id via Item:Get. A name uses Item:GetAll with
-- partial matching, so every matching item is returned.
local function ResolveItems(Input)
    local Results = {}
    local Num = tonumber(Input)

    if Num then
        local Ok, Data = pcall(function() return Item:Get(Num) end)
        if Ok and Data ~= nil and Data.id ~= nil and Data.id > 0 then
            local Name = (Data.name ~= nil and Data.name ~= "") and Data.name or "Unknown"
            Results[#Results + 1] = { Id = Data.id, Name = Name }
        end
        return Results
    end

    local Ok, List = pcall(function() return Item:GetAll(Input, true) end)
    if Ok and type(List) == "table" then
        for _, Data in ipairs(List) do
            if Data ~= nil and Data.id ~= nil and Data.id > 0 then
                local Name = (Data.name ~= nil and Data.name ~= "") and Data.name or "Unknown"
                Results[#Results + 1] = { Id = Data.id, Name = Name }
            end
        end
    end
    return Results
end

local function LootContains(Id)
    for _, Entry in ipairs(State.Loot) do
        if Entry.Id == Id then return true end
    end
    return false
end

local function AddLoot(Input)
    if Input == nil or Input == "" then
        Slib:Warn("[Loot] No item id or name entered")
        return
    end

    local Matches = ResolveItems(Input)
    if #Matches == 0 then
        Slib:Warn("[Loot] No item found for '" .. tostring(Input) .. "'")
        return
    end

    local Added = 0
    for _, Entry in ipairs(Matches) do
        if not LootContains(Entry.Id) then
            State.Loot[#State.Loot + 1] = { Id = Entry.Id, Name = Entry.Name }
            Added = Added + 1
            Slib:Info("[Loot] Added " .. Entry.Id .. " (" .. Entry.Name .. ")")
        end
    end

    if Added == 0 then
        Slib:Warn("[Loot] All " .. #Matches .. " match(es) for '" .. tostring(Input) .. "' were already in the list")
    else
        Slib:Info("[Loot] Added " .. Added .. " of " .. #Matches .. " match(es) for '" .. tostring(Input) .. "'")
    end
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
            RemoveAt(Action.Index)
        elseif Kind == "up" then
            MoveUp(Action.Index)
        elseif Kind == "down" then
            MoveDown(Action.Index)
        elseif Kind == "clear" then
            ClearPriority()
        elseif Kind == "lootadd" then
            AddLoot(Action.Index)
        elseif Kind == "lootremove" then
            RemoveLootAt(Action.Index)
        elseif Kind == "lootclear" then
            ClearLoot()
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
-- Walk the priority list top to bottom and attack the nearest live NPC that
-- matches the highest-priority name within scan range.
local function AttackByPriority()
    if #State.Priority == 0 then
        return false
    end

    -- Only proceed when idle or the current target is dead/dying; if we are
    -- mid-fight (a live target) IsReadyToAttack returns false and we skip.
    if not IsReadyToAttack() then
        return false
    end

    local Candidates = ScanNearbyNpcs()

    for _, WantedName in ipairs(State.Priority) do
        for _, Mob in ipairs(Candidates) do
            -- Skip the NPC we just attacked: its Life can still read > 0 during
            -- the death animation, so exclude it by unique id (Unique_Id) to
            -- avoid re-clicking the same corpse.
            if Mob.Name == WantedName
                and Mob.Distance <= Config.AttackRange
                and Mob.Unique_Id ~= State.LastAttackedId then
                Slib:Info(string.format("[Combat] Attacking %s (Id=%s, uid=%s, dist=%.1f)",
                    Mob.Name, tostring(Mob.Id), tostring(Mob.Unique_Id), Mob.Distance))
                local TargetTile = WPOINT.new(math.floor(Mob.Tile_XYZ.x), math.floor(Mob.Tile_XYZ.y), Mob.Floor)
                local Ok = Interact:NPC(WantedName, "Attack", TargetTile, Config.AttackRange)
                if Ok then
                    State.LastTarget = WantedName
                    State.LastAttackedId = Mob.Unique_Id
                    Slib:RandomSleep(Config.AttackMinSleep, Config.AttackMaxSleep, "ms")
                    API.WaitUntilMovingEnds()
                    return true
                end
                Slib:Warn("[Combat] Attack call failed for " .. WantedName)
            end
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

-- Heal HP with the first usable Excalibur variant, respecting its cooldown.
local function HealWithExcalibur()
    if not State.Sustain.Excalibur then return end
    if API.GetHPrecent() > Config.HealHpThreshold then return end
    if os.clock() - State.ExcaliburLastUsed < Config.ExcaliburCooldown then return end

    for _, Id in ipairs(ExcaliburIds) do
        if Slib:CanCastAbility(Id) then
            Slib:UseAbilityById(Id)
            State.ExcaliburLastUsed = os.clock()
            Slib:Info("[Sustain] Used Excalibur (" .. Id .. ")")
            return
        end
    end
    Slib:Warn("[Sustain] No usable Excalibur on the ability bars")
end

-- Heal HP by eating food when one is in the inventory.
local function EatFood()
    if not State.Sustain.EatFood then return end
    if API.GetHPrecent() > Config.EatHpThreshold then return end

    if Inventory:HasFood() then
        Slib:UseAbilityById(EatFoodAbilityId)
        Slib:Info("[Sustain] Ate food")
    end
end

-- Restore prayer with an Elven Shard (skips if its buff is still active).
local function RestorePrayer()
    if not State.Sustain.ElvenShard then return end
    if API.GetPrayPrecent() > Config.PrayerThreshold then return end

    if Inventory:Contains(ElvenShardId) and not Slib:HasBuff(ElvenShardId) then
        API.DoAction_Inventory1(ElvenShardId, 0, 1, API.OFF_ACT_GeneralInterface_route)
        Slib:Info("[Sustain] Used Elven Shard")
    end
end

-- Run all enabled sustain checks. Each is a no-op when its toggle is off.
local function Sustain()
    HealWithExcalibur()
    EatFood()
    RestorePrayer()
end
-- #endregion

-- #region GUI (render thread) ----------------------------------------------
-- Small helpers to keep the draw code tidy.
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

local function PopWindowStyle()
    ImGui.PopStyleVar(4)
    ImGui.PopStyleColor(16)
end

-- Status header line.
local function DrawStatus()
    if State.Running then
        ColoredText(Theme.Good, "Running")
    else
        ColoredText(Theme.Bad, "Paused")
    end
    ImGui.SameLine(0, 12)
    ColoredText(Theme.Muted, "Runtime " .. FormatRuntime())
    ImGui.SameLine(0, 12)
    ColoredText(Theme.Muted, "Last: " .. State.LastTarget)
end

-- Refresh + combo + Add controls.
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
        ImGui.SetTooltip("Add selected NPC to the priority list")
    end
end

-- The reorderable priority list.
local function DrawPriorityList()
    ImGui.SeparatorText("Kill Priority (top = first)")

    if #State.Priority == 0 then
        ColoredText(Theme.Muted, "Empty. Refresh, pick an NPC, then Add.")
    else
        for Index, Name in ipairs(State.Priority) do
            ImGui.PushID(Index)
            ColoredText(Theme.AccentHi, string.format("%d.", Index))
            ImGui.SameLine(0, 6)
            ImGui.Text(Name)

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

-- Loot id/name input + Add control.
local function DrawLootControls()
    ImGui.SeparatorText("Add Loot Item")

    ImGui.PushItemWidth(150)
    local Changed, NewText = ImGui.InputTextWithHint("##lootinput", "Item id or name", State.LootInput)
    if Changed then
        State.LootInput = NewText
    end
    ImGui.PopItemWidth()

    ImGui.SameLine(0, 8)
    if ImGui.Button("Add##lootadd", 60, 26) then
        QueueAction("lootadd", State.LootInput)
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Add an item to the loot list by id or name")
    end
end

-- The loot list showing id and resolved name.
local function DrawLootList()
    ImGui.SeparatorText("Loot Items")

    if #State.Loot == 0 then
        ColoredText(Theme.Muted, "Empty. Enter an item id or name, then Add.")
    else
        for Index, Entry in ipairs(State.Loot) do
            ImGui.PushID(1000 + Index)
            ColoredText(Theme.AccentHi, tostring(Entry.Id))
            ImGui.SameLine(0, 8)
            ImGui.Text(Entry.Name)

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

-- Sustain toggles.
local function DrawOptions()
    ImGui.SeparatorText("Health")

    local ExcalChanged, ExcalValue = ImGui.Checkbox("Excalibur", State.Sustain.Excalibur)
    if ExcalChanged then
        State.Sustain.Excalibur = ExcalValue
        QueueAction("savesettings")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Heal with Excalibur when HP <= " .. Config.HealHpThreshold .. "%")
    end

    local FoodChanged, FoodValue = ImGui.Checkbox("Eat Food", State.Sustain.EatFood)
    if FoodChanged then
        State.Sustain.EatFood = FoodValue
        QueueAction("savesettings")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Eat food when HP <= " .. Config.EatHpThreshold .. "%")
    end

    ImGui.SeparatorText("Prayer")

    local ShardChanged, ShardValue = ImGui.Checkbox("Elven Shard", State.Sustain.ElvenShard)
    if ShardChanged then
        State.Sustain.ElvenShard = ShardValue
        QueueAction("savesettings")
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Restore prayer with an Elven Shard when prayer <= " .. Config.PrayerThreshold .. "%")
    end
end

-- Start/Pause + Stop.
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
    local Visible = ImGui.Begin(ScriptName .. " v" .. ScriptVersion .. " by " .. Author .. "###SpectreBasicCombat", true)
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
end
-- #endregion

-- #region Main loop --------------------------------------------------------
-- Load saved config before the render callback starts reading State.
LoadConfig()

-- Clear any render callbacks left registered by a previous run of this script,
-- otherwise the window draws twice (the ME client keeps callbacks across runs).
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
Slib:Info("[Script] " .. ScriptName .. " v" .. ScriptVersion .. " started")

while API.Read_LoopyLoop() do
    ProcessActions()
    API.DoRandomEvents()

    if State.Running then
        -- Sustain runs every tick (including mid-combat) so heals are not delayed.
        Sustain()

        -- Attack first; only loot when not attacking and ready (idle or the
        -- target is dead) so we never interrupt a fight by walking off to loot.
        local Attacked = AttackByPriority()
        if not Attacked and IsReadyToAttack() then
            LootGround()
        end
    end

    Slib:RandomSleep(Config.LoopMinSleep, Config.LoopMaxSleep, "ms")
end
-- #endregion
