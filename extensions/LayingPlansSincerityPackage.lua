-- 始计篇-信包
-- Created by DZDcyj at 2023/2/25
module('extensions.LayingPlansSincerityPackage', package.seeall)
extension = sgs.Package('LayingPlansSincerityPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

local function globalTrigger(self, target)
    return true
end

local function targetTrigger(self, target)
    return target
end

-- 吴景
ExWujing = sgs.General(extension, 'ExWujing', 'wu', '4', true, true)

local function askForHeji(self, wujing, victim)
    local room = wujing:getRoom()
    local pattern = 'Slash,Duel|.'
    if wujing:getMark(self:objectName()) == 0 then
        local choices = {
            [1] = self:objectName() .. 'Slash',
            [2] = self:objectName() .. 'Duel',
            [3] = self:objectName() .. 'NoMoreHint',
            [4] = 'cancel',
        }
        local choice = room:askForChoice(wujing, self:objectName(), table.concat(choices, '+'))
        if choice == choices[3] then
            room:addPlayerMark(wujing, self:objectName())
        elseif choice ~= choices[4] then
            pattern = rinsan.firstToLower(string.gsub(choice, self:objectName(), ''))
        else
            return false
        end
    end
    local prompt = string.format('LuaHeji_ask:%s::%s', victim:objectName(), pattern)
    for _, cd in sgs.qlist(wujing:getCards('he')) do
        if wujing:isCardLimited(cd, sgs.Card_MethodUse) or room:isProhibited(wujing, victim, cd) then
            room:setCardFlag(cd, 'HejiDisabled')
            room:setPlayerCardLimitation(wujing, 'use, response', cd:toString(), false)
        end
    end
    local card = room:askForCard(wujing, pattern, prompt, sgs.QVariant(), sgs.Card_MethodResponse, nil, true)
    for _, cd in sgs.qlist(wujing:getCards('he')) do
        if cd:hasFlag('HejiDisabled') then
            room:setCardFlag(cd, '-HejiDisabled')
            room:removePlayerCardLimitation(wujing, 'use, response', cd:toString() .. '$0')
        end
    end
    if card then
        local card_use = sgs.CardUseStruct()
        card_use.card = card
        card_use.from = wujing
        card_use.to:append(victim)
        room:notifySkillInvoked(wujing, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        rinsan.skill(self, room, wujing, true)
        if not card:isVirtualCard() then
            local toObtain = rinsan.obtainCardFromPile(rinsan.isRedCard, room:getDrawPile())
            if not toObtain then
                toObtain = rinsan.obtainCardFromPile(rinsan.isRedCard, room:getDiscardPile())
            end
            if toObtain then
                room:obtainCard(wujing, toObtain, false)
            end
        end
        room:useCard(card_use)
    end
end

LuaHeji = sgs.CreateTriggerSkill {
    name = 'LuaHeji',
    events = {sgs.CardFinished},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.to:length() > 1 then
            return false
        end
        if use.card and ((use.card:isKindOf('Slash') and use.card:isRed()) or use.card:isKindOf('Duel')) then
            local victim = use.to:at(0)
            if not victim:isAlive() then
                return false
            end
            local wujings = room:findPlayersBySkillName(self:objectName())
            for _, wujing in sgs.qlist(wujings) do
                askForHeji(self, wujing, victim)
            end
        end
        return false
    end,
    can_trigger = targetTrigger,
}

LuaLiubing = sgs.CreateTriggerSkill {
    name = 'LuaLiubing',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:hasFlag('LuaLiubingInvoked') then
            return false
        end
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                card = data:toCardResponse().m_card
            end
        end
        if card and card:isKindOf('Slash') and (not card:isVirtualCard()) then
            room:setPlayerFlag(player, 'LuaLiubingInvoked')
            rinsan.sendLogMessage(room, '#LuaLiubingSuitChange', {
                ['from'] = player,
                ['card_str'] = card:toString(),
                ['arg2'] = card:toString(),
                ['arg'] = self:objectName(),
            })
            card:setSuit(sgs.Card_Diamond)
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                use.card = card
                data:setValue(use)
            else
                if data:toCardResponse().m_isUse then
                    local resp = data:toCardResponse()
                    resp.m_card = card
                    data:setValue(resp)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaLiubingObtain = sgs.CreateTriggerSkill {
    name = 'LuaLiubingObtain',
    global = true,
    events = {sgs.CardFinished, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local wujing = room:findPlayerBySkillName('LuaLiubing')
            if not wujing then
                return false
            end
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('Slash') and use.card:isBlack() and (not use.card:isVirtualCard()) then
                if use.card:hasFlag('LuaLiubingDamaged') or use.from:objectName() == wujing:objectName() then
                    return false
                end
                room:sendCompulsoryTriggerLog(wujing, 'LuaLiubing')
                room:obtainCard(wujing, use.card)
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf('Slash') and damage.card:isBlack() and
                (not damage.card:isVirtualCard()) then
                room:setCardFlag(damage.card, 'LuaLiubingDamaged');
            end
        end
    end,
    can_trigger = globalTrigger,
}

ExWujing:addSkill(LuaHeji)
ExWujing:addSkill(LuaLiubing)
SkillAnjiang:addSkill(LuaLiubingObtain)

-- 周处
ExZhouchu = sgs.General(extension, 'ExZhouchu', 'wu', '4', true, true)

LuaXianghai = sgs.CreateFilterSkill {
    name = 'LuaXianghai',
    view_filter = function(self, to_select)
        local room = sgs.Sanguosha:currentRoom()
        if room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand then
            return to_select:isKindOf('EquipCard')
        end
        return false
    end,
    view_as = function(self, card)
        local id = card:getId()
        local suit = card:getSuit()
        local number = card:getNumber()
        local analeptic = sgs.Sanguosha:cloneCard('analeptic', suit, number)
        analeptic:setSkillName('LuaXianghai')
        local vs_card = sgs.Sanguosha:getWrappedCard(id)
        vs_card:takeOver(analeptic)
        return vs_card
    end,
}

LuaXianghaiMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaXianghai',
    extra_func = function(self, target)
        local count = 0
        for _, sib in sgs.qlist(target:getAliveSiblings()) do
            if sib:hasSkill('LuaXianghai') then
                count = count - 1
            end
        end
        return count
    end,
}

LuaChuhaiCard = sgs.CreateSkillCard {
    name = 'LuaChuhaiCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0) and sgs.Self:canPindian(to_select, 'LuaChuhai')
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        source:drawCards(1, 'LuaChuhai')
        room:broadcastSkillInvoke('LuaChuhai', rinsan.random(1, 2))
        if source:pindian(target, 'LuaChuhai') then
            room:addPlayerMark(target, 'LuaChuhai')
            if target:isKongcheng() then
                return
            end
            room:showAllCards(target, source)
            local cardTypes = {}
            for _, cd in sgs.qlist(target:getHandcards()) do
                local typeStr = rinsan.firstToUpper(rinsan.replaceUnderline(cd:getType())) .. 'Card'
                if not table.contains(cardTypes, typeStr) then
                    table.insert(cardTypes, typeStr)
                end
            end
            local params = {
                ['findDiscardPile'] = true,
            }
            for _, cardType in ipairs(cardTypes) do
                params['type'] = cardType
                local toObtain = rinsan.obtainTargetedTypeCard(room, params)
                if toObtain then
                    room:obtainCard(source, toObtain, false)
                end
            end
        end
    end,
}

LuaChuhaiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaChuhai',
    view_as = function(self, cards)
        return LuaChuhaiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaChuhaiCard') and player:getMark(self:objectName() .. 'Wake') == 0
    end,
}

LuaChuhai = sgs.CreateTriggerSkill {
    name = 'LuaChuhai',
    events = {sgs.Damage},
    view_as_skill = LuaChuhaiVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (not damage.from) or damage.from:objectName() ~= player:objectName() then
            return false
        end
        if player:getMark('LuaChuhaiWake') > 0 then
            return false
        end
        if damage.to and damage.to:getMark(self:objectName()) > 0 then
            local equip_index = -1
            for i = 0, 4, 1 do
                if player:getEquip(i) == nil then
                    equip_index = i
                    break
                end
            end
            if equip_index ~= -1 then
                local type = rinsan.getEquipTypeStr(equip_index)
                local params = {
                    ['type'] = type,
                    ['findDiscardPile'] = true,
                }
                local equip = rinsan.obtainTargetedTypeCard(room, params)
                if equip then
                    room:broadcastSkillInvoke('LuaChuhai', rinsan.random(1, 2))
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:moveCardTo(equip, nil, player, sgs.Player_PlaceEquip, sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), ''), true)
                end
            end
        end
        return false
    end,
}

