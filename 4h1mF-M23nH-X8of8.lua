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
local HttpService = game:GetService("HttpService")
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
            Circle = nil,
            Mode = "Screen"
        },
        Part = "Head",
        Method = "Camera",
        CurrentTarget = nil,
        LockedOnto = nil,
        Checks = {
            Team = false,
            Health = false,
            Wall = false
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
            Health = false
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
local watermark1 = Drawing.new("Text")
watermark1.Text = "[ ⛅ SOLSTICE ]"
watermark1.Size = 18
watermark1.Outline = true
watermark1.OutlineColor = Color3.new(0, 0, 0)
watermark1.Color = Color3.fromRGB(59, 130, 246) -- #3b82f6
watermark1.Visible = config.Settings.Watermark

local watermark2 = Drawing.new("Text")
watermark2.Text = "[ ⛅ SOLSTICE ]"
watermark2.Size = 18
watermark2.Outline = true
watermark2.OutlineColor = Color3.new(0, 0, 0)
watermark2.Color = Color3.fromRGB(139, 92, 246) -- #8b5cf6
watermark2.Visible = config.Settings.Watermark

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
    
    local fovCenter
    if config.Aimbot.FOV.Mode == "Screen" then
        fovCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else -- Mouse
        fovCenter = mousePosition
    end

    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) and player.Character and player.Character:FindFirstChild(config.Aimbot.Part) then
            local part = player.Character:FindFirstChild(config.Aimbot.Part)
            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local fovDistance = (Vector2.new(screenPoint.X, screenPoint.Y) - fovCenter).Magnitude
                
                -- FOV check
                if config.Aimbot.FOV.Enabled and fovDistance > config.Aimbot.FOV.Value then
                    continue
                end

                local mouseDistance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude
                if mouseDistance < shortestDistance then
                    shortestDistance = mouseDistance
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
    if watermark1 and watermark2 then
        local textBounds = watermark1.TextBounds
        local position = Vector2.new(Camera.ViewportSize.X / 2 - textBounds.X / 2, 10)
        watermark1.Position = position
        watermark2.Position = position + Vector2.new(1, 1)
        watermark1.Visible = config.Settings.Watermark
        watermark2.Visible = config.Settings.Watermark
    end
    
    -- Update FOV circle if enabled
    if config.Aimbot.FOV.Enabled and config.Aimbot.FOV.Circle then
        if config.Aimbot.FOV.Mode == "Screen" then
            config.Aimbot.FOV.Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else -- Mouse
            config.Aimbot.FOV.Circle.Position = UserInputService:GetMouseLocation()
        end
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
local components = {
    Aimbot = {
        Enabled = nil,
        Keybind = nil,
        Sticky = nil,
        FOV = {
            Enabled = nil,
            Value = nil,
            Mode = nil
        },
        Smoothness = {
            Enabled = nil,
            Value = nil
        },
        Prediction = {
            Enabled = nil,
            X = nil,
            Y = nil
        },
        Part = nil,
        Method = nil,
        Checks = {
            Team = nil,
            Health = nil,
            Wall = nil
        },
        Humanization = {
            Jitter = {
                Enabled = nil,
                Intensity = nil,
                Speed = nil,
                RandomFactor = nil
            },
            AimCurve = {
                Enabled = nil,
                Curve = nil,
                Randomness = nil
            }
        }
    },
    Visuals = {
        Names = {
            Enabled = nil,
            Type = nil,
            Color = nil,
            Size = nil
        },
        Checks = {
            Team = nil,
            Health = nil
        }
    },
    Player = {
        Walkspeed = {
            Enabled = nil,
            Loop = nil,
            Value = nil
        },
        Jump = {
            Enabled = nil,
            Power = nil,
            NoCooldown = nil
        },
        AutoStrafe = {
            Enabled = nil,
            Speed = nil,
            Style = nil
        }
    },
    Settings = {
        Watermark = nil
    }
}

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
    
    sols_settings = tabs.Settings:Section({ Side = "Right" }),
    config_manager = tabs.Settings:Section({ Side = "Left" })
}

-- Config Functions
local configName = "Default"
local selectedConfig = "Default"

local function deepMerge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k] or false) == "table" then
            deepMerge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

