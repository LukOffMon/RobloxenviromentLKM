--!strict
-- RemoteSignal: envoltorio de RemoteEvent con pipeline de middleware en servidor:
--   (1) Authentication -> (2) Rate Limit -> (3) Type Validation -> (4) Sanity Check -> (5) Execution
-- En el cliente expone Fire/Connect sobre el mismo RemoteEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(script.Parent.Parent.Configurations.GameConfig)

-- Un validador recibe el valor del cliente y devuelve true si es aceptable.
export type Validator = (value: any) -> boolean
export type SanityCheck = (player: Player, ...any) -> boolean
export type Handler = (player: Player, ...any) -> ()

export type ServerOptions = {
	Name: string,
	Args: { Validator },
	RateLimit: number?,
	RateWindowSeconds: number?,
	Sanity: SanityCheck?,
}

local IS_SERVER = RunService:IsServer()
local NETWORK = GameConfig.Network

local violations: { [Player]: number } = {}

local function getRemotesFolder(): Folder
	if IS_SERVER then
		local existing = ReplicatedStorage:FindFirstChild(NETWORK.RemotesFolderName)
		if existing then
			return existing :: Folder
		end
		local folder = Instance.new("Folder")
		folder.Name = NETWORK.RemotesFolderName
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(NETWORK.RemotesFolderName) :: Folder
end

local function reportViolation(player: Player, remoteName: string, reason: string)
	local count = (violations[player] or 0) + 1
	violations[player] = count
	warn(string.format("[RemoteSignal] %s -> %s rechazado: %s (%d)", player.Name, remoteName, reason, count))
	if count >= NETWORK.MaxViolations then
		player:Kick("Actividad de red inválida detectada.")
	end
end

-- Validadores reutilizables ---------------------------------------------------
local Validators = {}

function Validators.number(min: number?, max: number?): Validator
	return function(value)
		if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
			return false
		end
		return (min == nil or value >= min) and (max == nil or value <= max)
	end
end

function Validators.integer(min: number?, max: number?): Validator
	local isNumber = Validators.number(min, max)
	return function(value)
		return isNumber(value) and value % 1 == 0
	end
end

function Validators.string(maxLength: number): Validator
	return function(value)
		return type(value) == "string" and #value <= maxLength and utf8.len(value) ~= nil
	end
end

function Validators.boolean(): Validator
	return function(value)
		return type(value) == "boolean"
	end
end

function Validators.vector3(maxMagnitude: number): Validator
	return function(value)
		if typeof(value) ~= "Vector3" then
			return false
		end
		local v = value :: Vector3
		if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
			return false
		end
		return v.Magnitude <= maxMagnitude
	end
end

function Validators.instanceOf(className: string, ancestor: Instance?): Validator
	return function(value)
		if typeof(value) ~= "Instance" then
			return false
		end
		local instance = value :: Instance
		if not instance:IsA(className) then
			return false
		end
		return ancestor == nil or instance:IsDescendantOf(ancestor)
	end
end

function Validators.oneOf(options: { any }): Validator
	local set = {}
	for _, option in options do
		set[option] = true
	end
	return function(value)
		return set[value] == true
	end
end

-- Servidor ------------------------------------------------------------------
export type ServerSignal = {
	Name: string,
	Connect: (self: ServerSignal, handler: Handler) -> RBXScriptConnection,
	FireClient: (self: ServerSignal, player: Player, ...any) -> (),
	FireAllClients: (self: ServerSignal, ...any) -> (),
	Destroy: (self: ServerSignal) -> (),
}

local ServerSignal = {}
ServerSignal.__index = ServerSignal

