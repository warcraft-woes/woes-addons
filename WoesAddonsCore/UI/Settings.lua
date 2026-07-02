local Core = _G.WoesAddonsCore
local UI = Core.UI
local Internal = Core.Internal
local NormalizePadding = Internal.NormalizePadding
local ShallowCopy = Internal.ShallowCopy
local UniqueFrameName = Internal.UniqueFrameName
local SetBackdrop = Internal.SetBackdrop

local SettingsUI = UI.Settings

local function ResolveSettingValue(config)
    if config and type(config.get) == "function" then
        return config.get()
    end

    if config and type(config.settings) == "table" and config.key ~= nil then
        return config.settings[config.key]
    end

    return nil
end

local function UpdateSettingValue(config, value)
    if not config then
        return
    end

    if type(config.set) == "function" then
        config.set(value, config.key)
    elseif type(config.settings) == "table" and config.key ~= nil then
        config.settings[config.key] = value
    end

    if type(config.onChanged) == "function" then
        config.onChanged(value, config.key)
    end
end

local function IsSettingEnabled(config)
    if config and type(config.enabled) == "function" then
        return config.enabled()
    end

    if config and config.enabled == false then
        return false
    end

    return true
end

local function SetControlAlpha(control, enabled)
    local alpha = enabled and 1 or 0.45

    if control.SetAlpha then
        control:SetAlpha(alpha)
    end

    if control.Text then
        control.Text:SetAlpha(alpha)
    end

    if control.Label then
        control.Label:SetAlpha(alpha)
    end

    if control.Low then
        control.Low:SetAlpha(alpha)
    end

    if control.High then
        control.High:SetAlpha(alpha)
    end
end

