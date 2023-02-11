-- 谋攻包 AI
-- Created by DZDcyj at 2023/2/8
-- 谋于禁节钺给牌
sgs.ai_skill_discard['LuaMouJieyue'] = function(self, discard_num, min_num, optional, include_equip)
    -- 空城就别给了
    if self.player:isKongcheng() then
        return {}
    end
    -- 始终给最低保留价值的手牌
    local cards = sgs.QList2Table(self.player:getCards('h'))
    self:sortByKeepValue(cards, true)
    return {cards[1]:getEffectiveId()}
end

-- 谋孙尚香给牌/移动标记
sgs.ai_skill_choice['LuaMouJieyin'] = function(self, choices)
    local target = self.player:getTag('LuaMouLiangZhuTarget'):toPlayer()
    -- 如果自己虚，且不是队友就不给
    if self:isWeak() and not self:isFriend(target) then
        return 'LuaMouJieyinChoice2'
    end
    -- 能给就给
    local items = choices:split('+')
    return items[1]
end
