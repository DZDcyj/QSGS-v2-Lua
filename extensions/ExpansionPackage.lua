-- 扩展武将包
-- Created by DZDcyj at 2021/8/15

module('extensions.ExpansionPackage', package.seeall)
extension = sgs.Package('ExpansionPackage')

-- 引入封装函数包
local rinsanFuncModule = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)
ExWangyuanji = sgs.General(extension, 'ExWangyuanji', 'wei', '3', false)

LuaQianchong =
    sgs.CreateTriggerSkill {
    name = 'LuaQianchong',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                room:setPlayerMark(player, 'LuaQianchongCard', 0)
                if player:getMark(self:objectName()) == 0 then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    local choice = room:askForChoice(player, self:objectName(), 'BasicCard+TrickCard+EquipCard')
                    rinsanFuncModule.sendLogMessage(room, '#LuaQianchongChoice', {['from'] = player, ['arg'] = choice})
                    if choice == 'BasicCard' then
                        room:setPlayerMark(player, 'LuaQianchongCard', 1)
                    elseif choice == 'TrickCard' then
                        room:setPlayerMark(player, 'LuaQianchongCard', 2)
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if
                ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) or
                    (move.from and move.from:objectName() == player:objectName()) and
                        move.from_places:contains(sgs.Player_PlaceEquip))
             then
                room:setPlayerMark(player, self:objectName(), 0)
                local type = 0 -- 0: not match 1: all red 2: all black
                for _, card in sgs.qlist(player:getEquips()) do
                    if card:isRed() then
                        if type == 0 then
                            type = 1
                        elseif type == 2 then
                            type = 0
                            break
                        end
                    elseif card:isBlack() then
                        if type == 0 then
                            type = 2
                        elseif type == 1 then
                            type = 0
                            break
                        end
                    end
                end
                if type == 1 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:handleAcquireDetachSkills(player, '-LuaWeimu|LuaMingzhe')
                    room:setPlayerMark(player, self:objectName(), 1)
                elseif type == 2 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:handleAcquireDetachSkills(player, 'LuaWeimu|-LuaMingzhe')
                    room:setPlayerMark(player, self:objectName(), 2)
                else
                    if player:hasSkill('LuaWeimu') or player:hasSkill('LuaMingzhe') then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                    end
                    room:handleAcquireDetachSkills(player, '-LuaWeimu|-LuaMingzhe')
                end
            end
        end
        return false
    end
}

LuaQianchongBasicCardTargetMod =
    sgs.CreateTargetModSkill {
    name = '#LuaQianchongBasicCardTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'BasicCard',
    residue_func = function(self, player)
        if player:hasSkill('LuaQianchong') and player:getMark('LuaQianchongCard') == 1 then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaQianchong') and from:getMark('LuaQianchongCard') == 1 then
            return 1000
        else
            return 0
        end
    end
}

LuaQianchongTrickCardTargetMod =
    sgs.CreateTargetModSkill {
    name = '#LuaQianchongTrickCardTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'TrickCard',
    residue_func = function(self, player)
        if player:hasSkill('LuaQianchong') and player:getMark('LuaQianchongCard') == 2 then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaQianchong') and from:getMark('LuaQianchongCard') == 2 then
            return 1000
        else
            return 0
        end
    end
}

LuaWeimu =
    sgs.CreateProhibitSkill {
    name = 'LuaWeimu',
    is_prohibited = function(self, from, to, card)
        return to:hasSkill(self:objectName()) and card:isKindOf('TrickCard') and card:isBlack()
    end
}

LuaMingzhe =
    sgs.CreateTriggerSkill {
    name = 'LuaMingzhe',
    frequency = sgs.Skill_Frequent,
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_NotActive then
            return false
        end
        if event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not move.from or move.from:objectName() ~= player:objectName() then
                return false
            end
            if event == sgs.BeforeCardsMove then
                local reason = move.reason
                if rinsanFuncModule.moveBasicReasonCompare(reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) then
                    local card
                    local i = 0
                    for _, id in sgs.qlist(move.card_ids) do
                        card = sgs.Sanguosha:getCard(id)
                        if
                            room:getCardOwner(id):objectName() == player:objectName() and card:isRed() and
                                move.from_places:at(i) == sgs.Player_PlaceHand or
                                move.from_places:at(i) == sgs.Player_PlaceEquip
                         then
                            player:addMark(self:objectName())
                        end
                        i = i + 1
                    end
                end
            else
                local n = player:getMark(self:objectName())
                local i = 0
                while i < n do
                    i = i + 1
                    player:removeMark(self:objectName())
                    if player:isAlive() and player:askForSkillInvoke(self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName())
                        player:drawCards(1, self:objectName())
                    else
                        break
                    end
                end
                player:setMark(self:objectName(), 0)
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:isRed() and player:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(1, self:objectName())
            end
        end
        return false
    end
}

LuaShangjian =
    sgs.CreateTriggerSkill {
    name = 'LuaShangjian',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) then
                if
                    (move.from and (move.from:objectName() == player:objectName()) and
                        (move.from_places:contains(sgs.Player_PlaceHand) or
                            move.from_places:contains(sgs.Player_PlaceEquip))) and
                        not (move.to and
                            (move.to:objectName() == player:objectName() and
                                (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
                 then
                    room:addPlayerMark(player, '@' .. self:objectName(), move.card_ids:length())
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self:objectName()) then
                        local x = p:getMark('@' .. self:objectName())
                        if x > 0 then
                            if x <= p:getHp() then
                                room:sendCompulsoryTriggerLog(p, self:objectName())
                                room:broadcastSkillInvoke(self:objectName())
                                p:drawCards(x, self:objectName())
                            end
                            room:setPlayerMark(p, '@' .. self:objectName(), 0)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExWangyuanji:addSkill(LuaQianchong)
SkillAnjiang:addSkill(LuaQianchongTrickCardTargetMod)
SkillAnjiang:addSkill(LuaQianchongBasicCardTargetMod)
SkillAnjiang:addSkill(LuaWeimu)
SkillAnjiang:addSkill(LuaMingzhe)
ExWangyuanji:addSkill(LuaShangjian)
ExWangyuanji:addRelateSkill('LuaWeimu')
ExWangyuanji:addRelateSkill('LuaMingzhe')

ExXurong = sgs.General(extension, 'ExXurong', 'qun', '4', true, true)

LuaXionghuoCard =
    sgs.CreateSkillCard {
    name = 'LuaXionghuoCard',
    target_fixed = false,
    will_throw = true,
    on_effect = function(self, effect)
        effect.from:loseMark('@baoli')
        effect.from:getRoom():broadcastSkillInvoke('LuaXionghuo')
        effect.to:gainMark('@baoli')
    end
}

LuaXionghuoVS =
    sgs.CreateViewAsSkill {
    name = 'LuaXionghuo',
    n = 0,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:objectName() ~= sgs.Self:objectName()
        end
        return false
    end,
    view_as = function(self, cards)
        return LuaXionghuoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@baoli') > 0
    end
}

LuaXionghuoMaxCards =
    sgs.CreateMaxCardsSkill {
    name = 'LuaXionghuoMaxCards',
    extra_func = function(self, target)
        if target:getMark('XionghuoCardMinus') > 0 then
            return -1
        end
        return 0
    end
}

LuaXionghuoProSlash =
    sgs.CreateProhibitSkill {
    name = 'LuaXionghuoSlash',
    is_prohibited = function(self, from, to, card)
        if to:hasSkill('LuaXionghuo') and from:getMark('XionghuoSlashPro') > 0 then
            return card:isKindOf('Slash')
        end
    end
}

LuaXionghuo =
    sgs.CreateTriggerSkill {
    name = 'LuaXionghuo',
    events = {
        sgs.GameStart,
        sgs.TurnStart,
        sgs.DamageCaused,
        sgs.EventPhaseStart
    },
    view_as_skill = LuaXionghuoVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or event == sgs.TurnStart then
            if player:hasSkill(self:objectName()) and player:getMark('LuaBaoliGetMark') == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                player:gainMark('@baoli', 3)
                room:addPlayerMark(player, 'LuaBaoliGetMark')
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from:hasSkill(self:objectName()) and damage.to:getMark('@baoli') > 0 then
                room:sendCompulsoryTriggerLog(damage.from, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        else
            if player:getPhase() == sgs.Player_Play then
                if player:getMark('@baoli') > 0 then
                    local splayer = room:findPlayerBySkillName(self:objectName())
                    if splayer and splayer:objectName() ~= player:objectName() then
                        player:loseMark('@baoli')
                        room:sendCompulsoryTriggerLog(splayer, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        local choice = math.random(1, 3)
                        if choice == 1 then
                            rinsanFuncModule.doDamage(room, nil, player, 1, sgs.DamageStruct_Fire)
                            room:addPlayerMark(player, 'XionghuoSlashPro')
                        elseif choice == 2 then
                            room:loseHp(player)
                            room:addPlayerMark(player, 'XionghuoCardMinus')
                        else
                            if not player:isKongcheng() then
                                local card_id = room:askForCardChosen(splayer, player, 'h', self:objectName())
                                local reason =
                                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, splayer:objectName())
                                room:obtainCard(splayer, sgs.Sanguosha:getCard(card_id), reason, false)
                            end
                            if player:hasEquip() then
                                local card_id2 = room:askForCardChosen(splayer, player, 'e', self:objectName())
                                local reason2 =
                                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, splayer:objectName())
                                room:obtainCard(splayer, sgs.Sanguosha:getCard(card_id2), reason2, false)
                            end
                        end
                    end
                end
            elseif player:getPhase() == sgs.Player_Finish then
                room:setPlayerMark(player, 'XionghuoSlashPro', 0)
                room:setPlayerMark(player, 'XionghuoCardMinus', 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaShajue =
    sgs.CreateTriggerSkill {
    name = 'LuaShajue',
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:getHp() < 0 then
            local splayer = room:findPlayerBySkillName(self:objectName())
            if splayer and splayer:objectName() ~= dying.who:objectName() then
                room:sendCompulsoryTriggerLog(splayer, self:objectName())
                room:notifySkillInvoked(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                splayer:gainMark('@baoli')
                local card = dying.damage.card
                if card then
                    splayer:obtainCard(card)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExXurong:addSkill(LuaXionghuo)
ExXurong:addSkill(LuaShajue)
SkillAnjiang:addSkill(LuaXionghuoMaxCards)
SkillAnjiang:addSkill(LuaXionghuoProSlash)

ExCaoying = sgs.General(extension, 'ExCaoying', 'wei', '4', false, true)

LuaLingren =
    sgs.CreateTriggerSkill {
    name = 'LuaLingren',
    events = {
        sgs.TargetConfirmed,
        sgs.DamageCaused,
        sgs.CardEffected,
        sgs.TurnStart
    },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            if room:getCurrent():objectName() ~= player:objectName() then
                return false
            end
            local use = data:toCardUse()
            local card = use.card
            if use.from:objectName() ~= player:objectName() then
                return false
            end
            if
                not (card:isKindOf('Slash') or card:isKindOf('Duel') or card:isKindOf('SavageAssault') or
                    card:isKindOf('ArcheryAttack') or
                    card:isKindOf('FireAttack'))
             then
                return false
            end
            if not player:hasFlag(self:objectName()) then
                local splayers = sgs.SPlayerList()
                for _, p in sgs.qlist(use.to) do
                    splayers:append(p)
                end
                local target =
                    room:askForPlayerChosen(player, splayers, self:objectName(), 'LuaLingren-choose', true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerFlag(player, self:objectName())
                    local choice1 = room:askForChoice(player, 'BasicCardGuess', 'Have+NotHave')
                    local choice2 = room:askForChoice(player, 'TrickCardGuess', 'Have+NotHave')
                    local choice3 = room:askForChoice(player, 'EquipCardGuess', 'Have+NotHave')
                    local basic = false
                    local trick = false
                    local equip = false
                    for _, handcard in sgs.qlist(target:getHandcards()) do
                        if handcard:isKindOf('BasicCard') then
                            basic = true
                        elseif handcard:isKindOf('TrickCard') then
                            trick = true
                        elseif handcard:isKindOf('EquipCard') then
                            equip = true
                        end
                    end
                    local totalRight = 0
                    if (basic and choice1 == 'Have') or (not basic and choice1 == 'NotHave') then
                        totalRight = totalRight + 1
                    end
                    if (trick and choice2 == 'Have') or (not trick and choice2 == 'NotHave') then
                        totalRight = totalRight + 1
                    end
                    if (equip and choice3 == 'Have') or (not equip and choice3 == 'NotHave') then
                        totalRight = totalRight + 1
                    end
                    if totalRight > 0 then
                        if totalRight > 1 then
                            if totalRight > 2 then
                                room:handleAcquireDetachSkills(player, 'LuaJianxiong|LuaXingshang')
                                room:addPlayerMark(player, 'LuaLingrenSkills')
                            end
                            player:drawCards(2, self:objectName())
                        end
                        room:setCardFlag(use.card, 'LuaLingrenAddDamage')
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            local card = damage.card
            if damage.from and damage.from:objectName() == player:objectName() then
                if card and card:hasFlag('LuaLingrenAddDamage') then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        elseif event == sgs.CardEffected then
            if data:toCardEffect().card:hasFlag('LuaLingrenAddDamage') then
                room:setCardFlag(data:toCardEffect().card, '-LuaLingrenAddDamage')
            end
        elseif event == sgs.TurnStart then
            if player:getMark('LuaLingrenSkills') > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:removePlayerMark(player, 'LuaLingrenSkills')
                room:handleAcquireDetachSkills(player, '-LuaJianxiong|-LuaXingshang')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target)
    end
}

LuaJianxiong =
    sgs.CreateMasochismSkill {
    name = 'LuaJianxiong',
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local data = sgs.QVariant()
        data:setValue(damage)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1, self:objectName())
            local card = damage.card
            if not card then
                return
            end
            local ids = sgs.IntList()
            if card:isVirtualCard() then
                ids = card:getSubcards()
            else
                ids:append(card:getEffectiveId())
            end
            for _, id in sgs.qlist(ids) do
                if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                    return
                end
            end
            player:obtainCard(card)
        end
    end
}

LuaXingshang =
    sgs.CreateTriggerSkill {
    name = 'LuaXingshang',
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local splayer = death.who
        if splayer:objectName() == player:objectName() or splayer:isNude() then
            return false
        end
        if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            local cards = splayer:getCards('he')
            for _, card in sgs.qlist(cards) do
                dummy:addSubcard(card)
            end
            if cards:length() > 0 then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
                room:broadcastSkillInvoke(self:objectName())
                room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), splayer:objectName())
                room:obtainCard(player, dummy, reason, false)
            end
            dummy:deleteLater()
        end
        return false
    end
}

LuaFujian =
    sgs.CreateTriggerSkill {
    name = 'LuaFujian',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local max = room:alivePlayerCount() - 1
            local index = math.random(1, max)
            local target = sgs.QList2Table(room:getOtherPlayers(player))[index]
            room:showAllCards(target, player)
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), target:objectName())
        end
    end
}

ExCaoying:addSkill(LuaLingren)
ExCaoying:addSkill(LuaFujian)
SkillAnjiang:addSkill(LuaJianxiong)
SkillAnjiang:addSkill(LuaXingshang)
ExCaoying:addRelateSkill('LuaJianxiong')
ExCaoying:addRelateSkill('LuaXingshang')

ExLijue = sgs.General(extension, 'ExLijue', 'qun', 6, true, false, false, 4)

LuaYisuan =
    sgs.CreateTriggerSkill {
    name = 'LuaYisuan',
    events = {sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                room:removePlayerMark(player, self:objectName())
            end
        else
            local effect = data:toCardUse()
            local card = effect.card
            if effect.from:hasSkill(self:objectName()) then
                if effect.from:objectName() ~= room:getCurrent():objectName() then
                    return false
                end
                if card and card:isKindOf('TrickCard') then
                    if room:getCardPlace(card:getEffectiveId()) ~= sgs.Player_DiscardPile then
                        return false
                    end
                    local togain
                    if card:isVirtualCard() then
                        togain = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(card:getSubcards()) do
                            togain:addSubcard(id)
                        end
                    else
                        togain = sgs.Sanguosha:getCard(card:getSubcards():first())
                    end
                    if togain then
                        if effect.from:getMark(self:objectName()) == 0 then
                            if room:askForSkillInvoke(effect.from, self:objectName(), data) then
                                room:addPlayerMark(effect.from, self:objectName())
                                room:broadcastSkillInvoke(self:objectName())
                                room:loseMaxHp(effect.from)
                                effect.from:obtainCard(togain)
                            end
                        end
                    end
                end
            end
        end
        return false
    end
}

LuaLangxi =
    sgs.CreateTriggerSkill {
    name = 'LuaLangxi',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHp() <= player:getHp() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target =
                    room:askForPlayerChosen(player, targets, self:objectName(), 'LuaLangxi-choose', true, true)
                if target then
                    local value = math.random(0, 2)
                    room:broadcastSkillInvoke(self:objectName())
                    if value == 0 then
                        return false
                    end
                    rinsanFuncModule.doDamage(room, player, target, value)
                end
            end
        end
        return false
    end
}

ExLijue:addSkill(LuaYisuan)
ExLijue:addSkill(LuaLangxi)

ExMaliang = sgs.General(extension, 'ExMaliang', 'shu', '3', true)

LuaZishu =
    sgs.CreateTriggerSkill {
    name = 'LuaZishu',
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() then
                if player:getPhase() == sgs.Player_NotActive then
                    for _, id in sgs.qlist(move.card_ids) do
                        if
                            room:getCardOwner(id):objectName() == player:objectName() and
                                room:getCardPlace(id) == sgs.Player_PlaceHand
                         then
                            room:addPlayerMark(player, self:objectName() .. id)
                        end
                    end
                elseif
                    player:getPhase() ~= sgs.Player_NotActive and move.reason.m_skillName ~= 'LuaZishu' and
                        rinsanFuncModule.RIGHT(self, player)
                 then
                    for _, id in sgs.qlist(move.card_ids) do
                        if
                            room:getCardOwner(id):objectName() == player:objectName() and
                                room:getCardPlace(id) == sgs.Player_PlaceHand
                         then
                            SendComLog(self, player, 1)
                            room:addPlayerMark(player, self:objectName() .. 'engine')
                            if player:getMark(self:objectName() .. 'engine') > 0 then
                                player:drawCards(1, self:objectName())
                                room:removePlayerMark(player, self:objectName() .. 'engine')
                                break
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                for _, card in sgs.list(p:getHandcards()) do
                    if p:getMark(self:objectName() .. card:getEffectiveId()) > 0 then
                        dummy:addSubcard(card:getEffectiveId())
                    end
                end
                if dummy:subcardsLength() > 0 then
                    SendComLog(self, p, 2)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        room:throwCard(
                            dummy,
                            sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                p:objectName(),
                                self:objectName(),
                                nil
                            ),
                            p
                        )
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                    if player:getNextAlive():objectName() == p:objectName() then
                        room:getThread():delay(2500)
                    end
                end
            end
            -- 自书弃牌完毕后移除所有玩家的自书弃牌标记
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                for _, mark in sgs.list(p:getMarkNames()) do
                    if string.find(mark, self:objectName()) and p:getMark(mark) > 0 then
                        room:setPlayerMark(p, mark, 0)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaYingyuan =
    sgs.CreateTriggerSkill {
    name = 'LuaYingyuan',
    events = {sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, 'LuaYingyuan') and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        else
            local effect = data:toCardUse()
            local card = effect.card
            if effect.from:hasSkill(self:objectName()) then
                if effect.from:objectName() ~= room:getCurrent():objectName() then
                    return false
                end
                if card:isKindOf('SkillCard') then
                    return false
                end
                if card and effect.from:getMark('LuaYingyuan' .. card:objectName() .. '-Clear') == 0 then
                    if room:getCardPlace(card:getEffectiveId()) ~= sgs.Player_DiscardPile then
                        return false
                    end

                    local togain
                    if card:isVirtualCard() then
                        togain = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(card:getSubcards()) do
                            togain:addSubcard(id)
                        end
                    else
                        togain = card
                    end
                    if togain then
                        local target =
                            room:askForPlayerChosen(
                            effect.from,
                            room:getOtherPlayers(effect.from),
                            'LuaYingyuan',
                            '@LuaYingyuanTo:' .. card:objectName(),
                            true,
                            true
                        )
                        if target then
                            room:obtainCard(target, togain)
                            room:addPlayerMark(effect.from, 'LuaYingyuan' .. card:objectName() .. '-Clear')
                            room:broadcastSkillInvoke(self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end
}

ExMaliang:addSkill(LuaZishu)
ExMaliang:addSkill(LuaYingyuan)

ExCaochun = sgs.General(extension, 'ExCaochun', 'wei', '4', true)

LuaShanjiaCard =
    sgs.CreateSkillCard {
    name = 'LuaShanjiaCard',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') or sgs.Sanguosha:getCard(id):isKindOf('TrickCard') then
                return #targets < 0
            end
        end
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:setSkillName('shanjia')
        for _, cd in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(cd)
        end
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, sgs.Self)
    end,
    feasible = function(self, targets)
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') or sgs.Sanguosha:getCard(id):isKindOf('TrickCard') then
                return #targets == 0
            end
        end
        return #targets >= 0
    end,
    on_use = function(self, room, source, targets)
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        if targets_list:length() > 0 then
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName('LuaShanjia')
            room:useCard(sgs.CardUseStruct(slash, source, targets_list))
        else
            room:broadcastSkillInvoke('LuaShanjia', math.random(1, 2))
        end
    end
}

LuaShanjiaVS =
    sgs.CreateViewAsSkill {
    name = 'LuaShanjia',
    n = 3,
    view_filter = function(self, selected, to_select)
        local x = 3 - sgs.Self:getMark('@luashanjia')
        return #selected < x and not sgs.Self:isJilei(to_select)
    end,
    view_as = function(self, cards)
        local x = 3 - sgs.Self:getMark('@luashanjia')
        if #cards ~= x then
            return nil
        end
        local card = LuaShanjiaCard:clone()
        for _, cd in ipairs(cards) do
            card:addSubcard(cd)
        end
        return card
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaShanjia')
    end
}

LuaShanjia =
    sgs.CreateTriggerSkill {
    name = 'LuaShanjia',
    view_as_skill = LuaShanjiaVS,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:drawCards(3, self:objectName())
                    room:askForUseCard(player, '@@LuaShanjia!', 'LuaShanjia_throw', -1, sgs.Card_MethodNone)
                end
            end
        else
            local move = data:toMoveOneTime()
            if
                (move.from and move.from:objectName() == player:objectName() and
                    move.from_places:contains(sgs.Player_PlaceEquip))
             then
                if player:getMark('@luashanjia') >= 3 then
                    return false
                end
                local count = 0
                for i = 0, move.card_ids:length() - 1, 1 do
                    if move.from_places:at(i) == sgs.Player_PlaceEquip then
                        count = count + 1
                    end
                end
                count = math.min(3 - player:getMark('@luashanjia'), count)
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:gainMark('@luashanjia', count)
            end
        end
    end
}

ExCaochun:addSkill(LuaShanjia)

ExJiakui = sgs.General(extension, 'ExJiakui', 'wei', '3', true, true)

LuaZhongzuo =
    sgs.CreateTriggerSkill {
    name = 'LuaZhongzuo',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseChanging, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:hasSkill(self:objectName()) then
                room:addPlayerMark(damage.from, '@LuaZhongzuoDamage')
            end
            if damage.to and damage.to:hasSkill(self:objectName()) then
                room:addPlayerMark(damage.to, '@LuaZhongzuoDamage')
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self:objectName()) then
                        if p:getMark('@LuaZhongzuoDamage') > 0 then
                            local target =
                                room:askForPlayerChosen(
                                p,
                                room:getAlivePlayers(),
                                'LuaZhongzuo',
                                '@LuaZhongzuoChoose',
                                true,
                                true
                            )
                            if target then
                                room:broadcastSkillInvoke(self:objectName())
                                target:drawCards(2, self:objectName())
                                if target:isWounded() then
                                    p:drawCards(1, self:objectName())
                                end
                            end
                            room:setPlayerMark(p, '@LuaZhongzuoDamage', 0)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaWanlan =
    sgs.CreateTriggerSkill {
    name = 'LuaWanlan',
    events = {sgs.Dying},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaWanlan',
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local current = room:getCurrent()
        local data2 = sgs.QVariant()
        data2:setValue(dying.who)
        if room:askForSkillInvoke(player, self:objectName(), data2) then
            room:broadcastSkillInvoke(self:objectName())
            player:loseMark('@LuaWanlan')
            player:throwAllHandCards()
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), dying.who:objectName())
            room:recover(dying.who, sgs.RecoverStruct(player, nil, 1 - dying.who:getHp()))
            room:damage(sgs.DamageStruct(self:objectName(), player, current))
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and target:getMark('@LuaWanlan') > 0
    end
}