LuaChuhaiClear = sgs.CreateTriggerSkill {
    name = 'LuaChuhaiClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if data:toPhaseChange().to == sgs.Player_NotActive then
                room:setPlayerMark(p, 'LuaZhangming', 0)
            end
            room:setPlayerMark(p, 'LuaChuhai', 0)
        end
    end,
    can_trigger = globalTrigger,
}

LuaChuhaiWake = sgs.CreateTriggerSkill {
    name = 'LuaChuhaiWake',
    events = {sgs.Pindian, sgs.CardsMoveOneTime, sgs.PindianVerifying},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasSkill('LuaChuhai') and
                move.to_place == sgs.Player_PlaceEquip then
                if player:getMark('LuaChuhaiWake') > 0 then
                    return false
                end
                if player:getEquips():length() >= 3 then
                    rinsan.sendLogMessage(room, '#LuaChuhaiSuccess', {
                        ['from'] = player,
                        ['arg'] = player:getEquips():length(),
                        ['arg2'] = 'LuaChuhai',
                    })
                    room:broadcastSkillInvoke('LuaChuhai', rinsan.random(1, 2))
                    room:addPlayerMark(player, 'LuaChuhaiWake')
                    local toRecover = player:getMaxHp() - player:getHp()
                    if toRecover > 0 then
                        rinsan.recover(player, toRecover)
                    end
                    room:detachSkillFromPlayer(player, 'LuaXianghai')
                    room:acquireSkill(player, 'LuaZhangming')
                end
            end
        else
            local pindian = data:toPindian()
            if pindian.reason ~= 'LuaChuhai' then
                return false
            end
            if event == sgs.PindianVerifying then
                if pindian.from and pindian.from:hasSkill('LuaChuhai') then
                    local diff = math.max(4 - pindian.from:getEquips():length(), 0)
                    if diff == 0 or pindian.from_number == 13 then
                        return false
                    end
                    diff = math.min(13 - pindian.from_number, diff)
                    pindian.from_number = pindian.from_number + diff
                    rinsan.sendLogMessage(room, '#LuaChuhaiPindian', {
                        ['from'] = pindian.from,
                        ['arg'] = 'LuaChuhai',
                        ['arg2'] = diff,
                    })
                    data:setValue(pindian)
                end
            else
                if (not pindian.success) and pindian.from_number <= 6 then
                    rinsan.sendLogMessage(room, '#LuaChuhaiFailure', {
                        ['from'] = pindian.from,
                        ['arg'] = pindian.from_number,
                        ['arg2'] = 'LuaChuhai',
                    })
                    room:addPlayerMark(pindian.from, 'LuaChuhaiWake')
                    room:broadcastSkillInvoke('LuaChuhai', 3)
                end
            end
        end
        return false
    end,
    can_trigger = globalTrigger,
}

