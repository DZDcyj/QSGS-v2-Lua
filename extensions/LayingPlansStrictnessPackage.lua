-- 始计篇-严包
-- Created by DZDcyj at 2023/2/27
module('extensions.LayingPlansStrictnessPackage', package.seeall)
extension = sgs.Package('LayingPlansStrictnessPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')
local rectification = require('extensions.RectificationPackage')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 吕范
ExLvfan = sgs.General(extension, 'ExLvfan', 'wu', '3', true, true)

LuaDiaoduCard = sgs.CreateSkillCard {
    name = 'LuaDiaodu',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            -- 选择起始，要求必须有装备
            return rinsan.canMoveCardOut(to_select, 'e')
        elseif #selected == 1 then
            -- 选择目标，要求可以移动到
            local from = selected[1]
            return rinsan.canMoveCardFromPlayer(from, to_select, 'e')
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, use)
        local thread = room:getThread()
        local data = sgs.QVariant()
        data:setValue(use)
        thread:trigger(sgs.PreCardUsed, room, use.from, data)
        rinsan.sendLogMessage(room, '#ChoosePlayerWithSkill', {
            ['from'] = use.from,
            ['tos'] = use.to,
            ['arg'] = self:objectName(),
        })
        thread:trigger(sgs.CardUsed, room, use.from, data)
        thread:trigger(sgs.CardFinished, room, use.from, data)
    end,
    on_use = function(self, room, source, targets)
        local from = targets[1]
        local to = targets[2]
        room:notifySkillInvoked(source, self:objectName())
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), from:objectName())
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), to:objectName())
        rinsan.askForMoveCards(source, from, to, self:objectName(), 'e')
        from:drawCards(1, self:objectName())
    end,
}

LuaDiaoduVS = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaDiaodu',
    view_as = function(self, cards)
        return LuaDiaoduCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == '@@LuaDiaodu'
    end,
}

LuaDiaodu = sgs.CreateTriggerSkill {
    name = 'LuaDiaodu',
    events = {sgs.EventPhaseStart},
    view_as_skill = LuaDiaoduVS,
    on_trigger = function(self, event, player, data, room)
        room:askForUseCard(player, '@@LuaDiaodu', '@LuaDiaodu')
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Start)
    end,
}

LuaDiancai = sgs.CreateTriggerSkill {
    name = 'LuaDiancai',
    events = {sgs.EventPhaseEnd, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local x = p:getMark('@' .. self:objectName())
                local toDraw = p:getMaxHp() - p:getHandcardNum()
                if toDraw > 0 and x >= p:getHp() and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    p:drawCards(toDraw, self:objectName())
                end
                room:setPlayerMark(p, '@' .. self:objectName(), 0)
            end
        elseif event == sgs.CardsMoveOneTime then
            local current = room:getCurrent()
            if current:objectName() == player:objectName() or current:getPhase() ~= sgs.Player_Play then
                return false
            end
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) then
                if rinsan.lostCard(move, player) then
                    room:addPlayerMark(player, '@' .. self:objectName(), move.card_ids:length())
                end
            end
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaYanji = sgs.CreateTriggerSkill {
    name = 'LuaYanji',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if not rectification.canBeAskedForRetification(player) then
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), 1)
            rectification.askForRetification(player, player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

ExLvfan:addSkill(LuaDiaodu)
ExLvfan:addSkill(LuaDiancai)
ExLvfan:addSkill(LuaYanji)

-- 崔琰
ExCuiyan = sgs.General(extension, 'ExCuiyan', 'wei', '3', true, true)

LuaYajunCard = sgs.CreateSkillCard {
    name = 'LuaYajun',
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if rinsan.checkFilter(targets, to_select, rinsan.EQUAL, 0) then
            return sgs.Self:canPindian(to_select, 'LuaYajun')
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local target = targets[1]
        local pindianCard = sgs.Sanguosha:getCard(self:getSubcards():first())
        source:pindian(target, self:objectName(), pindianCard)
    end,
}

LuaYajunVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaYajun',
    view_filter = function(self, to_select)
        if to_select:isEquipped() then
            return false
        end
        local id = to_select:getEffectiveId()
        return sgs.Self:getMark('LuaYajun' .. id .. '-Clear') > 0
    end,
    view_as = function(self, card)
        local yajunCard = LuaYajunCard:clone()
        yajunCard:addSubcard(card)
        return yajunCard
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaYajun'
    end,
}

