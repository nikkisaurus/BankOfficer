local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local LGBC = LibStub("LibGuildBankComm-1.0")

function private:GetOrganizeOptions(guildKey, organize)
	local guild = private.db.global.guilds[guildKey]

	local options = {
		controls = {
			order = 1,
			type = "group",
			inline = true,
			name = "",
			get = function(info)
				return private.organizeEditMode == info[#info]
			end,
			name = "",
			set = function(info, value)
				private.organizeEditMode = value and info[#info]
				ClearCursor()
			end,
			args = {
				duplicate = {
					order = 1,
					type = "toggle",
					name = L["Duplicate Mode"],
				},
				clear = {
					order = 2,
					type = "toggle",
					name = L["Clear Mode"],
				},
			},
		},
		organize = {
			order = 2,
			type = "input",
			dialogControl = "BankOfficer_OrganizeGroup",
			width = "full",
			name = guildKey,
		},
	}

	-- for tab = 1, guild.numTabs do
	-- 	options["tab" .. tab] = {
	-- 		order = tab,
	-- 		type = "group",
	-- 		name = format("%s %d", L["Tab"], tab),
	-- 		set = function()
	-- 			print(tab)
	-- 		end,
	-- 		args = {
	-- 			organizeGroup = {
	-- 				type = "input",
	-- 				dialogControl = "BankOfficer_OrganizeGroup",
	-- 				width = "full",
	-- 				name = "",
	-- 				validate = function()
	-- 					return tab
	-- 				end,
	-- 				arg = function(...)
	-- 					print(...)
	-- 				end,
	-- 			},
	-- 		},
	-- 	}
	-- end

	return options
end
