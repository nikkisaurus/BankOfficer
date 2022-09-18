local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local AceSerializer = LibStub("AceSerializer-3.0")

local restocks = {}
local items = {}
local logs = {}
function private:GetBankScan()
    if not private.bankOpen then
        return addon:Print(L["Scan canceled: bank frame is not open."])
    end

    local guild = private.db.global.guilds[private.guildKey]
    for tab = 1, guild.numTabs do
        QueryGuildBankTab(tab)
    end

    local scanID = time()

    C_Timer.After(98 * guild.numTabs * 0.001, function()
        wipe(restocks)

        for ruleName, rule in pairs(guild.restock) do
            for _, itemID in pairs(rule.ids) do
                restocks[itemID] = rule.quantity

                -- Scan bank for item counts
                for tab = 1, guild.numTabs do
                    logs[tab] = {}
                    -- Get guild bank transactions
                    for index = 1, GetNumGuildBankTransactions(tab) do
                        local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour =
                            GetGuildBankTransaction(tab, index)

                        tinsert(
                            logs[tab],
                            AceSerializer:Serialize(
                                transactionType,
                                name,
                                itemLink,
                                count,
                                moveOrigin or 0,
                                moveDestination or 0,
                                year,
                                month,
                                day,
                                hour
                            )
                        )
                    end

                    -- Get slots for item counts and restock
                    for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
                        local slotItemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)

                        if slotItemID then
                            local _, slotItemCount = GetGuildBankItemInfo(tab, slot)
                            items[slotItemID] = items[slotItemID] and items[slotItemID] + slotItemCount or slotItemCount
                            if slotItemID == itemID then
                                restocks[itemID] = restocks[itemID] - slotItemCount
                            end
                        end
                    end
                end

                -- Remove items from list if min stock is already met
                if restocks[itemID] <= 0 then
                    restocks[itemID] = nil
                end
            end
        end

        local numRestocks = addon.tcount(restocks)
        if numRestocks == 0 then
            return addon:Print(L["Bank is fully stocked."])
        end

        private.db.global.guilds[private.guildKey].scans[scanID] = {
            logs = addon.CloneTable(logs),
            restocks = addon.CloneTable(restocks),
            items = addon.CloneTable(items),
            checked = {},
        }
        addon:Print(format(L["Scan finished: %d restocks."], numRestocks))

        private:RefreshOptions()
    end)

    return scanID
end
