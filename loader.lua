local Defaults = {
    Interface = {
        Title = "TasuHub",
        ThemeName = "Rework Dark",
        Accent = Color3.fromRGB(242, 243, 245),
        AccentSoft = Color3.fromRGB(37, 39, 45),
        Background = Color3.fromRGB(18, 19, 22),
        Surface = Color3.fromRGB(37, 39, 45),
        Surface2 = Color3.fromRGB(18, 19, 22),
        Hover = Color3.fromRGB(242, 243, 245),
        ControlOff = Color3.fromRGB(37, 39, 45),
        Track = Color3.fromRGB(37, 39, 45),
        Text = Color3.fromRGB(242, 243, 245),
        Muted = Color3.fromRGB(242, 243, 245),
        Section = Color3.fromRGB(242, 243, 245)
    },
    Aim = {
        Enabled = false,
        HoldRightMouse = true,
        Activation = "Right Mouse",
        Rage = false,
        Method = "Camera",
        TargetPart = "Head",
        TeamCheck = false,
        WallCheck = true,
        AliveCheck = true,
        Prediction = true,
        PredictionTime = 0.12,
        Smoothing = 0.18,
        FOV = 180,
        MaxDistance = 2000,
        ShowFOV = true
    },
    Visuals = {
        Enabled = false,
        Boxes = false,
        BoxFilled = false,
        Names = true,
        Distance = false,
        Health = false,
        HeadDot = false,
        Tracers = false,
        Chams = true,
        Skeleton = false,
        Offscreen = false,
        TeamColors = false,
        MaxDistance = 2500,
        Thickness = 1
    },
    Movement = {
        Speed = false,
        SpeedMethod = "WalkSpeed",
        SpeedValue = 32,
        Jump = false,
        JumpValue = 80,
        InfiniteJump = false,
        BunnyHop = false,
        Fly = false,
        FlyMethod = "Velocity",
        FlySpeed = 70,
        Noclip = false,
        ClickTP = false,
        AntiFling = false,
        Godmode = false,
        Gravity = false,
        GravityValue = 196.2,
        Orbit = false,
        OrbitMode = "Circle",
        OrbitRadius = 8,
        OrbitSpeed = 2,
        OrbitHeight = 5,
        OrbitOffset = 2,
        Fling = false,
        FlingMode = "Walk Fling",
        FlingPower = 50000,
        FlingFlySpeed = 90
    },
    World = {
        Fullbright = false,
        NoFog = false,
        CameraFOV = 70,
        ThirdPerson = false,
        Freecam = false,
        FreecamSpeed = 1.5,
        LightingMode = "Default",
        GlowIntensity = 1.2,
        NeonIntensity = 2.2,
        NeonSize = 48,
        NeonThreshold = 0.42,
        ManualRed = 255,
        ManualGreen = 255,
        ManualBlue = 255,
        ManualBrightness = 0,
        ManualContrast = 0,
        ManualSaturation = 0,
        FlatTextures = false,
        RGB = {
            ESP = {Enabled = false, Speed = 0.18, Saturation = 0.9, Brightness = 1},
            Aim = {Enabled = false, Speed = 0.18, Saturation = 0.9, Brightness = 1},
            World = {Enabled = false, Speed = 0.18, Saturation = 0.9, Brightness = 1}
        }
    },
    Players = {
        Sort = "Nearest"
    },
    Stats = {
        Visible = false,
        FPS = true,
        Ping = true,
        Players = false,
        Memory = false
    },
    Keybinds = {},
    Catalog = {},
    Waypoints = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local StatsService = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return
end

local env = getgenv and getgenv() or _G
if env.TasuHub and type(env.TasuHub.Unload) == "function" then
    pcall(env.TasuHub.Unload)
elseif env.TasuAnticheatTest and type(env.TasuAnticheatTest.Unload) == "function" then
    pcall(env.TasuAnticheatTest.Unload)
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[deepCopy(key)] = deepCopy(item)
    end
    return result
end

local State = deepCopy(Defaults)
local connections = {}
local featureConnections = {}
local instances = {}
local originalCollision = setmetatable({}, {__mode = "k"})
local humanoidDefaults = setmetatable({}, {__mode = "k"})
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}
local flatObjectDefaults = setmetatable({}, {__mode = "k"})
local originalGravity = Workspace.Gravity
local originalCameraFOV = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70
local originalCameraMinZoom = LocalPlayer.CameraMinZoomDistance
local originalCameraMaxZoom = LocalPlayer.CameraMaxZoomDistance
local originalCameraMode = LocalPlayer.CameraMode
Defaults.World.CameraFOV = originalCameraFOV
State.World.CameraFOV = originalCameraFOV
local selectedPlayer = nil
local selectedWaypoint = 1
local unloaded = false
local unload

local function trackConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function trackFeature(name, connection)
    featureConnections[name] = featureConnections[name] or {}
    table.insert(featureConnections[name], connection)
    return connection
end

local function trackInstance(instance)
    table.insert(instances, instance)
    return instance
end

local function getCharacter(player)
    player = player or LocalPlayer
    local character = player.Character
    if not character then
        return nil, nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and not humanoidDefaults[humanoid] then
        humanoidDefaults[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            UseJumpPower = humanoid.UseJumpPower,
            PlatformStand = humanoid.PlatformStand,
            MaxHealth = humanoid.MaxHealth,
            BreakJointsOnDeath = humanoid.BreakJointsOnDeath,
            DeadEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead)
        }
    end
    local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    return character, humanoid, root
end

local function getAlive(player)
    local character, humanoid, root = getCharacter(player)
    return character and humanoid and root and humanoid.Health > 0, character, humanoid, root
end

local function getTeamToken(player)
    if player.Team then
        return "team:" .. tostring(player.Team)
    end
    for _, attributeName in ipairs({"Team", "TeamId", "TeamName"}) do
        local value = player:GetAttribute(attributeName)
        if value ~= nil then return attributeName .. ":" .. tostring(value) end
        if player.Character then
            value = player.Character:GetAttribute(attributeName)
            if value ~= nil then return attributeName .. ":" .. tostring(value) end
        end
    end
    return nil
end

local function areTeammates(first, second)
    local firstToken = getTeamToken(first)
    local secondToken = getTeamToken(second)
    return firstToken ~= nil and firstToken == secondToken
end

local function getRGBColor(scope, offset)
    local rgb = type(State.World.RGB) == "table" and State.World.RGB or Defaults.World.RGB
    local settings = type(rgb[scope]) == "table" and rgb[scope] or Defaults.World.RGB[scope]
    return Color3.fromHSV(((os.clock() + (offset or 0)) * settings.Speed) % 1, settings.Saturation, settings.Brightness)
end

local function getPlayerVisualColor(player)
    if State.World.RGB.ESP.Enabled then
        return getRGBColor("ESP", (player.UserId % 17) * 0.035)
    end
    if State.Visuals.TeamColors then
        if player.Team then return player.Team.TeamColor.Color end
        if player.TeamColor then return player.TeamColor.Color end
        local attributeColor = player:GetAttribute("TeamColor")
        if typeof(attributeColor) == "Color3" then
            return attributeColor
        end
        if player.Character then
            attributeColor = player.Character:GetAttribute("TeamColor")
            if typeof(attributeColor) == "Color3" then return attributeColor end
        end
    end
    return State.Interface.Accent
end

local function colorToHex(color)
    return string.format("#%02X%02X%02X", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

local function getMousePosition()
    local location = UserInputService:GetMouseLocation()
    local topLeftInset = GuiService:GetGuiInset()
    return Vector2.new(location.X - topLeftInset.X, location.Y - topLeftInset.Y)
end

local function resolveGlobal(name)
    local ok, value = pcall(function()
        return env[name] or _G[name]
    end)
    if ok then
        return value
    end
    return nil
end

local capabilities = {
    Drawing = type(Drawing) == "table" and type(Drawing.new) == "function",
    GetHui = type(resolveGlobal("gethui")) == "function",
    MouseMove = type(resolveGlobal("mousemoverel")) == "function",
    Files = type(resolveGlobal("writefile")) == "function" and type(resolveGlobal("readfile")) == "function",
    Folders = type(resolveGlobal("makefolder")) == "function" and type(resolveGlobal("isfolder")) == "function",
    Http = type(resolveGlobal("request")) == "function" or type(resolveGlobal("http_request")) == "function" or type(syn) == "table" and type(syn.request) == "function" or type(game.HttpGet) == "function",
    CustomAsset = type(resolveGlobal("getcustomasset")) == "function" or type(resolveGlobal("getsynasset")) == "function",
    LoadString = type(loadstring) == "function"
}

local function getRequest()
    return resolveGlobal("request") or resolveGlobal("http_request") or type(syn) == "table" and syn.request
end

local function getCustomAsset(path)
    local fn = resolveGlobal("getcustomasset") or resolveGlobal("getsynasset")
    if fn then
        local ok, value = pcall(fn, path)
        if ok then
            return value
        end
    end
    return nil
end

local function loadRemoteAsset(url, path)
    if not capabilities.Files or not capabilities.CustomAsset then
        return nil
    end
    local request = getRequest()
    local ok, response
    if request then
        ok, response = pcall(request, {Url = url, Method = "GET"})
    else
        ok, response = pcall(function()
            return {Body = game:HttpGet(url)}
        end)
    end
    if not ok or type(response) ~= "table" then
        return nil
    end
    local body = response.Body or response.body
    if type(body) ~= "string" or body == "" then
        return nil
    end
    local writefile = resolveGlobal("writefile")
    if type(writefile) ~= "function" then
        return nil
    end
    local saved = pcall(writefile, path, body)
    if not saved then
        return nil
    end
    return getCustomAsset(path)
end

local function ensureFolder(path)
    if not capabilities.Folders then
        return false
    end
    local isfolder = resolveGlobal("isfolder")
    local makefolder = resolveGlobal("makefolder")
    local current = ""
    for part in string.gmatch(path, "[^/]+") do
        current = current == "" and part or current .. "/" .. part
        if not isfolder(current) then
            local ok = pcall(makefolder, current)
            if not ok then
                return false
            end
        end
    end
    return true
end

local guiParent
local gethui = resolveGlobal("gethui")
if type(gethui) == "function" then
    local ok, value = pcall(gethui)
    if ok and value then
        guiParent = value
    end
end
guiParent = guiParent or CoreGui

local Theme = State.Interface
local ReworkPalette = {
    Base = Color3.fromRGB(18, 19, 22),
    Layer = Color3.fromRGB(37, 39, 45),
    Signal = Color3.fromRGB(242, 243, 245)
}
local UI = {
    Version = "0.1",
    Ready = false,
    LegacyUIEnabled = false,
    -- 9 category buttons: 148 brand + 495 categories + 6 gap + 48 search + 6 gap + 70 version + 12 padding.
    TopBarBaseWidth = 785,
    -- ShadowSpread / 2 is roughly the visible edge in pixels. Offset moves it right/down.
    ShadowOffsetX = 3,
    ShadowOffsetY = 0,
    ShadowSpread = 15,
    ShadowTransparency = 0.8,
    RefreshControls = function() end,
    RefreshNavigation = function() end,
    RefreshOrbitPlayers = function() end,
    RefreshVisualPreview = function() end,
    CloseGlobalSearch = function(_force) end,
    CloseActiveDropdown = function() end,
    ScheduleSearchHoverClose = function() end,
    OpenConfigSaveModal = function() end,
    AddStaticCard = function(_page, _title) return game end,
    ClearAntiFlingState = function() end,
    FlingTarget = function(_player, _protectLocal) return false end,
    StartFlingLoop = function() end,
    GetTouchingPlayers = function(_character) return {} end,
    FlingCooldowns = {},
    AimDiscardedCharacters = {},
    GlobalSearchPointerInside = false,
    SearchReturnVisible = false,
    SearchReturnCategory = "Home",
    SearchMode = false,
    GlobalSearchOpen = false,
    ActiveHexInput = game,
    UnloadIconUrl = "",
    ActionIconUrls = {
        Brand = "https://i.imgur.com/1UBgp0L.png", Search = "", Close = "",
        WaypointSave = "", WaypointTeleport = "", WaypointDelete = "",
        PlayerFling = "", PlayerView = "", PlayerStop = "", PlayerTeleport = "",
        CatalogNew = "", CatalogRun = "", CatalogView = "", CatalogEdit = "", CatalogDelete = "",
        Unload = "", FreecamTeleport = ""
    },
    ActionIconBindings = {},
    ActionIconAssets = {},
    IconLibrary = {},
    DesignTokens = {
        Palette = ReworkPalette,
        Canvas = ReworkPalette.Base,
        Surface = ReworkPalette.Layer,
        ControlIdle = ReworkPalette.Layer,
        BorderSubtle = ReworkPalette.Signal,
        TextPrimary = ReworkPalette.Signal,
        TextSecondary = ReworkPalette.Signal,
        TextOnAccent = ReworkPalette.Base,
        Accent = ReworkPalette.Signal,
        MotionStatus = 0.42,
        MotionProgress = 0.85,
        MotionLoader = 0.5,
        MotionLoaderExit = 0.9,
        MotionLoaderPop = 0.26,
        MotionLoaderSettle = 0.08
    },
    AudioLibrary = {
        FadeIn = {Id = "rbxassetid://1127797047", Volume = 0.12, PlaybackSpeed = 1.18},
        FadeOut = {Id = "rbxassetid://1127797047", Volume = 0.14, PlaybackSpeed = 0.82},
        PopIn = {Id = "rbxassetid://140323850218372", Volume = 0.18, PlaybackSpeed = 1.1}
    },
    Flags = {},
    Controls = {},
    AccordionOpeners = {},
    ThemeBindings = {},
    GradientBindings = {},
    CategoryIconUrls = {
        Home = "", Catalog = "", Players = "", Visuals = "", Aim = "",
        Movement = "", World = "", Misc = "", Configs = ""
    },
    CategoryIconBackgrounds = {
        Home = "AccentSoft", Catalog = "AccentSoft", Players = "AccentSoft", Visuals = "AccentSoft", Aim = "AccentSoft",
        Movement = "AccentSoft", World = "AccentSoft", Misc = "AccentSoft", Configs = "AccentSoft"
    },
    Fonts = {
        Option = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Description = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Heading = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        HeadingHeavy = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),
        Home = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        HomeRegular = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    },
    Themes = {
        ["Rework Dark"] = {
            Accent = ReworkPalette.Signal, AccentSoft = ReworkPalette.Layer,
            Background = ReworkPalette.Base, Surface = ReworkPalette.Layer,
            Surface2 = ReworkPalette.Base, Hover = ReworkPalette.Signal, ControlOff = ReworkPalette.Layer,
            Track = ReworkPalette.Layer, Text = ReworkPalette.Signal, Muted = ReworkPalette.Signal,
            Section = ReworkPalette.Signal
        }
    }
}

UI.PlaySound = function(name)
    local preset = UI.AudioLibrary[name]
    if type(preset) ~= "table" or type(preset.Id) ~= "string" or preset.Id == "" then
        return false
    end
    local sound = trackInstance(Instance.new("Sound"))
    sound.Name = "TasuHub" .. tostring(name)
    sound.SoundId = preset.Id
    sound.Volume = preset.Volume or 0.15
    sound.PlaybackSpeed = preset.PlaybackSpeed or 1
    sound.Parent = SoundService
    local played = pcall(function()
        SoundService:PlayLocalSound(sound)
    end)
    if not played then
        played = pcall(function() sound:Play() end)
    end
    task.delay(4, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
    return played
end

UI.BindTheme = function(object, property, token)
    table.insert(UI.ThemeBindings, {Object = object, Property = property, Token = token})
    if property == "BackgroundColor3" and object:GetAttribute("ThemeBaseTransparency") == nil then
        object:SetAttribute("ThemeBaseTransparency", object.BackgroundTransparency)
    end
    if Theme[token] ~= nil then
        object[property] = Theme[token]
    end
    if property == "BackgroundColor3" then
        local baseTransparency = object:GetAttribute("ThemeBaseTransparency")
        if type(baseTransparency) == "number" then
            object.BackgroundTransparency = Theme.ThemeName == "Rework Dark" and math.min(baseTransparency, 0.025) or baseTransparency
        end
    end
    return object
end

UI.RefreshTheme = function()
    for index = #UI.ThemeBindings, 1, -1 do
        local binding = UI.ThemeBindings[index]
        if not binding.Object or not binding.Object.Parent then
            table.remove(UI.ThemeBindings, index)
        elseif Theme[binding.Token] ~= nil then
            pcall(function()
                binding.Object[binding.Property] = Theme[binding.Token]
                if binding.Property == "BackgroundColor3" then
                    local baseTransparency = binding.Object:GetAttribute("ThemeBaseTransparency")
                    if type(baseTransparency) == "number" then
                        binding.Object.BackgroundTransparency = Theme.ThemeName == "Rework Dark" and math.min(baseTransparency, 0.025) or baseTransparency
                    end
                end
            end)
        end
    end
    for index = #UI.GradientBindings, 1, -1 do
        local binding = UI.GradientBindings[index]
        if not binding.Object or not binding.Object.Parent then
            table.remove(UI.GradientBindings, index)
        else
            binding.Object.Color = ColorSequence.new(Theme[binding.Top], Theme[binding.Bottom])
        end
    end
    if type(UI.RefreshControls) == "function" then
        UI.RefreshControls()
    end
    if type(UI.RefreshNavigation) == "function" then
        UI.RefreshNavigation()
    end
end

UI.ApplyTheme = function(name, preserveAccent)
    local resolvedName = UI.Themes[name] and name or "Rework Dark"
    local preset = UI.Themes[resolvedName]
    local accent = Theme.Accent
    for key, value in pairs(preset) do
        Theme[key] = value
    end
    if preserveAccent and typeof(accent) == "Color3" then
        Theme.Accent = accent
    end
    Theme.ThemeName = resolvedName
    UI.RefreshTheme()
end

UI.Register = function(flag, control)
    UI.Flags[flag] = control
    UI.Controls[flag] = control
    control.Flag = flag
    if type(control.Destroy) ~= "function" then
        control.Destroy = function(self)
            local instance = self.Instance or self.Holder or self.Row
            if instance then
                pcall(function() instance:Destroy() end)
            end
            UI.Flags[flag] = nil
            UI.Controls[flag] = nil
        end
    end
    return control
end

UI.ControlFlag = function(card, label)
    local categoryName = card:GetAttribute("CategoryName") or card.Parent.Name
    local cardName = card:GetAttribute("CardName") or card.Name
    return categoryName .. "/" .. cardName .. "/" .. label
end

UI.SetFlag = function(flag, value)
    local control = UI.Controls[flag]
    if not control or type(control.Set) ~= "function" then
        return false
    end
    control:Set(value)
    return true
end

UI.GetFlag = function(flag)
    local control = UI.Controls[flag]
    if not control or type(control.Get) ~= "function" then
        return nil
    end
    return control:Get()
end

local ScreenGui = trackInstance(Instance.new("ScreenGui"))
ScreenGui.Name = "TasuHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
local guiParented = pcall(function()
    ScreenGui.Parent = guiParent
end)
if not guiParented then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local InterfaceRoot = Instance.new("Frame")
InterfaceRoot.Name = "InterfaceRoot"
InterfaceRoot.BackgroundTransparency = 1
InterfaceRoot.BorderSizePixel = 0
InterfaceRoot.Size = UDim2.fromScale(1, 1)
InterfaceRoot.Position = UDim2.fromScale(0, 0)
InterfaceRoot.Parent = ScreenGui

local LegacyUIRoot = Instance.new("Frame")
LegacyUIRoot.Name = "LegacyUIRoot"
LegacyUIRoot.BackgroundTransparency = 1
LegacyUIRoot.BorderSizePixel = 0
LegacyUIRoot.Size = UDim2.fromScale(1, 1)
LegacyUIRoot.Position = UDim2.fromScale(0, 0)
LegacyUIRoot.Visible = false
LegacyUIRoot.Parent = InterfaceRoot
UI.LegacyUIRoot = LegacyUIRoot

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = object
    return corner
end

UI.IconLibrary.TasuHub = function(parent, options)
    options = type(options) == "table" and options or {}
    local tokens = UI.DesignTokens
    local color = options.Color or tokens.TextPrimary
    local zIndex = options.ZIndex or 1
    local canvas = Instance.new("CanvasGroup")
    canvas.Name = "TasuHubIcon"
    canvas.BackgroundTransparency = 1
    canvas.BorderSizePixel = 0
    canvas.Size = options.Size or UDim2.fromOffset(80, 80)
    canvas.ZIndex = zIndex
    canvas.Parent = parent

    local function iconPart(name, position, size, rotation)
        local part = Instance.new("Frame")
        part.Name = name
        part.AnchorPoint = Vector2.new(0.5, 0.5)
        part.BackgroundColor3 = color
        part.BorderSizePixel = 0
        part.Position = position
        part.Rotation = rotation or 0
        part.Size = size
        part.ZIndex = zIndex
        part.Parent = canvas
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.22, 0)
        corner.Parent = part
        return part
    end

    iconPart("Crown", UDim2.fromScale(0.5, 0.22), UDim2.fromScale(0.76, 0.16))
    iconPart("Stem", UDim2.fromScale(0.5, 0.51), UDim2.fromScale(0.16, 0.52))
    iconPart("LeftFoot", UDim2.fromScale(0.405, 0.76), UDim2.fromScale(0.25, 0.14), -32)
    iconPart("RightFoot", UDim2.fromScale(0.595, 0.76), UDim2.fromScale(0.25, 0.14), 32)
    return canvas
end

UI.CreateIcon = function(parent, name, options)
    local factory = UI.IconLibrary[name]
    if type(factory) ~= "function" then
        return nil
    end
    return factory(parent, options)
end

local function addShadow(object, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.BorderSizePixel = 0
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    local baseTransparency = transparency or 0.72
    shadow.ImageTransparency = baseTransparency
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = math.max(0, object.ZIndex - 1)
    if object.ClipsDescendants and object.Parent then
        shadow.AnchorPoint = object.AnchorPoint
        local function sync()
            shadow.Position = object.Position + UDim2.fromOffset(UI.ShadowOffsetX, UI.ShadowOffsetY)
            shadow.Size = object.Size + UDim2.fromOffset(UI.ShadowSpread, UI.ShadowSpread)
            shadow.Visible = object.Visible and object:GetAttribute("ShadowSuppressed") ~= true
            if object:IsA("CanvasGroup") then
                shadow.ImageTransparency = baseTransparency + (1 - baseTransparency) * object.GroupTransparency
            end
        end
        shadow.Parent = object.Parent
        sync()
        trackConnection(object:GetPropertyChangedSignal("Position"):Connect(sync))
        trackConnection(object:GetPropertyChangedSignal("Size"):Connect(sync))
        trackConnection(object:GetPropertyChangedSignal("Visible"):Connect(sync))
        trackConnection(object:GetAttributeChangedSignal("ShadowSuppressed"):Connect(sync))
        if object:IsA("CanvasGroup") then
            trackConnection(object:GetPropertyChangedSignal("GroupTransparency"):Connect(sync))
        end
    else
        shadow.Position = UDim2.new(0.5, UI.ShadowOffsetX, 0.5, UI.ShadowOffsetY)
        shadow.Size = UDim2.new(1, UI.ShadowSpread, 1, UI.ShadowSpread)
        shadow.Parent = object
    end
    return shadow
end

UI.SetActionIcon = function(name, url)
    if UI.ActionIconUrls[name] == nil then return false end
    UI.ActionIconUrls[name] = tostring(url or "")
    local resolved = UI.ActionIconUrls[name]
    UI.ActionIconAssets[name] = resolved ~= "" and (loadRemoteAsset(resolved, "TasuHub/Icons/" .. name .. ".png") or resolved) or ""
    for _, binding in ipairs(UI.ActionIconBindings[name] or {}) do
        if binding.Image and binding.Image.Parent then
            binding.Image.Image = UI.ActionIconAssets[name]
            binding.Image.Visible = resolved ~= ""
            if binding.Button and binding.DefaultText ~= "" then
                binding.Button.Text = resolved ~= "" and (binding.RemoteText or "") or binding.DefaultText
            end
            for _, fallback in ipairs(binding.Fallbacks) do
                if fallback and fallback.Parent then fallback.Visible = resolved == "" end
            end
        end
    end
    return true
end

UI.BindActionIcon = function(buttonObject, name, fallbacks, remoteText)
    UI.ActionIconBindings[name] = UI.ActionIconBindings[name] or {}
    local image = Instance.new("ImageLabel")
    image.Name = "Remote" .. name .. "Icon"
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.BackgroundTransparency = 1
    image.Position = UDim2.fromScale(0.5, 0.5)
    image.Size = UDim2.fromOffset(22, 22)
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = buttonObject.ZIndex + 3
    image.Parent = buttonObject
    local binding = {Image = image, Fallbacks = fallbacks or {}, Button = buttonObject, DefaultText = buttonObject.Text, RemoteText = remoteText}
    table.insert(UI.ActionIconBindings[name], binding)
    UI.SetActionIcon(name, UI.ActionIconUrls[name])
    return image
end

for iconName, iconUrl in pairs(UI.ActionIconUrls) do
    if iconUrl ~= "" then UI.SetActionIcon(iconName, iconUrl) end
end

local function stroke(object, color, thickness, transparency)
    local item = Instance.new("UIStroke")
    item.Color = color or Theme.Accent
    item.Thickness = thickness or 1
    item.Transparency = transparency or 0
    item.Parent = object
    if color == nil then
        UI.BindTheme(item, "Color", "Accent")
    end
    return item
end

local function gradient(object, topColor, bottomColor, rotation)
    local item = Instance.new("UIGradient")
    local topToken = type(topColor) == "string" and topColor or nil
    local bottomToken = type(bottomColor) == "string" and bottomColor or nil
    item.Color = ColorSequence.new(topToken and Theme[topToken] or topColor or Theme.Surface, bottomToken and Theme[bottomToken] or bottomColor or Theme.Surface2)
    item.Rotation = rotation or 90
    item.Parent = object
    if topToken and bottomToken then
        table.insert(UI.GradientBindings, {Object = item, Top = topToken, Bottom = bottomToken})
    end
    return item
end

local function animate(object, properties, duration, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.16, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local Toast = Instance.new("TextLabel")
Toast.AnchorPoint = Vector2.new(0.5, 0)
Toast.BackgroundColor3 = Color3.fromRGB(30, 42, 56)
Toast.BackgroundTransparency = 1
Toast.Position = UDim2.new(0.5, 0, 0, 18)
Toast.Size = UDim2.fromOffset(260, 30)
Toast.TextColor3 = Color3.fromRGB(255, 255, 255)
Toast.TextSize = 15
Toast.FontFace = UI.Fonts.Heading
Toast.TextTransparency = 1
Toast.Visible = false
Toast.ZIndex = 40
Toast.Parent = LegacyUIRoot
round(Toast, 9)
local toastRevision = 0
local function showToast(message)
    if not UI.LegacyUIEnabled then
        warn("[TasuHub] " .. tostring(message))
        return
    end
    toastRevision = toastRevision + 1
    local revision = toastRevision
    Toast.Text = message
    Toast.Visible = true
    Toast.BackgroundTransparency = 1
    Toast.TextTransparency = 1
    animate(Toast, {BackgroundTransparency = 0.06, TextTransparency = 0}, 0.16)
    task.delay(2.1, function()
        if revision == toastRevision and Toast.Parent then
            animate(Toast, {BackgroundTransparency = 1, TextTransparency = 1}, 0.18)
            task.delay(0.18, function()
                if revision == toastRevision and Toast.Parent then Toast.Visible = false end
            end)
        end
    end)
end

UI.Notify = function(options)
    if type(options) == "string" then
        showToast(options)
        return
    end
    options = type(options) == "table" and options or {}
    local title = tostring(options.Title or "TasuHub")
    local content = tostring(options.Content or "")
    showToast(content ~= "" and title .. "  •  " .. content or title)
end

local function textLabel(parent, text, size, position, textSize, color, alignment)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = color or Theme.Text
    label.TextSize = textSize or 17
    label.FontFace = UI.Fonts.Option
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.Size = size or UDim2.new(1, 0, 0, 24)
    label.Position = position or UDim2.new()
    label.Parent = parent
    if color == nil or color == Theme.Text then
        UI.BindTheme(label, "TextColor3", "Text")
    elseif color == Theme.Muted then
        UI.BindTheme(label, "TextColor3", "Muted")
    elseif color == Theme.Accent then
        UI.BindTheme(label, "TextColor3", "Accent")
    end
    return label
end

local function button(parent, text, size, position)
    local item = Instance.new("TextButton")
    item.AutoButtonColor = false
    item.BackgroundColor3 = Theme.Surface2
    item.BackgroundTransparency = 0.08
    item.Text = text
    item.TextColor3 = Theme.Text
    item.TextSize = 16
    item.FontFace = UI.Fonts.Heading
    item.ClipsDescendants = true
    item.Size = size or UDim2.new(0, 100, 0, 28)
    item.Position = position or UDim2.new()
    round(item, 8)
    gradient(item, "Surface", "Surface2")
    local hoverGlow = Instance.new("Frame")
    hoverGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    hoverGlow.BackgroundColor3 = Theme.Accent
    hoverGlow.BackgroundTransparency = 0.94
    hoverGlow.BorderSizePixel = 0
    hoverGlow.Position = UDim2.fromScale(0.5, 0.5)
    hoverGlow.Size = UDim2.fromOffset(0, 0)
    hoverGlow.ZIndex = 0
    hoverGlow.Parent = item
    round(hoverGlow, 50)
    local function restingColor()
        return item:GetAttribute("Selected") and Theme.AccentSoft or Theme.Surface2
    end
    item.MouseEnter:Connect(function()
        item.FontFace = UI.Fonts.HeadingHeavy
        animate(item, {BackgroundColor3 = item:GetAttribute("Selected") and Theme.AccentSoft or Theme.Hover}, 0.14)
        animate(hoverGlow, {Size = UDim2.new(1.25, 0, 1.25, 0), BackgroundTransparency = 0.88}, 0.16)
    end)
    item.MouseLeave:Connect(function()
        item.FontFace = UI.Fonts.Heading
        animate(item, {BackgroundColor3 = restingColor()}, 0.16)
        animate(hoverGlow, {Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.94}, 0.16)
    end)
    item.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            animate(hoverGlow, {Size = UDim2.new(0.86, 0, 0.86, 0), BackgroundTransparency = 0.82}, 0.08, Enum.EasingStyle.Quad)
        end
    end)
    item.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            animate(hoverGlow, {Size = UDim2.new(1.25, 0, 1.25, 0), BackgroundTransparency = 0.88}, 0.1, Enum.EasingStyle.Quad)
        end
    end)
    item.Parent = parent
    UI.BindTheme(item, "BackgroundColor3", "Surface2")
    UI.BindTheme(item, "TextColor3", "Text")
    return item
end

local function getCanvasSize()
    local size = InterfaceRoot.AbsoluteSize
    if size.X > 0 and size.Y > 0 then
        return size
    end
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1920, 1080)
end

local function getLocalPosition(frame)
    local rootPosition = InterfaceRoot.AbsolutePosition
    local framePosition = frame.AbsolutePosition
    return Vector2.new(framePosition.X - rootPosition.X, framePosition.Y - rootPosition.Y)
end

local function clampLocalPosition(frame, desired)
    local canvas = getCanvasSize()
    local size = frame.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then
        size = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
    end
    return Vector2.new(
        math.clamp(desired.X, 0, math.max(0, canvas.X - size.X)),
        math.clamp(desired.Y, 0, math.max(0, canvas.Y - size.Y))
    )
end

local function keepGuiOnScreen(frame)
    local current = getLocalPosition(frame)
    local clamped = clampLocalPosition(frame, current)
    if (clamped - current).Magnitude > 0.5 then
        frame.Position = UDim2.fromOffset(clamped.X, clamped.Y)
    end
end

local function makeDraggable(frame, handle, clickCallback)
    local dragging = false
    local dragMoved = false
    local dragStart
    local frameStart
    local function beginDrag(input)
        if not UI.Ready or input.UserInputType ~= Enum.UserInputType.MouseButton1 or not frame.Visible or dragging then
            return
        end
        dragging = true
        dragMoved = false
        dragStart = getMousePosition()
        frameStart = getLocalPosition(frame)
    end
    handle.Active = true
    trackConnection(handle.InputBegan:Connect(beginDrag))
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement or not dragStart or not frameStart then
            return
        end
        local delta = getMousePosition() - dragStart
        if delta.Magnitude < 4 then
            return
        end
        dragMoved = true
        local nextPosition = clampLocalPosition(frame, frameStart + delta)
        frame.Position = UDim2.fromOffset(nextPosition.X, nextPosition.Y)
    end))
    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local clicked = dragging and not dragMoved
            dragging = false
            dragMoved = false
            dragStart = nil
            frameStart = nil
            if clicked and clickCallback then
                pcall(clickCallback)
            end
        end
    end))
