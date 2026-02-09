local ScriptName = "VB Scanner"
local Author = "Spectre011"
local ScriptVersion = "1.0.0"
local ReleaseDate = "08-02-2026"
local DiscordHandle = "not_spectre011"

--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                              VB SCANNER SCRIPT                               ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Description: Real-time Varbit and Varp scanning, monitoring, and analysis   ║
║               tool with live GUI filtering and change detection.             ║
║                                                                              ║
║  Features:    • Full initial scan of all Varbits and Varps                   ║
║               • Non-destructive, real-time filtering (no apply button)       ║
║               • Change diff visualization and removal operations             ║
║               • Responsive ImGui-based interface with deferred execution     ║
║                                                                              ║
║  Usage:       Run the script, allow the initial scan to complete, then use   ║
║               the GUI to monitor, filter, update, and prune Varbit/Varp      ║
║               entries as values change in real time.                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

--[[
Changelog:
v1.0.0 - 08-02-2026
    - Initial release.
]]


local API = require("api")
local Slib = require("slib")

ClearRender()

local VARBIT_MAX = 60000
local VARP_MAX = 12000

-- ==========================================
-- STATE & CONFIGURATION
-- ==========================================
local state = {
    varbits = {}, -- Master list of varbits (NEVER modified by filters)
    varps = {},   -- Master list of varps (NEVER modified by filters)
    
    -- Scanning/Process States
    isInitialScanning = false,
    
    -- Filter Inputs (live filtering - no "apply" button needed)
    searchId = "",
    searchValue = "",
    searchFrom = "",
    searchTo = "",
    filterMode = 0, -- 0 = Show All, 1 = Show Changed, 2 = Show Unchanged
    
    -- GUI State
    statusText = "Initializing GUI...",
    statusColor = {1, 1, 1, 1},
    
    -- Window State
    windowInitialized = false,
    
    -- Deferred Actions
    pendingAction = nil,
    executionTime = 0
}

-- Colors (Solarized Dark / Gold Theme)
local colors = {
    text = {0.9, 0.9, 0.9, 1.0},
    textGreen = {0.2, 1.0, 0.2, 1.0},
    textRed = {1.0, 0.3, 0.3, 1.0},
    textGold = {1.0, 0.85, 0.0, 1.0},
    header = {0.15, 0.15, 0.15, 1.0},
}

-- ==========================================
-- LOGIC FUNCTIONS
-- ==========================================

-- Helper to create a new entry
local function createEntry(id, val)
    return {
        id = id,
        val = val,
        prev = val,
        changed = false,
        lastUpdate = 0
    }
end

-- 1. INITIAL SCAN (ALL AT ONCE)
local function performInitialScan()
    state.isInitialScanning = true
    
    -- Scan all Varbits
    for i = 0, VARBIT_MAX do
        local val = API.GetVarbitValue(i)
        state.varbits[i] = createEntry(i, val)
    end
    
    -- Scan all Varps
    for i = 0, VARP_MAX do
        local vb = API.VB_FindPSettinOrder(i)
        if vb then
            state.varps[i] = createEntry(i, vb.state)
        end
    end
    
    state.isInitialScanning = false
    state.statusText = "Scan Complete. Ready."
    state.statusColor = colors.textGreen
    print(string.format("Initial Scan Complete - %d varbits and %d varps scanned", VARBIT_MAX + 1, VARP_MAX + 1))
end

-- 2. UPDATE VALUES
local function updateValues()
    local count = 0
    
    -- Update Varbits
    for id, entry in pairs(state.varbits) do
        local newVal = API.GetVarbitValue(id)
        if newVal ~= entry.val then
            entry.prev = entry.val
            entry.val = newVal
            entry.changed = true
            entry.lastUpdate = os.clock()
            count = count + 1
        else
            entry.changed = false
        end
    end
    
    -- Update Varps
    for id, entry in pairs(state.varps) do
        local vb = API.VB_FindPSettinOrder(id)
        if vb then
            local newVal = vb.state
            if newVal ~= entry.val then
                entry.prev = entry.val
                entry.val = newVal
                entry.changed = true
                entry.lastUpdate = os.clock()
                count = count + 1
            else
                entry.changed = false
            end
        end
    end
    
    state.statusText = string.format("Update complete. %d changes found.", count)
    state.statusColor = count > 0 and colors.textGreen or colors.text
    print(string.format("Update complete: %d changes found", count))
    return count
end

-- ==========================================
-- IMPROVED FILTER LOGIC
-- ==========================================

