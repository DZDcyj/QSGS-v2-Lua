-- 日神杀公用 Lua 函数封装模块
-- Created by DZDcyj at 2021/9/23
module('QSanguoshaLuaFunction', package.seeall)

-- 封装好的函数部分

-- 忽略本文件中未引用 global variable 的警告
-- luacheck: push ignore 131

-- 蛊惑类技能通用 enabled_at_play
function guhuoVSSkillEnabledAtPlay(self, player)
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
    return true
end

-- 蛊惑类技能通用 enabled_at_response
function guhuoVSSkillEnabledAtResponse(self, player, pattern)
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
    if string.find(pattern, '[%u%d]') then
        return false
    end -- 这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
    return true
end

-- 蛊惑类（万能卡牌转换）filter
-- 参数：
-- self 对应的技能卡对象
-- custom_name 对应自定义 tag 的名称
function guhuoCardFilter(self, targets, to_select, custom_name)
    -- 解决【无中生有】选多人问题
    if selfTargetFixed(self) then
        return false
    end
    local players = sgs.PlayerList()
    for i = 1, #targets do
        players:append(targets[i])
    end
    if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
        local card
        if self:getUserString() and self:getUserString() ~= '' then
            card = sgs.Sanguosha:cloneCard(self:getUserString():split('+')[1])
            if sgs.Self:isProhibited(to_select, card, players) then
                return false
            end
            return card and card:targetFilter(players, to_select, sgs.Self)
        end
    elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
        return false
    end
    local _card = sgs.Self:getTag(custom_name):toCard()
    if _card == nil or sgs.Self:isProhibited(to_select, _card, players) then
        return false
    end
    local card = sgs.Sanguosha:cloneCard(_card)
    card:deleteLater()
    return card and card:targetFilter(players, to_select, sgs.Self)
end

-- 通用 on_validate 方法
-- 参数
-- skill_name，技能卡名，用于转换后的卡牌
-- 以下参数为空时默认设置为 skill_name
-- choice_name，用于选择，即选择对应的杀类型提示框
-- tag_name，自定义名称，用于 tag
function guhuoCardOnValidate(self, card_use, skill_name, choice_name, tag_name)
    choice_name = choice_name or skill_name
    tag_name = tag_name or skill_name
    local source = card_use.from
    local room = source:getRoom()
    local to_use = self:getUserString()
    if to_use == 'slash' and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
        local use_list = {}
        table.insert(use_list, 'slash')
        if not isPackageBanned('maneuvering') then
            table.insert(use_list, 'normal_slash')
            table.insert(use_list, 'thunder_slash')
            table.insert(use_list, 'fire_slash')
        end
        to_use = room:askForChoice(source, choice_name .. '_slash', table.concat(use_list, '+'))
        source:setTag(tag_name, sgs.QVariant(to_use))
    end
    local user_str = to_use
    local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, 0)
    if use_card == nil then
        return nil
    end
    use_card:setSkillName(skill_name)
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
end

-- 通用 on_validate_in_response 方法
function guhuoCardOnValidateInResponse(self, source, skill_name, choice_name, tag_name)
    choice_name = choice_name or skill_name
    tag_name = tag_name or skill_name
    local room = source:getRoom()
    local to_use
    if self:getUserString() == 'peach+analeptic' then
        local use_list = {}
        table.insert(use_list, 'peach')
        if not isPackageBanned('maneuvering') then
            table.insert(use_list, 'analeptic')
        end
        to_use = room:askForChoice(source, choice_name .. '_saveself', table.concat(use_list, '+'))
        source:setTag(tag_name .. 'SaveSelf', sgs.QVariant(to_use))
    elseif self:getUserString() == 'slash' then
        local use_list = {}
        table.insert(use_list, 'slash')
        if not isPackageBanned('maneuvering') then
            table.insert(use_list, 'normal_slash')
            table.insert(use_list, 'thunder_slash')
            table.insert(use_list, 'fire_slash')
        end
        to_use = room:askForChoice(source, choice_name .. '_slash', table.concat(use_list, '+'))
        source:setTag(tag_name .. 'Slash', sgs.QVariant(to_use))
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
    use_card:setSkillName(skill_name)
    use_card:addSubcards(self:getSubcards())
    use_card:deleteLater()
    return use_card
end

function selfFeasible(self, targets, skill_name)
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
    local _card = sgs.Self:getTag(skill_name):toCard()
    if _card == nil then
        return false
    end
    local card = sgs.Sanguosha:cloneCard(_card)
    card:deleteLater()
    return card and card:targetsFeasible(players, sgs.Self)
end

-- 蛊惑类型技能卡 targetFixed 自实现，避免多人无中生有等问题
function selfTargetFixed(self)
    local card
    local aocaistring = self:getUserString()
    if aocaistring ~= '' then
        local uses = aocaistring:split('+')
        card = sgs.Sanguosha:cloneCard(uses[1], sgs.Card_NoSuit, -1)
    end
    card:addSubcard(self:getSubcards():first())
    return card and card:targetFixed()
end

-- 桃色获取卡牌
function doTaoseGetCard(skill_name, room, source, flags, target)
    if target:getCards(flags):length() > 0 then
        local card_id = room:askForCardChosen(source, target, flags, skill_name, false, sgs.Card_MethodNone)
        room:obtainCard(source, card_id, false)
    end
end

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

-- 添加武将技能
-- general 为对应的武将卡
-- skillChecker 为技能判断的方法，返回值为布尔类型
function getSkillTable(general, skillChecker)
    if not general then
        return {}
    end
    local skill_list = {}
    for _, skill in sgs.qlist(general:getSkillList()) do
        if skillChecker(skill) then
            table.insert(skill_list, skill:objectName())
        end
    end
    return skill_list
end

-- 显示发动技能文本并播放语音
function skill(self, room, player, open, n)
    local log = sgs.LogMessage()
    log.type = '#InvokeSkill'
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

-- 权计摸牌放牌
function doQuanji(skillName, player, room, times)
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

