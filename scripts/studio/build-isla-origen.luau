--!strict
-- Construye la zona Isla Origen (tutorial, niveles 1–3) en el place abierto de Studio.
-- Uso: pegar en la barra de comandos de Studio o ejecutar con la herramienta MCP `execute_luau`.
-- Es idempotente: borra la versión anterior (modelo y terreno de la zona) y la vuelve a crear.
-- Documentación: docs/lore/isla-origen.md

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local ZONE_NAME = "IslaOrigen"
local TOP_Y = 51 -- altura de la superficie de la isla principal
local COIN_VALUE = 1
local BONUS_COIN_VALUE = 5

local rng = Random.new(2024)
local terrain = workspace.Terrain

-- Limpiar ---------------------------------------------------------------
local old = workspace:FindFirstChild(ZONE_NAME)
if old then
	old:Destroy()
end
terrain:FillBlock(CFrame.new(0, 40, -40), Vector3.new(200, 120, 260), Enum.Material.Air)

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy() -- el mundo es un archipiélago flotante
end
workspace.FallenPartsDestroyHeight = -50 -- quien cae reaparece rápido

local zone = Instance.new("Model")
zone.Name = ZONE_NAME

local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = zone
	return f
end

local coinsFolder = folder("Coins")
local platformsFolder = folder("Platforms")
local decorFolder = folder("Decor")
local markersFolder = folder("Markers")

local function part(props: { [string]: any }, parent: Instance?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

-- Terreno ---------------------------------------------------------------
-- Isla flotante: disco de hierba con un cono de roca debajo (cilindros cada vez más estrechos).
local function floatingIsland(center: Vector3, radius: number)
	local layers = { 0.85, 0.65, 0.42, 0.2 }
	for i, scale in layers do
		local y = center.Y - 3 - i * 8
		terrain:FillCylinder(CFrame.new(center.X, y, center.Z), 9, radius * scale, Enum.Material.Rock)
	end
	terrain:FillCylinder(CFrame.new(center.X, center.Y - 3, center.Z), 6, radius, Enum.Material.Grass)
	-- Bordes irregulares
	for _ = 1, math.floor(radius / 3) do
		local angle = rng:NextNumber(0, math.pi * 2)
		local r = radius * rng:NextNumber(0.75, 0.95)
		local size = rng:NextNumber(4, 8)
		-- Siempre por debajo de la superficie para no crear bultos en la hierba.
		local pos = center + Vector3.new(math.cos(angle) * r, -size - rng:NextNumber(1, 4), math.sin(angle) * r)
		terrain:FillBall(pos, size, Enum.Material.Rock)
	end
end

floatingIsland(Vector3.new(0, TOP_Y, 0), 60) -- isla principal
floatingIsland(Vector3.new(0, TOP_Y + 8, -124), 16) -- islote de recompensa
task.wait()

-- Spawn -----------------------------------------------------------------
local spawn = workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, TOP_Y + 0.5, 44)
spawn.Material = Enum.Material.Slate
spawn.Color = Color3.fromRGB(120, 200, 255)
spawn.Duration = 0
spawn.Parent = zone

-- Monedas ---------------------------------------------------------------
local coinCount = 0
local function coin(pos: Vector3, value: number?)
	coinCount += 1
	local isBonus = value ~= nil and value > COIN_VALUE
	local c = part({
		Name = string.format("Coin_%02d", coinCount),
		Shape = Enum.PartType.Cylinder,
		Size = if isBonus then Vector3.new(0.6, 5, 5) else Vector3.new(0.4, 3, 3),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0),
		Material = Enum.Material.Neon,
		Color = if isBonus then Color3.fromRGB(120, 230, 255) else Color3.fromRGB(255, 205, 60),
		CanCollide = false,
		CastShadow = false,
	})
	c:SetAttribute("Value", value or COIN_VALUE)
	CollectionService:AddTag(c, "Coin")
	c.Parent = coinsFolder
end

local COIN_Y = TOP_Y + 3

-- 1. Pasillo de bienvenida: 10 monedas en línea recta (misión de la Guardiana Iza).
for i = 0, 9 do
	coin(Vector3.new(0, COIN_Y, 34 - i * 4))
end

-- 2. Anillo alrededor del Cristal de Origen.
local CRYSTAL_POS = Vector3.new(0, TOP_Y, -26)
for i = 0, 11 do
	local a = i / 12 * math.pi * 2
	coin(CRYSTAL_POS + Vector3.new(math.cos(a) * 14, 3, math.sin(a) * 14))
end

-- 3. Monedas sueltas por la isla para explorar.
local scattered = {
	Vector3.new(-30, 0, 20),
	Vector3.new(-38, 0, 0),
	Vector3.new(-28, 0, -22),
	Vector3.new(30, 0, 22),
	Vector3.new(40, 0, 4),
	Vector3.new(26, 0, -30),
	Vector3.new(-14, 0, 40),
	Vector3.new(16, 0, 42),
}
for _, offset in scattered do
	coin(Vector3.new(offset.X, COIN_Y, offset.Z))