end

do
    local tokens = UI.DesignTokens
    UI.Loader = Instance.new("Frame")
    UI.Loader.Name = "Loader"
    UI.Loader.BackgroundColor3 = tokens.Canvas
    UI.Loader.BackgroundTransparency = 1
    UI.Loader.BorderSizePixel = 0
    UI.Loader.ClipsDescendants = false
    UI.Loader.Position = UDim2.fromScale(0, 0)
    UI.Loader.Size = UDim2.fromScale(1, 1)
    UI.Loader.ZIndex = 1000
    UI.Loader.Parent = InterfaceRoot

    UI.LoaderTopFade = Instance.new("Frame")
    UI.LoaderTopFade.Name = "TopEdgeGlow"
    UI.LoaderTopFade.AnchorPoint = Vector2.new(0, 1)
    UI.LoaderTopFade.BackgroundColor3 = tokens.Canvas
    UI.LoaderTopFade.BorderSizePixel = 0
    UI.LoaderTopFade.Position = UDim2.fromOffset(0, 0)
    UI.LoaderTopFade.Size = UDim2.new(1, 0, 0, 200)
    UI.LoaderTopFade.ZIndex = 1000
    UI.LoaderTopFade.Parent = UI.Loader
    local loaderTopGradient = Instance.new("UIGradient")
    loaderTopGradient.Color = ColorSequence.new(tokens.Canvas)
    loaderTopGradient.Rotation = 90
    loaderTopGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    loaderTopGradient.Parent = UI.LoaderTopFade

    UI.LoaderContent = Instance.new("CanvasGroup")
    UI.LoaderContent.Name = "LoaderContent"
    UI.LoaderContent.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.LoaderContent.BackgroundTransparency = 1
    UI.LoaderContent.BorderSizePixel = 0
    UI.LoaderContent.GroupTransparency = 0
    UI.LoaderContent.Position = UDim2.fromScale(0.5, 0.5)
    UI.LoaderContent.Size = UDim2.fromScale(1, 1)
    UI.LoaderContent.ZIndex = 1001
    UI.LoaderContent.Parent = UI.Loader

    UI.LoaderIcon = UI.CreateIcon(UI.LoaderContent, "TasuHub", {
        Size = UDim2.fromOffset(152, 152),
        Color = tokens.TextPrimary,
        ZIndex = 1002
    })
    UI.LoaderIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.LoaderIcon.GroupTransparency = 1
    UI.LoaderIcon.Position = UDim2.fromScale(0.5, 0.42)
    UI.LoaderIcon.Visible = false
    UI.LoaderIconScale = Instance.new("UIScale")
    UI.LoaderIconScale.Scale = 0.82
    UI.LoaderIconScale.Parent = UI.LoaderIcon

    UI.LoaderBar = Instance.new("CanvasGroup")
    UI.LoaderBar.Name = "ProgressTrack"
    UI.LoaderBar.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.LoaderBar.BackgroundColor3 = tokens.ControlIdle
    UI.LoaderBar.BorderSizePixel = 0
    UI.LoaderBar.ClipsDescendants = true
    UI.LoaderBar.GroupTransparency = 1
    UI.LoaderBar.Position = UDim2.fromScale(0.5, 0.76)
    UI.LoaderBar.Size = UDim2.fromOffset(400, 22)
    UI.LoaderBar.ZIndex = 1002
    UI.LoaderBar.Parent = UI.LoaderContent
    UI.LoaderBar.Visible = false
    UI.LoaderBarScale = Instance.new("UIScale")
    UI.LoaderBarScale.Scale = 0.82
    UI.LoaderBarScale.Parent = UI.LoaderBar
    round(UI.LoaderBar, 999)
    local loaderStroke = Instance.new("UIStroke")
    loaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    loaderStroke.Color = tokens.BorderSubtle
    loaderStroke.Thickness = 1
    loaderStroke.Transparency = 0.78
    loaderStroke.Parent = UI.LoaderBar

    UI.LoaderFill = Instance.new("Frame")
    UI.LoaderFill.Name = "ProgressFill"
    UI.LoaderFill.BackgroundColor3 = tokens.Accent
    UI.LoaderFill.BorderSizePixel = 0
    UI.LoaderFill.ClipsDescendants = true
    UI.LoaderFill.Size = UDim2.fromScale(0, 1)
    UI.LoaderFill.ZIndex = 1003
    UI.LoaderFill.Parent = UI.LoaderBar
    round(UI.LoaderFill, 999)

    UI.LoaderPercent = Instance.new("TextLabel")
    UI.LoaderPercent.Name = "ProgressPercent"
    UI.LoaderPercent.BackgroundTransparency = 1
    UI.LoaderPercent.Size = UDim2.fromScale(1, 1)
    UI.LoaderPercent.FontFace = UI.Fonts.HeadingHeavy
    UI.LoaderPercent.Text = "0%"
    UI.LoaderPercent.TextColor3 = tokens.TextPrimary
    UI.LoaderPercent.TextSize = 13
    UI.LoaderPercent.ZIndex = 1004
    UI.LoaderPercent.Parent = UI.LoaderBar

    UI.LoaderPercentNegative = UI.LoaderPercent:Clone()
    UI.LoaderPercentNegative.Name = "ProgressPercentNegative"
    UI.LoaderPercentNegative.Size = UDim2.fromOffset(400, 22)
    UI.LoaderPercentNegative.TextColor3 = tokens.TextOnAccent
    UI.LoaderPercentNegative.ZIndex = 1005
    UI.LoaderPercentNegative.Parent = UI.LoaderFill

    UI.LoaderStatus = Instance.new("TextLabel")
    UI.LoaderStatus.Name = "LoaderStatus"
    UI.LoaderStatus.AnchorPoint = Vector2.new(0.5, 0)
    UI.LoaderStatus.BackgroundTransparency = 1
    UI.LoaderStatus.FontFace = UI.Fonts.Description
    UI.LoaderStatus.Position = UDim2.new(0.5, 0, 0.76, 27)
    UI.LoaderStatus.Size = UDim2.fromOffset(400, 47)
    UI.LoaderStatus.Text = "Arayüz hazırlanıyor"
    UI.LoaderStatus.TextColor3 = tokens.TextSecondary
    UI.LoaderStatus.TextSize = 15
    UI.LoaderStatus.TextTransparency = 1
    UI.LoaderStatus.TextWrapped = true
    UI.LoaderStatus.TextXAlignment = Enum.TextXAlignment.Center
    UI.LoaderStatus.TextYAlignment = Enum.TextYAlignment.Top
    UI.LoaderStatus.ZIndex = 1002
    UI.LoaderStatus.Parent = UI.LoaderContent
    UI.LoaderStatus.Visible = false
    UI.LoaderStatusScale = Instance.new("UIScale")
    UI.LoaderStatusScale.Scale = 0.82
    UI.LoaderStatusScale.Parent = UI.LoaderStatus

    UI.LoaderVersion = Instance.new("TextLabel")
    UI.LoaderVersion.Name = "LoaderVersion"
    UI.LoaderVersion.AnchorPoint = Vector2.new(1, 1)
    UI.LoaderVersion.BackgroundTransparency = 1
    UI.LoaderVersion.Position = UDim2.new(1, -22, 1, -18)
    UI.LoaderVersion.Size = UDim2.fromOffset(180, 21)
    UI.LoaderVersion.FontFace = UI.Fonts.Description
    UI.LoaderVersion.Text = "TasuHub  ·  v" .. UI.Version
    UI.LoaderVersion.TextColor3 = tokens.TextSecondary
    UI.LoaderVersion.TextSize = 13
    UI.LoaderVersion.TextTransparency = 1
    UI.LoaderVersion.TextXAlignment = Enum.TextXAlignment.Right
    UI.LoaderVersion.ZIndex = 1001
    UI.LoaderVersion.Parent = UI.Loader

    UI.SetLoading = function(progress, status)
        progress = math.clamp(tonumber(progress) or 0, 0, 1)
        local percentage = tostring(math.floor(progress * 100 + 0.5)) .. "%"
        UI.LoaderPercent.Text = percentage
        UI.LoaderPercentNegative.Text = percentage
        animate(UI.LoaderFill, {Size = UDim2.fromScale(progress, 1)}, tokens.MotionProgress, Enum.EasingStyle.Quint)
        if status and status ~= UI.LoaderStatus.Text then
            UI.LoaderStatus.Text = status
            UI.LoaderStatus.TextTransparency = 1
            animate(UI.LoaderStatus, {TextTransparency = 0.42}, tokens.MotionStatus, Enum.EasingStyle.Quint)
        end
    end

    local function revealLoaderItem(item, itemScale, revealProperties)
        UI.PlaySound("PopIn")
        item.Visible = true
        itemScale.Scale = 0.82
        animate(item, revealProperties, tokens.MotionLoaderPop, Enum.EasingStyle.Quint)
        animate(itemScale, {Scale = 1.035}, tokens.MotionLoaderPop, Enum.EasingStyle.Quint).Completed:Wait()
        animate(itemScale, {Scale = 1}, tokens.MotionLoaderSettle, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Wait()
    end

    UI.PlaySound("FadeIn")
    animate(UI.LoaderVersion, {TextTransparency = 0.58}, tokens.MotionLoader, Enum.EasingStyle.Quint)
    local loaderEntryTween = animate(UI.Loader, {BackgroundTransparency = 0}, tokens.MotionLoader, Enum.EasingStyle.Quint)
    loaderEntryTween.Completed:Wait()
    revealLoaderItem(UI.LoaderIcon, UI.LoaderIconScale, {GroupTransparency = 0})
    revealLoaderItem(UI.LoaderBar, UI.LoaderBarScale, {GroupTransparency = 0})
    revealLoaderItem(UI.LoaderStatus, UI.LoaderStatusScale, {TextTransparency = 0.42})
end

UI.SetLoading(0.06, "Arayüz hazırlanıyor")

local TopBar = Instance.new("Frame")
TopBar.Name = "CategoryBar"
TopBar.BackgroundColor3 = Theme.Background
TopBar.BackgroundTransparency = 0.1
TopBar.Size = UDim2.fromOffset(UI.TopBarBaseWidth, 58)
TopBar.Position = UDim2.new(0.5, -UI.TopBarBaseWidth * 0.5, 0, 44)
TopBar.ClipsDescendants = true
TopBar.Visible = false
TopBar.ZIndex = 5
TopBar.Parent = LegacyUIRoot
UI.BindTheme(TopBar, "BackgroundColor3", "Background")
round(TopBar, 14)
gradient(TopBar, "Surface", "Surface2", 75)

do
    UI.CategoryGlow = Instance.new("ImageLabel")
    UI.CategoryGlow.Name = "CategoryGlow"
    UI.CategoryGlow.BackgroundTransparency = 1
    UI.CategoryGlow.BorderSizePixel = 0
    UI.CategoryGlow.Image = "rbxassetid://1316045217"
    UI.CategoryGlow.ImageColor3 = Theme.Accent
    UI.CategoryGlow.ImageTransparency = 0.38
    UI.CategoryGlow.ScaleType = Enum.ScaleType.Slice
    UI.CategoryGlow.SliceCenter = Rect.new(10, 10, 118, 118)
    UI.CategoryGlow.Visible = false
    UI.CategoryGlow.ZIndex = 4
    UI.CategoryGlow.Parent = LegacyUIRoot
    UI.BindTheme(UI.CategoryGlow, "ImageColor3", "Accent")
    local function syncCategoryGlow()
        UI.CategoryGlow.Position = TopBar.Position + UDim2.fromOffset(-14, -14)
        UI.CategoryGlow.Size = TopBar.Size + UDim2.fromOffset(28, 28)
        UI.CategoryGlow.Visible = TopBar.Visible
    end
    syncCategoryGlow()
    trackConnection(TopBar:GetPropertyChangedSignal("Position"):Connect(syncCategoryGlow))
    trackConnection(TopBar:GetPropertyChangedSignal("Size"):Connect(syncCategoryGlow))
    trackConnection(TopBar:GetPropertyChangedSignal("Visible"):Connect(syncCategoryGlow))
end

local DragGrip = Instance.new("Frame")
DragGrip.Name = "BrandButton"
DragGrip.BackgroundTransparency = 1
DragGrip.Size = UDim2.fromOffset(148, 58)
DragGrip.Parent = TopBar

local HubIcon = Instance.new("ImageLabel")
HubIcon.BackgroundColor3 = Theme.Accent
HubIcon.Size = UDim2.fromOffset(30, 30)
HubIcon.Position = UDim2.fromOffset(12, 14)
HubIcon.Parent = DragGrip
HubIcon.Image = UI.ActionIconAssets.Brand or UI.ActionIconUrls.Brand
HubIcon.ScaleType = Enum.ScaleType.Fit
HubIcon.BackgroundTransparency = 1
round(HubIcon, 10)
UI.ActionIconBindings.Brand = {{Image = HubIcon, Fallbacks = {}, Button = nil, DefaultText = ""}}

local TopTitle = textLabel(DragGrip, Theme.Title, UDim2.new(1, -56, 1, 0), UDim2.fromOffset(50, 0), 14, Theme.Text)
TopTitle.TextSize = 16
TopTitle.FontFace = UI.Fonts.HeadingHeavy

UI.GlobalSearchButton = button(TopBar, "", UDim2.fromOffset(48, 48), UDim2.fromOffset(649, 5))
UI.GlobalSearchButton.Name = "GlobalSearchButton"
UI.GlobalSearchButton.ZIndex = 5
do
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.Position = UDim2.fromOffset(22, 21)
    ring.Size = UDim2.fromOffset(15, 15)
    ring.ZIndex = 6
    ring.Parent = UI.GlobalSearchButton
    round(ring, 15)
    stroke(ring, nil, 2, 0)
    local handle = Instance.new("Frame")
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.BackgroundColor3 = Theme.Accent
    handle.BorderSizePixel = 0
    handle.Position = UDim2.fromOffset(30, 30)
    handle.Rotation = 45
    handle.Size = UDim2.fromOffset(3, 11)
    handle.ZIndex = 6
    handle.Parent = UI.GlobalSearchButton
    round(handle, 3)
    UI.BindTheme(handle, "BackgroundColor3", "Accent")
    UI.BindActionIcon(UI.GlobalSearchButton, "Search", {ring, handle})
end

UI.VersionLabel = textLabel(TopBar, "v" .. UI.Version, UDim2.fromOffset(70, 58), UDim2.fromOffset(703, 0), 11, Theme.Muted, Enum.TextXAlignment.Center)
UI.VersionLabel.Name = "VersionLabel"
UI.VersionLabel.FontFace = UI.Fonts.Description

UI.GlobalSearchClip = Instance.new("Frame")
UI.GlobalSearchClip.Name = "GlobalSearchClip"
UI.GlobalSearchClip.BackgroundTransparency = 1
UI.GlobalSearchClip.ClipsDescendants = true
UI.GlobalSearchClip.Position = UDim2.fromOffset(703, 14)
UI.GlobalSearchClip.Size = UDim2.fromOffset(0, 30)
UI.GlobalSearchClip.Visible = false
UI.GlobalSearchClip.ZIndex = 5
UI.GlobalSearchClip.Parent = TopBar

UI.GlobalSearchBox = Instance.new("TextBox")
UI.GlobalSearchBox.Name = "GlobalSearchBox"
UI.GlobalSearchBox.BackgroundColor3 = Theme.Surface2
UI.GlobalSearchBox.BackgroundTransparency = 0.04
UI.GlobalSearchBox.ClearTextOnFocus = false
UI.GlobalSearchBox.PlaceholderText = "Search every setting..."
UI.GlobalSearchBox.PlaceholderColor3 = Theme.Muted
UI.GlobalSearchBox.Text = ""
UI.GlobalSearchBox.TextColor3 = Theme.Text
UI.GlobalSearchBox.TextSize = 17
UI.GlobalSearchBox.FontFace = UI.Fonts.Option
UI.GlobalSearchBox.TextXAlignment = Enum.TextXAlignment.Left
UI.GlobalSearchBox.Position = UDim2.fromOffset(0, 0)
UI.GlobalSearchBox.Size = UDim2.fromOffset(224, 30)
UI.GlobalSearchBox.Visible = true
UI.GlobalSearchBox.ZIndex = 5
UI.GlobalSearchBox.Parent = UI.GlobalSearchClip
round(UI.GlobalSearchBox, 8)
UI.BindTheme(UI.GlobalSearchBox, "BackgroundColor3", "Surface2")
UI.BindTheme(UI.GlobalSearchBox, "TextColor3", "Text")
UI.BindTheme(UI.GlobalSearchBox, "PlaceholderColor3", "Muted")
UI.GlobalSearchPadding = Instance.new("UIPadding")
UI.GlobalSearchPadding.PaddingLeft = UDim.new(0, 10)
UI.GlobalSearchPadding.PaddingRight = UDim.new(0, 10)
UI.GlobalSearchPadding.Parent = UI.GlobalSearchBox

local CategoryScroller = Instance.new("ScrollingFrame")
CategoryScroller.BackgroundTransparency = 1
CategoryScroller.BorderSizePixel = 0
CategoryScroller.ScrollBarThickness = 0
CategoryScroller.ScrollBarImageColor3 = Theme.Accent
CategoryScroller.ScrollingDirection = Enum.ScrollingDirection.X
CategoryScroller.Size = UDim2.fromOffset(495, 58)
CategoryScroller.Position = UDim2.fromOffset(148, 0)
CategoryScroller.CanvasSize = UDim2.fromOffset(488, 0)
CategoryScroller.Parent = TopBar

local CategoryLayout = Instance.new("UIListLayout")
CategoryLayout.FillDirection = Enum.FillDirection.Horizontal
CategoryLayout.VerticalAlignment = Enum.VerticalAlignment.Center
CategoryLayout.Padding = UDim.new(0, 7)
CategoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
CategoryLayout.Parent = CategoryScroller

local ContentWindow = Instance.new("CanvasGroup")
ContentWindow.Name = "ContentWindow"
ContentWindow.BackgroundColor3 = Theme.Background
ContentWindow.BackgroundTransparency = 0.08
ContentWindow.Size = UDim2.fromOffset(680, 440)
ContentWindow.Position = UDim2.new(0.5, -340, 0, 64)
ContentWindow.Visible = false
ContentWindow.GroupTransparency = 1
ContentWindow.ClipsDescendants = true
ContentWindow.ZIndex = 10
ContentWindow.Parent = LegacyUIRoot
UI.BindTheme(ContentWindow, "BackgroundColor3", "Background")
round(ContentWindow, 16)
gradient(ContentWindow, "Surface", "Surface2", 80)
local ContentScale = Instance.new("UIScale")
ContentScale.Parent = ContentWindow
local ContentShadow = addShadow(ContentWindow, UI.ShadowTransparency)
ContentShadow.ZIndex = 2
local ContentShadowScale = Instance.new("UIScale")
ContentShadowScale.Parent = ContentShadow
trackConnection(ContentScale:GetPropertyChangedSignal("Scale"):Connect(function()
    ContentShadowScale.Scale = ContentScale.Scale
end))

local WindowHeader = Instance.new("Frame")
WindowHeader.BackgroundColor3 = Theme.Surface
WindowHeader.BackgroundTransparency = 0.04
WindowHeader.Size = UDim2.new(1, 0, 0, 48)
WindowHeader.Parent = ContentWindow
UI.BindTheme(WindowHeader, "BackgroundColor3", "Surface")
round(WindowHeader, 16)
gradient(WindowHeader, "Surface", "Surface2", 75)

local HeaderMask = Instance.new("Frame")
HeaderMask.BorderSizePixel = 0
HeaderMask.BackgroundColor3 = Theme.Surface
HeaderMask.BackgroundTransparency = 0.04
HeaderMask.Position = UDim2.new(0, 0, 1, -10)
HeaderMask.Size = UDim2.new(1, 0, 0, 10)
HeaderMask.Parent = WindowHeader
UI.BindTheme(HeaderMask, "BackgroundColor3", "Surface")

local WindowTitle = textLabel(WindowHeader, "Home", UDim2.new(1, -58, 1, 0), UDim2.fromOffset(16, 0), 18, Theme.Text)
WindowTitle.FontFace = UI.Fonts.HeadingHeavy

local CloseButton = button(WindowHeader, "×", UDim2.fromOffset(34, 34), UDim2.new(1, -42, 0, 7))
CloseButton.TextSize = 21
CloseButton.FontFace = UI.Fonts.HeadingHeavy
UI.BindActionIcon(CloseButton, "Close")

local WindowDragZone = Instance.new("Frame")
WindowDragZone.BackgroundTransparency = 1
WindowDragZone.Size = UDim2.new(1, -58, 1, 0)
WindowDragZone.ZIndex = 1
WindowDragZone.Parent = WindowHeader

local PageHost = Instance.new("Frame")
PageHost.BackgroundTransparency = 1
PageHost.ClipsDescendants = true
PageHost.Size = UDim2.new(1, -16, 1, -62)
PageHost.Position = UDim2.fromOffset(8, 54)
PageHost.Parent = ContentWindow

do
    UI.ConfirmOverlay = Instance.new("Frame")
    UI.ConfirmOverlay.Name = "ConfirmOverlay"
    UI.ConfirmOverlay.Active = true
    UI.ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.ConfirmOverlay.BackgroundTransparency = 0.42
    UI.ConfirmOverlay.BorderSizePixel = 0
    UI.ConfirmOverlay.Size = UDim2.fromScale(1, 1)
    UI.ConfirmOverlay.Visible = false
    UI.ConfirmOverlay.ZIndex = 70
    UI.ConfirmOverlay.Parent = ContentWindow
    round(UI.ConfirmOverlay, 16)
    UI.ConfirmModal = Instance.new("Frame")
    UI.ConfirmModal.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.ConfirmModal.BackgroundColor3 = Theme.Surface
    UI.ConfirmModal.Position = UDim2.fromScale(0.5, 0.5)
    UI.ConfirmModal.Size = UDim2.fromOffset(350, 176)
    UI.ConfirmModal.ZIndex = 71
    UI.ConfirmModal.Parent = UI.ConfirmOverlay
    UI.BindTheme(UI.ConfirmModal, "BackgroundColor3", "Surface")
    round(UI.ConfirmModal, 16)
    gradient(UI.ConfirmModal, "Surface", "Surface2", 90)
    UI.ConfirmScale = Instance.new("UIScale")
    UI.ConfirmScale.Parent = UI.ConfirmModal
    UI.ConfirmTitle = textLabel(UI.ConfirmModal, "Confirm", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 16), 19, Theme.Text, Enum.TextXAlignment.Center)
    UI.ConfirmTitle.FontFace = UI.Fonts.HeadingHeavy
    UI.ConfirmTitle.ZIndex = 72
    UI.ConfirmMessage = textLabel(UI.ConfirmModal, "", UDim2.new(1, -34, 0, 48), UDim2.fromOffset(17, 52), 15, Theme.Muted, Enum.TextXAlignment.Center)
    UI.ConfirmMessage.FontFace = UI.Fonts.Description
    UI.ConfirmMessage.TextWrapped = true
    UI.ConfirmMessage.ZIndex = 72
    UI.ConfirmCancel = button(UI.ConfirmModal, "Cancel", UDim2.fromOffset(145, 36), UDim2.fromOffset(20, 122))
    UI.ConfirmCancel.ZIndex = 72
    UI.ConfirmAccept = button(UI.ConfirmModal, "Delete", UDim2.fromOffset(145, 36), UDim2.new(1, -165, 0, 122))
    UI.ConfirmAccept.ZIndex = 72
    UI.ConfirmAction = function() end
    UI.CloseConfirm = function()
        UI.ConfirmOverlay.Visible = false
    end
    UI.ShowConfirm = function(title, message, callback)
        UI.ConfirmTitle.Text = title
        UI.ConfirmMessage.Text = message
        UI.ConfirmAction = callback or function() end
        UI.ConfirmOverlay.Visible = true
        UI.ConfirmScale.Scale = 0.9
        animate(UI.ConfirmScale, {Scale = 1}, 0.32, Enum.EasingStyle.Quint)
    end
    UI.ConfirmCancel.Activated:Connect(UI.CloseConfirm)
    UI.ConfirmAccept.Activated:Connect(function()
        local callback = UI.ConfirmAction
        UI.CloseConfirm()
        pcall(callback)
    end)
end

local StatsPanel = Instance.new("CanvasGroup")
StatsPanel.Name = "TasuHubStats"
StatsPanel.BackgroundColor3 = Theme.Surface
StatsPanel.BackgroundTransparency = 0.08
StatsPanel.GroupTransparency = 1
StatsPanel.ClipsDescendants = true
StatsPanel.Position = UDim2.fromOffset(24, 120)
StatsPanel.Size = UDim2.fromOffset(190, 92)
StatsPanel.Visible = false
StatsPanel.ZIndex = 30
StatsPanel.Parent = LegacyUIRoot
UI.BindTheme(StatsPanel, "BackgroundColor3", "Surface")
round(StatsPanel, 12)
gradient(StatsPanel, "Surface", "Surface2", 90)
addShadow(StatsPanel, 0.7)
local StatsTitle = textLabel(StatsPanel, "TasuHub Stats", UDim2.new(1, -34, 0, 30), UDim2.fromOffset(10, 2), 16, Theme.Text)
StatsTitle.FontFace = UI.Fonts.HeadingHeavy
StatsTitle.ZIndex = 31
local StatsClose = button(StatsPanel, "×", UDim2.fromOffset(26, 24), UDim2.new(1, -29, 0, 3))
StatsClose.ZIndex = 31
StatsClose.TextSize = 17
local StatsBody = textLabel(StatsPanel, "", UDim2.new(1, -20, 1, -34), UDim2.fromOffset(10, 31), 14, Theme.Text)
StatsBody.FontFace = UI.Fonts.Description
StatsBody.TextYAlignment = Enum.TextYAlignment.Top
StatsBody.ZIndex = 31
local StatsScale = Instance.new("UIScale")
StatsScale.Parent = StatsPanel
makeDraggable(StatsPanel, StatsTitle)
local statsTransition = 0
UI.RefreshStatsWindow = function()
    if not UI.LegacyUIEnabled then
        StatsPanel.Visible = false
        return
    end
    statsTransition = statsTransition + 1
    local revision = statsTransition
    if State.Stats.Visible then
        StatsPanel.Visible = true
        StatsPanel.GroupTransparency = 1
        StatsScale.Scale = 0.9
        animate(StatsPanel, {GroupTransparency = 0}, 0.28, Enum.EasingStyle.Quint)
        animate(StatsScale, {Scale = 1}, 0.32, Enum.EasingStyle.Quint)
    else
        animate(StatsPanel, {GroupTransparency = 1}, 0.22, Enum.EasingStyle.Quint)
        animate(StatsScale, {Scale = 0.92}, 0.22, Enum.EasingStyle.Quint)
        task.delay(0.23, function()
            if revision == statsTransition and not State.Stats.Visible and StatsPanel.Parent then StatsPanel.Visible = false end
        end)
    end
end
StatsClose.Activated:Connect(function()
    State.Stats.Visible = false
    UI.RefreshStatsWindow()
    UI.RefreshControls()
end)
local statsElapsed, statsFrames, statsFPS = 0, 0, 0
trackConnection(RunService.RenderStepped:Connect(function(deltaTime)
    statsElapsed = statsElapsed + deltaTime
    statsFrames = statsFrames + 1
    if statsElapsed < 0.3 then return end
    statsFPS = math.floor(statsFrames / statsElapsed + 0.5)
    statsElapsed, statsFrames = 0, 0
    if not State.Stats.Visible then return end
    local lines = {}
    if State.Stats.FPS then table.insert(lines, "FPS   " .. tostring(statsFPS)) end
    if State.Stats.Ping then
        local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() * 1000 end)
        table.insert(lines, "PING  " .. (ok and string.format("%.0f ms", ping) or "n/a"))
    end
    if State.Stats.Players then table.insert(lines, "PLAYERS  " .. tostring(#Players:GetPlayers())) end
    if State.Stats.Memory then
        local ok, memory = pcall(function() return StatsService:GetTotalMemoryUsageMb() end)
        table.insert(lines, "MEMORY  " .. (ok and string.format("%.0f MB", memory) or "n/a"))
    end
    StatsBody.Text = table.concat(lines, "\n")
    StatsPanel.Size = UDim2.fromOffset(190, 38 + math.max(1, #lines) * 18)
end))

UI.SetLoading(0.22, "Arayüz bileşenleri yükleniyor")

local topBarCollapsed = false
local topBarTransition = 0
local function toggleTopBarCollapsed()
    if type(UI.CloseGlobalSearch) == "function" then
        UI.CloseGlobalSearch(true)
    end
    topBarCollapsed = not topBarCollapsed
    topBarTransition = topBarTransition + 1
    local transition = topBarTransition
    if not topBarCollapsed then
        CategoryScroller.Visible = true
    end
    animate(TopBar, {Size = UDim2.fromOffset(topBarCollapsed and 148 or UI.TopBarBaseWidth, 58)}, 0.28, Enum.EasingStyle.Quint)
    if topBarCollapsed then
        task.delay(0.28, function()
            if transition == topBarTransition and topBarCollapsed and CategoryScroller.Parent then
                CategoryScroller.Visible = false
            end
        end)
    end
end

makeDraggable(TopBar, DragGrip, toggleTopBarCollapsed)
makeDraggable(ContentWindow, WindowDragZone)

local pages = {}
local pageScales = {}
local categoryButtons = {}
local categoryOutlines = {}
local controlRefreshers = {}
local currentCategory = "Home"

local function refreshControls()
    for _, refresh in ipairs(controlRefreshers) do
        pcall(refresh)
    end
end

UI.RefreshControls = refreshControls

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Size = UDim2.fromScale(1, 1)
    page.Visible = false
    page.Parent = PageHost
    UI.BindTheme(page, "ScrollBarImageColor3", "Accent")
    local pageScale = Instance.new("UIScale")
    pageScale.Parent = page
    pageScales[name] = pageScale
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = page
    pages[name] = page
    return page
end

local compactPendingRows = setmetatable({}, {__mode = "k"})
local function resetCompactRow(card)
    compactPendingRows[card] = nil
end

local function compactParent(card, minimumHeight)
    local pending = compactPendingRows[card]
    if not pending or not pending.Parent or (pending:GetAttribute("CompactCount") or 0) >= 2 then
        pending = Instance.new("Frame")
        pending.Name = "CompactOptionsRow"
        pending.BackgroundTransparency = 1
        pending.AutomaticSize = Enum.AutomaticSize.Y
        pending.Size = UDim2.new(1, 0, 0, minimumHeight)
        pending.Parent = card
        pending:SetAttribute("CompactCount", 0)
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 8)
        layout.Parent = pending
        compactPendingRows[card] = pending
    end
    pending:SetAttribute("CompactCount", (pending:GetAttribute("CompactCount") or 0) + 1)
    if pending:GetAttribute("CompactCount") >= 2 then compactPendingRows[card] = nil end
    return pending
end

local function addNote(card, text)
    resetCompactRow(card)
    local label = textLabel(card, text, UDim2.new(1, 0, 0, 38), nil, 16, Theme.Muted)
    label.FontFace = UI.Fonts.Description
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    return label
end

UI.AddAccordion = function(page, title, defaultOpen)
    local outer = Instance.new("Frame")
    outer.Name = string.gsub(title, "[^%w]", "") .. "Accordion"
    outer.BackgroundColor3 = Theme.Surface
    outer.BackgroundTransparency = 0.14
    outer.Size = UDim2.new(1, -4, 0, 44)
    outer.AutomaticSize = Enum.AutomaticSize.Y
    outer.Parent = page
    UI.BindTheme(outer, "BackgroundColor3", "Surface")
    round(outer, 12)
    gradient(outer, "Surface", "Surface2", 90)
    local outerLayout = Instance.new("UIListLayout")
    outerLayout.Padding = UDim.new(0, 5)
    outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    outerLayout.Parent = outer
    local header = button(outer, title, UDim2.new(1, 0, 0, 44))
    header.LayoutOrder = 0
    header.TextSize = 19
    header.TextXAlignment = Enum.TextXAlignment.Left
    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 12)
    headerPadding.PaddingRight = UDim.new(0, 12)
    headerPadding.Parent = header
    local body = Instance.new("CanvasGroup")
    body.Name = title .. "Body"
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    body.Size = UDim2.new(1, 0, 0, 0)
    body.GroupTransparency = 1
    body.Visible = false
    body.LayoutOrder = 1
    body.Parent = outer
    body:SetAttribute("CategoryName", page.Name)
    body:SetAttribute("CardName", title)
    body:SetAttribute("IsAccordionBody", true)
    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 7)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body
    local bodyPadding = Instance.new("UIPadding")
    bodyPadding.PaddingLeft = UDim.new(0, 10)
    bodyPadding.PaddingRight = UDim.new(0, 10)
    bodyPadding.PaddingBottom = UDim.new(0, 10)
    bodyPadding.Parent = body
    local open = false
    local function setOpen(value)
        open = value == true
        if not open then UI.CloseActiveDropdown() end
        header.Text = title .. (open and "   ▲" or "   ▼")
        if open then
            body.Visible = true
            body.GroupTransparency = 1
            body.Size = UDim2.new(1, 0, 0, 0)
            task.defer(function()
                if not open or not body.Parent then return end
                local targetHeight = bodyLayout.AbsoluteContentSize.Y + 10
                animate(body, {Size = UDim2.new(1, 0, 0, targetHeight), GroupTransparency = 0}, 0.4, Enum.EasingStyle.Quint)
            end)
        else
            animate(body, {Size = UDim2.new(1, 0, 0, 0), GroupTransparency = 1}, 0.34, Enum.EasingStyle.Quint)
            task.delay(0.34, function()
                if not open and body.Parent then body.Visible = false end
            end)
        end
    end
    UI.AccordionOpeners[body] = setOpen
    bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if open and body.Parent then
            animate(body, {Size = UDim2.new(1, 0, 0, bodyLayout.AbsoluteContentSize.Y + 10)}, 0.26, Enum.EasingStyle.Quint)
        end
    end)
    header.Activated:Connect(function() setOpen(not open) end)
    if defaultOpen then task.defer(function() setOpen(true) end) else setOpen(false) end
    return body
