--!strict
-- Tema visual "Toon-Cyber" de MonOG y utilidades para construir UI con poco código.
-- Paleta y reglas en docs/gdd/art-direction.md

local TweenService = game:GetService("TweenService")

local Assets = require(game:GetService("ReplicatedStorage").Shared.Configurations.Assets)
local OGCatalog = require(game:GetService("ReplicatedStorage").Shared.Configurations.OGCatalog)

local Theme = {}

Theme.Colors = table.freeze({
	Night = Color3.fromHex("#0B0E14"),
	Cyber = Color3.fromHex("#1A0933"),
	Panel = Color3.fromHex("#160B2B"),
	PanelLight = Color3.fromHex("#24124A"),
	Lime = Color3.fromHex("#39FF14"),
	Amber = Color3.fromHex("#FF8C00"),
	Gold = Color3.fromHex("#FFD700"),
	Pink = Color3.fromHex("#FF3EA5"),
	Cyan = Color3.fromHex("#20E3E0"),
	Red = Color3.fromHex("#FF2A4D"),
	White = Color3.new(1, 1, 1),
	Muted = Color3.fromHex("#A99BC9"),
})

Theme.Font = Enum.Font.FredokaOne
Theme.BodyFont = Enum.Font.GothamBold

function Theme.rarityColor(rarityId: string): Color3
	local rarity = OGCatalog.getRarity(rarityId)
	return if rarity then Color3.fromHex(rarity.Color) else Theme.Colors.Muted
end

function Theme.rarityName(rarityId: string): string
	local rarity = OGCatalog.getRarity(rarityId)
	return if rarity then rarity.DisplayName else rarityId
end

-- 1234567 -> "1.23M"
function Theme.formatNumber(value: number): string
	local abs = math.abs(value)
	if abs >= 1e12 then
		return string.format("%.2fT", value / 1e12)
	elseif abs >= 1e9 then
		return string.format("%.2fB", value / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.2fM", value / 1e6)
	elseif abs >= 1e4 then
		return string.format("%.1fK", value / 1e3)
	end
	return tostring(math.floor(value))
end

-- Crea una instancia con propiedades e hijos: create("Frame", { Size = ... }, { child1, child2 })
function Theme.create(className: string, props: { [string]: any }?, children: { any }?): any
	local instance = Instance.new(className) :: any
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Theme.corner(radius: number?): any
	return Theme.create("UICorner", { CornerRadius = UDim.new(0, radius or 14) })
end

function Theme.stroke(color: Color3?, thickness: number?): any
	return Theme.create("UIStroke", {
		Color = color or Theme.Colors.Night,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(pixels: number): any
	local p = UDim.new(0, pixels)
	return Theme.create("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

function Theme.label(text: string, size: number, color: Color3?, props: { [string]: any }?): TextLabel
	local label = Theme.create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = size,
		TextColor3 = color or Theme.Colors.White,
		TextStrokeTransparency = 0.4,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, size + 6),
	})
	if props then
		for key, value in props do
			(label :: any)[key] = value
		end
	end
	return label
end

function Theme.tween(
	instance: Instance,
	seconds: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

-- "Squish & Stretch": aplasta y rebota un elemento mediante su UIScale.
function Theme.squish(guiObject: GuiObject, strength: number?)
	local scale = guiObject:FindFirstChildOfClass("UIScale")
	if scale == nil then
		scale = Theme.create("UIScale", { Parent = guiObject })
	end
	local s = scale :: UIScale
	s.Scale = 1 + (strength or 0.18)
	Theme.tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Elastic)
end

-- Botón "jugoso": se hunde al pulsar y rebota al soltar.
function Theme.button(text: string, color: Color3, props: { [string]: any }?): TextButton
	local button = Theme.create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Text = text,
		Font = Theme.Font,
		TextSize = 22,
		TextColor3 = Theme.Colors.White,
		TextStrokeTransparency = 0.3,
		TextWrapped = true,
		Size = UDim2.fromOffset(180, 52),
	}, {
		Theme.corner(14),
		Theme.stroke(Theme.Colors.Night, 3),
		Theme.create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)),
		}),
	})
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	local scale = Theme.create("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		Theme.tween(scale, 0.08, { Scale = 0.9 })
	end)
	button.MouseButton1Up:Connect(function()
		Theme.tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Elastic)
	end)
	button.MouseLeave:Connect(function()
		Theme.tween(scale, 0.15, { Scale = 1 })
	end)
	return button
end

-- Icono de la UI: imagen subida (Assets.Icons) o, si aún no existe, el emoji de respaldo.
function Theme.icon(name: string, fallback: string, size: number, color: Color3?, props: { [string]: any }?): GuiObject
	local id = (Assets.Icons :: any)[name]
	local object: GuiObject
	if type(id) == "string" and id ~= "" then
		object = Theme.create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = id,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size),
		})
	else
		object = Theme.label(fallback, size, color)
	end
	if props then
		for key, value in props do
			(object :: any)[key] = value
		end
	end
	return object
end

-- Retrato de un OG: imagen (Assets.Portraits) o el emoji de OGVisuals.
function Theme.portrait(archetypeId: string, fallback: string, size: number, props: { [string]: any }?): GuiObject
	local id = (Assets.Portraits :: any)[archetypeId]
	local object: GuiObject
	if type(id) == "string" and id ~= "" then
		object = Theme.create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = id,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size),
		})
	else
		object = Theme.label(fallback, size, Theme.Colors.White)
	end
	if props then
		for key, value in props do
			(object :: any)[key] = value
		end
	end
	return object
end

function Theme.setEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.AutoButtonColor = false
	button.TextTransparency = if enabled then 0 else 0.45
	button.BackgroundTransparency = if enabled then 0 else 0.5
end

return Theme
