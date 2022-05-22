local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local COLS = 14
local ROWS = 7

local function GetSlotID(row, col)
	return format("%d.%d", row, col)
end

private.LoadTab = function(scrollFrame, tabID)
	private.status.tabID = tabID
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
