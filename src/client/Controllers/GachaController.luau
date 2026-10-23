--!strict
-- Edificio de Adopción: tienda de Cajas de Asilo y la cinemática de apertura
-- (¡TOC, TOC, TOC! -> la puerta brilla del color de la rareza -> sale volando -> confeti y anuncio).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Configurations.GameConfig)
local OGCatalog = require(ReplicatedStorage.Shared.Configurations.OGCatalog)

local AtmosphereController = require(script.Parent.AtmosphereController)
local HUDController = require(script.Parent.HUDController)
local Net = require(script.Parent.Net)
local OGVisuals = require(script.Parent.Parent.UI.OGVisuals)
local Panel = require(script.Parent.Parent.UI.Components.Panel)
local Sounds = require(script.Parent.Parent.UI.Sounds)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local C = Theme.Colors
local player = Players.LocalPlayer

local GachaController = {}

local panel: Panel.Panel
local pityLabel: TextLabel
local boxButtons: { [string]: TextButton } = {}
local robuxHolder: Frame
local overlay: Frame
local playing = false
local queue: { { any } } = {}

local function boxCard(parent: Instance, order: number, title: string, subtitle: string, color: Color3, mode: string)
	local card = Theme.create("Frame", {
		BackgroundColor3 = C.PanelLight,
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(16), Theme.stroke(color, 3) })
	Theme.label("🚪", 40, color, { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 44), Parent = card })
	Theme.label(
		title,
		18,
		C.White,
		{ Position = UDim2.fromOffset(4, 52), Size = UDim2.new(1, -8, 0, 22), Parent = card }
	)
	local button = Theme.button(subtitle, color, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 40),
		TextSize = 18,
		Parent = card,
	})
	button.Activated:Connect(function()
		if button.Active then
			Sounds.play("Click")
			Net.get("OpenBox"):Fire(mode)
		end
	end)
	boxButtons[mode] = button
end

