--!strict
-- Configuración central compartida. Los valores de seguridad se aplican SIEMPRE en el servidor;
-- el cliente solo los lee para ajustar su UI.

local GameConfig = table.freeze({
	Version = "1.0.0-alpha",

	Data = table.freeze({
		DataStoreName = "PlayerData_v1",
		SaveIntervalSeconds = 120,
		MaxSaveRetries = 5,
		SessionLockTimeoutSeconds = 1800,
		Template = table.freeze({
			Coins = 0,
			Level = 1,
			Experience = 0,
			Inventory = table.freeze({}),
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
		MaxCoins = 1_000_000_000,
		ExperiencePerLevel = 100,
	}),
})

return GameConfig