LuaYajun = sgs.CreateTriggerSkill {
    name = 'LuaYajun',
    events = {sgs.DrawNCards, sgs.EventPhaseStart, sgs.Pindian},
    view_as_skill = LuaYajunVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            data:setValue(data:toInt() + 1)
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason ~= self:objectName() then
                return false
            end
            if pindian.success then
                local choices = {'LuaYajunPutFrom', 'LuaYajunPutTo', 'cancel'}
                local choice = room:askForChoice(pindian.from, self:objectName(), table.concat(choices, '+'))
                local toMove, from
                if choice == choices[1] then
                    toMove = pindian.from_card
                    from = pindian.from
                elseif choice == choices[2] then
                    toMove = pindian.to_card
                    from = pindian.to
                end
                if toMove then
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, from:objectName(), '',
                        'LuaYajun', '')
                    room:moveCardTo(toMove, from, nil, sgs.Player_DrawPile, reason, true)
                end
            else
                room:addPlayerMark(pindian.from, self:objectName() .. '-Failed-Clear')
            end
        else
            if player:getPhase() == sgs.Player_Play then
                room:askForUseCard(player, '@@LuaYajun', '@LuaYajun')
            end
        end
    end,
}

LuaYajunMaxCards = sgs.CreateMaxCardsSkill {
    name = '#LuaYajunMaxCards',
    extra_func = function(self, target)
        local x = target:getMark('LuaYajun-Failed-Clear')
        if x > 0 then
            return -x
        end
        return 0
    end,
}

LuaYajunCardMove = sgs.CreateTriggerSkill {
    name = 'LuaYajunCardMove',
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
            player:getPhase() ~= sgs.Player_NotActive and move.to_place == sgs.Player_PlaceHand and
            not move.card_ids:isEmpty() then
            for _, id in sgs.qlist(move.card_ids) do
                room:addPlayerMark(player, 'LuaYajun' .. id .. '-Clear')
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaYajun')
    end,
}

LuaZundiMoveCard = sgs.CreateSkillCard {
    name = 'LuaZundiMove',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            -- 选择起始，要求必须有装备/判定牌
            return rinsan.canMoveCardOut(to_select)
        elseif #selected == 1 then
            -- 选择目标，要求可以移动到
            local from = selected[1]
            return rinsan.canMoveCardFromPlayer(from, to_select)
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, use)
        local thread = room:getThread()
        local data = sgs.QVariant()
        data:setValue(use)
        thread:trigger(sgs.PreCardUsed, room, use.from, data)
        rinsan.sendLogMessage(room, '#ChoosePlayerWithSkill', {
            ['from'] = use.from,
            ['tos'] = use.to,
            ['arg'] = 'LuaZundi',
        })
        thread:trigger(sgs.CardUsed, room, use.from, data)
        thread:trigger(sgs.CardFinished, room, use.from, data)
    end,
    on_use = function(self, room, source, targets)
        local from = targets[1]
        local to = targets[2]
        room:notifySkillInvoked(source, 'LuaZundi')
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), from:objectName())
        room:doAnimate(rinsan.ANIMATE_INDICATE, source:objectName(), to:objectName())
        rinsan.askForMoveCards(source, from, to, 'LuaZundi')
    end,
}

LuaZundiCard = sgs.CreateSkillCard {
    name = 'LuaZundi',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected == 0
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local target = targets[1]
        local judge = rinsan.createJudgeStruct({
            ['play_animation'] = true,
            ['who'] = source,
            ['reason'] = self:objectName(),
        })
        room:judge(judge)
        if judge.card:isBlack() then
            target:drawCards(3, self:objectName())
        else
            room:setPlayerFlag(target, 'LuaZundi-Moving')
            room:askForUseCard(target, '@@LuaZundi', '@LuaZundi')
            room:setPlayerFlag(target, '-LuaZundi-Moving')
        end
    end,
}

