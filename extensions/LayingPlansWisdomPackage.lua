-- 始计篇-智包
-- Created by DZDcyj at 2023/2/27
module('extensions.LayingPlansWisdomPackage', package.seeall)
extension = sgs.Package('LayingPlansWisdomPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量
SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

local function globalTrigger(self, target)
    return true
end

local function targetTrigger(self, target)
    return target
end

-- 孙邵
ExSunshao = sgs.General(extension, 'ExSunshao', 'wu', '3', true, true)

local function getDingyiCount(target, value)
    value = value or 1
    for _ = 1, target:getMark('@LuaFubi'), 1 do
        value = value * 2
    end
    return value
end

LuaDingyi = sgs.CreateTriggerSkill {
    name = 'LuaDingyi',
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        local choices = {}
        for i = 1, 4, 1 do
            local mark = string.format('%s%d', self:objectName(), i)
            table.insert(choices, mark)
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
        local pos = rinsan.getPos(choices, choice)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, '@LuaDingyi', pos)
        end
        return false
    end,
}

LuaDingyiBuff = sgs.CreateTriggerSkill {
    name = 'LuaDingyiBuff',
    events = {sgs.DrawNCards, sgs.QuitDying, sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.QuitDying then
            if player:getMark('@LuaDingyi') ~= 4 then
                return false
            end
            if data:toDying().who:objectName() == player:objectName() then
                room:broadcastSkillInvoke('LuaDingyi')
                rinsan.sendLogMessage(room, '#LuaDingyi4', {
                    ['from'] = player,
                    ['arg'] = 'LuaDingyi',
                    ['arg2'] = getDingyiCount(player),
                })
                rinsan.recover(room, player, getDingyiCount(player))
            end
        elseif event == sgs.DrawNCards then
            if player:getMark('@LuaDingyi') == 1 then
                local count = data:toInt() + getDingyiCount(player)
                room:broadcastSkillInvoke('LuaDingyi')
                rinsan.sendLogMessage(room, '#LuaDingyi1', {
                    ['from'] = player,
                    ['arg'] = 'LuaDingyi',
                    ['arg2'] = getDingyiCount(player),
                })
                data:setValue(count)
            end
        else
            local death = data:toDeath()
            local splayer = death.who
            if splayer:objectName() ~= player:objectName() then
                return false
            end
            if not player:hasSkill('LuaDingyi') then
                return false
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, '@LuaDingyi', 0)
                room:setPlayerMark(p, '@LuaFubi', 0)
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaDingyiAttackRange = sgs.CreateAttackRangeSkill {
    name = 'LuaDingyiAttackRange',
    extra_func = function(self, from, card)
        if from:getMark('@LuaDingyi') == 3 then
            return getDingyiCount(from)
        else
            return 0
        end
    end,
}

LuaDingyiMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaDingyiMaxCards',
    extra_func = function(self, target)
        if target:getMark('@LuaDingyi') == 2 then
            return getDingyiCount(target, 2)
        end
        return 0
    end,
}

LuaZuici = sgs.CreateTriggerSkill {
    name = 'LuaZuici',
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:getMark('@LuaDingyi') > 0 then
            local data2 = sgs.QVariant()
            data2:setValue(damage.from)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                room:broadcastSkillInvoke(self:objectName())
                room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.from:objectName())
                room:setPlayerMark(damage.from, '@LuaDingyi', 0)
                local cardName = room:askForChoice(player, self:objectName(), 'ex_nihilo+dismantlement+nullification')
                local obtain = rinsan.obtainCardFromPile(function(cd)
                    return cd:objectName() == cardName
                end, room:getDrawPile())
                if obtain then
                    damage.from:obtainCard(obtain, true)
                end
            end
        end
        return false
    end,
}

