--!strict
-- Etiqueta dorada en el chat para el pase "VIP Director del Asilo".

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ChatTagController = {}

function ChatTagController.start()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local speaker = source and Players:GetPlayerByUserId(source.UserId)
		if speaker and speaker:GetAttribute("VIP") == true then
			properties.PrefixText = '<font color="#FFD700">[👑 Director]</font> ' .. message.PrefixText
		end
		return properties
	end
end

return ChatTagController
