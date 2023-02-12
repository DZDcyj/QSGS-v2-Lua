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

ExMouSunshangxiang = sgs.General(extension, 'ExMouSunshangxiang', 'shu', '4', false, true)

LuaMouLiangzhuCard = sgs.CreateSkillCard {
    name = 'LuaMouLiangzhu',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and to_select:hasEquip()
    end,
    on_use = function(self, room, source, targets)
        local zhuTarget
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:getMark('@LuaMouLiangzhu') > 0 then
                zhuTarget = p
                break
            end
        end
        local target = targets[1]
        if target:hasEquip() then
            local card_id = room:askForCardChosen(source, target, 'e', self:objectName(), false, sgs.Card_MethodDiscard)
            source:addToPile('LuaMouLiangzhuPile', card_id)
        end
        local choices = {}
        if zhuTarget:isWounded() then
            table.insert(choices, 'LuaMouLiangzhuChoice1')
        end
        table.insert(choices, 'LuaMouLiangzhuChoice2')
        local choice = room:askForChoice(zhuTarget, self:objectName(), table.concat(choices, '+'))
        if choice == 'LuaMouLiangzhuChoice1' then
            rinsan.recover(room, zhuTarget)
        else
            zhuTarget:drawCards(2, self:objectName())
        end
    end
}

LuaMouLiangzhu = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouLiangzhu',
    view_as = function(self, cards)
        return LuaMouLiangzhuCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getKingdom() ~= 'shu' then
            return false
        end
        return not player:hasUsed('#LuaMouLiangzhu')
    end
}

LuaMouJieyinAwakeHelper = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyinAwakeHelper',
    events = {sgs.MarkChanged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local jieyinMark = 'LuaMouJieyin'
        local mousunshangxiang = room:findPlayerBySkillName(jieyinMark)
        if not mousunshangxiang or mousunshangxiang:getMark(jieyinMark) > 0 then
            return false
        end
        local mark = data:toMark()
        if mark.name ~= '@LuaMouLiangzhu' then
            return false
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark('@LuaMouLiangzhu') > 0 then
                return false
            end
        end
        rinsan.sendLogMessage(room, '#LuaMouJieyinWake', {
            ['from'] = mousunshangxiang,
            ['arg'] = 'LuaMouJieyin',
            ['arg2'] = '@LuaMouLiangzhu'
        })
        room:broadcastSkillInvoke('LuaMouJieyin', 2)
        if room:changeMaxHpForAwakenSkill(mousunshangxiang, 0) then
            room:addPlayerMark(mousunshangxiang, jieyinMark)
            rinsan.recover(room, mousunshangxiang)
            local to_obtain = sgs.IntList()
            local card_table = {}
            for _, id in sgs.qlist(mousunshangxiang:getPile('LuaMouLiangzhuPile')) do
                to_obtain:append(id)
                table.insert(card_table, id)
            end
            if #card_table > 0 then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                dummy:addSubcards(to_obtain)
                rinsan.sendLogMessage(room, '$LuaMouJieyinGot', {
                    ['from'] = mousunshangxiang,
                    ['arg'] = 'LuaMouLiangzhuPile',
                    ['card_str'] = table.concat(card_table, '+')
                })
                mousunshangxiang:obtainCard(dummy)
            end
            room:setPlayerProperty(mousunshangxiang, 'kingdom', sgs.QVariant('wu'))
            room:loseMaxHp(mousunshangxiang)
            room:acquireSkill(mousunshangxiang, 'LuaMouXiaoji')
        end
    end,
    can_trigger = function(self, target)
        return true
    end
}

LuaMouJieyinStart = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyinStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, _player, data, room)
        for _, player in sgs.qlist(room:findPlayersBySkillName('LuaMouJieyin')) do
            if player:getMark(self:objectName()) == 0 then
                local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), 'LuaMouJieyin',
                    'LuaMouJieyin-invoke', false, true)
                if to then
                    room:broadcastSkillInvoke('LuaMouJieyin', 1)
                    room:notifySkillInvoked(player, 'LuaMouJieyin')
                    to:gainMark('@LuaMouLiangzhu')
                end
                room:addPlayerMark(player, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return true
    end
}