end
task.wait()

-- Cristal de Origen (hito central) ------------------------------------
local crystal = Instance.new("Model")
crystal.Name = "CristalOrigen"
part({
	Name = "Base",
	Size = Vector3.new(10, 2, 10),
	CFrame = CFrame.new(CRYSTAL_POS + Vector3.new(0, 1, 0)),
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(90, 95, 110),
}, crystal)
for i, h in { 14, 9, 7 } do
	local angle = (i - 1) * math.rad(120)
	local offset = if i == 1 then Vector3.zero else Vector3.new(math.cos(angle) * 2.2, 0, math.sin(angle) * 2.2)
	local shard = part({
		Name = "Shard" .. i,
		Size = Vector3.new(2.4, h, 2.4),
		CFrame = CFrame.new(CRYSTAL_POS + offset + Vector3.new(0, 2 + h / 2, 0))
			* CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), math.rad(45), math.rad(rng:NextNumber(-12, 12))),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(110, 220, 255),
		CastShadow = false,
	})
	shard.Parent = crystal
end
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(110, 220, 255)
glow.Range = 24
glow.Brightness = 2
glow.Parent = crystal:FindFirstChild("Shard1")
crystal.Parent = decorFolder

-- Ruta de saltos hacia el islote de recompensa --------------------------
-- Plataformas de 8x8 separadas 11 studs (huecos de 3) que suben 2 studs cada una: saltos fáciles.
-- Se vuelve por el mismo camino: bajar es aún más fácil.
for i = 1, 4 do
	local y = TOP_Y - 0.5 + i * 2
	local z = -58 - i * 11
	part({
		Name = "JumpPlatform" .. i,
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(0, y, z),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(150, 160, 180),
	}, platformsFolder)
	coin(Vector3.new(0, y + 3.5, z))
end

-- Islote de recompensa: anillo de monedas y una moneda grande en el centro.
local REWARD_POS = Vector3.new(0, TOP_Y + 8, -124)
for i = 0, 7 do
	local a = i / 8 * math.pi * 2
	coin(REWARD_POS + Vector3.new(math.cos(a) * 8, 3, math.sin(a) * 8))
end
coin(REWARD_POS + Vector3.new(0, 4, 0), BONUS_COIN_VALUE)
task.wait()

-- Decoración: árboles y rocas ---------------------------------------------
local function tree(pos: Vector3)
	local model = Instance.new("Model")
	model.Name = "Tree"
	local height = rng:NextNumber(8, 12)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 2, 2),
		CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(105, 70, 45),
	}, model)
	local leafSize = rng:NextNumber(8, 11)
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(leafSize, leafSize, leafSize),
		CFrame = CFrame.new(pos + Vector3.new(0, height + leafSize * 0.3, 0)),
		Material = Enum.Material.LeafyGrass,
		Color = Color3.fromRGB(80, 170, 75),
		CastShadow = false,
	}, model)
	model.Parent = decorFolder
end

for i = 1, 10 do
	local a = (i / 10) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
	local r = rng:NextNumber(44, 52)
	local pos = Vector3.new(math.cos(a) * r, TOP_Y, math.sin(a) * r)
	-- Dejar libre la salida norte hacia las plataformas y la zona del spawn.
	if math.abs(pos.X) > 10 then
		tree(pos)
	end
end

for _ = 1, 8 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(20, 50)
	local size = rng:NextNumber(2, 4)
	part({
		Name = "Rock",
		Size = Vector3.new(size * 1.4, size, size),
		CFrame = CFrame.new(math.cos(a) * r, TOP_Y + size / 3, math.sin(a) * r)
			* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
		Material = Enum.Material.Rock,
		Color = Color3.fromRGB(110, 110, 115),
		CastShadow = false,
	}, decorFolder)
end

-- Marcadores para sistemas futuros ------------------------------------------
local izaMarker = part({
	Name = "GuardianaIza",
	Size = Vector3.new(2, 5, 2),
	CFrame = CFrame.new(10, TOP_Y + 2.5, 36),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
})
izaMarker:SetAttribute("NpcId", "GuardianaIza")
CollectionService:AddTag(izaMarker, "NpcSpawn")
izaMarker.Parent = markersFolder

zone.Parent = workspace

-- Ambiente de cielo abierto --------------------------------------------------
Lighting.ClockTime = 14
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Haze = 1
atmosphere.Color = Color3.fromRGB(200, 225, 255)
atmosphere.Decay = Color3.fromRGB(120, 160, 220)
atmosphere.Parent = Lighting

return string.format("Isla Origen construida: %d monedas", coinCount)
