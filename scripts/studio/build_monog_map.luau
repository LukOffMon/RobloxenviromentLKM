--!strict
-- Construye el mapa de MonOG: Pocket Seniors (estilo Toon-Cyber de noche) en el place abierto de Studio.
-- Uso: pegar en la barra de comandos de Studio o ejecutar con la herramienta MCP `execute_luau`.
-- No destructivo: archiva Workspace.IslaOrigen en ServerStorage.Archive_IslaOrigen (se recupera
-- volviendo a ponerle Parent = Workspace), no toca el Terrain y construye el mundo en X = +800.
-- Repetible: regenera Workspace.MonOGWorld cada vez.
-- Los nombres y etiquetas son un contrato con el código de src/ (ver docs/lore/world-building.md).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local ORIGIN = Vector3.new(800, 0, 0) -- centro de la plaza, lejos de Isla Origen

-- Paleta Toon-Cyber (docs/gdd/art-direction.md)
local BG0 = Color3.fromHex("#0B0E14")
local BG1 = Color3.fromHex("#1A0933")
local LIME = Color3.fromHex("#39FF14")
local ORANGE = Color3.fromHex("#FF8C00")
local GOLD = Color3.fromHex("#FFD700")
local PINK = Color3.fromHex("#FF3EA5")
local CYAN = Color3.fromHex("#20E3E0")
local YELLOW = Color3.fromRGB(255, 240, 60)
local PURPLE = Color3.fromHex("#24124A") -- Theme.Colors.PanelLight
local METAL = Color3.fromRGB(40, 44, 60)
local WHITE = Color3.fromRGB(235, 235, 245)

local rng = Random.new(1950)

-- Todo el cambio se puede deshacer con Ctrl+Z en Studio.
local okRecording, recording = pcall(function()
	return ChangeHistoryService:TryBeginRecording("Construir mapa MonOG")
end)

-- Preparar el place sin destruir nada del usuario ------------------------------
-- El SpawnLocation existente se reutiliza en el parque.
local existingSpawn: SpawnLocation? = nil
local isla = workspace:FindFirstChild("IslaOrigen")
if isla then
	local islaSpawn = isla:FindFirstChildOfClass("SpawnLocation")
	if islaSpawn then
		existingSpawn = islaSpawn
	end
	local archive = ServerStorage:FindFirstChild("Archive_IslaOrigen")
	if archive == nil then
		local folder = Instance.new("Folder")
		folder.Name = "Archive_IslaOrigen"
		folder.Parent = ServerStorage
		archive = folder
	end
	isla.Parent = archive
end
for _, child in workspace:GetChildren() do
	if child:IsA("SpawnLocation") then
		if existingSpawn == nil then
			existingSpawn = child
		end
	end
end

local previous = workspace:FindFirstChild("MonOGWorld")
if previous then
	previous:Destroy() -- generado por este mismo script
end

-- Streaming para móvil. Los radios y StreamOutBehavior no se pueden fijar por script:
-- se ajustan a mano en Workspace (ventana Propiedades, sección Streaming).
workspace.StreamingEnabled = true

-- Utilidades --------------------------------------------------------------
-- Todo se construye alrededor de (0, 0, 0) y al final se desplaza a ORIGIN.
local world = Instance.new("Model")
world.Name = "MonOGWorld"

