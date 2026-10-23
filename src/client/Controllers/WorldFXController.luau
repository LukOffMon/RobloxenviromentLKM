--!strict
-- Da vida al mapa: anima en el cliente cualquier pieza etiquetada, sin scripts dentro del place.
-- Etiquetas (BasePart o Model con PrimaryPart), contrato en docs/lore/world-building.md:
--   Spin         gira sobre Y         (atributo SpinSpeed, grados/s, por defecto 45)
--   Bob          flota arriba/abajo   (BobHeight, por defecto 1; BobSpeed, por defecto 1)
--   Sway         se mece (árboles)    (SwayAngle, grados, por defecto 4)
--   NeonPulse    late de brillo       (PulseSpeed, por defecto 1.5)
--   Blink        bombillas en cadena  (BlinkIndex 1..N para el efecto persecución)
--   RainbowCycle cambia de color en bucle
--   Walker       paloma robótica que deambula (WanderRadius, por defecto 10)
-- Solo se anima lo cercano a la cámara para cuidar el rendimiento en móvil.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

type Entry = {
	Instance: Instance,
	Tag: string,
	Base: CFrame,
	BaseColor: Color3?,
	BaseTransparency: number,
	Phase: number,
	-- Estado de Walker.
	Target: Vector3?,
	Position: Vector3?,
}

local TAGS = { "Spin", "Bob", "Sway", "NeonPulse", "Blink", "RainbowCycle", "Walker" }
local MAX_DISTANCE = 220

local WorldFXController = {}

local entries: { [Instance]: { Entry } } = {}

local function getPivot(instance: Instance): CFrame?
	if instance:IsA("BasePart") then
		return instance.CFrame
	elseif instance:IsA("Model") then
		return instance:GetPivot()
	end
	return nil
end

local function setPivot(instance: Instance, cframe: CFrame)
	if instance:IsA("BasePart") then
		instance.CFrame = cframe
	elseif instance:IsA("Model") then
		instance:PivotTo(cframe)
	end
end

local function number(instance: Instance, attribute: string, default: number): number
	local value = instance:GetAttribute(attribute)
	return if type(value) == "number" then value else default
end

local function add(instance: Instance, tag: string)
	local pivot = getPivot(instance)
	if pivot == nil then
		return
	end
	local list = entries[instance]
	if list == nil then
		list = {}
		entries[instance] = list
	end
	for _, existing in list do
		if existing.Tag == tag then
			return
		end
	end
	local part = if instance:IsA("BasePart") then instance else nil
	table.insert(list, {
		Instance = instance,
		Tag = tag,
		Base = pivot,
		BaseColor = if part then part.Color else nil,
		BaseTransparency = if part then part.Transparency else 0,
		-- Desfase estable por objeto para que no se muevan todos al unísono.
		Phase = (pivot.Position.X * 0.37 + pivot.Position.Z * 0.61) % (math.pi * 2),
		Target = nil,
		Position = if tag == "Walker" then pivot.Position else nil,
	})
end

local function remove(instance: Instance, tag: string)
	local list = entries[instance]
	if list == nil then
		return
	end
	for i = #list, 1, -1 do
		if list[i].Tag == tag then
			table.remove(list, i)
		end
	end
	if #list == 0 then
		entries[instance] = nil
	end
end

-- Varias etiquetas en el mismo objeto se combinan: el movimiento se compone sobre la base.
local function animate(list: { Entry }, now: number, dt: number)
	local first = list[1]
	local instance = first.Instance
	local cframe = first.Base
	local moved = false

	for _, entry in list do
		local tag = entry.Tag
		if tag == "Walker" then
			local position = entry.Position or entry.Base.Position
			local radius = number(instance, "WanderRadius", 10)
			local target = entry.Target
			if target == nil or (target - position).Magnitude < 0.5 then
				local angle = math.random() * math.pi * 2
				local distance = math.random() * radius
				target = entry.Base.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
				entry.Target = target
			end
			local goal = target :: Vector3
			local step = (goal - position)
			local stepLength = math.min(step.Magnitude, 4 * dt)
			if step.Magnitude > 0 then
				position += step.Unit * stepLength
			end
			entry.Position = position
			-- Pasitos: pequeño rebote y mirar hacia donde camina.
			local hop = math.abs(math.sin(now * 10 + entry.Phase)) * 0.25
			local look = if step.Magnitude > 0.01 then step.Unit else entry.Base.LookVector
			cframe = CFrame.lookAt(position, position + Vector3.new(look.X, 0, look.Z)) + Vector3.new(0, hop, 0)
			moved = true
		elseif tag == "Spin" then
			local speed = math.rad(number(instance, "SpinSpeed", 45))
			cframe *= CFrame.Angles(0, (now * speed + entry.Phase) % (math.pi * 2), 0)
			moved = true
		elseif tag == "Bob" then
			local height = number(instance, "BobHeight", 1)
			local speed = number(instance, "BobSpeed", 1)
			cframe += Vector3.new(0, math.sin(now * speed * 2 + entry.Phase) * height, 0)
			moved = true
		elseif tag == "Sway" then
			local angle = math.rad(number(instance, "SwayAngle", 4))
			cframe *= CFrame.Angles(
				math.sin(now * 0.8 + entry.Phase) * angle,
				0,
				math.cos(now * 0.6 + entry.Phase) * angle * 0.6
			)
			moved = true
		elseif instance:IsA("BasePart") then
			if tag == "NeonPulse" then
				local speed = number(instance, "PulseSpeed", 1.5)
				local wave = (math.sin(now * speed * 2 + entry.Phase) + 1) / 2
				instance.Transparency = entry.BaseTransparency + wave * 0.35
			elseif tag == "Blink" then
				local index = number(instance, "BlinkIndex", 1)
				local lit = math.floor(now * 8 - index) % 4 ~= 0
				instance.Transparency = if lit then entry.BaseTransparency else 0.85
			elseif tag == "RainbowCycle" then
				instance.Color = Color3.fromHSV((now * 0.15 + entry.Phase / (math.pi * 2)) % 1, 0.85, 1)
			end
		end
	end

	if moved then
		setPivot(instance, cframe)
	end
end

-- Texto flotante en el mundo ("+12 💰") que sube y se desvanece.
function WorldFXController.popAt(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(color)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.4, 0)
	sparkles.Speed = NumberRange.new(6, 10)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Lifetime = NumberRange.new(0.4, 0.7)
	sparkles.Rate = 0
	sparkles.Parent = anchor
	anchor.Parent = workspace
	sparkles:Emit(24)
	local start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		anchor.CFrame = CFrame.new(position + Vector3.new(0, t * 4, 0))
		label.TextTransparency = math.clamp((t - 0.6) / 0.6, 0, 1)
		label.TextStrokeTransparency = 0.2 + label.TextTransparency * 0.8
		if t > 1.2 then
			connection:Disconnect()
		end
	end)
	Debris:AddItem(anchor, 1.4)
end

function WorldFXController.start()
	for _, tag in TAGS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			add(instance, tag)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			remove(instance, tag)
		end)
		for _, instance in CollectionService:GetTagged(tag) do
			add(instance, tag)
		end
	end

	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local origin = camera.CFrame.Position
		local now = os.clock()
		for instance, list in entries do
			if instance.Parent == nil then
				entries[instance] = nil
				continue
			end
			if (list[1].Base.Position - origin).Magnitude <= MAX_DISTANCE then
				animate(list, now, dt)
			end
		end
	end)
end

return WorldFXController
