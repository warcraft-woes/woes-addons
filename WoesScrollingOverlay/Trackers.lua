local Overlay = _G.WoesScrollingOverlay
local Trackers = Overlay.Trackers
local State = Overlay.State
local C = Overlay.Constants
local DB = Overlay.DB

function Trackers.GetKillTrackMobTables()
    local KT = _G.KillTrack
    local globalMobs = KT and KT.Global and KT.Global.MOBS or _G.KILLTRACK and _G.KILLTRACK.MOBS
    local charMobs = KT and KT.CharGlobal and KT.CharGlobal.MOBS or _G.KILLTRACK_CHAR and _G.KILLTRACK_CHAR.MOBS

    return type(globalMobs) == "table" and globalMobs or {}, type(charMobs) == "table" and charMobs or {}
end

function Trackers.GetKillTrackTotal()
    local _, charMobs = Trackers.GetKillTrackMobTables()
    local total = 0

    for _, mob in pairs(charMobs) do
        if type(mob) == "table" then
            total = total + (tonumber(mob.kills or mob.Kills or mob.count) or 0)
        elseif type(mob) == "number" then
            total = total + mob
        end
    end

    return total
end

function Trackers.GetFavouredEnemy()
    local _, charMobs = Trackers.GetKillTrackMobTables()
    local bestName
    local bestKills = 0

    for key, mob in pairs(charMobs) do
        local name = type(mob) == "table" and (mob.name or mob.Name) or tostring(key)
        local kills = type(mob) == "table" and tonumber(mob.kills or mob.Kills or mob.count) or tonumber(mob)

        if kills and kills > bestKills then
            bestName = name
            bestKills = kills
        end
    end

    return bestName, bestKills
end

function Trackers.GetCurrentTimestamp()
    if type(GetServerTime) == "function" then
        return GetServerTime()
    end

    if type(time) == "function" then
        return time()
    end

    if type(GetTime) == "function" then
        return math.floor(GetTime())
    end

    return 0
end

function Trackers.PruneGreenLootDrops()
    if not WoesScrollingOverlayCharacterDB or type(WoesScrollingOverlayCharacterDB.greenLootDrops) ~= "table" then
        return 0
    end

    local now = Trackers.GetCurrentTimestamp()

    for index = #WoesScrollingOverlayCharacterDB.greenLootDrops, 1, -1 do
        local timestamp = tonumber(WoesScrollingOverlayCharacterDB.greenLootDrops[index])

        if not timestamp or now - timestamp > C.DROPS_PER_HOUR_WINDOW then
            table.remove(WoesScrollingOverlayCharacterDB.greenLootDrops, index)
        else
            WoesScrollingOverlayCharacterDB.greenLootDrops[index] = timestamp
        end
    end

    return #WoesScrollingOverlayCharacterDB.greenLootDrops
end

function Trackers.TrackLootQuality(quality)
    if not State.ready or not quality then
        return
    end

    if quality >= 2 then
        WoesScrollingOverlayCharacterDB.greenLootDrops[#WoesScrollingOverlayCharacterDB.greenLootDrops + 1] = Trackers.GetCurrentTimestamp()
        Trackers.PruneGreenLootDrops()
    end

    if quality >= 3 then
        WoesScrollingOverlayCharacterDB.rareDropKillTotal = Trackers.GetKillTrackTotal()
    end
end

function Trackers.GetKillsSinceRare()
    local baseline = tonumber(WoesScrollingOverlayCharacterDB and WoesScrollingOverlayCharacterDB.rareDropKillTotal)

    if not baseline then
        return nil
    end

    return math.max(0, Trackers.GetKillTrackTotal() - baseline)
end

function Trackers.GetItemInfoSafe(itemLink)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemLink)
    end

    if type(GetItemInfo) == "function" then
        return GetItemInfo(itemLink)
    end
end

function Trackers.QueueLootTickerItem(itemLink, quantity)
    local name, link, quality, _, _, _, _, _, _, icon = Trackers.GetItemInfoSafe(itemLink)
    quality = tonumber(quality) or 0
    link = link or itemLink

    if not name then
        return
    end

    Trackers.TrackLootQuality(quality)

    if not State.options.showLootItems or quality < (State.options.lootThreshold or 2) then
        return
    end

    Overlay.Ticker.AddOneShotItem({
        key = "loot:" .. tostring(GetTime()),
        text = (quantity and quantity > 1) and (link .. " x" .. tostring(quantity)) or link,
        texture = icon,
        link = link,
        tooltipLink = link,
    })
end

function Trackers.ParseLootMessage(message)
    if type(message) ~= "string" then
        return nil
    end

    local itemLink = string.match(message, "(|c%x+|Hitem:.-|h%[.-%]|h|r)")
    local quantity = tonumber(string.match(message, "x(%d+)")) or 1

    return itemLink, quantity
end

function Trackers.FormatGoldValue(includeCopper)
    local gold = type(GetMoney) == "function" and GetMoney() or 0

    return Trackers.FormatCopperValue(gold, includeCopper)
end

function Trackers.FormatCopperValue(amount, includeCopper)
    amount = math.floor(tonumber(amount) or 0)

    local sign = ""

    if amount < 0 then
        sign = "-"
        amount = math.abs(amount)
    end

    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100

    if includeCopper == false then
        return string.format("%s%d |TInterface\\MoneyFrame\\UI-GoldIcon:0|t %d |TInterface\\MoneyFrame\\UI-SilverIcon:0|t", sign, gold, silver)
    end

    return string.format(
        "%s%d |TInterface\\MoneyFrame\\UI-GoldIcon:0|t %d |TInterface\\MoneyFrame\\UI-SilverIcon:0|t %d |TInterface\\MoneyFrame\\UI-CopperIcon:0|t",
        sign,
        gold,
        silver,
        copper
    )
