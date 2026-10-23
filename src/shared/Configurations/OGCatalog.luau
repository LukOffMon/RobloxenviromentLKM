--!strict
-- Catálogo de OGs (abuelos coleccionables) y rarezas. Fuente: docs/gdd/og-catalog.md
-- Datos puros: sin dependencias de Roblox para poder probarlos con Lune.

export type RarityId = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Transcendent"

export type Rarity = {
	Id: RarityId,
	DisplayName: string,
	Order: number,
	-- Probabilidad en tanto por uno; la suma de todas es 1.
	Chance: number,
	-- Color del brillo de rareza (hex).
	Color: string,
	-- Pensión base por segundo de un OG de esta rareza equipado.
	PensionPerSecond: number,
}

export type Stats = { HP: number, ATK: number, DEF: number, SPD: number }

export type Special = {
	Name: string,
	-- Multiplicador de daño sobre ATK. Si Hits > 1, se reparte por golpe.
	Power: number,
	Hits: number,
	-- "Single" golpea a un objetivo; "All" a todo el equipo rival.
	Target: "Single" | "All",
	Description: string,
}

export type Archetype = {
	Id: string,
	DisplayName: string,
	Rarity: RarityId,
	Stats: Stats,
	Special: Special,
	Flavor: string,
}

local RARITIES: { Rarity } = {
	{
		Id = "Common",
		DisplayName = "Común",
		Order = 1,
		Chance = 0.55,
		Color = "#9C8F84",
		PensionPerSecond = 1,
	},
	{
		Id = "Rare",
		DisplayName = "Raro",
		Order = 2,
		Chance = 0.30,
		Color = "#20E3E0",
		PensionPerSecond = 3,
	},
	{
		Id = "Epic",
		DisplayName = "Épico",
		Order = 3,
		Chance = 0.11,
		Color = "#B44DFF",
		PensionPerSecond = 8,
	},
	{
		Id = "Legendary",
		DisplayName = "Legendario",
		Order = 4,
		Chance = 0.038,
		Color = "#FFD700",
		PensionPerSecond = 25,
	},
	{
		Id = "Mythic",
		DisplayName = "Mítico",
		Order = 5,
		Chance = 0.0019,
		Color = "#FF2A4D",
		PensionPerSecond = 90,
	},
	{
		Id = "Transcendent",
		DisplayName = "Transcendente",
		Order = 6,
		Chance = 0.0001,
		Color = "#39FF14",
		PensionPerSecond = 400,
	},
}

