local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "🔮 | Arcana",
    Subtitle = "Univεrsal v1.0.0",
    Size = UDim2.fromOffset(700, 500),
    DragStyle = 2,
    DisabledWindowControls = {ShowUserInfo},
    ShowUserInfo = false,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = false,
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Main configuration
local config = {
    Aimbot = {
        Enabled = false,
        Keybind = Enum.KeyCode.Q,
        Sticky = false,
        Smoothness = {
            Enabled = false,
            Value = 10
        },
        Prediction = {
            Enabled = false,
            X = 0.1,
            Y = 0.1
        },
        FOV = {
            Enabled = false,
            Value = 100,
            Circle = nil
        },
        Part = "Head",
        Method = "Camera",
        CurrentTarget = nil,
        LockedOnto = nil,
        Checks = {
            Team = false,
            Health = true,
            Knock = true,
            Invisible = true,
            Wall = true
        },
        Humanization = {
            Jitter = {
                Enabled = false,
                Intensity = 5,
                Speed = 2,
                RandomFactor = 1
            },
            AimCurve = {
                Enabled = false,
                Curve = 0.5,
                Randomness = 0.3
            }
        }
    },
    Visuals = {
        Names = {
            Enabled = false,
            Type = "Username", -- "Username" or "DisplayName"
            Color = Color3.new(1, 1, 1),
            DisplayNames = {},
            Font = 2,
            Size = 14
        },
        Checks = {
            Team = false,
            Health = true,
            Knock = true,
            Invisible = true
        }
    },
    Player = {
        Walkspeed = {
            Enabled = false,
            Loop = false,
            Value = 16
        },
        Jump = {
            Enabled = false,
            Power = 50,
            NoCooldown = false
        },
        AutoStrafe = {
            Enabled = false,
            Speed = 50,
            Style = "Smooth" -- "Smooth" or "Sharp"
        }
    },
    Settings = {
        Watermark = true
    }
}

-- Create watermark
local watermark = Drawing.new("Text")
watermark.Text = "[ ⛅ SOLSTICE ]"
watermark.Size = 18
watermark.Outline = true
watermark.OutlineColor = Color3.new(0, 0, 0)
watermark.Color = Color3.fromRGB(255, 165, 0) -- Orange
watermark.Position = Vector2.new(Camera.ViewportSize.X/2 - watermark.TextBounds.X/2, 10)
watermark.Visible = config.Settings.Watermark

-- Create FOV circle if enabled
if config.Aimbot.FOV.Enabled then
    config.Aimbot.FOV.Circle = Drawing.new("Circle")
    config.Aimbot.FOV.Circle.Visible = true
    config.Aimbot.FOV.Circle.Thickness = 1
    config.Aimbot.FOV.Circle.Color = Color3.new(1, 1, 1)
    config.Aimbot.FOV.Circle.Transparency = 1
    config.Aimbot.FOV.Circle.Filled = false
    config.Aimbot.FOV.Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    config.Aimbot.FOV.Circle.Radius = config.Aimbot.FOV.Value
end

-- Humanization variables
local jitterOffset = Vector2.new(0, 0)
local curveProgress = 0
local lastTargetPosition = nil
local aimStartTime = 0

-- Auto-strafe variables
local strafeDirection = 1
local lastStrafeTime = 0

