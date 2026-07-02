local Overlay = _G.WoesScrollingOverlay
local Ticker = Overlay.Ticker
local State = Overlay.State
local C = Overlay.Constants
local Theme = Overlay.Theme
local DB = Overlay.DB
local Providers = Overlay.Providers

local ticker = CreateFrame("Frame", Overlay.name .. "Ticker", UIParent)
ticker:SetFrameStrata("LOW")
ticker:Hide()

local backdrop = ticker:CreateTexture(nil, "BACKGROUND")
backdrop:SetAllPoints(ticker)
backdrop:SetColorTexture(0, 0, 0, 0.62)

local topLine = ticker:CreateTexture(nil, "BORDER")
topLine:SetPoint("TOPLEFT", ticker, "TOPLEFT", 0, 0)
topLine:SetPoint("TOPRIGHT", ticker, "TOPRIGHT", 0, 0)
topLine:SetHeight(1)
topLine:SetColorTexture(1, 0.82, 0.18, 0.85)

local bottomLine = ticker:CreateTexture(nil, "BORDER")
bottomLine:SetPoint("BOTTOMLEFT", ticker, "BOTTOMLEFT", 0, 0)
bottomLine:SetPoint("BOTTOMRIGHT", ticker, "BOTTOMRIGHT", 0, 0)
bottomLine:SetHeight(1)
bottomLine:SetColorTexture(1, 0.82, 0.18, 0.85)

local items = {}
local oneShotItems = {}
local active = {}
local pool = {}
local nextIndex = 1
local nextSpawnAt = 0
local running = false

function Ticker.IsRunning()
    return running
end

function Ticker.ApplyTheme()
    local background, border = Theme.GetColors()

    backdrop:SetColorTexture(background[1], background[2], background[3], background[4])
    topLine:SetColorTexture(border[1], border[2], border[3], border[4])
    bottomLine:SetColorTexture(border[1], border[2], border[3], border[4])
end

function Ticker.ApplyBorderWidth()
    local width = math.max(0, math.min(10, tonumber(State.options.borderWidth) or 0))

    topLine:SetHeight(math.max(1, width))
    bottomLine:SetHeight(math.max(1, width))

    if width > 0 then
        topLine:Show()
        bottomLine:Show()
    else
        topLine:Hide()
        bottomLine:Hide()
    end
end

local function NormalizeItem(item)
    if type(item) == "string" then
        return { text = item }
    end

    if type(item) == "table" and (type(item.text) == "string" or type(item.text) == "function") then
        return {
            key = item.key,
            text = item.text,
            texture = item.texture or item.icon,
            link = item.link,
            tooltipLink = item.tooltipLink,
        }
    end
end

local function GetItemText(item)
    if type(item.text) == "function" then
        local ok, text = pcall(item.text)

        if ok and text ~= nil and text ~= "" then
            return tostring(text)
        end

        return nil
    end

    return item.text or ""
end

local function MeasureItem(frame)
    local width = frame.text:GetStringWidth() + 28

    if frame.icon:IsShown() then
        width = width + frame.iconSize + 10
    end

    return math.max(width, 40)
end

local function ApplyMessageStyle(frame)
    local _, _, textColor = Theme.GetColors()

    frame:SetHeight(State.options.height)
    frame.iconSize = math.min(C.ICON_SIZE, math.max(1, State.options.height - 14))
    frame.icon:SetSize(frame.iconSize, frame.iconSize)
    frame.text:SetFont(STANDARD_TEXT_FONT, State.options.textSize, State.options.pixelSnap and "" or "OUTLINE")
    frame.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
end

local function CreateMessageFrame()
    local frame = CreateFrame("Frame", nil, ticker)
    frame:SetSize(40, State.options.height)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("LEFT", frame, "LEFT", 14, 0)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("LEFT", frame, "LEFT", 14, 0)
    frame.text:SetJustifyH("LEFT")
    frame.text:SetJustifyV("MIDDLE")

    ApplyMessageStyle(frame)
    return frame
end

local function AcquireMessageFrame()
    local frame = table.remove(pool) or CreateMessageFrame()
    frame:SetParent(ticker)
    frame:Show()
    ApplyMessageStyle(frame)
    return frame
