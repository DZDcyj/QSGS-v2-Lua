-- 斗地主包
-- Created by DZDcyj at 2021/10/9

module('extensions.LandlordsPackage', package.seeall)
extension = sgs.Package('LandlordsPackage')

SkillAnjiang = sgs.General(extension, 'SkillAnjiang', 'god', '6', true, true, true)

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
    events = {sgs.TurnStart, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = LuaFeiyangVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart and player:getMark(self:objectName()) == 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName())
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
        else
            if player:getPhase() == sgs.Player_Start then
                if
                    player:getJudgingArea():length() > 0 and player:canDiscard(player, 'h') and
                        player:getHandcardNum() >= 2
                 then
                    room:askForUseCard(player, '@@LuaFeiyang', '@LuaFeiyang')
                end
            end
        end
    end
}

LuaNongmin =
    sgs.CreateTriggerSkill {
    name = 'LuaNongmin',
    events = {sgs.Death, sgs.BuryVictim},
    global = true,
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BuryVictim then
            local death = data:toDeath()
            local reason = death.damage
            if reason then
                local killer = reason.from
                if killer then
                    if killer:isAlive() then
                        if killer:hasSkill(self:objectName()) then
                            room:sendCompulsoryTriggerLog(killer, self:objectName())
                            room:setTag('SkipNormalDeathProcess', sgs.QVariant(true))
                            player:bury()
                        end
                    end
                end
            end
        else
            local death = data:toDeath()
            if player:hasSkill(self:objectName()) then
                if player:objectName() == death.who:objectName() then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                        if target:getRole() == player:getRole() then
                            target:drawCards(2)
                            room:recover(target, sgs.RecoverStruct(player, nil, 1))
                        end
                    end
                end
            end
        end
        return false
    end
}

LuaDizhu =
    sgs.CreateTriggerSkill {
    name = 'LuaDizhu',
    events = {sgs.BuryVictim, sgs.TurnStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BuryVictim then
            local death = data:toDeath()
            local reason = death.damage
            if reason then
                local killer = reason.from
                if killer then
                    if killer:isAlive() then
                        if killer:hasSkill(self:objectName()) then
                            room:sendCompulsoryTriggerLog(killer, self:objectName())
                            room:setTag('SkipNormalDeathProcess', sgs.QVariant(true))
                            player:bury()
                        end
                    end
                end
            end
        elseif event == sgs.TurnStart then
            if player:getMark(self:objectName()) == 0 and player:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:addPlayerMark(player, self:objectName())
                for _, skill in sgs.qlist(player:getSkillList()) do
                    if skill:isLordSkill() then
                        room:detachSkillFromPlayer(player, skill:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

SkillAnjiang:addSkill(LuaBahu)
SkillAnjiang:addSkill(LuaBahuSlash)
SkillAnjiang:addSkill(LuaFeiyang)
SkillAnjiang:addSkill(LuaNongmin)
SkillAnjiang:addSkill(LuaDizhu)
