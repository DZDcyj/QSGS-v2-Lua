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
