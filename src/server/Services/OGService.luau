--!strict
-- OGService: inventario de abuelos, equipo activo (3) y XP. Única puerta para tocar profile.OGs.

local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Configurations.GameConfig)
local OGCatalog = require(Shared.Configurations.OGCatalog)
local ProgressionLogic = require(Shared.Logic.ProgressionLogic)

local DataService = require(script.Parent.DataService)

local OGService = {}

function OGService.count(player: Player): number
	local profile = DataService.getProfile(player)
	if profile == nil then
		return 0
	end
	local n = 0
	for _ in profile.OGs do
		n += 1
	end
	return n
end

function OGService.hasRoom(player: Player, amount: number): boolean
	return OGService.count(player) + amount <= GameConfig.OG.MaxOwned
end

-- Añade un OG nuevo y lo equipa automáticamente si hay hueco. Devuelve su uid.
function OGService.give(player: Player, archetypeId: string, shiny: boolean): string?
	local profile = DataService.getProfile(player)
	if profile == nil or OGCatalog.getArchetype(archetypeId) == nil or not OGService.hasRoom(player, 1) then
		return nil
	end
	local uid = HttpService:GenerateGUID(false)
	profile.OGs[uid] = {
		Id = archetypeId,
		Level = 1,
		XP = 0,
		Shiny = shiny,
		Obtained = os.time(),
	}
	if #profile.Equipped < GameConfig.OG.MaxEquipped then
		table.insert(profile.Equipped, uid)
	end
	DataService.markChanged(player)
	return uid
end

function OGService.setEquipped(player: Player, uid: string, equipped: boolean): boolean
	local profile = DataService.getProfile(player)
	if profile == nil or profile.OGs[uid] == nil then
		return false
	end
	local index = table.find(profile.Equipped, uid)
	if equipped then
		if index or #profile.Equipped >= GameConfig.OG.MaxEquipped then
			return false
		end
		table.insert(profile.Equipped, uid)
	else
		-- Siempre debe quedar al menos un OG equipado para poder combatir.
		if index == nil or #profile.Equipped <= 1 then
			return false
		end
		table.remove(profile.Equipped, index)
	end
	DataService.markChanged(player)
	return true
end

-- Suma XP a un OG respetando el nivel máximo y el boost de "Poción de Expreso Doble".
function OGService.addXp(player: Player, uid: string, amount: number): boolean
	local profile = DataService.getProfile(player)
	local og = profile and profile.OGs[uid]
	if profile == nil or og == nil or amount <= 0 then
		return false
	end
	local multiplier = if profile.XpBoostUntil > os.time() then GameConfig.Training.BoostMultiplier else 1
	og.Level, og.XP = ProgressionLogic.addXp(og.Level, og.XP, math.floor(amount * multiplier), GameConfig.OG.MaxLevel)
	DataService.markChanged(player)
	return true
end

-- Devuelve los OGs equipados que siguen existiendo (limpia uids rotos).
function OGService.getEquipped(player: Player): { { Uid: string, OG: DataService.OGData } }
	local profile = DataService.getProfile(player)
	local result = {}
	if profile == nil then
		return result
	end
	for i = #profile.Equipped, 1, -1 do
		if profile.OGs[profile.Equipped[i]] == nil then
			table.remove(profile.Equipped, i)
		end
	end
	for _, uid in profile.Equipped do
		table.insert(result, { Uid = uid, OG = profile.OGs[uid] })
	end
	return result
end

-- Pensión por segundo del equipo equipado, sin multiplicadores sociales.
function OGService.basePension(player: Player): number
	local total = 0
	for _, entry in OGService.getEquipped(player) do
		local archetype = OGCatalog.getArchetype(entry.OG.Id)
		local rarity = archetype and OGCatalog.getRarity(archetype.Rarity)
		if rarity then
			total += ProgressionLogic.pensionPerSecond(rarity.PensionPerSecond, entry.OG.Level)
		end
	end
	return total
end

return OGService
