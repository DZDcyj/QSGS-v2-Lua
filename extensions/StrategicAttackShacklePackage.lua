-- 谋攻篇-虞包
-- Created by DZDcyj at 2023/2/19
module('extensions.StrategicAttackShacklePackage', package.seeall)
extension = sgs.Package('StrategicAttackShacklePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

local function globalTrigger(self, target)
    return true
end

local function targetTrigger(self, target)
    return target
end

-- 谋于禁
ExMouYujin = sgs.General(extension, 'ExMouYujin', 'wei', '4', true, true)

LuaMouXiayuan = sgs.CreateTriggerSkill {
    name = 'LuaMouXiayuan',
    events = {sgs.Damaged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local invoke = rinsan.canInvokeXiayuan(player)
        if invoke then
            room:setPlayerFlag(player, '-ShieldAllLost')
            local lostCount = player:getTag('ShieldLostCount'):toInt()
            for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if sp:objectName() ~= player:objectName() and
                    sp:getMark(string.format('%s%s', self:objectName(), sp:objectName())) == 0 and
                    room:askForDiscard(sp, self:objectName(), 2, 2, true, false,
                        string.format('LuaMouXiayuan-Discard:%s::%s', player:objectName(), lostCount)) then
                    rinsan.skill(self, room, sp, true)
                    rinsan.increaseShield(player, lostCount)
                    room:addPlayerMark(sp, string.format('%s%s', self:objectName(), sp:objectName()))
                    break
                end
            end
        end
        return false
    end,
    can_trigger = globalTrigger
}

LuaMouXiayuanClear = sgs.CreateTriggerSkill {
    name = 'LuaMouXiayuanClear',
    events = {sgs.TurnStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerMark(player, string.format('%s%s', 'LuaMouXiayuan', player:objectName()), 0)
    end,
    can_trigger = globalTrigger
}

LuaMouJieyue = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyue',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if rinsan.canIncreaseShield(p) then
                targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, targets, self:objectName(), 'LuaMouJieyue-choose', true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            rinsan.increaseShield(target, 1)
            target:drawCards(2, self:objectName())
            local card = room:askForExchange(target, self:objectName(), 2, 2, true,
                string.format('LuaMouJieyue-Give:%s', player:objectName()), false)
            if card then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(),
                    player:objectName(), self:objectName(), nil)
                room:moveCardTo(card, target, player, sgs.Player_PlaceHand, reason, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Finish)
    end
}

ExMouYujin:addSkill(LuaMouXiayuan)
ExMouYujin:addSkill(LuaMouJieyue)
SkillAnjiang:addSkill(LuaMouXiayuanClear)

-- 谋吕蒙
ExMouLvmeng = sgs.General(extension, 'ExMouLvmeng', 'wu', '4', true, true)

-- 克己

-- 写成两张卡，方便多个出牌阶段

-- 失去体力
LuaMouKejiLoseHpCard = sgs.CreateSkillCard {
    name = 'LuaMouKejiLoseHpCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaMouKeji')
        room:notifySkillInvoked(source, 'LuaMouKeji')
        room:loseHp(source)
        rinsan.increaseShield(source, 2)
    end
}

-- 弃牌
LuaMouKejiDiscardCard = sgs.CreateSkillCard {
    name = 'LuaMouKejiDiscardCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaMouKeji')
        room:notifySkillInvoked(source, 'LuaMouKeji')
        rinsan.increaseShield(source, 1)
    end
}

LuaMouKeji = sgs.CreateViewAsSkill {
    name = 'LuaMouKeji',
    n = 1,
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasUsed('#LuaMouKejiDiscardCard') then
            return false
        end
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 1 and rinsan.canInvokeKeji(sgs.Self, 'LuaMouKejiDiscardCard') then
            local vs_card = LuaMouKejiDiscardCard:clone()
            vs_card:addSubcard(cards[1])
            return vs_card
        end
        if rinsan.canInvokeKeji(sgs.Self, 'LuaMouKejiLoseHpCard') then
            return LuaMouKejiLoseHpCard:clone()
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return rinsan.canInvokeKeji(player)
    end
}

LuaMouKejiMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaMouKejiMaxCards',
    extra_func = function(self, target)
        if target:hasSkill('LuaMouKeji') then
            return rinsan.getShieldCount(target)
        else
            return 0
        end
    end
}

