local Overlay = _G.WoesScrollingOverlay
local C = Overlay.Constants

C.DB_SCHEMA_VERSION = 1
C.ICON_SIZE = 24
C.SPAWN_PADDING = 30
C.XP_KILL_SAMPLE_SIZE = 10
C.DROPS_PER_HOUR_WINDOW = 3600
C.GOLD_LAST_HOUR_WINDOW = 3600
C.EMPTY_VALUE = "—"

C.DEFAULT_OPTIONS = {
    height = 42,
    borderWidth = 1,
    gap = 80,
    speed = 40,
    textSize = 14,
    y = 100,
    theme = "basic",
    pixelSnap = false,
    showLootItems = true,
    lootThreshold = 2,
    customBackgroundR = 0,
    customBackgroundG = 0,
    customBackgroundB = 0,
    customBackgroundA = 0.62,
    customBorderR = 1,
    customBorderG = 0.82,
    customBorderB = 0.18,
    customBorderA = 0.85,
    customTextR = 1,
    customTextG = 1,
    customTextB = 1,
    customTextA = 1,
}

C.THEMES = {
    basic = {
        label = "Basic",
        background = { 0, 0, 0, 0.62 },
        border = { 1, 0.82, 0.18, 0.85 },
        text = { 1, 1, 1, 1 },
    },
    horde = {
        label = "Horde",
        background = { 0.55, 0.09, 0.09, 0.62 },
        border = { 0, 0, 0, 0.9 },
        text = { 1, 0.92, 0.84, 1 },
    },
    alliance = {
        label = "Alliance",
        background = { 0, 0.26, 0.48, 0.72 },
        border = { 0.93, 0.91, 0.27, 0.9 },
        text = { 0.92, 0.96, 1, 1 },
    },
    class = {
        label = "Class",
    },
    custom = {
        label = "Custom",
    },
}

C.THEME_ORDER = { "basic", "horde", "alliance", "class", "custom" }

C.ITEM_QUALITY_LABELS = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
}

C.ITEM_QUALITY_HEX = {
    [0] = "ff9d9d9d",
    [1] = "ffffffff",
    [2] = "ff1eff00",
    [3] = "ff0070dd",
    [4] = "ffa335ee",
    [5] = "ffff8000",
}

C.SKILL_ICONS = {
    ["Alchemy"] = "Interface\\Icons\\Trade_Alchemy",
    ["Blacksmithing"] = "Interface\\Icons\\Trade_BlackSmithing",
    ["Cooking"] = "Interface\\Icons\\INV_Misc_Food_15",
    ["Defense"] = "Interface\\Icons\\Ability_Defend",
    ["Enchanting"] = "Interface\\Icons\\Trade_Engraving",
    ["Engineering"] = "Interface\\Icons\\Trade_Engineering",
    ["First Aid"] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Fishing"] = "Interface\\Icons\\Trade_Fishing",
    ["Herbalism"] = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    ["Leatherworking"] = "Interface\\Icons\\INV_Misc_ArmorKit_17",
    ["Mining"] = "Interface\\Icons\\Trade_Mining",
    ["Skinning"] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    ["Tailoring"] = "Interface\\Icons\\Trade_Tailoring",
    ["Axes"] = "Interface\\Icons\\INV_Axe_02",
    ["Two-Handed Axes"] = "Interface\\Icons\\INV_Axe_04",
    ["Bows"] = "Interface\\Icons\\INV_Weapon_Bow_05",
    ["Crossbows"] = "Interface\\Icons\\INV_Weapon_Crossbow_01",
    ["Daggers"] = "Interface\\Icons\\INV_Weapon_ShortBlade_05",
    ["Fist Weapons"] = "Interface\\Icons\\INV_Gauntlets_04",
    ["Guns"] = "Interface\\Icons\\INV_Weapon_Rifle_01",
    ["Maces"] = "Interface\\Icons\\INV_Mace_01",
    ["Two-Handed Maces"] = "Interface\\Icons\\INV_Hammer_04",
    ["Polearms"] = "Interface\\Icons\\INV_Spear_06",
    ["Staves"] = "Interface\\Icons\\INV_Staff_08",
    ["Swords"] = "Interface\\Icons\\INV_Sword_04",
    ["Two-Handed Swords"] = "Interface\\Icons\\INV_Sword_10",
    ["Thrown"] = "Interface\\Icons\\INV_ThrowingKnife_02",
    ["Unarmed"] = "Interface\\Icons\\Ability_GolemThunderClap",
    ["Wands"] = "Interface\\Icons\\INV_Wand_01",
}