ExJiakui:addSkill(LuaZhongzuo)
ExJiakui:addSkill(LuaWanlan)

JieXusheng = sgs.General(extension, 'JieXusheng', 'wu', '4', true)

LuaPojun =
    sgs.CreateTriggerSkill {
    name = 'LuaPojun',
    frequency = sgs.Skill_NotFrequent,
    events = {
        sgs.TargetSpecified,
        sgs.EventPhaseStart,
        sgs.Death,
        sgs.DamageCaused,
        sgs.BeforeCardsMove,
        sgs.CardsMoveOneTime
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('Slash') and rinsanFuncModule.RIGHT(self, player) then
                for _, t in sgs.qlist(use.to) do
                    local n = math.min(t:getCards('he'):length(), t:getHp())
                    local data2 = sgs.QVariant()
                    data2:setValue(t)
                    if n > 0 and room:askForSkillInvoke(player, self:objectName(), data2) then
                        room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), t:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        local dis_num = {}
                        for i = 1, n, 1 do
                            table.insert(dis_num, tostring(i))
                        end
                        local discard_n =
                            tonumber(room:askForChoice(player, self:objectName(), table.concat(dis_num, '+')))
                        room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), t:objectName())
                        if discard_n > 0 then
                            local orig_places = {}
                            local cards = sgs.IntList()
                            t:setFlags('olpojun_InTempMoving')
                            for i = 0, discard_n - 1, 1 do
                                local id =
                                    room:askForCardChosen(
                                    player,
                                    t,
                                    'he',
                                    self:objectName(),
                                    false,
                                    sgs.Card_MethodNone
                                )
                                local place = room:getCardPlace(id)
                                orig_places[i] = place
                                cards:append(id)
                                t:addToPile('#LuaPojun', id, false)
                            end
                            for i = 0, discard_n - 1, 1 do
                                room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), t, orig_places[i], false)
                            end
                            t:setFlags('-olpojun_InTempMoving')

                            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                            dummy:addSubcards(cards)
                            t:addToPile('LuaPojun', dummy, false)
                        end
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.card and damage.card:isKindOf('Slash') and damage.from:hasSkill(self:objectName()) then
                if
                    damage.from:getHandcardNum() >= damage.to:getHandcardNum() and
                        damage.from:getEquips():length() >= damage.to:getEquips():length()
                 then
                    damage.damage = damage.damage + 1
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, damage.from:objectName(), damage.to:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:notifySkillInvoked(player, self:objectName())
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#LuaPojunDamageUp',
                        {['from'] = damage.from, ['card_str'] = damage.card:toString()}
                    )
                    data:setValue(damage)
                end
            end
        elseif event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:hasFlag('olpojun_InTempMoving') then
                    return true
                end
            end
            return false
        elseif rinsanFuncModule.cardGoBack(event, player, data, self:objectName()) then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getPile('LuaPojun'):length() > 0 then
                    local to_obtain = sgs.IntList()
                    for _, id in sgs.qlist(p:getPile('LuaPojun')) do
                        to_obtain:append(id)
                    end
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    dummy:addSubcards(to_obtain)
                    room:obtainCard(p, dummy, false)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return true
    end
}

JieXusheng:addSkill(LuaPojun)

JieMadai = sgs.General(extension, 'JieMadai', 'shu', '4', true, true)

LuaMashu =
    sgs.CreateTriggerSkill {
    name = 'LuaMashu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
                local damage = data:toDamage()
                if damage and damage.card then
                    if damage.card:isKindOf('Slash') then
                        room:addPlayerMark(damage.from, 'MashuSlashDamage')
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then
                if player:getMark('MashuSlashDamage') == 0 then
                    local victims = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:canSlash(p, nil, false) then
                            victims:append(p)
                        end
                    end
                    if victims:isEmpty() then
                        return false
                    end
                    local victim =
                        room:askForPlayerChosen(player, victims, self:objectName(), '@LuaMashuSlashTo', true, true)
                    if victim then
                        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        slash:setSkillName(self:objectName())
                        room:useCard(sgs.CardUseStruct(slash, player, victim))
                    end
                end
                room:setPlayerMark(player, 'MashuSlashDamage', 0)
            end
        end
        return false
    end
}

LuaMashuDistance =
    sgs.CreateDistanceSkill {
    name = 'LuaMashuDistance',
    correct_func = function(self, from, to)
        if from:hasSkill('LuaMashu') then
            return -1
        end
        return 0
    end
}

LuaQianxi =
    sgs.CreateTriggerSkill {
    name = 'LuaQianxi',
    events = {sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                for _, sp in sgs.qlist(room:getAlivePlayers()) do
                    if sp:distanceTo(player) <= 1 and sp:hasSkill(self:objectName()) then
                        if room:askForSkillInvoke(sp, self:objectName()) then
                            local userData = sgs.QVariant()
                            userData:setValue(sp)
                            if room:askForSkillInvoke(room:getCurrent(), 'LuaQianxiDraw', userData) then
                                rinsanFuncModule.sendLogMessage(
                                    room,
                                    '#LuaQianxiDrawAccept',
                                    {['from'] = room:getCurrent(), ['to'] = sp}
                                )
                                room:doAnimate(
                                    rinsanFuncModule.ANIMATE_INDICATE,
                                    room:getCurrent():objectName(),
                                    sp:objectName()
                                )
                                sp:drawCards(1, self:objectName())
                            else
                                rinsanFuncModule.sendLogMessage(
                                    room,
                                    '#LuaQianxiDrawRefuse',
                                    {['from'] = room:getCurrent(), ['to'] = sp}
                                )
                            end

                            if not sp:isKongcheng() then
                                local card =
                                    room:askForCard(
                                    sp,
                                    '.|.|.|hand!',
                                    '@LuaQianxi-discard',
                                    sgs.QVariant(),
                                    sgs.Card_MethodDiscard
                                )
                                if card then
                                    local color = '.'
                                    if card:isRed() then
                                        color = 'red'
                                    elseif card:isBlack() then
                                        color = 'black'
                                    end
                                    local victims = sgs.SPlayerList()
                                    for _, p in sgs.qlist(room:getOtherPlayers(sp)) do
                                        if sp:distanceTo(p) == 1 then
                                            victims:append(p)
                                        end
                                    end
                                    if not victims:isEmpty() then
                                        local victim =
                                            room:askForPlayerChosen(
                                            sp,
                                            victims,
                                            self:objectName(),
                                            '@LuaQianxi-choose',
                                            false,
                                            true
                                        )
                                        if victim then
                                            local pattern = '.|' .. color .. '|.|hand'
                                            if player:getMark('@qianxi_red') > 0 and color == 'black' then
                                                pattern = '.|' .. '.' .. '|.|hand'
                                            end
                                            if player:getMark('@qianxi_black') > 0 and color == 'red' then
                                                pattern = '.|' .. '.' .. '|.|hand'
                                            end
                                            room:doAnimate(
                                                rinsanFuncModule.ANIMATE_INDICATE,
                                                sp:objectName(),
                                                victim:objectName()
                                            )
                                            room:broadcastSkillInvoke(self:objectName())
                                            room:addPlayerMark(victim, '@qianxi_' .. color)
                                            room:setPlayerCardLimitation(victim, 'use, response', pattern, false)
                                            rinsanFuncModule.sendLogMessage(
                                                room,
                                                '#Qianxi',
                                                {['from'] = victim, ['arg'] = color}
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            if event == sgs.EventPhaseChanging then
                if data:toPhaseChange().to ~= sgs.Player_NotActive then
                    return false
                end
            elseif event == sgs.Death then
                if
                    data:toDeath().who:objectName() ~= player:objectName() or
                        not data:toDeath().who:hasSkill(self:objectName())
                 then
                    return false
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark('@qianxi_red') > 0 or p:getMark('@qianxi_black') > 0 then
                    p:clearCardLimitation(false)
                    room:setPlayerMark(p, '@qianxi_red', 0)
                    room:setPlayerMark(p, '@qianxi_black', 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

SkillAnjiang:addSkill(LuaMashuDistance)
JieMadai:addSkill(LuaMashu)
JieMadai:addSkill(LuaQianxi)

ExMajun = sgs.General(extension, 'ExMajun', 'wei', '3', true)

LuaJingxieCard =
    sgs.CreateSkillCard {
    name = 'LuaJingxieCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        math.randomseed(os.time())
        room:broadcastSkillInvoke('LuaJingxie', math.random(1, 2))
        room:setPlayerMark(source, card:objectName(), 1)
        room:showCard(source, card:getEffectiveId())
        if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceHand then
            room:useCard(sgs.CardUseStruct(card, source, source))
        end
    end
}

LuaJingxieVS =
    sgs.CreateViewAsSkill {
    name = 'LuaJingxie',
    n = 1,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            if sgs.Self:getMark(to_select:objectName()) == 1 then
                return nil
            end
            return to_select:isKindOf('Armor') or to_select:objectName() == 'crossbow'
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local kf = LuaJingxieCard:clone()
            kf:addSubcard(cards[1])
            return kf
        end
        return nil
    end
}

LuaJingxie =
    sgs.CreateTriggerSkill {
    name = 'LuaJingxie',
    view_as_skill = LuaJingxieVS,
    events = {
        sgs.Dying,
        sgs.CardsMoveOneTime,
        sgs.CardEffected,
        sgs.AskForRetrial,
        sgs.ChainStateChange
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Dying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                room:filterCards(player, player:getCards('he'), true)
                local card = room:askForCard(player, 'Armor|.|.|.', 'LuaJingxie-Invoke', data, sgs.Card_MethodRecast)
                if card then
                    room:moveCardTo(
                        card,
                        player,
                        nil,
                        sgs.Player_DiscardPile,
                        sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_RECAST,
                            player:objectName(),
                            card:objectName(),
                            ''
                        )
                    )
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#UseCard_Recase',
                        {['from'] = player, ['card_str'] = card:getEffectiveId()}
                    )
                    room:broadcastSkillInvoke('@recast')
                    player:drawCards(1, 'recast')
                    room:recover(dying.who, sgs.RecoverStruct(player, nil, 1 - dying.who:getHp()))
                    room:broadcastSkillInvoke(self:objectName(), 1)
                end
                room:filterCards(player, player:getCards('he'), false)
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if
                (move.from and move.from:objectName() == player:objectName() and
                    move.from_places:contains(sgs.Player_PlaceEquip))
             then
                for i = 0, move.card_ids:length() - 1, 1 do
                    if move.from_places:at(i) == sgs.Player_PlaceEquip then
                        local card = sgs.Sanguosha:getCard(move.card_ids:at(i))
                        if card:isKindOf('Armor') or card:objectName() == 'crossbow' then
                            if player:getMark(card:objectName()) > 0 then
                                room:removePlayerMark(player, card:objectName())
                                if card:objectName() == 'silver_lion' then
                                    room:sendCompulsoryTriggerLog(player, self:objectName())
                                    player:drawCards(2, self:objectName())
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.CardEffected then
            local effect = data:toCardEffect()
            local card = effect.card
            if player:getMark('renwang_shield') == 0 then
                return false
            end
            if card and card:isKindOf('Slash') then
                if card:isBlack() or card:getSuit() == sgs.Card_Heart then
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#LuaJingxie-Renwang',
                        {['from'] = player, ['to'] = effect.from, ['arg'] = card:objectName()}
                    )
                    return true
                end
            end
        elseif event == sgs.AskForRetrial then
            local judge = data:toJudge()
            if judge.who:getMark('eight_diagram') == 0 then
                return false
            end
            if judge.reason ~= 'eight_diagram' then
                return false
            end
            if judge.card:getSuit() == sgs.Card_Club then
                local card = sgs.Sanguosha:getWrappedCard(judge.card:getId())
                card:setSkillName(self:objectName())
                card:setSuit(sgs.Card_Heart)
                card:setModified(true)
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastUpdateCard(room:getAllPlayers(true), judge.card:getId(), card)
                judge:updateResult()
            end
        elseif event == sgs.ChainStateChange then
            if player:getMark('vine') == 0 then
                return false
            end
            if not player:isChained() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                return true
            end
        end
        return false
    end
}

LuaJingxieTargetMod =
    sgs.CreateTargetModSkill {
    name = '#LuaJingxieTargetMod',
    pattern = 'Slash',
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaJingxie') and from:getMark('crossbow') > 0 then
            return 3
        else
            return 0
        end
    end
}

LuaQiaosiCard =
    sgs.CreateSkillCard {
    name = 'LuaQiaosiCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets)
        return #targets >= 0
    end,
    on_use = function(self, room, source, targets)
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cd)
        end
        local target = targets[1]
        if target then
            local reason =
                sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_GIVE,
                source:objectName(),
                target:objectName(),
                self:objectName(),
                nil
            )
            room:moveCardTo(to_goback, source, target, sgs.Player_PlaceHand, reason, true)
        else
            room:throwCard(to_goback, source)
        end
    end
}

LuaQiaosiStartCard =
    sgs.CreateSkillCard {
    name = 'LuaQiaosiStartCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaQiaosi')
        room:notifySkillInvoked(source, 'LuaQiaosi')
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        local marks = rinsanFuncModule.LuaDoQiaosiShow(room, source, dummy)
        if marks > 0 then
            room:addPlayerMark(source, 'LuaQiaosiCardsNum', marks)
            room:addPlayerMark(source, 'LuaQiaosiGiven')
            math.randomseed(os.time())
            room:askForUseCard(
                source,
                '@@LuaQiaosi!',
                'LuaQiaosi_give:' .. source:getMark('LuaQiaosiCardsNum'),
                -1,
                sgs.Card_MethodNone
            )
            room:removePlayerMark(source, 'LuaQiaosiGiven')
            room:setPlayerMark(source, 'LuaQiaosiCardsNum', 0)
        end
    end
}

LuaQiaosi =
    sgs.CreateViewAsSkill {
    name = 'LuaQiaosi',
    n = 999,
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMark('LuaQiaosiCardsNum')
    end,
    view_as = function(self, cards)
        if sgs.Self:getMark('LuaQiaosiGiven') > 0 then
            if #cards == sgs.Self:getMark('LuaQiaosiCardsNum') then
                local card = LuaQiaosiCard:clone()
                for _, cd in ipairs(cards) do
                    card:addSubcard(cd)
                end
                return card
            end
        else
            if #cards == 0 then
                return LuaQiaosiStartCard:clone()
            end
        end
        return nil
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaQiaosi')
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaQiaosiStartCard')
    end
}

ExMajun:addSkill(LuaJingxie)
ExMajun:addSkill(LuaQiaosi)
SkillAnjiang:addSkill(LuaJingxieTargetMod)

ExYiji = sgs.General(extension, 'ExYiji', 'shu', '3', true)

