--!strict
-- UIController: HUD del jugador. Solo muestra estado; nunca lo decide.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Shared.Utilities.Janitor)
local StatLabel = require(script.Parent.Parent.UI.Components.StatLabel)

export type ProfileView = { Coins: number, Level: number, Experience: number }

local UIController = {}

local janitor = Janitor.new()
local labels: { [string]: StatLabel.StatLabel } = {}

function UIController.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = janitor:Add(Instance.new("ScreenGui"))
	screen.Name = "LKMHud"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false

	local container = Instance.new("Frame")
	container.Name = "Stats"
	container.AnchorPoint = Vector2.new(0, 0)
	container.Position = UDim2.fromOffset(16, 16)
	container.Size = UDim2.fromOffset(220, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.Parent = screen

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	for order, stat in { "Coins", "Level", "Experience" } do
		local label = StatLabel.new(stat, order)
		label.Instance.Parent = container
		labels[stat] = label
		janitor:Add(label)
	end

	screen.Parent = playerGui
end

function UIController.render(view: ProfileView)
	labels.Coins:SetValue(view.Coins)
	labels.Level:SetValue(view.Level)
	labels.Experience:SetValue(view.Experience)
end

function UIController.stop()
	janitor:Cleanup()
	table.clear(labels)
end

return UIController
