-- 群英荟萃-徐州风云
-- Created by DZDcyj at 2024/12/30
module('extensions.GatheringHeroesXuzhouPackage', package.seeall)
extension = sgs.Package('GatheringHeroesXuzhouPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- 曹嵩-十周年
ExTenYearCaosong = sgs.General(extension, 'ExTenYearCaosong', 'wei', '4', true, true)

local LuaLiluMark = '@LuaLiluGiveOut'

LuaLilu = sgs.CreateTriggerSkill {
    name = 'LuaLilu',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local diff = math.min(5, player:getMaxHp()) - player:getHandcardNum()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            if diff > 0 then
                player:drawCards(diff, self:objectName())
            end
            local maxCardCount = math.min(5, player:getHandcardNum())
            room:askForYiji(player, player:handCards(), self:objectName(), false, false, false, maxCardCount)
            return true
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Draw)
    end,
}

LuaLiluMaxHp = sgs.CreateTriggerSkill {
    name = 'LuaLiluMaxHp',
    events = {sgs.ChoiceMade},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local dataStr = data:toString():split(':')
        if dataStr[1] ~= 'Yiji' then
            return false
        end
        local prev = player:getMark(LuaLiluMark)
        local curr = #(dataStr[5]:split('+'))
        if curr > prev then
            rinsan.addPlayerMaxHp(player, 1)
        end
        room:setPlayerMark(player, LuaLiluMark, curr)
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaTenYearYizheng = sgs.CreateTriggerSkill {
    name = 'LuaTenYearYizheng',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_RoundStart then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark('LuaTenYearYizheng-' .. player:objectName()) > 0 then
                    room:removePlayerMark(p, '@LuaTenYearYizheng')
                end
                room:setPlayerMark(p, 'LuaTenYearYizheng-' .. player:objectName(), 0)
            end
            return false
        end
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
            'LuaTenYearYizheng-choose', true, true)
        if target then
            room:addPlayerMark(target, 'LuaTenYearYizheng-' .. player:objectName())
            target:gainMark('@LuaTenYearYizheng')
        end
        return false
    end,
    can_trigger = function(self, target)
        if rinsan.RIGHT(self, target) then
            local phase = target:getPhase()
            return phase == sgs.Player_Finish or phase == sgs.Player_RoundStart
        end
        return false
    end,
}

LuaTenYearYizhengInc = sgs.CreateTriggerSkill {
    name = 'LuaTenYearYizhengInc',
    events = {sgs.DamageCaused, sgs.PreHpRecover},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local caosongs = room:findPlayersBySkillName('LuaTenYearYizheng')
        for _, caosong in sgs.qlist(caosongs) do
            if player:getMark('LuaTenYearYizheng-' .. caosong:objectName()) > 0 then
                if player:getMaxHp() < caosong:getMaxHp() then
                    room:sendCompulsoryTriggerLog(caosong, 'LuaTenYearYizheng')
                    room:loseMaxHp(caosong)
                    if event == sgs.DamageCaused then
                        local damage = data:toDamage()
                        damage.damage = damage.damage + 1
                        data:setValue(damage)
                    else
                        local rec = data:toRecover()
                        rec.recover = rec.recover + 1
                        data:setValue(rec)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

ExTenYearCaosong:addSkill(LuaLilu)
ExTenYearCaosong:addSkill(LuaTenYearYizheng)

table.insert(hiddenSkills, LuaLiluMaxHp)
table.insert(hiddenSkills, LuaTenYearYizhengInc)

rinsan.addHiddenSkills(hiddenSkills)
