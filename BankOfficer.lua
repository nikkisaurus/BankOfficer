local addonName, private = ...
local addon =
    LibStub("AceAddon-3.0"):NewAddon(addonName, "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = private.L
LibStub("LibAddonUtils-1.0"):Embed(addon)

private.media = [[INTERFACE/ADDONS/BANKOFFICER/MEDIA/]]

function addon:OnEnable()
    addon:RegisterEvent("GUILDBANKFRAME_OPENED")
    addon:RegisterEvent("GUILDBANKFRAME_CLOSED")
end

function addon:OnInitialize()
    private:InitializeDatabase()
    private:InitializeOptions()
    private:InitializeSlashCommands()

    if private.db.global.debug then
        addon:RegisterEvent("PLAYER_ENTERING_WORLD")
    end
end

function addon:PLAYER_ENTERING_WORLD()
    private:OpenOptions(private.guildKey, "review")
end

function addon:SlashCommandFunc(input)
    input = strlower(input)
    if not input or input:trim() == "" then
        private:OpenOptions(private.db.global.settings.defaultGuild)
    elseif input == "organize" then
        private:OrganizeBank()
    elseif input == "restock" then
        private:GetBankScan()
    end
end

function private:InitializeSlashCommands()
    for command, enabled in pairs(self.db.global.settings.commands) do
        if enabled then
            addon:RegisterChatCommand(command, "SlashCommandFunc")
        else
            addon:UnregisterChatCommand(command)
        end
    end
    return
end