-- Parse comma-separated values into a table
local function parseCSV(str, keepAsStrings)
    if str == "" then return {} end
    
    local values = {}
    for value in string.gmatch(str, "[^,]+") do
        local trimmed = value:match("^%s*(.-)%s*$")
        if keepAsStrings then
            -- Always keep as string for partial matching
            table.insert(values, trimmed)
        else
            local num = tonumber(trimmed)
            if num then
                table.insert(values, num)
            else
                table.insert(values, trimmed)
            end
        end
    end
    return values
end

-- Check if a value matches any in the filter list
local function matchesFilter(value, filterList, allowPartialMatch)
    if #filterList == 0 then return true end
    
    for _, filter in ipairs(filterList) do
        if allowPartialMatch then
            -- Partial string match (for IDs)
            if string.find(tostring(value), tostring(filter), 1, true) then 
                return true 
            end
        else
            -- Exact match (for values) - handle type conversion
            local numFilter = tonumber(filter)
            local numValue = tonumber(value)
            
            if numFilter and numValue then
                -- Both can be numbers - compare numerically
                if numValue == numFilter then return true end
            else
                -- String comparison fallback
                if tostring(value) == tostring(filter) then return true end
            end
        end
    end
    return false
end

-- UNIFIED FILTER FUNCTION
-- This is called at display time only - never modifies source data
local function passesFilters(entry)
    -- Filter 1: Filter Mode (Show All / Changed / Unchanged)
    if state.filterMode == 1 and not entry.changed then
        return false -- Show Changed Only
    elseif state.filterMode == 2 and entry.changed then
        return false -- Show Unchanged Only
    end
    -- filterMode == 0 shows all, so no filtering needed
    
    -- Filter 2: ID Filter (supports partial string matching)
    if state.searchId ~= "" then
        local idFilters = parseCSV(state.searchId, true) -- Keep as strings for partial match
        if not matchesFilter(entry.id, idFilters, true) then -- Allow partial match
            return false
        end
    end
    
    -- Filter 3: Current Value Filter (exact match)
    if state.searchValue ~= "" then
        local valueFilters = parseCSV(state.searchValue, false) -- Parse numbers
        if not matchesFilter(entry.val, valueFilters, false) then -- Exact match only
            return false
        end
    end
    
    -- Filter 4 & 5: Change Filters (From/To) - exact match
    if state.searchFrom ~= "" or state.searchTo ~= "" then
        -- Only apply to items that have changed at least once
        if entry.lastUpdate == 0 then
            return false
        end
        
        if state.searchFrom ~= "" then
            local fromFilters = parseCSV(state.searchFrom, false)
            if not matchesFilter(entry.prev, fromFilters, false) then
                return false
            end
        end
        
        if state.searchTo ~= "" then
            local toFilters = parseCSV(state.searchTo, false)
            if not matchesFilter(entry.val, toFilters, false) then
                return false
            end
        end
    end
    
    return true
end

-- Get filtered list for display (non-destructive)
local function getFilteredList(sourceTable)
    local result = {}
    local filtered = 0
    
    for id, entry in pairs(sourceTable) do
        if passesFilters(entry) then
            table.insert(result, entry)
        else
            filtered = filtered + 1
        end
    end
    
    -- Sort by ID
    table.sort(result, function(a, b) return a.id < b.id end)
    return result, filtered
end

-- 4. REMOVAL LOGIC (permanent operations on master data)
local function removeChangedItems()
    local removed = 0
    for id, entry in pairs(state.varbits) do
        if entry.changed then 
            state.varbits[id] = nil
            removed = removed + 1
        end
    end
    for id, entry in pairs(state.varps) do
        if entry.changed then 
            state.varps[id] = nil
            removed = removed + 1
        end
    end
    
    state.statusText = string.format("Removed %d changed items.", removed)
    state.statusColor = colors.textGreen
    print(string.format("Removed %d changed items", removed))
end

-- Remove unchanged items (destructive)
local function removeUnchangedItems()
    local removed = 0
    for id, entry in pairs(state.varbits) do
        if not entry.changed then 
            state.varbits[id] = nil
            removed = removed + 1
        end
    end
    for id, entry in pairs(state.varps) do
        if not entry.changed then 
            state.varps[id] = nil
            removed = removed + 1
        end
    end
    
    state.statusText = string.format("Removed %d unchanged items.", removed)
    state.statusColor = colors.textGreen
    print(string.format("Removed %d unchanged items", removed))
end

-- ==========================================
-- GUI DRAWING
-- ==========================================

local function DrawHeader()
    ImGui.TextColored(colors.textGold[1], colors.textGold[2], colors.textGold[3], 1.0, "SPECTRE'S VB SCANNER")
    ImGui.SameLine()
    ImGui.TextColored(state.statusColor[1], state.statusColor[2], state.statusColor[3], 1.0, "| " .. state.statusText)
