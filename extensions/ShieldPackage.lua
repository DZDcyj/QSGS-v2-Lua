-- 护甲包
-- Created by DZDcyj at 2023/2/6
module('extensions.ShieldPackage', package.seeall)
extension = sgs.Package('ShieldPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- 初始护甲值表
local START_SHIELDS = {
    ['ExMouHuaxiong'] = 1,
    ['ExMouCaoren'] = 1,
}

local function globalTrigger(self, target)
    return true
end

-- 护甲结算
LuaShield = sgs.CreateTriggerSkill {
    name = 'LuaShield',
    events = {sgs.DamageDone},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        -- 必要时终止多余结算
        if rinsan.getShieldCount(damage.to) <= 0 then
            return false
        end

        -- 这里延时一下，是避免当有多人同时受到伤害时(比如释放了AOE牌)，
        -- 掉血效果太快导致看不清楚的问题
        if damage.to:getAI() then
            room:getThread():delay(500)
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

        local newHp = damage.to:getHp() - math.max(0, damage.damage - rinsan.getShieldCount(damage.to))

        local jsonArray = string.format('"%s",%d,%d', damage.to:objectName(), -damage.damage, damage.nature)
        room:doBroadcastNotify(rinsan.FixedCommandType['S_COMMAND_CHANGE_HP'], jsonArray)

        room:setTag('HpChangedData', data)

        if damage.nature ~= sgs.DamageStruct_Normal and player:isChained() and (not damage.chain) then
            local n = room:getTag('is_chained'):toInt()
            n = n + 1
            room:setTag('is_chained', sgs.QVariant(n))
        end

        -- 失去护盾数，目前用于【狭援】
        if damage.damage >= rinsan.getShieldCount(damage.to) then
            room:setPlayerFlag(damage.to, 'ShieldAllLost')
            damage.to:setTag('ShieldLostCount', sgs.QVariant(math.min(damage.damage, rinsan.getShieldCount(damage.to))))
        end

        rinsan.decreaseShield(damage.to, damage.damage)

        -- 手动播放音效和动画
        if damage.damage > 0 then
            local delta = damage.damage > 3 and 3 or damage.damage
            sgs.Sanguosha:playSystemAudioEffect(string.format('injure%d', delta), true)
        end
        room:setEmotion(damage.to, 'damage')

        if damage.nature == sgs.DamageStruct_Fire then
            room:doAnimate(rinsan.ANIMATE_FIRE, damage.to:objectName())
        elseif damage.nature == sgs.DamageStruct_Thunder then
            room:doAnimate(rinsan.ANIMATE_LIGHTING, damage.to:objectName())
        end

        rinsan.sendLogMessage(room, '#GetHp', {
            ['from'] = damage.to,
            ['arg'] = newHp,
            ['arg2'] = damage.to:getMaxHp(),
        })
        room:setPlayerProperty(damage.to, 'hp', sgs.QVariant(newHp))
        return true
    end,
    can_trigger = globalTrigger,
}

-- 护甲初始化
LuaShieldInit = sgs.CreateTriggerSkill {
    name = 'LuaShieldInit',
    global = true,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local first = START_SHIELDS[p:getGeneralName()] or 0
            local second = START_SHIELDS[p:getGeneral2Name()] or 0
            room:setPlayerMark(p, rinsan.SHIELD_MARK, math.min(rinsan.MAX_SHIELD_COUNT, first + second))
        end
    end,
    can_trigger = globalTrigger,
}

-- 修正神甘宁魄袭多弃牌问题
LuaPoxiHotFix = sgs.CreateTriggerSkill {
    name = 'LuaPoxiHotFix',
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to_place == sgs.Player_DiscardPile then
            for _, id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                if card:hasFlag('poxi') then
                    room:setCardFlag(card, '-poxi')
                end
            end
        end
    end,
    can_trigger = globalTrigger,
}

table.insert(hiddenSkills, LuaShield)
table.insert(hiddenSkills, LuaShieldInit)
table.insert(hiddenSkills, LuaPoxiHotFix)

rinsan.addHiddenSkills(hiddenSkills)
