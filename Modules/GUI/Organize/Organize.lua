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
	ClearCursor()
	if private.status.organize.editMode == "clear" then
		private.status.organize.editMode = nil
	else
		private.status.organize.editMode = "clear"
		self.image:SetVertexColor(1, 0.82, 0)
	end
end

local function cancel_OnClick(self)
	self.parent:ReleaseChildren()
	private:DrawOrganizeContent(self.parent)
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

local function itemID_OnEnterPressed(self, itemID, slotID)
	itemID = private:ValidateItem(itemID)
	if not itemID then
		return
	end

	private:CacheItem(itemID)
	local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)

	if bindType and bindType ~= 1 then
		local slotInfo =
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID]
		local isEmpty = not slotInfo or not slotInfo.itemID

		if isEmpty then
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID] =
				{ itemID = itemID, stack = private.stack }
		else
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID].itemID =
				itemID
		end

		self.parent:NotifyChange()
		self:ClearFocus()
	end
end

local function stack_OnEnterPressed(self, stack, slotID)
	local slotInfo = private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID]
	local isEmpty = not slotInfo or not slotInfo.itemID
	if isEmpty then
		return
	end

	local func = loadstring("return " .. stack)
	if type(func) == "function" then
		local success, userFunc = pcall(func)
		if success and type(userFunc) == "function" then
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID].stack =
				stack
		end
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
	templateMode:SetLabel("Apply Template")
	templateMode:SetList(GetTemplates())
	templateMode:SetCallback("OnValueChanged", templateMode_OnValueChanged)

	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetWidth(10)

	local duplicateMode = AceGUI:Create("Icon")
	private:EmbedMethods(duplicateMode, {})
	duplicateMode:SetImage(self.media .. [[clone-solid]])
	duplicateMode:SetImageSize(14, 14)
	duplicateMode:SetSize(30, 20)
	duplicateMode:SetTooltip("ANCHOR_TOPRIGHT ", 0, 0, { { L["Duplicate Mode"] } })
	duplicateMode:SetCallback("OnClick", duplicateMode_OnClick)

	local clearMode = AceGUI:Create("Icon")
	private:EmbedMethods(clearMode, {})
	clearMode:SetImage(self.media .. [[ban-solid]])
	clearMode:SetImageSize(14, 14)
	clearMode:SetSize(30, 20)
	clearMode:SetTooltip("ANCHOR_TOPRIGHT ", 0, 0, { { L["Clear Mode"] } })
	clearMode:SetCallback("OnClick", clearMode_OnClick)

	controls:AddChildren(templateMode, spacer, duplicateMode, clearMode)
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

function private:EditOrganizeSlot(widget, slotID)
	local parent = widget.parent.parent
	parent:ReleaseChildren()

	local title = AceGUI:Create("Label")
	title:SetFullWidth(true)
	title:SetFontObject(GameFontNormalLarge)
	title:SetColor(1, 0.82, 0)
	title:SetText(widget:GetSlotTitle(slotID))

	local item = AceGUI:Create("Label")
	item:SetFullWidth(true)
	item:SetImageSize(16, 16)

	local itemID = AceGUI:Create("EditBox")
	itemID:SetLabel(L["Item ID"])
	itemID:SetCallback("OnEnterPressed", function(self, _, itemID)
		itemID_OnEnterPressed(self, itemID, slotID)
	end)

	local stack = AceGUI:Create("MultiLineEditBox")
	stack:SetFullWidth(true)
	stack:SetLabel(L["Stack"])
	stack:SetCallback("OnEnterPressed", function(self, _, func)
		stack_OnEnterPressed(self, func, slotID)
	end)

	local close = AceGUI:Create("Button")
	close:SetText(CLOSE)
	close:SetCallback("OnClick", cancel_OnClick)

	parent:AddChildren(title, item, itemID, stack, close)

	parent:OnNotifyChange(function()
		local slotInfo =
			private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slotID]
		local isEmpty = not slotInfo or not slotInfo.itemID
		local itemName
		if not isEmpty then
			private:CacheItem(slotInfo.itemID)
			itemName = GetItemInfo(slotInfo.itemID)
		end

		item:SetText(not isEmpty and itemName or "")
		item:SetImage(not isEmpty and GetItemIcon(slotInfo.itemID))

		itemID:SetText(not isEmpty and slotInfo.itemID or "")

		stack:SetText(not isEmpty and slotInfo.stack or "")

		parent:DoLayout()
	end)
	parent:NotifyChange()
end
