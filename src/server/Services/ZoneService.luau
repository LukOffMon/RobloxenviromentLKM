--!strict
-- ZoneService: zonas al estilo Pet Simulator, que se desbloquean en orden pagando en su portal.
-- El cliente abre los portales ya pagados solo para ese jugador; el servidor valida rompibles por zona.

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Configurations.GameConfig)

local DataService = require(script.Parent.DataService)

local ZoneService = {}

function ZoneService.isUnlocked(player: Player, zone: number): boolean
	local profile = DataService.getProfile(player)
	return profile ~= nil and zone <= profile.UnlockedZone
end

function ZoneService.multiplier(zone: number): number
	local data = GameConfig.Zones[zone]
	return if data then data.Multiplier else 1
end

-- Compra la zona siguiente. Devuelve true o el motivo del rechazo.
function ZoneService.buy(player: Player, zone: number): (boolean, string?)
	local profile = DataService.getProfile(player)
	local data = GameConfig.Zones[zone]
	if profile == nil or data == nil then
		return false, "Zona desconocida"
	end
	if zone <= profile.UnlockedZone then
		return false, "Ya tienes esa zona"
	end
	if zone ~= profile.UnlockedZone + 1 then
		return false, "Primero desbloquea " .. GameConfig.Zones[profile.UnlockedZone + 1].Name
	end
	if not DataService.adjust(player, "PensionCoins", -data.Price) then
		return false, string.format("Te faltan monedas: cuesta %d 💰", data.Price)
	end
	profile.UnlockedZone = zone
	DataService.markChanged(player)
	return true, nil
end

return ZoneService
