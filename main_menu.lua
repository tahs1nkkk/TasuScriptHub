local MainMenuModule = {Version = 2}

local CATEGORY_META = table.freeze({
    table.freeze({Id = "Home", Label = "Home", Glyph = "⌂"}),
    table.freeze({Id = "Players", Label = "Players", Glyph = "●●"}),
    table.freeze({Id = "Visuals", Label = "Visuals", Glyph = "◉"}),
    table.freeze({Id = "Aim", Label = "Aim", Glyph = "⊕"}),
    table.freeze({Id = "Movement", Label = "Movement", Glyph = "➤"}),
    table.freeze({Id = "World", Label = "World", Glyph = "◇"}),
    table.freeze({Id = "Lighting", Label = "Lighting", Glyph = "☼"}),
    table.freeze({Id = "Misc", Label = "Misc", Glyph = "✦"}),
    table.freeze({Id = "Configs", Label = "Configs", Glyph = "⚙"})
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
    local pageConnections, searchConnections, dropdownConnections = {}, {}, {}
    local destroyed, dragging = false, false
    local state, transitionRevision = "Closed", 0
    local pageRevision, searchShellRevision, searchResultsRevision = 0, 0, 0
    local currentCategory, currentPage = "Home", nil
    local currentRenderers, currentRows = {}, {}
    local restingPosition, dragStart, dragWindowStart = nil, nil, nil
    local windowPixelSize = Vector2.new(layout.WindowWidth, layout.WindowHeight)
    local responsiveScaleValue = 1
    local sidebarExpanded = true
    local searchOpen, searchPointerInside = false, false
    local activeSlider = nil
    local sectionCollapsed, sectionRecords, categoryIconRecords = {}, {}, {}
    local activeDropdown, playerSubscription, statsSubscription = nil, nil, nil

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
        if type(value) == "boolean" then return value and "On" or "Off" end
        if type(value) == "table" then
            local values = {}
            for _, item in ipairs(value) do table.insert(values, tostring(item)) end
            return #values > 0 and table.concat(values, ", ") or "None"
        end
        if typeof(value) == "Color3" then
            return string.format("#%02X%02X%02X", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
        end
        return tostring(value == nil and "None" or value)
    end

    local function windowSize()
        local viewport = context.GetViewportSize()
        local scale = math.min(1,
            math.max(0.1, (viewport.X - layout.ViewportInset * 2) / layout.WindowWidth),
            math.max(0.1, (viewport.Y - layout.ViewportInset * 2) / layout.WindowHeight)
        )
        return viewport, Vector2.new(layout.WindowWidth, layout.WindowHeight), scale
    end

    local function visibleRatio(point, size, viewport)
        local left, right = point.X - size.X * 0.5, point.X + size.X * 0.5
        local top, bottom = point.Y - size.Y * 0.5, point.Y + size.Y * 0.5
        local visibleWidth = math.max(0, math.min(right, viewport.X) - math.max(left, 0))
        local visibleHeight = math.max(0, math.min(bottom, viewport.Y) - math.max(top, 0))
        return (visibleWidth * visibleHeight) / math.max(1, size.X * size.Y)
    end

    local function targetGeometry()
        local viewport, size, scale = windowSize()
        responsiveScaleValue = scale
        windowPixelSize = size * scale
        local center = restingPosition or viewport * 0.5
        if visibleRatio(center, windowPixelSize, viewport) < 0.5 then center = viewport * 0.5 end
        restingPosition = center
        return viewport, size, center, scale
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
    searchBox.PlaceholderText = "Search..."
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

    hamburger.Parent = sidebar
    hamburger.Position = UDim2.fromOffset(16, 10)
    hamburger.ZIndex = 4010
    for _, child in ipairs(hamburger:GetChildren()) do
        if child:IsA("GuiObject") then child.ZIndex = 4011 end
    end

    local navScroll = Instance.new("ScrollingFrame")
    navScroll.Name = "Categories"
    navScroll.Active = true
    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navScroll.BackgroundTransparency = 1
    navScroll.BorderSizePixel = 0
    navScroll.CanvasSize = UDim2.new()
    navScroll.Position = UDim2.fromOffset(0, 62)
    navScroll.ScrollBarImageColor3 = theme.Signal
    navScroll.ScrollBarImageTransparency = 0.55
    navScroll.ScrollBarThickness = 2
    navScroll.Size = UDim2.new(1, 0, 1, -72)
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

    local dropdownDismiss = Instance.new("TextButton")
    dropdownDismiss.Name = "DropdownDismiss"
    dropdownDismiss.AutoButtonColor = false
    dropdownDismiss.BackgroundTransparency = 1
    dropdownDismiss.BorderSizePixel = 0
    dropdownDismiss.Size = UDim2.fromScale(1, 1)
    dropdownDismiss.Text = ""
    dropdownDismiss.Visible = false
    dropdownDismiss.ZIndex = 4040
    dropdownDismiss.Parent = body

    local dropdownPanel = Instance.new("CanvasGroup")
    dropdownPanel.Name = "DropdownList"
    dropdownPanel.BackgroundColor3 = theme.Base
    dropdownPanel.BackgroundTransparency = 0.03
    dropdownPanel.BorderSizePixel = 0
    dropdownPanel.ClipsDescendants = true
    dropdownPanel.GroupTransparency = 1
    dropdownPanel.Size = UDim2.fromOffset(220, 0)
    dropdownPanel.Visible = false
    dropdownPanel.ZIndex = 4041
    dropdownPanel.Parent = body
    round(dropdownPanel, 10)
    outline(dropdownPanel, 2, 0.08)

    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropdownList.BackgroundTransparency = 1
    dropdownList.BorderSizePixel = 0
    dropdownList.CanvasSize = UDim2.new()
    dropdownList.ScrollBarImageColor3 = theme.Signal
    dropdownList.ScrollBarImageTransparency = 0.42
    dropdownList.ScrollBarThickness = 3
    dropdownList.Size = UDim2.fromScale(1, 1)
    dropdownList.ZIndex = 4042
    dropdownList.Parent = dropdownPanel
    local dropdownLayout = Instance.new("UIListLayout")
    dropdownLayout.Padding = UDim.new(0, 4)
    dropdownLayout.Parent = dropdownList
    local dropdownPadding = Instance.new("UIPadding")
    dropdownPadding.PaddingLeft = UDim.new(0, 6)
    dropdownPadding.PaddingRight = UDim.new(0, 8)
    dropdownPadding.PaddingTop = UDim.new(0, 6)
    dropdownPadding.PaddingBottom = UDim.new(0, 6)
    dropdownPadding.Parent = dropdownList

    local function closeDropdown(instant)
        activeDropdown = nil
        clearScopedConnections(dropdownConnections)
        dropdownDismiss.Visible = false
        if instant then
            dropdownPanel.Visible = false
            dropdownPanel.GroupTransparency = 1
            dropdownPanel.Size = UDim2.new(0, dropdownPanel.Size.X.Offset, 0, 0)
        else
            local width = dropdownPanel.Size.X.Offset
            animate(dropdownPanel, {Size = UDim2.fromOffset(width, 0), GroupTransparency = 1}, motion.Control, Enum.EasingStyle.Quint)
            task.delay(motion.Control, function()
                if not destroyed and not activeDropdown then dropdownPanel.Visible = false end
            end)
        end
    end

    connect(dropdownDismiss.Activated, function() closeDropdown(false) end)

    local function openDropdown(anchor, options, current, selectCallback)
        closeDropdown(true)
        if #options == 0 or not anchor or not anchor.Parent then return end
        activeDropdown = anchor
        for _, child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local scale = math.max(0.1, responsiveScaleValue)
        local relative = (anchor.AbsolutePosition - body.AbsolutePosition) / scale
        local width = math.max(180, anchor.AbsoluteSize.X / scale)
        local height = math.min(238, #options * 38 + math.max(0, #options - 1) * 4 + 12)
        local x = math.clamp(relative.X, 8, layout.WindowWidth - width - 8)
        local preferredY = relative.Y + anchor.AbsoluteSize.Y / scale + 6
        local y = preferredY + height <= layout.WindowHeight - layout.HeaderHeight - 8 and preferredY or math.max(8, relative.Y - height - 6)
        dropdownPanel.Position = UDim2.fromOffset(x, y)
        dropdownPanel.Size = UDim2.fromOffset(width, 0)
        dropdownPanel.GroupTransparency = 1
        dropdownPanel.Visible = true
        dropdownDismiss.Visible = true
        for index, option in ipairs(options) do
            local button = Instance.new("TextButton")
            button.AutoButtonColor = false
            button.BackgroundColor3 = tostring(option.Value) == tostring(current) and theme.Signal or theme.Layer
            button.BackgroundTransparency = tostring(option.Value) == tostring(current) and 0 or 0.12
            button.BorderSizePixel = 0
            button.FontFace = fonts.HeadingHeavy
            button.LayoutOrder = index
            button.Size = UDim2.new(1, -2, 0, 38)
            button.Text = option.Label
            button.TextColor3 = tostring(option.Value) == tostring(current) and theme.Base or theme.Signal
            button.TextSize = 13
            button.ZIndex = 4043
            button.Parent = dropdownList
            round(button, 8)
            scopedConnect(dropdownConnections, button.Activated, function()
                playSound("ButtonClick")
                selectCallback(option.Value)
                closeDropdown(false)
            end)
        end
        animate(dropdownPanel, {Size = UDim2.fromOffset(width, height), GroupTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
    end

    local indexEntries = copyArray(context.GetIndexEntries())
    table.sort(indexEntries, function(first, second)
        local leftOrder = CATEGORY_ORDER[first.Category] or 99
        local rightOrder = CATEGORY_ORDER[second.Category] or 99
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        if tostring(first.Section) ~= tostring(second.Section) then return tostring(first.Section) < tostring(second.Section) end
        return tostring(first.Label) < tostring(second.Label)
    end)

    local entriesByCategory, entryByFlag = {}, {}
    for _, entry in ipairs(indexEntries) do
        if CATEGORY_BY_ID[entry.Category] then
            entriesByCategory[entry.Category] = entriesByCategory[entry.Category] or {}
            table.insert(entriesByCategory[entry.Category], entry)
            entryByFlag[entry.Flag] = entry
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
        local image = Instance.new("ImageLabel")
        image.Name = "CategoryImage"
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.Position = UDim2.fromOffset(4, 4)
        image.Size = UDim2.new(1, -8, 1, -8)
        image.ScaleType = Enum.ScaleType.Fit
        image.Visible = false
        image.ZIndex = 4008
        image.Parent = glyph
        local iconOk, iconValue = false, ""
        if type(context.GetCategoryIcon) == "function" then iconOk, iconValue = pcall(context.GetCategoryIcon, meta.Id) end
        local resolved = iconOk and iconValue or ""
        if type(resolved) == "string" and resolved ~= "" then
            image.Image = resolved
            image.Visible = true
            glyph.TextTransparency = 1
            task.delay(3, function()
                if not destroyed and image.Parent and image.Image == resolved and not image.IsLoaded then
                    image.Visible = false
                    glyph.TextTransparency = 0
                end
            end)
        end
        categoryIconRecords[meta.Id] = {Glyph = glyph, Image = image}
        return glyph, image
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
        local glyph, image = createGlyph(button, meta)
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
        navButtons[meta.Id] = {Button = button, Glyph = glyph, Image = image, Label = label, Stroke = stroke}
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

    local statsOverlay = Instance.new("CanvasGroup")
    statsOverlay.Name = "StatsOverlay"
    statsOverlay.BackgroundColor3 = theme.Layer
    statsOverlay.BackgroundTransparency = 0.06
    statsOverlay.BorderSizePixel = 0
    statsOverlay.GroupTransparency = 1
    statsOverlay.Position = UDim2.fromOffset(24, 104)
    statsOverlay.Size = UDim2.fromOffset(224, 128)
    statsOverlay.Visible = false
    statsOverlay.ZIndex = 4060
    statsOverlay.Parent = root
    round(statsOverlay, 14)
    outline(statsOverlay, 2, 0.1)
    local statsHeader = Instance.new("Frame")
    statsHeader.Active = true
    statsHeader.BackgroundColor3 = theme.Base
    statsHeader.BorderSizePixel = 0
    statsHeader.Size = UDim2.new(1, 0, 0, 38)
    statsHeader.ZIndex = 4061
    statsHeader.Parent = statsOverlay
    round(statsHeader, 14)
    local statsHeaderMask = Instance.new("Frame")
    statsHeaderMask.BackgroundColor3 = theme.Base
    statsHeaderMask.BorderSizePixel = 0
    statsHeaderMask.Position = UDim2.new(0, 0, 1, -14)
    statsHeaderMask.Size = UDim2.new(1, 0, 0, 14)
    statsHeaderMask.ZIndex = 4061
    statsHeaderMask.Parent = statsHeader
    local statsTitle = Instance.new("TextLabel")
    statsTitle.BackgroundTransparency = 1
    statsTitle.FontFace = fonts.HeadingBlack
    statsTitle.Position = UDim2.fromOffset(12, 0)
    statsTitle.Size = UDim2.new(1, -50, 1, 0)
    statsTitle.Text = "Live Stats"
    statsTitle.TextColor3 = theme.Signal
    statsTitle.TextSize = 16
    statsTitle.TextXAlignment = Enum.TextXAlignment.Left
    statsTitle.ZIndex = 4062
    statsTitle.Parent = statsHeader
    local statsClose = Instance.new("TextButton")
    statsClose.AnchorPoint = Vector2.new(1, 0.5)
    statsClose.AutoButtonColor = false
    statsClose.BackgroundTransparency = 1
    statsClose.BorderSizePixel = 0
    statsClose.FontFace = fonts.HeadingBlack
    statsClose.Position = UDim2.new(1, -6, 0.5, 0)
    statsClose.Size = UDim2.fromOffset(32, 32)
    statsClose.Text = "×"
    statsClose.TextColor3 = theme.Signal
    statsClose.TextSize = 22
    statsClose.ZIndex = 4063
    statsClose.Parent = statsHeader
    local statsBody = Instance.new("TextLabel")
    statsBody.BackgroundTransparency = 1
    statsBody.FontFace = fonts.Body
    statsBody.Position = UDim2.fromOffset(14, 46)
    statsBody.Size = UDim2.new(1, -28, 1, -54)
    statsBody.Text = ""
    statsBody.TextColor3 = theme.Signal
    statsBody.TextSize = 14
    statsBody.TextXAlignment = Enum.TextXAlignment.Left
    statsBody.TextYAlignment = Enum.TextYAlignment.Top
    statsBody.ZIndex = 4061
    statsBody.Parent = statsOverlay
    local statsLatest = type(context.GetStatsSnapshot) == "function" and context.GetStatsSnapshot() or {}
    local statsVisibleRevision = 0
    local function renderStatsOverlay(snapshot)
        if type(snapshot) == "table" then statsLatest = snapshot end
        local visible = getControlValue("Home/Stats Overlay/Show Stats") == true
        if not visible and not statsOverlay.Visible then
            statsOverlay.GroupTransparency = 1
            return
        end
        statsVisibleRevision = statsVisibleRevision + 1
        local revision = statsVisibleRevision
        if not visible then
            animate(statsOverlay, {GroupTransparency = 1}, motion.Control, Enum.EasingStyle.Quint)
            task.delay(motion.Control, function()
                if not destroyed and revision == statsVisibleRevision and getControlValue("Home/Stats Overlay/Show Stats") ~= true then statsOverlay.Visible = false end
            end)
            return
        end
        local lines = {}
        if statsLatest.ShowFPS ~= false then table.insert(lines, "FPS               " .. tostring(statsLatest.FPS or "--")) end
        if statsLatest.ShowPing ~= false then table.insert(lines, "Ping              " .. (statsLatest.Ping and string.format("%.0f ms", statsLatest.Ping) or "--")) end
        if statsLatest.ShowPlayerCount ~= false then table.insert(lines, "Players           " .. tostring(statsLatest.PlayerCount or "--")) end
        if statsLatest.ShowMemory ~= false then table.insert(lines, "Memory            " .. (statsLatest.Memory and string.format("%.0f MB", statsLatest.Memory) or "--")) end
        statsBody.Text = table.concat(lines, "\n")
        statsOverlay.Size = UDim2.fromOffset(224, 54 + math.max(1, #lines) * 18)
        statsOverlay.Visible = true
        animate(statsOverlay, {GroupTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
    end
    connect(statsClose.Activated, function()
        playSound("ButtonClick")
        setControlValue("Home/Stats Overlay/Show Stats", false)
        renderStatsOverlay()
    end)
    local statsDragging, statsDragStart, statsPositionStart = false, nil, nil
    connect(statsHeader.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        statsDragging = true
        statsDragStart = input.Position
        statsPositionStart = Vector2.new(statsOverlay.Position.X.Offset, statsOverlay.Position.Y.Offset)
    end)
    connect(inputService.InputChanged, function(input)
        if not statsDragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - statsDragStart
        statsOverlay.Position = UDim2.fromOffset(statsPositionStart.X + delta.X, statsPositionStart.Y + delta.Y)
    end)
    connect(inputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then statsDragging = false end
    end)
    if type(context.SubscribeStats) == "function" then statsSubscription = context.SubscribeStats(renderStatsOverlay) end

    local function normalizeOptions(values)
        local options = {}
        for _, option in ipairs(values) do
            if type(option) == "table" then
                table.insert(options, {Label = tostring(option.Label or option.Value or "Option"), Value = option.Value})
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
                selector.Text = display .. "   ▾"
            end
            scopedConnect(pageConnections, selector.Activated, function()
                local options = normalizeOptions(getOptions(entry.Flag))
                if #options == 0 then return end
                playSound("ButtonClick")
                openDropdown(selector, options, getControlValue(entry.Flag), function(value)
                    setControlValue(entry.Flag, value)
                    render()
                end)
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
            inputBox.PlaceholderText = tostring(entry.Label or "Value")
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
            action.Text = tostring(entry.Label or "Run")
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
        local sectionKey = tostring(entries[1] and entries[1].Category or currentCategory) .. "/" .. tostring(name)
        local section = Instance.new("Frame")
        section.Name = tostring(name):gsub("[^%w_]", "_")
        section.BackgroundColor3 = theme.Layer
        section.BackgroundTransparency = 0.06
        section.BorderSizePixel = 0
        section.Size = UDim2.new(1, 0, 0, 44)
        section.ZIndex = 4008
        section.Parent = parent
        round(section, 14)
        outline(section, 2, 0.16)
        local heading = Instance.new("TextLabel")
        heading.BackgroundTransparency = 1
        heading.FontFace = fonts.HeadingBlack
        heading.Position = UDim2.fromOffset(12, 6)
        heading.Size = UDim2.new(1, -58, 0, 32)
        heading.Text = tostring(name)
        heading.TextColor3 = theme.Signal
        heading.TextSize = 18
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.ZIndex = 4009
        heading.Parent = section

        local arrow = Instance.new("TextButton")
        arrow.AnchorPoint = Vector2.new(1, 0)
        arrow.AutoButtonColor = false
        arrow.BackgroundColor3 = theme.Base
        arrow.BackgroundTransparency = 0.18
        arrow.BorderSizePixel = 0
        arrow.FontFace = fonts.HeadingBlack
        arrow.Position = UDim2.new(1, -8, 0, 7)
        arrow.Size = UDim2.fromOffset(30, 30)
        arrow.Text = "⌃"
        arrow.TextColor3 = theme.Signal
        arrow.TextSize = 17
        arrow.ZIndex = 4011
        arrow.Parent = section
        round(arrow, 8)

        local content = Instance.new("CanvasGroup")
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ClipsDescendants = true
        content.Position = UDim2.fromOffset(10, 44)
        content.Size = UDim2.new(1, -20, 0, 0)
        content.ZIndex = 4009
        content.Parent = section
        local sectionLayout = Instance.new("UIListLayout")
        sectionLayout.Padding = UDim.new(0, 7)
        sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sectionLayout.Parent = content
        for index, entry in ipairs(entries) do
            local row = makeControlRow(content, entry)
            if row then row.LayoutOrder = index end
        end

        local function targetHeight()
            return sectionCollapsed[sectionKey] and 0 or sectionLayout.AbsoluteContentSize.Y + 10
        end
        local function renderCollapse(instant)
            local collapsed = sectionCollapsed[sectionKey] == true
            local height = targetHeight()
            if instant then
                content.Size = UDim2.new(1, -20, 0, height)
                content.GroupTransparency = collapsed and 1 or 0
                section.Size = UDim2.new(1, 0, 0, 44 + height)
                arrow.Rotation = collapsed and 180 or 0
            else
                animate(content, {Size = UDim2.new(1, -20, 0, height), GroupTransparency = collapsed and 1 or 0}, motion.Sidebar, Enum.EasingStyle.Quint)
                animate(section, {Size = UDim2.new(1, 0, 0, 44 + height)}, motion.Sidebar, Enum.EasingStyle.Quint)
                animate(arrow, {Rotation = collapsed and 180 or 0}, motion.Control, Enum.EasingStyle.Quint)
            end
        end
        scopedConnect(pageConnections, arrow.Activated, function()
            playSound("ButtonClick")
            sectionCollapsed[sectionKey] = not (sectionCollapsed[sectionKey] == true)
            renderCollapse(false)
        end)
        scopedConnect(pageConnections, sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            if not sectionCollapsed[sectionKey] then renderCollapse(false) end
        end)
        sectionRecords[sectionKey] = {Section = section, Render = renderCollapse}
        task.defer(function() if section.Parent then renderCollapse(true) end end)
        return section
    end

    local function createPlayerDirectory(parent)
        local card = Instance.new("Frame")
        card.Name = "PlayerDirectory"
        card.BackgroundColor3 = theme.Layer
        card.BackgroundTransparency = 0.06
        card.BorderSizePixel = 0
        card.LayoutOrder = 2
        card.Size = UDim2.new(1, -6, 0, 356)
        card.ZIndex = 4008
        card.Parent = parent
        round(card, 14)
        outline(card, 2, 0.16)

        local heading = Instance.new("TextLabel")
        heading.BackgroundTransparency = 1
        heading.FontFace = fonts.HeadingBlack
        heading.Position = UDim2.fromOffset(12, 8)
        heading.Size = UDim2.new(1, -24, 0, 30)
        heading.Text = "Live Players"
        heading.TextColor3 = theme.Signal
        heading.TextSize = 18
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.ZIndex = 4009
        heading.Parent = card

        local search = Instance.new("TextBox")
        search.BackgroundColor3 = theme.Base
        search.BackgroundTransparency = 0.16
        search.BorderSizePixel = 0
        search.ClearTextOnFocus = false
        search.FontFace = fonts.Body
        search.PlaceholderColor3 = theme.Signal
        search.PlaceholderText = "Search username or display name"
        search.Position = UDim2.fromOffset(12, 44)
        search.Size = UDim2.new(0.62, -18, 0, 34)
        search.Text = ""
        search.TextColor3 = theme.Signal
        search.TextSize = 13
        search.TextXAlignment = Enum.TextXAlignment.Left
        search.ZIndex = 4010
        search.Parent = card
        round(search, 8)
        local searchPadding = Instance.new("UIPadding")
        searchPadding.PaddingLeft = UDim.new(0, 10)
        searchPadding.PaddingRight = UDim.new(0, 10)
        searchPadding.Parent = search

        local playerSortOptions = {"Nearest", "Name A-Z", "Health High-Low", "Health Low-High"}
        local sortMode = type(context.GetPlayerSort) == "function" and tostring(context.GetPlayerSort() or "Nearest") or "Nearest"
        if not table.find(playerSortOptions, sortMode) then sortMode = "Nearest" end
        local sortButton = Instance.new("TextButton")
        sortButton.AnchorPoint = Vector2.new(1, 0)
        sortButton.AutoButtonColor = false
        sortButton.BackgroundColor3 = theme.Base
        sortButton.BackgroundTransparency = 0.16
        sortButton.BorderSizePixel = 0
        sortButton.FontFace = fonts.HeadingHeavy
        sortButton.Position = UDim2.new(1, -12, 0, 44)
        sortButton.Size = UDim2.new(0.38, -6, 0, 34)
        sortButton.Text = sortMode .. "   ▾"
        sortButton.TextColor3 = theme.Signal
        sortButton.TextSize = 13
        sortButton.ZIndex = 4010
        sortButton.Parent = card
        round(sortButton, 8)

        local status = Instance.new("TextLabel")
        status.BackgroundTransparency = 1
        status.FontFace = fonts.Body
        status.Position = UDim2.fromOffset(12, 82)
        status.Size = UDim2.new(1, -24, 0, 20)
        status.Text = "Ready"
        status.TextColor3 = theme.Signal
        status.TextSize = 12
        status.TextTransparency = 0.28
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.ZIndex = 4009
        status.Parent = card

        local playerList = Instance.new("ScrollingFrame")
        playerList.Active = true
        playerList.BackgroundColor3 = theme.Base
        playerList.BackgroundTransparency = 0.18
        playerList.BorderSizePixel = 0
        playerList.CanvasSize = UDim2.new()
        playerList.Position = UDim2.fromOffset(12, 104)
        playerList.ScrollBarImageColor3 = theme.Signal
        playerList.ScrollBarImageTransparency = 0.42
        playerList.ScrollBarThickness = 3
        playerList.Size = UDim2.new(1, -24, 1, -116)
        playerList.ZIndex = 4009
        playerList.Parent = card
        round(playerList, 10)

        local snapshots, rowPool = {}, {}
        local rowHeight, bufferRows = 62, 3

        local function actionButton(parentRow, text, xOffset, width)
            local button = Instance.new("TextButton")
            button.AnchorPoint = Vector2.new(1, 0.5)
            button.AutoButtonColor = false
            button.BackgroundColor3 = theme.Layer
            button.BackgroundTransparency = 0.08
            button.BorderSizePixel = 0
            button.FontFace = fonts.HeadingHeavy
            button.Position = UDim2.new(1, xOffset, 0.5, 0)
            button.Size = UDim2.fromOffset(width, 30)
            button.Text = text
            button.TextColor3 = theme.Signal
            button.TextSize = 11
            button.ZIndex = 4013
            button.Parent = parentRow
            round(button, 8)
            return button
        end

        local renderPlayers
        local function buildRow()
            local record = {}
            local row = Instance.new("Frame")
            row.BackgroundColor3 = theme.Layer
            row.BackgroundTransparency = 0.12
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -8, 0, rowHeight - 5)
            row.Visible = false
            row.ZIndex = 4010
            row.Parent = playerList
            round(row, 9)
            local avatar = Instance.new("ImageLabel")
            avatar.BackgroundColor3 = theme.Base
            avatar.BorderSizePixel = 0
            avatar.Position = UDim2.fromOffset(6, 6)
            avatar.Size = UDim2.fromOffset(44, 44)
            avatar.ZIndex = 4011
            avatar.Parent = row
            round(avatar, 12)
            local name = Instance.new("TextLabel")
            name.BackgroundTransparency = 1
            name.FontFace = fonts.HeadingHeavy
            name.Position = UDim2.fromOffset(58, 4)
            name.Size = UDim2.new(1, -286, 0, 22)
            name.TextColor3 = theme.Signal
            name.TextSize = 13
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.ZIndex = 4011
            name.Parent = row
            local details = Instance.new("TextLabel")
            details.BackgroundTransparency = 1
            details.FontFace = fonts.Body
            details.Position = UDim2.fromOffset(58, 25)
            details.Size = UDim2.new(1, -286, 0, 18)
            details.TextColor3 = theme.Signal
            details.TextSize = 11
            details.TextTransparency = 0.28
            details.TextTruncate = Enum.TextTruncate.AtEnd
            details.TextXAlignment = Enum.TextXAlignment.Left
            details.ZIndex = 4011
            details.Parent = row
            local healthTrack = Instance.new("Frame")
            healthTrack.BackgroundColor3 = theme.Base
            healthTrack.BorderSizePixel = 0
            healthTrack.Position = UDim2.fromOffset(58, 46)
            healthTrack.Size = UDim2.new(1, -286, 0, 5)
            healthTrack.ZIndex = 4011
            healthTrack.Parent = row
            round(healthTrack, 999)
            local healthFill = Instance.new("Frame")
            healthFill.BackgroundColor3 = theme.Success
            healthFill.BorderSizePixel = 0
            healthFill.Size = UDim2.fromScale(1, 1)
            healthFill.ZIndex = 4012
            healthFill.Parent = healthTrack
            round(healthFill, 999)
            local walk = actionButton(row, "Walk", -188, 50)
            local fling = actionButton(row, "Fling", -134, 50)
            local view = actionButton(row, "View", -80, 50)
            local teleport = actionButton(row, "TP", -26, 42)
            record.Row, record.Avatar, record.Name, record.Details, record.Health = row, avatar, name, details, healthFill
            record.Walk, record.Fling, record.View, record.Teleport = walk, fling, view, teleport
            local function invoke(action)
                if not record.UserId or type(context.PlayerAction) ~= "function" then return end
                playSound("ButtonClick")
                local ok, message = context.PlayerAction(action, record.UserId)
                status.Text = tostring(message or (ok and "Action started" or "Action failed"))
                status.TextColor3 = ok and theme.Success or theme.Danger
                task.defer(function() if renderPlayers then renderPlayers() end end)
            end
            scopedConnect(pageConnections, walk.Activated, function() invoke("Walk") end)
            scopedConnect(pageConnections, fling.Activated, function() invoke("Fling") end)
            scopedConnect(pageConnections, view.Activated, function() invoke("View") end)
            scopedConnect(pageConnections, teleport.Activated, function() invoke("Teleport") end)
            return record
        end

        for _ = 1, 12 do table.insert(rowPool, buildRow()) end
        renderPlayers = function()
            if not card.Parent then return end
            snapshots = type(context.GetPlayerSnapshot) == "function" and context.GetPlayerSnapshot(search.Text, sortMode) or {}
            playerList.CanvasSize = UDim2.fromOffset(0, #snapshots * rowHeight + 8)
            local first = math.max(1, math.floor(playerList.CanvasPosition.Y / rowHeight) + 1 - bufferRows)
            for poolIndex, record in ipairs(rowPool) do
                local dataIndex = first + poolIndex - 1
                local data = snapshots[dataIndex]
                if data then
                    record.UserId = data.UserId
                    record.Row.Visible = true
                    record.Row.Position = UDim2.fromOffset(4, (dataIndex - 1) * rowHeight + 4)
                    record.Avatar.Image = data.Avatar
                    record.Name.Text = data.DisplayName .. "  @" .. data.Username
                    local distance = data.Distance == math.huge and "--" or string.format("%.0f", data.Distance)
                    record.Details.Text = data.Relation .. "  •  " .. distance .. " studs  •  " .. string.format("%.0f%%", data.HealthRatio * 100)
                    record.Health.Size = UDim2.fromScale(data.HealthRatio, 1)
                    record.Walk.Text = data.Walking and "Stop" or "Walk"
                    record.View.Text = data.Viewing and "Stop" or "View"
                    local actionable = data.Alive and not data.Busy
                    local actionTransparency = actionable and 0 or 0.55
                    record.Walk.Active, record.Fling.Active = actionable, actionable
                    record.View.Active, record.Teleport.Active = actionable, actionable
                    record.Walk.TextTransparency, record.Fling.TextTransparency = actionTransparency, actionTransparency
                    record.View.TextTransparency, record.Teleport.TextTransparency = actionTransparency, actionTransparency
                else
                    record.UserId = nil
                    record.Row.Visible = false
                end
            end
        end

        scopedConnect(pageConnections, search:GetPropertyChangedSignal("Text"), renderPlayers)
        scopedConnect(pageConnections, sortButton.Activated, function()
            openDropdown(sortButton, normalizeOptions(playerSortOptions), sortMode, function(value)
                sortMode = value
                if type(context.SetPlayerSort) == "function" then context.SetPlayerSort(value) end
                sortButton.Text = value .. "   ▾"
                renderPlayers()
            end)
        end)
        scopedConnect(pageConnections, playerList:GetPropertyChangedSignal("CanvasPosition"), renderPlayers)
        if type(context.SubscribePlayers) == "function" then
            playerSubscription = context.SubscribePlayers(renderPlayers)
            if playerSubscription then table.insert(pageConnections, playerSubscription) end
        end
        renderPlayers()
        return card
    end

    local function createPage(category)
        currentRenderers, currentRows, sectionRecords = {}, {}, {}
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
            description.Text = string.format("%d indexed controls · %d categories\nUse the navigation rail or search to reach every feature.", total, #CATEGORY_META)
            description.TextColor3 = theme.Signal
            description.TextSize = 14
            description.TextTransparency = 0.22
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.ZIndex = 4009
            description.Parent = summary
        end

        if category == "Players" then
            createPlayerDirectory(scroll)
            return page, scroll
        end

        local grouped, sectionNames, sectionOrder = {}, {}, {}
        for _, entry in ipairs(entriesByCategory[category] or {}) do
            local sectionName = tostring(entry.Section or "General")
            if not grouped[sectionName] then
                grouped[sectionName] = {}
                table.insert(sectionNames, sectionName)
                sectionOrder[sectionName] = tonumber(entry.SectionOrder) or 9999
            end
            table.insert(grouped[sectionName], entry)
        end
        table.sort(sectionNames, function(first, second)
            if sectionOrder[first] ~= sectionOrder[second] then return sectionOrder[first] < sectionOrder[second] end
            return first < second
        end)
        for _, sectionName in ipairs(sectionNames) do
            table.sort(grouped[sectionName], function(first, second)
                return (tonumber(first.Order) or 99999) < (tonumber(second.Order) or 99999)
            end)
        end

        local columnsRoot = Instance.new("Frame")
        columnsRoot.BackgroundTransparency = 1
        columnsRoot.BorderSizePixel = 0
        columnsRoot.LayoutOrder = 2
        columnsRoot.Size = UDim2.new(1, -6, 0, 0)
        columnsRoot.ZIndex = 4007
        columnsRoot.Parent = scroll
        local columnGap = layout.SectionGap
        local leftColumn = Instance.new("Frame")
        leftColumn.AutomaticSize = Enum.AutomaticSize.Y
        leftColumn.BackgroundTransparency = 1
        leftColumn.BorderSizePixel = 0
        leftColumn.Size = UDim2.new(0.5, -columnGap * 0.5, 0, 0)
        leftColumn.ZIndex = 4007
        leftColumn.Parent = columnsRoot
        local rightColumn = leftColumn:Clone()
        rightColumn.AutomaticSize = Enum.AutomaticSize.Y
        rightColumn.Position = UDim2.new(0.5, columnGap * 0.5, 0, 0)
        rightColumn.Parent = columnsRoot
        local leftLayout = Instance.new("UIListLayout")
        leftLayout.Padding = UDim.new(0, layout.SectionGap)
        leftLayout.Parent = leftColumn
        local rightLayout = leftLayout:Clone()
        rightLayout.Parent = rightColumn
        local function syncColumnsHeight()
            columnsRoot.Size = UDim2.new(1, -6, 0, math.max(leftLayout.AbsoluteContentSize.Y, rightLayout.AbsoluteContentSize.Y))
        end
        scopedConnect(pageConnections, leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), syncColumnsHeight)
        scopedConnect(pageConnections, rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), syncColumnsHeight)
        for index, sectionName in ipairs(sectionNames) do
            local targetColumn = index % 2 == 1 and leftColumn or rightColumn
            local section = createSection(targetColumn, sectionName, grouped[sectionName])
            section.LayoutOrder = math.ceil(index / 2)
        end
        task.defer(syncColumnsHeight)

        if #sectionNames == 0 and category ~= "Home" then
            local empty = Instance.new("TextLabel")
            empty.BackgroundTransparency = 1
            empty.FontFace = fonts.HeadingHeavy
            empty.LayoutOrder = 2
            empty.Size = UDim2.new(1, -6, 0, 80)
            empty.Text = "This category has no registered controls yet."
            empty.TextColor3 = theme.Signal
            empty.TextSize = 16
            empty.TextTransparency = 0.3
            empty.TextWrapped = true
            empty.ZIndex = 4008
            empty.Parent = columnsRoot
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
            local entry = entryByFlag[flag]
            local sectionKey = entry and (tostring(entry.Category) .. "/" .. tostring(entry.Section)) or nil
            local sectionRecord = sectionKey and sectionRecords[sectionKey]
            if sectionRecord and sectionCollapsed[sectionKey] then
                sectionCollapsed[sectionKey] = false
                sectionRecord.Render(false)
                task.wait(motion.Sidebar)
            end
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
        closeDropdown(true)
        clearScopedConnections(pageConnections)
        refreshNavigation()
        if instant then
            if previous and previous.Parent then previous:Destroy() end
            local nextPage, nextScroll = createPage(category)
            currentPage = nextPage
            nextPage.Position = UDim2.fromOffset(0, 0)
            nextPage.GroupTransparency = 0
            if focusFlag then focusRow(focusFlag, nextScroll) end
            return true
        end
        currentPage = nil
        if previous and previous.Parent then
            animate(previous, {Position = UDim2.fromOffset(0, -28), GroupTransparency = 1}, motion.PageOut, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        end
        task.spawn(function()
            if previous and previous.Parent then task.wait(motion.PageOut) end
            if previous and previous.Parent then previous:Destroy() end
            task.wait(0.3)
            if destroyed or revision ~= pageRevision then return end
            local nextPage, nextScroll = createPage(category)
            currentPage = nextPage
            nextPage.Position = UDim2.fromOffset(0, -28)
            nextPage.GroupTransparency = 1
            animate(nextPage, {Position = UDim2.fromOffset(0, 0), GroupTransparency = 0}, motion.PageIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            if focusFlag then
                task.delay(motion.PageIn, function()
                    if not destroyed and revision == pageRevision then focusRow(focusFlag, nextScroll) end
                end)
            end
        end)
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
            local glyphPosition = expanded and UDim2.fromOffset(27, layout.NavigationHeight * 0.5) or UDim2.fromOffset(24, layout.NavigationHeight * 0.5)
            if instant then
                record.Button.Size = UDim2.new(1, -20, 0, layout.NavigationHeight)
                record.Glyph.Position = glyphPosition
                record.Label.Position = expanded and UDim2.fromOffset(54, 0) or UDim2.fromOffset(62, 0)
                record.Label.TextTransparency = expanded and 0 or 1
            else
                animate(record.Glyph, {Position = glyphPosition}, duration, Enum.EasingStyle.Quint)
                animate(record.Label, {
                    Position = expanded and UDim2.fromOffset(54, 0) or UDim2.fromOffset(62, 0),
                    TextTransparency = expanded and 0 or 1
                }, duration * 0.72, Enum.EasingStyle.Quint)
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
        local matches, seenSections = {}, {}
        for _, meta in ipairs(CATEGORY_META) do
            if string.find(normalizedText(meta.Id .. " " .. meta.Label), query, 1, true) then
                table.insert(matches, {Kind = "Category", Category = meta.Id, Label = meta.Label, Priority = 1})
            end
        end
        for _, entry in ipairs(indexEntries) do
            local sectionKey = tostring(entry.Category) .. "/" .. tostring(entry.Section)
            if not seenSections[sectionKey] and string.find(normalizedText(entry.Category .. " " .. entry.Section), query, 1, true) then
                seenSections[sectionKey] = true
                table.insert(matches, {
                    Kind = "Section", Category = entry.Category, Section = entry.Section,
                    Label = entry.Section, Flag = entry.Flag, Priority = 2,
                    SectionOrder = entry.SectionOrder
                })
            end
            if string.find(normalizedText(entry.Category .. " " .. entry.Section .. " " .. entry.Label .. " " .. entry.Kind), query, 1, true) then
                table.insert(matches, {
                    Kind = "Control", Category = entry.Category, Section = entry.Section,
                    Label = entry.Label, Flag = entry.Flag, Priority = 3,
                    SectionOrder = entry.SectionOrder, Order = entry.Order
                })
            end
        end
        table.sort(matches, function(first, second)
            if first.Priority ~= second.Priority then return first.Priority < second.Priority end
            local firstCategory, secondCategory = CATEGORY_ORDER[first.Category] or 99, CATEGORY_ORDER[second.Category] or 99
            if firstCategory ~= secondCategory then return firstCategory < secondCategory end
            if (tonumber(first.SectionOrder) or 9999) ~= (tonumber(second.SectionOrder) or 9999) then
                return (tonumber(first.SectionOrder) or 9999) < (tonumber(second.SectionOrder) or 9999)
            end
            if (tonumber(first.Order) or 99999) ~= (tonumber(second.Order) or 99999) then
                return (tonumber(first.Order) or 99999) < (tonumber(second.Order) or 99999)
            end
            return tostring(first.Label) < tostring(second.Label)
        end)
        searchCount.Text = tostring(#matches)
        if #matches == 0 then searchResults.Visible = false return end
        local targetHeight, visibleCount = 14, math.min(9, #matches)
        for index, match in ipairs(matches) do
            local height = match.Kind == "Category" and 44 or (match.Kind == "Section" and 40 or 36)
            local button = Instance.new("TextButton")
            button.AutoButtonColor = false
            button.BackgroundColor3 = match.Kind == "Section" and theme.Signal or theme.Layer
            button.BackgroundTransparency = match.Kind == "Category" and 0.04 or (match.Kind == "Section" and 0 or 0.2)
            button.BorderSizePixel = 0
            button.FontFace = match.Kind == "Category" and fonts.HeadingBlack or (match.Kind == "Section" and fonts.HeadingHeavy or fonts.Body)
            button.LayoutOrder = index
            button.Size = UDim2.new(1, -2, 0, height)
            button.Text = match.Kind == "Control"
                and (tostring(match.Label) .. "   ·   " .. tostring(match.Section))
                or tostring(match.Label)
            button.TextColor3 = match.Kind == "Section" and theme.Base or theme.Signal
            button.TextSize = match.Kind == "Category" and 17 or (match.Kind == "Section" and 15 or 12)
            button.TextTransparency = match.Kind == "Control" and 0.24 or 0
            button.TextTruncate = Enum.TextTruncate.AtEnd
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.ZIndex = 4032
            button.Parent = searchList
            round(button, 9)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, match.Kind == "Control" and 20 or 11)
            padding.PaddingRight = UDim.new(0, 11)
            padding.Parent = button
            scopedConnect(searchConnections, button.MouseEnter, function()
                animate(button, {BackgroundTransparency = match.Kind == "Section" and 0.08 or 0.06}, motion.Control, Enum.EasingStyle.Quint)
            end)
            scopedConnect(searchConnections, button.MouseLeave, function()
                animate(button, {BackgroundTransparency = match.Kind == "Category" and 0.04 or (match.Kind == "Section" and 0 or 0.2)}, motion.Control, Enum.EasingStyle.Quint)
            end)
            scopedConnect(searchConnections, button.Activated, function()
                playSound("ButtonClick")
                local flag = match.Kind == "Category" and nil or match.Flag
                selectCategory(match.Category, flag, false)
                searchBox.Text = ""
                searchBox:ReleaseFocus()
                clearSearchResults()
                searchResults.Visible = false
                setSearchOpen(false, false)
            end)
            if index <= visibleCount then targetHeight = targetHeight + height + (index > 1 and 5 or 0) end
        end
        searchResultsRevision = searchResultsRevision + 1
        searchResults.Visible = true
        searchResults.GroupTransparency = 1
        searchResults.Size = UDim2.fromOffset(390, 0)
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
        local delta = input.Position - dragStart
        restingPosition = dragWindowStart + Vector2.new(delta.X, delta.Y)
        window.Position = UDim2.fromOffset(restingPosition.X, restingPosition.Y)
    end)
    connect(inputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            activeSlider = nil
        end
    end)

    local close = function() return false end
    local function open()
        if destroyed or state == "Open" or state == "Opening" then return false end
        transitionRevision, state = transitionRevision + 1, "Opening"
        local revision = transitionRevision
        local _, size, center, scale = targetGeometry()
        local source = context.GetAnchorPoint()
        window.Size = UDim2.fromOffset(size.X, size.Y)
        window.Position = UDim2.fromOffset(source.X, source.Y)
        window.GroupTransparency = 1
        windowScale.Scale = 0
        window.Visible = true
        if not currentPage or not currentPage.Parent then selectCategory(currentCategory, nil, true) end
        local move = animate(window, {Position = UDim2.fromOffset(center.X, center.Y), GroupTransparency = 0}, motion.Open, Enum.EasingStyle.Quint)
        animate(windowScale, {Scale = scale}, motion.Open, Enum.EasingStyle.Back)
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
        if destroyed or (state ~= "Open" and state ~= "Opening") then return end
        local _, size, scale = windowSize()
        responsiveScaleValue = scale
        windowPixelSize = size * scale
        window.Size = UDim2.fromOffset(size.X, size.Y)
        animate(windowScale, {Scale = scale}, motion.Control, Enum.EasingStyle.Quint)
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
        renderStatsOverlay()
    end
    controller.SetCategoryIcon = function(category, asset)
        local record = categoryIconRecords[category]
        if not record then return false end
        local resolved = tostring(asset or "")
        record.Image.Image = resolved
        record.Image.Visible = resolved ~= ""
        record.Glyph.TextTransparency = resolved ~= "" and 1 or 0
        if resolved ~= "" then
            task.delay(3, function()
                if not destroyed and record.Image.Parent and record.Image.Image == resolved and not record.Image.IsLoaded then
                    record.Image.Visible = false
                    record.Glyph.TextTransparency = 0
                end
            end)
        end
        return true
    end
    controller.Destroy = function()
        if destroyed then return end
        destroyed, transitionRevision, pageRevision, searchShellRevision, searchResultsRevision = true, transitionRevision + 1, pageRevision + 1, searchShellRevision + 1, searchResultsRevision + 1
        activeSlider = nil
        closeDropdown(true)
        if statsSubscription then pcall(function() statsSubscription:Disconnect() end) end
        clearScopedConnections(pageConnections)
        clearScopedConnections(searchConnections)
        clearScopedConnections(dropdownConnections)
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        root:Destroy()
    end
    return table.freeze(controller)
end

return table.freeze(MainMenuModule)
