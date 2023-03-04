-- 始计篇-勇包 AI
-- Created by DZDcyj at 2023/3/4

-- 宗预
-- 御严给牌
sgs.ai_skill_cardask['@Yuyan-give'] = function(self, data)
    local use = data:toCardUse()
    local target = self.player:getTag('LuaYuyanTarget'):toPlayer()
    local card = use.card
    local number = use.card:getNumber()
    if self:isFriend(target) then
        self.room:writeToConsole('Friend')
        return '.'
    end
    self.room:writeToConsole('Not Friend')
    local cards = {}
    for _, cd in sgs.qlist(self.player:getCards('he')) do
        if cd:getNumber() > number then
            table.insert(cards, cd)
        end
    end
    self.room:writeToConsole('Cards Length:'..#cards)
    self:sortByUseValue(cards, true)
    if #cards == 0 or self:isValuableCard(cards[1]) then
        return '.'
    end
    return cards[1]
end
