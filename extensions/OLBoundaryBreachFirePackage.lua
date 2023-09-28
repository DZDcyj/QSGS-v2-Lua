-- OL-界限突破-火包
-- Created by DZDcyj at 2023/5/5
module('extensions.OLBoundaryBreachFirePackage', package.seeall)
extension = sgs.Package('OLBoundaryBreachFirePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- 界卧龙诸葛
JieWolong = sgs.General(extension, 'JieWolong', 'shu', '3', true, true)

LuaBazhen = sgs.CreateTriggerSkill {
    name = 'LuaBazhen',
    events = {sgs.CardAsked},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local pattern = data:toStringList()[1]
        if pattern ~= 'jink' then
            return false
        end
        if room:askForSkillInvoke(player, 'eight_diagram', data) then
            room:setEmotion(player, 'armor/eight_diagram')
            local judge = rinsan.createJudgeStruct({
                ['pattern'] = '.|red',
                ['who'] = player,
                ['play_animation'] = true,
                ['reason'] = 'eight_diagram',
            })
            room:judge(judge)
            if judge:isGood() then
                local jink = sgs.Sanguosha:cloneCard('jink', sgs.Card_NoSuit, 0)
                -- PreCardResponded 无法中止技能音效，手动换成另外技能名称，重新播放对应语音
                jink:setSkillName('LuaBazhenJink')
                room:provide(jink)
                return true
            end
            room:setTag('ArmorJudge', sgs.QVariant('eight_diagram'))
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and (not target:getArmor()) and rinsan.hasArmorEffect(target, 'eight_diagram')
    end,
}

LuaBazhenDraw = sgs.CreateTriggerSkill {
    name = 'LuaBazhenDraw',
    events = {sgs.FinishJudge},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.reason == 'eight_diagram' and judge:isBad() then
            room:sendCompulsoryTriggerLog(player, 'LuaBazhen')
            player:drawCards(1, 'LuaBazhen')
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target, 'LuaBazhen')
    end,
}

LuaHuojiVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaHuoji',
    filter_pattern = '.|red|.',
    response_or_use = true,
    view_as = function(self, card)
        local fireAttack = sgs.Sanguosha:cloneCard('fire_attack', card:getSuit(), card:getNumber())
        fireAttack:addSubcard(card)
        fireAttack:setSkillName(self:objectName())
        return fireAttack
    end,
}

LuaFireAttack = sgs.CreateTrickCard {
    name = 'fire_attack',
    class_name = 'FireAttack',
    subtype = 'single_target_trick',
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    filter = function(self, selected, to_select)
        return #selected == 0 and not to_select:isKongcheng()
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        if target:isKongcheng() then
            return
        end
        local toShow = target:getHandcards():at(rinsan.random(0, target:getHandcardNum() - 1))
        room:showCard(target, toShow:getEffectiveId())
        local toDiscard

        local card_ids = room:getNCards(4)
        room:fillAG(card_ids, source)
        local to_return = sgs.IntList()
        for _, id in sgs.qlist(card_ids) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:getSuit() ~= toShow:getSuit() then
                to_return:append(id)
            end
        end
        for _, id in sgs.qlist(to_return) do
            card_ids:removeOne(id)
            room:takeAG(nil, id, false)
        end
        if not card_ids:isEmpty() then
            repeat
                local card_id = room:askForAG(source, card_ids, true, self:objectName())
                if card_id == -1 then
                    room:clearAG(source)
                    break
                end
                card_ids:removeOne(card_id)
                room:takeAG(source, card_id, false)
                toDiscard = sgs.Sanguosha:getCard(card_id)
            until true
        end
        for _, id in sgs.qlist(card_ids) do
            to_return:append(id)
        end
        room:returnToTopDrawPile(to_return)
        room:clearAG(source)
        local pattern = string.format('.|%s|.|hand', rinsan.getColorString(toShow))
        local prompt = string.format('@LuaHuoji-Discard:%s::%s', target:objectName(), rinsan.getColorString(toShow))
        toDiscard = toDiscard or room:askForCard(source, pattern, prompt, sgs.QVariant(), sgs.Card_MethodNone)
        if toDiscard then
            room:throwCard(toDiscard, source)
            rinsan.doDamage(source, target, 1, sgs.DamageStruct_Fire, self)
        end
    end,
}

