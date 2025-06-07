-- 扩展卡牌包
-- Created by DZDcyj at 2022/12/29
module('extensions.ExpansionCardPackage', package.seeall)
extension = sgs.Package('ExpansionCardPackage', sgs.Package_CardPack)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local skillList = sgs.SkillList()

-- 奇正相生
indirect_combination = sgs.CreateTrickCard {
    name = 'indirect_combination',
    class_name = 'IndirectCombination',
    subtype = 'single_target_trick',
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    -- 无需覆写 on_use，否则会造成一系列结算问题
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local data = sgs.QVariant()
        data:setValue(effect)
        -- 正兵或奇兵
        local choice = room:askForChoice(source, self:objectName(), 'Direct+Indirect', data)
        local choice2 = room:askForChoice(target, self:objectName() .. '_defense', 'ResponseSlash+ResponseJink', data)
        local pattern = rinsan.firstToLower(string.gsub(choice2, 'Response', ''))
        local prompt = string.format('indirect_combination-card:%s::%s', source:objectName(), pattern)
        local card = room:askForCard(target, pattern, prompt, sgs.QVariant(), sgs.Card_MethodResponse)
        rinsan.sendLogMessage(room, '#choose', {
            ['from'] = source,
            ['arg'] = choice,
        })
        if choice == 'Direct' then
            -- 正兵
            if (not card) or (not card:isKindOf('Jink')) then
                if target:isNude() then
                    return
                end
                rinsan.sendLogMessage(room, '#DirectFailed', {
                    ['from'] = source,
                    ['to'] = target,
                    ['arg'] = 'jink',
                })
                local card_id = room:askForCardChosen(source, target, 'he', self:objectName(), false, sgs.Card_MethodNone)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
                room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
            end
        elseif choice == 'Indirect' then
            -- 奇兵
            if (not card) or (not card:isKindOf('Slash')) then
                rinsan.sendLogMessage(room, '#IndirectFailed', {
                    ['from'] = source,
                    ['to'] = target,
                    ['arg'] = 'slash',
                })
                rinsan.doDamage(source, target, 1, sgs.DamageStruct_Normal, self)
            end
        end
    end,
}

for i = 2, 9, 1 do
    local card = indirect_combination:clone()
    card:setSuit((i % 2 == 0) and sgs.Card_Spade or sgs.Card_Club)
    card:setNumber(i)
    card:setParent(extension)
end

