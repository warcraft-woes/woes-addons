local Overlay = _G.WoesScrollingOverlay
local Providers = Overlay.Providers
local C = Overlay.Constants
local Utils = Overlay.Utils
local Skills = Overlay.Skills
local Trackers = Overlay.Trackers

Providers.none = {
    render = function()
        return nil
    end,
}

Providers.customText = {
    render = function(row)
        return row.text ~= "" and row.text or nil
    end,
}

Providers.kills = {
    render = function(row)
        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Kills", tostring(Trackers.GetKillTrackTotal()), row.showLabel)
    end,
}

Providers.favouredEnemy = {
    render = function(row)
        local name, kills = Trackers.GetFavouredEnemy()
        local text = name and (name .. " (" .. tostring(kills) .. ")") or C.EMPTY_VALUE

        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Favoured Enemy", text, row.showLabel)
    end,
}

Providers.killsSinceRare = {
    render = function(row)
        local value = Trackers.GetKillsSinceRare()
        local text = value and tostring(value) or C.EMPTY_VALUE

        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Kills Since Rare", text, row.showLabel)
    end,
}

Providers.dropsLastHour = {
    render = function(row)
        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Drops Last Hour", tostring(Trackers.PruneGreenLootDrops()), row.showLabel)
    end,
}

Providers.gold = {
    render = function(row)
        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Gold", Trackers.FormatGoldValue(row.format ~= "compact"), row.showLabel)
    end,
}

Providers.goldLastHour = {
    render = function(row)
        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Gold Last Hour", Trackers.GetGoldLastHourText(row.format ~= "compact"), row.showLabel)
    end,
}

Providers.dropsPerHour = Providers.dropsLastHour
Providers.money = Providers.gold
Providers.moneyPerHour = Providers.goldLastHour

Providers.lowestHealth = {
    render = function(row)
        local value = Trackers.GetLowestHealthPercent()
        local text = value and string.format("%.1f%%", value) or C.EMPTY_VALUE

        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Lowest HP", text, row.showLabel)
    end,
}

Providers.killsToLevel = {
    render = function(row)
        local value = Trackers.GetKillsToLevelEstimate()
        local text = value and tostring(value) or C.EMPTY_VALUE

        return Utils.FormatLabeledText(row.label ~= "" and row.label or "Kills To Level", text, row.showLabel)
    end,
}

Providers.skill = {
    render = function(row)
        return Skills.Render(Skills.GetByName(row.target), row)
    end,
}

Providers.skillGroup = {
    render = function(row)
        return Skills.RenderGroup(row.target ~= "" and row.target or "primary", row)
    end,
}
