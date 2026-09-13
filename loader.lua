local Defaults = {
    Interface = {
        Title = "TasuHub",
        Accent = Color3.fromRGB(113, 180, 255),
        AccentSoft = Color3.fromRGB(218, 239, 255),
        Background = Color3.fromRGB(242, 248, 255),
        Surface = Color3.fromRGB(255, 255, 255),
        Surface2 = Color3.fromRGB(235, 245, 255),
        Text = Color3.fromRGB(22, 27, 34),
        Muted = Color3.fromRGB(82, 94, 108)
    },
    Aim = {
        Enabled = false,
        HoldRightMouse = true,
        Method = "Camera",
        TargetPart = "Head",
        TeamCheck = false,
        WallCheck = true,
        AliveCheck = true,
        Prediction = true,
        PredictionTime = 0.12,
        Smoothing = 0.18,
        FOV = 180,
        MaxDistance = 2000,
        ShowFOV = true
    },
    Visuals = {
        Enabled = false,
        Boxes = true,
        BoxFilled = false,
        Names = true,
        Distance = true,
        Health = true,
        HeadDot = false,
        Tracers = false,
        Chams = true,
        Skeleton = false,
        Offscreen = false,
        TeamColors = true,
        MaxDistance = 2500,
        Thickness = 1
    },
    Movement = {
        Speed = false,
        SpeedMethod = "WalkSpeed",
        SpeedValue = 32,
        Jump = false,
        JumpValue = 80,
        InfiniteJump = false,
        BunnyHop = false,
        Fly = false,
        FlyMethod = "Velocity",
        FlySpeed = 70,
        Noclip = false,
        ClickTP = false,
        AntiFling = false,
        Gravity = false,
        GravityValue = 196.2,
        Orbit = false,
        OrbitRadius = 8,
        OrbitSpeed = 2
    },
    World = {
        Fullbright = false,
        NoFog = false,
        CameraFOV = 70,
        ThirdPerson = false,
        Freecam = false,
        FreecamSpeed = 1.5
    },
    Keybinds = {},
    Catalog = {},
    Waypoints = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return
end

local env = getgenv and getgenv() or _G
if env.TasuHub and type(env.TasuHub.Unload) == "function" then
    pcall(env.TasuHub.Unload)
elseif env.TasuAnticheatTest and type(env.TasuAnticheatTest.Unload) == "function" then
    pcall(env.TasuAnticheatTest.Unload)
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[deepCopy(key)] = deepCopy(item)
    end
    return result
end

local State = deepCopy(Defaults)
local connections = {}
local featureConnections = {}
local instances = {}
local originalCollision = setmetatable({}, {__mode = "k"})
local humanoidDefaults = setmetatable({}, {__mode = "k"})
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}
local originalGravity = Workspace.Gravity
local originalCameraFOV = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70
local originalCameraMinZoom = LocalPlayer.CameraMinZoomDistance
local originalCameraMaxZoom = LocalPlayer.CameraMaxZoomDistance
Defaults.World.CameraFOV = originalCameraFOV
State.World.CameraFOV = originalCameraFOV
local selectedPlayer = nil
local selectedWaypoint = 1
local unloaded = false
local unload

local function trackConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function disconnectFeature(name)
    local list = featureConnections[name]
    if not list then
        return
    end
    for _, connection in ipairs(list) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    featureConnections[name] = nil
end

local function trackFeature(name, connection)
    featureConnections[name] = featureConnections[name] or {}
    table.insert(featureConnections[name], connection)
    return connection
end

local function trackInstance(instance)
    table.insert(instances, instance)
    return instance
end

local function getCharacter(player)
    player = player or LocalPlayer
    local character = player.Character
    if not character then
        return nil, nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and not humanoidDefaults[humanoid] then
        humanoidDefaults[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            UseJumpPower = humanoid.UseJumpPower,
            PlatformStand = humanoid.PlatformStand
        }
    end
    local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    return character, humanoid, root
end

local function getAlive(player)
    local character, humanoid, root = getCharacter(player)
    return character and humanoid and root and humanoid.Health > 0, character, humanoid, root
end

local function getTeamToken(player)
    if player.Team then
        return "team:" .. tostring(player.Team)
    end
    for _, attributeName in ipairs({"Team", "TeamId", "TeamName"}) do
        local value = player:GetAttribute(attributeName)
        if value ~= nil then return attributeName .. ":" .. tostring(value) end
        if player.Character then
            value = player.Character:GetAttribute(attributeName)
            if value ~= nil then return attributeName .. ":" .. tostring(value) end
        end
    end
end

local function areTeammates(first, second)
    local firstToken = getTeamToken(first)
    local secondToken = getTeamToken(second)
    return firstToken ~= nil and firstToken == secondToken
end

local function getPlayerVisualColor(player)
    if State.Visuals.TeamColors then
        if player.Team then
            return player.Team.TeamColor.Color
        end
        local attributeColor = player:GetAttribute("TeamColor")
        if typeof(attributeColor) == "Color3" then
            return attributeColor
        end
        if player.Character then
            attributeColor = player.Character:GetAttribute("TeamColor")
            if typeof(attributeColor) == "Color3" then return attributeColor end
        end
    end
    return Theme.Accent
end

local function getMousePosition()
    local location = UserInputService:GetMouseLocation()
    return Vector2.new(location.X, location.Y)
end

local function resolveGlobal(name)
    local ok, value = pcall(function()
        return env[name] or _G[name]
    end)
    if ok then
        return value
    end
end

local capabilities = {
    Drawing = type(Drawing) == "table" and type(Drawing.new) == "function",
    GetHui = type(resolveGlobal("gethui")) == "function",
    MouseMove = type(resolveGlobal("mousemoverel")) == "function",
    Files = type(resolveGlobal("writefile")) == "function" and type(resolveGlobal("readfile")) == "function",
    Folders = type(resolveGlobal("makefolder")) == "function" and type(resolveGlobal("isfolder")) == "function",
    Http = type(resolveGlobal("request")) == "function" or type(resolveGlobal("http_request")) == "function" or type(syn) == "table" and type(syn.request) == "function" or type(game.HttpGet) == "function",
    CustomAsset = type(resolveGlobal("getcustomasset")) == "function" or type(resolveGlobal("getsynasset")) == "function",
    LoadString = type(loadstring) == "function"
}

local function getRequest()
    return resolveGlobal("request") or resolveGlobal("http_request") or type(syn) == "table" and syn.request
end

local function getCustomAsset(path)
    local fn = resolveGlobal("getcustomasset") or resolveGlobal("getsynasset")
    if fn then
        local ok, value = pcall(fn, path)
        if ok then
            return value
        end
    end
end

local function ensureFolder(path)
    if not capabilities.Folders then
        return false
    end
    local isfolder = resolveGlobal("isfolder")
    local makefolder = resolveGlobal("makefolder")
    local current = ""
    for part in string.gmatch(path, "[^/]+") do
        current = current == "" and part or current .. "/" .. part
        if not isfolder(current) then
            local ok = pcall(makefolder, current)
            if not ok then
                return false
            end
        end
    end
    return true
end

local guiParent
local gethui = resolveGlobal("gethui")
if type(gethui) == "function" then
    local ok, value = pcall(gethui)
    if ok and value then
        guiParent = value
    end
end
guiParent = guiParent or CoreGui

local Theme = State.Interface
local ScreenGui = trackInstance(Instance.new("ScreenGui"))
ScreenGui.Name = "TasuHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

local function stroke(object, color, thickness, transparency)
    local item = Instance.new("UIStroke")
    item.Color = color or Theme.Accent
    item.Thickness = thickness or 1
    item.Transparency = transparency or 0
    item.Parent = object
    return item
end

local function gradient(object, topColor, bottomColor, rotation)
    local item = Instance.new("UIGradient")
    item.Color = ColorSequence.new(topColor or Theme.Surface, bottomColor or Theme.Surface2)
    item.Rotation = rotation or 90
    item.Parent = object
    return item
end

local function animate(object, properties, duration, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.16, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local Toast = Instance.new("TextLabel")
Toast.AnchorPoint = Vector2.new(0.5, 0)
Toast.BackgroundColor3 = Color3.fromRGB(30, 42, 56)
Toast.BackgroundTransparency = 1
Toast.Font = Enum.Font.Gotham
Toast.Position = UDim2.new(0.5, 0, 0, 18)
Toast.Size = UDim2.fromOffset(260, 30)
Toast.TextColor3 = Color3.fromRGB(255, 255, 255)
Toast.TextSize = 11
Toast.TextTransparency = 1
Toast.Visible = false
Toast.ZIndex = 40
Toast.Parent = ScreenGui
round(Toast, 9)
stroke(Toast, Color3.fromRGB(158, 207, 247), 1, 0.16)
local toastRevision = 0
local function showToast(message)
    toastRevision = toastRevision + 1
    local revision = toastRevision
    Toast.Text = message
    Toast.Visible = true
    Toast.BackgroundTransparency = 1
    Toast.TextTransparency = 1
    animate(Toast, {BackgroundTransparency = 0.06, TextTransparency = 0}, 0.16)
    task.delay(2.1, function()
        if revision == toastRevision and Toast.Parent then
            animate(Toast, {BackgroundTransparency = 1, TextTransparency = 1}, 0.18)
            task.delay(0.18, function()
                if revision == toastRevision and Toast.Parent then Toast.Visible = false end
            end)
        end
    end)
end

local function textLabel(parent, text, size, position, textSize, color, alignment)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = color or Theme.Text
    label.TextSize = textSize or 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.Size = size or UDim2.new(1, 0, 0, 24)
    label.Position = position or UDim2.new()
    label.Parent = parent
    return label
end

local function button(parent, text, size, position)
    local item = Instance.new("TextButton")
    item.AutoButtonColor = false
    item.BackgroundColor3 = Theme.Surface2
    item.BackgroundTransparency = 0.08
    item.Text = text
    item.TextColor3 = Theme.Text
    item.TextSize = 12
    item.Font = Enum.Font.GothamMedium
    item.ClipsDescendants = true
    item.Size = size or UDim2.new(0, 100, 0, 28)
    item.Position = position or UDim2.new()
    round(item, 8)
    local itemStroke = stroke(item, Color3.fromRGB(177, 212, 244), 1, 0.18)
    gradient(item, Color3.fromRGB(255, 255, 255), Theme.Surface2)
    local hoverGlow = Instance.new("Frame")
    hoverGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    hoverGlow.BackgroundColor3 = Theme.Accent
    hoverGlow.BackgroundTransparency = 0.94
    hoverGlow.BorderSizePixel = 0
    hoverGlow.Position = UDim2.fromScale(0.5, 0.5)
    hoverGlow.Size = UDim2.fromOffset(0, 0)
    hoverGlow.ZIndex = 0
    hoverGlow.Parent = item
    round(hoverGlow, 50)
    local function restingColor()
        return item:GetAttribute("Selected") and Theme.AccentSoft or Theme.Surface2
    end
    item.MouseEnter:Connect(function()
        animate(item, {BackgroundColor3 = item:GetAttribute("Selected") and Color3.fromRGB(200, 229, 255) or Color3.fromRGB(224, 241, 255)}, 0.14)
        animate(itemStroke, {Color = Theme.Accent, Transparency = 0.04}, 0.14)
        animate(hoverGlow, {Size = UDim2.new(1.25, 0, 1.25, 0), BackgroundTransparency = 0.88}, 0.16)
    end)
    item.MouseLeave:Connect(function()
        animate(item, {BackgroundColor3 = restingColor()}, 0.16)
        animate(itemStroke, {Color = Color3.fromRGB(177, 212, 244), Transparency = 0.18}, 0.16)
        animate(hoverGlow, {Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.94}, 0.16)
    end)
    item.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            animate(hoverGlow, {Size = UDim2.new(0.86, 0, 0.86, 0), BackgroundTransparency = 0.82}, 0.08, Enum.EasingStyle.Quad)
        end
    end)
    item.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            animate(hoverGlow, {Size = UDim2.new(1.25, 0, 1.25, 0), BackgroundTransparency = 0.88}, 0.1, Enum.EasingStyle.Quad)
        end
    end)
    item.Parent = parent
    return item
