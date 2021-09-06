sgs.ai_skill_discard['LuaShaika'] = function(self, discard_num, min_num, optional, include_equip)
    if discard_num > self.player:getCardCount(true) / 2 and not self.player:isWeak() then
        -- 如果要弃置的牌数量大于手牌数的二分之一，并且当前状态良好，则直接选择不弃牌
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
        if (self.player:hasSkill('qinyin') and #to_discard >= min_num) or #to_discard >= discard_num then
            break
        end
    end
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
            if (self.player:hasSkill('qinyin') and #to_discard >= min_num) or #to_discard >= discard_num then break end
        end
    end
    return to_discard
end
