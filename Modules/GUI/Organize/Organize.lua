local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Locals ]]
-- Lists
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
	if not guildDB then
		return tabs
	end

	for tab, tabInfo in pairs(guildDB) do
		tinsert(tabs, {
			value = tab,
			text = tabInfo[1],
		})
	end

	return tabs
end

local templates = {}
local function GetTemplates()
	wipe(templates)
	wipe(sort)

	for templateName, templateInfo in BankOfficer.pairs(private.db.global.templates) do
		templates[templateName] = templateName
		tinsert(sort, templateName)
	end

	templates["BANKOFFICER_TEMPLATE_NONE"] = L["None"]
	tinsert(sort, "BANKOFFICER_TEMPLATE_NONE")

	return templates, sort
end

--[[ Script handlers ]]
local function duplicateMode_OnClick(self)
	self.parent:NotifyChange()
	if private.status.organize.editMode == "duplicate" then
		private.status.organize.editMode = nil
		ClearCursor()
	else
		private.status.organize.editMode = "duplicate"
		self.image:SetVertexColor(1, 0.82, 0)
	end
end

local function clearMode_OnClick(self)
	self.parent:NotifyChange()
	if private.status.organize.editMode == "clear" then
		private.status.organize.editMode = nil
		ClearCursor()
	else
		private.status.organize.editMode = "clear"
		self.image:SetVertexColor(1, 0.82, 0)
	end
end

local function selectGuild_OnValueChanged(self, _, guildKey)
	private.status.organize.guildKey = guildKey

	local parent = self.parent
	local tabs = parent.children[#parent.children]

	tabs:SetTabs(GetTabs(guildKey))
	tabs:ReleaseChildren()

	if private.status.organize.guildKey then
		for slotID = 1, 98 do
			local slot = AceGUI:Create("BankOfficerOrganizeSlot")
			slot:SetUserData("slotID", slotID)
			slot:LoadSlot()

			--slot:SetCallback("OnClick", private.OrganizeSlot_OnClick)
			--slot:SetCallback("OnRelease", function()
			--	slot.frame:RegisterForClicks("LeftButtonUp")
			--	slot.frame:RegisterForDrag()
			--	BankOfficer:Unhook(slot.frame, "OnDragStart")
			--	BankOfficer:Unhook(slot.frame, "OnDragStop")
			--	BankOfficer:Unhook(slot.frame, "OnReceiveDrag")
			--end)
			--BankOfficer:HookScript(slot.frame, "OnDragStart", private.OrganizeSlot_OnDragStart)
			--BankOfficer:HookScript(slot.frame, "OnDragStop", private.OrganizeSlot_OnDragStop)
			--BankOfficer:HookScript(slot.frame, "OnReceiveDrag", private.OrganizeSlot_OnReceiveDrag)

			tabs:AddChild(slot)
		end
	end

	if not private.status.organize.tab then
		tabs:SelectTab(1)
	end

	parent.children[2]:NotifyChange() -- Update controls
end

local function tabs_OnGroupSelected(self, _, tab)
	private.status.organize.tab = tab or 1

	for _, child in pairs(self.children) do
		child:LoadSlot()
	end
end

local function templateMode_OnValueChanged(self, _, templateName)
	if templateName == "BANKOFFICER_TEMPLATE_NONE" then
		self:SetText("")
		ClearCursor()
	else
		private.status.organize.editMode = "duplicate"
		local templateInfo = private.db.global.templates[templateName]
		private.status.organize.cursorInfo = templateInfo
		PickupItem(templateInfo.itemID)
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
				child:SetDisabled(not private.status.organize.guildKey)
			end
			if child.image then
				child.image:SetVertexColor(1, 1, 1)
			end
		end
	end)

	local templateMode = AceGUI:Create("Dropdown")
	private:EmbedMethods(templateMode, {})
	templateMode:SetList(GetTemplates())
	templateMode:SetCallback("OnValueChanged", templateMode_OnValueChanged)

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

	controls:AddChildren(templateMode, duplicateMode, clearMode)
	controls:NotifyChange() -- Updates disabled status

	-- Tabs
	local tabs = AceGUI:Create("TabGroup")
	private:EmbedMethods(tabs, { "Container" })
	tabs:SetLayout("BankOfficer_GuildBankTab")
	tabs:SetHeight(0)
	tabs:SetFullWidth(true)
	tabs:SetCallback("OnGroupSelected", tabs_OnGroupSelected)

	parent:AddChildren(selectGuild, controls, tabs)

	C_Timer.After(private.status.organize.guildKey and 0 or 0.1, function()
		selectGuild:SetValue(private.status.organize.guildKey or private.db.global.settings.defaultGuild)
		selectGuild:Fire("OnValueChanged", private.status.organize.guildKey or private.db.global.settings.defaultGuild)
	end)
end
