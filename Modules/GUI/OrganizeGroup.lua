local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficer_OrganizeGroup"
local Version = 1

local SLOTBUTTON_HIGHLIGHTTEXTURE = [[INTERFACE\BUTTONS\ButtonHilight-Square]]
local SLOTBUTTON_TEXTURE = [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]]

local methods = {
	OnAcquire = function(widget)
		widget.frame:SetSize(200, 200)
		widget.frame:Show()
		widget:LoadSlots()
	end,

	LoadSlots = function(widget)
		local guildKey = widget:GetUserData("guildKey")
		local guild = guildKey and private.db.global.guilds[guildKey]
		local tabs = {}

		for tab = 1, MAX_GUILDBANK_TABS do
			tinsert(tabs, {
				value = "tab" .. tab,
				text = format("%s %d", L["Tab"], tab),
				disabled = tab > (guild and guild.numTabs or MAX_GUILDBANK_TABS),
			})
		end

		widget.tabGroup:SetTabs(tabs)
		widget.tabGroup:ReleaseChildren()
		widget.tabGroup:SelectTab()
	end,

	OnWidthSet = function(widget, ...)
		widget.tabGroup:OnWidthSet(...)
	end,

	SetLabel = function(widget, guildKey)
		widget:SetUserData("guildKey", guildKey)
	end,

	SetText = function(widget, ...) end,
}

local function Constructor()
	local frame = AceGUI:Create("SimpleGroup")

	local tabGroup = AceGUI:Create("TabGroup")
	frame:AddChild(tabGroup)
	tabGroup:SetFullWidth(true)
	tabGroup:SetLayout("Flow")
	tabGroup:SetLayout("BankOfficer_GuildBankTab")
	tabGroup:SetCallback("OnGroupSelected", function(self, _, group)
		local guildKey = self.obj:GetUserData("guildKey")
		local tab = tonumber(gsub(group, "tab", "") or "")

		self:ReleaseChildren()

		for slot = 1, 98 do
			local button = AceGUI:Create("BankOfficer_OrganizeSlot")
			button:SetUserData("guildKey", guildKey)
			button:SetUserData("slotID", slot)
			button:SetUserData("tab", tab)
			button:LoadSlot()
			tabGroup:AddChild(button)
		end

		local overstock = AceGUI:Create("CheckBox")
		overstock:SetLabel(L["Restock from this tab"])
		overstock:SetCallback("OnValueChanged", function(_, _, checked)
			private.db.global.guilds[guildKey].restockTabs[tab] = checked
		end)
		overstock:SetValue(private.db.global.guilds[guildKey].restockTabs[tab])
		tabGroup:AddChild(overstock)

		tabGroup:DoLayout()
	end)

	local widget = {
		container = frame,
		tabGroup = tabGroup,
		frame = frame.frame,
		type = Type,
	}

	frame.obj = widget
	tabGroup.obj = widget

	for method, func in pairs(methods) do
		widget[method] = func
	end

	AceGUI:RegisterAsWidget(widget)

	return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