LuaHuoji = sgs.CreateTriggerSkill {
    name = 'LuaHuoji',
    events = {sgs.CardEffected},
    view_as_skill = LuaHuojiVS,
    global = true,
    priority = 100,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        local card = effect.card
        local source = effect.from
        if card and card:isKindOf('FireAttack') then
            if not source:hasSkill(self:objectName()) then
                return false
            end
            room:sendCompulsoryTriggerLog(source, self:objectName())
            local fireAttack = LuaFireAttack:clone()
            fireAttack:addSubcard(effect.card)
            fireAttack:setSuit(effect.card:getSuit())
            fireAttack:setNumber(effect.card:getNumber())
            fireAttack:setId(effect.card:getId())
            effect.card = fireAttack
            data:setValue(effect)
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaKanpoVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaKanpo',
    filter_pattern = '.|black|.',
    response_pattern = 'nullification',
    response_or_use = true,
    view_as = function(self, card)
        local nullification = sgs.Sanguosha:cloneCard('nullification', card:getSuit(), card:getNumber())
        nullification:addSubcard(card)
        nullification:setSkillName(self:objectName())
        return nullification
    end,
    enabled_at_nullification = function(self, player)
        for _, cd in sgs.qlist(player:getCards('he')) do
            if cd:isBlack() then
                return true
            end
        end
        for _, id in sgs.qlist(player:getPile('wooden_ox')) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:isBlack() then
                return true
            end
        end
        return false
    end,
}

LuaKanpo = sgs.CreateTriggerSkill {
    name = 'LuaKanpo',
    events = {sgs.TrickCardCanceling},
    view_as_skill = LuaKanpoVS,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        if rinsan.RIGHT(self, effect.from) and effect.card:isKindOf('Nullification') then
            local index = rinsan.random(1, 2)
            if effect.from:getMark('LuaOLNiepanAcquiredLuaKanpo') > 0 then
                index = rinsan.random(3, 4)
            end
            SendComLog(self, effect.from, index)
            return true
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

LuaCangzhuo = sgs.CreateTriggerSkill {
    name = 'LuaCangzhuo',
    events = {sgs.CardUsed, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('TrickCard') then
                room:addPlayerMark(player, 'LuaCangzhuoUsedTrick-Clear')
            end
            return false
        end
        if player:getMark('LuaCangzhuoUsedTrick-Clear') > 0 then
            room:setPlayerMark(player, 'LuaCangzhuoUsedTrick-Clear', 0)
            return false
        end
        if event == sgs.AskForGameruleDiscard then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(player, self:objectName())
        end
        local n = room:getTag('DiscardNum'):toInt()
        for _, id in sgs.qlist(player:handCards()) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:isKindOf('TrickCard') then
                if event == sgs.AskForGameruleDiscard then
                    n = n - 1
                    room:setPlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString(), false)
                else
                    room:removePlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString() .. '$0')
                end
            end
        end
        room:setTag('DiscardNum', sgs.QVariant(n))
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTNOTATPHASE(self, target, sgs.Player_NotActive)
    end,
}

LuaCangzhuoMaxCards = sgs.CreateMaxCardsSkill {
    name = 'LuaCangzhuoMaxCards',
    extra_func = function(self, target)
        local x = 0
        if target:getMark('LuaCangzhuoUsedTrick-Clear') > 0 then
            return 0
        end
        if not target:hasSkill('LuaCangzhuo') then
            return 0
        end
        for _, cd in sgs.qlist(target:getHandcards()) do
            if cd:isKindOf('TrickCard') then
                x = x + 1
            end
        end
        -- 迫真多余牌修正
        return target:getHandcardNum() > target:getHp() and 0 or x
    end,
}

JieWolong:addSkill(LuaBazhen)
JieWolong:addSkill(LuaHuoji)
JieWolong:addSkill(LuaKanpo)
JieWolong:addSkill(LuaCangzhuo)
table.insert(hiddenSkills, LuaCangzhuoMaxCards)
table.insert(hiddenSkills, LuaBazhenDraw)

