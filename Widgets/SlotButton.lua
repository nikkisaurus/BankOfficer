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
		end
	elseif mouseButton == "RightButton" then
		local menu = {}

		local templates = {
			text = L["Apply Template"],
			notCheckable = true,
			hasArrow = true,
			menuList = {},
		}
		for templateName, templateInfo in addon.pairs(addon.db.global.templates) do
			if templateInfo.enabled then
				tinsert(templates.menuList, {
					text = templateName,
					notCheckable = true,
					func = function()
						private.ApplyTemplateToSlot(
							private.status.ruleName,
							private.status.tabID,
							widget:GetUserData("slotID"),
							templateName
						)
						widget:ApplyTemplate(templateName)
						CloseDropDownMenus()
					end,
				})
			end
		end
		tinsert(templates.menuList, {
			text = L["Add Template"],
			notCheckable = true,
			func = function()
				private.status.tabGroup:SelectTab("templates")
				private.status.templateGroup:SetGroup("__new")
				CloseDropDownMenus()
			end,
		})
		tinsert(menu, templates)

		if templateName then
			tinsert(menu, {
				text = L["Edit Template"],
				notCheckable = true,
				func = function()
					private.status.tabGroup:SelectTab("templates")
					private.status.templateGroup:SetGroup(templateName)
					CloseDropDownMenus()
				end,
			})

			tinsert(menu, {
				text = L["Clear Slot"],
				notCheckable = true,
				func = function()
					addon.db.global.rules[widget:GetUserData("ruleName")].tabs[widget:GetUserData("tabID")][widget:GetUserData(
						"slotID"
					)] =
						nil
					widget:SetUserData("templateName")
					widget:ApplyTemplate()
					CloseDropDownMenus()
				end,
			})
		end

		tinsert(menu, {
			text = CLOSE,
			notCheckable = true,
			func = function()
				CloseDropDownMenus()
			end,
		})

		EasyMenu(menu, widget.contextMenu, frame, frame:GetWidth(), frame:GetHeight(), "MENU")
	end
end

local function frame_OnDragStart(frame) end

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
				widget:SetUserData("templateName")
			end
		end

		widget:SetText()
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
