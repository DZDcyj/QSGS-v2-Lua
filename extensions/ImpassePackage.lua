-- 绝境之战包
-- Created by DZDcyj at 2021/11/30

module('extensions.ImpassePackage', package.seeall)
extension = sgs.Package('ImpassePackage')

SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

-- 暴走标记
BaozouMark = '@baozou'

-- BOSS 技能

-- 思略
-- 锁定技：摸牌阶段，你始终摸X张牌，X为你当前的体力值；进入暴走状态后，摸牌阶段放弃摸牌，改为依次从其他存活角色处获得一张牌
LuaSilve =
    sgs.CreateTriggerSkill {
    name = 'LuaSilve',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if player:getMark(BaozouMark) == 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            data:setValue(player:getHp())
        else
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isNude() then
                    local id = room:askForCardChosen(player, p, 'he', self:objectName())
                    player:obtainCard(sgs.Sanguosha:getCard(id), false)
                end
            end
            data:setValue(0)
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaSilve)

-- 克敌
-- 你受到伤害后可以摸X张牌，X为你当前体力值；进入暴走状态后，X为场上存活的角色数
LuaKedi =
    sgs.CreateTriggerSkill {
    name = 'LuaKedi',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local x = player:getHp()
        if player:getMark(BaozouMark) > 0 then
            x = room:alivePlayerCount()
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            player:drawCards(x, self:objectName())
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaKedi)

-- 济世
-- 锁定技，回合开始阶段，若你的手牌不大于X，你可以从除你以外每名角色那获得一张手牌，若目标角色无手牌，则失去一点体力。X为你当前体力值；
-- 进入暴走状态后，若目标角色无手牌，则失去两点体力。X为存活的角色数与你当前体力上限之和。你的手牌上限为存活的角色数
LuaJishi =
    sgs.CreateTriggerSkill {
    name = 'LuaJishi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local x = player:getHp()
            local loseHpNum = 1
            if player:getMark(BaozouMark) > 0 then
                x = player:getMaxHp() + room:alivePlayerCount()
                loseHpNum = 2
            end
            if player:getHandcardNum() > x then
                return false
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isKongcheng() then
                    room:loseHp(p, loseHpNum)
                else
                    local id = room:askForCardChosen(player, p, 'h', self:objectName())
                    player:obtainCard(sgs.Sanguosha:getCard(id), false)
                end
            end
        end
    end
}

LuaJishiMaxCards =
    sgs.CreateMaxCardsSkill {
    name = '#LuaJishiMaxCards',
    fixed_func = function(self, target)
        if target:hasSkill('LuaJishi') and target:getMark(BaozouMark) > 0 then
            return target:getAliveSiblings():length() + 1
        end
        return -1
    end
}

SkillAnjiang:addSkill(LuaJishi)
SkillAnjiang:addSkill(LuaJishiMaxCards)

-- 大吉
-- 锁定技，回合结束阶段，你摸X张牌（若你已进入暴走状态，则X为存活角色数，否则X为你的体力值）
-- 进入暴走状态后，你的回合外，若你已受伤，则你为锦囊牌的唯一目标时，该锦囊对你无效
-- 锁定技，当你受到大于1的伤害时，此伤害-1
LuaDaji =
    sgs.CreateTriggerSkill {
    name = 'LuaDaji',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.DamageInflicted, sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local x = player:getHp()
                if player:getMark(BaozouMark) > 0 then
                    x = room:alivePlayerCount()
                end
                player:drawCards(x, self:objectName())
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.damage > 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                damage.damage = damage.damage - 1
                data:setValue(damage)
            end
        elseif event == sgs.TargetConfirmed then
            if player:getMark(BaozouMark) == 0 or (not player:isWounded()) then
                return false
            end
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('TrickCard') then
                if use.to:length() == 1 and use.to:contains(player) then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, player:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaDaji)
