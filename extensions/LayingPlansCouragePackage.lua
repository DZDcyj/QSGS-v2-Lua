-- 始计篇-勇包
-- Created by DZDcyj at 2023/2/14
module('extensions.LayingPlansCouragePackage', package.seeall)
extension = sgs.Package('LayingPlansCouragePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 孙翊
ExSunyi = sgs.General(extension, 'ExSunyi', 'wu', '4', true, true)

LuaZaoli = sgs.CreateTriggerSkill {
    name = 'LuaZaoli',
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local isStart = (event == sgs.EventPhaseStart)
        if isStart then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            -- 卡牌封禁移到前面
            -- 仅封禁手牌中的、非本回合获取到的牌
            for _, cd in sgs.qlist(player:getHandcards()) do
                -- 带 -Clear 的标记通通由 extra.lua 内部接管，回合结束后消除
                if player:getMark(string.format('%s%d-Clear', self:objectName(), cd:getId())) == 0 then
                    room:setPlayerCardLimitation(player, 'use, response', cd:toString(), false)
                end
            end
            return false
        end

        -- 拆分出牌阶段开始时和出牌阶段结束时，避免出现清理失败的问题
        -- 单独处理解除卡牌封禁的问题
        -- 直接解除所有带卡牌标签的封禁
        for i = 0, 10000 do
            local _cd = sgs.Sanguosha:getEngineCard(i)
            if _cd == nil then
                break
            end
            room:removePlayerCardLimitation(player, 'use, response', _cd:toString() .. '$0')
        end

        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaZaoliCardMove = sgs.CreateTriggerSkill {
    name = 'LuaZaoliCardMove',
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
            player:getPhase() ~= sgs.Player_NotActive and move.to_place == sgs.Player_PlaceHand and
            not move.card_ids:isEmpty() then
            for _, id in sgs.qlist(move.card_ids) do
                room:addPlayerMark(player, 'LuaZaoli' .. id .. '-Clear')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZaoli')
    end,
}

LuaZaoliUse = sgs.CreateTriggerSkill {
    name = 'LuaZaoliUse',
    events = {sgs.CardUsed, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card
        local isHandcard
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            card = use.card
            isHandcard = use.m_isHandcard
        else
            local resp = data:toCardResponse()
            card = resp.m_card
            isHandcard = resp.m_isHandcard
        end
        if card and (not card:isKindOf('SkillCard')) and isHandcard and player:getMark('@LuaZaoli') < 4 then
            room:broadcastSkillInvoke('LuaZaoli')
            room:sendCompulsoryTriggerLog(player, 'LuaZaoli')
            player:gainMark('@LuaZaoli')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZaoli')
    end,
}

LuaZaoliStart = sgs.CreateTriggerSkill {
    name = 'LuaZaoliStart',
    events = {sgs.EventPhaseStart, sgs.ChoiceMade},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getMark('@LuaZaoli') == 0 or player:getPhase() ~= sgs.Player_RoundStart then
                return false
            end
            room:broadcastSkillInvoke('LuaZaoli')
            room:sendCompulsoryTriggerLog(player, 'LuaZaoli')
            if player:getCardCount(true) > 0 then
                room:askForDiscard(player, 'LuaZaoli', 10000, 1, false, true, 'LuaZaoli-discard')
                return false
            end
            local markCount = player:getMark('@LuaZaoli')
            player:loseMark('@LuaZaoli', markCount)
            player:drawCards(markCount, 'LuaZaoli')
            if markCount > 2 then
                room:loseHp(player)
            end
        else
            local dataStr = data:toString():split(':')
            if #dataStr ~= 3 or dataStr[1] ~= 'cardDiscard' or dataStr[2] ~= 'LuaZaoli' then
                return false
            end
            local count = #dataStr[3]:split('+')
            local markCount = player:getMark('@LuaZaoli')
            player:loseMark('@LuaZaoli', markCount)
            player:drawCards(markCount + count, 'LuaZaoli')
            if markCount > 2 then
                room:loseHp(player)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaZaoli')
    end,
}

ExSunyi:addSkill(LuaZaoli)
table.insert(hiddenSkills, LuaZaoliCardMove)
table.insert(hiddenSkills, LuaZaoliUse)
table.insert(hiddenSkills, LuaZaoliStart)

-- 宗预
ExZongyu = sgs.General(extension, 'ExZongyu', 'shu', '3', true, true)

LuaZhibian = sgs.CreateTriggerSkill {
    name = 'LuaZhibian',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local available_players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:canPindian(p, self:objectName()) then
                available_players:append(p)
            end
        end
        if available_players:isEmpty() then
            return false
        end
        local target = room:askForPlayerChosen(player, available_players, self:objectName(), '@LuaZhibian', true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            if player:pindian(target, self:objectName()) then
                local choices = {}
                if rinsan.canMoveCardFromPlayer(target, player) then
                    table.insert(choices, 'LuaZhibianChoice1')
                end
                if player:isWounded() then
                    table.insert(choices, 'LuaZhibianChoice2')
                end
                if #choices == 2 then
                    table.insert(choices, 'LastStand')
                end
                table.insert(choices, 'cancel')
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                if choice == 'cancel' then
                    return false
                end
                if choice == 'LuaZhibianChoice1' then
                    rinsan.askForMoveCards(player, target, player, self:objectName())
                elseif choice == 'LuaZhibianChoice2' then
                    rinsan.recover(player)
                else
                    rinsan.askForMoveCards(player, target, player, self:objectName())
                    rinsan.recover(player)
                    room:addPlayerMark(player, 'LuaZhibianSkipDraw')
                end
            else
                room:loseHp(player)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Start)
    end,
}

LuaZhibianSkipDraw = sgs.CreateTriggerSkill {
    name = 'LuaZhibianSkipDraw',
    events = {sgs.EventPhaseChanging},
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('LuaZhibianSkipDraw') == 0 then
            return false
        end
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw then
            room:sendCompulsoryTriggerLog(player, 'LuaZhibian')
            room:setPlayerMark(player, 'LuaZhibianSkipDraw', 0)
            player:skip(change.to)
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaYuyan = sgs.CreateTriggerSkill {
    name = 'LuaYuyan',
    events = {sgs.TargetConfirming},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') and not use.card:isVirtualCard() then
            if use.from and use.from:getHp() > player:getHp() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                local number = use.card:getNumber()
                local pattern = string.format('.|.|%d~14|.|.', number + 1)
                local dataforai = sgs.QVariant()
                dataforai:setValue(player)
                use.from:setTag('LuaYuyanTarget', dataforai)
                local prompt = string.format('@Yuyan-give:%s::%s', player:objectName(), use.card:getNumberString())
                local card = room:askForCard(use.from, pattern, prompt, data, sgs.Card_MethodNone)
                use.from:removeTag('LuaYuyanTarget')
                if card then
                    room:obtainCard(player, card)
                    return false
                end
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
            end
        end
        return false
    end,
}

ExZongyu:addSkill(LuaZhibian)
ExZongyu:addSkill(LuaYuyan)
table.insert(hiddenSkills, LuaZhibianSkipDraw)

-- 初始随机魏国/吴国
local wenyang_kingdoms = {'wei', 'wu'}
-- 文鸯
ExWenyang = sgs.General(extension, 'ExWenyang', wenyang_kingdoms[rinsan.random(1, 2)], '4', true, true)

LuaQuediCard = sgs.CreateSkillCard {
    name = 'LuaQuediCard',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        if self:subcardsLength() > 0 then
            return false
        end
        return to_select:hasFlag('LuaQuediTarget') and (not to_select:isKongcheng())
    end,
    feasible = function(self, targets)
        -- 如果没有弃牌，就要求为一（拿牌，确认背水选项）
        local len = self:subcardsLength()
        if len == 0 then
            return #targets == 1
        end
        -- 否则必须为零（弃牌加伤害）
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaQuedi')
        local target
        if #targets > 0 then
            target = targets[1]
        end
        room:broadcastSkillInvoke('LuaQuedi')
        room:addPlayerMark(source, 'LuaQuediUsed')
        local card
        if target then
            local card_id = room:askForCardChosen(source, target, 'h', 'LuaQuedi', false, sgs.Card_MethodNone)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
            room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
            card = room:askForCard(source, 'BasicCard|.|.|.', 'LuaQuediBeishui', sgs.QVariant())
        end
        if self:subcardsLength() > 0 then
            card = sgs.Sanguosha:getCard(self:getSubcards():first())
        end
        if card then
            room:setPlayerFlag(source, 'LuaQuediDamageUp')
        end
        if target and card then
            room:loseMaxHp(source)
        end
    end,
}

LuaQuediVS = sgs.CreateViewAsSkill {
    name = 'LuaQuedi',
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected == 0 and to_select:isKindOf('BasicCard')
    end,
    view_as = function(self, cards)
        local vs_card = LuaQuediCard:clone()
        for _, cd in ipairs(cards) do
            vs_card:addSubcard(cd)
        end
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@LuaQuedi')
    end,
}

LuaQuedi = sgs.CreateTriggerSkill {
    name = 'LuaQuedi',
    events = {sgs.TargetSpecified},
    view_as_skill = LuaQuediVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:getMark('LuaQuediUsed') >= player:getMark('LuaQuediExtra') + 1 then
            return false
        end
        if use.card and (use.card:isKindOf('Slash') or use.card:isKindOf('Duel')) then
            if use.to:length() == 1 then
                local target = use.to:at(0)
                room:setPlayerFlag(target, 'LuaQuediTarget')
                room:askForUseCard(player, '@@LuaQuedi', 'LuaQuedi_ask', -1, sgs.Card_MethodNone)
                room:setPlayerFlag(target, '-LuaQuediTarget')
            end
        end
    end,
}

LuaQuediDamageUp = sgs.CreateTriggerSkill {
    name = 'LuaQuediDamageUp',
    events = {sgs.DamageCaused},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and (damage.card:isKindOf('Slash') or damage.card:isKindOf('Duel')) and
            damage.from:hasFlag('LuaQuediDamageUp') then
            room:sendCompulsoryTriggerLog(damage.from, 'LuaQuedi')
            room:broadcastSkillInvoke(self:objectName())
            damage.damage = damage.damage + 1
            data:setValue(damage)
            room:setPlayerFlag(player, '-LuaQuediDamageUp')
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaQuediClear = sgs.CreateTriggerSkill {
    name = 'LuaQuediClear',
    global = true,
    events = {sgs.EventPhaseChanging, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, 'LuaQuediUsed', 0)
                    room:setPlayerMark(p, 'LuaQuediExtra', 0)
                end
            end
        else
            local use = data:toCardUse()
            if use.card and (use.card:isKindOf('Slash') or use.card:isKindOf('Duel')) and use.from and
                use.from:hasFlag('LuaQuediDamageUp') then
                room:setPlayerFlag(player, '-LuaQuediDamageUp')
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaChuifengCard = sgs.CreateSkillCard {
    name = 'LuaChuifengCard',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) then
            local targets_list = sgs.PlayerList()
            for _, target in ipairs(selected) do
                targets_list:append(target)
            end
            local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_NoSuit, 0)
            duel:setSkillName('LuaChuifeng')
            duel:deleteLater()
            if sgs.Self:isCardLimited(duel, sgs.Card_MethodUse) then
                return false
            end
            if duel:targetFilter(targets_list, to_select, sgs.Self) then
                return not sgs.Self:isProhibited(to_select, duel)
            end
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaChuifeng')
        room:loseHp(source)
        local victim = targets[1]
        local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_NoSuit, 0)
        duel:setSkillName('LuaChuifeng')
        room:useCard(sgs.CardUseStruct(duel, source, victim))
    end,
}

LuaChuifengVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaChuifeng',
    view_as = function(self, cards)
        return LuaChuifengCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getKingdom() ~= 'wei' then
            return false
        end
        return player:usedTimes('#LuaChuifengCard') < 2 and player:getMark('LuaChuifengSelfDamaged_biu') == 0
    end,
}

LuaChuifeng = sgs.CreateTriggerSkill {
    name = 'LuaChuifeng',
    events = {sgs.DamageInflicted},
    view_as_skill = LuaChuifengVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:getSkillName() == self:objectName() then
            rinsan.sendLogMessage(room, '#LuaChuifeng', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['card_str'] = damage.card:toString(),
            })
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, 'LuaChuifengSelfDamaged_biu')
            return true
        end
        return false
    end,
}