LuaZhangming = sgs.CreateTriggerSkill {
    name = 'LuaZhangming',
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardAsked, sgs.CardFinished, sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (not use.card) or (use.card:getSuit() ~= sgs.Card_Club) then
                return false
            end
            if (use.card:isKindOf('Slash') or use.card:isNDTrick()) and use.from:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                for _, p in sgs.qlist(use.to) do
                    room:addPlayerMark(p, 'LuaZhangmingTarget')
                end
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                use.from:setTag('LuaZhangmingSlash', sgs.QVariant(use.from:getTag('LuaZhangmingSlash'):toInt() + 1))
                if rinsan.RIGHT(self, use.from) and use.card:getSuit() == sgs.Card_Club then
                    local jink_table = sgs.QList2Table(use.from:getTag('Jink_' .. use.card:toString()):toIntList())
                    jink_table[use.from:getTag('LuaZhangmingSlash'):toInt() - 1] = 0
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    use.from:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and rinsan.RIGHT(self, effect.from) and effect.card and effect.card:getSuit() ==
                sgs.Card_Club then
                return true
            end
        elseif event == sgs.CardAsked then
            if player:getMark('LuaZhangmingTarget') > 0 then
                room:provide(nil)
                room:setPlayerMark(player, 'LuaZhangmingTarget', 0)
                return true
            end
        elseif event == sgs.Damage then
            if (not rinsan.RIGHT(self, player)) or player:getMark(self:objectName()) > 0 then
                return false
            end
            room:addPlayerMark(player, self:objectName())
            local victim = data:toDamage().to
            if player:objectName() == victim:objectName() then
                return false
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local card
            if not victim:isKongcheng() then
                local len = victim:getHandcardNum()
                card = victim:getHandcards():at(rinsan.random(0, len - 1))
                room:throwCard(card, victim)
            end
            local types = {'BasicCard', 'TrickCard', 'EquipCard'}
            for _, type in ipairs(types) do
                if (not card) or (not card:isKindOf(type)) then
                    local params = {
                        ['type'] = type,
                        ['findDiscardPile'] = true,
                    }
                    local togain = rinsan.obtainTargetedTypeCard(room, params)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(),
                        self:objectName(), '')
                    room:obtainCard(player, togain, reason, false)
                end
            end
        else
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                player:setTag('LuaZhangmingSlash', sgs.QVariant(0))
            end
            for _, p in sgs.qlist(use.to) do
                room:setPlayerMark(p, 'LuaZhangmingTarget', 0)
            end
        end
    end,
    can_trigger = targetTrigger,
}

