--!nocheck
-- Universal Game Scanner v2
-- Paste into your executor and run
-- Keybind: Right Ctrl to toggle UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- ============================================
-- STATE
-- ============================================
local State = {
    scanning = false,
    scanned = false,
    results = {},
    stats = { total = 0, success = 0, failed = 0, bytecode = 0 },
    filter = "all"
}

-- ============================================
-- THEME
-- ============================================
local Theme = {
    bg = Color3.fromRGB(20, 20, 25),
    topbar = Color3.fromRGB(30, 30, 38),
    tabbar = Color3.fromRGB(25, 25, 32),
    active = Color3.fromRGB(45, 45, 55),
    inactive = Color3.fromRGB(35, 35, 42),
    text = Color3.fromRGB(235, 235, 240),
    dim = Color3.fromRGB(150, 150, 160),
    accent = Color3.fromRGB(100, 130, 255),
    green = Color3.fromRGB(80, 200, 120),
    red = Color3.fromRGB(220, 70, 70),
    btn = Color3.fromRGB(45, 45, 55),
    btnhover = Color3.fromRGB(55, 55, 68),
    stroke = Color3.fromRGB(50, 50, 60),
    entry = Color3.fromRGB(28, 28, 35),
}

-- ============================================
-- SAFE PARENT
-- ============================================
local function getParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

-- ============================================
-- BUILD GUI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalScanner"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndex = 100
ScreenGui.Parent = getParent()

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 560, 0, 420)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.bg
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.stroke
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Theme.topbar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 20)
TitleFix.Position = UDim2.new(0, 0, 0, 20)
TitleFix.BackgroundColor3 = Theme.topbar
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Universal Game Scanner"
TitleLabel.TextColor3 = Theme.text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 3, 0, 16)
AccentBar.Position = UDim2.new(0, 6, 0, 12)
AccentBar.BackgroundColor3 = Theme.accent
AccentBar.BorderSizePixel = 0
Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(0, 2)
AccentBar.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = ""
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local CloseIcon = Instance.new("TextLabel")
CloseIcon.Size = UDim2.new(1, 0, 1, 0)
CloseIcon.BackgroundTransparency = 1
CloseIcon.Text = "✕"
CloseIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseIcon.Font = Enum.Font.GothamBold
CloseIcon.TextSize = 13
CloseIcon.Parent = CloseBtn

-- Status bar
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -16, 0, 28)
StatusBar.Position = UDim2.new(0, 8, 0, 46)
StatusBar.BackgroundColor3 = Theme.tabbar
StatusBar.BorderSizePixel = 0
StatusBar.Parent = MainFrame
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 1, 0)
StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready — Click Scan to begin"
StatusLabel.TextColor3 = Theme.dim
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusBar

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -16, 0.5, -4)
StatusDot.BackgroundColor3 = Theme.dim
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusBar
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

-- Button row
local BtnRow = Instance.new("Frame")
BtnRow.Size = UDim2.new(1, -16, 0, 32)
BtnRow.Position = UDim2.new(0, 8, 0, 80)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent = MainFrame

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 120, 1, 0)
ScanBtn.BackgroundColor3 = Theme.accent
ScanBtn.Text = "Scan Game"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 12
ScanBtn.AutoButtonColor = false
ScanBtn.Parent = BtnRow
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local ExportBtn = Instance.new("TextButton")
ExportBtn.Size = UDim2.new(0, 120, 1, 0)
ExportBtn.Position = UDim2.new(0, 128, 0, 0)
ExportBtn.BackgroundColor3 = Theme.btn
ExportBtn.Text = "Export to File"
ExportBtn.TextColor3 = Theme.text
ExportBtn.Font = Enum.Font.GothamBold
ExportBtn.TextSize = 12
ExportBtn.AutoButtonColor = false
ExportBtn.Parent = BtnRow
Instance.new("UICorner", ExportBtn).CornerRadius = UDim.new(0, 6)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 120, 1, 0)
CopyBtn.Position = UDim2.new(0, 256, 0, 0)
CopyBtn.BackgroundColor3 = Theme.btn
CopyBtn.Text = "Copy Results"
CopyBtn.TextColor3 = Theme.text
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 12
CopyBtn.AutoButtonColor = false
CopyBtn.Parent = BtnRow
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

