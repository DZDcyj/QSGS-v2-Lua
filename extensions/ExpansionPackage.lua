-- 扩展武将包
-- Created by DZDcyj at 2021/8/15
module('extensions.ExpansionPackage', package.seeall)
extension = sgs.Package('ExpansionPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

LuaFakeMove = sgs.CreateTriggerSkill {
    name = 'LuaFakeMove',
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
    priority = 10,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if room:getTag('LuaFakeMove'):toBool() then
            return true
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

table.insert(hiddenSkills, LuaFakeMove)

ExWangyuanji = sgs.General(extension, 'ExWangyuanji', 'wei', '3', false)

LuaQianchong = sgs.CreateTriggerSkill {
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
                    rinsan.sendLogMessage(room, '#LuaQianchongChoice', {
                        ['from'] = player,
                        ['arg'] = choice,
                    })
                    if choice == 'BasicCard' then
                        room:setPlayerMark(player, 'LuaQianchongCard', 1)
                    elseif choice == 'TrickCard' then
                        room:setPlayerMark(player, 'LuaQianchongCard', 2)
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) or
                (move.from and move.from:objectName() == player:objectName()) and
                move.from_places:contains(sgs.Player_PlaceEquip)) then
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
    end,
}

LuaQianchongBasicCardTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaQianchongBasicCardTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'BasicCard',
    residue_func = function(self, player)
        if player:getMark('LuaQianchongCard') == 1 then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:getMark('LuaQianchongCard') == 1 then
            return 1000
        else
            return 0
        end
    end,
}

LuaQianchongTrickCardTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaQianchongTrickCardTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'TrickCard',
    residue_func = function(self, player)
        if player:getMark('LuaQianchongCard') == 2 then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:getMark('LuaQianchongCard') == 2 then
            return 1000
        else
            return 0
        end
    end,
}

LuaQianchongClear = sgs.CreateTriggerSkill {
    name = 'LuaQianchongClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, 'LuaQianchongCard', 0)
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaWeimu = sgs.CreateProhibitSkill {
    name = 'LuaWeimu',
    is_prohibited = function(self, from, to, card)
        return to:hasSkill(self:objectName()) and card:isKindOf('TrickCard') and card:isBlack()
    end,
}

LuaMingzhe = sgs.CreateTriggerSkill {
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
                if rinsan.moveBasicReasonCompare(reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) then
                    local card
                    local i = 0
                    for _, id in sgs.qlist(move.card_ids) do
                        card = sgs.Sanguosha:getCard(id)
                        if room:getCardOwner(id):objectName() == player:objectName() and card:isRed() and
                            move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) ==
                            sgs.Player_PlaceEquip then
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
    end,
}

LuaShangjian = sgs.CreateTriggerSkill {
    name = 'LuaShangjian',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) then
                if rinsan.lostCard(move, player) then
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
    can_trigger = rinsan.targetTrigger,
}

ExWangyuanji:addSkill(LuaQianchong)
ExWangyuanji:addSkill(LuaShangjian)
ExWangyuanji:addRelateSkill('LuaWeimu')
ExWangyuanji:addRelateSkill('LuaMingzhe')
table.insert(hiddenSkills, LuaQianchongBasicCardTargetMod)
table.insert(hiddenSkills, LuaQianchongTrickCardTargetMod)
table.insert(hiddenSkills, LuaWeimu)
table.insert(hiddenSkills, LuaMingzhe)
table.insert(hiddenSkills, LuaQianchongClear)

ExXurong = sgs.General(extension, 'ExXurong', 'qun', '4', true, true)

LuaXionghuoCard = sgs.CreateSkillCard {
    name = 'LuaXionghuoCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and to_select:getMark('@baoli') == 0
    end,
    on_effect = function(self, effect)
        effect.from:loseMark('@baoli')
        effect.from:getRoom():broadcastSkillInvoke('LuaXionghuo')
        effect.to:gainMark('@baoli')
    end,
}

LuaXionghuoVS = sgs.CreateViewAsSkill {
    name = 'LuaXionghuo',
    n = 0,
    view_as = function(self, cards)
        return LuaXionghuoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@baoli') > 0
    end,
}

LuaXionghuoMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaXionghuoMaxCards',
    extra_func = function(self, target)
        if target:hasFlag('XionghuoCardMinus') then
            return -1
        end
        return 0
    end,
}

LuaXionghuoProSlash = sgs.CreateProhibitSkill {
    name = 'LuaXionghuoSlash',
    is_prohibited = function(self, from, to, card)
        if to:hasSkill('LuaXionghuo') and from:hasFlag('XionghuoSlashPro') then
            return card:isKindOf('Slash')
        end
    end,
}

LuaXionghuo = sgs.CreateTriggerSkill {
    name = 'LuaXionghuo',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaXionghuoVS,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('@baoli') > 0 then
            local splayer = room:findPlayerBySkillName(self:objectName())
            if splayer and splayer:objectName() ~= player:objectName() then
                player:loseMark('@baoli')
                room:sendCompulsoryTriggerLog(splayer, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local choice = rinsan.random(1, 3)
                if choice == 1 then
                    rinsan.doDamage(nil, player, 1, sgs.DamageStruct_Fire)
                    room:setPlayerFlag(player, 'XionghuoSlashPro')
                elseif choice == 2 then
                    room:loseHp(player)
                    room:setPlayerFlag(player, 'XionghuoCardMinus')
                else
                    if not player:isKongcheng() then
                        local handcard = player:getHandcards():at(math.random(0, player:getHandcardNum() - 1))
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, splayer:objectName())
                        room:obtainCard(splayer, handcard, reason, false)
                    end
                    if player:hasEquip() then
                        local equipCard = player:getCards('e'):at(math.random(0, player:getCards('e'):length() - 1))
                        local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, splayer:objectName())
                        room:obtainCard(splayer, equipCard, reason2, false)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Play
    end,
}

LuaXionghuoHelper = sgs.CreateTriggerSkill {
    name = 'LuaXionghuoHelper',
    events = {sgs.GameStart, sgs.DamageCaused},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill('LuaXionghuo') and p:getMark('LuaBaoliGetMark') == 0 then
                    room:sendCompulsoryTriggerLog(p, 'LuaXionghuo')
                    room:broadcastSkillInvoke('LuaXionghuo')
                    p:gainMark('@baoli', 3)
                    room:addPlayerMark(p, 'LuaBaoliGetMark')
                end
            end
        else
            local damage = data:toDamage()
            if damage.from:hasSkill('LuaXionghuo') and damage.to:getMark('@baoli') > 0 then
                room:sendCompulsoryTriggerLog(damage.from, 'LuaXionghuo')
                room:broadcastSkillInvoke('LuaXionghuo')
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShajue = sgs.CreateTriggerSkill {
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
    can_trigger = rinsan.targetTrigger,
}

ExXurong:addSkill(LuaXionghuo)
ExXurong:addSkill(LuaShajue)
table.insert(hiddenSkills, LuaXionghuoMaxCards)
table.insert(hiddenSkills, LuaXionghuoProSlash)
table.insert(hiddenSkills, LuaXionghuoHelper)

ExCaoying = sgs.General(extension, 'ExCaoying', 'wei', '4', false)

LuaLingren = sgs.CreateTriggerSkill {
    name = 'LuaLingren',
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local card = use.card
        if use.from:objectName() ~= player:objectName() then
            return false
        end
        if not (card:isKindOf('Slash') or card:isKindOf('Duel') or card:isKindOf('SavageAssault') or
            card:isKindOf('ArcheryAttack') or card:isKindOf('FireAttack')) then
            return false
        end
        local splayers = sgs.SPlayerList()
        for _, p in sgs.qlist(use.to) do
            splayers:append(p)
        end
        -- For AI
        local LuaLingrenAIData = sgs.QVariant()
        LuaLingrenAIData:setValue(card)
        player:setTag('LuaLingrenAIData', LuaLingrenAIData)
        local target = room:askForPlayerChosen(player, splayers, self:objectName(), 'LuaLingren-choose', true, true)
        player:removeTag('LuaLingrenAIData')
        if target then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerFlag(player, self:objectName())
            -- For AI
            local targetData = sgs.QVariant()
            targetData:setValue(rinsan.lingrenAIInitialize(player, target))
            local choice1 = room:askForChoice(player, 'BasicCardGuess', 'Have+NotHave', targetData)
            local choice2 = room:askForChoice(player, 'TrickCardGuess', 'Have+NotHave', targetData)
            local choice3 = room:askForChoice(player, 'EquipCardGuess', 'Have+NotHave', targetData)
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
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play) and not target:hasFlag(self:objectName())
    end,
}

-- 用于游戏开始时初始化总卡牌数量
LuaLingrenAIInitializer = sgs.CreateTriggerSkill {
    name = 'LuaLingrenAIInitializer',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if room:getTag('LuaLingrenAIInitialized'):toBool() then
            return false
        end
        for _, caoying in sgs.qlist(room:findPlayersBySkillName('LuaLingren')) do
            rinsan.cardNumInitialize(caoying)
        end
        room:setTag('LuaLingrenAIInitialized', sgs.QVariant(true))
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaLingrenHelper = sgs.CreateTriggerSkill {
    name = 'LuaLingrenHelper',
    events = {sgs.DamageCaused, sgs.CardEffected, sgs.TurnStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            local card = damage.card
            if damage.from and damage.from:objectName() == player:objectName() then
                if card and card:hasFlag('LuaLingrenAddDamage') then
                    room:sendCompulsoryTriggerLog(player, 'LuaLingren')
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
                room:sendCompulsoryTriggerLog(player, 'LuaLingren')
                room:removePlayerMark(player, 'LuaLingrenSkills')
                room:handleAcquireDetachSkills(player, '-LuaJianxiong|-LuaXingshang')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaLingren')
    end,
}

LuaJianxiong = sgs.CreateMasochismSkill {
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
    end,
}

LuaXingshang = sgs.CreateTriggerSkill {
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
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), splayer:objectName())
                room:obtainCard(player, dummy, reason, false)
            end
            dummy:deleteLater()
        end
        return false
    end,
}

LuaFujian = sgs.CreateTriggerSkill {
    name = 'LuaFujian',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local max = room:alivePlayerCount() - 1
            local index = rinsan.random(1, max)
            local target = sgs.QList2Table(room:getOtherPlayers(player))[index]
            room:showAllCards(target, player)
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
        end
    end,
}

ExCaoying:addSkill(LuaLingren)
ExCaoying:addSkill(LuaFujian)
ExCaoying:addRelateSkill('LuaJianxiong')
ExCaoying:addRelateSkill('LuaXingshang')
table.insert(hiddenSkills, LuaJianxiong)
table.insert(hiddenSkills, LuaXingshang)
table.insert(hiddenSkills, LuaLingrenHelper)
table.insert(hiddenSkills, LuaLingrenAIInitializer)

ExLijue = sgs.General(extension, 'ExLijue', 'qun', 6, true, false, false, 4)

LuaYisuan = sgs.CreateTriggerSkill {
    name = 'LuaYisuan',
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local card = data:toCardUse().card
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
                if not player:hasFlag(self:objectName()) then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:setPlayerFlag(player, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        room:loseMaxHp(player)
                        player:obtainCard(togain)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaLangxi = sgs.CreateTriggerSkill {
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
                local target = room:askForPlayerChosen(player, targets, self:objectName(), 'LuaLangxi-choose', true,
                    true)
                if target then
                    local value = rinsan.random(0, 2)
                    room:broadcastSkillInvoke(self:objectName())
                    if value == 0 then
                        return false
                    end
                    rinsan.doDamage(player, target, value)
                end
            end
        end
        return false
    end,
}

ExLijue:addSkill(LuaYisuan)
ExLijue:addSkill(LuaLangxi)

ExMaliang = sgs.General(extension, 'ExMaliang', 'shu', '3', true)

LuaZishu = sgs.CreateTriggerSkill {
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
                        local owner = room:getCardOwner(id)
                        if owner and owner:objectName() == player:objectName() and room:getCardPlace(id) ==
                            sgs.Player_PlaceHand then
                            room:addPlayerMark(player, self:objectName() .. id)
                        end
                    end
                elseif player:getPhase() ~= sgs.Player_NotActive and move.reason.m_skillName ~= 'LuaZishu' and
                    rinsan.RIGHT(self, player) then
                    for _, id in sgs.qlist(move.card_ids) do
                        if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) ==
                            sgs.Player_PlaceHand then
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
                        room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                            p:objectName(), self:objectName(), nil), p)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                    if player:getNextAlive():objectName() == p:objectName() then
                        room:getThread():delay(2500)
                    end
                end
            end
            -- 自书弃牌完毕后移除所有玩家的自书弃牌标记
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                rinsan.clearAllMarksContains(p, self:objectName())
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaYingyuan = sgs.CreateTriggerSkill {
    name = 'LuaYingyuan',
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local card = data:toCardUse().card
        if card:isKindOf('SkillCard') then
            return false
        end
        if card and player:getMark('LuaYingyuan' .. card:objectName() .. '-Clear') == 0 then
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
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), 'LuaYingyuan',
                    '@LuaYingyuanTo:' .. card:objectName(), true, true)
                if target then
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                        target:objectName(), self:objectName(), nil)
                    room:broadcastSkillInvoke(self:objectName())
                    room:moveCardTo(togain, player, target, sgs.Player_PlaceHand, reason, false)
                    room:addPlayerMark(player, 'LuaYingyuan' .. card:objectName() .. '-Clear')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTNOTATPHASE(self, target, sgs.Player_NotActive)
    end,
}

LuaYingyuanClear = sgs.CreateTriggerSkill {
    name = 'LuaYingyuanClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            rinsan.clearAllMarksContains(player, self:objectName())
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

ExMaliang:addSkill(LuaZishu)
ExMaliang:addSkill(LuaYingyuan)
table.insert(hiddenSkills, LuaYingyuanClear)

ExCaochun = sgs.General(extension, 'ExCaochun', 'wei', '4', true)

LuaShanjiaCard = sgs.CreateSkillCard {
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
        slash:setSkillName('LuaShanjia')
        for _, cd in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(cd)
        end
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, sgs.Self) and sgs.Self:canSlash(to_select)
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
        room:notifySkillInvoked(source, 'LuaShanjia')
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target) then
                targets_list:append(target)
            end
        end
        if targets_list:length() > 0 then
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName('LuaShanjia')
            room:useCard(sgs.CardUseStruct(slash, source, targets_list))
        else
            room:broadcastSkillInvoke('LuaShanjia')
        end
    end,
}

LuaShanjiaVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaShanjia = sgs.CreateTriggerSkill {
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
            if (move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceEquip)) then
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
    end,
}

ExCaochun:addSkill(LuaShanjia)

ExJiakui = sgs.General(extension, 'ExJiakui', 'wei', '3', true, true)

LuaZhongzuo = sgs.CreateTriggerSkill {
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
                            local target = room:askForPlayerChosen(p, room:getAlivePlayers(), 'LuaZhongzuo',
                                '@LuaZhongzuoChoose', true, true)
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
    can_trigger = rinsan.targetTrigger,
}

LuaWanlan = sgs.CreateTriggerSkill {
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
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), dying.who:objectName())
            rinsan.recover(dying.who, 1 - dying.who:getHp(), player)
            room:damage(sgs.DamageStruct(self:objectName(), player, current))
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getMark('@LuaWanlan') > 0
    end,
}

ExJiakui:addSkill(LuaZhongzuo)
ExJiakui:addSkill(LuaWanlan)

JieXusheng = sgs.General(extension, 'JieXusheng', 'wu', '4', true)

LuaPojun = sgs.CreateTriggerSkill {
    name = 'LuaPojun',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            for _, t in sgs.qlist(use.to) do
                local n = math.min(t:getCards('he'):length(), t:getHp())
                local data2 = sgs.QVariant()
                data2:setValue(t)
                if n > 0 and room:askForSkillInvoke(player, self:objectName(), data2) then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), t:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    local dis_num = {}
                    for i = 1, n, 1 do
                        table.insert(dis_num, tostring(i))
                    end
                    local discard_n = tonumber(room:askForChoice(player, self:objectName(), table.concat(dis_num, '+')))
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), t:objectName())
                    if discard_n > 0 then
                        local orig_places = {}
                        local cards = sgs.IntList()
                        room:setTag('LuaFakeMove', sgs.QVariant(true))
                        room:setPlayerFlag(t, 'xuanhuo_InTempMoving')
                        for i = 0, discard_n - 1, 1 do
                            local id = room:askForCardChosen(player, t, 'he', self:objectName(), false,
                                sgs.Card_MethodNone, cards)
                            local place = room:getCardPlace(id)
                            orig_places[i] = place
                            cards:append(id)
                            t:addToPile('#LuaPojun', id, false)
                        end
                        for i = 0, discard_n - 1, 1 do
                            room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), t, orig_places[i], false)
                        end
                        room:setPlayerFlag(t, '-xuanhuo_InTempMoving')
                        room:setTag('LuaFakeMove', sgs.QVariant(false))
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        dummy:addSubcards(cards)
                        t:addToPile('LuaPojun', dummy, false)
                    end
                end
            end
        end
        return false
    end,
}

LuaPojunBack = sgs.CreateTriggerSkill {
    name = 'LuaPojunBack',
    events = {sgs.EventPhaseStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
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
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Finish
    end,
}

LuaPojunDamage = sgs.CreateTriggerSkill {
    name = 'LuaPojunDamage',
    events = {sgs.DamageCaused},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (not damage.from) or (damage.from:objectName() ~= player:objectName()) then
            return false
        end
        if damage.card and damage.card:isKindOf('Slash') then
            if player:getHandcardNum() >= damage.to:getHandcardNum() and player:getEquips():length() >=
                damage.to:getEquips():length() then
                damage.damage = damage.damage + 1
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                room:broadcastSkillInvoke('LuaPojun')
                room:notifySkillInvoked(player, 'LuaPojun')
                rinsan.sendLogMessage(room, '#LuaPojunDamageUp', {
                    ['from'] = player,
                    ['card_str'] = damage.card:toString(),
                })
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaPojun')
    end,
}

JieXusheng:addSkill(LuaPojun)
table.insert(hiddenSkills, LuaPojunBack)
table.insert(hiddenSkills, LuaPojunDamage)

JieMadai = sgs.General(extension, 'JieMadai', 'shu', '4', true, true)

LuaMashu = sgs.CreateTriggerSkill {
    name = 'LuaMashu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        local victims = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:canSlash(p, nil, false) then
                victims:append(p)
            end
        end
        if victims:isEmpty() then
            return false
        end
        local victim = room:askForPlayerChosen(player, victims, self:objectName(), '@LuaMashuSlashTo', true, true)
        if victim then
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(slash, player, victim))
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Finish) and not target:hasFlag('MashuSlashDamage')
    end,
}

LuaMashuHelper = sgs.CreateTriggerSkill {
    name = 'LuaMashuHelper',
    events = {sgs.Damage},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (not damage.from) or damage.from:objectName() ~= player:objectName() then
            return false
        end
        if damage and damage.from and damage.card then
            if damage.card:isKindOf('Slash') then
                room:setPlayerFlag(damage.from, 'MashuSlashDamage')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play, 'LuaMashu')
    end,
}

LuaMashuDistance = sgs.CreateDistanceSkill {
    name = 'LuaMashuDistance',
    correct_func = function(self, from, to)
        if from:hasSkill('LuaMashu') then
            return -1
        end
        return 0
    end,
}

