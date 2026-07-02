local Overlay = _G.WoesScrollingOverlay
local Theme = Overlay.Theme
local C = Overlay.Constants

function Theme.GetDefaultThemeKey()
    local faction = type(UnitFactionGroup) == "function" and UnitFactionGroup("player")

    if faction == "Horde" then
        return "horde"
    elseif faction == "Alliance" then
        return "alliance"
    end

    return "basic"
end

function Theme.GetClassThemeColors()
    local localizedClass
    local className

    if type(UnitClass) == "function" then
        localizedClass, className = UnitClass("player")
    end

    local colors = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
    local color = colors and className and colors[className]
    local r = tonumber(color and color.r) or 1
    local g = tonumber(color and color.g) or 1
    local b = tonumber(color and color.b) or 1

    return { r * 0.35, g * 0.35, b * 0.35, 0.72 }, { r, g, b, 0.9 }, { 1, 1, 1, 1 }
end

function Theme.GetClassDisplayName()
    if type(UnitClass) == "function" then
        local localizedClass = UnitClass("player")

        if localizedClass and localizedClass ~= "" then
            return localizedClass
        end
    end

    return "Class"
end

function Theme.GetColors()
    local options = Overlay.State.options

    if options.theme == "custom" then
        return {
            tonumber(options.customBackgroundR) or 0,
            tonumber(options.customBackgroundG) or 0,
            tonumber(options.customBackgroundB) or 0,
            tonumber(options.customBackgroundA) or 0.62,
        }, {
            tonumber(options.customBorderR) or 1,
            tonumber(options.customBorderG) or 0.82,
            tonumber(options.customBorderB) or 0.18,
            tonumber(options.customBorderA) or 0.85,
        }, {
            tonumber(options.customTextR) or 1,
            tonumber(options.customTextG) or 1,
            tonumber(options.customTextB) or 1,
            tonumber(options.customTextA) or 1,
        }
    end

    if options.theme == "class" then
        return Theme.GetClassThemeColors()
    end

    local theme = C.THEMES[options.theme] or C.THEMES[Theme.GetDefaultThemeKey()] or C.THEMES.basic
    return theme.background, theme.border, theme.text or C.THEMES.basic.text
end
