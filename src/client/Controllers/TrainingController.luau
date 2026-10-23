--!strict
-- Minijuego "Chanclazo Timing": las chanclas cruzan la pista y hay que pulsar cuando tocan la línea.
-- El compás lo marca el reloj del servidor (workspace:GetServerTimeNow); el servidor juzga cada toque.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local OGCatalog = require(ReplicatedStorage.Shared.Configurations.OGCatalog)

local HUDController = require(script.Parent.HUDController)
local Net = require(script.Parent.Net)
local OGVisuals = require(script.Parent.Parent.UI.OGVisuals)
local Panel = require(script.Parent.Parent.UI.Components.Panel)
local Sounds = require(script.Parent.Parent.UI.Sounds)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local C = Theme.Colors
local ACTION = "MonOGChanclazo"
-- Segundos que tarda una chancla en cruzar la pista.
local TRAVEL_SECONDS = 1.6

local TrainingController = {}

local overlay: Frame
local lane: Frame
local title: TextLabel
local countLabel: TextLabel
local tapButton: TextButton
local session: any = nil
local notes: { [number]: TextLabel? } = {}
local stepConnection: RBXScriptConnection? = nil
local lastClickBeat = 0

local function judgementText(judgement: string): (string, Color3)
	if judgement == "Perfect" then
		return "¡PERFECTO!", C.Lime
	elseif judgement == "Good" then
		return "¡Bien!", C.Cyan
	end
	return "Fallo", C.Red
end

local function tap()
	if session == nil then
		return
	end
	Theme.squish(tapButton, 0.2)
	Net.get("TrainingTap"):Fire()
end

local function stop()
	session = nil
	if stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
	ContextActionService:UnbindAction(ACTION)
	for _, note in notes do
		if note then
			note:Destroy()
		end
	end
	table.clear(notes)
end

local function onStep()
	if session == nil then
		return
	end
	local now = workspace:GetServerTimeNow()
	local width = lane.AbsoluteSize.X
	for index = 1, session.Beats do
		local beatTime = session.StartTime + (index - 1) * session.Interval
		local remaining = beatTime - now
		local note = notes[index]
		if remaining <= TRAVEL_SECONDS and remaining > -0.3 then
			local shown: TextLabel = note
				or Theme.label("🩴", 38, C.White, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(48, 48),
					ZIndex = 43,
					Parent = lane,
				})
			notes[index] = shown
			-- La línea de golpe está al 12 % del ancho.
			local x = 0.12 * width + (remaining / TRAVEL_SECONDS) * 0.85 * width
			shown.Position = UDim2.new(0, x, 0.5, 0)
		elseif note and remaining <= -0.3 then
			note:Destroy()
			notes[index] = nil
		end
		-- Metrónomo local en cada beat.
		if remaining <= 0 and index > lastClickBeat then
			lastClickBeat = index
			Sounds.play("Click", 1.4)
		end
	end
	local untilStart = session.StartTime - now
	countLabel.Text = if untilStart > 0 then string.format("¡Prepárate! %d", math.ceil(untilStart)) else ""
end

local function buildOverlay(gui: ScreenGui)
	overlay = Theme.create("Frame", {
		Name = "Training",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.new(0.9, 0, 0, 230),
		BackgroundColor3 = C.Panel,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	}, {
		Theme.corner(20),
		Theme.stroke(C.Cyan, 4),
		Theme.create("UISizeConstraint", { MaxSize = Vector2.new(900, 230) }),
	})
	title = Theme.label("", 22, C.Cyan, {
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -32, 0, 28),
		ZIndex = 41,
		Parent = overlay,
	})
	countLabel = Theme.label("", 26, C.Gold, {
		Position = UDim2.fromOffset(16, 36),
		Size = UDim2.new(1, -32, 0, 30),
		ZIndex = 41,
		Parent = overlay,
	})
	lane = Theme.create("Frame", {
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(1, -200, 0, 70),
		BackgroundColor3 = C.Night,
		ClipsDescendants = true,
		ZIndex = 41,
		Parent = overlay,
	}, { Theme.corner(12) })
	Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.12, 0),
		Size = UDim2.new(0, 6, 1, 0),
		BackgroundColor3 = C.Lime,
		ZIndex = 42,
		Parent = lane,
	})
	tapButton = Theme.button("🦵\nCHANCLAZO", C.Pink, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 60),
		Size = UDim2.fromOffset(160, 150),
		TextSize = 22,
		ZIndex = 42,
		Parent = overlay,
	})
	tapButton.Activated:Connect(tap)
	Theme.label("Pulsa cuando la chancla toque la línea verde (Espacio, E o el botón)", 15, C.Muted, {
		Position = UDim2.fromOffset(16, 152),
		Size = UDim2.new(1, -200, 0, 40),
		ZIndex = 41,
		Parent = overlay,
	})
end

local function popJudgement(text: string, color: Color3)
	local label = Theme.label(text, 34, color, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.12, 0, 0, -10),
		Size = UDim2.fromOffset(220, 40),
		ZIndex = 44,
		Parent = lane,
	})
	Theme.squish(label, 0.5)
	Theme.tween(label, 0.6, { Position = UDim2.new(0.12, 0, 0, -40), TextTransparency = 1 })
	task.delay(0.6, function()
		label:Destroy()
	end)
end

function TrainingController.start(gui: ScreenGui)
	buildOverlay(gui)

	Net.get("TrainingStarted"):Connect(function(view: any)
		stop()
		Panel.closeAll()
		session = view
		lastClickBeat = 0
		local og = State.Profile and State.Profile.OGs[view.Uid]
		local archetype = og and OGCatalog.getArchetype(og.Id)
		title.Text = if archetype
			then string.format(
				"%s Gimnasio del Asilo — entrenando a %s",
				OGVisuals.get(archetype.Id).Icon,
				archetype.DisplayName
			)
			else "Gimnasio del Asilo"
		overlay.Visible = true
		Theme.squish(overlay, 0.1)
		ContextActionService:BindActionAtPriority(ACTION, function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				tap()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.E, Enum.KeyCode.ButtonA)
		stepConnection = RunService.RenderStepped:Connect(onStep)
	end)

	Net.get("TrainingJudged"):Connect(function(judgement: any)
		local text, color = judgementText(judgement)
		popJudgement(text, color)
		if judgement ~= "Miss" then
			Sounds.play("Hit", if judgement == "Perfect" then 1.3 else 1)
		end
	end)

	Net.get("TrainingResult"):Connect(function(result: any)
		stop()
		overlay.Visible = false
		HUDController.toast(
			string.format(
				"Entrenamiento: %d perfectos, %d bien → +%d XP 💪",
				result.Perfect,
				result.Good,
				result.Xp
			),
			"Reward"
		)
	end)

	HUDController.bind("Training", function()
		local profile = State.Profile
		local uid = profile and profile.Equipped[1]
		if uid then
			TrainingController.train(uid)
		else
			HUDController.toast("Primero consigue un OG en el Asilo 🚪", "Error")
		end
	end)
end

function TrainingController.train(uid: string)
	if session ~= nil then
		return
	end
	Net.get("StartTraining"):Fire(uid)
end

return TrainingController
