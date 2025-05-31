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

-- 武陆逊
WuLuxun = sgs.General(extension, 'WuLuxun', 'wu', 3, true, true, false)

LuaXiongmuCard = sgs.CreateSkillCard {
    name = 'LuaXiongmu',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        local ids = sgs.IntList()
        local equip_ids = sgs.IntList()
        for _, cid in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cid)
            if room:getCardPlace(cid) == sgs.Player_PlaceEquip then
                equip_ids:append(cid)
            else
                ids:append(cid)
            end
        end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), self:objectName(), '')
        local moves = sgs.CardsMoveList()
        local move = sgs.CardsMoveStruct(ids, source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, reason)
        local equip_move = sgs.CardsMoveStruct(equip_ids, source, nil, sgs.Player_PlaceEquip, sgs.Player_DrawPile, reason)
        if not ids:isEmpty() then
            moves:append(move)
        end
        if not equip_ids:isEmpty() then
            moves:append(equip_move)
        end
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

        for _, id in sgs.qlist(equip_move.card_ids) do
            local card = sgs.Sanguosha:getCard(id)
            source:removeCard(card, sgs.Player_PlaceEquip)
            rinsan.insertQList(drawPile, rinsan.random(0, len - 1), id)
            room:setCardMapping(id, nil, sgs.Player_DrawPile)
        end

        room:notifyMoveCards(false, moves, false, tmpList)

        local times = ids:length() + equip_ids:length()
        local checker = function(cd)
            return cd:getNumber() == 8
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
        room:notifySkillInvoked(source, self:objectName())
        source:loseMark('@' .. self:objectName())
        room:addPlayerMark(source, '@' .. self:objectName() .. '-Invoked')
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

-- 武诸葛亮
WuZhugeliang = sgs.General(extension, 'WuZhugeliang', 'shu', 7, true, true, false, 4)

LuaJincui = sgs.CreateTriggerSkill {
    name = 'LuaJincui',
    events = {sgs.AfterDrawInitialCards, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AfterDrawInitialCards then
            local curr = player:getHandcardNum()
            if curr < 7 then
                local x = 7 - curr
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(x, self:objectName())
            end
            return false
        end
        if player:getPhase() == sgs.Player_Start then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local seven_count = 0
            for _, cid in sgs.qlist(room:getDrawPile()) do
                local cd = sgs.Sanguosha:getCard(cid)
                if cd:getNumber() == 7 then
                    seven_count = seven_count + 1
                end
            end
            seven_count = math.max(1, seven_count)
            local diff = math.abs(seven_count - player:getHp())
            if seven_count > player:getHp() then
                rinsan.recover(player, diff)
            elseif seven_count < player:getHp() then
                room:loseHp(player, diff)
            end
            local cards = room:getNCards(player:getHp())
            room:askForGuanxing(player, cards)
        end
        return false
    end,
}

LuaQingshiCard = sgs.CreateSkillCard {
    name = 'LuaQingshi',
    target_fixed = false,
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName()
    end,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        for _, target in ipairs(targets) do
            target:drawCards(1, self:objectName())
        end
    end,
}

LuaQingshiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaQingshi',
    view_as = function(self)
        return LuaQingshiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaQingshi'
    end,
}

LuaQingshi = sgs.CreateTriggerSkill {
    name = 'LuaQingshi',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    view_as_skill = LuaQingshiVS,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('LuaQingshi-Drawed-Clear') > 0 then
            return false
        end
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            if not data:toCardResponse().m_isUse then
                return false
            end
            card = data:toCardResponse().m_card
        end
        if not card or card:isKindOf('SkillCard') then
            return false
        end
        local mark = string.format('%s-%s-Clear', self:objectName(), card:objectName())
        if player:getMark(mark) > 0 then
            return false
        end
        local can_invoke = false
        local cd_name = card:objectName()
        local cd_id = card:getId()
        for _, cd in sgs.qlist(player:getHandcards()) do
            if cd:objectName() == cd_name and cd:getId() ~= cd_id then
                can_invoke = true
                break
            end
        end
        if not can_invoke then
            return false
        end
        local choices = {'LuaQingshi-Damage', 'LuaQingshi-OtherDraw', 'LuaQingshi-Draw', 'cancel'}
        if event ~= sgs.CardUsed then
            table.removeAll(choices, 'LuaQingshi-Damage')
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
        if choice == 'cancel' then
            return false
        end
        if choice == 'LuaQingshi-Draw' then
            player:drawCards(3, self:objectName())
            room:addPlayerMark(player, 'LuaQingshi-Drawed-Clear')
        elseif choice == 'LuaQingshi-Damage' then
            local use = data:toCardUse()
            local splayers = sgs.SPlayerList()
            for _, p in sgs.qlist(use.to) do
                splayers:append(p)
            end
            local target = room:askForPlayerChosen(player, splayers, self:objectName(), '@LuaQingshi-Damage', true, true)
            if not target then
                return false
            end
            local damageMark = string.format('%s-%s-Damage-Clear', self:objectName(), use.card:toString())
            room:addPlayerMark(target, damageMark)
        elseif choice == 'LuaQingshi-OtherDraw' then
            room:askForUseCard(player, '@@LuaQingshi', '@LuaQingshi-OtherDraw')
        end
        room:addPlayerMark(player, mark)
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaQingshiDamage = sgs.CreateTriggerSkill {
    name = 'LuaQingshiDamage',
    events = {sgs.DamageCaused},
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if not damage.card then
            return false
        end
        local damageMark = string.format('%s-%s-Damage-Clear', 'LuaQingshi', damage.card:toString())
        if damage.to:getMark(damageMark) > 0 then
            room:sendCompulsoryTriggerLog(player, 'LuaQingshi')
            damage.damage = damage.damage + 1
            data:setValue(damage)
            room:removePlayerMark(damage.to, 'LuaQingshi-Damage-Clear')
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaZhizheCard = sgs.CreateSkillCard {
    name = 'LuaZhizhe',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        source:loseMark('@LuaZhizhe')
        local zhizheCard = self:getSubcards():first()
        room:showCard(source, zhizheCard)
        room:addPlayerMark(source, 'LuaZhizhe-' .. zhizheCard)
    end,
}

LuaZhizheVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaZhizhe',
    filter_pattern = '.|.|.|hand',
    view_as = function(self, card)
        local cd = LuaZhizheCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaZhizhe') > 0
    end,
}

LuaZhizhe = sgs.CreateTriggerSkill {
    name = 'LuaZhizhe',
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaZhizhe',
    view_as_skill = LuaZhizheVS,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        local isUse = rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_USE)
        local isResponse = rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_RESPONSE)
        if not (isUse or isResponse) then
            return false
        end
        if move.to_place == sgs.Player_DiscardPile then
            for _, id in sgs.qlist(move.card_ids) do
                if player:getMark('LuaZhizhe-' .. id) > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    player:obtainCard(sgs.Sanguosha:getCard(id), false)
                    room:setPlayerCardLimitation(player, 'use,response', sgs.Sanguosha:getCard(id):toString(), true)
                end
            end
        end
    end,
}

WuZhugeliang:addSkill(LuaJincui)
WuZhugeliang:addSkill(LuaQingshi)
WuZhugeliang:addSkill(LuaZhizhe)

table.insert(hiddenSkills, LuaQingshiDamage)

rinsan.addHiddenSkills(hiddenSkills)
