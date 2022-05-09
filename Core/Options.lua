local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function GetGuilds()
	local rules = {}
	for guildKey, guild in pairs(addon.db.global.guilds) do
		rules[guildKey] = guildKey
	end
	return rules
end

local function SetSelectedRule(rule)
	addon.OptionsFrame:SetUserData("selected", rule)
end

local keys = {
	settings = MAX_GUILDBANK_TABS + 1,
}

local function GetOptionsTree()
	local tree = {}
	for i = 1, MAX_GUILDBANK_TABS do
		local disable = not addon.GetGuild().tabsPurchased or i > addon.GetGuild().tabsPurchased
		tinsert(tree, {
			value = i,
			text = L.Tab(i),
			disabled = disable,
		})
	end

	tinsert(tree, {
		value = keys.settings,
		text = L["Settings"],
	})

	return tree
end

local function GetTabContent(optionsTree, _, tabID)
	optionsTree:ReleaseChildren()

	if addon.GetGuild().tabsPurchased and tabID <= addon.GetGuild().tabsPurchased then
		for row = 1, 7 do
			for col = 1, 14 do
				addon.OptionsFrame:SetUserData("selectedTabID", tabID)
				addon.GetOptionsTabSlot(optionsTree, row, col)
			end
		end
	elseif tabID == keys.settings then
		--TODO Settings
	end
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
	optionsContainer:SetWidth(825)
	optionsContainer:SetHeight(412)
	optionsContainer:SetUserData("children", {})
	optionsContainer:Hide()
	addon.OptionsFrame = optionsContainer

	local selectRuleButton = AceGUI:Create("Dropdown")
	selectRuleButton:SetList(GetGuilds())
	selectRuleButton:SetValue(addon.GetGuildKey())
	selectRuleButton:SetCallback("OnValueChanged", SetSelectedRule(value))

	local optionsTree = AceGUI:Create("TreeGroup")
	optionsTree:SetLayout("Flow")
	optionsTree:SetFullHeight(true)
	optionsTree:SetFullWidth(true)
	optionsTree:SetTree(GetOptionsTree())
	optionsTree:SetCallback("OnGroupSelected", GetTabContent)

	AddChild("selectRuleButton", selectRuleButton)
	AddChild("optionsTree", optionsTree)
end

addon.HandleSlashCommand = function()
	addon.OptionsFrame:Show()
end