-- Utility functions
local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    
    -- Aimbot checks
    if config.Aimbot.Checks.Team and player.Team == LocalPlayer.Team then
        return false
    end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if config.Aimbot.Checks.Health and humanoid.Health <= 0 then
        return false
    end
    
    if config.Aimbot.Checks.Knock and player.Character:FindFirstChild("KO") then
        return false
    end
    
    if config.Aimbot.Checks.Invisible and player.Character:FindFirstChild("Invisible") then
        return false
    end
    
    -- Wall check
    if config.Aimbot.Checks.Wall then
        local character = LocalPlayer.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            local targetPart = player.Character:FindFirstChild(config.Aimbot.Part)
            
            if root and targetPart then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {character, player.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local raycastResult = workspace:Raycast(root.Position, (targetPart.Position - root.Position).Unit * (targetPart.Position - root.Position).Magnitude, raycastParams)
                if raycastResult and raycastResult.Instance then
                    return false
                end
            end
        end
    end
    
    return true
end

local function isValidVisualTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    
    -- Visual checks
    if config.Visuals.Checks.Team and player.Team == LocalPlayer.Team then
        return false
    end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if config.Visuals.Checks.Health and humanoid.Health <= 0 then
        return false
    end
    
    if config.Visuals.Checks.Knock and player.Character:FindFirstChild("KO") then
        return false
    end
    
    if config.Visuals.Checks.Invisible and player.Character:FindFirstChild("Invisible") then
        return false
    end
    
    return true
end

-- Player movement functions
local function updateWalkspeed()
    if not config.Player.Walkspeed.Enabled then return end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = config.Player.Walkspeed.Value
        end
    end
end

local function updateJumpPower()
    if not config.Player.Jump.Enabled then return end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = config.Player.Jump.Power
            
            if config.Player.Jump.NoCooldown then
                humanoid.JumpHeight = config.Player.Jump.Power
            end
        end
    end
end

local function updateAutoStrafe()
    if not config.Player.AutoStrafe.Enabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Check if player is moving
    if humanoid.MoveDirection.Magnitude > 0 then
        local currentTime = tick()
        
        -- Change direction periodically for smooth strafe
        if currentTime - lastStrafeTime > (config.Player.AutoStrafe.Style == "Smooth" and 0.5 or 0.1) then
            strafeDirection = strafeDirection * -1
            lastStrafeTime = currentTime
        end
        
        -- Apply strafe force
        local strafeForce = Vector3.new(
            math.sin(rootPart.CFrame.LookVector.Unit.X + math.pi/2) * config.Player.AutoStrafe.Speed * strafeDirection,
            0,
            math.sin(rootPart.CFrame.LookVector.Unit.Z + math.pi/2) * config.Player.AutoStrafe.Speed * strafeDirection
        )
        
        -- Create or update BodyVelocity
        local bodyVelocity = rootPart:FindFirstChild("AutoStrafeVelocity")
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "AutoStrafeVelocity"
            bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
            bodyVelocity.Parent = rootPart
        end
        
        bodyVelocity.Velocity = Vector3.new(strafeForce.X, rootPart.Velocity.Y, strafeForce.Z)
    else
        -- Remove strafe when not moving
        local bodyVelocity = rootPart:FindFirstChild("AutoStrafeVelocity")
        if bodyVelocity then
            bodyVelocity:Destroy()
        end
    end
end

-- Enhanced humanization functions
local function updateJitter()
    if not config.Aimbot.Humanization.Jitter.Enabled then
        jitterOffset = Vector2.new(0, 0)
        return
    end
    
    local intensity = config.Aimbot.Humanization.Jitter.Intensity
    local speed = config.Aimbot.Humanization.Jitter.Speed
    local randomFactor = config.Aimbot.Humanization.Jitter.RandomFactor
    local time = tick()
    
    -- More complex jitter with multiple sine waves and random elements
    local jitterX = math.sin(time * speed) * intensity + 
                   math.sin(time * speed * 1.7) * (intensity * 0.3) +
                   (math.random(-100, 100) / 100) * randomFactor
                   
    local jitterY = math.cos(time * speed * 1.3) * intensity + 
                   math.cos(time * speed * 0.8) * (intensity * 0.4) +
                   (math.random(-100, 100) / 100) * randomFactor
    
    jitterOffset = Vector2.new(jitterX, jitterY)
end

local function updateAimCurve(targetPosition)
    if not config.Aimbot.Humanization.AimCurve.Enabled then
        curveProgress = 0
        return Vector3.new(0, 0, 0)
    end
    
    local currentTime = tick()
    
    -- Reset curve progress for new targets
    if not lastTargetPosition or (lastTargetPosition - targetPosition).Magnitude > 5 then
        curveProgress = 0
        aimStartTime = currentTime
        lastTargetPosition = targetPosition
    end
    
    -- Calculate curve progress (0 to 1)
    local timeDiff = currentTime - aimStartTime
    curveProgress = math.min(curveProgress + 0.02, 1)
    
    -- Create curved path using bezier-like interpolation
    local curveIntensity = config.Aimbot.Humanization.AimCurve.Curve
    local randomness = config.Aimbot.Humanization.AimCurve.Randomness
    
    -- Generate curve offset that diminishes as we approach target
    local curveMultiplier = (1 - curveProgress) * curveIntensity
    local randomOffset = (math.random(-100, 100) / 100) * randomness * curveMultiplier
    
    local curveOffset = Vector3.new(
        math.sin(curveProgress * math.pi) * curveMultiplier + randomOffset,
        math.cos(curveProgress * math.pi * 0.7) * curveMultiplier * 0.5,
        math.sin(curveProgress * math.pi * 1.3) * curveMultiplier * 0.3 + randomOffset * 0.5
    )
    
    return curveOffset
end

-- Aimbot functions
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) and player.Character and player.Character:FindFirstChild(config.Aimbot.Part) then
            local part = player.Character:FindFirstChild(config.Aimbot.Part)
            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mousePosition.X, mousePosition.Y)).Magnitude
                
                -- FOV check
                if config.Aimbot.FOV.Enabled and distance > config.Aimbot.FOV.Value then
                    continue
                end
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

