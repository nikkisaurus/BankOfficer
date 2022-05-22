local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(addon)
local private = {}

L[addonName] = "Bank Officer"

L["Add"] = true
L["Add ItemID"] = true
L["Add List"] = true
L["Add Rule"] = true
L["Apply rule to guilds"] = true
L["Apply list rule to guilds"] = true
L["Cannot add soulbound item to list rule"] = true
L["Control+click to remove from list"] = true
L["Duplicate"] = true
L["Guilds"] = true
L["ItemID exists in list rule"] = true
L["ItemIDs"] = true
L["Invalid itemID"] = true
L["List"] = true
L["Lists"] = true
L["Minimum Restock"] = true
L["Tab"] = true

L["Missing list name"] = true

L.DeleteList = function(ruleName, listName)
	return format('Are you sure you want to delete the list "%s" from "%s"?', listName, ruleName)
end
L.ListExists = function(listName)
	return format('List "%s" already exists', listName)
end

L["Invalid rule name"] = true
L["Missing rule name"] = true

L.DeleteRule = function(ruleName)
	return format('Are you sure you want to delete the rule "%s"?', ruleName)
end
L.RuleExists = function(ruleName)
	return format('Rule "%s" already exists', ruleName)
end
L.TabID = function(tabID)
	return tabID and ("Tab " .. tabID) or "Tab"
end