LuaChongjianCard = sgs.CreateSkillCard {
    name = 'LuaChongjianCard',
    will_throw = false,
    filter = function(self, targets, to_select)
        local plist = sgs.PlayerList()
        for i = 1, #targets do
            plist:append(targets[i])
        end
        local aocaistring = self:getUserString()
        if aocaistring ~= '' then
            local uses = aocaistring:split('+')
            local name = uses[1]
            local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            if not card then
                return false
            end
            card:addSubcard(self:getSubcards():first())
            if card and card:targetFixed() then
                return false
            else
                local total_num = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, card) + 1
                -- 处理指定目标，如【挑衅】
                local SpecificAssignee = false
                for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
                    if sgs.Slash_IsSpecificAssignee(p, sgs.Self, card) then
                        SpecificAssignee = true
                        break
                    end
                end
                local canSlash = (not SpecificAssignee)
                if SpecificAssignee then
                    if #targets == 0 then
                        canSlash = sgs.Slash_IsSpecificAssignee(to_select, sgs.Self, card)
                    else
                        if sgs.Self:hasFlag('slashDisableExtraTarget') then
                            return false
                        end
                        for _, p in ipairs(targets) do
                            if sgs.Slash_IsSpecificAssignee(p, sgs.Self, card) then
                                canSlash = true
                                break
                            end
                        end
                    end
                end
                return sgs.Self:canSlash(to_select, card, false) and #targets < total_num and canSlash
            end
        end
        return true
    end,
    target_fixed = function(self)
        local card
        local aocaistring = self:getUserString()
        if aocaistring ~= '' then
            local uses = aocaistring:split('+')
            card = sgs.Sanguosha:cloneCard(uses[1], sgs.Card_NoSuit, -1)
        end
        card:addSubcard(self:getSubcards():first())
        return card and card:targetFixed()
    end,
    feasible = function(self, targets)
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do
            plist:append(targets[i])
        end
        local aocaistring = self:getUserString()
        if aocaistring ~= '' then
            local uses = aocaistring:split('+')
            card = sgs.Sanguosha:cloneCard(uses[1], sgs.Card_NoSuit, -1)
        end
        card:addSubcard(self:getSubcards():first())
        return card and card:targetsFeasible(plist, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local room = card_use.from:getRoom()
        local aocaistring = self:getUserString()
        local uses = {}
        for _, name in pairs(aocaistring:split('+')) do
            table.insert(uses, name)
        end
        if table.contains(uses, 'slash') then
            if not rinsan.isPackageBanned('maneuvering') then
                table.insert(uses, 'normal_slash')
                table.insert(uses, 'thunder_slash')
                table.insert(uses, 'fire_slash')
            end
        end
        local name = room:askForChoice(card_use.from, 'LuaChongjian', table.concat(uses, '+'))
        if name == 'normal_slash' then
            name = 'slash'
        end
        local use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        if use_card == nil then
            return nil
        end
        use_card:setSkillName('LuaChongjian')
        use_card:addSubcard(self:getSubcards():first())
        local available = true
        for _, p in sgs.qlist(card_use.to) do
            if card_use.from:isProhibited(p, use_card) then
                available = false
                break
            end
        end
        if not available then
            return nil
        end
        return use_card
    end,
    on_validate_in_response = function(self, user)
        local room = user:getRoom()
        local aocaistring = self:getUserString()
        local uses = {}
        for _, name in pairs(aocaistring:split('+')) do
            table.insert(uses, name)
        end
        if table.contains(uses, 'slash') then
            if not rinsan.isPackageBanned('maneuvering') then
                table.insert(uses, 'normal_slash')
                table.insert(uses, 'thunder_slash')
                table.insert(uses, 'fire_slash')
            end
        end
        local name = room:askForChoice(user, 'LuaChongjian', table.concat(uses, '+'))
        if name == 'normal_slash' then
            name = 'slash'
        end
        local use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        if use_card == nil then
            return nil
        end
        use_card:addSubcard(self:getSubcards():first())
        use_card:setSkillName('LuaChongjian')
        return use_card
    end,
}

