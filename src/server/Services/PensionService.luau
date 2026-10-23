--!strict
-- PensionService: ingreso pasivo de PensionCoins según los OGs equipados.
-- Multiplicador social: +15 % por amigo conectado en el mismo servidor (máximo +75 %).
-- Pensión offline: 2 h al 50 %, o 24 h al 100 % con el pase "Pensión Offline Ampliada".

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Configurations.GameConfig)
local ProgressionLogic = require(Shared.Logic.ProgressionLogic)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local OGService = require(script.Parent.OGService)

local CONFIG = GameConfig.Pension

local friendCounts: { [Player]: number } = {}
local remainders: { [Player]: number } = {}
local offlineEarned = Instance.new("BindableEvent")

local PensionService = {}
-- (player, amount) tras pagar la pensión acumulada offline.
PensionService.OfflineEarned = offlineEarned.Event

local function countFriends(player: Player): number
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWithAsync, player, other.UserId)
			if ok and isFriend then
				count += 1
			end
		end
	end
	return count
end

function PensionService.getFriendMultiplier(player: Player): number
	return ProgressionLogic.friendMultiplier(friendCounts[player] or 0, CONFIG.PerFriend, CONFIG.MaxFriendBonus)
end

function PensionService.getRate(player: Player): number
	return OGService.basePension(player) * PensionService.getFriendMultiplier(player)
end

local function payOffline(player: Player, profile: DataService.ProfileData)
	if profile.LastSeen <= 0 then
		return
	end
	-- Esperar a conocer los pases para aplicar el tope correcto.
	local deadline = os.clock() + 10
	while not MonetizationService.isReady(player) and os.clock() < deadline and player.Parent == Players do
		task.wait(0.25)
	end
	local extended = MonetizationService.ownsPass(player, "OfflinePension")
	local amount = ProgressionLogic.offlineEarnings(
		OGService.basePension(player),
		os.time() - profile.LastSeen,
		if extended then CONFIG.ExtendedOfflineCapSeconds else CONFIG.OfflineCapSeconds,
		if extended then CONFIG.ExtendedOfflineEfficiency else CONFIG.OfflineEfficiency
	)
	if amount > 0 and DataService.adjust(player, "PensionCoins", amount) then
		offlineEarned:Fire(player, amount)
	end
end

function PensionService.start()
	DataService.ProfileLoaded:Connect(payOffline)

	Players.PlayerRemoving:Connect(function(player)
		friendCounts[player] = nil
		remainders[player] = nil
	end)

	-- Recuento de amigos (llamadas que pueden ceder: en su propio hilo y con poca frecuencia).
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				friendCounts[player] = countFriends(player)
			end
			task.wait(CONFIG.FriendRefreshSeconds)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(CONFIG.TickSeconds)
			for _, player in Players:GetPlayers() do
				if DataService.getProfile(player) then
					-- Acumular decimales para no perder pensión con tasas bajas.
					local total = (remainders[player] or 0) + PensionService.getRate(player) * CONFIG.TickSeconds
					local whole = math.floor(total)
					remainders[player] = total - whole
					if whole > 0 then
						DataService.adjust(player, "PensionCoins", whole)
					end
				end
			end
		end
	end)
end

return PensionService