LuaJijieCard =
    sgs.CreateSkillCard {
    name = 'LuaJijieCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaJijie')
        local ids = room:getDrawPile()
        local cards = sgs.IntList()
        local id = ids:last()
        cards:append(id)
        room:fillAG(cards, source)
        math.randomseed(os.time())
        room:broadcastSkillInvoke('LuaJijie', math.random(1, 2))
        local card = sgs.Sanguosha:getCard(id)
        local target =
            room:askForPlayerChosen(
            source,
            room:getOtherPlayers(source),
            'LuaJijie',
            '@LuaJijiePlayer-Chosen',
            true,
            true
        )
        if target then
            local reason =
                sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_GIVE,
                source:objectName(),
                target:objectName(),
                'LuaJijie',
                nil
            )
            room:clearAG()
            room:moveCardTo(card, source, target, sgs.Player_PlaceHand, reason, false)
        else
            local reason =
                sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_PREVIEWGIVE,
                source:objectName(),
                source:objectName(),
                'LuaJijie',
                nil
            )
            room:clearAG()
            room:moveCardTo(card, source, source, sgs.Player_PlaceHand, reason, false)
        end
    end
}

LuaJijie =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaJijie',
    view_as = function(self, cards)
        return LuaJijieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaJijieCard')
    end
}

LuaJiyuan =
    sgs.CreateTriggerSkill {
    name = 'LuaJiyuan',
    events = {sgs.Dying, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Dying then
            local dying = data:toDying()
            local data2 = sgs.QVariant()
            data2:setValue(dying.who)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                math.randomseed(os.time())
                room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), dying.who:objectName())
                dying.who:drawCards(1, self:objectName())
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() ~= player:objectName() then
                if move.from and move.from:objectName() == player:objectName() then
                    local reason = move.reason.m_reason
                    if reason == sgs.CardMoveReason_S_REASON_GIVE or reason == sgs.CardMoveReason_S_REASON_PREVIEWGIVE then
                        local target
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:objectName() == move.to:objectName() then
                                target = p
                                break
                            end
                        end
                        local data2 = sgs.QVariant()
                        data2:setValue(target)
                        if room:askForSkillInvoke(player, self:objectName(), data2) then
                            room:broadcastSkillInvoke(self:objectName())
                            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), target:objectName())
                            target:drawCards(1, self:objectName())
                        end
                    end
                end
            end
        end
    end
}

ExYiji:addSkill(LuaJijie)
ExYiji:addSkill(LuaJiyuan)

ExLifeng = sgs.General(extension, 'ExLifeng', 'shu', '3', true, true)

LuaTunchuCard =
    sgs.CreateSkillCard {
    name = 'LuaTunchuCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local subs = self:getSubcards()
        for _, card_id in sgs.qlist(subs) do
            source:addToPile('LuaLiang', card_id)
        end
    end
}

LuaTunchuVS =
    sgs.CreateViewAsSkill {
    name = 'LuaTunchu',
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local card = LuaTunchuCard:clone()
        for _, cd in ipairs(cards) do
            card:addSubcard(cd)
        end
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaTunchu'
    end
}

LuaTunchu =
    sgs.CreateTriggerSkill {
    name = 'LuaTunchu',
    view_as_skill = LuaTunchuVS,
    events = {
        sgs.DrawNCards,
        sgs.EventPhaseEnd,
        sgs.EventLoseSkill,
        sgs.EventAcquireSkill,
        sgs.CardsMoveOneTime
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            if player:hasSkill(self:objectName()) then
                if player:getPile('LuaLiang'):length() == 0 then
                    if room:askForSkillInvoke(player, self:objectName()) then
                        room:broadcastSkillInvoke(self:objectName())
                        local x = data:toInt()
                        x = x + 2
                        player:setFlags('LuaTunchuInvoked')
                        data:setValue(x)
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:hasFlag('LuaTunchuInvoked') then
                room:askForUseCard(player, '@@LuaTunchu', '@LuaTunchu', -1, sgs.Card_MethodNone)
                player:setFlags('-LuaTunchuInvoked')
            end
        elseif event == sgs.EventLoseSkill then
            if data:toString() == 'LuaTunchu' then
                room:removePlayerCardLimitation(player, 'use', 'Slash|.|.|.$0')
            end
        elseif event == sgs.EventAcquireSkill then
            if data:toString() == 'LuaTunchu' then
                if player:getPile('LuaLiang'):length() > 0 then
                    room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.', false)
                end
            end
        elseif event == sgs.CardsMoveOneTime and player:hasSkill(self:objectName()) and player:isAlive() then
            local move = data:toMoveOneTime()
            if
                move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceSpecial and
                    move.to_pile_name == 'LuaLiang'
             then
                if player:getPile('LuaLiang'):length() == 1 then
                    room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.', false)
                end
            elseif
                move.from and move.from:objectName() == player:objectName() and
                    move.from_places:contains(sgs.Player_PlaceSpecial)
             then
                if player:getPile('LuaLiang'):length() == 0 then
                    room:removePlayerCardLimitation(player, 'use', 'Slash|.|.|.$0')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaShuliangCard =
    sgs.CreateSkillCard {
    name = 'LuaShuliangCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaShuliang')
        local current = room:getCurrent()
        room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, source:objectName(), current:objectName())
        current:drawCards(2, 'LuaShuliang')
    end
}

LuaShuliangVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaShuliang',
    response_pattern = '@@LuaShuliang',
    filter_pattern = '.|.|.|LuaLiang',
    expand_pile = 'LuaLiang',
    view_as = function(self, card)
        local kf = LuaShuliangCard:clone()
        kf:addSubcard(card)
        return kf
    end
}

LuaShuliang =
    sgs.CreateTriggerSkill {
    name = 'LuaShuliang',
    view_as_skill = LuaShuliangVS,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Finish then
            return false
        end
        local splayers = room:findPlayersBySkillName(self:objectName())
        for _, splayer in sgs.qlist(splayers) do
            if player:getHandcardNum() < player:getHp() then
                if splayer:getPile('LuaLiang'):length() > 0 then
                    room:askForUseCard(splayer, '@@LuaShuliang', '@LuaShuliang')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExLifeng:addSkill(LuaTunchu)
ExLifeng:addSkill(LuaShuliang)

ExZhaotongZhaoguang = sgs.General(extension, 'ExZhaotongZhaoguang', 'shu', '4', true, true)

LuaYizanCard =
    sgs.CreateSkillCard {
    name = 'LuaYizanCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card
            if self:getUserString() and self:getUserString() ~= '' then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
                return card and card:targetFilter(players, to_select, sgs.Self) and
                    not sgs.Self:isProhibited(to_select, card, players)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local _card = sgs.Self:getTag('LuaYizan'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:deleteLater()
        return card and card:targetFilter(players, to_select, sgs.Self) and
            not sgs.Self:isProhibited(to_select, card, players)
    end,
    feasible = function(self, targets)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card
            if self:getUserString() and self:getUserString() ~= '' then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
                return card and card:targetsFeasible(players, sgs.Self)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local _card = sgs.Self:getTag('LuaYizan'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:deleteLater()
        return card and card:targetsFeasible(players, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local to_use = self:getUserString()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:addPlayerMark(source, 'LuaYizanUse')
        if
            to_use == 'slash' and
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'yizan_slash', table.concat(use_list, '+'))
            source:setTag('YizanSlash', sgs.QVariant(to_use))
        end
        local user_str = to_use
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        if use_card == nil then
            use_card = sgs.Sanguosha:cloneCard('slash', card:getSuit(), card:getNumber())
        end
        use_card:setSkillName('LuaYizan')
        use_card:addSubcards(self:getSubcards())
        use_card:deleteLater()
        local tos = card_use.to
        for _, to in sgs.qlist(tos) do
            local skill = room:isProhibited(source, to, use_card)
            if skill then
                card_use.to:removeOne(to)
            end
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:addPlayerMark(source, 'LuaYizanUse')
        local to_use
        if self:getUserString() == 'peach+analeptic' then
            local use_list = {}
            table.insert(use_list, 'peach')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'analeptic')
            end
            to_use = room:askForChoice(source, 'yizan_saveself', table.concat(use_list, '+'))
            source:setTag('YizanSaveSelf', sgs.QVariant(to_use))
        elseif self:getUserString() == 'slash' then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'yizan_slash', table.concat(use_list, '+'))
            source:setTag('YizanSlash', sgs.QVariant(to_use))
        else
            to_use = self:getUserString()
        end
        local user_str
        if to_use == 'slash' then
            user_str = 'slash'
        elseif to_use == 'normal_slash' then
            user_str = 'slash'
        else
            user_str = to_use
        end
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        use_card:setSkillName('LuaYizan')
        use_card:addSubcards(self:getSubcards())
        use_card:deleteLater()
        return use_card
    end
}

LuaYizanVS =
    sgs.CreateViewAsSkill {
    name = 'LuaYizan',
    response_or_use = true,
    n = 2,
    view_filter = function(self, selected, to_select)
        if sgs.Self:getMark('LuaLongyuan') == 0 then
            -- Before awake use 2 cards, one basic cards
            if #selected == 0 then
                return not to_select:isEquipped()
            elseif #selected == 1 then
                local first = selected[1]
                if first:isKindOf('BasicCard') then
                    return not to_select:isEquipped()
                else
                    return to_select:isKindOf('BasicCard')
                end
            end
        else
            -- After awake use 1 basic card
            if #selected == 0 then
                return to_select:isKindOf('BasicCard')
            end
        end
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        if string.sub(pattern, 1, 1) == '.' or string.sub(pattern, 1, 1) == '@' then
            return false
        end
        if pattern == 'peach' and player:getMark('Global_PreventPeach') > 0 then
            return false
        end
        if pattern == 'nullification' then
            return false
        end
        if string.find(pattern, '[%u%d]') then
            return false
        end -- 这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
        return true
    end,
    enabled_at_play = function(self, player)
        return player:isWounded() or sgs.Slash_IsAvailable(player) or not player:hasUsed('Analeptic')
    end,
    enabled_at_nullification = function(self, player)
        return false
    end,
    view_as = function(self, cards)
        if sgs.Self:getMark('LuaLongyuan') == 0 then
            if #cards < 2 then
                return nil
            end
        else
            if #cards < 1 then
                return nil
            end
        end

        if
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
            local card = LuaYizanCard:clone()
            card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            for _, cd in ipairs(cards) do
                card:addSubcard(cd)
            end
            return card
        end
        local c = sgs.Self:getTag('LuaYizan'):toCard()
        if c then
            local card = LuaYizanCard:clone()
            card:setUserString(c:objectName())
            for _, cd in ipairs(cards) do
                card:addSubcard(cd)
            end
            return card
        else
            return nil
        end
    end
}

LuaYizan =
    sgs.CreateTriggerSkill {
    name = 'LuaYizan',
    view_as_skill = LuaYizanVS,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == 'LuaLongyuan' and mark.who:hasSkill(self:objectName()) then
            ChangeSkill(self, room, player)
        end
    end
}

LuaYizan:setGuhuoDialog('l')

LuaLongyuan =
    sgs.CreateTriggerSkill {
    name = 'LuaLongyuan',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        if room:changeMaxHpForAwakenSkill(player, 0) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, 'LuaLongyuan')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and (target:getMark('LuaLongyuan') == 0) and
            (target:getMark('LuaYizanUse') >= 3) and
            (target:getPhase() == sgs.Player_Start)
    end
}

ExZhaotongZhaoguang:addSkill(LuaYizan)
ExZhaotongZhaoguang:addSkill(LuaLongyuan)

JieYanliangWenchou = sgs.General(extension, 'JieYanliangWenchou', 'qun', '4', true)

LuaShuangxiongVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaShuangxiong',
    view_filter = function(self, to_select)
        if to_select:isEquipped() then
            return false
        end
        local value = sgs.Self:getMark('LuaShuangxiong')
        if value == 1 then
            -- Black
            return to_select:isBlack()
        elseif value == 2 then
            -- Red
            return to_select:isRed()
        end
        return false
    end,
    view_as = function(self, card)
        local duel = sgs.Sanguosha:cloneCard('duel', card:getSuit(), card:getNumber())
        duel:addSubcard(card)
        duel:setSkillName(self:objectName())
        return duel
    end,
    enabled_at_play = function(self, player)
        return player:getMark('LuaShuangxiong') > 0 and not player:isKongcheng()
    end
}

LuaShuangxiong =
    sgs.CreateTriggerSkill {
    name = 'LuaShuangxiong',
    view_as_skill = LuaShuangxiongVS,
    events = {
        sgs.EventPhaseStart,
        sgs.Damaged,
        sgs.CardResponded,
        sgs.CardUsed,
        sgs.CardFinished
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                room:setPlayerMark(player, 'LuaShuangxiong', 0)
            elseif player:getPhase() == sgs.Player_Draw then
                if player:hasSkill(self:objectName()) then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName())
                        local card_ids = room:getNCards(2)
                        local to_get = sgs.IntList()
                        local to_throw = sgs.IntList()
                        room:fillAG(card_ids)
                        while not card_ids:isEmpty() do
                            local card_id = room:askForAG(player, card_ids, false, self:objectName())
                            card_ids:removeOne(card_id)
                            to_get:append(card_id)
                            local card = sgs.Sanguosha:getCard(card_id)
                            if card:isRed() then
                                room:setPlayerMark(player, 'LuaShuangxiong', 1)
                            else
                                room:setPlayerMark(player, 'LuaShuangxiong', 2)
                            end
                            room:takeAG(player, card_id, false)
                            local _card_ids = card_ids
                            for _, id in sgs.qlist(_card_ids) do
                                card_ids:removeOne(id)
                                to_throw:append(id)
                                room:takeAG(nil, id, false)
                            end
                        end
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        if not to_get:isEmpty() then
                            dummy:addSubcards(rinsanFuncModule.getCardList(to_get))
                            player:obtainCard(dummy)
                        end
                        dummy:clearSubcards()
                        if not to_throw:isEmpty() then
                            dummy:addSubcards(rinsanFuncModule.getCardList(to_throw))
                            local reason =
                                sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                player:objectName(),
                                self:objectName(),
                                ''
                            )
                            room:throwCard(dummy, reason, nil)
                        end
                        dummy:deleteLater()
                        room:clearAG()
                        return true
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                if damage.to:hasSkill(self:objectName()) then
                    -- For AI
                    room:setPlayerFlag(player, 'LuaShuangxiongDamaged')
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(room:getDiscardPile()) do
                            local card = sgs.Sanguosha:getCard(id)
                            if card:hasFlag('LuaShuangxiongResponded') then
                                dummy:addSubcard(card)
                            end
                        end
                        damage.to:obtainCard(dummy)
                    end
                    room:setPlayerFlag(player, '-LuaShuangxiongDamaged')
                end
            end
        elseif event == sgs.CardResponded then
            local resp = data:toCardResponse()
            if resp.m_who and resp.m_who:hasFlag('LuaShuangxiongInvoke') then
                if resp.m_card:isVirtualCard() then
                    for _, id in sgs.qlist(resp.m_card:getSubcards()) do
                        room:setCardFlag(sgs.Sanguosha:getCard(id), 'LuaShuangxiongResponded')
                    end
                else
                    room:setCardFlag(resp.m_card, 'LuaShuangxiongResponded')
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() then
                use.from:setFlags('LuaShuangxiongInvoke')
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            -- Clear all card flags
            if use.card and use.card:getSkillName() == self:objectName() then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    for _, card in sgs.qlist(p:getHandcards()) do
                        room:clearCardFlag(card)
                    end
                    for _, card in sgs.qlist(p:getEquips()) do
                        room:clearCardFlag(card)
                    end
                    p:setFlags('-LuaShuangxiongInvoke')
                end
                for _, id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    room:clearCardFlag(card)
                end
                for _, id in sgs.qlist(room:getDiscardPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    room:clearCardFlag(card)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

JieYanliangWenchou:addSkill(LuaShuangxiong)

JieLingtong = sgs.General(extension, 'JieLingtong', 'wu', '4', true)

LuaXuanfengCard =
    sgs.CreateSkillCard {
    name = 'LuaXuanfengCard',
    filter = function(self, targets, to_select)
        if #targets >= 2 then
            return false
        end
        if to_select:objectName() == sgs.Self:objectName() then
            return false
        end
        return sgs.Self:canDiscard(to_select, 'he')
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaXuanfeng')
        local map = {}
        local totaltarget
        for _, sp in ipairs(targets) do
            map[sp] = 1
        end
        totaltarget = #targets
        room:broadcastSkillInvoke('LuaXuanfeng')
        if totaltarget == 1 then
            for _, sp in ipairs(targets) do
                map[sp] = map[sp] + 1
            end
        end
        for _, sp in ipairs(targets) do
            while map[sp] > 0 do
                if source:isAlive() and sp:isAlive() and source:canDiscard(sp, 'he') then
                    local card_id =
                        room:askForCardChosen(source, sp, 'he', 'LuaXuanfeng', false, sgs.Card_MethodDiscard)
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, source:objectName(), sp:objectName())
                    room:throwCard(card_id, sp, source)
                    if room:getCurrent():objectName() == source:objectName() then
                        room:addPlayerMark(sp, 'LuaXuanfengTarget')
                    end
                end
                map[sp] = map[sp] - 1
            end
        end
        local damageAvailable = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark('LuaXuanfengTarget') > 0 then
                room:setPlayerMark(p, 'LuaXuanfengTarget', 0)
                damageAvailable:append(p)
            end
        end
        if not damageAvailable:isEmpty() then
            local target =
                room:askForPlayerChosen(source, damageAvailable, 'LuaXuanfeng', 'LuaXuanfengDamage-choose', true, true)
            if target then
                rinsanFuncModule.doDamage(room, source, target, 1)
                room:broadcastSkillInvoke('LuaXuanfeng')
            end
        end
    end
}

LuaXuanfengVS =
    sgs.CreateViewAsSkill {
    name = 'LuaXuanfeng',
    n = 0,
    view_as = function()
        return LuaXuanfengCard:clone()
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == '@@LuaXuanfeng'
    end
}

LuaXuanfeng =
    sgs.CreateTriggerSkill {
    name = 'LuaXuanfeng',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    view_as_skill = LuaXuanfengVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            player:setMark('LuaXuanfeng', 0)
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (not move.from) or (move.from:objectName() ~= player:objectName()) then
                return false
            end
            if
                (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard) and
                    rinsanFuncModule.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD)
             then
                player:setMark('LuaXuanfeng', player:getMark('LuaXuanfeng') + move.card_ids:length())
            end
            if
                ((player:getMark('LuaXuanfeng') >= 2) and (not player:hasFlag('LuaXuanfengUsed'))) or
                    move.from_places:contains(sgs.Player_PlaceEquip)
             then
                local targets = sgs.SPlayerList()
                for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:canDiscard(target, 'he') then
                        targets:append(target)
                    end
                end
                if targets:isEmpty() then
                    return false
                end
                if player:getPhase() == sgs.Player_Discard then
                    player:setFlags('LuaXuanfengUsed')
                end -- 修复源码Bug
                room:askForUseCard(player, '@@LuaXuanfeng', '@xuanfeng-card')
            end
        end
        return false
    end
}

