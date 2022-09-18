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
