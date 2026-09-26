local CatalogModule = {
    Version = 1
}

local STATUS_BY_BUILTIN_ID = table.freeze({
    mm2 = "Stable"
})
local DEFAULT_STATUS = "Supported"
local ALLOWED_STATUS = table.freeze({
    Stable = true,
    Supported = true,
    ["Un-Supported"] = true
})

local function copyEntry(source)
    local copy = {}
    for key, value in pairs(source) do
        if key ~= "Status" then
            copy[key] = value
        end
    end
    return table.freeze(copy)
end

local function getEntryStatus(entry)
    local status = STATUS_BY_BUILTIN_ID[tostring(entry.BuiltInId or "")] or DEFAULT_STATUS
    return ALLOWED_STATUS[status] and status or "Un-Supported"
end

function CatalogModule.Create(context)
    assert(type(context) == "table", "catalog context is required")
    assert(context.Parent, "catalog parent is required")
    assert(type(context.Animate) == "function", "catalog animate service is required")
    assert(type(context.GetAnchorPoint) == "function", "catalog anchor provider is required")
    assert(type(context.GetViewportSize) == "function", "catalog viewport provider is required")
    assert(type(context.GetEntries) == "function", "catalog entries provider is required")
    assert(type(context.RunEntry) == "function", "catalog execution service is required")

    local theme = context.Theme
    local fonts = context.Fonts
    local motion = context.Motion
    assert(type(motion) == "table", "catalog motion tokens are required")
    local animate = context.Animate
    local playSound = context.PlaySound or function() end
    local trackConnection = context.TrackConnection or function(connection) return connection end
    local localConnections = {}
    local destroyed = false
    local transitionRevision = 0
    local state = "Closed"

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(localConnections, connection)
        trackConnection(connection)
        return connection
    end

    local function round(object, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = object
        return corner
    end

    local function outline(object, thickness, transparency)
        local border = Instance.new("UIStroke")
        border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        border.Color = theme.Base
        border.Thickness = thickness
        border.Transparency = transparency or 0
        border.Parent = object
        return border
    end

    local function targetGeometry()
        local viewport = context.GetViewportSize()
        local width = math.max(320, math.min(1000, viewport.X - 32))
        local height = math.max(300, math.min(680, viewport.Y - 32))
        return viewport, Vector2.new(width, height), viewport * 0.5
    end

    local root = Instance.new("Frame")
    root.Name = "GameCatalogRoot"
    root.Active = false
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
    window.ClipsDescendants = true
    window.GroupTransparency = 1
    window.Position = UDim2.fromOffset(0, 0)
    window.Size = UDim2.fromOffset(22, 48)
    window.Visible = false
    window.ZIndex = 3001
    window.Parent = root
    round(window, 20)
    outline(window, 2, 0.06)

    local transitionFill = Instance.new("Frame")
    transitionFill.Name = "TransitionFill"
    transitionFill.BackgroundColor3 = theme.Layer
    transitionFill.BackgroundTransparency = 0.04
    transitionFill.BorderSizePixel = 0
    transitionFill.Size = UDim2.fromScale(1, 1)
    transitionFill.ZIndex = 3001
    transitionFill.Parent = window

    local content = Instance.new("CanvasGroup")
    content.Name = "WindowContent"
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.GroupTransparency = 1
    content.Size = UDim2.fromScale(1, 1)
    content.ZIndex = 3002
    content.Parent = window

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundColor3 = theme.Base
    header.BackgroundTransparency = 0
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 70)
    header.ZIndex = 3002
    header.Parent = content

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.FontFace = fonts.HeadingBlack
    title.Position = UDim2.fromOffset(150, 0)
    title.Size = UDim2.new(1, -300, 1, 0)
    title.Text = context.Title or "Oyun Kataloğu"
    title.TextColor3 = theme.Signal
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 3003
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
        button.Size = UDim2.fromOffset(42, 42)
        button.Text = label or ""
        button.TextColor3 = theme.Signal
        button.TextSize = 25
        button.ZIndex = 3004
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

    local closeButton = headerButton("Close", -18, "×")
    local searchButton = headerButton("Search", -70, "")

    local searchRing = Instance.new("Frame")
    searchRing.AnchorPoint = Vector2.new(0.5, 0.5)
    searchRing.BackgroundTransparency = 1
    searchRing.BorderSizePixel = 0
    searchRing.Position = UDim2.fromOffset(19, 18)
    searchRing.Size = UDim2.fromOffset(15, 15)
    searchRing.ZIndex = 3005
    searchRing.Parent = searchButton
    round(searchRing, 999)
    local searchRingStroke = Instance.new("UIStroke")
    searchRingStroke.Color = theme.Signal
    searchRingStroke.Thickness = 2
    searchRingStroke.Parent = searchRing
    local searchHandle = Instance.new("Frame")
    searchHandle.AnchorPoint = Vector2.new(0.5, 0)
    searchHandle.BackgroundColor3 = theme.Signal
    searchHandle.BorderSizePixel = 0
    searchHandle.Position = UDim2.fromOffset(28, 26)
    searchHandle.Rotation = -45
    searchHandle.Size = UDim2.fromOffset(2, 9)
    searchHandle.ZIndex = 3005
    searchHandle.Parent = searchButton
    round(searchHandle, 999)

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchInput"
    searchBox.AnchorPoint = Vector2.new(1, 0.5)
    searchBox.BackgroundColor3 = theme.Layer
    searchBox.BackgroundTransparency = 0.08
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.FontFace = fonts.Body
    searchBox.PlaceholderColor3 = theme.Signal
    searchBox.PlaceholderText = "Oyun veya durum ara"
    searchBox.Position = UDim2.new(1, -122, 0.5, 0)
    searchBox.Size = UDim2.fromOffset(0, 38)
    searchBox.Text = ""
    searchBox.TextColor3 = theme.Signal
    searchBox.TextSize = 15
    searchBox.TextTransparency = 1
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Visible = false
    searchBox.ZIndex = 3004
    searchBox.Parent = header
    round(searchBox, 11)
    outline(searchBox, 2, 0.08)
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 12)
    searchPadding.PaddingRight = UDim.new(0, 12)
    searchPadding.Parent = searchBox

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundColor3 = theme.Layer
    body.BackgroundTransparency = 0.8
    body.BorderSizePixel = 0
    body.Position = UDim2.fromOffset(0, 70)
    body.Size = UDim2.new(1, 0, 1, -116)
    body.ZIndex = 3002
    body.Parent = content

    local catalogScroll = Instance.new("ScrollingFrame")
    catalogScroll.Name = "Catalog"
    catalogScroll.Active = true
    catalogScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    catalogScroll.BackgroundTransparency = 1
    catalogScroll.BorderSizePixel = 0
    catalogScroll.CanvasSize = UDim2.fromOffset(0, 0)
    catalogScroll.Position = UDim2.fromOffset(16, 16)
    catalogScroll.ScrollBarImageColor3 = theme.Signal
    catalogScroll.ScrollBarImageTransparency = 0.35
    catalogScroll.ScrollBarThickness = 5
    catalogScroll.Size = UDim2.new(1, -32, 1, -32)
    catalogScroll.ZIndex = 3003
    catalogScroll.Parent = body

    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(12, 12)
    grid.CellSize = UDim2.new(1 / 3, -12, 0, 252)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.VerticalAlignment = Enum.VerticalAlignment.Top
    grid.Parent = catalogScroll

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyState"
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.FontFace = fonts.HeadingHeavy
    emptyLabel.Position = UDim2.fromScale(0.1, 0.38)
    emptyLabel.Size = UDim2.fromScale(0.8, 0.18)
    emptyLabel.Text = "Sonuç bulunamadı"
    emptyLabel.TextColor3 = theme.Signal
    emptyLabel.TextSize = 20
    emptyLabel.TextTransparency = 0.28
    emptyLabel.Visible = false
    emptyLabel.ZIndex = 3004
    emptyLabel.Parent = body

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.AnchorPoint = Vector2.new(0, 1)
    footer.BackgroundColor3 = theme.Base
    footer.BackgroundTransparency = 0
    footer.BorderSizePixel = 0
    footer.Position = UDim2.fromScale(0, 1)
    footer.Size = UDim2.new(1, 0, 0, 46)
    footer.ZIndex = 3002
    footer.Parent = content

    local footerMessage = Instance.new("TextLabel")
    footerMessage.BackgroundTransparency = 1
    footerMessage.FontFace = fonts.Body
    footerMessage.Position = UDim2.fromOffset(18, 0)
    footerMessage.Size = UDim2.new(1, -150, 1, 0)
    footerMessage.Text = "Çalıştırmak için bir karta tıkla"
    footerMessage.TextColor3 = theme.Signal
    footerMessage.TextSize = 14
    footerMessage.TextTransparency = 0.32
    footerMessage.TextXAlignment = Enum.TextXAlignment.Left
    footerMessage.ZIndex = 3003
    footerMessage.Parent = footer

    local footerCount = Instance.new("TextLabel")
    footerCount.AnchorPoint = Vector2.new(1, 0)
    footerCount.BackgroundTransparency = 1
    footerCount.FontFace = fonts.HeadingHeavy
    footerCount.Position = UDim2.new(1, -18, 0, 0)
    footerCount.Size = UDim2.fromOffset(110, 46)
    footerCount.Text = "0 script"
    footerCount.TextColor3 = theme.Signal
    footerCount.TextSize = 14
    footerCount.TextTransparency = 0.18
    footerCount.TextXAlignment = Enum.TextXAlignment.Right
    footerCount.ZIndex = 3003
    footerCount.Parent = footer

    local cardRecords = {}

    local function updateCanvas()
        catalogScroll.CanvasSize = UDim2.fromOffset(0, math.max(0, grid.AbsoluteContentSize.Y + 8))
    end
    connect(grid:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)

    local function setFooterMessage(message, emphasized)
        footerMessage.Text = tostring(message or "")
        footerMessage.TextTransparency = emphasized and 0 or 0.32
    end

    local function createCard(entry, index)
        local status = getEntryStatus(entry)
        local card = Instance.new("ImageButton")
        card.Name = "CatalogCard"
        card.Active = true
        card.AutoButtonColor = false
        card.BackgroundColor3 = theme.Layer
        card.BackgroundTransparency = 0.08
        card.BorderSizePixel = 0
        card.Image = ""
        card.LayoutOrder = index
        card.Selectable = true
        card.ZIndex = 3004
        card.Parent = catalogScroll
        round(card, 15)
        outline(card, 2, 0.08)

        local scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = card

        local coverFallback = Instance.new("Frame")
        coverFallback.BackgroundColor3 = theme.Base
        coverFallback.BackgroundTransparency = 0.18
        coverFallback.BorderSizePixel = 0
        coverFallback.Position = UDim2.fromOffset(8, 8)
        coverFallback.Size = UDim2.new(1, -16, 0, 142)
        coverFallback.ZIndex = 3005
        coverFallback.Parent = card
        round(coverFallback, 10)

        local fallbackText = Instance.new("TextLabel")
        fallbackText.BackgroundTransparency = 1
        fallbackText.FontFace = fonts.HeadingHeavy
        fallbackText.Position = UDim2.fromScale(0.08, 0.1)
        fallbackText.Size = UDim2.fromScale(0.84, 0.8)
        fallbackText.Text = tostring(entry.Name or "Oyun")
        fallbackText.TextColor3 = theme.Signal
        fallbackText.TextSize = 17
        fallbackText.TextTransparency = 0.24
        fallbackText.TextWrapped = true
        fallbackText.ZIndex = 3006
        fallbackText.Parent = coverFallback

        local cover = Instance.new("ImageLabel")
        cover.BackgroundTransparency = 1
        cover.BorderSizePixel = 0
        cover.Image = ""
        cover.ImageTransparency = 1
        cover.Position = UDim2.fromOffset(8, 8)
        cover.ScaleType = Enum.ScaleType.Crop
        cover.Size = UDim2.new(1, -16, 0, 142)
        cover.ZIndex = 3006
        cover.Parent = card
        round(cover, 10)

        local divider = Instance.new("Frame")
        divider.BackgroundColor3 = theme.Signal
        divider.BackgroundTransparency = 0.5
        divider.BorderSizePixel = 0
        divider.Position = UDim2.fromOffset(8, 158)
        divider.Size = UDim2.new(1, -16, 0, 2)
        divider.ZIndex = 3005
        divider.Parent = card
        round(divider, 999)

        local statusLabel = Instance.new("TextLabel")
        statusLabel.BackgroundTransparency = 1
        statusLabel.FontFace = fonts.HeadingHeavy
        statusLabel.Position = UDim2.fromOffset(10, 164)
        statusLabel.Size = UDim2.new(1, -20, 0, 22)
        statusLabel.Text = status
        statusLabel.TextColor3 = theme.Signal
        statusLabel.TextSize = 14
        statusLabel.TextTransparency = status == "Un-Supported" and 0.5 or 0.12
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.ZIndex = 3005
        statusLabel.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.FontFace = fonts.HeadingHeavy
        nameLabel.Position = UDim2.fromOffset(10, 189)
        nameLabel.Size = UDim2.new(1, -20, 0, 38)
        nameLabel.Text = tostring(entry.Name or "Adsız Script")
        nameLabel.TextColor3 = theme.Signal
        nameLabel.TextSize = 17
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextWrapped = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Top
        nameLabel.ZIndex = 3005
        nameLabel.Parent = card

        local actionHint = Instance.new("TextLabel")
        actionHint.AnchorPoint = Vector2.new(0, 1)
        actionHint.BackgroundTransparency = 1
        actionHint.FontFace = fonts.Body
        actionHint.Position = UDim2.new(0, 10, 1, -8)
        actionHint.Size = UDim2.new(1, -20, 0, 18)
        actionHint.Text = status == "Un-Supported" and "Kullanılamıyor" or "Çalıştır"
        actionHint.TextColor3 = theme.Signal
        actionHint.TextSize = 13
        actionHint.TextTransparency = 0.42
        actionHint.TextXAlignment = Enum.TextXAlignment.Right
        actionHint.ZIndex = 3005
        actionHint.Parent = card

        connect(card.MouseEnter, function()
            playSound("ButtonHover")
            animate(scale, {Scale = 1.015}, motion.Control, Enum.EasingStyle.Quint)
            animate(card, {BackgroundTransparency = 0}, motion.Control, Enum.EasingStyle.Quint)
        end)
        connect(card.MouseLeave, function()
            animate(scale, {Scale = 1}, motion.Control, Enum.EasingStyle.Quint)
            animate(card, {BackgroundTransparency = 0.08}, motion.Control, Enum.EasingStyle.Quint)
        end)
        connect(card.Activated, function()
            if state ~= "Open" then
                return
            end
            playSound("ButtonClick")
            if status == "Un-Supported" then
                setFooterMessage(tostring(entry.Name) .. " şu anda desteklenmiyor", true)
                return
            end
            setFooterMessage(tostring(entry.Name) .. " hazırlanıyor...", true)
            task.spawn(function()
                local result = context.RunEntry(entry)
                if destroyed then
                    return
                end
                setFooterMessage(result and result.Message or "Script sonucu alınamadı", true)
            end)
        end)

        if type(context.ResolveCover) == "function" and entry.PlaceId then
            task.spawn(function()
                local resolved = context.ResolveCover(entry.PlaceId)
                if destroyed or not card.Parent or not cover.Parent then
                    return
                end
                if type(resolved) == "string" and resolved ~= "" then
                    cover.Image = resolved
                    cover.ImageTransparency = 0
                    coverFallback.Visible = false
                end
            end)
        end

        local record = {
            Card = card,
            Entry = entry,
            SearchText = string.lower(
                tostring(entry.Name or "") .. " "
                    .. tostring(entry.PlaceId or "") .. " "
                    .. tostring(entry.BuiltInId or "") .. " "
                    .. status
            )
        }
        table.insert(cardRecords, record)
    end

    local entries = context.GetEntries()
    for index, sourceEntry in ipairs(type(entries) == "table" and entries or {}) do
        createCard(copyEntry(sourceEntry), index)
    end
    footerCount.Text = tostring(#cardRecords) .. " script"
    task.defer(updateCanvas)

    local function applySearch()
        local query = string.lower(searchBox.Text:gsub("^%s+", ""):gsub("%s+$", ""))
        local visibleCount = 0
        for _, record in ipairs(cardRecords) do
            local visible = query == "" or string.find(record.SearchText, query, 1, true) ~= nil
            record.Card.Visible = visible
            if visible then
                visibleCount = visibleCount + 1
            end
        end
        emptyLabel.Visible = visibleCount == 0
        footerCount.Text = tostring(visibleCount) .. " / " .. tostring(#cardRecords)
        task.defer(updateCanvas)
    end
    connect(searchBox:GetPropertyChangedSignal("Text"), applySearch)

    local searchOpen = false
    local searchRevision = 0
    local function setSearchOpen(open)
        open = open == true
        if searchOpen == open then
            return
        end
        searchOpen = open
        searchRevision = searchRevision + 1
        local revision = searchRevision
        if open then
            searchBox.Visible = true
            searchBox.Size = UDim2.fromOffset(0, 38)
            searchBox.TextTransparency = 1
            animate(
                searchBox,
                {Size = UDim2.fromOffset(240, 38), TextTransparency = 0},
                motion.SearchOpen,
                Enum.EasingStyle.Quint
            )
            task.delay(0.14, function()
                if not destroyed and revision == searchRevision and searchOpen then
                    searchBox:CaptureFocus()
                end
            end)
        else
            searchBox:ReleaseFocus()
            searchBox.Text = ""
            local tween = animate(
                searchBox,
                {Size = UDim2.fromOffset(0, 38), TextTransparency = 1},
                motion.SearchClose,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.In
            )
            task.spawn(function()
                tween.Completed:Wait()
                if not destroyed and revision == searchRevision and not searchOpen then
                    searchBox.Visible = false
                end
            end)
        end
    end

    local function setWindowToTarget()
        local _, targetSize, center = targetGeometry()
        window.Position = UDim2.fromOffset(center.X, center.Y)
        window.Size = UDim2.fromOffset(targetSize.X, targetSize.Y)
    end

    local function open()
        if destroyed or state == "Open" or state == "Opening" then
            return false
        end
        transitionRevision = transitionRevision + 1
        local revision = transitionRevision
        state = "Opening"
        task.spawn(function()
            local _, targetSize, center = targetGeometry()
            local source = context.GetAnchorPoint()
            local stretchPoint = source:Lerp(center, 0.46)
            window.Visible = true
            window.Position = UDim2.fromOffset(source.X, source.Y)
            window.Size = UDim2.fromOffset(20, 48)
            window.GroupTransparency = 0.82
            transitionFill.BackgroundTransparency = 0.04
            content.GroupTransparency = 1
            local stretchTween = animate(
                window,
                {
                    Position = UDim2.fromOffset(stretchPoint.X, stretchPoint.Y),
                    Size = UDim2.fromOffset(math.max(180, targetSize.X * 0.48), 20),
                    GroupTransparency = 0.18
                },
                motion.Stretch,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            )
            stretchTween.Completed:Wait()
            if destroyed or revision ~= transitionRevision then
                return
            end
            local expandTween = animate(
                window,
                {
                    Position = UDim2.fromOffset(center.X, center.Y),
                    Size = UDim2.fromOffset(targetSize.X, targetSize.Y),
                    GroupTransparency = 0
                },
                motion.Expand,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            )
            expandTween.Completed:Wait()
            if destroyed or revision ~= transitionRevision then
                return
            end
            animate(transitionFill, {BackgroundTransparency = 1}, motion.Content, Enum.EasingStyle.Quint)
            local contentTween = animate(
                content,
                {GroupTransparency = 0},
                motion.Content,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            )
            contentTween.Completed:Wait()
            if not destroyed and revision == transitionRevision then
                state = "Open"
            end
        end)
        return true
    end

    local function close()
        if destroyed or state == "Closed" or state == "Closing" then
            return false
        end
        transitionRevision = transitionRevision + 1
        local revision = transitionRevision
        state = "Closing"
        setSearchOpen(false)
        task.spawn(function()
            local _, targetSize, center = targetGeometry()
            local source = context.GetAnchorPoint()
            local stretchPoint = center:Lerp(source, 0.68)
            local contentTween = animate(
                content,
                {GroupTransparency = 1},
                motion.CloseContent,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.In
            )
            animate(
                transitionFill,
                {BackgroundTransparency = 0.04},
                motion.CloseContent,
                Enum.EasingStyle.Quint
            )
            contentTween.Completed:Wait()
            if destroyed or revision ~= transitionRevision then
                return
            end
            local contractTween = animate(
                window,
                {
                    Position = UDim2.fromOffset(stretchPoint.X, stretchPoint.Y),
                    Size = UDim2.fromOffset(math.max(180, targetSize.X * 0.48), 20),
                    GroupTransparency = 0.18
                },
                motion.Contract,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.In
            )
            contractTween.Completed:Wait()
            if destroyed or revision ~= transitionRevision then
                return
            end
            source = context.GetAnchorPoint()
            local returnTween = animate(
                window,
                {
                    Position = UDim2.fromOffset(source.X, source.Y),
                    Size = UDim2.fromOffset(18, 42),
                    GroupTransparency = 1
                },
                motion.Return,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.In
            )
            returnTween.Completed:Wait()
            if not destroyed and revision == transitionRevision then
                window.Visible = false
                state = "Closed"
            end
        end)
        return true
    end

    local function toggle()
        if state == "Open" or state == "Opening" then
            return close()
        end
        return open()
    end

    connect(searchButton.Activated, function()
        if state == "Open" then
            playSound("ButtonClick")
            setSearchOpen(not searchOpen)
        end
    end)
    connect(closeButton.Activated, function()
        if state == "Open" then
            playSound("ButtonClick")
            close()
        end
    end)
    connect(context.Parent:GetPropertyChangedSignal("AbsoluteSize"), function()
        if not destroyed and state == "Open" then
            setWindowToTarget()
        end
    end)

    local controller = {}
    controller.Open = open
    controller.Close = close
    controller.Toggle = toggle
    controller.IsOpen = function()
        return state == "Open" or state == "Opening"
    end
    controller.Destroy = function()
        if destroyed then
            return
        end
        destroyed = true
        transitionRevision = transitionRevision + 1
        for _, connection in ipairs(localConnections) do
            pcall(function() connection:Disconnect() end)
        end
        root:Destroy()
    end
    return table.freeze(controller)
end

return table.freeze(CatalogModule)