-- 调剂盐梅
adjust_salt_plum = sgs.CreateTrickCard {
    name = 'adjust_salt_plum',
    class_name = 'AdjustSaltPlum',
    target_fixed = false,
    can_recast = true,
    is_cancelable = true,
    filter = function(self, selected, to_select)
        local total_num = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, self)
        local handcardNums = {}
        for _, p in ipairs(selected) do
            local curr = p:getHandcardNum()
            if p:objectName() == sgs.Self:objectName() then
                curr = curr - 1
            end
            table.insert(handcardNums, curr)
        end
        local to_select_handcards_num = to_select:getHandcardNum()
        if to_select:objectName() == sgs.Self:objectName() then
            to_select_handcards_num = to_select_handcards_num - 1
        end
        if table.contains(handcardNums, to_select_handcards_num) then
            return false
        end
        return #selected < total_num and (not sgs.Self:isCardLimited(self, sgs.Card_MethodUse))
    end,
    feasible = function(self, targets)
        local rec = sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        local sub = sgs.IntList()
        if self:isVirtualCard() then
            sub = self:getSubcards()
        else
            sub:append(self:getEffectiveId())
        end
        for _, id in sgs.qlist(sub) do
            if sgs.Self:getHandPile():contains(id) then
                rec = false
                break
            end
        end
        if rec and sgs.Self:isCardLimited(self, sgs.Card_MethodUse) then
            return #targets == 0
        end
        if rec then
            return #targets > 1 or #targets == 0
        end
        return #targets > 1
    end,
    about_to_use = function(self, room, card_use)
        -- Recast
        if card_use.to:isEmpty() then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, card_use.from:objectName())
            reason.m_skillName = self:getSkillName()
            local ids = sgs.IntList()
            if self:isVirtualCard() then
                ids = self:getSubcards()
            else
                ids:append(self:getEffectiveId())
            end
            local moves = sgs.CardsMoveList()
            for _, id in sgs.qlist(ids) do
                local move = sgs.CardsMoveStruct(id, nil, sgs.Player_DiscardPile, reason)
                moves:append(move)
            end
            room:moveCardsAtomic(moves, true)
            card_use.from:broadcastSkillInvoke('@recast')
            rinsan.sendLogMessage(room, '#UseCard_Recast', {
                ['from'] = card_use.from,
                ['card_str'] = card_use.card:toString(),
            })
            card_use.from:drawCards(1, 'recast')
            return
        end
        local source = card_use.from
        local targets = card_use.to
        local use = sgs.CardUseStruct(self, source, targets)
        self:cardOnUse(room, use)
    end,
    on_use = function(self, room, source, targets)
        local minCard = 10000
        for _, p in ipairs(targets) do
            if p:getHandcardNum() < minCard then
                minCard = p:getHandcardNum()
            end
        end
        room:setTag('AdjustSaltPlum', sgs.QVariant(minCard))
        local ids = sgs.IntList()
        local data2 = sgs.QVariant()
        data2:setValue(ids)
        room:setTag('AdjustSaltPlumDiscards', data2)
        local target_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            target_list:append(target)
        end
        rinsan.defaultOnUse(self, room, source, targets)
        local allSame = true
        if #targets == 0 then
            return
        end
        for i = 1, #targets - 1, 1 do
            if targets[i]:getHandcardNum() ~= targets[i + 1]:getHandcardNum() then
                allSame = false
                break
            end
        end
        if allSame then
            local discard = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            for _, id in sgs.qlist(room:getTag('AdjustSaltPlumDiscards'):toIntList()) do
                if room:getCardPlace(id) == sgs.Player_DiscardPile then
                    discard:addSubcard(id)
                end
            end
            if discard:subcardsLength() == 0 then
                return
            end
            local choosePrompt = string.format('%s', 'AdjustSaltPlum-Choose')
            local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), choosePrompt, true)
            if target then
                target:obtainCard(discard)
            end
        end
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = target:getRoom()
        local minNum = room:getTag('AdjustSaltPlum'):toInt()
        local prompt = string.format('%s:%s', 'AdjustSaltPlum-Discard', source:objectName())
        if target:getHandcardNum() > minNum then
            local discard = room:askForCard(target, '.!', prompt, sgs.QVariant(), sgs.Card_MethodDiscard)
            if not discard then
                local cards = target:getCards('he')
                discard = cards:at(rinsan.random(0, cards:length() - 1))
                room:throwCard(discard, target)
            end
            local ids = room:getTag('AdjustSaltPlumDiscards'):toIntList()
            ids:append(discard:getEffectiveId())
            local data = sgs.QVariant()
            data:setValue(ids)
            room:setTag('AdjustSaltPlumDiscards', data)
        elseif target:getHandcardNum() == minNum then
            target:drawCards(1, self:objectName())
        end
    end,
}

local suits = {sgs.Card_Heart, sgs.Card_Spade, sgs.Card_Diamond, sgs.Card_Club}

for i = 1, 4, 1 do
    local card = adjust_salt_plum:clone()
    card:setSuit(suits[i])
    card:setNumber(6)
    card:setParent(extension)
end

