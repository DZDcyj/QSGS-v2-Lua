-- 蒲元武器包 AI
-- Created by DZDcyj at 2021/9/10
sgs.ai_skill_invoke.Hongduanqiang_skill = function(self)
    return self.player:isWounded()
end

sgs.ai_skill_cardask["@Liecuiren"] = function(self, data, pattern, target)
    if target and self:isFriend(target) then
        return "."
    end
    local types = pattern:split("|")[1]:split(",")
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards)
    for _, card in ipairs(cards) do
        if not self:isValuableCard(card) then
            for _, classname in ipairs(types) do
                if card:isKindOf(classname) then
                    return "$" .. card:getEffectiveId()
                end
            end
        end
    end
    return "."
end

sgs.ai_skill_invoke.Tianleiren_skill = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    return false
end

sgs.ai_skill_playerchosen.Shuibojian_skill = function(self, targetlist)
    local card = self.player:getTag('ShuibojianCard'):toString()
    if string.find(card, "slash") then
        -- Slash
        local targets = sgs.QList2Table(targetlist)
        self:sort(targets)
        local friends, enemies = {}, {}
        for _, target in ipairs(targets) do
            if not self:cantbeHurt(target, self.player) and self:damageIsEffective(target, nil, self.player) then
                if self:isEnemy(target) then
                    table.insert(enemies, target)
                elseif self:isFriend(target) then
                    table.insert(friends, target)
                end
            end
        end
        for _, enemy in ipairs(enemies) do
            if not self:getDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy, self.player) then
                return enemy
            end
        end
        for _, friend in ipairs(friends) do
            if self:getDamagedEffects(friend, self.player) and self:needToLoseHp(friend, self.player) then
                return friend
            end
        end
        return nil
    else
        -- NDTrick
        local targets = sgs.QList2Table(targetlist)
        self:sort(targets)
        if card == "ex_nihilo" then
            for _, target in ipairs(targets) do
                if self:isFriend(target) and not hasManjuanEffect(target) and not self:needKongcheng(target, true) then
                    return target
                end
            end
        else
            for _, target in ipairs(targets) do
                if self:isEnemy(target) and not self:needKongcheng(target, true) then
                    return target
                end
            end
        end
    end
    return nil
end

sgs.ai_skill_invoke.Hunduwandao_skill = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        if self:canHit(target, self.player) and not self:needToLoseHp(target, self.player, true) then
            return true
        end
    else
        if not self:canHit(target, self.player) or self:needLeiji(target, self.player) or
            self:getDamagedEffects(target, self.player, true) or self:needToLoseHp(target, self.player, true) then
            return true
        end
    end
    return false
end
