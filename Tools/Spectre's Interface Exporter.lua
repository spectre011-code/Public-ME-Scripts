local ScriptName = "Interface Exporter"
local Author = "Spectre011"
local ScriptVersion = "2.0.0"
local ReleaseDate = "10-01-2026"
local DiscordHandle = "not_spectre011"

--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                          INTERFACE EXPORTER SCRIPT                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Description: Recursively scans game interfaces and exports IInfo fields    ║
║  Usage:       Configure parameters in the Config table below and execute     ║
║  Output:      CSV file with IInfo interface data                             ║
║                                                                              ║
║  Credits:     Based on the excellent work of Ernie                           ║
║               GitHub: https://github.com/Ernestohh/                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

--[[
Changelog:
v1.0.0 - 15-06-2025
    - Initial release.

v1.1.0 - 21-06-2025
    - Added two new columns to CSV export:
      * memloc+I_itemids3_Char: Result of API.ReadCharsLimit(interface.memloc + API.I_itemids3, 255)
      * memloc+I_slides_Int: Result of API.Mem_Read_int(interface.memloc + API.I_slides)

v1.2.0 - 21-06-2025
    - Enhanced memory read functionality:
      * Added comprehensive memory read columns for all API memory functions
      * Includes Mem_Read_char, Mem_Read_short, Mem_Read_int, Mem_Read_uint64, and ReadCharsLimit
      * Combined with all API constants (I_00textP, I_itemids3, I_itemids, I_itemstack, I_slides, I_buffb)
      * Removed redundant specific memory read columns (now included in comprehensive reads)

v1.3.0 - 28-08-2025
    - Added parentInterfaceID column to CSV export
    - Added proper interfaceID column to CSV export

v2.0.0 - 10-01-2026
    - Refactored the script to be more efficient and readable
    - Now correctly explores all child combinations recursively
    - Includes memloc + API constant combinations
    - Increased max depth to 100000
]]

local API = require("api")

-- Configuration
local Config = {
    StartingInterface = { {1473,0,-1,0}, {1473,7,-1,0}, {1473,10,-1,0}, {1473,10,5120,0} },
    OutputDirectory = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\exports\\interfaces\\",
    OutputFileName = "interfaces_export.csv"
}

-- Opens the specified directory in Windows Explorer
---@param Path string The directory path to open (backslashes will be normalized)
local function OpenDirectory(Path)
    Path = Path:gsub("\\+$", "")
    os.execute('start "" "' .. Path .. '"')
end

-- Creates directory structure and validates write permissions
---@param DirPath string The directory path to create and validate
---@return boolean Success True if directory exists and is writable, false otherwise
local function EnsureDirectoryExists(DirPath)
    local Success = os.execute('mkdir "' .. DirPath .. '" 2>nul')
    
    local TestFile = io.open(DirPath .. "test_write.tmp", "w")
    if TestFile then
        TestFile:close()
        os.remove(DirPath .. "test_write.tmp")
        return true
    else
        print("[" .. ScriptName .. "] Error: Could not access directory: " .. DirPath)
        return false
    end
end

-- Initialize output directory with fallback handling
if not EnsureDirectoryExists(Config.OutputDirectory) then
    print("[" .. ScriptName .. "] Fallback: Using current directory instead of configured path.")
    Config.OutputDirectory = ".\\"
end

-- Generates unique filename by appending incremental counter to prevent overwrites
---@param BaseFilename string The base filename to make unique
---@return string UniqueFilename A filename guaranteed not to exist
local function GetUniqueFilename(BaseFilename)
    local FullPath = Config.OutputDirectory .. BaseFilename
    
    local File = io.open(FullPath, "r")
    if not File then
        return FullPath
    end
    File:close()
    
    local Name, Ext = BaseFilename:match("^(.+)%.([^%.]+)$")
    if not Name then
        Name = BaseFilename
        Ext = ""
    end
    
    local Counter = 1
    local NewFilename
    repeat
        if Ext and Ext ~= "" then
            NewFilename = Config.OutputDirectory .. Name .. "_" .. Counter .. "." .. Ext
        else
            NewFilename = Config.OutputDirectory .. Name .. "_" .. Counter
        end
        
        local TestFile = io.open(NewFilename, "r")
        if TestFile then
            TestFile:close()
            Counter = Counter + 1
        else
            break
        end
    until false
    
    print("[" .. ScriptName .. "] File exists, using numbered variant: " .. NewFilename)
    return NewFilename
