local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:GetRestockRules(guildKey, rules)
    local guild = private.db.global.guilds[guildKey]

    local options = {
        new = {
            order = 1,
            type = "execute",
            name = L["Add Rule"],
            func = function()
                local ruleName = private:AddRestockRule(guildKey, "New")
                private:RefreshOptions(guildKey, "restock", ruleName)
            end,
        },
        remove = {
            order = 2,
            type = "select",
            style = "dropdown",
            name = L["Remove Rule"],
            values = function()
                local values = {}

                for ruleName, _ in pairs(rules) do
                    values[ruleName] = ruleName
                end

                return values
            end,
            disabled = function()
                return addon.tcount(rules) == 0
            end,
            confirm = function(_, value)
                return format(L["Are you sure you want to remove the restock rule \"%s\" from %s?"], value, guildKey)
            end,
            set = function(_, value)
                private:RemoveRestockRule(guildKey, value)
                private:RefreshOptions(guildKey, "restock")
            end,
        },

        restockTabs = {
            order = 3,
            type = "multiselect",
            style = "dropdown",
            name = L["Restock Tabs"],
            values = function()
                local values = {}

                for tab = 1, guild.numTabs do
                    values[tab] = L["Tab"] .. " " .. tab
                end

                return values
            end,
            get = function(_, value)
                return private.db.global.guilds[guildKey].restockTabs[value]
            end,
            set = function(_, value, checked)
                private.db.global.guilds[guildKey].restockTabs[value] = checked and true or false
            end,
        },
    }

    for ruleName, rule in addon.pairs(rules) do
        options[ruleName] = {
            type = "group",
            name = ruleName,
            args = {
                rename = {
                    order = 1,
                    type = "input",
                    name = L["Rule Name"],
                    get = function()
                        return ruleName
                    end,
                    validate = function(_, value)
                        return not private.RestockRuleExists(value, guildKey)
                    end,
                    set = function(_, value)
                        local newRuleName = private:RenameRestockRule(guildKey, ruleName, value)
                        private:RefreshOptions(guildKey, "restock", newRuleName)
                    end,
                },
                quantity = {
                    order = 2,
                    type = "input",
                    name = L["Quantity"],
                    get = function(info)
                        return tostring(rule[info[#info]])
                    end,
                    validate = function(_, value)
                        value = tonumber(value) or 0
                        return value >= 0
                    end,
                    set = function(info, value)
                        value = tonumber(value) or 0
                        private.db.global.guilds[guildKey].restock[ruleName][info[#info]] = value
                    end,
                },
                ids = {
                    order = 4,
                    type = "group",
                    inline = true,
                    name = L["Items"],
                    args = private:GetRestockRuleIDs(guildKey, ruleName),
                },
            },
        }
    end

    return options
end

function private:GetRestockRuleIDs(guildKey, ruleName)
    local options = {
        itemID = {
            order = 3,
            type = "input",
            width = "full",
            name = "",
            set = function(_, value)
                addon.CacheItem(value, function(itemID)
                    tinsert(private.db.global.guilds[guildKey].restock[ruleName].ids, itemID)
                    private:RefreshOptions()
                end)
            end,
        },
    }

    for key, itemID in pairs(private.db.global.guilds[guildKey].restock[ruleName].ids) do
        addon.CacheItem(itemID, function(itemID, private, options)
            if not private.db.global.guilds[guildKey].restock[ruleName].ids[key] then
                return
            end

            local itemName = GetItemInfo(itemID)

            options["item:" .. itemID] = {
                type = "input",
                dialogControl = "BankOfficer_ListButton",
                width = "full",
                name = itemName,
                set = function(widget)
                    private.db.global.guilds[guildKey].restock[ruleName].ids[key] = nil
                    private:RefreshOptions(guildKey, "restock", ruleName)
                end,
            }
        end, private, options)
    end

    return options
end