end

UI.AddStaticCard = function(page, title)
    local outer = Instance.new("Frame")
    outer.Name = string.gsub(title, "[^%w]", "") .. "StaticCard"
    outer.BackgroundColor3 = Theme.Surface
    outer.BackgroundTransparency = 0.14
    outer.Size = UDim2.new(1, -4, 0, 44)
    outer.AutomaticSize = Enum.AutomaticSize.Y
    outer.Parent = page
    UI.BindTheme(outer, "BackgroundColor3", "Surface")
    round(outer, 12)
    gradient(outer, "Surface", "Surface2", 90)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = outer
    local header = textLabel(outer, title, UDim2.new(1, 0, 0, 44), nil, 19, Theme.Text)
    header.FontFace = UI.Fonts.HeadingHeavy
    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 12)
    headerPadding.PaddingRight = UDim.new(0, 12)
    headerPadding.Parent = header
    local body = Instance.new("Frame")
    body.Name = title .. "Body"
    body.BackgroundTransparency = 1
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Parent = outer
    body:SetAttribute("CategoryName", page.Name)
    body:SetAttribute("CardName", title)
    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 7)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body
    local bodyPadding = Instance.new("UIPadding")
    bodyPadding.PaddingLeft = UDim.new(0, 10)
    bodyPadding.PaddingRight = UDim.new(0, 10)
    bodyPadding.PaddingBottom = UDim.new(0, 10)
    bodyPadding.Parent = body
    return body
end

local function createCard(page, title)
    return UI.AddAccordion(page, title, false)
end

local function addAction(card, text, callback)
    resetCompactRow(card)
    local item = button(card, text, UDim2.new(1, 0, 0, 30))
    item.Activated:Connect(function()
        pcall(callback, item)
    end)
    local flag = UI.ControlFlag(card, text)
    UI.Register(flag, {
        Instance = item,
        Activate = function()
            pcall(callback, item)
        end
    })
    return item
end

local function addInput(card, placeholder, defaultText, callback, multiLine)
    resetCompactRow(card)
    local input = Instance.new("TextBox")
    input.BackgroundColor3 = Theme.Surface2
    input.BackgroundTransparency = 0.06
    input.ClearTextOnFocus = false
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = Theme.Muted
    input.Text = defaultText or ""
    input.TextColor3 = Theme.Text
    input.TextSize = 17
    input.FontFace = UI.Fonts.Option
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.MultiLine = multiLine or false
    input.TextWrapped = multiLine or false
    input.Size = UDim2.new(1, 0, 0, multiLine and 76 or 36)
    input.Parent = card
    UI.BindTheme(input, "BackgroundColor3", "Surface2")
    UI.BindTheme(input, "TextColor3", "Text")
    UI.BindTheme(input, "PlaceholderColor3", "Muted")
    round(input, 8)
    gradient(input, "Surface", "Surface2", 90)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = input
    if callback then
        input.FocusLost:Connect(function(enterPressed)
            pcall(callback, input.Text, enterPressed, input)
        end)
    end
    local flag = UI.ControlFlag(card, placeholder)
    UI.Register(flag, {
        Set = function(_, value)
            input.Text = tostring(value or "")
            if callback then
                pcall(callback, input.Text, false, input)
            end
        end,
        Get = function()
            return input.Text
        end,
        Instance = input
    })
    return input
end

local pendingKeybind
local keybindActions = {}

local function addToggle(card, text, getter, setter, bindable)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(0.5, -4, 0, 32)
    row.Parent = compactParent(card, 32)
    local label = textLabel(row, text, UDim2.new(1, bindable and -122 or -58, 1, 0), nil, 16, Theme.Text)
    label.FontFace = UI.Fonts.Option
    local toggle = Instance.new("TextButton")
    toggle.AutoButtonColor = false
    toggle.Text = ""
    toggle.Size = UDim2.fromOffset(44, 22)
    toggle.Position = UDim2.new(1, -44, 0.5, -11)
    toggle.Parent = row
    round(toggle, 11)
    local bindId = UI.ControlFlag(card, text)
    local bindButton
    if bindable then
        bindButton = button(row, State.Keybinds[bindId] or "Bind", UDim2.fromOffset(50, 22), UDim2.new(1, -102, 0.5, -11))
        bindButton.TextSize = 15
    end
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Theme.Text
    knob.Parent = toggle
    round(knob, 8)
    local function render()
        local enabled = getter()
        animate(toggle, {BackgroundColor3 = enabled and Theme.Accent or Theme.ControlOff}, 0.14)
        animate(knob, {BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(132, 158, 183), Position = enabled and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)}, 0.14)
    end
    local function renderBind()
        if bindButton then bindButton.Text = State.Keybinds[bindId] or "Bind" end
    end
    table.insert(controlRefreshers, render)
    if bindable then
        table.insert(controlRefreshers, renderBind)
        keybindActions[bindId] = function()
            setter(not getter())
            refreshControls()
        end
        bindButton.Activated:Connect(function()
            pendingKeybind = {Id = bindId, Button = bindButton}
            bindButton.Text = "Press"
            showToast("Press a key, or Backspace to clear")
        end)
    else
        State.Keybinds[bindId] = nil
        keybindActions[bindId] = nil
    end
    toggle.Activated:Connect(function()
        setter(not getter())
        render()
        refreshControls()
    end)
    render()
    return UI.Register(bindId, {
        Render = render,
        Row = row,
        Label = label,
        BindId = bindable and bindId or nil,
        Get = getter,
        Set = function(_, value)
            setter(value == true)
            render()
        end
    })
end

local function addSlider(card, text, minimum, maximum, getter, setter, decimals, visibleGetter)
    resetCompactRow(card)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.ClipsDescendants = true
    holder.Size = UDim2.new(1, 0, 0, 48)
    holder.Parent = card
    local title = textLabel(holder, text, UDim2.new(1, -70, 0, 24), nil, 16, Theme.Text)
    title.FontFace = UI.Fonts.Option
    local valueLabel = textLabel(holder, "", UDim2.fromOffset(65, 24), UDim2.new(1, -65, 0, 0), 14, Theme.Muted, Enum.TextXAlignment.Right)
    valueLabel.FontFace = UI.Fonts.Description
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Theme.Track
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 1, -11)
    bar.Parent = holder
    UI.BindTheme(bar, "BackgroundColor3", "Track")
    round(bar, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Accent
    fill.Size = UDim2.fromScale(0, 1)
    fill.Parent = bar
    round(fill, 3)
    gradient(fill, "AccentSoft", "Accent", 0)
    local dragging = false
    local precision = decimals or 0
    local function render()
        local value = math.clamp(tonumber(getter()) or minimum, minimum, maximum)
        fill.Size = UDim2.fromScale((value - minimum) / (maximum - minimum), 1)
        valueLabel.Text = string.format("%." .. precision .. "f", value)
        local visible = not visibleGetter or visibleGetter()
        if visible then
            holder.Visible = true
            animate(holder, {Size = UDim2.new(1, 0, 0, 48)}, 0.28, Enum.EasingStyle.Quint)
        else
            animate(holder, {Size = UDim2.new(1, 0, 0, 0)}, 0.24, Enum.EasingStyle.Quint)
            task.delay(0.24, function()
                if holder.Parent and visibleGetter and not visibleGetter() then holder.Visible = false end
            end)
        end
    end
    table.insert(controlRefreshers, render)
    local function update(input)
        local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local value = minimum + (maximum - minimum) * ratio
        local factor = 10 ^ precision
        value = math.floor(value * factor + 0.5) / factor
        setter(value)
        render()
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end))
    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    render()
    local flag = UI.ControlFlag(card, text)
    return UI.Register(flag, {
        Render = render,
        Holder = holder,
        Title = title,
        Get = getter,
        Set = function(_, value)
            setter(math.clamp(tonumber(value) or minimum, minimum, maximum))
            render()
        end
    })
end

UI.AddDropdown = function(card, text, values, getter, setter, multiple)
    local holder = Instance.new("Frame")
    holder.Name = string.gsub(text, "[^%w]", "") .. "Dropdown"
    holder.BackgroundTransparency = 1
    local forceFullWidth = card:GetAttribute("ForceFullWidth") == true
    holder.Size = forceFullWidth and UDim2.new(1, 0, 0, 38) or UDim2.new(0.5, -4, 0, 38)
    holder.Parent = forceFullWidth and card or compactParent(card, 38)
    holder:SetAttribute("SearchText", string.lower(text .. " " .. table.concat(values, " ")))
    local selector = button(holder, "", UDim2.new(1, 0, 0, 38))
    selector.TextSize = 17
    selector.LayoutOrder = 0
    selector.TextXAlignment = Enum.TextXAlignment.Left
    local selectorPadding = Instance.new("UIPadding")
    selectorPadding.PaddingLeft = UDim.new(0, 11)
    selectorPadding.PaddingRight = UDim.new(0, 11)
    selectorPadding.Parent = selector
    local options = Instance.new("CanvasGroup")
    options.BackgroundColor3 = Theme.Surface2
    options.BackgroundTransparency = 0.08
    options.ClipsDescendants = true
    options.Size = UDim2.new(1, 0, 0, 0)
    options.GroupTransparency = 1
    options.Visible = false
    options.ZIndex = 80
    options.Parent = LegacyUIRoot
    round(options, 9)
    UI.BindTheme(options, "BackgroundColor3", "Surface2")
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Padding = UDim.new(0, 4)
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = options
    local optionsPadding = Instance.new("UIPadding")
    optionsPadding.PaddingLeft = UDim.new(0, 5)
    optionsPadding.PaddingRight = UDim.new(0, 5)
    optionsPadding.PaddingTop = UDim.new(0, 5)
    optionsPadding.PaddingBottom = UDim.new(0, 5)
    optionsPadding.Parent = options
    local open = false
    local controller
    local closeDropdown
    local function optionsHeight()
        return #values > 0 and (#values * 34 + math.max(0, #values - 1) * 4 + 10) or 0
    end
    local function placeOptions(height)
        local rootPosition = InterfaceRoot.AbsolutePosition
        local selectorPosition = selector.AbsolutePosition - rootPosition
        local selectorSize = selector.AbsoluteSize
        local canvas = getCanvasSize()
        local targetHeight = height or optionsHeight()
        local below = selectorPosition.Y + selectorSize.Y + 5
        local y = below + targetHeight <= canvas.Y - 8 and below or math.max(8, selectorPosition.Y - targetHeight - 5)
        options.Position = UDim2.fromOffset(selectorPosition.X, y)
        return selectorSize.X, targetHeight
    end
    local function selectedValues()
        local current = getter()
        if multiple then
            return type(current) == "table" and current or {}
        end
        return {current}
    end
    local function render()
        local selected = selectedValues()
        local display = multiple and (#selected > 0 and table.concat(selected, ", ") or "None") or tostring(selected[1] or "None")
        selector.Text = text .. "   ›   " .. display .. (open and "   ▲" or "   ▼")
        for _, optionButton in ipairs(options:GetChildren()) do
            if optionButton:IsA("TextButton") then
                local active = table.find(selected, optionButton:GetAttribute("Value")) ~= nil
                optionButton:SetAttribute("Selected", active)
                optionButton.BackgroundColor3 = active and Theme.AccentSoft or Theme.Surface
            end
        end
    end
    local function setOpen(value)
        if value then
            if UI.CloseActiveDropdown ~= closeDropdown then UI.CloseActiveDropdown() end
            open = true
            UI.CloseActiveDropdown = closeDropdown
            local width, height = placeOptions()
            options.Visible = true
            options.GroupTransparency = 1
            options.Size = UDim2.fromOffset(width, 0)
            animate(options, {Size = UDim2.fromOffset(width, height), GroupTransparency = 0}, 0.36, Enum.EasingStyle.Quint)
        else
            open = false
            local width = math.max(1, options.AbsoluteSize.X, selector.AbsoluteSize.X)
            animate(options, {Size = UDim2.fromOffset(width, 0), GroupTransparency = 1}, 0.3, Enum.EasingStyle.Quint)
            task.delay(0.3, function()
                if not open and options.Parent then options.Visible = false end
            end)
        end
        render()
    end
    closeDropdown = function()
        if open then setOpen(false) end
    end
    local function rebuildOptions()
        for _, child in ipairs(options:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        holder:SetAttribute("SearchText", string.lower(text .. " " .. table.concat(values, " ")))
        for index, value in ipairs(values) do
            local optionButton = button(options, tostring(value), UDim2.new(1, 0, 0, 34))
            optionButton.TextSize = 16
            optionButton.ZIndex = 81
            optionButton.LayoutOrder = index
            optionButton:SetAttribute("Value", value)
            optionButton.Activated:Connect(function()
                if multiple then
                    local nextValues = table.clone(selectedValues())
                    local found = table.find(nextValues, value)
                    if found then
                        table.remove(nextValues, found)
                    else
                        table.insert(nextValues, value)
                    end
                    setter(nextValues)
                else
                    setter(value)
                    setOpen(false)
                end
                render()
                refreshControls()
            end)
        end
    end
    rebuildOptions()
    selector.Activated:Connect(function()
        setOpen(not open)
    end)
    trackConnection(selector:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if open then placeOptions() end
    end))
    trackConnection(selector:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if open then
            local width, height = placeOptions()
            options.Size = UDim2.fromOffset(width, height)
        end
    end))
    local flag = UI.ControlFlag(card, text)
    controller = UI.Register(flag, {
        Holder = holder,
        Get = getter,
        Render = render,
        Set = function(_, value)
            if multiple then
                setter(type(value) == "table" and value or {})
            elseif table.find(values, value) then
                setter(value)
            end
            render()
        end,
        Close = function()
            setOpen(false)
        end,
        SetOptions = function(_, nextOptions)
            values = type(nextOptions) == "table" and nextOptions or {}
            rebuildOptions()
            if open then
                local width, height = placeOptions()
                options.Size = UDim2.fromOffset(width, height)
            end
            render()
        end
    })
    table.insert(controlRefreshers, render)
    render()
    return controller
end

UI.AddPlayerDropdown = function(card, text, getter, setter)
    resetCompactRow(card)
    local holder = Instance.new("Frame")
    holder.Name = string.gsub(text, "[^%w]", "") .. "PlayerDropdown"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 42)
    holder.Parent = card
    holder:SetAttribute("SearchText", string.lower(text .. " player avatar target"))

    local selector = button(holder, "", UDim2.new(1, 0, 0, 42))
    selector.LayoutOrder = 0
    local selectedAvatar = Instance.new("ImageLabel")
    selectedAvatar.BackgroundColor3 = Theme.AccentSoft
    selectedAvatar.BackgroundTransparency = 0.08
    selectedAvatar.Position = UDim2.fromOffset(7, 5)
    selectedAvatar.Size = UDim2.fromOffset(32, 32)
    selectedAvatar.ScaleType = Enum.ScaleType.Crop
    selectedAvatar.Parent = selector
    round(selectedAvatar, 16)
    UI.BindTheme(selectedAvatar, "BackgroundColor3", "AccentSoft")
    local selectedText = textLabel(selector, text .. "   ›   Select player", UDim2.new(1, -54, 1, 0), UDim2.fromOffset(47, 0), 17, Theme.Text)
    selectedText.FontFace = UI.Fonts.Option

    local options = Instance.new("CanvasGroup")
    options.BackgroundColor3 = Theme.Surface2
    options.BackgroundTransparency = 0.06
    options.ClipsDescendants = true
    options.GroupTransparency = 1
    options.LayoutOrder = 1
    options.Size = UDim2.new(1, 0, 0, 0)
    options.Visible = false
    options.ZIndex = 80
    options.Parent = LegacyUIRoot
    round(options, 9)
    UI.BindTheme(options, "BackgroundColor3", "Surface2")
    local list = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = Theme.Accent
    list.Size = UDim2.fromScale(1, 1)
    list.Parent = options
    UI.BindTheme(list, "ScrollBarImageColor3", "Accent")
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingLeft = UDim.new(0, 6)
    listPadding.PaddingRight = UDim.new(0, 8)
    listPadding.PaddingTop = UDim.new(0, 6)
    listPadding.PaddingBottom = UDim.new(0, 6)
    listPadding.Parent = list

    local open = false
    local playerCount = 0
    local controller
    local closeDropdown
    local function targetHeight()
        local visible = math.min(5, playerCount)
        return visible > 0 and visible * 50 + math.max(0, visible - 1) * 5 + 12 or 0
    end
    local function placeOptions(height)
        local rootPosition = InterfaceRoot.AbsolutePosition
        local selectorPosition = selector.AbsolutePosition - rootPosition
        local selectorSize = selector.AbsoluteSize
        local canvas = getCanvasSize()
        local target = height or targetHeight()
        local below = selectorPosition.Y + selectorSize.Y + 5
        local y = below + target <= canvas.Y - 8 and below or math.max(8, selectorPosition.Y - target - 5)
        options.Position = UDim2.fromOffset(selectorPosition.X, y)
        return selectorSize.X, target
    end
    local function render()
        local player = getter()
        if player and player.Parent == Players then
            selectedAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
            selectedAvatar.ImageTransparency = 0
            selectedText.Text = text .. "   ›   " .. player.DisplayName .. "  (@" .. player.Name .. ")"
        else
            selectedAvatar.Image = ""
            selectedAvatar.ImageTransparency = 1
            selectedText.Text = text .. "   ›   Select player"
        end
    end
    local function setOpen(value)
        local shouldOpen = value == true and playerCount > 0
        if shouldOpen then
            if UI.CloseActiveDropdown ~= closeDropdown then UI.CloseActiveDropdown() end
            open = true
            UI.CloseActiveDropdown = closeDropdown
            local width, height = placeOptions()
            options.Visible = true
            options.GroupTransparency = 1
            options.Size = UDim2.fromOffset(width, 0)
            animate(options, {Size = UDim2.fromOffset(width, height), GroupTransparency = 0}, 0.36, Enum.EasingStyle.Quint)
        else
            open = false
            local width = math.max(1, options.AbsoluteSize.X, selector.AbsoluteSize.X)
            animate(options, {Size = UDim2.fromOffset(width, 0), GroupTransparency = 1}, 0.3, Enum.EasingStyle.Quint)
            task.delay(0.3, function()
                if not open and options.Parent then options.Visible = false end
            end)
        end
    end
    closeDropdown = function()
        if open then setOpen(false) end
    end
    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do
            if child.Name == "PlayerOption" then child:Destroy() end
        end
        local available = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then table.insert(available, player) end
        end
        table.sort(available, function(first, second)
            return string.lower(first.DisplayName) < string.lower(second.DisplayName)
        end)
        playerCount = #available
        for index, player in ipairs(available) do
            local row = button(list, "", UDim2.new(1, -4, 0, 50))
            row.Name = "PlayerOption"
            row.LayoutOrder = index
            row.ZIndex = 81
            local avatar = Instance.new("ImageLabel")
            avatar.BackgroundColor3 = Theme.AccentSoft
            avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
            avatar.Position = UDim2.fromOffset(6, 5)
            avatar.Size = UDim2.fromOffset(40, 40)
            avatar.ScaleType = Enum.ScaleType.Crop
            avatar.Parent = row
            round(avatar, 20)
            UI.BindTheme(avatar, "BackgroundColor3", "AccentSoft")
            local display = textLabel(row, player.DisplayName, UDim2.new(1, -62, 0, 22), UDim2.fromOffset(56, 4), 16, Theme.Text)
            display.FontFace = UI.Fonts.Option
            local username = textLabel(row, "@" .. player.Name, UDim2.new(1, -62, 0, 18), UDim2.fromOffset(56, 27), 14, Theme.Muted)
            username.FontFace = UI.Fonts.Description
            row.Activated:Connect(function()
                setter(player)
                render()
                setOpen(false)
            end)
        end
        if open then
            local width, height = placeOptions()
            options.Size = UDim2.fromOffset(width, height)
        end
        render()
    end
    selector.Activated:Connect(function() setOpen(not open) end)
    trackConnection(selector:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if open then placeOptions() end
    end))
    trackConnection(selector:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if open then
            local width, height = placeOptions()
            options.Size = UDim2.fromOffset(width, height)
        end
    end))
    controller = UI.Register(UI.ControlFlag(card, text), {
        Holder = holder,
        Instance = selector,
        Get = function()
            local player = getter()
            return player and player.UserId or nil
        end,
        Set = function(_, value)
            for _, player in ipairs(Players:GetPlayers()) do
                if player.UserId == tonumber(value) or player.Name == tostring(value) then
                    setter(player)
                    break
                end
            end
            render()
        end,
        Render = render,
        Refresh = rebuild,
        Close = function() setOpen(false) end
    })
    table.insert(controlRefreshers, render)
    rebuild()
    return controller
end

UI.AddColorPicker = function(card, text, getter, setter)
    resetCompactRow(card)
    local holder = Instance.new("Frame")
    holder.Name = string.gsub(text, "[^%w]", "") .. "ColorPicker"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 34)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Parent = card
    holder:SetAttribute("SearchText", string.lower(text .. " color rgb hex"))
    local holderLayout = Instance.new("UIListLayout")
    holderLayout.Padding = UDim.new(0, 5)
    holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    holderLayout.Parent = holder
    local selector = button(holder, text, UDim2.new(1, 0, 0, 34))
    selector.LayoutOrder = 0
    selector.TextXAlignment = Enum.TextXAlignment.Left
    local selectorPadding = Instance.new("UIPadding")
    selectorPadding.PaddingLeft = UDim.new(0, 11)
    selectorPadding.PaddingRight = UDim.new(0, 44)
    selectorPadding.Parent = selector
    local preview = Instance.new("Frame")
    preview.AnchorPoint = Vector2.new(1, 0.5)
    preview.Position = UDim2.new(1, -9, 0.5, 0)
    preview.Size = UDim2.fromOffset(24, 20)
    preview.Parent = selector
    round(preview, 6)
    local panel = Instance.new("Frame")
    panel.BackgroundColor3 = Theme.Surface2
    panel.BackgroundTransparency = 0.08
    panel.Size = UDim2.new(1, 0, 0, 124)
    panel.Visible = false
    panel.LayoutOrder = 1
    panel.Parent = holder
    round(panel, 9)
    UI.BindTheme(panel, "BackgroundColor3", "Surface2")
    local channels = {}
    local draggingChannel
    local currentColor = getter()
    local hexInput
    local function colorComponents()
        local color = typeof(currentColor) == "Color3" and currentColor or Color3.new(1, 1, 1)
        return math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
    end
    local function render()
        currentColor = getter()
        local r, g, b = colorComponents()
        preview.BackgroundColor3 = currentColor
        for index, value in ipairs({r, g, b}) do
            local channel = channels[index]
            if channel then
                channel.Fill.Size = UDim2.fromScale(value / 255, 1)
                channel.Value.Text = tostring(value)
            end
        end
        if hexInput and UI.ActiveHexInput ~= holder then
            hexInput.Text = string.format("#%02X%02X%02X", r, g, b)
        end
    end
    local function setChannel(index, value)
        local r, g, b = colorComponents()
        local valuesNow = {r, g, b}
        valuesNow[index] = math.clamp(math.round(value), 0, 255)
        currentColor = Color3.fromRGB(valuesNow[1], valuesNow[2], valuesNow[3])
        setter(currentColor)
        render()
    end
    for index, name in ipairs({"R", "G", "B"}) do
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Position = UDim2.fromOffset(9, 7 + (index - 1) * 27)
        row.Size = UDim2.new(1, -18, 0, 23)
        row.Parent = panel
        local label = textLabel(row, name, UDim2.fromOffset(18, 23), nil, 13, Theme.Text)
        label.FontFace = UI.Fonts.Heading
        local valueLabel = textLabel(row, "0", UDim2.fromOffset(32, 23), UDim2.new(1, -32, 0, 0), 12, Theme.Muted, Enum.TextXAlignment.Right)
        valueLabel.FontFace = UI.Fonts.Description
        local bar = Instance.new("Frame")
        bar.Active = true
        bar.BackgroundColor3 = Theme.Track
        bar.Position = UDim2.fromOffset(23, 8)
        bar.Size = UDim2.new(1, -62, 0, 7)
        bar.Parent = row
        UI.BindTheme(bar, "BackgroundColor3", "Track")
        round(bar, 4)
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = index == 1 and Color3.fromRGB(239, 88, 88) or index == 2 and Color3.fromRGB(79, 190, 116) or Color3.fromRGB(86, 139, 235)
        fill.Size = UDim2.fromScale(0, 1)
        fill.Parent = bar
        round(fill, 4)
        channels[index] = {Bar = bar, Fill = fill, Value = valueLabel}
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingChannel = index
                setChannel(index, (input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X) * 255)
            end
        end)
    end
    hexInput = Instance.new("TextBox")
    hexInput.Name = "HexInput"
    hexInput.BackgroundColor3 = Theme.Surface
    hexInput.ClearTextOnFocus = false
    hexInput.PlaceholderText = "#FFFFFF"
    hexInput.TextColor3 = Theme.Text
    hexInput.TextSize = 15
    hexInput.FontFace = UI.Fonts.Option
    hexInput.Position = UDim2.fromOffset(9, 89)
    hexInput.Size = UDim2.new(1, -18, 0, 27)
    hexInput.Parent = panel
    round(hexInput, 7)
    UI.BindTheme(hexInput, "BackgroundColor3", "Surface")
    UI.BindTheme(hexInput, "TextColor3", "Text")
    hexInput.Focused:Connect(function()
        UI.ActiveHexInput = holder
    end)
    hexInput.FocusLost:Connect(function()
        UI.ActiveHexInput = game
        local hex = string.match(hexInput.Text, "^#?(%x%x%x%x%x%x)$")
        if hex then
            local r = tonumber(string.sub(hex, 1, 2), 16)
            local g = tonumber(string.sub(hex, 3, 4), 16)
            local b = tonumber(string.sub(hex, 5, 6), 16)
            currentColor = Color3.fromRGB(r, g, b)
            setter(currentColor)
        end
        render()
    end)
    selector.Activated:Connect(function()
        panel.Visible = not panel.Visible
    end)
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if draggingChannel and input.UserInputType == Enum.UserInputType.MouseMovement then
            local channel = channels[draggingChannel]
            setChannel(draggingChannel, (input.Position.X - channel.Bar.AbsolutePosition.X) / math.max(1, channel.Bar.AbsoluteSize.X) * 255)
        end
    end))
    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingChannel = nil
        end
    end))
    local flag = UI.ControlFlag(card, text)
    local controller = UI.Register(flag, {
        Holder = holder,
        Get = getter,
        Render = render,
        Set = function(_, value)
            if typeof(value) == "Color3" then
                setter(value)
                render()
            end
        end
    })
    table.insert(controlRefreshers, render)
    render()
    return controller
end

local function addCycle(card, text, values, getter, setter)
    return UI.AddDropdown(card, text, values, getter, setter, false)
end

local categoryMeta = {
    Home = {Hint = "Home"},
    Aim = {Hint = "Aim"},
    Visuals = {Hint = "Visuals"},
    Movement = {Hint = "Movement"},
    World = {Hint = "World"},
    Players = {Hint = "Players"},
    Catalog = {Hint = "Catalog"},
    Misc = {Hint = "Misc"},
    Configs = {Hint = "Configs"}
}

local function iconPart(parent, x, y, width, height, rotation, radius)
    local part = Instance.new("Frame")
    part.AnchorPoint = Vector2.new(0.5, 0.5)
    part.BackgroundColor3 = Theme.Accent
    part.BorderSizePixel = 0
    part.Position = UDim2.fromOffset(x, y)
    part.Rotation = rotation or 0
    part.Size = UDim2.fromOffset(width, height)
    part.ZIndex = 2
    part.Parent = parent
    UI.BindTheme(part, "BackgroundColor3", "Accent")
    round(part, radius or math.min(width, height))
    return part
end

local function vectorIcon(parent, category)
    local canvas = Instance.new("Frame")
    canvas.Name = "VectorIcon"
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.fromOffset(28, 28)
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.Position = UDim2.fromScale(0.5, 0.5)
    canvas.ZIndex = 2
    canvas.Parent = parent
    if category == "Home" then
        iconPart(canvas, 14, 17, 14, 12, 0, 3)
        iconPart(canvas, 9, 11, 14, 3, 45, 2)
        iconPart(canvas, 19, 11, 14, 3, -45, 2)
        local door = iconPart(canvas, 14, 20, 4, 6, 0, 1)
        UI.BindTheme(door, "BackgroundColor3", "Surface")
    elseif category == "Aim" then
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.BackgroundTransparency = 1
        ring.Position = UDim2.fromOffset(14, 14)
        ring.Size = UDim2.fromOffset(20, 20)
        ring.ZIndex = 2
        ring.Parent = canvas
        round(ring, 20)
        stroke(ring, nil, 2, 0)
        iconPart(canvas, 14, 14, 5, 5, 0, 5)
        iconPart(canvas, 14, 2.5, 2, 5, 0, 1)
        iconPart(canvas, 14, 25.5, 2, 5, 0, 1)
        iconPart(canvas, 2.5, 14, 5, 2, 0, 1)
        iconPart(canvas, 25.5, 14, 5, 2, 0, 1)
    elseif category == "Visuals" then
        local eye = Instance.new("Frame")
        eye.AnchorPoint = Vector2.new(0.5, 0.5)
        eye.BackgroundTransparency = 1
        eye.Position = UDim2.fromOffset(14, 14)
        eye.Size = UDim2.fromOffset(25, 14)
        eye.ZIndex = 2
        eye.Parent = canvas
        round(eye, 14)
        stroke(eye, nil, 2, 0)
        iconPart(canvas, 14, 14, 7, 7, 0, 7)
    elseif category == "Movement" then
        iconPart(canvas, 9, 8, 12, 3, 45, 2)
        iconPart(canvas, 9, 14, 12, 3, -45, 2)
        iconPart(canvas, 18, 14, 12, 3, 45, 2)
        iconPart(canvas, 18, 20, 12, 3, -45, 2)
    elseif category == "World" then
        local globe = Instance.new("Frame")
        globe.AnchorPoint = Vector2.new(0.5, 0.5)
        globe.BackgroundTransparency = 1
        globe.Position = UDim2.fromOffset(14, 14)
        globe.Size = UDim2.fromOffset(22, 22)
        globe.ZIndex = 2
        globe.Parent = canvas
        round(globe, 22)
        stroke(globe, nil, 2, 0)
        iconPart(canvas, 14, 14, 2, 20, 0, 1)
        iconPart(canvas, 14, 14, 20, 2, 0, 1)
        iconPart(canvas, 14, 14, 12, 22, 0, 12).BackgroundTransparency = 1
    elseif category == "Players" then
        iconPart(canvas, 14, 8, 9, 9, 0, 9)
        iconPart(canvas, 14, 20, 18, 10, 0, 7)
        iconPart(canvas, 4, 21, 5, 3, 0, 2)
        iconPart(canvas, 24, 21, 5, 3, 0, 2)
    elseif category == "Catalog" then
        for _, point in ipairs({{8, 8}, {20, 8}, {8, 20}, {20, 20}}) do
            iconPart(canvas, point[1], point[2], 8, 8, 0, 2)
        end
    elseif category == "Misc" then
        iconPart(canvas, 7, 7, 5, 5, 0, 5)
        iconPart(canvas, 21, 14, 5, 5, 0, 5)
        iconPart(canvas, 21, 23, 5, 5, 0, 5)
        iconPart(canvas, 12, 10.5, 10, 2, 0, 1)
        iconPart(canvas, 16, 18.5, 2, 17, 0, 1)
        iconPart(canvas, 19, 14, 6, 2, 0, 1)
        iconPart(canvas, 19, 23, 6, 2, 0, 1)
    elseif category == "Configs" then
        for index, y in ipairs({7, 14, 21}) do
            iconPart(canvas, 14, y, 21, 2, 0, 1)
            iconPart(canvas, index == 1 and 9 or index == 2 and 18 or 12, y, 5, 5, 0, 5)
        end
    elseif category == "Settings" then
        iconPart(canvas, 14, 14, 10, 10, 0, 10)
        for _, point in ipairs({{14, 3}, {14, 25}, {3, 14}, {25, 14}, {6, 6}, {22, 22}, {22, 6}, {6, 22}}) do
            iconPart(canvas, point[1], point[2], 4, 4, 0, 1)
        end
        local hole = iconPart(canvas, 14, 14, 4, 4, 0, 4)
        UI.BindTheme(hole, "BackgroundColor3", "Surface")
    end
    return canvas
