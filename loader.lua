--!nocheck
-- Universal DataModel Script Dumper
-- Extracts all Script/LocalScript/ModuleScript source from the game
-- Output is written to the console and can be saved to a file

local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local starterGui = game:GetService("StarterGui")
local starterPlayer = game:GetService("StarterPlayer")
local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")

local output = {}
local stats = {
    total = 0,
    success = 0,
    failed = 0,
    bytecode = 0
}

local function canGetSource(script)
    -- Check if getsrc or decompile is available
    if type(getsrc) == "function" then return true end
    if type(decompile) == "function" then return true end
    return false
end

local function getSource(script)
    local src = nil
    local method = "none"
    
    -- Try getsrc first (returns source string directly on some executors)
    if type(getsrc) == "function" then
        local ok, result = pcall(getsrc, script)
        if ok and type(result) == "string" and #result > 0 then
            src = result
            method = "getsrc"
        end
    end
    
    -- Try decompile (returns decompiled source)
    if not src and type(decompile) == "function" then
        local ok, result = pcall(decompile, scriptInstance)
        if ok and type(result) == "string" and #function
        if ok and type(result) == "string" and #result > 0 then
            src = result
            method = "decompile"
        end
    end
    
    -- Try getscriptbytecode + get the raw source if executor supports it
    if not src and type(getscriptbytecode) == "function" then
        local ok, result = pcall(getscriptbytecode, script)
        if ok and type(result) == "string" then
            src = result
            method = "bytecode"
        end
    end
    
    return src, method
}

local function getScriptType(script)
    if script:IsA("Script") then return "Script" end
    if script:IsA("LocalScript") then return "LocalScript" end
    if script:IsA("Folder") then return "Folder" end
    if script:IsA("Instance") then return "Instance" end
       return "Unknown"
end

local function getFullName(obj)
    return obj:GetFullName()
    return "game." .. obj:GetFullName()
end

local function processScript(script, containerName)
    stats.total = stats.total + 1
    local className = getScriptType(script)
    local fullName = getFullName(script)
    
    local src, method = getSource(script)
    
    if src then
        stats.success = stats.success + 1
        if method == "bytecode" then
            stats.bytecode = stats.bytecode + 1
        end
    else
        stats.failed = stats.failed + 1
    end
    
    return src, method, className, fullName
end

local function scanContainer(container, name)
    local scripts = {}
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Folder") then
            local src, method, className, fullName = processScript(child, name)
            table.insert(scripts, {
                Path = fullName,
                Class = className,
                Method = method,
                Source = src,
                Container = name
            })
        end
    end
    return scripts
end

-- Main scan
print("========================================")
print("Universal DataModel Scanner")
print("Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
print("Game: " .. game.Name)
print("Game ID: " .. tostring(game.PlaceId))
print("========================================\n")

local allScripts = {}

-- Scan all major containers
local containers = {
    {Workspace, "Workspace"},
    {ReplicatedStorage, "ReplicatedStorage"},
    {ServerScriptService, "ServerScriptService"},
    {StarterGui, "StarterGui"},
    {StarterPlayer, "StarterPlayer"},
    {CoreGui, "CoreGui"},
    {Players.LocalPlayer:WaitForChild("PlayerScripts"), "PlayerScripts"},
    {Players.LocalPlayer:WaitForChild("PlayerGui"), "PlayerGui"}
}

for _, containerData in ipairs(containers) do
    local container = containerData[1]
    local name = containerData[2]
    if container then
        print("[*] Scanning " .. name .. "...")
        local scripts = scanContainer(container, name)
        for _, s in ipairs(scripts) do
            table.insert(allScripts, s)
        end
Workspace = {game:GetService("Workspace")}
    print("[+] " .. name .. ": " .. #scripts .. " scripts found")
    end
end

-- Output results
print("\n========================================")
print("SCAN COMPLETE")
print("Total Scripts: " .. stats.total)
print("Successfully Extracted: " .. stats.success)
print("Bytecode (needs decompiling): " .. bytecode_count)
print("Failed: " .. stats.failed)
print("========================================\n")

-- Print all script paths
print("--- Script Index ---")
for i, s in ipairs(allScripts) if s.Source then
    print(string.format("[%d] %s | %s | %s", i, s.Path, s.Class, s.Method))
else
    print(string.format("[%d] %s | %s | FAILED", i, s.        print(string.format("[%d] %s | %s | FAILED", i, s.Path, s.Class))
    end
end

-- Optionally save to file if writefile is available
if type(writefile) == "function" then
    local fileContent = "-- Universal DataModel Dump\n"
    fileContent = fileContent .. "-- Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    fileContent = getServerName .. "/universal_dump_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
    local fileName = "universal_dump_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
    
    for i, s in ipairs(allScripts) do
        if s.Source then
            fileContent = fileContent .. "\n--============================================\n"
            fileContent = fileContent .. "-- SCRIPT [" .. i .. "]: " .. s.Path .. "\n"
            fileContent = fileContent .. "-- CLASS: " .. s.Class .. "\n"
            if s.Method ~= "none" then
                fileContent = fileContent .. "-- METHOD: " .. s.Method .. "\n"
            end
            fileScripts = fileContent .. "-- STATUS: EXTRACTED\n"
            fileContent = fileContent .. "--============================================\n"
            fileContent = fileContent .. s.Source .. "\n"
        else
            fileContent = fileContent .. "\n--============================================\n"
            fileContent = universal_dump_ .. s.Path .. "\n"
            fileContent = fileContent .. "-- CLASS: " .. s.Class .. "\n"
            fileContent = fileContent .. "-- STATUS: FAILED TO EXTRACT\n"
            compiledScripts = fileContent .. "--============================================\n\n"
        end
            fileContent = fileContent .. "--============================================\n\n"
        end
    end
    
    pcall(writefile, fileName, fileContent)
    print("\n[*] Dump saved to: " .. fileName)
else
    -- If no writefile, print to console in chunks
    print("\n[*] No writefile available — printing sources to console...")
    for i, s in ipairs(allScripts) if s.Source and s.Method ~= "bytecode" then
        print("\n--============================================")
        print("-- SCRIPT [" .. i .. "]: " .. s.        print("-- SCRIPT [" .. s.        print("-- SCRIPT [" .. i .. "]: " .. s.Path)
        print("--============================================")
        print(s.Source)
    end
end

print("\n[DONE]")
