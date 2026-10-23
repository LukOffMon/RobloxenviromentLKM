--!strict
-- Minijuego "Chanclazo Timing": el jugador pulsa al ritmo. El servidor fija el compás y juzga
-- cada pulsación con su propio reloj, así el cliente no puede inventarse aciertos.

export type Judgement = "Perfect" | "Good" | "Miss"

export type Session = {
	StartTime: number,
	Interval: number,
	Beats: number,
	PerfectWindow: number,
	GoodWindow: number,
	-- Beats ya acertados (cada uno puntúa una sola vez).
	Used: { [number]: boolean },
	Perfect: number,
	Good: number,
	Taps: number,
}

local TrainingLogic = {}

function TrainingLogic.newSession(
	startTime: number,
	interval: number,
	beats: number,
	perfectWindow: number,
	goodWindow: number
): Session
	return {
		StartTime = startTime,
		Interval = interval,
		Beats = beats,
		PerfectWindow = perfectWindow,
		GoodWindow = goodWindow,
		Used = {},
		Perfect = 0,
		Good = 0,
		Taps = 0,
	}
end

function TrainingLogic.endTime(session: Session): number
	return session.StartTime + session.Interval * (session.Beats - 1) + session.GoodWindow
end

-- Juzga una pulsación en el instante `time` (ya corregido por latencia).
-- Devuelve el juicio y el índice del beat (1..Beats) o nil si no hay beat cerca.
function TrainingLogic.judge(session: Session, time: number): (Judgement, number?)
	session.Taps += 1
	local position = (time - session.StartTime) / session.Interval
	local index = math.floor(position + 0.5) + 1
	if index < 1 or index > session.Beats or session.Used[index] then
		return "Miss", nil
	end
	local beatTime = session.StartTime + (index - 1) * session.Interval
	local offset = math.abs(time - beatTime)
	if offset <= session.PerfectWindow then
		session.Used[index] = true
		session.Perfect += 1
		return "Perfect", index
	elseif offset <= session.GoodWindow then
		session.Used[index] = true
		session.Good += 1
		return "Good", index
	end
	return "Miss", index
end

-- XP final: 3 por Perfect y 1 por Good. Pulsar sin parar (más taps que el doble de beats) anula el bono.
function TrainingLogic.xpFor(session: Session): number
	local xp = session.Perfect * 3 + session.Good
	if session.Taps > session.Beats * 2 then
		return math.floor(xp / 2)
	end
	return xp
end

return TrainingLogic