end

UI.ApplyCategoryIcon = function(categoryButton, category, url)
    local oldVector = categoryButton:FindFirstChild("VectorIcon")
    local oldImage = categoryButton:FindFirstChild("CategoryImage")
    local oldBackground = categoryButton:FindFirstChild("CategoryIconBackground")
    if oldVector then oldVector:Destroy() end
    if oldImage then oldImage:Destroy() end
    if oldBackground then oldBackground:Destroy() end
    if type(url) ~= "string" or url == "" then
        vectorIcon(categoryButton, category)
        return
    end
    ensureFolder("TasuHub/Icons")
    local iconBackground = Instance.new("Frame")
    iconBackground.Name = "CategoryIconBackground"
    iconBackground.AnchorPoint = Vector2.new(0.5, 0.5)
    iconBackground.BackgroundTransparency = 0.06
    iconBackground.BorderSizePixel = 0
    iconBackground.Position = UDim2.fromScale(0.5, 0.5)
    iconBackground.Size = UDim2.fromOffset(36, 36)
    iconBackground.ZIndex = 2
    iconBackground.Parent = categoryButton
    round(iconBackground, 9)
    local backgroundSetting = UI.CategoryIconBackgrounds[category]
    if typeof(backgroundSetting) == "Color3" then
        iconBackground.BackgroundColor3 = backgroundSetting
    else
        local token = type(backgroundSetting) == "string" and Theme[backgroundSetting] and backgroundSetting or "AccentSoft"
        UI.BindTheme(iconBackground, "BackgroundColor3", token)
    end
    local image = Instance.new("ImageLabel")
    image.Name = "CategoryImage"
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.BackgroundTransparency = 1
    image.Image = loadRemoteAsset(url, "TasuHub/Icons/" .. category .. ".png") or url
    image.Position = UDim2.fromScale(0.5, 0.5)
    image.ScaleType = Enum.ScaleType.Fit
    image.Size = UDim2.fromOffset(27, 27)
    image.ZIndex = 3
    image.Parent = iconBackground
end

local categories = {"Home", "Catalog", "Players", "Visuals", "Aim", "Movement", "World", "Misc", "Configs"}
local CategoryTooltip = Instance.new("TextLabel")
CategoryTooltip.BackgroundColor3 = Color3.fromRGB(44, 83, 120)
CategoryTooltip.BackgroundTransparency = 1
CategoryTooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
CategoryTooltip.TextTransparency = 1
CategoryTooltip.TextSize = 15
CategoryTooltip.FontFace = UI.Fonts.Description
CategoryTooltip.TextXAlignment = Enum.TextXAlignment.Center
CategoryTooltip.TextYAlignment = Enum.TextYAlignment.Center
CategoryTooltip.Visible = false
CategoryTooltip.ZIndex = 20
CategoryTooltip.Size = UDim2.fromOffset(138, 26)
CategoryTooltip.Parent = LegacyUIRoot
round(CategoryTooltip, 7)
UI.BindTheme(CategoryTooltip, "BackgroundColor3", "Text")
UI.BindTheme(CategoryTooltip, "TextColor3", "Surface")
local tooltipTransition = 0
local function positionCategoryTooltip(categoryButton, verticalOffset)
    local canvas = getCanvasSize()
    local rootPosition = InterfaceRoot.AbsolutePosition
    local buttonPosition = categoryButton.AbsolutePosition
    local x = buttonPosition.X - rootPosition.X + categoryButton.AbsoluteSize.X * 0.5 - CategoryTooltip.AbsoluteSize.X * 0.5
    local y = buttonPosition.Y - rootPosition.Y - CategoryTooltip.AbsoluteSize.Y - 8 + (verticalOffset or 0)
    if y < 0 then
        y = buttonPosition.Y - rootPosition.Y + categoryButton.AbsoluteSize.Y + 8 + (verticalOffset or 0)
    end
    return UDim2.fromOffset(math.clamp(x, 0, math.max(0, canvas.X - CategoryTooltip.AbsoluteSize.X)), y)
end
local function showCategoryTooltip(text, categoryButton)
    tooltipTransition = tooltipTransition + 1
    CategoryTooltip.Text = text
    CategoryTooltip.Visible = true
    CategoryTooltip.BackgroundTransparency = 1
    CategoryTooltip.TextTransparency = 1
    CategoryTooltip.Position = positionCategoryTooltip(categoryButton, 5)
    animate(CategoryTooltip, {BackgroundTransparency = 0.04, TextTransparency = 0, Position = positionCategoryTooltip(categoryButton, 0)}, 0.26, Enum.EasingStyle.Quint)
end
local function hideCategoryTooltip()
    tooltipTransition = tooltipTransition + 1
    local transition = tooltipTransition
    animate(CategoryTooltip, {BackgroundTransparency = 1, TextTransparency = 1, Position = CategoryTooltip.Position + UDim2.fromOffset(0, 4)}, 0.22, Enum.EasingStyle.Quint)
    task.delay(0.22, function()
        if transition == tooltipTransition and CategoryTooltip.Parent then
            CategoryTooltip.Visible = false
        end
    end)
end
for index, name in ipairs(categories) do
    createPage(name)
    local categoryButton = button(CategoryScroller, "", UDim2.fromOffset(48, 48))
    categoryButton.Name = name .. "Button"
    categoryButton.LayoutOrder = index
    categoryButtons[name] = categoryButton
    local selectedOutline = stroke(categoryButton, Color3.fromRGB(0, 0, 0), 1.5, 0)
    selectedOutline.Enabled = false
    categoryOutlines[name] = selectedOutline
    categoryButton:SetAttribute("CategoryIcon", name)
    UI.ApplyCategoryIcon(categoryButton, name, UI.CategoryIconUrls[name])
    categoryButton.MouseEnter:Connect(function()
        showCategoryTooltip(categoryMeta[name].Hint, categoryButton)
    end)
    categoryButton.MouseLeave:Connect(function()
        hideCategoryTooltip()
    end)
end


UI.SetCategoryIcon = function(category, url, background)
    if not categoryButtons[category] then return false end
    UI.CategoryIconUrls[category] = tostring(url or "")
    if background ~= nil then
        UI.CategoryIconBackgrounds[category] = background
    end
    for _, target in ipairs(InterfaceRoot:GetDescendants()) do
        if target:GetAttribute("CategoryIcon") == category then
            UI.ApplyCategoryIcon(target, category, UI.CategoryIconUrls[category])
        end
    end
    return true
end

UI.SetCategoryIconBackground = function(category, background)
    if not categoryButtons[category] then return false end
    if typeof(background) ~= "Color3" and (type(background) ~= "string" or Theme[background] == nil) then
        return false
    end
    UI.CategoryIconBackgrounds[category] = background
    for _, target in ipairs(InterfaceRoot:GetDescendants()) do
        if target:GetAttribute("CategoryIcon") == category then
            UI.ApplyCategoryIcon(target, category, UI.CategoryIconUrls[category])
        end
    end
    return true
end

UI.RefreshNavigation = function()
    for name, categoryButton in pairs(categoryButtons) do
        categoryButton.BackgroundColor3 = name == currentCategory and Theme.AccentSoft or Theme.Surface2
    end
end

UI.GlobalSearchResults = Instance.new("CanvasGroup")
UI.GlobalSearchResults.Name = "GlobalSearchResults"
UI.GlobalSearchResults.BackgroundColor3 = Theme.Surface
UI.GlobalSearchResults.BackgroundTransparency = 0.04
UI.GlobalSearchResults.ClipsDescendants = true
UI.GlobalSearchResults.GroupTransparency = 1
UI.GlobalSearchResults.Size = UDim2.fromOffset(224, 0)
UI.GlobalSearchResults.Visible = false
UI.GlobalSearchResults.ZIndex = 45
UI.GlobalSearchResults.Parent = LegacyUIRoot
UI.BindTheme(UI.GlobalSearchResults, "BackgroundColor3", "Surface")
round(UI.GlobalSearchResults, 11)
gradient(UI.GlobalSearchResults, "Surface", "Surface2", 90)
UI.GlobalSearchList = Instance.new("ScrollingFrame")
UI.GlobalSearchList.BackgroundTransparency = 1
UI.GlobalSearchList.BorderSizePixel = 0
UI.GlobalSearchList.CanvasSize = UDim2.new()
UI.GlobalSearchList.AutomaticCanvasSize = Enum.AutomaticSize.Y
UI.GlobalSearchList.ScrollBarThickness = 3
UI.GlobalSearchList.ScrollBarImageColor3 = Theme.Accent
UI.GlobalSearchList.Size = UDim2.fromScale(1, 1)
UI.GlobalSearchList.ZIndex = 46
UI.GlobalSearchList.Parent = UI.GlobalSearchResults
UI.BindTheme(UI.GlobalSearchList, "ScrollBarImageColor3", "Accent")
UI.GlobalSearchLayout = Instance.new("UIListLayout")
UI.GlobalSearchLayout.Padding = UDim.new(0, 5)
UI.GlobalSearchLayout.SortOrder = Enum.SortOrder.LayoutOrder
UI.GlobalSearchLayout.Parent = UI.GlobalSearchList
UI.GlobalSearchListPadding = Instance.new("UIPadding")
UI.GlobalSearchListPadding.PaddingLeft = UDim.new(0, 6)
UI.GlobalSearchListPadding.PaddingRight = UDim.new(0, 8)
UI.GlobalSearchListPadding.PaddingTop = UDim.new(0, 6)
UI.GlobalSearchListPadding.PaddingBottom = UDim.new(0, 6)
UI.GlobalSearchListPadding.Parent = UI.GlobalSearchList

UI.SetLoading(0.44, "Özellikler hazırlanıyor")

local windowTransition = 0

local function placeContentWindow()
    local canvas = getCanvasSize()
    local barPosition = getLocalPosition(TopBar)
    local barSize = TopBar.AbsoluteSize
    local positioningWidth = math.min(barSize.X, UI.TopBarBaseWidth)
    local windowSize = ContentWindow.AbsoluteSize
    if windowSize.X <= 0 or windowSize.Y <= 0 then
        windowSize = Vector2.new(ContentWindow.Size.X.Offset, ContentWindow.Size.Y.Offset)
    end
    local opensBelow = barPosition.Y + barSize.Y * 0.5 < canvas.Y * 0.5
    local x = math.clamp(barPosition.X + positioningWidth * 0.5 - windowSize.X * 0.5, 0, math.max(0, canvas.X - windowSize.X))
    local y = opensBelow and barPosition.Y + barSize.Y + 12 or barPosition.Y - windowSize.Y - 12
    if y < 0 then
        opensBelow = true
        y = math.max(0, math.min(canvas.Y - windowSize.Y, barPosition.Y + barSize.Y + 12))
    elseif y + windowSize.Y > canvas.Y then
        opensBelow = false
        y = math.max(0, barPosition.Y - windowSize.Y - 12)
    end
    local targetPosition = UDim2.fromOffset(x, y)
    local entranceOffset = opensBelow and -10 or 10
    ContentWindow.Position = UDim2.new(
        targetPosition.X.Scale,
        targetPosition.X.Offset,
        targetPosition.Y.Scale,
        targetPosition.Y.Offset + entranceOffset
    )
    animate(ContentWindow, {Position = targetPosition}, 0.22, Enum.EasingStyle.Quint)
end

local function openContentWindow()
    if not UI.LegacyUIEnabled then return false end
    windowTransition = windowTransition + 1
    if not ContentWindow.Visible then
        placeContentWindow()
        ContentWindow.GroupTransparency = 1
        ContentScale.Scale = 0.9
        ContentShadowScale.Scale = 0.9
        ContentWindow.Visible = true
        animate(ContentWindow, {GroupTransparency = 0}, 0.34, Enum.EasingStyle.Quint)
        animate(ContentScale, {Scale = 1}, 0.42, Enum.EasingStyle.Quint)
    else
        animate(ContentWindow, {GroupTransparency = 0}, 0.24, Enum.EasingStyle.Quint)
        animate(ContentScale, {Scale = 1}, 0.28, Enum.EasingStyle.Quint)
    end
    task.defer(UI.RefreshVisualPreview)
end

local function closeContentWindow()
    if not ContentWindow.Visible then return end
    UI.CloseActiveDropdown()
    windowTransition = windowTransition + 1
    local transition = windowTransition
    UI.ActiveCategory = nil
    for buttonName, item in pairs(categoryButtons) do
        item:SetAttribute("Selected", false)
        animate(item, {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text}, 0.12)
        if categoryOutlines[buttonName] then categoryOutlines[buttonName].Enabled = false end
    end
    local exitPosition = ContentWindow.Position + UDim2.fromOffset(0, 12)
    animate(ContentWindow, {GroupTransparency = 1, Position = exitPosition}, 0.3, Enum.EasingStyle.Quint)
    animate(ContentScale, {Scale = 0.92}, 0.32, Enum.EasingStyle.Quint)
    task.delay(0.32, function()
        if transition == windowTransition and ContentWindow and ContentWindow.Parent then
            ContentWindow.Visible = false
            ContentScale.Scale = 1
            ContentWindow.GroupTransparency = 0
        end
    end)
    task.defer(UI.RefreshVisualPreview)
end

local function showCategory(name)
    if not UI.LegacyUIEnabled or not UI.Ready or not pages[name] or name == "SearchResults" then
        return
    end
    UI.CloseActiveDropdown()
    currentCategory = name
    UI.ActiveCategory = name
    UI.SearchMode = false
    openContentWindow()
    WindowTitle.Text = name
    for pageName, page in pairs(pages) do
        local selected = pageName == name
        page.Visible = selected
        if selected and pageScales[pageName] then
            pageScales[pageName].Scale = 0.975
            animate(pageScales[pageName], {Scale = 1}, 0.18, Enum.EasingStyle.Quint)
        end
    end
    for buttonName, item in pairs(categoryButtons) do
        local selected = buttonName == name
        item:SetAttribute("Selected", selected)
        animate(item, {BackgroundColor3 = selected and Theme.AccentSoft or Theme.Surface2, TextColor3 = Theme.Text}, 0.16)
        if categoryOutlines[buttonName] then
            categoryOutlines[buttonName].Enabled = selected
            if selected then animate(categoryOutlines[buttonName], {Thickness = 2.25, Transparency = 0}, 0.16) end
        end
    end
    task.defer(UI.RefreshVisualPreview)
end

UI.ShowCategory = showCategory
UI.OpenContentWindow = openContentWindow
UI.CloseContentWindow = closeContentWindow

UI.RebuildGlobalSearch = function(rawQuery)
    local query = string.lower((tostring(rawQuery or ""):gsub("^%s+", ""):gsub("%s+$", "")))
    UI.GlobalSearchList.CanvasPosition = Vector2.zero
    for _, child in ipairs(UI.GlobalSearchList:GetChildren()) do
        if child.Name == "IndexedResult" then
            child:Destroy()
        end
    end
    if query == "" then
        UI.GlobalSearchResults.Visible = false
        UI.GlobalSearchResults.GroupTransparency = 1
        UI.GlobalSearchResults.Size = UDim2.fromOffset(224, 0)
        return
    end
    local matches = {}
    for _, category in ipairs(categories) do
        local hint = categoryMeta[category] and categoryMeta[category].Hint or category
        if string.find(string.lower(category .. " " .. hint), query, 1, true) then
            table.insert(matches, {Flag = category, Category = category, Type = "Category", Priority = 1})
        end
    end
    for body in pairs(UI.AccordionOpeners) do
        local category = body:GetAttribute("CategoryName")
        local cardName = body:GetAttribute("CardName")
        if category and cardName and string.find(string.lower(category .. " " .. cardName), query, 1, true) then
            table.insert(matches, {Flag = category .. "/" .. cardName, Category = category, CardName = cardName, Instance = body, Type = "Section", Priority = 2})
        end
    end
    for catalogIndex, entry in ipairs(State.Catalog) do
        local catalogName = tostring(entry.Name or "Untitled")
        local catalogPlace = tostring(entry.PlaceId or "")
        local catalogId = tostring(entry.BuiltInId or "")
        if string.find(string.lower(catalogName .. " " .. catalogPlace .. " " .. catalogId .. " catalog game script"), query, 1, true) then
            table.insert(matches, {
                Flag = "Catalog/" .. catalogName,
                Category = "Catalog",
                CatalogIndex = catalogIndex,
                CatalogName = catalogName,
                Type = "CatalogGame",
                Priority = 2
            })
        end
    end
    for flag, control in pairs(UI.Controls) do
        local searchable = string.lower(flag)
        local instance = control.Instance or control.Holder or control.Row
        if instance and instance:IsA("TextBox") then
            searchable = searchable .. " " .. string.lower(instance.PlaceholderText)
        elseif instance and instance:IsA("TextButton") then
            searchable = searchable .. " " .. string.lower(instance.Text)
        end
        if string.find(searchable, query, 1, true) then
            table.insert(matches, {Flag = flag, Control = control, Instance = instance, Type = "Option", Priority = 3})
        end
    end
    table.sort(matches, function(first, second)
        return first.Priority == second.Priority and first.Flag < second.Flag or first.Priority < second.Priority
    end)
    if #matches == 0 then
        UI.GlobalSearchResults.Visible = false
        return
    end
    for index, match in ipairs(matches) do
        local category, cardName, optionName = string.match(match.Flag, "^([^/]+)/([^/]+)/(.+)$")
        category = match.Category or category or "Unknown"
        cardName = match.CardName or cardName or "Settings"
        optionName = optionName or match.Flag
        local displayText
        if match.Type == "Category" then
            displayText = "CATEGORY\n" .. (categoryMeta[category] and categoryMeta[category].Hint or category)
        elseif match.Type == "Section" then
            displayText = "SECTION\n" .. category .. "  ›  " .. cardName
        elseif match.Type == "CatalogGame" then
            displayText = "CATALOG GAME\n" .. tostring(match.CatalogName or optionName)
        else
            displayText = optionName .. "\n" .. category .. "  ›  " .. cardName
        end
        local resultButton = button(UI.GlobalSearchList, displayText, UDim2.new(1, -4, 0, 56))
        resultButton.Name = "IndexedResult"
        resultButton.LayoutOrder = index
        if match.Type == "Category" then
            resultButton.TextSize = 20
            resultButton.FontFace = UI.Fonts.HeadingHeavy
            resultButton.TextColor3 = Theme.Accent
            UI.BindTheme(resultButton, "TextColor3", "Accent")
        elseif match.Type == "Section" then
            resultButton.TextSize = 19
            resultButton.FontFace = UI.Fonts.HeadingHeavy
            resultButton.TextColor3 = Theme.Section
            UI.BindTheme(resultButton, "TextColor3", "Section")
        elseif match.Type == "CatalogGame" then
            resultButton.TextSize = 18
            resultButton.FontFace = UI.Fonts.HeadingHeavy
            resultButton.TextColor3 = Theme.Muted
            UI.BindTheme(resultButton, "TextColor3", "Muted")
        else
            resultButton.TextSize = 16
        end
        resultButton.TextWrapped = true
        resultButton.TextXAlignment = Enum.TextXAlignment.Left
        resultButton.ZIndex = 47
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = resultButton
        resultButton.Activated:Connect(function()
            UI.GlobalSearchResults.Visible = false
            showCategory(category)
            if match.Type == "Category" or match.Type == "CatalogGame" then return end
            if match.Type == "Section" then
                local opener = UI.AccordionOpeners[match.Instance]
                if opener then opener(true) end
                return
            end
            task.defer(function()
                local page = pages[category]
                local target = match.Instance
                if page and target and target.Parent then
                    local ancestor = target
                    while ancestor and ancestor ~= page do
                        if ancestor:GetAttribute("IsAccordionBody") then
                            local opener = UI.AccordionOpeners[ancestor]
                            if opener then opener(true) end
                            task.wait(0.42)
                            break
                        end
                        ancestor = ancestor.Parent
                    end
                    page.CanvasPosition = Vector2.new(0, math.max(0, target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 18))
                    local original = target.BackgroundTransparency
                    pcall(function()
                        target.BackgroundTransparency = math.min(original, 0.15)
                        animate(target, {BackgroundTransparency = original}, 0.7)
                    end)
                end
            end)
        end)
    end
    local visibleCount = math.min(5, #matches)
    local targetHeight = visibleCount * 56 + math.max(0, visibleCount - 1) * 5 + 12
    UI.GlobalSearchResults.Visible = true
    UI.GlobalSearchResults.GroupTransparency = 1
    UI.GlobalSearchResults.Size = UDim2.fromOffset(224, 0)
    animate(UI.GlobalSearchResults, {Size = UDim2.fromOffset(224, targetHeight), GroupTransparency = 0}, 0.34, Enum.EasingStyle.Quint)
end

UI.CloseGlobalSearch = function(force)
    if not UI.GlobalSearchOpen then return end
    if not force and UI.GlobalSearchBox.Text:gsub("%s", "") ~= "" then return end
    UI.GlobalSearchOpen = false
    if force then UI.GlobalSearchBox.Text = "" end
    UI.GlobalSearchResults.Visible = false
    animate(UI.GlobalSearchClip, {Size = UDim2.fromOffset(0, 30)}, 0.3, Enum.EasingStyle.Quint)
    animate(UI.VersionLabel, {TextTransparency = 0}, 0.3, Enum.EasingStyle.Quint)
    if not topBarCollapsed then
        animate(TopBar, {Size = UDim2.fromOffset(UI.TopBarBaseWidth, 58)}, 0.34, Enum.EasingStyle.Quint)
    end
    task.delay(0.31, function()
        if not UI.GlobalSearchOpen and UI.GlobalSearchClip.Parent then
            UI.GlobalSearchClip.Visible = false
        end
    end)
end

UI.OpenGlobalSearch = function()
    if not UI.LegacyUIEnabled or not UI.Ready or topBarCollapsed then return false end
    if not UI.GlobalSearchOpen then
        UI.GlobalSearchOpen = true
        UI.GlobalSearchClip.Visible = true
        animate(UI.VersionLabel, {TextTransparency = 1}, 0.22, Enum.EasingStyle.Quint)
        animate(TopBar, {Size = UDim2.fromOffset(UI.TopBarBaseWidth + 150, 58)}, 0.38, Enum.EasingStyle.Quint)
        animate(UI.GlobalSearchClip, {Size = UDim2.fromOffset(224, 30)}, 0.38, Enum.EasingStyle.Quint)
    end
end

UI.ScheduleSearchHoverClose = function()
    task.delay(0.08, function()
        if UI.GlobalSearchOpen and not UI.GlobalSearchPointerInside and not UI.GlobalSearchBox:IsFocused() and UI.GlobalSearchBox.Text:gsub("%s", "") == "" then
            UI.CloseGlobalSearch(false)
        end
    end)
end
UI.GlobalSearchButton.MouseEnter:Connect(function()
    UI.GlobalSearchPointerInside = true
    UI.OpenGlobalSearch()
end)
UI.GlobalSearchButton.MouseLeave:Connect(function()
    UI.GlobalSearchPointerInside = false
    UI.ScheduleSearchHoverClose()
end)
UI.GlobalSearchClip.MouseEnter:Connect(function()
    UI.GlobalSearchPointerInside = true
end)
UI.GlobalSearchClip.MouseLeave:Connect(function()
    UI.GlobalSearchPointerInside = false
    UI.ScheduleSearchHoverClose()
end)
UI.GlobalSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    UI.RebuildGlobalSearch(UI.GlobalSearchBox.Text)
end)
UI.GlobalSearchBox.Focused:Connect(function()
    UI.RebuildGlobalSearch(UI.GlobalSearchBox.Text)
end)
UI.GlobalSearchBox.FocusLost:Connect(function()
    UI.ScheduleSearchHoverClose()
end)

for name, item in pairs(categoryButtons) do
    local categoryName = name
    local categoryButton = item
    categoryButton.Activated:Connect(function()
        if currentCategory == categoryName and ContentWindow.Visible then
            closeContentWindow()
        else
            showCategory(categoryName)
        end
    end)
end

CloseButton.Activated:Connect(function()
    closeContentWindow()
end)

trackConnection(RunService.RenderStepped:Connect(function()
    if UI.LegacyUIEnabled and UI.Ready and not TopBar.Visible then TopBar.Visible = true end
    if not ScreenGui.Enabled then ScreenGui.Enabled = true end
    keepGuiOnScreen(TopBar)
    if UI.GlobalSearchResults.Visible then
        local barPosition = getLocalPosition(TopBar)
        UI.GlobalSearchResults.Position = UDim2.fromOffset(barPosition.X + 703, barPosition.Y + 64)
    end
    if ContentWindow.Visible then
        keepGuiOnScreen(ContentWindow)
    end
end))

local FOVCircle = Instance.new("Frame")
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.ZIndex = 3
FOVCircle.Parent = InterfaceRoot
round(FOVCircle, 1000)
local FOVStroke = stroke(FOVCircle, nil, 1, 0.15)

local function isVisibleTarget(character, targetPart)
    if not State.Aim.WallCheck then
        return true
    end
    local camera = Workspace.CurrentCamera
    local localCharacter = LocalPlayer.Character
    if not camera or not targetPart then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {localCharacter, camera}
    params.IgnoreWater = true
    local direction = targetPart.Position - camera.CFrame.Position
    local result = Workspace:Raycast(camera.CFrame.Position, direction, params)
    return not result or result.Instance:IsDescendantOf(character)
end