LuaZhangmingDiscardLimit = sgs.CreateTriggerSkill {
    name = 'LuaZhangmingDiscardLimit',
    events = {sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard, sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.reason and move.reason.m_skillName == 'LuaZhangming' then
                if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
                    move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() then
                    for _, id in sgs.qlist(move.card_ids) do
                        room:addPlayerMark(player, 'LuaZhangming' .. id .. '-Clear')
                    end
                end
            end
            return false
        end
        if event == sgs.AskForGameruleDiscard then
            room:sendCompulsoryTriggerLog(player, 'LuaZhangming')
        end
        local n = room:getTag('DiscardNum'):toInt()
        for _, id in sgs.qlist(player:handCards()) do
            if player:getMark('LuaZhangming' .. id .. '-Clear') > 0 then
                if event == sgs.AskForGameruleDiscard then
                    n = n - 1
                    room:setPlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString(), false)
                else
                    room:removePlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString() .. '$0')
                end
            end
        end
        room:setTag('DiscardNum', sgs.QVariant(n))
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZhangming')
    end,
}

LuaZhangmingMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaZhangmingMaxCards',
    extra_func = function(self, target)
        local x = 0
        for _, cd in sgs.qlist(target:getHandcards()) do
            if target:getMark('LuaZhangming' .. cd:getId() .. '-Clear') > 0 then
                x = x + 1
            end
        end
        -- 迫真多余牌修正
        return target:getHandcardNum() > target:getHp() and 0 or x
    end,
}

ExZhouchu:addSkill(LuaXianghai)
ExZhouchu:addSkill(LuaChuhai)
ExZhouchu:addRelateSkill('LuaZhangming')
SkillAnjiang:addSkill(LuaXianghaiMaxCards)
SkillAnjiang:addSkill(LuaChuhaiClear)
SkillAnjiang:addSkill(LuaChuhaiWake)
SkillAnjiang:addSkill(LuaZhangming)
SkillAnjiang:addSkill(LuaZhangmingDiscardLimit)
SkillAnjiang:addSkill(LuaZhangmingMaxCards)

-- 神太史慈
ExShenTaishici = sgs.General(extension, 'ExShenTaishici', 'god', '4', true, true)

LuaDulie = sgs.CreateTriggerSkill {
    name = 'LuaDulie',
    events = {sgs.TargetConfirming},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            if use.from and use.from:getHp() > player:getHp() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local judge = rinsan.createJudgeStruct({
                    ['who'] = player,
                    ['reason'] = self:objectName(),
                    ['play_animation'] = true,
                    ['pattern'] = '.|heart',
                })
                room:judge(judge)
                if judge:isGood() then
                    local to_list = use.to
                    to_list:removeOne(player)
                    use.to = to_list
                    data:setValue(use)
                    local msgType = '$CancelTargetNoUser'
                    local params = {
                        ['to'] = player,
                        ['arg'] = use.card:objectName(),
                    }
                    if use.from then
                        params['from'] = use.from
                        msgType = '$CancelTarget'
                    end
                    rinsan.sendLogMessage(room, msgType, params)
                end
            end
        end
        return false
    end,
}

