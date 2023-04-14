-- 始计篇-勇包 AI
-- Created by DZDcyj at 2023/3/4

-- 宗预
-- 御严给牌
sgs.ai_skill_cardask['@Yuyan-give'] = function(self, data)
    local use = data:toCardUse()
    local target = self.player:getTag('LuaYuyanTarget'):toPlayer()
    local number = use.card:getNumber()
    if self:isFriend(target) then
        return '.'
    end
    local cards = {}
    for _, cd in sgs.qlist(self.player:getCards('he')) do
        if cd:getNumber() > number then
            table.insert(cards, cd)
        end
    end
    self:sortByUseValue(cards, true)
    if #cards == 0 or self:isValuableCard(cards[1]) then
        return '.'
    end
    return cards[1]
end

-- 王双
-- 是否发动异勇
sgs.ai_skill_invoke['LuaYiyong'] = function(self, data)
    local target = data:toPlayer()
    return not self:isFriend(target)
end

-- 擅械
local LuaShanxie_skill = {}
LuaShanxie_skill.name = 'LuaShanxie'

table.insert(sgs.ai_skills, LuaShanxie_skill)

LuaShanxie_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getWeapon() then
        -- 有武器不发动
        return nil
    end
    if not self.player:hasUsed('#LuaShanxie') then
        return sgs.Card_Parse('#LuaShanxie:.:')
    end
end

sgs.ai_skill_use_func['#LuaShanxie'] = function(card, use, self)
    local card_str = '#LuaShanxie:.:'
    local acard = sgs.Card_Parse(card_str)
    assert(acard)
    use.card = acard
end
