--!strict
-- GachaService: Cajas de Asilo. Las tiradas se hacen SOLO aquí, con RNG del servidor.
-- Probabilidades publicadas en la UI antes de comprar (docs/gdd/og-catalog.md).

local Shared = game:GetService("ReplicatedStorage").Shared
local GachaLogic = require(Shared.Logic.GachaLogic)
local GameConfig = require(Shared.Configurations.GameConfig)
local OGCatalog = require(Shared.Configurations.OGCatalog)

local DataService = require(script.Parent.DataService)
local OGService = require(script.Parent.OGService)

export type OpenMode = "Coin" | "Coin5" | "Gem" | "Ticket" | "EpicTicket"

export type RollView = {
	Uid: string,
	ArchetypeId: string,
	Rarity: string,
	Shiny: boolean,
	PityTriggered: boolean,
}

local CONFIG = GameConfig.Gacha
local rng = Random.new()

local GachaService = {}

GachaService.Modes = { "Coin", "Coin5", "Gem", "Ticket", "EpicTicket" }

local function nextNumber(): number
	return rng:NextNumber()
end

-- Hace `count` tiradas ya pagadas. Si el inventario se llena a mitad, lo que sobra se devuelve
-- como Tickets para que nada pagado se pierda.
function GachaService.grantRolls(player: Player, count: number, minRarityOrder: number?): { RollView }
	local profile = DataService.getProfile(player)
	local results: { RollView } = {}
	if profile == nil then
		return results
	end
	for _ = 1, count do
		if not OGService.hasRoom(player, 1) then
			DataService.adjust(player, "Tickets", 1)
			continue
		end
		-- Los tipos del catálogo tienen más campos que los que la lógica necesita.
		local roll, newPity =
			GachaLogic.roll(OGCatalog.Rarities :: any, OGCatalog.ArchetypesByRarity :: any, nextNumber, profile.Pity, {
				PityLimit = CONFIG.PityLimit,
				ShinyChance = CONFIG.ShinyChance,
				MinRarityOrder = minRarityOrder,
			})
		profile.Pity = newPity
		profile.TotalRolls += 1
		local uid = OGService.give(player, roll.ArchetypeId, roll.Shiny)
		if uid then
			table.insert(results, {
				Uid = uid,
				ArchetypeId = roll.ArchetypeId,
				Rarity = roll.Rarity,
				Shiny = roll.Shiny,
				PityTriggered = roll.PityTriggered,
			})
		end
	end
	DataService.markChanged(player)
	return results
end

-- Abre una caja pagando con moneda del juego o tickets. Devuelve resultados o el motivo del rechazo.
function GachaService.open(player: Player, mode: OpenMode): ({ RollView }?, string?)
	local profile = DataService.getProfile(player)
	if profile == nil then
		return nil, "Perfil no cargado"
	end

	local currency: DataService.Currency = "PensionCoins"
	local count, cost, minOrder = 1, 0, nil :: number?
	if mode == "Coin" then
		cost = CONFIG.CoinBoxCost
	elseif mode == "Coin5" then
		count, cost = 5, CONFIG.CoinBox5Cost
	elseif mode == "Gem" then
		currency, cost, minOrder = "GigaGems", CONFIG.GemBoxCost, CONFIG.GemBoxMinRarityOrder
	elseif mode == "Ticket" then
		currency, cost = "Tickets", 1
	elseif mode == "EpicTicket" then
		currency, cost, minOrder = "EpicTickets", 1, CONFIG.StarterMinRarityOrder
	else
		return nil, "Caja desconocida"
	end

	if not OGService.hasRoom(player, count) then
		return nil, "¡Tu asilo está lleno! Máximo " .. GameConfig.OG.MaxOwned .. " OGs."
	end
	-- Cobrar antes de tirar: si el cobro falla no hay tirada.
	if not DataService.adjust(player, currency, -cost) then
		return nil, "No te alcanza"
	end
	return GachaService.grantRolls(player, count, minOrder), nil
end

return GachaService
