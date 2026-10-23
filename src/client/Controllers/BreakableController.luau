--!strict
-- Rompibles: barra de vida flotante, temblor al recibir golpes y celebración al romperse.
-- El daño lo decide el servidor (atributo HP); aquí solo se muestra.

local CollectionService = game:GetService("CollectionService")

local AtmosphereController = require(script.Parent.AtmosphereController)
local Net = require(script.Parent.Net)
local Sounds = require(script.Parent.Parent.UI.Sounds)
local Theme = require(script.Parent.Parent.UI.Theme)
local WorldFXController = require(script.Parent.WorldFXController)

local C = Theme.Colors

local BreakableController = {}

local function shake(part: BasePart)
	local origin = part:GetAttribute("ClientOrigin")
	if typeof(origin) ~= "CFrame" then
		origin = part.CFrame
		part:SetAttribute("ClientOrigin", origin)
	end
	local base = origin :: CFrame
	-- Cambio local: el servidor no mueve el rompible, así que el temblor es solo visual.
	part.CFrame = base * CFrame.new(math.random(-10, 10) / 40, 0, math.random(-10, 10) / 40)
	task.delay(0.06, function()
		if part.Parent then
			part.CFrame = base
		end
	end)
end

local function add(instance: Instance)
	if not instance:IsA("BasePart") or instance:FindFirstChild("HPBar") then
		return
	end
	local part = instance
	local gui = Instance.new("BillboardGui")
	gui.Name = "HPBar"
	gui.Size = UDim2.fromOffset(170, 46)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 2.2, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local title = Theme.label("", 16, C.White, {
		Size = UDim2.new(1, 0, 0, 18),
		TextStrokeTransparency = 0,
		Parent = gui,
	})
	local back = Theme.create("Frame", {
		Position = UDim2.fromOffset(10, 22),
		Size = UDim2.new(1, -20, 0, 16),
		BackgroundColor3 = C.Night,
		Parent = gui,
	}, { Theme.corner(8), Theme.stroke(C.Night, 2) })
	local fill = Theme.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Lime,
		Parent = back,
	}, { Theme.corner(8) })
	gui.Parent = part

	local function refresh(hit: boolean)
		local hp = part:GetAttribute("HP")
		local maxHp = part:GetAttribute("MaxHP")
		local coins = part:GetAttribute("Coins")
		local name = part:GetAttribute("DisplayName")
		if type(hp) ~= "number" or type(maxHp) ~= "number" or maxHp <= 0 then
			return
		end
		local fraction = math.clamp(hp / maxHp, 0, 1)
		fill.Size = UDim2.fromScale(fraction, 1)
		fill.BackgroundColor3 = if fraction > 0.5 then C.Lime elseif fraction > 0.2 then C.Amber else C.Red
		title.Text = string.format(
			"%s · %s 💰",
			if type(name) == "string" then name else "",
			Theme.formatNumber(if type(coins) == "number" then coins else 0)
		)
		if hit then
			shake(part)
		end
	end
	part:GetAttributeChangedSignal("HP"):Connect(function()
		refresh(true)
	end)
	refresh(false)
end

function BreakableController.start()
	CollectionService:GetInstanceAddedSignal("Breakable"):Connect(add)
	for _, instance in CollectionService:GetTagged("Breakable") do
		add(instance)
	end

	Net.get("BreakableBroken"):Connect(function(view: any)
		if type(view) ~= "table" or typeof(view.Position) ~= "Vector3" then
			return
		end
		local text = "+" .. Theme.formatNumber(view.Coins) .. " 💰"
		local color = C.Gold
		if view.Gems > 0 then
			text ..= "  +" .. view.Gems .. " 💎"
			color = C.Cyan
		end
		WorldFXController.popAt(view.Position, text, color)
		Sounds.play("Reward", if view.Type == "Vault" then 0.8 elseif view.Type == "Chest" then 1 else 1.25)
		if view.Type ~= "Coins" then
			AtmosphereController.flash(color, if view.Type == "Vault" then 1 else 0.4)
			AtmosphereController.punch(if view.Type == "Vault" then 6 else 3)
		end
	end)
end

return BreakableController
