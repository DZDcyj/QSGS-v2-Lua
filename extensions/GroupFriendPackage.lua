module('extensions.GroupFriendPackage', package.seeall)
extension = sgs.Package('GroupFriendPackage')
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)
Skadi = sgs.General(extension, 'Skadi', 'god', '5', false, true)
Cactus = sgs.General(extension, 'Cactus', 'wu', '4', true, true)
Fuhua = sgs.General(extension, 'Fuhua', 'qun', '4', true, true)
Rinsan = sgs.General(extension, 'Rinsan', 'shu', '3', true, true)
SPFuhua = sgs.General(extension, 'SPFuhua', 'qun', '4', true, true)
SPCactus = sgs.General(extension, 'SPCactus', 'wei', '4', true, true)
Qiumu = sgs.General(extension, 'Qiumu', 'qun', '3', true, true)
SPRinsan = sgs.General(extension, 'SPRinsan', 'shu', '4', true, true)
Anan = sgs.General(extension, 'Anan', 'qun', '4', false, true)
Erenlei = sgs.General(extension, 'Erenlei', 'wu', '3', true, true)
Yaoyu = sgs.General(extension, 'Yaoyu', 'wu', '4', true, true)
Shayu = sgs.General(extension, 'Shayu', 'qun', '3', true, true)
Yeniao = sgs.General(extension, 'Yeniao', 'shu', '4', true, true)
Linxi = sgs.General(extension, 'Linxi', 'qun', '3', false, true)

-- 额外设置其他信息，例如性别
-- 性别有以下枚举值，分别代表无性、男性、女性、中性（似乎与无性别一致）
-- Sexless, Male, Female, Neuter
-- 枚举值使用时加上 sgs.General_ 前缀
-- 例如 sgs.General_Sexless
Shayu:setGender(sgs.General_Sexless)

LuaChuntian =
    sgs.CreateTriggerSkill {
    name = 'LuaChuntian',
    events = {sgs.CardUsed, sgs.Damaged, sgs.HpLost},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() then
                if use.card:isKindOf('Peach') then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    player:gainMark('@Faqing')
                end
            end
        elseif event == sgs.Damaged then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:gainMark('@Faqing', data:toDamage().damage)
        elseif event == sgs.HpLost then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:gainMark('@Faqing', data:toInt())
        end
    end
}

LuaPenshuiCard =
    sgs.CreateSkillCard {
    name = 'LuaPenshui',
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark('@Faqing') and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        source:loseMark('@Faqing', #targets)
        for _, p in ipairs(targets) do
            p:throwAllEquips()
            room:damage(sgs.DamageStruct(self:objectName(), source, p, 1))
        end
    end
}

LuaPenshuiVS =
    sgs.CreateViewAsSkill {
    name = 'LuaPenshui',
    view_as = function(self, cards)
        return LuaPenshuiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaPenshui'
    end
}

LuaPenshui =
    sgs.CreateTriggerSkill {
    name = 'LuaPenshui',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaPenshuiVS,
    on_trigger = function(self, event, player, data, room)
        room:askForUseCard(player, '@@LuaPenshui', '@LuaPenshui')
        return false
    end,
    can_trigger = function(self, target)
        if target then
            if target:isAlive() and target:hasSkill(self:objectName()) then
                if target:getPhase() == sgs.Player_Start then
                    return target:getMark('@Faqing') > 0
                end
            end
        end
    end
}

LuaGaochao =
    sgs.CreateTriggerSkill {
    name = 'LuaGaochao',
    events = {sgs.MarkChanged},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == '@Faqing' and mark.who:hasSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            if room:changeMaxHpForAwakenSkill(player) then
                room:acquireSkill(player, LuaPenshui)
                room:addPlayerMark(player, 'LuaGaochao')
            end
        end
    end,
    can_trigger = function(self, player)
        return player:getMark('@Faqing') > 2 and player:getMark('LuaGaochao') == 0
    end
}

LuaBaipiao =
    sgs.CreateTriggerSkill {
    name = 'LuaBaipiao',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if player:hasSkill(self:objectName()) then
            if
                (move.from and (move.from:objectName() == player:objectName()) and
                    (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)))
             then
                if (move.to_place == sgs.Player_DiscardPile) then
                    if
                        not ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                            sgs.CardMoveReason_S_REASON_USE) or
                            (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                                sgs.CardMoveReason_S_REASON_RESPONSE) or
                            move.reason.m_reason == sgs.CardMoveReason_S_REASON_CHANGE_EQUIP)
                     then
                        local targets = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if not p:isAllNude() then
                                targets:append(p)
                            end
                        end
                        if not targets:isEmpty() then
                            room:sendCompulsoryTriggerLog(player, self:objectName())
                            local target =
                                room:askForPlayerChosen(
                                player,
                                targets,
                                self:objectName(),
                                'LuaBaipiao-invoke',
                                false,
                                true
                            )
                            if target then
                                local card_id =
                                    room:askForCardChosen(
                                    player,
                                    target,
                                    'hej',
                                    self:objectName(),
                                    false,
                                    sgs.Card_MethodNone
                                )
                                local reason =
                                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                                room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                            end
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

LuaGeidianCard =
    sgs.CreateSkillCard {
    name = 'LuaGeidianCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
    end,
    on_use = function(self, room, source, targets)
        for _, p in ipairs(targets) do
            local card =
                room:askForCard(
                p,
                '.|.|.|.|hand,equiped',
                '@LuaGeidian-ask:' .. source:objectName(),
                sgs.QVariant(),
                sgs.Card_MethodNone
            )
            if not card then
                local equipOrHand = math.random(0, 1)
                if p:getEquips():isEmpty() then
                    card = p:getHandcards():at(math.random(0, p:getHandcardNum() - 1))
                elseif p:getHandcardNum() == 0 then
                    card = p:getEquips():at(math.random(0, p:getEquips():length() - 1))
                else
                    if equipOrHand == 0 then
                        card = p:getHandcards():at(math.random(0, p:getHandcardNum() - 1))
                    else
                        card = p:getEquips():at(math.random(0, p:getEquips():length() - 1))
                    end
                end
            end
            source:obtainCard(card, false)
        end
        local slash = sgs.Sanguosha:cloneCard('Slash', sgs.Card_NoSuit, 0)
        slash:setSkillName('LuaGeidian')
        if #targets > 2 then
            for _, target in ipairs(targets) do
                room:useCard(sgs.CardUseStruct(slash, target, source))
            end
        end
    end
}

