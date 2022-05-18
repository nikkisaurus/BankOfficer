local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Lists
local RULE_TYPES = {
	tab = L["Tab"],
	list = L["List"],
}

local function GetRules()
	local rules = {}
	local order = {}

	for ruleName, rule in addon.pairs(addon.db.global.rules) do
		if rule.type then
			rules[ruleName] = ruleName
			tinsert(order, ruleName)
		end
	end

	rules["__new"] = L["Add Rule"]
	tinsert(order, "__new")

	return rules, order
end

local function GetGuildList()
	local guilds = {}

	for guildKey, _ in pairs(addon.db.global.guilds) do
		guilds[guildKey] = guildKey
	end

	return guilds
end

local function GetTreeList(ruleGroup)
	local list = {
		{
			value = "settings",
			text = SETTINGS,
		},
	}

	local ruleName = ruleGroup:GetUserData("selectedRule")
	if not ruleName then
		return list
	end

	local rule = addon.db.global.rules[ruleName]

	if rule.type == "tab" then
		for tabID = 1, MAX_GUILDBANK_TABS do
			tinsert(list, {
				value = "tab" .. tabID,
				text = L.TabID(tabID),
			})
		end
	end

	--TODO Add list tabs

	return list
end

-- Database

local function DeleteRule(ruleGroup, ruleName)
	wipe(addon.db.global.rules[ruleName])
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup()
	ruleGroup:ReleaseChildren()
end

local function ConfirmDeleteRule(deleteRuleButton)
	local ruleGroup = deleteRuleButton.parent.parent.parent.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")

	private.CreateCoroutine(function()
		private.RequestConfirmation(L.DeleteRule(ruleName))

		local confirmed = coroutine.yield()
		if not confirmed then
			return
		end

		DeleteRule(ruleGroup, ruleName)
	end)

	coroutine.resume(private.co)
end

local function RenameRule(ruleNameEditBox)
	local ruleGroup = ruleNameEditBox.parent.parent.parent.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")
	local newRuleName = ruleNameEditBox:GetText()
	local statusLabel = private.GetChild(ruleNameEditBox.parent, "statusLabel")

	if not newRuleName or newRuleName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif ruleName == newRuleName then
		return
	elseif private.RuleExists(newRuleName) then
		return statusLabel:SetText(L.RuleExists(ruleName))
	elseif newRuleName == "__new" then
		return statusLabel:SetText(L["Invalid rule name"])
	end

	addon.db.global.rules[newRuleName] = addon:CloneTable(addon.db.global.rules[ruleName])
	DeleteRule(ruleGroup, ruleName)
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(newRuleName)
end

private.RuleExists = function(ruleName)
	return addon.db.global.rules[ruleName].type
end

local function AddRule(addRuleButton)
	local ruleGroup = addRuleButton.parent
	local ruleNameEditBox = private.GetChild(ruleGroup, "ruleNameEditBox")
	local ruleName = ruleNameEditBox:GetText()
	local ruleTypeDropdown = private.GetChild(ruleGroup, "ruleTypeDropdown")
	local statusLabel = private.GetChild(ruleGroup, "statusLabel")

	if not ruleName or ruleName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif private.RuleExists(ruleName) then
		return statusLabel:SetText(L.RuleExists(ruleName))
	elseif ruleName == "__new" then
		return statusLabel:SetText(L["Invalid rule name"])
	end

	addon.db.global.rules[ruleName].type = ruleTypeDropdown:GetValue()
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(ruleName)
end

local function UpdateRule(treeGroup, key, value)
	local ruleGroup = treeGroup.parent
	addon.db.global.rules[ruleGroup:GetUserData("selectedRule")][key] = value
	treeGroup:SetTree(GetTreeList(ruleGroup))
end

-- AddRuleContent
local function ruleNameEditBox_OnEnterPressed(ruleNameEditBox)
	ruleNameEditBox:ClearFocus()
end

local function AddRuleContent(ruleGroup)
	ruleGroup:SetLayout("Flow")

	local ruleNameEditBox = AceGUI:Create("EditBox")
	ruleNameEditBox:SetUserData("elementName", "ruleNameEditBox")
	ruleNameEditBox:SetLabel(NAME)
	ruleNameEditBox:DisableButton(true)
	ruleNameEditBox:SetCallback("OnEnterPressed", ruleNameEditBox_OnEnterPressed)

	local ruleTypeDropdown = AceGUI:Create("Dropdown")
	ruleTypeDropdown:SetUserData("elementName", "ruleTypeDropdown")
	ruleTypeDropdown:SetList(RULE_TYPES)
	ruleTypeDropdown:SetLabel(TYPE)
	ruleTypeDropdown:SetValue("list")

	local addRuleButton = AceGUI:Create("Button")
	addRuleButton:SetUserData("elementName", "addRuleButton")
	addRuleButton:SetText(ADD)
	addRuleButton:SetCallback("OnClick", AddRule)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(ruleGroup, { ruleNameEditBox, ruleTypeDropdown, addRuleButton, statusLabel })