LuaYongjinCard =
    sgs.CreateSkillCard {
    name = 'LuaYongjinCard',
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:hasEquip()
        elseif #selected == 1 then
            for i = 0, 4, 1 do
                if selected[1]:getEquip(i) and not to_select:getEquip(i) then
                    return to_select:hasEquipArea(i)
                end
            end
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, use)
        local thread = room:getThread()
        local data = sgs.QVariant()
        data:setValue(use)
        thread:trigger(sgs.PreCardUsed, room, use.from, data)
        thread:trigger(sgs.CardUsed, room, use.from, data)
        thread:trigger(sgs.CardFinished, room, use.from, data)
    end,
    on_use = function(self, room, source, targets)
        local from = targets[1]
        local to = targets[2]
        local disabled_ids = sgs.IntList()
        for _, equip in sgs.qlist(from:getEquips()) do
            local equip_index = equip:getRealCard():toEquipCard():location()
            -- 如果移动的目标角色没有对应的装备栏，或者装备栏已经有装备，则不可以移动
            if not to:hasEquipArea(equip_index) or (equip and to:getEquip(equip_index)) then
                disabled_ids:append(equip:getId())
            end
        end
        rinsanFuncModule.sendLogMessage(room, '#InvokeSkill', {['from'] = source, ['arg'] = 'LuaYongjin'})
        room:notifySkillInvoked(source, 'LuaYongjin')
        room:broadcastSkillInvoke('LuaYongjin')
        local card_id = room:askForCardChosen(source, from, 'e', 'LuaYongjin', false, sgs.Card_MethodNone, disabled_ids)
        local card = sgs.Sanguosha:getCard(card_id)
        room:moveCardTo(
            card,
            from,
            to,
            sgs.Player_PlaceEquip,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, from:objectName(), 'LuaYongjin', '')
        )
        room:addPlayerMark(source, 'LuaYongjin')
        local use = room:askForUseCard(source, '@@LuaYongjin', '@LuaYongjin:::' .. (3 - source:getMark('LuaYongjin')))
        if not use then
            room:setPlayerMark(source, 'LuaYongjin', 0)
            source:loseMark('@luayongjin')
        end
    end
}

LuaYongjinVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaYongjin',
    view_as = function(self, cards)
        return LuaYongjinCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getMark('@luayongjin') > 0 then
            if player:hasEquip() then
                return true
            end
            for _, sib in sgs.qlist(player:getAliveSiblings()) do
                if sib:hasEquip() then
                    return true
                end
            end
        end
        return false
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == '@@LuaYongjin' and target:getMark('@luayongjin') > 0 and target:getMark('LuaYongjin') < 3
    end
}

LuaYongjin =
    sgs.CreateTriggerSkill {
    name = 'LuaYongjin',
    frequency = sgs.Skill_Limited,
    limit_mark = '@luayongjin',
    view_as_skill = LuaYongjinVS,
    on_trigger = function()
    end
}

JieLingtong:addSkill(LuaXuanfeng)
JieLingtong:addSkill(LuaYongjin)

ExShenpei = sgs.General(extension, 'ExShenpei', 'qun', 3, true, true, false, 2)

LuaShouye =
    sgs.CreateTriggerSkill {
    name = 'LuaShouye',
    events = {sgs.TargetSpecified, sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf('SkillCard') or use.to:length() > 1 or use.to:contains(use.from) then
                return false
            end
            for _, p in sgs.qlist(use.to) do
                if p:getMark(self:objectName()) == 0 and p:hasSkill(self:objectName()) then
                    local data2 = sgs.QVariant()
                    data2:setValue(use.from)
                    if room:askForSkillInvoke(p, self:objectName(), data2) then
                        room:addPlayerMark(p, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, p:objectName(), use.from:objectName())
                        local choice1 = room:askForChoice(use.from, 'LuaShouye', 'syjg1+syjg2')
                        local choice2 = room:askForChoice(p, 'LuaShouye', 'syfy1+syfy2')
                        ChoiceLog(use.from, choice1, nil)
                        ChoiceLog(p, choice2, nil)
                        if (choice1 == 'syjg1' and choice2 == 'syfy1') or (choice1 == 'syjg2' and choice2 == 'syfy2') then
                            rinsanFuncModule.sendLogMessage(room, '#ShouyeSucceed', {['from'] = p})
                            local nullified_list = use.nullified_list
                            table.insert(nullified_list, p:objectName())
                            use.nullified_list = nullified_list
                            data:setValue(use)
                            local togain
                            if use.card:isVirtualCard() then
                                togain = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                                for _, id in sgs.qlist(use.card:getSubcards()) do
                                    togain:addSubcard(id)
                                end
                            else
                                togain = use.card
                            end
                            room:obtainCard(p, togain)
                        else
                            rinsanFuncModule.sendLogMessage(room, '#ShouyeFailed', {['from'] = p})
                        end
                    end
                end
            end
        else
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName(), 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaLiezhiCard =
    sgs.CreateSkillCard {
    name = 'LuaLiezhicard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected <= 1 and to_select:objectName() ~= sgs.Self:objectName() and
            sgs.Self:canDiscard(to_select, 'hej')
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaLiezhi')
        for _, p in ipairs(targets) do
            local card_id = room:askForCardChosen(source, p, 'hej', 'LuaLiezhi', false, sgs.Card_MethodDiscard)
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, source:objectName(), p:objectName())
            room:throwCard(card_id, p, source)
        end
    end
}

LuaLiezhiVS =
    sgs.CreateViewAsSkill {
    name = 'LuaLiezhi',
    n = 0,
    view_as = function()
        return LuaLiezhiCard:clone()
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == '@@LuaLiezhi'
    end
}

LuaLiezhi =
    sgs.CreateTriggerSkill {
    name = 'LuaLiezhi',
    events = {sgs.Damaged, sgs.EventPhaseStart},
    view_as_skill = LuaLiezhiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            room:addPlayerMark(player, self:objectName())
        else
            if player:getPhase() == sgs.Player_Start then
                if player:getMark(self:objectName()) == 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:canDiscard(p, 'hej') then
                            room:askForUseCard(player, '@@LuaLiezhi', '@LuaLiezhi')
                            break
                        end
                    end
                end
            elseif player:getPhase() == sgs.Player_Finish then
                room:setPlayerMark(player, self:objectName(), 0)
            end
        end
    end
}

ExShenpei:addSkill(LuaShouye)
ExShenpei:addSkill(LuaLiezhi)

ExYangbiao = sgs.General(extension, 'ExYangbiao', 'qun', '3', true)

LuaZhaohan =
    sgs.CreateTriggerSkill {
    name = 'LuaZhaohan',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getMark(self:objectName() .. 'up') < 4 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:setPlayerProperty(player, 'maxhp', sgs.QVariant(player:getMaxHp() + 1))
                rinsanFuncModule.sendLogMessage(room, '#addmaxhp', {['from'] = player, ['arg'] = 1})
                local theRecover = sgs.RecoverStruct()
                theRecover.recover = 1
                theRecover.who = player
                room:recover(player, theRecover)
                room:addPlayerMark(player, self:objectName() .. 'up')
            elseif player:getMark(self:objectName() .. 'down') < 3 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:loseMaxHp(player)
                room:addPlayerMark(player, self:objectName() .. 'down')
            end
        end
        return false
    end
}

LuaRangjieCard =
    sgs.CreateSkillCard {
    name = 'LuaRangjieCard',
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:hasEquip() or to_select:getJudgingArea():length() > 0
        elseif #selected == 1 then
            if selected[1]:getJudgingArea():length() > 0 then
                local judgeCards = {}
                -- 判断要移动到的角色是否有判定区
                if to_select:hasJudgeArea() then
                    for _, jcd in sgs.qlist(to_select:getJudgingArea()) do
                        table.insert(judgeCards, jcd:objectName())
                    end
                    for _, jcd in sgs.qlist(selected[1]:getJudgingArea()) do
                        if not table.contains(judgeCards, jcd:objectName()) then
                            return true
                        end
                    end
                end
            end
            for i = 0, 4, 1 do
                if selected[1]:getEquip(i) and not to_select:getEquip(i) then
                    -- 判断要移动到的角色是否有对应的装备栏
                    return to_select:hasEquipArea(i)
                end
            end
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, use)
        local thread = room:getThread()
        local data = sgs.QVariant()
        data:setValue(use)
        thread:trigger(sgs.PreCardUsed, room, use.from, data)
        thread:trigger(sgs.CardUsed, room, use.from, data)
        thread:trigger(sgs.CardFinished, room, use.from, data)
    end,
    on_use = function(self, room, source, targets)
        local from = targets[1]
        local to = targets[2]
        local disabled_ids = sgs.IntList()
        for _, equip in sgs.qlist(from:getEquips()) do
            local equip_index = equip:getRealCard():toEquipCard():location()
            -- 如果移动的目标角色没有对应的装备栏，或者装备栏已经有装备，则不可以移动
            if not to:hasEquipArea(equip_index) or (equip and to:getEquip(equip_index)) then
                disabled_ids:append(equip:getId())
            end
        end
        local judgeCards = {}
        for _, jcd in sgs.qlist(to:getJudgingArea()) do
            table.insert(judgeCards, jcd:objectName())
        end
        for _, jcd in sgs.qlist(from:getJudgingArea()) do
            -- 如果移动的目标角色没有判定区，或者判定区内有重复卡牌，则不可以移动
            if not to:hasJudgeArea() or table.contains(judgeCards, jcd:objectName()) then
                disabled_ids:append(jcd:getId())
            end
        end
        rinsanFuncModule.sendLogMessage(room, '#InvokeSkill', {['from'] = source, ['arg'] = 'LuaRangjie'})
        room:notifySkillInvoked(source, 'LuaRangjie')
        local card_id =
            room:askForCardChosen(source, from, 'ej', 'LuaRangjie', false, sgs.Card_MethodNone, disabled_ids)
        local card = sgs.Sanguosha:getCard(card_id)
        room:moveCardTo(
            card,
            from,
            to,
            room:getCardPlace(card_id),
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, from:objectName(), 'LuaRangjie', '')
        )
    end
}

LuaRangjieVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaRangjie',
    view_as = function(self)
        return LuaRangjieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaRangjie'
    end
}

LuaRangjie =
    sgs.CreateTriggerSkill {
    name = 'LuaRangjie',
    events = {sgs.Damaged},
    view_as_skill = LuaRangjieVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local i = 0
        while i < damage.damage do
            i = i + 1
            local move
            if rinsanFuncModule.canMoveCard(room) then
                move = room:askForUseCard(player, '@@LuaRangjie', '@LuaRangjie')
            end
            if not move then
                local choice =
                    room:askForChoice(player, self:objectName(), 'obtainBasic+obtainTrick+obtainEquip+cancel')
                local params = {['existed'] = {}, ['findDiscardPile'] = true}
                if choice == 'cancel' then
                    return false
                else
                    params['type'] = string.gsub(choice, 'obtain', '') .. 'Card'
                    local card = rinsanFuncModule.obtainTargetedTypeCard(room, params)
                    if card then
                        player:obtainCard(card, false)
                    end
                end
            end
            -- 只要发动了“让节”，就会摸牌，因为选择“取消”时已经跳出循环了，因此不需要冗余的判断
            player:drawCards(1, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
        end
        return false
    end
}

LuaYizhengCard =
    sgs.CreateSkillCard {
    name = 'LuaYizhengCard',
    filter = function(self, selected, to_select)
        if #selected < 1 then
            return to_select:getHp() <= sgs.Self:getHp() and sgs.Self:canPindian(to_select, 'LuaYizheng') and
                to_select:objectName() ~= sgs.Self:objectName()
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke('LuaYizheng')
        if source:pindian(target, 'LuaYizheng') then
            room:addPlayerMark(target, 'LuaYizhengSkipDrawPhase')
        else
            room:loseMaxHp(source)
        end
    end
}

LuaYizhengVS =
    sgs.CreateViewAsSkill {
    name = 'LuaYizheng',
    n = 0,
    view_as = function(self, cards)
        return LuaYizhengCard:clone()
    end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getSiblings()) do
            if not p:isKongcheng() and p:objectName() ~= player:objectName() and p:getHp() <= player:getHp() then
                return not player:hasUsed('#LuaYizhengCard')
            end
        end
        return false
    end
}

