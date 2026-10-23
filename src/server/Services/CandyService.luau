--!strict
-- CandyService: caramelos de abuela que aparecen en los marcadores CandySpawn del mapa.
-- Bucle de exploración: invitan a recorrer cada rincón. El servidor crea, valida y paga;
-- el cliente solo los anima (etiquetas Spin y Bob) y celebra la recogida.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local CandyLogic = require(Shared.Logic.CandyLogic)
local GameConfig = require(Shared.Configurations.GameConfig)

local DataService = require(script.Parent.DataService)

local CONFIG = GameConfig.Candy
local COLORS = {
	Color3.fromHex("#FF3EA5"),
	Color3.fromHex("#20E3E0"),
	Color3.fromHex("#39FF14"),
	Color3.fromHex("#FFD700"),
	Color3.fromHex("#FF8C00"),
}

local rng = Random.new()
local occupied: { [BasePart]: BasePart? } = {}
local collected = Instance.new("BindableEvent")

local CandyService = {}
-- (player, reward, position) al recoger un caramelo.
CandyService.Collected = collected.Event

local folder: Folder

local function freeSpawns(): { BasePart }
	local list = {}
	for _, marker in CollectionService:GetTagged("CandySpawn") do
		if marker:IsA("BasePart") and marker:IsDescendantOf(workspace) and occupied[marker] == nil then
			table.insert(list, marker)
		end
	end
	return list
end

local function activeCount(): number
	local n = 0
	for _ in occupied do
		n += 1
	end
	return n
end

local function onTouched(candy: BasePart, marker: BasePart, hit: BasePart)
	if candy:GetAttribute("Taken") then
		return
	end
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local profile = player and DataService.getProfile(player)
	if player == nil or root == nil or profile == nil then
		return
	end
	-- Comprobación de distancia en el servidor: no vale tocarlo "desde lejos".
	if (root.Position - candy.Position).Magnitude > CONFIG.PickupRadius then
		return
	end
	-- Marcar y quitar antes de pagar: dos toques simultáneos no cobran dos veces.
	candy:SetAttribute("Taken", true)
	local position = candy.Position
	candy:Destroy()
	occupied[marker] = nil

	local reward = CandyLogic.reward(function()
		return rng:NextNumber()
	end, profile.BattleTier, CONFIG)
	DataService.adjust(player, "PensionCoins", reward.PensionCoins)
	if reward.Tickets > 0 then
		DataService.adjust(player, "Tickets", reward.Tickets)
	end
	if reward.GigaGems > 0 then
		DataService.adjust(player, "GigaGems", reward.GigaGems)
	end
	collected:Fire(player, reward, position)
end

local function spawnCandy(marker: BasePart)
	local candy = Instance.new("Part")
	candy.Name = "Caramelo"
	candy.Shape = Enum.PartType.Ball
	candy.Size = Vector3.new(1.6, 1.6, 1.6)
	candy.Material = Enum.Material.Neon
	candy.Color = COLORS[rng:NextInteger(1, #COLORS)]
	candy.Anchored = true
	candy.CanCollide = false
	candy.CanQuery = false
	candy.CastShadow = false
	candy.CFrame = CFrame.new(marker.Position + Vector3.new(0, 1.8, 0))
	candy:SetAttribute("SpinSpeed", 140)
	candy:SetAttribute("BobHeight", 0.4)
	candy:SetAttribute("BobSpeed", 1.6)
	-- Envoltorio del caramelo: dos "lazos" a los lados.
	for side = -1, 1, 2 do
		local wrap = Instance.new("Part")
		wrap.Name = "Lazo"
		wrap.Size = Vector3.new(0.7, 1, 0.2)
		wrap.Color = candy.Color
		wrap.Material = Enum.Material.Neon
		wrap.Anchored = false
		wrap.CanCollide = false
		wrap.CanQuery = false
		wrap.CanTouch = false
		wrap.Massless = true
		wrap.CastShadow = false
		wrap.CFrame = candy.CFrame * CFrame.new(side * 1.05, 0, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = candy
		weld.Part1 = wrap
		weld.Parent = wrap
		wrap.Parent = candy
	end
	candy.Touched:Connect(function(hit)
		onTouched(candy, marker, hit)
	end)
	candy:AddTag("Candy")
	candy:AddTag("Spin")
	candy:AddTag("Bob")
	occupied[marker] = candy
	candy.Parent = folder
end

function CandyService.start()
	folder = Instance.new("Folder")
	folder.Name = "MonOGCandies"
	folder.Parent = workspace

	task.spawn(function()
		while true do
			-- Limpiar referencias a caramelos que desaparecieron por otros motivos.
			for marker, candy in occupied do
				if candy == nil or candy.Parent == nil then
					occupied[marker] = nil
				end
			end
			local free = freeSpawns()
			-- Rellenar de golpe al principio y luego de uno en uno.
			local toSpawn = math.min(CONFIG.MaxActive - activeCount(), #free)
			if activeCount() > 0 then
				toSpawn = math.min(toSpawn, 3)
			end
			for _ = 1, toSpawn do
				local index = rng:NextInteger(1, #free)
				spawnCandy(table.remove(free, index) :: BasePart)
			end
			task.wait(CONFIG.RespawnSeconds)
		end
	end)
end

return CandyService