-- 获取可扶汉的武将 Table
-- 暂时没有排除已获得所有技能的武将
function getFuhanShuGenerals(general_num)
    local general_names = sgs.Sanguosha:getLimitedGeneralNames()
    local shu_generals = {}
    for _, name in ipairs(general_names) do
        local general = sgs.Sanguosha:getGeneral(name)
        if general:getKingdom() == 'shu' then
            if not table.contains(shu_generals, name) then
                table.insert(shu_generals, name)
            end
        end
    end
    local available_generals = {}
    local i = 0
    while i < general_num do
        i = i + 1
        local index = random(1, #shu_generals)
        local selected = shu_generals[index]
        table.insert(available_generals, selected)
        table.removeOne(shu_generals, shu_generals[index])
    end
    return available_generals
end

-- 激词收回大点数牌
function getBackPindianCardByJici(room, pindian, isFrom)
    local player
    if isFrom then
        player = pindian.from
    else
        player = pindian.to
    end
    if pindian.from_number > pindian.to_number then
        if room:getCardPlace(pindian.from_card:getEffectiveId()) ~= sgs.Player_PlaceHand then
            player:obtainCard(pindian.from_card)
        end
    elseif pindian.from_number < pindian.to_number then
        if room:getCardPlace(pindian.to_card:getEffectiveId()) ~= sgs.Player_PlaceHand then
            player:obtainCard(pindian.to_card)
        end
    else
        if room:getCardPlace(pindian.from_card:getEffectiveId()) ~= sgs.Player_PlaceHand then
            player:obtainCard(pindian.from_card)
        end
        if room:getCardPlace(pindian.to_card:getEffectiveId()) ~= sgs.Player_PlaceHand then
            player:obtainCard(pindian.to_card)
        end
    end
end

-- 封装好的 RIGHT 函数，判断技能能否发动的默认条件
function RIGHT(self, player, skillName)
    if not skillName then
        skillName = self:objectName()
    end
    return player and player:isAlive() and player:hasSkill(skillName)
end

-- 封装好的 RIGHTATPHASE 函数，在 RIGHT 基础上判断是否在对应的阶段
function RIGHTATPHASE(self, player, phase, skillName)
    return RIGHT(self, player, skillName) and player:getPhase() == phase
end

-- 封装好的 RIGHTNOTATPHASE 函数，在 RIGHT 函数基础上判断是否不处于对应阶段
function RIGHTNOTATPHASE(self, player, phase, skillName)
    return RIGHT(self, player, skillName) and player:getPhase() ~= phase
end

-- 讨灭用，from 从 card_source 区域中获得一张牌，然后选择一名除 card_source 之外的角色获得
function obtainOneCardAndGiveToOtherPlayer(self, room, from, card_source)
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

-- 造成伤害
-- room 当前 room
-- from 来源角色
-- to 目标角色
-- damage_value 伤害点数
-- nature 伤害类型，默认为无属性
function doDamage(room, from, to, damage_value, nature, card)
    local theDamage = sgs.DamageStruct()
    theDamage.from = from
    theDamage.to = to
    theDamage.damage = damage_value
    if not nature then
        nature = sgs.DamageStruct_Normal
    end
    theDamage.nature = nature
    theDamage.card = card
    room:damage(theDamage)
end

-- 获取对应装备栏的卡牌类型
function getEquipTypeStr(equip_index)
    local map = {
        [0] = 'Weapon',
        [1] = 'Armor',
        [2] = 'DefensiveHorse',
        [3] = 'OffensiveHorse',
        [4] = 'Treasure',
    }
    return map[equip_index]
end

-- 获取势力数
function getKingdomCount(room)
    local kingdoms = {}
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if not table.contains(kingdoms, p:getKingdom()) then
            table.insert(kingdoms, p:getKingdom())
        end
    end
    return #kingdoms
end

-- 将首字母换成大写
function firstToUpper(str)
    return str:gsub('^%l', string.upper)
end

-- 首字母小写
function firstToLower(str)
    return str:gsub('^%u', string.lower)
end

-- 将下划线换成大写
-- 例如 abc_def -> abcDef
function replaceUnderline(str)
    if string.find(str, '%p%l+') then
        local first = string.sub(str, string.find(str, '%l+'))
        local last = string.sub(str, string.find(str, '%p%l+'))
        last = firstToUpper(string.sub(last, 2))
        return first .. last
    end
    return str
end

-- 从弃牌堆获取指定类型的一张牌
function getCardFromDiscardPile(room, type)
    for _, id in sgs.qlist(room:getDiscardPile()) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isKindOf(type) then
            return card
        end
    end
    return nil
end

-- 巧思封装函数
function LuaDoQiaosiShow(room, player, dummyCard)
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
            local card1 = obtainTargetedTypeCard(room, params)
            expected_length = expected_length + 2
            if card1 then
                table.insert(about_to_obtain, card1:getId())
                dummyCard:addSubcard(card1)
                local card2 = obtainTargetedTypeCard(room, params)
                if card2 then
                    table.insert(about_to_obtain, card2:getId())
                    dummyCard:addSubcard(card2)
                end
            end
        else
            -- 不确定的，要抽奖
            local currType = random(1, 5)
            expected_length = expected_length + 1
            local type = cardTypes[currType]
            if string.find(type, 'JinkOrPeach') then
                type = LuaGetRoleCardType('scholarKing', true, true)
            elseif string.find(type, 'SlashOrAnaleptic') then
                type = LuaGetRoleCardType('merchantGeneral', true, true)
            end
            params['type'] = type
            local card = obtainTargetedTypeCard(room, params)
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

-- 巧思获得牌
function LuaQiaosiGetCards(room, roleType)
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

-- 巧思获得牌的类型判断
function LuaGetRoleCardType(roleType, kingActivated, generalActivated)
    local map = {
        ['king'] = {'TrickCard', 'TrickCard'},
        ['general'] = {'EquipCard', 'EquipCard'},
        ['artisan'] = {'Slash', 'Slash', 'Slash', 'Slash', 'Analeptic'},
        ['farmer'] = {'Jink', 'Jink', 'Jink', 'Jink', 'Peach'},
        ['scholar'] = {'TrickCard', 'TrickCard', 'TrickCard', 'TrickCard', 'JinkOrPeach'},
        ['scholarKing'] = {'Peach', 'Peach', 'Peach', 'Peach', 'Jink'},
        ['merchant'] = {'EquipCard', 'EquipCard', 'EquipCard', 'EquipCard', 'SlashOrAnaleptic'},
        ['merchantGeneral'] = {'Analeptic', 'Analeptic', 'Analeptic', 'Analeptic', 'Slash'},
    }
    if roleType == 'scholar' and kingActivated then
        roleType = roleType .. 'King'
    end
    if roleType == 'merchant' and generalActivated then
        roleType = roleType .. 'General'
    end
    return map[roleType]
end

-- 勤政技能获得牌
function LuaQinzhengGetCard(room, markNum, modNum, cardType1, cardType2)
    local mod = math.fmod(markNum, modNum)
    if mod == 0 then
        local type = random(1, 2)
        local card
        local params = {
            ['existed'] = {},
            ['findDiscardPile'] = true,
        }
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

-- 判断是否可以移动场上卡牌
function canMoveCard(room)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if (p:getJudgingArea():length() > 0 or p:hasEquip()) then
            return true
        end
    end
    return false
end

-- 判断是否可以从 from 移动装备区/判定区卡牌到 to
function canMoveCardFromPlayer(from, to)
    -- 如果 from 没有可以移动的卡牌，则不行
    if from:getCards('ej'):isEmpty() then
        return false
    end
    -- 判定区
    if to:hasJudgeArea() then
        local judgeCards = {}
        for _, jcd in sgs.qlist(to:getJudgingArea()) do
            table.insert(judgeCards, jcd:objectName())
        end
        for _, jcd in sgs.qlist(from:getJudgingArea()) do
            if not table.contains(judgeCards, jcd:objectName()) then
                return true
            end
        end
    end
    -- 装备区
    for i = 0, 4, 1 do
        if from:getEquip(i) and not to:getEquip(i) then
            -- 判断要移动到的角色是否有对应的装备栏
            if to:hasEquipArea(i) then
                return true
            end
        end
    end
    return false
end

-- 询问 controller 从 from 移动牌到 to 的区域里
function askForMoveCards(controller, from, to, skillName)
    local room = from:getRoom()
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
    local card_id = room:askForCardChosen(controller, from, 'ej', skillName, false, sgs.Card_MethodNone, disabled_ids)
    local card = sgs.Sanguosha:getCard(card_id)
    local place = room:getCardPlace(card_id)
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, from:objectName(), skillName, '')
    room:moveCardTo(card, from, to, place, reason)

end

-- 获得牌堆中指定类型的牌
-- params 代表参数，类型 Table
-- type 具体要获得的类型，可以使用 isKindOf 进行判断，为 String
-- existed 代表要避开的已有牌，为 Table 类型
-- findDiscardPile 代表是否在弃牌堆寻找，为布尔类型
function obtainTargetedTypeCard(room, params)
    local type = params['type']
    if type == nil then
        return nil
    end
    local existedIds = params['existed']
    if existedIds == nil then
        existedIds = {}
    end
    local findDiscardPile = params['findDiscardPile']
    local card
    local checker = function(cd)
        return cd:isKindOf(type) and not table.contains(existedIds, cd:getId())
    end
    card = obtainCardFromPile(checker, room:getDrawPile())
    if not card and findDiscardPile then
        card = obtainCardFromPile(checker, room:getDiscardPile())
    end
    return card
end

-- 从卡牌 id 列表获得卡牌列表
function getCardList(intlist)
    local ids = sgs.CardList()
    for _, id in sgs.qlist(intlist) do
        ids:append(sgs.Sanguosha:getCard(id))
    end
    return ids
end

