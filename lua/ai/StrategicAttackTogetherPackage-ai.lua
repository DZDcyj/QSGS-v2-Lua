-- 谋攻篇-同包 AI
-- Created by DZDcyj at 2023/4/1
-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 谋夏侯氏
-- 樵拾
sgs.ai_skill_invoke['LuaMouQiaoshi'] = function(self, data)
    -- data string likes below:
    -- invoke:sgs1::1
    local targetObjectName = data:toString():split(':')[2]
    local damageValue = data:toString():split(':')[4]
    damageValue = tonumber(damageValue)
    local target
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:objectName() == targetObjectName then
            target = p
            break
        end
    end
    -- 是友方就可以摸牌让他回血
    if self:isFriend(target) then
        return true
    end
    if damageValue > 1 then
        return false
    end
    local DoubleDamage = false
    if getKnownCard(from, self.player, 'TrickCard') > 1 or (getKnownCard(from, self.player, 'Slash') > 1 and
        ((getKnownCard(from, self.player, 'Crossbow') > 0 or from:hasSkills(sgs.double_slash_skill)))) or
        from:hasSkills(sgs.straight_damage_skill) or from:getHandcardNum() > 5 then
        DoubleDamage = true
    end
    -- 如果可以多打就自己摸牌
    return DoubleDamage
end
