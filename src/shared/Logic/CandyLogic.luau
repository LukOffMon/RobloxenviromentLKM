--!strict
-- Recompensa de los caramelos de abuela repartidos por el mapa (bucle de exploración).
-- Lógica pura: el servidor le pasa su RNG y la configuración.

export type Config = {
	CoinsMin: number,
	CoinsMax: number,
	-- Multiplicador extra de monedas por cada nivel de rival superado.
	TierBonus: number,
	TicketChance: number,
	GemChance: number,
	Gems: number,
}

export type Reward = { PensionCoins: number, Tickets: number, GigaGems: number }

local CandyLogic = {}

function CandyLogic.reward(rng: () -> number, battleTier: number, config: Config): Reward
	local base = config.CoinsMin + math.floor(rng() * (config.CoinsMax - config.CoinsMin + 1))
	local multiplier = 1 + config.TierBonus * math.max(battleTier - 1, 0)
	local roll = rng()
	return {
		PensionCoins = math.floor(base * multiplier),
		Tickets = if roll < config.TicketChance then 1 else 0,
		GigaGems = if roll >= config.TicketChance and roll < config.TicketChance + config.GemChance
			then config.Gems
			else 0,
	}
end

return CandyLogic
