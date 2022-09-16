local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

function private:CloseOptions()
	ACD:Close(addonName)
end

function private:GetGuilds()
	local options = {}

	for guildKey, guild in pairs(private.db.global.guilds) do
		options[guildKey] = {
			type = "group",
			name = guildKey,
			args = {
				scanBank = {
					order = 1,
					type = "execute",
					name = L["Scan"],
					func = function()
						private:GetBankRestock()
					end,
				},
				organizeBank = {
					order = 2,
					type = "execute",
					name = L["Organize"],
					func = function()
						private:OrganizeBank()
					end,
				},
				restock = {
					order = 3,
					type = "group",
					name = L["Restock"],
					childGroups = "select",
					args = private:GetRestockRules(guildKey, guild.restock),
				},
				organize = {
					order = 4,
					type = "group",
					name = L["Organize"],
					args = private:GetOrganizeOptions(guildKey, guild.organize),
				},
				review = {
					order = 5,
					type = "group",
					name = L["Review"],
					childGroups = "select",
					args = private:GetReviewOptions(guildKey, guild.scans),
				},
				settings = {
					order = 6,
					type = "group",
					name = L["Settings"],
					args = private:GetSettingsOptions(guildKey),
				},
			},
		}
	end

	return options
end

function private:GetOptions()
	local options = {
		type = "group",
		name = L.addonName,
		childGroups = "select",
		args = private:GetGuilds(),
	}

	return options
end

function private:InitializeOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, private:GetOptions())
	private.options = ACR:GetOptionsTable(addonName, "dialog", addonName .. "-1.0")
	private.frame = AceGUI:Create("Frame")
	private.frame:Hide()
	private.organizeContextMenu =
		CreateFrame("Frame", "BankOfficer_OrganizeContextMenu", UIParent, "UIDropDownMenuTemplate")
end

function private:OpenOptions(...)
	private.optionsPath = { ... }
	ACD:SelectGroup(addonName, ...)
	ACD:Open(addonName, private.frame)
end

function private:RefreshOptions(...)
	private.options.args = private:GetGuilds()
	ACR:NotifyChange(addonName)

	if ... then
		ACD:SelectGroup(addonName, ...)
	end
end
