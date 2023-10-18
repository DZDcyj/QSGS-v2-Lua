-- 斗地主包
-- Created by DZDcyj at 2021/10/9
module('extensions.LandlordsPackage', package.seeall)
extension = sgs.Package('LandlordsPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

LuaBahu = sgs.CreateTriggerSkill {
    name = 'LuaBahu',
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:drawCards(1)
        end
    end,
    -- 考虑到现在的“缠怨”实现不为倾城标记的添加，在这里以地主标记作为判断依据
    -- 如此一来，无论是“断肠”还是“缠怨”都不会影响地主技能的释放
    can_trigger = function(self, target)
        return target and target:isAlive() and (target:hasSkill(self:objectName()) or target:getMark('LuaDizhu') > 0)
    end,
}

LuaBahuSlash = sgs.CreateTargetModSkill {
    name = 'LuaBahuSlash',
    frequency = sgs.Skill_Compulsory,
    residue_func = function(self, player)
        if player:hasSkill('LuaBahu') or player:getMark('LuaDizhu') > 0 then
            return 1
        else
            return 0
        end
    end,
}

LuaFeiyangCard = sgs.CreateSkillCard {
    name = 'LuaFeiyangCard',
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:notifySkillInvoked(source, 'LuaFeiyang')
        if source:getJudgingArea():length() > 0 then
            room:throwCard(room:askForCardChosen(source, source, 'j', 'LuaFeiyang', true, sgs.Card_MethodDiscard),
                source)
        end
    end,
}

LuaFeiyangVS = sgs.CreateViewAsSkill {
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
    end,
}

LuaFeiyang = sgs.CreateTriggerSkill {
    name = 'LuaFeiyang',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = LuaFeiyangVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getJudgingArea():length() > 0 and rinsan.canDiscard(player, player, 'h') and
                player:getHandcardNum() >= 2 then
                room:askForUseCard(player, '@@LuaFeiyang', '@LuaFeiyang')
            end
        end
    end,
    -- 同“跋扈”
    can_trigger = function(self, target)
        return target and target:isAlive() and (target:hasSkill(self:objectName()) or target:getMark('LuaDizhu') > 0)
    end,
}

-- 兼容性考虑判断地主
local function LuaIsDizhu(target)
    return (target:hasSkill('LuaDizhu') or target:getMark('@Landlords') > 0)
end

local function getSeatString(i)
    return string.format('BroadcastSeat%d', i)
end

-- 通报座次
local function broadcastSeat(landlord)
    local room = landlord:getRoom()
    local curr = landlord
    local index = 1
    repeat
        rinsan.sendLogMessage(room, '#BroadcastSeat', {
            ['arg'] = curr:screenName(),
            ['arg2'] = getSeatString(index),
        })
        curr = curr:getNextAlive(1)
        index = index + 1
    until curr:objectName() == landlord:objectName()
end

local available_call_option = {
    [1] = '0x',
    [2] = '1x',
    [3] = '2x',
    [4] = '3x',
}

-- 叫地主环节
local function callLandholder(first)
    local room = first:getRoom()
    local curr = first
    local biggest = first
    local biggestNumber = 1
    repeat
        local call = room:askForChoice(curr, 'rob-landlord', table.concat(available_call_option, '+'))
        if call == '3x' then
            return curr
        end
        -- 同样叫分先到者行
        if rinsan.getPos(available_call_option, call) > biggestNumber then
            biggest = curr
            biggestNumber = rinsan.getPos(available_call_option, call)
        end
        curr = curr:getNextAlive(1)
    until curr:objectName() == first:objectName()
    return biggest
end

local function adjustPlayer(landlord)
    local room = landlord:getRoom()
    local players = room:getPlayers()
    while not players:isEmpty() do
        players:removeAt(0)
    end
    local curr = landlord
    repeat
        players:append(curr)
        curr = curr:getNextAlive(1)
    until curr:objectName() == landlord:objectName()
end

-- 设置斗地主模式当前状态
-- initState，是否为初始化状态，即是否无效化技能等
local function setInitState(room, initState)
    if initState then
        room:setTag('FirstRound', sgs.QVariant(true))
        rinsan.invalidateAllPlayersVisibleSkills(room)
    else
        rinsan.validateAllPlayersVisibleSkills(room)
        room:setTag('FirstRound', sgs.QVariant(false))
    end
end

LuaDizhu = sgs.CreateTriggerSkill {
    name = 'LuaDizhu',
    events = {sgs.TurnStart},
    frequency = sgs.Skill_Compulsory,
    -- priority 调整为最优先
    priority = 10,
    global = true,
    on_trigger = function(self, event, splayer, data, room)
        -- 优化 UI 显示
        room:setPlayerMark(splayer, '@Landlords', 0)

        local player = callLandholder(splayer)
        adjustPlayer(player)
        room:setCurrent(player)
        if splayer:objectName() ~= player:objectName() then
            room:setPlayerProperty(splayer, 'role', sgs.QVariant('rebel'))
            room:setPlayerProperty(player, 'role', sgs.QVariant('lord'))
        end
        room:addPlayerMark(player, self:objectName())

        broadcastSeat(player)

        rinsan.landlordsGeneralChoose(room)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:acquireSkill(player, 'LuaBahu')
        room:acquireSkill(player, 'LuaFeiyang')

        -- 屏蔽技能影响
        setInitState(room, true)

        -- 设置初始血量，主要针对不满血的武将
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local start_hp = rinsan.getStartHp(p)
            room:setPlayerProperty(p, 'hp', sgs.QVariant(start_hp))
        end

        -- 为自己增加一点体力上限
        rinsan.addPlayerMaxHp(player, 1)
        rinsan.recover(player, 1, player)

        -- 解除技能屏蔽
        setInitState(room, false)

        -- 初始技能触发
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            -- 触发游戏开始时时机，例如先辅、怀橘
            room:getThread():trigger(sgs.GameStart, room, p)
        end

        -- 摸牌在初始技能全部触发完毕之后
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            -- 统一在这里进行初始牌的摸取，避免提前摸牌导致一些问题
            room:setTag('FirstRound', sgs.QVariant(true))
            local draw_data = sgs.QVariant(4)
            room:getThread():trigger(sgs.DrawInitialCards, room, p, draw_data)
            local to_draw = draw_data:toInt()
            if to_draw > 0 then
                p:drawCards(to_draw, self:objectName())
            end
            room:setTag('FirstRound', sgs.QVariant(false))
        end

        -- 手气卡
        -- 屏蔽技能影响
        setInitState(room, true)

        -- 手气卡
        rinsan.askForLuckCard(room)
        
        -- 解除技能屏蔽
        setInitState(room, false)

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

        -- 处理锁定视为技
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            room:filterCards(p, p:getCards('he'), true)
        end

        -- 触发当前回合角色的技能
        for _, skill in sgs.qlist(player:getVisibleSkillList()) do
            local triggerSkill = sgs.Sanguosha:getTriggerSkill(skill:objectName())
            if triggerSkill then
                triggerSkill:trigger(sgs.TurnStart, room, player, data)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and LuaIsDizhu(target) and target:getMark(self:objectName()) == 0
    end,
}

-- 斗地主场景技能
-- 主要负责模块为：死亡奖惩与农民摸牌
LuaDoudizhuScenario = sgs.CreateTriggerSkill {
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
                        table.insert(choices, 'LuaNongminChoice1')
                    end
                    table.insert(choices, 'LuaNongminChoice2')
                    table.insert(choices, 'cancel')
                    local choice = room:askForChoice(target, 'LuaNongmin', table.concat(choices, '+'))
                    if choice == 'LuaNongminChoice1' then
                        rinsan.recover(target, 1, player)
                    elseif choice == 'LuaNongminChoice2' then
                        target:drawCards(2)
                    end
                end
            end
            room:setTag('FirstRound', sgs.QVariant(false))
        end
        return false
    end,
    can_trigger = function(self, target)
        -- 当且仅当存在拥有地主标志角色的时，才会启用斗地主模式相关逻辑
        if target and target:getMark('LuaDizhu') > 0 then
            return true
        end
        for _, p in sgs.qlist(target:getSiblings()) do
            if p:getMark('LuaDizhu') > 0 then
                return true
            end
        end
        return false
    end,
}

table.insert(hiddenSkills, LuaBahu)
table.insert(hiddenSkills, LuaBahuSlash)
table.insert(hiddenSkills, LuaFeiyang)
table.insert(hiddenSkills, LuaDizhu)
table.insert(hiddenSkills, LuaDoudizhuScenario)

rinsan.addHiddenSkills(hiddenSkills)
