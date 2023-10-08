-- 群友包
-- Created by DZDcyj at 2020/10/9
module('extensions.GroupFriendPackage', package.seeall)
extension = sgs.Package('GroupFriendPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')
local rectification = require('extensions.RectificationPackage')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

Cactus = sgs.General(extension, 'Cactus', 'wu', '4', true)
Fuhua = sgs.General(extension, 'Fuhua', 'qun', '4', true, true)
Rinsan = sgs.General(extension, 'Rinsan', 'shu', '3', true, true)
SPFuhua = sgs.General(extension, 'SPFuhua', 'qun', '4', true, true)
SPCactus = sgs.General(extension, 'SPCactus', 'wei', '4', true, false, false, 3)
Qiumu = sgs.General(extension, 'Qiumu', 'qun', '3', true)
SPRinsan = sgs.General(extension, 'SPRinsan', 'shu', '3', true)
Anan = sgs.General(extension, 'Anan', 'qun', '4', false, true)
Erenlei = sgs.General(extension, 'Erenlei', 'wu', '3', true, true)
Yaoyu = sgs.General(extension, 'Yaoyu', 'wu', '4', true)
Shayu = sgs.General(extension, 'Shayu', 'qun', '3', true)
Yeniao = sgs.General(extension, 'Yeniao', 'shu', '4', true, true)
Linxi = sgs.General(extension, 'Linxi', 'qun', '3', false, true)
Ajie = sgs.General(extension, 'Ajie', 'wei', '3', true)
Shatang = sgs.General(extension, 'Shatang', 'qun', '4', true, true)
Dalaojiang = sgs.General(extension, 'Dalaojiang', 'qun', '3', true, true)
Zhongliao = sgs.General(extension, 'Zhongliao', 'shu', '3', true, true)
Mikang = sgs.General(extension, 'Mikang', 'wu', '4', true, true)

-- 额外设置其他信息，例如性别
-- 性别有以下枚举值，分别代表无性、男性、女性、中性（似乎与无性别一致）
-- Sexless, Male, Female, Neuter
-- 枚举值使用时加上 sgs.General_ 前缀
-- 例如 sgs.General_Sexless
Shayu:setGender(sgs.General_Sexless)

LuaBaipiao = sgs.CreateTriggerSkill {
    name = 'LuaBaipiao',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        -- 当你的牌因使用、打出、重铸、给出、更换装备而失去时，不可以触发
        local isUse = rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_USE)
        local isRecast = rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_RECAST)
        local response = rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_RESPONSE)
        local giveOut = move.reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE
        local exchangeEquip = move.reason.m_reason == sgs.CardMoveReason_S_REASON_CHANGE_EQUIP
        local notTriggerable = isUse or response or isRecast or giveOut or exchangeEquip
        if notTriggerable then
            return false
        end
        if rinsan.RIGHT(self, player) then
            if rinsan.lostCard(move, player) then
                if move.to and move.to:objectName() ~= player:objectName() then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    player:drawCards(1, self:objectName())
                else
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not p:isAllNude() then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), 'LuaBaipiao-invoke',
                            false, true)
                        if target then
                            local card_id = room:askForCardChosen(player, target, 'hej', self:objectName(), false,
                                sgs.Card_MethodNone)
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
                                player:objectName())
                            room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaGeidianCard = sgs.CreateSkillCard {
    name = 'LuaGeidianCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude() then
            return not to_select:hasFlag('LuaGeidianTargeted')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:addPlayerMark(source, 'LuaGeidianUsedTime')
        room:setPlayerFlag(target, 'LuaGeidianTargeted')
        local card = room:askForCard(target, '.|.|.|.|.', '@LuaGeidian-ask:' .. source:objectName(), sgs.QVariant(),
            sgs.Card_MethodNone)
        if not card then
            local cards = target:getCards('he')
            card = cards:at(rinsan.random(0, cards:length() - 1))
        end
        source:obtainCard(card, false)
        if source:getMark('LuaGeidianUsedTime') > math.max(1, source:getLostHp()) then
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName('LuaGeidian')
            room:useCard(sgs.CardUseStruct(slash, target, source))
        end
    end,
}

LuaGeidianVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaGeidian',
    view_as = function(self)
        return LuaGeidianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

LuaGeidian = sgs.CreateTriggerSkill {
    name = 'LuaGeidian',
    view_as_skill = LuaGeidianVS,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            -- 出牌阶段结束时清理标记（因考虑当先）
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerFlag(p, '-LuaGeidianTargeted')
                room:setPlayerMark(p, 'LuaGeidianUsedTime', 0)
            end
        end
        return false
    end,
}

LuaWannengCard = sgs.CreateSkillCard {
    name = 'LuaWannengCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return rinsan.guhuoCardFilter(self, targets, to_select, 'LuaWanneng')
    end,
    feasible = function(self, targets)
        return rinsan.selfFeasible(self, targets, 'LuaWanneng')
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidate(self, card_use, 'LuaWanneng', 'wanneng', 'Wanneng')
        if use_card then
            room:addPlayerMark(source, 'LuaWanneng')
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidateInResponse(self, source, 'LuaWanneng', 'wanneng', 'Wanneng')
        if use_card then
            room:addPlayerMark(source, 'LuaWanneng')
        end
        return use_card
    end,
}

LuaWannengVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaWanneng',
    response_or_use = true,
    enabled_at_response = function(self, player, pattern)
        if player:getMark('LuaWanneng') > 0 then
            return false
        end
        return rinsan.guhuoVSSkillEnabledAtResponse(self, player, pattern)
    end,
    enabled_at_play = function(self, player)
        return player:getMark('LuaWanneng') == 0 and rinsan.guhuoVSSkillEnabledAtPlay(self, player)
    end,
    enabled_at_nullification = function(self, player)
        return player:getMark('LuaWanneng') == 0
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = LuaWannengCard:clone()
            card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            return card
        end
        local c = sgs.Self:getTag('LuaWanneng'):toCard()
        if c then
            local card = LuaWannengCard:clone()
            card:setUserString(c:objectName())
            return card
        else
            return nil
        end
    end,
}

LuaWanneng = sgs.CreateTriggerSkill {
    name = 'LuaWanneng',
    events = {sgs.TurnStart},
    view_as_skill = LuaWannengVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill('LuaWanneng') then
                room:setPlayerMark(p, 'LuaWanneng', 0)
            end
        end
    end,
}

LuaWanneng:setGuhuoDialog('lr')

LuaZibao = sgs.CreateTriggerSkill {
    name = 'LuaZibao',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.DamageCaused, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.DamageCaused then
            if player:getMark(self:objectName()) > 0 then
                return false
            end
            local data2 = sgs.QVariant()
            data2:setValue(damage.to)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                room:loseHp(player, 1)
                damage.damage = damage.damage + player:getLostHp()
                data:setValue(damage)
            end
        elseif event == sgs.Damaged then
            local data2 = sgs.QVariant()
            if not damage.from then
                return false
            end
            data2:setValue(damage.from)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                room:loseHp(player, 1)
                room:addPlayerMark(player, self:objectName())
                local theDamage = sgs.DamageStruct()
                theDamage.to = damage.from
                theDamage.damage = player:getLostHp()
                theDamage.from = player
                room:damage(theDamage)
                room:removePlayerMark(player, self:objectName())
            end
        end
    end,
}

