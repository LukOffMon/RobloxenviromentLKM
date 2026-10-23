--!strict
-- Rompibles al estilo Pet Simulator: tipos con peso, vida y premio escalados por zona,
-- daño del equipo y reparto del premio entre quienes ayudaron a romperlo. Lógica pura.

export type BreakableType = {
	Id: string,
	Name: string,
	HP: number,
	Coins: number,
	Weight: number,
	GemChance: number,
	Gems: number,
}

local BreakableLogic = {}

function BreakableLogic.pickType(types: { BreakableType }, roll: number): BreakableType
	local total = 0
	for _, kind in types do
		total += kind.Weight
	end
	local target = roll * total
	local accumulated = 0
	for _, kind in types do
		accumulated += kind.Weight
		if target < accumulated then
			return kind
		end
	end
	return types[#types]
end

-- Vida y monedas de un rompible en una zona con su multiplicador.
function BreakableLogic.stats(kind: BreakableType, zoneMultiplier: number): (number, number)
	return math.floor(kind.HP * zoneMultiplier), math.floor(kind.Coins * zoneMultiplier)
end

-- Daño por segundo del equipo: suma del ATK de los OGs equipados.
function BreakableLogic.teamDps(attacks: { number }, scale: number): number
	local total = 0
	for _, attack in attacks do
		total += attack
	end
	return total * scale
end

-- Reparte las monedas en proporción al daño hecho. Cada ayudante recibe al menos 1
-- y el redondeo sobrante va a quien más daño hizo.
function BreakableLogic.split<K>(coins: number, damage: { [K]: number }): { [K]: number }
	local total = 0
	local top: K? = nil
	for key, amount in damage do
		total += amount
		if top == nil or amount > damage[top :: K] then
			top = key
		end
	end
	local result: { [K]: number } = {}
	if total <= 0 or top == nil then
		return result
	end
	local given = 0
	for key, amount in damage do
		local share = math.max(1, math.floor(coins * amount / total))
		result[key] = share
		given += share
	end
	if given < coins then
		result[top :: K] += coins - given
	end
	return result
end

return BreakableLogic
