-- 限定-百战虎贲包 AI
-- Created by DZDcyj at 2023/5/5
-- 留赞
-- 力激 
local LuaLiji_skill = {}
LuaLiji_skill.name = 'LuaLiji'
table.insert(sgs.ai_skills, LuaLiji_skill)
LuaLiji_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then
        return nil
    end
    if self.player:usedTimes('#LuaLijiCard') >= self.player:getMark('LuaLijiAvailableTimes') then
        return nil
    end
    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    return sgs.Card_Parse('#LuaLijiCard:' .. cards[1]:getEffectiveId() .. ':')
end

sgs.ai_skill_use_func['#LuaLijiCard'] = function(card, use, self)
    local target
    if #self.enemies <= 0 then
        return
    end
    self:sort(self.enemies, 'defense')
    for _, enemy in ipairs(self.enemies) do
        if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
            target = enemy
            break
        end
    end
    if target then
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByKeepValue(cards)
        use.card = sgs.Card_Parse('#LuaLijiCard:' .. cards[1]:getEffectiveId() .. ':')
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_card_intention.LuaLijiCard = function(self, card, from, tos)
    local to = tos[1]
    sgs.updateIntention(from, to, 80)
end
