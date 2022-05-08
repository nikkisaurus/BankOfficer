local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local ACD = LibStub("AceConfigDialog-3.0")
addon.HandleSlashCommand = function()
	ACD:Open(addonName)
end

addon.GetOptionsTable = function()
	local options = {
		type = "group",
		name = L[addonName],
		args = {},
	}

	return options
end
