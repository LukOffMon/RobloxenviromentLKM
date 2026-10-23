--!strict
-- DataService: perfiles de jugador con session-locking sobre DataStoreService.
-- Evita duplicación de datos entre servidores: un perfil solo se carga si ningún otro
-- servidor lo tiene bloqueado (o si su bloqueo expiró). Esquema en docs/architecture/datastore-profile-schema.md

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Configurations.GameConfig)
local Promise = require(Shared.Utilities.Promise)

local CONFIG = GameConfig.Data

export type ProfileData = {
	Coins: number,
	Level: number,
	Experience: number,
	Inventory: { [string]: number },
}

type StoredRecord = {
	Data: ProfileData,
	LockJobId: string?,
	LockTime: number?,
	SchemaVersion: number,
}

local SCHEMA_VERSION = 1
local JOB_ID = if RunService:IsStudio() then "studio-" .. game.JobId else game.JobId

local store = DataStoreService:GetDataStore(CONFIG.DataStoreName)
local profiles: { [Player]: ProfileData } = {}
local loadedSignal = Instance.new("BindableEvent")

local DataService = {}
DataService.ProfileLoaded = loadedSignal.Event

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value :: any do
		copy[key] = deepCopy(child)
	end
	return copy :: any
end

-- Rellena campos faltantes con la plantilla (migración aditiva).
local function reconcile(data: { [string]: any }): ProfileData
	for key, default in CONFIG.Template :: any do
		if data[key] == nil then
			data[key] = deepCopy(default)
		end
	end
	return data :: any
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

local function updateAsync(key: string, transform: (StoredRecord?) -> StoredRecord?)
	return Promise.retry(function()
		return Promise.new(function(resolve)
			resolve(store:UpdateAsync(key, transform))
		end)
	end, CONFIG.MaxSaveRetries, 2)
end

local function loadProfile(player: Player)
	local acquired = false
	return updateAsync(keyFor(player), function(record: StoredRecord?)
		local now = os.time()
		if record and record.LockJobId and record.LockJobId ~= JOB_ID then
			local lockAge = now - (record.LockTime or 0)
			if lockAge < CONFIG.SessionLockTimeoutSeconds then
				acquired = false
				return nil -- otro servidor tiene el perfil: no escribir
			end
		end
		acquired = true
		local data = if record then record.Data else deepCopy(CONFIG.Template) :: any
		return {
			Data = reconcile(data),
			LockJobId = JOB_ID,
			LockTime = now,
			SchemaVersion = SCHEMA_VERSION,
		}
	end):andThen(function(record: StoredRecord?)
		if not acquired or record == nil then
			error("perfil bloqueado por otra sesión", 0)
		end
		return record.Data
	end)
end

local function saveProfile(player: Player, release: boolean)
	local data = profiles[player]
	if data == nil then
		return Promise.resolve()
	end
	local snapshot = deepCopy(data)
	return updateAsync(keyFor(player), function(record: StoredRecord?)
		if record and record.LockJobId and record.LockJobId ~= JOB_ID then
			return nil -- perdimos el bloqueo: nunca sobrescribir datos de otra sesión
		end
		return {
			Data = snapshot,
			LockJobId = if release then nil else JOB_ID,
			LockTime = if release then nil else os.time(),
			SchemaVersion = SCHEMA_VERSION,
		}
	end)
end

local function onPlayerAdded(player: Player)
	local ok, result = loadProfile(player):await()
	if player.Parent ~= Players then
		-- Salió mientras cargaba: liberar el bloqueo recién tomado.
		if ok then
			profiles[player] = result
			saveProfile(player, true):await()
			profiles[player] = nil
		end
		return
	end
	if not ok then
		warn("[DataService] No se pudo cargar", player.Name, result)
		player:Kick("No se pudieron cargar tus datos. Vuelve a entrar en unos segundos.")
		return
	end
	profiles[player] = result
	loadedSignal:Fire(player, result)
end

local function onPlayerRemoving(player: Player)
	local ok, err = saveProfile(player, true):await()
	if not ok then
		warn("[DataService] Error al guardar", player.Name, err)
	end
	profiles[player] = nil
end

-- API pública ------------------------------------------------------------------
function DataService.getProfile(player: Player): ProfileData?
	return profiles[player]
end

function DataService.addCoins(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile == nil or amount ~= amount or amount % 1 ~= 0 then
		return false
	end
	local newValue = profile.Coins + amount
	if newValue < 0 or newValue > GameConfig.Economy.MaxCoins then
		return false
	end
	profile.Coins = newValue
	return true
end

function DataService.addExperience(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile == nil or amount <= 0 or amount % 1 ~= 0 then
		return false
	end
	profile.Experience += amount
	local perLevel = GameConfig.Economy.ExperiencePerLevel
	while profile.Experience >= perLevel * profile.Level do
		profile.Experience -= perLevel * profile.Level
		profile.Level += 1
	end
	return true
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(CONFIG.SaveIntervalSeconds)
			for player in profiles do
				task.spawn(function()
					saveProfile(player, false):await()
				end)
			end
		end
	end)

	game:BindToClose(function()
		local pending = {}
		for player in profiles do
			table.insert(pending, saveProfile(player, true))
		end
		Promise.all(pending):await()
	end)
end

return DataService
