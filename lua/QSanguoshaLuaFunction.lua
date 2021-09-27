-- 日神杀公用 Lua 函数封装模块
-- Created by DZDcyj at 2021/9/23

module('QSanguoshaLuaFunction', package.seeall)

-- 封装好的函数部分

-- 忽略本文件中未引用 global variable 的警告
-- luacheck: push ignore 131

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
function doQuanji(self, player, room)
    if player:askForSkillInvoke(self:objectName()) then
        room:drawCards(player, 1, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        if not player:isKongcheng() then
            local card_id
            if player:getHandcardNum() == 1 then
                card_id = player:handCards():first()
                room:getThread():delay()
            else
                card_id =
                    room:askForExchange(player, self:objectName(), 1, 1, false, 'QuanjiPush'):getSubcards():first()
            end
            player:addToPile('power', card_id)
        end
    end
end

-- 获取可扶汉的武将 Table
-- 暂时没有排除已获得所有技能的武将
function getFuhanShuGenerals(room, general_num)
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
        local index = math.random(1, #shu_generals)
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
function RIGHT(self, player)
    return player and player:isAlive() and player:hasSkill(self:objectName())
end

-- 讨灭用，from 从 card_source 区域中获得一张牌，然后选择一名除 card_source 之外的角色获得
function obtainOneCardAndGiveToOtherPlayer(self, room, from, card_source)
    local card_id = room:askForCardChosen(from, card_source, 'hej', self:objectName())
    from:obtainCard(sgs.Sanguosha:getCard(card_id), false)
    local togive =
        room:askForPlayerChosen(
        from,
        room:getOtherPlayers(card_source),
        self:objectName(),
        '@LuaTaomie-give:' .. card_source:objectName(),
        true,
        true
    )
    if togive then
        local reason =
            sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_GIVE,
            from:objectName(),
            togive:objectName(),
            self:objectName(),
            nil
        )
        room:moveCardTo(sgs.Sanguosha:getCard(card_id), from, togive, sgs.Player_PlaceHand, reason, false)
    end
end

-- 造成伤害
-- room 当前 room
-- from 来源角色
-- to 目标角色
-- damage_value 伤害点数
-- nature 伤害类型，默认为无属性
function doDamage(room, from, to, damage_value, nature)
    local theDamage = sgs.DamageStruct()
    theDamage.from = from
    theDamage.to = to
    theDamage.damage = damage_value
    if not nature then
        nature = sgs.DamageStruct_Normal
    end
    theDamage.nature = nature
    room:damage(theDamage)
end

-- 获取对应装备栏的卡牌类型
function getEquipTypeStr(equip_index)
    local map = {
        [0] = 'Weapon',
        [1] = 'Armor',
        [2] = 'DefensiveHorse',
        [3] = 'OffensiveHorse',
        [4] = 'Treasure'
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
    return (str:gsub('^%l', string.upper))
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
    local choices = {
        'king',
        'merchant',
        'artisan',
        'farmer',
        'scholar',
        'general',
        'cancel'
    }
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
                if card2 then
                    dummyCard:addSubcard(card2)
                end
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
            if card then
                dummyCard:addSubcard(card)
            end
        end
    end
    player:obtainCard(dummyCard)
    return dummyCard:subcardsLength()
end

-- 巧思获得牌
function LuaQiaosiGetCards(room, roleType) --
    --[[ 
        王、商、工、农、士、将
        King、Merchant、Artisan、Farmer、Scholar、General
        roleType 代表转的人类型，为 Table 类型
        例如{"king", "artisan", "general"}
    ]] local results = {}
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
        ['scholar'] = {
            'TrickCard',
            'TrickCard',
            'TrickCard',
            'TrickCard',
            'JinkOrPeach'
        },
        ['scholarKing'] = {'Peach', 'Peach', 'Peach', 'Peach', 'Jink'},
        ['merchant'] = {
            'EquipCard',
            'EquipCard',
            'EquipCard',
            'EquipCard',
            'SlashOrAnaleptic'
        },
        ['merchantGeneral'] = {
            'Analeptic',
            'Analeptic',
            'Analeptic',
            'Analeptic',
            'Slash'
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

-- 勤政技能获得牌
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

-- 判断是否可以移动场上卡牌
function CanMoveCard(room)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if (p:getJudgingArea():length() > 0 or p:hasEquip()) then
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
    if type == nil then
        return nil
    end
    local existedNames = params['existed']
    if existedNames == nil then
        existedNames = {}
    end
    local findDiscardPile = params['findDiscardPile']
    for _, id in sgs.qlist(room:getDrawPile()) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isKindOf(type) and not table.contains(existedNames, card:objectName()) then
            return card
        end
    end
    if findDiscardPile then
        for _, id in sgs.qlist(room:getDiscardPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf(type) and not table.contains(existedNames, card:objectName()) then
                return card
            end
        end
    end
    return nil
end

-- 从卡牌 id 列表获得卡牌列表
function getCardList(intlist)
    local ids = sgs.CardList()
    for _, id in sgs.qlist(intlist) do
        ids:append(sgs.Sanguosha:getCard(id))
    end
    return ids
end

-- luacheck: pop
