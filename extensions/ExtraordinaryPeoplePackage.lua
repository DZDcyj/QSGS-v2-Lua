-- 限定-奇人异士包
-- Created by DZDcyj at 2023/4/27
module('extensions.ExtraordinaryPeoplePackage', package.seeall)
extension = sgs.Package('ExtraordinaryPeoplePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function globalTrigger(self, target)
    return true
end

-- 蒲元
ExPuyuan = sgs.General(extension, 'ExPuyuan', 'shu', '4', true, true)

LuaTianjiangCard = sgs.CreateSkillCard {
    name = 'LuaTianjiang',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local equip = sgs.Sanguosha:getCard(self:getSubcards():first())
        local location = equip:getRealCard():toEquipCard():location()
        local exchangeMove = sgs.CardsMoveList()
        local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(),
            '')
        local move1 = sgs.CardsMoveStruct(equip:getEffectiveId(), target, sgs.Player_PlaceEquip, reason1)
        exchangeMove:append(move1)
        if target:getEquip(location) then
            local equippedId = target:getEquip(location):getEffectiveId()
            local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, target:objectName())
            local move2 = sgs.CardsMoveStruct(equippedId, target, sgs.Player_DiscardPile, reason2)
            exchangeMove:append(move2)
        end
        room:moveCardsAtomic(exchangeMove, true)
        if rinsan.isPuyuanEquip(equip) then
            source:drawCards(2, self:objectName())
        end
    end,
}

LuaTianjiangVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaTianjiang',
    filter_pattern = '.|.|.|equipped',
    view_as = function(self, card)
        local kf = LuaTianjiangCard:clone()
        kf:addSubcard(card)
        return kf
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

local function initialTianjiang(puyuan)
    local room = puyuan:getRoom()
    room:sendCompulsoryTriggerLog(puyuan, 'LuaTianjiang')
    room:broadcastSkillInvoke('LuaTianjiang')
    for _ = 1, 2, 1 do
        local checker = function(cd)
            if cd:isKindOf('EquipCard') then
                local equip = cd:getRealCard():toEquipCard()
                return puyuan:getEquip(equip:location()) == nil
            end
            return false
        end
        local equip = rinsan.obtainCardFromPile(checker, room:getDrawPile())
        if equip then
            room:moveCardTo(equip, puyuan, sgs.Player_PlaceEquip)
        end
    end
end

LuaTianjiang = sgs.CreateTriggerSkill {
    name = 'LuaTianjiang',
    events = {sgs.GameStart},
    view_as_skill = LuaTianjiangVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, puyuan in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if puyuan:getMark('LuaTianjiangInvoked') == 0 then
                room:addPlayerMark(puyuan, 'LuaTianjiangInvoked')
                initialTianjiang(puyuan)
            end
        end
    end,
    can_trigger = globalTrigger,
}

local function doZhurenSuccessCheck(card)
    -- 闪电和 K 牌一定成功
    if card:isKindOf('Lightning') or card:getNumber() == 13 then
        return true
    end
    -- 9-Q 点数成功率 95%
    if card:getNumber() >= 9 then
        return rinsan.random(1, 100) <= 95
    end
    -- 5-8 点数成功率 90%
    if card:getNumber() >= 5 then
        return rinsan.random(1, 100) <= 90
    end
    -- A-4 点数成功率 85%
    return rinsan.random(1, 100) <= 85
end

LuaZhurenCard = sgs.CreateSkillCard {
    name = 'LuaZhuren',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local success = doZhurenSuccessCheck(card)
        if not success then
            -- 不成功摸牌
            source:drawCards(1, self:objectName())
            return
        end
        local equip = rinsan.getPuyuanEquip(card)
        if (not equip) or (room:getCardOwner(equip:getEffectiveId()) ~= nil) then
            -- 已有此装备摸牌
            source:drawCards(1, self:objectName())
            return
        end
        local ids = sgs.IntList()
        ids:append(equip:getEffectiveId())
        rinsan.obtainCard(ids, source)
    end,
}

LuaZhuren = sgs.CreateOneCardViewAsSkill {
    name = 'LuaZhuren',
    filter_pattern = '.|.|.|hand',
    view_as = function(self, card)
        local kf = LuaZhurenCard:clone()
        kf:addSubcard(card)
        return kf
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaZhuren')
    end,
}

ExPuyuan:addSkill(LuaTianjiang)
ExPuyuan:addSkill(LuaZhuren)
