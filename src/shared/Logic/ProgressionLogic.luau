--!strict
-- Fórmulas de progresión y economía de los OGs. Lógica pura y compartida por servidor y cliente.
-- Ver docs/gdd/progression-tree.md y docs/gdd/economy-systems.md

export type Stats = { HP: number, ATK: number, DEF: number, SPD: number }

local ProgressionLogic = {}

ProgressionLogic.StatGrowthPerLevel = 0.08
ProgressionLogic.PensionGrowthPerLevel = 0.10
ProgressionLogic.XpPerLevelStep = 20

-- XP necesaria para pasar del nivel `level` al siguiente.
function ProgressionLogic.xpToNext(level: number): number
	return ProgressionLogic.XpPerLevelStep * level
end

-- Suma XP y sube los niveles que correspondan. Al llegar a maxLevel la XP se queda en 0.
function ProgressionLogic.addXp(level: number, xp: number, amount: number, maxLevel: number): (number, number)
	xp += amount
	while level < maxLevel and xp >= ProgressionLogic.xpToNext(level) do
		xp -= ProgressionLogic.xpToNext(level)
		level += 1
	end
	if level >= maxLevel then
		return maxLevel, 0
	end
	return level, xp
end

function ProgressionLogic.statsAt(base: Stats, level: number): Stats
	local factor = 1 + ProgressionLogic.StatGrowthPerLevel * (level - 1)
	return {
		HP = math.floor(base.HP * factor),
		ATK = math.floor(base.ATK * factor),
		DEF = math.floor(base.DEF * factor),
		SPD = math.floor(base.SPD * factor),
	}
end

function ProgressionLogic.pensionPerSecond(rarityPension: number, level: number): number
	return rarityPension * (1 + ProgressionLogic.PensionGrowthPerLevel * (level - 1))
end

-- +perFriend por amigo conectado en el servidor, con tope.
function ProgressionLogic.friendMultiplier(friends: number, perFriend: number, maxBonus: number): number
	return 1 + math.min(math.max(friends, 0) * perFriend, maxBonus)
end

-- Ingresos acumulados mientras el jugador estaba desconectado.
function ProgressionLogic.offlineEarnings(
	perSecond: number,
	secondsAway: number,
	capSeconds: number,
	efficiency: number
): number
	local seconds = math.clamp(secondsAway, 0, capSeconds)
	return math.floor(perSecond * seconds * efficiency)
end

return ProgressionLogic
