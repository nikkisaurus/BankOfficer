local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function GetGuilds()
	local rules = {}
	for guildKey, guild in pairs(addon.db.global.guilds) do
		rules[guildKey] = guildKey
	end
	return rules
end

local keys = {
	settings = MAX_GUILDBANK_TABS + 1,
}

local function GetOptionsTree(rule)
	local tree = {}
	local guild = addon.GetGuild(rule or addon.GetGuildKey())
	for i = 1, MAX_GUILDBANK_TABS do
		local disable = not guild.tabsPurchased or i > guild.tabsPurchased
		tinsert(tree, {
			value = i,
			text = L.Tab(i),
			disabled = disable,
		})
	end

	tinsert(tree, {
		value = keys.settings,
		text = SETTINGS,
	})

	return tree
end

local function SetSelectedRule(rule)
	local OptionsFrame = addon.OptionsFrame
	OptionsFrame:SetUserData("selected", rule)

	OptionsFrame:GetUserData("children").optionsTree:SetTree(GetOptionsTree(rule))
end

local function GetTemplates()
	local templates = {}
	local order = {}

	for templateKey, template in addon.pairs(addon.db.global.templates) do
		templates[templateKey] = templateKey
		tinsert(order, templateKey)
	end

	templates[NEW] = NEW
	tinsert(order, NEW)

	return templates, order
end

local function PlaceTemplate(template, texture, itemID, stack, templateName)
	addon.moveFrame.texture:SetTexture(texture)
	addon.moveFrame.slotInfo = { itemID = itemID, stack = stack, template = templateName }
	addon.moveFrame:Show()
	addon.OptionsFrame:GetUserData("children").selectTemplateButton:SetList(GetTemplates())
	addon.OptionsFrame
		:GetUserData("children").optionsTree
		:SelectByValue(addon.OptionsFrame:GetUserData("selectedTabID"))
end

local function SaveTemplate(template)
	local templateNameEditBox = addon.OptionsFrame:GetUserData("children").templateNameEditBox
	local selectTemplateButton = addon.OptionsFrame:GetUserData("children").selectTemplateButton
	local itemIDEditBox = addon.OptionsFrame:GetUserData("children").itemIDEditBox
	local stackEditBox = addon.OptionsFrame:GetUserData("children").stackEditBox
	local templateName = templateNameEditBox:GetText()

	if not templateName or templateName == "" or templateName == "New" then
		addon:Print(L["Invalid template name"])
		templateNameEditBox:SetFocus()
		templateNameEditBox:HighlightText()
	elseif template == NEW and addon.db.global.templates[templateName] then
		addon:Print(L["Template already exists"])
		templateNameEditBox:SetFocus()
		templateNameEditBox:HighlightText()
	else
		local itemID = tonumber(itemIDEditBox:GetText()) or 0
		addon.CacheItem(itemID, function(templateName, itemID, stack)
			local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
			if name then
				addon.db.global.templates[templateName] = {
					itemID = itemID,
					stack = stack,
					template = templateName,
				}
				if template == NEW then
					addon.OptionsFrame:GetUserData("children").addButton:SetText(UPDATE)
				end
			else
				addon:Print(L["Invalid itemID"])
				itemIDEditBox:SetFocus()
				itemIDEditBox:HighlightText()
			end
		end, templateName, itemID, stackEditBox:GetText())
	end
end

local function DeleteTemplate(templateName)
	if addon.db.global.templates[templateName] then
		--TODO confirmation before delete
		addon.db.global.templates[templateName] = nil
		addon.OptionsFrame
			:GetUserData("children").optionsTree
			:SelectByValue(addon.OptionsFrame:GetUserData("selectedTabID"))
	end
end

