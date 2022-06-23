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

private.GetGuildList = function()
	local guilds = {}

	for guildKey, _ in pairs(addon.db.global.guilds) do
		guilds[guildKey] = guildKey
	end

	return guilds
end

private.GetTreeList = function()
	local list = {
		{
			value = "settings",
			text = SETTINGS,
		},
	}

	local ruleName = private.status.ruleName
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
	elseif rule.type == "list" then
		local lists = {
			value = "lists",
			text = L["Lists"],
		}

		for listKey, listInfo in addon.pairs(rule.lists) do
			if listInfo.min then
				if not lists.children then
					lists.children = {}
				end
				tinsert(lists.children, {
					value = listKey,
					text = listKey,
				})
			end
		end

		tinsert(list, lists)
	end

	return list
end

-- Database
local function AddRule(ruleName, ruleType)
	local ruleGroup = private.status.ruleGroup
	local statusLabel = private.GetChild(ruleGroup, "statusLabel")

	if not ruleName or ruleName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif private.RuleExists(ruleName) then
		return statusLabel:SetText(L.RuleExists(ruleName))
	elseif ruleName == "__new" then
		return statusLabel:SetText(L["Invalid rule name"])
	end

	addon.db.global.rules[ruleName].type = ruleType
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(ruleName)
end

local function ApplyRuleToGuild(guild, enabled)
	addon.db.global.rules[private.status.ruleName].guilds[guild] = enabled
end

local function DeleteRule(ruleName)
	wipe(addon.db.global.rules[ruleName or private.status.ruleName])

	local ruleGroup = private.status.ruleGroup
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup()
	ruleGroup:ReleaseChildren()
end

local function ConfirmDeleteRule(ruleName)
	private.CreateCoroutine(function()
		private.RequestConfirmation(L.DeleteRule(ruleName or private.status.ruleName))

		if not coroutine.yield() then
			return
		end

		DeleteRule()
	end)

	coroutine.resume(private.co)
end

local function DuplicateRule(ruleName)
	ruleName = ruleName or private.status.ruleName
	local newRuleName = addon.EnumerateString(ruleName, private.RuleExists)
	addon.db.global.rules[newRuleName] = addon.CloneTable(addon.db.global.rules[ruleName])

	local ruleGroup = private.status.ruleGroup
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(newRuleName)
end

local function RenameRule(ruleName, newRuleName)
	local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")

	if not newRuleName or newRuleName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif ruleName == newRuleName then
		return
	elseif private.RuleExists(newRuleName) then
		return statusLabel:SetText(L.RuleExists(ruleName))
	elseif newRuleName == "__new" then
		return statusLabel:SetText(L["Invalid rule name"])
	end

	addon.db.global.rules[newRuleName] = addon.CloneTable(addon.db.global.rules[ruleName])
	DeleteRule(ruleName or private.status.ruleName)

	local ruleGroup = private.status.ruleGroup
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(newRuleName)
end

private.RuleExists = function(ruleName)
	return addon.db.global.rules[ruleName].type
end

local function UpdateRuleInfo(key, value)
	addon.db.global.rules[private.status.ruleName][key] = value
	private.status.ruleTreeGroup:SetTree(private.GetTreeList())
end

-- AddRuleContent
local function AddRuleContent()
	local ruleGroup = private.status.ruleGroup
	ruleGroup:SetLayout("Flow")

	local ruleNameEditBox = AceGUI:Create("EditBox")
	ruleNameEditBox:SetUserData("elementName", "ruleNameEditBox")
	ruleNameEditBox:SetLabel(NAME)
	ruleNameEditBox:DisableButton(true)
	ruleNameEditBox:SetCallback("OnEnterPressed", function()
		ruleNameEditBox:ClearFocus()
	end)

	local ruleTypeDropdown = AceGUI:Create("Dropdown")
	ruleTypeDropdown:SetUserData("elementName", "ruleTypeDropdown")
	ruleTypeDropdown:SetList(RULE_TYPES)
	ruleTypeDropdown:SetLabel(TYPE)
	ruleTypeDropdown:SetValue("list")

	local addRuleButton = AceGUI:Create("Button")
	addRuleButton:SetUserData("elementName", "addRuleButton")
	addRuleButton:SetText(ADD)
	addRuleButton:SetCallback("OnClick", function(_, _, value)
		AddRule(value, ruleTypeDropdown:GetValue())
	end)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(ruleGroup, { ruleNameEditBox, ruleTypeDropdown, addRuleButton, statusLabel })
end

-- RuleContent
local function RefreshGuildsDropdown(guildsDropdown)
	for guildKey, checked in pairs(addon.db.global.rules[private.status.ruleName].guilds) do
		guildsDropdown:SetItemValue(guildKey, checked)
	end
end

