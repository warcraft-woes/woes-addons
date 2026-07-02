local Core = _G.WoesAddonsCore
local Internal = Core.Internal
local UniqueFrameName = Internal.UniqueFrameName

function Core.CreateButton(parent, text, width, height, onClick, options)
    if type(onClick) == "table" and options == nil then
        options = onClick
        onClick = nil
    end

    options = options or {}

    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 96, height or 24)
    button:SetText(text or "")

    button:SetScript("OnClick", function(self, ...)
        Core.PlaySound(Core.Sounds.ResolveButtonSound(options))

        if onClick then
            onClick(self, ...)
        end
    end)

    return button
end

function Core.CreateCheckButton(parent, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)

    if onClick then
        check:SetScript("OnClick", onClick)
    end

    return check
end

function Core.CreateEditBox(parent, width, height, onCommit)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(width or 160, height or 24)
    editBox:SetAutoFocus(false)

    if onCommit then
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            onCommit(self)
        end)
        editBox:SetScript("OnEditFocusLost", onCommit)
    end

    return editBox
end

function Core.CreateDropdown(parent, name, width, getItems, onSelect)
    local dropdown = CreateFrame("Frame", name or UniqueFrameName("Dropdown"), parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 140)

    UIDropDownMenu_Initialize(dropdown, function(self)
        local items = getItems and getItems(self) or {}

        for _, item in ipairs(items) do
            local selectedItem = item
            local selectedValue = item.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.label or item.text or tostring(item.value or "")
            info.value = item.value
            info.checked = item.checked
            info.disabled = item.disabled
            info.func = function()
                if onSelect then
                    onSelect(selectedValue, selectedItem)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    return dropdown
end

function Core.SetDropdownText(dropdown, text)
    if dropdown then
        UIDropDownMenu_SetText(dropdown, text or "")
    end
end

function Core.SetDropdownEnabled(dropdown, enabled)
    if not dropdown then
        return
    end

    local name = dropdown.GetName and dropdown:GetName()
    local button = name and _G[name .. "Button"]
    local text = name and _G[name .. "Text"]

    if enabled then
        if type(UIDropDownMenu_EnableDropDown) == "function" then
            UIDropDownMenu_EnableDropDown(dropdown)
        elseif dropdown.Enable then
            dropdown:Enable()
        end

        if button and button.Enable then
            button:Enable()
        end
    else
        if type(UIDropDownMenu_DisableDropDown) == "function" then
            UIDropDownMenu_DisableDropDown(dropdown)
        elseif dropdown.Disable then
            dropdown:Disable()
        end

        if button and button.Disable then
            button:Disable()
        end
    end

    local normalTexture = button and button.GetNormalTexture and button:GetNormalTexture()

    if normalTexture and normalTexture.SetDesaturated then
        normalTexture:SetDesaturated(not enabled)
    end

    if text and text.SetTextColor then
        if enabled then
            text:SetTextColor(1, 1, 1)
        else
            text:SetTextColor(0.5, 0.5, 0.5)
        end
    end
end

function Core.CreateLabel(parent, text, fontObject)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetText(text or "")
    return label
end

Core.UI.CreateButton = Core.CreateButton
Core.UI.CreateCheckButton = Core.CreateCheckButton
Core.UI.CreateEditBox = Core.CreateEditBox
Core.UI.CreateDropdown = Core.CreateDropdown
Core.UI.SetDropdownText = Core.SetDropdownText
Core.UI.SetDropdownEnabled = Core.SetDropdownEnabled
Core.UI.CreateLabel = Core.CreateLabel
