-- 谋攻篇-同包
-- Created by DZDcyj at 2023/4/1
module('extensions.StrategicAttackTogetherPackage', package.seeall)
extension = sgs.Package('StrategicAttackTogetherPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 谋夏侯氏
ExMouXiahoushi = sgs.General(extension, 'ExMouXiahoushi', 'shu', '3', false, true)

LuaMouQiaoshi = sgs.CreateTriggerSkill {
    name = 'LuaMouQiaoshi',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if player:getMark(self:objectName() .. '-Clear') > 0 then
            return false
        end
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() then
            local prompt = string.format('%s:%s::%d', 'invoke', player:objectName(), damage.damage)
            if room:askForSkillInvoke(damage.from, self:objectName(), sgs.QVariant(prompt)) then
                rinsan.sendLogMessage(room, '#LuaMouQiaoshiInvoke', {
                    ['from'] = damage.from,
                    ['to'] = player,
                    ['arg'] = self:objectName(),
                })
                room:broadcastSkillInvoke(self:objectName())
                room:doAnimate(rinsan.ANIMATE_INDICATE, damage.from:objectName(), player:objectName())
                rinsan.recover(player, damage.damage, damage.from)
                damage.from:drawCards(2, self:objectName())
                room:addPlayerMark(player, self:objectName() .. '-Clear')
            end
        end
        return false
    end,
}

LuaMouYanyuCard = sgs.CreateSkillCard {
    name = 'LuaMouYanyu',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        source:drawCards(1, self:objectName())
    end,
}

LuaMouYanyuVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaMouYanyu',
    filter_pattern = 'Slash',
    view_as = function(self, card)
        local vs_card = LuaMouYanyuCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#LuaMouYanyu') < 2
    end,
}

LuaMouYanyu = sgs.CreateTriggerSkill {
    name = 'LuaMouYanyu',
    events = {sgs.EventPhaseEnd},
    view_as_skill = LuaMouYanyuVS,
    on_trigger = function(self, event, player, data, room)
        if player:hasUsed('#LuaMouYanyu') then
            local targets = room:getOtherPlayers(player)
            local count = 3 * player:usedTimes('#LuaMouYanyu')
            local prompt = string.format('LuaMouYanyu-choose:%d', count)
            local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                target:drawCards(count, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

ExMouXiahoushi:addSkill(LuaMouQiaoshi)
ExMouXiahoushi:addSkill(LuaMouYanyu)

-- 谋孙策
ExMouSunce = sgs.General(extension, 'ExMouSunce$', 'wu', '4', true, true)

LuaMouJiangVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouJiang',
    view_as = function(self, cards)
        local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_SuitToBeDecided, -1)
        duel:addSubcards(sgs.Self:getHandcards())
        duel:setSkillName(self:objectName())
        return duel
    end,
    enabled_at_play = function(self, player)
        if player:isKongcheng() then
            return false
        end
        local count = 1
        if player:getMark('LuaMouZhiba') > 0 then
            count = player:getKingdom() == 'wu' and 2 or 1
            for _, sib in sgs.qlist(player:getAliveSiblings()) do
                if sib:getKingdom() == 'wu' then
                    count = count + 1
                end
            end
        end
        return player:getMark('LuaMouJiangDuelTimes_biu') < count
    end,
}

LuaMouJiang = sgs.CreateTriggerSkill {
    name = 'LuaMouJiang',
    events = {sgs.PreCardUsed, sgs.TargetConfirmed, sgs.TargetSpecified},
    view_as_skill = LuaMouJiangVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.PreCardUsed then
            if use.card:getSkillName() == self:objectName() then
                room:addPlayerMark(player, 'LuaMouJiangDuelTimes_biu')
            end
            if use.card:isKindOf('Duel') then
                local available_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if use.to:contains(p) or room:isProhibited(player, p, use.card) then
                        goto nextPlayer
                    end
                    if use.card:targetFixed() then
                        available_targets:append(p)
                    else
                        if use.card:targetFilter(sgs.PlayerList(), p, player) then
                            available_targets:append(p)
                        end
                    end
                    ::nextPlayer::
                end
                if available_targets:isEmpty() then
                    return false
                end
                local prompt = '@LuaMouJiang-add:' .. use.card:objectName()
                local extra = room:askForPlayerChosen(player, available_targets, self:objectName(), prompt, true)
                if not extra then
                    return false
                end
                rinsan.skill(self, room, player, true)
                use.to:append(extra)
                room:loseHp(player)
                rinsan.sendLogMessage(room, '#QiaoshuiAdd', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                    ['to'] = extra,
                    ['card_str'] = use.card:toString(),
                })
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), extra:objectName())
                room:sortByActionOrder(use.to)
                data:setValue(use)
            end
            return false
        end
        if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player)) then
            if use.card:isKindOf('Duel') or (use.card:isKindOf('Slash') and use.card:isRed()) then
                if player:askForSkillInvoke(self:objectName(), data) then
                    player:drawCards(1, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
        end
        return false
    end,
}

LuaMouHunzi = sgs.CreateTriggerSkill {
    name = 'LuaMouHunzi',
    frequency = sgs.Skill_Wake,
    events = {sgs.QuitDying},
    on_trigger = function(self, event, player, data, room)
        if data:toDying().who:objectName() == player:objectName() then
            rinsan.sendLogMessage(room, '#LuaMouHunziWake', {
                ['from'] = player,
                ['arg'] = self:objectName(),
            })
            if room:changeMaxHpForAwakenSkill(player) then
                room:broadcastSkillInvoke(self:objectName())
                rinsan.increaseShield(player, 1)
                player:drawCards(2, self:objectName())
                room:addPlayerMark(player, self:objectName())
                room:acquireSkill(player, 'LuaMouYingzi')
                room:acquireSkill(player, 'LuaYinghun')
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getMark(self:objectName()) == 0
    end,
}

LuaMouZhiba = sgs.CreateTriggerSkill {
    name = 'LuaMouZhiba$',
    events = {sgs.Dying},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaMouZhiba',
    on_trigger = function(self, event, player, data, room)
        if data:toDying().who:objectName() == player:objectName() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:loseMark('@LuaMouZhiba')
                local x = 0
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getKingdom() == 'wu' then
                        x = x + 1
                    end
                end
                if x > 0 then
                    rinsan.recover(player, x)
                end
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getKingdom() == 'wu' then
                        rinsan.doDamage(nil, p, 1)
                        if not p:isAlive() then
                            player:drawCards(3, self:objectName())
                        end
                    end
                end
            end
        end
    end,
}

ExMouSunce:addSkill(LuaMouJiang)
ExMouSunce:addSkill(LuaMouHunzi)
ExMouSunce:addSkill(LuaMouZhiba)
ExMouSunce:addRelateSkill('LuaMouYingzi')
ExMouSunce:addRelateSkill('LuaYinghun')