end

-- Escapes special characters in data values for CSV compatibility
---@param Value any The value to escape and format for CSV
---@return string EscapedValue The properly escaped CSV value
local function EscapeCSV(Value)
    if not Value then
        return ""
    end
    
    local Str = tostring(Value)
    if string.find(Str, '[,"\n\r]') then
        Str = string.gsub(Str, '"', '""')
        Str = '"' .. Str .. '"'
    end
    return Str
end

-- Escapes column names for CSV headers with guaranteed quoting
---@param Name string The column name to escape
---@return string EscapedName The properly escaped CSV column name
local function EscapeColumnName(Name)
    if not Name then
        return ""
    end
    
    local Str = tostring(Name)
    Str = string.gsub(Str, '"', '""')
    Str = '"' .. Str .. '"'
    return Str
end

-- Converts boolean values to consistent string representation
---@param Value any The value to convert (handles boolean and other types)
---@return string StringValue The string representation ("true", "false", or converted value)
local function BoolToString(Value)
    if type(Value) == "boolean" then
        return Value and "true" or "false"
    end
    return tostring(Value or "")
end

-- Creates a unique string identifier from interface path for duplicate detection
---@param Path table Array of interface path segments
---@return string UniqueKey A string key representing the path hierarchy
local function PathToKey(Path)
    local Parts = {}
    for I, Segment in ipairs(Path) do
        table.insert(Parts, Segment[1] .. "," .. Segment[2] .. "," .. Segment[3] .. "," .. Segment[4])
    end
    return table.concat(Parts, ";")
end

-- Creates child interface path by appending new segment to existing path
---@param CurrentPath table The current interface path hierarchy
---@param Id1 number The id1 value to append
---@param Id2 number The id2 value to append
---@param Id3 number The id3 value to append
---@return table ChildPath The extended path hierarchy for child interfaces
local function CreateChildPath(CurrentPath, Id1, Id2, Id3)
    local ChildPath = {}
    for I = 1, #CurrentPath do
        local PathSegment = {}
        for K, V in ipairs(CurrentPath[I]) do
            PathSegment[K] = V
        end
        table.insert(ChildPath, PathSegment)
    end
    
    table.insert(ChildPath, { Id1, Id2, Id3, 0 })
    
    return ChildPath
end

