-- 通用技能包（）
-- Created by DZDcyj at 2025/9/20
module('extensions.CommonSkillPackage', package.seeall)
extension = sgs.Package('CommonSkillPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

non_use_time = sgs.CreateTriggerSkill {
    name = 'non_use_time',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded},
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
        if (not card) or (card:isKindOf('SkillCard')) then
            return false
        end
        -- 统一在此处清理标记
        -- 不计入次数
        room:removePlayerMark(player, 'no_use_count')
        -- 不限制距离
        room:removePlayerMark(player, 'no_distance_limit')
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
                use.m_addHistory = false
            end
            data:setValue(use)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getMark('no_use_count') > 0
    end,
}

local function get_skill_marks_and_skills(splayer)
    local unresponsible_marks = {}
    local unresponsible_skills = {}
    for _, mark in sgs.list(splayer:getMarkNames()) do
        if string.find(mark, '_unresponsible', 1, true) and splayer:getMark(mark) > 0 then
            table.insert(unresponsible_marks, mark)
            local skill_name = string.gsub(mark, '_unresponsible', '')
            table.insert(unresponsible_skills, skill_name)
        end
    end
    return unresponsible_marks, unresponsible_skills
end

local function get_skill_name(splayer)
    local _, unresponsible_skills = get_skill_marks_and_skills(splayer)
    if #unresponsible_skills == 0 then
        return nil, nil
    end
    local skillName = unresponsible_skills[1]
    local skillMark = string.format('%sTarget', skillName)
    return skillName, skillMark
end

unresponsible = sgs.CreateTriggerSkill {
    name = 'unresponsible',
    global = true,
    priority = 10000,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardAsked, sgs.TurnStart, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (not use.from) then
                return false
            end
            if (not use.card) or use.card:isKindOf('SkillCard') then
                return false
            end
            local skillName, skillMark = get_skill_name(use.from)
            if not skillName then
                return false
            end
            room:setTag('current_unresponsible_skill', sgs.QVariant(skillName))
            room:setTag('current_unresponsible_skill_mark', sgs.QVariant(skillMark))
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:addPlayerMark(p, skillMark)
            end
            room:broadcastSkillInvoke(skillName)
            room:sendCompulsoryTriggerLog(use.from, skillName)
            if (use.card:isKindOf('Slash') or use.card:isNDTrick()) then
                room:addPlayerMark(use.from, self:objectName() .. 'engine')
                if use.from:getMark(self:objectName() .. 'engine') > 0 then
                    room:removePlayerMark(use.from, self:objectName() .. 'engine')
                end
            end
        elseif event == sgs.CardAsked then
            local skillMark = room:getTag('current_unresponsible_skill_mark'):toString()
            if not skillMark then
                return false
            end
            if player:getMark(skillMark) > 0 then
                room:provide(nil)
                room:setPlayerMark(player, skillMark, 0)
                return true
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf('Slash') then
                local skillName = room:getTag('current_unresponsible_skill'):toString()
                if not skillName then
                    return false
                end
                if rinsan.RIGHT(self, player, skillName) then
                    local jink_table = sgs.QList2Table(use.from:getTag('Jink_' .. use.card:toString()):toIntList())
                    local index = 1
                    for _, p in sgs.qlist(use.to) do
                        if p:isAlive() then
                            rinsan.sendLogMessage(room, '#NoJink', {
                                ['from'] = p,
                            })
                        end
                        jink_table[index] = 0
                        index = index + 1
                    end
                    local jink_data = sgs.QVariant()
                    jink_data:setValue(Table2IntList(jink_table))
                    use.from:setTag('Jink_' .. use.card:toString(), jink_data)
                end
            end
        elseif event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            local skillName = room:getTag('current_unresponsible_skill'):toString()
            if not skillName then
                return false
            end
            if effect.from and rinsan.RIGHT(self, effect.from, skillName) then
                return true
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if (not use.card) or use.card:isKindOf('SkillCard') then
                return false
            end
            local unresponsible_marks, _ = get_skill_marks_and_skills(use.from)
            for _, mark in ipairs(unresponsible_marks) do
                room:removePlayerMark(player, mark)
            end
            local skillName = room:getTag('current_unresponsible_skill'):toString()
            local skillMark = room:getTag('current_unresponsible_skill_mark'):toString()
            if not skillName then
                return false
            end
            room:addPlayerMark(player, skillName .. 'Used')
            if use.from and use.from:hasSkill(skillName) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, skillMark, 0)
                end
            end
            room:removeTag('current_unresponsible_skill')
            room:removeTag('current_unresponsible_skill_mark')
        else
            local skillName = room:getTag('current_unresponsible_skill'):toString()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if skillName then
                    room:setPlayerMark(p, skillName .. 'Used', 0)
                end
            end
        end
        return false
    end,
    can_trigger = rinsan.targetTrigger,
}

no_distance_limit = sgs.CreateTargetModSkill {
    name = 'no_distance_limit',
    distance_limit_func = function(self, from, card)
        if from:getMark('no_distance_limit') > 0 then
            return 1000
        end
        return 0
    end,
}

more_slash_tiime = sgs.CreateTargetModSkill {
    name = 'more_slash_time',
    pattern = 'Slash',
    residue_func = function(self, from, card)
        if from:getMark('more_slash_time') > 0 then
            return from:getMark('more_slash_time')
        end
        return 0
    end,
}

table.insert(hiddenSkills, non_use_time)
table.insert(hiddenSkills, unresponsible)
table.insert(hiddenSkills, no_distance_limit)
table.insert(hiddenSkills, more_slash_tiime)

rinsan.addHiddenSkills(hiddenSkills)
