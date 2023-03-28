-- 谋攻篇-识包
-- Created by DZDcyj at 2023/2/19
module('extensions.StrategicAttackKnowledgePackage', package.seeall)
extension = sgs.Package('StrategicAttackKnowledgePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

local function globalTrigger(self, target)
    return true
end

-- 谋徐晃
ExMouXuhuang = sgs.General(extension, 'ExMouXuhuang', 'wei', '4', true, true)

LuaMouDuanliangCard = sgs.CreateSkillCard {
    name = 'LuaMouDuanliangCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    on_use = function(self, room, source, targets)
        local attacks = {'LuaMouDuanliangAttack1', 'LuaMouDuanliangAttack2'}
        local defenses = {'LuaMouDuanliangDefense1', 'LuaMouDuanliangDefense2'}
        local target = targets[1]
        room:broadcastSkillInvoke('LuaMouDuanliang', 1)
        local attack = room:askForChoice(source, self:objectName(), table.concat(attacks, '+'))
        local defense = room:askForChoice(target, self:objectName(), table.concat(defenses, '+'))
        local success = string.sub(attack, -1) ~= string.sub(defense, -1)
        local type = success and '#LuaMouDuanliangSuccess' or '#LuaMouDuanliangFailure'
        rinsan.sendLogMessage(room, '#choose', {
            ['from'] = source,
            ['arg'] = attack,
        })
        rinsan.sendLogMessage(room, '#choose', {
            ['from'] = target,
            ['arg'] = defense,
        })
        rinsan.sendLogMessage(room, type, {
            ['from'] = source,
            ['arg'] = 'LuaMouDuanliangMouyi',
        })
        if success then
            if attack == attacks[1] then
                room:broadcastSkillInvoke('LuaMouDuanliang', 2)
                if target:containsTrick('supply_shortage') then
                    local card_id = room:askForCardChosen(source, target, 'he', self:objectName(), false,
                        sgs.Card_MethodNone)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
                    room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
                else
                    local card_ids = room:getNCards(1)
                    local supply_shortage = sgs.Sanguosha:cloneCard('supply_shortage', sgs.Card_NoSuit, 0)
                    supply_shortage:setSkillName(self:objectName())
                    supply_shortage:addSubcard(card_ids:at(0))
                    room:useCard(sgs.CardUseStruct(supply_shortage, source, target))
                end
            else
                room:broadcastSkillInvoke('LuaMouDuanliang', 3)
                local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_NoSuit, 0)
                duel:setSkillName(self:objectName())
                room:useCard(sgs.CardUseStruct(duel, source, target))
            end
        else
            room:broadcastSkillInvoke('LuaMouDuanliang', 4)
        end
    end,
}

LuaMouDuanliang = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouDuanliang',
    view_as = function(self, cards)
        return LuaMouDuanliangCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMouDuanliangCard')
    end,
}

LuaMouShipo = sgs.CreateTriggerSkill {
    name = 'LuaMouShipo',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local choices = {}
        local victims = sgs.SPlayerList()
        local shortages = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getHp() < player:getHp() then
                victims:append(p)
            end
            if p:containsTrick('supply_shortage') then
                shortages:append(p)
            end
        end
        if not victims:isEmpty() then
            table.insert(choices, 'LuaMouShipoChoice1')
        end
        if not shortages:isEmpty() then
            table.insert(choices, 'LuaMouShipoChoice2')
        end
        table.insert(choices, 'cancel')
        if #choices > 1 then
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
            if choice ~= 'cancel' then
                rinsan.skill(self, room, player, true)
            end
            if choice == 'LuaMouShipoChoice1' then
                local victim = room:askForPlayerChosen(player, victims, self:objectName(), 'LuaMouShipo-choose', true,
                    true)
                if victim then
                    if not room:askForDiscard(victim, self:objectName(), 1, 1, true, true,
                        'LuaMouShipo-discard:' .. player:objectName()) then
                        player:drawCards(1, self:objectName())
                    end
                end
            elseif choice == 'LuaMouShipoChoice2' then
                for _, p in sgs.qlist(shortages) do
                    if not room:askForDiscard(p, self:objectName(), 1, 1, true, true,
                        'LuaMouShipo-discard:' .. player:objectName()) then
                        player:drawCards(1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Finish)
    end,
}

