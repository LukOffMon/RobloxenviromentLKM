--!strict
-- MonetizationService: Developer Products (ProcessReceipt idempotente) y Game Passes.
-- Reglas: cada PurchaseId se concede una sola vez, se guarda antes de devolver PurchaseGranted
-- y los objetos aleatorios de pago respetan PolicyService (ArePaidRandomItemsRestricted).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Configurations.GameConfig)

local DataService = require(script.Parent.DataService)
local GachaService = require(script.Parent.GachaService)

export type PassKey = "AutoTrainer" | "OfflinePension" | "VipDirector" | "QuantumAura"

local MAX_RECEIPTS_KEPT = 100

local passCache: { [Player]: { [string]: boolean } } = {}
local randomAllowedCache: { [Player]: boolean } = {}
local boxGranted = Instance.new("BindableEvent")
local passesChanged = Instance.new("BindableEvent")

local MonetizationService = {}
-- (player, results) cuando una compra de Robux concede tiradas: Main lanza la cinemática.
MonetizationService.BoxGranted = boxGranted.Event
-- (player) cuando cambia la lista de pases del jugador.
MonetizationService.PassesChanged = passesChanged.Event

local productsById: { [number]: any } = {}
for key, product in GameConfig.Products :: any do
	if product.Id > 0 then
		productsById[product.Id] = { Key = key, Product = product }
	end
end

function MonetizationService.ownsPass(player: Player, key: PassKey): boolean
	local cache = passCache[player]
	return cache ~= nil and cache[key] == true
end

-- true cuando ya se consultaron los pases y la política del jugador.
function MonetizationService.isReady(player: Player): boolean
	return passCache[player] ~= nil
end

function MonetizationService.getPasses(player: Player): { [string]: boolean }
	return table.clone(passCache[player] or {})
end

-- Si la política del país del jugador prohíbe objetos aleatorios de pago, las cajas de Robux se ocultan.
function MonetizationService.canBuyRandomItems(player: Player): boolean
	return randomAllowedCache[player] == true
end

local function refreshPlayer(player: Player)
	local cache = {}
	for key, pass in GameConfig.GamePasses :: any do
		if pass.Id > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			cache[key] = ok and owns == true
		end
	end
	passCache[player] = cache

	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	-- Ante la duda (error de red), tratar como restringido.
	randomAllowedCache[player] = ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false
	passesChanged:Fire(player)
end

local function pruneReceipts(receipts: { [string]: number })
	local entries = {}
	for id, time in receipts do
		table.insert(entries, { id = id, time = time })
	end
	if #entries <= MAX_RECEIPTS_KEPT then
		return
	end
	table.sort(entries, function(a, b)
		return a.time > b.time
	end)
	for i = MAX_RECEIPTS_KEPT + 1, #entries do
		receipts[entries[i].id] = nil
	end
end

local function grant(player: Player, product: any): boolean
	local profile = DataService.getProfile(player)
	if profile == nil then
		return false
	end
	if product.Kind == "XpBoost" then
		profile.XpBoostUntil = math.max(profile.XpBoostUntil, os.time()) + product.Minutes * 60
		DataService.markChanged(player)
	elseif product.Kind == "StarterBox" then
		profile.StarterPackBought = true
		DataService.adjust(player, "EpicTickets", 1)
	elseif product.Kind == "Box" then
		local results = GachaService.grantRolls(player, product.Count, nil)
		boxGranted:Fire(player, results)
	else
		return false
	end
	return true
end

local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local entry = productsById[receipt.ProductId]
	local profile = player and DataService.getProfile(player)
	if player == nil or entry == nil or profile == nil then
		-- Roblox reintentará cuando el jugador vuelva a entrar.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receipt.PurchaseId)
	if profile.ProcessedReceipts[purchaseId] == nil then
		if not grant(player, entry.Product) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		profile.ProcessedReceipts[purchaseId] = os.time()
		pruneReceipts(profile.ProcessedReceipts)
	end

	-- Confirmar solo cuando el perfil (con el recibo marcado) está guardado.
	local ok = DataService.saveNow(player):await()
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in GameConfig.GamePasses :: any do
			if pass.Id == passId then
				passCache[player] = passCache[player] or {}
				passCache[player][key] = true
				passesChanged:Fire(player)
			end
		end
	end)

	Players.PlayerAdded:Connect(refreshPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(refreshPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		passCache[player] = nil
		randomAllowedCache[player] = nil
	end)
end

return MonetizationService
