local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:GetSettingsOptions(guildKey)
	local options = {
		defaultGuild = {
			order = 1,
			type = "toggle",
			name = L["Set as default guild"],
			get = function()
				return private.db.global.settings.defaultGuild == guildKey
			end,
			set = function()
				private.db.global.settings.defaultGuild = guildKey
			end,
		},
	}

	return options
end
