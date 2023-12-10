-- 江山如故·起包
-- Created by DZDcyj at 2023/10/4
module('extensions.CountryAsBeforeIntroductionPackage', package.seeall)
extension = sgs.Package('CountryAsBeforeIntroductionPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 起·刘备
ExQiLiubei = sgs.General(extension, 'ExQiLiubei', 'qun', '4', true, true)

LuaJishan = sgs.CreateTriggerSkill {
    name = 'LuaJishan',
    events = {sgs.DamageInflicted, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        -- 防止伤害
        if event == sgs.DamageInflicted then
            local data2 = sgs.QVariant()
            data2:setValue(player)
            for _, qiliubei in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if qiliubei:getMark('LuaJishan-Prevent-Damage-Clear') == 0 then
                    if room:askForSkillInvoke(qiliubei, self:objectName(), data2) then
                        room:addPlayerMark(qiliubei, 'LuaJishan-Prevent-Damage-Clear')
                        room:setPlayerMark(player, '@LuaJishan', 1)
                        rinsan.sendLogMessage(room, '#LuaJishan', {
                            ['from'] = qiliubei,
                            ['to'] = player,
                            ['arg'] = damage.damage,
                            ['arg2'] = self:objectName(),
                        })
                        room:doAnimate(rinsan.ANIMATE_INDICATE, qiliubei:objectName(), player:objectName())
                        room:loseHp(qiliubei)
                        qiliubei:drawCards(1, self:objectName())
                        player:drawCards(1, self:objectName())
                        return true
                    end
                end
            end
            return false
        end
        if not rinsan.RIGHT(self, player) then
            return false
        end
        -- 造成伤害后
        if player:getMark('LuaJishan-Damage-Clear') > 0 then
            return false
        end
        local minHp = 10000
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHp() < minHp then
                minHp = p:getHp()
            end
        end
        local available_targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHp() == minHp and p:getMark('@LuaJishan') > 0 and p:isWounded() then
                available_targets:append(p)
            end
        end
        if available_targets:isEmpty() then
            return false
        end
        local target = room:askForPlayerChosen(player, available_targets, self:objectName(), 'LuaJishan-choose', true,
            true)
        if target then
            room:addPlayerMark(player, 'LuaJishan-Damage-Clear')
            rinsan.recover(target, 1, player)
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaZhenqiao = sgs.CreateTriggerSkill {
    name = 'LuaZhenqiao',
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and use.card:getSkillName() ~= self:objectName() and
            (not use.card:hasFlag(self:objectName())) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            use.card:setSkillName(self:objectName())
            room:setCardFlag(use.card, self:objectName())
            local alives = sgs.SPlayerList()
            for _, p in sgs.qlist(use.to) do
                if p:isAlive() then
                    alives:append(p)
                end
            end
            if alives:isEmpty() then
                return false
            end
            room:useCard(sgs.CardUseStruct(use.card, player, alives))
        end
    end,
    can_trigger = function(self, target)
        if rinsan.RIGHT(self, target) then
            return target:getWeapon() == nil
        end
        return false
    end,
}

LuaZhenqiaoAttackRange = sgs.CreateAttackRangeSkill {
    name = 'LuaZhenqiaoAttackRange',
    extra_func = function(self, from, card)
        if from:hasSkill('LuaZhenqiao') then
            return 1
        end
        return 0
    end,
}

ExQiLiubei:addSkill(LuaJishan)
ExQiLiubei:addSkill(LuaZhenqiao)
table.insert(hiddenSkills, LuaZhenqiaoAttackRange)

-- 起·孙坚
ExQiSunjian = sgs.General(extension, 'ExQiSunjian', 'qun', '4', true, true)

LuaPingtaoCard = sgs.CreateSkillCard {
    name = 'LuaPingtao',
    will_throw = false,
    target_fixed = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local exchange = room:askForExchange(target, self:objectName(), 1, 1, true,
            '@LuaPingtao:' .. source:objectName(), true)
        if exchange then
            source:obtainCard(exchange)
            room:addPlayerMark(source, self:objectName() .. '-Clear')
        else
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(slash, source, target))
        end
    end,
}

LuaPingtao = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaPingtao',
    view_as = function(self, cards)
        return LuaPingtaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaPingtao')
    end,
}

LuaPingtaoTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaPingtaoTargetMod',
    pattern = 'Slash',
    residue_func = function(self, player)
        return player:getMark('LuaPingtao-Clear')
    end,
}

LuaJuelieVS = sgs.CreateViewAsSkill {
    name = 'LuaJuelie',
    target_fixed = true,
    will_throw = true,
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, card in ipairs(cards) do
            dummy:addSubcard(card)
        end
        dummy:setSkillName(self:objectName())
        return dummy
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaJuelie'
    end,
}

LuaJuelie = sgs.CreateTriggerSkill {
    name = 'LuaJuelie',
    events = {sgs.TargetSpecified, sgs.DamageCaused},
    view_as_skill = LuaJuelieVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then
                return false
            end
            if damage.card and damage.card:isKindOf('Slash') then
                local minHp = true
                local minHandcard = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHp() < player:getHp() then
                        minHp = false
                    end
                    if p:getHandcardNum() < player:getHandcardNum() then
                        minHandcard = false
                    end
                end
                if minHandcard or minHp then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
            return false
        end
        if not rinsan.canDiscard(player, player, 'he') then
            return false
        end
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            for _, t in sgs.qlist(use.to) do
                local dummy = room:askForCard(player, '@@LuaJuelie', '@LuaJuelie:' .. t:objectName(), data,
                    self:objectName())
                local discard_n = dummy:subcardsLength()
                if discard_n > 0 then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), t:objectName())
                    local orig_places = {}
                    local cards = sgs.IntList()
                    room:setTag('LuaFakeMove', sgs.QVariant(true))
                    room:setPlayerFlag(t, 'xuanhuo_InTempMoving')
                    for i = 0, discard_n - 1, 1 do
                        if not rinsan.canDiscard(player, t, 'he') then
                            break
                        end
                        local id = room:askForCardChosen(player, t, 'he', self:objectName(), false, sgs.Card_MethodNone,
                            cards)
                        local place = room:getCardPlace(id)
                        orig_places[i] = place
                        cards:append(id)
                        t:addToPile('#LuaJuelie', id, false)
                    end
                    for i = 0, cards:length() - 1, 1 do
                        room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), t, orig_places[i], false)
                    end
                    room:setPlayerFlag(t, '-xuanhuo_InTempMoving')
                    room:setTag('LuaFakeMove', sgs.QVariant(false))
                    local to_discard = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    to_discard:addSubcards(cards)
                    room:throwCard(to_discard, t, player)
                end
            end
        end
        return false
    end,
}

ExQiSunjian:addSkill(LuaPingtao)
ExQiSunjian:addSkill(LuaJuelie)
table.insert(hiddenSkills, LuaPingtaoTargetMod)

rinsan.addHiddenSkills(hiddenSkills)
