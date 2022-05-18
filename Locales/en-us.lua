local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(addon)
local private = {}

L[addonName] = "Bank Officer"

L["Add Rule"] = true
L["List"] = true
L["Tab"] = true

L["Invalid rule name"] = true
L["Missing rule name"] = true

L.RuleExists = function(ruleName)
	return format('Rule "%s" already exists', ruleName)
end

L.DeleteRule = function(ruleName)
	return format('Are you sure you want to delete the rule "%s"?', ruleName)
end

L.TabID = function(tabID)
	return tabID and ("Tab " .. tabID) or "Tab"
end
