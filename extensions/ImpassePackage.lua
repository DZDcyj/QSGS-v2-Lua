-- 绝境之战包
-- Created by DZDcyj at 2021/11/30

module('extensions.ImpassePackage', package.seeall)
extension = sgs.Package('ImpassePackage')

SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

-- 引入封装函数包
local rinsanFuncModule = require('QSanguoshaLuaFunction')

-- 暴走标记
BaozouMark = '@baozou'

-- BOSS 技能

-- 思略
-- 锁定技：摸牌阶段，你始终摸X张牌，X为你当前的体力值；进入暴走状态后，摸牌阶段放弃摸牌，改为依次从其他存活角色处获得一张牌
LuaSilve =
    sgs.CreateTriggerSkill {
    name = 'LuaSilve',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        if player:getMark(BaozouMark) == 0 then
            data:setValue(player:getHp())
        else
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isNude() then
                    local id = room:askForCardChosen(player, p, 'he', self:objectName())
                    player:obtainCard(sgs.Sanguosha:getCard(id), false)
                end
            end
            data:setValue(0)
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaSilve)

-- 克敌
-- 你受到伤害后可以摸X张牌，X为你当前体力值；进入暴走状态后，X为场上存活的角色数
LuaKedi =
    sgs.CreateTriggerSkill {
    name = 'LuaKedi',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local x = player:getHp()
        if player:getMark(BaozouMark) > 0 then
            x = room:alivePlayerCount()
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            player:drawCards(x, self:objectName())
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaKedi)

-- 济世
-- 锁定技，回合开始阶段，若你的手牌不大于X，你可以从除你以外每名角色那获得一张手牌，若目标角色无手牌，则失去一点体力。X为你当前体力值；
-- 进入暴走状态后，若目标角色无手牌，则失去两点体力。X为存活的角色数与你当前体力上限之和。你的手牌上限为存活的角色数
LuaJishi =
    sgs.CreateTriggerSkill {
    name = 'LuaJishi',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local x = player:getHp()
            local loseHpNum = 1
            if player:getMark(BaozouMark) > 0 then
                x = player:getMaxHp() + room:alivePlayerCount()
                loseHpNum = 2
            end
            if player:getHandcardNum() > x then
                return false
            end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isKongcheng() then
                    room:loseHp(p, loseHpNum)
                else
                    local id = room:askForCardChosen(player, p, 'h', self:objectName())
                    player:obtainCard(sgs.Sanguosha:getCard(id), false)
                end
            end
        end
    end
}

LuaJishiMaxCards =
    sgs.CreateMaxCardsSkill {
    name = '#LuaJishiMaxCards',
    fixed_func = function(self, target)
        if target:hasSkill('LuaJishi') and target:getMark(BaozouMark) > 0 then
            return target:getAliveSiblings():length() + 1
        end
        return -1
    end
}

SkillAnjiang:addSkill(LuaJishi)
SkillAnjiang:addSkill(LuaJishiMaxCards)

-- 大吉
-- 锁定技，回合结束阶段，你摸X张牌（若你已进入暴走状态，则X为存活角色数，否则X为你的体力值）
-- 进入暴走状态后，你的回合外，若你已受伤，则你为锦囊牌的唯一目标时，该锦囊对你无效
-- 锁定技，当你受到大于1的伤害时，此伤害-1
LuaDaji =
    sgs.CreateTriggerSkill {
    name = 'LuaDaji',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.DamageInflicted, sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local x = player:getHp()
                if player:getMark(BaozouMark) > 0 then
                    x = room:alivePlayerCount()
                end
                player:drawCards(x, self:objectName())
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.damage > 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                damage.damage = damage.damage - 1
                data:setValue(damage)
            end
        elseif event == sgs.TargetConfirmed then
            if player:getMark(BaozouMark) == 0 or (not player:isWounded()) then
                return false
            end
            local use = data:toCardUse()
            if use.card and use.card:isKindOf('TrickCard') then
                if use.to:length() == 1 and use.to:contains(player) then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, player:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaDaji)

