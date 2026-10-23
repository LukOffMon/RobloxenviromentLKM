--!strict
-- BattleService: combates por turnos contra escuadrones NPC en la Arena Central.
-- El servidor simula el combate entero (BattleLogic) y el cliente solo reproduce el registro.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local BattleLogic = require(Shared.Logic.BattleLogic)
local GameConfig = require(Shared.Configurations.GameConfig)
local OGCatalog = require(Shared.Configurations.OGCatalog)
local ProgressionLogic = require(Shared.Logic.ProgressionLogic)

local DataService = require(script.Parent.DataService)
local OGService = require(script.Parent.OGService)

local CONFIG = GameConfig.Battle

export type RewardView = { PensionCoins: number, GigaGems: number, TeamXp: number, NewTier: number }
export type BattleView = BattleLogic.Result & { Tier: number, Rewards: RewardView? }

local rng = Random.new()
local lastBattle: { [Player]: number } = {}

local BattleService = {}

local function toFighter(archetypeId: string, level: number, shiny: boolean): BattleLogic.FighterInput?
	local archetype = OGCatalog.getArchetype(archetypeId)
	if archetype == nil then
		return nil
	end
	local fighter: BattleLogic.FighterInput = {
		Name = archetype.DisplayName,
		ArchetypeId = archetype.Id,
		Rarity = archetype.Rarity :: string,
		Level = level,
		Shiny = shiny,
		Stats = ProgressionLogic.statsAt(archetype.Stats, level),
		Special = archetype.Special,
	}
	return fighter
end

-- Escuadrón rival del nivel `tier`: crece en nivel y rareza de forma determinista.
function BattleService.npcTeam(tier: number): { BattleLogic.FighterInput }
	local team = {}
	local size = if tier < 3 then 2 else 3
	local tierRng = Random.new(tier * 7919)
	for slot = 1, size do
		local maxOrder = math.clamp(1 + math.floor((tier - 1) / 4), 1, #OGCatalog.Rarities)
		local order = math.clamp(maxOrder - (slot - 1) % 2, 1, maxOrder)
		local rarity = OGCatalog.Rarities[order]
		local pool = OGCatalog.ArchetypesByRarity[rarity.Id]
		local archetype = pool[tierRng:NextInteger(1, #pool)]
		local level = math.clamp(tier * 2 - 1 + slot - 2, 1, GameConfig.OG.MaxLevel)
		local fighter = toFighter(archetype.Id, level, false)
		if fighter then
			table.insert(team, fighter)
		end
	end
	return team
end

function BattleService.fight(player: Player): (BattleView?, string?)
	local profile = DataService.getProfile(player)
	if profile == nil then
		return nil, "Perfil no cargado"
	end
	if os.clock() - (lastBattle[player] or 0) < CONFIG.CooldownSeconds then
		return nil, "Tus OGs están recuperando el aliento"
	end

	local equipped = OGService.getEquipped(player)
	local team = {}
	for _, entry in equipped do
		local fighter = toFighter(entry.OG.Id, entry.OG.Level, entry.OG.Shiny)
		if fighter then
			table.insert(team, fighter)
		end
	end
	if #team == 0 then
		return nil, "Equipa al menos un OG en «Mis OGs»"
	end
	lastBattle[player] = os.clock()

	local tier = profile.BattleTier
	local result = BattleLogic.simulate(team, BattleService.npcTeam(tier), function()
		return rng:NextNumber()
	end)
	local view = table.clone(result) :: any
	view.Tier = tier

	if result.Winner == "A" then
		local coins = CONFIG.CoinsBase + CONFIG.CoinsPerTier * tier
		local gems = if tier % CONFIG.GemMilestoneEvery == 0 then CONFIG.GemMilestoneReward else 0
		DataService.adjust(player, "PensionCoins", coins)
		if gems > 0 then
			DataService.adjust(player, "GigaGems", gems)
		end
		for _, entry in equipped do
			OGService.addXp(player, entry.Uid, CONFIG.TeamXp)
		end
		profile.BattleTier = tier + 1
		profile.BattlesWon += 1
		DataService.markChanged(player)
		view.Rewards = { PensionCoins = coins, GigaGems = gems, TeamXp = CONFIG.TeamXp, NewTier = tier + 1 }
	else
		-- Perder también entrena un poco: el jugador nunca sale con las manos vacías.
		for _, entry in equipped do
			OGService.addXp(player, entry.Uid, math.floor(CONFIG.TeamXp / 2))
		end
	end
	return view :: BattleView, nil
end

function BattleService.start()
	Players.PlayerRemoving:Connect(function(player)
		lastBattle[player] = nil
	end)
end

return BattleService