end

function Trackers.PruneGoldSamples(now)
    now = tonumber(now) or Trackers.GetCurrentTimestamp()

    local cutoff = now - C.GOLD_LAST_HOUR_WINDOW
    local valid = {}
    local pruned = {}
    local baselineGold

    for _, sample in ipairs(State.goldSamples) do
        if type(sample) == "table" then
            local timestamp = tonumber(sample.time)
            local gold = tonumber(sample.gold)

            if timestamp and gold and timestamp <= now and gold >= 0 then
                valid[#valid + 1] = {
                    time = timestamp,
                    gold = gold,
                }
            end
        end
    end

    table.sort(valid, function(left, right)
        return left.time < right.time
    end)

    for _, sample in ipairs(valid) do
        if sample.time <= cutoff then
            baselineGold = sample.gold
        else
            pruned[#pruned + 1] = sample
        end
    end

    if baselineGold then
        table.insert(pruned, 1, {
            time = cutoff,
            gold = baselineGold,
        })
    end

    State.goldSamples = pruned

    return State.goldSamples
end

function Trackers.RecordGoldSample()
    if not State.ready or type(GetMoney) ~= "function" then
        return
    end

    local now = Trackers.GetCurrentTimestamp()
    local gold = tonumber(GetMoney()) or 0
    local samples = Trackers.PruneGoldSamples(now)
    local last = samples[#samples]

    if last and last.time == now then
        last.gold = gold
    elseif not last or last.gold ~= gold then
        samples[#samples + 1] = {
            time = now,
            gold = gold,
        }
    end

    Trackers.PruneGoldSamples(now)
    DB.SaveGoldSamples()
end

function Trackers.GetGoldLastHour()
    if not State.ready or type(GetMoney) ~= "function" then
        return nil
    end

    local now = Trackers.GetCurrentTimestamp()
    local currentGold = tonumber(GetMoney()) or 0
    local samples = Trackers.PruneGoldSamples(now)

    if #samples == 0 then
        samples[1] = {
            time = now,
            gold = currentGold,
        }
        DB.SaveGoldSamples()
        return 0
    end

    local baseline = samples[1]
    if now - baseline.time <= 0 then
        return 0
    end

    return currentGold - baseline.gold
end

function Trackers.GetGoldLastHourText(includeCopper)
    local goldLastHour = Trackers.GetGoldLastHour()

    if not goldLastHour then
        return C.EMPTY_VALUE
    end

    return Trackers.FormatCopperValue(goldLastHour, includeCopper)
end

Trackers.FormatMoneyValue = Trackers.FormatGoldValue
Trackers.RecordMoneySample = Trackers.RecordGoldSample
Trackers.PruneMoneySamples = Trackers.PruneGoldSamples
Trackers.GetMoneyPerHour = Trackers.GetGoldLastHour
Trackers.GetMoneyPerHourText = Trackers.GetGoldLastHourText

function Trackers.AddKillXPSample(amount)
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        return
    end

    table.insert(State.xpKillSamples, 1, amount)

    while #State.xpKillSamples > C.XP_KILL_SAMPLE_SIZE do
        table.remove(State.xpKillSamples)
    end

    DB.SaveXPKillSamples()
end

function Trackers.GetAverageKillXP()
    local total = 0

    for _, amount in ipairs(State.xpKillSamples) do
        total = total + amount
    end

    if total <= 0 or #State.xpKillSamples == 0 then
        return nil
    end

    return total / #State.xpKillSamples
end

function Trackers.GetKillsToLevelEstimate()
    local averageXP = Trackers.GetAverageKillXP()

    if not averageXP or averageXP <= 0 or type(UnitXP) ~= "function" or type(UnitXPMax) ~= "function" then
        return nil
    end

    local remainingXP = (UnitXPMax("player") or 0) - (UnitXP("player") or 0)

    if remainingXP <= 0 then
        return 0
    end

    return math.ceil(remainingXP / averageXP)
end

function Trackers.TrackLowestHealth()
    if not State.ready or type(UnitHealth) ~= "function" or type(UnitHealthMax) ~= "function" then
        return false
    end

    local maxHealth = tonumber(UnitHealthMax("player")) or 0
    local currentHealth = tonumber(UnitHealth("player")) or 0

    if maxHealth <= 0 or currentHealth <= 0 then
        return false
    end

    local percent = (currentHealth / maxHealth) * 100
    local existing = tonumber(WoesScrollingOverlayCharacterDB.lowestHealthPercent)

    if not existing or percent < existing then
        WoesScrollingOverlayCharacterDB.lowestHealthPercent = percent
        return true
    end

    return false
end

function Trackers.GetLowestHealthPercent()
    return tonumber(WoesScrollingOverlayCharacterDB and WoesScrollingOverlayCharacterDB.lowestHealthPercent)
end

function Trackers.ResetLowestHealth()
    if not State.ready or not WoesScrollingOverlayCharacterDB then
        return
    end

    WoesScrollingOverlayCharacterDB.lowestHealthPercent = nil
    Trackers.TrackLowestHealth()
    Overlay.Ticker.ApplyConfiguredItems()
end

function Trackers.ParseCombatXP(message)
    if type(message) ~= "string" then
        return nil
    end

    local xp = string.match(string.lower(message), "(%d+)%s+experience") or string.match(message, "(%d+)")
    return tonumber(xp)
end