-- 孤战
-- 锁定技，当你没装备武器时，使用【杀】无次数限制
LuaGuzhan =
    sgs.CreateTargetModSkill {
    name = 'LuaGuzhan',
    residue_func = function(self, player)
        if player:hasSkill(self:objectName()) and not player:getWeapon() then
            return 1000
        else
            return 0
        end
    end
}

SkillAnjiang:addSkill(LuaGuzhan)

-- 激战
-- 锁定技，出牌阶段，你每对其他角色造成一点伤害回复一点体力；当手牌小于存活的角色数时，你摸一张牌
LuaJizhan =
    sgs.CreateTriggerSkill {
    name = 'LuaJizhan',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            if player:getPhase() == sgs.Player_Play then
                local damage = data:toDamage()
                if damage.to:objectName() ~= player:objectName() and player:isWounded() then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:recover(player, sgs.RecoverStruct(nil, nil, damage.damage))
                end
            end
        else
            local move = data:toMoveOneTime()
            local source = move.from
            local target = move.to
            if not source or source:objectName() ~= player:objectName() then
                if not target or target:objectName() ~= player:objectName() then
                    return false
                end
            end
            if move.to_place ~= sgs.Player_PlaceHand then
                if not move.from_places:contains(sgs.Player_PlaceHand) then
                    return false
                end
            end
            if player:getHandcardNum() < room:alivePlayerCount() then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(1, self:objectName())
            end
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaJizhan)

-- 独断
-- 锁定技，你不能成为延时类锦囊的目标
LuaDuduan =
    sgs.CreateProhibitSkill {
    name = 'LuaDuduan',
    is_prohibited = function(self, from, to, card)
        if to:hasSkill(self:objectName()) then
            return card:isKindOf('DelayedTrick')
        end
    end
}

SkillAnjiang:addSkill(LuaDuduan)

LuaBannedGenerals = {
    'yuanshao',
    'yanliangwenchou',
    'zhaoyun',
    'guanyu',
    'shencaocao'
}

LuaBannedBossSkills = {
    'luanji',
    'shuangxiong',
    'longdan',
    'wusheng',
    'guixin'
}

LuaBannedSkills = {
    'shenli',
    'midao',
    'kuangfeng',
    'dawu',
    'kuangbao',
    'wuqian',
    'shenfen',
    'wumou',
    'wuhun',
    'tongxin',
    'xinsheng',
    'zaoxian',
    'renjie',
    'baiyin'
}