end

local function makeDraggable(frame, handle)
    local dragging = false
    local targetPosition
    handle.Active = true
    trackConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local framePosition = frame.AbsolutePosition
            targetPosition = framePosition
            frame.Position = UDim2.fromOffset(framePosition.X, framePosition.Y)
        end
    end))
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and targetPosition then
            local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
			local mouseDelta = Vector2.new(input.Delta.X, input.Delta.Y)
			local desired = targetPosition + mouseDelta
            local x = math.clamp(desired.X, 0, math.max(0, viewport.X - frame.AbsoluteSize.X))
            local y = math.clamp(desired.Y, 0, math.max(0, viewport.Y - frame.AbsoluteSize.Y))
            targetPosition = Vector2.new(x, y)
        end
    end))
    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    trackConnection(RunService.RenderStepped:Connect(function(deltaTime)
        if dragging and targetPosition then
            local current = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
            local alpha = 1 - math.exp(-deltaTime * 24)
            local nextPosition = current:Lerp(targetPosition, alpha)
            frame.Position = UDim2.fromOffset(nextPosition.X, nextPosition.Y)
        end
    end))
end

local TopBar = Instance.new("Frame")
TopBar.Name = "CategoryBar"
TopBar.BackgroundColor3 = Theme.Background
TopBar.BackgroundTransparency = 0.1
TopBar.Size = UDim2.fromOffset(720, 58)
TopBar.Position = UDim2.new(0.5, -360, 0, 12)
TopBar.Parent = ScreenGui
round(TopBar, 14)
stroke(TopBar, Color3.fromRGB(167, 210, 247), 1, 0.08)
gradient(TopBar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 243, 255), 75)

local DragGrip = Instance.new("Frame")
DragGrip.BackgroundTransparency = 1
DragGrip.Size = UDim2.fromOffset(148, 58)
DragGrip.Parent = TopBar

local HubIcon = Instance.new("Frame")
HubIcon.BackgroundColor3 = Theme.Accent
HubIcon.Size = UDim2.fromOffset(30, 30)
HubIcon.Position = UDim2.fromOffset(12, 14)
HubIcon.Parent = DragGrip
round(HubIcon, 10)
gradient(HubIcon, Color3.fromRGB(128, 196, 255), Color3.fromRGB(87, 151, 247), 45)
stroke(HubIcon, Color3.fromRGB(255, 255, 255), 1, 0.25)
local HubMark = textLabel(HubIcon, "T", UDim2.fromScale(1, 1), nil, 16, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Center)
HubMark.Font = Enum.Font.GothamBold
local HubDot = Instance.new("Frame")
HubDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HubDot.Size = UDim2.fromOffset(5, 5)
HubDot.Position = UDim2.new(1, -7, 0, 3)
HubDot.Parent = HubIcon
round(HubDot, 5)

local TopTitle = textLabel(DragGrip, Theme.Title, UDim2.new(1, -56, 1, 0), UDim2.fromOffset(50, 0), 14, Theme.Text)
TopTitle.Font = Enum.Font.GothamSemibold

local CategoryScroller = Instance.new("ScrollingFrame")
CategoryScroller.BackgroundTransparency = 1
CategoryScroller.BorderSizePixel = 0
CategoryScroller.ScrollBarThickness = 0
CategoryScroller.ScrollBarImageColor3 = Theme.Accent
CategoryScroller.ScrollingDirection = Enum.ScrollingDirection.X
CategoryScroller.Size = UDim2.new(1, -158, 1, 0)
CategoryScroller.Position = UDim2.fromOffset(148, 0)
CategoryScroller.CanvasSize = UDim2.fromOffset(543, 0)
CategoryScroller.Parent = TopBar

local CategoryLayout = Instance.new("UIListLayout")
CategoryLayout.FillDirection = Enum.FillDirection.Horizontal
CategoryLayout.VerticalAlignment = Enum.VerticalAlignment.Center
CategoryLayout.Padding = UDim.new(0, 7)
CategoryLayout.Parent = CategoryScroller

local ContentWindow = Instance.new("Frame")
ContentWindow.Name = "ContentWindow"
ContentWindow.BackgroundColor3 = Theme.Background
ContentWindow.BackgroundTransparency = 0.08
ContentWindow.Size = UDim2.fromOffset(680, 440)
ContentWindow.Position = UDim2.new(0.5, -340, 0, 64)
ContentWindow.Visible = false
ContentWindow.Parent = ScreenGui
round(ContentWindow, 16)
stroke(ContentWindow, Color3.fromRGB(153, 204, 244), 1, 0.08)
gradient(ContentWindow, Color3.fromRGB(255, 255, 255), Color3.fromRGB(229, 244, 255), 80)
local ContentScale = Instance.new("UIScale")
ContentScale.Parent = ContentWindow

local WindowHeader = Instance.new("Frame")
WindowHeader.BackgroundColor3 = Theme.Surface
WindowHeader.BackgroundTransparency = 0.04
WindowHeader.Size = UDim2.new(1, 0, 0, 38)
WindowHeader.Parent = ContentWindow
round(WindowHeader, 16)
gradient(WindowHeader, Color3.fromRGB(255, 255, 255), Color3.fromRGB(237, 248, 255), 75)

local HeaderMask = Instance.new("Frame")
HeaderMask.BorderSizePixel = 0
HeaderMask.BackgroundColor3 = Theme.Surface
HeaderMask.BackgroundTransparency = 0.04
HeaderMask.Position = UDim2.new(0, 0, 1, -8)
HeaderMask.Size = UDim2.new(1, 0, 0, 8)
HeaderMask.Parent = WindowHeader

local WindowTitle = textLabel(WindowHeader, "Home", UDim2.new(1, -50, 1, 0), UDim2.fromOffset(14, 0), 14, Theme.Text)
WindowTitle.Font = Enum.Font.GothamSemibold

local CloseButton = button(WindowHeader, "×", UDim2.fromOffset(30, 26), UDim2.new(1, -36, 0, 6))
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold

local WindowDragZone = Instance.new("Frame")
WindowDragZone.BackgroundTransparency = 1
WindowDragZone.Size = UDim2.new(1, -50, 1, 0)
WindowDragZone.Parent = WindowHeader

local PageHost = Instance.new("Frame")
PageHost.BackgroundTransparency = 1
PageHost.ClipsDescendants = true
PageHost.Size = UDim2.new(1, -16, 1, -50)
PageHost.Position = UDim2.fromOffset(8, 44)
PageHost.Parent = ContentWindow

makeDraggable(TopBar, DragGrip)
makeDraggable(ContentWindow, WindowDragZone)

local pages = {}
local pageScales = {}
local categoryButtons = {}
local categoryOutlines = {}
local controlRefreshers = {}
local currentCategory = "Home"

local function refreshControls()
    for _, refresh in ipairs(controlRefreshers) do
        pcall(refresh)
    end
end

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Size = UDim2.fromScale(1, 1)
    page.Visible = false
    page.Parent = PageHost
    local pageScale = Instance.new("UIScale")
    pageScale.Parent = page
    pageScales[name] = pageScale
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = page
    pages[name] = page
    return page
end

local function createCard(page, title)
    local card = Instance.new("Frame")
    card.Name = string.gsub(title, "[^%w]", "")
    card.BackgroundColor3 = Theme.Surface
    card.BackgroundTransparency = 0.14
    card.Size = UDim2.new(1, -4, 0, 42)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = page
    round(card, 12)
    stroke(card, Color3.fromRGB(180, 218, 248), 1, 0.12)
    gradient(card, Color3.fromRGB(255, 255, 255), Color3.fromRGB(239, 248, 255), 90)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 9)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = card
    local heading = textLabel(card, title, UDim2.new(1, 0, 0, 22), nil, 13, Theme.Text)
    heading.Font = Enum.Font.GothamSemibold
    heading.LayoutOrder = 0
    return card
end

local function addNote(card, text)
    local label = textLabel(card, text, UDim2.new(1, 0, 0, 34), nil, 11, Theme.Muted)
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    return label
end

local function addAction(card, text, callback)
    local item = button(card, text, UDim2.new(1, 0, 0, 30))
    item.Activated:Connect(function()
        pcall(callback, item)
    end)
    return item
end

local function addInput(card, placeholder, defaultText, callback, multiLine)
    local input = Instance.new("TextBox")
    input.BackgroundColor3 = Theme.Surface2
    input.BackgroundTransparency = 0.06
    input.ClearTextOnFocus = false
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = Theme.Muted
    input.Text = defaultText or ""
    input.TextColor3 = Theme.Text
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.MultiLine = multiLine or false
    input.TextWrapped = multiLine or false
    input.Size = UDim2.new(1, 0, 0, multiLine and 70 or 30)
    input.Parent = card
    round(input, 8)
    local inputStroke = stroke(input, Color3.fromRGB(184, 218, 245), 1, 0.12)
    gradient(input, Color3.fromRGB(255, 255, 255), Color3.fromRGB(235, 246, 255), 90)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = input
    input.Focused:Connect(function()
        animate(inputStroke, {Color = Theme.Accent, Thickness = 1.5, Transparency = 0}, 0.14)
    end)
    input.FocusLost:Connect(function()
        animate(inputStroke, {Color = Color3.fromRGB(184, 218, 245), Thickness = 1, Transparency = 0.12}, 0.16)
    end)
    if callback then
        input.FocusLost:Connect(function(enterPressed)
            pcall(callback, input.Text, enterPressed, input)
        end)
    end
    return input
end

local pendingKeybind
local keybindActions = {}

local function addToggle(card, text, getter, setter)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 28)
    row.Parent = card
    local label = textLabel(row, text, UDim2.new(1, -122, 1, 0), nil, 12, Theme.Text)
    local toggle = Instance.new("TextButton")
    toggle.AutoButtonColor = false
    toggle.Text = ""
    toggle.Size = UDim2.fromOffset(44, 22)
    toggle.Position = UDim2.new(1, -44, 0.5, -11)
    toggle.Parent = row
    round(toggle, 11)
    local bindId = card.Parent.Name .. "/" .. card.Name .. "/" .. text
    local bindButton = button(row, State.Keybinds[bindId] or "Bind", UDim2.fromOffset(50, 22), UDim2.new(1, -102, 0.5, -11))
    bindButton.TextSize = 10
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Theme.Text
    knob.Parent = toggle
    round(knob, 8)
    local function render()
        local enabled = getter()
        animate(toggle, {BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(217, 231, 244)}, 0.14)
        animate(knob, {BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(132, 158, 183), Position = enabled and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)}, 0.14)
    end
    local function renderBind()
        bindButton.Text = State.Keybinds[bindId] or "Bind"
    end
    table.insert(controlRefreshers, render)
    table.insert(controlRefreshers, renderBind)
    keybindActions[bindId] = function()
        setter(not getter())
        refreshControls()
    end
    bindButton.Activated:Connect(function()
        pendingKeybind = {Id = bindId, Button = bindButton}
        bindButton.Text = "Press"
        showToast("Press a key, or Backspace to clear")
    end)
    toggle.Activated:Connect(function()
        setter(not getter())
        render()
    end)
    render()
    return {Render = render, Row = row, Label = label, BindId = bindId}
