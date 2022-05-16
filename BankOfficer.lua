local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.SPELLS_CHANGED = function()
	addon.InitializeDatabase()
	addon.InitializeOptions()
	addon.Debug()
	addon:UnregisterEvent("SPELLS_CHANGED")
end

addon.OnEnable = function()
	addon:RegisterEvent("SPELLS_CHANGED")
	addon:RegisterChatCommand("bo", addon.HandleSlashCommand)
end

addon.Debug = function()
	C_Timer.After(2, function()
		addon.OptionsFrame:Show()
		addon.OptionsFrame:GetUserData("children").optionsTree:SelectByPath(1)
	end)
end
