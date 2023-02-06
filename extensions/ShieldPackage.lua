-- 护盾包
-- Created by DZDcyj at 2023/2/6
module('extensions.ShieldPackage', package.seeall)
extension = sgs.Package('ShieldPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

LuaTest = sgs.CreateTriggerSkill {
    name = 'LuaTest',
    events = {sgs.DamageDone},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        -- 必要时终止多余结算
        if rinsan.getShieldCount(damage.to) <= 0 then
            return false
        end
        if damage.from and (not damage.from:isAlive()) then
            damage.from = nil
        end
        data:setValue(damage)

        local params = {}
        local type = '#DamageNoSource'

        if damage.from then
            params['from'] = damage.from
            type = '#Damage'
        end
        params['to'] = damage.to
        params['arg'] = damage.damage

        local nature = 'normal_nature'
        if damage.nature == sgs.DamageStruct_Fire then
            nature = 'fire_nature'
        elseif damage.nature == sgs.DamageStruct_Thunder then
            nature = 'thunder_nature'
        end
        params['arg2'] = nature
        rinsan.sendLogMessage(room, type, params)

        local newHp = damage.to:getHp() - damage.damage + rinsan.getShieldCount(damage.to)
        local newShield = math.max(rinsan.getShieldCount(damage.to) - damage.damage, 0)

        -- local changeString = string.format('%s:%d', damage.to:objectName(), -damage.damage)
        -- if damage.nature == sgs.DamageStruct_Fire then
        --     changeString = changeString .. 'F'
        -- elseif damage.nature == sgs.DamageStruct_Thunder then
        --     changeString = changeString .. 'T'
        -- end

        -- -- 用 int 替代 CommandType_S_COMMAND_CHANGE_HP
        -- room:doBroadcastNotify(30, changeString)

        room:setTag('HpChangedData', data)

        if damage.nature ~= sgs.DamageStruct_Normal and player:isChained() and (not damage.chain) then
            local n = room:getTag('is_chained'):toInt()
            n = n + 1
            room:setTag('is_chained', sgs.QVariant(n))
        end

        room:setPlayerProperty(damage.to, 'hp', sgs.QVariant(newHp))
        room:setPlayerMark(damage.to, '@shield', newShield)

        return true
    end,
    can_trigger = function(self, target)
        return true
    end
}

SkillAnjiang:addSkill(LuaTest)
