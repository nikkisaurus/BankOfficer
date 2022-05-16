local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

private.CreateCoroutine = function(func)
	private.co = coroutine.create(func)
end

addon.Debug = function()
	C_Timer.After(2, function()
		private.frame:Show()
	end)
end

addon.OnEnable = function()
	addon:RegisterEvent("SPELLS_CHANGED")
	addon:RegisterChatCommand("bo", addon.HandleSlashCommand)
end

addon.SPELLS_CHANGED = function()
	addon.InitializeDatabase()
	private.InitializeGUI()
	--addon.Debug()
	addon:UnregisterEvent("SPELLS_CHANGED")
end
