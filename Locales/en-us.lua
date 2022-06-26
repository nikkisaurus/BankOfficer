local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(BankOfficer)
private.status = {}

L.addonName = "Bank Officer"

L["Restock"] = true
L["Organize"] = true
L["Review"] = true
L["Settings"] = true
L["Tab"] = true