LuaMoukejiProhibit = sgs.CreateProhibitSkill {
    name = 'LuaMoukejiProhibit',
    is_prohibited = function(self, from, to, card)
        if from:hasSkill('LuaMouKeji') and card:isKindOf('Peach') then
            return from:objectName() ~= to:objectName() or to:getHp() > 0
        end
        return false
    end
}

LuaMouDujiang = sgs.CreateTriggerSkill {
    name = 'LuaMouDujiang',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        rinsan.sendLogMessage(room, '#LuaMouDujiang', {
            ['from'] = player,
            ['arg'] = rinsan.getShieldCount(player),
            ['arg2'] = self:objectName()
        })
        if room:changeMaxHpForAwakenSkill(player, 0) then
            room:broadcastSkillInvoke(self:objectName())
            room:notifySkillInvoked(player, self:objectName())
            room:addPlayerMark(player, self:objectName())
            rinsan.modifySkillDescription(':LuaMouKeji', ':LuaMouKejiAwake')
            ChangeCheck(player, player:getGeneralName())
            room:acquireSkill(player, 'LuaMouDuojing')
        end
    end,
    can_trigger = function(self, target)
        if rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_RoundStart) then
            return rinsan.getShieldCount(target) >= 3
        end
        return false
    end
}

LuaMouDuojing = sgs.CreateTriggerSkill {
    name = 'LuaMouDuojing',
    events = {sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (not use.card) or (not use.card:isKindOf('Slash')) then
            return false
        end
        for _, p in sgs.qlist(use.to) do
            if rinsan.getShieldCount(player) <= 0 then
                return false
            end
            local data2 = sgs.QVariant()
            data2:setValue(p)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                rinsan.decreaseShield(player, 1)
                rinsan.addQinggangTag(p, use.card)
                room:broadcastSkillInvoke(self:objectName())
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), p:objectName())
                room:addPlayerMark(player, self:objectName())
                if not p:isNude() then
                    local card_id =
                        room:askForCardChosen(player, p, 'he', self:objectName(), false, sgs.Card_MethodNone)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                    room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                end
            end
        end
    end
}

LuaMouDuojingClear = sgs.CreateTriggerSkill {
    name = 'LuaMouDuojingClear',
    events = {sgs.EventPhaseEnd},
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            rinsan.clearAllMarksContains(room, p, 'LuaMouDuojing')
        end
    end,
    can_trigger = globalTrigger
}

LuaMouDuojingTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaMouDuojingTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:hasSkill('LuaMouDuojing') then
            return player:getMark('LuaMouDuojing')
        else
            return 0
        end
    end
}

ExMouLvmeng:addSkill(LuaMouKeji)
ExMouLvmeng:addSkill(LuaMouDujiang)
ExMouLvmeng:addRelateSkill('LuaMouDuojing')
SkillAnjiang:addSkill(LuaMouKejiMaxCards)
SkillAnjiang:addSkill(LuaMoukejiProhibit)
SkillAnjiang:addSkill(LuaMouDuojingTargetMod)
SkillAnjiang:addSkill(LuaMouDuojing)
SkillAnjiang:addSkill(LuaMouDuojingClear)

-- 谋曹仁
ExMouCaoren = sgs.General(extension, 'ExMouCaoren', 'wei', '4', true, true)

LuaMouJushouCard = sgs.CreateSkillCard {
    name = 'LuaMouJushou',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        source:turnOver()
        room:askForDiscard(source, self:objectName(), 2, 1, true, true, 'LuaMouJushouDiscard')
    end
}

LuaMouJushouVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouJushou',
    view_as = function(self)
        return LuaMouJushouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMouJushou') and player:faceUp()
    end
}

