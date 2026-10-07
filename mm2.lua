local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then error("[TasuHub/MM2] LocalPlayer is unavailable") end

local env = getgenv and getgenv() or _G
if env.TasuHubMM2 and type(env.TasuHubMM2.Unload) == "function" then
    pcall(env.TasuHubMM2.Unload)
end

local hub = env.TasuHub
if type(hub) ~= "table" or type(hub.GetGameUIContext) ~= "function" then
    error("[TasuHub/MM2] Shared TasuHub UI context is unavailable")
end
local context = hub.GetGameUIContext("mm2")
if type(context) ~= "table" or not context.Parent then
    error("[TasuHub/MM2] Shared game-window context is invalid")
end

local theme, fonts = context.Theme, context.Fonts
local motion, layout = context.Motion, context.Layout
local animate = context.Animate
local playSound = context.PlaySound or function() end
local inputService = context.InputService

local State = {
    Enabled = false,
    PlayerESP = true,
    GunDropESP = true,
    AutoPickup = false,
    AutoFire = false
}
local connections = {}
local playerESP = {}
local gunHighlight
local unloaded = false

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function outline(object, thickness, transparency, color)
    local item = Instance.new("UIStroke")
    item.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    item.Color = color or theme.Base
    item.Thickness = thickness
    item.Transparency = transparency or 0
    item.Parent = object
    return item
end

local function characterInfo(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    return character, humanoid, root
end

local function findTool(player, toolName)
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    local tool = character and character:FindFirstChild(toolName)
    if not tool and backpack then tool = backpack:FindFirstChild(toolName) end
    return tool and tool:IsA("Tool") and tool or nil
end

local function replicatedRole(player)
    for _, container in ipairs({player, player.Character}) do
        if container then
            for _, name in ipairs({"Role", "ServerRole", "MM2ServerRole"}) do
                local value = container:GetAttribute(name)
                local object = container:FindFirstChild(name)
                if object and object:IsA("StringValue") then value = object.Value end
                if type(value) == "string" then
                    local lowered = string.lower(value)
                    if string.find(lowered, "murder", 1, true) then return "Murderer" end
                    if string.find(lowered, "sheriff", 1, true) then return "Sheriff" end
                end
            end
        end
    end
    if findTool(player, "Knife") then return "Murderer" end
    if findTool(player, "Gun") then return "Sheriff" end
    return "Innocent"
end

local function destroyPlayerESP(player)
    local record = playerESP[player]
    if not record then return end
    pcall(function() record.Highlight:Destroy() end)
    pcall(function() record.Billboard:Destroy() end)
    playerESP[player] = nil
end

local function ensurePlayerESP(player)
    local record = playerESP[player]
    if record then return record end
    local highlight = Instance.new("Highlight")
    highlight.Name = "TasuHubMM2Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.72
    highlight.OutlineTransparency = 0.05
    highlight.Enabled = false
    highlight.Parent = CoreGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TasuHubMM2Name"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(180, 26)
    billboard.StudsOffset = Vector3.new(0, 3.25, 0)
    billboard.Enabled = false
    billboard.Parent = CoreGui
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.FontFace = fonts.HeadingHeavy
    label.TextSize = 15
    label.TextStrokeTransparency = 0.15
    label.Parent = billboard
    record = {Highlight = highlight, Billboard = billboard, Label = label}
    playerESP[player] = record
    return record
end

local function findGunDrop()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object.Name == "GunDrop" then return object end
    end
    return nil
end

local function updateGunDrop()
    local gunDrop = findGunDrop()
    if not gunHighlight then
        gunHighlight = Instance.new("Highlight")
        gunHighlight.Name = "TasuHubMM2GunDrop"
        gunHighlight.FillColor = Color3.fromRGB(65, 145, 255)
        gunHighlight.OutlineColor = Color3.fromRGB(190, 225, 255)
        gunHighlight.FillTransparency = 0.55
        gunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        gunHighlight.Parent = CoreGui
    end
    gunHighlight.Adornee = State.Enabled and State.GunDropESP and gunDrop or nil
    gunHighlight.Enabled = gunHighlight.Adornee ~= nil
    return gunDrop
end

local function requestPickup()
    local gunDrop = findGunDrop()
    local _, _, root = characterInfo(LocalPlayer)
    if not gunDrop or not root then return false end
    local prompt = gunDrop:FindFirstChildWhichIsA("ProximityPrompt", true)
    local firePrompt = env.fireproximityprompt or _G.fireproximityprompt
    if prompt and type(firePrompt) == "function" then
        pcall(firePrompt, prompt)
        return true
    end
    local touch = env.firetouchinterest or _G.firetouchinterest
    local part = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildWhichIsA("BasePart", true)
    if part and type(touch) == "function" then
        pcall(touch, root, part, 0)
        pcall(touch, root, part, 1)
        return true
    end
    return false
end

local function requestShot()
    local gun = findTool(LocalPlayer, "Gun")
    if not gun then return false end
    local targetRoot
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and replicatedRole(player) == "Murderer" then
            local _, humanoid, root = characterInfo(player)
            if humanoid and humanoid.Health > 0 and root then
                targetRoot = root
                break
            end
        end
    end
    if not targetRoot then return false end
    for _, object in ipairs(gun:GetDescendants()) do
        local lowered = string.lower(object.Name)
        if object:IsA("RemoteEvent")
            and (string.find(lowered, "shoot", 1, true) or string.find(lowered, "fire", 1, true)) then
            pcall(function() object:FireServer(targetRoot.Position) end)
            return true
        end
    end
    return false
end

local root = Instance.new("Frame")
root.Name = "MM2GameRoot"
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.ZIndex = 4000
root.Parent = context.Parent

local window = Instance.new("CanvasGroup")
window.Name = "MM2Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = theme.Layer
window.BackgroundTransparency = 1
window.BorderSizePixel = 0
window.ClipsDescendants = false
window.GroupTransparency = 1
window.Size = UDim2.fromOffset(layout.WindowWidth, layout.WindowHeight)
window.Visible = false
window.ZIndex = 4001
window.Parent = root
round(window, layout.WindowRadius)
outline(window, 2, 0.06)

local windowScale = Instance.new("UIScale")
windowScale.Scale = 0
windowScale.Parent = window

local clip = Instance.new("Frame")
clip.Name = "ContentClip"
clip.BackgroundTransparency = 1
clip.BorderSizePixel = 0
clip.ClipsDescendants = true
clip.Size = UDim2.fromScale(1, 1)
clip.ZIndex = 4002
clip.Parent = window
round(clip, layout.WindowRadius)

local header = Instance.new("Frame")
header.Name = "Header"
header.Active = true
header.BackgroundColor3 = theme.Base
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, layout.HeaderHeight)
header.ZIndex = 4002
header.Parent = clip

