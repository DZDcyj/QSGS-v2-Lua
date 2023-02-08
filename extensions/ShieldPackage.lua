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

        room:setPlayerProperty(damage.to, 'hp', sgs.QVariant(newHp))
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
            ['arg'] = damage.to:getHp(),
            ['arg2'] = damage.to:getMaxHp()
        })

        return true
    end,
    can_trigger = function(self, target)
        return true
    end
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
    can_trigger = function(self, target)
        return true
    end
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
        return
            rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_RoundStart) and rinsan.getShieldCount(target) >=
                3
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
    can_trigger = function(self, target)
        return true
    end
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
    can_trigger = function(self, target)
        return true
    end
}

ExMouHuaxiong:addSkill(LuaMouYaowu)
ExMouHuaxiong:addSkill(LuaMouYangwei)
SkillAnjiang:addSkill(LuaMouYangweiTargetMod)
SkillAnjiang:addSkill(LuaMouyangweiBuff)