LuaQianxi = sgs.CreateTriggerSkill {
    name = 'LuaQianxi',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        for _, sp in sgs.qlist(room:getAlivePlayers()) do
            if sp:distanceTo(player) <= 1 and sp:hasSkill(self:objectName()) then
                if room:askForSkillInvoke(sp, self:objectName()) then
                    local userData = sgs.QVariant()
                    userData:setValue(sp)
                    if room:askForSkillInvoke(room:getCurrent(), 'LuaQianxiDraw', userData) then
                        rinsan.sendLogMessage(room, '#LuaQianxiDrawAccept', {
                            ['from'] = room:getCurrent(),
                            ['to'] = sp,
                        })
                        room:doAnimate(rinsan.ANIMATE_INDICATE, room:getCurrent():objectName(), sp:objectName())
                        sp:drawCards(1, self:objectName())
                    else
                        rinsan.sendLogMessage(room, '#LuaQianxiDrawRefuse', {
                            ['from'] = room:getCurrent(),
                            ['to'] = sp,
                        })
                    end
                    if sp:isKongcheng() then
                        return false
                    end
                    local card = room:askForCard(sp, '.|.|.|hand!', '@LuaQianxi-discard', sgs.QVariant(),
                        sgs.Card_MethodDiscard)
                    if not card then
                        return false
                    end
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
                    if victims:isEmpty() then
                        return false
                    end
                    local victim = room:askForPlayerChosen(sp, victims, self:objectName(), '@LuaQianxi-choose', false,
                        true)
                    if victim then
                        local pattern = '.|' .. color .. '|.|hand'
                        if player:getMark('@qianxi_red') > 0 and color == 'black' then
                            pattern = '.|' .. '.' .. '|.|hand'
                        end
                        if player:getMark('@qianxi_black') > 0 and color == 'red' then
                            pattern = '.|' .. '.' .. '|.|hand'
                        end
                        room:doAnimate(rinsan.ANIMATE_INDICATE, sp:objectName(), victim:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(victim, '@qianxi_' .. color)
                        room:setPlayerCardLimitation(victim, 'use, response', pattern, false)
                        rinsan.sendLogMessage(room, '#Qianxi', {
                            ['from'] = victim,
                            ['arg'] = color,
                        })
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Start
    end,
}

LuaQianxiClear = sgs.CreateTriggerSkill {
    name = 'LuaQianxiClear',
    events = {sgs.EventPhaseChanging, sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to ~= sgs.Player_NotActive then
                return false
            end
        elseif event == sgs.Death then
            if data:toDeath().who:objectName() ~= player:objectName() or
                not data:toDeath().who:hasSkill(self:objectName()) then
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
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

JieMadai:addSkill(LuaMashu)
JieMadai:addSkill(LuaQianxi)
table.insert(hiddenSkills, LuaMashuDistance)
table.insert(hiddenSkills, LuaMashuHelper)
table.insert(hiddenSkills, LuaQianxiClear)

ExMajun = sgs.General(extension, 'ExMajun', 'wei', '3', true)

LuaJingxieCard = sgs.CreateSkillCard {
    name = 'LuaJingxie',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:showCard(source, card:getEffectiveId())
        rinsan.majunUpgradeCard(card, source)
    end,
}

LuaJingxieVS = sgs.CreateViewAsSkill {
    name = 'LuaJingxie',
    n = 1,
    view_filter = function(self, selected, to_select)
        return rinsan.canBeUpgrade(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local kf = LuaJingxieCard:clone()
            kf:addSubcard(cards[1])
            return kf
        end
        return nil
    end,
}

LuaJingxie = sgs.CreateTriggerSkill {
    name = 'LuaJingxie',
    view_as_skill = LuaJingxieVS,
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() then
            room:filterCards(player, player:getCards('he'), true)
            local card = room:askForCard(player, 'Armor|.|.|.', 'LuaJingxie-Invoke', data, sgs.Card_MethodRecast)
            if card then
                room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(
                    sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), card:objectName(), ''))
                rinsan.sendLogMessage(room, '#UseCard_Recase', {
                    ['from'] = player,
                    ['card_str'] = card:getEffectiveId(),
                })
                room:broadcastSkillInvoke('@recast')
                player:drawCards(1, 'recast')
                rinsan.recover(dying.who, 1 - dying.who:getHp(), player)
                room:broadcastSkillInvoke(self:objectName(), 1)
            end
            room:filterCards(player, player:getCards('he'), false)
        end
        return false
    end,
}

LuaJingxieStart = sgs.CreateTriggerSkill {
    name = 'LuaJingxieStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if not room:getTag('MajunEquipsRemoved'):toBool() then
            rinsan.removeMajunEquipsFromPile(room)
            room:setTag('MajunEquipsRemoved', sgs.QVariant(true))
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaQiaosiCard = sgs.CreateSkillCard {
    name = 'LuaQiaosiCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0)
    end,
    feasible = function(self, targets)
        return #targets >= 0
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaQiaosi')
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cd)
        end
        local target = targets[1]
        if target then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
                target:objectName(), self:objectName(), nil)
            room:moveCardTo(to_goback, source, target, sgs.Player_PlaceHand, reason, true)
        else
            room:throwCard(to_goback, source)
        end
    end,
}

-- 巧思获得牌的类型判断
local function LuaGetRoleCardType(roleType, kingActivated, generalActivated)
    local map = {
        ['king'] = {
            'TrickCard',
            'TrickCard',
        },
        ['general'] = {
            'EquipCard',
            'EquipCard',
        },
        ['artisan'] = {
            'Slash',
            'Slash',
            'Slash',
            'Slash',
            'Analeptic',
        },
        ['farmer'] = {
            'Jink',
            'Jink',
            'Jink',
            'Jink',
            'Peach',
        },
        ['scholar'] = {
            'TrickCard',
            'TrickCard',
            'TrickCard',
            'TrickCard',
            'JinkOrPeach',
        },
        ['scholarKing'] = {
            'Peach',
            'Peach',
            'Peach',
            'Peach',
            'Jink',
        },
        ['merchant'] = {
            'EquipCard',
            'EquipCard',
            'EquipCard',
            'EquipCard',
            'SlashOrAnaleptic',
        },
        ['merchantGeneral'] = {
            'Analeptic',
            'Analeptic',
            'Analeptic',
            'Analeptic',
            'Slash',
        },
    }
    if roleType == 'scholar' and kingActivated then
        roleType = roleType .. 'King'
    end
    if roleType == 'merchant' and generalActivated then
        roleType = roleType .. 'General'
    end
    return map[roleType]
end

-- 巧思获得牌
local function LuaQiaosiGetCards(room, roleType)
    -- 王、商、工、农、士、将
    -- King、Merchant、Artisan、Farmer、Scholar、General
    -- roleType 代表转的人类型，为 Table 类型
    -- 例如{'king', 'artisan', 'general'}
    local results = {}
    local kingActivated = table.contains(roleType, 'king')
    local generalActivated = table.contains(roleType, 'general')
    for _, type in ipairs(roleType) do
        local cardTypes = LuaGetRoleCardType(type, kingActivated, generalActivated)
        table.insert(results, cardTypes)
    end
    return results
end

-- 巧思封装函数
local function LuaDoQiaosiShow(player, dummyCard)
    local room = player:getRoom()
    local choices = {'king', 'merchant', 'artisan', 'farmer', 'scholar', 'general', 'cancel'}
    local chosenRoles = {}
    local index = 0
    local continuePlaying = true
    while index < 3 and continuePlaying do
        local choice = room:askForChoice(player, 'LuaQiaosi', table.concat(choices, '+'))
        if choice == 'cancel' then
            continuePlaying = false
        end
        table.removeOne(choices, choice)
        table.insert(chosenRoles, choice)
        index = index + 1
    end
    local toGiveCardTypes = LuaQiaosiGetCards(room, chosenRoles)
    local about_to_obtain = {}
    -- 预期的总牌数
    local expected_length = 0
    for _, cardTypes in ipairs(toGiveCardTypes) do
        local params = {
            ['existed'] = about_to_obtain,
            ['findDiscardPile'] = true,
        }
        if #cardTypes == 2 then
            -- 确定的，王、将
            params['type'] = cardTypes[1]
            local card1 = rinsan.obtainTargetedTypeCard(room, params)
            expected_length = expected_length + 2
            if card1 then
                table.insert(about_to_obtain, card1:getId())
                dummyCard:addSubcard(card1)
                local card2 = rinsan.obtainTargetedTypeCard(room, params)
                if card2 then
                    table.insert(about_to_obtain, card2:getId())
                    dummyCard:addSubcard(card2)
                end
            end
        else
            -- 不确定的，要抽奖
            local currType = rinsan.random(1, 5)
            expected_length = expected_length + 1
            local type = cardTypes[currType]
            if string.find(type, 'JinkOrPeach') then
                type = LuaGetRoleCardType('scholarKing', true, true)
            elseif string.find(type, 'SlashOrAnaleptic') then
                type = LuaGetRoleCardType('merchantGeneral', true, true)
            end
            params['type'] = type
            local card = rinsan.obtainTargetedTypeCard(room, params)
            if card then
                table.insert(about_to_obtain, card:getId())
                dummyCard:addSubcard(card)
            end
        end
    end
    player:obtainCard(dummyCard)
    -- 直接从牌堆顶获取差额牌
    if dummyCard:subcardsLength() < expected_length then
        dummyCard:addSubcards(room:getNCards(expected_length - dummyCard:subCardsLength()))
    end
    return dummyCard:subcardsLength()
end

LuaQiaosiStartCard = sgs.CreateSkillCard {
    name = 'LuaQiaosiStartCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaQiaosi')
        room:notifySkillInvoked(source, 'LuaQiaosi')
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        local marks = LuaDoQiaosiShow(source, dummy)
        if marks > 0 then
            room:addPlayerMark(source, 'LuaQiaosiCardsNum', marks)
            room:addPlayerMark(source, 'LuaQiaosiGiven')
            room:askForUseCard(source, '@@LuaQiaosi!', 'LuaQiaosi_give:' .. source:getMark('LuaQiaosiCardsNum'), -1,
                sgs.Card_MethodNone)
            room:removePlayerMark(source, 'LuaQiaosiGiven')
            room:setPlayerMark(source, 'LuaQiaosiCardsNum', 0)
        end
    end,
}

LuaQiaosi = sgs.CreateViewAsSkill {
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
    end,
}

ExMajun:addSkill(LuaJingxie)
ExMajun:addSkill(LuaQiaosi)
table.insert(hiddenSkills, LuaJingxieStart)

ExYiji = sgs.General(extension, 'ExYiji', 'shu', '3', true)

LuaJijieCard = sgs.CreateSkillCard {
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
        room:broadcastSkillInvoke('LuaJijie')
        local card = sgs.Sanguosha:getCard(id)
        local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), 'LuaJijie',
            '@LuaJijiePlayer-Chosen', true, true)
        if target then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
                target:objectName(), 'LuaJijie', nil)
            room:clearAG()
            room:moveCardTo(card, source, target, sgs.Player_PlaceHand, reason, false)
        else
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEWGIVE, source:objectName(),
                source:objectName(), 'LuaJijie', nil)
            room:clearAG()
            room:moveCardTo(card, source, source, sgs.Player_PlaceHand, reason, false)
        end
    end,
}

LuaJijie = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaJijie',
    view_as = function(self, cards)
        return LuaJijieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaJijieCard')
    end,
}

LuaJiyuan = sgs.CreateTriggerSkill {
    name = 'LuaJiyuan',
    events = {sgs.Dying, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Dying then
            local dying = data:toDying()
            local data2 = sgs.QVariant()
            data2:setValue(dying.who)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                room:broadcastSkillInvoke(self:objectName())
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), dying.who:objectName())
                dying.who:drawCards(1, self:objectName())
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() ~= player:objectName() then
                if move.from and move.from:objectName() == player:objectName() then
                    local reason = move.reason.m_reason
                    -- 顺手牵羊等为此 reason_id
                    if reason == sgs.CardMoveReason_S_REASON_EXTRACTION or reason == sgs.CardMoveReason_S_REASON_ROB then
                        return false
                    end
                    if rinsan.moveBasicReasonCompare(reason, sgs.CardMoveReason_S_REASON_GOTCARD) then
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
                            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
                            target:drawCards(1, self:objectName())
                        end
                    end
                end
            end
        end
    end,
}

ExYiji:addSkill(LuaJijie)
ExYiji:addSkill(LuaJiyuan)

ExLifeng = sgs.General(extension, 'ExLifeng', 'shu', '3', true)

LuaTunchuCard = sgs.CreateSkillCard {
    name = 'LuaTunchuCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaTunchu')
        local subs = self:getSubcards()
        for _, card_id in sgs.qlist(subs) do
            source:addToPile('LuaLiang', card_id)
        end
    end,
}

LuaTunchuVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaTunchu = sgs.CreateTriggerSkill {
    name = 'LuaTunchu',
    view_as_skill = LuaTunchuVS,
    events = {sgs.DrawNCards, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            if player:getPile('LuaLiang'):length() == 0 then
                if room:askForSkillInvoke(player, self:objectName()) then
                    room:broadcastSkillInvoke(self:objectName())
                    local x = data:toInt()
                    x = x + 2
                    player:setFlags('LuaTunchuInvoked')
                    data:setValue(x)
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:hasFlag('LuaTunchuInvoked') then
                room:askForUseCard(player, '@@LuaTunchu', '@LuaTunchu', -1, sgs.Card_MethodNone)
                player:setFlags('-LuaTunchuInvoked')
            end
        end
        return false
    end,
}

LuaTunchuHelper = sgs.CreateTriggerSkill {
    name = 'LuaTunchuHelper',
    events = {sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventLoseSkill then
            if data:toString() == 'LuaTunchu' then
                room:removePlayerCardLimitation(player, 'use', 'Slash|.|.|.$0')
            end
        elseif event == sgs.EventAcquireSkill then
            if data:toString() == 'LuaTunchu' then
                if player:getPile('LuaLiang'):length() > 0 then
                    room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.', false)
                end
            end
        elseif event == sgs.CardsMoveOneTime and rinsan.RIGHT(self, player, 'LuaTunchu') then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceSpecial and
                move.to_pile_name == 'LuaLiang' then
                if player:getPile('LuaLiang'):length() == 1 then
                    room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.', false)
                end
            elseif move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceSpecial) then
                if player:getPile('LuaLiang'):length() == 0 then
                    room:removePlayerCardLimitation(player, 'use', 'Slash|.|.|.$0')
                end
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShuliangCard = sgs.CreateSkillCard {
    name = 'LuaShuliangCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaShuliang')
        room:broadcastSkillInvoke('LuaShuliang')
        local current = room:getCurrent()
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), current:objectName())
        current:drawCards(2, 'LuaShuliang')
    end,
}

LuaShuliangVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaShuliang',
    response_pattern = '@@LuaShuliang',
    filter_pattern = '.|.|.|LuaLiang',
    expand_pile = 'LuaLiang',
    view_as = function(self, card)
        local kf = LuaShuliangCard:clone()
        kf:addSubcard(card)
        return kf
    end,
}

LuaShuliang = sgs.CreateTriggerSkill {
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
    can_trigger = rinsan.targetTrigger,
}

ExLifeng:addSkill(LuaTunchu)
ExLifeng:addSkill(LuaShuliang)
table.insert(hiddenSkills, LuaTunchuHelper)

ExZhaotongZhaoguang = sgs.General(extension, 'ExZhaotongZhaoguang', 'shu', '4', true, true)

LuaYizanCard = sgs.CreateSkillCard {
    name = 'LuaYizanCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return rinsan.guhuoCardFilter(self, targets, to_select, 'LuaYizan')
    end,
    feasible = function(self, targets)
        return rinsan.selfFeasible(self, targets, 'LuaYizan')
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidate(self, card_use, 'LuaYizan', 'yizan', 'Yizan')
        if use_card then
            room:addPlayerMark(source, 'LuaYizanUse')
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidateInResponse(self, source, 'LuaYizan', 'yizan', 'Yizan')
        if use_card then
            room:addPlayerMark(source, 'LuaYizanUse')
        end
        return use_card
    end,
}

LuaYizanVS = sgs.CreateViewAsSkill {
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
        return rinsan.guhuoVSSkillEnabledAtResponse(self, player, pattern)
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

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = LuaYizanCard:clone()
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            card:setUserString(pattern)
            for _, cd in ipairs(cards) do
                card:addSubcard(cd)
            end
            local available = false
            for _, name in ipairs(pattern:split('+')) do
                local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
                c:deleteLater()
                if not sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                    available = true
                    break
                end
            end
            if not available then
                return nil
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
            if sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                return nil
            end
            return card
        else
            return nil
        end
    end,
}

LuaYizan = sgs.CreateTriggerSkill {
    name = 'LuaYizan',
    view_as_skill = LuaYizanVS,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == 'LuaLongyuan' and mark.who:hasSkill(self:objectName()) then
            ChangeSkill(self, room, player)
        end
    end,
}

LuaYizan:setGuhuoDialog('l')

LuaLongyuan = sgs.CreateTriggerSkill {
    name = 'LuaLongyuan',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        rinsan.sendLogMessage(room, '#LuaLongyuan', {
            ['from'] = player,
            ['arg'] = player:getMark('LuaYizanUse'),
            ['arg2'] = self:objectName(),
        })
        if room:changeMaxHpForAwakenSkill(player, 0) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, 'LuaLongyuan')
        end
        return false
    end,
    can_trigger = function(self, target)
        if target:getMark('LuaYizanUse') < 3 then
            return false
        end
        return rinsan.RIGHT(self, target) and rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Start)
    end,
}

ExZhaotongZhaoguang:addSkill(LuaYizan)
ExZhaotongZhaoguang:addSkill(LuaLongyuan)

JieYanliangWenchou = sgs.General(extension, 'JieYanliangWenchou', 'qun', '4', true)

LuaShuangxiongVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaShuangxiong',
    view_filter = function(self, to_select)
        if to_select:isEquipped() then
            return false
        end
        if sgs.Self:hasFlag('LuaShuangxiongRed') then
            -- Black
            return to_select:isBlack()
        elseif sgs.Self:hasFlag('LuaShuangxiongBlack') then
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
        if player:hasFlag('LuaShuangxiongRed') or player:hasFlag('LuaShuangxiongBlack') then
            return not player:isKongcheng()
        end
        return false
    end,
}

LuaShuangxiong = sgs.CreateTriggerSkill {
    name = 'LuaShuangxiong',
    view_as_skill = LuaShuangxiongVS,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
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
                    room:setPlayerFlag(player, 'LuaShuangxiongRed')
                else
                    room:setPlayerFlag(player, 'LuaShuangxiongBlack')
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
            return true
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Draw)
    end,
}