local function updateUIFromConfig()
    -- Note: Setting Keybinds and Colorpickers programmatically is not straightforward
    -- as it requires converting from JSON-safe formats back to Roblox-specific types.
    -- This functionality is not implemented in this version.

    -- Aimbot
    pcall(function() components.Aimbot.Enabled:SetValue(config.Aimbot.Enabled) end)
    pcall(function() components.Aimbot.Sticky:SetValue(config.Aimbot.Sticky) end)
    pcall(function() components.Aimbot.FOV.Enabled:SetValue(config.Aimbot.FOV.Enabled) end)
    pcall(function() components.Aimbot.FOV.Value:SetValue(config.Aimbot.FOV.Value) end)
    pcall(function() components.Aimbot.FOV.Mode:UpdateSelection(config.Aimbot.FOV.Mode) end)
    pcall(function() components.Aimbot.Smoothness.Enabled:SetValue(config.Aimbot.Smoothness.Enabled) end)
    pcall(function() components.Aimbot.Smoothness.Value:SetValue(config.Aimbot.Smoothness.Value) end)
    pcall(function() components.Aimbot.Prediction.Enabled:SetValue(config.Aimbot.Prediction.Enabled) end)
    pcall(function() components.Aimbot.Prediction.X:SetValue(config.Aimbot.Prediction.X) end)
    pcall(function() components.Aimbot.Prediction.Y:SetValue(config.Aimbot.Prediction.Y) end)
    pcall(function() components.Aimbot.Part:UpdateSelection(config.Aimbot.Part) end)
    pcall(function() components.Aimbot.Method:UpdateSelection(config.Aimbot.Method) end)
    
    -- Aimbot Checks
    pcall(function() components.Aimbot.Checks.Team:SetValue(config.Aimbot.Checks.Team) end)
    pcall(function() components.Aimbot.Checks.Health:SetValue(config.Aimbot.Checks.Health) end)
    pcall(function() components.Aimbot.Checks.Wall:SetValue(config.Aimbot.Checks.Wall) end)

    -- Humanization
    pcall(function() components.Aimbot.Humanization.Jitter.Enabled:SetValue(config.Aimbot.Humanization.Jitter.Enabled) end)
    pcall(function() components.Aimbot.Humanization.Jitter.Intensity:SetValue(config.Aimbot.Humanization.Jitter.Intensity) end)
    pcall(function() components.Aimbot.Humanization.Jitter.Speed:SetValue(config.Aimbot.Humanization.Jitter.Speed) end)
    pcall(function() components.Aimbot.Humanization.Jitter.RandomFactor:SetValue(config.Aimbot.Humanization.Jitter.RandomFactor) end)
    pcall(function() components.Aimbot.Humanization.AimCurve.Enabled:SetValue(config.Aimbot.Humanization.AimCurve.Enabled) end)
    pcall(function() components.Aimbot.Humanization.AimCurve.Curve:SetValue(config.Aimbot.Humanization.AimCurve.Curve) end)
    pcall(function() components.Aimbot.Humanization.AimCurve.Randomness:SetValue(config.Aimbot.Humanization.AimCurve.Randomness) end)

    -- Visuals
    pcall(function() components.Visuals.Names.Enabled:SetValue(config.Visuals.Names.Enabled) end)
    pcall(function() components.Visuals.Names.Type:UpdateSelection(config.Visuals.Names.Type) end)
    pcall(function() components.Visuals.Names.Size:SetValue(config.Visuals.Names.Size) end)
    
    -- Visuals Checks
    pcall(function() components.Visuals.Checks.Team:SetValue(config.Visuals.Checks.Team) end)
    pcall(function() components.Visuals.Checks.Health:SetValue(config.Visuals.Checks.Health) end)
    
    -- Player
    pcall(function() components.Player.Walkspeed.Enabled:SetValue(config.Player.Walkspeed.Enabled) end)
    pcall(function() components.Player.Walkspeed.Loop:SetValue(config.Player.Walkspeed.Loop) end)
    pcall(function() components.Player.Walkspeed.Value:SetValue(config.Player.Walkspeed.Value) end)
    pcall(function() components.Player.Jump.Enabled:SetValue(config.Player.Jump.Enabled) end)
    pcall(function() components.Player.Jump.Power:SetValue(config.Player.Jump.Power) end)
    pcall(function() components.Player.Jump.NoCooldown:SetValue(config.Player.Jump.NoCooldown) end)
    pcall(function() components.Player.AutoStrafe.Enabled:SetValue(config.Player.AutoStrafe.Enabled) end)
    pcall(function() components.Player.AutoStrafe.Speed:SetValue(config.Player.AutoStrafe.Speed) end)
    pcall(function() components.Player.AutoStrafe.Style:UpdateSelection(config.Player.AutoStrafe.Style) end)
end

local function applyConfig(loadedConfig)
    deepMerge(config, loadedConfig)
    updateUIFromConfig()
    Window:Notify({ Title = "Arcana", Description = "Successfully loaded config: " .. selectedConfig, Lifetime = 5 })
