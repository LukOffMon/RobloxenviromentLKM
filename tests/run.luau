--!strict
-- Tests de la lógica pura de MonOG. Ejecutar: lune run tests/run.luau

local BattleLogic = require("../src/shared/Logic/BattleLogic")
local DailyLogic = require("../src/shared/Logic/DailyLogic")
local GachaLogic = require("../src/shared/Logic/GachaLogic")
local OGCatalog = require("../src/shared/Configurations/OGCatalog")
local ProgressionLogic = require("../src/shared/Logic/ProgressionLogic")
local TrainingLogic = require("../src/shared/Logic/TrainingLogic")

local passed, failed = 0, 0

local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("  ok   " .. name)
	else
		failed += 1
		print("  FAIL " .. name .. "\n       " .. tostring(err))
	end
end

local function expect(condition: boolean, message: string)
	if not condition then
		error(message, 2)
	end
end

-- Generador determinista (PCG de math.random) para que los tests sean reproducibles.
local function seeded(seed: number): () -> number
	math.randomseed(seed)
	return function()
		return math.random()
	end
end

local PITY = { PityLimit = 1000, ShinyChance = 0.005 }

print("Catálogo")
test("las probabilidades suman 1", function()
	local total = 0
	for _, rarity in OGCatalog.Rarities do
		total += rarity.Chance
	end
	expect(math.abs(total - 1) < 1e-9, "suma = " .. total)
end)

