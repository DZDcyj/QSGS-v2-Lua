-- 斗地主包 AI
-- Created by DZDcyj at 2021/10/9
sgs.ai_skill_use['@@LuaFeiyang'] = function(self, prompt, method)
    -- 如果判定区内有“言笑”牌，不发动飞扬
    if self.player:containsTrick('YanxiaoCard') then
        return '.'
    end
    -- 引用“修罗”逻辑
    if
        not self.player:containsTrick('indulgence') and not self.player:containsTrick('supply_shortage') and
            not (self.player:containsTrick('lightning') and not self:hasWizard(self.enemies))
     then
        return '.'
    end
    -- 丢弃使用价值最低的两张手牌
    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    return '#LuaFeiyangCard:' .. table.concat({cards[1]:getEffectiveId(), cards[2]:getEffectiveId()}, '+') .. ':.'
end

-- 农民选择
sgs.ai_skill_choice['LuaNongmin'] = function(self, choices)
    -- choices 可能取值为
    -- LuaNongminChoice1 LuaNongminChoice2 cancel
    local items = choices:split('+')
    if self.player:getHp() < self.player:getMaxHp() - 1 then
        -- 此项流程中，一定可以回血，选第一个
        return items[1]
    end
    -- 选倒数第二个摸牌
    return items[#items-1]
end