local FilterBtn = Instance.new("TextButton")
FilterBtn.Size = UDim2.new(0, 120, 1, 0)
FilterBtn.Position = UDim2.new(1, -120, 0, 0)
FilterBtn.BackgroundColor3 = Theme.btn
FilterBtn.Text = "Filter: All"
FilterBtn.TextColor3 = Theme.text
FilterBtn.Font = Enum.Font.GothamBold
FilterBtn.TextSize = 12
FilterBtn.AutoButtonColor = false
FilterBtn.Parent = BtnRow
Instance.new("UICorner", FilterBtn).CornerRadius = UDim.new(0, 6)

-- Results list
local ResultsHeader = Instance.new("TextLabel")
ResultsHeader.Size = UDim2.new(1, -16, 0, 18)
ResultsHeader.Position = UDim2.new(0, 8, 0, 118)
ResultsHeader.BackgroundTransparency = 1
ResultsHeader.Text = "  Results"
ResultsHeader.TextColor3 = Theme.accent
ResultsHeader.Font = Enum.Font.GothamBold
ResultsHeader.TextSize = 11
ResultsHeader.TextXAlignment = Enum.TextXAlignment.Left
ResultsHeader.Parent = MainFrame

local ResultsFrame = Instance.new("Frame")
ResultsFrame.Size = UDim2.new(1, -16, 1, -146)
ResultsFrame.Position = UDim2.new(0, 8, 0, 138)
ResultsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ResultsFrame.BorderSizePixel = 0
ResultsFrame.Parent = MainFrame
Instance.new("UICorner", ResultsFrame).CornerRadius = UDim.new(0, 6)

local ResultsScroll = Instance.new("ScrollingFrame")
ResultsScroll.Size = UDim2.new(1, -8, 1, -8)
ResultsScroll.Position = UDim2.new(0, 4, 0, 4)
ResultsScroll.BackgroundTransparency = 1
ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultsScroll.ScrollBarImageColor3 = Theme.dim
ResultsScroll.ScrollBarThickness = 4
ResultsScroll.Parent = ResultsFrame

local ResultsLayout = Instance.new("UIListLayout")
ResultsLayout.Padding = UDim.new(0, 2)
ResultsLayout.Parent = ResultsScroll

-- Stats footer
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -16, 0, 16)
StatsLabel.Position = UDim2.new(0, 8, 1, -20)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Total: 0 | Success: 0 | Failed: 0 | Bytecode: 0"
StatsLabel.TextColor3 = Theme.dim
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextSize = 10
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = MainFrame

-- ============================================
-- DRAGGING
-- ============================================
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ============================================
-- HELPERS
-- ============================================
local function setStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or Theme.dim
    StatusDot.BackgroundColor3 = color or Theme.dim
end

local function updateStats()
    StatsLabel.Text = string.format("Total: %d | Success: %d | Failed: %d | Bytecode: %d",
        State.stats.total, State.stats.success, State.stats.failed, State.stats.bytecode)
end

local function updateCanvas()
    ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, ResultsLayout.AbsoluteContentSize.Y + 8)
end