LuaZundi = sgs.CreateViewAsSkill {
    name = 'LuaZundi',
    n = 1,
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag('LuaZundi-Moving') then
            return false
        end
        return #selected == 0 and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag('LuaZundi-Moving') then
            return LuaZundiMoveCard:clone()
        end
        if #cards == 0 then
            return nil
        end
        local zundiCard = LuaZundiCard:clone()
        for _, cd in ipairs(cards) do
            zundiCard:addSubcard(cd)
        end
        return zundiCard
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaZundi')
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaZundi'
    end,
}

ExCuiyan:addSkill(LuaYajun)
ExCuiyan:addSkill(LuaZundi)
table.insert(hiddenSkills, LuaYajunMaxCards)
table.insert(hiddenSkills, LuaYajunCardMove)
table.insert(hiddenSkills, LuaZundiMoveVS)

-- 朱儁
ExZhujun = sgs.General(extension, 'ExZhujun', 'qun', '4', true, true)

LuaYangjieCard = sgs.CreateSkillCard {
    name = 'LuaYangjie',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and
                   sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, self:objectName())
        local target = targets[1]
        if source:pindian(target, self:objectName()) then
            return
        end
        local available_slashers = sgs.SPlayerList()
        local slash = sgs.Sanguosha:cloneCard('fire_slash')
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:canSlash(target, slash, false) then
                available_slashers:append(p)
            end
        end
        slash:setSkillName('_LuaYangjie')
        if available_slashers:isEmpty() then
            return
        end
        local prompt = string.format('%s:%s', 'LuaYangjie-Choose', target:objectName())
        local slasher = room:askForPlayerChosen(source, available_slashers, self:objectName(), prompt, true)
        if slasher then
            room:useCard(sgs.CardUseStruct(slash, slasher, target))
        end
    end,
}

LuaYangjie = sgs.CreateZeroCardViewAsSkill {
    name = 'LuaYangjie',
    view_as = function(self, cards)
        return LuaYangjieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#LuaYangjie')
    end,
}

local function canInvokeLuaZhujunJuxiang(player, dying)
    return player:objectName() ~= dying.who:objectName() and player:getMark('@LuaZhujunJuxiang') > 0
end

-- 与界祝融【巨象】命名区分
LuaZhujunJuxiang = sgs.CreateTriggerSkill {
    name = 'LuaZhujunJuxiang',
    events = {sgs.QuitDying},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaZhujunJuxiang',
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local data2 = sgs.QVariant()
        data2:setValue(dying.who)
        if dying.who:isDead() then
            return false
        end
        for _, zhujun in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if canInvokeLuaZhujunJuxiang(zhujun, dying) and room:askForSkillInvoke(zhujun, self:objectName(), data2) then
                room:broadcastSkillInvoke(self:objectName())
                zhujun:loseMark('@LuaZhujunJuxiang')
                room:doAnimate(rinsan.ANIMATE_INDICATE, zhujun:objectName(), dying.who:objectName())
                rinsan.doDamage(zhujun, dying.who, 1)
                zhujun:drawCards(math.min(dying.who:getMaxHp(), 5), self:objectName())
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

local function canInvokeLuaHoufeng(zhujun, player)
    if not rectification.canBeAskedForRetification(player) then
        return false
    end
    return zhujun:getMark('LuaHoufeng_lun') == 0 and zhujun:inMyAttackRange(player)
end

LuaHoufeng = sgs.CreateTriggerSkill {
    name = 'LuaHoufeng',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local data2 = sgs.QVariant()
        data2:setValue(player)
        for _, zhujun in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if canInvokeLuaHoufeng(zhujun, player) then
                if room:askForSkillInvoke(zhujun, self:objectName(), data2) then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:doAnimate(rinsan.ANIMATE_INDICATE, zhujun:objectName(), player:objectName())
                    room:addPlayerMark(zhujun, 'LuaHoufeng_lun')
                    rectification.askForRetification(zhujun, player, self:objectName(), true)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getPhase() == sgs.Player_Play
    end,
}

ExZhujun:addSkill(LuaYangjie)
ExZhujun:addSkill(LuaZhujunJuxiang)
ExZhujun:addSkill(LuaHoufeng)

-- 皇甫嵩
ExHuangfusong = sgs.General(extension, 'ExHuangfusong', 'qun', '4', true, true)

local NUMBERS = {
    [1] = 'A',
    [2] = '2',
    [3] = '3',
    [4] = '4',
    [5] = '5',
    [6] = '6',
    [7] = '7',
    [8] = '8',
    [9] = '9',
    [10] = '10',
    [11] = 'J',
    [12] = 'Q',
    [13] = 'K',
}

LuaTaoluan = sgs.CreateTriggerSkill {
    name = 'LuaTaoluan',
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.card:getSuit() == sgs.Card_Spade and player:getMark(self:objectName() .. '-Clear') == 0 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local taoluan_choices = {'LuaTaoluanObtain'}
                if judge.who:objectName() ~= player:objectName() then
                    table.insert(taoluan_choices, 'LuaTaoluanFireSlash')
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(taoluan_choices, '+'))
                if choice == 'LuaTaoluanObtain' then
                    player:obtainCard(judge.card)
                else
                    room:addPlayerMark(player, self:objectName() .. '-Clear')
                    local fire_slash = sgs.Sanguosha:cloneCard('fire_slash', sgs.Card_NoSuit, 0)
                    fire_slash:setSkillName('_' .. self:objectName())
                    room:useCard(sgs.CardUseStruct(fire_slash, player, judge.who))
                end
                local suit = room:askForSuit(player, self:objectName())
                local card = sgs.Sanguosha:getWrappedCard(judge.card:getId())
                local number_str = room:askForChoice(player, self:objectName(), table.concat(NUMBERS, '+'))
                local number = getPos(NUMBERS, number_str)
                card:setSkillName(self:objectName())
                card:setSuit(suit)
                card:setNumber(number)
                card:setModified(true)
                room:broadcastUpdateCard(room:getAllPlayers(true), judge.card:getId(), card)
                judge:updateResult()
            end
        end
        return false
    end,
}

