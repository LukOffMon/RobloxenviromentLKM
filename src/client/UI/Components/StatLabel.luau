--!strict
-- StatLabel: componente de UI encapsulado (nombre + valor) con animación por Tween.

local TweenService = game:GetService("TweenService")

export type StatLabel = {
	Instance: Frame,
	SetValue: (self: StatLabel, value: number) -> (),
	Destroy: (self: StatLabel) -> (),
}

local StatLabel = {}
StatLabel.__index = StatLabel

local DISPLAY_NAMES = {
	Coins = "Monedas",
	Level = "Nivel",
	Experience = "Experiencia",
}

local PULSE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

function StatLabel.new(stat: string, layoutOrder: number): StatLabel
	local frame = Instance.new("Frame")
	frame.Name = stat
	frame.LayoutOrder = layoutOrder
	frame.Size = UDim2.new(1, 0, 0, 36)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	frame.BackgroundTransparency = 0.2

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.6, 1)
	name.Font = Enum.Font.GothamMedium
	name.TextSize = 16
	name.TextColor3 = Color3.fromRGB(200, 200, 210)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = DISPLAY_NAMES[stat] or stat
	name.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.BackgroundTransparency = 1
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.fromScale(1, 0)
	value.Size = UDim2.fromScale(0.4, 1)
	value.Font = Enum.Font.GothamBold
	value.TextSize = 18
	value.TextColor3 = Color3.fromRGB(255, 255, 255)
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Text = "0"
	value.Parent = frame

	local self = setmetatable({}, StatLabel) :: any
	self.Instance = frame
	self._value = value
	self._current = 0
	return self :: StatLabel
end

function StatLabel:SetValue(newValue: number)
	if newValue == self._current then
		return
	end
	self._current = newValue
	self._value.Text = string.format("%d", newValue)
	TweenService:Create(self._value, PULSE, { TextSize = 22 }):Play()
end

function StatLabel:Destroy()
	self.Instance:Destroy()
end

return StatLabel
