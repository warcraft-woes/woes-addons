local Overlay = _G.WoesScrollingOverlay
local DB = Overlay.DB
local State = Overlay.State
local C = Overlay.Constants
local Utils = Overlay.Utils
local Theme = Overlay.Theme

State.options = State.options or {}
State.rows = State.rows or {}
State.xpKillSamples = State.xpKillSamples or {}
State.goldSamples = State.goldSamples or {}
State.nextRowId = State.nextRowId or 1
State.ready = false

local ROW_TYPE_ALIASES = {
    dropsPerHour = "dropsLastHour",
    money = "gold",
    moneyPerHour = "goldLastHour",
}

local function ResetCurrentSchema(charDB)
    charDB.schemaVersion = C.DB_SCHEMA_VERSION
    charDB.options = {
        theme = Theme.GetDefaultThemeKey(),
    }
    charDB.rows = nil
    charDB.nextRowId = 1
end

local function HasRenderableRows(rows)
    if type(rows) ~= "table" then
        return false
    end

    for _, row in ipairs(rows) do
        if type(row) == "table" and row.type and row.type ~= "none" then
            return true
        end
    end

    return false
end

function DB.AllocateRowId()
    local rowId = "row:" .. tostring(State.nextRowId)
    State.nextRowId = State.nextRowId + 1

    if State.ready and WoesScrollingOverlayCharacterDB then
        WoesScrollingOverlayCharacterDB.nextRowId = State.nextRowId
    end

    return rowId
end

function DB.CopyTickerRow(row)
    row = row or {}

    return {
        id = type(row.id) == "string" and row.id ~= "" and row.id or DB.AllocateRowId(),
        type = ROW_TYPE_ALIASES[row.type] or row.type or "none",
        target = row.target or "",
        format = row.format or "full",
        label = row.label or row.text or "",
        text = row.text or "",
        showLabel = row.showLabel ~= false,
        showIcon = row.showIcon ~= false,
        showReminder = row.showReminder ~= false,
    }
end

function DB.CreateTickerRow(rowType)
    return DB.CopyTickerRow({
        id = DB.AllocateRowId(),
        type = rowType or "none",
        format = "full",
    })
end

function DB.SaveRows()
    if not State.ready or not WoesScrollingOverlayCharacterDB then
        return
    end

    WoesScrollingOverlayCharacterDB.rows = {}

    for index, row in ipairs(State.rows) do
        WoesScrollingOverlayCharacterDB.rows[index] = DB.CopyTickerRow(row)
    end

    WoesScrollingOverlayCharacterDB.nextRowId = State.nextRowId
end

function DB.SaveOptions()
    if not State.ready or not WoesScrollingOverlayCharacterDB then
        return
    end

    WoesScrollingOverlayCharacterDB.options = {}

    for key, value in pairs(State.options) do
        WoesScrollingOverlayCharacterDB.options[key] = value
    end
end

function DB.SaveXPKillSamples()
    if not State.ready or not WoesScrollingOverlayCharacterDB then
        return
    end

    WoesScrollingOverlayCharacterDB.xpKillSamples = {}

    for index, value in ipairs(State.xpKillSamples) do
        WoesScrollingOverlayCharacterDB.xpKillSamples[index] = value
    end
end

function DB.SaveGoldSamples()
    if not State.ready or not WoesScrollingOverlayCharacterDB then
        return
    end

    WoesScrollingOverlayCharacterDB.goldSamples = {}

    for index, sample in ipairs(State.goldSamples) do
        if type(sample) == "table" then
            WoesScrollingOverlayCharacterDB.goldSamples[index] = {
                time = tonumber(sample.time) or 0,
                gold = tonumber(sample.gold) or 0,
            }
        end
    end
end

function DB.Ensure()
    if type(WoesScrollingOverlayCharacterDB) ~= "table" then
        WoesScrollingOverlayCharacterDB = {}
    end

    local charDB = WoesScrollingOverlayCharacterDB

    if charDB.schemaVersion ~= C.DB_SCHEMA_VERSION or not HasRenderableRows(charDB.rows) then
        ResetCurrentSchema(charDB)
    end

    if type(charDB.options) ~= "table" then
        charDB.options = {
            theme = Theme.GetDefaultThemeKey(),
        }
    elseif charDB.options.theme == nil or not C.THEMES[charDB.options.theme] then
        charDB.options.theme = Theme.GetDefaultThemeKey()
    end

    charDB.options = Utils.CopyDefaults(charDB.options, C.DEFAULT_OPTIONS)

    if type(charDB.rows) ~= "table" then
        charDB.rows = {}

        for index, row in ipairs(C.DEFAULT_ROWS) do
            charDB.rows[index] = DB.CopyTickerRow(row)
        end
    end

    if type(charDB.nextRowId) ~= "number" then
        charDB.nextRowId = 1
    end

    if type(charDB.xpKillSamples) ~= "table" then
        charDB.xpKillSamples = {}
    end

    if type(charDB.goldSamples) ~= "table" then
        charDB.goldSamples = {}
    end

    if type(charDB.greenLootDrops) ~= "table" then
        charDB.greenLootDrops = {}
    end

    charDB.rareDropKillTotal = tonumber(charDB.rareDropKillTotal)
    charDB.lowestHealthPercent = tonumber(charDB.lowestHealthPercent)

    State.nextRowId = charDB.nextRowId
    State.options = {}

    for key in pairs(C.DEFAULT_OPTIONS) do
        State.options[key] = charDB.options[key]
    end

    State.rows = {}

    for _, row in ipairs(charDB.rows) do
        if type(row) == "table" then
            State.rows[#State.rows + 1] = DB.CopyTickerRow(row)
        end
    end

    if #State.rows == 0 then
        State.rows[1] = DB.CreateTickerRow("none")
    end

    State.xpKillSamples = {}

    for _, value in ipairs(charDB.xpKillSamples) do
        value = tonumber(value)

        if value and value > 0 then
            State.xpKillSamples[#State.xpKillSamples + 1] = value
        end
    end

    State.goldSamples = {}

    for _, sample in ipairs(charDB.goldSamples) do
        if type(sample) == "table" then
            local timestamp = tonumber(sample.time)
            local gold = tonumber(sample.gold)

            if timestamp and gold and timestamp >= 0 and gold >= 0 then
                State.goldSamples[#State.goldSamples + 1] = {
                    time = timestamp,
                    gold = gold,
                }
            end
        end
    end

    State.ready = true
    DB.SaveRows()
end
