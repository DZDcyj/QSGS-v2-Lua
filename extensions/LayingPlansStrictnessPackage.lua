-- 始计篇-严包
-- Created by DZDcyj at 2023/2/27
module('extensions.LayingPlansStrictnessPackage', package.seeall)
extension = sgs.Package('LayingPlansStrictnessPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')
local rectification = require('extensions.RectificationPackage')

-- 吕范
ExLvfan = sgs.General(extension, 'ExLvfan', 'wu', '3', true, true)

LuaDiaoduCard = sgs.CreateSkillCard {
    name = 'LuaDiaodu',
    target_fixed = false,
    will_throw = false,
    filter = function(self, selected, to_select)
        if #selected == 0 then
            -- 选择起始，要求必须有装备
            return to_select:hasEquip()
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
        rinsan.askForMoveCards(source, from, to, self:objectName())
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
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), 1)
            rectification.askForRetification(player, player, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end
}

ExLvfan:addSkill(LuaDiaodu)
ExLvfan:addSkill(LuaDiancai)
ExLvfan:addSkill(LuaYanji)

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
rinsan.addSingleHiddenSkill(LuaTaoluanFix)
