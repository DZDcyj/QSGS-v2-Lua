-- 神·武包
-- Created by DZDcyj at 2023/2/14
module('extensions.DevineForcePackage', package.seeall)
extension = sgs.Package('DevineForcePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

local function globalTrigger(self, target)
    return true
end

-- 神姜维
ExTenYearShenJiangwei = sgs.General(extension, 'ExTenYearShenJiangwei', 'god', '4', true, true)

LuaTianren = sgs.CreateTriggerSkill {
    name = 'LuaTianren',
    events = {sgs.CardsMoveOneTime, sgs.MarkChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then
                return false
            end
            if rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_USE) then
                return false
            end
            local markCount = 0
            for _, id in sgs.qlist(move.card_ids) do
                local curr_card = sgs.Sanguosha:getCard(id)
                if curr_card:isKindOf('BasicCard') or curr_card:isNDTrick() then
                    markCount = markCount + 1
                end
            end
            if markCount == 0 then
                return false
            end
            rinsan.sendLogMessage(room, '#LuaTianren', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['arg2'] = markCount,
            })
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, '@LuaTianren', markCount)
        else
            local mark = data:toMark()
            if mark.name == '@LuaTianren' and mark.gain and mark.who:hasSkill(self:objectName()) then
                if mark.who:getMark(self:objectName() .. 'engine') == 0 then
                    room:addPlayerMark(mark.who, self:objectName() .. 'engine')
                    while mark.who:getMark('@LuaTianren') >= mark.who:getMaxHp() do
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        local x = mark.who:getMaxHp()
                        room:removePlayerMark(mark.who, '@LuaTianren', x)
                        rinsan.addPlayerMaxHp(mark.who, 1)
                        mark.who:drawCards(2, self:objectName())
                    end
                    room:removePlayerMark(mark.who, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}

LuaJiufa = sgs.CreateTriggerSkill {
    name = 'LuaJiufa',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or card:isKindOf('SkillCard') then
            return false
        end
        local tag = player:getTag('LuaJiufaCards')
        local str = ''
        if tag then
            str = tag:toString()
        end
        local jiufa_cards = str:split('|')
        if not table.contains(jiufa_cards, card:objectName()) then
            table.insert(jiufa_cards, card:objectName())
        end
        if #jiufa_cards >= 9 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local ids = room:getNCards(9)
                room:fillAG(ids)
                local to_get = sgs.IntList()
                local to_throw = sgs.IntList()
                local numberTable = {}
                for i = 1, 13, 1 do
                    numberTable[i] = 0
                end
                for _, id in sgs.qlist(ids) do
                    local curr = sgs.Sanguosha:getCard(id)
                    numberTable[curr:getNumber()] = numberTable[curr:getNumber()] + 1
                end
                for number, count in ipairs(numberTable) do
                    if count == 1 then
                        for _, id in sgs.qlist(ids) do
                            local curr = sgs.Sanguosha:getCard(id)
                            if curr:getNumber() == number then
                                ids:removeOne(id)
                                to_throw:append(id)
                                room:takeAG(nil, id, false)
                            end
                        end
                    end
                end
                while not ids:isEmpty() do
                    local card_id = room:askForAG(player, ids, false, self:objectName())
                    local card_number = sgs.Sanguosha:getCard(card_id):getNumber()
                    to_get:append(card_id)
                    ids:removeOne(card_id)
                    room:takeAG(player, card_id, false)
                    local _card_ids = sgs.IntList()
                    -- 深拷贝
                    for _, id in sgs.qlist(ids) do
                        _card_ids:append(id)
                    end
                    for _, id in sgs.qlist(_card_ids) do
                        local c = sgs.Sanguosha:getCard(id)
                        if c:getNumber() == card_number then
                            ids:removeOne(id)
                            room:takeAG(nil, id, false)
                            to_throw:append(id)
                        end
                    end
                end
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                if not to_get:isEmpty() then
                    dummy:addSubcards(rinsan.getCardList(to_get))
                    player:obtainCard(dummy)
                end
                dummy:clearSubcards()
                if not to_throw:isEmpty() then
                    dummy:addSubcards(rinsan.getCardList(to_throw))
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                        self:objectName(), '')
                    room:throwCard(dummy, reason, nil)
                end
                dummy:deleteLater()
                room:clearAG()
                player:removeTag('LuaJiufaCards')
                room:setPlayerMark(player, '@LuaJiufa', 0)
                return false
            end
        end
        player:setTag('LuaJiufaCards', sgs.QVariant(table.concat(jiufa_cards, '|')))
        room:setPlayerMark(player, '@LuaJiufa', #jiufa_cards)
        return false
    end,
}

