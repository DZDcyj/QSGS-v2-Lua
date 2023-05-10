-- 始计篇-严包
-- Created by DZDcyj at 2023/2/27
module('extensions.LayingPlansStrictnessPackage', package.seeall)
extension = sgs.Package('LayingPlansStrictnessPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')
local rectification = require('extensions.RectificationPackage')

local function targetTrigger(self, target)
    return target
end

-- 朱儁
ExZhujun = sgs.General(extension, 'ExZhujun', 'qun', '4', true, true)

LuaYangjieCard = sgs.CreateSkillCard {
    name = 'LuaYangjie',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local target = targets[1]
        if source:pindian(target, self:objectName()) then
            return
        end
        local available_slashers = sgs.SPlayerList()
        local slash = sgs.Sanguosha:cloneCard('fire_slash')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:canSlash(target, slash, false) then
                available_slashers:append(p)
            end
        end
        slash:setSkillName('_LuaYangjie')
        if available_slashers:isEmpty() then
            return
        end
        local prompt = string.format('%s:%s', 'LuaYangjie-Choose', target:objectName())
        local slasher = room:askForPlayerChosen(source, available_slashers, self:objectName(), prompt, true)
        if slasher then
            room:useCard(sgs.CardUseStruct(slash, slasher, target))
        end
    end,
}

LuaYangjie = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaYangjie',
    view_as = function(self, cards)
        return LuaYangjieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaYangjie')
    end,
}

local function canInvokeLuaZhujunJuxiang(player, dying)
    return player:objectName() ~= dying.who:objectName() and player:getMark('@LuaZhujunJuxiang') > 0
end

-- 与界祝融【巨象】命名区分
LuaZhujunJuxiang = sgs.CreateTriggerSkill {
    name = 'LuaZhujunJuxiang',
    events = {sgs.QuitDying},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaZhujunJuxiang',
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local data2 = sgs.QVariant()
        data2:setValue(dying.who)
        if dying.who:isDead() then
            return false
        end
        for _, zhujun in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if canInvokeLuaZhujunJuxiang(zhujun, dying) and room:askForSkillInvoke(zhujun, self:objectName(), data2) then
                room:broadcastSkillInvoke(self:objectName())
                zhujun:loseMark('@LuaZhujunJuxiang')
                room:doAnimate(rinsan.ANIMATE_INDICATE, zhujun:objectName(), dying.who:objectName())
                rinsan.doDamage(zhujun, dying.who, 1)
                zhujun:drawCards(math.min(dying.who:getMaxHp(), 5), self:objectName())
            end
        end
        return false
    end,
    can_trigger = targetTrigger,
}

local function canInvokeLuaHoufeng(zhujun, player)
    return zhujun:getMark('LuaHoufeng-Clear') == 0 and zhujun:inMyAttackRange(player)
end

LuaHoufeng = sgs.CreateTriggerSkill {
    name = 'LuaHoufeng',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local data2 = sgs.QVariant()
        data2:setValue(player)
        for _, zhujun in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if canInvokeLuaHoufeng(zhujun, player) then
                if room:askForSkillInvoke(zhujun, self:objectName(), data2) then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:doAnimate(rinsan.ANIMATE_INDICATE, zhujun:objectName(), player:objectName())
                    rectification.askForRetification(zhujun, player, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getPhase() == sgs.Player_Play
    end,
}

ExZhujun:addSkill(LuaYangjie)
ExZhujun:addSkill(LuaZhujunJuxiang)
ExZhujun:addSkill(LuaHoufeng)
