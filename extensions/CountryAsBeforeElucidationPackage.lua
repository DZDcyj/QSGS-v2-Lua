-- 江山如故·承包
-- Created by DZDcyj at 2023/10/4
module('extensions.CountryAsBeforeElucidationPackage', package.seeall)
extension = sgs.Package('CountryAsBeforeElucidationPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 承·关羽
ExChengGuanyu = sgs.General(extension, 'ExChengGuanyu', 'shu', '5', true, true)

-- 合法花色（排除无花色）
local VALID_SUITS = {'club', 'spade', 'heart', 'diamond'}

local function hasValidSuit(card)
    return table.contains(VALID_SUITS, card:getSuitString())
end

LuaGuanjue = sgs.CreateTriggerSkill {
    name = 'LuaGuanjue',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and hasValidSuit(card) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local suit = card:getSuitString()
            local selfMark = string.format('@LuaGuanjue-%s-Clear', suit)
            room:setPlayerMark(player, selfMark, 1)
            local pattern = '.|' .. suit .. '|.|.|.'
            local checkMark = 'LuaGuanjue_ban_ur_' .. suit
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark(checkMark) == 0 then
                    room:setPlayerCardLimitation(p, 'use,response', pattern, true)
                    room:addPlayerMark(p, checkMark)
                end
            end
        end
    end,
}

LuaGuanjueClear = sgs.CreateTriggerSkill {
    name = 'LuaGuanjueClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to ~= sgs.Player_NotActive then
            return false
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            for _, suit in ipairs(VALID_SUITS) do
                local mark = 'LuaGuanjue_ban_ur_' .. suit
                local pattern = '.|' .. suit .. '|.|.|.'
                if p:getMark(mark) > 0 then
                    room:setPlayerMark(p, mark, 0)
                    room:removePlayerCardLimitation(p, 'use,response', pattern .. '$1')
                end
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaNianenCard = sgs.CreateSkillCard {
    name = 'LuaNianen',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return rinsan.guhuoCardFilter(self, targets, to_select, self:objectName())
    end,
    feasible = function(self, targets)
        return rinsan.selfFeasible(self, targets, self:objectName())
    end,
    on_validate = function(self, card_use)
        return rinsan.guhuoCardOnValidate(self, card_use, self:objectName(), 'nianen', 'Nianen')
    end,
    on_validate_in_response = function(self, source)
        return rinsan.guhuoCardOnValidateInResponse(self, source, 'LuaNianen', 'nianen', 'Nianen')
    end,
}

LuaNianenVS = sgs.CreateViewAsSkill {
    name = 'LuaNianen',
    response_or_use = true,
    n = 1,
    view_filter = function(self, selected, to_select)
        return true
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getMark('LuaNianen-Clear') > 0 then
            return false
        end
        if pattern == 'nullification' then
            return false
        end
        return rinsan.guhuoVSSkillEnabledAtResponse(self, player, pattern)
    end,
    enabled_at_play = function(self, player)
        if player:getMark('LuaNianen-Clear') > 0 then
            return false
        end
        local slashAvailable
        for _, cd in sgs.qlist(sgs.Self:getHandcards()) do
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName(self:objectName())
            slash:addSubcard(cd)
            if slash:isAvailable(player) then
                slashAvailable = true
                break
            end
        end

        return player:isWounded() or slashAvailable or sgs.Analeptic_IsAvailable(player)
    end,
    enabled_at_nullification = function(self, player)
        return false
    end,
    view_as = function(self, cards)
        if #cards < 1 then
            return nil
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = LuaNianenCard:clone()
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            card:setUserString(pattern)
            for _, cd in ipairs(cards) do
                card:addSubcard(cd)
            end
            local available = false
            for _, name in ipairs(pattern:split('+')) do
                local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
                c:deleteLater()
                if not sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                    available = true
                    break
                end
            end
            if not available then
                return nil
            end
            return card
        end
        local c = sgs.Self:getTag('LuaNianen'):toCard()
        if c then
            local card = LuaNianenCard:clone()
            card:setUserString(c:objectName())
            for _, cd in ipairs(cards) do
                card:addSubcard(cd)
            end
            if sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                return nil
            end
            return card
        end
        return nil
    end,
}

local function isNormalRedSlash(card)
    if card:isRed() then
        if card:isKindOf('Slash') and (not card:isKindOf('NatureSlash')) then
            return true
        end
    end
    return false
end

LuaNianen = sgs.CreateTriggerSkill {
    name = 'LuaNianen',
    view_as_skill = LuaNianenVS,
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and card:getSkillName() == self:objectName() then
            if not isNormalRedSlash(card) then
                room:addPlayerMark(player, self:objectName() .. '-Clear')
            end
        end
    end,
}

LuaNianenDistance = sgs.CreateDistanceSkill {
    name = 'LuaNianenDistance',
    correct_func = function(self, from, to)
        if from:getMark('LuaNianen-Clear') > 0 and (not from:hasSkill('mashu')) then
            return -1
        end
        return 0
    end,
}

LuaNianen:setGuhuoDialog('l')

ExChengGuanyu:addSkill(LuaGuanjue)
ExChengGuanyu:addSkill(LuaNianen)
table.insert(hiddenSkills, LuaGuanjueClear)
table.insert(hiddenSkills, LuaNianenDistance)

rinsan.addHiddenSkills(hiddenSkills)
