--!strict
-- Punto de entrada del cliente de MonOG: arranca controladores y escucha el estado del servidor.
-- El cliente solo muestra y expresa intención; toda decisión vive en el servidor.

local ProximityPromptService = game:GetService("ProximityPromptService")

local Controllers = script.Parent.Controllers
local BattleController = require(Controllers.BattleController)
local ChatTagController = require(Controllers.ChatTagController)
local DailyController = require(Controllers.DailyController)
local GachaController = require(Controllers.GachaController)
local HUDController = require(Controllers.HUDController)
local InventoryController = require(Controllers.InventoryController)
local Net = require(Controllers.Net)
local PetController = require(Controllers.PetController)
local State = require(Controllers.State)
local TrainingController = require(Controllers.TrainingController)

HUDController.start()
local gui = HUDController.Gui :: ScreenGui

GachaController.start(gui)
InventoryController.start(gui, TrainingController.train)
TrainingController.start(gui)
BattleController.start(gui)
DailyController.start(gui)
PetController.start()
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

Net.get("Notify"):Connect(function(text: any, kind: any)
	if type(text) == "string" then
		HUDController.toast(text, if type(kind) == "string" then kind else nil)
	end
end)

-- Los ProximityPrompt del mapa (puerta del Asilo, bancos, arena) abren el panel que toca.
local PROMPT_ACTIONS: { [string]: () -> () } = {
	Gacha = GachaController.open,
	Battle = BattleController.open,
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
		callback()
	end
end)

-- El primer perfil puede haberse enviado antes de que el cliente escuchara: pedirlo de nuevo.
Net.get("RequestProfile"):Fire()

-- Gancho de los primeros segundos: si hay una caja gratis, abrir el Asilo directamente.
local connection: RBXScriptConnection? = nil
connection = State.Changed:Connect(function(kind)
	local profile = State.Profile
	if kind == "Full" and profile then
		if connection then
			connection:Disconnect()
		end
		if profile.Tickets > 0 and next(profile.OGs) == nil then
			task.wait(1.5)
			HUDController.toast("¡Bienvenido a MonOG! Tienes una Caja de Asilo GRATIS 🎁", "Reward")
			GachaController.open()
		end
	end
end)