LuaPingxiangCard = sgs.CreateSkillCard {
    name = 'LuaPingxiang',
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        local fire_slash = sgs.Sanguosha:cloneCard('fire_slash', sgs.Card_NoSuit, 0)
        local total_num = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, fire_slash) + 1
        return sgs.Self:canSlash(to_select, fire_slash) and #targets < total_num
    end,
    on_use = function(self, room, source, targets)
        if not source:hasFlag('LuaPingxiang-Invoking') then
            source:loseMark('@LuaPingxiang')
            room:detachSkillFromPlayer(source, 'LuaJiufa')
            room:loseMaxHp(source, 9)
            room:addPlayerMark(source, 'LuaPingxiangInvoked')
        end
        room:addPlayerMark(source, 'LuaPingxiang')
        local target_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            target_list:append(target)
        end
        local fire_slash = sgs.Sanguosha:cloneCard('fire_slash', sgs.Card_NoSuit, 0)
        fire_slash:setSkillName(self:objectName())
        room:useCard(sgs.CardUseStruct(fire_slash, source, target_list), false)
        room:setPlayerFlag(source, 'LuaPingxiang-Invoking')
        local use = room:askForUseCard(source, '@@LuaPingxiang',
            '@LuaPingxiang-invoke:::' .. (9 - source:getMark('LuaPingxiang')))
        if not use then
            room:setPlayerMark(source, 'LuaPingxiang', 0)
            room:setPlayerFlag(source, '-LuaPingxiang-Invoking')
        end
    end,
}

LuaPingxiangVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaPingxiang',
    view_as = function(self, cards)
        return LuaPingxiangCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaPingxiang') > 0 and player:getMaxHp() > 9
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == '@@LuaPingxiang' and target:getMark('LuaPingxiang') < 9
    end,
}

LuaPingxiang = sgs.CreateTriggerSkill {
    name = 'LuaPingxiang',
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaPingxiang',
    view_as_skill = LuaPingxiangVS,
    on_trigger = function()
    end,
}

LuaPingxiangMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaPingxiangMaxCards',
    fixed_func = function(self, target)
        if target:getMark('LuaPingxiangInvoked') > 0 then
            return target:getMaxHp()
        end
        return -1
    end,
}

ExTenYearShenJiangwei:addSkill(LuaTianren)
ExTenYearShenJiangwei:addSkill(LuaJiufa)
ExTenYearShenJiangwei:addSkill(LuaPingxiang)
SkillAnjiang:addSkill(LuaPingxiangMaxCards)

-- 神张飞
ExTenYearShenZhangfei = sgs.General(extension, 'ExTenYearShenZhangfei', 'god', '4', true, true)

LuaShencaiCard = sgs.CreateSkillCard {
    name = 'LuaShencai',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local victim = targets[1]
        local judge = rinsan.createJudgeStruct({
            ['play_animation'] = true,
            ['who'] = victim,
            ['reason'] = self:objectName(),
        })
        room:judge(judge)
        local desc = judge.card:getDescription()
        source:obtainCard(judge.card)
        rinsan.clearShencaiMark(victim)
        rinsan.shencaiEffect(source, victim, desc)
    end,
}

LuaShencaiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaShencai',
    view_as = function(self)
        return LuaShencaiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#LuaShencai') < 1 + player:getMark('LuaXunshiAdd')
    end,
}