LuaMouJieyin = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyin',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        local zhuTarget
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getMark('@LuaMouLiangzhu') > 0 then
                zhuTarget = p
                break
            end
        end
        if zhuTarget then
            local choices = {}
            if not zhuTarget:isKongcheng() then
                table.insert(choices, 'LuaMouJieyinChoice1')
            end
            table.insert(choices, 'LuaMouJieyinChoice2')
            -- For AI
            local aiData = sgs.QVariant()
            aiData:setValue(zhuTarget)
            player:setTag('LuaMouLiangZhuTarget', aiData)
            room:broadcastSkillInvoke('LuaMouJieyin', 1)
            local choice = room:askForChoice(zhuTarget, self:objectName(), table.concat(choices, '+'))
            player:removeTag('LuaMouLiangZhuTarget')
            if choice == 'LuaMouJieyinChoice1' then
                if zhuTarget:getHandcardNum() < 2 then
                    room:obtainCard(player, zhuTarget:getHandcards():first(), false)
                    rinsan.increaseShield(zhuTarget, 1)
                    return false
                end
                local card = room:askForExchange(zhuTarget, self:objectName(), 2, 2, true,
                    'LuaMouJieyin-give:' .. player:objectName(), false)
                if card then
                    room:obtainCard(player, card, false)
                    rinsan.increaseShield(zhuTarget, 1)
                end
            else
                if zhuTarget:getMark('LuaMouLiangZhuTargeted') == 0 then
                    local available_targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:objectName() ~= player:objectName() and p:objectName() ~= zhuTarget:objectName() then
                            if p:getMark('LuaMouLiangZhuTargeted') <= 1 then
                                available_targets:append(p)
                            end
                        end
                    end
                    if available_targets:length() > 0 then
                        local target = room:askForPlayerChosen(player, available_targets, self:objectName(),
                            'LuaMouJieyinMoveTo', false, true)
                        if target then
                            target:gainMark('@LuaMouLiangzhu')
                        end
                    end
                end
                zhuTarget:loseMark('@LuaMouLiangzhu')
                room:addPlayerMark(zhuTarget, 'LuaMouLiangZhuTargeted')
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Play)
    end
}

LuaMouXiaoji = sgs.CreateTriggerSkill {
    name = 'LuaMouXiaoji',
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then
            if move.from_places:contains(sgs.Player_PlaceEquip) then
                for i, _ in sgs.qlist(move.card_ids) do
                    if not player:isAlive() then
                        return false
                    end
                    if move.from_places:at(i) == sgs.Player_PlaceEquip then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:broadcastSkillInvoke(self:objectName())
                            player:drawCards(2, self:objectName())
                            local available_targets = sgs.SPlayerList()
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                if rinsan.canDiscard(player, p, 'ej') then
                                    available_targets:append(p)
                                end
                            end
                            if available_targets:length() > 0 then
                                local target = room:askForPlayerChosen(player, available_targets, self:objectName(),
                                    'LuaMouXiaojiChoose', true, true)
                                if target then
                                    local card_id = room:askForCardChosen(player, target, 'ej', self:objectName(),
                                        false, sgs.Card_MethodDiscard)
                                    room:throwCard(card_id, target, player)
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getKingdom() == 'wu'
    end
}

ExMouSunshangxiang:addSkill(LuaMouLiangzhu)
ExMouSunshangxiang:addSkill(LuaMouJieyin)
ExMouSunshangxiang:addRelateSkill('LuaMouXiaoji')
SkillAnjiang:addSkill(LuaMouJieyinAwakeHelper)
SkillAnjiang:addSkill(LuaMouJieyinStart)
SkillAnjiang:addSkill(LuaMouXiaoji)