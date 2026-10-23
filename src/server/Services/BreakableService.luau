--!strict
-- BreakableService: el bucle principal de Pet Simulator adaptado a MonOG.
-- Montones de monedas, cofres y cajas fuertes aparecen en los marcadores BreakableSpawn (atributo Zone).
-- El jugador toca uno y sus OGs equipados lo atacan; el servidor calcula el daño, valida zona y
-- distancia, reparte el premio entre quienes ayudaron y lo vuelve a hacer aparecer.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = game:GetService("ReplicatedStorage").Shared
local BreakableLogic = require(Shared.Logic.BreakableLogic)
local GameConfig = require(Shared.Configurations.GameConfig)
local OGCatalog = require(Shared.Configurations.OGCatalog)
local ProgressionLogic = require(Shared.Logic.ProgressionLogic)

local DataService = require(script.Parent.DataService)
local OGService = require(script.Parent.OGService)
local ZoneService = require(script.Parent.ZoneService)

local CONFIG = GameConfig.Breakables

export type BrokenView = { Type: string, Coins: number, Gems: number, Position: Vector3 }

type Live = {
	Part: BasePart,
	Marker: BasePart,
	Kind: BreakableLogic.BreakableType,
	Zone: number,
	Coins: number,
	Damage: { [Player]: number },
}

local rng = Random.new()
local folder: Folder
local live: { [BasePart]: Live } = {}
local byMarker: { [BasePart]: BasePart? } = {}
local targets: { [Player]: BasePart } = {}
local broken = Instance.new("BindableEvent")

local BreakableService = {}
-- (player, BrokenView) a cada jugador que ayudó a romper uno.
BreakableService.Broken = broken.Event

local function decor(
	main: BasePart,
	shape: Enum.PartType,
	size: Vector3,
	color: Color3,
	offset: CFrame,
	material: Enum.Material?
)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = main.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = main
	weld.Part1 = p
	weld.Parent = p
	p.Parent = main
end