local function aimAt(target)
    if not target or not target.Character or not target.Character:FindFirstChild(config.Aimbot.Part) then return end
    
    local part = target.Character:FindFirstChild(config.Aimbot.Part)
    local targetPosition = part.Position
    
    -- Apply prediction if enabled
    if config.Aimbot.Prediction.Enabled and part:IsA("BasePart") then
        local velocity = part.Velocity
        targetPosition = targetPosition + Vector3.new(
            velocity.X * config.Aimbot.Prediction.X,
            velocity.Y * config.Aimbot.Prediction.Y,
            velocity.Z * config.Aimbot.Prediction.X
        )
    end
    
    -- Apply curve humanization
    local curveOffset = updateAimCurve(targetPosition)
    targetPosition = targetPosition + curveOffset
    
    if config.Aimbot.Method == "Camera" then
        -- Enhanced Camera aim method with better stability
        local cameraCFrame = Camera.CFrame
        local targetDirection = (targetPosition - cameraCFrame.Position).Unit
        
        -- Apply smoothness with better interpolation
        if config.Aimbot.Smoothness.Enabled then
            local currentLook = cameraCFrame.LookVector
            local smoothFactor = math.max(0.01, 1 / config.Aimbot.Smoothness.Value)
            targetDirection = currentLook:Lerp(targetDirection, smoothFactor)
        end
        
        -- Apply jitter to camera direction
        if config.Aimbot.Humanization.Jitter.Enabled then
            local rightVector = cameraCFrame.RightVector
            local upVector = cameraCFrame.UpVector
            targetDirection = (targetDirection + 
                              rightVector * (jitterOffset.X * 0.01) + 
                              upVector * (jitterOffset.Y * 0.01)).Unit
        end
        
        -- Smooth camera transition
        local newCFrame = CFrame.lookAt(cameraCFrame.Position, cameraCFrame.Position + targetDirection)
        Camera.CFrame = cameraCFrame:Lerp(newCFrame, 0.8)
        
    else
        -- Enhanced Mouse aim method
        local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPosition)
        
        if not onScreen then return end
        
        local mousePos = UserInputService:GetMouseLocation()
        local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
        
        -- Apply jitter to target position
        if config.Aimbot.Humanization.Jitter.Enabled then
            targetPos = targetPos + jitterOffset
        end
        
        -- Calculate movement delta
        local deltaX = targetPos.X - mousePos.X
        local deltaY = targetPos.Y - mousePos.Y
        
        -- Apply smoothness
        if config.Aimbot.Smoothness.Enabled then
            local smoothFactor = math.max(0.01, 1 / config.Aimbot.Smoothness.Value)
            deltaX = deltaX * smoothFactor
            deltaY = deltaY * smoothFactor
        end
        
        -- Move mouse with enhanced stability
        if math.abs(deltaX) > 0.5 or math.abs(deltaY) > 0.5 then
            mousemoverel(deltaX, deltaY)
        end
    end
end

-- Visuals functions
local function getNameText(player)
    if config.Visuals.Names.Type == "DisplayName" then
        return player.DisplayName
    else
        return player.Name
    end
end

local function updateVisuals()
    -- Update watermark position in case screen size changes
    watermark.Position = Vector2.new(Camera.ViewportSize.X/2 - watermark.TextBounds.X/2, 10)
    watermark.Visible = config.Settings.Watermark
    
    -- Update FOV circle if enabled
    if config.Aimbot.FOV.Enabled and config.Aimbot.FOV.Circle then
        config.Aimbot.FOV.Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        config.Aimbot.FOV.Circle.Radius = config.Aimbot.FOV.Value
    end

    for _, player in pairs(Players:GetPlayers()) do
        local validTarget = isValidVisualTarget(player)
        local character = player.Character
        local head = character and character:FindFirstChild("Head")
        
        -- Name ESP
        if config.Visuals.Names.Enabled then
            if not config.Visuals.Names.DisplayNames[player] then
                local textLabel = Drawing.new("Text")
                textLabel.Text = getNameText(player)
                textLabel.Size = config.Visuals.Names.Size
                textLabel.Center = true
                textLabel.Outline = true
                textLabel.OutlineColor = Color3.new(0, 0, 0)
                textLabel.Color = config.Visuals.Names.Color
                textLabel.Font = config.Visuals.Names.Font
                config.Visuals.Names.DisplayNames[player] = textLabel
            end
            
            if validTarget and head then
                local screenPosition, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                if onScreen then
                    config.Visuals.Names.DisplayNames[player].Position = Vector2.new(screenPosition.X, screenPosition.Y)
                    config.Visuals.Names.DisplayNames[player].Visible = true
                    config.Visuals.Names.DisplayNames[player].Text = getNameText(player)
                else
                    config.Visuals.Names.DisplayNames[player].Visible = false
                end
            else
                config.Visuals.Names.DisplayNames[player].Visible = false
            end
        end
    end
