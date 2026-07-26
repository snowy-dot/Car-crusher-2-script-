--!nocheck
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local State = {}
State.ESP_Enabled = false
State.ESP_Box = true
State.ESP_Name = true
State.ESP_Objects = {}
State.CrusherESP_Enabled = false
State.CrusherESP_Objects = {}
State.AutoFarm = false
State.AutoRespawn = false
State.PhaseWals = false
State.AutoCash = false
State.Fly_Enabled = false
State.Fly_Speed = 50
State.Vehicle_Fly = false
State.Vehicle_Speed = 150
State.Vehicle_Noclip = false
State.Q_Boost = false
State.Boost_Active = false
State.Boost_Speed = 600
State.Boost_EndTime = 0
State.Boost_Cooldown = 0
State.NoClip = false
State.InfJump = false
State.UnlockCam = false
State.AntiFling = false
State.PickupCar = false
State.Connections = {}
State.AntiGrav = false
State.CustomFOV = false
State.FOVValue = 70
State.AutoMaxStats = false
State.DriftMode = false
State.LastStatCheck = 0
State.FlingPvP = false
State.FlingRadius = 30
State.FlingPower = 5000
State.GUI_Open = false

local CooldownGui = Instance.new("ScreenGui")
CooldownGui.Name = "BoostCooldown"
CooldownGui.ResetOnSpawn = false
pcall(function() CooldownGui.Parent = gethui() end)
if not CooldownGui.Parent then CooldownGui.Parent = LP:WaitForChild("PlayerGui") end

local CooldownFrame = Instance.new("Frame", CooldownGui)
CooldownFrame.Size = UDim2.new(0, 200, 0, 50)
CooldownFrame.Position = UDim2.new(0.5, -100, 1, -100)
CooldownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CooldownFrame.BackgroundTransparency = 0.5
Instance.new("UICorner", CooldownFrame).CornerRadius = UDim.new(0, 8)
local CooldownLabel = Instance.new("TextLabel", CooldownFrame)
CooldownLabel.Size = UDim2.new(1, 0, 1, 0)
CooldownLabel.BackgroundTransparency = 1
CooldownLabel.Text = "Booster Ready"
CooldownLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
CooldownLabel.Font = Enum.Font.GothamBold
CooldownLabel.TextSize = 18
CooldownFrame.Visible = false

local FlingBarrier = Instance.new("Part")
FlingBarrier.Name = "FlingBarrierVisual"
FlingBarrier.Shape = Enum.PartType.Ball
FlingBarrier.Material = Enum.Material.ForceField
FlinkBarrier.Color = Color3.fromRGB(255, 0, 0)
FlingBarrier.Transparency = 1
FlingBarrier.Anchored = true
FlingBarrier.CanCollide = false
FlingBarrier.CanQuery = false
FlingBarrier.CanTouch = false
FlingBarrier.Size = Vector3.new(State.FlingRadius * 2, State.FlingRadius * 2, State.FlingRadius * 2)
FlingBarrier.Parent = Workspace

-- ============================================
-- GUI BUILDER
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CC2Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndex = 100
pcall(function() ScreenGui.Parent = gethui() end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 420)
MainFrame.Position = UDim2.new(0, 20, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(60, 60, 60)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", TitleBar).CornerRadius = UIMargin.new(0, 8, 0, 0)
local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "CC2 Hub"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
TitleLabel.Font = Enum.Font.GothamBold
TitleText = "CC2 Hub"
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Padding = UDim.new(0, 10, 0, 0)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -36, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
local CloseLabel = Instance.new("TextLabel", CloseBtn)
CloseLabel.Size = Uim2.new(1, 0, 1, 0)
CloseLabel.BackgroundTransparency = 1
CloseLabel.Text = "X"
CloseLabel.TextColor3 = Color3.new(1, 1, 1)
CloseLabel.Font = Enum.Font.GothamBold
CloseLabel.TextSize = 14

local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 30)
TabBar.Position = UDim2.new(0, 0, 1, -30)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8, 0, 0)

