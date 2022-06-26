local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Local List Functions ]]
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

--[[ Local Functions ]]
-- Draw tabs and slots
local function selectGuild_OnValueChanged(self, _, guildKey)
	private.status.guildKey = guildKey

	local parent = self.parent
	local tabs = parent.children[2]

	tabs:SetTabs(GetTabs(guildKey))

	for slotID = 1, 98 do
		local slot = AceGUI:Create("Icon")
		slot:SetUserData("slotID", slotID)
		slot.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		slot.frame:RegisterForDrag("LeftButton")
		slot:SetCallback("OnClick", private.OrganizeSlot_OnClick)
		slot:SetCallback("OnRelease", function()
			slot.frame:RegisterForClicks("LeftButtonUp")
			slot.frame:RegisterForDrag()
			slot.frame:HookScript("OnDragStart")
			slot.frame:HookScript("OnDragStop")
			slot.frame:HookScript("OnReceiveDrag")
		end)
		slot.frame:HookScript("OnDragStart", private.OrganizeSlot_OnDragStart)
		slot.frame:HookScript("OnDragStop", private.OrganizeSlot_OnDragStop)
		slot.frame:HookScript("OnReceiveDrag", private.OrganizeSlot_OnReceiveDrag)

		tabs:AddChild(slot)
	end

	tabs:SelectTab(1)
end

-- Load tab info onto slots
local function tabs_OnGroupSelected(self, _, tab)
	private.status.tab = tab

	for slotID = 1, 98 do
		private:LoadOrganizeSlotItem(self.children[slotID])
	end
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