LuaShuangxiongDamaged = sgs.CreateTriggerSkill {
    name = 'LuaShuangxiongDamaged',
    events = {sgs.Damaged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:getSkillName() == 'LuaShuangxiong' then
            -- For AI
            room:setPlayerFlag(player, 'LuaShuangxiongDamaged')
            if room:askForSkillInvoke(player, 'LuaShuangxiong', data) then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                for _, id in sgs.qlist(room:getDiscardPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:hasFlag('LuaShuangxiongResponded') then
                        dummy:addSubcard(card)
                    end
                end
                player:obtainCard(dummy)
            end
            room:setPlayerFlag(player, '-LuaShuangxiongDamaged')
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaShuangxiong')
    end,
}

LuaShuangxiongCardHandler = sgs.CreateTriggerSkill {
    name = 'LuaShuangxiongCardHandler',
    events = {sgs.CardResponded, sgs.CardUsed, sgs.CardFinished},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardResponded then
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
            if use.card and use.card:getSkillName() == 'LuaShuangxiong' then
                use.from:setFlags('LuaShuangxiongInvoke')
            end
        else
            local use = data:toCardUse()
            -- Clear all card flags
            if use.card and use.card:getSkillName() == 'LuaShuangxiong' then
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
    can_trigger = rinsan.globalTrigger,
}

JieYanliangWenchou:addSkill(LuaShuangxiong)
table.insert(hiddenSkills, LuaShuangxiongDamaged)
table.insert(hiddenSkills, LuaShuangxiongCardHandler)

JieLingtong = sgs.General(extension, 'JieLingtong', 'wu', '4', true)

LuaXuanfengCard = sgs.CreateSkillCard {
    name = 'LuaXuanfengCard',
    filter = function(self, targets, to_select)
        if #targets >= 2 then
            return false
        end
        if to_select:objectName() == sgs.Self:objectName() then
            return false
        end
        return rinsan.canDiscard(sgs.Self, to_select, 'he')
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
                if source:isAlive() and sp:isAlive() and rinsan.canDiscard(source, sp, 'he') then
                    local card_id =
                        room:askForCardChosen(source, sp, 'he', 'LuaXuanfeng', false, sgs.Card_MethodDiscard)
                    room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), sp:objectName())
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
            local target = room:askForPlayerChosen(source, damageAvailable, 'LuaXuanfeng', 'LuaXuanfengDamage-choose',
                true, true)
            if target then
                rinsan.doDamage(source, target, 1)
                room:broadcastSkillInvoke('LuaXuanfeng')
            end
        end
    end,
}

LuaXuanfengVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaXuanfeng = sgs.CreateTriggerSkill {
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
            if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard) and
                rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) then
                player:setMark('LuaXuanfeng', player:getMark('LuaXuanfeng') + move.card_ids:length())
            end
            if ((player:getMark('LuaXuanfeng') >= 2) and (not player:hasFlag('LuaXuanfengUsed'))) or
                move.from_places:contains(sgs.Player_PlaceEquip) then
                local targets = sgs.SPlayerList()
                for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                    if rinsan.canDiscard(player, target, 'he') then
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
    end,
}

LuaYongjinCard = sgs.CreateSkillCard {
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
        rinsan.sendLogMessage(room, '#InvokeSkill', {
            ['from'] = source,
            ['arg'] = 'LuaYongjin',
        })
        room:notifySkillInvoked(source, 'LuaYongjin')
        room:broadcastSkillInvoke('LuaYongjin')
        local card_id = room:askForCardChosen(source, from, 'e', 'LuaYongjin', false, sgs.Card_MethodNone, disabled_ids)
        local card = sgs.Sanguosha:getCard(card_id)
        room:moveCardTo(card, from, to, sgs.Player_PlaceEquip,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, from:objectName(), 'LuaYongjin', ''))
        room:addPlayerMark(source, 'LuaYongjin')
        local use = room:askForUseCard(source, '@@LuaYongjin', '@LuaYongjin:::' .. (3 - source:getMark('LuaYongjin')))
        if not use then
            room:setPlayerMark(source, 'LuaYongjin', 0)
            source:loseMark('@luayongjin')
        end
    end,
}

LuaYongjinVS = sgs.CreateZeroCardViewAsSkill {
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
    end,
}

LuaYongjin = sgs.CreateTriggerSkill {
    name = 'LuaYongjin',
    frequency = sgs.Skill_Limited,
    limit_mark = '@luayongjin',
    view_as_skill = LuaYongjinVS,
    on_trigger = function()
    end,
}

JieLingtong:addSkill(LuaXuanfeng)
JieLingtong:addSkill(LuaYongjin)

ExShenpei = sgs.General(extension, 'ExShenpei', 'qun', 3, true, false, false, 2)

LuaShouye = sgs.CreateTriggerSkill {
    name = 'LuaShouye',
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf('SkillCard') or use.to:length() > 1 or use.to:contains(use.from) then
            return false
        end
        for _, p in sgs.qlist(use.to) do
            if p:getMark(self:objectName()) == 0 and p:hasSkill(self:objectName()) then
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:addPlayerMark(p, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:doAnimate(rinsan.ANIMATE_INDICATE, p:objectName(), use.from:objectName())
                    local choice1 = room:askForChoice(use.from, 'LuaShouye', 'syjg1+syjg2')
                    local choice2 = room:askForChoice(p, 'LuaShouye', 'syfy1+syfy2')
                    ChoiceLog(use.from, choice1, nil)
                    ChoiceLog(p, choice2, nil)
                    local success1 = (choice1 == 'syjg1' and choice2 == 'syfy1')
                    local success2 = (choice1 == 'syjg2' and choice2 == 'syfy2')
                    local shouyeSuccess = (success1 or success2)
                    if not shouyeSuccess then
                        rinsan.sendLogMessage(room, '#ShouyeFailed', {
                            ['from'] = p,
                        })
                        return false
                    end
                    rinsan.sendLogMessage(room, '#ShouyeSucceed', {
                        ['from'] = p,
                    })
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, p:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                    local shouye_ids = sgs.IntList()
                    local card = use.card
                    if card:isVirtualCard() then
                        for _, id in sgs.qlist(card:getSubcards()) do
                            shouye_ids:append(id)
                        end
                    else
                        shouye_ids:append(card:getEffectiveId())
                    end
                    if shouye_ids:length() > 0 then
                        -- 以 Tag 形式存储【守邺】涉及到的牌
                        -- 存储内容为 id，若有多张，则以加号分隔
                        -- 为了避免在 card 上存储 Flag，效仿【化身】
                        local shouye_data = sgs.QVariant()
                        shouye_data:setValue(shouye_ids)
                        p:setTag('LuaShouyeIds', shouye_data)
                    end
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaShouyeClear = sgs.CreateTriggerSkill {
    name = 'LuaShouyeClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, 'LuaShouye', 0)
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShouyeRecycle = sgs.CreateTriggerSkill {
    name = 'LuaShouyeRecycle',
    events = {sgs.BeforeCardsMove},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to_place == sgs.Player_DiscardPile then
            local shouye_ids = player:getTag('LuaShouyeIds'):toIntList()
            if shouye_ids:length() <= 0 then
                return false
            end
            local card_ids = sgs.IntList()
            for _, card_id in sgs.qlist(move.card_ids) do
                if shouye_ids:contains(card_id) then
                    card_ids:append(card_id)
                end
            end
            if card_ids:isEmpty() then
                return false
            end
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
                room:obtainCard(player, dummy)
            end
            player:removeTag('LuaShouyeIds')
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaShouye')
    end,
}

LuaShouyeEffected = sgs.CreateTriggerSkill {
    name = 'LuaShouyeEffected',
    frequency = sgs.Skill_Compulsory,
    priority = 1000,
    global = true,
    events = {sgs.CardEffected},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        local shouye_ids = player:getTag('LuaShouyeIds'):toIntList()
        local can_invoke
        if effect.card:isVirtualCard() then
            for _, id in sgs.qlist(effect.card:getSubcards()) do
                if shouye_ids:contains(id) then
                    can_invoke = true
                    break
                end
            end
        else
            can_invoke = shouye_ids:contains(effect.card:getEffectiveId())
        end
        if can_invoke then
            rinsan.sendLogMessage(room, '#LuaSkillInvalidateCard', {
                ['from'] = player,
                ['arg'] = effect.card:objectName(),
                ['arg2'] = 'LuaShouye',
            })
            if effect.card:isKindOf('Slash') then
                player:removeQinggangTag(effect.card)
            end
            return true
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaLiezhiCard = sgs.CreateSkillCard {
    name = 'LuaLiezhiCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.LESS_OR_EQUAL, 1) then
            return rinsan.canDiscard(sgs.Self, to_select, 'hej')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaLiezhi')
        room:broadcastSkillInvoke('LuaLiezhi')
        for _, p in ipairs(targets) do
            local card_id = room:askForCardChosen(source, p, 'hej', 'LuaLiezhi', false, sgs.Card_MethodDiscard)
            room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), p:objectName())
            room:throwCard(card_id, p, source)
        end
    end,
}

LuaLiezhiVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaLiezhi = sgs.CreateTriggerSkill {
    name = 'LuaLiezhi',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaLiezhiVS,
    on_trigger = function(self, event, player, data, room)
        if player:hasFlag(self:objectName()) then
            return false
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if rinsan.canDiscard(player, p, 'hej') then
                room:askForUseCard(player, '@@LuaLiezhi', '@LuaLiezhi')
                break
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Start)
    end,
}

LuaLiezhiDamaged = sgs.CreateTriggerSkill {
    name = 'LuaLiezhiDamaged',
    events = {sgs.Damaged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerFlag(player, 'LuaLiezhi')
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaLiezhi')
    end,
}

ExShenpei:addSkill(LuaShouye)
ExShenpei:addSkill(LuaLiezhi)
table.insert(hiddenSkills, LuaShouyeClear)
table.insert(hiddenSkills, LuaShouyeEffected)
table.insert(hiddenSkills, LuaShouyeRecycle)
table.insert(hiddenSkills, LuaLiezhiDamaged)

ExYangbiao = sgs.General(extension, 'ExYangbiao', 'qun', '3', true)

LuaZhaohan = sgs.CreateTriggerSkill {
    name = 'LuaZhaohan',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getMark(self:objectName() .. 'up') < 4 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 1)
                rinsan.addPlayerMaxHp(player, 1)
                rinsan.recover(player, 1, player)
                room:addPlayerMark(player, self:objectName() .. 'up')
            elseif player:getMark(self:objectName() .. 'down') < 3 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:loseMaxHp(player)
                room:addPlayerMark(player, self:objectName() .. 'down')
            end
        end
        return false
    end,
}

LuaRangjieCard = sgs.CreateSkillCard {
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
        rinsan.sendLogMessage(room, '#InvokeSkill', {
            ['from'] = source,
            ['arg'] = 'LuaRangjie',
        })
        room:notifySkillInvoked(source, 'LuaRangjie')
        -- 使用 Tag 存储不能选择的 id
        local disabled_ids_data = sgs.QVariant()
        disabled_ids_data:setValue(disabled_ids)
        room:setTag('LuaRangjieDisabledIntList', disabled_ids_data)
        local card_id =
            room:askForCardChosen(source, from, 'ej', 'LuaRangjie', false, sgs.Card_MethodNone, disabled_ids)
        room:removeTag('LuaRangjieDisabledIntList')
        local card = sgs.Sanguosha:getCard(card_id)
        -- 由于 AI 的问题，可能会选中 disabled_ids 内的卡牌，这时不移动卡牌，使之返回
        local canMove
        if card:isKindOf('EquipCard') then
            canMove = not to:getEquip(card:getRealCard():toEquipCard():location())
        elseif card:isKindOf('TrickCard') then
            canMove = not to:containsTrick(card:objectName())
        end
        if canMove then
            room:moveCardTo(card, from, to, room:getCardPlace(card_id), sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_TRANSFER, from:objectName(), 'LuaRangjie', ''))
        else
            room:setTag('LuaRangjieMoveFailed', sgs.QVariant(true))
        end
    end,
}

LuaRangjieVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaRangjie',
    view_as = function(self)
        return LuaRangjieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaRangjie'
    end,
}

LuaRangjie = sgs.CreateTriggerSkill {
    name = 'LuaRangjie',
    events = {sgs.Damaged},
    view_as_skill = LuaRangjieVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local i = 0
        while i < damage.damage do
            i = i + 1
            local move
            if rinsan.canMoveCard(room) then
                move = room:askForUseCard(player, '@@LuaRangjie', '@LuaRangjie')
            end
            if (not move) or (room:getTag('LuaRangjieMoveFailed'):toBool()) then
                local choice =
                    room:askForChoice(player, self:objectName(), 'obtainBasic+obtainTrick+obtainEquip+cancel')
                local params = {
                    ['existed'] = {},
                    ['findDiscardPile'] = true,
                }
                if choice == 'cancel' then
                    room:setTag('LuaRangjieMoveFailed', sgs.QVariant(false))
                    return false
                else
                    params['type'] = string.gsub(choice, 'obtain', '') .. 'Card'
                    local card = rinsan.obtainTargetedTypeCard(room, params)
                    if card then
                        player:obtainCard(card, false)
                    end
                end
            end
            room:setTag('LuaRangjieMoveFailed', sgs.QVariant(false))
            -- 只要发动了“让节”，就会摸牌，因为选择“取消”时已经跳出循环了，因此不需要冗余的判断
            player:drawCards(1, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
        end
        return false
    end,
}

LuaYizhengCard = sgs.CreateSkillCard {
    name = 'LuaYizhengCard',
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.LESS, 1) then
            return to_select:getHp() <= sgs.Self:getHp() and sgs.Self:canPindian(to_select, 'LuaYizheng')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke('LuaYizheng')
        room:notifySkillInvoked(source, 'LuaYizheng')
        if source:pindian(target, 'LuaYizheng') then
            room:addPlayerMark(target, 'LuaYizhengSkipDrawPhase')
        else
            room:loseMaxHp(source)
        end
    end,
}

LuaYizhengVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaYizheng = sgs.CreateTriggerSkill {
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
    can_trigger = rinsan.targetTrigger,
}

ExYangbiao:addSkill(LuaZhaohan)
ExYangbiao:addSkill(LuaRangjie)
ExYangbiao:addSkill(LuaYizheng)

ExZhangyi = sgs.General(extension, 'ExZhangyi', 'shu', '4', true)

LuaZhiyi = sgs.CreateTriggerSkill {
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
                                sp:setTag('LuaZhiyiSlashType', sgs.QVariant(choice))
                                local target =
                                    room:askForPlayerChosen(sp, players, self:objectName(), 'LuaZhiyiSlashTo')
                                sp:removeTag('LuaZhiyiSlashTarget')
                                sp:removeTag('LuaZhiyiSlashType')
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
                        rinsan.clearAllMarksContains(sp, self:objectName())
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
    can_trigger = rinsan.targetTrigger,
}

ExZhangyi:addSkill(LuaZhiyi)

JieLiru = sgs.General(extension, 'JieLiru', 'qun', '3', true)

LuaJuece = sgs.CreateTriggerSkill {
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
            if rinsan.lostCard(move, player) then
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
                    local victim = room:askForPlayerChosen(player, victims, self:objectName(), '@LuaJueceDamageTo',
                        true, true)
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
    can_trigger = rinsan.targetTrigger,
}

LuaMiejiCard = sgs.CreateSkillCard {
    name = 'LuaMiejiCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) then
            return rinsan.canDiscard(to_select, to_select, 'he')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:notifySkillInvoked(source, 'LuaMieji')
        room:broadcastSkillInvoke('LuaMieji')
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), '', 'LuaMieji', '')
        local miejiCard = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:moveCardTo(miejiCard, source, nil, sgs.Player_DrawPile, reason, true)
        local cards = target:getCards('he')
        local cardsCopy = cards

        for _, c in sgs.qlist(cardsCopy) do
            if target:isCardLimited(c, sgs.Card_MethodDiscard) then
                cards:removeOne(c)
            end
        end

        if cards:isEmpty() then
            return
        end

        local pattern = '..!'
        local nonTrickNum = 0
        for _, c in sgs.qlist(cards) do
            if not c:isKindOf('TrickCard') then
                nonTrickNum = nonTrickNum + 1
            end
        end

        local card = room:askForCard(target, pattern, '@LuaMiejiDiscard', sgs.QVariant(), sgs.Card_MethodNone)
        if not card then
            card = cards:at(rinsan.random(0, cardsCopy:length() - 1))
        end
        if not card then
            return false
        end
        if card:isKindOf('TrickCard') then
            room:obtainCard(source, card)
        else
            room:throwCard(card, target)
            if nonTrickNum <= 1 then
                return false
            end
            pattern = '^TrickCard!'
            local maybeCards = {}
            for _, c in sgs.qlist(target:getCards('he')) do
                if not target:isCardLimited(c, sgs.Card_MethodDiscard) and not c:isKindOf('TrickCard') then
                    table.insert(maybeCards, c)
                end
            end
            if #maybeCards <= 0 then
                return false
            end
            card = room:askForCard(target, pattern, '@LuaMiejiDiscardNonTrick', sgs.QVariant(), sgs.Card_MethodNone)
            if not card or card:isKindOf('TrickCard') then
                card = maybeCards[rinsan.random(1, #maybeCards)]
            end
            if card then
                room:throwCard(card, target)
            end
        end
    end,
}

LuaMieji = sgs.CreateOneCardViewAsSkill {
    name = 'LuaMieji',
    filter_pattern = 'TrickCard|black',
    view_as = function(self, card)
        local miejiCard = LuaMiejiCard:clone()
        miejiCard:addSubcard(card)
        return miejiCard
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMiejiCard')
    end,
}

LuaFenchengCard = sgs.CreateSkillCard {
    name = 'LuaFenchengCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        source:loseMark('@burn')
        room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
        room:broadcastSkillInvoke('LuaFencheng')
        room:notifySkillInvoked(source, 'LuaFencheng')
        room:setEmotion(source, 'skill/fencheng')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), p:objectName())
        end
        room:getThread():delay(4000)
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                local length = room:getTag('LuaFenchengDiscard'):toInt() + 1
                if not rinsan.canDiscard(p, p, 'he') or p:getCardCount(true) < length or
                    not room:askForDiscard(p, 'fencheng', 10000, length, true, true, '@fencheng:::' .. length) then
                    room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
                    rinsan.doDamage(source, p, 2, sgs.DamageStruct_Fire)
                end
            end
        end
    end,
}

LuaFenchengVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaFencheng',
    view_as = function(self, cards)
        return LuaFenchengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@burn') > 0
    end,
}

LuaFencheng = sgs.CreateTriggerSkill {
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
    can_trigger = rinsan.targetTrigger,
}

JieLiru:addSkill(LuaJuece)
JieLiru:addSkill(LuaMieji)
JieLiru:addSkill(LuaFencheng)

JieManchong = sgs.General(extension, 'JieManchong', 'wei', '3', true)

LuaJunxingCard = sgs.CreateSkillCard {
    name = 'LuaJunxing',
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local target = targets[1]
        local len = self:subcardsLength()
        if room:askForDiscard(target, self:objectName(), len, len, true, true, '@LuaJunxing:::' .. len) then
            room:loseHp(target)
        else
            target:turnOver()
            target:drawCards(len, self:objectName())
        end
    end,
}

LuaJunxing = sgs.CreateViewAsSkill {
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
        return not player:hasUsed('#LuaJunxing') and not player:isKongcheng()
    end,
}

LuaYuce = sgs.CreateTriggerSkill {
    name = 'LuaYuce',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:isKongcheng() then
            return false
        end
        local card = room:askForCard(player, '.', '@LuaYuce-show', data, sgs.Card_MethodNone)
        if card then
            rinsan.skill(self, room, player, true)
            room:showCard(player, card:getEffectiveId())
            if damage.from == nil or damage.from:isDead() then
                return false
            end
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
            local typeName = {'BasicCard', 'TrickCard', 'EquipCard'}
            local toRemove = rinsan.firstToUpper(rinsan.replaceUnderline(card:getType())) .. 'Card'
            table.removeOne(typeName, toRemove)
            if not rinsan.canDiscard(damage.from, damage.from, 'h') or
                not room:askForCard(damage.from, table.concat(typeName, ',') .. '|.|.|hand', '@yuce-discard:' ..
                    player:objectName() .. '::' .. typeName[1] .. ':' .. typeName[2], data) then
                room:getThread():delay(1500)
                rinsan.recover(player, 1, player)
            end
        end
        return false
    end,
}

