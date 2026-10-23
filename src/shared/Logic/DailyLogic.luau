--!strict
-- "La Hora del Bingo Matutino": recompensa diaria con racha de 7 días.
-- Romper la racha la reinicia y se pierde el premio mayor del día 7.

local DailyLogic = {}

DailyLogic.SecondsPerDay = 86400
DailyLogic.CycleLength = 7

function DailyLogic.dayNumber(unixTime: number): number
	return math.floor(unixTime / DailyLogic.SecondsPerDay)
end

-- Devuelve si se puede reclamar hoy y la racha resultante tras reclamar (1..7).
function DailyLogic.claim(lastClaimDay: number, streak: number, today: number): (boolean, number)
	if lastClaimDay == today then
		return false, streak
	end
	if lastClaimDay == today - 1 then
		return true, (streak % DailyLogic.CycleLength) + 1
	end
	return true, 1
end

return DailyLogic
