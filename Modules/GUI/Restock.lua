local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

function private:DrawRestockContent(parent)
	local selectGuild = AceGUI:Create("Dropdown")
	selectGuild:SetFullWidth(true)
	selectGuild:SetList(private:GetGuildsList())
	selectGuild:SetCallback("OnValueChanged", selectGuild_OnValueChanged)

	parent:AddChildren(selectGuild)

	C_Timer.After(private.status.restock.guildKey and 0 or 0.1, function()
		selectGuild:SetValue(private.status.restock.guildKey or private.db.global.settings.defaultGuild)
		selectGuild:Fire("OnValueChanged", private.status.restock.guildKey or private.db.global.settings.defaultGuild)
	end)
end