-- Performs memory reads with all API functions and constants
---@param Memloc number The base memory location
---@return table MemoryReads Table of all memory read results
local function PerformMemoryReads(Memloc)
    local MemoryReads = {}
    
    if not Memloc then
        return MemoryReads
    end
    
    -- Define API constants
    local ApiConstants = {
        {name = "I_00textP", value = API.I_00textP},
        {name = "I_itemids3", value = API.I_itemids3},
        {name = "I_itemids", value = API.I_itemids},
        {name = "I_itemstack", value = API.I_itemstack},
        {name = "I_slides", value = API.I_slides},
        {name = "I_buffb", value = API.I_buffb}
    }
    
    -- Define memory read functions
    local MemReadFunctions = {
        {name = "Mem_Read_char", func = API.Mem_Read_char, format = function(v) 
            if type(v) ~= "number" then return tostring(v) end
            if v ~= v or v == math.huge or v == -math.huge then return "Invalid" end
            local safe = math.floor(v + 0.5) % 256
            return string.format("0x%02X (%d)", safe, v) 
        end},
        {name = "Mem_Read_short", func = API.Mem_Read_short, format = function(v) 
            if type(v) ~= "number" then return tostring(v) end
            if v ~= v or v == math.huge or v == -math.huge then return "Invalid" end
            local safe = math.floor(v + 0.5) % 65536
            return string.format("0x%04X (%d)", safe, v) 
        end},
        {name = "Mem_Read_int", func = API.Mem_Read_int, format = function(v) 
            if type(v) ~= "number" then return tostring(v) end
            if v ~= v or v == math.huge or v == -math.huge then return "Invalid" end
            local safe = math.floor(v + 0.5)
            return string.format("0x%08X (%d)", safe, v) 
        end},
        {name = "Mem_Read_uint64", func = API.Mem_Read_uint64, format = function(v) 
            if type(v) ~= "number" then return tostring(v) end
            if v ~= v or v == math.huge or v == -math.huge then return "Invalid" end
            if v > 9223372036854775807 then return "Overflow" end
            local safe = math.floor(v + 0.5)
            return string.format("0x%016X (%d)", safe, v) 
        end}
    }
    
    local StringReadFunctions = {
        {name = "ReadChars", func = function(addr) return API.ReadChars(addr, 250) end},
        {name = "ReadCharsLimitPointer", func = function(addr) return API.ReadCharsLimitPointer(addr, 250) end},
        {name = "ReadCharsLimit", func = function(addr) return API.ReadCharsLimit(addr, 250) end},
        {name = "ReadCharsPointer", func = API.ReadCharsPointer}
    }
    
    -- Perform reads with base memloc
    for _, ReadFunc in ipairs(MemReadFunctions) do
        local FuncName = ReadFunc.name .. "(memloc)"
        local Success, Result = pcall(ReadFunc.func, Memloc)
        if Success and Result ~= nil then
            MemoryReads[FuncName] = ReadFunc.format(Result)
        else
            MemoryReads[FuncName] = "Error"
        end
    end
    
    for _, ReadFunc in ipairs(StringReadFunctions) do
        local FuncName = ReadFunc.name .. "(memloc, 250)"
        local Success, Result = pcall(ReadFunc.func, Memloc)
        if Success and Result ~= nil then
            if type(Result) == "string" then
                if Result == "" then
                    MemoryReads[FuncName] = '""'
                else
                    local Escaped = string.gsub(Result, "[\0-\31\127-\255]", function(c)
                        return string.format("\\x%02X", string.byte(c))
                    end)
                    if #Escaped > 50 then
                        Escaped = string.sub(Escaped, 1, 47) .. "..."
                    end
                    MemoryReads[FuncName] = '"' .. Escaped .. '"'
                end
            else
                MemoryReads[FuncName] = tostring(Result)
            end
        else
            MemoryReads[FuncName] = "Error"
        end
    end
    
    -- Perform reads with memloc + API constants
    for _, Constant in ipairs(ApiConstants) do
        if Constant.value and type(Constant.value) == "number" then
            local Addr = Memloc + Constant.value
            
            -- Numeric reads
            for _, ReadFunc in ipairs(MemReadFunctions) do
                local FuncName = ReadFunc.name .. "(memloc+" .. Constant.name .. ")"
                local Success, Result = pcall(ReadFunc.func, Addr)
                if Success and Result ~= nil then
                    MemoryReads[FuncName] = ReadFunc.format(Result)
                else
                    MemoryReads[FuncName] = "Error"
                end
            end
            
            -- String reads
            for _, ReadFunc in ipairs(StringReadFunctions) do
                local FuncName = ReadFunc.name .. "(memloc+" .. Constant.name .. ", 250)"
                local Success, Result = pcall(ReadFunc.func, Addr)
                if Success and Result ~= nil then
                    if type(Result) == "string" then
                        if Result == "" then
                            MemoryReads[FuncName] = '""'
                        else
                            local Escaped = string.gsub(Result, "[\0-\31\127-\255]", function(c)
                                return string.format("\\x%02X", string.byte(c))
                            end)
                            if #Escaped > 50 then
                                Escaped = string.sub(Escaped, 1, 47) .. "..."
                            end
                            MemoryReads[FuncName] = '"' .. Escaped .. '"'
                        end
                    else
                        MemoryReads[FuncName] = tostring(Result)
                    end
                else
                    MemoryReads[FuncName] = "Error"
                end
            end
        end
    end
    
    return MemoryReads
end