LuaMouJushou = sgs.CreateTriggerSkill {
    name = 'LuaMouJushou',
    events = {sgs.Damaged, sgs.ChoiceMade, sgs.TurnedOver},
    view_as_skill = LuaMouJushouVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            if not player:faceUp() then
                local choices = {}
                if rinsan.getShieldCount(player) < rinsan.MAX_SHIELD_COUNT then
                    table.insert(choices, 'GainShield')
                end
                table.insert(choices, 'TurnOver')
                table.insert(choices, 'cancel')
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                if choice == 'GainShield' then
                    rinsan.skill(self, room, player, true)
                    rinsan.increaseShield(player, 1)
                elseif choice == 'TurnOver' then
                    rinsan.skill(self, room, player, true)
                    player:turnOver()
                end
            end
        elseif event == sgs.TurnedOver then
            if player:faceUp() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local count = rinsan.getShieldCount(player)
                player:drawCards(count, self:objectName())
            end
        else
            local dataStr = data:toString():split(':')
            if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~= self:objectName() then
                return false
            end
            rinsan.increaseShield(player, #dataStr[3]:split('+'))
            return false
        end
    end
}

LuaMouJieweiCard = sgs.CreateSkillCard {
    name = 'LuaMouJiewei',
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0) and (not to_select:isKongcheng())
    end,
    on_use = function(self, room, source, targets)
        rinsan.decreaseShield(source, 1)
        local target = targets[1]
        if target:getHandcardNum() > 0 then
            local cards = sgs.IntList()
            local cards_table = {}
            for _, cd in sgs.qlist(target:getHandcards()) do
                cards:append(cd:getEffectiveId())
                table.insert(cards_table, cd:getEffectiveId())
            end
            local cardString = table.concat(cards_table, '+')
            rinsan.sendLogMessage(room, '$ViewAllCards', {
                ['from'] = source,
                ['to'] = target,
                ['card_str'] = cardString
            })
            room:fillAG(cards, source)
            local id = room:askForAG(source, cards, false, self:objectName())
            if id ~= -1 then
                room:obtainCard(source, id)
            end
            room:clearAG(source)
        end
    end
}

LuaMouJiewei = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouJiewei',
    view_as = function(self)
        return LuaMouJieweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMouJiewei') and rinsan.getShieldCount(player) > 0
    end
}

ExMouCaoren:addSkill(LuaMouJushou)
ExMouCaoren:addSkill(LuaMouJiewei)

-- 谋甘宁
ExMouGanning = sgs.General(extension, 'ExMouGanning', 'wu', '4', true, true)

LuaQixi = sgs.CreateOneCardViewAsSkill {
    name = 'LuaQixi',
    filter_pattern = '.|black',
    view_as = function(self, card)
        local acard = sgs.Sanguosha:cloneCard('dismantlement', card:getSuit(), card:getNumber())
        acard:addSubcard(card)
        acard:setSkillName(self:objectName())
        return acard
    end
}

LuaQixiTrigger = sgs.CreateTriggerSkill {
    name = 'LuaQixiTrigger',
    events = {sgs.TrickEffect},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        local card = effect.card
        -- 替代的【过河拆桥】判断
        if (card:isKindOf('Dismantlement') or card:objectName() == 'dismantlement') and (not card:isVirtualCard()) then
            if not effect.from:hasSkill('LuaQixi') then
                return false
            end
            if (room:askForSkillInvoke(effect.from, 'LuaQixi', data)) then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
                for _, cd in sgs.qlist(effect.to:getCards('hej')) do
                    if (rinsan.canDiscardCard(effect.from, effect.to, cd:getId())) then
                        dummy:addSubcard(cd)
                    end
                end
                if dummy:subcardsLength() > 0 then
                    room:throwCard(dummy, effect.to, effect.from)
                end
                room:broadcastSkillInvoke('LuaQixi')
                return true
            end
        end
        return false
    end,
    can_trigger = targetTrigger
}

LuaFenweiCard = sgs.CreateSkillCard {
    name = 'LuaFenweiCard',
    target_fixed = false,
    filter = function(self, targets, to_select, player)
        return to_select:hasFlag('trickcardtarget')
    end,
    on_use = function(self, room, source, targets)
        source:loseMark('@fenwei')
        for _, p in ipairs(targets) do
            room:setPlayerFlag(p, 'luafenwei')
        end
    end
}

LuaFenweiVS = sgs.CreateViewAsSkill {
    name = 'LuaFenwei',
    n = 0,
    view_as = function(self, cards)
        return LuaFenweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getMark('@fenwei') > 0 and pattern == '@@LuaFenwei'
    end
}

