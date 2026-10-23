--!strict
-- Punto de entrada del cliente de MonOG: arranca controladores y escucha el estado del servidor.
-- El cliente solo muestra y expresa intención; toda decisión vive en el servidor.

local ProximityPromptService = game:GetService("ProximityPromptService")

local Sounds = require(script.Parent.UI.Sounds)

local Controllers = script.Parent.Controllers
local AtmosphereController = require(Controllers.AtmosphereController)
local BattleController = require(Controllers.BattleController)
local BreakableController = require(Controllers.BreakableController)
local ChatTagController = require(Controllers.ChatTagController)
local DailyController = require(Controllers.DailyController)
local GachaController = require(Controllers.GachaController)
local HUDController = require(Controllers.HUDController)
local InventoryController = require(Controllers.InventoryController)
local Net = require(Controllers.Net)
local PetController = require(Controllers.PetController)
local State = require(Controllers.State)
local TrainingController = require(Controllers.TrainingController)
local WorldFXController = require(Controllers.WorldFXController)
local ZoneController = require(Controllers.ZoneController)

AtmosphereController.start()
HUDController.start()
local gui = HUDController.Gui :: ScreenGui

GachaController.start(gui)
InventoryController.start(gui, TrainingController.train)
TrainingController.start(gui)
BattleController.start(gui)
DailyController.start(gui)
PetController.start()
WorldFXController.start()
BreakableController.start()
ZoneController.start()
ChatTagController.start()

Net.get("ProfileUpdated"):Connect(function(view: any)
	if type(view) == "table" then
		State.setFull(view)
	end
end)

Net.get("CurrencyUpdated"):Connect(function(view: any)
	if type(view) == "table" then
		State.setCurrencies(view)
	end
end)

Net.get("CandyCollected"):Connect(function(reward: any, position: any)
	if type(reward) ~= "table" or typeof(position) ~= "Vector3" then
		return
	end
	local text = "+" .. reward.PensionCoins .. " 💰"
	local color = Color3.fromHex("#FFD700")
	if reward.Tickets > 0 then
		text ..= "  +1 🎟"
		color = Color3.fromHex("#FF3EA5")
	elseif reward.GigaGems > 0 then
		text ..= "  +" .. reward.GigaGems .. " 💎"
		color = Color3.fromHex("#20E3E0")
	end
	WorldFXController.popAt(position, text, color)
	Sounds.play("Reward", 1.2 + math.random() * 0.3)
	if reward.Tickets > 0 or reward.GigaGems > 0 then
		AtmosphereController.flash(color, 0.6)
	end
end)

Net.get("Notify"):Connect(function(text: any, kind: any)
	if type(text) == "string" then
		HUDController.toast(text, if type(kind) == "string" then kind else nil)
	end
end)

-- Los ProximityPrompt del mapa (puerta del Asilo, bancos, arena) abren el panel que toca.
local PROMPT_ACTIONS: { [string]: (prompt: ProximityPrompt) -> () } = {
	BuyZone = function(prompt)
		local zone = prompt.Parent and prompt.Parent:GetAttribute("Zone")
		if type(zone) == "number" then
			Net.get("BuyZone"):Fire(zone)
		end
	end,
	Gacha = function()
		GachaController.open()
	end,
	Battle = function()
		BattleController.open()
	end,
	Training = function()
		local profile = State.Profile
		local uid = profile and profile.Equipped[1]
		if uid then
			TrainingController.train(uid)
		else
			GachaController.open()
		end
	end,
}

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local action = prompt:GetAttribute("Action")
	local callback = if type(action) == "string" then PROMPT_ACTIONS[action] else nil
	if callback then
		callback(prompt)
	end
end)

-- El primer perfil puede haberse enviado antes de que el cliente escuchara: pedirlo de nuevo.
Net.get("RequestProfile"):Fire()

-- Gancho de los primeros segundos: si hay una caja gratis, abrir el Asilo directamente.
-- Se comprueba también al arrancar, por si el perfil llegó antes de empezar a escuchar.
local welcomed = false
local function tryWelcome()
	local profile = State.Profile
	if welcomed or profile == nil then
		return
	end
	welcomed = true
	if profile.Tickets > 0 and next(profile.OGs) == nil then
		task.delay(1.5, function()
			HUDController.toast("¡Bienvenido a MonOG! Tienes una Caja de Asilo GRATIS 🎁", "Reward")
			GachaController.open()
		end)
	end
end
State.Changed:Connect(tryWelcome)
tryWelcome()
