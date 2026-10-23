--!strict
-- Mascotas OG: cada jugador lleva detrás a sus 3 abuelos equipados en estilo chibi-cabezón.
-- Se dibujan en cada cliente a partir del atributo público "EquippedOGs" (sin partes replicadas),
-- lo que mantiene el servidor ligero y la red sin tráfico de física.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local OGCatalog = require(ReplicatedStorage.Shared.Configurations.OGCatalog)

local OGVisuals = require(script.Parent.Parent.UI.OGVisuals)
local Theme = require(script.Parent.Parent.UI.Theme)

type Pet = { Model: Model, Root: BasePart, Parts: { BasePart }, Offset: Vector3, Phase: number }

-- Tamaño de las mascotas respecto al diseño base (cabeza de 2.4 studs).
local PET_SCALE = 0.7
local SLOT_OFFSETS = { Vector3.new(-4, 0, 4), Vector3.new(4, 0, 4), Vector3.new(0, 0, 6.5) }

local PetController = {}

local folder: Folder
local petsByPlayer: { [Player]: { Pet } } = {}
local signatures: { [Player]: string } = {}
local auras: { [Player]: ParticleEmitter? } = {}

local function part(
	model: Model,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	color: Color3,
	offset: CFrame,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size * PET_SCALE
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p:SetAttribute("Offset", CFrame.new(offset.Position * PET_SCALE) * offset.Rotation)
	p.Parent = model
	return p
end

-- Modelo 3D real si existe en ReplicatedStorage/MonOGAssets/OGs/<Id>; si no, el chibi de primitivas.
local function fromAsset(archetypeId: string, shiny: boolean): (Model?, BasePart?)
	local assets = ReplicatedStorage:FindFirstChild("MonOGAssets")
	local group = assets and assets:FindFirstChild("OGs")
	local template = group and group:FindFirstChild(archetypeId)
	if template == nil or not template:IsA("Model") or template.PrimaryPart == nil then
		return nil, nil
	end
	local model = template:Clone()
	local primary = model.PrimaryPart :: BasePart
	local pivot = model:GetPivot()
	local _, size = model:GetBoundingBox()
	-- Normaliza la altura a ~3 studs para que todos los OGs midan parecido.
	local scale = 3 / math.max(size.Y, 0.1)
	model:ScaleTo(model:GetScale() * scale)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = false
			-- Mismo contrato que el chibi: Offset relativo a la raíz, en el espacio sin escalar.
			local offset = primary.CFrame:ToObjectSpace(descendant.CFrame)
			descendant:SetAttribute("Offset", offset)
			if shiny and descendant ~= primary then
				descendant.Material = Enum.Material.Foil
				descendant.Color = descendant.Color:Lerp(Color3.fromHex("#FFD700"), 0.6)
			end
		end
	end
	model:PivotTo(pivot)
	return model, primary
end

-- Construye un abuelo chibi con primitivas: cabeza grande, cuerpo compacto y accesorios.
local function buildChibi(archetypeId: string, shiny: boolean): (Model, BasePart)
	local assetModel, assetRoot = fromAsset(archetypeId, shiny)
	if assetModel and assetRoot then
		return assetModel, assetRoot
	end
	local visual = OGVisuals.get(archetypeId)
	local archetype = OGCatalog.getArchetype(archetypeId)
	local rarityColor = Theme.rarityColor(if archetype then archetype.Rarity else "Common")
	local model = Instance.new("Model")
	model.Name = archetypeId

	local outfitMaterial = if shiny then Enum.Material.Foil else Enum.Material.SmoothPlastic
	local outfit = if shiny then Color3.fromHex("#FFD700") else visual.Outfit

	local root =
		part(model, "Body", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 1.8), outfit, CFrame.new(), outfitMaterial)
	part(model, "Head", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4), visual.Skin, CFrame.new(0, 1.8, 0))
	part(model, "Hair", Enum.PartType.Ball, Vector3.new(2.5, 2.2, 2.5), visual.Hair, CFrame.new(0, 2.15, 0.25))
	part(
		model,
		"EyeL",
		Enum.PartType.Ball,
		Vector3.new(0.35, 0.45, 0.2),
		Color3.new(0.05, 0.05, 0.08),
		CFrame.new(-0.45, 1.95, -1.1)
	)
	part(
		model,
		"EyeR",
		Enum.PartType.Ball,
		Vector3.new(0.35, 0.45, 0.2),
		Color3.new(0.05, 0.05, 0.08),
		CFrame.new(0.45, 1.95, -1.1)
	)
	if visual.Glasses then
		part(
			model,
			"Glasses",
			Enum.PartType.Block,
			Vector3.new(1.6, 0.18, 0.1),
			Color3.new(0.1, 0.1, 0.1),
			CFrame.new(0, 1.97, -1.18)
		)
	end
	if visual.Mustache then
		part(
			model,
			"Mustache",
			Enum.PartType.Block,
			Vector3.new(1.3, 0.28, 0.25),
			visual.Hair,
			CFrame.new(0, 1.45, -1.1)
		)
	end
	if visual.Beard then
		part(model, "Beard", Enum.PartType.Ball, Vector3.new(1.4, 1.3, 0.6), visual.Hair, CFrame.new(0, 0.95, -0.95))
	end
	if visual.Hat == "Sombrero" then
		part(
			model,
			"Brim",
			Enum.PartType.Cylinder,
			Vector3.new(0.2, 4.2, 4.2),
			visual.HatColor,
			CFrame.new(0, 2.95, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Neon
		)
		part(
			model,
			"Crown",
			Enum.PartType.Ball,
			Vector3.new(1.6, 1.4, 1.6),
			visual.HatColor,
			CFrame.new(0, 3.3, 0),
			Enum.Material.Neon
		)
	elseif visual.Hat == "Cap" then
		part(model, "Cap", Enum.PartType.Ball, Vector3.new(2.5, 1.4, 2.5), visual.HatColor, CFrame.new(0, 2.75, 0))
		part(model, "Visor", Enum.PartType.Block, Vector3.new(1.6, 0.15, 1), visual.HatColor, CFrame.new(0, 2.55, -1.2))
	elseif visual.Hat == "Bun" then
		part(model, "Bun", Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1), visual.HatColor, CFrame.new(0, 3.25, 0.4))
	elseif visual.Hat == "Band" then
		part(
			model,
			"Band",
			Enum.PartType.Cylinder,
			Vector3.new(0.35, 2.55, 2.55),
			visual.HatColor,
			CFrame.new(0, 2.35, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
	elseif visual.Hat == "Helmet" then
		local helmet = part(
			model,
			"Helmet",
			Enum.PartType.Ball,
			Vector3.new(3, 3, 3),
			visual.HatColor,
			CFrame.new(0, 1.9, 0),
			Enum.Material.Glass
		)
		helmet.Transparency = 0.6
	end

	-- Brillo en los ojos y mejillas sonrosadas: lo que más "vende" el estilo chibi.
	local white = Color3.new(1, 1, 1)
	part(
		model,
		"ShineL",
		Enum.PartType.Ball,
		Vector3.new(0.14, 0.14, 0.1),
		white,
		CFrame.new(-0.4, 2.05, -1.2),
		Enum.Material.Neon
	)
	part(
		model,
		"ShineR",
		Enum.PartType.Ball,
		Vector3.new(0.14, 0.14, 0.1),
		white,
		CFrame.new(0.5, 2.05, -1.2),
		Enum.Material.Neon
	)
	local cheek = Color3.fromRGB(255, 130, 150)
	part(model, "CheekL", Enum.PartType.Ball, Vector3.new(0.5, 0.3, 0.15), cheek, CFrame.new(-0.78, 1.6, -0.98)).Transparency =
		0.25
	part(model, "CheekR", Enum.PartType.Ball, Vector3.new(0.5, 0.3, 0.15), cheek, CFrame.new(0.78, 1.6, -0.98)).Transparency =
		0.25

	-- El andador del GDD: plateado normal, dorado de neón en la Edición Dorada.
	local walkerColor = if shiny then Color3.fromHex("#FFD700") else Color3.fromRGB(190, 196, 208)
	local walkerMaterial = if shiny then Enum.Material.Neon else Enum.Material.Metal
	part(
		model,
		"WalkerL",
		Enum.PartType.Block,
		Vector3.new(0.16, 1.7, 0.16),
		walkerColor,
		CFrame.new(-0.95, -0.15, -1.55),
		walkerMaterial
	)
	part(
		model,
		"WalkerR",
		Enum.PartType.Block,
		Vector3.new(0.16, 1.7, 0.16),
		walkerColor,
		CFrame.new(0.95, -0.15, -1.55),
		walkerMaterial
	)
	part(
		model,
		"WalkerBar",
		Enum.PartType.Block,
		Vector3.new(2.06, 0.16, 0.16),
		walkerColor,
		CFrame.new(0, 0.7, -1.55),
		walkerMaterial
	)
	part(
		model,
		"WheelL",
		Enum.PartType.Ball,
		Vector3.new(0.35, 0.35, 0.35),
		Color3.fromRGB(40, 40, 50),
		CFrame.new(-0.95, -1, -1.55)
	)
	part(
		model,
		"WheelR",
		Enum.PartType.Ball,
		Vector3.new(0.35, 0.35, 0.35),
		Color3.fromRGB(40, 40, 50),
		CFrame.new(0.95, -1, -1.55)
	)

	-- Aro de rareza en el suelo: se lee de lejos qué tan raro es cada OG.
	local ring = part(
		model,
		"AuraRing",
		Enum.PartType.Cylinder,
		Vector3.new(0.08, 3.4, 3.4),
		rarityColor,
		CFrame.new(0, -1.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.Material.Neon
	)
	ring.Transparency = 0.55
	if archetype and archetype.Rarity == "Transcendent" then
		model:SetAttribute("Rainbow", true)
	end

	-- Brillo de rareza (Common apenas brilla; Transcendent ilumina la plaza).
	local light = Instance.new("PointLight")
	light.Color = rarityColor
	light.Range = if archetype and archetype.Rarity ~= "Common" then 10 else 5
	light.Brightness = if shiny then 3 else 1.5
	light.Parent = root

	if
		archetype
		and (archetype.Rarity == "Legendary" or archetype.Rarity == "Mythic" or archetype.Rarity == "Transcendent")
	then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(rarityColor)
		sparkles.LightEmission = 1
		sparkles.Size = NumberSequence.new(0.25, 0)
		sparkles.Lifetime = NumberRange.new(0.8, 1.4)
		sparkles.Rate = if archetype.Rarity == "Transcendent" then 30 else 12
		sparkles.Speed = NumberRange.new(1, 2)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = root
	end

	model.PrimaryPart = root
	return model, root
end

local function clearPets(player: Player)
	local pets = petsByPlayer[player]
	if pets then
		for _, pet in pets do
			pet.Model:Destroy()
		end
	end
	petsByPlayer[player] = nil
end

local function rebuild(player: Player)
	local raw = player:GetAttribute("EquippedOGs")
	local signature = if type(raw) == "string" then raw else ""
	if signatures[player] == signature then
		return
	end
	signatures[player] = signature
	clearPets(player)
	local pets = {}
	local slot = 0
	for entry in string.gmatch(signature, "[^,]+") do
		local id, shinyFlag = string.match(entry, "^(.-):(%d)$")
		if id and OGCatalog.getArchetype(id) and slot < #SLOT_OFFSETS then
			slot += 1
			local model, root = buildChibi(id, shinyFlag == "1")
			model.Parent = folder
			local parts = {}
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("BasePart") then
					table.insert(parts, descendant)
				end
			end
			table.insert(pets, {
				Model = model,
				Root = root,
				Parts = parts,
				Offset = SLOT_OFFSETS[slot],
				Phase = slot * 1.3,
			})
		end
	end
	petsByPlayer[player] = pets
end

-- Aura del pase "Abuelo Cuántico": partículas arcoíris alrededor del jugador.
local function updateAura(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local wants = player:GetAttribute("QuantumAura") == true and root ~= nil
	local existing = auras[player]
	if wants and (existing == nil or existing.Parent ~= root) then
		if existing then
			existing:Destroy()
		end
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#FF2A4D")),
			ColorSequenceKeypoint.new(0.33, Color3.fromHex("#FFD700")),
			ColorSequenceKeypoint.new(0.66, Color3.fromHex("#39FF14")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#20E3E0")),
		})
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.Rate = 40
		emitter.Lifetime = NumberRange.new(1, 1.6)
		emitter.Speed = NumberRange.new(2, 4)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = root
		auras[player] = emitter
	elseif not wants and existing then
		existing:Destroy()
		auras[player] = nil
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("EquippedOGs"):Connect(function()
		rebuild(player)
	end)
	player:GetAttributeChangedSignal("QuantumAura"):Connect(function()
		updateAura(player)
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateAura(player)
	end)
	rebuild(player)
	updateAura(player)
end

local function step()
	local now = os.clock()
	for player, pets in petsByPlayer do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp == nil then
			continue
		end
		local base = hrp.CFrame
		local rainbow = Color3.fromHSV((now * 0.25) % 1, 0.9, 1)
		-- Modo ataque: si el jugador tocó un rompible, sus OGs lo rodean y lo golpean.
		local targetName = player:GetAttribute("Target")
		local breakables = workspace:FindFirstChild("MonOGBreakables")
		local attackPart = if type(targetName) == "string"
				and targetName ~= ""
				and breakables
			then breakables:FindFirstChild(targetName) :: BasePart?
			else nil
		for index, pet in pets do
			-- Saltitos con squish & stretch: se aplasta al tocar el suelo y se estira en el aire.
			local speed = if attackPart then 11 else 5
			local wave = math.abs(math.sin(now * speed + pet.Phase))
			local hop = wave * (if attackPart then 1.6 else 0.9)
			local squash = 1 - 0.2 * (1 - math.min(wave / 0.3, 1)) + 0.06 * wave
			local widen = 1 + (1 - squash) * 0.6
			local look: CFrame
			if attackPart then
				local center = attackPart.Position
				local angle = (index / #pets) * math.pi * 2 + now * 0.6
				local radius = math.max(attackPart.Size.X, attackPart.Size.Z) / 2 + 2.2
				local spot = Vector3.new(
					center.X + math.cos(angle) * radius,
					hrp.Position.Y - 1.6 + hop,
					center.Z + math.sin(angle) * radius
				)
				look = CFrame.lookAt(spot, Vector3.new(center.X, spot.Y, center.Z))
			else
				local target = base * CFrame.new(pet.Offset) * CFrame.new(0, -1.6 + hop, 0)
				look = CFrame.lookAt(target.Position, target.Position + base.LookVector)
			end
			local current = pet.Root.CFrame
			local goal = current:Lerp(look, 0.15)
			if (current.Position - look.Position).Magnitude > 40 then
				goal = look
			end
			local isRainbow = pet.Model:GetAttribute("Rainbow") == true
			for _, child in pet.Parts do
				do
					local offset = child:GetAttribute("Offset")
					if typeof(offset) == "CFrame" then
						local p = offset.Position
						local squished = Vector3.new(p.X * widen, p.Y * squash, p.Z * widen)
						child.CFrame = goal * CFrame.new(squished) * offset.Rotation
					else
						child.CFrame = goal
					end
					if isRainbow and child.Name == "AuraRing" then
						child.Color = rainbow
					end
				end
			end
		end
	end
end

function PetController.start()
	folder = Instance.new("Folder")
	folder.Name = "MonOGPets"
	folder.Parent = workspace

	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		clearPets(player)
		signatures[player] = nil
		local aura = auras[player]
		if aura then
			aura:Destroy()
			auras[player] = nil
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return PetController