ExMouXuhuang:addSkill(LuaMouDuanliang)
ExMouXuhuang:addSkill(LuaMouShipo)

-- 谋马超
ExMouMachao = sgs.General(extension, 'ExMouMachao', 'shu', '4', true)

-- 判断谋弈是否成功
local function checkLuaMouTiejiMouyi(sourceChoice, targetChoice)
    return string.sub(sourceChoice, -1) ~= string.sub(targetChoice, -1)
end

LuaMouTieji = sgs.CreateTriggerSkill {
    name = 'LuaMouTieji',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TargetSpecifying, sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (not use.card) or (not use.card:isKindOf('Slash')) then
            return false
        end
        if event == sgs.TargetSpecifying then
            local index = 1
            local indexes = sgs.IntList()
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then
                    break
                end
                local data2 = sgs.QVariant()
                data2:setValue(p)
                if room:askForSkillInvoke(player, self:objectName(), data2) then
                    indexes:append(index)
                    room:addPlayerMark(p, 'LuaMouTieji')
                    room:addPlayerMark(p, '@skill_invalidity')
                    room:doAnimate(1, player:objectName(), p:objectName())
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    local sourceChoice = room:askForChoice(player, self:objectName(),
                        'LuaMouTiejiAttack1+LuaMouTiejiAttack2', data2)
                    local targetChoice = room:askForChoice(p, self:objectName(),
                        'LuaMouTiejiDefense1+LuaMouTiejiDefense2')
                    rinsan.sendLogMessage(room, '#choose', {
                        ['from'] = player,
                        ['arg'] = sourceChoice,
                    })
                    rinsan.sendLogMessage(room, '#choose', {
                        ['from'] = p,
                        ['arg'] = targetChoice,
                    })
                    local success = checkLuaMouTiejiMouyi(sourceChoice, targetChoice)
                    local type = success and '#LuaMouTiejiSuccess' or '#LuaMouTiejiFailure'
                    rinsan.sendLogMessage(room, type, {
                        ['from'] = player,
                        ['arg'] = 'LuaMouTiejiMouyi',
                    })
                    if success then
                        if sourceChoice == 'LuaMouTiejiAttack1' then
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            if not p:isNude() then
                                local card_id = room:askForCardChosen(player, p, 'he', self:objectName(), false,
                                    sgs.Card_MethodNone)
                                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
                                    player:objectName())
                                room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                            end
                        else
                            room:broadcastSkillInvoke(self:objectName(), 3)
                            player:drawCards(2, self:objectName())
                        end
                    else
                        room:broadcastSkillInvoke(self:objectName(), 4)
                    end
                    if p:isAlive() then
                        rinsan.sendLogMessage(room, '#NoJink', {
                            ['from'] = p,
                        })
                    end
                end
                index = index + 1
            end
            if indexes:length() == 0 then
                return false
            end
            room:setPlayerFlag(player, 'LuaMouTiejiInvoked')
            local indexes_data = sgs.QVariant()
            indexes_data:setValue(indexes)
            player:setTag('LuaMouTiejiTargets', indexes_data)
            return false
        end
        if not player:hasFlag('LuaMouTiejiInvoked') then
            return false
        end
        local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
        local indexes = player:getTag('LuaMouTiejiTargets'):toIntList()
        for _, index in sgs.qlist(indexes) do
            jink_table[index] = 0
        end
        local jink_data = sgs.QVariant()
        jink_data:setValue(Table2IntList(jink_table))
        player:setTag('Jink_' .. use.card:toString(), jink_data)
        player:removeTag('LuaMouTiejiTargets')
        room:setPlayerFlag(player, '-LuaMouTiejiInvoked')
        return false
    end,
}

LuaMouTiejiClear = sgs.CreateTriggerSkill {
    name = 'LuaMouTiejiClear',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                local x = p:getMark('LuaMouTieji')
                room:removePlayerMark(p, 'LuaMouTieji', x)
                room:removePlayerMark(p, '@skill_invalidity', x)
            end
        end
    end,
    can_trigger = globalTrigger,
}

ExMouMachao:addSkill('mashu')
ExMouMachao:addSkill(LuaMouTieji)
SkillAnjiang:addSkill(LuaMouTiejiClear)