JieManchong:addSkill(LuaJunxing)
JieManchong:addSkill(LuaYuce)

JieLiaohua = sgs.General(extension, 'JieLiaohua', 'shu', '4', true)

LuaDangxian = sgs.CreateTriggerSkill {
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
                room:broadcastSkillInvoke(self:objectName(), rinsan.random(1, 2))
            end
            rinsan.sendLogMessage(room, '#LuaDangxianExtraPhase', {
                ['from'] = player,
            })
            player:setPhase(sgs.Player_Play)
            local card = rinsan.getCardFromDiscardPile(room, 'Slash')
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
    end,
}

LuaFuli = sgs.CreateTriggerSkill {
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
            local value = math.min(rinsan.getKingdomCount(room), player:getMaxHp()) - player:getHp()
            rinsan.recover(player, value)
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
        return rinsan.RIGHT(self, target) and target:getMark('@laoji') > 0
    end,
}

JieLiaohua:addSkill(LuaDangxian)
JieLiaohua:addSkill(LuaFuli)

JieZhuran = sgs.General(extension, 'JieZhuran', 'wu', '4', true)

LuaDanshou = sgs.CreateTriggerSkill {
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
            if use.from:objectName() ~= room:getCurrent():objectName() then
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
                                rinsan.skill(self, room, sp, true)
                                room:doAnimate(rinsan.ANIMATE_INDICATE, sp:objectName(), player:objectName())
                                rinsan.doDamage(sp, player, 1)
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
    can_trigger = rinsan.targetTrigger,
}

JieZhuran:addSkill(LuaDanshou)

JieYujin = sgs.General(extension, 'JieYujin', 'wei', '4', true)

LuaJieyueCard = sgs.CreateSkillCard {
    name = 'LuaJieyueCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        target:obtainCard(card, false)
        room:broadcastSkillInvoke('LuaJieyue')
        room:notifySkillInvoked(source, 'LuaJieyue')
        local data = sgs.QVariant()
        data:setValue(source)
        local choice = room:askForChoice(target, 'LuaJieyue', 'luajieyuediscard+luajieyuedraw', data)
        if choice == 'luajieyuediscard' then
            local hand_card_id
            local equip_card_id
            if rinsan.canDiscard(target, target, 'h') then
                hand_card_id = room:askForCardChosen(target, target, 'h', 'LuaJieyue', false, sgs.Card_MethodNone)
            end
            if rinsan.canDiscard(target, target, 'e') then
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
            room:doAnimate(rinsan.ANIMATE_INDICATE, target:objectName(), source:objectName())
            source:drawCards(3, 'LuaJieyue')
        end
    end,
}

LuaJieyueVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaJieyue = sgs.CreateTriggerSkill {
    name = 'LuaJieyue',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaJieyueVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if not player:isNude() then
                room:askForUseCard(player, '@@LuaJieyue', '@LuaJieyue')
            end
        end
    end,
}

JieYujin:addSkill(LuaJieyue)

JieSunce = sgs.General(extension, 'JieSunce$', 'wu', '4', true)

LuaJiang = sgs.CreateTriggerSkill {
    name = 'LuaJiang',
    events = {sgs.TargetConfirmed, sgs.TargetSpecified},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, sunce, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(sunce)) then
            if use.card:isKindOf('Duel') or (use.card:isKindOf('Slash') and use.card:isRed()) then
                if sunce:askForSkillInvoke(self:objectName(), data) then
                    sunce:drawCards(1, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
        end
        return false
    end,
}

LuaYingzi = sgs.CreateTriggerSkill {
    name = 'LuaYingzi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local count = data:toInt() + 1
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, 'drawed')
            data:setValue(count)
        end
    end,
}

LuaYingziMaxCard = sgs.CreateMaxCardsSkill {
    name = '#LuaYingzi',
    fixed_func = function(self, target)
        if target:hasSkill('LuaYingzi') then
            return target:getMaxHp()
        else
            return -1
        end
    end,
}

LuaYinghunCard = sgs.CreateSkillCard {
    name = 'LuaYinghunCard',
    target_fixed = false,
    will_throw = true,
    on_effect = function(self, effect)
        local source = effect.from
        local dest = effect.to
        local x = source:getLostHp()
        local room = source:getRoom()
        local good = false
        local index = source:hasSkill('LuaMouHunzi') and rinsan.random(3, 4) or rinsan.random(1, 2)
        if x > 1 then
            local data = sgs.QVariant()
            data:setValue(dest)
            local choice = room:askForChoice(source, 'LuaYinghun', 'd1tx+dxt1', data)
            if choice == 'd1tx' then
                room:broadcastSkillInvoke('LuaYinghun', index)
                dest:drawCards(1, 'LuaYinghun')
                x = math.min(x, dest:getCardCount(true))
                room:askForDiscard(dest, self:objectName(), x, x, false, true)
                good = false
            elseif choice == 'dxt1' then
                room:broadcastSkillInvoke('LuaYinghun', index)
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
            room:broadcastSkillInvoke('LuaYinghun', index)
            dest:drawCards(1, 'LuaYinghun')
            room:askForDiscard(dest, self:objectName(), 1, 1, false, true)
            room:setEmotion(dest, 'good')
        end
    end,
}

LuaYinghunVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaYinghun = sgs.CreateTriggerSkill {
    name = 'LuaYinghun',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaYinghunVS,
    on_trigger = function(self, event, player, data, room)
        room:askForUseCard(player, '@@LuaYinghun', '@yinghun')
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Start) and target:isWounded()
    end,
}

LuaHunzi = sgs.CreateTriggerSkill {
    name = 'LuaHunzi',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, 'LuaHunzi')
        rinsan.sendLogMessage(room, '#LuaHunzi', {
            ['from'] = player,
            ['arg'] = player:getHp(),
            ['arg2'] = self:objectName(),
        })
        if room:changeMaxHpForAwakenSkill(player) then
            room:broadcastSkillInvoke(self:objectName())
            room:getThread():delay(6500)
            rinsan.recover(player, 1, player)
            room:setEmotion(player, 'skill/hunzi')
            room:handleAcquireDetachSkills(player, 'LuaYingzi|LuaYinghun')
            room:addPlayerMark(player, 'hunzi')
        end
        return false
    end,
    can_trigger = function(self, target)
        if not rinsan.RIGHT(self, target) then
            return false
        end
        return rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Start) and (target:getHp() <= 2)
    end,
}

JieSunce:addSkill(LuaJiang)
JieSunce:addSkill(LuaHunzi)
JieSunce:addSkill('zhiba')
JieSunce:addRelateSkill('LuaYingzi')
JieSunce:addRelateSkill('LuaYinghun')
table.insert(hiddenSkills, LuaYingzi)
table.insert(hiddenSkills, LuaYinghun)
table.insert(hiddenSkills, LuaYingziMaxCard)

ExGongsunkang = sgs.General(extension, 'ExGongsunkang', 'qun', '4', true)

LuaJuliao = sgs.CreateDistanceSkill {
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
    end,
}

-- 讨灭用，from 从 card_source 区域中获得一张牌，然后选择一名除 card_source 之外的角色获得
local function obtainOneCardAndGiveToOtherPlayer(self, from, card_source)
    local room = from:getRoom()
    local card_id = room:askForCardChosen(from, card_source, 'hej', self:objectName())
    from:obtainCard(sgs.Sanguosha:getCard(card_id), false)
    local targets = room:getOtherPlayers(card_source)
    if targets:contains(from) then
        targets:removeOne(from)
    end
    local togive = room:askForPlayerChosen(from, targets, self:objectName(),
        '@LuaTaomie-give:' .. card_source:objectName(), true, true)
    if togive then
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, from:objectName(), togive:objectName(),
            self:objectName(), nil)
        room:moveCardTo(sgs.Sanguosha:getCard(card_id), from, togive, sgs.Player_PlaceHand, reason, false)
    end
end

LuaTaomie = sgs.CreateTriggerSkill {
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
                if damage.to:getMark('@' .. self:objectName()) == 0 and
                    room:askForSkillInvoke(player, self:objectName(), data2) then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:setPlayerMark(p, '@' .. self:objectName(), 0)
                    end
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
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
                if damage.from:getMark('@' .. self:objectName()) == 0 and
                    room:askForSkillInvoke(player, self:objectName(), data2) then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:setPlayerMark(p, '@' .. self:objectName(), 0)
                    end
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
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
                    room:broadcastSkillInvoke(self:objectName(), rinsan.random(2, 3))
                end
                if choice == 'addDamage' then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    damage.damage = damage.damage + 1
                elseif choice == 'getOneCard' then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    if not damage.to:isAllNude() then
                        obtainOneCardAndGiveToOtherPlayer(self, player, damage.to)
                    end
                elseif choice == 'removeMark' then
                    damage.damage = damage.damage + 1
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
                    if not damage.to:isAllNude() then
                        obtainOneCardAndGiveToOtherPlayer(self, player, damage.to)
                    end
                    room:addPlayerMark(player, self:objectName() .. 'Delay')
                end
                data:setValue(damage)
            end
        end
        return false
    end,
}

LuaTaomieMark = sgs.CreateTriggerSkill {
    name = 'LuaTaomieMark',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        local markFunction = rinsan.removeFromAttackRange
        if mark.who:getMark('@LuaTaomie') > 0 then
            markFunction = rinsan.addToAttackRange
        end
        if mark.name == '@LuaTaomie' then
            local gongsunkangs = room:findPlayersBySkillName('LuaTaomie')
            for _, gongsunkang in sgs.qlist(gongsunkangs) do
                if gongsunkang:objectName() ~= mark.who:objectName() then
                    markFunction(gongsunkang, mark.who)
                    markFunction(mark.who, gongsunkang)
                end
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

ExGongsunkang:addSkill(LuaJuliao)
ExGongsunkang:addSkill(LuaTaomie)
table.insert(hiddenSkills, LuaTaomieMark)

ExZhangji = sgs.General(extension, 'ExZhangji', 'qun', '4', true)

LuaLvemingCard = sgs.CreateSkillCard {
    name = 'LuaLvemingCard',
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:getEquips():length() < sgs.Self:getEquips():length()
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaLveming')
        local target = targets[1]
        local numbers = {}
        for i = 1, 13 do
            table.insert(numbers, tostring(i))
        end
        room:broadcastSkillInvoke('LuaLveming')
        local chosenNum = room:askForChoice(target, 'LuaLveming', table.concat(numbers, '+'))

        rinsan.sendLogMessage(room, '#choose', {
            ['from'] = target,
            ['arg'] = chosenNum,
        })

        local judge = rinsan.createJudgeStruct({
            ['play_animation'] = true,
            ['who'] = source,
            ['reason'] = 'LuaLveming',
        })
        room:judge(judge)
        if judge.card:getNumber() == tonumber(chosenNum) then
            rinsan.doDamage(source, target, 2)
        else
            local cards = target:getCards('hej')
            if not cards:isEmpty() then
                local card = cards:at(rinsan.random(0, cards:length() - 1))
                if card then
                    room:obtainCard(source, card, false)
                end
            end
        end
        room:addPlayerMark(source, 'LuaLveming')
    end,
}

LuaLveming = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaLveming',
    view_as = function(self, cards)
        return LuaLvemingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaLvemingCard')
    end,
}

LuaTunjunCard = sgs.CreateSkillCard {
    name = 'LuaTunjunCard',
    filter = function(self, selected, to_select)
        return #selected == 0
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke('LuaTunjun')
        room:notifySkillInvoked(source, 'LuaTunjun')
        source:loseMark('@LuaTunjun')
        local times = source:getMark('LuaLveming')
        local i = 0
        local params = {
            ['type'] = 'EquipCard',
        }
        while i < times do
            i = i + 1
            local equipCard = rinsan.obtainTargetedTypeCard(room, params)
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
    end,
}

LuaTunjunVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaTunjun',
    view_as = function(self, cards)
        return LuaTunjunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaTunjun') > 0 and player:getMark('LuaLveming') > 0
    end,
}

LuaTunjun = sgs.CreateTriggerSkill {
    name = 'LuaTunjun',
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaTunjun',
    view_as_skill = LuaTunjunVS,
    on_trigger = function()
    end,
}

ExZhangji:addSkill(LuaLveming)
ExZhangji:addSkill(LuaTunjun)

JieZhonghui = sgs.General(extension, 'JieZhonghui', 'wei', '4', true)

-- 权计摸牌放牌
local function doQuanji(skillName, player, room, times)
    times = times or 1
    local index = 0
    while index < times do
        if player:askForSkillInvoke(skillName) then
            room:drawCards(player, 1, skillName)
            room:broadcastSkillInvoke(skillName)
            if not player:isKongcheng() then
                local card_id
                if player:getHandcardNum() == 1 then
                    card_id = player:handCards():first()
                    room:getThread():delay()
                else
                    card_id = room:askForExchange(player, skillName, 1, 1, false, 'QuanjiPush'):getSubcards():first()
                end
                player:addToPile('power', card_id)
            end
        else
            break
        end
        index = index + 1
    end
end

LuaQuanji = sgs.CreateTriggerSkill {
    name = 'LuaQuanji',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play then
                if player:getHp() < player:getHandcardNum() then
                    doQuanji(self:objectName(), player, room)
                end
            end
        else
            doQuanji(self:objectName(), player, room, data:toDamage().damage)
        end
    end,
}

LuaQuanjiKeep = sgs.CreateMaxCardsSkill {
    name = '#LuaQuanji-keep',
    extra_func = function(self, target)
        if target:hasSkill('LuaQuanji') then
            return target:getPile('power'):length()
        else
            return 0
        end
    end,
}

LuaZili = sgs.CreateTriggerSkill {
    name = 'LuaZili',
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        rinsan.sendLogMessage(room, '#LuaZili', {
            ['from'] = player,
            ['arg'] = player:getPile('power'):length(),
        })
        if room:changeMaxHpForAwakenSkill(player) then
            room:broadcastSkillInvoke(self:objectName())
            if player:isWounded() and room:askForChoice(player, self:objectName(), 'zilirecover+zilidraw') ==
                'zilirecover' then
                rinsan.recover(player, 1, player)
            else
                room:drawCards(player, 2, self:objectName())
            end
            room:addPlayerMark(player, self:objectName())
            room:acquireSkill(player, 'LuaPaiyi')
        end
    end,
    can_trigger = function(self, target)
        if rinsan.RIGHT(self, target) and rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Start) then
            return target:getPile('power'):length() >= 3
        end
        return false
    end,
}

LuaPaiyiCard = sgs.CreateSkillCard {
    name = 'LuaPaiyiCard',
    filter = function(self, selected, to_select)
        return #selected == 0 and not to_select:hasFlag('LuaPaiyiUsedFlag')
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        room:broadcastSkillInvoke('LuaPaiyi')
        room:drawCards(target, 2, 'LuaPaiyi')
        room:setPlayerFlag(target, 'LuaPaiyiUsedFlag')
        if target:getHandcardNum() > source:getHandcardNum() then
            rinsan.doDamage(source, target, 1)
        end
    end,
}

LuaPaiyi = sgs.CreateOneCardViewAsSkill {
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
    end,
}

JieZhonghui:addSkill(LuaQuanji)
JieZhonghui:addSkill(LuaZili)
JieZhonghui:addRelateSkill('LuaPaiyi')
table.insert(hiddenSkills, LuaQuanjiKeep)
table.insert(hiddenSkills, LuaPaiyi)

ExStarXuhuang = sgs.General(extension, 'ExStarXuhuang', 'qun', '4', true)

LuaZhiyanDrawCard = sgs.CreateSkillCard {
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
        room:notifySkillInvoked(source, 'LuaZhiyan')
        local x = source:getMaxHp() - source:getHandcardNum()
        source:drawCards(x, 'LuaZhiyan')
    end,
}

LuaZhiyanGiveCard = sgs.CreateSkillCard {
    name = 'LuaZhiyanGiveCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaZhiyan')
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cd)
        end
        local target = targets[1]
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(),
            'LuaZhiyan', nil)
        room:broadcastSkillInvoke('LuaZhiyan')
        -- 不需要可见
        room:moveCardTo(to_goback, source, target, sgs.Player_PlaceHand, reason)
    end,
}

LuaZhiyan = sgs.CreateViewAsSkill {
    name = 'LuaZhiyan',
    n = 999,
    view_filter = function(self, selected, to_select)
        local y = sgs.Self:getHandcardNum() - sgs.Self:getHp()
        return y > 0 and #selected < y and (not to_select:isEquipped())
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
        local LuaZhiyanDrawAvailable = not player:hasUsed('#LuaZhiyanDrawCard') and player:getMaxHp() >
                                           player:getHandcardNum()
        local LuaZhiyanGiveAvailable = not player:hasUsed('#LuaZhiyanGiveCard') and player:getHandcardNum() >
                                           player:getHp()
        return LuaZhiyanDrawAvailable or LuaZhiyanGiveAvailable
    end,
}

LuaZhiyanMod = sgs.CreateProhibitSkill {
    name = '#LuaZhiyanMod',
    is_prohibited = function(self, from, to, card)
        return
            from:hasSkill('LuaZhiyan') and not card:isKindOf('SkillCard') and from:objectName() ~= to:objectName() and
                from:hasUsed('#LuaZhiyanDrawCard')
    end,
}

ExStarXuhuang:addSkill(LuaZhiyan)
table.insert(hiddenSkills, LuaZhiyanMod)

ExStarGanning = sgs.General(extension, 'ExStarGanning', 'qun', '4', true, true)

LuaJinfanCard = sgs.CreateSkillCard {
    name = 'LuaJinfanCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaJinfan')
        local to_pile = sgs.IntList()
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_pile:append(cd)
        end
        room:broadcastSkillInvoke('LuaJinfan')
        source:addToPile('&luajinfanpile', to_pile, false)
    end,
}

LuaJinfanVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaJinfan = sgs.CreateTriggerSkill {
    name = 'LuaJinfan',
    view_as_skill = LuaJinfanVS,
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
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
            if move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceSpecial) then
                for index, card_id in sgs.qlist(move.card_ids) do
                    -- from_pile_names 为 Table，故 index 需要加一
                    if move.from_pile_names[index + 1] == '&luajinfanpile' then
                        local curr_card = sgs.Sanguosha:getCard(card_id)
                        local togain = rinsan.obtainSpecifiedCard(room, function(check)
                            return check:getSuit() == curr_card:getSuit()
                        end)
                        if togain then
                            room:notifySkillInvoked(player, self:objectName())
                            room:broadcastSkillInvoke(self:objectName())
                            player:obtainCard(togain, false)
                        end
                    end
                end
            end
        end
        return false
    end,
}

