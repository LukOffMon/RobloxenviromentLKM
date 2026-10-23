--!strict
-- Arena Central: reproduce el registro de combate que calculó el servidor.
-- "Turn-Based Comedy": golpes con temblor, números elásticos y K.O. que salen volando.

local HUDController = require(script.Parent.HUDController)
local Net = require(script.Parent.Net)
local OGVisuals = require(script.Parent.Parent.UI.OGVisuals)
local Panel = require(script.Parent.Parent.UI.Components.Panel)
local Sounds = require(script.Parent.Parent.UI.Sounds)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local C = Theme.Colors

local BattleController = {}

local panel: Panel.Panel
local tierLabel: TextLabel
local fightButton: TextButton
local overlay: Frame
local speed = 1
local skipping = false
local busy = false

type Card = { Frame: Frame, Bar: Frame, HPLabel: TextLabel, MaxHP: number }

local function wait(seconds: number)
	if not skipping then
		task.wait(seconds / speed)
	end
end

local function makeCard(parent: Frame, fighter: any, index: number, count: number, enemy: boolean): Card
	local color = Theme.rarityColor(fighter.Rarity)
	local frame = Theme.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(index / (count + 1), 0.5),
		Size = UDim2.fromOffset(150, 170),
		BackgroundColor3 = if enemy then C.Cyber else C.PanelLight,
		ZIndex = 72,
		Parent = parent,
	}, { Theme.corner(16), Theme.stroke(color, 4) })
	Theme.label(OGVisuals.get(fighter.ArchetypeId).Icon, 54, C.White, {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 60),
		ZIndex = 73,
		Parent = frame,
	})
	Theme.label(fighter.Name, 14, C.White, {
		Position = UDim2.fromOffset(6, 68),
		Size = UDim2.new(1, -12, 0, 36),
		ZIndex = 73,
		Parent = frame,
	})
	Theme.label(string.format("Nv %d%s", fighter.Level, if fighter.Shiny then " ✨" else ""), 14, color, {
		Position = UDim2.fromOffset(0, 104),
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 73,
		Parent = frame,
	})
	local back = Theme.create("Frame", {
		Position = UDim2.fromOffset(10, 128),
		Size = UDim2.new(1, -20, 0, 14),
		BackgroundColor3 = C.Night,
		ZIndex = 73,
		Parent = frame,
	}, { Theme.corner(7) })
	local bar = Theme.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Lime,
		ZIndex = 74,
		Parent = back,
	}, { Theme.corner(7) })
	local hpLabel = Theme.label(string.format("%d / %d", fighter.MaxHP, fighter.MaxHP), 13, C.White, {
		Position = UDim2.fromOffset(0, 144),
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 73,
		Parent = frame,
	})
	return { Frame = frame, Bar = bar, HPLabel = hpLabel, MaxHP = fighter.MaxHP }
end