end

-- Cleanup functions
local function cleanupPlayer(player)
    -- Clean up name ESP
    if config.Visuals.Names.DisplayNames[player] then
        config.Visuals.Names.DisplayNames[player]:Remove()
        config.Visuals.Names.DisplayNames[player] = nil
    end
end

local function cleanupAllVisuals()
    for _, player in pairs(Players:GetPlayers()) do
        cleanupPlayer(player)
    end
end

local function cleanupAutoStrafe()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local bodyVelocity = character.HumanoidRootPart:FindFirstChild("AutoStrafeVelocity")
        if bodyVelocity then
            bodyVelocity:Destroy()
        end
    end
end

-- Connections
local aimbotConnection
local visualsConnection
local walkspeedConnection
local jumpConnection
local autoStrafeConnection
local humanizationConnection

local function toggleAimbot(state)
    if state then
        if aimbotConnection then aimbotConnection:Disconnect() end
        
        aimbotConnection = RunService.Heartbeat:Connect(function()
            if config.Aimbot.Enabled and UserInputService:IsKeyDown(config.Aimbot.Keybind) then
                local target
                
                if config.Aimbot.Sticky and config.Aimbot.LockedOnto and isValidTarget(config.Aimbot.LockedOnto) then
                    target = config.Aimbot.LockedOnto
                else
                    target = getClosestPlayer()
                    config.Aimbot.LockedOnto = target
                end
                
                if target then
                    aimAt(target)
                end
            elseif config.Aimbot.Sticky and not UserInputService:IsKeyDown(config.Aimbot.Keybind) then
                config.Aimbot.LockedOnto = nil
                curveProgress = 0
                lastTargetPosition = nil
            end
        end)
        
        -- Start humanization
        if humanizationConnection then humanizationConnection:Disconnect() end
        humanizationConnection = RunService.Heartbeat:Connect(function()
            updateJitter()
        end)
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        if humanizationConnection then
            humanizationConnection:Disconnect()
            humanizationConnection = nil
        end
        config.Aimbot.LockedOnto = nil
        curveProgress = 0
        lastTargetPosition = nil
    end
end

local function toggleVisuals(state)
    if state then
        if visualsConnection then visualsConnection:Disconnect() end
        
        visualsConnection = RunService.RenderStepped:Connect(function()
            updateVisuals()
        end)
        
        -- Setup player removal listener
        Players.PlayerRemoving:Connect(function(player)
            cleanupPlayer(player)
        end)
        
        -- Initialize visuals for existing players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if config.Visuals.Names.Enabled and not config.Visuals.Names.DisplayNames[player] then
                    local textLabel = Drawing.new("Text")
                    textLabel.Text = getNameText(player)
                    textLabel.Size = config.Visuals.Names.Size
                    textLabel.Center = true
                    textLabel.Outline = true
                    textLabel.OutlineColor = Color3.new(0, 0, 0)
                    textLabel.Color = config.Visuals.Names.Color
                    textLabel.Font = config.Visuals.Names.Font
                    config.Visuals.Names.DisplayNames[player] = textLabel
                end
            end
        end
    else
        if visualsConnection then
            visualsConnection:Disconnect()
            visualsConnection = nil
        end
        
        -- Clean up all visuals
        cleanupAllVisuals()
    end
end

local function toggleWalkspeed(state)
    if state then
        if walkspeedConnection then walkspeedConnection:Disconnect() end
        
        -- Get current walkspeed if not set
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and config.Player.Walkspeed.Value == 16 then -- Default value
                config.Player.Walkspeed.Value = humanoid.WalkSpeed
            end
        end
        
        if config.Player.Walkspeed.Loop then
            walkspeedConnection = RunService.Heartbeat:Connect(function()
                updateWalkspeed()
            end)
        else
            updateWalkspeed()
        end
    else
        if walkspeedConnection then
            walkspeedConnection:Disconnect()
            walkspeedConnection = nil
        end
        
        -- Reset walkspeed to default
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end
end

local function toggleJump(state)
    if state then
        if jumpConnection then jumpConnection:Disconnect() end
        
        -- Get current jump power if not set
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and config.Player.Jump.Power == 50 then -- Default value
                config.Player.Jump.Power = humanoid.JumpPower
            end
        end
        
        jumpConnection = RunService.Heartbeat:Connect(function()
            updateJumpPower()
        end)
    else
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
        
        -- Reset jump power to default
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = 50
                humanoid.JumpHeight = 7.2 -- Default Roblox jump height
            end
        end
    end
end