local headerDrag = Instance.new("Frame")
headerDrag.Name = "HeaderDragArea"
headerDrag.Active = true
headerDrag.BackgroundTransparency = 1
headerDrag.BorderSizePixel = 0
headerDrag.Size = UDim2.fromScale(1, 1)
headerDrag.ZIndex = 4004
headerDrag.Parent = header

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.BackgroundTransparency = 1
title.FontFace = fonts.HeadingBlack
title.Position = UDim2.fromScale(0.5, 0.5)
title.Size = UDim2.new(1, -120, 1, 0)
title.Text = "Murder Mystery 2"
title.TextColor3 = theme.Signal
title.TextSize = 21
title.ZIndex = 4003
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.AutoButtonColor = false
closeButton.BackgroundColor3 = theme.Layer
closeButton.BackgroundTransparency = 0.12
closeButton.BorderSizePixel = 0
closeButton.FontFace = fonts.HeadingHeavy
closeButton.Position = UDim2.new(1, -12, 0.5, 0)
closeButton.Size = UDim2.fromOffset(38, 38)
closeButton.Text = "×"
closeButton.TextColor3 = theme.Signal
closeButton.TextSize = 23
closeButton.ZIndex = 4005
closeButton.Parent = header
round(closeButton, 11)
outline(closeButton, 2, 0.08)

