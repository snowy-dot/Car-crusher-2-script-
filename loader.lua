--!nocheck
-- ============================================
-- CAR CRUSHERS 2 - TESTING & AUTOFARM HUB
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- Load Rayfield
local Rayfield = nil
pcall(function()
    local response = game:HttpGet('https://sirius.menu/rayfield')
    local func = loadstring(response)
    if func then
        Rayfield = func()
    end
end)

if not Rayfield then
    pcall(function()
        local response = game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua')
        local func = loadstring(response)
        if func then
            Rayfield = func()
        end
    end)
end

if not Rayfield then
    print("Rayfield failed to load")
    return
end

-- State
local State = {}
State.ESP_Enabled = false
State.ESP_Box = true
State.ESP_Name = true
State.ESP_Tracers = false
State.ESP_Objects = {}
State.AutoFarm = false
State.Fly_Enabled = false
State.Fly_Speed = 50
State.NoClip = false
State.InfJump = false
State.Connections = {}

-- ============================================
-- UNLOAD / DEAD SWITCH
-- ============================================
local function UnloadScript()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    
    pcall(function() RunService:UnbindFromRenderStep("HubMainLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
    
    for _, obj in pairs(State.ESP_Objects) do
        if obj.Frame then obj.Frame:Destroy() end
    end
    State.ESP_Objects = {}
    
    Rayfield:Destroy()
end

-- ============================================
-- ESP SYSTEM
-- ============================================
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
    
    local tracer = Instance.new("Frame", frame)
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Size = UDim2.new(0, 1, 0, 1)
    tracer.Visible = false
    
    local nameLbl = Instance.new("TextLabel", frame)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.AnchorPoint = Vector2.new(0.5, 1)
    nameLbl.Visible = false
    
    State.ESP_Objects[player] = {Frame = frame, Box = box, Tracer = tracer, Name = nameLbl, BoxStroke = boxStroke}
end

local function removeESP(player)
    if State.ESP_Objects[player] then
        State.ESP_Objects[player].Frame:Destroy()
        State.ESP_Objects[player] = nil
    end
end

Players.PlayerRemoving:Connect(removeESP)

-- ============================================
-- AUTO-FARM SYSTEM (Teleports car to crusher)
-- ============================================
local function getClosestCrusherPad()
    local closestPad = nil
    local shortestDist = math.huge
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

    -- Search for pads in the workspace (usually grouped under a Crushers folder or similar)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():match("pad") or obj.Name:lower():match("trigger") or obj.Name:lower():match("zone")) then
            local dist = (obj.Position - myHrp.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestPad = obj
            end
        end
    end
    return closestPad
end

local function doAutoFarm()
    if not LP.Character then return end
    local myHrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    -- Find the vehicle the player is currently in or near
    local myCar = nil
    if Workspace:FindFirstChild("CarCollection") then
        for _, carModel in pairs(Workspace.CarCollection:GetChildren()) do
            if carModel:FindFirstChild("Configuration") or carModel:FindFirstChild("Body") then
                local dist = (carModel:GetPivot().Position - myHrp.Position).Magnitude
                if dist < 30 then -- Only grab car if close to it
                    myCar = carModel
                    break
                end
            end
        end
    end

    if myCar then
        local pad = getClosestCrusherPad()
        if pad then
            -- Teleport car to pad
            myCar:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 5, 0)))
            -- Teleport player into seat
            myHrp.CFrame = myCar:GetPivot() * CFrame.new(0, 3, -5)
        end
    end
end

-- ============================================
-- MAIN RENDER LOOP
-- ============================================
RunService:BindToRenderStep("HubMainLoop", Enum.RenderPriority.Camera.Value + 1, function()
    -- ESP Logic
    if not State.ESP_Enabled then return end
    
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
                    
                    if State.ESP_Tracers then
                        local p1 = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                        local p2 = Vector2.new(headScreen.X, headScreen.Y)
                        local dist = (p2 - p1).Magnitude
                        local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
                        obj.Tracer.Position = UDim2.fromOffset((p1.X + p2.X)/2, (p1.Y + p2.Y)/2)
                        obj.Tracer.Size = UDim2.fromOffset(dist, 1)
                        obj.Tracer.Rotation = math.deg(angle)
                        obj.Tracer.Visible = true
                    else obj.Tracer.Visible = false end
                else
                    obj.Frame.Visible = false
                end
            else
                obj.Frame.Visible = false
            end
        end
    end
end)

-- Background Loop for AutoFarm
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.AutoFarm then
        doAutoFarm()
        task.wait(2) -- Wait for car to settle and crush
    end
end))

-- ============================================
-- UI SETUP
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Car Crushers 2 - Hub",
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "by Rayfield",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabLocal = Window:CreateTab("Local", 4483362458)
local TabESP = Window:CreateTab("Visuals", 4483362458)
local TabFarm = Window:CreateTab("AutoFarm", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

-- Local Tab
TabLocal:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Callback = function(Value)
        State.Fly_Enabled = Value
        if Value then
            RunService:BindToRenderStep("FlyLoop", 1, function()
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    hum.PlatformStand = true
                    local d = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
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
    end
})
TabLocal:CreateSlider({Name = "Fly Speed", Range = {10, 500}, Increment = 1, CurrentValue = 50, Callback = function(v) State.Fly_Speed = v end})
TabLocal:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Callback = function(v) State.InfJump = v end})
TabLocal:CreateToggle({Name = "Noclip", CurrentValue = false, Callback = function(v) State.NoClip = v end})

table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.NoClip and LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))

-- Visuals Tab
TabESP:CreateToggle({Name = "Enable Player ESP", CurrentValue = false, Callback = function(v) State.ESP_Enabled = v end})
TabESP:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) State.ESP_Box = v end})
TabESP:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(v) State.ESP_Name = v end})
TabESP:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) State.ESP_Tracers = v end})
TabESP:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
        end
    end
})

-- AutoFarm Tab
TabFarm:CreateToggle({
    Name = "Auto-Crush (Teleport to Pad)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoFarm = v
        Rayfield:Notify({Title = "AutoFarm", Content = v and "Enabled. Stand near your car." or "Disabled.", Duration = 3})
    end
})

-- Misc Tab
TabMisc:CreateButton({Name = "Unload Script", Callback = function() UnloadScript() end})

Rayfield:Notify({Title = "Car Crushers 2", Content = "Hub loaded successfully! Press RightCtrl to toggle UI.", Duration = 3})