local TabContent = Instance.new("Frame", MainFrame)
TabContent.Size = UDim2.new(1, -4, 1, -66)
TabBar.Position = UDim2.new(0, 2, 0, 30)
TabContent.BackgroundTransparency = 1

local function clearTabContent()
    for _, child in pairs(TabContent:GetChildren()) do
        if child:IsA("ScrollingFrame") then child:Destroy() end
    end
end

local function createScrollFrame()
    local sf = Instance.new("ScrollingFrame", TabContent)
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    sf.ScrollBarThickness = 4
    return sf
end

local tabs = {}
local currentTab = nil

local function createTab(name)
    if tabs[name] then return tabs[name] end
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160, 160, 160)
    btn.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4, 4, 0)
    
    local sf = createScrollFrame()
    sf.Name = name
    sf.Visible = false
    sf.Parent = TabContent
    
    tabs[name] = {Button = btn, Frame = sf}
    
    btn.MouseButton1Click:Connect(function()
        if currentTab then
        tabs[currentTab].Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            tabs[currentTab].Frame.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        sf.Visible = true
        currentTab = name
    end)
    
    return tabs[name]
end

local function createSection(parent, name)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(140, 140, 140)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Padding = UDim.new(0, 8, 0, 0)
    lbl.Parent = parent
    parent.CanvasSize = parent.CanvasSize + UDim2.new(0, 0, 0, 26)
end

local function createToggle(parent, name, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 26)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -40, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Padding = UDim.new(0, 8, 0, 0)
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 36, 0, 20)
    btn.Position = UDim2.new(1, -40, 3, 3)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
    btn.Font = Enum.Font.GothamBold
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = default and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 150)
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Parent = frame
    
    local isOn = default
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        btn.Text = isOn and "ON" or "OFF"
        btn.BackgroundColor3 = isOn and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = isOn and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 150)
        callback(isOn)
    end)
    
    parent.CanvasSize = parent.CanvasSize + UDim2.new(0, 0, 0, 26)
    return btn
end

local function createSlider(parent, name, min, max, inc, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment = Left
    label.Padding = UDim.new(0, 8, 0, 0)
    
    local slider = Instance.new("TextBox", frame)
    slider.Size = UDim2.new(0.6, 0, 0, 22)
    slider.Position = UDim2.new(0.4, 0, 20, 0)
    slider.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    slider.Text = tostring(default)
    slider.TextColor3 = Color3.fromRGB(220, 220, 220)
    slider.Font = Enum.Font.Gotham
    slider.TextSize = 11
    slider.ClearTextOnFocus = false
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 4)
    slider.Parent = frame
    
    slider.FocusLost:Connect(function()
        local num = tonumber(slider.Text)
        if num then
            num = math.clamp(num, min, max)
            slider.Text = tostring(num)
            callback(num)
        else
            slider.Text = tostring(default)
        end
    end)
    
    slider.ReturnKeyPressed:Connect(function()
        local num = tonumber(slider.Text)
        if num then
            num = math.clamp(num, min, max)
            slider.Text = tostring(num)
            callback(num)
        end
    end)
    
    parent.CanvasSize = parent.CanvasSize + UDim2.new(0, 0, 0, 42)
    return slider
end

local function createButton(parent, name, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    btn.Parent = parent
    parent.CanvasSize = parent.CanvasSize + UDim2.new(0, 0, 0, 28)
    return btn
end

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
    State.GUI_Open = false
end)

