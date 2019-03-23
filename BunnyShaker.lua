local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
EventFrame:RegisterEvent('ADDON_LOADED')
--https://us.battle.net/forums/en/wow/topic/3595346852
EventFrame:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
EventFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')

local completed_classes = {}
local bunny_debug = false
local buff_name = 'Sprung!'
local unit = 'target'
local race, gender, level, race_text
local valid_unit = false
local has_target = false

--achievement 2422
function colorize(text, color)
    return string.format('|cFF%s%s|r', color, text)
end

function list_buffs()
    for i=1,40 do
        local name, icon, _, _, _, expirationTime = UnitBuff("player",i)
        if name then
            print(("%d=%s, %s, %.2f minutes left."):format(i,name,icon,(expirationTime -GetTime())/60))
        end
    end
end

function find_buff(find_name, unit)
    if not unit then
        unit = "target"
    end
    for i=1,40 do
        local name = UnitBuff(unit,i)
        if name==find_name then
            return UnitBuff(unit,i)
        end
    end
end

function buff_expiry(expirationTime)
    local time_left = expirationTime - GetTime()
    if time_left < 60 then
        return string.format("%.0f seconds left.", time_left)
    else
        local minutes = math.floor(time_left/60)
        local seconds = math.floor(time_left - (minutes*60))
        -- return string.format("%.2f minutes left.", time_left/60)
        return string.format("%d:%d minutes left.", minutes, seconds)
    end
end

function bunny_progress()
    for i=1, GetAchievementNumCriteria(2422) do
        local criteriaString, criteriaType, completed, quantity, reqQuantity,
        charName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(2422, i)
        completed_classes[criteriaString] = completed
    end
end
function completed_debug()
    for i=1, GetAchievementNumCriteria(2422) do
        local criteriaString, criteriaType, completed, quantity, reqQuantity,
        charName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(2422, i)

        if completed_classes[criteriaString] then
            DEFAULT_CHAT_FRAME:AddMessage(string.format('%s', colorize(criteriaString, '00ff00')))
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format('%s', colorize(criteriaString, 'ff0000')))
        end
    end
end

function race_image(race, gender)
    if race == 'Undead' then -- Images for undead are named scourge
        race = 'Scourge'
    end
    return string.format("Interface/CHARACTERFRAME/TEMPORARYPORTRAIT-%s-%s.PNG",gender, race:gsub(' ', ''))
end

function update_tooltip()
    local buff, icon, count, _, duration, expirationTime = find_buff(buff_name, unit)

    if not has_target and not UnitIsPlayer('mouseover') then
        valid_unit = false
    end

    if not valid_unit then
        BunnyMakerTooltip:Hide()
    else
        BunnyMakerTooltip:Show()
    end
    BunnyMakerTooltip_RaceText:SetText(race_text);
    if buff then
        BunnyMakerTooltip_BuffText:SetText(buff_expiry(expirationTime))
        BunnyMakerTooltip_RaceIcon:SetTexture('Interface/ICONS/INV_Misc_Roses_01.PNG')
    else
        BunnyMakerTooltip_BuffText:SetText()
        if gender == 3 then
            BunnyMakerTooltip_RaceIcon:SetTexture(race_image(race, 'female'))
        elseif gender == 2 then
            BunnyMakerTooltip_RaceIcon:SetTexture(race_image(race, 'male'))
        end
    end
end

function unit_info(UnitId)
    if not UnitIsPlayer(UnitId) then
        valid_unit = false
        return
    end
    level = UnitLevel(UnitId)
    if level < 18 then
        valid_unit = false
        return
    end
    --Race is not an objective or is completed
    if completed_classes[race] ~= false and bunny_debug == false then
        valid_unit = false
        return
    end

    valid_unit = true
    unit = UnitId
    gender = UnitSex(UnitId)
    race = UnitRace(UnitId)
    race_text = string.format('%s level %s', race, level)
    if bunny_debug then
        print('Unit updated:', race_text)
    end
end

EventFrame:SetScript('OnUpdate', update_tooltip)
EventFrame:SetScript("OnEvent", function(self, event,...)
    if event == 'PLAYER_TARGET_CHANGED' then
        unit_info('target')
        if bunny_debug then
            print('Target changed, is the target valid?', valid_unit)
        end
        if UnitIsPlayer("target") then
            has_target = true
        else
            has_target = false
        end
    elseif event == 'UPDATE_MOUSEOVER_UNIT' then
        --Only use mouseover if no player is targeted
        if bunny_debug then
            print('UPDATE_MOUSEOVER_UNIT')
        end
        if not UnitIsPlayer("target") then
            unit_info('mouseover')
        end
    elseif event == 'ADDON_LOADED' then
        bunny_progress()
    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then
        local target, _, spell = ...
        if spell == 61815 then
            print(string.format('Sprung! cast on %s', target))
            --TODO: Update progress
        end
    end
end)