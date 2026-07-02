local Core = _G.WoesAddonsCore
local UI = Core.UI
local Internal = Core.Internal
local UniqueFrameName = Internal.UniqueFrameName
local SetPortraitTextureWithFallback = Internal.SetPortraitTextureWithFallback

function Core.CloseWindow(frame)
    if not frame then
        return
    end

    Core.PlaySound(Core.Sounds.windowClose)
    frame:Hide()
end

function Core.CreateWindow(name, title, width, height, options)
    options = options or {}

    local frame = CreateFrame("Frame", name or UniqueFrameName("Window"), UIParent, options.template or "PortraitFrameTemplate")
    frame:SetSize(width or 640, height or 320)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata(options.strata or "FULLSCREEN")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetClampRectInsets(-10, 42, 10, -10)
    frame:Hide()

    if frame.TitleText then
        frame.TitleText:SetText(title or "")
        frame.TitleText:SetTextColor(1, 0.82, 0.18, 1)
        frame.title = frame.TitleText
    else
        frame.title = Core.CreateLabel(frame, title or "", "GameFontHighlightLarge")
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -14)
    end

    if frame.portrait then
        SetPortraitTextureWithFallback(frame.portrait, options.portraitTexture)
    end

    if frame.Bg and frame.Bg.SetAtlas then
        frame.Bg:SetAtlas("ClassHall_StoneFrame-BackgroundTile", true)
        frame.Bg:SetHorizTile(true)
        frame.Bg:SetVertTile(true)
    end

    if frame.TopTileStreaks then
        frame.TopTileStreaks:SetAlpha(0.5)
    end

    frame.TitleBar = frame.TitleBar or CreateFrame("Frame", nil, frame)
    frame.TitleBar:ClearAllPoints()
    frame.TitleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 60, 0)
    frame.TitleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, 0)
    frame.TitleBar:SetHeight(30)
    frame.TitleBar:EnableMouse(true)
    frame.TitleBar:RegisterForDrag("LeftButton")
    frame.TitleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame.TitleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.closeButton = frame.CloseButton

    if not frame.closeButton then
        frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    end

    frame.closeButton:SetScript("OnClick", function()
        Core.CloseWindow(frame)
    end)

    frame.ViewHost = frame.ViewHost or CreateFrame("Frame", nil, frame)
    frame.ViewHost:ClearAllPoints()
    frame.ViewHost:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -65)
    frame.ViewHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 42)
    frame.ViewHost:EnableMouse(true)

    local footer = CreateFrame("Frame", nil, frame)
    footer:SetPoint("TOPLEFT", frame.ViewHost, "BOTTOMLEFT", 0, -8)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    frame.Footer = footer

    frame:EnableKeyboard(true)
    if frame.SetPropagateKeyboardInput then
        frame:SetPropagateKeyboardInput(true)
    end
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            Core.CloseWindow(self)

            if self.SetPropagateKeyboardInput then
                self:SetPropagateKeyboardInput(false)
            end
        end
    end)
    frame:SetScript("OnShow", function(self)
        if self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(true)
        end
    end)

    function frame:SetView(view)
        if self.View and self.View.GetRoot then
            local oldRoot = self.View:GetRoot()

            if oldRoot then
                oldRoot:Hide()
                oldRoot:SetParent(nil)
            end
        end

        self.View = view

        if not view then
            return self
        end

        if view.AttachToWindow then
            view:AttachToWindow(self)
        end

        if view.GetRoot then
            local root = view:GetRoot()

            if root then
                root:SetParent(self.ViewHost)
                root:ClearAllPoints()
                root:SetAllPoints(self.ViewHost)
                root:Show()
            end
        end

        if view.Refresh then
            view:Refresh()
        end

        return self
    end

    return frame
end

UI.Windows.MainWindow = {
    Create = function(_, name, title, portraitTexture, options)
        options = options or {}
        options.portraitTexture = portraitTexture or options.portraitTexture
        return Core.CreateWindow(name, title, options.width or 800, options.height or 600, options)
    end,
}

function UI:CreateMainWindow(name, title, portraitTexture, options)
    return self.Windows.MainWindow:Create(name, title, portraitTexture, options)
end

function Core.CreateMainWindow(name, title, portraitTexture, options)
    return UI:CreateMainWindow(name, title, portraitTexture, options)
end