-- Create tabs
local TabFarm = createTab("AutoFarm")
local TabVehicle = createTab("Vehicle")
local TabPvP = createTab("PvP / Fling")
TabBar.Size = UDim2.new(0, 80 * #TabBar:GetChildren(), 1, 0)
for i, child in ipairs(TabBar:GetChildren()) do
    child.Position = UDim2.new(0, (i-1) * 80, 0, 0)
end

-- ============================================
-- POPULATE TABS
-- ============================================
createToggle(TabVehicle.Frame, "Auto Max Car Stats (Permanent)", false, function(v) State.AutoMaxStats = v; if v then applyMaxStats() end end)
createButton(TabVehicle.Frame, "Max Stats (One Time)", function() applyMaxStats() end)
createToggle(TabVehicle.Frame, "Drift Mode (Extreme)", false, function(v) State.DriftMode = v; if v then applyDriftMode() else applyMaxStats() end end)
createToggle(TabVehicle.Frame, "Anti-Gravity Car (Float)", false, function(v) State.AntiGrav = v; if not v then local cm = getMyCarModel(); if cm and cm.PrimaryPart and cm.PrimaryPart:FindFirstChild("CC2_AntiGrav") then cm.PrimaryPart.CC2_AntiGrav:Destroy() end end end)
createSection(TabVehicle.Frame, "Flight & Camera")
createToggle(TabVehicle.Frame, "Vehicle Fly (W/S/Camera)", false, function(v) State.Vehicle_Fly = v end)
createSlider(TabVehicle.Frame, "Vehicle Fly Speed", 10, 500, 1, 150, function(v) State.Vehicle_Speed = v end)
createToggle(TabVehicle.Frame, "Unlock Camera (360 Look)", false, function(v) State.UnlockCam = v end)
createSection(TabVehicle.Frame, "Physics & Speed")
createToggle(TabVehicle.Frame, "Rocket Booster (Press Q) - Pure Grip", false, function(v) State.Q_Boost = v; CooldownFrame.Visible = v end)
createSlider(TabVehicle.Frame, "Rocket Boost Power", 100, 3000, 50, 600, function(v) State.Boost_Speed = v end)
createToggle(TabVehicle.Frame, "Vehicle Noclip (No Sink)", false, function(v) State.Vehicle_Noclip = v end)
createToggle(TabVehicle.Frame, "Anti-Fling (Vehicle)", false, function(v) State.AntiFling = v end)
createToggle(TabVehicle.Frame, "Left-Click Hold Pickup Car", false, function(v) State.PickupCar = v end)
createSection(TabVehicle.Frame, "Actions")
createButton(TabVehicle.Frame, "Flip Car Upright", function() local cm = getMyCarModel(); if cm and cm.PrimaryPart then local p = cm.PrimaryPart.Position; cm:PivotTo(CFrame.new(p)) end end)
createButton(TabVehicle.Frame, "Super Brakes (Instant Stop)", function() local s = getMyCarSeat(); if s then s.AssemblyLinearVelocity = Vector3.new(0,0,0); s.AssemblyAngularVelocity = Vector3.new(0,0,0) end end)

createToggle(TabFarm.Frame, "Auto-Crush (Teleport Inside Crusher)", false, function(v) State.AutoFarm = v end)
createToggle(TabFarm.Frame, "Auto-Respawn (No Cooldown)", false, function(v) State.AutoRespawn = v end)
createToggle(TabFarm.Frame, "Auto-Collect Cash", false, function(v) State.AutoCash = v end)
createToggle(TlabFarm.Frame, "Phase Walls (Nuke Room Access)", false, function(v) State.PhaseWalls = v end)
createButton(TabFarm.Frame, "Teleport to Nearest Crusher", function() local s = getMyCarSeat(); if s then local cm = s:FindFirstAncestorOfClass("Model"); local cr, _ = getClosestCrusher(); if cr and cm then local c = getCrusherCenter(cr); cm:PivotTo(CFrame.new(c + Vector3.new(0, 5, 0))) end end end)

createSection(TabPvP.Frame, "Fling Aura System")
createToggle(TabPvP.Frame, "Enable Fling Aura", false, function(v) State.FlingPvP = v; FlingBarrier.Transparency = v and 0.8 or 1 end)
createSlider(TabPvP.Frame, "Fling Radius", 10, 100, 1, 30, function(v) State.FlingRadius = v; FlingBarrier.Size = Vector3.new(v * 2, v * 2, v * 2) end)
createSlider(TabPvP.Frame, "Plink Power", 1000, 20000, 500, 5000, function(v) State.FlingPower = v end)

local TabLocal = createTab("Local")
createToggle(TabLocal.Frame, "Enable Fly (Player)", false, function(v)
    State.Fly_Enabled = v
    if v then
        RunService:BindToRenderStep("FlyLoop", 1, function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                hum.PlatformStand = true
                local d = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0,1,0) end
                hrp.AssemblyLinearVelocity = d * State.Fly_Speed
            end
        end)
    else
        pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end
end)
createSlider(TabLocal.Frame, "Player Fly Speed", 10, 500, 1, 50, function(v) State.Fly_Speed = v end)
createToggle(TabLocal.Frame, "Infinite Jump", false, function(v) State.InfJump = v end)
createToggle(TabLocal.Frame, "Player Noclip", false, function(v) State.NoClip = v end)

