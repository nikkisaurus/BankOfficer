local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function delay(tick)
	local th = coroutine.running()
	C_Timer.After(tick, function()
		coroutine.resume(th)
	end)
	coroutine.yield()
end

private.OrganizeBank = function()
	for tab, tabInfo in pairs(private.db.global.guilds[private.guildKey]) do
		QueryGuildBankTab(tab)
		coroutine.yield()
		if not private.db.global.restockTabs[private.guildKey][tab] then
			for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
				local slotInfo = private.db.global.organize[private.guildKey][tab][slot]

				if slotInfo and slotInfo.itemID then
					-- Get guild bank slot info
					local itemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
					local _, itemCount = GetGuildBankItemInfo(tab, slot)

					-- Get database stack info
					local func = loadstring("return " .. slotInfo.stack)
					if type(func) == "function" then
						local success, userFunc = pcall(func)
						local stockNeeded = userFunc() - itemCount

						-- Compare slot to database
						if not itemID or itemID ~= slotInfo.itemID or itemCount < userFunc() then
							-- Restock
							for stockTab, _ in pairs(private.db.global.restockTabs[private.guildKey]) do
								QueryGuildBankTab(stockTab)
								for stockSlot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
									local stockItemID =
										private:ValidateItem(GetGuildBankItemLink(stockTab, stockSlot) or 0)
									if stockItemID and stockItemID == slotInfo.itemID then
										local _, stockItemCount = GetGuildBankItemInfo(stockTab, stockSlot)

										if stockNeeded == stockItemCount then
											PickupGuildBankItem(stockTab, stockSlot)
										else
											SplitGuildBankItem(stockTab, stockSlot, stockNeeded)
										end
										coroutine.yield()
										PickupGuildBankItem(tab, slot)
										coroutine.yield()
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return true
end

function private:StartBankOrganize()
	local co = coroutine.create(private.OrganizeBank)
	local _, restocked = coroutine.resume(co)
	while not restocked do
		_, restocked = coroutine.resume(co)
	end
end