-- 初始化技能
-- 调整全场血量，赋予随机技能
LuaBoss =
    sgs.CreateTriggerSkill {
    name = 'LuaBoss',
    events = {sgs.TurnStart},
    frequency = sgs.Skill_Compulsory,
    -- priority 调整为最优先
    priority = 10,
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:addPlayerMark(player, self:objectName())

        -- 避免触发暴走
        room:setTag('BaozouNotInvoke', sgs.QVariant(true))

        -- 调整 BOSS 武将
        if table.contains(LuaBannedGenerals, player:getGeneralName()) then
            local to_change = rinsanFuncModule.getRandomGeneral(LuaBannedGenerals)
            room:changeHero(player, to_change, true, false, false, true)
        end

        -- 设置初始血量，主要针对不满血的武将
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local start_hp = rinsanFuncModule.getStartHp(p)
            room:setPlayerProperty(p, 'hp', sgs.QVariant(start_hp))
        end

        -- 调整 BOSS 体力上限
        local to_maxhp = 8
        if player:getGeneral():getMaxHp() < 4 then
            to_maxhp = 7
        end
        room:setPlayerProperty(player, 'maxhp', sgs.QVariant(to_maxhp))
        room:setPlayerProperty(player, 'hp', sgs.QVariant(to_maxhp))
        room:setTag('BaozouNotInvoke', sgs.QVariant(false))

        -- 获取随机技能
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:acquireSkill(
                p,
                rinsanFuncModule.getRandomGeneralSkill(room, LuaBannedSkills, LuaBannedBossSkills, p:isLord())
            )
        end

        -- BOSS 获取技能
        local skill_pair = rinsanFuncModule.random(0, 1)
        if skill_pair == 1 then
            room:acquireSkill(player, 'LuaSilve')
            room:acquireSkill(player, 'LuaKedi')
        else
            room:acquireSkill(player, 'LuaJishi')
            room:acquireSkill(player, 'LuaDaji')
        end

        -- 初始技能触发
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            -- 触发游戏开始时时机，例如先辅、怀橘
            room:getThread():trigger(sgs.GameStart, room, p)

            -- 涉及到摸初始牌的，补一下，例如挫锐、七星
            local draw_data = sgs.QVariant(0)
            room:getThread():trigger(sgs.DrawInitialCards, room, p, draw_data)
            local to_draw = draw_data:toInt()
            if to_draw > 0 then
                p:drawCards(to_draw, self:objectName())
            end
        end

        -- 手气卡
        -- 避免“自书”触发
        room:setTag('FirstRound', sgs.QVariant(true))
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            -- 在手气卡使用前先令所有技能失效，避免不必要的其他结算
            local skills = p:getSkillList()
            for _, skill in sgs.qlist(skills) do
                room:addPlayerMark(p, 'Qingcheng' .. skill:objectName())
            end
            rinsanFuncModule.askForLuckCard(room, p)
            -- 恢复所有技能
            for _, skill in sgs.qlist(skills) do
                room:removePlayerMark(p, 'Qingcheng' .. skill:objectName())
            end
        end
        room:setTag('FirstRound', sgs.QVariant(false))

        -- 初始技能触发
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            -- 摸牌后操作，例如七星
            room:getThread():trigger(sgs.AfterDrawInitialCards, room, p)
        end

        -- 移除主公技
        for _, skill in sgs.qlist(player:getSkillList()) do
            if skill:isLordSkill() then
                room:detachSkillFromPlayer(player, skill:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsanFuncModule.RIGHT(self, target) and target:getMark(self:objectName()) == 0
    end
}

SkillAnjiang:addSkill(LuaBoss)

-- 暴走状态技能
-- 进入暴走状态、判定相关
LuaBaozou =
    sgs.CreateTriggerSkill {
    name = 'LuaBaozou',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.HpChanged, sgs.MaxHpChanged, sgs.TurnStart, sgs.EventPhaseChanging, sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        if room:getTag('BaozouNotInvoke'):toBool() then
            return false
        end
        if event == sgs.TurnStart then
            if player:getMark(self:objectName()) == 0 then
                return false
            end
            if player:getMark(BaozouMark) > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:loseMark(BaozouMark)
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag('LuaBaozouKill') then
                        room:sendCompulsoryTriggerLog(p, self:objectName())
                        room:killPlayer(p)
                    end
                end
            end
        elseif event == sgs.MarkChanged then
            if data:toMark().name == BaozouMark then
                if player:getMark(self:objectName()) > 0 then
                    if player:getMark(BaozouMark) == 0 then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            local judge =
                                rinsanFuncModule.createJudgeStruct(
                                {
                                    ['who'] = p,
                                    ['pattern'] = 'Peach,Analeptic|.|.|.',
                                    ['reason'] = self:objectName(),
                                    ['play_animation'] = true
                                }
                            )
                            room:judge(judge)
                            if not judge:isGood() then
                                local x = p:getHp()
                                room:loseHp(p, x)
                                if x > 1 then
                                    room:recover(p, sgs.RecoverStruct(nil, nil, x - 1))
                                end
                            end
                        end
                        room:setPlayerFlag(player, 'LuaBaozouKill')
                    end
                end
            end
        else
            if player:getMark(self:objectName()) > 0 then
                return false
            end
            if player:hasSkill(self:objectName()) or player:getMark('LuaBoss') > 0 then
                if player:getHp() <= 3 then
                    room:addPlayerMark(player, self:objectName())
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    if player:getJudgingArea():length() > 0 then
                        local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
                        for _, cd in sgs.qlist(player:getJudgingArea()) do
                            slash:addSubcard(cd)
                        end
                        room:throwCard(slash, player)
                    end
                    -- 获得特殊技能
                    room:acquireSkill(player, 'LuaGuzhan')
                    room:acquireSkill(player, 'LuaJizhan')
                    room:acquireSkill(player, 'LuaDuduan')

                    -- 修正技能效果
                    rinsanFuncModule.modifieSkillDescription(':LuaSilve', ':LuaSilveBaozou')
                    rinsanFuncModule.modifieSkillDescription(':LuaKedi', ':LuaKediBaozou')
                    rinsanFuncModule.modifieSkillDescription(':LuaJishi', ':LuaJishiBaozou')
                    rinsanFuncModule.modifieSkillDescription(':LuaDaji', ':LuaDajiBaozou')
                    room:setPlayerProperty(player, 'maxhp', sgs.QVariant(3))
                    player:gainMark(BaozouMark, room:alivePlayerCount())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

SkillAnjiang:addSkill(LuaBaozou)

LuaImpasseDeath =
    sgs.CreateTriggerSkill {
    name = 'LuaImpasseDeath',
    events = {sgs.BuryVictim, sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BuryVictim then
            room:setTag('SkipNormalDeathProcess', sgs.QVariant(true))
            player:bury()
        else
            if player:getMark('LuaBoss') == 0 then
                return false
            end
            local death = data:toDeath()
            local killer
            if death.damage then
                killer = death.damage.from
            end
            if killer then
                if killer:isLord() then
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#LuaImpasseLordKill',
                        {['from'] = killer, ['to'] = death.who, ['arg'] = 2}
                    )
                    killer:drawCards(2, self:objectName())
                    if killer:getMaxHp() > 3 then
                        rinsanFuncModule.sendLogMessage(
                            room,
                            '#LuaImpasseLordLoseMaxHp',
                            {['from'] = killer, ['to'] = death.who, ['arg'] = 1}
                        )
                        room:loseMaxHp(killer)
                    end
                    -- 如果标记大于场上反贼数，失去一个
                    if killer:getMark(BaozouMark) > room:alivePlayerCount() - 1 then
                        rinsanFuncModule.sendLogMessage(
                            room,
                            '#LuaImpasseLordLoseMark',
                            {
                                ['from'] = killer,
                                ['arg'] = killer:getMark(BaozouMark),
                                ['arg2'] = room:alivePlayerCount() - 1
                            }
                        )
                        killer:loseMark(BaozouMark)
                    end
                else
                    rinsanFuncModule.sendLogMessage(
                        room,
                        '#LuaImpasseRebelKill',
                        {['from'] = killer, ['to'] = death.who}
                    )
                    killer:throwAllHandCards()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target and target:getMark('LuaBoss') > 0 then
            return true
        end
        for _, p in sgs.qlist(target:getSiblings()) do
            if p:getMark('LuaBoss') > 0 then
                return true
            end
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaImpasseDeath)

LuaImpasseArmor =
    sgs.CreateTriggerSkill {
    name = 'LuaImpasseArmor',
    events = {sgs.TargetConfirmed, sgs.CardFinished},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getMark('LuaBaozou') == 0 then
            return false
        end
        local use = data:toCardUse()
        if use.from:objectName() ~= player:objectName() then
            return false
        end
        if event == sgs.TargetConfirmed then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:addPlayerMark(p, 'Armor_Nullified')
            end
        else
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:removePlayerMark(p, 'Armor_Nullified')
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

SkillAnjiang:addSkill(LuaImpasseArmor)