-- Recursively scans interface hierarchies and extracts IInfo data
---@param CurrentPath table Current interface path being scanned
---@param VisitedPaths table Tracking table to prevent infinite recursion
---@param AllInterfaces table Accumulator for all discovered interfaces
---@param Depth number Current recursion depth (for logging and limits)
---@param MaxDepth number Maximum recursion depth to prevent stack overflow
---@param SeenMemlocs table Memory location tracker for duplicate detection
---@return table AllInterfaces Complete collection of interface data
local function ScanAllInterfaces(CurrentPath, VisitedPaths, AllInterfaces, Depth, MaxDepth, SeenMemlocs)
    Depth = Depth or 0
    MaxDepth = MaxDepth or 100000
    VisitedPaths = VisitedPaths or {}
    AllInterfaces = AllInterfaces or {}
    SeenMemlocs = SeenMemlocs or {}
    
    if Depth > MaxDepth then
        return AllInterfaces
    end
    
    local PathKey = PathToKey(CurrentPath)
    if VisitedPaths[PathKey] then
        return AllInterfaces
    end
    VisitedPaths[PathKey] = true
    
    local PathString = ""
    for I, Segment in ipairs(CurrentPath) do
        if I > 1 then PathString = PathString .. " -> " end
        PathString = PathString .. table.concat(Segment, ",")
    end
    
    local InterfaceIDString = "{ "
    for I, Segment in ipairs(CurrentPath) do
        if I > 1 then InterfaceIDString = InterfaceIDString .. ", " end
        InterfaceIDString = InterfaceIDString .. "{" .. table.concat(Segment, ",") .. "}"
    end
    InterfaceIDString = InterfaceIDString .. " }"
    
    -- First, try to get the exact interface at this path
    local ExactSuccess, ExactInterface = pcall(function() 
        return API.ScanForInterfaceTest2Get(false, CurrentPath) 
    end)
    
    if ExactSuccess and ExactInterface and #ExactInterface > 0 then
        local Interface = ExactInterface[1]
        
        -- Check if we've already seen this interface
        if not (Interface.memloc and SeenMemlocs[Interface.memloc]) then
            if Interface.memloc then 
                SeenMemlocs[Interface.memloc] = true 
            end

            local ProperInterfaceID = InterfaceIDString
            
            -- Perform memory reads
            local MemoryReads = PerformMemoryReads(Interface.memloc)

            -- Create interface data with only IInfo base fields
            local InterfaceCopy = {
                _parentInterfaceID = InterfaceIDString,
                _interfaceID = ProperInterfaceID,
                _depth = Depth,
                _memoryReads = MemoryReads,
                index = Interface.index,
                x = Interface.x,
                xs = Interface.xs,
                y = Interface.y,
                ys = Interface.ys,
                box_x = Interface.box_x,
                box_y = Interface.box_y,
                scroll_y = Interface.scroll_y,
                id1 = Interface.id1,
                id2 = Interface.id2,
                id3 = Interface.id3,
                itemid1 = Interface.itemid1,
                itemid1_size = Interface.itemid1_size,
                itemid2 = Interface.itemid2,
                hov = Interface.hov,
                textids = Interface.textids,
                textitem = Interface.textitem,
                memloc = Interface.memloc,
                memloctop = Interface.memloctop,
                fullpath = Interface.fullpath,
                fullIDpath = Interface.fullIDpath,
                notvisible = Interface.notvisible,
                OP = Interface.OP,
                xy = Interface.xy
            }
            
            table.insert(AllInterfaces, InterfaceCopy)
        end
    end
    
    -- Now get all children of this path
    local ChildrenSuccess, Children = pcall(function() 
        return API.ScanForInterfaceTest2Get(true, CurrentPath) 
    end)
    
    if not ChildrenSuccess then
        return AllInterfaces
    end
    
    if not Children or #Children == 0 then
        return AllInterfaces
    end
    
    -- Track unique child combinations to explore
    local UniqueChildren = {}
    
    for _, Child in ipairs(Children) do
        -- Create a key for this child combination
        local ChildKey = (Child.id1 or 0) .. "," .. (Child.id2 or 0) .. "," .. (Child.id3 or 0)
        
        if not UniqueChildren[ChildKey] then
            UniqueChildren[ChildKey] = {
                id1 = Child.id1 or 0,
                id2 = Child.id2 or 0,
                id3 = Child.id3 or 0
            }
        end
    end
    
    -- Recursively explore each unique child path
    for _, ChildIds in pairs(UniqueChildren) do
        local ChildPath = CreateChildPath(CurrentPath, ChildIds.id1, ChildIds.id2, ChildIds.id3)
        local ChildPathKey = PathToKey(ChildPath)
        
        if not VisitedPaths[ChildPathKey] then
            ScanAllInterfaces(ChildPath, VisitedPaths, AllInterfaces, Depth + 1, MaxDepth, SeenMemlocs)
        end
    end
    
    collectgarbage("collect")
    
    return AllInterfaces
end

