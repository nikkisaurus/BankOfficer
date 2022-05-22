local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local COLS = 14
local ROWS = 7

local function GetSlotID(row, col)
	return format("%d.%d", row, col)
end

-- Lists
local function GetTemplates()
	local templates = {}
	local order = {}

	templates["__none"] = NONE
	tinsert(order, "__none")

	templates["__clear"] = L["Clear Slot"]
	tinsert(order, "__clear")

	for templateName, templateInfo in addon.pairs(addon.db.global.templates) do
		if templateInfo.enabled then
			templates[templateName] = templateName
			tinsert(order, templateName)
		end
	end

	return templates, order
end

-- Load
private.LoadTab = function(scrollFrame, tabID)
	private.status.tabID = tabID

	local quickAddTemplateDropdown = AceGUI:Create("Dropdown")
	quickAddTemplateDropdown:SetUserData("elementName", "quickAddTemplateDropdown")
	quickAddTemplateDropdown:SetFullWidth(true)
	quickAddTemplateDropdown:SetList(GetTemplates())
	quickAddTemplateDropdown:SetLabel(L["Quick-add template"])
	quickAddTemplateDropdown:SetCallback("OnValueChanged", function(_, _, value)
		private.status.quickAddTemplate = value ~= "__none" and value
		if value == "__none" then
			quickAddTemplateDropdown:SetValue()
		end
	end)

	private.AddChildren(scrollFrame, { quickAddTemplateDropdown })

	if private.status.quickAddTemplate then
		quickAddTemplateDropdown:SetValue(private.status.quickAddTemplate)
	end

	for row = 1, ROWS do
		for col = 1, COLS do
			local slotButton = AceGUI:Create("BankOfficerSlotButton")
			slotButton:SetUserData("elementName", "slotButton_" .. GetSlotID(row, col))
			slotButton:SetRelativeWidth(1 / 14.25)
			private.AddChildren(scrollFrame, { slotButton })
			slotButton:SetSlotID(private.status.ruleName, tabID, GetSlotID(row, col))
		end
	end
	scrollFrame:DoLayout()

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(scrollFrame, { statusLabel })
end