LuaFubiCard = sgs.CreateSkillCard {
    name = 'LuaFubi',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:getMark('@LuaDingyi') > 0
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. '_lun')
        source:setTag('InvokeFubiTurnCount', sgs.QVariant(room:getTag('TurnLengthCount'):toInt()))
        local target = targets[1]
        local len = self:subcardsLength()
        if len > 0 then
            room:addPlayerMark(target, '@' .. self:objectName())
            return
        end
        local choices = {}
        local originChoices = {}
        for i = 1, 4, 1 do
            local mark = string.format('%s%d', 'LuaDingyi', i)
            table.insert(choices, mark)
            table.insert(originChoices, mark)
        end
        table.removeOne(choices, string.format('%s%d', 'LuaDingyi', target:getMark('@LuaDingyi')))
        local choice = room:askForChoice(source, self:objectName(), table.concat(choices, '+'))
        local pos = rinsan.getPos(originChoices, choice)
        room:setPlayerMark(target, '@LuaDingyi', pos)
    end,
}

LuaFubiVS = sgs.CreateViewAsSkill {
    name = 'LuaFubi',
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected == 0
    end,
    view_as = function(self, cards)
        local vs_card = LuaFubiCard:clone()
        for _, cd in ipairs(cards) do
            vs_card:addSubcard(cd)
        end
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return player:getMark(self:objectName() .. '_lun') == 0
    end,
}

LuaFubi = sgs.CreateTriggerSkill {
    name = 'LuaFubi',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaFubiVS,
    on_trigger = function(self, event, player, data, room)
        local curr = player:getTag('InvokeFubiTurnCount')
        if curr then
            if curr:toInt() == room:getTag('TurnLengthCount'):toInt() then
                return false
            end
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, '@' .. self:objectName(), 0)
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_RoundStart)
    end,
}

ExSunshao:addSkill(LuaDingyi)
ExSunshao:addSkill(LuaZuici)
ExSunshao:addSkill(LuaFubi)
SkillAnjiang:addSkill(LuaDingyiBuff)
SkillAnjiang:addSkill(LuaDingyiMaxCards)
SkillAnjiang:addSkill(LuaDingyiAttackRange)

-- 杜预
ExDuyu = sgs.General(extension, 'ExDuyu', 'qun', '4', true, true)

LuaWuku = sgs.CreateTriggerSkill {
    name = 'LuaWuku',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('EquipCard') then
            for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if sp:getMark('@wuku') < 3 then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(sp, self:objectName())
                    sp:gainMark('@wuku')
                end
            end
        end
    end,
}

LuaSanchen = sgs.CreateTriggerSkill {
    name = 'LuaSanchen',
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        rinsan.sendLogMessage(room, '#LuaSanchen', {
            ['from'] = player,
            ['arg'] = player:getMark('@wuku'),
            ['arg2'] = self:objectName(),
        })
        if room:changeMaxHpForAwakenSkill(player, 1) then
            room:broadcastSkillInvoke(self:objectName())
            rinsan.recover(room, player, 1, player)
            room:handleAcquireDetachSkills(player, 'LuaMiewu')
            room:addPlayerMark(player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        if rinsan.RIGHT(self, target) then
            return rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Finish) and target:getMark('@wuku') > 2
        end
        return false
    end,
}

LuaMiewuCard = sgs.CreateSkillCard {
    name = 'LuaMiewuCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return rinsan.guhuoCardFilter(self, targets, to_select, 'LuaMiewu')
    end,
    feasible = function(self, targets)
        return rinsan.selfFeasible(self, targets, 'LuaMiewu')
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidate(self, card_use, 'LuaMiewu', 'miewu', 'Miewu')
        if use_card then
            room:addPlayerMark(source, 'LuaMiewu')
            source:loseMark('@wuku')
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidateInResponse(self, source, 'LuaMiewu', 'miewu', 'Miewu')
        if use_card then
            room:addPlayerMark(source, 'LuaMiewu')
            source:loseMark('@wuku')
        end
        return use_card
    end,
}

LuaMiewuVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaMiewu',
    filter_pattern = '.|.|.|.',
    response_or_use = true,
    enabled_at_response = function(self, player, pattern)
        if player:isNude() or player:getMark('@wuku') <= 0 or player:getMark('LuaMiewu') > 0 then
            return false
        end
        return rinsan.guhuoVSSkillEnabledAtResponse(self, player, pattern)
    end,
    enabled_at_play = function(self, player)
        if player:isNude() or player:getMark('LuaMiewu') > 0 or player:getMark('@wuku') <= 0 then
            return false
        end
        return rinsan.guhuoVSSkillEnabledAtPlay(self, player)
    end,
    enabled_at_nullification = function(self, player)
        return not player:isNude() and player:getMark('LuaMiewu') == 0 and player:getMark('@wuku') > 0
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = LuaMiewuCard:clone()
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            card:setUserString(pattern)
            card:addSubcard(cards)
            local available = false
            for _, name in ipairs(pattern:split('+')) do
                local c = sgs.Sanguosha:cloneCard(name, cards:getSuit(), cards:getNumber())
                c:deleteLater()
                if not sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                    available = true
                    break
                end
            end
            if not available then
                return nil
            end
            return card
        end
        local c = sgs.Self:getTag('LuaMiewu'):toCard()
        if c then
            local card = LuaMiewuCard:clone()
            card:setUserString(c:objectName())
            card:addSubcard(cards)
            if sgs.Self:isCardLimited(card, c:getHandlingMethod()) then
                return nil
            end
            return card
        else
            return nil
        end
    end,
}

LuaMiewu = sgs.CreateTriggerSkill {
    name = 'LuaMiewu',
    events = {sgs.TurnStart, sgs.CardUsed, sgs.CardResponded},
    view_as_skill = LuaMiewuVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill('LuaMiewu') then
                    room:setPlayerMark(p, 'LuaMiewu', 0)
                end
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:getSkillName() == self:objectName() and player:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(1, self:objectName())
            end
        end
    end,
}
LuaMiewu:setGuhuoDialog('lrd')

SkillAnjiang:addSkill(LuaMiewu)
ExDuyu:addSkill(LuaWuku)
ExDuyu:addSkill(LuaSanchen)
ExDuyu:addRelateSkill('LuaMiewu')

-- 王粲
ExWangcan = sgs.General(extension, 'ExWangcan', 'wei', '3', true)

LuaQiaiCard = sgs.CreateSkillCard {
    name = 'LuaQiaiCard',
    target_fixed = false,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        target:obtainCard(card, false)
        room:broadcastSkillInvoke('LuaQiai')
        local choices = 'letdraw2'
        if source:isWounded() then
            choices = choices .. '+letrecover'
        end
        local data = sgs.QVariant()
        data:setValue(source)
        local choice = room:askForChoice(target, 'LuaQiai', choices, data)
        if choice == 'letdraw2' then
            source:drawCards(2, 'LuaQiai')
        else
            rinsan.recover(room, source, 1, target)
        end
    end,
}

LuaQiai = sgs.CreateViewAsSkill {
    name = 'LuaQiai',
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isKindOf('BasicCard')
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local vs_card = LuaQiaiCard:clone()
            vs_card:addSubcard(cards[1])
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaQiaiCard')
    end,
}

LuaShanxi = sgs.CreateTriggerSkill {
    name = 'LuaShanxi',
    events = {sgs.EventPhaseStart, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, self:objectName() .. player:objectName(), 0)
                end
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    'LuaShanxi-choose', true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(target, self:objectName() .. player:objectName())
                end
            end
        elseif event == sgs.HpRecover then
            local splayers = room:findPlayersBySkillName(self:objectName())
            for _, sp in sgs.qlist(splayers) do
                if player:getMark(self:objectName() .. sp:objectName()) > 0 then
                    if player:getHp() <= 0 then
                        return false
                    end
                    local chooseLoseHp = true
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(sp, self:objectName())
                    if player:getCardCount(true) >= 2 then
                        local card = room:askForExchange(player, self:objectName(), 2, 2, true,
                            'LuaShanxi-give:' .. sp:objectName(), true)
                        if card then
                            chooseLoseHp = false
                            room:obtainCard(sp, card, false)
                        end
                    end
                    if chooseLoseHp then
                        room:loseHp(player)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = targetTrigger,
}

