local CatalogModule = {Version = 1}

local STATUS_BY_ID = table.freeze({
    mm2 = "Stable",
    preview_blox_fruits = "Un-Supported",
    preview_brookhaven = "Un-Supported",
    preview_arsenal = "Un-Supported",
    preview_doors = "Un-Supported",
    preview_adopt_me = "Un-Supported",
    preview_blade_ball = "Un-Supported",
    preview_pet_simulator_99 = "Un-Supported",
    preview_jailbreak = "Un-Supported",
    preview_tower_of_hell = "Un-Supported",
    preview_rivals = "Un-Supported",
    preview_dress_to_impress = "Un-Supported",
    preview_prison_life = "Un-Supported",
    preview_build_a_boat = "Un-Supported"
})
local FEATURES_BY_ID = table.freeze({
    mm2 = "ESP  •  AIM  •  GUN BRING  •  AUTO SHOOT",
    preview_blox_fruits = "ESP  •  FARM  •  QUEST  •  TELEPORT",
    preview_brookhaven = "ESP  •  VEHICLE  •  TELEPORT",
    preview_arsenal = "ESP  •  AIM  •  TRIGGER",
    preview_doors = "ESP  •  ENTITY ALERT  •  SPEED",
    preview_adopt_me = "ESP  •  FARM  •  TELEPORT",
    preview_blade_ball = "AUTO PARRY  •  ESP  •  SPEED",
    preview_pet_simulator_99 = "FARM  •  QUEST  •  TELEPORT",
    preview_jailbreak = "ESP  •  VEHICLE  •  TELEPORT",
    preview_tower_of_hell = "ESP  •  CHECKPOINT  •  SPEED",
    preview_rivals = "ESP  •  AIM  •  TRIGGER",
    preview_dress_to_impress = "ESP  •  WALK  •  TELEPORT",
    preview_prison_life = "ESP  •  GUN  •  TELEPORT",
    preview_build_a_boat = "FARM  •  BUILD  •  TELEPORT"
})
local PLACEHOLDERS = table.freeze({
    table.freeze({BuiltInId = "preview_blox_fruits", Name = "Blox Fruits", PlaceId = 2753915549, Placeholder = true}),
    table.freeze({BuiltInId = "preview_brookhaven", Name = "Brookhaven RP", PlaceId = 4924922222, Placeholder = true}),
    table.freeze({BuiltInId = "preview_arsenal", Name = "Arsenal", PlaceId = 286090429, Placeholder = true}),
    table.freeze({BuiltInId = "preview_doors", Name = "DOORS", PlaceId = 6516141723, Placeholder = true}),
    table.freeze({BuiltInId = "preview_adopt_me", Name = "Adopt Me!", PlaceId = 920587237, Placeholder = true}),
    table.freeze({BuiltInId = "preview_blade_ball", Name = "Blade Ball", PlaceId = 13772394625, Placeholder = true}),
    table.freeze({BuiltInId = "preview_pet_simulator_99", Name = "Pet Simulator 99", PlaceId = 8737899170, Placeholder = true}),
    table.freeze({BuiltInId = "preview_jailbreak", Name = "Jailbreak", PlaceId = 606849621, Placeholder = true}),
    table.freeze({BuiltInId = "preview_tower_of_hell", Name = "Tower of Hell", PlaceId = 1962086868, Placeholder = true}),
    table.freeze({BuiltInId = "preview_rivals", Name = "RIVALS", PlaceId = 17625359962, Placeholder = true}),
    table.freeze({BuiltInId = "preview_dress_to_impress", Name = "Dress To Impress", PlaceId = 15101393044, Placeholder = true}),
    table.freeze({BuiltInId = "preview_prison_life", Name = "Prison Life", PlaceId = 155615604, Placeholder = true}),
    table.freeze({BuiltInId = "preview_build_a_boat", Name = "Build A Boat For Treasure", PlaceId = 537413528, Placeholder = true})
})

local function copyEntry(source)
    local copy = {}
    for key, value in pairs(source) do
        if key ~= "Status" and key ~= "Features" then copy[key] = value end
    end
    return table.freeze(copy)
end

local function getStatus(entry)
    return STATUS_BY_ID[tostring(entry.BuiltInId or "")] or "Supported"
end

local function getFeatures(entry)
    return FEATURES_BY_ID[tostring(entry.BuiltInId or "")] or "CUSTOM  •  SCRIPT"
end

