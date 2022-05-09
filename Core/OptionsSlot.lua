local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local Type = "BankOfficerSlot"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")

local function AddSlotItem(widget)
	local cursorType, itemID = GetCursorInfo()
	ClearCursor()

	if cursorType == "item" and itemID then
		addon.GetGuild().tabs[widget:GetUserData("tabID")].slots[widget:GetUserData("slotKey")].itemID = itemID
		widget:SetItem(itemID)
	end
end

local function frame_onClick(frame, mouseButton)
	local widget = frame.obj

	if mouseButton == "LeftButton" then
		if not widget:GetUserData("slotInfo").itemID then
			AddSlotItem(widget)
		else
			print("Move")
		end
	elseif mouseButton == "RightButton" then
		print("Edit")
	end
end

local methods = {
	OnAcquire = function(widget)
		widget:SetSize(40, 40)
	end,

	SetItem = function(widget, itemID)
		widget:SetIcon(GetItemIcon(itemID))
		widget:SetStack(itemID and widget:GetUserData("slotInfo").stack)
	end,

	SetIcon = function(widget, iconID)
		widget.frame:SetNormalTexture(iconID or [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]])
	end,

	SetSlotData = function(widget, tabID, slotKey, slotInfo)
		widget:SetUserData("tabID", tabID)
		widget:SetUserData("slotKey", slotKey)
		widget:SetUserData("slotInfo", slotInfo)

		widget:SetItem(slotInfo.itemID)
	end,

	SetSize = function(widget, width, height)
		widget.frame:SetSize(width, height)
	end,

	SetStack = function(widget, stack)
		if not stack then
			return widget.frame:SetText("")
		end

		local func = loadstring("return " .. stack)
		if type(func) == "function" then
			local success, userFunc = pcall(func)
			widget.frame:SetText(success and type(userFunc) == "function" and userFunc())
		end
	end,
}

local function Constructor()
	local frame = CreateFrame("Button", Type .. AceGUI:GetNextWidgetNum(Type), UIParent)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frame:SetPushedTextOffset(0, 0)
	frame:SetNormalFontObject(NumberFontNormal)
	frame:SetScript("OnClick", frame_onClick)

	local widget = {
		frame = frame,
		type = Type,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	AceGUI:RegisterAsWidget(widget)

	return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
