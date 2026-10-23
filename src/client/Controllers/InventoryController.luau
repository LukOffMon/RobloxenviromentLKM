--!strict
-- "Mis OGs": colección de abuelos, equipo activo (3) y acceso rápido a entrenar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Configurations.GameConfig)
local OGCatalog = require(ReplicatedStorage.Shared.Configurations.OGCatalog)
local ProgressionLogic = require(ReplicatedStorage.Shared.Logic.ProgressionLogic)

local HUDController = require(script.Parent.HUDController)
local Net = require(script.Parent.Net)
local OGVisuals = require(script.Parent.Parent.UI.OGVisuals)
local Panel = require(script.Parent.Parent.UI.Components.Panel)
local Sounds = require(script.Parent.Parent.UI.Sounds)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Parent.UI.Theme)

local C = Theme.Colors

local InventoryController = {}

local panel: Panel.Panel
local header: TextLabel
local grid: ScrollingFrame
local trainCallback: ((uid: string) -> ())? = nil

local function sortedOGs(profile: any): { { Uid: string, OG: any, Order: number, Equipped: boolean } }
	local list = {}
	for uid, og in profile.OGs do
		local archetype = OGCatalog.getArchetype(og.Id)
		local rarity = archetype and OGCatalog.getRarity(archetype.Rarity)
		table.insert(list, {
			Uid = uid,
			OG = og,
			Order = if rarity then rarity.Order else 0,
			Equipped = table.find(profile.Equipped, uid) ~= nil,
		})
	end
	table.sort(list, function(a, b)
		if a.Equipped ~= b.Equipped then
			return a.Equipped
		end
		if a.Order ~= b.Order then
			return a.Order > b.Order
		end
		if a.OG.Level ~= b.OG.Level then
			return a.OG.Level > b.OG.Level
		end
		return a.Uid < b.Uid
	end)
	return list
end

local function card(entry: { Uid: string, OG: any, Order: number, Equipped: boolean }, order: number)
	local og = entry.OG
	local archetype = OGCatalog.getArchetype(og.Id)
	if archetype == nil then
		return
	end
	local color = Theme.rarityColor(archetype.Rarity)
	local visual = OGVisuals.get(og.Id)
	local frame = Theme.create("Frame", {
		BackgroundColor3 = if entry.Equipped then C.PanelLight else C.Night,
		LayoutOrder = order,
		Parent = grid,
	}, { Theme.corner(16), Theme.stroke(color, if entry.Equipped then 4 else 2) })

	Theme.portrait(
		og.Id,
		visual.Icon,
		46,
		{ Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 52), Parent = frame }
	)
	if og.Shiny then
		Theme.label(
			"✨",
			22,
			C.Gold,
			{ Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(26, 26), Parent = frame }
		)
	end
	Theme.label(
		archetype.DisplayName,
		15,
		C.White,
		{ Position = UDim2.fromOffset(6, 58), Size = UDim2.new(1, -12, 0, 36), Parent = frame }
	)
	Theme.label(
		string.format("%s · Nv %d", Theme.rarityName(archetype.Rarity), og.Level),
		14,
		color,
		{ Position = UDim2.fromOffset(0, 94), Size = UDim2.new(1, 0, 0, 18), Parent = frame }
	)

	-- Barra de XP hacia el siguiente nivel.
	local barBack = Theme.create("Frame", {
		Position = UDim2.fromOffset(10, 116),
		Size = UDim2.new(1, -20, 0, 8),
		BackgroundColor3 = C.Cyber,
		Parent = frame,
	}, { Theme.corner(4) })
	local progress = if og.Level >= GameConfig.OG.MaxLevel then 1 else og.XP / ProgressionLogic.xpToNext(og.Level)
	Theme.create("Frame", {
		Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1),
		BackgroundColor3 = C.Lime,
		Parent = barBack,
	}, { Theme.corner(4) })

	local equip =
		Theme.button(if entry.Equipped then "Quitar" else "Equipar", if entry.Equipped then C.Muted else C.Amber, {
			Position = UDim2.new(0, 8, 1, -42),
			Size = UDim2.new(0.5, -12, 0, 34),
			TextSize = 15,
			Parent = frame,
		})
	equip.Activated:Connect(function()
		Sounds.play("Click")
		Net.get("SetEquipped"):Fire(entry.Uid, not entry.Equipped)
	end)
	local train = Theme.button("🦵", C.Cyan, {
		Position = UDim2.new(0.5, 4, 1, -42),
		Size = UDim2.new(0.5, -12, 0, 34),
		TextSize = 18,
		Parent = frame,
	})
	train.Activated:Connect(function()
		Sounds.play("Click")
		if trainCallback then
			panel:Close()
			trainCallback(entry.Uid)
		end
	end)
end

local function render()
	local profile = State.Profile
	if profile == nil or not panel.IsOpen then
		return
	end
	for _, child in grid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local list = sortedOGs(profile)
	header.Text = string.format(
		"Equipo: %d/%d   ·   Colección: %d/%d   ·   Tus OGs equipados cobran pensión y combaten",
		#profile.Equipped,
		GameConfig.OG.MaxEquipped,
		#list,
		GameConfig.OG.MaxOwned
	)
	for index, entry in list do
		card(entry, index)
	end
end

function InventoryController.start(gui: ScreenGui, onTrain: (uid: string) -> ())
	trainCallback = onTrain
	panel = Panel.new(gui, "🎒 Mis OGs", C.Amber)
	header = Theme.label("", 16, C.Muted, {
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel.Content,
	})
	grid = Theme.create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 1, -28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel.Content,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(150, 176),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	State.Changed:Connect(function(kind)
		if kind == "Full" then
			render()
		end
	end)
	HUDController.bind("Inventory", InventoryController.open)
end

function InventoryController.open()
	panel:Open()
	render()
end

return InventoryController
