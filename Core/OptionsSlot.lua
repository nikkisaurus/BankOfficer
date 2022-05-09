local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local Type = "BankOfficerSlot"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")

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

		if _G["BankOfficerScannerTextLeft" .. i]:GetText() == ITEM_BIND_ON_PICKUP then
			return true
		end
	end
end

local function AddSlotItem(widget)
	local cursorType, itemID = GetCursorInfo()
	ClearCursor()

	if cursorType == "item" and itemID and not IsSoulbound(itemID) then
		addon.CacheItem(itemID, function(widget, cursorType, itemID)
			addon.GetGuild().tabs[widget:GetUserData("tabID")].slots[widget:GetUserData("slotKey")].itemID = itemID
			widget:SetItem(itemID)
		end, widget, cursorType, itemID)
	end
end

local function CloneSlotInfo(slotInfo)
	local newSlotInfo = {}
	for k, v in pairs(slotInfo) do
		newSlotInfo[k] = v
	end
	return newSlotInfo
end

local function MoveItem(target)
	local source = addon.OptionsFrame:GetUserData("isMoving")
	local sourceTabID, sourceSlotKey, sourceSlotInfo =
		source:GetUserData("tabID"), source:GetUserData("slotKey"), source:GetUserData("slotInfo")
	local targetTabID, targetSlotKey, targetSlotInfo =
		target:GetUserData("tabID"), target:GetUserData("slotKey"), target:GetUserData("slotInfo")

	addon.GetGuild().tabs[targetTabID].slots[targetSlotKey] = CloneSlotInfo(sourceSlotInfo)
	target:SetSlotData(sourceTabID, sourceSlotKey, sourceSlotInfo)

	addon.GetGuild().tabs[sourceTabID].slots[sourceSlotKey] = CloneSlotInfo(targetSlotInfo)
	source:SetSlotData(targetTabID, targetSlotKey, targetSlotInfo)

	addon.OptionsFrame:SetUserData("isMoving")
end

local function frame_onClick(frame, mouseButton)
	local widget = frame.obj
	local isMoving = addon.OptionsFrame:GetUserData("isMoving")

	if mouseButton == "LeftButton" then
		if widget:GetUserData("slotInfo").itemID then
			if isMoving then
				MoveItem(widget)
			else
				--TODO Create icon at cursor
				addon.OptionsFrame:SetUserData("isMoving", widget)
			end
		elseif isMoving then
			MoveItem(widget)
		else
			AddSlotItem(widget)
		end
	elseif mouseButton == "RightButton" then
		if IsShiftKeyDown() then
			local slotInfo = {
				itemID = false,
				stack = [[function()
                    return 1
                end]],
			}
			local tabID, slotKey = widget:GetUserData("tabID"), widget:GetUserData("slotKey")
			addon.GetGuild().tabs[tabID].slots[slotKey] = slotInfo
			widget:SetSlotData(tabID, slotKey, slotInfo)
		else
			print("Edit") --TODO
		end
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
