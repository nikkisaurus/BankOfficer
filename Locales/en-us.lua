local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(addon)

L[addonName] = "Bank Officer"
L["Invalid itemID"] = true
L["Invalid template name"] = true
L["Place"] = true
L["Save and add"] = true
L["Select template"] = true
L["Stack"] = true
L["Template already exists"] = true
L["Template Name"] = true

L.Tab = function(tabID)
	return tabID and ("Tab " .. tabID) or "Tab"
end
