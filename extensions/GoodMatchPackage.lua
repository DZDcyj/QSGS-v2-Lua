-- 限定-锦瑟良缘包
-- Created by DZDcyj at 2023/5/4
module('extensions.GoodMatchPackage', package.seeall)
extension = sgs.Package('GoodMatchPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 曹金玉
ExTenYearCaojinyu = sgs.General(extension, 'ExTenYearCaojinyu', 'wei', '3', false, true)

-- 曹金玉系列判断

-- 可以观看的牌数
local function getYuqiPreviewCardCount(caojinyu)
    return 3 + caojinyu:getMark('LuaYuqiPreviewCardCount')
end

-- 判断距离
local function getYuqiAvailableDistance(caojinyu)
    return caojinyu:getMark('LuaYuqiDistance')
end

-- 是否可以发动“隅泣”
local function canInvokeYuqi(caojinyu, player)
    if caojinyu:distanceTo(player) > getYuqiAvailableDistance(caojinyu) then
        return false
    end
    return caojinyu:getMark('LuaYuqiInvokeTime') < 2
end

-- 至多给出的牌
local function getYuqiGiveCardCount(caojinyu)
    return 1 + caojinyu:getMark('LuaYuqiGiveCardCount')
end

-- 至多获得的牌
local function getYuqiKeepCardCount(caojinyu)
    return 1 + caojinyu:getMark('LuaYuqiKeepCardCount')
end

-- 函数映射
local YUQI_FUNCS = {getYuqiPreviewCardCount, getYuqiGiveCardCount, getYuqiKeepCardCount, getYuqiAvailableDistance}

-- 映射位置
local YUQI_MAP = {'LuaYuqiPreviewCardCount', 'LuaYuqiGiveCardCount', 'LuaYuqiKeepCardCount', 'LuaYuqiDistance'}

-- 是否可以增加数字
local function canIncreaseNumber(caojinyu)
    if getYuqiAvailableDistance(caojinyu) < 5 then
        return true
    end
    if getYuqiPreviewCardCount(caojinyu) < 5 then
        return true
    end
    if getYuqiGiveCardCount(caojinyu) < 5 then
        return true
    end
    if getYuqiKeepCardCount(caojinyu) < 5 then
        return true
    end
    return false
end

-- 增加“隅泣”数字
local function increaseYuqiNumber(caojinyu, position, value)
    if position <= 0 or position > 4 then
        return
    end
    local room = caojinyu:getRoom()
    local diff = math.max(0, 5 - YUQI_FUNCS[position](caojinyu))
    if diff <= 0 then
        return
    end
    room:addPlayerMark(caojinyu, YUQI_MAP[position], math.min(diff, value))
end

-- 选择增加选项
local function askForYuqiIncreaseChoice(caojinyu, value, skill_name)
    local choices = {}
    for index, func in ipairs(YUQI_FUNCS) do
        if func(caojinyu) < 5 then
            table.insert(choices, YUQI_MAP[index])
        end
    end
    if #choices == 0 then
        return
    end
    local room = caojinyu:getRoom()
    local choice = room:askForChoice(caojinyu, skill_name, table.concat(choices, '+'))
    local pos = rinsan.getPos(YUQI_MAP, choice)
    increaseYuqiNumber(caojinyu, pos, value)
end

LuaYuqi = sgs.CreateTriggerSkill {
    name = 'LuaYuqi',
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local victim = data:toDamage().to
        for _, caojinyu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if canInvokeYuqi(caojinyu, player) and room:askForSkillInvoke(caojinyu, self:objectName(), data) then
                room:addPlayerMark(caojinyu, 'LuaYuqiInvokeTime')
                room:broadcastSkillInvoke(self:objectName())

                local totalCount = getYuqiPreviewCardCount(caojinyu)
                local giveCount = getYuqiGiveCardCount(caojinyu)
                local keepCount = getYuqiKeepCardCount(caojinyu)

                local _cjy = sgs.SPlayerList()
                _cjy:append(caojinyu)
                local yuqi_cards = room:getNCards(totalCount, false)
                local move = sgs.CardsMoveStruct(yuqi_cards, nil, caojinyu, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, caojinyu:objectName(), self:objectName(), nil))
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, _cjy)
                room:notifyMoveCards(false, moves, false, _cjy)
                local origin_yuqi = sgs.IntList()
                for _, id in sgs.qlist(yuqi_cards) do
                    origin_yuqi:append(id)
                end
                local tos = sgs.SPlayerList()
                tos:append(victim)
                if victim:isAlive() and
                    room:askForYiji(caojinyu, yuqi_cards, self:objectName(), true, false, true, giveCount, tos,
                        sgs.CardMoveReason(), string.format('LuaYuqiGiveOut:%s:%s', victim:objectName(), giveCount)) then
                    local _reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, caojinyu:objectName(),
                        self:objectName(), nil)
                    move = sgs.CardsMoveStruct(sgs.IntList(), caojinyu, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                        _reason)
                    for _, id in sgs.qlist(origin_yuqi) do
                        if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                            move.card_ids:append(id)
                            yuqi_cards:removeOne(id)
                        end
                    end
                    origin_yuqi = sgs.IntList()
                    for _, id in sgs.qlist(yuqi_cards) do
                        origin_yuqi:append(id)
                    end
                    moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _cjy)
                    room:notifyMoveCards(false, moves, false, _cjy)
                    if not caojinyu:isAlive() then
                        return
                    end
                end
                local selfs = sgs.SPlayerList()
                selfs:append(caojinyu)
                if room:askForYiji(caojinyu, yuqi_cards, self:objectName(), true, false, true, keepCount, selfs,
                    sgs.CardMoveReason(), string.format('LuaYuqiKeep:%d', keepCount)) then
                    local _reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, caojinyu:objectName(),
                        self:objectName(), nil)
                    move = sgs.CardsMoveStruct(sgs.IntList(), caojinyu, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                        _reason)
                    for _, id in sgs.qlist(origin_yuqi) do
                        if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                            move.card_ids:append(id)
                            yuqi_cards:removeOne(id)
                        end
                    end
                    origin_yuqi = sgs.IntList()
                    for _, id in sgs.qlist(yuqi_cards) do
                        origin_yuqi:append(id)
                    end
                    moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _cjy)
                    room:notifyMoveCards(false, moves, false, _cjy)
                    if not caojinyu:isAlive() then
                        return
                    end
                end
                if not yuqi_cards:isEmpty() then
                    move = sgs.CardsMoveStruct(yuqi_cards, caojinyu, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, '', self:objectName(), nil))
                    moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _cjy)
                    room:notifyMoveCards(false, moves, false, _cjy)
                    room:returnToTopDrawPile(yuqi_cards)
                end
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaYuqiClear = sgs.CreateTriggerSkill {
    name = 'LuaYuqiClear',
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, 'LuaYuqiInvokeTime', 0)
            end
        end
    end,
    can_trigger = rinsan.globalTrigger,
}