ExWangcan:addSkill(LuaQiai)
ExWangcan:addSkill(LuaShanxi)

-- 神荀彧
ExShenXunyu = sgs.General(extension, 'ExShenXunyu', 'god', '3', true, true)

-- 天佐，只处理【奇正相生】无效
LuaTianzuo = sgs.CreateTriggerSkill {
    name = 'LuaTianzuo',
    events = {sgs.CardEffected},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        if effect.card:isKindOf('IndirectCombination') then
            room:broadcastSkillInvoke(self:objectName())
            rinsan.sendLogMessage(room, '#LuaSkillInvalidateCard', {
                ['from'] = player,
                ['arg'] = effect.card:objectName(),
                ['arg2'] = self:objectName(),
            })
            return true
        end
        return false
    end,
}

-- 天佐辅助，如果启用了扩展卡牌包，就放一句语音
LuaTianzuoStart = sgs.CreateTriggerSkill {
    name = 'LuaTianzuoStart',
    events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local invoked = room:getTag('LuaTianzuoStartInvoked') and room:getTag('LuaTianzuoStartInvoked'):toBool()
        if invoked then
            return false
        end
        local luapkg = sgs.GetConfig('LuaPackages', '')
        if string.find(luapkg, 'ExpansionCardPackage') then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill('LuaTianzuo') then
                    room:sendCompulsoryTriggerLog(p, 'LuaTianzuo')
                    room:broadcastSkillInvoke('LuaTianzuo')
                    if rinsan.isPackageBanned('ExpansionCardPackage') then
                        rinsan.initIndirectCombination(room)
                    end
                    room:setTag('LuaTianzuoStartInvoked', sgs.QVariant(true))
                    break
                end
            end
        end
        return false
    end,
    can_trigger = globalTrigger,
}

LuaLingce = sgs.CreateTriggerSkill {
    name = 'LuaLingce',
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local card = data:toCardUse().card
        if card:isKindOf('TrickCard') and not card:isVirtualCard() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if rinsan.playerCanInvokeLingce(p, card) then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    p:drawCards(1, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
        end
    end,
    can_trigger = targetTrigger,
}

LuaDinghan = sgs.CreateTriggerSkill {
    name = 'LuaDinghan',
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local dinghan_cards = rinsan.getDinghanCardsTable(player)
        if not use.card:isKindOf('TrickCard') or table.contains(dinghan_cards, use.card:objectName()) then
            return false
        end
        if use.to:contains(player) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local to_list = use.to
            to_list:removeOne(player)
            use.to = to_list
            data:setValue(use)
            local msgType = '$CancelTargetNoUser'
            local params = {
                ['to'] = player,
                ['arg'] = use.card:objectName(),
            }
            if use.from then
                params['from'] = use.from
                msgType = '$CancelTarget'
            end
            rinsan.sendLogMessage(room, msgType, params)
            table.insert(dinghan_cards, use.card:objectName())
            rinsan.sendLogMessage(room, '#LuaDinghanAdd', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['arg2'] = use.card:objectName(),
            })
            rinsan.setDinghanCardsTable(player, dinghan_cards)
        end
    end,
}

