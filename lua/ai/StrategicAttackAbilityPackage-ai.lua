-- 谋攻篇-能包 AI
-- Created by DZDcyj at 2023/2/23

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 谋孙尚香给牌/移动标记
sgs.ai_skill_choice['LuaMouJieyin'] = function(self, choices)
    local target = self.player:getTag('LuaMouLiangZhuTarget'):toPlayer()
    -- 如果自己虚，且不是队友就不给
    if not self:isFriend(target) then
        -- 如果自己叠满了，且不是队友就不给
        if self:isWeak() or (not rinsan.canIncreaseShield(self.player)) then
            return 'LuaMouJieyinChoice2'
        end
    end
    -- 能给就给
    local items = choices:split('+')
    return items[1]
end