local function model(name: string, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

local function neon(props: { [string]: any }, parent: Instance): Part
	props.Material = Enum.Material.Neon
	return part(props, parent)
end

-- Cilindro de eje vertical (los cilindros de Roblox tienen el eje en X).
local function disc(pos: Vector3, diameter: number, height: number): (CFrame, Vector3)
	return CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(height, diameter, diameter)
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

local function sign(parent: BasePart, text: string, color: Color3, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	gui.Parent = parent
end

local function tag(instance: Instance, name: string)
	CollectionService:AddTag(instance, name)
end

local function lamp(parent: Instance, pos: Vector3, height: number, color: Color3, withLight: boolean)
	local m = model("Lamp", parent)
	local cf, size = disc(pos + Vector3.new(0, height / 2, 0), 0.8, height)
	part({ Name = "Pole", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = METAL }, m)
	part({
		Name = "Arm",
		Size = Vector3.new(0.5, 0.5, 2.4),
		CFrame = CFrame.new(pos + Vector3.new(0, height - 0.3, 0)),
		Color = METAL,
	}, m)
	local bulb = neon({
		Name = "Bulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.6, 2.6, 2.6),
		CFrame = CFrame.new(pos + Vector3.new(0, height + 1, 0)),
		Color = color,
	}, m)
	if withLight then
		light(bulb, color, 20, 1)
	end
end

-- Suelo base: evita caer al vacío fuera de las zonas.
part({ Name = "Ground", Size = Vector3.new(700, 2, 700), CFrame = CFrame.new(0, -1, 40), Color = BG0 }, world)

-- PLAZA ---------------------------------------------------------------------
local plaza = model("Plaza", world)
do
	local cf, size = disc(Vector3.new(0, 0, 0), 190, 1)
	part({ Name = "Floor", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = BG1 }, plaza)
	cf, size = disc(Vector3.new(0, -0.2, 0), 194, 0.9)
	neon({ Name = "Rim", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = CYAN }, plaza)
	-- Anillo interior de baldosas neón alrededor de la arena.
	cf, size = disc(Vector3.new(0, 0.15, 0), 104, 0.9)
	local innerRing =
		neon({ Name = "InnerRing", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = PINK }, plaza)
	tag(innerRing, "NeonPulse")
	innerRing:SetAttribute("PulseSpeed", 0.8)
	cf, size = disc(Vector3.new(0, 0.2, 0), 102, 0.9)
	part({ Name = "InnerFloor", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = PURPLE }, plaza)

	-- Caminos de neón hacia el parque (sur), la residencia (norte) y los portales (oeste/este).
	for i, dir in { Vector3.zAxis, -Vector3.zAxis, -Vector3.xAxis, Vector3.xAxis } do
		for _, side in { -3, 3 } do
			local offset = Vector3.new(dir.Z, 0, -dir.X) * side
			local mid = dir * 72 + offset + Vector3.new(0, 0.55, 0)
			neon({
				Name = "PathLine",
				Size = Vector3.new(0.6, 0.1, 42),
				CFrame = CFrame.lookAt(mid, mid + dir),
				Color = if i % 2 == 0 then PINK else CYAN,
			}, plaza)
		end
	end

	-- Farolas: solo la mitad lleva luz para cuidar el rendimiento en móvil.
	for i = 0, 7 do
		local a = math.rad(22.5 + i * 45)
		local color = if i % 2 == 0 then PINK else CYAN
		lamp(plaza, Vector3.new(math.cos(a) * 86, 0.5, math.sin(a) * 86), 14, color, i % 2 == 0)
	end
end
task.wait()

-- ARENA: coliseo hexagonal con gradas, abierto hacia el sur (+Z) --------------
local arena = model("Arena", plaza)
do
	local APOTHEM = 30
	local function sideWidth(apothem: number): number
		return 2 * apothem / math.sqrt(3)
	end

	-- Un hexágono regular es la unión de tres rectángulos girados 60°.
	for i = 0, 2 do
		part({
			Name = "Floor",
			Size = Vector3.new(sideWidth(APOTHEM), 0.5, APOTHEM * 2),
			CFrame = CFrame.new(0, 0.75, 0) * CFrame.Angles(0, math.rad(i * 60), 0),
			Color = BG1,
		}, arena)
	end

	local cf, size = disc(Vector3.new(0, 1.1, 0), 26, 0.4)
	local pad =
		neon({ Name = "BattlePad", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = LIME }, arena)
	tag(pad, "BattlePad")
	light(pad, LIME, 24, 1.2)
	cf, size = disc(Vector3.new(0, 1.05, 0), 30, 0.3)
	local padRing =
		neon({ Name = "BattlePadRing", Shape = Enum.PartType.Cylinder, CFrame = cf, Size = size, Color = PINK }, arena)
	tag(padRing, "NeonPulse")

	-- Gradas: 3 escalones por lado; el lado sur (normal 90°) es la entrada.
	for k = 0, 5 do
		local normalDeg = 30 + k * 60
		if normalDeg == 90 then
			continue
		end
		local normal = Vector3.new(math.cos(math.rad(normalDeg)), 0, math.sin(math.rad(normalDeg)))
		local rotation = CFrame.Angles(0, math.rad(90 - normalDeg), 0)
		for t = 1, 3 do
			local inner = APOTHEM + (t - 1) * 4
			local top = 1 + t * 2.5
			local width = sideWidth(inner + 4)
			part({
				Name = "Stand",
				Size = Vector3.new(width, top, 4),
				CFrame = CFrame.new(normal * (inner + 2) + Vector3.new(0, top / 2, 0)) * rotation,
				Color = if t % 2 == 0 then PURPLE else BG1,
			}, arena)
			neon({
				Name = "StandTrim",
				Size = Vector3.new(sideWidth(inner), 0.3, 0.3),
				CFrame = CFrame.new(normal * (inner + 0.15) + Vector3.new(0, top, 0)) * rotation,
				Color = if t == 3 then ORANGE elseif k % 2 == 0 then PINK else CYAN,
			}, arena)
		end
	end

	-- Torres de focos en las esquinas del fondo (norte), apuntando al centro.
	for _, deg in { 240, 300 } do
		local base = Vector3.new(math.cos(math.rad(deg)), 0, math.sin(math.rad(deg))) * 46
		local tower = model("FloodlightTower", arena)
		local pcf, psize = disc(base + Vector3.new(0, 12, 0), 1.4, 24)
		part({ Name = "Pole", Shape = Enum.PartType.Cylinder, CFrame = pcf, Size = psize, Color = METAL }, tower)
		local head = neon({
			Name = "Head",
			Size = Vector3.new(6, 3, 1),
			CFrame = CFrame.lookAt(base + Vector3.new(0, 25, 0), Vector3.new(0, 1, 0)),
			Color = WHITE,
		}, tower)
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Angle = 45
		spot.Range = 60
		spot.Brightness = 2
		spot.Color = Color3.fromRGB(220, 230, 255)
		spot.Parent = head
	end

	-- Arco de entrada sur.
	for _, x in { -16, 16 } do
		neon({
			Name = "EntrancePillar",
			Size = Vector3.new(2, 12, 2),
			CFrame = CFrame.new(x, 6.5, APOTHEM + 2),
			Color = CYAN,
		}, arena)
	end
	local arch = part({
		Name = "EntranceSign",
		Size = Vector3.new(34, 4, 1),
		CFrame = CFrame.new(0, 14, APOTHEM + 2),
		Color = BG0,
	}, arena)
	sign(arch, "ARENA OG", ORANGE, Enum.NormalId.Back)
	neon({
		Name = "EntranceTrim",
		Size = Vector3.new(34, 0.4, 1.2),
		CFrame = CFrame.new(0, 16.1, APOTHEM + 2),
		Color = ORANGE,
	}, arena)
end
task.wait()

-- PODIO: 3 pedestales dorados al sureste de la arena --------------------------
local podium = model("Podium", plaza)
do
	local BASE = Vector3.new(50, 0.5, 55)
	part({
		Name = "Base",
		Size = Vector3.new(26, 1, 10),
		CFrame = CFrame.new(BASE + Vector3.new(0, 0.5, 0)),
		Color = BG0,
	}, podium)
	neon({
		Name = "BaseTrim",
		Size = Vector3.new(26.4, 0.3, 10.4),
		CFrame = CFrame.new(BASE + Vector3.new(0, 0.2, 0)),
		Color = GOLD,
	}, podium)
	local slots = { { rank = 2, x = -8, h = 6 }, { rank = 1, x = 0, h = 8 }, { rank = 3, x = 8, h = 4 } }
	for _, slot in slots do
		local p = part({
			Name = "Slot" .. slot.rank,
			Size = Vector3.new(7, slot.h, 7),
			CFrame = CFrame.new(BASE + Vector3.new(slot.x, 1 + slot.h / 2, 0)),
			Color = GOLD,
			Material = Enum.Material.Foil,
		}, podium)
		p:SetAttribute("Rank", slot.rank)
		tag(p, "PodiumSlot")
		sign(p, tostring(slot.rank), BG1, Enum.NormalId.Back)
	end
	light(podium:FindFirstChild("Slot1") :: BasePart, GOLD, 18, 1)
	local backdrop = part({
		Name = "Backdrop",
		Size = Vector3.new(26, 10, 1),
		CFrame = CFrame.new(BASE + Vector3.new(0, 14, -4.5)),
		Color = BG0,
	}, podium)
	sign(backdrop, "TOP OG DEL SERVIDOR", GOLD, Enum.NormalId.Back)
	neon({
		Name = "BackdropTrim",
		Size = Vector3.new(26.6, 10.6, 0.6),
		CFrame = CFrame.new(BASE + Vector3.new(0, 14, -5)),
		Color = ORANGE,
	}, podium)
end
task.wait()

-- RESIDENCIA DE ADOPCIÓN (norte) ---------------------------------------------
local adoption = model("AdoptionBuilding", world)
do
	local FRONT_Z = -100
	local OLD_BRICK = Color3.fromRGB(125, 70, 95)
	part({
		Name = "Body",
		Size = Vector3.new(60, 28, 30),
		CFrame = CFrame.new(0, 14, FRONT_Z - 15),
		Color = OLD_BRICK,
	}, adoption)
	part({
		Name = "Roof",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(64, 30, 30),
		CFrame = CFrame.new(0, 28, FRONT_Z - 15),
		Color = Color3.fromRGB(35, 70, 95),
	}, adoption)
	neon({
		Name = "RoofTrim",
		Size = Vector3.new(64, 0.5, 31),
		CFrame = CFrame.new(0, 28.2, FRONT_Z - 15),
		Color = CYAN,
	}, adoption)

	-- Ventanas iluminadas a ambos lados de la puerta, en dos pisos.
	for _, x in { -24, -15, 15, 24 } do
		for _, y in { 8, 18 } do
			neon({
				Name = "Window",
				Size = Vector3.new(5, 6, 0.4),
				CFrame = CFrame.new(x, y, FRONT_Z + 0.2),
				Color = Color3.fromRGB(255, 200, 110),
			}, adoption)
			neon({
				Name = "Awning",
				Size = Vector3.new(6.5, 0.5, 2.5),
				CFrame = CFrame.new(x, y + 3.8, FRONT_Z + 1.2) * CFrame.Angles(math.rad(-15), 0, 0),
				Color = if y == 8 then PINK else CYAN,
			}, adoption)
		end
	end

	-- Columnas y puerta grande de adopción (el código añade el ProximityPrompt).
	for _, x in { -9, 9 } do
		local cf, size = disc(Vector3.new(x, 9, FRONT_Z + 1.5), 2.4, 18)
		part({
			Name = "Column",
			Shape = Enum.PartType.Cylinder,
			CFrame = cf,
			Size = size,
			Color = WHITE,
		}, adoption)
	end
	local door = neon({
		Name = "AdoptionDoor",
		Size = Vector3.new(12, 16, 1),
		CFrame = CFrame.new(0, 8, FRONT_Z + 0.5),
		Color = ORANGE,
	}, adoption)
	tag(door, "GachaDoor")
	light(door, ORANGE, 22, 1.5)
	part({
		Name = "DoorFrame",
		Size = Vector3.new(14, 1, 1.4),
		CFrame = CFrame.new(0, 16.5, FRONT_Z + 0.5),
		Color = GOLD,
	}, adoption)
	part({
		Name = "Steps",
		Size = Vector3.new(18, 0.6, 6),
		CFrame = CFrame.new(0, 0.3, FRONT_Z + 3),
		Color = WHITE,
	}, adoption)

	-- Marquesina con bombillas en cadena (Blink, animadas por WorldFXController).
	part({
		Name = "Marquee",
		Size = Vector3.new(22, 1, 7),
		CFrame = CFrame.new(0, 18.5, FRONT_Z + 3.5),
		Color = BG0,
	}, adoption)
	neon({
		Name = "MarqueeTrim",
		Size = Vector3.new(22.4, 0.4, 7.4),
		CFrame = CFrame.new(0, 18, FRONT_Z + 3.5),
		Color = LIME,
	}, adoption)
	for i = 0, 10 do
		local bulb = neon({
			Name = "MarqueeBulb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.8, 0.8, 0.8),
			CFrame = CFrame.new(-10 + i * 2, 17.5, FRONT_Z + 7.1),
			Color = if i % 2 == 0 then YELLOW else PINK,
		}, adoption)
		bulb:SetAttribute("BlinkIndex", i + 1)
		tag(bulb, "Blink")
	end
	local board = part({
		Name = "Sign",
		Size = Vector3.new(30, 5, 1),
		CFrame = CFrame.new(0, 26, FRONT_Z + 0.8),
		Color = BG0,
	}, adoption)
	sign(board, "RESIDENCIA OG · ADOPCIÓN", GOLD, Enum.NormalId.Back)
	neon({
		Name = "SignTrim",
		Size = Vector3.new(30.4, 5.4, 0.6),
		CFrame = CFrame.new(0, 26, FRONT_Z + 0.4),
		Color = PINK,
	}, adoption)
end
task.wait()

-- ZONA 1: PARQUE (sur, zona inicial) ----------------------------------------
local trees: { Vector3 } = {} -- también lo usan los marcadores de caramelos
local park = model("Zona1_Parque", world)
do
	local CENTER = Vector3.new(0, 0, 162)
	part({
		Name = "Grass",
		Size = Vector3.new(130, 0.6, 130),
		CFrame = CFrame.new(CENTER),
		Color = Color3.fromRGB(55, 200, 70),
	}, park)
	for _, edge in { { 0, 65, 130, 1 }, { 0, -65, 130, 1 }, { 65, 0, 1, 130 }, { -65, 0, 1, 130 } } do
		neon({
			Name = "GrassTrim",
			Size = Vector3.new(edge[3], 0.2, edge[4]),
			CFrame = CFrame.new(CENTER + Vector3.new(edge[1], 0.3, edge[2])),
			Color = LIME,
		}, park)
	end
	part({
		Name = "Path",
		Size = Vector3.new(8, 0.7, 120),
		CFrame = CFrame.new(CENTER + Vector3.new(0, 0, -5)),
		Color = Color3.fromRGB(75, 65, 110),
	}, park)

	-- Arco de entrada con cartel.
	for _, x in { -7, 7 } do
		neon(
			{ Name = "GatePillar", Size = Vector3.new(1.5, 12, 1.5), CFrame = CFrame.new(x, 6, 100), Color = LIME },
			park
		)
	end
	local gateSign = part({
		Name = "GateSign",
		Size = Vector3.new(16, 3, 0.8),
		CFrame = CFrame.new(0, 12.5, 100),
		Color = BG0,
	}, park)
	sign(gateSign, "ZONA 1 · EL PARQUE", LIME, Enum.NormalId.Front)
	sign(gateSign, "ZONA 1 · EL PARQUE", LIME, Enum.NormalId.Back)

	local spawnLocation = existingSpawn or Instance.new("SpawnLocation")
	spawnLocation.Name = "SpawnLocation"
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.CFrame = CFrame.new(0, 0.5, 118)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Color = LIME
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.Parent = park

	-- Árboles cartoon.
	trees = {
		Vector3.new(-45, 0, 110),
		Vector3.new(-30, 0, 140),
		Vector3.new(-50, 0, 175),
		Vector3.new(-25, 0, 205),
		Vector3.new(45, 0, 112),
		Vector3.new(32, 0, 150),
		Vector3.new(50, 0, 185),
		Vector3.new(22, 0, 212),
		Vector3.new(-8, 0, 215),
		Vector3.new(-20, 0, 100),
		Vector3.new(-55, 0, 140),
		Vector3.new(55, 0, 140),
	}
	for i, pos in trees do
		local tree = model("Tree", park)
		local cf, size = disc(pos + Vector3.new(0, 4, 0), 1.8, 8)
		local trunk = part({
			Name = "Trunk",
			Shape = Enum.PartType.Cylinder,
			CFrame = cf,
			Size = size,
			Color = Color3.fromRGB(110, 70, 50),
		}, tree)
		local leaf = if i % 3 == 0 then Color3.fromRGB(255, 120, 200) else Color3.fromRGB(40, 210, 120)
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(9, 9, 9),
			CFrame = CFrame.new(pos + Vector3.new(0, 10, 0)),
			Color = leaf,
		}, tree)
		part({
			Name = "LeavesTop",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(6, 6, 6),
			CFrame = CFrame.new(pos + Vector3.new(1, 14, -1)),
			Color = leaf,
		}, tree)
		-- Se mece desde la base del tronco.
		tree.PrimaryPart = trunk
		trunk.PivotOffset = trunk.CFrame:ToObjectSpace(CFrame.new(pos))
		tag(tree, "Sway")
	end

	-- Flores y arbustos fuera del camino.
	local flowerColors = { PINK, YELLOW, CYAN, Color3.fromRGB(255, 255, 255) }
	for i = 1, 24 do
		local x = rng:NextNumber(8, 58) * (if i % 2 == 0 then 1 else -1)
		local pos = Vector3.new(x, 0.3, rng:NextNumber(104, 222))
		local flower = model("Flower", park)
		local cf, size = disc(pos + Vector3.new(0, 0.6, 0), 0.25, 1.2)
		part({
			Name = "Stem",
			Shape = Enum.PartType.Cylinder,
			CFrame = cf,
			Size = size,
			Color = Color3.fromRGB(30, 140, 60),
		}, flower)
		part({
			Name = "Petals",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2, 1.2, 1.2),
			CFrame = CFrame.new(pos + Vector3.new(0, 1.4, 0)),
			Color = flowerColors[(i % #flowerColors) + 1],
		}, flower)
	end
	for i = 1, 8 do
		local x = rng:NextNumber(14, 60) * (if i % 2 == 0 then 1 else -1)
		local s = rng:NextNumber(3, 5)
		part({
			Name = "Bush",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(s, s, s),
			CFrame = CFrame.new(x, s * 0.3, rng:NextNumber(104, 222)),
			Color = Color3.fromRGB(35, 170, 80),
		}, park)
	end

	-- Farolas a lo largo del camino.
	for i, z in { 108, 138, 168, 198 } do
		lamp(park, Vector3.new(if i % 2 == 0 then 7 else -7, 0.3, z), 10, YELLOW, true)
	end

	-- Bancos de entrenamiento mirando al camino.
	local WOOD = Color3.fromRGB(150, 95, 55)
	local benches =
		{ Vector3.new(-12, 0, 130), Vector3.new(12, 0, 130), Vector3.new(-12, 0, 165), Vector3.new(12, 0, 165) }
	for i, pos in benches do
		local bench = model("Bench" .. i, park)
		local facing = CFrame.lookAt(pos, Vector3.new(0, 0, pos.Z))
		local seat = part({
			Name = "Seat",
			Size = Vector3.new(6, 0.6, 2.2),
			CFrame = facing * CFrame.new(0, 2, 0),
			Color = WOOD,
		}, bench)
		tag(seat, "TrainingBench")
		part(
			{ Name = "Back", Size = Vector3.new(6, 2.2, 0.4), CFrame = facing * CFrame.new(0, 3.4, 1), Color = WOOD },
			bench
		)
		for _, x in { -2.5, 2.5 } do
			part({
				Name = "Leg",
				Size = Vector3.new(0.5, 1.7, 2),
				CFrame = facing * CFrame.new(x, 0.85, 0),
				Color = METAL,
			}, bench)
		end
	end

	-- Palomas robóticas decorativas.
	local pigeons = {
		Vector3.new(-5, 0.35, 124),
		Vector3.new(4, 0.35, 133),
		Vector3.new(-16, 0.3, 150),
		Vector3.new(18, 0.3, 158),
		Vector3.new(-3, 0.35, 180),
		Vector3.new(6, 0.35, 186),
	}
	for _, pos in pigeons do
		local pigeon = model("RoboPigeon", park)
		local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		local body = part({
			Name = "Body",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 1.6, 1.6),
			CFrame = cf * CFrame.new(0, 1.1, 0),
			Color = Color3.fromRGB(150, 155, 175),
			Material = Enum.Material.Metal,
		}, pigeon)
		part({
			Name = "Head",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1),
			CFrame = cf * CFrame.new(0, 2.1, -0.6),
			Color = Color3.fromRGB(110, 115, 140),
			Material = Enum.Material.Metal,
		}, pigeon)
		part({
			Name = "Beak",
			Size = Vector3.new(0.25, 0.25, 0.5),
			CFrame = cf * CFrame.new(0, 2, -1.2),
			Color = ORANGE,
		}, pigeon)
		for _, x in { -0.32, 0.32 } do
			neon({
				Name = "Eye",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.25, 0.25, 0.25),
				CFrame = cf * CFrame.new(x, 2.25, -1),
				Color = CYAN,
			}, pigeon)
			part({
				Name = "Leg",
				Size = Vector3.new(0.12, 0.5, 0.12),
				CFrame = cf * CFrame.new(x, 0.25, 0),
				Color = ORANGE,
			}, pigeon)
		end
		neon({
			Name = "Antenna",
			Size = Vector3.new(0.1, 0.6, 0.1),
			CFrame = cf * CFrame.new(0, 2.85, -0.6),
			Color = LIME,
		}, pigeon)
		pigeon.PrimaryPart = body
		pigeon:SetAttribute("WanderRadius", 8)
		tag(pigeon, "Walker")
	end
