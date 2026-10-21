local ConfigServiceModule = {Version = 2}

local SCHEMA = "TasuHub.Config"
local CONFIG_VERSION = 2

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local result = {}
    for key, child in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            local childType = typeof(child)
            if childType == "table" then
                result[key] = copy(child, seen)
            elseif childType == "string" or childType == "number" or childType == "boolean" then
                result[key] = child
            end
        end
    end
    seen[value] = nil
    return result
end

local function sanitizeName(value)
    local name = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[^%w%-%_ ]", "_"):gsub("%s+", "_")
    return name:sub(1, 64)
end

local function validateScalarTree(value, depth)
    depth = depth or 0
    if depth > 8 then return false end
    local valueType = type(value)
    if valueType == "string" then return #value <= 2048 end
    if valueType == "number" then return value == value and value > -math.huge and value < math.huge end
    if valueType == "boolean" then return true end
    if valueType ~= "table" then return false end
    local count = 0
    for key, child in pairs(value) do
        count = count + 1
        if count > 2048 or (type(key) ~= "string" and type(key) ~= "number")
            or not validateScalarTree(child, depth + 1) then
            return false
        end
    end
    return true
end

local function validateBindings(bindings)
    if type(bindings) ~= "table" or #bindings > 5 then return false end
    local seenIds, seenKeys = {}, {}
    for _, item in ipairs(bindings) do
        if type(item) ~= "table" then return false end
        local id, key = tostring(item.Id or ""), tostring(item.Key or "")
        if id == "" or key == "" or seenIds[id] or seenKeys[key] then return false end
        seenIds[id], seenKeys[key] = true, true
    end
    return true
end

function ConfigServiceModule.Create(context)
    assert(type(context) == "table", "config service context is required")
    assert(type(context.Encode) == "function" and type(context.Decode) == "function", "config JSON services are required")

    local root = tostring(context.Root or "TasuHub/configs/v2")
    local controller = {}

    local function pathFor(name)
        name = sanitizeName(name)
        if name == "" then return nil end
        return root .. "/" .. name .. ".json", name
    end

    local function canWrite()
        return type(context.WriteFile) == "function" and type(context.EnsureFolder) == "function"
    end

    local function canRead()
        return type(context.ReadFile) == "function"
    end

    local function buildPayload()
        local payload = {
            Schema = SCHEMA,
            Version = CONFIG_VERSION,
            HubVersion = tostring(context.HubVersion or "unknown"),
            CreatedAt = os.time(),
            General = copy(type(context.GetGeneralValues) == "function" and context.GetGeneralValues() or {}),
            Games = copy(type(context.GetGameValues) == "function" and context.GetGameValues() or {}),
            Bindings = copy(type(context.GetBindings) == "function" and context.GetBindings() or {}),
            AutoRun = copy(type(context.GetAutoRunSnapshot) == "function" and context.GetAutoRunSnapshot() or {}),
            Waypoints = copy(type(context.GetWaypoints) == "function" and context.GetWaypoints() or {})
        }
        if not validateBindings(payload.Bindings) then
            return nil, "Current bind state is invalid"
        end
        if not validateScalarTree(payload.General) or not validateScalarTree(payload.Games)
            or not validateScalarTree(payload.AutoRun) or not validateScalarTree(payload.Waypoints) then
            return nil, "Config contains unsupported state"
        end
        return payload
    end

    function controller.Save(name)
        if not canWrite() then return false, "Filesystem unsupported" end
        local path, safeName = pathFor(name)
        if not path then return false, "Config name required" end
        if not context.EnsureFolder(root) then return false, "Config folder unavailable" end
        local payload, buildError = buildPayload()
        if not payload then return false, buildError end
        local ok, encoded = pcall(context.Encode, payload)
        if not ok or type(encoded) ~= "string" then return false, tostring(encoded) end
        local saved, writeError = pcall(context.WriteFile, path, encoded)
        return saved, saved and safeName or tostring(writeError)
    end

    function controller.Load(name)
        if not canRead() then return false, "Filesystem unsupported" end
        local path = pathFor(name)
        if not path then return false, "Config name required" end
        if type(context.IsFile) == "function" and not context.IsFile(path) then return false, "Config not found" end
        local readOk, raw = pcall(context.ReadFile, path)
        if not readOk or type(raw) ~= "string" then return false, tostring(raw) end
        local decodeOk, payload = pcall(context.Decode, raw)
        if not decodeOk or type(payload) ~= "table" then return false, "Malformed config JSON" end
        if payload.Schema ~= SCHEMA or payload.Version ~= CONFIG_VERSION then
            return false, "Unsupported config schema"
        end
        if not validateBindings(payload.Bindings or {}) then return false, "Config bind list is invalid" end
        if not validateScalarTree(payload.General or {}) or not validateScalarTree(payload.Games or {})
            or not validateScalarTree(payload.AutoRun or {}) or not validateScalarTree(payload.Waypoints or {}) then
            return false, "Config payload is invalid"
        end

        local warnings = {}
        local partial = false
        if type(context.EnsureAutoRun) == "function" then
            local ok, message = context.EnsureAutoRun(copy(payload.AutoRun or {}), copy(payload.Games or {}))
            if ok == false then
                partial = true
                table.insert(warnings, tostring(message or "Game package could not be loaded"))
            end
        end
        if type(context.ApplyGeneralValues) == "function" then
            local ok, message = context.ApplyGeneralValues(copy(payload.General or {}))
            if ok == false then return false, tostring(message or "General settings could not be applied") end
        end
        if type(context.ApplyGameValues) == "function" then
            local ok, message = context.ApplyGameValues(copy(payload.Games or {}))
            if ok == false then
                partial = true
                table.insert(warnings, tostring(message or "Game settings were skipped"))
            end
        end
        if type(context.ApplyBindings) == "function" then
            local ok, message = context.ApplyBindings(copy(payload.Bindings or {}))
            if ok == false then return false, tostring(message or "Bindings could not be applied") end
        end
        if type(context.ApplyWaypoints) == "function" then
            local ok, message = context.ApplyWaypoints(copy(payload.Waypoints or {}))
            if ok == false then
                partial = true
                table.insert(warnings, tostring(message or "Waypoints were skipped"))
            end
        end
        if partial then return true, "Partial: " .. table.concat(warnings, "; "), {Partial = true, Warnings = warnings} end
        return true, "Loaded", {Partial = false, Warnings = {}}
    end

    function controller.List()
        if type(context.ListFiles) ~= "function" then return {} end
        local ok, paths = pcall(context.ListFiles, root)
        if not ok or type(paths) ~= "table" then return {} end
        local names = {}
        for _, path in ipairs(paths) do
            local normalized = tostring(path):gsub("\\", "/")
            local name = normalized:match("([^/]+)%.json$")
            if name then table.insert(names, name) end
        end
        table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
        return names
    end

    function controller.Delete(name)
        local path = pathFor(name)
        if not path or type(context.DeleteFile) ~= "function" then return false, "Delete unsupported" end
        if type(context.IsFile) == "function" and not context.IsFile(path) then return false, "Config not found" end
        local ok, message = pcall(context.DeleteFile, path)
        return ok, ok and "Deleted" or tostring(message)
    end

    function controller.Export()
        return buildPayload()
    end

    return table.freeze(controller)
end

return table.freeze(ConfigServiceModule)
