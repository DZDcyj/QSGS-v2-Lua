-- 群英荟萃-江湖之远
-- Created by DZDcyj at 2024/01/30
module('extensions.GatheringHeroesFarAwayJianghuPackage', package.seeall)
extension = sgs.Package('GatheringHeroesFarAwayJianghuPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- 管宁
ExTenYearGuanning = sgs.General(extension, 'ExTenYearGuanning', 'wei', 7, true, true, false, 3)

local available_dunshi_skills = { -- 仁义礼智信技能表
'rende', 'renxin', 'suiren', -- 仁
'juyi', 'yicong', 'yijue', 'yishe', 'yixiang', 'tianyi', 'LuaYizheng', 'LuaStarYishi', 'LuaZhiyi', 'LuaShangyi', -- 义
'lixia', 'LuaLilu', 'yili', 'lirang', -- 礼
'zhiyu', 'zhichi', 'jizhi', 'shenzhi' -- 智
-- 信
}

local dunshi_patterns = {'slash', 'jink', 'peach', 'analeptic'}

LuaDunshi_select = sgs.CreateSkillCard {
    name = 'LuaDunshi',
    will_throw = false,
    target_fixed = true,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        local choices = {}
        for _, name in ipairs(dunshi_patterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            poi:setSkillName('LuaDunshi')
            room:setCardFlag(poi, 'LuaDunshi')
            if poi:isAvailable(source) and source:getMark('LuaDunshi' .. name) == 0 and
                not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
                table.insert(choices, name)
            end
        end
        if next(choices) ~= nil then
            table.insert(choices, 'cancel')
            local pattern = room:askForChoice(source, 'LuaDunshi', table.concat(choices, '+'))
            if pattern and pattern ~= 'cancel' then
                local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
                room:setCardFlag(poi, 'LuaDunshi')
                if poi:targetFixed() then
                    poi:setSkillName('LuaDunshi')
                    room:useCard(sgs.CardUseStruct(poi, source, source), true)
                else
                    local pos = rinsan.getPos(dunshi_patterns, pattern)
                    room:setPlayerMark(source, 'LuaDunshipos', pos)
                    room:askForUseCard(source, '@@LuaDunshi', '@LuaDunshi:' .. pattern)
                end
            end
        end
    end,
}

LuaDunshiCard = sgs.CreateSkillCard {
    name = 'LuaDunshiCard',
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
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
            if card and card:targetFixed() then
                return false
            else
                if card then
                    local filter = card:targetFilter(plist, to_select, sgs.Self)
                    local prohibited = sgs.Self:isProhibited(to_select, card, plist)
                    return filter and (not prohibited)
                end
                return false
            end
        end
        return true
    end,
    target_fixed = false,
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
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        end
        return card and card:targetsFeasible(plist, sgs.Self)
    end,
    on_validate_in_response = function(self, user)
        local room = user:getRoom()
        local aocaistring = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
        if string.find(aocaistring, '+') then
            local uses = {}
            for _, name in pairs(aocaistring:split('+')) do
                if table.contains(dunshi_patterns, name) then
                    if user:getMark('LuaDunshi' .. name) == 0 then
                        table.insert(uses, name)
                    end
                end
            end
            local name = room:askForChoice(user, 'LuaDunshi', table.concat(uses, '+'))
            use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        use_card:setSkillName('LuaDunshi')
        room:setCardFlag(use_card, 'LuaDunshi')
        return use_card
    end,
    on_validate = function(self, card_use)
        local room = card_use.from:getRoom()
        local aocaistring = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
        if string.find(aocaistring, '+') then
            local uses = {}
            for _, name in pairs(aocaistring:split('+')) do
                if table.contains(dunshi_patterns, name) then
                    if card_use.from:getMark('LuaDunshi' .. name) == 0 then
                        table.insert(uses, name)
                    end
                end
            end
            local name = room:askForChoice(card_use.from, 'LuaDunshi', table.concat(uses, '+'))
            use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        if use_card == nil then
            return nil
        end
        use_card:setSkillName('LuaDunshi')
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
        room:setCardFlag(use_card, 'LuaDunshi')
        return use_card
    end,
}

LuaDunshiVS = sgs.CreateViewAsSkill {
    name = 'LuaDunshi',
    n = 0,
    response_or_use = true,
    view_filter = function(self, selected, to_select)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern and pattern == '@@LuaDunshi' then
            return false
        else
            return true
        end
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            local acard = LuaDunshi_select:clone()
            return acard
        else
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == 'slash' then
                pattern = 'slash+thunder_slash+fire_slash'
            end
            local acard = LuaDunshiCard:clone()
            if pattern and pattern == '@@LuaDunshi' then
                pattern = dunshi_patterns[sgs.Self:getMark('LuaDunshipos')]
            end
            if pattern == 'peach+analeptic' and sgs.Self:hasFlag('Global_PreventPeach') then
                pattern = 'analeptic'
            end
            acard:setUserString(pattern)
            return acard
        end
    end,
    enabled_at_play = function(self, player)
        if player:getMark('LuaDunshi-Clear') > 0 then
            return false
        end
        local choices = {}
        for _, name in ipairs(dunshi_patterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            if poi:isAvailable(player) and player:getMark('LuaDunshi' .. name) == 0 then
                table.insert(choices, name)
            end
        end
        return next(choices)
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getMark('LuaDunshi-Clear') > 0 then
            return false
        end
        if pattern == '@@LuaDunshi' then
            return true
        end
        for _, p in pairs(pattern:split('+')) do
            if table.contains(dunshi_patterns, p) then
                if player:getMark(self:objectName() .. p) == 0 then
                    return true
                end
            end
        end
        return false
    end,
    enabled_at_nullification = function(self, player, pattern)
        return false
    end,
}

LuaDunshi = sgs.CreateTriggerSkill {
    name = 'LuaDunshi',
    events = {sgs.DamageCaused, sgs.CardUsed, sgs.CardResponded},
    view_as_skill = LuaDunshiVS,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            local from = damage.from
            if not from then
                return false
            end
            for _, guanning in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if from:getMark(self:objectName() .. guanning:objectName() .. '-Clear') > 0 then
                    local skill_choices = {}
                    -- 获得技能并防止伤害
                    local available_skills = {}
                    for _, skill in ipairs(available_dunshi_skills) do
                        if not from:hasSkill(skill) then
                            table.insert(available_skills, skill)
                        end
                    end
                    rinsan.shuffleTable(available_skills)
                    local skill_to_choose = {}
                    for i = 1, #available_skills, 1 do
                        table.insert(skill_to_choose, available_skills[i])
                        if i == 3 then
                            break
                        end
                    end
                    if #skill_to_choose > 0 then
                        table.insert(skill_choices, 'LuaDunshi1')
                    end
                    -- 用于记录已删除的牌名
                    local choices = {}
                    for _, pattern in ipairs(dunshi_patterns) do
                        if player:getMark('LuaDunshi' .. pattern) == 0 then
                            table.insert(choices, pattern)
                        end
                    end
                    if #skill_choices == 0 then
                        goto next_guanning
                    end
                    table.insert(skill_choices, 'LuaDunshi2')
                    table.insert(skill_choices, 'LuaDunshi3')
                    local skill_choice1 = room:askForChoice(guanning, self:objectName(), table.concat(skill_choices, '+'))
                    table.removeAll(skill_choices, skill_choice1)
                    local skill_choice2 = room:askForChoice(guanning, self:objectName(), table.concat(skill_choices, '+'))
                    local total_chosen = {skill_choice1, skill_choice2}
                    local x = 4 - #choices
                    if table.contains(total_chosen, 'LuaDunshi3') then
                        -- 删除本次使用牌名
                        local choice = dunshi_patterns[guanning:getMark('LuaDunshi-Used-Clear')]
                        room:addPlayerMark(guanning, 'LuaDunshi' .. choice)
                        x = x + 1
                    end
                    if table.contains(total_chosen, 'LuaDunshi2') then
                        -- 减一点体力上限，摸 X 张牌
                        room:loseMaxHp(guanning)
                        if x > 0 then
                            guanning:drawCards(x, self:objectName())
                        end
                    end
                    if table.contains(total_chosen, 'LuaDunshi1') then
                        -- 获得技能并防止伤害
                        local gain = room:askForChoice(guanning, self:objectName(), table.concat(skill_to_choose, '+'))
                        room:acquireSkill(from, gain)
                        room:removePlayerMark(from, self:objectName() .. guanning:objectName() .. '-Clear')
                        return true
                    end
                    room:removePlayerMark(from, self:objectName() .. guanning:objectName() .. '-Clear')
                end
                ::next_guanning::
            end
            return false
        end
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and card:hasFlag('LuaDunshi') then
            room:addPlayerMark(player, 'LuaDunshi-Clear')
            room:addPlayerMark(room:getCurrent(), self:objectName() .. player:objectName() .. '-Clear')
            room:setPlayerMark(player, 'LuaDunshi-Used-Clear', rinsan.getPos(dunshi_patterns, card:objectName()))
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

ExTenYearGuanning:addSkill(LuaDunshi)

rinsan.addHiddenSkills(hiddenSkills)