local LuaChongjianPatterns = {'slash', 'analeptic'}

LuaChongjianUseCard = sgs.CreateSkillCard {
    name = 'LuaChongjian',
    will_throw = false,
    target_fixed = false,
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
        if not card then
            return false
        end
        card:addSubcards(self:getSubcards())
        local total_num = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, card) + 1
        return sgs.Self:canSlash(to_select, card, false) and #targets < total_num
    end,
    feasible = function(self, targets)
        local type = #targets > 0 and 'slash' or 'analeptic'
        local temp = sgs.Sanguosha:cloneCard(type, sgs.Card_NoSuit, 0)
        temp:deleteLater()
        temp:addSubcards(self:getSubcards())
        if sgs.Self:isCardLimited(temp, temp:getHandlingMethod()) then
            return false
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local players = sgs.PlayerList()
            for i = 1, #targets do
                players:append(targets[i])
            end
            local card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
            card:addSubcards(self:getSubcards())
            local slash_available = sgs.Slash_IsAvailable(sgs.Self) and card and card:targetsFeasible(players, sgs.Self)
            local analeptic_available = sgs.Analeptic_IsAvailable(sgs.Self) and #targets == 0
            return analeptic_available or slash_available
        else
            local card
            local plist = sgs.PlayerList()
            for i = 1, #targets do
                plist:append(targets[i])
            end
            local aocaistring = self:getUserString()
            if aocaistring ~= '' then
                local uses = aocaistring:split('+')
                card = sgs.Sanguosha:cloneCard(uses[1], sgs.Card_NoSuit, -1)
            end
            card:addSubcard(self:getSubcards():first())
            return card and card:targetsFeasible(plist, sgs.Self)
        end
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local pattern = #targets > 0 and 'slash' or 'analeptic'
        repeat
            if pattern == 'slash' then
                local uses = {}
                if rinsan.isPackageBanned('maneuvering') then
                    break
                end
                table.insert(uses, 'normal_slash')
                table.insert(uses, 'thunder_slash')
                table.insert(uses, 'fire_slash')
                pattern = room:askForChoice(source, 'LuaChongjian', table.concat(uses, '+'))
                if pattern == 'normal_slash' then
                    pattern = 'slash'
                end
            end
        until true
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        local card_use = sgs.CardUseStruct()
        card_use.card = card
        card_use.from = source
        if #targets > 0 then
            for _, target in ipairs(targets) do
                card_use.to:append(target)
            end
        else
            card_use.to:append(source)
        end
        room:useCard(card_use, true)
    end,
}