-- 发送消息
-- type 为字符串型，必需
-- params 为对应的参数，Table 类型
function sendLogMessage(room, type, params)
    local msg = sgs.LogMessage()
    msg.type = type
    local from = params['from']
    if from then
        msg.from = from
    end
    local to = params['to']
    local tos = params['tos']
    assert(to == nil or tos == nil)
    if to then
        msg.to:append(to)
    end
    if tos then
        for _, p in sgs.qlist(tos) do
            msg.to:append(p)
        end
    end
    local arg = params['arg']
    if arg then
        msg.arg = arg
    end
    local arg2 = params['arg2']
    if arg2 then
        msg.arg2 = arg2
    end
    local card_str = params['card_str']
    if card_str then
        msg.card_str = card_str
    end
    room:sendLog(msg)
end

-- 获取可获得的技能列表
-- skills 代表候选技能
-- 返回 skills 除去 player 已有技能的 Table
function getGainableSkillTable(player, skills)
    local gainableSkillTable = {}
    for _, skill in ipairs(skills) do
        if not player:hasSkill(skill) then
            table.insert(gainableSkillTable, skill)
        end
    end
    return gainableSkillTable
end

-- 从牌堆获取特定的牌
-- cardChecker 卡牌判断函数
-- findDiscardPile 是否在弃牌堆寻找
function obtainSpecifiedCard(room, cardChecker, findDiscardPile)
    local card
    card = obtainCardFromPile(cardChecker, room:getDrawPile())
    if not card and findDiscardPile then
        card = obtainCardFromPile(cardChecker, room:getDiscardPile())
    end
    return card
end

-- 从指定牌堆中获取对应卡牌
function obtainCardFromPile(checker, pile)
    local availableCards = {}
    for _, id in sgs.qlist(pile) do
        local card = sgs.Sanguosha:getCard(id)
        if checker(card) then
            table.insert(availableCards, card)
        end
    end
    -- 随机化，避免一直拿牌堆顶层牌
    if #availableCards > 0 then
        return availableCards[random(1, #availableCards)]
    end
    return nil
end

-- 判断卡牌移动时 reason 的基本类型是否匹配
function moveBasicReasonCompare(source, dest)
    return bit32.band(source, sgs.CardMoveReason_S_MASK_BASIC_REASON) == dest
end

-- 创建 JudgeStruct
-- params 参数 Table
function createJudgeStruct(params)
    local judge = sgs.JudgeStruct()

    judge.who = params['who']

    if params['good'] ~= nil then
        judge.good = params['good']
    else
        judge.good = true
    end

    if params['pattern'] then
        judge.pattern = params['pattern']
    else
        judge.pattern = '.'
    end

    if params['reason'] then
        judge.reason = params['reason']
    else
        judge.reason = ''
    end

    if params['play_animation'] ~= nil then
        judge.play_animation = params['play_animation']
    else
        judge.play_animation = false
    end

    return judge
end

-- 将移出游戏的卡牌放回原位时机判断
function cardGoBack(event, player, data, skill)
    if event == sgs.EventPhaseStart then
        return player:getPhase() == sgs.Player_Finish
    elseif event == sgs.Death then
        return data:toDeath().who:hasSkill(skill)
    end
    return false
end

-- sgs.AskforPindianCard 时机卡牌获取
function obtainIdFromAskForPindianCardEvent(room, target)
    local from_id = -1
    local random_from_id = random(1, 10000)
    local from_data = sgs.QVariant()
    from_data:setValue(random_from_id)
    room:setTag('pindian' .. random_from_id, sgs.QVariant(-1))
    -- 根据天辩的相关 Lua 逻辑，data 会传递一个 id，然后将对应摸牌的 id 放入 room 对应的 Tag
    room:getThread():trigger(sgs.AskforPindianCard, room, target, from_data)
    -- 使用负数作为初始值，以判断是否有类似天辩的情况出现
    if room:getTag('pindian' .. random_from_id):toInt() ~= -1 then
        from_id = room:getTag('pindian' .. random_from_id):toInt()
    end
    return from_id
end

-- 判断是否失去牌
-- move 卡牌移动结构体
-- source 判断是否为该角色失去牌
function lostCard(move, source)
    local fromSource = move.from and (move.from:objectName() == source:objectName()) and
                           (move.from_places:contains(sgs.Player_PlaceHand) or
                               move.from_places:contains(sgs.Player_PlaceEquip))
    local toSource = move.to and (move.to:objectName() == source:objectName() and
                         (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))
    return fromSource and not toSource
end

-- 判断是否红牌
function isRedCard(card)
    return card:isRed()
end

-- 判断是否黑牌
function isBlackCard(card)
    return card:isBlack()
end

-- 获取武将初始血量
function getStartHp(player)
    -- 目前缺少详细 API，暂时只能写死，之后根据具体情形要更新这部分
    local general_hp_map = {
        ['shenganning'] = 3,
        ['ExShenpei'] = 2,
        ['ExLijue'] = 4,
        ['SPCactus'] = 3,
        ['ExShenSunce'] = 1,
        ['ExMouHuaxiong'] = 3,
    }
    return general_hp_map[player:getGeneralName()] or player:getGeneral():getMaxHp()
end

-- 手气卡
function askForLuckCard(room)
    local players = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if not p:getAI() then
            players:append(p)
        end
    end

    if players:isEmpty() then
        return
    end
    local time = 0
    local times = sgs.GetConfig('LuckCardLimitation', 0)
    while time < times do
        local used = sgs.SPlayerList()
        for _, player in sgs.qlist(players) do
            if not player:hasFlag('RefusedToUseLuckCard') then
                if room:askForSkillInvoke(player, 'luck_card', sgs.QVariant('LuaLuckCard')) then
                    used:append(player)
                else
                    room:setPlayerFlag(player, 'RefusedToUseLuckCard')
                end
            end
        end
        if used:isEmpty() then
            return
        end

        for _, player in sgs.qlist(used) do
            sendLogMessage(room, '#UseLuckCard', {
                ['from'] = player,
            })
        end

        local drawList = sgs.IntList()
        local drawPile = room:getDrawPile()
        for _, player in sgs.qlist(used) do
            drawList:append(player:getHandcardNum())
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), 'luck_card', '')
            local moves = sgs.CardsMoveList()
            local move = sgs.CardsMoveStruct(player:handCards(), player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
                reason)
            moves:append(move)
            local tmpList = sgs.SPlayerList()
            tmpList:append(player)
            room:notifyMoveCards(true, moves, false, tmpList)

            for _, id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                player:removeCard(card, sgs.Player_PlaceHand)
                drawPile:prepend(id)
                room:setCardMapping(id, nil, sgs.Player_DrawPile)
            end

            room:notifyMoveCards(false, moves, false, tmpList)
            room:returnToTopDrawPile(player:handCards())
        end
        shuffleDrawPile(room)
        local index = -1
        for _, player in sgs.qlist(used) do
            index = index + 1
            local ids = room:getNCards(drawList:at(index), false)
            local moves = sgs.CardsMoveList()
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(), 'luck_card', '')
            local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand, reason)
            moves:append(move)
            room:notifyMoveCards(true, moves, false)
            for _, id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                player:addCard(card, sgs.Player_PlaceHand)
                drawPile:removeOne(id)
                room:setCardMapping(id, player, sgs.Player_PlaceHand)
            end
            room:notifyMoveCards(false, moves, false)
        end
        time = time + 1
    end
    room:doBroadcastNotify(sgs.CommandType['S_COMMAND_UPDATE_PILE'], tostring(room:getDrawPile():length()))
end

