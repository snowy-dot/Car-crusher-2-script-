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
State.ESP_Objects = {}
State.CrusherESP_Enabled = false
State.CrusherESP_Objects = {}
State.AutoFarm = false
State.AutoRespawn = false
State.PhaseWalls = false
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

-- CC2 Specific States
State.AntiGrav = false
State.CustomFOV = false
State.FOVValue = 70
State.AutoMaxStats = false
State.DriftMode = false
State.LastStatCheck = 0

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
local ConerRadius = Instance.new("UICorner", CooldownFrame)
local CooldownLabel = Instance.new("TextLabel", CooldownFrame)
CooldownLabel.Size = UDim2.new(1, 0, 1, 0)
CooldownLabel.BackgroundTransparency = 1
CooldownLabel.Text = "Booster Ready"
CooldownLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
CooldownLabel.Font = Enum.Font.GothamBold
CooldownLabel.TextSize = 18
CooldownFrame.Visible = false

local function UnloadScript()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    pcall(function() RunService:UnbindFromRenderStep("HubMainLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("VehicleFlyLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("CamUnlockLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("CC2_FOVLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("CrusherESPLoop") end)
    
    for _, obj in pairs(State.ESP_Objects) do
        if obj.Frame then obj.Frame:Destroy() end
    end
    State.ESP_Objects = {}
    
    for _, obj in pairs(State.CrusherESP_Objects) do
        if obj.Billboard then obj.Billboard:Destroy() end
    end
    State.CrusherESP_Objects = {}
    
    Cam.FieldOfView = 70
    
    local carModel = workspace:FindFirstChild("CarCollection") and workspace.CarCollection:FindFirstChild(LP.Name)
    if carModel and carModel.PrimaryPart and carModel.PrimaryPart:FindFirstChild("CC2_AntiGrav") then
        carModel.PrimaryPart.CC2_AntiGrav:Destroy()
    end
    
    CooldownGui:Destroy()
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

local function getMyCarModel()
    local seat = getMyCarSeat()
    if seat then
        return seat:FindFirstAncestorOfClass("Model")
    end
    return nil
end

-- ============================================
-- CRUSHER DETECTION (From decompiled CrusherSignals)
-- ============================================
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
    -- Try to find specific trigger parts from decompiled code
    local scripted = crusher:FindFirstChild("Scripted")
    if scripted then
        -- From CrusherSignals: Sensor, Bottom, Spikes are trigger parts
        local sensor = scripted:FindFirstChild("Sensor")
        if sensor then return sensor.Position, sensor end
        
        local bottom = scripted:FindFirstChild("Bottom")
        if bottom and bottom:FindFirstChild("Part") then return bottom.Part.Position, bottom.Part end
        
        local bottomPart = scripted:FindFirstChild("Bottom")
        if bottomPart and bottomPart:IsA("BasePart") then return bottomPart.Position, bottomPart end
    end
    
    -- Fallback: find the largest part in the crusher (likely the crush zone)
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

-- ============================================
-- AUTO CRUSH (Fixed: Teleport inside crusher)
-- ============================================
local function doAutoCrush()
    local seat = getMyCarSeat()
    if not seat then return end
    
    local carModel = seat:FindFirstAncestorOfClass("Model")
    if not carModel then return end
    
    local crusher, triggerPart = getClosestCrusher()
    if not crusher then return end
    
    local center, part = getCrusherCenter(crusher)
    if not center then return end
    
    -- Teleport car INSIDE the crusher (slightly above center to fall into it)
    local targetPos = center + Vector3.new(0, 5, 0)
    carModel:PivotTo(CFrame.new(targetPos))
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

-- ============================================
-- AUTO MAX STATS (Fixed: Re-applies every 2 seconds)
-- ============================================
local function applyMaxStats()
    local carCollection = workspace:FindFirstChild("CarCollection")
    if not carCollection then return end
    
    local carModel = carCollection:FindFirstChild(LP.Name)
    if not carModel then return end
    
    local configModule = carModel:FindFirstChild("Car") 
        and carModel.Car:FindFirstChild("Body") 
        and carModel.Car.Body:FindFirstChild("Configuration")
    
    if configModule then
        local success, config = pcall(require, configModule)
        if success and type(config) == "table" then
            -- Exact variables from decompiled Configuration module
            config.TopSpeed = 500
            config.Acceleration = 100
            config.Horsepower = 1000
            config.Handling = 5.0
            config.BrakeForce = 50000
            config.DriftSlide = 2.0
            config.SusStiffness = 1.5
            config.SusDamping = 3000
        end
    end
end

local function applyDriftMode()
    local carCollection = workspace:FindFirstChild("CarCollection")
    if not carCollection then return end
    
    local carModel = carCollection:FindFirstChild(LP.Name)
    if not carModel then return end
    
    local configModule = carModel:FindFirstChild("Car") 
        and carModel.Car:FindFirstChild("Body") 
        and carModel.Car.Body:FindFirstChild("Configuration")
    
    if configModule then
        local success, config = pcall(require, configModule)
        if success and type(config) == "table" then
            -- Extreme drift values from decompiled variables
            config.DriftSlide = 5.0
            config.RearGripHandbrake = 5.0
            config.RearGripDrift = 5.0
            config.Handling = 3.0
        end
    end
end

-- ============================================
-- ESP SYSTEMS
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

Players.PlayerRemoving:Connect(function(p) 
    if State.ESP_Objects[p] then 
        State.ESP_Objects[p].Frame:Destroy() 
        State.ESP_Objects[p] = nil 
    end 
end)

-- Crusher ESP System
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
    -- Player ESP
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
                        else 
                            obj.Box.Visible = false 
                        end
                        if State.ESP_Name then
                            obj.Name.Position = UDim2.fromOffset(headScreen.X, headScreen.Y - 15)
                            obj.Name.Text = player.Name
                            obj.Name.Visible = true
                        else 
                            obj.Name.Visible = false 
                        end
                    else 
                        obj.Frame.Visible = false 
                    end
                else 
                    obj.Frame.Visible = false 
                end
            end
        end
    end
end)

-- CC2 Custom FOV Override Loop
RunService:BindToRenderStep("CC2_FOVLoop", Enum.RenderPriority.Camera.Value + 4, function()
    if State.CustomFOV then
        if Cam.FieldOfView ~= State.FOVValue then
            Cam.FieldOfView = State.FOVValue
        end
    end
end)

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    -- Auto Farm (Fixed: proper crusher teleport + crush cycle)
    if State.AutoFarm then
        local seat = getMyCarSeat()
        if seat then
            -- Teleport into crusher
            doAutoCrush()
            task.wait(3)
            
            -- Check if still in car (car might be crushed)
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
                if hrp then
                    obj.CFrame = hrp.CFrame
                end
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
    
    -- Auto Max Stats (Fixed: re-applies every 2 seconds)
    if State.AutoMaxStats and tick() - State.LastStatCheck > 2 then
        State.LastStatCheck = tick()
        applyMaxStats()
    end
    
    -- Drift Mode
    if State.DriftMode and tick() - State.LastStatCheck > 2 then
        State.LastStatCheck = tick()
        applyDriftMode()
    end
    
    -- Anti-Gravity
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
end))

