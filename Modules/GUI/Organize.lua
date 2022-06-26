local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Local Functions ]]
local guilds, sort = {}, {}
local function GetGuildsList()
	wipe(guilds)
	wipe(sort)

	for guildKey, _ in BankOfficer.pairs(private.db.global.guilds) do
		guilds[guildKey] = guildKey
		tinsert(sort, guildKey)
	end

	return guilds, sort
end

local tabs = {}
local function GetTabs(guildKey)
	wipe(tabs)

	local guildDB = private.db.global.guilds[guildKey]

	for tab, tabInfo in pairs(guildDB) do
		tinsert(tabs, {
			value = tab,
			text = tabInfo[1],
		})
	end

	return tabs
end

local function tabs_OnGroupSelected(self, _, tab)
	print("load tab " .. tab)
end

local slots = {}
local function selectGuild_OnValueChanged(self, _, guildKey)
	local parent = self.parent
	local tabs = parent.children[2]

	tabs:SetTabs(GetTabs(guildKey))

	for i = 1, 98 do
		local icon = AceGUI:Create("Icon")
		icon:SetImage([[INTERFACE/ADDONS/BANKOFFICER/MEDIA/UI-SLOT-BACKGROUND]])
		icon:SetCallback("OnClick", function()
			print(i)
		end)
		tinsert(slots, icon)
	end

	tabs:AddChildren(unpack(slots))
end

--[[ Private ]]
function private:DrawOrganizeContent(parent)
	local selectGuild = AceGUI:Create("Dropdown")
	selectGuild:SetFullWidth(true)
	selectGuild:SetList(GetGuildsList())
	selectGuild:SetCallback("OnValueChanged", selectGuild_OnValueChanged)

	local tabs = AceGUI:Create("TabGroup")
	private:EmbedMethods(tabs, { "Container" })
	tabs:SetLayout("BankOfficer_GuildBankTab")
	tabs:SetHeight(0)
	tabs:SetFullWidth(true)
	tabs:SetCallback("OnGroupSelected", tabs_OnGroupSelected)

	parent:AddChildren(selectGuild, tabs)
end
