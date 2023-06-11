-- OL-界限突破-标准包
-- Created by DZDcyj at 2023/5/5
module('extensions.OLBoundaryBreachStandardPackage', package.seeall)
extension = sgs.Package('OLBoundaryBreachStandardPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 界华雄
OLJieHuaxiong = sgs.General(extension, 'OLJieHuaxiong', 'qun', '6', true, true)

LuaOLYaowu = sgs.CreateTriggerSkill {
    name = 'LuaOLYaowu',
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(damage.to, self:objectName())
            if damage.card:isRed() then
                if damage.from and damage.from:isAlive() then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, damage.to:objectName(), damage.from:objectName())
                    damage.from:drawCards(1, self:objectName())
                end
            else
                damage.to:drawCards(1, self:objectName())
            end
        end
        return false
    end,
}

LuaOLShizhanCard = sgs.CreateSkillCard {
    name = 'LuaOLShizhanCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) then
            local targets_list = sgs.PlayerList()
            for _, target in ipairs(selected) do
                targets_list:append(target)
            end
            local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_NoSuit, 0)
            duel:setSkillName('_LuaOLShizhan')
            duel:deleteLater()
            -- 特殊处理李丰
            if to_select:hasSkill('tunchu') and (not to_select:getPile('food'):isEmpty()) then
                return false
            end
            if to_select:isCardLimited(duel, sgs.Card_MethodUse) then
                return false
            end
            if duel:targetFilter(targets_list, sgs.Self, to_select) then
                return not to_select:isProhibited(sgs.Self, duel)
            end
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaOLShizhan')
        local target = targets[1]
        local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_NoSuit, 0)
        duel:setSkillName('_LuaOLShizhan')
        room:useCard(sgs.CardUseStruct(duel, target, source))
    end,
}

LuaOLShizhan = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaOLShizhan',
    view_as = function(self, cards)
        return LuaOLShizhanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#LuaOLShizhanCard') < 2
    end,
}

OLJieHuaxiong:addSkill(LuaOLYaowu)
OLJieHuaxiong:addSkill(LuaOLShizhan)

-- 界赵云
OLJieZhaoyun = sgs.General(extension, 'OLJieZhaoyun', 'shu', '4', true, true)

LuaOLLongdan = sgs.CreateOneCardViewAsSkill {
    name = 'LuaOLLongdan',
    response_or_use = true,
    view_filter = function(self, card)
        local usereason = sgs.Sanguosha:getCurrentCardUseReason()
        if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if card:isKindOf('Jink') then
                return sgs.Slash_IsAvailable(sgs.Self)
            elseif card:isKindOf('Peach') then
                return sgs.Analeptic_IsAvailable(sgs.Self)
            elseif card:isKindOf('Analeptic') then
                return sgs.Self:isWounded()
            end
            return false
        elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or
            (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == 'slash' then
                return card:isKindOf('Jink')
            elseif pattern == 'jink' then
                return card:isKindOf('Slash')
            elseif pattern == 'peach' then
                return card:isKindOf('Analeptic')
            elseif pattern == 'analeptic' then
                return card:isKindOf('Peach')
            elseif string.find(pattern, 'peach') or string.find(pattern, 'analeptic') then
                return card:isKindOf('Peach') or card:isKindOf('Analeptic')
            end
        end
        return false
    end,
    view_as = function(self, card)
        if card:isKindOf('Slash') then
            local jink = sgs.Sanguosha:cloneCard('jink', card:getSuit(), card:getNumber())
            jink:addSubcard(card)
            jink:setSkillName(self:objectName())
            return jink
        elseif card:isKindOf('Jink') then
            local slash = sgs.Sanguosha:cloneCard('slash', card:getSuit(), card:getNumber())
            slash:addSubcard(card)
            slash:setSkillName(self:objectName())
            return slash
        elseif card:isKindOf('Peach') then
            local analeptic = sgs.Sanguosha:cloneCard('analeptic', card:getSuit(), card:getNumber())
            analeptic:addSubcard(card)
            analeptic:setSkillName(self:objectName())
            return analeptic
        elseif card:isKindOf('Analeptic') then
            local peach = sgs.Sanguosha:cloneCard('peach', card:getSuit(), card:getNumber())
            peach:addSubcard(card)
            peach:setSkillName(self:objectName())
            return peach
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player) or player:isWounded()
    end,
    enabled_at_response = function(self, player, pattern)
        if pattern == 'peach+analeptic' then
            return true
        end
        return pattern == 'slash' or pattern == 'jink' or pattern == 'peach' or pattern == 'analeptic'
    end,
}

