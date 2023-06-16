-- 限定-高山仰止包 AI
-- Created by DZDcyj at 2023/5/2

-- 王朗
-- 鼓舌
local LuaGushe_skill = {}
LuaGushe_skill.name = 'LuaGushe'
table.insert(sgs.ai_skills, LuaGushe_skill)
LuaGushe_skill.getTurnUseCard = function(self)
    -- 防止自爆
    if self.player:getMark('@LuaGushe') >= 6 or self.player:isKongcheng() then
        return
    end
    if self.player:getMark('LuaGusheWin') >= 7 - self.player:getMark('@LuaGushe') then
        return
    end
    for _, enemy in ipairs(self.enemies) do
        if self.player:canPindian(enemy, 'LuaGushe') then
            return sgs.Card_Parse('#LuaGusheCard:.:')
        end
    end
end

sgs.ai_skill_use_func['#LuaGusheCard'] = function(_card, use, self)
    local cards = sgs.QList2Table(self.player:getCards('h'))
    self:sortByUseValue(cards, true)
    self:sort(self.enemies, 'handcard')
    local mostTargets = math.min(3, 7 - self.player:getMark('@LuaGushe'))
    if mostTargets <= 1 then
        return
    end
    for _, enemy in ipairs(self.enemies) do
        if self.player:canPindian(enemy, 'LuaGushe') then
            if use.to and use.to:length() < mostTargets then
                use.to:append(enemy)
            end
        end
    end
    for _, card in ipairs(cards) do
        if not card:isKindOf('Peach') and not card:isKindOf('ExNihilo') and not card:isKindOf('Jink') or
            (card:getNumber() <= self.player:getMark('@LuaGushe')) then
            use.card = sgs.Card_Parse('#LuaGusheCard:' .. card:getId() .. ':')
        end
    end
end

sgs.ai_use_value['LuaGusheCard'] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority['LuaGusheCard'] = sgs.ai_use_priority.ExNihilo - 0.1
