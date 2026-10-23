--!strict
-- Ventana modal con título, botón de cerrar y animación de entrada. Solo una abierta a la vez.

local Sounds = require(script.Parent.Parent.Sounds)
local Theme = require(script.Parent.Parent.Theme)

export type Panel = {
	Frame: Frame,
	Content: Frame,
	Title: TextLabel,
	IsOpen: boolean,
	OnClose: (() -> ())?,
	Open: (self: Panel) -> (),
	Close: (self: Panel) -> (),
}

local Panel = {}
Panel.__index = Panel

local current: any = nil

function Panel.new(parent: Instance, title: string, accent: Color3): Panel
	local scale = Theme.create("UIScale", { Scale = 1 })
	local frame = Theme.create("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.62, 0.72),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	}, {
		scale,
		Theme.corner(22),
		Theme.stroke(accent, 4),
		Theme.create("UISizeConstraint", { MinSize = Vector2.new(320, 300), MaxSize = Vector2.new(900, 640) }),
	})

	local titleLabel = Theme.label(title, 30, accent, {
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -90, 0, 38),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = frame,
	})

	local close = Theme.button("X", Theme.Colors.Red, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(46, 46),
		ZIndex = 22,
		Parent = frame,
	})

	local content = Theme.create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 1, -78),
		ZIndex = 21,
		Parent = frame,
	})

	local self = setmetatable({
		Frame = frame,
		Content = content,
		Title = titleLabel,
		IsOpen = false,
		OnClose = nil,
		_scale = scale,
	}, Panel) :: any

	close.Activated:Connect(function()
		Sounds.play("Click")
		self:Close()
	end)
	return self :: Panel
end

function Panel.Open(self: any)
	local active = current
	if active and active ~= self then
		active:Close()
	end
	current = self
	self.IsOpen = true
	self.Frame.Visible = true
	self._scale.Scale = 0.6
	Theme.tween(self._scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

function Panel.Close(self: any)
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	if current == self then
		current = nil
	end
	self.Frame.Visible = false
	if self.OnClose then
		self.OnClose()
	end
end

function Panel.closeAll()
	if current then
		current:Close()
	end
end

return Panel