local function buildPanel(gui: ScreenGui)
	panel = Panel.new(gui, "🚪 Edificio de Adopción", C.Pink)
	local content = panel.Content

	pityLabel = Theme.label("", 16, C.Lime, {
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = content,
	})

	local scroller = Theme.create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 1, -26),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local boxes = Theme.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = scroller,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(160, 140),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local cfg = GameConfig.Gacha
	boxCard(boxes, 1, "Caja de Asilo", string.format("%d 💰", cfg.CoinBoxCost), C.Amber, "Coin")
	boxCard(boxes, 2, "Caja de Asilo x5", string.format("%d 💰", cfg.CoinBox5Cost), C.Gold, "Coin5")
	boxCard(boxes, 3, "Caja de Gemas (Raro+)", string.format("%d 💎", cfg.GemBoxCost), C.Cyan, "Gem")
	boxCard(boxes, 4, "Ticket gratis", "Usar 🎟", C.Lime, "Ticket")
	boxCard(boxes, 5, "Ticket Épico", "Usar ⭐", Theme.rarityColor("Epic"), "EpicTicket")

	robuxHolder = Theme.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = scroller,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(240, 48),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Probabilidades publicadas siempre antes de abrir (requisito de Roblox para cajas aleatorias).
	local odds = Theme.create("Frame", {
		BackgroundColor3 = C.Night,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = scroller,
	}, {
		Theme.corner(12),
		Theme.padding(10),
		Theme.create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Theme.label(
		"Probabilidades por caja",
		18,
		C.White,
		{ LayoutOrder = 0, TextXAlignment = Enum.TextXAlignment.Left, Parent = odds }
	)
	for _, rarity in OGCatalog.Rarities do
		local names = {}
		for _, archetype in OGCatalog.ArchetypesByRarity[rarity.Id] do
			table.insert(names, archetype.DisplayName)
		end
		Theme.label(
			string.format(
				"%s — %s%%  ·  %s",
				rarity.DisplayName,
				string.format("%g", rarity.Chance * 100),
				table.concat(names, ", ")
			),
			15,
			Color3.fromHex(rarity.Color),
			{
				LayoutOrder = rarity.Order,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 34),
				Parent = odds,
			}
		)
	end
	Theme.label(
		string.format("Shiny / Edición Dorada: %g%% (solo estética)", cfg.ShinyChance * 100),
		15,
		C.Gold,
		{ LayoutOrder = 99, TextXAlignment = Enum.TextXAlignment.Left, Parent = odds }
	)
end

local function rebuildRobuxButtons()
	for _, child in robuxHolder:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	local profile = State.Profile
	if profile == nil then
		return
	end
	local order = 0
	local function addProduct(key: string, label: string, random: boolean)
		local product = (GameConfig.Products :: any)[key]
		if product.Id <= 0 or (random and not profile.PaidRandomAllowed) then
			return
		end
		order += 1
		local button = Theme.button(string.format("%s  ·  R$ %d", label, product.Price), C.Lime, {
			LayoutOrder = order,
			TextSize = 17,
			Parent = robuxHolder,
		})
		button.Activated:Connect(function()
			MarketplaceService:PromptProductPurchase(player, product.Id)
		end)
	end
	if not profile.StarterPackBought then
		addProduct("StarterBox", "⭐ Caja de Inicio (Épico+)", true)
	end
	addProduct("AsylumBox1", "Caja de Asilo x1", true)
	addProduct("AsylumBox5", "Caja de Asilo x5", true)
	addProduct("AsylumBox10", "Caja de Asilo x10", true)
	addProduct("ExpressoDoble", "☕ Expreso Doble (x3 XP 30 min)", false)

	for key, pass in GameConfig.GamePasses :: any do
		if pass.Id > 0 and not (profile.Passes and profile.Passes[key]) then
			order += 1
			local names = {
				AutoTrainer = "🤖 Enfermero Automático",
				OfflinePension = "🌙 Pensión Offline 24 h",
				VipDirector = "👑 VIP Director del Asilo",
				QuantumAura = "🌈 Aura Abuelo Cuántico",
			}
			local button = Theme.button(string.format("%s  ·  R$ %d", names[key] or key, pass.Price), C.Gold, {
				LayoutOrder = order,
				TextSize = 17,
				Parent = robuxHolder,
			})
			button.Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
		end
	end
end

local function refresh()
	local profile = State.Profile
	if profile == nil then
		return
	end
	pityLabel.Text = string.format(
		"Contador de piedad: %d / %d — a los %d intentos sin Transcendente, ¡te lo garantizamos!",
		profile.Pity,
		profile.PityLimit,
		profile.PityLimit
	)
	local cfg = GameConfig.Gacha
	Theme.setEnabled(boxButtons.Coin, profile.PensionCoins >= cfg.CoinBoxCost)
	Theme.setEnabled(boxButtons.Coin5, profile.PensionCoins >= cfg.CoinBox5Cost)
	Theme.setEnabled(boxButtons.Gem, profile.GigaGems >= cfg.GemBoxCost)
	Theme.setEnabled(boxButtons.Ticket, profile.Tickets > 0)
	Theme.setEnabled(boxButtons.EpicTicket, profile.EpicTickets > 0)
	boxButtons.Ticket.Text = string.format("Usar 🎟 (%d)", profile.Tickets)
	boxButtons.EpicTicket.Text = string.format("Usar ⭐ (%d)", profile.EpicTickets)
end

-- Cinemática -----------------------------------------------------------------------

local function shake(frame: GuiObject, strength: number, duration: number)
	local origin = frame.Position
	local start = os.clock()
	while os.clock() - start < duration do
		frame.Position = origin + UDim2.fromOffset(math.random(-strength, strength), math.random(-strength, strength))
		task.wait(1 / 60)
	end
	frame.Position = origin
end

local function popText(parent: Instance, text: string, color: Color3, size: number, position: UDim2)
	local label = Theme.label(text, size, color, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(600, size + 10),
		ZIndex = 60,
		Parent = parent,
	})
	Theme.squish(label, 0.6)
	return label
end

