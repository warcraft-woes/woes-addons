local Overlay = _G.WoesScrollingOverlay
local Editor = Overlay.Editor
local Core = Overlay.Core
local C = Overlay.Constants
local State = Overlay.State
local DB = Overlay.DB
local Skills = Overlay.Skills
local Ticker = Overlay.Ticker
local Trackers = Overlay.Trackers

local configFrame
local configRows = {}
local ROW_HEIGHT = 34

local function RefreshConfigGUI()
    if configFrame and configFrame.rowList then
        configFrame.rowList:SetData(State.rows)
    end

    if configFrame and configFrame.rowCountLabel then
        local rowCount = #State.rows
        configFrame.rowCountLabel:SetText(rowCount == 1 and "1 Row" or (tostring(rowCount) .. " Rows"))
    end
end

local function GetTypeOptions(rowFrame)
    local selectedType = State.rows[rowFrame.rowIndex] and State.rows[rowFrame.rowIndex].type
    local optionsList = {}

    for _, tickerType in ipairs(C.TICKER_TYPES) do
        optionsList[#optionsList + 1] = {
            value = tickerType.value,
            label = tickerType.label,
            checked = selectedType == tickerType.value,
        }
    end

    return optionsList
end

local function GetTargetOptions(rowFrame)
    local row = State.rows[rowFrame.rowIndex] or {}
    local optionsList = {}

    if row.type == "skillGroup" then
        local targets = {
            { value = "weapon", label = "Weapon Skills" },
            { value = "primary", label = "Primary Professions" },
            { value = "secondary", label = "Secondary Skills" },
        }

        for _, target in ipairs(targets) do
            target.checked = row.target == target.value
            optionsList[#optionsList + 1] = target
        end
    elseif row.type == "skill" then
        local added = {}

        for skillName in pairs(C.SKILL_ICONS) do
            added[skillName] = true
            optionsList[#optionsList + 1] = {
                value = skillName,
                label = skillName,
                checked = row.target == skillName,
            }
        end

        for _, skill in ipairs(Skills.Collect()) do
            if not added[skill.name] then
                optionsList[#optionsList + 1] = {
                    value = skill.name,
                    label = skill.name,
                    checked = row.target == skill.name,
                }
            end
        end

        table.sort(optionsList, function(a, b)
            return a.label < b.label
        end)
    else
        optionsList[1] = {
            value = "",
            label = "None",
            checked = true,
            disabled = true,
        }
    end

    return optionsList
end

local function GetFormatOptions(rowFrame)
    local row = State.rows[rowFrame.rowIndex] or {}
    local optionsList = {}

    for _, format in ipairs(C.FORMAT_ORDER) do
        optionsList[#optionsList + 1] = {
            value = format,
            label = C.FORMAT_LABELS[format],
            checked = (row.format or "full") == format,
        }
    end

    return optionsList
end

local function SaveTickerRowFromGUI(index)
    local rowFrame = configRows[index]
    local row = State.rows[index]

    if not rowFrame or not row then
        return
    end

    if row.type == "customText" then
        row.text = rowFrame.labelEdit:GetText() or ""
        row.label = ""
    else
        row.label = rowFrame.labelEdit:GetText() or ""
    end

    row.showLabel = rowFrame.labelCheck:GetChecked() and true or false
    DB.SaveRows()
    Ticker.ApplyConfiguredItems()
end

local function SetTickerRowType(index, rowType)
    local row = State.rows[index]

    if not row then
        row = DB.CreateTickerRow(rowType)
        State.rows[index] = row
    end

    row.type = rowType

    if rowType == "skillGroup" and row.target == "" then
        row.target = "primary"
    elseif rowType == "skill" and row.target == "" then
        row.target = "Blacksmithing"
    elseif rowType ~= "skill" and rowType ~= "skillGroup" then
        row.target = ""
    end

    DB.SaveRows()
    Ticker.ApplyConfiguredItems()
    RefreshConfigGUI()
end

local function SetTickerRowTarget(index, target)
    if State.rows[index] then
        State.rows[index].target = target or ""
        DB.SaveRows()
        Ticker.ApplyConfiguredItems()
        RefreshConfigGUI()
    end
end

local function SetTickerRowFormat(index, format)
    if State.rows[index] then
        State.rows[index].format = format or "full"
        DB.SaveRows()
        Ticker.ApplyConfiguredItems()
        RefreshConfigGUI()
    end
end

local function AddTickerRow()
    State.rows[#State.rows + 1] = DB.CreateTickerRow("none")
    DB.SaveRows()
    Ticker.ApplyConfiguredItems()
    RefreshConfigGUI()
end

local function RemoveTickerRow(index)
    if not State.rows[index] then
        return
    end

    table.remove(State.rows, index)

    if #State.rows == 0 then
        State.rows[1] = DB.CreateTickerRow("none")
    end

    DB.SaveRows()
    Ticker.ApplyConfiguredItems()
    RefreshConfigGUI()
end

local function MoveTickerRow(index, direction)
    local newIndex = index + direction

    if not State.rows[index] or not State.rows[newIndex] then
        return
    end

    State.rows[index], State.rows[newIndex] = State.rows[newIndex], State.rows[index]
    DB.SaveRows()
    Ticker.ApplyConfiguredItems()
    RefreshConfigGUI()
end

local function BindConfigRow(rowFrame, rowIndex, row)
    rowFrame.rowIndex = rowIndex
    rowFrame.number:SetText(rowIndex .. ".")
    Core.SetDropdownText(rowFrame.typeDropdown, C.TICKER_TYPE_LABELS[row.type] or "None")

    if row.type == "skill" then
        Core.SetDropdownText(rowFrame.targetDropdown, row.target ~= "" and row.target or "Choose Skill")
    elseif row.type == "skillGroup" then
        local labels = { weapon = "Weapon Skills", primary = "Primary Professions", secondary = "Secondary Skills" }
        Core.SetDropdownText(rowFrame.targetDropdown, labels[row.target] or "Choose Group")
    else
        Core.SetDropdownText(rowFrame.targetDropdown, "None")
    end

    if Core.SetDropdownEnabled then
        Core.SetDropdownEnabled(rowFrame.targetDropdown, row.type == "skill" or row.type == "skillGroup")
    end

    Core.SetDropdownText(rowFrame.formatDropdown, C.FORMAT_LABELS[row.format or "full"] or "Full")
    rowFrame.labelEdit:SetText(row.type == "customText" and (row.text or "") or (row.label or ""))
    rowFrame.labelCheck:SetChecked(row.showLabel ~= false)
    Core.SetEnabled(rowFrame.upButton, rowIndex > 1)
    Core.SetEnabled(rowFrame.downButton, rowIndex < #State.rows)
end

local function CreateConfigRow(parent, rowIndex)
    local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame.rowIndex = rowIndex
    rowFrame:SetSize(748, 30)

    local number = Core.CreateLabel(rowFrame, rowIndex .. ".", "GameFontHighlightSmall")
    number:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)

    local upButton = Core.CreateButton(rowFrame, "^", 22, 22, function()
        SaveTickerRowFromGUI(rowFrame.rowIndex)
        MoveTickerRow(rowFrame.rowIndex, -1)
    end)
    upButton:SetPoint("LEFT", rowFrame, "LEFT", 25, 0)

    local downButton = Core.CreateButton(rowFrame, "v", 22, 22, function()
        SaveTickerRowFromGUI(rowFrame.rowIndex)
        MoveTickerRow(rowFrame.rowIndex, 1)
    end)
    downButton:SetPoint("LEFT", rowFrame, "LEFT", 49, 0)

    local typeDropdown = Core.CreateDropdown(rowFrame, Overlay.name .. "TypeDropdown" .. rowIndex, 125, function()
        return GetTypeOptions(rowFrame)
    end, function(value)
        SaveTickerRowFromGUI(rowFrame.rowIndex)
        SetTickerRowType(rowFrame.rowIndex, value)
    end)
    typeDropdown:SetPoint("LEFT", rowFrame, "LEFT", 75, -2)

    local targetDropdown = Core.CreateDropdown(rowFrame, Overlay.name .. "TargetDropdown" .. rowIndex, 130, function()
        return GetTargetOptions(rowFrame)
    end, function(value)
        SetTickerRowTarget(rowFrame.rowIndex, value)
    end)
    targetDropdown:SetPoint("LEFT", rowFrame, "LEFT", 240, -2)

    local formatDropdown = Core.CreateDropdown(rowFrame, Overlay.name .. "FormatDropdown" .. rowIndex, 105, function()
        return GetFormatOptions(rowFrame)
    end, function(value)
        SetTickerRowFormat(rowFrame.rowIndex, value)
    end)
    formatDropdown:SetPoint("LEFT", rowFrame, "LEFT", 405, -2)

    local labelEdit = Core.CreateEditBox(rowFrame, 120, 24, function()
        SaveTickerRowFromGUI(rowFrame.rowIndex)
    end)
    labelEdit:SetPoint("LEFT", rowFrame, "LEFT", 555, 0)

    local labelCheck = Core.CreateCheckButton(rowFrame, function()
        SaveTickerRowFromGUI(rowFrame.rowIndex)
    end)
    labelCheck:SetPoint("LEFT", rowFrame, "LEFT", 690, 0)

    local removeButton = Core.CreateButton(rowFrame, "x", 24, 22, function()
        RemoveTickerRow(rowFrame.rowIndex)
    end)
    removeButton:SetPoint("LEFT", rowFrame, "LEFT", 735, 0)

    rowFrame.number = number
    rowFrame.upButton = upButton
    rowFrame.downButton = downButton
    rowFrame.typeDropdown = typeDropdown
    rowFrame.targetDropdown = targetDropdown
    rowFrame.formatDropdown = formatDropdown
    rowFrame.labelEdit = labelEdit
    rowFrame.labelCheck = labelCheck
    rowFrame.removeButton = removeButton

    return rowFrame
end

function Editor.CreateFrame()
    if configFrame then
        return configFrame
    end

    local UI = Core.UI
    configFrame = Core.CreateMainWindow and Core.CreateMainWindow(Overlay.name .. "ConfigFrame", Overlay.displayName, nil, {
        width = 820,
        height = 360,
    }) or Core.CreateWindow(Overlay.name .. "ConfigFrame", Overlay.displayName, 820, 360)

    local view = UI and UI.CreateContainerView and UI:CreateContainerView({
        backdrop = false,
        padding = 0,
    })
    local host = configFrame.ViewHost or configFrame

    if view and configFrame.SetView then
        configFrame:SetView(view)
        host = view:GetContent()
    end

    local headers = {
        { text = "Move", x = 40 },
        { text = "Source", x = 95 },
        { text = "Target", x = 260 },
        { text = "Format", x = 425 },
        { text = "Label Override", x = 555 },
        { text = "Show Label", x = 675 },
        { text = "Remove", x = 735 },
    }

    for _, header in ipairs(headers) do
        local label = Core.CreateLabel(host, header.text, "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", host, "TOPLEFT", header.x, -2)
        label:SetText(header.text)
    end

    local scrollView = Core.CreateScrollView and Core.CreateScrollView({
        scrollbarInset = 24,
        contentWidthPadding = 8,
    })
    local scrollRoot = scrollView and scrollView:GetRoot()
    local rowContainer = scrollView and scrollView:GetContent()

    if scrollRoot then
        scrollRoot:SetParent(host)
        scrollRoot:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -26)
        scrollRoot:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -4, 0)
    end

    configFrame.scrollView = scrollView
    configFrame.rowContainer = rowContainer

    configFrame.rowList = Core.CreateSimpleList and Core.CreateSimpleList(rowContainer, {
        rowHeight = ROW_HEIGHT,
        rowGap = 0,
        createRow = function(parent, rowIndex)
            local rowFrame = CreateConfigRow(parent, rowIndex)
            configRows[rowIndex] = rowFrame
            return rowFrame
        end,
        bindRow = BindConfigRow,
    })

    local addButtonParent = configFrame.Footer or configFrame
    local addButton = Core.CreateButton(addButtonParent, "Add Row", 96, 24, AddTickerRow)
    addButton:SetPoint("LEFT", addButtonParent, "LEFT", 0, 0)

    local resetHealthButton = Core.CreateButton(addButtonParent, "Reset Lowest HP", 140, 24, function()
        Trackers.ResetLowestHealth()
        Overlay.Print("Lowest HP tracker reset.")
    end)
    resetHealthButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)

    local settingsButton = Core.CreateButton(addButtonParent, "Settings", 96, 24, function()
        if not Overlay.Settings.Open() then
            Overlay.Print("Settings are available from Game Menu > Options > AddOns.")
        end
    end)
    settingsButton:SetPoint("LEFT", resetHealthButton, "RIGHT", 8, 0)

    local toggleButton
    local function RefreshToggleButton()
        if toggleButton then
            toggleButton:SetText(Ticker.IsRunning() and "Stop Overlay" or "Start Overlay")
        end
    end

    toggleButton = Core.CreateButton(addButtonParent, "", 116, 24, function()
        if Ticker.IsRunning() then
            Ticker.Stop()
            Overlay.Print("Stopped.")
        else
            Ticker.Start()
            Overlay.Print("Started.")
        end

        RefreshToggleButton()
    end)
    toggleButton:SetPoint("LEFT", settingsButton, "RIGHT", 8, 0)
    configFrame.RefreshOverlayToggleButton = RefreshToggleButton
    RefreshToggleButton()

    local rowCountLabel = Core.CreateLabel(addButtonParent, "", "GameFontDisableSmall")
    rowCountLabel:SetPoint("RIGHT", addButtonParent, "RIGHT", -6, 0)
    rowCountLabel:SetJustifyH("RIGHT")
    rowCountLabel:SetWidth(140)
    configFrame.rowCountLabel = rowCountLabel
    RefreshConfigGUI()

    return configFrame
end

function Editor.Toggle()
    local frame = Editor.CreateFrame()
    RefreshConfigGUI()

    if frame.RefreshOverlayToggleButton then
        frame:RefreshOverlayToggleButton()
    end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()

        if frame.scrollView and frame.scrollView.Refresh then
            frame.scrollView:Refresh()
        end
    end
end

Overlay.ToggleConfig = function()
    return Editor.Toggle()
end