end

local function saveConfig()
    if not isfolder("starlight") then
        makefolder("starlight")
    end
    if not isfolder("starlight/configs") then
        makefolder("starlight/configs")
    end

    local file = "starlight/configs/" .. configName .. ".json"
    
    if isfile(file) then
        Window:Confirm({
            Title = "Overwrite Confirmation",
            Description = "A config with this name already exists. Are you sure you want to overwrite it?",
            Buttons = {
                {
                    Name = "Yes",
                    Callback = function()
                        writefile(file, HttpService:JSONEncode(config))
                        Window:Notify({ Title = "Arcana", Description = "Successfully saved config: " .. configName, Lifetime = 5 })
                        updateConfigDropdown()
                    end
                },
                { Name = "No" }
            }
        })
    else
        writefile(file, HttpService:JSONEncode(config))
        Window:Notify({ Title = "Arcana", Description = "Successfully saved config: " .. configName, Lifetime = 5 })
        updateConfigDropdown()
    end
end

local function loadConfig()
    local file = "starlight/configs/" .. selectedConfig .. ".json"
    if isfile(file) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(file))
        end)
        
        if success and result then
            applyConfig(result)
        else
            Window:Notify({ Title = "Arcana", Description = "Failed to load config: " .. selectedConfig, Lifetime = 5 })
        end
    else
        Window:Notify({ Title = "Arcana", Description = "Config not found: " .. selectedConfig, Lifetime = 5 })
    end
end

function updateConfigDropdown()
    local configs = {}
    if isfolder("starlight/configs") then
        for _, file in ipairs(list_files("starlight/configs")) do
            if file:match(".json$") then
                table.insert(configs, file:gsub(".json", ""))
            end
        end
    end
    components.Settings.ConfigDropdown:UpdateOptions(configs)
end


-- Settings Section
sections.sols_settings:Toggle({
    Name = "Show Watermark",
    Default = true,
    Callback = function(value)
        config.Settings.Watermark = value
        if watermark1 and watermark2 then
            watermark1.Visible = value
            watermark2.Visible = value
        end
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Watermark"
        })
    end,
}, "Toggle")

-- Config Manager Section
sections.config_manager:Header({ Name = "📚 | Configuations" })
sections.config_manager:Divider()

components.Settings.ConfigNameBox = sections.config_manager:Input({
    Name = "Config Name",
    Placeholder = "Enter config name...",
    Default = configName,
    Callback = function(value)
        configName = value
    end
}, "Input")

sections.config_manager:Button({
    Name = "Save as Config",
    Callback = saveConfig
})

sections.config_manager:Divider()

components.Settings.ConfigDropdown = sections.config_manager:Dropdown({
    Name = "Configs",
    Options = {},
    Default = 1,
    Callback = function(value)
        selectedConfig = value
    end
})

sections.config_manager:Button({
    Name = "Load Config",
    Callback = loadConfig
})