end

local function addSlider(card, text, minimum, maximum, getter, setter, decimals)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 48)
    holder.Parent = card
    local title = textLabel(holder, text, UDim2.new(1, -70, 0, 22), nil, 12, Theme.Text)
    local valueLabel = textLabel(holder, "", UDim2.fromOffset(65, 22), UDim2.new(1, -65, 0, 0), 11, Theme.Muted, Enum.TextXAlignment.Right)
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.fromRGB(217, 231, 244)
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 1, -11)
    bar.Parent = holder
    round(bar, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Accent
    fill.Size = UDim2.fromScale(0, 1)
    fill.Parent = bar
    round(fill, 3)
    gradient(fill, Color3.fromRGB(133, 204, 255), Color3.fromRGB(95, 155, 247), 0)
    local dragging = false
    local precision = decimals or 0
    local function render()
        local value = math.clamp(tonumber(getter()) or minimum, minimum, maximum)
        fill.Size = UDim2.fromScale((value - minimum) / (maximum - minimum), 1)
        valueLabel.Text = string.format("%." .. precision .. "f", value)
    end
    table.insert(controlRefreshers, render)
    local function update(input)
        local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local value = minimum + (maximum - minimum) * ratio
        local factor = 10 ^ precision
        value = math.floor(value * factor + 0.5) / factor
        setter(value)
        render()
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end))
    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    render()
    return {Render = render, Holder = holder, Title = title}
end

local function addCycle(card, text, values, getter, setter)
    local item = addAction(card, "", function(buttonItem)
        local current = getter()
        local index = table.find(values, current) or 1
        index = index % #values + 1
        setter(values[index])
        buttonItem.Text = text .. ": " .. tostring(values[index])
    end)
    local function render()
        item.Text = text .. ": " .. tostring(getter())
    end
    table.insert(controlRefreshers, render)
    render()
    return item
end

local categoryMeta = {
    Home = {Hint = "Home"},
    Aim = {Hint = "Aim"},
    Visuals = {Hint = "Visuals"},
    Movement = {Hint = "Movement"},
    World = {Hint = "World"},
    Players = {Hint = "Players"},
    Catalog = {Hint = "Catalog"},
    Explorer = {Hint = "Explorer"},
    Configs = {Hint = "Configs"}
}

local function iconPart(parent, x, y, width, height, rotation, radius)
    local part = Instance.new("Frame")
    part.AnchorPoint = Vector2.new(0.5, 0.5)
    part.BackgroundColor3 = Theme.Accent
    part.BorderSizePixel = 0
    part.Position = UDim2.fromOffset(x, y)
    part.Rotation = rotation or 0
    part.Size = UDim2.fromOffset(width, height)
    part.ZIndex = 2
    part.Parent = parent
    round(part, radius or math.min(width, height))
    return part
end

local function vectorIcon(parent, category)
    local canvas = Instance.new("Frame")
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.fromOffset(28, 28)
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.Position = UDim2.fromScale(0.5, 0.5)
    canvas.ZIndex = 2
    canvas.Parent = parent
    if category == "Home" then
        iconPart(canvas, 14, 17, 14, 12, 0, 3)
        iconPart(canvas, 9, 11, 14, 3, 45, 2)
        iconPart(canvas, 19, 11, 14, 3, -45, 2)
        local door = iconPart(canvas, 14, 20, 4, 6, 0, 1)
        door.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    elseif category == "Aim" then
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.BackgroundTransparency = 1
        ring.Position = UDim2.fromOffset(14, 14)
        ring.Size = UDim2.fromOffset(20, 20)
        ring.ZIndex = 2
        ring.Parent = canvas
        round(ring, 20)
        stroke(ring, Theme.Accent, 2, 0)
        iconPart(canvas, 14, 14, 5, 5, 0, 5)
        iconPart(canvas, 14, 2.5, 2, 5, 0, 1)
        iconPart(canvas, 14, 25.5, 2, 5, 0, 1)
        iconPart(canvas, 2.5, 14, 5, 2, 0, 1)
        iconPart(canvas, 25.5, 14, 5, 2, 0, 1)
    elseif category == "Visuals" then
        local eye = Instance.new("Frame")
        eye.AnchorPoint = Vector2.new(0.5, 0.5)
        eye.BackgroundTransparency = 1
        eye.Position = UDim2.fromOffset(14, 14)
        eye.Size = UDim2.fromOffset(25, 14)
        eye.ZIndex = 2
        eye.Parent = canvas
        round(eye, 14)
        stroke(eye, Theme.Accent, 2, 0)
        iconPart(canvas, 14, 14, 7, 7, 0, 7)
    elseif category == "Movement" then
        iconPart(canvas, 9, 8, 12, 3, 45, 2)
        iconPart(canvas, 9, 14, 12, 3, -45, 2)
        iconPart(canvas, 18, 14, 12, 3, 45, 2)
        iconPart(canvas, 18, 20, 12, 3, -45, 2)
    elseif category == "World" then
        local globe = Instance.new("Frame")
        globe.AnchorPoint = Vector2.new(0.5, 0.5)
        globe.BackgroundTransparency = 1
        globe.Position = UDim2.fromOffset(14, 14)
        globe.Size = UDim2.fromOffset(22, 22)
        globe.ZIndex = 2
        globe.Parent = canvas
        round(globe, 22)
        stroke(globe, Theme.Accent, 2, 0)
        iconPart(canvas, 14, 14, 2, 20, 0, 1)
        iconPart(canvas, 14, 14, 20, 2, 0, 1)
        iconPart(canvas, 14, 14, 12, 22, 0, 12).BackgroundTransparency = 1
    elseif category == "Players" then
        iconPart(canvas, 14, 8, 9, 9, 0, 9)
        iconPart(canvas, 14, 20, 18, 10, 0, 7)
        iconPart(canvas, 4, 21, 5, 3, 0, 2)
        iconPart(canvas, 24, 21, 5, 3, 0, 2)
    elseif category == "Catalog" then
        for _, point in ipairs({{8, 8}, {20, 8}, {8, 20}, {20, 20}}) do
            iconPart(canvas, point[1], point[2], 8, 8, 0, 2)
        end
    elseif category == "Explorer" then
        iconPart(canvas, 7, 7, 5, 5, 0, 5)
        iconPart(canvas, 21, 14, 5, 5, 0, 5)
        iconPart(canvas, 21, 23, 5, 5, 0, 5)
        iconPart(canvas, 12, 10.5, 10, 2, 0, 1)
        iconPart(canvas, 16, 18.5, 2, 17, 0, 1)
        iconPart(canvas, 19, 14, 6, 2, 0, 1)
        iconPart(canvas, 19, 23, 6, 2, 0, 1)
    elseif category == "Configs" then
        for index, y in ipairs({7, 14, 21}) do
            iconPart(canvas, 14, y, 21, 2, 0, 1)
            iconPart(canvas, index == 1 and 9 or index == 2 and 18 or 12, y, 5, 5, 0, 5)
        end
    elseif category == "Settings" then
        iconPart(canvas, 14, 14, 10, 10, 0, 10)
        for _, point in ipairs({{14, 3}, {14, 25}, {3, 14}, {25, 14}, {6, 6}, {22, 22}, {22, 6}, {6, 22}}) do
            iconPart(canvas, point[1], point[2], 4, 4, 0, 1)
        end
        local hole = iconPart(canvas, 14, 14, 4, 4, 0, 4)
        hole.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
    return canvas
end

local categories = {"Home", "Catalog", "Players", "Visuals", "Aim", "Movement", "World", "Explorer", "Configs"}
local CategoryTooltip = Instance.new("TextLabel")
CategoryTooltip.BackgroundColor3 = Color3.fromRGB(44, 83, 120)
CategoryTooltip.BackgroundTransparency = 1
CategoryTooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
CategoryTooltip.TextTransparency = 1
CategoryTooltip.TextSize = 10
CategoryTooltip.Font = Enum.Font.Gotham
CategoryTooltip.TextXAlignment = Enum.TextXAlignment.Center
CategoryTooltip.TextYAlignment = Enum.TextYAlignment.Center
CategoryTooltip.Visible = false
CategoryTooltip.ZIndex = 20
CategoryTooltip.Size = UDim2.fromOffset(116, 22)
CategoryTooltip.Parent = ScreenGui
round(CategoryTooltip, 7)
stroke(CategoryTooltip, Color3.fromRGB(178, 220, 255), 1, 0.12)
local tooltipTransition = 0
local function positionCategoryTooltip()
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local x = TopBar.AbsolutePosition.X + TopBar.AbsoluteSize.X * 0.5 - CategoryTooltip.AbsoluteSize.X * 0.5
    local y = TopBar.AbsolutePosition.Y + TopBar.AbsoluteSize.Y + 8
    if y + CategoryTooltip.AbsoluteSize.Y > viewport.Y then
        y = TopBar.AbsolutePosition.Y - CategoryTooltip.AbsoluteSize.Y - 8
    end
    CategoryTooltip.Position = UDim2.fromOffset(x, y)
end
local function showCategoryTooltip(text)
    tooltipTransition = tooltipTransition + 1
    positionCategoryTooltip()
    CategoryTooltip.Text = text
    CategoryTooltip.Visible = true
    CategoryTooltip.BackgroundTransparency = 1
    CategoryTooltip.TextTransparency = 1
    animate(CategoryTooltip, {BackgroundTransparency = 0.04, TextTransparency = 0}, 0.16)
end
local function hideCategoryTooltip()
    tooltipTransition = tooltipTransition + 1
    local transition = tooltipTransition
    animate(CategoryTooltip, {BackgroundTransparency = 1, TextTransparency = 1}, 0.14)
    task.delay(0.14, function()
        if transition == tooltipTransition and CategoryTooltip.Parent then
            CategoryTooltip.Visible = false
        end
    end)
end
for _, name in ipairs(categories) do
    createPage(name)
    local categoryButton = button(CategoryScroller, "", UDim2.fromOffset(48, 48))
    categoryButton.Name = name .. "Button"
    categoryButton.LayoutOrder = #categoryButtons + 1
    categoryButtons[name] = categoryButton
    local selectedOutline = stroke(categoryButton, Theme.Accent, 1.5, 0)
    selectedOutline.Enabled = false
    categoryOutlines[name] = selectedOutline
    vectorIcon(categoryButton, name)
    categoryButton.MouseEnter:Connect(function()
        showCategoryTooltip(categoryMeta[name].Hint)
    end)
    categoryButton.MouseLeave:Connect(function()
        hideCategoryTooltip()
    end)
end

local windowTransition = 0

local function placeContentWindow()
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local barPosition = TopBar.AbsolutePosition
    local barSize = TopBar.AbsoluteSize
    local windowSize = ContentWindow.AbsoluteSize
    if windowSize.X <= 0 or windowSize.Y <= 0 then
        windowSize = Vector2.new(ContentWindow.Size.X.Offset, ContentWindow.Size.Y.Offset)
    end
    local opensBelow = barPosition.Y + barSize.Y * 0.5 < viewport.Y * 0.5
    local x = math.clamp(barPosition.X + barSize.X * 0.5 - windowSize.X * 0.5, 0, math.max(0, viewport.X - windowSize.X))
    local y = opensBelow and barPosition.Y + barSize.Y + 12 or barPosition.Y - windowSize.Y - 12
    if y < 0 then
        opensBelow = true
        y = math.min(viewport.Y - windowSize.Y, barPosition.Y + barSize.Y + 12)
    elseif y + windowSize.Y > viewport.Y then
        opensBelow = false
        y = math.max(0, barPosition.Y - windowSize.Y - 12)
    end
    ContentWindow.Position = UDim2.fromOffset(x, y + (opensBelow and -10 or 10))
    animate(ContentWindow, {Position = UDim2.fromOffset(x, y)}, 0.22, Enum.EasingStyle.Quint)