end

local function ReleaseMessageFrame(frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame.icon:Hide()
    frame.text:SetText("")
    frame.sourceItem = nil
    table.insert(pool, frame)
end

local function GetTickerWidth()
    return ticker:GetWidth() > 0 and ticker:GetWidth() or UIParent:GetWidth()
end

local function ClearActiveItems()
    for index = #active, 1, -1 do
        ReleaseMessageFrame(active[index])
        active[index] = nil
    end
end

local function SpawnNextItem(startVisible)
    if #oneShotItems == 0 and #items == 0 then
        return
    end

    local item
    local text
    local attempts = #oneShotItems + #items

    while attempts > 0 and not text do
        item = table.remove(oneShotItems, 1)

        if not item and #items > 0 then
            item = items[nextIndex]
            nextIndex = nextIndex + 1

            if nextIndex > #items then
                nextIndex = 1
            end
        end

        if item then
            text = GetItemText(item)
        end

        attempts = attempts - 1
    end

    if not item or not text then
        return
    end

    local frame = AcquireMessageFrame()
    frame.sourceItem = item
    frame.text:SetText(text)

    if item.texture then
        frame.icon:SetTexture(item.texture)
        frame.icon:Show()
        frame.text:ClearAllPoints()
        frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
    else
        frame.icon:Hide()
        frame.text:ClearAllPoints()
        frame.text:SetPoint("LEFT", frame, "LEFT", 14, 0)
    end

    frame.itemWidth = MeasureItem(frame)
    frame:SetSize(frame.itemWidth, State.options.height)

    frame.x = GetTickerWidth() + C.SPAWN_PADDING

    frame:SetPoint("LEFT", ticker, "LEFT", frame.x, 0)
    table.insert(active, frame)
    nextSpawnAt = frame.x + frame.itemWidth + State.options.gap
end

local function ResetVisibleTicker()
    if not running then
        return
    end

    ClearActiveItems()
    nextIndex = 1
    nextSpawnAt = 0
end

function Ticker.ApplyLayout()
    ticker:SetHeight(State.options.height)
    ticker:ClearAllPoints()
    ticker:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, State.options.y)
    ticker:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, State.options.y)
    ResetVisibleTicker()
end

function Ticker.ApplyPosition()
    ticker:ClearAllPoints()
    ticker:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, State.options.y)
    ticker:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, State.options.y)
end

function Ticker.RestyleVisibleItems()
    for index = #active, 1, -1 do
        local frame = active[index]
        ApplyMessageStyle(frame)

        if frame.sourceItem then
            local text = GetItemText(frame.sourceItem)

            if not text then
                ReleaseMessageFrame(frame)
                table.remove(active, index)
            else
                frame.text:SetText(text)
                frame.itemWidth = MeasureItem(frame)
                frame:SetSize(frame.itemWidth, State.options.height)
            end
        else
            frame.itemWidth = MeasureItem(frame)
            frame:SetSize(frame.itemWidth, State.options.height)
        end
    end
end

local function ApplyOptionsLive(changedOptions)
    if changedOptions.theme ~= nil
        or changedOptions.customBackgroundR ~= nil
        or changedOptions.customBackgroundG ~= nil
        or changedOptions.customBackgroundB ~= nil
        or changedOptions.customBackgroundA ~= nil
        or changedOptions.customBorderR ~= nil
        or changedOptions.customBorderG ~= nil
        or changedOptions.customBorderB ~= nil
        or changedOptions.customBorderA ~= nil
        or changedOptions.customTextR ~= nil
        or changedOptions.customTextG ~= nil
        or changedOptions.customTextB ~= nil
        or changedOptions.customTextA ~= nil then
        Ticker.ApplyTheme()
        Ticker.RestyleVisibleItems()
    end

    if changedOptions.height ~= nil then
        ticker:SetHeight(State.options.height)
        Ticker.RestyleVisibleItems()
    elseif changedOptions.textSize ~= nil then
        Ticker.RestyleVisibleItems()
    end

    if changedOptions.borderWidth ~= nil then
        Ticker.ApplyBorderWidth()
    end

    if changedOptions.y ~= nil then
        Ticker.ApplyPosition()
    end
