-- 谋攻篇-能包
-- Created by DZDcyj at 2023/2/19
module('extensions.StrategicAttackAbilityPackage', package.seeall)
extension = sgs.Package('StrategicAttackAbilityPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function globalTrigger(self, target)
    return true
end

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 谋华雄
ExMouHuaxiong = sgs.General(extension, 'ExMouHuaxiong', 'qun', '4', true, true, false, 3)

LuaMouYaowu = sgs.CreateTriggerSkill {
    name = 'LuaMouYaowu',
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') then
            if damage.card:isRed() then
                if damage.from and damage.from:isAlive() then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(damage.to, self:objectName())
                    local choices = {}
                    if damage.from:isWounded() then
                        table.insert(choices, 'recover')
                    end
                    table.insert(choices, 'draw')
                    room:doAnimate(rinsan.ANIMATE_INDICATE, damage.to:objectName(), damage.from:objectName())
                    local choice = room:askForChoice(damage.from, 'yaowu', table.concat(choices, '+'))
                    if choice == 'recover' then
                        rinsan.recover(damage.from, 1)
                    else
                        damage.from:drawCards(1, self:objectName())
                    end
                end
            else
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(damage.to, self:objectName())
                damage.to:drawCards(1, self:objectName())
            end
        end
        return false
    end,
}

LuaMouYangweiCard = sgs.CreateSkillCard {
    name = 'LuaMouYangwei',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        source:drawCards(2, self:objectName())
        source:gainMark('@LuaWei')
        room:setPlayerFlag(source, 'LuaMouYangweiInvoked')
        room:addPlayerMark(source, 'LuaMouYangweiDisabled')
    end,
}

LuaMouYangweiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouYangwei',
    view_as = function(self)
        return LuaMouYangweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaMouYangwei') and player:getMark('LuaMouYangweiDisabled') == 0
    end,
}

LuaMouYangwei = sgs.CreateTriggerSkill {
    name = 'LuaMouYangwei',
    events = {sgs.EventPhaseEnd},
    view_as_skill = LuaMouYangweiVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:hasFlag('LuaMouYangweiInvoked') then
                room:setPlayerFlag(player, '-LuaMouYangweiInvoked')
            else
                room:setPlayerMark(player, 'LuaMouYangweiDisabled', 0)
            end
        end
        room:setPlayerMark(player, '@LuaWei', 0)
        return false
    end,
}

LuaMouYangweiTargetMod = sgs.CreateTargetModSkill {
    name = 'LuaMouYangweiTargetMod',
    pattern = 'Slash',
    residue_func = function(self, player)
        if player:getMark('@LuaWei') > 0 then
            return 1
        end
        return 0
    end,
    distance_limit_func = function(self, from)
        if from:getMark('@LuaWei') > 0 then
            return 1000
        end
        return 0
    end,
}

LuaMouyangweiBuff = sgs.CreateTriggerSkill {
    name = 'LuaMouyangweiBuff',
    events = {sgs.TargetSpecified},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from and use.from:getMark('@LuaWei') > 0 and use.card and use.card:isKindOf('Slash') then
            for _, p in sgs.qlist(use.to) do
                rinsan.addQinggangTag(p, use.card)
            end
        end
    end,
    can_trigger = globalTrigger,
}

ExMouHuaxiong:addSkill(LuaMouYaowu)
ExMouHuaxiong:addSkill(LuaMouYangwei)
table.insert(hiddenSkills, LuaMouYangweiTargetMod)
table.insert(hiddenSkills, LuaMouyangweiBuff)

-- 谋孙尚香
ExMouSunshangxiang = sgs.General(extension, 'ExMouSunshangxiang', 'shu', '4', false, true)

