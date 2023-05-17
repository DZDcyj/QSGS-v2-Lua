-- 限定-高山仰止包
-- Created by DZDcyj at 2023/5/2

module('extensions.BeholdHighMountainPackage', package.seeall)
extension = sgs.Package('BeholdHighMountainPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 王朗
ExTenYearWanglang = sgs.General(extension, 'ExTenYearWanglang', 'wei', '3', true)

LuaGusheCard = sgs.CreateSkillCard {
    name = 'LuaGusheCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        return #selected < 3 and sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        local from_id = self:getSubcards():first()
        room:broadcastSkillInvoke('LuaGushe')
        room:notifySkillInvoked(source, 'LuaGushe')
        -- 只有一个目标直接可以使用 pindian 方法
        if #targets == 1 then
            room:setPlayerFlag(source, 'LuaGusheSingleTarget')
            source:pindian(targets[1], 'LuaGushe', sgs.Sanguosha:getCard(from_id))
            return
        end
        local get_id = rinsan.obtainIdFromAskForPindianCardEvent(source)
        if get_id ~= -1 then
            from_id = get_id
        end
        local from_card = sgs.Sanguosha:getCard(from_id)
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:addSubcard(from_card)
        local moves = sgs.CardsMoveList()
        local move = sgs.CardsMoveStruct(from_id, source, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, source:objectName(), 'LuaGushe', ''))
        moves:append(move)
        for _, p in ipairs(targets) do
            -- 此处同理，响应天辩等
            local ask_id = rinsan.obtainIdFromAskForPindianCardEvent(p)
            local card, to_move, to_slash
            if ask_id == -1 then
                card = room:askForExchange(p, 'LuaGushe', 1, 1, false, '@LuaGushePindian')
                to_move = card:getSubcards()
                to_slash = to_move:first()
            else
                card = ask_id
                to_move = card
                to_slash = card
            end
            slash:addSubcard(to_slash)
            room:setPlayerMark(p, 'LuaGusheId', to_slash + 1)
            local _move = sgs.CardsMoveStruct(to_move, p, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, p:objectName(), 'LuaGushe', ''))
            moves:append(_move)
        end

        -- 将拼点所用卡牌置入处理区
        room:moveCardsAtomic(moves, true)
        for i = 1, #targets, 1 do
            local pindian = sgs.PindianStruct()
            pindian.from = source
            pindian.to = targets[i]
            pindian.from_card = from_card
            pindian.to_card = sgs.Sanguosha:getCard(targets[i]:getMark('LuaGusheId') - 1)
            pindian.from_number = pindian.from_card:getNumber()
            pindian.to_number = pindian.to_card:getNumber()
            pindian.reason = 'LuaGushe'
            room:setPlayerMark(targets[i], 'LuaGusheId', 0)
            local data = sgs.QVariant()
            data:setValue(pindian)
            rinsan.sendLogMessage(room, '$PindianResult', {
                ['from'] = pindian.from,
                ['card_str'] = pindian.from_card:toString(),
            })
            rinsan.sendLogMessage(room, '$PindianResult', {
                ['from'] = pindian.to,
                ['card_str'] = pindian.to_card:toString(),
            })
            -- 依次触发对应的拼点修改阶段，例如【天辩】会在此时触发
            room:getThread():trigger(sgs.PindianVerifying, room, source, data)
            room:getThread():trigger(sgs.PindianVerifying, room, targets[i], data)

            -- 触发拼点结果阶段
            room:getThread():trigger(sgs.Pindian, room, source, data)
        end
        local subs = sgs.IntList()
        for _, cd in sgs.qlist(slash:getSubcards()) do
            if room:getCardPlace(cd) == sgs.Player_PlaceTable then
                subs:append(cd)
            end
        end

        -- 拼点时用的卡牌会移动到处理区，在这里将其置入弃牌堆
        local move2 = sgs.CardsMoveStruct(subs, nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, 'LuaGushe', ''))
        room:moveCardsAtomic(move2, true)
    end,
}

LuaGusheVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaGushe',
    view_filter = function(self, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, card)
        local vs_card = LuaGusheCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and player:getMark('LuaGusheWin') < 7 - player:getMark('@LuaGushe')
    end,
}

LuaGushe = sgs.CreateTriggerSkill {
    name = 'LuaGushe',
    events = {sgs.MarkChanged, sgs.EventPhaseChanging, sgs.Pindian},
    view_as_skill = LuaGusheVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.MarkChanged then
            local mark = data:toMark()
            if mark.name == '@LuaGushe' then
                if player:getMark(mark.name) >= 7 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:killPlayer(player)
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                room:setPlayerMark(player, 'LuaGusheWin', 0)
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason ~= self:objectName() then
                return false
            end
            pindian.success = pindian.from_number > pindian.to_number
            local loser = pindian.from
            if pindian.success then
                room:addPlayerMark(pindian.from, 'LuaGusheWin')
                loser = pindian.to
                if not pindian.from:hasFlag('LuaGusheSingleTarget') then
                    rinsan.sendLogMessage(room, '#PindianSuccess', {
                        ['from'] = pindian.from,
                        ['to'] = pindian.to,
                    })
                else
                    room:setPlayerFlag(pindian.from, '-LuaGusheSingleTarget')
                end
            else
                if not pindian.from:hasFlag('LuaGusheSingleTarget') then
                    rinsan.sendLogMessage(room, '#PindianFailure', {
                        ['from'] = pindian.from,
                        ['to'] = pindian.to,
                    })
                else
                    room:setPlayerFlag(pindian.from, '-LuaGusheSingleTarget')
                end
                pindian.from:gainMark('@LuaGushe')
            end
            -- 单独处理同点数问题
            if pindian.from_number == pindian.to_number then
                if not room:askForDiscard(pindian.to, 'LuaGushe', 1, 1, true, true,
                    '@LuaGusheDiscard:' .. pindian.from:objectName()) then
                    pindian.from:drawCards(1, self:objectName())
                end
            end
            -- 该处代码只让拼点失败方选择，若点数相同，则失败方为己方，故使用上面代码额外处理
            if not room:askForDiscard(loser, 'LuaGushe', 1, 1, true, true,
                '@LuaGusheDiscard:' .. pindian.from:objectName()) then
                pindian.from:drawCards(1, self:objectName())
            end
        end
    end,
}

LuaJici = sgs.CreateTriggerSkill {
    name = 'LuaJici',
    events = {sgs.PindianVerifying, sgs.Death},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            local obtained
            if pindian.from:hasSkill(self:objectName()) then
                if pindian.from_number <= pindian.from:getMark('@LuaGushe') then
                    room:sendCompulsoryTriggerLog(pindian.from, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    pindian.from_number = pindian.from_number + pindian.from:getMark('@LuaGushe')
                    rinsan.getBackPindianCardByJici(pindian, true)
                    obtained = true
                end
            end
            if pindian.to:hasSkill(self:objectName()) then
                if pindian.to_number <= pindian.to:getMark('@LuaGushe') then
                    room:sendCompulsoryTriggerLog(pindian.to, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    pindian.to_number = pindian.to_number + pindian.to:getMark('@LuaGushe')
                    if not obtained then
                        rinsan.getBackPindianCardByJici(pindian, false)
                    end
                end
            end
            data:setValue(pindian)
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() or not player:hasSkill(self:objectName()) then
                return false
            end
            if death.damage then
                if death.damage.from then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), death.damage.from:objectName())
                    local x = 7 - player:getMark('@LuaGushe')
                    x = math.min(death.damage.from:getCardCount(true), x)
                    if x > 0 then
                        room:askForDiscard(death.damage.from, self:objectName(), x, x, false, true)
                    end
                    room:loseHp(death.damage.from)
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

ExTenYearWanglang:addSkill(LuaGushe)
ExTenYearWanglang:addSkill(LuaJici)
