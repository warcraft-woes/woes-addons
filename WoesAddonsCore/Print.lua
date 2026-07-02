local Core = _G.WoesAddonsCore

function Core.Print(addonName, ...)
    local messageParts = {}

    if select("#", ...) == 0 then
        messageParts[1] = tostring(addonName or "")
        addonName = "Woes AddOns"
    else
        for index = 1, select("#", ...) do
            messageParts[index] = tostring(select(index, ...))
        end
    end

    print("|c" .. Core.brandColor .. tostring(addonName or "Woes AddOns") .. "|r: " .. table.concat(messageParts, " "))
end

function Core.CreatePrinter(addonName)
    return function(...)
        Core.Print(addonName, ...)
    end
end

function Core.RegisterLoadedAddon(label)
    label = tostring(label or "")

    if label == "" then
        return
    end

    for _, existing in ipairs(Core.loadedAddons) do
        if existing == label then
            return
        end
    end

    Core.loadedAddons[#Core.loadedAddons + 1] = label
end

function Core.PrintLoadedSummary()
    Core.EnsureDB()

    if Core.options.showLoadedMessage == false then
        return
    end

    print("|c" .. Core.brandColor .. "Woes AddOns|r Loaded:")

    local printed = {}

    for _, label in ipairs(Core.loadedAddonOrder) do
        for _, loadedLabel in ipairs(Core.loadedAddons) do
            if loadedLabel == label then
                print("  " .. loadedLabel)
                printed[loadedLabel] = true
                break
            end
        end
    end

    for _, label in ipairs(Core.loadedAddons) do
        if not printed[label] then
            print("  " .. label)
        end
    end
end

