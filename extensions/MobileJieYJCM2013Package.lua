-- 手杀-界一将成名 2013 包
-- Created by DZDcyj at 2023/9/30
module('extensions.MobileJieYJCM2013Package', package.seeall)
extension = sgs.Package('MobileJieYJCM2013Package')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 界朱然
JieZhuran = sgs.General(extension, 'JieZhuran', 'wu', '4', true)

LuaDanshou = sgs.CreateTriggerSkill {
    name = 'LuaDanshou',
    events = {sgs.TargetSpecified, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf('SkillCard') then
                return false
            end
            if use.from:objectName() ~= room:getCurrent():objectName() then
                return false
            end
            for _, p in sgs.qlist(use.to) do
                room:addPlayerMark(p, self:objectName())
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if sp:objectName() ~= player:objectName() then
                        local num = sp:getMark(self:objectName())
                        if num == 0 then
                            if room:askForSkillInvoke(sp, self:objectName()) then
                                room:broadcastSkillInvoke(self:objectName())
                                sp:drawCards(1, self:objectName())
                            end
                        else
                            if room:askForDiscard(sp, 'LuaDanshou', num, num, true, true, '@LuaDanshou:::' .. num) then
                                rinsan.skill(self, room, sp, true)
                                room:doAnimate(rinsan.ANIMATE_INDICATE, sp:objectName(), player:objectName())
                                rinsan.doDamage(sp, player, 1)
                            end
                        end
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName(), 0)
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

JieZhuran:addSkill(LuaDanshou)

-- 界李儒
JieLiru = sgs.General(extension, 'JieLiru', 'qun', '3', true)

LuaJuece = sgs.CreateTriggerSkill {
    name = 'LuaJuece',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == room:getCurrent():objectName() then
                return false
            end
            if rinsan.lostCard(move, player) then
                room:addPlayerMark(player, self:objectName())
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                if player:hasSkill(self:objectName()) then
                    local victims = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark(self:objectName()) > 0 then
                            victims:append(p)
                        end
                    end
                    if victims:isEmpty() then
                        return false
                    end
                    local victim = room:askForPlayerChosen(player, victims, self:objectName(), '@LuaJueceDamageTo',
                        true, true)
                    if victim then
                        room:broadcastSkillInvoke(self:objectName())
                        room:damage(sgs.DamageStruct(self:objectName(), player, victim))
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName(), 0)
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaMiejiCard = sgs.CreateSkillCard {
    name = 'LuaMiejiCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) then
            return rinsan.canDiscard(to_select, to_select, 'he')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:notifySkillInvoked(source, 'LuaMieji')
        room:broadcastSkillInvoke('LuaMieji')
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), '', 'LuaMieji', '')
        local miejiCard = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:moveCardTo(miejiCard, source, nil, sgs.Player_DrawPile, reason, true)
        local cards = target:getCards('he')
        local cardsCopy = cards

        for _, c in sgs.qlist(cardsCopy) do
            if target:isCardLimited(c, sgs.Card_MethodDiscard) then
                cards:removeOne(c)
            end
        end

        if cards:isEmpty() then
            return
        end

        local pattern = '..!'
        local nonTrickNum = 0
        for _, c in sgs.qlist(cards) do
            if not c:isKindOf('TrickCard') then
                nonTrickNum = nonTrickNum + 1
            end
        end

        local card = room:askForCard(target, pattern, '@LuaMiejiDiscard', sgs.QVariant(), sgs.Card_MethodNone)
        if not card then
            card = cards:at(rinsan.random(0, cardsCopy:length() - 1))
        end
        if not card then
            return false
        end
        if card:isKindOf('TrickCard') then
            room:obtainCard(source, card)
        else
            room:throwCard(card, target)
            if nonTrickNum <= 1 then
                return false
            end
            pattern = '^TrickCard!'
            local maybeCards = {}
            for _, c in sgs.qlist(target:getCards('he')) do
                if not target:isCardLimited(c, sgs.Card_MethodDiscard) and not c:isKindOf('TrickCard') then
                    table.insert(maybeCards, c)
                end
            end
            if #maybeCards <= 0 then
                return false
            end
            card = room:askForCard(target, pattern, '@LuaMiejiDiscardNonTrick', sgs.QVariant(), sgs.Card_MethodNone)
            if not card or card:isKindOf('TrickCard') then
                card = maybeCards[rinsan.random(1, #maybeCards)]
            end
            if card then
                room:throwCard(card, target)
            end
        end
    end,
}

LuaMieji = sgs.CreateOneCardViewAsSkill {
    name = 'LuaMieji',
    filter_pattern = 'TrickCard|black',
    view_as = function(self, card)
        local miejiCard = LuaMiejiCard:clone()
        miejiCard:addSubcard(card)
        return miejiCard
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMiejiCard')
    end,
}

LuaFenchengCard = sgs.CreateSkillCard {
    name = 'LuaFenchengCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        source:loseMark('@burn')
        room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
        room:broadcastSkillInvoke('LuaFencheng')
        room:notifySkillInvoked(source, 'LuaFencheng')
        room:setEmotion(source, 'skill/fencheng')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), p:objectName())
        end
        room:getThread():delay(4000)
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                local length = room:getTag('LuaFenchengDiscard'):toInt() + 1
                if not rinsan.canDiscard(p, p, 'he') or p:getCardCount(true) < length or
                    not room:askForDiscard(p, 'fencheng', 10000, length, true, true, '@fencheng:::' .. length) then
                    room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
                    rinsan.doDamage(source, p, 2, sgs.DamageStruct_Fire)
                end
            end
        end
    end,
}

LuaFenchengVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaFencheng',
    view_as = function(self, cards)
        return LuaFenchengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@burn') > 0
    end,
}

LuaFencheng = sgs.CreateTriggerSkill {
    name = 'LuaFencheng',
    frequency = sgs.Skill_Limited,
    limit_mark = '@burn',
    view_as_skill = LuaFenchengVS,
    events = {sgs.ChoiceMade},
    on_trigger = function(self, event, player, data, room)
        local dataStr = data:toString():split(':')
        if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~= 'fencheng' then
            return false
        end
        room:setTag('LuaFenchengDiscard', sgs.QVariant(#dataStr[3]:split('+')))
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

JieLiru:addSkill(LuaJuece)
JieLiru:addSkill(LuaMieji)
JieLiru:addSkill(LuaFencheng)

-- 界满宠
JieManchong = sgs.General(extension, 'JieManchong', 'wei', '3', true)

LuaJunxingCard = sgs.CreateSkillCard {
    name = 'LuaJunxing',
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local target = targets[1]
        local len = self:subcardsLength()
        if room:askForDiscard(target, self:objectName(), len, len, true, true, '@LuaJunxing:::' .. len) then
            room:loseHp(target)
        else
            target:turnOver()
            target:drawCards(len, self:objectName())
        end
    end,
}

LuaJunxing = sgs.CreateViewAsSkill {
    name = 'LuaJunxing',
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards >= 1 then
            local vs_card = LuaJunxingCard:clone()
            for _, cd in ipairs(cards) do
                vs_card:addSubcard(cd)
            end
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaJunxing') and not player:isKongcheng()
    end,
}

LuaYuce = sgs.CreateTriggerSkill {
    name = 'LuaYuce',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:isKongcheng() then
            return false
        end
        local card = room:askForCard(player, '.', '@LuaYuce-show', data, sgs.Card_MethodNone)
        if card then
            rinsan.skill(self, room, player, true)
            room:showCard(player, card:getEffectiveId())
            if damage.from == nil or damage.from:isDead() then
                return false
            end
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
            local typeName = {'BasicCard', 'TrickCard', 'EquipCard'}
            local toRemove = rinsan.firstToUpper(rinsan.replaceUnderline(card:getType())) .. 'Card'
            table.removeOne(typeName, toRemove)
            if not rinsan.canDiscard(damage.from, damage.from, 'h') or
                not room:askForCard(damage.from, table.concat(typeName, ',') .. '|.|.|hand', '@yuce-discard:' ..
                    player:objectName() .. '::' .. typeName[1] .. ':' .. typeName[2], data) then
                room:getThread():delay(1500)
                rinsan.recover(player, 1, player)
            end
        end
        return false
    end,
}

JieManchong:addSkill(LuaJunxing)
JieManchong:addSkill(LuaYuce)