LuaPoweiCard = sgs.CreateSkillCard {
    name = 'LuaPoweiCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if self:subcardsLength() > 0 then
            return false
        end
        return to_select:getPhase() == sgs.Player_RoundStart and to_select:getHp() <= sgs.Self:getHp() and
                   (not to_select:isKongcheng())
    end,
    feasible = function(self, targets)
        if self:subcardsLength() > 0 then
            return #targets == 0
        elseif self:subcardsLength() == 0 then
            return #targets == 1
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaPowei', 1)
        local target = room:getCurrent()
        repeat
            if #targets > 0 then
                if target:isKongcheng() then
                    break
                end
                local card_id = room:askForCardChosen(source, target, 'h', 'LuaPowei', false, sgs.Card_MethodNone)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
                room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
            end
        until (true)
        local len = self:subcardsLength()
        if len > 0 then
            rinsan.doDamage(room, source, target, 1)
        end
        rinsan.addToAttackRange(room, target, source)
    end,
}

LuaPoweiVS = sgs.CreateViewAsSkill {
    name = 'LuaPowei',
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        local vs_card = LuaPoweiCard:clone()
        if #cards == 1 then
            vs_card:addSubcard(cards[1]:getId())
        end
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaPoweiHelper'
    end,
}

LuaPoweiHelper = sgs.CreateTriggerSkill {
    name = 'LuaPoweiHelper',
    events = {sgs.GameStart, sgs.Damaged, sgs.EventPhaseStart, sgs.EventPhaseChanging},
    global = true,
    view_as_skill = LuaPoweiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            local shentaishici = room:findPlayerBySkillName('LuaPowei')
            if (not shentaishici) or shentaishici:getMark('LuaPoweiStart') > 0 then
                return false
            end
            room:addPlayerMark(shentaishici, 'LuaPoweiStart')
            room:sendCompulsoryTriggerLog(shentaishici, 'LuaPowei')
            room:broadcastSkillInvoke('LuaPowei', 1)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if (not p:hasSkill('LuaPowei')) and p:getMark('LuaPoweiStart') == 0 then
                    p:gainMark('@LuaPowei', 1)
                    room:addPlayerMark(p, 'LuaPoweiStart')
                end
            end
        elseif event == sgs.Damaged then
            if player:getMark('@LuaPowei') > 0 then
                player:loseMark('@LuaPowei', player:getMark('@LuaPowei'))
            end
        elseif event == sgs.EventPhaseStart then
            if player:getMark('@LuaPowei') == 0 or player:getPhase() ~= sgs.Player_RoundStart then
                return false
            end
            local stscs = room:findPlayersBySkillName('LuaPowei')
            local _data = sgs.QVariant()
            _data:setValue(player)
            for _, stsc in sgs.qlist(stscs) do
                room:broadcastSkillInvoke('LuaPowei', 1)
                room:askForUseCard(stsc, '@@LuaPoweiHelper', 'LuaPowei_ask', -1, sgs.Card_MethodNone)
            end
        else
            if data:toPhaseChange().to == sgs.Player_NotActive then
                local stscs = room:findPlayersBySkillName('LuaPowei')
                for _, stsc in sgs.qlist(stscs) do
                    rinsan.removeFromAttackRange(room, player, stsc)
                end
                if player:hasSkill('LuaPowei') and player:getMark('LuaPowei') == 0 then
                    rinsan.moveLuaPoweiMark(room, player)
                end
            end
        end
        return false
    end,
    can_trigger = globalTrigger,
}

LuaPowei = sgs.CreateTriggerSkill {
    name = 'LuaPowei',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        rinsan.sendLogMessage(room, '#LuaPoweiSuccess', {
            ['from'] = player,
            ['arg'] = self:objectName(),
        })
        room:broadcastSkillInvoke('LuaPowei', 2)
        if room:changeMaxHpForAwakenSkill(player, 0) then
            room:acquireSkill(player, 'LuaShenzhu')
            room:addPlayerMark(player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        if target:getMark('LuaPowei') > 0 then
            return false
        end
        if target:getMark('@LuaPowei') > 0 then
            return false
        end
        for _, p in sgs.qlist(target:getSiblings()) do
            if p:getMark('@LuaPowei') > 0 then
                return false
            end
        end
        return rinsan.RIGHT(self, target) and rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_RoundStart)
    end,
}

