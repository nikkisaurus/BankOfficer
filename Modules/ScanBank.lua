local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local rules = {}
local function GetGuildRules()
	wipe(rules)
	for ruleName, rule in pairs(addon.db.global.rules) do
		if rule.guilds[private.GetGuildKey()] then
			tinsert(rules, ruleName)
		end
	end
	return rules
end

local items = {}
local function ScanList(guild, rule)
	local numTabs = guild.tabsPurchased
	wipe(items)

	for listName, list in pairs(rule.lists) do
		for itemID, itemInfo in pairs(list.itemIDs) do
			local guildTabs = itemInfo.guilds[guild]
			items[itemID] = list.min

			-- Scan bank for item counts
			for tab = 1, numTabs do
				if guildTabs[tab] then
					for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
						local slotItemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
						if slotItemID and slotItemID == itemID then
							local _, slotItemCount = GetGuildBankItemInfo(tab, slot)
							items[itemID] = items[itemID] - slotItemCount
						end
					end
				end
			end

			-- Remove items from list if min stock is already met
			if items[itemID] <= 0 then
				items[itemID] = nil
			end
		end
	end

	local numRestocks = addon.tcount(items)
	if numRestocks == 0 then
		return addon:Print("Bank is fully stocked") --TODO: localize
	end

	local scanID = time()
	local scan = addon.db.global.scans[scanID]
	scan.guild = guild
	scan.type = "list"
	scan.restocks = addon.CloneTable(items)
	addon:Print(format("Scan finished: %d restocks", numRestocks)) --TODO: localize, add rule name
	private.LoadScanFrame(scanID)
end

private.ScanBank = function(ruleName)
	local ruleName = strjoin(" ", unpack(ruleName))

	local rules = GetGuildRules()
	if not ruleName or ruleName == "" then
		if #rules == 0 then
			return
		elseif #rules > 1 then
			return addon:Print("Specify ruleName: " .. strjoin(", ", unpack(rules))) --TODO: localize
		end
		ruleName = unpack(rules)
	end

	local rule = addon.db.global.rules[ruleName]
	local guild = addon.db.global.guilds[private.GetGuildKey()]
	for tab = 1, guild.tabsPurchased do
		QueryGuildBankTab(tab)
	end

	if rule.type == "list" then
		C_Timer.After(98 * guild.tabsPurchased * 0.001, function()
			ScanList(guild, rule)
		end)
	elseif rule.type == "tab" then
	end
end
