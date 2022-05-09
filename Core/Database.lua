local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.InitializeDatabase = function()
	addon.db = LibStub("AceDB-3.0"):New("BankOfficerDB", {
		global = {
			settings = {},
			guilds = {
				["*"] = {
					tabsPurchased = false,
					settings = {},
					tabs = {
						["*"] = {
							slots = {
								["*"] = {
									itemID = false,
									stack = [[function()
										return 1
									end]],
								},
							},
						},
					},
				},
			},
		},
	}, true)

	local guildKey = addon.GetGuildKey()

	C_Timer.After(1, function()
		addon.db.global.guilds[guildKey].tabsPurchased = GetNumGuildBankTabs()
	end)
end

addon.GetGuildKey = function()
	local guild = (GetGuildInfo("player"))
	local realm = GetRealmName()

	return format("%s - %s", guild, realm)
end

addon.GetGuild = function()
	return addon.db.global.guilds[addon.GetGuildKey()]
end
