sgs.ai_skill_discard['LuaShaika'] = function(self, discard_num, min_num, optional, include_equip)
    -- 如果要弃置的牌大于总牌数，则不弃牌
    if discard_num > self.player:getCardCount(true) then
        return {}
    end
    -- 如果要弃置的牌数量大于总牌数的二分之一，并且当前状态良好，则直接选择不弃牌
    if discard_num > self.player:getCardCount(true) / 2 and not self.player:isWeak() then
        return {}
    end
    local room = self.player:getRoom()
    -- 如果当前角色没有绝情
    if not room:getCurrent():hasSkill('jueqing') then
        -- 如果可以卖血
        if
            self:hasSkills(sgs.masochism_skill, self.player) and
                (self.player:getHp() > 1 or self:getCardsNum('Peach') > 0 or self:getCardsNum('Analeptic') > 0)
         then
            return {}
        end
    end
    local to_discard, temp = {}, {}
    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    -- 遍历手牌和装备区，将价值较低的牌先列入准备弃置的列表
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) then
            local place = self.room:getCardPlace(card:getEffectiveId())
            if place == sgs.Player_PlaceEquip then
                table.insert(temp, card:getEffectiveId())
            elseif self:getKeepValue(card) >= 4.1 then
                table.insert(temp, card:getEffectiveId())
            else
                table.insert(to_discard, card:getEffectiveId())
            end
        end
        -- 待弃牌数量足够，则直接弃牌
        if #to_discard == discard_num then
            return to_discard
        end
    end
    -- 如果先前的列表不够弃置
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
        end
    end
    return to_discard
end
