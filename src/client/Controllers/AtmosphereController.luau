--!strict
-- Ambiente de día "cartoon brillante" (inspirado en Pet Simulator): cielo azul, sol suave,
-- colores saturados y un poco de bloom para los acentos de neón.
-- Se aplica en el cliente al entrar, así el look es el mismo en cualquier mapa (docs/gdd/art-direction.md).
-- También ofrece destellos de color y "golpes" de cámara para los momentos épicos.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local AtmosphereController = {}

local LIGHTING = {
	ClockTime = 14.2,
	GeographicLatitude = 20,
	Brightness = 3,
	Ambient = Color3.fromRGB(120, 120, 135),
	OutdoorAmbient = Color3.fromRGB(150, 150, 165),
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 0.6,
	ExposureCompensation = 0.1,
	GlobalShadows = true,
	ShadowSoftness = 0.4,
}

local bloom: BloomEffect? = nil
local grade: ColorCorrectionEffect? = nil
local BASE_BLOOM = 0.35
local BASE_TINT = Color3.fromRGB(255, 252, 245)

-- Reutiliza el efecto si el mapa ya trae uno con ese nombre; si no, lo crea.
local function ensure<T>(className: string, name: string): T
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing :: any
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = Lighting
	return instance :: any
end

function AtmosphereController.start()
	for key, value in LIGHTING do
		(Lighting :: any)[key] = value
	end

	local atmosphere = ensure("Atmosphere", "MonOGAtmosphere") :: Atmosphere
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.05
	atmosphere.Color = Color3.fromRGB(199, 225, 255)
	atmosphere.Decay = Color3.fromRGB(110, 160, 230)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.6

	local newBloom = ensure("BloomEffect", "MonOGBloom") :: BloomEffect
	newBloom.Intensity = BASE_BLOOM
	newBloom.Size = 20
	newBloom.Threshold = 0.98
	bloom = newBloom

	local newGrade = ensure("ColorCorrectionEffect", "MonOGGrade") :: ColorCorrectionEffect
	newGrade.Saturation = 0.22
	newGrade.Contrast = 0.06
	newGrade.Brightness = 0.02
	newGrade.TintColor = BASE_TINT
	grade = newGrade

	local sky = ensure("Sky", "MonOGSky") :: Sky
	sky.CelestialBodiesShown = true
	sky.SunAngularSize = 14
end

-- Destello del color de la rareza: tiñe la pantalla y sube el bloom un instante.
function AtmosphereController.flash(color: Color3, strength: number?)
	local b, g = bloom, grade
	if b == nil or g == nil then
		return
	end
	local s = math.clamp(strength or 1, 0, 3)
	b.Intensity = BASE_BLOOM + 1.6 * s
	g.TintColor = BASE_TINT:Lerp(color, 0.45 * math.min(s, 1.5))
	g.Brightness = 0.02 + 0.12 * s
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(b, info, { Intensity = BASE_BLOOM }):Play()
	TweenService:Create(g, info, { TintColor = BASE_TINT, Brightness = 0.02 }):Play()
end

-- "Golpe" de cámara: abre el campo de visión y vuelve, para impactos y revelaciones.
function AtmosphereController.punch(amount: number?)
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	local base = 70
	camera.FieldOfView = base + (amount or 8)
	TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Back), { FieldOfView = base }):Play()
end

return AtmosphereController