end

local function openContentWindow()
    windowTransition = windowTransition + 1
    if not ContentWindow.Visible then
        placeContentWindow()
        ContentWindow.Visible = true
        ContentScale.Scale = 0.94
        animate(ContentScale, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
    else
        animate(ContentScale, {Scale = 1}, 0.16)
    end
end

local function closeContentWindow()
    if not ContentWindow.Visible then return end
    windowTransition = windowTransition + 1
    local transition = windowTransition
    for buttonName, item in pairs(categoryButtons) do
        item:SetAttribute("Selected", false)
        animate(item, {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text}, 0.12)
        if categoryOutlines[buttonName] then categoryOutlines[buttonName].Enabled = false end
    end
    animate(ContentScale, {Scale = 0.95}, 0.16, Enum.EasingStyle.Quad)
    task.delay(0.16, function()
        if transition == windowTransition and ContentWindow and ContentWindow.Parent then
            ContentWindow.Visible = false
            ContentScale.Scale = 1
        end
    end)
end

local function showCategory(name)
    if not pages[name] then
        return
    end
    currentCategory = name
    openContentWindow()
    WindowTitle.Text = name
    for pageName, page in pairs(pages) do
        local selected = pageName == name
        page.Visible = selected
        if selected and pageScales[pageName] then
            pageScales[pageName].Scale = 0.975
            animate(pageScales[pageName], {Scale = 1}, 0.18, Enum.EasingStyle.Quint)
        end
    end
    for buttonName, item in pairs(categoryButtons) do
        local selected = buttonName == name
        item:SetAttribute("Selected", selected)
        animate(item, {BackgroundColor3 = selected and Theme.AccentSoft or Theme.Surface2, TextColor3 = Theme.Text}, 0.16)
        if categoryOutlines[buttonName] then
            categoryOutlines[buttonName].Enabled = selected
            if selected then animate(categoryOutlines[buttonName], {Thickness = 2.25, Transparency = 0}, 0.16) end
        end
    end
end

for name, item in pairs(categoryButtons) do
    item.Activated:Connect(function()
        if currentCategory == name and ContentWindow.Visible then
            closeContentWindow()
        else
            showCategory(name)
        end
    end)
end

CloseButton.Activated:Connect(function()
    closeContentWindow()
end)

trackConnection(RunService.RenderStepped:Connect(function()
    if not TopBar.Visible then TopBar.Visible = true end
    if not ScreenGui.Enabled then ScreenGui.Enabled = true end
end))

local FOVCircle = Instance.new("Frame")
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.ZIndex = 3
FOVCircle.Parent = ScreenGui
round(FOVCircle, 1000)
local FOVStroke = stroke(FOVCircle, Theme.Accent, 1, 0.15)

local function isVisibleTarget(character, targetPart)
    if not State.Aim.WallCheck then
        return true
    end
    local camera = Workspace.CurrentCamera
    local localCharacter = LocalPlayer.Character
    if not camera or not targetPart then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {localCharacter, camera}
    params.IgnoreWater = true
    local direction = targetPart.Position - camera.CFrame.Position
    local result = Workspace:Raycast(camera.CFrame.Position, direction, params)
    return not result or result.Instance:IsDescendantOf(character)
end

local function chooseTarget()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    local mousePosition = getMousePosition()
    local best
    local bestScore = State.Aim.FOV
    local _, _, localRoot = getCharacter(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local alive, character, humanoid, root = getAlive(player)
            if alive and (not State.Aim.TeamCheck or not areTeammates(player, LocalPlayer)) then
                local targetPart = character:FindFirstChild(State.Aim.TargetPart) or character:FindFirstChild("Head") or root
                if targetPart then
                    local worldDistance = localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
                    local screen, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screen.Z > 0 and worldDistance <= State.Aim.MaxDistance then
                        local score = (Vector2.new(screen.X, screen.Y) - mousePosition).Magnitude
                        if score < bestScore and isVisibleTarget(character, targetPart) then
                            bestScore = score
                            best = {Player = player, Character = character, Humanoid = humanoid, Root = root, Part = targetPart}
                        end
                    end
                end
            end
        end
    end
    return best
end

local currentTarget
local mousemoverel = resolveGlobal("mousemoverel")
trackFeature("Aim", RunService.RenderStepped:Connect(function(deltaTime)
    local mousePosition = getMousePosition()
    local diameter = State.Aim.FOV * 2
    FOVCircle.Size = UDim2.fromOffset(diameter, diameter)
    FOVCircle.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
    FOVCircle.Visible = State.Aim.Enabled and State.Aim.ShowFOV
    if not State.Aim.Enabled then
        currentTarget = nil
        return
    end
    if State.Aim.HoldRightMouse and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        currentTarget = nil
        return
    end
    currentTarget = chooseTarget()
    local camera = Workspace.CurrentCamera
    if not currentTarget or not camera then
        return
    end
    local aimPosition = currentTarget.Part.Position
    if State.Aim.Prediction then
        aimPosition = aimPosition + currentTarget.Root.AssemblyLinearVelocity * State.Aim.PredictionTime
    end
    if State.Aim.Method == "Mouse" and type(mousemoverel) == "function" then
        local screen = camera:WorldToViewportPoint(aimPosition)
        local delta = Vector2.new(screen.X, screen.Y) - mousePosition
        local factor = math.clamp(1 - State.Aim.Smoothing, 0.02, 1)
        pcall(mousemoverel, delta.X * factor, delta.Y * factor)
    else
        local goal = CFrame.lookAt(camera.CFrame.Position, aimPosition)
        local factor = math.clamp((1 - State.Aim.Smoothing) * deltaTime * 60, 0.01, 1)
        camera.CFrame = camera.CFrame:Lerp(goal, factor)
    end
end))

local espRecords = {}

local function newLine(parent, color)
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = color or Theme.Accent
    line.Size = UDim2.fromOffset(0, State.Visuals.Thickness)
    line.Visible = false
    line.ZIndex = 2
    line.Parent = parent
    return line
end

local function setLine(line, from, to, thickness)
    local difference = to - from
    local length = difference.Magnitude
    line.Position = UDim2.fromOffset(from.X, from.Y)
    line.Size = UDim2.fromOffset(length, thickness or 1)
    line.Rotation = math.deg(math.atan2(difference.Y, difference.X))
    line.Visible = true
end

local function getBoundingScreenBox(character, camera)
    local cframe, size = character:GetBoundingBox()
    local minimumX, minimumY = math.huge, math.huge
    local maximumX, maximumY = -math.huge, -math.huge
    local visibleCorners = 0
    for _, x in ipairs({-0.5, 0.5}) do
        for _, y in ipairs({-0.5, 0.5}) do
            for _, z in ipairs({-0.5, 0.5}) do
                local point = cframe:PointToWorldSpace(Vector3.new(size.X * x, size.Y * y, size.Z * z))
                local screen = camera:WorldToViewportPoint(point)
                if screen.Z > 0 then
                    visibleCorners = visibleCorners + 1
                    minimumX = math.min(minimumX, screen.X)
                    minimumY = math.min(minimumY, screen.Y)
                    maximumX = math.max(maximumX, screen.X)
                    maximumY = math.max(maximumY, screen.Y)
                end
            end
        end
    end
    if visibleCorners == 0 then return nil end
    local viewport = camera.ViewportSize
    local left = math.clamp(minimumX, -viewport.X, viewport.X * 2)
    local right = math.clamp(maximumX, -viewport.X, viewport.X * 2)
    local top = math.clamp(minimumY, -viewport.Y, viewport.Y * 2)
    local bottom = math.clamp(maximumY, -viewport.Y, viewport.Y * 2)
    if right - left < 2 or bottom - top < 2 then return nil end
    return left, right, top, bottom
end

local function destroyESP(player)
    local record = espRecords[player]
    if not record then
        return
    end
    for _, object in pairs(record) do
        if typeof(object) == "Instance" then
            pcall(function()
                object:Destroy()
            end)
        end
    end
    espRecords[player] = nil
end

local function createESP(player)
    destroyESP(player)
    local record = {
        BoxTop = newLine(ScreenGui),
        BoxBottom = newLine(ScreenGui),
        BoxLeft = newLine(ScreenGui),
        BoxRight = newLine(ScreenGui),
        BoxFill = Instance.new("Frame"),
        HealthBg = newLine(ScreenGui, Color3.fromRGB(25, 25, 27)),
        HealthBar = newLine(ScreenGui, Color3.fromRGB(100, 230, 130)),
        Tracer = newLine(ScreenGui),
        HeadDot = Instance.new("Frame"),
        SkeletonLayer = Instance.new("Frame"),
        Arrow = textLabel(ScreenGui, "▲", UDim2.fromOffset(22, 22), nil, 18, Theme.Accent, Enum.TextXAlignment.Center),
        Label = textLabel(ScreenGui, "", UDim2.fromOffset(180, 18), nil, 11, Theme.Text, Enum.TextXAlignment.Center),
        Highlight = Instance.new("Highlight")
    }
    record.BoxFill.BorderSizePixel = 0
    record.BoxFill.BackgroundColor3 = Theme.Accent
    record.BoxFill.BackgroundTransparency = 0.82
    record.BoxFill.Visible = false
    record.BoxFill.ZIndex = 1
    record.BoxFill.Parent = ScreenGui
    record.HeadDot.AnchorPoint = Vector2.new(0.5, 0.5)
    record.HeadDot.BorderSizePixel = 0
    record.HeadDot.BackgroundColor3 = Theme.Accent
    record.HeadDot.Size = UDim2.fromOffset(6, 6)
    record.HeadDot.Visible = false
    record.HeadDot.ZIndex = 3
    record.HeadDot.Parent = ScreenGui
    round(record.HeadDot, 6)
    record.SkeletonLayer.BackgroundTransparency = 1
    record.SkeletonLayer.Size = UDim2.fromScale(1, 1)
    record.SkeletonLayer.Visible = false
    record.SkeletonLayer.ZIndex = 2
    record.SkeletonLayer.Parent = ScreenGui
    for _ = 1, 15 do newLine(record.SkeletonLayer) end
    record.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    record.Arrow.Visible = false
    record.Arrow.ZIndex = 4
    record.Label.AnchorPoint = Vector2.new(0.5, 1)
    record.Label.Visible = false
    record.Label.ZIndex = 3
    record.Highlight.FillColor = Theme.Accent
    record.Highlight.OutlineColor = Theme.Text
    record.Highlight.FillTransparency = 0.75
    record.Highlight.OutlineTransparency = 0.1
    record.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    record.Highlight.Enabled = false
    record.Highlight.Parent = ScreenGui
    espRecords[player] = record
    return record
end

local function updateSkeleton(record, character, camera, color)
    local pairsToDraw
    if character:FindFirstChild("UpperTorso") then
        pairsToDraw = {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }
    else
        pairsToDraw = {
            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
            {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
        }
    end
    local lines = record.SkeletonLayer:GetChildren()
    local used = 0
    for _, pair in ipairs(pairsToDraw) do
        local first = character:FindFirstChild(pair[1])
        local second = character:FindFirstChild(pair[2])
        if first and second then
            local a, visibleA = camera:WorldToViewportPoint(first.Position)
            local b, visibleB = camera:WorldToViewportPoint(second.Position)
            if visibleA and visibleB and a.Z > 0 and b.Z > 0 then
                used = used + 1
                local line = lines[used]
                if line then
                    line.BackgroundColor3 = color
                    setLine(line, Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), State.Visuals.Thickness)
                end
            end
        end
    end
    for index = used + 1, #lines do
        if lines[index]:IsA("GuiObject") then lines[index].Visible = false end
    end
    record.SkeletonLayer.Visible = used > 0
end

local function hideRecord(record)
    for key, object in pairs(record) do
        if key == "Highlight" then
            object.Enabled = false
        elseif object:IsA("GuiObject") then
            object.Visible = false
        end
    end
end

trackFeature("ESP", RunService.RenderStepped:Connect(function()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local localAlive, _, _, localRoot = getAlive(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local record = espRecords[player] or createESP(player)
            if not State.Visuals.Enabled then
                hideRecord(record)
            else
                local alive, character, humanoid, root = getAlive(player)
                local allowed = alive
                local distance = localAlive and localRoot and root and (root.Position - localRoot.Position).Magnitude or math.huge
                if not allowed or distance > State.Visuals.MaxDistance then
                    hideRecord(record)
                else
                    local left, right, top, bottom = getBoundingScreenBox(character, camera)
                    if not left then
                        hideRecord(record)
                        if State.Visuals.Offscreen then
                            local rootScreen = camera:WorldToViewportPoint(root.Position)
                            local center = camera.ViewportSize * 0.5
                            local direction = Vector2.new(rootScreen.X, rootScreen.Y) - center
                            if rootScreen.Z < 0 then direction = -direction end
                            if direction.Magnitude > 0 then
                                local edge = center + direction.Unit * math.min(center.X, center.Y) * 0.82
                                record.Arrow.Position = UDim2.fromOffset(edge.X, edge.Y)
                                record.Arrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
                                record.Arrow.TextColor3 = getPlayerVisualColor(player)
                                record.Arrow.Visible = true
                            end
                        end
                    else
                        local width = right - left
                        local height = bottom - top
                        local centerX = left + width * 0.5
                        local color = getPlayerVisualColor(player)
                        record.Arrow.Visible = false
                        for _, line in ipairs({record.BoxTop, record.BoxBottom, record.BoxLeft, record.BoxRight, record.Tracer}) do
                            line.BackgroundColor3 = color
                        end
                        if State.Visuals.Boxes then
                            setLine(record.BoxTop, Vector2.new(left, top), Vector2.new(right, top), State.Visuals.Thickness)
                            setLine(record.BoxBottom, Vector2.new(left, bottom), Vector2.new(right, bottom), State.Visuals.Thickness)
                            setLine(record.BoxLeft, Vector2.new(left, top), Vector2.new(left, bottom), State.Visuals.Thickness)
                            setLine(record.BoxRight, Vector2.new(right, top), Vector2.new(right, bottom), State.Visuals.Thickness)
                        else
                            record.BoxTop.Visible = false
                            record.BoxBottom.Visible = false
                            record.BoxLeft.Visible = false
                            record.BoxRight.Visible = false
                        end
                        record.BoxFill.Position = UDim2.fromOffset(left, top)
                        record.BoxFill.Size = UDim2.fromOffset(width, height)
                        record.BoxFill.BackgroundColor3 = color
                        record.BoxFill.Visible = State.Visuals.Boxes and State.Visuals.BoxFilled
                        if State.Visuals.Health then
                            local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
                            local barX = right + 6
                            setLine(record.HealthBg, Vector2.new(barX, bottom), Vector2.new(barX, top), 4)
                            local healthTop = bottom - height * ratio
                            setLine(record.HealthBar, Vector2.new(barX, bottom), Vector2.new(barX, healthTop), 2)
                            record.HealthBar.BackgroundColor3 = Color3.fromRGB(235, 70, 70):Lerp(Color3.fromRGB(80, 235, 120), ratio)
                        else
                            record.HealthBg.Visible = false
                            record.HealthBar.Visible = false
                        end
                        record.Label.Text = (State.Visuals.Names and player.DisplayName or "") .. (State.Visuals.Distance and string.format("  [%.0f]", distance) or "")
                        record.Label.Position = UDim2.fromOffset(centerX, top - 3)
                        record.Label.Visible = State.Visuals.Names or State.Visuals.Distance
                        local head = character:FindFirstChild("Head")
                        if State.Visuals.HeadDot and head then
                            local headScreen, headVisible = camera:WorldToViewportPoint(head.Position)
                            record.HeadDot.Position = UDim2.fromOffset(headScreen.X, headScreen.Y)
                            record.HeadDot.BackgroundColor3 = color
                            record.HeadDot.Visible = headVisible and headScreen.Z > 0
                        else
                            record.HeadDot.Visible = false
                        end
                        if State.Visuals.Skeleton then
                            updateSkeleton(record, character, camera, color)
                        else
                            record.SkeletonLayer.Visible = false
                        end
                        if State.Visuals.Tracers then
                            setLine(record.Tracer, Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y - 4), Vector2.new(centerX, bottom), State.Visuals.Thickness)
                        else
                            record.Tracer.Visible = false
                        end
                        record.Highlight.Adornee = character
                        record.Highlight.FillColor = color
                        record.Highlight.Enabled = State.Visuals.Chams
                    end
                end
            end
        end
    end
end))

trackConnection(Players.PlayerRemoving:Connect(destroyESP))

local freecamState
local flyApplied = false
local flyVelocity
local flyGyro
local flyRoot
local movementClock = 0

local function clearFlyController()
    if flyVelocity then pcall(function() flyVelocity:Destroy() end) end
    if flyGyro then pcall(function() flyGyro:Destroy() end) end
    flyVelocity = nil
    flyGyro = nil
    flyRoot = nil
end

local function ensureFlyController(root)
    if flyRoot == root and flyVelocity and flyVelocity.Parent and flyGyro and flyGyro.Parent then
        return
    end
    clearFlyController()
    flyRoot = root
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    flyVelocity.P = 3000
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
    flyGyro.P = 3000
    flyGyro.D = 250
    flyGyro.Parent = root
end

trackFeature("Movement", RunService.Heartbeat:Connect(function(deltaTime)
    movementClock = movementClock + deltaTime
    local alive, character, humanoid, root = getAlive(LocalPlayer)
    if not alive then
        clearFlyController()
        flyApplied = false
        return
    end
    if State.Movement.Speed then
        if State.Movement.SpeedMethod == "WalkSpeed" then
            humanoid.WalkSpeed = State.Movement.SpeedValue
        elseif State.Movement.SpeedMethod == "Velocity" then
            local direction = humanoid.MoveDirection
            root.AssemblyLinearVelocity = Vector3.new(direction.X * State.Movement.SpeedValue, root.AssemblyLinearVelocity.Y, direction.Z * State.Movement.SpeedValue)
        elseif humanoid.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + humanoid.MoveDirection * State.Movement.SpeedValue * deltaTime
        end
    end
    if State.Movement.Jump then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = State.Movement.JumpValue
    end
    if State.Movement.BunnyHop and humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    if State.Movement.Fly then
        local camera = Workspace.CurrentCamera
        if camera then
            ensureFlyController(root)
            local direction = Vector3.zero
            local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
            local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
            if forward.Magnitude > 0 then forward = forward.Unit end
            if right.Magnitude > 0 then right = right.Unit end
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.yAxis end
            if direction.Magnitude > 0 then direction = direction.Unit end
            humanoid.PlatformStand = true
            flyApplied = true
            flyVelocity.Velocity = direction * State.Movement.FlySpeed
            flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + camera.CFrame.LookVector)
        end
    elseif flyApplied then
        clearFlyController()
        humanoid.PlatformStand = humanoidDefaults[humanoid] and humanoidDefaults[humanoid].PlatformStand or false
        flyApplied = false
    end
    if State.Movement.Noclip then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                if originalCollision[descendant] == nil then
                    originalCollision[descendant] = descendant.CanCollide
                end
                descendant.CanCollide = false
            end
        end
    end
    if State.Movement.AntiFling then
        if root.AssemblyLinearVelocity.Magnitude > 250 then
            root.AssemblyLinearVelocity = Vector3.zero
        end
        if root.AssemblyAngularVelocity.Magnitude > 120 then
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end
    if State.Movement.Orbit and selectedPlayer then
        local targetAlive, _, _, targetRoot = getAlive(selectedPlayer)
        if targetAlive then
            local angle = movementClock * State.Movement.OrbitSpeed
            root.CFrame = CFrame.lookAt(targetRoot.Position + Vector3.new(math.cos(angle) * State.Movement.OrbitRadius, 1.5, math.sin(angle) * State.Movement.OrbitRadius), targetRoot.Position)
        end
    end
end))

trackFeature("World", RunService.RenderStepped:Connect(function(deltaTime)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    camera.FieldOfView = State.World.CameraFOV
    LocalPlayer.CameraMinZoomDistance = originalCameraMinZoom
    LocalPlayer.CameraMaxZoomDistance = State.World.ThirdPerson and math.max(40, originalCameraMaxZoom) or originalCameraMaxZoom
    if State.World.Freecam then
        if not freecamState then
            local pitch, yaw = camera.CFrame:ToOrientation()
            freecamState = {Position = camera.CFrame.Position, Pitch = pitch, Yaw = yaw, Type = camera.CameraType, Subject = camera.CameraSubject}
            camera.CameraType = Enum.CameraType.Scriptable
        end
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local mouseDelta = UserInputService:GetMouseDelta()
            freecamState.Yaw = freecamState.Yaw - mouseDelta.X * 0.0025
            freecamState.Pitch = math.clamp(freecamState.Pitch - mouseDelta.Y * 0.0025, -1.5, 1.5)
        end
        local rotation = CFrame.fromOrientation(freecamState.Pitch, freecamState.Yaw, 0)
        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + rotation.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - rotation.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + rotation.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - rotation.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.yAxis end
        if direction.Magnitude > 0 then
            freecamState.Position = freecamState.Position + direction.Unit * State.World.FreecamSpeed * 60 * deltaTime
        end
        camera.CFrame = CFrame.new(freecamState.Position) * rotation
    elseif freecamState then
        camera.CameraType = freecamState.Type or Enum.CameraType.Custom
        camera.CameraSubject = freecamState.Subject
        freecamState = nil
    end
end))

trackConnection(UserInputService.JumpRequest:Connect(function()
    if State.Movement.InfiniteJump then
        local _, humanoid = getCharacter(LocalPlayer)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if pendingKeybind then
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local bind = pendingKeybind
        pendingKeybind = nil
        if input.KeyCode == Enum.KeyCode.Backspace then
            State.Keybinds[bind.Id] = nil
            bind.Button.Text = "Bind"
            showToast("Keybind cleared")
            return
        end
        if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Unknown then
            bind.Button.Text = State.Keybinds[bind.Id] or "Bind"
            showToast("That key is reserved or unavailable")
            return
        end
        local keyName = input.KeyCode.Name
        for id, assignedKey in pairs(State.Keybinds) do
            if id ~= bind.Id and assignedKey == keyName then
                bind.Button.Text = State.Keybinds[bind.Id] or "Bind"
                showToast("Key is already assigned; clear it first")
                return
            end
        end
        State.Keybinds[bind.Id] = keyName
        bind.Button.Text = keyName
        showToast("Bound to " .. keyName)
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for id, assignedKey in pairs(State.Keybinds) do
            if assignedKey == input.KeyCode.Name and keybindActions[id] then
                keybindActions[id]()
                return
            end
        end
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and State.Movement.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local camera = Workspace.CurrentCamera
        local _, _, root = getCharacter(LocalPlayer)
        if camera and root then
            local mouse = LocalPlayer:GetMouse()
            local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
            if result then
                root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if ContentWindow.Visible then
            closeContentWindow()
        else
            openContentWindow()
        end
    end
end))

local function restoreCollision()
    for part, value in pairs(originalCollision) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = value
            end)
        end
    end
    table.clear(originalCollision)
