local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")
local sub = string.sub

-- Load
local function frame_OnShow(frame)
	private.GetChild(frame, "tabGroup"):SelectTab("rules")
end

local function LoadTab(tabGroup, _, tabName)
	tabGroup:ReleaseChildren()
	tabName = strupper(sub(tabName, 1, 1)) .. sub(tabName, 2)
	local tabContent = private["Load" .. tabName](tabGroup)
	private.AddChildren(tabGroup, { tabContent })
	private.status.tabName = tabName
end

-- Initialize
private.status = {}

private.AddChildren = function(parent, children)
	for _, child in pairs(children) do
		parent:AddChild(child)
		parent:GetUserData("children")[child:GetUserData("elementName")] = child
	end
end

private.GetChild = function(parent, child)
	return parent:GetUserData("children")[child]
end

private.InitializeGUI = function()
	local frame = AceGUI:Create("Window")
	frame:SetUserData("children", {})
	frame:SetTitle(L[addonName])
	frame:SetLayout("Fill")
	frame:EnableResize(false)
	frame:SetWidth(1000)
	frame:SetHeight(550)
	frame:SetCallback("OnShow", frame_OnShow)
	frame:Hide()
	private.frame = frame
	_G["BankOfficerFrame"] = frame.frame
	tinsert(UISpecialFrames, "BankOfficerFrame")

	local tabGroup = AceGUI:Create("TabGroup")
	tabGroup:SetUserData("elementName", "tabGroup")
	tabGroup:SetUserData("children", {})
	tabGroup:SetTabs({
		{
			value = "rules",
			text = "Rules",
		},
		{
			value = "settings",
			text = "Settings",
			disabled = true,
		},
		{
			value = "help",
			text = "Help",
			disabled = true,
		},
	})
	tabGroup:SetCallback("OnGroupSelected", LoadTab)

	private.AddChildren(frame, { tabGroup })
end

-- Confirmation dialog
local function acceptButton_OnClick(acceptButton)
	acceptButton.parent:Hide()
	coroutine.resume(private.co, true)
	coroutine.status(private.co)
end

local function cancelButton_OnClick(cancelButton)
	cancelButton.parent:Hide()
	coroutine.resume(private.co, false)
	coroutine.status(private.co)
end

private.RequestConfirmation = function(message)
	local dialog = private.dialog or AceGUI:Create("Window")
	dialog:SetTitle(L[addonName])
	dialog:SetLayout("Flow")
	dialog:SetWidth(350)
	dialog:EnableResize(false)
	dialog:SetPoint("TOP", 0, -200)
	dialog.frame:SetFrameStrata("TOOLTIP")
	dialog.closebutton:Hide()
	private.dialog = dialog

	dialog:ReleaseChildren()

	local messageLabel = AceGUI:Create("Label")
	messageLabel:SetText(message)
	messageLabel:SetFullWidth(true)
	dialog:AddChild(messageLabel)
	dialog:SetHeight(100 + messageLabel.label:GetStringHeight())

	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetFullWidth(true)
	dialog:AddChild(spacer)

	local acceptButton = AceGUI:Create("Button")
	acceptButton:SetUserData("elementName", "acceptButton")
	acceptButton:SetRelativeWidth(0.5)
	acceptButton:SetText(ACCEPT)
	acceptButton:SetCallback("OnClick", acceptButton_OnClick)
	dialog:AddChild(acceptButton)

	local cancelButton = AceGUI:Create("Button")
	cancelButton:SetUserData("elementName", "cancelButton")
	cancelButton:SetRelativeWidth(0.5)
	cancelButton:SetText(CANCEL)
	cancelButton:SetCallback("OnClick", cancelButton_OnClick)
	dialog:AddChild(cancelButton)

	dialog:Show()
end

-- GUI Control
local LoadGUI = function()
	private.frame:Show()

	if private.status.tabName == "Rules" and private.status.ruleName then
		private.status.ruleGroup:SetGroup(private.status.ruleName)
	end
end

addon.HandleSlashCommand = function()
	LoadGUI()
end

-- Tooltips
private.ShowHyperlinkTip = function(itemLink, owner, anchor)
	GameTooltip:SetOwner(owner or private.frame.frame, anchor or "ANCHOR_CURSOR", 0, 0)
	GameTooltip:SetHyperlink(itemLink)
	GameTooltip:Show()
end

private.HideTooltip = function()
	GameTooltip:ClearLines()
	GameTooltip:Hide()
end
