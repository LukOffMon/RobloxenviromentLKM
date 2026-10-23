--!strict
-- Punto de entrada del servidor de MonOG: arranca servicios y declara los remotes con su middleware.
-- Mapa de red completo en docs/architecture/client-server-network-map.md

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Configurations.GameConfig)
local RemoteSignal = require(ReplicatedStorage.Shared.Network.RemoteSignal)

local Services = script.Parent.Services
local BattleService = require(Services.BattleService)
local DailyService = require(Services.DailyService)
local DataService = require(Services.DataService)
local GachaService = require(Services.GachaService)
local MonetizationService = require(Services.MonetizationService)
local OGService = require(Services.OGService)
local PensionService = require(Services.PensionService)
local SanityChecker = require(script.Parent.AntiExploit.SanityChecker)
local TrainingService = require(Services.TrainingService)
local WorldService = require(Services.WorldService)

local V = RemoteSignal.Validators

type PushKind = "Full" | "Currency"

-- Servidor -> cliente -----------------------------------------------------------
local function outgoing(name: string)
	return RemoteSignal.server({ Name = name, Args = {} })
end

local profileUpdated = outgoing("ProfileUpdated")
local currencyUpdated = outgoing("CurrencyUpdated")
local gachaResult = outgoing("GachaResult")
local trainingStarted = outgoing("TrainingStarted")
local trainingJudged = outgoing("TrainingJudged")
local trainingResult = outgoing("TrainingResult")
local battleResult = outgoing("BattleResult")
local dailyResult = outgoing("DailyResult")
local notify = outgoing("Notify")

-- Cliente -> servidor ------------------------------------------------------------
-- El cliente solo expresa intención; el servidor decide coste, resultado y recompensa.
local openBox = RemoteSignal.server({
	Name = "OpenBox",
	Args = { V.oneOf(GachaService.Modes) },
	RateLimit = 2,
	RateWindowSeconds = 1,
})

local setEquipped = RemoteSignal.server({
	Name = "SetEquipped",
	Args = { V.string(64), V.boolean() },
	RateLimit = 6,
	RateWindowSeconds = 1,
})

local startTraining = RemoteSignal.server({
	Name = "StartTraining",
	Args = { V.string(64) },
	RateLimit = 2,
	RateWindowSeconds = 1,
})

local trainingTap = RemoteSignal.server({
	Name = "TrainingTap",
	Args = {},
	RateLimit = 12,
	RateWindowSeconds = 1,
})

local startBattle = RemoteSignal.server({
	Name = "StartBattle",
	Args = {},
	RateLimit = 2,
	RateWindowSeconds = 1,
})

local claimDaily = RemoteSignal.server({
	Name = "ClaimDaily",
	Args = {},
	RateLimit = 2,
	RateWindowSeconds = 2,
})

local requestProfile = RemoteSignal.server({
	Name = "RequestProfile",
	Args = {},
	RateLimit = 2,
	RateWindowSeconds = 5,
})

-- Vista del perfil para la UI -----------------------------------------------------
local function currencyView(profile: DataService.ProfileData)
	return {
		PensionCoins = profile.PensionCoins,
		GigaGems = profile.GigaGems,
		Tickets = profile.Tickets,
		EpicTickets = profile.EpicTickets,
	}
end

local function fullView(player: Player, profile: DataService.ProfileData)
	return {
		PensionCoins = profile.PensionCoins,
		GigaGems = profile.GigaGems,
		Tickets = profile.Tickets,
		EpicTickets = profile.EpicTickets,
		OGs = profile.OGs,
		Equipped = profile.Equipped,
		Pity = profile.Pity,
		PityLimit = GameConfig.Gacha.PityLimit,
		BattleTier = profile.BattleTier,
		BattlesWon = profile.BattlesWon,
		DailyStreak = profile.DailyStreak,
		CanClaimDaily = DailyService.canClaim(player),
		XpBoostUntil = profile.XpBoostUntil,
		StarterPackBought = profile.StarterPackBought,
		PensionRate = PensionService.getRate(player),
		FriendMultiplier = PensionService.getFriendMultiplier(player),
		Passes = MonetizationService.getPasses(player),
		PaidRandomAllowed = MonetizationService.canBuyRandomItems(player),
		MemoryOnly = DataService.isMemoryOnly(player),
	}
end

