--!strict
-- Promise compacta (Promises/A+) para flujos asíncronos con yield de Roblox.
-- Soporta: new, resolve, reject, all, delay, retry, andThen, catch, finally, await.

export type Status = "Pending" | "Resolved" | "Rejected"

export type Promise = {
	andThen: (self: Promise, onResolved: ((...any) -> ...any)?, onRejected: ((...any) -> ...any)?) -> Promise,
	catch: (self: Promise, onRejected: (...any) -> ...any) -> Promise,
	finally: (self: Promise, callback: () -> ()) -> Promise,
	await: (self: Promise) -> (boolean, ...any),
	expect: (self: Promise) -> ...any,
	getStatus: (self: Promise) -> Status,
}

local Promise = {}
Promise.__index = Promise

local function isPromise(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Promise
end

function Promise.new(executor: (resolve: (...any) -> (), reject: (...any) -> ()) -> ()): Promise
	local self = setmetatable({}, Promise) :: any
	self._status = "Pending" :: Status
	self._values = {} :: { any }
	self._valuesCount = 0
	self._queue = {} :: { () -> () }
	self._waiting = {} :: { thread }

	local function settle(status: Status, ...: any)
		if self._status ~= "Pending" then
			return
		end
		self._status = status
		self._values = table.pack(...)
		self._valuesCount = select("#", ...)
		local queue = self._queue
		self._queue = {}
		for _, callback in queue do
			task.spawn(callback)
		end
		for _, waiting in self._waiting do
			task.spawn(waiting)
		end
		self._waiting = {}
	end

	local function resolve(...: any)
		local first = ...
		if isPromise(first) then
			(first :: any):andThen(function(...)
				settle("Resolved", ...)
			end, function(...)
				settle("Rejected", ...)
			end)
		else
			settle("Resolved", ...)
		end
	end

	local function reject(...: any)
		settle("Rejected", ...)
	end

	task.spawn(function()
		local ok: boolean, err: any = pcall(executor, resolve, reject)
		if not ok then
			reject(err)
		end
	end)

	return self :: Promise
end

function Promise.resolve(...: any): Promise
	local values = table.pack(...)
	return Promise.new(function(resolve)
		resolve(table.unpack(values, 1, values.n))
	end)
end

function Promise.reject(...: any): Promise
	local values = table.pack(...)
	return Promise.new(function(_, reject)
		reject(table.unpack(values, 1, values.n))
	end)
end

function Promise.delay(seconds: number): Promise
	return Promise.new(function(resolve)
		resolve(task.wait(seconds))
	end)
end

function Promise.all(promises: { Promise }): Promise
	return Promise.new(function(resolve, reject)
		local results = table.create(#promises)
		local remaining = #promises
		if remaining == 0 then
			resolve(results)
			return
		end
		for index, promise in promises do
			promise:andThen(function(value)
				results[index] = value
				remaining -= 1
				if remaining == 0 then
					resolve(results)
				end
			end, reject)
		end
	end)
end

function Promise.retry(callback: (...any) -> Promise, attempts: number, waitSeconds: number, ...: any): Promise
	local args = table.pack(...)
	return Promise.new(function(resolve, reject)
		local lastError: any = nil
		for attempt = 1, attempts do
			local ok, result = callback(table.unpack(args, 1, args.n)):await()
			if ok then
				resolve(result)
				return
			end
			lastError = result
			if attempt < attempts then
				task.wait(waitSeconds * attempt)
			end
		end
		reject(lastError)
	end)
end

function Promise:andThen(onResolved, onRejected)
	return Promise.new(function(resolve, reject)
		local function run()
			local handler = if self._status == "Resolved" then onResolved else onRejected
			if handler == nil then
				if self._status == "Resolved" then
					resolve(table.unpack(self._values, 1, self._valuesCount))
				else
					reject(table.unpack(self._values, 1, self._valuesCount))
				end
				return
			end
			local results = table.pack(pcall(handler, table.unpack(self._values, 1, self._valuesCount)))
			if results[1] then
				resolve(table.unpack(results, 2, results.n))
			else
				reject(results[2])
			end
		end
		if self._status == "Pending" then
			table.insert(self._queue, run)
		else
			run()
		end
	end)
end

function Promise:catch(onRejected)
	return self:andThen(nil, onRejected)
end

function Promise:finally(callback)
	return self:andThen(function(...)
		callback()
		return ...
	end, function(...)
		callback()
		error((...), 0)
	end)
end

function Promise:await(): (boolean, ...any)
	if self._status == "Pending" then
		table.insert(self._waiting, coroutine.running())
		coroutine.yield()
	end
	return self._status == "Resolved", table.unpack(self._values, 1, self._valuesCount)
end

function Promise:expect(): ...any
	local results = table.pack(self:await())
	if not results[1] then
		error(results[2], 2)
	end
	return table.unpack(results, 2, results.n)
end

function Promise:getStatus(): Status
	return self._status
end

Promise.is = isPromise

return Promise