end

local function restoreMovement()
    clearFlyController()
    flyApplied = false
    local character, humanoid, root = getCharacter(LocalPlayer)
    if humanoid then
        local defaults = humanoidDefaults[humanoid]
        humanoid.WalkSpeed = defaults and defaults.WalkSpeed or 16
        humanoid.JumpPower = defaults and defaults.JumpPower or 50
        humanoid.UseJumpPower = defaults and defaults.UseJumpPower ~= false
        humanoid.PlatformStand = defaults and defaults.PlatformStand or false
    end
    if root then
        root.AssemblyAngularVelocity = Vector3.zero
    end
    restoreCollision()
    Workspace.Gravity = originalGravity
end

local function applyWorld()
    if State.World.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
    if State.World.NoFog then
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000
    else
        Lighting.FogStart = originalLighting.FogStart
        Lighting.FogEnd = originalLighting.FogEnd
    end
    Workspace.Gravity = State.Movement.Gravity and State.Movement.GravityValue or originalGravity
end

local HomePage = pages.Home
local HomeCard = createCard(HomePage, "TasuHub")
local HomeBrand = textLabel(HomeCard, "TasuHub", UDim2.new(1, 0, 0, 32), nil, 24, Theme.Text)
HomeBrand.Font = Enum.Font.GothamBold
local HomeSubtitle = addNote(HomeCard, "Live client test workspace")
HomeSubtitle.TextSize = 12
local StatusCard = createCard(HomePage, "Live Session")
local StatusText = addNote(StatusCard, "")
local NavigationCard = createCard(HomePage, "Categories")
local function addHomeCategory(title, description, category)
    local tile = Instance.new("TextButton")
    tile.AutoButtonColor = false
    tile.Text = ""
    tile.BackgroundColor3 = Theme.Surface2
    tile.BackgroundTransparency = 0.08
    tile.Size = UDim2.new(1, 0, 0, 62)
    tile.Parent = NavigationCard
    round(tile, 10)
    local tileStroke = stroke(tile, Color3.fromRGB(188, 220, 246), 1, 0.14)
    gradient(tile, Color3.fromRGB(255, 255, 255), Color3.fromRGB(232, 246, 255), 0)
    local iconFrame = Instance.new("Frame")
    iconFrame.BackgroundColor3 = Theme.AccentSoft
    iconFrame.Size = UDim2.fromOffset(42, 42)
    iconFrame.Position = UDim2.fromOffset(10, 10)
    iconFrame.Parent = tile
    round(iconFrame, 12)
    vectorIcon(iconFrame, category)
    local titleLabel = textLabel(tile, title, UDim2.new(1, -72, 0, 26), UDim2.fromOffset(64, 7), 16, Theme.Text)
    titleLabel.Font = Enum.Font.GothamSemibold
    local detailLabel = textLabel(tile, description, UDim2.new(1, -72, 0, 20), UDim2.fromOffset(64, 32), 11, Theme.Muted)
    tile.MouseEnter:Connect(function()
        animate(tile, {BackgroundColor3 = Color3.fromRGB(224, 241, 255)}, 0.14)
        animate(tileStroke, {Color = Theme.Accent, Transparency = 0.02}, 0.14)
    end)
    tile.MouseLeave:Connect(function()
        animate(tile, {BackgroundColor3 = Theme.Surface2}, 0.16)
        animate(tileStroke, {Color = Color3.fromRGB(188, 220, 246), Transparency = 0.14}, 0.16)
    end)
    tile.Activated:Connect(function()
        showCategory(category)
    end)
