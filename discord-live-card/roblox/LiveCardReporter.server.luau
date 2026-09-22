--!strict
-- ServerScriptService icinde calisir; LocalScript olarak kullanmayin.
-- Roblox Studio > Game Settings > Security > Allow HTTP Requests acik olmalidir.

local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local Adapter = require(ServerScriptService:WaitForChild("GameStateAdapter"))

-- Yerel kopru adresi ve .env ile ayni INGEST_TOKEN degeri.
-- Bu adres Roblox'un canli bulut sunucularindan calismaz; yalnizca yerel/izinli calisma ortaminda kullanilir.
local ENDPOINT = "http://127.0.0.1:8787/v1/snapshot"
local INGEST_TOKEN = "CHANGE-ME-TO-THE-SAME-32-CHARACTER-SECRET"
local DEBOUNCE_SECONDS = 0.35
local HEARTBEAT_SECONDS = 5

local WATCHED_ATTRIBUTES = {
	"RoundPhase",
	"MapName",
	"RoundNumber",
	"MurdererUserId",
	"DetectiveUserId",
	"DetectiveAlive",
	"GunStatus",
	"GunHolderUserId",
	"RoundWinner",
}

local revision = 0
local scheduled = false

local function publish()
	revision += 1
	local snapshot = Adapter.readSnapshot(revision)
	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url = ENDPOINT,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. INGEST_TOKEN,
			},
			Body = HttpService:JSONEncode(snapshot),
		})
	end)

	if not ok then
		warn("Live card istegi basarisiz:", result)
	elseif not result.Success then
		warn(string.format("Live card HTTP %d: %s", result.StatusCode, result.Body))
	end
end

local function schedulePublish()
	if scheduled then
		return
	end
	scheduled = true
	task.delay(DEBOUNCE_SECONDS, function()
		scheduled = false
		publish()
	end)
end

for _, attributeName in WATCHED_ATTRIBUTES do
	workspace:GetAttributeChangedSignal(attributeName):Connect(schedulePublish)
end

task.delay(1, publish)

-- Durum degismese bile yerel kopru baglantinin canli oldugunu bilir.
task.spawn(function()
	while true do
		task.wait(HEARTBEAT_SECONDS)
		schedulePublish()
	end
end)
