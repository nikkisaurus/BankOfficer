local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:AddRestockRule(guildKey, ruleName)
	ruleName = addon.IncrementString(ruleName, private, "RestockRuleExists", guildKey)
	private.db.global.guilds[guildKey].restock[ruleName] = addon.CloneTable(private.defaults.restockRule)
	return ruleName
end

function private:RemoveRestockRule(guildKey, ruleName)
	private.db.global.guilds[guildKey].restock[ruleName] = nil
end

function private:RenameRestockRule(guildKey, ruleName, newRuleName)
	newRuleName = addon.IncrementString(newRuleName, private, "RestockRuleExists", guildKey)
	private.db.global.guilds[guildKey].restock[newRuleName] =
		addon.CloneTable(private.db.global.guilds[guildKey].restock[ruleName])
	private.db.global.guilds[guildKey].restock[ruleName] = nil
	return newRuleName
end

function private:RestockRuleExists(guildKey, ruleName)
	return private.db.global.guilds[guildKey].restock[ruleName]
end

local items = {}
private.GetBankRestock = function()
	local guild = private.db.global.guilds[private.guildKey]
	for tab = 1, MAX_GUILDBANK_TABS do
		QueryGuildBankTab(tab)
	end

	local scanID = time()

	C_Timer.After(98 * MAX_GUILDBANK_TABS * 0.001, function()
		wipe(items)

		for ruleName, rule in pairs(guild.restock) do
			for _, itemID in pairs(rule.ids) do
				items[itemID] = rule.quantity

				-- Scan bank for item counts
				for tab = 1, MAX_GUILDBANK_TABS do
					for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
						local slotItemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
						if slotItemID and slotItemID == itemID then
							local _, slotItemCount = GetGuildBankItemInfo(tab, slot)
							items[itemID] = items[itemID] - slotItemCount
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
			return addon:Print(L["Bank is fully stocked."])
		end

		private.db.global.guilds[private.guildKey].scans[scanID] = {
			restocks = addon.CloneTable(items),
			checked = {},
		}
		addon:Print(format(L["Scan finished: %d restocks."], numRestocks))

		private:RefreshOptions()
	end)

	return scanID
end