LuaSheque = sgs.CreateTriggerSkill {
    name = 'LuaSheque',
    events = {sgs.EventPhaseStart, sgs.TargetSpecified},
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
                room:notifySkillInvoked(player, self:objectName())
                for _, p in sgs.qlist(use.to) do
                    rinsan.addQinggangTag(p, use.card)
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

ExStarGanning:addSkill(LuaJinfan)
ExStarGanning:addSkill(LuaSheque)

JieCaozhi = sgs.General(extension, 'JieCaozhi', 'wei', '3', true)

LuaLuoying = sgs.CreateTriggerSkill {
    name = 'LuaLuoying',
    frequency = sgs.Skill_Frequent,
    events = {sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from == nil or move.from:objectName() == player:objectName() then
            return false
        end
        if (move.to_place == sgs.Player_DiscardPile) and
            rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) or
            (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE) then
            local card_ids = sgs.IntList()
            for index, card_id in sgs.qlist(move.card_ids) do
                if (sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club) and
                    (((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE) and
                        (move.from_places:at(index) == sgs.Player_PlaceJudge) and
                        (move.to_place == sgs.Player_DiscardPile)) or
                        ((move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE) and
                            (room:getCardOwner(card_id):objectName() == move.from:objectName()) and
                            ((move.from_places:at(index) == sgs.Player_PlaceHand) or
                                (move.from_places:at(index) == sgs.Player_PlaceEquip)))) then
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
    end,
}

LuaJiushiVS = sgs.CreateZeroCardViewAsSkill {
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
    end,
}

LuaJiushi = sgs.CreateTriggerSkill {
    name = 'LuaJiushi',
    events = {sgs.PreCardUsed, sgs.Damaged, sgs.MarkChanged, sgs.TurnedOver, sgs.PreDamageDone},
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
        elseif event == sgs.Damaged then
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
                local togain = rinsan.obtainTargetedTypeCard(room, {
                    ['type'] = 'TrickCard',
                    ['findDiscardPile'] = true,
                })
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
    end,
}

LuaChengzhang = sgs.CreateTriggerSkill {
    name = 'LuaChengzhang',
    frequency = sgs.Skill_Wake,
    events = {sgs.Damaged, sgs.Damage, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged or event == sgs.Damage then
            room:addPlayerMark(player, '@' .. self:objectName() .. 'damage', data:toDamage().damage)
        else
            if player:getPhase() == sgs.Player_Start and player:getMark('@' .. self:objectName() .. 'damage') >= 7 then
                rinsan.sendLogMessage(room, '#LuaChengzhang', {
                    ['from'] = player,
                    ['arg'] = player:getMark('@' .. self:objectName() .. 'damage'),
                    ['arg2'] = self:objectName(),
                })
                if room:changeMaxHpForAwakenSkill(player, 0) then
                    rinsan.recover(player)
                    room:setPlayerMark(player, '@' .. self:objectName() .. 'damage', 0)
                    player:drawCards(1, self:objectName())
                    room:addPlayerMark(player, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getMark(self:objectName()) == 0
    end,
}

JieCaozhi:addSkill(LuaLuoying)
JieCaozhi:addSkill(LuaJiushi)
JieCaozhi:addSkill(LuaChengzhang)

JieChenqun = sgs.General(extension, 'JieChenqun', 'wei', '3', true)

LuaDingpinCard = sgs.CreateSkillCard {
    name = 'LuaDingpinCard',
    filter = function(self, selected, to_select)
        return #selected == 0 and not to_select:hasFlag('LuaDingpinSucceed')
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaDingpin')
        local subcard = sgs.Sanguosha:getCard(self:getSubcards():first())
        local target = targets[1]
        room:broadcastSkillInvoke('LuaDingpin')
        local judge = rinsan.createJudgeStruct({
            ['play_animation'] = true,
            ['reason'] = 'LuaDingpin',
            ['who'] = target,
        })
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
    end,
}

LuaDingpin = sgs.CreateOneCardViewAsSkill {
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
    end,
}

LuaFaen = sgs.CreateTriggerSkill {
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
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), sp:objectName())
                player:drawCards(1, self:objectName())
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

JieChenqun:addSkill(LuaDingpin)
JieChenqun:addSkill(LuaFaen)

JieXunyu = sgs.General(extension, 'JieXunyu', 'wei', '3', true, true)

LuaQuhuCard = sgs.CreateSkillCard {
    name = 'LuaQuhuCard',
    filter = function(self, selected, to_select)
        -- 使用 canPindian 进行判断
        return #selected == 0 and to_select:getHp() > sgs.Self:getHp() and sgs.Self:canPindian(to_select, 'LuaQuhu')
    end,
    on_use = function(self, room, source, targets)
        -- 驱虎吞狼，被驱的自然是 tiger
        local tiger = targets[1]
        room:broadcastSkillInvoke('LuaQuhu')
        room:notifySkillInvoked(source, 'LuaQuhu')
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
            rinsan.doDamage(tiger, wolf, 1)
        else
            rinsan.doDamage(tiger, source, 1)
        end
    end,
}

LuaQuhu = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaQuhu',
    view_as = function(self)
        return LuaQuhuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaQuhuCard') and not player:isKongcheng()
    end,
}

LuaJieming = sgs.CreateTriggerSkill {
    name = 'LuaJieming',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local i = 0
        while i < damage.damage do
            i = i + 1
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 'jieming-invoke',
                true, true)
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
    end,
}

JieXunyu:addSkill(LuaQuhu)
JieXunyu:addSkill(LuaJieming)

ExSufei = sgs.General(extension, 'ExSufei', 'qun', '4', true, true)

LuaZhengjian = sgs.CreateTriggerSkill {
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
                            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), p:objectName())
                            p:drawCards(x, self:objectName())
                        end
                        room:setPlayerMark(p, 'LuaZhengjianCard' .. player:objectName(), 0)
                        room:setPlayerMark(p, self:objectName() .. player:objectName(), 0)
                    end
                end
            elseif player:getPhase() == sgs.Player_Finish then
                if player:hasSkill(self:objectName()) then
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                        '@LuaZhengjian-choose', false, true)
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
    can_trigger = rinsan.targetTrigger,
}

LuaGaoyuan = sgs.CreateTriggerSkill {
    name = 'LuaGaoyuan',
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and use.to:contains(player) and
            rinsan.canDiscard(player, player, 'he') then
            if use.from:getMark('LuaZhengjian' .. player:objectName()) == 0 and
                player:getMark('LuaZhengjian' .. player:objectName()) == 0 then
                local target
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark('LuaZhengjian' .. player:objectName()) > 0 then
                        target = p
                        break
                    end
                end
                if target and not use.to:contains(target) and
                    room:askForCard(player, '.|.|.|.', '@LuaGaoyuan:' .. target:objectName(), data,
                        sgs.Card_MethodDiscard, target, false, self:objectName()) then
                    room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
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
    end,
}

ExSufei:addSkill(LuaZhengjian)
ExSufei:addSkill(LuaGaoyuan)

ExShenZhaoyun = sgs.General(extension, 'ExShenZhaoyun', 'god', '2', true, true)

LuaJuejing = sgs.CreateTriggerSkill {
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
    end,
}

LuaJuejingMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaJuejing',
    extra_func = function(self, target)
        if target:hasSkill('LuaJuejing') then
            return 2
        else
            return 0
        end
    end,
}

LuaLonghunVS = sgs.CreateViewAsSkill {
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
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
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
                   (string.find(pattern, 'peach') and player:getMark('Global_PreventPeach') == 0) or pattern ==
                   'nullification'
    end,
    enabled_at_nullification = function(self, player)
        for _, cd in sgs.qlist(player:getCards('he')) do
            if cd:getSuit() == sgs.Card_Spade then
                return true
            end
        end
        return false
    end,
}

LuaLonghun = sgs.CreateTriggerSkill {
    name = 'LuaLonghun',
    view_as_skill = LuaLonghunVS,
    events = {sgs.DamageCaused, sgs.PreHpRecover, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() and damage.card:subcardsLength() > 1 then
                rinsan.sendLogMessage(room, '#LuaLonghunAddDamage', {
                    ['from'] = player,
                    ['arg'] = damage.damage,
                    ['arg2'] = damage.damage + 1,
                })
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
            if use.card and use.card:isBlack() and use.card:getSkillName() == self:objectName() and
                use.card:subcardsLength() > 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                if rinsan.canDiscard(player, room:getCurrent(), 'he') then
                    room:throwCard(room:askForCardChosen(player, room:getCurrent(), 'he', self:objectName(), false,
                        sgs.Card_MethodDiscard), room:getCurrent(), player)
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

ExShenZhaoyun:addSkill(LuaJuejing)
ExShenZhaoyun:addSkill(LuaLonghun)
table.insert(hiddenSkills, LuaJuejingMaxCards)

ExZhuling = sgs.General(extension, 'ExZhuling', 'wei', '4', true, true)

LuaZhanyiCard = sgs.CreateSkillCard {
    name = 'LuaZhanyiCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        -- 首先失去一点体力
        room:broadcastSkillInvoke('LuaZhanyi')
        room:loseHp(source)
        room:setPlayerFlag(source, 'LuaZhanyiUsed')
        room:notifySkillInvoked(source, 'LuaZhanyi')

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
    end,
}

LuaZhanyiBasicCard = sgs.CreateSkillCard {
    name = 'LuaZhanyiBasicCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return rinsan.guhuoCardFilter(self, targets, to_select, 'LuaZhanyi')
    end,
    feasible = function(self, targets)
        return rinsan.selfFeasible(self, targets, 'LuaZhanyi')
    end,
    on_validate = function(self, card_use)
        return rinsan.guhuoCardOnValidate(self, card_use, 'LuaZhanyi', 'zhanyi', 'Zhanyi')
    end,
    on_validate_in_response = function(self, source)
        return rinsan.guhuoCardOnValidateInResponse(self, source, 'LuaZhanyi', 'zhanyi', 'Zhanyi')
    end,
}

LuaZhanyiVS = sgs.CreateOneCardViewAsSkill {
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
        return rinsan.guhuoVSSkillEnabledAtResponse(self, player, pattern)
    end,
    enabled_at_play = function(self, player)
        if player:hasFlag('LuaZhanyiUsed') and (not player:hasFlag('LuaZhanyiBasicCard')) then
            return false
        end
        return (player:isWounded() or sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player))
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
            if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
                local card = LuaZhanyiBasicCard:clone()
                local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
                card:setUserString(pattern)
                card:addSubcard(orginalCard)
                local available = false
                for _, name in ipairs(pattern:split('+')) do
                    local c = sgs.Sanguosha:cloneCard(name, orginalCard:getSuit(), orginalCard:getNumber())
                    c:deleteLater()
                    if not sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                        available = true
                        break
                    end
                end
                if not available then
                    return nil
                end
                return card
            end
            local c = sgs.Self:getTag('LuaZhanyi'):toCard()
            if c then
                local card = LuaZhanyiBasicCard:clone()
                card:setUserString(c:objectName())
                card:addSubcard(orginalCard)
                if sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                    return nil
                end
                return card
            else
                return nil
            end
        end
        return nil
    end,
}

LuaZhanyi = sgs.CreateTriggerSkill {
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
    end,
}

LuaZhanyi:setGuhuoDialog('l')

ExZhuling:addSkill(LuaZhanyi)

ExGuozhao = sgs.General(extension, 'ExGuozhao', 'wei', '3', false, true)

LuaPianchong = sgs.CreateTriggerSkill {
    name = 'LuaPianchong',
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Draw then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    local redCard = rinsan.obtainSpecifiedCard(room, rinsan.isRedCard)
                    local blackCard = rinsan.obtainSpecifiedCard(room, rinsan.isBlackCard)
                    if redCard then
                        player:obtainCard(redCard, false)
                    end
                    if blackCard then
                        player:obtainCard(blackCard, false)
                    end
                    local choice = room:askForChoice(player, self:objectName(),
                        'LuaPianchongChoice1+LuaPianchongChoice2')
                    rinsan.sendLogMessage(room, '#choose', {
                        ['from'] = player,
                        ['arg'] = choice,
                    })
                    if choice == 'LuaPianchongChoice1' then
                        -- 失去红牌摸黑牌
                        room:setPlayerMark(player, self:objectName(), 1)
                    elseif choice == 'LuaPianchongChoice2' then
                        -- 失去黑牌摸红牌
                        room:setPlayerMark(player, self:objectName(), 2)
                    end
                    return true
                end
            end
        elseif event == sgs.TurnStart then
            room:setPlayerMark(player, self:objectName(), 0)
        else
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) and player:getMark(self:objectName()) > 0 then
                if rinsan.lostCard(move, player) then
                    -- 判断卡牌颜色和要获得的卡牌颜色
                    if player:getMark(self:objectName()) > 2 then
                        return false
                    end
                    local cardColorCheck = rinsan.isRedCard
                    local obtainCardColorCheck = rinsan.isBlackCard
                    if player:getMark(self:objectName()) == 2 then
                        cardColorCheck = rinsan.isBlackCard
                        obtainCardColorCheck = rinsan.isRedCard
                    end
                    local broadcasted = false
                    for _, id in sgs.qlist(move.card_ids) do
                        local move_card = sgs.Sanguosha:getCard(id)
                        if cardColorCheck(move_card) then
                            local obtainCard = rinsan.obtainSpecifiedCard(room, obtainCardColorCheck)
                            if obtainCard then
                                if not broadcasted then
                                    broadcasted = true
                                    room:broadcastSkillInvoke(self:objectName())
                                    room:sendCompulsoryTriggerLog(player, self:objectName())
                                end
                                player:obtainCard(obtainCard, false)
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaZunweiCard = sgs.CreateSkillCard {
    name = 'LuaZunweiCard',
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) then
            -- 分别代表三个选项是否可用

            -- 选项一：摸牌至与对应角色相同
            -- 判断依据：未选中过此选项且手牌数小于对方
            local choice1_available = sgs.Self:getMark('LuaZunweiChoice1') == 0 and to_select:getHandcardNum() >
                                          sgs.Self:getHandcardNum()

            -- 选项二：随机使用装备牌至与对应角色相同
            -- 判断依据：未选中过此选项且装备数数小于对方
            local choice2_available = sgs.Self:getMark('LuaZunweiChoice2') == 0 and to_select:getEquips():length() >
                                          sgs.Self:getEquips():length()

            -- 选项三：回复体力至与对应角色相同
            -- 判断依据：未选中过此选项且体力值小于对方体力值与自身最大体力值
            local choice3_available = sgs.Self:getMark('LuaZunweiChoice3') == 0 and
                                          math.min(to_select:getHp(), sgs.Self:getMaxHp()) > sgs.Self:getHp()

            -- 需要满足这三个条件之一，方可被选中
            return choice1_available or choice2_available or choice3_available
        end
        return false
    end,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaZunwei')
        local target = targets[1]
        local choices = {}

        -- 三个选项是否可用

        -- 手牌选项是否满足
        local choice1_available = source:getMark('LuaZunweiChoice1') == 0 and target:getHandcardNum() >
                                      source:getHandcardNum()
        -- 如果满足，添加到备选
        if choice1_available then
            table.insert(choices, 'LuaZunweiChoice1')
        end

        -- 装备选项是否满足
        local choice2_available = source:getMark('LuaZunweiChoice2') == 0 and target:getEquips():length() >
                                      source:getEquips():length()
        -- 如果满足，添加到备选
        if choice2_available then
            table.insert(choices, 'LuaZunweiChoice2')
        end

        -- 体力选项是否满足
        local choice3_available = source:getMark('LuaZunweiChoice3') == 0 and
                                      math.min(target:getHp(), source:getMaxHp()) > source:getHp()
        -- 如果满足，添加到备选
        if choice3_available then
            table.insert(choices, 'LuaZunweiChoice3')
        end

        -- 如果至少有一个可选项，则可以执行下列流程
        if #choices > 0 then
            room:broadcastSkillInvoke('LuaZunwei')
            local choice = room:askForChoice(source, 'LuaZunwei', table.concat(choices, '+'))
            room:addPlayerMark(source, choice)
            if choice == 'LuaZunweiChoice1' then
                -- 摸牌
                local x = math.min(target:getHandcardNum() - source:getHandcardNum(), 5)
                if x > 0 then
                    source:drawCards(x, 'LuaZunwei')
                end
            elseif choice == 'LuaZunweiChoice2' then
                -- 用装备
                local equip = rinsan.obtainTargetedTypeCard(room, {
                    ['type'] = 'EquipCard',
                })
                while equip and source:getEquips():length() < target:getEquips():length() do
                    room:useCard(sgs.CardUseStruct(equip, source, source))
                    equip = rinsan.obtainTargetedTypeCard(room, {
                        ['type'] = 'EquipCard',
                    })
                end
            elseif choice == 'LuaZunweiChoice3' then
                -- 回复体力
                local x = target:getHp() - source:getHp()
                if x > 0 then
                    rinsan.recover(source, x)
                end
            end
        end
    end,
}

LuaZunwei = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaZunwei',
    view_as = function(self)
        return LuaZunweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        local choicesAvailable = player:getMark('LuaZunweiChoice1') == 0 or player:getMark('LuaZunweiChoice2') == 0 or
                                     player:getMark('LuaZunweiChoice3') == 0
        return choicesAvailable and not player:hasUsed('#LuaZunweiCard')
    end,
}

ExGuozhao:addSkill(LuaPianchong)
ExGuozhao:addSkill(LuaZunwei)

JieDengai = sgs.General(extension, 'JieDengai', 'wei', '4', true)

LuaTuntian = sgs.CreateTriggerSkill {
    name = 'LuaTuntian',
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime, sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local triggerable
            if rinsan.lostCard(move, player) then
                if player:getPhase() == sgs.Player_NotActive then
                    triggerable = true
                end
                if (not triggerable) and
                    (rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD)) then
                    for _, id in sgs.qlist(move.card_ids) do
                        local curr_card = sgs.Sanguosha:getCard(id)
                        if curr_card:isKindOf('Slash') then
                            triggerable = true
                            break
                        end
                    end
                end
                if triggerable and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    local judge = rinsan.createJudgeStruct({
                        ['who'] = player,
                        ['good'] = false,
                        ['pattern'] = '.|heart',
                        ['reason'] = self:objectName(),
                        ['play_animation'] = true,
                    })
                    room:judge(judge)
                end
            end
        else
            local judge = data:toJudge()
            if judge.reason == self:objectName() and room:getCardPlace(judge.card:getEffectiveId()) ==
                sgs.Player_PlaceJudge then
                if judge:isGood() then
                    player:addToPile('field', judge.card:getEffectiveId())
                else
                    player:obtainCard(judge.card)
                end
            end
        end
        return false
    end,
}

LuaTuntianDistance = sgs.CreateDistanceSkill {
    name = '#LuaTuntianDistance',
    correct_func = function(self, from, to)
        if from:hasSkill('LuaTuntian') then
            return -from:getPile('field'):length()
        else
            return 0
        end
    end,
}

LuaZaoxian = sgs.CreateTriggerSkill {
    name = 'LuaZaoxian',
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if rinsan.canWakeAtPhase(player, self:objectName(), sgs.Player_Start) and
                (player:getPile('field'):length() >= 3) then
                rinsan.sendLogMessage(room, '#ZaoxianWake', {
                    ['from'] = player,
                    ['arg'] = player:getPile('field'):length(),
                    ['arg2'] = self:objectName(),
                })
                if room:changeMaxHpForAwakenSkill(player) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName())
                    room:acquireSkill(player, 'LuaJixi')
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive and player:getMark(self:objectName()) >= 1 and
                player:getMark(self:objectName() .. 'ExtraTurn') == 0 then
                room:addPlayerMark(player, self:objectName() .. 'ExtraTurn')
                room:broadcastSkillInvoke(self:objectName())
                rinsan.sendLogMessage(room, '#LuaZaoxianExtraTurn', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                })
                player:gainAnExtraTurn()
            end
        end
    end,
}

