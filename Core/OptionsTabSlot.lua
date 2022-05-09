local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local AceGUI = LibStub("AceGUI-3.0")
addon.GetOptionsTabSlot = function(optionsTree)
	local slot = AceGUI:Create("Icon")
	slot:SetImage([[INTERFACE\BUTTONS\UI-EmptySlot-Disabled]])
	slot:SetImageSize(58, 58)
	slot:SetWidth(40)
	slot:SetHeight(40)
	optionsTree:AddChild(slot)

	slot:SetCallback("OnClick", function(_, _, mouseButton)
		if mouseButton == "LeftButton" then
			-- if not button.empty then
			print("Move")
			-- else
			print("Add")
			-- end
		elseif mouseButton == "RightButton" then
			print("Edit")
		end
	end)
end
