local Overlay = _G.WoesScrollingOverlay
local Settings = Overlay.Settings
local Core = Overlay.Core
local C = Overlay.Constants
local State = Overlay.State
local Theme = Overlay.Theme
local Ticker = Overlay.Ticker
local Trackers = Overlay.Trackers
local Utils = Overlay.Utils

local optionsPanel
local optionsCategory

function Settings.Refresh()
    if optionsPanel and optionsPanel.SettingsCanvas then
        optionsPanel.SettingsCanvas:Refresh()
    end
end

local function SetOptionValue(key, value)
    local optionUpdate = { [key] = value }

    if string.find(key, "^custom") then
        optionUpdate.theme = "custom"
    end

    Ticker.SetOptions(optionUpdate)

    if string.find(key, "^custom") or key == "height" or key == "showLootItems" or key == "theme" then
        Settings.Refresh()
    end
end

local function OptionConfig(key, config)
    config = config or {}
    config.key = key
    config.get = function()
        return State.options[key]
    end
    config.set = function(value)
        SetOptionValue(key, value)
    end
    return config
end

local function ThemeColorConfig(prefix, label, x, y)
    return {
        label = label,
        x = x,
        y = y,
        get = function()
            return State.options[prefix .. "R"], State.options[prefix .. "G"], State.options[prefix .. "B"], State.options[prefix .. "A"]
        end,
        set = function(r, g, b, a)
            Ticker.SetOptions({
                theme = "custom",
                [prefix .. "R"] = r,
                [prefix .. "G"] = g,
                [prefix .. "B"] = b,
                [prefix .. "A"] = a,
            })
            Settings.Refresh()
        end,
    }
end

local function ResetDisplayOptions()
    Ticker.SetOptions({
        height = C.DEFAULT_OPTIONS.height,
        borderWidth = C.DEFAULT_OPTIONS.borderWidth,
        gap = C.DEFAULT_OPTIONS.gap,
        speed = C.DEFAULT_OPTIONS.speed,
        textSize = C.DEFAULT_OPTIONS.textSize,
        y = C.DEFAULT_OPTIONS.y,
        pixelSnap = C.DEFAULT_OPTIONS.pixelSnap,
        showLootItems = C.DEFAULT_OPTIONS.showLootItems,
        lootThreshold = C.DEFAULT_OPTIONS.lootThreshold,
    })
    Settings.Refresh()
end

local function ResetThemeOptions()
    Ticker.SetOptions({
        theme = Theme.GetDefaultThemeKey(),
        customBackgroundR = C.DEFAULT_OPTIONS.customBackgroundR,
        customBackgroundG = C.DEFAULT_OPTIONS.customBackgroundG,
        customBackgroundB = C.DEFAULT_OPTIONS.customBackgroundB,
        customBackgroundA = C.DEFAULT_OPTIONS.customBackgroundA,
        customBorderR = C.DEFAULT_OPTIONS.customBorderR,
        customBorderG = C.DEFAULT_OPTIONS.customBorderG,
        customBorderB = C.DEFAULT_OPTIONS.customBorderB,
        customBorderA = C.DEFAULT_OPTIONS.customBorderA,
        customTextR = C.DEFAULT_OPTIONS.customTextR,
        customTextG = C.DEFAULT_OPTIONS.customTextG,
        customTextB = C.DEFAULT_OPTIONS.customTextB,
        customTextA = C.DEFAULT_OPTIONS.customTextA,
    })
    Settings.Refresh()
end

function Settings.Open()
    if not optionsPanel then
        Settings.CreatePanel()
    end

    if not optionsPanel then
        return false
    end

    if Core.OpenSettingsPanel then
        return Core.OpenSettingsPanel(optionsPanel)
    end

    if type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        return true
    end

    return false
end