function doSoutu(card, soutuer, rinsanPlayer, room, self)
    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
    local ids = sgs.IntList()
    local i = 0
    while i < 3 do
        i = i + 1
        ids:append(room:drawCard())
    end
    room:fillAG(ids, rinsanPlayer)
    local type = 'dummy_card'
    if card:isKindOf('BasicCard') then
        type = 'BasicCard'
    elseif card:isKindOf('TrickCard') then
        type = 'TrickCard'
    elseif card:isKindOf('EquipCard') then
        type = 'EquipCard'
    end
    for _, id in sgs.qlist(ids) do
        local currCard = sgs.Sanguosha:getCard(id)
        local get = false
        if currCard:isKindOf(type) then
            get = true
        end
        if currCard:getSuit() == card:getSuit() then
            get = true
        end
        if currCard:getNumber() == card:getNumber() then
            get = true
        end
        if get then
            dummy:addSubcard(id)
        end
    end
    room:getThread():delay()
    rinsanPlayer:obtainCard(dummy)
    room:clearAG()
    local to_goback = room:askForExchange(rinsanPlayer, self:objectName(), rinsanPlayer:getHandcardNum(), 1, false,
        'LuaSoutuGoBack', true)
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, rinsanPlayer:objectName(), soutuer:objectName(),
        self:objectName(), nil)
    if to_goback then
        room:doAnimate(rinsan.ANIMATE_INDICATE, rinsanPlayer:objectName(), soutuer:objectName())
        room:moveCardTo(to_goback, rinsanPlayer, soutuer, sgs.Player_PlaceHand, reason, true)
    end
end

LuaSoutuCard = sgs.CreateSkillCard {
    name = 'LuaSoutuCard',
    target_fixed = false,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        if rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0) then
            return to_select:hasSkill('LuaSoutu') and not to_select:hasFlag('LuaSoutuInvoked')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local Rinsan = targets[1]
        if Rinsan:hasSkill('LuaSoutu') then
            room:setPlayerFlag(Rinsan, 'LuaSoutuInvoked')
            room:notifySkillInvoked(Rinsan, 'LuaSoutu')
            Rinsan:obtainCard(self)
            doSoutu(sgs.Sanguosha:getCard(self:getSubcards():first()), source, Rinsan, room, self)
            local Rinsans = room:getLieges('shu', Rinsan)
            if Rinsans:isEmpty() then
                room:setPlayerFlag(source, 'ForbidSoutu')
            end
        end
    end,
}

LuaSoutuVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaSoutuVS&',
    filter_pattern = '.',
    view_as = function(self, card)
        local acard = LuaSoutuCard:clone()
        acard:addSubcard(card)
        return acard
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag('ForbidSoutu')
    end,
}

LuaSoutu = sgs.CreateTriggerSkill {
    name = 'LuaSoutu',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.GameStart, sgs.TurnStart, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
    on_trigger = function(self, triggerEvent, player, data, room)
        local rinsans = room:findPlayersBySkillName(self:objectName())
        if (triggerEvent == sgs.TurnStart) or (triggerEvent == sgs.GameStart) or
            (triggerEvent == sgs.EventAcquireSkill and data:toString() == 'LuaSoutu') then
            if rinsans:isEmpty() then
                return false
            end
            local players = room:getOtherPlayers(rinsans:first())
            if rinsans:length() > 1 then
                players = room:getAlivePlayers()
            end
            for _, p in sgs.qlist(players) do
                if not p:hasSkill('LuaSoutuVS') then
                    room:attachSkillToPlayer(p, 'LuaSoutuVS')
                end
            end
        elseif triggerEvent == sgs.EventLoseSkill and data:toString() == 'LuaSoutu' then
            if rinsans:length() > 2 then
                return false
            end
            local players = sgs.SPlayerList()
            if rinsans:isEmpty() then
                players = room:getAlivePlayers()
            else
                players:append(rinsans:first())
            end
            for _, p in sgs.qlist(players) do
                if p:hasSkill('LuaSoutuVS') then
                    room:detachSkillFromPlayer(p, 'LuaSoutuVS', true)
                end
            end
        elseif (triggerEvent == sgs.EventPhaseChanging) then
            local phase_change = data:toPhaseChange()
            if phase_change.from ~= sgs.Player_Play then
                return false
            end
            if player:hasFlag('ForbidSoutu') then
                room:setPlayerFlag(player, '-ForbidSoutu')
            end
            local players = room:getOtherPlayers(player)
            for _, p in sgs.qlist(players) do
                if p:hasFlag('SoutuInvoked') then
                    room:setPlayerFlag(p, '-SoutuInvoked')
                end
            end
        end
        return false
    end,
}

LuaYangjing = sgs.CreateTriggerSkill {
    name = 'LuaYangjing',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PreCardUsed, sgs.EventPhaseEnd, sgs.CardFinished, sgs.DamageCaused, sgs.TargetSpecified,
              sgs.BeforeCardsMove},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            local can = true
            if player:hasFlag('LuaYangjingSlashInPlayPhase') then
                can = false
                player:setFlags('-LuaYangjingSlashInPlayPhase')
            end
            if player:getPhase() == sgs.Player_Play and player:isAlive() and player:hasSkill(self:objectName()) then
                if can then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    player:gainMark('@LuaJing')
                end
            end
        elseif event == sgs.PreCardUsed then
            local card = data:toCardUse().card
            if card:isKindOf('Slash') then
                player:setFlags('LuaYangjingSlash')
                if player:getPhase() == sgs.Player_Play then
                    player:setFlags('LuaYangjingSlashInPlayPhase')
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            local card = use.card
            if card:isKindOf('Slash') then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, 'LuaYangjingDamageUp', 0)
                    if p:hasFlag('LuaYangjingSlash') then
                        p:loseAllMarks('@LuaJing')
                        p:setFlags('-LuaYangjingSlash')
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then
                return false
            end
            if damage.transfer then
                return false
            end
            if damage.to:getMark('LuaYangjingDamageUp') > 0 then
                local x = damage.to:getMark('LuaYangjingDamageUp')
                damage.damage = damage.damage + x
                room:setPlayerMark(damage.to, 'LuaYangjingDamageUp', 0)
                room:doAnimate(rinsan.ANIMATE_INDICATE, damage.from:objectName(), damage.to:objectName())
                local msg = sgs.LogMessage()
                msg.type = '#LuaYangjingDamageUp'
                msg.from = player
                msg.arg = x
                if damage.card and not damage.card:isVirtualCard() then
                    msg.card_str = damage.card:getEffectiveId()
                else
                    msg.type = '#LuaYangjingDamageUpVirtualCard'
                end
                room:notifySkillInvoked(player, self:objectName())
                room:sendLog(msg)
                data:setValue(damage)
            end
        elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if not use.card:isKindOf('Slash') then
                return false
            end
            local x = player:getMark('@LuaJing')
            if x == 0 then
                return false
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(use.to) do
                room:addPlayerMark(p, 'LuaYangjingDamageUp', x)
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), p:objectName())
            end
        elseif event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if rinsan.RIGHT(self, player) and rinsan.lostCard(move, player) and
                rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) then
                local x = 0
                for _, id in sgs.qlist(move.card_ids) do
                    local curr_card = sgs.Sanguosha:getCard(id)
                    if curr_card:isKindOf('Slash') then
                        x = x + 1
                    end
                end
                if x > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    player:gainMark('@LuaJing', x)
                end
            end
        end
        return false
    end,
}

LuaYangjingAttackRange = sgs.CreateAttackRangeSkill {
    name = 'LuaYangjingAttackRange',
    extra_func = function(self, from, card)
        if from:hasSkill('LuaYangjing') then
            return from:getMark('@LuaJing')
        else
            return 0
        end
    end,
}

LuaTuci = sgs.CreateTriggerSkill {
    name = 'LuaTuci',
    events = {sgs.TargetSpecified, sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf('Slash') then
            return false
        end
        if event == sgs.TargetSpecified then
            local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
            local index = 1
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then
                    break
                end
                if p:isAlive() and p:distanceTo(player) < player:getAttackRange() + player:getMark('@LuaJing') then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    rinsan.sendLogMessage(room, '#NoJink', {
                        ['from'] = p,
                    })
                    jink_table[index] = 0
                end
                index = index + 1
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(Table2IntList(jink_table))
            player:setTag('Jink_' .. use.card:toString(), jink_data)
        elseif event == sgs.PreCardUsed then
            if use.from:objectName() == player:objectName() then
                for _, p in sgs.qlist(use.to) do
                    if not player:isAlive() then
                        break
                    end
                    if p:isAlive() and p:distanceTo(player) < player:getAttackRange() + player:getMark('@LuaJing') then
                        rinsan.addQinggangTag(p, use.card)
                    end
                end
            end
        end
        return false
    end,
}

LuaNosJuesha = sgs.CreateTriggerSkill {
    name = 'LuaNosJuesha',
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local data2 = sgs.QVariant()
        data2:setValue(dying.who)
        if player:getMark(self:objectName()) == 0 and room:askForSkillInvoke(player, self:objectName(), data2) then
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), dying.who:objectName())
            room:addPlayerMark(player, self:objectName())
            room:loseHp(dying.who)
            room:removePlayerMark(player, self:objectName())
        end
        return false
    end,
}