local function confetti(parent: Instance, color: Color3)
	local palette = { color, C.Gold, C.Pink, C.Cyan, C.Lime, C.White }
	for _ = 1, 46 do
		local piece = Theme.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromOffset(math.random(8, 16), math.random(10, 22)),
			BackgroundColor3 = palette[math.random(1, #palette)],
			Rotation = math.random(0, 360),
			ZIndex = 58,
			Parent = parent,
		})
		local angle = math.random() * math.pi * 2
		local distance = 0.25 + math.random() * 0.35
		Theme.tween(piece, 1.4 + math.random() * 0.6, {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * distance, 0.48 + math.sin(angle) * distance + 0.25),
			Rotation = piece.Rotation + math.random(-540, 540),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Quart)
		task.delay(2.2, function()
			piece:Destroy()
		end)
	end
end

local function playOne(result: any, fast: boolean)
	local rarity = OGCatalog.getRarity(result.Rarity)
	local archetype = OGCatalog.getArchetype(result.ArchetypeId)
	if rarity == nil or archetype == nil then
		return
	end
	local color = Color3.fromHex(rarity.Color)
	for _, child in overlay:GetChildren() do
		if not child:IsA("UIGradient") then
			child:Destroy()
		end
	end

	-- 1. Anticipación: zoom rápido a la puerta y tres toques.
	local glow = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(300, 400),
		BackgroundColor3 = color,
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = overlay,
	}, { Theme.corner(30) })
	local door = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(240, 340),
		BackgroundColor3 = Color3.fromRGB(110, 62, 32),
		ZIndex = 52,
		Parent = overlay,
	}, {
		Theme.corner(10),
		Theme.stroke(Color3.fromRGB(60, 30, 12), 6),
		Theme.create("UIScale", { Scale = 0.3 }),
	})
	for row = 0, 1 do
		Theme.create("Frame", {
			Position = UDim2.fromScale(0.12, 0.08 + row * 0.46),
			Size = UDim2.fromScale(0.76, 0.38),
			BackgroundColor3 = Color3.fromRGB(140, 82, 44),
			ZIndex = 53,
			Parent = door,
		}, { Theme.corner(8) })
	end
	Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.84, 0.52),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = C.Gold,
		ZIndex = 54,
		Parent = door,
	}, { Theme.corner(9) })
	Theme.label("ASILO", 26, C.Pink, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.fromOffset(240, 30),
		ZIndex = 54,
		Parent = door,
	})
	local doorScale = door:FindFirstChildOfClass("UIScale") :: UIScale
	Theme.tween(doorScale, if fast then 0.15 else 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.wait(if fast then 0.2 else 0.45)

	local knocks = if fast then 1 else 3
	for i = 1, knocks do
		Sounds.play("Knock", 0.45 + i * 0.05)
		local toc = popText(overlay, "¡TOC!", C.White, 44, UDim2.fromScale(0.5 + (i - 2) * 0.16, 0.18))
		Theme.squish(door, 0.08)
		shake(door, 6, 0.12)
		task.delay(0.5, function()
			toc:Destroy()
		end)
		task.wait(if fast then 0.15 else 0.4)
	end

	-- 2. Revelación: la luz de la rareza sale por las rendijas.
	Theme.tween(glow, if fast then 0.2 else 0.6, { BackgroundTransparency = 0.15, Size = UDim2.fromOffset(330, 430) })
	Theme.tween(door:FindFirstChildOfClass("UIStroke") :: UIStroke, 0.4, { Color = color })
	if rarity.Order >= 4 and not fast then
		shake(door, 10, 0.6)
	else
		task.wait(if fast then 0.15 else 0.4)
	end

	-- 3. Explosión: la puerta sale volando y aparece el OG.
	Theme.tween(door, 0.5, {
		Position = UDim2.fromScale(1.4, -0.4),
		Rotation = 220,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Theme.tween(glow, 0.8, { BackgroundTransparency = 1, Size = UDim2.fromOffset(900, 900) })
	confetti(overlay, color)
	Sounds.play("Reward", 0.8 + rarity.Order * 0.08)
	AtmosphereController.flash(color, 0.4 + rarity.Order * 0.25)
	AtmosphereController.punch(4 + rarity.Order * 2)

	-- Rayos de luz del color de la rareza girando detrás del OG.
	local rays = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ZIndex = 54,
		Parent = overlay,
	})
	for i = 0, 7 do
		Theme.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(900, 46),
			Rotation = i * 22.5,
			BackgroundColor3 = color,
			BackgroundTransparency = if rarity.Order >= 4 then 0.55 else 0.75,
			BorderSizePixel = 0,
			ZIndex = 54,
			Parent = rays,
		}, {
			Theme.create("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	TweenService
		:Create(rays, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
		:Play()

	local visual = OGVisuals.get(archetype.Id)
	local card = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 300),
		BackgroundColor3 = C.Panel,
		ZIndex = 55,
		Parent = overlay,
	}, { Theme.corner(24), Theme.stroke(color, 5) })
	Theme.label(
		visual.Icon,
		110,
		C.White,
		{ Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 120), ZIndex = 56, Parent = card }
	)
	Theme.label(
		archetype.DisplayName,
		24,
		C.White,
		{ Position = UDim2.fromOffset(10, 136), Size = UDim2.new(1, -20, 0, 58), ZIndex = 56, Parent = card }
	)
	Theme.label(
		rarity.DisplayName:upper(),
		26,
		color,
		{ Position = UDim2.fromOffset(0, 196), Size = UDim2.new(1, 0, 0, 30), ZIndex = 56, Parent = card }
	)
	if result.Shiny then
		Theme.label(
			"✨ EDICIÓN DORADA ✨",
			22,
			C.Gold,
			{ Position = UDim2.fromOffset(0, 228), Size = UDim2.new(1, 0, 0, 26), ZIndex = 56, Parent = card }
		)
	end
	Theme.label(
		archetype.Special.Name,
		16,
		C.Muted,
		{ Position = UDim2.fromOffset(0, 262), Size = UDim2.new(1, 0, 0, 22), ZIndex = 56, Parent = card }
	)
	Theme.squish(card, 0.5)

	local headline = if result.PityTriggered
		then "¡CONTADOR DE PIEDAD! ¡ABUELO TRANSCENDENTE CONSEGUIDO!"
		else string.format("¡ABUELO %s CONSEGUIDO!", rarity.DisplayName:upper())
	popText(overlay, headline, color, if fast then 30 else 38, UDim2.fromScale(0.5, 0.12))
	task.wait(if fast then 0.9 else 1.6)