LuaOLYajiao = sgs.CreateTriggerSkill {
    name = 'LuaOLYajiao',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local card, isHandcard
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
            isHandcard = use.m_isHandcard
        else
            local resp = data:toCardResponse()
            card = resp.m_card
            isHandcard = resp.m_isHandcard
        end
        if isHandcard and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            local ids = room:getNCards(1, false)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
                self:objectName(), '')
            local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, reason)
            room:moveCardsAtomic(move, true)
            local id = ids:first()
            local topCard = sgs.Sanguosha:getCard(id)
            room:fillAG(ids, player)
            local dealt = false
            if topCard:getTypeId() == card:getTypeId() then
                local cardSuitString = string.format('%s_char', topCard:getSuitString())
                local prompt = string.format('%s-give:::%s:%s\\%s', self:objectName(), topCard:objectName(),
                    cardSuitString, topCard:getNumberString())
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), prompt)
                if target then
                    room:clearAG(player)
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
                    dealt = true
                    local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, target:objectName(),
                        self:objectName(), '')
                    room:obtainCard(target, topCard, reason2)
                end
            else
                local available_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:inMyAttackRange(player) and rinsan.canDiscard(player, p, 'hej') then
                        available_targets:append(p)
                    end
                end
                if available_targets:isEmpty() then
                    room:clearAG(player)
                    return false
                end
                local prompt = string.format('%s-discard', self:objectName())
                local target = room:askForPlayerChosen(player, available_targets, self:objectName(), prompt, true)
                if target then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
                    room:clearAG(player)
                    room:throwCard(room:askForCardChosen(player, target, 'hej', self:objectName(), false,
                        sgs.Card_MethodDiscard), target, player)
                end
            end
            if not dealt then
                room:returnToTopDrawPile(ids)
            end
            room:clearAG(player)
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_NotActive)
    end,
}

OLJieZhaoyun:addSkill(LuaOLLongdan)
OLJieZhaoyun:addSkill(LuaOLYajiao)

-- 界李典
OLJieLidian = sgs.General(extension, 'OLJieLidian', 'wei', '3', true, true)

LuaOLWangxi = sgs.CreateTriggerSkill {
    name = 'LuaOLWangxi',
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local target
        if event == sgs.Damage and damage.to and (not damage.to:hasFlag('Global_DebutFlag')) then
            target = damage.to
        elseif event == sgs.Damaged then
            target = damage.from
        end
        if (not target) or (target:objectName() == player:objectName()) then
            return false
        end
        if (not target:isAlive()) or (not player:isAlive()) then
            return false
        end
        for _ = 1, damage.damage, 1 do
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(2, self:objectName())
                local prompt = string.format('LuaOLWangxi-Give:%s', target:objectName())
                if (not player:isAlive()) or (not target:isAlive()) then
                    return false
                end
                local give = room:askForExchange(player, self:objectName(), 1, 1, true, prompt, false)
                if give then
                    room:moveCardTo(give, target, sgs.Player_PlaceHand, false)
                end
            else
                break
            end
        end
    end,
}

OLJieLidian:addSkill('ol_xunxun')
OLJieLidian:addSkill(LuaOLWangxi)