local ARCHETYPES: { Archetype } = {
	{
		Id = "VecinoReganon",
		DisplayName = "Vecino Regañón",
		Rarity = "Common",
		Stats = { HP = 100, ATK = 14, DEF = 10, SPD = 8 },
		Special = {
			Name = "¡Bájale a la Música!",
			Power = 1.8,
			Hits = 1,
			Target = "Single",
			Description = "Un regaño tan fuerte que aturde los tímpanos.",
		},
		Flavor = "Lleva 40 años quejándose del ruido. Nadie sabe de qué ruido.",
	},
	{
		Id = "AbueloDomino",
		DisplayName = "Abuelo del Dominó",
		Rarity = "Common",
		Stats = { HP = 90, ATK = 12, DEF = 12, SPD = 10 },
		Special = {
			Name = "Capicúa",
			Power = 0.9,
			Hits = 2,
			Target = "Single",
			Description = "Azota dos fichas sobre la mesa del rival.",
		},
		Flavor = "Juega dominó en el parque desde antes de que existiera el parque.",
	},
	{
		Id = "AbuelaCosturera",
		DisplayName = "Abuela Costurera Bélica",
		Rarity = "Rare",
		Stats = { HP = 120, ATK = 18, DEF = 12, SPD = 14 },
		Special = {
			Name = "Chanclazo Teledirigido",
			Power = 2.2,
			Hits = 1,
			Target = "Single",
			Description = "Lanza la pantufla como bumerán; persigue al rival.",
		},
		Flavor = "Gafas de fondo de botella y chaleco tejido de camuflaje.",
	},
	{
		Id = "AbueloCartero",
		DisplayName = "Cartero Jubilado Turbo",
		Rarity = "Rare",
		Stats = { HP = 105, ATK = 16, DEF = 10, SPD = 20 },
		Special = {
			Name = "Correo Certificado",
			Power = 0.8,
			Hits = 3,
			Target = "Single",
			Description = "Tres cartas de reclamo entregadas a toda velocidad.",
		},
		Flavor = "Nunca perdió una carta. Ni un perro le ganó una carrera.",
	},
	{
		Id = "DonChente",
		DisplayName = 'Don Chente "El Charro Inmortal"',
		Rarity = "Epic",
		Stats = { HP = 150, ATK = 24, DEF = 15, SPD = 15 },
		Special = {
			Name = "Grito Vicente",
			Power = 1.4,
			Hits = 1,
			Target = "All",
			Description = "Onda expansiva roja que marea a todo el equipo rival.",
		},
		Flavor = "Bigote gigantesco y sombrero de charro de neón.",
	},
	{
		Id = "MaestroMarcial",
		DisplayName = "Maestro Marcial Retirado",
		Rarity = "Epic",
		Stats = { HP = 135, ATK = 27, DEF = 13, SPD = 19 },
		Special = {
			Name = "Patada del Jubilado",
			Power = 2.8,
			Hits = 1,
			Target = "Single",
			Description = "Una patada voladora con la cadera de titanio.",
		},
		Flavor = "Se retiró del dojo, pero el dojo nunca se retiró de él.",
	},
	{
		Id = "SenseiTanaka",
		DisplayName = 'Sensei Tanaka "100 Añejos"',
		Rarity = "Legendary",
		Stats = { HP = 180, ATK = 32, DEF = 18, SPD = 24 },
		Special = {
			Name = "Sombra de Bastón",
			Power = 0.75,
			Hits = 5,
			Target = "Single",
			Description = "Desaparece en humo y golpea 5 veces a súper velocidad.",
		},
		Flavor = "Barba que arrastra por el suelo y bastón de bambú eléctrico.",
	},
	{
		Id = "CientificoLoco",
		DisplayName = "Científico Loco de la Posguerra",
		Rarity = "Legendary",
		Stats = { HP = 165, ATK = 35, DEF = 16, SPD = 21 },
		Special = {
			Name = "Fórmula de Juventud Inestable",
			Power = 1.7,
			Hits = 1,
			Target = "All",
			Description = "Un matraz que explota en burbujas radiactivas.",
		},
		Flavor = "Inventó el control remoto. Lo perdió al día siguiente.",
	},
	{
		Id = "ViajeroIntergalactico",
		DisplayName = "Viajero Intergaláctico de la Tercera Edad",
		Rarity = "Mythic",
		Stats = { HP = 230, ATK = 44, DEF = 22, SPD = 27 },
		Special = {
			Name = "Dentadura Orbital",
			Power = 2.1,
			Hits = 1,
			Target = "All",
			Description = "Su dentadura postiza orbita la arena y muerde a todos.",
		},
		Flavor = "Dice que vio la Tierra desde arriba. Nadie le cree.",
	},
	{
		Id = "CiberAbuelo",
		DisplayName = "Ciber-Abuelo MonOG-01",
		Rarity = "Transcendent",
		Stats = { HP = 320, ATK = 60, DEF = 30, SPD = 32 },
		Special = {
			Name = "Sobrecarga de Pensión",
			Power = 3.0,
			Hits = 1,
			Target = "All",
			Description = "Una dentadura cuántica gigante cae del cielo y aplasta la arena.",
		},
		Flavor = "Mitad abuelo, mitad exoesqueleto de cromo. Flota sobre plasma verde.",
	},
}

local raritiesById: { [string]: Rarity } = {}
for _, rarity in RARITIES do
	raritiesById[rarity.Id] = table.freeze(rarity)
end

local archetypesById: { [string]: Archetype } = {}
local archetypesByRarity: { [string]: { Archetype } } = {}
for _, archetype in ARCHETYPES do
	archetypesById[archetype.Id] = archetype
	local list = archetypesByRarity[archetype.Rarity]
	if list == nil then
		list = {}
		archetypesByRarity[archetype.Rarity] = list
	end
	table.insert(list, archetype)
end

local OGCatalog = {
	Rarities = RARITIES,
	Archetypes = ARCHETYPES,
	RaritiesById = raritiesById,
	ArchetypesById = archetypesById,
	ArchetypesByRarity = archetypesByRarity,
}

function OGCatalog.getRarity(id: string): Rarity?
	return raritiesById[id]
end

function OGCatalog.getArchetype(id: string): Archetype?
	return archetypesById[id]
end

return OGCatalog
