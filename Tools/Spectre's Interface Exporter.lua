local ScriptName = "Interface Exporter"
local Author = "Spectre011"
local ScriptVersion = "1.3.0"
local ReleaseDate = "15-06-2025"
local DiscordHandle = "not_spectre011"

--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                          INTERFACE EXPORTER SCRIPT                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Description: Recursively scans game interfaces and exports data to CSV      ║
║  Usage:       Configure parameters in the Config table below and execute     ║
║  Output:      CSV file with detailed interface information                   ║
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
    -- Normalize path by removing trailing backslashes
    Path = Path:gsub("\\+$", "")
    
    -- Use Windows 'start' command for optimal window management
    -- This will bring existing Explorer windows to front instead of opening duplicates
    os.execute('start "" "' .. Path .. '"')
end

-- Creates directory structure and validates write permissions
---@param DirPath string The directory path to create and validate
---@return boolean Success True if directory exists and is writable, false otherwise
local function EnsureDirectoryExists(DirPath)
    -- Attempt to create directory (silently fails if already exists)
    local Success = os.execute('mkdir "' .. DirPath .. '" 2>nul')
    
    -- Validate write access by creating and removing a temporary test file
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
    
    -- Return base filename if it doesn't exist
    local File = io.open(FullPath, "r")
    if not File then
        return FullPath
    end
    File:close()
    
    -- Parse filename into name and extension components
    local Name, Ext = BaseFilename:match("^(.+)%.([^%.]+)$")
    if not Name then
        Name = BaseFilename
        Ext = ""
    end
    
    -- Find next available numbered filename
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
    -- Quote and escape if contains CSV special characters (comma, quote, newline, carriage return)
    if string.find(Str, '[,"\n\r]') then
        Str = string.gsub(Str, '"', '""') -- Escape internal quotes by doubling them
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
    -- Always wrap column names in quotes for maximum compatibility
    Str = string.gsub(Str, '"', '""') -- Escape internal quotes
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
        table.insert(Parts, Segment[1] .. "," .. Segment[2])
    end
    return table.concat(Parts, ";")
end

-- Creates child interface path by appending new segment to existing path
---@param CurrentPath table The current interface path hierarchy
---@param Id2 number The id2 value to append as new path segment
---@return table ChildPath The extended path hierarchy for child interfaces
local function CreateChildPath(CurrentPath, Id2)
    local ChildPath = {}
    -- Deep copy existing path segments to avoid reference issues
    for I = 1, #CurrentPath do
        local PathSegment = {}
        for K, V in ipairs(CurrentPath[I]) do
            PathSegment[K] = V
        end
        table.insert(ChildPath, PathSegment)
    end
    
    -- Append new segment using same path identifier as root for consistency
    local PathIdentifier = CurrentPath[1][1]
    table.insert(ChildPath, { PathIdentifier, Id2, -1, 0 })
    
    return ChildPath
end

