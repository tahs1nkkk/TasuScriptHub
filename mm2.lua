local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
if game.PlaceId ~= 142823291 then
    warn("TasuHub MM2: bu modul yalnizca Murder Mystery 2 icinde calisir")
    return
end

local env = getgenv and getgenv() or _G
if env.TasuHubMM2 and type(env.TasuHubMM2.Unload) == "function" then
    pcall(env.TasuHubMM2.Unload)
end

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
    label.Font = Enum.Font.BuilderSansBold
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
        if object:IsA("RemoteEvent") and (string.find(string.lower(object.Name), "shoot", 1, true) or string.find(string.lower(object.Name), "fire", 1, true)) then
            pcall(function() object:FireServer(targetRoot.Position) end)
            return true
        end
    end
    return false
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TasuHubMM2"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = (type(env.gethui) == "function" and env.gethui()) or CoreGui

local Window = Instance.new("CanvasGroup")
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.BackgroundColor3 = Color3.fromRGB(20, 29, 40)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.Size = UDim2.fromOffset(390, 250)
Window.Visible = false
Window.GroupTransparency = 1
Window.Parent = ScreenGui
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(14, 7)
Title.Size = UDim2.new(1, -58, 0, 36)
Title.Font = Enum.Font.BuilderSansBold
Title.Text = "Murder Mystery 2"
Title.TextColor3 = Color3.fromRGB(244, 248, 255)
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Window

local Close = Instance.new("TextButton")
Close.AutoButtonColor = false
Close.BackgroundColor3 = Color3.fromRGB(34, 48, 66)
Close.Position = UDim2.new(1, -43, 0, 8)
Close.Size = UDim2.fromOffset(34, 32)
Close.Font = Enum.Font.BuilderSansBold
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(244, 248, 255)
Close.TextSize = 21
Close.Parent = Window
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Body = Instance.new("Frame")
Body.BackgroundTransparency = 1
Body.Position = UDim2.fromOffset(12, 52)
Body.Size = UDim2.new(1, -24, 1, -64)
Body.Parent = Window
local Grid = Instance.new("UIGridLayout")
Grid.CellPadding = UDim2.fromOffset(8, 8)
Grid.CellSize = UDim2.new(0.5, -4, 0, 40)
Grid.Parent = Body

local function addToggle(labelText, key)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundColor3 = Color3.fromRGB(28, 40, 55)
    button.Font = Enum.Font.BuilderSansBold
    button.TextColor3 = Color3.fromRGB(244, 248, 255)
    button.TextSize = 15
    button.Parent = Body
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
    local function render()
        button.Text = labelText .. "  " .. (State[key] and "ON" or "OFF")
        button.BackgroundColor3 = State[key] and Color3.fromRGB(42, 93, 145) or Color3.fromRGB(28, 40, 55)
    end
    button.Activated:Connect(function()
        State[key] = not State[key]
        render()
    end)
    render()
end

local function addAction(labelText, callback)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundColor3 = Color3.fromRGB(36, 52, 72)
    button.Font = Enum.Font.BuilderSansBold
    button.Text = labelText
    button.TextColor3 = Color3.fromRGB(244, 248, 255)
    button.TextSize = 15
    button.Parent = Body
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
    button.Activated:Connect(callback)
end

addToggle("Enabled", "Enabled")
addToggle("Role ESP", "PlayerESP")
addToggle("GunDrop ESP", "GunDropESP")
addToggle("Auto Pickup", "AutoPickup")
addToggle("Auto Fire", "AutoFire")
addAction("Pickup Now", requestPickup)
addAction("Fire Now", requestShot)

