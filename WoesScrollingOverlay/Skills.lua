local Overlay = _G.WoesScrollingOverlay
local Skills = Overlay.Skills
local C = Overlay.Constants
local Utils = Overlay.Utils

function Skills.GetRelevantWeaponSkills()
    local relevant = {}
    local hasEquippedWeapon = false
    local inventorySlots = { 16, 17, 18 }

    if type(GetInventoryItemLink) == "function" and type(GetItemInfo) == "function" then
        for _, slotId in ipairs(inventorySlots) do
            local itemLink = GetInventoryItemLink("player", slotId)

            if itemLink then
                local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
                local skillName = C.WEAPON_SKILL_MAP[itemSubType] or itemSubType

                if itemType == "Weapon" and C.WEAPON_SKILLS[skillName] and skillName ~= "Unarmed" then
                    relevant[skillName] = true
                    hasEquippedWeapon = true
                end
            end
        end
    end

    relevant.Defense = true

    if not hasEquippedWeapon then
        relevant.Unarmed = true
    end

    return relevant
end

function Skills.GetProfessionRankReminder(current, max)
    current = tonumber(current) or 0
    max = tonumber(max) or 0

    if max >= 300 or current < max then
        return nil
    end

    local playerLevel = type(UnitLevel) == "function" and UnitLevel("player") or 0

    for _, requirement in ipairs(C.PROFESSION_RANK_REQUIREMENTS) do
        if max == requirement.max and current >= requirement.skill and playerLevel >= requirement.level then
            return "Interface\\Icons\\INV_Misc_Note_01"
        end
    end
end

function Skills.Collect()
    local skills = {}
    local relevantWeaponSkills = Skills.GetRelevantWeaponSkills()

    if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then
        return skills
    end

    for index = 1, GetNumSkillLines() do
        local skillName, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(index)

        if skillName and not isHeader then
            local current = tonumber(rank) or 0
            local max = tonumber(maxRank) or 0
            local mappedWeapon = C.WEAPON_SKILL_MAP[skillName] or skillName
            local category

            if current > 0 or max > 0 then
                if C.SECONDARY_SKILLS[skillName] then
                    category = "secondary"
                elseif C.WEAPON_SKILLS[mappedWeapon] or C.WEAPON_SKILLS[skillName] then
                    if relevantWeaponSkills[mappedWeapon] then
                        skillName = mappedWeapon
                        category = "weapon"
                    elseif relevantWeaponSkills[skillName] then
                        category = "weapon"
                    end
                elseif C.PRIMARY_SKILLS[skillName] then
                    category = "primary"
                end

                if category then
                    skills[#skills + 1] = {
                        category = category,
                        name = skillName,
                        current = current,
                        max = max,
                        icon = C.SKILL_ICONS[skillName],
                        reminderIcon = (category == "primary" or category == "secondary") and Skills.GetProfessionRankReminder(current, max) or nil,
                    }
                end
            end
        end
    end

    table.sort(skills, function(a, b)
        if a.category ~= b.category then
            return a.category < b.category
        end

        return a.name < b.name
    end)

    return skills
end

function Skills.GetByName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    for _, skill in ipairs(Skills.Collect()) do
        if skill.name == name then
            return skill
        end
    end
end

function Skills.Render(skill, row)
    if not skill then
        return nil
    end

    local format = row.format or "full"
    local value = tostring(skill.current or 0) .. "/" .. tostring(skill.max or 0)
    local icon = row.showIcon ~= false and Utils.IconText(skill.icon) or ""
    local reminder = row.showReminder ~= false and Utils.IconText(skill.reminderIcon) or ""
    local label = row.label ~= "" and row.label or skill.name

    if format == "valueOnly" then
        return Utils.FormatLabeledText(label, value, row.showLabel)
    end

    if format == "iconValue" then
        return Utils.FormatLabeledText(label, icon .. reminder .. value, row.showLabel)
    end

    if format == "compact" then
        local shortName = C.SKILL_ABBREVIATIONS[skill.name] or skill.name
        return Utils.FormatLabeledText(label, icon .. reminder .. shortName .. " " .. value, row.showLabel)
    end

    return Utils.FormatLabeledText(label, icon .. reminder .. skill.name .. " " .. value, row.showLabel)
end

function Skills.RenderGroup(category, row)
    local parts = {}

    for _, skill in ipairs(Skills.Collect()) do
        if skill.category == category then
            parts[#parts + 1] = Skills.Render(skill, {
                format = row.format,
                label = "",
                showLabel = false,
                showIcon = row.showIcon,
                showReminder = row.showReminder,
            })
        end
    end

    if #parts == 0 then
        return nil
    end

    local labels = {
        weapon = "Weapon Skills",
        primary = "Primary Professions",
        secondary = "Secondary Skills",
    }

    return Utils.FormatLabeledText(row.label ~= "" and row.label or labels[category], table.concat(parts, "    "), row.showLabel)
end