LuaJixi = sgs.CreateOneCardViewAsSkill {
    name = 'LuaJixi',
    filter_pattern = '.|.|.|field',
    expand_pile = 'field',
    view_as = function(self, card)
        local snatch = sgs.Sanguosha:cloneCard('snatch', card:getSuit(), card:getNumber())
        snatch:addSubcard(card)
        snatch:setSkillName(self:objectName())
        return snatch
    end,
    enabled_at_play = function(self, player)
        return not player:getPile('field'):isEmpty()
    end,
}

JieDengai:addSkill(LuaTuntian)
JieDengai:addSkill(LuaZaoxian)
JieDengai:addRelateSkill('LuaJixi')
table.insert(hiddenSkills, LuaTuntianDistance)
table.insert(hiddenSkills, LuaJixi)

JieZhangjiao = sgs.General(extension, 'JieZhangjiao$', 'qun', '3', true, true)

LuaLeiji = sgs.CreateTriggerSkill {
    name = 'LuaLeiji',
    events = {sgs.FinishJudge, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.FinishJudge then
            local judge = data:toJudge()
            if judge.reason == 'baonue' then
                return false
            end
            if judge.who:objectName() == player:objectName() and judge.card:isBlack() then
                -- 默认为黑桃，草花额外提供回血并调整伤害数值
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local damageValue = 2
                if judge.card:getSuit() == sgs.Card_Club then
                    rinsan.recover(player)
                    damageValue = 1
                end
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    '@LuaLeiji-choose-damage:' .. tostring(damageValue), true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    rinsan.doDamage(player, target, damageValue, sgs.DamageStruct_Thunder)
                end
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card then
                if card:isKindOf('Jink') or card:isKindOf('Lightning') then
                    if room:askForSkillInvoke(player, self:objectName()) then
                        room:broadcastSkillInvoke(self:objectName())
                        local judge = rinsan.createJudgeStruct({
                            ['pattern'] = '.|black',
                            ['reason'] = self:objectName(),
                            ['who'] = player,
                            ['play_animation'] = true,
                        })
                        room:judge(judge)
                    end
                end
            end
        end
        return false
    end,
}

LuaGuidao = sgs.CreateTriggerSkill {
    name = 'LuaGuidao',
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if player:hasSkill(self:objectName()) and player:isAlive() then
            local prompt_list = {'@guidao-card', judge.who:objectName(), self:objectName(), judge.reason,
                                 tostring(judge.card:getEffectiveId())}
            local prompt = table.concat(prompt_list, ':')
            local card =
                room:askForCard(player, '.|black|.|.|.', prompt, data, sgs.Card_MethodResponse, judge.who, true)
            if card then
                room:broadcastSkillInvoke(self:objectName())
                room:retrial(card, player, judge, self:objectName(), true)
                if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    player:drawCards(1)
                end
            end
        end
        return false
    end,
}

JieZhangjiao:addSkill(LuaLeiji)
JieZhangjiao:addSkill(LuaGuidao)
JieZhangjiao:addSkill('huangtian')

ExYuantanYuanshang = sgs.General(extension, 'ExYuantanYuanshang', 'qun', '4', true, true)

-- 获取内伐不可使用手牌数
local function getNeifaUnavailableCardCount(player)
    return math.min(rinsan.getUnavailableHandcardCount(player), 5)
end

LuaNeifaCard = sgs.CreateSkillCard {
    name = 'LuaNeifaCard',
    filter = function(self, selected, to_select)
        return #selected < 1 and (not to_select:isAllNude())
    end,
    feasible = function(self, targets)
        return #targets <= 1
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaNeifa')
        if #targets == 0 then
            source:drawCards(2, 'LuaNeifa')
        else
            local card_id = room:askForCardChosen(source, targets[1], 'hej', 'LuaNeifa', false, sgs.Card_MethodNone)
            source:obtainCard(sgs.Sanguosha:getCard(card_id), false)
        end
        room:broadcastSkillInvoke('LuaNeifa')
        if rinsan.canDiscard(source, source, 'he') then
            local card = room:askForCard(source, '..!', '@LuaNeifa-discard', sgs.QVariant(), sgs.Card_MethodDiscard)
            if card then
                local flag = 'LuaNeifa-NonBasic'
                local limit_prompt = 'BasicCard'
                if card:isKindOf('BasicCard') then
                    flag = 'LuaNeifa-Basic'
                    limit_prompt = 'TrickCard,EquipCard'
                end
                room:setPlayerFlag(source, flag)
                room:setPlayerCardLimitation(source, 'use', limit_prompt .. '|.|.|.', true)
                local x = getNeifaUnavailableCardCount(source)
                room:setPlayerMark(source, '@LuaNeifaCount', x)
            end
        end
    end,
}

LuaNeifaVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaNeifa',
    view_as = function(self, cards)
        return LuaNeifaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaNeifa'
    end,
}

LuaNeifa = sgs.CreateTriggerSkill {
    name = 'LuaNeifa',
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.CardUsed, sgs.TargetConfirmed},
    view_as_skill = LuaNeifaVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                room:askForUseCard(player, '@@LuaNeifa', '@LuaNeifa')
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                room:setPlayerMark(player, '@LuaNeifaCount', 0)
                room:setPlayerMark(player, 'LuaNeifaEquipCount', 0)
            end
        elseif event == sgs.CardUsed then
            if not player:hasFlag('LuaNeifa-NonBasic') then
                return false
            end
            if player:getMark('LuaNeifaEquipCount') > 1 then
                return false
            end
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('EquipCard') then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(player:getMark('@LuaNeifaCount'), self:objectName())
                room:addPlayerMark(player, 'LuaNeifaEquipCount')
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and use.card:isNDTrick() and use.from:hasFlag('LuaNeifa-NonBasic') then
                local players = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if (not room:isProhibited(use.from, p, use.card)) and
                        use.card:targetFilter(sgs.PlayerList(), p, use.from) then
                        players:append(p)
                    end
                end
                for _, p in sgs.qlist(use.to) do
                    if not players:contains(p) then
                        players:append(p)
                    end
                end
                if not players:isEmpty() then
                    local to = room:askForPlayerChosen(use.from, players, self:objectName(),
                        'LuaNeifa-invoke:' .. use.card:objectName(), true, true)
                    if to then
                        local params = {
                            ['to'] = to,
                            ['card_str'] = use.card:toString(),
                        }
                        room:broadcastSkillInvoke(self:objectName())
                        if use.to:contains(to) then
                            use.to:removeOne(to)
                            rinsan.sendLogMessage(room, '#LuaNeifaRemove', params)
                        else
                            use.to:append(to)
                            rinsan.sendLogMessage(room, '#LuaNeifaAppend', params)
                        end
                        room:sortByActionOrder(use.to)
                        data:setValue(use)
                    end
                end
            end
        end
    end,
}

LuaNeifaTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaNeifa',
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:hasFlag('LuaNeifa-Basic') then
            return player:getMark('@LuaNeifaCount')
        end
        return 0
    end,
    extra_target_func = function(self, from)
        if from:hasFlag('LuaNeifa-Basic') then
            return 1
        end
        return 0
    end,
}

ExYuantanYuanshang:addSkill(LuaNeifa)
table.insert(hiddenSkills, LuaNeifaTargetMod)

JieJiaxu = sgs.General(extension, 'JieJiaxu', 'qun', '3', true)

LuaWansha = sgs.CreateTriggerSkill {
    name = 'LuaWansha',
    events = {sgs.Dying},
    frequency = sgs.Skill_Compulsory,
    priority = 10000,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local splayer = room:findPlayerBySkillName(self:objectName())
        if not splayer then
            return false
        end
        local to = dying.who
        -- 死亡事件询问从当前回合角色开始，因此从此开始，以避免技能封锁不够及时
        local current = room:getCurrent()
        if current:objectName() ~= player:objectName() then
            return false
        end
        local victims = sgs.SPlayerList()
        -- 以是否拥有【完杀】进行判断
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:objectName() ~= to:objectName() and not p:hasSkill(self:objectName()) then
                -- 只有当前回合角色拥有完杀时才会封锁桃
                if current:hasSkill(self:objectName()) then
                    -- 现在是以 Mark 而非 Flag 形式标记 Global_PreventPeach
                    room:addPlayerMark(p, 'Global_PreventPeach')
                end
                room:addPlayerMark(p, '@skill_invalidity')
                room:addPlayerMark(p, 'LuaWanshaInvokeTime')
                victims:append(p)
            end
        end
        room:broadcastSkillInvoke(self:objectName())
        room:notifySkillInvoked(splayer, self:objectName())
        if not victims:isEmpty() then
            rinsan.sendLogMessage(room, '#LuaWanshaSkillInvalid', {
                ['from'] = splayer,
                ['tos'] = victims,
                ['arg'] = self:objectName(),
            })
        end
        if current:hasSkill(self:objectName()) then
            local from = current
            -- 为源码所需要
            room:setPlayerFlag(to, 'wansha')
            local type = '#LuaWanshaTwo'
            if from:objectName() == to:objectName() then
                type = '#LuaWanshaOne'
            end
            rinsan.sendLogMessage(room, type, {
                ['from'] = from,
                ['to'] = to,
                ['arg'] = self:objectName(),
            })
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaWanshaClear = sgs.CreateTriggerSkill {
    name = 'LuaWanshaClear',
    global = true,
    events = {sgs.Death, sgs.QuitDying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAllPlayers()) do
            local x = p:getMark('LuaWanshaInvokeTime')
            if x > 0 then
                room:removePlayerMark(p, 'Global_PreventPeach', x)
                room:removePlayerMark(p, '@skill_invalidity', x)
                room:setPlayerMark(p, 'LuaWanshaInvokeTime', 0)
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaLuanwuCard = sgs.CreateSkillCard {
    name = 'LuaLuanwuCard',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaLuanwu')
        room:notifySkillInvoked(source, 'LuaLuanwu')
        room:removePlayerMark(source, '@chaos')
        room:setEmotion(source, 'skill/luanwu')
        local players = room:getOtherPlayers(source)
        for _, p in sgs.qlist(players) do
            room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), p:objectName())
        end
        for _, p in sgs.qlist(players) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
            room:getThread():delay()
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local players = room:getOtherPlayers(effect.to)
        local distance_list = sgs.IntList()
        local nearest = 1000
        for _, player in sgs.qlist(players) do
            local distance = effect.to:distanceTo(player)
            distance_list:append(distance)
            nearest = math.min(nearest, distance)
        end
        local luanwu_targets = sgs.SPlayerList()
        for i = 0, distance_list:length() - 1, 1 do
            if distance_list:at(i) == nearest and effect.to:canSlash(players:at(i), nil, false) then
                luanwu_targets:append(players:at(i))
            end
        end
        if luanwu_targets:length() == 0 or not room:askForUseSlashTo(effect.to, luanwu_targets, '@luanwu-slash') then
            room:loseHp(effect.to)
        end
    end,
}
LuaLuanwuVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaLuanwu',
    view_as = function(self, cards)
        return LuaLuanwuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@chaos') >= 1
    end,
}
LuaLuanwu = sgs.CreateTriggerSkill {
    name = 'LuaLuanwu',
    frequency = sgs.Skill_Limited,
    view_as_skill = LuaLuanwuVS,
    limit_mark = '@chaos',
    on_trigger = function()
    end,
}

LuaJiejiaxuWeimu = sgs.CreateProhibitSkill {
    name = 'LuaJiejiaxuWeimu',
    is_prohibited = function(self, from, to, card)
        return to:hasSkill(self:objectName()) and card:isKindOf('TrickCard') and card:isBlack()
    end,
}

LuaJiejiaxuWeimuDamagePrevent = sgs.CreateTriggerSkill {
    name = 'LuaJiejiaxuWeimuDamagePrevent',
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if room:getCurrent():objectName() == player:objectName() then
            local x = data:toDamage().damage
            rinsan.sendLogMessage(room, '#LuaJiejiaxuWeimu', {
                ['from'] = player,
                ['arg'] = x,
                ['arg2'] = 'LuaJiejiaxuWeimu',
            })
            room:broadcastSkillInvoke('LuaJiejiaxuWeimu')
            room:notifySkillInvoked(player, 'LuaJiejiaxuWeimu')
            return true
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaJiejiaxuWeimu')
    end,
}

JieJiaxu:addSkill(LuaWansha)
JieJiaxu:addSkill(LuaLuanwu)
JieJiaxu:addSkill(LuaJiejiaxuWeimu)
table.insert(hiddenSkills, LuaWanshaClear)
table.insert(hiddenSkills, LuaJiejiaxuWeimuDamagePrevent)

JieXiahoudun = sgs.General(extension, 'JieXiahoudun', 'wei', '4', true, true)

-- 【清俭】存牌
LuaQingjianStoCard = sgs.CreateSkillCard {
    name = 'LuaQingjianStoCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:setPlayerFlag(source, 'LuaQingjianStorage')
        local subs = self:getSubcards()
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
        for _, card_id in sgs.qlist(subs) do
            dummy:addSubcard(card_id)
            room:addPlayerMark(source, 'LuaQingjianCardStorage' .. card_id)
        end
        source:addToPile('LuaQingjian', dummy)
        room:broadcastSkillInvoke('LuaQingjian')
        room:notifySkillInvoked(source, 'LuaQingjian')
    end,
}

-- 【清俭】给牌
LuaQingjianGiveCard = sgs.CreateSkillCard {
    name = 'LuaQingjianGiveCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and not to_select:hasFlag('LuaQingjianGiven')
    end,
    on_use = function(self, room, source, targets)
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cd)
            room:setPlayerMark(source, 'LuaQingjianCardStorage' .. cd, 0)
        end
        local target = targets[1]
        room:setPlayerFlag(target, 'LuaQingjianGiven')
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(),
            'LuaQingjian', nil)
        room:broadcastSkillInvoke('LuaQingjian')
        room:notifySkillInvoked(source, 'LuaQingjian')
        room:moveCardTo(to_goback, source, target, sgs.Player_PlaceHand, reason, true)
        room:addPlayerMark(source, 'LuaQingjianGiveOut', self:subcardsLength())
        if not source:hasFlag('LuaQingjianGiveOutFlag') and source:getMark('LuaQingjianGiveOut') > 1 then
            source:drawCards(1, 'LuaQingjian')
            room:setPlayerFlag(source, 'LuaQingjianGiveOutFlag')
        end
        local needInvokeAgain = (source:getPile('LuaQingjian'):length() > 0)
        if not needInvokeAgain then
            return
        end
        needInvokeAgain = false
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if not p:hasFlag('LuaQingjianGiven') then
                needInvokeAgain = true
            end
        end
        if needInvokeAgain then
            local len = source:getPile('LuaQingjian'):length()
            room:askForUseCard(source, '@@LuaQingjian!', 'LuaQingjian-Give:::' .. len, -1, sgs.Card_MethodNone)
        end
    end,
}

LuaQingjianVS = sgs.CreateViewAsSkill {
    name = 'LuaQingjian',
    n = 999,
    expand_pile = 'LuaQingjian',
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag('LuaQingjianGive') and not sgs.Self:hasFlag('LuaQingjianStoraging') then
            return sgs.Self:getMark('LuaQingjianCardStorage' .. to_select:getEffectiveId()) > 0
        end
        if not to_select:isEquipped() then
            return sgs.Self:getMark('LuaQingjianCardStorage' .. to_select:getEffectiveId()) == 0
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        if sgs.Self:hasFlag('LuaQingjianStoraging') then
            local sto = LuaQingjianStoCard:clone()
            for _, cd in ipairs(cards) do
                sto:addSubcard(cd)
            end
            return sto
        end
        if sgs.Self:hasFlag('LuaQingjianGive') then
            local give = LuaQingjianGiveCard:clone()
            for _, cd in ipairs(cards) do
                give:addSubcard(cd)
            end
            return give
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaQingjian')
    end,
}

LuaQingjian = sgs.CreateTriggerSkill {
    name = 'LuaQingjian',
    events = {sgs.CardsMoveOneTime},
    view_as_skill = LuaQingjianVS,
    on_trigger = function(self, event, player, data, room)
        if room:getTag('FirstRound'):toBool() then
            return false
        end
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
            if player:getPhase() ~= sgs.Player_Draw and not player:hasFlag('LuaQingjianStorage') then
                room:setPlayerFlag(player, 'LuaQingjianStoraging')
                room:askForUseCard(player, '@@LuaQingjian', 'LuaQingjian-Storage', -1, sgs.Card_MethodNone)
                room:setPlayerFlag(player, '-LuaQingjianStoraging')
            end
        end
    end,
}

LuaQingjianClear = sgs.CreateTriggerSkill {
    name = 'LuaQingjianClear',
    events = {sgs.EventPhaseEnd},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getPile('LuaQingjian'):length() > 0 then
                    room:setPlayerFlag(p, 'LuaQingjianGive')
                    local len = p:getPile('LuaQingjian'):length()
                    room:askForUseCard(p, '@@LuaQingjian!', 'LuaQingjian-Give:::' .. len, -1, sgs.Card_MethodNone)
                    room:setPlayerFlag(p, '-LuaQingjianGive')
                end
            end
        elseif player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerFlag(p, '-LuaQingjianGiven')
                room:setPlayerFlag(p, '-LuaQingjianStorage')
                room:setPlayerFlag(p, '-LuaQingjianStoraging')
                room:setPlayerFlag(p, '-LuaQingjianGiveOutFlag')
                room:setPlayerMark(p, 'LuaQingjianGiveOut', 0)
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

JieXiahoudun:addSkill('ganglie')
JieXiahoudun:addSkill(LuaQingjian)
table.insert(hiddenSkills, LuaQingjianClear)

ExSunhanhua = sgs.General(extension, 'ExSunhanhua', 'wu', '3', false, true)

-- 孙寒华系列判断

-- 妙剑等级
local function getMiaojianLevel(sunhanhua)
    return 1 + sunhanhua:getMark('LuaMiaojianLevelUp')
end

-- 莲华等级
local function getLianhuaLevel(sunhanhua)
    return 1 + sunhanhua:getMark('LuaLianhuaLevelUp')
end

-- 更新技能描述
local function sunhanhuaUpdateSkillDesc(sunhanhua)
    local miaojianLevel = getMiaojianLevel(sunhanhua)
    if miaojianLevel > 1 then
        rinsan.modifySkillDescription(':LuaMiaojian', string.format(':LuaMiaojian%d', miaojianLevel))
    end
    local lianhuaLevel = getLianhuaLevel(sunhanhua)
    if lianhuaLevel > 1 then
        rinsan.modifySkillDescription(':LuaLianhua', string.format(':LuaLianhua%d', lianhuaLevel))
    end
    -- 刷新一下，免得技能修正后显示不出来
    ChangeCheck(sunhanhua, sunhanhua:getGeneralName())
end

LuaChongxuCard = sgs.CreateSkillCard {
    name = 'LuaChongxuCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        -- 固定 5 分
        room:broadcastSkillInvoke('LuaChongxu')
        room:notifySkillInvoked(source, 'LuaChongxu')
        local score = 5
        while score > 1 do
            local choices = {}
            if getMiaojianLevel(source) < 3 and score >= 3 then
                table.insert(choices, 'LuaMiaojianLevelUp')
            end
            if getLianhuaLevel(source) < 3 and score >= 3 then
                table.insert(choices, 'LuaLianhuaLevelUp')
            end
            if score >= 2 then
                table.insert(choices, 'LuaChongxuDraw')
            end
            table.insert(choices, 'cancel')
            local choice = room:askForChoice(source, 'LuaChongxu', table.concat(choices, '+'))
            if choice == 'cancel' then
                break
            elseif choice == 'LuaChongxuDraw' then
                score = score - 2
                source:drawCards(1, 'LuaChongxu')
            else
                score = score - 3
                room:addPlayerMark(source, choice)
                sunhanhuaUpdateSkillDesc(source)
            end
        end
    end,
}

LuaChongxu = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaChongxu',
    view_as = function(self, cards)
        return LuaChongxuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaChongxuCard')
    end,
}

