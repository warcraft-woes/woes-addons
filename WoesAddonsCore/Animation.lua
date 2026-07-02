local Core = _G.WoesAddonsCore

local Animation = Core.Animation

function Animation.Fade(frame, fromAlpha, toAlpha, duration, onFinished)
    if not frame or not frame.CreateAnimationGroup then
        if frame and frame.SetAlpha then
            frame:SetAlpha(toAlpha or 1)
        end
        if onFinished then
            onFinished(frame)
        end
        return nil
    end

    local group = frame:CreateAnimationGroup()
    local fade = group:CreateAnimation("Alpha")
    fade:SetFromAlpha(fromAlpha or frame:GetAlpha() or 1)
    fade:SetToAlpha(toAlpha or 1)
    fade:SetDuration(duration or 0.15)

    if onFinished then
        group:SetScript("OnFinished", function()
            onFinished(frame)
        end)
    end

    group:Play()
    return group
end

function Animation.FadeIn(frame, duration)
    if frame then
        frame:Show()
    end

    return Animation.Fade(frame, 0, 1, duration)
end

function Animation.FadeOut(frame, duration)
    return Animation.Fade(frame, frame and frame.GetAlpha and frame:GetAlpha() or 1, 0, duration, function(target)
        if target then
            target:Hide()
            target:SetAlpha(1)
        end
    end)
end

Core:RegisterModule("Animation", Animation)