LuaYizheng =
    sgs.CreateTriggerSkill {
    name = 'LuaYizheng',
    events = {sgs.EventPhaseChanging},
    view_as_skill = LuaYizhengVS,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('LuaYizhengSkipDrawPhase') == 0 then
            return false
        end
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw then
            local splayer = room:findPlayerBySkillName(self:objectName())
            if splayer then
                room:sendCompulsoryTriggerLog(splayer, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, 'LuaYizhengSkipDrawPhase', 0)
                player:skip(change.to)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExYangbiao:addSkill(LuaZhaohan)
ExYangbiao:addSkill(LuaRangjie)
ExYangbiao:addSkill(LuaYizheng)

ExLuotong = sgs.General(extension, 'ExLuotong', 'wu', '4', true)

LuaQinzheng =
    sgs.CreateTriggerSkill {
    name = 'LuaQinzheng',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:isKindOf('SkillCard') then
            return false
        end
        room:addPlayerMark(player, '@' .. self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        local markNum = player:getMark('@' .. self:objectName())
        local card1 = rinsanFuncModule.LuaQinzhengGetCard(room, markNum, 3, 'Slash', 'Jink')
        if card1 then
            player:obtainCard(card1, false)
        end
        local card2 = rinsanFuncModule.LuaQinzhengGetCard(room, markNum, 5, 'Peach', 'Analeptic')
        if card2 then
            player:obtainCard(card2, false)
        end
        local card3 = rinsanFuncModule.LuaQinzhengGetCard(room, markNum, 8, 'Duel', 'ExNihilo')
        if card3 then
            player:obtainCard(card3, false)
        end
        return false
    end
}

ExLuotong:addSkill(LuaQinzheng)

ExZhangyi = sgs.General(extension, 'ExZhangyi', 'shu', '4', true, true)

LuaZhiyi =
    sgs.CreateTriggerSkill {
    name = 'LuaZhiyi',
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if sp:getMark(self:objectName() .. 'invoked') > 0 then
                        room:setPlayerMark(sp, self:objectName() .. 'invoked', 0)
                        room:broadcastSkillInvoke(self:objectName())
                        room:sendCompulsoryTriggerLog(sp, self:objectName())
                        local cardTypes = {}
                        for _, mark in sgs.list(sp:getMarkNames()) do
                            if string.find(mark, self:objectName()) and sp:getMark(mark) > 0 then
                                local type = string.gsub(mark, self:objectName(), '')
                                if type == 'peach' and sp:isWounded() then
                                    table.insert(cardTypes, type)
                                elseif type == 'analeptic' and sgs.Analeptic_IsAvailable(sp) then
                                    table.insert(cardTypes, type)
                                elseif string.find(type, 'slash') then
                                    for _, p in sgs.qlist(room:getOtherPlayers(sp)) do
                                        if sp:inMyAttackRange(p) then
                                            table.insert(cardTypes, type)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        table.insert(cardTypes, 'luazhiyidraw')
                        local choice = room:askForChoice(sp, self:objectName(), table.concat(cardTypes, '+'))
                        if choice == 'luazhiyidraw' then
                            sp:drawCards(1, self:objectName())
                        elseif choice == 'peach' or choice == 'analeptic' then
                            local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
                            card:setSkillName(self:objectName())
                            local card_use = sgs.CardUseStruct()
                            card_use.card = card
                            card_use.from = sp
                            card_use.to:append(sp)
                            room:broadcastSkillInvoke(self:objectName())
                            room:useCard(card_use, false)
                        else
                            local players = sgs.SPlayerList()
                            for _, p in sgs.qlist(room:getOtherPlayers(sp)) do
                                if sp:inMyAttackRange(p) then
                                    players:append(p)
                                end
                            end
                            if not players:isEmpty() then
                                local target =
                                    room:askForPlayerChosen(sp, players, self:objectName(), 'LuaZhiyiSlashTo')
                                if target then
                                    local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
                                    card:setSkillName(self:objectName())
                                    local card_use = sgs.CardUseStruct()
                                    card_use.card = card
                                    card_use.from = sp
                                    card_use.to:append(target)
                                    room:broadcastSkillInvoke(self:objectName())
                                    room:useCard(card_use, false)
                                end
                            end
                        end
                        for _, mark in sgs.list(sp:getMarkNames()) do
                            if string.find(mark, self:objectName()) and sp:getMark(mark) > 0 then
                                room:setPlayerMark(sp, mark, 0)
                            end
                        end
                    end
                end
            end
        else
            if not player:hasSkill(self:objectName()) then
                return false
            end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf('BasicCard') then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. card:objectName())
                room:addPlayerMark(player, self:objectName() .. 'invoked')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExZhangyi:addSkill(LuaZhiyi)

JieLiru = sgs.General(extension, 'JieLiru', 'qun', '3', true)

LuaJuece =
    sgs.CreateTriggerSkill {
    name = 'LuaJuece',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == room:getCurrent():objectName() then
                return false
            end
            if
                (move.from and (move.from:objectName() == player:objectName()) and
                    (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and
                    not (move.to and
                        (move.to:objectName() == player:objectName() and
                            (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
             then
                room:addPlayerMark(player, self:objectName())
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                if player:hasSkill(self:objectName()) then
                    local victims = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark(self:objectName()) > 0 then
                            victims:append(p)
                        end
                    end
                    if victims:isEmpty() then
                        return false
                    end
                    local victim =
                        room:askForPlayerChosen(player, victims, self:objectName(), '@LuaJueceDamageTo', true, true)
                    if victim then
                        room:broadcastSkillInvoke(self:objectName())
                        room:damage(sgs.DamageStruct(self:objectName(), player, victim))
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName(), 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaMiejiCard =
    sgs.CreateSkillCard {
    name = 'LuaMiejiCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]

        room:broadcastSkillInvoke('LuaMieji')
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), '', 'LuaMieji', '')
        room:moveCardTo(
            sgs.Sanguosha:getCard(self:getSubcards():first()),
            source,
            nil,
            sgs.Player_DrawPile,
            reason,
            true
        )
        local cards = target:getCards('he')
        local cardsCopy = cards

        for _, c in sgs.qlist(cardsCopy) do
            if target:isJilei(c) then
                cards:removeOne(c)
            end
        end

        if cards:isEmpty() then
            return
        end

        local pattern = '..!'
        local nonTrickNum = 0
        local trickExists = false
        for _, c in sgs.qlist(cards) do
            if c:isKindOf('TrickCard') then
                trickExists = true
            else
                nonTrickNum = nonTrickNum + 1
            end
        end

        if nonTrickNum < 2 and trickExists then
            pattern = 'TrickCard!'
        end

        local card = room:askForCard(target, pattern, '@LuaMiejiDiscard', sgs.QVariant(), sgs.Card_MethodNone)
        if card == nil then
            -- 随机抽卡
            if nonTrickNum < 2 and trickExists then
                cardsCopy = cards
                for _, c in sgs.qlist(cardsCopy) do
                    if not c:isKindOf('TrickCard') then
                        cards:removeOne(c)
                    end
                end
            end
            card = cards:at(math.random(0, cards:length() - 1))
        end
        if card then
            if card:isKindOf('TrickCard') then
                room:obtainCard(source, card)
                return
            else
                room:throwCard(card, target)
            end
        end

        if target:getCardCount(true) > 0 then
            room:askForDiscard(target, 'LuaMieji', 1, 1, false, true, '@LuaMiejiDiscardNonTrick', '^TrickCard')
        end
    end
}

LuaMieji =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaMieji',
    filter_pattern = 'TrickCard|black',
    view_as = function(self, card)
        local miejiCard = LuaMiejiCard:clone()
        miejiCard:addSubcard(card)
        return miejiCard
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMiejiCard')
    end
}

LuaFenchengCard =
    sgs.CreateSkillCard {
    name = 'LuaFenchengCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        source:loseMark('@burn')
        room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
        room:broadcastSkillInvoke('LuaFencheng')
        room:setEmotion(source, 'skill/fencheng')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, source:objectName(), p:objectName())
        end
        room:getThread():delay(4000)
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                local length = room:getTag('LuaFenchengDiscard'):toInt() + 1
                if
                    not p:canDiscard(p, 'he') or p:getCardCount(true) < length or
                        not room:askForDiscard(p, 'fencheng', 10000, length, true, true, '@fencheng:::' .. length)
                 then
                    room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
                    rinsanFuncModule.doDamage(room, source, p, 2, sgs.DamageStruct_Fire)
                end
            end
        end
    end
}

LuaFenchengVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaFencheng',
    view_as = function(self, cards)
        return LuaFenchengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@burn') > 0
    end
}

LuaFencheng =
    sgs.CreateTriggerSkill {
    name = 'LuaFencheng',
    frequency = sgs.Skill_Limited,
    limit_mark = '@burn',
    view_as_skill = LuaFenchengVS,
    events = {sgs.ChoiceMade},
    on_trigger = function(self, event, player, data, room)
        local dataStr = data:toString():split(':')
        if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~= 'fencheng' then
            return false
        end
        room:setTag('LuaFenchengDiscard', sgs.QVariant(#dataStr[3]:split('+')))
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

JieLiru:addSkill(LuaJuece)
JieLiru:addSkill(LuaMieji)
JieLiru:addSkill(LuaFencheng)

JieManchong = sgs.General(extension, 'JieManchong', 'wei', '3', true)

LuaJunxingCard =
    sgs.CreateSkillCard {
    name = 'LuaJunxingCard',
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:objectName() ~= sgs.Self:objectName()
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaJunxing')
        local target = targets[1]
        local len = self:subcardsLength()
        if room:askForDiscard(target, 'LuaJunxing', len, len, true, true, '@LuaJunxing:::' .. len) then
            room:loseHp(target)
        else
            target:turnOver()
            target:drawCards(len, 'LuaJunxing')
        end
    end
}

LuaJunxing =
    sgs.CreateViewAsSkill {
    name = 'LuaJunxing',
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards >= 1 then
            local vs_card = LuaJunxingCard:clone()
            for _, cd in ipairs(cards) do
                vs_card:addSubcard(cd)
            end
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaJunxingCard') and not player:isKongcheng()
    end
}

LuaYuce =
    sgs.CreateTriggerSkill {
    name = 'LuaYuce',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:isKongcheng() then
            return false
        end
        local card = room:askForCard(player, '.', '@LuaYuce-show', data, sgs.Card_MethodNone)
        if card then
            rinsanFuncModule.skill(self, room, player, true)
            room:showCard(player, card:getEffectiveId())
            if damage.from == nil or damage.from:isDead() then
                return false
            end
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
            local typeName = {'BasicCard', 'TrickCard', 'EquipCard'}
            local toRemove = rinsanFuncModule.firstToUpper(rinsanFuncModule.replaceUnderline(card:getType())) .. 'Card'
            table.removeOne(typeName, toRemove)
            if
                not damage.from:canDiscard(damage.from, 'h') or
                    not room:askForCard(
                        damage.from,
                        table.concat(typeName, ',') .. '|.|.|hand',
                        '@yuce-discard:' .. player:objectName() .. '::' .. typeName[1] .. ':' .. typeName[2],
                        data
                    )
             then
                room:getThread():delay(1500)
                room:recover(player, sgs.RecoverStruct(player, nil, 1))
            end
        end
        return false
    end
}

JieManchong:addSkill(LuaJunxing)
JieManchong:addSkill(LuaYuce)

JieLiaohua = sgs.General(extension, 'JieLiaohua', 'shu', '4', true)

LuaDangxian =
    sgs.CreateTriggerSkill {
    name = 'LuaDangxian',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_RoundStart then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            -- 关索征南单独处理
            if player:hasSkill('LuaZhengnan') then
                room:broadcastSkillInvoke(self:objectName(), 3)
            else
                room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
            end
            rinsanFuncModule.sendLogMessage(room, '#LuaDangxianExtraPhase', {['from'] = player})
            player:setPhase(sgs.Player_Play)
            local card = rinsanFuncModule.getCardFromDiscardPile(room, 'Slash')
            if card then
                player:obtainCard(card, false)
            end
            room:broadcastProperty(player, 'phase')
            local thread = room:getThread()
            if not thread:trigger(sgs.EventPhaseStart, room, player) then
                thread:trigger(sgs.EventPhaseProceeding, room, player)
            end
            thread:trigger(sgs.EventPhaseEnd, room, player)
            player:setPhase(sgs.Player_RoundStart)
            room:broadcastProperty(player, 'phase')
        end
        return false
    end
}

LuaFuli =
    sgs.CreateTriggerSkill {
    name = 'LuaFuli',
    events = {sgs.AskForPeaches},
    frequency = sgs.Skill_Limited,
    limit_mark = '@laoji',
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() ~= player:objectName() then
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:removePlayerMark(player, '@laoji')
            local recover = sgs.RecoverStruct()
            recover.recover = math.min(rinsanFuncModule.getKingdomCount(room), player:getMaxHp()) - player:getHp()
            room:recover(player, recover)
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHp() >= player:getHp() then
                    return false
                end
            end
            player:turnOver()
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and target:getMark('@laoji') > 0
    end
}

JieLiaohua:addSkill(LuaDangxian)
JieLiaohua:addSkill(LuaFuli)

JieZhuran = sgs.General(extension, 'JieZhuran', 'wu', '4', true)

LuaDanshou =
    sgs.CreateTriggerSkill {
    name = 'LuaDanshou',
    events = {sgs.TargetSpecified, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf('SkillCard') then
                return false
            end
            for _, p in sgs.qlist(use.to) do
                room:addPlayerMark(p, self:objectName())
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if sp:objectName() ~= player:objectName() then
                        local num = sp:getMark(self:objectName())
                        if num == 0 then
                            if room:askForSkillInvoke(sp, self:objectName()) then
                                room:broadcastSkillInvoke(self:objectName())
                                sp:drawCards(1, self:objectName())
                            end
                        else
                            if room:askForDiscard(sp, 'LuaDanshou', num, num, true, true, '@LuaDanshou:::' .. num) then
                                rinsanFuncModule.skill(self, room, sp, true)
                                room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, sp:objectName(), player:objectName())
                                rinsanFuncModule.doDamage(room, sp, player, 1)
                            end
                        end
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName(), 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

JieZhuran:addSkill(LuaDanshou)

JieYujin = sgs.General(extension, 'JieYujin', 'wei', '4', true, true)

LuaJieyueCard =
    sgs.CreateSkillCard {
    name = 'LuaJieyueCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        target:obtainCard(card, false)
        room:broadcastSkillInvoke('LuaJieyue')
        local data = sgs.QVariant()
        data:setValue(source)
        local choice = room:askForChoice(target, 'LuaJieyue', 'luajieyuediscard+luajieyuedraw', data)
        if choice == 'luajieyuediscard' then
            local hand_card_id
            local equip_card_id
            if target:canDiscard(target, 'h') then
                hand_card_id = room:askForCardChosen(target, target, 'h', 'LuaJieyue', false, sgs.Card_MethodNone)
            end
            if target:canDiscard(target, 'e') then
                equip_card_id = room:askForCardChosen(target, target, 'e', 'LuaJieyue', false, sgs.Card_MethodNone)
            end
            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            for _, cd in sgs.qlist(target:getCards('he')) do
                local id = cd:getEffectiveId()
                if id ~= hand_card_id and id ~= equip_card_id then
                    dummy:addSubcard(cd)
                end
            end
            room:throwCard(dummy, target)
        else
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, target:objectName(), source:objectName())
            source:drawCards(3, 'LuaJieyue')
        end
    end
}

LuaJieyueVS =
    sgs.CreateViewAsSkill {
    name = 'LuaJieyue',
    n = 1,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = LuaJieyueCard:clone()
            card:addSubcard(cards[1])
            return card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaJieyue'
    end
}

LuaJieyue =
    sgs.CreateTriggerSkill {
    name = 'LuaJieyue',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaJieyueVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if not player:isNude() then
                room:askForUseCard(player, '@@LuaJieyue', '@LuaJieyue')
            end
        end
    end
}

JieYujin:addSkill(LuaJieyue)

ExTenYearLiuzan = sgs.General(extension, 'ExTenYearLiuzan', 'wu', '4', true, true)

LuaFenyin =
    sgs.CreateTriggerSkill {
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
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, self:objectName()) and p:getMark(mark) > 0 then
                            room:setPlayerMark(p, mark, 0)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaLijiCard =
    sgs.CreateSkillCard {
    name = 'LuaLijiCard',
    target_fixed = false,
    will_throw = true,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        room:broadcastSkillInvoke('LuaLiji')
        room:damage(sgs.DamageStruct(self:objectName(), source, target))
    end
}

LuaLijiVS =
    sgs.CreateViewAsSkill {
    name = 'LuaLiji',
    n = 1,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
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
    end
}

LuaLiji =
    sgs.CreateTriggerSkill {
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
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, self:objectName()) and p:getMark(mark) > 0 then
                            room:setPlayerMark(p, mark, 0)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExTenYearLiuzan:addSkill(LuaFenyin)
ExTenYearLiuzan:addSkill(LuaLiji)

ExWangcan = sgs.General(extension, 'ExWangcan', 'wei', '3', true, true)

LuaQiaiCard =
    sgs.CreateSkillCard {
    name = 'LuaQiaiCard',
    target_fixed = false,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        target:obtainCard(card, false)
        room:broadcastSkillInvoke('LuaQiai')
        local choices = 'letdraw2'
        if source:isWounded() then
            choices = choices .. '+letrecover'
        end
        local choice = room:askForChoice(target, 'LuaQiai', choices)
        if choice == 'letdraw2' then
            source:drawCards(2, 'LuaQiai')
        else
            local theRecover = sgs.RecoverStruct()
            theRecover.recover = 1
            theRecover.who = target
            room:recover(source, theRecover)
        end
    end
}

LuaQiai =
    sgs.CreateViewAsSkill {
    name = 'LuaQiai',
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isKindOf('BasicCard')
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local vs_card = LuaQiaiCard:clone()
            vs_card:addSubcard(cards[1])
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaQiaiCard')
    end
}

LuaShanxi =
    sgs.CreateTriggerSkill {
    name = 'LuaShanxi',
    events = {sgs.EventPhaseStart, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName() .. player:objectName(), 0)
                end
                local target =
                    room:askForPlayerChosen(
                    player,
                    room:getOtherPlayers(player),
                    self:objectName(),
                    'LuaShanxi-choose',
                    true,
                    true
                )
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(target, self:objectName() .. player:objectName())
                end
            end
        elseif event == sgs.HpRecover then
            local splayers = room:findPlayersBySkillName(self:objectName())
            for _, sp in sgs.qlist(splayers) do
                if player:getMark(self:objectName() .. sp:objectName()) > 0 then
                    if player:getHp() <= 0 then
                        return false
                    end
                    local chooseLoseHp = true
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(sp, self:objectName())
                    if player:getCardCount(true) >= 2 then
                        local card =
                            room:askForExchange(
                            player,
                            self:objectName(),
                            2,
                            2,
                            true,
                            'LuaShanxi-give:' .. sp:objectName(),
                            true
                        )
                        if card then
                            chooseLoseHp = false
                            room:obtainCard(sp, card, false)
                        end
                    end
                    if chooseLoseHp then
                        room:loseHp(player)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExWangcan:addSkill(LuaQiai)
ExWangcan:addSkill(LuaShanxi)

ExZhouchu = sgs.General(extension, 'ExZhouchu', 'wu', '4', true, true)

LuaXianghai =
    sgs.CreateFilterSkill {
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
    end
}

LuaXianghaiMaxCards =
    sgs.CreateMaxCardsSkill {
    name = '#LuaXianghai',
    extra_func = function(self, target)
        local count = 0
        for _, sib in sgs.qlist(target:getAliveSiblings()) do
            if sib:hasSkill('LuaXianghai') then
                count = count - 1
            end
        end
        return count
    end
}

LuaChuhaiCard =
    sgs.CreateSkillCard {
    name = 'LuaChuhaiCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
            sgs.Self:canPindian(to_select, 'LuaChuhai')
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        source:drawCards(1, 'LuaChuhai')
        if source:pindian(target, 'LuaChuhai') then
            room:addPlayerMark(target, 'LuaChuhai')
            if target:isKongcheng() then
                return
            end
            room:showAllCards(target, source)
            local cardTypes = {}
            for _, cd in sgs.qlist(target:getHandcards()) do
                local typeStr = rinsanFuncModule.firstToUpper(rinsanFuncModule.replaceUnderline(cd:getType())) .. 'Card'
                if not table.contains(cardTypes, typeStr) then
                    table.insert(cardTypes, typeStr)
                end
            end
            local params = {
                ['findDiscardPile'] = true
            }
            for _, cardType in ipairs(cardTypes) do
                params['type'] = cardType
                local toObtain = rinsanFuncModule.obtainTargetedTypeCard(room, params)
                if toObtain then
                    room:obtainCard(source, toObtain, false)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end
}

LuaChuhaiVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaChuhai',
    view_as = function(self, cards)
        return LuaChuhaiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaChuhaiCard')
    end
}

LuaChuhai =
    sgs.CreateTriggerSkill {
    name = 'LuaChuhai',
    events = {sgs.Damage, sgs.EventPhaseChanging},
    view_as_skill = LuaChuhaiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if (not damage.from) or damage.from:objectName() ~= player:objectName() then
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
                    local type = rinsanFuncModule.getEquipTypeStr(equip_index)
                    local params = {
                        ['type'] = type,
                        ['findDiscardPile'] = true
                    }
                    local equip = rinsanFuncModule.obtainTargetedTypeCard(room, params)
                    if equip then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        room:moveCardTo(
                            equip,
                            nil,
                            player,
                            sgs.Player_PlaceEquip,
                            sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_TRANSFER,
                                player:objectName(),
                                self:objectName(),
                                ''
                            ),
                            true
                        )
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName(), 0)
                end
            end
        end
        return false
    end
}

ExZhouchu:addSkill(LuaXianghai)
ExZhouchu:addSkill(LuaChuhai)
SkillAnjiang:addSkill(LuaXianghaiMaxCards)

JieSunce = sgs.General(extension, 'JieSunce$', 'wu', '4', true)

LuaJiang =
    sgs.CreateTriggerSkill {
    name = 'LuaJiang',
    events = {sgs.TargetConfirmed, sgs.TargetSpecified},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, sunce, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(sunce)) then
            if use.card:isKindOf('Duel') or (use.card:isKindOf('Slash') and use.card:isRed()) then
                if sunce:askForSkillInvoke(self:objectName(), data) then
                    sunce:drawCards(1, self:objectName())
                    math.randomseed(os.time())
                    room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                end
            end
        end
        return false
    end
}

LuaYingzi =
    sgs.CreateTriggerSkill {
    name = 'LuaYingzi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local count = data:toInt() + 1
            math.randomseed(os.time())
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, 'drawed')
            data:setValue(count)
        end
    end
}

LuaYingziMaxCard =
    sgs.CreateMaxCardsSkill {
    name = '#LuaYingzi',
    fixed_func = function(self, target)
        if target:hasSkill('LuaYingzi') then
            return target:getMaxHp()
        else
            return -1
        end
    end
}

LuaYinghunCard =
    sgs.CreateSkillCard {
    name = 'LuaYinghunCard',
    target_fixed = false,
    will_throw = true,
    on_effect = function(self, effect)
        local source = effect.from
        local dest = effect.to
        local x = source:getLostHp()
        local room = source:getRoom()
        local good = false
        if x > 1 then
            local data = sgs.QVariant()
            data:setValue(dest)
            local choice = room:askForChoice(source, 'LuaYinghun', 'd1tx+dxt1', data)
            if choice == 'd1tx' then
                room:broadcastSkillInvoke('LuaYinghun')
                dest:drawCards(1, 'LuaYinghun')
                x = math.min(x, dest:getCardCount(true))
                room:askForDiscard(dest, self:objectName(), x, x, false, true)
                good = false
            elseif choice == 'dxt1' then
                room:broadcastSkillInvoke('LuaYinghun')
                dest:drawCards(x, 'LuaYinghun')
                room:askForDiscard(dest, self:objectName(), 1, 1, false, true)
                good = true
            end
            if good then
                room:setEmotion(dest, 'good')
            else
                room:setEmotion(dest, 'bad')
            end
        else
            room:broadcastSkillInvoke('LuaYinghun')
            dest:drawCards(1, 'LuaYinghun')
            room:askForDiscard(dest, self:objectName(), 1, 1, false, true)
            room:setEmotion(dest, 'good')
        end
    end
}

LuaYinghunVS =
    sgs.CreateViewAsSkill {
    name = 'LuaYinghun',
    n = 0,
    view_as = function(self, cards)
        return LuaYinghunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaYinghun'
    end
}

LuaYinghun =
    sgs.CreateTriggerSkill {
    name = 'LuaYinghun',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaYinghunVS,
    on_trigger = function(self, event, player, data, room)
        room:askForUseCard(player, '@@LuaYinghun', '@yinghun')
        return false
    end,
    can_trigger = function(self, target)
        if rinsanFuncModule.RIGHT(self, target) then
            if target:getPhase() == sgs.Player_Start then
                return target:isWounded()
            end
        end
        return false
    end
}

LuaHunzi =
    sgs.CreateTriggerSkill {
    name = 'LuaHunzi',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, 'LuaHunzi')
        rinsanFuncModule.sendLogMessage(room, '#Hunzi', {['from'] = player, ['arg'] = player:getHp()})
        if room:changeMaxHpForAwakenSkill(player) then
            room:broadcastSkillInvoke(self:objectName())
            room:getThread():delay(6500)
            local theRecover = sgs.RecoverStruct()
            theRecover.recover = 1
            theRecover.who = player
            room:recover(player, theRecover)
            room:setEmotion(player, 'skill/hunzi')
            room:handleAcquireDetachSkills(player, 'LuaYingzi|LuaYinghun')
            room:addPlayerMark(player, 'hunzi')
        end
        return false
    end,
    can_trigger = function(self, target)
        return (rinsanFuncModule.RIGHT(self, target)) and (target:getMark('LuaHunzi') == 0) and
            (target:getPhase() == sgs.Player_Start) and
            (target:getHp() <= 2)
    end
}

SkillAnjiang:addSkill(LuaYingzi)
SkillAnjiang:addSkill(LuaYinghun)
SkillAnjiang:addSkill(LuaYingziMaxCard)
JieSunce:addSkill(LuaJiang)
JieSunce:addSkill(LuaHunzi)
JieSunce:addSkill('zhiba')
JieSunce:addRelateSkill('LuaYingzi')
JieSunce:addRelateSkill('LuaYinghun')

ExDuyu = sgs.General(extension, 'ExDuyu', 'qun', '4', true, true)

LuaWuku =
    sgs.CreateTriggerSkill {
    name = 'LuaWuku',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('EquipCard') then
            for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if sp:getMark('@wuku') < 3 then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(sp, self:objectName())
                    sp:gainMark('@wuku')
                end
            end
        end
    end
}

LuaSanchen =
    sgs.CreateTriggerSkill {
    name = 'LuaSanchen',
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        if room:changeMaxHpForAwakenSkill(player, 1) then
            room:broadcastSkillInvoke(self:objectName())
            room:recover(player, sgs.RecoverStruct(player, nil, 1))
            room:handleAcquireDetachSkills(player, 'LuaMiewu')
            room:addPlayerMark(player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and target:getMark(self:objectName()) == 0 and
            target:getPhase() == sgs.Player_Finish and
            target:getMark('@wuku') > 2
    end
}

LuaMiewuCard =
    sgs.CreateSkillCard {
    name = 'LuaMiewuCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card
            if self:getUserString() and self:getUserString() ~= '' then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
                return card and card:targetFilter(players, to_select, sgs.Self) and
                    not sgs.Self:isProhibited(to_select, card, players)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local _card = sgs.Self:getTag('LuaMiewu'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:deleteLater()
        return card and card:targetFilter(players, to_select, sgs.Self) and
            not sgs.Self:isProhibited(to_select, card, players)
    end,
    feasible = function(self, targets)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card
            if self:getUserString() and self:getUserString() ~= '' then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
                return card and card:targetsFeasible(players, sgs.Self)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local _card = sgs.Self:getTag('LuaMiewu'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:deleteLater()
        return card and card:targetsFeasible(players, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local to_use = self:getUserString()
        room:addPlayerMark(source, 'LuaMiewu')
        source:loseMark('@wuku')
        if
            to_use == 'slash' and
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'miewu_slash', table.concat(use_list, '+'))
            source:setTag('MiewuSlash', sgs.QVariant(to_use))
        end
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local user_str = to_use
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        use_card:setSkillName('LuaMiewu')
        use_card:addSubcard(self:getSubcards():first())
        use_card:deleteLater()
        local tos = card_use.to
        for _, to in sgs.qlist(tos) do
            local skill = room:isProhibited(source, to, use_card)
            if skill then
                card_use.to:removeOne(to)
            end
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local to_use
        room:addPlayerMark(source, 'LuaMiewu')
        source:loseMark('@wuku')
        if self:getUserString() == 'peach+analeptic' then
            local use_list = {}
            table.insert(use_list, 'peach')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'analeptic')
            end
            to_use = room:askForChoice(source, 'miewu_saveself', table.concat(use_list, '+'))
            source:setTag('MiewuSaveSelf', sgs.QVariant(to_use))
        elseif self:getUserString() == 'slash' then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'miewu_slash', table.concat(use_list, '+'))
            source:setTag('MiewuSlash', sgs.QVariant(to_use))
        else
            to_use = self:getUserString()
        end
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local user_str
        if to_use == 'slash' then
            user_str = 'slash'
        elseif to_use == 'normal_slash' then
            user_str = 'slash'
        else
            user_str = to_use
        end
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        use_card:setSkillName('LuaMiewu')
        use_card:addSubcard(self)
        use_card:deleteLater()
        return use_card
    end
}

LuaMiewuVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaMiewu',
    filter_pattern = '.|.|.|.',
    response_or_use = true,
    enabled_at_response = function(self, player, pattern)
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        if
            player:isNude() or string.sub(pattern, 1, 1) == '.' or player:getMark('@wuku') <= 0 or
                string.sub(pattern, 1, 1) == '@' or
                player:getMark('LuaMiewu') > 0
         then
            return false
        end
        if pattern == 'peach' and player:getMark('Global_PreventPeach') > 0 then
            return false
        end
        if string.find(pattern, '[%u%d]') then
            return false
        end -- 这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
        return true
    end,
    enabled_at_play = function(self, player)
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        return not player:isNude() and player:getMark('LuaMiewu') == 0 and player:getMark('@wuku') > 0
    end,
    enabled_at_nullification = function(self, player)
        return not player:isNude() and player:getMark('LuaMiewu') == 0 and player:getMark('@wuku') > 0
    end,
    view_as = function(self, cards)
        if
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
            local card = LuaMiewuCard:clone()
            card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            card:addSubcard(cards)
            return card
        end
        local c = sgs.Self:getTag('LuaMiewu'):toCard()
        if c then
            local card = LuaMiewuCard:clone()
            card:setUserString(c:objectName())
            card:addSubcard(cards)
            return card
        else
            return nil
        end
    end
}

LuaMiewu =
    sgs.CreateTriggerSkill {
    name = 'LuaMiewu',
    events = {sgs.TurnStart, sgs.CardUsed, sgs.CardResponded},
    view_as_skill = LuaMiewuVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill('LuaMiewu') then
                    room:setPlayerMark(p, 'LuaMiewu', 0)
                end
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:getSkillName() == self:objectName() and player:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(1, self:objectName())
            end
        end
    end
}
LuaMiewu:setGuhuoDialog('lrd')

SkillAnjiang:addSkill(LuaMiewu)
ExDuyu:addSkill(LuaWuku)
ExDuyu:addSkill(LuaSanchen)
ExDuyu:addRelateSkill('LuaMiewu')

ExChenzhen = sgs.General(extension, 'ExChenzhen', 'shu', '3', true, true)

LuaShamengCard =
    sgs.CreateSkillCard {
    name = 'LuaShamengCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local sourse = effect.from
        local dest = effect.to
        local room = sourse:getRoom()
        room:broadcastSkillInvoke('LuaShameng')
        room:drawCards(sourse, 3, 'LuaShameng')
        room:drawCards(dest, 2, 'LuaShameng')
    end
}
LuaShameng =
    sgs.CreateViewAsSkill {
    name = 'LuaShameng',
    n = 2,
    view_filter = function(self, selected, to_select)
        if to_select:isEquipped() then
            return false
        end
        if #selected == 0 then
            return true
        elseif #selected == 1 then
            return selected[1]:sameColorWith(to_select)
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards < 2 then
            return nil
        end
        local vs_card = LuaShamengCard:clone()
        vs_card:addSubcard(cards[1])
        vs_card:addSubcard(cards[2])
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaShamengCard')
    end
}

ExChenzhen:addSkill(LuaShameng)

ExGongsunkang = sgs.General(extension, 'ExGongsunkang', 'qun', '4', true)

LuaJuliao =
    sgs.CreateDistanceSkill {
    name = 'LuaJuliao',
    correct_func = function(self, from, to)
        if to:hasSkill(self:objectName()) then
            local kingdoms = {to:getKingdom()}
            for _, sib in sgs.qlist(to:getAliveSiblings()) do
                if not table.contains(kingdoms, sib:getKingdom()) then
                    table.insert(kingdoms, sib:getKingdom())
                end
            end
            return #kingdoms - 1
        end
        return 0
    end
}

LuaTaomie =
    sgs.CreateTriggerSkill {
    name = 'LuaTaomie',
    events = {sgs.Damage, sgs.Damaged, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.Damage then
            if player:getMark(self:objectName() .. 'Delay') == 0 then
                local data2 = sgs.QVariant()
                data2:setValue(damage.to)
                if not damage.to:isAlive() then
                    return false
                end
                if
                    damage.to:getMark('@' .. self:objectName()) == 0 and
                        room:askForSkillInvoke(player, self:objectName(), data2)
                 then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:setPlayerMark(p, '@' .. self:objectName(), 0)
                    end
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    damage.to:gainMark('@' .. self:objectName())
                end
            elseif player:getMark(self:objectName() .. 'Delay') > 0 then
                room:setPlayerMark(player, self:objectName() .. 'Delay', 0)
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, '@' .. self:objectName(), 0)
                end
            end
        elseif event == sgs.Damaged then
            if damage.from then
                local data2 = sgs.QVariant()
                data2:setValue(damage.from)
                if
                    damage.from:getMark('@' .. self:objectName()) == 0 and
                        room:askForSkillInvoke(player, self:objectName(), data2)
                 then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:setPlayerMark(p, '@' .. self:objectName(), 0)
                    end
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
                    damage.from:gainMark('@' .. self:objectName())
                end
            end
        elseif event == sgs.DamageCaused then
            if damage.to and damage.to:getMark('@' .. self:objectName()) > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local choices = {'addDamage'}
                if not damage.to:isAllNude() then
                    table.insert(choices, 'getOneCard')
                    table.insert(choices, 'removeMark')
                end
                table.insert(choices, 'cancel')
                local data2 = sgs.QVariant()
                data2:setValue(damage.to)
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'), data2)
                if choice ~= 'cancel' then
                    room:broadcastSkillInvoke(self:objectName(), math.random(2, 3))
                end
                if choice == 'addDamage' then
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    damage.damage = damage.damage + 1
                elseif choice == 'getOneCard' then
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    if not damage.to:isAllNude() then
                        rinsanFuncModule.obtainOneCardAndGiveToOtherPlayer(self, room, player, damage.to)
                    end
                elseif choice == 'removeMark' then
                    damage.damage = damage.damage + 1
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    if not damage.to:isAllNude() then
                        rinsanFuncModule.obtainOneCardAndGiveToOtherPlayer(self, room, player, damage.to)
                    end
                    room:addPlayerMark(player, self:objectName() .. 'Delay')
                end
                data:setValue(damage)
            end
        end
        return false
    end
}

ExGongsunkang:addSkill(LuaJuliao)
ExGongsunkang:addSkill(LuaTaomie)

ExZhangji = sgs.General(extension, 'ExZhangji', 'qun', '4', true, true)

LuaLvemingCard =
    sgs.CreateSkillCard {
    name = 'LuaLvemingCard',
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:getEquips():length() < sgs.Self:getEquips():length()
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local numbers = {}
        for i = 1, 13 do
            table.insert(numbers, tostring(i))
        end
        room:broadcastSkillInvoke('LuaLveming')
        local chosenNum = room:askForChoice(target, 'LuaLveming', table.concat(numbers, '+'))

        rinsanFuncModule.sendLogMessage(room, '#choose', {['from'] = target, ['arg'] = chosenNum})

        local judge =
            rinsanFuncModule.createJudgeStruct(
            {
                ['play_animation'] = true,
                ['who'] = source,
                ['reason'] = 'LuaLveming'
            }
        )
        room:judge(judge)
        if judge.card:getNumber() == tonumber(chosenNum) then
            rinsanFuncModule.doDamage(room, source, target, 2)
        else
            local cards = target:getCards('hej')
            if not cards:isEmpty() then
                local card = cards:at(math.random(0, cards:length() - 1))
                if card then
                    room:obtainCard(source, card, false)
                end
            end
        end
        room:addPlayerMark(source, 'LuaLveming')
    end
}

LuaLveming =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaLveming',
    view_as = function(self, cards)
        return LuaLvemingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaLvemingCard')
    end
}

