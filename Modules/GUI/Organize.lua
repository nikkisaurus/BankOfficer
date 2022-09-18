local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local LGBC = LibStub("LibGuildBankComm-1.0")

function private:GetOrganizeOptions(guildKey, organize)
    local guild = private.db.global.guilds[guildKey]

    local options = {
        duplicate = {
            order = 2,
            type = "toggle",
            name = L["Duplicate Mode"],
            get = function(info)
                return private.organizeEditMode == info[#info]
            end,
            set = function(info, value)
                private.organizeEditMode = value and info[#info]
                ClearCursor()
            end,
        },
        clear = {
            order = 3,
            type = "toggle",
            name = L["Clear Mode"],
            get = function(info)
                return private.organizeEditMode == info[#info]
            end,
            set = function(info, value)
                private.organizeEditMode = value and info[#info]
                ClearCursor()
            end,
        },
        stack = {
            order = 4,
            type = "input",
            multiline = true,
            width = "full",
            name = function()
                if private.organizeEditSlot and private.organizeEditSlot.guildKey == guildKey then
                    return format("%s: %s %d", L["Stack"], L["Slot"], private.organizeEditSlot.slotID)
                else
                    return L["Stack"]
                end
            end,
            get = function()
                if not private.organizeEditSlot or private.organizeEditSlot.guildKey ~= guildKey then
                    return
                end

                return private.db.global.guilds[private.organizeEditSlot.guildKey].organize[private.organizeEditSlot.tab][private.organizeEditSlot.slotID].stack
            end,
            set = function(_, value)
                private.db.global.guilds[private.organizeEditSlot.guildKey].organize[private.organizeEditSlot.tab][private.organizeEditSlot.slotID].stack =
                    value
                private.organizeEditSlot = nil
                private:RefreshOptions()
            end,
            validate = function(_, value)
                local func = loadstring("return " .. value)
                if type(func) == "function" then
                    local success, userFunc = pcall(func)
                    if success then
                        local ret = userFunc()

                        return tonumber(ret)
                    end
                end
            end,
            disabled = function()
                return not private.organizeEditSlot or private.organizeEditSlot.guildKey ~= guildKey
            end,
        },
    }

    for tab = 1, guild.numTabs do
        options["tab" .. tab] = {
            order = tab,
            type = "group",
            width = "full",
            name = format("%s %d", L["Tab"], tab),
            disabled = function()
                return private.db.global.guilds[guildKey].restockTabs[tab]
            end,
            args = {
                organizeGroup = {
                    order = 1,
                    type = "input",
                    dialogControl = "BankOfficer_OrganizeGroup",
                    width = "full",
                    name = guildKey .. ":" .. tab,
                },
            },
        }
    end

    return options
end