local function floatText(parent: Frame, text: string, color: Color3, size: number)
	local label = Theme.label(text, size, color, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(200, size + 8),
		ZIndex = 80,
		Parent = parent,
	})
	Theme.squish(label, 0.7)
	Theme.tween(
		label,
		0.9 / speed,
		{ Position = UDim2.fromScale(0.5, -0.25), TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	task.delay(1, function()
		label:Destroy()
	end)
end

local function shake(frame: GuiObject, strength: number, duration: number)
	local origin = frame.Position
	local start = os.clock()
	while os.clock() - start < duration / speed do
		frame.Position = origin + UDim2.fromOffset(math.random(-strength, strength), math.random(-strength, strength))
		task.wait(1 / 60)
	end
	frame.Position = origin
end

local function banner(text: string, color: Color3)
	local label = Theme.label(text, 40, color, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(700, 50),
		ZIndex = 85,
		Parent = overlay,
	})
	Theme.squish(label, 0.6)
	task.delay(0.9 / speed, function()
		Theme.tween(label, 0.2, { TextTransparency = 1, TextStrokeTransparency = 1 })
		task.wait(0.2)
		label:Destroy()
	end)
end

local function play(view: any)
	busy = true
	skipping = false
	panel:Close()
	for _, child in overlay:GetChildren() do
		if not child:IsA("UIGradient") and not child:IsA("UICorner") then
			child:Destroy()
		end
	end
	overlay.Visible = true

	Theme.label(string.format("⚔️ Arena Central — Rival nivel %d", view.Tier), 24, C.Gold, {
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 71,
		Parent = overlay,
	})
	local enemyRow = Theme.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.1),
		Size = UDim2.fromScale(1, 0.36),
		ZIndex = 71,
		Parent = overlay,
	})
	local allyRow = Theme.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.52),
		Size = UDim2.fromScale(1, 0.36),
		ZIndex = 71,
		Parent = overlay,
	})

	local speedButton = Theme.button("⏩ x1", C.Cyan, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -150, 1, -12),
		Size = UDim2.fromOffset(120, 44),
		TextSize = 18,
		ZIndex = 86,
		Parent = overlay,
	})
	speedButton.Activated:Connect(function()
		speed = if speed == 1 then 2 else 1
		speedButton.Text = "⏩ x" .. speed
	end)
	local skipButton = Theme.button("Saltar ⏭", C.Muted, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.fromOffset(120, 44),
		TextSize = 18,
		ZIndex = 86,
		Parent = overlay,
	})
	skipButton.Activated:Connect(function()
		skipping = true
	end)

	local cards: { [string]: Card } = {}
	local counts = { A = 0, B = 0 }
	for _, fighter in view.Fighters do
		counts[fighter.Side] += 1
	end
	local seen = { A = 0, B = 0 }
	for _, fighter in view.Fighters do
		seen[fighter.Side] += 1
		local row = if fighter.Side == "A" then allyRow else enemyRow
		cards[fighter.Key] = makeCard(row, fighter, seen[fighter.Side], counts[fighter.Side], fighter.Side == "B")
	end

	for _, event in view.Events do
		local actor = cards[event.Actor]
		if actor == nil then
			continue
		end
		local lunge = if string.sub(event.Actor, 1, 1) == "A" then -24 else 24
		local origin = actor.Frame.Position
		if not skipping then
			Theme.tween(actor.Frame, 0.12 / speed, { Position = origin + UDim2.fromOffset(0, lunge) })
		end
		if event.Move == "Special" and not skipping then
			local fighterRarity = "Common"
			for _, fighter in view.Fighters do
				if fighter.Key == event.Actor then
					fighterRarity = fighter.Rarity
				end
			end
			banner("💥 " .. event.MoveName .. "!", Theme.rarityColor(fighterRarity))
			wait(0.5)
		end
		for _, hit in event.Hits do
			local target = cards[hit.Target]
			if target == nil then
				continue
			end
			if not skipping then
				Sounds.play("Hit", 0.9 + math.random() * 0.3)
				floatText(
					target.Frame,
					(if hit.Crit then "¡CRÍTICO! " else "") .. "-" .. hit.Damage,
					if hit.Crit then C.Gold else C.Red,
					if hit.Crit then 30 else 26
				)
				task.spawn(shake, target.Frame, if hit.Crit then 10 else 5, 0.2)
			end
			local fraction = math.clamp(hit.HPAfter / target.MaxHP, 0, 1)
			Theme.tween(target.Bar, if skipping then 0 else 0.25 / speed, {
				Size = UDim2.fromScale(fraction, 1),
				BackgroundColor3 = if fraction > 0.5 then C.Lime elseif fraction > 0.2 then C.Amber else C.Red,
			})
			target.HPLabel.Text = string.format("%d / %d", hit.HPAfter, target.MaxHP)
			if hit.KO then
				-- K.O. cómico: la carta sale disparada girando.
				if not skipping then
					Sounds.play("KO")
					floatText(target.Frame, "¡K.O.!", C.Pink, 34)
				end
				local direction = if string.sub(hit.Target, 1, 1) == "A" then 1 else -1
				Theme.tween(target.Frame, if skipping then 0 else 0.8 / speed, {
					Position = target.Frame.Position + UDim2.fromScale(math.random(-30, 30) / 100, 0.9 * direction),
					Rotation = math.random(-720, 720),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			wait(0.18)
		end
		if not skipping then
			Theme.tween(actor.Frame, 0.12 / speed, { Position = origin })
		end
		wait(0.35)
	end

	local won = view.Winner == "A"
	banner(
		if won then "🏆 ¡VICTORIA!" elseif view.Winner == "Draw" then "🤝 ¡EMPATE!" else "😵 DERROTA...",
		if won then C.Gold else C.Red
	)
	Sounds.play(if won then "Reward" else "KO")
	if view.Rewards then
		local rewards = view.Rewards
		local text =
			string.format("+%s 💰   +%d XP a tu equipo", Theme.formatNumber(rewards.PensionCoins), rewards.TeamXp)
		if rewards.GigaGems > 0 then
			text ..= string.format("   +%d 💎", rewards.GigaGems)
		end
		Theme.label(text, 24, C.Lime, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.9, -8),
			Size = UDim2.fromOffset(600, 30),
			ZIndex = 86,
			Parent = overlay,
		})
	elseif not won then
		Theme.label("Tus OGs ganaron algo de XP. ¡Entrénalos en el Gimnasio y vuelve!", 20, C.Muted, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.9, -8),
			Size = UDim2.fromOffset(600, 30),
			ZIndex = 86,
			Parent = overlay,
		})
	end

	speedButton:Destroy()
	skipButton:Destroy()
	local again = Theme.button(if won then "Siguiente rival ⚔️" else "Revancha ⚔️", C.Red, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -150, 1, -12),
		Size = UDim2.fromOffset(200, 48),
		TextSize = 18,
		ZIndex = 86,
		Parent = overlay,
	})
	local close = Theme.button("Cerrar", C.Muted, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.fromOffset(120, 48),
		TextSize = 18,
		ZIndex = 86,
		Parent = overlay,
	})
	busy = false
	again.Activated:Connect(function()
		Sounds.play("Click")
		Net.get("StartBattle"):Fire()
	end)
	close.Activated:Connect(function()
		Sounds.play("Click")
		overlay.Visible = false
	end)