end
task.wait()

-- PORTALES DE ZONAS FUTURAS ---------------------------------------------------
local function portal(name: string, zone: number, pos: Vector3, color: Color3, accent: Color3, label: string): Model
	local m = model(name, world)
	local facing = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)) -- mira hacia la plaza
	part({ Name = "Path", Size = Vector3.new(10, 0.6, 22), CFrame = facing * CFrame.new(0, 0.3, -11), Color = BG1 }, m)
	for _, x in { -11, 11 } do
		part({ Name = "Pillar", Size = Vector3.new(4, 24, 4), CFrame = facing * CFrame.new(x, 12, 0), Color = BG1 }, m)
		neon({
			Name = "PillarTrim",
			Size = Vector3.new(0.6, 22, 4.4),
			CFrame = facing * CFrame.new(x + (if x < 0 then 2.2 else -2.2), 12, 0),
			Color = color,
		}, m)
	end
	local beam = part({
		Name = "Beam",
		Size = Vector3.new(26, 5, 4),
		CFrame = facing * CFrame.new(0, 26.5, 0),
		Color = BG0,
	}, m)
	sign(beam, label, color, Enum.NormalId.Front)
	neon({
		Name = "BeamTrim",
		Size = Vector3.new(26.4, 0.4, 4.4),
		CFrame = facing * CFrame.new(0, 24, 0),
		Color = accent,
	}, m)
	local gate = neon({
		Name = "ZoneGate",
		Size = Vector3.new(18, 24, 1),
		CFrame = facing * CFrame.new(0, 12, 0),
		Color = color,
		Transparency = 0.45,
	}, m)
	gate:SetAttribute("Zone", zone)
	tag(gate, "ZoneGate")
	tag(gate, "NeonPulse")
	light(gate, color, 26, 1.2)
	return m
