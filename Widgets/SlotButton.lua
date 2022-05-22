local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficerSlotButton"
local Version = 1

private.SLOTBUTTON_TEXTURE = [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]]
local SLOTBUTTON_HIGHLIGHTTEXTURE = [[INTERFACE\BUTTONS\ButtonHilight-Square]]

-- Database
private.ApplyTemplateToSlot = function(ruleName, tabID, slotID, template)
	addon.db.global.rules[ruleName].tabs[tabID][slotID] = template
end

private.ClearSlot = function(ruleName, tabID, slotID)
	addon.db.global.rules[ruleName].tabs[tabID][slotID] = nil
end

-- Frame
local function frame_onClick(frame, mouseButton)
	local widget = frame.obj
	local templateName = widget:GetUserData("templateName")

	if mouseButton == "LeftButton" then
		local quickAddTemplate = private.status.quickAddTemplate
		if quickAddTemplate == "__clear" then
			addon.db.global.rules[widget:GetUserData("ruleName")].tabs[widget:GetUserData("tabID")][widget:GetUserData(
				"slotID"
			)] =
				nil
			widget:SetUserData("templateName")
			widget:ApplyTemplate()
			return
		end

		local cursorType, itemID = GetCursorInfo()
		ClearCursor()
		if not templateName and cursorType == "item" and itemID then
			addon.CacheItem(itemID, function(itemID, addon, private, widget)
				local itemName, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)
				local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")
				local newTemplateName = private.TemplateExists(itemName)
						and addon.EnumerateString(itemName, private.TemplateExists)
					or itemName
				if bindType == 1 then
					return statusLabel:SetText(L["Cannot add soulbound item to rule"])
				end
				statusLabel:SetText("")
				private.AddTemplateFromCursor(newTemplateName, itemID)
				private.ApplyTemplateToSlot(
					private.status.ruleName,
					private.status.tabID,
					widget:GetUserData("slotID"),
					newTemplateName
				)
				private.status.tabGroup:SelectTab("templates")
				private.status.templateGroup:SetGroup(newTemplateName)
				CloseDropDownMenus()
			end, itemID, addon, private, widget)
		elseif templateName then
			if cursorType == "item" and itemID then
				print("Replace item")
			else
				print("Move item")
			end
		elseif quickAddTemplate then
			private.ApplyTemplateToSlot(
				private.status.ruleName,
				private.status.tabID,
				widget:GetUserData("slotID"),
				quickAddTemplate
			)
			widget:ApplyTemplate(quickAddTemplate)
		end
	elseif mouseButton == "RightButton" and templateName then
		local menu = {
			{
				text = L["Edit Template"],
				notCheckable = true,
				func = function()
					private.status.tabGroup:SelectTab("templates")
					private.status.templateGroup:SetGroup(templateName)
					CloseDropDownMenus()
				end,
			},
			{
				text = L["Clear Slot"],
				notCheckable = true,
				func = function()
					widget:ClearSlot()
					widget:ApplyTemplate()
					CloseDropDownMenus()
				end,
			},
			{
				text = CLOSE,
				notCheckable = true,
				func = function()
					CloseDropDownMenus()
				end,
			},
		}

		EasyMenu(menu, widget.contextMenu, frame, frame:GetWidth(), frame:GetHeight(), "MENU")
	end
end

local function frame_OnDragStart(frame) end

local function frame_OnEnter(frame)
	local template = addon.db.global.templates[frame.obj:GetUserData("templateName")]
	if template and template.enabled and template.itemID then
		addon.CacheItem(template.itemID, function(itemID, private, frame)
			local _, itemLink = GetItemInfo(itemID)
			private.ShowHyperlinkTip(itemLink, frame, "ANCHOR_RIGHT")
		end, template.itemID, private, frame)
	end
end

local function frame_OnLeave(frame)
	private.HideTooltip()
end

local methods = {
	OnAcquire = function(widget)
		widget.label:SetFont([[Fonts\ARIALN.TTF]], 14, "OUTLINE, MONOCHROME")
		widget.label:SetJustifyH("RIGHT")
		widget.label:SetPoint("BOTTOM", 0, 6)
	end,

	OnWidthSet = function(widget, width)
		if widget.frame:GetHeight() ~= width then
			widget:SetHeight(width)
			widget.label:SetFont([[Fonts\ARIALN.TTF]], width * 0.35, "OUTLINE, MONOCHROME")
			widget.label:SetWidth(width * 0.9)
		end
	end,

	ApplyTemplate = function(widget, templateName)
		if templateName then
			widget:SetUserData("templateName", templateName)
		end

		widget:SetIcon()
		if widget:GetUserData("templateName") then
			local template = addon.db.global.templates[widget:GetUserData("templateName")]
			if template.enabled then
				if template.itemID then
					addon.CacheItem(template.itemID, function(itemID, widget)
						local itemName, _, _, _, _, _, _, _, _, iconTexture = GetItemInfo(itemID)
						widget:SetIcon(iconTexture)
					end, template.itemID, widget)
				else
					widget:SetIcon(134400)
				end
			else
				widget:ClearSlot()
			end
		end

		widget:SetText()
	end,

	ClearSlot = function(widget)
		addon.db.global.rules[widget:GetUserData("ruleName")].tabs[widget:GetUserData("tabID")][widget:GetUserData(
			"slotID"
		)] =
			nil
		widget:SetUserData("templateName")
	end,

	LoadSlotInfo = function(widget)
		if widget:GetUserData("templateName") then
			widget:ApplyTemplate()
		else
			widget:SetIcon()
			widget:SetText()
		end
	end,

	SetIcon = function(widget, icon)
		widget.frame:SetNormalTexture(icon or private.SLOTBUTTON_TEXTURE)
	end,

	SetText = function(widget)
		local templateName = widget:GetUserData("templateName")
		local template = addon.db.global.templates[templateName]

		if templateName and template.enabled then
			local func = loadstring("return " .. template.stackSize)
			if type(func) == "function" then
				local success, userFunc = pcall(func)
				widget.frame:SetText(success and type(userFunc) == "function" and userFunc())
			end
		else
			widget.frame:SetText(" ")
		end
	end,

	SetSlotID = function(widget, ruleName, tabID, slotID)
		widget:SetUserData("ruleName", ruleName)
		widget:SetUserData("tabID", tabID)
		widget:SetUserData("slotID", slotID)
		widget:SetUserData("templateName", addon.db.global.rules[ruleName].tabs[tabID][slotID])

		widget:LoadSlotInfo()
	end,
}

local function Constructor()
	local frame = CreateFrame("Button", Type .. AceGUI:GetNextWidgetNum(Type), UIParent)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frame:SetText(" ")
	frame:SetPushedTextOffset(0, 0)
	frame:SetScript("OnClick", frame_onClick)
	frame:SetScript("OnEnter", frame_OnEnter)
	frame:SetScript("OnLeave", frame_OnLeave)

	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame_OnDragStart)

	frame:SetNormalTexture(private.SLOTBUTTON_TEXTURE)
	frame:SetHighlightTexture(SLOTBUTTON_HIGHLIGHTTEXTURE)

	local contextMenu = CreateFrame(
		"Frame",
		Type .. AceGUI:GetNextWidgetNum(Type) .. "ContextMenu",
		frame,
		"UIDropDownMenuTemplate"
	)

	local widget = {
		frame = frame,
		label = frame:GetFontString(),
		contextMenu = contextMenu,
		type = Type,
	}

	frame.obj = widget

	for method, func in pairs(methods) do
		widget[method] = func
	end

	AceGUI:RegisterAsWidget(widget)

	return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