local AceGUI = LibStub("AceGUI-3.0")
local function AddTemplateToCursor(selectTemplateButton, _, template)
	local optionsTree = addon.OptionsFrame:GetUserData("children").optionsTree
	selectTemplateButton:SetValue()
	selectTemplateButton:SetText(L["Select template"])
	addon.OptionsFrame:GetUserData("children").selectTemplateButton = selectTemplateButton
	optionsTree:ReleaseChildren()
	local templateInfo = template ~= NEW and addon.db.global.templates[template]

	local templateNameEditBox = AceGUI:Create("EditBox")
	templateNameEditBox:SetText(template)
	templateNameEditBox:SetLabel(L["Template Name"])
	addon.OptionsFrame:GetUserData("children").templateNameEditBox = templateNameEditBox
	optionsTree:AddChild(templateNameEditBox)

	local itemIDEditBox = AceGUI:Create("EditBox")
	itemIDEditBox:SetText(template == NEW and "" or templateInfo.itemID)
	itemIDEditBox:SetLabel("itemID")
	addon.OptionsFrame:GetUserData("children").itemIDEditBox = itemIDEditBox
	optionsTree:AddChild(itemIDEditBox)

	local stackEditBox = AceGUI:Create("MultiLineEditBox")
	stackEditBox:SetText(template == NEW and addon.stack or templateInfo.stack)
	stackEditBox:SetLabel(L["Stack"])
	stackEditBox:SetFullWidth(true)
	addon.OptionsFrame:GetUserData("children").stackEditBox = stackEditBox
	optionsTree:AddChild(stackEditBox)

	local addButton = AceGUI:Create("Button")
	addButton:SetText(template == NEW and ADD or UPDATE)
	addon.OptionsFrame:GetUserData("children").addButton = addButton
	optionsTree:AddChild(addButton)
	addButton:SetCallback("OnClick", function(button)
		SaveTemplate(template)
	end)

	local placeButton = AceGUI:Create("Button")
	placeButton:SetText(L["Place"])
	addon.OptionsFrame:GetUserData("children").placeButton = placeButton
	optionsTree:AddChild(placeButton)
	placeButton:SetCallback("OnClick", function(...)
		local templateName = templateNameEditBox:GetText()
		local itemID = tonumber(itemIDEditBox:GetText()) or 0
		addon.CacheItem(itemID, function(templateName, itemID, stack)
			local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
			if name then
				addon.db.global.templates[templateName] = {
					itemID = itemID,
					stack = stack,
					template = templateName,
				}
				PlaceTemplate(template, texture, itemID, stack, templateName)
			end
		end, templateName, itemID, stackEditBox:GetText())
	end)

	local deleteButton = AceGUI:Create("Button")
	deleteButton:SetText(L["Delete"])
	addon.OptionsFrame:GetUserData("children").deleteButton = deleteButton
	optionsTree:AddChild(deleteButton)
	deleteButton:SetCallback("OnClick", DeleteTemplate(templateNameEditBox:GetText()))

	local cancelButton = AceGUI:Create("Button")
	cancelButton:SetText(CANCEL)
	optionsTree:AddChild(cancelButton)
	cancelButton:SetCallback("OnClick", function()
		optionsTree:SelectByValue(addon.OptionsFrame:GetUserData("selectedTabID"))
	end)
end

local function GetTabContent(optionsTree, _, tabID)
	optionsTree:ReleaseChildren()

	local guild = addon.GetGuild(addon.OptionsFrame:GetUserData("selected") or addon.GetGuildKey())

	if guild.tabsPurchased and tabID <= guild.tabsPurchased then
		for row = 1, 7 do
			for col = 1, 14 do
				addon.OptionsFrame:SetUserData("selectedTabID", tabID)
				addon.GetOptionsTabSlot(optionsTree, row, col)
			end
		end
	elseif tabID == keys.settings then
		--TODO Settings
	end
end

local function AddChild(childName, child)
	addon.OptionsFrame:AddChild(child)
	addon.OptionsFrame:GetUserData("children")[childName] = child
end

addon.InitializeOptions = function()
	local optionsContainer = AceGUI:Create("Window")
	optionsContainer:SetTitle(L[addonName])
	optionsContainer:SetLayout("Flow")
	optionsContainer:EnableResize(false)
	optionsContainer:SetWidth(825)
	optionsContainer:SetHeight(412)
	optionsContainer:SetUserData("children", {})
	optionsContainer:Hide()
	addon.OptionsFrame = optionsContainer

	local selectRuleButton = AceGUI:Create("Dropdown")
	selectRuleButton:SetList(GetGuilds())
	selectRuleButton:SetValue(addon.GetGuildKey())

	local selectTemplateButton = AceGUI:Create("Dropdown")
	selectTemplateButton:SetList(GetTemplates())
	selectTemplateButton:SetText(L["Select template"])
	selectTemplateButton:SetCallback("OnValueChanged", AddTemplateToCursor)

	local optionsTree = AceGUI:Create("TreeGroup")
	optionsTree:SetLayout("Flow")
	optionsTree:SetFullHeight(true)
	optionsTree:SetFullWidth(true)
	optionsTree:SetTree(GetOptionsTree())
	optionsTree:SetCallback("OnGroupSelected", GetTabContent)

	AddChild("selectRuleButton", selectRuleButton)
	AddChild("selectTemplateButton", selectTemplateButton)
	AddChild("optionsTree", optionsTree)

	selectRuleButton:SetCallback("OnValueChanged", SetSelectedRule())
end

addon.HandleSlashCommand = function()
	addon.OptionsFrame:Show()
end