end

local asylum = portal("Zona3_CiberAsilo", 3, Vector3.new(-118, 0, 0), CYAN, LIME, "ZONA 3 · CIBER-ASILO")
for _, z in { -18, 18 } do
	-- Cápsulas criogénicas a los lados de la entrada.
	local cf, size = disc(Vector3.new(-122, 5, z), 5, 10)
	local pod = neon({
		Name = "CryoPod",
		Shape = Enum.PartType.Cylinder,
		CFrame = cf,
		Size = size,
		Color = CYAN,
		Transparency = 0.5,
	}, asylum)
	tag(pod, "NeonPulse")
	local capCf, capSize = disc(Vector3.new(-122, 10.5, z), 5.6, 1)
	part({ Name = "CryoCap", Shape = Enum.PartType.Cylinder, CFrame = capCf, Size = capSize, Color = METAL }, asylum)
end

local galaxy = portal("Zona4_GalaxiaOG", 4, Vector3.new(118, 0, 0), PINK, YELLOW, "ZONA 4 · GALAXIA OG")
for i = 0, 5 do
	local a = math.rad(i * 60)
	local star = neon({
		Name = "Star",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		CFrame = CFrame.new(118 + math.cos(a) * 4, 14 + math.sin(a) * 15, math.cos(a) * 16),
		Color = YELLOW,
	}, galaxy)
	star:SetAttribute("BobHeight", 0.6)
	tag(star, "Bob")
