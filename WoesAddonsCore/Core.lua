local Core = _G.WoesAddonsCore
local Internal = Core.Internal

local function ShallowCopy(source)
    local copy = {}

    for key, value in pairs(source or {}) do
        copy[key] = value
    end

    return copy
end

local function NormalizeAxis(value, default)
    default = default or 0

    if type(value) == "table" then
        return {
            x = tonumber(value.x) or tonumber(value[1]) or default,
            y = tonumber(value.y) or tonumber(value[2]) or default,
        }
    end

    local number = tonumber(value) or default
    return { x = number, y = number }
end

local function NormalizePadding(value, default)
    default = default or 0

    if type(value) == "table" then
        if value.left or value.right or value.top or value.bottom then
            return {
                left = tonumber(value.left) or default,
                right = tonumber(value.right) or default,
                top = tonumber(value.top) or default,
                bottom = tonumber(value.bottom) or default,
            }
        end

        local axis = NormalizeAxis(value, default)
        return { left = axis.x, right = axis.x, top = axis.y, bottom = axis.y }
    end

    local number = tonumber(value) or default
    return { left = number, right = number, top = number, bottom = number }
end

local function UniqueFrameName(prefix)
    prefix = prefix or "Frame"

    local index = 1
    local frameName

    repeat
        frameName = string.format("%s_%s_%d", Core.acronym or "WAC", prefix, index)
        index = index + 1
    until not _G[frameName]

    return frameName
end

local function SetBackdrop(frame, alpha)
    if not frame or not frame.SetBackdrop then
        return frame
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, alpha or 0.88)
    frame:SetBackdropBorderColor(0.9, 0.72, 0.28, 0.9)

    return frame
end

local function SetPortraitTextureWithFallback(texture, preferred, fallback)
    if not texture then
        return
    end

    fallback = fallback or Core.defaultIcon

    if type(SetPortraitToTexture) == "function" then
        if preferred and preferred ~= "" and texture:SetTexture(preferred) then
            SetPortraitToTexture(texture, preferred)
        else
            SetPortraitToTexture(texture, fallback)
        end

        texture:Show()
        return
    end

    if preferred and preferred ~= "" and texture:SetTexture(preferred) then
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        texture:Show()
        return
    end

    texture:SetTexture(fallback)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    texture:Show()
end

function Core.CopyDefaults(target, defaults)
    if type(target) ~= "table" then
        target = {}
    end

    if type(defaults) ~= "table" then
        return target
    end

    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = ShallowCopy(value)
            else
                target[key] = value
            end
        end
    end

    return target
end

function Core.SetShown(frame, shown)
    if not frame then
        return
    end

    if shown then
        frame:Show()
    else
        frame:Hide()
    end
end

function Core.SetEnabled(button, enabled)
    if not button then
        return
    end

    if enabled then
        button:Enable()
    else
        button:Disable()
    end
end

Internal.ShallowCopy = ShallowCopy
Internal.NormalizeAxis = NormalizeAxis
Internal.NormalizePadding = NormalizePadding
Internal.UniqueFrameName = UniqueFrameName
Internal.SetBackdrop = SetBackdrop
Internal.SetPortraitTextureWithFallback = SetPortraitTextureWithFallback