local TabESP = createTab("Visuals")
createToggle(TabESP.Frame, "Enable Player ESP", false, function(v) State.ESP_Enabled = v end)
createToggle(TabESP.Frame, "ESP Boxes", true, function(v) State.ESP_Box = v end)
createToggle(TabESP.Frame, "ESP Names", true, function(v) State.ESP_Name = v end)
createSection(TabESP.Frame, "Crusher ESP")
createToggle(TabESP.Frame, "Show Crusher Locations", false, function(v)
    State.CrusherESP_Enabled = v
    if v then setupCrusherESP()
    else
        for _, obj in pairs(State.CrusherESP_Objects) do
            if obj.Billboard then obj.Billboard:Destroy()
        end
        State.CrusherESP_Objects = {}
    end
end)
createSection(TabESP.Frame, "Lighting & Camera")
createToggle(TabESP.Frame, "Fullbright", false, function(v)
    if v then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1; Lighting.ClockTime = 12; Lighting.FogEnd = 100000; Lighting.GlobalShadows = true
    end
end)
createToggle(TabESP.Frame, "Enable Custom FOV", false, function(v) State.CustomFOV = v; if not v then Cam.FieldOfView = 70 end end)
createSlider(TabESP.Frame, "Camera FOV", 40, 120, 1, 70, function(v) State.FOVValue = v end)
createButton(TabESP.Frame, "Set Time to Day", function() Lighting.ClockTime = 14 end)
createButton(TabESP.Frame, "Set Time to Night", function() Lighting.ClockTime = 0 end)

local TabMisc = createTab("Misc")
createButton(TabMisc.Frame, "Unload Script", function() UnloadScript() end)

-- Select first tab
if TabFarm.Button then
    TabFarm.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TabFarm.Frame.Visible = true
    currentTab = "AutoFarm"
end

-- Open/Close with key
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        ScreenGui.Enabled = not ScreenGui.Enabled
        State.GUI_Open = ScreenGui.Enabled
    end
end)

