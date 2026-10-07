local PlayerServiceModule = {Version = 1}

function PlayerServiceModule.Create(context)
    assert(type(context) == "table", "player service context is required")
    local Players = assert(context.Players, "Players service is required")
    local LocalPlayer = assert(context.LocalPlayer, "LocalPlayer is required")
    local Workspace = assert(context.Workspace, "Workspace is required")
    local RunService = assert(context.RunService, "RunService is required")
    local PathfindingService = assert(context.PathfindingService, "PathfindingService is required")

    local destroyed = false
    local connections, subscribers = {}, {}
    local walkRevision, walkTargetId, walkStatus = 0, nil, "Idle"
    local routeFolder = nil
    local actionRevision, actionBusy = 0, false

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        if context.TrackConnection then context.TrackConnection(connection) end
        return connection
    end

    local function getCharacter(player)
        player = player or LocalPlayer
        local character = player and player.Character
        if not character then return nil, nil, nil end
        return character, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    end

    local function getAlive(player)
        local character, humanoid, root = getCharacter(player)
        return character and humanoid and root and humanoid.Health > 0, character, humanoid, root
    end

    local function playerById(userId)
        userId = tonumber(userId)
        if not userId then return nil end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == userId then return player end
        end
        return nil
    end

    local function teammateState(player)
        if player.Team and LocalPlayer.Team then return player.Team == LocalPlayer.Team and "Teammate" or "Other" end
        if player.TeamColor and LocalPlayer.TeamColor then return player.TeamColor == LocalPlayer.TeamColor and "Teammate" or "Other" end
        return "Other"
    end

    local function notify(reason)
        for callback in pairs(subscribers) do
            task.spawn(function() pcall(callback, reason or "Update") end)
        end
    end

    local function clearRoute()
        if routeFolder then routeFolder:Destroy() end
        routeFolder = nil
    end

    local function showRoute(waypoints, revision)
        if destroyed or revision ~= walkRevision then return end
        local folder = Instance.new("Folder")
        folder.Name = "TasuHubLivePath"
        local nodes = {}
        for index, waypoint in ipairs(waypoints) do
            local node = Instance.new("Part")
            node.Name = "Node" .. tostring(index)
            node.Anchored = true
            node.CanCollide = false
            node.CanQuery = false
            node.CanTouch = false
            node.CastShadow = false
            node.Size = Vector3.new(0.12, 0.12, 0.12)
            node.Transparency = 1
            node.CFrame = CFrame.new(waypoint.Position + Vector3.new(0, 0.18, 0))
            node.Parent = folder
            local attachment = Instance.new("Attachment")
            attachment.Parent = node
            nodes[index] = attachment
        end
        for index = 1, #nodes - 1 do
            local beam = Instance.new("Beam")
            beam.Name = "PathSegment"
            beam.Attachment0 = nodes[index]
            beam.Attachment1 = nodes[index + 1]
            beam.Color = ColorSequence.new(context.RouteColor or Color3.new(1, 1, 1))
            beam.FaceCamera = true
            beam.LightEmission = 0.65
            beam.Transparency = NumberSequence.new(0.12)
            beam.Width0 = 0.09
            beam.Width1 = 0.09
            beam.Parent = nodes[index].Parent
        end
        folder.Parent = Workspace
        local previous = routeFolder
        routeFolder = folder
        if previous then previous:Destroy() end
    end

    local function stopWalk(reason)
        walkRevision = walkRevision + 1
        local wasWalking = walkTargetId ~= nil
        walkTargetId = nil
        walkStatus = reason or "Stopped"
        clearRoute()
        local _, humanoid, root = getCharacter(LocalPlayer)
        if humanoid then
            humanoid:Move(Vector3.zero, false)
            if root then humanoid:MoveTo(root.Position) end
        end
        if wasWalking then notify("Walk") end
        return wasWalking
    end

    local function waitForMove(humanoid, targetRoot, targetOrigin, revision)
        local completed, reached = false, false
        local connection = humanoid.MoveToFinished:Connect(function(value)
            reached, completed = value == true, true
        end)
        local started = os.clock()
        while not completed and not destroyed and revision == walkRevision do
            if not targetRoot.Parent or (targetRoot.Position - targetOrigin).Magnitude >= 6 or os.clock() - started >= 4.5 then break end
            RunService.Heartbeat:Wait()
        end
        connection:Disconnect()
        return reached, targetRoot.Parent and (targetRoot.Position - targetOrigin).Magnitude >= 6
    end

    local function startWalk(userId)
        if actionBusy then return false, "Another player action is active" end
        local target = playerById(userId)
        if not target or target == LocalPlayer then return false, "Player is unavailable" end
        if walkTargetId == target.UserId then
            stopWalk("Stopped")
            return true, "Walk stopped"
        end
        stopWalk("Replaced")
        walkTargetId = target.UserId
        walkStatus = "Calculating route"
        walkRevision = walkRevision + 1
        local revision = walkRevision
        notify("Walk")
        task.spawn(function()
            while not destroyed and revision == walkRevision and walkTargetId == target.UserId do
                local localAlive, character, humanoid, root = getAlive(LocalPlayer)
                local targetAlive, _, _, targetRoot = getAlive(target)
                if not localAlive or not targetAlive then
                    stopWalk("Character unavailable")
                    break
                end
                if (targetRoot.Position - root.Position).Magnitude <= 4.5 then
                    stopWalk("Arrived")
                    break
                end
                local extents = character:GetExtentsSize()
                local path = PathfindingService:CreatePath({
                    AgentRadius = math.max(2, math.ceil(math.max(extents.X, extents.Z) * 0.5)),
                    AgentHeight = math.max(5, math.ceil(extents.Y)),
                    AgentCanJump = true,
                    AgentCanClimb = true,
                    WaypointSpacing = 3
                })
                local computed = pcall(function() path:ComputeAsync(root.Position, targetRoot.Position) end)
                if not computed or path.Status ~= Enum.PathStatus.Success then
                    walkStatus = "No route"
                    notify("Walk")
                    task.wait(0.45)
                    continue
                end
                local waypoints = path:GetWaypoints()
                if #waypoints < 2 then
                    stopWalk("No route")
                    break
                end
                showRoute(waypoints, revision)
                walkStatus = "Walking"
                notify("Walk")
                local repath = false
                local currentWaypointIndex = 2
                local blockedConnection = path.Blocked:Connect(function(blockedIndex)
                    if blockedIndex >= currentWaypointIndex then repath = true end
                end)
                for index = 2, #waypoints do
                    if destroyed or revision ~= walkRevision or repath then break end
                    currentWaypointIndex = index
                    targetAlive, _, _, targetRoot = getAlive(target)
                    if not targetAlive then break end
                    local targetOrigin = targetRoot.Position
                    local waypoint = waypoints[index]
                    if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
                    humanoid:MoveTo(waypoint.Position)
                    local reached, targetMoved = waitForMove(humanoid, targetRoot, targetOrigin, revision)
                    if targetMoved or not reached then repath = true break end
                end
                blockedConnection:Disconnect()
                if revision ~= walkRevision then break end
                task.wait(repath and 0.08 or 0.18)
            end
        end)
        return true, "Walk started"
    end

    local function teleport(userId)
        if actionBusy then return false, "Another player action is active" end
        local target = playerById(userId)
        local targetAlive, _, _, targetRoot = getAlive(target)
        local localAlive, _, _, root = getAlive(LocalPlayer)
        if not targetAlive or not localAlive then return false, "Character is unavailable" end
        stopWalk("Teleport")
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        notify("Teleport")
        return true, "Teleported"
    end

    local function view(userId)
        if actionBusy then return false, "Another player action is active" end
        local target = playerById(userId)
        local targetAlive, _, targetHumanoid = getAlive(target)
        local camera = Workspace.CurrentCamera
        if not camera then return false, "Camera is unavailable" end
        if targetAlive and camera.CameraSubject ~= targetHumanoid then
            camera.CameraSubject = targetHumanoid
            notify("View")
            return true, "Viewing " .. target.DisplayName
        end
        local _, localHumanoid = getCharacter(LocalPlayer)
        if localHumanoid then camera.CameraSubject = localHumanoid end
        notify("View")
        return true, "View restored"
    end

    local function fling(userId)
        local target = playerById(userId)
        local targetAlive, targetCharacter, targetHumanoid, targetRoot = getAlive(target)
        if actionBusy then return false, "Another player action is active" end
        if not targetAlive or target == LocalPlayer or targetRoot.Anchored then return false, "Target cannot be flung" end
        local localAlive, _, localHumanoid, localRoot = getAlive(LocalPlayer)
        if not localAlive then return false, "Local character is unavailable" end
        stopWalk("Fling")
        actionRevision = actionRevision + 1
        local revision = actionRevision
        actionBusy = true
        local exclusiveToken = nil
        if context.BeforeExclusiveAction then
            local prepared, token = pcall(context.BeforeExclusiveAction, "Fling")
            if prepared then exclusiveToken = token end
        end
        task.spawn(function()
            local camera = Workspace.CurrentCamera
            local safeCFrame = localRoot.CFrame
            local safeVelocity = localRoot.AssemblyLinearVelocity
            local safeAngular = localRoot.AssemblyAngularVelocity
            local safeAutoRotate = localHumanoid.AutoRotate
            local cameraType = camera and camera.CameraType
            local cameraSubject = camera and camera.CameraSubject
            local cameraCFrame = camera and camera.CFrame
            local cameraLock
            local function restore()
                if cameraLock then cameraLock:Disconnect() end
                if localRoot and localRoot.Parent then
                    localRoot.CFrame = safeCFrame
                    localRoot.AssemblyLinearVelocity = safeVelocity
                    localRoot.AssemblyAngularVelocity = safeAngular
                end
                if localHumanoid and localHumanoid.Parent then
                    localHumanoid.AutoRotate = safeAutoRotate
                    localHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                if camera and camera.Parent then
                    camera.CameraType = cameraType or Enum.CameraType.Custom
                    camera.CameraSubject = cameraSubject
                    if cameraCFrame then camera.CFrame = cameraCFrame end
                end
                actionBusy = false
                if context.AfterExclusiveAction then pcall(context.AfterExclusiveAction, "Fling", exclusiveToken) end
                notify("Fling")
            end
            local ok = pcall(function()
                if camera and cameraCFrame then
                    camera.CameraType = Enum.CameraType.Scriptable
                    cameraLock = RunService.RenderStepped:Connect(function()
                        if camera and camera.Parent then camera.CFrame = cameraCFrame end
                    end)
                end
                if context.ResolveGlobal then
                    local setSimulationRadius = context.ResolveGlobal("setsimulationradius")
                    if type(setSimulationRadius) == "function" then pcall(setSimulationRadius, math.huge, math.huge) end
                    local setHiddenProperty = context.ResolveGlobal("sethiddenproperty")
                    if type(setHiddenProperty) == "function" then pcall(setHiddenProperty, LocalPlayer, "SimulationRadius", math.huge) end
                end
                local power = math.clamp(tonumber(context.GetFlingPower and context.GetFlingPower()) or 50000, 1000, 100000)
                localHumanoid.AutoRotate = false
                for index = 1, 20 do
                    if destroyed or revision ~= actionRevision or not localRoot.Parent or not targetCharacter.Parent or not targetRoot.Parent or targetHumanoid.Health <= 0 then break end
                    local phase = (index % 4) * math.pi * 0.5
                    local offset = Vector3.new(math.cos(phase) * 0.75, (index % 2 == 0) and 0.35 or -0.15, math.sin(phase) * 0.75)
                    localRoot.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
                    localRoot.AssemblyAngularVelocity = Vector3.new(power, power, power)
                    localRoot.AssemblyLinearVelocity = Vector3.new(-offset.X, 0.22, -offset.Z).Unit * power
                    RunService.Heartbeat:Wait()
                    localRoot.CFrame = safeCFrame
                    localRoot.AssemblyLinearVelocity = safeVelocity
                    localRoot.AssemblyAngularVelocity = Vector3.zero
                    RunService.RenderStepped:Wait()
                end
            end)
            restore()
            if not ok then walkStatus = "Fling failed" end
        end)
        return true, "Fling pulse started"
    end

    local function snapshot(query, sortMode)
        query = string.lower(tostring(query or ""))
        sortMode = tostring(sortMode or "Nearest")
        local _, _, localRoot = getCharacter(LocalPlayer)
        local camera = Workspace.CurrentCamera
        local result = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local matches = query == "" or string.find(string.lower(player.Name), query, 1, true) or string.find(string.lower(player.DisplayName), query, 1, true)
                if matches then
                    local alive, _, humanoid, root = getAlive(player)
                    local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
                    local ratio = alive and math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1) or 0
                    table.insert(result, {
                        UserId = player.UserId,
                        Username = player.Name,
                        DisplayName = player.DisplayName,
                        Avatar = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150",
                        Relation = teammateState(player),
                        Distance = distance,
                        HealthRatio = ratio,
                        Alive = alive == true,
                        Viewing = camera and humanoid and camera.CameraSubject == humanoid or false,
                        Walking = walkTargetId == player.UserId,
                        WalkStatus = walkTargetId == player.UserId and walkStatus or nil,
                        Busy = actionBusy
                    })
                end
            end
        end
        table.sort(result, function(first, second)
            if sortMode == "Name A-Z" then return string.lower(first.DisplayName) < string.lower(second.DisplayName) end
            if sortMode == "Health High-Low" then return first.HealthRatio > second.HealthRatio end
            if sortMode == "Health Low-High" then return first.HealthRatio < second.HealthRatio end
            return first.Distance < second.Distance
        end)
        return result
    end

    local elapsed = 0
    connect(RunService.Heartbeat, function(deltaTime)
        elapsed = elapsed + deltaTime
        if elapsed < 0.2 then return end
        elapsed = 0
        notify("Sample")
    end)
    connect(Players.PlayerAdded, function() notify("Players") end)
    connect(Players.PlayerRemoving, function(player)
        if walkTargetId == player.UserId then stopWalk("Player left") end
        local camera = Workspace.CurrentCamera
        if camera and player.Character and camera.CameraSubject and camera.CameraSubject:IsDescendantOf(player.Character) then
            local _, localHumanoid = getCharacter(LocalPlayer)
            if localHumanoid then camera.CameraSubject = localHumanoid end
        end
        notify("Players")
    end)

    local controller = {}
    controller.GetSnapshot = snapshot
    controller.Subscribe = function(callback)
        assert(type(callback) == "function", "player subscriber must be a function")
        subscribers[callback] = true
        local subscription = {}
        function subscription:Disconnect() subscribers[callback] = nil end
        task.defer(callback, "Initial")
        return subscription
    end
    controller.View = view
    controller.Teleport = teleport
    controller.Walk = startWalk
    controller.StopWalk = stopWalk
    controller.Fling = fling
    controller.Destroy = function()
        if destroyed then return end
        destroyed = true
        actionRevision = actionRevision + 1
        stopWalk("Destroyed")
        table.clear(subscribers)
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        local camera = Workspace.CurrentCamera
        local _, humanoid = getCharacter(LocalPlayer)
        if camera and humanoid and camera.CameraSubject and camera.CameraSubject.Parent == nil then camera.CameraSubject = humanoid end
    end
    return table.freeze(controller)
end

return table.freeze(PlayerServiceModule)
