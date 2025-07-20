local Lib = {}
if game.CoreGui:FindFirstChild("Lib") then
    game.CoreGui:FindFirstChild("Lib"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui",game.CoreGui)
ScreenGui.Name = "Lib"
ScreenGui.ResetOnSpawn = false

-- Mobile detection
local isMobile = game:GetService("UserInputService").TouchEnabled
local isGamepad = game:GetService("UserInputService").GamepadEnabled

-- Mobile scaling factor
local mobileScale = isMobile and 1.5 or 1

local roundDecimals = function(num, places)
    places = math.pow(10, places or 0)
    num = num * places
    if num >= 0 then 
        num = math.floor(num + 0.5) 
    else 
        num = math.ceil(num - 0.5) 
    end
    return num / places
end

local Usp = game:GetService("UserInputService")
local visible = true
local Usable = true

if _G.HideKeybind == nil then
    _G.HideKeybind = Enum.KeyCode.RightControl
end

-- Modified input handling for mobile
local function handleHideInput(input)
    if input.KeyCode == _G.HideKeybind and Usable and not isMobile then
        toggleVisibility()
    elseif input.UserInputType == Enum.UserInputType.Touch and Usable and isMobile then
        -- Double tap to hide/show on mobile
        local tapCount = 0
        local lastTap = 0
        local currentTime = tick()
        
        if currentTime - lastTap < 0.3 then
            tapCount = tapCount + 1
            if tapCount >= 2 then
                toggleVisibility()
                tapCount = 0
            end
        else
            tapCount = 1
        end
        lastTap = currentTime
    end
end

Usp.InputBegan:Connect(handleHideInput)

local function toggleVisibility()
    Usable = false
    for i,v in pairs(ScreenGui:GetChildren()) do
        spawn(function()
            if visible == true then
                v:TweenPosition(UDim2.new(0,v.AbsolutePosition.X,0,v.AbsolutePosition.Y - 500),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.5,true)
                wait(0.5)
                v.Visible = false
            else
                v.Visible = true
                v:TweenPosition(UDim2.new(0,v.AbsolutePosition.X,0,v.AbsolutePosition.Y + 500),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.5,true)
            end
        end)
        wait(0.05)
    end
    Usable = true
    visible = not visible
end

-- Modified drag function for touch support
function AddDrag(frame1, frame2)
    local dragStartPos
    local startPos
    local dragging = false
    
    local function handleInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStartPos = input.Position
            startPos = frame2.Position
            dragging = true
            
            local connection
            connection = game:GetService("RunService").RenderStepped:Connect(function()
                if not dragging then 
                    connection:Disconnect()
                    return 
                end
                
                local inputService = game:GetService("UserInputService")
                local currentInput
                
                if isMobile then
                    currentInput = inputService:GetTouchInput(input)
                else
                    currentInput = inputService:GetMouseLocation()
                end
                
                if currentInput then
                    local delta = currentInput - dragStartPos
                    frame2.Position = UDim2.new(
                        startPos.X.Scale, 
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end
    end
    
    local function endDrag()
        dragging = false
    end
    
    frame1.InputBegan:Connect(handleInput)
    frame1.InputEnded:Connect(endDrag)
    
    if isMobile then
        Usp.TouchEnded:Connect(endDrag)
    else
        Usp.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                endDrag()
            end
        end)
    end
end

function Lib:CreateWindow(Name)
    local Window = {}

    -- Adjust sizes for mobile
    local baseWidth = isMobile and 200 or 150
    local baseHeight = isMobile and 230 or 206
    local titleHeight = isMobile and 35 or 25
    local fontSize = isMobile and 16 or 12

    local Main = Instance.new("ImageLabel")
    local glow = Instance.new("ImageLabel")
    local buttonHolder = Instance.new("Frame")
    local Corner = Instance.new("UICorner")
    local holder = Instance.new("Frame")
    local UIPadding = Instance.new("UIPadding")
    local UIListLayout = Instance.new("UIListLayout")
    local Title = Instance.new("Frame")
    local Title_2 = Instance.new("TextLabel")
    local Minimize = Instance.new("TextButton")
    local glow_2 = Instance.new("ImageLabel")

    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Main.BackgroundTransparency = 1.000
    Main.Position = UDim2.new(0, 15, 0, 15)
    Main.Size = UDim2.new(0, baseWidth, 0, baseHeight)
    Main.Image = "rbxassetid://3570695787"
    Main.ImageColor3 = Color3.fromRGB(35, 35, 35)
    Main.ScaleType = Enum.ScaleType.Slice
    Main.SliceCenter = Rect.new(100, 100, 100, 100)
    Main.SliceScale = 0.040
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0, #ScreenGui:GetChildren() * (baseWidth + 20) - (baseWidth - 5), 0, 15)
    Main.Size = UDim2.new(0, baseWidth, 0, titleHeight)

    -- Rest of the window creation code remains similar but with mobile adjustments
    -- Make sure to scale all sizes and fonts based on mobileScale
    
    -- Example for button creation with mobile support:
    function Window:Button(name, callback)
        local callback = callback or function() end
        local buttonHeight = isMobile and 35 or 25
        
        local Button = Instance.new("Frame")
        local Text = Instance.new("TextButton")

        Button.Name = "Button"
        Button.Parent = holder
        Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Button.BackgroundTransparency = 1.000
        Button.Size = UDim2.new(1, 0, 0, buttonHeight)

        Text.Name = "Text"
        Text.Parent = Button
        Text.Active = false
        Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text.BackgroundTransparency = 1.000
        Text.Selectable = false
        Text.Size = UDim2.new(1, 0, 1, 0)
        Text.Font = Enum.Font.GothamBold
        Text.TextColor3 = Color3.fromRGB(255, 255, 255)
        Text.TextSize = fontSize
        Text.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
        Text.TextStrokeTransparency = 0.920
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Text = name
        
        -- Enhanced input handling for mobile
        local function handleActivation(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                spawn(callback)
                
                -- Visual feedback for mobile
                if isMobile then
                    local ripple = Instance.new("Frame")
                    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ripple.BackgroundTransparency = 0.8
                    ripple.Size = UDim2.new(0, 0, 0, 0)
                    ripple.Position = UDim2.new(
                        0, input.Position.X - Button.AbsolutePosition.X,
                        0, input.Position.Y - Button.AbsolutePosition.Y
                    )
                    ripple.Parent = Button
                    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                    ripple.ZIndex = 5
                    
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    game:GetService("TweenService"):Create(
                        ripple,
                        tweenInfo,
                        {
                            Size = UDim2.new(2, 0, 2, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 1
                        }
                    ):Play()
                    
                    delay(0.3, function() ripple:Destroy() end)
                end
            end
        end
        
        Text.InputBegan:Connect(handleActivation)
        Update(buttonHeight)
    end
    
    -- Similar modifications for other elements (toggles, sliders, etc.)
    -- Adjust sizes, fonts, and input handling for each element
    
    return Window
end

return Lib
