local addonName = ...
local addon = _G.LibStub("AceAddon-3.0"):NewAddon("FistfulOfLove", "AceEvent-3.0")
local AceGUI = _G.LibStub("AceGUI-3.0")
local fistful_events = _G.fistful_achievements
local InCombatLockdown = _G.InCombatLockdown
local UnitBuff
if _G.UnitBuffCustom then
    UnitBuff = _G.UnitBuffCustom
else
    UnitBuff = _G.UnitBuff
end
local C_Container = _G.C_Container
local UnitRace, UnitClass, UnitName = _G.UnitRace, _G.UnitClass, _G.UnitName
local UnitSex, UnitLevel, UnitIsPlayer = _G.UnitSex, _G.UnitLevel, _G.UnitIsPlayer
local unpack = _G.unpack
local GetTime = _G.GetTime
local GetAchievementCriteriaInfoByID = _G.GetAchievementCriteriaInfoByID
local GetAchievementInfo = _G.GetAchievementInfo
local GetAchievementLink = _G.GetAchievementLink
local GetInventoryItemID = _G.GetInventoryItemID

function addon:hide_tooltip()
    if self.frame then
        AceGUI:Release(self.frame)
        self.frame = nil
    end
end

function addon:findEventItem()
    for container = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(container) do
            local item = C_Container.GetContainerItemInfo(container, slot)
            if item then
                for key, event in pairs(fistful_events) do
                    if item['itemID'] == event['item'] then
                        return key
                    end
                end
            end
        end
    end

    --Check if the item is equipped
    for _, slot in ipairs({ 16, 17 }) do
        for key, event in pairs(fistful_events) do
            local itemID = GetInventoryItemID("player", slot)
            if itemID and itemID == event['item'] then
                return key
            end
        end
    end
    self:RegisterEvent('ITEM_PUSH')
end

local function race_image(race, gender)
    if race == 'Undead' then
        -- Images for undead are named scourge
        race = 'Scourge'
    end
    return string.format("Interface/CHARACTERFRAME/TEMPORARYPORTRAIT-%s-%s.PNG", gender, race:gsub(' ', ''))
end

local function buff_expiry(expirationTime)
    local time_left = expirationTime - GetTime()
    if time_left < 60 then
        return string.format("%.0f seconds left.", time_left)
    else
        local minutes = math.floor(time_left / 60)
        local seconds = math.floor(time_left - (minutes * 60))
        -- return string.format("%.2f minutes left.", time_left/60)
        return string.format("%d:%d minutes left.", minutes, seconds)
    end
end

function addon:getBuff(unit, find_spellId)
    for i = 1, 40 do
        local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, i)
        if spellId == find_spellId then
            return name, icon, duration, expirationTime
        elseif spellId == nil then
            return
        end
    end
end

function addon:show_tooltip(text, race, gender, buffName, buffIcon, expirationTime)
    self.frame = AceGUI:Create("Window")
    local f = self.frame
    f:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        addon.frame = nil
    end)
    f:SetTitle(self.achievement_name)
    f:SetLayout("Flow")
    f:SetHeight(100)
    f:SetWidth(250)
    f:EnableResize(false)

    local label = AceGUI:Create("Label")
    label:SetText(text)
    label:SetImageSize(32, 32)
    label:SetJustifyH('CENTER')
    f:AddChild(label)

    local buffText = AceGUI:Create("Label")
    f:AddChild(buffText)
    if buffIcon then
        buffText:SetText(buffName .. " " .. buff_expiry(expirationTime))
        label:SetImage(buffIcon)
    else
        buffText:SetText()
        if gender == 3 then
            label:SetImage(race_image(race, 'female'))
        elseif gender == 2 then
            label:SetImage(race_image(race, 'male'))
        end
    end
end

function addon:init(event_key)
    self.data = _G.fistful_achievements[event_key]
    self.data['criteria'] = _G.fistful_criteria[self.data['achievement']]
    self.achievement = GetAchievementLink(self.data['achievement'])
    self.achievement_name = select(2, GetAchievementInfo(self.data['achievement']))
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    --self:RegisterEvent(PLAYER_REGEN_ENABLED)
    --self:RegisterEvent(PLAYER_REGEN_DISABLED)
    print(('[%s] Initialized with achievement %s'):format(addonName, self.achievement))

    self:getNeed()
