local Core = _G.WoesAddonsCore
local UI = Core.UI

UI.Widgets.PageTitle = {}

function UI.Widgets.PageTitle:Create(parent, text)
    if not parent then
        return nil
    end

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(28)
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    holder:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    holder.Text = Core.CreateLabel(holder, text or "", "GameFontHighlightLarge")
    holder.Text:SetPoint("LEFT", holder, "LEFT", 0, 0)

    return holder
end

function UI:CreatePageTitle(parent, text)
    return self.Widgets.PageTitle:Create(parent, text)
end

function Core.CreatePageTitle(parent, text)
    return UI:CreatePageTitle(parent, text)
end

UI.Views.TabbedView = {}

function UI.Views.TabbedView:Create(options)
    options = options or {}

    local root = CreateFrame("Frame", nil, nil)
    local tabsHost = CreateFrame("Frame", nil, root)
    tabsHost:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    tabsHost:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    tabsHost:SetHeight(32)

    local pageHost = CreateFrame("Frame", nil, root)
    pageHost:SetPoint("TOPLEFT", tabsHost, "BOTTOMLEFT", 0, -8)
    pageHost:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)

    local pages = {}
    local tabs = {}
    local order = {}
    local activeKey
    local view = {}

    local function Select(key)
        local page = pages[key]

        if not page or page.disabled then
            return
        end

        for _, existingPage in pairs(pages) do
            existingPage.root:Hide()
        end

        for _, tab in pairs(tabs) do
            tab:UnlockHighlight()
        end

        page.root:Show()

        if tabs[key] then
            tabs[key]:LockHighlight()
        end

        activeKey = key
    end

    function view:GetRoot()
        return root
    end

    function view:GetContent()
        return activeKey and pages[activeKey] and pages[activeKey].content or nil
    end

    function view:GetPageContent(key)
        return key and pages[key] and pages[key].content or nil
    end

    function view:AddPage(config)
        if not config or not config.key or pages[config.key] then
            return false
        end

        local page = CreateFrame("Frame", nil, pageHost)
        page:SetAllPoints(pageHost)
        page:Hide()

        local title

        if config.title then
            title = UI:CreatePageTitle(page, config.title)
        end

        local content = CreateFrame("Frame", nil, page)

        if title then
            content:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
            content:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
        else
            content:SetAllPoints(page)
        end

        pages[config.key] = {
            root = page,
            content = content,
            disabled = config.disabled,
        }
        order[#order + 1] = config.key

        local tab = Core.CreateButton(tabsHost, config.label or config.title or config.key, tonumber(options.tabWidth) or 96, 24, function()
            Select(config.key)
        end)

        if #order == 1 then
            tab:SetPoint("TOPLEFT", tabsHost, "TOPLEFT", 0, 0)
        else
            tab:SetPoint("LEFT", tabs[order[#order - 1]], "RIGHT", 4, 0)
        end

        Core.SetEnabled(tab, not config.disabled)
        tabs[config.key] = tab

        if config.build then
            config.build(content, page)
        end

        if not activeKey and not config.disabled then
            Select(config.key)
        end

        return true
    end

    function view:Select(key)
        Select(key)
        return self
    end

    function view:Refresh()
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

function UI:CreateTabbedView(options)
    return self.Views.TabbedView:Create(options)
end

function Core.CreateTabbedView(options)
    return UI:CreateTabbedView(options)
end

UI.Widgets.SimpleList = {}

function UI.Widgets.SimpleList:Create(parent, options)
    options = options or {}

    local rowHeight = tonumber(options.rowHeight) or 28
    local rowGap = tonumber(options.rowGap) or 2
    local createRow = options.createRow
    local bindRow = options.bindRow
    local rows = {}
    local data = {}
    local list = {}

    local function EnsureRow(index)
        if rows[index] then
            return rows[index]
        end

        local row = createRow and createRow(parent, index) or CreateFrame("Frame", nil, parent)
        row:SetHeight(rowHeight)

        if index == 1 then
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
            row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
        else
            row:SetPoint("TOPLEFT", rows[index - 1], "BOTTOMLEFT", 0, -rowGap)
            row:SetPoint("TOPRIGHT", rows[index - 1], "BOTTOMRIGHT", 0, -rowGap)
        end

        rows[index] = row
        return row
    end

    local function Refresh()
        for index, item in ipairs(data) do
            local row = EnsureRow(index)

            if bindRow then
                bindRow(row, index, item)
            end

            row:Show()
        end

        for index = #data + 1, #rows do
            rows[index]:Hide()
        end

        if parent.SetHeight then
            parent:SetHeight(math.max(1, (#data * rowHeight) + (math.max(0, #data - 1) * rowGap)))
        end
    end

    function list:SetData(newData)
        data = type(newData) == "table" and newData or {}
        Refresh()
        return self
    end

    function list:Refresh()
        Refresh()
        return self
    end

    function list:Clear()
        data = {}
        Refresh()
        return self
    end

    return list
end

function UI:CreateSimpleList(parent, options)
    return self.Widgets.SimpleList:Create(parent, options)
end

function Core.CreateSimpleList(parent, options)
    return UI:CreateSimpleList(parent, options)
end

UI.Widgets.VirtualList = {}

function UI.Widgets.VirtualList:Create(scrollView, options)
    if not scrollView or not scrollView.GetContent or not scrollView.GetScrollFrame then
        return nil
    end

    options = options or {}

    local createItem = options.createItem
    local bindItem = options.bindItem
    local rowHeight = tonumber(options.rowHeight) or 28
    local rowGap = tonumber(options.rowGap) or 2
    local overscan = tonumber(options.overscan) or 2
    local content = scrollView:GetContent()
    local scrollFrame = scrollView:GetScrollFrame()
    local data = {}
    local pool = {}
    local firstRenderedIndex = 1
    local list = {}

    local function CreatePoolItem(index)
        local frame = createItem and createItem(content, index) or CreateFrame("Frame", nil, content)
        frame:SetHeight(rowHeight)
        frame:Hide()
        pool[index] = frame
        return frame
    end

    local function GetPoolItem(index)
        return pool[index] or CreatePoolItem(index)
    end

    local function GetVisibleCount()
        local height = scrollFrame:GetHeight() or 1
        return math.max(1, math.ceil(height / math.max(1, rowHeight + rowGap)) + overscan)
    end

    local function Refresh()
        local stride = rowHeight + rowGap
        local scrollOffset = scrollFrame:GetVerticalScroll() or 0
        local firstIndex = math.max(1, math.floor(scrollOffset / math.max(1, stride)) + 1)
        local visibleCount = GetVisibleCount()

        firstRenderedIndex = firstIndex
        content:SetHeight(math.max(1, (#data * rowHeight) + (math.max(0, #data - 1) * rowGap)))

        for poolIndex = 1, visibleCount do
            local dataIndex = firstIndex + poolIndex - 1
            local frame = GetPoolItem(poolIndex)

            if data[dataIndex] then
                frame:SetParent(content)
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((dataIndex - 1) * stride))
                frame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((dataIndex - 1) * stride))
                frame:SetHeight(rowHeight)

                if bindItem then
                    bindItem(frame, dataIndex, data[dataIndex])
                end

                frame:Show()
            else
                frame:Hide()
            end
        end

        for poolIndex = visibleCount + 1, #pool do
            pool[poolIndex]:Hide()
        end
    end

    scrollFrame:HookScript("OnVerticalScroll", Refresh)
    scrollFrame:HookScript("OnSizeChanged", Refresh)

    function list:SetData(newData)
        data = type(newData) == "table" and newData or {}
        Refresh()
        return self
    end

    function list:Refresh()
        Refresh()
        return self
    end

    function list:ScrollToIndex(index)
        index = tonumber(index)

        if index then
            scrollFrame:SetVerticalScroll(math.max(0, (index - 1) * (rowHeight + rowGap)))
            Refresh()
        end

        return self
    end

    function list:GetFirstRenderedIndex()
        return firstRenderedIndex
    end

    function list:Clear()
        data = {}
        Refresh()
        return self
    end

    return list
end

function UI:CreateVirtualList(scrollView, options)
    return self.Widgets.VirtualList:Create(scrollView, options)
end

function Core.CreateVirtualList(scrollView, options)
    return UI:CreateVirtualList(scrollView, options)
end