LuaMouLiangzhuCard = sgs.CreateSkillCard {
    name = 'LuaMouLiangzhu',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and to_select:hasEquip()
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local zhuTarget
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:getMark('@LuaMouLiangzhu') > 0 then
                zhuTarget = p
                break
            end
        end
        local target = targets[1]
        if target:hasEquip() then
            local card_id = room:askForCardChosen(source, target, 'e', self:objectName(), false, sgs.Card_MethodDiscard)
            source:addToPile('LuaMouLiangzhuPile', card_id)
        end
        local choices = {}
        if zhuTarget:isWounded() then
            table.insert(choices, 'LuaMouLiangzhuChoice1')
        end
        table.insert(choices, 'LuaMouLiangzhuChoice2')
        local choice = room:askForChoice(zhuTarget, self:objectName(), table.concat(choices, '+'))
        if choice == 'LuaMouLiangzhuChoice1' then
            rinsan.recover(zhuTarget)
        else
            zhuTarget:drawCards(2, self:objectName())
        end
    end,
}

LuaMouLiangzhu = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaMouLiangzhu',
    view_as = function(self, cards)
        return LuaMouLiangzhuCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getKingdom() ~= 'shu' then
            return false
        end
        return not player:hasUsed('#LuaMouLiangzhu')
    end,
}

LuaMouJieyinAwakeHelper = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyinAwakeHelper',
    events = {sgs.MarkChanged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local jieyinMark = 'LuaMouJieyin'
        local mousunshangxiang = room:findPlayerBySkillName(jieyinMark)
        if not mousunshangxiang or mousunshangxiang:getMark(jieyinMark) > 0 then
            return false
        end
        local mark = data:toMark()
        if mark.name ~= '@LuaMouLiangzhu' then
            return false
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark('@LuaMouLiangzhu') > 0 then
                return false
            end
        end
        rinsan.sendLogMessage(room, '#LuaMouJieyinWake', {
            ['from'] = mousunshangxiang,
            ['arg'] = 'LuaMouJieyin',
            ['arg2'] = '@LuaMouLiangzhu',
        })
        room:broadcastSkillInvoke('LuaMouJieyin', 2)
        if room:changeMaxHpForAwakenSkill(mousunshangxiang, 0) then
            room:addPlayerMark(mousunshangxiang, jieyinMark)
            rinsan.recover(mousunshangxiang)
            local to_obtain = sgs.IntList()
            local card_table = {}
            for _, id in sgs.qlist(mousunshangxiang:getPile('LuaMouLiangzhuPile')) do
                to_obtain:append(id)
                table.insert(card_table, id)
            end
            if #card_table > 0 then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                dummy:addSubcards(to_obtain)
                rinsan.sendLogMessage(room, '$LuaMouJieyinGot', {
                    ['from'] = mousunshangxiang,
                    ['arg'] = 'LuaMouLiangzhuPile',
                    ['card_str'] = table.concat(card_table, '+'),
                })
                mousunshangxiang:obtainCard(dummy)
            end
            room:setPlayerProperty(mousunshangxiang, 'kingdom', sgs.QVariant('wu'))
            room:loseMaxHp(mousunshangxiang)
            room:acquireSkill(mousunshangxiang, 'LuaMouXiaoji')
        end
    end,
    can_trigger = globalTrigger,
}

