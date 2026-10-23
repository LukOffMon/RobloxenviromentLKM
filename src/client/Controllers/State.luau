--!strict
-- Estado del jugador tal como lo envía el servidor. Solo lectura para la UI.

local State = {}

-- Vista completa del perfil (ver fullView en Main.server). Nil hasta que llega del servidor.
State.Profile = nil :: any

local changed = Instance.new("BindableEvent")
-- (kind: "Full" | "Currency")
State.Changed = changed.Event

function State.setFull(view: any)
	State.Profile = view
	changed:Fire("Full")
end

function State.setCurrencies(view: any)
	if State.Profile == nil then
		return
	end
	for key, value in view do
		State.Profile[key] = value
	end
	changed:Fire("Currency")
end

return State