LuaDinghanChange = sgs.CreateTriggerSkill {
    name = 'LuaDinghanChange',
    events = {sgs.EventPhaseStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local dinghan_cards = rinsan.getDinghanCardsTable(player)
        local add_available = {}
        for _, cd in ipairs(rinsan.ALL_TRICKS) do
            if not table.contains(dinghan_cards, cd) then
                table.insert(add_available, cd)
            end
        end
        local remove_available = dinghan_cards
        local choices = {}
        if #add_available > 0 then
            table.insert(choices, 'LuaDinghanAdd')
        end
        if #remove_available > 0 then
            table.insert(choices, 'LuaDinghanRemove')
        end
        if #choices == 0 then
            return false
        end
        if room:askForSkillInvoke(player, 'LuaDinghan', data) then
            room:broadcastSkillInvoke('LuaDinghan')
            local choice = room:askForChoice(player, 'LuaDinghan', table.concat(choices, '+'))
            local card_choice
            if choice == 'LuaDinghanAdd' then
                card_choice = room:askForChoice(player, 'LuaDinghanAdd', table.concat(add_available, '+'))
                table.insert(dinghan_cards, card_choice)
            else
                card_choice = room:askForChoice(player, 'LuaDinghanRemove', table.concat(remove_available, '+'))
                table.removeOne(dinghan_cards, card_choice)
            end
            rinsan.sendLogMessage(room, '#' .. choice, {
                ['from'] = player,
                ['arg'] = 'LuaDinghan',
                ['arg2'] = card_choice,
            })
            rinsan.setDinghanCardsTable(player, dinghan_cards)
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_RoundStart, 'LuaDinghan')
    end,
}

ExShenXunyu:addSkill(LuaTianzuo)
SkillAnjiang:addSkill(LuaTianzuoStart)
ExShenXunyu:addSkill(LuaLingce)
ExShenXunyu:addSkill(LuaDinghan)
SkillAnjiang:addSkill(LuaDinghanChange)

-- 神郭嘉
ExShenGuojia = sgs.General(extension, 'ExShenGuojia', 'god', '3', true)

LuaHuishiCard = sgs.CreateSkillCard {
    name = 'LuaHuishiCard',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local suits = {}
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
        room:broadcastSkillInvoke('LuaHuishi')
        room:setTag('LuaFakeMove', sgs.QVariant(true))
        while source:getMaxHp() < 10 do
            local pattern = '.'
            if #suits > 0 then
                pattern = table.concat(suits, ',')
            end
            -- 此处动态判断动画效果
            -- good 代表命中 pattern 时为好（打勾）或差（打叉）
            -- 当 suits 没有内容时，pattern 接纳所有，因此需要判断第一次，故以 #suits 来简化代码
            -- pattern 由 table 元素内容以逗号分隔产生
            local judge = rinsan.createJudgeStruct({
                ['play_animation'] = true,
                ['who'] = source,
                ['reason'] = 'LuaHuishi',
                ['good'] = (#suits == 0),
                ['pattern'] = '.|' .. pattern .. '|.',
            })
            room:judge(judge)
            local card = judge.card
            dummy:addSubcard(card)
            if table.contains(suits, string.lower(card:getSuitString())) then
                break
            else
                table.insert(suits, string.lower(card:getSuitString()))
                rinsan.addPlayerMaxHp(source, 1)
            end
            if source:getMaxHp() < 10 and not room:askForSkillInvoke(source, 'LuaHuishi') then
                break
            end
        end
        room:removeTag('LuaFakeMove')
        local others = room:getOtherPlayers(source)
        local target = room:askForPlayerChosen(source, others, self:objectName(), 'LuaHuishi-choose', true)
        if not target then
            target = source
        end
        target:obtainCard(dummy)
        local isMaxCard = true
        for _, p in sgs.qlist(room:getOtherPlayers(target)) do
            if p:getHandcardNum() > target:getHandcardNum() then
                isMaxCard = false
                break
            end
        end
        if isMaxCard then
            room:loseMaxHp(source)
        end
    end,
}

LuaHuishi = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaHuishi',
    view_as = function(self)
        return LuaHuishiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed('#LuaHuishiCard')) and player:getMaxHp() < 10
    end,
}

