-- 谋攻篇-知包
-- Created by DZDcyj at 2023/3/9
module('extensions.StrategicAttackPreviewPackage', package.seeall)
extension = sgs.Package('StrategicAttackPreviewPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

local function globalTrigger(self, target)
    return true
end

-- 谋曹操
ExMouCaocao = sgs.General(extension, 'ExMouCaocao$', 'wei', '4', true, true)

LuaMouJianxiong = sgs.CreateTriggerSkill {
    name = 'LuaMouJianxiong',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            local card = damage.card
            if card then
                local ids = sgs.IntList()
                if card:isVirtualCard() then
                    ids = card:getSubcards()
                else
                    ids:append(card:getEffectiveId())
                end
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                        return
                    end
                end
                player:obtainCard(card)
            end
            local x = 2 - player:getMark('@LuaZhishi')
            if x > 0 then
                player:drawCards(x, self:objectName())
            end
            if room:askForChoice(player, self:objectName(), 'RemoveLuaZhishiMark+cancel') ~= 'cancel' then
                player:loseMark('@LuaZhishi')
            end
        end
    end,
}

LuaMouJianxiongStart = sgs.CreateTriggerSkill {
    name = 'LuaMouJianxiongStart',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName('LuaMouJianxiong')) do
            if p:getMark('LuaMouJianxiongInvoked') == 0 then
                room:notifySkillInvoked(p, 'LuaMouJianxiong')
                room:broadcastSkillInvoke('LuaMouJianxiong')
                local choices = {0, 1, 2}
                local choice = room:askForChoice(p, 'LuaMouJianxiong', table.concat(choices, '+'))
                local num = tonumber(choice)
                if num and num > 0 then
                    p:gainMark('@LuaZhishi', num)
                end
                room:addPlayerMark(p, 'LuaMouJianxiongInvoked')
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaMouQingzhengCard = sgs.CreateSkillCard {
    name = 'LuaMouQingzheng',
    will_throw = true,
    target_fixed = false,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0) and not to_select:isKongcheng()
    end,
    feasible = function(self, targets)
        local cards = {}
        for _, id in sgs.qlist(self:getSubcards()) do
            table.insert(cards, sgs.Sanguosha:getCard(id))
        end
        if rinsan.checkMouQingzhengCards(sgs.Self, cards) then
            return #targets == 1
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local suits = {}
        for _, cd in sgs.qlist(target:getHandcards()) do
            local suit = cd:getSuitString()
            if not table.contains(suits, suit) then
                table.insert(suits, suit)
            end
        end
        room:showAllCards(target, source)
        local choice = room:askForChoice(source, self:objectName(), table.concat(suits, '+'))
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in sgs.qlist(target:getHandcards()) do
            local suit = cd:getSuitString()
            if suit == choice then
                dummy:addSubcard(cd)
            end
        end
        room:throwCard(dummy, target, source)
        room:clearAG(source)
        if dummy:subcardsLength() < self:subcardsLength() then
            rinsan.doDamage(room, source, target, 1)
            local x = source:getMark('@LuaZhishi')
            if x < 2 and source:hasSkill('LuaMouJianxiong') then
                if room:askForChoice(source, self:objectName(), 'GainLuaZhishiMark+cancel') ~= 'cancel' then
                    source:gainMark('@LuaZhishi')
                end
            end
        end
    end,
}

LuaMouQingzhengVS = sgs.CreateViewAsSkill {
    name = 'LuaMouQingzheng',
    n = 99999,
    view_filter = function(self, selected, to_select)
        return rinsan.filterMouQingzhengCards(sgs.Self, selected, to_select)
    end,
    view_as = function(self, cards)
        if not rinsan.checkMouQingzhengCards(sgs.Self, cards) then
            return nil
        end
        local vs_card = LuaMouQingzhengCard:clone()
        for _, cd in ipairs(cards) do
            vs_card:addSubcard(cd)
        end
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaMouQingzheng'
    end,
}

LuaMouQingzheng = sgs.CreateTriggerSkill {
    name = 'LuaMouQingzheng',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaMouQingzhengVS,
    on_trigger = function(self, event, player, data, room)
        local prompt = string.format('@LuaMouQingzheng:::%d', 3 - player:getMark('@LuaZhishi'))
        room:askForUseCard(player, '@@LuaMouQingzheng', prompt, -1, sgs.Card_MethodNone)
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaMouHujia = sgs.CreateTriggerSkill {
    name = 'LuaMouHujia$',
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:getMark(self:objectName() .. '_lun') > 0 then
            return false
        end
        local wei_generals = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getKingdom() == 'wei' then
                wei_generals:append(p)
            end
        end
        if wei_generals:isEmpty() then
            return false
        end
        local target =
            room:askForPlayerChosen(player, wei_generals, self:objectName(), 'LuaMouHujia-choose', true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            if damage.card and damage.card:isKindOf('Slash') then
                damage.from:removeQinggangTag(damage.card)
            end
            damage.to = target
            damage.transfer = true
            room:damage(damage)
            room:addPlayerMark(player, self:objectName() .. '_lun')
            return true
        end
        return false
    end,
}

ExMouCaocao:addSkill(LuaMouJianxiong)
SkillAnjiang:addSkill(LuaMouJianxiongStart)
ExMouCaocao:addSkill(LuaMouQingzheng)
ExMouCaocao:addSkill(LuaMouHujia)
