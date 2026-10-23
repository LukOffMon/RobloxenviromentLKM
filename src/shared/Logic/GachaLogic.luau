--!strict
-- Tiradas del gacha (Cajas de Asilo). Lógica pura: el servidor le pasa el RNG y el estado.
-- Ver docs/gdd/og-catalog.md para probabilidades y contador de piedad.

export type RarityLike = { Id: string, Order: number, Chance: number }
export type ArchetypeLike = { Id: string, Rarity: string }

export type RollOptions = {
	-- La tirada número PityLimit sin Transcendente lo garantiza.
	PityLimit: number,
	-- Probabilidad de variante Shiny / Edición Dorada (solo cosmética).
	ShinyChance: number,
	-- Rareza mínima garantizada (p. ej. 3 = Épico para la caja de inicio).
	MinRarityOrder: number?,
}

export type RollResult = {
	Rarity: string,
	ArchetypeId: string,
	Shiny: boolean,
	PityTriggered: boolean,
}

local GachaLogic = {}

-- Elige rareza con probabilidades ponderadas entre las permitidas (Order >= minOrder).
function GachaLogic.pickRarity(rarities: { RarityLike }, roll: number, minOrder: number): RarityLike
	local total = 0
	for _, rarity in rarities do
		if rarity.Order >= minOrder then
			total += rarity.Chance
		end
	end
	local target = roll * total
	local accumulated = 0
	local last: RarityLike? = nil
	for _, rarity in rarities do
		if rarity.Order >= minOrder then
			accumulated += rarity.Chance
			last = rarity
			if target < accumulated then
				return rarity
			end
		end
	end
	-- Por redondeo de coma flotante target puede igualar el total: devolver la última válida.
	assert(last, "no hay rarezas que cumplan el mínimo")
	return last
end

-- Hace una tirada completa. Devuelve el resultado y el nuevo valor del contador de piedad.
function GachaLogic.roll(
	rarities: { RarityLike },
	archetypesByRarity: { [string]: { ArchetypeLike } },
	rng: () -> number,
	pity: number,
	options: RollOptions
): (RollResult, number)
	local highest = rarities[#rarities]
	local pityTriggered = pity + 1 >= options.PityLimit
	local rarity = if pityTriggered
		then highest
		else GachaLogic.pickRarity(rarities, rng(), options.MinRarityOrder or 1)

	local pool = archetypesByRarity[rarity.Id]
	assert(pool and #pool > 0, "rareza sin arquetipos: " .. rarity.Id)
	local archetype = pool[math.clamp(math.floor(rng() * #pool) + 1, 1, #pool)]

	local newPity = if rarity.Id == highest.Id then 0 else pity + 1
	return {
		Rarity = rarity.Id,
		ArchetypeId = archetype.Id,
		Shiny = rng() < options.ShinyChance,
		PityTriggered = pityTriggered,
	},
		newPity
end

return GachaLogic
