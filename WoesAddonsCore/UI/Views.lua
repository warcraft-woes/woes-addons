local Core = _G.WoesAddonsCore
local UI = Core.UI
local Internal = Core.Internal
local NormalizeAxis = Internal.NormalizeAxis
local NormalizePadding = Internal.NormalizePadding
local SetBackdrop = Internal.SetBackdrop
local ShallowCopy = Internal.ShallowCopy

UI.Views.ContainerView = {}

function UI.Views.ContainerView:Create(options)
    options = options or {}

    local root = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    local padding = NormalizePadding(options.padding, 0)

    if options.backdrop ~= false then
        SetBackdrop(root, options.alpha or 0.35)
    end

    local content = CreateFrame("Frame", nil, root)
    content:SetPoint("TOPLEFT", root, "TOPLEFT", padding.left, -padding.top)
    content:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -padding.right, padding.bottom)

    local view = {}

    function view:GetRoot()
        return root
    end

    function view:GetContent()
        return content
    end

    function view:GetInner()
        return content
    end

    function view:AttachTo(parent)
        root:SetParent(parent)
        root:SetAllPoints(parent)
        return self
    end

    function view:Show()
        root:Show()
        return self
    end

    function view:Hide()
        root:Hide()
        return self
    end

    return view
end

function UI:CreateContainerView(options)
    return self.Views.ContainerView:Create(options)
end

function UI:CreateInsetContainerView(options)
    options = options or {}
    options.backdrop = options.backdrop ~= false
    options.padding = options.padding or 8
    return self.Views.ContainerView:Create(options)
end

function UI:CreateArtisanContainerView(options)
    options = options or {}
    options.backdrop = options.backdrop ~= false
    options.padding = options.padding or 12
    options.alpha = options.alpha or 0.55
    return self.Views.ContainerView:Create(options)
end

function Core.CreateContainerView(options)
    return UI:CreateContainerView(options)
end

function Core.CreateInsetContainerView(options)
    return UI:CreateInsetContainerView(options)
end

function Core.CreateArtisanContainerView(options)
    return UI:CreateArtisanContainerView(options)
end

UI.Views.ScrollView = {}

function UI.Views.ScrollView:Create(options)
    options = options or {}

    local root = CreateFrame("Frame", nil, nil)
    local padding = NormalizePadding(options.padding, 0)
    local scrollbarInset = tonumber(options.scrollbarInset) or 26
    local contentWidthPadding = tonumber(options.contentWidthPadding) or 20

    local scrollFrame = CreateFrame("ScrollFrame", nil, root, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", root, "TOPLEFT", padding.left, -padding.top)
    scrollFrame:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -(padding.right + scrollbarInset), padding.bottom)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    local watermark

    if options.watermarkAtlas or options.watermarkTexture then
        watermark = root:CreateTexture(nil, "BACKGROUND")
        watermark:SetPoint("CENTER", root, "CENTER", 0, 0)
        watermark:SetSize(tonumber(options.watermarkSize) or 128, tonumber(options.watermarkSize) or 128)
        watermark:SetAlpha(tonumber(options.watermarkAlpha) or 0.25)
        watermark:SetDesaturated(true)

        if options.watermarkAtlas and watermark.SetAtlas then
            watermark:SetAtlas(options.watermarkAtlas)
        else
            watermark:SetTexture(options.watermarkTexture)
        end

        watermark:Hide()
    end

    local statusBar
    local statusText

    if options.showStatusBar then
        statusBar = CreateFrame("Frame", nil, root, "BackdropTemplate")
        SetBackdrop(statusBar, 0.5)
        statusBar:SetPoint("LEFT", root, "LEFT", padding.left, 0)
        statusBar:SetPoint("RIGHT", root, "RIGHT", -padding.right, 0)
        statusBar:SetPoint("BOTTOM", root, "BOTTOM", 0, padding.bottom)
        statusBar:SetHeight(tonumber(options.statusBarHeight) or 22)

        statusText = Core.CreateLabel(statusBar, "", "GameFontDisableSmall")
        statusText:SetPoint("LEFT", statusBar, "LEFT", 8, 0)

        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", root, "TOPLEFT", padding.left, -padding.top)
        scrollFrame:SetPoint("BOTTOMRIGHT", statusBar, "TOPRIGHT", -scrollbarInset, 4)
    end

    local function Refresh()
        local width = math.max(1, (scrollFrame:GetWidth() or 1) - contentWidthPadding)
        content:SetWidth(width)
    end

    root:SetScript("OnSizeChanged", Refresh)
    scrollFrame:HookScript("OnVerticalScroll", Refresh)

    local view = {}

    function view:GetRoot()
        return root
    end

    function view:GetScrollFrame()
        return scrollFrame
    end

    function view:GetContent()
        return content
    end

    function view:GetStatusFrame()
        return statusBar
    end

    function view:SetStatusText(text)
        if statusText then
            statusText:SetText(text or "")
        end
        return self
    end

    function view:SetWatermarkVisible(shown)
        Core.SetShown(watermark, shown)
        return self
    end

    function view:Refresh()
        Refresh()
        return self
    end

    function view:AttachTo(parent)
        root:SetParent(parent)
        root:SetAllPoints(parent)
        Refresh()
        return self
    end

    function view:Show()
        root:Show()
        Refresh()
        return self
    end

    function view:Hide()
        root:Hide()
        return self
    end

    return view
