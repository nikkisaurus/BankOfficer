local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:InitializeDatabase()
	private.db = LibStub("AceDB-3.0"):New("BankOfficerDevDB", {
		global = {
			-- debug = true,
			guilds = {},
			templates = {},
			settings = {
				dateFormat = "%x (%I:%M %p)", -- "%x (%X)"
				commands = {
					bo = true,
					bankofficer = true,
				},
			},
		},
	}, true)

	private:InitializeGuild()
end

function private:InitializeGuild()
	local guild = (GetGuildInfo("player"))
	local realm = GetRealmName()

	if not guild or not realm then
		C_Timer.After(0.1, function()
			private:InitializeGuild()
		end)
		return
	end

	private.guildKey = realm and format("%s - %s", guild, realm)
	private.db.global.guilds[private.guildKey] = private.db.global.guilds[private.guildKey]
		or addon.CloneTable(private.defaults.guild)
	local tabs = private.db.global.guilds[private.guildKey].tabs
	private.db.global.guilds[private.guildKey].numTabs = GetNumGuildBankTabs()

	wipe(tabs)

	for tab = 1, GetNumGuildBankTabs() do
		QueryGuildBankTab(tab)
		C_Timer.After(0.01, function()
			local name, icon, viewable = GetGuildBankTabInfo(tab)
			if name then
				tabs[tab] = { name, icon, viewable }
			end
		end)
	end
end

private.defaults = {
	guild = {
		tabs = {},
		organize = {},
		restock = {},
		restockTabs = {},
		scans = {},
	},
	restockRule = {
		quantity = 1,
		ids = {},
	},
	stack = [[function()
	return 1
end]],
}
