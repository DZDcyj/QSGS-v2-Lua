-- 兵势篇-势包
-- Created by DZDcyj at 2025/9/20
module('extensions.MilitaryPowerPackage', package.seeall)
extension = sgs.Package('MilitaryPowerPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')
local common = require('extensions.CommonSkillPackage')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 势魏延
ShiWeiyan = sgs.General(extension, 'ShiWeiyan', 'shu', 4, true, true, false)

VOICE_FUNCS = {
    ['LuaShiYinzhan'] = function(player)
        if player:getMark('LuaShiZhongao_success') > 0 then
            return rinsan.random(4, 6)
        elseif player:getMark('LuaShiZhongao_failure') > 0 then
            return rinsan.random(7, 9)
        else
            return rinsan.random(1, 3)
        end
    end,
    ['LuaShiZhuangshi'] = function(player)
        if player:getMark('LuaShiZhongao_success') > 0 then
            return rinsan.random(3, 4)
        end
        return rinsan.random(1, 2)
    end,
    ['LuaShiKuanggu'] = function(player)
        if player:getMark('LuaShiZhongao_success') > 0 then
            return rinsan.random(3, 6)
        elseif player:getMark('LuaShiZhongao_failure') > 0 then
            return rinsan.random(7, 8)
        end
        return rinsan.random(1, 2)
    end,
}

LuaShiZhuangshiCard = sgs.CreateSkillCard {
    name = 'LuaShiZhuangshiCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaShiZhuangshi')
        room:broadcastSkillInvoke('LuaShiZhuangshi', common.getVoiceIndex(source, 'LuaShiZhuangshi'))
        room:addPlayerMark(source, 'LuaShiZhuangshi_unresponsible_biu', self:subcardsLength())
        room:addPlayerMark(source, 'no_distance_limit_biu', self:subcardsLength())
    end,
}

LuaShiZhuangshiVS = sgs.CreateViewAsSkill {
    name = 'LuaShiZhuangshi',
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local card = LuaShiZhuangshiCard:clone()
            for _, c in ipairs(cards) do
                card:addSubcard(c)
            end
            return card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaShiZhuangshi'
    end,
}