-- 界庞统
OLJiePangtong = sgs.General(extension, 'OLJiePangtong', 'shu', '3', true, true)

LuaOLLianhuan = sgs.CreateOneCardViewAsSkill {
    name = 'LuaOLLianhuan',
    filter_pattern = '.|club|.|hand',
    view_as = function(self, card)
        local chain = sgs.Sanguosha:cloneCard('iron_chain', sgs.Card_NoSuit, 0)
        chain:addSubcard(card)
        chain:setSkillName(self:objectName())
        return chain
    end,
}

LuaOLLianhuanTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaOLLianhuan',
    pattern = 'IronChain',
    extra_target_func = function(self, from)
        if from:hasSkill('LuaOLLianhuan') then
            return 1
        end
        return 0
    end,
}

NIEPAN_SKILLS = {'LuaBazhen', 'LuaHuoji', 'LuaKanpo'}

LuaOLNiepan = sgs.CreateTriggerSkill {
    name = 'LuaOLNiepan',
    frequency = sgs.Skill_Limited,
    events = {sgs.AskForPeaches},
    limit_mark = '@nirvana',
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying_data = data:toDying()
        local source = dying_data.who
        if source:objectName() == player:objectName() then
            if player:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:loseMark('@nirvana')
                -- 弃置所有牌
                player:throwAllCards()

                -- 复原武将牌
                if player:isChained() then
                    local damage = dying_data.damage
                    if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
                        room:setPlayerProperty(player, 'chained', sgs.QVariant(false))
                    end
                end
                if not player:faceUp() then
                    player:turnOver()
                end
                -- 摸三张牌
                player:drawCards(3)

                -- 回复至三点体力
                local maxhp = player:getMaxHp()
                local hp = math.min(3, maxhp)
                rinsan.recover(player, hp - player:getHp())

                -- 选择技能获得
                local skills = {}
                for _, skill in ipairs(NIEPAN_SKILLS) do
                    if not player:hasSkill(skill) then
                        table.insert(skills, skill)
                    end
                end
                if #skills == 0 then
                    return false
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(skills, '+'))
                room:acquireSkill(player, choice)
                room:addPlayerMark(player, 'LuaOLNiepanAcquired' .. choice)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getMark('@nirvana') > 0
    end,
}

LuaFengchuMute = sgs.CreateTriggerSkill {
    name = 'LuaFengchuMute',
    events = {sgs.PreCardUsed, sgs.PreCardResponded},
    global = true,
    priority = 1,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.PreCardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if not card then
            return false
        end
        local skill = card:getSkillName()
        if skill == 'LuaHuoji' then
            room:notifySkillInvoked(player, skill)
            if player:getMark('LuaOLNiepanAcquiredLuaHuoji') > 0 then
                room:broadcastSkillInvoke(skill, rinsan.random(3, 4))
            else
                room:broadcastSkillInvoke(skill, rinsan.random(1, 2))
            end
            return true
        end
        if skill == 'LuaKanpo' then
            room:notifySkillInvoked(player, skill)
            if player:getMark('LuaOLNiepanAcquiredLuaKanpo') > 0 then
                room:broadcastSkillInvoke(skill, rinsan.random(3, 4))
            else
                room:broadcastSkillInvoke(skill, rinsan.random(1, 2))
            end
            return true
        end
        if skill == 'LuaBazhenJink' then
            room:notifySkillInvoked(player, 'LuaBazhen')
            if player:getMark('LuaOLNiepanAcquiredLuaBazhen') > 0 then
                room:broadcastSkillInvoke('LuaBazhen', rinsan.random(3, 4))
            else
                room:broadcastSkillInvoke('LuaBazhen', rinsan.random(1, 2))
            end
            return true
        end
    end,
}

OLJiePangtong:addSkill(LuaOLLianhuan)
OLJiePangtong:addSkill(LuaOLNiepan)
OLJiePangtong:addRelateSkill('LuaBazhen')
OLJiePangtong:addRelateSkill('LuaHuoji')
OLJiePangtong:addRelateSkill('LuaKanpo')
table.insert(hiddenSkills, LuaOLLianhuanTargetMod)
table.insert(hiddenSkills, LuaFengchuMute)

