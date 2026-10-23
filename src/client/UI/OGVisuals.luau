--!strict
-- Aspecto de cada OG: icono para la UI y colores para el modelo chibi 3D que sigue al jugador.
-- Estilo "chibi-cabezón": cabeza grande, cuerpo compacto (docs/gdd/art-direction.md).

export type Visual = {
	Icon: string,
	Skin: Color3,
	Hair: Color3,
	Outfit: Color3,
	-- Accesorio sobre la cabeza: "Bun" (moño), "Sombrero", "Cap", "Band", "Helmet", "None".
	Hat: "Bun" | "Sombrero" | "Cap" | "Band" | "Helmet" | "None",
	HatColor: Color3,
	Mustache: boolean,
	Beard: boolean,
	Glasses: boolean,
}

local SKIN_LIGHT = Color3.fromRGB(255, 214, 180)
local SKIN_TAN = Color3.fromRGB(214, 158, 112)
local SKIN_DARK = Color3.fromRGB(150, 98, 66)
local WHITE_HAIR = Color3.fromRGB(240, 240, 245)
local GREY_HAIR = Color3.fromRGB(190, 190, 200)

local VISUALS: { [string]: Visual } = {
	VecinoReganon = {
		Icon = "👴",
		Skin = SKIN_LIGHT,
		Hair = GREY_HAIR,
		Outfit = Color3.fromRGB(120, 110, 100),
		Hat = "Cap",
		HatColor = Color3.fromRGB(90, 80, 70),
		Mustache = true,
		Beard = false,
		Glasses = false,
	},
	AbueloDomino = {
		Icon = "🧓",
		Skin = SKIN_DARK,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(240, 240, 240),
		Hat = "None",
		HatColor = Color3.new(1, 1, 1),
		Mustache = false,
		Beard = false,
		Glasses = true,
	},
	AbuelaCosturera = {
		Icon = "👵",
		Skin = SKIN_LIGHT,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(86, 110, 60),
		Hat = "Bun",
		HatColor = WHITE_HAIR,
		Mustache = false,
		Beard = false,
		Glasses = true,
	},
	AbueloCartero = {
		Icon = "📮",
		Skin = SKIN_TAN,
		Hair = GREY_HAIR,
		Outfit = Color3.fromRGB(40, 90, 200),
		Hat = "Cap",
		HatColor = Color3.fromRGB(30, 60, 160),
		Mustache = true,
		Beard = false,
		Glasses = false,
	},
	DonChente = {
		Icon = "🤠",
		Skin = SKIN_TAN,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(20, 20, 30),
		Hat = "Sombrero",
		HatColor = Color3.fromRGB(255, 62, 165),
		Mustache = true,
		Beard = false,
		Glasses = false,
	},
	MaestroMarcial = {
		Icon = "🥋",
		Skin = SKIN_TAN,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(245, 245, 245),
		Hat = "Band",
		HatColor = Color3.fromRGB(230, 30, 40),
		Mustache = false,
		Beard = true,
		Glasses = false,
	},
	SenseiTanaka = {
		Icon = "🎋",
		Skin = SKIN_LIGHT,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(30, 30, 40),
		Hat = "None",
		HatColor = WHITE_HAIR,
		Mustache = true,
		Beard = true,
		Glasses = false,
	},
	CientificoLoco = {
		Icon = "🧪",
		Skin = SKIN_LIGHT,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(250, 250, 250),
		Hat = "None",
		HatColor = WHITE_HAIR,
		Mustache = true,
		Beard = false,
		Glasses = true,
	},
	ViajeroIntergalactico = {
		Icon = "🚀",
		Skin = SKIN_DARK,
		Hair = WHITE_HAIR,
		Outfit = Color3.fromRGB(230, 230, 240),
		Hat = "Helmet",
		HatColor = Color3.fromRGB(32, 227, 224),
		Mustache = false,
		Beard = true,
		Glasses = false,
	},
	CiberAbuelo = {
		Icon = "🤖",
		Skin = Color3.fromRGB(200, 205, 215),
		Hair = Color3.fromRGB(57, 255, 20),
		Outfit = Color3.fromRGB(160, 170, 185),
		Hat = "Helmet",
		HatColor = Color3.fromRGB(57, 255, 20),
		Mustache = false,
		Beard = false,
		Glasses = true,
	},
}

local FALLBACK: Visual = VISUALS.VecinoReganon

local OGVisuals = {}

function OGVisuals.get(archetypeId: string): Visual
	return VISUALS[archetypeId] or FALLBACK
end

return OGVisuals
