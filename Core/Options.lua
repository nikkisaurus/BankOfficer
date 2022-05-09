local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function InventoryRuleExists()
	return addon.db.global.guilds[(GetGuildInfo("player"))].tabsPurchased
end

local function GetOptionsTree()
	local tree = {}
	for i = 1, MAX_GUILDBANK_TABS do
		local disable = i > (InventoryRuleExists() or 0)

		tinsert(tree, {
			value = i,
			text = L.Tab(i),
			disabled = disable,
		})
	end
	return tree
end

local function GetGroupContent(optionsTree, _, tabID)
	optionsTree:ReleaseChildren()

	if tabID <= (InventoryRuleExists() or 0) then
		for y = 1, 7 do
			for x = 1, 14 do
				addon.GetOptionsTabSlot(optionsTree)
			end
		end
	elseif tabID <= 8 then
		optionsTree:ReleaseChildren()
	else
		--Settings
	end
end

local function SetDisabled(disable)
	local children = addon.OptionsFrame:GetUserData("children")
	children.addInventoryRuleButton:SetDisabled(disable)
	children.optionsTree:SetTree(GetOptionsTree())
end

local function AddInventoryRule(addInventoryRuleButton)
	addon.db.global.guilds[(GetGuildInfo("player"))].tabsPurchased = GetNumGuildBankTabs()
	SetDisabled(true)
end

local function AddChild(childName, child)
	addon.OptionsFrame:AddChild(child)
	addon.OptionsFrame:GetUserData("children")[childName] = child
end

local AceGUI = LibStub("AceGUI-3.0")
addon.InitializeOptions = function()
	local optionsContainer = AceGUI:Create("Window")
	optionsContainer:SetTitle(L[addonName])
	optionsContainer:SetLayout("Flow")
	optionsContainer:EnableResize(false)
	optionsContainer:SetWidth(800)
	optionsContainer:SetHeight(400)
	optionsContainer:SetUserData("children", {})

	local addInventoryRuleButton = AceGUI:Create("Button")
	addInventoryRuleButton:SetText(L["Add Rule"])
	addInventoryRuleButton:SetCallback("OnClick", AddInventoryRule)

	local optionsTree = AceGUI:Create("TreeGroup")
	optionsTree:SetLayout("Flow")
	optionsTree:SetFullHeight(true)
	optionsTree:SetFullWidth(true)
	optionsTree:SetTree(GetOptionsTree())
	optionsTree:SetCallback("OnGroupSelected", GetGroupContent)

	addon.OptionsFrame = optionsContainer
	AddChild("addInventoryRuleButton", addInventoryRuleButton)
	AddChild("optionsTree", optionsTree)
	SetDisabled(InventoryRuleExists())
end

addon.HandleSlashCommand = function()
	addon.OptionsFrame:Show()
end
