--!strict
-- Janitor: limpieza determinista de conexiones, instancias, funciones y hilos.
-- Cada objeto agregado se destruye en orden inverso al llamar a :Cleanup() o :Destroy().

export type Cleanable = RBXScriptConnection | Instance | () -> () | thread | { Destroy: (any) -> () }

type Entry = { item: Cleanable, key: any? }

export type Janitor = {
	Add: <T>(self: Janitor, item: T & Cleanable, key: any?) -> T,
	Remove: (self: Janitor, key: any) -> boolean,
	Cleanup: (self: Janitor) -> (),
	Destroy: (self: Janitor) -> (),
	LinkToInstance: (self: Janitor, instance: Instance) -> RBXScriptConnection,
}

local Janitor = {}
Janitor.__index = Janitor

local function cleanItem(item: Cleanable)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		(item :: RBXScriptConnection):Disconnect()
	elseif kind == "Instance" then
		(item :: Instance):Destroy()
	elseif kind == "function" then
		(item :: () -> ())()
	elseif kind == "thread" then
		local co = item :: thread
		if coroutine.status(co) ~= "dead" then
			local cancelled = pcall(task.cancel, co)
			if not cancelled then
				coroutine.close(co)
			end
		end
	elseif kind == "table" then
		(item :: any):Destroy()
	end
end

function Janitor.new(): Janitor
	local self = setmetatable({}, Janitor) :: any
	self._entries = {} :: { Entry }
	self._cleaning = false
	return self :: Janitor
end

function Janitor:Add(item, key)
	if self._cleaning then
		cleanItem(item)
		return item
	end
	if key ~= nil then
		self:Remove(key)
	end
	table.insert(self._entries, { item = item, key = key })
	return item
end

function Janitor:Remove(key): boolean
	for index = #self._entries, 1, -1 do
		local entry = self._entries[index]
		if entry.key == key then
			table.remove(self._entries, index)
			cleanItem(entry.item)
			return true
		end
	end
	return false
end

function Janitor:Cleanup()
	if self._cleaning then
		return
	end
	self._cleaning = true
	local entries = self._entries
	self._entries = {}
	for index = #entries, 1, -1 do
		local ok: boolean, err: any = pcall(cleanItem, entries[index].item)
		if not ok then
			warn("[Janitor] Error al limpiar:", err)
		end
	end
	self._cleaning = false
end

function Janitor:Destroy()
	self:Cleanup()
	setmetatable(self, nil)
end

function Janitor:LinkToInstance(instance: Instance): RBXScriptConnection
	local connection = instance.Destroying:Connect(function()
		self:Cleanup()
	end)
	self:Add(connection)
	return connection
end

return Janitor
