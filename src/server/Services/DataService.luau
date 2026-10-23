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

export type OGData = {
	Id: string,
	Level: number,
	XP: number,
	Shiny: boolean,
	Obtained: number,
}

export type ProfileData = {
	PensionCoins: number,
	GigaGems: number,
	Tickets: number,
	EpicTickets: number,
	OGs: { [string]: OGData },
	Equipped: { string },
	Pity: number,
	TotalRolls: number,
	BattleTier: number,
	BattlesWon: number,
	DailyStreak: number,
	LastDailyDay: number,
	LastSeen: number,
	XpBoostUntil: number,
	ProcessedReceipts: { [string]: number },
	StarterPackBought: boolean,
	UnlockedZone: number,
}

export type Currency = "PensionCoins" | "GigaGems" | "Tickets" | "EpicTickets"

type StoredRecord = {
	Data: ProfileData,
	LockJobId: string?,
	LockTime: number?,
	SchemaVersion: number,
}

local SCHEMA_VERSION = 1
local JOB_ID = if RunService:IsStudio() then "studio-" .. game.JobId else game.JobId

-- En un place sin publicar GetDataStore lanza error: no debe tumbar el servidor entero.
local storeOk, storeResult = pcall(DataStoreService.GetDataStore, DataStoreService, CONFIG.DataStoreName)
local store: DataStore? = if storeOk then storeResult else nil
if not storeOk then
	warn("[DataService] DataStore no disponible:", storeResult)
end
local profiles: { [Player]: ProfileData } = {}
-- En Studio sin acceso a API (place sin publicar) el perfil vive solo en memoria y no se guarda.
local memoryOnly: { [Player]: boolean } = {}
local loadedSignal = Instance.new("BindableEvent")
local changedSignal = Instance.new("BindableEvent")

local DataService = {}
DataService.ProfileLoaded = loadedSignal.Event
-- Se dispara cuando un servicio modifica el perfil; Main lo usa para avisar al cliente.
DataService.ProfileChanged = changedSignal.Event

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
	local activeStore = store
	if activeStore == nil then
		return Promise.reject("DataStore no disponible")
	end
	return Promise.retry(function()
		return Promise.new(function(resolve)
			resolve(activeStore:UpdateAsync(key, transform))
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
	if data == nil or memoryOnly[player] then
		return Promise.resolve()
	end
	data.LastSeen = os.time()
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
		if RunService:IsStudio() and not string.find(tostring(result), "bloqueado", 1, true) then
			warn("[DataService] Studio sin acceso a DataStores; perfil temporal en memoria:", result)
			memoryOnly[player] = true
			result = reconcile({})
		else
			warn("[DataService] No se pudo cargar", player.Name, result)
			player:Kick("No se pudieron cargar tus datos. Vuelve a entrar en unos segundos.")
			return
		end
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
	memoryOnly[player] = nil
end

-- API pública ------------------------------------------------------------------
function DataService.getProfile(player: Player): ProfileData?
	return profiles[player]
end

-- Guarda ya (sin soltar el bloqueo). Lo usan las compras antes de confirmar el recibo.
function DataService.saveNow(player: Player)
	return saveProfile(player, false)
end

function DataService.isMemoryOnly(player: Player): boolean
	return memoryOnly[player] == true
end

-- Suma (o resta) una moneda. Rechaza valores no enteros, saldo negativo y desbordes.
function DataService.adjust(player: Player, currency: Currency, delta: number): boolean
	local profile = profiles[player]
	if profile == nil or delta ~= delta or delta % 1 ~= 0 then
		return false
	end
	local newValue = (profile :: any)[currency] + delta
	if newValue < 0 or newValue > GameConfig.Economy.MaxCurrency then
		return false
	end
	(profile :: any)[currency] = newValue
	changedSignal:Fire(player, "Currency")
	return true
end

-- Para cambios que no son de moneda (OGs, equipo, rachas): el servicio modifica el perfil y avisa.
function DataService.markChanged(player: Player)
	if profiles[player] then
		changedSignal:Fire(player, "Full")
	end
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