LuaShiZhuangshi = sgs.CreateTriggerSkill {
    name = 'LuaShiZhuangshi',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaShiZhuangshiVS,
    on_trigger = function(self, event, player, data, room)
        local card = room:askForUseCard(player, '@@LuaShiZhuangshi', '@LuaShiZhuangshi')
        local lose_num = {}
        for i = 1, player:getHp() do
            table.insert(lose_num, tostring(i))
        end
        table.insert(lose_num, 'cancel')
        local choice = room:askForChoice(player, self:objectName(), table.concat(lose_num, '+'))
        if choice ~= 'cancel' then
            room:notifySkillInvoked(player, 'LuaShiZhuangshi')
            room:broadcastSkillInvoke(self:objectName(), common.getVoiceIndex(player, self:objectName()))
            choice = tonumber(choice)
            room:loseHp(player, tonumber(choice))
            room:addPlayerMark(player, 'no_use_count_biu', tonumber(choice))
        end
        if player:getMark('LuaShiZhongao') == 0 and not card and choice == 'cancel' then
            rinsan.sendLogMessage(room, '#LuaShiZhongaoFailure', {
                ['from'] = player,
                ['arg'] = 'LuaShiZhongao',
                ['arg2'] = 'LuaShiZhongaoNoZhuangshi',
            })
            room:broadcastSkillInvoke('LuaShiZhongao', 4)
            room:addPlayerMark(player, 'LuaShiZhongao_failure')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaShiZhongaoKilled = sgs.CreateTriggerSkill {
    name = '#LuaShiZhongaoKilled',
    events = {sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local killer
        if death.damage then
            killer = death.damage.from
        end
        if not killer or killer:objectName() ~= player:objectName() then
            return false
        end
        if killer:hasSkill('LuaShiZhongao') and killer:getMark('LuaShiZhongao') == 0 then
            rinsan.sendLogMessage(room, '#LuaShiZhongaoSuccess', {
                ['from'] = killer,
                ['arg'] = 'LuaShiZhongao',
                ['arg2'] = 'LuaShiZhongaoKilledPlayer',
            })
            room:broadcastSkillInvoke('LuaShiZhongao', rinsan.random(2, 3))
            room:addPlayerMark(killer, 'LuaShiZhongao_success')
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShiYinzhan = sgs.CreateTriggerSkill {
    name = 'LuaShiYinzhan',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if not damage.to then
            return false
        end
        local condition1 = player:getHp() <= damage.to:getHp()
        local condition2 = player:getCardCount(true) <= damage.to:getCardCount(true)
        if damage.card and damage.card:isKindOf('Slash') then
            if condition1 or condition2 then
                room:broadcastSkillInvoke(self:objectName(), common.getVoiceIndex(player, self:objectName()))
                room:sendCompulsoryTriggerLog(player, self:objectName())
            end
            if condition1 then
                damage.damage = damage.damage + 1
            end
            if condition2 then
                room:addPlayerMark(damage.to, 'LuaShiYinzhan_discard_biu')
            end
            if condition1 and condition2 then
                room:addPlayerMark(damage.to, 'LuaShiYinzhan_discard_obtain_biu')
            end
            data:setValue(damage)
        end
        return false
    end,
}

LuaShiYinzhanFinish = sgs.CreateTriggerSkill {
    name = 'LuaShiYinzhanFinish',
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            local card_id
            -- 处理铁索连环导致的伤害传导
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isAlive() then
                    if p:getMark('LuaShiYinzhan_discard_biu') > 0 then
                        room:removePlayerMark(p, 'LuaShiYinzhan_discard_biu')
                        room:sendCompulsoryTriggerLog(player, 'LuaShiYinzhan')
                        if rinsan.canDiscard(player, p, 'he') then
                            card_id = room:askForCardChosen(player, p, 'he', 'LuaShiYinzhan', false, sgs.Card_MethodDiscard)
                            room:throwCard(card_id, p, player)
                        end
                    end
                    if p:getMark('LuaShiYinzhan_discard_obtain_biu') > 0 then
                        room:removePlayerMark(p, 'LuaShiYinzhan_discard_obtain_biu')
                        rinsan.recover(player)
                        if card_id then
                            room:obtainCard(player, card_id, false)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShiZhongao = sgs.CreateTriggerSkill {
    name = 'LuaShiZhongao',
    events = {sgs.MarkChanged},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        local success_mark = 'LuaShiZhongao_success'
        local failure_mark = 'LuaShiZhongao_failure'
        local change_name = mark.name
        if change_name == success_mark then
            room:notifySkillInvoked(player, 'LuaShiZhongao')
            -- 成功
            if room:changeMaxHpForAwakenSkill(player, 0) then
                -- 如果还剩下标记，说明使用的牌没超过对应的项目
                -- 使用的牌数小于因“壮誓”弃置的牌数，摸一张牌
                if player:getMark('no_distance_limit_biu') > 0 then
                    player:drawCards(1, self:objectName())
                end
                -- 使用的牌数小于因“壮誓”失去的体力数，你回复1点体力（若你未受伤则改为摸一张牌）
                if player:getMark('no_use_count_biu') > 0 then
                    if player:isWounded() then
                        rinsan.recover(player)
                    else
                        player:drawCards(1, self:objectName())
                    end
                end
                room:addPlayerMark(player, self:objectName())
            end
        elseif change_name == failure_mark then
            room:notifySkillInvoked(player, 'LuaShiZhongao')
            -- 失败
            if room:changeMaxHpForAwakenSkill(player, 0) then
                room:detachSkillFromPlayer(player, 'LuaShiZhuangshi')
                room:acquireSkill(player, 'LuaShiKunfen')
                room:addPlayerMark(player, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target:getMark(self:objectName()) > 0 then
            return false
        end
        return rinsan.RIGHT(self, target)
    end,
}

LuaShiZhongaoStart = sgs.CreateTriggerSkill {
    name = '#LuaShiZhongaoStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local shiweiyans = room:findPlayersBySkillName('LuaShiZhongao')
        for _, p in sgs.qlist(shiweiyans) do
            if not p:hasSkill('LuaShiKuanggu') then
                room:broadcastSkillInvoke('LuaShiZhongao', 1)
                room:sendCompulsoryTriggerLog(p, 'LuaShiZhongao')
                room:acquireSkill(p, 'LuaShiKuanggu')
            end
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShizhongaoDying = sgs.CreateTriggerSkill {
    name = '#LuaShiZhongaoDying',
    events = {sgs.Dying},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:hasSkill('LuaShiZhongao') and dying.who:getMark('LuaShiZhongao') == 0 then
            rinsan.sendLogMessage(room, '#LuaShiZhongaoFailure', {
                ['from'] = dying.who,
                ['arg'] = 'LuaShiZhongao',
                ['arg2'] = 'LuaShiZhongaoDying',
            })
            room:broadcastSkillInvoke('LuaShiZhongao', 5)
            room:addPlayerMark(dying.who, 'LuaShiZhongao_failure')
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShiKuanggu = sgs.CreateTriggerSkill {
    name = 'LuaShiKuanggu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage, sgs.PreDamageDone},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.PreDamageDone and rinsan.RIGHT(self, damage.from) then
            damage.from:setTag('invoke_shi_kuanggu', sgs.QVariant((damage.from:distanceTo(damage.to) <= 1)))
            return false
        end
        local invoke = player:getTag('invoke_shi_kuanggu'):toBool()
        player:setTag('invoke_shi_kuanggu', sgs.QVariant(false))
        if not invoke then
            return false
        end
        local choices = {'kuanggu1'}
        if player:isWounded() then
            table.insert(choices, 'kuanggu2')
        end
        if player:getMark('LuaShiZhongao_success') > 0 then
            table.insert(choices, 'kunaggu3_behind_water')
        end
        table.insert(choices, 'cancel')
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
        if choice == 'cancel' then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), common.getVoiceIndex(player, self:objectName()))
        room:addPlayerMark(player, self:objectName() .. 'engine')
        if player:getMark(self:objectName() .. 'engine') > 0 then
            if choice == 'kuanggu1' then
                player:drawCards(1)
            elseif choice == 'kuanggu2' then
                rinsan.recover(player)
            elseif choice == 'kunaggu3_behind_water' then
                player:drawCards(1)
                rinsan.recover(player)
                if rinsan.canDiscard(player, player, 'he') then
                    if room:askForDiscard(player, self:objectName(), 1, 1, false, true, '@LuaKuanggu3Discard') then
                        room:addPlayerMark(player, 'more_slash_time_biu')
                    end
                end
            end
            room:removePlayerMark(player, self:objectName() .. 'engine')
        end
        return false
    end,
}

LuaShiKunfen = sgs.CreateTriggerSkill {
    name = 'LuaShiKunfen',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        room:broadcastSkillInvoke(self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:loseHp(player)
        player:drawCards(2, self:objectName())
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Finish)
    end,
}

ShiWeiyan:addSkill(LuaShiZhuangshi)
ShiWeiyan:addSkill(LuaShiYinzhan)
ShiWeiyan:addSkill(LuaShiZhongao)
ShiWeiyan:addRelateSkill('LuaShiKuanggu')
ShiWeiyan:addRelateSkill('LuaShiKunfen')

table.insert(hiddenSkills, LuaShiZhongaoStart)
table.insert(hiddenSkills, LuaShiKuanggu)
table.insert(hiddenSkills, LuaShiKunfen)
table.insert(hiddenSkills, LuaShiYinzhanFinish)
table.insert(hiddenSkills, LuaShizhongaoDying)
table.insert(hiddenSkills, LuaShiZhongaoKilled)

rinsan.addHiddenSkills(hiddenSkills)

package.loaded['extensions.MilitaryPowerPackage'].VOICE_FUNCS = VOICE_FUNCS