end

-- RuleContent
local function guildsDropdown_OnValueChanged(guildsDropdown, _, guild, checked)
	local ruleGroup = guildsDropdown.parent.parent.parent.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")

	addon.db.global.rules[ruleName].guilds[guild] = checked
end

local function UpdateGuildsDropdown(guildsDropdown)
	local ruleGroup = guildsDropdown.parent.parent.parent.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")

	for guildKey, checked in pairs(addon.db.global.rules[ruleName].guilds) do
		guildsDropdown:SetItemValue(guildKey, checked)
	end
end

local function treeGroup_OnGroupSelected(treeGroup, _, path)
	local ruleGroup = treeGroup.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")
	local rule = addon.db.global.rules[ruleName]
	local scrollFrame = private.GetChild(private.GetChild(treeGroup, "scrollContainer"), "scrollFrame")

	scrollFrame:ReleaseChildren()

	if not rule or not rule.type then
		return
	end

	if path == "settings" then
		local ruleNameEditBox = AceGUI:Create("EditBox")
		ruleNameEditBox:SetUserData("elementName", "ruleNameEditBox")
		ruleNameEditBox:SetFullWidth(true)
		ruleNameEditBox:SetText(ruleName)
		ruleNameEditBox:SetLabel(NAME)
		ruleNameEditBox:DisableButton(true)
		ruleNameEditBox:SetCallback("OnEnterPressed", RenameRule)

		local ruleTypeDropdown = AceGUI:Create("Dropdown")
		ruleTypeDropdown:SetUserData("elementName", "ruleTypeDropdown")
		ruleTypeDropdown:SetRelativeWidth(1 / 2)
		ruleTypeDropdown:SetList(RULE_TYPES)
		ruleTypeDropdown:SetLabel(TYPE)
		ruleTypeDropdown:SetValue(rule.type)
		ruleTypeDropdown:SetCallback("OnValueChanged", function(_, _, ruleType)
			UpdateRule(treeGroup, "type", ruleType)
		end)

		local guildsDropdown = AceGUI:Create("Dropdown")
		guildsDropdown:SetUserData("elementName", "guildsDropdown")
		guildsDropdown:SetRelativeWidth(1 / 2)
		guildsDropdown:SetList(GetGuildList())
		guildsDropdown:SetLabel(L["Apply rule to guilds"])
		guildsDropdown:SetMultiselect(true)
		guildsDropdown:SetCallback("OnValueChanged", guildsDropdown_OnValueChanged)

		local deleteRuleButton = AceGUI:Create("Button")
		deleteRuleButton:SetUserData("elementName", "deleteRuleButton")
		deleteRuleButton:SetText(DELETE)
		deleteRuleButton:SetCallback("OnClick", ConfirmDeleteRule)

		local statusLabel = AceGUI:Create("Label")
		statusLabel:SetUserData("elementName", "statusLabel")
		statusLabel:SetFullWidth(true)
		statusLabel:SetColor(1, 0, 0)
		statusLabel:SetText()

		private.AddChildren(
			scrollFrame,
			{ ruleNameEditBox, ruleTypeDropdown, guildsDropdown, deleteRuleButton, statusLabel }
		)

		UpdateGuildsDropdown(guildsDropdown)
	elseif strfind(path, "tab") then
		private.LoadTab(scrollFrame, gsub(path, "tab", ""))
	end
end

local function RuleContent(ruleGroup)
	ruleGroup:SetLayout("Fill")

	local treeGroup = AceGUI:Create("TreeGroup")
	treeGroup:SetUserData("elementName", "treeGroup")
	treeGroup:SetUserData("children", {})
	treeGroup:SetLayout("Flow")
	treeGroup:SetTree(GetTreeList(ruleGroup))
	treeGroup:SetCallback("OnGroupSelected", treeGroup_OnGroupSelected)
	private.AddChildren(ruleGroup, { treeGroup })

	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetUserData("elementName", "scrollContainer")
	scrollContainer:SetUserData("children", {})
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	private.AddChildren(treeGroup, { scrollContainer })

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetUserData("elementName", "scrollFrame")
	scrollFrame:SetUserData("children", {})
	scrollFrame:SetLayout("Flow")
	private.AddChildren(scrollContainer, { scrollFrame })

	treeGroup:SelectByPath("settings")
end

-- Load
local function SelectRule(ruleGroup, _, rule)
	ruleGroup:ReleaseChildren()
	ruleGroup:SetUserData("selectedRule", rule)

	if rule == "__new" then
		AddRuleContent(ruleGroup)
	else
		RuleContent(ruleGroup)
	end
end

private.LoadRules = function(tabGroup)
	tabGroup:SetLayout("Fill")
	local ruleGroup = AceGUI:Create("DropdownGroup")
	ruleGroup:SetUserData("elementName", "ruleGroup")
	ruleGroup:SetUserData("children", {})
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetCallback("OnGroupSelected", SelectRule)
	return ruleGroup
end