-- Si hay un modelo 3D en ReplicatedStorage/MonOGAssets/Breakables/<Tipo>, se usa ese.
-- Todas sus piezas quedan ancladas y colgando de la PrimaryPart, que es la que se toca y se destruye.
local function fromAsset(kind: BreakableLogic.BreakableType, position: Vector3): BasePart?
	local assets = ReplicatedStorage:FindFirstChild("MonOGAssets")
	local group = assets and assets:FindFirstChild("Breakables")
	local template = group and group:FindFirstChild(kind.Id)
	if template == nil or not template:IsA("Model") or template.PrimaryPart == nil then
		return nil
	end
	local model = template:Clone()
	local _, size = model:GetBoundingBox()
	model:PivotTo(
		CFrame.new(position + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	)
	local primary = model.PrimaryPart :: BasePart
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = descendant == primary
			if descendant ~= primary then
				descendant.Parent = primary
			end
		end
	end
	primary.Parent = nil
	model:Destroy()
	return primary
end

-- Aspecto de respaldo: montón de monedas doradas, cofre de madera o caja fuerte metálica.
local function build(kind: BreakableLogic.BreakableType, position: Vector3): BasePart
	local asset = fromAsset(kind, position)
	if asset then
		return asset
	end
	local gold = Color3.fromHex("#FFD23F")
	local main = Instance.new("Part")
	main.Anchored = true
	main.CanCollide = true
	main.CastShadow = true
	main.TopSurface = Enum.SurfaceType.Smooth
	if kind.Id == "Coins" then
		main.Shape = Enum.PartType.Cylinder
		main.Size = Vector3.new(0.6, 3.6, 3.6)
		main.Color = gold
		main.Material = Enum.Material.Foil
		main.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		for i = 1, 4 do
			local angle = i * 1.7
			decor(
				main,
				Enum.PartType.Cylinder,
				Vector3.new(0.3, 1.4, 1.4),
				gold,
				CFrame.new(0.35 + i * 0.28, math.cos(angle) * 0.7, math.sin(angle) * 0.7),
				Enum.Material.Neon
			)
		end
	elseif kind.Id == "Chest" then
		main.Size = Vector3.new(4, 2.6, 2.8)
		main.Color = Color3.fromRGB(150, 92, 48)
		main.Material = Enum.Material.Wood
		main.CFrame = CFrame.new(position + Vector3.new(0, 1.3, 0))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		decor(
			main,
			Enum.PartType.Block,
			Vector3.new(4.2, 1.1, 3),
			Color3.fromRGB(120, 70, 36),
			CFrame.new(0, 1.7, 0),
			Enum.Material.Wood
		)
		decor(main, Enum.PartType.Block, Vector3.new(0.5, 3.9, 3.1), gold, CFrame.new(-1.4, 0.4, 0), Enum.Material.Foil)
		decor(main, Enum.PartType.Block, Vector3.new(0.5, 3.9, 3.1), gold, CFrame.new(1.4, 0.4, 0), Enum.Material.Foil)
		decor(main, Enum.PartType.Ball, Vector3.new(0.7, 0.7, 0.7), gold, CFrame.new(0, 1, -1.5), Enum.Material.Neon)
	else
		main.Size = Vector3.new(5.5, 5.5, 5)
		main.Color = Color3.fromRGB(110, 118, 135)
		main.Material = Enum.Material.DiamondPlate
		main.CFrame = CFrame.new(position + Vector3.new(0, 2.75, 0))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		decor(
			main,
			Enum.PartType.Cylinder,
			Vector3.new(0.4, 2.6, 2.6),
			Color3.fromRGB(70, 75, 90),
			CFrame.new(0, 0.3, -2.6) * CFrame.Angles(0, math.rad(90), 0),
			Enum.Material.Metal
		)
		decor(main, Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8), gold, CFrame.new(0, 0.3, -2.85), Enum.Material.Neon)
		decor(main, Enum.PartType.Block, Vector3.new(5.7, 0.4, 5.2), gold, CFrame.new(0, 2.6, 0), Enum.Material.Foil)
	end
	return main
end

local function teamAttacks(player: Player): { number }
	local attacks = {}
	for _, entry in OGService.getEquipped(player) do
		local archetype = OGCatalog.getArchetype(entry.OG.Id)
		if archetype then
			table.insert(attacks, ProgressionLogic.statsAt(archetype.Stats, entry.OG.Level).ATK)
		end
	end
	return attacks
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setTarget(player: Player, part: BasePart?)
	if part then
		targets[player] = part
	else
		targets[player] = nil
	end
	player:SetAttribute("Target", if part then part.Name else "")
end

-- Busca el rompible desbloqueado más cercano para seguir rompiendo sin tocar cada uno.
local function nearestFor(player: Player, from: Vector3): BasePart?
	local best, bestDistance = nil, CONFIG.AutoRetargetRange
	for part, entry in live do
		local distance = (part.Position - from).Magnitude
		if distance < bestDistance and ZoneService.isUnlocked(player, entry.Zone) then
			best, bestDistance = part, distance
		end
	end
	return best
end

function BreakableService.attack(player: Player, part: BasePart): boolean
	local entry = live[part]
	local root = rootOf(player)
	if entry == nil or root == nil or DataService.getProfile(player) == nil then
		return false
	end
	if not ZoneService.isUnlocked(player, entry.Zone) then
		return false
	end
	if (root.Position - part.Position).Magnitude > CONFIG.AttackRange then
		return false
	end
	if #OGService.getEquipped(player) == 0 then
		return false
	end
	setTarget(player, part)
	return true
end