LuaShanshen = sgs.CreateTriggerSkill {
    name = 'LuaShanshen',
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        for _, sp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if canIncreaseNumber(sp) and room:askForSkillInvoke(sp, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                askForYuqiIncreaseChoice(sp, 2, self:objectName())
                if death.who:getMark(string.format('LuaDamagedBy%s', sp:objectName())) == 0 then
                    rinsan.recover(sp)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

LuaXianjing = sgs.CreateTriggerSkill {
    name = 'LuaXianjing',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if canIncreaseNumber(player) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            askForYuqiIncreaseChoice(player, 1, self:objectName())
            if not player:isWounded() then
                askForYuqiIncreaseChoice(player, 1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_RoundStart)
    end,
}

ExTenYearCaojinyu:addSkill(LuaYuqi)
ExTenYearCaojinyu:addSkill(LuaShanshen)
ExTenYearCaojinyu:addSkill(LuaXianjing)
table.insert(hiddenSkills, LuaYuqiClear)

-- 孙翊
ExTenYearSunyi = sgs.General(extension, 'ExTenYearSunyi', 'wu', '5', true, true)

local JIQIAO_PILE_NAME = 'LuaJiqiao'

LuaJiqiao = sgs.CreateTriggerSkill {
    name = 'LuaJiqiao',
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            if player:getPile(JIQIAO_PILE_NAME):isEmpty() then
                return false
            end
            player:clearOnePrivatePile(JIQIAO_PILE_NAME)
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            local ids = room:getNCards(player:getMaxHp())
            player:addToPile(JIQIAO_PILE_NAME, ids)
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHTATPHASE(self, target, sgs.Player_Play)
    end,
}

LuaJiqiaoFinished = sgs.CreateTriggerSkill {
    name = 'LuaJiqiaoFinished',
    events = {sgs.CardFinished},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (not use.card) or use.card:isKindOf('SkillCard') then
            return false
        end
        room:sendCompulsoryTriggerLog(player, 'LuaJiqiao')
        local ids = player:getPile(JIQIAO_PILE_NAME)
        room:fillAG(ids, player)
        local id = room:askForAG(player, ids, false, 'LuaJiqiao')
        room:clearAG(player)
        player:obtainCard(sgs.Sanguosha:getCard(id))
        local redCount, blackCount = 0, 0
        for _, cid in sgs.qlist(player:getPile(JIQIAO_PILE_NAME)) do
            local cd = sgs.Sanguosha:getCard(cid)
            if cd:isRed() then
                redCount = redCount + 1
            elseif cd:isBlack() then
                blackCount = blackCount + 1
            end
        end
        if redCount == blackCount then
            rinsan.recover(player, 1)
        else
            room:loseHp(player)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and (not target:getPile(JIQIAO_PILE_NAME):isEmpty())
    end,
}

LuaXiongyi = sgs.CreateTriggerSkill {
    name = 'LuaXiongyi',
    frequency = sgs.Skill_Limited,
    events = {sgs.AskForPeaches},
    limit_mark = '@LuaXiongyi',
    on_trigger = function(self, event, player, data, room)
        local dying_data = data:toDying()
        local source = dying_data.who
        if source:objectName() == player:objectName() then
            if player:askForSkillInvoke(self:objectName(), data) then
                player:loseMark('@LuaXiongyi')
                local choices = {'LuaXiongyi1', 'LuaXiongyi2'}
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, '+'))
                if choice == choices[1] then
                    room:broadcastSkillInvoke(self:objectName(), 2)
                    -- 回复至三点体力
                    local maxhp = player:getMaxHp()
                    local hp = math.min(3, maxhp)
                    rinsan.recover(player, hp - player:getHp())
                    -- 需要根据主副将判断
                    local firstGeneralName = player:getGeneralName()
                    local secondGeneralName = player:getGeneral2Name()

                    -- 默认单将，改主将位置
                    local isSecondaryHero = false

                    -- 双将才涉及询问，否则默认主将
                    if secondGeneralName ~= '' then
                        if firstGeneralName == 'ExTenYearSunyi' then
                            -- 如果主将是孙翊
                            -- 默认副将不是，如果副将也是，做额外询问
                            if secondGeneralName == 'ExTenYearSunyi' then
                                local general_choice = room:askForChoice(player, self:objectName(), 'GeneralA+GeneralB')
                                isSecondaryHero = (general_choice == 'GeneralB')
                            end
                        else
                            -- 默认副将不为，此处默认为
                            isSecondaryHero = true
                            -- 主将不是孙翊，若副将也不是孙翊，则额外询问
                            if secondGeneralName ~= 'ExTenYearSunyi' then
                                local general_choice = room:askForChoice(player, self:objectName(), 'GeneralA+GeneralB')
                                isSecondaryHero = (general_choice == 'GeneralB')
                            end
                        end
                    end

                    -- 将卡牌替换为徐氏
                    room:changeHero(player, 'xushi', false, true, isSecondaryHero, true)
                    room:setPlayerProperty(player, 'maxhp', sgs.QVariant(maxhp))
                else
                    room:broadcastSkillInvoke(self:objectName(), 1)
                    -- 回复至一点体力
                    local maxhp = player:getMaxHp()
                    local hp = math.min(1, maxhp)
                    rinsan.recover(player, hp - player:getHp())
                    -- 获得“魂姿”
                    room:acquireSkill(player, 'LuaSunyiHunzi')
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return rinsan.RIGHT(self, target) and target:getMark('@LuaXiongyi') > 0
    end,
}