LuaTianyi = sgs.CreateTriggerSkill {
    name = 'LuaTianyi',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        rinsan.sendLogMessage(room, '#LuaTianyi', {
            ['from'] = player,
            ['arg'] = self:objectName(),
        })
        if room:changeMaxHpForAwakenSkill(player, 2) then
            rinsan.recover(room, player)
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName())
            local target =
                room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 'LuaTianyi-choose')
            if target then
                room:acquireSkill(target, 'LuaZuoxing')
            end
        end
    end,
    can_trigger = function(self, target)
        if target:getMark('LuaTianyiDamaged') == 0 then
            return false
        end
        for _, p in sgs.qlist(target:getSiblings()) do
            if p:getMark('LuaTianyiDamaged') == 0 then
                return false
            end
        end
        return rinsan.RIGHT(self, target) and rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Start)
    end,
}

LuaTianyiDamaged = sgs.CreateTriggerSkill {
    name = 'LuaTianyiDamaged',
    events = {sgs.Damaged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        local damage = data:toDamage()
        if damage.from then
            room:addPlayerMark(player, string.format('LuaDamagedBy%s', damage.from:objectName()))
        end
    end,
    can_trigger = targetTrigger,
}

LuaLimitHuishiCard = sgs.CreateSkillCard {
    name = 'LuaLimitHuishiCard',
    target_fixed = false,
    filter = function(self, selected, to_select)
        return #selected == 0
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        source:loseMark('@LuaLimitHuishi')
        target:drawCards(4, 'LuaLimitHuishi')
        room:broadcastSkillInvoke('LuaLimitHuishi')
        room:loseMaxHp(source, 2)
    end,
}

LuaLimitHuishiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaLimitHuishi',
    view_as = function(self, cards)
        return LuaLimitHuishiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaLimitHuishi') >= 1
    end,
}

LuaLimitHuishi = sgs.CreateTriggerSkill {
    name = 'LuaLimitHuishi',
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaLimitHuishi',
    view_as_skill = LuaLimitHuishiVS,
    on_trigger = function()
    end,
}

LuaZuoxingCard = sgs.CreateSkillCard {
    name = 'LuaZuoxingCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return rinsan.guhuoCardFilter(self, targets, to_select, 'LuaZuoxing')
    end,
    feasible = function(self, targets)
        return rinsan.selfFeasible(self, targets, 'LuaZuoxing')
    end,
    on_validate = function(self, card_use)
        local source = card_use.from
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidate(self, card_use, 'LuaZuoxing', 'zuoxing', 'Zuoxing')
        if use_card then
            local splayer
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if rinsan.availableShenGuojiaExists(p) then
                    splayer = p
                    break
                end
            end
            if splayer then
                room:loseMaxHp(splayer)
            end
            room:setPlayerFlag(source, 'LuaZuoxing')
        end
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local use_card = rinsan.guhuoCardOnValidateInResponse(self, source, 'LuaZuoxing', 'zuoxing', 'Zuoxing')
        if use_card then
            local splayer
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if rinsan.availableShenGuojiaExists(p) then
                    splayer = p
                    break
                end
            end
            if splayer then
                room:loseMaxHp(splayer)
            end
            room:setPlayerFlag(source, 'LuaZuoxing')
        end
        return use_card
    end,
}

LuaZuoxingVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaZuoxing',
    response_or_use = true,
    enabled_at_response = function(self, player, pattern)
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        if pattern ~= 'nullification' then
            return false
        end
        if rinsan.availableShenGuojiaExists(player) then
            return not player:hasFlag('LuaZuoxing') and player:getPhase() == sgs.Player_Play
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if rinsan.availableShenGuojiaExists(p) then
                return not player:hasFlag('LuaZuoxing') and player:getPhase() == sgs.Player_Play
            end
        end
        return false
    end,
    enabled_at_play = function(self, player)
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        if player:getPhase() ~= sgs.Player_Play or player:hasFlag('LuaZuoxing') then
            return false
        end
        if rinsan.availableShenGuojiaExists(player) then
            return true
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if rinsan.availableShenGuojiaExists(p) then
                return true
            end
        end
        return false
    end,
    enabled_at_nullification = function(self, player)
        return false
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = LuaZuoxingCard:clone()
            card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            return card
        end
        local c = sgs.Self:getTag('LuaZuoxing'):toCard()
        if c then
            local card = LuaZuoxingCard:clone()
            card:setUserString(c:objectName())
            return card
        else
            return nil
        end
    end,
}

LuaZuoxing = sgs.CreateTriggerSkill {
    name = 'LuaZuoxing',
    view_as_skill = LuaZuoxingVS,
    on_trigger = function()
    end,
}

LuaZuoxing:setGuhuoDialog('r')

ExShenGuojia:addSkill(LuaHuishi)
ExShenGuojia:addSkill(LuaTianyi)
SkillAnjiang:addSkill(LuaTianyiDamaged)
ExShenGuojia:addSkill(LuaLimitHuishi)
SkillAnjiang:addSkill(LuaZuoxing)
ExShenGuojia:addRelateSkill('LuaZuoxing')

-- 费祎
ExFeiyi = sgs.General(extension, 'ExFeiyi', 'shu', '3', true, true)

LuaJianyuCard = sgs.CreateSkillCard {
    name = 'LuaJianyu',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return true
        elseif #selected == 1 then
            return to_select:objectName() ~= selected[1]:objectName()
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    on_use = function(self, room, source, targets)
        for _, target in ipairs(targets) do
            room:addPlayerMark(target, '@LuaJianyu')
        end
        room:addPlayerMark(source, self:objectName() .. '_lun')
    end,
}

LuaJianyuVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaJianyu',
    view_as = function(self, cards)
        return LuaJianyuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark(self:objectName() .. '_lun') == 0
    end,
}

LuaJianyu = sgs.CreateTriggerSkill {
    name = 'LuaJianyu',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaJianyuVS,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, '@LuaJianyu', 0)
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_RoundStart)
    end,
}

LuaJianyuDraw = sgs.CreateTriggerSkill {
    name = 'LuaJianyuDraw',
    events = {sgs.TargetConfirming},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local feiyi = room:findPlayerBySkillName('LuaJianyu')
        if not feiyi then
            return false
        end
        local use = data:toCardUse()
        if (not use.card) or use.card:isKindOf('SkillCard') then
            return false
        end
        if use.from and use.from:getMark('@LuaJianyu') > 0 then
            if player:getMark('@LuaJianyu') > 0 and player:objectName() ~= use.from:objectName() then
                room:sendCompulsoryTriggerLog(feiyi, 'LuaJianyu')
                room:broadcastSkillInvoke('LuaJianyu')
                room:doAnimate(rinsan.ANIMATE_INDICATE, feiyi:objectName(), player:objectName())
                player:drawCards(1, 'LuaJianyu')
            end
        end
    end,
    can_trigger = globalTrigger,
}

