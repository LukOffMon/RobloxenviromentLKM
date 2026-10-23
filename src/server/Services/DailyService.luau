--!strict
-- DailyService: "La Hora del Bingo Matutino". Una recompensa por día con racha de 7.

local Shared = game:GetService("ReplicatedStorage").Shared
local DailyLogic = require(Shared.Logic.DailyLogic)
local GameConfig = require(Shared.Configurations.GameConfig)

local DataService = require(script.Parent.DataService)

local DailyService = {}

function DailyService.canClaim(player: Player): boolean
	local profile = DataService.getProfile(player)
	if profile == nil then
		return false
	end
	local can = DailyLogic.claim(profile.LastDailyDay, profile.DailyStreak, DailyLogic.dayNumber(os.time()))
	return can
end

-- Devuelve el día de la racha reclamado (1..7) y su recompensa, o nil si ya se reclamó hoy.
function DailyService.claim(player: Player): (number?, { [string]: number }?)
	local profile = DataService.getProfile(player)
	if profile == nil then
		return nil, nil
	end
	local today = DailyLogic.dayNumber(os.time())
	local can, streak = DailyLogic.claim(profile.LastDailyDay, profile.DailyStreak, today)
	if not can then
		return nil, nil
	end
	profile.LastDailyDay = today
	profile.DailyStreak = streak
	local reward = GameConfig.Daily[streak] :: any
	for currency, amount in reward do
		DataService.adjust(player, currency, amount)
	end
	DataService.markChanged(player)
	return streak, reward
end

return DailyService
