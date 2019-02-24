local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
EventFrame:RegisterEvent('VARIABLES_LOADED')
--https://us.battle.net/forums/en/wow/topic/3595346852
EventFrame:RegisterEvent('UPDATE_MOUSEOVER_UNIT')

local completed_classes = {}
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
    return string.format("%.2f minutes left.", expirationTime - GetTime()/60)
end

function bunny_progress()
    for i=1, GetAchievementNumCriteria(2422) do
        local criteriaString, criteriaType, completed, quantity, reqQuantity,
        charName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(2422, i)
        completed_classes[criteriaString] = completed
        --if completed then
        --    DEFAULT_CHAT_FRAME:AddMessage(string.format('%s', colorize(criteriaString, '00ff00')))
        --else
        --    DEFAULT_CHAT_FRAME:AddMessage(string.format('%s', colorize(criteriaString, 'ff0000')))
        --end
    end
end

function race_image(race, gender)
    return string.format("Interface/CHARACTERFRAME/TEMPORARYPORTRAIT-%s-%s.PNG",gender, race:gsub(' ', ''))
end

function gender_check(UnitId)
    if not UnitId then
        UnitId = "target"
    end
    BunnyMakerTooltip:Hide()

    if not UnitIsPlayer(UnitId) then
        return
    end
    --TODO: Check if unit is allied race (UnitAlliedRaceInfo)
    local gender = UnitSex(UnitId)
    local race = UnitRace(UnitId)
    local level = UnitLevel(UnitId)

    -- DEFAULT_CHAT_FRAME:AddMessage(string.format('Gender: %d Race: %d, Level %d', gender, race, level))
    if level >= 18 then
        -- DEFAULT_CHAT_FRAME:AddMessage(string.format('Target is female %s of level %s', race, level))
        local race_text = string.format('%s level %s', race, level)
        BunnyMakerTooltip_RaceText:SetText(race_text);
        if gender == 3 then
            BunnyMakerTooltip_RaceIcon:SetTexture(race_image(race, 'female'))
        elseif gender == 2 then
            BunnyMakerTooltip_RaceIcon:SetTexture(race_image(race, 'male'))
        end
        --TODO: Add buff check to tooltip
        buff = find_buff('Sprung!', UnitId)

        BunnyMakerTooltip:Show();

    end
end

EventFrame:SetScript("OnEvent", function(self, event,...)
    if event == 'PLAYER_TARGET_CHANGED' then
        gender_check()
    elseif event == 'UPDATE_MOUSEOVER_UNIT' then
        --Only use mouseover if no player is targeted
        if not UnitIsPlayer("target") then
            gender_check("mouseover")
        end
    end
end)