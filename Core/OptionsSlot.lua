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

local function EditSlot(tabID, slotKey, slotInfo)
	local optionsTree = addon.OptionsFrame:GetUserData("children").optionsTree
	optionsTree:ReleaseChildren()

	local icon = AceGUI:Create("Icon")
	icon:SetImage(GetItemIcon(slotInfo.itemID))
	icon:SetImageSize(40, 40)
	icon:SetWidth(40)
	icon:SetHeight(40)
	optionsTree:AddChild(icon)

	local name = GetItemInfo(slotInfo.itemID)
	local label = AceGUI:Create("Label")
	label:SetText(format("%s\n%d.%s", name, tabID, slotKey))
	optionsTree:AddChild(label)

	local stackEditBox = AceGUI:Create("MultiLineEditBox")
	stackEditBox:SetText(slotInfo.stack)
	stackEditBox:SetLabel(L["Stack"])
	stackEditBox:SetFullWidth(true)
	optionsTree:AddChild(stackEditBox)
	stackEditBox:SetCallback("OnEnterPressed", function(_, _, stack)
		addon.GetGuild().tabs[tabID].slots[slotKey].stack = stack
		optionsTree:SelectByValue(tabID)
	end)

	local backButton = AceGUI:Create("Button")
	backButton:SetText(BACK)
	optionsTree:AddChild(backButton)
	backButton:SetCallback("OnClick", function()
		optionsTree:SelectByValue(tabID)
	end)
end

local function moveFrame_OnUpdate(frame)
	if frame:IsVisible() then
		local scale, x, y = frame:GetEffectiveScale(), GetCursorPosition()
		frame:SetPoint("CENTER", nil, "BOTTOMLEFT", (x / scale) + 50, (y / scale) - 20)
	end
end

local moveFrame = CreateFrame("Frame", "BankOfficerMoveFrame", UIParent)
moveFrame:SetSize(40, 40)
moveFrame:SetFrameStrata("TOOLTIP")
moveFrame:Hide()
moveFrame:SetScript("OnUpdate", moveFrame_OnUpdate)
local moveFrameTexture = moveFrame:CreateTexture()
moveFrameTexture:SetAllPoints(moveFrame)

local function MoveItem(target)
	local source = addon.OptionsFrame:GetUserData("isMoving")
	local sourceTabID, sourceSlotKey, sourceSlotInfo =
		source:GetUserData("tabID"), source:GetUserData("slotKey"), source:GetUserData("slotInfo")
	local targetTabID, targetSlotKey, targetSlotInfo =
		target:GetUserData("tabID"), target:GetUserData("slotKey"), target:GetUserData("slotInfo")

	addon.GetGuild().tabs[targetTabID].slots[targetSlotKey] = {
		itemID = sourceSlotInfo.itemID,
		stack = sourceSlotInfo.stack,
	}
	target:SetSlotData(sourceTabID, sourceSlotKey, sourceSlotInfo)

	if not addon.OptionsFrame:GetUserData("duplicate") then
		addon.GetGuild().tabs[sourceTabID].slots[sourceSlotKey] = {
			itemID = targetSlotInfo.itemID,
			stack = targetSlotInfo.stack,
		}
		source:SetSlotData(targetTabID, targetSlotKey, targetSlotInfo)
	else
		addon.OptionsFrame:SetUserData("duplicate")
	end

	addon.OptionsFrame:SetUserData("isMoving")
	moveFrame:Hide()
end

local function StartMoving(widget, duplicate)
	addon.OptionsFrame:SetUserData("isMoving", widget)
	addon.OptionsFrame:SetUserData("duplicate", duplicate)
	moveFrame:Show()
	moveFrameTexture:SetTexture(GetItemIcon(widget:GetUserData("slotInfo").itemID))
end

local function frame_onClick(frame, mouseButton)
	local widget = frame.obj
	local isMoving = addon.OptionsFrame:GetUserData("isMoving")
	local tabID, slotKey, slotInfo =
		widget:GetUserData("tabID"), widget:GetUserData("slotKey"), widget:GetUserData("slotInfo")
	local itemID = slotInfo.itemID

	if mouseButton == "LeftButton" then
		if itemID then
			local cursorType, itemID = GetCursorInfo()
			if isMoving then
				MoveItem(widget)
			elseif cursorType == "item" and itemID then
				AddSlotItem(widget)
			else
				StartMoving(widget, IsControlKeyDown())
			end
		elseif isMoving then
			MoveItem(widget)
		else
			AddSlotItem(widget)
		end
	elseif mouseButton == "RightButton" then
		if IsShiftKeyDown() then
			addon.GetGuild().tabs[tabID].slots[slotKey].itemID = false
			addon.GetGuild().tabs[tabID].slots[slotKey].stack = [[function()
                return 1
            end]]
			widget:SetSlotData(tabID, slotKey, addon.GetGuild().tabs[tabID].slots[slotKey])
		elseif itemID then
			addon.CacheItem(itemID, EditSlot, tabID, slotKey, slotInfo)
		end
	end
end

local function frame_OnDragStart(frame)
	local widget = frame.obj
	if
		IsShiftKeyDown()
		and widget:GetUserData("slotInfo").itemID
		and not addon.OptionsFrame:GetUserData("isMoving")
	then
		StartMoving(widget)
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
			widget.frame:GetFontString():SetPoint("BOTTOMRIGHT", -1, 6)
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
