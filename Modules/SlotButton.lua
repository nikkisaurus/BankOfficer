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
	--addon:Unhook(scrollFrame.frame, "OnSizeChanged")
	for row = 1, ROWS do
		for col = 1, COLS do
			local slotButton = AceGUI:Create("BankOfficerSlotButton")
			slotButton:SetUserData("elementName", "slotButton_" .. GetSlotID(row, col))
			slotButton:SetRelativeWidth(1 / 14.25)
			private.AddChildren(scrollFrame, { slotButton })
		end
	end
	scrollFrame:DoLayout()
	--addon:HookScript(scrollFrame.frame, "OnSizeChanged", function()
	--	scrollFrame:PauseLayout()
	--	for row = 1, ROWS do
	--		for col = 1, COLS do
	--			local slotButton = private.GetChild(scrollFrame, "slotButton_" .. GetSlotID(row, col))
	--			slotButton:SetSize(1 / 15)
	--		end
	--	end
	--	scrollFrame:ResumeLayout()
	--end)
end
