local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Lists
local function GetTemplates()
	local templates = {}
	local order = {}

	for templateName, _ in addon.pairs(addon.db.global.templates) do
		templates[templateName] = templateName
		tinsert(order, templateName)
	end

	templates["__new"] = L["Add Template"]
	tinsert(order, "__new")

	return templates, order
end

-- Database
local function AddTemplate(templateNameEditBox, _, templateName)
	local templateGroup = private.status.templateGroup
	local statusLabel = private.GetChild(templateGroup, "statusLabel")

	if not templateName or templateName == "" then
		return statusLabel:SetText(L["Missing template name"])
	elseif private.TemplateExists(templateName) then
		templateNameEditBox:HighlightText()
		return statusLabel:SetText(L.TemplateExists(templateName))
	elseif templateName == "__new" then
		templateNameEditBox:HighlightText()
		return statusLabel:SetText(L["Invalid template name"])
	end

	addon.db.global.templates[templateName].enabled = true
	statusLabel:SetText("")
	templateGroup:SetGroupList(GetTemplates())
	templateGroup:SetGroup(templateName)
end

private.TemplateExists = function(templateName)
	return addon.db.global.templates[templateName].enabled
end

private.UpdateTemplateInfo = function(templateName, key, value, isOpen)
	addon.db.global.templates[templateName or private.status.templateName][key] = value
	if isOpen then
		local itemID = addon.db.global.templates[templateName or private.status.templateName].itemID
		addon.CacheItem(itemID, function(itemID, private)
			local itemName, _, _, _, _, _, _, _, _, iconTexture = GetItemInfo(itemID)
			local itemIcon = private.GetChild(private.status.templateScrollFrame, "itemIcon")
			local itemIDEditBox = private.GetChild(private.status.templateScrollFrame, "itemIDEditBox")
			local statusLabel = private.GetChild(private.status.templateScrollFrame, "statusLabel")

			itemIcon:SetImage(iconTexture)
			itemIDEditBox:SetLabel(itemName)
			itemIDEditBox:SetText(itemID)
			statusLabel:SetText("")
		end, itemID, private)
	end
end

-- AddTemplateContent
local function AddTemplateContent()
	local templateNameEditBox = AceGUI:Create("EditBox")
	templateNameEditBox:SetUserData("elementName", "templateNameEditBox")
	templateNameEditBox:SetRelativeWidth(2 / 3)
	templateNameEditBox:SetLabel(NAME)
	templateNameEditBox:DisableButton(true)
	templateNameEditBox:SetCallback("OnEnterPressed", AddTemplate)

	local addTemplateButton = AceGUI:Create("Button")
	addTemplateButton:SetUserData("elementName", "addTemplateButton")
	addTemplateButton:SetRelativeWidth(1 / 3)
	addTemplateButton:SetText(ADD)
	addTemplateButton:SetCallback("OnClick", function()
		AddTemplate(templateNameEditBox, _, templateNameEditBox:GetText())
	end)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(private.status.templateScrollFrame, { templateNameEditBox, addTemplateButton, statusLabel })
end

-- Template content
local function itemIDEditBox_OnEnterPressed(itemIDEditBox, _, value)
	local itemID = tonumber(value)
	local statusLabel = private.GetChild(private.status.templateScrollFrame, "statusLabel")

	if not value or value == "" then
		itemIDEditBox:HighlightText()
		return statusLabel:SetText(L["Missing itemID"])
	elseif not itemID then
		itemIDEditBox:HighlightText()
		return statusLabel:SetText(L["Invalid itemID"])
	else
		itemID = GetItemInfoInstant(itemID)
		if not itemID or itemID == "" then
			itemIDEditBox:HighlightText()
			return statusLabel:SetText(L["Invalid itemID"])
		elseif itemID == addon.db.global.templates[private.status.templateName].itemID then
			itemIDEditBox:ClearFocus()
			return statusLabel:SetText("")
		end
	end

	addon.CacheItem(itemID, function(itemID, private, itemIDEditBox)
		local itemName, _, _, _, _, _, _, _, _, iconTexture, _, _, _, bindType = GetItemInfo(itemID)
		if bindType == 1 then
			itemIDEditBox:HighlightText()
			return statusLabel:SetText(L["Cannot add soulbound item to template"])
		end

		private.UpdateTemplateInfo(private.status.templateName, "itemID", itemID, true)
		itemIDEditBox:ClearFocus()
	end, itemID, private, itemIDEditBox)