LuaTunjunCard =
    sgs.CreateSkillCard {
    name = 'LuaTunjunCard',
    filter = function(self, selected, to_select)
        return #selected == 0
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke('LuaTunjun')
        source:loseMark('@LuaTunjun')
        local times = source:getMark('LuaLveming')
        local i = 0
        local params = {
            ['type'] = 'EquipCard'
        }
        while i < times do
            i = i + 1
            local equipCard = rinsanFuncModule.obtainTargetedTypeCard(room, params)
            if equipCard then
                if target:getEquip(equipCard:getRealCard():toEquipCard():location()) then
                    room:throwCard(equipCard, source)
                else
                    local card_use = sgs.CardUseStruct()
                    card_use.from = source
                    card_use.to:append(target)
                    card_use.card = equipCard
                    room:useCard(card_use, true)
                end
            else
                break
            end
        end
    end
}

LuaTunjunVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaTunjun',
    view_as = function(self, cards)
        return LuaTunjunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaTunjun') > 0 and player:getMark('LuaLveming') > 0
    end
}

LuaTunjun =
    sgs.CreateTriggerSkill {
    name = 'LuaTunjun',
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaTunjun',
    view_as_skill = LuaTunjunVS,
    on_trigger = function()
    end
}

ExZhangji:addSkill(LuaLveming)
ExZhangji:addSkill(LuaTunjun)

ExTenYearDongcheng = sgs.General(extension, 'ExTenYearDongcheng', 'qun', '4', true, true)

LuaXuezhaoCard =
    sgs.CreateSkillCard {
    name = 'LuaXuezhaoCard',
    filter = function(self, selected, to_select)
        return #selected < sgs.Self:getHp() and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        for _, target in ipairs(targets) do
            local card =
                room:askForCard(
                target,
                '.',
                '@LuaXuezhao-give:' .. source:objectName(),
                sgs.QVariant(),
                sgs.Card_MethodNone
            )
            if card then
                target:drawCards(1, 'LuaXuezhao')
                room:addPlayerMark(source, 'LuaXuezhao-Slash')
                source:obtainCard(card, false)
            else
                room:addPlayerMark(target, 'LuaXuezhao-Nogive')
                room:addPlayerMark(source, 'LuaXuezhao-Force')
            end
        end
    end
}

LuaXuezhaoVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaXuezhao',
    view_filter = function(self, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, card)
        local vs_card = LuaXuezhaoCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed('#LuaXuezhaoCard')
    end
}

LuaXuezhao =
    sgs.CreateTriggerSkill {
    name = 'LuaXuezhao',
    view_as_skill = LuaXuezhaoVS,
    events = {
        sgs.EventPhaseChanging,
        sgs.CardUsed,
        sgs.TargetConfirmed,
        sgs.TrickCardCanceling,
        sgs.CardFinished,
        sgs.CardAsked
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, 'LuaXuezhao-Nogive', 0)
                end
                room:setPlayerMark(player, 'LuaXuezhao-Slash', 0)
                room:setPlayerMark(player, 'LuaXuezhao-Force', 0)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            local invoke = false
            if
                use.from and use.from:hasSkill(self:objectName()) and
                    (use.card:isKindOf('Slash') or use.card:isNDTrick())
             then
                for _, p in sgs.qlist(use.to) do
                    if p:getMark('LuaXuezhao-Nogive') > 0 then
                        invoke = true
                        room:addPlayerMark(p, '@LuaXuezhaoTarget')
                    end
                end
                if invoke and use.from:hasSkill(self:objectName()) then
                    room:sendCompulsoryTriggerLog(use.from, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(use.from, self:objectName() .. 'engine')
                    if use.from:getMark(self:objectName() .. 'engine') > 0 then
                        room:removePlayerMark(use.from, self:objectName() .. 'engine')
                    end
                end
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                use.from:setTag('XuezhaoSlash', sgs.QVariant(use.from:getTag('XuezhaoSlash'):toInt() + 1))
                if rinsanFuncModule.RIGHT(self, use.from) and player:getMark('LuaXuezhao-Nogive') > 0 then
                    local jink_table = sgs.QList2Table(use.from:getTag('Jink_' .. use.card:toString()):toIntList())
                    jink_table[use.from:getTag('XuezhaoSlash'):toInt() - 1] = 0
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    use.from:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and rinsanFuncModule.RIGHT(self, effect.from) and player:getMark('LuaXuezhao-Nogive') > 0 then
                return true
            end
        elseif event == sgs.CardAsked then
            if player:getMark('@LuaXuezhaoTarget') > 0 then
                room:provide(nil)
                room:setPlayerMark(player, '@LuaXuezhaoTarget', 0)
                return true
            end
        else
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('Slash') then
                player:setTag('XuezhaoSlash', sgs.QVariant(0))
            end
            for _, p in sgs.qlist(use.to) do
                room:setPlayerMark(p, '@LuaXuezhaoTarget', 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaXuezhaoTargetMod =
    sgs.CreateTargetModSkill {
    name = '#LuaXuezhao',
    frequency = sgs.Skill_Compulsory,
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:hasSkill('LuaXuezhao') then
            return player:getMark('LuaXuezhao-Slash')
        else
            return 0
        end
    end
}

SkillAnjiang:addSkill(LuaXuezhaoTargetMod)
ExTenYearDongcheng:addSkill(LuaXuezhao)

ExTenYearWanglang = sgs.General(extension, 'ExTenYearWanglang', 'wei', '3', true)

LuaGusheCard =
    sgs.CreateSkillCard {
    name = 'LuaGusheCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        return #selected < 3 and sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        local from_id = self:getSubcards():first()
        room:broadcastSkillInvoke('LuaGushe')
        -- 只有一个目标直接可以使用 pindian 方法
        if #targets == 1 then
            room:setPlayerFlag(source, 'LuaGusheSingleTarget')
            source:pindian(targets[1], 'LuaGushe', sgs.Sanguosha:getCard(from_id))
            return
        end
        local get_id = rinsanFuncModule.obtainIdFromAskForPindianCardEvent(room, source)
        if get_id ~= -1 then
            from_id = get_id
        end
        local from_card = sgs.Sanguosha:getCard(from_id)
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:addSubcard(from_card)
        local moves = sgs.CardsMoveList()
        local move =
            sgs.CardsMoveStruct(
            from_id,
            source,
            nil,
            sgs.Player_PlaceHand,
            sgs.Player_PlaceTable,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, source:objectName(), 'LuaGushe', '')
        )
        moves:append(move)
        for _, p in ipairs(targets) do
            -- 此处同理，响应天辩等
            local ask_id = rinsanFuncModule.obtainIdFromAskForPindianCardEvent(room, p)
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
            local _move =
                sgs.CardsMoveStruct(
                to_move,
                p,
                nil,
                sgs.Player_PlaceHand,
                sgs.Player_PlaceTable,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, p:objectName(), 'LuaGushe', '')
            )
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
            rinsanFuncModule.sendLogMessage(
                room,
                '$PindianResult',
                {['from'] = pindian.from, ['card_str'] = pindian.from_card:toString()}
            )
            rinsanFuncModule.sendLogMessage(
                room,
                '$PindianResult',
                {['from'] = pindian.to, ['card_str'] = pindian.to_card:toString()}
            )
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
        local move2 =
            sgs.CardsMoveStruct(
            subs,
            nil,
            nil,
            sgs.Player_PlaceTable,
            sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, 'LuaGushe', '')
        )
        room:moveCardsAtomic(move2, true)
    end
}

LuaGusheVS =
    sgs.CreateOneCardViewAsSkill {
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
    end
}

LuaGushe =
    sgs.CreateTriggerSkill {
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
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#PindianSuccess',
                        {['from'] = pindian.from, ['to'] = pindian.to}
                    )
                else
                    room:setPlayerFlag(pindian.from, '-LuaGusheSingleTarget')
                end
            else
                if not pindian.from:hasFlag('LuaGusheSingleTarget') then
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#PindianFailure',
                        {['from'] = pindian.from, ['to'] = pindian.to}
                    )
                else
                    room:setPlayerFlag(pindian.from, '-LuaGusheSingleTarget')
                end
                pindian.from:gainMark('@LuaGushe')
            end
            if
                not room:askForDiscard(
                    loser,
                    'LuaGushe',
                    1,
                    1,
                    true,
                    true,
                    '@LuaGusheDiscard:' .. pindian.from:objectName()
                )
             then
                pindian.from:drawCards(1, self:objectName())
            end
        end
    end
}

LuaJici =
    sgs.CreateTriggerSkill {
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
                    rinsanFuncModule.getBackPindianCardByJici(room, pindian, true)
                    obtained = true
                end
            end
            if pindian.to:hasSkill(self:objectName()) then
                if pindian.to_number <= pindian.to:getMark('@LuaGushe') then
                    room:sendCompulsoryTriggerLog(pindian.to, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    pindian.to_number = pindian.to_number + pindian.to:getMark('@LuaGushe')
                    if not obtained then
                        rinsanFuncModule.getBackPindianCardByJici(room, pindian, false)
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
                    room:doAnimate(
                        rinsanFuncModule.ANIMATE_INDICATE,
                        player:objectName(),
                        death.damage.from:objectName()
                    )
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
    can_trigger = function(self, target)
        return target
    end
}

ExTenYearWanglang:addSkill(LuaGushe)
ExTenYearWanglang:addSkill(LuaJici)

ExTenYearZhaoxiang = sgs.General(extension, 'ExTenYearZhaoxiang', 'shu', '4', false, true)

LuaFanghunVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaFanghun',
    response_or_use = true,
    view_filter = function(self, card)
        local usereason = sgs.Sanguosha:getCurrentCardUseReason()
        if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return card:isKindOf('Jink')
        elseif
            (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or
                (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
         then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == 'slash' then
                return card:isKindOf('Jink')
            else
                return card:isKindOf('Slash')
            end
        end
        return false
    end,
    view_as = function(self, card)
        if card:isKindOf('Slash') then
            local jink = sgs.Sanguosha:cloneCard('jink', card:getSuit(), card:getNumber())
            jink:addSubcard(card)
            jink:setSkillName(self:objectName())
            return jink
        elseif card:isKindOf('Jink') then
            local slash = sgs.Sanguosha:cloneCard('slash', card:getSuit(), card:getNumber())
            slash:addSubcard(card)
            slash:setSkillName(self:objectName())
            return slash
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaFanghun') > 0 and sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getMark('@LuaFanghun') > 0 and pattern == 'slash' or pattern == 'jink'
    end
}

LuaFanghun =
    sgs.CreateTriggerSkill {
    name = 'LuaFanghun',
    view_as_skill = LuaFanghunVS,
    events = {sgs.TargetConfirmed, sgs.TargetSpecified, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player)) then
            if use.card and use.card:isKindOf('Slash') then
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:gainMark('@LuaFanghun')
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:getSkillName() == self:objectName() then
                player:loseMark('@LuaFanghun')
                player:drawCards(1, self:objectName())
            end
        end
    end
}

LuaFuhan =
    sgs.CreateTriggerSkill {
    name = 'LuaFuhan',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaFuhan',
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local x = player:getMark('@LuaFanghun')
            if x > 0 then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:loseAllMarks('@LuaFanghun')
                    player:loseMark('@LuaFuhan')
                    player:drawCards(x, self:objectName())
                    local shu_generals =
                        rinsanFuncModule.getFuhanShuGenerals(room, math.max(4, room:alivePlayerCount()))
                    local index = 0
                    while index < 2 and #shu_generals > 0 and
                        room:askForChoice(player, self:objectName(), 'LuaFuhan+cancel') ~= 'cancel' do
                        index = index + 1
                        local generals = table.concat(shu_generals, '+')
                        local general = room:askForGeneral(player, generals)
                        local target = sgs.Sanguosha:getGeneral(general)
                        local skills = target:getVisibleSkillList()
                        local skillnames = {}
                        for _, skill in sgs.qlist(skills) do
                            if
                                not skill:inherits('SPConvertSkill') and not player:hasSkill(skill:objectName()) and
                                    not skill:isLordSkill() and
                                    skill:getFrequency() ~= sgs.Skill_Wake and
                                    skill:getFrequency() ~= sgs.Skill_Limited
                             then
                                table.insert(skillnames, skill:objectName())
                            end
                        end
                        local choices = table.concat(skillnames, '+')
                        local skill = room:askForChoice(player, self:objectName(), choices)
                        room:acquireSkill(player, skill, true)
                        skillnames = {}
                        for _, left_skill in sgs.qlist(skills) do
                            if
                                not left_skill:inherits('SPConvertSkill') and
                                    not player:hasSkill(left_skill:objectName()) and
                                    not left_skill:isLordSkill() and
                                    left_skill:getFrequency() ~= sgs.Skill_Wake and
                                    left_skill:getFrequency() ~= sgs.Skill_Limited
                             then
                                table.insert(skillnames, left_skill:objectName())
                            end
                        end
                        if #skillnames == 0 then
                            table.removeOne(shu_generals, general)
                        end
                    end
                    local hasMinHp = true
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getHp() < player:getHp() then
                            hasMinHp = false
                            break
                        end
                    end
                    if hasMinHp and player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(nil, nil, 1))
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, player)
        return rinsanFuncModule.RIGHT(self, player) and player:getMark('@LuaFuhan') > 0
    end
}