-- Main export function that orchestrates scanning and CSV generation
---@return boolean Success True if export completed successfully, false on error
local function ExportInterfacesToCSV()
    print("[" .. ScriptName .. "] Scanning interfaces...")
    
    local AllInterfaces = ScanAllInterfaces(Config.StartingInterface, {}, {}, 0, 100000, {})
    
    if not AllInterfaces or #AllInterfaces == 0 then
        print("[" .. ScriptName .. "] No interfaces found")
        return false
    end
    
    print("[" .. ScriptName .. "] Found " .. #AllInterfaces .. " interfaces")
    
    local FinalFilename = GetUniqueFilename(Config.OutputFileName)
    
    local File = io.open(FinalFilename, "w")
    if not File then
        print("[" .. ScriptName .. "] Error: Cannot create file")
        return false
    end
    
    -- CSV headers matching IInfo fields only
    local Headers = {
        "parentInterfaceID", "interfaceID", "depth", "index", "x", "xs", "y", "ys", "box_x", "box_y", "scroll_y",
        "id1", "id2", "id3", "itemid1", "itemid1_size", "itemid2",
        "hov", "textids", "textitem", "memloc", "memloctop",
        "fullpath", "fullIDpath", "notvisible", "OP", "xy"
    }
    
    -- Collect memory read headers from first interface
    local MemoryReadHeaders = {}
    if AllInterfaces and #AllInterfaces > 0 and AllInterfaces[1]._memoryReads then
        for FunctionName, _ in pairs(AllInterfaces[1]._memoryReads) do
            table.insert(MemoryReadHeaders, FunctionName)
        end
        table.sort(MemoryReadHeaders)
    end
    
    local EscapedHeaders = {}
    for _, Header in ipairs(Headers) do
        table.insert(EscapedHeaders, EscapeColumnName(Header))
    end
    for _, Header in ipairs(MemoryReadHeaders) do
        table.insert(EscapedHeaders, EscapeColumnName(Header))
    end
    
    File:write(table.concat(EscapedHeaders, ",") .. "\n")
    
    local ExportedCount = 0
    for I, Interface in ipairs(AllInterfaces) do
        local RowData = {
            EscapeCSV(Interface._parentInterfaceID),
            EscapeCSV(Interface._interfaceID),
            EscapeCSV(Interface._depth),
            EscapeCSV(Interface.index),
            EscapeCSV(Interface.x),
            EscapeCSV(Interface.xs),
            EscapeCSV(Interface.y),
            EscapeCSV(Interface.ys),
            EscapeCSV(Interface.box_x),
            EscapeCSV(Interface.box_y),
            EscapeCSV(Interface.scroll_y),
            EscapeCSV(Interface.id1),
            EscapeCSV(Interface.id2),
            EscapeCSV(Interface.id3),
            EscapeCSV(Interface.itemid1),
            EscapeCSV(Interface.itemid1_size),
            EscapeCSV(Interface.itemid2),
            EscapeCSV(BoolToString(Interface.hov)),
            EscapeCSV(Interface.textids),
            EscapeCSV(Interface.textitem),
            EscapeCSV(Interface.memloc),
            EscapeCSV(Interface.memloctop),
            EscapeCSV(Interface.fullpath),
            EscapeCSV(Interface.fullIDpath),
            EscapeCSV(BoolToString(Interface.notvisible)),
            EscapeCSV(Interface.OP),
            EscapeCSV(Interface.xy)
        }
        
        -- Append memory read data
        if Interface._memoryReads then
            for _, Header in ipairs(MemoryReadHeaders) do
                local MemData = Interface._memoryReads[Header]
                table.insert(RowData, EscapeCSV(MemData or ""))
            end
        else
            for _ = 1, #MemoryReadHeaders do
                table.insert(RowData, EscapeCSV(""))
            end
        end
        
        File:write(table.concat(RowData, ",") .. "\n")
        ExportedCount = ExportedCount + 1
    end
    
    File:close()
    
    print("[" .. ScriptName .. "] Exported to: " .. FinalFilename)
    
    return true
end

-- Execute the main export process
local Success = ExportInterfacesToCSV()

-- Display script information
print("=" .. string.rep("=", 50) .. "=")
print("  " .. ScriptName .. " v" .. ScriptVersion)
print("  Author: " .. Author .. " (" .. DiscordHandle .. ")")
print("  Released: " .. ReleaseDate)
print("=" .. string.rep("=", 50) .. "=")

if Success then
    OpenDirectory(Config.OutputDirectory)
end

-- The line below is needed to run the script from the ScriptManager, do not uncomment it
-- while API.Read_LoopyLoop() do