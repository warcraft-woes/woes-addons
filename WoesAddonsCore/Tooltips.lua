local Core = _G.WoesAddonsCore

local Tooltips = Core.Tooltips

function Tooltips.Attach(frame, text, title)
    if not frame then
        return frame
    end

    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if title and title ~= "" then
            GameTooltip:SetText(title)
            if text and text ~= "" then
                GameTooltip:AddLine(text, 1, 1, 1, true)
            end
        else
            GameTooltip:SetText(text or "")
        end

        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return frame
end

Core:RegisterModule("Tooltips", Tooltips)