LuaGeidian =
    sgs.CreateViewAsSkill {
    name = 'LuaGeidian',
    n = 0,
    view_as = function(self, cards)
        return LuaGeidianCard:clone()
    end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getSiblings()) do
            if not p:isNude() then
                return not player:hasUsed('#LuaGeidianCard')
            end
        end
        return false
    end
}

LuaWannengCard =
    sgs.CreateSkillCard {
    name = 'LuaWannengCard',
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
        local _card = sgs.Self:getTag('LuaWanneng'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        -- card:setCanRecast(false)
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
        local _card = sgs.Self:getTag('LuaWanneng'):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        -- card:setCanRecast(false)
        card:deleteLater()
        return card and card:targetsFeasible(players, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local to_use = self:getUserString()
        room:addPlayerMark(source, 'LuaWanneng')
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
            to_use = room:askForChoice(source, 'wanneng_slash', table.concat(use_list, '+'))
            source:setTag('WannengSlash', sgs.QVariant(to_use))
        end
        local user_str = to_use
        -- source:setTag("WannengSlash", sgs.QVariant(user_str))
        local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
        if use_card == nil then
            use_card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        end
        use_card:setSkillName('LuaWanneng')
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
        room:addPlayerMark(source, 'LuaWanneng')
        if self:getUserString() == 'peach+analeptic' then
            local use_list = {}
            table.insert(use_list, 'peach')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'analeptic')
            end
            to_use = room:askForChoice(source, 'wanneng_saveself', table.concat(use_list, '+'))
            source:setTag('WannengSaveSelf', sgs.QVariant(to_use))
        elseif self:getUserString() == 'slash' then
            local use_list = {}
            table.insert(use_list, 'slash')
            local sts = sgs.GetConfig('BanPackages', '')
            if not string.find(sts, 'maneuvering') then
                table.insert(use_list, 'normal_slash')
                table.insert(use_list, 'thunder_slash')
                table.insert(use_list, 'fire_slash')
            end
            to_use = room:askForChoice(source, 'wanneng_slash', table.concat(use_list, '+'))
            source:setTag('WannengSlash', sgs.QVariant(to_use))
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
        local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
        use_card:setSkillName('LuaWanneng')
        use_card:deleteLater()
        return use_card
    end
}

LuaWannengVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaWanneng',
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
        if string.sub(pattern, 1, 1) == '.' or string.sub(pattern, 1, 1) == '@' or player:getMark('LuaWanneng') > 0 then
            return false
        end
        if pattern == 'peach' and player:getMark('Global_PreventPeach') > 0 then
            return false
        end
        -- if pattern == "nullification" then return false end
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
        return player:getMark('LuaWanneng') == 0
    end,
    enabled_at_nullification = function(self, player)
        return player:getMark('LuaWanneng') == 0
    end,
    view_as = function(self, cards)
        if
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
         then
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
    end
}

LuaWanneng =
    sgs.CreateTriggerSkill {
    name = 'LuaWanneng',
    events = {sgs.TurnStart},
    view_as_skill = LuaWannengVS,
    global = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill('LuaWanneng') then
                room:setPlayerMark(p, 'LuaWanneng', 0)
            end
        end
    end
}

LuaWanneng:setGuhuoDialog('lr')

LuaXiaosa =
    sgs.CreateTriggerSkill {
    name = 'LuaXiaosa',
    events = {sgs.TargetConfirmed, sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart then
            room:setPlayerMark(player, self:objectName(), 0)
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() then
                return false
            end -- 使用者不为玩家
            if use.card:isKindOf('BasicCard') or use.card:isNDTrick() then
                if use.to:contains(player) then
                    if player:getMark(self:objectName()) == 0 then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:addPlayerMark(player, self:objectName())
                            local nullified_list = use.nullified_list
                            for _, dest in sgs.qlist(use.to) do
                                table.insert(nullified_list, dest:objectName())
                            end
                            use.nullified_list = nullified_list
                            data:setValue(use)
                        end
                    end
                end
            end
        end
        return false
    end
}

LuaMasochism =
    sgs.CreateTriggerSkill {
    name = 'LuaMasochism',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardEffected},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local effect = data:toCardEffect()
        local card = effect.card
        local hp = player:getHp()
        if hp > 0 then
            if player:isAlive() then
                if card:isKindOf('Peach') then
                    if player:hasSkill(self:objectName()) then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        return true
                    end
                end
            end
        end
    end
}

LuaZibao =
    sgs.CreateTriggerSkill {
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
    end
}

function doSoutu(card, soutuer, rinsan, room, self)
    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
    local ids = sgs.IntList()
    local i = 0
    while i < 3 do
        i = i + 1
        ids:append(room:drawCard())
    end
    room:fillAG(ids, rinsan)
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
    rinsan:obtainCard(dummy)
    room:clearAG()
    local to_goback =
        room:askForExchange(rinsan, self:objectName(), rinsan:getHandcardNum(), 1, false, 'LuaSoutuGoBack', true)
    local reason =
        sgs.CardMoveReason(
        sgs.CardMoveReason_S_REASON_GIVE,
        rinsan:objectName(),
        soutuer:objectName(),
        self:objectName(),
        nil
    )
    if to_goback then
        room:doAnimate(1, rinsan:objectName(), soutuer:objectName())
        room:moveCardTo(to_goback, rinsan, soutuer, sgs.Player_PlaceHand, reason, true)
    end
end

LuaSoutuCard =
    sgs.CreateSkillCard {
    name = 'LuaSoutuCard',
    target_fixed = false,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:hasSkill('LuaSoutu') and to_select:objectName() ~= sgs.Self:objectName() and
            not to_select:hasFlag('LuaSoutuInvoked')
    end,
    on_use = function(self, room, source, targets)
        local Rinsan = targets[1]
        if Rinsan:hasSkill('LuaSoutu') then
            room:setPlayerFlag(Rinsan, 'LuaSoutuInvoked')
            room:notifySkillInvoked(Rinsan, 'LuaSoutu')
            Rinsan:obtainCard(self)
            doSoutu(sgs.Sanguosha:getCard(self:getSubcards():first()), source, Rinsan, Rinsan:getRoom(), self)
            local Rinsans = room:getLieges('shu', Rinsan)
            if Rinsans:isEmpty() then
                room:setPlayerFlag(source, 'ForbidSoutu')
            end
        end
    end
}

LuaSoutuVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaSoutuVS&',
    filter_pattern = '.',
    view_as = function(self, card)
        local acard = LuaSoutuCard:clone()
        acard:addSubcard(card)
        return acard
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag('ForbidSoutu')
    end
}

LuaSoutu =
    sgs.CreateTriggerSkill {
    name = 'LuaSoutu',
    frequency = sgs.Skill_NotFrequent,
    events = {
        sgs.GameStart,
        sgs.TurnStart,
        sgs.EventPhaseChanging,
        sgs.EventAcquireSkill,
        sgs.EventLoseSkill
    },
    on_trigger = function(self, triggerEvent, player, data)
        local room = player:getRoom()
        local rinsans = room:findPlayersBySkillName(self:objectName())
        if
            (triggerEvent == sgs.TurnStart) or (triggerEvent == sgs.GameStart) or
                (triggerEvent == sgs.EventAcquireSkill and data:toString() == 'LuaSoutu')
         then
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
    end
}

LuaYangjing =
    sgs.CreateTriggerSkill {
    name = 'LuaYangjing',
    frequency = sgs.Skill_Compulsory,
    events = {
        sgs.PreCardUsed,
        sgs.EventPhaseEnd,
        sgs.CardFinished,
        sgs.DamageCaused,
        sgs.TargetSpecified
    },
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
                room:doAnimate(1, damage.from:objectName(), damage.to:objectName())
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
                room:doAnimate(1, player:objectName(), p:objectName())
            end
        end
    end
}

LuaYangjingTargetMod =
    sgs.CreateTargetModSkill {
    name = 'LuaYangjingTargetMod',
    pattern = 'Slash',
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaYangjing') then
            return from:getMark('@LuaJing')
        else
            return 0
        end
    end
}

LuaTuci =
    sgs.CreateTriggerSkill {
    name = 'LuaTuci',
    events = {sgs.TargetSpecified},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf('Slash') then
            return false
        end
        local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
        local index = 1
        for _, p in sgs.qlist(use.to) do
            if not player:isAlive() then
                break
            end
            if p:isAlive() and p:distanceTo(player) < player:getAttackRange() + player:getMark('@LuaJing') then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local msg = sgs.LogMessage()
                msg.type = '#NoJink'
                msg.from = p
                room:sendLog(msg)
                jink_table[index] = 0
            end
            index = index + 1
        end
        local jink_data = sgs.QVariant()
        jink_data:setValue(Table2IntList(jink_table))
        player:setTag('Jink_' .. use.card:toString(), jink_data)
        return false
    end
}

LuaNosJuesha =
    sgs.CreateTriggerSkill {
    name = 'LuaNosJuesha',
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local data2 = sgs.QVariant()
        data2:setValue(dying.who)
        if player:getMark(self:objectName()) == 0 and room:askForSkillInvoke(player, self:objectName(), data2) then
            room:doAnimate(1, player:objectName(), dying.who:objectName())
            room:addPlayerMark(player, self:objectName())
            room:loseHp(dying.who)
            room:removePlayerMark(player, self:objectName())
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill(self:objectName())
    end
}

SkillAnjiang:addSkill(LuaNosJuesha)

