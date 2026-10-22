local Module = {Version = 2}

local ROLE_COLORS = table.freeze({
    Murderer = Color3.fromRGB(244, 72, 83),
    Sheriff = Color3.fromRGB(65, 145, 255),
    Innocent = Color3.fromRGB(242, 243, 245)
})

local function copyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local function disconnectAll(connections)
    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(connections)
end

local function characterInfo(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    return character, humanoid, root
end

local function findTool(player, toolName)
    if not player then return nil end
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    local tool = character and character:FindFirstChild(toolName)
    if not tool and backpack then tool = backpack:FindFirstChild(toolName) end
    return tool and tool:IsA("Tool") and tool or nil
end

local function roleFromReplicatedState(player)
    for _, container in ipairs({player, player and player.Character}) do
        if container then
            for _, name in ipairs({"Role", "ServerRole", "MM2ServerRole"}) do
                local value = container:GetAttribute(name)
                local object = container:FindFirstChild(name)
                if object and object:IsA("StringValue") then value = object.Value end
                if type(value) == "string" then
                    local lowered = string.lower(value)
                    if string.find(lowered, "murder", 1, true) then return "Murderer" end
                    if string.find(lowered, "sheriff", 1, true) or string.find(lowered, "hero", 1, true) then
                        return "Sheriff"
                    end
                    if string.find(lowered, "innocent", 1, true) then return "Innocent" end
                end
            end
        end
    end
    if findTool(player, "Knife") then return "Murderer" end
    if findTool(player, "Gun") then return "Sheriff" end
    return "Innocent"
end

local function getAdorneeHeight(character)
    local ok, _, size = pcall(function() return character:GetBoundingBox() end)
    return ok and size and size.Y or 6
end

local function clearContainer(container)
    for _, child in ipairs(container:GetChildren()) do child:Destroy() end
end

local function sanitizeToolClone(tool)
    local clone = tool and tool:Clone()
    if not clone then return nil end
    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript")
            or object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
        end
    end
    return clone
end

function Module.Create(context)
    assert(type(context) == "table", "[TasuHub/MM2Service] context is required")
    local Players = assert(context.Players, "Players is required")
    local LocalPlayer = assert(context.LocalPlayer, "LocalPlayer is required")
    local Workspace = assert(context.Workspace, "Workspace is required")
    local RunService = assert(context.RunService, "RunService is required")
    local TweenService = context.TweenService
    local overlayParent = assert(context.OverlayParent, "OverlayParent is required")
    local theme = assert(context.Theme, "Theme is required")
    local roleColors = type(context.DataColors) == "table" and context.DataColors or ROLE_COLORS
    local resolveGlobal = context.ResolveGlobal or function(name)
        local environment = getgenv and getgenv() or _G
        return environment[name] or _G[name]
    end
    local claimOverlay = context.ClaimOverlay or function() end
    local releaseOverlay = context.ReleaseOverlay or function() end

    local initial = type(context.InitialState) == "table" and context.InitialState or {}
    local initialUndergroundOffset = tonumber(initial.UndergroundOffset)
    if initialUndergroundOffset == 12 then initialUndergroundOffset = 5 end
    local State = {
        Enabled = initial.Enabled == true,
        MurdererESP = initial.MurdererESP ~= false and initial.PlayerESP ~= false,
        SheriffESP = initial.SheriffESP ~= false and initial.PlayerESP ~= false,
        InnocentESP = initial.InnocentESP == true,
        AvatarCardESP = initial.AvatarCardESP == true,
        WeaponCardESP = initial.WeaponCardESP == true,
        GunDropESP = initial.GunDropESP ~= false,
        AutoPickup = initial.AutoPickup == true,
        AutoFire = initial.AutoFire == true,
        AutoFarm = initial.AutoFarm == true,
        FarmSpeed = math.clamp(tonumber(initial.FarmSpeed) or 55, 20, 90),
        UndergroundOffset = math.clamp(initialUndergroundOffset or 5, 5, 30)
    }
    local connections, subscribers, espRecords = {}, {}, {}
    local roleSnapshot, destroyed = {}, false
    local gunHighlight, heartbeatClock, lastShotAt = nil, 0, 0
    local farmRevision, farmState = 0, "Stopped"
    local farmSnapshot, antiIdleConnection = nil, nil
    local avatarCache = {}
    local farmCache = {
        Map = nil,
        Container = nil,
        LastMapScan = 0,
        BagLabel = nil,
        FullBagIndicator = nil,
        LastBagScan = 0,
        FailedUntil = setmetatable({}, {__mode = "k"})
    }
    local shotHook = {Pending = nil, Installed = false}
    local shotBusy = false

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function snapshot()
        local result = copyTable(State)
        result.FarmState = farmState
        return result
    end

    local function emit(eventName, message, success)
        local current = snapshot()
        for callback in pairs(subscribers) do
            pcall(callback, current, eventName, message, success)
        end
    end

    local function roleEnabled(role)
        return role == "Murderer" and State.MurdererESP
            or role == "Sheriff" and State.SheriffESP
            or role == "Innocent" and State.InnocentESP
    end

    local function destroyESP(player)
        local record = espRecords[player]
        if not record then return end
        releaseOverlay(player, "mm2")
        if record.ColorTween then pcall(function() record.ColorTween:Cancel() end) end
        for _, object in pairs(record) do
            if typeof(object) == "Instance" then pcall(function() object:Destroy() end) end
        end
        espRecords[player] = nil
        roleSnapshot[player] = nil
    end

    local function createCardFrame(parent, name)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.BackgroundColor3 = theme.Layer
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 0
        frame.Size = UDim2.fromScale(0.47, 1)
        frame.Visible = false
        frame.ZIndex = 8
        frame.Parent = parent
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = theme.Layer
        stroke.Thickness = 2
        stroke.Transparency = 0
        stroke.Parent = frame
        return frame
    end

    local function ensureESP(player)
        local record = espRecords[player]
        if record then return record end
        local highlight = Instance.new("Highlight")
        highlight.Name = "TasuHubMM2RoleChams"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.64
        highlight.OutlineTransparency = 0.04
        highlight.Enabled = false
        highlight.Parent = overlayParent

        local cards = Instance.new("BillboardGui")
        cards.Name = "TasuHubMM2RoleCards"
        cards.AlwaysOnTop = true
        cards.LightInfluence = 0
        cards.MaxDistance = 2500
        cards.Size = UDim2.fromScale(9.8, 4.8)
        cards.Enabled = false
        cards.Parent = overlayParent

        local avatarCard = createCardFrame(cards, "AvatarCard")
        local avatar = Instance.new("ImageLabel")
        avatar.Name = "Avatar"
        avatar.BackgroundTransparency = 1
        avatar.Position = UDim2.fromOffset(4, 4)
        avatar.Size = UDim2.new(1, -8, 1, -8)
        avatar.ScaleType = Enum.ScaleType.Crop
        avatar.ZIndex = 9
        avatar.Parent = avatarCard
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 8)
        avatarCorner.Parent = avatar

        local weaponCard = createCardFrame(cards, "WeaponCard")
        local viewport = Instance.new("ViewportFrame")
        viewport.Name = "WeaponViewport"
        viewport.Ambient = theme.Signal
        viewport.BackgroundTransparency = 1
        viewport.LightColor = theme.Signal
        viewport.LightDirection = Vector3.new(-1, -1, -1)
        viewport.Position = UDim2.fromOffset(4, 4)
        viewport.Size = UDim2.new(1, -8, 1, -8)
        viewport.ZIndex = 9
        viewport.Parent = weaponCard
        local world = Instance.new("WorldModel")
        world.Parent = viewport
        local camera = Instance.new("Camera")
        camera.FieldOfView = 38
        camera.Parent = viewport
        viewport.CurrentCamera = camera

        record = {
            Highlight = highlight,
            Cards = cards,
            AvatarCard = avatarCard,
            Avatar = avatar,
            WeaponCard = weaponCard,
            WeaponViewport = viewport,
            WeaponWorld = world,
            WeaponCamera = camera,
            Role = nil,
            Character = nil,
            Weapon = nil,
            AvatarRevision = 0
        }
        espRecords[player] = record
        return record
    end

    local function requestAvatar(player, record)
        if avatarCache[player.UserId] then
            record.Avatar.Image = avatarCache[player.UserId]
            return
        end
        if record.AvatarLoading then return end
        record.AvatarLoading = true
        record.AvatarRevision = record.AvatarRevision + 1
        local revision = record.AvatarRevision
        task.spawn(function()
            local ok, image = pcall(
                Players.GetUserThumbnailAsync,
                Players,
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size420x420
            )
            if ok and type(image) == "string" and image ~= "" then avatarCache[player.UserId] = image end
            record.AvatarLoading = false
            if not destroyed and record.Avatar.Parent and revision == record.AvatarRevision then
                record.Avatar.Image = ok and image or ""
            end
        end)
    end

    local function renderWeapon(record, tool)
        if record.Weapon == tool then return end
        record.Weapon = tool
        clearContainer(record.WeaponWorld)
        if not tool then return end
        local clone = sanitizeToolClone(tool)
        if not clone then return end
        clone.Parent = record.WeaponWorld
        local handle = clone:FindFirstChild("Handle", true) or clone:FindFirstChildWhichIsA("BasePart", true)
        if not handle then clone:Destroy(); return end
        local origin = handle.CFrame
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then part.CFrame = origin:ToObjectSpace(part.CFrame) end
        end
        local size = handle.Size.Magnitude
        record.WeaponCamera.CFrame = CFrame.lookAt(Vector3.new(0, size * 0.35, math.max(3, size * 2.2)), Vector3.zero)
    end

    local function arrangeCards(record, showAvatar, showWeapon)
        record.AvatarCard.Visible = showAvatar
        record.WeaponCard.Visible = showWeapon
        if showAvatar and showWeapon then
            record.AvatarCard.Position = UDim2.fromScale(0.015, 0)
            record.WeaponCard.Position = UDim2.fromScale(0.515, 0)
        elseif showAvatar then
            record.AvatarCard.Position = UDim2.fromScale(0.265, 0)
        elseif showWeapon then
            record.WeaponCard.Position = UDim2.fromScale(0.265, 0)
        end
        record.Cards.Enabled = showAvatar or showWeapon
    end

    local function updateRoleESP(pulse)
        local present = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                present[player] = true
                local character, humanoid, root = characterInfo(player)
                local role = roleFromReplicatedState(player)
                roleSnapshot[player] = role
                local color = roleColors[role]
                local visible = State.Enabled and roleEnabled(role) and character and root
                    and humanoid and humanoid.Health > 0 and color ~= nil
                local record = espRecords[player]
                if visible then
                    record = record or ensureESP(player)
                    claimOverlay(player, "mm2")
                    record.Highlight.Adornee = character
                    if record.Role ~= role then
                        if record.ColorTween then pcall(function() record.ColorTween:Cancel() end) end
                        if TweenService and record.Role then
                            record.ColorTween = TweenService:Create(
                                record.Highlight,
                                TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                {FillColor = color, OutlineColor = color}
                            )
                            record.ColorTween:Play()
                        else
                            record.Highlight.FillColor = color
                            record.Highlight.OutlineColor = color
                        end
                    end
                    record.Highlight.FillTransparency = 0.64
                    record.Highlight.OutlineTransparency = 0.025 + pulse * 0.16
                    record.Highlight.Enabled = true
                    record.Character = character
                    record.Role = role
                    local cardRole = role == "Murderer" or role == "Sheriff"
                    local showAvatar = cardRole and State.AvatarCardESP
                    local showWeapon = cardRole and State.WeaponCardESP
                    record.Cards.Adornee = root
                    record.Cards.StudsOffsetWorldSpace = Vector3.new(0, getAdorneeHeight(character) * 0.5 + 1.25, 0)
                    arrangeCards(record, showAvatar, showWeapon)
                    if showAvatar then requestAvatar(player, record) end
                    if showWeapon then renderWeapon(record, findTool(player, role == "Murderer" and "Knife" or "Gun")) end
                elseif record then
                    releaseOverlay(player, "mm2")
                    record.Highlight.Enabled = false
                    record.Highlight.Adornee = nil
                    record.Cards.Enabled = false
                    record.Cards.Adornee = nil
                end
            end
        end
        for player in pairs(espRecords) do
            if not present[player] then destroyESP(player) end
        end
    end

    local function findGunDrop()
        for _, object in ipairs(Workspace:GetDescendants()) do
            if object.Name == "GunDrop" then return object end
        end
        return nil
    end

    local function updateGunDrop()
        local drop = findGunDrop()
        if not gunHighlight then
            gunHighlight = Instance.new("Highlight")
            gunHighlight.Name = "TasuHubMM2GunDrop"
            gunHighlight.FillColor = roleColors.Sheriff
            gunHighlight.OutlineColor = Color3.fromRGB(190, 225, 255)
            gunHighlight.FillTransparency = 0.55
            gunHighlight.OutlineTransparency = 0.04
            gunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            gunHighlight.Parent = overlayParent
        end
        gunHighlight.Adornee = State.Enabled and State.GunDropESP and drop or nil
        gunHighlight.Enabled = gunHighlight.Adornee ~= nil
        return drop
    end

    local function requestPickup()
        local gunDrop = findGunDrop()
        local _, _, root = characterInfo(LocalPlayer)
        if not gunDrop or not root then return false, "Gun drop is unavailable" end
        local prompt = gunDrop:FindFirstChildWhichIsA("ProximityPrompt", true)
        local firePrompt = resolveGlobal("fireproximityprompt")
        if prompt and type(firePrompt) == "function" then
            local ok = pcall(firePrompt, prompt)
            return ok, ok and "Gun pickup requested" or "Gun prompt failed"
        end
        local touch = resolveGlobal("firetouchinterest")
        local part = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildWhichIsA("BasePart", true)
        if part and type(touch) == "function" then
            local ok = pcall(function()
                touch(root, part, 0)
                touch(root, part, 1)
            end)
            return ok, ok and "Gun pickup requested" or "Gun touch failed"
        end
        return false, "Executor touch/prompt helper is unavailable"
    end

    local function findMurderer()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and roleFromReplicatedState(player) == "Murderer" then
                local _, humanoid, root = characterInfo(player)
                if humanoid and humanoid.Health > 0 and root then return player, root end
            end
        end
        return nil
    end

    local function equipTool(tool)
        if not tool then return false end
        local character, humanoid = characterInfo(LocalPlayer)
        if not character or not humanoid then return false end
        if tool.Parent ~= character then pcall(function() humanoid:EquipTool(tool) end) end
        return tool.Parent == character
    end

    local function findShootRemote(gun)
        if shotHook.ObservedRemote and shotHook.ObservedRemote.Parent then return shotHook.ObservedRemote end
        if gun then
            local direct = gun:FindFirstChild("ShootGun", true)
            if direct and direct:IsA("RemoteFunction") then shotHook.ObservedRemote = direct; return direct end
            for _, object in ipairs(gun:GetDescendants()) do
                if object:IsA("RemoteFunction") then
                    local lowered = string.lower(object.Name)
                    if string.find(lowered, "shoot", 1, true) or string.find(lowered, "fire", 1, true) then
                        shotHook.ObservedRemote = object
                        return object
                    end
                end
            end
        end
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local shared = replicatedStorage:FindFirstChild("ShootGun", true)
        if shared and shared:IsA("RemoteFunction") then shotHook.ObservedRemote = shared; return shared end
        return nil
    end

    local function setMetatableReadonly(metatableValue, readonly)
        local setter = resolveGlobal("setreadonly")
        if type(setter) == "function" then return pcall(setter, metatableValue, readonly) end
        local alternate = resolveGlobal(readonly and "make_readonly" or "make_writeable")
        if type(alternate) == "function" then return pcall(alternate, metatableValue) end
        return false
    end

    local function installShootHook()
        if shotHook.Installed then return true end
        local getRawMetatable = resolveGlobal("getrawmetatable")
        local getNamecallMethod = resolveGlobal("getnamecallmethod")
        if type(getRawMetatable) ~= "function" or type(getNamecallMethod) ~= "function" then return false end
        local ok, metatableValue = pcall(getRawMetatable, game)
        if not ok or type(metatableValue) ~= "table" or type(metatableValue.__namecall) ~= "function" then return false end
        local original = metatableValue.__namecall
        local wrapper
        wrapper = function(target, ...)
            local method = getNamecallMethod()
            local pending = shotHook.Pending
            if pending and os.clock() <= pending.ExpiresAt and method == "InvokeServer"
                and typeof(target) == "Instance" and target:IsA("RemoteFunction")
                and string.lower(target.Name) == "shootgun" then
                local arguments = table.pack(...)
                if arguments.n >= 2 then
                    arguments[2] = pending.Position
                    pending.Observed = true
                    pending.Remote = target
                    shotHook.ObservedRemote = target
                end
                return original(target, table.unpack(arguments, 1, arguments.n))
            end
            return original(target, ...)
        end
        local newClosure = resolveGlobal("newcclosure")
        if type(newClosure) == "function" then wrapper = newClosure(wrapper) end
        setMetatableReadonly(metatableValue, false)
        local assigned = pcall(function() metatableValue.__namecall = wrapper end)
        setMetatableReadonly(metatableValue, true)
        if not assigned then return false end
        shotHook.Metatable = metatableValue
        shotHook.Original = original
        shotHook.Wrapper = wrapper
        shotHook.Installed = true
        return true
    end

    local function removeShootHook()
        shotHook.Pending = nil
        local metatableValue = shotHook.Metatable
        if not shotHook.Installed or not metatableValue then return end
        if metatableValue.__namecall == shotHook.Wrapper then
            setMetatableReadonly(metatableValue, false)
            pcall(function() metatableValue.__namecall = shotHook.Original end)
            setMetatableReadonly(metatableValue, true)
        end
        shotHook.Installed = false
    end

    local function requestShot(requireVisibility)
        if shotBusy then return false, "A shot is already in progress" end
        shotBusy = true
        local function finish(ok, message)
            shotBusy = false
            return ok, message
        end
        local murderer, targetRoot = findMurderer()
        if not murderer or not targetRoot then return finish(false, "Murderer is unavailable") end
        local gun = findTool(LocalPlayer, "Gun")
        if not gun or not equipTool(gun) then return finish(false, "Gun is unavailable") end
        if requireVisibility then
            local camera = Workspace.CurrentCamera
            if not camera then return finish(false, "Camera is unavailable") end
            local screen, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
            if not onScreen or screen.Z <= 0 then return finish(false, "Murderer is outside the viewport") end
            local localCharacter = LocalPlayer.Character
            local parameters = RaycastParams.new()
            parameters.FilterType = Enum.RaycastFilterType.Exclude
            parameters.FilterDescendantsInstances = localCharacter and {localCharacter} or {}
            local result = Workspace:Raycast(camera.CFrame.Position, targetRoot.Position - camera.CFrame.Position, parameters)
            local targetCharacter = murderer.Character
            if result and (not targetCharacter or not result.Instance:IsDescendantOf(targetCharacter)) then
                return finish(false, "Murderer is behind cover")
            end
        end
        RunService.Heartbeat:Wait()
        gun = findTool(LocalPlayer, "Gun") or gun
        local predicted = targetRoot.Position + targetRoot.AssemblyLinearVelocity / 40
        local hooked = installShootHook()
        local pending = {Position = predicted, ExpiresAt = os.clock() + 0.45, Observed = false}
        if hooked then shotHook.Pending = pending end
        local activated = pcall(function() gun:Activate() end)
        local deadline = os.clock() + 0.32
        while activated and hooked and not pending.Observed and os.clock() < deadline do task.wait(0.02) end
        if shotHook.Pending == pending then shotHook.Pending = nil end
        if pending.Observed then return finish(true, "Shot fired through the game gun controller") end
        local remote = findShootRemote(gun)
        if not remote then return finish(false, "ShootGun RemoteFunction is unavailable") end
        local ok = pcall(function() remote:InvokeServer(1, predicted, "AH") end)
        return finish(ok, ok and "Shot sent through compatibility fallback" or "ShootGun invocation failed")
    end

    local function collectiblePart(object)
        if object:IsA("BasePart") then return object end
        return object:FindFirstChildWhichIsA("BasePart", true)
    end

    local function isCollectible(object)
        return collectiblePart(object) ~= nil and (
            object:FindFirstChildWhichIsA("TouchTransmitter", true) ~= nil
            or object:FindFirstChild("CoinVisual", true) ~= nil
            or object:FindFirstChild("Coin_Server", true) ~= nil
        )
    end

    local function findActiveMap(force)
        if not force and farmCache.Container and farmCache.Container.Parent and farmCache.Container:IsDescendantOf(Workspace) then
            return farmCache.Map, farmCache.Container
        end
        if not force and os.clock() - farmCache.LastMapScan < 1 then return nil, nil end
        farmCache.LastMapScan = os.clock()
        farmCache.Map, farmCache.Container = nil, nil
        for _, candidate in ipairs(Workspace:GetChildren()) do
            if candidate.Name ~= "Lobby" then
                local container = candidate:FindFirstChild("CoinContainer", true)
                if container and (candidate:FindFirstChild("Spawns", true) or #container:GetChildren() > 0) then
                    farmCache.Map, farmCache.Container = candidate, container
                    break
                end
            end
        end
        return farmCache.Map, farmCache.Container
    end

    local function discoverCollectibles()
        local result, seen = {}, {}
        local _, container = findActiveMap(false)
        if not container then return result end
        for _, object in ipairs(container:GetChildren()) do
            local part = collectiblePart(object)
            if part and not seen[part] and isCollectible(object) then
                seen[part] = true
                table.insert(result, {Object = object, Part = part})
            end
        end
        return result
    end

    local function findDescendantPath(root, names)
        local current = root
        for _, name in ipairs(names) do
            current = current and current:FindFirstChild(name)
        end
        return current
    end

    local function scanBagGui()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return end
        farmCache.BagLabel = findDescendantPath(playerGui, {
            "MainGUI", "Game", "CoinBags", "Container", "Candy", "CurrencyFrame", "Icon", "Coins"
        })
        farmCache.FullBagIndicator = nil
        if farmCache.BagLabel and (farmCache.BagLabel:IsA("TextLabel") or farmCache.BagLabel:IsA("TextButton")) then return end
        farmCache.BagLabel = nil
        for _, object in ipairs(playerGui:GetDescendants()) do
            local lowered = string.lower(object.Name)
            if not farmCache.FullBagIndicator and object:IsA("GuiObject")
                and string.find(lowered, "fullbag", 1, true) then farmCache.FullBagIndicator = object end
            if not farmCache.BagLabel and (object:IsA("TextLabel") or object:IsA("TextButton")) and (
                string.find(lowered, "coin", 1, true) or string.find(lowered, "candy", 1, true)
                or string.find(lowered, "token", 1, true) or string.find(lowered, "bag", 1, true)
            ) and string.match(object.Text or "", "%d+") then farmCache.BagLabel = object end
        end
    end

    local function readBagState()
        if (not farmCache.BagLabel or not farmCache.BagLabel.Parent)
            and os.clock() - farmCache.LastBagScan >= 1 then
            farmCache.LastBagScan = os.clock()
            scanBagGui()
        end
        if farmCache.FullBagIndicator and farmCache.FullBagIndicator.Parent and farmCache.FullBagIndicator.Visible then
            return true, nil
        end
        local label = farmCache.BagLabel
        if label and label.Parent then
            local text = label.Text or ""
            local current, capacity = string.match(text, "(%d+)%s*/%s*(%d+)")
            current, capacity = tonumber(current or string.match(text, "(%d+)")), tonumber(capacity)
            if current then return current >= (capacity or 40), current end
        end
        return false, nil
    end

    local function setFarmState(value, message)
        if farmState == value and not message then return end
        farmState = value
        emit("FarmState", message or value, true)
    end

    local function restoreFarmCharacter()
        local snapshotValue = farmSnapshot
        farmSnapshot = nil
        if not snapshotValue then return end
        local character, humanoid, root = characterInfo(LocalPlayer)
        for part, values in pairs(snapshotValue.Parts or {}) do
            if part and part.Parent then
                part.CanCollide = values.CanCollide
                part.CanTouch = values.CanTouch
                part.CanQuery = values.CanQuery
            end
        end
        if character == snapshotValue.Character and root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if snapshotValue.CFrame then character:PivotTo(snapshotValue.CFrame) end
        end
        if snapshotValue.Humanoid and snapshotValue.Humanoid.Parent then
            snapshotValue.Humanoid.AutoRotate = snapshotValue.AutoRotate
        end
    end

    local function prepareFarmCharacter()
        local character, humanoid, root = characterInfo(LocalPlayer)
        if not character or not humanoid or not root or humanoid.Health <= 0 then return nil end
        if farmSnapshot and farmSnapshot.Character ~= character then restoreFarmCharacter() end
        if not farmSnapshot then
            farmSnapshot = {
                Character = character,
                Humanoid = humanoid,
                CFrame = character:GetPivot(),
                AutoRotate = humanoid.AutoRotate,
                Parts = {}
            }
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    farmSnapshot.Parts[part] = {
                        CanCollide = part.CanCollide,
                        CanTouch = part.CanTouch,
                        CanQuery = part.CanQuery
                    }
                end
            end
        end
        humanoid.AutoRotate = false
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if not farmSnapshot.Parts[part] then
                    farmSnapshot.Parts[part] = {
                        CanCollide = part.CanCollide,
                        CanTouch = part.CanTouch,
                        CanQuery = part.CanQuery
                    }
                end
                part.CanCollide = false
                part.CanTouch = true
                part.CanQuery = false
            end
        end
        return character, humanoid, root
    end

    local function moveUndergroundTo(revision, targetPosition)
        local character, _, root = prepareFarmCharacter()
        if not root then return false end
        local target = Vector3.new(targetPosition.X, targetPosition.Y - State.UndergroundOffset, targetPosition.Z)
        if target.Y <= Workspace.FallenPartsDestroyHeight + 8 then return false end
        local start = Vector3.new(root.Position.X, target.Y, root.Position.Z)
        character:PivotTo(CFrame.new(start, start + root.CFrame.LookVector))
        local duration = math.max(0.05, (target - start).Magnitude / State.FarmSpeed)
        local started = os.clock()
        while not destroyed and revision == farmRevision and State.AutoFarm do
            local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
            local position = start:Lerp(target, alpha)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(position, position + root.CFrame.LookVector)
            if alpha >= 1 then return true end
            task.wait(1 / 30)
        end
        return false
    end

    local function touchCollectible(entry)
        local _, _, root = characterInfo(LocalPlayer)
        local touch = resolveGlobal("firetouchinterest")
        if not root or type(touch) ~= "function" or not entry.Part or not entry.Part.Parent then return false end
        local beforeParent = entry.Object.Parent
        local _, beforeCount = readBagState()
        local ok = pcall(function()
            touch(root, entry.Part, 0)
            task.wait(0.04)
            touch(root, entry.Part, 1)
        end)
        if not ok then return false end
        local deadline = os.clock() + 0.45
        repeat
            if not entry.Object.Parent or entry.Object.Parent ~= beforeParent or not entry.Part.Parent
                or entry.Part.Transparency >= 0.95 then return true end
            local _, currentCount = readBagState()
            if beforeCount and currentCount and currentCount > beforeCount then return true end
            task.wait(0.04)
        until os.clock() >= deadline
        return false
    end

    local function closestCollectible(entries, origin)
        local best, bestDistance
        for _, entry in ipairs(entries) do
            local failedUntil = farmCache.FailedUntil[entry.Object] or 0
            if entry.Part and entry.Part.Parent and failedUntil <= os.clock() then
                local distance = (entry.Part.Position - origin).Magnitude
                if not bestDistance or distance < bestDistance then best, bestDistance = entry, distance end
            end
        end
        return best
    end

    local function finishRound(revision)
        local role = roleFromReplicatedState(LocalPlayer)
        if role == "Sheriff" then
            requestShot(false)
        elseif role == "Murderer" then
            local knife = findTool(LocalPlayer, "Knife")
            equipTool(knife)
            local stab = knife and knife:FindFirstChild("Stab", true)
            local touch = resolveGlobal("firetouchinterest")
            for _, player in ipairs(Players:GetPlayers()) do
                if revision ~= farmRevision or not State.AutoFarm then break end
                if player ~= LocalPlayer then
                    local _, humanoid, targetRoot = characterInfo(player)
                    if humanoid and humanoid.Health > 0 and targetRoot and moveUndergroundTo(revision, targetRoot.Position) then
                        if stab and stab:IsA("RemoteEvent") then pcall(function() stab:FireServer() end) end
                        local _, _, localRoot = characterInfo(LocalPlayer)
                        if type(touch) == "function" and localRoot then
                            pcall(function() touch(localRoot, targetRoot, 0); touch(localRoot, targetRoot, 1) end)
                        end
                    end
                end
            end
        end
    end

    local function runFarm(revision)
        local failures = 0
        while not destroyed and revision == farmRevision and State.AutoFarm do
            local character, humanoid, root = characterInfo(LocalPlayer)
            if not character or not humanoid or not root or humanoid.Health <= 0 then
                setFarmState("WaitForRound", "Waiting for character")
                task.wait(0.5)
            else
                local full = readBagState()
                if full then
                    setFarmState("BagFull", "Bag is full")
                    setFarmState("FinishRound", "Finishing round")
                    finishRound(revision)
                    task.wait(1)
                else
                    setFarmState("DiscoverMap", "Finding collectibles")
                    local entries = discoverCollectibles()
                    if #entries == 0 then
                        setFarmState("LobbyIdle", "Waiting in lobby")
                        findActiveMap(true)
                        task.wait(0.75)
                    else
                        setFarmState("Collect", "Collecting coins and candy")
                        local target = closestCollectible(entries, root.Position)
                        if target and moveUndergroundTo(revision, target.Part.Position) then
                            local collected = false
                            for _ = 1, 2 do
                                if touchCollectible(target) then collected = true; break end
                            end
                            failures = collected and 0 or failures + 1
                            if not collected then farmCache.FailedUntil[target.Object] = os.clock() + 3 end
                            if failures >= 5 then
                                failures = 0
                                farmCache.Map, farmCache.Container = nil, nil
                                setFarmState("DiscoverMap", "Refreshing collectible cache")
                                emit("Error", "Several collectibles were skipped after touch verification failed", false)
                                task.wait(0.5)
                            end
                        elseif not target then
                            setFarmState("Collect", "Waiting for the next collectible")
                            task.wait(0.2)
                        else
                            failures = failures + 1
                        end
                    end
                end
            end
        end
        restoreFarmCharacter()
        if farmState ~= "Stopped" then setFarmState("Stopped") end
    end

    local function startFarm()
        if destroyed then return false, "Service is destroyed" end
        if type(resolveGlobal("firetouchinterest")) ~= "function" then
            return false, "Executor firetouchinterest capability is unavailable"
        end
        State.AutoFarm = true
        farmRevision = farmRevision + 1
        farmCache.Map, farmCache.Container = nil, nil
        farmCache.LastMapScan = 0
        table.clear(farmCache.FailedUntil)
        local revision = farmRevision
        setFarmState("WaitForRound", "Farm started")
        task.spawn(runFarm, revision)
        emit("StateChanged", "Auto Farm enabled", true)
        return true, "Auto Farm enabled"
    end

    local function stopFarm(message)
        State.AutoFarm = false
        farmRevision = farmRevision + 1
        farmCache.Map, farmCache.Container = nil, nil
        table.clear(farmCache.FailedUntil)
        restoreFarmCharacter()
        setFarmState("Stopped", message or "Farm stopped")
        return true, message or "Farm stopped"
    end

    local function setState(key, value)
        if State[key] == nil then return false, "Unknown MM2 state" end
        if key == "FarmSpeed" then
            State[key] = math.clamp(tonumber(value) or State[key], 20, 90)
        elseif key == "UndergroundOffset" then
            State[key] = math.clamp(tonumber(value) or State[key], 5, 30)
        else
            State[key] = value == true
        end
        if key == "AutoFarm" then
            if State.AutoFarm then return startFarm() end
            return stopFarm()
        end
        if key == "Enabled" and not State.Enabled then
            for player, record in pairs(espRecords) do
                releaseOverlay(player, "mm2")
                record.Highlight.Enabled = false
                record.Cards.Enabled = false
            end
            if gunHighlight then gunHighlight.Enabled = false; gunHighlight.Adornee = nil end
        end
        emit("StateChanged", key .. (State[key] == true and " enabled" or State[key] == false and " disabled" or " updated"), true)
        return true
    end

    local function instancePath(instance)
        if not instance then return "Unavailable" end
        local ok, path = pcall(function() return instance:GetFullName() end)
        return ok and path or instance.Name
    end

    local function inspectRuntime()
        local gun = findTool(LocalPlayer, "Gun")
        local map, container = findActiveMap(true)
        farmCache.LastBagScan = 0
        readBagState()
        local report = {
            RoundPhase = container and "Active" or "LobbyOrPreparing",
            LocalRole = roleFromReplicatedState(LocalPlayer),
            Gun = instancePath(gun),
            ShootRemote = instancePath(findShootRemote(gun)),
            ShootHookAvailable = installShootHook(),
            Map = instancePath(map),
            CoinContainer = instancePath(container),
            CollectibleCount = #discoverCollectibles(),
            BagLabel = instancePath(farmCache.BagLabel),
            BagText = farmCache.BagLabel and farmCache.BagLabel.Text or "Unavailable",
            DecompiledShootReferences = {}
        }
        local decompileFunction = resolveGlobal("decompile")
        if type(decompileFunction) == "function" then
            local attempts = 0
            local scopes = {}
            if gun then table.insert(scopes, gun) end
            if LocalPlayer.Character then table.insert(scopes, LocalPlayer.Character) end
            local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
            if playerScripts then table.insert(scopes, playerScripts) end
            for _, scope in ipairs(scopes) do
                for _, object in ipairs(scope:GetDescendants()) do
                    if attempts >= 12 or #report.DecompiledShootReferences >= 4 then break end
                    if object:IsA("LocalScript") or object:IsA("ModuleScript") then
                        attempts = attempts + 1
                        local ok, source = pcall(decompileFunction, object)
                        if ok and type(source) == "string" then
                            local startIndex = string.find(string.lower(source), "shootgun", 1, true)
                            if startIndex then
                                local from = math.max(1, startIndex - 180)
                                local snippet = string.sub(source, from, math.min(#source, startIndex + 360))
                                snippet = string.gsub(snippet, "%s+", " ")
                                table.insert(report.DecompiledShootReferences, instancePath(object) .. ": " .. snippet)
                            end
                        end
                    end
                end
                if attempts >= 12 or #report.DecompiledShootReferences >= 4 then break end
            end
        end
        return report
    end

    connect(RunService.Heartbeat, function(deltaTime)
        heartbeatClock = heartbeatClock + deltaTime
        local pulse = (math.sin(os.clock() * math.pi * 0.8) + 1) * 0.5
        updateRoleESP(pulse)
        if heartbeatClock < 0.15 then return end
        heartbeatClock = 0
        local drop = updateGunDrop()
        if State.Enabled and State.AutoPickup and drop then requestPickup() end
        if State.Enabled and State.AutoFire and os.clock() - lastShotAt >= 0.75 then
            lastShotAt = os.clock()
            local ok = requestShot(true)
            if ok then emit("Shot", "Auto Fire shot sent", true) end
        end
    end)
    connect(Players.PlayerRemoving, destroyESP)
    antiIdleConnection = connect(LocalPlayer.Idled, function()
        if not State.AutoFarm then return end
        local ok, virtualUser = pcall(function() return game:GetService("VirtualUser") end)
        if ok and virtualUser then
            pcall(function()
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.zero)
            end)
        end
    end)

    local controller
    local function destroy()
        if destroyed then return end
        destroyed = true
        stopFarm("Service destroyed")
        removeShootHook()
        disconnectAll(connections)
        for player in pairs(espRecords) do destroyESP(player) end
        if gunHighlight then gunHighlight:Destroy(); gunHighlight = nil end
        table.clear(subscribers)
    end

    controller = table.freeze({
        GetState = snapshot,
        SetState = setState,
        Subscribe = function(callback)
            if type(callback) ~= "function" or destroyed then return nil end
            subscribers[callback] = true
            pcall(callback, snapshot(), "Snapshot", farmState, true)
            return function() subscribers[callback] = nil end
        end,
        GetRoleSnapshot = function()
            local result = {}
            for player, role in pairs(roleSnapshot) do result[player.UserId] = role end
            return result
        end,
        PickupGun = function()
            local ok, message = requestPickup()
            emit(ok and "Action" or "Error", message, ok)
            return ok, message
        end,
        ShootNow = function()
            local ok, message = requestShot(false)
            if ok then lastShotAt = os.clock() end
            emit(ok and "Action" or "Error", message, ok)
            return ok, message
        end,
        InspectRuntime = inspectRuntime,
        StartFarm = startFarm,
        StopFarm = stopFarm,
        Destroy = destroy
    })
    if State.AutoFarm then startFarm() end
    return controller
end

return table.freeze(Module)