LuaShiji = sgs.CreateTriggerSkill {
    name = 'LuaShiji',
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Normal or damage.to:objectName() == player:objectName() then
            return false
        end
        local currCount = player:getHandcardNum()
        local canInvoke = false
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getHandcardNum() >= currCount then
                canInvoke = true
                break
            end
        end
        if canInvoke then
            local data2 = sgs.QVariant()
            data2:setValue(damage.to)
            if room:askForSkillInvoke(player, self:objectName(), data2) then
                room:broadcastSkillInvoke(self:objectName())
                room:showAllCards(damage.to, player)
                room:getThread():delay(500)
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                for _, cd in sgs.qlist(damage.to:getHandcards()) do
                    if cd:isRed() then
                        dummy:addSubcard(cd)
                    end
                end
                local len = dummy:subcardsLength()
                room:clearAG(player)
                if len > 0 then
                    room:throwCard(dummy, damage.to, player)
                    player:drawCards(len, self:objectName())
                end
            end
        end
    end,
}

LuaZhengjun = sgs.CreateTriggerSkill {
    name = 'LuaZhengjun',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if not rectification.canBeAskedForRetification(player) then
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), 1)
            rectification.askForRetification(player, player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaTaoluanFix = sgs.CreateTriggerSkill {
    name = 'LuaTaoluanFix',
    events = {sgs.PreCardUsed, sgs.PreCardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.PreCardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:getSkillName() == 'LuaTaoluan' and not card:isVirtualCard() then
            room:filterCards(player, player:getCards('he'), true)
            if event == sgs.PreCardUsed then
                local use = data:toCardUse()
                use.card = sgs.Sanguosha:getCard(use.card:getEffectiveId())
                data:setValue(use)
            else
                local resp = data:toCardResponse()
                resp.m_card = sgs.Sanguosha:getCard(resp.m_card:getEffectiveId())
                data:setValue(resp)
            end
        end
    end,
}

ExHuangfusong:addSkill(LuaTaoluan)
ExHuangfusong:addSkill(LuaShiji)
ExHuangfusong:addSkill(LuaZhengjun)
table.insert(hiddenSkills, LuaTaoluanFix)

rinsan.addHiddenSkills(hiddenSkills)
