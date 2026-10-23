--!strict
-- Simulación del combate por turnos "Turn-Based Comedy". El servidor la ejecuta completa y
-- envía el registro de eventos al cliente, que solo lo anima. Ver docs/gdd/battle-system.md

export type Special = {
	Name: string,
	Power: number,
	Hits: number,
	Target: "Single" | "All",
}

export type FighterInput = {
	Name: string,
	ArchetypeId: string,
	Rarity: string,
	Level: number,
	Shiny: boolean,
	Stats: { HP: number, ATK: number, DEF: number, SPD: number },
	Special: Special,
}

export type Side = "A" | "B"

export type Fighter = FighterInput & {
	Key: string,
	Side: Side,
	Index: number,
	HP: number,
	MaxHP: number,
	Charge: number,
}

export type Hit = { Target: string, Damage: number, Crit: boolean, KO: boolean, HPAfter: number }

export type Event = {
	Round: number,
	Actor: string,
	Move: "Basic" | "Special",
	MoveName: string,
	Hits: { Hit },
}

export type FighterSummary = {
	Key: string,
	Side: Side,
	Name: string,
	ArchetypeId: string,
	Rarity: string,
	Level: number,
	Shiny: boolean,
	MaxHP: number,
}

export type Result = {
	Winner: Side | "Draw",
	Rounds: number,
	Fighters: { FighterSummary },
	Events: { Event },
}

export type Options = {
	MaxRounds: number,
	-- Acciones necesarias para cargar el ataque especial.
	SpecialEvery: number,
	CritChance: number,
	CritMultiplier: number,
}

local BattleLogic = {}

BattleLogic.DefaultOptions = table.freeze({
	MaxRounds = 30,
	SpecialEvery = 3,
	CritChance = 0.1,
	CritMultiplier = 1.5,
}) :: Options

local function buildTeam(inputs: { FighterInput }, side: Side): { Fighter }
	local team = {}
	for index, input in inputs do
		local fighter = table.clone(input) :: any
		fighter.Key = side .. index
		fighter.Side = side
		fighter.Index = index
		fighter.MaxHP = input.Stats.HP
		fighter.HP = input.Stats.HP
		fighter.Charge = 0
		table.insert(team, fighter :: Fighter)
	end
	return team
end

local function alive(team: { Fighter }): { Fighter }
	local result = {}
	for _, fighter in team do
		if fighter.HP > 0 then
			table.insert(result, fighter)
		end
	end
	return result
end

local function hpFraction(team: { Fighter }): number
	local current, max = 0, 0
	for _, fighter in team do
		current += fighter.HP
		max += fighter.MaxHP
	end
	return if max > 0 then current / max else 0
end

function BattleLogic.damage(
	atk: number,
	def: number,
	power: number,
	variance: number,
	crit: boolean,
	critMult: number
): number
	local raw = atk * power * 100 / (100 + def * 2) * variance
	if crit then
		raw *= critMult
	end
	return math.max(1, math.floor(raw))
end

function BattleLogic.simulate(
	teamAInput: { FighterInput },
	teamBInput: { FighterInput },
	rng: () -> number,
	options: Options?
): Result
	local opts = options or BattleLogic.DefaultOptions
	local teamA = buildTeam(teamAInput, "A")
	local teamB = buildTeam(teamBInput, "B")
	local events: { Event } = {}

	local fighters: { FighterSummary } = {}
	for _, team in { teamA, teamB } do
		for _, f in team do
			table.insert(fighters, {
				Key = f.Key,
				Side = f.Side,
				Name = f.Name,
				ArchetypeId = f.ArchetypeId,
				Rarity = f.Rarity,
				Level = f.Level,
				Shiny = f.Shiny,
				MaxHP = f.MaxHP,
			})
		end
	end

	local round = 0
	while round < opts.MaxRounds and #alive(teamA) > 0 and #alive(teamB) > 0 do
		round += 1
		local order = alive(teamA)
		for _, f in alive(teamB) do
			table.insert(order, f)
		end
		table.sort(order, function(a, b)
			if a.Stats.SPD ~= b.Stats.SPD then
				return a.Stats.SPD > b.Stats.SPD
			end
			if a.Side ~= b.Side then
				return a.Side == "A"
			end
			return a.Index < b.Index
		end)

		for _, actor in order do
			if actor.HP <= 0 then
				continue
			end
			local enemies = alive(if actor.Side == "A" then teamB else teamA)
			if #enemies == 0 then
				break
			end

			actor.Charge += 1
			local useSpecial = actor.Charge >= opts.SpecialEvery
			local power, hits, targetMode, moveName = 1, 1, "Single", "Bastonazo"
			if useSpecial then
				actor.Charge = 0
				power, hits, targetMode, moveName =
					actor.Special.Power, actor.Special.Hits, actor.Special.Target, actor.Special.Name
			end

			local event: Event = {
				Round = round,
				Actor = actor.Key,
				Move = if useSpecial then "Special" else "Basic",
				MoveName = moveName,
				Hits = {},
			}

			for _ = 1, hits do
				local targets = alive(if actor.Side == "A" then teamB else teamA)
				if #targets == 0 then
					break
				end
				if targetMode == "Single" then
					table.sort(targets, function(a, b)
						if a.HP ~= b.HP then
							return a.HP < b.HP
						end
						return a.Index < b.Index
					end)
					targets = { targets[1] }
				end
				for _, target in targets do
					local crit = rng() < opts.CritChance
					local variance = 0.9 + rng() * 0.2
					local amount = BattleLogic.damage(
						actor.Stats.ATK,
						target.Stats.DEF,
						power,
						variance,
						crit,
						opts.CritMultiplier
					)
					target.HP = math.max(0, target.HP - amount)
					table.insert(event.Hits, {
						Target = target.Key,
						Damage = amount,
						Crit = crit,
						KO = target.HP == 0,
						HPAfter = target.HP,
					})
				end
			end
			table.insert(events, event)
		end
	end

	local winner: Side | "Draw"
	if #alive(teamB) == 0 and #alive(teamA) > 0 then
		winner = "A"
	elseif #alive(teamA) == 0 and #alive(teamB) > 0 then
		winner = "B"
	else
		local a, b = hpFraction(teamA), hpFraction(teamB)
		winner = if a > b then "A" elseif b > a then "B" else "Draw"
	end

	return { Winner = winner, Rounds = round, Fighters = fighters, Events = events }
end

return BattleLogic
