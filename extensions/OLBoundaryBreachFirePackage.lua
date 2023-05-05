-- OL-界限突破-火包
-- Created by DZDcyj at 2023/5/5
module('extensions.OLBoundaryBreachFirePackage', package.seeall)
extension = sgs.Package('OLBoundaryBreachFirePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

OLJieXunyu = sgs.General(extension, 'OLJieXunyu', 'wei', '3', true, true)

LuaOLJieming = sgs.CreateTriggerSkill {
    name = 'LuaOLJieming',
    events = {sgs.Death, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                rinsan.doJiemingDrawDiscard(self:objectName(), player, room)
            end
        else
            if not player:isAlive() then
                return false
            end
            local damage = data:toDamage()
            local i = 0
            while i < damage.damage do
                i = i + 1
                if not rinsan.doJiemingDrawDiscard(self:objectName(), player, room) then
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

OLJieXunyu:addSkill('LuaQuhu')
OLJieXunyu:addSkill(LuaOLJieming)
