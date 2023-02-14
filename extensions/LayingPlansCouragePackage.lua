-- 始计篇-勇包
-- Created by DZDcyj at 2023/2/14
module('extensions.LayingPlansCouragePackage', package.seeall)
extension = sgs.Package('LayingPlansCouragePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

ExSunyi = sgs.General(extension, 'ExSunyi', 'wu', '4', true, true)

LuaZaoli = sgs.CreateTriggerSkill {
    name = 'LuaZaoli',
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local isStart = (event == sgs.EventPhaseStart)
        if isStart then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
        end
        for _, cd in sgs.qlist(player:getHandcards()) do
            -- 带 -Clear 的标记通通由 extra.lua 内部接管，回合结束后消除
            if player:getMark(string.format('%s%d-Clear', self:objectName(), cd:getId())) == 0 then
                if isStart then
                    room:setPlayerCardLimitation(player, 'use, response', cd:toString(), false)
                else
                    room:removePlayerCardLimitation(player, 'use, response', cd:toString() .. '$0')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end
}

LuaZaoliCardMove = sgs.CreateTriggerSkill {
    name = 'LuaZaoliCardMove',
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
            player:objectName() ~= sgs.Player_NotActive and move.to_place == sgs.Player_PlaceHand and
            not move.card_ids:isEmpty() then
            for _, id in sgs.qlist(move.card_ids) do
                room:addPlayerMark(player, 'LuaZaoli' .. id .. '-Clear')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZaoli')
    end
}

LuaZaoliUse = sgs.CreateTriggerSkill {
    name = 'LuaZaoliUse',
    events = {sgs.CardUsed, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card
        local isHandcard
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
            isHandcard = use.m_isHandcard;
        else
            local resp = data:toCardResponse()
            card = resp.m_card
            isHandcard = resp.m_isHandcard;
        end
        if card and isHandcard and player:getMark('@LuaZaoli') < 4 then
            room:broadcastSkillInvoke('LuaZaoli')
            room:sendCompulsoryTriggerLog(player, 'LuaZaoli')
            player:gainMark('@LuaZaoli')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZaoli')
    end
}

LuaZaoliStart = sgs.CreateTriggerSkill {
    name = 'LuaZaoliStart',
    events = {sgs.EventPhaseStart, sgs.ChoiceMade},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getMark('@LuaZaoli') == 0 or player:getPhase() ~= sgs.Player_RoundStart then
                return false
            end
            room:broadcastSkillInvoke('LuaZaoli')
            if player:getCardCount(true) > 0 then
                room:askForDiscard(player, 'LuaZaoli', 10000, 1, false, true, 'LuaZaoli-discard')
                return false
            end
            local markCount = player:getMark('@LuaZaoli')
            player:loseMark('@LuaZaoli', markCount)
            player:drawCards(markCount, self:objectName())
            if markCount > 2 then
                room:loseHp(player)
            end
        else
            local dataStr = data:toString():split(':')
            if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~= 'LuaZaoli' then
                return false
            end
            local count = #dataStr[3]:split('+')
            local markCount = player:getMark('@LuaZaoli')
            player:loseMark('@LuaZaoli', markCount)
            player:drawCards(markCount + count, self:objectName())
            if markCount > 2 then
                room:loseHp(player)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZaoli')
    end
}

ExSunyi:addSkill(LuaZaoli)
SkillAnjiang:addSkill(LuaZaoliCardMove)
SkillAnjiang:addSkill(LuaZaoliUse)
SkillAnjiang:addSkill(LuaZaoliStart)
