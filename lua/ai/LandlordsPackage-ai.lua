-- 飞扬 AI
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