local function clearResults()
    for _, child in pairs(ResultsScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
end

local function addResultEntry(data)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, 28)
    entry.BackgroundColor3 = Theme.entry
    entry.BorderSizePixel = 0
    entry.Parent = ResultsScroll
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)

    local pathLabel = Instance.new("TextLabel")
    pathLabel.Size = UDim2.new(1, -80, 1, 0)
    pathLabel.Position = UDim2.new(0, 8, 0, 0)
    pathLabel.BackgroundTransparency = 1
    pathLabel.Text = data.path
    pathLabel.TextColor3 = Theme.text
    pathLabel.Font = Enum.Font.Gotham
    pathLabel.TextSize = 10
    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
    pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pathLabel.Parent = entry

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 64, 1, 0)
    statusLabel.Position = UDim2.new(1, -72, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = data.status
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 9
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = entry

    if data.status == "OK" then
        statusLabel.TextColor3 = Theme.green
    elseif data.status == "BYTECODE" then
        statusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
    else
        statusLabel.TextColor3 = Theme.red
    end

    -- Click to view source
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = entry

    btn.MouseButton1Click:Connect(function()
        if data.source and #data.source > 0 then
            -- Show source in a popup
            showSourcePopup(data.path, data.source)
        else
            setStatus("No source available for " .. data.path, Theme.red)
        end
    end)

    updateCanvas()
end

-- ============================================
-- SOURCE VIEWER POPUP
-- ============================================
local PopupFrame = nil

local function closePopup()
    if PopupFrame then PopupFrame:Destroy() PopupFrame = nil end
end

function showSourcePopup(path, source)
    closePopup()

    PopupFrame = Instance.new("Frame")
    PopupFrame.Size = UDim2.new(0, 500, 0, 400)
    PopupFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    PopupFrame.BackgroundColor3 = Theme.bg
    PopupFrame.BorderSizePixel = 0
    PopupFrame.ZIndex = 200
    PopupFrame.Parent = ScreenGui
    Instance.new("UICorner", PopupFrame).CornerRadius = UDim.new(0, 8)

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = Theme.accent
    pStroke.Thickness = 1
    pStroke.Parent = PopupFrame

    local pTitle = Instance.new("Frame")
    pTitle.Size = UDim2.new(1, 0, 0, 32)
    pTitle.BackgroundColor3 = Theme.topbar
    pTitle.BorderSizePixel = 0
    pTitle.Parent = PopupFrame
    Instance.new("UICorner", pTitle).CornerRadius = UDim.new(0, 8)

    local pTitleLabel = Instance.new("TextLabel")
    pTitleLabel.Size = UDim2.new(1, -60, 1, 0)
    pTitleLabel.Position = UDim2.new(0, 10, 0, 0)
    pTitleLabel.BackgroundTransparency = 1
    pTitleLabel.Text = path
    pTitleLabel.TextColor3 = Theme.text
    pTitleLabel.Font = Enum.Font.GothamBold
    pTitleLabel.TextSize = 11
    pTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    pTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pTitleLabel.Parent = pTitle

    local pClose = Instance.new("TextButton")
    pClose.Size = UDim2.new(0, 24, 0, 24)
    pClose.Position = UDim2.new(1, -28, 0, 4)
    pClose.BackgroundColor3 = Theme.red
    pClose.Text = "✕"
    pClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    pClose.Font = Enum.Font.GothamBold
    pClose.TextSize = 11
    pClose.Parent = pTitle
    Instance.new("UICorner", pClose).CornerRadius = UDim.new(0, 4)
    pClose.MouseButton1Click:Connect(closePopup)

    local pScroll = Instance.new("ScrollingFrame")
    pScroll.Size = UDim2.new(1, -12, 1, -44)
    pScroll.Position = UDim2.new(0, 6, 0, 38)
    pScroll.BackgroundTransparency = 1
    pScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    pScroll.ScrollBarImageColor3 = Theme.dim
    pScroll.ScrollBarThickness = 4
    pScroll.Parent = PopupFrame

    local pSource = Instance.new("TextLabel")
    pSource.Size = UDim2.new(1, -8, 0, 0)
    pSource.BackgroundTransparency = 1
    pSource.Text = source
    pSource.TextColor3 = Theme.text
    pSource.Font = Enum.Font.Code
    pSource.TextSize = 11
    pSource.TextXAlignment = Enum.TextXAlignment.Left
    pSource.TextYAlignment = Enum.TextYAlignment.Top
    pSource.RichText = true
    pSource.Parent = pScroll

    -- Auto-size
    local textBounds = TextService and TextService:GetTextSize(source, 11, Enum.Font.Code, Vector2.new(pScroll.AbsoluteSize.X - 8, math.huge))
    if textBounds then
        pSource.Size = UDim2.new(1, -8, 0, textBounds.Y + 20)
        pScroll.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 20)
    else
        pSource.AutomaticSize = Enum.AutomaticSize.Y
        pScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end

    -- Popup dragging
    local dragging, dragStart, startPos
    pTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = PopupFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            PopupFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ============================================
