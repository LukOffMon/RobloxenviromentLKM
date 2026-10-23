--!strict
-- Punto de entrada del servidor: arranca servicios y declara los remotes con su middleware.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Services.DataService)
local RemoteSignal = require(ReplicatedStorage.Shared.Network.RemoteSignal)
local SanityChecker = require(script.Parent.AntiExploit.SanityChecker)

local V = RemoteSignal.Validators

SanityChecker.start()
DataService.start()

-- Servidor -> cliente: estado del perfil para la UI.
local profileUpdated = RemoteSignal.server({
	Name = "ProfileUpdated",
	Args = {},
})

-- Cliente -> servidor: recoger una moneda del mundo.
-- El cliente solo dice QUÉ moneda; el servidor decide si puede y cuánto vale.
local collectCoin = RemoteSignal.server({
	Name = "CollectCoin",
	Args = { V.instanceOf("BasePart", workspace) },
	RateLimit = 5,
	RateWindowSeconds = 1,
	Sanity = function(player: Player, coin: BasePart)
		return coin:HasTag("Coin") and SanityChecker.canInteractWith(player, coin)
	end,
})

local function pushProfile(player: Player)
	local profile = DataService.getProfile(player)
	if profile then
		profileUpdated:FireClient(player, {
			Coins = profile.Coins,
			Level = profile.Level,
			Experience = profile.Experience,
		})
	end
end

DataService.ProfileLoaded:Connect(pushProfile)

collectCoin:Connect(function(player: Player, coin: BasePart)
	local value = coin:GetAttribute("Value")
	local amount = if type(value) == "number" and value > 0 and value % 1 == 0 then value else 1
	-- Destruir antes de pagar evita que dos peticiones simultáneas cobren la misma moneda.
	coin:Destroy()
	if DataService.addCoins(player, amount) then
		DataService.addExperience(player, 1)
		pushProfile(player)
	end
end)