end

local function OnUpdate(_, elapsed)
    local travel = State.options.speed * elapsed

    for index = #active, 1, -1 do
        local frame = active[index]
        frame.x = frame.x - travel
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", ticker, "LEFT", frame.x, 0)

        if frame.x + frame.itemWidth < 0 then
            ReleaseMessageFrame(frame)
            table.remove(active, index)
        end
    end

    nextSpawnAt = nextSpawnAt - travel

    if nextSpawnAt <= GetTickerWidth() then
        SpawnNextItem()
    end
end

function Ticker.SetItems(newItems, keepVisibleItems)
    local normalizedItems = {}

    if not keepVisibleItems then
        nextSpawnAt = 0
        ClearActiveItems()
    elseif #active == 0 then
        nextSpawnAt = 0
    end

    if type(newItems) ~= "table" then
        items = {}
        nextIndex = 1
        return
    end

    for _, item in ipairs(newItems) do
        local normalized = NormalizeItem(item)

        if normalized then
            normalizedItems[#normalizedItems + 1] = normalized
        end
    end

    items = normalizedItems

    if nextIndex > #items then
        nextIndex = 1
    end
end

function Ticker.AddOneShotItem(item)
    local normalized = NormalizeItem(item)

    if normalized then
        oneShotItems[#oneShotItems + 1] = normalized
    end
end

local function BuildItemFromRow(row, index)
    local provider = Providers[row.type or "none"]

    if not provider or not provider.render then
        return nil
    end

    return {
        key = tostring(row.id or index) .. ":" .. tostring(row.type),
        text = function()
            return provider.render(row)
        end,
    }
end

function Ticker.BuildConfiguredItems()
    local configuredItems = {}

    for index, row in ipairs(State.rows) do
        local item = BuildItemFromRow(row, index)

        if item then
            configuredItems[#configuredItems + 1] = item
        end
    end

    return configuredItems
end

function Ticker.ApplyConfiguredItems()
    Ticker.SetItems(Ticker.BuildConfiguredItems(), running)
end

function Ticker.Start()
    if running then
        return
    end

    running = true
    nextSpawnAt = GetTickerWidth()
    ticker:Show()
    ticker:SetScript("OnUpdate", OnUpdate)
end

function Ticker.Stop()
    running = false
    ticker:SetScript("OnUpdate", nil)
    ticker:Hide()
    ClearActiveItems()
end

function Ticker.SetOptions(newOptions)
    if type(newOptions) ~= "table" then
        return
    end

    local changedOptions = {}

    for key in pairs(C.DEFAULT_OPTIONS) do
        if newOptions[key] ~= nil and State.options[key] ~= newOptions[key] then
            local value = newOptions[key]

            if key == "y" then
                value = math.max(0, math.min(tonumber(value) or 0, math.max(0, (UIParent:GetHeight() or 800) - (State.options.height or C.DEFAULT_OPTIONS.height))))
            elseif key == "borderWidth" then
                value = math.max(0, math.min(10, tonumber(value) or 0))
            elseif string.find(key, "^custom") then
                value = math.max(0, math.min(1, tonumber(value) or 0))
            end

            State.options[key] = value
            changedOptions[key] = value
        end
    end

    if changedOptions.height ~= nil then
        local maxY = math.max(0, (UIParent:GetHeight() or 800) - (State.options.height or C.DEFAULT_OPTIONS.height))

        if (State.options.y or 0) > maxY then
            State.options.y = maxY
            changedOptions.y = maxY
        end
    end

    DB.SaveOptions()
    ApplyOptionsLive(changedOptions)
end

Overlay.SetItems = function(_, ...)
    return Ticker.SetItems(...)
end

Overlay.AddOneShotItem = function(_, ...)
    return Ticker.AddOneShotItem(...)
end

Overlay.ApplyConfiguredItems = function()
    return Ticker.ApplyConfiguredItems()
end

Overlay.Start = function()
    return Ticker.Start()
end

Overlay.Stop = function()
    return Ticker.Stop()
end

Overlay.SetOptions = function(_, ...)
    return Ticker.SetOptions(...)
end