local function newServer(options: ServerOptions): ServerSignal
	assert(IS_SERVER, "RemoteSignal.server solo puede usarse en el servidor")
	local folder = getRemotesFolder()
	assert(folder:FindFirstChild(options.Name) == nil, "RemoteSignal duplicado: " .. options.Name)

	local remote = Instance.new("RemoteEvent")
	remote.Name = options.Name
	remote.Parent = folder

	local self = setmetatable({}, ServerSignal) :: any
	self.Name = options.Name
	self._remote = remote
	self._options = options
	self._buckets = {} :: { [Player]: { count: number, windowStart: number } }
	self._leaveConnection = Players.PlayerRemoving:Connect(function(player)
		self._buckets[player] = nil
	end)
	return self :: ServerSignal
end

function ServerSignal:_passesMiddleware(player: Player, ...: any): boolean
	local options: ServerOptions = self._options

	-- (1) Authentication: el jugador debe seguir conectado al servidor.
	if player.Parent ~= Players then
		return false
	end

	-- (2) Rate limit por jugador y por remote (ventana fija).
	local limit = options.RateLimit or NETWORK.DefaultRateLimit
	local window = options.RateWindowSeconds or NETWORK.DefaultRateWindowSeconds
	local now = os.clock()
	local bucket = self._buckets[player]
	if bucket == nil or now - bucket.windowStart >= window then
		bucket = { count = 0, windowStart = now }
		self._buckets[player] = bucket
	end
	bucket.count += 1
	if bucket.count > limit then
		reportViolation(player, self.Name, "rate limit")
		return false
	end

	-- (3) Type validation: número exacto de argumentos y cada uno validado.
	local count = select("#", ...)
	if count ~= #options.Args then
		reportViolation(player, self.Name, "número de argumentos")
		return false
	end
	for index, validator in options.Args do
		local ok, valid = pcall(validator, (select(index, ...)))
		if not ok or not valid then
			reportViolation(player, self.Name, "argumento " .. index .. " inválido")
			return false
		end
	end

	-- (4) Sanity / distance check específico del remote.
	if options.Sanity then
		local ok, sane = pcall(options.Sanity, player, ...)
		if not ok or not sane then
			reportViolation(player, self.Name, "sanity check")
			return false
		end
	end

	return true
end

function ServerSignal:Connect(handler: Handler): RBXScriptConnection
	return self._remote.OnServerEvent:Connect(function(player: Player, ...: any)
		if not self:_passesMiddleware(player, ...) then
			return
		end
		-- (5) Execution aislada: un error en el handler no tumba la conexión.
		local ok: boolean, err: any = pcall(handler, player, ...)
		if not ok then
			warn(string.format("[RemoteSignal] Error en %s: %s", self.Name, tostring(err)))
		end
	end)
end

function ServerSignal:FireClient(player: Player, ...: any)
	self._remote:FireClient(player, ...)
end

function ServerSignal:FireAllClients(...: any)
	self._remote:FireAllClients(...)
end

function ServerSignal:Destroy()
	self._leaveConnection:Disconnect()
	self._remote:Destroy()
	table.clear(self._buckets)
end

-- Cliente -------------------------------------------------------------------
export type ClientSignal = {
	Name: string,
	Fire: (self: ClientSignal, ...any) -> (),
	Connect: (self: ClientSignal, handler: (...any) -> ()) -> RBXScriptConnection,
}

local ClientSignal = {}
ClientSignal.__index = ClientSignal

local function newClient(name: string, timeoutSeconds: number?): ClientSignal
	assert(not IS_SERVER, "RemoteSignal.client solo puede usarse en el cliente")
	local remote = getRemotesFolder():WaitForChild(name, timeoutSeconds or 30)
	assert(remote and remote:IsA("RemoteEvent"), "RemoteSignal no encontrado: " .. name)

	local self = setmetatable({}, ClientSignal) :: any
	self.Name = name
	self._remote = remote
	return self :: ClientSignal
end

function ClientSignal:Fire(...: any)
	self._remote:FireServer(...)
end

function ClientSignal:Connect(handler: (...any) -> ()): RBXScriptConnection
	return self._remote.OnClientEvent:Connect(handler)
end

Players.PlayerRemoving:Connect(function(player)
	violations[player] = nil
end)

return {
	server = newServer,
	client = newClient,
	Validators = Validators,
}