-- ============================================
-- CORE FUNCTIONS (unchanged)
-- ============================================
local function UnloadScript()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    pcall(function() RunService:UnbindFromRenderStep("HubMainLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("VehicleFlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("CC2_FOVLoop") end)
    for _, obj in pairs(State.ESP_Objects) do
        if obj.Frame then obj.Frame:Destroy() end
    end
    State.ESP_Objects = {}
    for _, obj in pairs(State.CrusherESP_Objects) do
        if obj.Billboard then obj.Billboard:Destroy() end
    end
    State.CrusherESP_Objects = {}
    Cam.FieldOfView = 70
    FlingBarrier:Destroy()
    local carModel = workspace:FindFirstChild("CarCollection") and workspace.CarCollection:FindFirstChild(LP.Name)
    if carModel and carModel.PrimaryPart and carModel.PrimaryPart:FindFirstChild("CC2_AntiGrav") then
        carModel.PrimaryPart.CC2_AntiGrav:Destroy()
    end
    CooldownGui:Destroy()
    ScreenGui:Destroy()
end

local function getMyCarSeat()
    local char = LP.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        return hum.SeatPart
    end
    return nil
end

local function getMyCarModel()
    local seat = getMyCarSeat()
    if seat then
        return seat:FindFirstAncestorOfClass("Model")
    end
    return nil
end

local function getAllCrushers()
    local crushers = Workspace:FindFirstChild("Crushers")
    if not crushers then return {} end
    local list = {}
    for _, crusher in pairs(crushers:GetChildren()) do
        if crusher:IsA("Model") or crusher:IsA("Folder") then
            table.insert(list, crusher)
        end
    end
    return list
end

local function getCrusherCenter(crusher)
    local scripted = crusher:FindFirstChild("Scripted")
    if scripted then
        local sensor = scripted:FindFirstChild("Sensor")
        if sensor then return sensor.Position, sensor end
        local bottom = scripted:FindFirstChild("Bottom")
        if bottom and bottom:FindFirstChild("Part") then return bottom.Part.Position, bottom.Part end
        if bottom and bottom:IsA("BasePart") then return bottom.Position, bottom end
    end
    local largestPart = nil
    local largestSize = 0
    for _, part in pairs(crusher:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "Spawn" then
            local size = part.Size.X * part.Size.Y * part.Size.Z
            if size > largestSize then
                largestSize = size
                largestPart = part
            end
        end
    end
    if largestPart then return largestPart.Position, largestPart end
    return crusher:GetPivot().Position, nil
end

local function getClosestCrusher()
    local seat = getMyCarSeat()
    if not seat then return nil, nil end
    local carPos = seat.Position
    local closest = nil
    local closestPart = nil
    local dist = math.huge
    for _, crusher in pairs(getAllCrushers()) do
        local center, triggerPart = getCrusherCenter(crusher)
        if center then
            local d = (center - carPos).Magnitude
            if d < dist then
                dist = d
                closest = crusher
                closestPart = triggerPart
            end
        end
    end
    return closest, closestPart
end

local function doAutoCrush()
    local seat = getMyCarSeat()
    if not seat then return end
    local carModel = seat:FindFirstAncestorOfClass("Model")
    if not carModel then return end
    local crusher, triggerPart = getClosestCrusher()
    if not crusher then return end
    local center, part = getCrusherCenter(crusher)
    if not center then return end
    carModel:PivotTo(CFrame.new(center + Vector3.new(0, 5, 0)))
end

local function findAndClickRespawn()
    local playerGui = LP:WaitForChild("PlayerGui")
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, obj in pairs(gui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                    local match = obj.Name:lower():match("spawn") or obj.Name:lower():match("respawn")
                    if not match and obj:IsA("TextButton") then 
                        match = obj.Text:lower():match("spawn") or obj.Text:lower():match("respawn") 
                    end
                    if match then
                        pcall(function() firesignal(obj.MouseButton1Down) end)
                        pcall(function() firesignal(obj.MouseButton1Click) end)
                        pcall(function() firesignal(obj.MouseButton1Up) end)
                        pcall(function() obj.Activated:Fire() end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function applyMaxStats()
    local carCollection = workspace:FindFirstChild("CarCollection")
    if not carCollection then return end
    local carModel = carCollection:FindFirstChild(LP.Name)
    if not carModel then return end
    local configModule = carModel:FindFirstChild("Car") and carModel.Car:FindFirstChild("Body") and carModel.Car.Body:FindFirstChild("Configuration")
    if configModule then
        local success, config = pcall(require, configModule)
        if success and type(config) == "table" then
            config.TopSpeed = 400
            config.Acceleration = 80
            config.Horsepower = 1000
            config.Handling = 2.5
            config.BrakeForce = 25000
            config.DriftSlide = 1.5
        end
    end
end

local function applyDriftMode()
    local carCollection = workspace:FindFirstChild("CarCollection")
    if not carCollection then return end
    local carModel = carCollection:FindFirstChild(LP.Name)
    if not carModel then return end
    local configModule = carModel:FindFirstChild("Car") and carModel.Car:FindFirstChild("Body") and carModel.Car.Body:FindFirstChild("Configuration")
    if configModule then
        local success, config = pcall(require, configModule)
        if success and type(config) == "table" then
            config.DriftSlide = 5.0
            config.RearGripHandbrake = 5.0
            config.RearGripDrift = 5.0
            config.Handling = 2.0
        end
    end
end

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "UniversalESP"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
pcall(function() ESPGui.Parent = gethui() end)
if not ESPGui.Parent then pcall(function() ESPGui.Parent = CoreGui end) end
if not ESPGui.Parent then ESPGui.Parent = LP:WaitForChild("PlayerGui") end

local function createESP(player)
    if State.ESP_Objects[player] then return end
    local frame = Instance.new("Frame", ESPGui)
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    local box = Instance.new("Frame", frame)
    box.BackgroundTransparency = 1
    box.Visible = false
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = Color3.fromRGB(255, 50, 50)
    boxStroke.Thickness = 1.5
    local nameLbl = Instance.new("TextLabel", frame)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.AnchorPoint = Vector2.new(0.5, 1)
    nameLbl.Visible = false
    State.ESP_Objects[player] = {Frame = frame, Box = box, Name = nameLbl}
end

Players.PlayerRemoving:Connect(function(p) 
    if State.ESP_Objects[p] then 
        State.ESP_Objects[p].Frame:Destroy() 
        State.ESP_Objects[p] = nil 
    end 
end)

local function setupCrusherESP()
    for _, obj in pairs(State.CrusherESP_Objects) do
        if obj.Billboard then obj.Billboard:Destroy() end
    end
    State.CrusherESP_Objects = {}
    for _, crusher in pairs(getAllCrushers()) do
        local center, part = getCrusherCenter(crusher)
        if center then
            local attachPart = part or crusher.PrimaryPart
            if attachPart then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "CrusherESP"
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 15, 0)
                billboard.AlwaysOnTop = true
                billboard.MaxDistance = 500
                billboard.Parent = attachPart
                local label = Instance.new("TextLabel", billboard)
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = crusher.Name
                label.TextColor3 = Color3.fromRGB(0, 255, 100)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 16
                label.TextStrokeTransparency = 0.3
                State.CrusherESP_Objects[crusher] = {Billboard = billboard, Label = label}
            end
        end
    end
end

-- ============================================
-- MAIN LOOPS
-- ============================================
RunService:BindToRenderStep("HubMainLoop", Enum.RenderPriority.Camera.Value + 1, function()
    if State.ESP_Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                if not State.ESP_Objects[player] then createESP(player) end
                local obj = State.ESP_Objects[player]
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                if hrp and head then
                    local headScreen, onScreen = Cam:WorldToViewportPoint(head.Position)
                    if onScreen then
                        obj.Frame.Visible = true
                        local legScreen = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(headScreen.Y - legScreen.Y)
                        if height < 15 then height = 15 end
                        local width = height / 2
                        if State.ESP_Box then
                            obj.Box.Position = UDim2.fromOffset(headScreen.X - width/2, headScreen.Y)
                            obj.Box.Size = UDim2.fromOffset(width, height)
                            obj.Box.Visible = true
                        else obj.Box.Visible = false end
                        if State.ESP_Name then
                            obj.Name.Position = UDim2.fromOffset(headScreen.X, headScreen.Y - 15)
                            obj.Name.Text = player.Name
                            obj.Name.Visible = true
                        else obj.Name.Visible = false end
                    else obj.Frame.Visible = false end
                else obj.Frame.Visible = false end
            end
        end
    end
end)

RunService:BindToRenderStep("CC2_FOVLoop", Enum.RenderPriority.Camera.Value + 4, function()
    if State.CustomFOV then
        if Cam.FieldOfView ~= State.FOVValue then Cam.FieldOfView = State.FOVValue end
    end
end)

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.AutoFarm then
        local seat = getMyCarSeat()
        if seat then
            doAutoCrush()
            task.wait(3)
            local seat2 = getMyCarSeat()
            if not seat2 and State.AutoRespawn then
                findAndClickRespawn()
                task.wait(3)
            end
        elseif State.AutoRespawn then
            findAndClickRespawn()
            task.wait(2)
        end
    end
    
    if State.AutoRespawn and not State.AutoFarm then
        findAndClickRespawn()
        task.wait(0.5)
    end
    
    if State.AutoCash then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():match("cash") or obj.Name:lower():match("money") or obj.Name:lower():match("coin")) then
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then obj.CFrame = hrp.CFrame end
            end
        end
        task.wait(1)
    end
    
    if State.AntiFling then
        local seat = getMyCarSeat()
        if seat and seat.AssemblyLinearVelocity.Magnitude > 2000 then
            seat.AssemblyLinearVelocity = Vector3.new(0,0,0)
            seat.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
    end
    
    if State.AutoMaxStats and tick() - State.LastStatCheck > 2 then
        State.LastStatCheck = tick()
        applyMaxStats()
    end
    
    if State.DriftMode and tick() - State.LastStatCheck > 2 then
        State.LastStatCheck = tick()
        applyDriftMode()
    end
    
    if State.AntiGrav then
        local carModel = getMyCarModel()
        if carModel and carModel.PrimaryPart then
            local mass = carModel.PrimaryPart.AssemblyMass
            local forceVector = Vector3.new(0, workspace.Gravity * mass * 0.5, 0)
            if not carModel.PrimaryPart:FindFirstChild("CC2_AntiGrav") then
                local att = Instance.new("Attachment", carModel.PrimaryPart)
                att.Name = "CC2_AntiGrav"
                local vf = Instance.new("VectorForce", carModel.PrimaryPart)
                vf.Name = "CC2_AntiGrav"
                vf.Attachment0 = att
                vf.RelativeTo = Enum.ActuatorRelativeTo.World
            end
            carModel.PrimaryPart.CC2_AntiGrav.VectorForce.Force = forceVector
        end
    end
    
    if State.FlingPvP then
        local rootPart = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local carModel = getMyCarModel()
        local myPos = nil
        
        if carModel and carModel.PrimaryPart then
            myPos = carModel.PrimaryPart.Position
        elseif rootPart then
            myPos = rootPart.Position
        end
        
        if myPos then
            FlingBarrier.Position = myPos
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local targetChar = plr.Character
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetCar = workspace:FindFirstChild("CarCollection") and workspace.CarCollection:FindFirstChild(plr.Name)
                    local targetCarRoot = targetCar and targetCar.PrimaryPart
                    
                    local pos1 = targetRoot and targetRoot.Position
                    local pos2 = targetCarRoot and targetCarRoot.Position
                    
                    if pos1 and (pos1 - myPos).Magnitude <= State.FlingRadius then
                        local dir = (pos1 - myPos).Unit
                        targetRoot.AssemblyLinearVelocity = (dir + Vector3.new(0, 0.5, 0)) * State.FlingPower
                    end
                    if pos2 and (pos2 - myPos).Magnitude <= State.FlingRadius then
                        local dir = (pos2 - myPos).Unit
                        targetCarRoot.AssemblyLinearVelocity = (dir + Vector3.new(0, 0.5, 0)) * State.FlingPower
                    end
                end
            end
        end
    end
end))