C.SKILL_ABBREVIATIONS = {
    ["Alchemy"] = "Alch",
    ["Blacksmithing"] = "BS",
    ["Enchanting"] = "Ench",
    ["Engineering"] = "Eng",
    ["First Aid"] = "FA",
    ["Herbalism"] = "Herb",
    ["Leatherworking"] = "LW",
    ["Two-Handed Axes"] = "2H Axes",
    ["Two-Handed Maces"] = "2H Maces",
    ["Two-Handed Swords"] = "2H Swords",
}

C.PRIMARY_SKILLS = {
    ["Alchemy"] = true,
    ["Blacksmithing"] = true,
    ["Enchanting"] = true,
    ["Engineering"] = true,
    ["Herbalism"] = true,
    ["Leatherworking"] = true,
    ["Mining"] = true,
    ["Skinning"] = true,
    ["Tailoring"] = true,
}

C.SECONDARY_SKILLS = {
    ["Cooking"] = true,
    ["First Aid"] = true,
    ["Fishing"] = true,
}

C.WEAPON_SKILL_MAP = {
    ["One-Handed Axes"] = "Axes",
    ["Two-Handed Axes"] = "Two-Handed Axes",
    ["One-Handed Maces"] = "Maces",
    ["Two-Handed Maces"] = "Two-Handed Maces",
    ["One-Handed Swords"] = "Swords",
    ["Two-Handed Swords"] = "Two-Handed Swords",
    ["Daggers"] = "Daggers",
    ["Fist Weapons"] = "Fist Weapons",
    ["Polearms"] = "Polearms",
    ["Staves"] = "Staves",
    ["Bows"] = "Bows",
    ["Crossbows"] = "Crossbows",
    ["Guns"] = "Guns",
    ["Thrown"] = "Thrown",
    ["Wands"] = "Wands",
}

C.WEAPON_SKILLS = {
    ["Axes"] = true,
    ["Two-Handed Axes"] = true,
    ["Bows"] = true,
    ["Crossbows"] = true,
    ["Daggers"] = true,
    ["Defense"] = true,
    ["Fist Weapons"] = true,
    ["Guns"] = true,
    ["Maces"] = true,
    ["Two-Handed Maces"] = true,
    ["Polearms"] = true,
    ["Staves"] = true,
    ["Swords"] = true,
    ["Two-Handed Swords"] = true,
    ["Thrown"] = true,
    ["Unarmed"] = true,
    ["Wands"] = true,
}

C.PROFESSION_RANK_REQUIREMENTS = {
    { skill = 50, level = 10, max = 150 },
    { skill = 125, level = 20, max = 225 },
    { skill = 200, level = 35, max = 300 },
}

C.TICKER_TYPES = {
    { value = "none", label = "None" },
    { value = "customText", label = "Custom Text" },
    { value = "kills", label = "Kill Count" },
    { value = "favouredEnemy", label = "Favoured Enemy" },
    { value = "killsSinceRare", label = "Kills Since Rare" },
    { value = "dropsLastHour", label = "Drops Last Hour" },
    { value = "gold", label = "Gold" },
    { value = "goldLastHour", label = "Gold Last Hour" },
    { value = "lowestHealth", label = "Lowest HP" },
    { value = "killsToLevel", label = "Kills To Level" },
    { value = "skill", label = "Skill" },
    { value = "skillGroup", label = "Skill Group" },
}

C.TICKER_TYPE_LABELS = {}

for _, tickerType in ipairs(C.TICKER_TYPES) do
    C.TICKER_TYPE_LABELS[tickerType.value] = tickerType.label
end

C.FORMAT_LABELS = {
    full = "Full",
    compact = "Compact",
    valueOnly = "Value Only",
    iconValue = "Icon + Value",
}

C.FORMAT_ORDER = { "full", "compact", "valueOnly", "iconValue" }

C.DEFAULT_ROWS = {
    { id = "default:1", type = "kills", showLabel = true, format = "full" },
    { id = "default:2", type = "skillGroup", target = "weapon", showLabel = true, showIcon = true, showReminder = true, format = "full" },
    { id = "default:3", type = "skillGroup", target = "primary", showLabel = true, showIcon = true, showReminder = true, format = "full" },
    { id = "default:4", type = "skillGroup", target = "secondary", showLabel = true, showIcon = true, showReminder = true, format = "full" },
    { id = "default:5", type = "gold", showLabel = true, format = "full" },
    { id = "default:6", type = "none", showLabel = true, format = "full" },
}