local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundColor3 = theme.Layer
body.BackgroundTransparency = layout.BodyTransparency
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(0, layout.HeaderHeight)
body.Size = UDim2.new(1, 0, 1, -(layout.HeaderHeight + layout.FooterHeight))
body.ZIndex = 4002
body.Parent = clip

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Active = true
footer.AnchorPoint = Vector2.new(0, 1)
footer.BackgroundColor3 = theme.Base
footer.BorderSizePixel = 0
footer.Position = UDim2.fromScale(0, 1)
footer.Size = UDim2.new(1, 0, 0, layout.FooterHeight)
footer.ZIndex = 4002
footer.Parent = clip

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.FontFace = fonts.Body
statusLabel.Position = UDim2.fromOffset(16, 0)
statusLabel.Size = UDim2.new(1, -32, 1, 0)
statusLabel.Text = "Ready"
statusLabel.TextColor3 = theme.Signal
statusLabel.TextSize = 13
statusLabel.TextTransparency = 0.28
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 4003
statusLabel.Parent = footer

local function setStatus(message, color)
    statusLabel.Text = tostring(message or "Ready")
    statusLabel.TextColor3 = color or theme.Signal
    statusLabel.TextTransparency = color and 0 or 0.28
end

local controls = {}
local contentPadding = layout.ContentPadding
local columnGap, rowGap, rowHeight = 12, 12, 62

local function controlPosition(column, row)
    return UDim2.new(
        (column - 1) * 0.5,
        column == 1 and contentPadding or columnGap * 0.5,
        0,
        contentPadding + (row - 1) * (rowHeight + rowGap)
    )
end

local function controlSize(height)
    return UDim2.new(0.5, -(contentPadding + columnGap * 0.5), 0, height)
end

