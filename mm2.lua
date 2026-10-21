local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then error("[TasuHub/MM2] LocalPlayer is unavailable") end

local env = getgenv and getgenv() or _G
local previousState
if env.TasuHubMM2 and type(env.TasuHubMM2.GetState) == "function" then
    local ok, state = pcall(env.TasuHubMM2.GetState)
    if ok and type(state) == "table" then previousState = state end
end
if env.TasuHubMM2 and type(env.TasuHubMM2.Unload) == "function" then pcall(env.TasuHubMM2.Unload) end
local hub = env.TasuHub
if type(hub) ~= "table" or type(hub.GetGameUIContext) ~= "function" then
    error("[TasuHub/MM2] Shared TasuHub UI context is unavailable")
end
local context = hub.GetGameUIContext("mm2")
if type(context) ~= "table" or not context.Parent or type(context.CreateService) ~= "function" then
    error("[TasuHub/MM2] Shared game-window/service context is invalid")
end

local theme, fonts = context.Theme, context.Fonts
local motion, layout = context.Motion, context.Layout
local animate, playSound = context.Animate, context.PlaySound or function() end
local uiRuntime = context.UIRuntime
local inputService = context.InputService
local service = context.CreateService(previousState)
if type(service) ~= "table" or type(service.GetState) ~= "function" then
    error("[TasuHub/MM2] MM2 service creation failed: " .. tostring(context.ServiceError or "unknown error"))
end

local connections, controlRenderers, registeredBindIds = {}, {}, {}
local unloaded = false
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
local function round(object, radius)
    if uiRuntime and type(uiRuntime.Round) == "function" then return uiRuntime.Round(object, radius) end
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end
local function outline(object, thickness, transparency, color)
    if uiRuntime and type(uiRuntime.Outline) == "function" then
        return uiRuntime.Outline(object, thickness, transparency, color)
    end
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color or theme.Base
    stroke.Thickness = thickness
    stroke.Transparency = transparency or 0
    stroke.Parent = object
    return stroke
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
header.ClipsDescendants = true
header.Size = UDim2.new(1, 0, 0, layout.HeaderHeight)
header.ZIndex = 4002
header.Parent = clip

local bannerLayer = Instance.new("Frame")
bannerLayer.Name = "BannerBlurLayer"
bannerLayer.BackgroundTransparency = 1
bannerLayer.ClipsDescendants = true
bannerLayer.Size = UDim2.fromScale(1, 1)
bannerLayer.ZIndex = 4002
bannerLayer.Parent = header
local bannerImages = {}
for index, offset in ipairs({-5, -2, 0, 2, 5}) do
    local image = Instance.new("ImageLabel")
    image.Name = "BlurSample" .. tostring(index)
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.Image = ""
    image.ImageTransparency = index == 3 and 0.46 or 0.78
    image.Position = UDim2.fromOffset(offset, math.abs(offset) * 0.25 - 3)
    image.ScaleType = Enum.ScaleType.Stretch
    image.Size = UDim2.new(1, math.abs(offset) * 2, 1, 6)
    image.ZIndex = 4002
    image.Parent = bannerLayer
    table.insert(bannerImages, image)
end
local bannerShade = Instance.new("Frame")
bannerShade.Name = "HeaderTint"
bannerShade.BackgroundColor3 = theme.Base
bannerShade.BackgroundTransparency = 0.28
bannerShade.BorderSizePixel = 0
bannerShade.Size = UDim2.fromScale(1, 1)
bannerShade.ZIndex = 4003
bannerShade.Parent = header

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
title.Size = UDim2.new(1, -130, 1, 0)
title.Text = context.GameName or "Murder Mystery 2"
title.TextColor3 = theme.Signal
title.TextSize = 21
title.TextStrokeColor3 = theme.Base
title.TextStrokeTransparency = 0.42
title.ZIndex = 4005
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
closeButton.ZIndex = 4006
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
local function setStatus(message, success)
    statusLabel.Text = tostring(message or "Ready")
    statusLabel.TextColor3 = success == false and theme.Danger or success == true and theme.Success or theme.Signal
    statusLabel.TextTransparency = success == nil and 0.28 or 0
