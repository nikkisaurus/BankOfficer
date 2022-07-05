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
-- EditMode
local function duplicateMode_OnClick(self)
	self.parent:NotifyChange()
	if private.status.editMode == "duplicate" then
		private.status.editMode = nil
		ClearCursor()
	else
		private.status.editMode = "duplicate"
		self.image:SetVertexColor(1, 0.82, 0)
	end
end

local function clearMode_OnClick(self)
	self.parent:NotifyChange()
	if private.status.editMode == "clear" then
		private.status.editMode = nil
		ClearCursor()
	else
		private.status.editMode = "clear"
		self.image:SetVertexColor(1, 0.82, 0)
	end
end

-- Draw tabs and slots
local function selectGuild_OnValueChanged(self, _, guildKey)
	private.status.guildKey = guildKey

	local parent = self.parent
	local tabs = parent.children[#parent.children]

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
			BankOfficer:Unhook(slot.frame, "OnDragStart")
			BankOfficer:Unhook(slot.frame, "OnDragStop")
			BankOfficer:Unhook(slot.frame, "OnReceiveDrag")
		end)
		BankOfficer:HookScript(slot.frame, "OnDragStart", private.OrganizeSlot_OnDragStart)
		BankOfficer:HookScript(slot.frame, "OnDragStop", private.OrganizeSlot_OnDragStop)
		BankOfficer:HookScript(slot.frame, "OnReceiveDrag", private.OrganizeSlot_OnReceiveDrag)

		tabs:AddChild(slot)
	end

	tabs:SelectTab(1)
	parent.children[2]:NotifyChange() -- Update controls
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

	-- Controls
	local controls = AceGUI:Create("InlineGroup")
	private:EmbedMethods(controls, { "Container" })
	controls:SetLayout("Flow")
	controls:SetFullWidth(true)

	controls:OnNotifyChange(function()
		local children = controls.children
		for _, child in pairs(children) do
			if child.SetDisabled then
				child:SetDisabled(not private.status.guildKey)
			end
			if child.image then
				child.image:SetVertexColor(1, 1, 1)
			end
		end
	end)

	local templateMode = AceGUI:Create("Dropdown")
	private:EmbedMethods(templateMode, {})
	templateMode:SetList({})

	local duplicateMode = AceGUI:Create("Icon")
	private:EmbedMethods(duplicateMode, {})
	duplicateMode:SetImage(self.media .. [[clone-solid]])
	duplicateMode:SetImageSize(14, 14)
	duplicateMode:SetSize(20, 20)
	duplicateMode:SetTooltip("ANCHOR_TOPRIGHT ", 0, 0, { { L["Duplicate Mode"] } })
	duplicateMode:SetCallback("OnClick", duplicateMode_OnClick)

	local clearMode = AceGUI:Create("Icon")
	private:EmbedMethods(clearMode, {})
	clearMode:SetImage(self.media .. [[ban-solid]])
	clearMode:SetImageSize(14, 14)
	clearMode:SetSize(20, 20)
	clearMode:SetTooltip("ANCHOR_TOPRIGHT ", 0, 0, { { L["Clear Mode"] } })
	clearMode:SetCallback("OnClick", clearMode_OnClick)

	local editOrganizeSlot = AceGUI:Create("InlineGroup")
	private:EmbedMethods(editOrganizeSlot, { "Container" })
	editOrganizeSlot:SetLayout("Flow")
	editOrganizeSlot:SetFullWidth(true)

	controls:AddChildren(templateMode, duplicateMode, clearMode, editOrganizeSlot)
	controls:NotifyChange() -- Updates disabled status

	-- Tabs
	local tabs = AceGUI:Create("TabGroup")
	private:EmbedMethods(tabs, { "Container" })
	tabs:SetLayout("BankOfficer_GuildBankTab")
	tabs:SetHeight(0)
	tabs:SetFullWidth(true)
	tabs:SetCallback("OnGroupSelected", tabs_OnGroupSelected)

	parent:AddChildren(selectGuild, controls, tabs)
end