-- 界典韦
OLJieDianwei = sgs.General(extension, 'OLJieDianwei', 'wei', '4', true, true)

LuaOLQiangxiCard = sgs.CreateSkillCard {
    name = 'LuaOLQiangxi',
    target_fixed = false,
    will_throw = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0) and to_select:getMark('LuaOLQiangxi_biu') == 0
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        room:notifySkillInvoked(source, self:objectName())
        if self:subcardsLength() == 0 then
            rinsan.doDamage(nil, source, 1)
        end
        rinsan.doDamage(source, target, 1)
        room:addPlayerMark(target, 'LuaOLQiangxi_biu')
    end,
}

LuaOLQiangxi = sgs.CreateViewAsSkill {
    name = 'LuaOLQiangxi',
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf('Weapon')
    end,
    view_as = function(self, cards)
        local vs_card = LuaOLQiangxiCard:clone()
        if #cards == 1 then
            vs_card:addSubcard(cards[1])
        end
        return vs_card
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#LuaOLQiangxi') < 2
    end,
}

local function doNinge(jiedianwei)
    local room = jiedianwei:getRoom()
    room:sendCompulsoryTriggerLog(jiedianwei, 'LuaOLNinge')
    room:broadcastSkillInvoke('LuaOLNinge')
    jiedianwei:drawCards(1, 'LuaOLNinge')
    local targets = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if rinsan.canDiscard(jiedianwei, p, 'hej') then
            targets:append(p)
        end
    end
    if targets:isEmpty() then
        return
    end
    local target = room:askForPlayerChosen(jiedianwei, targets, 'LuaOLNinge', '@LuaOLNinge-choose', false)
    if target and rinsan.canDiscard(jiedianwei, target, 'hej') then
        room:doAnimate(rinsan.ANIMATE_INDICATE, jiedianwei:objectName(), target:objectName())
        local card_id = room:askForCardChosen(jiedianwei, target, 'hej', 'LuaOLNinge', false, sgs.Card_MethodDiscard)
        room:throwCard(card_id, target, jiedianwei)
    end
end

LuaOLNinge = sgs.CreateTriggerSkill {
    name = 'LuaOLNinge',
    events = {sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        room:addPlayerMark(player, self:objectName() .. '-Clear')
        if player:getMark(self:objectName() .. '-Clear') ~= 2 then
            return false
        end
        if rinsan.RIGHT(self, damage.from) then
            doNinge(damage.from)
        end
        if rinsan.RIGHT(self, damage.to) then
            doNinge(damage.to)
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

OLJieDianwei:addSkill(LuaOLQiangxi)
OLJieDianwei:addSkill(LuaOLNinge)

-- 界荀彧
OLJieXunyu = sgs.General(extension, 'OLJieXunyu', 'wei', '3', true, true)

-- 封装函数【节命】OL
-- 返回值代表是否成功发动【节命】
local function doJiemingDrawDiscard(player)
    local room = player:getRoom()
    local alives = room:getAlivePlayers()
    if alives:isEmpty() then
        return false
    end
    local target = room:askForPlayerChosen(player, alives, 'LuaOLJieming', 'jieming-invoke', true, true)
    if target then
        room:broadcastSkillInvoke('LuaOLJieming')
        local x = math.min(5, target:getMaxHp())
        target:drawCards(x, 'LuaOLJieming')
        local diff = target:getHandcardNum() - x
        if diff > 0 then
            room:askForDiscard(target, 'LuaOLJieming', diff, diff)
        end
    end
    return target ~= nil
end

LuaOLJieming = sgs.CreateTriggerSkill {
    name = 'LuaOLJieming',
    events = {sgs.Death, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                doJiemingDrawDiscard(player)
            end
        else
            if not player:isAlive() then
                return false
            end
            local damage = data:toDamage()
            local i = 0
            while i < damage.damage do
                i = i + 1
                if not doJiemingDrawDiscard(player) then
                    break
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

OLJieXunyu:addSkill('LuaQuhu')
OLJieXunyu:addSkill(LuaOLJieming)

rinsan.addHiddenSkills(hiddenSkills)