-- 斗地主模式武将选择
function landlordsGeneralChoose(room)
    local all = sgs.Sanguosha:getRandomGenerals(sgs.Sanguosha:getGeneralCount())
    local players = room:getPlayers()
    shuffleTable(all)
    for _, sp in sgs.qlist(players) do
        local available = {}
        for _ = 0, 4, 1 do
            local choice = findReasonable(all)
            table.insert(available, choice)
            table.removeOne(all, choice)
        end
        local general = room:askForGeneral(sp, table.concat(available, '+'))
        table.insertTable(all, available)
        table.removeOne(all, general)
        sp:setTag('LandlordsGeneral', sgs.QVariant(general))
        shuffleTable(all)
    end
    for _, p in sgs.qlist(players) do
        local generalName = p:getTag('LandlordsGeneral'):toString()
        local general = sgs.Sanguosha:getGeneral(generalName)
        local toChange
        if general:getKingdom() == 'god' then
            toChange = room:askForKingdom(p)
        elseif generalName == 'ExWenyang' then
            toChange = room:askForChoice(p, 'LuaWenyangKingdomChoose', 'wei+wu')
            room:addPlayerMark(p, 'LuaWenyangKingdomChoose')
        end
        if toChange then
            p:setTag('KingdomChosen', sgs.QVariant(toChange))
        end
    end
    for _, p in sgs.qlist(players) do
        local general = p:getTag('LandlordsGeneral'):toString()
        if general then
            room:changeHero(p, general, false, false, false, false)
            if p:getTag('KingdomChosen') then
                local kingdom = p:getTag('KingdomChosen'):toString()
                room:setPlayerProperty(p, 'kingdom', sgs.QVariant(kingdom))
            end
        end
    end
end

-- 打乱 table
function shuffleTable(table)
    local len = #table
    for i = 0, len - 1, 1 do
        local j = random(i, len - 1)
        table[i], table[j] = table[j], table[i]
    end
end

function findReasonable(generals, no_unreasonable)
    for _, name in ipairs(generals) do
        local banList = sgs.GetConfig('Banlist/Roles', ''):split(',')
        if not table.contains(banList, name) then
            return name
        end
    end
    if no_unreasonable then
        return ''
    end
    return generals[0]
end

-- 使用 Fisher-Yates 洗牌算法打乱牌堆
function shuffleDrawPile(room)
    local drawPile = room:getDrawPile()
    local len = drawPile:length()
    for i = 0, len - 1, 1 do
        local j = random(i, len - 1)
        drawPile:swap(i, j)
    end
end

-- 种子偏移量
local seed_offset = 0

-- 随机数
-- 返回[min, max]随机值
function random(min, max)
    seed_offset = seed_offset + 1
    if min ~= nil and max ~= nil then
        -- 使用种子偏移量和当前时间的方式保证随机数种子不同
        local seed = os.time() + seed_offset
        math.randomseed(seed)

        -- 由于某些原因，初始的几个随机数一致的，先 pop 出来
        math.random()
        math.random()
        math.random()

        -- 无参数调用产生[0, 1)之间的浮点数
        local rand = math.random()

        -- 修正参数，使得范围值达到 [0, max - min + 1)
        rand = rand * (max - min + 1)

        -- 修正参数到范围 [min, max + 1)
        rand = rand + min

        -- 向下取整，使得最后的结果为 [min, max] 范围内整数
        return math.floor(rand)
    end
    error('Invalid Input')
end

