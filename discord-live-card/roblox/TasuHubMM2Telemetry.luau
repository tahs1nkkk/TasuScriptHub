--!strict
-- TasuHub MM2 -> local Discord card telemetry.
-- This file is served by the local Node bridge; __INGEST_TOKEN__ is replaced in memory.

local MM2_PLACE_ID = 142823291
if game.PlaceId ~= MM2_PLACE_ID then
	return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local env = if getgenv then getgenv() else _G

if env.TasuHubMM2LiveCard and type(env.TasuHubMM2LiveCard.Unload) == "function" then
	pcall(env.TasuHubMM2LiveCard.Unload)
end

local requestFunction = env.request or env.http_request
if not requestFunction and type(env.syn) == "table" then
	requestFunction = env.syn.request
end
if type(requestFunction) ~= "function" then
	warn("TasuHub Live Card: executor localhost HTTP request desteklemiyor")
	return
end

local ENDPOINT = "http://127.0.0.1:8787/v1/snapshot"
local INGEST_TOKEN = "__INGEST_TOKEN__"
local HEARTBEAT_SECONDS = 5
local ENDED_SECONDS = 8

local stopped = false
local sequence = 0
local rememberedMurderer: Player? = nil
local rememberedDetective: Player? = nil
local roundWasActive = false
local lastRoundSignal = 0

local bridge = {
	Connected = false,
	LastError = nil,
	LastStatusCode = nil,
}
env.TasuHubMM2LiveCard = bridge
local owner = env.TasuHubMM2

local function findTool(player: Player, toolName: string): Tool?
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = if character then character:FindFirstChild(toolName) else nil
	if not tool and backpack then
		tool = backpack:FindFirstChild(toolName)
	end
	return if tool and tool:IsA("Tool") then tool else nil
end

local function roleOf(player: Player): string
	for _, container in ipairs({player, player.Character}) do
		if container then
			for _, name in ipairs({"Role", "ServerRole", "MM2ServerRole"}) do
				local value = container:GetAttribute(name)
				local object = container:FindFirstChild(name)
				if object and object:IsA("StringValue") then
					value = object.Value
				end
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

local function isAlive(player: Player?): boolean
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function playerData(player: Player?): {[string]: any}?
	if not player then return nil end
	return {
		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,
	}
end

local function findGunDrop(): Instance?
	return Workspace:FindFirstChild("GunDrop", true)
end

local function mapName(): string
	local attribute = Workspace:GetAttribute("MapName")
	if type(attribute) == "string" then return attribute end
	local map = Workspace:FindFirstChild("Map")
	return map and map.Name or ""
end

local function readSnapshot(): {[string]: any}
	local detectedMurderer: Player? = nil
	local gunHolder: Player? = nil
	for _, player in ipairs(Players:GetPlayers()) do
		local role = roleOf(player)
		if role == "Murderer" then detectedMurderer = player end
		if findTool(player, "Gun") then gunHolder = player end
		if role == "Sheriff" and not rememberedDetective then rememberedDetective = player end
	end

	if detectedMurderer then rememberedMurderer = detectedMurderer end
	if gunHolder and not rememberedDetective then rememberedDetective = gunHolder end

	local gunDrop = findGunDrop()
	local hasRoundSignal = detectedMurderer ~= nil or gunHolder ~= nil or gunDrop ~= nil
	if hasRoundSignal then
		roundWasActive = true
		lastRoundSignal = os.clock()
	end

	local phase = "lobby"
	if hasRoundSignal then
		phase = "round"
	elseif roundWasActive and os.clock() - lastRoundSignal <= ENDED_SECONDS then
		phase = "ended"
	else
		roundWasActive = false
		rememberedMurderer = nil
		rememberedDetective = nil
	end

	local detectiveAlive = isAlive(rememberedDetective)
	local gunStatus = "unknown"
	local hero: Player? = nil
	if gunDrop then
		gunStatus = "dropped"
	elseif gunHolder and rememberedDetective and gunHolder ~= rememberedDetective then
		gunStatus = "picked_up"
		hero = gunHolder
	elseif gunHolder then
		gunStatus = "held"
	end

	local winner = "none"
	if phase == "ended" and rememberedMurderer and not isAlive(rememberedMurderer) then
		winner = "innocents"
	end

	sequence += 1
	return {
		eventId = string.format("%s:%d", game.JobId ~= "" and game.JobId or "local", sequence),
		sessionId = game.JobId ~= "" and game.JobId or "local",
		phase = phase,
		map = mapName(),
		round = nil,
		murderer = playerData(rememberedMurderer),
		detective = playerData(rememberedDetective),
		detectiveAlive = detectiveAlive,
		gun = {
			status = gunStatus,
			holder = playerData(hero),
		},
		winner = winner,
		sentAt = DateTime.now():ToIsoDate(),
	}
end

local function publish()
	local ok, result = pcall(requestFunction, {
		Url = ENDPOINT,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. INGEST_TOKEN,
		},
		Body = HttpService:JSONEncode(readSnapshot()),
	})

	if not ok or type(result) ~= "table" then
		bridge.Connected = false
		bridge.LastError = tostring(result)
		return
	end
	local statusCode = tonumber(result.StatusCode or result.Status)
	bridge.LastStatusCode = statusCode
	bridge.Connected = statusCode ~= nil and statusCode >= 200 and statusCode < 300
	bridge.LastError = if bridge.Connected then nil else tostring(result.Body or result.StatusMessage or "HTTP error")
end

local function unload(stopServer: boolean?)
	if stopped then return end
	stopped = true
	bridge.Connected = false
	if stopServer then
		pcall(requestFunction, {
			Url = "http://127.0.0.1:8787/control/shutdown",
			Method = "POST",
			Headers = { ["Authorization"] = "Bearer " .. INGEST_TOKEN },
			Body = "{}",
		})
	end
	if env.TasuHubMM2LiveCard == bridge then
		env.TasuHubMM2LiveCard = nil
	end
end
bridge.Unload = unload

task.spawn(function()
	while not stopped do
		publish()
		for _ = 1, HEARTBEAT_SECONDS * 2 do
			task.wait(0.5)
			if stopped then break end
		end
		if env.TasuHub == nil then
			unload(true)
		elseif env.TasuHubMM2 ~= owner then
			-- A Catalog re-run replaces the module briefly. Stop this reporter,
			-- but let the replacement keep using the same local bot process.
			unload(false)
		end
	end
end)