end
local planetModel = model("Planet", galaxy)
local planet = part({
	Name = "Planet",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(8, 8, 8),
	CFrame = CFrame.new(126, 32, -14),
	Color = Color3.fromRGB(120, 60, 200),
}, planetModel)
local ringCf, ringSize = disc(Vector3.new(126, 32, -14), 14, 0.3)
neon({
	Name = "PlanetRing",
	Shape = Enum.PartType.Cylinder,
	CFrame = ringCf * CFrame.Angles(math.rad(20), 0, 0),
	Size = ringSize,
	Color = PINK,
}, planetModel)
planetModel.PrimaryPart = planet
planetModel:SetAttribute("SpinSpeed", 20)
tag(planetModel, "Spin")

-- MARCADORES DE CARAMELOS (CandyService) ------------------------------------
-- Invisibles, a 2 studs sobre el suelo transitable de la plaza y el parque.
local candyFolder = Instance.new("Folder")
candyFolder.Name = "CandySpawns"
candyFolder.Parent = world
local function candySpawn(pos: Vector3)
	local marker = part({
		Name = "CandySpawn",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(pos),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	}, candyFolder)
	tag(marker, "CandySpawn")
end
local placed = 0
while placed < 25 do
	-- Anillo de la plaza entre la arena y las farolas, fuera del podio.
	local a = rng:NextNumber(0, math.pi * 2)
	local pos = Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(52, 82) + Vector3.new(0, 2.5, 0)
	if not (pos.X > 33 and pos.X < 67 and pos.Z > 46 and pos.Z < 64) then
		candySpawn(pos)
		placed += 1
	end
end
placed = 0
while placed < 25 do
	-- Parque, lejos de los troncos.
	local pos = Vector3.new(rng:NextNumber(-58, 58), 2.3, rng:NextNumber(104, 222))
	local clear = true
	for _, t in trees do
		if (Vector3.new(t.X, pos.Y, t.Z) - pos).Magnitude < 4 then
			clear = false
		end
	end
	if clear then
		candySpawn(pos)
		placed += 1
	end
end

-- Desplazar todo el mundo a ORIGIN y colocarlo en el Workspace.
world.WorldPivot = CFrame.new()
world:PivotTo(CFrame.new(ORIGIN))
world.Parent = workspace

-- Vista de edición nocturna (en juego la aplica AtmosphereController desde src/).
Lighting.ClockTime = 0
Lighting.Ambient = Color3.fromRGB(60, 40, 95)
Lighting.OutdoorAmbient = Color3.fromRGB(80, 60, 120)

if okRecording and recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end

local count = 0
for _, d in world:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
	end
end
return string.format("MonOGWorld construido en %s: %d partes", tostring(ORIGIN), count)
