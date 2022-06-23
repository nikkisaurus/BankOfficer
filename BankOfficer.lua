local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
LibStub("LibAddonUtils-1.0"):Embed(BankOfficer)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

private.addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
private.locale = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
private.status = {}

function private:unpack()
	return self.addon, self.locale, self.status
end

function BankOfficer:OnInitialize()
	private:InitializeDatabase()
end