function Settings.CreatePanel()
    if optionsPanel then
        return optionsPanel
    end

    local panel = CreateFrame("Frame", Overlay.name .. "OptionsPanel")
    panel.name = Overlay.displayName
    panel:SetSize(920, 640)

    local canvas = Core.CreateSettingsCanvas(panel, {
        title = Overlay.displayName,
        description = "Use this panel for display settings and maintenance. Use /wso for ticker rows.",
    })
    panel.SettingsCanvas = canvas

    canvas:AddActionButton("Open Ticker Rows", 140, function()
        Overlay.ToggleConfig()
    end)

    local settingsToggleButton
    local function RefreshSettingsToggleButton()
        if settingsToggleButton then
            settingsToggleButton:SetText(Ticker.IsRunning() and "Stop Overlay" or "Start Overlay")
        end
    end

    settingsToggleButton = canvas:AddActionButton("", 116, function()
        if Ticker.IsRunning() then
            Ticker.Stop()
        else
            Ticker.Start()
        end

        RefreshSettingsToggleButton()
    end)
    panel.RefreshOverlayToggleButton = RefreshSettingsToggleButton
    RefreshSettingsToggleButton()

    canvas:AddActionButton("Reset Lowest HP", 140, function()
        Trackers.ResetLowestHealth()
        Overlay.Print("Lowest HP tracker reset.")
    end)

    canvas:AddActionButton("Reset Display", 120, ResetDisplayOptions)

    local themeChoices = {}

    for _, themeKey in ipairs(C.THEME_ORDER) do
        local theme = C.THEMES[themeKey]
        themeChoices[#themeChoices + 1] = {
            value = themeKey,
            label = themeKey == "class" and Theme.GetClassDisplayName() or (theme and theme.label or themeKey),
        }
    end

    canvas:AddDivider("Display")
    local displayBlock, displayGrid = canvas:AddGrid(5, 240, {
        cols = 12,
        padding = 0,
        gutter = { x = 12, y = 10 },
    })
    local appearanceSection = Core.CreateSettingsSection(displayBlock, "Appearance", "Size and text rendering. Changes apply immediately.")
    local movementSection = Core.CreateSettingsSection(displayBlock, "Movement", "Scroll speed, vertical placement, and spacing between ticker items.")
    displayGrid:Add(appearanceSection, { x = 0, y = 0, w = 6, h = 5 })
    displayGrid:Add(movementSection, { x = 6, y = 0, w = 6, h = 5 })

    canvas:RegisterControl(Core.CreateSettingsSlider(appearanceSection, OptionConfig("height", {
        label = "Height",
        min = 20,
        max = 80,
        step = 1,
        x = 14,
        y = -64,
        width = 320,
    })))
    canvas:RegisterControl(Core.CreateSettingsSlider(appearanceSection, OptionConfig("textSize", {
        label = "Text Size",
        min = 8,
        max = 32,
        step = 1,
        x = 14,
        y = -116,
        width = 320,
    })))
    canvas:RegisterControl(Core.CreateSettingsSlider(appearanceSection, OptionConfig("borderWidth", {
        label = "Border Width",
        min = 0,
        max = 10,
        step = 1,
        x = 14,
        y = -168,
        width = 320,
    })))
    canvas:RegisterControl(Core.CreateSettingsCheck(appearanceSection, OptionConfig("pixelSnap", {
        label = "Pixel Snap",
        x = 14,
        y = -216,
    })))
    canvas:RegisterControl(Core.CreateSettingsSlider(movementSection, OptionConfig("speed", {
        label = "Speed",
        min = 10,
        max = 160,
        step = 1,
        x = 14,
        y = -64,
        width = 320,
    })))
    canvas:RegisterControl(Core.CreateSettingsSlider(movementSection, OptionConfig("y", {
        label = "Y Offset From Bottom",
        min = 0,
        max = function()
            return math.max(0, math.floor((UIParent:GetHeight() or 800) - (State.options.height or C.DEFAULT_OPTIONS.height)))
        end,
        step = 1,
        x = 14,
        y = -116,
        width = 320,
    })))
    canvas:RegisterControl(Core.CreateSettingsSlider(movementSection, OptionConfig("gap", {
        label = "Gap",
        min = 0,
        max = 240,
        step = 1,
        x = 14,
        y = -168,
        width = 320,
    })))

    canvas:AddDivider("Tracking")
    local trackingBlock, trackingGrid = canvas:AddGrid(5, 240, {
        cols = 12,
        padding = 0,
        gutter = { x = 12, y = 10 },
    })
    local trackingSection = Core.CreateSettingsSection(trackingBlock, "Loot And Tracking", "Loot one-shots and lightweight local trackers.")
    trackingGrid:Add(trackingSection, { x = 0, y = 0, w = 12, h = 5 })

    canvas:RegisterControl(Core.CreateSettingsCheck(trackingSection, OptionConfig("showLootItems", {
        label = "Show Loot Items",
        x = 14,
        y = -64,
    })))
    canvas:RegisterControl(Core.CreateSettingsSlider(trackingSection, OptionConfig("lootThreshold", {
        label = "Loot Quality",
        min = 0,
        max = 5,
        step = 1,
        x = 14,
        y = -112,
        width = 320,
        formatValue = Utils.FormatItemQuality,
        enabled = function()
            return State.options.showLootItems and true or false
        end,
    })))

    canvas:AddDivider("Theme")
    local themeBlock, themeGrid = canvas:AddGrid(5, 240, {
        cols = 12,
        padding = 0,
        gutter = { x = 12, y = 10 },
    })
    local themeSection = Core.CreateSettingsSection(themeBlock, "Theme", "Choose a preset or reset the current theme.")
    local customColourSection = Core.CreateSettingsSection(themeBlock, "Custom Colours", "Use the colour pickers for ticker background, border, and text.")

    local function RefreshThemeLayout()
        themeGrid:Clear()
        themeSection:Show()

        if State.options.theme == "custom" then
            customColourSection:Show()
            themeGrid:Add(themeSection, { x = 0, y = 0, w = 6, h = 5 })
            themeGrid:Add(customColourSection, { x = 6, y = 0, w = 6, h = 5 })
        else
            customColourSection:Hide()
            themeGrid:Add(themeSection, { x = 0, y = 0, w = 12, h = 5 })
        end
    end

    canvas:RegisterControl({ Refresh = RefreshThemeLayout })
    RefreshThemeLayout()

    canvas:RegisterControl(Core.CreateSettingsDropdown(themeSection, OptionConfig("theme", {
        label = "Theme Preset",
        choices = themeChoices,
        name = Overlay.name .. "ThemeDropdown",
        x = 14,
        y = -64,
        width = 140,
    })))
    canvas:RegisterControl(Core.CreateSettingsButton(themeSection, {
        text = "Reset Theme",
        width = 110,
        x = 14,
        y = -128,
        onClick = ResetThemeOptions,
    }))
    canvas:RegisterControl(Core.CreateSettingsColorPicker(customColourSection, ThemeColorConfig("customBackground", "Background", 14, -58)))
    canvas:RegisterControl(Core.CreateSettingsColorPicker(customColourSection, ThemeColorConfig("customBorder", "Border", 14, -112)))
    canvas:RegisterControl(Core.CreateSettingsColorPicker(customColourSection, ThemeColorConfig("customText", "Text", 14, -166)))

    panel:SetScript("OnShow", function(self)
        if self.RefreshOverlayToggleButton then
            self:RefreshOverlayToggleButton()
        end

        if self.SettingsCanvas then
            self.SettingsCanvas:Refresh()
        end
    end)

    if Core.RegisterSettingsPanel then
        optionsCategory = Core.RegisterSettingsPanel(panel, "Scrolling Overlay")
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    end

    optionsPanel = panel
    return panel
end

function Settings.GetCategory()
    return optionsCategory
end