LuaFenwei = sgs.CreateTriggerSkill {
    name = 'LuaFenwei',
    frequency = sgs.Skill_Limited,
    limit_mark = '@fenwei',
    events = {sgs.CardUsed},
    view_as_skill = LuaFenweiVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf('TrickCard') then
            return false
        end
        if use.to:length() < 2 then
            return false
        end
        local splayer = room:findPlayerBySkillName(self:objectName())
        if splayer then
            for _, dest in sgs.qlist(use.to) do
                room:setPlayerFlag(dest, 'trickcardtarget')
            end
            if room:askForUseCard(splayer, '@@LuaFenwei', '@LuaFenwei') then
                local targetCount = 0
                local nullified_list = use.nullified_list
                for _, dest in sgs.qlist(use.to) do
                    if dest:hasFlag('luafenwei') then
                        table.insert(nullified_list, dest:objectName())
                        room:setPlayerFlag(dest, '-luafenwei')
                        targetCount = targetCount + 1
                    end
                end
                targetCount = math.min(4, targetCount)
                use.nullified_list = nullified_list
                data:setValue(use)
                room:broadcastSkillInvoke(self:objectName())
                room:setEmotion(splayer, 'skill/ganning_fenwei')
                local checker = function(card)
                    return card:isKindOf('Dismantlement')
                end
                while targetCount > 0 do
                    local dismantlement = rinsan.obtainCardFromPile(checker, room:getDrawPile())
                    if dismantlement then
                        splayer:obtainCard(dismantlement)
                    else
                        break
                    end
                    targetCount = targetCount - 1
                end
            end
            for _, target in sgs.qlist(room:getAllPlayers()) do
                room:setPlayerFlag(target, '-trickcardtarget')
            end
        end
        return false
    end,
    can_trigger = globalTrigger
}

-- 替换原版【过河拆桥】
LuaDismantlement = sgs.CreateTrickCard {
    name = 'dismantlement',
    subtype = 'single_target_trick',
    filter = function(self, targets, to_select, player)
        local total_num = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
        return
            targets:length() < total_num and to_select ~= player:objectName() and to_select:getCards('hej'):length() > 0
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        if source:isDead() then
            return
        end
        local room = effect.to:getRoom()
        if (not rinsan.canDiscard(source, target, 'hej')) then
            return
        end
        local card_id = room:askForCardChosen(source, target, 'hej', self:objectName(), false, sgs.Card_MethodDiscard)
        local place = target
        if room:getCardPlace(card_id) == sgs.Player_PlaceDelayedTrick then
            place = nil
        end
        room:throwCard(card_id, place, source)
    end
}

LuaQicaiHotfix = sgs.CreateTriggerSkill {
    name = 'LuaQicaiHotfix',
    frequency = sgs.Skill_Compulsory,
    priority = 10000,
    global = true,
    events = {sgs.CardEffected},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        if effect.to:hasSkill('qicai') and effect.card and effect.card:isKindOf('Dismantlement') then
            local dismantlement = LuaDismantlement:clone()
            dismantlement:setSuit(effect.card:getSuit())
            dismantlement:setNumber(effect.card:getNumber())
            dismantlement:setId(effect.card:getId())
            effect.card = dismantlement
            data:setValue(effect)
        end
        return false
    end,
    can_trigger = targetTrigger
}

ExMouGanning:addSkill(LuaQixi)
ExMouGanning:addSkill(LuaFenwei)
SkillAnjiang:addSkill(LuaQixiTrigger)
SkillAnjiang:addSkill(LuaQicaiHotfix)

-- 谋黄忠
ExMouHuangzhong = sgs.General(extension, 'ExMouHuangzhong', 'shu', '4', true)