-- 获取随机未拥有技能
-- banned_skills 为随机技能禁表
-- banned_skills_for_lord 为 BOSS 技能禁表
-- is_lord 参数代表是否为 BOSS
-- 因主公为 boss，故直接判断主公即可
function getRandomGeneralSkill(room, banned_skills, banned_skills_for_lord, is_lord)
    local general_names = sgs.Sanguosha:getLimitedGeneralNames()
    local available_skills = {}
    repeat
        local random_general = general_names[random(1, #general_names)]
        local general = sgs.Sanguosha:getGeneral(random_general)
        for _, skill in sgs.qlist(general:getVisibleSkillList()) do
            local have
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(skill:objectName()) then
                    have = true
                    break
                end
            end
            if (not have) and (not table.contains(banned_skills, skill:objectName())) then
                if not is_lord or (is_lord and (not table.contains(banned_skills_for_lord, skill:objectName()))) then
                    table.insert(available_skills, skill:objectName())
                end
            end
        end
    until #available_skills > 0
    return available_skills[random(1, #available_skills)]
end

-- 修改技能描述
function modifySkillDescription(translation, new_translation)
    sgs.Sanguosha:addTranslationEntry(translation,
        '' .. string.gsub(sgs.Sanguosha:translate(translation), sgs.Sanguosha:translate(translation),
            sgs.Sanguosha:translate(new_translation)))
end

-- 获取随机武将
function getRandomGeneral(banned_generals)
    local general_names = sgs.Sanguosha:getLimitedGeneralNames()
    local random_general
    repeat
        random_general = general_names[random(1, #general_names)]
    until not table.contains(banned_generals, random_general)
    return random_general
end

-- 判断是否处于暴走状态
function isBaozou(player)
    return player:getMark('LuaBaozou') > 0
end

-- 判断是否可以使用 BOSS 技能
function bossSkillEnabled(player, skill_name, mark_name)
    return player:getMark(mark_name) > 0 or player:hasSkill(skill_name)
end

-- 获取内伐不可使用手牌数
function getNeifaUnavailableCardCount(player)
    return math.min(getUnavailableHandcardCount(player), 5)
end

-- 获取烈弓花色数
function getLiegongSuitNum(player)
    local count = 0
    if player:getMark('@LuaLiegongClub') > 0 then
        count = count + 1
    end
    if player:getMark('@LuaLiegongDiamond') > 0 then
        count = count + 1
    end
    if player:getMark('@LuaLiegongHeart') > 0 then
        count = count + 1
    end
    if player:getMark('@LuaLiegongSpade') > 0 then
        count = count + 1
    end

    return count
end

-- 烈弓用，判断是否记录该牌花色
function cardCanBeRecorded(card)
    return card and (not card:isKindOf('SkillCard')) and cardSuitCanBeRecorded(card)
end

-- 替代简单的判断 NoSuit，因存在无花色红、黑等
function cardSuitCanBeRecorded(card)
    return card:getSuit() == sgs.Card_Spade or card:getSuit() == sgs.Card_Club or card:getSuit() == sgs.Card_Heart or
               card:getSuit() == sgs.Card_Diamond
end

-- 烈弓用，获取花色标记名称
function getLiegongSuitMarkName(card)
    return '@LuaLiegong' .. firstToUpper(card:getSuitString())
end

-- 清除 player 所有包含有 content 内容的 mark
function clearAllMarksContains(room, player, content)
    for _, mark in sgs.list(player:getMarkNames()) do
        if string.find(mark, content) and player:getMark(mark) > 0 then
            room:setPlayerMark(player, mark, 0)
        end
    end
end

-- 统一的 canDiscard 接口，处理奇才问题
function canDiscard(from, to, flags)
    if string.find(flags, 'h') and not to:isKongcheng() then
        return true
    end
    if string.find(flags, 'j') and not to:getJudgingArea():isEmpty() then
        return true
    end
    if string.find(flags, 'e') then
        if to:getOffensiveHorse() or to:getDefensiveHorse() then
            return true
        end
        if to:getWeapon() or to:getArmor() or to:getTreasure() then
            if from:objectName() == to:objectName() or (not to:hasSkill('qicai')) then
                return true
            end
        end
    end
    return false
end

-- from 是否可以弃置 to 的某一张牌
function canDiscardCard(from, to, card_id)
    if not to then
        return false
    end
    if to:hasSkill('qicai') and from:objectName() ~= to:objectName() then
        if (to:getWeapon() and card_id == to:getWeapon():getEffectiveId()) or
            (to:getArmor() and card_id == to:getArmor():getEffectiveId()) or
            (to:getTreasure() and card_id == to:getTreasure():getEffectiveId()) then
            return false
        end
    elseif from:objectName() == to:objectName() then
        if (not from:getJudgingAreaID():contains(card_id) and from:isJilei(sgs.Sanguosha:getCard(card_id))) then
            return false
        end
    end
    return true
end

-- 封装函数【节命】OL
-- 返回值代表是否成功发动【节命】
function doJiemingDrawDiscard(skillName, player, room)
    local alives = room:getAlivePlayers()
    if alives:isEmpty() then
        return false
    end
    local target = room:askForPlayerChosen(player, alives, skillName, 'jieming-invoke', true, true)
    if target then
        room:broadcastSkillInvoke(skillName)
        local x = math.min(5, target:getMaxHp())
        target:drawCards(x, skillName)
        local diff = target:getHandcardNum() - x
        if diff > 0 then
            room:askForDiscard(target, skillName, diff, diff)
        end
    end
    return target ~= nil
end

-- 增加角色体力上限
-- player 要增加的角色
-- value 增加值
function addPlayerMaxHp(player, value)
    local room = player:getRoom()
    local newValue = sgs.QVariant(player:getMaxHp() + value)
    room:setPlayerProperty(player, 'maxhp', newValue)
    sendLogMessage(room, '#addmaxhp', {
        ['from'] = player,
        ['arg'] = value,
    })
end

-- 是否存在可以发动【佐幸】的神郭嘉
function availableShenGuojiaExists(player)
    return (player:getGeneralName() == 'ExShenGuojia' or player:getGeneral2Name() == 'ExShenGuojia') and
               player:getMaxHp() > 1
end

-- 是否可以在对应阶段觉醒
-- player 对应的角色
-- wakeSkillMark 对应的判断标记
-- eventPhase 对应的阶段，可以为单个时机或多个时机的table
function canWakeAtPhase(player, wakeSkillMark, eventPhase)
    if player:getMark(wakeSkillMark) ~= 0 then
        return false
    end
    if type(eventPhase) == 'number' then
        return player:getPhase() == eventPhase
    elseif type(eventPhase) == 'table' then
        return table.contains(eventPhase, player:getPhase())
    end
    return false
end

-- 体力回复函数封装
-- target 要回复体力的角色
-- value 要回复的体力值，默认为1
-- source 体力回复来源，默认为 nil
-- card 体力回复来源卡牌，默认为 nil
function recover(room, target, value, source, card)
    value = value or 1
    room:recover(target, sgs.RecoverStruct(source, card, value))
end

-- 封装 filter 函数判断，选取对应数量的其他角色
-- selected 已选择角色
-- to_select 将要选取角色
-- compareType 判断类型，由下面的参数列表决定
-- compareValue 对应的判断值
function checkFilter(selected, to_select, compareType, compareValue)
    if to_select:objectName() == sgs.Self:objectName() then
        return false
    end
    compareValue = compareValue or 0
    if compareType < EQUAL then
        return (#selected < compareValue) or (#selected == compareValue and compareType == LESS_OR_EQUAL)
    elseif compareType > EQUAL then
        return (#selected > compareValue) or (#selected == compareValue and compareType == GREATER_OR_EQUAL)
    end
    return compareValue == #selected
end

-- 封装方法，用于添加 to 到 from 的攻击范围
function addToAttackRange(room, from, to)
    room:insertAttackRangePair(from, to)
end

-- 封装方法，用于将 to 从 from 的攻击范围中移除（用于解除上一方法的问题）
function removeFromAttackRange(room, from, to)
    room:removeAttackRangePair(from, to)
end

-- 获取不可使用卡牌数
function getUnavailableHandcardCount(player)
    local count = 0
    for _, cd in sgs.qlist(player:getHandcards()) do
        if not cd:isAvailable(player) then
            count = count + 1
        end
    end
    return count
end

-- 获取对应卡牌极限值
function getMaxCardMostProbably(cardType)
    if cardType == BASIC_CARD then
        return 4
    elseif cardType == TRICK_CARD then
        return 6
    end
    return 8
end

-- 获取对应卡牌修正系数
function getCorrectionFactor(cardType, turnCount)
    -- 回合数增加越多，越保留重要的牌概率越大，比如酒闪桃无懈
    if cardType == BASIC_CARD then
        return 1 + turnCount * 0.1
    elseif cardType == TRICK_CARD then
        return 0.5 + turnCount * 0.1
    end
    return 0.3 + turnCount * 0.1
end

-- 概率计算
-- unknownCardNum 未知牌数
-- typeCardRemain 现存对应类型牌数
-- totalRemain 剩余所有牌数
-- cardType 对应卡牌类型
-- 经过的回合数
function calculateProbably(unknownCardNum, typeCardRemain, totalRemain, cardType, turnCount)
    -- 考虑到概率是小于等于1的，所以如果我们拥有的牌数越多，不可能拥有该类型牌的概率就会下降
    -- 在这里我们取一个极限值，认为如果超过了对应数量，就拥有
    if unknownCardNum >= getMaxCardMostProbably(cardType) then
        return 1
    end
    local probably = 1 - math.pow(typeCardRemain, unknownCardNum) / math.pow(totalRemain, unknownCardNum)
    -- 取两位小数
    return math.min((probably - probably % 0.01) * getCorrectionFactor(cardType, turnCount), 1)
end

-- 初始化三种牌数量
function cardNumInitialize(room, source)
    local totalBasic, totalTrick, totalEquip = 0, 0, 0
    for _, cid in sgs.qlist(room:getDrawPile()) do
        local cd = sgs.Sanguosha:getCard(cid)
        if cd:isKindOf('BasicCard') then
            totalBasic = totalBasic + 1
        elseif cd:isKindOf('TrickCard') then
            totalTrick = totalTrick + 1
        elseif cd:isKindOf('EquipCard') then
            totalEquip = totalEquip + 1
        end
    end
    for _, cid in sgs.qlist(room:getDiscardPile()) do
        local cd = sgs.Sanguosha:getCard(cid)
        if cd:isKindOf('BasicCard') then
            totalBasic = totalBasic + 1
        elseif cd:isKindOf('TrickCard') then
            totalTrick = totalTrick + 1
        elseif cd:isKindOf('EquipCard') then
            totalEquip = totalEquip + 1
        end
    end
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        for _, cd in sgs.qlist(p:getCards('hej')) do
            if cd:isKindOf('BasicCard') then
                totalBasic = totalBasic + 1
            elseif cd:isKindOf('TrickCard') then
                totalTrick = totalTrick + 1
            elseif cd:isKindOf('EquipCard') then
                totalEquip = totalEquip + 1
            end
        end
        for _, pile in sgs.list(p:getPileNames()) do
            for _, cid in sgs.qlist(p:getPile(pile)) do
                local cd = sgs.Sanguosha:getCard(cid)
                if cd:hasFlag('visible') or cd:hasFlag(string.format('%s_%s_%s', source:objectName(), p:objectName())) then
                    if cd:isKindOf('BasicCard') then
                        totalBasic = totalBasic + 1
                    elseif cd:isKindOf('TrickCard') then
                        totalTrick = totalTrick + 1
                    elseif cd:isKindOf('EquipCard') then
                        totalEquip = totalEquip + 1
                    end
                end
            end
        end
    end
    room:setTag('LuaLingrenAIBasic', sgs.QVariant(totalBasic))
    room:setTag('LuaLingrenAITrick', sgs.QVariant(totalTrick))
    room:setTag('LuaLingrenAIEquip', sgs.QVariant(totalEquip))
end

-- 曹婴【凌人】 AI 初始化
-- 返回值为一个带有对应牌数的 IntList，顺序为基本、锦囊、装备、未知、剩余基本、剩余锦囊、剩余装备
function lingrenAIInitialize(source, target)
    local basic, trick, equip
    basic = getKnownCard(target, source, 'BasicCard')
    trick = getKnownCard(target, source, 'TrickCard')
    equip = getKnownCard(target, source, 'EquipCard')
    local unknown = target:getHandcardNum() - basic - trick - equip
    -- 特殊处理未知一张牌，全选没有
    if unknown == 1 and target:getHandcardNum() == 1 then
        basic, trick, equip, unknown = 0, 0, 0, 0
    end
    local result = sgs.IntList()
    result:append(basic)
    result:append(trick)
    result:append(equip)
    result:append(unknown)
    unknownAnalyze(result, source, target, source:getRoom())
    result:append(target:getMark('Global_TurnCount'))
    return result
end

function unknownAnalyze(resultList, source, target, room)
    local totalBasic = room:getTag('LuaLingrenAIBasic')
    local totalTrick = room:getTag('LuaLingrenAITrick')
    local totalEquip = room:getTag('LuaLingrenAIEquip')
    while (not totalBasic) or (not totalTrick) or (not totalEquip) do
        cardNumInitialize(room, source)
        totalBasic = room:getTag('LuaLingrenAIBasic')
        totalTrick = room:getTag('LuaLingrenAITrick')
        totalEquip = room:getTag('LuaLingrenAIEquip')
    end
    local basicRemain = totalBasic:toInt()
    local trickRemain = totalTrick:toInt()
    local equipRemain = totalEquip:toInt()
    for _, cid in sgs.qlist(room:getDiscardPile()) do
        local cd = sgs.Sanguosha:getCard(cid)
        if cd:isKindOf('BasicCard') then
            basicRemain = basicRemain - 1
        elseif cd:isKindOf('TrickCard') then
            trickRemain = trickRemain - 1
        elseif cd:isKindOf('EquipCard') then
            equipRemain = equipRemain - 1
        end
    end
    for _, p in sgs.qlist(room:getOtherPlayers(target)) do
        local basic, trick, equip
        basic = getKnownCard(p, source, 'BasicCard')
        trick = getKnownCard(p, source, 'TrickCard')
        equip = getKnownCard(p, source, 'EquipCard')
        for _, pile in sgs.list(p:getPileNames()) do
            for _, cid in sgs.qlist(p:getPile(pile)) do
                local cd = sgs.Sanguosha:getCard(cid)
                if cd:hasFlag('visible') or cd:hasFlag(string.format('%s_%s_%s', source:objectName(), p:objectName())) then
                    if cd:isKindOf('BasicCard') then
                        basicRemain = basicRemain - 1
                    elseif cd:isKindOf('TrickCard') then
                        trickRemain = trickRemain - 1
                    elseif cd:isKindOf('EquipCard') then
                        equipRemain = equipRemain - 1
                    end
                end
            end
        end
        basicRemain = basicRemain - basic
        trickRemain = trickRemain - trick
        equipRemain = equipRemain - equip
    end

    resultList:append(basicRemain)
    resultList:append(trickRemain)
    resultList:append(equipRemain)
end

function playerCanInvokeLingce(player, card)
    -- 判断是否为固定可以发动的【无中生有】【过河拆桥】【无懈可击】【奇正相生】
    local fixed_types = {'ExNihilo', 'Dismantlement', 'Nullification', 'IndirectCombination'}
    for _, type in ipairs(fixed_types) do
        if card:isKindOf(type) then
            return true
        end
    end
    local dinghan_cards = player:getTag('LuaDinghanCards'):toString():split('|')
    for _, type in ipairs(dinghan_cards) do
        if card:objectName() == type then
            return true
        end
    end
    return false
end

-- 封装方法用于获取定汉记录牌名 table
function getDinghanCardsTable(player)
    local dinghan_str = player:getTag('LuaDinghanCards') and player:getTag('LuaDinghanCards'):toString() or ''
    return dinghan_str:split('|')
end

-- 封装方法用于设置定汉记录牌名
function setDinghanCardsTable(player, dinghan_cards)
    player:setTag('LuaDinghanCards', sgs.QVariant(table.concat(dinghan_cards, '|')))
end

-- 封装方法用于添加青钢标记
function addQinggangTag(victim, card)
    -- 日神杀使用迫真 QStringList 来存储青钢标记牌名
    -- 因此需要先判断是否已经存在，如果存在就不要再加
    -- 在【杀】结束之后，将会自动清除青钢标记
    local qinggang = victim:getTag('Qinggang'):toStringList()
    -- 迫真 type 是 table
    if qinggang and table.contains(qinggang, card:toString()) then
        return
    end
    victim:addQinggangTag(card)
end

function Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

-- 封装方法用于轮回标记
function moveLuaPoweiMark(room, currentPlayer)
    room:sendCompulsoryTriggerLog(currentPlayer, 'LuaPowei')
    local froms = sgs.SPlayerList()
    local maxIndex = room:alivePlayerCount() - 1
    local targetMap = {}
    -- 首先确定要动的来源
    for i = 1, maxIndex do
        local curr = currentPlayer:getNextAlive(i)
        if curr:getMark('@LuaPowei') > 0 then
            froms:append(curr)
        end
    end
    -- 确认移动到的目标
    for _, from in sgs.qlist(froms) do
        for i = 1, maxIndex do
            local curr = from:getNextAlive(i)
            if not curr:hasSkill('LuaPowei') then
                targetMap[from:objectName()] = i
                goto label
            end
        end
        ::label::
    end
    for _, from in sgs.qlist(froms) do
        local toIndex = targetMap[from:objectName()]
        if not toIndex then
            return
        end
        local to = from:getNextAlive(toIndex)
        room:removePlayerMark(from, '@LuaPowei')
        room:addPlayerMark(to, '@LuaPowei')
    end
end

-- 死亡负面技能风险
function hasDeathSkillRisk(source, target)
    local room = target:getRoom()
    if target:hasSkill('wuhun') then
        local wuhunDeathRisk = true
        local sourceMarkCount = source:getMark('@nightmare')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:getMark('@nightmare') > sourceMarkCount then
                wuhunDeathRisk = false
                break
            end
        end
        if wuhunDeathRisk then
            return true
        end
    end
    -- 挥泪、断肠、毒士
    return target:hasSkills('huilei|duanchang|dushi')
end

-- 判断对应包是否被禁用
function isPackageBanned(packageName)
    -- 必须每次判断，如果写成全局，只会在打开程序时加载一次
    -- 采用 extra.lua 的 Set 写法
    local bannedPackages = {}
    for _, pkg in ipairs(sgs.Sanguosha:getBanPackages()) do
        bannedPackages[pkg] = true
    end
    return bannedPackages[packageName]
end

-- 获取护盾值
function getShieldCount(player)
    return player:getMark(SHIELD_MARK)
end

-- 是否可以增加护甲
function canIncreaseShield(player)
    return getShieldCount(player) < MAX_SHIELD_COUNT
end

-- 获得护甲
function increaseShield(player, count)
    local curr = getShieldCount(player)
    local toGain = math.min(count, MAX_SHIELD_COUNT - curr)
    if toGain <= 0 then
        return
    end
    local room = player:getRoom()
    room:addPlayerMark(player, SHIELD_MARK, toGain)
    sendLogMessage(room, '#GainShield', {
        ['from'] = player,
        ['arg'] = toGain,
    })
end

-- 失去护甲
function decreaseShield(player, count)
    local curr = getShieldCount(player)
    local toLose = math.min(curr, count)
    if toLose <= 0 then
        return
    end
    local room = player:getRoom()
    room:removePlayerMark(player, SHIELD_MARK, toLose)
    sendLogMessage(room, '#LoseShield', {
        ['from'] = player,
        ['arg'] = toLose,
    })
end

-- 是否可以发动克己
-- player 角色
-- option 选项，填卡牌名
function canInvokeKeji(player, option)
    -- 不能超过最大
    if getShieldCount(player) >= MAX_SHIELD_COUNT then
        return false
    end
    -- 觉醒了只能选一个
    if player:getMark('LuaMouDujiang') > 0 then
        return (not player:hasUsed('#LuaMouKejiDiscardCard')) and (not player:hasUsed('#LuaMouKejiLoseHpCard'))
    end
    if (not option) then
        return (not player:hasUsed('#LuaMouKejiDiscardCard')) or (not player:hasUsed('#LuaMouKejiLoseHpCard'))
    end
    return not player:hasUsed(string.format('#%s', option))
end

-- 是否可以发动狭援
function canInvokeXiayuan(player)
    return player:hasFlag('ShieldAllLost')
end

-- 护甲标记
SHIELD_MARK = '@shield'

-- 最大上限护甲为 5
MAX_SHIELD_COUNT = 5

-- 获取 table 中 value 的 index
function getPos(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return 0
end

-- 曹金玉系列判断
-- 是否可以发动“隅泣”
function canInvokeYuqi(caojinyu, player)
    if caojinyu:distanceTo(player) > getYuqiAvailableDistance(caojinyu) then
        return false
    end
    return caojinyu:getMark('LuaYuqiInvokeTime') < 2
end

-- 判断距离
function getYuqiAvailableDistance(caojinyu)
    return caojinyu:getMark('LuaYuqiDistance')
end

-- 可以观看的牌数
function getYuqiPreviewCardCount(caojinyu)
    return 3 + caojinyu:getMark('LuaYuqiPreviewCardCount')
end

-- 至多给出的牌
function getYuqiGiveCardCount(caojinyu)
    return 1 + caojinyu:getMark('LuaYuqiGiveCardCount')
end

-- 至多获得的牌
function getYuqiKeepCardCount(caojinyu)
    return 1 + caojinyu:getMark('LuaYuqiKeepCardCount')
end

-- 是否可以增加数字
function canIncreaseNumber(caojinyu)
    if getYuqiAvailableDistance(caojinyu) < 5 then
        return true
    end
    if getYuqiPreviewCardCount(caojinyu) < 5 then
        return true
    end
    if getYuqiGiveCardCount(caojinyu) < 5 then
        return true
    end
    if getYuqiKeepCardCount(caojinyu) < 5 then
        return true
    end
    return false
end

-- 选择增加选项
function askForYuqiIncreaseChoice(caojinyu, value, skill_name)
    local choices = {}
    for index, func in ipairs(YUQI_FUNCS) do
        if func(caojinyu) < 5 then
            table.insert(choices, YUQI_MAP[index])
        end
    end
    if #choices == 0 then
        return
    end
    local room = caojinyu:getRoom()
    local choice = room:askForChoice(caojinyu, skill_name, table.concat(choices, '+'))
    local pos = getPos(YUQI_MAP, choice)
    increaseYuqiNumber(caojinyu, pos, value)
end

-- 增加“隅泣”数字
function increaseYuqiNumber(caojinyu, position, value)
    if position <= 0 or position > 4 then
        return
    end
    local room = caojinyu:getRoom()
    local diff = math.max(0, 5 - YUQI_FUNCS[position](caojinyu))
    if diff <= 0 then
        return
    end
    room:addPlayerMark(caojinyu, YUQI_MAP[position], math.min(diff, value))
end

-- Position 参数，用于隅泣
YUQI_PREVIEW_COUNT = 1
YUQI_GIVE_COUNT = 2
YUQI_KEEP_COUNT = 3
YUQI_DISTANCE = 4

-- 函数映射
YUQI_FUNCS = {getYuqiPreviewCardCount, getYuqiGiveCardCount, getYuqiKeepCardCount, getYuqiAvailableDistance}

-- 映射位置
YUQI_MAP = {'LuaYuqiPreviewCardCount', 'LuaYuqiGiveCardCount', 'LuaYuqiKeepCardCount', 'LuaYuqiDistance'}

-- 孙寒华系列判断

-- 妙剑等级
function getMiaojianLevel(sunhanhua)
    return 1 + sunhanhua:getMark('LuaMiaojianLevelUp')
end

-- 莲华等级
function getLianhuaLevel(sunhanhua)
    return 1 + sunhanhua:getMark('LuaLianhuaLevelUp')
end

-- 更新技能描述
function sunhanhuaUpdateSkillDesc(sunhanhua)
    local miaojianLevel = getMiaojianLevel(sunhanhua)
    if miaojianLevel > 1 then
        modifySkillDescription(':LuaMiaojian', string.format(':LuaMiaojian%d', miaojianLevel))
    end
    local lianhuaLevel = getLianhuaLevel(sunhanhua)
    if lianhuaLevel > 1 then
        modifySkillDescription(':LuaLianhua', string.format(':LuaLianhua%d', lianhuaLevel))
    end
    -- 刷新一下，免得技能修正后显示不出来
    ChangeCheck(sunhanhua, sunhanhua:getGeneralName())
end

-- 清正选牌
function filterMouQingzhengCards(source, selected, to_select)
    -- 需要的花色数
    local requiredSuitCount = 3 - source:getMark('@LuaZhishi')
    -- 判断已选择卡牌是否满足花色数
    local suits = {}
    for _, cd in ipairs(selected) do
        local suit = cd:getSuitString()
        if not table.contains(suits, suit) then
            table.insert(suits, suit)
        end
    end

    -- 是否是装备牌、能否弃置
    if to_select:isEquipped() or source:isJilei(to_select) then
        return false
    end

    -- 要么是已选中花色，要么是不够花色
    return table.contains(suits, to_select:getSuitString()) or #suits < requiredSuitCount
end

-- 判断清正合法性
function checkMouQingzhengCards(source, cards)
    -- 需要的花色数
    local requiredSuitCount = 3 - source:getMark('@LuaZhishi')

    -- 判断已选择卡牌是否满足花色数
    local suits = {}
    for _, cd in ipairs(cards) do
        local suit = cd:getSuitString()
        if not table.contains(suits, suit) then
            table.insert(suits, suit)
        end
    end
    if #suits < requiredSuitCount then
        return false
    end

    local ids = {}
    for _, cd in ipairs(cards) do
        table.insert(ids, cd:getEffectiveId())
    end

    -- 判断所有手牌是否已被选中
    for _, cd in sgs.qlist(source:getHandcards()) do
        local suit = cd:getSuitString()
        if table.contains(suits, suit) and not table.contains(ids, cd:getEffectiveId()) then
            return false
        end
    end

    return true
end

-- 避免一堆 if-else
local suitStringFuncs = {
    [sgs.Card_Spade] = function()
        return 'spade'
    end,
    [sgs.Card_Club] = function()
        return 'club'
    end,
    [sgs.Card_Heart] = function()
        return 'heart'
    end,
    [sgs.Card_Diamond] = function()
        return 'diamond'
    end,
    [sgs.Card_NoSuitBlack] = function()
        return 'no_suit_black'
    end,
    [sgs.Card_NoSuitRed] = function()
        return 'no_suit_red'
    end,
}

-- 花色转字符串
function Suit2String(suit)
    local f = suitStringFuncs[suit]
    if f then
        return f()
    end
    return 'no_suit'
end

-- 判断字符串是否以给定前缀开头
function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

-- 获取秉清标记数
function getBingQingMarkCount(player)
    local suits = {sgs.Card_Diamond, sgs.Card_Spade, sgs.Card_Heart, sgs.Card_Club}
    local count = 0
    for _, suit in ipairs(suits) do
        local mark = string.format('@%s%s_biu', 'LuaBingqing', Suit2String(suit))
        if player:getMark(mark) > 0 then
            count = count + 1
        end
    end
    return count
end

local SHENCAI_KEYWORDS = {'体力', '武器', '打出', '距离'}
local SHENCAI_MARKS = {'@LuaShencai-Chi', '@LuaShencai-Zhang', '@LuaShencai-Tu', '@LuaShencai-Liu'}

-- 清除神张飞标记
function clearShencaiMark(player)
    local room = player:getRoom()
    room:setPlayerMark(player, '@LuaShencai-Chi', 0)
    room:setPlayerMark(player, '@LuaShencai-Zhang', 0)
    room:setPlayerMark(player, '@LuaShencai-Tu', 0)
    room:setPlayerMark(player, '@LuaShencai-Liu', 0)
end

-- 中文字符匹配
function chineseStrFind(str, pattern)
    local startIndex, endIndex = string.find(str, pattern, 1, true)
    return startIndex and endIndex
end

-- 根据牌面给玩家上 debuff
function shencaiEffect(source, victim, desc)
    local room = victim:getRoom()
    local markCount = 0
    for i = 1, 4, 1 do
        if chineseStrFind(desc, SHENCAI_KEYWORDS[i]) then
            victim:gainMark(SHENCAI_MARKS[i])
            markCount = markCount + 1
        end
    end
    if markCount == 0 then
        victim:gainMark('@LuaShencai-Death')
        if not victim:isAllNude() then
            local card_id = room:askForCardChosen(source, victim, 'hej', 'LuaShencai', false, sgs.Card_MethodNone)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
            room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
        end
    end
end

-- 将【奇正相生】加入到初始卡牌
function initIndirectCombination(room)
    local drawPile = room:getDrawPile()
    local ids = {}
    for i = 0, 10000 do
        local card = sgs.Sanguosha:getEngineCard(i)
        if card == nil then
            break
        end
        if (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and (card:isKindOf('IndirectCombination')) then
            if card:getPackage() ~= 'jiaozhao' then
                -- 排除【矫诏】包的无色卡牌
                table.insert(ids, card:getId())
            end
        end
    end
    for _, id in ipairs(ids) do
        drawPile:append(id)
        room:setCardMapping(id, nil, sgs.Player_DrawPile)
    end
    shuffleDrawPile(room)
    sendLogMessage(room, '$LuaTianzuo', {
        ['card_str'] = table.concat(ids, '+'),
    })
    room:doBroadcastNotify(sgs.CommandType['S_COMMAND_UPDATE_PILE'], tostring(drawPile:length()))
end

-- 将马钧装备包移出游戏
function removeMajunEquipsFromPile(room)
    -- 被 Ban 了就不用操作
    if isPackageBanned('MajunEquipCardPackage') then
        return
    end
    local drawPile = room:getDrawPile()
    local ids = {}
    for _, id in sgs.qlist(drawPile) do
        local cd = sgs.Sanguosha:getCard(id)
        if isMajunEquip(cd) then
            table.insert(ids, id)
        end
    end
    for _, id in ipairs(ids) do
        drawPile:removeOne(id)
        room:setCardMapping(id, nil, sgs.Player_PlaceUnknown)
    end
    room:doBroadcastNotify(sgs.CommandType['S_COMMAND_UPDATE_PILE'], tostring(drawPile:length()))
end

-- 升级装备对应
local MAJUN_EQUIPS = {
    ['yuanrong_crossbow'] = 'crossbow',
    ['xiantian_eightdiagram'] = 'eight_diagram',
    ['jingang_renwang_shield'] = 'renwang_shield',
    ['zhaoyue_silver_lion'] = 'silver_lion',
    ['tongyou_vine'] = 'vine',
}

-- 原始装备对应升级
local EQUIP_UPGRADE = {
    ['crossbow'] = 'yuanrong_crossbow',
    ['eight_diagram'] = 'xiantian_eightdiagram',
    ['renwang_shield'] = 'jingang_renwang_shield',
    ['silver_lion'] = 'zhaoyue_silver_lion',
    ['vine'] = 'tongyou_vine',
}

-- 是否是马钧装备
function isMajunEquip(card)
    return MAJUN_EQUIPS[card:objectName()] ~= nil
end

-- 是否可以升级
function canBeUpgrade(card)
    return EQUIP_UPGRADE[card:objectName()] ~= nil
end

-- 获取升级卡牌
function majunUpgradeCard(card, player)
    local room = player:getRoom()
    local newEquipName = EQUIP_UPGRADE[card:objectName()]
    if not newEquipName then
        return
    end
    local newEquip
    for i = 0, 10000 do
        local cd = sgs.Sanguosha:getEngineCard(i)
        if cd == nil then
            break
        end
        if cd:objectName() == newEquipName and cd:getSuit() == card:getSuit() then
            newEquip = cd
            break
        end
    end
    if not newEquip then
        return
    end
    -- 移除旧装备
    local ids = sgs.IntList()
    ids:append(card:getEffectiveId())
    local place = room:getCardPlace(card:getEffectiveId())
    moveOutCardFromGame(ids, player, place)
    -- 获取新装备
    local newIds = sgs.IntList()
    newIds:append(newEquip:getEffectiveId())
    obtainCard(newIds, player)
end

-- 将卡牌移出游戏
function moveOutCardFromGame(card_ids, mover, place)
    local room = mover:getRoom()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, mover:objectName(), 'moveout', '')
    local moves = sgs.CardsMoveList()
    local move = sgs.CardsMoveStruct(card_ids, mover, nil, place, sgs.Player_DrawPile, reason)
    moves:append(move)
    room:notifyMoveCards(true, moves, false)
    for _, id in sgs.qlist(move.card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        mover:removeCard(card, place)
        room:setCardMapping(id, nil, sgs.Player_PlaceUnknown)
    end
    room:notifyMoveCards(false, moves, false)
    room:doBroadcastNotify(sgs.CommandType['S_COMMAND_UPDATE_PILE'], tostring(room:getDrawPile():length()))
end

-- 获取卡牌
function obtainCard(ids, player)
    local room = player:getRoom()
    local moves = sgs.CardsMoveList()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(), 'obtain', '')
    local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand, reason)
    moves:append(move)
    room:notifyMoveCards(true, moves, true)
    for _, id in sgs.qlist(move.card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        player:addCard(card, sgs.Player_PlaceHand)
        room:setCardMapping(id, player, sgs.Player_PlaceHand)
    end
    room:notifyMoveCards(false, moves, true)
end

-- 判断是否是智囊牌
function isZhinangCard(card)
    if card:isKindOf('ExNihilo') then
        return true
    end
    if card:isKindOf('Dismantlement') then
        return true
    end
    if card:isKindOf('Nullification') then
        return true
    end
    return false
end

-- 常规 on_use
function defaultOnUse(card, room, source, targets)
    local nullified_list = room:getTag('CardUseNullifiedList'):toStringList()
    local all_nullified = table.contains(nullified_list, '_ALL_TARGETS')
    for _, target in ipairs(targets) do
        local effect = sgs.CardEffectStruct()
        effect.card = card
        effect.from = source
        effect.to = target
        effect.multiple = #targets > 1
        effect.nullified = (all_nullified or table.contains(nullified_list, target:objectName()))

        room:cardEffect(effect)
    end

    local ids = sgs.IntList()
    if card:isVirtualCard() then
        ids = card:getSubcards()
    else
        ids:append(card:getId())
    end
    local moves = sgs.CardsMoveList()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), '', card:getSkillName(), '')
    if #targets == 1 then
        reason.m_targetId = targets:first():objectName()
    end
    local data = sgs.QVariant()
    data:setValue(card)
    reason.m_extraData = data
    for _, id in sgs.qlist(ids) do
        if room:getCardPlace(id) == sgs.Player_PlaceTable then
            local move = sgs.CardsMoveStruct(id, source, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, reason)
            moves:append(move)
        end
    end
    if not moves:isEmpty() then
        room:moveCardsAtomic(moves, true)
    end
end

-- CardType 参数，用于 getCardMostProbably 方法
BASIC_CARD = 1
TRICK_CARD = 2
EQUIP_CARD = 3

-- Compare 参数，用于 checkFilter 方法
LESS = 0
LESS_OR_EQUAL = 1
EQUAL = 2
GREATER_OR_EQUAL = 3
GREATER = 4

-- Animate 参数，用于 doAnimate 方法
ANIMATE_NULL = 0 -- 空
ANIMATE_INDICATE = 1 -- 指示线
ANIMATE_LIGHTBOX = 2 -- 与 LightBox 有关
ANIMATE_NULLIFICATION = 3 -- 无懈可击石狮子
ANIMATE_HUASHEN = 4 -- 化身用，表现为一张武将牌从牌堆移动到武将上
ANIMATE_FIRE = 5 -- 火焰效果
ANIMATE_LIGHTING = 6 -- 闪电效果

-- 初始化所有锦囊牌类型
ALL_TRICKS = {}
for i = 0, 10000 do
    local card = sgs.Sanguosha:getEngineCard(i)
    if card == nil then
        break
    end
    if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and (card:isKindOf('TrickCard')) and
        not table.contains(ALL_TRICKS, card:objectName()) then
        table.insert(ALL_TRICKS, card:objectName())
    end
end

-- luacheck: pop
