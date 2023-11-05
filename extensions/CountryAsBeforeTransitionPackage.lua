-- 江山如故·转包
-- Created by DZDcyj at 2023/11/5
module('extensions.CountryAsBeforeTransitionPackage', package.seeall)
extension = sgs.Package('CountryAsBeforeTransitionPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 转·马超
ExZhuanMachao = sgs.General(extension, 'ExZhuanMachao', 'qun', '4', true, true)

LuaZhuiming = sgs.CreateTriggerSkill {
    name = 'LuaZhuiming',
    events = {sgs.TargetSpecified, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain then
                return false
            end
            if damage.card and player:getMark(string.format('%s-%s-Clear', self:objectName(), damage.card:toString())) > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:removePlayerMark(player, string.format('%s-%s-Clear', self:objectName(), damage.card:toString()))
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
            return false
        end
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and use.to:length() == 1 then
            local caocao = use.to:at(0)
            local data2 = sgs.QVariant()
            data2:setValue(caocao)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), caocao:objectName())
                local choice = room:askForChoice(player, self:objectName(), 'red+black')
                rinsan.sendLogMessage(room, '#choose', {
                    ['from'] = player,
                    ['arg'] = choice,
                })
                local prompt = string.format('@LuaZhuiming:%s::%s', player:objectName(), choice)
                room:askForDiscard(caocao, 'LuaZhuiming', 10000, 1, true, true, prompt)
                if not caocao:isNude() then
                    local card_id = room:askForCardChosen(player, caocao, 'he', self:objectName())
                    room:showCard(caocao, card_id)
                    local real_card = sgs.Sanguosha:getCard(card_id)
                    if choice == rinsan.getColorString(real_card) then
                        -- 不可闪避
                        local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
                        local index = 1
                        for _, p in sgs.qlist(use.to) do
                            if p:isAlive() then
                                rinsan.sendLogMessage(room, '#NoJink', {
                                    ['from'] = p,
                                })
                            end
                            jink_table[index] = 0
                            index = index + 1
                        end
                        local jink_data = sgs.QVariant()
                        jink_data:setValue(Table2IntList(jink_table))
                        player:setTag('Jink_' .. use.card:toString(), jink_data)
                        -- 不计入使用次数
                        room:addPlayerHistory(player, use.card:getClassName(), -1)
                        use.m_addHistory = false
                        data:setValue(use)
                        -- 伤害+1
                        room:addPlayerMark(player, string.format('%s-%s-Clear', self:objectName(), use.card:toString()))
                    end
                end
            end
        end
        return false
    end,
}

ExZhuanMachao:addSkill(LuaZhuiming)
ExZhuanMachao:addSkill('mashu')

rinsan.addHiddenSkills(hiddenSkills)