-- SCAN LOGIC
-- ============================================
local function getScriptSource(script)
    -- Try getsrc
    if type(getsrc) == "function" then
        local ok, result = pcall(getsrc, script)
        if ok and type(result) == "string" and #result > 0 then
            return result, "OK"
        end
    end

    -- Try decompile
    if type(decompile) == "function" then
        local ok, result = pcall(decompile, script)
        if ok and type(result) == "string" and #result > 0 then
            return result, "OK"
        end
    end

    -- Try getscriptbytecode
    if type(getscriptbytecode) == "function" then
        local ok, result = pcall(getscriptbytecode, script)
        if ok and type(result) == "string" and #result > 0 then
            return result, "BYTECODE"
        end
    end

    return nil, "FAILED"
end

local function getContainers()
    return {
        {game:GetService("Workspace"), "Workspace"},
        {game:GetService("ReplicatedStorage"), "ReplicatedStorage"},
        {game:GetService("ServerScriptService"), "ServerScriptService"},
        {game:GetService("StarterGui"), "StarterGui"},
        {game:GetService("StarterPlayer"), "StarterPlayer"},
    }
end

local function performScan()
    State.scanning = true
    State.scanned = false
    State.results = {}
    State.stats = { total = 0, success = 0, failed = 0, bytecode = 0 }
    clearResults()
    setStatus("Scanning...", Theme.accent)
    ScanBtn.Text = "Scanning..."
    ScanBtn.BackgroundColor3 = Theme.dim

    local containers = getContainers()

    -- Also try CoreGui and PlayerScripts
    pcall(function()
        table.insert(containers, {game:GetService("CoreGui"), "CoreGui"})
    end)
    pcall(function()
        table.insert(containers, {LP:WaitForChild("PlayerScripts"), "PlayerScripts"})
    end)
    pcall(function()
        table.insert(containers, {LP:WaitForChild("PlayerGui"), "PlayerGui"})
    end)

    for _, containerData in ipairs(containers) do
        local container = containerData[1]
        local name = containerData[2]
        if container then
            setStatus("Scanning " .. name .. "...", Theme.accent)

            for _, child in ipairs(container:GetDescendants()) do
                if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
                    State.stats.total = State.stats.total + 1
                    local path = child:GetFullName()
                    local className = child.ClassName
                    local src, status = getScriptSource(child)

                    if status == "OK" then
                        State.stats.success = State.stats.success + 1
                    elseif status == "BYTECODE" then
                        State.stats.bytecode = State.stats.bytecode + 1
                    else
                        State.stats.failed = State.stats.failed + 1
                    end

                    local entry = {
                        path = path,
                        class = className,
                        status = status,
                        source = src,
                        container = name
                    }
                    table.insert(State.results, entry)

                    -- Add to UI (respect filter)
                    local show = false
                    if State.filter == "all" then show = true
                    elseif State.filter == "ok" and status == "OK" then show = true
                    elseif State.filter == "bytecode" and status == "BYTECODE" then show = true
                    elseif State.filter == "failed" and status == "FAILED" then show = true
                    end

                    if show then
                        addResultEntry(entry)
                    end

                    updateStats()
                    RunService.RenderStepped:Wait()
                end
            end
        end
    end

    State.scanning = false
    State.scanned = true
    ScanBtn.Text = "Scan Game"
    ScanBtn.BackgroundColor3 = Theme.accent
    setStatus(string.format("Scan complete — %d scripts found", State.stats.total), Theme.green)
end