ExTenYearZhaoxiang:addSkill(LuaFanghun)
ExTenYearZhaoxiang:addSkill(LuaFuhan)

JieZhonghui = sgs.General(extension, 'JieZhonghui', 'wei', '4', true, true)

LuaQuanji =
    sgs.CreateTriggerSkill {
    name = 'LuaQuanji',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play then
                if player:getHp() < player:getHandcardNum() then
                    rinsanFuncModule.doQuanji(self, player, room)
                end
            end
        else
            local x = data:toDamage().damage
            local i = 0
            while i < x do
                i = i + 1
                rinsanFuncModule.doQuanji(self, player, room)
            end
        end
    end
}

LuaQuanjiKeep =
    sgs.CreateMaxCardsSkill {
    name = '#LuaQuanji-keep',
    extra_func = function(self, target)
        if target:hasSkill('LuaQuanji') then
            return target:getPile('power'):length()
        else
            return 0
        end
    end
}

LuaZili =
    sgs.CreateTriggerSkill {
    name = 'LuaZili',
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        rinsanFuncModule.sendLogMessage(
            room,
            '#LuaZili',
            {['from'] = player, ['arg'] = player:getPile('power'):length()}
        )
        if room:changeMaxHpForAwakenSkill(player) then
            room:broadcastSkillInvoke(self:objectName())
            if
                player:isWounded() and
                    room:askForChoice(player, self:objectName(), 'zilirecover+zilidraw') == 'zilirecover'
             then
                room:recover(player, sgs.RecoverStruct(player))
            else
                room:drawCards(player, 2, self:objectName())
            end
            room:addPlayerMark(player, self:objectName())
            room:acquireSkill(player, 'LuaPaiyi')
        end
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and target:getPhase() == sgs.Player_Start and
            target:getMark(self:objectName()) == 0 and
            target:getPile('power'):length() >= 3
    end
}

LuaPaiyiCard =
    sgs.CreateSkillCard {
    name = 'LuaPaiyiCard',
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:getMark('LuaPaiyiUsed') == 0
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        room:broadcastSkillInvoke('LuaPaiyi')
        room:drawCards(target, 2, 'LuaPaiyi')
        room:addPlayerMark(target, 'LuaPaiyiUsed')
        if target:getHandcardNum() > source:getHandcardNum() then
            rinsanFuncModule.doDamage(room, source, target, 1)
        end
    end
}

LuaPaiyiVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaPaiyi',
    filter_pattern = '.|.|.|power',
    expand_pile = 'power',
    view_as = function(self, card)
        local py = LuaPaiyiCard:clone()
        py:addSubcard(card)
        return py
    end,
    enabled_at_play = function(self, player)
        return not player:getPile('power'):isEmpty()
    end
}

LuaPaiyi =
    sgs.CreateTriggerSkill {
    name = 'LuaPaiyi',
    events = {sgs.EventPhaseEnd},
    view_as_skill = LuaPaiyiVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, 'LuaPaiyiUsed', 0)
            end
        end
    end
}

JieZhonghui:addSkill(LuaQuanji)
JieZhonghui:addSkill(LuaZili)
JieZhonghui:addRelateSkill('LuaPaiyi')
SkillAnjiang:addSkill(LuaQuanjiKeep)
SkillAnjiang:addSkill(LuaPaiyi)

ExStarXuhuang = sgs.General(extension, 'ExStarXuhuang', 'qun', '4', true, true)

LuaZhiyanDrawCard =
    sgs.CreateSkillCard {
    name = 'LuaZhiyanDrawCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return false
    end,
    feasible = function(self, targets)
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaZhiyan')
        local x = source:getMaxHp() - source:getHandcardNum()
        source:drawCards(x, 'LuaZhiyan')
    end
}

LuaZhiyanGiveCard =
    sgs.CreateSkillCard {
    name = 'LuaZhiyanGiveCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cd)
        end
        local target = targets[1]
        local reason =
            sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_GIVE,
            source:objectName(),
            target:objectName(),
            'LuaZhiyan',
            nil
        )
        room:broadcastSkillInvoke('LuaZhiyan')
        room:moveCardTo(to_goback, source, target, sgs.Player_PlaceHand, reason, true)
    end
}

LuaZhiyan =
    sgs.CreateViewAsSkill {
    name = 'LuaZhiyan',
    n = 999,
    view_filter = function(self, selected, to_select)
        local y = sgs.Self:getHandcardNum() - sgs.Self:getHp()
        return y > 0 and #selected < y
    end,
    view_as = function(self, cards)
        local x = sgs.Self:getMaxHp() - sgs.Self:getHandcardNum()
        local LuaZhiyanDrawAvailable = x > 0 and not sgs.Self:hasUsed('#LuaZhiyanDrawCard') and #cards == 0
        if LuaZhiyanDrawAvailable then
            return LuaZhiyanDrawCard:clone()
        end
        local y = sgs.Self:getHandcardNum() - sgs.Self:getHp()
        local LuaZhiyanGiveAvailable = y > 0 and not sgs.Self:hasUsed('#LuaZhiyanGiveCard') and #cards == y
        if LuaZhiyanGiveAvailable then
            local luaZhiyanGiveCard = LuaZhiyanGiveCard:clone()
            for _, cd in ipairs(cards) do
                luaZhiyanGiveCard:addSubcard(cd)
            end
            return luaZhiyanGiveCard
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        local LuaZhiyanDrawAvailable =
            not player:hasUsed('#LuaZhiyanDrawCard') and player:getMaxHp() > player:getHandcardNum()
        local LuaZhiyanGiveAvailable =
            not player:hasUsed('#LuaZhiyanGiveCard') and player:getHandcardNum() > player:getHp()
        return LuaZhiyanDrawAvailable or LuaZhiyanGiveAvailable
    end
}

LuaZhiyanMod =
    sgs.CreateProhibitSkill {
    name = '#LuaZhiyanMod',
    is_prohibited = function(self, from, to, card)
        return from:hasSkill('LuaZhiyan') and not card:isKindOf('SkillCard') and from:objectName() ~= to:objectName() and
            from:hasUsed('#LuaZhiyanDrawCard')
    end
}

ExStarXuhuang:addSkill(LuaZhiyan)
SkillAnjiang:addSkill(LuaZhiyanMod)

ExTenYearGuansuo = sgs.General(extension, 'ExTenYearGuansuo', 'shu', '4', true)

LuaZhengnan =
    sgs.CreateTriggerSkill {
    name = 'LuaZhengnan',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:getMark(self:objectName() .. player:objectName()) == 0 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(dying.who, self:objectName() .. player:objectName())
                if player:isWounded() then
                    room:recover(player, sgs.RecoverStruct())
                end
                player:drawCards(1, self:objectName())
                local gainableSkills =
                    rinsanFuncModule.getGainableSkillTable(player, {'LuaDangxian', 'wusheng', 'LuaZhiman'})
                -- gainnableSkills 代表可以获得的剩余技能，若为0，则代表已经获取了三个技能，走摸牌流程
                if #gainableSkills == 0 then
                    player:drawCards(3, self:objectName())
                else
                    local choice = room:askForChoice(player, self:objectName(), table.concat(gainableSkills, '+'))
                    room:acquireSkill(player, choice)
                end
            end
        end
    end
}

LuaZhiman =
    sgs.CreateTriggerSkill {
    name = 'LuaZhiman',
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:objectName() == player:objectName() then
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
            if not damage.to:isAllNude() then
                local id = room:askForCardChosen(player, damage.to, 'hej', self:objectName())
                player:obtainCard(sgs.Sanguosha:getCard(id), false)
            end
            return true
        end
        return false
    end
}

ExTenYearGuansuo:addSkill(LuaZhengnan)
ExTenYearGuansuo:addSkill('xiefang')
ExTenYearGuansuo:addRelateSkill('LuaDangxian')
ExTenYearGuansuo:addRelateSkill('wusheng')
ExTenYearGuansuo:addRelateSkill('LuaZhiman')
SkillAnjiang:addSkill(LuaZhiman)

ExStarGanning = sgs.General(extension, 'ExStarGanning', 'qun', '4', true, true)

LuaJinfanCard =
    sgs.CreateSkillCard {
    name = 'LuaJinfanCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local to_pile = sgs.IntList()
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_pile:append(cd)
        end
        room:broadcastSkillInvoke('LuaJinfan')
        source:addToPile('&luajinfanpile', to_pile, false)
    end
}

LuaJinfanVS =
    sgs.CreateViewAsSkill {
    name = 'LuaJinfan',
    n = 4,
    view_filter = function(self, selected, to_select)
        if to_select:isEquipped() then
            return false
        end
        local suits = {}
        for _, cd in sgs.qlist(sgs.Self:getPile('&luajinfanpile')) do
            if not table.contains(suits, sgs.Sanguosha:getCard(cd):getSuit()) then
                table.insert(suits, sgs.Sanguosha:getCard(cd):getSuit())
            end
        end
        for _, cd in ipairs(selected) do
            if not table.contains(suits, cd:getSuit()) then
                table.insert(suits, cd:getSuit())
            end
        end
        return not table.contains(suits, to_select:getSuit())
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local vs_card = LuaJinfanCard:clone()
        for _, cd in ipairs(cards) do
            vs_card:addSubcard(cd)
        end
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaJinfan'
    end
}

LuaJinfan =
    sgs.CreateTriggerSkill {
    name = 'LuaJinfan',
    view_as_skill = LuaJinfanVS,
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Discard then
            local canInvoke
            local suits = {}
            for _, cd in sgs.qlist(player:getPile('&luajinfanpile')) do
                if not table.contains(suits, sgs.Sanguosha:getCard(cd):getSuit()) then
                    table.insert(suits, sgs.Sanguosha:getCard(cd):getSuit())
                end
            end
            for _, cd in sgs.qlist(player:getHandcards()) do
                if not table.contains(suits, cd:getSuit()) then
                    canInvoke = true
                    break
                end
            end
            if canInvoke then
                room:askForUseCard(player, '@@LuaJinfan', '@LuaJinfan')
            end
        else
            local move = data:toMoveOneTime()
            if
                move.from and move.from:objectName() == player:objectName() and
                    move.from_places:contains(sgs.Player_PlaceSpecial)
             then
                for index, card_id in sgs.qlist(move.card_ids) do
                    -- from_pile_names 为 Table，故 index 需要加一
                    if move.from_pile_names[index + 1] == '&luajinfanpile' then
                        local curr_card = sgs.Sanguosha:getCard(card_id)
                        local togain =
                            rinsanFuncModule.obtainSpecifiedCard(
                            room,
                            function(check)
                                return check:getSuit() == curr_card:getSuit()
                            end
                        )
                        if togain then
                            room:broadcastSkillInvoke(self:objectName())
                            player:obtainCard(togain, false)
                        end
                    end
                end
            end
        end
    end
}

LuaSheque =
    sgs.CreateTriggerSkill {
    name = 'LuaSheque',
    events = {sgs.EventPhaseStart, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:hasEquip() then
                    for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if sp:objectName() ~= player:objectName() then
                            room:setPlayerFlag(sp, 'LuaSheque')
                            room:askForUseSlashTo(sp, player, '@LuaSheque:' .. player:objectName(), false)
                            room:setPlayerFlag(sp, '-LuaSheque')
                        end
                    end
                end
            end
        else
            local use = data:toCardUse()
            if use.from and use.from:hasFlag(self:objectName()) and use.card:isKindOf('Slash') then
                room:broadcastSkillInvoke(self:objectName())
                for _, p in sgs.qlist(use.to) do
                    p:addQinggangTag(use.card)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExStarGanning:addSkill(LuaJinfan)
ExStarGanning:addSkill(LuaSheque)

JieCaozhi = sgs.General(extension, 'JieCaozhi', 'wei', '3', true)

LuaLuoying =
    sgs.CreateTriggerSkill {
    name = 'LuaLuoying',
    frequency = sgs.Skill_Frequent,
    events = {sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from == nil or move.from:objectName() == player:objectName() then
            return false
        end
        if
            (move.to_place == sgs.Player_DiscardPile) and
                rinsanFuncModule.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) or
                (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)
         then
            local card_ids = sgs.IntList()
            for index, card_id in sgs.qlist(move.card_ids) do
                if
                    (sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club) and
                        (((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE) and
                            (move.from_places:at(index) == sgs.Player_PlaceJudge) and
                            (move.to_place == sgs.Player_DiscardPile)) or
                            ((move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE) and
                                (room:getCardOwner(card_id):objectName() == move.from:objectName()) and
                                ((move.from_places:at(index) == sgs.Player_PlaceHand) or
                                    (move.from_places:at(index) == sgs.Player_PlaceEquip))))
                 then
                    card_ids:append(card_id)
                end
            end
            if card_ids:isEmpty() then
                return false
            elseif player:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                while not card_ids:isEmpty() do
                    room:fillAG(card_ids, player)
                    local id = room:askForAG(player, card_ids, true, self:objectName())
                    if id == -1 then
                        room:clearAG(player)
                        break
                    end
                    card_ids:removeOne(id)
                    room:clearAG(player)
                end
                if not card_ids:isEmpty() then
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    for _, id in sgs.qlist(card_ids) do
                        if move.card_ids:contains(id) then
                            move.from_places:removeAt(listIndexOf(move.card_ids, id))
                            move.card_ids:removeOne(id)
                            dummy:addSubcard(id)
                            data:setValue(move)
                        end
                        if not player:isAlive() then
                            return false
                        end
                    end
                    if player:isAlive() then
                        room:moveCardTo(dummy, player, sgs.Player_PlaceHand, move.reason, true)
                    end
                end
            end
        end
    end
}

LuaJiushiVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaJiushi',
    view_as = function(self)
        local analeptic = sgs.Sanguosha:cloneCard('analeptic', sgs.Card_NoSuit, 0)
        analeptic:setSkillName(self:objectName())
        return analeptic
    end,
    enabled_at_play = function(self, player)
        return sgs.Analeptic_IsAvailable(player) and player:faceUp()
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, 'analeptic') and player:faceUp()
    end
}

LuaJiushi =
    sgs.CreateTriggerSkill {
    name = 'LuaJiushi',
    events = {sgs.PreCardUsed, sgs.PreDamageDone, sgs.DamageComplete, sgs.MarkChanged, sgs.TurnedOver},
    view_as_skill = LuaJiushiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            local card = use.card
            if card:getSkillName() == self:objectName() then
                player:turnOver()
            end
        elseif event == sgs.PreDamageDone then
            room:setTag('PredamagedFace', sgs.QVariant(player:faceUp()))
        elseif event == sgs.DamageComplete then
            local faceup = room:getTag('PredamagedFace'):toBool()
            room:removeTag('PredamagedFace')
            if not (faceup or player:faceUp()) then
                if player:askForSkillInvoke(self:objectName(), data) then
                    room:setPlayerFlag(player, 'LuaJiushiTurnOver')
                    player:turnOver()
                    room:setPlayerFlag(player, '-LuaJiushiTurnOver')
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
        elseif event == sgs.TurnedOver then
            if player:getMark('LuaChengzhang') > 0 or player:hasFlag('LuaJiushiTurnOver') then
                local togain =
                    rinsanFuncModule.obtainTargetedTypeCard(room, {['type'] = 'TrickCard', ['findDiscardPile'] = true})
                if togain then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    player:obtainCard(togain, false)
                end
            end
        else
            local mark = data:toMark()
            if mark.name == 'LuaChengzhang' and mark.who:hasSkill(self:objectName()) then
                ChangeSkill(self, room, player)
                -- ChangeSkill 会加上一个显示标记②，在这里删掉
                room:setPlayerMark(player, '@ChangeSkill2', 0)
            end
        end
        return false
    end
}