-- General Aimbot Section
sections.aim_general:Header({
    Name = "🔒 | General"
})
sections.aim_general:Divider()
components.Aimbot.Enabled = sections.aim_general:Toggle({
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
components.Aimbot.Keybind = sections.aim_general:Keybind({
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
components.Aimbot.Sticky = sections.aim_general:Toggle({
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
components.Aimbot.FOV.Enabled = sections.aim_general:Toggle({
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
components.Aimbot.FOV.Value = sections.aim_general:Slider({
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
components.Aimbot.Smoothness.Enabled = sections.aim_general:Toggle({
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
components.Aimbot.Smoothness.Value = sections.aim_general:Slider({
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
components.Aimbot.Prediction.Enabled = sections.aim_general:Toggle({
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
components.Aimbot.Prediction.X = sections.aim_general:Slider({
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
components.Aimbot.Prediction.Y = sections.aim_general:Slider({
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
components.Aimbot.Humanization.Jitter.Enabled = sections.aim_hum:Toggle({
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
components.Aimbot.Humanization.Jitter.Intensity = sections.aim_hum:Slider({
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
components.Aimbot.Humanization.Jitter.Speed = sections.aim_hum:Slider({
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
components.Aimbot.Humanization.Jitter.RandomFactor = sections.aim_hum:Slider({
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
components.Aimbot.Humanization.AimCurve.Enabled = sections.aim_hum:Toggle({
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
components.Aimbot.Humanization.AimCurve.Curve = sections.aim_hum:Slider({
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
components.Aimbot.Humanization.AimCurve.Randomness = sections.aim_hum:Slider({
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
components.Aimbot.Part = sections.aim_methods:Dropdown({
    Name = "Aim Part",
    Multi = false,
    Required = true,
    Options = a_part,
    Default = 1,
    Callback = function(Value)
        config.Aimbot.Part = Value
    end,
}, "Dropdown")
components.Aimbot.Method = sections.aim_methods:Dropdown({
    Name = "Aim Method",
    Multi = false,
    Required = true,
    Options = a_meth,
    Default = 2,
    Callback = function(Value)
        config.Aimbot.Method = Value
    end,
}, "Dropdown")

local a_fov = {
    "Screen",
    "Mouse"
}
components.Aimbot.FOV.Mode = sections.aim_methods:Dropdown({
    Name = "FOV",
    Multi = false,
    Required = true,
    Options = a_fov,
    Default = 1,
    Callback = function(Value)
        config.Aimbot.FOV.Mode = Value
    end,
}, "Dropdown")

-- Visuals Section
sections.vis_general:Header({
    Name = "🔎 | General"
})
sections.vis_general:Divider()
components.Visuals.Names.Enabled = sections.vis_general:Toggle({
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
components.Visuals.Names.Type = sections.vis_config:Dropdown({
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
components.Visuals.Names.Color = sections.vis_config:Colorpicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        config.Visuals.Names.Color = color
        
        for _, textLabel in pairs(config.Visuals.Names.DisplayNames) do
            textLabel.Color = color
        end
    end,
}, "Colorpicker")
components.Visuals.Names.Size = sections.vis_config:Slider({
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
components.Aimbot.Checks.Team = sections.aim_checks:Toggle({
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
components.Aimbot.Checks.Health = sections.aim_checks:Toggle({
    Name = "Health Check",
    Default = false,
    Callback = function(value)
        config.Aimbot.Checks.Health = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Health Check"
        })
    end
}, "Toggle")
components.Aimbot.Checks.Wall = sections.aim_checks:Toggle({
    Name = "Wall Check",
    Default = false,
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
components.Visuals.Checks.Team = sections.vis_checks:Toggle({
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
components.Visuals.Checks.Health = sections.vis_checks:Toggle({
    Name = "Health Check",
    Default = false,
    Callback = function(value)
        config.Visuals.Checks.Health = value
        Window:Notify({
            Title = Window.Settings.Title,
            Description = (value and "Enabled " or "Disabled ") .. "Health Check"
        })
    end
}, "Toggle")

-- Player Sections
sections.plr_speed:Header({
    Name = "🦵 | Walkspeed"
})
sections.plr_speed:Divider()
components.Player.Walkspeed.Enabled = sections.plr_speed:Toggle({
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
components.Player.Walkspeed.Loop = sections.plr_speed:Toggle({
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
components.Player.Walkspeed.Value = sections.plr_speed:Slider({
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
components.Player.AutoStrafe.Enabled = sections.plr_strafe:Toggle({
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
components.Player.AutoStrafe.Speed = sections.plr_strafe:Slider({
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
components.Player.AutoStrafe.Style = sections.plr_strafe:Dropdown({
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
components.Player.Jump.Enabled = sections.plr_jump:Toggle({
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
components.Player.Jump.Power = sections.plr_jump:Slider({
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
components.Player.Jump.NoCooldown = sections.plr_jump:Toggle({
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
    Body = "unconcerning (Player)"
})
sections.prog_creds:Paragraph({
    Header = "🔎 | Visuals",
    Body = "unconcerning (Player)"
})
sections.prog_creds:Paragraph({
    Header = "🌺 | Player Settings",
    Body = "unconcerning (Player)"
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
sections.ui_creds:Divider()
sections.ui_creds:Button({
    Name = "MacLib GitHub",
    Callback = function()
        setclipboard("https://github.com/biggaboy212/Maclib/tree/main")
        Window:Notify({
            Title = Window.Settings.Title,
            Description = "Copied GitHub link."
        })
    end,
})
sections.ui_creds:Button({
    Name = "MacLib Documentation",
    Callback = function()
        setclipboard("https://brady-xyz.gitbook.io/maclib-ui-library")
        Window:Notify({
            Title = Window.Settings.Title,
            Description = "Copied documentation link."
        })
    end,
})

-- Config and cleanup
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
    if watermark1 then
        watermark1:Remove()
    end
    if watermark2 then
        watermark2:Remove()
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

updateConfigDropdown()
tabs.Aimbot:Select()
MacLib:LoadAutoLoadConfig()MacLib:LoadAutoLoadConfig()