-- ============================================
-- EXPORT
-- ============================================
local function exportToFile()
    if #State.results == 0 then
        setStatus("Nothing to export — scan first", Theme.red)
        return
    end

    if type(writefile) ~= "function" then
        setStatus("writefile not available", Theme.red)
        return
    end

    setStatus("Exporting...", Theme.accent)

    local content = "============================================\n"
    content = content .. "Universal Game Scanner Dump\n"
    content = content .. "Game: " .. game.Name .. "\n"
    content = content .. "Place ID: " .. tostring(game.PlaceId) .. "\n"
    content = content .. "Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    content = content .. "Total: " .. State.stats.total .. " | Success: " .. State.stats.success .. " | Failed: " .. State.stats.failed .. " | Bytecode: " .. State.stats.bytecode .. "\n"
    content = content .. "============================================\n\n"

    -- Index
    content = content .. "SCRIPT INDEX:\n"
    content = content .. string.rep("-", 80) .. "\n"
    for i, r in ipairs(State.results) do
        content = content .. string.format("[%d] %s | %s | %s\n", i, r.path, r.class, r.status)
    end
    content = content .. "\n"

    -- Sources
    for i, r in ipairs(State.results) do
        content = content .. "\n============================================\n"
        content = content .. string.format("SCRIPT [%d]: %s\n", i, r.path)
        content = content .. "CLASS: " .. r.class .. "\n"
        content = content .. "STATUS: " .. r.status .. "\n"
        content = content .. "============================================\n"
        if r.source then
            content = content .. r.source .. "\n"
        else
            content = content .. "-- [NO SOURCE AVAILABLE]\n"
        end
    end

    local filename = "scan_" .. game.Name:gsub("%s", "_") .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    pcall(writefile, filename, content)
    setStatus("Exported to: " .. filename, Theme.green)
end

local function copyResults()
    if #State.results == 0 then
        setStatus("Nothing to copy — scan first", Theme.red)
        return
    end

    if type(setclipboard) ~= "function" then
        setStatus("setclipboard not available", Theme.red)
        return
    end

    local text = "Universal Scanner Results\n"
    text = text .. "Game: " .. game.Name .. " | Place: " .. tostring(game.PlaceId) .. "\n"
    text = text .. "Total: " .. State.stats.total .. " | OK: " .. State.stats.success .. " | Failed: " .. State.stats.failed .. " | Bytecode: " .. State.stats.bytecode .. "\n\n"

    for i, r in ipairs(State.results) do
        text = text .. string.format("[%d] %s | %s | %s\n", i, r.path, r.class, r.status)
    end

    pcall(setclipboard, text)
    setStatus("Results copied to clipboard", Theme.green)
end

-- ============================================
-- BUTTONS
-- ============================================
ScanBtn.MouseButton1Click:Connect(function()
    if not State.scanning then
        performScan()
    end
end)

ExportBtn.MouseButton1Click:Connect(exportToFile)
CopyBtn.MouseButton1Click:Connect(copyResults)

FilterBtn.MouseButton1Click:Connect(function()
    local filters = {"all", "ok", "bytecode", "failed"}
    local labels = {"All", "OK Only", "Bytecode Only", "Failed Only"}
    local idx = 1
    for i, f in ipairs(filters) do
        if f == State.filter then idx = i break end
    end
    idx = idx % #filters + 1
    State.filter = filters[idx]
    FilterBtn.Text = "Filter: " .. labels[idx]

    -- Re-populate
    clearResults()
    for _, r in ipairs(State.results) do
        local show = false
        if State.filter == "all" then show = true
        elseif State.filter == "ok" and r.status == "OK" then show = true
        elseif State.filter == "bytecode" and r.status == "BYTECODE" then show = true
        elseif State.filter == "failed" and r.status == "FAILED" then show = true
        end
        if show then addResultEntry(r) end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- ============================================
-- KEYBIND
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- ============================================
-- INIT
-- ============================================
setStatus("Ready — Click Scan to begin | Right Ctrl to toggle", Theme.dim)
print("[Universal Scanner] Loaded — Right Ctrl to toggle UI")