table.insert(hiddenSkills, LuaNosJuesha)

local function canInvokeLuaJuesha(player)
    if player:hasSkill('LuaJuesha') then
        return player:getMark('LuaInvokedJuesha-Clear') == 0 or player:getPhase() ~= sgs.Player_NotActive
    end
    return false
end

LuaJuesha = sgs.CreateTriggerSkill {
    name = 'LuaJuesha',
    events = {sgs.Dying, sgs.CardUsed, sgs.QuitDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Dying then
            local dying = data:toDying()
            local data2 = sgs.QVariant()
            data2:setValue(dying.who)
            if canInvokeLuaJuesha(player) and room:askForSkillInvoke(player, self:objectName(), data2) then
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), dying.who:objectName())
                room:addPlayerMark(dying.who, self:objectName() .. player:objectName())
                room:addPlayerMark(player, 'LuaInvokedJuesha-Clear')
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('Peach') or use.card:isKindOf('Analeptic') then
                local splayers = room:findPlayersBySkillName(self:objectName())
                for _, target in sgs.qlist(use.to) do
                    for _, splayer in sgs.qlist(splayers) do
                        if target:getMark(self:objectName() .. splayer:objectName()) > 0 then
                            local nullified_list = use.nullified_list
                            room:sendCompulsoryTriggerLog(splayer, self:objectName())
                            for _, dest in sgs.qlist(room:getAlivePlayers()) do
                                table.insert(nullified_list, dest:objectName())
                            end
                            use.nullified_list = nullified_list
                            data:setValue(use)
                            room:removePlayerMark(target, self:objectName() .. splayer:objectName())
                            return false
                        end
                    end
                end
            end
        elseif event == sgs.QuitDying then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                rinsan.clearAllMarksContains(p, self:objectName())
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaMouhai = sgs.CreateTriggerSkill {
    name = 'LuaMouhai',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHp() >= player:getHp() or p:getHp() == 1 then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), 'LuaMouhai-choose', true,
                    true)
                if target then
                    local damage = sgs.DamageStruct()
                    damage.from = player
                    damage.to = target
                    damage.damage = 1
                    room:damage(damage)
                end
            end
        end
        return false
    end,
}

LuaChuanyi = sgs.CreateTriggerSkill {
    name = 'LuaChuanyi',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local choices = {}
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                -- 先判断是否对该玩家发动过传艺
                if p:getMark(player:objectName() .. self:objectName()) == 0 then
                    targets:append(p)
                    -- 判断其是否有“绝杀”或“谋害”技能
                    if not table.contains(choices, 'LuaJuesha') and not p:hasSkill('LuaJuesha') then
                        table.insert(choices, 'LuaJuesha')
                    end
                    if not table.contains(choices, 'LuaMouhai') and not p:hasSkill('LuaMouhai') then
                        table.insert(choices, 'LuaMouhai')
                    end
                end
            end
            if not targets:isEmpty() and player:getMark('LuaChuanyiGiveUp') == 0 then
                -- 取消和本局不发动
                table.insert(choices, 'cancel')
                table.insert(choices, 'LuaChuanyiGiveUp')
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                if choice == 'LuaJuesha' or choice == 'LuaMouhai' then
                    local available_targets = sgs.SPlayerList()
                    -- 从没被“传艺”过的玩家中选择没有对应技能的
                    for _, target in sgs.qlist(targets) do
                        if not target:hasSkill(choice) then
                            available_targets:append(target)
                        end
                    end
                    if not available_targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, available_targets, self:objectName(),
                            'LuaChuanyi-choose:' .. choice, true, true)
                        if target then
                            room:loseMaxHp(player)
                            room:acquireSkill(target, choice)
                            room:addPlayerMark(target, '@' .. self:objectName())
                            room:addPlayerMark(target, player:objectName() .. self:objectName())
                        end
                    end
                elseif choice == 'LuaChuanyiGiveUp' then
                    -- 本局游戏不再发动
                    room:addPlayerMark(player, 'LuaChuanyiGiveUp')
                end
            end
        end
        return false
    end,
}

LuaPaozhuan = sgs.CreateTriggerSkill {
    name = 'LuaPaozhuan',
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then
            if move.to and move.to:objectName() ~= player:objectName() then
                if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and
                    (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip) then
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
                        room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
                        room:damage(sgs.DamageStruct(self:objectName(), player, target))
                    end
                end
            end
        end
    end,
}

LuaYinyu = sgs.CreateTriggerSkill {
    name = 'LuaYinyu',
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:isKongcheng() then
                        local data2 = sgs.QVariant()
                        data2:setValue(player)
                        local card = room:askForCard(p, '.', '@LuaYinyu-show', data2, sgs.Card_MethodNone, nil, false,
                            self:objectName())
                        if card then
                            rinsan.sendLogMessage(room, '#InvokeSkill', {
                                ['from'] = p,
                                ['arg'] = self:objectName(),
                            })
                            room:showCard(p, card:getEffectiveId())
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(),
                                player:objectName(), self:objectName(), nil)
                            room:doAnimate(rinsan.ANIMATE_INDICATE, p:objectName(), player:objectName())
                            room:moveCardTo(card, p, player, sgs.Player_PlaceHand, reason, false)
                            room:addPlayerMark(player, self:objectName() .. p:objectName(), card:getTypeId())
                        end
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getPhase() ~= sgs.Player_Play then
                return false
            end
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:getMark(self:objectName() .. p:objectName()) > 0 then
                    if use.card and use.card:getTypeId() == player:getMark(self:objectName() .. p:objectName()) then
                        local data2 = sgs.QVariant()
                        data2:setValue(player)
                        if room:askForSkillInvoke(p, self:objectName(), data2) then
                            room:doAnimate(rinsan.ANIMATE_INDICATE, p:objectName(), player:objectName())
                            player:drawCards(1, self:objectName())
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                rinsan.clearAllMarksContains(player, self:objectName())
            end
        end
        return false
    end,
}

LuaQingyu = sgs.CreateTriggerSkill {
    name = 'LuaQingyu',
    events = {sgs.Damage, sgs.TargetConfirmed, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            if player:getPhase() ~= sgs.Player_Play then
                return false
            end
            local choices = {}
            if player:getMaxCards() > 0 then
                table.insert(choices, 'LuaQingyuChoice1')
            end
            table.insert(choices, 'LuaQingyuChoice2')
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
            if choice == 'LuaQingyuChoice1' then
                room:addPlayerMark(player, self:objectName() .. 'Minus')
                player:drawCards(1, self:objectName())
            elseif choice == 'LuaQingyuChoice2' then
                room:addPlayerMark(player, self:objectName() .. 'Plus')
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                room:setPlayerMark(player, self:objectName() .. 'Plus', 0)
                room:setPlayerMark(player, self:objectName() .. 'Minus', 0)
            end
        end
        return false
    end,
}

LuaQingyuTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaQingyuTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = '.',
    residue_func = function(self, player)
        if player:hasSkill('LuaQingyu') then
            if player:getPhase() == sgs.Player_Play then
                return 1000
            end
        end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaQingyu') then
            if from:getPhase() == sgs.Player_Play then
                return 1000
            end
        end
        return 0
    end,
}

LuaQingyuMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaQingyu',
    extra_func = function(self, target)
        if target:hasSkill('LuaQingyu') then
            return target:getMark('LuaQingyuPlus') - target:getMark('LuaQingyuMinus')
        end
        return 0
    end,
}