LuaJuesha =
    sgs.CreateTriggerSkill {
    name = 'LuaJuesha',
    events = {sgs.Dying, sgs.CardUsed, sgs.QuitDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Dying then
            local dying = data:toDying()
            local data2 = sgs.QVariant()
            data2:setValue(dying.who)
            if player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data2) then
                room:doAnimate(1, player:objectName(), dying.who:objectName())
                room:addPlayerMark(dying.who, self:objectName() .. player:objectName())
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

LuaMouhai =
    sgs.CreateTriggerSkill {
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
                local target =
                    room:askForPlayerChosen(player, targets, self:objectName(), 'LuaMouhai-choose', true, true)
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
    end
}

LuaChuanyiCard =
    sgs.CreateSkillCard {
    name = 'LuaChuanyiCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:detachSkillFromPlayer(source, 'LuaChuanyi')
    end
}

LuaChuanyiVS =
    sgs.CreateZeroCardViewAsSkill {
    name = 'LuaChuanyi',
    view_as = function(self, cards)
        return LuaChuanyiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

LuaChuanyi =
    sgs.CreateTriggerSkill {
    name = 'LuaChuanyi',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaChuanyiVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark('@' .. self:objectName()) == 0 then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target =
                    room:askForPlayerChosen(player, targets, self:objectName(), 'LuaChuanyi-choose', true, true)
                if target then
                    room:loseMaxHp(player)
                    local choose = room:askForChoice(player, self:objectName(), 'LuaJuesha+LuaMouhai')
                    room:acquireSkill(target, choose)
                    room:addPlayerMark(target, '@' .. self:objectName())
                end
            end
        end
        return false
    end
}

LuaPaoZhuan =
    sgs.CreateTriggerSkill {
    name = 'LuaPaozhuan',
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then
            if move.to and move.to:objectName() ~= player:objectName() then
                if
                    (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and
                        (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)
                 then
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
                        room:doAnimate(1, player:objectName(), target:objectName())
                        room:damage(sgs.DamageStruct(self:objectName(), player, target))
                    end
                end
            end
        end
    end
}

LuaYinyu =
    sgs.CreateTriggerSkill {
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
                        local card =
                            room:askForCard(
                            p,
                            '.',
                            '@LuaYinyu-show',
                            data2,
                            sgs.Card_MethodNone,
                            nil,
                            false,
                            self:objectName()
                        )
                        if card then
                            local log = sgs.LogMessage()
                            log.from = p
                            log.type = '#InvokeSkill'
                            log.arg = self:objectName()
                            room:sendLog(log)
                            room:showCard(p, card:getEffectiveId())
                            local reason =
                                sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_GIVE,
                                p:objectName(),
                                player:objectName(),
                                self:objectName(),
                                nil
                            )
                            room:doAnimate(1, p:objectName(), player:objectName())
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
                            room:doAnimate(1, p:objectName(), player:objectName())
                            player:drawCards(1)
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        end
        return false
    end
}

LuaQingyu =
    sgs.CreateTriggerSkill {
    name = 'LuaQingyu',
    events = {sgs.Damage, sgs.SlashEffected},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if player:getHandcardNum() >= player:getHp() then
                local choices = 'draw1+cancel'
                local i = 0
                while i < damage.damage do
                    i = i + 1
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    local choice = room:askForChoice(player, self:objectName(), choices)
                    if choice == 'draw1' then
                        player:drawCards(1)
                    else
                        break
                    end
                end
            end
        elseif event == sgs.SlashEffected then
            if player:getHandcardNum() <= player:getHp() / 2 then
                local effect = data:toSlashEffect()
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local msg = sgs.LogMessage()
                msg.type = '#NoJink'
                msg.from = player
                room:sendLog(msg)
                room:slashResult(effect, nil)
                return true
            end
        end
        return false
    end
}

LuaQingyuTargetMod =
    sgs.CreateTargetModSkill {
    name = '#LuaQingyuTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = '.',
    residue_func = function(self, player)
        if player:hasSkill('LuaQingyu') then
            if player:getHp() <= player:getHandcardNum() then
                return 1000
            end
        end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaQingyu') then
            if from:getHp() <= from:getHandcardNum() then
                return 1000
            end
        end
        return 0
    end
}

LuaJiaoxie =
    sgs.CreateTriggerSkill {
    name = 'LuaJiaoxie',
    events = {sgs.Damaged, sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if player:hasSkill(self:objectName()) then
                if damage.from:getMark('LuaJiaoxieForbid') > 0 then
                    return false
                end
                if damage.from then
                    local data2 = sgs.QVariant()
                    data2:setValue(damage.from)
                    if room:askForSkillInvoke(player, self:objectName(), data2) then
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        room:doAnimate(1, player:objectName(), damage.from:objectName())
                        if damage.from:hasEquip() then
                            for _, cd in sgs.qlist(damage.from:getEquips()) do
                                dummy:addSubcard(cd)
                            end
                            damage.from:addToPile('LuaJiaoxie', dummy)
                        end
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
                for _, cd in sgs.qlist(player:getPile('LuaJiaoxie')) do
                    local card = sgs.Sanguosha:getCard(cd)
                    room:moveCardTo(
                        card,
                        player,
                        player,
                        sgs.Player_PlaceEquip,
                        sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_TRANSFER,
                            player:objectName(),
                            self:objectName(),
                            ''
                        )
                    )
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaShulian =
    sgs.CreateTriggerSkill {
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
    end
}

LuaShulianForbidden =
    sgs.CreateProhibitSkill {
    name = 'LuaShulianForbidden',
    is_prohibited = function(self, from, to, card)
        if to:hasSkill('LuaShulian') then
            return card:isKindOf('DelayedTrick')
        end
    end
}

LuaZhazhi =
    sgs.CreateTriggerSkill {
    name = 'LuaZhazhi',
    events = {
        sgs.EventPhaseStart,
        sgs.DamageCaused,
        sgs.EventPhaseChanging,
        sgs.PreCardUsed,
        sgs.Damage
    },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                local splayers = room:findPlayersBySkillName(self:objectName())
                for _, sp in sgs.qlist(splayers) do
                    if sp:objectName() ~= player:objectName() and player:inMyAttackRange(sp) then
                        local data2 = sgs.QVariant()
                        data2:setValue(player)
                        if room:askForSkillInvoke(sp, self:objectName(), data2) then
                            room:doAnimate(1, sp:objectName(), player:objectName())
                            player:setFlags('LuaZhazhiTarget')
                            local slash =
                                room:askForUseSlashTo(player, sp, '@LuaZhazhi-slash:' .. sp:objectName(), false, true)
                            if not slash then
                                player:setFlags('-LuaZhazhiTarget')
                                room:addPlayerMark(player, 'LuaZhazhiDebuff' .. sp:objectName())
                                room:addPlayerMark(player, '@LuaZhazhi')
                            else
                                player:setFlags('-LuaZhazhiTarget')
                                if not sp:hasFlag('LuaZhazhiDefenseFailed') then
                                    sp:drawCards(1)
                                    room:recover(sp, sgs.RecoverStruct(sp, nil, 1))
                                    sp:setFlags('-LuaZhazhiDefenseFailed')
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            local slash = use.card
            if use.from:hasFlag('LuaZhazhiTarget') then
                room:setCardFlag(slash, 'LuaZhazhiSlash')
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card then
                if damage.card:hasFlag('LuaZhazhiSlash') then
                    damage.to:setFlags('LuaZhazhiDefenseFailed')
                    room:setCardFlag(damage.card, '-LuaZhazhiSlash')
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                -- room:sendCompulsoryTriggerLog(player, self:objectName())
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
                local loc = sgs.LogMessage()
                loc.type = '#LuaZhazhi'
                loc.arg = damageNum
                loc.arg2 = damage.damage
                loc.from = damage.from
                room:sendLog(loc)
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
    can_trigger = function(self, target)
        return target
    end
}

LuaShaikaCard =
    sgs.CreateSkillCard {
    name = 'LuaShaikaCard',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
            to_select:getMark('LuaShaikaTarget') == 0
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local len = self:getSubcards():length() + 1
        if
            not room:askForDiscard(
                target,
                'LuaShaika',
                len,
                len,
                true,
                false,
                '@LuaShaika:' .. source:objectName() .. '::' .. len
            )
         then
            local damage = sgs.DamageStruct()
            damage.from = source
            damage.to = target
            damage.damage = 1
            room:damage(damage)
        end
        room:addPlayerMark(target, 'LuaShaikaTarget')
    end
}

LuaShaikaVS =
    sgs.CreateViewAsSkill {
    name = 'LuaShaika',
    n = 999,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getMark('LuaShaika' .. to_select:objectName()) == 0
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local vs_card = LuaShaikaCard:clone()
        local containsTrick
        for _, cd in ipairs(cards) do
            vs_card:addSubcard(cd)
            if cd:isKindOf('TrickCard') then
                containsTrick = true
            end
        end
        if containsTrick then
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        for _, sib in sgs.qlist(player:getAliveSiblings()) do
            if sib:getMark('LuaShaikaTarget') == 0 then
                return not player:isNude()
            end
        end
        return false
    end
}

LuaShaika =
    sgs.CreateTriggerSkill {
    name = 'LuaShaika',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    view_as_skill = LuaShaikaVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if room:getCurrent():objectName() == player:objectName() and player:hasSkill(self:objectName()) then
                if move.to_place == sgs.Player_DiscardPile then
                    for _, id in sgs.qlist(move.card_ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        room:addPlayerMark(player, self:objectName() .. card:objectName())
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

LuaChutou =
    sgs.CreateTriggerSkill {
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
                if
                    room:getCardOwner(id):objectName() == player:objectName() and
                        (room:getCardPlace(id) == sgs.Player_PlaceHand) and
                        move.reason and
                        (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                            sgs.CardMoveReason_S_REASON_DRAW)
                 then
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
        if
            (move.from and (move.from:objectName() == player:objectName()) and
                (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and
                not (move.to and
                    (move.to:objectName() == player:objectName() and
                        (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
         then
            if
                move.reason and
                    (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                        sgs.CardMoveReason_S_REASON_DISCARD) and
                    player:getMark(self:objectName()) == 0 and
                    player:hasSkill(self:objectName())
             then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(1)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaYingshi =
    sgs.CreateTriggerSkill {
    name = 'LuaYingshi',
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local data2 = sgs.QVariant()
        data2:setValue(death.who)
        for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(sp, self:objectName(), data2) then
                room:doAnimate(1, sp:objectName(), death.who:objectName())
                local skillTable = {}
                -- 添加主将技能
                for _, skill in ipairs(getSkillTable(death.who:getGeneral())) do
                    table.insert(skillTable, skill)
                end
                -- 添加副将技能
                for _, skill in ipairs(getSkillTable(death.who:getGeneral2())) do
                    table.insert(skillTable, skill)
                end
                -- 移除已有技能
                for _, skill in ipairs(skillTable) do
                    if sp:hasSkill(skill) then
                        table.removeOne(skillTable, skill)
                    end
                end
                table.insert(skillTable, 'cancel')
                while #skillTable > 1 do
                    local choice = room:askForChoice(sp, self:objectName(), table.concat(skillTable, '+'))
                    if choice ~= 'cancel' then
                        table.removeOne(skillTable, choice)
                        room:acquireSkill(sp, choice)
                    else
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end
}

LuaWangming =
    sgs.CreateTriggerSkill {
    name = 'LuaWangming',
    events = {sgs.Dying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.damage and dying.damage.from and dying.damage.from:objectName() == player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local damage = sgs.DamageStruct()
            damage.from = player
            room:killPlayer(dying.who, damage)
            return true
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill(self:objectName())
    end
}

LuaTianfa =
    sgs.CreateTriggerSkill {
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
                    local card_id = drawPile:at(math.random(0, len - 1))
                    local card = sgs.Sanguosha:getCard(card_id)
                    room:throwCard(
                        card,
                        sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                            shayu:objectName(),
                            self:objectName(),
                            ''
                        ),
                        shayu
                    )
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
                    local target =
                        room:askForPlayerChosen(
                        player,
                        availablePlayers,
                        self:objectName(),
                        '@LuaTianfa-choose',
                        false,
                        true
                    )
                    room:acquireSkill(target, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

LuaZhixieCard =
    sgs.CreateSkillCard {
    name = 'LuaZhixieCard',
    filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMark('LuaZhixie')
    end,
    on_use = function(self, room, source, targets)
        for _, target in ipairs(targets) do
            target:setChained(true)
            room:broadcastProperty(target, 'chained')
            room:setEmotion(target, 'chain')
            room:getThread():trigger(sgs.ChainStateChanged, room, target)
        end
    end
}

LuaZhixieVS =
    sgs.CreateViewAsSkill {
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
    end
}

LuaZhixie =
    sgs.CreateTriggerSkill {
    name = 'LuaZhixie',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    view_as_skill = LuaZhixieVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if
                room:getCurrent():objectName() == player:objectName() and player:hasSkill(self:objectName()) and
                    move.to_place == sgs.Player_DiscardPile
             then
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
    can_trigger = function(self, target)
        return target
    end
}

LuaJixie =
    sgs.CreateTriggerSkill {
    name = 'LuaJixie',
    events = {sgs.DamageInflicted},
    priority = 3,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Thunder then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            damage.damage = damage.damage - 1
            player:drawCards(1)
            if damage.damage == 0 then
                return true
            end
            data:setValue(damage)
        end
        return false
    end
}

LuaFumoVS =
    sgs.CreateViewAsSkill {
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
            local slash = sgs.Sanguosha:cloneCard('slash', cards[1]:getSuit(), cards[1]:getNumber())
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
        return pattern == 'slash' and
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
    end
}

LuaFumo =
    sgs.CreateTriggerSkill {
    name = 'LuaFumo',
    view_as_skill = LuaFumoVS,
    events = {sgs.DamageCaused, sgs.TargetConfirmed, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                local containsBlack =
                    checkIfSubcardsContainType(
                    damage.card,
                    function(card)
                        return card:isBlack()
                    end
                )
                if containsBlack then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() then
                local containsTrick =
                    checkIfSubcardsContainType(
                    use.card,
                    function(card)
                        return card:isKindOf('TrickCard')
                    end
                )
                local containsEquip =
                    checkIfSubcardsContainType(
                    use.card,
                    function(card)
                        return card:isKindOf('EquipCard')
                    end
                )
                if containsEquip or containsTrick then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                end
                if containsTrick then
                    for _, to in sgs.qlist(use.to) do
                        local i = 2
                        while not to:isNude() and i > 0 do
                            i = i - 1
                            local card_id =
                                room:askForCardChosen(
                                player,
                                to,
                                'he',
                                self:objectName(),
                                false,
                                sgs.Card_MethodDiscard
                            )
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
                        local msg = sgs.LogMessage()
                        msg.type = '#NoJink'
                        msg.from = p
                        room:sendLog(msg)
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
                    local extra =
                        room:askForPlayerChosen(
                        player,
                        available_targets,
                        self:objectName(),
                        '@LuaFumo:::' .. slashCount,
                        true,
                        true
                    )
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
    end
}

LuaFumoTargetMod =
    sgs.CreateTargetModSkill {
    name = 'LuaFumoTargetMod',
    pattern = 'Slash',
    distance_limit_func = function(self, from, card)
        if from:hasSkill('LuaFumo') then
            local containsRed =
                checkIfSubcardsContainType(
                card,
                function(check_card)
                    return check_card:isRed()
                end
            )
            if containsRed then
                return 1000
            end
            return 0
        end
        return 0
    end
}

LuaTaoseCard =
    sgs.CreateSkillCard {
    name = 'LuaTaoseCard',
    will_throw = false,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:obtainCard(target, card)
        if target:getCards('h'):length() > 0 then
            local card_id = room:askForCardChosen(source, target, 'h', 'LuaTaose', false, sgs.Card_MethodNone)
            if card_id then
                room:obtainCard(source, card_id)
            end
        end
        if target:getCards('e'):length() > 0 then
            local card_id = room:askForCardChosen(source, target, 'e', 'LuaTaose', false, sgs.Card_MethodNone)
            if card_id then
                room:obtainCard(source, card_id)
            end
        end
        if target:getCards('j'):length() > 0 then
            local card_id = room:askForCardChosen(source, target, 'j', 'LuaTaose', false, sgs.Card_MethodNone)
            if card_id then
                room:obtainCard(source, card_id)
            end
        end
        if target:getGender() ~= source:getGender() then
            local slash = sgs.Sanguosha:cloneCard('Slash', sgs.Card_NoSuit, 0)
            slash:setSkillName('LuaTaose')
            room:useCard(sgs.CardUseStruct(slash, source, target))
        end
    end
}

LuaTaoseVS =
    sgs.CreateOneCardViewAsSkill {
    name = 'LuaTaose',
    filter_pattern = '.|heart|.|hand',
    view_as = function(self, card)
        local ts = LuaTaoseCard:clone()
        ts:addSubcard(card)
        return ts
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaTaoseCard')
    end
}

LuaTaose =
    sgs.CreateTriggerSkill {
    name = 'LuaTaose',
    view_as_skill = LuaTaoseVS,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') and damage.card:getSkillName() == self:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
    end
}

Linxi:addSkill(LuaTaose)

-- 检查 card 的 subcards 中是否存在符合条件的卡牌
function checkIfSubcardsContainType(card, checkFunc)
    local containsType
    if type(checkFunc) ~= 'function' then
        return nil
    end
    if not card then
        return nil
    end
    for _, subcard in sgs.qlist(card:getSubcards()) do
        if checkFunc(sgs.Sanguosha:getCard(subcard)) then
            containsType = true
            break
        end
    end
    return containsType
end

-- 添加武将技能（除去主公技、觉醒技、限定技）
function getSkillTable(general)
    if not general then
        return {}
    end
    local skill_list = {}
    for _, skill in sgs.qlist(general:getSkillList()) do
        if
            skill:isVisible() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and
                skill:getFrequency() ~= sgs.Skill_Limited
         then
            table.insert(skill_list, skill:objectName())
        end
    end
    return skill_list
end

Skadi:addSkill(LuaChuntian)
Skadi:addSkill(LuaGaochao)
Skadi:addRelateSkill('LuaPenshui')
SkillAnjiang:addSkill(LuaPenshui)
Cactus:addSkill(LuaBaipiao)
SkillAnjiang:addSkill(LuaGeidian)
SkillAnjiang:addSkill(LuaWanneng)
Fuhua:addSkill(LuaGeidian)
Rinsan:addSkill(LuaWanneng)
SkillAnjiang:addSkill(LuaXiaosa)
SkillAnjiang:addSkill(LuaMasochism)
SkillAnjiang:addSkill(LuaZibao)
SkillAnjiang:addSkill(LuaSoutuVS)
Rinsan:addSkill(LuaSoutu)
SPFuhua:addSkill(LuaYangjing)
SkillAnjiang:addSkill(LuaYangjingTargetMod)
SPFuhua:addSkill(LuaTuci)
SPCactus:addSkill(LuaJuesha)
SPCactus:addSkill(LuaMouhai)
SPCactus:addSkill(LuaChuanyi)
Qiumu:addSkill(LuaPaoZhuan)
Qiumu:addSkill(LuaYinyu)
SPRinsan:addSkill(LuaQingyu)
SkillAnjiang:addSkill(LuaQingyuTargetMod)
SPRinsan:addSkill(LuaJiaoxie)
SPRinsan:addSkill(LuaShulian)
SkillAnjiang:addSkill(LuaShulianForbidden)
Anan:addSkill(LuaZhazhi)
Erenlei:addSkill(LuaShaika)
Erenlei:addSkill(LuaChutou)
Yaoyu:addSkill(LuaYingshi)
Yaoyu:addSkill(LuaWangming)
Shayu:addSkill(LuaTianfa)
Shayu:addSkill(LuaZhixie)
Shayu:addSkill(LuaJixie)
Yeniao:addSkill(LuaFumo)
SkillAnjiang:addSkill(LuaFumoTargetMod)

sgs.LoadTranslationTable {
    ['GroupFriendPackage'] = '群友包',
    ['Skadi'] = '蒂蒂',
    ['&Skadi'] = '蒂蒂',
    ['#Skadi'] = '搅动潮汐',
    ['LuaChuntian'] = 'G点',
    [':LuaChuntian'] = '锁定技，你使用一张【桃】，或是失去一点体力/受到一点伤害后，获得一枚“发情”标记',
    ['@Faqing'] = '发情',
    ['LuaGaochao'] = '高潮',
    [':LuaGaochao'] = '觉醒技，当你的“发情”标记数达到了3或更多，你须减一点体力上限，然后获得技能“喷水”',
    ['LuaPenshui'] = '喷水',
    [':LuaPenshui'] = '准备阶段开始时，你可以选择至多X名其他角色，然后失去对应角色数的标记，弃置这些角色的所有装备，然后对其造成1点伤害（X为你的“发情”标记数）',
    ['luapenshui'] = '喷水',
    ['@LuaPenshui'] = '你可以发动“喷水”',
    ['~LuaPenshui'] = '选择若干其他角色→点击确定',
    ['Cactus'] = '仙人掌',
    ['&Cactus'] = '仙人掌',
    ['#Cactus'] = '五溪未成年人',
    ['LuaBaipiao'] = '白嫖',
    [':LuaBaipiao'] = '锁定技，当你不因打出、使用和更换装备的牌进入弃牌堆时，你获得场上角色区域内的一张牌',
    ['LuaBaipiao-invoke'] = '你须选择一名角色白嫖',
    ['Fuhua'] = '浮华',
    ['&Fuhua'] = '浮华',
    ['#Fuhua'] = '憨态',
    ['LuaGeidian'] = '给点',
    [':LuaGeidian'] = '出牌阶段限一次，你可以选择任意名有牌的角色，令这些角色依次交给你一张牌，若你以此法选择的角色数大于2，视为这些角色依次对你使用一张【杀】',
    ['@LuaGeidian-ask'] = '请选择一张牌交给 %src，或点击“取消”给出随机一张牌',
    ['luageidian'] = '给点',
    ['LuaWanneng'] = '万能',
    [':LuaWanneng'] = '<font color = "green"><b>每回合限一次</b></font>，你可以视为使用/打出一张基本牌或非延时锦囊牌，或是视为重铸一张【铁索连环】',
    ['LuaXiaosa'] = '潇洒',
    [':LuaXiaosa'] = '<font color = "green"><b>每轮限一次</b></font>，当你成为其他角色使用的基本牌或非延时锦囊牌的目标时，你可以令此牌无效',
    ['luawanneng'] = '万能',
    ['wanneng_slash'] = '万能',
    ['wanneng_saveself'] = '万能',
    ['LuaMasochism'] = '受虐',
    [':LuaMasochism'] = '锁定技，非濒死状态下，【桃】对你无效',
    ['Rinsan'] = '磷酸',
    ['&Rinsan'] = '磷酸',
    ['#Rinsan'] = '妹抖',
    ['LuaZibao'] = '自爆',
    [':LuaZibao'] = '当你不因此技能造成伤害时，你可以失去一点体力，令伤害+X；当你受到伤害后，你可以失去一点体力，对伤害来源造成X点伤害。（X为你失去的体力值）',
    ['LuaSoutu'] = '搜图',
    [':LuaSoutu'] = '<font color = "green"><b>其他角色的出牌阶段限一次</b></font>，该角色可以交给你一张手牌，然后你观看牌堆顶的3张牌，获得与此牌类型/点数/花色一致的牌，然后将任意牌交给该角色',
    ['LuaSoutuVS'] = '搜图',
    [':LuaSoutuVS'] = '<font color = "green"><b>出牌阶段限一次</b></font>，你可以交给其一张手牌，然后其观看牌堆顶的3张牌，获得与此牌类型/点数/花色一致的牌，然后将任意牌交给你',
    ['luasoutu'] = '搜图送牌',
    ['LuaSoutuGoBack'] = '请交出任意张牌，若不想交出，点击“取消”即可',
    ['SPFuhua'] = 'SP浮华',
    ['&SPFuhua'] = '浮华',
    ['#SPFuhua'] = '憨态Plus',
    ['LuaYangjing'] = '养精',
    [':LuaYangjing'] = '锁定技，出牌阶段结束时，若你未在出牌阶段使用【杀】，你获得一枚“精”标记，你的攻击距离+X（X为“精”标记的数目）；锁定技，你使用【杀】造成的伤害+X（X为“精”标记的数目）；锁定技，你使用【杀】结算完毕后，移除所有“精”标记',
    ['LuaTuci'] = '突刺',
    [':LuaTuci'] = '锁定技，当你使用【杀】指定目标后，若你与其距离小于你的攻击范围，则目标角色不可使用【闪】响应此【杀】\
    ☆攻击范围 = 武器范围（无武器时基础值为1）+ “精”标记数（因为日神杀 API 这样写的，我也没法，只能写死）',
    ['@LuaJing'] = '精',
    ['#LuaYangjingDamageUp'] = '%from 执行“<font color="yellow"><b>养精</b></font>”的效果，%card 的伤害值 + %arg',
    ['#LuaYangjingDamageUpVirtualCard'] = '%from 执行“<font color="yellow"><b>养精</b></font>”的效果，\
    <font color = "yellow"><b>杀[无色]</b></font> 的伤害值 + %arg',
    ['SPCactus'] = 'SP仙人掌',
    ['&SPCactus'] = '仙人掌',
    ['#SPCactus'] = '心狠手辣',
    ['LuaNosJuesha'] = '绝杀',
    [':LuaNosJuesha'] = '当一名角色进入濒死阶段时，你可以令其失去一点体力，每次濒死结算限一次',
    ['LuaJuesha'] = '绝杀',
    [':LuaJuesha'] = '当一名角色进入濒死阶段时，你可以发动此技能，若如此做，在此濒死结算结束前，第一张目标含有该角色的【桃】或【酒】无效',
    ['LuaMouhai'] = '谋害',
    [':LuaMouhai'] = '结束阶段开始时，你可以选择一名体力值不小于你或者体力值为1的角色，对其造成一点伤害',
    ['LuaMouhai-choose'] = '你可以发动“谋害”<br/> <b>操作提示</b>: 选择一名体力值不小于你或体力值为1的角色→点击确定<br/>',
    ['LuaChuanyi'] = '传艺',
    ['luachuanyi'] = '传艺',
    [':LuaChuanyi'] = '准备阶段开始时，你可以选择一名角色，若如此做，你失去一点体力上限，然后选择令该角色获得“谋害”或“绝杀”，同时令该角色不再是“传艺”的合法目标；出牌阶段，你可以失去此技能',
    ['LuaChuanyi-choose'] = '你可以发动“传艺”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>',
    ['Qiumu'] = '秋目',
    ['&Qiumu'] = '秋目',
    ['#Qiumu'] = '秋目',
    ['LuaPaozhuan'] = '抛砖',
    [':LuaPaozhuan'] = '当其他角色从你这里获得牌至其手牌或装备区时，你可对其造成一点伤害',
    ['LuaYinyu'] = '引玉',
    [':LuaYinyu'] = '一名角色的出牌阶段开始时，你可以展示一张手牌并令该角色获得之，若如此做，该角色在出牌阶段使用与此牌类型一致的牌时，你可令其摸一张牌',
    ['@LuaYinyu-show'] = '你可以展示一张手牌发动“引玉”',
    ['SPRinsan'] = 'SP磷酸',
    ['&SPRinsan'] = 'SP磷酸',
    ['#SPRinsan'] = '工口上手',
    ['LuaQingyu'] = '情欲',
    [':LuaQingyu'] = '锁定技，若你的手牌数：不小于体力值，你使用牌无距离次数限制且每造成1点伤害可以摸一张牌；不大于体力值的一半，你不能使用【闪】响应以你为目标的【杀】',
    ['LuaJiaoxie'] = '缴械',
    [':LuaJiaoxie'] = '当你受到有来源的伤害后，若伤害来源没有被“缴械”，你可以将其所有装备移出游戏，然后废除其装备区。若同时伤害来源正处于出牌阶段，在所有结算结束后你结束该出牌阶段。当伤害来源的下一个回合开始时，其恢复装备区，然后将移出的牌置入装备区',
    ['LuaShulian'] = '熟练',
    [':LuaShulian'] = '锁定技，你不是延时类锦囊的合法目标；锁定技，你的非锁定技不会失效',
    ['LuaShulian-choose'] = '你可以选择一名角色，废除他的判定区',
    ['LuaShulian-forbid'] = '熟练教导',
    ['LuaShulianForbidden'] = '熟练',
    ['Anan'] = '暗暗',
    ['&Anan'] = '暗暗',
    ['#Anan'] = '榨汁姬',
    ['LuaZhazhi'] = '榨汁',
    [':LuaZhazhi'] = '一名其他角色的出牌阶段开始时，若你在其攻击范围内，你可以令其对你使用一张不计入使用次数限制的杀（无距离限制），若该杀未对你造成伤害，你摸一张牌并回复一点体力；否则该角色造成的伤害-1直到回合结束',
    ['#LuaZhazhi'] = '%from 的“<font color="yellow"><b>榨汁</b></font>”生效，伤害值由 %arg2 减为 %arg',
    ['@LuaZhazhi-slash'] = '%src 对你发动“榨汁”，请对其使用一张【杀】，否则你本回合造成伤害-1',
    ['Erenlei'] = '饿人类',
    ['&Erenlei'] = '饿人类',
    ['#Erenlei'] = '哔哔机',
    ['LuaShaika'] = '晒卡',
    ['luashaika'] = '晒卡',
    [':LuaShaika'] = '锁定技，当一张牌进入弃牌堆后，本回合内与此牌同名的卡牌不能以此法弃置\
    出牌阶段，你可以弃置至少一张牌且其中包含锦囊牌，然后你指定一名其他角色，该角色选择以下一项执行：\
    1.弃置X+1张牌（X为你以此法弃置的牌数）\
    2.受到你造成的一点伤害\
    若如此做，该角色本回合内不再是你发动此技能的合法目标',
    ['@LuaShaika'] = '%src 对你发动了“晒卡”，你需要弃置 %arg 张牌，或者点击“取消”受到一点伤害',
    ['LuaChutou'] = '出头',
    [':LuaChutou'] = '锁定技，当你的牌不因此技能而弃置时，你摸一张牌。当你摸牌后手牌数为全场唯一最多时，你弃置一张牌',
    ['Yaoyu'] = '西行寺妖羽',
    ['&Yaoyu'] = '妖羽',
    ['#Yaoyu'] = '孤星',
    ['LuaYingshi'] = '影噬',
    [':LuaYingshi'] = '其他角色阵亡时，你可以选择获得其任意个技能（限定技、觉醒技、主公技除外）',
    ['LuaWangming'] = '亡命',
    [':LuaWangming'] = '锁定技，当其他角色因你造成的伤害而进入濒死状态时，其直接死亡',
    ['Shayu'] = '纱羽',
    ['&Shayu'] = '纱羽',
    ['#Shayu'] = '机屑人',
    ['LuaTianfa'] = '天罚',
    [':LuaTianfa'] = '锁定技，每名角色的回合结束后，你从牌堆中随机展示一张牌并将其置入弃牌堆。若这张牌为黑桃2～9，则该角色受到3点无伤害来源的雷属性伤害。当你死亡时，你令一名其他角色获得该技能',
    ['@LuaTianfa-choose'] = '请选择一名其他角色获得“天罚”',
    ['LuaZhixie'] = '智屑',
    ['luazhixie'] = '智屑',
    [':LuaZhixie'] = '你可以将锦囊牌当成铁索连环使用或重铸；结束阶段，你可以横置至多X名角色（X为你出牌阶段发动智屑的次数）',
    ['@LuaZhixie'] = '你可以发动“智屑”，横置至多 %arg 名角色',
    ['~LuaZhixie'] = '选择若干名角色→点击确定',
    ['LuaJixie'] = '机械',
    [':LuaJixie'] = '锁定技，当你受到雷属性伤害时，你摸一张牌，然后本次伤害-1',
    ['Yeniao'] = '夜鸟',
    ['&Yeniao'] = '夜鸟',
    ['#Yeniao'] = '魅魔酱',
    ['LuaFumo'] = '附魔',
    [':LuaFumo'] = '你可以将至少两张牌当作【杀】使用。若你使用的牌中包含有：\
    1. 杀，则你可以额外选择X个目标（X为【杀】的数量）\
    2. 有红色牌，则该杀无距离限制\
    3. 有黑色牌，该杀伤害+1\
    4. 有锦囊牌，你弃置目标2张牌\
    5. 有装备牌，该【杀】无法使用【闪】响应',
    ['@LuaFumo'] = '你可以发动“附魔”选择额外的目标，还可以选择至多 %arg 名角色',
    ['Linxi'] = '文爻林夕',
    ['&Linxi'] = '林夕',
    ['#Linxi'] = '待定',
    ['LuaTaose'] = '桃色',
    [':LuaTaose'] = '出牌阶段限一次，你可以将一张红桃牌交给一名其他角色，然后获得该角色每个区域各一张牌。若该角色为异性，则视为你对其使用一张【杀】，且此【杀】造成的伤害+1',
    ['luataose'] = '桃色'
}