end
addHomeCategory("Aim", "Targeting, field of view and prediction", "Aim")
addHomeCategory("Visuals", "Live player overlays and visual telemetry", "Visuals")
addHomeCategory("Movement", "Movement and world-physics test controls", "Movement")
addHomeCategory("World", "Camera, lighting and waypoint controls", "World")
addHomeCategory("Players", "Select, inspect and observe live players", "Players")
addHomeCategory("Catalog", "Your custom game-script collection", "Catalog")
addAction(HomeCard, "Unload TasuHub", function()
    if unload then unload() end
end)

local statusClock = 0
trackConnection(RunService.Heartbeat:Connect(function(deltaTime)
    statusClock = statusClock + deltaTime
    if statusClock < 0.25 then return end
    statusClock = 0
    local ping = "n/a"
    local ok, value = pcall(function()
        return LocalPlayer:GetNetworkPing() * 1000
    end)
    if ok then ping = string.format("%.0f ms", value) end
    StatusText.Text = string.format("Player: %s   •   PlaceId: %s   •   Players: %d   •   Ping: %s   •   Target: %s", LocalPlayer.Name, tostring(game.PlaceId), #Players:GetPlayers(), ping, currentTarget and currentTarget.Player.Name or "None")
end))

local AimPage = pages.Aim
local AimCard = createCard(AimPage, "Live Aim")
addToggle(AimCard, "Enabled", function() return State.Aim.Enabled end, function(value) State.Aim.Enabled = value end)
addToggle(AimCard, "Hold Right Mouse", function() return State.Aim.HoldRightMouse end, function(value) State.Aim.HoldRightMouse = value end)
addCycle(AimCard, "Method", {"Camera", "Mouse"}, function() return State.Aim.Method end, function(value) State.Aim.Method = value end)
addCycle(AimCard, "Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, function() return State.Aim.TargetPart end, function(value) State.Aim.TargetPart = value end)
addToggle(AimCard, "Team Check", function() return State.Aim.TeamCheck end, function(value) State.Aim.TeamCheck = value end)
addToggle(AimCard, "Wall Check", function() return State.Aim.WallCheck end, function(value) State.Aim.WallCheck = value end)
addToggle(AimCard, "Prediction", function() return State.Aim.Prediction end, function(value) State.Aim.Prediction = value end)
addToggle(AimCard, "Show FOV", function() return State.Aim.ShowFOV end, function(value) State.Aim.ShowFOV = value end)
addSlider(AimCard, "FOV Radius", 20, 600, function() return State.Aim.FOV end, function(value) State.Aim.FOV = value end)
addSlider(AimCard, "Smoothing", 0, 0.95, function() return State.Aim.Smoothing end, function(value) State.Aim.Smoothing = value end, 2)
addSlider(AimCard, "Prediction Time", 0, 0.5, function() return State.Aim.PredictionTime end, function(value) State.Aim.PredictionTime = value end, 2)
addSlider(AimCard, "Maximum Distance", 50, 5000, function() return State.Aim.MaxDistance end, function(value) State.Aim.MaxDistance = value end)

local VisualPage = pages.Visuals
local VisualCard = createCard(VisualPage, "Player ESP")
addToggle(VisualCard, "Enabled", function() return State.Visuals.Enabled end, function(value) State.Visuals.Enabled = value end)
addToggle(VisualCard, "Boxes", function() return State.Visuals.Boxes end, function(value) State.Visuals.Boxes = value end)
addToggle(VisualCard, "Box Filled", function() return State.Visuals.BoxFilled end, function(value) State.Visuals.BoxFilled = value end)
addToggle(VisualCard, "Names", function() return State.Visuals.Names end, function(value) State.Visuals.Names = value end)
addToggle(VisualCard, "Distance", function() return State.Visuals.Distance end, function(value) State.Visuals.Distance = value end)
addToggle(VisualCard, "Health", function() return State.Visuals.Health end, function(value) State.Visuals.Health = value end)
addToggle(VisualCard, "Head Dot", function() return State.Visuals.HeadDot end, function(value) State.Visuals.HeadDot = value end)
addToggle(VisualCard, "Tracers", function() return State.Visuals.Tracers end, function(value) State.Visuals.Tracers = value end)
addToggle(VisualCard, "Chams", function() return State.Visuals.Chams end, function(value) State.Visuals.Chams = value end)
addToggle(VisualCard, "Skeleton", function() return State.Visuals.Skeleton end, function(value) State.Visuals.Skeleton = value end)
addToggle(VisualCard, "Offscreen Arrows", function() return State.Visuals.Offscreen end, function(value) State.Visuals.Offscreen = value end)
addToggle(VisualCard, "Use Team Colors", function() return State.Visuals.TeamColors end, function(value) State.Visuals.TeamColors = value end)
addSlider(VisualCard, "Maximum Distance", 100, 5000, function() return State.Visuals.MaxDistance end, function(value) State.Visuals.MaxDistance = value end)
addSlider(VisualCard, "Line Thickness", 1, 4, function() return State.Visuals.Thickness end, function(value) State.Visuals.Thickness = value end)

local MovementPage = pages.Movement
local MoveCard = createCard(MovementPage, "Movement")
addToggle(MoveCard, "Speed", function() return State.Movement.Speed end, function(value)
    State.Movement.Speed = value
    if not value then
        local _, humanoid = getCharacter(LocalPlayer)
        if humanoid then humanoid.WalkSpeed = humanoidDefaults[humanoid] and humanoidDefaults[humanoid].WalkSpeed or 16 end
    end
end)
addCycle(MoveCard, "Speed Method", {"WalkSpeed", "Velocity", "CFrame"}, function() return State.Movement.SpeedMethod end, function(value) State.Movement.SpeedMethod = value end)
addSlider(MoveCard, "Speed Value", 16, 200, function() return State.Movement.SpeedValue end, function(value) State.Movement.SpeedValue = value end)
addToggle(MoveCard, "Jump Power", function() return State.Movement.Jump end, function(value)
    State.Movement.Jump = value
    if not value then
        local _, humanoid = getCharacter(LocalPlayer)
        local defaults = humanoid and humanoidDefaults[humanoid]
        if humanoid and defaults then
            humanoid.JumpPower = defaults.JumpPower
            humanoid.UseJumpPower = defaults.UseJumpPower
        end
    end
end)
addSlider(MoveCard, "Jump Value", 50, 300, function() return State.Movement.JumpValue end, function(value) State.Movement.JumpValue = value end)
addToggle(MoveCard, "Infinite Jump", function() return State.Movement.InfiniteJump end, function(value) State.Movement.InfiniteJump = value end)
addToggle(MoveCard, "Bunny Hop", function() return State.Movement.BunnyHop end, function(value) State.Movement.BunnyHop = value end)
local FlyCard = createCard(MovementPage, "Flight and Collision")
addToggle(FlyCard, "Fly", function() return State.Movement.Fly end, function(value) State.Movement.Fly = value end)
addCycle(FlyCard, "Fly Method", {"Velocity", "CFrame"}, function() return State.Movement.FlyMethod end, function(value) State.Movement.FlyMethod = value end)
addSlider(FlyCard, "Fly Speed", 10, 250, function() return State.Movement.FlySpeed end, function(value) State.Movement.FlySpeed = value end)
addToggle(FlyCard, "Noclip", function() return State.Movement.Noclip end, function(value)
    State.Movement.Noclip = value
    if not value then restoreCollision() end
end)
addToggle(FlyCard, "Ctrl + Click Teleport", function() return State.Movement.ClickTP end, function(value) State.Movement.ClickTP = value end)
addToggle(FlyCard, "Anti Fling", function() return State.Movement.AntiFling end, function(value) State.Movement.AntiFling = value end)
local GravityCard = createCard(MovementPage, "World Physics")
addToggle(GravityCard, "Custom Gravity", function() return State.Movement.Gravity end, function(value)
    State.Movement.Gravity = value
    Workspace.Gravity = value and State.Movement.GravityValue or originalGravity
end)
addSlider(GravityCard, "Gravity", 0, 300, function() return State.Movement.GravityValue end, function(value)
    State.Movement.GravityValue = value
    if State.Movement.Gravity then Workspace.Gravity = value end
end, 1)
addToggle(GravityCard, "Orbit Selected Player", function() return State.Movement.Orbit end, function(value) State.Movement.Orbit = value end)
addSlider(GravityCard, "Orbit Radius", 2, 30, function() return State.Movement.OrbitRadius end, function(value) State.Movement.OrbitRadius = value end)
addSlider(GravityCard, "Orbit Speed", 0.2, 8, function() return State.Movement.OrbitSpeed end, function(value) State.Movement.OrbitSpeed = value end, 1)

local WorldPage = pages.World
local LightingCard = createCard(WorldPage, "Lighting")
addToggle(LightingCard, "Fullbright", function() return State.World.Fullbright end, function(value) State.World.Fullbright = value applyWorld() end)
addToggle(LightingCard, "Remove Fog", function() return State.World.NoFog end, function(value) State.World.NoFog = value applyWorld() end)
local CameraCard = createCard(WorldPage, "Camera")
addSlider(CameraCard, "Field of View", 40, 120, function() return State.World.CameraFOV end, function(value) State.World.CameraFOV = value end)
addToggle(CameraCard, "Third Person", function() return State.World.ThirdPerson end, function(value) State.World.ThirdPerson = value end)
addToggle(CameraCard, "Freecam", function() return State.World.Freecam end, function(value) State.World.Freecam = value end)
addSlider(CameraCard, "Freecam Speed", 0.2, 8, function() return State.World.FreecamSpeed end, function(value) State.World.FreecamSpeed = value end, 1)
local WaypointCard = createCard(WorldPage, "Waypoints")
local waypointNameInput = addInput(WaypointCard, "Waypoint name", "")
local waypointStatus = addNote(WaypointCard, "No waypoint selected")
addAction(WaypointCard, "Save Current Position", function()
    local _, _, root = getCharacter(LocalPlayer)
    if not root then return end
    local components = {root.CFrame:GetComponents()}
    table.insert(State.Waypoints, {Name = waypointNameInput.Text ~= "" and waypointNameInput.Text or "Waypoint " .. tostring(#State.Waypoints + 1), CFrame = components})
    selectedWaypoint = #State.Waypoints
    waypointStatus.Text = State.Waypoints[selectedWaypoint].Name
end)
addAction(WaypointCard, "Next Waypoint", function()
    if #State.Waypoints == 0 then waypointStatus.Text = "No waypoints" return end
    selectedWaypoint = selectedWaypoint % #State.Waypoints + 1
    waypointStatus.Text = State.Waypoints[selectedWaypoint].Name
end)
addAction(WaypointCard, "Teleport to Waypoint", function()
    local entry = State.Waypoints[selectedWaypoint]
    local _, _, root = getCharacter(LocalPlayer)
    if entry and root and type(entry.CFrame) == "table" and #entry.CFrame >= 12 then
        root.CFrame = CFrame.new(table.unpack(entry.CFrame))
    end
end)
addAction(WaypointCard, "Delete Selected Waypoint", function()
    if State.Waypoints[selectedWaypoint] then table.remove(State.Waypoints, selectedWaypoint) end
    selectedWaypoint = math.clamp(selectedWaypoint, 1, math.max(1, #State.Waypoints))
    waypointStatus.Text = State.Waypoints[selectedWaypoint] and State.Waypoints[selectedWaypoint].Name or "No waypoint selected"
end)

local PlayersPage = pages.Players
local PlayerCard = createCard(PlayersPage, "Live Players")
local playerSearch = addInput(PlayerCard, "Search username or display name", "")
local PlayerList = Instance.new("ScrollingFrame")
PlayerList.BackgroundColor3 = Theme.Surface2
PlayerList.BackgroundTransparency = 0.2
PlayerList.BorderSizePixel = 0
PlayerList.CanvasSize = UDim2.new()
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollBarImageColor3 = Theme.Accent
PlayerList.ScrollBarThickness = 3
PlayerList.Size = UDim2.new(1, 0, 0, 340)
PlayerList.Parent = PlayerCard
round(PlayerList, 10)
stroke(PlayerList, Color3.fromRGB(188, 220, 246), 1, 0.16)
local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.Parent = PlayerList
local PlayerListPadding = Instance.new("UIPadding")
PlayerListPadding.PaddingLeft = UDim.new(0, 6)
PlayerListPadding.PaddingRight = UDim.new(0, 6)
PlayerListPadding.PaddingTop = UDim.new(0, 6)
PlayerListPadding.PaddingBottom = UDim.new(0, 6)
PlayerListPadding.Parent = PlayerList
local playerRows = {}

local function createPlayerRow(player)
    local row = Instance.new("Frame")
    row.Name = tostring(player.UserId)
    row.BackgroundColor3 = Theme.Surface
    row.BackgroundTransparency = 0.06
    row.Size = UDim2.new(1, 0, 0, 58)
    row.Parent = PlayerList
    round(row, 9)
    stroke(row, Color3.fromRGB(198, 226, 248), 1, 0.2)
    local avatar = Instance.new("ImageLabel")
    avatar.BackgroundColor3 = Theme.AccentSoft
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
    avatar.Size = UDim2.fromOffset(42, 42)
    avatar.Position = UDim2.fromOffset(8, 8)
    avatar.Parent = row
    round(avatar, 21)
    local name = textLabel(row, player.DisplayName, UDim2.new(1, -252, 0, 21), UDim2.fromOffset(60, 7), 13, Theme.Text)
    name.Font = Enum.Font.GothamSemibold
    local details = textLabel(row, "", UDim2.new(1, -252, 0, 18), UDim2.fromOffset(60, 31), 10, Theme.Muted)
    local healthTrack = Instance.new("Frame")
    healthTrack.BackgroundColor3 = Color3.fromRGB(220, 234, 244)
    healthTrack.Size = UDim2.fromOffset(94, 5)
    healthTrack.Position = UDim2.new(1, -185, 0, 12)
    healthTrack.Parent = row
    round(healthTrack, 5)
    local healthFill = Instance.new("Frame")
    healthFill.BackgroundColor3 = Color3.fromRGB(93, 202, 133)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.Parent = healthTrack
    round(healthFill, 5)
    local healthText = textLabel(row, "", UDim2.fromOffset(94, 18), UDim2.new(1, -185, 0, 21), 10, Theme.Muted, Enum.TextXAlignment.Center)
    local view = button(row, "View", UDim2.fromOffset(48, 30), UDim2.new(1, -82, 0.5, -15))
    local teleport = button(row, "TP", UDim2.fromOffset(30, 30), UDim2.new(1, -34, 0.5, -15))
    view.TextSize = 10
    teleport.TextSize = 10
    view.Activated:Connect(function()
        local alive, _, humanoid = getAlive(player)
        local camera = Workspace.CurrentCamera
        if alive and camera then
            if camera.CameraSubject == humanoid then
                local _, localHumanoid = getCharacter(LocalPlayer)
                if localHumanoid then camera.CameraSubject = localHumanoid end
            else
                selectedPlayer = player
                camera.CameraSubject = humanoid
            end
        end
    end)
    teleport.Activated:Connect(function()
        local alive, _, _, targetRoot = getAlive(player)
        local _, _, root = getCharacter(LocalPlayer)
        if alive and root then root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4) end
    end)
    playerRows[player] = {Row = row, Name = name, Details = details, HealthFill = healthFill, HealthText = healthText, View = view}
end

local function refreshPlayerRows()
    local query = string.lower(playerSearch.Text)
    local _, _, localRoot = getCharacter(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not playerRows[player] then createPlayerRow(player) end
            local record = playerRows[player]
            local matches = query == "" or string.find(string.lower(player.Name), query, 1, true) or string.find(string.lower(player.DisplayName), query, 1, true)
            record.Row.Visible = matches
            if matches then
                local alive, _, humanoid, root = getAlive(player)
                local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
                local ratio = alive and math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1) or 0
                record.Name.Text = player.DisplayName .. "  @" .. player.Name
                record.Details.Text = string.format("%s  •  %.0f studs", areTeammates(player, LocalPlayer) and "Teammate" or "Other", distance)
                record.HealthFill.Size = UDim2.fromScale(ratio, 1)
                record.HealthText.Text = string.format("%.0f%%", ratio * 100)
                local camera = Workspace.CurrentCamera
                record.View.Text = camera and camera.CameraSubject == humanoid and "Stop" or "View"
            end
        end
    end
    for player, record in pairs(playerRows) do
        if player.Parent ~= Players then
            record.Row:Destroy()
            playerRows[player] = nil
        end
    end
end
playerSearch.FocusLost:Connect(refreshPlayerRows)
local playerStatusClock = 0
trackConnection(RunService.Heartbeat:Connect(function(deltaTime)
    playerStatusClock = playerStatusClock + deltaTime
    if playerStatusClock < 0.5 then return end
    playerStatusClock = 0
    refreshPlayerRows()
end))

local function sanitizeName(value)
    return string.gsub(tostring(value), "[^%w_%-]", "_")
end

local function httpGet(url)
    local request = getRequest()
    if request then
        local ok, response = pcall(request, {Url = url, Method = "GET"})
        if not ok or type(response) ~= "table" then
            return nil, "Request failed"
        end
        local statusCode = response.StatusCode or response.Status or response.status_code
        if statusCode and statusCode >= 400 then
            return nil, "HTTP " .. tostring(statusCode)
        end
        return response.Body or response.body
    end
    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        return nil, "Request failed"
    end
    return response
end

local function parsePlaceId(value)
    local direct = tonumber(value)
    if direct then return math.floor(direct) end
    local text = tostring(value or "")
    local matched = string.match(text, "roblox%.com/games/(%d+)") or string.match(text, "[?&]placeId=(%d+)") or string.match(text, "/places/(%d+)")
    return matched and tonumber(matched) or nil
end

local CatalogPage = pages.Catalog
local CatalogCard = createCard(CatalogPage, "Custom Game Catalog")
addNote(CatalogCard, "The catalog starts empty. Entries are saved only when you save a config.")
local catalogName = addInput(CatalogCard, "Game name", "")
local catalogPlace = addInput(CatalogCard, "PlaceId or Roblox game URL", tostring(game.PlaceId))
local catalogUrl = addInput(CatalogCard, "HTTPS script URL", "")
local catalogStatus = addNote(CatalogCard, "No catalog entries")
local catalogBanner = Instance.new("ImageLabel")
catalogBanner.BackgroundColor3 = Theme.Surface2
catalogBanner.Image = ""
catalogBanner.Size = UDim2.new(1, 0, 0, 150)
catalogBanner.ScaleType = Enum.ScaleType.Crop
catalogBanner.Parent = CatalogCard
round(catalogBanner, 6)
local catalogIndex = 1
local pendingRun = false
local runButton
local function currentCatalogEntry()
    return State.Catalog[catalogIndex]
end
local function updateCatalogStatus()
    local entry = currentCatalogEntry()
    pendingRun = false
    if runButton then runButton.Text = "Run Selected Script" end
    if not entry then
        catalogStatus.Text = "No catalog entries"
        catalogBanner.Image = ""
        return
    end
    catalogStatus.Text = string.format("%d/%d   •   %s   •   PlaceId %s", catalogIndex, #State.Catalog, entry.Name, tostring(entry.PlaceId))
    catalogName.Text = entry.Name
    catalogPlace.Text = tostring(entry.PlaceId)
    catalogUrl.Text = entry.Url or ""
    catalogBanner.Image = entry.BannerAsset or ""
end
local function fetchBanner(entry)
    if not entry or not capabilities.Http or not capabilities.Files or not capabilities.Folders or not capabilities.CustomAsset then
        return false
    end
    local universeMetadata, errorMessage = httpGet("https://apis.roblox.com/universes/v1/places/" .. tostring(entry.PlaceId) .. "/universe")
    if not universeMetadata then
        catalogStatus.Text = errorMessage
        return false
    end
    local universeOk, universeDecoded = pcall(HttpService.JSONDecode, HttpService, universeMetadata)
    local universeId = universeOk and universeDecoded and universeDecoded.universeId
    if not universeId then
        catalogStatus.Text = "Universe unavailable"
        return false
    end
    local metadata
    metadata, errorMessage = httpGet("https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=" .. tostring(universeId) .. "&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false")
    if not metadata then
        catalogStatus.Text = errorMessage
        return false
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, metadata)
    local imageUrl = ok and decoded and decoded.data and decoded.data[1] and decoded.data[1].thumbnails and decoded.data[1].thumbnails[1] and decoded.data[1].thumbnails[1].imageUrl
    if not imageUrl then
        catalogStatus.Text = "Banner unavailable"
        return false
    end
    local imageBody, imageError = httpGet(imageUrl)
    if not imageBody then
        catalogStatus.Text = imageError
        return false
    end
    ensureFolder("TasuHub/Catalog/Banners")
    local path = "TasuHub/Catalog/Banners/" .. sanitizeName(entry.PlaceId) .. ".png"
    local writefile = resolveGlobal("writefile")
    local saved = pcall(writefile, path, imageBody)
    if not saved then
        return false
    end
    entry.BannerAsset = getCustomAsset(path)
    catalogBanner.Image = entry.BannerAsset or ""
    return true
end
addAction(CatalogCard, "Add Entry", function()
    local placeId = parsePlaceId(catalogPlace.Text)
    if catalogName.Text == "" or not placeId then
        catalogStatus.Text = "Name and valid PlaceId or Roblox URL required"
        return
    end
    table.insert(State.Catalog, {Name = catalogName.Text, PlaceId = placeId, Url = catalogUrl.Text})
    catalogIndex = #State.Catalog
    updateCatalogStatus()
    task.spawn(fetchBanner, currentCatalogEntry())
end)
addAction(CatalogCard, "Update Selected Entry", function()
    local entry = currentCatalogEntry()
    local placeId = parsePlaceId(catalogPlace.Text)
    if not entry or not placeId then return end
    entry.Name = catalogName.Text
    entry.PlaceId = placeId
    entry.Url = catalogUrl.Text
    entry.BannerAsset = nil
    updateCatalogStatus()
    task.spawn(fetchBanner, entry)
end)
addAction(CatalogCard, "Next Entry", function()
    if #State.Catalog == 0 then return end
    catalogIndex = catalogIndex % #State.Catalog + 1
    updateCatalogStatus()
    if currentCatalogEntry() and not currentCatalogEntry().BannerAsset then task.spawn(fetchBanner, currentCatalogEntry()) end
end)
addAction(CatalogCard, "Previous Entry", function()
    if #State.Catalog == 0 then return end
    catalogIndex = (catalogIndex - 2) % #State.Catalog + 1
    updateCatalogStatus()
    if currentCatalogEntry() and not currentCatalogEntry().BannerAsset then task.spawn(fetchBanner, currentCatalogEntry()) end
end)
addAction(CatalogCard, "Delete Selected Entry", function()
    if State.Catalog[catalogIndex] then table.remove(State.Catalog, catalogIndex) end
    catalogIndex = math.clamp(catalogIndex, 1, math.max(1, #State.Catalog))
    updateCatalogStatus()
end)
runButton = addAction(CatalogCard, "Run Selected Script", function(item)
    local entry = currentCatalogEntry()
    if not entry or type(entry.Url) ~= "string" or entry.Url == "" then
        catalogStatus.Text = "Selected entry has no URL"
        return
    end
    if not string.match(entry.Url, "^https://") then
        catalogStatus.Text = "HTTPS URL required"
        return
    end
    if not capabilities.LoadString or not capabilities.Http then
        catalogStatus.Text = "Executor cannot load URL scripts"
        return
    end
    if not pendingRun then
        pendingRun = true
        item.Text = "Confirm Run"
        catalogStatus.Text = "Press again to download and run this entry"
        return
    end
    pendingRun = false
    item.Text = "Run Selected Script"
    local source, errorMessage = httpGet(entry.Url)
    if not source then
        catalogStatus.Text = errorMessage
        return
    end
    local chunk, compileError = loadstring(source, "TasuCatalog:" .. entry.Name)
    if not chunk then
        catalogStatus.Text = tostring(compileError)
        return
    end
    local ok, runtimeError = pcall(chunk)
    catalogStatus.Text = ok and "Script completed" or tostring(runtimeError)
end)
updateCatalogStatus()

local ExplorerPage = pages.Explorer
local ExplorerCard = createCard(ExplorerPage, "Read-only Instance Explorer")
local explorerSearch = addInput(ExplorerCard, "Search instance name or class", "")
local explorerStatus = addNote(ExplorerCard, "Enter a search term")
local explorerResults = {}
local explorerIndex = 1
local function scanExplorer()
    explorerResults = {}
    explorerIndex = 1
    local query = string.lower(explorerSearch.Text)
    if query == "" then
        explorerStatus.Text = "Enter a search term"
        return
    end
    for _, instance in ipairs(game:GetDescendants()) do
        if #explorerResults >= 500 then break end
        if string.find(string.lower(instance.Name), query, 1, true) or string.find(string.lower(instance.ClassName), query, 1, true) then
            table.insert(explorerResults, instance)
        end
    end
    local selected = explorerResults[1]
    explorerStatus.Text = selected and string.format("1/%d   •   %s [%s]   •   %s", #explorerResults, selected.Name, selected.ClassName, selected:GetFullName()) or "No results"
end
addAction(ExplorerCard, "Search", scanExplorer)
addAction(ExplorerCard, "Next Result", function()
    if #explorerResults == 0 then return end
    explorerIndex = explorerIndex % #explorerResults + 1
    local selected = explorerResults[explorerIndex]
    explorerStatus.Text = string.format("%d/%d   •   %s [%s]   •   %s", explorerIndex, #explorerResults, selected.Name, selected.ClassName, selected:GetFullName())
end)
addAction(ExplorerCard, "Copy Selected Path", function()
    local selected = explorerResults[explorerIndex]
    local setclipboard = resolveGlobal("setclipboard") or resolveGlobal("toclipboard")
    if selected and setclipboard then pcall(setclipboard, selected:GetFullName()) end
end)

local function configPayload()
    local payload = deepCopy(State)
    payload.Interface = {Title = State.Interface.Title}
    for _, entry in ipairs(payload.Catalog) do
        entry.BannerAsset = nil
    end
    return payload
end

local function merge(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then return end
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" and key ~= "Catalog" and key ~= "Waypoints" then
            merge(target[key], value)
        else
            target[key] = deepCopy(value)
        end
    end
end

local function saveConfig(name)
    if not capabilities.Files or not capabilities.Folders then
        return false, "Filesystem unsupported"
    end
    ensureFolder("TasuHub/Configs")
    local path = "TasuHub/Configs/" .. sanitizeName(name) .. ".json"
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, configPayload())
    if not ok then return false, encoded end
    local writefile = resolveGlobal("writefile")
    local saved, errorMessage = pcall(writefile, path, encoded)
    return saved, saved and path or errorMessage
end

local function loadConfig(name)
    if not capabilities.Files then
        return false, "Filesystem unsupported"
    end
    local path = "TasuHub/Configs/" .. sanitizeName(name) .. ".json"
    local isfile = resolveGlobal("isfile")
    if type(isfile) == "function" and not isfile(path) then
        return false, "Config not found"
    end
    local readfile = resolveGlobal("readfile")
    local ok, raw = pcall(readfile, path)
    if not ok then return false, raw end
    local decodedOk, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not decodedOk or type(decoded) ~= "table" then return false, decoded end
    merge(State, decoded)
    applyWorld()
    TopTitle.Text = State.Interface.Title or Theme.Title
    catalogIndex = math.clamp(catalogIndex, 1, math.max(1, #State.Catalog))
    refreshControls()
    return true, path
end

local ConfigPage = pages.Configs
local ConfigCard = createCard(ConfigPage, "Manual Config Storage")
addNote(ConfigCard, "Configs never load automatically when the hub is injected.")
local configName = addInput(ConfigCard, "Config name", "default")
local configStatus = addNote(ConfigCard, "Ready")
addAction(ConfigCard, "Save Config", function()
    local ok, message = saveConfig(configName.Text)
    configStatus.Text = ok and "Saved: " .. tostring(message) or "Error: " .. tostring(message)
end)
addAction(ConfigCard, "Load Config", function()
    local ok, message = loadConfig(configName.Text)
    configStatus.Text = ok and "Loaded: " .. tostring(message) or "Error: " .. tostring(message)
    updateCatalogStatus()
end)
addAction(ConfigCard, "Reset to Defaults", function()
    State = deepCopy(Defaults)
    State.World.CameraFOV = originalCameraFOV
    Theme = State.Interface
    restoreMovement()
    applyWorld()
    TopTitle.Text = State.Interface.Title
    if env.TasuHub then env.TasuHub.State = State end
    refreshControls()
    updateCatalogStatus()
    configStatus.Text = "Defaults restored"
end)

unload = function()
    if unloaded then return end
    unloaded = true
    State.Aim.Enabled = false
    State.Visuals.Enabled = false
    State.Movement.Fly = false
    State.Movement.Noclip = false
    State.Movement.Orbit = false
    State.World.Freecam = false
    restoreMovement()
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.FogStart = originalLighting.FogStart
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    local camera = Workspace.CurrentCamera
    if camera then
        camera.FieldOfView = originalCameraFOV
        camera.CameraType = Enum.CameraType.Custom
        local _, humanoid = getCharacter(LocalPlayer)
        if humanoid then camera.CameraSubject = humanoid end
    end
    LocalPlayer.CameraMinZoomDistance = originalCameraMinZoom
    LocalPlayer.CameraMaxZoomDistance = originalCameraMaxZoom
    for _, player in ipairs(Players:GetPlayers()) do destroyESP(player) end
    for _, list in pairs(featureConnections) do
        for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
    end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for _, instance in ipairs(instances) do pcall(function() instance:Destroy() end) end
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    if env.TasuHub and env.TasuHub.Unload == unload then
        env.TasuHub = nil
    end
end

env.TasuHub = {
    Version = "1.2.0",
    State = State,
    Capabilities = capabilities,
    Open = function() ContentWindow.Visible = true end,
    Close = function() ContentWindow.Visible = false end,
    Toggle = function() ContentWindow.Visible = not ContentWindow.Visible end,
    ShowCategory = showCategory,
    SaveConfig = saveConfig,
    LoadConfig = loadConfig,
    Unload = unload
}

showCategory("Home")