local function toggleAutoStrafe(state)
    if state then
        if autoStrafeConnection then autoStrafeConnection:Disconnect() end
        
        autoStrafeConnection = RunService.Heartbeat:Connect(function()
            updateAutoStrafe()
        end)
    else
        if autoStrafeConnection then
            autoStrafeConnection:Disconnect()
            autoStrafeConnection = nil
        end
        cleanupAutoStrafe()
    end
end

-- UI Setup
local globalSettings = {
    UIBlurToggle = Window:GlobalSetting({
        Name = "UI Blur",
        Default = Window:GetAcrylicBlurState(),
        Callback = function(bool)
            Window:SetAcrylicBlurState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
                Lifetime = 5
            })
        end,
    }),
    NotificationToggler = Window:GlobalSetting({
        Name = "Notifications",
        Default = Window:GetNotificationsState(),
        Callback = function(bool)
            Window:SetNotificationsState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " Notifications",
                Lifetime = 5
            })
        end,
    }),
    ShowUserInfo = Window:GlobalSetting({
        Name = "Show User Info",
        Default = Window:GetUserInfoState(),
        Callback = function(bool)
            Window:SetUserInfoState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Showing" or "Redacted") .. " User Info",
                Lifetime = 5
            })
        end,
    })
}

local MainGroup = {
    starlight = Window:TabGroup()
}
local PlayerGroup = {
    starlight = Window:TabGroup()
}
local ExtraGroup = {
    starlight = Window:TabGroup()
}

local tabs = {
    Aimbot = MainGroup.starlight:Tab({ Name = "🔒 | Aimbot" }),
    Visuals = MainGroup.starlight:Tab({ Name = "🔎 | Visuals" }),
    Checks = MainGroup.starlight:Tab({ Name = "🔗 | Checks" }),
    
    Player = PlayerGroup.starlight:Tab({ Name = "🌺 | Player" }),

    Credits = ExtraGroup.starlight:Tab({ Name = "📚 | Credits" }),
    Settings = ExtraGroup.starlight:Tab({ Name = "🧠 | Settings" }),
}

local sections = {
    aim_general = tabs.Aimbot:Section({ Side = "Left" }),
    aim_methods = tabs.Aimbot:Section({ Side = "Right" }),
    aim_hum = tabs.Aimbot:Section({ Side = "Right" }),

    vis_general = tabs.Visuals:Section({ Side = "Left" }),
    vis_config = tabs.Visuals:Section({ Side = "Right" }),

    prog_creds = tabs.Credits:Section({ Side = "Left" }),
    ui_creds = tabs.Credits:Section({ Side = "Right" }),

    aim_checks = tabs.Checks:Section({ Side = "Left" }),
    vis_checks = tabs.Checks:Section({ Side = "Right" }),
    
    plr_speed = tabs.Player:Section({ Side = "Left" }),
    plr_jump = tabs.Player:Section({ Side = "Right" }),
    plr_strafe = tabs.Player:Section({ Side = "Left" }),
    
    sols = tabs.Settings:Section({ Side = "Right" }),
}

-- Settings Section
sections.sols:Toggle({
    Name = "Show Watermark",
    Default = true,
    Callback = function(value)
        config.Settings.Watermark = value
        watermark.Visible = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Watermark"
        })
    end,
}, "Toggle")

