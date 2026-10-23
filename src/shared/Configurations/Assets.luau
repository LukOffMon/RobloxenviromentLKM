--!strict
-- Ids de imágenes subidas a Roblox para la UI. Vacío ("") = se usa el emoji de respaldo.
-- Los modelos 3D no van aquí: viven en ReplicatedStorage/MonOGAssets (ver docs/gdd/art-direction.md):
--   MonOGAssets/OGs/<ArchetypeId>       Model con PrimaryPart, mirando a -Z, ~4 studs de alto
--   MonOGAssets/Breakables/<TypeId>     Model con PrimaryPart (Coins, Chest, Vault)

local Assets = table.freeze({
	Icons = table.freeze({
		PensionCoins = "",
		GigaGems = "",
		Tickets = "",
		EpicTickets = "",
		Gacha = "",
		Inventory = "",
		Training = "",
		Battle = "",
		Daily = "",
		Lock = "",
	}),
	-- Retrato de cada OG para cartas e inventario (rbxassetid://...).
	Portraits = table.freeze({
		VecinoReganon = "",
		AbueloDomino = "",
		AbuelaCosturera = "",
		AbueloCartero = "",
		DonChente = "",
		MaestroMarcial = "",
		SenseiTanaka = "",
		CientificoLoco = "",
		ViajeroIntergalactico = "",
		CiberAbuelo = "",
	}),
})

return Assets
