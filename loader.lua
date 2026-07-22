--!nocheck
-- ============================================
-- CAR CRUSHERS 2 - ADVANCED HUB
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
pcall(function() Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))() end)
if not Rayfield then
    pcall(function() Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))() end)
end
if not Rayfield then return end

-- State
local State = {}
State.ESP_Enabled = false
State.ESP_Box = true
State.ESP_Name = true
State.ESP_Objects = {}
State.AutoFarm = false
State.Fly_Enabled = false
State.Fly_Speed = 50
State.Vehicle_Fly = false
State.Vehicle_Speed = 100
State.NoClip = false
State.InfJump = false
State.Connections = {}

-- ============================================
-- UNLOAD
-- ============================================
local function UnloadScript()
    for _, conn in ipairs(State.Connections) do pcall(function() conn:Disconnect() end) end
    State.Connections = {}
    pcall(function() RunService:UnbindFromRenderStep("HubMainLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("VehicleFlyLoop") end)
    for _, obj in pairs(State.ESP_Objects) do if obj.Frame then obj.Frame:Destroy() end end
    State.ESP_Objects = {}
    Rayfield:Destroy()
end

-- ============================================
-- CC2 SPECIFIC LOGIC
-- ============================================
-- Find the car the player is currently driving
local function getMyCar()
    local char = LP.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local seat = hum.SeatPart
        local carModel = seat:FindFirstAncestorOfClass("Model")
        if carModel and carModel:FindFirstChild("Body") then
            return carModel
        end
    end
    return nil
end

-- Find the closest crusher pad to teleport to
local function getClosestCrusherPad()
    local myCar = getMyCar()
    if not myCar then return nil end
    local carPos = myCar:GetPivot().Position
    local closest = nil
    local dist = math.huge
    
    if Workspace:FindFirstChild("Crushers") then
        for _, crusher in pairs(Workspace.Crushers:GetChildren()) do
            -- Look for a part named Pad, Trigger, or DropZone inside the crusher
            local pad = crusher:FindFirstChild("Pad") or crusher:FindFirstChild("Trigger") or crusher:FindFirstChild("DropZone")
            if not pad then
                for _, desc in pairs(crusher:GetDescendants()) do
                    if desc:IsA("BasePart") and (desc.Name:lower():match("pad") or desc.Name:lower():match("trigger")) then
                        pad = desc
                        break
                    end
                end
            end
            if pad then
                local d = (pad.Position - carPos).Magnitude
                if d < dist then
                    dist = d
                    closest = pad
                end
            end
        end
    end
    return closest
end

local function doAutoFarm()
    local myCar = getMyCar()
    if myCar then
        local pad = getClosestCrusherPad()
        if pad then
            -- Teleport car to the pad
            myCar:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 5, 0)))
        end
    end
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

Players.PlayerRemoving:Connect(function(p) if State.ESP_Objects[p] then State.ESP_Objects[p].Frame:Destroy() State.ESP_Objects[p] = nil end end)

-- ============================================
-- MAIN LOOPS
-- ============================================
RunService:BindToRenderStep("HubMainLoop", Enum.RenderPriority.Camera.Value + 1, function()
    -- ESP Logic
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

-- AutoFarm Loop
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.AutoFarm then
        doAutoFarm()
        task.wait(3) -- Wait for car to crush
    end
end))

-- Vehicle Fly Loop
RunService:BindToRenderStep("VehicleFlyLoop", Enum.RenderPriority.Camera.Value + 2, function()
    if State.Vehicle_Fly then
        local car = getMyCar()
        if car and car.PrimaryPart then
            local hrp = car.PrimaryPart
            local bv = hrp:FindFirstChild("HubVehFlyBV")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "HubVehFlyBV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = hrp
            end
            local d = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
            bv.Velocity = d * State.Vehicle_Speed
        end
    else
        local car = getMyCar()
        if car and car.PrimaryPart then
            local bv = car.PrimaryPart:FindFirstChild("HubVehFlyBV")
            if bv then bv:Destroy() end
        end
    end
end)

-- ============================================
-- UI SETUP
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Car Crushers 2 - Hub",
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "Advanced Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabFarm = Window:CreateTab("AutoFarm", 4483362458)
local TabVehicle = Window:CreateTab("Vehicle", 4483362458)
local TabLocal = Window:CreateTab("Local", 4483362458)
local TabESP = Window:CreateTab("Visuals", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

-- AutoFarm Tab
TabFarm:CreateToggle({
    Name = "Auto-Crush (Teleport to Pad)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoFarm = v
        Rayfield:Notify({Title = "AutoFarm", Content = v and "Enabled. Sit in your car." or "Disabled.", Duration = 3})
    end
})

-- Vehicle Tab
TabVehicle:CreateToggle({
    Name = "Vehicle Fly (Sit in car first)",
    CurrentValue = false,
    Callback = function(v) State.Vehicle_Fly = v end
})
TabVehicle:CreateSlider({Name = "Vehicle Fly Speed", Range = {10, 500}, Increment = 1, CurrentValue = 100, Callback = function(v) State.Vehicle_Speed = v end})

-- Local Tab
TabLocal:CreateToggle({
    Name = "Enable Fly (Player)",
    CurrentValue = false,
    Callback = function(v)
        State.Fly_Enabled = v
        if v then
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
TabLocal:CreateSlider({Name = "Player Fly Speed", Range = {10, 500}, Increment = 1, CurrentValue = 50, Callback = function(v) State.Fly_Speed = v end})
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
TabESP:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")
        if v then
            Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1 Lighting.ClockTime = 12 Lighting.FogEnd = 100000 Lighting.GlobalShadows = true
        end
    end
})

-- Misc Tab
TabMisc:CreateButton({Name = "Unload Script", Callback = function() UnloadScript() end})

Rayfield:Notify({Title = "Car Crushers 2", Content = "Hub loaded! Sit in your car to use AutoFarm/Vehicle Fly.", Duration = 5})