-- Atributos públicos: los clientes dibujan con ellos las mascotas y auras de cada jugador.
local function updatePublicAttributes(player: Player, profile: DataService.ProfileData)
	local parts = {}
	for _, entry in OGService.getEquipped(player) do
		table.insert(parts, entry.OG.Id .. ":" .. (if entry.OG.Shiny then "1" else "0"))
	end
	player:SetAttribute("EquippedOGs", table.concat(parts, ","))
	player:SetAttribute("VIP", MonetizationService.ownsPass(player, "VipDirector"))
	player:SetAttribute("QuantumAura", MonetizationService.ownsPass(player, "QuantumAura"))
	player:SetAttribute("BattleTier", profile.BattleTier)
end

-- Envío agrupado: muchos cambios seguidos producen un solo mensaje.
local pending: { [Player]: PushKind } = {}

local function queuePush(player: Player, kind: PushKind)
	if pending[player] ~= "Full" then
		pending[player] = kind
	end
end

local function flush()
	for player, kind in pending do
		pending[player] = nil
		local profile = DataService.getProfile(player)
		if profile and player.Parent == Players then
			if kind == "Full" then
				profileUpdated:FireClient(player, fullView(player, profile))
				updatePublicAttributes(player, profile)
				WorldService.updateLeaderstats(player)
			else
				currencyUpdated:FireClient(player, currencyView(profile))
			end
		end
	end
end

-- Arranque -------------------------------------------------------------------------
SanityChecker.start()
DataService.start()
MonetizationService.start()
PensionService.start()
TrainingService.start()
BattleService.start()
WorldService.start()

DataService.ProfileLoaded:Connect(function(player: Player)
	queuePush(player, "Full")
end)
DataService.ProfileChanged:Connect(function(player: Player, kind: PushKind)
	queuePush(player, kind)
end)
MonetizationService.PassesChanged:Connect(function(player: Player)
	queuePush(player, "Full")
end)
Players.PlayerRemoving:Connect(function(player)
	pending[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(GameConfig.Economy.ProfilePushDebounce)
		flush()
	end
end)

-- La tasa de pensión depende de amigos conectados: refrescar la vista de vez en cuando.
task.spawn(function()
	while true do
		task.wait(GameConfig.Pension.FriendRefreshSeconds)
		for _, player in Players:GetPlayers() do
			queuePush(player, "Full")
		end
	end
end)

PensionService.OfflineEarned:Connect(function(player: Player, amount: number)
	notify:FireClient(
		player,
		string.format("Tus OGs cobraron %d PensionCoins mientras no estabas 👵💰", amount),
		"Reward"
	)
end)

MonetizationService.BoxGranted:Connect(function(player: Player, results)
	gachaResult:FireClient(player, results)
end)

TrainingService.Finished:Connect(function(player: Player, result)
	trainingResult:FireClient(player, result)
end)

-- Handlers ------------------------------------------------------------------------
openBox:Connect(function(player, mode)
	local results, reason = GachaService.open(player, mode)
	if results then
		gachaResult:FireClient(player, results)
	else
		notify:FireClient(player, reason, "Error")
	end
end)

setEquipped:Connect(function(player, uid, equipped)
	if not OGService.setEquipped(player, uid, equipped) then
		local message = if equipped
			then "Solo puedes equipar " .. GameConfig.OG.MaxEquipped .. " OGs"
			else "Necesitas al menos un OG equipado"
		notify:FireClient(player, message, "Error")
	end
end)

startTraining:Connect(function(player, uid)
	local session, reason = TrainingService.begin(player, uid)
	if session then
		trainingStarted:FireClient(player, session)
	else
		notify:FireClient(player, reason, "Error")
	end
end)

trainingTap:Connect(function(player)
	local judgement = TrainingService.tap(player)
	if judgement then
		trainingJudged:FireClient(player, judgement)
	end
end)

startBattle:Connect(function(player)
	local view, reason = BattleService.fight(player)
	if view then
		battleResult:FireClient(player, view)
	else
		notify:FireClient(player, reason, "Error")
	end
end)

claimDaily:Connect(function(player)
	local day, reward = DailyService.claim(player)
	if day then
		dailyResult:FireClient(player, day, reward)
	else
		notify:FireClient(player, "Ya jugaste el bingo de hoy. ¡Vuelve mañana!", "Error")
	end
end)

requestProfile:Connect(function(player)
	queuePush(player, "Full")
end)
