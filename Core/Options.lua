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

local function GetOptionsTree()
	local tree = {}
	for i = 1, MAX_GUILDBANK_TABS do
		local tabsPurchased = addon.GetGuild().tabsPurchased
		local disable = i > tabsPurchased
		tinsert(tree, {
			value = i,
			text = L.Tab(i),
			disabled = disable,
		})
	end

	tinsert(tree, {
		value = "settings",
		text = L["Settings"],
	})

	return tree
end

local function GetTabContent(optionsTree, _, tabID)
	optionsTree:ReleaseChildren()

	if tabID <= 8 then --! FIX
		for y = 1, 7 do
			for x = 1, 14 do
				addon.GetOptionsTabSlot(optionsTree)
			end
		end
	else
		--Settings
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
	optionsContainer:SetWidth(800)
	optionsContainer:SetHeight(400)
	optionsContainer:SetUserData("children", {})
	optionsContainer:Hide()

	local selectRuleButton = AceGUI:Create("Dropdown")
	selectRuleButton:SetList(GetGuilds())
	selectRuleButton:SetValue(addon.GetGuildKey())

	local optionsTree = AceGUI:Create("TreeGroup")
	optionsTree:SetLayout("Flow")
	optionsTree:SetFullHeight(true)
	optionsTree:SetFullWidth(true)
	optionsTree:SetTree(GetOptionsTree())
	--optionsTree:SetCallback("OnGroupSelected", GetTabContent)

	addon.OptionsFrame = optionsContainer
	AddChild("selectRuleButton", selectRuleButton)
	AddChild("optionsTree", optionsTree)
end

addon.HandleSlashCommand = function()
	addon.OptionsFrame:Show()
end
