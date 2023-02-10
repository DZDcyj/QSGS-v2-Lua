-- 谋攻包
-- Created by DZDcyj at 2023/2/6
module('extensions.ShieldPackage', package.seeall)
extension = sgs.Package('ShieldPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

-- 初始护甲值表
local START_SHIELDS = {
    ['ExMouHuaxiong'] = 1
}

local function globalTrigger(self, target)
    return true
end

-- 护甲结算
LuaShield = sgs.CreateTriggerSkill {
    name = 'LuaShield',
    events = {sgs.DamageDone},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        -- 必要时终止多余结算
        if rinsan.getShieldCount(damage.to) <= 0 then
            return false
        end

        -- 这里延时一下，是避免当有多人同时受到伤害时(比如释放了AOE牌)，
        -- 掉血效果太快导致看不清楚的问题
        if damage.to:getAI() then
            room:getThread():delay(500)
        end

        if damage.from and (not damage.from:isAlive()) then
            damage.from = nil
        end
        data:setValue(damage)

        local params = {}
        local type = '#DamageNoSource'

        if damage.from then
            params['from'] = damage.from
            type = '#Damage'
        end
        params['to'] = damage.to
        params['arg'] = damage.damage

        local nature = 'normal_nature'
        if damage.nature == sgs.DamageStruct_Fire then
            nature = 'fire_nature'
        elseif damage.nature == sgs.DamageStruct_Thunder then
            nature = 'thunder_nature'
        end
        params['arg2'] = nature
        rinsan.sendLogMessage(room, type, params)

        local newHp = damage.to:getHp() - math.max(0, damage.damage - rinsan.getShieldCount(damage.to))

        local jsonArray = string.format('"%s",%d,%d', damage.to:objectName(), -damage.damage, damage.nature)
        room:doBroadcastNotify(sgs.CommandType['S_COMMAND_CHANGE_HP'], jsonArray)

        room:setTag('HpChangedData', data)

        if damage.nature ~= sgs.DamageStruct_Normal and player:isChained() and (not damage.chain) then
            local n = room:getTag('is_chained'):toInt()
            n = n + 1
            room:setTag('is_chained', sgs.QVariant(n))
        end

        -- 失去护盾数，目前用于【狭援】
        if damage.damage >= rinsan.getShieldCount(damage.to) then
            room:setPlayerFlag(damage.to, 'ShieldAllLost')
            damage.to:setTag('ShieldLostCount', sgs.QVariant(math.min(damage.damage, rinsan.getShieldCount(damage.to))))
        end

        rinsan.decreaseShield(damage.to, damage.damage)

        -- 手动播放音效和动画
        if damage.damage > 0 then
            local delta = damage.damage > 3 and 3 or damage.damage
            sgs.Sanguosha:playSystemAudioEffect(string.format('injure%d', delta), true)
        end
        room:setEmotion(damage.to, 'damage')

        if damage.nature == sgs.DamageStruct_Fire then
            room:doAnimate(rinsan.ANIMATE_FIRE, damage.to:objectName())
        elseif damage.nature == sgs.DamageStruct_Thunder then
            room:doAnimate(rinsan.ANIMATE_LIGHTING, damage.to:objectName())
        end

        rinsan.sendLogMessage(room, '#GetHp', {
            ['from'] = damage.to,
            ['arg'] = newHp,
            ['arg2'] = damage.to:getMaxHp()
        })
        room:setPlayerProperty(damage.to, 'hp', sgs.QVariant(newHp))
        return true
    end,
    can_trigger = globalTrigger
}

LuaShieldInit = sgs.CreateTriggerSkill {
    name = 'LuaShieldInit',
    global = true,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local first = START_SHIELDS[p:getGeneralName()] or 0
            local second = START_SHIELDS[p:getGeneral2Name()] or 0
            room:setPlayerMark(p, rinsan.SHIELD_MARK, math.min(rinsan.MAX_SHIELD_COUNT, first + second))
        end
    end,
    can_trigger = globalTrigger
}

SkillAnjiang:addSkill(LuaShield)
SkillAnjiang:addSkill(LuaShieldInit)

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
            local card = room:askForExchange(target, self:objectName(), 1, 1, true,
                string.format('LuaMouJieyue-Give:%s', player:objectName()), true)
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

-- 谋华雄
ExMouHuaxiong = sgs.General(extension, 'ExMouHuaxiong', 'qun', '4', true, true, false, 3)

LuaMouYaowu = sgs.CreateTriggerSkill {
    name = 'LuaMouYaowu',
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') then
            if damage.card:isRed() then
                if damage.from and damage.from:isAlive() then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(damage.to, self:objectName())
                    local choices = {}
                    if damage.from:isWounded() then
                        table.insert(choices, 'recover')
                    end
                    table.insert(choices, 'draw')
                    room:doAnimate(rinsan.ANIMATE_INDICATE, damage.to:objectName(), damage.from:objectName())
                    local choice = room:askForChoice(damage.from, 'yaowu', table.concat(choices, '+'))
                    if choice == 'recover' then
                        rinsan.recover(room, damage.from, 1)
                    else
                        damage.from:drawCards(1, self:objectName())
                    end
                end
            else
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(damage.to, self:objectName())
                damage.to:drawCards(1, self:objectName())
            end
        end
        return false
    end
}

LuaMouYangweiCard = sgs.CreateSkillCard {
    name = 'LuaMouYangwei',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        source:drawCards(2, self:objectName())
        source:gainMark('@LuaWei')
        room:setPlayerFlag(source, 'LuaMouYangweiInvoked')
        room:addPlayerMark(source, 'LuaMouYangweiDisabled')
    end
}

LuaMouYangweiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouYangwei',
    view_as = function(self)
        return LuaMouYangweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMouYangwei') and player:getMark('LuaMouYangweiDisabled') == 0
    end
}

LuaMouYangwei = sgs.CreateTriggerSkill {
    name = 'LuaMouYangwei',
    events = {sgs.EventPhaseEnd},
    view_as_skill = LuaMouYangweiVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:hasFlag('LuaMouYangweiInvoked') then
                room:setPlayerFlag(player, '-LuaMouYangweiInvoked')
            else
                room:setPlayerMark(player, 'LuaMouYangweiDisabled', 0)
            end
        end
        room:setPlayerMark(player, '@LuaWei', 0)
        return false
    end
}

LuaMouYangweiTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaMouYangweiTargetMod',
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:getMark('@LuaWei') > 0 then
            return 1
        end
        return 0
    end,
    distance_limit_func = function(self, from)
        if from:getMark('@LuaWei') > 0 then
            return 1000
        end
        return 0
    end
}

LuaMouyangweiBuff = sgs.CreateTriggerSkill {
    name = 'LuaMouyangweiBuff',
    events = {sgs.TargetSpecified},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from and use.from:getMark('@LuaWei') > 0 and use.card and use.card:isKindOf('Slash') then
            for _, p in sgs.qlist(use.to) do
                rinsan.addQinggangTag(p, use.card)
            end
        end
    end,
    can_trigger = globalTrigger
}

ExMouHuaxiong:addSkill(LuaMouYaowu)
ExMouHuaxiong:addSkill(LuaMouYangwei)
SkillAnjiang:addSkill(LuaMouYangweiTargetMod)
SkillAnjiang:addSkill(LuaMouyangweiBuff)

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
    can_trigger = function(self, target)
        return target
    end
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
