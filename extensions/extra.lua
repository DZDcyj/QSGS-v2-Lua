extension = sgs.Package('extra', sgs.Package_GeneralPack)
extension_z = sgs.Package('zhongcheng', sgs.Package_GeneralPack)
extension_pm = sgs.Package('pigmonkey', sgs.Package_GeneralPack)
extension_god = sgs.Package('god_ol', sgs.Package_GeneralPack)
extension_ol = sgs.Package('ol_heg', sgs.Package_GeneralPack)
extension6 = sgs.Package('yijiang6', sgs.Package_GeneralPack)
extension7 = sgs.Package('yijiang7', sgs.Package_GeneralPack)
extension_sp = sgs.Package('ol_sp', sgs.Package_GeneralPack)
extension_friend = sgs.Package('friend', sgs.Package_GeneralPack)
card_slash = sgs.Package('jiaozhao', sgs.Package_CardPack)
extension_bf = sgs.Package('bianfeng', sgs.Package_GeneralPack)
extension_yijiang = sgs.Package('ol_yijiang', sgs.Package_GeneralPack)
extension_mobile = sgs.Package('mobile', sgs.Package_GeneralPack)
extension_hulaoguan = sgs.Package('ol_hulaoguan', sgs.Package_GeneralPack)
extension_exam = sgs.Package('god_exam', sgs.Package_GeneralPack)
extension_star = sgs.Package('firexiongxiongxiong', sgs.Package_GeneralPack)
extension_yin = sgs.Package('yin', sgs.Package_GeneralPack)
extension_lei = sgs.Package('lei', sgs.Package_GeneralPack)
math.random()

-- 仅限于本文件不检查单行长度
-- luacheck: push ignore 631

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- sgs.Sanguosha:playAudioEffect('audio/system/bgm'..math.random(10)..'.ogg', false)
-- 感谢myetyet大神和Ho-spair大神的帮忙使得阴雷星火燎原的进度加速
axe_bug = sgs.CreateTriggerSkill {
    name = 'axe_bug',
    global = true,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) or
            (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip))) then
            if player:hasSkill('axe') then
                room:detachSkillFromPlayer(player, 'axe', true)
            end
        end
        return false
    end,
}
clearAG = sgs.CreateTriggerSkill {
    name = 'clearAG',
    global = true,
    events = {sgs.CardEffected},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        if effect.card and effect.card:isKindOf('AmazingGrace') and room:getTag('AmazingGrace'):toIntList():length() == 0 then
            return true
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
turn_length = sgs.CreateTriggerSkill {
    name = 'turn_length',
    global = true,
    events = {sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        local n = 15
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            n = math.min(p:getSeat(), n)
        end
        if player:getSeat() == n and not room:getTag('ExtraTurn'):toBool() then
            room:setPlayerMark(player, '@clock_time', room:getTag('TurnLengthCount'):toInt() + 1)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                for _, mark in sgs.list(p:getMarkNames()) do
                    if string.find(mark, '_lun') and p:getMark(mark) > 0 then
                        room:setPlayerMark(p, mark, 0)
                    end
                end
            end
        end
        return false
    end,
}
Maxcards = sgs.CreateMaxCardsSkill {
    name = 'Maxcards',
    extra_func = function(self, target)
        local n = 0
        if target:hasSkill('jugu') then
            n = n + target:getMaxHp()
        end
        if target:hasSkill('jieying') and target:isChained() then
            n = n + 2
        end
        if target:hasSkill('jieyingy') and target:getMark('@thiefed') > 0 then
            n = n + 1
        end
        for _, p in sgs.qlist(target:getAliveSiblings()) do
            if p:hasSkill('jieying') and target:isChained() then
                n = n + 2
            end
        end
        for _, p in sgs.qlist(target:getAliveSiblings()) do
            if p:hasSkill('jieyingy') and target:getMark('@thiefed') > 0 then
                n = n + 1
            end
        end
        for _, p in sgs.qlist(target:getAliveSiblings()) do
            if not p:isYourFriend(target) and p:hasSkill('shenen') then
                n = n + 1
            end
        end
        for _, p in sgs.qlist(target:getAliveSiblings()) do
            if p:hasSkill('zhiti') and p:inMyAttackRange(target) and target:isWounded() then
                n = n - 1
            end
        end
        if target:hasSkill('zhiti') and target:isWounded() then
            n = n - 1
        end
        if target:hasSkill('pizhuan') then
            n = n + target:getPile('book'):length()
        end
        if target:getMark('jueyan1-Clear') > 0 then
            n = n + 3
        end
        if target:hasFlag('poxi') then
            n = n - 1
        end
        if target:getMark('@hulaoguan') > 0 and target:hasSkill('shenwei') then
            n = n + 1
        end
        return target:getMark('@Maxcards') + target:getMark('@Maxcards-Clear') - target:getMark('@zhongjian') -
                   target:getMark('@jishe-Clear') + target:getMark('@ol_mingjian_flag') + n
    end,
}
clear_mark = sgs.CreateTriggerSkill {
    name = 'clear_mark',
    global = true,
    priority = -100,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, splayer, data, room)
        local change = data:toPhaseChange()
        for _, player in sgs.qlist(room:getAlivePlayers()) do
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, '_biu') and player:getMark(mark) > 0 then
                    room:setPlayerMark(player, mark, 0)
                end
            end
        end
        if change.to == sgs.Player_NotActive then
            for _, player in sgs.qlist(room:getAlivePlayers()) do
                for _, skill in sgs.qlist(player:getSkillList(false, false)) do
                    if string.find(skill:objectName(), '_clear') then
                        room:detachSkillFromPlayer(player, skill:objectName(), true)
                        room:filterCards(player, player:getCards('h'), true)
                    end
                end
                if player:getMark('ol_huxiao-Clear') > 0 then
                    local assignee_list = room:getCurrent():property('extra_slash_specific_assignee'):toString():split('+')
                    table.removeOne(assignee_list, player:objectName())
                    room:setPlayerProperty(room:getCurrent(), 'extra_slash_specific_assignee',
                        sgs.QVariant(table.concat(assignee_list, '+')))
                end
                if player:getMark('funan-Clear') > 0 then
                    room:removePlayerCardLimitation(player, 'use,response', card:toString())
                end
                if player:getMark('@weilu-Clear') > 0 then
                    room:recover(player, sgs.RecoverStruct(player, nil, player:getMark('@weilu-Clear')))
                end
                if player:getMark('ban_ur') > 0 then
                    room:removePlayerMark(player, 'ban_ur')
                    room:removePlayerCardLimitation(player, 'use,response', '.|.|.|hand')
                end
                for _, mark in sgs.list(player:getMarkNames()) do
                    if player:getMark(mark) > 0 and string.find(mark, '_skillClear') then
                        if player:hasSkill(string.sub(mark, 1, string.len(mark) - 11)) then
                            room:detachSkillFromPlayer(player, string.sub(mark, 1, string.len(mark) - 11))
                            room:filterCards(player, player:getCards('h'), true)
                        end
                        room:setPlayerMark(player, mark, 0)
                    end
                    if splayer:objectName() == player:objectName() then
                        if string.find(mark, '_flag') and player:getMark(mark) > 0 then
                            room:setPlayerMark(player, mark, 0)
                        end
                        if string.find(mark, '_manmanlai') and player:getMark(mark) > 0 then
                            room:removePlayerMark(player, mark)
                        end
                        local duoruis = {}
                        for _, skill in sgs.qlist(player:getVisibleSkillList()) do
                            if player:getMark('Duorui' .. skill:objectName() .. 'from') > 0 then
                                table.insert(duoruis, '-' .. skill:objectName())
                            end
                        end
                        if #duoruis > 0 then
                            room:handleAcquireDetachSkills(player, table.concat(duoruis, '|'))
                        end
                        for _, skill in sgs.qlist(player:getVisibleSkillList()) do
                            if player:getMark('Duorui' .. skill:objectName()) > 0 then
                                room:removePlayerMark(player, 'Qingcheng' .. skill:objectName())
                                room:removePlayerMark(player, 'Duorui' .. skill:objectName())
                            end
                        end
                    end
                    if string.find(mark, '-Clear') and player:getMark(mark) > 0 then
                        if mark == 'turnOver-Clear' and player:getMark('turnOver-Clear') > 1 and player:faceUp() then
                            room:addPlayerMark(player, 'stop')
                        end
                        if string.find(mark, 'funan') then
                            room:removePlayerCardLimitation(player, 'use,response', sgs.Sanguosha:getCard(
                                tonumber(string.sub(mark, 6, string.len(mark) - 6))):toString())
                        end
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        elseif change.to == sgs.Player_Play then
            for _, player in sgs.qlist(room:getAlivePlayers()) do
                for _, mark in sgs.list(player:getMarkNames()) do
                    if splayer:objectName() == player:objectName() and string.find(mark, '_play') and player:getMark(mark) >
                        0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                    if string.find(mark, '_Play') and player:getMark(mark) > 0 then
                        if mark == 'zhongjian_Play' then
                            sgs.Sanguosha:addTranslationEntry(':zhongjian',
                                '' ..
                                    string.gsub(sgs.Sanguosha:translate(':zhongjian'), sgs.Sanguosha:translate(':zhongjian'),
                                        sgs.Sanguosha:translate(':zhongjian')))
                        end
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        elseif change.to == sgs.Player_Discard then
            for _, player in sgs.qlist(room:getAlivePlayers()) do
                if room:getCurrent():objectName() == player:objectName() then
                    for _, card in sgs.list(player:getHandcards()) do
                        if player:getMark('luoshen' .. card:getId() .. '-Clear') > 0 then
                            room:setPlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(card:getId()):toString(),
                                false)
                        end
                    end
                end
            end
        elseif change.to == sgs.Player_Start then
            if splayer:getMark('ol_hunshang-Clear') > 0 and change.to == sgs.Player_Start and splayer:isWounded() then
                local to = room:askForPlayerChosen(splayer, room:getOtherPlayers(splayer), 'yinghun', 'yinghun-invoke', true,
                    true)
                local x = splayer:getLostHp()
                local choices = {'yinghun1'}
                if to then
                    if not to:isNude() and x ~= 1 then
                        table.insert(choices, 'yinghun2')
                    end
                    local choice = room:askForChoice(splayer, 'yinghun', table.concat(choices, '+'))
                    ChoiceLog(splayer, choice)
                    if choice == 'yinghun1' then
                        to:drawCards(1)
                        room:askForDiscard(to, self:objectName(), x, x, false, true)
                        room:broadcastSkillInvoke('yinghun', 3)
                    else
                        to:drawCards(x)
                        room:askForDiscard(to, self:objectName(), 1, 1, false, true)
                        room:broadcastSkillInvoke('yinghun', 4)
                    end
                end
            end
        elseif change.to == sgs.Player_RoundStart then
            for _, player in sgs.qlist(room:getAlivePlayers()) do
                if room:getCurrent():objectName() == player:objectName() then
                    room:addPlayerMark(player, 'turn')
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
turn_clear = sgs.CreatePhaseChangeSkill {
    name = 'turn_clear',
    global = true,
    priority = 0,
    on_phasechange = function(self, splayer)
        local room = splayer:getRoom()
        for _, player in sgs.qlist(room:getAlivePlayers()) do
            if player:getPhase() == sgs.Player_RoundStart then
                if splayer:objectName() == player:objectName() then
                    for _, skill in sgs.qlist(player:getVisibleSkillList()) do
                        if player:getMark('Duorui' .. skill:objectName()) > 0 then
                            room:addPlayerMark(player, 'Qingcheng' .. skill:objectName())
                        end
                    end
                end
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, '_start') and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        end
    end,
}
end_clear = sgs.CreateTriggerSkill {
    name = 'end_clear',
    global = true,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, splayer, data, room)
        if splayer:getPhase() == sgs.Player_Discard then
            for _, player in sgs.qlist(room:getAlivePlayers()) do
                if room:getCurrent():objectName() == player:objectName() then
                    for _, card in sgs.list(player:getHandcards()) do
                        if player:getMark('luoshen' .. card:getId() .. '-Clear') > 0 then
                            room:removePlayerCardLimitation(player, 'discard',
                                sgs.Sanguosha:getCard(card:getId()):toString() .. '$0')
                        end
                    end
                end
            end
        elseif splayer:getPhase() == sgs.Player_Play then
            for _, player in sgs.qlist(room:getAlivePlayers()) do
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, '_replay') and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                        if mark == 'wanglie_replay' then
                            room:removePlayerCardLimitation(player, 'use, response', '.|.|.|hand')
                        end
                    end
                end
            end
        end
    end,
}
slashmore = sgs.CreateTargetModSkill {
    name = 'slashmore',
    pattern = '.',
    residue_func = function(self, from, card, to)
        local n = 0
        for _, p in sgs.qlist(from:getAliveSiblings()) do
            if p:hasSkill('shenen') then
                n = n + 1000
            end
        end
        if card:isKindOf('Slash') then
            for _, p in sgs.qlist(from:getAliveSiblings()) do
                if p:hasSkill('jieyingy') and from:getMark('@thiefed') > 0 then
                    n = n + 1
                end
            end
            if from:hasSkill('jieyingy') and from:getMark('@thiefed') > 0 then
                n = n + 1
            end
            if from:getMark('@hulaoguan') > 0 and from:hasSkill('shenji') and not from:getWeapon() then
                n = n + 1
            end
            if from:hasSkill('huihuo') then
                n = n + 1
            end
            n = n + from:getMark('@Slash-Clear') + from:getMark('@qimou-Clear') + from:getMark('@ol_mingjian_flag')
        elseif card:isKindOf('Analeptic') then
            if from:getMark('ol_huxiao' .. from:objectName() .. '_me-Clear') > 0 then
                n = n + 1000
            end
        end
        if from:getMark('kuangcai_replay') > 0 then
            n = n + 1000
        end
        if from:hasSkill('ol_fentian') and card:isRed() then
            n = n + 1000
        end
        if from:getMark('jueyan0-Clear') > 0 and card:isKindOf('Slash') then
            n = n + 3
        end
        if card:getSkillName() == 'longnu_trick' then
            n = n + 1000
        end
        if from:getMark('chenglve' .. card:getSuitString() .. '-Clear') > 0 then
            n = n + 1000
        end
        if from:hasSkill('limu') and not from:getJudgingArea():isEmpty() and to and from:inMyAttackRange(to) then
            n = n + 1000
        end
        if to and to:getMark('ol_huxiao' .. from:objectName() .. '-Clear') > 0 then
            n = n + 1000
        end
        if from:getMark('fuck_caocao-Clear') > 0 and to and to:getMark('@be_fucked-Clear') > 0 then
            n = n + 1000
        end
        return n
    end,
    distance_limit_func = function(self, from, card, to)
        local n = 0
        if from:hasSkill('ol_fentian') and card:isRed() then
            n = n + 1000
        end
        if card:getSkillName() == 'ol_shensu' or card:getSkillName() == 'longnu_red' or card:getSkillName() == 'yingjian' or
            card:getSkillName() == 'shanjia' or from:getMark('kuangcai_replay') > 0 or from:getMark('sheyan') > 0 then
            n = n + 1000
        end
        for _, p in sgs.qlist(from:getAliveSiblings()) do
            if p:isYourFriend(from) and p:hasSkill('shenen') then
                n = n + 1000
            end
        end
        if from:getMark('used_Play') == 0 and from:hasSkill('wanglie') then
            n = n + 1000
        end
        if from:hasSkill('shenen') then
            n = n + 1000
        end
        if from:hasSkill('ol_liegong') then
            n = n + math.max(card:getNumber() - from:getAttackRange(), 0)
        end
        if from:getMark('jueyan2-Clear') > 0 then
            n = n + 1000
        end
        if sgs.GetConfig('starfire', true) and from:hasSkill('wusheng') and card and card:getSuit() == sgs.Card_Diamond and
            card:isKindOf('Slash') then
            n = n + 1000
        end
        if from:getMark('chenglve' .. card:getSuitString() .. '-Clear') > 0 then
            n = n + 1000
        end
        if card:isKindOf('SupplyShortage') and from:hasSkill('ol_duanliang') and to and to:getHandcardNum() >=
            from:getHandcardNum() then
            n = n + 1000
        end
        if from:hasSkill('limu') and not from:getJudgingArea():isEmpty() and to and from:inMyAttackRange(to) then
            n = n + 1000
        end
        if card:isKindOf('Slash') and from:getMark('paoxiao_buff-Clear') > 0 then
            n = n + 1000
        end
        if from:getMark('fuck_caocao-Clear') > 0 and to and to:getMark('@be_fucked-Clear') > 0 then
            -- 骜肆处理距离
            if from:getMark('LuaAosiInvoked_biu') > 0 and to and to:getMark('LuaAosi_biu') then
                if to and to:getMark('@be_fucked-Clear') == 1 then
                    n = n - 1000
                end
            end
            n = n + 1000
        end
        return n
    end,
}
distance = sgs.CreateDistanceSkill {
    name = 'distance',
    correct_func = function(self, from, to)
        local n = 0
        return to:getMark('@biluan') - from:getMark('@qimou-Clear') - to:getMark('@lixia') + n
    end,
}
mute_e = sgs.CreateTriggerSkill {
    name = 'mute_e',
    events = {sgs.PreCardUsed},
    global = true,
    priority = 1,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card then
            local skill = use.card:getSkillName()
            if skill == '_ol_rende' and use.card:isKindOf('BasicCard') then
                if use.from:isMale() then
                    room:broadcastSkillInvoke(use.card:objectName())
                else
                    sgs.Sanguosha:playAudioEffect('audio/card/female/' .. use.card:objectName() .. '.ogg', false)
                end
                return true
            end
            if player:hasSkill('ol_shichou') and use.card:isKindOf('Slash') and use.to:length() > 1 then
                room:broadcastSkillInvoke('ol_shichou')
            end
            if use.from:hasFlag(self:objectName()) then
                use.card:setSkillName('_' .. self:objectName())
                data:setValue(use)
                room:broadcastSkillInvoke(self:objectName(), 2)
            end
            if skill == 'jiewei' then
                room:broadcastSkillInvoke(skill, 2)
                return true
            end
            if skill == 'wusheng' and use.from:hasSkill('nosfuhun') and not use.from:hasInnateSkill('wusheng') then
                room:broadcastSkillInvoke('nosfuhun', 1)
                return true
            end
            if skill == 'dingpan' or skill == '_mizhao' or skill == 'duliang' or skill == '_ol_zhongyong' or skill == 'jiyu' or
                skill == 'kuangbi' or skill == 'fenyue' or skill == '_fenyue' or skill == 'shuimeng' or skill == '_shensu' or
                skill == 'shanjia' or skill == '_shanjia' or skill == 'jixu' or skill == 'qinguo' or skill == 'poxi' then
                return true
            end
        end
    end,
}
hand_skill = sgs.CreateTriggerSkill {
    name = 'hand_skill',
    events = {sgs.EventPhaseProceeding},
    global = true,
    priority = -1,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Discard then
            local extra = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == 'qun' then
                    extra = true
                end
            end
            if player:hasLordSkill('xueyi') and extra then
                room:sendCompulsoryTriggerLog(player, 'xueyi')
                if player:getGeneralName() == 'yuanshao_po' then
                    room:broadcastSkillInvoke('xueyi')
                end
            end
            if player:hasSkill('jugu') then
                room:sendCompulsoryTriggerLog(player, 'jugu')
                room:broadcastSkillInvoke('jugu', 1)
            end
            if player:hasSkill('zongshi') then
                room:sendCompulsoryTriggerLog(player, 'zongshi')
                room:broadcastSkillInvoke('zongshi')
            end
            if player:hasSkill('shenju') then
                room:sendCompulsoryTriggerLog(player, 'shenju')
                room:broadcastSkillInvoke('shenju')
            end
            if player:hasSkill('juejing') then
                room:sendCompulsoryTriggerLog(player, 'juejing')
            end
            if player:hasSkill('yingzi') then
                room:sendCompulsoryTriggerLog(player, 'yingzi')
            end
        end
    end,
}
ExtraCollateralCard = sgs.CreateSkillCard {
    name = 'ExtraCollateral',
    filter = function(self, targets, to_select)
        local coll = sgs.Card_Parse(sgs.Self:property('extra_collateral'):toString())
        if (not coll) then
            return false
        end
        local tos = sgs.Self:property('extra_collateral_current_targets'):toString():split('+')
        if #targets == 0 then
            return not table.contains(tos, to_select:objectName()) and not sgs.Self:isProhibited(to_select, coll) and
                       coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
        else
            return coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
        end
    end,
    about_to_use = function(self, room, use)
        local killer = use.to:first()
        local victim = use.to:last()
        killer:setFlags('ExtraCollateralTarget')
        local _data = sgs.QVariant()
        _data:setValue(victim)
        killer:setTag('collateralVictim', _data)
    end,
}
ExtraCollateral = sgs.CreateZeroCardViewAsSkill {
    name = 'ExtraCollateral',
    response_pattern = '@@ExtraCollateral',
    view_as = function()
        return ExtraCollateralCard:clone()
    end,
}
fulin_ex = sgs.CreateTriggerSkill {
    name = 'fulin_ex',
    global = true,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
            move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() then
            for _, id in sgs.qlist(move.card_ids) do
                room:addPlayerMark(player, 'fulin' .. id .. '-Clear')
            end
        end
        return false
    end,
}
banbanban = sgs.CreateProhibitSkill {
    name = '#banbanban',
    is_prohibited = function(self, from, to, card)
        return not card:isKindOf('SkillCard') and
                   ((card:getSkillName() == 'jiaozhao' and from:objectName() == to:objectName()) or
                       (from:hasSkill('caishi') and to:getMark('caishi-Clear') > 0) or
                       (from:getMark('juzhanFrom-Clear') > 0 and to:getMark('juzhanTo-Clear') > 0 and
                           not card:isKindOf('SkillCard')) or
                       ((not to:hasEquipArea(0) and card:isKindOf('Weapon')) or
                           (not to:hasEquipArea(1) and card:isKindOf('Armor')) or
                           (not to:hasEquipArea(2) and card:isKindOf('DefensiveHorse')) or
                           (not to:hasEquipArea(3) and card:isKindOf('OffensiveHorse')) or
                           (not to:hasEquipArea(4) and card:isKindOf('Treasure')) or
                           (not to:hasEquipArea() and card:isKindOf('EquipCard')) or
                           ((to:hasSkill('yinship') or to:hasSkill('qianjie') or to:hasSkill('zhenlve') or
                               not to:hasJudgeArea()) and card:isKindOf('DelayedTrick')))) or
                   card:hasFlag('lianji' .. to:objectName())
    end,
}
card_used = sgs.CreateTriggerSkill {
    name = 'card_used',
    events = {sgs.PreCardUsed, sgs.PreCardResponded},
    global = true,
    priority = -1,
    on_trigger = function(self, event, player, data, room)
        local card
        local invoke = true
        if event == sgs.PreCardUsed then
            card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                card = data:toCardResponse().m_card
            else
                invoke = false
            end
        end
        if card and not card:isKindOf('SkillCard') then
            if card:getSubcards():length() > 1 or
                (player:getMark('used_Play') > 0 and player:getMark('used-before-Clear') - 1 ~= card:getSuit()) or
                card:getSuit() > 3 then
                room:addPlayerMark(player, 'guanwei_break-Clear')
            end
            room:setPlayerMark(player, 'used-before-Clear', card:getSuit() + 1)
            if invoke then
                room:addPlayerMark(player, 'used-Clear')
                if player:getPhase() == sgs.Player_Play then
                    room:addPlayerMark(player, 'used_Play')
                end
            end
            room:addPlayerMark(player, 'us-Clear')
            if player:getPhase() == sgs.Player_Play then
                room:addPlayerMark(player, 'us_Play')
            end
            if card:isKindOf('Slash') then
                room:addPlayerMark(player, 'used_slash-Clear')
                if player:getPhase() == sgs.Player_Play then
                    room:addPlayerMark(player, 'used_slash_Play')
                end
            end
        end
        return false
    end,
}
kuangcai_buff = sgs.CreateTriggerSkill {
    name = 'kuangcai_buff',
    events = {sgs.CardUsed, sgs.CardResponded, sgs.DamageCaused},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            return player:getMark('kuangcai_replay') > 0 and sgs.GetConfig('kuangcai_change', true)
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf('SkillCard') and player:getPhase() == sgs.Player_Play then
                room:addPlayerMark(player, 'used_record-Clear')
                if player:getMark('kuangcai_replay') > 0 then
                    player:drawCards(1, self:objectName())
                    room:addPlayerMark(player, '@kuangcaidraw_Play')
                    if player:getMark('@kuangcaidraw_Play') >= 5 or
                        (sgs.GetConfig('kuangcai_change', true) and player:getMark('@kuangcaidraw_Play') >= 2) then
                        room:setPlayerFlag(player, 'Global_PlayPhaseTerminated')
                    end
                end
            end
        end
        return false
    end,
}
Fake_Move = sgs.CreateTriggerSkill {
    name = 'Fake_Move',
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
    priority = 10,
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:hasFlag('Fake_Move') then
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}

kuanshiing = sgs.CreateTriggerSkill {
    name = 'kuanshiing',
    events = {sgs.DamageInflicted},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage > 1 and (damage.to:getMark('@kuanshi_start') > 0 or damage.to:getMark('kuanshi_start') > 0) then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getMark('kuanshi' .. damage.to:objectName() .. damage.to:getMark('@kuanshi_start')) > 0 or
                    p:getMark('kuanshi' .. damage.to:objectName() .. damage.to:getMark('kuanshi_start')) then
                    if p:getMark('kuanshi' .. damage.to:objectName() .. damage.to:getMark('kuanshi_start')) > 0 then
                        ALLAPPEAR(room, damage.to, 'kuanshi_start', true)
                    end
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    room:sendCompulsoryTriggerLog(p, 'kuanshi')
                    room:removePlayerMark(damage.to, '@kuanshi_start')
                    room:removePlayerMark(p, 'kuanshi' .. damage.to:objectName() .. damage.to:getMark('@kuanshi_start'))
                    room:addPlayerMark(p, 'skip_draw')
                    return true
                end
            end
        end
    end,
}
skip = sgs.CreateTriggerSkill {
    name = 'skip',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_Draw and player:getMark('skip_draw') > 0 then
            room:removePlayerMark(player, 'skip_draw')
            player:skip(sgs.Player_Draw)
        end
    end,
}
damage_record = sgs.CreateTriggerSkill {
    name = 'damage_record',
    events = {sgs.DamageComplete},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toDamage().from then
            room:addPlayerMark(data:toDamage().from, self:objectName(), data:toDamage().damage)
            room:addPlayerMark(data:toDamage().from, self:objectName() .. '-Clear', data:toDamage().damage)
            if data:toDamage().from:getPhase() == sgs.Player_Play then
                room:addPlayerMark(data:toDamage().from, self:objectName() .. 'play-Clear', data:toDamage().damage)
            end
        end
    end,
}
skill_mark = sgs.CreateTriggerSkill {
    name = 'skill_mark',
    global = true,
    priority = 1,
    events = {sgs.PreCardUsed, sgs.JinkEffect, sgs.NullificationEffect, sgs.PreCardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:getSkillName() ~= '' and use.card:getSkillName() ~= 'fan' then
                room:addPlayerMark(use.from, use.card:getSkillName() .. 'engine')
                if use.from:getMark(use.card:getSkillName() .. 'engine') == 0 then
                    use.to = sgs.SPlayerList()
                    data:setValue(use)
                end
                room:removePlayerMark(use.from, use.card:getSkillName() .. 'engine')
            end
        elseif event == sgs.PreCardResponded then
            local res = data:toCardResponse()
            if res.m_card:isVirtualCard() then
                room:addPlayerMark(player, res.m_card:getSkillName() .. 'engine')
                if player:getMark(res.m_card:getSkillName() .. 'engine') == 0 then
                    room:setCardFlag(res.m_card, 'response_failed')
                end
                room:removePlayerMark(player, res.m_card:getSkillName() .. 'engine')
            end
        else
            local card
            if event == sgs.JinkEffect then
                card = data:toCard()
            else
                card = data:toCardEffect().card
            end
            if card and card:getSubcards():length() ~= 0 and not card:isKindOf('SkillCard') and card:isVirtualCard() then
                room:addPlayerMark(player, card:getSkillName() .. 'engine')
                if player:getMark(card:getSkillName() .. 'engine') == 0 then
                    return true
                end
                room:removePlayerMark(player, card:getSkillName() .. 'engine')
            end
        end
    end,
}
JUDGE_BUG = sgs.CreateTriggerSkill {
    name = 'JUDGE_BUG',
    events = {sgs.FinishJudge},
    on_trigger = function(self, event, player, data)
        local judge = data:toJudge()
        if judge.reason ~= self:objectName() then
            return false
        end
        judge.pattern = tostring(judge.card:getEffectiveId())
    end,
    can_trigger = function(self, target)
        return target
    end,
}
wenguaCard = sgs.CreateSkillCard {
    name = 'wengua_bill',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:hasSkill('wengua') and to_select:getMark('wengua_Play') == 0 and
                   (sgs.Self:hasSkill('wengua') and to_select:getMark('bf_huashenxushi') == 0)
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, 'wenguaengine')
        if source:getMark('wenguaengine') > 0 then
            room:addPlayerMark(targets[1], 'wengua_Play')
            local wenguas = {'wengua1', 'wengua2'}
            if targets[1]:objectName() ~= source:objectName() then
                room:broadcastSkillInvoke('wengua', 1)
                room:obtainCard(targets[1], self, false)
                table.insert(wenguas, 2, 'cancel')
            else
                room:broadcastSkillInvoke('wengua', 2)
            end
            local choice = room:askForChoice(targets[1], 'wengua', table.concat(wenguas, '+'))
            if choice ~= 'cancel' then
                ChoiceLog(targets[1], choice)
                room:moveCardTo(self, targets[1], sgs.Player_DrawPile)
                if choice == 'wengua1' then
                    room:obtainCard(source, room:getDrawPile():last(), false)
                    if targets[1]:objectName() ~= source:objectName() then
                        room:obtainCard(targets[1], room:getDrawPile():last(), false)
                    end
                elseif choice == 'wengua2' then
                    local card_ids = room:getNCards(1)
                    room:askForGuanxing(source, card_ids, sgs.Room_GuanxingDownOnly)
                    room:obtainCard(source, room:getDrawPile():first(), false)
                    if targets[1]:objectName() ~= source:objectName() then
                        room:obtainCard(targets[1], room:getDrawPile():first(), false)
                    end
                end
            end
            room:removePlayerMark(source, 'wenguaengine')
        end
    end,
}
wenguaVS = sgs.CreateOneCardViewAsSkill {
    name = 'wengua_bill&',
    filter_pattern = '.',
    view_as = function(self, card)
        local skillcard = wenguaCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
extra_targetCard = sgs.CreateSkillCard {
    name = 'extra_target',
    filter = function(self, targets, to_select)
        local x = 0
        if sgs.Self:getMark('fumian2_manmanlai') > 0 and sgs.Self:getMark('fumian2now_manmanlai') == 0 and
            sgs.Self:getPhase() ~= sgs.Player_NotActive then
            x = x + 1
            if sgs.Self:getMark('@fumian1') > 0 then
                x = x + 1
            end
        end
        if sgs.Self:getMark('ol_fumian2_manmanlai') == 3 and sgs.Self:getMark('stop_fumian_bug-Clear') == 0 then
            x = x + 1
            if sgs.Self:getMark('ol_fumian1_manmanlai') == 2 then
                x = x + 1
            end
        end
        return #targets < x and to_select:getMark(self:objectName()) == 0
    end,
    about_to_use = function(self, room, use)
        room:addPlayerMark(use.to:first(), self:objectName())
        room:addPlayerMark(use.from, 'stop_fumian_bug-Clear')
    end,
}
extra_targetVS = sgs.CreateZeroCardViewAsSkill {
    name = 'extra_target',
    response_pattern = '@@extra_target',
    view_as = function()
        return extra_targetCard:clone()
    end,
}
extra_target = sgs.CreateTriggerSkill {
    name = 'extra_target',
    events = {sgs.PreCardUsed},
    view_as_skill = extra_targetVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from:objectName() == player:objectName() and
            ((player:getMark('fumian2_manmanlai') > 0 and player:getMark('fumian2now_manmanlai') == 0) or
                (player:getMark('ol_fumian2_manmanlai') == 3 and player:getMark('stop_fumian_bug-Clear') == 0)) and
            use.card:isRed() and not use.card:isKindOf('Collateral') and not use.card:isKindOf('EquipCard') and
            not use.card:isKindOf('SkillCard') then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if use.to:contains(p) or room:isProhibited(player, p, use.card) or
                    not use.card:targetFilter(sgs.PlayerList(), p, player) then
                    room:addPlayerMark(p, self:objectName())
                end
            end
            -- room:setPlayerMark(player, 'card_id', use.card:getEffectiveId())
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getMark(self:objectName()) == 0 then
                    room:askForUseCard(player, '@@extra_target', '@extra_target')
                    break
                end
            end
            -- room:setPlayerMark(player, 'card_id', 0)
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getMark(self:objectName()) > 0 then
                    room:removePlayerMark(p, self:objectName())
                    if not use.to:contains(p) and not room:isProhibited(player, p, use.card) and
                        use.card:targetFilter(sgs.PlayerList(), p, player) then
                        use.to:append(p)
                    end
                end
            end
            room:sortByActionOrder(use.to)
            data:setValue(use)
        elseif use.from:objectName() == player:objectName() and use.card:isKindOf('Collateral') and use.card:isRed() then
            local x = 0
            if player:getMark('fumian2_flag') > 0 and player:getMark('fumian2now_flag') == 0 then
                x = x + 1
                if sgs.Self:getMark('@fumian1') > 0 then
                    x = x + 1
                end
            end
            for _ = 1, x do
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then
                        goto next_target
                    end
                    if use.card:targetFilter(sgs.PlayerList(), p, player) then
                        targets:append(p)
                    end
                    ::next_target::
                end
                if targets:isEmpty() then
                    return false
                end
                local tos = {}
                for _, t in sgs.qlist(use.to) do
                    table.insert(tos, t:objectName())
                end
                room:setPlayerProperty(player, 'extra_collateral', sgs.QVariant(use.card:toString()))
                room:setPlayerProperty(player, 'extra_collateral_current_targets', sgs.QVariant(table.concat(tos, '+')))
                local used = room:askForUseCard(player, '@@ExtraCollateral', '@qiaoshui-add:::collateral')
                room:setPlayerProperty(player, 'extra_collateral', sgs.QVariant(''))
                room:setPlayerProperty(player, 'extra_collateral_current_targets', sgs.QVariant('+'))
                if not used then
                    return false
                end
                local extra
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasFlag('ExtraCollateralTarget') then
                        p:setFlags('-ExtraColllateralTarget')
                        extra = p
                        break
                    end
                end
                if extra == nil then
                    return false
                end
                use.to:append(extra)
                room:sortByActionOrder(use.to)
                data:setValue(use)
            end
        end
    end,
}
poison_effect = sgs.CreateTriggerSkill {
    name = 'poison_effect',
    global = true,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function()
    end,
}
wenji_buff = sgs.CreateTriggerSkill {
    name = 'wenji_buff',
    global = true,
    events = {sgs.TargetSpecified, sgs.TrickCardCanceling},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if player:getMark('wenji' .. rinsan.getTrueClassName(use.card:getClassName()) .. '-Clear') > 0 then
                if string.find(use.card:getClassName(), 'Slash') then
                    local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
                    local index = 1
                    for _, p in sgs.qlist(use.to) do
                        local _data = sgs.QVariant()
                        _data:setValue(p)
                        jink_table[index] = 0
                        index = index + 1
                    end
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    player:setTag('Jink_' .. use.card:toString(), jink_data)
                else
                    room:setCardFlag(use.card, 'wenji')
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and effect.from:hasSkill(self:objectName()) and
                effect.from:getMark('wenji' .. effect.card:getClassName() .. '-Clear') > 0 then
                return true
            end
        end
    end,
}
Fire = function(player, target, damagePoint)
    local damage = sgs.DamageStruct()
    damage.from = player
    damage.to = target
    damage.damage = damagePoint
    damage.nature = sgs.DamageStruct_Fire
    player:getRoom():damage(damage)
end
function toSet(self)
    local set = {}
    for _, ele in pairs(self) do
        if not table.contains(set, ele) then
            table.insert(set, ele)
        end
    end
    return set
end
dajianjieCard = sgs.CreateSkillCard {
    name = 'dajianjie',
    skill_name = 'yeyan',
    filter = function(self, targets, to_select)
        local i = 0
        for _, p in pairs(targets) do
            if p:objectName() == to_select:objectName() then
                i = i + 1
            end
        end
        local maxVote = math.max(3 - #targets, 0) + i
        return maxVote
    end,
    feasible = function(self, targets)
        if self:getSubcards():length() ~= 4 then
            return false
        end
        local all_suit = {}
        for _, id in sgs.qlist(self:getSubcards()) do
            local c = sgs.Sanguosha:getCard(id)
            if not table.contains(all_suit, c:getSuit()) then
                table.insert(all_suit, c:getSuit())
            else
                return false
            end
        end
        if #toSet(targets) == 1 then
            return true
        elseif #toSet(targets) == 2 then
            return #targets == 3
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        source:loseMark('@dragon')
        source:loseMark('@phoenix')
        local criticaltarget = 0
        local totalvictim = 0
        local map = {}
        for _, sp in pairs(targets) do
            if map[sp:objectName()] then
                map[sp:objectName()] = map[sp:objectName()] + 1
            else
                map[sp:objectName()] = 1
            end
        end
        if #targets == 1 then
            map[targets[1]:objectName()] = map[targets[1]:objectName()] + 2
        end
        local target_table = sgs.SPlayerList()
        for sp, va in pairs(map) do
            if va > 1 then
                criticaltarget = criticaltarget + 1
            end
            totalvictim = totalvictim + 1
            for _, p in pairs(targets) do
                if p:objectName() == sp then
                    target_table:append(p)
                    break
                end
            end
        end
        if criticaltarget > 0 then
            room:removePlayerMark(source, '@flame')
            room:loseHp(source, 3)
            room:sortByActionOrder(target_table)
            for _, sp in sgs.qlist(target_table) do
                Fire(source, sp, map[sp:objectName()])
            end
        end
    end,
}
xiaojianjieCard = sgs.CreateSkillCard {
    name = 'xiaojianjie',
    skill_name = 'yeyan',
    filter = function(self, targets, to_select)
        return #targets < 3
    end,
    feasible = function(self, targets)
        return #targets > 0
    end,
    on_use = function(self, room, source, targets)
        source:loseMark('@dragon')
        source:loseMark('@phoenix')
        for _, sp in sgs.list(targets) do
            Fire(source, sp, 1)
        end
    end,
}
jianjievsCard = sgs.CreateSkillCard {
    name = 'jianjievs',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local name, vs = 'lianhuan', 'iron_chain'
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
            name = 'huoji'
            vs = 'fire_attack'
        end
        local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(),
            sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
        card:addSubcard(self:getSubcards():first())
        card:setSkillName(name)
        if card and card:targetFixed() then
            return false
        end
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        return card and card:targetFilter(qtargets, to_select, sgs.Self) and
                   not sgs.Self:isProhibited(to_select, card, qtargets)
    end,
    feasible = function(self, targets)
        local name, vs = 'lianhuan', 'iron_chain'
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
            name = 'huoji'
            vs = 'fire_attack'
        end
        local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(),
            sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
        card:addSubcard(self:getSubcards():first())
        card:setSkillName(name)
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        return card and card:targetsFeasible(qtargets, sgs.Self)
    end,
    on_validate = function(self, use)
        local room = use.from:getRoom()
        local name, vs = 'lianhuan', 'iron_chain'
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
            name = 'huoji'
            vs = 'fire_attack'
        end
        local use_card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(),
            sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
        use_card:addSubcard(self:getSubcards():first())
        use_card:setSkillName(name)
        local available = true
        for _, p in sgs.qlist(use.to) do
            if use.from:isProhibited(p, use_card) then
                available = false
                break
            end
        end
        room:addPlayerMark(use.from, name .. '_Play')
        available = available and use_card:isAvailable(use.from)
        if not available then
            return nil
        end
        return use_card
    end,
}
jianjievs = sgs.CreateViewAsSkill {
    name = 'jianjievs&',
    response_or_use = true,
    n = 999,
    view_filter = function(self, selected, to_select)
        if #selected == 0 and ((sgs.Self:getMark('@dragon') > 0 and to_select:isRed()) or
            (#selected == 0 and sgs.Self:getMark('@phoenix') > 0 and to_select:getSuit() == sgs.Card_Club) or
            (sgs.Self:getMark('@dragon') > 0 and sgs.Self:getMark('@phoenix') > 0 and sgs.Self:getHandcardNum() >= 4)) then
            return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
        elseif sgs.Self:getMark('@dragon') > 0 and sgs.Self:getMark('@phoenix') > 0 and #selected > 0 and #selected < 4 then
            for _, ca in sgs.list(selected) do
                if ca:getSuit() == to_select:getSuit() then
                    return false
                end
            end
            return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Self:getMark('@dragon') > 0 and sgs.Self:getMark('@phoenix') > 0 and #cards == 4 then
            local skillcard = dajianjieCard:clone()
            for _, card in ipairs(cards) do
                skillcard:addSubcard(card)
            end
            return skillcard
        elseif sgs.Self:getMark('@dragon') > 0 and sgs.Self:getMark('@phoenix') > 0 and #cards == 0 then
            return xiaojianjieCard:clone()
        elseif #cards == 1 then
            if sgs.Self:getMark('@dragon') > 0 and sgs.Self:getMark('huoji_Play') < 3 and cards[1]:isRed() then
                local skillcard = jianjievsCard:clone()
                skillcard:setSkillName('huoji')
                skillcard:addSubcard(cards[1])
                return skillcard
            elseif sgs.Self:getMark('@phoenix') > 0 and sgs.Self:getMark('lianhuan_Play') < 3 and cards[1]:getSuit() ==
                sgs.Card_Club then
                local skillcard = jianjievsCard:clone()
                skillcard:setSkillName('lianhuan')
                skillcard:addSubcard(cards[1])
                return skillcard
            end
        end
        return nil
    end,
}
yongsi_buff = sgs.CreateMaxCardsSkill {
    name = 'yongsi_buff',
    fixed_func = function(self, player)
        if player:hasFlag('god_yongsi') then
            return player:getLostHp()
        end
        return -1
    end,
}
people_fuck = sgs.CreateTriggerSkill {
    name = 'people_fuck',
    events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local num, n, m = 0, 0, 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getRole() == 'rebel' then
                num = num + 1
            end
            if p:getRole() == 'loyalist' then
                n = n + 1
            end
            if p:isFemale() then
                m = m + 1
            end
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:setPlayerMark(p, 'dingpan', num)
            room:setPlayerMark(p, 'fenyue', n)
            room:setPlayerMark(p, 'xiefang', m)
        end
    end,
}
damage_card_record = sgs.CreateTriggerSkill {
    name = 'damage_card_record',
    events = {sgs.DamageComplete, sgs.CardFinished},
    priority = -1,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageComplete then
            local damage = data:toDamage()
            if damage.card then
                room:setCardFlag(damage.card, 'damage_record')
            end
        else
            local use = data:toCardUse()
            if use.card then
                room:setCardFlag(use.card, '-damage_record')
            end
        end
    end,
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill('mute_e') then
    skills:append(mute_e)
end
if not sgs.Sanguosha:getSkill('hand_skill') then
    skills:append(hand_skill)
end
if not sgs.Sanguosha:getSkill('distance') then
    skills:append(distance)
end
if not sgs.Sanguosha:getSkill('slashmore') then
    skills:append(slashmore)
end
if not sgs.Sanguosha:getSkill('clear_mark') then
    skills:append(clear_mark)
end
if not sgs.Sanguosha:getSkill('turn_clear') then
    skills:append(turn_clear)
end
if not sgs.Sanguosha:getSkill('turn_length') then
    skills:append(turn_length)
end
if not sgs.Sanguosha:getSkill('Maxcards') then
    skills:append(Maxcards)
end
if not sgs.Sanguosha:getSkill('ExtraCollateral') then
    skills:append(ExtraCollateral)
end
if not sgs.Sanguosha:getSkill('clearAG') then
    skills:append(clearAG)
end
if not sgs.Sanguosha:getSkill('fulin_ex') then
    skills:append(fulin_ex)
end
if not sgs.Sanguosha:getSkill('#banbanban') then
    skills:append(banbanban)
end
if not sgs.Sanguosha:getSkill('card_used') then
    skills:append(card_used)
end
if not sgs.Sanguosha:getSkill('end_clear') then
    skills:append(end_clear)
end
if not sgs.Sanguosha:getSkill('kuanshiing') then
    skills:append(kuanshiing)
end
if not sgs.Sanguosha:getSkill('skip') then
    skills:append(skip)
end
if not sgs.Sanguosha:getSkill('Fake_Move') then
    skills:append(Fake_Move)
end
if not sgs.Sanguosha:getSkill('kuangcai_buff') then
    skills:append(kuangcai_buff)
end
if not sgs.Sanguosha:getSkill('damage_record') then
    skills:append(damage_record)
end
if not sgs.Sanguosha:getSkill('skill_mark') then
    skills:append(skill_mark)
end
if not sgs.Sanguosha:getSkill('JUDGE_BUG') then
    skills:append(JUDGE_BUG)
end
if not sgs.Sanguosha:getSkill('wengua_bill') then
    skills:append(wenguaVS)
end
if not sgs.Sanguosha:getSkill('extra_target') then
    skills:append(extra_target)
end
if not sgs.Sanguosha:getSkill('poison_effect') then
    skills:append(poison_effect)
end
if not sgs.Sanguosha:getSkill('wenji_buff') then
    skills:append(wenji_buff)
end
if not sgs.Sanguosha:getSkill('jianjievs') then
    skills:append(jianjievs)
end
if not sgs.Sanguosha:getSkill('yongsi_buff') then
    skills:append(yongsi_buff)
end
if not sgs.Sanguosha:getSkill('people_fuck') then
    skills:append(people_fuck)
end
if not sgs.Sanguosha:getSkill('axe_bug') then
    skills:append(axe_bug)
end
if not sgs.Sanguosha:getSkill('damage_card_record') then
    skills:append(damage_card_record)
end
getKingdoms = function(player)
    local kingdoms = {}
    for _, p in sgs.qlist(player:getRoom():getAlivePlayers()) do
        local flag = true
        for _, k in ipairs(kingdoms) do
            if p:getKingdom() == k then
                flag = false
                break
            end
        end
        if flag then
            table.insert(kingdoms, p:getKingdom())
        end
    end
    return #kingdoms
end
Table2IntList = function(theTable)
    local result = sgs.IntList()
    for i = 1, #theTable, 1 do
        result:append(theTable[i])
    end
    return result
end
function Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end
function ChangeCheck(player, name)
    if player:getGeneralName() == name or player:getGeneral2Name() == name then
        local x = player:getMaxHp()
        local y = player:getHp()
        player:getRoom():changeHero(player, name, false, false,
            player:getGeneral2Name() and player:getGeneral2Name() == name, false)
        player:getRoom():setPlayerProperty(player, 'maxhp', sgs.QVariant(x))
        player:getRoom():setPlayerProperty(player, 'hp', sgs.QVariant(math.min(y, player:getMaxHp())))
        player:getRoom():setPlayerProperty(player, 'kingdom', sgs.QVariant(player:getKingdom()))
    end
end
function skill(self, room, player, open, n)
    local log = sgs.LogMessage()
    log.type = '#InvokeSkill'
    log.from = player
    log.arg = self:objectName()
    room:sendLog(log)
    room:notifySkillInvoked(player, self:objectName())
    if open then
        if n then
            room:broadcastSkillInvoke(self:objectName(), n)
        else
            room:broadcastSkillInvoke(self:objectName())
        end
    end
end
function ChoiceLog(player, choice, to)
    local log = sgs.LogMessage()
    log.type = '#choice'
    log.from = player
    log.arg = choice
    if to then
        log.to:append(to)
    end
    player:getRoom():sendLog(log)
end
function lazy(self, room, player, choice, open, n)
    skill(self, room, player, open, n)
    ChoiceLog(player, choice)
end
function CDM(room, player, a, b)
    local x = math.min(player:getMark(a), player:getMark(b))
    room:removePlayerMark(player, a, x)
    room:removePlayerMark(player, b, x)
end
function RIGHT(self, player)
    if player and player:isAlive() and player:hasSkill(self:objectName()) then
        return true
    else
        return false
    end
end
function BeMan(room, player)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:objectName() == player:objectName() then
            return p
        end
    end
end
function GetColor(card)
    if card:isRed() then
        return 'red'
    elseif card:isBlack() then
        return 'black'
    end
end
function ChangeGeneral(room, player)
    local generals = {}
    for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
        if not sgs.Sanguosha:isGeneralHidden(name) and not table.contains(generals, name) then
            table.insert(generals, name)
        end
    end
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if table.contains(generals, p:getGeneralName()) then
            table.removeOne(generals, p:getGeneralName())
        end
        if table.contains(generals, p:getGeneral2Name()) then
            table.removeOne(generals, p:getGeneral2Name())
        end
    end
    local x = player:getMaxHp()
    local y = player:getHp()
    room:changeHero(player, generals[math.random(1, #generals)], false, false)
    room:setPlayerProperty(player, 'maxhp', sgs.QVariant(x))
    room:setPlayerProperty(player, 'hp', sgs.QVariant(y))
end
function ALLAPPEAR(room, player, mark, right)
    if right then
        room:addPlayerMark(player, '@' .. mark, player:getMark(mark))
        room:setPlayerMark(player, mark, 0)
    end
end
function HIDMARK(room, player, mark, right, n)
    if n == nil then
        n = 1
    end
    if right then
        room:addPlayerMark(player, '@' .. mark, n)
        ALLAPPEAR(room, player, mark, right)
    else
        room:addPlayerMark(player, mark, n)
    end
end
function targetsTable2QList(thetable)
    local theqlist = sgs.PlayerList()
    for _, p in ipairs(thetable) do
        theqlist:append(p)
    end
    return theqlist
end
function getIntList(cardlists)
    local list = sgs.IntList()
    for _, card in sgs.qlist(cardlists) do
        list:append(card:getId())
    end
    return list
end
function TrueName(card)
    if card == nil then
        return ''
    end
    if (card:objectName() == 'fire_slash' or card:objectName() == 'thunder_slash') then
        return 'slash'
    end
    return card:objectName()
end
function ChangeNumber(m, n)
    if m > n then
        return m - n
    end
    return m
end
function ChangeSkill(self, room, player, wrong_number, max_number, name)
    if max_number == nil then
        max_number = 2
    end
    if wrong_number == nil then
        wrong_number = 1
    end
    if name then
        name = player:getGeneral2Name()
    else
        name = player:getGeneralName()
    end
    room:addPlayerMark(player, self:objectName())
    room:setPlayerMark(player, self:objectName(), ChangeNumber(player:getMark(self:objectName()), max_number))
    sgs.Sanguosha:addTranslationEntry(':' .. self:objectName(),
        '' ..
            string.gsub(sgs.Sanguosha:translate(':' .. self:objectName()), sgs.Sanguosha:translate(':' .. self:objectName()),
                sgs.Sanguosha:translate(':' .. self:objectName() ..
                                            ChangeNumber(player:getMark(self:objectName()) + wrong_number, max_number))))
    ChangeCheck(player, name)
    room:removePlayerMark(player, '@ChangeSkill' ..
        ChangeNumber(player:getMark(self:objectName()) + max_number - 1 + wrong_number, max_number))
    room:addPlayerMark(player, '@ChangeSkill' ..
        ChangeNumber(player:getMark(self:objectName()) + max_number - wrong_number, max_number))
    return player:getMark(self:objectName())
end
function fakeNumber(x)
    if type(x) == 'number' then
        if x == 1 then
            return 'A'
        elseif x == 11 then
            return 'J'
        elseif x == 12 then
            return 'Q'
        elseif x == 13 then
            return 'K'
        end
        return tostring(x)
    else
        if x == 'heart' then
            return 1
        elseif x == 'diamond' then
            return 2
        elseif x == 'spade' then
            return 3
        elseif x == 'club' then
            return 4
        else
            return 5
        end
    end
end
function ShowManyCards(player, ids)
    for _, id in sgs.qlist(ids) do
        player:getRoom():showCard(player, id)
    end
end
function ThrowEquipArea(self, player, cancel, hourse)
    local choices = {}
    for i = 0, 4 do
        if player:hasEquipArea(i) and (horse or (i ~= 3 and i ~= 2)) then
            table.insert(choices, 'jueyan' .. i)
        end
    end
    if not horse and (player:hasEquipArea(2) or player:hasEquipArea(3)) then
        table.insert(choices, 'jueyan' .. 2)
    end
    if cancel then
        table.insert(choices, 'cancel')
    end
    local choice = player:getRoom():askForChoice(player, self:objectName(), table.concat(choices, '+'))
    if choice ~= 'cancel' then
        lazy(self, player:getRoom(), player, choice, true)
        local x = tonumber(string.sub(choice, string.len(choice), string.len(choice)))
        player:throwEquipArea(x)
        if x == 2 and not horse then
            player:throwEquipArea(3)
        end
        return x
    end
    return -1
end
function ObtainEquipArea(self, player, cancel, hourse)
    local choices = {}
    for i = 0, 4 do
        if not player:hasEquipArea(i) and (horse or (i ~= 3 and i ~= 2)) then
            table.insert(choices, 'jueyan' .. i)
        end
    end
    if not horse and (not player:hasEquipArea(2)) then
        table.insert(choices, 'jueyan' .. 2)
    end
    if cancel then
        table.insert(choices, 'cancel')
    end
    if #choices > 0 then
        local choice = player:getRoom():askForChoice(player, self:objectName(), table.concat(choices, '+'))
        if choice ~= 'cancel' then
            lazy(self, player:getRoom(), player, choice, true)
            local x = tonumber(string.sub(choice, string.len(choice), string.len(choice)))
            player:obtainEquipArea(x)
            if x == 2 and not horse then
                player:obtainEquipArea(3)
            end
            return x
        end
    end
    return -1
end
function SendComLog(self, player, n, invoke)
    if invoke == nil then
        invoke = true
    end
    if invoke then
        player:getRoom():sendCompulsoryTriggerLog(player, self:objectName())
        player:getRoom():broadcastSkillInvoke(self:objectName(), n)
    end
end
wutugu = sgs.General(extension, 'wutugu', 'qun', 15)
ranshang = sgs.CreateTriggerSkill {
    name = 'ranshang',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:gainMark('@ranshang', damage.damage)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:getMark('@ranshang') > 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName(), 2)
            room:addPlayerMark(player, self:objectName() .. 'engine', 2)
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:loseHp(player, player:getMark('@ranshang'))
                room:removePlayerMark(player, self:objectName() .. 'engine', 2)
            end
        end
        return false
    end,
}
wutugu:addSkill(ranshang)
hanyong = sgs.CreateTriggerSkill {
    name = 'hanyong',
    events = {sgs.CardUsed, sgs.ConfirmDamage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed and player:getHp() < room:getLord():getMark('@clock_time') then
            local use = data:toCardUse()
            if (use.card:isKindOf('SavageAssault') or use.card:isKindOf('ArcheryAttack')) and
                room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setCardFlag(use.card, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if damage.card:hasFlag(self:objectName()) then
                local log = sgs.LogMessage()
                log.type = '$hanyong'
                log.from = player
                log.card_str = damage.card:toString()
                log.arg = self:objectName()
                room:sendLog(log)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.CardFinished and data:toCardUse().card:hasFlag(self:objectName()) then
            room:clearCardFlag(data:toCardUse().card)
        end
        return false
    end,
}
wutugu:addSkill(hanyong)
ol_quancong = sgs.General(extension_yijiang, 'ol_quancong', 'wu', 4, true, sgs.GetConfig('EnableHidden', true))
yaoming = sgs.CreateTriggerSkill {
    name = 'yaoming',
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() ~= player:getHandcardNum() then
                players:append(p)
            end
        end
        if not room:getCurrent():hasFlag(self:objectName() .. player:objectName()) then
            local target = room:askForPlayerChosen(player, players, self:objectName(), 'yaoming-invoke', true, true)
            if target then
                room:getCurrent():setFlags(self:objectName() .. player:objectName())
                if target:getHandcardNum() > player:getHandcardNum() then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local to_throw = room:askForCardChosen(player, target, 'h', self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                elseif target:getHandcardNum() < player:getHandcardNum() then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        target:drawCards(1)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
ol_quancong:addSkill(yaoming)
cuiyan = sgs.General(extension_z, 'cuiyan', 'wei', 3)
yawang = sgs.CreateTriggerSkill {
    name = 'yawang',
    global = true,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Draw and RIGHT(self, player) then
                local x = 0
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getHp() == player:getHp() then
                        x = x + 1
                    end
                end
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(x)
                room:setPlayerMark(player, 'yawang-Clear', x)
                return true
            elseif player:getPhase() == sgs.Player_Play and player:getMark('yawang_stop-Clear') ~= 0 then
                room:setPlayerCardLimitation(player, 'use', '.', false)
            end
        elseif player:getPhase() == sgs.Player_Play and (event == sgs.CardUsed or event == sgs.CardResponded) then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card and card:getHandlingMethod() == sgs.Card_MethodUse and player:getMark('yawang-Clear') > 0 then
                room:removePlayerMark(player, 'yawang-Clear')
                if player:getMark('yawang-Clear') == 0 then
                    room:setPlayerCardLimitation(player, 'use', '.', false)
                    room:addPlayerMark(player, 'yawang_stop-Clear')
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and RIGHT(self, player) then
            room:removePlayerCardLimitation(player, 'use', '.')
        end
    end,
}
cuiyan:addSkill(yawang)
ol_xunzhi = sgs.CreatePhaseChangeSkill {
    name = 'ol_xunzhi',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:getPhase() == sgs.Player_Start and p:getNextAlive():objectName() == player:objectName() and p:getHp() ~=
                player:getHp() and player:getNextAlive():getHp() ~= player:getHp() and
                room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                room:loseHp(player)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:addPlayerMark(player, '@Maxcards', 2)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
                break
            end
        end
    end,
}
cuiyan:addSkill(ol_xunzhi)
ol_caoxiu = sgs.General(extension_yijiang, 'ol_caoxiu', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
qianju = sgs.CreateDistanceSkill {
    name = 'qianju',
    correct_func = function(self, from, to)
        if from:hasSkill(self:objectName()) then
            return -from:getLostHp()
        end
    end,
}
ol_caoxiu:addSkill(qianju)
qingxi = sgs.CreateTriggerSkill {
    name = 'qingxi',
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local room = player:getRoom()
        if player:getWeapon() == nil then
            return false
        end
        local x = player:getWeapon():getRealCard():toWeapon():getRange()
        if damage.card and damage.card:isKindOf('Slash') and damage.by_user and not damage.chain and not damage.transfer and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if room:askForDiscard(damage.to, self:objectName(), x, x, true, true) then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:throwCard(player:getWeapon(), player, damage.to)
                else
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
ol_caoxiu:addSkill(qingxi)
ol_caorui = sgs.General(extension_yijiang, 'ol_caorui$', 'wei', 3, true, sgs.GetConfig('EnableHidden', true))
ol_caorui:addSkill('huituo')
ol_mingjianCard = sgs.CreateSkillCard {
    name = 'ol_mingjian',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:obtainCard(targets[1], source:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
            source:objectName(), targets[1]:objectName(), self:objectName(), ''), false)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:addPlayerMark(targets[1], '@ol_mingjian_flag')
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
ol_mingjian = sgs.CreateZeroCardViewAsSkill {
    name = 'ol_mingjian',
    view_as = function(self, cards)
        return ol_mingjianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed('#ol_mingjian')
    end,
}
ol_caorui:addSkill(ol_mingjian)
ol_caorui:addSkill('xingshuai')
ol_shixie = sgs.General(extension_pm, 'ol_shixie', 'qun', 3)
ol_biluan = sgs.CreatePhaseChangeSkill {
    name = 'ol_biluan',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:distanceTo(player) == 1 then
                if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName()) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        room:addPlayerMark(player, '@biluan', getKingdoms(player))
                        CDM(room, player, '@biluan', '@lixia')
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                        return true
                    end
                end
                break
            end
        end
        return false
    end,
}
ol_shixie:addSkill(ol_biluan)
ol_lixia = sgs.CreatePhaseChangeSkill {
    name = 'ol_lixia',
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and not player:inMyAttackRange(p) then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        local choice = room:askForChoice(p, self:objectName(), 'lixia1+lixia2')
                        if choice == 'lixia1' then
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            p:drawCards(1, self:objectName())
                        else
                            room:broadcastSkillInvoke(self:objectName(), 1)
                            player:drawCards(1, self:objectName())
                        end
                        room:addPlayerMark(p, '@lixia')
                        CDM(room, p, '@biluan', '@lixia')
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
}
ol_shixie:addSkill(ol_lixia)
super_liubei = sgs.General(extension_god, 'super_liubei$', 'shu', 4, true, sgs.GetConfig('EnableHidden', true))
ol_rendeCard = sgs.CreateSkillCard {
    name = 'ol_rende',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName() and
                   (not sgs.Self:hasUsed('#ol_rende') or to_select:getMark(self:objectName() .. '_Play') == 0)
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:addPlayerMark(source, self:objectName() .. '_Play', self:getSubcards():length())
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(),
                'ol_rende', '')
            room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
            room:addPlayerMark(targets[1], self:objectName() .. '_Play')
            if source:getMark(self:objectName() .. '_Play') >= 2 and not source:hasFlag(self:objectName()) then
                source:setFlags(self:objectName())
                local Set = function(list)
                    local set = {}
                    for _, l in ipairs(list) do
                        set[l] = true
                    end
                    return set
                end
                local basic = {'slash', 'peach', 'cancel'}
                if not (Set(sgs.Sanguosha:getBanPackages()))['maneuvering'] then
                    table.insert(basic, 2, 'thunder_slash')
                    table.insert(basic, 2, 'fire_slash')
                    table.insert(basic, 'analeptic')
                end
                for _, patt in ipairs(basic) do
                    local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
                    if poi and (not poi:isAvailable(source)) or (patt == 'peach' and not source:isWounded()) then
                        table.removeOne(basic, patt)
                        if patt == 'slash' then
                            table.removeOne(basic, 'thunder_slash')
                            table.removeOne(basic, 'fire_slash')
                        end
                    end
                end
                local choice = room:askForChoice(source, self:objectName(), table.concat(basic, '+'))
                if choice ~= 'cancel' then
                    room:setPlayerProperty(source, 'ol_rende', sgs.QVariant(choice))
                    room:askForUseCard(source, '@@ol_rende', '@ol_rende', -1, sgs.Card_MethodUse)
                    room:setPlayerProperty(source, 'ol_rende', sgs.QVariant())
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
ol_rende = sgs.CreateViewAsSkill {
    name = 'ol_rende',
    n = 999,
    response_pattern = '@@ol_rende',
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@@ol_rende' then
            return false
        end
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@@ol_rende' then
            if #cards == 0 then
                local name = sgs.Self:property('ol_rende'):toString()
                local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
                card:setSkillName('_ol_rende')
                return card
            end
        else
            if #cards > 0 then
                local rende = ol_rendeCard:clone()
                for _, c in ipairs(cards) do
                    rende:addSubcard(c)
                end
                rende:setSkillName('ol_rende')
                return rende
            end
        end
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
}
super_liubei:addSkill(ol_rende)
super_liubei:addSkill('jijiang')
caochun = sgs.General(extension_mobile, 'caochun', 'wei')
shanjiaCard = sgs.CreateSkillCard {
    name = 'shanjia',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):isEquipped() then
                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                slash:setSkillName('shanjia')
                for _, cd in sgs.qlist(self:getSubcards()) do
                    slash:addSubcard(cd)
                end
                slash:deleteLater()
                return slash:targetFilter(targets_list, to_select, sgs.Self)
            end
        end
        return #targets < 0
    end,
    feasible = function(self, targets)
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):isEquipped() then
                return #targets > 0
            end
        end
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        if targets_list:length() > 0 then
            room:broadcastSkillInvoke('shanjia', 2)
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            slash:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(slash, source, targets_list))
        else
            room:broadcastSkillInvoke('shanjia', 1)
        end
    end,
}
shanjiaVS = sgs.CreateViewAsSkill {
    name = 'shanjia',
    n = 7,
    view_filter = function(self, selected, to_select)
        local x = math.min(sgs.Self:getMark('@shanjia'), 7)
        return #selected < x and not sgs.Self:isJilei(to_select)
    end,
    view_as = function(self, cards)
        local x = math.min(sgs.Self:getMark('@shanjia'), 7)
        if #cards ~= x then
            return nil
        end
        local card = shanjiaCard:clone()
        for _, cd in ipairs(cards) do
            card:addSubcard(cd)
        end
        return card
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@shanjia')
    end,
}
shanjia = sgs.CreateTriggerSkill {
    name = 'shanjia',
    global = true,
    view_as_skill = shanjiaVS,
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        ALLAPPEAR(room, player, self:objectName(), player:hasSkill(self:objectName()))
        local x = math.min(player:getMark('@shanjia'), 7)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and x > 0 and
            player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:drawCards(x)
                room:askForUseCard(player, '@@shanjia!', 'shanjia_throw', -1, sgs.Card_MethodNone)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif event == sgs.CardUsed and data:toCardUse().card:isKindOf('EquipCard') then
            HIDMARK(room, player, self:objectName(), player:hasSkill(self:objectName()))
        end
    end,
}
caochun:addSkill(shanjia)
liuyu = sgs.General(extension6, 'liuyu', 'qun', 2)
zhigeCard = sgs.CreateSkillCard {
    name = 'zhige',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:inMyAttackRange(sgs.Self)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if effect.to:canSlash(p, nil, false) then
                targets:append(p)
            end
        end
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            local use_slash = room:askForUseSlashTo(effect.to, targets, '@zhige')
            if not use_slash and not effect.to:getEquips():isEmpty() then
                local card =
                    room:askForCard(effect.to, '.|.|.|equipped!', '@zhige_give', sgs.QVariant(), sgs.Card_MethodNone)
                if card then
                    room:moveCardTo(card, effect.from, sgs.Player_PlaceHand, sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_GIVE, effect.to:objectName(), effect.from:objectName(),
                        self:objectName(), ''))
                end
            end
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
zhige = sgs.CreateZeroCardViewAsSkill {
    name = 'zhige',
    view_as = function()
        return zhigeCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#zhige') and player:getHandcardNum() > player:getHp()
    end,
}
liuyu:addSkill(zhige)
zongzuo = sgs.CreateTriggerSkill {
    name = 'zongzuo',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.Deathed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart and RIGHT(self, player) then
            room:broadcastSkillInvoke(self:objectName(), 1)
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:gainMaxHp(player, getKingdoms(player))
                room:recover(player, sgs.RecoverStruct(player, nil, getKingdoms(player)))
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif event == sgs.Deathed then
            local death = data:toDeath()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if death.who:getKingdom() == p:getKingdom() then
                    return false
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if RIGHT(self, p) then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        room:loseMaxHp(p)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
liuyu:addSkill(zongzuo)
sundeng = sgs.General(extension6, 'sundeng', 'wu')
kuangbiCard = sgs.CreateSkillCard {
    name = 'kuangbi',
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isNude() and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke(self:objectName(), 1)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local cards = room:askForExchange(targets[1], self:objectName(), 3, 1, true, '@kuangbi')
            source:addToPile('kuang', cards:getSubcards(), false)
            room:addPlayerMark(source, self:objectName() .. targets[1]:objectName())
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
kuangbiVS = sgs.CreateZeroCardViewAsSkill {
    name = 'kuangbi',
    view_as = function(self)
        local card = kuangbiCard:clone()
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#kuangbi')
    end,
}
kuangbi = sgs.CreatePhaseChangeSkill {
    name = 'kuangbi',
    view_as_skill = kuangbiVS,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if not player:getPile('kuang'):isEmpty() and player:getPhase() == sgs.Player_RoundStart then
            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            for _, id in sgs.qlist(player:getPile('kuang')) do
                dummy:addSubcard(id)
            end
            room:obtainCard(player, dummy,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName()), false)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:getMark(self:objectName() .. p:objectName()) > 0 then
                    room:setPlayerMark(player, self:objectName() .. p:objectName(), 0)
                    if p:isAlive() then
                        room:broadcastSkillInvoke(self:objectName(), 2)
                        p:drawCards(dummy:subcardsLength(), self:objectName())
                    end
                end
            end
            dummy:deleteLater()
        end
        return false
    end,
}
sundeng:addSkill(kuangbi)
liyan = sgs.General(extension6, 'liyan', 'shu', 3)
duliangCard = sgs.CreateSkillCard {
    name = 'duliang',
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local card = sgs.Sanguosha:getCard(room:askForCardChosen(source, targets[1], 'h', self:objectName()))
            room:obtainCard(source, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName()),
                false)
            local choice = room:askForChoice(source, self:objectName(), 'duliang1+duliang2')
            ChoiceLog(source, choice)
            if choice == 'duliang1' then
                room:broadcastSkillInvoke(self:objectName(), 1)
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                local ids = sgs.IntList()
                ids:append(room:drawCard())
                ids:append(room:drawCard())
                room:fillAG(ids, targets[1])
                for _, id in sgs.qlist(ids) do
                    if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') then
                        dummy:addSubcard(id)
                    end
                end
                room:getThread():delay()
                targets[1]:obtainCard(dummy, false)
                room:clearAG()
            else
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:addPlayerMark(targets[1], self:objectName())
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        else
            room:broadcastSkillInvoke(self:objectName(), 2)
        end
    end,
}
duliangVS = sgs.CreateZeroCardViewAsSkill {
    name = 'duliang',
    view_as = function()
        return duliangCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#duliang')
    end,
}
duliang = sgs.CreateDrawCardsSkill {
    name = 'duliang',
    global = true,
    view_as_skill = duliangVS,
    draw_num_func = function(self, player, n)
        local room = player:getRoom()
        local x = player:getMark(self:objectName())
        if player:getMark('ol_hunshang-Clear') > 0 and room:askForSkillInvoke(player, 'yingzi') then
            x = x + 1
        end
        if player:getMark('fumian1_manmanlai') > 0 and player:getMark('fumian1now_manmanlai') == 0 then
            x = x + 1
            if player:getMark('@fumian2') > 0 then
                x = x + 1
            end
        end
        if player:getMark('ol_fumian1_manmanlai') == 3 then
            x = x + 1
            if player:getMark('ol_fumian2_manmanlai') == 2 then
                x = x + 1
            end
        end
        if player:getMark('@hulaoguan') > 0 and player:hasSkill('shenwei') > 0 then
            x = x + 1
        end
        if x > 0 then
            player:getRoom():setPlayerMark(player, self:objectName(), 0)
        end
        if player:getMark('@thiefed') > 0 then
            n = n + room:findPlayersBySkillName('jieyingy'):length()
        end
        for _, pe in sgs.qlist(room:findPlayersBySkillName('shenen')) do
            if not player:isYourFriend(pe) then
                n = n + 1
            end
        end
        return n + x
    end,
}
liyan:addSkill(duliang)

fulin = sgs.CreateTriggerSkill {
    name = 'fulin',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
    on_trigger = function(self, event, player, data, room)
        SendComLog(self, player, nil, event == sgs.AskForGameruleDiscard)
        local n = room:getTag('DiscardNum'):toInt()
        for _, id in sgs.qlist(player:handCards()) do
            if player:getMark(self:objectName() .. id .. '-Clear') > 0 then
                if event == sgs.AskForGameruleDiscard then
                    n = n - 1
                    room:setPlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString(), false)
                else
                    room:removePlayerCardLimitation(player, 'discard', sgs.Sanguosha:getCard(id):toString() .. '$0')
                end
            end
        end
        room:setTag('DiscardNum', sgs.QVariant(n))
    end,
}
liyan:addSkill(fulin)
guohuanghou = sgs.General(extension6, 'guohuanghou', 'wei', 3, false)
jiaozhaoCard = sgs.CreateSkillCard {
    name = 'jiaozhao',
    will_throw = false,
    filter = function(self, targets, to_select)
        if sgs.Self:getMark('danxin') == 2 then
            return false
        else
            local nearest = 1000
            for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
                nearest = math.min(nearest, sgs.Self:distanceTo(p))
            end
            return #targets == 0 and sgs.Self:distanceTo(to_select) == nearest
        end
    end,
    feasible = function(self, targets)
        if sgs.Self:getMark('danxin') == 2 then
            return #targets == 0
        else
            return #targets == 1
        end
    end,
    on_use = function(self, room, source, targets)
        local target = source
        if targets[1] then
            target = targets[1]
        end
        room:showCard(source, self:getSubcards():first())
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local ban_list, choices = {}, sgs.IntList()
            for i = 0, 10000 do
                local card = sgs.Sanguosha:getEngineCard(i)
                if card == nil then
                    break
                end
                if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and
                    not table.contains(ban_list, card:objectName()) then
                    if (card:isKindOf('BasicCard') or card:isNDTrick()) then
                        table.insert(ban_list, card:objectName())
                    end
                end
            end
            for _, name in ipairs(ban_list) do
                for i = 0, 10000 do
                    local card = sgs.Sanguosha:getEngineCard(i)
                    if card == nil then
                        break
                    end
                    if card:objectName() == name and
                        (card:isKindOf('BasicCard') or (source:getMark('danxin') > 0 and card:isNDTrick())) and
                        card:getSuit() == 6 and card:getNumber() == 14 then
                        choices:append(i)
                    end
                end
            end
            room:fillAG(choices)
            local card_id = room:askForAG(target, choices, false, self:objectName())
            if card_id ~= -1 then
                ChoiceLog(target, sgs.Sanguosha:getCard(card_id):objectName())
                room:addPlayerMark(source, self:objectName() .. sgs.Sanguosha:getCard(card_id):objectName() .. '-Clear')
                room:addPlayerMark(source, self:objectName() .. self:getSubcards():first() .. '-Clear', 2)
                room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():first()),
                    self:objectName() .. sgs.Sanguosha:getCard(card_id):objectName())
            end
            room:clearAG()
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
jiaozhao = sgs.CreateOneCardViewAsSkill {
    name = 'jiaozhao',
    view_filter = function(self, card)
        local writing = false
        for _, mark in sgs.list(sgs.Self:getMarkNames()) do
            if string.find(mark, self:objectName()) and sgs.Self:getMark(mark) == 1 then
                writing = string.sub(mark, 9, string.len(mark) - 6)
            end
        end
        if not writing then
            return not card:isEquipped()
        end
        return sgs.Self:getMark(self:objectName() .. card:getId() .. '-Clear') == 2
    end,
    view_as = function(self, card)
        local writing = false
        for _, mark in sgs.list(sgs.Self:getMarkNames()) do
            if string.find(mark, self:objectName()) and sgs.Self:getMark(mark) > 0 then
                writing = string.sub(mark, 9, string.len(mark) - 6)
            end
        end
        if writing then
            local skillcard = sgs.Sanguosha:cloneCard(writing, card:getSuit(), card:getNumber())
            skillcard:setSkillName(self:objectName())
            skillcard:addSubcard(card)
            return skillcard
        else
            local skillcard = jiaozhaoCard:clone()
            skillcard:setSkillName(self:objectName())
            skillcard:addSubcard(card)
            return skillcard
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end,
    enabled_at_response = function(self, player, pattern)
        local writing = false
        for _, mark in sgs.list(player:getMarkNames()) do
            if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
                writing = string.sub(mark, 9, string.len(mark) - 6)
            end
        end
        return writing and (pattern == writing or string.find(pattern, writing))
    end,
    enabled_at_nullification = function(self, player)
        local writing = false
        for _, mark in sgs.list(player:getMarkNames()) do
            if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
                writing = string.sub(mark, 9, string.len(mark) - 6)
            end
        end
        return writing and writing == 'nullification'
    end,
}
guohuanghou:addSkill(jiaozhao)
danxin = sgs.CreateMasochismSkill {
    name = 'danxin',
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local choices = {'danxin1+cancel'}
        if player:getMark(self:objectName()) == 0 then
            table.insert(choices, 'danxin2')
        elseif player:getMark(self:objectName()) == 1 then
            table.insert(choices, 'danxin3')
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
        if choice ~= 'cancel' then
            lazy(self, room, player, choice, true)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if choice == 'danxin1' then
                    player:drawCards(1, self:objectName())
                else
                    if player:getMark(self:objectName()) == 0 then
                        sgs.Sanguosha:addTranslationEntry(':danxin', '' ..
                            string.gsub(sgs.Sanguosha:translate(':danxin'), sgs.Sanguosha:translate(':danxin'),
                                sgs.Sanguosha:translate(':danxin1')))
                        sgs.Sanguosha:addTranslationEntry(':jiaozhao', '' ..
                            string.gsub(sgs.Sanguosha:translate(':jiaozhao'), sgs.Sanguosha:translate(':jiaozhao'),
                                sgs.Sanguosha:translate(':jiaozhao1')))
                    else
                        sgs.Sanguosha:addTranslationEntry(':danxin', '' ..
                            string.gsub(sgs.Sanguosha:translate(':danxin'), sgs.Sanguosha:translate(':danxin'),
                                sgs.Sanguosha:translate(':danxin2')))
                        sgs.Sanguosha:addTranslationEntry(':jiaozhao', '' ..
                            string.gsub(sgs.Sanguosha:translate(':jiaozhao'), sgs.Sanguosha:translate(':jiaozhao'),
                                sgs.Sanguosha:translate(':jiaozhao2')))
                    end
                    ChangeCheck(player, 'guohuanghou')
                    room:addPlayerMark(player, self:objectName())
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
guohuanghou:addSkill(danxin)
cenhun = sgs.General(extension6, 'cenhun', 'wu', 3)
jishecard = sgs.CreateSkillCard {
    name = 'jishe',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            source:drawCards(1, self:objectName())
            room:addPlayerMark(source, '@jishe-Clear')
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
jishechainedcard = sgs.CreateSkillCard {
    name = 'jishe_chained',
    filter = function(self, targets, to_select)
        return not to_select:isChained() and #targets < sgs.Self:getHp()
    end,
    feasible = function(self, targets)
        return #targets <= sgs.Self:getHp() and #targets > 0
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine', 2)
        if source:getMark(self:objectName() .. 'engine') > 0 then
            for _, p in ipairs(targets) do
                room:setPlayerChained(p)
            end
            room:removePlayerMark(source, self:objectName() .. 'engine', 2)
        end
    end,
}
jisheVS = sgs.CreateZeroCardViewAsSkill {
    name = 'jishe',
    view_as = function(self, cards)
        if sgs.Self:getPhase() == sgs.Player_Finish then
            return jishechainedcard:clone()
        end
        return jishecard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMaxCards() > 0 and (not sgs.GetConfig('jishe_change', true) or player:usedTimes('#jishe') < 2)
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@jishe'
    end,
}
jishe = sgs.CreatePhaseChangeSkill {
    name = 'jishe',
    view_as_skill = jisheVS,
    on_phasechange = function(self, player)
        local invoke = false
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not invoke then
                invoke = not p:isChained()
            end
        end
        if invoke and player:getPhase() == sgs.Player_Finish and player:isKongcheng() and player:getHp() > 0 then
            player:getRoom():askForUseCard(player, '@@jishe', '@jishe')
        end
    end,
}
cenhun:addSkill(jishe)
lianhuo = sgs.CreateTriggerSkill {
    name = 'lianhuo',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire and not damage.chain and player:isChained() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                damage.damage = damage.damage + 1
                data:setValue(damage)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
cenhun:addSkill(lianhuo)
huanghao = sgs.General(extension6, 'huanghao', 'shu', 3, true,
    sgs.GetConfig('hidden_ai', true) and sgs.GetConfig('huanghao_down', true))
qinqingCard = sgs.CreateSkillCard {
    name = 'qinqing',
    filter = function(self, targets, to_select)
        local lord = sgs.Self
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            if p:isLord() then
                lord = p
            end
        end
        return (to_select:isNude() or sgs.Self:canDiscard(to_select, 'he')) and to_select:inMyAttackRange(lord)
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            for _, p in pairs(targets) do
                if not p:isNude() then
                    local to_throw = room:askForCardChosen(source, p, 'he', self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(sgs.Sanguosha:getCard(to_throw), p, source)
                end
            end
            for _, p in pairs(targets) do
                p:drawCards(1, self:objectName())
            end
            local x = 0
            for _, p in pairs(targets) do
                if p:getHandcardNum() > room:getLord():getHandcardNum() then
                    x = x + 1
                end
            end
            source:drawCards(x, self:objectName())
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
qinqingVS = sgs.CreateZeroCardViewAsSkill {
    name = 'qinqing',
    view_as = function(self, cards)
        return qinqingCard:clone()
    end,
    response_pattern = '@qinqing',
}
qinqing = sgs.CreatePhaseChangeSkill {
    name = 'qinqing',
    view_as_skill = qinqingVS,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if room:getLord() and p:inMyAttackRange(room:getLord()) and
                (p:objectName() ~= player:objectName() or sgs.GetConfig('huanghao_down', true)) and
                (player:canDiscard(p, 'he') and not p:isNude()) or (sgs.GetConfig('huanghao_down', true) and p:isNude()) then
                players:append(p)
            end
        end
        if not players:isEmpty() and player:getPhase() == sgs.Player_Finish then
            if sgs.GetConfig('huanghao_down', true) then
                room:askForUseCard(player, '@qinqing', '@qinqing')
            else
                local target = room:askForPlayerChosen(player, players, self:objectName(), 'qinqing-invoke', true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local to_throw = room:askForCardChosen(player, target, 'he', self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
                        target:drawCards(1, self:objectName())
                        if target:getHandcardNum() > room:getLord():getHandcardNum() then
                            player:drawCards(1, self:objectName())
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
}
huanghao:addSkill(qinqing)
huishengCard = sgs.CreateSkillCard {
    name = 'huisheng',
    target_fixed = true,
    will_throw = false,
    about_to_use = function(self, room, use)
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):getTag('huisheng'):toBool() then
                sgs.Sanguosha:getCard(id):removeTag('huisheng')
            else
                sgs.Sanguosha:getCard(id):setTag('huisheng', sgs.QVariant(true))
            end
        end
    end,
}
huishengVS = sgs.CreateViewAsSkill {
    name = 'huisheng',
    n = 999,
    view_filter = function(self, selected, to_select)
        if #selected > 0 and #selected < sgs.Self:getMark('huisheng') - 1 and not selected[1]:hasFlag('huisheng') then
            return not to_select:hasFlag('huisheng')
        end
        if #selected == 0 then
            return true
        end
        return nil
    end,
    response_pattern = '@@huisheng!',
    view_as = function(self, cards)
        local huisheng = huishengCard:clone()
        for _, c in ipairs(cards) do
            huisheng:addSubcard(c)
        end
        return huisheng
    end,
}
huisheng = sgs.CreateTriggerSkill {
    name = 'huisheng',
    view_as_skill = huishengVS,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:getMark('@huisheng') == 0 and damage.from:objectName() ~= player:objectName() then
            room:addPlayerMark(damage.from, self:objectName(), damage.damage)
            room:setTag('CurrentDamageStruct', data)
            local cards = room:askForExchange(player, self:objectName(), player:getCards('he'):length(), 1, true,
                '@huisheng', true)
            if not sgs.GetConfig('huanghao_down', true) then
                room:addPlayerMark(damage.from, '@huisheng')
            end
            if cards then
                skill(self, room, player, damage.from:getAI())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    if damage.from:getAI() or damage.from:getState() == 'robot' then
                        local choice = sgs.IntList()
                        for _, id in sgs.qlist(cards:getSubcards()) do
                            choice:append(id)
                        end
                        if damage.from:getCards('he'):length() >= cards:subcardsLength() then
                            for _, card in sgs.qlist(damage.from:getCards('he')) do
                                choice:append(card:getId())
                            end
                        end
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _ = 1, cards:subcardsLength() do
                            room:fillAG(choice, damage.from)
                            local id = room:askForAG(damage.from, choice, false, self:objectName())
                            choice:removeOne(id)
                            for _, card in sgs.qlist(damage.from:getCards('he')) do
                                if card:getId() == id then
                                    dummy:addSubcard(card:getId())
                                end
                                for _, i in sgs.qlist(cards:getSubcards()) do
                                    choice:removeOne(i)
                                end
                            end
                            for _, i in sgs.qlist(cards:getSubcards()) do
                                if i == id then
                                    room:obtainCard(damage.from, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(
                                        sgs.CardMoveReason_S_REASON_EXTRACTION, damage.from:objectName()),
                                        room:getCardPlace(id) ~= sgs.Player_PlaceHand)
                                    room:clearAG(damage.from)
                                    if sgs.GetConfig('huanghao_down', true) then
                                        room:addPlayerMark(damage.from, '@huisheng')
                                    end
                                    return true
                                end
                            end
                            room:clearAG(damage.from)
                        end
                        if dummy:subcardsLength() > 0 then
                            room:throwCard(dummy, damage.from, damage.from)
                        end
                    else
                        local ids = sgs.IntList()
                        for _, id in sgs.qlist(cards:getSubcards()) do
                            sgs.Sanguosha:getCard(id):setTag('huisheng', sgs.QVariant(true))
                            ids:append(id)
                        end
                        room:setPlayerFlag(damage.from, 'Fake_Move')
                        local _guojia = sgs.SPlayerList()
                        _guojia:append(damage.from)
                        local move = sgs.CardsMoveStruct(ids, player, damage.from, sgs.Player_PlaceHand,
                            sgs.Player_PlaceHand, sgs.CardMoveReason())
                        local moves = sgs.CardsMoveList()
                        moves:append(move)
                        room:notifyMoveCards(true, moves, false, _guojia)
                        room:notifyMoveCards(false, moves, false, _guojia)
                        room:addPlayerMark(damage.from, 'huisheng', ids:length())
                        room:setTag('huisheng', sgs.QVariant(0))
                        for _, id in sgs.qlist(ids) do
                            room:setCardFlag(sgs.Sanguosha:getCard(id), 'huisheng')
                        end
                        room:askForUseCard(damage.from, '@@huisheng!', '@@huisheng!')
                        for _, id in sgs.qlist(ids) do
                            room:setCardFlag(sgs.Sanguosha:getCard(id), '-huisheng')
                        end
                        room:setPlayerMark(damage.from, 'huisheng', 0)
                        local move_to = sgs.CardsMoveStruct(ids, damage.from, player, sgs.Player_PlaceHand,
                            sgs.Player_PlaceHand, sgs.CardMoveReason())
                        local moves_to = sgs.CardsMoveList()
                        moves_to:append(move_to)
                        room:notifyMoveCards(true, moves_to, false, _guojia)
                        room:notifyMoveCards(false, moves_to, false, _guojia)
                        room:setPlayerFlag(damage.from, '-Fake_Move')
                        for _, id in sgs.qlist(ids) do
                            if sgs.Sanguosha:getCard(id):getTag('huisheng'):toBool() then
                                sgs.Sanguosha:getCard(id):removeTag('huisheng')
                            else
                                if sgs.GetConfig('huanghao_down', true) then
                                    room:addPlayerMark(damage.from, '@huisheng')
                                end
                                room:obtainCard(damage.from, sgs.Sanguosha:getCard(id), false)
                                return true
                            end
                        end
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, card in sgs.qlist(damage.from:getCards('he')) do
                            if card:getTag('huisheng'):toBool() then
                                dummy:addSubcard(card:getId())
                                card:removeTag('huisheng')
                            end
                        end
                        room:throwCard(dummy, damage.from, damage.from)
                    end
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
            room:removeTag('CurrentDamageStruct')
        end
        return false
    end,
}
huanghao:addSkill(huisheng)
sunziliufang = sgs.General(extension6, 'sunziliufang', 'wei', 3)
guizao = sgs.CreateTriggerSkill {
    name = 'guizao',
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == player:objectName() and
                move.from:hasSkill(self:objectName()) and
                (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                    sgs.CardMoveReason_S_REASON_DISCARD) then
                local guizao_ex = {}
                for _, id in sgs.qlist(move.card_ids) do
                    if table.contains(guizao_ex, sgs.Sanguosha:getCard(id):getSuit()) then
                        room:setPlayerMark(player, 'guizao_biu', 0)
                        return false
                    end
                    table.insert(guizao_ex, sgs.Sanguosha:getCard(id):getSuit())
                    room:setPlayerMark(player, 'guizao_biu', #guizao_ex)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark('guizao_biu') >= 2 and
            RIGHT(self, player) then
            local choices = {'guizao1+cancel'}
            if player:isWounded() then
                table.insert(choices, 'guizao2')
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
            if choice ~= 'cancel' then
                lazy(self, room, player, choice, true)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    if choice == 'guizao1' then
                        player:drawCards(1, self:objectName())
                    else
                        room:recover(player, sgs.RecoverStruct(player))
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sunziliufang:addSkill(guizao)
jiyuCard = sgs.CreateSkillCard {
    name = 'jiyu',
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isKongcheng() and to_select:getMark('jiyu_Play') == 0
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(targets[1], 'jiyu_Play')
        room:notifySkillInvoked(source, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), 2)
        local _data = sgs.QVariant()
        _data:setValue(source)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            if targets[1]:canDiscard(targets[1], 'h') then
                local card = room:askForCard(targets[1], '.!', '@jiyu', _data)
                if card then
                    room:setPlayerCardLimitation(source, 'use', '.|' .. card:getSuitString(), true)
                    if card:getSuit() == sgs.Card_Spade then
                        room:broadcastSkillInvoke(self:objectName(), 1)
                        source:turnOver()
                        room:loseHp(targets[1])
                    end
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
jiyu = sgs.CreateZeroCardViewAsSkill {
    name = 'jiyu',
    view_as = function(self, cards)
        local card = jiyuCard:clone()
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        for _, card in sgs.qlist(player:getHandcards()) do
            if card:isAvailable(player) then
                return true
            end
        end
        return false
    end,
}
sunziliufang:addSkill(jiyu)
zhangrang = sgs.General(extension6, 'zhangrang', 'qun', 3)
local patterns = {}
for i = 0, 10000 do
    local card = sgs.Sanguosha:getEngineCard(i)
    if card == nil then
        break
    end
    if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and (card:isKindOf('BasicCard') or card:isNDTrick()) and
        not table.contains(patterns, card:objectName()) then
        table.insert(patterns, card:objectName())
    end
end
function getPos(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return 0
end
local pos = 0
taoluan_select = sgs.CreateSkillCard {
    name = 'taoluan',
    will_throw = false,
    target_fixed = true,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        local choices = {}
        for _, name in ipairs(patterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            poi:setSkillName('taoluan')
            poi:addSubcard(self:getSubcards():first())
            if poi:isAvailable(source) and source:getMark('taoluan' .. name) == 0 and
                not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
                table.insert(choices, name)
            end
        end
        if next(choices) ~= nil then
            table.insert(choices, 'cancel')
            local pattern = room:askForChoice(source, 'taoluan', table.concat(choices, '+'))
            if pattern and pattern ~= 'cancel' then
                local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                if poi:targetFixed() then
                    poi:setSkillName('taoluan')
                    poi:addSubcard(self:getSubcards():first())
                    room:useCard(sgs.CardUseStruct(poi, source, source), true)
                else
                    pos = getPos(patterns, pattern)
                    room:setPlayerMark(source, 'taoluanpos', pos)
                    room:setPlayerProperty(source, 'taoluan', sgs.QVariant(self:getSubcards():first()))
                    room:askForUseCard(source, '@@taoluan', '@taoluan:' .. pattern) -- %src
                end
            end
        end
    end,
}
taoluanCard = sgs.CreateSkillCard {
    name = 'taoluanCard',
    will_throw = false,
    filter = function(self, targets, to_select)
        local name
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do
            plist:append(targets[i])
        end
        local aocaistring = self:getUserString()
        if aocaistring ~= '' then
            local uses = aocaistring:split('+')
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            card:addSubcard(self:getSubcards():first())
            if card and card:targetFixed() then
                return false
            else
                return card and card:targetFilter(plist, to_select, sgs.Self) and
                           not sgs.Self:isProhibited(to_select, card, plist)
            end
        end
        return true
    end,
    target_fixed = function(self)
        local name
        local card
        local aocaistring = self:getUserString()
        if aocaistring ~= '' then
            local uses = aocaistring:split('+')
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        card:addSubcard(self:getSubcards():first())
        return card and card:targetFixed()
    end,
    feasible = function(self, targets)
        local name
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do
            plist:append(targets[i])
        end
        local aocaistring = self:getUserString()
        if aocaistring ~= '' then
            local uses = aocaistring:split('+')
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        card:addSubcard(self:getSubcards():first())
        return card and card:targetsFeasible(plist, sgs.Self)
    end,
    on_validate_in_response = function(self, user)
        local room = user:getRoom()
        local aocaistring = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
        if string.find(aocaistring, '+') then
            local uses = {}
            for _, name in pairs(aocaistring:split('+')) do
                if user:getMark('taoluan' .. name) == 0 then
                    table.insert(uses, name)
                end
            end
            local name = room:askForChoice(user, 'taoluan', table.concat(uses, '+'))
            use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        use_card:addSubcard(self:getSubcards():first())
        use_card:setSkillName('taoluan')
        return use_card
    end,
    on_validate = function(self, card_use)
        local room = card_use.from:getRoom()
        local aocaistring = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
        if string.find(aocaistring, '+') then
            local uses = {}
            for _, name in pairs(aocaistring:split('+')) do
                if card_use.from:getMark('taoluan' .. name) == 0 then
                    table.insert(uses, name)
                end
            end
            local name = room:askForChoice(card_use.from, 'taoluan', table.concat(uses, '+'))
            use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        if use_card == nil then
            return false
        end
        use_card:setSkillName('taoluan')
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
        use_card:addSubcard(self:getSubcards():first())
        return use_card
    end,
}
taoluanVS = sgs.CreateViewAsSkill {
    name = 'taoluan',
    n = 1,
    response_or_use = true,
    view_filter = function(self, selected, to_select)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern and pattern == '@@taoluan' then
            return false
        else
            return true
        end
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if #cards == 1 then
                local acard = taoluan_select:clone()
                acard:addSubcard(cards[1]:getId())
                return acard
            end
        else
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == 'slash' then
                pattern = 'slash+thunder_slash+fire_slash'
            end
            local acard = taoluanCard:clone()
            if pattern and pattern == '@@taoluan' then
                pattern = patterns[sgs.Self:getMark('taoluanpos')]
                acard:addSubcard(sgs.Self:property('taoluan'):toInt())
                if #cards ~= 0 then
                    return
                end
            else
                if #cards ~= 1 then
                    return
                end
                acard:addSubcard(cards[1]:getId())
            end
            if pattern == 'peach+analeptic' and sgs.Self:hasFlag('Global_PreventPeach') then
                pattern = 'analeptic'
            end
            acard:setUserString(pattern)
            return acard
        end
    end,
    enabled_at_play = function(self, player)
        local choices = {}
        for _, name in ipairs(patterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            if poi:isAvailable(player) and player:getMark('taoluan' .. name) == 0 then
                table.insert(choices, name)
            end
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if sgs.GetConfig('taoluan_down', true) and (p:hasFlag('Global_Dying') or player:hasFlag('Global_Dying')) then
                return false
            end
        end
        return next(choices) and player:getMark('taoluan-Clear') == 0
    end,
    enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or
            player:getMark('taoluan-Clear') > 0 then
            return false
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if sgs.GetConfig('taoluan_down', true) and (p:hasFlag('Global_Dying') or player:hasFlag('Global_Dying')) then
                return false
            end
        end
        for _, p in pairs(pattern:split('+')) do
            if player:getMark(self:objectName() .. p) == 0 then
                return true
            end
        end
    end,
    enabled_at_nullification = function(self, player, pattern)
        return player:getMark('taoluannullification') == 0 and player:getMark('taoluan-Clear') == 0
    end,
}
taoluan = sgs.CreateTriggerSkill {
    name = 'taoluan',
    view_as_skill = taoluanVS,
    events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card and card:getHandlingMethod() == sgs.Card_MethodUse then
                if card:getSkillName() == 'taoluan' and player:getMark('taoluan' .. card:objectName()) == 0 then
                    room:addPlayerMark(player, 'taoluan' .. card:objectName())
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:getSkillName() == 'taoluan' and use.card:getTypeId() ~= 0 then
                local types = {'BasicCard', 'TrickCard', 'EquipCard'}
                table.removeOne(types, types[use.card:getTypeId()])
                room:setTag('TaoluanType', sgs.QVariant(table.concat(types, ',')))
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    '@taoluan-ask:' .. use.card:objectName(), false, true)
                room:removeTag('TaoluanType')
                if target then
                    local card
                    if not target:isKongcheng() then
                        card = room:askForCard(target, table.concat(types, ','), '@taoluan-give:' .. player:objectName(),
                            data, sgs.Card_MethodNone)
                    end
                    if card then
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(),
                            player:objectName(), self:objectName(), nil)
                        reason.m_playerId = player:objectName()
                        room:moveCardTo(card, target, player, sgs.Player_PlaceHand, reason)
                    else
                        room:loseHp(player)
                        room:addPlayerMark(player, 'taoluan-Clear')
                    end
                end
            end
        end
    end,
}
zhangrang:addSkill(taoluan)
guansuo = sgs.General(extension, 'guansuo', 'shu')
zhengnan = sgs.CreateTriggerSkill {
    name = 'zhengnan',
    events = {sgs.Deathed},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(p, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(p, self:objectName() .. 'engine')
                if p:getMark(self:objectName() .. 'engine') > 0 then
                    p:drawCards(3, self:objectName())
                    local choices = {}
                    if not p:hasSkill('wusheng') then
                        table.insert(choices, 'wusheng')
                    end
                    if not p:hasSkill('zhiman') then
                        table.insert(choices, 'zhiman')
                    end
                    if not p:hasSkill('dangxian') then
                        table.insert(choices, 'dangxian')
                    end
                    if #choices > 0 then
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, '+'))
                        room:acquireSkill(p, choice)
                    end
                    room:removePlayerMark(p, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
guansuo:addSkill(zhengnan)
guansuo:addRelateSkill('wusheng')
guansuo:addRelateSkill('dangxian')
guansuo:addRelateSkill('zhiman')
xiefang = sgs.CreateDistanceSkill {
    name = 'xiefang',
    correct_func = function(self, from, to)
        if from:hasSkill(self:objectName()) then
            return -from:getMark(self:objectName())
        end
        return 0
    end,
}
guansuo:addSkill(xiefang)
yanbaihu = sgs.General(extension_pm, 'yanbaihu', 'qun')
zhidao = sgs.CreateTriggerSkill {
    name = 'zhidao',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if not damage.to:isAllNude() and damage.to:objectName() ~= player:objectName() and player:getPhase() ==
            sgs.Player_Play and player:getMark('zhidao_Play') == 0 then
            SendComLog(self, player)
            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if not damage.to:isKongcheng() then
                    local id1 = room:askForCardChosen(player, damage.to, 'h', self:objectName())
                    dummy:addSubcard(id1)
                end
                if not damage.to:getEquips():isEmpty() then
                    local id2 = room:askForCardChosen(player, damage.to, 'e', self:objectName())
                    dummy:addSubcard(id2)
                end
                if not damage.to:getJudgingArea():isEmpty() then
                    local id3 = room:askForCardChosen(player, damage.to, 'j', self:objectName())
                    dummy:addSubcard(id3)
                end
                if dummy:subcardsLength() > 0 then
                    room:obtainCard(player, dummy,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
                    room:addPlayerMark(player, 'zhidao_Play')
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
zhidaomod = sgs.CreateProhibitSkill {
    name = '#zhidaomod',
    is_prohibited = function(self, from, to, card)
        return
            from:hasSkill(self:objectName()) and not card:isKindOf('SkillCard') and from:objectName() ~= to:objectName() and
                from:getMark('zhidao_Play') ~= 0
    end,
}
yanbaihu:addSkill(zhidao)
yanbaihu:addSkill(zhidaomod)
extension:insertRelatedSkills('zhidao', '#zhidaomod')
jili = sgs.CreateTriggerSkill {
    name = 'jili',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if use.card and use.card:isRed() and use.from:objectName() ~= p:objectName() and not use.to:contains(p) and
                (use.card:isKindOf('BasicCard') or use.card:isNDTrick()) and not use.card:isKindOf('Collateral') and
                player:distanceTo(p) == 1 and not room:isProhibited(use.from, p, use.card) then
                local n = 1
                if use.card:isKindOf('Peach') or use.card:isKindOf('ExNihilo') or use.card:isKindOf('Analeptic') then
                    n = 2
                end
                room:broadcastSkillInvoke(self:objectName(), n)
                room:sendCompulsoryTriggerLog(p, self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    use.to:append(p)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
yanbaihu:addSkill(jili)
tadun = sgs.General(extension_pm, 'tadun', 'qun')
luanzhanCard = sgs.CreateSkillCard {
    name = 'luanzhan',
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark('@luanz') and to_select:getMark(self:objectName()) == 0 and
                   sgs.Sanguosha:getCard(sgs.Self:getMark('card_id')):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and
                   not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark('card_id')))
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            for _, p in pairs(targets) do
                room:addPlayerMark(p, self:objectName())
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
luanzhanVS = sgs.CreateZeroCardViewAsSkill {
    name = 'luanzhan',
    response_pattern = '@@luanzhan',
    view_as = function()
        return luanzhanCard:clone()
    end,
}
luanzhan = sgs.CreateTriggerSkill {
    name = 'luanzhan',
    events = {sgs.PreCardUsed, sgs.TargetSpecified, sgs.HpChanged},
    view_as_skill = luanzhanVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() and player:getMark('@luanz') > 0 and
                (use.card:isKindOf('Slash') or
                    (use.card:isNDTrick() and use.card:isBlack() and not use.card:isKindOf('Collateral') and
                        not use.card:isKindOf('Nullification'))) then
                for _, p in sgs.qlist(use.to) do
                    room:addPlayerMark(p, self:objectName())
                end
                room:setPlayerMark(player, 'card_id', use.card:getEffectiveId())
                room:askForUseCard(player, '@@luanzhan', '@luanzhan')
                room:setPlayerMark(player, 'card_id', 0)
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark(self:objectName()) > 0 and not room:isProhibited(player, p, use.card) then
                        room:removePlayerMark(p, self:objectName())
                        if not use.to:contains(p) then
                            use.to:append(p)
                        end
                    end
                end
                room:sortByActionOrder(use.to)
                data:setValue(use)
            elseif use.from:objectName() == player:objectName() and use.card:isKindOf('Collateral') and use.card:isBlack() then
                for _ = 1, player:getMark('@luanz') do
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if use.to:contains(p) or room:isProhibited(player, p, use.card) then
                            goto next_target
                        end
                        if use.card:targetFilter(sgs.PlayerList(), p, player) then
                            targets:append(p)
                        end
                        ::next_target::
                    end
                    if targets:isEmpty() then
                        return false
                    end
                    local tos = {}
                    for _, t in sgs.qlist(use.to) do
                        table.insert(tos, t:objectName())
                    end
                    room:setPlayerProperty(player, 'extra_collateral', sgs.QVariant(use.card:toString()))
                    room:setPlayerProperty(player, 'extra_collateral_current_targets', sgs.QVariant(table.concat(tos, '+')))
                    local used = room:askForUseCard(player, '@@ExtraCollateral', '@qiaoshui-add:::collateral')
                    room:setPlayerProperty(player, 'extra_collateral', sgs.QVariant(''))
                    room:setPlayerProperty(player, 'extra_collateral_current_targets', sgs.QVariant('+'))
                    if not used then
                        return false
                    end
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            if p:hasFlag('ExtraCollateralTarget') then
                                p:setFlags('-ExtraColllateralTarget')
                                extra = p
                                break
                            end
                        end
                        if extra == nil then
                            return false
                        end
                        use.to:append(extra)
                        room:sortByActionOrder(use.to)
                        data:setValue(use)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    else
                        return false
                    end
                end
            end
        elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() and
                (use.card:isKindOf('Slash') or (use.card:isNDTrick() and use.card:isBlack())) and use.to:length() <
                player:getMark('@luanz') then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:loseAllMarks('@luanz')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.HpChanged then
            local damage = data:toDamage()
            if damage and damage.damage and damage.damage > 0 and RIGHT(self, damage.from) then
                damage.from:gainMark('@luanz')
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
tadun:addSkill(luanzhan)
wanglang = sgs.General(extension, 'wanglang', 'wei', 3)
gusheCard = sgs.CreateSkillCard {
    name = 'gushe',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 3 and sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            if #targets == 1 then
                source:pindian(targets[1], 'gushe', sgs.Sanguosha:getCard(self:getSubcards():first()))
                source:setFlags('-jiciused')
                return
            end
            local slash = sgs.Sanguosha:cloneCard('slash')
            slash:addSubcard(self:getSubcards():first())
            local moves = sgs.CardsMoveList()
            local move = sgs.CardsMoveStruct(self:getSubcards(), source, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, source:objectName(), self:objectName(), ''))
            moves:append(move)
            for _, p in pairs(targets) do
                local card = room:askForExchange(p, self:objectName(), 1, 1, false, '@gushepindian:' .. source:objectName())
                slash:addSubcard(card:getSubcards():first())
                room:setPlayerMark(p, 'gusheid', card:getSubcards():first() + 1)
                local _move = sgs.CardsMoveStruct(card:getSubcards(), p, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, p:objectName(), self:objectName(), ''))
                moves:append(_move)
            end
            room:moveCardsAtomic(moves, true)
            for i = 1, #targets, 1 do
                local pindian = sgs.PindianStruct()
                pindian.from = source
                pindian.to = targets[i]
                pindian.from_card = sgs.Sanguosha:getCard(self:getSubcards():first())
                pindian.to_card = sgs.Sanguosha:getCard(targets[i]:getMark('gusheid') - 1)
                if not source:hasFlag('jiciused') then
                    pindian.from_number = pindian.from_card:getNumber()
                else
                    pindian.from_number = pindian.from_card:getNumber() + source:getMark('@she')
                end
                pindian.to_number = pindian.to_card:getNumber()
                pindian.reason = 'gushe'
                room:setPlayerMark(targets[i], 'gusheid', 0)
                local data = sgs.QVariant()
                data:setValue(pindian)
                local log = sgs.LogMessage()
                log.type = '$PindianResult'
                log.from = pindian.from
                log.card_str = pindian.from_card:toString()
                room:sendLog(log)
                log.from = pindian.to
                log.card_str = pindian.to_card:toString()
                room:sendLog(log)
                if not source:hasFlag('jiciused') then
                    room:getThread():trigger(sgs.PindianVerifying, room, source, data)
                end
                room:getThread():trigger(sgs.Pindian, room, source, data)
            end
            source:setFlags('-jiciused')
            local move2 = sgs.CardsMoveStruct(slash:getSubcards(), nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ''))
            moves:append(move2)
            room:moveCardsAtomic(moves, true)
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
gusheVS = sgs.CreateOneCardViewAsSkill {
    name = 'gushe',
    filter_pattern = '.|.|.|hand!',
    view_as = function(self, card)
        local aaa = gusheCard:clone()
        aaa:addSubcard(card)
        return aaa
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#gushe') < 1 + player:getMark('jiciextra-Clear') and player:canPindian()
    end,
}
gushe = sgs.CreateTriggerSkill {
    name = 'gushe',
    events = {sgs.Pindian, sgs.MarkChanged},
    view_as_skill = gusheVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason ~= self:objectName() then
                return false
            end
            local winner
            local loser
            if pindian.from_number > pindian.to_number then
                winner = pindian.from
                loser = pindian.to
                local log = sgs.LogMessage()
                log.type = '#PindianSuccess'
                log.from = winner
                log.to:append(loser)
                room:sendLog(log)
            elseif pindian.from_number < pindian.to_number then
                winner = pindian.to
                loser = pindian.from
                local log = sgs.LogMessage()
                log.type = '#PindianFailure'
                log.from = loser
                log.to:append(winner)
                room:sendLog(log)
                pindian.from:gainMark('@she')
            else
                pindian.from:gainMark('@she')
                if pindian.from:isAlive() and not room:askForDiscard(pindian.from, self:objectName(), 1, 1, true) then
                    pindian.from:drawCards(1, self:objectName())
                end
                if pindian.to:isAlive() then
                    if pindian.from:isAlive() then
                        if not room:askForDiscard(pindian.to, self:objectName(), 1, 1, true) then
                            pindian.from:drawCards(1, self:objectName())
                        end
                    else
                        room:askForDiscard(pindian.to, self:objectName(), 1, 1, true)
                    end
                end
                return false
            end
            if pindian.from:isAlive() then
                if loser:isAlive() and not room:askForDiscard(loser, self:objectName(), 1, 1, true) then
                    pindian.from:drawCards(1, self:objectName())
                end
            else
                if loser:isAlive() and not loser:isNude() then
                    room:askForDiscard(loser, self:objectName(), 1, 1)
                end
            end
        else
            local mark = data:toMark()
            if mark.name == '@she' and mark.who:hasSkill('gushe') and mark.who:getMark('@she') >= 7 then
                room:killPlayer(mark.who)
            end
        end
        return false
    end,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
}
wanglang:addSkill(gushe)
jici = sgs.CreateTriggerSkill {
    name = 'jici',
    events = sgs.PindianVerifying,
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if pindian.reason == 'gushe' and pindian.from:objectName() == player:objectName() then
            local x = player:getMark('@she')
            if pindian.from_number < x and player:askForSkillInvoke(self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:setFlags('jiciused')
                    local log = sgs.LogMessage()
                    log.type = '#jicipindian'
                    log.from = pindian.from
                    log.arg = pindian.from_number
                    pindian.from_number = pindian.from_number + x
                    if pindian.from_number > 13 then
                        pindian.from_number = 13
                    end
                    log.arg2 = pindian.from_number
                    room:sendLog(log)
                    data:setValue(pindian)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                    return
                end
            end
            if pindian.from_number == x then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setPlayerFlag(player, 'jiciused')
                    room:addPlayerMark(player, 'jiciextra-Clear')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
wanglang:addSkill(jici)
ol_machao = sgs.General(extension_sp, 'ol_machao', 'qun', 4, true, sgs.GetConfig('EnableHidden', true))
ol_zhuiji = sgs.CreateDistanceSkill {
    name = 'ol_zhuiji',
    correct_func = function(self, from, to)
        if from:hasSkill(self:objectName()) and from:getHp() >= to:getHp() then
            return -1000
        end
        return 0
    end,
}
ol_machao:addSkill(ol_zhuiji)
ol_shichou = sgs.CreateTargetModSkill {
    name = 'ol_shichou',
    frequency = sgs.Skill_NotCompulsory,
    extra_target_func = function(self, from)
        if from:hasSkill(self:objectName()) then
            return from:getLostHp()
        end
        return 0
    end,
}
ol_machao:addSkill(ol_shichou)
ol_jiaxu = sgs.General(extension_sp, 'ol_jiaxu', 'wei', 3, true, sgs.GetConfig('EnableHidden', true))
zhenlve = sgs.CreateTriggerSkill {
    name = 'zhenlve',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TrickCardCanceling},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        if RIGHT(self, effect.from) then
            SendComLog(self, effect.from)
            room:addPlayerMark(effect.from, self:objectName() .. 'engine')
            if effect.from:getMark(self:objectName() .. 'engine') > 0 then
                room:removePlayerMark(effect.from, self:objectName() .. 'engine')
                return true
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_jiaxu:addSkill(zhenlve)
jianshuCard = sgs.CreateSkillCard {
    name = 'jianshu',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:removePlayerMark(source, '@book')
            room:obtainCard(targets[1], sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ''))
            local players = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(targets[1])) do
                if p:inMyAttackRange(targets[1]) and p:objectName() ~= source:objectName() and
                    targets[1]:canPindian(p, self:objectName()) then
                    players:append(p)
                end
            end
            if not players:isEmpty() then
                local player = room:askForPlayerChosen(source, players, self:objectName(), '@jianshu')
                targets[1]:pindian(player, self:objectName())
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
jianshuVS = sgs.CreateOneCardViewAsSkill {
    name = 'jianshu',
    filter_pattern = '.|black',
    view_as = function(self, card)
        local cards = jianshuCard:clone()
        cards:addSubcard(card)
        return cards
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@book') > 0
    end,
}
jianshu = sgs.CreateTriggerSkill {
    name = 'jianshu',
    view_as_skill = jianshuVS,
    frequency = sgs.Skill_Limited,
    limit_mark = '@book',
    events = {sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if pindian.reason == self:objectName() then
            local winner = pindian.from
            local loser = pindian.to
            local players = sgs.SPlayerList()
            if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
                winner = pindian.to
                loser = pindian.from
            elseif pindian.from_card:getNumber() == pindian.to_card:getNumber() then
                players:append(winner)
                winner = nil
            end
            players:append(loser)
            if winner then
                room:askForDiscard(winner, self:objectName(), 2, 2, false, true)
            end
            room:sortByActionOrder(players)
            for _, p in sgs.qlist(players) do
                if p:isAlive() then
                    room:loseHp(p)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_jiaxu:addSkill(jianshu)
yongdi = sgs.CreateMasochismSkill {
    name = 'yongdi',
    limit_mark = '@yong',
    frequency = sgs.Skill_Limited,
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isMale() then
                targets:append(p)
            end
        end
        if not targets:isEmpty() and player:getMark('@yong') > 0 then
            local target = room:askForPlayerChosen(player, targets, self:objectName(), 'yongdi-invoke', true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:removePlayerMark(player, '@yong')
                    room:gainMaxHp(target)
                    local lord = {}
                    for _, skill in sgs.qlist(target:getGeneral():getVisibleSkillList()) do
                        if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) and not target:isLord() then
                            table.insert(lord, skill:objectName())
                        end
                    end
                    if target:getGeneral2() then
                        for _, skill in sgs.qlist(target:getGeneral2():getVisibleSkillList()) do
                            if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) and not target:isLord() then
                                table.insert(lord, skill:objectName())
                            end
                        end
                    end
                    room:handleAcquireDetachSkills(target, table.concat(lord, '|'))
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
ol_jiaxu:addSkill(yongdi)
ol_zumao = sgs.General(extension_yijiang, 'ol_zumao', 'wu', 4, true, sgs.GetConfig('EnableHidden', true))
ol_zumao:addSkill('yinbing')
ol_juedi = sgs.CreateTriggerSkill {
    name = 'ol_juedi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and not player:getPile('hat'):isEmpty() then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getHp() <= player:getHp() then
                    targets:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), '@ol_juedi', false, true)
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if target:objectName() == player:objectName() then
                    player:clearOnePrivatePile('hat')
                    if player:getHandcardNum() < player:getMaxHp() then
                        player:drawCards(player:getMaxHp() - player:getHandcardNum())
                    end
                else
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    local x = player:getPile('hat'):length()
                    for _, c in sgs.qlist(player:getPile('hat')) do
                        dummy:addSubcard(c)
                    end
                    room:obtainCard(target, dummy)
                    dummy:deleteLater()
                    room:recover(target, sgs.RecoverStruct(player))
                    target:drawCards(x)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
ol_zumao:addSkill(ol_juedi)
ol_caozhen = sgs.General(extension_yijiang, 'ol_caozhen', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
ol_sidi = sgs.CreateTriggerSkill {
    name = 'ol_sidi',
    global = true,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if player:getPhase() == sgs.Player_Play and p:objectName() ~= player:objectName() and p:hasEquip() then
                if event == sgs.EventPhaseStart then
                    local _data = sgs.QVariant()
                    _data:setValue(player)
                    local extra = ''
                    for _, card in sgs.qlist(p:getCards('e')) do
                        if extra ~= '' then
                            extra = extra .. ','
                        end
                        extra = extra .. GetColor(card)
                    end
                    local card = room:askForCard(p, '^BasicCard|' .. extra, '@ol_sidi:' .. player:objectName(), _data,
                        self:objectName())
                    if card then
                        room:addPlayerMark(p, self:objectName() .. 'engine')
                        if p:getMark(self:objectName() .. 'engine') > 0 then
                            room:setPlayerCardLimitation(player, 'use, response', '.|' .. GetColor(card), true)
                            player:setFlags(self:objectName())
                            room:removePlayerMark(p, self:objectName() .. 'engine')
                        end
                    end
                else
                    if player:hasFlag(self:objectName()) and player:getMark('used_slash-Clear') == 0 and
                        p:canSlash(player, nil, false) then
                        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        slash:setSkillName('_ol_sidi')
                        room:useCard(sgs.CardUseStruct(slash, p, player))
                    end
                end
            end
        end
        return false
    end,
}
ol_caozhen:addSkill(ol_sidi)
ol_zhoucang = sgs.General(extension_yijiang, 'ol_zhoucang', 'shu', 4, true, sgs.GetConfig('EnableHidden', true))
ol_zhongyong = sgs.CreateTriggerSkill {
    name = 'ol_zhongyong',
    events = {sgs.SlashMissed, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashMissed then
            room:addPlayerMark(player, self:objectName() .. data:toSlashEffect().jink:getEffectiveId())
        else
            local use = data:toCardUse()
            local friends, targets = sgs.SPlayerList(), sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not use.to:contains(player) then
                    friends:append(p)
                end
                if player:inMyAttackRange(p) then
                    targets:append(p)
                end
            end
            for _, p in sgs.qlist(use.to) do
                friends:removeOne(p)
            end
            if use.card and use.card:isKindOf('Slash') then
                local ids, slash = sgs.IntList(), sgs.IntList()
                for _, id in sgs.list(use.card:getSubcards()) do
                    if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
                        slash:append(id)
                        ids:append(id)
                    end
                end
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
                        local id = tonumber(string.sub(mark, 13, string.len(mark)))
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable and room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                            goto nextmark
                        end
                        ids:append(id)
                        room:setPlayerMark(player, mark, 0)
                    end
                    ::nextmark::
                end
                if not friends:isEmpty() then
                    room:fillAG(ids, player)
                    local id = room:askForAG(player, ids, true, self:objectName())
                    local help = false
                    if id ~= -1 then
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        skill(self, room, player, false)
                        local friend = room:askForPlayerChosen(player, friends, self:objectName(), '@ol_zhongyong', false,
                            true)
                        if friend then
                            room:addPlayerMark(player, self:objectName() .. 'engine')
                            if player:getMark(self:objectName() .. 'engine') > 0 then
                                room:broadcastSkillInvoke(self:objectName(), 1)
                                for _, i in sgs.list(slash) do
                                    if sgs.Sanguosha:getCard(i):isRed() then
                                        help = true
                                    end
                                    ids:removeOne(i)
                                end
                                if slash:contains(id) then
                                    dummy:addSubcards(slash)
                                else
                                    help = false
                                    for _, i in sgs.list(ids) do
                                        if sgs.Sanguosha:getCard(i):isRed() then
                                            help = true
                                        end
                                    end
                                    dummy:addSubcards(ids)
                                end
                                room:obtainCard(friend, dummy)
                                room:removePlayerMark(player, self:objectName() .. 'engine')
                            end
                        end
                        if not targets:isEmpty() and help then
                            room:setPlayerFlag(friend, self:objectName())
                            if room:askForUseSlashTo(friend, targets, self:objectName(), false, false, false) then
                                room:broadcastSkillInvoke(self:objectName(), 1)
                            end
                            room:setPlayerFlag(friend, '-' .. self:objectName())
                        end
                    end
                    room:clearAG(player)
                end
            end
        end
        return false
    end,
}
ol_zhoucang:addSkill(ol_zhongyong)
bf_lingtong = sgs.General(extension_bf, 'bf_lingtong', 'wu', 4, true, sgs.GetConfig('hidden_ai', true))
xuanlve = sgs.CreateTriggerSkill {
    name = 'xuanlve',
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canDiscard(p, 'he') then
                    targets:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), 'xuanlve-invoke', true, true)
            if target then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local id = room:askForCardChosen(player, target, 'he', self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(id, target, player)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
bf_lingtong:addSkill(xuanlve)
yongjinCard = sgs.CreateSkillCard {
    name = 'yongjin',
    will_throw = false,
    filter = function(self, targets, to_select)
        if self:subcardsLength() == 0 or #targets == 1 then
            return false
        end
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local equip = card:getRealCard():toEquipCard()
        local equip_index = equip:location()
        return to_select:getEquip(equip_index) == nil and to_select:hasEquipArea(equip_index)
    end,
    feasible = function(self, targets)
        if sgs.Self:hasFlag('yongjin') then
            return #targets == 1
        end
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        if source:hasFlag('yongjin') then
            room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), self:objectName(), ''))
        else
            room:doSuperLightbox('bf_lingtong', self:objectName())
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                room:removePlayerMark(source, '@yongjin')
                local ids = sgs.IntList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    for _, card in sgs.qlist(p:getCards('e')) do
                        ids:append(card:getId())
                    end
                end
                room:fillAG(ids)
                local t = 0
                for i = 1, 3 do
                    local id = room:askForAG(source, ids, i ~= 1, self:objectName())
                    if id == -1 then
                        break
                    end
                    ids:removeOne(id)
                    source:obtainCard(sgs.Sanguosha:getCard(id))
                    room:takeAG(source, id, false)
                    room:setCardFlag(sgs.Sanguosha:getCard(id), 'yongjin')
                    t = i
                    if ids:isEmpty() then
                        break
                    end
                end
                room:clearAG()
                room:setPlayerFlag(source, 'yongjin')
                for _ = 1, t do
                    room:askForUseCard(source, '@@yongjin!', '@yongjin')
                end
                room:setPlayerFlag(source, '-yongjin')
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
        end
    end,
}
yongjinVS = sgs.CreateViewAsSkill {
    name = 'yongjin',
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:hasFlag('yongjin')
    end,
    view_as = function(self, cards)
        local card = yongjinCard:clone()
        if sgs.Self:hasFlag('yongjin') and cards[1] then
            card:addSubcard(cards[1])
        end
        return card
    end,
    enabled_at_play = function(self, player)
        if player:getMark('@yongjin') > 0 then
            for _, p in sgs.qlist(player:getAliveSiblings()) do
                if p:hasEquip() then
                    return true
                end
            end
            return player:hasEquip()
        end
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@yongjin')
    end,
}
yongjin = sgs.CreateTriggerSkill {
    name = 'yongjin',
    frequency = sgs.Skill_Limited,
    view_as_skill = yongjinVS,
    limit_mark = '@yongjin',
    on_trigger = function()
    end,
}
bf_lingtong:addSkill(yongjin)
lvfan = sgs.General(extension_bf, 'lvfan', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
tiaoduCard = sgs.CreateSkillCard {
    name = 'tiaodu',
    filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:objectName() == sgs.Self:objectName()
        end
        return to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            local card = room:askForCard(effect.to, '.Equip', '@tiaodu', sgs.QVariant(), sgs.Card_MethodNone)
            if card then
                if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand then
                    room:useCard(sgs.CardUseStruct(card, effect.to, effect.to))
                else
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
                        for i = 1, 5 do
                            if p:getEquip(i) ~= card and not targets:contains(p) and p:hasEquipArea(i) then
                                targets:append(p)
                            end
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(effect.to, targets, self:objectName(), 'tiaodu-invoke', true,
                            true)
                        if target then
                            room:moveCardTo(card, target, sgs.Player_PlaceEquip)
                        end
                    end
                end
            end
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
tiaodu = sgs.CreateZeroCardViewAsSkill {
    name = 'tiaodu',
    view_as = function()
        return tiaoduCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#tiaodu')
    end,
}
lvfan:addSkill(tiaodu)
diancai = sgs.CreateTriggerSkill {
    name = 'diancai',
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if event == sgs.CardsMoveOneTime then
                local move = data:toMoveOneTime()
                if (move.from and move.from:objectName() == p:objectName() and move.from:objectName() == player:objectName() and
                    (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and
                    not (move.to and
                        (move.to:objectName() == p:objectName() and
                            (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
                    room:addPlayerMark(p, self:objectName() .. '-Clear')
                end
            elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:objectName() ~=
                p:objectName() and p:getMark(self:objectName() .. '-Clear') >= p:getHp() and p:getMaxHp() >
                p:getHandcardNum() and room:askForSkillInvoke(p, self:objectName(), data) then
                room:addPlayerMark(p, self:objectName() .. 'engine')
                if p:getMark(self:objectName() .. 'engine') > 0 then
                    p:drawCards(p:getMaxHp() - p:getHandcardNum(), self:objectName())
                    if room:askForSkillInvoke(p, 'ChangeGeneral', data) then
                        ChangeGeneral(room, p)
                    end
                    room:removePlayerMark(p, self:objectName() .. 'engine')
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
lvfan:addSkill(diancai)
bf_xunyou = sgs.General(extension_bf, 'bf_xunyou', 'wei', 3, true, sgs.GetConfig('hidden_ai', true))
bf_qiceCard = sgs.CreateSkillCard {
    name = 'bf_qice',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local card = sgs.Self:getTag('bf_qice'):toCard()
        card:addSubcards(sgs.Self:getHandcards())
        card:setSkillName(self:objectName())
        if card and card:targetFixed() then
            return false
        end
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(card, qtargets)
    end,
    feasible = function(self, targets)
        local card = sgs.Self:getTag('bf_qice'):toCard()
        card:addSubcards(sgs.Self:getHandcards())
        card:setSkillName(self:objectName())
        local qtargets = sgs.PlayerList()
        local n = #targets
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        if n == 0 then
            if not sgs.Self:isProhibited(sgs.Self, card) and card:isKindOf('GlobalEffect') then
                n = 1
            end
            for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
                if not sgs.Self:isProhibited(p, card) and (card:isKindOf('AOE') or card:isKindOf('GlobalEffect')) then
                    n = n + 1
                end
            end
        end
        if card and ((card:canRecast() and n == 0) or (n > sgs.Self:getHandcardNum())) then
            return false
        end
        return card and card:targetsFeasible(qtargets, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
        use_card:addSubcards(card_use.from:getHandcards())
        use_card:setSkillName(self:objectName())
        local available = true
        for _, p in sgs.qlist(card_use.to) do
            if card_use.from:isProhibited(p, use_card) then
                available = false
                break
            end
        end
        available = available and use_card:isAvailable(card_use.from)
        if not available then
            return nil
        end
        return use_card
    end,
}
bf_qiceVS = sgs.CreateZeroCardViewAsSkill {
    name = 'bf_qice',
    view_as = function(self)
        local c = sgs.Self:getTag('bf_qice'):toCard()
        if c then
            local card = bf_qiceCard:clone()
            card:setUserString(c:objectName())
            card:addSubcards(sgs.Self:getHandcards())
            return card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#bf_qice') and not player:isKongcheng()
    end,
}
bf_qice = sgs.CreateTriggerSkill {
    name = 'bf_qice',
    view_as_skill = bf_qiceVS,
    global = true,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:getSkillName() == 'bf_qice' and use.card:getTypeId() ~= 0 and use.from then
            if room:askForSkillInvoke(use.from, 'ChangeGeneral', data) then
                ChangeGeneral(room, use.from)
            end
        end
    end,
}
bf_qice:setGuhuoDialog('r')
bf_xunyou:addSkill(bf_qice)
bf_xunyou:addSkill('zhiyu')
bianhuanghou = sgs.General(extension_bf, 'bianhuanghou', 'wei', 3, false, false, false)
wanwei = sgs.CreateTriggerSkill {
    name = 'wanwei',
    events = {sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data)
        local move = data:toMoveOneTime()
        local room = player:getRoom()
        if move.from and move.from:objectName() == player:objectName() and
            ((move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and
                move.reason.m_playerId ~= move.reason.m_targetId) or
                (move.to and move.to:isAlive() and move.from:objectName() ~= move.to:objectName() and move.reason.m_reason ~=
                    sgs.CardMoveReason_S_REASON_PREVIEWGIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE and
                    move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP)) then
            local toReplace = sgs.IntList()
            local i = 0
            for _, id in sgs.qlist(move.card_ids) do
                if room:getCardOwner(id):objectName() == move.from:objectName() and
                    (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
                    toReplace:append(id)
                end
                i = i + 1
            end
            if not toReplace:isEmpty() then
                local card = room:askForExchange(player, self:objectName(), toReplace:length(), toReplace:length(), true,
                    'wanwei-invoke', true)
                if card and not card:getSubcards():isEmpty() then
                    -- move:removeCardIds(toReplace)
                    -- myetyet按：removeCardIds有毒，如果真的需要用请把源码Lua化
                    for _, p in sgs.qlist(toReplace) do
                        local _i = move.card_ids:indexOf(p)
                        if _i >= 0 then
                            move.card_ids:removeAt(i)
                            move.from_places:removeAt(i)
                            -- move.from_pile_names:removeAt(i)
                            -- move.open:removeAt(i)
                            -- myetyet按：以上两句有毒，请勿使用
                        end
                    end
                    for _, p in sgs.qlist(card:getSubcards()) do
                        move.card_ids:append(p)
                        move.from_places:append(room:getCardPlace(p))
                    end
                    data:setValue(move)
                end
            end
        end
        return false
    end,
}
bianhuanghou:addSkill(wanwei)
yuejian = sgs.CreatePhaseChangeSkill {
    name = 'yuejian',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if player:getPhase() == sgs.Player_Discard and player:getMark('qietin') == 0 and
                room:askForSkillInvoke(p, self:objectName()) then
                room:addPlayerMark(p, self:objectName() .. 'engine')
                if p:getMark(self:objectName() .. 'engine') > 0 then
                    player:setFlags('yuejian_buff')
                    room:removePlayerMark(p, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
yuejian_buff = sgs.CreateMaxCardsSkill {
    name = '#yuejian',
    fixed_func = function(self, target)
        if target:hasFlag('yuejian_buff') then
            return target:getMaxHp()
        end
        return -1
    end,
}
bianhuanghou:addSkill(yuejian)
bianhuanghou:addSkill(yuejian_buff)
extension:insertRelatedSkills('yuejian', '#yuejian')
bf_masu = sgs.General(extension_bf, 'bf_masu', 'shu', 3, true, sgs.GetConfig('hidden_ai', true))
bf_masu:addSkill('sanyao')
bf_zhiman = sgs.CreateTriggerSkill {
    name = 'bf_zhiman',
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local log = sgs.LogMessage()
            log.from = player
            log.to:append(damage.to)
            log.arg = self:objectName()
            log.type = '#Yishi'
            room:sendLog(log)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if damage.to:hasEquip() or damage.to:getJudgingArea():length() > 0 then
                    local card = room:askForCardChosen(player, damage.to, 'ej', self:objectName())
                    room:obtainCard(player, card, false)
                end
                if room:askForSkillInvoke(damage.to, 'ChangeGeneral', data) then
                    ChangeGeneral(room, damage.to)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
                return true
            end
        end
        return false
    end,
}
bf_masu:addSkill(bf_zhiman)
shamoke = sgs.General(extension_bf, 'shamoke', 'shu')
bf_jili = sgs.CreateTriggerSkill {
    name = 'bf_jili',
    global = true,
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and not card:isKindOf('SkillCard') then
            room:addPlayerMark(player, self:objectName() .. '-Clear')
            if player:getMark(self:objectName() .. '-Clear') == player:getAttackRange() and RIGHT(self, player) and
                room:askForSkillInvoke(player, self:objectName(), data) then
                player:drawCards(player:getAttackRange(), self:objectName())
            end
        end
    end,
}
shamoke:addSkill(bf_jili)
lijueguosi = sgs.General(extension_bf, 'lijueguosi', 'qun', 4, true, sgs.GetConfig('hidden_ai', true))
xiongsuanCard = sgs.CreateSkillCard {
    name = 'xiongsuan',
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:removePlayerMark(source, '@scary')
            room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
            source:drawCards(3, self:objectName())
            local SkillList = {}
            for _, skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
                if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and skill:getFrequency() ==
                    sgs.Skill_Limited then
                    table.insert(SkillList, skill:objectName())
                end
            end
            if #SkillList > 0 then
                local choice = room:askForChoice(source, self:objectName(), table.concat(SkillList, '+'))
                ChoiceLog(source, choice)
                room:addPlayerMark(targets[1], self:objectName() .. choice)
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
xiongsuanVS = sgs.CreateOneCardViewAsSkill {
    name = 'xiongsuan',
    filter_pattern = '.',
    view_as = function(self, card)
        local cards = xiongsuanCard:clone()
        cards:addSubcard(card)
        return cards
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@scary') > 0
    end,
}
xiongsuan = sgs.CreatePhaseChangeSkill {
    name = 'xiongsuan',
    view_as_skill = xiongsuanVS,
    frequency = sgs.Skill_Limited,
    limit_mark = '@scary',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            for _, skill in sgs.qlist(p:getVisibleSkillList()) do
                if p:getMark(self:objectName() .. skill:objectName()) > 0 and player:getPhase() == sgs.Player_Finish then
                    room:handleAcquireDetachSkills(p, '-' .. skill:objectName() .. '|' .. skill:objectName())
                end
            end
        end
    end,
}
lijueguosi:addSkill(xiongsuan)
bf_zuoci = sgs.General(extension_bf, 'bf_zuoci', 'qun', 3, true, sgs.GetConfig('EnableHidden', true))
cancel = sgs.General(extension_bf, 'cancel', 'qun', 3, true, true, true)
-- 避免 unused variable
cancel:setGender(sgs.General_Male)
bf_huashen = sgs.CreateTriggerSkill {
    name = 'bf_huashen',
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart, sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            local generals = sgs.Sanguosha:getLimitedGeneralNames()
            local huashenss = {}
            for _, name in pairs(generals) do
                if player:getMark('bf_huashen' .. name) > 0 then
                    table.removeOne(generals, name)
                    table.insert(huashenss, name)
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if table.contains(generals, p:getGeneralName()) then
                    table.removeOne(generals, p:getGeneralName())
                end
                if table.contains(generals, p:getGeneral2Name()) then
                    table.removeOne(generals, p:getGeneral2Name())
                end
            end
            if player:getPhase() == sgs.Player_Start and #generals > 0 and room:askForSkillInvoke(player, self:objectName()) then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:broadcastSkillInvoke(self:objectName())
                    local SkillList = {}
                    if #huashenss < 2 then
                        local huashens = {}
                        for _ = 1, 5 do
                            local name = generals[math.random(1, #generals)]
                            table.insert(huashens, name)
                            table.removeOne(generals, name)
                        end
                        for _ = 1, 2 do
                            huashenss = {}
                            for _, name in pairs(generals) do
                                if player:getMark('bf_huashen' .. name) > 0 then
                                    table.removeOne(generals, name)
                                    table.insert(huashenss, name)
                                end
                            end
                            if #huashenss > 0 then
                                table.insert(huashens, 'cancel')
                            end
                            local general = room:askForGeneral(player, table.concat(huashens, '+'))
                            if general == 'cancel' then
                                return false
                            end
                            room:addPlayerMark(player, 'bf_huashen' .. general)
                            table.removeOne(huashens, general)
                            for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
                                if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and
                                    not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and
                                    skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~=
                                    sgs.Skill_Compulsory then
                                    table.insert(SkillList, skill:objectName())
                                end
                            end
                        end
                    else
                        local name = generals[math.random(1, #generals)]
                        local choice = room:askForGeneral(player, name .. '+cancel')
                        if choice ~= 'cancel' then
                            room:addPlayerMark(player, 'bf_huashen' .. name)
                            local general = room:askForGeneral(player, table.concat(huashenss, '+'))
                            room:removePlayerMark(player, 'bf_huashen' .. general)
                            for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
                                if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and
                                    not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and
                                    skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~=
                                    sgs.Skill_Compulsory then
                                    table.insert(SkillList, '-' .. skill:objectName())
                                end
                            end
                            for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(name):getVisibleSkillList()) do
                                if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and
                                    not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and
                                    skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~=
                                    sgs.Skill_Compulsory then
                                    table.insert(SkillList, skill:objectName())
                                end
                            end
                        end
                    end
                    if #SkillList > 0 then
                        room:handleAcquireDetachSkills(player, table.concat(SkillList, '|'))
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        else
            local mark = data:toMark()
            if string.find(mark.name, 'engine') and mark.gain > 0 then
                for _, m in sgs.list(player:getMarkNames()) do
                    if player:getMark(m) > 0 and string.find(m, 'bf_huashen') then
                        local SkillList = {}
                        for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m)))
                            :getVisibleSkillList()) do
                            if skill:objectName() .. 'engine' == mark.name or skill:objectName() .. 'Cardengine' == mark.name or
                                skill:objectName() .. 'cardengine' == mark.name or '#' .. skill:objectName() .. 'engine' ==
                                mark.name or string.upper(string.sub(skill:objectName(), 1, 1)) ..
                                string.sub(skill:objectName(), 2, string.len(skill:objectName())) .. 'engine' == mark.name then
                                room:removePlayerMark(player, 'bf_huashen' .. string.sub(m, 11, string.len(m)))
                                for _, s in sgs.qlist(sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m)))
                                    :getVisibleSkillList()) do
                                    if not s:inherits('SPConvertSkill') and not s:isAttachedLordSkill() and
                                        not s:isLordSkill() and s:getFrequency() ~= sgs.Skill_Wake and s:getFrequency() ~=
                                        sgs.Skill_Limited and s:getFrequency() ~= sgs.Skill_Compulsory then
                                        table.insert(SkillList, '-' .. s:objectName())
                                    end
                                end
                            end
                        end
                        room:handleAcquireDetachSkills(player, table.concat(SkillList, '|'))
                    end
                end
            end
        end
        return false
    end,
}
bf_zuoci:addSkill(bf_huashen)
bf_xinsheng = sgs.CreateMasochismSkill {
    name = 'bf_xinsheng',
    frequency = sgs.Skill_Frequent,
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local generals = sgs.Sanguosha:getLimitedGeneralNames()
        for _, name in pairs(generals) do
            if player:getMark('bf_huashen' .. name) > 0 then
                table.removeOne(generals, name)
            end
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if table.contains(generals, p:getGeneralName()) then
                table.removeOne(generals, p:getGeneralName())
            end
            if table.contains(generals, p:getGeneral2Name()) then
                table.removeOne(generals, p:getGeneral2Name())
            end
        end
        if #generals > 0 and room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                local general = generals[math.random(1, #generals)]
                ChoiceLog(player, general, player)
                room:addPlayerMark(player, 'bf_huashen' .. general)
                local SkillList = {}
                for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
                    if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and not skill:isLordSkill() and
                        skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and
                        skill:getFrequency() ~= sgs.Skill_Compulsory then
                        table.insert(SkillList, skill:objectName())
                    end
                end
                room:handleAcquireDetachSkills(player, table.concat(SkillList, '|'))
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
bf_zuoci:addSkill(bf_xinsheng)
litong = sgs.General(extension, 'litong', 'wei')
tuifeng = sgs.CreateTriggerSkill {
    name = 'tuifeng',
    events = {sgs.Damaged, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            for _ = 1, damage.damage, 1 do
                if not player:isNude() then
                    local id = room:askForExchange(player, self:objectName(), 1, 1, true, 'tuifeng-invoke', true)
                        :getSubcards():first()
                    if id ~= -1 then
                        skill(self, room, player, true, 2)
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            player:addToPile('feng', id, false)
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                end
            end
        else
            if player:getPhase() == sgs.Player_Start then
                local x = player:getPile('feng'):length()
                if x > 0 then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:addPlayerMark(player, self:objectName() .. 'engine', 2)
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, cd in sgs.qlist(player:getPile('feng')) do
                            dummy:addSubcard(cd)
                        end
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, '',
                            player:objectName(), self:objectName(), '')
                        room:throwCard(dummy, reason, nil)
                        player:drawCards(2 * x)
                        room:addPlayerMark(player, '@Slash-Clear', x)
                        room:removePlayerMark(player, self:objectName() .. 'engine', 2)
                    end
                end
            end
        end
    end,
}
litong:addSkill(tuifeng)
mizhu = sgs.General(extension_star, 'mizhu', 'shu', 3)
ziyuanCard = sgs.CreateSkillCard {
    name = 'ziyuanCard',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(),
                'ziyuan', '')
            room:obtainCard(targets[1], self, reason, false)
            room:recover(targets[1], sgs.RecoverStruct(source, nil, 1))
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
ziyuan = sgs.CreateViewAsSkill {
    name = 'ziyuan',
    n = 999,
    view_filter = function(self, selected, to_select)
        if to_select:isEquipped() then
            return false
        end
        local sum = 0
        for _, card in ipairs(selected) do
            sum = sum + card:getNumber()
        end
        sum = sum + to_select:getNumber()
        return sum <= 13
    end,
    view_as = function(self, cards)
        local sum = 0
        for _, c in ipairs(cards) do
            sum = sum + c:getNumber()
        end
        if sum == 13 then
            local card = ziyuanCard:clone()
            for _, c in ipairs(cards) do
                card:addSubcard(c)
            end
            return card
        else
            return nil
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#ziyuanCard') and not player:isKongcheng()
    end,
}
mizhu:addSkill(ziyuan)
jugu = sgs.CreateTriggerSkill {
    name = 'jugu',
    events = {sgs.DrawInitialCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), 2)
        room:addPlayerMark(player, self:objectName() .. 'engine')
        if player:getMark(self:objectName() .. 'engine') > 0 then
            data:setValue(data:toInt() + player:getMaxHp())
            room:removePlayerMark(player, self:objectName() .. 'engine')
        end
    end,
}
mizhu:addSkill(jugu)
ol_xiahouyuan = sgs.General(extension_god, 'ol_xiahouyuan', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
ol_shensuCard = sgs.CreateSkillCard {
    name = 'ol_shensu',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, sgs.Self)
    end,
    on_use = function(self, room, source, targets)
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        if targets_list:length() > 0 then
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                slash:setSkillName(self:objectName())
                room:useCard(sgs.CardUseStruct(slash, source, targets_list))
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
        end
    end,
}
ol_shensuVS = sgs.CreateViewAsSkill {
    name = 'ol_shensu',
    n = 1,
    view_filter = function(self, selected, to_select)
        if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '2') then
            return #selected == 0 and to_select:isKindOf('EquipCard') and not sgs.Self:isJilei(to_select)
        else
            return false
        end
    end,
    view_as = function(self, cards)
        if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '1') or
            string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '3') then
            return #cards == 0 and ol_shensuCard:clone() or nil
        else
            if #cards ~= 1 then
                return nil
            end
            local card = ol_shensuCard:clone()
            for _, cd in ipairs(cards) do
                card:addSubcard(cd)
            end
            return card
        end
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@ol_shensu')
    end,
}
ol_shensu = sgs.CreateTriggerSkill {
    name = 'ol_shensu',
    events = {sgs.EventPhaseChanging},
    view_as_skill = ol_shensuVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) then
            if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, '@@ol_shensu1', '@shensu1', 1) then
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
            end
        elseif sgs.Slash_IsAvailable(player) and change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
            if player:canDiscard(player, 'he') and
                room:askForUseCard(player, '@@ol_shensu2', '@shensu2', 2, sgs.Card_MethodDiscard) then
                player:skip(sgs.Player_Play)
            end
        elseif change.to == sgs.Player_Discard and not player:isSkipped(sgs.Player_Discard) then
            if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, '@@ol_shensu3', '@shensu3', 3) then
                player:skip(sgs.Player_Discard)
                player:turnOver()
            end
        end
        return false
    end,
}
ol_xiahouyuan:addSkill(ol_shensu)
ol_weiyan = sgs.General(extension_god, 'ol_weiyan', 'shu', 4, true, sgs.GetConfig('EnableHidden', true))
ol_kuanggu = sgs.CreateTriggerSkill {
    name = 'ol_kuanggu',
    global = true,
    events = {sgs.Damage, sgs.PreDamageDone},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.PreDamageDone and RIGHT(self, damage.from) then
            damage.from:setTag('invoke_kuanggu_ol', sgs.QVariant((damage.from:distanceTo(damage.to) <= 1)))
        elseif event == sgs.Damage and RIGHT(self, player) then
            local invoke = player:getTag('invoke_kuanggu_ol'):toBool()
            player:setTag('invoke_kuanggu_ol', sgs.QVariant(false))
            if invoke then
                for _ = 1, damage.damage do
                    local choices = {'kuanggu1+cancel'}
                    if player:isWounded() then
                        table.insert(choices, 1, 'kuanggu2')
                    end
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                    if choice == 'cancel' then
                        break
                    end
                    lazy(self, room, player, choice, true)
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if choice == 'kuanggu1' then
                            player:drawCards(1)
                        else
                            room:recover(player, sgs.RecoverStruct(player))
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
ol_weiyan:addSkill(ol_kuanggu)
qimouCard = sgs.CreateSkillCard {
    name = 'qimouCard',
    target_fixed = true,
    on_use = function(self, room, source)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local lose_num = {}
            for i = 1, source:getHp() do
                table.insert(lose_num, tostring(i))
            end
            local choice = room:askForChoice(source, 'qimou', table.concat(lose_num, '+'))
            room:removePlayerMark(source, '@qimou')
            room:loseHp(source, tonumber(choice))
            room:addPlayerMark(source, '@qimou-Clear', tonumber(choice))
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
qimouVS = sgs.CreateZeroCardViewAsSkill {
    name = 'qimou',
    view_as = function()
        return qimouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@qimou') >= 1 and player:getHp() > 1
    end,
}
qimou = sgs.CreateTriggerSkill {
    name = 'qimou',
    frequency = sgs.Skill_Limited,
    limit_mark = '@qimou',
    view_as_skill = qimouVS,
    on_trigger = function()
    end,
}
ol_weiyan:addSkill(qimou)
dongbai = sgs.General(extension, 'dongbai', 'qun', 3, false, sgs.GetConfig('hidden_ai', true))
lianzhuCard = sgs.CreateSkillCard {
    name = 'lianzhu',
    will_throw = false,
    on_use = function(self, room, source, targets)
        local need = sgs.Sanguosha:getCard(self:getSubcards():first()):isBlack()
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
                targets[1]:objectName(), self:objectName(), ''), true)
            if need then
                if not room:askForDiscard(targets[1], 'lianzhu', 2, 2, true, true, '@lianzhu:' .. source:objectName()) then
                    source:drawCards(2, self:objectName())
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        else
            room:showCard(source, self:getSubcards():first())
        end
    end,
}
lianzhu = sgs.CreateOneCardViewAsSkill {
    name = 'lianzhu',
    filter_pattern = '.',
    view_as = function(self, card)
        local skill_card = lianzhuCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#lianzhu')
    end,
}
dongbai:addSkill(lianzhu)
xiahui = sgs.CreateTriggerSkill {
    name = 'xiahui',
    global = true,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard, sgs.CardsMoveOneTime, sgs.Damaged, sgs.HpLost},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.AskForGameruleDiscard or event == sgs.AfterGameruleDiscard) and RIGHT(self, player) then
            SendComLog(self, player, nil, event == sgs.AskForGameruleDiscard)
            local n = room:getTag('DiscardNum'):toInt()
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isBlack() then
                    n = n - 1
                end
            end
            if event == sgs.AskForGameruleDiscard then
                SendComLog(self, player)
                room:setPlayerCardLimitation(player, 'discard', '.|black|.|hand', true)
            else
                room:removePlayerCardLimitation(player, 'discard', '.|black|.|hand$1')
            end
            room:setTag('DiscardNum', sgs.QVariant(n))
        elseif event == sgs.CardsMoveOneTime and RIGHT(self, player) then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() ~= player:objectName() and move.from and move.from:objectName() ==
                player:objectName() and
                (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and
                move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
                for _, id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(id):isBlack() then
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            room:setPlayerCardLimitation(BeMan(room, move.to), 'use,response,discard',
                                sgs.Sanguosha:getCard(id):toString(), false)
                            room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
                            room:addPlayerMark(BeMan(room, move.to), self:objectName())
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                end
            end
            if (move.from and (move.from:objectName() == player:objectName()) and
                (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and
                not (move.to and (move.to:objectName() == player:objectName() and
                    (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
                for _, c in sgs.qlist(player:getCards('he')) do
                    if c:hasFlag(self:objectName()) then
                        room:removePlayerCardLimitation(player, 'use,response,discard', c:toString() .. '$0')
                        room:removePlayerMark(player, self:objectName())
                    end
                end
            end
        elseif event == sgs.HpChanged then
            local int = 0
            if data:toDamage() and data:toDamage().damage > 0 then
                int = data:toDamage().damage
            elseif data:toInt() > 0 then
                int = data:toInt()
            end
            if int > 0 and player:getMark(self:objectName()) > 0 then
                for _, c in sgs.qlist(player:getHandcards()) do
                    if c:hasFlag(self:objectName()) then
                        room:removePlayerCardLimitation(player, 'use,response,discard', c:toString() .. '$0')
                        room:removePlayerMark(player, self:objectName())
                    end
                end
            end
        end
    end,
}
dongbai:addSkill(xiahui)
extension:insertRelatedSkills('xiahui', '#xiahui')
ol_huangzhong = sgs.General(extension_god, 'ol_huangzhong', 'shu', 4, true, sgs.GetConfig('EnableHidden', true))
ol_liegong = sgs.CreateTriggerSkill {
    name = 'ol_liegong',
    events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished},
    on_trigger = function(self, event, player, data)
        local use = data:toCardUse()
        local room = player:getRoom()
        if event == sgs.TargetSpecified and player:objectName() == use.from:objectName() and
            use.from:hasSkill(self:objectName()) and use.card:isKindOf('Slash') then
            local index, up = 1, 0
            local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then
                    break
                end
                local invoke, jink, dama = false, false, false
                if p:getHandcardNum() <= player:getHandcardNum() then
                    invoke = true
                    jink = true
                end
                if p:getHp() >= player:getHp() then
                    invoke = true
                    dama = true
                end
                local _data = sgs.QVariant()
                _data:setValue(p)
                if invoke and room:askForSkillInvoke(player, self:objectName(), _data) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if jink then
                            jink_table[index] = 0
                        end
                        if dama then
                            up = up + 1
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
                index = index + 1
            end
            if up > 0 then
                room:addPlayerMark(player, 'ol_liegong_Play', up)
                room:setCardFlag(use.card, 'ol_liegong_Play')
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(Table2IntList(jink_table))
            player:setTag('Jink_' .. use.card:toString(), jink_data)
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag('ol_liegong_Play') then
                local log = sgs.LogMessage()
                log.type = '$hanyong'
                log.from = player
                log.card_str = damage.card:toString()
                log.arg = self:objectName()
                room:sendLog(log)
                damage.damage = damage.damage + player:getMark('ol_liegong_Play')
                data:setValue(damage)
            end
        elseif event == sgs.CardFinished and data:toCardUse().card:hasFlag('ol_liegong_Play') then
            room:clearCardFlag(data:toCardUse().card)
            room:setPlayerMark(player, 'ol_liegong_Play', 0)
        end
        return false
    end,
}
ol_huangzhong:addSkill(ol_liegong)
zhaoxiang = sgs.General(extension, 'zhaoxiang', 'shu', 4, false, sgs.GetConfig('hidden_ai', true))
fanghunCard = sgs.CreateSkillCard {
    name = 'fanghun',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        if self:subcardsLength() ~= 0 and
            (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or
                sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
            local targets_list = sgs.PlayerList()
            for _, target in ipairs(targets) do
                targets_list:append(target)
            end
            local slash = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
            slash:addSubcard(self:getSubcards():first())
            slash:setSkillName('longdan')
            slash:deleteLater()
            return slash:targetFilter(targets_list, to_select, sgs.Self)
        end
        return false
    end,
    feasible = function(self, targets)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and
            self:getUserString() == 'slash' then
            return #targets > 0
        else
            return #targets == 0
        end
    end,
    on_validate = function(self, use)
        local data = sgs.QVariant()
        data:setValue(use.from)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), card:getSuit(), card:getNumber())
        use_card:setSkillName('longdan')
        use_card:addSubcard(self:getSubcards():first())
        for _, to in sgs.qlist(use.to) do
            if use.from:getRoom():isProhibited(use.from, to, use_card) then
                use.to:removeOne(to)
            end
        end
        use_card:deleteLater()
        skill(self, use.from:getRoom(), use.from, true)
        use.from:loseMark('@meiying')
        use.from:drawCards(1, self:objectName())
        return use_card
    end,
    on_validate_in_response = function(self, player)
        local data = sgs.QVariant()
        data:setValue(player)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), card:getSuit(), card:getNumber())
        use_card:setSkillName('longdan')
        use_card:addSubcard(self:getSubcards():first())
        use_card:deleteLater()
        skill(self, player:getRoom(), player, true)
        player:loseMark('@meiying')
        player:drawCards(1, self:objectName())
        return use_card
    end,
}
fanghunVS = sgs.CreateOneCardViewAsSkill {
    name = 'fanghun',
    view_filter = function(self, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return to_select:isKindOf('Jink')
        elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or
            (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
            if sgs.Sanguosha:getCurrentCardUsePattern() == 'slash' then
                return to_select:isKindOf('Jink')
            else
                return to_select:isKindOf('Slash')
            end
        end
        return false
    end,
    view_as = function(self, card)
        local dragon = 'jink'
        if card:isKindOf('Jink') then
            dragon = 'slash'
        end
        local cards = fanghunCard:clone()
        cards:addSubcard(card)
        cards:setUserString(dragon)
        return cards
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getMark('@meiying') > 0
    end,
    enabled_at_response = function(self, player, pattern)
        return (pattern == 'slash' or pattern == 'jink') and player:getMark('@meiying') > 0
    end,
}
fanghun = sgs.CreateTriggerSkill {
    name = 'fanghun',
    view_as_skill = fanghunVS,
    events = {sgs.Damage, sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf('Slash') then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:gainMark('@meiying')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        else
            local mark = data:toMark()
            if mark.name == '@meiying' and mark.gain > 0 then
                room:addPlayerMark(player, self:objectName(), mark.gain)
            end
        end
        return false
    end,
}
zhaoxiang:addSkill(fanghun)
fuhan = sgs.CreateTriggerSkill {
    name = 'fuhan',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = '@fuhan',
    on_trigger = function(self, event, player, data, room)
        local x = player:getMark('fanghun') + player:getMark('@meiying')
        if player:getPhase() == sgs.Player_RoundStart and x > 0 and player:hasSkill('fanghun') and player:getMark('@fuhan') >
            0 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant('up:' .. x)) then
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:loseAllMarks('@meiying')
                local fuhans = {}
                local fuhan = {}
                for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
                    if sgs.Sanguosha:getGeneral(name):getKingdom() == 'shu' then
                        table.insert(fuhans, name)
                    end
                end
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    if table.contains(fuhans, p:getGeneralName()) then
                        table.removeOne(fuhans, p:getGeneralName())
                    end
                end
                for _ = 1, 5 do
                    local first = fuhans[math.random(1, #fuhans)]
                    table.insert(fuhan, first)
                    table.removeOne(fuhans, first)
                end
                room:removePlayerMark(player, '@fuhan')
                local general = room:askForGeneral(player, table.concat(fuhan, '+'))
                ChoiceLog(player, general)
                room:changeHero(player, general, false, false)
                local can_invoke = true
                local _x = 0
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    _x = _x + 1
                    if player:getHp() > p:getHp() then
                        can_invoke = false
                    end
                end
                room:setPlayerProperty(player, 'maxhp', sgs.QVariant(math.min(x, player:getMark('fanghun'))))
                if can_invoke and player:isWounded() then
                    room:recover(player, sgs.RecoverStruct(player))
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
zhaoxiang:addSkill(fuhan)
heqi = sgs.General(extension_star, 'heqi', 'wu')
qizhou = sgs.CreateTriggerSkill {
    name = 'qizhou',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip)) or
            (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) then
            local suit = {}
            for _, card in sgs.qlist(player:getEquips()) do
                if not table.contains(suit, card:getSuit()) then
                    table.insert(suit, card:getSuit())
                end
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            if #suit >= 1 then
                room:acquireSkill(player, 'mashu')
                if #suit >= 2 then
                    room:acquireSkill(player, 'nosyingzi')
                    if #suit >= 3 then
                        room:acquireSkill(player, 'duanbing')
                        if #suit >= 4 then
                            room:acquireSkill(player, 'fenwei')
                            if player:getMark('used_fenwei') > 0 then
                                room:removePlayerMark(player, '@fenwei')
                            end
                        else
                            if player:getMark('@fenwei') == 0 then
                                room:addPlayerMark(player, 'used_fenwei')
                            end
                            room:detachSkillFromPlayer(player, 'fenwei', false, true)
                        end
                    else
                        room:detachSkillFromPlayer(player, 'duanbing', false, true)
                    end
                else
                    room:detachSkillFromPlayer(player, 'nosyingzi', false, true)
                end
            else
                room:detachSkillFromPlayer(player, 'mashu', false, true)
            end
        end
    end,
}
heqi:addSkill(qizhou)
shanxiCard = sgs.CreateSkillCard {
    name = 'shanxi',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and
                   sgs.Self:canDiscard(to_select, 'he')
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local card = sgs.Sanguosha:getCard(room:askForCardChosen(source, targets[1], 'he', self:objectName(), false,
                sgs.Card_MethodDiscard))
            room:throwCard(card, targets[1], source)
            if card:isKindOf('Jink') and not targets[1]:isKongcheng() then
                room:showAllCards(targets[1], source)
            elseif not card:isKindOf('Jink') and not source:isKongcheng() then
                room:showAllCards(source, targets[1])
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
shanxi = sgs.CreateOneCardViewAsSkill {
    name = 'shanxi',
    filter_pattern = 'BasicCard|red',
    view_as = function(self, card)
        local aaa = shanxiCard:clone()
        aaa:addSubcard(card)
        return aaa
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#shanxi')
    end,
}
heqi:addSkill(shanxi)
mazhong = sgs.General(extension_star, 'mazhong', 'shu')
fumanCard = sgs.CreateSkillCard {
    name = 'fuman',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return to_select:getMark('fuman_Play') == 0 and sgs.Self:objectName() ~= to_select:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
                targets[1]:objectName(), self:objectName(), ''), false)
            room:addPlayerMark(targets[1], self:objectName() .. self:getSubcards():first() .. source:objectName() .. '_flag')
            room:addPlayerMark(targets[1], 'fuman_Play')
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
fumanVS = sgs.CreateOneCardViewAsSkill {
    name = 'fuman',
    view_filter = function(self, card)
        return card:isKindOf('Slash')
    end,
    view_as = function(self, card)
        local fumancard = fumanCard:clone()
        fumancard:addSubcard(card)
        return fumancard
    end,
}
fuman = sgs.CreateTriggerSkill {
    name = 'fuman',
    events = {sgs.CardUsed, sgs.CardResponded},
    view_as_skill = fumanVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                card = data:toCardResponse().m_card
            end
        end
        if card and not card:isKindOf('SkillCard') then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                for _, id in sgs.qlist(card:getSubcards()) do
                    if player:getMark(self:objectName() .. id .. p:objectName() .. '_flag') > 0 then
                        room:sendCompulsoryTriggerLog(p, self:objectName())
                        p:drawCards(1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
}
mazhong:addSkill(fuman)
kanze = sgs.General(extension, 'kanze', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
xiashu = sgs.CreatePhaseChangeSkill {
    name = 'xiashu',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'xiashu-invoke',
                true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:obtainCard(target, player:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                        player:objectName(), target:objectName(), self:objectName(), ''), false)
                    if not target:isNude() then
                        local cards = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, false,
                            '@xiashu')
                        local list = target:getCards('h')
                        for _, id in sgs.qlist(cards:getSubcards()) do
                            room:showCard(target, id)
                            list:removeOne(sgs.Sanguosha:getCard(id))
                        end
                        local choices = {'xiashu1'}
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        if not list:isEmpty() then
                            table.insert(choices, 'xiashu2')
                            dummy:addSubcards(list)
                        end
                        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                        if choice == 'xiashu1' then
                            room:obtainCard(player, cards, false)
                        else
                            room:obtainCard(player, dummy, false)
                        end
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
kanze:addSkill(xiashu)
kuanshi = sgs.CreatePhaseChangeSkill {
    name = 'kuanshi',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 'kuanshi-invoke', true,
                sgs.GetConfig('face_game', true))
            if target then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    if not sgs.GetConfig('face_game', true) then
                        skill(self, room, player, false)
                        room:addPlayerMark(target, 'kuanshi_start')
                        room:addPlayerMark(player, 'kuanshi' .. target:objectName() .. target:getMark('kuanshi_start'))
                    else
                        room:addPlayerMark(target, '@kuanshi_start')
                        room:addPlayerMark(player, 'kuanshi' .. target:objectName() .. target:getMark('@kuanshi_start'))
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
kanze:addSkill(kuanshi)
shenlvbu_gui = sgs.General(extension_hulaoguan, 'shenlvbu_gui', 'qun', 4, true, sgs.GetConfig('hidden_ai', true))
shenlvbu_gui:addSkill('wushuang')
shenqu = sgs.CreateTriggerSkill {
    name = 'shenqu',
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if RIGHT(self, p) then
                if event == sgs.EventPhaseStart then
                    if player:getPhase() == sgs.Player_RoundStart and p:getHandcardNum() <= p:getMaxHp() and
                        room:askForSkillInvoke(p, self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName(), 1)
                        room:addPlayerMark(p, self:objectName() .. 'engine')
                        if p:getMark(self:objectName() .. 'engine') > 0 then
                            p:drawCards(2, self:objectName())
                            room:removePlayerMark(p, self:objectName() .. 'engine')
                        end
                    end
                else
                    if p:objectName() == data:toDamage().to:objectName() and room:askForUseCard(p, 'peach', '@shenqu') then
                        room:broadcastSkillInvoke(self:objectName(), 2)
                        room:addPlayerMark(p, self:objectName() .. 'engine')
                        if p:getMark(self:objectName() .. 'engine') > 0 then
                            room:removePlayerMark(p, self:objectName() .. 'engine')
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
shenlvbu_gui:addSkill(shenqu)
jiwuCard = sgs.CreateSkillCard {
    name = 'jiwu',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local choices = {'qiangxi', 'lieren', 'xuanfeng', 'wansha'}
        local copy = {'qiangxi', 'lieren', 'xuanfeng', 'wansha'}
        for i = 1, 4 do
            if source:hasSkill(choices[i]) then
                table.removeOne(copy, choices[i])
            end
        end
        if #copy > 0 then
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                local choice = room:askForChoice(source, self:objectName(), table.concat(copy, '+'))
                room:acquireSkill(source, choice)
                room:addPlayerMark(source, choice .. '_skillClear')
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
        end
    end,
}
jiwu = sgs.CreateOneCardViewAsSkill {
    name = 'jiwu',
    filter_pattern = '.|.|.|hand!',
    view_as = function(self, card)
        local skill_card = jiwuCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasSkill('qiangxi') or not player:hasSkill('lieren') or not player:hasSkill('xuanfeng') or
                   not player:hasSkill('wansha')
    end,
}
shenlvbu_gui:addSkill(jiwu)
shenlvbu_gui:addRelateSkill('qiangxi')
shenlvbu_gui:addRelateSkill('lieren')
shenlvbu_gui:addRelateSkill('wansha')
shenlvbu_gui:addRelateSkill('xuanfeng')
mol_sunru = sgs.General(extension_mobile, 'mol_sunru', 'wu', 3, false, sgs.GetConfig('EnableHidden', true))
yingjianCard = sgs.CreateSkillCard {
    name = 'yingjian',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:setSkillName('_' .. self:objectName())
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, sgs.Self)
    end,
    on_use = function(self, room, source, targets)
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        if not targets_list:isEmpty() then
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                slash:setSkillName('_' .. self:objectName())
                room:useCard(sgs.CardUseStruct(slash, source, targets_list))
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
        end
    end,
}
yingjianVS = sgs.CreateZeroCardViewAsSkill {
    name = 'yingjian',
    view_as = function()
        return yingjianCard:clone()
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@yingjian'
    end,
}
yingjian = sgs.CreatePhaseChangeSkill {
    name = 'yingjian',
    view_as_skill = yingjianVS,
    on_phasechange = function(self, player)
        if sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Start then
            player:getRoom():askForUseCard(player, '@@yingjian', '@yingjian')
        end
        return false
    end,
}
mol_sunru:addSkill(yingjian)
mol_sunru:addSkill('shixin')
ol_pangde = sgs.General(extension_star, 'ol_pangde', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
juesiCard = sgs.CreateSkillCard {
    name = 'juesi',
    filter = function(self, targets, to_select)
        local rangefix = 0
        if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() ==
            self:getSubcards():first() then
            local card = sgs.Self:getWeapon():getRealCard():toWeapon()
            rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
            rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
        end
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
                   sgs.Self:inMyAttackRange(to_select, rangefix) and not to_select:isNude()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local card = room:askForCard(targets[1], '.|.|.|.!', '@juesi', sgs.QVariant(), self:objectName())
            local duel = sgs.Sanguosha:cloneCard('duel', sgs.Card_NoSuit, 0)
            duel:setSkillName('_' .. self:objectName())
            if card and not card:isKindOf('Slash') and source:getHp() <= targets[1]:getHp() and
                not source:isCardLimited(duel, sgs.Card_MethodUse) and not source:isProhibited(targets[1], duel) then
                room:useCard(sgs.CardUseStruct(duel, source, targets[1]))
            end
            duel:deleteLater()
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
juesi = sgs.CreateOneCardViewAsSkill {
    name = 'juesi',
    filter_pattern = 'Slash',
    view_as = function(self, card)
        local cards = juesiCard:clone()
        cards:addSubcard(card)
        return cards
    end,
}
ol_pangde:addSkill(juesi)
ol_pangde:addSkill('mashu')
buzhi = sgs.General(extension_star, 'buzhi', 'wu', 3)
hongde = sgs.CreateTriggerSkill {
    name = 'hongde',
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.card_ids:length() >= 2 and
            ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and
                move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) or
                (move.from and move.from:objectName() == player:objectName() and
                    (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and
                    not (move.to and move.to:objectName() == player:objectName() and
                        (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'hongde-invoke',
                true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    target:drawCards(1, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
buzhi:addSkill(hongde)
dingpanCard = sgs.CreateSkillCard {
    name = 'dingpan',
    filter = function(self, selected, to_select)
        return #selected == 0 and not to_select:getEquips():isEmpty()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            targets[1]:drawCards(1, self:objectName())
            local choice = 'dingpan2'
            if source:canDiscard(targets[1], 'e') then
                choice = room:askForChoice(targets[1], self:objectName(), 'dingpan1+dingpan2')
            end
            if choice == 'dingpan1' then
                room:broadcastSkillInvoke(self:objectName(), 1)
                local id = room:askForCardChosen(source, targets[1], 'e', self:objectName(), false, sgs.Card_MethodDiscard)
                room:throwCard(id, targets[1], source)
            else
                room:broadcastSkillInvoke(self:objectName(), 2)
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                for _, equip in sgs.qlist(targets[1]:getEquips()) do
                    dummy:addSubcard(equip:getEffectiveId())
                end
                room:obtainCard(targets[1], dummy)
                room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
dingpan = sgs.CreateZeroCardViewAsSkill {
    name = 'dingpan',
    view_as = function(self)
        local card = dingpanCard:clone()
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#dingpan') < player:getMark(self:objectName())
    end,
}
buzhi:addSkill(dingpan)
dongyun = sgs.General(extension_star, 'dongyun', 'shu', 3, true, sgs.GetConfig('hidden_ai', true))
bingzheng = sgs.CreateTriggerSkill {
    name = 'bingzheng',
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() ~= p:getHp() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local to = room:askForPlayerChosen(player, targets, self:objectName(), 'bingzheng-invoke', true, true)
                if to then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local choices = {'bingzheng2'}
                        if not to:isKongcheng() then
                            table.insert(choices, 1, 'bingzheng1')
                        end
                        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                        room:broadcastSkillInvoke(self:objectName())
                        if choice == 'bingzheng1' then
                            room:askForDiscard(to, self:objectName(), 1, 1)
                        else
                            to:drawCards(1)
                        end
                        if to:getHandcardNum() == to:getHp() then
                            room:broadcastSkillInvoke(self:objectName())
                            player:drawCards(1, self:objectName())
                            local players = sgs.SPlayerList()
                            players:append(to)
                            if to:objectName() ~= player:objectName() then
                                room:askForYiji(player, getIntList(player:getCards('he')), self:objectName(), false, false,
                                    true, 1, players, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                                        player:objectName(), to:objectName(), self:objectName(), ''), 'bingzheng-distribute',
                                    true)
                            end
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
dongyun:addSkill(bingzheng)
sheyan = sgs.CreateTriggerSkill {
    name = 'sheyan',
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isNDTrick() and use.to:contains(player) and not use.card:isKindOf('Collateral') then
            local players = room:getOtherPlayers(player)
            for _, p in sgs.qlist(use.to) do
                players:removeOne(p)
            end
            for _, p in sgs.qlist(players) do
                if room:isProhibited(use.from, p, use.card) then
                    players:removeOne(p)
                end
            end
            if sgs.GetConfig('sheyan_down', true) then
                players = sgs.SPlayerList()
            end
            if use.to:length() > 1 then
                for _, p in sgs.qlist(use.to) do
                    players:append(p)
                end
            end
            if not players:isEmpty() then
                local to = room:askForPlayerChosen(player, players, self:objectName(), 'sheyan-invoke', true, true)
                if to then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if use.to:contains(to) then
                            use.to:removeOne(to)
                            room:broadcastSkillInvoke(self:objectName(), 1)
                        else
                            use.to:append(to)
                            room:broadcastSkillInvoke(self:objectName(), 2)
                        end
                        room:sortByActionOrder(use.to)
                        data:setValue(use)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
dongyun:addSkill(sheyan)
zhangliang = sgs.General(extension_star, 'zhangliang', 'qun', 4, true, sgs.GetConfig('hidden_ai', true))
jijun = sgs.CreateTriggerSkill {
    name = 'jijun',
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetSpecified, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if (use.card:isKindOf('Weapon') or not use.card:isKindOf('EquipCard')) and not use.card:isKindOf('SkillCard') and
                player:getPhase() == sgs.Player_Play and use.from:objectName() == player:objectName() and
                use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local judge = sgs.JudgeStruct()
                    judge.pattern = '.'
                    judge.good = true
                    judge.reason = self:objectName()
                    judge.who = player
                    room:setPlayerCardLimitation(player, 'response', use.card:toString(), false)
                    room:setPlayerFlag(player, self:objectName())
                    room:judge(judge)
                    room:setPlayerFlag(player, '-' .. self:objectName())
                    -- myetyet按：zy说被鬼才改之前的判定牌也要置于武将牌上，然而我觉得描述里没这个意思；ZY按：就是有这个意思！！！！！！！！！！！！！
                    room:removePlayerCardLimitation(player, 'response', use.card:toString())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and
                move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE and
                (move.reason.m_skillName == self:objectName() or move.from:hasFlag(self:objectName())) and
                not move.card_ids:isEmpty() then
                player:addToPile('fang', move.card_ids)
            end
        end
        return false
    end,
}
zhangliang:addSkill(jijun)
fangtongCard = sgs.CreateSkillCard {
    name = 'fangtong',
    will_throw = true,
    filter = function(self, targets, to_select)
        local num = 0
        for _, id in sgs.qlist(self:getSubcards()) do
            num = num + sgs.Sanguosha:getCard(id):getNumber()
        end
        if num == 36 then
            return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets <= 1
    end,
    on_use = function(self, room, source, targets)
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, id in sgs.qlist(self:getSubcards()) do
            if id ~= self:getSubcards():first() then
                dummy:addSubcard(id)
            end
        end
        room:throwCard(self:getSubcards():first(), source, source)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:throwCard(dummy,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, '', '', self:objectName(), ''), nil)
            if targets[1] then
                room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 3, sgs.DamageStruct_Thunder))
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
fangtongVS = sgs.CreateViewAsSkill {
    name = 'fangtong',
    n = 999,
    expand_pile = 'fang',
    view_filter = function(self, selected, to_select)
        return sgs.Self:canDiscard(sgs.Self, to_select:getEffectiveId()) and
                   ((#selected == 0 and not sgs.Self:getPile('fang'):contains(to_select:getEffectiveId())) or
                       (#selected > 0 and sgs.Self:getPile('fang'):contains(to_select:getEffectiveId())))
    end,
    view_as = function(self, cards)
        if #cards >= 2 and not sgs.Self:getPile('fang'):contains(cards[1]:getEffectiveId()) then
            local ft = fangtongCard:clone()
            for _, c in ipairs(cards) do
                ft:addSubcard(c)
            end
            ft:setSkillName(self:objectName())
            return ft
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@' .. self:objectName()
    end,
}
fangtong = sgs.CreateTriggerSkill {
    name = 'fangtong',
    events = {sgs.EventPhaseStart},
    view_as_skill = fangtongVS,
    on_trigger = function(self, event, player, data)
        if player:getPhase() == sgs.Player_Finish and player:getPile('fang'):length() > 0 and not player:isNude() then
            player:getRoom():askForUseCard(player, '@' .. self:objectName(), '@' .. self:objectName())
        end
        return false
    end,
}
zhangliang:addSkill(fangtong)
fire_pangde = sgs.General(extension_god, 'fire_pangde', 'qun', 4, true, sgs.GetConfig('EnableHidden', true))
fire_pangde:addSkill('mashu')
jianchu = sgs.CreateTriggerSkill {
    name = 'jianchu',
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data)
        local use = data:toCardUse()
        local room = player:getRoom()
        if use.card:isKindOf('Slash') then
            local index = 1
            local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
            for _, p in sgs.qlist(use.to) do
                if not player:isAlive() then
                    break
                end
                local _data = sgs.QVariant()
                _data:setValue(p)
                if player:canDiscard(p, 'he') and room:askForSkillInvoke(player, self:objectName(), _data) then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local id = room:askForCardChosen(player, p, 'he', self:objectName(), false, sgs.Card_MethodDiscard)
                        room:throwCard(sgs.Sanguosha:getCard(id), p, player)
                        if sgs.Sanguosha:getCard(id):isKindOf('EquipCard') then
                            jink_table[index] = 0
                        else
                            local ids = sgs.IntList()
                            if use.card:isVirtualCard() then
                                ids = use.card:getSubcards()
                            else
                                ids:append(use.card:getEffectiveId())
                            end
                            if ids:length() > 0 then
                                local all_place_table = true
                                for _, cid in sgs.qlist(ids) do
                                    if room:getCardPlace(cid) ~= sgs.Player_PlaceTable then
                                        all_place_table = false
                                        break
                                    end
                                end
                                if all_place_table then
                                    p:obtainCard(use.card)
                                end
                            end
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
                index = index + 1
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(Table2IntList(jink_table))
            player:setTag('Jink_' .. use.card:toString(), jink_data)
        end
        return false
    end,
}
fire_pangde:addSkill(jianchu)
taoqian = sgs.General(extension_pm, 'taoqian', 'qun', 3)
zhaohuo = sgs.CreateTriggerSkill {
    name = 'zhaohuo',
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:objectName() ~= player:objectName() then
                SendComLog(self, p)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local x = p:getMaxHp() - 1
                    room:loseMaxHp(p, x)
                    p:drawCards(x, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
taoqian:addSkill(zhaohuo)
yixiang = sgs.CreateTriggerSkill {
    name = 'yixiang',
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if RIGHT(self, player) and use.from:getHp() > player:getHp() and not use.card:isKindOf('SkillCard') and
            not room:getCurrent():hasFlag(self:objectName() .. player:objectName()) and use.to:contains(player) and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:getCurrent():setFlags(self:objectName() .. player:objectName())
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                local basic = {}
                for _, hand in sgs.qlist(player:getHandcards()) do
                    if not table.contains(basic, TrueName(hand)) then
                        table.insert(basic, TrueName(hand))
                    end
                end
                local check = sgs.IntList()
                for _, id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isKindOf('BasicCard') and not table.contains(basic, TrueName(card)) then
                        check:append(id)
                    end
                end
                if not sgs.GetConfig('face_game', true) then
                    if not check:isEmpty() then
                        player:obtainCard(sgs.Sanguosha:getCard(ids:at(math.random(0, ids:length() - 1))))
                    end
                else
                    ShowManyCards(player, player:handCards())
                    if check:isEmpty() then
                        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        dummy:addSubcards(room:getDrawPile())
                        room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                            player:objectName(), self:objectName(), ''), nil)
                        dummy:deleteLater()
                    else
                        local ids = sgs.IntList()
                        while true do
                            if #basic == 4 then
                                break
                            end
                            local id = room:drawCard()
                            local move = sgs.CardsMoveStruct(id, nil, sgs.Player_PlaceTable, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), ''))
                            room:moveCardsAtomic(move, true)
                            room:getThread():delay()
                            local card = sgs.Sanguosha:getCard(id)
                            if card:isKindOf('BasicCard') and not table.contains(basic, TrueName(card)) then
                                room:obtainCard(player, card)
                                break
                            else
                                ids:append(id)
                            end
                        end
                        if not ids:isEmpty() then
                            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                            dummy:addSubcards(ids)
                            room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                player:objectName(), self:objectName(), ''), nil)
                            dummy:deleteLater()
                        end
                    end
                end
            end
            room:removePlayerMark(player, self:objectName() .. 'engine')
        end
        return false
    end,
}
taoqian:addSkill(yixiang)
yirang = sgs.CreatePhaseChangeSkill {
    name = 'yirang',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local ids = sgs.IntList()
        local kind = {}
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMaxHp() > player:getMaxHp() then
                players:append(p)
            end
        end
        for _, card in sgs.qlist(player:getCards('he')) do
            if not card:isKindOf('BasicCard') then
                ids:append(card:getId())
                if not table.contains(kind, card:getType()) then
                    table.insert(kind, card:getType())
                end
            end
        end
        if player:getPhase() == sgs.Player_Play and not ids:isEmpty() then
            local target = room:askForPlayerChosen(player, players, self:objectName(), 'yirang-invoke', true, true)
            if target then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                dummy:addSubcards(ids)
                target:obtainCard(dummy)
                room:setPlayerProperty(player, 'maxhp', sgs.QVariant(target:getMaxHp()))
                room:recover(player, sgs.RecoverStruct(player, nil, #kind))
            end
        end
        return false
    end,
}
taoqian:addSkill(yirang)
miheng = sgs.General(extension_mobile, 'miheng', 'qun', 3)
kuangcai = sgs.CreatePhaseChangeSkill {
    name = 'kuangcai',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:addPlayerMark(player, 'kuangcai_replay')
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
miheng:addSkill(kuangcai)
shejian_list = {}
shejian = sgs.CreateTriggerSkill {
    name = 'shejian',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            shejian_list = {}
            local move = data:toMoveOneTime()
            if not move.from then
                return false
            end
            for _, id in sgs.qlist(move.card_ids) do
                if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                    sgs.CardMoveReason_S_REASON_DISCARD then
                    table.insert(shejian_list, id)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
            for _, id in pairs(shejian_list) do
                for _, fid in pairs(shejian_list) do
                    if id ~= fid and sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(fid):getSuit() then
                        return false
                    end
                end
            end
            local suit = {}
            for _, id in pairs(shejian_list) do
                table.insert(suit, sgs.Sanguosha:getCard(id):getSuit())
            end
            if #shejian_list > 0 and #suit > 1 then
                local players = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:canDiscard(p, 'he') then
                        players:append(p)
                    end
                end
                local target = room:askForPlayerChosen(player, players, self:objectName(), 'shejian-invoke', true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local to_throw = room:askForCardChosen(player, target, 'he', self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
miheng:addSkill(shejian)
ol_guanyinping = sgs.General(extension_sp, 'ol_guanyinping', 'shu', 3, false, sgs.GetConfig('hidden_ai', true))
ol_xuejiCard = sgs.CreateSkillCard {
    name = 'ol_xueji',
    filter = function(self, targets, to_select)
        return #targets < math.max(sgs.Self:getLostHp(), 1) and not to_select:isChained()
    end,
    about_to_use = function(self, room, use)
        local reason =
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), '', self:objectName(), '')
        room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason, true)
        skill(self, room, use.from, true)
        for _, p in sgs.qlist(use.to) do
            room:doAnimate(1, use.from:objectName(), p:objectName())
        end
        room:addPlayerMark(use.from, self:objectName() .. 'engine')
        if use.from:getMark(self:objectName() .. 'engine') > 0 then
            for _, p in sgs.qlist(use.to) do
                room:setPlayerChained(p)
            end
            room:doAnimate(1, use.from:objectName(), use.to:first():objectName())
            room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), 1, sgs.DamageStruct_Fire))
            room:removePlayerMark(use.from, self:objectName() .. 'engine')
        end
    end,
}
ol_xueji = sgs.CreateOneCardViewAsSkill {
    name = 'ol_xueji',
    filter_pattern = '.|red!',
    view_as = function(self, card)
        local first = ol_xuejiCard:clone()
        first:addSubcard(card:getId())
        first:setSkillName(self:objectName())
        return first
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, 'he') and not player:hasUsed('#ol_xueji')
    end,
}
ol_guanyinping:addSkill(ol_xueji)
ol_huxiao = sgs.CreateTriggerSkill {
    name = 'ol_huxiao',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                damage.to:drawCards(1, self:objectName())
                room:addPlayerMark(player, self:objectName() .. player:objectName() .. '_me-Clear')
                room:addPlayerMark(damage.to, self:objectName() .. player:objectName() .. '-Clear')
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
ol_guanyinping:addSkill(ol_huxiao)
ol_wuji = sgs.CreatePhaseChangeSkill {
    name = 'ol_wuji',
    frequency = sgs.Skill_Wake,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish and player:getMark(self:objectName()) == 0 and
            player:getMark('damage_point_round') >= 3 then
            room:broadcastSkillInvoke(self:objectName())
            -- room:doSuperLightbox('guanyinping', self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:addPlayerMark(player, self:objectName())
                if room:changeMaxHpForAwakenSkill(player, 1) then
                    room:recover(player, sgs.RecoverStruct(player))
                    room:detachSkillFromPlayer(player, 'ol_huxiao')
                    local ids = sgs.IntList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        for _, card in sgs.qlist(p:getCards('ej')) do
                            if card:isKindOf('Blade') then
                                ids:append(card:getId())
                            end
                        end
                    end
                    for _, id in sgs.qlist(room:getDiscardPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf('Blade') then
                            ids:append(id)
                        end
                    end
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf('Blade') then
                            ids:append(id)
                        end
                    end
                    room:fillAG(ids)
                    if not ids:isEmpty() then
                        local id = room:askForAG(player, ids, false, self:objectName())
                        player:obtainCard(sgs.Sanguosha:getCard(id))
                    end
                    room:clearAG()
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
ol_guanyinping:addSkill(ol_wuji)
super_yujin = sgs.General(extension_yijiang, 'super_yujin', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
zhenjun = sgs.CreatePhaseChangeSkill {
    name = 'zhenjun',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() > math.max(p:getHp(), 0) then
                players:append(p)
            end
        end
        if player:getPhase() == sgs.Player_Start and not players:isEmpty() then
            local to = room:askForPlayerChosen(player, players, self:objectName(), 'zhenjun-invoke', true, true)
            if to then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setPlayerFlag(to, 'Fake_Move')
                    local x = to:getHandcardNum() - math.max(to:getHp(), 0)
                    local n = 0
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    local card_ids = sgs.IntList()
                    local original_places = sgs.IntList()
                    for i = 0, x - 1 do
                        if not player:canDiscard(to, 'he') then
                            break
                        end
                        card_ids:append(room:askForCardChosen(player, to, 'he', self:objectName(), false,
                            sgs.Card_MethodDiscard))
                        original_places:append(room:getCardPlace(card_ids:at(i)))
                        dummy:addSubcard(card_ids:at(i))
                        to:addToPile('#xuehen', card_ids:at(i), false)
                    end
                    for i = 0, dummy:subcardsLength() - 1, 1 do
                        room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), to, original_places:at(i), false)
                        if not sgs.Sanguosha:getCard(card_ids:at(i)):isKindOf('EquipCard') then
                            n = n + 1
                        end
                    end
                    room:setPlayerFlag(to, '-Fake_Move')
                    if dummy:subcardsLength() > 0 then
                        room:throwCard(dummy, to, player)
                    end
                    local cards = room:askForExchange(player, self:objectName(), n, n, true, '@zhenjun', true)
                    if cards then
                        room:throwCard(cards, player, player)
                    else
                        if n == 0 and not room:askForSkillInvoke(player, self:objectName()) then
                            return false
                        end
                        to:drawCards(x, self:objectName())
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
super_yujin:addSkill(zhenjun)
ol_lidian = sgs.General(extension_star, 'ol_lidian', 'wei', 3, true, sgs.GetConfig('EnableHidden', true)) -- his xunxun is very important!
ol_xunxun = sgs.CreatePhaseChangeSkill {
    name = 'ol_xunxun',
    frequency = sgs.Skill_Frequent,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            local card_ids = room:getNCards(4)
            for _ = 1, 2 do
                room:fillAG(card_ids, player)
                local id = room:askForAG(player, card_ids, false, self:objectName())
                card_ids:removeOne(id)
                room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_DrawPile)
                room:clearAG()
            end
            room:askForGuanxing(player, card_ids, sgs.Room_GuanxingDownOnly)
        end
        return false
    end,
}
ol_lidian:addSkill(ol_xunxun)
ol_lidian:addSkill('wangxi')
ol_sunce = sgs.General(extension_ol, 'ol_sunce$', 'wu', 3, true, sgs.GetConfig('EnableHidden', true))
ol_sunce:addSkill('jiang')
ol_sunce:addSkill('yingyang')
ol_hunshang = sgs.CreatePhaseChangeSkill {
    name = 'ol_hunshang',
    frequency = sgs.Skill_Compulsory,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and player:getHp() <= 1 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:addPlayerMark(player, self:objectName() .. '-Clear')
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
ol_sunce:addSkill(ol_hunshang)
ol_sunce:addSkill('zhiba')
-- local liuqi_k = {'qun','shu'}
-- liuqi = sgs.General(extension, 'liuqi', liuqi_k[math.random(1,2)], 3)
liuqi = sgs.General(extension_friend, 'liuqi', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
wenji = sgs.CreatePhaseChangeSkill {
    name = 'wenji',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if not p:isNude() then
                players:append(p)
            end
        end
        if player:getPhase() == sgs.Player_Play and not players:isEmpty() then
            local to = room:askForPlayerChosen(player, players, self:objectName(), 'wenji-invoke', true, true)
            if to then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local card = room:askForCard(to, '..!', '@wenji', sgs.QVariant(), sgs.Card_MethodNone)
                    if not card then
                        -- 规避 AI 不给牌的情况，随机获取
                        local _cards = to:getCards('he')
                        card = _cards:at(rinsan.random(0, _cards:length() - 1))
                    end
                    if card then
                        room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), player:objectName(), self:objectName(), ''))
                        room:addPlayerMark(player, 'wenji' .. rinsan.getTrueClassName(card:getClassName()) .. '-Clear')
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
liuqi:addSkill(wenji)
tunjiang_skip = sgs.CreateTriggerSkill {
    name = 'tunjiang_skip',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseSkipping},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            room:addPlayerMark(player, 'LuaTunjiang-Skipped-Play-Clear')
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill('tunjiang_skip') then
    skills:append(tunjiang_skip)
end
tunjiang = sgs.CreatePhaseChangeSkill {
    name = 'tunjiang',
    frequency = sgs.Skill_Frequent,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish and player:getMark('LuaTunjiang-Skipped-Play-Clear') == 0 and
            player:getMark('qieting') == 0 and room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:drawCards(getKingdoms(player), self:objectName())
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
liuqi:addSkill(tunjiang)
local tangzi_k = {'wei', 'wu'}
tangzi = sgs.General(extension_friend, 'tangzi', tangzi_k[math.random(1, 2)])
xingzhao = sgs.CreateTriggerSkill {
    name = 'xingzhao',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.CardUsed, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if event == sgs.CardsMoveOneTime then
                local move = data:toMoveOneTime()
                if ((move.from and move.from:objectName() == p:objectName() and player:objectName() == p:objectName() and
                    move.from_places:contains(sgs.Player_PlaceEquip)) or
                    (move.to and move.to:objectName() == p:objectName() and player:objectName() == p:objectName() and
                        move.to_place == sgs.Player_PlaceEquip)) and
                    ((p:getEquips():length() > 1 and not p:hasSkill('xunxun')) or
                        (p:hasSkill('xunxun') and p:getEquips():length() <= 1)) then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    if p:getEquips():length() > 1 then
                        room:acquireSkill(p, 'xunxun')
                    else
                        room:detachSkillFromPlayer(p, 'xunxun', false, true)
                    end
                end
            elseif event == sgs.CardUsed then
                local use = data:toCardUse()
                if use.card:isKindOf('EquipCard') and p:getEquips():length() > 2 and
                    room:askForSkillInvoke(p, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    room:addPlayerMark(use.from, self:objectName() .. 'engine')
                    if use.from:getMark(self:objectName() .. 'engine') > 0 then
                        use.from:drawCards(1, self:objectName())
                        room:removePlayerMark(use.from, self:objectName() .. 'engine')
                    end
                end
            elseif event == sgs.EventPhaseChanging then
                if data:toPhaseChange().to == sgs.Player_Judge and p:getEquips():length() > 3 and
                    room:askForSkillInvoke(p, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        player:skip(sgs.Player_Judge)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
tangzi:addSkill(xingzhao)
tangzi:addRelateSkill('ol_xunxun')
huangfusong = sgs.General(extension_z, 'huangfusong', 'qun')
fenyueCard = sgs.CreateSkillCard {
    name = 'fenyue',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:canPindian(to_select, self:objectName())
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            if source:pindian(targets[1], self:objectName(), self) then
                room:broadcastSkillInvoke(self:objectName(), 2)
                local choices = 'fenyue1'
                if source:canSlash(targets[1], nil, false) then
                    choices = 'fenyue1+fenyue2'
                end
                local choice = room:askForChoice(source, self:objectName(), choices)
                if choice == 'fenyue2' then
                    local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    slash:setSkillName('_' .. self:objectName())
                    room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
                else
                    room:addPlayerMark(targets[1], 'ban_ur')
                    room:setPlayerCardLimitation(targets[1], 'use,response', '.|.|.|hand', false)
                end
            else
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:setPlayerFlag(source, 'Global_PlayPhaseTerminated')
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
fenyue = sgs.CreateOneCardViewAsSkill {
    name = 'fenyue',
    filter_pattern = '.|.|.|hand',
    view_as = function(self, card)
        local skillcard = fenyueCard:clone()
        skillcard:addSubcard(card:getId())
        skillcard:setSkillName(self:objectName())
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#fenyue') < player:getMark('fenyue')
    end,
}
huangfusong:addSkill(fenyue)
ol_caoren = sgs.General(extension_god, 'ol_caoren', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
ol_jushou = sgs.CreatePhaseChangeSkill {
    name = 'ol_jushou',
    on_phasechange = function(self, target)
        local room = target:getRoom()
        if target:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(target, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(target, self:objectName() .. 'engine')
            if target:getMark(self:objectName() .. 'engine') > 0 then
                target:turnOver()
                target:drawCards(4)
                if not target:isKongcheng() then
                    local card = room:askForCard(target, '.|.|.|hand!', '@jushou', sgs.QVariant(), sgs.Card_MethodNone)
                    if card then
                        if card:isKindOf('EquipCard') and not target:isCardLimited(card, sgs.Card_MethodUse) then
                            room:useCard(sgs.CardUseStruct(card, target, target))
                        else
                            room:throwCard(card, target, target)
                        end
                    end
                end
                room:removePlayerMark(target, self:objectName() .. 'engine')
            end
        end
    end,
}
ol_caoren:addSkill(ol_jushou)
ol_jieweiCard = sgs.CreateSkillCard {
    name = 'ol_jiewei',
    filter = function(self, targets, to_select)
        return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        if #targets == 0 then
            return
        end
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            if not targets[1]:hasEquip() and targets[1]:getJudgingArea():length() == 0 then
                return
            end
            local card_id = room:askForCardChosen(source, targets[1], 'ej', self:objectName())
            local card = sgs.Sanguosha:getCard(card_id)
            local place = room:getCardPlace(card_id)
            local equip_index = -1
            if place == sgs.Player_PlaceEquip then
                local equip = card:getRealCard():toEquipCard()
                equip_index = equip:location()
            end
            local tos = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if equip_index ~= -1 then
                    if not p:getEquip(equip_index) and p:hasEquipArea(equip_index) then
                        tos:append(p)
                    end
                else
                    if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) and p:hasJudgeArea() then
                        tos:append(p)
                    end
                end
            end
            local tag = sgs.QVariant()
            tag:setValue(targets[1])
            room:setTag('QiaobianTarget', tag)
            local to = room:askForPlayerChosen(source, tos, self:objectName(), '@qiaobian-to' .. card:objectName())
            if to then
                room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,
                    source:objectName(), self:objectName(), ''))
            end
            room:removeTag('QiaobianTarget')
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
ol_jieweiVS = sgs.CreateOneCardViewAsSkill {
    name = 'ol_jiewei',
    view_filter = function(self, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == 'nullification' then
            return to_select:isEquipped()
        end
        return true
    end,
    view_as = function(self, first)
        if sgs.Sanguosha:getCurrentCardUsePattern() == 'nullification' then
            local ncard = sgs.Sanguosha:cloneCard('nullification', first:getSuit(), first:getNumber())
            ncard:addSubcard(first)
            ncard:setSkillName(self:objectName())
            return ncard
        else
            local card = ol_jieweiCard:clone()
            card:addSubcard(first)
            card:setSkillName(self:objectName())
            return card
        end
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == 'nullification' or pattern == '@ol_jiewei'
    end,
    enabled_at_nullification = function(self, player)
        return player:hasEquip()
    end,
}
ol_jiewei = sgs.CreateTriggerSkill {
    name = 'ol_jiewei',
    view_as_skill = ol_jieweiVS,
    events = {sgs.TurnedOver},
    on_trigger = function(self, event, player, data, room)
        if player:faceUp() then
            room:askForUseCard(player, '@ol_jiewei', '@ol_jiewei', -1, sgs.Card_MethodNone)
        end
    end,
}
ol_caoren:addSkill(ol_jiewei)
bug_caoren = sgs.General(extension_sp, 'bug_caoren', 'wei', 4, true,
    sgs.GetConfig('hidden_ai', true) or sgs.GetConfig('EnableHidden', true))
weikuiCard = sgs.CreateSkillCard {
    name = 'weikui',
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isKongcheng()
    end,
    on_use = function(self, room, source, targets)
        room:loseHp(source)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local bug = sgs.IntList()
            for _, card in sgs.qlist(targets[1]:getHandcards()) do
                if not card:isKindOf('Jink') then
                    bug:append(card:getEffectiveId())
                end
            end
            local id = room:doGongxin(source, targets[1], bug, self:objectName())
            if bug:length() == targets[1]:getHandcardNum() then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, source:objectName(), nil,
                    self:objectName(), nil)
                if id ~= -1 then
                    room:throwCard(sgs.Sanguosha:getCard(id), reason, targets[1], source)
                else
                    room:throwCard(targets[1]:getRandomHandCard(), reason, targets[1], source)
                end
            else
                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                slash:setSkillName('_' .. self:objectName())
                if sgs.Slash_IsAvailable(source) and source:canSlash(targets[1], nil, false) and
                    not source:isProhibited(targets[1], slash) then
                    local players = sgs.SPlayerList()
                    players:append(targets[1])
                    room:useCard(sgs.CardUseStruct(slash, source, players))
                    room:setFixedDistance(source, targets[1], 1)
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
weikui = sgs.CreateZeroCardViewAsSkill {
    name = 'weikui',
    view_as = function(self, cards)
        local card = weikuiCard:clone()
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#weikui') and player:getHp() > 0
    end,
}
bug_caoren:addSkill(weikui)
lizhanCard = sgs.CreateSkillCard {
    name = 'lizhan',
    filter = function(self, targets, to_select)
        return to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            effect.to:drawCards(1, self:objectName())
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
lizhanVS = sgs.CreateZeroCardViewAsSkill {
    name = 'lizhan',
    response_pattern = '@@lizhan',
    view_as = function()
        return lizhanCard:clone()
    end,
}
lizhan = sgs.CreatePhaseChangeSkill {
    name = 'lizhan',
    view_as_skill = lizhanVS,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local invoke = false
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isWounded() then
                invoke = true
            end
        end
        if player:getPhase() == sgs.Player_Finish and invoke then
            room:askForUseCard(player, '@@lizhan', '@lizhan')
        end
        return false
    end,
}
bug_caoren:addSkill(lizhan)
xinxianying = sgs.General(extension7, 'xinxianying', 'wei', 3, false, sgs.GetConfig('hidden_ai', true))
zhongjianCard = sgs.CreateSkillCard {
    name = 'zhongjian',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getHandcardNum() > to_select:getHp() and to_select:objectName() ~=
                   sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:showCard(source, self:getSubcards():first())
            local ids = getIntList(targets[1]:getHandcards())
            local color, num = false, false
            for _ = 1, targets[1]:getHandcardNum() - targets[1]:getHp() do
                local id = ids:at(math.random(0, ids:length() - 1))
                room:showCard(targets[1], id)
                if GetColor(sgs.Sanguosha:getCard(id)) == GetColor(sgs.Sanguosha:getCard(self:getSubcards():first())) then
                    color = true
                end
                if sgs.Sanguosha:getCard(id):getNumber() == sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() then
                    num = true
                end
                ids:removeOne(id)
            end
            if color then
                local choices = {'danxin1'}
                if source:canDiscard(targets[1], 'he') then
                    table.insert(choices, 'zhongjian1')
                end
                local choice = room:askForChoice(source, self:objectName(), table.concat(choices, '+'))
                ChoiceLog(source, choice)
                if choice == 'danxin1' then
                    source:drawCards(1, self:objectName())
                else
                    local throw = room:askForCardChosen(source, targets[1], 'he', self:objectName(), false,
                        sgs.Card_MethodDiscard)
                    room:throwCard(sgs.Sanguosha:getCard(throw), targets[1], source)
                end
            end
            if num then
                room:addPlayerMark(source, 'zhongjian_Play')
                sgs.Sanguosha:addTranslationEntry(':zhongjian',
                    '' .. string.gsub(sgs.Sanguosha:translate(':zhongjian'), sgs.Sanguosha:translate(':zhongjian'),
                        sgs.Sanguosha:translate(':zhongjian1')))
                ChangeCheck(source, 'xinxianying')
            end
            if not num and not color and source:getMaxCards() > 0 then
                room:addPlayerMark(source, '@zhongjian')
                CDM(room, source, '@Maxcards', '@zhongjian')
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
zhongjian = sgs.CreateOneCardViewAsSkill {
    name = 'zhongjian',
    filter_pattern = '.',
    view_as = function(self, card)
        local skillcard = zhongjianCard:clone()
        skillcard:setSkillName(self:objectName())
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        if player:getMark('zhongjian_Play') > 0 then
            return player:usedTimes('#zhongjian') < 2
        end
        return not player:hasUsed('#zhongjian')
    end,
}
xinxianying:addSkill(zhongjian)
caishi = sgs.CreatePhaseChangeSkill {
    name = 'caishi',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Draw then
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                local choices = {'caishi1+cancel'}
                if player:isWounded() then
                    table.insert(choices, 1, 'caishi2')
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                if choice ~= 'cancel' then
                    lazy(self, room, player, choice)
                    if choice == 'caishi1' then
                        room:broadcastSkillInvoke(self:objectName(), 2)
                        room:addPlayerMark(player, '@Maxcards')
                        CDM(room, player, '@Maxcards', '@zhongjian')
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            room:addPlayerMark(p, 'caishi-Clear')
                        end
                    else
                        room:broadcastSkillInvoke(self:objectName(), 1)
                        room:recover(player, sgs.RecoverStruct(player))
                        room:addPlayerMark(player, 'caishi-Clear')
                    end
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
xinxianying:addSkill(caishi)
xushi = sgs.General(extension7, 'xushi', 'wu', 3, false, sgs.GetConfig('hidden_ai', true))
wengua = sgs.CreateTriggerSkill {
    name = 'wengua',
    events = {sgs.GameStart, sgs.EventAcquireSkill},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event == sgs.GameStart then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if not p:hasSkill('wengua_bill') then
                    room:attachSkillToPlayer(p, 'wengua_bill')
                end
            end
        end
    end,
}
xushi:addSkill(wengua)
fuzhu = sgs.CreatePhaseChangeSkill {
    name = 'fuzhu',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:inMyAttackRange(player) and player:getPhase() == sgs.Player_Finish and player:isMale() and
                not room:getDrawPile():isEmpty() and room:getDrawPile():length() < p:getHp() * 10 and
                p:askForSkillInvoke(self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local x = 0
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card and card:isKindOf('Slash') and p:canSlash(player, card, true) then
                            room:useCard(sgs.CardUseStruct(card, p, player))
                            x = x + 1
                            if x == room:alivePlayerCount() then
                                break
                            end
                        end
                    end
                    local ids = sgs.IntList()
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        ids:append(id)
                    end
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    dummy:addSubcards(ids)
                    room:throwCard(dummy, nil, nil)
                    if player:isDead() then
                        room:broadcastSkillInvoke(self:objectName(), 1)
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
}
xushi:addSkill(fuzhu)
caojie = sgs.General(extension7, 'caojie', 'qun', 3, false, sgs.GetConfig('hidden_ai', true))
shouxi = sgs.CreateTriggerSkill {
    name = 'shouxi',
    events = {sgs.SlashEffected, sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player) and use.card and use.card:isKindOf('Slash') then
                local ban_list, choices = {}, sgs.IntList()
                for i = 0, 10000 do
                    local card = sgs.Sanguosha:getEngineCard(i)
                    if card == nil then
                        break
                    end
                    if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and
                        not (table.contains(ban_list, TrueName(card))) then
                        if (card:isKindOf('BasicCard') or card:isNDTrick()) then
                            table.insert(ban_list, TrueName(card))
                        end
                    end
                end
                for _, name in ipairs(ban_list) do
                    for i = 0, 10000 do
                        local card = sgs.Sanguosha:getEngineCard(i)
                        if card == nil then
                            break
                        end
                        if card:objectName() == name and (card:isKindOf('BasicCard') or card:isNDTrick()) and card:getSuit() ==
                            6 and card:getNumber() == 14 and player:getMark(self:objectName() .. name) == 0 then
                            choices:append(i)
                        end
                    end
                end
                room:fillAG(choices)
                local card_id = room:askForAG(player, choices, true, self:objectName())
                if card_id ~= -1 then
                    room:broadcastSkillInvoke(self:objectName())
                    ChoiceLog(player, sgs.Sanguosha:getCard(card_id):objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        room:addPlayerMark(player, self:objectName() .. sgs.Sanguosha:getCard(card_id):objectName())
                        if not room:askForCard(use.from, sgs.Sanguosha:getCard(card_id):objectName(), '@jiyu', data) then
                            local nullified_list = use.nullified_list
                            table.insert(nullified_list, player:objectName())
                            use.nullified_list = nullified_list
                            data:setValue(use)
                        else
                            local id = room:askForCardChosen(use.from, player, 'he', self:objectName(), false)
                            room:obtainCard(use.from, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_EXTRACTION, use.from:objectName()), false)
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
                room:clearAG()
            end
        end
    end,
}
caojie:addSkill(shouxi)
huimin = sgs.CreatePhaseChangeSkill {
    name = 'huimin',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() < p:getHp() then
                targets:append(p)
            end
        end
        if player:getPhase() == sgs.Player_Finish and not targets:isEmpty() and
            room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:drawCards(targets:length())
                local cards = room:askForExchange(player, self:objectName(),
                    math.min(player:getHandcardNum(), targets:length()), math.min(player:getHandcardNum(), targets:length()),
                    false, '@xiashu-invoke', false)
                if cards then
                    local ids = sgs.IntList()
                    for _, id in sgs.qlist(cards:getSubcards()) do
                        room:showCard(player, id)
                        ids:append(id)
                    end
                    room:fillAG(ids)
                    local to = room:askForPlayerChosen(player, targets, self:objectName(), 'huimin-invoke', false, true)
                    local start = false
                    for _, p in sgs.qlist(targets) do
                        if ids:isEmpty() then
                            break
                        end
                        if p:objectName() == to:objectName() then
                            start = true
                        end
                        if start then
                            local id = room:askForAG(p, ids, false, self:objectName())
                            room:takeAG(p, id, false)
                            ids:removeOne(id)
                            p:obtainCard(sgs.Sanguosha:getCard(id), false)
                            targets:removeOne(p)
                        end
                    end
                    for _, p in sgs.qlist(targets) do
                        if ids:isEmpty() then
                            break
                        end
                        local id = room:askForAG(p, ids, false, self:objectName())
                        room:takeAG(p, id, false)
                        ids:removeOne(id)
                        p:obtainCard(sgs.Sanguosha:getCard(id), false)
                        targets:removeOne(p)
                    end
                    room:clearAG()
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
caojie:addSkill(huimin)
quyi = sgs.General(extension, 'quyi', 'qun')
fuji = sgs.CreateTriggerSkill {
    name = 'fuji',
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            local invoke = false
            for _, p in sgs.qlist(use.to) do
                if p:distanceTo(use.from) == 1 then
                    invoke = true
                end
            end
            if (use.card:isKindOf('Slash') or use.card:isNDTrick()) and invoke and use.from:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                use.from:setTag('FujiSlash', sgs.QVariant(use.from:getTag('FujiSlash'):toInt() + 1))
                if RIGHT(self, use.from) and player:distanceTo(use.from) == 1 then
                    local jink_table = sgs.QList2Table(use.from:getTag('Jink_' .. use.card:toString()):toIntList())
                    jink_table[use.from:getTag('FujiSlash'):toInt() - 1] = 0
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    use.from:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and RIGHT(self, effect.from) and player:distanceTo(effect.from) == 1 then
                return true
            end
        else
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                player:setTag('FujiSlash', sgs.QVariant(0))
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
quyi:addSkill(fuji)
jiaozi = sgs.CreateTriggerSkill {
    name = 'jiaozi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getHandcardNum() >= player:getHandcardNum() then
                return false
            end
        end
        local n = 2
        if event == sgs.DamageCaused then
            n = 1
            room:getThread():delay(3500)
        end
        SendComLog(self, player, n)
        room:addPlayerMark(player, self:objectName() .. 'engine')
        if player:getMark(self:objectName() .. 'engine') > 0 then
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            data:setValue(damage)
            room:removePlayerMark(player, self:objectName() .. 'engine')
        end
        return false
    end,
}
quyi:addSkill(jiaozi)
xizhicai = sgs.General(extension_star, 'xizhicai', 'wei', 3)
xizhicai:addSkill('tiandu')
xianfu = sgs.CreateTriggerSkill {
    name = 'xianfu',
    events = {sgs.GameStart, sgs.HpRecover, sgs.Damaged},
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart and RIGHT(self, player) then
            local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'xianfu-invoke',
                false, sgs.GetConfig('face_game', true))
            if to then
                room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    if sgs.GetConfig('face_game', true) then
                        room:addPlayerMark(to, '@fu')
                    end
                    room:addPlayerMark(to, 'fu' .. player:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        else
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:getMark('fu' .. p:objectName()) > 0 and player:isAlive() then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    if player:getMark('@fu') == 0 then
                        room:addPlayerMark(player, '@fu')
                    end
                    if event == sgs.Damaged then
                        room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
                        room:damage(sgs.DamageStruct(self:objectName(), nil, p, data:toDamage().damage))
                    else
                        room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
                        room:recover(p, sgs.RecoverStruct(p, nil, data:toRecover().recover))
                    end
                end
            end
        end
        return false
    end,
}
xizhicai:addSkill(xianfu)
chouce = sgs.CreateTriggerSkill {
    name = 'chouce',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        for _ = 0, damage.damage - 1 do
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local judge = sgs.JudgeStruct()
                    judge.pattern = '.'
                    judge.reason = self:objectName()
                    judge.who = player
                    room:judge(judge)
                    room:setTag('chouce', sgs.QVariant(judge.card:isRed()))
                    if judge.card:isRed() then
                        local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                            'chouce-invoke', true, true)
                        if to then
                            local x = 1
                            if to:getMark('fu' .. player:objectName()) > 0 then
                                x = 2
                                room:broadcastSkillInvoke(self:objectName(), 2)
                            end
                            to:drawCards(x, self:objectName())
                        end
                    elseif judge.card:isBlack() then
                        local targets = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if player:canDiscard(p, 'hej') then
                                targets:append(p)
                            end
                        end
                        if not targets:isEmpty() then
                            local to = room:askForPlayerChosen(player, targets, self:objectName(), 'chouce-invoke', true,
                                true)
                            if to then
                                if to:getMark('fu' .. player:objectName()) > 0 then
                                    room:broadcastSkillInvoke(self:objectName(), 2)
                                end
                                local id = room:askForCardChosen(player, to, 'hej', self:objectName(), false,
                                    sgs.Card_MethodDiscard)
                                room:throwCard(id, to, player)
                            end
                        end
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
xizhicai:addSkill(chouce)
sunqian = sgs.General(extension_star, 'sunqian', 'shu', 3)
qianya = sgs.CreateTriggerSkill {
    name = 'qianya',
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.to:contains(player) and use.card:isKindOf('TrickCard') and not player:isKongcheng() then
            if room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, -1, sgs.SPlayerList(),
                sgs.CardMoveReason(), '@qianya', true) then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
sunqian:addSkill(qianya)
shuimeng = sgs.CreateTriggerSkill {
    name = 'shuimeng',
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:canPindian(p, self:objectName()) then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local to = room:askForPlayerChosen(player, targets, self:objectName(), 'shuimeng-invoke', true, true)
                if to then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local success = player:pindian(to, self:objectName(), nil)
                        local card = sgs.Sanguosha:cloneCard('dismantlement', sgs.Card_NoSuit, 0)
                        if success then
                            card = sgs.Sanguosha:cloneCard('ex_nihilo', sgs.Card_NoSuit, 0)
                            to = player
                        end
                        card:setSkillName('shuimeng')
                        if not to:isLocked(card) and not to:isProhibited(player, card) then
                            room:useCard(sgs.CardUseStruct(card, to, player))
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
sunqian:addSkill(shuimeng)
wuxian = sgs.General(extension7, 'wuxian', 'shu', 3, false, sgs.GetConfig('hidden_ai', true))
fumian = sgs.CreatePhaseChangeSkill {
    name = 'fumian',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish then
            local choices = {'cancel'}
            if player:getMark('@fumian2') == 0 then
                table.insert(choices, 1, 'fumian2')
            end
            if player:getMark('@fumian1') == 0 then
                table.insert(choices, 1, 'fumian1')
            end
            if #choices == 1 then
                room:removePlayerMark(player, '@fumian1')
                room:removePlayerMark(player, '@fumian2')
                table.insert(choices, 1, 'fumian1+fumian2')
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
            if choice ~= 'cancel' then
                lazy(self, room, player, choice, true)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:addPlayerMark(player, '@' .. choice)
                    room:addPlayerMark(player, choice .. '_manmanlai', 2)
                    room:addPlayerMark(player, choice .. 'now_manmanlai')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
wuxian:addSkill(fumian)
daiyan = sgs.CreatePhaseChangeSkill {
    name = 'daiyan',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start then
            local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                '@invoke:' .. self:objectName(), true, true)
            if to then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local peachs = sgs.IntList()
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf('Peach') then
                            peachs:append(id)
                        end
                    end
                    if not peachs:isEmpty() then
                        room:obtainCard(to, peachs:at(0), true)
                        if to:getMark('@lazy') > 0 then
                            room:getThread():delay(3000)
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            room:loseHp(to)
                        end
                        room:setPlayerMark(to, '@lazy', 1)
                        for _, p in sgs.qlist(room:getOtherPlayers(to)) do
                            if p:getMark('@lazy') > 0 then
                                room:setPlayerMark(to, '@lazy', 0)
                            end
                        end
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
wuxian:addSkill(daiyan)
ol_wuxian = sgs.General(extension_star, 'ol_wuxian', 'shu', 3, false, sgs.GetConfig('hidden_ai', true))
ol_fumian = sgs.CreatePhaseChangeSkill {
    name = 'ol_fumian',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start then
            if (player:getMark('ol_fummian1_manmanlai') == 2 and player:getMark('ol_fummian2_manmanlai') == 1) or
                (player:getMark('ol_fummian2_manmanlai') == 2 and player:getMark('ol_fummian1_manmanlai') == 1) then
                room:setPlayerMark(player, 'ol_fummian1_manmanlai', 0)
                room:setPlayerMark(player, 'ol_fummian2_manmanlai', 0)
            end
            local choice = room:askForChoice(player, self:objectName(), 'ol_fumian1+ol_fumian2+cancel')
            if choice ~= 'cancel' then
                lazy(self, room, player, choice, true)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setPlayerMark(player, choice .. '_manmanlai', 3)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
ol_wuxian:addSkill(ol_fumian)
ol_daiyan = sgs.CreatePhaseChangeSkill {
    name = 'ol_daiyan',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish then
            local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                '@invoke:' .. self:objectName(), true, true)
            if to then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    local peachs = sgs.IntList()
                    for _, id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') and sgs.Sanguosha:getCard(id):getSuit() ==
                            sgs.Card_Heart then
                            peachs:append(id)
                        end
                    end
                    if not peachs:isEmpty() then
                        room:obtainCard(to, peachs:at(0), true)
                        if to:getMark('@ol_lazy') > 0 then
                            room:getThread():delay(2000)
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            room:loseHp(to)
                        end
                        for _, p in sgs.qlist(room:getOtherPlayers(to)) do
                            if p:getMark('@ol_lazy') > 0 then
                                room:setPlayerMark(p, '@ol_lazy', 0)
                            end
                        end
                        room:setPlayerMark(to, '@ol_lazy', 1)
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
ol_wuxian:addSkill(ol_daiyan)
ol_xuhuang = sgs.General(extension_god, 'ol_xuhuang', 'wei', 4, true, sgs.GetConfig('EnableHidden', true))
ol_duanliang = sgs.CreateOneCardViewAsSkill {
    name = 'ol_duanliang',
    filter_pattern = 'BasicCard,EquipCard|black',
    response_or_use = true,
    view_as = function(self, card)
        local shortage = sgs.Sanguosha:cloneCard('supply_shortage', card:getSuit(), card:getNumber())
        shortage:setSkillName(self:objectName())
        shortage:addSubcard(card)
        return shortage
    end,
}
ol_duanliang_buff = sgs.CreateTargetModSkill {
    name = '#ol_duanliang',
    pattern = 'SupplyShortage',
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill('ol_duanliang') and to and to:getHandcardNum() >= from:getHandcardNum() then
            return 1000
        end
        return 0
    end,
}
ol_xuhuang:addSkill(ol_duanliang)
ol_xuhuang:addSkill(ol_duanliang_buff)
extension:insertRelatedSkills('ol_duanliang', '#ol_duanliang')
jiezi = sgs.CreateTriggerSkill {
    name = 'jiezi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseSkipping},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Draw then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                SendComLog(self, p)
                room:addPlayerMark(p, self:objectName() .. 'engine')
                if p:getMark(self:objectName() .. 'engine') > 0 then
                    p:drawCards(1, self:objectName())
                    room:removePlayerMark(p, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_xuhuang:addSkill(jiezi)
ol_xiaoqiao = sgs.General(extension_god, 'ol_xiaoqiao', 'wu', 3, false,
    sgs.GetConfig('hidden_ai', true) or sgs.GetConfig('EnableHidden', true))
ol_xiaoqiao:addSkill('hongyan')
ol_tianxiangCard = sgs.CreateSkillCard {
    name = 'ol_tianxiang',
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local choices = {'tianxiang1'}
            if targets[1]:getHp() > 0 then
                table.insert(choices, 'tianxiang2')
            end
            local choice = room:askForChoice(source, self:objectName(), table.concat(choices, '+'))
            if choice == 'tianxiang1' then
                room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
                targets[1]:drawCards(math.min(targets[1]:getLostHp(), 5), 'tianxiang')
            else
                room:loseHp(targets[1])
                room:obtainCard(targets[1], self)
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
ol_tianxiangVS = sgs.CreateOneCardViewAsSkill {
    name = 'ol_tianxiang',
    view_filter = function(self, selected)
        return not selected:isEquipped() and selected:getSuit() == sgs.Card_Heart and not sgs.Self:isJilei(selected)
    end,
    view_as = function(self, card)
        local tianxiangCard = ol_tianxiangCard:clone()
        tianxiangCard:addSubcard(card)
        return tianxiangCard
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@ol_tianxiang'
    end,
}
ol_tianxiang = sgs.CreateTriggerSkill {
    name = 'ol_tianxiang',
    events = {sgs.DamageInflicted},
    view_as_skill = ol_tianxiangVS,
    on_trigger = function(self, event, player, data, room)
        if player:canDiscard(player, 'h') then
            return room:askForUseCard(player, '@@ol_tianxiang', '@ol_tianxiang', -1, sgs.Card_MethodDiscard)
        end
        return false
    end,
}
ol_xiaoqiao:addSkill(ol_tianxiang)
caiyong = sgs.General(extension7, 'caiyong', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
pizhuan = sgs.CreateTriggerSkill {
    name = 'pizhuan',
    events = {sgs.CardUsed, sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (player:getPile('book'):length() < 4 and
            ((event == sgs.TargetConfirmed and use.to:contains(player) and use.from:objectName() ~= player:objectName()) or
                (event == sgs.CardUsed and use.from:objectName() == player:objectName()))) and use.card:getSuit() ==
            sgs.Card_Spade and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:addToPile('book', room:drawCard())
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
caiyong:addSkill(pizhuan)
tongboCard = sgs.CreateSkillCard {
    name = 'tongbo',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local to_handcard = sgs.IntList()
        local to_pile = sgs.IntList()
        local set = source:getPile('book')
        for _, id in sgs.qlist(self:getSubcards()) do
            set:append(id)
        end
        for _, id in sgs.qlist(set) do
            if not self:getSubcards():contains(id) then
                to_handcard:append(id)
            elseif not source:getPile('book'):contains(id) then
                to_pile:append(id)
            end
        end
        assert(to_handcard:length() == to_pile:length())
        if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then
            return
        end
        room:notifySkillInvoked(source, 'tongbo')
        source:addToPile('book', to_pile, false)
        local to_handcard_x = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, id in sgs.qlist(to_handcard) do
            to_handcard_x:addSubcard(id)
        end
        room:obtainCard(source, to_handcard_x, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
            source:objectName(), self:objectName(), ''))
        local suits = {}
        for _, id in sgs.qlist(source:getPile('book')) do
            if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuit()) then
                table.insert(suits, sgs.Sanguosha:getCard(id):getSuit())
            end
        end
        if #suits == 4 then
            while not source:getPile('book'):isEmpty() do
                room:setPlayerFlag(source, 'Fake_Move')
                local ids = source:getPile('book')
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                dummy:addSubcards(ids)
                source:obtainCard(dummy)
                room:setPlayerFlag(source, '-Fake_Move')
                while room:askForYiji(source, ids, self:objectName(), false, true, false, -1, room:getOtherPlayers(source)) do
                    if ids:isEmpty() then
                        break
                    end
                end
            end
        end
    end,
}
tongboVS = sgs.CreateViewAsSkill {
    name = 'tongbo',
    n = 4,
    response_pattern = '@@tongbo',
    expand_pile = 'book',
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return not sgs.Sanguosha:matchExpPattern('.|.|.|book', sgs.Self, to_select)
        end
        if #selected < sgs.Self:getPile('book'):length() then
            return not to_select:isEquipped()
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == sgs.Self:getPile('book'):length() and #cards ~= 0 then
            local c = tongboCard:clone()
            for _, card in ipairs(cards) do
                c:addSubcard(card)
            end
            return c
        end
        return nil
    end,
}
tongbo = sgs.CreateTriggerSkill {
    name = 'tongbo',
    events = {sgs.EventPhaseEnd},
    view_as_skill = tongboVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Draw and not player:getPile('book'):isEmpty() then
            room:askForUseCard(player, '@@tongbo', '@tongbo', -1, sgs.Card_MethodNone)
        end
        return false
    end,
}
caiyong:addSkill(tongbo)
jikang = sgs.General(extension7, 'jikang', 'wei', 3, true, sgs.GetConfig('hidden_ai', true))
function useEquip(room, player, kind)
    local equips = sgs.CardList()
    for _, id in sgs.qlist(room:getDrawPile()) do
        if sgs.Sanguosha:getCard(id):isKindOf('EquipCard') and (kind == nil or sgs.Sanguosha:getCard(id):isKindOf(kind)) then
            equips:append(sgs.Sanguosha:getCard(id))
        end
    end
    if not equips:isEmpty() then
        local card = equips:at(math.random(0, equips:length() - 1))
        room:useCard(sgs.CardUseStruct(card, player, player))
        return card
    end
    return nil
end
function throwEquip(room, player)
    local invoke = '.|.|.|equipped'
    for _, card in sgs.qlist(player:getHandcards()) do
        if card:isKindOf('EquipCard') then
            invoke = '.|.|.|equipped!'
            break
        end
    end
    local card = room:askForCard(player, invoke, '@throw_E', sgs.QVariant(), sgs.Card_MethodNone)
    if not card then
        room:showAllCards(player)
    end
    return card
end
qingxian = sgs.CreateTriggerSkill {
    name = 'qingxian',
    events = {sgs.Damaged, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if room:getCurrentDyingPlayer() then
            return false
        end
        local target
        local choices = {}
        if event == sgs.Damaged then
            target = data:toDamage().from
            table.insert(choices, 'cancel')
        end
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getHp() > 0 or p:getLostHp() > 0 then
                players:append(p)
            end
        end
        if event == sgs.HpRecover and not players:isEmpty() then
            target = room:askForPlayerChosen(player, players, self:objectName(), 'qingxian-invoke', true, true)
        end
        if target then
            if target:getHp() > 0 then
                table.insert(choices, 'qingxian1')
            end
            if target:getLostHp() > 0 then
                table.insert(choices, 'qingxian2')
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
            if choice ~= 'cancel' then
                lazy(self, room, player, choice, true)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    if choice == 'qingxian1' then
                        room:loseHp(target)
                        if target:isAlive() then
                            local card = useEquip(room, target)
                            if card and card:getSuit() == sgs.Card_Club then
                                player:drawCards(1, self:objectName())
                            end
                        end
                    else
                        room:recover(target, sgs.RecoverStruct(player))
                        local card = throwEquip(room, target)
                        if card and card:getSuit() == sgs.Card_Club then
                            player:drawCards(1, self:objectName())
                        end
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
jikang:addSkill(qingxian)
juexiang = sgs.CreateTriggerSkill {
    name = 'juexiang',
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if data:toDeath().who:objectName() == player:objectName() then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 'juexiang-invoke',
                true, true)
            if target then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:broadcastSkillInvoke(self:objectName())
                    local jikang_skills = {'jixian', 'liexian', 'rouxian', 'hexian'}
                    room:handleAcquireDetachSkills(target, jikang_skills[math.random(1, #jikang_skills)])
                    room:addPlayerMark(target, 'juexiang_time')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}
jikang:addSkill(juexiang)
jixian = sgs.CreateMasochismSkill {
    name = 'jixian',
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        if room:getCurrentDyingPlayer() then
            return false
        end
        local data = sgs.QVariant()
        data:setValue(damage.from)
        if damage.from and damage.from:isAlive() and damage.from:getHp() > 0 and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:loseHp(damage.from)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if damage.from:isAlive() then
                    useEquip(room, damage.from)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill('jixian') then
    skills:append(jixian)
end
liexian = sgs.CreateTriggerSkill {
    name = 'liexian',
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if room:getCurrentDyingPlayer() then
            return false
        end
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers()) do
            if p:getHp() > 0 then
                players:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, players, self:objectName(), 'liexian-invoke', true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            room:loseHp(target)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if target:isAlive() then
                    useEquip(room, target)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill('liexian') then
    skills:append(liexian)
end
rouxian = sgs.CreateMasochismSkill {
    name = 'rouxian',
    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        if room:getCurrentDyingPlayer() then
            return false
        end
        local data = sgs.QVariant()
        data:setValue(damage.from)
        if damage.from and damage.from:isAlive() and damage.from:getLostHp() > 0 and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:recover(damage.from, sgs.RecoverStruct(player))
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                throwEquip(room, damage.from)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill('rouxian') then
    skills:append(rouxian)
end
hexian = sgs.CreateTriggerSkill {
    name = 'hexian',
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if room:getCurrentDyingPlayer() then
            return false
        end
        local players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers()) do
            if p:getHp() > 0 then
                players:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, players, self:objectName(), 'hexian-invoke', true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            room:recover(target, sgs.RecoverStruct(player))
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                throwEquip(room, target)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill('hexian') then
    skills:append(hexian)
end
qinmi = sgs.General(extension7, 'qinmi', 'shu', 3, true, sgs.GetConfig('hidden_ai', true))
jianzheng = sgs.CreateTriggerSkill {
    name = 'jianzheng',
    events = {sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if use.card:isKindOf('Slash') and not use.to:contains(p) and p:objectName() ~= player:objectName() and
                not p:isKongcheng() and use.from:inMyAttackRange(p) then
                local card = room:askForCard(p, '.|.|.|hand', '@jianzheng_put:' .. use.from:objectName(), data,
                    sgs.Card_MethodNone)
                if card then
                    skill(self, room, p, true)
                    room:moveCardTo(card, player, sgs.Player_DrawPile, true)
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        use.to = sgs.SPlayerList()
                        if not use.card:isBlack() then
                            use.to:append(p)
                        end
                        data:setValue(use)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}
qinmi:addSkill(jianzheng)
zhuandui = sgs.CreateTriggerSkill {
    name = 'zhuandui',
    events = {sgs.TargetSpecified, sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf('Slash') then
            local _data = sgs.QVariant()
            _data:setValue(p)
            if event == sgs.TargetSpecified then
                local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
                local index = 1
                for _, p in sgs.qlist(use.to) do
                    if player:canPindian(p, self:objectName()) and room:askForSkillInvoke(player, self:objectName(), _data) then
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            if player:pindian(p, self:objectName(), nil) then
                                room:getThread():delay(3000)
                                room:broadcastSkillInvoke(self:objectName(), 1)
                                jink_table[index] = 0
                            end
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
                jink_data:setValue(Table2IntList(jink_table))
                player:setTag('Jink_' .. use.card:toString(), jink_data)
            else
                if use.from and use.from:isAlive() and use.to:contains(player) and
                    player:canPindian(use.from, self:objectName()) and
                    room:askForSkillInvoke(player, self:objectName(), _data) then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if player:pindian(use.from, self:objectName(), nil) then
                            room:getThread():delay(3000)
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            local nullified_list = use.nullified_list
                            table.insert(nullified_list, player:objectName())
                            use.nullified_list = nullified_list
                            data:setValue(use)
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
}
qinmi:addSkill(zhuandui)
tianbian = sgs.CreateTriggerSkill {
    name = 'tianbian',
    events = {sgs.AskforPindianCard, sgs.PindianVerifying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AskforPindianCard and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), 1)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:setTag('pindian' .. data:toInt(), sgs.QVariant(room:drawCard()))
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif event == sgs.PindianVerifying and RIGHT(self, player) then
            local pindian = data:toPindian()
            if (pindian.from:objectName() == player:objectName() and pindian.from_card:getSuit() == sgs.Card_Heart) or
                (pindian.to:objectName() == player:objectName() and pindian.to_card:getSuit() == sgs.Card_Heart) then
                SendComLog(self, player, 2)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    if pindian.from:objectName() == player:objectName() then
                        pindian.from_number = 13
                    else
                        pindian.to_number = 13
                    end
                    data:setValue(pindian)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}
qinmi:addSkill(tianbian)
xuezong = sgs.General(extension7, 'xuezong', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
funan = sgs.CreateTriggerSkill {
    name = 'funan',
    events = {sgs.CardResponded, sgs.CardUsed, sgs.NullificationCardResponded},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            local card = room:getTag('Wolaigequ'):toCard()
            local to = room:getTag('Woxiangtu'):toPlayer()
            local ob
            if event == sgs.CardUsed then
                ob = data:toCardUse().card
            else
                local res = data:toCardResponse()
                if res.main_card then
                    card = res.main_card
                    ob = res.m_card
                    to = res.m_who
                end
            end
            local all_place_table = true
            if card then
                for _, id in sgs.qlist(card:getSubcards()) do
                    if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                        all_place_table = false
                    end
                end
                if all_place_table and (event ~= sgs.CardResponded or p:objectName() == to:objectName()) and
                    player:objectName() ~= p:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if p:getMark('@funan') == 0 then
                            player:obtainCard(card)
                            for _, c in sgs.qlist(card:getSubcards()) do
                                room:addPlayerMark(player, self:objectName() .. c .. '-Clear')
                                room:setPlayerCardLimitation(player, 'use,response', sgs.Sanguosha:getCard(c):toString(),
                                    false)
                            end
                        end
                        p:obtainCard(ob)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
xuezong:addSkill(funan)
jiexun = sgs.CreateTriggerSkill {
    name = 'jiexun',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        local n = 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            for _, card in sgs.qlist(p:getCards('ej')) do
                if card:getSuit() == sgs.Card_Diamond then
                    n = n + 1
                end
            end
        end
        if event == sgs.EventPhaseStart and RIGHT(self, player) and n > 0 and player:getPhase() == sgs.Player_Finish then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'jiexun-invoke',
                true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    target:drawCards(n, self:objectName())
                    local all = false
                    if player:getMark('@jiexun') > 0 then
                        local ids = sgs.IntList()
                        for _, c in sgs.qlist(target:getCards('he')) do
                            if target:canDiscard(target, c:getEffectiveId()) then
                                ids:append(c:getEffectiveId())
                            end
                        end
                        all = ids:length() == target:getCards('he'):length() and player:getMark('@jiexun') >=
                                  target:getCards('he'):length()
                        player:speak(ids:length())
                        player:speak(target:getCards('he'):length())
                        room:askForDiscard(target, self:objectName(), player:getMark('@jiexun'), player:getMark('@jiexun'),
                            false, true)
                    end
                    if all then
                        room:getThread():delay(3000)
                        room:broadcastSkillInvoke(self:objectName(), 2)
                        room:detachSkillFromPlayer(player, self:objectName())
                        sgs.Sanguosha:addTranslationEntry(':funan', '' ..
                            string.gsub(sgs.Sanguosha:translate(':funan'), sgs.Sanguosha:translate(':funan'),
                                sgs.Sanguosha:translate(':funan1')))
                        ChangeCheck(player, 'xuezong')
                        room:addPlayerMark(player, '@funan')
                    end
                    room:addPlayerMark(player, '@jiexun')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
xuezong:addSkill(jiexun)
wangyun = sgs.General(extension, 'wangyun', 'qun', 4, true, true, true)
lianjiCard = sgs.CreateSkillCard {
    name = 'lianji',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return to_select:getMark('lianji_Play') == 0
    end,
    on_use = function(self, room, source, targets)
        room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
            targets[1]:objectName(), self:objectName(), ''), false)
        local card = useEquip(room, targets[1], 'Weapon')
        if card then
            -- 临时规避
            room:broadcastSkillInvoke(self:objectName())
        end
        room:setCardFlag(self, 'lianji' .. source:objectName())
    end,
}
lianjiVS = sgs.CreateOneCardViewAsSkill {
    name = 'lianji',
    view_filter = function(self, card)
        return card:isKindOf('Slash') or (card:isBlack() and card:isKindOf('TrickCard'))
    end,
    view_as = function(self, card)
        local lianjicard = lianjiCard:clone()
        lianjicard:addSubcard(card)
        return lianjicard
    end,
}
lianji = sgs.CreateTriggerSkill {
    name = 'lianji',
    events = {sgs.Damage, sgs.TargetSpecified},
    view_as_skill = lianjiVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if damage.card and damage.card:hasFlag('lianji' .. p:objectName()) then
                    room:addPlayerMark(p, 'lianji')
                end
            end
        else
            local use = data:toCardUse()
            for _, p in sgs.qlist(use.to) do
                if use.card and use.card:hasFlag('lianji' .. p:objectName()) then
                    room:addPlayerMark(p, 'lianji-target')
                end
            end
        end
        return false
    end,
}
wangyun:addSkill(lianji)
moucheng = sgs.CreateTriggerSkill {
    name = 'moucheng',
    frequency = sgs.Skill_Wake,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        if player:getMark('lianji') == 3 and player:getMark(self:objectName()) > 0 then
            room:addPlayerMark(player, self:objectName())
            room:handleAcquireDetachSkills(target, '-lianji|jingong')
        end
        return false
    end,
}
wangyun:addSkill(moucheng)
jingong = sgs.CreateTriggerSkill {
    name = 'jingong',
    view_as_skill = jingongVS,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        if player:getMark(self:objectName() .. '-Clear') == 0 then
            room:loseHp(player)
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill('jingong') then
    skills:append(jingong)
end
-- 神之试炼
--------------------------------------------------------------------------------------------------------------------------------------
zhuque = sgs.General(extension_exam, 'zhuque', 'god', 4, false, true)
shenyi = sgs.CreateTriggerSkill {
    name = 'shenyi',
    events = {sgs.TurnOver, sgs.StartJudge},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnOver and player:faceUp() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            return true
        elseif event == sgs.StartJudge then
            local judge = data:toJudge()
            if judge.reason == 'indulgence' or judge.reason == 'lightning' or judge.reason == 'supply_shortage' then
                judge.good = not judge.good
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
        end
        return false
    end,
}
ol_fentian = sgs.CreateTriggerSkill {
    name = 'ol_fentian',
    events = {sgs.ConfirmDamage, sgs.TrickCardCanceling, sgs.SlashProceed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            damage.nature = sgs.DamageStruct_Fire
            data:setValue(damage)
            room:sendCompulsoryTriggerLog(poi, self:objectName())
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.card and effect.card:isRed() then
                return true
            end
        else
            local effect = data:toSlashEffect()
            if effect.from:objectName() == poi:objectName() and effect.slash:isRed() then
                room:sendCompulsoryTriggerLog(poi, self:objectName())
                room:slashResult(effect, nil)
                return true
            end
        end
    end,
}
zhuque:addSkill(shenyi)
zhuque:addSkill(ol_fentian)
huoshenzhurong = sgs.General(extension_exam, 'huoshenzhurong', 'god', 5, true, true)
huoshenzhurong:addSkill('shenyi')
xingxiaCard = sgs.CreateSkillCard {
    name = 'xingxia',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, 'xingxia_turn_count', 2)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getGeneralName() == 'yanling' or p:getGeneral2Name() == 'yanling' then
                room:damage(sgs.DamageStruct(self:objectName(), source, p, 2, sgs.DamageStruct_Fire))
            end
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isYourFriend(source) and
                not room:askForCard(p, '.|red', '@xingxia-discard:' .. p:objectName(), sgs.QVariant(), sgs.Card_MethodDiscard) then
                room:damage(sgs.DamageStruct(self:objectName(), source, p, 1, sgs.DamageStruct_Fire))
            end
        end
    end,
}
xingxia = sgs.CreateZeroCardViewAsSkill {
    name = 'xingxia',
    view_as = function()
        return xingxiaCard:clone()
    end,
    enabled_at_play = function(self, target)
        return target:getMark('xingxia_turn_count') == 0
    end,
}
huoshenzhurong:addSkill(xingxia)
yanling = sgs.General(extension_exam, 'yanling', 'god', 4, true, true)
huihuo = sgs.CreateTriggerSkill {
    name = 'huihuo',
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isYourFriend(player) then
                    room:damage(sgs.DamageStruct(self:objectName(), player, p, 3, sgs.DamageStruct_Fire))
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
yanling:addSkill(huihuo)
furan = sgs.CreateTriggerSkill {
    name = 'furan',
    frequency = sgs.Skill_NotCompulsory,
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:hasSkill('furan') then
                if not p:hasSkill('furan_use') then
                    room:attachSkillToPlayer(p, 'furan_use')
                end
            end
        end
        return false
    end,
}
yanling:addSkill(furan)
furan_use = sgs.CreateOneCardViewAsSkill {
    name = 'furan_use&',
    response_or_use = true,
    filter_pattern = '.|red',
    view_as = function(self, card)
        local peach = sgs.Sanguosha:cloneCard('peach', card:getSuit(), card:getNumber())
        peach:setSkillName(self:objectName())
        peach:addSubcard(card:getId())
        return peach
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasSkill('furan') and p:getHp() < 0 then
                return string.find(pattern, 'peach')
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill('furan_use') then
    skills:append(furan_use)
end
yandi = sgs.General(extension_exam, 'yandi', 'god', 6, true, true)
yandi:addSkill('shenyi')
shenen = sgs.CreatePhaseChangeSkill {
    name = 'shenen',
    frequency = sgs.Skill_Compulsory,
    on_phasechange = function()
    end,
}
yandi:addSkill(shenen)
chiyi = sgs.CreateTriggerSkill {
    name = 'chiyi',
    events = {sgs.DamageInflicted, sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local count = room:getTag('TurnLengthCount'):toInt()
        player:speak(count)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if not damage.to:isYourFriend(p) and count >= 3 then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        else
            if player:hasSkill(self:objectName()) then
                if count == 5 then
                    for _, pe in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:sendCompulsoryTriggerLog(pe, self:objectName())
                        for _, p in sgs.qlist(room:getAllPlayers()) do
                            room:damage(sgs.DamageStruct(self:objectName(), pe, p, 1, sgs.DamageStruct_Fire))
                        end
                    end
                elseif count == 7 then
                    for _, pe in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:sendCompulsoryTriggerLog(pe, self:objectName())
                        for _, p in sgs.qlist(room:getOtherPlayers(pe)) do
                            if p:getGeneralName() == 'yanling' or p:getGeneral2Name() == 'yanling' then
                                room:damage(sgs.DamageStruct(self:objectName(), pe, p, 5, sgs.DamageStruct_Fire))
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
yandi:addSkill(chiyi)
qinglong = sgs.General(extension_exam, 'qinglong', 'god', 4, true, true)
qinglong:addSkill('shenyi')
qinglong:addSkill('olleiji')
mushengoumang = sgs.General(extension_exam, 'mushengoumang', 'god', 5, true, true)
mushengoumang:addSkill('shenyi')
buchunCard = sgs.CreateSkillCard {
    name = 'buchun',
    target_fixed = false,
    filter = function(self, targets, to_select)
        local need = sgs.Self:isWounded()
        for _, p in sgs.qlist(sgs.Self:getSiblings()) do
            need = p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == 'shujing'
            if need then
                break
            end
        end
        if need then
            return #targets == 0 and to_select:isWounded() and OursContains(to_select)
        end
        return false
    end,
    feasible = function(self, targets)
        local need = sgs.Self:isWounded()
        for _, p in sgs.qlist(sgs.Self:getSiblings()) do
            need = p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == 'shujing'
            if need then
                break
            end
        end
        if need then
            return #targets == 0
        else
            return #targets == 1
        end
    end,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, 'buchun_turn_count', 2)
        if #targets == 1 then
            room:recover(targets[1], sgs.RecoverStruct(source, nil, 2))
        elseif #targets == 0 then
            room:loseHp(source)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == 'shujing' then
                    local hp = p:getHp()
                    room:revivePlayer(p)
                    room:setPlayerProperty(p, 'hp', sgs.QVariant(hp))
                    room:recover(p, sgs.RecoverStruct(source, nil, 1 - hp))
                    p:drawCards(2 - p:getHandcardNum(), self:objectName())
                end
            end
        end
        return false
    end,
}
buchun = sgs.CreateZeroCardViewAsSkill {
    name = 'buchun',
    view_as = function()
        return buchunCard:clone()
    end,
    enabled_at_play = function(self, player)
        local need = player:isWounded()
        for _, p in sgs.qlist(player:getSiblings()) do
            if need then
                break
            end
            need = (p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == 'shujing') or p:isWounded()
        end
        return player:getMark('buchun_turn_count') == 0 and need
    end,
}
mushengoumang:addSkill(buchun)
shujing = sgs.General(extension_exam, 'shujing', 'god', 2, false, true)
cuidu = sgs.CreateTriggerSkill {
    name = 'cuidu',
    events = {sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:isAlive() and not damage.to:hasSkill('zhongdu') then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:acquireSkill(damage.to, 'zhongdu')
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if (p:getGeneralName() == 'mushengoumang') then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
    end,
}
shujing:addSkill(cuidu)
zhongdu = sgs.CreateTriggerSkill {
    name = 'zhongdu',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local judge = sgs.JudgeStruct()
            judge.pattern = '.|heart'
            judge.who = player
            judge.reason = self:objectName()
            judge.good = false
            room:judge(judge)
            if judge:isGood() then
                room:damage(sgs.DamageStruct(self:objectName(), nil, player))
            end
            if judge.card:getSuit() ~= sgs.Card_Spade then
                room:detachSkillFromPlayer(player, self:objectName())
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill('zhongdu') then
    skills:append(zhongdu)
end
taihao = sgs.General(extension_exam, 'taihao', 'god', 6)
taihao:addSkill('shenyi')
taihao:addSkill('shenen')
god_qingyi = sgs.CreateTriggerSkill {
    name = 'god_qingyi',
    events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local count = room:getTag('TurnLengthCount'):toInt()
        if count == 3 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:isYourFriend(player) and p:isWounded() then
                    room:recover(p, sgs.RecoverStruct(player))
                end
            end
        elseif count == 5 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if not p:isYourFriend(player) then
                    room:loseHp(p)
                end
            end
        elseif count == 7 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(room:getPlayers()) do
                if (p:getGeneralName() == 'shujing' or p:getGeneralName() == 'mushengoumang') and p:isDead() and p:getMaxHp() >
                    0 then
                    room:revivePlayer(p)
                    room:drawCards(p, 3, self:objectName())
                    room:setPlayerProperty(p, 'maxhp', sgs.QVariant(p:getMaxHp() + 1))
                    local msg = sgs.LogMessage()
                    msg.type = '#GainMaxHp'
                    msg.from = p
                    msg.arg = 1
                    room:sendLog(msg)
                    room:recover(p, sgs.RecoverStruct(player, nil, 3))
                end
            end
        end
        return false
    end,
}
taihao:addSkill(god_qingyi)
baihu = sgs.General(extension_exam, 'baihu', 'god')
baihu:addSkill('shenyi')
kuangxiao = sgs.CreateTriggerSkill {
    name = 'kuangxiao',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isYourFriend(player) and not use.to:contains(p) then
                    use.to:append(p)
                end
            end
            room:sortByActionOrder(use.to)
            data:setValue(use)
            room:sendCompulsoryTriggerLog(player, self:objectName())
        end
    end,
}
baihu:addSkill(kuangxiao)
---------------------------------------------------------------------------------------------------
ol_zhangbao = sgs.General(extension_sp, 'ol_zhangbao', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
ol_zhoufuCard = sgs.CreateSkillCard {
    name = 'ol_zhoufu',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
                   to_select:getPile('incantation'):isEmpty()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            targets[1]:addToPile('incantation', self)
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
ol_zhoufuVS = sgs.CreateOneCardViewAsSkill {
    name = 'ol_zhoufu',
    filter_pattern = '.|.|.|hand',
    view_as = function(self, cards)
        local card = ol_zhoufuCard:clone()
        card:addSubcard(cards)
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#ol_zhoufu')
    end,
}
ol_zhoufu = sgs.CreateTriggerSkill {
    name = 'ol_zhoufu',
    events = {sgs.StartJudge, sgs.EventPhaseChanging},
    view_as_skill = ol_zhoufuVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.StartJudge then
            if not player:getPile('incantation'):isEmpty() then
                local judge = data:toJudge()
                judge.card = sgs.Sanguosha:getCard(player:getPile('incantation'):first())
                room:moveCardTo(judge.card, nil, judge.who, sgs.Player_PlaceJudge, sgs.CardMoveReason(
                    sgs.CardMoveReason_S_REASON_JUDGE, judge.who:objectName(), self:objectName(), '', judge.reason), true)
                judge:updateResult()
                room:setTag('SkipGameRule', sgs.QVariant(true))
                room:addPlayerMark(player, self:objectName() .. '-Clear')
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    room:removePlayerMark(player,
                        self:objectName() .. player:getPile('incantation'):first() .. p:objectName())
                end
            end
        else
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(self:objectName() .. '-Clear') > 0 then
                        local target = room:findPlayerBySkillName(self:objectName())
                        if target then
                            room:addPlayerMark(target, self:objectName() .. 'engine')
                            if target:getMark(self:objectName() .. 'engine') > 0 then
                                room:loseHp(p)
                                room:removePlayerMark(target, self:objectName() .. 'engine')
                            end
                        else
                            room:loseHp(p)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_zhangbao:addSkill(ol_zhoufu)
ol_yingbing = sgs.CreateTriggerSkill {
    name = 'ol_yingbing',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            local response = data:toCardResponse()
            if response.m_isUse then
                card = response.m_card
            end
        end
        if card and card:getHandlingMethod() == sgs.Card_MethodUse and card:getSuit() ==
            sgs.Sanguosha:getCard(player:getPile('incantation'):first()):getSuit() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:sendCompulsoryTriggerLog(p, self:objectName())
                room:addPlayerMark(p, self:objectName() .. 'engine')
                if p:getMark(self:objectName() .. 'engine') > 0 then
                    p:drawCards(1, self:objectName())
                    room:addPlayerMark(player, self:objectName() .. player:getPile('incantation'):first() .. p:objectName())
                    if player:getMark(self:objectName() .. player:getPile('incantation'):first() .. p:objectName()) == 2 then
                        room:setPlayerMark(player,
                            self:objectName() .. player:getPile('incantation'):first() .. p:objectName(), 0)
                        room:throwCard(sgs.Sanguosha:getCard(player:getPile('incantation'):first()), sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, '', p:objectName(), self:objectName(), ''), nil)
                    end
                    room:removePlayerMark(p, self:objectName() .. 'engine')
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and not target:getPile('incantation'):isEmpty()
    end,
}
ol_zhangbao:addSkill(ol_yingbing)
ol_lingju = sgs.General(extension_sp, 'ol_lingju', 'qun', 3, false, sgs.GetConfig('hidden_ai', true))
ol_lingju:addSkill('jieyuan')
ol_fenxin = sgs.CreateTriggerSkill {
    name = 'ol_fenxin',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if death.who:objectName() ~= p:objectName() then
                room:addPlayerMark(p, self:objectName() .. 'engine')
                if p:getMark(self:objectName() .. 'engine') > 0 then
                    if death.who:getRole() == 'loyalist' then
                        room:setPlayerMark(p, '@fenxin1', 1)
                    elseif death.who:getRole() == 'rebel' then
                        room:setPlayerMark(p, '@fenxin2', 1)
                    elseif death.who:getRole() == 'renegade' then
                        room:setPlayerMark(p, '@fenxin3', 1)
                    end
                    room:removePlayerMark(p, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_lingju:addSkill(ol_fenxin)
ol_maliang = sgs.General(extension_sp, 'ol_maliang', 'shu', 3, true, sgs.GetConfig('hidden_ai', true))
zishu = sgs.CreateTriggerSkill {
    name = 'zishu',
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if event == sgs.CardsMoveOneTime and not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() ==
            player:objectName() then
            if player:getPhase() == sgs.Player_NotActive then
                for _, id in sgs.qlist(move.card_ids) do
                    if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) ==
                        sgs.Player_PlaceHand then
                        room:addPlayerMark(player, self:objectName() .. id)
                    end
                end
            elseif player:getPhase() ~= sgs.Player_NotActive and move.reason.m_skillName ~= 'zishu' and RIGHT(self, player) then
                for _, id in sgs.qlist(move.card_ids) do
                    if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) ==
                        sgs.Player_PlaceHand then
                        SendComLog(self, player, 1)
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            player:drawCards(1, self:objectName())
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                            break
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                for _, card in sgs.list(p:getHandcards()) do
                    if p:getMark(self:objectName() .. card:getEffectiveId()) > 0 then
                        dummy:addSubcard(card:getEffectiveId())
                    end
                end
                if dummy:subcardsLength() > 0 then
                    SendComLog(self, p, 2)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, p:objectName(),
                            self:objectName(), nil), p)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                    if player:getNextAlive():objectName() == p:objectName() then
                        room:getThread():delay(2500)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_maliang:addSkill(zishu)
yingyuan = sgs.CreateTriggerSkill {
    name = 'yingyuan',
    events = {sgs.CardsMoveOneTime, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local invoke = false
            for _, id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):hasFlag('yingyuan') then
                    invoke = true
                end
            end
            if move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile and
                bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE and
                (move.from and move.from:objectName() == player:objectName() or invoke) and player:getPhase() ~=
                sgs.Player_NotActive then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                for _, id in sgs.qlist(move.card_ids) do
                    if player:getMark(self:objectName() .. TrueName(sgs.Sanguosha:getCard(id):getClassName()) .. '-Clear') ==
                        0 then
                        dummy:addSubcard(id)
                        room:addPlayerMark(player, self:objectName() .. TrueName(sgs.Sanguosha:getCard(id):getClassName()) ..
                            '-Clear')
                    end
                end
                if dummy:subcardsLength() > 0 then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                        'yingyuan-invoke', true, true)
                    if target then
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            target:obtainCard(dummy)
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                end
            end
        else
            local use = data:toCardUse()
            if use.card:getClassName() == 'Nullification' then
                room:setCardFlag(use.card, 'yingyuan')
            end
        end
    end,
}
ol_maliang:addSkill(yingyuan)
ol_chenqun = sgs.General(extension_yijiang, 'ol_chenqun', 'wei', 3, true, sgs.GetConfig('hidden_ai', true))
pindiCard = sgs.CreateSkillCard {
    name = 'pindi',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark(self:objectName() .. '_Play') == 0 and to_select:objectName() ~=
                   sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:addPlayerMark(effect.from, self:objectName() .. 'from_Play')
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            local x = effect.from:getMark(self:objectName() .. 'from_Play')
            if effect.to:isNude() or room:askForChoice(effect.from, self:objectName(), 'pindi1+pindi2') == 'pindi1' then
                effect.to:drawCards(x, self:objectName())
            else
                room:askForDiscard(effect.to, self:objectName(), x, x, false, true)
            end
            room:addPlayerMark(effect.to, self:objectName() .. '_Play')
            room:addPlayerMark(effect.from,
                self:objectName() .. sgs.Sanguosha:getCard(self:getSubcards():first()):getTypeId() .. '_Play')
            if effect.to:isWounded() and not effect.from:isChained() then
                effect.from:setChained(true)
                room:broadcastProperty(effect.from, 'chained')
                room:setEmotion(effect.from, 'chain')
                room:getThread():trigger(sgs.ChainStateChanged, room, effect.from)
            end
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
pindi = sgs.CreateOneCardViewAsSkill {
    name = 'pindi',
    view_filter = function(self, card)
        return not card:isEquipped() and sgs.Self:getMark(self:objectName() .. card:getTypeId() .. '_Play') == 0
    end,
    view_as = function(self, card)
        local SkillCard = pindiCard:clone()
        SkillCard:addSubcard(card)
        return SkillCard
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, 'h')
    end,
}
ol_chenqun:addSkill(pindi)
ol_faen = sgs.CreateTriggerSkill {
    name = 'ol_faen',
    events = {sgs.TurnedOver, sgs.ChainStateChanged},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.ChainStateChanged and player:isChained()) or (event == sgs.TurnedOver and player:isFaceUp()) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        player:drawCards(1, self:objectName())
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ol_chenqun:addSkill(ol_faen)
beimihu = sgs.General(extension, 'beimihu', 'qun', 3, false, sgs.GetConfig('hidden_ai', true))
zongkui = sgs.CreateTriggerSkill {
    name = 'zongkui',
    events = {sgs.TurnStart, sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local players = sgs.SPlayerList()
        if event == sgs.TurnStart then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark('@puppet') == 0 then
                    players:append(p)
                end
            end
        else
            local n = player:getHp()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                n = math.min(n, p:getHp())
            end
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHp() == n and p:getMark('@puppet') == 0 then
                    players:append(p)
                end
            end
        end
        if not players:isEmpty() then
            local target = room:askForPlayerChosen(player, players, self:objectName(), 'zongkui-invoke',
                event == sgs.TurnStart, true)
            if target then
                if event == sgs.TurnStart then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                else
                    room:broadcastSkillInvoke(self:objectName(), 1)
                end
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    target:gainMark('@puppet')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
beimihu:addSkill(zongkui)
guju = sgs.CreateTriggerSkill {
    name = 'guju',
    events = {sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('@puppet') > 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                SendComLog(self, p)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    p:drawCards(1, self:objectName())
                    room:addPlayerMark(p, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
beimihu:addSkill(guju)
baijia = sgs.CreatePhaseChangeSkill {
    name = 'baijia',
    frequency = sgs.Skill_Wake,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and player:getMark('guju') >= 7 and player:getMark(self:objectName()) == 0 then
            SendComLog(self, player)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:addPlayerMark(player, self:objectName())
                if room:changeMaxHpForAwakenSkill(player, 1) then
                    room:recover(player, sgs.RecoverStruct(player))
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark('@puppet') == 0 then
                            p:gainMark('@puppet')
                        end
                    end
                    room:handleAcquireDetachSkills(player, '-guju|canshib')
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
beimihu:addSkill(baijia)
canshibCard = sgs.CreateSkillCard {
    name = 'canshib',
    filter = function(self, targets, to_select)
        return to_select:getMark(self:objectName()) == 0 and to_select:getMark('@puppet') > 0 and
                   sgs.Sanguosha:getCard(sgs.Self:getMark('card_id')):targetFilter(sgs.PlayerList(), to_select, sgs.Self)
    end,
    on_effect = function(self, effect)
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            effect.to:getRoom():addPlayerMark(effect.to, self:objectName())
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
canshibEXCard = sgs.CreateSkillCard {
    name = 'canshibEX',
    filter = function(self, targets, to_select)
        local coll = sgs.Card_Parse(sgs.Self:property('extra_collateral'):toString())
        if not coll then
            return false
        end
        local tos = sgs.Self:property('extra_collateral_current_targets'):toString():split('+')
        if #targets == 0 then
            return not table.contains(tos, to_select:objectName()) and not sgs.Self:isProhibited(to_select, coll) and
                       coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self) and to_select:getMark('@puppet') >
                       0
        else
            return coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
        end
    end,
    about_to_use = function(self, room, use)
        local killer = use.to:first()
        local victim = use.to:last()
        killer:setFlags('ExtraCollateralTarget')
        local _data = sgs.QVariant()
        _data:setValue(victim)
        killer:setTag('collateralVictim', _data)
    end,
}
canshibVS = sgs.CreateZeroCardViewAsSkill {
    name = 'canshib',
    response_pattern = '@@canshib',
    view_as = function()
        if sgs.Self:getMark('card_id') > 0 then
            return canshibCard:clone()
        else
            return canshibEXCard:clone()
        end
    end,
}
canshib = sgs.CreateTriggerSkill {
    name = 'canshib',
    view_as_skill = canshibVS,
    events = {sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.to:length() == 1 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if use.from:getMark('@puppet') > 0 and use.to:contains(p) and
                    room:askForSkillInvoke(p, self:objectName(), data) then
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        room:broadcastSkillInvoke(self:objectName())
                        use.from:loseMark('@puppet')
                        use.to:removeOne(p)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
                if use.from:objectName() == p:objectName() and
                    (not use.card:isKindOf('Collateral') and not use.card:isKindOf('SkillCard') and
                        not use.card:isKindOf('EquipCard') and not use.card:isKindOf('DelayedTrick')) then
                    for _, pe in sgs.qlist(use.to) do
                        room:addPlayerMark(pe, self:objectName())
                    end
                    room:setPlayerMark(p, 'card_id', use.card:getEffectiveId())
                    room:askForUseCard(p, '@@canshib', '@canshib')
                    room:setPlayerMark(p, 'card_id', 0)
                    for _, pe in sgs.qlist(room:getAllPlayers()) do
                        if pe:getMark(self:objectName()) > 0 and not room:isProhibited(p, pe, use.card) then
                            room:removePlayerMark(pe, self:objectName())
                            if not use.to:contains(pe) then
                                pe:loseMark('@puppet')
                                use.to:append(pe)
                            end
                        end
                    end
                elseif use.from:objectName() == p:objectName() and use.card:isKindOf('Collateral') then
                    for _ = 1, p:getMark('@luanz') do
                        local targets = sgs.SPlayerList()
                        for _, pe in sgs.qlist(room:getAlivePlayers()) do
                            if (use.to:contains(pe) or room:isProhibited(p, pe, use.card)) then
                                goto next_pe
                            end
                            if use.card:targetFilter(sgs.PlayerList(), pe, p) and pe:getMark('@puppet') > 0 then
                                targets:append(pe)
                            end
                            ::next_pe::
                        end
                        if not targets:isEmpty() then
                            local tos = {}
                            for _, t in sgs.qlist(use.to) do
                                table.insert(tos, t:objectName())
                            end
                            room:setPlayerProperty(p, 'extra_collateral', sgs.QVariant(use.card:toString()))
                            room:setPlayerProperty(p, 'extra_collateral_current_targets',
                                sgs.QVariant(table.concat(tos, '+')))
                            local used = room:askForUseCard(p, '@@ExtraCollateral', '@qiaoshui-add:::collateral')
                            room:setPlayerProperty(p, 'extra_collateral', sgs.QVariant(''))
                            room:setPlayerProperty(p, 'extra_collateral_current_targets', sgs.QVariant('+'))
                            if used then
                                local extra
                                for _, pe in sgs.qlist(room:getOtherPlayers(p)) do
                                    if pe:hasFlag('ExtraCollateralTarget') then
                                        pe:setFlags('-ExtraColllateralTarget')
                                        extra = pe
                                        break
                                    end
                                end
                                if extra then
                                    extra:loseMark('@puppet')
                                    use.to:append(extra)
                                end
                            end
                        end
                    end
                end
                room:sortByActionOrder(use.to)
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill('canshib') then
    skills:append(canshib)
end
beimihu:addRelateSkill('canshib')
ol_zhuhuan = sgs.General(extension_yijiang, 'ol_zhuhuan', 'wu', 4, true, sgs.GetConfig('hidden_ai', true))
fenli = sgs.CreateTriggerSkill {
    name = 'fenli',
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        local hp, hand, equip = true, true, player:hasEquip()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() > player:getHandcardNum() then
                hp = false
            end
            if p:getHp() > player:getHp() then
                hand = false
            end
            if p:getEquips():length() > player:getEquips():length() then
                equip = false
            end
        end
        if not player:isSkipped(change.to) and
            ((hp and change.to == sgs.Player_Draw) or (hand and change.to == sgs.Player_Play) or
                (equip and change.to == sgs.Player_Discard)) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:skip(change.to)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
ol_zhuhuan:addSkill(fenli)
pingkouCard = sgs.CreateSkillCard {
    name = 'pingkou',
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark(self:objectName() .. '-Clear') and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
pingkouVS = sgs.CreateZeroCardViewAsSkill {
    name = 'pingkou',
    response_pattern = '@@pingkou',
    view_as = function(self, card)
        return pingkouCard:clone()
    end,
}
pingkou = sgs.CreateTriggerSkill {
    name = 'pingkou',
    view_as_skill = pingkouVS,
    events = {sgs.EventPhaseChanging, sgs.EventPhaseSkipping},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive and
            player:getMark(self:objectName() .. '-Clear') > 0 then
            room:askForUseCard(player, '@@pingkou', '@pingkou', -1, sgs.Card_MethodUse)
        elseif event == sgs.EventPhaseSkipping then
            room:addPlayerMark(player, self:objectName() .. '-Clear')
        end
    end,
}
ol_zhuhuan:addSkill(pingkou)
luzhi = sgs.General(extension, 'luzhi', 'wei', 3, true, sgs.GetConfig('hidden_ai', true))
qingzhong = sgs.CreateTriggerSkill {
    name = 'qingzhong',
    global = true,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and RIGHT(self, player) and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), 1)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:drawCards(2, self:objectName())
                room:addPlayerMark(player, self:objectName() .. '_replay')
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and
            player:getMark(self:objectName() .. '_replay') > 0 then
            local players = sgs.SPlayerList()
            local n = player:getHandcardNum()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                n = math.min(p:getHandcardNum(), n)
            end
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() == n then
                    players:append(p)
                end
            end
            if not players:isEmpty() then
                local target = room:askForPlayerChosen(player, players, self:objectName(), 'qingzhong-invoke',
                    player:getHandcardNum() == n, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    local exchangeMove = sgs.CardsMoveList()
                    exchangeMove:append(sgs.CardsMoveStruct(player:handCards(), target, sgs.Player_PlaceHand,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(),
                            self:objectName(), '')))
                    exchangeMove:append(sgs.CardsMoveStruct(target:handCards(), player, sgs.Player_PlaceHand,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(),
                            self:objectName(), '')))
                    room:moveCardsAtomic(exchangeMove, false)
                end
            end
        end
    end,
}
luzhi:addSkill(qingzhong)
weijingVS = sgs.CreateZeroCardViewAsSkill {
    name = 'weijing',
    view_as = function(self)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern ~= 'jink' then
            pattern = 'slash'
        end
        local cards = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
        cards:setSkillName(self:objectName())
        return cards
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getMark(self:objectName() .. '_lun') == 0
    end,
    enabled_at_response = function(self, player, pattern)
        return (pattern == 'slash' or pattern == 'jink') and player:getMark(self:objectName() .. '_lun') == 0 and
                   sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
    end,
}
weijing = sgs.CreateTriggerSkill {
    name = 'weijing',
    view_as_skill = weijingVS,
    events = {sgs.PreCardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.PreCardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and card:getSkillName() == self:objectName() then
            room:addPlayerMark(player, self:objectName() .. '_lun')
        end
    end,
}
luzhi:addSkill(weijing)
simahui = sgs.General(extension, 'simahui', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
jianjieCard = sgs.CreateSkillCard {
    name = 'jianjie',
    filter = function(self, targets, to_select)
        if sgs.Self:getMark(self:objectName()) > 0 then
            if sgs.Self:getMark(self:objectName()) == 3 then
                return #targets < 2
            else
                return #targets == 0
            end
        elseif sgs.Self:getMark('turn') == 1 then
            return #targets < 2
        else
            if (#targets == 0 and to_select:getMark('@dragon') > 0) or (#targets == 1 and to_select:getMark('@dragon') == 0) then
                return true
            elseif (#targets == 0 and to_select:getMark('@phoenix') > 0) or
                (#targets == 1 and to_select:getMark('@phoenix') == 0) then
                return true
            end
        end
        return false
    end,
    feasible = function(self, targets)
        if sgs.Self:getMark(self:objectName()) == 0 then
            return #targets == 2
        end
        return #targets < 3
    end,
    about_to_use = function(self, room, use)
        room:addPlayerMark(use.from, self:objectName() .. 'engine')
        if use.from:getMark(self:objectName() .. 'engine') > 0 then
            if use.from:getMark(self:objectName()) > 0 then
                if use.from:getMark(self:objectName()) == 3 then
                    if use.to:last() then
                        use.to:first():gainMark('@dragon')
                        use.to:last():gainMark('@phoenix')
                    else
                        use.to:first():gainMark('@dragon')
                        use.to:first():gainMark('@phoenix')
                    end
                else
                    if use.from:getMark(self:objectName()) == 1 then
                        use.to:first():gainMark('@dragon')
                    else
                        use.to:first():gainMark('@phoenix')
                    end
                end
            elseif use.from:getMark('turn') == 1 then
                use.to:first():gainMark('@dragon')
                use.to:last():gainMark('@phoenix')
            else
                local choices = {}
                if use.to:first():getMark('@dragon') > 0 then
                    table.insert(choices, 'dragon_move')
                end
                if use.to:first():getMark('@phoenix') > 0 then
                    table.insert(choices, 'phoenix_move')
                end
                local choice = room:askForChoice(use.from, self:objectName(), table.concat(choices, '+'))
                if choice == 'dragon_move' then
                    use.to:first():loseMark('@dragon')
                    use.to:last():gainMark('@dragon')
                else
                    use.to:first():loseMark('@phoenix')
                    use.to:last():gainMark('@phoenix')
                end
            end
            local together
            for _, p in sgs.qlist(use.to) do
                if p:getMark('@dragon') > 0 and p:getMark('@phoenix') > 0 then
                    together = true
                end
            end
            -- 判断是否同时拥有龙凤印
            local index = together and 3 or rinsan.random(1, 2)
            room:broadcastSkillInvoke('jianjie', index)
            room:removePlayerMark(use.from, self:objectName() .. 'engine')
        end
    end,
}
jianjieVS = sgs.CreateZeroCardViewAsSkill {
    name = 'jianjie',
    response_pattern = '@@jianjie',
    view_as = function(self)
        return jianjieCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('turn') > 1 and not player:hasUsed('#jianjie')
    end,
}
jianjie = sgs.CreateTriggerSkill {
    name = 'jianjie',
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.Death},
    view_as_skill = jianjieVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and RIGHT(self, player) and
                player:getMark('first_' .. self:objectName()) == 0 then
                room:askForUseCard(player, '@@jianjie', '@jianjie')
                room:addPlayerMark(player, 'first_' .. self:objectName())
            end
        elseif event == sgs.GameStart then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if not p:hasSkill('jianjievs') then
                    room:attachSkillToPlayer(p, 'jianjievs')
                end
            end
        else
            local death = data:toDeath()
            local players = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if (death.who:getMark('@dragon') > 0 and p:getMark('@dragon') == 0) or
                    (death.who:getMark('@phoenix') > 0 and p:getMark('@phoenix') == 0) then
                    players:append(p)
                end
            end
            if death.who:objectName() == player:objectName() and not players:isEmpty() then
                if death.who:getMark('@dragon') > 0 then
                    room:addPlayerMark(player, self:objectName())
                end
                if death.who:getMark('@phoenix') > 0 then
                    room:addPlayerMark(player, self:objectName(), 2)
                end
                room:askForUseCard(player, '@@jianjie', '@jianjie')
                room:setPlayerMark(player, self:objectName(), 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
simahui:addSkill(jianjie)
chenghao = sgs.CreateTriggerSkill {
    name = 'chenghao',
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        local n = 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isChained() then
                n = n + 1
            end
        end
        if mark.name == self:objectName() and mark.gain > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                local _guojia = sgs.SPlayerList()
                _guojia:append(player)
                local yiji_cards = room:getNCards(n, false)
                local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, _guojia)
                room:notifyMoveCards(false, moves, false, _guojia)
                local origin_yiji = sgs.IntList()
                for _, id in sgs.qlist(yiji_cards) do
                    origin_yiji:append(id)
                end
                while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
                    local _move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand,
                        sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(),
                            self:objectName(), nil))
                    for _, id in sgs.qlist(origin_yiji) do
                        if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                            _move.card_ids:append(id)
                            yiji_cards:removeOne(id)
                        end
                    end
                    origin_yiji = sgs.IntList()
                    for _, id in sgs.qlist(yiji_cards) do
                        origin_yiji:append(id)
                    end
                    local _moves = sgs.CardsMoveList()
                    _moves:append(_move)
                    room:notifyMoveCards(true, _moves, false, _guojia)
                    room:notifyMoveCards(false, _moves, false, _guojia)
                    if not player:isAlive() then
                        return
                    end
                end
                if not yiji_cards:isEmpty() then
                    local _move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                    local _moves = sgs.CardsMoveList()
                    _moves:append(_move)
                    room:notifyMoveCards(true, _moves, false, _guojia)
                    room:notifyMoveCards(false, _moves, false, _guojia)
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    for _, id in sgs.qlist(yiji_cards) do
                        dummy:addSubcard(id)
                    end
                    player:obtainCard(dummy, false)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
simahui:addSkill(chenghao)
yinshi = sgs.CreateTriggerSkill {
    name = 'yinshi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
    end,
}
simahui:addSkill(yinshi)
pangdegong = sgs.General(extension_mobile, 'pangdegong', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
pingcai_wolongCard = sgs.CreateSkillCard {
    name = 'pingcai_wolong',
    filter = function(self, targets, to_select)
        local invoke = string.find(sgs.Sanguosha:translate(sgs.Self:getGeneralName()) .. '&' ..
                                       sgs.Sanguosha:translate(sgs.Self:getGeneral2Name()), sgs.Sanguosha:translate('wolong'))
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            if not invoke then
                invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()) .. '&' ..
                                         sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate('wolong'))
            end
        end
        if invoke then
            return #targets < 2
        else
            return #targets == 0
        end
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('pingcai', 2)
        for _, p in pairs(targets) do
            room:damage(sgs.DamageStruct('pingcai', source, p, 1, sgs.DamageStruct_Fire))
        end
        if source:hasSkill('pingcai_wolong') then
            room:detachSkillFromPlayer(source, 'pingcai_wolong', true)
        end
        if source:hasSkill('pingcai_fengchu') then
            room:detachSkillFromPlayer(source, 'pingcai_fengchu', true)
        end
        if source:hasSkill('pingcai_shuijing') then
            room:detachSkillFromPlayer(source, 'pingcai_shuijing', true)
        end
        if source:hasSkill('pingcai_xuanjian') then
            room:detachSkillFromPlayer(source, 'pingcai_xuanjian', true)
        end
    end,
}
pingcai_wolong = sgs.CreateZeroCardViewAsSkill {
    name = 'pingcai_wolong&',
    view_as = function(self)
        return pingcai_wolongCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:hasUsed('#pingcai') and not player:hasUsed('#pingcai_wolong')
    end,
}
if not sgs.Sanguosha:getSkill('pingcai_wolong') then
    skills:append(pingcai_wolong)
end
pingcai_fengchuCard = sgs.CreateSkillCard {
    name = 'pingcai_fengchu',
    filter = function(self, targets, to_select)
        local invoke = string.find(sgs.Sanguosha:translate(sgs.Self:getGeneralName()) .. '&' ..
                                       sgs.Sanguosha:translate(sgs.Self:getGeneral2Name()),
            sgs.Sanguosha:translate('pangtong'))
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            if not invoke then
                invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()) .. '&' ..
                                         sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate('pangtong'))
            end
        end
        if invoke then
            return #targets < 4
        else
            return #targets < 3
        end
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('pingcai', 3)
        for _, p in pairs(targets) do
            p:setChained(true)
            room:broadcastProperty(p, 'chained')
            room:setEmotion(p, 'chain')
            room:getThread():trigger(sgs.ChainStateChanged, room, p)
        end
        if source:hasSkill('pingcai_wolong') then
            room:detachSkillFromPlayer(source, 'pingcai_wolong', true)
        end
        if source:hasSkill('pingcai_fengchu') then
            room:detachSkillFromPlayer(source, 'pingcai_fengchu', true)
        end
        if source:hasSkill('pingcai_shuijing') then
            room:detachSkillFromPlayer(source, 'pingcai_shuijing', true)
        end
        if source:hasSkill('pingcai_xuanjian') then
            room:detachSkillFromPlayer(source, 'pingcai_xuanjian', true)
        end
    end,
}
pingcai_fengchu = sgs.CreateZeroCardViewAsSkill {
    name = 'pingcai_fengchu&',
    view_as = function(self)
        return pingcai_fengchuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:hasUsed('#pingcai') and not player:hasUsed('#pingcai_fengchu')
    end,
}
if not sgs.Sanguosha:getSkill('pingcai_fengchu') then
    skills:append(pingcai_fengchu)
end
pingcai_shuijingCard = sgs.CreateSkillCard {
    name = 'pingcai_shuijing',
    filter = function(self, targets, to_select)
        local invoke = string.find(sgs.Sanguosha:translate(sgs.Self:getGeneralName()) .. '&' ..
                                       sgs.Sanguosha:translate(sgs.Self:getGeneral2Name()),
            sgs.Sanguosha:translate('simahui'))
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            if not invoke then
                invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()) .. '&' ..
                                         sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate('simahui'))
            end
        end
        if #targets == 1 then
            if invoke then
                for _, card in sgs.qlist(targets[1]:getEquips()) do
                    if not (to_select:getEquip(card:getRealCard():toEquipCard():location())) and
                        to_select:hasEquipArea(card:getRealCard():toEquipCard():location()) then
                        return true
                    end
                end
            else
                return not to_select:getArmor()
            end
        elseif #targets == 0 then
            if invoke then
                return to_select:hasEquip()
            else
                return to_select:getArmor() and to_select:getArmor():getEffectiveId() ~= -1 and to_select:hasEquipArea(1)
            end
        end
        return false
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, use)
        room:broadcastSkillInvoke('pingcai', 4)
        local equiplist = {}
        for i = 0, 4, 1 do
            if use.to:first():getEquip(i) then
                if use.to:at(1):getEquip(i) == nil then
                    table.insert(equiplist, 'shuijing_' .. tostring(i))
                end
            end
        end
        if #equiplist == nil then
            return false
        end
        local _data = sgs.QVariant()
        _data:setValue(use.to:first())
        local x = 'shuijing_1'
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if string.find(
                sgs.Sanguosha:translate(p:getGeneralName()) .. '&' .. sgs.Sanguosha:translate(p:getGeneral2Name()),
                sgs.Sanguosha:translate('simahui')) then
                x = room:askForChoice(use.from, 'pingcai_shuijing', table.concat(equiplist, '+'), _data)
                break
            end
        end
        local card = use.to:first():getEquip(tonumber(string.sub(x, string.len(x), string.len(x))))
        if card then
            room:moveCardTo(card, use.to:at(1), sgs.Player_PlaceEquip)
        end
        if use.from:hasSkill('pingcai_wolong') then
            room:detachSkillFromPlayer(use.from, 'pingcai_wolong', true)
        end
        if use.from:hasSkill('pingcai_fengchu') then
            room:detachSkillFromPlayer(use.from, 'pingcai_fengchu', true)
        end
        if use.from:hasSkill('pingcai_shuijing') then
            room:detachSkillFromPlayer(use.from, 'pingcai_shuijing', true)
        end
        if use.from:hasSkill('pingcai_xuanjian') then
            room:detachSkillFromPlayer(use.from, 'pingcai_xuanjian', true)
        end
    end,
}
pingcai_shuijing = sgs.CreateZeroCardViewAsSkill {
    name = 'pingcai_shuijing&',
    view_as = function()
        return pingcai_shuijingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:hasUsed('#pingcai') and not player:hasUsed('#pingcai_shuijing')
    end,
}
if not sgs.Sanguosha:getSkill('pingcai_shuijing') then
    skills:append(pingcai_shuijing)
end
pingcai_xuanjianCard = sgs.CreateSkillCard {
    name = 'pingcai_xuanjian',
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke('pingcai', 5)
        local invoke = false
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not invoke then
                invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()) .. '&' ..
                                         sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate('xushu'))
            end
        end
        targets[1]:drawCards(1, self:objectName())
        targets[1]:getRoom():recover(targets[1], sgs.RecoverStruct(source))
        if invoke then
            source:drawCards(1, self:objectName())
        end
        if source:hasSkill('pingcai_wolong') then
            room:detachSkillFromPlayer(source, 'pingcai_wolong', true)
        end
        if source:hasSkill('pingcai_fengchu') then
            room:detachSkillFromPlayer(source, 'pingcai_fengchu', true)
        end
        if source:hasSkill('pingcai_shuijing') then
            room:detachSkillFromPlayer(source, 'pingcai_shuijing', true)
        end
        if source:hasSkill('pingcai_xuanjian') then
            room:detachSkillFromPlayer(source, 'pingcai_xuanjian', true)
        end
    end,
}
pingcai_xuanjian = sgs.CreateZeroCardViewAsSkill {
    name = 'pingcai_xuanjian&',
    view_as = function(self)
        return pingcai_xuanjianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:hasUsed('#pingcai') and not player:hasUsed('#pingcai_xuanjian')
    end,
}
if not sgs.Sanguosha:getSkill('pingcai_xuanjian') then
    skills:append(pingcai_xuanjian)
end
pingcaiCard = sgs.CreateSkillCard {
    name = 'pingcai',
    target_fixed = true,
    about_to_use = function(self, room, use)
        room:addPlayerMark(use.from, self:objectName() .. 'engine')
        if use.from:getMark(self:objectName() .. 'engine') > 0 then
            room:broadcastSkillInvoke(self:objectName(), 1)
            room:getThread():delay(3820)
            if not use.from:hasSkill('pingcai_wolong') then
                room:attachSkillToPlayer(use.from, 'pingcai_wolong')
            end
            room:getThread():delay(1053)
            if not use.from:hasSkill('pingcai_fengchu') then
                room:attachSkillToPlayer(use.from, 'pingcai_fengchu')
            end
            room:getThread():delay(1351)
            if not use.from:hasSkill('pingcai_shuijing') then
                room:attachSkillToPlayer(use.from, 'pingcai_shuijing')
            end
            room:getThread():delay(1147)
            if not use.from:hasSkill('pingcai_xuanjian') then
                room:attachSkillToPlayer(use.from, 'pingcai_xuanjian')
            end
            room:removePlayerMark(use.from, self:objectName() .. 'engine')
        end
    end,
}
pingcai = sgs.CreateZeroCardViewAsSkill {
    name = 'pingcai',
    view_as = function(self)
        return pingcaiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#pingcai')
    end,
}
pangdegong:addSkill(pingcai)
yinship = sgs.CreateTriggerSkill {
    name = 'yinship',
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if not player:isSkipped(change.to) and
            (change.to == sgs.Player_Start or change.to == sgs.Player_Judge or change.to == sgs.Player_Finish) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:skip(change.to)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
pangdegong:addSkill(yinship)
wangji = sgs.General(extension_yin, 'wangji', 'wei', 3)
qizhi = sgs.CreateTriggerSkill {
    name = 'qizhi',
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:getPhase() ~= sgs.Player_NotActive and (use.card:isKindOf('TrickCard') or use.card:isKindOf('BasicCard')) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if not use.to:contains(p) then
                    targets:append(p)
                end
            end
            if targets:length() > 0 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), 'qizhi-invoke', true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, '@qizhi-Clear')
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if player:canDiscard(target, 'he') then
                            local id = room:askForCardChosen(player, target, 'he', self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            room:throwCard(id, target, player)
                            target:drawCards(1, self:objectName())
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                end
            end
        end
        return false
    end,
}
wangji:addSkill(qizhi)
jinqu = sgs.CreateTriggerSkill {
    name = 'jinqu',
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:drawCards(2, self:objectName())
                local n = player:getHandcardNum() - player:getMark('@qizhi-Clear')
                if n > 0 then
                    room:askForDiscard(player, self:objectName(), n, n)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
wangji:addSkill(jinqu)
kuaiyuekuailiang = sgs.General(extension_yin, 'kuaiyuekuailiang', 'wei', 3, true, sgs.GetConfig('hidden_ai', true))
jianxiang = sgs.CreateTriggerSkill {
    name = 'jianxiang',
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from:objectName() ~= player:objectName() and use.to:contains(player) and not use.card:isKindOf('SkillCard') then
            local n = room:getAlivePlayers():first():getHandcardNum()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                n = math.min(n, p:getHandcardNum())
            end
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() == n then
                    targets:append(p)
                end
            end
            local to = room:askForPlayerChosen(player, targets, self:objectName(), 'jianxiang-invoke', true, true)
            if to then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    to:drawCards(1, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
kuaiyuekuailiang:addSkill(jianxiang)
shenshiCard = sgs.CreateSkillCard {
    name = 'shenshi',
    will_throw = false,
    filter = function(self, targets, to_select)
        local n = 0
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            n = math.max(n, p:getHandcardNum())
        end
        local m = 0
        if not sgs.Sanguosha:getCard(self:getSubcards():first()):isEquipped() then
            m = m + 1
        end
        n = math.max(n, sgs.Self:getHandcardNum() - m)
        return #targets == 0 and to_select:getHandcardNum() == n and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        ChangeSkill(self, room, source)
        room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
            targets[1]:objectName(), self:objectName(), ''), false)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
            if room:getTag('shenshi'):toBool() then
                room:setTag('shenshi', sgs.QVariant(false))
                local targets_list = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    targets_list:append(p)
                end
                if targets_list:isEmpty() then
                    return false
                end
                local to = room:askForPlayerChosen(source, targets_list, self:objectName(), 'shenshi-invoke', true)
                if to and to:getHandcardNum() < 4 then
                    to:drawCards(4 - to:getHandcardNum(), self:objectName())
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
shenshiVS = sgs.CreateOneCardViewAsSkill {
    name = 'shenshi',
    filter_pattern = '.',
    view_as = function(self, card)
        local first = shenshiCard:clone()
        first:addSubcard(card:getId())
        first:setSkillName(self:objectName())
        return first
    end,
    enabled_at_play = function(self, player)
        return player:getMark(self:objectName()) ~= 1 and not player:hasUsed('#shenshi')
    end,
}
shenshi = sgs.CreateTriggerSkill {
    name = 'shenshi',
    view_as_skill = shenshiVS,
    frequency = sgs.Skill_Change,
    events = {sgs.Death, sgs.Damage, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if event == sgs.Death then
                local death = data:toDeath()
                if death.who:objectName() == player:objectName() and death.damage.reason and death.damage.reason ==
                    self:objectName() then
                    room:setTag(self:objectName(), sgs.QVariant(true))
                end
            elseif event == sgs.Damage then
                local damage = data:toDamage()
                if p and damage.to:objectName() == p:objectName() and p:getMark(self:objectName()) == 1 and damage.from and
                    damage.from:objectName() ~= p:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
                    ChangeSkill(self, room, p)
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        room:showAllCards(damage.from, p)
                        if not p:isNude() then
                            local card = room:askForCard(p, '..!', '@shenshi_give:' .. damage.from:objectName(), data,
                                sgs.Card_MethodNone, nil, false, self:objectName())
                            room:moveCardTo(card, damage.from, sgs.Player_PlaceHand, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), damage.from:objectName(),
                                self:objectName(), ''))
                            room:setPlayerMark(damage.from, self:objectName() .. card:getEffectiveId() .. '-Clear', 1)
                        end
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            else
                if p and data:toPhaseChange().to == sgs.Player_NotActive then
                    for _, pe in sgs.qlist(room:getOtherPlayers(p)) do
                        for _, mark in sgs.list(pe:getMarkNames()) do
                            if string.find(mark, self:objectName()) and pe:getMark(mark) > 0 then
                                for _, card in sgs.list(pe:getCards('he')) do
                                    if mark == self:objectName() .. card:getEffectiveId() .. '-Clear' and p:getHandcardNum() <
                                        4 then
                                        p:drawCards(4 - p:getHandcardNum(), self:objectName())
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
kuaiyuekuailiang:addSkill(shenshi)
yanyan = sgs.General(extension_yin, 'yanyan', 'shu', 4, true, sgs.GetConfig('hidden_ai', true))
juzhan = sgs.CreateTriggerSkill {
    name = 'juzhan',
    frequency = sgs.Skill_Change,
    events = {sgs.TargetConfirmed, sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local _data = sgs.QVariant()
        if event == sgs.TargetConfirmed then
            _data:setValue(use.from)
            if use.card:isKindOf('Slash') and player:getMark(self:objectName()) ~= 1 and use.from and use.to:contains(player) and
                use.from:objectName() ~= player:objectName() and room:askForSkillInvoke(player, self:objectName(), _data) then
                ChangeSkill(self, room, player)
                room:broadcastSkillInvoke(self:objectName(), 2)
                local players = sgs.SPlayerList()
                players:append(player)
                players:append(use.from)
                room:sortByActionOrder(players)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:drawCards(players, 1, self:objectName())
                    room:addPlayerMark(use.from, 'juzhanFrom-Clear')
                    room:addPlayerMark(player, 'juzhanTo-Clear')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        else
            for _, p in sgs.qlist(use.to) do
                _data:setValue(p)
                if use.card:isKindOf('Slash') and player:getMark(self:objectName()) == 1 and not p:isNude() and
                    room:askForSkillInvoke(player, self:objectName(), _data) then
                    ChangeSkill(self, room, player)
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local id = room:askForCardChosen(player, p, 'he', self:objectName())
                        if id ~= -1 then
                            room:obtainCard(player, id, false)
                            room:addPlayerMark(player, 'juzhanFrom-Clear')
                            room:addPlayerMark(p, 'juzhanTo-Clear')
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
yanyan:addSkill(juzhan)
wangping = sgs.General(extension_yin, 'wangping', 'shu', 4, true, sgs.GetConfig('hidden_ai', true))
feijunCard = sgs.CreateSkillCard {
    name = 'feijun',
    filter = function(self, targets, to_select)
        local n, m = 0, 0
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isEquipped() then
            m = 1
        else
            n = 1
        end
        return #targets == 0 and
                   (to_select:getHandcardNum() > sgs.Self:getHandcardNum() - n or to_select:getEquips():length() >
                       sgs.Self:getEquips():length() - m) and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        local choices = {}
        if targets[1]:getHandcardNum() > source:getHandcardNum() then
            table.insert(choices, 'feijun1')
        end
        if targets[1]:getEquips():length() > source:getEquips():length() then
            table.insert(choices, 'feijun2')
        end
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            if targets[1]:getMark(self:objectName() .. source:objectName()) == 0 then
                room:addPlayerMark(source, 'binglve')
                room:setPlayerMark(targets[1], '@binglve', 1)
                room:addPlayerMark(targets[1], self:objectName() .. source:objectName())
            end
            local choice = room:askForChoice(source, self:objectName(), table.concat(choices, '+'))
            ChoiceLog(source, choice)
            if choice == 'feijun1' then
                local card = room:askForCard(targets[1], '.!', '@feijun_give', sgs.QVariant(), sgs.Card_MethodNone)
                if card then
                    room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                        targets[1]:objectName(), source:objectName(), self:objectName(), ''))
                end
            else
                local card = room:askForCard(targets[1], '.|.|.|equipped!', '@feijun_throw', sgs.QVariant(),
                    sgs.Card_MethodNone)
                if card then
                    room:throwCard(card, targets[1], source)
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
feijun = sgs.CreateOneCardViewAsSkill {
    name = 'feijun',
    filter_pattern = '.',
    view_as = function(self, card)
        local cards = feijunCard:clone()
        cards:addSubcard(card)
        return cards
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#feijun')
    end,
}
wangping:addSkill(feijun)
binglve = sgs.CreateTriggerSkill {
    name = 'binglve',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == self:objectName() and mark.gain == -1 then
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(2, self:objectName())
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
wangping:addSkill(binglve)
luji = sgs.General(extension_yin, 'luji', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
huaiju = sgs.CreateTriggerSkill {
    name = 'huaiju',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.DamageInflicted, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if event == sgs.GameStart then
                if player:objectName() == p:objectName() then
                    SendComLog(self, p, 1)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        p:gainMark('@orange', 3)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            elseif event == sgs.DamageInflicted then
                if player:getMark('@orange') > 0 then
                    SendComLog(self, p, 2)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        player:loseMark('@orange')
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                    return true
                end
            else
                if player:getMark('@orange') > 0 then
                    SendComLog(self, p, 1)
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        data:setValue(data:toInt() + 1)
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
luji:addSkill(huaiju)
yili = sgs.CreatePhaseChangeSkill {
    name = 'yili',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Play then
            room:broadcastSkillInvoke(self:objectName())
            local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'yili-invoke', true,
                true)
            if to then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local choiceList = {'yili1'}
                    if player:getMark('@orange') > 0 then
                        table.insert(choiceList, 'yili2')
                    end
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choiceList, '+'))
                    ChoiceLog(player, choice)
                    room:broadcastSkillInvoke(self:objectName())
                    if choice == 'yili1' then
                        room:loseHp(player)
                    else
                        player:loseMark('@orange')
                    end
                    to:gainMark('@orange')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
luji:addSkill(yili)
zhenglun = sgs.CreateTriggerSkill {
    name = 'zhenglun',
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) and player:getMark('@orange') == 0 and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:skip(sgs.Player_Draw)
                player:gainMark('@orange')
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
luji:addSkill(zhenglun)
sunliang = sgs.General(extension_yin, 'sunliang$', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
kuizhuCard = sgs.CreateSkillCard {
    name = 'kuizhu',
    filter = function(self, targets, to_select)
        local n = sgs.Self:getMark(self:objectName())
        for i = 1, #targets do
            n = n - targets[i]:getHp()
        end
        return #targets < sgs.Self:getMark(self:objectName()) or to_select:getHp() <= n
    end,
    feasible = function(self, targets)
        local sum = 0
        for i = 1, #targets do
            sum = sum + targets[i]:getHp()
        end
        return #targets > 0 and #targets <= sgs.Self:getMark(self:objectName()) or sum == sgs.Self:getMark(self:objectName())
    end,
    on_use = function(self, room, source, targets)
        local sum = 0
        for _, p in pairs(targets) do
            sum = sum + p:getHp()
        end
        local choices = {}
        if #targets <= source:getMark(self:objectName()) then
            table.insert(choices, 'kuizhu1')
        end
        if sum == source:getMark(self:objectName()) then
            table.insert(choices, 'kuizhu2')
        end
        local choice = room:askForChoice(source, self:objectName(), table.concat(choices, '+'))
        ChoiceLog(source, choice)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            for _, p in pairs(targets) do
                if choice == 'kuizhu1' then
                    p:drawCards(1, self:objectName())
                else
                    room:damage(sgs.DamageStruct(self:objectName(), source, p))
                end
            end
            if choice == 'kuizhu2' and #targets >= 2 then
                room:damage(sgs.DamageStruct(self:objectName(), source, source))
            end
            room:setPlayerMark(source, self:objectName(), 0)
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
kuizhuVS = sgs.CreateZeroCardViewAsSkill {
    name = 'kuizhu',
    view_as = function(self, cards)
        return kuizhuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@@kuizhu')
    end,
}
kuizhu = sgs.CreateTriggerSkill {
    name = 'kuizhu',
    view_as_skill = kuizhuVS,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Discard then
            if event == sgs.CardsMoveOneTime then
                local move = data:toMoveOneTime()
                if move.from and move.from:objectName() == player:objectName() and
                    bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                    sgs.CardMoveReason_S_REASON_DISCARD then
                    room:addPlayerMark(player, self:objectName(), move.card_ids:length())
                end
            else
                if player:getMark(self:objectName()) > 0 then
                    room:askForUseCard(player, '@@kuizhu', '@kuizhu', -1, sgs.Card_MethodUse)
                end
            end
        end
        return false
    end,
}
sunliang:addSkill(kuizhu)
chezheng = sgs.CreateTriggerSkill {
    name = 'chezheng',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseEnd, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Play then
            return false
        end
        if event == sgs.EventPhaseEnd then
            local count, targets = 0, sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:inMyAttackRange(player) then
                    count = count + 1
                    if player:canDiscard(p, 'he') then
                        targets:append(p)
                    end
                end
            end
            if not targets:isEmpty() and player:getMark('used_Play') < count then
                local to = room:askForPlayerChosen(player, targets, self:objectName(), 'chezheng-invoke', false, true)
                room:broadcastSkillInvoke(self:objectName())
                if to then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local id = room:askForCardChosen(player, to, 'he', self:objectName(), false, sgs.Card_MethodDiscard)
                        room:throwCard(id, to, player)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
chezhengPro = sgs.CreateProhibitSkill {
    name = '#chezhengPro',
    is_prohibited = function(self, from, to, card)
        return from:hasSkill(self:objectName()) and from:getPhase() == sgs.Player_Play and not to:inMyAttackRange(from) and
                   from:objectName() ~= to:objectName() and not card:isKindOf('SkillCard')
    end,
}
sunliang:addSkill(chezheng)
sunliang:addSkill(chezhengPro)
lijun = sgs.CreateTriggerSkill {
    name = 'lijun$',
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local card = data:toCardUse().card
        if card and card:isKindOf('Slash') and room:getCardPlace(card:getEffectiveId()) == sgs.Player_DiscardPile then
            local sunliangs = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasLordSkill(self:objectName()) then
                    sunliangs:append(p)
                end
            end
            if not sunliangs:isEmpty() then
                local _data = sgs.QVariant()
                for _, p in sgs.qlist(sunliangs) do
                    _data:setValue(p)
                    if room:askForSkillInvoke(player, self:objectName(), _data) then
                        room:obtainCard(p, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                            p:objectName(), self:objectName(), ''), false)
                        _data:setValue(player)
                        if room:askForSkillInvoke(p, self:objectName(), _data) then
                            room:addPlayerMark(player, self:objectName() .. 'engine')
                            if player:getMark(self:objectName() .. 'engine') > 0 then
                                player:drawCards(1, self:objectName())
                                room:removePlayerMark(player, self:objectName() .. 'engine')
                            end
                        end
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getKingdom() == 'wu'
    end,
}
sunliang:addSkill(lijun)
ol_xuyou = sgs.General(extension_yin, 'ol_xuyou', 'qun', '3', true, sgs.GetConfig('hidden_ai', true))
chenglveCard = sgs.CreateSkillCard {
    name = 'chenglve',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            ChangeSkill(self, room, source)
            local n, x, prompt = 0, 0, nil
            if source:getMark(self:objectName()) == 1 then
                n, x, prompt = 1, 2, '@disTwo'
            elseif source:getMark(self:objectName()) ~= 1 then
                n, x, prompt = 2, 1, '@disOne'
            end
            source:drawCards(n, self:objectName())
            local cards = room:askForExchange(source, self:objectName(), math.min(source:getHandcardNum(), x), x, false,
                prompt)
            if cards then
                room:throwCard(cards, source, source)
                room:addPlayerMark(source,
                    'chenglve' .. sgs.Sanguosha:getCard(cards:getSubcards():first()):getSuitString() .. '-Clear')
                room:addPlayerMark(source, 'chenglve' .. sgs.Sanguosha:getCard(cards:getSubcards():last()):getSuitString() ..
                    '-Clear')
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
chenglveVS = sgs.CreateZeroCardViewAsSkill {
    name = 'chenglve',
    view_as = function()
        return chenglveCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#chenglve')
    end,
}
chenglve = sgs.CreatePhaseChangeSkill {
    name = 'chenglve',
    view_as_skill = chenglveVS,
    frequency = sgs.Skill_Change,
    on_phasechange = function(self, player)
    end,
}
ol_xuyou:addSkill(chenglve)
extension_yin:insertRelatedSkills('chenglve', '#chenglveBuff')
ol_shicai = sgs.CreateTriggerSkill {
    name = 'ol_shicai',
    global = true,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local card = data:toCardUse().card
        if player:getMark('shicai' .. card:getTypeId() .. '-Clear') == 0 and not card:isKindOf('SkillCard') and
            RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                if room:getCardPlace(card:getEffectiveId()) == sgs.Player_Discard then
                    local log = sgs.LogMessage()
                    log.type = '#shicai_put'
                    log.from = player
                    log.card_str = card:toString()
                    room:sendLog(log)
                end
                room:moveCardTo(card, player, sgs.Player_DrawPile)
                player:drawCards(1, self:objectName())
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        room:addPlayerMark(player, 'shicai' .. card:getTypeId() .. '-Clear')
        return false
    end,
}
ol_xuyou:addSkill(ol_shicai)
cunmu = sgs.CreateTriggerSkill {
    name = 'cunmu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
            move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW then
            SendComLog(self, player)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                local n, drawpile = move.card_ids:length(), room:getDrawPile()
                room:returnToTopDrawPile(move.card_ids)
                move.card_ids = sgs.IntList()
                for i = 1, n do
                    move.card_ids:append(drawpile:at(drawpile:length() - i))
                end
                data:setValue(move)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
ol_xuyou:addSkill(cunmu)
luzhiy = sgs.General(extension_yin, 'luzhiy', 'qun', '3', true, sgs.GetConfig('hidden_ai', true))
mingren = sgs.CreateTriggerSkill {
    name = 'mingren',
    events = {sgs.DrawInitialCards, sgs.AfterDrawInitialCards, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawInitialCards then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                data:setValue(data:toInt() + 1)
                player:setTag('mingren', sgs.QVariant(true))
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif event == sgs.AfterDrawInitialCards and player:getTag('mingren'):toBool() and not player:isKongcheng() then
            room:broadcastSkillInvoke(self:objectName())
            player:setTag('mingren', sgs.QVariant(false))
            local id = room:askForExchange(player, self:objectName(), 1, 1, false, 'mingren_put'):getSubcards():first()
            if id ~= -1 then
                player:addToPile('ren', id)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and
            not player:getPile('ren'):isEmpty() and not player:isKongcheng() then
            local card = room:askForExchange(player, self:objectName(), 1, 1, false, 'mingren_exchange', true)
            if card and card:getSubcards():first() ~= -1 then
                skill(self, room, player, true)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:addToPile('ren', card:getSubcards():first())
                    local _card = sgs.Sanguosha:getCard(player:getPile('ren'):first())
                    room:obtainCard(player, _card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                        player:objectName(), self:objectName(), ''))
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
luzhiy:addSkill(mingren)
zhenliangCard = sgs.CreateSkillCard {
    name = 'zhenliang',
    filter = function(self, targets, to_select)
        return #targets == 0 and math.max(1, math.abs(to_select:getHp() - sgs.Self:getHp())) == self:subcardsLength() and
                   sgs.Self:inMyAttackRange(to_select) and sgs.Self:objectName() ~= to_select:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        ChangeSkill(self, room, effect.from, 0)
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
zhenliangVS = sgs.CreateViewAsSkill {
    name = 'zhenliang',
    n = 999,
    view_filter = function(self, selected, to_select)
        return GetColor(to_select) == GetColor(sgs.Sanguosha:getCard(sgs.Self:getPile('ren'):first()))
    end,
    view_as = function(self, cards)
        local skill = zhenliangCard:clone()
        if #cards ~= 0 then
            for _, c in ipairs(cards) do
                skill:addSubcard(c)
            end
        end
        return skill
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, 'he') and not player:hasUsed('#zhenliang') and player:getMark(self:objectName()) ~=
                   1 and player:getPile('ren'):length() > 0
    end,
}
zhenliang = sgs.CreateTriggerSkill {
    name = 'zhenliang',
    view_as_skill = zhenliangVS,
    frequency = sgs.Skill_Change,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            local invoke = false
            for _, id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
                    invoke = true
                end
            end
            if player:getPhase() == sgs.Player_NotActive and player:getMark(self:objectName()) == 1 and
                not player:getPile('ren'):isEmpty() and invoke then
                local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), 'zhenliang-invoke',
                    true, true)
                if to then
                    ChangeSkill(self, room, player, 0)
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        to:drawCards(1, self:objectName())
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:getTypeId() == sgs.Sanguosha:getCard(player:getPile('ren'):first()):getTypeId() then
                room:setCardFlag(card, self:objectName())
            end
        end
        return false
    end,
}
luzhiy:addSkill(zhenliang)
shenliubei = sgs.General(extension_yin, 'shenliubei', 'god', 6, true, sgs.GetConfig('hidden_ai', true))
longnu = sgs.CreatePhaseChangeSkill {
    name = 'longnu',
    frequency = sgs.Skill_Compulsory,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Play then
            SendComLog(self, player)
            if ChangeSkill(self, room, player) == 1 then
                room:loseHp(player)
                player:drawCards(1, self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:acquireSkill(player, '#longnu_red_clear', false)
                    room:filterCards(player, player:getCards('h'), false)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            else
                room:loseMaxHp(player)
                player:drawCards(1, self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:acquireSkill(player, '#longnu_trick_clear', false)
                    room:filterCards(player, player:getCards('h'), false)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
longnu_red_clear = sgs.CreateFilterSkill {
    name = '#longnu_red_clear',
    view_filter = function(self, to_select)
        return to_select:isRed() and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) ==
                   sgs.Player_PlaceHand
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard('fire_slash', card:getSuit(), card:getNumber())
        slash:setSkillName('longnu_red')
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(slash)
        return new
    end,
}
longnu_trick_clear = sgs.CreateFilterSkill {
    name = '#longnu_trick_clear',
    view_filter = function(self, to_select)
        return to_select:isKindOf('TrickCard') and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) ==
                   sgs.Player_PlaceHand
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard('thunder_slash', card:getSuit(), card:getNumber())
        slash:setSkillName('longnu_trick')
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(slash)
        return new
    end,
}
shenliubei:addSkill(longnu)
if not sgs.Sanguosha:getSkill('#longnu_red_clear') then
    skills:append(longnu_red_clear)
end
if not sgs.Sanguosha:getSkill('#longnu_trick_clear') then
    skills:append(longnu_trick_clear)
end
jieying = sgs.CreateTriggerSkill {
    name = 'jieying',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.ChainStateChange},
    on_trigger = function(self, event, player, data, room)
        if not player:isChained() then
            room:setPlayerChained(player)
        end
        if event == sgs.ChainStateChange and player:isChained() then
            return true
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not p:isChained() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), 'jieying-invoke', false, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        room:setPlayerChained(target)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
}
shenliubei:addSkill(jieying)
shenluxun = sgs.General(extension_yin, 'shenluxun', 'god', 4, true, sgs.GetConfig('hidden_ai', true))
junlve = sgs.CreateTriggerSkill {
    name = 'junlve',
    events = {sgs.Damage, sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        if event == sgs.Damage then
            room:broadcastSkillInvoke(self:objectName(), 1)
        else
            room:broadcastSkillInvoke(self:objectName(), 2)
        end
        room:addPlayerMark(player, self:objectName() .. 'engine')
        if player:getMark(self:objectName() .. 'engine') > 0 then
            player:gainMark('@junlve', data:toDamage().damage)
            room:removePlayerMark(player, self:objectName() .. 'engine')
        end
    end,
}
shenluxun:addSkill(junlve)
-- 忽略函数循环复杂度过高的警告
-- luacheck: push ignore 561
bukuishishen = sgs.CreateTriggerSkill {
    name = 'bukuishishen',
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.DamageInflicted},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local choices = {}
        local choicess = {}
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and
            (player:hasSkill('cuike') or player:hasSkill('zhanhuo')) then
            local ji = math.mod(player:getMark('@junlve'), 2) == 1
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if ji or not player:isChained() or player:canDiscard(p, 'he') then
                    targets:append(p)
                end
            end
            local targets_c = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isChained() then
                    targets_c:append(p)
                end
            end
            if not targets:isEmpty() and player:hasSkill('cuike') then
                table.insert(choices, 'cuike')
            end
            if not targets_c:isEmpty() and player:hasSkill('zhanhuo') and player:getMark('@junlve') > 0 and
                player:getMark('@fire_boom') > 0 then
                table.insert(choices, 'zhanhuo')
            end
            if #choices > 0 then
                local targets_e = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if ji or not player:isChained() or player:canDiscard(p, 'he') then
                        targets_e:append(p)
                    end
                end
                local targets_ch = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isChained() then
                        targets_ch:append(p)
                    end
                end
                local choice = room:askForChoice(player, 'SKILL', table.concat(choices, '+'))
                room:addPlayerMark(player, choice)
                room:removePlayerMark(player, choice)
                if not targets_e:isEmpty() and player:hasSkill('cuike') then
                    if not table.contains(choices, 'cuike') then
                        table.insert(choices, 'cuike')
                    end
                else
                    if table.contains(choices, 'cuike') then
                        table.removeOne(choices, 'cuike')
                    end
                end
                if not targets_ch:isEmpty() and player:hasSkill('zhanhuo') and player:getMark('@junlve') > 0 and
                    player:getMark('@fire_boom') > 0 then
                    if not table.contains(choices, 'zhanhuo') then
                        table.insert(choices, 'zhanhuo')
                    end
                else
                    if table.contains(choices, 'zhanhuo') then
                        table.removeOne(choices, 'zhanhuo')
                    end
                end
                table.removeOne(choices, choice)
                if #choices > 0 then
                    local twice = room:askForChoice(player, 'SKILL', table.concat(choices, '+'))
                    room:addPlayerMark(player, twice)
                    room:removePlayerMark(player, twice)
                end
            end
        elseif event == sgs.Damage and (player:hasSkill('duorui') or player:hasSkill('zhiti')) then
            local damage = data:toDamage()
            local duoruis = {}
            for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
                if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and
                    string.find(skill:getDescription(), sgs.Sanguosha:translate('duorui1')) or
                    string.find(skill:getDescription(), sgs.Sanguosha:translate('duorui2')) then
                    table.insert(duoruis, skill:objectName())
                end
            end
            if player:hasSkill('duorui') and damage.to:objectName() ~= player:objectName() and player:getPhase() ==
                sgs.Player_Play and player:getMark('duorui_lun') == 0 and player:hasEquipArea() and #duoruis > 0 then
                table.insert(choices, 'duorui')
            end
            local invoke = false
            for i = 0, 4 do
                if not invoke then
                    invoke = not player:hasEquipArea(i)
                end
            end
            if player:hasSkill('zhiti') and damage.card and damage.card:isKindOf('Duel') and invoke and damage.to:isWounded() and
                player:inMyAttackRange(damage.to) then
                table.insert(choices, 'zhiti')
            end
            if #choices > 0 then
                local choice = room:askForChoice(player, 'SKILL', table.concat(choices, '+'))
                player:setTag(choice, data)
                room:addPlayerMark(player, choice)
                room:removePlayerMark(player, choice)
                local duoruiss = {}
                for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
                    if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and
                        string.find(skill:getDescription(), sgs.Sanguosha:translate('duorui1')) or
                        string.find(skill:getDescription(), sgs.Sanguosha:translate('duorui2')) then
                        table.insert(duoruiss, skill:objectName())
                    end
                end
                if player:hasSkill('duorui') and damage.to:objectName() ~= player:objectName() and player:getPhase() ==
                    sgs.Player_Play and player:getMark('duorui_lun') == 0 and player:hasEquipArea() and #duoruiss > 0 then
                    table.insert(choicess, 'duorui')
                end
                local _invoke = false
                for i = 0, 4 do
                    if not _invoke then
                        _invoke = not player:hasEquipArea(i)
                    end
                end
                if player:hasSkill('zhiti') and damage.card:isKindOf('Duel') and invoke and damage.to:isWounded() and
                    player:inMyAttackRange(damage.to) then
                    table.insert(choicess, 'zhiti')
                end
                table.removeOne(choicess, choice)
                if #choicess > 0 then
                    local choicee = room:askForChoice(player, 'SKILL', table.concat(choicess, '+'))
                    player:setTag(choicee, data)
                    room:addPlayerMark(player, choicee)
                    room:removePlayerMark(player, choicee)
                end
            end
        elseif event == sgs.DamageInflicted then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                local damage = data:toDamage()
                local n = 0
                for _, pe in sgs.qlist(room:getAlivePlayers()) do
                    if pe:isChained() then
                        n = n + 1
                    end
                end
                if damage.nature ~= sgs.DamageStruct_Normal and not damage.chain and damage.to:isChained() and n > 0 and
                    p:hasSkill('chenghao') then
                    table.insert(choices, 'chenghao')
                end
                if p:getMark('@dragon') + p:getMark('@phoenix') == 0 and not p:getArmor() and
                    (damage.nature ~= sgs.DamageStruct_Normal or (damage.card and damage.card:isKindOf('TrickCard'))) and
                    p:hasSkill('yinshi') and p:objectName() == player:objectName() then
                    table.insert(choices, 'yinshi')
                end
                if #choices > 0 then
                    local choice = room:askForChoice(p, 'SKILL', table.concat(choices, '+'))
                    room:addPlayerMark(p, choice)
                    room:removePlayerMark(p, choice)
                    if choice == 'yinshi' then
                        local msg = sgs.LogMessage()
                        msg.type = '#YinshiProtect'
                        msg.from = p
                        msg.arg = damage.damage
                        if damage.nature == sgs.DamageStruct_Fire then
                            msg.arg2 = 'fire_nature'
                        elseif damage.nature == sgs.DamageStruct_Thunder then
                            msg.arg2 = 'thunder_nature'
                        elseif damage.nature == sgs.DamageStruct_Normal then
                            msg.arg2 = 'normal_nature'
                        end
                        room:sendLog(msg)
                        room:notifySkillInvoked(p, 'yinshi')
                        room:broadcastSkillInvoke('yinshi')
                        room:addPlayerMark(p, 'yinshiengine')
                        if p:getMark('yinshiengine') > 0 then
                            room:removePlayerMark(p, 'yinshiengine')
                            return true
                        end
                    end
                    local m = 0
                    for _, pe in sgs.qlist(room:getAlivePlayers()) do
                        if pe:isChained() then
                            m = m + 1
                        end
                    end
                    if damage.nature ~= sgs.DamageStruct_Normal and not damage.chain and damage.to:isChained() and m > 0 and
                        p:hasSkill('chenghao') then
                        table.insert(choicess, 'chenghao')
                    end
                    if p:getMark('@dragon') + p:getMark('@phoenix') == 0 and not p:getArmor() and
                        (damage.nature ~= sgs.DamageStruct_Normal or (damage.card and damage.card:isKindOf('TrickCard'))) and
                        p:hasSkill('yinshi') and p:objectName() == player:objectName() then
                        table.insert(choicess, 'yinshi')
                    end
                    table.removeOne(choicess, choice)
                    if #choicess > 0 then
                        local choicee = room:askForChoice(p, 'SKILL', table.concat(choicess, '+'))
                        room:addPlayerMark(p, choicee)
                        room:removePlayerMark(p, choicee)
                        if choicee == 'yinshi' then
                            local msg = sgs.LogMessage()
                            msg.type = '#YinshiProtect'
                            msg.from = p
                            msg.arg = damage.damage
                            if damage.nature == sgs.DamageStruct_Fire then
                                msg.arg2 = 'fire_nature'
                            elseif damage.nature == sgs.DamageStruct_Thunder then
                                msg.arg2 = 'thunder_nature'
                            elseif damage.nature == sgs.DamageStruct_Normal then
                                msg.arg2 = 'normal_nature'
                            end
                            room:sendLog(msg)
                            room:notifySkillInvoked(p, 'yinshi')
                            room:broadcastSkillInvoke('yinshi')
                            room:addPlayerMark(p, 'yinshiengine')
                            if p:getMark('yinshiengine') > 0 then
                                room:removePlayerMark(p, 'yinshiengine')
                                return true
                            end
                        end
                    end
                end
            end
        end
    end,
}
-- luacheck: pop
if not sgs.Sanguosha:getSkill('bukuishishen') then
    skills:append(bukuishishen)
end
cuike = sgs.CreateTriggerSkill {
    name = 'cuike',
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == self:objectName() and mark.gain > 0 then
            local ji = math.mod(player:getMark('@junlve'), 2) == 1
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if ji or not p:isChained() or player:canDiscard(p, 'he') then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), 'cuike-invoke', true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        if ji then
                            room:damage(sgs.DamageStruct(self:objectName(), player, target))
                        else
                            if not target:isChained() then
                                room:setPlayerChained(target)
                            end
                            if player:canDiscard(target, 'he') then
                                local id = room:askForCardChosen(player, target, 'he', self:objectName(), false,
                                    sgs.Card_MethodDiscard)
                                if id ~= -1 then
                                    room:throwCard(sgs.Sanguosha:getCard(id), target, player)
                                end
                            end
                        end
                        if player:getMark('@junlve') > 7 and room:askForSkillInvoke(player, self:objectName(), data) then
                            player:loseAllMarks('@junlve')
                            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                                room:damage(sgs.DamageStruct(self:objectName(), player, p))
                            end
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
}
shenluxun:addSkill(cuike)
zhanhuoCard = sgs.CreateSkillCard {
    name = 'zhanhuo',
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark('@junlve') and to_select:isChained()
    end,
    about_to_use = function(self, room, use)
        use.from:loseAllMarks('@junlve')
        skill(self, room, use.from, true)
        room:addPlayerMark(use.from, self:objectName() .. 'engine')
        if use.from:getMark(self:objectName() .. 'engine') > 0 then
            room:removePlayerMark(use.from, '@fire_boom')
            for _, p in sgs.qlist(use.to) do
                room:doAnimate(1, use.from:objectName(), p:objectName())
                p:throwAllEquips()
            end
            room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), 1, sgs.DamageStruct_Fire))
            room:removePlayerMark(use.from, self:objectName() .. 'engine')
        end
    end,
}
zhanhuoVS = sgs.CreateZeroCardViewAsSkill {
    name = 'zhanhuo',
    view_as = function(self, cards)
        return zhanhuoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@zhanhuo'
    end,
}
zhanhuo = sgs.CreateTriggerSkill {
    name = 'zhanhuo',
    frequency = sgs.Skill_Limited,
    limit_mark = '@fire_boom',
    view_as_skill = zhanhuoVS,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == self:objectName() and mark.gain > 0 then
            room:askForUseCard(player, '@@zhanhuo', '@zhanhuo', -1, sgs.Card_MethodUse)
        end
    end,
}
shenluxun:addSkill(zhanhuo)
chendao = sgs.General(extension_lei, 'chendao', 'shu', 4, true, sgs.GetConfig('hidden_ai', true))
wanglie = sgs.CreateTriggerSkill {
    name = 'wanglie',
    events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetSpecified, sgs.TrickCardCanceling},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:hasFlag('wenji') and string.find(use.card:getClassName(), 'Slash') then
                local jink_table = sgs.QList2Table(player:getTag('Jink_' .. use.card:toString()):toIntList())
                local index = 1
                for _, p in sgs.qlist(use.to) do
                    local _data = sgs.QVariant()
                    _data:setValue(p)
                    jink_table[index] = 0
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
                jink_data:setValue(Table2IntList(jink_table))
                player:setTag('Jink_' .. use.card:toString(), jink_data)
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and effect.from:hasSkill(self:objectName()) and effect.card:hasFlag('wenji') then
                room:broadcastSkillInvoke(self:objectName())
                return true
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf('SkillCard') and player:getPhase() == sgs.Player_Play and
                room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setCardFlag(card, 'wenji')
                    room:setPlayerCardLimitation(player, 'use, response', '.|.|.|hand', false)
                    room:addPlayerMark(player, self:objectName() .. '_replay')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
chendao:addSkill(wanglie)
zhugezhan = sgs.General(extension_lei, 'zhugezhan', 'shu', 3, true, sgs.GetConfig('hidden_ai', true))
zuilunCard = sgs.CreateSkillCard {
    name = 'zuilun',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
                   ((sgs.Self:getMark('zuilunequip_Play') > 0 and not to_select:isKongcheng()) or
                       (sgs.Self:getMark('zuilunhand_Play') > 0 and to_select:hasEquip()) or
                       (sgs.Self:getMark('zuilunhand_Play') == 0 and sgs.Self:getMark('zuilunequip_Play') == 0 and
                           not to_select:isNude()))
    end,
    on_use = function(self, room, source, targets)
        local pattern = 'he'
        if source:getMark('zuilunhand_Play') > 0 then
            pattern = 'e'
        elseif source:getMark('zuilunequip_Play') > 0 then
            pattern = 'h'
        end
        local id = room:askForCardChosen(source, targets[1], pattern, self:objectName())
        if id ~= -1 then
            if room:getCardPlace(id) == sgs.Player_PlaceHand then
                room:addPlayerMark(source, 'zuilunhand_Play')
            elseif room:getCardPlace(id) == sgs.Player_PlaceEquip then
                room:addPlayerMark(source, 'zuilunequip_Play')
            end
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                room:obtainCard(source, sgs.Sanguosha:getCard(id), false)
                targets[1]:drawCards(1, self:objectName())
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
        end
    end,
}
zuilun = sgs.CreateZeroCardViewAsSkill {
    name = 'zuilun',
    view_as = function()
        return zuilunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('zuilunhand_Play') == 0 or player:getMark('zuilunequip_Play') == 0
    end,
}
zhugezhan:addSkill(zuilun)
fuyin = sgs.CreateProhibitSkill {
    name = 'fuyin',
    frequency = sgs.Skill_Compulsory,
    is_prohibited = function(self, from, to, card)
        return to:hasSkill(self:objectName()) and not to:getArmor() and from:getHandcardNum() >= to:getHandcardNum() and
                   from:objectName() ~= to:objectName() and
                   (card:isKindOf('Slash') or card:isKindOf('Duel') or card:isKindOf('FireAttack'))
    end,
}
zhugezhan:addSkill(fuyin)
haozhao = sgs.General(extension_lei, 'haozhao', 'wei', 4, true, sgs.GetConfig('hidden_ai', true))
zhengu = sgs.CreatePhaseChangeSkill {
    name = 'zhengu',
    global = true,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:getMark('zhengu' .. p:objectName()) > 0 then
                    room:setPlayerMark(player, 'zhengu' .. p:objectName(), 0)
                    if p:getMark('@zhengu') > 0 then
                        room:setPlayerMark(p, '@zhengu', 0)
                    end
                end
            end
            if RIGHT(self, player) then
                local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'zhengu-invoke',
                    true, true)
                if to then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        room:addPlayerMark(to, '@zhengu')
                        room:addPlayerMark(player, 'zhengu' .. to:objectName())
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        elseif player:getPhase() == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                local from = player
                local to = p
                if to:getMark('zhengu' .. from:objectName()) > 0 and from:getMark('@zhengu') > 0 then
                    from = p
                    to = player
                end
                if from:getMark('zhengu' .. to:objectName()) > 0 and to:getMark('@zhengu') > 0 then
                    room:doAnimate(1, from:objectName(), to:objectName())
                    local n = from:getHandcardNum() - to:getHandcardNum()
                    if n < 0 then
                        room:askForDiscard(to, self:objectName(), -n, -n, false, false)
                    elseif n > 0 then
                        to:drawCards(n, self:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
haozhao:addSkill(zhengu)
guanqiujian = sgs.General(extension_lei, 'guanqiujian', 'wei', 4, true, sgs.GetConfig('hidden_ai', true))
zhengrong = sgs.CreateTriggerSkill {
    name = 'zhengrong',
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to and damage.to:objectName() ~= player:objectName() and damage.to:getHandcardNum() >
            player:getHandcardNum() and not damage.to:isNude() and
            room:askForSkillInvoke(player, self:objectName(), sgs.QVariant('zhengrong-invoke:' .. damage.to:objectName())) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                local id = room:askForCardChosen(player, damage.to, 'he', self:objectName())
                if id ~= -1 then
                    player:addToPile('honor', id)
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
guanqiujian:addSkill(zhengrong)
hongjuCard = sgs.CreateSkillCard {
    name = 'hongju',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local to_handcard = sgs.IntList()
        local to_pile = sgs.IntList()
        local set = source:getPile('honor')
        for _, id in sgs.qlist(self:getSubcards()) do
            set:append(id)
        end
        for _, id in sgs.qlist(set) do
            if not self:getSubcards():contains(id) then
                to_handcard:append(id)
            elseif not source:getPile('honor'):contains(id) then
                to_pile:append(id)
            end
        end
        assert(to_handcard:length() == to_pile:length())
        if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then
            return
        end
        room:notifySkillInvoked(source, 'hongju')
        source:addToPile('honor', to_pile, false)
        local to_handcard_x = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, id in sgs.qlist(to_handcard) do
            to_handcard_x:addSubcard(id)
        end
        room:obtainCard(source, to_handcard_x, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
            source:objectName(), self:objectName(), ''))
    end,
}
hongjuVS = sgs.CreateViewAsSkill {
    name = 'hongju',
    n = 999,
    response_pattern = '@@hongju',
    expand_pile = 'honor',
    view_filter = function(self, selected, to_select)
        if #selected < sgs.Self:getPile('honor'):length() then
            return not to_select:isEquipped()
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == sgs.Self:getPile('honor'):length() then
            local c = hongjuCard:clone()
            for _, card in ipairs(cards) do
                c:addSubcard(card)
            end
            return c
        end
        return nil
    end,
}
hongju = sgs.CreatePhaseChangeSkill {
    name = 'hongju',
    frequency = sgs.Skill_Wake,
    view_as_skill = hongjuVS,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 and
            player:getPile('honor'):length() >= 3 then
            local invoke = false
            for _, p in sgs.qlist(room:getAllPlayers(true)) do
                if p:isDead() then
                    invoke = true
                end
            end
            if invoke then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:addPlayerMark(player, self:objectName())
                    if not player:isKongcheng() then
                        room:askForUseCard(player, '@@hongju', '@hongju', -1, sgs.Card_MethodNone)
                    end
                    if room:changeMaxHpForAwakenSkill(player) then
                        room:acquireSkill(player, 'qingce')
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
guanqiujian:addSkill(hongju)
qingceCard = sgs.CreateSkillCard {
    name = 'qingce',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and (to_select:hasEquip() or to_select:getJudgingArea():length() > 0)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:addPlayerMark(effect.from, self:objectName() .. 'engine')
        if effect.from:getMark(self:objectName() .. 'engine') > 0 then
            room:throwCard(sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, '', effect.to:objectName(), self:objectName(), ''), nil)
            local id = room:askForCardChosen(effect.from, effect.to, 'ej', self:objectName(), false, sgs.Card_MethodDiscard)
            if id ~= -1 then
                room:throwCard(id, effect.to, effect.from)
            end
            room:removePlayerMark(effect.from, self:objectName() .. 'engine')
        end
    end,
}
qingce = sgs.CreateOneCardViewAsSkill {
    name = 'qingce',
    filter_pattern = '.|.|.|honor',
    expand_pile = 'honor',
    view_as = function(self, card)
        local scard = qingceCard:clone()
        scard:addSubcard(card)
        return scard
    end,
    enabled_at_play = function(self, player)
        return player:getPile('honor'):length() > 0
    end,
}
if not sgs.Sanguosha:getSkill('qingce') then
    skills:append(qingce)
end
guanqiujian:addRelateSkill('qingce')
zhoufei = sgs.General(extension_lei, 'zhoufei', 'wu', 3, false, sgs.GetConfig('hidden_ai', true))
liangyin = sgs.CreateTriggerSkill {
    name = 'liangyin',
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        local players = sgs.SPlayerList()
        if move.from and move.to_place == sgs.Player_PlaceSpecial then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() > player:getHandcardNum() then
                    players:append(p)
                end
            end
            if not players:isEmpty() then
                local to = room:askForPlayerChosen(player, players, self:objectName(), self:objectName() .. '-invoke', true,
                    true)
                if to then
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        to:drawCards(1, self:objectName())
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        elseif move.to and move.to_place == sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_PlaceSpecial) then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() < player:getHandcardNum() and not p:isNude() then
                    players:append(p)
                end
            end
            if not players:isEmpty() then
                local to = room:askForPlayerChosen(player, players, self:objectName(), self:objectName() .. '-invoke', true,
                    true)
                if to then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    room:addPlayerMark(player, self:objectName() .. 'engine', 2)
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        room:askForDiscard(to, self:objectName(), 1, 1, false, true)
                        room:removePlayerMark(player, self:objectName() .. 'engine', 2)
                    end
                end
            end
        end
        return false
    end,
}
zhoufei:addSkill(liangyin)
kongshengCard = sgs.CreateSkillCard {
    name = 'kongsheng',
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '!') then
                room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(self:getSubcards():first()), source, source))
            else
                source:addToPile('music', self)
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
kongshengVS = sgs.CreateViewAsSkill {
    name = 'kongsheng',
    n = 999,
    expand_pile = 'music',
    response_pattern = '@kongsheng',
    view_filter = function(self, selected, to_select)
        if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '!') then
            return sgs.Self:getPile('music'):contains(to_select:getEffectiveId()) and to_select:isKindOf('EquipCard') and
                       not sgs.Self:isProhibited(sgs.Self, to_select) and to_select:isAvailable(sgs.Self)
        else
            return not sgs.Self:getPile('music'):contains(to_select:getEffectiveId())
        end
    end,
    view_as = function(self, cards)
        if #cards ~= 0 then
            local card = kongshengCard:clone()
            for _, c in ipairs(cards) do
                card:addSubcard(c)
            end
            return card
        end
        return nil
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@kongsheng')
    end,
}
kongsheng = sgs.CreatePhaseChangeSkill {
    name = 'kongsheng',
    view_as_skill = kongshengVS,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and not player:isNude() then
            room:askForUseCard(player, '@kongsheng', '@kongsheng', -1, sgs.Card_MethodNone)
        elseif player:getPhase() == sgs.Player_Finish then
            local invoke = false
            for _, id in sgs.qlist(player:getPile('music')) do
                if sgs.Sanguosha:getCard(id):isKindOf('EquipCard') and
                    not player:isProhibited(player, sgs.Sanguosha:getCard(id)) and
                    sgs.Sanguosha:getCard(id):isAvailable(player) then
                    invoke = true
                end
            end
            while invoke and room:askForUseCard(player, '@kongsheng!', '@kongsheng', -1, sgs.Card_MethodNone) do
                invoke = false
                for _, id in sgs.qlist(player:getPile('music')) do
                    if sgs.Sanguosha:getCard(id):isKindOf('EquipCard') and
                        not player:isProhibited(player, sgs.Sanguosha:getCard(id)) and
                        sgs.Sanguosha:getCard(id):isAvailable(player) then
                        invoke = true
                    end
                end
            end
            if not player:getPile('music'):isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard('slash')
                dummy:addSubcards(player:getPile('music'))
                room:obtainCard(player, dummy, false)
            end
        end
    end,
}
zhoufei:addSkill(kongsheng)
ol_lukang = sgs.General(extension_lei, 'ol_lukang', 'wu', 4, true, sgs.GetConfig('hidden_ai', true))
qianjie = sgs.CreateTriggerSkill {
    name = 'qianjie',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.ChainStateChange},
    on_trigger = function(self, event, player, data, room)
        if not player:isChained() then
            SendComLog(self, player)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:removePlayerMark(player, self:objectName() .. 'engine')
                return true
            end
        end
    end,
}
ol_lukang:addSkill(qianjie)
jueyanCard = sgs.CreateSkillCard {
    name = 'jueyan',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local x = ThrowEquipArea(self, source)
            room:addPlayerMark(source, 'jueyan' .. x .. '-Clear')
            if x == 1 then
                source:drawCards(3, self:objectName())
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
jueyanVS = sgs.CreateZeroCardViewAsSkill {
    name = 'jueyan',
    view_as = function(self)
        return jueyanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#jueyan')
    end,
}
jueyan = sgs.CreateTriggerSkill {
    name = 'jueyan',
    global = true,
    view_as_skill = jueyanVS,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local jizhi = sgs.Sanguosha:getTriggerSkill('nosjizhi')
        if jizhi and data:toCardUse().card and player:getMark('jueyan4-Clear') > 0 then
            jizhi:trigger(event, room, player, data)
        end
        return false
    end,
}
ol_lukang:addSkill(jueyan)
poshi = sgs.CreatePhaseChangeSkill {
    name = 'poshi',
    frequency = sgs.Skill_Wake,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and (not player:hasEquipArea() or player:getHp() == 1) and
            player:getMark(self:objectName()) == 0 then
            SendComLog(self, player)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:addPlayerMark(player, self:objectName())
                if room:changeMaxHpForAwakenSkill(player) then
                    if player:getHandcardNum() < player:getMaxHp() then
                        player:drawCards(player:getMaxHp() - player:getHandcardNum(), self:objectName())
                    end
                    room:handleAcquireDetachSkills(player, '-jueyan|huairou')
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
ol_lukang:addSkill(poshi)
huairouCard = sgs.CreateSkillCard {
    name = 'huairou',
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST,
                source:objectName(), self:objectName(), ''))
            room:broadcastSkillInvoke('@recast')
            local log = sgs.LogMessage()
            log.type = '#UseCard_Recast'
            log.from = source
            log.card_str = tostring(self:getSubcards():first())
            room:sendLog(log)
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                source:drawCards(1, 'recast')
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
huairou = sgs.CreateOneCardViewAsSkill {
    name = 'huairou',
    filter_pattern = 'EquipCard',
    view_as = function(self, card)
        local skill_card = huairouCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
}
if not sgs.Sanguosha:getSkill('huairou') then
    skills:append(huairou)
end
ol_lukang:addRelateSkill('huairou')
god_yuanshu = sgs.General(extension_lei, 'god_yuanshu$', 'qun', 4, true, sgs.GetConfig('hidden_ai', true))
god_yongsi = sgs.CreateTriggerSkill {
    name = 'god_yongsi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            if getKingdoms(player) > 2 then
                room:broadcastSkillInvoke(self:objectName(), 1)
            end
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                data:setValue(getKingdoms(player))
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard and
            player:getMark('damage_record-Clear') ~= 1 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            if player:getMark('damage_record-Clear') == 0 and player:getHandcardNum() < player:getHp() then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:drawCards(player:getHp() - player:getHandcardNum(), self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            elseif player:getMark('damage_record-Clear') > 1 then
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setPlayerFlag(player, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
god_yuanshu:addSkill(god_yongsi)
god_weidiCard = sgs.CreateSkillCard {
    name = 'god_weidi',
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return
            #targets == 0 and to_select:getMark(self:objectName() .. '-Clear') == 0 and to_select:getKingdom() == 'qun' and
                sgs.Self:objectName() ~= to_select:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local sbs = {}
            if source:getTag('god_weidi'):toString() ~= '' then
                sbs = source:getTag('god_weidi'):toString():split('+')
            end
            for _, cdid in sgs.qlist(self:getSubcards()) do
                table.insert(sbs, tostring(cdid))
            end
            source:setTag('god_weidi', sgs.QVariant(table.concat(sbs, '+')))
            room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
                targets[1]:objectName(), self:objectName(), ''), false)
            room:addPlayerMark(targets[1], self:objectName() .. '-Clear')
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
god_weidiVS = sgs.CreateOneCardViewAsSkill {
    name = 'god_weidi',
    view_filter = function(self, card)
        return string.find(sgs.Self:property('god_weidi'):toString(), tostring(card:getEffectiveId()))
    end,
    view_as = function(self, cards)
        local card = god_weidiCard:clone()
        card:addSubcard(cards)
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@god_weidi' and player:hasLordSkill(self:objectName())
    end,
}
function listIndexOf(theqlist, theitem)
    local index = 0
    for _, item in sgs.qlist(theqlist) do
        if item == theitem then
            return index
        end
        index = index + 1
    end
end
god_weidi = sgs.CreateTriggerSkill {
    name = 'god_weidi',
    view_as_skill = god_weidiVS,
    events = {sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and player:hasLordSkill(self:objectName()) and
            player:getPhase() == sgs.Player_Discard and move.to_place == sgs.Player_DiscardPile then
            if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ==
                sgs.CardMoveReason_S_REASON_DISCARD then
                local zongxuan_card = sgs.IntList()
                for i = 0, (move.card_ids:length() - 1), 1 do
                    local card_id = move.card_ids:at(i)
                    if room:getCardOwner(card_id):getSeat() == move.from:getSeat() and
                        (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
                        zongxuan_card:append(card_id)
                    end
                end
                if zongxuan_card:isEmpty() then
                    return
                end
                local zongxuantable = sgs.QList2Table(zongxuan_card)
                room:setPlayerProperty(player, 'god_weidi', sgs.QVariant(table.concat(zongxuantable, '+')))
                while not zongxuan_card:isEmpty() do
                    if not room:askForUseCard(player, '@@god_weidi', '@god_weidiput') then
                        break
                    end
                    local subcards = sgs.IntList()
                    local subcards_variant = player:getTag('god_weidi'):toString():split('+')
                    if #subcards_variant > 0 then
                        for _, ids in ipairs(subcards_variant) do
                            subcards:append(tonumber(ids))
                        end
                        local zongxuan = player:property('god_weidi'):toString():split('+')
                        for _, id in sgs.qlist(subcards) do
                            zongxuan_card:removeOne(id)
                            table.removeOne(zongxuan, tonumber(id))
                            if move.card_ids:contains(id) then
                                move.from_places:removeAt(listIndexOf(move.card_ids, id))
                                move.card_ids:removeOne(id)
                                data:setValue(move)
                            end
                            if player:isDead() then
                                break
                            end
                        end
                    end
                    player:removeTag('god_weidi')
                end
            end
        end
        return
    end,
}
god_yuanshu:addSkill(god_weidi)
zhangxiu = sgs.General(extension_lei, 'zhangxiu', 'qun', 4, true, sgs.GetConfig('hidden_ai', true))
xiongluanCard = sgs.CreateSkillCard {
    name = 'xiongluan',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:removePlayerMark(source, '@fuck_caocao')
            source:throwEquipArea()
            source:throwJudgeArea()
            room:addPlayerMark(source, 'fuck_caocao-Clear')
            room:addPlayerMark(targets[1], '@be_fucked-Clear')
            room:addPlayerMark(targets[1], 'ban_ur')
            room:setPlayerCardLimitation(targets[1], 'use,response', '.|.|.|hand', false)
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
xiongluanVS = sgs.CreateZeroCardViewAsSkill {
    name = 'xiongluan',
    view_as = function(self, cards)
        return xiongluanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@fuck_caocao') > 0
    end,
}
xiongluan = sgs.CreatePhaseChangeSkill {
    name = 'xiongluan',
    frequency = sgs.Skill_Limited,
    view_as_skill = xiongluanVS,
    limit_mark = '@fuck_caocao',
    on_phasechange = function()
    end,
}
zhangxiu:addSkill(xiongluan)
congjianCard = sgs.CreateSkillCard {
    name = 'congjian',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark(self:objectName()) > 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
                targets[1]:objectName(), self:objectName(), ''), false)
            local x = 1
            if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf('EquipCard') then
                x = 2
            end
            source:drawCards(x, self:objectName())
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
congjianVS = sgs.CreateOneCardViewAsSkill {
    name = 'congjian',
    filter_pattern = '.',
    view_as = function(self, card)
        local first = congjianCard:clone()
        first:addSubcard(card:getId())
        first:setSkillName(self:objectName())
        return first
    end,
    response_pattern = '@congjian',
    enabled_at_play = function(self, player)
        return false
    end,
}
congjian = sgs.CreateTriggerSkill {
    name = 'congjian',
    view_as_skill = congjianVS,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf('TrickCard') and use.to and use.to:contains(player) and use.to:length() > 1 then
            local targets = use.to
            targets:removeOne(player)
            for _, p in sgs.qlist(targets) do
                room:addPlayerMark(p, self:objectName())
            end
            room:askForUseCard(player, '@congjian', '@congjian', -1, sgs.Card_MethodNone)
            for _, p in sgs.qlist(targets) do
                room:removePlayerMark(p, self:objectName())
            end
        end
        return false
    end,
}
zhangxiu:addSkill(congjian)
shenzhangliao = sgs.General(extension_lei, 'shenzhangliao', 'god', 4, true, sgs.GetConfig('hidden_ai', true))
duorui = sgs.CreateTriggerSkill {
    name = 'duorui',
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == self:objectName() and mark.gain > 0 then
            local damage = player:getTag(self:objectName()):toDamage()
            local duoruis = {}
            for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
                if not skill:inherits('SPConvertSkill') and not skill:isAttachedLordSkill() and
                    string.find(skill:getDescription(), sgs.Sanguosha:translate('duorui1')) or
                    string.find(skill:getDescription(), sgs.Sanguosha:translate('duorui2')) then
                    table.insert(duoruis, skill:objectName())
                end
            end
            if #duoruis > 0 then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local n = ThrowEquipArea(self, player, true)
                    if n ~= -1 then
                        for i = 1, #duoruis do
                            room:addPlayerMark(damage.to, 'Duorui' .. duoruis[i])
                            room:addPlayerMark(damage.from, 'Duorui' .. duoruis[i] .. 'from')
                        end
                        room:addPlayerMark(player, 'duorui_lun')
                        room:handleAcquireDetachSkills(player, table.concat(duoruis, '|'))
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
shenzhangliao:addSkill(duorui)
zhiti = sgs.CreateTriggerSkill {
    name = 'zhiti',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged, sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.from_card:getNumber() ~= pindian.to_card:getNumber() then
                local winner = pindian.to
                local loser = pindian.from
                if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
                    winner = pindian.from
                    loser = pindian.to
                end
                if winner and winner:objectName() == player:objectName() and loser:isWounded() and
                    winner:inMyAttackRange(loser) then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        ObtainEquipArea(self, player)
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        else
            local mark = data:toMark()
            if mark.name == self:objectName() and mark.gain > 0 then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    ObtainEquipArea(self, player)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
shenzhangliao:addSkill(zhiti)
shenganning = sgs.General(extension_lei, 'shenganning', 'god', 6, true, sgs.GetConfig('hidden_ai', true), false, 3)
poxiCard = sgs.CreateSkillCard {
    name = 'poxi',
    will_throw = false,
    filter = function(self, targets, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi' or sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi_less' then
            return #targets < 0
        end
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    feasible = function(self, targets)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi' or sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi_less' then
            return #targets == 0
        end
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi' then
            for _, id in sgs.qlist(self:getSubcards()) do
                room:setCardFlag(sgs.Sanguosha:getCard(id), 'poxi')
            end
        else
            if targets[1] then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(source, self:objectName() .. 'engine')
                if source:getMark(self:objectName() .. 'engine') > 0 then
                    local ids = targets[1]:handCards()
                    room:setPlayerFlag(source, 'Fake_Move')
                    local _guojia = sgs.SPlayerList()
                    _guojia:append(source)
                    local move = sgs.CardsMoveStruct(ids, targets[1], source, sgs.Player_PlaceHand, sgs.Player_PlaceHand,
                        sgs.CardMoveReason())
                    local moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _guojia)
                    room:notifyMoveCards(false, moves, false, _guojia)
                    local invoke = room:askForUseCard(source, '@poxi', '@poxi')
                    local idt = sgs.IntList()
                    for _, id in sgs.qlist(targets[1]:handCards()) do
                        if ids:contains(id) then
                            idt:append(id)
                        end
                    end
                    local move_to = sgs.CardsMoveStruct(idt, source, targets[1], sgs.Player_PlaceHand, sgs.Player_PlaceHand,
                        sgs.CardMoveReason())
                    local moves_to = sgs.CardsMoveList()
                    moves_to:append(move_to)
                    room:notifyMoveCards(true, moves_to, false, _guojia)
                    room:notifyMoveCards(false, moves_to, false, _guojia)
                    room:setPlayerFlag(source, '-Fake_Move')
                    if invoke then
                        local dummy = sgs.Sanguosha:cloneCard('slash')
                        local dummy_target = sgs.Sanguosha:cloneCard('slash')
                        if source:getHandcardNum() + targets[1]:getHandcardNum() > 4 then
                            for _, id in sgs.qlist(source:handCards()) do
                                if sgs.Sanguosha:getCard(id):hasFlag('poxi') then
                                    dummy:addSubcard(id)
                                end
                            end
                            for _, id in sgs.qlist(targets[1]:handCards()) do
                                if sgs.Sanguosha:getCard(id):hasFlag('poxi') then
                                    dummy_target:addSubcard(id)
                                end
                            end
                            if dummy:subcardsLength() > 0 then
                                room:throwCard(dummy, source)
                            end
                            if dummy_target:subcardsLength() > 0 then
                                room:throwCard(dummy_target, targets[1], source)
                            end
                        end
                        if dummy:subcardsLength() == 0 then
                            room:loseMaxHp(source)
                        elseif dummy:subcardsLength() == 1 then
                            room:setPlayerFlag(source, 'Global_PlayPhaseTerminated')
                            room:setPlayerFlag(source, 'poxi')
                        elseif dummy:subcardsLength() == 3 then
                            room:recover(source, sgs.RecoverStruct(source))
                        elseif dummy:subcardsLength() == 4 then
                            source:drawCards(4, self:objectName())
                        end
                    end
                    room:removePlayerMark(source, self:objectName() .. 'engine')
                end
            end
        end
    end,
}
poxi = sgs.CreateViewAsSkill {
    name = 'poxi',
    n = 4,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi' then
            for _, c in sgs.list(selected) do
                if c:getSuit() == to_select:getSuit() then
                    return false
                end
            end
            return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
        end
        return true
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUsePattern() == '@poxi' then
            if #cards ~= 4 then
                return nil
            end
            local skillcard = poxiCard:clone()
            for _, c in ipairs(cards) do
                skillcard:addSubcard(c)
            end
            return skillcard
        else
            if #cards ~= 0 then
                return nil
            end
            return poxiCard:clone()
        end
    end,
    enabled_at_play = function(self, target)
        return not target:hasUsed('#poxi')
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@poxi'
    end,
}
shenganning:addSkill(poxi)
jieyingy = sgs.CreateTriggerSkill {
    name = 'jieyingy',
    events = {sgs.TurnStart, sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p and p:isAlive() and p:objectName() ~= player:objectName() and player:getMark('@thiefed') > 0 then
                    room:addPlayerMark(p, self:objectName() .. 'engine')
                    if p:getMark(self:objectName() .. 'engine') > 0 then
                        player:loseMark('@thiefed')
                        room:broadcastSkillInvoke(self:objectName(), 2)
                        room:obtainCard(p, player:wholeHandCards())
                        room:removePlayerMark(p, self:objectName() .. 'engine')
                    end
                end
            end
        else
            local players, targets = sgs.SPlayerList(), sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark('@thiefed') == 0 then
                    players:append(p)
                else
                    targets:append(p)
                end
            end
            if event == sgs.TurnStart and targets:isEmpty() and RIGHT(self, player) then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:gainMark('@thiefed')
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            elseif event == sgs.EventPhaseStart and RIGHT(self, player) and not players:isEmpty() and
                player:getMark('@thiefed') > 0 and player:getPhase() == sgs.Player_Finish then
                local target = room:askForPlayerChosen(player, players, self:objectName(), 'jieyingy-invoke', true, true)
                if target then
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        player:loseMark('@thiefed')
                        room:broadcastSkillInvoke(self:objectName(), 1)
                        target:gainMark('@thiefed')
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
shenganning:addSkill(jieyingy)
yanjun = sgs.General(extension_star, 'yanjun', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
guanchao = sgs.CreateTriggerSkill {
    name = 'guanchao',
    global = true,
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and RIGHT(self, player) then
            local choice = room:askForChoice(player, self:objectName(), 'guanchao1+guanchao2+cancel')
            if choice ~= 'cancel' then
                lazy(self, room, player, choice, true, 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setPlayerFlag(player, choice)
                    local log = sgs.LogMessage()
                    log.from = player
                    log.type = '#' .. choice
                    room:sendLog(log)
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf('SkillCard') then
                local num = card:getNumber()
                if (player:hasFlag('guanchao1') or player:hasFlag('guanchao2')) and
                    player:getMark(self:objectName() .. '_break_replay') == 0 and player:getMark('used_Play') > 1 and
                    player:getPhase() == sgs.Player_Play then
                    local log = sgs.LogMessage()
                    log.from = player
                    log.arg = fakeNumber(player:getMark(self:objectName() .. '_Play')) .. ' -> ' .. fakeNumber(num)
                    log.arg2 = self:objectName()
                    if player:hasFlag('guanchao1') then
                        if num > player:getMark(self:objectName() .. '_Play') then
                            log.type = '#guanchao_success_1'
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            room:addPlayerMark(player, self:objectName() .. 'engine')
                            if player:getMark(self:objectName() .. 'engine') > 0 then
                                player:drawCards(1, self:objectName())
                                room:removePlayerMark(player, self:objectName() .. 'engine')
                            end
                        else
                            log.type = '#guanchao_fail_1'
                            room:addPlayerMark(player, self:objectName() .. '_break_replay')
                        end
                    elseif player:hasFlag('guanchao2') then
                        if num < player:getMark(self:objectName() .. '_Play') then
                            log.type = '#guanchao_success_2'
                            room:broadcastSkillInvoke(self:objectName(), 2)
                            room:addPlayerMark(player, self:objectName() .. 'engine')
                            if player:getMark(self:objectName() .. 'engine') > 0 then
                                player:drawCards(1, self:objectName())
                                room:removePlayerMark(player, self:objectName() .. 'engine')
                            end
                        else
                            log.type = '#guanchao_fail_2'
                            room:addPlayerMark(player, self:objectName() .. '_break_replay')
                        end
                    end
                    room:sendLog(log)
                end
                if num > 0 and num < 14 and player:getMark(self:objectName() .. '_break_replay') == 0 then
                    room:setPlayerMark(player, self:objectName() .. '_Play', num)
                else
                    room:addPlayerMark(player, self:objectName() .. '_break_replay')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
yanjun:addSkill(guanchao)
xunxian = sgs.CreateTriggerSkill {
    name = 'xunxian',
    events = {sgs.BeforeCardsMove, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            local invoke = false
            local move = data:toMoveOneTime()
            for _, id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):hasFlag('xunxian') then
                    invoke = true
                end
            end
            local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            if player:getPhase() == sgs.Player_NotActive and move.from and
                (move.from:objectName() == player:objectName() or invoke) and move.to_place == sgs.Player_DiscardPile and
                (extract == sgs.CardMoveReason_S_REASON_USE or extract == sgs.CardMoveReason_S_REASON_RESPONSE) then
                if not room:getCurrent():hasFlag(self:objectName() .. player:objectName()) then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getHandcardNum() > player:getHandcardNum() then
                            targets:append(p)
                        end
                    end
                    local target = room:askForPlayerChosen(player, targets, self:objectName(),
                        self:objectName() .. '-invoke', true, true)
                    if target then
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            local dummy = sgs.Sanguosha:cloneCard('slash')
                            dummy:addSubcards(move.card_ids)
                            room:moveCardTo(dummy, target, sgs.Player_PlaceHand, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(),
                                self:objectName(), ''))
                            room:setPlayerFlag(room:getCurrent(), self:objectName() .. player:objectName())
                            move:removeCardIds(move.card_ids)
                            data:setValue(move)
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                end
            end
        else
            local use = data:toCardUse()
            if use.card:getClassName() == 'Nullification' then
                room:setCardFlag(use.card, 'xunxian')
            end
        end
        return false
    end,
}
yanjun:addSkill(xunxian)
duji = sgs.General(extension_star, 'duji', 'wei', 3, true, sgs.GetConfig('hidden_ai', true))
andong = sgs.CreateTriggerSkill {
    name = 'andong',
    global = true,
    events = {sgs.DamageInflicted, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() and RIGHT(self, player) and
                room:askForSkillInvoke(player, self:objectName(), data) then
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    local choice = room:askForChoice(damage.from, self:objectName(), 'andong1+andong2', data)
                    lazy(self, room, player, choice, true,
                        tonumber(string.sub(choice, string.len(choice), string.len(choice))))
                    if choice == 'andong1' then
                        room:addPlayerMark(damage.from, self:objectName() .. '-Clear')
                        local log = sgs.LogMessage()
                        log.type = '$andong_prevent'
                        log.from = damage.from
                        log.to:append(player)
                        log.arg = self:objectName()
                        room:sendLog(log)
                        return true
                    elseif choice == 'andong2' then
                        room:showAllCards(damage.from, player)
                        local cards = sgs.IntList()
                        for _, p in sgs.qlist(damage.from:getHandcards()) do
                            if p:getSuit() == sgs.Card_Heart then
                                cards:append(p:getEffectiveId())
                            end
                        end
                        if cards:length() > 0 then
                            local dummy = sgs.Sanguosha:cloneCard('slash')
                            dummy:addSubcards(cards)
                            room:obtainCard(player, dummy, false)
                        end
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        else
            if player:getMark(self:objectName() .. '-Clear') > 0 then
                local n = room:getTag('DiscardNum'):toInt()
                for _, card in sgs.qlist(player:getHandcards()) do
                    if card:getSuit() == sgs.Card_Heart then
                        n = n - 1
                    end
                end
                if event == sgs.AskForGameruleDiscard then
                    room:setPlayerCardLimitation(player, 'discard', '.|heart|.|hand', true)
                else
                    room:removePlayerCardLimitation(player, 'discard', '.|heart|.|hand$1')
                end
                room:setTag('DiscardNum', sgs.QVariant(n))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
duji:addSkill(andong)
yingshi = sgs.CreateTriggerSkill {
    name = 'yingshi',
    global = true,
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if RIGHT(self, player) and player:getPhase() == sgs.Player_Play then
                local list = sgs.IntList()
                local invoke = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if invoke then
                        invoke = p:getPile('reward'):isEmpty()
                    end
                end
                for _, c in sgs.qlist(player:getCards('he')) do
                    if c:getSuit() == sgs.Card_Heart then
                        list:append(c:getEffectiveId())
                    end
                end
                if invoke and not list:isEmpty() then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                        self:objectName() .. '-invoke', true, true)
                    if target then
                        room:broadcastSkillInvoke(self:objectName())
                        room:addPlayerMark(player, self:objectName() .. 'engine')
                        if player:getMark(self:objectName() .. 'engine') > 0 then
                            target:addToPile('reward', list)
                            room:removePlayerMark(player, self:objectName() .. 'engine')
                        end
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.to and not damage.to:getPile('reward'):isEmpty() and damage.card and
                damage.card:isKindOf('Slash') then
                room:fillAG(damage.to:getPile('reward'), damage.from)
                local id = room:askForAG(damage.from, damage.to:getPile('reward'), true, self:objectName())
                if id ~= -1 then
                    room:obtainCard(damage.from, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, damage.from:objectName()))
                end
                room:clearAG(damage.from)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if not death.who:getPile('reward'):isEmpty() and RIGHT(self, player) then
                local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                dummy:addSubcards(death.who:getPile('reward'))
                room:obtainCard(player, dummy,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName()))
            end
        end
        return false
    end,
}
duji:addSkill(yingshi)
liuyan = sgs.General(extension_star, 'liuyan', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
tushe = sgs.CreateTriggerSkill {
    name = 'tushe',
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.to:isEmpty() and not use.card:isKindOf('EquipCard') and not use.card:isKindOf('SkillCard') then
            for _, p in sgs.qlist(player:getCards('he')) do
                if p:isKindOf('BasicCard') then
                    return false
                end
            end
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    player:drawCards(use.to:length(), self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
liuyan:addSkill(tushe)
limuCard = sgs.CreateSkillCard {
    name = 'limu',
    target_fixed = true,
    will_throw = false,
    about_to_use = function(self, room, use)
        room:addPlayerMark(use.from, self:objectName() .. 'engine')
        if use.from:getMark(self:objectName() .. 'engine') > 0 then
            local c = sgs.Sanguosha:getCard(self:getSubcards():first())
            local card = sgs.Sanguosha:cloneCard('indulgence', c:getSuit(), c:getNumber())
            card:addSubcard(c:getEffectiveId())
            card:setSkillName(self:getSkillName())
            room:useCard(sgs.CardUseStruct(card, use.from, use.from), true)
            room:recover(use.from, sgs.RecoverStruct(use.from))
            room:removePlayerMark(use.from, self:objectName() .. 'engine')
        end
    end,
}
limu = sgs.CreateOneCardViewAsSkill {
    name = 'limu',
    filter_pattern = '.|diamond|.|.',
    view_as = function(self, card)
        local lm = limuCard:clone()
        lm:addSubcard(card:getEffectiveId())
        lm:setSkillName(self:objectName())
        return lm
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard('indulgence')
        card:deleteLater()
        return not player:containsTrick('indulgence') and not player:isProhibited(player, card)
    end,
}
liuyan:addSkill(limu)
wangcan = sgs.General(extension_star, 'wangcan', 'qun', 3, true, sgs.GetConfig('hidden_ai', true))
sanwen = sgs.CreateTriggerSkill {
    name = 'sanwen',
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getCurrent():hasFlag(self:objectName() .. player:objectName()) and not room:getTag('FirstRound'):toBool() and
            move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
            local show_ids = sgs.IntList()
            local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            for _, id in sgs.qlist(move.card_ids) do
                if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) ==
                    sgs.Player_PlaceHand then
                    for _, card in sgs.qlist(player:getHandcards()) do
                        if not move.card_ids:contains(card:getId()) and not show_ids:contains(card:getId()) and
                            TrueName(card) == TrueName(sgs.Sanguosha:getCard(id)) then
                            show_ids:append(card:getId())
                            for _, i in sgs.qlist(move.card_ids) do
                                if TrueName(card) == TrueName(sgs.Sanguosha:getCard(i)) and
                                    not dummy:getSubcards():contains(i) and room:getCardOwner(i):objectName() ==
                                    player:objectName() and room:getCardPlace(i) == sgs.Player_PlaceHand then
                                    dummy:addSubcard(i)
                                end
                            end
                        end
                    end
                end
            end
            if not show_ids:isEmpty() and player:canDiscard(player, 'h') and dummy:getSubcards():length() > 0 and
                room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerFlag(room:getCurrent(), self:objectName() .. player:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    ShowManyCards(player, show_ids)
                    room:throwCard(dummy, player, player)
                    player:drawCards(dummy:getSubcards():length() * 2, self:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
}
wangcan:addSkill(sanwen)
qiai = sgs.CreateTriggerSkill {
    name = 'qiai',
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Limited,
    limit_mark = '@qiai',
    on_trigger = function(self, event, player, data, room)
        if player:getMark('@qiai') > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:removePlayerMark(player, '@qiai')
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:doAnimate(1, player:objectName(), p:objectName())
                end
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if not p:isNude() then
                        local card = room:askForCard(p, '..!', '@qiai_give:' .. player:objectName(), sgs.QVariant(),
                            sgs.Card_MethodNone)
                        if card then
                            room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), ''))
                        end
                    end
                end
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
wangcan:addSkill(qiai)
denglouCard = sgs.CreateSkillCard {
    name = 'denglou',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and
                   not sgs.Self:isProhibited(to_select, card)
    end,
    feasible = function(self, targets)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        return card and card:targetsFeasible(targets_list, sgs.Self)
    end,
    about_to_use = function(self, room, use)
        local ids = sgs.IntList()
        local list = use.from:property(self:objectName()):toString():split('+')
        if #list > 0 then
            for _, l in pairs(list) do
                ids:append(tonumber(l))
            end
        end
        local _guojia = sgs.SPlayerList()
        _guojia:append(use.from)
        local move_to = sgs.CardsMoveStruct(ids, use.from, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
            sgs.CardMoveReason())
        local moves_to = sgs.CardsMoveList()
        moves_to:append(move_to)
        room:notifyMoveCards(true, moves_to, false, _guojia)
        room:notifyMoveCards(false, moves_to, false, _guojia)
        ids:removeOne(self:getSubcards():first())
        room:setPlayerFlag(use.from, '-Fake_Move')
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:setCardFlag(card, '-' .. self:objectName())
        local targets_list = sgs.SPlayerList()
        for _, p in sgs.qlist(use.to) do
            if not use.from:isProhibited(p, card) then
                targets_list:append(p)
            end
        end
        room:useCard(sgs.CardUseStruct(card, use.from, targets_list))
        room:setPlayerFlag(use.from, 'Fake_Move')
        local move = sgs.CardsMoveStruct(ids, nil, use.from, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false, _guojia)
        room:notifyMoveCards(false, moves, false, _guojia)
        room:setPlayerProperty(use.from, self:objectName(), sgs.QVariant(table.concat(sgs.QList2Table(ids), '+')))
    end,
}
denglouVS = sgs.CreateOneCardViewAsSkill {
    name = 'denglou',
    view_filter = function(self, card)
        return not sgs.Self:isJilei(card) and card:hasFlag(self:objectName()) and card:isAvailable(sgs.Self)
    end,
    view_as = function(self, card)
        local skillcard = denglouCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@denglou'
    end,
}
denglou =
    sgs.CreatePhaseChangeSkill { -- 尽最大努力只能做到从左到右使用观看的基本牌ZY:poi???FM大法参上!!!!!
        name = 'denglou',
        view_as_skill = denglouVS,
        frequency = sgs.Skill_Limited,
        limit_mark = '@denglou',
        on_phasechange = function(self, player)
            local room = player:getRoom()
            if player:getPhase() == sgs.Player_Finish and player:isKongcheng() and player:getMark('@denglou') > 0 and
                room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:removePlayerMark(player, '@denglou')
                    local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                    local ids = sgs.IntList()
                    for _, id in sgs.qlist(room:getNCards(4, false)) do
                        if sgs.Sanguosha:getCard(id):isKindOf('BasicCard') then
                            ids:append(id)
                        else
                            dummy:addSubcard(id)
                        end
                    end
                    if dummy:subcardsLength() > 0 then
                        room:obtainCard(player, dummy, false)
                    end
                    if not ids:isEmpty() then
                        for _, id in sgs.qlist(ids) do
                            room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
                        end
                        room:setPlayerFlag(player, 'Fake_Move')
                        local _guojia = sgs.SPlayerList()
                        _guojia:append(player)
                        local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand,
                            sgs.CardMoveReason())
                        local moves = sgs.CardsMoveList()
                        moves:append(move)
                        room:notifyMoveCards(true, moves, false, _guojia)
                        room:notifyMoveCards(false, moves, false, _guojia)
                        room:setPlayerProperty(player, self:objectName(),
                            sgs.QVariant(table.concat(sgs.QList2Table(ids), '+')))
                        while room:askForUseCard(player, '@denglou', '@denglou') do
                            local invoke = false
                            for _, id in sgs.qlist(ids) do
                                local card = sgs.Sanguosha:getCard(id)
                                if card:hasFlag(self:objectName()) then
                                    invoke = true
                                end
                            end
                            if not invoke then
                                break
                            end
                        end
                        room:setTag(self:objectName(), sgs.QVariant())
                        local move_to = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
                            sgs.CardMoveReason())
                        local moves_to = sgs.CardsMoveList()
                        moves_to:append(move_to)
                        room:notifyMoveCards(true, moves_to, false, _guojia)
                        room:notifyMoveCards(false, moves_to, false, _guojia)
                        room:setPlayerFlag(player, '-Fake_Move')
                        local dumm = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, id in sgs.qlist(ids) do
                            local card = sgs.Sanguosha:getCard(id)
                            if card:hasFlag(self:objectName()) then
                                room:setCardFlag(card, '-' .. self:objectName())
                                dumm:addSubcard(card:getId())
                            end
                        end
                        room:throwCard(dumm, nil, player)
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
            return false
        end,
    }
wangcan:addSkill(denglou)
panjun = sgs.General(extension_star, 'panjun', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
guanwei = sgs.CreateTriggerSkill {
    name = 'guanwei',
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if player:getPhase() == sgs.Player_Play and not player:hasFlag(self:objectName() .. p:objectName()) and
                player:getMark('used_Play') > 1 and player:getMark('guanwei_break-Clear') == 0 and
                room:askForCard(p, '..', '@guanwei', data, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:setPlayerFlag(player, self:objectName() .. p:objectName())
                    player:drawCards(2, self:objectName())
                    local thread = room:getThread()
                    local change = sgs.PhaseChangeStruct()
                    change.from = sgs.Player_Play
                    change.to = sgs.Player_Play
                    local _data = sgs.QVariant()
                    _data:setValue(change)
                    room:broadcastProperty(player, 'phase')
                    if not thread:trigger(sgs.EventPhaseChanging, room, player, _data) then
                        if not thread:trigger(sgs.EventPhaseStart, room, player) then
                            thread:trigger(sgs.EventPhaseProceeding, room, player)
                        end
                        thread:trigger(sgs.EventPhaseEnd, room, player)
                    end
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
panjun:addSkill(guanwei)
gongqing = sgs.CreateTriggerSkill {
    name = 'gongqing',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:getAttackRange() < 3 and damage.damage > 1 then
            SendComLog(self, player, 1)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                damage.damage = 1
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        elseif damage.from and damage.from:getAttackRange() > 3 then
            SendComLog(self, player, 2)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                damage.damage = damage.damage + 1
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        data:setValue(damage)
        return false
    end,
}
panjun:addSkill(gongqing)
sp_pangtong = sgs.General(extension_star, 'sp_pangtong', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
guolunCard = sgs.CreateSkillCard {
    name = 'guolun',
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local id = room:askForCardChosen(source, targets[1], 'h', self:objectName())
            if id ~= -1 then
                room:showCard(targets[1], id)
                local card = room:askForCard(source, '..', '@guolun_choose', sgs.QVariant(), sgs.Card_MethodNone)
                if card then
                    local exchangeMove = sgs.CardsMoveList()
                    exchangeMove:append(sgs.CardsMoveStruct(card:getId(), targets[1], sgs.Player_PlaceHand,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), targets[1]:objectName(),
                            self:objectName(), '')))
                    exchangeMove:append(sgs.CardsMoveStruct(id, source, sgs.Player_PlaceHand, sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_SWAP, targets[1]:objectName(), source:objectName(), self:objectName(), '')))
                    room:moveCardsAtomic(exchangeMove, false)
                    if sgs.Sanguosha:getCard(id):getNumber() < card:getNumber() then
                        targets[1]:drawCards(1, self:objectName())
                    elseif sgs.Sanguosha:getCard(id):getNumber() > card:getNumber() then
                        source:drawCards(1, self:objectName())
                    end
                end
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
guolun = sgs.CreateZeroCardViewAsSkill {
    name = 'guolun',
    view_as = function()
        return guolunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#guolun')
    end,
}
sp_pangtong:addSkill(guolun)
songsang = sgs.CreateTriggerSkill {
    name = 'songsang',
    frequency = sgs.Skill_Limited,
    events = {sgs.Death},
    limit_mark = '@songsang',
    on_trigger = function(self, event, player, data, room)
        if player:getMark('@songsang') > 0 and data:toDeath().who:objectName() ~= player:objectName() and
            room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:removePlayerMark(player, '@songsang')
                if player:isWounded() then
                    room:recover(player, sgs.RecoverStruct(player))
                else
                    room:gainMaxHp(player)
                end
                room:acquireSkill(player, 'zhanji')
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
sp_pangtong:addSkill(songsang)
zhanji = sgs.CreateTriggerSkill {
    name = 'zhanji',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() and
            move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW and move.to_place == sgs.Player_PlaceHand and
            move.reason.m_skillName ~= self:objectName() and player:getPhase() == sgs.Player_Play then
            SendComLog(self, player)
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                player:drawCards(1, self:objectName())
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill('zhanji') then
    skills:append(zhanji)
end
sp_pangtong:addRelateSkill('zhanji')
sp_taishici = sgs.General(extension_star, 'sp_taishici', 'qun', '4', true, sgs.GetConfig('hidden_ai', true))
jixuCard = sgs.CreateSkillCard {
    name = 'jixu',
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName() and (#targets == 0 or to_select:getHp() == targets[1]:getHp())
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke(self:objectName(), 1)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            local slash = 'jixu_no'
            for _, card in sgs.qlist(source:getHandcards()) do
                if card:isKindOf('Slash') then
                    slash = 'jixu_yes'
                    break
                end
            end
            local n = 0
            for _, p in pairs(targets) do
                local choice = room:askForChoice(p, self:objectName(), 'jixu_yes+jixu_no')
                ChoiceLog(p, choice)
                if choice ~= slash then
                    room:addPlayerMark(p, slash .. '_Play')
                    n = n + 1
                end
            end
            for _, p in pairs(targets) do
                if slash == 'jixu_no' and p:getMark(slash .. '_Play') > 0 and source:canDiscard(p, 'he') then
                    local id = room:askForCardChosen(source, p, 'he', self:objectName(), false, sgs.Card_MethodDiscard)
                    if id ~= -1 then
                        room:throwCard(id, p, source)
                    end
                end
            end
            if n > 0 then
                source:drawCards(n, self:objectName())
            else
                room:setPlayerFlag(source, 'Global_PlayPhaseTerminated')
            end
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
jixuVS = sgs.CreateZeroCardViewAsSkill {
    name = 'jixu',
    view_as = function()
        return jixuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#jixu')
    end,
}
jixu = sgs.CreateTriggerSkill {
    name = 'jixu',
    view_as_skill = jixuVS,
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from:hasUsed('#' .. self:objectName()) and use.card and use.card:isKindOf('Slash') then
            room:broadcastSkillInvoke(self:objectName(), 2)
            for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
                if p:getMark('jixu_yes_Play') > 0 and not use.to:contains(p) and not room:isProhibited(use.from, p, use.card) then
                    room:doAnimate(1, use.from:objectName(), p:objectName())
                    use.to:append(p)
                end
            end
            room:sortByActionOrder(use.to)
            data:setValue(use)
        end
        return false
    end,
}
sp_taishici:addSkill(jixu)
zhoufang = sgs.General(extension_star, 'zhoufang', 'wu', 3, true, sgs.GetConfig('hidden_ai', true))
duanfaCard = sgs.CreateSkillCard {
    name = 'duanfa',
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, self:objectName() .. '_Play', self:subcardsLength())
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            source:drawCards(self:subcardsLength(), self:objectName())
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
duanfa = sgs.CreateViewAsSkill {
    name = 'duanfa',
    n = 999,
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMaxHp() - sgs.Self:getMark(self:objectName() .. '_Play') and to_select:isBlack()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local duanfacard = duanfaCard:clone()
            for _, card in pairs(cards) do
                duanfacard:addSubcard(card)
            end
            duanfacard:setSkillName(self:objectName())
            return duanfacard
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark(self:objectName() .. '_Play') < player:getMaxHp()
    end,
}
zhoufang:addSkill(duanfa)
ol_youdi = sgs.CreatePhaseChangeSkill {
    name = 'ol_youdi',
    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:canDiscard(player, 'h') then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local to = room:askForPlayerChosen(player, targets, self:objectName(), 'ol_youdi-invoke', true, true)
                if to then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, self:objectName() .. 'engine')
                    if player:getMark(self:objectName() .. 'engine') > 0 then
                        local id = room:askForCardChosen(to, player, 'h', self:objectName(), false, sgs.Card_MethodDiscard)
                        if id ~= -1 then
                            room:throwCard(sgs.Sanguosha:getCard(id), player, to)
                        end
                        if not to:isNude() and not sgs.Sanguosha:getCard(id):isKindOf('Slash') then
                            local _id = room:askForCardChosen(player, to, 'he', self:objectName())
                            if _id ~= -1 then
                                room:obtainCard(player, _id, false)
                            end
                        end
                        if not sgs.Sanguosha:getCard(id):isBlack() then
                            player:drawCards(1, self:objectName())
                        end
                        room:removePlayerMark(player, self:objectName() .. 'engine')
                    end
                end
            end
        end
        return false
    end,
}
zhoufang:addSkill(ol_youdi)
lvdai = sgs.General(extension_star, 'lvdai', 'wu', 4, true, sgs.GetConfig('hidden_ai', true))
qinguoCard = sgs.CreateSkillCard {
    name = 'qinguo',
    filter = function(self, targets, to_select)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        slash:setSkillName('_' .. self:objectName())
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, sgs.Self)
    end,
    on_use = function(self, room, source, targets)
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        if not targets_list:isEmpty() then
            room:broadcastSkillInvoke(self:objectName(), 1)
            room:addPlayerMark(source, self:objectName() .. 'engine')
            if source:getMark(self:objectName() .. 'engine') > 0 then
                local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                slash:setSkillName('_' .. self:objectName())
                room:useCard(sgs.CardUseStruct(slash, source, targets_list))
                room:removePlayerMark(source, self:objectName() .. 'engine')
            end
        end
    end,
}
qinguoVS = sgs.CreateZeroCardViewAsSkill {
    name = 'qinguo',
    view_as = function()
        return qinguoCard:clone()
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@qinguo'
    end,
}
qinguo = sgs.CreateTriggerSkill {
    name = 'qinguo',
    view_as_skill = qinguoVS,
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            room:setPlayerMark(player, self:objectName(), player:getEquips():length())
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) or
                (move.from and move.from:objectName() == player:objectName() and
                    move.from_places:contains(sgs.Player_PlaceEquip))) and player:getHp() == player:getEquips():length() and
                player:getEquips():length() ~= player:getMark(self:objectName()) and player:isWounded() and
                room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:recover(player, sgs.RecoverStruct(player))
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.CardFinished then
            if data:toCardUse().card:isKindOf('EquipCard') then
                room:askForUseCard(player, '@qinguo', '@qinguo')
            end
        end
        return false
    end,
}
lvdai:addSkill(qinguo)
liuyao = sgs.General(extension_star, 'liuyao', 'qun', 4, true, sgs.GetConfig('hidden_ai', true))
kannanCard = sgs.CreateSkillCard {
    name = 'kannan',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:canPindian(to_select, self:objectName()) and
                   to_select:getMark(self:objectName() .. '_Play') == 0
    end,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(targets[1], self:objectName() .. '_Play', 1)
        room:addPlayerMark(source, self:objectName() .. 'engine')
        if source:getMark(self:objectName() .. 'engine') > 0 then
            source:pindian(targets[1], self:objectName())
            room:removePlayerMark(source, self:objectName() .. 'engine')
        end
    end,
}
kannanVS = sgs.CreateZeroCardViewAsSkill {
    name = 'kannan',
    view_as = function()
        return kannanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes('#kannan') < player:getHp() and player:getMark(self:objectName() .. 'source_Play') == 0 and
                   player:canPindian()
    end,
}
kannan = sgs.CreateTriggerSkill {
    name = 'kannan',
    global = true,
    view_as_skill = kannanVS,
    events = {sgs.Pindian, sgs.CardUsed, sgs.ConfirmDamage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                local winner = nil
                if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
                    winner = pindian.to
                elseif pindian.from_card:getNumber() > pindian.to_card:getNumber() then
                    winner = pindian.from
                end
                if winner then
                    room:addPlayerMark(winner, '@kannanBuff')
                    if winner:objectName() == pindian.from:objectName() then
                        room:addPlayerMark(winner, self:objectName() .. 'source_Play')
                    end
                end
            end
        elseif event == sgs.CardUsed and player:getMark('@kannanBuff') > 0 then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                use.card:setTag('kannanBuffed', sgs.QVariant(player:getMark('@kannanBuff')))
                room:setPlayerMark(player, '@kannanBuff', 0)
            end
        elseif event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if damage.card and damage.card:getTag('kannanBuffed'):toInt() > 0 then
                local log = sgs.LogMessage()
                log.type = '$kannan'
                log.from = player
                log.card_str = damage.card:toString()
                log.arg = self:objectName()
                log.arg2 = damage.card:getTag('kannanBuffed'):toInt()
                room:sendLog(log)
                damage.damage = damage.damage + damage.card:getTag('kannanBuffed'):toInt()
                data:setValue(damage)
            end
            if damage.from and damage.to:getMark('wusheng-Clear' .. damage.from:objectName()) > 0 and damage.card and
                damage.card:isKindOf('Slash') and damage.card:getSuit() == sgs.Card_Heart then
                local log = sgs.LogMessage()
                log.type = '$kannan'
                log.from = player
                log.card_str = damage.card:toString()
                log.arg = 'yijue'
                log.arg2 = 1
                room:sendLog(log)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:getTag('kannanBuffed'):toInt() > 0 then
                use.card:removeTag('kannanBuffed')
            end
            if player:hasSkill('paoxiao') and use.card:isKindOf('Slash') then
                room:addPlayerMark(player, 'paoxiaoengine', 2)
                if player:getMark('paoxiaoengine') > 0 then
                    room:addPlayerMark(player, 'paoxiao_buff-Clear')
                    room:removePlayerMark(player, 'paoxiaoengine', 2)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
liuyao:addSkill(kannan)
lvqian = sgs.General(extension_star, 'lvqian', 'wei', 4, true, sgs.GetConfig('hidden_ai', true))
weilu = sgs.CreateTriggerSkill {
    name = 'weilu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:addPlayerMark(damage.from, self:objectName() .. player:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            local send = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark(self:objectName() .. player:objectName()) > 0 then
                    room:removePlayerMark(p, self:objectName() .. player:objectName())
                    local x = math.max(p:getHp() - 1, 0)
                    if x > 0 then
                        if not send then
                            send = true
                            room:sendCompulsoryTriggerLog(player, self:objectName())
                            room:broadcastSkillInvoke(self:objectName(), 2)
                        end
                        room:loseHp(p, x)
                        room:addPlayerMark(p, '@' .. self:objectName() .. '-Clear', x)
                    end
                end
            end
        end
        return false
    end,
}
lvqian:addSkill(weilu)
zengdaoCard = sgs.CreateSkillCard {
    name = 'zengdao',
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '!') then
            room:throwCard(sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, '', source:objectName(), self:objectName(), ''), nil)
        else
            room:addPlayerMark(player, self:objectName() .. 'engine')
            if player:getMark(self:objectName() .. 'engine') > 0 then
                room:removePlayerMark(source, '@donate')
                targets[1]:addToPile('sword', self)
                room:removePlayerMark(player, self:objectName() .. 'engine')
            end
        end
    end,
}
zengdaoVS = sgs.CreateViewAsSkill {
    name = 'zengdao',
    n = 999,
    expand_pile = 'sword',
    view_filter = function(self, selected, to_select)
        return (not string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '!') and to_select:isEquipped()) or
                   (string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), '!') and
                       sgs.Self:getPile('sword'):contains(to_select:getEffectiveId()))
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local skill_card = zengdaoCard:clone()
            for _, c in ipairs(cards) do
                skill_card:addSubcard(c)
            end
            skill_card:setSkillName(self:objectName())
            return skill_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, '@zengdao')
    end,
}
zengdao = sgs.CreateTriggerSkill {
    name = 'zengdao',
    limit_mark = '@donate',
    view_as_skill = zengdaoVS,
    frequency = sgs.Skill_Limited,
    global = true,
    events = {sgs.EventPhaseStart, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and RIGHT(self, player) and player:getPhase() == sgs.Player_Finish and
            player:getMark('@donate') > 0 and not player:getEquips():isEmpty() then
            room:askForUseCard(player, '@zengdao', '@zengdao', -1, sgs.Card_MethodNone)
        elseif event == sgs.DamageCaused and not player:getPile('sword'):isEmpty() then
            if not room:askForUseCard(player, '@zengdao!', '@zengdao', -1, sgs.Card_MethodNone) then
                room:throwCard(sgs.Sanguosha:getCard(player:getPile('sword'):first()), sgs.CardMoveReason(
                    sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, '', player:objectName(), self:objectName(), ''), nil)
            end
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
    end,
}
lvqian:addSkill(zengdao)
local sufei_k = {'qun', 'wu'}
sufei = sgs.General(extension_friend, 'sufei', sufei_k[math.random(1, 2)])
lianpian = sgs.CreateTriggerSkill {
    name = 'lianpian',
    global = true,
    events = {sgs.TargetSpecified, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            local invoke = false
            if not use.card:isKindOf('SkillCard') then
                for _, p in sgs.qlist(use.to) do
                    if p:getMark(self:objectName() .. player:objectName() .. '_Play') > 0 then
                        invoke = true
                        break
                    end
                end
            end
            for _, p in sgs.qlist(use.to) do
                if use.to:contains(p) then
                    room:addPlayerMark(p, self:objectName() .. player:objectName() .. '_Play')
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark(self:objectName() .. player:objectName() .. '_Play') > 0 and not use.to:contains(p) then
                    room:setPlayerMark(p, self:objectName() .. player:objectName() .. '_Play', 0)
                end
            end
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if invoke and player:getKingdom() == p:getKingdom() and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:doAnimate(1, p:objectName(), player:objectName())
                    player:drawCards(1, self:objectName())
                end
            end
        else
            local n = 0
            if event == sgs.CardUsed then
                n = data:toCardUse().to
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if n == 0 then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(self:objectName() .. player:objectName() .. '_Play') > 0 then
                        room:setPlayerMark(p, self:objectName() .. player:objectName() .. '_Play', 0)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sufei:addSkill(lianpian)
local huangquan_k = {'wei', 'shu'}
huangquan = sgs.General(extension_friend, 'huangquan', huangquan_k[math.random(1, 2)])
dianhu = sgs.CreateTriggerSkill {
    name = 'dianhu',
    events = {sgs.GameStart, sgs.Damaged},
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart and RIGHT(self, player) then
            local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), 'dianhu-invoke',
                false, sgs.GetConfig('face_game', true))
            if to then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:addPlayerMark(player, self:objectName() .. 'engine')
                if player:getMark(self:objectName() .. 'engine') > 0 then
                    room:addPlayerMark(to, '@aim')
                    room:addPlayerMark(to, 'aim' .. player:objectName())
                    room:removePlayerMark(player, self:objectName() .. 'engine')
                end
            end
        else
            local damage = data:toDamage()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:getMark('aim' .. p:objectName()) > 0 and player:isAlive() and damage.from:getKingdom() ==
                    p:getKingdom() and room:askForSkillInvoke(p, self:objectName(), data) then
                    SendComLog(self, p, 2)
                    damage.from:drawCards(damage.damage, self:objectName())
                end
            end
        end
        return false
    end,
}
huangquan:addSkill(dianhu)
jianjiCard = sgs.CreateSkillCard {
    name = 'jianji',
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        local card_ids = room:getNCards(1, false)
        local id = card_ids:first()
        if targets[1]:hasSkill('cunmu') then
            id = room:getDrawPile():last()
        end
        local moves = sgs.CardsMoveList()
        local move = sgs.CardsMoveStruct(card_ids, nil, targets[1], sgs.Player_DrawPile, sgs.Player_PlaceHand,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, targets[1]:objectName(), 'jianji', ''))
        moves:append(move)
        room:moveCardsAtomic(moves, false)
        if sgs.Sanguosha:getCard(id):isAvailable(source) then
            room:askForUseCard(targets[1], '' .. id, '@jianji')
        end
    end,
}
jianji = sgs.CreateZeroCardViewAsSkill {
    name = 'jianji',
    view_as = function(self)
        return jianjiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed('#jianji')
    end,
}
huangquan:addSkill(jianji)
sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
    ['extra'] = '额外区域',
    ['zhongcheng'] = '忠胆英杰',
    ['pigmonkey'] = '诸侯传',
    ['friend'] = '同舟共济',
    ['ol_heg'] = '国战OL',
    ['ol_sp'] = 'OL SP',
    ['god_po'] = '神话再临·破',
    ['god_ol'] = '神话再临OL',
    ['yijiang6'] = '原创之魂2016',
    ['yijiang7'] = '原创之魂2017',
    ['bianfeng'] = '边锋',
    ['ol_yijiang'] = '一将成名OL',
    ['mobile'] = '手机OL',
    ['ol_hulaoguan'] = '虎牢关',
    ['god_exam'] = '神之试炼',
    ['firexiongxiongxiong'] = '星火燎原',
    ['yin'] = '阴包',
    ['lei'] = '雷包',
    ['ChangeGeneral'] = '变更武将',
    ['shuijing_0'] = '武器',
    ['shuijing_1'] = '防具',
    ['shuijing_2'] = '+1坐骑',
    ['shuijing_3'] = '-1坐骑',
    ['shuijing_4'] = '宝物',
    ['h'] = '手牌',
    ['e'] = '装备区',
    ['j'] = '判定区',
    ['feng'] = '锋',
    ['@ranshang'] = '燃',
    ['@clock_time'] = '轮',
    ['@luanz'] = '乱',
    ['@Maxcards'] = '手牌上限',
    ['@Maxcards-Clear'] = '手牌上限',
    ['@Slash-Clear'] = '额外使用【杀】',
    ['@lixia'] = '距离-1',
    ['@biluan'] = '距离+1',
    ['@juesi'] = '请弃置一张牌<br/> <b>操作提示</b>: 选择一一张牌→点击确定<br/>',
    ['@jianshu'] = '你发动“间书”选择一名角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['@tiaodu'] = '你可以发动“调度”<br/> <b>操作提示</b>: 选择一张装备牌→点击确定<br/>',
    ['@yongjin'] = '请发动“旋略”',
    ['lixia1'] = '你摸一张牌',
    ['lixia2'] = '其摸一张牌',
    ['fengpo1'] = '摸X张牌',
    ['fengpo2'] = '此牌伤害值+X',
    ['danxin1'] = '摸一张牌',
    ['danxin2'] = '“矫诏”的描述中的“基本牌”改为“基本牌或非延时类锦囊牌”',
    ['danxin3'] = '“矫诏”的描述中的“与你距离最小的其他角色”改为“你”。',
    ['dingpan1'] = '令其弃置你装备区里的一张牌',
    ['dingpan2'] = '你获得装备区里的所有牌，其对你造成1点伤害',
    ['kuanggu1'] = '摸一张牌',
    ['kuanggu2'] = '回复1点体力',
    ['yinghun1'] = '令其摸一张牌，然后弃置X张牌',
    ['yinghun2'] = '令其摸X张牌，然后弃置一张牌',
    ['tianxiang1'] = '其摸X张牌',
    ['tianxiang2'] = '“天香”于你的下回合开始前无效且防止其你的回合开始造成或受到的伤害',
    ['shanjia_throw'] = '请弃置若干张牌',
    ['~shanjia'] = '选择若干张牌→点击确定',
    ['~ol_shensu1'] = '选择若干名角色→点击确定',
    ['~ol_shensu2'] = '选择一张装备牌→若干名角色→点击确定',
    ['~ol_shensu3'] = '选择若干名角色→点击确定',
    ['~luanzhan'] = '选择目标角色→点“确定”',
    ['~yongjin'] = '选择一张装备牌→选择一名角色→点击确定',
    ['~lizhan'] = '选择若干名角色→点击确定',
    ['~ol_jiewei'] = '选择一张牌→选择一名角色→点击确定',
    ['yaoming-invoke'] = '你可以发动“邀名”<br/> <b>操作提示</b>: 选择一名手牌数与你不同的角色→点击确定<br/>',
    ['yongdi-invoke'] = '你可以发动“拥嫡”<br/> <b>操作提示</b>: 选择一名男性角色→点击确定<br/>',
    ['tuifeng-invoke'] = '你可以将一张牌置于你的武将牌上称为“锋”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>',
    ['wanwei-invoke'] = '你可以发动“挽危”<br/> <b>操作提示</b>: 选择若干张牌→点击确定<br/>',
    ['hongde-invoke'] = '你可以发动“弘德”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['qizhi-invoke'] = '你可以发动“奇制”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['tiaodu-invoke'] = '你可以发动“调度”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['xuanlve-invoke'] = '你可以发动“烈风”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['yirang-invoke'] = '你可以发动“揖让”<br/> <b>操作提示</b>: 选择一名体力上限大于你的角色→点击确定<br/>',
    ['zhenjun-invoke'] = '你可以发动“镇军”<br/> <b>操作提示</b>: 选择一名手牌数大于体力值的角色→点击确定<br/>',
    ['qinqing-invoke'] = '你可以发动“寝情”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['shejian-invoke'] = '你可以发动“舌剑”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['shuimeng-invoke'] = '你可以发动“说盟”选择一名角色拼点<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['chouce-invoke'] = '你可以发动“筹策”选择一名角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['xianfu-invoke'] = '你可以发动“先辅”选择一名其他角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['@invoke'] = '你可以发动“%src”选择一名角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['$hanyong'] = '%from 执行“%arg”的效果，%card 的伤害值+1',
    ['$fengpo'] = '%from 执行“%arg”的效果，%card 的伤害值+%arg2',
    ['#choice'] = '%from 选择了 %arg',
    ['@she'] = '饶舌',
    ['@luanzhan'] = '你可以发动“乱战”',
    ['@zhige'] = '你可以使用【杀】，否则交给其一张装备区里的牌',
    ['@zhige_give'] = '请交给其一张装备区里的牌',
    ['@qizhi'] = '奇制',
    ['@ol_sidi'] = '你可以弃置一张牌对<font color="#00FF00"><b>%src </b></font> 发动“司敌”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>',
    ['@ol_zhongyong'] = '你可以发动“忠勇”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['@shenqu'] = '你可以发动“神躯”',
    ['@qianya'] = '你可以发动“谦雅”',
    ['@lianzhu'] = '你可以弃置两张牌，否则使用者摸两张牌。',
    ['@zhenjun'] = '你可以弃置一定数量的牌。<br/> <b>操作提示</b>: 选择若干张牌→点击确定<br/>',
    ['@wenji'] = '请交给其一张手牌',
    ['@lizhan'] = '你可以发动“励战”令若干名角色各摸一张牌',
    ['@extra_target'] = '',
    ['~extra_target'] = '选择若干名角色→点击确定',
    ['@throw_E'] = '请弃置一张装备牌',

    ['wutugu'] = '兀突骨',
    ['#wutugu'] = '霸体金刚',
    ['illustrator:wutugu'] = 'biou09&KayaK',
    ['ranshang'] = '燃殇',
    [':ranshang'] = '锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；锁定技，结束阶段开始时，你失去X点体力。（X为“燃”标记数）',
    ['$ranshang1'] = '战火燃尽英雄胆~',
    ['$ranshang2'] = '尔等竟如此歹毒！',
    ['hanyong'] = '悍勇',
    [':hanyong'] = '当你使用【南蛮入侵】或【万箭齐发】时，若你的体力值小于轮数，你可以令此牌的伤害值基数+1。',
    ['$hanyong1'] = '犯我者，杀！',
    ['$hanyong2'] = '藤甲军从无对手，不服来战！',
    ['~wutugu'] = '撤..快撤！',

    ['ol_quancong'] = '全琮',
    ['#ol_quancong'] = '白马王子',
    ['illustrator:ol_quancong'] = '东公子',
    ['yaoming'] = '邀名',
    [':yaoming'] = '每名角色的回合限一次，当你造成或受到伤害后，你可以选择一项：1.弃置一名手牌数大于你的角色一张手牌；2.令一名手牌数小于你的角色摸一张牌。',
    ['$yaoming1'] = '赈济百姓，何愁民心不归~',
    ['$yaoming2'] = '这~于你予我都是有利之势。',
    ['~ol_quancong'] = '患难可共济，生死不同等...',

    ['cuiyan'] = '崔琰',
    ['#cuiyan'] = '伯夷之风',
    ['illustrator:cuiyan'] = 'F.源',
    ['yawang'] = '雅望',
    [':yawang'] = '锁定技，摸牌阶段开始时，你放弃摸牌，然后摸X张牌，令你于此回合的出牌阶段内使用的牌数不大于X。（X为体力值与你相同的角色数）', -- ZY按：若X为3且你执行两个出牌阶段，第一个出牌阶段使用两张牌，第二个出牌阶段就只能使用一张牌了
    ['$yawang1'] = '琰，定不负诸位雅望。',
    ['$yawang2'] = '君子，当以正气，立于乱世！',
    ['ol_xunzhi'] = '殉志',
    [':ol_xunzhi'] = '准备阶段开始时，若你的上家与下家的体力值均与你不同，你可以失去1点体力，令你的手牌上限+2。',
    ['$ol_xunzhi1'] = '成大义者，这点儿牺牲，算不得什么！',
    ['$ol_xunzhi2'] = '春秋大业，自在我心！',
    ['~cuiyan'] = '尔等，尽是欺世盗名之辈......',

    ['ol_caoxiu'] = '曹休',
    ['#ol_caoxiu'] = '诸神的黄昏',
    ['illustrator:ol_caoxiu'] = '诸神黄昏',
    ['qianju'] = '千驹',
    [':qianju'] = '锁定技，你与其他角色的距离-X。（X为你已损失的体力值）',
    ['qingxi'] = '倾袭',
    [':qingxi'] = '当你使用【杀】对目标角色造成伤害时，若你的装备区里有武器牌，你可以令其选择一项：1.弃置X张牌，然后弃置你的武器牌；2.伤害值+1。（X为此武器牌的攻击范围）',
    ['$qingxi1'] = '你本领再高，也斗不过我的~',
    ['$qingxi2'] = '倾兵所有，袭敌不意！',
    ['~ol_caoxiu'] = '孤军深入，犯了兵家大忌！',

    ['ol_caorui'] = '曹叡',
    ['#ol_caorui'] = '魏明皇',
    ['illustrator:ol_caorui'] = '王立雄',
    ['ol_mingjian'] = '明鉴',
    [':ol_mingjian'] = '出牌阶段限一次，你可以将所有手牌交给一名角色，令其于其的下回合内使用【杀】的次数上限+1且手牌上限+1。',
    ['$ol_mingjian1'] = '以卿之才学，何愁此战不胜？',
    ['$ol_mingjian2'] = '用人自当不疑，卿大可放心！',
    ['~ol_caorui'] = '愧为人主，何颜见父......',

    ['ol_shixie'] = '士燮',
    ['#ol_shixie'] = '雄长百越',
    ['illustrator:ol_shixie'] = '銘zmy',
    ['ol_biluan'] = '避乱',
    [':ol_biluan'] = '摸牌阶段开始时，若有角色与你的距离为1，你可以放弃摸牌，若如此做，其他角色与你的距离+X。（X为势力数）',
    ['$ol_biluan1'] = '身处乱世，自保足矣~',
    ['$ol_biluan2'] = '避一时之乱，求长世安稳~',
    ['ol_lixia'] = '礼下',
    [':ol_lixia'] = '锁定技，其他角色的结束阶段开始时，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.其摸一张牌。若如此做，其他角色与你的距离-1。',
    ['$ol_lixia1'] = '将军，真乃国之栋梁~',
    ['$ol_lixia2'] = '英雄可安身立命于交州之地~',

    ['super_liubei'] = '刘备',
    ['#super_liubei'] = '乱世的枭雄',
    ['illustrator:super_liubei'] = '木美人',
    ['ol_rende'] = '仁德',
    [':ol_rende'] = '出牌阶段，你可以将至少一张手牌交给一名角色，然后你于此阶段内不能以此法交给其手牌，若你以此法交给其他角色的手牌数不小于2，你可以视为使用任意一种基本牌（每阶段限一次）。',
    ['$ol_rende1'] = '仁德之君，则所向披靡也',
    ['$ol_rende2'] = '上报国家，下安黎庶',
    ['~super_liubei'] = '大业未成，心有不甘呐~',

    ['ol_lidian'] = '李典',
    ['#ol_lidian'] = '功在青州',
    ['cv:ol_lidian'] = '黑冰',
    ['illustrator:ol_lidian'] = 'zero',
    ['ol_xunxun'] = '恂恂',
    [':ol_xunxun'] = '摸牌阶段开始时，你可以观看牌堆顶四张牌，将其中两张牌置于牌堆顶，其余两张牌置于牌堆底。',
    ['$ol_xunxun1'] = '大将之范，当有恂恂之风。',
    ['$ol_xunxun2'] = '矜严重礼，进退恂恂。',
    ['$wangxi_ol_lidian1'] = '典岂可因私憾而忘公义？',
    ['$wangxi_ol_lidian2'] = '义忘私隙，端国正己。',
    ['~ol_lidian'] = '隙仇俱忘，怎奈……',

    --[[['ol_jiangwanfeiyi'] = '蒋琬&费祎',
    ['#ol_jiangwanfeiyi'] = '社稷股肱',
    ['ol_shengxi'] = '生息',
    [':ol_shengxi'] = '弃牌阶段开始时，若你于此回合内未造成过伤害，你可以摸两张牌。',
    ['$ol_shengxi1'] = '国之生计，在民生息。',
    ['$ol_shengxi2'] = '安民止战，兴汉室！',
    ['$shoucheng1'] = '大汉羸弱，唯有守成，方有生机。',
    ['$shoucheng2'] = '待吾等助将军一臂之力！',
    ['~ol_jiangwanfeiyi'] = '墨守成规，终为其害啊。',]] --

    ['ol_caozhen'] = '曹真',
    ['#ol_caozhen'] = '荷国天督',
    ['illustrator:ol_caozhen'] = '',
    ['ol_sidi'] = '司敌',
    [':ol_sidi'] = '其他角色的出牌阶段开始时，你可以弃置与装备区里的牌颜色相同的一张不为基本牌的牌，其于此回合内不能使用和打出与之颜色相同的牌，若如此做，此阶段结束时，若其未于此阶段内使用过【杀】，你视为对其使用【杀】。',
    ['$ol_sidi1'] = '',
    ['$ol_sidi2'] = '',
    ['~ol_caozhen'] = '...',

    ['ol_zhoucang'] = '周仓',
    ['#ol_zhoucang'] = '披肝沥胆',
    ['illustrator:ol_zhoucang'] = '',
    ['ol_zhongyong'] = '忠勇',
    [':ol_zhongyong'] = '当你使用的【杀】结算完毕后，你可以将此【杀】或目标角色使用的【闪】交给其以外的一名其他角色，若其中有红色牌，其可以对你攻击范围内的角色使用【杀】。',
    ['$ol_zhongyong1'] = '',
    ['$ol_zhongyong2'] = '',
    ['~ol_zhoucang'] = '...',

    ['ol_zumao'] = '祖茂',
    ['#ol_zumao'] = '碧血染赤帻',
    ['illustrator:ol_zumao'] = '',
    ['ol_juedi'] = '绝地',
    ['@ol_juedi'] = '你可以发动“绝地”<br/> <b>操作提示</b>: 选择一名角色（若选择的角色为你，执行选项1，不为你，执行选项2）→点击确定<br/>',
    [':ol_juedi'] = '锁定技，准备阶段开始时，你选择一项：1．将所有“帻”置入弃牌堆，然后将手牌补至体力上限；2．将所有“帻”交给体力值不大于你的一名其他角色，若如此做，其回复1点体力，摸等量的牌。',
    ['$ol_juedi1'] = '',
    ['$ol_juedi2'] = '',
    ['~ol_zumao'] = '...',

    ['bf_xunyou'] = '荀攸',
    ['#bf_xunyou'] = '曹魏的谋主', -- 编一个
    ['illustrator:bf_xunyou'] = '心中一凛',
    ['bf_qice'] = '奇策',
    [':bf_qice'] = '出牌阶段限一次，你可以将所有手牌当目标数不大于X的非延时类锦囊牌使用，若如此做，你可以变更武将牌。',
    ['$bf_qice1'] = '',
    ['$bf_qice2'] = '',
    ['~bf_xunyou'] = '',

    ['bianhuanghou'] = '卞夫人',
    ['#bianhuanghou'] = '奕世之雍容',
    ['illustrator:bianhuanghou'] = '雪君S',
    ['wanwei'] = '挽危',
    ['@wanwei'] = '请弃置等量的牌',
    [':wanwei'] = '你可以选择被其他角色弃置或获得的牌。',
    ['$wanwei1'] = '',
    ['$wanwei2'] = '',
    ['yuejian'] = '约俭',
    [':yuejian'] = '一名角色的弃牌阶段开始时，若其于此回合内未使用过确定目标包括除其和你外的角色的牌，你可以令其于此回合内手牌上限视为体力上限。',
    ['$yuejian1'] = '',
    ['$yuejian2'] = '',
    ['~bianhuanghou'] = '',

    ['bf_masu'] = '马谡',
    ['#bf_masu'] = '帷幄经谋',
    ['illustrator:bf_masu'] = '蚂蚁君',
    ['bf_zhiman'] = '制蛮',
    [':bf_zhiman'] = '当你对其他角色造成伤害时，你可以防止此伤害，获得其装备区或判定区里的一张牌，然后其可以变更武将牌。',
    ['$bf_zhiman1'] = '',
    ['$bf_zhiman2'] = '',
    ['~bf_masu'] = '',

    ['shamoke'] = '沙摩柯',
    ['#shamoke'] = '五溪蛮王',
    ['illustrator:shamoke'] = 'LiuHeng',
    ['bf_jili'] = '蒺藜',
    [':bf_jili'] = '当你于一名角色的回合内使用或打出第X张牌时，你可以摸X张牌。（X为你的攻击范围）',
    ['$bf_jili1'] = '',
    ['$bf_jili2'] = '',
    ['~shamoke'] = '',

    ['bf_lingtong'] = '凌统',
    ['#bf_lingtong'] = '豪情烈胆',
    ['illustrator:bf_lingtong'] = 'F.源',
    ['xuanlve'] = '旋略',
    [':xuanlve'] = '当你失去装备区里的牌后，你可以弃置一名其他角色一张牌。',
    ['$xuanlve1'] = '',
    ['$xuanlve2'] = '',
    ['yongjin'] = '勇进',
    [':yongjin'] = '限定技，出牌阶段，你可以获得场上的最多三张装备区里的牌，然后将这些牌置入一至三名角色的装备区。',
    ['$yongjin1'] = '',
    ['$yongjin2'] = '',
    ['~bf_lingtong'] = '',

    ['lvfan'] = '吕范',
    ['#lvfan'] = '忠笃亮直',
    ['illustrator:lvfan'] = '銘zmy',
    ['tiaodu'] = '调度',
    [':tiaodu'] = '出牌阶段限一次，你可以选择包括你在内的至少一名角色，这些角色各可以选择一项：1.使用装备牌；2.将装备区里的一张牌置入一名角色的装备区内。',
    ['$tiaodu1'] = '',
    ['$tiaodu2'] = '',
    ['diancai'] = '典财',
    [':diancai'] = '其他角色的出牌阶段结束时，若你于此阶段内失去过至少X张牌，你可以将手牌补至上限，然后可以变更武将牌。（X为你的体力值）',
    ['$diancai1'] = '',
    ['$diancai2'] = '',
    ['~lvfan'] = '',

    ['lijueguosi'] = '李傕&郭汜',
    ['#lijueguosi'] = '犯祚倾祸',
    ['illustrator:lijueguosi'] = '旭',
    ['cv:lijueguosi'] = '《三国演义》',
    ['xiongsuan'] = '凶算',
    [':xiongsuan'] = '限定技，出牌阶段，你可以弃置一张牌并选择一名角色，对其造成1点伤害，然后你摸三张牌，若其拥有限定技，你可以令其中一个限定技于此回合结束后视为未发动。',
    ['$xiongsuan1'] = '让他看看我的箭法~',
    ['$xiongsuan2'] = '我们是太师的人，太师不平反，我们就不能名正言顺！ 郭将军所言极是！',
    ['~lijueguosi'] = '李傕郭汜二贼火拼，两败俱伤~',

    ['bf_zuoci'] = '左慈',
    ['#bf_zuoci'] = '迷之仙人', -- 编一个
    ['illustrator:bf_zuoci'] = '吕阳',
    ['bf_huashen'] = '化身',
    [':bf_huashen'] = '准备阶段开始时，若“化身”数：小于2，你可以观看武将牌堆顶五张牌，将其中一至两张牌扣置于你的武将牌上，称为“化身”；\
    不小于2，你可以观看武将牌堆顶一张牌，然后将之与其中一张“化身”替换。你可以发动“化身”拥有的技能（除锁定技、转换技、限定技、觉醒技、主公技），若如此做，将那张武将牌置入武将牌堆。',
    ['$bf_huashen1'] = '为仙之道,飘渺莫测~',
    ['$bf_huashen2'] = '仙人之力,昭于世间~',
    ['bf_xinsheng'] = '新生',
    [':bf_xinsheng'] = '当你受到伤害后，你可以将武将牌堆顶一张牌扣置于武将牌上，称为“化身”。',
    ['$bf_xinsheng1'] = '感觉到了新的魂魄~',
    ['$bf_xinsheng2'] = '神光不灭,仙力不绝~',
    ['~bf_zuoci'] = '仙人转世，一去无返',

    ['caochun'] = '曹纯',
    ['#caochun'] = '虎豹骑首',
    ['illustrator:caochun'] = 'depp',
    ['shanjia'] = '缮甲',
    [':shanjia'] = '出牌阶段开始时，你可以摸X张牌，然后弃置X张牌，若你以此法弃置了装备区里的牌，你视为使用【杀】（不计入使用次数限制）。（X为你使用过的装备牌数且至多为7）',
    ['$shanjia1'] = '',
    ['$shanjia2'] = '',
    ['~caochun'] = '',

    ['wangji'] = '王基',
    ['#wangji'] = '经行合一',
    ['designer:wangji'] = '韩旭',
    ['illustrator:wangji'] = '雪君S',
    ['qizhi'] = '奇制',
    [':qizhi'] = '当你于回合内使用基本牌或锦囊牌指定目标后，你可以选择一名不是此牌目标且有牌的角色，弃置其一张牌，然后其摸一张牌。',
    ['$qizhi1'] = '声东击西，敌寇一网成擒！',
    ['$qizhi2'] = '吾意不在此地，已遣别部出发。',
    ['jinqu'] = '进趋',
    [':jinqu'] = '结束阶段开始时，你可以摸两张牌，然后将手牌弃至X张。（X为你于此回合内发动“奇制”的次数）',
    ['$jinqu1'] = '建上昶水城，以逼夏口！',
    ['$jinqu2'] = '通川聚粮，伐吴之业，当步步为营。',
    ['~wangji'] = '天下之势，必归大魏，可恨，未能得见啊。',

    ['guansuo'] = '关索',
    ['#guansuo'] = '倜傥孑侠',
    ['illustrator:guansuo'] = 'depp',
    ['zhengnan'] = '征南',
    [':zhengnan'] = '当其他角色死亡后，你可以摸三张牌，然后获得一个技能：武圣；制蛮；当先。',
    ['$zhengnan1'] = '末将愿承父志，随丞相出征~',
    ['$wusheng8'] = '逆贼！可识得关氏之勇！',
    ['$zhiman3'] = '蛮夷可抚，不能剿。',
    ['$dangxian3'] = '各位将军，且让小辈先行出战！',
    ['xiefang'] = '撷芳',
    [':xiefang'] = '锁定技，你与其他角色距离-X。（X为女性角色数）',
    ['~guansuo'] = '只恨天下未平，空留遗志~',

    ['yanbaihu'] = '严白虎',
    ['#yanbaihu'] = '豺牙落涧',
    ['illustrator:yanbaihu'] = 'NOVART',
    ['zhidao'] = '雉盗',
    [':zhidao'] = '锁定技，当你于出牌阶段内第一次对其他角色造成伤害后，你获得其每个区里各一张牌，然后令其他角色不是你于此回合内使用牌的合法目标。',
    ['$zhidao1'] = '谁有地盘，谁是老大！',
    ['$zhidao2'] = '乱世之中，能者为王！',
    ['jili'] = '寄篱',
    [':jili'] = '锁定技，当其他角色成为其他角色使用红色基本牌或红色非延时类锦囊的目标时，若目标没有你且其与你的距离为1，你也成为此牌的目标。',
    ['$jili1'] = '寄人篱下的日子，不好过啊~',
    ['$jili2'] = '这份恩德，白虎记下了~',
    ['~yanbaihu'] = '严舆吾弟，为兄来陪你了~',

    ['tadun'] = '蹋顿',
    ['#tadun'] = '北狄王',
    ['illustrator:tadun'] = 'NOVART',
    ['luanzhan'] = '乱战',
    [':luanzhan'] = '当一名角色因受到伤害而扣减体力后，若来源为你，你获得1枚“乱”标记；你使用【杀】或黑色非延时类锦囊牌的目标上限+X；当你使用【杀】或黑色非延时类锦囊牌指定目标后，若目标数小于X，你弃所有“乱”标记。（X为“乱”标记数）',
    ['$luanzhan1'] = '现，正是我乌桓崛起之机！',
    ['$luanzhan2'] = '受袁氏大恩，当效死力！',
    ['~tadun'] = '呃~不该~趟曹袁之争的浑水~',

    ['liuyu'] = '刘虞',
    ['#liuyu'] = '甘棠永固',
    ['illustrator:liuyu'] = '尼乐小丑',
    ['designer:liuyu'] = '冰眼',
    ['zhige'] = '止戈',
    [':zhige'] = '出牌阶段限一次，若你的手牌数大于体力值，你可以选择一名攻击范围内有你的角色，令其选择是否使用【杀】，若其选择否，其将装备区里的一张牌交给你。',
    ['$zhige1'] = '天下和，而平乱~ 神器宁，而止戈~',
    ['$zhige2'] = '刀兵纷争即止，国运福祚绵长~',
    ['zongzuo'] = '宗祚',
    [':zongzuo'] = '锁定技，游戏开始时，你加X点体力上限，然后回复X点体力；锁定技，当一名角色死亡后，若没有与其势力相同的角色，你减1点体力上限。（X为势力数）',
    ['$zongzuo1'] = '尽死生之力，保大厦不倾~',
    ['$zongzuo2'] = '乾坤倒，黎民苦，高祖后，岂任之？',
    ['~liuyu'] = '怀柔之计，终非良策~',

    ['sundeng'] = '孙登',
    ['#sundeng'] = '才高德茂',
    ['illustrator:sundeng'] = 'DH',
    ['designer:sundeng'] = '过客',
    ['kuangbi'] = '匡弼',
    ['@kuangbi'] = '请选择一至三张牌',
    ['kuang'] = '辅',
    [':kuangbi'] = '出牌阶段限一次，你可以选择一名有牌的角色，其将一至三张牌置于你的武将牌上，称为“辅”，若如此做，回合开始时，你获得所有“辅”，其摸等量的牌',
    ['$kuangbi1'] = '匡人助己，辅政弼贤',
    ['$kuangbi2'] = '兴隆大化，佐理时务',
    ['~sundeng'] = '愿陛下留意听采，儿臣虽死犹生~',

    ['liyan'] = '李严',
    ['#liyan'] = '矜风流务',
    ['illustrator:liyan'] = '米SIR',
    ['designer:liyan'] = 'RP',
    ['duliang'] = '督粮',
    ['duliang1'] = '令其观看牌堆顶两张牌，然后展示并获得其中的所有基本牌',
    ['duliang2'] = '令其于下个摸牌阶段多摸一张牌',
    [':duliang'] = '出牌阶段限一次，你可以获得一名角色一张手牌，然后选择一项：1.令其观看牌堆顶两张牌，然后获得其中的基本牌；2.令其于其下个摸牌阶段内的额定摸牌数+1。',
    ['$duliang1'] = '粮草已到，请将军验看~',
    ['$duliang2'] = '告诉丞相，山路难走，请宽限几天~',
    ['fulin'] = '腹鳞',
    [':fulin'] = '锁定技，你于此回合获得的手牌于弃牌阶段内不计入手牌数且不能弃置。',
    ['$fulin1'] = '丞相！丞相！你们没看见我吗！',
    ['$fulin2'] = '我乃托孤忠臣，却在这儿搞什么粮草！',
    ['~liyan'] = '孔明这一走，我算是没指望了！',

    ['guohuanghou'] = '郭皇后',
    ['#guohuanghou'] = '月华驱霾',
    ['illustrator:guohuanghou'] = '樱花闪乱',
    ['designer:guohuanghou'] = '杰米Y',
    ['jiaozhao'] = '矫诏',
    [':jiaozhao'] = '出牌阶段限一次，你可以展示一张手牌并选择一名与你距离最近的其他角色，令其声明任意一种基本牌，然后你可以于回合内将之当其声明的牌使用且你不是以此法转化的牌的合法目标。',
    [':jiaozhao1'] = '出牌阶段限一次，你可以展示一张手牌并选择一名与你距离最近的其他角色，令其声明任意一种基本牌或非延时类锦囊牌，然后你可以于回合内将之当其声明的牌使用且你不是以此法转化的牌的合法目标。',
    [':jiaozhao2'] = '出牌阶段限一次，你可以展示一张手牌并声明任意一种基本牌或非延时类锦囊牌，然后你可以于回合内将之当其声明的牌使用且你不是以此法转化的牌的合法目标。',
    ['$jiaozhao1'] = '诏书在此，不得放肆！',
    ['$jiaozhao2'] = '妾身也是逼不得已，方才出此下策~',
    ['danxin'] = '殚心',
    [':danxin'] = '当你受到伤害后，你可以选择一项：1.摸一张牌；2.“矫诏”的描述中的“基本牌”改为“基本牌或非延时类锦囊牌”，然后令此选项改为““矫诏”的描述中的“与你距离最近的其他角色”改为“你””。',
    [':danxin1'] = '当你受到伤害后，你可以选择一项：1.摸一张牌；2.“矫诏”的描述中的“与你距离最近的其他角色”改为“你”。',
    [':danxin2'] = '当你受到伤害后，你可以摸一张牌。',
    ['$danxin1'] = '司马一族，其心可诛！',
    ['$danxin2'] = '妾身，定为我大魏，鞠躬尽瘁，死而后已~',
    ['~guohuanghou'] = '陛下，臣妾这就来见你~',

    ['cenhun'] = '岑昏',
    ['#cenhun'] = '伐梁倾瓴',
    ['illustrator:cenhun'] = '心中一凛',
    ['designer:cenhun'] = '韩旭',
    ['jishe'] = '极奢',
    ['jishe_chained'] = '极奢',
    ['@jishe'] = '你可以发动“极奢”',
    ['~jishe'] = '选择若干名角色→点击确定',
    [':jishe'] = '出牌阶段，若你的手牌上限大于0，你可以摸一张牌，若如此做，你于此回合内手牌上限-1；结束阶段开始时，若你没有手牌，你可以横置至多X名角色。（X为你的体力值）',
    ['$jishe1'] = '孙吴正当盛世，兴些土木又何妨~',
    ['$jishe2'] = '当再建新殿，扬我国威！',
    ['lianhuo'] = '链祸',
    [':lianhuo'] = '锁定技，当你受到火焰伤害时，若你处于连环状态且此伤害不为传导伤害，伤害值+1。',
    ['$lianhuo1'] = '用那剩下的铁石，正好做些工事！',
    ['$lianhuo2'] = '筑下这铁链，江东天险牢不可破！',
    ['~cenhun'] = '我为主上出过力！！！呃啊~',

    ['huanghao'] = '黄皓',
    ['#huanghao'] = '便辟佞慧',
    ['illustrator:huanghao'] = '2B铅笔',
    ['designer:huanghao'] = '凌天翼',
    ['qinqing'] = '寝情',
    ['@qinqing'] = '你可以发动“寝情”',
    ['~qinqing'] = '选择若干名角色→点击确定',
    ['$qinqing1'] = '陛下勿忧~大将军危言耸听~',
    ['$qinqing2'] = '陛下，莫让他人知晓此事！',
    ['huisheng'] = '贿生',
    ['@huisheng'] = '你可以展示至少一张牌',
    ['@@huisheng!'] = '你可以获得展示的一张牌，或者弃置展示数量的牌',
    ['~huisheng'] = '选择若干张牌→点击确定',
    ['$huisheng1'] = '大人~这些钱···够吗？',
    ['$huisheng2'] = '嗯哼哼~~劳烦大人美言几句',
    ['~huanghao'] = '魏军竟然真杀来了！',

    ['sunziliufang'] = '孙资&刘放',
    ['#sunziliufang'] = '服馋搜慝',
    ['illustrator:sunziliufang'] = '怪僧',
    ['designer:sunziliufang'] = 'Rivers',
    ['guizao'] = '瑰藻',
    ['guizao1'] = '摸一张牌',
    ['guizao2'] = '回复1点体力',
    [':guizao'] = '弃牌阶段结束时，若你于此阶段内弃置过至少两张手牌且这些牌花色均不同，你可以选择一项：1.摸一张牌；2.回复1点体力。',
    ['$guizao1'] = '这都是陛下的恩泽啊~',
    ['$guizao2'] = '陛下盛宠，臣万莫敢忘~',
    ['jiyu'] = '讥谀',
    ['@jiyu'] = '请弃置一张手牌',
    [':jiyu'] = '出牌阶段，若你有于出牌阶段空闲时间点可以使用且有合法目标的手牌，你可以选择一名于此阶段内未成为过此技能目标的角色，令其弃置一张手牌，然后你于此回合内不能使用与之相同花色的牌，若之花色为黑桃，你翻面，其失去1点体力。',
    ['$jiyu1'] = '陛下，此人不堪大用！',
    ['$jiyu2'] = '尔等玩忽职守，依诏降职处置~',
    ['~sunziliufang'] = '唉！树倒猢狲散，鼓破众人捶啊！',

    ['zhangrang'] = '张让',
    ['#zhangrang'] = '窃幸绝禋',
    ['illustrator:zhangrang'] = '蚂蚁君',
    ['designer:zhangrang'] = '千幻',
    ['taoluan'] = '滔乱',
    ['@taoluan'] = '请选择目标',
    ['~taoluan'] = '选择若干名角色→点击确定',
    ['@taoluan-ask'] = '请选择一名其他角色',
    ['@taoluan-give'] = '请交出你的一张手牌',
    [':taoluan'] = '你可以将一张牌当一种未以此法使用过的基本牌或非延时类锦囊牌使用，然后选择一名其他角色，其选择一项：1.交给你一张与之类别不同的牌2.令你失去1点体力且“滔乱”于此回合内无效。',
    ['$taoluan1'] = '睁开你的眼睛看看，现在，是谁说了算',
    ['$taoluan2'] = '国家承平，神气稳固，陛下勿忧~',
    ['~zhangrang'] = '臣等殄灭，唯陛下自爱~~~~~噗......',

    ['wanglang'] = '王朗',
    ['#wanglang'] = '凤鹛',
    ['illustrator:wanglang'] = '銘zmy',
    ['gushe'] = '鼓舌',
    ['@gushepindian'] = '请选择一张手牌进行拼点',
    [':gushe'] = '出牌阶段限一次，你可以用一张拼点牌与三名角色拼点：没赢的角色选择是否弃置一张牌，若其选择否，你摸一张牌。若如此做且其为你，你获得1枚“饶舌”标记；当你拥有7枚“饶舌”标记时，你死亡。',
    ['$gushe1'] = '公既知天命，识时务，为何要兴无名之师？犯我疆界？',
    ['$gushe2'] = '你若倒戈卸甲，以礼来降，仍不失封侯之位，国安民乐，岂不美哉？',
    ['jici'] = '激词',
    [':jici'] = '当你因“鼓舌”而拼点的牌亮出后，若点数：小于X，你可以令此牌的点数于此次拼点中+X；等于X，令“鼓舌”于此回合内发动次数上限+1。（X为“饶舌”标记数）',
    ['$jici1'] = '谅尔等腐草之荧光，如何比得上天空之皓月~',
    ['$jici2'] = '你……诸葛村夫，你敢……',
    ['~wanglang'] = '你、你……啊……',

    ['ol_machao'] = '马超',
    ['#ol_machao'] = '西凉的猛狮',
    ['illustrator:ol_machao'] = '',
    ['ol_zhuiji'] = '追击',
    [':ol_zhuiji'] = '锁定技，你与体力值不大于你的角色的距离视为1。',
    ['$ol_zhuiji1'] = '',
    ['$ol_zhuiji2'] = '',
    ['ol_shichou'] = '誓仇',
    [':ol_shichou'] = '你使用【杀】的目标上限+X（X为你已损失的体力值）。',
    ['$ol_shichou1'] = '灭族之恨，不共戴天！',
    ['$ol_shichou2'] = '休想跑~',
    ['~ol_machao'] = '西凉~~~回不去了......',

    ['ol_pangde'] = '庞德',
    ['#ol_pangde'] = '抬榇之悟',
    ['illustrator:ol_pangde'] = '',
    ['juesi'] = '决死',
    [':juesi'] = '出牌阶段，你可以弃置一张【杀】并选择一名攻击范围内有牌的角色，其弃置一张牌，若之不为【杀】且你的体力值不大于其，你视为对其使用【决斗】。',
    ['$juesi1'] = '死都不怕，还能怕你？',
    ['$juesi2'] = '抬棺而战，不死不休~',
    ['~ol_pangde'] = '受魏王厚恩，唯以死报之~',

    ['ol_jiaxu'] = '贾诩',
    ['#ol_jiaxu'] = '算无遗策',
    ['illustrator:ol_jiaxu'] = '',
    ['zhenlve'] = '缜略',
    [':zhenlve'] = '锁定技，你使用非延时类锦囊牌不能被【无懈可击】响应；锁定技，你不是延时类锦囊牌的合法目标。',
    ['$zhenlve1'] = '',
    ['$zhenlve2'] = '',
    ['jianshu'] = '间书',
    [':jianshu'] = '限定技， 出牌阶段，你可以将一张黑色手牌交给一名角色并令其与由你选择的一名攻击范围内有其的其他角色拼点：赢的角色弃置两张牌，没赢的角色失去1点体力。',
    ['$jianshu1'] = '纵有千军万马，离心，则难成大事~',
    ['$jianshu2'] = '来~让我看一出好戏吧~',
    ['yongdi'] = '拥嫡',
    [':yongdi'] = '限定技， 当你受到伤害后，你可以选择一名其他男性角色，令其加1点体力上限，然后若其不为主公且其武将牌上有主公技，其获得此主公技。',
    ['$yongdi1'] = '臣，愿为世子，肝脑涂地~',
    ['$yongdi2'] = '嫡庶有别~尊卑有序~',
    ['~ol_jiaxu'] = '立嫡之事，真是取祸之道！',

    ['litong'] = '李通',
    ['#litong'] = '万亿吾独往',
    ['illustrator:litong'] = ' 瞎子Ghe',
    ['tuifeng'] = '推锋',
    [':tuifeng'] = '当你受到1点伤害后，你可以将一张牌扣置于武将牌上，称为“锋”；准备阶段开始时，你将所有“锋”置入弃牌堆，摸2X张牌，令你于此回合内使用【杀】的次数上限+X。（X为你以此法置入弃牌堆的牌数）',
    ['$tuifeng1'] = '摧锋陷阵，以杀贼首！',
    ['$tuifeng2'] = '敌锋之锐，我已尽知。',
    ['~litong'] = '战死沙场，快哉！',

    ['mizhu'] = '糜竺',
    ['#mizhu'] = '挥金追义',
    ['illustrator:mizhu'] = '瞎子Ghe',
    ['ziyuan'] = '资援',
    [':ziyuan'] = '出牌阶段限一次，你可以将至少一张点数之和为13的手牌交给一名角色，然后其回复1点体力。',
    ['$ziyuan1'] = '区区薄礼，万望使君笑纳~',
    ['$ziyuan2'] = '雪中送炭，以解君愁。',
    ['jugu'] = '巨贾',
    [':jugu'] = '锁定技，你的起始手牌数+X；锁定技，你的手牌上限+X。（X为你的体力上限）',
    ['$jugu1'] = '钱~要多少有多少！',
    ['$jugu2'] = '君子爱财，取之有道~',
    ['~mizhu'] = '劣弟背主，我之罪也~',

    ['buzhi'] = '步骘',
    ['#buzhi'] = '积硅靖边',
    ['illustrator:buzhi'] = 'sinno',
    ['hongde'] = '弘德',
    [':hongde'] = '当你获得或失去至少两张牌后，你可以选择一名其他角色，令其摸一张牌。',
    ['$hongde1'] = '德无单行，福必双至。',
    ['$hongde2'] = '江南重义，东吴尚德。',
    ['dingpan'] = '定叛',
    [':dingpan'] = '<font color="green"><b>出牌阶段限X次，</b></font>你可以选择装备区里有牌的一名角色，令其摸一张牌，然后其选择一项：\
    1.令你弃置其装备区里的一张牌；2.其获得其装备区里的所有牌，你对其造成1点伤害。（X为反贼数）',
    ['$dingpan1'] = '从孙者生，从刘者死！',
    ['$dingpan2'] = '多行不义，必自毙！',
    ['~buzhi'] = '交州已定，主公~尽可放心......',

    ['ol_xiahouyuan'] = '夏侯渊',
    ['#ol_xiahouyuan'] = '疾行的猎豹',
    ['illustrator:ol_xiahouyuan'] = '',
    ['ol_shensu'] = '神速',
    [':ol_shensu'] = '你可以：跳过判定阶段和摸牌阶段；弃置一张装备牌并跳过出牌阶段；跳过弃牌阶段并翻面。若如此做，视为使用【杀】（无距离限制）。',
    ['$ol_shensu1'] = '',
    ['$ol_shensu2'] = '',
    ['~ol_xiahouyuan'] = '',

    ['ol_weiyan'] = '魏延',
    ['#ol_weiyan'] = '嗜血的独狼',
    ['illustrator:ol_weiyan'] = '',
    ['ol_kuanggu'] = '狂骨',
    [':ol_kuanggu'] = '当你对一名角色造成1点伤害后，若你与其的距离于其因受到此伤害而扣减体力前不大于1，你可以选择一项：1.回复1点体力；2.摸一张牌。',
    ['$ol_kuanggu1'] = '',
    ['$ol_kuanggu2'] = '',
    ['qimou'] = '奇谋',
    [':qimou'] = '限定技，出牌阶段，你可以失去至少1点体力，然后你于此回合内使用【杀】的次数上限+X且与其他角色的距离-X。（X为你以此法失去的体力值）',
    ['$qimou1'] = '',
    ['$qimou2'] = '',
    ['~ol_weiyan'] = '',

    --[[['menghuo_po'] = '孟获',
    ['#menghuo_po'] = '南蛮王',
    ['zaiqi_po'] = '再起',
    [':zaiqi_po'] = '弃牌阶段开始时，你可以选择一至X名角色，这些角色各选择一项：1、摸一张牌；2、令你回复1点体力。（X为于此回合内置入弃牌堆的红色牌数）',
    ['$zaiqi_po1'] = '',
    ['$zaiqi_po2'] = '',
    ['~menghuo_po'] = '',
    
    ['zhurong_po'] = '祝融',
    ['#zhurong_po'] = '野性的女王',
    ['lieren_po'] = '烈刃',
    [':lieren_po'] = '当你使用【杀】指定一个目标后，你可以与其拼点：若你赢，你获得其一张牌；若你没赢，你可以获得两张拼点的牌中点数大的一张。 ',
    ['$lieren_po1'] = '',
    ['$lieren_po2'] = '',
    ['~zhurong_po'] = '',
    
    ['sunjian_po'] = '孙坚',
    ['#sunjian_po'] = '武烈帝',
    ['yinghun_po'] = '英魂',
    [':yinghun_po'] = ' 准备阶段开始时，若你已受伤，你可以选择一名其他角色，然后选择一项：1.令其摸一张牌，然后弃置X张牌；2.令其摸X张牌，然后弃置一张牌。（若你的装备区里的牌数不小于体力值，X为你的体力上限，否则X为你已损失的体力值）',
    ['$yinghun_po1'] = '',
    ['$yinghun_po2'] = '',
    ['~sunjian_po'] = '',
    
    ['xiaoqiao_po'] = '小乔',
    ['#xiaoqiao_po'] = '矫情之花',
    ['tianxiang_po'] = '天香',
    [':tianxiang_po'] = ' 当你受到伤害时，你可弃置一张红桃手牌并选择一名其他角色，将此伤害转移给该角色，若如此做，你选择一项：1.其摸X张牌（X为其已损失的体力值）；2.于你的下回合开始前“天香”无效且防止其造成或受到的伤害。',
    ['$tianxiang_po1'] = '',
    ['$tianxian_po2'] = '',
    ['~xiaoqiao_po'] = '',
    
    ['lusu_po'] = '鲁肃',
    ['#lusu_po'] = '独断的外交家',
    ['dimeng_po'] = '缔盟',
    [':dimeng_po'] = '出牌阶段限一次，你可以选择两名其他角色并弃置X张牌（X为这两名角色手牌数的差），将这些角色的手牌扣置于你的武将牌上，称为“盟”，令这些角色观看“盟”，然后选择其中一名角色：令其获得其中一张牌，另一名角色获得其中一张牌，且重复此流程。',
    ['$dimeng_po1'] = '',
    ['$dimeng_po2'] = '',
    ['~lusu_po'] = '',
    
    ['yuanshao_po'] = '袁绍',
    ['#yuanshao_po'] = '高贵的名门',
    ['luanji_po'] = '乱击',
    [':luanji_po'] = '你可以将两张于此回合内未以此法转化过的花色的手牌当【万箭齐发】使用；当已受伤的角色响应此牌时，令其摸一张牌。',
    ['$luanji_po1'] = '放箭！放箭！',
    ['$luanji_po2'] = '箭支充足，尽管取用~',
    ['$xueyi1'] = '世受皇恩，威震海内！',
    ['$xueyi2'] = '四世三公，名冠天下！',
    ['~yuanshao_po'] = '我袁家~怎么会输？',
    
    ['ol_caocao'] = '曹操',
    ['ol_guixin'] = '归心',
    [':ol_guixin'] = '当你受到1点伤害后，你可以获得所有其他角色各你选择的有牌区域里的随机一张牌，然后翻面。',
    ['$ol_guixin1'] = '扫清六合，席卷八荒！',
    ['$ol_guixin2'] = '民之归吾，如水之就下！',
    ['~ol_caocao'] = '神龟虽寿，犹有尽时···',]] --

    ['dongbai'] = '董白',
    ['#dongbai'] = '魔姬',
    ['illustrator:dongbai'] = 'Sonia Tang',
    ['lianzhu'] = '连诛',
    [':lianzhu'] = '出牌阶段限一次，你可以展示一张牌并将之交给一名角色，若之为黑色，其选择是否弃置两张牌，若其选择否，你摸两张牌。',
    ['$lianzhu1'] = '若有不臣之心，定当株连九族！',
    ['$lianzhu2'] = '你们都是一条绳上的蚂蚱~',
    ['xiahui'] = '黠慧',
    [':xiahui'] = '锁定技，你于弃牌阶段内黑色手牌不计入手牌数且不能弃置；锁定技，当你因其他角色获得而失去黑色牌后，令其于其扣减体力或失去此牌前不能使用、打出或弃置之。',
    ['~dongbai'] = '放肆！我要让爷爷，赐你们死罪！',

    ['ol_huangzhong'] = '黄忠',
    ['#ol_huangzhong'] = '老将的逆袭',
    ['illustrator:ol_huangzhong'] = '',
    ['ol_liegong'] = '烈弓',
    [':ol_liegong'] = '你使用【杀】可以选择距离为X以内的目标；当你使用【杀】指定一个目标后，你可以执行以下效果：1.若其手牌数不大于你，令其不能使用【闪】响应此【杀】；2.若其体力值不小于你，令此【杀】的伤害值基数+1。（X为此【杀】的点数）',

    ['zhaoxiang'] = '赵襄',
    ['#zhaoxiang'] = '拾梅鹊影',
    ['illustrator:zhaoxiang'] = '木美人',
    ['fanghun'] = '芳魂',
    [':fanghun'] = '当你使用【杀】造成伤害后，你可以获得1枚“梅影”标记；你可以弃1枚“梅影”标记并发动”龙胆”并摸一张牌。',
    ['$fanghun1'] = '万花凋落尽，一梅独傲霜。',
    ['$fanghun2'] = '暗香疏影处，凌风踏雪来~',
    ['@meiying'] = '魅影',
    ['fuhan'] = '扶汉',
    ['fuhan:up'] = '你想发动“扶汉”令体力上限为%src吗?',
    [':fuhan'] = '限定技，回合开始时，若X大于0且你拥有“芳魂”，你可以先弃所有“梅影”标记再观看五张未登场的蜀势力武将牌，将此武将牌替换为其中一张，然后令体力上限为X；\
    若你为体力值最少的角色，你回复1点体力。（X为你弃置过的“梅影”标记数且至多为游戏开始时的角色数）',
    ['$fuhan1'] = '承先父之志，扶汉兴刘~',
    ['$fuhan2'] = '天将降大任于我！',
    ['~zhaoxiang'] = '遁入阴影之中...',

    ['heqi'] = '贺齐',
    ['#heqi'] = '马踏群峦',
    ['illustrator:heqi'] = 'DH',
    ['qizhou'] = '绮胄',
    [':qizhou'] = '锁定技，若你的装备区里的花色数：不小于1，你拥有“马术”；不小于2，你拥有“英姿”；不小于3，你拥有“短兵”；为4，你拥有“奋威”。',
    ['$qizhou1'] = '人靠衣装，马靠鞍~',
    ['$qizhou2'] = '可真是把好刀啊~',
    ['$qizhou3'] = '我的船队，要让全建业城都看见~',
    ['shanxi'] = '闪袭',
    [':shanxi'] = '出牌阶段限一次，你可以弃置一张红色基本牌并弃置攻击范围内的一名角色一张牌，若之：为【闪】，你观看其手牌；不为【闪】，其观看你的手牌。',
    ['$shanxi1'] = '敌援未到，需要速战速决！',
    ['$shanxi2'] = '快马加鞭，赶在敌人戒备之前！',
    ['~heqi'] = '别拿走……我的装备~',

    ['dongyun'] = '董允',
    ['#dongyun'] = '骨鲠良相',
    ['illustrator:dongyun'] = '玖等仁品',
    ['bingzheng'] = '秉正',
    [':bingzheng'] = '出牌阶段结束时，你可以选择一名手牌数不等于体力值的一名角色，你选择一项：1.其弃置一张手牌；2.其摸一张牌。然后若其手牌数等于体力值，你摸一张牌，然后可以交给其一张牌。',
    ['bingzheng-invoke'] = '你可以发动“秉正”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['bingzheng-distribute'] = '你可以发动“秉正”交出一张牌',
    ['bingzheng1'] = '其弃置一张手牌',
    ['bingzheng2'] = '其摸一张牌',
    ['@bingzheng'] = '你可以选择一张牌交给 %src ',
    ['$bingzheng1'] = '自古~就是邪不胜正！',
    ['$bingzheng2'] = '主公面前，岂容小人搬弄是非！',
    ['sheyan'] = '舍宴',
    ['sheyan-invoke'] = '你可以发动“舍宴”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':sheyan'] = '当你成为不为【借刀杀人】的非延时类锦囊牌的目标时，你可以选择一项：1.令一名角色成为此牌的目标（无距离限制）；2.若目标数大于1，取消其中一个目标。',
    ['$sheyan1'] = '公事为重~宴席，不去也罢~',
    ['$sheyan2'] = '还是改日吧~',
    ['~dongyun'] = '大汉，要亡于宦官之手了。',

    ['mazhong'] = '马忠',
    ['#mazhong'] = '笑合南中',
    ['illustrator:mazhong'] = 'Thinking',
    ['fuman'] = '抚蛮',
    [':fuman'] = '出牌阶段，你可以将一张【杀】交给一名于回合内未因“抚蛮”而获得过牌的角色，若如此做，当其于其回合结束前使用此牌时，你摸一张牌。',
    ['$fuman1'] = '恩威并施，蛮夷可为我所用。',
    ['$fuman2'] = '发兵器啦！',
    ['~mazhong'] = '丞相不在，你们竟然……',

    ['kanze'] = '阚泽',
    ['#kanze'] = '慧眼的博士',
    ['illustrator:kanze'] = 'LiuHeng',
    ['cv:kanze'] = '倪康',
    ['xiashu'] = '下书',
    ['xiashu-invoke'] = '你可以发动“下书”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>',
    ['@xiashu-invoke'] = '请展示若干张牌<br/> <b>操作提示</b>: 选择若干张牌→点击确定<br/>',
    ['xiashu1'] = '获得其展示的牌',
    ['xiashu2'] = '获得其未展示的手牌',
    [':xiashu'] = '出牌阶段开始时，你可以将所有手牌交给一名角色，然后令其展示至少一张手牌，你选择一项：1.获得其展示的牌；2.获得其未展示的手牌。',
    ['$xiashu1'] = '吾有密信，特来献予将军。',
    ['$xiashu2'] = '将军若不信，可亲自验看。',
    ['kuanshi'] = '宽释',
    ['kuanshi-invoke'] = '你可以发动“宽释”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':kuanshi'] = '结束阶段开始时，你可以选择一名角色，若如此做，当其于你的下回合开始前受到下一次大于1点的伤害时，防止此伤害，跳过你下回合的摸牌阶段。',
    ['$kuanshi1'] = '不知者，无罪~',
    ['$kuanshi2'] = '罚酒三杯，下不为例~',
    ['~kanze'] = '我~早已做好了牺牲的准备~',

    ['shenlvbu_gui'] = '神吕布',
    ['#shenlvbu_gui'] = '神鬼无前',
    ['illustrator:shenlvbu_gui'] = 'LiuHeng',
    ['shenqu'] = '神躯',
    [':shenqu'] = '一名角色的回合开始时，若你的手牌数不大于体力上限，你可以摸两张牌；当你受到伤害后，你可以使用【桃】。',
    ['$shenqu1'] = '别心怀侥幸了，你们不可能赢~',
    ['$shenqu2'] = '虎牢关，我一人镇守足矣~',
    ['jiwu'] = '极武',
    [':jiwu'] = '出牌阶段，你可以弃置一张手牌，令你于此回合内拥有一项：“强袭”、“烈刃”、“旋风”、“完杀”。',
    ['$jiwu1'] = '我。是不可战胜的！',
    ['$jiwu2'] = '今天，就让你们感受一下真正的绝望~',
    ['$xuanfeng3'] = '千钧之势，力贯苍穹！',
    ['$xuanfeng4'] = '风扫六合，威震八荒！',
    ['$wansha3'] = '蝼蚁，怎容偷生！',
    ['$wansha4'] = '沉沦吧，在这无边的恐惧！',
    ['$qiangxi3'] = '这么想死！那我就成全你！',
    ['$qiangxi4'] = '项上人头，待我来取！',
    ['$lieren3'] = '哈哈哈，破绽百出！',
    ['$lieren4'] = '我要让这虎牢关下，血流成河！',
    ['~shenlvbu_gui'] = '你们的项上人头，我改日再取~',

    ['mol_sunru'] = '孙茹',
    ['#mol_sunru'] = '出水青莲',
    ['illustrator:mol_sunru'] = '撒呀酱',
    ['yingjian'] = '影箭',
    ['@yingjian'] = '你可以发动“影箭”',
    ['~yingjian'] = '选择若干名角色→点击确定',
    [':yingjian'] = '准备阶段开始时，你可以视为使用【杀】（无距离限制）。',
    ['$yingjian1'] = '',
    ['$yingjian2'] = '',
    ['~mol_sunru'] = '',

    ['fire_pangde'] = '庞德',
    ['#fire_pangde'] = '周苛之节',
    ['illustrator:fire_pangde'] = '',
    ['jianchu'] = '鞬出',
    [':jianchu'] = '当你使用【杀】指定一个目标后，你可以弃置其一张牌，若之：为装备牌，其不能使用【闪】响应此【杀】；不为装备牌；其获得此【杀】。',
    ['$jianchu1'] = '',
    ['$jianchu2'] = '',
    ['~fire_pangde'] = '',

    ['miheng'] = '祢衡',
    ['#miheng'] = '鸷鹗啄孤凤',
    ['illustrator:miheng'] = 'Thinking',
    ['kuangcai'] = '狂才',
    [':kuangcai'] = '出牌阶段开始时，你可以令你于此阶段内使用牌无距离和次数限制，若如此做，当你于此阶段内使用牌时，你摸一张牌，然后若你于此阶段内以此法获得过至少五张牌，结束此出牌阶段。',
    ['$kuangcai1'] = '',
    ['$kuangcai2'] = '',
    ['shejian'] = '舌剑',
    [':shejian'] = '弃牌阶段结束时，若你于此阶段内弃置过的你的至少两张手牌且这些牌的花色均不相同，你可以弃置一名其他角色一张牌。',
    ['$shejian1'] = '',
    ['$shejian2'] = '',
    ['~miheng'] = '',

    ['taoqian'] = '陶谦',
    ['#taoqian'] = '膺秉温仁',
    ['illustrator:taoqian'] = 'F.源',
    ['zhaohuo'] = '招祸',
    [':zhaohuo'] = '锁定技，当其他角色进入濒死状态时，你减X点体力上限，然后摸等量的牌。（X为你的体力上限-1）',
    ['$zhaohuo1'] = '',
    ['$zhaohuo2'] = '',
    ['yixiang'] = '义襄',
    [':yixiang'] = '每名角色的回合限一次，当你成为牌的目标后，若使用者的体力值大于你，你可以获得牌堆里随机一张你手牌中的基本牌的牌名均不同的基本牌。',
    [':yixiang_face'] = '每名角色的回合限一次，当你成为牌的目标后，若使用者的体力值大于你，你可以亮出牌堆顶的一张牌，若之：与你手牌中的基本牌的牌名均不同的基本牌，获得之，否则你重复此流程。',
    ['$yixiang1'] = '',
    ['$yixiang2'] = '',
    ['yirang'] = '揖让',
    [':yirang'] = '出牌阶段开始时，你可以将所有非基本牌交给一名体力上限大于你的角色，然后将体力上限调整至与其相同，回复X点体力。（X为你以此法交给其的牌的类别数）',
    ['$yirang1'] = '',
    ['$yirang2'] = '',
    ['~taoqian'] = '',

    ['huangfusong'] = '皇甫嵩',
    ['#huangfusong'] = '志定雪霜',
    ['illustrator:huangfusong'] = '秋呆呆',
    ['fenyue'] = '奋钺',
    [':fenyue'] = '<font color="green"><b>出牌阶段限X次，</b></font>你可以与一名角色拼点：若你赢，你视为对其使用【杀】，若选择否，其于此回合内不能使用或打出手牌；若你没赢后，你结束此阶段。（X为忠臣数）',
    ['fenyue1'] = '其于此回合内不能使用或打出手牌',
    ['fenyue2'] = '视为对其使用【杀】',
    ['$fenyue1'] = '逆贼势大，且扎营寨，击其懈怠。',
    ['$fenyue2'] = '兵有其变，不在众寡。',
    ['~huangfusong'] = '只恨黄巾未除，不能报效朝廷。',

    ['ol_guanyinping'] = '关银屏',
    ['#ol_guanyinping'] = '将门虎女',
    ['illustrator:ol_guanyinping'] = '',
    ['ol_xueji'] = '雪恨',
    [':ol_xueji'] = '出牌阶段限一次，你可以弃置一张红色牌并横置一至X名角色，然后选择其中一名角色，对其造成1点火焰伤害。（X为你已损失的体力值且至少为1）',
    ['$ol_xueji1'] = '',
    ['$ol_xueji2'] = '',
    ['ol_huxiao'] = '虎啸',
    [':ol_huxiao'] = '锁定技，当你对一名角色造成火焰伤害后，其摸一张牌，令你于此回合内对你与其使用牌无次数限制。',
    ['$ol_huxiao1'] = '',
    ['$ol_huxiao2'] = '',
    ['ol_wuji'] = '武继',
    [':ol_wuji'] = '<font color="purple"><b>觉醒技，</b></font>结束阶段开始时，若你于此回合内造成过至少3点伤害，你加1点体力上限，然后回复1点体力，失去“虎啸”，获得场上、牌堆或弃牌堆里的一张【青龙偃月刀】。',
    ['$ol_wuji1'] = '',
    ['$ol_wuji2'] = '',
    ['~ol_guanyinping'] = '',

    ['super_yujin'] = '于禁',
    ['#super_yujin'] = '临危不惧',
    ['illustrator:super_yujin'] = '',
    ['zhenjun'] = '镇军',
    [':zhenjun'] = '准备阶段开始时，你可以选择一名手牌数大于体力值的角色，弃置其X张牌，然后选择是否弃置其中非装备牌数量的牌，若选择否，其摸等量的牌。（X为其手牌数与体力值之差）',
    ['$zhenjun1'] = '',
    ['$zhenjun2'] = '',
    ['~super_yujin'] = '',

    ['zhuque'] = '朱雀',
    ['shenyi'] = '神裔',
    [':shenyi'] = '锁定技，若你的武将牌正面朝上，你不能翻面；锁定技，你的判定区里的牌的结果反转。',
    ['$shenyi1'] = '',
    ['$shenyi2'] = '',
    ['ol_fentian'] = '焚天',
    -- [':ol_fentian'] = '锁定技，你造成的伤害视为火焰伤害；锁定技，你使用红色牌无距离和次数限制且不能被其他角色使用【闪】和【无懈可击】响应。',
    [':ol_fentian'] = '出牌阶段限一次，你可以选择一名其他角色，对其造成1点火焰伤害，然后若其以此法死亡，此技能发动次数上限+1。',
    [':ol_fentian_sp'] = '出牌阶段限一次，你可以选择距离1以内的一名其他角色，对其造成1点火焰伤害，然后若其以此法死亡，此技能发动次数上限+1。',
    ['$ol_fentian1'] = '',
    ['$ol_fentian2'] = '',
    ['~zhuque'] = '',

    ['huoshenzhurong'] = '火神祝融',
    ['xingxia'] = '行夏',
    -- [':xingxia'] = '每两轮的出牌阶段限一次，你可以对焰灵造成2点火焰伤害，然后令所有对方角色选择一项：1.弃置一张红色手牌；2.受到由你造成的1点火焰伤害。',
    [':xingxia'] = '锁定技，每两轮限一次，出牌阶段开始时，你选择一名己方其他角色，对其造成2点火焰伤害，然后令所有对方角色各选择一项：1.弃置一张红色手牌；2.受到由你造成的1点火焰伤害。',
    [':xingxia_sp'] = '每两轮限一次，出牌阶段开始时，你可以选择一名其他角色，对其造成2点火焰伤害，然后其以外的所有其他角色各选择一项：1.弃置一张红色手牌；2.受到由你造成的1点火焰伤害。',
    ['$xingxia1'] = '',
    ['$xingxia2'] = '',
    ['~huoshenzhurong'] = '',

    ['yanling'] = '焰灵',
    ['huihuo'] = '回火',
    -- [':huihuo'] = '锁定技，当你死亡时，你对所有对方角色各造成3点火焰伤害；锁定技，你使用【杀】的次数上限+1。',
    [':huihuo'] = '当你死亡后，你对所有对方角色各造成3点火焰伤害；你使用【杀】的次数上限+1。',
    [':huihuo_sp'] = '当你死亡后，你选择一名角色，对其造成3点火焰伤害；你使用【杀】的次数上限+1。',
    ['$huihuo1'] = '',
    ['$huihuo2'] = '',
    ['furan'] = '复燃',
    -- [':furan'] = '对方角色于你处于濒死状态时可以将一张红色牌当【桃】使用。',
    [':furan'] = '锁定技，对方角色于你处于濒死状态时选择是否将一张红色牌当【桃】使用。',
    [':furan_sp'] = '其他角色于你处于濒死状态时可以将一张牌当【桃】使用',
    ['$furan1'] = '',
    ['$furan2'] = '',
    ['~yanling'] = '',

    ['yandi'] = '炎帝',
    ['shenen'] = '神恩',
    [':shenen'] = '锁定技，己方角色使用牌无距离限制；锁定技，对方角色的额定摸牌数和手牌上限+1。',
    ['$shenen1'] = '',
    ['$shenen2'] = '',
    ['chiyi'] = '赤仪',
    -- [':chiyi'] = '锁定技，当对方角色受到伤害时，若轮数不小于3，伤害值+1；锁定技，第五轮开始时，你对所有角色各造成1点火焰伤害；锁定技，第七轮开始时，你对焰灵造成5点火焰伤害。',
    [':chiyi'] = '锁定技，当对方角色受到伤害时，若轮数不小于3，伤害值+1；锁定技，第六轮开始时，你对所有其他角色各造成1点火焰伤害；锁定技，第九轮开始时，焰灵死亡。',
    [':chiyi_sp'] = '锁定技，当你造成伤害时，若轮数不小于3，伤害值+1；锁定技，第六轮开始时，你对所有其他角色各造成1点火焰伤害；锁定技，第九轮开始时，你死亡。',
    ['$chiyi1'] = '',
    ['$chiyi2'] = '',
    ['~yandi'] = '',

    ['qinglong'] = '青龙',
    ['tengyun'] = '腾云',
    [':tengyun'] = '锁定技，当你受到伤害后，其他角色于此回合内对你使用牌无效。',
    ['$tengyun1'] = '',
    ['$tengyun2'] = '',
    ['~qinglong'] = '',

    ['mushengoumang'] = '木神勾芒',
    ['buchun'] = '布春',
    -- [':buchun'] = '每两轮的出牌阶段限一次，若：有已阵亡的树精，你可以失去1点体力，令树精复活，然后其将体力值回复至1点，将手牌补至两张；没有已阵亡的树精，你可以选择一名已受伤的己方角色，令其回复2点体力。',
    [':buchun'] = '锁定技，每两轮限一次，准备阶段开始时，若：有已阵亡的己方角色，你令这些角色复活，各将体力值回复至1点，将手牌补至体力上限；没有已阵亡的己方角色，你选择一名对方角色，其失去2点体力。',
    [':buchun_sp'] = '每两轮限一次，准备阶段开始时，你可以失去1点体力并选择一名角色，若其：存活，其失去2点体力；阵亡，其复活，将体力值回复至1点，将手牌补至两张。',
    ['$buchun1'] = '',
    ['$buchun2'] = '',
    ['~mushengoumang'] = '',

    ['shujing'] = '树精',
    ['cuidu'] = '淬毒',
    [':cuidu'] = '锁定技，当你对对方角色造成伤害后，其获得“中毒”，然后木神勾芒摸一张牌。',
    [':cuidu_sp'] = '锁定技，当你对其他角色造成伤害后，你选择一名角色，其摸一张牌，然后其获得“中毒”。',
    ['$cuidu1'] = '',
    ['$cuidu2'] = '',
    ['zhongdu'] = '中毒',
    -- [':zhongdu'] = '锁定技，回合开始时，你判定，若结果：不为红桃，你受到1点伤害；不为黑桃，你失去此技能。',
    [':zhongdu'] = '锁定技，准备阶段开始时，你判定，若结果：为方块，你失去1点体力；不为方块，你失去此技能。',
    ['$zhongdu1'] = '',
    ['$zhongdu2'] = '',
    ['~shujing'] = '',

    ['taihao'] = '太昊',
    ['god_qingyi'] = '青仪',
    -- [':god_qingyi'] = '锁定技，第三轮开始时，所有己方角色各回复1点体力；锁定技，第五轮开始时，所有对方角色各失去1点体力；锁定技，第七轮开始时，木神勾芒和树精复活，然后各摸三张牌，加1点体力上限，回复3点体力。',
    [':god_qingyi'] = '锁定技，第三轮开始时，所有己方角色各加1点体力上限，回复1点体力；锁定技，第六轮开始时，所有对方角色各失去1点体力；锁定技，第九轮开始时，己方阵亡角色复活，然后各将体力值回复至上限，摸四张牌，然后所有己方角色获得“青囊”。',
    [':god_qingyi_sp'] = '锁定技，第三轮开始时，你加1点体力上限，回复1点体力；锁定技，第六轮开始时，所有其他角色各失去1点体力；锁定技，第九轮开始时，若你已死亡，你复活，然后将体力值回复至上限，摸四张牌，获得“青囊”。',
    ['$qingyi1'] = '',
    ['$qingyi2'] = '',
    ['~taihao'] = '',

    ['ol_sunce'] = '孙策',
    ['illustrator:ol_sunce'] = '',
    ['ol_hunshang'] = '魂殇',
    [':ol_hunshang'] = '锁定技，准备阶段开始时，若你的体力值不大于1，你于此回合内拥有“英魂”和“英姿”。',
    ['$ol_hunshang1'] = '',
    ['$ol_hunshang2'] = '',
    ['~ol_sunce'] = '',

    ['ol_caohong'] = '曹洪',
    ['illustrator:ol_caohong'] = '',
    ['ol_huyuan'] = '护援',
    [':ol_huyuan'] = '结束阶段开始时，你可以将一张装备牌置入一名角色的装备区，若如此做，你可以弃置其距离为1的一名角色一张牌。',
    ['$ol_huyuan1'] = '',
    ['$ol_huyuan2'] = '',
    ['~ol_caohong'] = '',

    ['ol_xuhuang'] = '徐晃',
    ['illustrator:ol_xuhuang'] = '',
    ['ol_duanliang'] = '断粮',
    [':ol_duanliang'] = '你可以将一张不为锦囊牌的黑色牌当【兵粮寸断】使用；你使用【兵粮寸断】对手牌数不小于你的角色无距离限制。',
    ['$ol_duanliang1'] = '',
    ['$ol_duanliang2'] = '',
    ['jiezi'] = '截辎',
    [':jiezi'] = '锁定技，当一名角色跳过摸牌阶段后，你摸一张牌。',
    ['$jiezi1'] = '',
    ['$jiezi2'] = '',
    ['~ol_xuhuang'] = '',

    ['liuqi'] = '刘琦',
    ['#liuqi'] = '居外而安',
    ['illustrator:liuqi'] = 'NOVART',
    ['wenji'] = '问计',
    ['wenji-invoke'] = '你可以发动“问计”<br/> <b>操作提示</b>: 选择一名有手牌的角色→点击确定<br/>',
    [':wenji'] = '出牌阶段开始时，你可以令一名其他角色交给你一张牌，若如此做，你于此回合内使用与之相同名称的牌不能被其他角色响应。',
    ['$wenji1'] = '还望先生救我！',
    ['$wenji2'] = '言出子口，入于吾耳，可以言未？',
    ['tunjiang'] = '屯江',
    [':tunjiang'] = '结束阶段开始时，若你未于此回合内跳过出牌阶段且于此回合的出牌阶段内未使用牌指定过其他角色为目标，你可以摸X张牌。（X为势力数）',
    ['$tunjiang1'] = '江夏冲要之地，孩儿愿往守之。',
    ['$tunjiang2'] = '皇叔勿惊，吾与关将军已到。',
    ['~liuqi'] = '父亲…孩儿来见你了…',

    ['tangzi'] = '唐咨',
    ['#tangzi'] = '工学之奇才',
    ['illustrator:tangzi'] = 'NOVART',
    ['xingzhao'] = '兴棹',
    [':xingzhao'] = '锁定技，若你拥有的装备牌数大于：1，你拥有“恂恂”；2.当一名角色使用装备牌时，你选择是否令其摸一张牌；3.你选择是否跳过一名角色的判定阶段。',
    ['$xingzhao1'] = '拿些上好的木料来。',
    ['$xingzhao2'] = '精挑细选，方能成百年之计。',
    ['$xingzhao3'] = '让我先探他一探。',
    ['$xingzhao4'] = '船也不是一天就能造出来。',
    ['~tangzi'] = '偷工减料，要不得呀！',

    ['ol_yuji'] = '于吉',
    ['#ol_yuji'] = '魂绕左右',
    ['ol_qianhuan'] = '千幻',
    [':ol_qianhuan'] = '当一名角色受到伤害后，你可以将一张与“幻”花色均不同的牌置于你的武将牌上，称为“幻”；当一名角色成为基本牌或锦囊牌的目标时，若目标数为1，你可以将一张“幻”置入弃牌堆，取消其。',
    ['$ol_qianhuan1'] = '',
    ['$ol_qianhuan2'] = '',
    ['~ol_yuji'] = '',

    ['fool_sunce'] = '孙策',
    ['#fool_sunce'] = '魂绕左右',
    ['fool_jiang'] = '激昂',
    [':fool_jiang'] = '锁定技，当你使用【决斗】或红色【杀】时。或成为【决斗】或红色【杀】的目标后，你令伤害值基数+1，然后摸一张牌。',
    ['$fool_jiang1'] = '',
    ['$fool_jiang2'] = '',
    ['fool_hunzi'] = '魂姿',
    [':fool_hunzi'] = '<font color="purple"><b>觉醒技，</b></font>当你进入濒死状态时，你减1点体力上限，然后将体力值回复至2点，获得“英姿”和“英魂”。',
    ['$fool_hunzi1'] = '',
    ['$fool_hunzi2'] = '',
    ['~fool_sunce'] = '',

    ['ol_caoren'] = '曹仁',
    ['#ol_caoren'] = '神勇御敌',
    ['illustrator:ol_caoren'] = '',
    ['ol_jushou'] = '据守',
    [':ol_jushou'] = '结束阶段开始时，你可以翻面并摸四张牌，然后选择一张手牌，若之为能使用且为装备牌，你使用之，否则弃置之。',
    ['@jushou'] = '请弃置一张手牌',
    ['$ol_jushou1'] = '',
    ['$ol_jushou2'] = '',
    ['ol_jiewei'] = '解围',
    [':ol_jiewei'] = '你可以将装备区的一张牌当【无懈可击】使用；当你翻面后，若你的武将牌正面朝上，你可以弃置一张牌，然后可以将一名角色判定区／装备区里的一张牌置入另一名角色的判定区／装备区。',
    ['@ol_jiewei'] = '你可以弃置一张牌发动“解围”',
    ['$ol_jiewei1'] = '',
    ['$ol_jiewei2'] = '',
    ['~ol_caoren'] = '',

    ['bug_caoren'] = 'SP曹仁',
    ['#bug_caoren'] = '冷面将军',
    ['illustrator:bug_caoren'] = '',
    ['weikui'] = '伪溃',
    [':weikui'] = '出牌阶段限一次，你可以失去1点体力并选择一名有手牌的其他角色，观看其手牌，然后若其中：有【闪】，视为对其使用【杀】且你于此回合内于其距离视为1；没有【闪】，弃置其中一张牌。',
    ['$weikui1'] = '',
    ['$weikui2'] = '',
    ['lizhan'] = '励战',
    [':lizhan'] = '结束阶段开始时，你可以选择至少一名已受伤的角色，这些角色各摸一张牌。',
    ['$lizhan1'] = '',
    ['$lizhan2'] = '',
    ['~bug_caoren'] = '',

    ['xinxianying'] = '辛宪英',
    ['#xinxianying'] = '名门智女',
    ['designer:xinxianying'] = '如释帆飞',
    ['illustrator:xinxianying'] = '玫芍之言',
    ['zhongjian'] = '忠鉴',
    [':zhongjian'] = '出牌阶段限一次，你可以展示一张手牌并展示手牌数大于体力值的一名其他角色X张手牌，若其以此法展示的牌与你展示的牌之中：有颜色相同的牌，你选择是否弃置其一张牌，若选择否，你摸一张牌；\
    有点数相同的牌，此技能于此回合内视为“出牌阶段限两次”；均没有，你的手牌上限-1。（X为其手牌数和体力值之差）',
    [':zhongjian_buff'] = '出牌阶段限两次，你可以展示一张手牌并展示手牌数大于体力值的一名其他角色X张手牌，若其以此法展示的牌与你展示的牌：有颜色相同的牌，你选择是否弃置其一张牌，若选择否，你摸一张牌；\
    没有颜色相同的牌且没有点数相同的牌，你的手牌上限-1。（X为其手牌数和体力值之差）',
    ['zhongjian1'] = '弃置其一张牌',
    ['$zhongjian1'] = '浊世风云变幻，当以明眸洞察。',
    ['$zhongjian2'] = '心中自有明镜，可鉴奸佞忠良。',
    ['caishi'] = '才识',
    [':caishi'] = '摸牌阶段开始时，你可以选择一项：1.手牌上限+1，然后其他角色于此回合内不是你使用牌的合法目标；2.回复1点体力，然后你于此回合内不是你使用牌的合法目标。',
    ['caishi1'] = '手牌上限+1，然后其他角色于此回合内不是你使用牌的合法目标',
    ['caishi2'] = '回复1点体力，然后你于此回合内不是你使用牌的合法目标',
    ['$caishi1'] = '清识难尚，至德可师。',
    ['$caishi2'] = '知书达礼，博古通今。',
    ['~xinxianying'] = '吾一生明鉴，竟错看于你……',

    ['wuxian'] = '吴苋',
    ['#wuxian'] = '穆皇后',
    ['designer:wuxian'] = 'wlf元首',
    ['illustrator:wuxian'] = '樱花闪乱',
    ['fumian'] = '福绵',
    [':fumian'] = '结束阶段开始时，你可以选择一项：1.于下回合内额定摸牌数+X；2.于下回合内使用红色牌的目标上限+X。若如此做，你于此技能没有选项前失去此选项。（X为3-选项数）',
    ['fumian1'] = '下回合内额定摸牌数+X',
    ['fumian2'] = '下回合内使用红色牌的目标上限+X',
    ['$fumian1'] = '人言吾吉人天相，福寿绵绵。',
    ['$fumian2'] = '永理二子，当保大汉血脉长存。',
    ['daiyan'] = '怠宴',
    [':daiyan'] = '准备阶段开始时，你可以选择一名其他角色，令其获得牌堆里的一张【桃】，然后若其为上一个以此法选择的角色，其失去1点体力。',
    ['$daiyan1'] = '汝可于宫中多留几日无妨。',
    ['$daiyan2'] = '胡氏受屈，吾亦心不安。',
    ['~wuxian'] = '所幸伴君半生，善始终得善终……',

    ['ol_wuxian'] = '吴苋',
    ['#ol_wuxian'] = '穆皇后',
    ['designer:ol_wuxian'] = '韩旭',
    ['illustrator:ol_wuxian'] = '缨尧',
    ['ol_fumian'] = '福绵',
    [':ol_fumian'] = '准备阶段开始时，你可以选择一项：1.于此回合内的额定摸牌数+1；2.于此回合内限一次令你使用红色牌的目标上限+1。然后若没有选项中有2，令你另一个选项的1视为2，否则所有选项的2视为1。',
    -- [':ol_fumian'] = '准备阶段开始时，你可以选择一项：1.于此回合内的额定摸牌数+1；2.与此回合内使用红色牌的目标上限+1。然后令另一个选项的1视为2，此选项的2视为1。',
    ['ol_fumian1'] = '于此回合内的额定摸牌数+1',
    ['ol_fumian2'] = '于此回合内使用红色牌的目标上限+1',
    ['$ol_fumian1'] = '人言吾吉人天相，福寿绵绵。',
    ['$ol_fumian2'] = '胡氏受屈，吾亦心不安。',
    ['ol_daiyan'] = '怠宴',
    [':ol_daiyan'] = '结束阶段开始时，你可以选择一名其他角色，令其获得牌堆里的一张红桃基本牌，然后若其为上一个以此法选择的角色，其失去1点体力。',
    ['$ol_daiyan1'] = '汝可于宫中多留几日无妨。',
    ['$ol_daiyan2'] = '胡氏受屈，吾亦心不安。',
    ['~ol_wuxian'] = '所幸伴君半生，善始终得善终……',

    ['xushi'] = '徐氏',
    ['#xushi'] = '节义双全',
    ['designer:xushi'] = '追蛋格林',
    ['illustrator:xushi'] = '懿肆琬兮',
    ['wengua'] = '问卦',
    ['wengua_bill'] = '问卦',
    ['wengua1'] = '置于牌堆顶',
    ['wengua2'] = '置于牌堆底',
    [':wengua'] = '<font color="green"><b>每名角色的出牌阶段限一次，</b></font>若其：不为你，其可以交给你一张手牌，你可以将之置于牌堆顶/牌堆底，若如此做，你与其各从牌堆底/牌堆顶获得一张牌；\
    为你，你可以将一张手牌置于牌堆顶/牌堆底，若如此做，你从牌堆底/牌堆顶获得一张牌。',
    ['$wengua1'] = '卦不能佳，可须异日。',
    ['$wengua2'] = '阴阳相生相克，万事周而复始。',
    ['fuzhu'] = '伏诛',
    [':fuzhu'] = '一名男性角色的结束阶段开始时，若牌堆数不大于你的体力值的十倍，你可以对其使用牌堆里的X张【杀】，然后洗牌堆。（X为牌堆里的【杀】数且不超过角色数）',
    ['$fuzhu1'] = '我连做梦都在等这一天呢！',
    ['$fuzhu2'] = '既然来了，就别想走了！',
    ['~xushi'] = '莫问前程凶吉，但求落幕无悔……',

    ['caojie'] = '曹节',
    ['#caojie'] = '献穆皇后',
    ['designer:caojie'] = '会智迟的沮授',
    ['illustrator:caojie'] = '小小鸡仔',
    ['shouxi'] = '守玺',
    [':shouxi'] = '当你成为【杀】的目标后，你可以令使用者选择是否弃置一张你未以此法声明过的基本牌或锦囊牌的牌名，若选择：是，其获得你的一张牌；否，此【杀】对你无效。',
    ['@shouxi'] = '请弃置一张声明的牌，否则此【杀】无效<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>',
    ['$shouxi1'] = '天子之位，乃归刘汉！',
    ['$shouxi2'] = '吾父功盖皇区，然且不敢篡窃神器！',
    ['huimin'] = '惠民',
    [':huimin'] = '结束阶段开始时，你可以摸X张牌，然后展示等量的手牌并选择所有手牌数小于体力值的角色，这些角色从你选择的角色开始依次获得其中的牌。（X为手牌数小于体力值的角色数）',
    ['huimin-invoke'] = '选择一名角色开始获得牌<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['$huimin1'] = '悬壶济世，施医救民。',
    ['$huimin2'] = '心系百姓，惠布山阳。',
    ['~caojie'] = '皇天……必不祚尔……',

    ['quyi'] = '麴义',
    ['#quyi'] = '名门的骁将',
    ['illustrator:quyi'] = '秋呆呆',
    ['fuji'] = '伏骑',
    [':fuji'] = '锁定技，与你距离为1的角色不能使用或打出牌响应你使用的牌。',
    ['$fuji1'] = '白马？哼！定叫他有来无回~',
    ['$fuji2'] = '既来之，休走之~',
    ['jiaozi'] = '骄恣',
    [':jiaozi'] = '锁定技，当你造成或受到伤害时，若你为唯一手牌数最多的角色，伤害值+1。',
    ['$jiaozi1'] = '今日之祸，皆是吾之功劳~',
    ['$jiaozi2'] = '今吾于此，尔等皆为飞灰！',
    ['~quyi'] = '为主公戎马一生，主公为何如此对我？！',

    ['xizhicai'] = '戏志才',
    ['#xizhicai'] = '负俗的天才',
    -- ['illustrator:xizhicai'] = '眉毛子/凝聚永恒',
    ['illustrator:xizhicai'] = '眉毛子',
    ['$tiandu5'] = '既是如此~',
    ['$tiandu6'] = '天意，不可逆~',
    ['xianfu'] = '先辅',
    [':xianfu'] = '锁定技，游戏开始时，你选择一名其他角色，若如此做：当其受到伤害后，你受到等量的伤害；当其回复体力后，你回复等量的体力。',
    ['$xianfu1'] = '',
    ['$xianfu2'] = '',
    ['$xianfu3'] = '',
    ['$xianfu4'] = '',
    ['$xianfu5'] = '',
    ['$xianfu6'] = '',
    ['chouce'] = '筹策',
    [':chouce'] = '当你受到1点伤害后，你可以判定，若结果为：红色，令一名角色摸X张牌；黑色，弃置一名角色区域里的一张牌。（若其为你因“先辅”而选择的角色，X为2，否则为1）',
    ['$chouce1'] = '',
    ['$chouce2'] = '',
    ['~xizhicai'] = '',

    ['sunqian'] = '孙乾',
    ['#sunqian'] = '折冲樽俎',
    ['illustrator:sunqian'] = 'Thinking',
    ['qianya'] = '谦雅',
    [':qianya'] = '当你成为锦囊牌的目标后，你可以将至少一张手牌交给一名角色。',
    ['$qianya1'] = '君子不妄动，动必有道。',
    ['$qianya2'] = '诶，将军过虑了。',
    ['shuimeng'] = '说盟',
    [':shuimeng'] = '出牌阶段结束时，你可以与一名角色拼点：若你赢，你视为使用【无中生有】；若你没赢，其视为对你使用【过河拆桥】。',
    ['$shuimeng1'] = '你我唇齿相依，共域外敌，何如？',
    ['$shuimeng2'] = '今兵薄士寡，可遣某为使，望说之。',
    ['~sunqian'] = '恨不能得见皇叔造登大宝，额......',

    ['caijue'] = '裁决',
    [':caijue'] = '当其他角色的技能发动时，你可以令发动无效。',
    ['$caijue1'] = '',
    ['$caijue2'] = '',

    ['$duanbing1'] = '一寸短，一寸险。',
    ['$wansha1'] = '汝今势孤，命必绝矣',
    ['$qiangxi1'] = '五步之内，汝命休矣！',

    ['wangyun'] = '王允',
    ['#wangyun'] = '',
    ['illustrator:wangyun'] = 'Town',
    ['lianji'] = '连计',
    [':lianji'] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以将一张【杀】或黑色锦囊牌交给一名角色，令其使用牌堆里随机一张武器牌。然后其选择一项：\
    1.使用你以此法交给其的牌且你不是此牌的合法目标，然后将装备区里的武器牌交给其中一个目标；2.你视为对其使用你以此法交给其的牌，然后将装备区内的武器牌交给你。',
    ['$lianji1'] = '',
    ['$lianji2'] = '',
    ['moucheng'] = '谋逞',
    [':moucheng'] = '<font color="purple"><b>觉醒技，</b></font>当其他角色因“连计”而造成过至少3点伤害后，你失去“连计”，然后获得“矜功”。',
    ['$moucheng1'] = '',
    ['$moucheng2'] = '',
    ['jingong'] = '矜功',
    [':jingong'] = '出牌阶段限一次，你可以将一张装备牌或【杀】从三张随机锦囊牌中选择其中一种牌并当之使用，此回合结束阶段开始时，若你于此回合内未造成过伤害，你失去1点体力。',
    ['$jingong1'] = '',
    ['$jingong2'] = '',
    ['~wangyun'] = '',

    ['ol_xiaoqiao'] = '小乔',
    ['#ol_xiaoqiao'] = '',
    ['illustrator:ol_xiaoqiao'] = 'Town',
    ['ol_tianxiang'] = '天香',
    [':ol_tianxiang'] = '当你受到伤害时，你可以弃置一张红桃手牌并防止此伤害并选择一名其他角色，令其选择一项：1.来源对其造成1点伤害，其摸X张牌；2.其失去1点体力，获得你以此法弃置的牌。（X为其已损失的体力值且至多为5）',
    ['$ol_tianxiang1'] = '',
    ['$ol_tianxiang2'] = '',
    ['~ol_xiaoqiao'] = '',

    ['caiyong'] = '蔡邕',
    ['#caiyong'] = '大鸿儒',
    ['illustrator:caiyong'] = 'Town',
    ['designer:caiyong'] = '千幻',
    ['pizhuan'] = '辟撰',
    ['book'] = '书',
    [':pizhuan'] = '当你使用黑桃牌时，或当你成为其他角色使用的黑桃牌的目标后，若你的“书”数小于4，你可以将牌堆顶一张牌置于武将牌上，称为“书”；你的手牌上限+X。（X为“书”数）',
    ['$pizhuan1'] = '无墨不成书，无时不成才。',
    ['$pizhuan2'] = '笔可抒情，亦可诛心！',
    ['tongbo'] = '通博',
    ['@tongbo'] = '你可以发动“通博”',
    ['~tongbo'] = '选择不想被替换的“书”与想被替换的手牌→点击确定',
    [':tongbo'] = '摸牌阶段结束时，你可以用至少一张手牌替换等量的“书”，然后若你的“书”拥有四种花色，你将“书”交给其他角色。',
    ['$tongbo1'] = '读万卷书，行万里路。',
    ['$tongbo2'] = '博学而不穷，笃行而不倦。',
    ['~caiyong'] = '感叹时事，何罪之有！',

    ['jikang'] = '嵇康',
    ['#jikang'] = '峻峰孤松',
    ['illustrator:jikang'] = '眉毛子',
    ['qingxian'] = '清弦',
    [':qingxian'] = '当你受到伤害/回复体力后，若没有角色处于濒死状态，你可以选择来源/一名其他角色，你选择一项：1.其失去1点体力，随机使用一张牌堆里的装备牌；2.其回复1点体力，弃置一张装备牌。若其以此法使用或弃置的牌为梅花牌，你摸一张牌。',
    ['qingxian1'] = '其失去1点体力，然后随机使用一张牌堆里的装备牌',
    ['qingxian2'] = '其回复1点体力，然后弃置一张装备牌',
    ['qingxian-invoke'] = '你可以发动“清弦”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['$qingxian1'] = '抚琴拨弦，悠然自得。',
    ['$qingxian2'] = '寄情于琴，和于天地。',
    ['juexiang'] = '绝响',
    [':juexiang'] = '当你死亡时，你可以选择一名角色，其随机获得“清弦残谱”上的一项技能且其于其的下回合开始前不是其他角色使用梅花牌的合法目标。\
    <font color="grey">激弦：当你受到伤害后，若没有角色处于濒死状态，你可以令来源失去1点体力，其随机使用一张牌堆里的装备牌。</font>\
    <font color="grey">烈弦：当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色失去1点体力，其随机使用一张牌堆里的装备牌。</font>\
    <font color="grey">柔弦：当你受到伤害后，若没有角色处于濒死状态，你可以令来源回复1点体力，其弃置一张装备牌。</font>\
    <font color="grey">和弦：当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色回复1点体力，其弃置一张装备牌。</font>',
    ['$juexiang1'] = '此曲，不能绝矣。',
    ['$juexiang2'] = '一曲琴音，为我送别。',
    ['jixian'] = '激弦',
    [':jixian'] = '当你受到伤害后，若没有角色处于濒死状态，你可以令来源失去1点体力，其随机使用一张牌堆里的装备牌。',
    ['$jixian1'] = '一弹一拨，铿锵有力！',
    ['liexian'] = '烈弦',
    [':liexian'] = '当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色失去1点体力，其随机使用一张牌堆里的装备牌。',
    ['$liexian1'] = '一壶烈云烧，一曲人皆醉。',
    ['rouxian'] = '柔弦',
    [':rouxian'] = '当你受到伤害后，若没有角色处于濒死状态，你可以令来源回复1点体力，其弃置一张装备牌。',
    ['$rouxian1'] = '君子以琴会友，以瑟辅仁。',
    ['hexian'] = '和弦',
    [':hexian'] = '当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色回复1点体力，其弃置一张装备牌。',
    ['$hexian1'] = '悠悠琴音，人人自醉。',
    ['~jikang'] = '多少遗恨俱随琴音去……',

    ['qinmi'] = '秦宓',
    ['#qinmi'] = '彻天之舌',
    ['illustrator:qinmi'] = 'Thinking',
    ['designer:qinmi'] = '凌天翼',
    ['jianzheng'] = '谏征',
    [':jianzheng'] = '当其他角色使用【杀】指定目标时，若你在其攻击范围内且目标没有你，你可以展示一张手牌并将之置于牌堆顶，取消所有目标，然后若此【杀】不为黑色，你成为目标。',
    ['$jianzheng1'] = '天时不当，必难取胜。',
    ['$jianzheng2'] = '且慢！此阵打不得！',
    ['zhuandui'] = '专对',
    [':zhuandui'] = '当你使用【杀】指定一个目标后/成为其他角色使用【杀】的目标后，你可以与其拼点：若你赢，其不能使用【闪】相应此【杀】/此【杀】对你无效。',
    ['$zhuandui1'] = '你已无话可说了吧！',
    ['$zhuandui2'] = '黄口小儿，也敢来班门弄斧？',
    ['tianbian'] = '天辩',
    [':tianbian'] = '当你拼点时，你可以用牌堆顶一张牌作为你的拼点牌；当你拼点的红桃牌亮出后，令之视为K。',
    ['$tianbian1'] = '当今天子为刘，天亦姓刘。',
    ['$tianbian2'] = '阁下知其然，而未知其所以然。',
    ['~qinmi'] = '我居然……也百口莫辩了……',

    ['xuezong'] = '薛综',
    ['#xuezong'] = '彬彬之玊',
    ['illustrator:xuezong'] = '秋呆呆',
    ['designer:xuezong'] = '韩旭',
    ['funan'] = '复难',
    [':funan'] = '当其他角色使用/打出牌响应你使用的牌时，你可以先令其获得你使用的牌且其于此回合内不能使用或打出之再令你获得其使用/打出的牌。',
    ['$funan1'] = '礼尚往来，乃君子风范。',
    ['$funan2'] = '以子之矛，攻子之盾。',
    ['jiexun'] = '诫训',
    ['jiexun-invoke'] = '你可以发动“诫训”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':jiexun'] = '结束阶段开始时，若场上有方块牌，你可以选择一名其他角色，其摸场上方块数量的牌，然后弃置X张牌，当其以此法失去所有牌后，你失去“诫训”，令其他角色无法因你发动的“复难”而获得牌。（X为此技能结算完毕的次数）',
    ['$jiexun1'] = '帝王应以社稷为重，以大观为主。',
    ['$jiexun2'] = '吾冒昧进谏，只求陛下思虑。',
    ['~xuezong'] = '尔等……竟做如此有辱斯文之事……',

    ['zodiac_zishu'] = '子鼠',
    ['#zodiac_zishu'] = '',
    [':ruishou'] = '锁定技，当你对一名角色或一名角色对你造成伤害时，若其势力与你不同且有与其势力相同且拥有“瑞兽”的角色，防止此伤害。',
    ['$ruishou1'] = '',
    ['$ruishou2'] = '',
    --[[['zishu'] = '子鼠',
    [':zishu'] = '出牌阶段限一次，你可以获得手牌数大于你的一名角色一张手牌且可以重复此流程。',
    ['$zishu1'] = '',
    ['$zishu2'] = '',
    ['~zodiac_zishu'] = '',]] --

    ['zodiac_chouniu'] = '丑牛',
    ['#zodiac_chouniu'] = '',
    ['chouniu'] = '丑牛',
    [':chouniu'] = '锁定技，游戏开始时，你的体力值变为1；锁定技，结束阶段开始时，若你为体力值最少的角色，你回复1点体力。',
    ['$chouniu1'] = '',
    ['$chouniu2'] = '',
    ['~zodiac_chouniu'] = '',

    ['zodiac_yinhu'] = '寅虎',
    ['#zodiac_yinhu'] = '',
    ['yinhu'] = '寅虎',
    [':yinhu'] = '出牌阶段，你可以弃置一张于此阶段内未以此法弃置过的相同类别的手牌并选择一名其他角色，对其造成1点伤害，然后若你以此法令一名角色进入濒死状态，此技能于此回合内无效。',
    ['$yinhu1'] = '',
    ['$yinhu2'] = '',
    ['~zodiac_yinhu'] = '',

    ['zodiac_maotu'] = '卯兔',
    ['#zodiac_maotu'] = '',
    ['maotu'] = '卯兔',
    [':maotu'] = '锁定技，若有与你势力相同的其他角色，你不是与你势力不同且体力值不小于你的对方角色使用牌的合法目标。',
    [':maotu_sp'] = '锁定技，若有与你势力相同的其他角色，你不是与你势力不同且体力值不小于你的其他角色使用牌的合法目标。',
    ['$maotu1'] = '',
    ['$maotu2'] = '',
    ['~zodiac_maotu'] = '',

    ['zodiac_chenlong'] = '辰龙',
    ['#zodiac_chenlong'] = '',
    ['chenlong'] = '辰龙',
    [':chenlong'] = '限定技，出牌阶段，你可以失去1至5点体力值并选择一名其他角色，对其造成等量的伤害；当你因“辰龙”而进入濒死状态时，你将体力值回复至1点，然后将体力上限变为1。',
    ['$chenlong1'] = '',
    ['$chenlong2'] = '',
    ['chuancheng'] = '传承',
    [':chuancheng'] = '锁定技，杀死你的角色获得此武将牌上此技能以外的一个技能，然后若有因“传承”而获得的其他技能，失去之。',
    ['$chuancheng1'] = '',
    ['$chuancheng2'] = '',
    ['~zodiac_chenlong'] = '',

    ['zodiac_sishe'] = '巳蛇',
    ['#zodiac_sishe'] = '',
    ['sishe'] = '巳蛇',
    [':sishe'] = '当你受到伤害后，你可以对来源造成等量的伤害。',
    ['$sishe1'] = '',
    ['$sishe2'] = '',
    ['~zodiac_sishe'] = '',

    ['zodiac_wuma'] = '午马',
    ['#zodiac_wuma'] = '',
    ['wuma'] = '午马',
    -- [':wuma'] = '锁定技，你不能翻面且不能跳过阶段。',
    [':wuma'] = '锁定技，你不能翻面且不能跳过阶段；锁定技，当你成为其他角色使用的锦囊牌的目标后，你摸一张牌。',
    ['$wuma1'] = '',
    ['$wuma2'] = '',
    ['~zodiac_wuma'] = '',

    ['zodiac_weiyang'] = '未羊',
    ['#zodiac_weiyang'] = '',
    ['weiyang'] = '未羊',
    -- [':weiyang'] = '出牌阶段限一次，你可以弃置至少一张牌并选择至多等量的角色，这些角色各回复1点体力。',
    [':weiyang'] = '出牌阶段限一次，你可以弃置至少一张类别各不相同的牌并选择至多等量的角色，这些角色各回复1点体力。',
    ['$weiyang1'] = '',
    ['$weiyang2'] = '',
    ['~zodiac_weiyang'] = '',

    ['zodiac_shenhou'] = '申猴',
    ['#zodiac_shenhou'] = '',
    ['shenhou'] = '申猴',
    [':shenhou'] = '当你成为【杀】的目标时，你可以判定，若结果为红色，此【杀】对你无效。',
    ['$shenhou1'] = '',
    ['$shenhou2'] = '',
    ['~zodiac_shenhou'] = '',

    ['zodiac_youji'] = '酉鸡',
    ['#zodiac_youji'] = '',
    ['youji'] = '酉鸡',
    [':youji'] = '锁定技，游戏开始时，你为1号位；锁定技，摸牌阶段，你多摸X张牌。（X为轮数）',
    ['$youji1'] = '',
    ['$youji2'] = '',
    ['~zodiac_youji'] = '',

    ['zodiac_xugou'] = '戌狗',
    ['#zodiac_xugou'] = '',
    ['xugou'] = '戌狗',
    [':xugou'] = '锁定技，红色【杀】对你无效且你使用红色【杀】无距离限制且你使用红色【杀】的伤害值基数+1。',
    ['$xugou1'] = '',
    ['$xugou2'] = '',
    ['~zodiac_xugou'] = '',

    ['zodiac_haizhu'] = '亥猪',
    ['#zodiac_haizhu'] = '',
    ['haizhu'] = '亥猪',
    [':haizhu'] = '锁定技，当其他角色的黑色牌因弃置而置入弃牌堆后，你获得之；锁定技，准备阶段开始，若你为手牌数最多的角色，你失去1点体力。',
    ['$haizhu1'] = '',
    ['$haizhu2'] = '',
    ['~zodiac_haizhu'] = '',

    ['easy_nianshou'] = '年兽', -- 简单
    ['#easy_nianshou'] = '',
    ['jiyuan'] = '汲源',
    [':jiyuan'] = '锁定技，结束阶段开始时，你摸X张牌。（X为你的体力上限的一半且向上取整）', -- OMT
    ['$jiyuan1'] = '',
    ['$jiyuan2'] = '',
    ['suizhong'] = '岁终', -- OMT
    [':suizhong'] = '限定技，当你进入濒死状态时，你可以将体力值回复至1点（然后若你不为简单年兽，所有其他角色各弃置所有牌），若当前回合角色不为你，结束当前回合。',
    ['$suizhong1'] = '',
    ['$suizhong2'] = '',
    ['cuiku'] = '摧枯',
    [':cuiku'] = '游戏开始时，或当轮数为6的倍数时，若你：为简单年兽，你可以选择一名其他角色，对其造成2点伤害；\
    为普通年兽，你可以选择一至两名其他角色，对这些角色各造成2点伤害；\
    为困难年兽，对所有其他角色各造成为其体力值一半的伤害，然后你摸等同于其中体力上限为奇数的角色数的牌。',
    [':cuiku_sp'] = '当轮数为6的倍数时，若你：为简单年兽，你可以选择一名其他角色，对其造成2点伤害；\
    为普通年兽，你可以选择一至两名其他角色，对这些角色各造成1点伤害；\
    为困难年兽，你选择三名体力值大于1的其他角色，对这些角色各造成1点伤害，然后你摸一张牌。',
    ['$cuiku1'] = '',
    ['$cuiku2'] = '',
    ['~easy_nianshou'] = '',

    ['normal_nianshou'] = '年兽', -- 普通
    ['#normal_nianshou'] = '',
    ['nianyi'] = '年裔',
    [':nianyi'] = '锁定技，你使用牌无距离限制；锁定技，准备阶段开始时，你随机弃置判定区里的一张牌；锁定技，其他角色的回合结束后，若你为困难年兽且你于此回合内失去过至少三张牌，你对所有其他角色各造成1点伤害。',
    [':nianyi_sp'] = '锁定技，你使用牌无距离限制；锁定技，准备阶段开始时，若你的判定区里有牌，你随机弃置区域里的一张牌，然后若你的判定区里有牌，重复此流程；\
    锁定技，其他角色的回合结束后，若你为困难年兽且你于此回合内失去过至少三张牌，你对当前回合角色造成1点伤害。',
    ['$nianyi1'] = '',
    ['$nianyi2'] = '',
    ['~normal_nianshou'] = '',

    ['ol_lingju'] = '灵雎',
    ['#ol_lingju'] = '',
    ['ol_fenxin'] = '焚心',
    [':ol_fenxin'] = '锁定技，当其他角色死亡时，若其为：忠臣，你发动“竭缘”减少伤害无体力值限制；反贼，你发动“竭缘”增加伤害无体力值限制；内奸，你发动“竭缘”无颜色限制且将“竭缘”描述中的“手牌”改为“牌”。',
    ['$ol_fenxin1'] = '',
    ['$ol_fenxin2'] = '',
    ['~ol_lingju'] = '',

    ['ol_zhangbao'] = '张宝',
    ['#ol_zhangbao'] = '地公将军',
    ['illustrator:ol_zhangbao'] = '大佬荣',
    ['ol_zhoufu'] = '咒缚',
    [':ol_zhoufu'] = '出牌阶段限一次，你可以将一张手牌置于一名没有“咒”的其他角色的武将牌上，称为“咒”；当拥有“咒”的角色判定时，其将一张“咒”当判定牌；一名角色的回合结束时，于此回合内因判定而失去“咒”的角色各失去1点体力。',
    ['$ol_zhoufu1'] = '',
    ['$ol_zhoufu2'] = '',
    ['ol_yingbing'] = '影兵',
    [':ol_yingbing'] = '锁定技，当拥有“咒”的角色使用与“咒”花色相同的牌时，你摸一张牌，然后若你因其的此“咒”以此法摸过两张牌，将此“咒”置入弃牌堆。',
    ['$ol_yingbing1'] = '',
    ['$ol_yingbing2'] = '',
    ['~ol_zhangbao'] = '',

    ['ol_maliang'] = '马良',
    ['#ol_maliang'] = '白眉智士',
    ['illustrator:ol_maliang'] = 'depp',
    ['zishu'] = '自书',
    [':zishu'] = '锁定技，当你于回合内不因“自书”而获得牌后，你摸一张牌；锁定技，其他角色的回合结束时，你将于此回合内获得的手牌置入弃牌堆。',
    ['$zishu1'] = '',
    ['$zishu2'] = '',
    ['yingyuan'] = '应援',
    ['yingyuan-invoke'] = '你可以发动“应援”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':yingyuan'] = '当你于回合内使用牌置入弃牌堆后，若之与你于此回合内以此法交给其他角色的牌名均不同，你可以将之交给一名角色。',
    ['$yingyuan1'] = '',
    ['$yingyuan2'] = '',
    ['~ol_maliang'] = '',

    ['ol_chenqun'] = '陈群',
    ['#ol_chenqun'] = '握卷之臣',
    ['illustrator:ol_chenqun'] = '大佬荣',
    ['pindi'] = '品第',
    ['pindi1'] = '其摸X张牌',
    ['pindi2'] = '其弃置X张牌',
    [':pindi'] = '出牌阶段，你可以弃置一张未于此阶段内以此法弃置过的相同类型的牌并选择一名未于此阶段内成为过此技能目标的其他角色，你选择一项：其摸X张牌；其弃置X张牌。然后若其已受伤，你横置。（X为你于此回合内发动此技能的次数）',
    ['$pindi1'] = '',
    ['$pindi2'] = '',
    ['ol_faen'] = '法恩',
    [':ol_faen'] = '当一名角色翻面（若其武将牌正面朝上）或横置后，你可以令其摸一张牌。',
    ['$ol_faen1'] = '',
    ['$ol_faen2'] = '',
    ['~ol_chenqun'] = '',

    ['beimihu'] = '卑弥呼',
    ['#beimihu'] = '亲魏倭王',
    ['illustrator:beimihu'] = 'Town',
    ['zongkui'] = '纵傀',
    ['zongkui-invoke'] = '你可以发动“纵傀”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['@puppet'] = '傀',
    [':zongkui'] = '回合开始前，你可以选择一名没有“傀”标记的其他角色，其获得1枚“傀”标记；每轮开始时，你选择一名除你外体力值最少且没有“傀”标记的其他角色，其获得1枚“傀”标记。',
    ['$zongkui1'] = '准备好听候女王的差遣了吗？',
    ['$zongkui2'] = '契约已定。',
    ['guju'] = '骨疽',
    [':guju'] = '锁定技，当拥有“傀”标记的角色受到伤害后，你摸一张牌。',
    ['$guju1'] = '我能看到你的灵魂在颤抖。',
    ['$guju2'] = '你死后，我将超度你的亡魂。',
    ['baijia'] = '拜假',
    [':baijia'] = '觉醒技，准备阶段开始时，若你因“骨疽”而获得的牌数不小于7，你加1点体力上限，回复1点体力，然后令所有没有“傀”标记的其他角色获得1枚“傀”标记，你失去“骨疽”，获得“蚕食”。',
    ['$baijia1'] = '以邪马台的名义。',
    ['$baijia2'] = '我要摧毁你的一切，然后建立我的国度。',
    ['canshib'] = '蚕食',
    ['@canshib'] = '你可以发动“蚕食”',
    ['~canshib'] = '选择若干名拥有“傀”标记的角色->点击确定',
    [':canshib'] = '当一名角色使用牌指定目标时，若其有“傀”标记且目标数为1且目标有你，你可以取消自己，然后其弃1枚“傀”标记；当你使用牌指定目标时，若目标数为1，你可以令至少一名拥有“傀”标记的角色成为此牌的目标，然后这些角色各弃1枚“傀”标记。',
    ['$canshib1'] = '是你在召唤我吗？',
    ['$canshib2'] = '这片土地的人真是太有趣了。',
    ['~beimihu'] = '我还会从黄泉比良坂,回来的',

    ['ol_zhuhuan'] = '朱桓',
    ['#ol_zhuhuan'] = '嘉兴侯',
    ['fenli'] = '奋励',
    [':fenli'] = '若你为：手牌数最多的角色，你可以跳过摸牌阶段；体力值最多的角色，你可以跳过出牌阶段；装备区里有牌且牌数最多的角色，你可以跳过弃牌阶段。',
    -- [':fenli'] = '若你为手牌数最多/体力值最多/装备区里有牌且牌数最多的角色，你可以跳过摸牌/出牌/弃牌阶段。',
    ['$fenli1'] = '',
    ['$fenli2'] = '',
    ['pingkou'] = '平寇',
    ['@pingkou'] = '你可以发动“平寇”',
    ['~pingkou'] = '选择若干名角色->点击确定',
    [':pingkou'] = '回合结束时，你可以对X名其他角色各造成1点伤害。（X为你于此回合内跳过的阶段数）',
    ['$pingkou1'] = '',
    ['$pingkou2'] = '',
    ['~ol_zhuhuan'] = '',

    ['sufei'] = '苏飞',
    ['#sufei'] = '与子同胞',
    ['illustrator:sufei'] = '兴游',
    ['lianpian'] = '联翩',
    [':lianpian'] = '当一名角色于其出牌阶段内使用牌指定目标后，若目标中有其于此阶段内使用的上一张牌的目标，你可以令其摸一张牌。',
    ['$lianpian1'] = '',
    ['$lianpian2'] = '',
    ['~sufei'] = '',

    ['huangquan'] = '黄权',
    ['#huangquan'] = '道绝殊途',
    ['illustrator:huangquan'] = '兴游',
    ['dianhu'] = '点虎',
    [':dianhu'] = '锁定技，游戏开始时，你选择一名其他角色，若如此做，当与你势力相同的角色对其造成伤害后，你选择是否令来源摸一张牌。',
    ['$dianhu1'] = '',
    ['$dianhu2'] = '',
    ['jianji'] = '谏计',
    ['@jianji'] = '你可以发动“谏计”使用牌',
    [':jianji'] = '出牌阶段限一次，你可以选择一名与你势力相同的其他角色，其摸一张牌，然后其可以使用之。',
    ['$jianji1'] = '',
    ['$jianji2'] = '',
    ['~huangquan'] = '',

    ['luzhi'] = '鲁芝',
    ['#luzhi'] = '夷夏慕德',
    ['qingzhong'] = '清忠',
    ['qingzhong-invoke'] = '你（可以）发动“清忠”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>',
    [':qingzhong'] = '出牌阶段开始时，你可以摸两张牌，若如此做，此阶段结束时，若你：为手牌数最少的角色，你可以与手牌数最少的角色交换手牌；不为手牌数最少的角色，你与手牌数最少的角色交换手牌。',
    ['$qingzhong1'] = '执政为民，当尽我所能！',
    ['$qingzhong2'] = '吾自幼流离失所，更能体恤百姓之苦~',
    ['weijing'] = '卫境',
    [':weijing'] = '每轮限一次，你可以视为使用【杀】/【闪】。',
    ['$weijing1'] = '战事兴起，最苦的仍是百姓！',
    ['$weijing2'] = '国乃大家，保大家才有小家。',
    ['~luzhi'] = '',

    ['simahui'] = '司马徽',
    ['#simahui'] = '水镜先生',
    ['jianjie'] = '荐杰',
    ['jianjievs'] = '荐杰',
    ['@dragon'] = '龙印',
    ['@phoenix'] = '凤印',
    ['@jianjie'] = '你可以发动“荐杰”',
    ['~jianjie'] = '选择角色→点击确定',
    [':jianjie'] = '第一个准备阶段开始时，你选择两名角色，其中一名角色获得1枚“龙印”标记，令一名角色获得1枚“凤印”标记；\
    出牌阶段限一次（若此回合不是你的第一个回合，你选择一名拥有1“龙印”/“凤印”标记的角色）或当拥有“龙印”/“凤印”标记的角色死亡时，你可以令其将其拥有的“龙印”/“凤印”标记的角色弃所有“龙印”/“凤印”标记，然后令另一名角色获得1枚“龙印”/“凤印”标记；\
    拥有“龙印”/“凤印”的角色拥有“火计”/“连环”，以此法获得的技能每名角色的回合限发动三次；拥有“龙印”和“凤印”的角色拥有“业炎”，以此法获得的技能发动后，其弃所有“龙印”标记和“凤印”标记。',
    ['$jianjie1'] = '卧龙凤雏，二者得一，可安天下',
    ['$jianjie2'] = '公怀王佐之才，宜择人而仕',
    ['$jianjie3'] = '二人齐聚，汉室可兴矣',
    ['dragon_move'] = '移动龙印',
    ['phoenix_move'] = '移动凤印',
    ['chenghao'] = '称好',
    ['#YinshiProtect'] = '%from 的“<font color="yellow"><b>隐士</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]',
    [':chenghao'] = '当一名角色受到伤害时，若之不为传导伤害且其处于连环状态，你可以观看牌堆顶的X张牌，然后将这些牌交给至少一名角色。（X为处于连环状态的角色数）',
    ['$chenghao1'] = '好，很好，非常好',
    ['$chenghao2'] = '您的话也很好',
    ['yinshi'] = '隐士',
    [':yinshi'] = '锁定技，当你受到属性伤害或由锦囊牌造成的伤害时，若你没有“龙印”标记且没有“凤印”标记且装备区里没有防具牌，你防止此伤害。',
    ['$yinshi1'] = '山野闲散之人，不堪世用',
    ['$yinshi2'] = '我老啦，会有胜我十倍的人来帮助你',
    ['~simahui'] = '这似乎……没那么好了……',

    ['pangdegong'] = '庞德公',
    ['#pangdegong'] = '德懿举世',
    ['pingcai'] = '评才',
    [':pingcai'] = '出牌阶段限一次，你可以选择一项：\
    1.若所有角色中有诸葛亮（火），你对一至两名角色各造成1点火焰伤害，否则你对一名角色造成1点火焰伤害；\
    2.若所有角色中有庞统，你横置一至四名角色，否则你横置一至三名角色；\
    3.若所有角色中有司马徽，你将一名角色装备区里的装备牌置入另一名角色的装备区，否则你将一名角色装备区里的防具牌置入另一名角色的装备区；\
    4.若所有角色中有徐庶，你令一名角色摸一张牌，其回复1点体力，然后你摸一张牌，否则你令一名角色摸一张牌，其回复1点体力。',
    ['pingcai_wolong'] = '卧龙',
    [':pingcai_wolong'] = '出牌阶段限一次，你可以对一至X名角色各造成1点火焰伤害。（若所有角色中有诸葛亮（火），X为2，否则X为1）',
    ['pingcai_fengchu'] = '凤雏',
    [':pingcai_fengchu'] = '出牌阶段限一次，你可以横置一至X名角色。（若所有角色中有庞统，X为4，否则X为3）',
    ['pingcai_shuijing'] = '水镜',
    [':pingcai_shuijing'] = '出牌阶段限一次，若所有角色中：有司马徽，你可以将一名角色装备区里的装备牌置入另一名角色的装备区；没有司马徽，你可以将一名角色装备区里的防具牌置入另一名角色的装备区。',
    ['pingcai_xuanjian'] = '玄剑',
    [':pingcai_xuanjian'] = '出牌阶段限一次，若所有角色中：有徐庶，你可以令一名角色摸一张牌，其回复1点体力，然后你摸一张牌；没有徐庶，你令一名角色摸一张牌，其回复1点体力。',
    ['$pingcai1'] = '',
    ['$pingcai2'] = '',
    ['$pingcai3'] = '',
    ['$pingcai4'] = '',
    ['$pingcai5'] = '',
    ['yinship'] = '隐世',
    [':yinship'] = '锁定技，你跳过准备/判定/结束阶段；锁定技，你不是延时类锦囊牌的合法目标。',
    ['$yinship1'] = '',
    ['$yinship2'] = '',
    ['~pangdegong'] = '',

    ['shenliubei'] = '神刘备',
    ['#shenliubei'] = '誓守桃园义',
    ['longnu'] = '龙怒',
    ['longnu_red'] = '龙怒',
    ['longnu_trick'] = '龙怒',
    [':longnu'] = '转换技，锁定技，出牌阶段开始时，①你失去1点体力并摸一张牌，令你于此回合内红色手牌视为火【杀】且无距离限制；②你减1点体力上限并摸一张牌，令你于此阶段内锦囊牌视为雷【杀】且无次数限制。',
    [':longnu1'] = '转换技，锁定技，出牌阶段开始时，\
    ①你失去1点体力并摸一张牌，令你于此回合内红色手牌视为火【杀】且无距离限制；\
    <font color="#01A5AF"><s>②你减1点体力上限并摸一张牌，令你于此阶段内锦囊牌视为雷【杀】且无次数限制</s></font>。',
    [':longnu2'] = '转换技，锁定技，出牌阶段开始时，\
    <font color="#01A5AF"><s>①你失去1点体力并摸一张牌，令你于此回合内红色手牌视为火【杀】且无距离限制</s></font>；\
    ②你减1点体力上限并摸一张牌，令你于此阶段内锦囊牌视为雷【杀】且无次数限制。',
    ['$longnu1'] = '龙怒降临，岂是尔等凡人可抗？',
    ['$longnu2'] = '龙意怒火，汝皆不能逃脱！',
    ['jieying'] = '结营',
    ['jieying-invoke'] = '你可以发动“结营”<br/> <b>操作提示</b>: 选择一名不处于连环状态的角色→点击确定<br/>',
    [':jieying'] = '锁定技，你视为处于连环状态；锁定技，处于连环状态的角色的手牌上限+2；锁定技，结束阶段开始时，你横置一名角色。',
    ['$jieying1'] = '桃园结义，营一时之交。',
    ['$jieying2'] = '结草衔环，报兄弟大恩。',
    ['~shenliubei'] = '桃园依旧，来世再结。',

    ['shenluxun'] = '神陆逊',
    ['#shenluxun'] = '红莲业火',
    ['illustrator:shenluxun'] = 'Thinking',
    ['junlve'] = '军略',
    ['@junlve'] = '军略',
    [':junlve'] = '锁定技，当你造成或受到1点伤害后，你获得1枚“军略”标记。',
    ['$junlve1'] = '文韬武略兼备，方可破敌如破竹。',
    ['$junlve2'] = '军略绵腹，制敌千里。',
    ['cuike'] = '摧克',
    ['cuike-invoke'] = '你可以发动“摧克”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':cuike'] = '出牌阶段开始时，若你拥有的“军略”标记数为：奇数，你可以对一名角色造成1点伤害；偶数，你可以横置一名角色，然后弃置其一张牌。\
    然后若你拥有的“军略”标记数大于7，你可以弃所有“军略”标记，对所有其他角色各造成1点伤害。',
    ['$cuike1'] = '摧敌心神，克敌计谋。',
    ['$cuike2'] = '克险摧难，军略当先。',
    ['zhanhuo'] = '绽火',
    ['@zhanhuo'] = '你可以发动“绽火”',
    ['~zhanhuo'] = '选择若干名处于连环状态的角色（第一个目标将会受到火焰伤害）→点击确定',
    [':zhanhuo'] = '限定技，出牌阶段开始时，你可以弃所有“军略”标记并选择至多等量的处于连环状态的角色，这些角色各弃置装备区里的所有牌，然后对其中一名角色造成1点火焰伤害。',
    ['$zhanhuo1'] = '绽东吴业火，烧敌军数千！',
    ['$zhanhuo2'] = '业火映东水，吴志绽敌营！',
    ['~shenluxun'] = '东吴业火，终究熄灭……',

    ['yanyan'] = '严颜',
    ['#yanyan'] = '断头将军',
    ['illustrator:yanyan'] = 'Town',
    ['juzhan'] = '拒战',
    [':juzhan'] = '转换技，①当你成为其他角色使用【杀】的目标后，你可以与其各摸一张牌，然后其本回合不能对你使用牌；②当你使用【杀】指定一名角色为目标后，你可以获得其一张牌，然后你本回合不能对其使用牌。',
    [':juzhan1'] = '转换技，①当你成为其他角色使用【杀】的目标后，你可以与其各摸一张牌，然后其本回合不能对你使用牌；\
    <font color="#01A5AF"><s>②当你使用【杀】指定一名角色为目标后，你可以获得其一张牌，然后你本回合不能对其使用牌</s></font>。',
    [':juzhan2'] = '转换技，<font color="#01A5AF"><s>①当你成为其他角色使用【杀】的目标后，你可以与其各摸一张牌，然后其本回合不能对你使用牌</s></font>；\
    ②当你使用【杀】指定一名角色为目标后，你可以获得其一张牌，然后你本回合不能对其使用牌。',
    ['$juzhan1'] = '砍头便砍头，何为怒邪！',
    ['$juzhan2'] = '我州但有断头将军，无降将军之也！',
    ['~yanyan'] = '宁可断头死，安能屈膝降！',

    ['wangping'] = '王平',
    ['#wangping'] = '兵谋以致用',
    ['illustrator:wangping'] = 'YanBai',
    ['feijun'] = '飞军',
    [':feijun'] = '出牌阶段限一次，你可以弃置一张牌并选择一项：1.令一名手牌数大于你的角色将一张手牌交给你；2.令一名装备区里的牌数大于你的角色弃置其装备区里的一张牌。',
    [':feijun1'] = '令一名手牌数大于你的角色将一张手牌交给你',
    [':feijun2'] = '令一名装备区里的牌数大于你的角色弃置其装备区里的一张牌',
    ['$feijun1'] = '无当飞军，伐叛乱，镇蛮夷！',
    ['$feijun2'] = '山地崎岖，也挡不住飞军破势！',
    ['binglve'] = '兵略',
    [':binglve'] = '锁定技，当你发动“飞军”时，若你未指定过其为“飞军”的目标，你摸两张牌。',
    ['$binglve1'] = '奇略兵速，敌未能料之。',
    ['$binglve2'] = '兵略者，明战胜攻取之数、形机之势、诈谲之变。',
    ['~wangping'] = '无当飞军，也有困于山林之时……',

    ['kuaiyuekuailiang'] = '蒯越＆蒯良',
    ['#kuaiyuekuailiang'] = '雍论臼谋',
    ['illustrator:kuaiyuekuailiang'] = '北辰南',
    ['jianxiang'] = '荐降',
    [':jianxiang'] = '当你成为其他角色使用牌的目标后，你可以令一名手牌数最少的角色摸一张牌。',
    ['$jianxiang1'] = '得遇曹公，吾之幸也。',
    ['$jianxiang2'] = '曹公得荆不喜，喜得吾二人足以。',
    ['jianxiang-invoke'] = '你可以发动“荐降”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['shenshi'] = '审时',
    ['shenshi-invoke'] = '你可以发动“审时”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['@shenshi_give'] = '请交给 %src 一张牌',
    [':shenshi'] = '转换技，①出牌阶段限一次，你可以将一张牌交给一名手牌数最多的角色，对其造成1点伤害，然后若其以此法死亡，你可以选择一名角色，其将手牌补至四张；\
    ②当其他角色对你造成伤害后，你可以观看其的手牌，然后交给其一张牌，若如此做，当前回合结束时，若其未失去你以此法交给其的牌，你将手牌补至四张。',
    [':shenshi1'] = '转换技，①出牌阶段限一次，你可以将一张牌交给一名手牌数最多的角色，对其造成1点伤害，然后若其以此法死亡，你可以选择一名角色，其将手牌补至四张；\
    <font color="#01A5AF"><s>②当其他角色对你造成伤害后，你可以观看其的手牌，然后交给其一张牌，若如此做，当前回合结束时，若其未失去你以此法交给其的牌，你将手牌补至四张</s></font>。',
    [':shenshi2'] = '转换技，<font color="#01A5AF"><s>①出牌阶段限一次，你可以将一张牌交给一名手牌数最多的角色，对其造成1点伤害，然后若其以此法死亡，你可以选择一名角色，其将手牌补至四张</s></font>；\
    ②当其他角色对你造成伤害后，你可以观看其的手牌，然后交给其一张牌，若如此做，当前回合结束时，若其未失去你以此法交给其的牌，你将手牌补至四张。',
    ['$shenshi1'] = '深中足智，见时审情。',
    ['$shenshi2'] = '数语之言，审时度势。',
    ['~kuaiyuekuailiang'] = '表不能善用，所憾也。',

    ['luji'] = '陆绩',
    ['#luji'] = '瑚琏之器',
    ['illustrator:luji'] = '秋呆呆',
    ['huaiju'] = '怀橘',
    [':huaiju'] = '锁定技，游戏开始时，你获得3枚“橘”标记；锁定技，当拥有“橘”标记的角色受到伤害时，防止此伤害，然后其弃1枚“橘”标记；锁定技，拥有“橘”标记的角色的额定摸牌数+1。',
    ['@orange'] = '橘',
    ['$huaiju1'] = '袖中怀绿桔，遗母报乳哺。',
    ['$huaiju2'] = '情深舐犊，怀着藏橘。',
    ['yili'] = '遗礼',
    [':yili'] = '出牌阶段开始时，你可以失去1点体力或弃1枚“橘”标记并选择一名其他角色，然后其获得1枚“橘”标记。',
    ['yili1'] = '失去1点体力',
    ['yili2'] = '弃1枚“橘”标记',
    ['yili-invoke'] = '你可以发动“遗礼”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['$yili1'] = '违失礼仪，则俱非议。',
    ['$yili2'] = '行遗礼之举，于不敬王者。',
    ['zhenglun'] = '整论',
    [':zhenglun'] = '若你没有“橘”标记，你可以跳过摸牌阶段，然后获得1枚“橘”标记。',
    ['$zhenglun1'] = '整论四海未泰，修文德以平。',
    ['$zhenglun2'] = '今论者不务道德怀取之术，而惟尚武，窃所未安。',
    ['~luji'] = '恨不能见，车同轨，书同文……',

    ['sunliang'] = '孙亮',
    ['#sunliang'] = '寒江枯水',
    ['illustrator:sunliang'] = '眉毛子',
    ['kuizhu'] = '溃诛',
    ['@kuizhu'] = '你可以发动“溃诛”',
    ['~kuizhu'] = '选择若干名角色->点击确定',
    ['kuizhu1'] = '令一至X名角色各摸一张牌',
    ['kuizhu2'] = '对至少一名体力值之和为X的角色造成1点伤害，然后若以此法选择的角色数不小于2，你对你造成1点伤害',
    [':kuizhu'] = '弃牌阶段结束时，你可以选择一项：1.令一至X名角色各摸一张牌；2.对至少一名体力值之和为X的角色造成1点伤害，然后若以此法选择的角色数不小于2，你对你造成1点伤害。（X为你于此阶段内弃置的牌数）',
    ['$kuizhu1'] = '子通专恣，必谋而诛之！',
    ['$kuizhu2'] = '孙綝久专，不可久忍，必溃诛！',
    ['chezheng'] = '掣政',
    ['chezheng-invoke'] = '你可以发动“掣政”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':chezheng'] = '锁定技，攻击范围内没有你的角色于你的出牌阶段内不是你使用牌的合法目标；锁定技，出牌阶段结束时，若你于此阶段内使用的牌数小于攻击范围内没有你的角色数，你弃置其中一名角色一张牌。',
    ['$chezheng1'] = '风驰电掣，政权不怠。',
    ['$chezheng2'] = '唉~廉平掣政，实为艰事。',
    ['lijun'] = '立军',
    [':lijun'] = '主公技，当其他吴势力角色使用【杀】结算完毕时，其可以将之交给你，然后你可以令其摸一张牌。',
    ['$lijun1'] = '立于朝堂，定于军心。',
    ['$lijun2'] = '君立于朝堂，军侧于四方。',
    ['~sunliang'] = '今日欲诛逆臣而不得，方知机事不密则害成……',

    ['ol_xuyou'] = '许攸',
    ['#ol_xuyou'] = '朝秦暮楚',
    ['chenglve'] = '成略',
    [':chenglve'] = '转换技，①出牌阶段限一次，你可以摸一张牌，然后弃置两张手牌；②你可以摸两张牌，然后弃置一张手牌。若如此做，你于此回合内使用与以此法弃置的牌相同花色的牌无距离和次数限制。',
    [':chenglve1'] = '转换技，<font color="#01A5AF"><s>①出牌阶段限一次，你可以摸一张牌，然后弃置两张手牌</s></font>；\
    ②你可以摸两张牌，然后弃置一张手牌。若如此做，你于此回合内使用与以此法弃置的牌相同花色的牌无距离和次数限制。',
    [':chenglve2'] = '转换技，①出牌阶段限一次，你可以摸一张牌，然后弃置两张手牌；\
    <font color="#01A5AF"><s>②你可以摸两张牌，然后弃置一张手牌</s></font>。若如此做，你于此回合内使用与以此法弃置的牌相同花色的牌无距离和次数限制。',
    ['$chenglve1'] = '成略在胸，良计速出。',
    ['$chenglve2'] = '吾有良略在怀，必为阿瞒所需。',
    ['@disOne'] = '请弃置一张手牌',
    ['@disTwo'] = '请弃置两张手牌',
    ['#shicai_put'] = '%from 将 %card 置于牌堆顶',
    ['ol_shicai'] = '恃才',
    [':ol_shicai'] = '当你使用牌结算完毕后，若此牌与你于此回合使用过的牌类别均不同，你可以将之置于牌堆顶，然后摸一张牌。',
    ['$ol_shicai1'] = '吾才满腹，袁本初竟不从之！',
    ['$ol_shicai2'] = '阿瞒有我良计，取冀州便是易如反掌！',
    ['cunmu'] = '寸目',
    [':cunmu'] = '锁定技，你的摸牌视为从牌堆底摸牌。',
    ['$cunmu1'] = '哼~目光所及，短寸之间。',
    ['$cunmu2'] = '狭目之间，只能窥底。',
    ['~ol_xuyou'] = '阿瞒！没有我，你得不到冀州啊！',

    ['luzhiy'] = '卢植',
    ['#luzhiy'] = '国之桢干',
    ['mingren'] = '明任',
    [':mingren'] = '分发起始手牌时，你多摸一张牌，然后将一张手牌置于武将牌上，称为“任”；结束阶段开始时，你可以用一张手牌替换“任”。',
    ['$mingren1'] = '得义真所救，吾任之必尽瘁以报！',
    ['$mingren2'] = '吾之任，君之明举。',
    ['mingren_put'] = '请将一张手牌做为“任”',
    ['mingren_exchange'] = '你可以用手牌替换“任”',
    ['ren'] = '任',
    ['zhenliang'] = '贞良',
    [':zhenliang'] = '转换技，①出牌阶段限一次，你可以选择一名攻击范围内的其他角色并弃置X张与“任”颜色相同的牌，对其造成1点伤害；\
    ②当你于回合外使用或打出的牌置入弃牌堆时，若此牌与“任”类别相同，你可以令一名角色摸一张牌。（X为你与其体力值之差且至少为1）',
    [':zhenliang1'] = '转换技，<font color="#01A5AF"><s>①出牌阶段限一次，你可以选择一名攻击范围内的其他角色并弃置X张与“任”颜色相同的牌，对其造成1点伤害</s></font>；\
    ②当你于回合外使用或打出的牌置入弃牌堆时，若此牌与“任”类别相同，你可以令一名角色摸一张牌。（X为你与其体力值之差且至少为1）',
    [':zhenliang2'] = '转换技，①出牌阶段限一次，你可以选择一名攻击范围内的其他角色并弃置X张与“任”颜色相同的牌，对其造成1点伤害；\
    <font color="#01A5AF"><s>②当你于回合外使用或打出的牌置入弃牌堆时，若此牌与“任”类别相同，你可以令一名角色摸一张牌</s></font>。（X为你与其体力值之差且至少为1）',
    ['$zhenliang1'] = '风霜以别草木之性，危乱而见贞良之节。',
    ['$zhenliang2'] = '贞节贤良，吾之本心。',
    ['zhenliang-invoke'] = '你可以发动“贞良”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['@zhenliang-1'] = '贞良1',
    ['@zhenliang-2'] = '贞良2',
    ['~luzhiy'] = '泓泓眸子渊亭，不见蛾眉只见经……',

    ['haozhao'] = '郝昭',
    ['#haozhao'] = '扣弦的豪将',
    ['illustrator:haozhao'] = '秋呆呆',
    ['zhengu'] = '镇骨',
    ['zhengu-invoke'] = '你可以发动“镇骨”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':zhengu'] = '结束阶段开始时，你可以选择一名角色，若如此做，此回合或其的下回合的回合结束时，其将手牌数补/弃至与你手牌数相同。',
    ['$zhengu1'] = '镇守城池，当以骨相拼！',
    ['$zhengu2'] = '孔明计虽百算，却难抵吾镇骨千拒。',
    ['~haozhao'] = '镇守陈仓，也有一失……',

    ['guanqiujian'] = '毌丘俭',
    ['#guanqiujian'] = '镌功名征荣',
    ['zhengrong'] = '征荣',
    [':zhengrong'] = '当你对其他角色造成伤害后，若其手牌比你多，你可以将其一张牌置于你的武将牌上，称为“荣”。',
    ['$zhengrong1'] = '东征高句丽，保辽东安稳！',
    ['$zhengrong2'] = '跨海东征，家国俱荣！',
    ['honor'] = '荣',
    ['zhengrong:zhengrong-invoke'] = '你可以发动“征荣”，将 %src 的一张牌置为“荣”<br/> <b>操作提示</b>: 点击确定<br/>',
    ['hongju'] = '鸿举',
    [':hongju'] = '觉醒技，准备阶段开始时，若“荣”数不小于3且有已死亡的角色，你用任意张手牌替换等量的“荣”，然后减1点体力上限，获得“清侧”。',
    ['@hongju'] = '你可以从中将与“荣”数量相同的牌置为新的“荣”',
    ['~hongju'] = '选择要替换的手牌和不需要替换的“荣”→点击确定',
    ['$hongju1'] = '一举拿下，鸿途可得！',
    ['$hongju2'] = '鸿飞荣升，举重若轻！',
    ['qingce'] = '清侧',
    [':qingce'] = '出牌阶段，你可以将一张“荣”置入弃牌堆并选择一名装备区或判定区有牌的角色，然后弃置其装备区或判定区里的一张牌。',
    ['$qingce1'] = '感明帝之恩，清君侧之贼！',
    ['$qingce2'] = '得太后手诏，清奸佞乱臣！',
    ['~guanqiujian'] = '峥嵘一生，然被平民所击射！',

    ['chendao'] = '陈到',
    ['#chendao'] = '白毦督',
    ['illustrator:chendao'] = '王立雄',
    ['wanglie'] = '往烈',
    [':wanglie'] = '你于出牌阶段内使用的第一张牌无距离限制；当你于出牌阶段内使用牌时，你可以令其他角色不能响应此牌，然后你于此阶段内不能使用牌。',
    ['$wanglie1'] = '猛将之烈，统帅之所往。',
    ['$wanglie2'] = '与子龙忠勇相往，猛烈相合。',
    ['~chendao'] = '我的白毦兵，再也不能为先帝出力了……',

    ['zhugezhan'] = '诸葛瞻',
    ['#zhugezhan'] = '临难死义',
    ['illustrator:zhugezhan'] = 'zoo',
    ['zuilun'] = '罪论',
    [':zuilun'] = '出牌阶段，你可以获得一名角色一张牌，然后其摸一张牌，你于此阶段内不能以此法获得与之牌区相同的牌。',
    ['$zuilun1'] = '吾有三罪，未能除黄皓，制伯约，守国土。',
    ['$zuilun2'] = '数罪当论，吾愧对先帝恩惠。',
    ['fuyin'] = '父荫',
    [':fuyin'] = '锁定技，若你的装备区里没有防具牌，你不是手牌数不小于你的其他角色使用【杀】和【决斗】和【火攻】的合法目标。',
    ['$fuyin1'] = '得父荫庇，平步青云。',
    ['$fuyin2'] = '吾自幼心怀父诫，方不愧父亲荫庇。',
    ['~zhugezhan'] = '临难而死义，无愧先父。',

    ['zhoufei'] = '周妃',
    ['#zhoufei'] = '软玉温香',
    ['illustrator:zhoufei'] = '眉毛子',
    ['liangyin'] = '良姻',
    ['liangyin-invoke'] = '你可以发动“良姻”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':liangyin'] = '当一张牌置于一名角色的武将牌上/旁后，你可以令一名手牌数大于你的角色摸一张牌；当一名角色从武将牌上/旁获得牌后，你可以令一名手牌数小于你的角色弃置一张牌。',
    ['$liangyin1'] = '结得良姻，固吴基业。',
    ['$liangyin2'] = '君恩之命，妾身良姻之福。',
    ['kongsheng'] = '箜声',
    ['@kongsheng'] = '你可以发动“箫声”',
    ['~kongsheng'] = '选择一名角色→点击确定',
    ['music'] = '声',
    [':kongsheng'] = '准备阶段开始时，你可以将至少一张牌置于武将牌上，称为“声”；结束阶段开始时，若你有“声”，你使用其中的所有装备牌，然后获得所有“声”。',
    ['$kongsheng1'] = '窈窕淑女，箜篌友之。',
    ['$kongsheng2'] = '箜篌声声，琴瑟鸣鸣。',
    ['~zhoufei'] = '夫君，妾身再也不能，陪你看这江南翠绿了……',

    ['ol_lukang'] = '陆抗',
    ['#ol_lukang'] = '社稷之瑰宝',
    ['cv:ol_lukang'] = '官方',
    ['illustrator:ol_lukang'] = 'zoo',
    ['qianjie'] = '谦节',
    [':qianjie'] = '锁定技，你不能横置；锁定技，你不是延时类锦囊牌的合法目标；锁定技，你不是其他角色拼点的合法目标。',
    ['$qianjie1'] = '继父之节，谦逊恭毕。',
    ['$qianjie2'] = '谦谦清廉德，节节卓尔茂。',
    ['jueyan'] = '决堰',
    ['jueyan0'] = '武器栏',
    ['jueyan1'] = '防具栏',
    ['jueyan2'] = '坐骑栏×2',
    ['jueyan4'] = '宝物栏',
    [':jueyan'] = '出牌阶段限一次，你可以废除一个坐骑栏以外的装备栏或两个坐骑栏，若之为：武器栏，你于此回合内使用【杀】的次数上限+3；防具栏，你摸三张牌且于此回合内手牌上限+3；坐骑栏，你于此回合内使用牌无距离限制；宝物栏，你于此回合内拥有“集智”。',
    ['$jueyan1'] = '毁堰坝之计，实为阻晋粮道。',
    ['$jueyan2'] = '堰坝毁之，可令敌军自退。',
    ['poshi'] = '破势',
    [':poshi'] = '觉醒技，准备阶段开始时，若你没有装备区或你的体力值为1，你减1点体力上限，然后将手牌补至体力上限，失去“决堰”，获得“怀柔”。',
    ['$poshi1'] = '破晋军分进合击之势，牵晋军主力之实。',
    ['$poshi2'] = '破羊祜之策，势在必行。',
    ['huairou'] = '怀柔',
    [':huairou'] = '你可以重铸装备牌。',
    ['$huairou1'] = '胸怀千万，彰其德，包其柔。',
    ['$huairou2'] = '各保分界，无求细利。',
    ['~ol_lukang'] = '吾既亡矣，吴又能存几时？',

    ['god_yuanshu'] = '袁术',
    ['#god_yuanshu'] = '仲家帝',
    ['illustrator:god_yuanshu'] = '波子',
    ['cv:god_yuanshu'] = '寂镜Jnrio',
    ['god_yongsi'] = '庸肆',
    [':god_yongsi'] = '锁定技，摸牌阶段开始时，你放弃摸牌，然后摸X张牌；锁定技，弃牌阶段开始时，若你于此回合内：没有造成过伤害，你将手牌补至体力值；造成过的伤害值大于1，你于此回合内的手牌上限为已损失的体力值。（X为势力数）',
    ['$god_yongsi1'] = '看我大淮南，兵精粮足！',
    ['$god_yongsi2'] = '老子明牌，不虚你们这些渣渣！',
    ['god_weidi'] = '伪帝',
    ['@god_weidiput'] = '你可以发动“伪帝”',
    ['~god_weidi'] = '选择一张牌→选择一名角色→点击确定',
    [':god_weidi'] = '主公技，当你的牌于弃牌阶段因弃置而置入弃牌堆时，你可以交给至少一名群势力其他角色各一张其中的牌。',
    ['$god_weidi1'] = '是明是暗，你自己选好了。',
    ['$god_weidi2'] = '违朕旨意，死路一条！',
    ['~god_yuanshu'] = '蜜……蜜水呢……',

    ['zhangxiu'] = '张绣',
    ['#zhangxiu'] = '北地枪王',
    ['illustrator:zhangxiu'] = 'PCC',
    ['xiongluan'] = '雄乱',
    [':xiongluan'] = '限定技，出牌阶段，你可以废除装备区和判定区并选择一名其他角色，然后令其于此回合内不能使用或打出手牌且你于此回合内对其使用牌无次数和距离限制。',
    ['$xiongluan1'] = '雄踞宛城，虽乱世可安。',
    ['$xiongluan2'] = '北地枭雄，乱世不败！',
    ['congjian'] = '从谏',
    ['@congjian'] = '你可以发动“从谏”',
    ['~congjian'] = '选择一名其他角色→点击确定',
    [':congjian'] = '当你成为锦囊牌的目标时，你可以将一张牌交给其中一个目标，然后摸X张牌。（若你以此法交给其他角色的牌为装备牌，X为2，否则X为1）',
    ['$congjian1'] = '听君谏言，去危亡，保宗祀！',
    ['$congjian2'] = '从谏良计，可得自保。',
    ['~zhangxiu'] = '若失文和，吾将何归？',

    ['shenzhangliao'] = '神张辽',
    ['#shenzhangliao'] = '雁门之刑天',
    ['illustrator:shenzhangliao'] = 'town',
    ['duorui'] = '夺锐',
    ['duorui1'] = '出牌阶段限一次',
    ['duorui2'] = '每阶段限一次，当你于出牌阶段内',
    [':duorui'] = '每轮限一次，当你于出牌阶段内对其他角色造成伤害后，你可以废除一个坐骑栏以外的装备栏或两个坐骑栏，\
    然后于此回合内拥有其拥有的“出牌阶段限一次”的技能且拥有其拥有的“每阶段限一次，当你于出牌阶段内”的技能，若如此做，其于其的下回合内这些技能无效。',
    ['$duorui1'] = '夺敌军锐气，杀敌方士气。',
    ['$duorui2'] = '尖锐之势，吾亦可一人夺之。',
    ['zhiti'] = '止啼',
    [':zhiti'] = '锁定技，当你与攻击范围内已受伤的角色拼点赢时或当你因执行【决斗】而对已受伤的你或攻击范围内已受伤的角色造成伤害后，你选择一项：\
    1.恢复一个坐骑栏以外的装备栏；2.恢复两个坐骑栏；锁定技，你攻击范围内已受伤的角色的手牌上限-1；锁定技，若你已受伤，你的手牌上限-1。',
    ['$zhiti1'] = '江东小儿安敢啼哭？',
    ['$zhiti2'] = '娃闻名止啼，孙损十万休！',
    ['~shenzhangliao'] = '我也有被孙仲谋所伤之时？',

    ['shenganning'] = '神甘宁',
    ['#shenganning'] = '江表之力牧',
    ['illustrator:shenganning'] = 'depp',
    ['poxi'] = '魄袭',
    ['@poxi'] = '你可以发动“魄袭”',
    ['@poxi_less'] = '你可以发动“魄袭”',
    ['~poxi'] = '选择四张花色不同的手牌→点击确定',
    ['~poxi_less'] = '点击技能→点击确定',
    [':poxi'] = '出牌阶段限一次，你可以观看一名其他角色的手牌且你可以弃置你的手牌和其中的牌中四张不同花色的牌，若你以此法弃置了牌且你以此法弃置你的牌数为：0，你减1点体力上限；1，结束此阶段且你于此回合内的手牌上限-1；3，你回复1点体力；4.你摸四张牌。',
    ['$poxi1'] = '夜袭敌军，挫其锐气。',
    ['$poxi2'] = '受主知遇，袭敌不惧。',
    ['jieyingy'] = '劫营',
    ['@thiefed'] = '营',
    ['jieyingy-invoke'] = '你可以发动“劫营”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    [':jieyingy'] = '回合开始时，若没有角色拥有“营”标记，你获得1枚“营”标记；结束阶段开始时，你可以弃1枚“营”标记并选择一名其他角色，然后其获得1枚“营”标记；\
    拥有“营”的角色的额定摸牌数+1且手牌上限+1且使用【杀】的次数上限+1；拥有“营”的其他角色的回合结束时，其弃1枚“营”标记，然后你获得其所有手牌。',
    ['$jieyingy1'] = '裹甲衔枚，劫营如如无人之境！',
    ['$jieyingy2'] = '劫营速战，措手不及！',
    ['~shenganning'] = '吾不能奉主，谁辅主基业？',

    ['yanjun'] = '严畯',
    ['#yanjun'] = '志存补益',
    ['illustrator:yanjun'] = '',
    ['guanchao'] = '观潮',
    [':guanchao'] = '出牌阶段开始时，你可以选择一项：1.当你于此回合的出牌阶段内使用牌时，若你于此回合的出牌阶段内使用过的牌的点数严格递增，你摸一张牌；2.当你于此回合的出牌阶段内使用牌时，若你于此回合的出牌阶段内使用过的牌的点数严格递减，你摸一张牌。',
    ['guanchao1'] = '当你于此回合内使用牌时，若你于出牌阶段内使用过的牌的点数严格递增，你摸一张牌',
    ['guanchao2'] = '当你于此回合内使用牌时，若你于出牌阶段内使用过的牌的点数严格递减，你摸一张牌',
    ['#guanchao1'] = '%from 选择了 <font color="yellow"><b>递增</b></font>',
    ['#guanchao2'] = '%from 选择了 <font color="yellow"><b>递减</b></font>',
    ['#guanchao_success_1'] = '%from 使用的牌点数变化： %arg ，符合递增，“%arg2”被触发',
    ['#guanchao_fail_1'] = '%from 使用的牌点数变化： %arg ，不符合递增，“%arg2”结算中止',
    ['#guanchao_success_2'] = '%from 使用的牌点数变化： %arg ，符合递减，“%arg2”被触发',
    ['#guanchao_fail_2'] = '%from 使用的牌点数变化： %arg ，不符合递减，“%arg2”结算中止',
    ['$guanchao1'] = '朝夕之间，可知所进退。',
    ['$guanchao2'] = '月盈，潮起沉暮也；月亏，潮起日半也。',
    ['xunxian'] = '逊贤',
    ['xunxian-invoke'] = '你可以发动“逊贤”<br/> <b>操作提示</b>: 选择一名手牌比你多的角色→点击确定<br/>',
    [':xunxian'] = '每名角色的回合限一次，当你于回合外使用或打出的牌置入弃牌堆时，你可以将之交给一名手牌比你多的角色。',
    ['$xunxian1'] = '督军之才，子明强于我甚多。',
    ['$xunxian2'] = '此间重任，公卿可担之。',
    ['~yanjun'] = '著作……还……没完成……',

    ['duji'] = '杜畿',
    ['#duji'] = '惠以康民',
    ['illustrator:duji'] = '凝聚永恒',
    ['andong'] = '安东',
    [':andong'] = '当你受到其他角色造成的伤害时，你可以令其选择一项：1.防止此伤害且其于此回合的弃牌阶段内红桃牌不计入手牌上限且不能弃置；2.观看其手牌，你获得其中的红桃牌。',
    ['andong1'] = '防止此伤害且你于此回合的弃牌阶段内红桃牌不计入手牌上限且不能弃置',
    ['andong2'] = '其观看你的手牌，获得其中的红桃牌',
    ['$andong_prevent'] = '由于“%arg”，%from 对 %to 使用 %card 造成的伤害被防止',
    ['$andong1'] = '勇足以当大难，智涌以安万变。',
    ['$andong2'] = '宽猛克济，方安河东之民。',
    ['yingshi'] = '应势',
    ['reward'] = '酬',
    [':yingshi'] = '出牌阶段开始时，若没有角色拥有“酬”，你可以将所有红桃牌罝于一名其他角色的武将牌上，称为“酬”；当一名角色使用【杀】对拥有“酬”的角色造成伤害后，其可以获得拥有“酬”的角色的一张“酬”；当拥有“酬”的角色死亡时，你获得其所有“酬”。',
    ['yingshi-invoke'] = '你可以发动“应势”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['$yingshi1'] = '应民之声，势民之根。',
    ['$yingshi2'] = '应势而谋，顺民而为。',
    ['~duji'] = '试船而溺之，虽亡而忠至。',

    ['liuyan'] = '刘焉',
    ['#liuyan'] = '裂土之宗',
    ['tushe'] = '图射',
    [':tushe'] = '当你使用不为装备牌的牌指定目标后，若你没有基本牌，你可以摸X张牌。（X为目标数）',
    ['$tushe1'] = '非英杰不图？吾既谋之且射毕。',
    ['$tushe2'] = '汉室衰微，朝纲祸乱，必图后福。',
    ['limu'] = '立牧',
    [':limu'] = '你可以将一张方块牌当【乐不思蜀】对你使用，然后回复1点体力；若你的判定区里有牌，你对攻击范围内的角色使用牌无次数和距离限制。',
    ['$limu1'] = '米贼作乱，吾必为益州自保。',
    ['$limu2'] = '废史立牧，可得一方安定。',
    ['~liuyan'] = '背疮难治，失子难继！',

    ['panjun'] = '潘濬',
    ['#panjun'] = '方严嫉恶',
    ['illustrator:panjun'] = '秋呆呆',
    ['guanwei'] = '观微',
    ['@guanwei'] = '你可以弃置一张牌发动“观微”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>',
    [':guanwei'] = '一名角色的出牌阶段结束时，若其于此阶段内使用过的牌数大于1且其于此回合内使用过的牌的花色均相同且你于此回合内未发动过此技能，你可以弃置一张牌，其摸两张牌，然后其执行一个额外的出牌阶段。',
    ['$guanwei1'] = '今日宴请诸位，有要事相商。',
    ['$guanwei2'] = '天下未定，请主公以大局为重。',
    ['gongqing'] = '公清',
    [':gongqing'] = '锁定技，当你受到伤害时，若来源的攻击范围：小于3，伤害值为1；大于3，伤害值+1。',
    ['$gongqing1'] = '尔辈何故与降掳交善！',
    ['$gongqing2'] = '豪将在外，增兵必成祸患啊！',
    ['~panjun'] = '耻失荆州……耻失荆州啊！',

    ['wangcan'] = '王粲',
    ['#wangcan'] = '七子之冠',
    ['illustrator:wangcan'] = '凝聚永恒',
    ['sanwen'] = '散文',
    ['@sanwen'] = '你可以发动“散文”',
    ['~sanwen'] = '选择若干张牌→点击确定',
    [':sanwen'] = '每名角色的回合限一次，当你获得牌后，你可以弃置这些牌并展示这些牌以外与这些牌之中的牌的牌名相同的手牌，然后摸2X张牌。（X为你以此法弃置的牌数）',
    ['$sanwen1'] = '文若春华，思若泉涌。',
    ['$sanwen2'] = '独步汉南，散文天下。',
    ['qiai'] = '七哀',
    [':qiai'] = '限定技，当你进入濒死状态时，你可以令所有其他角色各交给你一张牌。',
    ['@qiai'] = '请交给 %src 一张牌',
    ['$qiai1'] = '未知身死处，何能两相完？',
    ['$qiai2'] = '悟彼下泉人，喟然伤心肝。',
    ['denglou'] = '登楼',
    ['@denglou'] = '你可以使用“登楼”中的基本牌',
    ['~denglou'] = '选择一张可以使用的基本牌->点击确定',
    [':denglou'] = '限定技，结束阶段开始时，若你没有手牌，你可以观看牌堆顶四张牌，然后获得其中的非基本牌，使用其中的基本牌，弃置其余的牌。',
    ['$denglou1'] = '登兹楼以四望兮，聊暇日以销忧。',
    ['$denglou2'] = '惟日月之逾迈兮，俟河清其未极。',
    ['~wangcan'] = '一坐驴鸣悲，万古送葬别~',

    ['sp_pangtong'] = '庞统',
    ['#sp_pangtong'] = '南州士冠',
    ['guolun'] = '过论',
    [':guolun'] = '出牌阶段限一次，你可以展示一名其他角色一张手牌，然后你可以选择一张牌，若你选择的手牌：小于你以此法展示的牌，你与其交换这些牌，其摸一张牌；大于你以此法展示的牌，你与其交换这些牌，你摸一张牌。',
    ['@guolun_choose'] = '你可以选择一张牌',
    ['$guolun1'] = '品过是非，讨评好坏。',
    ['$guolun2'] = '若有天下太平时，必讨四海之内才。',
    ['songsang'] = '送丧',
    [':songsang'] = '限定技，当其他角色死亡时，若你：已受伤，你可以回复1点体力；未受伤，你可以加1点体力上限。若如此做，你获得“展骥”。',
    ['@songsang'] = '送丧',
    ['$songsang1'] = '送丧至东吴，使命已完。',
    ['$songsang2'] = '送丧虽至，吾与孝则得相交。',
    ['zhanji'] = '展骥',
    [':zhanji'] = '锁定技，当你于出牌阶段内不以此法且因摸牌而获得牌时，你摸一张牌。',
    ['$zhanji1'] = '公瑾安全至吴，心安之。',
    ['$zhanji2'] = '功曹之恩，吾必有展骥之机。',
    ['~sp_pangtong'] = '诶，我终究不得东吴赏识~',

    ['sp_taishici'] = '太史慈',
    ['#sp_taishici'] = '北海酬恩',
    ['illustrator:sp_taishici'] = '凝聚永恒',
    ['jixu'] = '击虚',
    [':jixu'] = '出牌阶段限一次，你可以选择至少一名体力值相同的其他角色，这些角色各猜你的手牌中是否有【杀】。若其中有角色猜错且你的手牌中：有【杀】，你于此阶段内使用【杀】所有猜错的角色各成为此【杀】的目标；\
    没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸X张牌。若其中没有角色猜错，你结束此阶段。（X为猜错的角色数）',
    ['jixu_yes'] = '有杀',
    ['jixu_no'] = '没杀',
    ['@jixuWrong_replay'] = '猜错',
    ['$jixu1'] = '击虚箭射，懈敌戒备。',
    ['$jixu2'] = '虚实难辨，方迷敌方之心。',
    ['~sp_taishici'] = '刘繇之见，短浅也。',

    ['zhoufang'] = '周鲂',
    ['#zhoufang'] = '下发载义',
    ['duanfa'] = '断发',
    [':duanfa'] = '出牌阶段，若X大于0，你可以弃置一至X张黑色牌，摸等量的牌。（X为你于此阶段内以此法弃置过的牌数与体力上限之差）',
    ['$duanfa1'] = '身体发肤，受之父母。',
    ['$duanfa2'] = '今断发以明志，尚不可证吾之心意。',
    ['ol_youdi'] = '诱敌',
    [':ol_youdi'] = '结束阶段开始时，你可以令一名其他角色弃置你一张手牌，若之：不为【杀】，你获得其一张牌；不为黑色，你摸一张牌。',
    ['ol_youdi-invoke'] = '你可以发动“诱敌”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>',
    ['$ol_youdi1'] = '东吴以容不下我，愿降以保周全。',
    ['$ol_youdi2'] = '间书七条，足以表我归降之心。',
    ['~zhoufang'] = '功亏一篑，功亏一篑啊~',

    ['lvdai'] = '吕岱',
    ['#lvdai'] = '材匪戡难',
    ['illustrator:lvdai'] = 'biou09',
    ['qinguo'] = '勤国',
    ['@qinguo'] = '你可以发动“勤国”',
    ['~qinguo'] = '选择若干名角色→点击确定',
    [':qinguo'] = '当你于回合内使用装备牌结算完毕后，你可以视为使用【杀】；当你失去装备区里的牌或一张牌置入你的装备区里后，若你的装备区里的牌数与体力值相等且装备区里的牌数以此法变化，你可以回复1点体力。',
    ['$qinguo1'] = '卫国勤事，提速津勤。',
    ['$qinguo2'] = '忠勤为国，通达治体。',
    ['~lvdai'] = '再也不能为吴国奉身了......',

    ['liuyao'] = '刘繇',
    ['illustrator:liuyao'] = '凝聚永恒',
    ['#liuyao'] = '材匪戡难',
    ['kannan'] = '戡难',
    [':kannan'] = '<font color="green"><b>出牌阶段限X次，</b></font>你可以与你于此阶段内未以此法拼点过的一名角色拼点：\
    赢的角色使用下一张【杀】的伤害值基数+1，然后若其为你，你于于此阶段内不能发动此技能。（X为你的体力值）',
    ['$kannan'] = '%from 执行“%arg”的效果，%card 的伤害值+ %arg2 ',
    ['$kannan1'] = '俊才之杰，才斐戡难。',
    ['$kannan2'] = '俊才之杰，才斐戡难。',
    ['~liuyao'] = '',

    ['lvqian'] = '吕虔',
    ['illustrator:lvqian'] = '凝聚永恒',
    ['#lvqian'] = '恩威并诸',
    ['weilu'] = '威虏',
    [':weilu'] = '锁定技，当你受到其他角色造成的伤害后，你令你的下回合内的出牌阶段开始时，其失去X点体力，若如此做，此回合结束时，其回复等量的体力。（X为其的体力值-1）',
    ['$weilu1'] = '贼人势大，须从长计议。',
    ['$weilu2'] = '时机未到，先行撤退！',
    ['zengdao'] = '赠刀',
    ['sword'] = '刀',
    [':zengdao'] = '限定技，结束阶段开始时，你可以将至少一张装备区里的牌置于一名其他角色的武将牌上，称为“刀”，若如此做，当拥有“刀”的角色造成伤害时，其将一张“刀”置入弃牌堆，伤害值+1。',
    ['@zengdao'] = '你可以发动“赠刀”',
    ['~zengdao'] = '选择若干张装备区里的牌→点击确定',
    ['$zengdao1'] = '有功赏之，有过罚之。',
    ['$zengdao2'] = '治军之道，功过分明。',
    ['~lvqian'] = '吾自泰山郡以来，百姓祸安，镇军罚贼，此生已无憾~',

    ['zhangliang'] = '张梁',
    ['#zhangliang'] = '人公将军',
    ['sp_jijun'] = '集军',
    [':sp_jijun'] = '出牌阶段，你可以将至少一张牌置于武将牌上，称为“方”。',
    ['sp_fangtong'] = '方统',
    [':sp_fangtong'] = '结束阶段开始时，若“方”数为36，与你胜利条件相同的角色（包括已死亡的角色）胜利。',
    ['jijun'] = '集军',
    [':jijun'] = '当你于出牌阶段内使用武器牌或不为装备牌的牌指定目标后，若你为目标，你可以判定，当此判定牌置入弃牌堆后或因此判定的判定牌因其他牌打出代替判定而被置入弃牌堆后，你可以将这些牌置于武将牌上，称为“方”。',
    ['$jijun1'] = '集民力万千，亦可为军！',
    ['$jijun2'] = '集万千一军，定天下大局！',
    ['fang'] = '方',
    ['fangtong'] = '方统',
    [':fangtong'] = '结束阶段开始时，你可以弃置一张牌，将至少一张“方”置入弃牌堆，然后若这些牌的点数之和为36，你对一名其他角色造成3点雷电伤害。',
    ['@fangtong'] = '你可以发动“方统”',
    ['$fangtong1'] = '统领方队，为名义所举！',
    ['$fangtong2'] = '三十六方，必为大桶！',
    ['~fangtong'] = '选择一张手牌→选择至少一张“方”→可选步骤：若“方”的点数之和等于36则选择一名其他角色→点击确定',
    ['~zhangliang'] = '张梁，回不去了......',

    ['baosanniang'] = '鲍三娘',
    ['#baosanniang'] = '',
    ['wuniang'] = '武娘',
    [':wuniang'] = '当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，然后其摸一张牌，关索摸一张牌。',
    ['$wuniang1'] = '虽为女子身，不输男儿郎',
    ['$wuniang2'] = '剑舞轻盈，沙场克敌',
    ['xushen'] = '许身',
    [':xushen'] = '当你的濒死结算完毕后，于此濒死结算内使用【桃】令你回复体力的角色可以失去所有技能，将其的武将牌替换为关索，然后将其的体力上限调整至X，然后你回复1点体力，获得“镇南”。（若其为主公，X为5，否则为4）',
    ['@xushen'] = '你可以发动“许身”',
    ['$xushen1'] = '救命之恩，涌泉相报',
    ['$xushen2'] = '解我危难，报君华彩',
    ['~baosanniang'] = '我还想与你共骑这雪花骏',

    ['cuiyanmaojie'] = '崔琰&毛玠',
    ['#cuiyanmaojie'] = '日出月盛',
    ['zhengpi'] = '征辟',
    [':zhengpi'] = '出牌阶段开始时，你可以选择一项：1.令一名角色势力变成魏；2.你将一张基本牌交一名角色，然后其选择是否交给你一张不为基本牌的牌，若其选择否，其交给你两张基本牌。',
    ['@zhengpi'] = '你可以选择一张牌',
    ['$zhengpi1'] = '',
    ['$zhengpi2'] = '',
    ['fengying'] = '奉迎',
    [':fengying'] = '限定技，出牌阶段，你可以弃置所有手牌，然后令所有魏势力角色各将手牌补至体力上限，结束此出牌阶段，若如此做，此回合结束时，你可以弃置一张牌，然后执行一个额外的回合。',
    ['@fengying'] = '奉迎',
    ['$fengying1'] = '',
    ['$fengying2'] = '',
    ['~cuiyanmaojie'] = '',

    ['ol_zhugezhan'] = '诸葛瞻',
    ['#ol_zhugezhan'] = '卧龙之子',
    ['illustrator:ol_zhugezhan'] = 'OnLine',
    ['~ol_zhugezhan'] = '临难而死义，无愧先父。',
}
if sgs.GetConfig('huanghao_down', true) then
    sgs.LoadTranslationTable {
        [':qinqing'] = '结束阶段开始时，你可以选择至少一名攻击范围内有主公的角色，先弃置这些角色各一张牌再摸一张牌，若如此做，你摸X张牌（X为这些角色中手牌比主公多的角色数）。',
        [':huisheng'] = '当你受到其他角色造成的伤害时，你可以对其展示至少一张牌，其选择一项：1.获得其中一张牌，若如此做，防止此伤害，令其不是“贿生”的合法目标2.弃置等量的牌。',
    }
else
    sgs.LoadTranslationTable {
        [':qinqing'] = '结束阶段开始时，你可以弃置一名攻击范围内有主公的其他角色一张牌，若如此做，其摸一张牌，然后若其手牌大于主公，你摸一张牌。',
        [':huisheng'] = '当你受到其他角色造成的伤害时，你可以对其展示至少一张牌，其选择一项：1.获得其中一张牌，若如此做，防止此伤害2.弃置等量的牌。每名角色限一次。',
    }
end
--[[
		room:addPlayerMark(player, self:objectName()..'engine')
		if player:getMark(self:objectName()..'engine') > 0 then
			room:removePlayerMark(player, self:objectName()..'engine')
		end
]]
local jiaozhao_cards = {}
for i = 0, 10000 do
    local card = sgs.Sanguosha:getEngineCard(i)
    if card == nil then
        break
    end
    if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and (card:isKindOf('BasicCard') or card:isNDTrick()) and
        not table.contains(jiaozhao_cards, card:objectName()) and
        not table.contains(sgs.Sanguosha:getBanPackages(), card:getPackage()) then
        table.insert(jiaozhao_cards, card:objectName())
        local cards = sgs.Sanguosha:cloneCard(card:objectName(), 6, 14)
        cards:setParent(card_slash)
    end
end
return {extension, extension_z, extension_pm, extension6, extension7, extension_friend, extension_ol, extension_sp,
        extension_bf, card_slash, extension_yijiang, extension_god, extension_hulaoguan, extension_mobile, extension_star,
        extension_yin, extension_lei}

-- luacheck: pop