LuaChengzhang =
    sgs.CreateTriggerSkill {
    name = 'LuaChengzhang',
    frequency = sgs.Skill_Wake,
    events = {sgs.Damaged, sgs.Damage, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged or event == sgs.Damage then
            room:addPlayerMark(player, '@' .. self:objectName() .. 'damage', data:toDamage().damage)
        else
            if player:getPhase() == sgs.Player_Start and player:getMark('@' .. self:objectName() .. 'damage') >= 7 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                if room:changeMaxHpForAwakenSkill(player, 0) then
                    room:recover(player, sgs.RecoverStruct())
                    room:setPlayerMark(player, '@' .. self:objectName() .. 'damage', 0)
                    player:drawCards(1, self:objectName())
                    room:addPlayerMark(player, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and target:getMark(self:objectName()) == 0
    end
}

JieCaozhi:addSkill(LuaLuoying)
JieCaozhi:addSkill(LuaJiushi)
JieCaozhi:addSkill(LuaChengzhang)

JieChenqun = sgs.General(extension, 'JieChenqun', 'wei', '3', true, true)

LuaDingpinCard =
    sgs.CreateSkillCard {
    name = 'LuaDingpinCard',
    filter = function(self, selected, to_select)
        return #selected == 0 and not to_select:hasFlag('LuaDingpinSucceed')
    end,
    on_use = function(self, room, source, targets)
        local subcard = sgs.Sanguosha:getCard(self:getSubcards():first())
        local target = targets[1]
        room:broadcastSkillInvoke('LuaDingpin')
        local judge =
            rinsanFuncModule.createJudgeStruct(
            {
                ['play_animation'] = true,
                ['reason'] = 'LuaDingpin',
                ['who'] = target
            }
        )
        room:judge(judge)
        if judge.card:isBlack() then
            target:drawCards(math.min(3, target:getHp()), 'LuaDingpin')
            room:setPlayerFlag(target, 'LuaDingpinSucceed')
        elseif judge.card:getSuit() == sgs.Card_Diamond then
            source:turnOver()
        end
        if judge.card:getSuit() ~= sgs.Card_Heart then
            room:setPlayerFlag(source, 'LuaDingpinCard' .. subcard:getType())
        end
    end
}

LuaDingpin =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaDingpin',
    view_filter = function(self, to_select)
        return not sgs.Self:hasFlag('LuaDingpinCard' .. to_select:getType())
    end,
    view_as = function(self, card)
        local vs_card = LuaDingpinCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        -- 判断有无可发动定品的目标
        local targetAvailable = player:hasFlag('LuaDingpinSucceed')
        for _, sib in sgs.qlist(player:getSiblings()) do
            if targetAvailable then
                break
            end
            if not sib:hasFlag('LuaDingpinSucceed') then
                targetAvailable = true
            end
        end
        -- 判断有无可定品的卡牌
        for _, cd in sgs.qlist(player:getHandcards()) do
            if not player:hasFlag('LuaDingpinCard' .. cd:getType()) then
                return true
            end
        end
        for _, cd in sgs.qlist(player:getEquips()) do
            if not player:hasFlag('LuaDingpinCard' .. cd:getType()) then
                return true
            end
        end
        return false
    end
}

LuaFaen =
    sgs.CreateTriggerSkill {
    name = 'LuaFaen',
    events = {sgs.TurnedOver, sgs.ChainStateChanged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.ChainStateChanged and not player:isChained() then
            return false
        end
        local data2 = sgs.QVariant()
        data2:setValue(player)
        for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(sp, self:objectName(), data2) then
                room:broadcastSkillInvoke(self:objectName())
                room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), sp:objectName())
                player:drawCards(1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

JieChenqun:addSkill(LuaDingpin)
JieChenqun:addSkill(LuaFaen)

JieXunyu = sgs.General(extension, 'JieXunyu', 'wei', '3', true, true)

LuaQuhuCard =
    sgs.CreateSkillCard {
    name = 'LuaQuhuCard',
    filter = function(self, selected, to_select)
        -- 使用 canPindian 进行判断
        return #selected == 0 and to_select:getHp() > sgs.Self:getHp() and sgs.Self:canPindian(to_select, 'LuaQuhu')
    end,
    on_use = function(self, room, source, targets)
        -- 驱虎吞狼，被驱的自然是 tiger
        local tiger = targets[1]
        room:broadcastSkillInvoke('LuaQuhu')
        if source:pindian(tiger, 'LuaQuhu') then
            -- 要被吞的狼
            local wolves = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(tiger)) do
                if tiger:inMyAttackRange(p) then
                    wolves:append(p)
                end
            end
            -- 如果没有被吞的狼，结束结算
            if wolves:isEmpty() then
                return
            end
            local wolf = room:askForPlayerChosen(source, wolves, 'LuaQuhu', '@quhu-damage:' .. tiger:objectName())
            rinsanFuncModule.doDamage(room, tiger, wolf, 1)
        else
            rinsanFuncModule.doDamage(room, tiger, source, 1)
        end
    end
}

LuaQuhu =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaQuhu',
    view_as = function(self)
        return LuaQuhuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaQuhuCard') and not player:isKongcheng()
    end
}

LuaJieming =
    sgs.CreateTriggerSkill {
    name = 'LuaJieming',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local i = 0
        while i < damage.damage do
            i = i + 1
            local target =
                room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 'jieming-invoke', true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                target:drawCards(2, self:objectName())
                if target:getHandcardNum() < target:getMaxHp() then
                    player:drawCards(1, self:objectName())
                end
            else
                break
            end
        end
    end
}

JieXunyu:addSkill(LuaQuhu)
JieXunyu:addSkill(LuaJieming)

ExSufei = sgs.General(extension, 'ExSufei', 'qun', '4', true, true)

LuaZhengjian =
    sgs.CreateTriggerSkill {
    name = 'LuaZhengjian',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(self:objectName() .. player:objectName()) > 0 then
                        local x = p:getMark('LuaZhengjianCard' .. player:objectName())
                        if x > 0 then
                            room:sendCompulsoryTriggerLog(player, self:objectName())
                            room:broadcastSkillInvoke(self:objectName())
                            room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), p:objectName())
                            p:drawCards(x, self:objectName())
                        end
                        room:setPlayerMark(p, 'LuaZhengjianCard' .. player:objectName(), 0)
                        room:setPlayerMark(p, self:objectName() .. player:objectName(), 0)
                    end
                end
            elseif player:getPhase() == sgs.Player_Finish then
                if player:hasSkill(self:objectName()) then
                    local target =
                        room:askForPlayerChosen(
                        player,
                        room:getAlivePlayers(),
                        self:objectName(),
                        '@LuaZhengjian-choose',
                        false,
                        true
                    )
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(target, self:objectName() .. player:objectName())
                end
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf('SkillCard') then
                return false
            end
            local x = math.min(player:getMaxHp(), 5)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:getMark(self:objectName() .. p:objectName()) > 0 then
                    if player:getMark('LuaZhengjianCard' .. p:objectName()) < x then
                        room:sendCompulsoryTriggerLog(p, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(player, 'LuaZhengjianCard' .. p:objectName())
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaGaoyuan =
    sgs.CreateTriggerSkill {
    name = 'LuaGaoyuan',
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and use.to:contains(player) and player:canDiscard(player, 'he') then
            if
                use.from:getMark('LuaZhengjian' .. player:objectName()) == 0 and
                    player:getMark('LuaZhengjian' .. player:objectName()) == 0
             then
                local target
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark('LuaZhengjian' .. player:objectName()) > 0 then
                        target = p
                        break
                    end
                end
                if
                    target and not use.to:contains(target) and
                        room:askForCard(
                            player,
                            '.|.|.|.',
                            '@LuaGaoyuan:' .. target:objectName(),
                            data,
                            sgs.Card_MethodDiscard,
                            target,
                            false,
                            self:objectName()
                        )
                 then
                    room:doAnimate(rinsanFuncModule.ANIMATE_INDICATE, player:objectName(), target:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    use.to:removeOne(player)
                    use.to:append(target)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                    -- 需要让 target 触发一次该时机，以触发享乐等技能
                    room:getThread():trigger(sgs.TargetConfirming, room, target, data)
                end
            end
        end
        return false
    end
}

ExSufei:addSkill(LuaZhengjian)
ExSufei:addSkill(LuaGaoyuan)

ExShenZhaoyun = sgs.General(extension, 'ExShenZhaoyun', 'god', '2', true, true)

LuaJuejing =
    sgs.CreateTriggerSkill {
    name = 'LuaJuejing',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Dying, sgs.QuitDying, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Discard then
                room:sendCompulsoryTriggerLog(player, self:objectName())
            end
        else
            if data:toDying().who:objectName() == player:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(1, self:objectName())
            end
        end
    end
}

LuaJuejingMaxCards =
    sgs.CreateMaxCardsSkill {
    name = '#LuaJuejing',
    extra_func = function(self, target)
        if target:hasSkill('LuaJuejing') then
            return 2
        else
            return 0
        end
    end
}

LuaLonghunVS =
    sgs.CreateViewAsSkill {
    name = 'LuaLonghun',
    response_or_use = true,
    n = 2,
    view_filter = function(self, selected, card)
        if #selected >= 2 or card:hasFlag('using') then
            return false
        end
        if #selected >= 1 then
            local suit = selected[1]:getSuit()
            return card:getSuit() == suit
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if sgs.Self:isWounded() and card:getSuit() == sgs.Card_Heart then
                return true
            elseif card:getSuit() == sgs.Card_Diamond then
                local slash = sgs.Sanguosha:cloneCard('fire_slash', sgs.Card_SuitToBeDecided, -1)
                slash:addSubcard(card:getEffectiveId())
                slash:deleteLater()
                return slash:isAvailable(sgs.Self)
            else
                return false
            end
        elseif
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == 'jink' then
                return card:getSuit() == sgs.Card_Club
            elseif pattern == 'nullification' then
                return card:getSuit() == sgs.Card_Spade
            elseif string.find(pattern, 'peach') then
                return card:getSuit() == sgs.Card_Heart
            elseif pattern == 'slash' then
                return card:getSuit() == sgs.Card_Diamond
            end
            return false
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards < 1 then
            return nil
        end
        local card = cards[1]
        local new_card = nil
        if card:getSuit() == sgs.Card_Spade then
            new_card = sgs.Sanguosha:cloneCard('nullification', sgs.Card_SuitToBeDecided, 0)
        elseif card:getSuit() == sgs.Card_Heart then
            new_card = sgs.Sanguosha:cloneCard('peach', sgs.Card_SuitToBeDecided, 0)
        elseif card:getSuit() == sgs.Card_Club then
            new_card = sgs.Sanguosha:cloneCard('jink', sgs.Card_SuitToBeDecided, 0)
        elseif card:getSuit() == sgs.Card_Diamond then
            new_card = sgs.Sanguosha:cloneCard('fire_slash', sgs.Card_SuitToBeDecided, 0)
        end
        if new_card then
            new_card:setSkillName(self:objectName())
            for _, c in ipairs(cards) do
                new_card:addSubcard(c)
            end
        end
        return new_card
    end,
    enabled_at_play = function(self, player)
        return player:isWounded() or sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == 'slash' or pattern == 'jink' or
            (string.find(pattern, 'peach') and player:getMark('Global_PreventPeach') == 0) or
            pattern == 'nullification'
    end,
    enabled_at_nullification = function(self, player)
        for _, cd in sgs.qlist(player:getCards('he')) do
            if cd:getSuit() == sgs.Card_Spade then
                return true
            end
        end
        return false
    end
}

LuaLonghun =
    sgs.CreateTriggerSkill {
    name = 'LuaLonghun',
    view_as_skill = LuaLonghunVS,
    events = {sgs.DamageCaused, sgs.PreHpRecover, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() and damage.card:subcardsLength() > 1 then
                local msg = sgs.LogMessage()
                room:sendLog(msg)
                rinsanFuncModule.sendLogMessage(
                    room,
                    '#LuaLonghunAddDamage',
                    {['from'] = player, ['arg'] = damage.damage, ['arg2'] = damage.damage + 1}
                )
                room:notifySkillInvoked(damage.from, self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.PreHpRecover then
            local rec = data:toRecover()
            if rec.card and rec.card:getSkillName() == self:objectName() and rec.card:subcardsLength() > 1 then
                rec.recover = rec.recover + 1
                room:sendCompulsoryTriggerLog(rec.who, self:objectName())
                data:setValue(rec)
            end
        else
            local use = data:toCardUse()
            if
                use.card and use.card:isBlack() and use.card:getSkillName() == self:objectName() and
                    use.card:subcardsLength() > 1
             then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                if player:canDiscard(room:getCurrent(), 'he') then
                    room:throwCard(
                        room:askForCardChosen(
                            player,
                            room:getCurrent(),
                            'he',
                            self:objectName(),
                            false,
                            sgs.Card_MethodDiscard
                        ),
                        room:getCurrent(),
                        player
                    )
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

ExShenZhaoyun:addSkill(LuaJuejing)
ExShenZhaoyun:addSkill(LuaLonghun)
SkillAnjiang:addSkill(LuaJuejingMaxCards)

ExZhuling = sgs.General(extension, 'ExZhuling', 'wei', '4', true, true)

LuaZhanyiCard =
    sgs.CreateSkillCard {
    name = 'LuaZhanyiCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        -- 首先失去一点体力
        room:loseHp(source)
        room:setPlayerFlag(source, 'LuaZhanyiUsed')
        room:broadcastSkillInvoke('LuaZhanyi')

        -- 根据不同牌型，用不同 flag 标识
        if card:isKindOf('BasicCard') then
            room:setPlayerFlag(source, 'LuaZhanyiBasicCard')
            room:setPlayerFlag(source, 'LuaZhanyiFirstBasicCard')
            -- 解禁蛊惑框内容
            room:setPlayerProperty(source, 'allowed_guhuo_dialog_buttons', sgs.QVariant(''))
        elseif card:isKindOf('TrickCard') then
            source:drawCards(3, 'LuaZhanyi')
            room:setPlayerFlag(source, 'LuaZhanyiTrickCard')
        elseif card:isKindOf('EquipCard') then
            room:setPlayerFlag(source, 'LuaZhanyiEquipCard')
        end
    end
}

LuaZhanyiBasicCard =
    sgs.CreateSkillCard {
    name = 'LuaZhanyiBasicCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card
            if self:getUserString() and self:getUserString() ~= '' then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
                return card and card:targetFilter(players, to_select, sgs.Self) and
                    not sgs.Self:isProhibited(to_select, card, players)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local _card = sgs.Self:getTag('LuaZhanyi'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:deleteLater()
        return card and card:targetFilter(players, to_select, sgs.Self) and
            not sgs.Self:isProhibited(to_select, card, players)
    end,
    feasible = function(self, targets)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card
            if self:getUserString() and self:getUserString() ~= '' then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
                return card and card:targetsFeasible(players, sgs.Self)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local _card = sgs.Self:getTag('LuaZhanyi'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:deleteLater()
        return card and card:targetsFeasible(players, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local to_use = self:getUserString()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        if
            to_use == 'slash' and
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'zhanyi_slash', table.concat(use_list, '+'))
            source:setTag('ZhanyiSlash', sgs.QVariant(to_use))
        end
        local user_str = to_use
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        if use_card == nil then
            use_card = sgs.Sanguosha:cloneCard('slash', card:getSuit(), card:getNumber())
        end
        use_card:setSkillName('LuaZhanyi')
        use_card:addSubcards(self:getSubcards())
        use_card:deleteLater()
        local tos = card_use.to
        for _, to in sgs.qlist(tos) do
            local skill = room:isProhibited(source, to, use_card)
            if skill then
                card_use.to:removeOne(to)
            end
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local to_use
        if self:getUserString() == 'peach+analeptic' then
            local use_list = {}
            table.insert(use_list, 'peach')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'analeptic')
            end
            to_use = room:askForChoice(source, 'zhanyi_saveself', table.concat(use_list, '+'))
            source:setTag('ZhanyiSaveSelf', sgs.QVariant(to_use))
        elseif self:getUserString() == 'slash' then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'zhanyi_slash', table.concat(use_list, '+'))
            source:setTag('ZhanyiSlash', sgs.QVariant(to_use))
        else
            to_use = self:getUserString()
        end
        local user_str
        if to_use == 'slash' then
            user_str = 'slash'
        elseif to_use == 'normal_slash' then
            user_str = 'slash'
        else
            user_str = to_use
        end
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        use_card:setSkillName('LuaZhanyi')
        use_card:addSubcards(self:getSubcards())
        use_card:deleteLater()
        return use_card
    end
}

LuaZhanyiVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaZhanyi',
    response_or_use = false,
    view_filter = function(self, to_select)
        -- 如果没有发动过“战意”，那么啥牌都行，如果发动过且弃置的是基本牌，只能基本牌
        return not sgs.Self:hasFlag('LuaZhanyiUsed') or
            (sgs.Self:hasFlag('LuaZhanyiBasicCard') and to_select:isKindOf('BasicCard'))
    end,
    enabled_at_response = function(self, player, pattern)
        if not player:hasFlag('LuaZhanyiBasicCard') then
            return false
        end
        if string.startsWith(pattern, '.') or string.startsWith(pattern, '@') then
            return false
        end
        if pattern == 'peach' and player:getMark('Global_PreventPeach') > 0 then
            return false
        end
        if pattern == 'nullification' then
            return false
        end
        if string.find(pattern, '[%u%d]') then
            return false
        end -- 这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
        return true
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag('LuaZhanyiUsed') or
            (player:hasFlag('LuaZhanyiBasicCard') and
                (player:isWounded() or sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player)))
    end,
    enabled_at_nullification = function(self, player)
        return false
    end,
    view_as = function(self, orginalCard)
        if not sgs.Self:hasFlag('LuaZhanyiUsed') then
            local vs_card = LuaZhanyiCard:clone()
            vs_card:addSubcard(orginalCard)
            return vs_card
        end
        if sgs.Self:hasFlag('LuaZhanyiBasicCard') then
            if
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
                    sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
             then
                local card = LuaZhanyiBasicCard:clone()
                card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
                card:addSubcard(orginalCard)
                return card
            end
            local c = sgs.Self:getTag('LuaZhanyi'):toCard()
            if c then
                local card = LuaZhanyiBasicCard:clone()
                card:setUserString(c:objectName())
                card:addSubcard(orginalCard)
                return card
            else
                return nil
            end
        end
    end
}

LuaZhanyi =
    sgs.CreateTriggerSkill {
    name = 'LuaZhanyi',
    events = {sgs.TurnStart, sgs.CardEffected, sgs.CardUsed, sgs.DamageCaused, sgs.PreHpRecover, sgs.ChoiceMade},
    view_as_skill = LuaZhanyiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart and player:hasSkill(self:objectName()) then
            -- 蛊惑框导致选择技能时会弹框，影响体验，在这里先把基本牌排除掉
            -- 令蛊惑框内容仅允许【决斗】可选，但指定为基本牌类型，故初次使用时不会弹框
            -- 在基本牌使用后解除弹框限制即可
            room:setPlayerProperty(player, 'allowed_guhuo_dialog_buttons', sgs.QVariant('duel'))
        elseif event == sgs.CardEffected then
            local effect = data:toCardEffect()
            local source = effect.from
            local card = effect.card
            -- 因持续效果，故在此判断 Flag
            if source:hasFlag('LuaZhanyiTrickCard') then
                if card:isNDTrick() then
                    room:sendCompulsoryTriggerLog(source, self:objectName())
                    local trick = card:toTrick()
                    trick:setCancelable(false)
                    effect.card = trick
                    data:setValue(effect)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            local card = use.card
            if card:isKindOf('Slash') and use.from:hasFlag('LuaZhanyiEquipCard') then
                room:sendCompulsoryTriggerLog(use.from, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                for _, p in sgs.qlist(use.to) do
                    room:askForDiscard(p, self:objectName(), 2, 2, false, true)
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            -- 如果有对应 flag 且造成伤害为基本牌，则加伤害
            if damage.from and damage.from:hasFlag('LuaZhanyiFirstBasicCard') then
                if damage.card and damage.card:isKindOf('BasicCard') then
                    room:sendCompulsoryTriggerLog(damage.from, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                    room:setPlayerFlag(damage.from, '-LuaZhanyiFirstBasicCard')
                end
            end
        elseif event == sgs.PreHpRecover then
            local rec = data:toRecover()
            -- 如果有对应 flag 且回复牌为基本牌，则加回复量
            if rec.who and rec.who:hasFlag('LuaZhanyiFirstBasicCard') then
                if rec.card and rec.card:isKindOf('BasicCard') then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(rec.who, self:objectName())
                    rec.recover = rec.recover + 1
                    data:setValue(rec)
                    room:setPlayerFlag(rec.who, '-LuaZhanyiFirstBasicCard')
                end
            end
        elseif event == sgs.ChoiceMade then
            local dataStr = data:toString():split(':')
            if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~= self:objectName() then
                return false
            end
            if #dataStr[3]:split('+') == 0 then
                return false
            end
            local source
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag('LuaZhanyiEquipCard') then
                    source = p
                    break
                end
            end
            -- dataStr[3] 的结构是：$id+id+id+...，因此需要去掉第一个$
            local card_ids = string.sub(dataStr[3], 2):split('+')
            local cards = sgs.IntList()
            for _, id in ipairs(card_ids) do
                cards:append(tonumber(id))
            end
            if source and not cards:isEmpty() then
                room:fillAG(cards, source)
                -- false 代表不能拒绝拿牌（根据技能描述）
                local id = room:askForAG(source, cards, false, self:objectName())
                if id ~= -1 then
                    room:obtainCard(source, id)
                end
                room:clearAG(source)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end
}

LuaZhanyi:setGuhuoDialog('l')

ExZhuling:addSkill(LuaZhanyi)