-- ============================================
-- INPUT HANDLING
-- ============================================
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and State.PickupCar then
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if carModel and hrp then
                local existing = hrp:FindFirstChild("HubCarPickup")
                if existing then existing:Destroy() end
                local wc = Instance.new("WeldConstraint")
                wc.Name = "HubCarPickup"
                wc.Part0 = hrp
                wc.Part1 = carModel.PrimaryPart or seat
                wc.Parent = hrp
            end
        end
    end
    
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Q and State.Q_Boost then
        if tick() > State.Boost_Cooldown then
            State.Boost_Active = true
            State.Boost_EndTime = tick() + 1.5
            State.Boost_Cooldown = tick() + 6.5
            CooldownFrame.Visible = true
        end
    end
end)

table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local wc = hrp:FindFirstChild("HubCarPickup")
            if wc then wc:Destroy() end
        end
    end
end))

-- ============================================
-- ROCKET BOOSTER (Fixed: AssemblyLinearVelocity, no BodyVelocity)
-- ============================================
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.Boost_Active then
        if tick() < State.Boost_EndTime then
            local seat = getMyCarSeat()
            if seat then
                local carModel = seat:FindFirstAncestorOfClass("Model")
                
                if carModel and not carModel:GetAttribute("BoostGripActive") then
                    carModel:SetAttribute("BoostGripActive", true)
                    for _, part in pairs(carModel:GetDescendants()) do
                        if part:IsA("BasePart") and (part.Name:lower():match("wheel") or part.Name:lower():match("tire")) then
                            pcall(function()
                                part.CustomPhysicalProperties = PhysicalProperties.new(5.0, 1.0, 1.0)
                            end)
                        end
                    end
                end
                
                local carLook = seat.CFrame.LookVector
                local flatLook = Vector3.new(carLook.X, 0, carLook.Z)
                if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                
                local currentVel = seat.AssemblyLinearVelocity
                seat.AssemblyLinearVelocity = Vector3.new(
                    flatLook.X * State.Boost_Speed,
                    currentVel.Y,
                    flatLook.Z * State.Boost_Speed
                )
            end
        else
            State.Boost_Active = false
            local seat = getMyCarSeat()
            if seat then
                local carModel = seat:FindFirstAncestorOfClass("Model")
                if carModel and carModel:GetAttribute("BoostGripActive") then
                    carModel:SetAttribute("BoostGripActive", nil)
                    for _, part in pairs(carModel:GetDescendants()) do
                        if part:IsA("BasePart") and (part.Name:lower():match("wheel") or part.Name:lower():match("tire")) then
                            pcall(function()
                                part.CustomPhysicalProperties = nil
                            end)
                        end
                    end
                end
            end
        end
    end

    if State.Q_Boost and State.Boost_Cooldown > tick() then
        local timeLeft = math.ceil(State.Boost_Cooldown - tick())
        CooldownLabel.Text = "Cooldown: " .. tostring(timeLeft) .. "s"
        CooldownLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        CooldownFrame.Visible = true
    elseif State.Q_Boost then
        CooldownLabel.Text = "Booster Ready (Press Q)"
        CooldownLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        CooldownFrame.Visible = true
    else
        CooldownFrame.Visible = false
    end
