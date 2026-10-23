--!strict
-- Efectos de sonido de caricatura. Usa sonidos que trae el cliente de Roblox (rbxasset://),
-- así funcionan sin subir audio. Para cambiarlos por audios propios, edita SOUNDS.

local SoundService = game:GetService("SoundService")

local SOUNDS = {
	Click = { Id = "rbxasset://sounds/button.wav", Volume = 0.5 },
	Knock = { Id = "rbxasset://sounds/button.wav", Volume = 1, Pitch = 0.45 },
	Reward = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 },
	Hit = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.5 },
	KO = { Id = "rbxasset://sounds/uuhhh.mp3", Volume = 0.7 },
}

export type SoundName = "Click" | "Knock" | "Reward" | "Hit" | "KO"

local Sounds = {}

function Sounds.play(name: SoundName, pitch: number?)
	local spec = (SOUNDS :: any)[name]
	if spec == nil then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = spec.Id
	sound.Volume = spec.Volume
	sound.PlaybackSpeed = pitch or spec.Pitch or 1
	sound.Parent = SoundService
	SoundService:PlayLocalSound(sound)
	task.delay(4, function()
		sound:Destroy()
	end)
end

return Sounds
