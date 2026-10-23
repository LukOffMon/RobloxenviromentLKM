--!strict
-- HUD principal: barra superior de recursos, botones de acción (pensados para el pulgar) y avisos.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Sounds = require(script.Parent.Parent.UI.Sounds)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local C = Theme.Colors

local HUDController = {}

HUDController.Gui = nil :: ScreenGui?

local actions: { [string]: () -> () } = {}
local valueLabels: { [string]: TextLabel } = {}
local lastValues: { [string]: number } = {}
local freeBadge: TextLabel? = nil
local bingoBadge: TextLabel? = nil
local rateLabel: TextLabel? = nil
local boostLabel: TextLabel? = nil
local memoryLabel: TextLabel? = nil
local toastHolder: Frame? = nil

local function pill(parent: Instance, key: string, icon: string, color: Color3, order: number): TextLabel
	local frame = Theme.create("Frame", {
		Name = key,
		BackgroundColor3 = C.Panel,
		Size = UDim2.fromOffset(150, 44),
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(22), Theme.stroke(color, 3) })
	local iconLabel = Theme.label(icon, 26, color, {
		Size = UDim2.fromOffset(40, 44),
		Position = UDim2.fromOffset(4, 0),
		Parent = frame,
	})
	if key == "GigaGems" then
		-- Icono rotatorio brillante.
		task.spawn(function()
			while iconLabel.Parent do
				iconLabel.Rotation = math.sin(os.clock() * 2) * 14
				task.wait(1 / 30)
			end
		end)
	end
	local value = Theme.label("0", 24, C.White, {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.fromOffset(44, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	valueLabels[key] = value
	return value
end

local function actionButton(parent: Instance, key: string, text: string, color: Color3, order: number): TextButton
	local button = Theme.button(text, color, {
		Name = key,
		Size = UDim2.fromOffset(150, 54),
		TextSize = 20,
		LayoutOrder = order,
		Parent = parent,
	})
	button.Activated:Connect(function()
		Sounds.play("Click")
		local callback = actions[key]
		if callback then
			callback()
		end
	end)
	return button
end

local function badge(parent: GuiObject, text: string, color: Color3): TextLabel
	local label = Theme.label(text, 16, C.White, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 6, 0.5, 0),
		Size = UDim2.fromOffset(96, 28),
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		Visible = false,
		ZIndex = 5,
		Parent = parent,
	})
	Theme.corner(10).Parent = label
	return label
end

function HUDController.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	local gui = Theme.create("ScreenGui", {
		Name = "MonOGHud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	HUDController.Gui = gui

	-- Barra superior (Top HUD)
	local top = Theme.create("Frame", {
		Name = "TopBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(640, 44),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	pill(top, "PensionCoins", "💰", C.Gold, 1)
	pill(top, "GigaGems", "💎", C.Cyan, 2)
	pill(top, "Tickets", "🎟", C.Pink, 3)

	rateLabel = Theme.label("", 16, C.Lime, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.fromOffset(420, 20),
		Parent = gui,
	})
	boostLabel = Theme.label("", 16, C.Amber, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 76),
		Size = UDim2.fromOffset(420, 20),
		Parent = gui,
	})
	memoryLabel = Theme.label("Modo prueba de Studio: tus datos no se guardan", 14, C.Red, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(420, 18),
		Visible = false,
		Parent = gui,
	})

	-- Columna de acciones a la izquierda, a media altura (lejos del joystick y del botón de salto).
	local left = Theme.create("Frame", {
		Name = "Actions",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.45, 0),
		Size = UDim2.fromOffset(150, 330),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local asylum = actionButton(left, "Gacha", "🚪 Asilo", C.Pink, 1)
	actionButton(left, "Inventory", "🎒 Mis OGs", C.Amber, 2)
	actionButton(left, "Training", "🦵 Entrenar", C.Cyan, 3)
	actionButton(left, "Battle", "⚔️ Combatir", C.Red, 4)
	local bingo = actionButton(left, "Daily", "🔥 Bingo", C.Lime, 5)
	freeBadge = badge(asylum, "¡GRATIS!", C.Lime)
	bingoBadge = badge(bingo, "¡Listo!", C.Amber)

	toastHolder = Theme.create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100),
		-- Por encima de paneles (20) y pantallas completas (50-86).
		ZIndex = 100,
		Size = UDim2.fromOffset(460, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.create("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Insignias que laten para llamar la atención.
	RunService.RenderStepped:Connect(function()
		local pulse = 1 + math.sin(os.clock() * 6) * 0.08
		for _, label in { freeBadge, bingoBadge } do
			if label and label.Visible then
				label.Size = UDim2.fromOffset(96 * pulse, 28 * pulse)
			end
		end
		local profile = State.Profile
		if profile and boostLabel then
			local remaining = (profile.XpBoostUntil or 0) - os.time()
			boostLabel.Text = if remaining > 0
				then string.format("☕ Expreso Doble x3 XP: %d:%02d", remaining // 60, remaining % 60)
				else ""
		end
	end)

	State.Changed:Connect(HUDController.render)
end

function HUDController.bind(action: string, callback: () -> ())
	actions[action] = callback
end

function HUDController.render()
	local profile = State.Profile
	if profile == nil then
		return
	end
	for key, label in valueLabels do
		local value = profile[key] or 0
		label.Text = Theme.formatNumber(value)
		local previous = lastValues[key]
		if previous and value > previous and label.Parent then
			-- El contador "salta" cada vez que entra dinero.
			Theme.squish(label.Parent :: GuiObject, 0.12)
		end
		lastValues[key] = value
	end
	if freeBadge then
		freeBadge.Visible = (profile.Tickets or 0) + (profile.EpicTickets or 0) > 0
	end
	if bingoBadge then
		bingoBadge.Visible = profile.CanClaimDaily == true
	end
	if rateLabel and profile.PensionRate then
		local friends = profile.FriendMultiplier or 1
		rateLabel.Text = string.format(
			"Pensión: +%s 💰/s%s",
			Theme.formatNumber(profile.PensionRate),
			if friends > 1 then string.format("  (👥 x%.2f por amigos)", friends) else ""
		)
	end
	if memoryLabel then
		memoryLabel.Visible = profile.MemoryOnly == true
	end
end

function HUDController.toast(text: string, kind: string?)
	local holder = toastHolder
	if holder == nil then
		return
	end
	local color = if kind == "Error" then C.Red elseif kind == "Reward" then C.Lime else C.Cyan
	local label = Theme.label(text, 20, C.White, {
		Size = UDim2.fromOffset(460, 40),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = C.Panel,
		ZIndex = 100,
		Parent = holder,
	})
	Theme.corner(12).Parent = label
	Theme.stroke(color, 3).Parent = label
	Theme.squish(label, 0.2)
	if kind == "Reward" then
		Sounds.play("Reward")
	end
	task.delay(3.2, function()
		Theme.tween(label, 0.3, { TextTransparency = 1, BackgroundTransparency = 1 })
		task.wait(0.3)
		label:Destroy()
	end)
end

return HUDController