end))

table.insert(State.Connections, RunService.Stepped:Connect(function()
    if State.Vehicle_Noclip then
        local carModel = getMyCarModel()
        if carModel then
            for _, part in pairs(carModel:GetDescendants()) do
                if part:IsA("BasePart") then 
                    part.CanCollide = false 
                    part.CanQuery = false 
                end
            end
        end
    end

    if State.PhaseWalls and LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
            end
        end
    end

    if State.NoClip and LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

-- ============================================
-- VEHICLE FLY
-- ============================================
RunService:BindToRenderStep("VehicleFlyLoop", Enum.RenderPriority.Camera.Value + 2, function()
    if State.Vehicle_Fly then
        local seat = getMyCarSeat()
        if seat then
            local bv = seat:FindFirstChild("HubVehFlyBV")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "HubVehFlyBV"
                bv.MaxForce = Vector3.new(99999, 99999, 99999)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = seat
            end
            local bg = seat:FindFirstChild("HubVehFlyBG")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "HubVehFlyBG"
                bg.MaxTorque = Vector3.new(99999, 99999, 99999)
                bg.D = 50
                bg.Parent = seat
            end
            
            local d = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
            
            if d.Magnitude > 0 then
                bv.Velocity = d.Unit * State.Vehicle_Speed
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local lookPos = seat.Position + Cam.CFrame.LookVector
                bg.CFrame = CFrame.lookAt(seat.Position, lookPos)
            end
        end
    else
        local seat = getMyCarSeat()
        if seat then
            local bv = seat:FindFirstChild("HubVehFlyBV")
            local bg = seat:FindFirstChild("HubVehFlyBG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
    end
end)

RunService:BindToRenderStep("CamUnlockLoop", Enum.RenderPriority.Camera.Value + 3, function()
    if State.UnlockCam then
        if LP.CameraMode ~= Enum.CameraMode.Classic then
            LP.CameraMode = Enum.CameraMode.Classic
        end
    end
end)

-- ============================================
-- INFINITE JUMP
-- ============================================
table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- Init
ScreenGui.Enabled = true
State.GUI_Open = true
print("[CC2 Hub] Loaded — Right Ctrl to toggle. Q for boost.")