local function chooseTarget()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    local mousePosition = getMousePosition()
    local best
    local rage = State.Aim.Rage
    local bestScore = rage and math.huge or State.Aim.FOV
    local _, _, localRoot = getCharacter(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local alive, character, humanoid, root = getAlive(player)
            if UI.AimDiscardedCharacters[player] and UI.AimDiscardedCharacters[player] ~= character then
                UI.AimDiscardedCharacters[player] = nil
            end
            if alive and UI.AimDiscardedCharacters[player] ~= character and (rage or not State.Aim.TeamCheck or not areTeammates(player, LocalPlayer)) then
                local targetPart = character:FindFirstChild(rage and "Head" or State.Aim.TargetPart) or character:FindFirstChild("Head") or root
                if targetPart then
                    local worldDistance = localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
                    local screen, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screen.Z > 0 and (rage or worldDistance <= State.Aim.MaxDistance) then
                        local score = (Vector2.new(screen.X, screen.Y) - mousePosition).Magnitude
                        if score < bestScore and isVisibleTarget(character, targetPart) then
                            bestScore = score
                            best = {Player = player, Character = character, Humanoid = humanoid, Root = root, Part = targetPart, LastPosition = root.Position}
                        end
                    end
                end
            end
        end
    end
    return best
end

local currentTarget
local mousemoverel = resolveGlobal("mousemoverel")
trackFeature("Aim", RunService.RenderStepped:Connect(function(deltaTime)
    local mousePosition = getMousePosition()
    local cursorPosition = UserInputService:GetMouseLocation()
    FOVStroke.Color = State.World.RGB.Aim.Enabled and getRGBColor("Aim", 0) or Theme.Accent
    local diameter = State.Aim.FOV * 2
    FOVCircle.Size = UDim2.fromOffset(diameter, diameter)
    FOVCircle.Position = UDim2.fromOffset(cursorPosition.X, cursorPosition.Y)
    FOVCircle.Visible = State.Aim.Enabled and State.Aim.ShowFOV
    if not State.Aim.Enabled then
        currentTarget = nil
        return
    end
    local activation = State.Aim.Activation or (State.Aim.HoldRightMouse and "Right Mouse" or "Always")
    local held = activation == "Always"
        or activation == "Right Mouse" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        or activation == "Left Mouse" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if not held then
        currentTarget = nil
        return
    end
    if currentTarget then
        local alive, character, humanoid, root = getAlive(currentTarget.Player)
        local _, _, localRoot = getCharacter(LocalPlayer)
        local state = humanoid and humanoid:GetState()
        local tooFar = root and localRoot and (root.Position - localRoot.Position).Magnitude > math.max(State.Aim.MaxDistance * 1.5, 3000)
        local belowWorld = root and root.Position.Y < Workspace.FallenPartsDestroyHeight + 80
        local deathTeleport = root and currentTarget.LastPosition and (root.Position - currentTarget.LastPosition).Magnitude > 450
        local invalidState = state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.None
        if alive and character == currentTarget.Character and character:IsDescendantOf(Workspace) and not tooFar and not belowWorld and not deathTeleport and not invalidState then
            currentTarget.Humanoid = humanoid
            currentTarget.Root = root
            currentTarget.Part = character:FindFirstChild(State.Aim.Rage and "Head" or State.Aim.TargetPart) or character:FindFirstChild("Head") or root
            currentTarget.LastPosition = root.Position
            currentTarget.Occluded = not isVisibleTarget(character, currentTarget.Part)
        else
            UI.AimDiscardedCharacters[currentTarget.Player] = currentTarget.Character
            currentTarget = nil
        end
    end
    if not currentTarget then currentTarget = chooseTarget() end
    local camera = Workspace.CurrentCamera
    if not currentTarget or not camera then
        return
    end
    if currentTarget.Occluded then
        return
    end
    local aimPosition = currentTarget.Part.Position
    if State.Aim.Rage or State.Aim.Prediction then
        aimPosition = aimPosition + currentTarget.Root.AssemblyLinearVelocity * (State.Aim.Rage and 0.15 or State.Aim.PredictionTime)
    end
    if State.Aim.Method == "Mouse" and type(mousemoverel) == "function" then
        local screen = camera:WorldToViewportPoint(aimPosition)
        local delta = Vector2.new(screen.X, screen.Y) - mousePosition
        local factor = State.Aim.Rage and 1 or math.clamp(1 - State.Aim.Smoothing, 0.02, 1)
        pcall(mousemoverel, delta.X * factor, delta.Y * factor)
    else
        local goal = CFrame.lookAt(camera.CFrame.Position, aimPosition)
        local factor = State.Aim.Rage and 1 or math.clamp((1 - State.Aim.Smoothing) * deltaTime * 60, 0.01, 1)
        camera.CFrame = camera.CFrame:Lerp(goal, factor)
    end
end))

local espRecords = {}

local function newLine(parent, color)
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = color or Theme.Accent
    line.Size = UDim2.fromOffset(0, State.Visuals.Thickness)
    line.Visible = false
    line.ZIndex = 2
    line.Parent = parent
    return line
end

local function setLine(line, from, to, thickness)
    local difference = to - from
    local length = difference.Magnitude
    local center = (from + to) * 0.5
    line.Position = UDim2.fromOffset(center.X, center.Y)
    line.Size = UDim2.fromOffset(length, thickness or 1)
    line.Rotation = math.deg(math.atan2(difference.Y, difference.X))
    line.Visible = true
end

local function getBoundingScreenBox(character, camera, viewportOverride, partOverride)
    local minimumX, minimumY = math.huge, math.huge
    local maximumX, maximumY = -math.huge, -math.huge
    local visibleCorners = 0
    for _, part in ipairs(partOverride or character:GetDescendants()) do
        if part:IsA("BasePart") and part:IsDescendantOf(character) and not part:FindFirstAncestorOfClass("Accessory") and not part:FindFirstAncestorOfClass("Tool") then
            local half = part.Size * 0.5
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local point = part.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
                        local screen
                        if camera == Workspace.CurrentCamera then
                            screen = camera:WorldToScreenPoint(point)
                        else
                            screen = camera:WorldToViewportPoint(point)
                        end
                        if screen.Z > 0 then
                            visibleCorners = visibleCorners + 1
                            minimumX = math.min(minimumX, screen.X)
                            minimumY = math.min(minimumY, screen.Y)
                            maximumX = math.max(maximumX, screen.X)
                            maximumY = math.max(maximumY, screen.Y)
                        end
                    end
                end
            end
        end
    end
    if visibleCorners == 0 then return nil end
    local viewport = viewportOverride or (camera == Workspace.CurrentCamera and getCanvasSize() or camera.ViewportSize)
    if maximumX < 0 or minimumX > viewport.X or maximumY < 0 or minimumY > viewport.Y then return nil end
    local left = math.clamp(minimumX, 0, viewport.X)
    local right = math.clamp(maximumX, 0, viewport.X)
    local top = math.clamp(minimumY, 0, viewport.Y)
    local bottom = math.clamp(maximumY, 0, viewport.Y)
    if right - left < 2 or bottom - top < 2 then return nil end
    return left, right, top, bottom
end

local function destroyESP(player)
    local record = espRecords[player]
    if not record then
        return
    end
    for _, object in pairs(record) do
        if typeof(object) == "Instance" then
            pcall(function()
                object:Destroy()
            end)
        end
    end
    espRecords[player] = nil
end

local function createESP(player)
    destroyESP(player)
    local record = {
        Tracer = newLine(ScreenGui),
        SkeletonLayer = Instance.new("Frame"),
        SkeletonLines = {},
        Arrow = textLabel(ScreenGui, "▲", UDim2.fromOffset(32, 32), nil, 28, Theme.Accent, Enum.TextXAlignment.Center),
        Highlight = Instance.new("Highlight")
    }
    record.SkeletonLayer.BackgroundTransparency = 1
    record.SkeletonLayer.Size = UDim2.fromScale(1, 1)
    record.SkeletonLayer.Visible = false
    record.SkeletonLayer.ZIndex = 2
    record.SkeletonLayer.Parent = ScreenGui
    for _ = 1, 15 do
        table.insert(record.SkeletonLines, newLine(record.SkeletonLayer))
    end
    record.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    record.Arrow.TextStrokeColor3 = Color3.fromRGB(8, 12, 18)
    record.Arrow.TextStrokeTransparency = 0.15
    record.Arrow.Visible = false
    record.Arrow.ZIndex = 4
    record.Highlight.FillColor = Theme.Accent
    record.Highlight.OutlineColor = Theme.Text
    record.Highlight.FillTransparency = 0.75
    record.Highlight.OutlineTransparency = 0.1
    record.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    record.Highlight.Enabled = false
    record.Highlight.Parent = ScreenGui
    espRecords[player] = record
    return record
end

local function ensureWorldESP(record, character, root)
    if record.WorldCharacter == character and record.BoxProxy and record.BoxProxy.Parent then return end
    for _, key in ipairs({"BoxProxy", "NameBillboard", "HealthBillboard", "HeadAdornment"}) do
        local object = record[key]
        if object then pcall(function() object:Destroy() end) end
        record[key] = nil
    end
    local boundsCFrame, boundsSize = character:GetBoundingBox()
    local proxy = Instance.new("Part")
    proxy.Name = "TasuESPBounds"
    proxy.Size = boundsSize + Vector3.new(0.18, 0.18, 0.18)
    proxy.CFrame = boundsCFrame
    proxy.Transparency = 1
    proxy.CanCollide = false
    proxy.CanTouch = false
    proxy.CanQuery = false
    proxy.CastShadow = false
    proxy.Massless = true
    proxy.Parent = character
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = proxy
    weld.Parent = proxy

    local box = Instance.new("SelectionBox")
    box.Name = "TasuESP3DBox"
    box.Adornee = proxy
    box.Color3 = Theme.Accent
    box.SurfaceColor3 = Theme.Accent
    box.SurfaceTransparency = 1
    box.LineThickness = 0.025
    box.Visible = false
    box.Parent = proxy

    local nameBillboard = Instance.new("BillboardGui")
    nameBillboard.Name = "TasuESPName"
    nameBillboard.Adornee = proxy
    nameBillboard.AlwaysOnTop = true
    nameBillboard.Enabled = false
    nameBillboard.LightInfluence = 0
    nameBillboard.MaxDistance = State.Visuals.MaxDistance
    nameBillboard.Size = UDim2.fromOffset(240, 42)
    nameBillboard.StudsOffsetWorldSpace = Vector3.new(0, boundsSize.Y * 0.5 + 0.75, 0)
    nameBillboard.Parent = ScreenGui
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.FontFace = UI.Fonts.Option
    label.RichText = true
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = Theme.Accent
    label.TextSize = 14
    label.TextStrokeColor3 = Color3.fromRGB(8, 12, 18)
    label.TextStrokeTransparency = 0.25
    label.TextWrapped = true
    label.Parent = nameBillboard

    local healthBillboard = Instance.new("BillboardGui")
    healthBillboard.Name = "TasuESPHealth"
    healthBillboard.Adornee = proxy
    healthBillboard.AlwaysOnTop = true
    healthBillboard.Enabled = false
    healthBillboard.LightInfluence = 0
    healthBillboard.MaxDistance = State.Visuals.MaxDistance
    healthBillboard.Size = UDim2.fromOffset(8, math.clamp(math.floor(boundsSize.Y * 14), 54, 104))
    healthBillboard.StudsOffset = Vector3.new(boundsSize.X * 0.5 + 0.4, 0, 0)
    healthBillboard.Parent = ScreenGui
    local healthBackground = Instance.new("Frame")
    healthBackground.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
    healthBackground.BorderSizePixel = 0
    healthBackground.Size = UDim2.fromScale(1, 1)
    healthBackground.Parent = healthBillboard
    local healthFill = Instance.new("Frame")
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(80, 235, 120)
    healthFill.BorderSizePixel = 0
    healthFill.Position = UDim2.fromScale(0, 1)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.Parent = healthBackground

    local headAdornment = Instance.new("SphereHandleAdornment")
    headAdornment.Name = "TasuESPHeadDot"
    headAdornment.Adornee = character:FindFirstChild("Head")
    headAdornment.AlwaysOnTop = true
    headAdornment.Color3 = Theme.Accent
    headAdornment.Radius = 0.16
    headAdornment.Transparency = 0.08
    headAdornment.Visible = false
    headAdornment.ZIndex = 3
    headAdornment.Parent = ScreenGui

    record.WorldCharacter = character
    record.BoxProxy = proxy
    record.Box3D = box
    record.NameBillboard = nameBillboard
    record.Label = label
    record.HealthBillboard = healthBillboard
    record.HealthBar = healthFill
    record.HeadAdornment = headAdornment
    record.LastInfoUpdate = 0
end

local function updateSkeleton(record, character, camera, color)
    if record.SkeletonCharacter ~= character then
        record.SkeletonCharacter = character
        record.SkeletonMotors = {}
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                record.SkeletonMotors[descendant.Name] = descendant
            end
        end
    end
    local function joint(name)
        local motor = record.SkeletonMotors[name]
        if motor and motor.Parent and motor.Part0 then
            return (motor.Part0.CFrame * motor.C0 * motor.Transform).Position
        end
        return nil
    end
    local function endOf(partName, direction)
        local part = character:FindFirstChild(partName)
        return part and part.CFrame:PointToWorldSpace(direction * part.Size * 0.5) or nil
    end
    local points = {}
    local head = character:FindFirstChild("Head")
    if character:FindFirstChild("UpperTorso") then
        local neck, waist = joint("Neck"), joint("Waist")
        local ls, le, lw = joint("LeftShoulder"), joint("LeftElbow"), joint("LeftWrist")
        local rs, re, rw = joint("RightShoulder"), joint("RightElbow"), joint("RightWrist")
        local lh, lk, la = joint("LeftHip"), joint("LeftKnee"), joint("LeftAnkle")
        local rh, rk, ra = joint("RightHip"), joint("RightKnee"), joint("RightAnkle")
        points = {
            {head and head.Position, neck}, {neck, waist},
            {neck, ls}, {ls, le}, {le, lw}, {lw, endOf("LeftHand", Vector3.new(0, -1, 0))},
            {neck, rs}, {rs, re}, {re, rw}, {rw, endOf("RightHand", Vector3.new(0, -1, 0))},
            {waist, lh}, {lh, lk}, {lk, la},
            {waist, rh}, {rh, rk}, {rk, ra}
        }
    else
        local neck = joint("Neck")
        local leftShoulder, rightShoulder = joint("Left Shoulder"), joint("Right Shoulder")
        local leftHip, rightHip = joint("Left Hip"), joint("Right Hip")
        points = {
            {head and head.Position, neck},
            {neck, leftShoulder}, {leftShoulder, endOf("Left Arm", Vector3.new(0, -1, 0))},
            {neck, rightShoulder}, {rightShoulder, endOf("Right Arm", Vector3.new(0, -1, 0))},
            {neck, leftHip}, {leftHip, endOf("Left Leg", Vector3.new(0, -1, 0))},
            {neck, rightHip}, {rightHip, endOf("Right Leg", Vector3.new(0, -1, 0))}
        }
    end
    local lines = record.SkeletonLines
    local used = 0
    for _, pair in ipairs(points) do
        if pair[1] and pair[2] then
            local a, visibleA
            local b, visibleB
            if camera == Workspace.CurrentCamera then
                a, visibleA = camera:WorldToScreenPoint(pair[1])
                b, visibleB = camera:WorldToScreenPoint(pair[2])
            else
                a, visibleA = camera:WorldToViewportPoint(pair[1])
                b, visibleB = camera:WorldToViewportPoint(pair[2])
            end
            if visibleA and visibleB and a.Z > 0 and b.Z > 0 then
                used = used + 1
                local line = lines[used]
                if line then
                    line.BackgroundColor3 = color
                    setLine(line, Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), State.Visuals.Thickness)
                end
            end
        end
    end
    for index = used + 1, #lines do
        if lines[index]:IsA("GuiObject") then lines[index].Visible = false end
    end
    record.SkeletonLayer.Visible = used > 0
end

local function hideRecord(record)
    for key, object in pairs(record) do
        if key == "Highlight" then
            object.Enabled = false
            object.Adornee = nil
        elseif typeof(object) == "Instance" and object:IsA("SelectionBox") then
            object.Visible = false
        elseif typeof(object) == "Instance" and object:IsA("BillboardGui") then
            object.Enabled = false
        elseif typeof(object) == "Instance" and object:IsA("HandleAdornment") then
            object.Visible = false
        elseif typeof(object) == "Instance" and object:IsA("GuiObject") then
            object.Visible = false
        end
    end
end


RunService:BindToRenderStep("TasuHubESP", Enum.RenderPriority.Camera.Value + 50, function()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    if not State.Visuals.Enabled then
        for _, record in pairs(espRecords) do hideRecord(record) end
        return
    end
    local localAlive, _, _, localRoot = getAlive(LocalPlayer)
    local now = os.clock()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local record = espRecords[player] or createESP(player)
            local alive, character, humanoid, root = getAlive(player)
            local distance = localAlive and localRoot and root and (root.Position - localRoot.Position).Magnitude or math.huge
            if not alive or distance > State.Visuals.MaxDistance then
                hideRecord(record)
            else
                ensureWorldESP(record, character, root)
                local color = getPlayerVisualColor(player)
                local rootScreen = nil
                local visibleOnScreen = false
                if State.Visuals.Tracers or State.Visuals.Skeleton or State.Visuals.Offscreen then
                    local projectedRoot, onScreen = camera:WorldToScreenPoint(root.Position)
                    rootScreen = projectedRoot
                    visibleOnScreen = onScreen and projectedRoot.Z > 0
                end

                record.Box3D.Color3 = color
                record.Box3D.SurfaceColor3 = color
                record.Box3D.LineThickness = math.clamp(State.Visuals.Thickness * 0.0125, 0.0125, 0.06)
                record.Box3D.SurfaceTransparency = State.Visuals.BoxFilled and 0.82 or 1
                record.Box3D.Visible = State.Visuals.Boxes

                record.NameBillboard.MaxDistance = State.Visuals.MaxDistance
                record.NameBillboard.Enabled = State.Visuals.Names or State.Visuals.Distance
                record.HealthBillboard.MaxDistance = State.Visuals.MaxDistance
                record.HealthBillboard.Enabled = State.Visuals.Health
                record.HeadAdornment.Color3 = color
                record.HeadAdornment.Adornee = character:FindFirstChild("Head")
                record.HeadAdornment.Visible = State.Visuals.HeadDot and record.HeadAdornment.Adornee ~= nil

                if now - (record.LastInfoUpdate or 0) >= 0.12 then
                    record.LastInfoUpdate = now
                    local nameText = State.Visuals.Names and player.DisplayName or ""
                    local distanceColor = State.World.RGB.ESP.Enabled and color or Color3.fromRGB(255, 196, 74)
                    local distanceText = State.Visuals.Distance and string.format("<font color=\"%s\">[%.0f studs]</font>", colorToHex(distanceColor), distance) or ""
                    record.Label.Text = nameText ~= "" and distanceText ~= "" and nameText .. "\n" .. distanceText or nameText .. distanceText
                    record.Label.TextColor3 = color
                    local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
                    record.HealthBar.Size = UDim2.fromScale(1, ratio)
                    record.HealthBar.BackgroundColor3 = Color3.fromRGB(235, 70, 70):Lerp(Color3.fromRGB(80, 235, 120), ratio)
                end

                record.Tracer.BackgroundColor3 = color
                if State.Visuals.Tracers and visibleOnScreen and rootScreen then
                    local canvas = getCanvasSize()
                    setLine(record.Tracer, Vector2.new(canvas.X * 0.5, canvas.Y - 3), Vector2.new(rootScreen.X, rootScreen.Y), State.Visuals.Thickness)
                else
                    record.Tracer.Visible = false
                end

                if State.Visuals.Skeleton and visibleOnScreen then
                    updateSkeleton(record, character, camera, color)
                else
                    record.SkeletonLayer.Visible = false
                end

                record.Arrow.Visible = false
                if State.Visuals.Offscreen and not visibleOnScreen and rootScreen then
                    local center = getCanvasSize() * 0.5
                    local direction = Vector2.new(rootScreen.X, rootScreen.Y) - center
                    if rootScreen.Z < 0 then direction = -direction end
                    if direction.Magnitude > 0 then
                        local edge = center + direction.Unit * math.min(center.X, center.Y) * 0.82
                        local distanceRatio = math.clamp(distance / math.max(25, State.Visuals.MaxDistance), 0, 1)
                        local arrowSize = math.floor(18 + distanceRatio * 30)
                        record.Arrow.Size = UDim2.fromOffset(arrowSize, arrowSize)
                        record.Arrow.TextSize = math.floor(16 + distanceRatio * 24)
                        record.Arrow.Position = UDim2.fromOffset(edge.X, edge.Y)
                        record.Arrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
                        record.Arrow.TextColor3 = color
                        record.Arrow.Visible = true
                    end
                end

                record.Highlight.Adornee = character
                record.Highlight.FillColor = color
                record.Highlight.OutlineColor = color
                record.Highlight.Enabled = State.Visuals.Chams
            end
        end
    end
end)

trackConnection(Players.PlayerRemoving:Connect(destroyESP))


local freecamState
local FREECAM_SINK_ACTION = "TasuHubFreecamMovementSink"
local colorCorrection
local bloom
local applyFlatTextures
local flyApplied = false
local flyVelocity
local flyGyro
local flyRoot
local movementClock = 0
local antiFlingState = {
    Root = nil,
    Humanoid = nil,
    SafeCFrame = nil,
    AutoRotate = true,
    PlatformStand = false,
    FallingDownEnabled = true,
    RagdollEnabled = true
}
local flingState = {Humanoid = nil, Root = nil, AutoRotate = true, Running = false, MoveLift = 0.1}
local orbitState = {Root = nil, Active = false}

local function clearFlingState()
    if flingState.Root and flingState.Root.Parent then
        flingState.Root.AssemblyLinearVelocity = Vector3.zero
        flingState.Root.AssemblyAngularVelocity = Vector3.zero
    end
    if flingState.Humanoid and flingState.Humanoid.Parent then
        flingState.Humanoid.AutoRotate = flingState.AutoRotate
    end
    flingState.Humanoid = nil
    flingState.Root = nil
end

UI.ClearAntiFlingState = function()
    local protectedRoot = antiFlingState.Root
    if protectedRoot and protectedRoot.Parent then
        protectedRoot.Anchored = false
        protectedRoot.AssemblyLinearVelocity = Vector3.zero
        protectedRoot.AssemblyAngularVelocity = Vector3.zero
    end
    local protectedHumanoid = antiFlingState.Humanoid
    if protectedHumanoid and protectedHumanoid.Parent then
        protectedHumanoid.AutoRotate = antiFlingState.AutoRotate
        protectedHumanoid.PlatformStand = antiFlingState.PlatformStand
        protectedHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, antiFlingState.FallingDownEnabled)
        protectedHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, antiFlingState.RagdollEnabled)
        protectedHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    antiFlingState.Root = nil
    antiFlingState.Humanoid = nil
    antiFlingState.SafeCFrame = nil
end

UI.FlingTarget = function(player, protectLocal)
    if player == LocalPlayer or UI.FlingCooldowns[player] then return false end
    local targetAlive, targetCharacter, targetHumanoid, targetRoot = getAlive(player)
    if not targetAlive or targetRoot.Anchored then return false end
    UI.FlingCooldowns[player] = true
    task.delay(0.55, function()
        UI.FlingCooldowns[player] = nil
    end)

    pcall(function()
        local setSimulationRadius = resolveGlobal("setsimulationradius")
        if type(setSimulationRadius) == "function" then
            setSimulationRadius(math.huge, math.huge)
        end
        local setHiddenProperty = resolveGlobal("sethiddenproperty")
        if type(setHiddenProperty) == "function" then
            setHiddenProperty(LocalPlayer, "SimulationRadius", math.huge)
        end
    end)

    task.spawn(function()
        local localAlive, _, localHumanoid, localRoot = getAlive(LocalPlayer)
        if not localAlive then return end
        local safeCFrame = localRoot.CFrame
        local safeVelocity = localRoot.AssemblyLinearVelocity
        local safeAutoRotate = localHumanoid.AutoRotate
        local pulse = math.clamp(State.Movement.FlingPower, 1000, 100000)
        local offsetSign = 1
        local moveLift = 0.1
        local savedFlyForce = flyVelocity and flyVelocity.Parent and flyVelocity.MaxForce or nil
        if savedFlyForce then flyVelocity.MaxForce = Vector3.zero end
        for _ = 1, protectLocal and 4 or 18 do
            if unloaded or not localRoot.Parent or not targetCharacter.Parent or not targetRoot.Parent or targetHumanoid.Health <= 0 then break end
            RunService.Heartbeat:Wait()
            local stepCFrame = localRoot.CFrame
            local stepVelocity = protectLocal and localRoot.AssemblyLinearVelocity or safeVelocity
            if not protectLocal then
                localRoot.CFrame = targetRoot.CFrame * CFrame.new(offsetSign * 0.7, 0, 0)
                offsetSign = -offsetSign
            end
            localHumanoid.AutoRotate = false
            localRoot.AssemblyAngularVelocity = Vector3.zero
            localRoot.Velocity = stepVelocity * 10000 + Vector3.new(0, pulse, 0)
            RunService.RenderStepped:Wait()
            localRoot.CFrame = protectLocal and stepCFrame or safeCFrame
            localRoot.Velocity = stepVelocity
            localRoot.AssemblyAngularVelocity = Vector3.zero
            RunService.Stepped:Wait()
            localRoot.CFrame = protectLocal and stepCFrame or safeCFrame
            localRoot.Velocity = stepVelocity + Vector3.new(0, moveLift, 0)
            localRoot.AssemblyAngularVelocity = Vector3.zero
            moveLift = -moveLift
        end
        if savedFlyForce and flyVelocity and flyVelocity.Parent then flyVelocity.MaxForce = savedFlyForce end
        if localRoot.Parent then
            localRoot.CFrame = safeCFrame
            localRoot.AssemblyLinearVelocity = safeVelocity
            localRoot.AssemblyAngularVelocity = Vector3.zero
            localHumanoid.AutoRotate = safeAutoRotate
            localHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    return true
end

UI.StartFlingLoop = function()
    if flingState.Running then return end
    flingState.Running = true
    task.spawn(function()
        while not unloaded and State.Movement.Fling do
            RunService.Heartbeat:Wait()
            local alive, character, humanoid, root = getAlive(LocalPlayer)
            if alive then
                local mode = State.Movement.FlingMode
                local shouldPulse = mode ~= "Contact Fling" or next(UI.GetTouchingPlayers(character)) ~= nil
                if shouldPulse then
                    local safeCFrame = root.CFrame
                    local safeVelocity = root.AssemblyLinearVelocity
                    local safeAutoRotate = humanoid.AutoRotate
                    local savedFlyForce = flyVelocity and flyVelocity.Parent and flyVelocity.MaxForce or nil
                    if savedFlyForce then flyVelocity.MaxForce = Vector3.zero end
                    humanoid.AutoRotate = false
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.Velocity = safeVelocity * 10000 + Vector3.new(0, math.clamp(State.Movement.FlingPower, 1000, 100000), 0)
                    RunService.RenderStepped:Wait()
                    if root.Parent then
                        root.CFrame = safeCFrame
                        root.Velocity = safeVelocity
                        root.AssemblyAngularVelocity = Vector3.zero
                        humanoid.AutoRotate = safeAutoRotate
                    end
                    if savedFlyForce and flyVelocity and flyVelocity.Parent then flyVelocity.MaxForce = savedFlyForce end
                    RunService.Stepped:Wait()
                    if root.Parent then
                        root.CFrame = safeCFrame
                        root.Velocity = safeVelocity + Vector3.new(0, flingState.MoveLift, 0)
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                    flingState.MoveLift = -flingState.MoveLift
                end
            end
        end
        flingState.Running = false
    end)
end

UI.GetTouchingPlayers = function(character)
    local found = {}
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {character}
    overlap.MaxParts = 200
    for _, localPart in ipairs(character:GetDescendants()) do
        if localPart:IsA("BasePart") then
            local ok, touching = pcall(function()
                return Workspace:GetPartsInPart(localPart, overlap)
            end)
            if ok then
                for _, part in ipairs(touching) do
                    local model = part:FindFirstAncestorOfClass("Model")
                    local player = model and Players:GetPlayerFromCharacter(model)
                    if player and player ~= LocalPlayer then found[player] = true end
                end
            end
        end
    end
    return found
end

local function clearOrbitMotion()
    if orbitState.Root and orbitState.Root.Parent then
        orbitState.Root.AssemblyLinearVelocity = Vector3.zero
        orbitState.Root.AssemblyAngularVelocity = Vector3.zero
    end
    orbitState.Root = nil
    orbitState.Active = false
end

local godmodeState = {Humanoid = nil, Resetting = false}
local function clearGodmodeState()
    local humanoid = godmodeState.Humanoid
    local defaults = humanoid and humanoidDefaults[humanoid]
    if humanoid and humanoid.Parent and defaults then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, defaults.DeadEnabled)
        humanoid.BreakJointsOnDeath = defaults.BreakJointsOnDeath
        humanoid.MaxHealth = defaults.MaxHealth
        humanoid.Health = math.min(humanoid.Health, defaults.MaxHealth)
    end
    godmodeState.Humanoid = nil
end

local godmodeResetEvent = trackInstance(Instance.new("BindableEvent"))
trackConnection(godmodeResetEvent.Event:Connect(function()
    godmodeState.Resetting = true
    clearGodmodeState()
    local character, humanoid = getCharacter(LocalPlayer)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        humanoid.BreakJointsOnDeath = true
        humanoid.Health = 0
    elseif character then
        character:BreakJoints()
    end
    task.delay(1.5, function()
        godmodeState.Resetting = false
    end)
end))
task.spawn(function()
    for _ = 1, 12 do
        if unloaded then return end
        local ok = pcall(function()
            StarterGui:SetCore("ResetButtonCallback", godmodeResetEvent)
        end)
        if ok then return end
        task.wait(0.5)
    end
end)

trackFeature("Godmode", RunService.Heartbeat:Connect(function()
    local _, humanoid = getCharacter(LocalPlayer)
    if State.Movement.Godmode and not godmodeState.Resetting and humanoid then
        if godmodeState.Humanoid ~= humanoid then
            clearGodmodeState()
            godmodeState.Humanoid = humanoid
        end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        humanoid.BreakJointsOnDeath = false
        humanoid.MaxHealth = 1000000000
        humanoid.Health = humanoid.MaxHealth
    elseif godmodeState.Humanoid then
        clearGodmodeState()
    end
end))

local function freezeFreecamCharacter()
    if not freecamState then return end
    local _, humanoid, root = getCharacter(LocalPlayer)
    local frozen = freecamState.FrozenCharacter
    if frozen and frozen.Humanoid ~= humanoid then
        if frozen.Humanoid and frozen.Humanoid.Parent then
            frozen.Humanoid.WalkSpeed = frozen.WalkSpeed
            frozen.Humanoid.JumpPower = frozen.JumpPower
            frozen.Humanoid.JumpHeight = frozen.JumpHeight
            frozen.Humanoid.AutoRotate = frozen.AutoRotate
        end
        frozen = nil
        freecamState.FrozenCharacter = nil
    end
    if humanoid and root and not frozen then
        frozen = {
            Humanoid = humanoid,
            Root = root,
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight,
            AutoRotate = humanoid.AutoRotate
        }
        freecamState.FrozenCharacter = frozen
    end
    if frozen and frozen.Humanoid.Parent and frozen.Root.Parent then
        frozen.Humanoid.WalkSpeed = 0
        frozen.Humanoid.JumpPower = 0
        frozen.Humanoid.JumpHeight = 0
        frozen.Humanoid.AutoRotate = false
        frozen.Humanoid.Jump = false
        frozen.Humanoid:Move(Vector3.zero, false)
        frozen.Root.AssemblyLinearVelocity = Vector3.zero
        frozen.Root.AssemblyAngularVelocity = Vector3.zero
    end
end

local function releaseFreecamCharacter()
    ContextActionService:UnbindAction(FREECAM_SINK_ACTION)
    if freecamState then
        UserInputService.MouseBehavior = freecamState.MouseBehavior or Enum.MouseBehavior.Default
        if freecamState.MouseIconEnabled ~= nil then
            UserInputService.MouseIconEnabled = freecamState.MouseIconEnabled
        end
    end
    local frozen = freecamState and freecamState.FrozenCharacter
    if frozen and frozen.Humanoid and frozen.Humanoid.Parent then
        frozen.Humanoid.WalkSpeed = frozen.WalkSpeed
        frozen.Humanoid.JumpPower = frozen.JumpPower
        frozen.Humanoid.JumpHeight = frozen.JumpHeight
        frozen.Humanoid.AutoRotate = frozen.AutoRotate
    end
    if frozen and frozen.Root and frozen.Root.Parent then
        frozen.Root.AssemblyLinearVelocity = Vector3.zero
        frozen.Root.AssemblyAngularVelocity = Vector3.zero
    end
end

local function clearFlyController()
    if flyVelocity then pcall(function() flyVelocity:Destroy() end) end
    if flyGyro then pcall(function() flyGyro:Destroy() end) end
    flyVelocity = nil
    flyGyro = nil
    flyRoot = nil
end

local function ensureFlyController(root)
    if flyRoot == root and flyVelocity and flyVelocity.Parent and flyGyro and flyGyro.Parent then
        return
    end
    clearFlyController()
    flyRoot = root
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyVelocity.P = 12500
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyGyro.P = 9000
    flyGyro.D = 500
    flyGyro.Parent = root
end

trackFeature("Movement", RunService.Heartbeat:Connect(function(deltaTime)
    movementClock = movementClock + deltaTime
    local alive, character, humanoid, root = getAlive(LocalPlayer)
    if not alive then
        clearFlyController()
        flyApplied = false
        return
    end
    if State.World.Freecam then
        if flyApplied then
            clearFlyController()
            humanoid.PlatformStand = humanoidDefaults[humanoid] and humanoidDefaults[humanoid].PlatformStand or false
            flyApplied = false
        end
        humanoid:Move(Vector3.zero, false)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        return
    end
    if State.Movement.AntiFling and not State.Movement.Fling then
        if antiFlingState.Root ~= root then
            UI.ClearAntiFlingState()
            antiFlingState.Root = root
            antiFlingState.Humanoid = humanoid
            antiFlingState.AutoRotate = humanoid.AutoRotate
            antiFlingState.PlatformStand = humanoid.PlatformStand
            antiFlingState.FallingDownEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.FallingDown)
            antiFlingState.RagdollEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Ragdoll)
            local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
            antiFlingState.SafeCFrame = look.Magnitude > 0.01 and CFrame.lookAt(root.Position, root.Position + look.Unit) or CFrame.new(root.Position)
        end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        root.Anchored = true
        if antiFlingState.SafeCFrame then root.CFrame = antiFlingState.SafeCFrame end
        humanoid.PlatformStand = false
        humanoid.AutoRotate = false
        humanoid.Jump = false
        humanoid:Move(Vector3.zero, false)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.AssemblyLinearVelocity = Vector3.zero
                descendant.AssemblyAngularVelocity = Vector3.zero
            end
        end
        return
    elseif antiFlingState.Root then
        UI.ClearAntiFlingState()
    end
    if State.Movement.Speed then
        if State.Movement.SpeedMethod == "WalkSpeed" then
            humanoid.WalkSpeed = State.Movement.SpeedValue
        elseif State.Movement.SpeedMethod == "Velocity" then
            local direction = humanoid.MoveDirection
            root.AssemblyLinearVelocity = Vector3.new(direction.X * State.Movement.SpeedValue, root.AssemblyLinearVelocity.Y, direction.Z * State.Movement.SpeedValue)
        elseif humanoid.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + humanoid.MoveDirection * State.Movement.SpeedValue * deltaTime
        end
    end
    if State.Movement.Jump then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = State.Movement.JumpValue
    end
    if State.Movement.BunnyHop and humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    local flingFly = State.Movement.Fling and State.Movement.FlingMode == "Fly Fling"
    if (State.Movement.Fly and not State.Movement.Fling) or flingFly then
        local camera = Workspace.CurrentCamera
        if camera then
            ensureFlyController(root)
            local direction = Vector3.zero
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            if forward.Magnitude > 0 then forward = forward.Unit end
            if right.Magnitude > 0 then right = right.Unit end
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
                direction = direction + Vector3.yAxis
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
                direction = direction - Vector3.yAxis
            end
            if direction.Magnitude > 0 then direction = direction.Unit end
            humanoid.Sit = false
            humanoid.PlatformStand = true
            flyApplied = true
            local facing = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
            if facing.Magnitude < 0.01 then facing = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) end
            flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + facing.Unit)
            local flySpeed = flingFly and State.Movement.FlingFlySpeed or State.Movement.FlySpeed
            if not flingFly and State.Movement.FlyMethod == "CFrame" then
                flyVelocity.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = root.CFrame + direction * flySpeed * deltaTime
            else
                flyVelocity.Velocity = direction * flySpeed
                root.AssemblyLinearVelocity = direction * flySpeed
            end
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    if originalCollision[descendant] == nil then originalCollision[descendant] = descendant.CanCollide end
                    descendant.CanCollide = false
                end
            end
        end
    elseif flyApplied then
        clearFlyController()
        humanoid.PlatformStand = humanoidDefaults[humanoid] and humanoidDefaults[humanoid].PlatformStand or false
        flyApplied = false
        if not State.Movement.Noclip then
            for part, canCollide in pairs(originalCollision) do
                if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
            end
            table.clear(originalCollision)
        end
    end
    if State.Movement.Noclip then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                if originalCollision[descendant] == nil then
                    originalCollision[descendant] = descendant.CanCollide
                end
                descendant.CanCollide = false
            end
        end
    end
    if State.Movement.Fling then
        UI.StartFlingLoop()
        if flingState.Root ~= root then
            clearFlingState()
            flingState.Root = root
            flingState.Humanoid = humanoid
            flingState.AutoRotate = humanoid.AutoRotate
        end
        humanoid.AutoRotate = flingState.AutoRotate
        root.AssemblyAngularVelocity = Vector3.zero
    elseif flingState.Root then
        clearFlingState()
    end
    local orbitApplied = false
    if State.Movement.Orbit and selectedPlayer then
        local targetAlive, _, _, targetRoot = getAlive(selectedPlayer)
        if targetAlive then
            orbitApplied = true
            orbitState.Root = root
            orbitState.Active = true
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            local angle = movementClock * State.Movement.OrbitSpeed
            local radius = State.Movement.OrbitRadius
            local mode = State.Movement.OrbitMode
            local offset
            if mode == "Carpet" then
                offset = targetRoot.CFrame:VectorToWorldSpace(Vector3.new(0, -math.abs(State.Movement.OrbitHeight), -State.Movement.OrbitOffset))
            elseif mode == "Backpack" then
                offset = targetRoot.CFrame:VectorToWorldSpace(Vector3.new(0, State.Movement.OrbitHeight, State.Movement.OrbitOffset))
            elseif mode == "Helicopter" then
                offset = Vector3.new(math.cos(angle) * State.Movement.OrbitOffset, State.Movement.OrbitHeight, math.sin(angle) * State.Movement.OrbitOffset)
            elseif mode == "Wave" then
                offset = Vector3.new(math.cos(angle) * radius, 2 + math.sin(angle * 2) * radius * 0.55, math.sin(angle) * radius)
            elseif mode == "Vertical Loop" then
                offset = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
            elseif mode == "Horizontal Loop" then
                offset = Vector3.new(math.cos(angle) * radius, 1.5, math.sin(angle) * radius)
            elseif mode == "Spiral" then
                offset = Vector3.new(math.cos(angle) * radius, 2 + math.sin(angle * 0.5) * radius, math.sin(angle) * radius)
            else
                offset = Vector3.new(math.cos(angle) * radius, 1.5, math.sin(angle) * radius)
            end
            local orbitPosition = targetRoot.Position + offset
            if mode == "Carpet" then
                root.CFrame = CFrame.lookAt(orbitPosition, orbitPosition + targetRoot.CFrame.LookVector) * CFrame.Angles(math.rad(90), 0, 0)
            elseif mode == "Backpack" then
                root.CFrame = targetRoot.CFrame * CFrame.new(0, State.Movement.OrbitHeight, State.Movement.OrbitOffset)
            elseif mode == "Helicopter" then
                root.CFrame = CFrame.new(orbitPosition) * CFrame.Angles(0, angle * 2, math.rad(90))
            elseif mode == "Avatar Spin" then
                root.CFrame = CFrame.new(orbitPosition) * CFrame.Angles(0, movementClock * 3, 0)
            elseif mode == "Vertical Loop" then
                root.CFrame = CFrame.lookAt(orbitPosition, targetRoot.Position) * CFrame.Angles(0, 0, angle)
            elseif mode == "Horizontal Loop" then
                root.CFrame = CFrame.lookAt(orbitPosition, targetRoot.Position) * CFrame.Angles(0, 0, math.rad(90))
            else
                root.CFrame = CFrame.lookAt(orbitPosition, targetRoot.Position)
            end
        end
    end
    if not orbitApplied and orbitState.Active then
        clearOrbitMotion()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end))

