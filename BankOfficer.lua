local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

private.CreateCoroutine = function(func)
	private.co = coroutine.create(func)
end

addon.Debug = function()
	private.LoadGUI()
	local tabGroup = private.GetChild(private.frame, "tabGroup")

	--private.status.ruleGroup:SetGroup("Born of Blood")
	--private.status.ruleTreeGroup:SelectByPath("tab1")

	--private.status.ruleGroup:SetGroup("Born of Blood - List")
	--private.status.ruleTreeGroup:SelectByPath("lists", "Enchants")

	private.status.tabGroup:SelectTab("templates")
	private.status.templateGroup:SetGroup("Test")
end

addon.OnEnable = function()
	addon:RegisterEvent("SPELLS_CHANGED")
	addon:RegisterChatCommand("bo", addon.HandleSlashCommand)
end

addon.SPELLS_CHANGED = function()
	addon.InitializeDatabase()
	private.InitializeGUI()
	addon.Debug()
	addon:UnregisterEvent("SPELLS_CHANGED")
end