LuaPoweiFailed = sgs.CreateTriggerSkill {
    name = 'LuaPoweiFailed',
    events = {sgs.EnterDying},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if not dying.who:hasSkill('LuaPowei') then
            return false
        end
        room:addPlayerMark(dying.who, 'LuaPowei')
        rinsan.sendLogMessage(room, '#LuaPoweiFailure', {
            ['from'] = player,
            ['arg'] = 'LuaPowei',
        })
        room:broadcastSkillInvoke('LuaPowei', 3)
        rinsan.recover(dying.who, 1 - dying.who:getHp(), player)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, '@LuaPowei', 0)
        end
        dying.who:throwAllEquips()
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaPowei') and target:getMark('LuaPowei') == 0
    end,
}

LuaShenzhu = sgs.CreateTriggerSkill {
    name = 'LuaShenzhu',
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local card = use.card
        if card and card:isKindOf('Slash') and (not card:isVirtualCard()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local choices = {string.format('%s1', self:objectName()), string.format('%s2', self:objectName())}
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
            if choice == choices[1] then
                -- 摸一牌、如果在出牌阶段多加一次出杀次数
                player:drawCards(1, self:objectName())
                if player:getPhase() == sgs.Player_Play then
                    room:addPlayerMark(player, self:objectName())
                end
            elseif choice == choices[2] then
                -- 摸三牌，然后本回合内不能用杀
                player:drawCards(3, self:objectName())
                room:addPlayerMark(player, 'LuaShenzhuForbid')
                room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.', true)
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target)
    end,
}

LuaShenzhuClear = sgs.CreateTriggerSkill {
    name = 'LuaShenzhuClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark('LuaShenzhuForbid') > 0 then
                    room:removePlayerCardLimitation(p, 'use', 'Slash|.|.|.$1')
                end
                rinsan.clearAllMarksContains(room, p, 'LuaShenzhu')
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaShenzhuTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaShenzhuTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:hasSkill('LuaShenzhu') then
            return player:getMark('LuaShenzhu')
        else
            return 0
        end
    end,
}

ExShenTaishici:addSkill(LuaDulie)
ExShenTaishici:addSkill(LuaPowei)
ExShenTaishici:addRelateSkill('LuaShenzhu')
SkillAnjiang:addSkill(LuaShenzhu)
SkillAnjiang:addSkill(LuaPoweiHelper)
SkillAnjiang:addSkill(LuaPoweiFailed)
SkillAnjiang:addSkill(LuaShenzhuClear)
SkillAnjiang:addSkill(LuaShenzhuTargetMod)

-- 神孙策
ExShenSunce = sgs.General(extension, 'ExShenSunce', 'god', 6, true, true, false, 1)

LuaYingbaCard = sgs.CreateSkillCard {
    name = 'LuaYingbaCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.LESS, 1) and to_select:getMaxHp() > 1
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke('LuaYingba')
        room:loseMaxHp(target)
        target:gainMark('@LuaPingding')
        room:loseMaxHp(source)
    end,
}

LuaYingbaTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaYingbaTargetMod',
    pattern = '.',
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill('LuaYingba') and to and to:getMark('@LuaPingding') > 0 then
            return 1000
        end
        return 0
    end,
}

LuaYingba = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaYingba',
    view_as = function(self)
        return LuaYingbaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaYingbaCard')
    end,
}

LuaFuhai = sgs.CreateTriggerSkill {
    name = 'LuaFuhai',
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardAsked},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (not use.from) or (not use.from:hasSkill(self:objectName())) then
                return false
            end
            if (not use.card) or use.card:isKindOf('SkillCard') then
                return false
            end
            local invoke = false
            for _, p in sgs.qlist(use.to) do
                if p:getMark('@LuaPingding') > 0 then
                    invoke = true
                    room:addPlayerMark(p, 'LuaFuhaiTarget')
                end
            end
            if invoke then
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(use.from, self:objectName())
                if use.from:getMark('LuaFuhaiDraw') < 2 then
                    use.from:drawCards(1, self:objectName())
                end
                if (use.card:isKindOf('Slash') or use.card:isNDTrick()) then
                    room:addPlayerMark(use.from, self:objectName() .. 'engine')
                    if use.from:getMark(self:objectName() .. 'engine') > 0 then
                        room:removePlayerMark(use.from, self:objectName() .. 'engine')
                    end
                end
            end
        elseif event == sgs.CardAsked then
            if player:getMark('LuaFuhaiTarget') > 0 then
                room:provide(nil)
                room:setPlayerMark(player, 'LuaFuhaiTarget', 0)
                return true
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                use.from:setTag('FuhaiSlash', sgs.QVariant(use.from:getTag('FuhaiSlash'):toInt() + 1))
                if rinsan.RIGHT(self, use.from) and player:getMark('@LuaPingding') > 0 then
                    local jink_table = sgs.QList2Table(use.from:getTag('Jink_' .. use.card:toString()):toIntList())
                    jink_table[use.from:getTag('FuhaiSlash'):toInt() - 1] = 0
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    use.from:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and rinsan.RIGHT(self, effect.from) and player:getMark('@LuaPingding') > 0 then
                return true
            end
        end
        return false
    end,
    can_trigger = targetTrigger,
}