local function addToggle(labelText, key, column, row)
    local button = Instance.new("TextButton")
    button.Name = key
    button.AutoButtonColor = false
    button.BackgroundColor3 = theme.Base
    button.BackgroundTransparency = 0.14
    button.BorderSizePixel = 0
    button.Position = controlPosition(column, row)
    button.Size = controlSize(rowHeight)
    button.Text = ""
    button.ZIndex = 4003
    button.Parent = body
    round(button, 13)
    local cardStroke = outline(button, 2, 0.16)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = fonts.HeadingHeavy
    label.Position = UDim2.fromOffset(15, 0)
    label.Size = UDim2.new(1, -75, 1, 0)
    label.Text = labelText
    label.TextColor3 = theme.Signal
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4004
    label.Parent = button

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = theme.Layer
    track.BackgroundTransparency = 0.08
    track.BorderSizePixel = 0
    track.Position = UDim2.new(1, -14, 0.5, 0)
    track.Size = UDim2.fromOffset(38, 22)
    track.ZIndex = 4004
    track.Parent = button
    round(track, 999)
    outline(track, 1, 0.22, theme.Signal)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = theme.Signal
    knob.BorderSizePixel = 0
    knob.Size = UDim2.fromOffset(14, 14)
    knob.ZIndex = 4005
    knob.Parent = track
    round(knob, 999)

    local function render(instant)
        local enabled = State[key] == true
        local trackProperties = {
            BackgroundColor3 = enabled and theme.Signal or theme.Layer,
            BackgroundTransparency = enabled and 0 or 0.08
        }
        local knobProperties = {
            BackgroundColor3 = enabled and theme.Base or theme.Signal,
            Position = enabled and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
        }
        if instant then
            for property, value in pairs(trackProperties) do track[property] = value end
            for property, value in pairs(knobProperties) do knob[property] = value end
        else
            animate(track, trackProperties, motion.Control, Enum.EasingStyle.Quint)
            animate(knob, knobProperties, motion.Control, Enum.EasingStyle.Quint)
        end
        cardStroke.Color = enabled and theme.Signal or theme.Base
    end
    connect(button.MouseEnter, function()
        playSound("ButtonHover")
        animate(button, {BackgroundTransparency = 0.04}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(button.MouseLeave, function()
        animate(button, {BackgroundTransparency = 0.14}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(button.Activated, function()
        State[key] = not State[key]
        playSound("ButtonClick")
        render(false)
        setStatus(labelText .. (State[key] and " enabled" or " disabled"), State[key] and theme.Success or nil)
    end)
    controls[key] = {Render = render}
    render(true)
end

local function addAction(labelText, callback, column, row)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundColor3 = theme.Layer
    button.BackgroundTransparency = 0.04
    button.BorderSizePixel = 0
    button.FontFace = fonts.HeadingBlack
    button.Position = controlPosition(column, row)
    button.Size = controlSize(48)
    button.Text = labelText
    button.TextColor3 = theme.Signal
    button.TextSize = 15
    button.ZIndex = 4003
    button.Parent = body
    round(button, 13)
    local actionStroke = outline(button, 2, 0.08, theme.Signal)
    connect(button.MouseEnter, function()
        playSound("ButtonHover")
        animate(button, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
        animate(actionStroke, {Transparency = 0}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(button.MouseLeave, function()
        animate(button, {BackgroundTransparency = 0.04}, motion.Control, Enum.EasingStyle.Quint)
        animate(actionStroke, {Transparency = 0.08}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(button.Activated, function()
        playSound("ButtonClick")
        local ok = callback()
        setStatus(ok and (labelText .. " succeeded") or (labelText .. " unavailable"), ok and theme.Success or theme.Danger)
    end)
end

addToggle("Main System", "Enabled", 1, 1)
addToggle("Role ESP", "PlayerESP", 2, 1)
addToggle("GunDrop ESP", "GunDropESP", 1, 2)
addToggle("Auto Pickup", "AutoPickup", 2, 2)
addToggle("Auto Fire", "AutoFire", 1, 3)
addAction("Pick Up Gun Now", requestPickup, 1, 4)
addAction("Shoot Now", requestShot, 2, 4)

local uiState = "Closed"
local transitionRevision = 0
local restingPosition
local dragging, dragStart, dragWindowStart = false, nil, nil

local function windowSize()
    local viewport = context.GetViewportSize()
    return viewport, Vector2.new(
        math.min(layout.WindowWidth, math.max(360, viewport.X - layout.ViewportInset * 2)),
        math.min(layout.WindowHeight, math.max(320, viewport.Y - layout.ViewportInset * 2))
    )
end

local function clampCenter(point, size, viewport)
    local margin, halfX, halfY = layout.ViewportInset, size.X * 0.5, size.Y * 0.5
    local minX, maxX = halfX + margin, viewport.X - halfX - margin
    local minY, maxY = halfY + margin, viewport.Y - halfY - margin
    if minX > maxX then minX, maxX = viewport.X * 0.5, viewport.X * 0.5 end
    if minY > maxY then minY, maxY = viewport.Y * 0.5, viewport.Y * 0.5 end
    return Vector2.new(math.clamp(point.X, minX, maxX), math.clamp(point.Y, minY, maxY))
end

local function targetGeometry()
    local viewport, size = windowSize()
    restingPosition = clampCenter(restingPosition or viewport * 0.5, size, viewport)
    return viewport, size, restingPosition
end

local function beginDrag(input)
    if uiState ~= "Open" then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = true
    dragStart = Vector2.new(input.Position.X, input.Position.Y)
    dragWindowStart = restingPosition
end
connect(headerDrag.InputBegan, beginDrag)
connect(footer.InputBegan, beginDrag)
connect(inputService.InputChanged, function(input)
    if not dragging or not dragStart or not dragWindowStart then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local viewport, size = windowSize()
    local pointer = Vector2.new(input.Position.X, input.Position.Y)
    restingPosition = clampCenter(dragWindowStart + pointer - dragStart, size, viewport)
    window.Position = UDim2.fromOffset(restingPosition.X, restingPosition.Y)
end)
connect(inputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, dragWindowStart = false, nil, nil
    end
end)

local function open()
    if unloaded or uiState == "Open" or uiState == "Opening" then return false end
    local reversingClose = uiState == "Closing"
    transitionRevision, uiState = transitionRevision + 1, "Opening"
    local revision = transitionRevision
    local _, size, center = targetGeometry()
    window.Size = UDim2.fromOffset(size.X, size.Y)
    if not reversingClose then
        local source = context.GetAnchorPoint()
        window.Position = UDim2.fromOffset(source.X, source.Y)
        windowScale.Scale, window.GroupTransparency = 0, 1
    end
    window.Visible = true
    local move = animate(window, {Position = UDim2.fromOffset(center.X, center.Y), GroupTransparency = 0}, motion.Open, Enum.EasingStyle.Quint)
    animate(windowScale, {Scale = 1}, motion.Open, Enum.EasingStyle.Back)
    task.spawn(function()
        move.Completed:Wait()
        if not unloaded and revision == transitionRevision then uiState = "Open" end
    end)
    return true
end

local function close()
    if unloaded or uiState == "Closed" or uiState == "Closing" then return false end
    transitionRevision, uiState = transitionRevision + 1, "Closing"
    local revision = transitionRevision
    local source = context.GetAnchorPoint()
    dragging = false
    local move = animate(window, {Position = UDim2.fromOffset(source.X, source.Y), GroupTransparency = 1}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    animate(windowScale, {Scale = 0}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.spawn(function()
        move.Completed:Wait()
        if not unloaded and revision == transitionRevision then
            window.Visible, uiState = false, "Closed"
        end
    end)
    return true
end

connect(closeButton.MouseEnter, function()
    animate(closeButton, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
end)
connect(closeButton.MouseLeave, function()
    animate(closeButton, {BackgroundTransparency = 0.12}, motion.Control, Enum.EasingStyle.Quint)
end)
connect(closeButton.Activated, function()
    playSound("ButtonClick")
    close()
end)
connect(context.Parent:GetPropertyChangedSignal("AbsoluteSize"), function()
    if unloaded or (uiState ~= "Open" and uiState ~= "Opening") then return end
    local _, size, center = targetGeometry()
    window.Size = UDim2.fromOffset(size.X, size.Y)
    window.Position = UDim2.fromOffset(center.X, center.Y)
end)

local clock = 0
connect(RunService.Heartbeat, function(deltaTime)
    clock = clock + deltaTime
    if clock < 0.15 then return end
    clock = 0
    local gunDrop = updateGunDrop()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local record = ensurePlayerESP(player)
            local character, humanoid, characterRoot = characterInfo(player)
            local role = replicatedRole(player)
            local color = role == "Murderer" and Color3.fromRGB(244, 72, 83)
                or role == "Sheriff" and Color3.fromRGB(65, 145, 255) or nil
            local visible = State.Enabled and State.PlayerESP and color ~= nil
                and humanoid and humanoid.Health > 0 and characterRoot ~= nil
            record.Highlight.Adornee = visible and character or nil
            record.Highlight.FillColor = color or Color3.new(1, 1, 1)
            record.Highlight.OutlineColor = color or Color3.new(1, 1, 1)
            record.Highlight.Enabled = visible
            record.Billboard.Adornee = visible and characterRoot or nil
            record.Billboard.Enabled = visible
            record.Label.Text = player.DisplayName
            record.Label.TextColor3 = color or Color3.new(1, 1, 1)
        end
    end
    if State.Enabled and State.AutoPickup and gunDrop then requestPickup() end
    if State.Enabled and State.AutoFire then requestShot() end
end)
connect(Players.PlayerRemoving, destroyPlayerESP)

local controller
local function unload()
    if unloaded then return end
    unloaded = true
    transitionRevision = transitionRevision + 1
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for player in pairs(playerESP) do destroyPlayerESP(player) end
    if gunHighlight then gunHighlight:Destroy() end
    if root.Parent then root:Destroy() end
    if env.TasuHubMM2 == controller then env.TasuHubMM2 = nil end
end

controller = table.freeze({
    State = State,
    PlaceId = 142823291,
    GetState = function()
        local copy = {}
        for key, value in pairs(State) do copy[key] = value end
        return copy
    end,
    SetState = function(key, value)
        if State[key] == nil then return false end
        State[key] = value == true
        if controls[key] then controls[key].Render(false) end
        return true
    end,
    Enable = function() State.Enabled = true; controls.Enabled.Render(false); return true end,
    Disable = function() State.Enabled = false; controls.Enabled.Render(false); return true end,
    RefreshCharacter = function() return true end,
    Open = open,
    Close = close,
    Toggle = function()
        return (uiState == "Open" or uiState == "Opening") and close() or open()
    end,
    IsOpen = function() return uiState == "Open" or uiState == "Opening" end,
    Destroy = unload,
    Unload = unload
})
env.TasuHubMM2 = controller
return controller