LuaMiaojianUseCard = sgs.CreateSkillCard {
    name = 'LuaMiaojian',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
        if not card then
            return false
        end
        local total_num = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, card) + 1
        return sgs.Self:canSlash(to_select, card, false) and #targets < total_num
    end,
    feasible = function(self, targets)
        if #targets > 0 then
            return sgs.Slash_IsAvailable(sgs.Self)
        end
        return true
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaMiaojian')
        local pattern = #targets > 0 and 'slash' or 'ex_nihilo'
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
        card:setSkillName(self:objectName())
        local card_use = sgs.CardUseStruct()
        card_use.card = card
        card_use.from = source
        if #targets > 0 then
            for _, target in ipairs(targets) do
                card_use.to:append(target)
            end
        else
            card_use.to:append(source)
        end
        room:useCard(card_use, true)
    end,
}

LuaMiaojianVS = sgs.CreateViewAsSkill {
    name = 'LuaMiaojian',
    n = 1,
    view_filter = function(self, selected, to_select)
        local level = getMiaojianLevel(sgs.Self)
        if level >= 3 then
            return false
        end
        if level == 1 then
            return #selected == 0 and to_select:isKindOf('Slash') or to_select:isKindOf('TrickCard')
        end
        return #selected == 0
    end,
    view_as = function(self, cards)
        local level = getMiaojianLevel(sgs.Self)
        if level == 3 then
            return LuaMiaojianUseCard:clone()
        elseif #cards == 0 then
            return nil
        elseif level == 2 then
            local card = cards[1]
            local type = card:isKindOf('BasicCard') and 'slash' or 'ex_nihilo'
            local vs_card = sgs.Sanguosha:cloneCard(type, card:getSuit(), card:getNumber())
            vs_card:addSubcard(cards[1])
            vs_card:setSkillName(self:objectName())
            return vs_card
        elseif level == 1 then
            local card = cards[1]
            local type
            if card:isKindOf('Slash') then
                type = 'slash'
            elseif card:isKindOf('TrickCard') then
                type = 'ex_nihilo'
            end
            if not type then
                return nil
            end
            local vs_card = sgs.Sanguosha:cloneCard(type, card:getSuit(), card:getNumber())
            vs_card:addSubcard(cards[1])
            vs_card:setSkillName(self:objectName())
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag('LuaMiaojianUsed')
    end,
}

LuaMiaojian = sgs.CreateTriggerSkill {
    name = 'LuaMiaojian',
    events = {sgs.CardUsed, sgs.SlashMissed, sgs.EventPhaseEnd},
    view_as_skill = LuaMiaojianVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() then
                room:setPlayerFlag(player, 'LuaMiaojianUsed')
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play then
                room:setPlayerFlag(player, '-LuaMiaojianUsed')
            end
        else
            local effect = data:toSlashEffect()
            if not effect.slash or effect.slash:getSkillName() ~= self:objectName() then
                return false
            end
            if effect.to and not effect.to:isKongcheng() then
                if not room:askForDiscard(effect.to, 'LuaMiaojian', 1, 1, true, false, 'LuaMiaojianDiscard') then
                    room:slashResult(effect, nil)
                    return true
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaLianhua = sgs.CreateTriggerSkill {
    name = 'LuaLianhua',
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and use.to:contains(player) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            player:drawCards(1, self:objectName())
            local level = getLianhuaLevel(player)
            if level <= 1 then
                return false
            elseif level == 2 then
                local judge = rinsan.createJudgeStruct({
                    ['who'] = player,
                    ['reason'] = self:objectName(),
                    ['play_animation'] = true,
                    ['pattern'] = '.|spade',
                })
                room:judge(judge)
                if not judge:isGood() then
                    return false
                end
            elseif level >= 3 then
                if not use.from then
                    return false
                end
                local dataforai = sgs.QVariant()
                dataforai:setValue(player)
                if room:askForCard(use.from, '.|.|.|hand', '@xiangle-discard', dataforai) then
                    return false
                end
            end
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
    end,
}

ExSunhanhua:addSkill(LuaChongxu)
ExSunhanhua:addSkill(LuaMiaojian)
ExSunhanhua:addSkill(LuaLianhua)

-- 毛玠
ExMaojie = sgs.General(extension, 'ExMaojie', 'wei', '3', true, true)

-- 获取秉清标记数
local function getBingQingMarkCount(player)
    local suits = {
        sgs.Card_Diamond,
        sgs.Card_Spade,
        sgs.Card_Heart,
        sgs.Card_Club,
    }
    local count = 0
    for _, suit in ipairs(suits) do
        local mark = string.format('@%s%s_biu', 'LuaBingqing', rinsan.Suit2String(suit))
        if player:getMark(mark) > 0 then
            count = count + 1
        end
    end
    return count
end

LuaBingqing = sgs.CreateTriggerSkill {
    name = 'LuaBingqing',
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local suitString = use.card:getSuitString()
        if (not use.card) or (use.card:isKindOf('SkillCard')) or (rinsan.startsWith(suitString, 'no_suit')) then
            return false
        end
        local mark = string.format('@%s%s_biu', self:objectName(), suitString)
        if player:getMark(mark) > 0 then
            return false
        end
        room:addPlayerMark(player, mark)
        local count = getBingQingMarkCount(player)
        if count <= 1 then
            return false
        end
        local available_targets = sgs.SPlayerList()
        if count < 4 then
            available_targets:append(player)
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if count ~= 3 or rinsan.canDiscard(player, p, 'hej') then
                available_targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, available_targets, self:objectName(),
            'LuaBingqing-invoke' .. count, true, true)
        if target then
            room:notifySkillInvoked(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            if count == 2 then
                target:drawCards(2, self:objectName())
            elseif count == 3 then
                if rinsan.canDiscard(player, target, 'hej') then
                    local id = room:askForCardChosen(player, target, 'hej', self:objectName())
                    room:throwCard(id, target, player)
                end
            elseif count == 4 then
                rinsan.doDamage(player, target, 1)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

ExMaojie:addSkill(LuaBingqing)

-- 裴秀
ExPeixiu = sgs.General(extension, 'ExPeixiu', 'qun', '3', true, true)

LuaXingtu = sgs.CreateTriggerSkill {
    name = 'LuaXingtu',
    events = {sgs.CardUsed, sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (not use.card) or use.card:isKindOf('SkillCard') then
            return false
        end
        if event == sgs.CardFinished then
            local record = use.card:getNumber()
            if use.card:isVirtualCard() then
                if use.card:subcardsLength() == 0 then
                    return false
                else
                    record = 0
                    for _, id in sgs.qlist(use.card:getSubcards()) do
                        local cd = sgs.Sanguosha:getCard(id)
                        record = record + cd:getNumber()
                    end
                end
            end
            room:setPlayerMark(player, '@LuaXingtu', record)
        else
            local recorded = player:getMark('@LuaXingtu')
            if recorded == 0 then
                return false
            end
            if recorded % use.card:getNumber() == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(1, self:objectName())
            end
        end
        return false
    end,
}

LuaXingtuTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaXingtuTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = '.',
    residue_func = function(self, player, card)
        if player:hasSkill('LuaXingtu') then
            local num = card:getNumber()
            local recorded = player:getMark('@LuaXingtu')
            if num == 0 then
                return 0
            end
            if num % recorded == 0 then
                return 1000
            end
        end
        return 0
    end,
}

LuaJuezhiCard = sgs.CreateSkillCard {
    name = 'LuaJuezhi',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local count = 0
        room:notifySkillInvoked(source, self:objectName())
        for _, id in sgs.qlist(self:getSubcards()) do
            local cd = sgs.Sanguosha:getCard(id)
            count = count + cd:getNumber()
        end
        count = count % 13
        if count == 0 then
            count = 13
        end
        local checker = function(cd)
            return cd:getNumber() == count
        end
        local card = rinsan.obtainCardFromPile(checker, room:getDrawPile())
        if card then
            source:obtainCard(card, false)
        end
    end,
}

LuaJuezhi = sgs.CreateViewAsSkill {
    name = 'LuaJuezhi',
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards < 2 then
            return nil
        end
        local vs_card = LuaJuezhiCard:clone()
        for _, cd in ipairs(cards) do
            vs_card:addSubcard(cd)
        end
        return vs_card
    end,
}

ExPeixiu:addSkill(LuaXingtu)
ExPeixiu:addSkill(LuaJuezhi)
table.insert(hiddenSkills, LuaXingtuTargetMod)

-- 手杀界公孙瓒
JieGongsunzan = sgs.General(extension, 'JieGongsunzan', 'qun', '4', true, true)

JieYicong = sgs.CreateDistanceSkill {
    name = 'JieYicong',
    correct_func = function(self, from, to)
        if from:hasSkill('JieYicong') then
            return -from:getHp() + 1
        end
        if to:hasSkill('JieYicong') then
            return to:getLostHp() - 1
        end
        return 0
    end,
}

JieGongsunzan:addSkill(JieYicong)
JieGongsunzan:addSkill('qiaomeng')

-- 曹嵩
ExCaosong = sgs.General(extension, 'ExCaosong', 'wei', '3', true, true)

local GOLDS = {
    [1] = '@LuaYijin1',
    [2] = '@LuaYijin2',
    [3] = '@LuaYijin3',
    [4] = '@LuaYijin4',
    [5] = '@LuaYijin5',
    [6] = '@LuaYijin6',
}

-- 从 1 到 6 分别是
-- 膴仕：摸牌阶段多摸四张牌、出牌阶段使用【杀】的次数上限+1
-- 厚任：回合结束时，回复3点体力
-- 通神：受到非雷电伤害时，防止之
-- 金迷：跳过下一个出牌阶段和弃牌阶段
-- 贾凶：出牌阶段开始时失去1点体力，本回合手牌上限-3
-- 拥蔽：准备阶段，跳过下一个摸牌阶段
local function getGoldTable(player)
    local golds = {}
    for i = 1, 6, 1 do
        local mark = string.format('@LuaYijin%d', i)
        if player:getMark(mark) > 0 then
            table.insert(golds, mark)
        end
    end
    return golds
end

local function getGoldCount(player)
    return #getGoldTable(player)
end

local function initialGolds(player)
    local room = player:getRoom()
    room:sendCompulsoryTriggerLog(player, 'LuaYijin')
    for i = 1, 6, 1 do
        local mark = string.format('@LuaYijin%d', i)
        room:addPlayerMark(player, mark)
    end
end

-- 令 player 获取第 effectIndex 个金
local function gainGoldEffect(player, effectIndex)
    local room = player:getRoom()
    room:addPlayerMark(player, string.format('@LuaYijin%d', effectIndex))
    local index = 1
    -- 额外处理跳过阶段
    if effectIndex == 4 then
        -- 金迷
        room:addPlayerMark(player, 'LuaYijinPlay')
        room:addPlayerMark(player, 'LuaYijinDiscard')
        index = 2
    elseif effectIndex == 6 then
        -- 拥蔽
        room:addPlayerMark(player, 'LuaYijinDraw')
        index = 2
    end
    room:broadcastSkillInvoke('LuaYijin', index)
end

local function clearGoldEffect(player)
    local room = player:getRoom()
    for i = 1, 6, 1 do
        local mark = string.format('@LuaYijin%d', i)
        room:setPlayerMark(player, mark, 0)
    end
end

local function transferGold(from, to, gold)
    local room = from:getRoom()
    room:notifySkillInvoked(from, 'LuaYijin')
    room:doAnimate(rinsan.ANIMATE_INDICATE, from:objectName(), to:objectName())
    gainGoldEffect(to, rinsan.getPos(GOLDS, gold))
    room:removePlayerMark(from, gold)
    rinsan.sendLogMessage(room, '#LuaYijinTransfer', {
        ['from'] = from,
        ['to'] = to,
        ['arg'] = gold,
    })
end

LuaYijinStart = sgs.CreateTriggerSkill {
    name = 'LuaYijinStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local caosongs = room:findPlayersBySkillName('LuaYijin')
        if caosongs:isEmpty() then
            return false
        end
        room:broadcastSkillInvoke('LuaYijin', 1)
        for _, caosong in sgs.qlist(caosongs) do
            if getGoldCount(caosong) == 0 then
                initialGolds(caosong)
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaYijin = sgs.CreateTriggerSkill {
    name = 'LuaYijin',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_RoundStart then
            if getGoldCount(player) == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 3)
                room:killPlayer(player)
            end
        elseif player:getPhase() == sgs.Player_Play then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if getGoldCount(p) == 0 then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then
                return false
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local gold = room:askForChoice(player, self:objectName(), table.concat(getGoldTable(player), '+'))
            local target = room:askForPlayerChosen(player, targets, self:objectName(), 'LuaYijin-invoke:' .. gold)
            if target then
                transferGold(player, target, gold)
            end
        end
        return false
    end,
}

LuaYijinEffect = sgs.CreateTriggerSkill {
    name = 'LuaYijinEffect',
    events = {sgs.DrawNCards, sgs.EventPhaseChanging, sgs.DamageInflicted, sgs.EventPhaseStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        -- 有亿金的曹嵩不需要执行
        if player:hasSkill('LuaYijin') then
            return false
        end
        -- 无金的也不需要
        if getGoldCount(player) == 0 then
            return false
        end
        if event == sgs.DrawNCards then
            -- 膴仕：摸牌阶段多摸四张牌
            if player:getMark('@LuaYijin1') > 0 then
                rinsan.sendLogMessage(room, '#LuaYijin1', {
                    ['from'] = player,
                    ['arg'] = '@LuaYijin1',
                    ['arg2'] = 4,
                })
                data:setValue(data:toInt() + 4)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Finish then
                -- 厚任：回合结束时，回复3点体力
                if player:getMark('@LuaYijin2') > 0 then
                    if player:getLostHp() > 0 then
                        rinsan.sendLogMessage(room, '#LuaYijin2', {
                            ['from'] = player,
                            ['arg'] = '@LuaYijin2',
                            ['arg2'] = 3,
                        })
                    end
                    rinsan.recover(player, 3)
                end
                clearGoldEffect(player)
            else
                -- 金迷：跳过下一个出牌阶段和弃牌阶段
                if player:getMark('@LuaYijin4') > 0 then
                    if player:getMark('LuaYijinPlay') > 0 and change.to == sgs.Player_Play then
                        rinsan.sendLogMessage(room, '#LuaYijin4', {
                            ['from'] = player,
                            ['arg'] = '@LuaYijin4',
                            ['arg2'] = 'play',
                        })
                        player:skip(change.to)
                        room:removePlayerMark(player, 'LuaYijinPlay')
                    elseif player:getMark('LuaYijinDiscard') > 0 and change.to == sgs.Player_Discard then
                        rinsan.sendLogMessage(room, '#LuaYijin4', {
                            ['from'] = player,
                            ['arg'] = '@LuaYijin4',
                            ['arg2'] = 'discard',
                        })
                        player:skip(change.to)
                        room:removePlayerMark(player, 'LuaYijinDiscard')
                    end
                end
            end
        elseif event == sgs.DamageInflicted then
            if player:getMark('@LuaYijin3') > 0 then
                -- 通神：受到非雷电伤害时，防止之
                local damage = data:toDamage()
                if damage.damage ~= sgs.DamageStruct_Thunder then
                    rinsan.sendLogMessage(room, '#LuaYijin3', {
                        ['from'] = player,
                        ['arg'] = '@LuaYijin3',
                    })
                    return true
                end
            end
        else
            if player:getPhase() == sgs.Player_Play then
                -- 贾凶：出牌阶段开始时失去1点体力
                if player:getMark('@LuaYijin5') > 0 then
                    rinsan.sendLogMessage(room, '#LuaYijin5', {
                        ['from'] = player,
                        ['arg'] = '@LuaYijin5',
                        ['arg2'] = 1,
                    })
                    room:loseHp(player)
                end
            elseif player:getPhase() == sgs.Player_Start then
                -- 拥蔽：准备阶段，跳过下一个摸牌阶段
                if player:getMark('@LuaYijin6') > 0 then
                    rinsan.sendLogMessage(room, '#LuaYijin6', {
                        ['from'] = player,
                        ['arg'] = '@LuaYijin6',
                        ['arg2'] = 'draw',
                    })
                    player:skip(sgs.Player_Draw)
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaYijinMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaYijinMaxCards',
    extra_func = function(self, target)
        if target:hasSkill('LuaYijin') then
            return 0
        end
        if target:getMark('@LuaYijin5') > 0 and target:getPhase() ~= sgs.Player_NotActive then
            -- 贾凶：本回合手牌上限-3
            return -3
        end
        return 0
    end,
}

LuaYijinTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaYijinTargetMod',
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:hasSkill('LuaYijin') then
            return 0
        end
        if player:getMark('@LuaYijin1') > 0 then
            return 1
        end
        return 0
    end,
}

LuaGuanzongCard = sgs.CreateSkillCard {
    name = 'LuaGuanzong',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected < 2 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, use)
        local thread = room:getThread()
        local data = sgs.QVariant()
        data:setValue(use)
        thread:trigger(sgs.PreCardUsed, room, use.from, data)
        rinsan.sendLogMessage(room, '#ChoosePlayerWithSkill', {
            ['from'] = use.from,
            ['tos'] = use.to,
            ['arg'] = self:objectName(),
        })
        thread:trigger(sgs.CardUsed, room, use.from, data)
        thread:trigger(sgs.CardFinished, room, use.from, data)
    end,
    on_use = function(self, room, source, targets)
        local from = targets[1]
        local to = targets[2]
        room:notifySkillInvoked(source, self:objectName())
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), from:objectName())
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), to:objectName())
        local damage = sgs.DamageStruct()
        damage.from = from
        damage.to = to
        damage.nature = sgs.DamageStruct_Normal
        local data = sgs.QVariant()
        data:setValue(damage)
        rinsan.sendLogMessage(room, '#LuaGuanzong', {
            ['from'] = from,
            ['to'] = to,
            ['arg'] = self:objectName(),
            ['arg2'] = 1,
        })
        sgs.Sanguosha:playSystemAudioEffect('injure1', true)
        room:setEmotion(to, 'damage')
        room:doAnimate(rinsan.ANIMATE_INDICATE, from:objectName(), to:objectName())
        room:getThread():trigger(sgs.PreDamageDone, room, to, data)
        room:addPlayerMark(from, 'damage_point_round')
        room:setPlayerFlag(to, 'LuaGuanzongProceeding')
        room:getThread():trigger(sgs.DamageDone, room, to, data)
        room:setPlayerFlag(to, '-LuaGuanzongProceeding')
        room:getThread():trigger(sgs.Damage, room, from, data)
        room:getThread():trigger(sgs.Damaged, room, to, data)
    end,
}

