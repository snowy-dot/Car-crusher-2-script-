--!nocheck
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then return end

local State = {}
State.ESP_Enabled = false
State.ESP_Box = true
State.ESP_Name = true
State.Crusher_ESP = false
State.ESP_Objects = {}
State.AutoFarm = false
State.AutoRespawn = false
State.Fly_Enabled = false
State.Fly_Speed = 50
State.Vehicle_Fly = false
State.Vehicle_Speed = 150
State.Vehicle_Noclip = false
State.Speed_Boost = false
State.Boost_Amt = 300
State.Boost_EndTime = 0
State.NoClip = false
State.InfJump = false
State.UnlockCam = false
State.AntiFling = false
State.ReWeld = false
State.Connections = {}

local function UnloadScript()
    for _, conn in ipairs(State.Connections) do pcall(function() conn:Disconnect() end) end
    State.Connections = {}
    pcall(function() RunService:UnbindFromRenderStep("HubMainLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("VehicleFlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("CamUnlockLoop") end)
    for _, obj in pairs(State.ESP_Objects) do if obj.Frame then obj.Frame:Destroy() end end
    State.ESP_Objects = {}
    Cam.FieldOfView = 70
    Rayfield:Destroy()
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

local function getClosestCrusherPad()
    local seat = getMyCarSeat()
    if not seat then return nil end
    local carPos = seat.Position
    local closest = nil
    local dist = math.huge
    
    local crushers = Workspace:FindFirstChild("Crushers")
    if not crushers then return nil end
    
    for _, crusher in pairs(crushers:GetChildren()) do
        local pad = nil
        for _, desc in pairs(crusher:GetDescendants()) do
            if desc:IsA("BasePart") and (desc.Name:lower():match("pad") or desc.Name:lower():match("trigger") or desc.Name:lower():match("zone")) then
                pad = desc
                break
            end
        end
        if not pad then pad = crusher.PrimaryPart or crusher:FindFirstChildWhichIsA("BasePart") end
        if pad then
            local d = (pad.Position - carPos).Magnitude
            if d < dist then
                dist = d
                closest = pad
            end
        end
    end
    return closest
end

local function doAutoFarm()
    local seat = getMyCarSeat()
    if seat then
        local pad = getClosestCrusherPad()
        if pad then
            local targetCFrame = CFrame.new(pad.Position + Vector3.new(0, 5, 0))
            seat.CFrame = targetCFrame
            local carModel = seat:FindFirstAncestorOfClass("Model")
            if carModel and carModel.PrimaryPart then
                carModel:PivotTo(targetCFrame)
            end
        end
    end
end

local function findAndClickRespawn()
    local playerGui = LP:WaitForChild("PlayerGui")
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, obj in pairs(gui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible and obj.Active then
                    local match = obj.Name:lower():match("spawn") or obj.Name:lower():match("respawn")
                    if not match and obj:IsA("TextButton") then match = obj.Text:lower():match("spawn") or obj.Text:lower():match("respawn") end
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

-- ============================================
-- ESP SYSTEM (Players + Crushers)
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

local function drawCrusherESP()
    local crushers = Workspace:FindFirstChild("Crushers")
    if not crushers then return end
    for _, crusher in pairs(crushers:GetChildren()) do
        if not State.ESP_Objects[crusher] then
            local pad = crusher.PrimaryPart or crusher:FindFirstChildWhichIsA("BasePart")
            if pad then
                local frame = Instance.new("Frame", ESPGui)
                frame.BackgroundTransparency = 1
                frame.Size = UDim2.new(1, 0, 1, 0)
                local box = Instance.new("Frame", frame)
                box.BackgroundTransparency = 1
                box.Visible = false
                local boxStroke = Instance.new("UIStroke", box)
                boxStroke.Color = Color3.fromRGB(255, 255, 0)
                boxStroke.Thickness = 2
                local nameLbl = Instance.new("TextLabel", frame)
                nameLbl.BackgroundTransparency = 1
                nameLbl.TextColor3 = Color3.new(1, 1, 0)
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 14
                nameLbl.TextStrokeTransparency = 0.5
                nameLbl.AnchorPoint = Vector2.new(0.5, 1)
                nameLbl.Visible = false
                State.ESP_Objects[crusher] = {Frame = frame, Box = box, Name = nameLbl, Pad = pad}
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

    if State.Crusher_ESP then
        drawCrusherESP()
        for objName, obj in pairs(State.ESP_Objects) do
            if typeof(objName) == "Instance" and objName:IsA("Model") then
                if objName.Parent then
                    local pad = obj.Pad
                    if pad and pad.Parent then
                        local screenPos, onScreen = Cam:WorldToViewportPoint(pad.Position)
                        if onScreen then
                            obj.Frame.Visible = true
                            obj.Box.Position = UDim2.fromOffset(screenPos.X - 15, screenPos.Y - 15)
                            obj.Box.Size = UDim2.fromOffset(30, 30)
                            obj.Box.Visible = true
                            obj.Name.Position = UDim2.fromOffset(screenPos.X, screenPos.Y - 20)
                            obj.Name.Text = objName.Name
                            obj.Name.Visible = true
                        else
                            obj.Frame.Visible = false
                        end
                    else
                        obj.Frame:Destroy()
                        State.ESP_Objects[objName] = nil
                    end
                end
            end
        end
    end
end)

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.AutoFarm then
        doAutoFarm()
        task.wait(3) 
    end
    if State.AutoRespawn then
        findAndClickRespawn()
        task.wait(0.5)
    end
    if State.AntiFling then
        local seat = getMyCarSeat()
        if seat and seat.AssemblyLinearVelocity.Magnitude > 2000 then
            seat.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end
    if State.ReWeld then
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            if carModel then
                for _, p in pairs(carModel:GetDescendants()) do
                    if p:IsA("Weld") or p:IsA("WeldConstraint") or p:IsA("Motor6D") then
                        p.Enabled = true
                    end
                end
            end
        end
    end
end))

