module('extensions.ExpansionPackage', package.seeall)
extension = sgs.Package('ExpansionPackage')

SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true,
                           true)
Wangyuanji = sgs.General(extension, 'Wangyuanji', 'wei', '3', false, true)
Xurong = sgs.General(extension, 'Xurong', 'qun', '4', true, true)
Caoying = sgs.General(extension, 'Caoying', 'wei', '4', false, true)
Lijue = sgs.General(extension, 'Lijue', 'qun', 6, true,
                    sgs.GetConfig("hidden_ai", true), false, 4)
Caochun = sgs.General(extension, 'Caochun', 'wei', '4', true, true)
Maliang = sgs.General(extension, 'Maliang', 'shu', '3', true, true)
Jiakui = sgs.General(extension, 'Jiakui', 'wei', '3', true, true)
JieMadai = sgs.General(extension, 'JieMadai', 'shu', '4', true, true)
JieXusheng = sgs.General(extension, 'JieXusheng', 'wu', '4', true, true)
Majun = sgs.General(extension, 'Majun', 'wei', '3', true, true)
Yiji = sgs.General(extension, 'Yiji', 'shu', '3', true, true)
Lifeng = sgs.General(extension, 'Lifeng', 'shu', '3', true, true)
ZhaotongZhaoguang = sgs.General(extension, 'ZhaotongZhaoguang', 'shu', '4',
                                true, true)
JieYanliangWenchou = sgs.General(extension, 'JieYanliangWenchou', 'qun', '4',
                                 true, true)
JieLingtong = sgs.General(extension, 'JieLingtong', 'wu', '4', true, true)
Shenpei = sgs.General(extension, 'Shenpei', 'qun', 3, true,
                      sgs.GetConfig("hidden_ai", true), false, 2)
Yangbiao = sgs.General(extension, 'Yangbiao', 'qun', '3', true, true)
Luotong = sgs.General(extension, 'Luotong', 'wu', '4', true, true)
Zhangyi = sgs.General(extension, 'Zhangyi', 'shu', '4', true, true)
JieLiru = sgs.General(extension, 'JieLiru', 'qun', '3', true, true)
Jiemanchong = sgs.General(extension, 'Jiemanchong', 'wei', '3', true, true)

LuaQianchong = sgs.CreateTriggerSkill {
    name = 'LuaQianchong',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                room:setPlayerMark(player, 'LuaQianchongCard', 0)
                if player:getMark(self:objectName()) == 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    local choice = room:askForChoice(player, self:objectName(),
                                                     'BasicCard+TrickCard+EquipCard')
                    local msg = sgs.LogMessage()
                    msg.type = '#LuaQianchongChoice'
                    msg.from = player
                    msg.arg = choice
                    room:sendLog(msg)
                    if choice == 'BasicCard' then
                        room:setPlayerMark(player, 'LuaQianchongCard', 1)
                    elseif choice == 'TrickCard' then
                        room:setPlayerMark(player, 'LuaQianchongCard', 2)
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (move.from_places:contains(sgs.Player_PlaceEquip) or
                move.to_place == sgs.Player_PlaceEquip) and
                ((move.to and move.to:objectName() == player:objectName()) or
                    (move.from and move.from:objectName() == player:objectName())) then
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
                    room:handleAcquireDetachSkills(player, '-weimu|mingzhe')
                    room:setPlayerMark(player, self:objectName(), 1)
                elseif type == 2 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:handleAcquireDetachSkills(player, 'weimu|-mingzhe')
                    room:setPlayerMark(player, self:objectName(), 2)
                else
                    if player:hasSkill('weimu') or player:hasSkill('mingzhe') then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                    end
                    room:handleAcquireDetachSkills(player, '-weimu|-mingzhe')
                end
            end
        end
        return false
    end
}

LuaQianchongBasicCardTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaQianchongBasicCardTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'BasicCard',
    residue_func = function(self, player)
        if player:hasSkill('LuaQianchong') and
            player:getMark('LuaQianchongCard') == 1 then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaQianchong') and from:getMark('LuaQianchongCard') ==
            1 then
            return 1000
        else
            return 0
        end
    end
}

LuaQianchongTrickCardTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaQianchongTrickCardTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = 'TrickCard',
    residue_func = function(self, player)
        if player:hasSkill('LuaQianchong') and
            player:getMark('LuaQianchongCard') == 2 then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaQianchong') and from:getMark('LuaQianchongCard') ==
            2 then
            return 1000
        else
            return 0
        end
    end
}

LuaShangjian = sgs.CreateTriggerSkill {
    name = 'LuaShangjian',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) then
                if (move.from and
                    (move.from:objectName() == player:objectName()) and
                    (move.from_places:contains(sgs.Player_PlaceHand) or
                        move.from_places:contains(sgs.Player_PlaceEquip))) and
                    not (move.to and
                        (move.to:objectName() == player:objectName() and
                            (move.to_place == sgs.Player_PlaceHand or
                                move.to_place == sgs.Player_PlaceEquip))) then
                    room:addPlayerMark(player, '@' .. self:objectName(),
                                       move.card_ids:length())
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self:objectName()) then
                        local x = p:getMark('@' .. self:objectName())
                        if x > 0 then
                            if x <= p:getHp() then
                                p:drawCards(x)
                            end
                            room:setPlayerMark(p, '@' .. self:objectName(), 0)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

Wangyuanji:addSkill(LuaQianchong)
SkillAnjiang:addSkill(LuaQianchongTrickCardTargetMod)
SkillAnjiang:addSkill(LuaQianchongBasicCardTargetMod)
Wangyuanji:addSkill(LuaShangjian)
Wangyuanji:addRelateSkill('weimu')
Wangyuanji:addRelateSkill('mingzhe')

LuaXionghuoCard = sgs.CreateSkillCard {
    name = 'LuaXionghuoCard',
    target_fixed = false,
    will_throw = true,
    on_effect = function(self, effect)
        effect.from:loseMark('@baoli')
        effect.from:getRoom():broadcastSkillInvoke('LuaXionghuo')
        effect.to:gainMark('@baoli')
    end
}

LuaXionghuoVS = sgs.CreateViewAsSkill {
    name = 'LuaXionghuo',
    n = 0,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:objectName() ~= sgs.Self:objectName()
        end
        return false
    end,
    view_as = function(self, cards) return LuaXionghuoCard:clone() end,
    enabled_at_play = function(self, player)
        return player:getMark('@baoli') > 0
    end
}

LuaXionghuoMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaXionghuoMaxCards',
    extra_func = function(self, target)
        if target:getMark('XionghuoCardMinus') > 0 then return -1 end
        return 0
    end
}

LuaXionghuoProSlash = sgs.CreateProhibitSkill {
    name = 'LuaXionghuoSlash',
    is_prohibited = function(self, from, to, card)
        if to:hasSkill('LuaXionghuo') and from:getMark('XionghuoSlashPro') > 0 then
            return card:isKindOf('Slash')
        end
    end
}