end

local sidebarExpanded = true
local sidebarExpandedWidth, sidebarCollapsedWidth = 138, 58
local sidebar = Instance.new("Frame")
sidebar.Name = "PageNavigation"
sidebar.BackgroundColor3 = theme.Base
sidebar.BackgroundTransparency = 0.06
sidebar.BorderSizePixel = 0
sidebar.ClipsDescendants = true
sidebar.Size = UDim2.new(0, sidebarExpandedWidth, 1, 0)
sidebar.ZIndex = 4003
sidebar.Parent = body
local collapseButton = Instance.new("TextButton")
collapseButton.Name = "CollapseNavigation"
collapseButton.AutoButtonColor = false
collapseButton.BackgroundColor3 = theme.Layer
collapseButton.BackgroundTransparency = 0.12
collapseButton.BorderSizePixel = 0
collapseButton.FontFace = fonts.HeadingBlack
collapseButton.Position = UDim2.fromOffset(9, 9)
collapseButton.Size = UDim2.fromOffset(40, 38)
collapseButton.Text = "≡"
collapseButton.TextColor3 = theme.Signal
collapseButton.TextSize = 21
collapseButton.ZIndex = 4005
collapseButton.Parent = sidebar
round(collapseButton, 11)

local pageHost = Instance.new("Frame")
pageHost.Name = "PageHost"
pageHost.BackgroundTransparency = 1
pageHost.BorderSizePixel = 0
pageHost.ClipsDescendants = true
pageHost.Position = UDim2.fromOffset(sidebarExpandedWidth, 0)
pageHost.Size = UDim2.new(1, -sidebarExpandedWidth, 1, 0)
pageHost.ZIndex = 4003
pageHost.Parent = body

local pageDefinitions = {{Id = "ESP", Glyph = "◇"}, {Id = "AIM", Glyph = "◎"}, {Id = "FARM", Glyph = "◆"}}
local pages, navRecords = {}, {}
for index, definition in ipairs(pageDefinitions) do
    local button = Instance.new("TextButton")
    button.Name = definition.Id
    button.AutoButtonColor = false
    button.BackgroundColor3 = theme.Layer
    button.BackgroundTransparency = index == 1 and 0 or 0.65
    button.BorderSizePixel = 0
    button.Position = UDim2.fromOffset(9, 58 + (index - 1) * 52)
    button.Size = UDim2.new(1, -18, 0, 44)
    button.Text = ""
    button.ZIndex = 4004
    button.Parent = sidebar
    round(button, 11)
    local glyph = Instance.new("TextLabel")
    glyph.BackgroundTransparency = 1
    glyph.FontFace = fonts.HeadingBlack
    glyph.Size = UDim2.fromOffset(40, 44)
    glyph.Text = definition.Glyph
    glyph.TextColor3 = theme.Signal
    glyph.TextSize = 20
    glyph.ZIndex = 4005
    glyph.Parent = button
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = fonts.HeadingHeavy
    label.Position = UDim2.fromOffset(42, 0)
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Text = definition.Id
    label.TextColor3 = theme.Signal
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4005
    label.Parent = button
    navRecords[definition.Id] = {Button = button, Label = label}
    local page = Instance.new("CanvasGroup")
    page.Name = definition.Id .. "Page"
    page.BackgroundTransparency = 1
    page.GroupTransparency = index == 1 and 0 or 1
    page.Size = UDim2.fromScale(1, 1)
    page.Visible = index == 1
    page.ZIndex = 4003
    page.Parent = pageHost
    pages[definition.Id] = page
end

