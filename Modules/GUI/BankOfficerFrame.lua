local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Local ]]
local trees = {
	menu = {
		{
			value = "Restock",
			text = L["Restock"],
		},
		{
			value = "Organize",
			text = L["Organize"],
		},
		{
			value = "Review",
			text = L["Review"],
		},
		{
			value = "Settings",
			text = L["Settings"],
		},
	},
}

--[[ Local Functions ]]
local function menu_OnGroupSelected(self, _, group)
	local content = self:GetUserData("content")
	content:ReleaseChildren()
	content:SetLayout("Flow")
	content:DrawContent(group)
end

--[[ Private ]]
function private:InitializeFrame()
	local frame = AceGUI:Create("Window")
	private:AddSpecialFrame(frame.frame, "BankOfficerFrame")
	private:EmbedMethods(frame, { "Container" })

	frame:SetTitle(L.addonName)
	frame:SetSize(1000, 725)
	frame:SetLayout("Fill")

	local menu = AceGUI:Create("TreeGroup")
	private:GetContentContainer(menu)
	menu:SetTree(trees.menu)
	menu:SetCallback("OnGroupSelected", menu_OnGroupSelected)

	frame:AddChildren(menu)
end