-- Speed Boost (Fixed: Uses Camera LookVector to avoid backward boosting, preserves gravity)
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W and State.Speed_Boost then
        State.Boost_EndTime = tick() + 1.5
    end
end))

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.Speed_Boost and tick() < State.Boost_EndTime then
        local seat = getMyCarSeat()
        if seat then
            -- Use Camera LookVector projected on X/Z plane to avoid backward issues
            local camLook = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
            if camLook.Magnitude > 0 then camLook = camLook.Unit end
            local currentVel = seat.AssemblyLinearVelocity
            seat.AssemblyLinearVelocity = Vector3.new(camLook.X * State.Boost_Amt, currentVel.Y, camLook.Z * State.Boost_Amt)
        end
    end
end))

-- Vehicle Noclip Loop
table.insert(State.Connections, RunService.Stepped:Connect(function()
    if State.Vehicle_Noclip then
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            if carModel then
                for _, part in pairs(carModel:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end
end))

-- Vehicle Fly Loop (Fixed: Uses AssemblyLinearVelocity for true flight)
RunService:BindToRenderStep("VehicleFlyLoop", Enum.RenderPriority.Camera.Value + 2, function()
    if State.Vehicle_Fly then
        local seat = getMyCarSeat()
        if seat then
            local d = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
            
            if d.Magnitude > 0 then
                seat.AssemblyLinearVelocity = d.Unit * State.Vehicle_Speed
            else
                -- Freeze in air to prevent drifting
                seat.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end))

-- Camera Unlock Loop
RunService:BindToRenderStep("CamUnlockLoop", Enum.RenderPriority.Camera.Value + 3, function()
    if State.UnlockCam then
        if LP.CameraMode ~= Enum.CameraMode.Classic then
            LP.CameraMode = Enum.CameraMode.Classic
        end
    end
end)

