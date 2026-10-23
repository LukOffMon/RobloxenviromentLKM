--!strict
-- Acceso perezoso a los remotes del cliente: cada uno se busca una sola vez.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteSignal = require(ReplicatedStorage.Shared.Network.RemoteSignal)

local cache: { [string]: RemoteSignal.ClientSignal } = {}

local Net = {}

function Net.get(name: string): RemoteSignal.ClientSignal
	local signal = cache[name]
	if signal == nil then
		signal = RemoteSignal.client(name)
		cache[name] = signal
	end
	return signal :: RemoteSignal.ClientSignal
end

return Net
