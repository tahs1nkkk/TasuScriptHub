--!strict
-- Bu ModuleScript'i ServerScriptService icinde tutun.
-- Kendi oyununuzdaki gercek tur yoneticisi bu attribute'lari guncellemelidir.

local Players = game:GetService("Players")

local Adapter = {}

local function playerData(userIdValue: any): {[string]: any}?
	local userId = tonumber(userIdValue)
	if not userId or userId <= 0 then
		return nil
	end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		return {
			userId = player.UserId,
			username = player.Name,
			displayName = player.DisplayName,
		}
	end

	local ok, username = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	return {
		userId = userId,
		username = if ok then username else ("User" .. tostring(userId)),
		displayName = if ok then username else ("User " .. tostring(userId)),
	}
end

function Adapter.readSnapshot(revision: number): {[string]: any}
	local phase = tostring(workspace:GetAttribute("RoundPhase") or "lobby"):lower()
	if phase ~= "lobby" and phase ~= "round" and phase ~= "ended" then
		phase = "lobby"
	end

	local gunStatus = tostring(workspace:GetAttribute("GunStatus") or "unknown"):lower()
	if gunStatus ~= "held" and gunStatus ~= "dropped" and gunStatus ~= "picked_up" then
		gunStatus = "unknown"
	end

	return {
		eventId = string.format("%s:%d", game.JobId ~= "" and game.JobId or "studio", revision),
		sessionId = game.JobId ~= "" and game.JobId or "studio",
		phase = phase,
		map = tostring(workspace:GetAttribute("MapName") or ""),
		round = tonumber(workspace:GetAttribute("RoundNumber")),
		murderer = playerData(workspace:GetAttribute("MurdererUserId")),
		detective = playerData(workspace:GetAttribute("DetectiveUserId")),
		detectiveAlive = workspace:GetAttribute("DetectiveAlive") ~= false,
		gun = {
			status = gunStatus,
			holder = playerData(workspace:GetAttribute("GunHolderUserId")),
		},
		winner = tostring(workspace:GetAttribute("RoundWinner") or "none"):lower(),
		sentAt = DateTime.now():ToIsoDate(),
	}
end

return Adapter
