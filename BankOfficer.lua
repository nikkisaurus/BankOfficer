local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.PLAYER_ENTERING_WORLD = function()
	LibStub("AceConfigDialog-3.0"):Open(addonName)
end

local function EnableDebug()
	addon:RegisterEvent("PLAYER_ENTERING_WORLD")
end

addon.OnEnable = function()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, addon.GetOptionsTable)
	addon:RegisterChatCommand("bo", addon.HandleSlashCommand)

	EnableDebug()
end