-- ============================================
-- INPUT HANDLING (Fixed: Pickup Car works before gpe check)
-- ============================================
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    -- Pickup Car: MUST be before gpe check so it works while in car
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
end))

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
-- ROCKET BOOSTER (Fixed: Full control at all speeds)
-- ============================================
table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if State.Boost_Active then
        if tick() < State.Boost_EndTime then
            local seat = getMyCarSeat()
            if seat then
                -- BodyVelocity for forward movement
                local bv = seat:FindFirstChild("HubBoostBV")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "HubBoostBV"
                    bv.MaxForce = Vector3.new(99999, 0, 99999)
                    bv.Velocity = Vector3.new(0,0,0)
                    bv.Parent = seat
                end
                
                -- FIX 1: BodyAngularVelocity to STOP ALL SPINNING
                local bav = seat:FindFirstChild("HubBoostBAV")
                if not bav then
                    bav = Instance.new("BodyAngularVelocity")
                    bav.Name = "HubBoostBAV"
                    bav.MaxTorque = Vector3.new(99999, 99999, 99999)
                    bav.AngularVelocity = Vector3.new(0, 0, 0)
                    bav.Parent = seat
                end
                
                -- FIX 2: BodyGyro to lock car facing camera direction
                local bg = seat:FindFirstChild("HubBoostBG")
                if not bg then
                    bg = Instance.new("BodyGyro")
                    bg.Name = "HubBoostBG"
                    bg.MaxTorque = Vector3.new(99999, 99999, 99999)
                    bg.D = 100
                    bg.Parent = seat
                end
                
                -- Get camera look direction (horizontal only)
                local camLook = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
                if camLook.Magnitude > 0 then camLook = camLook.Unit end
                
                -- Lock car to face camera direction
                bg.CFrame = CFrame.lookAt(seat.Position, seat.Position + camLook)
                
                -- Apply velocity in camera direction (keep current Y velocity for gravity)
                bv.Velocity = Vector3.new(
                    camLook.X * State.Boost_Speed, 
                    seat.AssemblyLinearVelocity.Y, 
                    camLook.Z * State.Boost_Speed
                )
            end
        else
            State.Boost_Active = false
            local seat = getMyCarSeat()
            if seat then
                local bv = seat:FindFirstChild("HubBoostBV")
                local bav = seat:FindFirstChild("HubBoostBAV")
                local bg = seat:FindFirstChild("HubBoostBG")
                if bv then bv:Destroy() end
                if bav then bav:Destroy() end
                if bg then bg:Destroy() end
            end
        end
    end

    -- Cooldown UI
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

