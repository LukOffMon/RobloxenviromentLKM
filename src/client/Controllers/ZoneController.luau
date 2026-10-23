--!strict
-- Portales de zona al estilo Pet Simulator: cada cliente ve abiertos los que ya pagó y,
-- en los cerrados, un cartel con el nombre y el precio (verde si le alcanza).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Configurations.GameConfig)

local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

type Gate = { Part: BasePart, Zone: number, Transparency: number, Sign: BillboardGui, Label: TextLabel }

local ZoneController = {}

local gates: { [BasePart]: Gate } = {}

local function render(gate: Gate)
	local profile = State.Profile
	local unlocked = if profile then profile.UnlockedZone or 1 else 1
	local data = GameConfig.Zones[gate.Zone]
	local open = gate.Zone <= unlocked
	-- Cambio solo local: el personaje lo mueve el cliente, así que puede cruzar el portal pagado.
	gate.Part.CanCollide = not open
	gate.Part.Transparency = if open then 1 else gate.Transparency
	gate.Sign.Enabled = not open
	local prompt = gate.Part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = not open and gate.Zone == unlocked + 1
	end
	if data and not open then
		local coins = if profile then profile.PensionCoins else 0
		local affordable = coins >= data.Price
		gate.Label.TextColor3 = if affordable then Theme.Colors.Lime else Theme.Colors.White
		gate.Label.Text = if gate.Zone == unlocked + 1
			then string.format("🔒 %s\n%s 💰", data.Name, Theme.formatNumber(data.Price))
			else string.format("🔒 %s\nDesbloquea antes la zona %d", data.Name, gate.Zone - 1)
	end
end

local function add(instance: Instance)
	if not instance:IsA("BasePart") or gates[instance] then
		return
	end
	local zone = instance:GetAttribute("Zone")
	if type(zone) ~= "number" then
		return
	end
	local sign = Instance.new("BillboardGui")
	sign.Name = "ZonePrice"
	sign.Size = UDim2.fromOffset(320, 100)
	sign.StudsOffset = Vector3.new(0, instance.Size.Y / 2 + 4, 0)
	sign.MaxDistance = 160
	sign.LightInfluence = 0
	local label = Theme.label("", 34, Theme.Colors.White, {
		Size = UDim2.fromScale(1, 1),
		TextScaled = true,
		TextStrokeTransparency = 0,
		Parent = sign,
	})
	sign.Parent = instance
	local gate = { Part = instance, Zone = zone, Transparency = instance.Transparency, Sign = sign, Label = label }
	gates[instance] = gate
	render(gate)
end

function ZoneController.start()
	CollectionService:GetInstanceAddedSignal("ZoneGate"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("ZoneGate"):Connect(function(instance)
		if instance:IsA("BasePart") then
			gates[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged("ZoneGate") do
		add(instance)
	end
	State.Changed:Connect(function()
		for _, gate in gates do
			render(gate)
		end
	end)
end

return ZoneController