end

local function DrawControls()
    if state.isInitialScanning then
        ImGui.Text("Scanning in progress... Please wait.")
        return
    end

    -- Top Row: Actions
    if ImGui.Button("Scan All (Reset)", 120, 25) then
        state.statusText = "Scanning all varbits and varps..."
        state.statusColor = colors.textGold
        state.pendingAction = "scan"
    end
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Reset and scan all varbits/varps from scratch") 
    end
    
    ImGui.SameLine()
    -- Modified Update Button
    if ImGui.Button("Update Values", 120, 25) then
        state.statusText = "Updating values..." -- Set text immediately
        state.statusColor = colors.textGold
        
        state.pendingAction = "update"
        -- schedule execution for 0.1 seconds (100ms) later
        -- This allows the UI to render the text BEFORE the freeze happens
        state.executionTime = os.clock() + 0.1 
    end
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Refresh current values and detect changes") 
    end

    ImGui.SameLine()
    if ImGui.Button("Remove Changed", 120, 25) then
        state.statusText = "Removing changed items..."
        state.statusColor = colors.textGold
        state.pendingAction = "remove_changed"
    end
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Permanently remove items marked as 'Changed'") 
    end
    
    ImGui.SameLine()
    if ImGui.Button("Remove Unchanged", 130, 25) then
        state.statusText = "Removing unchanged items..."
        state.statusColor = colors.textGold
        state.pendingAction = "remove_unchanged"
    end
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Permanently remove items that have NOT changed") 
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Filters Section with 2-Column Layout
    ImGui.TextColored(colors.textGold[1], colors.textGold[2], colors.textGold[3], 1.0, "Filters (Live - no apply button needed):")
    ImGui.Spacing()
    
    -- Filter Mode Dropdown
    ImGui.Text("Display Mode:")
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Choose what to display:\nShow All - displays everything\nShow Changed Only - only items that changed\nShow Unchanged Only - only items that haven't changed") 
    end
    ImGui.SameLine()
    ImGui.PushItemWidth(200)
    
    -- DEFINE OPTIONS AS A TABLE
    local options = {"Show All", "Show Changed Only", "Show Unchanged Only"}
    
    -- PASS THE TABLE TO COMBO
    local filterModeChanged, newFilterMode = ImGui.Combo("##filterMode", state.filterMode, options)
    
    if filterModeChanged then
        state.filterMode = newFilterMode
    end
    ImGui.PopItemWidth()
    
    ImGui.Spacing()
    
    -- Create 2 columns for filters
    ImGui.Columns(2, "FilterColumns", false)
    
    -- LEFT COLUMN
    -- Filter 1: ID Contains
    ImGui.Text("ID Contains:")
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Filter by ID (partial match)\nExample: '12' matches 12, 123, 1234, 5120, etc.\nMultiple: '12,34,56' matches any ID containing 12, 34, or 56\nSupports comma-separated values") 
    end
    ImGui.SameLine()
    ImGui.PushItemWidth(150)
    local changed1, val1 = ImGui.InputText("##searchId", state.searchId, 100)
    if changed1 then state.searchId = val1 end
    ImGui.PopItemWidth()
    
    -- Filter 2: Current Value
    ImGui.Text("Current Value =:")
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Filter by current value\nExample: '5,10,15' shows items with value 5, 10, or 15\nSupports multiple comma-separated values") 
    end
    ImGui.SameLine()
    ImGui.PushItemWidth(150)
    local changed2, val2 = ImGui.InputText("##searchValue", state.searchValue, 100)
    if changed2 then state.searchValue = val2 end
    ImGui.PopItemWidth()
    
    -- Move to RIGHT COLUMN
    ImGui.NextColumn()
    
    -- Filter 3: Changed From
    ImGui.Text("Changed From:")
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Filter by previous value\nExample: '0,5' shows items that changed FROM 0 or 5\nSupports multiple comma-separated values") 
    end
    ImGui.SameLine()
    ImGui.PushItemWidth(150)
    local changed3, val3 = ImGui.InputText("##searchFrom", state.searchFrom, 100)
    if changed3 then state.searchFrom = val3 end
    ImGui.PopItemWidth()
    
    -- Filter 4: Changed To
    ImGui.Text("Changed To:")
    if ImGui.IsItemHovered() then 
        ImGui.SetTooltip("Filter by new value\nExample: '1,10' shows items that changed TO 1 or 10\nSupports multiple comma-separated values") 
    end
    ImGui.SameLine()
    ImGui.PushItemWidth(150)
    local changed4, val4 = ImGui.InputText("##searchTo", state.searchTo, 100)
    if changed4 then state.searchTo = val4 end
    ImGui.PopItemWidth()
    
    -- Reset columns
    ImGui.Columns(1)