trackFeature("World", RunService.RenderStepped:Connect(function(deltaTime)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    camera.FieldOfView = State.World.CameraFOV
    if State.World.RGB.World.Enabled then
        colorCorrection.TintColor = getRGBColor("World", 0)
    end
    if State.World.Freecam then
        if not freecamState then
            local pitch, yaw = camera.CFrame:ToOrientation()
            freecamState = {
                Position = camera.CFrame.Position,
                Pitch = pitch,
                Yaw = yaw,
                Type = camera.CameraType,
                Subject = camera.CameraSubject,
                MouseBehavior = UserInputService.MouseBehavior,
                MouseIconEnabled = UserInputService.MouseIconEnabled
            }
            camera.CameraType = Enum.CameraType.Scriptable
            ContextActionService:BindActionAtPriority(
                FREECAM_SINK_ACTION,
                function() return Enum.ContextActionResult.Sink end,
                false,
                Enum.ContextActionPriority.High.Value + 100,
                Enum.KeyCode.W,
                Enum.KeyCode.A,
                Enum.KeyCode.S,
                Enum.KeyCode.D,
                Enum.KeyCode.Space,
                Enum.KeyCode.LeftControl,
                Enum.KeyCode.Q,
                Enum.KeyCode.E
            )
        end
        freezeFreecamCharacter()
        local captureLook = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if captureLook then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            UserInputService.MouseIconEnabled = true
            local mouseDelta = UserInputService:GetMouseDelta()
            freecamState.Yaw = freecamState.Yaw - mouseDelta.X * 0.0025
            freecamState.Pitch = math.clamp(freecamState.Pitch - mouseDelta.Y * 0.0025, -1.5, 1.5)
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
        local rotation = CFrame.fromOrientation(freecamState.Pitch, freecamState.Yaw, 0)
        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + rotation.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - rotation.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + rotation.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - rotation.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.yAxis end
        if direction.Magnitude > 0 then
            freecamState.Position = freecamState.Position + direction.Unit * State.World.FreecamSpeed * 60 * deltaTime
        end
        camera.CFrame = CFrame.new(freecamState.Position) * rotation
    elseif freecamState then
        releaseFreecamCharacter()
        camera.CameraType = freecamState.Type or Enum.CameraType.Custom
        camera.CameraSubject = freecamState.Subject
        freecamState = nil
    end
end))

local thirdPersonBaseCFrame
local thirdPersonAppliedCFrame
RunService:BindToRenderStep("TasuHubThirdPerson", Enum.RenderPriority.Camera.Value + 25, function()
    local camera = Workspace.CurrentCamera
    if not camera or not State.World.ThirdPerson or State.World.Freecam then
        thirdPersonBaseCFrame = nil
        thirdPersonAppliedCFrame = nil
        return
    end
    local observed = camera.CFrame
    local base = observed
    if thirdPersonAppliedCFrame and thirdPersonBaseCFrame then
        local unchangedPosition = (observed.Position - thirdPersonAppliedCFrame.Position).Magnitude < 0.002
        local unchangedLook = observed.LookVector:Dot(thirdPersonAppliedCFrame.LookVector) > 0.99999
        if unchangedPosition and unchangedLook then base = thirdPersonBaseCFrame end
    end
    thirdPersonBaseCFrame = base
    local desired = base * CFrame.new(1.35, 0.45, 6)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, camera}
    params.IgnoreWater = true
    local offset = desired.Position - base.Position
    local hit = Workspace:Raycast(base.Position, offset, params)
    if hit then
        local safeDistance = math.max(0.25, hit.Distance - 0.35)
        desired = CFrame.new(base.Position + offset.Unit * safeDistance) * base.Rotation
    end
    camera.CFrame = desired
    camera.Focus = CFrame.new(base.Position + base.LookVector * 12)
    thirdPersonAppliedCFrame = desired
end)

trackConnection(UserInputService.JumpRequest:Connect(function()
    if State.Movement.InfiniteJump and not State.World.Freecam then
        local _, humanoid = getCharacter(LocalPlayer)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if pendingKeybind then
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local bind = pendingKeybind
        pendingKeybind = nil
        if input.KeyCode == Enum.KeyCode.Backspace then
            State.Keybinds[bind.Id] = nil
            bind.Button.Text = (bind.Prefix or "") .. "Bind"
            showToast("Keybind cleared")
            return
        end
        if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Unknown then
            bind.Button.Text = (bind.Prefix or "") .. (State.Keybinds[bind.Id] or "Bind")
            showToast("That key is reserved or unavailable")
            return
        end
        local keyName = input.KeyCode.Name
        for id, assignedKey in pairs(State.Keybinds) do
            if id ~= bind.Id and assignedKey == keyName then
                bind.Button.Text = (bind.Prefix or "") .. (State.Keybinds[bind.Id] or "Bind")
                showToast("Key is already assigned; clear it first")
                return
            end
        end
        State.Keybinds[bind.Id] = keyName
        bind.Button.Text = (bind.Prefix or "") .. keyName
        showToast("Bound to " .. keyName)
        return
    end
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for id, assignedKey in pairs(State.Keybinds) do
            if assignedKey == input.KeyCode.Name and keybindActions[id] then
                keybindActions[id]()
                return
            end
        end
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and State.Movement.ClickTP and not State.World.Freecam and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local camera = Workspace.CurrentCamera
        local _, _, root = getCharacter(LocalPlayer)
        if camera and root then
            local mouse = LocalPlayer:GetMouse()
            local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
            if result then
                root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if ContentWindow.Visible then
            closeContentWindow()
        else
            openContentWindow()
        end
    end
end))

local function restoreCollision()
    for part, value in pairs(originalCollision) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = value
            end)
        end
    end
    table.clear(originalCollision)
end

local function restoreMovement()
    clearFlyController()
    flyApplied = false
    local _, humanoid, root = getCharacter(LocalPlayer)
    if humanoid then
        local defaults = humanoidDefaults[humanoid]
        humanoid.WalkSpeed = defaults and defaults.WalkSpeed or 16
        humanoid.JumpPower = defaults and defaults.JumpPower or 50
        humanoid.UseJumpPower = defaults and defaults.UseJumpPower ~= false
        humanoid.PlatformStand = defaults and defaults.PlatformStand or false
    end
    if root then
        root.AssemblyAngularVelocity = Vector3.zero
    end
    restoreCollision()
    Workspace.Gravity = originalGravity
end

colorCorrection = trackInstance(Instance.new("ColorCorrectionEffect"))
colorCorrection.Name = "TasuHubColorVision"
colorCorrection.Enabled = false
colorCorrection.Parent = Lighting
bloom = trackInstance(Instance.new("BloomEffect"))
bloom.Name = "TasuHubGlowVision"
bloom.Enabled = false
bloom.Parent = Lighting

local function rememberFlatProperties(object, properties)
    if flatObjectDefaults[object] then return end
    local saved = {}
    for _, property in ipairs(properties) do
        local ok, value = pcall(function() return object[property] end)
        if ok then saved[property] = value end
    end
    flatObjectDefaults[object] = saved
end

local function flattenObject(object)
    if flatObjectDefaults[object] then return end
    if object:IsA("BasePart") then
        local properties = {"Material", "MaterialVariant", "Reflectance"}
        if object:IsA("MeshPart") then table.insert(properties, "TextureID") end
        rememberFlatProperties(object, properties)
        pcall(function()
            object.Material = Enum.Material.SmoothPlastic
            object.MaterialVariant = ""
            object.Reflectance = 0
            if object:IsA("MeshPart") then object.TextureID = "" end
        end)
    elseif object:IsA("Decal") or object:IsA("Texture") then
        rememberFlatProperties(object, {"Transparency"})
        object.Transparency = 1
    elseif object:IsA("SpecialMesh") then
        rememberFlatProperties(object, {"TextureId"})
        pcall(function() object.TextureId = "" end)
    elseif object:IsA("SurfaceAppearance") then
        rememberFlatProperties(object, {"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"})
        pcall(function()
            object.ColorMap = ""
            object.MetalnessMap = ""
            object.NormalMap = ""
            object.RoughnessMap = ""
        end)
    end
end

applyFlatTextures = function()
    if not State.World.FlatTextures then return end
    for _, object in ipairs(Workspace:GetDescendants()) do
        flattenObject(object)
    end
end

local function restoreFlatTextures()
    for object, properties in pairs(flatObjectDefaults) do
        if object and object.Parent then
            for property, value in pairs(properties) do
                pcall(function() object[property] = value end)
            end
        end
    end
    table.clear(flatObjectDefaults)
end

trackConnection(Workspace.DescendantAdded:Connect(function(object)
    if State.World.FlatTextures then
        task.defer(flattenObject, object)
    end
end))

local function applyWorld()
    if State.World.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
    if State.World.NoFog then
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000
    else
        Lighting.FogStart = originalLighting.FogStart
        Lighting.FogEnd = originalLighting.FogEnd
    end
    local lightingMode = State.World.LightingMode
    local worldRGB = State.World.RGB.World.Enabled or lightingMode == "RGB Vision"
    colorCorrection.Enabled = lightingMode ~= "Default" or worldRGB
    bloom.Enabled = lightingMode == "Glow" or lightingMode == "Neon Glow" or worldRGB
    if worldRGB then
        bloom.Intensity = State.World.GlowIntensity * 0.65
        bloom.Size = 28
        bloom.Threshold = 0.9
        colorCorrection.TintColor = getRGBColor("World", 0)
        colorCorrection.Brightness = 0.04
        colorCorrection.Contrast = 0.08
        colorCorrection.Saturation = 0.28
    elseif lightingMode == "Glow" then
        bloom.Intensity = State.World.GlowIntensity
        bloom.Size = 36
        bloom.Threshold = 0.78
        colorCorrection.TintColor = Color3.new(1, 1, 1)
        colorCorrection.Brightness = 0.08
        colorCorrection.Contrast = 0.14
        colorCorrection.Saturation = 0.18
    elseif lightingMode == "Neon Glow" then
        bloom.Intensity = State.World.NeonIntensity
        bloom.Size = State.World.NeonSize
        bloom.Threshold = State.World.NeonThreshold
        colorCorrection.TintColor = Color3.new(1, 1, 1)
        colorCorrection.Brightness = 0.1
        colorCorrection.Contrast = 0.24
        colorCorrection.Saturation = 0.5
    elseif lightingMode == "Manual" then
        colorCorrection.TintColor = Color3.fromRGB(State.World.ManualRed, State.World.ManualGreen, State.World.ManualBlue)
        colorCorrection.Brightness = State.World.ManualBrightness
        colorCorrection.Contrast = State.World.ManualContrast
        colorCorrection.Saturation = State.World.ManualSaturation
    else
        colorCorrection.TintColor = Color3.new(1, 1, 1)
        colorCorrection.Brightness = 0
        colorCorrection.Contrast = 0
        colorCorrection.Saturation = 0
    end
    if State.World.FlatTextures then
        applyFlatTextures()
    else
        restoreFlatTextures()
    end
    Workspace.Gravity = State.Movement.Gravity and State.Movement.GravityValue or originalGravity
end

do
UI.SetLoading(0.7, "Kategoriler oluşturuluyor")

local HomePage = pages.Home
local HomeCard = UI.AddAccordion(HomePage, "TasuHub", true)
HomeCard.Parent.LayoutOrder = 4
local HomeBrand = textLabel(HomeCard, "TasuHub", UDim2.new(1, 0, 0, 36), nil, 28, Theme.Text)
HomeBrand.FontFace = UI.Fonts.Home
local HomeSubtitle = addNote(HomeCard, "Live client test workspace")
HomeSubtitle.TextSize = 16
HomeSubtitle.FontFace = UI.Fonts.HomeRegular
local StatsCard = createCard(HomePage, "Stats Overlay")
StatsCard.Parent.LayoutOrder = 2
addToggle(StatsCard, "Show Stats", function() return State.Stats.Visible end, function(value)
    State.Stats.Visible = value
    UI.RefreshStatsWindow()
end)
addToggle(StatsCard, "FPS", function() return State.Stats.FPS end, function(value) State.Stats.FPS = value end)
addToggle(StatsCard, "Ping", function() return State.Stats.Ping end, function(value) State.Stats.Ping = value end)
addToggle(StatsCard, "Player Count", function() return State.Stats.Players end, function(value) State.Stats.Players = value end)
addToggle(StatsCard, "Memory", function() return State.Stats.Memory end, function(value) State.Stats.Memory = value end)
local StatusCard = UI.AddStaticCard(HomePage, "Live Session")
StatusCard.Parent.LayoutOrder = 1
local StatusText = addNote(StatusCard, "")
do
    UI.UpdateLog = {
        "Hover search with indexed results",
        "Frame-synchronous body bounds, names and bottom-center tracers",
        "Glow, Neon Glow, scoped RGB, Manual and reversible Flat Texture modes",
        "Freecam player teleport and conditional movement controls",
        "Overlay dropdowns, catalog-aware search and rounded synchronized shadows",
        "Stable R6/R15 flight, reference-timed fling pulses and target wall memory"
    }
    local updateCard = createCard(HomePage, "Update Log  ·  v" .. UI.Version)
    updateCard.Parent.LayoutOrder = 3
    addNote(updateCard, (table.concat(UI.UpdateLog, "\n• "):gsub("^", "• ")))
end
local unloadButton = addAction(HomeCard, "Unload TasuHub", function()
    if unload then unload() end
end)
local unloadButtonIcon = UI.BindActionIcon(unloadButton, "Unload", nil, "      Unload TasuHub")
unloadButtonIcon.Position = UDim2.fromOffset(18, 15)
unloadButtonIcon.Size = UDim2.fromOffset(18, 18)

local statusClock = 0
trackConnection(RunService.Heartbeat:Connect(function(deltaTime)
    statusClock = statusClock + deltaTime
    if statusClock < 0.25 then return end
    statusClock = 0
    local ping = "n/a"
    local ok, value = pcall(function()
        return LocalPlayer:GetNetworkPing() * 1000
    end)
    if ok then ping = string.format("%.0f ms", value) end
    StatusText.Text = string.format("Player: %s   •   PlaceId: %s   •   Players: %d   •   Ping: %s   •   Target: %s", LocalPlayer.Name, tostring(game.PlaceId), #Players:GetPlayers(), ping, currentTarget and currentTarget.Player.Name or "None")
end))

end

do
local AimPage = pages.Aim
local AimCard = createCard(AimPage, "Live Aim")
addToggle(AimCard, "Enabled", function() return State.Aim.Enabled end, function(value) State.Aim.Enabled = value end, true)
addToggle(AimCard, "Rage Mode", function() return State.Aim.Rage end, function(value)
    State.Aim.Rage = value
    currentTarget = nil
end)
addToggle(AimCard, "Show FOV", function() return State.Aim.ShowFOV end, function(value) State.Aim.ShowFOV = value end)
addToggle(AimCard, "Wall Check", function() return State.Aim.WallCheck end, function(value) State.Aim.WallCheck = value end)
local aimSliderVisible = function() return State.Aim.Enabled and not State.Aim.Rage end
addSlider(AimCard, "FOV Radius", 20, 600, function() return State.Aim.FOV end, function(value) State.Aim.FOV = value end, nil, aimSliderVisible)
addSlider(AimCard, "Smoothing", 0, 0.95, function() return State.Aim.Smoothing end, function(value) State.Aim.Smoothing = value end, 2, aimSliderVisible)
addSlider(AimCard, "Prediction Time", 0, 0.5, function() return State.Aim.PredictionTime end, function(value) State.Aim.PredictionTime = value end, 2, function() return aimSliderVisible() and State.Aim.Prediction end)
addSlider(AimCard, "Maximum Distance", 25, 5000, function() return State.Aim.MaxDistance end, function(value) State.Aim.MaxDistance = value end, nil, aimSliderVisible)
local aimAdjustables = {
    addCycle(AimCard, "Activation", {"Right Mouse", "Left Mouse", "Always"}, function() return State.Aim.Activation end, function(value)
        State.Aim.Activation = value
        State.Aim.HoldRightMouse = value == "Right Mouse"
        currentTarget = nil
    end),
    addCycle(AimCard, "Method", {"Camera", "Mouse"}, function() return State.Aim.Method end, function(value) State.Aim.Method = value end),
    addCycle(AimCard, "Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, function() return State.Aim.TargetPart end, function(value) State.Aim.TargetPart = value end),
    addToggle(AimCard, "Team Check", function() return State.Aim.TeamCheck end, function(value) State.Aim.TeamCheck = value end),
    addToggle(AimCard, "Prediction", function() return State.Aim.Prediction end, function(value) State.Aim.Prediction = value end)
}
table.insert(controlRefreshers, function()
    for _, control in ipairs(aimAdjustables) do
        local object = control.Holder or control.Row
        if object then object.Visible = not State.Aim.Rage end
    end
end)

end

do
local VisualPage = pages.Visuals
local VisualCard = UI.AddAccordion(VisualPage, "ESP", false)
addToggle(VisualCard, "Enabled", function() return State.Visuals.Enabled end, function(value) State.Visuals.Enabled = value end, true)
addToggle(VisualCard, "Chams", function() return State.Visuals.Chams end, function(value) State.Visuals.Chams = value end)
addToggle(VisualCard, "Names", function() return State.Visuals.Names end, function(value) State.Visuals.Names = value end)
addToggle(VisualCard, "Boxes", function() return State.Visuals.Boxes end, function(value) State.Visuals.Boxes = value end)
addToggle(VisualCard, "Box Filled", function() return State.Visuals.BoxFilled end, function(value) State.Visuals.BoxFilled = value end)
addToggle(VisualCard, "Distance", function() return State.Visuals.Distance end, function(value) State.Visuals.Distance = value end)
addToggle(VisualCard, "Health", function() return State.Visuals.Health end, function(value) State.Visuals.Health = value end)
addToggle(VisualCard, "Head Dot", function() return State.Visuals.HeadDot end, function(value) State.Visuals.HeadDot = value end)
addToggle(VisualCard, "Tracers", function() return State.Visuals.Tracers end, function(value) State.Visuals.Tracers = value end)
addToggle(VisualCard, "Skeleton", function() return State.Visuals.Skeleton end, function(value) State.Visuals.Skeleton = value end)
addToggle(VisualCard, "Offscreen Arrows", function() return State.Visuals.Offscreen end, function(value) State.Visuals.Offscreen = value end)
addToggle(VisualCard, "Use Team Colors", function() return State.Visuals.TeamColors end, function(value) State.Visuals.TeamColors = value end)
addSlider(VisualCard, "Maximum Distance", 25, 5000, function() return State.Visuals.MaxDistance end, function(value) State.Visuals.MaxDistance = value end, nil, function() return State.Visuals.Enabled end)
addSlider(VisualCard, "Line Thickness", 1, 4, function() return State.Visuals.Thickness end, function(value) State.Visuals.Thickness = value end, nil, function() return State.Visuals.Enabled end)

local function setupVisualPreview()
local previewOpen = false
local previewModel
local PreviewPanel = Instance.new("CanvasGroup")
PreviewPanel.Name = "VisualPreviewPanel"
PreviewPanel.BackgroundColor3 = Theme.Surface
PreviewPanel.BackgroundTransparency = 1
PreviewPanel.ClipsDescendants = true
PreviewPanel.GroupTransparency = 1
PreviewPanel.Size = UDim2.fromOffset(300, 440)
PreviewPanel.Visible = false
PreviewPanel.ZIndex = 8
PreviewPanel.Parent = LegacyUIRoot
UI.BindTheme(PreviewPanel, "BackgroundColor3", "Surface")
round(PreviewPanel, 16)
gradient(PreviewPanel, "Surface", "Surface2", 90)
PreviewPanel:SetAttribute("ShadowSuppressed", true)
local PreviewShadow = addShadow(PreviewPanel, 0.72)
PreviewShadow.ZIndex = 1
local PreviewTitle = textLabel(PreviewPanel, "Live Visual Preview", UDim2.new(1, -36, 0, 42), UDim2.fromOffset(14, 4), 17, Theme.Text)
PreviewTitle.FontFace = UI.Fonts.HeadingHeavy
PreviewTitle.ZIndex = 9
PreviewTitle.Visible = false
local PreviewToggle = button(PreviewPanel, "Ⅱ", UDim2.fromOffset(20, 390), UDim2.new(1, -22, 0, 25))
PreviewToggle.TextSize = 13
PreviewToggle.ZIndex = 12
local PreviewViewport = Instance.new("ViewportFrame")
PreviewViewport.BackgroundColor3 = Theme.Surface2
PreviewViewport.BackgroundTransparency = 0.12
PreviewViewport.Position = UDim2.fromOffset(12, 48)
PreviewViewport.Size = UDim2.new(1, -42, 1, -62)
PreviewViewport.Ambient = Color3.fromRGB(190, 190, 200)
PreviewViewport.LightColor = Color3.fromRGB(255, 255, 255)
PreviewViewport.LightDirection = Vector3.new(-1, -1, -1)
PreviewViewport.ZIndex = 9
PreviewViewport.Parent = PreviewPanel
PreviewViewport.Visible = false
UI.BindTheme(PreviewViewport, "BackgroundColor3", "Surface2")
round(PreviewViewport, 12)
local PreviewWorld = Instance.new("WorldModel")
PreviewWorld.Parent = PreviewViewport
local PreviewCamera = Instance.new("Camera")
PreviewCamera.Parent = PreviewViewport
PreviewViewport.CurrentCamera = PreviewCamera
local PreviewBox = Instance.new("Frame")
PreviewBox.BackgroundColor3 = Theme.Accent
PreviewBox.BackgroundTransparency = 0.88
PreviewBox.Position = UDim2.fromScale(0.25, 0.15)
PreviewBox.Size = UDim2.fromScale(0.5, 0.72)
PreviewBox.ZIndex = 11
PreviewBox.Parent = PreviewViewport
local PreviewBoxStroke = stroke(PreviewBox, nil, State.Visuals.Thickness, 0)
local PreviewName = textLabel(PreviewViewport, LocalPlayer.DisplayName, UDim2.fromScale(0.8, 0.07), UDim2.fromScale(0.1, 0.06), 14, Theme.Accent, Enum.TextXAlignment.Center)
PreviewName.ZIndex = 12
local PreviewDistance = textLabel(PreviewViewport, "[25]", UDim2.fromOffset(70, 20), UDim2.fromScale(0.68, 0.08), 13, Color3.fromRGB(255, 196, 74), Enum.TextXAlignment.Center)
PreviewDistance.ZIndex = 12
local PreviewHealthBg = Instance.new("Frame")
PreviewHealthBg.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
PreviewHealthBg.BorderSizePixel = 0
PreviewHealthBg.ClipsDescendants = true
PreviewHealthBg.Visible = false
PreviewHealthBg.ZIndex = 12
PreviewHealthBg.Parent = PreviewViewport
local PreviewHealth = Instance.new("Frame")
PreviewHealth.AnchorPoint = Vector2.new(0, 1)
PreviewHealth.BackgroundColor3 = Color3.fromRGB(80, 235, 120)
PreviewHealth.ZIndex = 12
PreviewHealth.Parent = PreviewHealthBg
round(PreviewHealthBg, 3)
round(PreviewHealth, 2)
local PreviewHead = Instance.new("Frame")
PreviewHead.AnchorPoint = Vector2.new(0.5, 0.5)
PreviewHead.BackgroundColor3 = Theme.Accent
PreviewHead.Position = UDim2.fromScale(0.5, 0.25)
PreviewHead.Size = UDim2.fromOffset(7, 7)
PreviewHead.ZIndex = 12
PreviewHead.Parent = PreviewViewport
round(PreviewHead, 7)
local PreviewSkeletonLayer = Instance.new("Frame")
PreviewSkeletonLayer.BackgroundTransparency = 1
PreviewSkeletonLayer.Size = UDim2.fromScale(1, 1)
PreviewSkeletonLayer.Visible = false
PreviewSkeletonLayer.ZIndex = 11
PreviewSkeletonLayer.Parent = PreviewViewport
local PreviewSkeleton = {}
for _ = 1, 16 do
    local skeletonLine = newLine(PreviewSkeletonLayer)
    skeletonLine.ZIndex = 12
    table.insert(PreviewSkeleton, skeletonLine)
end
local PreviewSkeletonRecord = {SkeletonLayer = PreviewSkeletonLayer, SkeletonLines = PreviewSkeleton}
local PreviewHighlight
local previewIdleTrack
local previewSourceCharacter
local previewPartStyles = {}
local previewCosmeticStyles = {}

local function placePreviewPanel(animated)
    local position = getLocalPosition(ContentWindow)
    local target = UDim2.fromOffset(position.X + (previewOpen and ContentWindow.AbsoluteSize.X - 4 or 400), position.Y)
    if animated then
        animate(PreviewPanel, {Position = target}, 0.42, Enum.EasingStyle.Quint)
    else
        PreviewPanel.Position = target
    end
end

local function destroyPreviewModel()
    if previewIdleTrack then
        pcall(function() previewIdleTrack:Stop(0) end)
        previewIdleTrack = nil
    end
    if previewModel then
        previewModel:Destroy()
        previewModel = nil
    end
    PreviewHighlight = nil
    previewSourceCharacter = nil
    previewPartStyles = {}
    previewCosmeticStyles = {}
    PreviewSkeletonRecord.SkeletonCharacter = nil
    PreviewSkeletonRecord.SkeletonMotors = nil
end

local function getIdleAnimationId(character, humanoid)
    local animateScript = character:FindFirstChild("Animate")
    local idleFolder = animateScript and animateScript:FindFirstChild("idle")
    local idleAnimation = idleFolder and idleFolder:FindFirstChildWhichIsA("Animation", true)
    if idleAnimation and idleAnimation.AnimationId ~= "" then return idleAnimation.AnimationId end
    return humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://180435571" or "rbxassetid://507766666"
end

local function createPreviewModel()
    destroyPreviewModel()
    local character = LocalPlayer.Character
    if not character then return end
    local sourceHumanoid = character:FindFirstChildOfClass("Humanoid")
    local idleAnimationId = getIdleAnimationId(character, sourceHumanoid)
    local archivable = character.Archivable
    character.Archivable = true
    local ok, clone = pcall(function() return character:Clone() end)
    character.Archivable = archivable
    if not ok or not clone then return end
    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("Tool") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = object.Name == "HumanoidRootPart"
            object.CanCollide = false
            object.Massless = true
            object.AssemblyLinearVelocity = Vector3.zero
            object.AssemblyAngularVelocity = Vector3.zero
            previewPartStyles[object] = {
                Color = object.Color,
                Material = object.Material,
                Transparency = object.Transparency,
                TextureID = object:IsA("MeshPart") and object.TextureID or nil
            }
        elseif object:IsA("Motor6D") then
            object.Transform = CFrame.identity
        elseif object:IsA("Shirt") then
            table.insert(previewCosmeticStyles, {Object = object, Property = "ShirtTemplate", Value = object.ShirtTemplate})
        elseif object:IsA("Pants") then
            table.insert(previewCosmeticStyles, {Object = object, Property = "PantsTemplate", Value = object.PantsTemplate})
        elseif object:IsA("ShirtGraphic") then
            table.insert(previewCosmeticStyles, {Object = object, Property = "Graphic", Value = object.Graphic})
        elseif object:IsA("Decal") or object:IsA("Texture") then
            table.insert(previewCosmeticStyles, {Object = object, Property = "Transparency", Value = object.Transparency})
        end
    end
    clone:PivotTo(CFrame.Angles(0, math.pi, 0))
    clone.Parent = PreviewWorld
    previewModel = clone
    previewSourceCharacter = character
    local boundsCFrame, size = clone:GetBoundingBox()
    local distance = math.max(size.Y * 1.02, size.X * 1.8, 6)
    local target = boundsCFrame.Position
    PreviewCamera.CFrame = CFrame.lookAt(target + Vector3.new(0, size.Y * 0.03, distance), target)
    PreviewHighlight = Instance.new("Highlight")
    PreviewHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    PreviewHighlight.FillTransparency = 0.48
    PreviewHighlight.OutlineTransparency = 0.04
    PreviewHighlight.Adornee = clone
    PreviewHighlight.Parent = clone
    local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
    if cloneHumanoid then
        cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        local animator = cloneHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", cloneHumanoid)
        local animation = Instance.new("Animation")
        animation.AnimationId = idleAnimationId
        animation.Parent = clone
        local loaded, track = pcall(function() return animator:LoadAnimation(animation) end)
        if loaded and track then
            previewIdleTrack = track
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Idle
            track:Play(0.18, 1, 1)
        end
    end
end

local function setPreviewOpen(value)
    previewOpen = value == true
    if previewOpen then
        PreviewPanel:SetAttribute("ShadowSuppressed", false)
        PreviewTitle.Visible = true
        PreviewViewport.Visible = true
        createPreviewModel()
        animate(PreviewPanel, {BackgroundTransparency = 0.06}, 0.3, Enum.EasingStyle.Quint)
    else
        PreviewPanel:SetAttribute("ShadowSuppressed", true)
        PreviewPanel.BackgroundTransparency = 1
        PreviewTitle.Visible = false
        PreviewViewport.Visible = false
        destroyPreviewModel()
    end
    placePreviewPanel(true)
end
PreviewToggle.Activated:Connect(function() setPreviewOpen(not previewOpen) end)
UI.RefreshVisualPreview = function()
    if not UI.LegacyUIEnabled then
        setPreviewOpen(false)
        PreviewPanel.Visible = false
        return
    end
    local available = UI.ActiveCategory == "Visuals" and ContentWindow.Visible
    if available then
        PreviewPanel.Visible = true
        placePreviewPanel(false)
        animate(PreviewPanel, {GroupTransparency = 0}, 0.28, Enum.EasingStyle.Quint)
    else
        setPreviewOpen(false)
        animate(PreviewPanel, {GroupTransparency = 1}, 0.2, Enum.EasingStyle.Quint)
        task.delay(0.21, function()
            if (UI.ActiveCategory ~= "Visuals" or not ContentWindow.Visible) and PreviewPanel.Parent then PreviewPanel.Visible = false end
        end)
    end
end
trackConnection(ContentWindow:GetPropertyChangedSignal("Position"):Connect(function() placePreviewPanel(false) end))

local function applyPreviewChams(enabled, color)
    for part, style in pairs(previewPartStyles) do
        if part.Parent then
            part.Color = enabled and color or style.Color
            part.Material = enabled and Enum.Material.Neon or style.Material
            part.Transparency = style.Transparency
            if part:IsA("MeshPart") and style.TextureID ~= nil then
                part.TextureID = enabled and "" or style.TextureID
            end
        end
    end
    for _, style in ipairs(previewCosmeticStyles) do
        local object = style.Object
        if object and object.Parent then
            pcall(function()
                object[style.Property] = enabled and (style.Property == "Transparency" and 1 or "") or style.Value
            end)
        end
    end
end

local function hidePreviewOverlays()
    PreviewBox.Visible = false
    PreviewName.Visible = false
    PreviewDistance.Visible = false
    PreviewHealthBg.Visible = false
    PreviewHead.Visible = false
    PreviewSkeletonLayer.Visible = false
end

trackConnection(RunService.RenderStepped:Connect(function()
    if not previewOpen or not previewModel or not PreviewPanel.Visible then return end
    if LocalPlayer.Character ~= previewSourceCharacter then
        createPreviewModel()
        if not previewModel then return end
    end
    local color = State.World.RGB.ESP.Enabled and getRGBColor("ESP", 0)
        or (State.Visuals.TeamColors and ((LocalPlayer.Team and LocalPlayer.Team.TeamColor.Color) or LocalPlayer.TeamColor.Color) or Theme.Accent)
    local visualsEnabled = true
    applyPreviewChams(visualsEnabled and State.Visuals.Chams, color)
    if PreviewHighlight then
        PreviewHighlight.FillColor = color
        PreviewHighlight.OutlineColor = color
        PreviewHighlight.Enabled = visualsEnabled and State.Visuals.Chams
    end
    local left, right, top, bottom = getBoundingScreenBox(previewModel, PreviewCamera, PreviewViewport.AbsoluteSize)
    if not left then
        hidePreviewOverlays()
        return
    end
    local width, height = right - left, bottom - top
    local centerX = left + width * 0.5
    PreviewBox.BackgroundColor3 = color
    PreviewBox.BackgroundTransparency = State.Visuals.BoxFilled and 0.82 or 1
    PreviewBox.Position = UDim2.fromOffset(left, top)
    PreviewBox.Size = UDim2.fromOffset(width, height)
    PreviewBoxStroke.Color = color
    PreviewBoxStroke.Thickness = State.Visuals.Thickness
    PreviewBox.Visible = visualsEnabled and State.Visuals.Boxes
    PreviewName.Text = LocalPlayer.DisplayName
    PreviewName.TextColor3 = color
    PreviewName.Position = UDim2.fromOffset(centerX - 90, top - 38)
    PreviewName.Size = UDim2.fromOffset(180, 20)
    PreviewName.Visible = visualsEnabled and State.Visuals.Names
    local boundsCFrame = previewModel:GetBoundingBox()
    PreviewDistance.Text = tostring(math.floor((PreviewCamera.CFrame.Position - boundsCFrame.Position).Magnitude + 0.5)) .. " studs"
    PreviewDistance.Position = UDim2.fromOffset(centerX - 45, top - 19)
    PreviewDistance.Size = UDim2.fromOffset(90, 18)
    PreviewDistance.Visible = visualsEnabled and State.Visuals.Distance
    local sourceHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local healthRatio = sourceHumanoid and math.clamp(sourceHumanoid.Health / math.max(1, sourceHumanoid.MaxHealth), 0, 1) or 0
    PreviewHealthBg.Position = UDim2.fromOffset(right + 5, top)
    PreviewHealthBg.Size = UDim2.fromOffset(8, height)
    PreviewHealthBg.Visible = visualsEnabled and State.Visuals.Health
    PreviewHealth.Position = UDim2.fromOffset(1, height - 1)
    PreviewHealth.Size = UDim2.fromOffset(6, math.max(0, (height - 2) * healthRatio))
    PreviewHealth.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - healthRatio)), math.floor(235 * healthRatio), 70)
    PreviewHealth.Visible = PreviewHealthBg.Visible
    local previewHeadPart = previewModel:FindFirstChild("Head")
    local headScreen = previewHeadPart and PreviewCamera:WorldToViewportPoint(previewHeadPart.Position)
    PreviewHead.BackgroundColor3 = color
    if visualsEnabled and State.Visuals.HeadDot and headScreen and headScreen.Z > 0 then
        PreviewHead.Position = UDim2.fromOffset(headScreen.X, headScreen.Y)
        PreviewHead.Visible = true
    else
        PreviewHead.Visible = false
    end
    if visualsEnabled and State.Visuals.Skeleton then
        updateSkeleton(PreviewSkeletonRecord, previewModel, PreviewCamera, color)
    else
        PreviewSkeletonLayer.Visible = false
    end
end))
end
setupVisualPreview()