-- ============================================
-- NOCLIP & PHASE WALLS
-- ============================================
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
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.new(0, 1, 0) end
            
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
-- UI CREATION
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Car Crushers 2 - Hub",
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "Decompiled Code Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabFarm = Window:CreateTab("AutoFarm", 4483362458)
local TabVehicle = Window:CreateTab("Vehicle", 4483362458)
local TabLocal = Window:CreateTab("Local", 4483362458)
local TabESP = Window:CreateTab("Visuals", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

-- ============================================
-- AUTOFARM TAB
-- ============================================
TabFarm:CreateToggle({
    Name = "Auto-Crush (Teleport Inside Crusher)",
    CurrentValue = false, 
    Callback = function(v) State.AutoFarm = v end
})
TabFarm:CreateToggle({
    Name = "Auto-Respawn (No Cooldown)", 
    CurrentValue = false, 
    Callback = function(v) State.AutoRespawn = v end
})
TabFarm:CreateToggle({
    Name = "Auto-Collect Cash", 
    CurrentValue = false, 
    Callback = function(v) State.AutoCash = v end
})
TabFarm:CreateToggle({
    Name = "Phase Walls (Nuke Room Access)", 
    CurrentValue = false, 
    Callback = function(v) State.PhaseWalls = v end
})
TabFarm:CreateButton({
    Name = "Teleport to Nearest Crusher", 
    Callback = function()
        local seat = getMyCarSeat()
        if seat then
            local carModel = seat:FindFirstAncestorOfClass("Model")
            local crusher, trigger = getClosestCrusher()
            if crusher and carModel then
                local center = getCrusherCenter(crusher)
                carModel:PivotTo(CFrame.new(center + Vector3.new(0, 5, 0)))
                Rayfield:Notify({Title = "Teleport", Content = "Teleported to " .. crusher.Name, Duration = 3})
            end
        end
    end
})

-- ============================================
-- VEHICLE TAB
-- ============================================
TabVehicle:CreateSection("Car Crushers 2 Mods")

-- FIX 3: Auto Max Stats (toggle that re-applies every 2 seconds)
TabVehicle:CreateToggle({
   Name = "Auto Max Car Stats (Permanent)",
   CurrentValue = false,
   Callback = function(v)
       State.AutoMaxStats = v
       if v then
           applyMaxStats()
           Rayfield:Notify({Title = "Stats", Content = "Auto max stats enabled! Will re-apply on respawn.", Duration = 3})
       end
   end
})

TabVehicle:CreateButton({
   Name = "Max Stats (One Time)",
   Callback = function()
       applyMaxStats()
       Rayfield:Notify({Title = "Stats", Content = "Stats maxed for current car!", Duration = 3})
   end
})

TabVehicle:CreateToggle({
   Name = "Drift Mode (Extreme)",
   CurrentValue = false,
   Callback = function(v)
       State.DriftMode = v
       if v then applyDriftMode() end
   end
})

TabVehicle:CreateToggle({
   Name = "Anti-Gravity Car (Float)",
   CurrentValue = false,
   Callback = function(Value)
       State.AntiGrav = Value
       if not Value then
           local carModel = getMyCarModel()
           if carModel and carModel.PrimaryPart and carModel.PrimaryPart:FindFirstChild("CC2_AntiGrav") then
               carModel.PrimaryPart.CC2_AntiGrav:Destroy()
           end
       end
   end
})

TabVehicle:CreateSection("Flight & Camera")
TabVehicle:CreateToggle({Name = "Vehicle Fly (Right-Click to Steer)", CurrentValue = false, Callback = function(v) State.Vehicle_Fly = v end})
TabVehicle:CreateSlider({Name = "Vehicle Fly Speed", Range = {10, 500}, Increment = 1, CurrentValue = 150, Callback = function(v) State.Vehicle_Speed = v end})
TabVehicle:CreateToggle({Name = "Unlock Camera (360 Look)", CurrentValue = false, Callback = function(v) State.UnlockCam = v end})

TabVehicle:CreateSection("Physics & Speed")
TabVehicle:CreateToggle({
    Name = "Rocket Booster (Press Q) - Stabilized", 
    CurrentValue = false, 
    Callback = function(v) 
        State.Q_Boost = v 
        CooldownFrame.Visible = v
    end
})
TabVehicle:CreateSlider({Name = "Rocket Boost Power", Range = {100, 3000}, Increment = 50, CurrentValue = 600, Callback = function(v) State.Boost_Speed = v end})
TabVehicle:CreateToggle({Name = "Vehicle Noclip (No Sink)", CurrentValue = false, Callback = function(v) State.Vehicle_Noclip = v end})
TabVehicle:CreateToggle({Name = "Anti-Fling (Vehicle)", CurrentValue = false, Callback = function(v) State.AntiFling = v end})

-- FIX 2: Pickup Car (moved before gpe check in input handler)
TabVehicle:CreateToggle({Name = "Left-Click Hold Pickup Car", CurrentValue = false, Callback = function(v) State.PickupCar = v end})

TabVehicle:CreateSection("Actions")
TabVehicle:CreateButton({
    Name = "Flip Car Upright",
    Callback = function()
        local carModel = getMyCarModel()
        if carModel and carModel.PrimaryPart then
            local pos = carModel.PrimaryPart.Position
            carModel:PivotTo(CFrame.new(pos))
        end
    end
})
TabVehicle:CreateButton({
    Name = "Super Brakes (Instant Stop)",
    Callback = function()
        local seat = getMyCarSeat()
        if seat then
            seat.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            seat.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
})

-- ============================================
-- LOCAL TAB
-- ============================================
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

-- ============================================
-- VISUALS TAB
-- ============================================
TabESP:CreateToggle({Name = "Enable Player ESP", CurrentValue = false, Callback = function(v) State.ESP_Enabled = v end})
TabESP:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) State.ESP_Box = v end})
TabESP:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(v) State.ESP_Name = v end})