LuaGuanzong = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaGuanzong',
    view_as = function(self, cards)
        return LuaGuanzongCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaGuanzong')
    end,
}

LuaGuanzongDamageDone = sgs.CreateTriggerSkill {
    name = 'LuaGuanzongDamageDone',
    events = {sgs.DamageDone},
    priority = 10000,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to and damage.to:hasFlag('LuaGuanzongProceeding') then
            return true
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

ExCaosong:addSkill(LuaYijin)
ExCaosong:addSkill(LuaGuanzong)
table.insert(hiddenSkills, LuaYijinEffect)
table.insert(hiddenSkills, LuaYijinStart)
table.insert(hiddenSkills, LuaYijinMaxCards)
table.insert(hiddenSkills, LuaYijinTargetMod)
table.insert(hiddenSkills, LuaGuanzongDamageDone)

-- 贾逵重制
ExTongquJiakui = sgs.General(extension, 'ExTongquJiakui', 'wei', '4', true, true)

LuaTongquCard = sgs.CreateSkillCard {
    name = 'LuaTongqu',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and to_select:getMark('@LuaTongqu') > 0
    end,
    feasible = function(self, targets)
        return #targets <= 1
    end,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local target
        if #targets > 0 then
            target = targets[1]
        end
        if target then
            target:obtainCard(card, false)
            if card:isKindOf('EquipCard') then
                room:useCard(sgs.CardUseStruct(card, target, target))
            end
        else
            room:throwCard(card, source)
        end
    end,
}

LuaTongquVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaTongqu',
    filter_pattern = '.',
    view_as = function(self, card)
        local vs_card = LuaTongquCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaTongqu')
    end,
}

LuaTongqu = sgs.CreateTriggerSkill {
    name = 'LuaTongqu',
    events = {sgs.DrawNCards, sgs.EventPhaseEnd, sgs.Dying},
    view_as_skill = LuaTongquVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            if player:getMark('@LuaTongqu') == 0 then
                return false
            end
            room:addPlayerMark(player, self:objectName() .. '_biu')
            room:broadcastSkillInvoke(self:objectName())
            rinsan.sendLogMessage(room, '#LuaTongqu', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['arg2'] = 1,
            })
            data:setValue(data:toInt() + 1)
        elseif event == sgs.Dying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                if player:getMark('@LuaTongqu') > 0 then
                    player:loseMark('@LuaTongqu')
                end
            end
        elseif player:getPhase() == sgs.Player_Draw then
            if player:getMark('@LuaTongqu') == 0 then
                return false
            end
            if player:getMark(self:objectName() .. '_biu') > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:askForUseCard(player, '@@LuaTongqu!', 'LuaTongqu-Invoke', -1, sgs.Card_MethodNone)
            end
        elseif player:getPhase() == sgs.Player_Start then
            if not player:hasSkill(self:objectName()) then
                return false
            end
            local available_targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark('@LuaTongqu') == 0 then
                    available_targets:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, available_targets, self:objectName(), 'LuaTongqu-Give', true,
                true)
            if target then
                room:broadcastSkillInvoke('LuaTongqu')
                room:loseHp(player)
                target:gainMark('@LuaTongqu')
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaTongquStart = sgs.CreateTriggerSkill {
    name = 'LuaTongquStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local tongqujiakuis = room:findPlayersBySkillName('LuaTongqu')
        if tongqujiakuis:isEmpty() then
            return false
        end
        for _, tongqujiakui in sgs.qlist(tongqujiakuis) do
            if tongqujiakui:getMark('@LuaTongqu') == 0 then
                room:broadcastSkillInvoke('LuaTongqu')
                room:sendCompulsoryTriggerLog(tongqujiakui, 'LuaTongqu')
                tongqujiakui:gainMark('@LuaTongqu')
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaWanlanTongqu = sgs.CreateTriggerSkill {
    name = 'LuaWanlanTongqu',
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage >= player:getHp() + rinsan.getShieldCount(player) then
            local data2 = sgs.QVariant()
            data2:setValue(damage.to)
            for _, tongqujiakui in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if tongqujiakui:hasEquip() then
                    if room:askForSkillInvoke(tongqujiakui, self:objectName(), data2) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:doAnimate(rinsan.ANIMATE_INDICATE, tongqujiakui:objectName(), damage.to:objectName())
                        tongqujiakui:throwAllEquips()
                        rinsan.sendLogMessage(room, '#LuaWanlanTongqu', {
                            ['from'] = tongqujiakui,
                            ['to'] = damage.to,
                            ['arg'] = self:objectName(),
                            ['arg2'] = damage.damage,
                        })
                        return true
                    end
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

ExTongquJiakui:addSkill(LuaTongqu)
ExTongquJiakui:addSkill(LuaWanlanTongqu)
table.insert(hiddenSkills, LuaTongquStart)

JieWolong = sgs.General(extension, 'JieWolong', 'shu', '3', true, true)

LuaBazhen = sgs.CreateTriggerSkill {
    name = 'LuaBazhen',
    events = {sgs.CardAsked},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local pattern = data:toStringList()[1]
        if pattern ~= 'jink' then
            return false
        end
        if room:askForSkillInvoke(player, 'eight_diagram', data) then
            room:setEmotion(player, 'armor/eight_diagram')
            local judge = rinsan.createJudgeStruct({
                ['pattern'] = '.|red',
                ['who'] = player,
                ['play_animation'] = true,
                ['reason'] = 'eight_diagram',
            })
            room:judge(judge)
            if judge:isGood() then
                local jink = sgs.Sanguosha:cloneCard('jink', sgs.Card_NoSuit, 0)
                jink:setSkillName(self:objectName())
                room:provide(jink)
                return true
            end
            room:setTag('ArmorJudge', sgs.QVariant('eight_diagram'))
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and (not target:getArmor()) and rinsan.hasArmorEffect(target, 'eight_diagram')
    end,
}

LuaBazhenDraw = sgs.CreateTriggerSkill {
    name = 'LuaBazhenDraw',
    events = {sgs.FinishJudge},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.reason == 'eight_diagram' and judge:isBad() then
            room:sendCompulsoryTriggerLog(player, 'LuaBazhen')
            player:drawCards(1, 'LuaBazhen')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaBazhen')
    end,
}

LuaHuojiVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaHuoji',
    filter_pattern = '.|red|.',
    response_or_use = true,
    view_as = function(self, card)
        local fireAttack = sgs.Sanguosha:cloneCard('fire_attack', card:getSuit(), card:getNumber())
        fireAttack:addSubcard(card)
        fireAttack:setSkillName(self:objectName())
        return fireAttack
    end,
}

LuaFireAttack = sgs.CreateTrickCard {
    name = 'fire_attack',
    class_name = 'FireAttack',
    subtype = 'single_target_trick',
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    filter = function(self, selected, to_select)
        return #selected == 0 and not to_select:isKongcheng()
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        if target:isKongcheng() then
            return
        end
        local toShow = target:getHandcards():at(rinsan.random(0, target:getHandcardNum() - 1))
        room:showCard(target, toShow:getEffectiveId())
        local toDiscard

        local card_ids = room:getNCards(4)
        room:fillAG(card_ids, source)
        local to_return = sgs.IntList()
        for _, id in sgs.qlist(card_ids) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:getSuit() ~= toShow:getSuit() then
                to_return:append(id)
            end
        end
        for _, id in sgs.qlist(to_return) do
            card_ids:removeOne(id)
            room:takeAG(nil, id, false)
        end
        if not card_ids:isEmpty() then
            repeat
                local card_id = room:askForAG(source, card_ids, true, self:objectName())
                if card_id == -1 then
                    room:clearAG(source)
                    break
                end
                card_ids:removeOne(card_id)
                room:takeAG(source, card_id, false)
                toDiscard = sgs.Sanguosha:getCard(card_id)
            until true
        end
        for _, id in sgs.qlist(card_ids) do
            to_return:append(id)
        end
        room:returnToTopDrawPile(to_return)
        room:clearAG(source)
        local pattern = string.format('.|%s|.|hand', rinsan.getColorString(toShow))
        local prompt = string.format('@LuaHuoji-Discard:%s::%s', target:objectName(), rinsan.getColorString(toShow))
        toDiscard = toDiscard or room:askForCard(source, pattern, prompt, sgs.QVariant(), sgs.Card_MethodNone)
        if toDiscard then
            room:throwCard(toDiscard, source)
            rinsan.doDamage(source, target, 1, sgs.DamageStruct_Fire, self)
        end
    end,
}

LuaHuoji = sgs.CreateTriggerSkill {
    name = 'LuaHuoji',
    events = {sgs.CardEffected},
    view_as_skill = LuaHuojiVS,
    global = true,
    priority = 100,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        local card = effect.card
        local source = effect.from
        if card and card:isKindOf('FireAttack') then
            if not source:hasSkill(self:objectName()) then
                return false
            end
            room:sendCompulsoryTriggerLog(source, self:objectName())
            local fireAttack = LuaFireAttack:clone()
            fireAttack:addSubcard(effect.card)
            fireAttack:setSuit(effect.card:getSuit())
            fireAttack:setNumber(effect.card:getNumber())
            fireAttack:setId(effect.card:getId())
            effect.card = fireAttack
            data:setValue(effect)
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaKanpoVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaKanpo',
    filter_pattern = '.|black|.',
    response_pattern = 'nullification',
    response_or_use = true,
    view_as = function(self, card)
        local nullification = sgs.Sanguosha:cloneCard('nullification', card:getSuit(), card:getNumber())
        nullification:addSubcard(card)
        nullification:setSkillName(self:objectName())
        return nullification
    end,
    enabled_at_nullification = function(self, player)
        for _, cd in sgs.qlist(player:getCards('he')) do
            if cd:isBlack() then
                return true
            end
        end
        for _, id in sgs.qlist(player:getPile('wooden_ox')) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:isBlack() then
                return true
            end
        end
        return false
    end,
}

LuaKanpo = sgs.CreateTriggerSkill {
    name = 'LuaKanpo',
    events = {sgs.TrickCardCanceling},
    view_as_skill = LuaKanpoVS,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        if rinsan.RIGHT(self, effect.from) and effect.card:isKindOf('Nullification') then
            SendComLog(self, effect.from)
            return true
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaCangzhuo = sgs.CreateTriggerSkill {
    name = 'LuaCangzhuo',
    events = {sgs.CardUsed, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('TrickCard') then
                room:addPlayerMark(player, 'LuaCangzhuoUsedTrick-Clear')
            end
            return false
        end
        if player:getMark('LuaCangzhuoUsedTrick-Clear') > 0 then
            room:setPlayerMark(player, 'LuaCangzhuoUsedTrick-Clear', 0)
            return false
        end
        if event == sgs.AskForGameruleDiscard then
            room:sendCompulsoryTriggerLog(player, self:objectName())
        end
        local n = room:getTag('DiscardNum'):toInt()
        for _, id in sgs.qlist(player:handCards()) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:isKindOf('TrickCard') then
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
        return rinsan.RIGHTNOTATPHASE(self, target, sgs.Player_NotActive)
    end,
}

LuaCangzhuoMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaCangzhuoMaxCards',
    extra_func = function(self, target)
        local x = 0
        if target:getMark('LuaCangzhuoUsedTrick-Clear') > 0 then
            return 0
        end
        if not target:hasSkill('LuaCangzhuo') then
            return 0
        end
        for _, cd in sgs.qlist(target:getHandcards()) do
            if cd:isKindOf('TrickCard') then
                x = x + 1
            end
        end
        -- 迫真多余牌修正
        return target:getHandcardNum() > target:getHp() and 0 or x
    end,
}

JieWolong:addSkill(LuaBazhen)
JieWolong:addSkill(LuaHuoji)
JieWolong:addSkill(LuaKanpo)
JieWolong:addSkill(LuaCangzhuo)
table.insert(hiddenSkills, LuaCangzhuoMaxCards)
table.insert(hiddenSkills, LuaBazhenDraw)

-- 界祝融
JieZhurong = sgs.General(extension, 'JieZhurong', 'shu', '4', false, true)

LuaJuxiang = sgs.CreateTriggerSkill {
    name = 'LuaJuxiang',
    events = {sgs.CardEffected, sgs.BeforeCardsMove, sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if not player:hasSkill(self:objectName()) then
                return false
            end
            if effect.card and effect.card:isKindOf('SavageAssault') then
                room:broadcastSkillInvoke(self:objectName())
                room:notifySkillInvoked(player, self:objectName())
                rinsan.sendLogMessage(room, '#SkillNullify', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                    ['arg2'] = 'savage_assault',
                })
                return true
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf('SavageAssault') then
                if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then
                    return false
                end
                if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and
                    sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf('SavageAssault') then
                    room:setCardFlag(use.card:getEffectiveId(), 'real_SA')
                end
            end
        else
            if rinsan.RIGHT(self, player) then
                local move = data:toMoveOneTime()
                if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable) and
                    (move.to_place == sgs.Player_DiscardPile) and
                    (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
                    local card = sgs.Sanguosha:getCard(move.card_ids:first())
                    if card:hasFlag('real_SA') and (player:objectName() ~= move.from:objectName()) then
                        player:obtainCard(card)
                        move.card_ids = sgs.IntList()
                        data:setValue(move)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaLieren = sgs.CreateTriggerSkill {
    name = 'LuaLieren',
    events = {sgs.TargetSpecified, sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('Slash') then
                for _, t in sgs.qlist(use.to) do
                    local data2 = sgs.QVariant()
                    data2:setValue(t)
                    if player:canPindian(t, self:objectName()) and
                        room:askForSkillInvoke(player, self:objectName(), data2) then
                        room:broadcastSkillInvoke(self:objectName())
                        player:pindian(t, self:objectName())
                    end
                end
            end
        else
            local pindian = data:toPindian()
            if pindian.reason ~= self:objectName() then
                return false
            end
            if pindian.success then
                if not pindian.to:isNude() then
                    local card_id = room:askForCardChosen(pindian.from, pindian.to, 'he', self:objectName(), false,
                        sgs.Card_MethodNone)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, pindian.from:objectName())
                    room:obtainCard(pindian.from, sgs.Sanguosha:getCard(card_id), reason, false)
                end
            else
                pindian.from:obtainCard(pindian.to_card)
                pindian.to:obtainCard(pindian.from_card)
            end
        end
        return false
    end,
}

JieZhurong:addSkill(LuaJuxiang)
JieZhurong:addSkill(LuaLieren)

ExStarHuangzhong = sgs.General(extension, 'ExStarHuangzhong', 'qun', '4', true, true)

local function isYang(huangzhong)
    return huangzhong:getMark('LuaShidi') ~= 1
end

local function setToYang(huangzhong)
    local room = huangzhong:getRoom()
    room:setPlayerMark(huangzhong, 'LuaShidi', 2)
    rinsan.modifySkillDescription(':LuaShidi', ':LuaShidi1')
    ChangeCheck(huangzhong, 'ExStarHuangzhong')
    room:removePlayerMark(huangzhong, '@ChangeSkill2')
    room:addPlayerMark(huangzhong, '@ChangeSkill1')
end

local function isYin(huangzhong)
    return huangzhong:getMark('LuaShidi') == 1
end

local function setToYin(huangzhong)
    local room = huangzhong:getRoom()
    room:setPlayerMark(huangzhong, 'LuaShidi', 1)
    rinsan.modifySkillDescription(':LuaShidi', ':LuaShidi2')
    ChangeCheck(huangzhong, 'ExStarHuangzhong')
    room:removePlayerMark(huangzhong, '@ChangeSkill1')
    room:addPlayerMark(huangzhong, '@ChangeSkill2')
end

LuaShidi = sgs.CreateDistanceSkill {
    name = 'LuaShidi',
    correct_func = function(self, from, to)
        local distance = 0
        if from:hasSkill(self:objectName()) and isYang(from) then
            distance = distance - 1
        end
        if to:hasSkill(self:objectName()) and isYin(to) then
            distance = distance + 1
        end
        return distance
    end,
}

LuaShidiChange = sgs.CreateTriggerSkill {
    name = 'LuaShidiChange',
    events = {sgs.EventPhaseStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if isYin(player) then
                room:sendCompulsoryTriggerLog(player, 'LuaShidi')
                room:broadcastSkillInvoke('LuaShidi', 1)
                setToYang(player)
            end
        elseif player:getPhase() == sgs.Player_Finish then
            if isYang(player) then
                room:sendCompulsoryTriggerLog(player, 'LuaShidi')
                room:broadcastSkillInvoke('LuaShidi', 2)
                setToYin(player)
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaShidi')
    end,
}

LuaShidiSlash = sgs.CreateTriggerSkill {
    name = 'LuaShidiSlash',
    events = {sgs.TargetSpecified, sgs.SlashProceed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if isYang(player) and rinsan.RIGHT(self, player, 'LuaShidi') then
                if use.card and use.card:isBlack() and use.card:isKindOf('Slash') then
                    room:sendCompulsoryTriggerLog(player, 'LuaShidi')
                    local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
                    local index = 1
                    for _, p in sgs.qlist(use.to) do
                        if p:isAlive() then
                            rinsan.sendLogMessage(room, '#NoJink', {
                                ['from'] = p,
                            })
                        end
                        jink_table[index] = 0
                        index = index + 1
                    end
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    player:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        else
            local effect = data:toSlashEffect()
            if isYin(effect.to) then
                if rinsan.RIGHT(self, effect.to, 'LuaShidi') and effect.slash:isRed() then
                    room:sendCompulsoryTriggerLog(effect.to, 'LuaShidi')
                    rinsan.sendLogMessage(room, '#NoJink', {
                        ['from'] = effect.to,
                    })
                    room:slashResult(effect, nil)
                    return true
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaStarYishi = sgs.CreateTriggerSkill {
    name = 'LuaStarYishi',
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:objectName() == player:objectName() then
            return false
        end
        if damage.to:hasEquip() and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
            if damage.to:hasEquip() then
                local id = room:askForCardChosen(player, damage.to, 'e', self:objectName())
                player:obtainCard(sgs.Sanguosha:getCard(id), false)
            end
            damage.damage = damage.damage - 1
            data:setValue(damage)
            if damage.damage == 0 then
                return true
            end
        end
        return false
    end,
}

LuaQishe = sgs.CreateOneCardViewAsSkill {
    name = 'LuaQishe',
    view_filter = function(self, to_select)
        return to_select:isKindOf('EquipCard')
    end,
    view_as = function(self, card)
        local analeptic = sgs.Sanguosha:cloneCard('analeptic', card:getSuit(), card:getNumber())
        analeptic:addSubcard(card)
        analeptic:setSkillName(self:objectName())
        return analeptic
    end,
    enabled_at_play = function(self, player)
        return sgs.Analeptic_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, 'analeptic')
    end
}

LuaQisheMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaQisheMaxCards',
    extra_func = function(self, target)
        if target:hasSkill('LuaQishe') then
            return target:getEquips():length()
        end
        return 0
    end,
}

ExStarHuangzhong:addSkill(LuaShidi)
table.insert(hiddenSkills, LuaShidiChange)
table.insert(hiddenSkills, LuaShidiSlash)
ExStarHuangzhong:addSkill(LuaStarYishi)
ExStarHuangzhong:addSkill(LuaQishe)
table.insert(hiddenSkills, LuaQisheMaxCards)

rinsan.addHiddenSkills(hiddenSkills)