-- Recursively scans interface hierarchies and extracts comprehensive data
-- Performs memory reads, duplicate detection, and hierarchical traversal
---@param CurrentPath table Current interface path being scanned
---@param VisitedPaths table Tracking table to prevent infinite recursion
---@param AllInterfaces table Accumulator for all discovered interfaces
---@param Depth number Current recursion depth (for logging and limits)
---@param MaxDepth number Maximum recursion depth to prevent stack overflow
---@param SeenMemlocs table Memory location tracker for duplicate detection
---@return table AllInterfaces Complete collection of interface data
local function ScanAllInterfaces(CurrentPath, VisitedPaths, AllInterfaces, Depth, MaxDepth, SeenMemlocs)
    Depth = Depth or 0
    MaxDepth = MaxDepth or 50
    VisitedPaths = VisitedPaths or {}
    AllInterfaces = AllInterfaces or {}
    SeenMemlocs = SeenMemlocs or {}
    
    -- Prevent infinite recursion by enforcing depth limits
    if Depth > MaxDepth then
        print("[" .. ScriptName .. "] Warning: Max depth reached (" .. Depth .. ")")
        return AllInterfaces
    end
    
    -- Skip paths already visited to prevent circular scanning
    local PathKey = PathToKey(CurrentPath)
    if VisitedPaths[PathKey] then
        return AllInterfaces
    end
    VisitedPaths[PathKey] = true
    
    -- Generate human-readable path string for debugging and logging
    local PathString = ""
    for I, Segment in ipairs(CurrentPath) do
        if I > 1 then PathString = PathString .. " -> " end
        PathString = PathString .. table.concat(Segment, ",")
    end
    
    -- Create formatted interface ID string for CSV export
    local InterfaceIDString = "{ "
    for I, Segment in ipairs(CurrentPath) do
        if I > 1 then InterfaceIDString = InterfaceIDString .. ", " end
        InterfaceIDString = InterfaceIDString .. "{" .. table.concat(Segment, ",") .. "}"
    end
    InterfaceIDString = InterfaceIDString .. " }"
    
    -- Safely attempt to scan current interface level with error handling
    local Success, Interfaces = pcall(function() 
        return API.ScanForInterfaceTest2Get(true, CurrentPath) 
    end)
    
    if not Success then
        print("[" .. ScriptName .. "] Error at depth " .. Depth .. ": " .. tostring(Interfaces))
        return AllInterfaces
    end
    
    if not Interfaces or #Interfaces == 0 then
        return AllInterfaces
    end
    
    print("[" .. ScriptName .. "] Level " .. Depth .. ": Found " .. #Interfaces .. " interfaces")
    
    -- Track unique id2 values for recursive sub-interface scanning
    local UniqueId2Values = {}
    local Id2Count = 0
    
    -- Process each discovered interface and extract comprehensive data
    for I, Interface in ipairs(Interfaces) do
        -- Skip duplicate interfaces based on memory location to avoid redundant data
        if Interface.memloc and SeenMemlocs[Interface.memloc] then
            -- Skip silently to avoid spam in console output
        else
            -- Mark this memory location as seen for future duplicate detection
            if Interface.memloc then 
                SeenMemlocs[Interface.memloc] = true 
            end

            -- Legacy specific memory reads (maintained for backward compatibility)
            local Memloc_I_itemids3_Char = ""
            local Memloc_I_slides_Int = ""
            
            -- Comprehensive memory read analysis using multiple API functions
            local MemoryReads = {}
            
            if Interface.memloc then
                -- Define all available API constants for memory offset calculations
                local ApiConstants = {
                    {name = "I_00textP", value = API.I_00textP},
                    {name = "I_itemids3", value = API.I_itemids3},
                    {name = "I_itemids", value = API.I_itemids},
                    {name = "I_itemstack", value = API.I_itemstack},
                    {name = "I_slides", value = API.I_slides},
                    {name = "I_buffb", value = API.I_buffb}
                }
                
                -- Group memory read functions by data type for systematic analysis
                local MemReadGroups = {
                    {
                        name = "Mem_Read_char",
                        func = API.Mem_Read_char,
                        reads = {
                            {name = "memloc", offset = 0}  -- Base memory location
                        }
                    },
                    {
                        name = "Mem_Read_short", 
                        func = API.Mem_Read_short,
                        reads = {
                            {name = "memloc", offset = 0}
                        }
                    },
                    {
                        name = "Mem_Read_int",
                        func = API.Mem_Read_int,
                        reads = {
                            {name = "memloc", offset = 0}
                        }
                    },
                    {
                        name = "Mem_Read_uint64",
                        func = API.Mem_Read_uint64,
                        reads = {
                            {name = "memloc", offset = 0}
                        }
                    },
                    {
                        name = "ReadCharsLimit",
                        func = API.ReadCharsLimit,
                        reads = {}  -- Will be populated with constant combinations
                    }
                }
                
                -- Generate all combinations of memory functions with API constants
                for _, Constant in ipairs(ApiConstants) do
                    if Constant.value and type(Constant.value) == "number" then
                        -- Add constant offset combinations to numeric read functions
                        for _, Group in ipairs(MemReadGroups) do
                            if Group.name ~= "ReadCharsLimit" then
                                table.insert(Group.reads, {name = "memloc+" .. Constant.name, offset = Constant.value})
                            end
                        end
                        
                        -- Add constant offset combinations to string read function
                        table.insert(MemReadGroups[5].reads, {name = "memloc+" .. Constant.name, offset = Constant.value, limit = 255})
                    end
                end
                
                -- Execute memory reads and format results for CSV export
                for _, Group in ipairs(MemReadGroups) do
                    for _, Read in ipairs(Group.reads) do
                        -- Generate descriptive function name for CSV column
                        local FunctionName = Group.name .. "(" .. Read.name .. ")"
                        if Group.func == API.ReadCharsLimit then
                            FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                        end
                        
                        -- Safely execute memory read with error handling
                        local Success, Result = pcall(function()
                            if Group.func == API.ReadCharsLimit then
                                return Group.func(Interface.memloc + Read.offset, Read.limit)
                            else
                                return Group.func(Interface.memloc + Read.offset)
                            end
                        end)
                        
                        -- Format results based on data type for optimal CSV presentation
                        if Success and Result then
                            local FormattedResult
                            local ResultType = type(Result)
                            
                            if ResultType == "number" then
                                -- Validate number is finite and can be formatted
                                if Result == Result and Result ~= math.huge and Result ~= -math.huge then
                                    -- Ensure Result is within valid integer range for formatting
                                    local SafeResult = math.floor(Result + 0.5) -- Round to nearest integer
                                    
                                    -- Additional range validation for format safety
                                    if SafeResult < 0 then
                                        SafeResult = 0  -- Clamp negative values for hex formatting
                                    end
                                    
                                    -- Safely format numbers with error handling
                                    local formatSuccess, formattedValue = pcall(function()
                                        if Group.func == API.Mem_Read_char then
                                            return string.format("0x%02X (%d)", SafeResult % 256, SafeResult)
                                        elseif Group.func == API.Mem_Read_short then
                                            return string.format("0x%04X (%d)", SafeResult % 65536, SafeResult)
                                        elseif Group.func == API.Mem_Read_int then
                                            return string.format("0x%08X (%d)", SafeResult % 4294967296, SafeResult)
                                        elseif Group.func == API.Mem_Read_uint64 then
                                            -- For very large numbers, limit to safe range
                                            if SafeResult > 9223372036854775807 then  -- Max safe integer
                                                return "0xFFFFFFFFFFFFFFFF (overflow)"
                                            else
                                                return string.format("0x%016X (%d)", SafeResult, SafeResult)
                                            end
                                        else
                                            return tostring(SafeResult)
                                        end
                                    end)
                                    
                                    if formatSuccess then
                                        FormattedResult = formattedValue
                                    else
                                        FormattedResult = "Format Error (" .. tostring(SafeResult) .. ")"
                                    end
                                else
                                    -- Handle invalid numbers (NaN, infinity)
                                    FormattedResult = "Invalid (" .. tostring(Result) .. ")"
                                end
                            elseif ResultType == "string" then
                                if Result == "" then
                                    FormattedResult = '"" (empty string)'
                                else
                                    -- Escape control characters and limit length for readability
                                    local EscapedResult = string.gsub(Result, "[\0-\31\127-\255]", function(c)
                                        local byteValue = string.byte(c)
                                        if byteValue and byteValue >= 0 and byteValue <= 255 then
                                            return string.format("\\x%02X", byteValue)
                                        else
                                            return "\\x??"  -- Fallback for invalid byte values
                                        end
                                    end)
                                    
                                    if string.len(EscapedResult) > 50 then
                                        EscapedResult = string.sub(EscapedResult, 1, 47) .. "..."
                                    end
                                    
                                    FormattedResult = '"' .. EscapedResult .. '"'
                                end
                            else
                                -- Handle other data types (boolean, table, etc.)
                                FormattedResult = tostring(Result) .. " (" .. ResultType .. ")"
                            end
                            
                            MemoryReads[FunctionName] = FormattedResult
                        else
                            -- Mark failed reads for debugging purposes
                            MemoryReads[FunctionName] = "Error"
                        end
                    end
                end
                
                -- Maintain legacy memory reads for backward compatibility with older exports
                local Success1, Result1 = pcall(function()
                    return API.ReadCharsLimit(Interface.memloc + API.I_itemids3, 255)
                end)
                if Success1 and Result1 then
                    Memloc_I_itemids3_Char = tostring(Result1)
                end
                
                local Success2, Result2 = pcall(function()
                    return API.Mem_Read_int(Interface.memloc + API.I_slides)
                end)
                if Success2 and Result2 then
                    Memloc_I_slides_Int = tostring(Result2)
                end
            end

            -- Create proper InterfaceID by appending current interface's id1, id2, id3
            local ProperInterfaceID = "{ "
            for I, Segment in ipairs(CurrentPath) do
                if I > 1 then ProperInterfaceID = ProperInterfaceID .. ", " end
                ProperInterfaceID = ProperInterfaceID .. "{" .. table.concat(Segment, ",") .. "}"
            end
            -- Append current interface's id values
            ProperInterfaceID = ProperInterfaceID .. ", {" .. (Interface.id1 or 0) .. "," .. (Interface.id2 or 0) .. "," .. (Interface.id3 or 0) .. ",0} }"

            -- Create comprehensive interface data structure for CSV export
            local InterfaceCopy = {
                -- Metadata fields
                _parentInterfaceID = InterfaceIDString,
                _interfaceID = ProperInterfaceID,
                _depth = Depth,
                -- Standard interface properties from API
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
                xy = Interface.xy,
                -- Comprehensive memory analysis results
                _memoryReads = MemoryReads
            }
            
            table.insert(AllInterfaces, InterfaceCopy)
            
            -- Collect valid id2 values for recursive sub-interface scanning
            if Interface.id2 ~= nil and Interface.id2 ~= -1 and Interface.id2 ~= 0 then
                if not UniqueId2Values[Interface.id2] then
                    UniqueId2Values[Interface.id2] = true
                    Id2Count = Id2Count + 1
                end
            end
        end
    end
    
    -- Recursively scan discovered sub-interfaces
    if Id2Count > 0 then
        print("[" .. ScriptName .. "] Level " .. Depth .. ": Scanning " .. Id2Count .. " sub-interfaces")
        for Id2, _ in pairs(UniqueId2Values) do
            local ChildPath = CreateChildPath(CurrentPath, Id2)
            local ChildKey = PathToKey(ChildPath)
            
            -- Prevent re-scanning already visited paths
            if not VisitedPaths[ChildKey] then
                ScanAllInterfaces(ChildPath, VisitedPaths, AllInterfaces, Depth + 1, MaxDepth, SeenMemlocs)
            end
        end
    end
    
    -- Periodic memory cleanup to prevent excessive memory usage during deep scans
    collectgarbage("collect")
    
    return AllInterfaces
end

-- Main export function that orchestrates scanning and CSV generation
---Handles file creation, header generation, data formatting, and error recovery
---@return boolean Success True if export completed successfully, false on error
local function ExportInterfacesToCSV()
    print("[" .. ScriptName .. "] Starting interface scan...")
    
    -- Execute comprehensive recursive interface scanning
    local AllInterfaces = ScanAllInterfaces(Config.StartingInterface, {}, {}, 0, 50, {})
    
    -- Validate scan results before proceeding with export
    if not AllInterfaces or #AllInterfaces == 0 then
        print("[" .. ScriptName .. "] No interfaces found!")
        return false
    end
    
    print("[" .. ScriptName .. "] Total interfaces found: " .. #AllInterfaces)
    
    -- Generate unique filename to prevent accidental overwrites
    local FinalFilename = GetUniqueFilename(Config.OutputFileName)
    
    -- Create and open CSV file for writing with error handling
    local File = io.open(FinalFilename, "w")
    if not File then
        print("[" .. ScriptName .. "] Error: Could not create file: " .. FinalFilename)
        return false
    end
    
    -- Define standard CSV column headers for interface properties
    local Headers = {
        "parentInterfaceID", "interfaceID", "depth", "index", "x", "xs", "y", "ys", "box_x", "box_y", "scroll_y",
        "id1", "id2", "id3", "itemid1", "itemid1_size", "itemid2",
        "hov", "textids", "textitem", "memloc", "memloctop",
        "fullpath", "fullIDpath", "notvisible", "OP", "xy"
    }
    
    -- Dynamically generate column headers for memory read functions
    local MemoryReadHeaders = {}
    if AllInterfaces and #AllInterfaces > 0 and AllInterfaces[1]._memoryReads then
        for FunctionName, _ in pairs(AllInterfaces[1]._memoryReads) do
            table.insert(MemoryReadHeaders, FunctionName)
        end
        -- Sort headers alphabetically for consistent column ordering
        table.sort(MemoryReadHeaders)
    end
    
    -- Combine and escape all headers for CSV compatibility
    local EscapedHeaders = {}
    for _, Header in ipairs(Headers) do
        table.insert(EscapedHeaders, EscapeColumnName(Header))
    end
    for _, Header in ipairs(MemoryReadHeaders) do
        table.insert(EscapedHeaders, EscapeColumnName(Header))
    end
    
    -- Write CSV header row
    File:write(table.concat(EscapedHeaders, ",") .. "\n")
    
    -- Export each interface as a properly formatted CSV row
    local ExportedCount = 0
    for I, Interface in ipairs(AllInterfaces) do
        -- Build standard data columns with proper CSV escaping
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
        
        -- Append memory read data columns in consistent order
        if Interface._memoryReads then
            for _, Header in ipairs(MemoryReadHeaders) do
                local MemoryData = Interface._memoryReads[Header]
                if MemoryData then
                    table.insert(RowData, EscapeCSV(MemoryData))
                else
                    table.insert(RowData, EscapeCSV(""))  -- Empty cell for missing data
                end
            end
        else
            -- Add empty columns if no memory reads available for this interface
            for _ = 1, #MemoryReadHeaders do
                table.insert(RowData, EscapeCSV(""))
            end
        end
        
        -- Write complete row to CSV file
        File:write(table.concat(RowData, ",") .. "\n")
        ExportedCount = ExportedCount + 1
    end
    
    File:close()
    
    print("[" .. ScriptName .. "] Export completed!")
    print("[" .. ScriptName .. "] Exported " .. ExportedCount .. " interfaces to: " .. FinalFilename)
    
    return true
end

-- Execute the main export process and capture results
local Success = ExportInterfacesToCSV()

-- Display comprehensive script information and execution results
print("=" .. string.rep("=", 50) .. "=")
print("  " .. ScriptName .. " v" .. ScriptVersion)
print("  Author: " .. Author .. " (" .. DiscordHandle .. ")")
print("  Released: " .. ReleaseDate)
print("=" .. string.rep("=", 50) .. "=")

if Success then
    print("")
    print("[" .. ScriptName .. "] Export successful!")
    -- Automatically open the output directory for user convenience
    OpenDirectory(Config.OutputDirectory)
else
    print("")
    print("[" .. ScriptName .. "] Export failed!")
end

-- The line below is needed to run the script from the ScriptManager, do not uncomment it
-- while API.Read_LoopyLoop() do
