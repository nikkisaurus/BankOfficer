local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.stack = [[function()
    return 1
end]]

addon.InitializeDatabase = function()
	addon.db = LibStub("AceDB-3.0"):New("BankOfficerDB", {
		global = {
			templates = {
				["*"] = {
					enabled = false,
					itemID = nil,
					stackSize = addon.stack,
				},
			},
			settings = {
				frameScale = 1,
			},
			rules = {
				["*"] = {
					type = nil, -- tab|list
					guilds = {},
					tabs = {
						["*"] = {},
					},
					lists = {
						["*"] = {
							min = nil, -- min restock amount
							itemIDs = {
								["*"] = {
									enabled = false,
									guilds = {
										["*"] = {
											enabled = false,
											[1] = true,
											[2] = true,
											[3] = true,
											[4] = true,
											[5] = true,
											[6] = true,
											[7] = true,
											[8] = true,
										},
									},
								},
							},
						},
					},
				},
			},
			guilds = {
				["*"] = {
					tabsPurchased = false,
				},
			},
		},
	}, true)

	addon.db.global.guilds[addon.GetGuildKey()].tabsPurchased = GetNumGuildBankTabs()
end

addon.GetGuildKey = function()
	local guild = (GetGuildInfo("player"))
	local realm = GetRealmName()

	return format("%s - %s", guild, realm)
end

addon.GetGuild = function(guild)
	return addon.db.global.guilds[guild or addon.GetGuildKey()]
end
