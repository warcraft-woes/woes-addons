local Overlay = _G.WoesScrollingOverlay
local DB = Overlay.DB
local Trackers = Overlay.Trackers
local Ticker = Overlay.Ticker
local Settings = Overlay.Settings

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...

        if addonName ~= Overlay.name then
            return
        end

        DB.Ensure()
        Settings.CreatePanel()
        Trackers.TrackLowestHealth()
        Ticker.ApplyTheme()
        Ticker.ApplyBorderWidth()
        Ticker.ApplyLayout()
        Ticker.ApplyConfiguredItems()
        Ticker.Start()
        if Overlay.Core.RegisterLoadedAddon then
            Overlay.Core.RegisterLoadedAddon("Scrolling Overlay")
        end
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_MONEY")
        eventFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
        eventFrame:RegisterEvent("CHAT_MSG_LOOT")
        eventFrame:RegisterEvent("UNIT_HEALTH")
        eventFrame:RegisterEvent("UNIT_MAXHEALTH")
        eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        Trackers.RecordGoldSample()
        Trackers.TrackLowestHealth()
        Ticker.ApplyConfiguredItems()
    elseif event == "PLAYER_MONEY" then
        Trackers.RecordGoldSample()
        Ticker.ApplyConfiguredItems()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...

        if unit == "player" and Trackers.TrackLowestHealth() then
            Ticker.ApplyConfiguredItems()
        end
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        Trackers.AddKillXPSample(Trackers.ParseCombatXP(...))
        Ticker.ApplyConfiguredItems()
    elseif event == "CHAT_MSG_LOOT" then
        local itemLink, quantity = Trackers.ParseLootMessage(...)

        if itemLink then
            Trackers.QueueLootTickerItem(itemLink, quantity)
            Ticker.ApplyConfiguredItems()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "SKILL_LINES_CHANGED" then
        Ticker.ApplyConfiguredItems()
    end
end)

SLASH_WOESSCROLLINGOVERLAY1 = "/woesscrollingoverlay"
SLASH_WOESSCROLLINGOVERLAY2 = "/wso"

SlashCmdList.WOESSCROLLINGOVERLAY = function(message)
    local command = string.match(string.lower(message or ""), "^(%S*)")

    if command == "" or command == "config" then
        Overlay.ToggleConfig()
    elseif command == "settings" or command == "options" then
        if not Settings.Open() then
            Overlay.Print("Settings are available from Game Menu > Options > AddOns.")
        end
    elseif command == "toggle" then
        if Ticker.IsRunning() then
            Ticker.Stop()
            Overlay.Print("Stopped.")
        else
            Ticker.Start()
            Overlay.Print("Started.")
        end
    else
        Overlay.Print("Commands: /wso, /wso settings, /wso toggle")
    end
end
