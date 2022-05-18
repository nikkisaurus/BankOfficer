local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

private.CreateCoroutine = function(func)
	private.co = coroutine.create(func)
end

addon.Debug = function()
	private.frame:Show()

	local tabGroup = private.GetChild(private.frame, "tabGroup")
	local ruleGroup = private.GetChild(tabGroup, "ruleGroup")
	ruleGroup:SetGroup("Born of Blood - List")
	private.GetChild(ruleGroup, "treeGroup"):SelectByPath("lists", "Default")
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