end

local function refresh()
	local profile = State.Profile
	if profile == nil then
		return
	end
	tierLabel.Text = string.format(
		"Próximo rival: nivel %d   ·   Victorias: %d\nTu equipo: %d OG(s) equipados",
		profile.BattleTier,
		profile.BattlesWon,
		#profile.Equipped
	)
	Theme.setEnabled(fightButton, #profile.Equipped > 0)
end

function BattleController.start(gui: ScreenGui)
	panel = Panel.new(gui, "⚔️ Arena Central", C.Red)
	tierLabel = Theme.label("", 22, C.White, {
		Size = UDim2.new(1, 0, 0, 70),
		Parent = panel.Content,
	})
	Theme.label(
		"Tus 3 OGs equipados pelean por turnos contra un escuadrón rival. Cada 3 acciones lanzan su ataque especial. Ganar da PensionCoins, XP y, cada 5 rivales, GigaGems.",
		16,
		C.Muted,
		{ Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 70), Parent = panel.Content }
	)
	fightButton = Theme.button("¡A pelear! ⚔️", C.Red, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 170),
		Size = UDim2.fromOffset(260, 64),
		TextSize = 26,
		Parent = panel.Content,
	})
	fightButton.Activated:Connect(function()
		if fightButton.Active then
			Sounds.play("Click")
			Net.get("StartBattle"):Fire()
		end
	end)

	overlay = Theme.create("Frame", {
		Name = "BattleViewer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Night,
		BackgroundTransparency = 0.05,
		Visible = false,
		Active = true,
		ZIndex = 70,
		Parent = gui,
	}, {
		Theme.create("UIGradient", { Rotation = 90, Color = ColorSequence.new(C.Cyber, C.Night) }),
	})

	Net.get("BattleResult"):Connect(function(view: any)
		if busy or type(view) ~= "table" then
			return
		end
		task.spawn(play, view)
	end)
	State.Changed:Connect(refresh)
	HUDController.bind("Battle", BattleController.open)
end

function BattleController.open()
	refresh()
	panel:Open()
end

return BattleController
