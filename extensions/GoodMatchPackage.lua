-- 限定-锦瑟良缘包
-- Created by DZDcyj at 2023/5/4
module('extensions.GoodMatchPackage', package.seeall)
extension = sgs.Package('GoodMatchPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function globalTrigger(self, target)
    return true
end

-- 曹金玉
ExTenYearCaojinyu = sgs.General(extension, 'ExTenYearCaojinyu', 'wei', '3', false, true)

LuaYuqi = sgs.CreateTriggerSkill {
    name = 'LuaYuqi',
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local victim = data:toDamage().to
        for _, caojinyu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if rinsan.canInvokeYuqi(caojinyu, player) and room:askForSkillInvoke(caojinyu, self:objectName(), data) then
                room:addPlayerMark(caojinyu, 'LuaYuqiInvokeTime')
                room:broadcastSkillInvoke(self:objectName())

                local totalCount = rinsan.getYuqiPreviewCardCount(caojinyu)
                local giveCount = rinsan.getYuqiGiveCardCount(caojinyu)
                local keepCount = rinsan.getYuqiKeepCardCount(caojinyu)

                local _cjy = sgs.SPlayerList()
                _cjy:append(caojinyu)
                local yuqi_cards = room:getNCards(totalCount, false)
                local move = sgs.CardsMoveStruct(yuqi_cards, nil, caojinyu, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, caojinyu:objectName(), self:objectName(),
                        nil))
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, _cjy)
                room:notifyMoveCards(false, moves, false, _cjy)
                local origin_yuqi = sgs.IntList()
                for _, id in sgs.qlist(yuqi_cards) do
                    origin_yuqi:append(id)
                end
                local tos = sgs.SPlayerList()
                tos:append(victim)
                if victim:isAlive() and
                    room:askForYiji(caojinyu, yuqi_cards, self:objectName(), true, false, true, giveCount, tos,
                        sgs.CardMoveReason(), string.format('LuaYuqiGiveOut:%s:%s', victim:objectName(), giveCount)) then
                    local _reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, caojinyu:objectName(),
                        self:objectName(), nil)
                    move = sgs.CardsMoveStruct(sgs.IntList(), caojinyu, nil, sgs.Player_PlaceHand,
                        sgs.Player_PlaceTable, _reason)
                    for _, id in sgs.qlist(origin_yuqi) do
                        if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                            move.card_ids:append(id)
                            yuqi_cards:removeOne(id)
                        end
                    end
                    origin_yuqi = sgs.IntList()
                    for _, id in sgs.qlist(yuqi_cards) do
                        origin_yuqi:append(id)
                    end
                    moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _cjy)
                    room:notifyMoveCards(false, moves, false, _cjy)
                    if not caojinyu:isAlive() then
                        return
                    end
                end
                local selfs = sgs.SPlayerList()
                selfs:append(caojinyu)
                if room:askForYiji(caojinyu, yuqi_cards, self:objectName(), true, false, true, keepCount, selfs,
                    sgs.CardMoveReason(), string.format('LuaYuqiKeep:%d', keepCount)) then
                    local _reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, caojinyu:objectName(),
                        self:objectName(), nil)
                    move = sgs.CardsMoveStruct(sgs.IntList(), caojinyu, nil, sgs.Player_PlaceHand,
                        sgs.Player_PlaceTable, _reason)
                    for _, id in sgs.qlist(origin_yuqi) do
                        if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                            move.card_ids:append(id)
                            yuqi_cards:removeOne(id)
                        end
                    end
                    origin_yuqi = sgs.IntList()
                    for _, id in sgs.qlist(yuqi_cards) do
                        origin_yuqi:append(id)
                    end
                    moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _cjy)
                    room:notifyMoveCards(false, moves, false, _cjy)
                    if not caojinyu:isAlive() then
                        return
                    end
                end
                if not yuqi_cards:isEmpty() then
                    move = sgs.CardsMoveStruct(yuqi_cards, caojinyu, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, '', self:objectName(), nil))
                    moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _cjy)
                    room:notifyMoveCards(false, moves, false, _cjy)
                    room:returnToTopDrawPile(yuqi_cards)
                end
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaYuqiClear = sgs.CreateTriggerSkill {
    name = 'LuaYuqiClear',
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, 'LuaYuqiInvokeTime', 0)
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaShanshen = sgs.CreateTriggerSkill {
    name = 'LuaShanshen',
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if rinsan.canIncreaseNumber(sp) and room:askForSkillInvoke(sp, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                rinsan.askForYuqiIncreaseChoice(sp, 2, self:objectName())
                if death.who:getMark(string.format('LuaDamagedBy%s', sp:objectName())) == 0 then
                    rinsan.recover(sp)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

LuaXianjing = sgs.CreateTriggerSkill {
    name = 'LuaXianjing',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if rinsan.canIncreaseNumber(player) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            rinsan.askForYuqiIncreaseChoice(player, 1, self:objectName())
            if not player:isWounded() then
                rinsan.askForYuqiIncreaseChoice(player, 1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_RoundStart)
    end,
}

ExTenYearCaojinyu:addSkill(LuaYuqi)
ExTenYearCaojinyu:addSkill(LuaShanshen)
ExTenYearCaojinyu:addSkill(LuaXianjing)
rinsan.addSingleHiddenSkill(LuaYuqiClear)
