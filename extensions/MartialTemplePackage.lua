-- 限定-武庙包
-- Created by DZDcyj at 2025/5/31
module('extensions.MartialTemplePackage', package.seeall)
extension = sgs.Package('MartialTemplePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

WuLuxun = sgs.General(extension, 'WuLuxun', 'wu', 3, true, true, false, 3)

LuaXiongmuCard = sgs.CreateSkillCard {
    name = 'LuaXiongmu',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        local ids = sgs.IntList()
        for _, cid in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cid)
            ids:append(cid)
        end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), self:objectName(), '')
        local moves = sgs.CardsMoveList()
        local move = sgs.CardsMoveStruct(ids, source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, reason)
        moves:append(move)
        local tmpList = sgs.SPlayerList()
        tmpList:append(source)
        room:notifyMoveCards(true, moves, false, tmpList)
        local drawPile = room:getDrawPile()
        local len = drawPile:length()

        for _, id in sgs.qlist(move.card_ids) do
            local card = sgs.Sanguosha:getCard(id)
            source:removeCard(card, sgs.Player_PlaceHand)
            rinsan.insertQList(drawPile, rinsan.random(0, len - 1), id)
            room:setCardMapping(id, nil, sgs.Player_DrawPile)
        end
        room:notifyMoveCards(false, moves, false, tmpList)

        local times = ids:length()
        local checker = function(_card)
            return _card:getNumber() == 8
        end
        local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, source:objectName(), self:objectName(), '')
        local dummy = rinsan.obtainSpecifiedCards(room, checker, times, true)
        room:obtainCard(source, dummy, reason2, false)
    end,
}

LuaXiongmuVS = sgs.CreateViewAsSkill {
    name = 'LuaXiongmu',
    n = 9999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local cd = LuaXiongmuCard:clone()
        for _, card in ipairs(cards) do
            cd:addSubcard(card)
        end
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaXiongmu'
    end,
}

LuaXiongmu = sgs.CreateTriggerSkill {
    name = 'LuaXiongmu',
    events = {sgs.DamageInflicted, sgs.RoundStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = LuaXiongmuVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.RoundStart then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local x = player:getMaxHp() - player:getHandcardNum()
                if x > 0 then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(x, self:objectName())
                end
                room:askForUseCard(player, '@@LuaXiongmu', '@LuaXiongmu')
            end
            return false
        end
        if player:getMark(self:objectName() .. '-Clear') > 0 then
            return false
        end
        if player:getHandcardNum() > player:getHp() then
            return false
        end
        room:broadcastSkillInvoke(self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:addPlayerMark(player, self:objectName() .. '-Clear')
        local damage = data:toDamage()
        damage.damage = damage.damage - 1
        if damage.damage <= 0 then
            return true
        end
        data:setValue(damage)
        return false
    end,
}

local function getXiongmuMark(card_id)
    return 'LuaXiongmu_' .. card_id .. '_lun'
end

LuaXiongmuDiscard = sgs.CreateTriggerSkill {
    name = 'LuaXiongmuDiscardLimit',
    events = {sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard, sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.reason and move.reason.m_skillName == 'LuaXiongmu' then
                if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and
                    not move.card_ids:isEmpty() then
                    player:speak(move.reason.m_skillName)
                    for _, id in sgs.qlist(move.card_ids) do
                        room:addPlayerMark(player, getXiongmuMark(id))
                    end
                end
            end
            return false
        end
        if event == sgs.AskForGameruleDiscard then
            room:sendCompulsoryTriggerLog(player, 'LuaXiongmu')
        end
        local n = room:getTag('DiscardNum'):toInt()
        for _, id in sgs.qlist(player:handCards()) do
            if player:getMark(getXiongmuMark(id)) > 0 then
                if event == sgs.AskForGameruleDiscard then
                    n = n - 1
                    room:setPlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString(), false)
                else
                    room:removePlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString() .. '$0')
                end
            end
        end
        room:setTag('DiscardNum', sgs.QVariant(n))
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaXiongmu')
    end,
}

LuaXiongmuMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaXiongmuMaxCards',
    extra_func = function(self, target)
        local x = 0
        for _, cd in sgs.qlist(target:getHandcards()) do
            if target:getMark(getXiongmuMark(cd:getEffectiveId())) > 0 then
                x = x + 1
            end
        end
        -- 迫真多余牌修正
        return target:getHandcardNum() > target:getHp() and 0 or x
    end,
}

local function getZhangcaiNumber(wuluxun, card)
    if wuluxun:getMark('@LuaRuxian-Invoked') > 0 then
        return card:getNumber()
    end
    return 8
end

LuaZhangcai = sgs.CreateTriggerSkill {
    name = 'LuaZhangcai',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if not card or card:isKindOf('SkillCard') then
            return false
        end
        local number = getZhangcaiNumber(player, card)
        if card:getNumber() == number then
            local count = 0
            for _, cd in sgs.qlist(player:getHandcards()) do
                if cd:getNumber() == number then
                    count = count + 1
                end
            end
            count = math.max(1, count)
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(count, self:objectName())
            end
        end
        return false
    end,
}

LuaRuxianCard = sgs.CreateSkillCard {
    name = 'LuaRuxian',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        source:loseMark('@' .. self:objectName())
        source:gainMark('@' .. self:objectName() .. '-Invoked')
    end,
}

LuaRuxianVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaRuxian',
    view_as = function(self)
        return LuaRuxianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@' .. self:objectName()) > 0
    end,
}

LuaRuxian = sgs.CreateTriggerSkill {
    name = 'LuaRuxian',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaRuxian',
    view_as_skill = LuaRuxianVS,
    on_trigger = function(self, event, player, data, room)
        local mark = '@' .. self:objectName() .. '-Invoked'
        player:loseMark(mark, player:getMark(mark))
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_RoundStart)
    end,
}

WuLuxun:addSkill(LuaXiongmu)
WuLuxun:addSkill(LuaZhangcai)
WuLuxun:addSkill(LuaRuxian)
table.insert(hiddenSkills, LuaXiongmuDiscard)
table.insert(hiddenSkills, LuaXiongmuMaxCards)

rinsan.addHiddenSkills(hiddenSkills)