local function treeGroup_OnGroupSelected(treeGroup, _, path)
	local ruleName = private.status.ruleName
	local rule = addon.db.global.rules[ruleName]
	local scrollFrame = private.status.ruleScrollFrame

	scrollFrame:ReleaseChildren()

	if not rule or not rule.type then
		return
	end

	if rule.type == "tab" and strfind(path, "tab") then
		private.LoadTab(scrollFrame, gsub(path, "tab", ""))
	elseif rule.type == "list" and path == "lists" then
		private.LoadListsContent()
	elseif rule.type == "list" and strfind(path, "lists") then
		local _, listName = strsplit("\001", path)
		private.status.listName = listName
		private.LoadList()
	else
		path = "settings"

		local ruleNameEditBox = AceGUI:Create("EditBox")
		ruleNameEditBox:SetUserData("elementName", "ruleNameEditBox")
		ruleNameEditBox:SetFullWidth(true)
		ruleNameEditBox:SetText(ruleName)
		ruleNameEditBox:SetLabel(NAME)
		ruleNameEditBox:DisableButton(true)
		ruleNameEditBox:SetCallback("OnEnterPressed", function(_, _, value)
			RenameRule(ruleName, value)
		end)

		local ruleTypeDropdown = AceGUI:Create("Dropdown")
		ruleTypeDropdown:SetUserData("elementName", "ruleTypeDropdown")
		ruleTypeDropdown:SetRelativeWidth(1 / 2)
		ruleTypeDropdown:SetList(RULE_TYPES)
		ruleTypeDropdown:SetLabel(TYPE)
		ruleTypeDropdown:SetValue(rule.type)
		ruleTypeDropdown:SetCallback("OnValueChanged", function(_, _, ruleType)
			UpdateRuleInfo("type", ruleType)
		end)

		local guildsDropdown = AceGUI:Create("Dropdown")
		guildsDropdown:SetUserData("elementName", "guildsDropdown")
		guildsDropdown:SetRelativeWidth(1 / 2)
		guildsDropdown:SetList(private.GetGuildList())
		guildsDropdown:SetLabel(L["Apply rule to guilds"])
		guildsDropdown:SetMultiselect(true)
		guildsDropdown:SetCallback("OnValueChanged", function(_, _, guild, enabled)
			ApplyRuleToGuild(guild, enabled)
		end)

		local duplicateRuleButton = AceGUI:Create("Button")
		duplicateRuleButton:SetUserData("elementName", "deleteRuleButton")
		duplicateRuleButton:SetText(L["Duplicate"])
		duplicateRuleButton:SetCallback("OnClick", function()
			DuplicateRule(ruleName)
		end)

		local deleteRuleButton = AceGUI:Create("Button")
		deleteRuleButton:SetUserData("elementName", "deleteRuleButton")
		deleteRuleButton:SetText(DELETE)
		deleteRuleButton:SetCallback("OnClick", function()
			ConfirmDeleteRule(ruleName)
		end)

		local statusLabel = AceGUI:Create("Label")
		statusLabel:SetUserData("elementName", "statusLabel")
		statusLabel:SetFullWidth(true)
		statusLabel:SetColor(1, 0, 0)
		statusLabel:SetText()

		private.AddChildren(scrollFrame, {
			ruleNameEditBox,
			ruleTypeDropdown,
			guildsDropdown,
			duplicateRuleButton,
			deleteRuleButton,
			statusLabel,
		})

		RefreshGuildsDropdown(guildsDropdown)
	end

	private.status.rulePath = path
end

local function RuleContent()
	local ruleGroup = private.status.ruleGroup
	ruleGroup:SetLayout("Fill")

	local treeGroup = AceGUI:Create("TreeGroup")
	treeGroup:SetUserData("elementName", "treeGroup")
	treeGroup:SetUserData("children", {})
	treeGroup:SetLayout("Flow")
	treeGroup:SetTree(private.GetTreeList())
	treeGroup:SetCallback("OnGroupSelected", treeGroup_OnGroupSelected)
	private.AddChildren(ruleGroup, { treeGroup })
	private.status.ruleTreeGroup = treeGroup

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
	private.status.ruleScrollFrame = scrollFrame

	treeGroup:SelectByPath(private.status.rulePath or "settings")
end

-- Load
local function SelectRule(ruleGroup, _, rule)
	ruleGroup:ReleaseChildren()
	private.status.ruleName = rule

	if rule == "__new" then
		AddRuleContent()
	else
		RuleContent()
	end
end

private.LoadRules = function(tabGroup)
	tabGroup:SetLayout("Fill")
	local ruleGroup = AceGUI:Create("DropdownGroup")
	ruleGroup:SetUserData("elementName", "ruleGroup")
	ruleGroup:SetUserData("children", {})
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetCallback("OnGroupSelected", SelectRule)

	if private.status.ruleName then
		ruleGroup:SetGroup(private.status.ruleName)
	end

	private.status.ruleGroup = ruleGroup
	return ruleGroup
end