end

local function TemplateContent()
	local template = addon.db.global.templates[private.status.templateName]
	local itemID = template.itemID

	local templateNameEditBox = AceGUI:Create("EditBox")
	templateNameEditBox:SetUserData("elementName", "templateNameEditBox")
	templateNameEditBox:SetFullWidth(true)
	templateNameEditBox:SetLabel(NAME)
	templateNameEditBox:SetText(private.status.templateName)
	templateNameEditBox:DisableButton(true)
	--templateNameEditBox:SetCallback("OnEnterPressed", templateNameEditBox_OnEnterPressed)

	local itemIcon = AceGUI:Create("Icon")
	itemIcon:SetUserData("elementName", "itemIcon")
	itemIcon:SetImage(itemID and GetItemIcon(itemID) or 134400)
	itemIcon:SetImageSize(40, 40)
	itemIcon:SetWidth(50)
	itemIcon:SetCallback("OnClick", function()
		local cursorType, itemID = GetCursorInfo()
		ClearCursor()
		if cursorType == "item" and itemID then
			addon.CacheItem(itemID, function(itemID, private)
				local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)
				if bindType == 1 then
					return private.GetChild(private.status.templateScrollFrame, "statusLabel"):SetText(
						L["Cannot add soulbound item to template"]
					)
				end

				private.UpdateTemplateInfo(private.status.templateName, "itemID", itemID, true)
			end, itemID, private)
		end
	end)

	local itemIDEditBox = AceGUI:Create("EditBox")
	itemIDEditBox:SetUserData("elementName", "itemIDEditBox")
	if itemID then
		addon.CacheItem(itemID, function(itemID, itemIDEditBox)
			local itemName = GetItemInfo(itemID)
			itemIDEditBox:SetLabel(itemName)
		end, itemID, itemIDEditBox)
	else
		itemIDEditBox:SetLabel(L["Enter ItemID:"])
	end
	itemIDEditBox:SetText(itemID or "")
	itemIDEditBox:DisableButton(true)
	itemIDEditBox:SetCallback("OnEnterPressed", itemIDEditBox_OnEnterPressed)

	local stackSizeEditBox = AceGUI:Create("MultiLineEditBox")
	stackSizeEditBox:SetUserData("elementName", "stackSizeEditBox")
	stackSizeEditBox:SetFullWidth(true)
	stackSizeEditBox:SetText(template.stackSize)
	stackSizeEditBox:SetLabel(L["Stack Size"])
	stackSizeEditBox:SetCallback("OnEnterPressed", function(_, _, value)
		--TODO Validate function return
		private.UpdateTemplateInfo(private.status.templateName, "stackSize", value)
	end)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(
		private.status.templateScrollFrame,
		{ templateNameEditBox, itemIcon, itemIDEditBox, stackSizeEditBox, statusLabel }
	)
end

-- Load
local function SelectTemplate(templateGroup, _, template)
	private.status.templateName = template
	templateGroup:ReleaseChildren()

	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetUserData("elementName", "scrollContainer")
	scrollContainer:SetUserData("children", {})
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	private.AddChildren(private.status.templateGroup, { scrollContainer })

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetUserData("elementName", "scrollFrame")
	scrollFrame:SetUserData("children", {})
	scrollFrame:SetLayout("Flow")
	private.AddChildren(scrollContainer, { scrollFrame })
	private.status.templateScrollFrame = scrollFrame

	if template == "__new" then
		AddTemplateContent()
	else
		TemplateContent()
	end
end

private.LoadTemplates = function(tabGroup)
	tabGroup:SetLayout("Fill")

	local templateGroup = AceGUI:Create("DropdownGroup")
	templateGroup:SetUserData("elementName", "templateGroup")
	templateGroup:SetUserData("children", {})
	templateGroup:SetGroupList(GetTemplates())
	templateGroup:SetCallback("OnGroupSelected", SelectTemplate)
	templateGroup:SetLayout("Flow")

	if private.status.templateName then
		templateGroup:SetGroup(private.status.templateName)
	end

	private.status.templateGroup = templateGroup

	return templateGroup
end