local dragging, dragStart, windowStart
connect(Title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, windowStart = true, input.Position, Window.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Window.Position = windowStart + UDim2.fromOffset(delta.X, delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local function open()
    Window.Visible = true
    Window.GroupTransparency = 1
    TweenService:Create(Window, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {GroupTransparency = 0}):Play()
end
local function close()
    TweenService:Create(Window, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {GroupTransparency = 1}):Play()
    task.delay(0.23, function()
        if Window.Parent and Window.GroupTransparency > 0.98 then Window.Visible = false end
    end)
end
Close.Activated:Connect(close)

local clock = 0
connect(RunService.Heartbeat, function(deltaTime)
    clock = clock + deltaTime
    if clock < 0.15 then return end
    clock = 0
    local gunDrop = updateGunDrop()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local record = ensurePlayerESP(player)
            local character, humanoid, root = characterInfo(player)
            local role = replicatedRole(player)
            local color = role == "Murderer" and Color3.fromRGB(244, 72, 83) or role == "Sheriff" and Color3.fromRGB(65, 145, 255) or nil
            local visible = State.Enabled and State.PlayerESP and color ~= nil and humanoid and humanoid.Health > 0 and root ~= nil
            record.Highlight.Adornee = visible and character or nil
            record.Highlight.FillColor = color or Color3.new(1, 1, 1)
            record.Highlight.OutlineColor = color or Color3.new(1, 1, 1)
            record.Highlight.Enabled = visible
            record.Billboard.Adornee = visible and root or nil
            record.Billboard.Enabled = visible
            record.Label.Text = player.DisplayName
            record.Label.TextColor3 = color or Color3.new(1, 1, 1)
        end
    end
    if State.Enabled and State.AutoPickup and gunDrop then requestPickup() end
    if State.Enabled and State.AutoFire then requestShot() end
end)
connect(Players.PlayerRemoving, destroyPlayerESP)

local function unload()
    if unloaded then return end
    unloaded = true
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for player in pairs(playerESP) do destroyPlayerESP(player) end
    if gunHighlight then gunHighlight:Destroy() end
    ScreenGui:Destroy()
    if env.TasuHubMM2 and env.TasuHubMM2.Unload == unload then env.TasuHubMM2 = nil end
end

env.TasuHubMM2 = {
    State = State,
    PlaceId = 142823291,
    Open = open,
    Close = close,
    Toggle = function()
        if Window.Visible then close() else open() end
    end,
    Unload = unload
}

-- The live card belongs to the MM2 catalog module, not to the main TasuHub
-- loader. Ask the tiny localhost launcher to start the private Node bridge,
-- then fetch telemetry after the bridge becomes healthy.
local function getHttpRequest()
    local request = env.request or env.http_request
    if not request and type(env.syn) == "table" then request = env.syn.request end
    return request
end

local function requestTelemetry(request)
    local ok, response = pcall(request, {
        Url = "http://127.0.0.1:8787/client/mm2-telemetry.lua",
        Method = "GET",
        Headers = { ["Cache-Control"] = "no-cache" }
    })
    local statusCode = ok and type(response) == "table" and tonumber(response.StatusCode or response.Status)
    local source = ok and type(response) == "table" and (response.Body or response.body)
    if statusCode and statusCode >= 200 and statusCode < 300 and type(source) == "string" and source ~= "" then
        return source
    end
    return nil
end

local function startLocalMM2LiveCard()
    local request = getHttpRequest()
    if type(request) ~= "function" then
        warn("TasuHub Live Card: executor localhost HTTP request desteklemiyor")
        return
    end

    local source = requestTelemetry(request)
    if not source then
        pcall(request, {
            Url = "http://127.0.0.1:8786/start",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = "{}"
        })
        for _ = 1, 24 do
            task.wait(0.25)
            source = requestTelemetry(request)
            if source then break end
        end
    end

    if not source then
        warn("TasuHub Live Card: yerel baslaticiya ulasilamadi. install-launcher.ps1 dosyasini bir kez calistirin.")
        return
    end
    local chunk, compileError = loadstring(source, "TasuHubMM2LiveCard")
    if not chunk then
        warn("TasuHub Live Card derlenemedi:", compileError)
        return
    end
    local started, runtimeError = pcall(chunk)
    if not started then warn("TasuHub Live Card baslatilamadi:", runtimeError) end
end

task.spawn(startLocalMM2LiveCard)