TabESP:CreateSection("Crusher ESP")
TabESP:CreateToggle({
    Name = "Show Crusher Locations",
    CurrentValue = false,
    Callback = function(v)
        State.CrusherESP_Enabled = v
        if v then
            setupCrusherESP()
        else
            for _, obj in pairs(State.CrusherESP_Objects) do
                if obj.Billboard then obj.Billboard:Destroy() end
            end
            State.CrusherESP_Objects = {}
        end
    end
})

TabESP:CreateSection("Lighting")
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

TabESP:CreateSection("Camera")
TabESP:CreateToggle({
    Name = "Enable Custom FOV (Override Game)",
    CurrentValue = false,
    Callback = function(v)
        State.CustomFOV = v
        if not v then Cam.FieldOfView = 70 end
    end
})
TabESP:CreateSlider({Name = "Camera FOV", Range = {40, 120}, Increment = 1, CurrentValue = 70, Callback = function(v) State.FOVValue = v end})

TabESP:CreateButton({Name = "Set Time to Day", Callback = function() Lighting.ClockTime = 14 end})
TabESP:CreateButton({Name = "Set Time to Night", Callback = function() Lighting.ClockTime = 0 end})

-- ============================================
-- MISC TAB
-- ============================================
TabMisc:CreateButton({Name = "Unload Script", Callback = function() UnloadScript() end})

Rayfield:Notify({Title = "Car Crushers 2", Content = "Hub loaded! Sit in your car to use features.", Duration = 5})