LuaLiegong = sgs.CreateTriggerSkill {
    name = 'LuaLiegong',
    events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.SlashProceed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            local card = use.card
            if use.to:length() > 1 then
                return false
            end
            if card and card:isKindOf('Slash') then
                local x = rinsan.getLiegongSuitNum(player)
                if x > 0 then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:setPlayerFlag(player, 'LuaLiegongInvoked')
                        x = math.max(0, x - 1)
                        if x > 0 then
                            -- 参照源码【裸衣】亮出方式
                            local card_ids = room:getNCards(x, false)
                            for _, to in sgs.qlist(use.to) do
                                room:setPlayerFlag(to, 'LuaLiegongTarget')
                            end
                            local move = sgs.CardsMoveStruct(card_ids, player, sgs.Player_PlaceTable,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
                                    self:objectName(), ''))
                            room:moveCardsAtomic(move, true)
                            room:getThread():delay()
                            room:getThread():delay()
                            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                            local damage_count = 0
                            for _, card_id in sgs.qlist(card_ids) do
                                local cd = sgs.Sanguosha:getCard(card_id)
                                local suit_string = rinsan.firstToUpper(cd:getSuitString())
                                if player:getMark('@LuaLiegong' .. suit_string) > 0 then
                                    damage_count = damage_count + 1
                                end
                                dummy:addSubcard(cd)
                            end
                            card:setTag('LuaLiegongExtraDamage', sgs.QVariant(damage_count))
                            room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                player:objectName(), self:objectName(), ''), nil)
                        end
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.transfer or damage.chain then
                return false
            end
            local card = damage.card
            if card and card:isKindOf('Slash') then
                local x = card:getTag('LuaLiegongExtraDamage'):toInt()
                if x > 0 then
                    damage.damage = damage.damage + x
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    data:setValue(damage)
                end
                card:removeTag('LuaLiegongExtraDamage')
            end
        else
            local effect = data:toSlashEffect()
            if not effect.to:hasFlag('LuaLiegongTarget') then
                return false
            end
            local all_suits = {'heart', 'diamond', 'club', 'spade'}
            local suits = {}
            for _, suit in ipairs(all_suits) do
                if effect.from:getMark('@LuaLiegong' .. rinsan.firstToUpper(suit)) > 0 then
                    table.insert(suits, suit)
                end
            end
            if #suits > 0 then
                room:setPlayerCardLimitation(effect.to, 'use, response', 'Jink|' .. table.concat(suits, ','), false)
                local source = room:findPlayerBySkillName(self:objectName())
                local prompt = string.format('@LuaLiegong-jink:%s:%s:%s', effect.from:objectName(), source:objectName(),
                    self:objectName())
                local jink = room:askForCard(effect.to, 'jink', prompt, data, sgs.Card_MethodUse, source)
                if jink then
                    local invalid_jink = table.contains(suits, jink:getSuitString())
                    if invalid_jink then
                        rinsan.sendLogMessage(room, '#LuaLiegongInvalidJink', {
                            ['from'] = effect.to,
                            ['card_str'] = jink:toString()
                        })
                        room:slashResult(effect, nil)
                    else
                        room:slashResult(effect, jink)
                    end
                else
                    room:slashResult(effect, nil)
                end
                room:removePlayerCardLimitation(effect.to, 'use, response', 'Jink|' .. table.concat(suits, ','))
                return true
            end
        end
        return false
    end,
    can_trigger = targetTrigger
}

LuaLiegongMark = sgs.CreateTriggerSkill {
    name = 'LuaLiegongMark',
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.CardFinished, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            if player:hasFlag('LuaLiegongInvoked') then
                room:setPlayerFlag(player, '-LuaLiegongInvoked')
                room:setPlayerMark(player, '@LuaLiegongHeart', 0)
                room:setPlayerMark(player, '@LuaLiegongClub', 0)
                room:setPlayerMark(player, '@LuaLiegongSpade', 0)
                room:setPlayerMark(player, '@LuaLiegongDiamond', 0)
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local card = use.card
            if rinsan.cardCanBeRecorded(card) then
                if use.to:contains(player) and player:hasSkill('LuaLiegong') then
                    room:setPlayerMark(player, rinsan.getLiegongSuitMarkName(card), 1)
                end
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                -- 用于区分无目标响应使用卡牌，例如【闪】
                local resp = data:toCardResponse()
                if not resp.m_isUse then
                    return false
                end
                card = resp.m_card
            end
            if rinsan.cardCanBeRecorded(card) then
                if player:hasSkill('LuaLiegong') then
                    room:setPlayerMark(player, rinsan.getLiegongSuitMarkName(card), 1)
                end
            end
        end
    end,
    can_trigger = targetTrigger
}

LuaLiegongAttackMod = sgs.CreateTargetModSkill {
    name = 'LuaLiegongAttackMod',
    pattern = 'Slash',
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill('LuaLiegong') then
            return math.max(card:getNumber() - from:getAttackRange(), 0)
        end
    end
}

ExMouHuangzhong:addSkill(LuaLiegong)
SkillAnjiang:addSkill(LuaLiegongAttackMod)
SkillAnjiang:addSkill(LuaLiegongMark)

-- 谋黄盖
ExMouHuanggai = sgs.General(extension, 'ExMouHuanggai', 'wu', '4', true, true)