LuaShengxi = sgs.CreateTriggerSkill {
    name = 'LuaShengxi',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local ids = {}
                for i = 0, 10000 do
                    local card = sgs.Sanguosha:getEngineCard(i)
                    if card == nil then
                        break
                    end
                    if card:isKindOf('AdjustSaltPlum') and card:getNumber() == 6 then
                        table.insert(ids, card:getId())
                    end
                end
                local available_ids = {}
                for _, id in ipairs(ids) do
                    local place = room:getCardPlace(id)
                    local owner = room:getCardOwner(id)
                    if not owner then
                        if place ~= sgs.Player_DiscardPile then
                            table.insert(available_ids, id)
                        end
                    end
                end
                if #available_ids == 0 then
                    return false
                end
                local id = available_ids[rinsan.random(1, #available_ids)]
                local id_list = sgs.IntList()
                id_list:append(id)
                room:broadcastSkillInvoke(self:objectName())
                rinsan.obtainCard(id_list, player)
            end
        elseif player:getPhase() == sgs.Player_Finish then
            if player:hasFlag('LuaShengxiCardUsed') and not player:hasFlag('LuaShengxiDamageCaused') then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    local choice = room:askForChoice(player, self:objectName(), 'LuaShengxiZhinang+LuaShengxiDraw')
                    if choice == 'LuaShengxiZhinang' then
                        local obtain = rinsan.obtainCardFromPile(rinsan.isZhinangCard, room:getDrawPile())
                        if obtain then
                            player:obtainCard(obtain, false)
                            return
                        end
                    end
                    player:drawCards(1, self:objectName())
                end
            end
        end
    end,
}

LuaShengxiCheck = sgs.CreateTriggerSkill {
    name = 'LuaShengxiCheck',
    events = {sgs.Damage, sgs.CardUsed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            room:setPlayerFlag(player, 'LuaShengxiDamageCaused')
        else
            local use = data:toCardUse()
            if use.card and (not use.card:isKindOf('SkillCard')) then
                room:setPlayerFlag(player, 'LuaShengxiCardUsed')
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTNOTATPHASE(self, target, sgs.Player_NotActive, 'LuaShengxi')
    end,
}

ExFeiyi:addSkill(LuaJianyu)
SkillAnjiang:addSkill(LuaJianyuDraw)
ExFeiyi:addSkill(LuaShengxi)
SkillAnjiang:addSkill(LuaShengxiCheck)

-- 陈震
ExChenzhen = sgs.General(extension, 'ExChenzhen', 'shu', '3', true)

LuaShamengCard = sgs.CreateSkillCard {
    name = 'LuaShamengCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0)
    end,
    on_effect = function(self, effect)
        local sourse = effect.from
        local dest = effect.to
        local room = sourse:getRoom()
        room:broadcastSkillInvoke('LuaShameng')
        room:drawCards(sourse, 3, 'LuaShameng')
        room:drawCards(dest, 2, 'LuaShameng')
    end,
}
LuaShameng = sgs.CreateViewAsSkill {
    name = 'LuaShameng',
    n = 2,
    view_filter = function(self, selected, to_select)
        if to_select:isEquipped() then
            return false
        end
        if #selected == 0 then
            return true
        elseif #selected == 1 then
            return selected[1]:sameColorWith(to_select)
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards < 2 then
            return nil
        end
        local vs_card = LuaShamengCard:clone()
        vs_card:addSubcard(cards[1])
        vs_card:addSubcard(cards[2])
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaShamengCard')
    end,
}

ExChenzhen:addSkill(LuaShameng)

-- 骆统
ExLuotong = sgs.General(extension, 'ExLuotong', 'wu', '4', true)

LuaQinzheng = sgs.CreateTriggerSkill {
    name = 'LuaQinzheng',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:isKindOf('SkillCard') then
            return false
        end
        room:addPlayerMark(player, '@' .. self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName())
        local markNum = player:getMark('@' .. self:objectName())
        local card1 = rinsan.LuaQinzhengGetCard(room, markNum, 3, 'Slash', 'Jink')
        if card1 then
            player:obtainCard(card1, false)
        end
        local card2 = rinsan.LuaQinzhengGetCard(room, markNum, 5, 'Peach', 'Analeptic')
        if card2 then
            player:obtainCard(card2, false)
        end
        local card3 = rinsan.LuaQinzhengGetCard(room, markNum, 8, 'Duel', 'ExNihilo')
        if card3 then
            player:obtainCard(card3, false)
        end
        return false
    end,
}

ExLuotong:addSkill(LuaQinzheng)
