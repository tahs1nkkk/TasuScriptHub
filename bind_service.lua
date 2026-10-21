local BindServiceModule = {Version = 1}

local DEFAULT_ICON = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png"
local RESERVED_KEYS = table.freeze({
    Unknown = true,
    RightShift = true,
    Escape = true
})

local function copyAssignments(order, keys)
    local result = {}
    for _, id in ipairs(order) do
        local key = keys[id]
        if key then table.insert(result, {Id = id, Key = key}) end
    end
    return result
end

function BindServiceModule.Create(context)
    assert(type(context) == "table", "bind service context is required")
    assert(context.Parent, "bind service parent is required")
    assert(context.InputService, "bind service input service is required")
    assert(context.RunService, "bind service run service is required")
    assert(type(context.Animate) == "function", "bind service animate service is required")
    assert(type(context.Theme) == "table", "bind service theme is required")

    local theme = context.Theme
    local inputService = context.InputService
    local runService = context.RunService
    local animate = context.Animate
    local playSound = context.PlaySound or function() end
    local resolveIcon = context.ResolveIcon or function() return "" end
    local trackConnection = context.TrackConnection or function(connection) return connection end
    local maxBindings = tonumber(context.MaxBindings) or 5

    local destroyed = false
    local targets, keys, order, records = {}, {}, {}, {}
    local connections, subscribers = {}, {}
    local pendingCapture = nil
    local cooldowns = {}
    local cooldownConnection = nil
    local hudAllowed = context.InitiallyVisible == true

    local root = Instance.new("Frame")
    root.Name = "BindHUD"
    root.AnchorPoint = Vector2.new(1, 0.5)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ClipsDescendants = false
    root.Position = UDim2.new(1, -22, 0.5, 0)
    root.Size = UDim2.fromOffset(64, 1)
    root.Visible = false
    root.ZIndex = 1500
    root.Parent = context.Parent

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

    local function notify(event, payload)
        for callback in pairs(subscribers) do
            task.defer(callback, event, payload)
        end
        if type(context.OnAssignmentsChanged) == "function"
            and (event == "Assigned" or event == "Cleared" or event == "Applied") then
            task.defer(context.OnAssignmentsChanged, copyAssignments(order, keys))
        end
    end

    local function targetColor(target, active)
        if active and typeof(target.ActiveColor) == "Color3" then return target.ActiveColor end
        if not active and typeof(target.InactiveColor) == "Color3" then return target.InactiveColor end
        return target.Color or theme.Signal
    end

    local function isTargetActive(target)
        if type(target.GetActive) ~= "function" then return false end
        local ok, value = pcall(target.GetActive)
        return ok and value == true
    end

    local function refreshRecord(id)
        local record, target = records[id], targets[id]
        if not record or not target then return end
        local active = isTargetActive(target)
        local color = targetColor(target, active)
        local resolvedIcon = tostring(resolveIcon(target.IconKey, id) or "")
        record.Icon.Image = resolvedIcon ~= "" and resolvedIcon or DEFAULT_ICON
        record.Icon.ImageColor3 = color
        record.Icon.ImageTransparency = active and 0 or 0.34
        record.Stroke.Color = color
        record.Stroke.Transparency = active and 0.08 or 0.42
    end

    local function pressRecord(record, denied)
        if not record or not record.Scale then return end
        local color = denied and theme.Danger or nil
        if color then
            record.Stroke.Color = color
            record.Stroke.Transparency = 0
        end
        animate(record.Scale, {Scale = denied and 0.9 or 0.88}, 0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.07, function()
            if destroyed or not record.Scale.Parent then return end
            animate(record.Scale, {Scale = denied and 1.03 or 1.06}, 0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            task.delay(0.11, function()
                if destroyed or not record.Scale.Parent then return end
                animate(record.Scale, {Scale = 1}, 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                refreshRecord(record.Id)
            end)
        end)
    end

    local function updateCooldownMask(record, remainingRatio)
        remainingRatio = math.clamp(remainingRatio or 0, 0, 1)
        record.CooldownMask.Visible = remainingRatio > 0
        record.CooldownMask.Size = UDim2.fromScale(1, remainingRatio)
        record.CooldownMask.Position = UDim2.fromScale(0, 1 - remainingRatio)
    end

    local function stopCooldownSchedulerIfIdle()
        if next(cooldowns) ~= nil or not cooldownConnection then return end
        cooldownConnection:Disconnect()
        cooldownConnection = nil
    end

    local function startCooldownScheduler()
        if cooldownConnection then return end
        cooldownConnection = runService.Heartbeat:Connect(function()
            local now = os.clock()
            for id, cooldown in pairs(cooldowns) do
                local record = records[id]
                local remaining = cooldown.EndsAt - now
                if remaining <= 0 then
                    cooldowns[id] = nil
                    if record then updateCooldownMask(record, 0); refreshRecord(id) end
                elseif record then
                    updateCooldownMask(record, remaining / cooldown.Duration)
                end
            end
            stopCooldownSchedulerIfIdle()
        end)
        trackConnection(cooldownConnection)
    end

    local function beginCooldown(id, duration)
        duration = tonumber(duration) or 0
        if duration <= 0 then return end
        cooldowns[id] = {Duration = duration, EndsAt = os.clock() + duration}
        local record = records[id]
        if record then updateCooldownMask(record, 1) end
        startCooldownScheduler()
    end

    local function invoke(id)
        local target, record = targets[id], records[id]
        if not target then return false, "Bind target is unavailable" end
        if cooldowns[id] then
            pressRecord(record, true)
            return false, "Action is cooling down"
        end
        if type(target.IsAvailable) == "function" then
            local ok, available = pcall(target.IsAvailable)
            if not ok or available == false then
                pressRecord(record, true)
                return false, "Action is unavailable"
            end
        end
        if type(target.Invoke) ~= "function" then return false, "Bind target has no action" end
        pressRecord(record, false)
        local ok, first, second = pcall(target.Invoke)
        if not ok or first == false then
            pressRecord(record, true)
            return false, ok and second or first
        end
        beginCooldown(id, target.Cooldown)
        task.defer(refreshRecord, id)
        return true, second
    end

    local function createRecord(id)
        local target = targets[id]
        if not target or not keys[id] or records[id] then return records[id] end

        local tile = Instance.new("Frame")
        tile.Name = "Bind_" .. id:gsub("[^%w_]", "_")
        tile.AnchorPoint = Vector2.new(0.5, 0.5)
        tile.BackgroundColor3 = theme.Layer
        tile.BackgroundTransparency = 0.12
        tile.BorderSizePixel = 0
        tile.ClipsDescendants = true
        tile.Position = UDim2.fromOffset(32, 0)
        tile.Size = UDim2.fromOffset(56, 56)
        tile.ZIndex = 1501
        tile.Parent = root
        round(tile, 14)
        local stroke = outline(tile, 2, 0.42, theme.Signal)

        local scale = Instance.new("UIScale")
        scale.Scale = 0.82
        scale.Parent = tile

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.BorderSizePixel = 0
        icon.Image = tostring(resolveIcon(target.IconKey, id) or "")
        if icon.Image == "" then icon.Image = DEFAULT_ICON end
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Size = UDim2.fromOffset(38, 38)
        icon.ZIndex = 1502
        icon.Parent = tile

        local cooldownMask = Instance.new("Frame")
        cooldownMask.Name = "CooldownMask"
        cooldownMask.BackgroundColor3 = theme.Layer
        cooldownMask.BackgroundTransparency = 0.12
        cooldownMask.BorderSizePixel = 0
        cooldownMask.Position = UDim2.fromScale(0, 1)
        cooldownMask.Size = UDim2.fromScale(1, 0)
        cooldownMask.Visible = false
        cooldownMask.ZIndex = 1503
        cooldownMask.Parent = tile

        local record = {
            Id = id,
            Tile = tile,
            Scale = scale,
            Icon = icon,
            Stroke = stroke,
            CooldownMask = cooldownMask
        }
        records[id] = record
        refreshRecord(id)
        animate(scale, {Scale = 1}, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        return record
    end

    local function layoutRecords()
        local visible = {}
        for _, id in ipairs(order) do
            if keys[id] and targets[id] then
                table.insert(visible, id)
                createRecord(id)
            end
        end
        root.Visible = hudAllowed and #visible > 0
        local step = 68
        for index, id in ipairs(visible) do
            local record = records[id]
            if record then
                local y = (index - (#visible + 1) * 0.5) * step
                animate(record.Tile, {Position = UDim2.fromOffset(32, y)}, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            end
        end
        for id, record in pairs(records) do
            if not table.find(visible, id) then
                records[id] = nil
                animate(record.Scale, {Scale = 0.82}, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
                task.delay(0.18, function()
                    if record.Tile and record.Tile.Parent then record.Tile:Destroy() end
                end)
            end
        end
    end

    local function removeOrder(id)
        local index = table.find(order, id)
        if index then table.remove(order, index) end
    end

    local controller = {}

    function controller.Register(descriptor)
        if destroyed or type(descriptor) ~= "table" then return false, "Invalid bind descriptor" end
        local id = tostring(descriptor.Id or "")
        if id == "" or (descriptor.Kind ~= "Toggle" and descriptor.Kind ~= "Action")
            or type(descriptor.Invoke) ~= "function" then
            return false, "Invalid bind descriptor"
        end
        targets[id] = {
            Id = id,
            Scope = tostring(descriptor.Scope or "Global"),
            Kind = descriptor.Kind,
            IconKey = tostring(descriptor.IconKey or "Generic"),
            Color = descriptor.Color,
            ActiveColor = descriptor.ActiveColor,
            InactiveColor = descriptor.InactiveColor,
            Cooldown = math.max(0, tonumber(descriptor.Cooldown) or 0),
            GetActive = descriptor.GetActive,
            IsAvailable = descriptor.IsAvailable,
            Invoke = descriptor.Invoke
        }
        layoutRecords()
        return true
    end

    function controller.Unregister(id)
        id = tostring(id or "")
        targets[id] = nil
        cooldowns[id] = nil
        if keys[id] then
            keys[id] = nil
            removeOrder(id)
            notify("Cleared", {Id = id})
        end
        layoutRecords()
        return true
    end

    function controller.Assign(id, keyName)
        id, keyName = tostring(id or ""), tostring(keyName or "")
        if not targets[id] then return false, "Bind target is unavailable", "Unavailable" end
        if keyName == "" or RESERVED_KEYS[keyName] then return false, "Key is reserved", "Reserved" end
        for otherId, assignedKey in pairs(keys) do
            if otherId ~= id and assignedKey == keyName then
                return false, "Key is already assigned", "Conflict"
            end
        end
        if not keys[id] and #order >= maxBindings then
            return false, "Maximum of five binds reached", "Limit"
        end
        if not keys[id] then table.insert(order, id) end
        keys[id] = keyName
        layoutRecords()
        notify("Assigned", {Id = id, Key = keyName})
        return true, keyName, "Success"
    end

    function controller.Clear(id)
        id = tostring(id or "")
        if not keys[id] then return true end
        keys[id] = nil
        removeOrder(id)
        cooldowns[id] = nil
        layoutRecords()
        notify("Cleared", {Id = id})
        return true
    end

    function controller.BeginCapture(id, callback)
        id = tostring(id or "")
        if not targets[id] then return false, "Bind target is unavailable" end
        pendingCapture = {Id = id, Callback = callback, PreviousKey = keys[id]}
        notify("CaptureStarted", {Id = id, PreviousKey = keys[id]})
        return true
    end

    function controller.CancelCapture()
        if not pendingCapture then return false end
        local capture = pendingCapture
        pendingCapture = nil
        if type(capture.Callback) == "function" then
            task.defer(capture.Callback, {Status = "Cancelled", PreviousKey = capture.PreviousKey})
        end
        return true
    end

    function controller.GetKey(id)
        return keys[tostring(id or "")]
    end

    function controller.HasTarget(id)
        return targets[tostring(id or "")] ~= nil
    end

    function controller.GetAssignments()
        return copyAssignments(order, keys)
    end

    function controller.ApplyAssignments(assignments)
        if type(assignments) ~= "table" or #assignments > maxBindings then
            return false, "Invalid bind list"
        end
        local nextKeys, nextOrder, seenKeys = {}, {}, {}
        for _, item in ipairs(assignments) do
            local id = tostring(type(item) == "table" and item.Id or "")
            local keyName = tostring(type(item) == "table" and item.Key or "")
            if id == "" or keyName == "" or RESERVED_KEYS[keyName] or seenKeys[keyName] or not targets[id] then
                return false, "Invalid or unavailable bind: " .. id
            end
            seenKeys[keyName] = true
            nextKeys[id] = keyName
            table.insert(nextOrder, id)
        end
        keys, order = nextKeys, nextOrder
        layoutRecords()
        notify("Applied", controller.GetAssignments())
        return true
    end

    function controller.Refresh(id)
        if id then refreshRecord(tostring(id)) else
            for targetId in pairs(targets) do refreshRecord(targetId) end
        end
    end

    function controller.SetVisible(visible)
        hudAllowed = visible == true
        layoutRecords()
    end

    function controller.Subscribe(callback)
        if type(callback) ~= "function" then return nil end
        subscribers[callback] = true
        return {Disconnect = function() subscribers[callback] = nil end}
    end

    function controller.Invoke(id)
        return invoke(tostring(id or ""))
    end

    function controller.Destroy()
        if destroyed then return end
        destroyed = true
        pendingCapture = nil
        if cooldownConnection then cooldownConnection:Disconnect(); cooldownConnection = nil end
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        table.clear(connections)
        table.clear(subscribers)
        table.clear(cooldowns)
        if root then root:Destroy() end
    end

    connect(inputService.InputBegan, function(input, processed)
        if destroyed then return end
        if pendingCapture then
            if processed or inputService:GetFocusedTextBox() then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local capture = pendingCapture
            local keyName = input.KeyCode.Name
            if keyName == "Escape" then
                controller.CancelCapture()
                return
            end
            pendingCapture = nil
            local ok, message, status
            if keyName == "Backspace" then
                controller.Clear(capture.Id)
                ok, message, status = true, nil, "Cleared"
            else
                ok, message, status = controller.Assign(capture.Id, keyName)
            end
            if type(capture.Callback) == "function" then
                task.defer(capture.Callback, {
                    Status = status or (ok and "Success" or "Rejected"),
                    Message = message,
                    Key = ok and controller.GetKey(capture.Id) or keyName,
                    PreviousKey = capture.PreviousKey
                })
            end
            return
        end
        if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if inputService:GetFocusedTextBox() then return end
        local keyName = input.KeyCode.Name
        for _, id in ipairs(order) do
            if keys[id] == keyName then
                playSound("ButtonClick")
                invoke(id)
                return
            end
        end
    end)

    return table.freeze(controller)
end

return table.freeze(BindServiceModule)