end

local function playQueue()
	if playing then
		return
	end
	playing = true
	panel:Close()
	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	Theme.tween(overlay, 0.25, { BackgroundTransparency = 0.15 })
	while #queue > 0 do
		local results = table.remove(queue, 1) :: { any }
		local fast = #results > 1
		for _, result in results do
			playOne(result, fast)
		end
	end
	local continueButton = Theme.button("¡A presumir! ▶", C.Lime, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.95),
		Size = UDim2.fromOffset(240, 56),
		ZIndex = 60,
		Parent = overlay,
	})
	continueButton.Activated:Wait()
	Sounds.play("Click")
	overlay.Visible = false
	playing = false
end

function GachaController.start(gui: ScreenGui)
	buildPanel(gui)
	overlay = Theme.create("Frame", {
		Name = "GachaCinematic",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Night,
		Visible = false,
		ZIndex = 50,
		Active = true,
		Parent = gui,
	}, {
		Theme.create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(C.Cyber, C.Night),
		}),
	})

	Net.get("GachaResult"):Connect(function(results: any)
		if type(results) ~= "table" or #results == 0 then
			return
		end
		table.insert(queue, results)
		task.spawn(playQueue)
	end)

	State.Changed:Connect(function(kind)
		refresh()
		if kind == "Full" then
			rebuildRobuxButtons()
		end
	end)
	HUDController.bind("Gacha", GachaController.open)
end

function GachaController.open()
	refresh()
	panel:Open()
end

return GachaController
