local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.PLAYER_ENTERING_WORLD = function()
	C_Timer.After(2, function()
		addon.OptionsFrame:Show()
		addon.OptionsFrame:GetUserData("children").optionsTree:SelectByPath(1)
	end)
end

local function EnableDebug()
	addon:RegisterEvent("PLAYER_ENTERING_WORLD")
end

addon.OnEnable = function()
	addon.InitializeDatabase()
	addon:RegisterChatCommand("bo", addon.HandleSlashCommand)

	--EnableDebug()
end
