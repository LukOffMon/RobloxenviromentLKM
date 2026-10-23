--!strict
-- WorldService: conecta el mapa construido en Studio con los sistemas mediante etiquetas.
-- Contrato de etiquetas en docs/lore/world-building.md:
--   GachaDoor, TrainingBench, BattlePad -> ProximityPrompt con atributo Action
--   PodiumSlot (atributo Rank 1..3)      -> top 3 del servidor por nivel de rival
--   ZoneGate (atributo Zone)             -> portal cerrado "Próximamente"

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

type PromptSpec = { Action: string, ActionText: string, ObjectText: string }

local PROMPTS: { [string]: PromptSpec } = {
	GachaDoor = { Action = "Gacha", ActionText = "Abrir Caja de Asilo", ObjectText = "Edificio de Adopción" },
	TrainingBench = { Action = "Training", ActionText = "Entrenar (Chanclazo Timing)", ObjectText = "Gimnasio" },
	BattlePad = { Action = "Battle", ActionText = "¡Combatir!", ObjectText = "Arena Central" },
}

local ZONE_NAMES = { [3] = "Ciber-Asilo", [4] = "Galaxia OG" }

local WorldService = {}

local function addPrompt(part: Instance, spec: PromptSpec)
	if not part:IsA("BasePart") or part:FindFirstChild("MonOGPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MonOGPrompt"
	prompt.ActionText = spec.ActionText
	prompt.ObjectText = spec.ObjectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", spec.Action)
	prompt.Parent = part
end

local function addZoneSign(part: Instance)
	if not part:IsA("BasePart") or part:FindFirstChild("ZoneSign") then
		return
	end
	local zone = part:GetAttribute("Zone")
	local gui = Instance.new("BillboardGui")
	gui.Name = "ZoneSign"
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 3, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromHex("#39FF14")
	label.TextStrokeTransparency = 0.2
	label.Text = string.format("🔒 %s\nPróximamente", ZONE_NAMES[zone :: number] or "Zona secreta")
	label.Parent = gui
	gui.Parent = part
end

local function bindTag(tag: string, callback: (Instance) -> ())
	CollectionService:GetInstanceAddedSignal(tag):Connect(callback)
	for _, instance in CollectionService:GetTagged(tag) do
		task.spawn(callback, instance)
	end
end

-- Leaderstats visibles en la lista de jugadores y podio de los 3 mejores del servidor.
local function setupLeaderstats(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local tier = Instance.new("IntValue")
	tier.Name = "Rival"
	tier.Parent = folder
	local ogs = Instance.new("IntValue")
	ogs.Name = "OGs"
	ogs.Parent = folder
	folder.Parent = player
end

function WorldService.updateLeaderstats(player: Player)
	local profile = DataService.getProfile(player)
	local folder = player:FindFirstChild("leaderstats")
	if profile == nil or folder == nil then
		return
	end
	local count = 0
	for _ in profile.OGs do
		count += 1
	end
	(folder:FindFirstChild("Rival") :: IntValue).Value = profile.BattleTier;
	(folder:FindFirstChild("OGs") :: IntValue).Value = count
end

local function refreshPodium()
	local ranking = {}
	for _, player in Players:GetPlayers() do
		local profile = DataService.getProfile(player)
		if profile then
			table.insert(ranking, { Name = player.DisplayName, Tier = profile.BattleTier })
		end
	end
	table.sort(ranking, function(a, b)
		return a.Tier > b.Tier
	end)
	for _, slot in CollectionService:GetTagged("PodiumSlot") do
		if not slot:IsA("BasePart") then
			continue
		end
		local rank = slot:GetAttribute("Rank")
		local entry = if type(rank) == "number" then ranking[rank] else nil
		local gui = slot:FindFirstChild("PodiumSign") :: BillboardGui?
		if gui == nil then
			local newGui = Instance.new("BillboardGui")
			newGui.Name = "PodiumSign"
			newGui.Size = UDim2.fromOffset(220, 60)
			newGui.StudsOffset = Vector3.new(0, slot.Size.Y / 2 + 4, 0)
			newGui.MaxDistance = 150
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromHex("#FFD700")
			label.TextStrokeTransparency = 0.1
			label.Parent = newGui
			newGui.Parent = slot
			gui = newGui
		end
		local label = (gui :: BillboardGui):FindFirstChild("Label") :: TextLabel
		label.Text = if entry
			then string.format("#%d %s\nRival %d", rank, entry.Name, entry.Tier)
			else string.format("#%d\n¡Libre!", rank)
	end
end

function WorldService.start()
	for tag, spec in PROMPTS do
		bindTag(tag, function(instance)
			addPrompt(instance, spec)
		end)
	end
	bindTag("ZoneGate", addZoneSign)

	Players.PlayerAdded:Connect(setupLeaderstats)
	for _, player in Players:GetPlayers() do
		setupLeaderstats(player)
	end

	task.spawn(function()
		while true do
			refreshPodium()
			task.wait(10)
		end
	end)
end

return WorldService