end

local function DrawList(title, dataList, filteredCount, childId)
    -- Calculate counts
    local visibleCount = #dataList
    
    local countText = filteredCount > 0 
        and string.format("%s (Showing: %d, Filtered: %d)", title, visibleCount, filteredCount)
        or string.format("%s (Total: %d)", title, visibleCount)
    
    ImGui.TextColored(colors.textGold[1], colors.textGold[2], colors.textGold[3], 1.0, countText)
    
    -- Use Child to handle scrolling independently
    if ImGui.BeginChild(childId, 0, 0, true) then
        -- Define columns explicitly
        ImGui.Columns(4, childId .. "_cols", true)
        
        -- Set fixed widths
        ImGui.SetColumnWidth(0, 80)  -- ID
        ImGui.SetColumnWidth(1, 100) -- Val
        ImGui.SetColumnWidth(2, 100) -- Prev
        
        -- Headers
        ImGui.Text("ID"); ImGui.NextColumn()
        ImGui.Text("Value"); ImGui.NextColumn()
        ImGui.Text("Previous"); ImGui.NextColumn()
        ImGui.Text("Diff"); ImGui.NextColumn()
        ImGui.Separator()

        -- Render Items
        for _, entry in ipairs(dataList) do
            -- Colorize changed rows
            if entry.changed then
                ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.5, 0.0, 1.0)
            end

            ImGui.Text(tostring(entry.id)); ImGui.NextColumn()
            ImGui.Text(tostring(entry.val)); ImGui.NextColumn()
            ImGui.Text(tostring(entry.prev)); ImGui.NextColumn()
            
            if entry.changed then
                local diff = entry.val - entry.prev
                ImGui.Text(string.format("%+d", diff))
            else
                ImGui.Text("-")
            end
            ImGui.NextColumn()

            if entry.changed then
                ImGui.PopStyleColor()
            end
        end
        
        ImGui.Columns(1) -- Reset columns
    end
    ImGui.EndChild()
end

local function Draw()
    -- Initialize window size on first draw
    if not state.windowInitialized then
        ImGui.SetNextWindowSize(900, 600, ImGuiCond.FirstUseEver)
        ImGui.SetNextWindowPos(100, 100, ImGuiCond.FirstUseEver)
        state.windowInitialized = true
    end
    
    -- Safe Theme Pushing
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.1, 0.1, 0.1, 1.0)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.1, 0.1, 0.1, 1.0)
    
    local open = ImGui.Begin("Spectre's VB Scanner", true)
    
    if open then
        DrawHeader()
        ImGui.Separator()
        DrawControls()
        ImGui.Separator()
        
        -- Main Data Area (Split 50/50)
        ImGui.Columns(2, "MainSplit", true)
        
        local filteredVarbits, vbFiltered = getFilteredList(state.varbits)
        DrawList("VARBITS", filteredVarbits, vbFiltered, "vblist")
        
        ImGui.NextColumn()
        
        local filteredVarps, vpFiltered = getFilteredList(state.varps)
        DrawList("VARPS", filteredVarps, vpFiltered, "vplist")
        
        ImGui.Columns(1) -- Reset Main Split
    end
    
    ImGui.End()
    ImGui.PopStyleColor(2)
end

-- ==========================================
-- MAIN EXECUTION
-- ==========================================

DrawImGui(Draw)

-- Schedule initial scan
state.statusText = "Scanning all varbits and varps..."
state.statusColor = colors.textGold
state.pendingAction = "scan"
state.executionTime = os.clock() + 0.1 -- Small delay for initial scan too

while API.Read_LoopyLoop() do
    
    -- CHECK 1: Is there an action pending?
    -- CHECK 2: Has enough time passed (0.1s) for the UI to redraw?
    if state.pendingAction and os.clock() > state.executionTime then
        
        if state.pendingAction == "scan" then
            state.varbits = {}
            state.varps = {}
            performInitialScan()
            
        elseif state.pendingAction == "update" then
            updateValues()
            
        elseif state.pendingAction == "remove_changed" then
            removeChangedItems()
            
        elseif state.pendingAction == "remove_unchanged" then
            removeUnchangedItems()
        end
        
        -- Reset action after finishing
        state.pendingAction = nil
    end
    
    Slib:RandomSleep(10, 20, "ms")
end
ClearRender()