test("cada rareza tiene al menos un arquetipo", function()
	for _, rarity in OGCatalog.Rarities do
		local list = OGCatalog.ArchetypesByRarity[rarity.Id]
		expect(list ~= nil and #list > 0, "sin arquetipos: " .. rarity.Id)
	end
end)

print("Gacha")
test("las frecuencias coinciden con la tabla", function()
	local rng = seeded(42)
	local counts: { [string]: number } = {}
	local n = 200000
	for _ = 1, n do
		local result = GachaLogic.roll(OGCatalog.Rarities, OGCatalog.ArchetypesByRarity, rng, 0, PITY)
		counts[result.Rarity] = (counts[result.Rarity] or 0) + 1
	end
	local function near(id: string, expected: number, tolerance: number)
		local actual = (counts[id] or 0) / n
		expect(math.abs(actual - expected) <= tolerance, string.format("%s: %.4f vs %.4f", id, actual, expected))
	end
	near("Common", 0.55, 0.006)
	near("Rare", 0.30, 0.006)
	near("Epic", 0.11, 0.004)
	near("Legendary", 0.038, 0.002)
end)

test("la tirada 1000 sin Transcendente lo garantiza y reinicia la piedad", function()
	local result, pity = GachaLogic.roll(OGCatalog.Rarities, OGCatalog.ArchetypesByRarity, seeded(1), 999, PITY)
	expect(result.Rarity == "Transcendent", "rareza " .. result.Rarity)
	expect(result.PityTriggered, "debería marcar PityTriggered")
	expect(pity == 0, "pity " .. pity)
end)

test("la tirada 999 no fuerza nada y suma piedad", function()
	local rng = seeded(7)
	local result, pity = GachaLogic.roll(OGCatalog.Rarities, OGCatalog.ArchetypesByRarity, rng, 998, PITY)
	expect(not result.PityTriggered, "no debería forzar")
	expect(pity == 999 or result.Rarity == "Transcendent", "pity " .. pity)
end)

test("la caja de inicio nunca da menos de Épico", function()
	local rng = seeded(99)
	local options = { PityLimit = 1000, ShinyChance = 0, MinRarityOrder = 3 }
	for _ = 1, 5000 do
		local result = GachaLogic.roll(OGCatalog.Rarities, OGCatalog.ArchetypesByRarity, rng, 0, options)
		local rarity = OGCatalog.RaritiesById[result.Rarity]
		expect(rarity.Order >= 3, "salió " .. result.Rarity)
	end
end)

test("un roll casi 1 devuelve la última rareza válida", function()
	local rarity = GachaLogic.pickRarity(OGCatalog.Rarities, 0.9999999999, 1)
	expect(rarity.Id == "Transcendent", rarity.Id)
end)

print("Progresión")
test("subir varios niveles conserva la XP sobrante", function()
	local level, xp = ProgressionLogic.addXp(1, 0, 20 + 40 + 5, 100)
	expect(level == 3 and xp == 5, string.format("nivel %d xp %d", level, xp))
end)

test("el nivel máximo no se supera", function()
	local level, xp = ProgressionLogic.addXp(99, 0, 1e9, 100)
	expect(level == 100 and xp == 0, string.format("nivel %d xp %d", level, xp))
end)

test("el multiplicador de amigos tiene tope de +75%", function()
	expect(ProgressionLogic.friendMultiplier(2, 0.15, 0.75) == 1.3, "2 amigos")
	expect(ProgressionLogic.friendMultiplier(10, 0.15, 0.75) == 1.75, "10 amigos")
end)

test("la pensión offline respeta el tope", function()
	expect(ProgressionLogic.offlineEarnings(10, 99999, 7200, 0.5) == 36000, "tope 2h al 50%")
	expect(ProgressionLogic.offlineEarnings(10, -5, 7200, 0.5) == 0, "tiempo negativo")
end)

print("Combate")
local function fighter(archetypeId: string, level: number): BattleLogic.FighterInput
	local archetype = OGCatalog.ArchetypesById[archetypeId]
	return {
		Name = archetype.DisplayName,
		ArchetypeId = archetype.Id,
		Rarity = archetype.Rarity,
		Level = level,
		Shiny = false,
		Stats = ProgressionLogic.statsAt(archetype.Stats, level),
		Special = archetype.Special,
	}
end

test("un equipo legendario vence a uno común", function()
	local strong = { fighter("SenseiTanaka", 10), fighter("CientificoLoco", 10), fighter("DonChente", 10) }
	local weak = { fighter("VecinoReganon", 1), fighter("AbueloDomino", 1), fighter("VecinoReganon", 1) }
	local result = BattleLogic.simulate(strong, weak, seeded(5))
	expect(result.Winner == "A", "ganó " .. result.Winner)
	expect(#result.Events > 0, "sin eventos")
end)

test("el combate es determinista con la misma semilla", function()
	local a = { fighter("AbuelaCosturera", 3), fighter("AbueloCartero", 3) }
	local b = { fighter("MaestroMarcial", 2), fighter("VecinoReganon", 4) }
	local r1 = BattleLogic.simulate(a, b, seeded(11))
	local r2 = BattleLogic.simulate(a, b, seeded(11))
	expect(r1.Winner == r2.Winner and #r1.Events == #r2.Events, "resultados distintos")
end)

test("la vida reportada nunca baja de 0 y los KO cuadran", function()
	local result = BattleLogic.simulate(
		{ fighter("CiberAbuelo", 5) },
		{ fighter("VecinoReganon", 1), fighter("AbueloDomino", 1) },
		seeded(3)
	)
	for _, event in result.Events do
		for _, hit in event.Hits do
			expect(hit.HPAfter >= 0, "HP negativa")
			expect(hit.KO == (hit.HPAfter == 0), "KO inconsistente")
			expect(hit.Damage >= 1, "daño < 1")
		end
	end
end)

test("el combate termina aunque nadie pueda morir a tiempo", function()
	local tank = fighter("CiberAbuelo", 100)
	local result = BattleLogic.simulate({ tank }, { tank }, seeded(8), {
		MaxRounds = 3,
		SpecialEvery = 3,
		CritChance = 0,
		CritMultiplier = 1.5,
	})
	expect(result.Rounds <= 3, "rondas " .. result.Rounds)
end)

print("Entrenamiento")
test("pulsar justo en el beat es Perfect y no puntúa dos veces", function()
	local session = TrainingLogic.newSession(100, 0.5, 8, 0.08, 0.2)
	local first = TrainingLogic.judge(session, 100.5)
	local second = TrainingLogic.judge(session, 100.52)
	expect(first == "Perfect", first)
	expect(second == "Miss", second)
end)

test("ventanas Good y Miss", function()
	local session = TrainingLogic.newSession(0, 1, 4, 0.08, 0.2)
	expect(TrainingLogic.judge(session, 1.15) == "Good", "Good")
	expect(TrainingLogic.judge(session, 2.4) == "Miss", "fuera de ventana")
	expect(TrainingLogic.judge(session, 10) == "Miss", "después del final")
end)

test("spamear pulsaciones reduce la XP", function()
	local session = TrainingLogic.newSession(0, 1, 4, 0.08, 0.2)
	for beat = 0, 3 do
		TrainingLogic.judge(session, beat)
	end
	expect(TrainingLogic.xpFor(session) == 12, "4 Perfect = 12 XP")
	for _ = 1, 10 do
		TrainingLogic.judge(session, 0.5)
	end
	expect(TrainingLogic.xpFor(session) == 6, "spam penalizado")
end)

print("Bingo diario")
test("racha diaria", function()
	local can, streak = DailyLogic.claim(10, 3, 10)
	expect(not can and streak == 3, "mismo día")
	can, streak = DailyLogic.claim(10, 3, 11)
	expect(can and streak == 4, "día siguiente")
	can, streak = DailyLogic.claim(10, 3, 13)
	expect(can and streak == 1, "racha rota")
	can, streak = DailyLogic.claim(10, 7, 11)
	expect(can and streak == 1, "nuevo ciclo tras el día 7")
end)

print(string.format("\n%d ok, %d fallidos", passed, failed))
if failed > 0 then
	error("hay tests fallidos", 0)
end
