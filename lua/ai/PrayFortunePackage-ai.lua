-- 限定-祈福包 AI
-- Created by DZDcyj at 2023/5/4
-- 是否发动制蛮
sgs.ai_skill_invoke.LuaZhiman = function(self, data)
    local damage = data:toDamage()
    local target = damage.to
    if self:isFriend(target) then
        if damage.damage == 1 and self:getDamagedEffects(target, self.player) then
            return false
        end
        return true
    else
        if self:hasHeavySlashDamage(self.player, damage.card, target) then
            return false
        end
        if self:isWeak(target) then
            return false
        end
        if self:doNotDiscard(target, 'e', true) then
            return false
        end
        if self:getDamagedEffects(target, self.player, true) or
            (target:getArmor() and not target:getArmor():isKindOf('SilverLion')) then
            return true
        end
        if self:getDangerousCard(target) then
            return true
        end
        if target:getDefensiveHorse() then
            return true
        end
        return false
    end
end

-- 征南选择
sgs.ai_skill_choice['LuaZhengnan'] = function(self, choices)
    local items = choices:split('+')
    if #items == 1 then
        return items[1]
    else
        if table.contains(items, 'LuaDangxian') then
            return 'LuaDangxian'
        end
        if table.contains(items, 'zhiman') then
            return 'LuaZhiman'
        end
        if table.contains(items, 'wusheng') then
            return 'wusheng'
        end
    end
    return items[1]
end