LuaXionghuo = sgs.CreateTriggerSkill {
    name = 'LuaXionghuo',
    events = {
        sgs.GameStart, sgs.TurnStart, sgs.DamageCaused, sgs.EventPhaseStart
    },
    view_as_skill = LuaXionghuoVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or event == sgs.TurnStart then
            if player:hasSkill(self:objectName()) and
                player:getMark('LuaBaoliGetMark') == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                player:gainMark('@baoli', 3)
                room:addPlayerMark(player, 'LuaBaoliGetMark')
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from:hasSkill(self:objectName()) and
                damage.to:getMark('@baoli') > 0 then
                room:sendCompulsoryTriggerLog(damage.from, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        else
            if player:getPhase() == sgs.Player_Play then
                if player:getMark('@baoli') > 0 then
                    local splayer =
                        room:findPlayerBySkillName(self:objectName())
                    if splayer and splayer:objectName() ~= player:objectName() then
                        player:loseMark('@baoli')
                        room:sendCompulsoryTriggerLog(splayer, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        local choice = math.random(1, 3)
                        if choice == 1 then
                            local theDamage = sgs.DamageStruct()
                            theDamage.to = player
                            theDamage.damage = 1
                            theDamage.nature = sgs.DamageStruct_Fire
                            room:damage(theDamage)
                            room:addPlayerMark(player, 'XionghuoSlashPro')
                        elseif choice == 2 then
                            room:loseHp(player)
                            room:addPlayerMark(player, 'XionghuoCardMinus')
                        else
                            if not player:isKongcheng() then
                                local card_id =
                                    room:askForCardChosen(splayer, player, 'h',
                                                          self:objectName())
                                local reason = sgs.CardMoveReason(
                                                   sgs.CardMoveReason_S_REASON_EXTRACTION,
                                                   splayer:objectName())
                                room:obtainCard(splayer,
                                                sgs.Sanguosha:getCard(card_id),
                                                reason, false)
                            end
                            if player:getEquips():length() > 0 then
                                local card_id2 =
                                    room:askForCardChosen(splayer, player, 'e',
                                                          self:objectName())
                                local reason2 = sgs.CardMoveReason(
                                                    sgs.CardMoveReason_S_REASON_EXTRACTION,
                                                    splayer:objectName())
                                room:obtainCard(splayer, sgs.Sanguosha:getCard(
                                                    card_id2), reason2, false)
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
    can_trigger = function(self, target) return target end
}

LuaShajue = sgs.CreateTriggerSkill {
    name = 'LuaShajue',
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.who:getHp() < 0 then
            local splayer = room:findPlayerBySkillName(self:objectName())
            if splayer and splayer:objectName() ~= dying.who:objectName() then
                room:sendCompulsoryTriggerLog(splayer, self:objectName())
                room:notifySkillInvoked(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                splayer:gainMark('@baoli')
                local card = dying.damage.card
                if card then splayer:obtainCard(card) end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

Xurong:addSkill(LuaXionghuo)
Xurong:addSkill(LuaShajue)
SkillAnjiang:addSkill(LuaXionghuoMaxCards)
SkillAnjiang:addSkill(LuaXionghuoProSlash)

LuaLingren = sgs.CreateTriggerSkill {
    name = 'LuaLingren',
    events = {
        sgs.TargetConfirmed, sgs.EventPhaseChanging, sgs.DamageCaused,
        sgs.CardEffected, sgs.TurnStart
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
            if not (card:isKindOf('Slash') or card:isKindOf('Duel') or
                card:isKindOf('SavageAssault') or card:isKindOf('ArcheryAttack') or
                card:isKindOf('FireAttack')) then return false end
            if player:getMark(self:objectName()) == 0 then

                local splayers = sgs.SPlayerList()
                for _, p in sgs.qlist(use.to) do
                    splayers:append(p)
                end
                local target = room:askForPlayerChosen(player, splayers,
                                                       self:objectName(),
                                                       'LuaLingren-choose',
                                                       true, true)
                if target then
                    room:addPlayerMark(player, self:objectName())
                    local choice1 = room:askForChoice(player, 'BasicCardGuess',
                                                      'Have+NotHave')
                    local choice2 = room:askForChoice(player, 'TrickCardGuess',
                                                      'Have+NotHave')
                    local choice3 = room:askForChoice(player, 'EquipCardGuess',
                                                      'Have+NotHave')
                    local basic = false
                    local trick = false
                    local equip = false
                    for _, card in sgs.qlist(target:getHandcards()) do
                        if card:isKindOf('BasicCard') then
                            basic = true
                        elseif card:isKindOf('TrickCard') then
                            trick = true
                        elseif card:isKindOf('EquipCard') then
                            equip = true
                        end
                    end
                    local totalRight = 0
                    if (basic and choice1 == 'Have') or
                        (not basic and choice1 == 'NotHave') then
                        totalRight = totalRight + 1
                    end
                    if (trick and choice2 == 'Have') or
                        (not trick and choice2 == 'NotHave') then
                        totalRight = totalRight + 1
                    end
                    if (equip and choice3 == 'Have') or
                        (not equip and choice3 == 'NotHave') then
                        totalRight = totalRight + 1
                    end
                    if totalRight > 0 then
                        if totalRight > 1 then
                            if totalRight > 2 then
                                room:handleAcquireDetachSkills(player,
                                                               'jianxiong|xingshang')
                                room:addPlayerMark(player, 'LuaLingrenSkills')
                            end
                            player:drawCards(2)
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
                room:setCardFlag(data:toCardEffect().card,
                                 '-LuaLingrenAddDamage')
            end
        elseif event == sgs.TurnStart then
            if player:getMark('LuaLingrenSkills') > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:removePlayerMark(player, 'LuaLingrenSkills')
                room:handleAcquireDetachSkills(player, '-jianxiong|-xingshang')
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:removePlayerMark(player, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and
                   target:isAlive()
    end
}

LuaFujian = sgs.CreateTriggerSkill {
    name = 'LuaFujian',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local max = room:alivePlayerCount() - 1
            local index = math.random(1, max)
            local count = 1
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if count == index then
                    room:showAllCards(p, player)
                    break
                end
                count = count + 1
            end
        end
    end
}

Caoying:addSkill(LuaLingren)
Caoying:addSkill(LuaFujian)
Caoying:addRelateSkill('jianxiong')
Caoying:addRelateSkill('xingshang')

LuaYisuan = sgs.CreateTriggerSkill {
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
                    if room:getCardPlace(card:getEffectiveId()) ~=
                        sgs.Player_DiscardPile then
                        return false
                    end
                    local togain
                    if card:isVirtualCard() then
                        togain = sgs.Sanguosha:cloneCard('slash',
                                                         sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(card:getSubcards()) do
                            togain:addSubcard(id)
                        end
                    else
                        togain = sgs.Sanguosha:getCard(card:getSubcards()
                                                           :first())
                    end
                    if togain then
                        if effect.from:getMark(self:objectName()) == 0 then
                            if room:askForSkillInvoke(effect.from,
                                                      self:objectName(), data) then
                                room:addPlayerMark(effect.from,
                                                   self:objectName())
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
                local target = room:askForPlayerChosen(player, targets,
                                                       self:objectName(),
                                                       'LuaLangxi-choose', true,
                                                       true)
                if target then
                    local value = math.random(0, 2)
                    room:broadcastSkillInvoke(self:objectName())
                    if value == 0 then return false end
                    local damage = sgs.DamageStruct()
                    damage.from = player
                    damage.to = target
                    damage.damage = value
                    room:damage(damage)
                end
            end
        end
        return false
    end
}

Lijue:addSkill(LuaYisuan)
Lijue:addSkill(LuaLangxi)

LuaZishu = sgs.CreateTriggerSkill {
    name = "LuaZishu",
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if event == sgs.CardsMoveOneTime and
            not room:getTag("FirstRound"):toBool() and move.to and
            move.to:objectName() == player:objectName() then
            if player:getPhase() == sgs.Player_NotActive then
                for _, id in sgs.qlist(move.card_ids) do
                    if room:getCardOwner(id):objectName() == player:objectName() and
                        room:getCardPlace(id) == sgs.Player_PlaceHand then
                        room:addPlayerMark(player, self:objectName() .. id)
                    end
                end
            elseif player:getPhase() ~= sgs.Player_NotActive and
                move.reason.m_skillName ~= "LuaZishu" and RIGHT(self, player) then
                for _, id in sgs.qlist(move.card_ids) do
                    if room:getCardOwner(id):objectName() == player:objectName() and
                        room:getCardPlace(id) == sgs.Player_PlaceHand then
                        SendComLog(self, player, 1)
                        room:addPlayerMark(player, self:objectName() .. "engine")
                        if player:getMark(self:objectName() .. "engine") > 0 then
                            player:drawCards(1, self:objectName())
                            room:removePlayerMark(player,
                                                  self:objectName() .. "engine")
                            break
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to ==
            sgs.Player_NotActive then
            for _, p in
                sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit,
                                                      0)
                for _, card in sgs.list(p:getHandcards()) do
                    if p:getMark(self:objectName() .. card:getEffectiveId()) > 0 then
                        dummy:addSubcard(card:getEffectiveId())
                    end
                end
                if dummy:subcardsLength() > 0 then
                    SendComLog(self, p, 2)
                    room:addPlayerMark(p, self:objectName() .. "engine")
                    if p:getMark(self:objectName() .. "engine") > 0 then
                        room:throwCard(dummy,
                                       sgs.CardMoveReason(
                                           sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                           p:objectName(), self:objectName(),
                                           nil), p)
                        room:removePlayerMark(p, self:objectName() .. "engine")
                    end
                    if player:getNextAlive():objectName() == p:objectName() then
                        room:getThread():delay(500)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

LuaYingyuan = sgs.CreateTriggerSkill {
    name = 'LuaYingyuan',
    events = {sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "LuaYingyuan") and player:getMark(mark) >
                        0 then
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
                if card:isKindOf('SkillCard') then return false end
                if card and
                    effect.from:getMark(
                        'LuaYingyuan' .. card:objectName() .. '-Clear') == 0 then
                    if room:getCardPlace(card:getEffectiveId()) ~=
                        sgs.Player_DiscardPile then
                        return false
                    end

                    local togain
                    if card:isVirtualCard() then
                        togain = sgs.Sanguosha:cloneCard('slash',
                                                         sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(card:getSubcards()) do
                            togain:addSubcard(id)
                        end
                    else
                        togain = card
                    end
                    if togain then
                        local target = room:askForPlayerChosen(effect.from,
                                                               room:getOtherPlayers(
                                                                   effect.from),
                                                               'LuaYingyuan',
                                                               '@LuaYingyuanTo:' ..
                                                                   card:objectName(),
                                                               true, true)
                        if target then
                            room:obtainCard(target, togain)
                            room:addPlayerMark(effect.from, 'LuaYingyuan' ..
                                                   card:objectName() .. '-Clear')
                            room:broadcastSkillInvoke(self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end
}

Maliang:addSkill(LuaZishu)
Maliang:addSkill(LuaYingyuan)

LuaShanjiaCard = sgs.CreateSkillCard {
    name = 'LuaShanjiaCard',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do targets_list:append(target) end
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') or
                sgs.Sanguosha:getCard(id):isKindOf('TrickCard') then
                return #targets < 0
            end
        end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("shanjia")
        for _, cd in sgs.qlist(self:getSubcards()) do
            slash:addSubcard(cd)
        end
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, sgs.Self)
    end,
    feasible = function(self, targets)
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') or
                sgs.Sanguosha:getCard(id):isKindOf('TrickCard') then
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

LuaShanjiaVS = sgs.CreateViewAsSkill {
    name = 'LuaShanjia',
    n = 3,
    view_filter = function(self, selected, to_select)
        local x = 3 - sgs.Self:getMark('@luashanjia')
        return #selected < x and not sgs.Self:isJilei(to_select)
    end,
    view_as = function(self, cards)
        local x = 3 - sgs.Self:getMark('@luashanjia')
        if #cards ~= x then return nil end
        local card = LuaShanjiaCard:clone()
        for _, cd in ipairs(cards) do card:addSubcard(cd) end
        return card
    end,
    enabled_at_play = function() return false end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaShanjia')
    end
}

LuaShanjia = sgs.CreateTriggerSkill {
    name = 'LuaShanjia',
    view_as_skill = LuaShanjiaVS,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:drawCards(3)
                    room:askForUseCard(player, '@@LuaShanjia!',
                                       'LuaShanjia_throw', -1,
                                       sgs.Card_MethodNone)
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
    end
}

Caochun:addSkill(LuaShanjia)

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
                            local target =
                                room:askForPlayerChosen(p,
                                                        room:getAlivePlayers(),
                                                        'LuaZhongzuo',
                                                        '@LuaZhongzuoChoose',
                                                        true, true)
                            if target then
                                room:broadcastSkillInvoke(self:objectName())
                                target:drawCards(2)
                                if target:isWounded() then
                                    p:drawCards(1)
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
    can_trigger = function(self, target) return target end
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
            room:doAnimate(1, player:objectName(), dying.who:objectName())
            room:recover(dying.who,
                         sgs.RecoverStruct(player, nil, 1 - dying.who:getHp()))
            room:damage(sgs.DamageStruct(self:objectName(), player, current))
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and
                   target:hasSkill(self:objectName()) and
                   target:getMark('@LuaWanlan') > 0
    end
}

Jiakui:addSkill(LuaZhongzuo)
Jiakui:addSkill(LuaWanlan)

function cardGoBack(event, player, data, skill)
    if event == sgs.EventPhaseStart then
        return player:getPhase() == sgs.Player_Finish
    elseif event == sgs.Death then
        return data:toDeath().who:hasSkill(skill)
    end
    return false
end

LuaPojun = sgs.CreateTriggerSkill {
    name = 'LuaPojun',
    frequency = sgs.Skill_NotFrequent,
    events = {
        sgs.TargetSpecified, sgs.EventPhaseStart, sgs.Death, sgs.DamageCaused,
        sgs.BeforeCardsMove, sgs.CardsMoveOneTime
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('Slash') and RIGHT(self, player) then
                for _, t in sgs.qlist(use.to) do
                    local n = math.min(t:getCards('he'):length(), t:getHp())
                    local data2 = sgs.QVariant()
                    data2:setValue(t)
                    if n > 0 and
                        room:askForSkillInvoke(player, self:objectName(), data2) then
                        room:doAnimate(1, player:objectName(), t:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        local dis_num = {}
                        for i = 1, n, 1 do
                            table.insert(dis_num, tostring(i))
                        end
                        local discard_n = tonumber(
                                              room:askForChoice(player,
                                                                self:objectName(),
                                                                table.concat(
                                                                    dis_num, '+')))
                        room:doAnimate(1, player:objectName(), t:objectName())
                        if discard_n > 0 then
                            local orig_places = {}
                            local cards = sgs.IntList()
                            t:setFlags('olpojun_InTempMoving')
                            for i = 0, discard_n - 1, 1 do
                                local id =
                                    room:askForCardChosen(player, t, 'he',
                                                          self:objectName(),
                                                          false,
                                                          sgs.Card_MethodNone)
                                local place = room:getCardPlace(id)
                                orig_places[i] = place
                                cards:append(id)
                                t:addToPile('#LuaPojun', id, false)
                            end
                            for i = 0, discard_n - 1, 1 do
                                room:moveCardTo(
                                    sgs.Sanguosha:getCard(cards:at(i)), t,
                                    orig_places[i], false)
                            end
                            t:setFlags('-olpojun_InTempMoving')

                            local dummy =
                                sgs.Sanguosha:cloneCard('slash',
                                                        sgs.Card_NoSuit, 0)
                            dummy:addSubcards(cards)
                            t:addToPile('LuaPojun', dummy, false)
                        end
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.card and damage.card:isKindOf('Slash') and
                damage.from:hasSkill(self:objectName()) then
                if damage.from:getHandcardNum() >= damage.to:getHandcardNum() and
                    damage.from:getEquips():length() >=
                    damage.to:getEquips():length() then
                    damage.damage = damage.damage + 1
                    room:doAnimate(1, damage.from:objectName(),
                                   damage.to:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    room:notifySkillInvoked(player, self:objectName())
                    local msg = sgs.LogMessage()
                    msg.type = '#LuaPojunDamageUp'
                    msg.from = damage.from
                    msg.card_str = damage.card:toString()
                    room:sendLog(msg)
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
        elseif cardGoBack(event, player, data, self:objectName()) then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getPile('LuaPojun'):length() > 0 then
                    local to_obtain = sgs.IntList()
                    for _, id in sgs.qlist(p:getPile('LuaPojun')) do
                        to_obtain:append(id)
                    end
                    local dummy = sgs.Sanguosha:cloneCard('slash',
                                                          sgs.Card_NoSuit, 0)
                    dummy:addSubcards(to_obtain)
                    room:obtainCard(p, dummy, false)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return true end
}

JieXusheng:addSkill(LuaPojun)

LuaMashu = sgs.CreateTriggerSkill {
    name = 'LuaMashu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            if player:getPhase() == sgs.Player_Play and
                player:hasSkill(self:objectName()) then
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
                    if victims:isEmpty() then return false end
                    local victim = room:askForPlayerChosen(player, victims,
                                                           self:objectName(),
                                                           '@LuaMashuSlashTo',
                                                           true, true)
                    if victim then
                        local slash = sgs.Sanguosha:cloneCard('slash',
                                                              sgs.Card_NoSuit, 0)
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

LuaMashuDistance = sgs.CreateDistanceSkill {
    name = 'LuaMashuDistance',
    correct_func = function(self, from, to)
        if from:hasSkill('LuaMashu') then return -1 end
        return 0
    end
}

LuaQianxi = sgs.CreateTriggerSkill {
    name = 'LuaQianxi',
    events = {sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                for _, sp in sgs.qlist(room:getAlivePlayers()) do
                    if sp:distanceTo(player) <= 1 and
                        sp:hasSkill(self:objectName()) then
                        if room:askForSkillInvoke(sp, self:objectName()) then
                            -- sp:drawCards(1)
                            local userData = sgs.QVariant()
                            userData:setValue(sp)
                            local msg = sgs.LogMessage()
                            msg.from = room:getCurrent()
                            msg.to:append(sp)
                            if room:askForSkillInvoke(room:getCurrent(),
                                                      'LuaQianxiDraw', userData) then
                                msg.type = "#LuaQianxiDrawAccept"
                                room:sendLog(msg)
                                room:doAnimate(1,
                                               room:getCurrent():objectName(),
                                               sp:objectName())
                                sp:drawCards(1)

                            else
                                msg.type = '#LuaQianxiDrawRefuse'
                                room:sendLog(msg)
                            end

                            if not sp:isKongcheng() then
                                local card =
                                    room:askForCard(sp, ".|.|.|hand!",
                                                    "@LuaQianxi-discard",
                                                    sgs.QVariant(),
                                                    sgs.Card_MethodDiscard)
                                if card then
                                    local color = "."
                                    if card:isRed() then
                                        color = "red"
                                    elseif card:isBlack() then
                                        color = "black"
                                    end
                                    local victims = sgs.SPlayerList()
                                    for _, p in sgs.qlist(
                                                    room:getOtherPlayers(sp)) do
                                        if sp:distanceTo(p) == 1 then
                                            victims:append(p)
                                        end
                                    end
                                    if not victims:isEmpty() then
                                        local victim =
                                            room:askForPlayerChosen(sp, victims,
                                                                    self:objectName(),
                                                                    "@LuaQianxi-choose",
                                                                    false, true)
                                        if victim then
                                            local pattern = ".|" .. color ..
                                                                "|.|hand"
                                            if player:getMark("@qianxi_red") > 0 and
                                                color == "black" then
                                                pattern = ".|" .. "." ..
                                                              "|.|hand"
                                            end
                                            if player:getMark("@qianxi_black") >
                                                0 and color == "red" then
                                                pattern = ".|" .. "." ..
                                                              "|.|hand"
                                            end
                                            room:doAnimate(1, sp:objectName(),
                                                           victim:objectName())
                                            room:broadcastSkillInvoke(
                                                self:objectName())
                                            room:addPlayerMark(victim,
                                                               "@qianxi_" ..
                                                                   color)
                                            room:setPlayerCardLimitation(victim,
                                                                         "use, response",
                                                                         pattern,
                                                                         false)
                                            local msg = sgs.LogMessage()
                                            msg.type = '#Qianxi'
                                            msg.from = victim
                                            msg.arg = color
                                            room:sendLog(msg)
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
                if data:toDeath().who:objectName() ~= player:objectName() or
                    not data:toDeath().who:hasSkill(self:objectName()) then
                    return false
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark('@qianxi_red') > 0 or p:getMark('@qianxi_black') >
                    0 then
                    p:clearCardLimitation(false)
                    room:setPlayerMark(p, "@qianxi_red", 0)
                    room:setPlayerMark(p, "@qianxi_black", 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

JieMadai:addSkill(LuaMashu)
JieMadai:addSkill(LuaQianxi)

LuaJingxieCard = sgs.CreateSkillCard {
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

LuaJingxieVS = sgs.CreateViewAsSkill {
    name = 'LuaJingxie',
    n = 1,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            if sgs.Self:getMark(to_select:objectName()) == 1 then
                return nil
            end
            return to_select:isKindOf('Armor') or to_select:objectName() ==
                       'crossbow'
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

LuaJingxie = sgs.CreateTriggerSkill {
    name = 'LuaJingxie',
    view_as_skill = LuaJingxieVS,
    events = {
        sgs.Dying, sgs.CardsMoveOneTime, sgs.CardEffected, sgs.AskForRetrial,
        sgs.ChainStateChange
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Dying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                room:filterCards(player, player:getCards('he'), true)
                local card = room:askForCard(player, 'Armor|.|.|.',
                                             'LuaJingxie-Invoke', data,
                                             sgs.Card_MethodRecast)
                if card then
                    room:moveCardTo(card, player, nil, sgs.Player_DiscardPile,
                                    sgs.CardMoveReason(
                                        sgs.CardMoveReason_S_REASON_RECAST,
                                        player:objectName(), card:objectName(),
                                        ""))
                    local log = sgs.LogMessage()
                    log.type = "#UseCard_Recast"
                    log.from = player
                    log.card_str = card:getEffectiveId()
                    room:sendLog(log)
                    room:broadcastSkillInvoke("@recast")
                    player:drawCards(1, "recast")
                    room:recover(dying.who, sgs.RecoverStruct(player, nil, 1 -
                                                                  dying.who:getHp()))
                    room:broadcastSkillInvoke(self:objectName(), 1)
                end
                room:filterCards(player, player:getCards('he'), false)
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceEquip)) then
                for i = 0, move.card_ids:length() - 1, 1 do
                    if move.from_places:at(i) == sgs.Player_PlaceEquip then
                        local card = sgs.Sanguosha:getCard(move.card_ids:at(i))
                        if card:isKindOf('Armor') or card:objectName() ==
                            'crossbow' then
                            if player:getMark(card:objectName()) > 0 then
                                room:removePlayerMark(player, card:objectName())
                                if card:objectName() == 'silver_lion' then
                                    room:sendCompulsoryTriggerLog(player,
                                                                  self:objectName())
                                    player:drawCards(2)
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
                    local log = sgs.LogMessage()
                    log.type = '#LuaJingxie-Renwang'
                    log.from = player
                    log.to:append(effect.from)
                    log.arg = card:objectName()
                    room:sendLog(log)
                    return true
                end
            end
        elseif event == sgs.AskForRetrial then
            local judge = data:toJudge()
            if judge.who:getMark('eight_diagram') == 0 then
                return false
            end
            if judge.reason ~= 'eight_diagram' then return false end
            if judge.card:getSuit() == sgs.Card_Club then
                local card = sgs.Sanguosha:getWrappedCard(judge.card:getId())
                card:setSkillName(self:objectName())
                card:setSuit(sgs.Card_Heart)
                card:setModified(true)
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastUpdateCard(room:getAllPlayers(true),
                                         judge.card:getId(), card)
                judge:updateResult()
            end
        elseif event == sgs.ChainStateChange then
            if player:getMark('vine') == 0 then return false end
            if not player:isChained() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                return true
            end
        end
        return false
    end
}

LuaJingxieTargetMod = sgs.CreateTargetModSkill {
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

LuaQiaosiCard = sgs.CreateSkillCard {
    name = 'LuaQiaosiCard',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets) return #targets >= 0 end,
    on_use = function(self, room, source, targets)
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        local to_goback = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(self:getSubcards()) do
            to_goback:addSubcard(cd)
        end
        if targets_list:length() > 0 then
            local target = targets[1]
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                                              source:objectName(),
                                              target:objectName(),
                                              self:objectName(), nil)
            room:moveCardTo(to_goback, source, target, sgs.Player_PlaceHand,
                            reason, true)
        else
            room:throwCard(to_goback, source)
        end
    end
}

LuaQiaosiStartCard = sgs.CreateSkillCard {
    name = 'LuaQiaosiStartCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaQiaosi', math.random(1, 2))
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        local marks = LuaDoQiaosiShow(room, source, dummy)
        if marks > 0 then
            room:addPlayerMark(source, 'LuaQiaosiCardsNum', marks)
            room:addPlayerMark(source, 'LuaQiaosiGiven')
            math.randomseed(os.time())
            room:askForUseCard(source, '@@LuaQiaosi!', 'LuaQiaosi_give:' ..
                                   source:getMark('LuaQiaosiCardsNum'), -1,
                               sgs.Card_MethodNone)
            room:removePlayerMark(source, 'LuaQiaosiGiven')
            room:setPlayerMark(source, 'LuaQiaosiCardsNum', 0)
        end
    end
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
                for _, cd in ipairs(cards) do card:addSubcard(cd) end
                return card
            end
        else
            if #cards == 0 then return LuaQiaosiStartCard:clone() end
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

Majun:addSkill(LuaJingxie)
Majun:addSkill(LuaQiaosi)

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
        math.randomseed(os.time())
        room:broadcastSkillInvoke('LuaJijie', math.random(1, 2))
        local card = sgs.Sanguosha:getCard(id)
        local target = room:askForPlayerChosen(source,
                                               room:getOtherPlayers(source),
                                               'LuaJijie',
                                               '@LuaJijiePlayer-Chosen', true,
                                               true)
        if target then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                                              source:objectName(),
                                              target:objectName(), 'LuaJijie',
                                              nil)
            room:clearAG()
            room:moveCardTo(card, source, target, sgs.Player_PlaceHand, reason,
                            false)
        else
            local reason = sgs.CardMoveReason(
                               sgs.CardMoveReason_S_REASON_PREVIEWGIVE,
                               source:objectName(), source:objectName(),
                               'LuaJijie', nil)
            room:clearAG()
            room:moveCardTo(card, source, source, sgs.Player_PlaceHand, reason,
                            false)
        end
    end
}

LuaJijie = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaJijie',
    view_as = function(self, cards) return LuaJijieCard:clone() end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaJijieCard')
    end
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
                math.randomseed(os.time())
                room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                room:doAnimate(1, player:objectName(), dying.who:objectName())
                dying.who:drawCards(1)
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() ~= player:objectName() then
                if move.from and move.from:objectName() == player:objectName() then
                    local reason = move.reason.m_reason
                    if reason == sgs.CardMoveReason_S_REASON_GIVE or reason ==
                        sgs.CardMoveReason_S_REASON_PREVIEWGIVE then
                        local target
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:objectName() == move.to:objectName() then
                                target = p
                                break
                            end
                        end
                        local data2 = sgs.QVariant()
                        data2:setValue(target)
                        if room:askForSkillInvoke(player, self:objectName(),
                                                  data2) then
                            room:broadcastSkillInvoke(self:objectName())
                            room:doAnimate(1, player:objectName(),
                                           target:objectName())
                            target:drawCards(1)
                        end
                    end
                end
            end
        end
    end
}

Yiji:addSkill(LuaJijie)
Yiji:addSkill(LuaJiyuan)

LuaTunchuCard = sgs.CreateSkillCard {
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

LuaTunchuVS = sgs.CreateViewAsSkill {
    name = 'LuaTunchu',
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card = LuaTunchuCard:clone()
        for _, cd in ipairs(cards) do card:addSubcard(cd) end
        return card
    end,
    enabled_at_play = function(self, player) return false end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaTunchu'
    end
}

LuaTunchu = sgs.CreateTriggerSkill {
    name = 'LuaTunchu',
    view_as_skill = LuaTunchuVS,
    events = {
        sgs.DrawNCards, sgs.EventPhaseEnd, sgs.EventLoseSkill,
        sgs.EventAcquireSkill, sgs.CardsMoveOneTime
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
                room:askForUseCard(player, '@@LuaTunchu', '@LuaTunchu', -1,
                                   sgs.Card_MethodNone)
                player:setFlags('-LuaTunchuInvoked')
            end
        elseif event == sgs.EventLoseSkill then
            if data:toString() == 'LuaTunchu' then
                room:removePlayerCardLimitation(player, 'use', 'Slash|.|.|.$0')
            end
        elseif event == sgs.EventAcquireSkill then
            if data:toString() == 'LuaTunchu' then
                if player:getPile('LuaLiang'):length() > 0 then
                    room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.',
                                                 false)
                end
            end
        elseif event == sgs.CardsMoveOneTime and
            player:hasSkill(self:objectName()) and player:isAlive() then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and
                move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name ==
                'LuaLiang' then
                if player:getPile('LuaLiang'):length() == 1 then
                    room:setPlayerCardLimitation(player, 'use', 'Slash|.|.|.',
                                                 false)
                end
            elseif move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceSpecial) then
                if player:getPile('LuaLiang'):length() == 0 then
                    room:removePlayerCardLimitation(player, 'use',
                                                    'Slash|.|.|.$0')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

LuaShuliangCard = sgs.CreateSkillCard {
    name = 'LuaShuliangCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('LuaShuliang')
        local current = room:getCurrent()
        room:doAnimate(1, source:objectName(), current:objectName())
        current:drawCards(2)
    end
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
    end
}

LuaShuliang = sgs.CreateTriggerSkill {
    name = 'LuaShuliang',
    view_as_skill = LuaShuliangVS,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Finish then return false end
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
    can_trigger = function(self, target) return target end
}

Lifeng:addSkill(LuaTunchu)
Lifeng:addSkill(LuaShuliang)

LuaYizanCard = sgs.CreateSkillCard {
    name = "LuaYizanCard",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local players = sgs.PlayerList()
        for i = 1, #targets do players:append(targets[i]) end
        if sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = nil
            if self:getUserString() and self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(
                           self:getUserString():split("+")[1])
                return
                    card and card:targetFilter(players, to_select, sgs.Self) and
                        not sgs.Self:isProhibited(to_select, card, players)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local _card = sgs.Self:getTag("LuaYizan"):toCard()
        if _card == nil then return false end
        local card = sgs.Sanguosha:cloneCard(_card)
        -- card:setCanRecast(false)
        card:deleteLater()
        return card and card:targetFilter(players, to_select, sgs.Self) and
                   not sgs.Self:isProhibited(to_select, card, players)
    end,
    feasible = function(self, targets)
        local players = sgs.PlayerList()
        for i = 1, #targets do players:append(targets[i]) end
        if sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = nil
            if self:getUserString() and self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(
                           self:getUserString():split("+")[1])
                return card and card:targetsFeasible(players, sgs.Self)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local _card = sgs.Self:getTag("LuaYizan"):toCard()
        if _card == nil then return false end
        local card = sgs.Sanguosha:cloneCard(_card)
        -- card:setCanRecast(false)
        card:deleteLater()
        return card and card:targetsFeasible(players, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local to_use = self:getUserString()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:addPlayerMark(source, "LuaYizanUse")
        if to_use == "slash" and sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local use_list = {}
            table.insert(use_list, "slash")
            local sts = sgs.GetConfig("BanPackages", "")
            if not string.find(sts, "maneuvering") then
                table.insert(use_list, "normal_slash")
                table.insert(use_list, "thunder_slash")
                table.insert(use_list, "fire_slash")
            end
            to_use = room:askForChoice(source, "yizan_slash",
                                       table.concat(use_list, "+"))
            source:setTag("YizanSlash", sgs.QVariant(to_use))
        end
        local user_str = to_use
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(),
                                                 card:getNumber())
        if use_card == nil then
            use_card = sgs.Sanguosha:cloneCard('slash', card:getSuit(),
                                               card:getNumber())
        end
        use_card:setSkillName("LuaYizan")
        use_card:addSubcards(self:getSubcards())
        use_card:deleteLater()
        local tos = card_use.to
        for _, to in sgs.qlist(tos) do
            local skill = room:isProhibited(source, to, use_card)
            if skill then card_use.to:removeOne(to) end
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:addPlayerMark(source, 'LuaYizanUse')
        local to_use = ""
        if self:getUserString() == "peach+analeptic" then
            local use_list = {}
            table.insert(use_list, "peach")
            local sts = sgs.GetConfig("BanPackages", "")
            if not string.find(sts, "maneuvering") then
                table.insert(use_list, "analeptic")
            end
            to_use = room:askForChoice(source, "yizan_saveself",
                                       table.concat(use_list, "+"))
            source:setTag("YizanSaveSelf", sgs.QVariant(to_use))
        elseif self:getUserString() == "slash" then
            local use_list = {}
            table.insert(use_list, "slash")
            local sts = sgs.GetConfig("BanPackages", "")
            if not string.find(sts, "maneuvering") then
                table.insert(use_list, "normal_slash")
                table.insert(use_list, "thunder_slash")
                table.insert(use_list, "fire_slash")
            end
            to_use = room:askForChoice(source, "yizan_slash",
                                       table.concat(use_list, "+"))
            source:setTag("YizanSlash", sgs.QVariant(to_use))
        else
            to_use = self:getUserString()
        end
        local user_str = ""
        if to_use == "slash" then
            user_str = "slash"
        elseif to_use == "normal_slash" then
            user_str = "slash"
        else
            user_str = to_use
        end
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(),
                                                 card:getNumber())
        use_card:setSkillName("LuaYizan")
        use_card:addSubcards(self:getSubcards())
        use_card:deleteLater()
        return use_card
    end
}

LuaYizanVS = sgs.CreateViewAsSkill {
    name = "LuaYizan",
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
        if not current then return false end
        if string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
            return false
        end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then
            return false
        end
        if pattern == "nullification" then return false end
        if string.find(pattern, "[%u%d]") then return false end -- 这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
        return true
    end,
    enabled_at_play = function(self, player)
        return player:isWounded() or sgs.Slash_IsAvailable(player) or
                   not player:hasUsed('Analeptic')
    end,
    enabled_at_nullification = function(self, player) return false end,
    view_as = function(self, cards)
        if sgs.Self:getMark('LuaLongyuan') == 0 then
            if #cards < 2 then return nil end
        else
            if #cards < 1 then return nil end
        end

        if sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = LuaYizanCard:clone()
            card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            for _, cd in ipairs(cards) do card:addSubcard(cd) end
            return card
        end
        local c = sgs.Self:getTag("LuaYizan"):toCard()
        if c then
            local card = LuaYizanCard:clone()
            card:setUserString(c:objectName())
            for _, cd in ipairs(cards) do card:addSubcard(cd) end
            return card
        else
            return nil
        end
    end
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
    end
}

LuaYizan:setGuhuoDialog("l")
LuaLongyuan = sgs.CreateTriggerSkill {
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
        return (target and target:isAlive() and
                   target:hasSkill(self:objectName())) and
                   (target:getMark('LuaLongyuan') == 0) and
                   (target:getMark('LuaYizanUse') >= 3) and
                   (target:getPhase() == sgs.Player_Start)
    end
}

ZhaotongZhaoguang:addSkill(LuaYizan)
ZhaotongZhaoguang:addSkill(LuaLongyuan)

LuaShuangxiongVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaShuangxiong',
    view_filter = function(self, to_select)
        if to_select:isEquipped() then return false end
        local value = sgs.Self:getMark("LuaShuangxiong")
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
        local duel = sgs.Sanguosha:cloneCard('duel', card:getSuit(),
                                             card:getNumber())
        duel:addSubcard(card)
        duel:setSkillName(self:objectName())
        return duel
    end,
    enabled_at_play = function(self, player)
        return player:getMark('LuaShuangxiong') > 0 and not player:isKongcheng()
    end
}

LuaShuangxiong = sgs.CreateTriggerSkill {
    name = 'LuaShuangxiong',
    view_as_skill = LuaShuangxiongVS,
    events = {
        sgs.EventPhaseStart, sgs.Damaged, sgs.CardResponded, sgs.CardUsed,
        sgs.CardFinished
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                room:setPlayerMark(player, "LuaShuangxiong", 0)
            elseif player:getPhase() == sgs.Player_Draw then
                if player:hasSkill(self:objectName()) then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName())
                        local card_ids = room:getNCards(2)
                        local to_get = sgs.IntList()
                        local to_throw = sgs.IntList()
                        room:fillAG(card_ids)
                        while not card_ids:isEmpty() do
                            local card_id =
                                room:askForAG(player, card_ids, false,
                                              self:objectName())
                            card_ids:removeOne(card_id)
                            to_get:append(card_id)
                            local card = sgs.Sanguosha:getCard(card_id)
                            if card:isRed() then
                                room:setPlayerMark(player, "LuaShuangxiong", 1)
                            else
                                room:setPlayerMark(player, "LuaShuangxiong", 2)
                            end
                            room:takeAG(player, card_id, false)
                            local _card_ids = card_ids
                            for _, id in sgs.qlist(_card_ids) do
                                card_ids:removeOne(id)
                                to_throw:append(id)
                                room:takeAG(nil, id, false)
                            end
                        end
                        local dummy = sgs.Sanguosha:cloneCard('slash',
                                                              sgs.Card_NoSuit, 0)
                        if not to_get:isEmpty() then
                            dummy:addSubcards(getCardList(to_get))
                            player:obtainCard(dummy)
                        end
                        dummy:clearSubcards()
                        if not to_throw:isEmpty() then
                            dummy:addSubcards(getCardList(to_throw))
                            local reason = sgs.CardMoveReason(
                                               sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                               player:objectName(),
                                               self:objectName(), "")
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
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        local dummy = sgs.Sanguosha:cloneCard('slash',
                                                              sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(room:getDiscardPile()) do
                            local card = sgs.Sanguosha:getCard(id)
                            if card:hasFlag('LuaShuangxiongResponded') then
                                dummy:addSubcard(card)
                            end
                        end
                        damage.to:obtainCard(dummy)
                    end
                end
            end
        elseif event == sgs.CardResponded then
            local resp = data:toCardResponse()
            if resp.m_who and resp.m_who:hasFlag('LuaShuangxiongInvoke') then
                if resp.m_card:isVirtualCard() then
                    for _, id in sgs.qlist(resp.m_card:getSubcards()) do
                        room:setCardFlag(sgs.Sanguosha:getCard(id),
                                         'LuaShuangxiongResponded')
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
    can_trigger = function(self, target) return target end
}

JieYanliangWenchou:addSkill(LuaShuangxiong)

LuaXuanfengCard = sgs.CreateSkillCard {
    name = "LuaXuanfengCard",
    filter = function(self, targets, to_select)
        if #targets >= 2 then return false end
        if to_select:objectName() == sgs.Self:objectName() then
            return false
        end
        return sgs.Self:canDiscard(to_select, "he")
    end,
    on_use = function(self, room, source, targets)
        local map = {}
        local totaltarget
        for _, sp in ipairs(targets) do map[sp] = 1 end
        totaltarget = #targets
        room:broadcastSkillInvoke('LuaXuanfeng')
        if totaltarget == 1 then
            for _, sp in ipairs(targets) do map[sp] = map[sp] + 1 end
        end
        for _, sp in ipairs(targets) do
            while map[sp] > 0 do
                if source:isAlive() and sp:isAlive() and
                    source:canDiscard(sp, "he") then
                    local card_id = room:askForCardChosen(source, sp, "he",
                                                          'LuaXuanfeng', false,
                                                          sgs.Card_MethodDiscard)
                    room:doAnimate(1, source:objectName(), sp:objectName())
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
            local target = room:askForPlayerChosen(source, damageAvailable,
                                                   'LuaXuanfeng',
                                                   'LuaXuanfengDamage-choose',
                                                   true, true)
            if target then
                local damage = sgs.DamageStruct()
                damage.from = source
                damage.to = target
                damage.damage = 1
                room:damage(damage)
                room:broadcastSkillInvoke('LuaXuanfeng')
            end
        end
    end
}

LuaXuanfengVS = sgs.CreateViewAsSkill {
    name = "LuaXuanfeng",
    n = 0,
    view_as = function() return LuaXuanfengCard:clone() end,
    enabled_at_play = function() return false end,
    enabled_at_response = function(self, target, pattern)
        return pattern == "@@LuaXuanfeng"
    end
}

LuaXuanfeng = sgs.CreateTriggerSkill {
    name = "LuaXuanfeng",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    view_as_skill = LuaXuanfengVS,
    on_trigger = function(self, event, player, data)
        if event == sgs.EventPhaseStart then
            player:setMark("LuaXuanfeng", 0)
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (not move.from) or
                (move.from:objectName() ~= player:objectName()) then
                return false
            end
            if (move.to_place == sgs.Player_DiscardPile) and
                (player:getPhase() == sgs.Player_Discard) and
                (bit32.band(move.reason.m_reason,
                            sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                    sgs.CardMoveReason_S_REASON_DISCARD) then
                player:setMark("LuaXuanfeng", player:getMark("LuaXuanfeng") +
                                   move.card_ids:length())
            end
            if ((player:getMark("LuaXuanfeng") >= 2) and
                (not player:hasFlag("LuaXuanfengUsed"))) or
                move.from_places:contains(sgs.Player_PlaceEquip) then
                local room = player:getRoom()
                local targets = sgs.SPlayerList()
                for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:canDiscard(target, "he") then
                        targets:append(target)
                    end
                end
                if targets:isEmpty() then return false end
                -- player:setFlags("LuaXuanfengUsed") --这是源码Bug的地方
                if player:getPhase() == sgs.Player_Discard then
                    player:setFlags("LuaXuanfengUsed")
                end -- 修复源码Bug
                room:askForUseCard(player, "@@LuaXuanfeng", "@xuanfeng-card")
            end
        end
        return false
    end
}

JieLingtong:addSkill(LuaXuanfeng)
JieLingtong:addSkill('yongjin')

LuaShouye = sgs.CreateTriggerSkill {
    name = 'LuaShouye',
    events = {sgs.TargetSpecified, sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf('SkillCard') or use.to:length() > 1 or
                use.to:contains(use.from) then return false end
            for _, p in sgs.qlist(use.to) do
                if p:getMark(self:objectName()) == 0 and
                    p:hasSkill(self:objectName()) then
                    local data2 = sgs.QVariant()
                    data2:setValue(use.from)
                    if room:askForSkillInvoke(p, self:objectName(), data2) then
                        room:addPlayerMark(p, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        room:doAnimate(1, p:objectName(), use.from:objectName())
                        local choice1 = room:askForChoice(use.from, 'LuaShouye',
                                                          'syjg1+syjg2')
                        local choice2 = room:askForChoice(p, 'LuaShouye',
                                                          'syfy1+syfy2')
                        ChoiceLog(use.from, choice1, nil)
                        ChoiceLog(p, choice2, nil)
                        if (choice1 == 'syjg1' and choice2 == 'syfy1') or
                            (choice1 == 'syjg2' and choice2 == 'syfy2') then
                            local log = sgs.LogMessage()
                            log.from = p
                            log.type = '#ShouyeSucceed'
                            room:sendLog(log)
                            local nullified_list = use.nullified_list
                            table.insert(nullified_list, p:objectName())
                            use.nullified_list = nullified_list
                            data:setValue(use)
                            local togain
                            if use.card:isVirtualCard() then
                                togain =
                                    sgs.Sanguosha:cloneCard('slash',
                                                            sgs.Card_NoSuit, 0)
                                for _, id in sgs.qlist(use.card:getSubcards()) do
                                    togain:addSubcard(id)
                                end
                            else
                                togain = use.card
                            end
                            room:obtainCard(p, togain)
                        else
                            local log = sgs.LogMessage()
                            log.from = p
                            log.type = '#ShouyeFailed'
                            room:sendLog(log)
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
    can_trigger = function(self, target) return target end
}

LuaLiezhiCard = sgs.CreateSkillCard {
    name = 'LuaLiezhicard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected <= 1 and to_select:objectName() ~=
                   sgs.Self:objectName() and
                   sgs.Self:canDiscard(to_select, "hej")
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("LuaLiezhi")
        for _, p in ipairs(targets) do
            local card_id = room:askForCardChosen(source, p, "hej", 'LuaLiezhi',
                                                  false, sgs.Card_MethodDiscard)
            room:doAnimate(1, source:objectName(), p:objectName())
            room:throwCard(card_id, p, source)
        end
    end
}

LuaLiezhiVS = sgs.CreateViewAsSkill {
    name = 'LuaLiezhi',
    n = 0,
    view_as = function() return LuaLiezhiCard:clone() end,
    enabled_at_play = function() return false end,
    enabled_at_response = function(self, target, pattern)
        return pattern == "@@LuaLiezhi"
    end
}

LuaLiezhi = sgs.CreateTriggerSkill {
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
                            room:askForUseCard(player, "@@LuaLiezhi",
                                               "@LuaLiezhi")
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

Shenpei:addSkill(LuaShouye)
Shenpei:addSkill(LuaLiezhi)

LuaZhaohan = sgs.CreateTriggerSkill {
    name = 'LuaZhaohan',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getMark(self:objectName() .. 'up') < 4 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:setPlayerProperty(player, 'maxhp',
                                       sgs.QVariant(player:getMaxHp() + 1))
                local msg = sgs.LogMessage()
                msg.type = '#addmaxhp'
                msg.arg = 1
                msg.from = player
                room:sendLog(msg)
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

LuaRangjie = sgs.CreateTriggerSkill {
    name = 'LuaRangjie',
    events = {sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        for i = 0, damage.damage - 1, 1 do
            local choices = 'obtainBasic+obtainTrick+obtainEquip'
            if CanMoveCard(room) then
                choices = 'moveOneCard+' .. choices
            end
            local choice = room:askForChoice(player, self:objectName(), choices)
            local params = {['existed'] = {}, ['findDiscardPile'] = true}
            if choice == 'moveOneCard' then
                local fromPlayers = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getJudgingArea():length() > 0 or p:getEquips():length() >
                        0 then fromPlayers:append(p) end
                end
                if fromPlayers:isEmpty() then return false end
                local from = room:askForPlayerChosen(player, fromPlayers,
                                                     self:objectName(),
                                                     '@LuaRangjieMoveFrom',
                                                     false, true)
                if from then
                    local card_id = room:askForCardChosen(player, from, 'ej',
                                                          self:objectName())
                    local card = sgs.Sanguosha:getCard(card_id)
                    local place = room:getCardPlace(card_id)
                    local equip_index = -1
                    if place == sgs.Player_PlaceEquip then
                        local equip = card:getRealCard():toEquipCard()
                        equip_index = equip:location()
                    end
                    local tos = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if equip_index ~= -1 then
                            if not p:getEquip(equip_index) then
                                tos:append(p)
                            end
                        else
                            if not player:isProhibited(p, card) and
                                not p:containsTrick(card:objectName()) then
                                tos:append(p)
                            end
                        end
                    end
                    if not tos:isEmpty() then
                        local to = room:askForPlayerChosen(player, tos,
                                                           self:objectName(),
                                                           '@LuaRangjieMoveTo',
                                                           false, true)
                        if to then
                            room:moveCardTo(card, from, to, place,
                                            sgs.CardMoveReason(
                                                sgs.CardMoveReason_S_REASON_TRANSFER,
                                                player:objectName(),
                                                self:objectName(), ''))
                        end
                    end
                end
            else
                params['type'] = string.gsub(choice, 'obtain', '') .. 'Card'
                local card = obtainTargetedTypeCard(room, params)
                if card then player:obtainCard(card) end
            end
            player:drawCards(1)
            room:broadcastSkillInvoke(self:objectName())
        end
        return false
    end
}

LuaYizhengCard = sgs.CreateSkillCard {
    name = 'LuaYizhengCard',
    filter = function(self, selected, to_select)
        if #selected < 1 then
            return to_select:getHp() <= sgs.Self:getHp() and
                       (not to_select:isKongcheng()) and to_select:objectName() ~=
                       sgs.Self:objectName()
        end
        return false
    end,

    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke('LuaYizheng')
        if source:pindian(target, 'LuaYizheng', nil) then
            room:addPlayerMark(target, 'LuaYizhengSkipDrawPhase')
        else
            room:loseMaxHp(source)
        end
    end
}

LuaYizhengVS = sgs.CreateViewAsSkill {
    name = 'LuaYizheng',
    n = 0,
    view_as = function(self, cards) return LuaYizhengCard:clone() end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getSiblings()) do
            if not p:isKongcheng() and p:objectName() ~= player:objectName() and
                p:getHp() <= player:getHp() then
                return not player:hasUsed('#LuaYizhengCard')
            end
        end
        return false
    end
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
    can_trigger = function(self, target) return target end
}

Yangbiao:addSkill(LuaZhaohan)
Yangbiao:addSkill(LuaRangjie)
Yangbiao:addSkill(LuaYizheng)

LuaQinzheng = sgs.CreateTriggerSkill {
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
        if card:isKindOf('SkillCard') then return false end
        room:addPlayerMark(player, '@' .. self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        local markNum = player:getMark('@' .. self:objectName())
        local card1 = LuaQinzhengGetCard(room, markNum, 3, 'Slash', 'Jink')
        if card1 then player:obtainCard(card1) end
        local card2 = LuaQinzhengGetCard(room, markNum, 5, 'Peach', 'Analeptic')
        if card2 then player:obtainCard(card2) end
        local card3 = LuaQinzhengGetCard(room, markNum, 8, 'Duel', 'ExNihilo')
        if card3 then player:obtainCard(card3) end
        return false
    end
}

Luotong:addSkill(LuaQinzheng)

LuaZhiyi = sgs.CreateTriggerSkill {
    name = 'LuaZhiyi',
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                for _, sp in sgs.qlist(room:findPlayersBySkillName(
                                           self:objectName())) do
                    if sp:getMark(self:objectName() .. 'invoked') > 0 then
                        room:setPlayerMark(sp, self:objectName() .. 'invoked', 0)
                        room:broadcastSkillInvoke(self:objectName())
                        room:sendCompulsoryTriggerLog(sp, self:objectName())
                        local cardTypes = {}
                        for _, mark in sgs.list(sp:getMarkNames()) do
                            if string.find(mark, self:objectName()) and
                                sp:getMark(mark) > 0 then
                                local type = string.gsub(mark,
                                                         self:objectName(), '')
                                if type == 'peach' and sp:isWounded() then
                                    table.insert(cardTypes, type)
                                elseif type == 'analeptic' then
                                    table.insert(cardTypes, type)
                                elseif type ~= 'jink' then
                                    for _, p in sgs.qlist(
                                                    room:getOtherPlayers(sp)) do
                                        if sp:inMyAttackRange(p) then
                                            table.insert(cardTypes, type)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        table.insert(cardTypes, 'linyindraw')
                        local choice = room:askForChoice(sp, self:objectName(),
                                                         table.concat(cardTypes,
                                                                      '+'))
                        if choice == 'linyindraw' then
                            sp:drawCards(1)
                        elseif choice == 'peach' or choice == 'analeptic' then
                            local card =
                                sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit,
                                                        0)
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
                                    room:askForPlayerChosen(sp, players,
                                                            self:objectName(),
                                                            'LuaZhiyiSlashTo')
                                if target then
                                    local card =
                                        sgs.Sanguosha:cloneCard(choice,
                                                                sgs.Card_NoSuit,
                                                                0)
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
                            if string.find(mark, self:objectName()) and
                                sp:getMark(mark) > 0 then
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
                room:addPlayerMark(player,
                                   self:objectName() .. card:objectName())
                room:addPlayerMark(player, self:objectName() .. 'invoked')
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

Zhangyi:addSkill(LuaZhiyi)

LuaJuece = sgs.CreateTriggerSkill {
    name = 'LuaJuece',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() ==
                room:getCurrent():objectName() then return false end
            if (move.from and (move.from:objectName() == player:objectName()) and
                (move.from_places:contains(sgs.Player_PlaceHand) or
                    move.from_places:contains(sgs.Player_PlaceEquip))) and
                not (move.to and
                    (move.to:objectName() == player:objectName() and
                        (move.to_place == sgs.Player_PlaceHand or move.to_place ==
                            sgs.Player_PlaceEquip))) then
                room:addPlayerMark(player, '@' .. self:objectName())
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                if player:hasSkill(self:objectName()) then
                    local victims = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark('@' .. self:objectName()) > 0 then
                            victims:append(p)
                        end
                    end
                    if victims:isEmpty() then return false end
                    local victim = room:askForPlayerChosen(player, victims,
                                                           self:objectName(),
                                                           '@LuaJueceDamageTo',
                                                           true, true)
                    if victim then
                        room:broadcastSkillInvoke(self:objectName())
                        room:damage(sgs.DamageStruct(self:objectName(), player,
                                                     victim))
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, '@' .. self:objectName(), 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target) return target end
}

LuaMiejiCard = sgs.CreateSkillCard {
    name = 'LuaMiejiCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:objectName() ~= sgs.Self:objectName() and
                       not to_select:isNude()
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]

        room:broadcastSkillInvoke('LuaMieji')
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
                                          source:objectName(), '', 'LuaMieji',
                                          '')
        room:moveCardTo(sgs.Sanguosha:getCard(self:getSubcards():first()),
                        source, nil, sgs.Player_DrawPile, reason, true)
        local cards = target:getCards('he')
        local cardsCopy = cards

        for _, c in sgs.qlist(cardsCopy) do
            if target:isJilei(c) then cards:removeOne(c) end
        end

        if cards:isEmpty() then return end

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

        if nonTrickNum < 2 and trickExists then pattern = 'TrickCard!' end

        local card = room:askForCard(target, pattern, '@LuaMiejiDiscard',
                                     sgs.QVariant(), sgs.Card_MethodNone)
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
            room:askForDiscard(target, 'LuaMieji', 1, 1, false, true,
                               '@LuaMiejiDiscardNonTrick', '^TrickCard')
        end
    end
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
    end
}

LuaFenchengCard = sgs.CreateSkillCard {
    name = 'LuaFenchengCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        source:loseMark('@burn')
        room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
        room:broadcastSkillInvoke('LuaFencheng')
        room:setEmotion(source, 'skill/fencheng')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            room:doAnimate(1, source:objectName(), p:objectName())
        end
        room:getThread():delay(4000)
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                local length = room:getTag('LuaFenchengDiscard'):toInt() + 1
                if not p:canDiscard(p, 'he') or p:getCardCount(true) < length or
                    not room:askForDiscard(p, 'fencheng', 10000, length, true,
                                           true, '@fencheng:::' .. length) then
                    room:setTag('LuaFenchengDiscard', sgs.QVariant(0))
                    local damage = sgs.DamageStruct()
                    damage.from = source
                    damage.to = p
                    damage.damage = 2
                    damage.nature = sgs.DamageStruct_Fire
                    room:damage(damage)
                end
            end
        end
    end
}

LuaFenchengVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaFencheng',
    view_as = function(self, cards) return LuaFenchengCard:clone() end,
    enabled_at_play = function(self, player)
        return player:getMark('@burn') > 0
    end
}

LuaFencheng = sgs.CreateTriggerSkill {
    name = 'LuaFencheng',
    frequency = sgs.Skill_Limited,
    limit_mark = '@burn',
    view_as_skill = LuaFenchengVS,
    events = {sgs.ChoiceMade},
    on_trigger = function(self, event, player, data, room)
        local dataStr = data:toString():split(':')
        if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~=
            'fencheng' then return false end
        room:setTag('LuaFenchengDiscard', sgs.QVariant(#dataStr[3]:split('+')))
        return false
    end,
    can_trigger = function(self, target) return target end
}

JieLiru:addSkill(LuaJuece)
JieLiru:addSkill(LuaMieji)
JieLiru:addSkill(LuaFencheng)

LuaJunxingCard = sgs.CreateSkillCard {
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
        local len = self:getSubcards():length()
        if room:askForDiscard(target, 'LuaJunxing', len, len, true, false,
                              '@LuaJunxing:::' .. len) then
            room:loseHp(target)
        else
            target:turnOver()
            target:drawCards(len)
        end
    end
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
            for _, cd in ipairs(cards) do vs_card:addSubcard(cd) end
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaJunxingCard')
    end
}

LuaYuce = sgs.CreateTriggerSkill {
    name = 'LuaYuce',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local card = room:askForCard(player, '.', '@LuaYuce-show', data,
                                     sgs.Card_MethodNone)
        if card then
            skill(self, room, player, true)
            room:showCard(player, card:getEffectiveId())
            if damage.from == nil or damage.from:isDead() then
                return false
            end
            room:doAnimate(1, player:objectName(), damage.from:objectName())
            local typeName = {'BasicCard', 'TrickCard', 'EquipCard'}
            local toRemove = firstToUpper(replaceUnderline(card:getType())) ..
                                 'Card'
            table.removeOne(typeName, toRemove)
            if not damage.from:canDiscard(damage.from, 'h') or
                not room:askForCard(damage.from,
                                    table.concat(typeName, ',') .. '|.|.|hand',
                                    '@yuce-discard:' .. player:objectName() ..
                                        '::' .. typeName[1] .. ':' ..
                                        typeName[2], data) then
                room:getThread():delay(1500)
                room:recover(player, sgs.RecoverStruct(player, nil, 1))
            end
        end
        return false
    end
}

Jiemanchong:addSkill(LuaJunxing)
Jiemanchong:addSkill(LuaYuce)

function firstToUpper(str) return (str:gsub("^%l", string.upper)) end

function replaceUnderline(str)
    if string.find(str, "%p%l+") then
        local first = string.sub(str, string.find(str, "%l+"))
        local last = string.sub(str, string.find(str, "%p%l+"))
        last = firstToUpper(string.sub(last, 2))
        return first .. last
    end
    return str
end

-- 封装好的函数部分
function LuaDoQiaosiShow(room, player, dummyCard)
    local choices = {
        'king', 'merchant', 'artisan', 'farmer', 'scholar', 'general', 'cancel'
    }
    local chosenRoles = {}
    local index = 0
    local continuePlaying = true
    while index < 3 and continuePlaying do
        local choice = room:askForChoice(player, 'LuaQiaosi',
                                         table.concat(choices, '+'))
        if choice == 'cancel' then continuePlaying = false end
        table.removeOne(choices, choice)
        table.insert(chosenRoles, choice)
        index = index + 1
    end
    local toGiveCardTypes = LuaQiaosiGetCards(room, chosenRoles)
    for _, cardTypes in ipairs(toGiveCardTypes) do
        local params = {['existed'] = {}, ['findDiscardPile'] = true}
        if #cardTypes == 2 then
            -- 确定的，王、将
            params['type'] = cardTypes[1]
            local card1 = obtainTargetedTypeCard(room, params)
            if card1 then
                params['existed'] = {card1:objectName()}
                dummyCard:addSubcard(card1)
                local card2 = obtainTargetedTypeCard(room, params)
                if card2 then dummyCard:addSubcard(card2) end
            end
        else
            -- 不确定的，要抽奖
            math.randomseed(os.time())
            local currType = math.random(1, 5)
            local type = cardTypes[currType]
            if string.find(type, 'JinkOrPeach') then
                type = LuaGetRoleCardType('scholarKing', true, true)
            elseif string.find(type, 'SlashOrAnaleptic') then
                type = LuaGetRoleCardType('merchantGeneral', true, true)
            end
            params['type'] = type
            local card = obtainTargetedTypeCard(room, params)
            if card then dummyCard:addSubcard(card) end
        end
    end
    player:obtainCard(dummyCard)
    return dummyCard:subcardsLength()
end

function LuaQiaosiGetCards(room, roleType)
    --[[ 
        王、商、工、农、士、将
        King、Merchant、Artisan、Farmer、Scholar、General
        roleType 代表转的人类型，为 Table 类型
        例如{"king", "artisan", "general"}
    ]] --
    local results = {}
    local kingActivated = table.contains(roleType, 'king')
    local generalActivated = table.contains(roleType, 'general')
    for _, type in ipairs(roleType) do
        local cardTypes = LuaGetRoleCardType(type, kingActivated,
                                             generalActivated)
        table.insert(results, cardTypes)
    end
    return results
end

function LuaGetRoleCardType(roleType, kingActivated, generalActivated)
    local map = {
        ['king'] = {'TrickCard', 'TrickCard'},
        ['general'] = {'EquipCard', 'EquipCard'},
        ['artisan'] = {'Slash', 'Slash', 'Slash', 'Slash', 'Analeptic'},
        ['farmer'] = {'Jink', 'Jink', 'Jink', 'Jink', 'Peach'},
        ['scholar'] = {
            'TrickCard', 'TrickCard', 'TrickCard', 'TrickCard', 'JinkOrPeach'
        },
        ['scholarKing'] = {'Peach', 'Peach', 'Peach', 'Peach', 'Jink'},
        ['merchant'] = {
            'EquipCard', 'EquipCard', 'EquipCard', 'EquipCard',
            'SlashOrAnaleptic'
        },
        ['merchantGeneral'] = {
            'Analeptic', 'Analeptic', 'Analeptic', 'Analeptic', 'Slash'
        }
    }
    if roleType == 'scholar' and kingActivated then
        roleType = roleType .. 'King'
    end
    if roleType == 'merchant' and generalActivated then
        roleType = roleType .. 'General'
    end
    return map[roleType]
end

function LuaQinzhengGetCard(room, markNum, modNum, cardType1, cardType2)
    local mod = math.fmod(markNum, modNum)
    if mod == 0 then
        math.randomseed(os.time())
        local type = math.random(1, 2)
        local card
        local params = {['existed'] = {}, ['findDiscardPile'] = true}
        if type == 1 then
            params['type'] = cardType1
            card = obtainTargetedTypeCard(room, params)
        else
            params['type'] = cardType2
            card = obtainTargetedTypeCard(room, params)
        end
        return card
    end
    return nil
end

function CanMoveCard(room)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if (p:getJudgingArea():length() > 0 or p:getEquips():length() > 0) then
            return true
        end
    end
    return false
end

-- 获得牌堆中指定类型的牌
-- params 代表参数，类型 Table
-- type 具体要获得的类型，可以使用 isKindOf 进行判断，为 String
-- existed 代表要避开的已有牌，为 Table 类型
-- findDiscardPile 代表是否在弃牌堆寻找，为布尔类型
function obtainTargetedTypeCard(room, params)
    local type = params['type']
    if type == nil then return nil end
    local existedNames = params['existed']
    if existedNames == nil then existedNames = {} end
    local findDiscardPile = params['findDiscardPile']
    if findDiscardPile == nil then findDiscardPile = false end
    for _, id in sgs.qlist(room:getDrawPile()) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isKindOf(type) and
            not table.contains(existedNames, card:objectName()) then
            return card
        end
    end
    if findDiscardPile then
        for _, id in sgs.qlist(room:getDiscardPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf(type) and
                not table.contains(existedNames, card:objectName()) then
                return card
            end
        end
    end
    return nil
end

function getCardList(intlist)
    local ids = sgs.CardList()
    for _, id in sgs.qlist(intlist) do ids:append(sgs.Sanguosha:getCard(id)) end
    return ids
end

function skill(self, room, player, open, n)
    local log = sgs.LogMessage()
    log.type = "#InvokeSkill"
    log.from = player
    log.arg = self:objectName()
    room:sendLog(log)
    room:notifySkillInvoked(player, self:objectName())
    if open then
        if n then
            room:broadcastSkillInvoke(self:objectName(), n)
        else
            room:broadcastSkillInvoke(self:objectName())
        end
    end
end

sgs.LoadTranslationTable {
    ['ExpansionPackage'] = '扩展武将包',
    ['Wangyuanji'] = '王元姬',
    ['&Wangyuanji'] = '王元姬',
    ['#Wangyuanji'] = '清雅抑华',
    ['LuaQianchong'] = '谦冲',
    [':LuaQianchong'] = '锁定技，若你的装备区所有牌为黑色，则你拥有“帷幕”；若你的装备区所有牌为红色，则你拥有“明哲”；出牌阶段开始时，若你不满足上述条件，则你选择一种类型的牌，本回合使用此类型的牌无次数和距离限制',
    ['#LuaQianchongChoice'] = '%from 选择了 %arg，本回合其使用 %arg 无距离次数限制',
    ['LuaShangjian'] = '尚俭',
    [':LuaShangjian'] = '锁定技，任意角色的结束阶段开始时，若你于本回合内失去的牌不大于体力值，你摸等量的牌',
    ['Xurong'] = '徐荣',
    ['&Xurong'] = '徐荣',
    ['#Xurong'] = '玄菟战魔',
    ['~Xurong'] = '此生无悔，心中……无愧',
    ['LuaXionghuo'] = '凶镬',
    [':LuaXionghuo'] = '游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，你对有此标记的角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”标记并随机执行一项：1.受到1点火焰伤害且本回合不能对你使用【杀】；2.失去1点体力且本回合手牌上限-1；3.你获得其一张手牌和一张装备区里的牌',
    ['@baoli'] = '暴戾',
    ['$LuaXionghuo1'] = '此镬加之于你，定有所伤！',
    ['$LuaXionghuo2'] = '凶镬沿袭，怎会轻易无伤？',
    ['luaxionghuo'] = '凶镬',
    ['LuaShajue'] = '杀绝',
    [':LuaShajue'] = '锁定技，其他角色进入濒死状态时，若其体力小于0，则你获得一个“暴戾”标记，并获得使其进入濒死状态的牌',
    ['$LuaShajue1'] = '杀伐决绝，不留后患！',
    ['$LuaShajue2'] = '吾既出，必绝之！',
    ['Caoying'] = '曹婴',
    ['&Caoying'] = '曹婴',
    ['#Caoying'] = '龙城凤鸣',
    ['LuaLingren'] = '凌人',
    [':LuaLingren'] = '出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一个目标的手牌是否有基本牌、锦囊牌或装备牌。至少猜对一项则此牌伤害+1；至少猜对两项则你摸两张牌；猜对三项则你获得“奸雄”和“行殇”直到你下回合开始',
    ['BasicCardGuess'] = '基本牌',
    ['TrickCardGuess'] = '锦囊牌',
    ['EquipCardGuess'] = '装备牌',
    ['Have'] = '有',
    ['NotHave'] = '没有',
    ['LuaLingren-choose'] = '你可以发动“凌人”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['LuaFujian'] = '伏间',
    [':LuaFujian'] = '锁定技，结束阶段开始时，你随机观看一名其他角色的手牌',
    ['Lijue'] = '李傕',
    ['&Lijue'] = '李傕',
    ['#Lijue'] = '兵道诡谲',
    ['LuaYisuan'] = '亦算',
    [':LuaYisuan'] = '出牌阶段限一次，当你使用的锦囊牌进入弃牌堆时，你可以减一点体力上限，从弃牌堆获得之',
    ['$LuaYisuan1'] = '吾亦能善算谋划！',
    ['$LuaYisuan2'] = '算计人心，我也可略施一二',
    ['LuaLangxi'] = '狼袭',
    [':LuaLangxi'] = '准备阶段开始时，你可以对一名体力值小于等于你的角色造成0-2点随机伤害',
    ['LuaLangxi-choose'] = '你可以发动“狼袭”<br/> <b>操作提示</b>: 选择一名体力值不大于你的角色→点击确定<br/>',
    ['$LuaLangxi1'] = '袭夺之势，如狼噬骨！',
    ['$LuaLangxi2'] = '引吾至此，怎能不袭掠之？',
    ['~Lijue'] = '若无内讧，也不至如此……',
    ['Caochun'] = '曹纯',
    ['&Caochun'] = '曹纯',
    ['#Caochun'] = '虎豹骑首',
    ['LuaShanjia'] = '缮甲',
    [':LuaShanjia'] = '出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（本局游戏你每失去过一张装备区里的牌，便少弃置一张），若你本次没有弃置基本牌或锦囊牌，可视为使用一张【杀】（不计入次数限制）',
    ['luashanjia'] = '缮甲',
    ['LuaShanjia_throw'] = '请弃置若干张牌',
    ['~LuaShanjia'] = '选择若干张牌→选择出【杀】目标（如果有）→点击确定',
    ['@luashanjia'] = '缮甲',
    ['$LuaShanjia1'] = '缮甲厉兵，伺机而行',
    ['$LuaShanjia2'] = '战，当取精锐之兵，而弃驽钝也',
    ['Maliang'] = '马良',
    ['&Maliang'] = '马良',
    ['#Maliang'] = '白眉智士',
    ['LuaZishu'] = '自书',
    [':LuaZishu'] = '锁定技，你的回合外，你获得的牌均会在当前回合结束后置入弃牌堆；你的回合内，当你不因此技能效果获得牌时，摸一张牌',
    ['$LuaZishu1'] = '两国修好，不动干戈',
    ['$LuaZishu2'] = '敌不犯我，我不犯人',
    ['LuaYingyuan'] = '应援',
    ['$LuaYingyuan1'] = '蛮族精兵，为我所用！',
    ['$LuaYingyuan2'] = '汉室危亡，赖诸位大王助力！',
    [':LuaYingyuan'] = '<font color="green"><b>相同牌名的牌每回合限一次</b></font>，当你于回合内使用的牌置入弃牌堆后，你可以将之交给一名其他角色。',
    ['@LuaYingyuanTo'] = '你可以选择一名其他角色，将 %src 交给他',
    ['~Maliang'] = '侍主尽忠，死亦无妨',
    ['Jiakui'] = '贾逵',
    ['&Jiakui'] = '贾逵',
    ['#Jiakui'] = '肃齐万里',
    ['LuaZhongzuo'] = '忠佐',
    [':LuaZhongzuo'] = '一名角色的回合结束时，若你于此回合内造成过或受到过伤害，则你可令一名角色摸两张牌。若你选择的角色已受伤，则你摸一张牌',
    ['@LuaZhongzuoChoose'] = '你可以选择一名角色发动“忠佐”，令其摸两张牌，若他已受伤，则你摸一张牌',
    ['$LuaZhongzuo1'] = '历经磨难，不改祖国之志！',
    ['$LuaZhongzuo2'] = '建立功业，惟愿天下早定',
    ['LuaWanlan'] = '挽澜',
    [':LuaWanlan'] = '限定技，一名角色进入濒死状态时，你可弃置所有手牌令该角色回复体力至1点，然后你对当前回合角色造成一点伤害',
    ['@LuaWanlan'] = '挽澜',
    ['$LuaWanlan1'] = '挽狂澜于既倒，扶大厦于将倾！',
    ['$LuaWanlan2'] = '深受国恩，今日便是报偿之时！',
    ['~Jiakui'] = '不斩孙权，九泉之下愧见先帝啊！',
    ['JieXusheng'] = '界徐盛',
    ['&JieXusheng'] = '界徐盛',
    ['#JieXusheng'] = '江东的铁壁',
    ['LuaPojun'] = '破军',
    [':LuaPojun'] = '当你使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值）；若如此做，当前回合结束阶段开始时，该角色获得这些牌。锁定技，你使用【杀】对手牌数与装备数均不大于你的角色造成伤害时，此伤害+1',
    ['#LuaPojunDamageUp'] = '%from 执行“<font color="yellow"><b>破军</b></font>”的效果，%card 的伤害值 + <font color = "yellow"><b>1</b></font>',
    ['#LuaPojunDamageUpVirtualCard'] = '%from 执行“<font color="yellow"><b>破军</b></font>”的效果，<font color = "yellow"><b>杀[无色]</b></font> 的伤害值 + <font color = "yellow"><b>1</b></font>',
    ['$LuaPojun1'] = '江东铁壁，御敌于千里之外！',
    ['$LuaPojun2'] = '破军剑舞，正在此时！',
    ['~JieXusheng'] = '贼军连绵不绝，盛力已竭……',
    ['JieMadai'] = '界马岱',
    ['&JieMadai'] = '界马岱',
    ['#JieMadai'] = '临危受命',
    ['LuaMashu'] = '马术',
    [':LuaMashu'] = '锁定技，你计算与其他角色的距离-1；若你于出牌阶段未使用【杀】造成过伤害，你于结束阶段结束时，可以视为使用一张无距离限制的【杀】',
    ['@LuaMashuSlashTo'] = '你可以发动“马术”，视为对其他一名角色使用一张【杀】',
    ['LuaQianxi'] = '潜袭',
    [':LuaQianxi'] = '当一名角色的回合开始时，若你与其的距离不大于1，你可以令当前回合角色选择是否令你摸一张牌；若如此做，你须弃置一张手牌并指定一名距离为1的角色，然后该角色于本回合内不能使用和打出和你弃置的牌颜色相同的手牌，',
    ['$LuaQianxi1'] = '叛夫小儿，快快授首！',
    ['$LuaQianxi2'] = '前军待阵，袭杀逆贼！',
    ['~JieMadai'] = '原来，你早有防备……',
    ['@LuaQianxi-choose'] = '请选择一名其他角色',
    ['@LuaQianxi-discard'] = '请弃置一张手牌',
    ['LuaQianxiDraw'] = '潜袭摸牌',
    ['#LuaQianxiDrawAccept'] = '%from 同意让 %to 摸牌',
    ['#LuaQianxiDrawRefuse'] = '%from 拒绝让 %to 摸牌',
    ['Majun'] = '马钧',
    ['&Majun'] = '马钧',
    ['#Majun'] = '没渊瑰璞',
    ['~Majun'] = '衡石不用，美玉见诬啊……',
    ['luajingxie'] = '精械',
    ['LuaJingxie'] = '精械',
    [':LuaJingxie'] = '出牌阶段，你可以展示一张防具牌或是【诸葛连弩】，若其在你的手牌中，你使用之，然后根据其牌名，在该装备还在装备区时你获得以下效果：\
    【诸葛连弩】：你的攻击距离+3（注意：无法与公清等技能联动）\
    【八卦阵】：当你进行【八卦阵】判定时，梅花牌视为红桃牌\
    【仁王盾】：黑色【杀】和红桃【杀】对你无效\
    【白银狮子】：当其从你的装备区失去时，你摸2张牌\
    【藤甲】：防止你进入横置状态\
    当你进入濒死状态后，你可以重铸一张防具牌，若如此做，你将体力值回复至1',
    ['$LuaJingxie1'] = '军具精巧，方保无虞',
    ['$LuaJingxie2'] = '巧则巧矣，未尽善也',
    ['#LuaJingxie-Renwang'] = '%from 的“<font color="yellow"><b>精械</b></font>”被触发， %to 的【%arg】对其无效',
    ['LuaJingxie-Invoke'] = '你可以重铸一张防具牌，将体力值回复至1',
    ['luaqiaosistart'] = '巧思',
    ['LuaQiaosi'] = '巧思',
    ['luaqiaosi'] = '巧思',
    [':LuaQiaosi'] = '出牌阶段限一次，你可以表演“水转百戏图”来赢取相应的牌，然后你选择一项：1.弃置等量的牌；2.将等量的牌交给一名其他角色',
    ['LuaQiaosi_give'] = '你发动“巧思”处置 %src 张牌，选择交给其他角色或弃置',
    ['king'] = '君王',
    ['merchant'] = '商人',
    ['farmer'] = '农民',
    ['artisan'] = '工匠',
    ['scholar'] = '学者',
    ['~LuaQiaosi'] = '选择对应数量手牌→选择一名其他角色（可不选）→点击确定',
    ['$LuaQiaosi1'] = '待我稍作思量，更议其巧',
    ['$LuaQiaosi2'] = '虚争空言，不如思而试之',
    ['Yiji'] = '伊籍',
    ['&Yiji'] = '伊籍',
    ['#Yiji'] = '礼仁同渡',
    ['~Yiji'] = '未能，救得刘公脱险……',
    ['LuaJijie'] = '机捷',
    [':LuaJijie'] = '出牌阶段限一次，你可以观看牌堆底的一张牌，然后将其交给任意角色',
    ['luajijie'] = '机捷',
    ['@LuaJijiePlayer-Chosen'] = '你可选择一名其他角色交给其这张牌，或是点击取消将其交给自己',
    ['$LuaJijie1'] = '识言观行，方能雍容风议',
    ['$LuaJijie2'] = '一拜一起，未足为劳',
    ['LuaJiyuan'] = '急援',
    [':LuaJiyuan'] = '当一名角色进入濒死状态或你交给一名其他角色牌时，你可令该角色摸一张牌',
    ['$LuaJiyuan1'] = '情势危急，还请速行！',
    ['$LuaJiyuan2'] = '公若此，必遭蔡瑁之害矣！',
    ['Lifeng'] = '李丰',
    ['&Lifeng'] = '李丰',
    ['#Lifeng'] = '继父尽事',
    ['~Lifeng'] = '马困人饥，我军休矣',
    ['LuaTunchu'] = '屯储',
    [':LuaTunchu'] = '摸牌阶段，若你没有“粮”，你可以额外摸两张牌，若如此做，然后将任意张手牌置于你的武将牌上，称为“粮”，若你的武将牌上有“粮”，你不能使用【杀】',
    ['@LuaTunchu'] = '你可以发动“屯储”',
    ['~LuaTunchu'] = '选择若干张手牌→点击确定',
    ['luatunchu'] = '屯储',
    ['LuaLiang'] = '粮',
    ['$LuaTunchu1'] = '广屯粮草，方能长久对峙！',
    ['$LuaTunchu2'] = '屯以安定社稷，储为不时之需！',
    ['LuaShuliang'] = '输粮',
    [':LuaShuliang'] = '一名角色的结束阶段开始时，若其手牌数小于体力值，你可以将一张“粮”置入弃牌堆，然后该角色摸两张牌',
    ['luashuliang'] = '输粮',
    ['@LuaShuliang'] = '你可以发动“输粮”，令当前回合角色摸2张牌',
    ['~LuaShuliang'] = '选择一张“粮”→点击确定',
    ['$LuaShuliang1'] = '承父之志，助丞相再伐中原！',
    ['$LuaShuliang2'] = '兵马未动，粮草先行！',
    ['ZhaotongZhaoguang'] = '赵统赵广',
    ['&ZhaotongZhaoguang'] = '赵统赵广',
    ['#ZhaotongZhaoguang'] = '身继龙魂',
    ['~ZhaotongZhaoguang'] = '皇上……丞相，统（广）愧矣……',
    ['LuaYizan'] = '翊赞',
    [':LuaYizan'] = '你可以将一张基本牌和其他一张牌当任意基本牌使用或打出',
    [':LuaYizan2'] = '你可以将一张基本牌当任意基本牌使用或打出',
    ['$LuaYizan1'] = '慎审进退，立于不败之地！',
    ['$LuaYizan2'] = '毅志弥奋，扬我赵家之武！',
    ['LuaLongyuan'] = '龙渊',
    [':LuaLongyuan'] = '觉醒技，准备阶段开始时，若你已经已累计发动过3或更多次“翊赞”，你将“翊赞”改为“你可以将一张基本牌当任意基本牌使用或打出”',
    ['$LuaLongyuan1'] = '久历战阵，成跃在渊！',
    ['$LuaLongyuan2'] = '龙威犹存，其势在天！',
    ['yizan_slash'] = '翊赞',
    ['yizan_saveself'] = '翊赞',
    ['JieYanliangWenchou'] = '界颜良文丑',
    ['&JieYanliangWenchou'] = '界颜良文丑',
    ['#JieYanliangWenchou'] = '虎狼兄弟',
    ['LuaShuangxiong'] = '双雄',
    [':LuaShuangxiong'] = '摸牌阶段，你可以改为展示牌堆顶两张牌，获得其中一张牌，然后本回合你可以将与任意一张与该牌不同颜色的一张手牌当【决斗】使用；当你因“双雄”受到伤害后，你可以获得此次【决斗】中其他角色打出的【杀】',
    ['$LuaShuangxiong1'] = '此战如有你我一人在此，何惧华雄？——定叫他有去无回！',
    ['$LuaShuangxiong2'] = '哥哥，且看我与赵云一战！——先与他战个五十回合！',
    ['~JieYanliangWenchou'] = '不是叫你看好我身后吗……',
    ['JieLingtong'] = '界凌统',
    ['&JieLingtong'] = '界凌统',
    ['#JieLingtong'] = '豪情烈胆',
    ['LuaXuanfeng'] = '旋风',
    [':LuaXuanfeng'] = '当你于弃牌阶段弃置过至少两张牌，或当你失去装备区里的牌后，你可以弃置至多两名其他角色的共计两张牌。然后若此时是你的回合内，你可以对其中一名角色造成1点伤害',
    ['LuaXuanfengDamage-choose'] = '你可以对其中一名角色造成一点伤害',
    ['@xuanfeng-card'] = '你可以发动“旋风”，弃置至多两名其他角色的两张牌',
    ['~LuaXuanfeng'] = '选择一至两名其他角色→点击确定',
    ['luaxuanfeng'] = '旋风',
    ['throwone'] = '弃置该角色一张牌',
    ['throwtwo'] = '弃置该角色两张牌',
    ['$LuaXuanfeng1'] = '急军先行，斩将，夺城，再败军！',
    ['$LuaXuanfeng2'] = '短兵相接，教尔等片甲不留！',
    ['~JieLingtong'] = '公绩之犬子就托于主公了……',
    ['Shenpei'] = '审配',
    ['&Shenpei'] = '审配',
    ['#Shenpei'] = '正南义北',
    ['~Shenpei'] = '吾君在北，但求面北而亡……',
    ['LuaLiezhi'] = '烈直',
    [':LuaLiezhi'] = '准备阶段，你可以选择至多两名其他角色，依次弃置其区域内的一张牌；若你受到伤害，则直至你的下个结束阶段时，此技能失效',
    ['lualiezhi'] = '烈直',
    ['@LuaLiezhi'] = '你可以发动“烈直”，弃置至多两名其他角色区域内各一张牌',
    ['~LuaLiezhi'] = '选择一至两名其他角色→点击确定',
    ['$LuaLiezhi1'] = '只恨箭支太少，不能射杀汝等！',
    ['$LuaLiezhi2'] = '死便死，降？断不能降！',
    ['LuaShouye'] = '守邺',
    [':LuaShouye'] = '<font color="green"><b>每回合限一次</b></font>，当你成为其他角色使用牌的唯一目标后，你可以与其进行对策：若你对策成功，则此牌对你无效，且你获得此牌',
    ['syjg1'] = '全力攻城',
    ['syjg2'] = '分兵围城',
    ['syfy1'] = '开城诱敌',
    ['syfy2'] = '奇袭粮道',
    ['$LuaShouye1'] = '敌军攻势渐怠，还望诸位依策坚守',
    ['$LuaShouye2'] = '袁幽州不日便至，当行策建功以报之',
    ['#ShouyeSucceed'] = '%from 守邺 <font color="yellow"><b>成功</b></font>',
    ['#ShouyeFailed'] = '%from 守邺 <font color="yellow"><b>失败</b></font>',
    ['Yangbiao'] = '杨彪',
    ['#Yangbiao'] = '德彰海內',
    ['&Yangbiao'] = '杨彪',
    ['~Yangbiao'] = '未能效死佑汉，只因宗族之重……',
    ['LuaZhaohan'] = '昭汉',
    [':LuaZhaohan'] = '锁定技，你的前四个准备阶段开始时加1点体力上限并回复1点体力，之后的三个准备阶段开始时减1点体力上限',
    ['$LuaZhaohan1'] = '天道昭昭，再兴如光武亦可期！',
    ['$LuaZhaohan2'] = '汉祚将终，我又岂能无憾？',
    ['LuaRangjie'] = '让节',
    [':LuaRangjie'] = '锁定技，当你受到1点伤害后，你选择一项：1.移动场上一张牌；2.从牌堆中获得一张你指定类型的牌。然后你摸一张牌',
    ['$LuaRangjie1'] = '一人劫天子，一人质公卿，此可行耶？',
    ['$LuaRangjie2'] = '诸君举事，当上顺天心，奈何如是！',
    ['moveOneCard'] = '移动场上的一张牌',
    ['obtainBasic'] = '从牌堆中获得基本牌',
    ['obtainTrick'] = '从牌堆中获得锦囊牌',
    ['obtainEquip'] = '从牌堆中获得装备牌',
    ['@LuaRangjieMoveFrom'] = '请选择你要移动牌的来源角色',
    ['@LuaRangjieMoveTo'] = '请选择此牌的目标角色',
    ['LuaYizheng'] = '义争',
    [':LuaYizheng'] = '出牌阶段限一次，你可以与一名体力值不大于你的角色拼点，若你：赢，其跳过下个摸牌阶段；没赢，你减1点体力上限',
    ['$LuaYizheng1'] = '公既执掌权柄，又何必令君臣遭乱？',
    ['$LuaYizheng2'] = '公虽权倾朝野，亦当遵圣上之意',
    ['luayizheng'] = '义争',
    ['Luotong'] = '骆统',
    ['&Luotong'] = '骆统',
    ['#Luotong'] = '辨明大义',
    ['LuaQinzheng'] = '勤政',
    [':LuaQinzheng'] = '锁定技，你每使用或打出三张牌时，你随机获得一张【杀】或【闪】﹔每使用或打出五张牌时，你随机获得一张【桃】或【酒】﹔每使用或打出八张牌时，你随机获得一张【无中生有】或【决斗】',
    ['$LuaQinzheng1'] = '治疾及其未笃，除患贵其未深',
    ['$LuaQinzheng2'] = '夫国之有民，犹水之有舟，停则以安，扰则以危',
    ['Zhangyi'] = '张翼',
    ['&Zhangyi'] = '张翼',
    ['#Zhangyi'] = '亢锐怀忠',
    ['~Zhangyi'] = '惟愿百姓不受此乱所害……',
    ['LuaZhiyi'] = '执义',
    [':LuaZhiyi'] = '锁定技，若你于一个回合内使用或打出过基本牌，则本回合的结束阶段，你选择一项：1.视为你使用一张你本回合使用或打出过的基本牌；2.摸一张牌',
    ['$LuaZhiyi1'] = '岂可擅退而误国家之功！',
    ['$LuaZhiyi2'] = '统摄不懈，只为破敌！',
    ['LuaZhiyiSlashTo'] = '请选择一名角色作为【杀】的目标',
    ['JieLiru'] = '界李儒',
    ['&JieLiru'] = '界李儒',
    ['#JieLiru'] = '魔仕',
    ['~JieLiru'] = '乱世的好戏才刚刚开始……',
    ['LuaJuece'] = '绝策',
    [':LuaJuece'] = '结束阶段，你可以对本回合失去过牌的一名其他角色造成1点伤害',
    ['@LuaJueceDamageTo'] = '你可以选择一名在本回合内失去过牌的其他角色，对其造成一点伤害',
    ['$LuaJuece1'] = '我，最喜欢落井下石~',
    ['$LuaJuece2'] = '一无所有？那就拿命来填！',
    ['LuaMieji'] = '灭计',
    ['luamieji'] = '灭计',
    ['@LuaMiejiDiscard'] = '请交出一张锦囊牌或者弃置两张非锦囊牌（先弃置第一张）',
    ['@LuaMiejiDiscardNonTrick'] = '请弃置一张非锦囊牌',
    [':LuaMieji'] = '出牌阶段限一次，你可以将一张黑色锦囊牌置于牌堆顶，令一名其他角色选择一项：1.交给你一张锦囊牌；2.依次弃置两张非锦囊牌（不足则弃置一张）',
    ['$LuaMieji1'] = '我要的是斩草除根~',
    ['$LuaMieji2'] = '叫天天不应，叫地地不灵~',
    ['LuaFencheng'] = '焚城',
    [':LuaFencheng'] = '限定技，出牌阶段，你可以令所有其他角色依次选择一项：1. 弃置至少X张牌（若上一名进行选择的角色以此法弃置过牌，X为其以此法弃置的牌数+1，否则X为1）；2. 受到你造成的2点火焰伤害',
    ['luafencheng'] = '焚城',
    ['$LuaFencheng1'] = '我要这满城的人都来给你陪葬~',
    ['$LuaFencheng2'] = '一把火烧他个精光吧！诶啊哈哈哈哈哈~',
    ['Jiemanchong'] = '界满宠',
    ['&Jiemanchong'] = '界满宠',
    ['#Jiemanchong'] = '政法兵谋',
    ['~Jiemanchong'] = '酷法峻刑，不得人心啊……',
    ['LuaJunxing'] = '峻刑',
    [':LuaJunxing'] = '出牌阶段限一次，你可以弃置任意张手牌并令一名其他角色选择一项：1.弃置等量的牌并失去1点体力；2.翻面，然后摸等量的牌',
    ['$LuaJunxing1'] = '看你如何诡辩！',
    ['$LuaJunxing2'] = '天子犯法，也与庶民同罪！',
    ['luajunxing'] = '峻刑',
    ['@LuaJunxing'] = '你可以弃置 %arg 张手牌并失去一点体力，或者点击“取消”翻面并摸取等量的牌',
    ['LuaYuce'] = '御策',
    [':LuaYuce'] = '当你受到伤害后，你可以展示一张手牌，然后除非伤害来源弃置与你展示的牌类别不同的一张手牌，否则你回复1点体力',
    ["@LuaYuce-show"] = "你可以发动“御策”展示一张手牌",
    ['$LuaYuce1'] = '亡羊补牢，为时未晚',
    ['$LuaYuce2'] = '坚守城阙，以待援军'
}