LuaJiaoxie = sgs.CreateTriggerSkill {
    name = 'LuaJiaoxie',
    events = {sgs.Damaged, sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if rinsan.RIGHT(self, player) then
                if damage.from:getMark('LuaJiaoxieForbid') > 0 then
                    return false
                end
                if damage.from then
                    local data2 = sgs.QVariant()
                    data2:setValue(damage.from)
                    if room:askForSkillInvoke(player, self:objectName(), data2) then
                        room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
                        room:addPlayerMark(damage.from, 'LuaJiaoxieForbid')
                        if damage.from:objectName() == room:getCurrent():objectName() then
                            room:setPlayerFlag(damage.from, 'Global_PlayPhaseTerminated')
                        end
                        damage.from:throwEquipArea()
                    end
                end
            end
        elseif event == sgs.TurnStart then
            if player:getMark('LuaJiaoxieForbid') > 0 then
                player:obtainEquipArea()
                room:removePlayerMark(player, 'LuaJiaoxieForbid')
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaShulian = sgs.CreateTriggerSkill {
    name = 'LuaShulian',
    events = {sgs.MarkChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if not player:hasFlag('LuaShulianCleaning') then
            if mark.name == '@skill_invalidity' then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:setFlags('LuaShulianCleaning')
                room:removePlayerMark(player, mark.name, player:getMark(mark.name))
                player:setFlags('-LuaShulianCleaning')
            end
        end
    end,
}

LuaShulianForbidden = sgs.CreateProhibitSkill {
    name = 'LuaShulianForbidden',
    is_prohibited = function(self, from, to, card)
        if to:hasSkill('LuaShulian') then
            return card:isKindOf('DelayedTrick')
        end
    end,
}

LuaZhazhi = sgs.CreateTriggerSkill {
    name = 'LuaZhazhi',
    events = {sgs.EventPhaseStart, sgs.DamageCaused, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                local splayers = room:findPlayersBySkillName(self:objectName())
                for _, sp in sgs.qlist(splayers) do
                    if sp:objectName() ~= player:objectName() and sp:faceUp() then
                        local data2 = sgs.QVariant()
                        data2:setValue(player)
                        if room:askForSkillInvoke(sp, self:objectName(), data2) then
                            sp:turnOver()
                            room:doAnimate(rinsan.ANIMATE_INDICATE, sp:objectName(), player:objectName())
                            room:showAllCards(player)
                            local choices = {}
                            local tempSlash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                            -- 该角色可以对发动“榨汁”的角色使用【杀】时
                            if not player:isCardLimited(tempSlash, sgs.Card_MethodUse) then
                                -- 有杀或者黑色锦囊牌才可选择第一项
                                for _, cd in sgs.qlist(player:getHandcards()) do
                                    if cd:isKindOf('Slash') or (cd:isKindOf('TrickCard') and cd:isBlack()) then
                                        table.insert(choices, 'LuaZhazhiChoice1')
                                        break
                                    end
                                end
                            end
                            tempSlash:deleteLater()
                            table.insert(choices, 'LuaZhazhiChoice2')
                            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                            if choice == 'LuaZhazhiChoice1' then
                                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                                for _, cd in sgs.qlist(player:getHandcards()) do
                                    if cd:isKindOf('Slash') or (cd:isKindOf('TrickCard') and cd:isBlack()) then
                                        slash:addSubcard(cd)
                                    end
                                end
                                slash:setSkillName(self:objectName())
                                -- 此【杀】需要计入出牌阶段次数
                                room:useCard(sgs.CardUseStruct(slash, player, sp), true)
                            else
                                room:addPlayerMark(player, 'LuaZhazhiDebuff' .. sp:objectName())
                                room:addPlayerMark(player, '@LuaZhazhi')
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, 'LuaZhazhiDebuff') and p:getMark(mark) > 0 then
                            local num = p:getMark(mark)
                            room:removePlayerMark(p, mark, num)
                            room:removePlayerMark(p, '@LuaZhazhi', num)
                        end
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark('@LuaZhazhi') > 0 then
                local damageNum = damage.damage
                for _, mark in sgs.list(damage.from:getMarkNames()) do
                    if string.find(mark, 'LuaZhazhiDebuff') and damage.from:getMark(mark) > 0 then
                        local num = damage.from:getMark(mark)
                        damageNum = damageNum - num
                    end
                end
                if damageNum < 0 then
                    damageNum = 0
                end
                rinsan.sendLogMessage(room, '#LuaZhazhi', {
                    ['from'] = damage.from,
                    ['arg'] = damageNum,
                    ['arg2'] = damage.damage,
                })
                damage.damage = damageNum
                if damageNum > 0 then
                    data:setValue(damage)
                else
                    return true
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaJueding = sgs.CreateTriggerSkill {
    name = 'LuaJueding',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TurnedOver, sgs.DamageInflicted, sgs.EventLoseSkill, sgs.EventAcquireSkill},
    on_trigger = function(self, event, player, data, room)
        if (event ~= sgs.EventLoseSkill and event ~= sgs.EventAcquireSkill) and (not player:hasSkill(self:objectName())) then
            return false
        end
        if event == sgs.TurnedOver then
            if player:faceUp() then
                -- 翻回来，解除卡牌限制
                rinsan.sendLogMessage(room, '#LuaJuedingAvailable', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                })
                room:removePlayerCardLimitation(player, 'use, response', '.|.|.|.$0')
            else
                -- 进行卡牌限制
                rinsan.sendLogMessage(room, '#LuaJuedingDisable', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                })
                room:setPlayerCardLimitation(player, 'use, response', '.|.|.|.', false)
            end
        elseif event == sgs.EventLoseSkill then
            -- 失去技能时应当解除卡牌限制
            if data:toString() == self:objectName() then
                rinsan.sendLogMessage(room, '#LuaJuedingAvailable', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                })
                room:removePlayerCardLimitation(player, 'use, response', '.|.|.|.$0')
            end
        elseif event == sgs.DamageInflicted then
            if not player:faceUp() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:turnOver()
            end
        elseif event == sgs.EventAcquireSkill then
            if data:toString() == self:objectName() then
                if not player:faceUp() then
                    rinsan.sendLogMessage(room, '#LuaJuedingDisable', {
                        ['from'] = player,
                        ['arg'] = self:objectName(),
                    })
                    room:setPlayerCardLimitation(player, 'use, response', '.|.|.|.', false)
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaXunxinCard = sgs.CreateSkillCard {
    name = 'LuaXunxin',
    will_throw = true,
    target_fixed = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and
                   sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        source:pindian(targets[1], self:objectName())
    end,
}

LuaXunxinVS = sgs.CreateViewAsSkill {
    name = 'LuaXunxin',
    n = 0,
    view_as = function(self, cards)
        return LuaXunxinCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
}

LuaXunxin = sgs.CreateTriggerSkill {
    name = 'LuaXunxin',
    events = {sgs.Pindian, sgs.PindianVerifying, sgs.CardUsed, sgs.Damage},
    view_as_skill = LuaXunxinVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                room:addPlayerMark(damage.from, 'LuaXunxinWon-Clear', damage.damage)
            end
            return false
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from and use.card:getSkillName() == self:objectName() and use.card:isKindOf('Slash') then
                room:broadcastSkillInvoke(self:objectName())
                room:notifySkillInvoked(player, self:objectName())
                for _, p in sgs.qlist(use.to) do
                    rinsan.addQinggangTag(p, use.card)
                end
            end
            return false
        end
        local pindian = data:toPindian()
        if pindian.reason ~= self:objectName() then
            return false
        end
        if event == sgs.Pindian then
            if pindian.from_number == pindian.to_number then
                return false
            end
            local winner, loser
            if pindian.from_number > pindian.to_number then
                winner = pindian.from
                loser = pindian.to
            else
                winner = pindian.to
                loser = pindian.from
            end
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName('_LuaXunxin')
            if winner:canSlash(loser, slash, false) then
                room:useCard(sgs.CardUseStruct(slash, winner, loser))
            end
            room:addPlayerMark(winner, 'LuaXunxinWon-Clear')
            return false
        end
        if pindian.from:hasSkill(self:objectName()) then
            local x = player:getMark('LuaXunxinWon-Clear')
            -- 涉及到消息提示和语音播放（如果有），所以还是保留判断
            if x > 0 then
                room:sendCompulsoryTriggerLog(pindian.from, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                pindian.from_number = pindian.from_number - x
                rinsan.sendLogMessage(room, '#LuaXunxin', {
                    ['from'] = pindian.from,
                    ['arg'] = self:objectName(),
                    ['arg2'] = pindian.from_number,
                })
            end
        end
        if pindian.to:hasSkill(self:objectName()) then
            local x = player:getMark('LuaXunxinWon-Clear')
            if x > 0 then
                room:sendCompulsoryTriggerLog(pindian.to, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                pindian.to_number = pindian.to_number - x
                rinsan.sendLogMessage(room, '#LuaXunxin', {
                    ['from'] = pindian.to,
                    ['arg'] = self:objectName(),
                    ['arg2'] = pindian.to_number,
                })
            end
        end
        data:setValue(pindian)
    end,
    can_trigger = rinsan.targetTrigger,
}

local function canInvokeChutou(player, move)
    if not player:hasSkill('LuaChutou') then
        return false
    end
    if not rinsan.lostCard(move, player) then
        -- 不是失去牌不能发动
        return false
    end
    if move.reason and rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) then
        -- 弃牌且为此技能影响
        if player:getMark('LuaChutou') > 0 then
            return false
        end
    end
    if move.reason.m_reason == sgs.CardMoveReason_S_REASON_CHANGE_EQUIP then
        -- 更换装备时不摸牌
        return false
    end
    if rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_RECAST) then
        -- 重铸不摸牌
        return false
    end
    if rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_USE) or
        rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_RESPONSE) then
        -- 使用或打出失去时，回合内不能发动
        if player:getPhase() ~= sgs.Player_NotActive then
            return false
        end
    end
    return true