-- ============================================
-- UI SETUP
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Car Crushers 2 - Hub",
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "Advanced Physics Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabFarm = Window:CreateTab("AutoFarm", 4483362458)
local TabVehicle = Window:CreateTab("Vehicle", 4483362458)
local TabLocal = Window:CreateTab("Local", 4483362458)
local TabESP = Window:CreateTab("Visuals", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

-- AutoFarm Tab
TabFarm:CreateToggle({Name = "Auto-Crush (Teleport to Pad)", CurrentValue = false, Callback = function(v) State.AutoFarm = v end})
TabFarm:CreateToggle({Name = "Auto-Respawn (No Cooldown)", CurrentValue = false, Callback = function(v) State.AutoRespawn = v end})

-- Vehicle Tab
TabVehicle:CreateToggle({Name = "Vehicle Fly (Sit in car first)", CurrentValue = false, Callback = function(v) State.Vehicle_Fly = v end})
TabVehicle:CreateSlider({Name = "Vehicle Fly Speed", Range = {10, 500}, Increment = 1, CurrentValue = 150, Callback = function(v) State.Vehicle_Speed = v end})

TabVehicle:CreateSection("Physics & Speed")
TabVehicle:CreateToggle({Name = "Burst Boost (Press W)", CurrentValue = false, Callback = function(v) State.Speed_Boost = v end})
TabVehicle:CreateSlider({Name = "Boost Power", Range = {50, 2000}, Increment = 10, CurrentValue = 300, Callback = function(v) State.Boost_Amt = v end})
TabVehicle:CreateToggle({Name = "Vehicle Noclip", CurrentValue = false, Callback = function(v) State.Vehicle_Noclip = v end})
TabVehicle:CreateToggle({Name = "Anti-Fling (Vehicle)", CurrentValue = false, Callback = function(v) State.AntiFling = v end})
TabVehicle:CreateToggle({Name = "Re-Weld (Anti-Crush)", CurrentValue = false, Callback = function(v) State.ReWeld = v end})
TabVehicle:CreateToggle({Name = "Unlock Camera (360 Look)", CurrentValue = false, Callback = function(v) State.UnlockCam = v end})

TabVehicle:CreateSection("Vehicle Mass (Gravity Manip)")
TabVehicle:CreateButton({
    Name = "Feather Mode (Floaty)",
    Callback = function()
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            local mass = 0
            for _, p in pairs(carModel:GetDescendants()) do
                if p:IsA("BasePart") then mass = mass + p.AssemblyMass end
            end
            local bf = seat:FindFirstChild("HubFeatherForce")
            if not bf then
                bf = Instance.new("BodyForce")
                bf.Name = "HubFeatherForce"
                bf.Parent = seat
            end
            -- Counteract 90% of gravity to make it floaty without breaking suspension
            bf.Force = Vector3.new(0, mass * Workspace.Gravity * 0.9, 0)
            local tankBf = seat:FindFirstChild("HubTankForce")
            if tankBf then tankBf:Destroy() end
            Rayfield:Notify({Title = "Mass", Content = "Car is now floaty!", Duration = 2})
        end
    end
})
TabVehicle:CreateButton({
    Name = "Tank Mode (Heavy Downforce)",
    Callback = function()
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            local mass = 0
            for _, p in pairs(carModel:GetDescendants()) do
                if p:IsA("BasePart") then mass = mass + p.AssemblyMass end
            end
            local bf = seat:FindFirstChild("HubTankForce")
            if not bf then
                bf = Instance.new("BodyForce")
                bf.Name = "HubTankForce"
                bf.Parent = seat
            end
            -- Push down with 2x gravity
            bf.Force = Vector3.new(0, -mass * Workspace.Gravity * 2, 0)
            local featherBf = seat:FindFirstChild("HubFeatherForce")
            if featherBf then featherBf:Destroy() end
            Rayfield:Notify({Title = "Mass", Content = "Car is now heavy!", Duration = 2})
        end
    end
})
TabVehicle:CreateButton({
    Name = "Reset Vehicle Mass",
    Callback = function()
        local seat = getMyCarSeat()
        if seat then
            local f1 = seat:FindFirstChild("HubFeatherForce")
            local f2 = seat:FindFirstChild("HubTankForce")
            if f1 then f1:Destroy() end
            if f2 then f2:Destroy() end
            Rayfield:Notify({Title = "Mass", Content = "Vehicle mass reset.", Duration = 2})
        end
    end
})

TabVehicle:CreateSection("Actions")
TabVehicle:CreateButton({
    Name = "Self Destruct (Break Car)",
    Callback = function()
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            if carModel then
                for _, p in pairs(carModel:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p:BreakJoints()
                        p.Anchored = false
                    end
                end
            end
        end
    end
})

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
TabLocal:CreateToggle({Name = "Player Noclip", CurrentValue = false, Callback = function(v) State.NoClip = v end})

table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(State.Connections, RunService.Stepped:Connect(function()
    if State.NoClip and LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))

-- Visuals Tab
TabESP:CreateToggle({Name = "Enable Player ESP", CurrentValue = false, Callback = function(v) State.ESP_Enabled = v end})
TabESP:CreateToggle({Name = "Enable Crusher ESP", CurrentValue = false, Callback = function(v) State.Crusher_ESP = v end})
TabESP:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) State.ESP_Box = v end})
TabESP:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(v) State.ESP_Name = v end})
TabESP:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
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
TabESP:CreateSlider({Name = "Camera FOV", Range = {40, 120}, Increment = 1, CurrentValue = 70, Callback = function(v) Cam.FieldOfView = v end})
TabESP:CreateButton({Name = "Set Time to Day", Callback = function() Lighting.ClockTime = 14 end})
TabESP:CreateButton({Name = "Set Time to Night", Callback = function() Lighting.ClockTime = 0 end})

-- Misc Tab
TabMisc:CreateButton({Name = "Unload Script", Callback = function() UnloadScript() end})

Rayfield:Notify({Title = "Car Crushers 2", Content = "Hub loaded! Sit in your car to use features.", Duration = 5})
