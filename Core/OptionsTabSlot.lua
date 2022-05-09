local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function GetSlotKey(row, col)
	local slotKey = format("%d.%d", row, col)
	return slotKey
end

local AceGUI = LibStub("AceGUI-3.0")
addon.GetOptionsTabSlot = function(optionsTree, row, col)
	local tabID = addon.OptionsFrame:GetUserData("selectedTabID")
	local slotKey = GetSlotKey(row, col)
	local slotInfo = addon.GetGuild().tabs[tabID].slots[slotKey]
	--local Col = mod(col, 2) == 0 and col / 2 or ceil(col / 2) -- Blizzard col

	local slot = AceGUI:Create("BankOfficerSlot")
	slot:SetSize(42, 42)
	slot:SetSlotData(tabID, slotKey, slotInfo)
	optionsTree:AddChild(slot)
end