-- General Aimbot Section
sections.aim_general:Header({
    Name = "🔒 | General"
})
sections.aim_general:Divider()
sections.aim_general:Toggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(value)
        config.Aimbot.Enabled = value
        toggleAimbot(value)
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Aimbot"
        })
    end,
}, "Toggle")
sections.aim_general:Keybind({
    Name = "Aimbot Key",
    Blacklist = false,
    onBinded = function(bind)
        config.Aimbot.Keybind = bind
        Window:Notify({
            Title = Window.Settings.Title,
            Description = "Successfully Binded Aimbot to - "..tostring(bind.Name),
            Lifetime = 3
        })
    end,
}, "Keybind")
sections.aim_general:Toggle({
    Name = "Sticky Aim",
    Default = false,
    Callback = function(value)
        config.Aimbot.Sticky = value
        if not value then
            config.Aimbot.LockedOnto = nil
        end
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Sticky"
        })
    end,
}, "Toggle")
sections.aim_general:Divider()
sections.aim_general:Toggle({
    Name = "Enable FOV",
    Default = false,
    Callback = function(value)
        config.Aimbot.FOV.Enabled = value
        if value and not config.Aimbot.FOV.Circle then
            config.Aimbot.FOV.Circle = Drawing.new("Circle")
            config.Aimbot.FOV.Circle.Visible = true
            config.Aimbot.FOV.Circle.Thickness = 1
            config.Aimbot.FOV.Circle.Color = Color3.new(1, 1, 1)
            config.Aimbot.FOV.Circle.Transparency = 1
            config.Aimbot.FOV.Circle.Filled = false
            config.Aimbot.FOV.Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            config.Aimbot.FOV.Circle.Radius = config.Aimbot.FOV.Value
        elseif not value and config.Aimbot.FOV.Circle then
            config.Aimbot.FOV.Circle:Remove()
            config.Aimbot.FOV.Circle = nil
        end
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "FOV"
        })
    end,
}, "Toggle")
sections.aim_general:Slider({
    Name = "FOV Size",
    Default = 100,
    Minimum = 25,
    Maximum = 500,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Aimbot.FOV.Value = Value
        if config.Aimbot.FOV.Circle then
            config.Aimbot.FOV.Circle.Radius = Value
        end
    end
}, "Slider")
sections.aim_general:Divider()
sections.aim_general:Toggle({
    Name = "Enable Smoothness",
    Default = false,
    Callback = function(value)
        config.Aimbot.Smoothness.Enabled = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Smoothness"
        })
    end,
}, "Toggle")
sections.aim_general:Slider({
    Name = "Smoothness",
    Default = 10,
    Minimum = 1,
    Maximum = 100,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Aimbot.Smoothness.Value = Value
    end
}, "Slider")
sections.aim_general:Divider()
sections.aim_general:Toggle({
    Name = "Enable Prediction",
    Default = false,
    Callback = function(value)
        config.Aimbot.Prediction.Enabled = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Prediction"
        })
    end,
}, "Toggle")
sections.aim_general:Slider({
    Name = "Prediction X",
    Default = 0.1,
    Minimum = 0.01,
    Maximum = 1,
    DisplayMethod = nil,
    Precision = 2,
    Callback = function(Value)
        config.Aimbot.Prediction.X = Value
    end
}, "Slider")
sections.aim_general:Slider({
    Name = "Prediction Y",
    Default = 0.1,
    Minimum = 0.01,
    Maximum = 1,
    DisplayMethod = nil,
    Precision = 2,
    Callback = function(Value)
        config.Aimbot.Prediction.Y = Value
    end
}, "Slider")

-- Humanization Section
sections.aim_hum:Header({
    Name = "🧍‍♂️ | Humanization"
})
sections.aim_hum:Divider()
sections.aim_hum:Toggle({
    Name = "Enable Jitter",
    Default = false,
    Callback = function(value)
        config.Aimbot.Humanization.Jitter.Enabled = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Jitter"
        })
    end,
}, "Toggle")
sections.aim_hum:Slider({
    Name = "Jitter Intensity",
    Default = 5,
    Minimum = 1,
    Maximum = 20,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Aimbot.Humanization.Jitter.Intensity = Value
    end
}, "Slider")
sections.aim_hum:Slider({
    Name = "Jitter Speed",
    Default = 2,
    Minimum = 0.5,
    Maximum = 10,
    DisplayMethod = nil,
    Precision = 1,
    Callback = function(Value)
        config.Aimbot.Humanization.Jitter.Speed = Value
    end
}, "Slider")
sections.aim_hum:Slider({
    Name = "Random Factor",
    Default = 1,
    Minimum = 0,
    Maximum = 5,
    DisplayMethod = nil,
    Precision = 1,
    Callback = function(Value)
        config.Aimbot.Humanization.Jitter.RandomFactor = Value
    end
}, "Slider")
sections.aim_hum:Divider()
sections.aim_hum:Toggle({
    Name = "Enable Aim Curve",
    Default = false,
    Callback = function(value)
        config.Aimbot.Humanization.AimCurve.Enabled = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Aim Curve"
        })
    end,
}, "Toggle")
sections.aim_hum:Slider({
    Name = "Curve Intensity",
    Default = 0.5,
    Minimum = 0.1,
    Maximum = 3,
    DisplayMethod = nil,
    Precision = 1,
    Callback = function(Value)
        config.Aimbot.Humanization.AimCurve.Curve = Value
    end
}, "Slider")
sections.aim_hum:Slider({
    Name = "Curve Randomness",
    Default = 0.3,
    Minimum = 0,
    Maximum = 2,
    DisplayMethod = nil,
    Precision = 1,
    Callback = function(Value)
        config.Aimbot.Humanization.AimCurve.Randomness = Value
    end
}, "Slider")

-- Methods Section
sections.aim_methods:Header({
    Name = "👻 | Methods"
})
sections.aim_methods:Divider()
local a_part = {
    "Head",
    "HumanoidRootPart",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg"
}
local a_meth = {
    "Mouse",
    "Camera"
}
sections.aim_methods:Dropdown({
    Name = "Aim Part",
    Multi = false,
    Required = true,
    Options = a_part,
    Default = 1,
    Callback = function(Value)
        config.Aimbot.Part = Value
    end,
}, "Dropdown")
sections.aim_methods:Dropdown({
    Name = "Aim Method",
    Multi = false,
    Required = true,
    Options = a_meth,
    Default = 2,
    Callback = function(Value)
        config.Aimbot.Method = Value
    end,
}, "Dropdown")

