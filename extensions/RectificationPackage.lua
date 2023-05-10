-- 整肃包
-- Created by DZDcyj at 2023/5/9
module('extensions.RectificationPackage', package.seeall)
extension = sgs.Package('RectificationPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function targetTrigger(self, target)
    return target
end

-- 忽略本文件中未引用 global variable 的警告
-- luacheck: push ignore 131

local hiddenSkills = {}

local RECTIFICATION_CHOICES = {
    [1] = 'RectificationPackage_Leijin', -- 擂进
    [2] = 'RectificationPackage_Bianzhen', -- 变阵
    [3] = 'RectificationPackage_Mingzhi', -- 鸣止
}

local SEPARATOR = '|'
local NUMBER_TAG = 'RectificationPackage_Play_Number'
local SUIT_TAG = 'RectificationPackage_Play_Suit'
local DISCARD_TAG = 'RectificationPackage_Discard_Suit'

-- 获取角色对应整肃 tagName 的 table
local function getRectificationStringTable(player, tagName)
    local tag = player:getTag(tagName)
    if tag then
        local str = tag:toString()
        return str:split(SEPARATOR)
    end
    return {}
end

local function setRectificationStringTable(player, tagName, strTable)
    player:setTag(tagName, sgs.QVariant(table.concat(strTable, SEPARATOR)))
end

-- 询问整肃选项
local function askForRectificationChoice(player, skillName)
    local room = player:getRoom()
    skillName = skillName or ''
    return room:askForChoice(player, skillName, table.concat(RECTIFICATION_CHOICES, '+'))
end

-- 询问整肃，暴露的外部接口
function askForRetification(from, to, skillName, isFromChoose)
    local room = from:getRoom()
    local chooser = isFromChoose and from or to
    local choice = askForRectificationChoice(chooser, skillName)
    rinsan.sendLogMessage(room, '#Rectification-Choose', {
        ['from'] = to,
        ['arg'] = choice,
        ['arg2'] = ':' .. choice,
    })
    -- 标记整肃类型
    room:addPlayerMark(to, choice)
    -- 标记整肃发起者
    -- 标记规则：整肃选项-执行者-发起者-技能名称
    local mark = string.format('%s-%s-%s-%s', choice, to:objectName(), from:objectName(), skillName)
    room:addPlayerMark(to, mark)
end

local RECTIFICATION_CHECK_FUNCTIONS = {
    ['RectificationPackage_Leijin'] = function(player)
        local leijinTable = getRectificationStringTable(player, NUMBER_TAG)
        -- 使用过至少三张牌
        if #leijinTable < 3 then
            return false
        end
        -- 点数需要严格递增
        for i = 1, #leijinTable - 1, 1 do
            if leijinTable[i] >= leijinTable[i + 1] then
                return false
            end
        end
        return true
    end,
    ['RectificationPackage_Bianzhen'] = function(player)
        local bianzhenTable = getRectificationStringTable(player, SUIT_TAG)
        -- 使用过至少两张牌
        if #bianzhenTable < 2 then
            return false
        end
        -- 花色一致
        local fixedSuit = bianzhenTable[1]
        for _, suit in ipairs(bianzhenTable) do
            if suit ~= fixedSuit then
                return false
            end
        end
        return true
    end,
    ['RectificationPackage_Mingzhi'] = function(player)
        local mingzhiTable = getRectificationStringTable(player, DISCARD_TAG)
        -- 使用过至少两张牌
        if #mingzhiTable < 2 then
            return false
        end
        -- 花色一致
        local suits = {}
        for _, suit in ipairs(mingzhiTable) do
            if table.contains(suits, suit) then
                return false
            else
                table.insert(suits, suit)
            end
        end
        return true
    end,
}

-- 外部接口，返回整肃成功选项的 table
function doRetificationCheck(player)
    local successChoices = {}
    for _, choice in ipairs(RECTIFICATION_CHOICES) do
        local checkFunc = RECTIFICATION_CHECK_FUNCTIONS[choice]
        if checkFunc(player) then
            table.insert(successChoices, choice)
        end
    end
    return successChoices
end

local function findPlayerByName(room, name)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:objectName() == name then
            return p
        end
    end
    return nil
end

-- 外部接口，返回整肃选项的发起人 table
function getAskerTableOfRetification(player, choice)
    local avaiable_asker_names = {}
    local askers = {}
    local markPrefix = string.format('%s-%s', choice, player:objectName())
    for _, mark in sgs.list(player:getMarkNames()) do
        -- 必须显式 plain
        if string.find(mark, markPrefix, 1, true) and player:getMark(mark) > 0 then
            local name = mark:split('-')[3]
            table.insert(avaiable_asker_names, name)
        end
    end
    if #avaiable_asker_names > 0 then
        local room = player:getRoom()
        for _, name in ipairs(avaiable_asker_names) do
            local asker = findPlayerByName(room, name)
            if asker then
                table.insert(askers, asker)
            end
        end
    end
    return askers
end

-- 出牌阶段用牌记录
LuaRectificationPlayPhaseRecord = sgs.CreateTriggerSkill {
    name = 'LuaRectificationPlayPhaseRecord',
    events = {sgs.CardUsed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and (not use.card:isKindOf('SkillCard')) then
            local numberTable = getRectificationStringTable(player, NUMBER_TAG)
            local suitTable = getRectificationStringTable(player, SUIT_TAG)
            local number = use.card:getNumber()
            local suit = use.card:getSuitString()
            table.insert(numberTable, number)
            table.insert(suitTable, suit)
            setRectificationStringTable(player, NUMBER_TAG, numberTable)
            setRectificationStringTable(player, SUIT_TAG, suitTable)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getPhase() == sgs.Player_Play
    end,
}

-- 弃牌阶段弃牌记录
LuaRectificationDiscardPhaseRecord = sgs.CreateTriggerSkill {
    name = 'LuaRectificationDiscardPhaseRecord',
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        local source = move.from
        if not source then
            return false
        end
        if player:objectName() ~= source:objectName() then
            return false
        end
        local reason = move.reason
        if not rinsan.moveBasicReasonCompare(reason.m_reason, sgs.CardMoveReason_S_REASON_DISCARD) then
            return false
        end
        local discardSuitTable = getRectificationStringTable(player, DISCARD_TAG)
        for _, id in sgs.qlist(move.card_ids) do
            local cd = sgs.Sanguosha:getCard(id)
            table.insert(discardSuitTable, cd:getSuitString())
        end
        setRectificationStringTable(player, DISCARD_TAG, discardSuitTable)
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:getPhase() == sgs.Player_Discard
    end,
}

local function askForBonus(player)
    local room = player:getRoom()
    local choices = {}
    if player:isWounded() then
        table.insert(choices, 'rectification:recover')
    end
    table.insert(choices, 'rectification:draw')
    local choice = room:askForChoice(player, 'RectificationBonus', table.concat(choices, '+'))
    if choice == 'rectification:draw' then
        player:drawCards(2, 'RectificationBonus')
    else
        rinsan.recover(player, 1)
    end
end

LuaRectificationCheck = sgs.CreateTriggerSkill {
    name = 'LuaRectificationCheck',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().from == sgs.Player_Discard then
            local success = doRetificationCheck(player)
            for _, choice in ipairs(success) do
                local askers = getAskerTableOfRetification(player, choice)
                for _, asker in ipairs(askers) do
                    askForBonus(asker)
                    askForBonus(player)
                end
            end
            player:removeTag(DISCARD_TAG)
            player:removeTag(SUIT_TAG)
            player:removeTag(NUMBER_TAG)
            rinsan.clearAllMarksContains(player, 'RectificationPackage')
        end
    end,
    can_trigger = targetTrigger,
}

table.insert(hiddenSkills, LuaRectificationCheck)
table.insert(hiddenSkills, LuaRectificationDiscardPhaseRecord)
table.insert(hiddenSkills, LuaRectificationPlayPhaseRecord)

rinsan.addHiddenSkills(hiddenSkills)

-- luacheck: pop
