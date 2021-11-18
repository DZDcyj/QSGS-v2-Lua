-- 斗地主包
-- Created by DZDcyj at 2021/10/9

module('extensions.LandlordsPackage', package.seeall)
extension = sgs.Package('LandlordsPackage')

SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

-- 引入封装函数包
local rinsanFuncModule = require('QSanguoshaLuaFunction')

LuaBahu =
    sgs.CreateTriggerSkill {
    name = 'LuaBahu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:drawCards(1)
        end
    end
}

LuaBahuSlash =
    sgs.CreateTargetModSkill {
    name = 'LuaBahuSlash',
    frequency = sgs.Skill_Compulsory,
    residue_func = function(self, player)
        if player:hasSkill('LuaBahu') then
            return 1
        else
            return 0
        end
    end
}

LuaFeiyangCard =
    sgs.CreateSkillCard {
    name = 'LuaFeiyangCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        if source:getJudgingArea():length() > 0 then
            room:throwCard(
                room:askForCardChosen(source, source, 'j', 'LuaFeiyang', true, sgs.Card_MethodDiscard),
                source
            )
        end
    end
}

LuaFeiyangVS =
    sgs.CreateViewAsSkill {
    name = 'LuaFeiyang',
    n = 2,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local vs_card = LuaFeiyangCard:clone()
            for _, cd in ipairs(cards) do
                vs_card:addSubcard(cd)
            end
            return vs_card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@@LuaFeiyang'
    end
}

LuaFeiyang =
    sgs.CreateTriggerSkill {
    name = 'LuaFeiyang',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = LuaFeiyangVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getJudgingArea():length() > 0 and player:canDiscard(player, 'h') and player:getHandcardNum() >= 2 then
                room:askForUseCard(player, '@@LuaFeiyang', '@LuaFeiyang')
            end
        end
    end
}

LuaDizhu =
    sgs.CreateTriggerSkill {
    name = 'LuaDizhu',
    events = {sgs.BuryVictim, sgs.TurnStart},
    frequency = sgs.Skill_Compulsory,
    -- priority 调整为最优先
    priority = 10,
    on_trigger = function(self, event, player, data, room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:addPlayerMark(player, self:objectName())

        -- 设置初始血量，主要针对不满血的武将
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local start_hp = rinsanFuncModule.getStartHp(p)
            room:setPlayerProperty(p, 'hp', sgs.QVariant(start_hp))
        end

        -- 为自己增加一点体力上限
        room:setPlayerProperty(player, 'maxhp', sgs.QVariant(player:getMaxHp() + 1))
        local msg = sgs.LogMessage()
        msg.type = '#addmaxhp'
        msg.arg = 1
        msg.from = player
        room:sendLog(msg)
        local theRecover = sgs.RecoverStruct()
        theRecover.recover = 1
        theRecover.who = player
        room:recover(player, theRecover)
        room:addPlayerMark(player, self:objectName())

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

-- 斗地主场景技能
-- 主要负责模块为：死亡奖惩与农民摸牌
LuaDoudizhuScenario =
    sgs.CreateTriggerSkill {
    name = 'LuaDoudizhuScenario',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.BuryVictim, sgs.Death},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BuryVictim then
            room:setTag('SkipNormalDeathProcess', sgs.QVariant(true))
            player:bury()
        elseif event == sgs.Death then
            -- 避免触发“自书”
            room:setTag('FirstRound', sgs.QVariant(true))
            for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                if target:getRole() == player:getRole() then
                    local choices = {}
                    if target:isWounded() then
                        table.insert(choices, 'recover')
                    end
                    table.insert(choices, 'draw')
                    table.insert(choices, 'cancel')
                    local choice = room:askForChoice(target, 'LuaNongmin', table.concat(choices, '+'))
                    if choice == 'recover' then
                        room:recover(target, sgs.RecoverStruct(player, nil, 1))
                    elseif choice == 'draw' then
                        target:drawCards(2)
                    end
                end
            end
            room:setTag('FirstRound', sgs.QVariant(false))
        end
        return false
    end,
    can_trigger = function(self, target)
        if target and target:hasSkill('LuaDizhu') then
            return true
        end
        for _, p in sgs.qlist(target:getSiblings()) do
            if p:hasSkill('LuaDizhu') then
                return true
            end
        end
        return false
    end
}

SkillAnjiang:addSkill(LuaBahu)
SkillAnjiang:addSkill(LuaBahuSlash)
SkillAnjiang:addSkill(LuaFeiyang)
SkillAnjiang:addSkill(LuaDizhu)
SkillAnjiang:addSkill(LuaDoudizhuScenario)
