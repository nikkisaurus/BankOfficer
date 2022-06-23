local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:InitializeDatabase()
	private.db = LibStub("AceDB-3.0"):New("BankOfficerDB", {
		global = {
			debug = {
				enabled = true,
				frames = {
					BankOfficerFrame = true,
				},
			},
			guilds = {},
		},
	}, true)

	private:InitializeGuild()
end

--[[ Guild ]]
local tabs = {}

function private:InitializeGuild()
	local guild = (GetGuildInfo("player"))
	local realm = GetRealmName()
	private.guildKey = realm and format("%s - %s", guild, realm)

	wipe(tabs)

	for tab = 1, 8 do
		QueryGuildBankTab(tab)
		C_Timer.After(0.01, function()
			local name, icon, viewable = GetGuildBankTabInfo(tab)
			if name then
				tabs[tab] = { name, icon, viewable }
			end
		end)
	end

	private.db.global.guilds[private.guildKey] = tabs
end
