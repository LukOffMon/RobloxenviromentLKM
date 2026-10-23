--!strict
-- Configuración central compartida. Los valores de seguridad se aplican SIEMPRE en el servidor;
-- el cliente solo los lee para ajustar su UI. Diseño en docs/gdd/monog-gdd.md

type Reward = { [string]: number }

-- Recompensas del Bingo Matutino por día de racha (1..7).
local DAILY_REWARDS: { Reward } = {
	{ PensionCoins = 200 },
	{ PensionCoins = 400 },
	{ Tickets = 1 },
	{ PensionCoins = 800 },
	{ GigaGems = 25 },
	{ PensionCoins = 1500 },
	{ Tickets = 3, GigaGems = 100 },
}
for _, reward in DAILY_REWARDS do
	table.freeze(reward)
end

local GameConfig = table.freeze({
	Version = "0.1.0-monog",

	Data = table.freeze({
		DataStoreName = "MonOG_PlayerData_v1",
		SaveIntervalSeconds = 120,
		MaxSaveRetries = 5,
		SessionLockTimeoutSeconds = 1800,
		-- Un jugador nuevo recibe monedas y una Caja de Asilo gratis: el gancho de los primeros 180 s.
		Template = table.freeze({
			PensionCoins = 300,
			GigaGems = 0,
			Tickets = 1,
			EpicTickets = 0,
			OGs = table.freeze({}),
			Equipped = table.freeze({}),
			Pity = 0,
			TotalRolls = 0,
			BattleTier = 1,
			BattlesWon = 0,
			DailyStreak = 0,
			LastDailyDay = -1,
			LastSeen = 0,
			XpBoostUntil = 0,
			ProcessedReceipts = table.freeze({}),
			StarterPackBought = false,
		}),
	}),

	Network = table.freeze({
		RemotesFolderName = "LKMRemotes",
		-- Peticiones permitidas por ventana, por jugador y por remote.
		DefaultRateLimit = 10,
		DefaultRateWindowSeconds = 1,
		-- Infracciones antes de expulsar al jugador.
		MaxViolations = 25,
	}),

	AntiExploit = table.freeze({
		MaxInteractDistance = 16,
		MaxWalkSpeed = 24,
		MaxTeleportDistancePerSecond = 120,
	}),

	Economy = table.freeze({
		MaxCurrency = 1_000_000_000_000,
		-- Desde cuántos segundos sin cambios se envía el perfil al cliente.
		ProfilePushDebounce = 0.25,
	}),

	OG = table.freeze({
		MaxLevel = 100,
		MaxOwned = 60,
		MaxEquipped = 3,
	}),

	Gacha = table.freeze({
		PityLimit = 1000,
		ShinyChance = 0.005,
		CoinBoxCost = 250,
		CoinBox5Cost = 1150,
		GemBoxCost = 120,
		-- La caja de gemas garantiza Raro o mejor.
		GemBoxMinRarityOrder = 2,
		-- La caja de inicio (producto de Robux) garantiza Épico o mejor.
		StarterMinRarityOrder = 3,
	}),

	Pension = table.freeze({
		TickSeconds = 1,
		PerFriend = 0.15,
		MaxFriendBonus = 0.75,
		FriendRefreshSeconds = 30,
		OfflineCapSeconds = 7200,
		OfflineEfficiency = 0.5,
		ExtendedOfflineCapSeconds = 86400,
		ExtendedOfflineEfficiency = 1,
	}),

	Training = table.freeze({
		Beats = 16,
		IntervalSeconds = 0.6,
		LeadInSeconds = 2.5,
		PerfectWindow = 0.09,
		GoodWindow = 0.2,
		CooldownSeconds = 3,
		BoostMultiplier = 3,
		AutoTrainerXpPerMinute = 30,
	}),

	Battle = table.freeze({
		CooldownSeconds = 4,
		CoinsBase = 60,
		CoinsPerTier = 40,
		TeamXp = 10,
		-- Cada cuántos niveles de rival se regalan gemas al ganarlo por primera vez.
		GemMilestoneEvery = 5,
		GemMilestoneReward = 50,
	}),

	Daily = table.freeze(DAILY_REWARDS),

	-- Id = 0 significa "aún no creado en el Creator Hub": el botón se muestra desactivado.
	-- Pasos para crearlos en docs/gdd/monetization-and-growth.md
	Products = table.freeze({
		ExpressoDoble = table.freeze({ Id = 0, Price = 49, Kind = "XpBoost", Minutes = 30 }),
		StarterBox = table.freeze({ Id = 0, Price = 89, Kind = "StarterBox" }),
		AsylumBox1 = table.freeze({ Id = 0, Price = 79, Kind = "Box", Count = 1 }),
		AsylumBox5 = table.freeze({ Id = 0, Price = 349, Kind = "Box", Count = 5 }),
		AsylumBox10 = table.freeze({ Id = 0, Price = 699, Kind = "Box", Count = 10 }),
	}),

	GamePasses = table.freeze({
		AutoTrainer = table.freeze({ Id = 0, Price = 299 }),
		OfflinePension = table.freeze({ Id = 0, Price = 399 }),
		VipDirector = table.freeze({ Id = 0, Price = 799 }),
		QuantumAura = table.freeze({ Id = 0, Price = 1200 }),
	}),
})

return GameConfig
