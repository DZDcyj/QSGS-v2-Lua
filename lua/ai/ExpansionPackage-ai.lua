sgs.ai_skill_discard['LuaMieji']=function(self, discard_num, min_num, optional, include_equip)
	min_num = min_num or discard_num
    local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
    self:assignKeep(true)

    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local to_discard, temp = {}, {}

    local least = min_num
    if discard_num - min_num > 1 then
        least = discard_num - 1
    end
    for _, card in ipairs(cards) do
        if exchange or not self.player:isJilei(card) and not card:isKindOf('TrickCard') then
            if self:getKeepValue(card) >= 4.1 then
                table.insert(temp, card:getEffectiveId())
            else
                table.insert(to_discard, card:getEffectiveId())
            end
        end
        if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then break end
    end
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
            if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then break end
        end
    end
    return to_discard
end

sgs.ai_skill_choice['LuaJieyue'] = function(self, choices, data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if self:isFriend(target) then return items[2] end
    if self.player:getCardCount(true) <= 3 then return items[1] end
    local count = 0
    for _, card in sgs.qlist(self.player:getHandcards()) do
        count = count + 1
        if self:isValuableCard(card) then count = count + 0.5 end
    end
    local equip_val_table = { 2, 2.5, 1, 1.5, 2.2 }
    for i = 0, 4, 1 do
        if self.player:getEquip(i) then
            if i == 1 and self:needToThrowArmor() then
                count = count - 1
            else
                count = count + equip_val_table[i + 1]
                if self.player:hasSkills(sgs.lose_equip_skill) then count = count + 0.5 end
            end
        end
    end
    if count < 4 then
        return items[1]
    end
    return items[2]
end

sgs.ai_skill_cardchosen['LuaJieyue'] = function(self, who, flags)
    local cards = self.player:getCards(flags)
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards, true)
    return cards[1]
end


sgs.ai_skill_discard['LuaShanxi'] = function(self, discard_num, min_num, optional, include_equip)
    -- 诈降
    if not self:isWeak() and self.player:hasSkill('zhaxiang') then
        return {}
    end

    min_num = min_num or discard_num
    local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
    local callback = sgs.ai_skill_discard[reason]
    self:assignKeep(true)

    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local to_discard, temp = {}, {}

    local least = min_num
    if discard_num - min_num > 1 then
        least = discard_num - 1
    end
    for _, card in ipairs(cards) do
        if exchange or not self.player:isJilei(card) and not card:isKindOf('TrickCard') then
            place = self.room:getCardPlace(card:getEffectiveId())
            if self:getKeepValue(card) >= 4.1 then
                table.insert(temp, card:getEffectiveId())
            else
                table.insert(to_discard, card:getEffectiveId())
            end
        end
        if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then break end
    end
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
            if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then break end
        end
    end
    return to_discard
end