local function breakPart(part: BasePart, entry: Live)
	live[part] = nil
	byMarker[entry.Marker] = nil
	local position = part.Position
	local shares = BreakableLogic.split(entry.Coins, entry.Damage)
	for player, coins in shares do
		if player.Parent == Players then
			DataService.adjust(player, "PensionCoins", coins)
			local gems = if rng:NextNumber() < entry.Kind.GemChance then entry.Kind.Gems else 0
			if gems > 0 then
				DataService.adjust(player, "GigaGems", gems)
			end
			broken:Fire(player, { Type = entry.Kind.Id, Coins = coins, Gems = gems, Position = position } :: BrokenView)
		end
	end
	part:Destroy()
	-- Los que atacaban este siguen con el más cercano.
	for player, target in targets do
		if target == part then
			local root = rootOf(player)
			setTarget(player, if root then nearestFor(player, root.Position) else nil)
		end
	end
end

local function spawnAt(marker: BasePart)
	local zone = marker:GetAttribute("Zone")
	local zoneId = if type(zone) == "number" then zone else 1
	local kind = BreakableLogic.pickType(CONFIG.Types :: any, rng:NextNumber())
	local hp, coins = BreakableLogic.stats(kind, ZoneService.multiplier(zoneId))
	local part = build(kind, marker.Position)
	part.Name = HttpService:GenerateGUID(false)
	part:SetAttribute("Type", kind.Id)
	part:SetAttribute("DisplayName", kind.Name)
	part:SetAttribute("Zone", zoneId)
	part:SetAttribute("MaxHP", hp)
	part:SetAttribute("HP", hp)
	part:SetAttribute("Coins", coins)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = CONFIG.AttackRange
	click.Parent = part
	click.MouseClick:Connect(function(player)
		BreakableService.attack(player, part)
	end)
	part:AddTag("Breakable")
	live[part] = { Part = part, Marker = marker, Kind = kind, Zone = zoneId, Coins = coins, Damage = {} }
	byMarker[marker] = part
	part.Parent = folder
end

local function tick(dt: number)
	for player, part in targets do
		local entry = live[part]
		local root = rootOf(player)
		if entry == nil or root == nil or player.Parent ~= Players then
			setTarget(player, nil)
			continue
		end
		-- Si se aleja demasiado, sus OGs vuelven con él.
		if (root.Position - part.Position).Magnitude > CONFIG.AttackRange * 1.5 then
			setTarget(player, nil)
			continue
		end
		local damage = BreakableLogic.teamDps(teamAttacks(player), CONFIG.DamageScale) * dt
		entry.Damage[player] = (entry.Damage[player] or 0) + damage
		local hp = math.max(0, (part:GetAttribute("HP") :: number) - damage)
		part:SetAttribute("HP", math.floor(hp))
		if hp <= 0 then
			breakPart(part, entry)
		end
	end
end

function BreakableService.start()
	folder = Instance.new("Folder")
	folder.Name = "MonOGBreakables"
	folder.Parent = workspace

	Players.PlayerRemoving:Connect(function(player)
		targets[player] = nil
		for _, entry in live do
			entry.Damage[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			local dt = task.wait(CONFIG.TickSeconds)
			tick(dt)
		end
	end)

	task.spawn(function()
		while true do
			local perZone: { [number]: number } = {}
			for _, entry in live do
				perZone[entry.Zone] = (perZone[entry.Zone] or 0) + 1
			end
			local free: { BasePart } = {}
			for _, marker in CollectionService:GetTagged("BreakableSpawn") do
				if marker:IsA("BasePart") and marker:IsDescendantOf(workspace) and byMarker[marker] == nil then
					table.insert(free, marker)
				end
			end
			-- Rellena hasta el máximo por zona, en orden aleatorio.
			for i = #free, 2, -1 do
				local j = rng:NextInteger(1, i)
				free[i], free[j] = free[j], free[i]
			end
			for _, marker in free do
				local zone = marker:GetAttribute("Zone")
				local zoneId = if type(zone) == "number" then zone else 1
				if (perZone[zoneId] or 0) < CONFIG.MaxPerZone then
					perZone[zoneId] = (perZone[zoneId] or 0) + 1
					spawnAt(marker)
				end
			end
			task.wait(CONFIG.RespawnSeconds)
		end
	end)
end

return BreakableService
