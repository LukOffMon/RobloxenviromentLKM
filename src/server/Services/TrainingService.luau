--!strict
-- TrainingService: "Chanclazo Timing" en el Gimnasio del Asilo.
-- El servidor fija el compás con su reloj (workspace:GetServerTimeNow) y juzga cada pulsación
-- corrigiendo la latencia del jugador. El cliente solo envía "pulsé".

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Configurations.GameConfig)
local TrainingLogic = require(Shared.Logic.TrainingLogic)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local OGService = require(script.Parent.OGService)

local CONFIG = GameConfig.Training

-- ServerNow permite al cliente medir el compás en relativo aunque su reloj no esté sincronizado.
export type SessionView = { StartTime: number, ServerNow: number, Interval: number, Beats: number, Uid: string }
export type ResultView = { Uid: string, Perfect: number, Good: number, Beats: number, Xp: number }

type Active = { Uid: string, Session: TrainingLogic.Session }

local active: { [Player]: Active } = {}
local lastFinished: { [Player]: number } = {}
local finished = Instance.new("BindableEvent")

local TrainingService = {}
-- (player, ResultView) al terminar una sesión.
TrainingService.Finished = finished.Event

local function finish(player: Player, entry: Active)
	if active[player] ~= entry then
		return
	end
	active[player] = nil
	lastFinished[player] = os.clock()
	local xp = TrainingLogic.xpFor(entry.Session)
	if xp > 0 then
		OGService.addXp(player, entry.Uid, xp)
	end
	finished:Fire(
		player,
		{
			Uid = entry.Uid,
			Perfect = entry.Session.Perfect,
			Good = entry.Session.Good,
			Beats = entry.Session.Beats,
			Xp = xp,
		} :: ResultView
	)
end

function TrainingService.begin(player: Player, uid: string): (SessionView?, string?)
	local profile = DataService.getProfile(player)
	if profile == nil or profile.OGs[uid] == nil then
		return nil, "Ese OG no es tuyo"
	end
	if active[player] then
		return nil, "Ya estás entrenando"
	end
	if os.clock() - (lastFinished[player] or 0) < CONFIG.CooldownSeconds then
		return nil, "Tu OG está tomando su té. Espera un momento."
	end
	local serverNow = workspace:GetServerTimeNow()
	local startTime = serverNow + CONFIG.LeadInSeconds
	local session = TrainingLogic.newSession(
		startTime,
		CONFIG.IntervalSeconds,
		CONFIG.Beats,
		CONFIG.PerfectWindow,
		CONFIG.GoodWindow
	)
	local entry = { Uid = uid, Session = session }
	active[player] = entry
	task.delay(TrainingLogic.endTime(session) - workspace:GetServerTimeNow() + 0.5, finish, player, entry)
	return {
		StartTime = startTime,
		ServerNow = serverNow,
		Interval = CONFIG.IntervalSeconds,
		Beats = CONFIG.Beats,
		Uid = uid,
	},
		nil
end

-- Devuelve el juicio de la pulsación para el feedback inmediato del cliente.
function TrainingService.tap(player: Player): TrainingLogic.Judgement?
	local entry = active[player]
	if entry == nil then
		return nil
	end
	-- La pulsación salió del cliente ~media latencia antes de llegar aquí.
	local time = workspace:GetServerTimeNow() - player:GetNetworkPing() * 0.5
	return (TrainingLogic.judge(entry.Session, time))
end

function TrainingService.start()
	Players.PlayerRemoving:Connect(function(player)
		active[player] = nil
		lastFinished[player] = nil
	end)

	-- Pase "Enfermero Automático": XP pasiva a los OGs equipados cada minuto.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				if MonetizationService.ownsPass(player, "AutoTrainer") then
					for _, entry in OGService.getEquipped(player) do
						OGService.addXp(player, entry.Uid, CONFIG.AutoTrainerXpPerMinute)
					end
				end
			end
		end
	end)
end

return TrainingService
