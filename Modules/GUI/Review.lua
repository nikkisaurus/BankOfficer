local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:GetReviewOptions(guildKey, scans)
	local options = {
		delete = {
			order = 1,
			type = "select",
			style = "dropdown",
			name = L["Delete Scan"],
			values = function()
				local values = {}

				for scanID, _ in pairs(scans) do
					values[tostring(scanID)] = date(private.db.global.settings.dateFormat, scanID)
				end

				return values
			end,
			disabled = function()
				return addon.tcount(scans) == 0
			end,
			confirm = function(_, value)
				value = tonumber(value)
				return format(
					L['Are you sure you want to remove the scan "%s" from %s?'],
					date(private.db.global.settings.dateFormat, value),
					guildKey
				)
			end,
			set = function(_, value)
				value = tonumber(value)
				private.db.global.guilds[guildKey].scans[value] = nil
				private:RefreshOptions(guildKey, "review")
			end,
		},
	}

	local i = 1
	for scanID, scan in
		addon.pairs(scans, function(a, b)
			return a > b
		end)
	do
		options["scan" .. scanID] = {
			order = i,
			type = "group",
			name = date(private.db.global.settings.dateFormat, scanID),
			-- childGroups = "tab",
			args = {
				logs = {
					type = "group",
					name = L["Logs"],
					args = {},
				},
				restock = {
					type = "group",
					name = L["Restock"],
					args = {},
				},
				stocked = {
					type = "group",
					name = L["Stocked"],
					args = {},
				},
			},
		}
		i = i + 1

		local sorted = {}
		for itemID, quantity in pairs(scan.restocks) do
			addon.CacheItem(itemID, function(itemID, options, quantity)
				local itemName, itemLink = GetItemInfo(itemID)
				options.restock.args["item:" .. itemID] = {
					type = "toggle",
					width = "full",
					name = format("%s x%d", itemLink, quantity),
					get = function()
						return scan.checked[itemID]
					end,
					hidden = function()
						return scan.checked[itemID]
					end,
					set = function(_, value)
						private.db.global.guilds[guildKey].scans[scanID].checked[itemID] = value
					end,
				}
				options.stocked.args["item:" .. itemID] = {
					type = "toggle",
					width = "full",
					name = format("%s x%d", itemLink, quantity),
					get = function()
						return scan.checked[itemID]
					end,
					hidden = function()
						return not scan.checked[itemID]
					end,
					set = function(_, value)
						private.db.global.guilds[guildKey].scans[scanID].checked[itemID] = value
					end,
				}
			end, options["scan" .. scanID].args, quantity)
		end
	end

	return options
end