function CatalogModule.Create(context)
    assert(type(context) == "table", "catalog context is required")
    assert(context.Parent, "catalog parent is required")
    assert(type(context.Animate) == "function", "catalog animate service is required")
    assert(type(context.GetAnchorPoint) == "function", "catalog anchor provider is required")
    assert(type(context.GetViewportSize) == "function", "catalog viewport provider is required")
    assert(type(context.GetEntries) == "function", "catalog entries provider is required")
    assert(type(context.RunEntry) == "function", "catalog execution service is required")
    assert(context.InputService, "catalog input service is required")

    local theme, fonts = context.Theme, context.Fonts
    local motion, layout = context.Motion, context.Layout
    assert(type(theme) == "table" and type(fonts) == "table", "catalog visual tokens are required")
    assert(type(motion) == "table" and type(layout) == "table", "catalog motion/layout tokens are required")

    local animate = context.Animate
    local playSound = context.PlaySound or function() end
    local trackConnection = context.TrackConnection or function(connection) return connection end
    local inputService = context.InputService
    local connections = {}
    local destroyed, dragging = false, false
    local transitionRevision, toastRevision = 0, 0
    local state, restingPosition, dragStart, dragWindowStart = "Closed", nil, nil, nil
    local windowPixelSize = Vector2.new(layout.WindowWidth, layout.WindowHeight)

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        trackConnection(connection)
        return connection
    end

    local function round(object, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = object
        return corner
    end

    local function outline(object, thickness, transparency, color)
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = color or theme.Base
        stroke.Thickness = thickness
        stroke.Transparency = transparency or 0
        stroke.Parent = object
        return stroke
    end

    local function statusColor(status)
        if status == "Stable" then return theme.Success end
        if status == "Supported" then return theme.Warning end
        return theme.Danger
    end

    local function windowSize()
        local viewport = context.GetViewportSize()
        return viewport, Vector2.new(
            math.min(layout.WindowWidth, math.max(360, viewport.X - layout.ViewportInset * 2)),
            math.min(layout.WindowHeight, math.max(360, viewport.Y - layout.ViewportInset * 2))
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
        windowPixelSize = size
        restingPosition = clampCenter(restingPosition or viewport * 0.5, size, viewport)
        return viewport, size, restingPosition
    end

    local root = Instance.new("Frame")
    root.Name = "GameCatalogRoot"
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Size = UDim2.fromScale(1, 1)
    root.ZIndex = 3000
    root.Parent = context.Parent

    local window = Instance.new("CanvasGroup")
    window.Name = "GameCatalogWindow"
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.BackgroundColor3 = theme.Layer
    window.BackgroundTransparency = 1
    window.BorderSizePixel = 0
    window.ClipsDescendants = false
    window.GroupTransparency = 1
    window.Size = UDim2.fromOffset(layout.WindowWidth, layout.WindowHeight)
    window.Visible = false
    window.ZIndex = 3001
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
    clip.ZIndex = 3002
    clip.Parent = window
    round(clip, layout.WindowRadius)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Active = true
    header.BackgroundColor3 = theme.Base
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, layout.HeaderHeight)
    header.ZIndex = 3002
    header.Parent = clip

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.FontFace = fonts.HeadingBlack
    title.Position = UDim2.fromScale(0.5, 0.5)
    title.Size = UDim2.fromOffset(220, layout.HeaderHeight)
    title.Text = context.Title or "Oyun Kataloğu"
    title.TextColor3 = theme.Signal
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 3003
    title.Parent = header

    local applyFilters = function() end
    local close = function() return false end
    local showAllScripts = false

    local allSwitch = Instance.new("TextButton")
    allSwitch.Name = "ShowAllScripts"
    allSwitch.AnchorPoint = Vector2.new(0, 0.5)
    allSwitch.AutoButtonColor = false
    allSwitch.BackgroundTransparency = 1
    allSwitch.BorderSizePixel = 0
    allSwitch.Position = UDim2.new(0, 14, 0.5, 0)
    allSwitch.Size = UDim2.fromOffset(92, 32)
    allSwitch.Text = ""
    allSwitch.ZIndex = 3005
    allSwitch.Parent = header

    local switchTrack = Instance.new("Frame")
    switchTrack.AnchorPoint = Vector2.new(0, 0.5)
    switchTrack.BackgroundColor3 = theme.Layer
    switchTrack.BackgroundTransparency = 0.08
    switchTrack.BorderSizePixel = 0
    switchTrack.Position = UDim2.new(0, 0, 0.5, 0)
    switchTrack.Size = UDim2.fromOffset(36, 20)
    switchTrack.ZIndex = 3006
    switchTrack.Parent = allSwitch
    round(switchTrack, 999)
    outline(switchTrack, 1, 0.25, theme.Signal)

    local switchKnob = Instance.new("Frame")
    switchKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    switchKnob.BackgroundColor3 = theme.Signal
    switchKnob.BorderSizePixel = 0
    switchKnob.Position = UDim2.new(0, 8, 0.5, 0)
    switchKnob.Size = UDim2.fromOffset(14, 14)
    switchKnob.ZIndex = 3007
    switchKnob.Parent = switchTrack
    round(switchKnob, 999)

    local switchLabel = Instance.new("TextLabel")
    switchLabel.BackgroundTransparency = 1
    switchLabel.FontFace = fonts.HeadingHeavy
    switchLabel.Position = UDim2.fromOffset(44, 0)
    switchLabel.Size = UDim2.new(1, -44, 1, 0)
    switchLabel.Text = "Tümü"
    switchLabel.TextColor3 = theme.Signal
    switchLabel.TextSize = 13
    switchLabel.TextTransparency = 0.18
    switchLabel.TextXAlignment = Enum.TextXAlignment.Left
    switchLabel.ZIndex = 3006
    switchLabel.Parent = allSwitch

    local function refreshAllSwitch(instant)
        local trackColor = showAllScripts and theme.Signal or theme.Layer
        local trackTransparency = showAllScripts and 0 or 0.08
        local knobColor = showAllScripts and theme.Base or theme.Signal
        local knobPosition = showAllScripts and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
        if instant then
            switchTrack.BackgroundColor3 = trackColor
            switchTrack.BackgroundTransparency = trackTransparency
            switchKnob.BackgroundColor3 = knobColor
            switchKnob.Position = knobPosition
            return
        end
        animate(switchTrack, {
            BackgroundColor3 = trackColor,
            BackgroundTransparency = trackTransparency
        }, motion.Control, Enum.EasingStyle.Quint)
        animate(switchKnob, {
            BackgroundColor3 = knobColor,
            Position = knobPosition
        }, motion.Control, Enum.EasingStyle.Quint)
    end
    refreshAllSwitch(true)
    connect(allSwitch.Activated, function()
        if state ~= "Open" then return end
        showAllScripts = not showAllScripts
        playSound("ButtonClick")
        refreshAllSwitch(false)
        applyFilters(true)
    end)

    local headerDrag = Instance.new("Frame")
    headerDrag.Name = "HeaderDragArea"
    headerDrag.Active = true
    headerDrag.BackgroundTransparency = 1
    headerDrag.BorderSizePixel = 0
    headerDrag.Size = UDim2.fromScale(1, 1)
    headerDrag.ZIndex = 3004
    headerDrag.Parent = header

    local function headerButton(name, rightOffset, label)
        local button = Instance.new("TextButton")
        button.Name = name
        button.AnchorPoint = Vector2.new(1, 0.5)
        button.AutoButtonColor = false
        button.BackgroundColor3 = theme.Layer
        button.BackgroundTransparency = 0.12
        button.BorderSizePixel = 0
        button.FontFace = fonts.HeadingHeavy
        button.Position = UDim2.new(1, rightOffset, 0.5, 0)
        button.Size = UDim2.fromOffset(40, 40)
        button.Text = label or ""
        button.TextColor3 = theme.Signal
        button.TextSize = 24
        button.ZIndex = 3005
        button.Parent = header
        round(button, 12)
        outline(button, 2, 0.08)
        connect(button.MouseEnter, function()
            animate(button, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
        end)
        connect(button.MouseLeave, function()
            animate(button, {BackgroundTransparency = 0.12}, motion.Control, Enum.EasingStyle.Quint)
        end)
        return button
    end

    local closeButton = headerButton("Close", -14, "×")
    local searchButton = headerButton("Search", -62, "")

    local searchRing = Instance.new("Frame")
    searchRing.AnchorPoint = Vector2.new(0.5, 0.5)
    searchRing.BackgroundTransparency = 1
    searchRing.BorderSizePixel = 0
    searchRing.Position = UDim2.fromOffset(18, 17)
    searchRing.Size = UDim2.fromOffset(14, 14)
    searchRing.ZIndex = 3006
    searchRing.Parent = searchButton
    round(searchRing, 999)
    outline(searchRing, 2, 0, theme.Signal)

    local searchHandle = Instance.new("Frame")
    searchHandle.AnchorPoint = Vector2.new(0.5, 0)
    searchHandle.BackgroundColor3 = theme.Signal
    searchHandle.BorderSizePixel = 0
    searchHandle.Position = UDim2.fromOffset(27, 25)
    searchHandle.Rotation = -45
    searchHandle.Size = UDim2.fromOffset(2, 8)
    searchHandle.ZIndex = 3006
    searchHandle.Parent = searchButton
    round(searchHandle, 999)

    local searchShell = Instance.new("Frame")
    searchShell.Name = "SearchShell"
    searchShell.Active = true
    searchShell.AnchorPoint = Vector2.new(1, 0.5)
    searchShell.BackgroundColor3 = theme.Layer
    searchShell.BackgroundTransparency = 0.08
    searchShell.BorderSizePixel = 0
    searchShell.ClipsDescendants = true
    searchShell.Position = UDim2.new(1, -110, 0.5, 0)
    searchShell.Size = UDim2.fromOffset(0, 36)
    searchShell.Visible = false
    searchShell.ZIndex = 3005
    searchShell.Parent = header
    round(searchShell, 10)
    outline(searchShell, 2, 0.08)

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchInput"
    searchBox.BackgroundTransparency = 1
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.FontFace = fonts.Body
    searchBox.PlaceholderColor3 = theme.Signal
    searchBox.PlaceholderText = "Ara..."
    searchBox.Position = UDim2.fromOffset(0, 0)
    searchBox.Size = UDim2.new(1, -48, 1, 0)
    searchBox.Text = ""
    searchBox.TextColor3 = theme.Signal
    searchBox.TextSize = 14
    searchBox.TextTransparency = 1
    searchBox.TextTruncate = Enum.TextTruncate.AtEnd
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ZIndex = 3006
    searchBox.Parent = searchShell
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 11)
    searchPadding.PaddingRight = UDim.new(0, 6)
    searchPadding.Parent = searchBox

    local resultLabel = Instance.new("TextLabel")
    resultLabel.Name = "SearchResultCount"
    resultLabel.BackgroundTransparency = 1
    resultLabel.FontFace = fonts.HeadingHeavy
    resultLabel.Position = UDim2.new(1, -48, 0, 0)
    resultLabel.Size = UDim2.fromOffset(48, 36)
    resultLabel.Text = "0 / 0"
    resultLabel.TextColor3 = theme.Signal
    resultLabel.TextSize = 13
    resultLabel.TextTransparency = 0.18
    resultLabel.TextXAlignment = Enum.TextXAlignment.Center
    resultLabel.ZIndex = 3006
    resultLabel.Parent = searchShell

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundColor3 = theme.Layer
    body.BackgroundTransparency = layout.BodyTransparency
    body.BorderSizePixel = 0
    body.Position = UDim2.fromOffset(0, layout.HeaderHeight)
    body.Size = UDim2.new(1, 0, 1, -(layout.HeaderHeight + layout.FooterHeight))
    body.ZIndex = 3002
    body.Parent = clip

    local catalogScroll = Instance.new("ScrollingFrame")
    catalogScroll.Name = "Catalog"
    catalogScroll.Active = true
    catalogScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    catalogScroll.BackgroundTransparency = 1
    catalogScroll.BorderSizePixel = 0
    catalogScroll.CanvasSize = UDim2.fromOffset(0, 0)
    catalogScroll.ClipsDescendants = true
    catalogScroll.Position = UDim2.fromOffset(layout.ContentPadding, layout.ContentPadding)
    catalogScroll.ScrollBarImageColor3 = theme.Signal
    catalogScroll.ScrollBarImageTransparency = 0.35
    catalogScroll.ScrollBarThickness = 5
    catalogScroll.Size = UDim2.new(1, -layout.ContentPadding * 2, 1, -layout.ContentPadding * 2)
    catalogScroll.Visible = false
    catalogScroll.ZIndex = 3003
    catalogScroll.Parent = body

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.FontFace = fonts.HeadingHeavy
    emptyLabel.Position = UDim2.fromScale(0.1, 0.4)
    emptyLabel.Size = UDim2.fromScale(0.8, 0.14)
    emptyLabel.Text = "Sonuç bulunamadı"
    emptyLabel.TextColor3 = theme.Signal
    emptyLabel.TextSize = 19
    emptyLabel.TextTransparency = 0.28
    emptyLabel.Visible = false
    emptyLabel.ZIndex = 3004
    emptyLabel.Parent = body

    local contentRevealOverlay = Instance.new("Frame")
    contentRevealOverlay.Name = "ContentRevealOverlay"
    contentRevealOverlay.Active = false
    contentRevealOverlay.BackgroundColor3 = theme.Layer
    contentRevealOverlay.BackgroundTransparency = 0
    contentRevealOverlay.BorderSizePixel = 0
    contentRevealOverlay.Size = UDim2.fromScale(1, 1)
    contentRevealOverlay.Visible = false
    contentRevealOverlay.ZIndex = 3018
    contentRevealOverlay.Parent = body

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Active = true
    footer.AnchorPoint = Vector2.new(0, 1)
    footer.BackgroundColor3 = theme.Base
    footer.BorderSizePixel = 0
    footer.Position = UDim2.fromScale(0, 1)
    footer.Size = UDim2.new(1, 0, 0, layout.FooterHeight)
    footer.ZIndex = 3002
    footer.Parent = clip

    local toast = Instance.new("CanvasGroup")
    toast.Name = "CatalogStatusToast"
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.BackgroundColor3 = theme.Success
    toast.BackgroundTransparency = 0.04
    toast.BorderSizePixel = 0
    toast.GroupTransparency = 1
    toast.Position = UDim2.new(0.5, 0, 1, 10)
    toast.Size = UDim2.fromOffset(layout.ToastWidth, layout.ToastHeight)
    toast.Visible = false
    toast.ZIndex = 3020
    toast.Parent = window
    round(toast, 11)
    local toastStroke = outline(toast, 2, 0.05, theme.Success)
    local toastScale = Instance.new("UIScale")
    toastScale.Scale = 0.94
    toastScale.Parent = toast

    local toastText = Instance.new("TextLabel")
    toastText.BackgroundTransparency = 1
    toastText.FontFace = fonts.HeadingHeavy
    toastText.Size = UDim2.fromScale(1, 1)
    toastText.Text = ""
    toastText.TextColor3 = theme.Base
    toastText.TextSize = layout.ToastTextSize
    toastText.TextTruncate = Enum.TextTruncate.AtEnd
    toastText.ZIndex = 3021
    toastText.Parent = toast
    local toastPadding = Instance.new("UIPadding")
    toastPadding.PaddingLeft = UDim.new(0, 14)
    toastPadding.PaddingRight = UDim.new(0, 14)
    toastPadding.Parent = toastText

    local function showToast(message, color)
        toastRevision = toastRevision + 1
        local revision = toastRevision
        toast.BackgroundColor3, toastStroke.Color, toastText.Text = color, color, tostring(message or "")
        toast.Visible, toast.GroupTransparency = true, 1
        toast.Position, toastScale.Scale = UDim2.new(0.5, 0, 1, 10), 0.94
        animate(toast, {GroupTransparency = 0, Position = UDim2.new(0.5, 0, 1, -7)}, motion.Toast, Enum.EasingStyle.Quint)
        animate(toastScale, {Scale = 1}, motion.Toast, Enum.EasingStyle.Back)
        task.delay(layout.ToastDuration, function()
            if destroyed or revision ~= toastRevision then return end
            local tween = animate(toast, {GroupTransparency = 1, Position = UDim2.new(0.5, 0, 1, 8)}, motion.Toast, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.spawn(function()
                tween.Completed:Wait()
                if not destroyed and revision == toastRevision then toast.Visible = false end
            end)
        end)
    end

    local function shakeCard(card)
        task.spawn(function()
            for _, offset in ipairs({-7, 7, -5, 5, -3, 3, 0}) do
                if destroyed or not card.Parent then return end
                local tween = animate(card, {Position = UDim2.new(0.5, offset, 0.5, 0)}, motion.ShakeStep, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tween.Completed:Wait()
            end
        end)
    end

    local activeCards = {}
    local allItems = {}
    local filteredItems = {}
    local coverCache = {}
    local virtualFirstRow = -1
    local virtualCellWidth = -1
    local contentLoaded, contentRevision = false, 0

    local function createCard(entry, index)
        local cardContentRevision = contentRevision
        local status, featureText = getStatus(entry), getFeatures(entry)
        local cardConnections = {}
        local function cardConnect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(cardConnections, connection)
            return connection
        end
        local slot = Instance.new("Frame")
        slot.Name = "CatalogCardSlot"
        slot.BackgroundTransparency = 1
        slot.BorderSizePixel = 0
        slot.ClipsDescendants = false
        slot.LayoutOrder = index
        slot.ZIndex = 3004
        slot.Parent = catalogScroll

        local card = Instance.new("ImageButton")
        card.Name = "CatalogCard"
        card.Active = true
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.AutoButtonColor = false
        card.BackgroundColor3 = theme.Layer
        card.BackgroundTransparency = 0.08
        card.BorderSizePixel = 0
        card.Image = ""
        card.Position = UDim2.fromScale(0.5, 0.5)
        card.Size = UDim2.fromScale(1, 1)
        card.ZIndex = 3004
        card.Parent = slot
        round(card, 15)
        outline(card, layout.CardStroke, 0.08)
        local glow = outline(card, layout.CardGlowStroke, 1, theme.Warning)
        glow.Name = "InteractionGlow"
        local scale = Instance.new("UIScale")
        scale.Parent = card

        local fallback = Instance.new("Frame")
        fallback.BackgroundColor3 = theme.Base
        fallback.BackgroundTransparency = 0.18
        fallback.BorderSizePixel = 0
        fallback.ClipsDescendants = true
        fallback.Position = UDim2.fromOffset(8, 8)
        fallback.Size = UDim2.new(1, -16, 0, layout.CoverHeight)
        fallback.ZIndex = 3005
        fallback.Parent = card
        round(fallback, 10)
        local fallbackText = Instance.new("TextLabel")
        fallbackText.BackgroundTransparency = 1
        fallbackText.FontFace = fonts.HeadingHeavy
        fallbackText.Position = UDim2.fromScale(0.08, 0.1)
        fallbackText.Size = UDim2.fromScale(0.84, 0.72)
        fallbackText.Text = tostring(entry.Name or "Oyun")
        fallbackText.TextColor3 = theme.Signal
        fallbackText.TextSize = 17
        fallbackText.TextTransparency = 0.24
        fallbackText.TextWrapped = true
        fallbackText.ZIndex = 3006
        fallbackText.Parent = fallback

        local cover = Instance.new("ImageLabel")
        cover.BackgroundTransparency = 1
        cover.BorderSizePixel = 0
        cover.Image = ""
        cover.ImageTransparency = 1
        cover.ClipsDescendants = true
        cover.Position = UDim2.fromOffset(8, 8)
        cover.ScaleType = Enum.ScaleType.Crop
        cover.Size = UDim2.new(1, -16, 0, layout.CoverHeight)
        cover.ZIndex = 3006
        cover.Parent = card
        round(cover, 10)

        local statusStrip = Instance.new("Frame")
        statusStrip.AnchorPoint = Vector2.new(0, 1)
        statusStrip.BackgroundColor3 = statusColor(status)
        statusStrip.BackgroundTransparency = 0.12
        statusStrip.BorderSizePixel = 0
        statusStrip.Position = UDim2.fromScale(0, 1)
        statusStrip.Size = UDim2.new(1, 0, 0, layout.StatusHeight)
        statusStrip.ZIndex = 3007
        statusStrip.Parent = cover
        local statusLabel = Instance.new("TextLabel")
        statusLabel.BackgroundTransparency = 1
        statusLabel.FontFace = fonts.HeadingBlack
        statusLabel.Size = UDim2.fromScale(1, 1)
        statusLabel.Text = status
        statusLabel.TextColor3 = theme.Base
        statusLabel.TextSize = 10
        statusLabel.ZIndex = 3008
        statusLabel.Parent = statusStrip

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.FontFace = fonts.HeadingBlack
        nameLabel.Position = UDim2.fromOffset(10, 8 + layout.CoverHeight + 10)
        nameLabel.Size = UDim2.new(1, -20, 0, 31)
        nameLabel.Text = tostring(entry.Name or "Adsız Script")
        nameLabel.TextColor3 = theme.Signal
        nameLabel.TextSize = 21
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 3005
        nameLabel.Parent = card

        local featureLabel = Instance.new("TextLabel")
        featureLabel.BackgroundTransparency = 1
        featureLabel.FontFace = fonts.Body
        featureLabel.Position = UDim2.fromOffset(10, 8 + layout.CoverHeight + 42)
        featureLabel.Size = UDim2.new(1, -20, 0, 34)
        featureLabel.Text = featureText
        featureLabel.TextColor3 = theme.Signal
        featureLabel.TextSize = 12
        featureLabel.TextTransparency = 0.28
        featureLabel.TextTruncate = Enum.TextTruncate.AtEnd
        featureLabel.TextWrapped = true
        featureLabel.TextXAlignment = Enum.TextXAlignment.Left
        featureLabel.TextYAlignment = Enum.TextYAlignment.Top
        featureLabel.ZIndex = 3005
        featureLabel.Parent = card

        local hovering, outcomeActive, outcomeRevision = false, false, 0
        local function restoreHover()
            if destroyed or not card.Parent then return end
            outcomeActive = false
            animate(glow, {Color = theme.Warning, Transparency = hovering and 0.08 or 1}, motion.Glow, Enum.EasingStyle.Quint)
        end
        local function showOutcome(color, shouldShake)
            outcomeActive, outcomeRevision = true, outcomeRevision + 1
            local revision = outcomeRevision
            animate(glow, {Color = color, Transparency = 0}, motion.Glow, Enum.EasingStyle.Quint)
            if shouldShake then shakeCard(card) end
            task.delay(layout.OutcomeGlowDuration, function()
                if revision == outcomeRevision then restoreHover() end
            end)
        end

        cardConnect(card.MouseEnter, function()
            hovering = true
            playSound("ButtonHover")
            animate(scale, {Scale = 1.012}, motion.Control, Enum.EasingStyle.Quint)
            animate(card, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
            if not outcomeActive then animate(glow, {Color = theme.Warning, Transparency = 0.08}, motion.Glow, Enum.EasingStyle.Quint) end
        end)
        cardConnect(card.MouseLeave, function()
            hovering = false
            animate(scale, {Scale = 1}, motion.Control, Enum.EasingStyle.Quint)
            animate(card, {BackgroundTransparency = 0.08}, motion.Control, Enum.EasingStyle.Quint)
            if not outcomeActive then animate(glow, {Transparency = 1}, motion.Glow, Enum.EasingStyle.Quint) end
        end)
        cardConnect(card.Activated, function()
            if state ~= "Open" then return end
            playSound("ButtonClick")
            if entry.Placeholder then
                local message = status == "Un-Supported" and (tostring(entry.Name) .. " henüz desteklenmiyor") or (tostring(entry.Name) .. " scripti henüz kataloğa eklenmedi")
                showOutcome(theme.Danger, true)
                showToast(message, theme.Danger)
                return
            end
            if status == "Un-Supported" then
                showOutcome(theme.Danger, true)
                showToast(tostring(entry.Name) .. " şu anda desteklenmiyor", theme.Danger)
                return
            end
            task.spawn(function()
                local result = context.RunEntry(entry)
                if destroyed or not card.Parent then return end
                if result and result.Ok then
                    showOutcome(theme.Success, false)
                    showToast(result.Message or (tostring(entry.Name) .. " çalıştırıldı"), theme.Success)
                    local closing = close()
                    if type(result.Activate) == "function" then
                        task.delay(closing and motion.Close or 0, function()
                            if destroyed then return end
                            pcall(result.Activate)
                        end)
                    end
                else
                    showOutcome(theme.Danger, true)
                    showToast(result and result.Message or "Script çalıştırılamadı", theme.Danger)
                end
            end)
        end)

        if type(context.ResolveCover) == "function" and entry.PlaceId then
            task.spawn(function()
                local cacheKey = tostring(entry.PlaceId)
                local resolved = coverCache[cacheKey]
                if type(resolved) ~= "string" or resolved == "" then
                    resolved = context.ResolveCover(entry.PlaceId)
                    if destroyed or not contentLoaded or cardContentRevision ~= contentRevision or not card.Parent or not cover.Parent then return end
                    if type(resolved) == "string" and resolved ~= "" then coverCache[cacheKey] = resolved end
                end
                if destroyed or not contentLoaded or cardContentRevision ~= contentRevision or not card.Parent or not cover.Parent then return end
                if type(resolved) == "string" and resolved ~= "" then
                    cover.Image, cover.ImageTransparency, fallback.Visible = resolved, 0, false
                end
            end)
        end
        return {Slot = slot, Connections = cardConnections}
    end

    local usedIds = {}
    local entries = context.GetEntries()
    for _, source in ipairs(type(entries) == "table" and entries or {}) do
        local entry = copyEntry(source)
        usedIds[tostring(entry.BuiltInId or "")] = true
        table.insert(allItems, {
            Entry = entry,
            Status = getStatus(entry),
            Features = getFeatures(entry),
            NameKey = string.lower(tostring(entry.Name or "")),
            SearchText = string.lower(tostring(entry.Name or "") .. " " .. tostring(entry.PlaceId or "") .. " " .. tostring(entry.BuiltInId or "") .. " " .. getStatus(entry) .. " " .. getFeatures(entry))
        })
    end
    for _, source in ipairs(PLACEHOLDERS) do
        if not usedIds[tostring(source.BuiltInId)] then
            local entry = copyEntry(source)
            table.insert(allItems, {
                Entry = entry,
                Status = getStatus(entry),
                Features = getFeatures(entry),
                NameKey = string.lower(tostring(entry.Name or "")),
                SearchText = string.lower(tostring(entry.Name or "") .. " " .. tostring(entry.PlaceId or "") .. " " .. tostring(entry.BuiltInId or "") .. " " .. getStatus(entry) .. " " .. getFeatures(entry))
            })
        end
    end

    local statusRank = {Stable = 1, Supported = 2, ["Un-Supported"] = 3}
    table.sort(allItems, function(left, right)
        local leftRank = statusRank[left.Status] or 4
        local rightRank = statusRank[right.Status] or 4
        if leftRank ~= rightRank then return leftRank < rightRank end
        if left.NameKey ~= right.NameKey then return left.NameKey < right.NameKey end
        return tostring(left.Entry.BuiltInId or left.Entry.PlaceId or "") < tostring(right.Entry.BuiltInId or right.Entry.PlaceId or "")
    end)

    local function clearActiveCards()
        for _, record in ipairs(activeCards) do
            for _, connection in ipairs(record.Connections) do
                pcall(function() connection:Disconnect() end)
            end
            if record.Slot and record.Slot.Parent then record.Slot:Destroy() end
        end
        table.clear(activeCards)
    end

    local function renderVirtualPage(force)
        if destroyed then return end
        local gap = layout.GridGap
        local safetyInset = layout.CardGlowStroke + 2
        local stride = layout.CardHeight + gap
        local firstRow = math.max(0, math.floor(math.max(0, catalogScroll.CanvasPosition.Y - safetyInset) / math.max(1, stride)))
        local availableWidth = math.max(1, math.floor(windowPixelSize.X - layout.ContentPadding * 2) - safetyInset * 2)
        local cellWidth = math.max(80, math.floor((availableWidth - gap * 2) / 3))
        if not force and firstRow == virtualFirstRow and cellWidth == virtualCellWidth then return end
        virtualFirstRow, virtualCellWidth = firstRow, cellWidth
        clearActiveCards()
        local rowWidth = cellWidth * 3 + gap * 2
        local startX = safetyInset + math.max(0, math.floor((availableWidth - rowWidth) * 0.5))
        local firstIndex = firstRow * 3 + 1
        for offset = 0, layout.VirtualCardCount - 1 do
            local globalIndex = firstIndex + offset
            local item = filteredItems[globalIndex]
            if not item then break end
            local record = createCard(item.Entry, globalIndex)
            local zeroIndex = globalIndex - 1
            local row, column = math.floor(zeroIndex / 3), zeroIndex % 3
            record.Slot.Position = UDim2.fromOffset(startX + column * (cellWidth + gap), safetyInset + row * stride)
            record.Slot.Size = UDim2.fromOffset(cellWidth, layout.CardHeight)
            table.insert(activeCards, record)
        end
    end

    applyFilters = function(resetScroll)
        local query = string.lower(searchBox.Text:gsub("^%s+", ""):gsub("%s+$", ""))
        table.clear(filteredItems)
        for _, item in ipairs(allItems) do
            local statusAllowed = showAllScripts or item.Status ~= "Un-Supported"
            local queryAllowed = query == "" or string.find(item.SearchText, query, 1, true) ~= nil
            if statusAllowed and queryAllowed then table.insert(filteredItems, item) end
        end
        local rows = math.ceil(#filteredItems / 3)
        local safetyInset = layout.CardGlowStroke + 2
        local canvasHeight = rows > 0 and safetyInset * 2 + rows * layout.CardHeight + math.max(0, rows - 1) * layout.GridGap or 0
        catalogScroll.CanvasSize = UDim2.fromOffset(0, canvasHeight)
        resultLabel.Text = tostring(#filteredItems) .. " / " .. tostring(#allItems)
        emptyLabel.Visible = #filteredItems == 0
        if resetScroll then catalogScroll.CanvasPosition = Vector2.new(0, 0) end
        virtualFirstRow = -1
        if contentLoaded and state ~= "Closing" then renderVirtualPage(true) end
    end

    connect(catalogScroll:GetPropertyChangedSignal("CanvasPosition"), function()
        if contentLoaded and state ~= "Closing" then renderVirtualPage(false) end
    end)
    connect(catalogScroll:GetPropertyChangedSignal("AbsoluteSize"), function()
        if contentLoaded and state ~= "Closing" then renderVirtualPage(false) end
    end)

    local searchOpen, searchRevision, searchPointerInside = false, 0, false
    local function setSearchOpen(open, clearText)
        open = open == true
        if clearText then searchBox.Text = "" end
        if searchOpen == open then return end
        searchOpen, searchRevision = open, searchRevision + 1
        local revision = searchRevision
        if open then
            searchShell.Visible = true
            searchShell.Size = UDim2.fromOffset(0, 36)
            searchBox.TextTransparency = 1
            animate(searchShell, {Size = UDim2.fromOffset(layout.SearchWidth, 36)}, motion.SearchOpen, Enum.EasingStyle.Quint)
            animate(searchBox, {TextTransparency = 0}, motion.SearchOpen, Enum.EasingStyle.Quint)
        else
            searchBox:ReleaseFocus()
            local tween = animate(searchShell, {Size = UDim2.fromOffset(0, 36)}, motion.SearchClose, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            animate(searchBox, {TextTransparency = 1}, motion.SearchClose, Enum.EasingStyle.Quint)
            task.spawn(function()
                tween.Completed:Wait()
                if not destroyed and revision == searchRevision and not searchOpen then
                    searchShell.Visible = false
                end
            end)
        end
    end

    local function scheduleSearchClose()
        local revision = searchRevision
        task.delay(0.18, function()
            if not destroyed and revision == searchRevision and searchOpen and searchBox.Text == "" and not searchPointerInside then
                setSearchOpen(false, false)
            end
        end)
    end
    connect(searchBox:GetPropertyChangedSignal("Text"), function()
        applyFilters(true)
        if searchBox.Text == "" then scheduleSearchClose() end
    end)
    connect(searchButton.MouseEnter, function()
        searchPointerInside = true
        if state == "Open" then setSearchOpen(true, false) end
    end)
    connect(searchButton.MouseLeave, function()
        searchPointerInside = false
        scheduleSearchClose()
    end)
    connect(searchShell.MouseEnter, function() searchPointerInside = true end)
    connect(searchShell.MouseLeave, function()
        searchPointerInside = false
        scheduleSearchClose()
    end)
    connect(searchBox.FocusLost, function()
        if searchBox.Text == "" then
            searchPointerInside = false
            scheduleSearchClose()
        end
    end)
    connect(searchButton.Activated, function()
        if state == "Open" then
            playSound("ButtonClick")
            setSearchOpen(true, false)
            task.defer(function() if searchOpen and searchShell.Visible then searchBox:CaptureFocus() end end)
        end
    end)

    local function setWindowToTarget()
        local _, size, center = targetGeometry()
        window.Size, window.Position = UDim2.fromOffset(size.X, size.Y), UDim2.fromOffset(center.X, center.Y)
    end
    local function beginDrag(input)
        if state ~= "Open" then return end
        dragging, dragStart, dragWindowStart = true, Vector2.new(input.Position.X, input.Position.Y), restingPosition
    end
    connect(headerDrag.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginDrag(input) end
    end)
    connect(footer.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginDrag(input) end
    end)
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
        if destroyed or state == "Open" or state == "Opening" then return false end
        local reversingClose = state == "Closing"
        transitionRevision, state = transitionRevision + 1, "Opening"
        local revision = transitionRevision
        local _, size, center = targetGeometry()
        window.Size = UDim2.fromOffset(size.X, size.Y)
        if not reversingClose then
            local source = context.GetAnchorPoint()
            window.Position = UDim2.fromOffset(source.X, source.Y)
            windowScale.Scale, window.GroupTransparency = 0, 1
        end
        contentRevision = contentRevision + 1
        table.clear(coverCache)
        contentLoaded = false
        catalogScroll.Visible = true
        contentRevealOverlay.BackgroundTransparency = 0
        contentRevealOverlay.Visible = true
        window.Visible = true
        local move = animate(window, {Position = UDim2.fromOffset(center.X, center.Y), GroupTransparency = 0}, motion.Open, Enum.EasingStyle.Quint)
        animate(windowScale, {Scale = 1}, motion.Open, Enum.EasingStyle.Back)
        virtualFirstRow = -1
        applyFilters(true)
        contentLoaded = true
        renderVirtualPage(true)
        local reveal = animate(contentRevealOverlay, {BackgroundTransparency = 1}, motion.ContentReveal or motion.Open, Enum.EasingStyle.Quint)
        task.spawn(function()
            reveal.Completed:Wait()
            if not destroyed and revision == transitionRevision then contentRevealOverlay.Visible = false end
        end)
        task.spawn(function()
            move.Completed:Wait()
            if not destroyed and revision == transitionRevision then state = "Open" end
        end)
        return true
    end

    close = function()
        if destroyed or state == "Closed" or state == "Closing" then return false end
        transitionRevision, state = transitionRevision + 1, "Closing"
        local revision, source = transitionRevision, context.GetAnchorPoint()
        dragging = false
        setSearchOpen(false, true)
        toastRevision, toast.Visible = toastRevision + 1, false
        local move = animate(window, {Position = UDim2.fromOffset(source.X, source.Y), GroupTransparency = 1}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        animate(windowScale, {Scale = 0}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.spawn(function()
            move.Completed:Wait()
            if not destroyed and revision == transitionRevision then
                window.Visible, state = false, "Closed"
                contentRevision = contentRevision + 1
                clearActiveCards()
                table.clear(coverCache)
                table.clear(filteredItems)
                contentLoaded = false
                virtualFirstRow = -1
                virtualCellWidth = -1
                catalogScroll.CanvasPosition = Vector2.new(0, 0)
                catalogScroll.CanvasSize = UDim2.fromOffset(0, 0)
                catalogScroll.Visible = false
                emptyLabel.Visible = false
                contentRevealOverlay.Visible = false
                contentRevealOverlay.BackgroundTransparency = 0
            end
        end)
        return true
    end

    local function toggle()
        return (state == "Open" or state == "Opening") and close() or open()
    end
    connect(closeButton.Activated, function()
        if state == "Open" or state == "Opening" then
            playSound("ButtonClick")
            close()
        end
    end)
    connect(context.Parent:GetPropertyChangedSignal("AbsoluteSize"), function()
        if not destroyed and (state == "Open" or state == "Opening") then setWindowToTarget() end
    end)
    applyFilters(true)

    local controller = {}
    controller.Open, controller.Close, controller.Toggle = open, close, toggle
    controller.IsOpen = function() return state == "Open" or state == "Opening" end
    controller.Destroy = function()
        if destroyed then return end
        destroyed, transitionRevision, toastRevision, contentRevision = true, transitionRevision + 1, toastRevision + 1, contentRevision + 1
        clearActiveCards()
        table.clear(coverCache)
        table.clear(filteredItems)
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        root:Destroy()
    end
    return table.freeze(controller)
end

return table.freeze(CatalogModule)