LuaFuhaiDraw = sgs.CreateTriggerSkill {
    name = 'LuaFuhaiDraw',
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.reason and move.reason.m_skillName == 'LuaFuhai' and rinsan.RIGHT(self, player, 'LuaFuhai') then
            room:addPlayerMark(player, 'LuaFuhaiDraw', move.card_ids:length())
        end
    end,
    can_trigger = globalTrigger,
}

LuaFuhaiClear = sgs.CreateTriggerSkill {
    name = 'LuaFuhaiClear',
    events = {sgs.CardFinished, sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    local x = p:getMark('LuaFuhai')
                    if x > 0 then
                        room:removePlayerMark(p, 'LuaFuhai', x)
                    end
                    room:setPlayerMark(p, 'LuaFuhaiDraw', 0)
                end
            end
        else
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                player:setTag('FuhaiSlash', sgs.QVariant(0))
            end
            for _, p in sgs.qlist(use.to) do
                room:setPlayerMark(p, 'LuaFuhaiTarget', 0)
            end
        end
        return false
    end,
    can_trigger = globalTrigger,
}

LuaFuhaiDeath = sgs.CreateTriggerSkill {
    name = 'LuaFuhaiDeath',
    events = {sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:objectName() ~= data:toDeath().who:objectName() then
            return false
        end
        local x = player:getMark('@LuaPingding')
        if x <= 0 then
            return false
        end
        local splayers = room:findPlayersBySkillName('LuaFuhai')
        for _, sp in sgs.qlist(splayers) do
            room:sendCompulsoryTriggerLog(sp, 'LuaFuhai')
            sp:drawCards(x, 'LuaFuhai')
            rinsan.addPlayerMaxHp(sp, x)
        end
    end,
    can_trigger = globalTrigger,
}

LuaPingheCard = sgs.CreateSkillCard {
    name = 'LuaPingheCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:loseMaxHp(source)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        target:obtainCard(card, false)
    end,
}

LuaPingheVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaPinghe',
    view_filter = function(self, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, card)
        local pingheCard = LuaPingheCard:clone()
        pingheCard:addSubcard(card)
        return pingheCard
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaPinghe')
    end,
}

LuaPinghe = sgs.CreateTriggerSkill {
    name = 'LuaPinghe',
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = LuaPingheVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        -- 需要伤害来源，且伤害来源不为自己才可发动
        if (not damage.from) or damage.from:objectName() == player:objectName() then
            return false
        end
        if player:getMaxHp() > 1 and (not player:isKongcheng()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:askForUseCard(player, '@@LuaPinghe!', 'LuaPingheGive', -1, sgs.Card_MethodNone)
            if damage.from and player:hasSkill('LuaYingba') then
                damage.from:gainMark('@LuaPingding')
            end
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
    end,
}

LuaPingheMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaPingheMaxCards',
    fixed_func = function(self, target)
        if target:hasSkill('LuaPinghe') then
            return target:getLostHp()
        else
            return -1
        end
    end,
}

ExShenSunce:addSkill(LuaYingba)
SkillAnjiang:addSkill(LuaYingbaTargetMod)
ExShenSunce:addSkill(LuaFuhai)
SkillAnjiang:addSkill(LuaFuhaiDraw)
SkillAnjiang:addSkill(LuaFuhaiClear)
SkillAnjiang:addSkill(LuaFuhaiDeath)
ExShenSunce:addSkill(LuaPinghe)
SkillAnjiang:addSkill(LuaPingheMaxCards)

-- 羊祜
ExYanghu = sgs.General(extension, 'ExYanghu', 'qun', '3', true, true)

LuaMingfa = sgs.CreateTriggerSkill {
    name = 'LuaMingfa',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            local card = room:askForCard(player, '.|.|.|.|.', '@LuaMingfa-show', data, sgs.Card_MethodNone)
            if card then
                rinsan.skill(self, room, player, true)
                room:showCard(player, card:getEffectiveId())
                player:setTag('LuaMingfaCard', sgs.QVariant(card:getEffectiveId()))
            end
        elseif player:getPhase() == sgs.Player_Play then
            local pindian_card
            local tag = player:getTag('LuaMingfaCard')
            if tag then
                local id = tag:toInt()
                for _, cd in sgs.qlist(player:getCards('he')) do
                    if cd:getEffectiveId() == id then
                        pindian_card = cd
                        break
                    end
                end
            end
            if not pindian_card then
                player:removeTag('LuaMingfaCard')
                return false
            end
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canPindian(p, self:objectName()) then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then
                return false
            end
            local prompt = string.format('LuaMingfa-choose:%s::%s:%s', pindian_card:objectName(),
                pindian_card:getSuitString(), pindian_card:getNumberString())
            local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                if player:pindian(target, self:objectName(), pindian_card) then
                    if not target:isNude() then
                        local card_id = room:askForCardChosen(player, target, 'he', self:objectName(), false,
                            sgs.Card_MethodNone)
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                        room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                    end
                    local togain = rinsan.obtainSpecifiedCard(room, function(toCheck)
                        return toCheck:getNumber() == pindian_card:getNumber() - 1
                    end)
                    if togain then
                        room:obtainCard(player, togain)
                    end
                else
                    room:setPlayerFlag(player, 'LuaMingfaFailed')
                end
            end
            player:removeTag('LuaMingfaCard')
        end
        return false
    end,
}

LuaMingfaMod = sgs.CreateProhibitSkill {
    name = '#LuaMingfaMod',
    is_prohibited = function(self, from, to, card)
        if card:isKindOf('SkillCard') then
            return false
        end
        return from:objectName() ~= to:objectName() and from:hasFlag('LuaMingfaFailed')
    end,
}

LuaMingfaPindian = sgs.CreateTriggerSkill {
    name = 'LuaMingfaPindian',
    events = {sgs.PindianVerifying},
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if pindian.from:hasSkill('LuaMingfa') then
            local diff = math.min(2, 13 - pindian.from_number)
            if diff > 0 then
                rinsan.sendLogMessage(room, '#LuaMingfaPindian', {
                    ['from'] = pindian.from,
                    ['arg'] = 'LuaMingfa',
                    ['arg2'] = diff,
                })
                pindian.from_number = pindian.from_number + diff
            end
        end
        if pindian.to:hasSkill('LuaMingfa') then
            local diff = math.min(2, 13 - pindian.to_number)
            if diff > 0 then
                rinsan.sendLogMessage(room, '#LuaMingfaPindian', {
                    ['from'] = pindian.to,
                    ['arg'] = 'LuaMingfa',
                    ['arg2'] = diff,
                })
                pindian.to_number = pindian.to_number + diff
            end
        end
        data:setValue(pindian)
    end,
    can_trigger = globalTrigger,
}

LuaRongbeiCard = sgs.CreateSkillCard {
    name = 'LuaRongbei',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:getEquips():length() < 5
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        source:loseMark('@LuaRongbei')
        room:notifySkillInvoked(source, 'LuaRongbei')
        for index = 0, 4, 1 do
            if not target:getEquip(index) then
                local equip = rinsan.obtainSpecifiedCard(room, function(card)
                    return card:isKindOf(rinsan.getEquipTypeStr(index))
                end)
                if equip then
                    room:useCard(sgs.CardUseStruct(equip, target, target))
                end
            end
        end
    end,
}

LuaRongbeiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaRongbei',
    view_as = function(self, cards)
        return LuaRongbeiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaRongbei') > 0
    end,
}

LuaRongbei = sgs.CreateTriggerSkill {
    name = 'LuaRongbei',
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaRongbei',
    view_as_skill = LuaRongbeiVS,
    on_trigger = function()
    end,
}

ExYanghu:addSkill(LuaMingfa)
SkillAnjiang:addSkill(LuaMingfaMod)
SkillAnjiang:addSkill(LuaMingfaPindian)
ExYanghu:addSkill(LuaRongbei)
