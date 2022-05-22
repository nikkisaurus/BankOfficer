local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficerSlotButton"
local Version = 1

local SLOTBUTTON_TEXTURE = [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]]

local scanner = CreateFrame("GameTooltip", "BankOfficerScanner", UIParent, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
local function IsSoulbound(itemID)
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent =
		GetItemInfo(
			itemID
		)

	scanner:ClearLines()
	scanner:SetHyperlink(itemLink)
	for i = 1, scanner:NumLines() do
		scanner:AddFontStrings(
			scanner:CreateFontString("$parentTextLeft" .. i, nil, "GameTooltipText"),
			scanner:CreateFontString("$parentTextRight" .. i, nil, "GameTooltipText")
		)

		if
			_G["BankOfficerScannerTextLeft" .. i]
			and _G["BankOfficerScannerTextLeft" .. i]:GetText() == ITEM_BIND_ON_PICKUP
		then
			return true
		end
	end
end

local function frame_onClick(frame, mouseButton)
	print(mouseButton)
end

local function frame_OnDragStart(frame) end

local methods = {
	OnAcquire = function(widget) end,

	OnWidthSet = function(widget, width)
		if widget.frame:GetHeight() ~= width then
			widget:SetHeight(width)
		end
	end,
}

local function Constructor()
	local frame = CreateFrame("Button", Type .. AceGUI:GetNextWidgetNum(Type), UIParent)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frame:SetPushedTextOffset(0, 0)
	frame:SetNormalFontObject(NumberFontNormal)
	frame:SetScript("OnClick", frame_onClick)

	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame_OnDragStart)

	frame:SetNormalTexture(SLOTBUTTON_TEXTURE)

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
