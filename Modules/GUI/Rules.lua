local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:GetRulesOptions(guildKey)
    local guild = private.db.global.guilds[guildKey]
    local options = {
        restock = {
            order = 1,
            type = "group",
            name = L["Restock"],
            childGroups = "select",
            args = private:GetRestockRules(guildKey, guild.restock),
        },
        organize = {
            order = 2,
            type = "group",
            name = L["Organize"],
            childGroups = "tab",
            args = private:GetOrganizeOptions(guildKey, guild.organize),
        },
    }

    return options
end