local function createPageGrid(page)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Active = true
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.Position = UDim2.fromOffset(layout.ContentPadding, layout.ContentPadding)
    scroll.ScrollBarImageColor3 = theme.Signal
    scroll.ScrollBarImageTransparency = 0.48
    scroll.ScrollBarThickness = 3
    scroll.Size = UDim2.new(1, -layout.ContentPadding * 2, 1, -layout.ContentPadding * 2)
    scroll.ZIndex = 4003
    scroll.Parent = page
    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(10, 10)
    grid.CellSize = UDim2.new(0.5, -5, 0, 72)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = scroll
    return scroll
end
local pageGrids = {ESP = createPageGrid(pages.ESP), AIM = createPageGrid(pages.AIM), FARM = createPageGrid(pages.FARM)}

local function createControlBase(parent, labelText, order, height)
    local item = Instance.new("Frame")
    item.BackgroundColor3 = theme.Base
    item.BackgroundTransparency = 0.14
    item.BorderSizePixel = 0
    item.LayoutOrder = order
    item.Size = UDim2.new(0.5, -5, 0, height or 58)
    item.ZIndex = 4004
    item.Parent = parent
    round(item, 13)
    local itemStroke = outline(item, 2, 0.16)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = fonts.HeadingHeavy
    label.Position = UDim2.fromOffset(14, 0)
    label.Size = UDim2.new(1, -72, 1, 0)
    label.Text = labelText
    label.TextColor3 = theme.Signal
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4005
    label.Parent = item
    return item, itemStroke, label
end

local function snake(value)
    return string.lower(tostring(value or ""):gsub("(%l)(%u)", "%1_%2"):gsub("[^%w]+", "_"))
end

