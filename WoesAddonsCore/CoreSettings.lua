local Core = _G.WoesAddonsCore

local function CreateCoreSettingsPanel()
    if Core.coreSettingsPanel then
        return Core.coreSettingsPanel
    end

    Core.EnsureDB()

    local panel = CreateFrame("Frame", "WoesAddonsCoreOptionsPanel")
    panel.name = "Core"
    panel:SetSize(680, 420)

    local canvas = Core.CreateSettingsCanvas(panel, {
        title = "Woes AddOns Core",
        description = "Shared settings for Woes AddOns.",
    })
    panel.SettingsCanvas = canvas

    canvas:AddDivider("Messages")
    local block, grid = canvas:AddGrid(3, 140, {
        cols = 12,
        padding = 0,
        gutter = { x = 12, y = 10 },
    })
    local section = Core.CreateSettingsSection(block, "Load Messages", "Control the shared Woes AddOns loaded summary.")
    grid:Add(section, { x = 0, y = 0, w = 12, h = 3 })

    canvas:RegisterControl(Core.CreateSettingsCheck(section, {
        label = "Show loaded summary",
        x = 14,
        y = -64,
        get = function()
            return Core.options.showLoadedMessage
        end,
        set = function(value)
            Core.options.showLoadedMessage = value and true or false
        end,
    }))

    panel:SetScript("OnShow", function(self)
        if self.SettingsCanvas then
            self.SettingsCanvas:Refresh()
        end
    end)

    if Core.RegisterSettingsPanel then
        Core.RegisterSettingsPanel(panel, "Core")
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    end

    Core.coreSettingsPanel = panel
    return panel
end

Core.EnsureDB()
CreateCoreSettingsPanel()
Core.RegisterLoadedAddon("Core")

local loadedSummaryFrame = CreateFrame("Frame")
loadedSummaryFrame:RegisterEvent("PLAYER_LOGIN")
loadedSummaryFrame:SetScript("OnEvent", function()
    Core.PrintLoadedSummary()
    loadedSummaryFrame:UnregisterEvent("PLAYER_LOGIN")
end)