end

LuaChutou = sgs.CreateTriggerSkill {
    name = 'LuaChutou',
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if room:getTag('FirstRound'):toBool() then
            return false
        end
        -- 获得牌时结算
        if move.to and move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
            if move.from and move.from:objectName() == player:objectName() then
                return false
            end
            for _, id in sgs.qlist(move.card_ids) do
                if room:getCardOwner(id):objectName() == player:objectName() and
                    (room:getCardPlace(id) == sgs.Player_PlaceHand) and move.reason and
                    rinsan.moveBasicReasonCompare(move.reason.m_reason, sgs.CardMoveReason_S_REASON_DRAW) then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local isMax = true
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            if p:getHandcardNum() >= player:getHandcardNum() then
                                isMax = false
                                break
                            end
                        end
                        if isMax then
                            room:sendCompulsoryTriggerLog(player, self:objectName())
                            room:addPlayerMark(player, self:objectName())
                            room:askForDiscard(player, self:objectName(), 1, 1, false, true)
                            room:removePlayerMark(player, self:objectName())
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                        break
                    end
                end
            end
        end
        -- 弃牌时结算
        if canInvokeChutou(player, move) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:drawCards(1, self:objectName())
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaYingshi = sgs.CreateTriggerSkill {
    name = 'LuaYingshi',
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local data2 = sgs.QVariant()
        data2:setValue(death.who)
        for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if sp:isWounded() then
                room:sendCompulsoryTriggerLog(sp, self:objectName())
                rinsan.recover(sp)
            end
        end
        local killer
        if death.damage then
            killer = death.damage.from
        end
        if killer and killer:objectName() == player:objectName() and killer:hasSkill(self:objectName()) then
            -- 如果为伤害来源，则可以二选一
            room:sendCompulsoryTriggerLog(killer, self:objectName())
            local choice = room:askForChoice(killer, self:objectName(), 'LuaYingshiChoice1+LuaYingshiChoice2')
            rinsan.sendLogMessage(room, '#choose', {
                ['from'] = killer,
                ['arg'] = choice,
            })
            if choice == 'LuaYingshiChoice1' then
                -- 加一点体力上限，摸三张牌
                rinsan.addPlayerMaxHp(killer, 1)
                killer:drawCards(3, self:objectName())
            else
                -- 选一个觉醒技外技能并失去一点体力上限
                room:loseMaxHp(killer)
                local skillTable = {}
                local skillChecker = function(skill)
                    return skill:isVisible() and skill:getFrequency() ~= sgs.Skill_Wake
                end
                -- 主将
                for _, skill in ipairs(rinsan.getSkillTable(death.who:getGeneral(), skillChecker)) do
                    -- 移除已有
                    if not killer:hasSkill(skill) and not table.contains(skillTable, skill) then
                        table.insert(skillTable, skill)
                    end
                end
                -- 副将
                for _, skill in ipairs(rinsan.getSkillTable(death.who:getGeneral2(), skillChecker)) do
                    -- 移除已有
                    if not killer:hasSkill(skill) and not table.contains(skillTable, skill) then
                        table.insert(skillTable, skill)
                    end
                end
                local skillChoice = room:askForChoice(killer, self:objectName(), table.concat(skillTable, '+'))
                room:acquireSkill(killer, skillChoice)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

LuaWangming = sgs.CreateTriggerSkill {
    name = 'LuaWangming',
    events = {sgs.Dying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.damage and dying.damage.from and dying.damage.from:objectName() == player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:killPlayer(dying.who, dying.damage)
            return true
        end
        return false
    end,
}

LuaTianfa = sgs.CreateTriggerSkill {
    name = 'LuaTianfa',
    events = {sgs.EventPhaseChanging, sgs.Death},
    global = true,
    priority = -1,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                local shayus = room:findPlayersBySkillName(self:objectName())
                for _, shayu in sgs.qlist(shayus) do
                    room:sendCompulsoryTriggerLog(shayu, self:objectName())
                    local drawPile = room:getDrawPile()
                    local len = drawPile:length()
                    local card_id = drawPile:at(rinsan.random(0, len - 1))
                    local card = sgs.Sanguosha:getCard(card_id)
                    room:throwCard(card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                        shayu:objectName(), self:objectName(), ''), shayu)
                    if card:getSuit() == sgs.Card_Spade then
                        if card:getNumber() >= 2 and card:getNumber() <= 9 then
                            local damage = sgs.DamageStruct()
                            damage.to = player
                            damage.damage = 3
                            damage.nature = sgs.DamageStruct_Thunder
                            room:damage(damage)
                        end
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
                local availablePlayers = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not p:hasSkill(self:objectName()) then
                        availablePlayers:append(p)
                    end
                end
                if not availablePlayers:isEmpty() then
                    local target = room:askForPlayerChosen(player, availablePlayers, self:objectName(),
                        '@LuaTianfa-choose', false, true)
                    room:acquireSkill(target, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaZhixieCard = sgs.CreateSkillCard {
    name = 'LuaZhixieCard',
    filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMark('LuaZhixie')
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaZhixie')
        for _, target in ipairs(targets) do
            target:setChained(true)
            room:broadcastProperty(target, 'chained')
            room:setEmotion(target, 'chain')
            room:getThread():trigger(sgs.ChainStateChanged, room, target)
        end
    end,
}

LuaZhixieVS = sgs.CreateViewAsSkill {
    name = 'LuaZhixie',
    n = 1,
    view_filter = function(self, selected, to_select)
        if sgs.Self:getPhase() ~= sgs.Player_Play then
            return false
        end
        return #selected == 0 and to_select:isKindOf('TrickCard')
    end,
    view_as = function(self, cards)
        if sgs.Self:getPhase() ~= sgs.Player_Play then
            return LuaZhixieCard:clone()
        end
        if #cards == 1 then
            local chain = sgs.Sanguosha:cloneCard('iron_chain', cards[1]:getSuit(), cards[1]:getNumber())
            chain:addSubcard(cards[1])
            chain:setSkillName(self:objectName())
            return chain
        end
        return nil
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaZhixie'
    end,
}

LuaZhixie = sgs.CreateTriggerSkill {
    name = 'LuaZhixie',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    view_as_skill = LuaZhixieVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if room:getCurrent():objectName() == player:objectName() and player:hasSkill(self:objectName()) and
                move.to_place == sgs.Player_DiscardPile then
                local reason = move.reason
                local skillName = reason.m_skillName
                if reason and skillName and skillName == self:objectName() then
                    room:addPlayerMark(player, self:objectName())
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                if player:getMark(self:objectName()) > 0 then
                    room:askForUseCard(player, '@@LuaZhixie', '@LuaZhixie:::' .. player:getMark(self:objectName()))
                    room:setPlayerMark(player, self:objectName(), 0)
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaJixie = sgs.CreateTriggerSkill {
    name = 'LuaJixie',
    events = {sgs.DamageInflicted},
    priority = 3,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Thunder then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            damage.damage = damage.damage - 1
            player:drawCards(1, self:objectName())
            if damage.damage == 0 then
                return true
            end
            data:setValue(damage)
        end
        return false
    end,
}

LuaFumoVS = sgs.CreateViewAsSkill {
    name = 'LuaFumo',
    n = 999,
    response_or_use = false,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_SuitToBeDecided, -1)
            for _, cd in ipairs(selected) do
                slash:addSubcard(cd)
            end
            slash:deleteLater()
            return slash:isAvailable(sgs.Self)
        end
        return true
    end,
    view_as = function(self, cards)
        if #cards >= 2 then
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            for _, cd in ipairs(cards) do
                slash:addSubcard(cd)
            end
            slash:setSkillName(self:objectName())
            return slash
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return pattern == 'slash'
        end
        return false
    end,
}

LuaFumo = sgs.CreateTriggerSkill {
    name = 'LuaFumo',
    view_as_skill = LuaFumoVS,
    events = {sgs.DamageCaused, sgs.TargetConfirmed, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                local containsBlack = rinsan.checkIfSubcardsContainType(damage.card, function(card)
                    return card:isBlack()
                end)
                if containsBlack then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() then
                local containsTrick = rinsan.checkIfSubcardsContainType(use.card, function(card)
                    return card:isKindOf('TrickCard')
                end)
                local containsEquip = rinsan.checkIfSubcardsContainType(use.card, function(card)
                    return card:isKindOf('EquipCard')
                end)
                if containsEquip or containsTrick then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                end
                if containsTrick then
                    for _, to in sgs.qlist(use.to) do
                        local i = 2
                        while not to:isNude() and i > 0 do
                            i = i - 1
                            local card_id = room:askForCardChosen(player, to, 'he', self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            if card_id then
                                room:throwCard(card_id, to, player)
                            else
                                i = 0
                            end
                        end
                    end
                end
                if containsEquip then
                    local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
                    local index = 1
                    for _, p in sgs.qlist(use.to) do
                        local _data = sgs.QVariant()
                        _data:setValue(p)
                        jink_table[index] = 0
                        index = index + 1
                        rinsan.sendLogMessage(room, '#NoJink', {
                            ['from'] = p,
                        })
                    end
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    player:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() then
                local available_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not use.to:contains(p) then
                        if not (use.card:targetFixed()) then
                            if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
                                available_targets:append(p)
                            end
                        end
                    end
                end
                local slashCount = 0
                for _, cd in sgs.qlist(use.card:getSubcards()) do
                    if sgs.Sanguosha:getCard(cd):isKindOf('Slash') then
                        slashCount = slashCount + 1
                    end
                end
                while not available_targets:isEmpty() and slashCount > 0 do
                    local extra = room:askForPlayerChosen(player, available_targets, self:objectName(),
                        '@LuaFumo:::' .. slashCount, true, true)
                    if extra then
                        use.to:append(extra)
                        available_targets:removeOne(extra)
                        slashCount = slashCount - 1
                    else
                        break
                    end
                end
                data:setValue(use)
            end
        end
        return false
    end,
}

LuaFumoTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaFumoTargetMod',
    pattern = 'Slash',
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaFumo') then
            local containsRed = rinsan.checkIfSubcardsContainType(card, function(check_card)
                return check_card:isRed()
            end)
            if containsRed then
                return 1000
            end
            return 0
        end
        return 0
    end,
}

-- 桃色获取卡牌
local function doTaoseGetCard(skill_name, room, source, flags, target)
    if target:getCards(flags):length() > 0 then
        local card_id = room:askForCardChosen(source, target, flags, skill_name, false, sgs.Card_MethodNone)
        room:obtainCard(source, card_id, false)
    end
end

LuaTaoseCard = sgs.CreateSkillCard {
    name = 'LuaTaoseCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaTaose')
        local target = targets[1]
        room:obtainCard(target, self:getSubcards():first())
        doTaoseGetCard('LuaTaose', room, source, 'h', target)
        doTaoseGetCard('LuaTaose', room, source, 'e', target)
        doTaoseGetCard('LuaTaose', room, source, 'j', target)
        if target:getGender() ~= source:getGender() then
            local slash = sgs.Sanguosha:cloneCard('Slash', sgs.Card_NoSuit, 0)
            slash:setSkillName('LuaTaose')
            room:setCardFlag(slash, 'LuaTaose')
            room:useCard(sgs.CardUseStruct(slash, source, target))
        end
    end,
}

LuaTaoseVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaTaose',
    filter_pattern = '.|heart|.|.',
    view_as = function(self, card)
        local ts = LuaTaoseCard:clone()
        ts:addSubcard(card)
        return ts
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaTaoseCard')
    end,
}

LuaTaose = sgs.CreateTriggerSkill {
    name = 'LuaTaose',
    view_as_skill = LuaTaoseVS,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') and damage.card:hasFlag(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
    end,
}

LuaJiaren = sgs.CreateTriggerSkill {
    name = 'LuaJiaren',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and use.to:contains(player) then
            if use.from and use.from:objectName() ~= player:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local suitStr = use.card:getSuitString()
                local judge = rinsan.createJudgeStruct({
                    ['who'] = player,
                    ['reason'] = self:objectName(),
                    ['play_animation'] = true,
                    ['pattern'] = '.|' .. suitStr,
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

LuaFabing = sgs.CreateTriggerSkill {
    name = 'LuaFabing',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.transfer or damage.chain then
            return false
        end
        if damage.card and damage.card:isKindOf('Slash') then
            if damage.nature ~= sgs.DamageStruct_Normal then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
}

LuaChengsheng = sgs.CreateTriggerSkill {
    name = 'LuaChengsheng',
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseChanging, sgs.CardEffected},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card and effect.card:isKindOf('TrickCard') then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:drawCards(1, self:objectName())
                    if room:getCurrent():objectName() == player:objectName() then
                        room:setPlayerFlag(player, 'LuaChengshengSkipDiscardPhase')
                    end
                end
            end
        else
            local phase = data:toPhaseChange().to
            if phase == sgs.Player_Discard then
                if player:hasFlag('LuaChengshengSkipDiscardPhase') then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        player:skip(phase)
                    end
                end
            end
        end
    end,
}

LuaXiandeng = sgs.CreateTriggerSkill {
    name = 'LuaXiandeng',
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            if player:getMark(self:objectName() .. '_biu') > 0 then
                return false
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:addPlayerHistory(player, use.card:getClassName(), -1);
            use.m_addHistory = false
            data:setValue(use)
            room:addPlayerMark(player, self:objectName() .. '_biu')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaXiandengStart = sgs.CreateTriggerSkill {
    name = 'LuaXiandengStart',
    events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName('LuaXiandeng')) do
            if not p:isLord() and p:getMark(self:objectName()) == 0 then
                rinsan.sendLogMessage(room, '#LuaXiandeng', {
                    ['from'] = p,
                    ['arg'] = 'LuaXiandeng',
                })
                room:addPlayerMark(p, self:objectName())
                room:setCurrent(p)
            end
        end
        -- set the turncount to 1
        if room:getCurrent():hasSkill('LuaXiandeng') then
            local currTurn = 1
            room:setPlayerMark(room:getPlayers():at(0), '@clock_time', currTurn)
            room:setTag('TurnLengthCount', sgs.QVariant(currTurn))
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaXiandengTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaXiandengTargetMod',
    pattern = 'Slash',
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaXiandeng') then
            if from:getMark('LuaXiandeng_biu') == 0 then
                return 1000
            end
        end
        return 0
    end,
}

LuaZhiyuanCard = sgs.CreateSkillCard {
    name = 'LuaZhiyuan',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected > 0 then
            local first = selected[1]
            if first:getHandcardNum() <= first:getHp() then
                return to_select:getHandcardNum() <= to_select:getHp()
            end
            return false
        end
        return to_select:getHandcardNum() <= to_select:getHp() or to_select:isWounded()
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        for _, target in ipairs(targets) do
            if target:getHandcardNum() <= target:getHp() then
                target:drawCards(1, self:objectName())
            else
                rinsan.recover(target, 1, source)
            end
        end
    end,
}

LuaZhiyuanVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaZhiyuan',
    view_as = function(self, cards)
        return LuaZhiyuanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaZhiyuan'
    end,
}

LuaZhiyuan = sgs.CreateTriggerSkill {
    name = 'LuaZhiyuan',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaZhiyuanVS,
    on_trigger = function(self, event, player, data, room)
        room:askForUseCard(player, '@@LuaZhiyuan', '@LuaZhiyuan', -1, sgs.Card_MethodNone)
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Start)
    end,
}

LuaYishi = sgs.CreateTriggerSkill {
    name = 'LuaYishi',
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    frequency = sgs.Skill_Change,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.DamageInflicted then
            if damage.from and damage.from:objectName() == player:objectName() then
                return false
            end
        end
        local damageSuffix = (damage.to:objectName() ~= player:objectName()) and 'From' or 'To'
        local targetName = (event == sgs.DamageCaused) and damage.to:objectName() or player:objectName()
        local isMinus = (player:getMark(self:objectName()) == 1)
        local damageString = isMinus and '-1' or '+1'
        local diff = isMinus and -1 or 1
        local prompt = string.format('prompt:%s::%s', targetName, damageString)
        if room:askForSkillInvoke(player, string.format('%s%s', self:objectName(), damageSuffix), sgs.QVariant(prompt)) then
            ChangeSkill(self, room, player)
            room:broadcastSkillInvoke(self:objectName())
            rinsan.sendLogMessage(room, '#LuaYishi', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['to'] = damage.to,
                ['arg2'] = damageString,
            })
            damage.damage = damage.damage + diff
            data:setValue(damage)
            if damage.damage == 0 then
                return true
            end
        end
        return false
    end,
}

LuaManyan = sgs.CreateTriggerSkill {
    name = 'LuaManyan',
    events = {sgs.CardFinished, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardFinished then
            card = data:toCardUse().card
        else
            local response = data:toCardResponse()
            if not response.m_isUse then
                card = response.m_card
            end
        end
        if (not card) or card:isKindOf('SkillCard') then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        local chained_players = {}
        local unchained_players = {}
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isChained() then
                table.insert(chained_players, p)
            else
                table.insert(unchained_players, p)
            end
        end
        if #chained_players > 0 then
            -- 有无必须连的
            local playerToChain = sgs.SPlayerList()
            for _, up in ipairs(unchained_players) do
                for _, cp in ipairs(chained_players) do
                    if up:distanceTo(cp) == 1 and (not playerToChain:contains(up)) then
                        playerToChain:append(up)
                    end
                end
            end
            -- 必须连
            if not playerToChain:isEmpty() then
                local prompt = '@LuaManyan-choose'
                local target = room:askForPlayerChosen(player, playerToChain, self:objectName(), prompt, false)
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
                room:setPlayerChained(target)
                return false
            end
        end
        -- 不满足条件
        local choices = {}
        if #chained_players > 0 then
            table.insert(choices, 'LuaManyanFireDamage')
        end
        if #unchained_players > 0 then
            table.insert(choices, 'LuaManyanChain')
        end
        local playerToChoose = sgs.SPlayerList()
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
        local prompt = string.format('@%s-choose', choice)
        local func = function(victim)
            if choice == 'LuaManyanChain' then
                room:setPlayerChained(victim)
            else
                rinsan.doDamage(player, victim, 1, sgs.DamageStruct_Fire)
            end
        end
        if choice == 'LuaManyanChain' then
            for _, p in ipairs(unchained_players) do
                playerToChoose:append(p)
            end
        else
            for _, p in ipairs(chained_players) do
                playerToChoose:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, playerToChoose, self:objectName(), prompt, false)
        room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), target:objectName())
        func(target)
    end,
}

