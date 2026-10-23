--!strict
-- "La Hora del Bingo Matutino": cartilla de 7 días. Romper la racha la reinicia.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Configurations.GameConfig)

local HUDController = require(script.Parent.HUDController)
local Net = require(script.Parent.Net)
local Panel = require(script.Parent.Parent.UI.Components.Panel)
local Sounds = require(script.Parent.Parent.UI.Sounds)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local C = Theme.Colors
local ICONS = { PensionCoins = "💰", GigaGems = "💎", Tickets = "🎟", EpicTickets = "⭐" }

local DailyController = {}

local panel: Panel.Panel
local cells: { Frame } = {}
local claimButton: TextButton
local info: TextLabel

local function rewardText(reward: { [string]: number }): string
	local parts = {}
	for currency, amount in reward do
		table.insert(parts, string.format("%s %s", ICONS[currency] or currency, Theme.formatNumber(amount)))
	end
	table.sort(parts)
	return table.concat(parts, "\n")
end

local function refresh()
	local profile = State.Profile
	if profile == nil then
		return
	end
	local streak = profile.DailyStreak
	for day, cell in cells do
		local claimed = day <= streak
		local stroke = cell:FindFirstChildOfClass("UIStroke") :: UIStroke
		cell.BackgroundColor3 = if claimed then C.Cyber else C.PanelLight
		local mark = cell:FindFirstChild("Mark") :: TextLabel
		mark.Text = if claimed then "✔" else ""
		stroke.Color = if day == 7 then C.Gold else C.Lime
	end
	Theme.setEnabled(claimButton, profile.CanClaimDaily == true)
	claimButton.Text = if profile.CanClaimDaily then "¡Cantar BINGO! 🔥" else "Vuelve mañana ⏰"
	info.Text = string.format(
		"Racha actual: %d día(s). Conéctate cada día: el día 7 trae el premio mayor. Si faltas un día, la cartilla vuelve a empezar.",
		streak
	)
end

function DailyController.start(gui: ScreenGui)
	panel = Panel.new(gui, "🔥 Bingo Matutino", C.Lime)
	local grid = Theme.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 260),
		Parent = panel.Content,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(120, 120),
			CellPadding = UDim2.fromOffset(10, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for day, reward in GameConfig.Daily do
		local cell = Theme.create("Frame", {
			BackgroundColor3 = C.PanelLight,
			LayoutOrder = day,
			Parent = grid,
		}, { Theme.corner(16), Theme.stroke(if day == 7 then C.Gold else C.Lime, 3) })
		Theme.label("Día " .. day, 18, if day == 7 then C.Gold else C.White, {
			Position = UDim2.fromOffset(0, 6),
			Parent = cell,
		})
		Theme.label(rewardText(reward :: any), 18, C.White, {
			Position = UDim2.fromOffset(0, 34),
			Size = UDim2.new(1, 0, 0, 60),
			Parent = cell,
		})
		Theme.label("", 64, C.Lime, {
			Name = "Mark",
			Size = UDim2.fromScale(1, 1),
			TextTransparency = 0.15,
			Parent = cell,
		})
		cells[day] = cell
	end
	info = Theme.label("", 15, C.Muted, {
		Position = UDim2.fromOffset(0, 270),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = panel.Content,
	})
	claimButton = Theme.button("", C.Lime, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.fromOffset(280, 56),
		TextSize = 22,
		Parent = panel.Content,
	})
	claimButton.Activated:Connect(function()
		if claimButton.Active then
			Sounds.play("Click")
			Net.get("ClaimDaily"):Fire()
		end
	end)

	Net.get("DailyResult"):Connect(function(day: any, reward: any)
		local cell = cells[day]
		if cell then
			Theme.squish(cell, 0.4)
		end
		HUDController.toast(string.format("¡BINGO! Día %d: %s", day, (rewardText(reward):gsub("\n", "  "))), "Reward")
	end)

	State.Changed:Connect(function(kind)
		if kind == "Full" then
			refresh()
		end
	end)
	HUDController.bind("Daily", DailyController.open)
end

function DailyController.open()
	refresh()
	panel:Open()
end

return DailyController