-- Visuals Section
sections.vis_general:Header({
    Name = "🔎 | General"
})
sections.vis_general:Divider()
sections.vis_general:Toggle({
    Name = "Show Names",
    Default = false,
    Callback = function(value)
        config.Visuals.Names.Enabled = value
        if value and not visualsConnection then
            toggleVisuals(true)
        elseif not value then
            toggleVisuals(false)
        end
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Name ESP"
        })
    end
}, "Toggle")

sections.vis_config:Header({
    Name = "🎨 | Config"
})
sections.vis_config:Divider()
local nameTypes = {"Username", "DisplayName"}
sections.vis_config:Dropdown({
    Name = "Name Type",
    Multi = false,
    Required = true,
    Options = nameTypes,
    Default = 1,
    Callback = function(Value)
        config.Visuals.Names.Type = Value
        for player, textLabel in pairs(config.Visuals.Names.DisplayNames) do
            textLabel.Text = getNameText(player)
        end
    end,
}, "Dropdown")
sections.vis_config:Colorpicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        config.Visuals.Names.Color = color
        
        for _, textLabel in pairs(config.Visuals.Names.DisplayNames) do
            textLabel.Color = color
        end
    end,
}, "Colorpicker")
sections.vis_config:Slider({
    Name = "Font Size",
    Default = 14,
    Minimum = 8,
    Maximum = 24,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Visuals.Names.Size = Value
        for _, textLabel in pairs(config.Visuals.Names.DisplayNames) do
            textLabel.Size = Value
        end
    end
}, "Slider")

-- Checks Sections
sections.aim_checks:Header({
    Name = "🎯 | Aimbot Checks"
})
sections.aim_checks:Divider()
sections.aim_checks:Toggle({
    Name = "Team Check",
    Default = false,
    Callback = function(value)
        config.Aimbot.Checks.Team = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Team Check"
        })
    end
}, "Toggle")
sections.aim_checks:Toggle({
    Name = "Health Check",
    Default = true,
    Callback = function(value)
        config.Aimbot.Checks.Health = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Health Check"
        })
    end
}, "Toggle")
sections.aim_checks:Toggle({
    Name = "Knock Check",
    Default = true,
    Callback = function(value)
        config.Aimbot.Checks.Knock = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Knock Check"
        })
    end
}, "Toggle")
sections.aim_checks:Toggle({
    Name = "Invisible Check",
    Default = true,
    Callback = function(value)
        config.Aimbot.Checks.Invisible = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Invisible Check"
        })
    end
}, "Toggle")
sections.aim_checks:Toggle({
    Name = "Wall Check",
    Default = true,
    Callback = function(value)
        config.Aimbot.Checks.Wall = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Wall Check"
        })
    end
}, "Toggle")

sections.vis_checks:Header({
    Name = "🔎 | Visual Checks"
})
sections.vis_checks:Divider()
sections.vis_checks:Toggle({
    Name = "Team Check",
    Default = false,
    Callback = function(value)
        config.Visuals.Checks.Team = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Team Check"
        })
    end
}, "Toggle")
sections.vis_checks:Toggle({
    Name = "Health Check",
    Default = true,
    Callback = function(value)
        config.Visuals.Checks.Health = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Health Check"
        })
    end
}, "Toggle")
sections.vis_checks:Toggle({
    Name = "Knock Check",
    Default = true,
    Callback = function(value)
        config.Visuals.Checks.Knock = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Knock Check"
        })
    end
}, "Toggle")
sections.vis_checks:Toggle({
    Name = "Invisible Check",
    Default = true,
    Callback = function(value)
        config.Visuals.Checks.Invisible = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Invisible Check"
        })
    end
}, "Toggle")

-- Player Sections
sections.plr_speed:Header({
    Name = "🦵 | Walkspeed"
})
sections.plr_speed:Divider()
sections.plr_speed:Toggle({
    Name = "Enable Walkspeed",
    Default = false,
    Callback = function(value)
        config.Player.Walkspeed.Enabled = value
        toggleWalkspeed(value)
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Walkspeed"
        })
    end
}, "Toggle")
sections.plr_speed:Toggle({
    Name = "Loop Walkspeed",
    Default = false,
    Callback = function(value)
        config.Player.Walkspeed.Loop = value
        if config.Player.Walkspeed.Enabled then
            toggleWalkspeed(true)
        end
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Loop Walkspeed"
        })
    end
}, "Toggle")
sections.plr_speed:Slider({
    Name = "Speed",
    Default = 16,
    Minimum = 1,
    Maximum = 500,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Player.Walkspeed.Value = Value
        if config.Player.Walkspeed.Enabled then
            updateWalkspeed()
        end
    end
}, "Slider")

