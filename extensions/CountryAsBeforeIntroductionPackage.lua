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
        if use.card and use.card:isKindOf('Slash') and use.card:getSkillName() ~= self:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            use.card:setSkillName(self:objectName())
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

rinsan.addHiddenSkills(hiddenSkills)