LuaMouJieyinStart = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyinStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, _player, data, room)
        for _, player in sgs.qlist(room:findPlayersBySkillName('LuaMouJieyin')) do
            if player:getMark(self:objectName()) == 0 then
                local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), 'LuaMouJieyin',
                    'LuaMouJieyin-invoke', false, true)
                if to then
                    room:broadcastSkillInvoke('LuaMouJieyin', 1)
                    room:notifySkillInvoked(player, 'LuaMouJieyin')
                    to:gainMark('@LuaMouLiangzhu')
                end
                room:addPlayerMark(player, self:objectName())
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaMouJieyin = sgs.CreateTriggerSkill {
    name = 'LuaMouJieyin',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        local zhuTarget
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getMark('@LuaMouLiangzhu') > 0 then
                zhuTarget = p
                break
            end
        end
        if zhuTarget then
            local choices = {}
            if not zhuTarget:isKongcheng() then
                table.insert(choices, 'LuaMouJieyinChoice1')
            end
            table.insert(choices, 'LuaMouJieyinChoice2')
            -- For AI
            local aiData = sgs.QVariant()
            aiData:setValue(zhuTarget)
            player:setTag('LuaMouLiangZhuTarget', aiData)
            room:broadcastSkillInvoke('LuaMouJieyin', 1)
            local choice = room:askForChoice(zhuTarget, self:objectName(), table.concat(choices, '+'))
            player:removeTag('LuaMouLiangZhuTarget')
            if choice == 'LuaMouJieyinChoice1' then
                if zhuTarget:getHandcardNum() < 2 then
                    room:obtainCard(player, zhuTarget:getHandcards():first(), false)
                    rinsan.increaseShield(zhuTarget, 1)
                    return false
                end
                local card = room:askForExchange(zhuTarget, self:objectName(), 2, 2, true,
                    'LuaMouJieyin-give:' .. player:objectName(), false)
                if card then
                    room:obtainCard(player, card, false)
                    rinsan.increaseShield(zhuTarget, 1)
                end
            else
                repeat
                    if zhuTarget:getMark('LuaMouLiangZhuTargeted') == 0 then
                        local markChoice = room:askForChoice(player, self:objectName(),
                            'LuaMouJieyinMove+LuaMouJieyinRemove')
                        if markChoice == 'LuaMouJieyinRemove' then
                            break
                        end
                        local available_targets = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:objectName() ~= player:objectName() and p:objectName() ~= zhuTarget:objectName() then
                                if p:getMark('LuaMouLiangZhuTargeted') <= 1 then
                                    available_targets:append(p)
                                end
                            end
                        end
                        if available_targets:length() > 0 then
                            local target = room:askForPlayerChosen(player, available_targets, self:objectName(),
                                'LuaMouJieyinMoveTo', false, true)
                            if target then
                                target:gainMark('@LuaMouLiangzhu')
                            end
                        end
                    end
                until true
                zhuTarget:loseMark('@LuaMouLiangzhu')
                room:addPlayerMark(zhuTarget, 'LuaMouLiangZhuTargeted')
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Play)
    end,
}

LuaMouXiaoji = sgs.CreateTriggerSkill {
    name = 'LuaMouXiaoji',
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() then
            if move.from_places:contains(sgs.Player_PlaceEquip) then
                for i, _ in sgs.qlist(move.card_ids) do
                    if not player:isAlive() then
                        return false
                    end
                    if move.from_places:at(i) == sgs.Player_PlaceEquip then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:broadcastSkillInvoke(self:objectName())
                            player:drawCards(2, self:objectName())
                            local available_targets = sgs.SPlayerList()
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                if rinsan.canDiscard(player, p, 'ej') then
                                    available_targets:append(p)
                                end
                            end
                            if available_targets:length() > 0 then
                                local target = room:askForPlayerChosen(player, available_targets, self:objectName(),
                                    'LuaMouXiaojiChoose', true, true)
                                if target then
                                    local card_id = room:askForCardChosen(player, target, 'ej', self:objectName(),
                                        false, sgs.Card_MethodDiscard)
                                    room:throwCard(card_id, target, player)
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getKingdom() == 'wu'
    end,
}

ExMouSunshangxiang:addSkill(LuaMouLiangzhu)
ExMouSunshangxiang:addSkill(LuaMouJieyin)
ExMouSunshangxiang:addRelateSkill('LuaMouXiaoji')
table.insert(hiddenSkills, LuaMouJieyinAwakeHelper)
table.insert(hiddenSkills, LuaMouJieyinStart)
table.insert(hiddenSkills, LuaMouXiaoji)

rinsan.addHiddenSkills(hiddenSkills)