end

local MiscPage = pages.Misc
do
local MovementPage = pages.Movement
local MoveCard = createCard(MovementPage, "Movement")
addToggle(MoveCard, "Speed", function() return State.Movement.Speed end, function(value)
    State.Movement.Speed = value
    if not value then
        local _, humanoid = getCharacter(LocalPlayer)
        if humanoid then humanoid.WalkSpeed = humanoidDefaults[humanoid] and humanoidDefaults[humanoid].WalkSpeed or 16 end
    end
    refreshControls()
end, true)
addSlider(MoveCard, "Speed Value", 0, 1000, function() return State.Movement.SpeedValue end, function(value) State.Movement.SpeedValue = value end, nil, function() return State.Movement.Speed end)
local speedMethodControl = addCycle(MoveCard, "Speed Method", {"WalkSpeed", "Velocity", "CFrame"}, function() return State.Movement.SpeedMethod end, function(value) State.Movement.SpeedMethod = value end)
table.insert(controlRefreshers, function()
    speedMethodControl.Holder.Visible = State.Movement.Speed
end)
addToggle(MoveCard, "Jump Power", function() return State.Movement.Jump end, function(value)
    State.Movement.Jump = value
    if not value then
        local _, humanoid = getCharacter(LocalPlayer)
        local defaults = humanoid and humanoidDefaults[humanoid]
        if humanoid and defaults then
            humanoid.JumpPower = defaults.JumpPower
            humanoid.UseJumpPower = defaults.UseJumpPower
        end
    end
end, true)
addSlider(MoveCard, "Jump Value", 50, 300, function() return State.Movement.JumpValue end, function(value) State.Movement.JumpValue = value end, nil, function() return State.Movement.Jump end)
local FlyCard = createCard(MovementPage, "Flight and Collision")
addToggle(FlyCard, "Fly", function() return State.Movement.Fly end, function(value)
    State.Movement.Fly = value
    refreshControls()
end, true)
addSlider(FlyCard, "Fly Speed", 10, 250, function() return State.Movement.FlySpeed end, function(value) State.Movement.FlySpeed = value end, nil, function() return State.Movement.Fly end)
local flyMethodControl = addCycle(FlyCard, "Fly Method", {"Velocity", "CFrame"}, function() return State.Movement.FlyMethod end, function(value) State.Movement.FlyMethod = value end)
table.insert(controlRefreshers, function()
    flyMethodControl.Holder.Visible = State.Movement.Fly
end)
addNote(FlyCard, "WASD follows the camera. Space or E moves up; Ctrl, Q or C moves down.")
addToggle(FlyCard, "Noclip", function() return State.Movement.Noclip end, function(value)
    State.Movement.Noclip = value
    if not value then restoreCollision() end
end, true)
local MobilityCard = createCard(MiscPage, "Mobility Utilities")
addToggle(MobilityCard, "Infinite Jump", function() return State.Movement.InfiniteJump end, function(value) State.Movement.InfiniteJump = value end, true)
addToggle(MobilityCard, "Bunny Hop", function() return State.Movement.BunnyHop end, function(value) State.Movement.BunnyHop = value end, true)
addToggle(MobilityCard, "Ctrl + Click Teleport", function() return State.Movement.ClickTP end, function(value) State.Movement.ClickTP = value end, true)
local ProtectionCard = createCard(MiscPage, "Character Protection")
addToggle(ProtectionCard, "Anti Fling", function() return State.Movement.AntiFling end, function(value)
    State.Movement.AntiFling = value
    if value then
        State.Movement.Fling = false
        clearFlingState()
        refreshControls()
    else
        UI.ClearAntiFlingState()
    end
end, true)
addToggle(ProtectionCard, "Godmode", function() return State.Movement.Godmode end, function(value)
    State.Movement.Godmode = value
    if not value then clearGodmodeState() end
end, true)
local FlingCard = createCard(MiscPage, "Fling")
addToggle(FlingCard, "Enabled", function() return State.Movement.Fling end, function(value)
    State.Movement.Fling = value
    if value then
        State.Movement.AntiFling = false
        UI.ClearAntiFlingState()
        State.Movement.Fly = false
        State.Movement.Noclip = false
        restoreCollision()
    else
        clearFlingState()
    end
    refreshControls()
end, true)
addSlider(FlingCard, "Fling Power", 1000, 100000, function() return State.Movement.FlingPower end, function(value) State.Movement.FlingPower = value end, nil, function() return State.Movement.Fling end)
addSlider(FlingCard, "Fly Fling Speed", 10, 300, function() return State.Movement.FlingFlySpeed end, function(value) State.Movement.FlingFlySpeed = value end, nil, function() return State.Movement.Fling and State.Movement.FlingMode == "Fly Fling" end)
addCycle(FlingCard, "Fling Mode", {"Walk Fling", "Fly Fling", "Contact Fling"}, function() return State.Movement.FlingMode end, function(value) State.Movement.FlingMode = value end)
addNote(FlingCard, "Your avatar never spins. Walk uses a continuous hidden pulse, Contact pulses only while touching a player, and Fly uses WASD/Space/Ctrl. Local position is restored every pulse.")
local GravityCard = createCard(MovementPage, "World Physics")
addToggle(GravityCard, "Custom Gravity", function() return State.Movement.Gravity end, function(value)
    State.Movement.Gravity = value
    Workspace.Gravity = value and State.Movement.GravityValue or originalGravity
end, true)
addSlider(GravityCard, "Gravity", 0, 1000, function() return State.Movement.GravityValue end, function(value)
    State.Movement.GravityValue = value
    if State.Movement.Gravity then Workspace.Gravity = value end
end, 1, function() return State.Movement.Gravity end)
local OrbitCard = createCard(MiscPage, "Orbit")
local orbitSelectionRow = Instance.new("Frame")
orbitSelectionRow.BackgroundTransparency = 1
orbitSelectionRow.AutomaticSize = Enum.AutomaticSize.Y
orbitSelectionRow.Size = UDim2.new(1, 0, 0, 42)
orbitSelectionRow.Parent = OrbitCard
local orbitSelectionLayout = Instance.new("UIListLayout")
orbitSelectionLayout.FillDirection = Enum.FillDirection.Horizontal
orbitSelectionLayout.VerticalAlignment = Enum.VerticalAlignment.Top
orbitSelectionLayout.Padding = UDim.new(0, 8)
orbitSelectionLayout.Parent = orbitSelectionRow
local orbitPlayerSlot = Instance.new("Frame")
orbitPlayerSlot.BackgroundTransparency = 1
orbitPlayerSlot.AutomaticSize = Enum.AutomaticSize.Y
orbitPlayerSlot.Size = UDim2.new(0.5, -4, 0, 42)
orbitPlayerSlot:SetAttribute("ForceFullWidth", true)
orbitPlayerSlot.Parent = orbitSelectionRow
local orbitModeSlot = orbitPlayerSlot:Clone()
orbitModeSlot.Parent = orbitSelectionRow
UI.OrbitPlayerDropdown = UI.AddPlayerDropdown(orbitPlayerSlot, "Player", function()
    return selectedPlayer
end, function(player)
    selectedPlayer = player
end)
UI.OrbitModeDropdown = addCycle(orbitModeSlot, "Feature", {"Circle", "Wave", "Vertical Loop", "Horizontal Loop", "Spiral", "Avatar Spin", "Carpet", "Backpack", "Helicopter"}, function()
    return State.Movement.OrbitMode
end, function(value)
    State.Movement.OrbitMode = value
    refreshControls()
end)
UI.RefreshOrbitPlayers = function()
    if UI.OrbitPlayerDropdown and UI.OrbitPlayerDropdown.Refresh then
        UI.OrbitPlayerDropdown.Refresh()
    end
end
trackConnection(Players.PlayerAdded:Connect(function()
    task.defer(UI.RefreshOrbitPlayers)
end))
trackConnection(Players.PlayerRemoving:Connect(function(player)
    if selectedPlayer == player then selectedPlayer = nil end
    task.defer(UI.RefreshOrbitPlayers)
end))
addToggle(OrbitCard, "Orbit Selected Player", function() return State.Movement.Orbit end, function(value)
    State.Movement.Orbit = value
    if not value then clearOrbitMotion() end
end, true)
addSlider(OrbitCard, "Orbit Radius", 2, 30, function() return State.Movement.OrbitRadius end, function(value) State.Movement.OrbitRadius = value end, nil, function() return State.Movement.Orbit end)
addSlider(OrbitCard, "Orbit Speed", 0.2, 100, function() return State.Movement.OrbitSpeed end, function(value) State.Movement.OrbitSpeed = value end, 1, function() return State.Movement.Orbit end)
addSlider(OrbitCard, "Feature Height", -5, 20, function() return State.Movement.OrbitHeight end, function(value) State.Movement.OrbitHeight = value end, 1, function()
    return State.Movement.Orbit and table.find({"Wave", "Spiral", "Carpet", "Backpack", "Helicopter"}, State.Movement.OrbitMode) ~= nil
end)
addSlider(OrbitCard, "Feature Offset", 0, 10, function() return State.Movement.OrbitOffset end, function(value) State.Movement.OrbitOffset = value end, 1, function()
    return State.Movement.Orbit and table.find({"Carpet", "Backpack", "Helicopter"}, State.Movement.OrbitMode) ~= nil
end)
end

do
local WorldPage = pages.World
local LightingCard = createCard(WorldPage, "Lighting")
addSlider(LightingCard, "Glow Strength", 0, 4, function() return State.World.GlowIntensity end, function(value)
    State.World.GlowIntensity = value
    applyWorld()
end, 2, function() return State.World.LightingMode == "Glow" end)
addSlider(LightingCard, "Neon Intensity", 0, 5, function() return State.World.NeonIntensity end, function(value)
    State.World.NeonIntensity = value
    applyWorld()
end, 2, function() return State.World.LightingMode == "Neon Glow" end)
addSlider(LightingCard, "Neon Size", 0, 56, function() return State.World.NeonSize end, function(value)
    State.World.NeonSize = value
    applyWorld()
end, nil, function() return State.World.LightingMode == "Neon Glow" end)
addSlider(LightingCard, "Neon Threshold", 0, 1, function() return State.World.NeonThreshold end, function(value)
    State.World.NeonThreshold = value
    applyWorld()
end, 2, function() return State.World.LightingMode == "Neon Glow" end)
for _, channel in ipairs({{"Red", "ManualRed"}, {"Green", "ManualGreen"}, {"Blue", "ManualBlue"}}) do
    local labelName, propertyName = channel[1], channel[2]
    addSlider(LightingCard, "Manual " .. labelName, 0, 255, function() return State.World[propertyName] end, function(value)
        State.World[propertyName] = value
        applyWorld()
    end, nil, function() return State.World.LightingMode == "Manual" end)
end
addSlider(LightingCard, "Manual Brightness", -1, 1, function() return State.World.ManualBrightness end, function(value)
    State.World.ManualBrightness = value
    applyWorld()
end, 2, function() return State.World.LightingMode == "Manual" end)
addSlider(LightingCard, "Manual Contrast", -1, 1, function() return State.World.ManualContrast end, function(value)
    State.World.ManualContrast = value
    applyWorld()
end, 2, function() return State.World.LightingMode == "Manual" end)
addSlider(LightingCard, "Manual Saturation", -1, 1, function() return State.World.ManualSaturation end, function(value)
    State.World.ManualSaturation = value
    applyWorld()
end, 2, function() return State.World.LightingMode == "Manual" end)
addCycle(LightingCard, "Vision Mode", {"Default", "Glow", "Neon Glow", "Manual"}, function() return State.World.LightingMode end, function(value)
    State.World.LightingMode = value
    applyWorld()
    refreshControls()
end)
addToggle(LightingCard, "Fullbright", function() return State.World.Fullbright end, function(value)
    State.World.Fullbright = value
    applyWorld()
end, true)
addToggle(LightingCard, "Remove Fog", function() return State.World.NoFog end, function(value)
    State.World.NoFog = value
    applyWorld()
end, true)
addToggle(LightingCard, "Flat Textures", function() return State.World.FlatTextures end, function(value)
    State.World.FlatTextures = value
    applyWorld()
    refreshControls()
end, true)
addNote(LightingCard, "Flat Textures removes texture maps while preserving each object's own color. Disabling it restores every saved material and texture client-side.")
local RGBCard = createCard(WorldPage, "RGB Effects")
for _, scopeName in ipairs({"ESP", "Aim", "World"}) do
    local scope = scopeName
    addToggle(RGBCard, scope .. " RGB", function() return State.World.RGB[scope].Enabled end, function(value)
        State.World.RGB[scope].Enabled = value
        if scope == "World" then applyWorld() end
        refreshControls()
    end)
    addSlider(RGBCard, scope .. " Speed", 0.02, 1.2, function() return State.World.RGB[scope].Speed end, function(value)
        State.World.RGB[scope].Speed = value
    end, 2, function() return State.World.RGB[scope].Enabled end)
    addSlider(RGBCard, scope .. " Saturation", 0, 1, function() return State.World.RGB[scope].Saturation end, function(value)
        State.World.RGB[scope].Saturation = value
    end, 2, function() return State.World.RGB[scope].Enabled end)
    addSlider(RGBCard, scope .. " Brightness", 0.2, 1, function() return State.World.RGB[scope].Brightness end, function(value)
        State.World.RGB[scope].Brightness = value
    end, 2, function() return State.World.RGB[scope].Enabled end)
end
local CameraCard = createCard(WorldPage, "Camera")
addSlider(CameraCard, "Field of View", 40, 120, function() return State.World.CameraFOV end, function(value) State.World.CameraFOV = value end)
addToggle(CameraCard, "Third Person", function() return State.World.ThirdPerson end, function(value) State.World.ThirdPerson = value end, true)
local FreecamCard = createCard(WorldPage, "Freecam")
addToggle(FreecamCard, "Freecam", function() return State.World.Freecam end, function(value)
    State.World.Freecam = value
    refreshControls()
end, true)
addSlider(FreecamCard, "Freecam Speed", 0.2, 8, function() return State.World.FreecamSpeed end, function(value) State.World.FreecamSpeed = value end, 1, function() return State.World.Freecam end)
local freecamTeleportButton = addAction(FreecamCard, "Teleport Player to Freecam", function()
    local camera = Workspace.CurrentCamera
    local _, _, root = getCharacter(LocalPlayer)
    if not camera or not root then return end
    local look = camera.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
    root.CFrame = CFrame.lookAt(camera.CFrame.Position - Vector3.new(0, 2.5, 0), camera.CFrame.Position - Vector3.new(0, 2.5, 0) + flatLook.Unit)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end)
UI.BindActionIcon(freecamTeleportButton, "FreecamTeleport")
table.insert(controlRefreshers, function()
    freecamTeleportButton.Visible = State.World.Freecam
end)
local WaypointCard = createCard(MiscPage, "Waypoints")
local waypointStatus = addNote(WaypointCard, "No waypoint selected")
UI.WaypointDropdown = UI.AddDropdown(WaypointCard, "Saved Waypoint", {}, function()
    local entry = State.Waypoints[selectedWaypoint]
    return entry and string.format("%d · %s", selectedWaypoint, entry.Name) or nil
end, function(value)
    local index = tonumber(tostring(value):match("^(%d+)"))
    if index and State.Waypoints[index] then
        selectedWaypoint = index
        waypointStatus.Text = State.Waypoints[index].Name
    end
end, false)
UI.RefreshWaypointList = function()
    local options = {}
    for index, entry in ipairs(State.Waypoints) do
        table.insert(options, string.format("%d · %s", index, entry.Name))
    end
    selectedWaypoint = math.clamp(selectedWaypoint, 1, math.max(1, #State.Waypoints))
    UI.WaypointDropdown:SetOptions(options)
    UI.WaypointDropdown:Render()
    waypointStatus.Text = State.Waypoints[selectedWaypoint] and State.Waypoints[selectedWaypoint].Name or "No waypoint selected"
end

UI.WaypointActions = Instance.new("Frame")
UI.WaypointActions.BackgroundTransparency = 1
UI.WaypointActions.Size = UDim2.new(1, 0, 0, 46)
UI.WaypointActions.Parent = WaypointCard
UI.WaypointActionLayout = Instance.new("UIListLayout")
UI.WaypointActionLayout.FillDirection = Enum.FillDirection.Horizontal
UI.WaypointActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UI.WaypointActionLayout.Padding = UDim.new(0, 10)
UI.WaypointActionLayout.Parent = UI.WaypointActions
UI.WaypointSave = button(UI.WaypointActions, "+", UDim2.new(1 / 3, -7, 0, 46))
UI.WaypointSave.TextSize = 27
UI.WaypointTeleport = button(UI.WaypointActions, "", UDim2.new(1 / 3, -7, 0, 46))
UI.WaypointDelete = button(UI.WaypointActions, "", UDim2.new(1 / 3, -7, 0, 46))
UI.BindActionIcon(UI.WaypointSave, "WaypointSave")
do
    local pin = Instance.new("Frame")
    pin.AnchorPoint = Vector2.new(0.5, 0.5)
    pin.BackgroundTransparency = 1
    pin.Position = UDim2.fromOffset(23, 19)
    pin.Size = UDim2.fromOffset(17, 17)
    pin.Parent = UI.WaypointTeleport
    round(pin, 17)
    stroke(pin, nil, 2, 0)
    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Theme.Accent
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.Size = UDim2.fromOffset(5, 5)
    dot.Parent = pin
    round(dot, 5)
    UI.BindTheme(dot, "BackgroundColor3", "Accent")
    local stem = Instance.new("Frame")
    stem.AnchorPoint = Vector2.new(0.5, 0.5)
    stem.BackgroundColor3 = Theme.Accent
    stem.Position = UDim2.fromOffset(23, 31)
    stem.Rotation = 45
    stem.Size = UDim2.fromOffset(8, 8)
    stem.Parent = UI.WaypointTeleport
    UI.BindTheme(stem, "BackgroundColor3", "Accent")
    local bin = Instance.new("Frame")
    bin.AnchorPoint = Vector2.new(0.5, 0.5)
    bin.BackgroundColor3 = Theme.Accent
    bin.Position = UDim2.fromOffset(23, 25)
    bin.Size = UDim2.fromOffset(16, 18)
    bin.Parent = UI.WaypointDelete
    round(bin, 3)
    UI.BindTheme(bin, "BackgroundColor3", "Accent")
    local lid = Instance.new("Frame")
    lid.AnchorPoint = Vector2.new(0.5, 0.5)
    lid.BackgroundColor3 = Theme.Accent
    lid.Position = UDim2.fromOffset(23, 14)
    lid.Size = UDim2.fromOffset(22, 4)
    lid.Parent = UI.WaypointDelete
    round(lid, 2)
    UI.BindTheme(lid, "BackgroundColor3", "Accent")
    UI.BindActionIcon(UI.WaypointTeleport, "WaypointTeleport", {pin, stem})
    UI.BindActionIcon(UI.WaypointDelete, "WaypointDelete", {bin, lid})
end

local function saveWaypoint()
    local _, _, root = getCharacter(LocalPlayer)
    if not root then return end
    local components = {root.CFrame:GetComponents()}
    table.insert(State.Waypoints, {Name = "Waypoint " .. tostring(#State.Waypoints + 1), CFrame = components})
    selectedWaypoint = #State.Waypoints
    UI.RefreshWaypointList()
end
local function teleportWaypoint()
    local entry = State.Waypoints[selectedWaypoint]
    local _, _, root = getCharacter(LocalPlayer)
    if entry and root and type(entry.CFrame) == "table" and #entry.CFrame >= 12 then
        root.CFrame = CFrame.new(table.unpack(entry.CFrame))
    end
end
local function deleteWaypoint()
    local entry = State.Waypoints[selectedWaypoint]
    if not entry then return end
    UI.ShowConfirm("Delete Waypoint", "Delete “" .. entry.Name .. "”? This cannot be undone.", function()
        table.remove(State.Waypoints, selectedWaypoint)
        UI.RefreshWaypointList()
    end)
end
UI.WaypointSave.Activated:Connect(saveWaypoint)
UI.WaypointTeleport.Activated:Connect(teleportWaypoint)
UI.WaypointDelete.Activated:Connect(deleteWaypoint)
local waypointBindRow = Instance.new("Frame")
waypointBindRow.BackgroundTransparency = 1
waypointBindRow.Size = UDim2.new(1, 0, 0, 32)
waypointBindRow.Parent = WaypointCard
local waypointBindLayout = Instance.new("UIListLayout")
waypointBindLayout.FillDirection = Enum.FillDirection.Horizontal
waypointBindLayout.Padding = UDim.new(0, 10)
waypointBindLayout.Parent = waypointBindRow
for _, bindData in ipairs({
    {"WaypointSave", "Save", saveWaypoint},
    {"WaypointTeleport", "Teleport", teleportWaypoint},
    {"WaypointDelete", "Delete", deleteWaypoint}
}) do
    local bindId = "Misc/Waypoints/" .. bindData[1]
    local bindButton = button(waypointBindRow, bindData[2] .. ": " .. (State.Keybinds[bindId] or "Bind"), UDim2.new(1 / 3, -7, 0, 32))
    bindButton.TextSize = 13
    keybindActions[bindId] = bindData[3]
    bindButton.Activated:Connect(function()
        pendingKeybind = {Id = bindId, Button = bindButton, Prefix = bindData[2] .. ": "}
        bindButton.Text = bindData[2] .. ": ..."
    end)
end
UI.Register("Misc/Waypoints/Save Current Position", {Instance = UI.WaypointSave})
UI.Register("Misc/Waypoints/Teleport to Waypoint", {Instance = UI.WaypointTeleport})
UI.Register("Misc/Waypoints/Delete Selected Waypoint", {Instance = UI.WaypointDelete})
UI.RefreshWaypointList()
end

do
local PlayersPage = pages.Players
PlayersPage.ScrollingEnabled = false
PlayersPage.ScrollBarThickness = 0
local PlayerCard = UI.AddStaticCard(PlayersPage, "Live Players")
UI.AddDropdown(PlayerCard, "Sort Players", {"Nearest", "Name A-Z", "Health High-Low", "Health Low-High"}, function()
    return State.Players.Sort
end, function(value)
    State.Players.Sort = value
end, false)
local playerSearch = addInput(PlayerCard, "Search username or display name", "")
local PlayerList = Instance.new("ScrollingFrame")
PlayerList.BackgroundColor3 = Theme.Surface2
PlayerList.BackgroundTransparency = 0.2
PlayerList.BorderSizePixel = 0
PlayerList.ClipsDescendants = true
PlayerList.Active = true
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.CanvasSize = UDim2.new()
PlayerList.ScrollingDirection = Enum.ScrollingDirection.Y
PlayerList.ScrollBarThickness = 4
PlayerList.ScrollBarImageColor3 = Theme.Accent
PlayerList.Size = UDim2.new(1, 0, 0, 220)
PlayerList.Parent = PlayerCard
round(PlayerList, 10)
UI.BindTheme(PlayerList, "BackgroundColor3", "Surface2")
UI.BindTheme(PlayerList, "ScrollBarImageColor3", "Accent")
local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerList
local PlayerListPadding = Instance.new("UIPadding")
PlayerListPadding.PaddingLeft = UDim.new(0, 6)
PlayerListPadding.PaddingRight = UDim.new(0, 6)
PlayerListPadding.PaddingTop = UDim.new(0, 6)
PlayerListPadding.PaddingBottom = UDim.new(0, 6)
PlayerListPadding.Parent = PlayerList
local playerRows = {}

local function createPlayerRow(player)
    local row = Instance.new("Frame")
    row.Name = tostring(player.UserId)
    row.BackgroundColor3 = Theme.Surface
    row.BackgroundTransparency = 0.06
    row.Size = UDim2.new(1, 0, 0, 42)
    row.Parent = PlayerList
    round(row, 9)
    UI.BindTheme(row, "BackgroundColor3", "Surface")
    local avatar = Instance.new("ImageLabel")
    avatar.BackgroundColor3 = Theme.AccentSoft
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
    avatar.Size = UDim2.fromOffset(32, 32)
    avatar.Position = UDim2.fromOffset(6, 5)
    avatar.Parent = row
    UI.BindTheme(avatar, "BackgroundColor3", "AccentSoft")
    round(avatar, 16)
    local name = textLabel(row, player.DisplayName, UDim2.new(1, -312, 0, 19), UDim2.fromOffset(46, 3), 14, Theme.Text)
    name.FontFace = UI.Fonts.Option
    local details = textLabel(row, "", UDim2.new(1, -312, 0, 16), UDim2.fromOffset(46, 22), 12, Theme.Muted)
    local healthTrack = Instance.new("Frame")
    healthTrack.BackgroundColor3 = Color3.fromRGB(220, 234, 244)
    healthTrack.Size = UDim2.fromOffset(94, 5)
    healthTrack.Position = UDim2.new(1, -255, 0, 7)
    healthTrack.Parent = row
    UI.BindTheme(healthTrack, "BackgroundColor3", "Track")
    round(healthTrack, 5)
    local healthFill = Instance.new("Frame")
    healthFill.BackgroundColor3 = Color3.fromRGB(93, 202, 133)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.Parent = healthTrack
    round(healthFill, 5)
    local healthText = textLabel(row, "", UDim2.fromOffset(94, 16), UDim2.new(1, -255, 0, 19), 12, Theme.Muted, Enum.TextXAlignment.Center)
    local fling = button(row, "Fling", UDim2.fromOffset(62, 28), UDim2.new(1, -154, 0.5, -14))
    local view = button(row, "◉", UDim2.fromOffset(48, 28), UDim2.new(1, -86, 0.5, -14))
    local teleport = button(row, "TP", UDim2.fromOffset(30, 28), UDim2.new(1, -34, 0.5, -14))
    fling.TextSize = 14
    view.TextSize = 19
    teleport.TextSize = 14
    local flingIcon = UI.BindActionIcon(fling, "PlayerFling", nil, "      Fling")
    flingIcon.Position = UDim2.fromOffset(14, 14)
    flingIcon.Size = UDim2.fromOffset(16, 16)
    local viewIcon = UI.BindActionIcon(view, "PlayerView")
    local teleportIcon = UI.BindActionIcon(teleport, "PlayerTeleport")
    teleportIcon.Size = UDim2.fromOffset(18, 18)
    fling.Activated:Connect(function()
        UI.FlingTarget(player, false)
    end)
    view.Activated:Connect(function()
        local alive, _, humanoid = getAlive(player)
        local camera = Workspace.CurrentCamera
        if alive and camera then
            if camera.CameraSubject == humanoid then
                local _, localHumanoid = getCharacter(LocalPlayer)
                if localHumanoid then camera.CameraSubject = localHumanoid end
            else
                camera.CameraSubject = humanoid
            end
            for rowPlayer, record in pairs(playerRows) do
                local viewing = camera.CameraSubject == (rowPlayer.Character and rowPlayer.Character:FindFirstChildOfClass("Humanoid"))
                record.View.Text = viewing and "■" or "◉"
                if record.ViewIcon then
                    local iconName = viewing and "PlayerStop" or "PlayerView"
                    local url = UI.ActionIconUrls[iconName]
                    record.ViewIcon.Image = UI.ActionIconAssets[iconName] or url
                    record.ViewIcon.Visible = url ~= ""
                    if url ~= "" then record.View.Text = "" end
                end
            end
        end
    end)
    teleport.Activated:Connect(function()
        local alive, _, _, targetRoot = getAlive(player)
        local _, _, root = getCharacter(LocalPlayer)
        if alive and root then root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4) end
    end)
    playerRows[player] = {Row = row, Name = name, Details = details, HealthFill = healthFill, HealthText = healthText, Fling = fling, View = view, ViewIcon = viewIcon}
end

local function refreshPlayerRows()
    local query = string.lower(playerSearch.Text)
    local _, _, localRoot = getCharacter(LocalPlayer)
    local sortedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(sortedPlayers, player) end
    end
    table.sort(sortedPlayers, function(first, second)
        if State.Players.Sort == "Name A-Z" then
            return string.lower(first.DisplayName) < string.lower(second.DisplayName)
        end
        local firstAlive, _, firstHumanoid, firstRoot = getAlive(first)
        local secondAlive, _, secondHumanoid, secondRoot = getAlive(second)
        if State.Players.Sort == "Health High-Low" or State.Players.Sort == "Health Low-High" then
            local firstHealth = firstAlive and firstHumanoid.Health or 0
            local secondHealth = secondAlive and secondHumanoid.Health or 0
            if State.Players.Sort == "Health Low-High" then
                return firstHealth < secondHealth
            end
            return firstHealth > secondHealth
        end
        local firstDistance = firstRoot and localRoot and (firstRoot.Position - localRoot.Position).Magnitude or math.huge
        local secondDistance = secondRoot and localRoot and (secondRoot.Position - localRoot.Position).Magnitude or math.huge
        return firstDistance < secondDistance
    end)
    for order, player in ipairs(sortedPlayers) do
        if not playerRows[player] then createPlayerRow(player) end
        local record = playerRows[player]
        local matches = query == "" or string.find(string.lower(player.Name), query, 1, true) or string.find(string.lower(player.DisplayName), query, 1, true)
        record.Row.LayoutOrder = order
        record.Row.Visible = matches
        if matches then
            local alive, _, humanoid, root = getAlive(player)
            local distance = root and localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
            local ratio = alive and math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1) or 0
            record.Name.Text = player.DisplayName .. "  @" .. player.Name
            record.Details.Text = string.format("%s  •  %.0f studs", areTeammates(player, LocalPlayer) and "Teammate" or "Other", distance)
            record.HealthFill.Size = UDim2.fromScale(ratio, 1)
            record.HealthText.Text = string.format("%.0f%%", ratio * 100)
            local camera = Workspace.CurrentCamera
            local viewing = camera and camera.CameraSubject == humanoid
            local iconName = viewing and "PlayerStop" or "PlayerView"
            local url = UI.ActionIconUrls[iconName]
            record.ViewIcon.Image = UI.ActionIconAssets[iconName] or url
            record.ViewIcon.Visible = url ~= ""
            record.View.Text = url ~= "" and "" or (viewing and "■" or "◉")
        end
    end
    for player, record in pairs(playerRows) do
        if player.Parent ~= Players then
            record.Row:Destroy()
            playerRows[player] = nil
        end
    end
end
playerSearch.FocusLost:Connect(refreshPlayerRows)
playerSearch:GetPropertyChangedSignal("Text"):Connect(refreshPlayerRows)
local playerStatusClock = 0
trackConnection(RunService.Heartbeat:Connect(function(deltaTime)
    playerStatusClock = playerStatusClock + deltaTime
    if playerStatusClock < 0.1 then return end
    playerStatusClock = 0
    refreshPlayerRows()
end))
end

local function sanitizeName(value)
    return string.gsub(tostring(value), "[^%w_%-]", "_")
end

local function httpGet(url)
    local request = getRequest()
    if request then
        local ok, response = pcall(request, {Url = url, Method = "GET"})
        if not ok or type(response) ~= "table" then
            return nil, "Request failed"
        end
        local statusCode = response.StatusCode or response.Status or response.status_code
        if statusCode and statusCode >= 400 then
            return nil, "HTTP " .. tostring(statusCode)
        end
        return response.Body or response.body
    end
    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        return nil, "Request failed"
    end
    return response
end

local function parsePlaceId(value)
    local direct = tonumber(value)
    if direct then return math.floor(direct) end
    local text = tostring(value or "")
    local matched = string.match(text, "roblox%.com/games/(%d+)") or string.match(text, "[?&]placeId=(%d+)") or string.match(text, "/places/(%d+)")
    return matched and tonumber(matched) or nil
end

local MM2_CATALOG_URL = "https://raw.githubusercontent.com/tahs1nkkk/TasuScriptHub/refs/heads/main/mm2.lua"
local function ensureBuiltinCatalogEntries()
    for _, entry in ipairs(State.Catalog) do
        if entry.BuiltInId == "mm2" then
            entry.Name = "Murder Mystery 2"
            entry.PlaceId = 142823291
            entry.Url = MM2_CATALOG_URL
            return
        end
    end
    table.insert(State.Catalog, 1, {
        BuiltInId = "mm2",
        Name = "Murder Mystery 2",
        PlaceId = 142823291,
        Url = MM2_CATALOG_URL
    })
end
ensureBuiltinCatalogEntries()

local updateCatalogStatus = function() end
local function setupCatalog()
local CatalogPage = pages.Catalog
local CatalogCard = UI.AddStaticCard(CatalogPage, "Script Catalog")
local CatalogGrid = Instance.new("Frame")
CatalogGrid.BackgroundTransparency = 1
CatalogGrid.AutomaticSize = Enum.AutomaticSize.Y
CatalogGrid.Size = UDim2.new(1, 0, 0, 0)
CatalogGrid.Parent = CatalogCard
local CatalogLayout = Instance.new("UIGridLayout")
CatalogLayout.CellPadding = UDim2.fromOffset(10, 10)
CatalogLayout.CellSize = UDim2.fromOffset(195, 232)
CatalogLayout.SortOrder = Enum.SortOrder.LayoutOrder
CatalogLayout.Parent = CatalogGrid

local catalogEditingIndex
local catalogOverlay = Instance.new("Frame")
catalogOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
catalogOverlay.BackgroundTransparency = 0.38
catalogOverlay.Size = UDim2.fromScale(1, 1)
catalogOverlay.Visible = false
catalogOverlay.ZIndex = 70
catalogOverlay.Parent = ContentWindow
round(catalogOverlay, 16)
local catalogEditor = Instance.new("Frame")
catalogEditor.AnchorPoint = Vector2.new(0.5, 0.5)
catalogEditor.BackgroundColor3 = Theme.Surface
catalogEditor.Position = UDim2.fromScale(0.5, 0.5)
catalogEditor.Size = UDim2.fromOffset(510, 344)
catalogEditor.ZIndex = 71
catalogEditor.Parent = catalogOverlay
round(catalogEditor, 16)
UI.BindTheme(catalogEditor, "BackgroundColor3", "Surface")
local catalogEditorTitle = textLabel(catalogEditor, "New Save", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 12), 20, Theme.Text, Enum.TextXAlignment.Center)
catalogEditorTitle.ZIndex = 72
catalogEditorTitle.FontFace = UI.Fonts.HeadingHeavy
local function catalogField(placeholder, y, height, multiLine)
    local field = Instance.new("TextBox")
    field.BackgroundColor3 = Theme.Surface2
    field.ClearTextOnFocus = false
    field.PlaceholderText = placeholder
    field.PlaceholderColor3 = Theme.Muted
    field.Text = ""
    field.TextColor3 = Theme.Text
    field.TextSize = 15
    field.FontFace = UI.Fonts.Option
    field.MultiLine = multiLine == true
    field.TextWrapped = multiLine == true
    field.TextXAlignment = Enum.TextXAlignment.Left
    field.TextYAlignment = multiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    field.Position = UDim2.fromOffset(18, y)
    field.Size = UDim2.new(1, -36, 0, height)
    field.ZIndex = 72
    field.Parent = catalogEditor
    round(field, 9)
    UI.BindTheme(field, "BackgroundColor3", "Surface2")
    UI.BindTheme(field, "TextColor3", "Text")
    UI.BindTheme(field, "PlaceholderColor3", "Muted")
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, multiLine and 7 or 0)
    padding.Parent = field
    return field
end
local catalogName = catalogField("Game / save name", 50, 34, false)
local catalogPlace = catalogField("PlaceId or Roblox game URL", 91, 34, false)
local catalogUrl = catalogField("HTTPS raw script URL (optional)", 132, 34, false)
local catalogSource = catalogField("Script source", 173, 112, true)
local catalogCancel = button(catalogEditor, "Cancel", UDim2.fromOffset(224, 36), UDim2.fromOffset(18, 296))
local catalogSave = button(catalogEditor, "Save", UDim2.fromOffset(224, 36), UDim2.new(1, -242, 0, 296))
catalogCancel.ZIndex = 72
catalogSave.ZIndex = 72

local function closeCatalogEditor()
    catalogOverlay.Visible = false
    catalogSource:ReleaseFocus()
end
local function openCatalogEditor(index)
    catalogEditingIndex = index
    local entry = index and State.Catalog[index] or nil
    catalogEditorTitle.Text = entry and "Edit Save" or "New Save"
    catalogName.Text = entry and entry.Name or ""
    catalogPlace.Text = entry and tostring(entry.PlaceId or "") or tostring(game.PlaceId)
    catalogUrl.Text = entry and tostring(entry.Url or "") or ""
    catalogSource.Text = entry and tostring(entry.Source or "") or ""
    catalogOverlay.Visible = true
end
local function runCatalogEntry(entry)
    if entry.BuiltInId == "mm2" and game.PlaceId ~= entry.PlaceId then
        showToast("This script can only run inside Murder Mystery 2")
        return
    end
    if not capabilities.LoadString then
        showToast("Executor cannot compile scripts")
        return
    end
    local source = entry.Source
    if (not source or source == "") and type(entry.Url) == "string" and entry.Url:match("^https://") then
        source = httpGet(entry.Url)
    end
    if type(source) ~= "string" or source == "" then
        showToast("This save has no script")
        return
    end
    local chunk, compileError = loadstring(source, "TasuCatalog:" .. tostring(entry.Name))
    if not chunk then
        showToast(tostring(compileError))
        return
    end
    local ok, runtimeError = pcall(chunk)
    showToast(ok and "Script completed" or tostring(runtimeError))
end
local function fetchBanner(entry)
    if not entry or not entry.PlaceId or not capabilities.Http then return end
    local universeBody = httpGet("https://apis.roblox.com/universes/v1/places/" .. tostring(entry.PlaceId) .. "/universe")
    local universeOk, universe = pcall(HttpService.JSONDecode, HttpService, universeBody or "")
    if not universeOk or not universe.universeId then return end
    local body = httpGet("https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=" .. tostring(universe.universeId) .. "&countPerUniverse=1&defaults=true&size=768x432&format=Png&isCircular=false")
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body or "")
    local url = ok and decoded.data and decoded.data[1] and decoded.data[1].thumbnails and decoded.data[1].thumbnails[1] and decoded.data[1].thumbnails[1].imageUrl
    if not url then return end
    entry.BannerAsset = url
    if capabilities.Files and capabilities.CustomAsset then
        ensureFolder("TasuHub/Catalog/Banners")
        local imageBody = httpGet(url)
        local path = "TasuHub/Catalog/Banners/" .. sanitizeName(entry.PlaceId) .. ".png"
        local writefile = resolveGlobal("writefile")
        if imageBody and type(writefile) == "function" and pcall(writefile, path, imageBody) then entry.BannerAsset = getCustomAsset(path) or url end
    end
    updateCatalogStatus()