end

function UI:CreateScrollView(options)
    return self.Views.ScrollView:Create(options)
end

function Core.CreateScrollView(options)
    return UI:CreateScrollView(options)
end

UI.Widgets.GridLayout = {}

function UI.Widgets.GridLayout:Create(container, options)
    if not container then
        return nil
    end

    options = options or {}

    local cfg = {
        cols = math.max(1, tonumber(options.cols) or 12),
        rows = math.max(1, tonumber(options.rows) or 12),
        padding = NormalizePadding(options.padding, 4),
        gutter = NormalizeAxis(options.gutter, 8),
        offset = NormalizeAxis(options.offset, 0),
    }
    local placements = {}

    local function Compute()
        local width = container:GetWidth() or 0
        local height = container:GetHeight() or 0
        local availableW = math.max(0, width - cfg.padding.left - cfg.padding.right - ((cfg.cols - 1) * cfg.gutter.x))
        local availableH = math.max(0, height - cfg.padding.top - cfg.padding.bottom - ((cfg.rows - 1) * cfg.gutter.y))
        local trackW = math.max(1, math.floor(availableW / cfg.cols))
        local trackH = math.max(1, math.floor(availableH / cfg.rows))
        local remW = math.max(0, availableW - (trackW * cfg.cols))
        local remH = math.max(0, availableH - (trackH * cfg.rows))

        return trackW, trackH, remW, remH
    end

    local function Apply(placement)
        if not placement or not placement.frame then
            return
        end

        local trackW, trackH, remW, remH = Compute()
        local x = math.max(0, tonumber(placement.x) or 0)
        local y = math.max(0, tonumber(placement.y) or 0)
        local w = math.max(1, tonumber(placement.w) or 1)
        local h = math.max(1, tonumber(placement.h) or 1)
        local left = cfg.padding.left + x * (trackW + cfg.gutter.x) + cfg.offset.x
        local top = cfg.padding.top + y * (trackH + cfg.gutter.y) + cfg.offset.y
        local width = (w * trackW) + ((w - 1) * cfg.gutter.x)
        local height = (h * trackH) + ((h - 1) * cfg.gutter.y)

        if x + w == cfg.cols then
            width = width + remW
        end

        if y + h == cfg.rows then
            height = height + remH
        end

        placement.frame:SetParent(container)
        placement.frame:ClearAllPoints()
        placement.frame:SetPoint("TOPLEFT", container, "TOPLEFT", left, -top)
        placement.frame:SetSize(width, height)
        placement.frame:Show()
    end

    local function Refresh()
        for _, placement in ipairs(placements) do
            Apply(placement)
        end
    end

    container:HookScript("OnSizeChanged", Refresh)

    local layout = {}

    function layout:Add(frame, spec)
        if frame and spec then
            placements[#placements + 1] = {
                frame = frame,
                x = spec.x,
                y = spec.y,
                w = spec.w,
                h = spec.h,
            }
            Refresh()
        end
        return self
    end

    function layout:Remove(frame)
        for index = #placements, 1, -1 do
            if placements[index].frame == frame then
                table.remove(placements, index)
            end
        end

        Refresh()
        return self
    end

    function layout:Clear()
        for index = #placements, 1, -1 do
            placements[index] = nil
        end

        Refresh()
        return self
    end

    function layout:Refresh()
        Refresh()
        return self
    end

    function layout:GetContainer()
        return container
    end

    return layout
end

function UI:CreateGridLayout(container, options)
    return self.Widgets.GridLayout:Create(container, options)
end

function Core.CreateGridLayout(container, options)
    return UI:CreateGridLayout(container, options)
end

UI.Views.GridView = {}

function UI.Views.GridView:Create(options)
    options = options or {}

    local containerView = UI:CreateContainerView({
        padding = options.padding or 0,
        backdrop = options.backdrop,
        alpha = options.alpha,
    })
    local layout = UI:CreateGridLayout(containerView:GetContent(), options.layout or {})
    local view = {}

    function view:GetRoot()
        return containerView:GetRoot()
    end

    function view:GetContent()
        return containerView:GetContent()
    end

    function view:GetLayout()
        return layout
    end

    function view:Add(frame, spec)
        if layout then
            layout:Add(frame, spec)
        end
        return self
    end

    function view:Remove(frame)
        if layout then
            layout:Remove(frame)
        end
        return self
    end

    function view:Clear()
        if layout then
            layout:Clear()
        end
        return self
    end

    function view:Refresh()
        if layout then
            layout:Refresh()
        end
        return self
    end

    function view:Show()
        containerView:Show()
        self:Refresh()
        return self
    end

    function view:Hide()
        containerView:Hide()
        return self
    end

    return view
end

function UI:CreateGridView(options)
    return self.Views.GridView:Create(options)
end

function Core.CreateGridView(options)
    return UI:CreateGridView(options)
end