-- 是否满足【诈降】条件
local function canInvokeZhaxiang(from)
    return from:getMark('LuaMouZhaxiangUsed') < from:getLostHp()
end

LuaMouKurouCard = sgs.CreateSkillCard {
    name = 'LuaMouKurou',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local loseHp = 1
        if card:isKindOf('Peach') or card:isKindOf('Analeptic') then
            loseHp = 2
        end
        local target = targets[1]
        room:obtainCard(target, card)
        room:loseHp(source, loseHp)
    end
}

LuaMouKurouVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaMouKurou',
    view_filter = function(self, to_select)
        return true
    end,
    view_as = function(self, card)
        local vs_card = LuaMouKurouCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaMouKurou'
    end
}

LuaMouKurou = sgs.CreateTriggerSkill {
    name = 'LuaMouKurou',
    events = {sgs.EventPhaseStart, sgs.HpLost},
    view_as_skill = LuaMouKurouVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                room:askForUseCard(player, '@@LuaMouKurou', '@LuaMouKurou')
            end
        else
            local lostHp = data:toInt()
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            rinsan.increaseShield(player, lostHp * 2)
        end
    end
}

LuaMouZhaxiang = sgs.CreateTriggerSkill {
    name = 'LuaMouZhaxiang',
    events = {sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local lostHp = player:getLostHp()
        if lostHp == 0 then
            return false
        end
        local count = data:toInt()
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        data:setValue(count + lostHp)
    end
}

LuaMouZhaxiangBuff = sgs.CreateTriggerSkill {
    name = 'LuaMouZhaxiangBuff',
    global = true,
    priority = 10000,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardAsked, sgs.TurnStart, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (not use.from) or (not use.from:hasSkill('LuaMouZhaxiang')) then
                return false
            end
            if (not use.card) or use.card:isKindOf('SkillCard') then
                return false
            end
            if canInvokeZhaxiang(use.from) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:addPlayerMark(p, 'LuaMouZhaxiangTarget')
                end
                room:broadcastSkillInvoke('LuaMouZhaxiang')
                room:sendCompulsoryTriggerLog(use.from, 'LuaMouZhaxiang')
                if (use.card:isKindOf('Slash') or use.card:isNDTrick()) then
                    room:addPlayerMark(use.from, self:objectName() .. 'engine')
                    if use.from:getMark(self:objectName() .. 'engine') > 0 then
                        room:removePlayerMark(use.from, self:objectName() .. 'engine')
                    end
                end
            end
        elseif event == sgs.CardAsked then
            if player:getMark('LuaMouZhaxiangTarget') > 0 then
                room:provide(nil)
                room:setPlayerMark(player, 'LuaMouZhaxiangTarget', 0)
                return true
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                if rinsan.RIGHT(self, use.from, 'LuaMouZhaxiang') and canInvokeZhaxiang(use.from) then
                    local jink_table = sgs.QList2Table(use.from:getTag('Jink_' .. use.card:toString()):toIntList())
                    local index = 1
                    for _, _ in sgs.qlist(use.to) do
                        jink_table[index] = 0
                        index = index + 1
                    end
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    use.from:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and rinsan.RIGHT(self, effect.from, 'LuaMouZhaxiang') and canInvokeZhaxiang(effect.from) then
                return true
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if (not use.card) or use.card:isKindOf('SkillCard') then
                return false
            end
            room:addPlayerMark(player, 'LuaMouZhaxiangUsed')
            if use.from and use.from:hasSkill('LuaMouZhaxiang') then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, 'LuaMouZhaxiangTarget', 0)
                end
            end
        else
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, 'LuaMouZhaxiangUsed', 0)
            end
        end
        return false
    end,
    can_trigger = targetTrigger
}

LuaMouZhaxiangTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaMouZhaxiangTargetMod',
    pattern = '.',
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill('LuaMouZhaxiang') and canInvokeZhaxiang(from) then
            return 1000
        end
        return 0
    end,
    residue_func = function(self, player)
        if player:hasSkill('LuaMouZhaxiang') and canInvokeZhaxiang(player) then
            return 1000
        else
            return 0
        end
    end
}

ExMouHuanggai:addSkill(LuaMouKurou)
ExMouHuanggai:addSkill(LuaMouZhaxiang)
SkillAnjiang:addSkill(LuaMouZhaxiangBuff)
SkillAnjiang:addSkill(LuaMouZhaxiangTargetMod)
