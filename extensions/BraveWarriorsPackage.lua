-- 限定-百战虎贲包
-- Created by DZDcyj at 2023/5/4
module('extensions.BraveWarriorsPackage', package.seeall)
extension = sgs.Package('BraveWarriorsPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function targetTrigger(self, target)
    return target
end

-- 留赞
ExTenYearLiuzan = sgs.General(extension, 'ExTenYearLiuzan', 'wu', '4', true)

LuaFenyin = sgs.CreateTriggerSkill {
    name = 'LuaFenyin',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if room:getCurrent():objectName() == player:objectName() and player:hasSkill(self:objectName()) then
                if move.to_place == sgs.Player_DiscardPile then
                    for _, id in sgs.qlist(move.card_ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        if player:getMark(self:objectName() .. card:getSuitString()) == 0 then
                            room:sendCompulsoryTriggerLog(player, self:objectName())
                            room:broadcastSkillInvoke(self:objectName())
                            room:addPlayerMark(player, self:objectName() .. card:getSuitString())
                            player:drawCards(1, self:objectName())
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    rinsan.clearAllMarksContains(p, self:objectName())
                end
            end
        end
    end,
    can_trigger = targetTrigger,
}

LuaLijiCard = sgs.CreateSkillCard {
    name = 'LuaLijiCard',
    target_fixed = false,
    will_throw = true,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        room:broadcastSkillInvoke('LuaLiji')
        room:damage(sgs.DamageStruct(self:objectName(), source, target))
    end,
}

LuaLijiVS = sgs.CreateViewAsSkill {
    name = 'LuaLiji',
    n = 1,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = LuaLijiCard:clone()
            card:addSubcard(cards[1])
            return card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and player:usedTimes('#LuaLijiCard') < player:getMark('LuaLijiAvailableTimes')
    end,
}

LuaLiji = sgs.CreateTriggerSkill {
    name = 'LuaLiji',
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    view_as_skill = LuaLijiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then
                local count = room:alivePlayerCount()
                local multiple = 8
                if count < 5 then
                    multiple = 4
                end
                room:setPlayerMark(player, self:objectName() .. 'multiple', multiple)
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if room:getCurrent():objectName() == player:objectName() and player:hasSkill(self:objectName()) then
                if move.to_place == sgs.Player_DiscardPile then
                    room:addPlayerMark(player, self:objectName(), move.card_ids:length())
                    local multiple = player:getMark(self:objectName() .. 'multiple')
                    local markCount = math.modf(player:getMark(self:objectName()) / multiple)
                    if markCount > player:getMark('LuaLijiAvailableTimes') then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        room:setPlayerMark(player, 'LuaLijiAvailableTimes', markCount)
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    rinsan.clearAllMarksContains(p, self:objectName())
                end
            end
        end
    end,
    can_trigger = targetTrigger,
}

ExTenYearLiuzan:addSkill(LuaFenyin)
ExTenYearLiuzan:addSkill(LuaLiji)
