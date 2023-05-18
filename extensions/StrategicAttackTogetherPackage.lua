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