LuaShencai = sgs.CreateTriggerSkill {
    name = 'LuaShencai',
    events = {sgs.Damaged, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.SlashProceed},
    global = true,
    view_as_skill = LuaShencaiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if player:getMark('@LuaShencai-Chi') > 0 and damage.damage > 0 then
                rinsan.sendLogMessage(room, '#LuaShencai-Chi', {
                    ['from'] = player,
                    ['arg'] = damage.damage,
                    ['arg2'] = '@LuaShencai-Chi',
                })
                room:loseHp(player, damage.damage)
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                if player:getMark('@LuaShencai-Death') > room:alivePlayerCount() then
                    rinsan.sendLogMessage(room, '#LuaShencai-Death', {
                        ['from'] = player,
                        ['arg'] = '@LuaShencai-Death',
                    })
                    room:killPlayer(player)
                end
                if player:getMark('@LuaShencai-Liu') > 0 then
                    rinsan.sendLogMessage(room, '#LuaShencai-Liu', {
                        ['from'] = player,
                        ['arg'] = '@LuaShencai-Liu',
                    })
                    player:turnOver()
                end
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.to:getMark('@LuaShencai-Zhang') > 0 then
                rinsan.sendLogMessage(room, '#LuaShencai-Zhang', {
                    ['from'] = effect.to,
                    ['arg'] = '@LuaShencai-Zhang',
                })
                room:slashResult(effect, nil)
                return true
            end
        else
            local move = data:toMoveOneTime()
            if player:getMark('@LuaShencai-Tu') > 0 then
                if rinsan.lostCard(move, player) and move.from_places:contains(sgs.Player_PlaceHand) then
                    if move.reason.m_skillName ~= self:objectName() then
                        if not player:isKongcheng() then
                            rinsan.sendLogMessage(room, '#LuaShencai-Tu', {
                                ['from'] = player,
                                ['arg'] = '@LuaShencai-Tu',
                            })
                            local len = player:getHandcardNum()
                            local card = player:getHandcards():at(rinsan.random(0, len - 1))
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(),
                                self:objectName(), '')
                            room:throwCard(card, reason, player)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = globalTrigger,
}

LuaShencaiMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaShencaiMaxCards',
    extra_func = function(self, target)
        return -target:getMark('@LuaShencai-Death')
    end,
}

LuaXunshi = sgs.CreateFilterSkill {
    name = 'LuaXunshi',
    view_filter = function(self, to_select)
        if to_select:isKindOf('IronChain') then
            return true
        end
        return to_select:getSubtype() == 'global_effect' or to_select:getSubtype() == 'aoe'

    end,
    view_as = function(self, card)
        local id = card:getId()
        local number = card:getNumber()
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, number)
        slash:setSkillName(self:objectName())
        local vs_card = sgs.Sanguosha:getWrappedCard(id)
        vs_card:takeOver(slash)
        return vs_card
    end,
}

LuaXunshiTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaXunshiTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = '.|no_suit',
    residue_func = function(self, player)
        if player:hasSkill('LuaXunshi') then
            return 10000
        end
        return 0
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill('LuaXunshi') then
            return 10000
        end
        return 0
    end,
    extra_target_func = function(self, from)
        if from:hasSkill('LuaXunshi') then
            return 10000
        end
        return 0
    end,
}

LuaXunshiUsed = sgs.CreateTriggerSkill {
    name = 'LuaXunshiUsed',
    events = {sgs.CardUsed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf('SkillCard') then
            return false
        end
        if player:getMark('LuaXunshiAdd') >= 4 then
            return false
        end
        if use.card:getSuit() == sgs.Card_NoSuit then
            room:addPlayerMark(player, 'LuaXunshiAdd')
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaXunshi')
    end,
}

ExTenYearShenZhangfei:addSkill(LuaShencai)
SkillAnjiang:addSkill(LuaShencaiMaxCards)
ExTenYearShenZhangfei:addSkill(LuaXunshi)
SkillAnjiang:addSkill(LuaXunshiTargetMod)
SkillAnjiang:addSkill(LuaXunshiUsed)
