local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function BankOfficer:GUILDBANKFRAME_OPENED()
	private.status.bankOpen = true
end

function BankOfficer:GUILDBANKFRAME_CLOSED()
	private.status.bankOpen = nil
end

local stocked = {}
function private:OrganizeBank()
	private.status.cancelOrganize = nil
	print("Starting organize bank.")
	private.status.organizeBucket =
		BankOfficer:RegisterBucketEvent("GUILDBANKBAGSLOTS_CHANGED", 1, "GUILDBANKBAGSLOTS_CHANGED")
	wipe(stocked)
	private.status.queryTab = 1

	SetCurrentGuildBankTab(private.status.queryTab)
	QueryGuildBankTab(private.status.queryTab)
end

function BankOfficer:GUILDBANKBAGSLOTS_CHANGED()
	if not private.status.bankOpen then
		BankOfficer:UnregisterBucket(private.status.organizeBucket)
		return BankOfficer:Print(L["Organize canceled: bank frame is not open."])
	elseif private.status.cancelOrganize then
		BankOfficer:UnregisterBucket(private.status.organizeBucket)
		return BankOfficer:Print(L["Organize has been canceled."])
	end

	local numTabs = #private.db.global.guilds[private.guildKey]

	-- If tab exists then
	local targetTab = private.status.queryTab
	if targetTab and targetTab <= numTabs then
		SetCurrentGuildBankTab(private.status.queryTab)
		_G["GuildBankTab" .. private.status.queryTab].Button:Click()
		-- Scan tab slots
		for targetSlot = 1, 98 do
			local queryNext
			if targetSlot == 98 then
				private.status.queryTab = private.status.queryTab + 1
				queryNext = true
			end
			-- Check if slot is in database
			local slotDB = private.db.global.organize[private.guildKey][targetTab][targetSlot]

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
						for sourceTab, _ in pairs(private.db.global.restockTabs[private.guildKey]) do
							QueryGuildBankTab(sourceTab)
							for sourceSlot = 1, 98 do
								local sourceItemID =
									private:ValidateItem(GetGuildBankItemLink(sourceTab, sourceSlot) or 0)
								if
									sourceItemID
									and not private.db.global.organize[private.guildKey][sourceTab][sourceSlot]
									and sourceItemID == slotDB.itemID
								then
									local _, sourceItemCount = GetGuildBankItemInfo(sourceTab, sourceSlot)

									if sourceItemCount == stockNeeded then
										PickupGuildBankItem(sourceTab, sourceSlot)
										PickupGuildBankItem(targetTab, targetSlot)
										stocked[targetTab .. ":" .. targetSlot] = true
										if queryNext then
											QueryGuildBankTab(private.status.queryTab)
										end
										return
									elseif sourceItemCount > stockNeeded then
										SplitGuildBankItem(sourceTab, sourceSlot, stockNeeded)
										PickupGuildBankItem(targetTab, targetSlot)
										stocked[targetTab .. ":" .. targetSlot] = true
										if queryNext then
											QueryGuildBankTab(private.status.queryTab)
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
	else
		print("Organize bank finished.")
		BankOfficer:UnregisterBucket(private.status.organizeBucket)
	end
end
