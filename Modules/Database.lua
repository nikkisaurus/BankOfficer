local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:InitializeDatabase()
	self.db = LibStub("AceDB-3.0"):New("BankOfficerDB", {
		global = {
			debug = {
				enabled = true,
				frames = {
					BankOfficerFrame = true,
				},
			},
			guilds = {},
			organize = {
				["*"] = {
					["*"] = {},
				},
			},
		},
	}, true)

	self:InitializeGuild()
end

--[[ Guild ]]
local tabs = {}

function private:InitializeGuild()
	local guild = (GetGuildInfo("player"))
	local realm = GetRealmName()
	self.guildKey = realm and format("%s - %s", guild, realm)

	wipe(tabs)

	for tab = 1, MAX_GUILDBANK_TABS do
		QueryGuildBankTab(tab)
		C_Timer.After(0.01, function()
			local name, icon, viewable = GetGuildBankTabInfo(tab)
			if name then
				tabs[tab] = { name, icon, viewable }
			end
		end)
	end

	self.db.global.guilds[self.guildKey] = tabs
end