LuaSunyiHunzi = sgs.CreateTriggerSkill {
    name = 'LuaSunyiHunzi',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, 'LuaSunyiHunzi')
        rinsan.sendLogMessage(room, '#LuaHunzi', {
            ['from'] = player,
            ['arg'] = player:getHp(),
            ['arg2'] = self:objectName(),
        })
        if room:changeMaxHpForAwakenSkill(player) then
            room:broadcastSkillInvoke(self:objectName())
            room:notifySkillInvoked(player, self:objectName())
            room:getThread():delay(6500)
            room:setEmotion(player, 'skill/hunzi')
            room:handleAcquireDetachSkills(player, 'LuaYingzi|LuaYinghun')
            room:addPlayerMark(player, 'hunzi')
        end
        return false
    end,
    can_trigger = function(self, target)
        if not rinsan.RIGHT(self, target) then
            return false
        end
        return rinsan.canWakeAtPhase(target, self:objectName(), sgs.Player_Start) and (target:getHp() <= 1)
    end,
}

ExTenYearSunyi:addSkill(LuaJiqiao)
ExTenYearSunyi:addSkill(LuaXiongyi)
ExTenYearSunyi:addRelateSkill('LuaSunyiHunzi')
ExTenYearSunyi:addRelateSkill('LuaYingzi')
ExTenYearSunyi:addRelateSkill('LuaYinghun')
table.insert(hiddenSkills, LuaJiqiaoFinished)
table.insert(hiddenSkills, LuaSunyiHunzi)

rinsan.addHiddenSkills(hiddenSkills)
