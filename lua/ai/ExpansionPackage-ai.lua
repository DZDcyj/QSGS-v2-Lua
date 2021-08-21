sgs.ai_skill_discard['LuaMieji']=function(self, discard_num, min_num, optional, include_equip)
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
