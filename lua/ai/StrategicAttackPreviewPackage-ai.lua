-- 谋攻篇-知包 AI
-- Created by DZDcyj at 2023/3/11
-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 相关涉及到失去体力技能
local function needLoseHp(player)
    if player:isWeak() then
        return false
    end
    if player:hasSkill('zhaxiang') then
        return true
    end
    if player:hasSkill('LuaMouKurou') then
        return rinsan.canIncreaseShield(player)
    end
    return false
end

-- 谋周瑜反间选择
sgs.ai_skill_choice['LuaMouFanjian'] = function(self, choices, data)
    local items = choices:split('+')
    if not self.player:faceUp() then
        -- 翻面就翻回来
        return items[#items]
    end
    local mouzhouyu = data:toPlayer()
    local suit = self.room:getTag('LuaMoufanjianDeclaredSuit'):toInt()
    -- 如果谋周瑜已经反间过这种花色，那必定不为其声明花色
    if mouzhouyu:hasFlag('LuaMouFanjian' .. rinsan.Suit2String(suit)) then
        -- 如果谋周瑜是友方，并且有相关失去体力技能，则就失去体力
        if self:isFriend(mouzhouyu) and needLoseHp(self.player) then
            return items[1]
        end
        return items[2]
    end
    -- 随机猜猜
    return items[rinsan.random(1, 2)]
end