end
updateCatalogStatus = function()
    for _, child in ipairs(CatalogGrid:GetChildren()) do
        if child.Name == "CatalogTile" then child:Destroy() end
    end
    for index, entry in ipairs(State.Catalog) do
        local card = Instance.new("Frame")
        card.Name = "CatalogTile"
        card.LayoutOrder = index
        card.Active = true
        card.BackgroundColor3 = Theme.Surface2
        card.Parent = CatalogGrid
        round(card, 15)
        UI.BindTheme(card, "BackgroundColor3", "Surface2")
        local banner = Instance.new("ImageLabel")
        banner.BackgroundColor3 = Theme.AccentSoft
        banner.Image = entry.BannerAsset or ""
        banner.Position = UDim2.fromOffset(8, 8)
        banner.Size = UDim2.new(1, -16, 0, 136)
        banner.ScaleType = Enum.ScaleType.Crop
        banner.Parent = card
        round(banner, 12)
        UI.BindTheme(banner, "BackgroundColor3", "AccentSoft")
        local title = textLabel(card, tostring(entry.Name or "Untitled"), UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 148), 15, Theme.Text, Enum.TextXAlignment.Center)
        title.FontFace = UI.Fonts.HeadingHeavy
        local run = button(card, "▶  RUN", UDim2.fromOffset(84, 38), UDim2.fromOffset(8, 184))
        local view = button(card, "◉  VIEW", UDim2.fromOffset(84, 38), UDim2.new(1, -92, 0, 184))
        local edit = button(card, "✎", UDim2.fromOffset(34, 34), UDim2.new(1, -78, 0, 4))
        local deleteButton = button(card, "▣", UDim2.fromOffset(34, 34), UDim2.new(1, -40, 0, 4))
        edit.ZIndex = 6
        deleteButton.ZIndex = 6
        local runIcon = UI.BindActionIcon(run, "CatalogRun", nil, "      RUN")
        runIcon.Position = UDim2.fromOffset(17, 19)
        runIcon.Size = UDim2.fromOffset(17, 17)
        local viewIcon = UI.BindActionIcon(view, "CatalogView", nil, "      VIEW")
        viewIcon.Position = UDim2.fromOffset(17, 19)
        viewIcon.Size = UDim2.fromOffset(17, 17)
        UI.BindActionIcon(edit, "CatalogEdit")
        UI.BindActionIcon(deleteButton, "CatalogDelete")
        local builtIn = entry.BuiltInId ~= nil
        edit.Visible = false
        deleteButton.Visible = false
        card.MouseEnter:Connect(function()
            edit.Visible = not builtIn
            deleteButton.Visible = not builtIn
        end)
        card.MouseLeave:Connect(function()
            edit.Visible = false
            deleteButton.Visible = false
        end)
        run.Activated:Connect(function() runCatalogEntry(entry) end)
        view.Activated:Connect(function()
            if entry.BuiltInId == "mm2" then
                if game.PlaceId ~= entry.PlaceId then
                    showToast("Open Murder Mystery 2 before viewing this menu")
                    return
                end
                local mm2 = env.TasuHubMM2
                if mm2 and type(mm2.Open) == "function" then
                    mm2.Open()
                else
                    showToast("Run the MM2 catalog script first")
                end
            else
                openCatalogEditor(index)
            end
        end)
        edit.Activated:Connect(function() openCatalogEditor(index) end)
        deleteButton.Activated:Connect(function()
            UI.ShowConfirm("Delete Script", "Delete “" .. tostring(entry.Name) .. "”? This cannot be undone.", function()
                table.remove(State.Catalog, index)
                updateCatalogStatus()
            end)
        end)
        if not entry.BannerAsset then task.spawn(fetchBanner, entry) end
    end
    local newTile = Instance.new("TextButton")
    newTile.Name = "CatalogTile"
    newTile.LayoutOrder = #State.Catalog + 1
    newTile.AutoButtonColor = false
    newTile.BackgroundColor3 = Theme.Surface2
    newTile.Text = "+\n\nNEW SAVE"
    newTile.TextColor3 = Theme.Muted
    newTile.TextSize = 22
    newTile.FontFace = UI.Fonts.HeadingHeavy
    newTile.Parent = CatalogGrid
    round(newTile, 15)
    UI.BindTheme(newTile, "BackgroundColor3", "Surface2")
    UI.BindTheme(newTile, "TextColor3", "Muted")
    local newIcon = UI.BindActionIcon(newTile, "CatalogNew", nil, "\n\nNEW SAVE")
    newIcon.Position = UDim2.new(0.5, 0, 0, 70)
    newIcon.Size = UDim2.fromOffset(54, 54)
    newTile.Activated:Connect(function() openCatalogEditor(nil) end)
end
catalogCancel.Activated:Connect(closeCatalogEditor)
catalogSave.Activated:Connect(function()
    local placeId = parsePlaceId(catalogPlace.Text)
    if catalogName.Text:gsub("%s", "") == "" or not placeId then
        showToast("Name and valid PlaceId required")
        return
    end
    local entry = catalogEditingIndex and State.Catalog[catalogEditingIndex] or {}
    entry.Name = catalogName.Text
    entry.PlaceId = placeId
    entry.Url = catalogUrl.Text
    entry.Source = catalogSource.Text
    entry.BannerAsset = nil
    if not catalogEditingIndex then table.insert(State.Catalog, entry) end
    closeCatalogEditor()
    updateCatalogStatus()
    task.spawn(fetchBanner, entry)
end)
updateCatalogStatus()
end
setupCatalog()

local function configPayload()
    local payload = deepCopy(State)
    payload.Interface = {
        Title = State.Interface.Title,
        ThemeName = State.Interface.ThemeName,
        Accent = {
            R = math.round(State.Interface.Accent.R * 255),
            G = math.round(State.Interface.Accent.G * 255),
            B = math.round(State.Interface.Accent.B * 255)
        }
    }
    for _, entry in ipairs(payload.Catalog) do
        entry.BannerAsset = nil
    end
    return payload
end

local function merge(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then return end
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" and key ~= "Catalog" and key ~= "Waypoints" then
            merge(target[key], value)
        else
            target[key] = deepCopy(value)
        end
    end
end

local function saveConfig(name)
    if not capabilities.Files or not capabilities.Folders then
        return false, "Filesystem unsupported"
    end
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return false, "Config name required" end
    ensureFolder("configs")
    local path = "configs/" .. sanitizeName(name) .. ".json"
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, configPayload())
    if not ok then return false, encoded end
    local writefile = resolveGlobal("writefile")
    local saved, errorMessage = pcall(writefile, path, encoded)
    return saved, saved and path or errorMessage
end

local function loadConfig(name)
    if not capabilities.Files then
        return false, "Filesystem unsupported"
    end
    local path = "configs/" .. sanitizeName(name) .. ".json"
    local isfile = resolveGlobal("isfile")
    if type(isfile) == "function" and not isfile(path) then
        return false, "Config not found"
    end
    local readfile = resolveGlobal("readfile")
    local ok, raw = pcall(readfile, path)
    if not ok then return false, raw end
    local decodedOk, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not decodedOk or type(decoded) ~= "table" then return false, decoded end
    if type(decoded.Interface) == "table" and type(decoded.Interface.Accent) == "table" then
        local accent = decoded.Interface.Accent
        decoded.Interface.Accent = Color3.fromRGB(
            math.clamp(tonumber(accent.R) or 113, 0, 255),
            math.clamp(tonumber(accent.G) or 180, 0, 255),
            math.clamp(tonumber(accent.B) or 255, 0, 255)
        )
    end
    merge(State, decoded)
    State.Interface.RGBEnabled = nil
    State.Interface.RGBSpeed = nil
    State.Interface.RGBSaturation = nil
    State.Interface.RGBBrightness = nil
    local decodedRGB = type(decoded.World) == "table" and type(decoded.World.RGB) == "table" and decoded.World.RGB or {}
    if type(State.World.RGB) ~= "table" then State.World.RGB = {} end
    for _, scope in ipairs({"ESP", "Aim", "World"}) do
        State.World.RGB[scope] = deepCopy(Defaults.World.RGB[scope])
        if type(decodedRGB[scope]) == "table" then merge(State.World.RGB[scope], decodedRGB[scope]) end
    end
    if State.World.LightingMode == "RGB Vision" then
        State.World.LightingMode = "Default"
        State.World.RGB.World.Enabled = true
    end
    ensureBuiltinCatalogEntries()
    Theme = State.Interface
    UI.ApplyTheme(State.Interface.ThemeName or "Rework Dark", true)
    applyWorld()
    TopTitle.Text = State.Interface.Title or Theme.Title
    updateCatalogStatus()
    refreshControls()
    UI.RefreshStatsWindow()
    UI.RefreshWaypointList()
    return true, path
end

UI.SetLoading(0.9, "Son kontroller yapılıyor")

local ConfigPage = pages.Configs
do
    local appearanceCard = createCard(ConfigPage, "Appearance")
    addNote(appearanceCard, "Choose a complete theme or fine-tune the shared accent color.")
    UI.AddDropdown(appearanceCard, "Theme", {"Rework Dark"}, function()
        return State.Interface.ThemeName or "Rework Dark"
    end, function(value)
        UI.ApplyTheme(value, false)
        refreshControls()
    end, false)
    UI.AddColorPicker(appearanceCard, "Accent Color", function()
        return State.Interface.Accent
    end, function(value)
        State.Interface.Accent = value
        UI.RefreshTheme()
    end)
end
local ConfigCard = createCard(ConfigPage, "Manual Config Storage")
addNote(ConfigCard, "Files are stored in the executor's configs folder. Selecting a file loads it immediately.")
UI.SelectedConfigName = nil
UI.ConfigStatus = addNote(ConfigCard, "Select a config or save a new one")
UI.ConfigDropdown = UI.AddDropdown(ConfigCard, "Config File", {}, function()
    return UI.SelectedConfigName
end, function(value)
    UI.SelectedConfigName = value
    local ok, message = loadConfig(value)
    UI.ConfigStatus.Text = ok and "Loaded: " .. tostring(value) or "Error: " .. tostring(message)
    if ok then updateCatalogStatus() end
end, false)

UI.ListConfigs = function()
    ensureFolder("configs")
    local listfiles = resolveGlobal("listfiles")
    if type(listfiles) ~= "function" then return {} end
    local ok, paths = pcall(listfiles, "configs")
    if not ok or type(paths) ~= "table" then return {} end
    local names = {}
    for _, path in ipairs(paths) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then table.insert(names, name) end
    end
    table.sort(names, function(first, second)
        return string.lower(first) < string.lower(second)
    end)
    return names
end

UI.RefreshConfigList = function()
    local names = UI.ListConfigs()
    if UI.SelectedConfigName and not table.find(names, UI.SelectedConfigName) then
        UI.SelectedConfigName = nil
    end
    UI.ConfigDropdown:SetOptions(names)
    UI.ConfigDropdown:Render()
    if #names == 0 then
        UI.ConfigStatus.Text = capabilities.Files and "No configs found" or "Filesystem unsupported"
    end
end

addAction(ConfigCard, "Save Config", function()
    UI.OpenConfigSaveModal()
end)
addAction(ConfigCard, "Refresh Config List", function()
    UI.RefreshConfigList()
end)
addAction(ConfigCard, "Reset to Defaults", function()
    State.Movement.AntiFling = false
    State.Movement.Godmode = false
    UI.ClearAntiFlingState()
    clearFlingState()
    clearOrbitMotion()
    clearGodmodeState()
    selectedPlayer = nil
    State = deepCopy(Defaults)
    State.World.CameraFOV = originalCameraFOV
    Theme = State.Interface
    UI.ApplyTheme(State.Interface.ThemeName or "Rework Dark", false)
    restoreMovement()
    applyWorld()
    TopTitle.Text = State.Interface.Title
    if env.TasuHub then env.TasuHub.State = State end
    refreshControls()
    UI.RefreshStatsWindow()
    UI.RefreshWaypointList()
    UI.RefreshOrbitPlayers()
    updateCatalogStatus()
    UI.ConfigStatus.Text = "Defaults restored"
end)

do
    UI.ConfigOverlay = Instance.new("Frame")
    UI.ConfigOverlay.Name = "ConfigSaveModal"
    UI.ConfigOverlay.Active = true
    UI.ConfigOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.ConfigOverlay.BackgroundTransparency = 0.42
    UI.ConfigOverlay.BorderSizePixel = 0
    UI.ConfigOverlay.Size = UDim2.fromScale(1, 1)
    UI.ConfigOverlay.Visible = false
    UI.ConfigOverlay.ZIndex = 60
    UI.ConfigOverlay.Parent = ContentWindow
    round(UI.ConfigOverlay, 16)

    UI.ConfigModal = Instance.new("Frame")
    UI.ConfigModal.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.ConfigModal.BackgroundColor3 = Theme.Surface
    UI.ConfigModal.Position = UDim2.fromScale(0.5, 0.5)
    UI.ConfigModal.Size = UDim2.fromOffset(330, 178)
    UI.ConfigModal.ZIndex = 61
    UI.ConfigModal.Parent = UI.ConfigOverlay
    UI.BindTheme(UI.ConfigModal, "BackgroundColor3", "Surface")
    round(UI.ConfigModal, 16)
    gradient(UI.ConfigModal, "Surface", "Surface2", 90)
    UI.ConfigModalScale = Instance.new("UIScale")
    UI.ConfigModalScale.Parent = UI.ConfigModal

    local title = textLabel(UI.ConfigModal, "Save Config", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 14), 19, Theme.Text, Enum.TextXAlignment.Center)
    title.FontFace = UI.Fonts.HeadingHeavy
    title.ZIndex = 62
    local description = textLabel(UI.ConfigModal, "Leave empty for an automatic name.", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 45), 15, Theme.Muted, Enum.TextXAlignment.Center)
    description.FontFace = UI.Fonts.Description
    description.ZIndex = 62

    UI.ConfigNameInput = Instance.new("TextBox")
    UI.ConfigNameInput.BackgroundColor3 = Theme.Surface2
    UI.ConfigNameInput.ClearTextOnFocus = false
    UI.ConfigNameInput.PlaceholderText = "Config name"
    UI.ConfigNameInput.PlaceholderColor3 = Theme.Muted
    UI.ConfigNameInput.Text = ""
    UI.ConfigNameInput.TextColor3 = Theme.Text
    UI.ConfigNameInput.TextSize = 16
    UI.ConfigNameInput.FontFace = UI.Fonts.Option
    UI.ConfigNameInput.Position = UDim2.fromOffset(20, 76)
    UI.ConfigNameInput.Size = UDim2.new(1, -40, 0, 34)
    UI.ConfigNameInput.ZIndex = 62
    UI.ConfigNameInput.Parent = UI.ConfigModal
    UI.BindTheme(UI.ConfigNameInput, "BackgroundColor3", "Surface2")
    UI.BindTheme(UI.ConfigNameInput, "TextColor3", "Text")
    UI.BindTheme(UI.ConfigNameInput, "PlaceholderColor3", "Muted")
    round(UI.ConfigNameInput, 9)
    local inputPadding = Instance.new("UIPadding")
    inputPadding.PaddingLeft = UDim.new(0, 10)
    inputPadding.PaddingRight = UDim.new(0, 10)
    inputPadding.Parent = UI.ConfigNameInput

    UI.ConfigModalCancel = button(UI.ConfigModal, "Cancel", UDim2.fromOffset(136, 34), UDim2.fromOffset(20, 126))
    UI.ConfigModalCancel.ZIndex = 62
    UI.ConfigModalSave = button(UI.ConfigModal, "Save", UDim2.fromOffset(136, 34), UDim2.new(1, -156, 0, 126))
    UI.ConfigModalSave.ZIndex = 62

    UI.CloseConfigSaveModal = function()
        UI.ConfigOverlay.Visible = false
        UI.ConfigNameInput:ReleaseFocus()
    end
    UI.OpenConfigSaveModal = function()
        UI.ConfigNameInput.Text = ""
        UI.ConfigNameInput.PlaceholderText = "Config name"
        UI.ConfigOverlay.Visible = true
        UI.ConfigModalScale.Scale = 0.9
        animate(UI.ConfigModalScale, {Scale = 1}, 0.2, Enum.EasingStyle.Back)
        task.defer(function() UI.ConfigNameInput:CaptureFocus() end)
    end
    UI.ConfigModalCancel.Activated:Connect(UI.CloseConfigSaveModal)
    UI.ConfigModalSave.Activated:Connect(function()
        local name = UI.ConfigNameInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then
            local existing = UI.ListConfigs()
            local index = 1
            repeat
                name = "tasuhub_saveconfig_" .. tostring(index)
                index = index + 1
            until not table.find(existing, name)
        end
        local ok, message = saveConfig(name)
        if ok then
            UI.SelectedConfigName = sanitizeName(name)
            UI.ConfigStatus.Text = "Saved: " .. UI.SelectedConfigName
            UI.RefreshConfigList()
            UI.CloseConfigSaveModal()
        else
            UI.ConfigStatus.Text = "Error: " .. tostring(message)
        end
    end)
end

UI.RefreshConfigList()

UI.SetUnloadIcon = function(url)
    UI.UnloadIconUrl = tostring(url or "")
    UI.SetActionIcon("Unload", url)
end

UI.PlayUnloadScreen = function()
    return
end

unload = function()
    if unloaded then return end
    unloaded = true
    State.Aim.Enabled = false
    State.Visuals.Enabled = false
    State.Movement.Fly = false
    State.Movement.Fling = false
    State.Movement.Noclip = false
    State.Movement.Orbit = false
    State.Movement.AntiFling = false
    State.Movement.Godmode = false
    State.World.Freecam = false
    releaseFreecamCharacter()
    freecamState = nil
    clearFlingState()
    clearOrbitMotion()
    UI.ClearAntiFlingState()
    clearGodmodeState()
    restoreFlatTextures()
    colorCorrection.Enabled = false
    bloom.Enabled = false
    pcall(function()
        StarterGui:SetCore("ResetButtonCallback", true)
    end)
    restoreMovement()
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.FogStart = originalLighting.FogStart
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    local camera = Workspace.CurrentCamera
    if camera then
        camera.FieldOfView = originalCameraFOV
        camera.CameraType = Enum.CameraType.Custom
        local _, humanoid = getCharacter(LocalPlayer)
        if humanoid then camera.CameraSubject = humanoid end
    end
    LocalPlayer.CameraMinZoomDistance = originalCameraMinZoom
    LocalPlayer.CameraMaxZoomDistance = originalCameraMaxZoom
    LocalPlayer.CameraMode = originalCameraMode
    for _, player in ipairs(Players:GetPlayers()) do destroyESP(player) end
    RunService:UnbindFromRenderStep("TasuHubESP")
    RunService:UnbindFromRenderStep("TasuHubThirdPerson")
    UI.PlayUnloadScreen()
    for _, list in pairs(featureConnections) do
        for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
    end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for _, instance in ipairs(instances) do pcall(function() instance:Destroy() end) end
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    if env.TasuHub and env.TasuHub.Unload == unload then
        env.TasuHub = nil
    end
end

env.TasuHub = {
    Version = UI.Version,
    State = State,
    Flags = UI.Flags,
    SetFlag = UI.SetFlag,
    GetFlag = UI.GetFlag,
    SetCategoryIcon = UI.SetCategoryIcon,
    SetCategoryIconBackground = UI.SetCategoryIconBackground,
    SetActionIcon = UI.SetActionIcon,
    ActionIconUrls = UI.ActionIconUrls,
    SetUnloadIcon = UI.SetUnloadIcon,
    UpdateLog = UI.UpdateLog,
    Notify = UI.Notify,
    ApplyTheme = UI.ApplyTheme,
    Capabilities = capabilities,
    Open = function() return false, "UI rework in progress" end,
    Close = function() return true end,
    Toggle = function() return false, "UI rework in progress" end,
    ShowCategory = function() return false, "UI rework in progress" end,
    SaveConfig = saveConfig,
    LoadConfig = loadConfig,
    Unload = unload
}

UI.SetLoading(1, "Herşey Hazır!")
task.wait(1.3)
UI.PlaySound("FadeOut")
local loaderExitTween = animate(UI.Loader, {
    Position = UDim2.new(0, 0, 1, 200)
}, UI.DesignTokens.MotionLoaderExit, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
loaderExitTween.Completed:Wait()
UI.Loader.Visible = false
TopBar.Visible = false
ContentWindow.Visible = false
StatsPanel.Visible = false
Toast.Visible = false
UI.Ready = true
if UI.Loader then UI.Loader:Destroy() end