LuaChongjianVS = sgs.CreateViewAsSkill {
    name = 'LuaChongjian',
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf('EquipCard')
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if #cards == 1 then
                local acard = LuaChongjianUseCard:clone()
                acard:addSubcard(cards[1]:getId())
                return acard
            end
        else
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            local acard = LuaChongjianCard:clone()
            if #cards ~= 1 then
                return nil
            end
            acard:addSubcard(cards[1]:getId())
            if pattern == 'peach+analeptic' then
                pattern = 'analeptic'
            end
            acard:setUserString(pattern)
            local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
            c:deleteLater()
            for _, cd in ipairs(cards) do
                c:addSubcard(cd)
            end
            if sgs.Self:isCardLimited(acard, c:getHandlingMethod()) then
                return nil
            end
            return acard
        end
    end,
    enabled_at_play = function(self, player)
        if player:getKingdom() ~= 'wu' then
            return false
        end
        local choices = {}
        for _, name in ipairs(LuaChongjianPatterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            if poi:isAvailable(player) then
                table.insert(choices, name)
            end
        end
        return next(choices)
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getKingdom() ~= 'wu' then
            return false
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return (string.find(pattern, 'analeptic') or string.find(pattern, 'slash'))
        end
        return false
    end,
}

LuaChongjian = sgs.CreateTriggerSkill {
    name = 'LuaChongjian',
    events = {sgs.Damage},
    view_as_skill = LuaChongjianVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (not damage.card) or (damage.card:getSkillName() ~= self:objectName()) then
            return false
        end
        local victim = damage.to
        local x = math.min(damage.damage, victim:getEquips():length())
        if x > 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local orig_places = {}
            local cards = sgs.IntList()
            room:setPlayerFlag(victim, 'xuanhuo_InTempMoving')
            room:setTag('LuaFakeMove', sgs.QVariant(true))
            for i = 0, x - 1, 1 do
                local id = room:askForCardChosen(player, victim, 'e', self:objectName(), false, sgs.Card_MethodNone, cards)
                local place = room:getCardPlace(id)
                orig_places[i] = place
                cards:append(id)
                victim:addToPile('#LuaChongjian', id, false)
            end
            for i = 0, x - 1, 1 do
                room:moveCardTo(sgs.Sanguosha:getCard(cards:at(i)), victim, orig_places[i], false)
            end
            room:setPlayerFlag(victim, '-xuanhuo_InTempMoving')
            room:setTag('LuaFakeMove', sgs.QVariant(false))
            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            dummy:addSubcards(cards)
            room:obtainCard(player, dummy, false)
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getKingdom() == 'wu'
    end,
}

LuaChongjianQinggang = sgs.CreateTriggerSkill {
    name = 'LuaChongjianQinggang',
    events = {sgs.TargetSpecified},
    priority = -1,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from and use.card and use.card:isKindOf('Slash') and use.card:getSkillName() == 'LuaChongjian' then
            for _, p in sgs.qlist(use.to) do
                rinsan.addQinggangTag(p, use.card)
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaChoujue = sgs.CreateTriggerSkill {
    name = 'LuaChoujue',
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local splayer = death.who
        if splayer:objectName() == player:objectName() then
            return false
        end
        local killer
        if death.damage then
            killer = death.damage.from
        end
        if player:isAlive() and killer and killer:objectName() == player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            rinsan.addPlayerMaxHp(player, 1)
            player:drawCards(2, self:objectName())
            room:addPlayerMark(player, 'LuaQuediExtra')
        end
    end,
}

LuaWenyangKingdomChoose = sgs.CreateTriggerSkill {
    name = 'LuaWenyangKingdomChoose',
    events = {sgs.GameStart},
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getGeneralName() == 'ExWenyang' and p:getMark('LuaWenyangKingdomChoose') == 0 then
                local choice = room:askForChoice(p, 'LuaWenyangKingdomChoose', 'wei+wu')
                room:setPlayerProperty(p, 'kingdom', sgs.QVariant(choice))
                room:addPlayerMark(p, 'LuaWenyangKingdomChoose')
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

ExWenyang:addSkill(LuaQuedi)
ExWenyang:addSkill(LuaChuifeng)
ExWenyang:addSkill(LuaChongjian)
ExWenyang:addSkill(LuaChoujue)
table.insert(hiddenSkills, LuaQuediDamageUp)
table.insert(hiddenSkills, LuaQuediClear)
table.insert(hiddenSkills, LuaChongjianQinggang)
table.insert(hiddenSkills, LuaWenyangKingdomChoose)

-- 王双
ExWangshuang = sgs.General(extension, 'ExWangshuang', 'wei', '4', true)
LuaYiyong = sgs.CreateTriggerSkill {
    name = 'LuaYiyong',
    events = {sgs.Damaged, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (not damage.card) or (not damage.card:isKindOf('Slash')) then
            return false
        end
        if event == sgs.Damaged then
            if not player:getWeapon() then
                return false
            end
            if (not damage.from) or damage.from:objectName() == player:objectName() then
                return false
            end
            if damage.card:isVirtualCard() and damage.card:subcardsLength() == 0 then
                return false
            end
            local data2 = sgs.QVariant()
            data2:setValue(damage.from)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                player:obtainCard(damage.card)
                room:broadcastSkillInvoke(self:objectName())
                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                if damage.card:isVirtualCard() then
                    slash:addSubcards(damage.card:getSubcards())
                else
                    slash:addSubcard(damage.card)
                end
                slash:setSkillName(self:objectName())
                room:useCard(sgs.CardUseStruct(slash, player, damage.from))
            end
        else
            if damage.card and damage.card:getSkillName() == self:objectName() then
                if damage.to:getWeapon() then
                    return false
                end
                room:sendCompulsoryTriggerLog(player, self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
}

local function isWeapon(cd)
    return cd:isKindOf('Weapon')
end

LuaShanxieCard = sgs.CreateSkillCard {
    name = 'LuaShanxie',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local weapon = rinsan.obtainCardFromPile(isWeapon, room:getDrawPile())
        if weapon then
            source:obtainCard(weapon, true)
            return
        end
        local ids = {}
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:getWeapon() then
                table.insert(ids, p:getWeapon():getEffectiveId())
            end
        end
        if #ids == 0 then
            return
        end
        local cd = sgs.Sanguosha:getCard(ids[rinsan.random(1, #ids)])
        source:obtainCard(cd, false)
    end,
}

LuaShanxieVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaShanxie',
    view_as = function(self, cards)
        return LuaShanxieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaShanxie')
    end,
}

LuaShanxie = sgs.CreateTriggerSkill {
    name = 'LuaShanxie',
    events = {sgs.SlashProceed},
    view_as_skill = LuaShanxieVS,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        local slasher = effect.from
        if slasher:hasSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(slasher, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local number = slasher:getAttackRange() * 2
            local pattern = string.format('Jink|.|1~%d|.|.|.', number)
            room:setPlayerCardLimitation(effect.to, 'use', pattern, false)
            local prompt = string.format('@LuaShanxie-jink:%s::%s', slasher:objectName(), number)
            local jink
            if effect.jink_num == 1 then
                jink = room:askForCard(effect.to, 'jink', prompt, data, sgs.Card_MethodUse, effect.from)
                room:removePlayerCardLimitation(effect.to, 'use', pattern)
                if room:isJinkEffected(effect.to, jink) then
                    local valid = jink:getNumber() > number
                    if valid then
                        room:slashResult(effect, jink)
                    else
                        rinsan.sendLogMessage(room, '$LuaShanxieInvalidJink', {
                            ['from'] = effect.to,
                            ['arg'] = number,
                            ['to'] = slasher,
                            ['arg2'] = 'jink',
                        })
                        room:slashResult(effect, nil)
                    end
                else
                    room:slashResult(effect, nil)
                end
            else
                jink = sgs.Sanguosha:cloneCard('jink', sgs.Card_NoSuit, 0)
                local index = effect.jink_num
                while index > 0 do
                    local suffix = index == effect.jink_num and '-start' or ''
                    prompt = string.format('@LuaShanxie-multi-jink%s:%s::%s:%s', suffix, slasher:objectName(), index, number)
                    local temp = room:askForCard(effect.to, 'jink', prompt, data, sgs.Card_MethodUse, effect.from)
                    if room:isJinkEffected(effect.to, temp) then
                        jink:addSubcard(temp:getEffectiveId())
                    else
                        room:slashResult(effect, nil)
                        break
                    end
                    index = index - 1
                end
                local valid = jink:getNumber() > number
                if valid then
                    room:slashResult(effect, jink)
                else
                    rinsan.sendLogMessage(room, '$LuaShanxieInvalidJink', {
                        ['from'] = effect.to,
                        ['arg'] = number,
                        ['to'] = slasher,
                        ['arg2'] = 'jink',
                    })
                    room:slashResult(effect, nil)
                end
            end
            return true
        end
        return false
    end,
    can_trigger = rinsan.globalTrigger,
}

ExWangshuang:addSkill(LuaYiyong)
ExWangshuang:addSkill(LuaShanxie)

-- 高览
ExGaolan = sgs.General(extension, 'ExGaolan', 'qun', '4', true, true)

LuaJungongCard = sgs.CreateSkillCard {
    name = 'LuaJungong',
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, -1)
        if not card then
            return false
        end
        card:addSubcards(self:getSubcards())
        local total_num = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, card) + 1
        return sgs.Self:canSlash(to_select, card, false) and #targets < total_num
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local len = self:subcardsLength()
        if len == 0 then
            -- 此时已经 used 了，不必特别 +1
            room:loseHp(source, source:usedTimes('#LuaJungong'))
        end
        local victim = targets[1]
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        room:useCard(sgs.CardUseStruct(slash, source, victim))
    end,
}

LuaJungongVS = sgs.CreateViewAsSkill {
    name = 'LuaJungong',
    n = 99999,
    view_filter = function(self, selected, to_select)
        local required = sgs.Self:usedTimes('#LuaJungong') + 1
        return #selected < required
    end,
    view_as = function(self, cards)
        local required = sgs.Self:usedTimes('#LuaJungong') + 1
        if #cards > 0 and #cards ~= required then
            return nil
        end
        local card = LuaJungongCard:clone()
        for _, cd in ipairs(cards) do
            card:addSubcard(cd)
        end
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag('LuaJungongDamaged')
    end,
}

LuaJungong = sgs.CreateTriggerSkill {
    name = 'LuaJungong',
    events = {sgs.Damage},
    view_as_skill = LuaJungongVS,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:getSkillName() == self:objectName() then
            room:setPlayerFlag(player, 'LuaJungongDamaged')
        end
        return false
    end,
}

LuaDengli = sgs.CreateTriggerSkill {
    name = 'LuaDengli',
    events = {sgs.TargetConfirmed, sgs.TargetSpecified},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (not use.card) or (not use.card:isKindOf('Slash')) then
            return false
        end
        if event == sgs.TargetSpecified then
            for _, p in sgs.qlist(use.to) do
                if p:getHp() == player:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(1, self:objectName())
                end
            end
        else
            if use.to:contains(player) then
                if use.from and use.from:getHp() == player:getHp() then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName())
                        player:drawCards(1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
}

ExGaolan:addSkill(LuaJungong)
ExGaolan:addSkill(LuaDengli)

rinsan.addHiddenSkills(hiddenSkills)
