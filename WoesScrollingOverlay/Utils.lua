local Overlay = _G.WoesScrollingOverlay
local Utils = Overlay.Utils

function Utils.CopyDefaults(target, defaults)
    local core = Overlay.Core

    if core.CopyDefaults then
        return core.CopyDefaults(target, defaults)
    end

    target = type(target) == "table" and target or {}

    for key, value in pairs(defaults or {}) do
        if target[key] == nil then
            target[key] = value
        end
    end

    return target
end

function Utils.FormatLabeledText(label, text, showLabel)
    if showLabel == false or not label or label == "" then
        return text or ""
    end

    return label .. ": " .. (text or "")
end

function Utils.IconText(texture)
    return texture and ("|T" .. texture .. ":0|t ") or ""
end

function Utils.FormatItemQuality(value)
    local C = Overlay.Constants
    local quality = math.max(0, math.min(5, tonumber(value) or 0))
    local label = C.ITEM_QUALITY_LABELS[quality] or tostring(quality)
    local color = C.ITEM_QUALITY_HEX[quality] or "ffffffff"

    return "|c" .. color .. label .. "|r"
end
