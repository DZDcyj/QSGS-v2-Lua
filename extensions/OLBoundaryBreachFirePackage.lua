-- OL-界限突破-火包
-- Created by DZDcyj at 2023/5/5
module('extensions.OLBoundaryBreachFirePackage', package.seeall)
extension = sgs.Package('OLBoundaryBreachFirePackage')

OLJieXunyu = sgs.General(extension, 'OLJieXunyu', 'wei', '3', true, true)

-- 封装函数【节命】OL
-- 返回值代表是否成功发动【节命】
local function doJiemingDrawDiscard(player)
    local room = player:getRoom()
    local alives = room:getAlivePlayers()
    if alives:isEmpty() then
        return false
    end
    local target = room:askForPlayerChosen(player, alives, 'LuaOLJieming', 'jieming-invoke', true, true)
    if target then
        room:broadcastSkillInvoke('LuaOLJieming')
        local x = math.min(5, target:getMaxHp())
        target:drawCards(x, 'LuaOLJieming')
        local diff = target:getHandcardNum() - x
        if diff > 0 then
            room:askForDiscard(target, 'LuaOLJieming', diff, diff)
        end
    end
    return target ~= nil
end

LuaOLJieming = sgs.CreateTriggerSkill {
    name = 'LuaOLJieming',
    events = {sgs.Death, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                doJiemingDrawDiscard(player)
            end
        else
            if not player:isAlive() then
                return false
            end
            local damage = data:toDamage()
            local i = 0
            while i < damage.damage do
                i = i + 1
                if not doJiemingDrawDiscard(player) then
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