sections.plr_strafe:Header({
    Name = "🏃 | Auto-Strafe"
})
sections.plr_strafe:Divider()
sections.plr_strafe:Toggle({
    Name = "Enable Auto-Strafe",
    Default = false,
    Callback = function(value)
        config.Player.AutoStrafe.Enabled = value
        toggleAutoStrafe(value)
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Auto-Strafe"
        })
    end
}, "Toggle")
sections.plr_strafe:Slider({
    Name = "Strafe Speed",
    Default = 50,
    Minimum = 10,
    Maximum = 200,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Player.AutoStrafe.Speed = Value
    end
}, "Slider")
local strafeStyles = {"Smooth", "Sharp"}
sections.plr_strafe:Dropdown({
    Name = "Strafe Style",
    Multi = false,
    Required = true,
    Options = strafeStyles,
    Default = 1,
    Callback = function(Value)
        config.Player.AutoStrafe.Style = Value
    end,
}, "Dropdown")

sections.plr_jump:Header({
    Name = "🦘 | Jumping"
})
sections.plr_jump:Divider()
sections.plr_jump:Toggle({
    Name = "Enable Jump Power",
    Default = false,
    Callback = function(value)
        config.Player.Jump.Enabled = value
        toggleJump(value)
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Jump Power"
        })
    end
}, "Toggle")
sections.plr_jump:Slider({
    Name = "Jump Power",
    Default = 50,
    Minimum = 1,
    Maximum = 500,
    DisplayMethod = nil,
    Precision = 0,
    Callback = function(Value)
        config.Player.Jump.Power = Value
        if config.Player.Jump.Enabled then
            updateJumpPower()
        end
    end
}, "Slider")
sections.plr_jump:Toggle({
    Name = "Disable Jump Cooldowns",
    Default = false,
    Callback = function(value)
        config.Player.Jump.NoCooldown = value
        if config.Player.Jump.Enabled then
            updateJumpPower()
        end
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Jump Cooldowns"
        })
    end
}, "Toggle")

-- Credits Sections
sections.prog_creds:Header({
    Name = "☕ | Features Programming"
})
sections.prog_creds:Divider()
sections.prog_creds:Paragraph({
    Header = "🔒 | Aimbot",
    Body = "unconcerning"
})
sections.prog_creds:Paragraph({
    Header = "🔎 | Visuals",
    Body = "unconcerning"
})
sections.prog_creds:Paragraph({
    Header = "🌺 | Player Settings",
    Body = "unconcerning"
})
sections.prog_creds:Divider()
sections.prog_creds:Button({
    Name = "Join Discord",
    Callback = function()
        setclipboard("https://discord.gg/example")
        Window:Notify({
            Title = Window.Settings.Title,
            Description = "Copied discord invite link."
        })
    end,
})

sections.ui_creds:Header({
    Name = "🧠 | UI Library"
})
sections.ui_creds:Divider()
sections.ui_creds:Paragraph({
    Header = "💎 | UI Design & Functionality",
    Body = "MacLib by biggaboy212"
})
sections.ui_creds:Paragraph({
    Header = "🚀 | UI Documentation",
    Body = "brady-xyz"
})

-- Config and cleanup
MacLib:SetFolder("starlight")
tabs.Settings:InsertConfigSection("Left")

-- Character added event to apply movement changes
LocalPlayer.CharacterAdded:Connect(function(character)
    if config.Player.Walkspeed.Enabled then
        updateWalkspeed()
    end
    if config.Player.Jump.Enabled then
        updateJumpPower()
    end
end)

Window.onUnloaded(function()
    if aimbotConnection then
        aimbotConnection:Disconnect()
    end
    if visualsConnection then
        visualsConnection:Disconnect()
    end
    if walkspeedConnection then
        walkspeedConnection:Disconnect()
    end
    if jumpConnection then
        jumpConnection:Disconnect()
    end
    if autoStrafeConnection then
        autoStrafeConnection:Disconnect()
    end
    if humanizationConnection then
        humanizationConnection:Disconnect()
    end
    
    -- Clean up all visuals
    cleanupAllVisuals()
    
    -- Clean up auto-strafe
    cleanupAutoStrafe()
    
    -- Remove watermark
    if watermark then
        watermark:Remove()
    end
    
    -- Remove FOV circle
    if config.Aimbot.FOV.Circle then
        config.Aimbot.FOV.Circle:Remove()
    end
    
    -- Reset player movement
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            humanoid.JumpHeight = 7.2
        end
    end
    
    print("Unloaded!")
end)

tabs.Aimbot:Select()
MacLib:LoadAutoLoadConfig()
