--!strict
-- Punto de entrada del cliente: arranca controladores y escucha el estado del servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteSignal = require(ReplicatedStorage.Shared.Network.RemoteSignal)
local UIController = require(script.Parent.Controllers.UIController)

UIController.start()

local profileUpdated = RemoteSignal.client("ProfileUpdated")
profileUpdated:Connect(function(view)
	if type(view) == "table" then
		UIController.render(view)
	end
end)
