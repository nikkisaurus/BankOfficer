local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(BankOfficer)
private.status = {
	organize = {},
	restock = {},
	review = {},
}
private.media = [[INTERFACE/ADDONS/BANKOFFICER/MEDIA/]]

L.addonName = "Bank Officer"

L["Restock"] = true
L["Organize"] = true
L["Review"] = true
L["Settings"] = true
L["Tab"] = true
L["Clear Slot"] = true
L["Duplicate Slot"] = true
L["Edit Slot"] = true
L["Clear Mode"] = true
L["Duplicate Mode"] = true
L["Template Mode"] = true
L["Item ID"] = true
L["None"] = true