local function createBindControl(item, bindId)
    if type(context.GetBind) ~= "function" or type(context.BeginBind) ~= "function" then return nil end
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.AutoButtonColor = false
    button.BackgroundColor3 = theme.Layer
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.FontFace = fonts.HeadingHeavy
    button.Position = UDim2.new(1, -59, 0.5, 0)
    button.Size = UDim2.fromOffset(40, 24)
    button.Text = tostring(context.GetBind(bindId) or "Bind")
    button.TextColor3 = theme.Signal
    button.TextSize = 10
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.ZIndex = 4008
    button.Parent = item
    round(button, 7)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button
    connect(button.Activated, function()
        playSound("ButtonClick")
        button.Text = "..."
        context.BeginBind(bindId, function(result)
            if unloaded or not button.Parent then return end
            result = type(result) == "table" and result or {Status = "Success"}
            if result.Status == "Success" or result.Status == "Cleared" then
                button.Text = tostring(context.GetBind(bindId) or "Bind")
                button.TextColor3 = theme.Success
                animate(scale, {Scale = 1.1}, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                task.delay(0.12, function()
                    if button.Parent then
                        animate(scale, {Scale = 1}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        animate(button, {TextColor3 = theme.Signal}, 0.18, Enum.EasingStyle.Quint)
                    end
                end)
            elseif result.Status == "Cancelled" then
                button.Text = tostring(context.GetBind(bindId) or "Bind")
            else
                local resting = button.Position
                button.Text = tostring(result.Key or result.PreviousKey or "Bind")
                button.TextColor3 = theme.Danger
                task.spawn(function()
                    for _, offset in ipairs({-5, 5, -3, 3, 0}) do
                        if not button.Parent then return end
                        button.Position = resting + UDim2.fromOffset(offset, 0)
                        task.wait(0.045)
                    end
                    if button.Parent then
                        button.Position = resting
                        button.Text = tostring(context.GetBind(bindId) or "Bind")
                        animate(button, {TextColor3 = theme.Signal}, 0.18, Enum.EasingStyle.Quint)
                    end
                end)
            end
        end)
    end)
    return button
end

local function registerBind(descriptor)
    if type(context.RegisterBind) ~= "function" then return false end
    local ok = context.RegisterBind(descriptor)
    if ok then table.insert(registeredBindIds, descriptor.Id) end
    return ok
end

local function addToggle(parent, labelText, key, order, iconKey, color)
    local item, itemStroke, label = createControlBase(parent, labelText, order, 58)
    label.Size = UDim2.new(1, -122, 1, 0)
    if typeof(color) == "Color3" then label.TextColor3 = color end
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.Size = UDim2.fromScale(1, 1)
    button.Text = ""
    button.ZIndex = 4006
    button.Parent = item
    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = theme.Layer
    track.BackgroundTransparency = 0.08
    track.BorderSizePixel = 0
    track.Position = UDim2.new(1, -13, 0.5, 0)
    track.Size = UDim2.fromOffset(38, 22)
    track.ZIndex = 4005
    track.Parent = item
    round(track, 999)
    outline(track, 1, 0.22, theme.Signal)
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = theme.Signal
    knob.BorderSizePixel = 0
    knob.Size = UDim2.fromOffset(14, 14)
    knob.ZIndex = 4006
    knob.Parent = track
    round(knob, 999)
    local function render(instant)
        local enabled = service.GetState()[key] == true
        local trackProperties = {BackgroundColor3 = enabled and theme.Signal or theme.Layer, BackgroundTransparency = enabled and 0 or 0.08}
        local knobProperties = {BackgroundColor3 = enabled and theme.Base or theme.Signal, Position = enabled and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)}
        if instant then
            for property, value in pairs(trackProperties) do track[property] = value end
            for property, value in pairs(knobProperties) do knob[property] = value end
        else
            animate(track, trackProperties, motion.Control, Enum.EasingStyle.Quint)
            animate(knob, knobProperties, motion.Control, Enum.EasingStyle.Quint)
        end
        itemStroke.Color = enabled and theme.Signal or theme.Base
        if type(context.RefreshBind) == "function" then context.RefreshBind("mm2." .. snake(key)) end
    end
    connect(button.MouseEnter, function() playSound("ButtonHover"); animate(item, {BackgroundTransparency = 0.04}, motion.Control, Enum.EasingStyle.Quint) end)
    connect(button.MouseLeave, function() animate(item, {BackgroundTransparency = 0.14}, motion.Control, Enum.EasingStyle.Quint) end)
    connect(button.Activated, function()
        playSound("ButtonClick")
        local ok, message = service.SetState(key, not service.GetState()[key])
        render(false)
        setStatus(message or labelText, ok)
    end)
    controlRenderers[key] = render
    local bindId = "mm2." .. snake(key)
    registerBind({
        Id = bindId,
        Scope = "Game:mm2",
        Kind = "Toggle",
        IconKey = iconKey or "Toggle",
        Color = color or theme.Signal,
        ActiveColor = color or theme.Success,
        GetActive = function() return service.GetState()[key] == true end,
        Invoke = function()
            local ok, message = service.SetState(key, not service.GetState()[key])
            render(false)
            setStatus(message or labelText, ok)
            return ok, message
        end
    })
    createBindControl(item, bindId)
    render(true)
end

local function addAction(parent, labelText, callback, order, actionId, iconKey, cooldown)
    local item, itemStroke, label = createControlBase(parent, labelText, order, 58)
    label.Size = UDim2.new(1, -76, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Center
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.Size = UDim2.fromScale(1, 1)
    button.Text = ""
    button.ZIndex = 4006
    button.Parent = item
    connect(button.MouseEnter, function()
        playSound("ButtonHover")
        animate(item, {BackgroundTransparency = 0.03}, motion.Control, Enum.EasingStyle.Quint)
        animate(itemStroke, {Transparency = 0}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(button.MouseLeave, function()
        animate(item, {BackgroundTransparency = 0.14}, motion.Control, Enum.EasingStyle.Quint)
        animate(itemStroke, {Transparency = 0.16}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(button.Activated, function()
        playSound("ButtonClick")
        local ok, message = callback()
        setStatus(message or (ok and "Action completed" or "Action unavailable"), ok)
    end)
    local bindId = "mm2." .. tostring(actionId or snake(labelText))
    registerBind({
        Id = bindId,
        Scope = "Game:mm2",
        Kind = "Action",
        IconKey = iconKey or "Action",
        Color = theme.Signal,
        ActiveColor = theme.Success,
        Cooldown = cooldown or 0,
        Invoke = function()
            local ok, message = callback()
            setStatus(message or (ok and "Action completed" or "Action unavailable"), ok)
            return ok, message
        end
    })
    local bindButton = createBindControl(item, bindId)
    if bindButton then bindButton.Position = UDim2.new(1, -10, 0.5, 0) end
end

local function addSlider(parent, labelText, key, minimum, maximum, order)
    local item, _, label = createControlBase(parent, labelText, order, 72)
    label.Size = UDim2.new(1, -70, 0, 34)
    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.FontFace = fonts.Body
    valueLabel.Position = UDim2.new(1, -64, 0, 0)
    valueLabel.Size = UDim2.fromOffset(50, 34)
    valueLabel.TextColor3 = theme.Signal
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 4005
    valueLabel.Parent = item
    local track = Instance.new("Frame")
    track.Active = true
    track.BackgroundColor3 = theme.Layer
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 14, 1, -20)
    track.Size = UDim2.new(1, -28, 0, 6)
    track.ZIndex = 4005
    track.Parent = item
    round(track, 999)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = theme.Signal
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(0, 1)
    fill.ZIndex = 4006
    fill.Parent = track
    round(fill, 999)
    local dragging = false
    local function render()
        local value = tonumber(service.GetState()[key]) or minimum
        fill.Size = UDim2.fromScale(math.clamp((value - minimum) / (maximum - minimum), 0, 1), 1)
        valueLabel.Text = tostring(math.floor(value + 0.5))
    end
    local function update(input)
        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        service.SetState(key, minimum + (maximum - minimum) * ratio)
        render()
    end
    connect(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input) end
    end)
    connect(inputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
    connect(inputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    controlRenderers[key] = render
    render()
end

addToggle(pageGrids.ESP, "Main System", "Enabled", 1)
addToggle(pageGrids.ESP, "Murderer ESP", "MurdererESP", 2, "Toggle", context.DataColors and context.DataColors.Murderer)
addToggle(pageGrids.ESP, "Sheriff ESP", "SheriffESP", 3, "Toggle", context.DataColors and context.DataColors.Sheriff)
addToggle(pageGrids.ESP, "Innocent ESP", "InnocentESP", 4, "Toggle", context.DataColors and context.DataColors.Innocent)
addToggle(pageGrids.ESP, "Avatar Card", "AvatarCardESP", 5)
addToggle(pageGrids.ESP, "Weapon Card", "WeaponCardESP", 6)
addToggle(pageGrids.ESP, "Gun Drop ESP", "GunDropESP", 7)
addToggle(pageGrids.AIM, "Auto Fire", "AutoFire", 1, "MM2AutoFire")
addToggle(pageGrids.AIM, "Auto Pickup", "AutoPickup", 2, "MM2AutoPickup")
addAction(pageGrids.AIM, "Shoot Now", service.ShootNow, 3, "shoot_now", "MM2ShootNow", 0.75)
addAction(pageGrids.AIM, "Pick Up Gun", service.PickupGun, 4, "pickup_gun", "MM2PickupGun", 1)
addToggle(pageGrids.FARM, "Auto Farm", "AutoFarm", 1)
addSlider(pageGrids.FARM, "Farm Speed", "FarmSpeed", 20, 90, 2)
addSlider(pageGrids.FARM, "Underground Offset", "UndergroundOffset", 7, 30, 3)

local currentPage, pageRevision = "ESP", 0
local function selectPage(pageId)
    if unloaded or not pages[pageId] or pageId == currentPage then return false end
    pageRevision = pageRevision + 1
    local revision, oldId = pageRevision, currentPage
    currentPage = pageId
    for id, record in pairs(navRecords) do
        animate(record.Button, {BackgroundTransparency = id == pageId and 0 or 0.65}, motion.Control, Enum.EasingStyle.Quint)
    end
    local oldPage = pages[oldId]
    animate(oldPage, {Position = UDim2.fromOffset(0, -18), GroupTransparency = 1}, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.delay(0.18, function()
        if unloaded or revision ~= pageRevision then return end
        oldPage.Visible = false
        task.delay(0.22, function()
            if unloaded or revision ~= pageRevision then return end
            local newPage = pages[pageId]
            newPage.Position = UDim2.fromOffset(0, -18)
            newPage.GroupTransparency = 1
            newPage.Visible = true
            animate(newPage, {Position = UDim2.fromOffset(0, 0), GroupTransparency = 0}, 0.26, Enum.EasingStyle.Quint)
        end)
    end)
    return true
end
for id, record in pairs(navRecords) do
    connect(record.Button.MouseEnter, function() playSound("ButtonHover") end)
    connect(record.Button.Activated, function() playSound("ButtonClick"); selectPage(id) end)
end
connect(collapseButton.Activated, function()
    sidebarExpanded = not sidebarExpanded
    playSound("ButtonClick")
    local width = sidebarExpanded and sidebarExpandedWidth or sidebarCollapsedWidth
    animate(sidebar, {Size = UDim2.new(0, width, 1, 0)}, 0.34, Enum.EasingStyle.Quint)
    animate(pageHost, {Position = UDim2.fromOffset(width, 0), Size = UDim2.new(1, -width, 1, 0)}, 0.34, Enum.EasingStyle.Quint)
    for _, record in pairs(navRecords) do
        animate(record.Label, {
            Position = sidebarExpanded and UDim2.fromOffset(42, 0) or UDim2.fromOffset(55, 0),
            TextTransparency = sidebarExpanded and 0 or 1
        }, 0.24, Enum.EasingStyle.Quint)
    end
end)

local uiState, transitionRevision = "Closed", 0
local restingPosition, dragging, dragStart, dragWindowStart = nil, false, nil, nil
local function responsiveScale()
    local viewport = context.GetViewportSize()
    return math.min(1, (viewport.X - layout.ViewportInset * 2) / layout.WindowWidth, (viewport.Y - layout.ViewportInset * 2) / layout.WindowHeight)
end
local function visibleRatio(center, scale)
    local viewport = context.GetViewportSize()
    local size = Vector2.new(layout.WindowWidth, layout.WindowHeight) * scale
    local left, top = center.X - size.X * 0.5, center.Y - size.Y * 0.5
    local right, bottom = center.X + size.X * 0.5, center.Y + size.Y * 0.5
    local width = math.max(0, math.min(right, viewport.X) - math.max(left, 0))
    local height = math.max(0, math.min(bottom, viewport.Y) - math.max(top, 0))
    return width * height / math.max(1, size.X * size.Y)
end
local function targetGeometry()
    local viewport = context.GetViewportSize()
    local scale = responsiveScale()
    restingPosition = restingPosition or viewport * 0.5
    if visibleRatio(restingPosition, scale) < 0.5 then restingPosition = viewport * 0.5 end
    return restingPosition, scale
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
    local pointer = Vector2.new(input.Position.X, input.Position.Y)
    restingPosition = dragWindowStart + pointer - dragStart
    window.Position = UDim2.fromOffset(restingPosition.X, restingPosition.Y)
end)
connect(inputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, dragWindowStart = false, nil, nil
    end
end)

local function open()
    if unloaded or uiState == "Open" or uiState == "Opening" then return false end
    transitionRevision, uiState = transitionRevision + 1, "Opening"
    local revision = transitionRevision
    local center, scale = targetGeometry()
    local source = context.GetAnchorPoint()
    window.Position = UDim2.fromOffset(source.X, source.Y)
    windowScale.Scale, window.GroupTransparency = 0, 1
    window.Visible = true
    local move = animate(window, {Position = UDim2.fromOffset(center.X, center.Y), GroupTransparency = 0}, motion.Open, Enum.EasingStyle.Quint)
    animate(windowScale, {Scale = scale}, motion.Open, Enum.EasingStyle.Back)
    task.spawn(function()
        move.Completed:Wait()
        if not unloaded and revision == transitionRevision then uiState = "Open" end
    end)
    return true
end
local function close()
    if unloaded or uiState == "Closed" or uiState == "Closing" then return false end
    transitionRevision, uiState = transitionRevision + 1, "Closing"
    local revision, source = transitionRevision, context.GetAnchorPoint()
    dragging = false
    local move = animate(window, {Position = UDim2.fromOffset(source.X, source.Y), GroupTransparency = 1}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    animate(windowScale, {Scale = 0}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.spawn(function()
        move.Completed:Wait()
        if not unloaded and revision == transitionRevision then window.Visible, uiState = false, "Closed" end
    end)
    return true
end

connect(closeButton.MouseEnter, function() animate(closeButton, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint) end)
connect(closeButton.MouseLeave, function() animate(closeButton, {BackgroundTransparency = 0.12}, motion.Control, Enum.EasingStyle.Quint) end)
connect(closeButton.Activated, function() playSound("ButtonClick"); close() end)
connect(context.Parent:GetPropertyChangedSignal("AbsoluteSize"), function()
    if unloaded or (uiState ~= "Open" and uiState ~= "Opening") then return end
    windowScale.Scale = responsiveScale()
end)

local unsubscribe = service.Subscribe(function(_, eventName, message, success)
    if eventName ~= "Snapshot" then setStatus(message, success) end
    for _, render in pairs(controlRenderers) do render(false) end
    if type(context.RefreshBind) == "function" then
        for _, bindId in ipairs(registeredBindIds) do context.RefreshBind(bindId) end
    end
end)
task.spawn(function()
    if type(context.GetBannerAsset) ~= "function" then return end
    local ok, asset = pcall(context.GetBannerAsset)
    if ok and type(asset) == "string" and asset ~= "" and not unloaded then
        for _, image in ipairs(bannerImages) do image.Image = asset end
    end
end)

local controller
local function unload()
    if unloaded then return end
    unloaded = true
    transitionRevision, pageRevision = transitionRevision + 1, pageRevision + 1
    if unsubscribe then pcall(unsubscribe); unsubscribe = nil end
    if type(context.UnregisterBind) == "function" then
        for _, bindId in ipairs(registeredBindIds) do pcall(context.UnregisterBind, bindId) end
    end
    table.clear(registeredBindIds)
    pcall(service.Destroy)
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    table.clear(connections)
    if root.Parent then root:Destroy() end
    if env.TasuHubMM2 == controller then env.TasuHubMM2 = nil end
end

controller = table.freeze({
    State = service.GetState(),
    PlaceId = context.PlaceId or 142823291,
    GetState = service.GetState,
    SetState = function(key, value)
        local ok, message = service.SetState(key, value)
        if controlRenderers[key] then controlRenderers[key](false) end
        return ok, message
    end,
    Enable = function() return service.SetState("Enabled", true) end,
    Disable = function() return service.SetState("Enabled", false) end,
    RefreshCharacter = function() return true end,
    Open = open,
    Close = close,
    Toggle = function() return (uiState == "Open" or uiState == "Opening") and close() or open() end,
    IsOpen = function() return uiState == "Open" or uiState == "Opening" end,
    Destroy = unload,
    Unload = unload
})
env.TasuHubMM2 = controller
return controller
