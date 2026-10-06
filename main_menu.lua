local MainMenuModule = {Version = 1}

local CATEGORY_META = table.freeze({
    table.freeze({Id = "Home", Label = "Ana Sayfa", Glyph = "⌂"}),
    table.freeze({Id = "Players", Label = "Oyuncular", Glyph = "●●"}),
    table.freeze({Id = "Visuals", Label = "Görseller", Glyph = "◉"}),
    table.freeze({Id = "Aim", Label = "Nişan", Glyph = "⊕"}),
    table.freeze({Id = "Movement", Label = "Hareket", Glyph = "➤"}),
    table.freeze({Id = "World", Label = "Dünya", Glyph = "◇"}),
    table.freeze({Id = "Misc", Label = "Diğer", Glyph = "✦"}),
    table.freeze({Id = "Configs", Label = "Ayarlar", Glyph = "⚙"})
})

local CATEGORY_ORDER = {}
local CATEGORY_BY_ID = {}
for index, item in ipairs(CATEGORY_META) do
    CATEGORY_ORDER[item.Id] = index
    CATEGORY_BY_ID[item.Id] = item
end

local function copyArray(source)
    local result = {}
    for index, value in ipairs(type(source) == "table" and source or {}) do
        result[index] = value
    end
    return result
end

function MainMenuModule.Create(context)
    assert(type(context) == "table", "main menu context is required")
    assert(context.Parent, "main menu parent is required")
    assert(type(context.Animate) == "function", "main menu animate service is required")
    assert(type(context.GetAnchorPoint) == "function", "main menu anchor provider is required")
    assert(type(context.GetViewportSize) == "function", "main menu viewport provider is required")
    assert(type(context.GetIndexEntries) == "function", "main menu search index is required")
    assert(type(context.GetControlValue) == "function", "main menu control getter is required")
    assert(type(context.SetControlValue) == "function", "main menu control setter is required")
    assert(type(context.ActivateControl) == "function", "main menu action service is required")
    assert(context.InputService, "main menu input service is required")

    local theme, fonts = context.Theme, context.Fonts
    local motion, layout = context.Motion, context.Layout
    assert(type(theme) == "table" and type(fonts) == "table", "main menu visual tokens are required")
    assert(type(motion) == "table" and type(layout) == "table", "main menu motion/layout tokens are required")

    local animate = context.Animate
    local playSound = context.PlaySound or function() end
    local trackConnection = context.TrackConnection or function(connection) return connection end
    local inputService = context.InputService
    local connections = {}
    local pageConnections, searchConnections = {}, {}
    local destroyed, dragging = false, false
    local state, transitionRevision = "Closed", 0
    local pageRevision, searchShellRevision, searchResultsRevision = 0, 0, 0
    local currentCategory, currentPage = "Home", nil
    local currentRenderers, currentRows = {}, {}
    local restingPosition, dragStart, dragWindowStart = nil, nil, nil
    local windowPixelSize = Vector2.new(layout.WindowWidth, layout.WindowHeight)
    local sidebarExpanded = true
    local searchOpen, searchPointerInside = false, false
    local activeSlider = nil

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        trackConnection(connection)
        return connection
    end

    local function scopedConnect(bucket, signal, callback)
        local connection = signal:Connect(callback)
        table.insert(bucket, connection)
        return connection
    end

    local function clearScopedConnections(bucket)
        for _, connection in ipairs(bucket) do pcall(function() connection:Disconnect() end) end
        table.clear(bucket)
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

    local function normalizedText(value)
        return string.lower(tostring(value or ""))
    end

    local function displayValue(value)
        if type(value) == "boolean" then return value and "Açık" or "Kapalı" end
        if type(value) == "table" then
            local values = {}
            for _, item in ipairs(value) do table.insert(values, tostring(item)) end
            return #values > 0 and table.concat(values, ", ") or "Yok"
        end
        if typeof(value) == "Color3" then
            return string.format("#%02X%02X%02X", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
        end
        return tostring(value == nil and "Yok" or value)
    end

    local function windowSize()
        local viewport = context.GetViewportSize()
        return viewport, Vector2.new(
            math.min(layout.WindowWidth, math.max(420, viewport.X - layout.ViewportInset * 2)),
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
    root.Name = "MainMenuRoot"
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Size = UDim2.fromScale(1, 1)
    root.ZIndex = 4000
    root.Parent = context.Parent

    local window = Instance.new("CanvasGroup")
    window.Name = "MainMenuWindow"
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.BackgroundColor3 = theme.Layer
    window.BackgroundTransparency = 1
    window.BorderSizePixel = 0
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
    headerDrag.ZIndex = 4003
    headerDrag.Parent = header

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.FontFace = fonts.HeadingBlack
    title.Position = UDim2.fromScale(0.5, 0.5)
    title.Size = UDim2.fromOffset(250, layout.HeaderHeight)
    title.Text = context.Title or "TasuHub"
    title.TextColor3 = theme.Signal
    title.TextSize = 22
    title.ZIndex = 4004
    title.Parent = header

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
        button.ZIndex = 4008
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
    searchRing.ZIndex = 4009
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
    searchHandle.ZIndex = 4009
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
    searchShell.ZIndex = 4008
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
    searchBox.Size = UDim2.new(1, -48, 1, 0)
    searchBox.Text = ""
    searchBox.TextColor3 = theme.Signal
    searchBox.TextSize = 14
    searchBox.TextTransparency = 1
    searchBox.TextTruncate = Enum.TextTruncate.AtEnd
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ZIndex = 4009
    searchBox.Parent = searchShell
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 11)
    searchPadding.PaddingRight = UDim.new(0, 6)
    searchPadding.Parent = searchBox

    local searchCount = Instance.new("TextLabel")
    searchCount.BackgroundTransparency = 1
    searchCount.FontFace = fonts.HeadingHeavy
    searchCount.Position = UDim2.new(1, -48, 0, 0)
    searchCount.Size = UDim2.fromOffset(48, 36)
    searchCount.Text = "0"
    searchCount.TextColor3 = theme.Signal
    searchCount.TextSize = 13
    searchCount.TextTransparency = 0.18
    searchCount.ZIndex = 4009
    searchCount.Parent = searchShell

    local hamburger = Instance.new("TextButton")
    hamburger.Name = "NavigationToggle"
    hamburger.AutoButtonColor = false
    hamburger.BackgroundColor3 = theme.Layer
    hamburger.BackgroundTransparency = 0.12
    hamburger.BorderSizePixel = 0
    hamburger.Position = UDim2.fromOffset(14, 10)
    hamburger.Size = UDim2.fromOffset(40, 40)
    hamburger.Text = ""
    hamburger.ZIndex = 4008
    hamburger.Parent = header
    round(hamburger, 12)
    outline(hamburger, 2, 0.08)
    for lineIndex = 1, 3 do
        local line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BackgroundColor3 = theme.Signal
        line.BorderSizePixel = 0
        line.Position = UDim2.fromOffset(20, 13 + (lineIndex - 1) * 7)
        line.Size = UDim2.fromOffset(lineIndex == 2 and 18 or 22, 2)
        line.ZIndex = 4009
        line.Parent = hamburger
        round(line, 999)
    end
    connect(hamburger.MouseEnter, function()
        animate(hamburger, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
    end)
    connect(hamburger.MouseLeave, function()
        animate(hamburger, {BackgroundTransparency = 0.12}, motion.Control, Enum.EasingStyle.Quint)
    end)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundColor3 = theme.Layer
    body.BackgroundTransparency = layout.BodyTransparency
    body.BorderSizePixel = 0
    body.Position = UDim2.fromOffset(0, layout.HeaderHeight)
    body.Size = UDim2.new(1, 0, 1, -layout.HeaderHeight)
    body.ZIndex = 4002
    body.Parent = clip

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Navigation"
    sidebar.BackgroundColor3 = theme.Layer
    sidebar.BackgroundTransparency = 0.08
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Size = UDim2.new(0, layout.SidebarExpandedWidth, 1, 0)
    sidebar.ZIndex = 4004
    sidebar.Parent = body
    local sidebarEdge = Instance.new("Frame")
    sidebarEdge.AnchorPoint = Vector2.new(1, 0)
    sidebarEdge.BackgroundColor3 = theme.Base
    sidebarEdge.BackgroundTransparency = 0.35
    sidebarEdge.BorderSizePixel = 0
    sidebarEdge.Position = UDim2.fromScale(1, 0)
    sidebarEdge.Size = UDim2.new(0, 2, 1, 0)
    sidebarEdge.ZIndex = 4005
    sidebarEdge.Parent = sidebar

    local navScroll = Instance.new("ScrollingFrame")
    navScroll.Name = "Categories"
    navScroll.Active = true
    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navScroll.BackgroundTransparency = 1
    navScroll.BorderSizePixel = 0
    navScroll.CanvasSize = UDim2.new()
    navScroll.Position = UDim2.fromOffset(0, 10)
    navScroll.ScrollBarImageColor3 = theme.Signal
    navScroll.ScrollBarImageTransparency = 0.55
    navScroll.ScrollBarThickness = 2
    navScroll.Size = UDim2.new(1, 0, 1, -20)
    navScroll.ZIndex = 4005
    navScroll.Parent = sidebar
    local navLayout = Instance.new("UIListLayout")
    navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navLayout.Padding = UDim.new(0, 8)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent = navScroll

    local contentHost = Instance.new("Frame")
    contentHost.Name = "PageHost"
    contentHost.BackgroundTransparency = 1
    contentHost.BorderSizePixel = 0
    contentHost.ClipsDescendants = true
    contentHost.Position = UDim2.fromOffset(layout.SidebarExpandedWidth + layout.ContentPadding, layout.ContentPadding)
    contentHost.Size = UDim2.new(1, -(layout.SidebarExpandedWidth + layout.ContentPadding * 2), 1, -layout.ContentPadding * 2)
    contentHost.ZIndex = 4003
    contentHost.Parent = body

    local searchResults = Instance.new("CanvasGroup")
    searchResults.Name = "SearchResults"
    searchResults.AnchorPoint = Vector2.new(1, 0)
    searchResults.BackgroundColor3 = theme.Base
    searchResults.BackgroundTransparency = 0.04
    searchResults.BorderSizePixel = 0
    searchResults.ClipsDescendants = true
    searchResults.GroupTransparency = 1
    searchResults.Position = UDim2.new(1, -14, 0, 10)
    searchResults.Size = UDim2.fromOffset(390, 0)
    searchResults.Visible = false
    searchResults.ZIndex = 4030
    searchResults.Parent = body
    round(searchResults, 12)
    outline(searchResults, 2, 0.08)

    local searchList = Instance.new("ScrollingFrame")
    searchList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    searchList.BackgroundTransparency = 1
    searchList.BorderSizePixel = 0
    searchList.CanvasSize = UDim2.new()
    searchList.ScrollBarImageColor3 = theme.Signal
    searchList.ScrollBarImageTransparency = 0.4
    searchList.ScrollBarThickness = 3
    searchList.Size = UDim2.fromScale(1, 1)
    searchList.ZIndex = 4031
    searchList.Parent = searchResults
    local searchListLayout = Instance.new("UIListLayout")
    searchListLayout.Padding = UDim.new(0, 5)
    searchListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    searchListLayout.Parent = searchList
    local searchListPadding = Instance.new("UIPadding")
    searchListPadding.PaddingLeft = UDim.new(0, 7)
    searchListPadding.PaddingRight = UDim.new(0, 9)
    searchListPadding.PaddingTop = UDim.new(0, 7)
    searchListPadding.PaddingBottom = UDim.new(0, 7)
    searchListPadding.Parent = searchList

    local indexEntries = copyArray(context.GetIndexEntries())
    table.sort(indexEntries, function(first, second)
        local leftOrder = CATEGORY_ORDER[first.Category] or 99
        local rightOrder = CATEGORY_ORDER[second.Category] or 99
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        if tostring(first.Section) ~= tostring(second.Section) then return tostring(first.Section) < tostring(second.Section) end
        return tostring(first.Label) < tostring(second.Label)
    end)

    local entriesByCategory = {}
    for _, entry in ipairs(indexEntries) do
        if CATEGORY_BY_ID[entry.Category] then
            entriesByCategory[entry.Category] = entriesByCategory[entry.Category] or {}
            table.insert(entriesByCategory[entry.Category], entry)
        end
    end

    local navButtons = {}

    local function createGlyph(parent, meta)
        local glyph = Instance.new("TextLabel")
        glyph.Name = "Icon"
        glyph.AnchorPoint = Vector2.new(0.5, 0.5)
        glyph.BackgroundColor3 = theme.Base
        glyph.BackgroundTransparency = 0.22
        glyph.BorderSizePixel = 0
        glyph.FontFace = fonts.HeadingBlack
        glyph.Position = UDim2.fromOffset(27, layout.NavigationHeight * 0.5)
        glyph.Size = UDim2.fromOffset(30, 30)
        glyph.Text = meta.Glyph
        glyph.TextColor3 = theme.Signal
        glyph.TextSize = meta.Id == "Players" and 11 or 18
        glyph.ZIndex = 4007
        glyph.Parent = parent
        round(glyph, 9)
        return glyph
    end

    for index, meta in ipairs(CATEGORY_META) do
        local button = Instance.new("TextButton")
        button.Name = meta.Id
        button.AutoButtonColor = false
        button.BackgroundColor3 = theme.Base
        button.BackgroundTransparency = 0.22
        button.BorderSizePixel = 0
        button.LayoutOrder = index
        button.Size = UDim2.new(1, -20, 0, layout.NavigationHeight)
        button.Text = ""
        button.ZIndex = 4006
        button.Parent = navScroll
        round(button, 12)
        local stroke = outline(button, 2, 1, theme.Signal)
        local glyph = createGlyph(button, meta)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.FontFace = fonts.HeadingHeavy
        label.Position = UDim2.fromOffset(50, 0)
        label.Size = UDim2.new(1, -62, 1, 0)
        label.Text = meta.Label
        label.TextColor3 = theme.Signal
        label.TextSize = 15
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4007
        label.Parent = button
        navButtons[meta.Id] = {Button = button, Glyph = glyph, Label = label, Stroke = stroke}
    end

    local function isControlVisible(flag)
        if type(context.IsControlVisible) ~= "function" then return true end
        local ok, visible = pcall(context.IsControlVisible, flag)
        return not ok or visible ~= false
    end

    local function getControlValue(flag)
        local ok, value = pcall(context.GetControlValue, flag)
        return ok and value or nil
    end

    local function setControlValue(flag, value)
        local ok, result = pcall(context.SetControlValue, flag, value)
        if ok and result ~= false then
            for _, render in ipairs(currentRenderers) do pcall(render) end
            return true
        end
        return false
    end

    local function getOptions(flag)
        if type(context.GetControlOptions) ~= "function" then return {} end
        local ok, values = pcall(context.GetControlOptions, flag)
        return ok and type(values) == "table" and values or {}
    end

    local function normalizeOptions(values)
        local options = {}
        for _, option in ipairs(values) do
            if type(option) == "table" then
                table.insert(options, {Label = tostring(option.Label or option.Value or "Seçenek"), Value = option.Value})
            else
                table.insert(options, {Label = tostring(option), Value = option})
            end
        end
        return options
    end

    local function makeControlRow(parent, entry)
        local row = Instance.new("Frame")
        row.Name = tostring(entry.Flag):gsub("[^%w_]", "_")
        row.BackgroundColor3 = theme.Base
        row.BackgroundTransparency = 0.26
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, 0, 0, entry.Kind == "Slider" and 58 or 44)
        row.ZIndex = 4010
        row.Parent = parent
        round(row, 10)

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.FontFace = fonts.Body
        label.Position = UDim2.fromOffset(12, 0)
        label.Size = UDim2.new(1, -24, 1, 0)
        label.Text = tostring(entry.Label or entry.Flag)
        label.TextColor3 = theme.Signal
        label.TextSize = 14
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4011
        label.Parent = row

        local function applyVisibility()
            row.Visible = isControlVisible(entry.Flag)
        end

        if entry.Kind == "Toggle" then
            label.Size = UDim2.new(1, -78, 1, 0)
            local toggle = Instance.new("TextButton")
            toggle.AnchorPoint = Vector2.new(1, 0.5)
            toggle.AutoButtonColor = false
            toggle.BackgroundColor3 = theme.Layer
            toggle.BorderSizePixel = 0
            toggle.Position = UDim2.new(1, -11, 0.5, 0)
            toggle.Size = UDim2.fromOffset(42, 24)
            toggle.Text = ""
            toggle.ZIndex = 4012
            toggle.Parent = row
            round(toggle, 999)
            outline(toggle, 1, 0.22, theme.Signal)
            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.BackgroundColor3 = theme.Signal
            knob.BorderSizePixel = 0
            knob.Size = UDim2.fromOffset(16, 16)
            knob.ZIndex = 4013
            knob.Parent = toggle
            round(knob, 999)
            local function render()
                applyVisibility()
                local enabled = getControlValue(entry.Flag) == true
                animate(toggle, {
                    BackgroundColor3 = enabled and theme.Signal or theme.Layer,
                    BackgroundTransparency = enabled and 0 or 0.08
                }, motion.Control, Enum.EasingStyle.Quint)
                animate(knob, {
                    BackgroundColor3 = enabled and theme.Base or theme.Signal,
                    Position = enabled and UDim2.new(1, -9, 0.5, 0) or UDim2.new(0, 9, 0.5, 0)
                }, motion.Control, Enum.EasingStyle.Quint)
            end
            scopedConnect(pageConnections, toggle.Activated, function()
                playSound("ButtonClick")
                setControlValue(entry.Flag, not (getControlValue(entry.Flag) == true))
                render()
            end)
            table.insert(currentRenderers, render)
            render()
        elseif entry.Kind == "Slider" then
            label.Size = UDim2.new(1, -90, 0, 30)
            local valueLabel = Instance.new("TextLabel")
            valueLabel.AnchorPoint = Vector2.new(1, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.FontFace = fonts.HeadingHeavy
            valueLabel.Position = UDim2.new(1, -12, 0, 0)
            valueLabel.Size = UDim2.fromOffset(72, 30)
            valueLabel.TextColor3 = theme.Signal
            valueLabel.TextSize = 13
            valueLabel.TextTransparency = 0.16
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.ZIndex = 4011
            valueLabel.Parent = row
            local bar = Instance.new("Frame")
            bar.Active = true
            bar.BackgroundColor3 = theme.Layer
            bar.BorderSizePixel = 0
            bar.Position = UDim2.fromOffset(12, 39)
            bar.Size = UDim2.new(1, -24, 0, 7)
            bar.ZIndex = 4011
            bar.Parent = row
            round(bar, 999)
            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = theme.Signal
            fill.BorderSizePixel = 0
            fill.Size = UDim2.fromScale(0, 1)
            fill.ZIndex = 4012
            fill.Parent = bar
            round(fill, 999)
            local minimum = tonumber(entry.Minimum) or 0
            local maximum = tonumber(entry.Maximum) or 1
            local decimals = tonumber(entry.Decimals) or 0
            local function render()
                applyVisibility()
                local value = math.clamp(tonumber(getControlValue(entry.Flag)) or minimum, minimum, maximum)
                fill.Size = UDim2.fromScale((value - minimum) / math.max(0.0001, maximum - minimum), 1)
                valueLabel.Text = string.format("%." .. decimals .. "f", value)
            end
            local function update(input)
                local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                local factor = 10 ^ decimals
                local value = minimum + (maximum - minimum) * ratio
                value = math.floor(value * factor + 0.5) / factor
                setControlValue(entry.Flag, value)
                render()
            end
            scopedConnect(pageConnections, bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    activeSlider = {Row = row, Update = update}
                    update(input)
                end
            end)
            table.insert(currentRenderers, render)
            render()
        elseif entry.Kind == "Dropdown" or entry.Kind == "PlayerDropdown" then
            label.Size = UDim2.new(0.42, -12, 1, 0)
            local selector = Instance.new("TextButton")
            selector.AnchorPoint = Vector2.new(1, 0.5)
            selector.AutoButtonColor = false
            selector.BackgroundColor3 = theme.Layer
            selector.BackgroundTransparency = 0.08
            selector.BorderSizePixel = 0
            selector.FontFace = fonts.HeadingHeavy
            selector.Position = UDim2.new(1, -8, 0.5, 0)
            selector.Size = UDim2.new(0.56, 0, 0, 32)
            selector.TextColor3 = theme.Signal
            selector.TextSize = 13
            selector.TextTruncate = Enum.TextTruncate.AtEnd
            selector.ZIndex = 4012
            selector.Parent = row
            round(selector, 8)
            local function render()
                applyVisibility()
                local value = getControlValue(entry.Flag)
                local display = displayValue(value)
                for _, option in ipairs(normalizeOptions(getOptions(entry.Flag))) do
                    if tostring(option.Value) == tostring(value) then
                        display = option.Label
                        break
                    end
                end
                selector.Text = display .. "   ›"
            end
            scopedConnect(pageConnections, selector.Activated, function()
                local options = normalizeOptions(getOptions(entry.Flag))
                if #options == 0 then return end
                local current = getControlValue(entry.Flag)
                local selectedIndex = 0
                for index, option in ipairs(options) do
                    if tostring(option.Value) == tostring(current) then selectedIndex = index break end
                end
                local nextOption = options[selectedIndex % #options + 1]
                playSound("ButtonClick")
                setControlValue(entry.Flag, nextOption.Value)
                render()
            end)
            table.insert(currentRenderers, render)
            render()
        elseif entry.Kind == "Input" then
            label.Visible = false
            local inputBox = Instance.new("TextBox")
            inputBox.BackgroundColor3 = theme.Layer
            inputBox.BackgroundTransparency = 0.08
            inputBox.BorderSizePixel = 0
            inputBox.ClearTextOnFocus = false
            inputBox.FontFace = fonts.Body
            inputBox.PlaceholderColor3 = theme.Signal
            inputBox.PlaceholderText = tostring(entry.Label or "Değer")
            inputBox.Position = UDim2.fromOffset(8, 6)
            inputBox.Size = UDim2.new(1, -16, 1, -12)
            inputBox.TextColor3 = theme.Signal
            inputBox.TextSize = 14
            inputBox.TextXAlignment = Enum.TextXAlignment.Left
            inputBox.ZIndex = 4012
            inputBox.Parent = row
            round(inputBox, 8)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 10)
            padding.PaddingRight = UDim.new(0, 10)
            padding.Parent = inputBox
            local function render()
                applyVisibility()
                if not inputBox:IsFocused() then inputBox.Text = displayValue(getControlValue(entry.Flag)) end
            end
            scopedConnect(pageConnections, inputBox.FocusLost, function()
                setControlValue(entry.Flag, inputBox.Text)
                render()
            end)
            table.insert(currentRenderers, render)
            render()
        elseif entry.Kind == "Action" then
            label.Visible = false
            local action = Instance.new("TextButton")
            action.AutoButtonColor = false
            action.BackgroundColor3 = theme.Signal
            action.BackgroundTransparency = 0
            action.BorderSizePixel = 0
            action.FontFace = fonts.HeadingHeavy
            action.Position = UDim2.fromOffset(8, 6)
            action.Size = UDim2.new(1, -16, 1, -12)
            action.Text = tostring(entry.Label or "Çalıştır")
            action.TextColor3 = theme.Base
            action.TextSize = 14
            action.ZIndex = 4012
            action.Parent = row
            round(action, 8)
            scopedConnect(pageConnections, action.MouseEnter, function()
                animate(action, {BackgroundTransparency = 0.12}, motion.Control, Enum.EasingStyle.Quint)
            end)
            scopedConnect(pageConnections, action.MouseLeave, function()
                animate(action, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
            end)
            scopedConnect(pageConnections, action.Activated, function()
                playSound("ButtonClick")
                pcall(context.ActivateControl, entry.Flag)
            end)
            local function render() applyVisibility() end
            table.insert(currentRenderers, render)
            render()
        else
            row:Destroy()
            return nil
        end
        currentRows[entry.Flag] = row
        return row
    end

    local function createSection(parent, name, entries)
        local section = Instance.new("Frame")
        section.Name = tostring(name):gsub("[^%w_]", "_")
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.BackgroundColor3 = theme.Layer
        section.BackgroundTransparency = 0.06
        section.BorderSizePixel = 0
        section.Size = UDim2.new(1, -6, 0, 0)
        section.ZIndex = 4008
        section.Parent = parent
        round(section, 14)
        outline(section, 2, 0.16)
        local sectionLayout = Instance.new("UIListLayout")
        sectionLayout.Padding = UDim.new(0, 7)
        sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sectionLayout.Parent = section
        local sectionPadding = Instance.new("UIPadding")
        sectionPadding.PaddingLeft = UDim.new(0, 10)
        sectionPadding.PaddingRight = UDim.new(0, 10)
        sectionPadding.PaddingTop = UDim.new(0, 8)
        sectionPadding.PaddingBottom = UDim.new(0, 10)
        sectionPadding.Parent = section
        local heading = Instance.new("TextLabel")
        heading.BackgroundTransparency = 1
        heading.FontFace = fonts.HeadingBlack
        heading.LayoutOrder = 0
        heading.Size = UDim2.new(1, 0, 0, 32)
        heading.Text = tostring(name)
        heading.TextColor3 = theme.Signal
        heading.TextSize = 18
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.ZIndex = 4009
        heading.Parent = section
        for index, entry in ipairs(entries) do
            local row = makeControlRow(section, entry)
            if row then row.LayoutOrder = index end
        end
        return section
    end

    local function createPage(category)
        currentRenderers, currentRows = {}, {}
        local page = Instance.new("CanvasGroup")
        page.Name = category .. "Page"
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.GroupTransparency = 1
        page.Position = UDim2.fromOffset(0, -24)
        page.Size = UDim2.fromScale(1, 1)
        page.ZIndex = 4006
        page.Parent = contentHost

        local scroll = Instance.new("ScrollingFrame")
        scroll.Active = true
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.CanvasSize = UDim2.new()
        scroll.ScrollBarImageColor3 = theme.Signal
        scroll.ScrollBarImageTransparency = 0.4
        scroll.ScrollBarThickness = 4
        scroll.Size = UDim2.fromScale(1, 1)
        scroll.ZIndex = 4007
        scroll.Parent = page
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, layout.SectionGap)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = scroll
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 3)
        padding.PaddingRight = UDim.new(0, 9)
        padding.PaddingTop = UDim.new(0, 3)
        padding.PaddingBottom = UDim.new(0, 12)
        padding.Parent = scroll

        local pageHeading = Instance.new("TextLabel")
        pageHeading.BackgroundTransparency = 1
        pageHeading.FontFace = fonts.HeadingBlack
        pageHeading.LayoutOrder = 0
        pageHeading.Size = UDim2.new(1, -6, 0, 44)
        pageHeading.Text = CATEGORY_BY_ID[category] and CATEGORY_BY_ID[category].Label or category
        pageHeading.TextColor3 = theme.Signal
        pageHeading.TextSize = 26
        pageHeading.TextXAlignment = Enum.TextXAlignment.Left
        pageHeading.ZIndex = 4008
        pageHeading.Parent = scroll

        if category == "Home" then
            local total = #indexEntries
            local summary = Instance.new("Frame")
            summary.AutomaticSize = Enum.AutomaticSize.Y
            summary.BackgroundColor3 = theme.Base
            summary.BackgroundTransparency = 0.12
            summary.BorderSizePixel = 0
            summary.LayoutOrder = 1
            summary.Size = UDim2.new(1, -6, 0, 0)
            summary.ZIndex = 4008
            summary.Parent = scroll
            round(summary, 14)
            outline(summary, 2, 0.12)
            local summaryPadding = Instance.new("UIPadding")
            summaryPadding.PaddingLeft = UDim.new(0, 16)
            summaryPadding.PaddingRight = UDim.new(0, 16)
            summaryPadding.PaddingTop = UDim.new(0, 14)
            summaryPadding.PaddingBottom = UDim.new(0, 14)
            summaryPadding.Parent = summary
            local summaryLayout = Instance.new("UIListLayout")
            summaryLayout.Padding = UDim.new(0, 5)
            summaryLayout.Parent = summary
            local brand = Instance.new("TextLabel")
            brand.BackgroundTransparency = 1
            brand.FontFace = fonts.HeadingBlack
            brand.Size = UDim2.new(1, 0, 0, 32)
            brand.Text = "TasuHub"
            brand.TextColor3 = theme.Signal
            brand.TextSize = 25
            brand.TextXAlignment = Enum.TextXAlignment.Left
            brand.ZIndex = 4009
            brand.Parent = summary
            local description = Instance.new("TextLabel")
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.FontFace = fonts.Body
            description.Size = UDim2.new(1, 0, 0, 0)
            description.Text = string.format("%d indekslenmiş kontrol · %d kategori\nSoldaki sekmeler veya üstteki arama ile tüm özelliklere ulaşabilirsin.", total, #CATEGORY_META)
            description.TextColor3 = theme.Signal
            description.TextSize = 14
            description.TextTransparency = 0.22
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.ZIndex = 4009
            description.Parent = summary
        end

        local grouped, sectionNames = {}, {}
        for _, entry in ipairs(entriesByCategory[category] or {}) do
            local sectionName = tostring(entry.Section or "Genel")
            if not grouped[sectionName] then
                grouped[sectionName] = {}
                table.insert(sectionNames, sectionName)
            end
            table.insert(grouped[sectionName], entry)
        end
        table.sort(sectionNames)
        for index, sectionName in ipairs(sectionNames) do
            local section = createSection(scroll, sectionName, grouped[sectionName])
            section.LayoutOrder = index + 2
        end

        if #sectionNames == 0 and category ~= "Home" then
            local empty = Instance.new("TextLabel")
            empty.BackgroundTransparency = 1
            empty.FontFace = fonts.HeadingHeavy
            empty.LayoutOrder = 2
            empty.Size = UDim2.new(1, -6, 0, 80)
            empty.Text = "Bu kategori bir sonraki özellik geçişinde doldurulacak."
            empty.TextColor3 = theme.Signal
            empty.TextSize = 16
            empty.TextTransparency = 0.3
            empty.TextWrapped = true
            empty.ZIndex = 4008
            empty.Parent = scroll
        end
        return page, scroll
    end

    local function refreshNavigation()
        for id, record in pairs(navButtons) do
            local selected = id == currentCategory
            animate(record.Button, {
                BackgroundColor3 = selected and theme.Signal or theme.Base,
                BackgroundTransparency = selected and 0 or 0.22
            }, motion.Control, Enum.EasingStyle.Quint)
            animate(record.Glyph, {
                BackgroundColor3 = selected and theme.Base or theme.Base,
                TextColor3 = selected and theme.Signal or theme.Signal
            }, motion.Control, Enum.EasingStyle.Quint)
            animate(record.Label, {TextColor3 = selected and theme.Base or theme.Signal}, motion.Control, Enum.EasingStyle.Quint)
            animate(record.Stroke, {Transparency = selected and 0.04 or 1}, motion.Control, Enum.EasingStyle.Quint)
        end
    end

    local function focusRow(flag, scroll)
        task.defer(function()
            if destroyed or not scroll or not scroll.Parent then return end
            local row = currentRows[flag]
            if not row or not row.Parent then return end
            scroll.CanvasPosition = Vector2.new(0, math.max(0, row.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y - 18))
            local original = row.BackgroundTransparency
            row.BackgroundTransparency = 0.02
            animate(row, {BackgroundTransparency = original}, 0.8, Enum.EasingStyle.Quint)
        end)
    end

    local function selectCategory(category, focusFlag, instant)
        if not CATEGORY_BY_ID[category] then return false end
        pageRevision = pageRevision + 1
        local revision, previous = pageRevision, currentPage
        currentCategory = category
        clearScopedConnections(pageConnections)
        local nextPage, nextScroll = createPage(category)
        currentPage = nextPage
        refreshNavigation()
        if instant then
            if previous and previous.Parent then previous:Destroy() end
            nextPage.Position = UDim2.fromOffset(0, 0)
            nextPage.GroupTransparency = 0
            if focusFlag then focusRow(focusFlag, nextScroll) end
            return true
        end
        if previous and previous.Parent then
            animate(previous, {Position = UDim2.fromOffset(0, -28), GroupTransparency = 1}, motion.PageOut, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        end
        nextPage.Position = UDim2.fromOffset(0, -28)
        nextPage.GroupTransparency = 1
        animate(nextPage, {Position = UDim2.fromOffset(0, 0), GroupTransparency = 0}, motion.PageIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        task.delay(motion.PageOut, function()
            if previous and previous ~= currentPage and previous.Parent then previous:Destroy() end
        end)
        if focusFlag then
            task.delay(motion.PageIn, function()
                if not destroyed and revision == pageRevision then focusRow(focusFlag, nextScroll) end
            end)
        end
        return true
    end

    for id, record in pairs(navButtons) do
        connect(record.Button.MouseEnter, function()
            if id ~= currentCategory then
                playSound("ButtonHover")
                animate(record.Button, {BackgroundTransparency = 0.08}, motion.Control, Enum.EasingStyle.Quint)
            end
        end)
        connect(record.Button.MouseLeave, function()
            if id ~= currentCategory then
                animate(record.Button, {BackgroundTransparency = 0.22}, motion.Control, Enum.EasingStyle.Quint)
            end
        end)
        connect(record.Button.Activated, function()
            if state ~= "Open" or id == currentCategory then return end
            playSound("ButtonClick")
            selectCategory(id, nil, false)
        end)
    end

    local function contentGeometry(expanded)
        local sidebarWidth = expanded and layout.SidebarExpandedWidth or layout.SidebarCollapsedWidth
        return sidebarWidth,
            UDim2.fromOffset(sidebarWidth + layout.ContentPadding, layout.ContentPadding),
            UDim2.new(1, -(sidebarWidth + layout.ContentPadding * 2), 1, -layout.ContentPadding * 2)
    end

    local function setSidebarExpanded(expanded, instant)
        expanded = expanded == true
        if sidebarExpanded == expanded and not instant then return end
        sidebarExpanded = expanded
        local sidebarWidth, contentPosition, contentSize = contentGeometry(expanded)
        local duration = instant and 0 or motion.Sidebar
        if instant then
            sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
            contentHost.Position = contentPosition
            contentHost.Size = contentSize
        else
            animate(sidebar, {Size = UDim2.new(0, sidebarWidth, 1, 0)}, duration, Enum.EasingStyle.Quint)
            animate(contentHost, {Position = contentPosition, Size = contentSize}, duration, Enum.EasingStyle.Quint)
        end
        for _, record in pairs(navButtons) do
            local targetSize = expanded and UDim2.new(1, -20, 0, layout.NavigationHeight) or UDim2.fromOffset(48, layout.NavigationHeight)
            local glyphPosition = expanded and UDim2.fromOffset(27, layout.NavigationHeight * 0.5) or UDim2.fromOffset(24, layout.NavigationHeight * 0.5)
            if instant then
                record.Button.Size = targetSize
                record.Glyph.Position = glyphPosition
                record.Label.TextTransparency = expanded and 0 or 1
            else
                animate(record.Button, {Size = targetSize}, duration, Enum.EasingStyle.Quint)
                animate(record.Glyph, {Position = glyphPosition}, duration, Enum.EasingStyle.Quint)
                animate(record.Label, {TextTransparency = expanded and 0 or 1}, duration * 0.72, Enum.EasingStyle.Quint)
            end
        end
    end

    connect(hamburger.Activated, function()
        if state ~= "Open" then return end
        playSound("ButtonClick")
        setSidebarExpanded(not sidebarExpanded, false)
    end)

    local function setSearchOpen(open, instant)
        open = open == true
        if searchOpen == open and not instant then return end
        searchOpen, searchShellRevision = open, searchShellRevision + 1
        local revision = searchShellRevision
        if open then searchShell.Visible = true end
        local width = open and layout.SearchWidth or 0
        local duration = open and motion.SearchOpen or motion.SearchClose
        if instant then
            searchShell.Size = UDim2.fromOffset(width, 36)
            searchBox.TextTransparency = open and 0 or 1
            searchShell.Visible = open
            return
        end
        local tween = animate(searchShell, {Size = UDim2.fromOffset(width, 36)}, duration, Enum.EasingStyle.Quint, open and Enum.EasingDirection.Out or Enum.EasingDirection.In)
        animate(searchBox, {TextTransparency = open and 0 or 1}, duration, Enum.EasingStyle.Quint)
        if not open then
            task.spawn(function()
                tween.Completed:Wait()
                if not destroyed and revision == searchShellRevision and not searchOpen then searchShell.Visible = false end
            end)
        end
    end

    local function clearSearchResults()
        clearScopedConnections(searchConnections)
        for _, child in ipairs(searchList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
    end

    local function hideSearchResults()
        searchResultsRevision = searchResultsRevision + 1
        local revision = searchResultsRevision
        animate(searchResults, {Size = UDim2.fromOffset(390, 0), GroupTransparency = 1}, motion.SearchClose, Enum.EasingStyle.Quint)
        task.delay(motion.SearchClose, function()
            if revision == searchResultsRevision and searchBox.Text:gsub("%s", "") == "" then searchResults.Visible = false end
        end)
    end

    local function rebuildSearch()
        clearSearchResults()
        local query = normalizedText(searchBox.Text:gsub("^%s+", ""):gsub("%s+$", ""))
        if query == "" then
            searchCount.Text = "0"
            hideSearchResults()
            return
        end
        local matches = {}
        for _, meta in ipairs(CATEGORY_META) do
            if string.find(normalizedText(meta.Id .. " " .. meta.Label), query, 1, true) then
                table.insert(matches, {Category = meta.Id, Label = meta.Label, Section = "Kategori", Priority = 1})
            end
        end
        for _, entry in ipairs(indexEntries) do
            local searchable = normalizedText(entry.Category .. " " .. entry.Section .. " " .. entry.Label .. " " .. entry.Kind)
            if string.find(searchable, query, 1, true) then
                table.insert(matches, {
                    Category = entry.Category,
                    Label = entry.Label,
                    Section = entry.Section,
                    Flag = entry.Flag,
                    Priority = 2
                })
            end
        end
        table.sort(matches, function(first, second)
            if first.Priority ~= second.Priority then return first.Priority < second.Priority end
            if first.Category ~= second.Category then return (CATEGORY_ORDER[first.Category] or 99) < (CATEGORY_ORDER[second.Category] or 99) end
            return tostring(first.Label) < tostring(second.Label)
        end)
        searchCount.Text = tostring(#matches)
        local visible = math.min(7, #matches)
        if visible == 0 then
            searchResults.Visible = false
            return
        end
        for index = 1, #matches do
            local match = matches[index]
            local button = Instance.new("TextButton")
            button.AutoButtonColor = false
            button.BackgroundColor3 = theme.Layer
            button.BackgroundTransparency = 0.16
            button.BorderSizePixel = 0
            button.FontFace = fonts.Body
            button.LayoutOrder = index
            button.Size = UDim2.new(1, -2, 0, 50)
            button.Text = tostring(match.Label) .. "\n" .. tostring(CATEGORY_BY_ID[match.Category] and CATEGORY_BY_ID[match.Category].Label or match.Category) .. "  ›  " .. tostring(match.Section)
            button.TextColor3 = theme.Signal
            button.TextSize = 13
            button.TextWrapped = true
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.ZIndex = 4032
            button.Parent = searchList
            round(button, 9)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 11)
            padding.PaddingRight = UDim.new(0, 11)
            padding.Parent = button
            scopedConnect(searchConnections, button.MouseEnter, function()
                animate(button, {BackgroundTransparency = 0.04}, motion.Control, Enum.EasingStyle.Quint)
            end)
            scopedConnect(searchConnections, button.MouseLeave, function()
                animate(button, {BackgroundTransparency = 0.16}, motion.Control, Enum.EasingStyle.Quint)
            end)
            scopedConnect(searchConnections, button.Activated, function()
                playSound("ButtonClick")
                searchResults.Visible = false
                selectCategory(match.Category, match.Flag, false)
                clearSearchResults()
            end)
        end
        searchResultsRevision = searchResultsRevision + 1
        searchResults.Visible = true
        searchResults.GroupTransparency = 1
        searchResults.Size = UDim2.fromOffset(390, 0)
        local targetHeight = visible * 50 + math.max(0, visible - 1) * 5 + 14
        animate(searchResults, {Size = UDim2.fromOffset(390, targetHeight), GroupTransparency = 0}, motion.SearchOpen, Enum.EasingStyle.Quint)
    end

    connect(searchButton.MouseEnter, function()
        searchPointerInside = true
        setSearchOpen(true, false)
    end)
    connect(searchButton.MouseLeave, function()
        searchPointerInside = false
        task.delay(0.08, function()
            if not searchPointerInside and not searchBox:IsFocused() and searchBox.Text:gsub("%s", "") == "" then setSearchOpen(false, false) end
        end)
    end)
    connect(searchShell.MouseEnter, function() searchPointerInside = true end)
    connect(searchShell.MouseLeave, function()
        searchPointerInside = false
        task.delay(0.08, function()
            if not searchPointerInside and not searchBox:IsFocused() and searchBox.Text:gsub("%s", "") == "" then setSearchOpen(false, false) end
        end)
    end)
    connect(searchBox:GetPropertyChangedSignal("Text"), rebuildSearch)
    connect(searchBox.FocusLost, function()
        if not searchPointerInside and searchBox.Text:gsub("%s", "") == "" then setSearchOpen(false, false) end
    end)

    local function beginDrag(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 or state ~= "Open" then return end
        dragging = true
        dragStart = input.Position
        dragWindowStart = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
    end
    connect(headerDrag.InputBegan, beginDrag)
    connect(inputService.InputChanged, function(input)
        if activeSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            if activeSlider.Row and activeSlider.Row.Parent then activeSlider.Update(input) else activeSlider = nil end
        end
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local viewport = context.GetViewportSize()
        local delta = input.Position - dragStart
        restingPosition = clampCenter(dragWindowStart + Vector2.new(delta.X, delta.Y), windowPixelSize, viewport)
        window.Position = UDim2.fromOffset(restingPosition.X, restingPosition.Y)
    end)
    connect(inputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            activeSlider = nil
        end
    end)

    local function setWindowToTarget()
        local _, size, center = targetGeometry()
        window.Size = UDim2.fromOffset(size.X, size.Y)
        window.Position = UDim2.fromOffset(center.X, center.Y)
    end

    local close = function() return false end
    local function open()
        if destroyed or state == "Open" or state == "Opening" then return false end
        transitionRevision, state = transitionRevision + 1, "Opening"
        local revision = transitionRevision
        local _, size, center = targetGeometry()
        local source = context.GetAnchorPoint()
        window.Size = UDim2.fromOffset(size.X, size.Y)
        window.Position = UDim2.fromOffset(source.X, source.Y)
        window.GroupTransparency = 1
        windowScale.Scale = 0
        window.Visible = true
        if not currentPage or not currentPage.Parent then selectCategory(currentCategory, nil, true) end
        local move = animate(window, {Position = UDim2.fromOffset(center.X, center.Y), GroupTransparency = 0}, motion.Open, Enum.EasingStyle.Quint)
        animate(windowScale, {Scale = 1}, motion.Open, Enum.EasingStyle.Back)
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
        dragging, activeSlider = false, nil
        searchBox:ReleaseFocus()
        searchBox.Text = ""
        searchResults.Visible = false
        setSearchOpen(false, true)
        local move = animate(window, {Position = UDim2.fromOffset(source.X, source.Y), GroupTransparency = 1}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        animate(windowScale, {Scale = 0}, motion.Close, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.spawn(function()
            move.Completed:Wait()
            if not destroyed and revision == transitionRevision then
                window.Visible, state = false, "Closed"
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

    setSidebarExpanded(true, true)
    selectCategory("Home", nil, true)

    local controller = {}
    controller.Open, controller.Close, controller.Toggle = open, close, toggle
    controller.IsOpen = function() return state == "Open" or state == "Opening" end
    controller.SelectCategory = function(category)
        if not CATEGORY_BY_ID[category] then return false end
        if state == "Closed" or state == "Closing" then open() end
        return selectCategory(category, nil, false)
    end
    controller.Refresh = function()
        for _, render in ipairs(currentRenderers) do pcall(render) end
    end
    controller.Destroy = function()
        if destroyed then return end
        destroyed, transitionRevision, pageRevision, searchShellRevision, searchResultsRevision = true, transitionRevision + 1, pageRevision + 1, searchShellRevision + 1, searchResultsRevision + 1
        activeSlider = nil
        clearScopedConnections(pageConnections)
        clearScopedConnections(searchConnections)
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        root:Destroy()
    end
    return table.freeze(controller)
end

return table.freeze(MainMenuModule)
