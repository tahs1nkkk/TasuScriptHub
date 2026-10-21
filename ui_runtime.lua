local UIRuntimeModule = {Version = 1}

local function assertContext(context)
    assert(type(context) == "table", "UI runtime context is required")
    assert(type(context.Animate) == "function", "UI runtime animate service is required")
    assert(type(context.Theme) == "table", "UI runtime theme is required")
end

function UIRuntimeModule.Create(context)
    assertContext(context)

    local runtime = {}
    local destroyed = false
    local ownedConnections = {}

    function runtime.Round(object, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, tonumber(radius) or 0)
        corner.Parent = object
        return corner
    end

    function runtime.Outline(object, thickness, transparency, color)
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = color or context.Theme.Base
        stroke.Thickness = tonumber(thickness) or 1
        stroke.Transparency = tonumber(transparency) or 0
        stroke.Parent = object
        return stroke
    end

    function runtime.Connect(signal, callback, bucket)
        if destroyed then return nil end
        local connection = signal:Connect(callback)
        table.insert(bucket or ownedConnections, connection)
        if type(context.TrackConnection) == "function" then
            context.TrackConnection(connection)
        end
        return connection
    end

    function runtime.ClearConnections(bucket)
        for _, connection in ipairs(type(bucket) == "table" and bucket or {}) do
            pcall(function() connection:Disconnect() end)
        end
        if type(bucket) == "table" then table.clear(bucket) end
    end

    function runtime.CreateScope()
        local scope = {Connections = {}, Instances = {}, Revision = 0, Destroyed = false}

        function scope:Connect(signal, callback)
            if self.Destroyed then return nil end
            return runtime.Connect(signal, callback, self.Connections)
        end

        function scope:Own(instance)
            if typeof(instance) == "Instance" then table.insert(self.Instances, instance) end
            return instance
        end

        function scope:NextRevision()
            self.Revision = self.Revision + 1
            return self.Revision
        end

        function scope:IsCurrent(revision)
            return not self.Destroyed and self.Revision == revision
        end

        function scope:Destroy()
            if self.Destroyed then return end
            self.Destroyed = true
            self.Revision = self.Revision + 1
            runtime.ClearConnections(self.Connections)
            for _, instance in ipairs(self.Instances) do
                if instance and instance.Parent then pcall(function() instance:Destroy() end) end
            end
            table.clear(self.Instances)
        end

        return scope
    end

    function runtime.CreateSurface(parent, options)
        options = type(options) == "table" and options or {}
        local className = options.ClassName or "Frame"
        local surface = Instance.new(className)
        surface.Name = options.Name or "Surface"
        surface.BackgroundColor3 = options.Color or context.Theme.Layer
        surface.BackgroundTransparency = options.Transparency == nil and 0 or options.Transparency
        surface.BorderSizePixel = 0
        surface.Size = options.Size or UDim2.fromScale(1, 1)
        surface.Position = options.Position or UDim2.fromOffset(0, 0)
        surface.ZIndex = options.ZIndex or 1
        surface.Parent = parent
        if options.Radius then runtime.Round(surface, options.Radius) end
        if options.Stroke then
            runtime.Outline(surface, options.Stroke, options.StrokeTransparency, options.StrokeColor)
        end
        return surface
    end

    function runtime.CreateLabel(parent, options)
        options = type(options) == "table" and options or {}
        local label = Instance.new(options.ClassName or "TextLabel")
        label.Name = options.Name or "Label"
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.FontFace = options.Font or context.Fonts.Body
        label.Position = options.Position or UDim2.fromOffset(0, 0)
        label.Size = options.Size or UDim2.fromScale(1, 1)
        label.Text = tostring(options.Text or "")
        label.TextColor3 = options.Color or context.Theme.Signal
        label.TextSize = options.TextSize or 13
        label.TextTransparency = options.TextTransparency or 0
        label.TextXAlignment = options.TextXAlignment or Enum.TextXAlignment.Left
        label.TextYAlignment = options.TextYAlignment or Enum.TextYAlignment.Center
        label.ZIndex = options.ZIndex or 1
        label.Parent = parent
        return label
    end

    function runtime.CreateButton(parent, options)
        options = type(options) == "table" and options or {}
        local button = runtime.CreateSurface(parent, {
            ClassName = "TextButton",
            Name = options.Name or "Button",
            Color = options.Color or context.Theme.Layer,
            Transparency = options.Transparency == nil and 0.12 or options.Transparency,
            Position = options.Position,
            Size = options.Size,
            ZIndex = options.ZIndex,
            Radius = options.Radius,
            Stroke = options.Stroke,
            StrokeColor = options.StrokeColor,
            StrokeTransparency = options.StrokeTransparency
        })
        button.Active = options.Active ~= false
        button.AutoButtonColor = false
        button.FontFace = options.Font or context.Fonts.Body
        button.Text = tostring(options.Text or "")
        button.TextColor3 = options.TextColor or context.Theme.Signal
        button.TextSize = options.TextSize or 13
        return button
    end

    function runtime.Animate(object, properties, duration, style, direction)
        if destroyed or not object or not object.Parent then return nil end
        return context.Animate(object, properties, duration, style, direction)
    end

    function runtime.Destroy()
        if destroyed then return end
        destroyed = true
        runtime.ClearConnections(ownedConnections)
    end

    return table.freeze(runtime)
end

return table.freeze(UIRuntimeModule)
