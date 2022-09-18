local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function addon:GUILDBANKFRAME_OPENED()
    private.bankOpen = true
end

function addon:GUILDBANKFRAME_CLOSED()
    private.bankOpen = false
end

local stocked = {}
function private:OrganizeBank()
    if not private.bankOpen then
        return addon:Print(L["Organize canceled: bank frame is not open."])
    end
    private.cancelOrganize = nil
    addon:Print("Starting organize bank.")
    private.organizeBucket = addon:RegisterBucketEvent("GUILDBANKBAGSLOTS_CHANGED", 1, "GUILDBANKBAGSLOTS_CHANGED")
    wipe(stocked)
    private.queryTab = 1

    SetCurrentGuildBankTab(private.queryTab)
    QueryGuildBankTab(private.queryTab)
end

function addon:GUILDBANKBAGSLOTS_CHANGED()
    if not private.bankOpen then
        addon:UnregisterBucket(private.organizeBucket)
        return addon:Print(L["Organize canceled: bank frame is not open."])
    elseif private.cancelOrganize then
        addon:UnregisterBucket(private.organizeBucket)
        return addon:Print(L["Organize has been canceled."])
    end

    -- If tab exists then
    local targetTab = private.queryTab
    if targetTab and targetTab <= private.db.global.guilds[private.guildKey].numTabs then
        SetCurrentGuildBankTab(private.queryTab)
        _G["GuildBankTab" .. private.queryTab].Button:Click()
        -- Scan tab slots
        for targetSlot = 1, 98 do
            local queryNext
            if targetSlot == 98 then
                private.queryTab = private.queryTab + 1
                queryNext = true
            end
            -- Check if slot is in database
            local tab = private.db.global.guilds[private.guildKey].organize[targetTab]
            local slotDB = tab and tab[targetSlot]

            if slotDB and slotDB.itemID then
                -- Get info about the target slot
                local targetItemID = GetItemInfoInstant(GetGuildBankItemLink(targetTab, targetSlot) or 0)
                local _, targetItemCount = GetGuildBankItemInfo(targetTab, targetSlot)

                -- Get database stack info
                local userFunc = loadstring("return " .. slotDB.stack)
                if type(userFunc) == "function" then
                    local success, GetStack = pcall(userFunc)
                    local stockNeeded = GetStack() - targetItemCount

                    -- Compare target slot to database
                    if
                        not stocked[targetTab .. ":" .. targetSlot] and not targetItemID
                        or targetItemID ~= slotDB.itemID
                        or targetItemCount < GetStack()
                    then
                        -- Restock
                        for sourceTab, enabled in pairs(private.db.global.guilds[private.guildKey].restockTabs) do
                            if enabled == true then
                                QueryGuildBankTab(sourceTab)
                                for sourceSlot = 1, 98 do
                                    local sourceItemID =
                                        GetItemInfoInstant(GetGuildBankItemLink(sourceTab, sourceSlot) or 0)
                                    if
                                        sourceItemID
                                        and not (private.db.global.guilds[private.guildKey].organize[sourceTab] and private.db.global.guilds[private.guildKey].organize[sourceTab][sourceSlot])
                                        and sourceItemID == slotDB.itemID
                                    then
                                        local _, sourceItemCount = GetGuildBankItemInfo(sourceTab, sourceSlot)

                                        if sourceItemCount > stockNeeded then
                                            SplitGuildBankItem(sourceTab, sourceSlot, stockNeeded)
                                            PickupGuildBankItem(targetTab, targetSlot)
                                            stocked[targetTab .. ":" .. targetSlot] = true
                                            if queryNext then
                                                QueryGuildBankTab(private.queryTab)
                                            end
                                            return
                                        else
                                            PickupGuildBankItem(sourceTab, sourceSlot)
                                            PickupGuildBankItem(targetTab, targetSlot)
                                            stocked[targetTab .. ":" .. targetSlot] = true
                                            if queryNext then
                                                QueryGuildBankTab(private.queryTab)
                                            end
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        addon:Print("Organize bank finished.")
        addon:UnregisterBucket(private.organizeBucket)
    end
end