LuaBaijia = sgs.CreateTriggerSkill {
    name = 'LuaBaijia',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and (not card:isKindOf('SkillCard')) then
            room:setPlayerCardLimitation(player, 'discard', card:toString(), false)
            local available_cards = {}
            for _, cd in sgs.qlist(player:getCards('he')) do
                if not player:isCardLimited(cd, sgs.Card_MethodDiscard) then
                    table.insert(available_cards, cd)
                end
            end
            if #available_cards > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                if not room:askForDiscard(player, self:objectName(), 1, 1, false, true, '@LuaBaijia-Discard') then
                    local c = available_cards[rinsan.random(1, #available_cards)]
                    room:throwCard(c, player)
                end
            end
            room:removePlayerCardLimitation(player, 'discard', card:toString() .. '$0')
        end
    end,
}

-- 锐评技能组
local RUIPING_SKILLS = {
    [1] = 'chouhai', -- 仇海
    [2] = 'shiyong', -- 恃勇
    [3] = 'LuaBaijia', -- 败家
    [4] = 'yingzi', -- 英姿（新）
    [5] = 'bosszuijiu', -- 醉酒（BOSS 战）
}

-- 是否可以通过锐评获取技能
local function canAcquireSkill(player, skillName)
    -- 已有技能则不可以选择
    if player:hasSkill(skillName) then
        return false
    end
    -- 本回合内已经获取过技能了
    if player:getMark('LuaRuiping-Clear') > 0 then
        return false
    end
    return true
end

LuaRuipingCard = sgs.CreateSkillCard {
    name = 'LuaRuiping',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local choices = {}
        for _, skill in ipairs(RUIPING_SKILLS) do
            table.insert(choices, skill)
        end
        table.insert(choices, 'cancel')
        local choice = room:askForChoice(source, self:objectName(), table.concat(choices, '+'))
        if choice ~= 'cancel' then
            table.insert(choices, choice)
        end
        table.removeOne(choices, 'cancel')
        local randomSkill = choices[rinsan.random(1, #choices)]
        rinsan.sendLogMessage(room, '#LuaRuiping', {
            ['from'] = source,
            ['arg'] = randomSkill,
        })
        local available_targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if canAcquireSkill(p, randomSkill) then
                available_targets:append(p)
            end
        end
        if available_targets:isEmpty() then
            return
        end
        local prompt = string.format('%s:%s', 'LuaRuiping-Choose', randomSkill)
        local target = room:askForPlayerChosen(source, available_targets, self:objectName(), prompt)
        if target then
            room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), target:objectName())
            room:addPlayerMark(target, self:objectName() .. '-Clear')
            room:addPlayerMark(target, self:objectName() .. randomSkill)
            room:addPlayerMark(target, source:objectName() .. self:objectName() .. randomSkill)
            room:acquireSkill(target, randomSkill)
        end
    end,
}

LuaRuipingVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaRuiping',
    view_as = function(self, cards)
        return LuaRuipingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#LuaRuiping') < 2
    end,
}

LuaRuiping = sgs.CreateTriggerSkill {
    name = 'LuaRuiping',
    events = {sgs.EventPhaseChanging},
    view_as_skill = LuaRuipingVS,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                for _, skill in ipairs(RUIPING_SKILLS) do
                    local flagMark = player:objectName() .. self:objectName() .. skill
                    if p:getMark(flagMark) > 0 then
                        room:setPlayerMark(p, flagMark, 0)
                    else
                        local mark = self:objectName() .. skill
                        if p:getMark(mark) > 0 then
                            room:setPlayerMark(p, mark, 0)
                            room:detachSkillFromPlayer(p, skill)
                        end
                    end
                end
            end
        end
    end,
}

LuaJiuwenCard = sgs.CreateSkillCard {
    name = 'LuaJiuwen',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return rinsan.canDiscard(sgs.Self, to_select, 'he')
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        for _, p in ipairs(targets) do
            local card_id = room:askForCardChosen(source, p, 'he', self:objectName(), false, sgs.Card_MethodDiscard)
            room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), p:objectName())
            room:throwCard(card_id, p, source)
            room:addPlayerMark(p, self:objectName())
        end
        room:addPlayerMark(source, 'LuaJiuwen-Chosen', #targets)
    end,
}

LuaJiuwenVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaJiuwen',
    view_as = function(self)
        return LuaJiuwenCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == '@@LuaJiuwen'
    end,
}

LuaJiuwen = sgs.CreateTriggerSkill {
    name = 'LuaJiuwen',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaJiuwenVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if rinsan.canDiscard(player, p, 'he') then
                    room:askForUseCard(player, '@@LuaJiuwen', '@LuaJiuwen')
                    break
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            local x = player:getMark('LuaJiuwen-Chosen')
            room:setPlayerMark(player, 'LuaJiuwen-Chosen', 0)
            player:drawCards(x, self:objectName())
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark(self:objectName()) > 0 then
                    if player:isNude() then
                        break
                    end
                    if p:objectName() ~= player:objectName() then
                        local prompt = string.format('LuaJiuwen-Give:%s', p:objectName())
                        local card = room:askForExchange(player, self:objectName(), 1, 1, true, prompt)
                        p:obtainCard(card, false)
                    end
                end
                room:setPlayerMark(p, self:objectName(), 0)
            end
        end
    end,
}

LuaJiuwenDamaged = sgs.CreateTriggerSkill {
    name = 'LuaJiuwenDamaged',
    events = {sgs.Damaged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('LuaJiuwen') > 0 then
            room:setPlayerMark(player, 'LuaJiuwen', 0)
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaDuzhanCard = sgs.CreateSkillCard {
    name = 'LuaDuzhan',
    will_throw = false,
    target_fixed = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        target:obtainCard(sgs.Sanguosha:getCard(self:getSubcards():first()))
        local prompt = string.format('LuaDuzhanChooseSlashTarget:%s', target:objectName())
        local victims = room:getOtherPlayers(target)
        local victim = room:askForPlayerChosen(source, victims, self:objectName(), prompt, false, true)
        local slashPrompt = string.format('@LuaDuzhanSlashTo:%s:%s', source:objectName(), victim:objectName())
        if not room:askForUseSlashTo(target, victim, slashPrompt) then
            if not target:isNude() then
                local card_id = room:askForCardChosen(source, target, 'he', self:objectName(), false,
                    sgs.Card_MethodNone)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
                room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
            end
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(slash, source, target))
        end
    end,
}

LuaDuzhan = sgs.CreateOneCardViewAsSkill {
    name = 'LuaDuzhan',
    filter_pattern = '.',
    view_as = function(self, card)
        local vs_card = LuaDuzhanCard:clone()
        vs_card:addSubcard(card)
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaDuzhan')
    end,
}

local function askForLixing(mikang, currentPlayer)
    local room = mikang:getRoom()
    local card = room:askForCard(mikang, '.|.|.|.|.', '@LuaLixing-Give:' .. currentPlayer:objectName(), sgs.QVariant(),
        sgs.Card_MethodNone)
    if card then
        room:showCard(mikang, card:getEffectiveId())
        room:addPlayerMark(mikang, 'LuaLixing-Clear')
        currentPlayer:obtainCard(card, false)
        rectification.askForRectification(mikang, currentPlayer, 'LuaLixing', false)
    end
end

LuaLixing = sgs.CreateTriggerSkill {
    name = 'LuaLixing',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Play then
            return false
        end
        for _, mikang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if mikang:getMark(self:objectName() .. '-Clear') == 0 then
                askForLixing(mikang, player)
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaLixingExtraPhase = sgs.CreateTriggerSkill {
    name = 'LuaLixingExtraPhase',
    events = {sgs.EventPhaseEnd},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getMark('LuaLixingExtraPlayPhase') > 0 then
            room:setPlayerMark(player, 'LuaLixingExtraPlayPhase', 0)
            rinsan.sendLogMessage(room, '#LuaDangxianExtraPhase', {
                ['from'] = player,
            })
            rinsan.executeExtraPhase(player, sgs.Player_Play)
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaQinggong = sgs.CreateTriggerSkill {
    name = 'LuaQinggong',
    events = {sgs.CardsMoveOneTime, sgs.HpRecover},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local invokable
        if room:getTag('FirstRound'):toBool() then
            return false
        end
        if event == sgs.HpRecover then
            invokable = player:getPhase() ~= sgs.Player_Play
        else
            local move = data:toMoveOneTime()
            if player:getPhase() == sgs.Player_Draw then
                return false
            end
            invokable = move.to and (move.to:objectName() == player:objectName()) and (move.card_ids:length() >= 2)
            if (not invokable) or (move.from and move.to and move.from:objectName() == move.to:objectName()) then
                return false
            end
        end
        if invokable then
            for _, mikang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(mikang, self:objectName(), data) then
                    mikang:drawCards(1, self:objectName())
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

Cactus:addSkill(LuaBaipiao)
Fuhua:addSkill(LuaGeidian)
Rinsan:addSkill(LuaWanneng)
Rinsan:addSkill(LuaSoutu)
SPFuhua:addSkill(LuaYangjing)
SPFuhua:addSkill(LuaTuci)
SPCactus:addSkill(LuaJuesha)
SPCactus:addSkill(LuaMouhai)
SPCactus:addSkill(LuaChuanyi)
Qiumu:addSkill(LuaPaozhuan)
Qiumu:addSkill(LuaYinyu)
SPRinsan:addSkill(LuaQingyu)
SPRinsan:addSkill(LuaJiaoxie)
SPRinsan:addSkill(LuaShulian)
Anan:addSkill(LuaZhazhi)
Anan:addSkill(LuaJueding)
Erenlei:addSkill(LuaXunxin)
Erenlei:addSkill(LuaChutou)
Yaoyu:addSkill(LuaYingshi)
Yaoyu:addSkill(LuaWangming)
Shayu:addSkill(LuaTianfa)
Shayu:addSkill(LuaZhixie)
Shayu:addSkill(LuaJixie)
Yeniao:addSkill(LuaFumo)
Linxi:addSkill(LuaTaose)
Linxi:addSkill('hongyan')
Ajie:addSkill(LuaJiaren)
Ajie:addSkill(LuaFabing)
Ajie:addSkill(LuaChengsheng)
Shatang:addSkill(LuaXiandeng)
Shatang:addSkill(LuaZhiyuan)
Dalaojiang:addSkill(LuaYishi)
Dalaojiang:addSkill(LuaManyan)
Zhongliao:addSkill(LuaRuiping)
Zhongliao:addSkill(LuaJiuwen)
for _, relateSkill in ipairs(RUIPING_SKILLS) do
    Zhongliao:addRelateSkill(relateSkill)
end
Mikang:addSkill(LuaDuzhan)
Mikang:addSkill(LuaLixing)
Mikang:addSkill(LuaQinggong)

table.insert(hiddenSkills, LuaZibao)
table.insert(hiddenSkills, LuaSoutuVS)
table.insert(hiddenSkills, LuaYangjingAttackRange)
table.insert(hiddenSkills, LuaQingyuTargetMod)
table.insert(hiddenSkills, LuaQingyuMaxCards)
table.insert(hiddenSkills, LuaShulianForbidden)
table.insert(hiddenSkills, LuaFumoTargetMod)
table.insert(hiddenSkills, LuaXiandengStart)
table.insert(hiddenSkills, LuaXiandengTargetMod)
table.insert(hiddenSkills, LuaBaijia)
table.insert(hiddenSkills, LuaJiuwenDamaged)
table.insert(hiddenSkills, LuaLixingExtraPhase)

rinsan.addHiddenSkills(hiddenSkills)
