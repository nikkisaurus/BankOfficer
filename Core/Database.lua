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
									col = 0,
									row = 0,
									item = {
										itemID = false,
										minQty = 1,
										maxQty = 20,
										restock = false, --min, max, false
									},
								},
							},
						},
					},
				},
			},
		},
	}, true)
end