function SettingsUI:CreateCanvas(parent, options)
    options = options or {}

    local canvas = CreateFrame("Frame", nil, parent)
    canvas:SetPoint("TOPLEFT", parent, "TOPLEFT", options.left or 16, options.top or -16)
    canvas:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(options.right or 16), options.bottom or 16)

    canvas.controls = {}
    canvas.blocks = {}

    canvas.Title = Core.CreateLabel(canvas, options.title or "", "GameFontNormalLarge")
    canvas.Title:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, 0)

    canvas.Description = Core.CreateLabel(canvas, options.description or "", "GameFontHighlightSmall")
    canvas.Description:SetPoint("TOPLEFT", canvas.Title, "BOTTOMLEFT", 0, -8)
    canvas.Description:SetJustifyH("LEFT")

    canvas.ActionBar = CreateFrame("Frame", nil, canvas)
    canvas.ActionBar:SetPoint("TOPLEFT", canvas.Description, "BOTTOMLEFT", 0, -16)
    canvas.ActionBar:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", 0, 0)
    canvas.ActionBar:SetHeight(options.actionBarHeight or 26)
    canvas.ActionBar.nextX = 0

    canvas.ScrollFrame = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
    canvas.ScrollFrame:SetPoint("TOPLEFT", canvas.ActionBar, "BOTTOMLEFT", 0, -14)
    canvas.ScrollFrame:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -26, 0)

    canvas.Content = CreateFrame("Frame", nil, canvas.ScrollFrame)
    canvas.Content:SetSize(1, 1)
    canvas.ScrollFrame:SetScrollChild(canvas.Content)
    canvas.nextY = 0

    local function RefreshContentWidth()
        local width = math.max(1, canvas.ScrollFrame:GetWidth() or 1)
        canvas.Content:SetWidth(width)

        for _, block in ipairs(canvas.blocks) do
            block:SetWidth(width)

            if block.Layout and block.Layout.Refresh then
                block.Layout:Refresh()
            end
        end

        canvas.Description:SetWidth(math.max(200, (canvas:GetWidth() or 300) - 24))
    end

    function canvas:AddActionButton(text, width, onClick, buttonOptions)
        local button = Core.CreateButton(self.ActionBar, text, width or 110, 24, onClick, buttonOptions)
        button:SetPoint("LEFT", self.ActionBar, "LEFT", self.ActionBar.nextX or 0, 0)
        self.ActionBar.nextX = (self.ActionBar.nextX or 0) + (width or 110) + 8
        return button
    end

    function canvas:AddBlock(height)
        local block = CreateFrame("Frame", nil, self.Content)
        block:SetPoint("TOPLEFT", self.Content, "TOPLEFT", 0, -self.nextY)
        block:SetWidth(math.max(1, self.ScrollFrame:GetWidth() or 1))
        block:SetHeight(height or 120)
        self.nextY = self.nextY + (height or 120)
        self.Content:SetHeight(math.max(1, self.nextY))
        self.blocks[#self.blocks + 1] = block
        return block
    end

    function canvas:AddDivider(label, height)
        local divider = SettingsUI:CreateDivider(self.Content, label)
        local dividerHeight = height or 64
        divider:SetPoint("TOPLEFT", self.Content, "TOPLEFT", 0, -self.nextY)
        divider:SetPoint("TOPRIGHT", self.Content, "TOPRIGHT", 0, -self.nextY)
        divider:SetHeight(dividerHeight)
        self.nextY = self.nextY + dividerHeight
        self.Content:SetHeight(math.max(1, self.nextY))
        return divider
    end

    function canvas:AddGrid(rows, height, options)
        local block = self:AddBlock(height)
        local layoutOptions = ShallowCopy(options or {})
        layoutOptions.rows = rows or layoutOptions.rows or 4
        block.Layout = UI:CreateGridLayout(block, layoutOptions)
        return block, block.Layout
    end

    function canvas:RegisterControl(control)
        if control then
            self.controls[#self.controls + 1] = control
        end
        return control
    end

    function canvas:Refresh()
        RefreshContentWidth()

        for _, control in ipairs(self.controls or {}) do
            if control.Refresh then
                control:Refresh()
            end
        end
    end

    canvas:SetScript("OnSizeChanged", RefreshContentWidth)
    canvas.ScrollFrame:HookScript("OnVerticalScroll", RefreshContentWidth)

    return canvas
end

function Core.CreateSettingsCanvas(parent, options)
    return SettingsUI:CreateCanvas(parent, options)
end

SettingsUI.rootName = SettingsUI.rootName or "Woes AddOns"

local function GetSettingsCategoryID(category)
    if not category then
        return nil
    end

    if category.ID then
        return category.ID
    end

    if type(category.GetID) == "function" then
        return category:GetID()
    end

    return nil
end

function SettingsUI:CreateRootPanel()
    local panel = CreateFrame("Frame", "WoesAddonsSettingsRootPanel")
    panel.name = self.rootName

    local title = Core.CreateLabel(panel, "Woes AddOns", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)

    local description = Core.CreateLabel(panel, "Shared settings for Woes addons live in the pages below.", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetWidth(520)
    description:SetJustifyH("LEFT")

    return panel
end

function SettingsUI:EnsureRootCategory()
    if self.rootCategory or self.rootPanel then
        return self.rootCategory or self.rootPanel
    end

    if Settings and type(Settings.RegisterVerticalLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
        self.rootCategory = Settings.RegisterVerticalLayoutCategory(self.rootName)
        Settings.RegisterAddOnCategory(self.rootCategory)
        return self.rootCategory
    end

    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
        self.rootPanel = self:CreateRootPanel()
        self.rootCategory = Settings.RegisterCanvasLayoutCategory(self.rootPanel, self.rootName)
        Settings.RegisterAddOnCategory(self.rootCategory)
        return self.rootCategory
    end

    if type(InterfaceOptions_AddCategory) == "function" then
        self.rootPanel = self:CreateRootPanel()
        InterfaceOptions_AddCategory(self.rootPanel)
        return self.rootPanel
    end

    return nil
end

function SettingsUI:RegisterPanel(panel, name)
    if not panel then
        return nil
    end

    panel.name = name or panel.name or "Settings"

    local root = self:EnsureRootCategory()

    if Settings and root and type(Settings.RegisterCanvasLayoutSubcategory) == "function" then
        local category = Settings.RegisterCanvasLayoutSubcategory(root, panel, panel.name)
        panel.WoesSettingsCategory = category
        return category
    end

    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        panel.WoesSettingsCategory = category
        return category
    end

    if type(InterfaceOptions_AddCategory) == "function" then
        panel.parent = self.rootName
        InterfaceOptions_AddCategory(panel)
        return panel
    end

    return nil
end

function Core.RegisterSettingsPanel(panel, name)
    return SettingsUI:RegisterPanel(panel, name)
end

function SettingsUI:OpenPanel(target)
    local panelTarget = target
    local categoryTarget = target and target.WoesSettingsCategory or target

    if Settings and categoryTarget and type(Settings.OpenToCategory) == "function" then
        local categoryID = GetSettingsCategoryID(categoryTarget)

        if categoryID then
            Settings.OpenToCategory(categoryID)
            return true
        end
    end

    if type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(panelTarget)
        InterfaceOptionsFrame_OpenToCategory(panelTarget)
        return true
    end

    return false
end

function Core.OpenSettingsPanel(target)
    return SettingsUI:OpenPanel(target)
end

function SettingsUI:CreateSection(parent, title, description)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section.SettingsPadding = NormalizePadding({ left = 12, right = 12, top = 10, bottom = 10 }, 12)

    SetBackdrop(section, 0.22)

    if section.SetBackdropBorderColor then
        section:SetBackdropBorderColor(0.8, 0.68, 0.34, 0.35)
    end

    section.Title = Core.CreateLabel(section, title or "", "GameFontNormalSmall")
    section.Title:SetPoint("TOPLEFT", section, "TOPLEFT", section.SettingsPadding.left, -section.SettingsPadding.top)

    section.Description = Core.CreateLabel(section, description or "", "GameFontDisableSmall")
    section.Description:SetPoint("TOPLEFT", section.Title, "BOTTOMLEFT", 0, -3)
    section.Description:SetJustifyH("LEFT")

    section:SetScript("OnSizeChanged", function(self, width)
        self.Description:SetWidth(math.max(160, width - self.SettingsPadding.left - self.SettingsPadding.right))
    end)

    return section
end

function Core.CreateSettingsSection(parent, title, description)
    return SettingsUI:CreateSection(parent, title, description)
end

function SettingsUI:CreateDivider(parent, label)
    local divider = CreateFrame("Frame", nil, parent)

    local line = divider:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", divider, "BOTTOMLEFT", 0, 8)
    line:SetPoint("BOTTOMRIGHT", divider, "BOTTOMRIGHT", 0, 8)
    line:SetHeight(1)
    line:SetColorTexture(0.8, 0.68, 0.34, 0.45)
    divider.Line = line

    if label and label ~= "" then
        divider.Label = Core.CreateLabel(divider, label, "GameFontNormal")
        divider.Label:SetPoint("BOTTOMLEFT", line, "TOPLEFT", 0, 10)
    end

    return divider
end

function Core.CreateSettingsDivider(parent, label)
    return SettingsUI:CreateDivider(parent, label)
end

function SettingsUI:CreateText(parent, config)
    config = config or {}

    local fontObject = config.fontObject

    if not fontObject then
        if config.kind == "title" then
            fontObject = "GameFontNormalLarge"
        elseif config.kind == "subtitle" then
            fontObject = "GameFontNormal"
        elseif config.kind == "description" then
            fontObject = "GameFontDisableSmall"
        else
            fontObject = "GameFontHighlight"
        end
    end

    local text = Core.CreateLabel(parent, config.text or "", fontObject)
    text:SetPoint(config.point or "TOPLEFT", parent, config.relativePoint or "TOPLEFT", config.x or 0, config.y or 0)
    text:SetJustifyH(config.justifyH or "LEFT")

    if config.width then
        text:SetWidth(config.width)
    end

    return text
end

function Core.CreateSettingsText(parent, config)
    return SettingsUI:CreateText(parent, config)
end

local function FormatSliderValue(config, value)
    if config and type(config.formatValue) == "function" then
        return config.formatValue(value)
    end

    return tostring(value)
end

local function SetSliderText(slider, label, value)
    if slider.Text then
        slider.Text:SetText((label or "") .. ": " .. FormatSliderValue(slider.Config, value))
    end
end

local function SetSliderRangeText(slider, minValue, maxValue)
    if slider.Low then
        slider.Low:SetText(FormatSliderValue(slider.Config, minValue))
    end

    if slider.High then
        slider.High:SetText(FormatSliderValue(slider.Config, maxValue))
    end
end

function SettingsUI:CreateSlider(parent, config)
    config = config or {}

    local initialMin = type(config.min) == "function" and config.min() or tonumber(config.min) or 0
    local initialMax = type(config.max) == "function" and config.max() or tonumber(config.max) or 1
    local padding = parent and parent.SettingsPadding or {}
    local x = config.x or padding.left or 0
    local y = config.y or -(padding.top or 0)

    local slider = CreateFrame("Slider", config.name or UniqueFrameName("SettingsSlider"), parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(initialMin, initialMax)
    slider:SetValueStep(config.step or 1)
    slider.Config = config

    local function ApplySliderWidth()
        local parentWidth = parent and parent.GetWidth and parent:GetWidth() or 0
        local rightInset = tonumber(config.rightInset) or padding.right or 12
        local maxWidth = parentWidth > 1 and math.max(80, parentWidth - x - rightInset) or nil
        local requestedWidth = tonumber(config.width) or maxWidth or 260

        if maxWidth then
            slider:SetWidth(math.min(requestedWidth, maxWidth))
        else
            slider:SetWidth(requestedWidth)
        end
    end

    ApplySliderWidth()

    if parent and parent.HookScript then
        parent:HookScript("OnSizeChanged", ApplySliderWidth)
    end

    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    SetSliderRangeText(slider, initialMin, initialMax)

    function slider:SetControlEnabled(enabled)
        if enabled then
            self:Enable()
        else
            self:Disable()
        end

        SetControlAlpha(self, enabled)
    end

    slider:SetScript("OnValueChanged", function(self, value)
        if self.silent then
            return
        end

        local step = self.Config.step or 1
        value = math.floor((value / step) + 0.5) * step

        if step >= 1 then
            value = math.floor(value + 0.5)
        end

        SetSliderText(self, self.Config.label, value)
        UpdateSettingValue(self.Config, value)
    end)

    function slider:Refresh()
        ApplySliderWidth()

        local minValue = type(self.Config.min) == "function" and self.Config.min() or tonumber(self.Config.min) or 0
        local maxValue = type(self.Config.max) == "function" and self.Config.max() or tonumber(self.Config.max) or 1
        local value = ResolveSettingValue(self.Config)

        if value == nil then
            value = minValue
        end

        self:SetMinMaxValues(minValue, maxValue)

        SetSliderRangeText(self, minValue, maxValue)

        self.silent = true
        self:SetValue(value)
        self.silent = false
        SetSliderText(self, self.Config.label, value)
        self:SetControlEnabled(IsSettingEnabled(self.Config))
    end

    return slider
end

function Core.CreateSettingsSlider(parent, config)
    return SettingsUI:CreateSlider(parent, config)
end

function SettingsUI:CreateCheck(parent, config)
    config = config or {}

    local check = Core.CreateCheckButton(parent, function(self)
        UpdateSettingValue(config, self:GetChecked() and true or false)
    end)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", config.x or 0, config.y or 0)
    check.Config = config
    check.Text = Core.CreateLabel(check, config.label or "", "GameFontHighlight")
    check.Text:SetPoint("LEFT", check, "RIGHT", 4, 0)

    function check:Refresh()
        self:SetChecked(ResolveSettingValue(self.Config) and true or false)
        local enabled = IsSettingEnabled(self.Config)
        Core.SetEnabled(self, enabled)
        SetControlAlpha(self, enabled)
    end

    return check
end

function Core.CreateSettingsCheck(parent, config)
    return SettingsUI:CreateCheck(parent, config)
end

function SettingsUI:CreateDropdown(parent, config)
    config = config or {}

    local label = Core.CreateLabel(parent, config.label or "", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", config.x or 0, config.y or 0)

    local dropdown = Core.CreateDropdown(parent, config.name or UniqueFrameName("SettingsDropdown"), config.width or 140, function()
        local items = {}
        local choices = type(config.choices) == "function" and config.choices() or config.choices or {}
        local currentValue = ResolveSettingValue(config)

        for _, choice in ipairs(choices) do
            items[#items + 1] = {
                value = choice.value,
                label = choice.label,
                checked = currentValue == choice.value,
                disabled = choice.disabled,
            }
        end

        return items
    end, function(value)
        UpdateSettingValue(config, value)
    end)
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -4)
    dropdown.Config = config
    dropdown.Label = label

    function dropdown:Refresh()
        local choices = type(self.Config.choices) == "function" and self.Config.choices() or self.Config.choices or {}
        local currentValue = ResolveSettingValue(self.Config)
        local text = ""

        for _, choice in ipairs(choices) do
            if choice.value == currentValue then
                text = choice.label or tostring(choice.value or "")
                break
            end
        end

        Core.SetDropdownText(self, text)

        local enabled = IsSettingEnabled(self.Config)
        SetControlAlpha(self, enabled)
    end

    return dropdown
end

function Core.CreateSettingsDropdown(parent, config)
    return SettingsUI:CreateDropdown(parent, config)
end

local function ResolveColorValue(config)
    local r, g, b, a

    if config and type(config.get) == "function" then
        r, g, b, a = config.get()

        if type(r) == "table" then
            local color = r
            r = color.r or color[1]
            g = color.g or color[2]
            b = color.b or color[3]
            a = color.a or color[4]
        end
    elseif config and type(config.settings) == "table" then
        local prefix = config.prefix or config.key

        if prefix then
            r = config.settings[prefix .. "R"]
            g = config.settings[prefix .. "G"]
            b = config.settings[prefix .. "B"]
            a = config.settings[prefix .. "A"]
        end
    end

    return tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1
end

local function UpdateColorValue(config, r, g, b, a)
    if not config then
        return
    end

    if type(config.set) == "function" then
        config.set(r, g, b, a, config.key)
    elseif type(config.settings) == "table" then
        local prefix = config.prefix or config.key

        if prefix then
            config.settings[prefix .. "R"] = r
            config.settings[prefix .. "G"] = g
            config.settings[prefix .. "B"] = b
            config.settings[prefix .. "A"] = a
        end
    end

    if type(config.onChanged) == "function" then
        config.onChanged(r, g, b, a, config.key)
    end
end

local function ReadColorPickerAlpha(defaultAlpha)
    if OpacitySliderFrame and OpacitySliderFrame.GetValue then
        return 1 - (tonumber(OpacitySliderFrame:GetValue()) or 0)
    end

    if ColorPickerFrame and ColorPickerFrame.opacity ~= nil then
        return 1 - (tonumber(ColorPickerFrame.opacity) or 0)
    end

    return defaultAlpha or 1
end

function SettingsUI:CreateColorPicker(parent, config)
    config = config or {}

    local control = CreateFrame("Frame", nil, parent)
    control:SetPoint("TOPLEFT", parent, "TOPLEFT", config.x or 0, config.y or 0)
    control:SetSize(config.width or 260, config.height or 54)
    control.Config = config

    control.Label = Core.CreateLabel(control, config.label or "", "GameFontHighlight")
    control.Label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)

    control.Button = Core.CreateButton(control, config.buttonText or "Choose Colour", config.buttonWidth or 120, 24, nil, config.buttonOptions)
    control.Button:SetPoint("TOPLEFT", control.Label, "BOTTOMLEFT", 0, -8)

    control.Swatch = CreateFrame("Frame", nil, control.Button, "BackdropTemplate")
    control.Swatch:SetPoint("LEFT", control.Button, "RIGHT", 8, 0)
    control.Swatch:SetSize(config.swatchWidth or 34, config.swatchHeight or 20)
    SetBackdrop(control.Swatch, 0.35)

    control.SwatchTexture = control.Swatch:CreateTexture(nil, "ARTWORK")
    control.SwatchTexture:SetPoint("TOPLEFT", control.Swatch, "TOPLEFT", 3, -3)
    control.SwatchTexture:SetPoint("BOTTOMRIGHT", control.Swatch, "BOTTOMRIGHT", -3, 3)

    local function ApplyColorPickerWidth()
        local parentWidth = parent and parent.GetWidth and parent:GetWidth() or 0
        local padding = parent and parent.SettingsPadding or {}
        local x = config.x or padding.left or 0
        local rightInset = tonumber(config.rightInset) or padding.right or 12
        local width = parentWidth > 1 and math.max(180, parentWidth - x - rightInset) or (config.width or 260)

        control:SetWidth(math.min(tonumber(config.width) or width, width))
    end

    ApplyColorPickerWidth()

    if parent and parent.HookScript then
        parent:HookScript("OnSizeChanged", ApplyColorPickerWidth)
    end

    local function ApplyPickedColor()
        if not ColorPickerFrame or not ColorPickerFrame.GetColorRGB then
            return
        end

        local r, g, b = ColorPickerFrame:GetColorRGB()
        local _, _, _, oldAlpha = ResolveColorValue(config)
        local a = config.hasAlpha == false and oldAlpha or ReadColorPickerAlpha(oldAlpha)
        UpdateColorValue(config, r, g, b, a)

        if control.Refresh then
            control:Refresh()
        end
    end

    local function CancelPickedColor(previous, g, b, a)
        previous = previous or (ColorPickerFrame and ColorPickerFrame.previousValues)

        if type(previous) == "table" then
            UpdateColorValue(config, previous.r or previous[1], previous.g or previous[2], previous.b or previous[3], previous.a or previous[4])
        elseif previous ~= nil and g ~= nil and b ~= nil then
            UpdateColorValue(config, previous, g, b, a)
        end

        if control.Refresh then
            control:Refresh()
        end
    end

    control.Button:SetScript("OnClick", function()
        if not ColorPickerFrame then
            return
        end

        Core.PlaySound(Core.Sounds.buttonClick)

        local r, g, b, a = ResolveColorValue(config)
        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
        ColorPickerFrame.func = ApplyPickedColor
        ColorPickerFrame.swatchFunc = ApplyPickedColor
        ColorPickerFrame.opacityFunc = ApplyPickedColor
        ColorPickerFrame.cancelFunc = CancelPickedColor
        ColorPickerFrame.hasOpacity = config.hasAlpha ~= false
        local pickerOpacity = 1 - (a or 1)
        ColorPickerFrame.opacity = pickerOpacity

        if ColorPickerFrame.SetColorRGB then
            ColorPickerFrame:SetColorRGB(r, g, b)
        end

        if OpacitySliderFrame and OpacitySliderFrame.SetValue then
            OpacitySliderFrame:SetValue(pickerOpacity)
        end

        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end)

    function control:Refresh()
        ApplyColorPickerWidth()

        local r, g, b, a = ResolveColorValue(self.Config)
        self.SwatchTexture:SetColorTexture(r, g, b, a)

        local enabled = IsSettingEnabled(self.Config)
        Core.SetEnabled(self.Button, enabled)
        SetControlAlpha(self, enabled)
    end

    return control
end

function Core.CreateSettingsColorPicker(parent, config)
    return SettingsUI:CreateColorPicker(parent, config)
end

function SettingsUI:CreateButton(parent, config)
    config = config or {}

    local button = Core.CreateButton(parent, config.text or "", config.width or 110, config.height or 24, function(self)
        if type(config.onClick) == "function" then
            config.onClick(self)
        end

        if type(config.onChanged) == "function" then
            config.onChanged()
        end
    end, config.buttonOptions)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", config.x or 0, config.y or 0)
    button.Config = config

    function button:Refresh()
        local enabled = IsSettingEnabled(self.Config)
        Core.SetEnabled(self, enabled)
        SetControlAlpha(self, enabled)
    end

    return button
end

function Core.CreateSettingsButton(parent, config)
    return SettingsUI:CreateButton(parent, config)
end