end

function addon:OnEnable()
    local event_key = self:findEventItem()
    if not event_key then
        --@debug@
        print(('[%s] No event item found'):format(addonName))
        --@end-debug@
        return
    else
        self:init(event_key)
    end
end

function addon:getNeed()
    self.missing = {}
    self.missingCombo = {}
    for criteriaID, criteria in pairs(self.data['criteria']) do
        local criteriaString, _, completed = GetAchievementCriteriaInfoByID(self.data['achievement'], criteriaID)
        --print(self.data['achievement'], criteriaID, criteriaString)
        if not completed then
            self.missingCombo[criteriaID] = criteria
            self.missing[criteriaID] = criteriaString
        end
    end
    --@debug@
    _G.DevTools_Dump(self.missing)
    --@end-debug@
end

function addon:valid(UnitId)
    local gender = UnitSex(UnitId)
    local level = UnitLevel(UnitId)
    if self.data['gender'] and gender ~= self.data['gender'] then
        return false
    end

    if self.data['min_level'] and level < self.data['level'] then
        return false
    end
end

function addon:need(UnitId)
    if not UnitIsPlayer(UnitId) then
        return
    end

    local race, raceFile, raceID = UnitRace(UnitId)
    local class, _, classID = UnitClass(UnitId)
    local gender = UnitSex(UnitId)
    local check_string
    if self.data["race"] and self.data["class"] then
        check_string = ('%s %s'):format(race, class)
    elseif self.data["race"] then
        check_string = race
    elseif self.data["class"] then
        check_string = class
    end

    for _, combo in pairs(self.missingCombo) do
        local race_iter, class_iter = unpack(combo)
        if not race_iter then
            raceID = nil
        end
        if not class_iter then
            classID = nil
        end

        if raceID == race_iter and classID == class_iter then
            local buffName, buffIcon, duration, expirationTime
            if self.data['spell'] ~= nil then
                buffName, buffIcon, duration, expirationTime = self:getBuff(UnitId, self.data['spell'])
                --@debug@
                if buffName then
                    print(('%s has buff %s duration %d expiration %d'):format(
                            UnitId, buffName, duration, expirationTime))
                    print(buff_expiry(expirationTime))
                else
                    print(('%s does not have buff'):format(UnitId))
                end
                --@end-debug@
            end
            print(('%s is a %s needed for %s'):format(UnitName(UnitId), check_string, self.achievement))
            if UnitId ~= "mouseover" then
                self:show_tooltip(('%s %s'):format(race, class), raceFile, gender, buffName, buffIcon, expirationTime)
            end
            return
        end
    end
    self:hide_tooltip()
end

function addon:PLAYER_TARGET_CHANGED()
    self:hide_tooltip()
    self:need("target")
end

function addon:UPDATE_MOUSEOVER_UNIT()
    self:need('mouseover')
end

function addon:CRITERIA_UPDATE()
    --Achievement criteria updated, scan achievement
    self:getNeed()
    self:UnregisterEvent("CRITERIA_UPDATE")
end

function addon:UNIT_SPELLCAST_SUCCEEDED(_, _, _, spell)
    if InCombatLockdown() then
        return
    end

    if spell == self.data['spell'] then
        --@debug@
        print(('Tracked spell %d cast on %s %s %s'):format(
                spell, UnitRace('target'), UnitClass('target'), UnitName('target')))
        --@end-debug@
        self:RegisterEvent("CRITERIA_UPDATE")
        self:getNeed()
        self:hide_tooltip()
    end
end

function addon:ITEM_PUSH(_, _, iconFileId)
    for key, event in pairs(fistful_events) do
        if iconFileId == event['item_icon'] then
            self:init(key)
            self:UnregisterEvent('ITEM_PUSH')
            return
        end
    end
end


--/dump GetAchievementCriteriaInfo(1699, 1)