-- 兵临城下
city_under_siege = sgs.CreateTrickCard {
    name = 'city_under_siege',
    class_name = 'CityUnderSiege',
    subtype = 'single_target_trick',
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    -- 无需覆写 on_use，否则会造成一系列结算问题
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local card_ids = room:getNCards(4, false)
        room:fillAG(card_ids)
        room:getThread():delay(500)
        local goback = sgs.IntList()
        for _, id in sgs.qlist(card_ids) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:isKindOf('Slash') then
                room:useCard(sgs.CardUseStruct(cd, source, target), false)
            else
                goback:append(id)
            end
        end
        room:clearAG()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, '', self:objectName(), nil)
        local move = sgs.CardsMoveStruct(goback, nil, nil, sgs.Player_PlaceTable, sgs.Player_DrawPile, reason)
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false)
        room:notifyMoveCards(false, moves, false)
        room:returnToTopDrawPile(goback)
    end,
}

for i = 1, 3, 1 do
    local card = city_under_siege:clone()
    card:setSuit(i ~= 1 and sgs.Card_Club or sgs.Card_Spade)
    card:setNumber(i == 3 and 13 or 7)
    card:setParent(extension)
end

-- 玄剑
xuanjian_sword = sgs.CreateWeapon {
    name = 'xuanjian_sword',
    class_name = 'XuanjianSword',
    range = 3,
    suit = sgs.Card_Spade,
    number = 9,
}

xuanjian_sword:setParent(extension)

-- 共砺接口
local function gongliZhugeAvailable(youxushu)
    -- TODO：后续友诸葛亮上线时增加判断
    return false
end

-- 玄剑选牌
local function filterXuanjianCards(source, selected, to_select)
    if gongliZhugeAvailable(source) then
        -- 共砺生效：一张牌即可
        return #selected < 1 and not to_select:isEquipped()
    end
    -- 需要的花色数
    local requiredSuitCount = 1
    -- 判断已选择卡牌是否满足花色数
    local xuanjian_suits = {}
    for _, cd in ipairs(selected) do
        local suit = cd:getSuitString()
        if not table.contains(xuanjian_suits, suit) then
            table.insert(xuanjian_suits, suit)
        end
    end

    -- 是否是装备牌、能否弃置
    if to_select:isEquipped() or source:isJilei(to_select) then
        return false
    end

    -- 要么是已选中花色，要么是不够花色
    return table.contains(xuanjian_suits, to_select:getSuitString()) or #xuanjian_suits < requiredSuitCount
end

-- 判断玄剑选牌合法性
local function checkXuanjianCards(source, cards)
    if gongliZhugeAvailable(source) then
        -- 共砺生效：一张牌即可
        return #cards == 1 and not cards[1]:isEquipped()
    end

    -- 需要的花色数
    local requiredSuitCount = 1

    -- 判断已选择卡牌是否满足花色数
    local xuanjian_suits = {}
    for _, cd in ipairs(cards) do
        local suit = cd:getSuitString()
        if not table.contains(xuanjian_suits, suit) then
            table.insert(xuanjian_suits, suit)
        end
    end
    if #xuanjian_suits < requiredSuitCount then
        return false
    end

    local ids = {}
    for _, cd in ipairs(cards) do
        table.insert(ids, cd:getEffectiveId())
    end

    -- 判断所有手牌是否已被选中
    for _, cd in sgs.qlist(source:getHandcards()) do
        local suit = cd:getSuitString()
        if table.contains(xuanjian_suits, suit) and not table.contains(ids, cd:getEffectiveId()) then
            return false
        end
    end

    return true
end

xuanjian_sword_skill = sgs.CreateViewAsSkill {
    name = 'xuanjian_sword',
    n = 999,
    view_filter = function(self, selected, to_select)
        return filterXuanjianCards(sgs.Self, selected, to_select)
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        if not checkXuanjianCards(sgs.Self, cards) then
            return nil
        end
        local card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in ipairs(cards) do
            card:addSubcard(cd)
        end
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getMark('Equips_Nullified_to_Yourself') == 0
    end,
}

if not sgs.Sanguosha:getSkill('xuanjian_sword') then
    skillList:append(xuanjian_sword_skill)
end

sgs.Sanguosha:addSkills(skillList)
