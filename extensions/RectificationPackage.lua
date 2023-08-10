-- 整肃包
-- Created by DZDcyj at 2023/5/9
module('extensions.RectificationPackage', package.seeall)
extension = sgs.Package('RectificationPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

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
local function askForRectificationChoice(player, skillName, to, ignoreChosen)
    local room = player:getRoom()
    skillName = skillName or ''
    local choices = {}
    if ignoreChosen then
        choices = RECTIFICATION_CHOICES
    else
        for _, choice in ipairs(RECTIFICATION_CHOICES) do
            if to:getMark(choice) == 0 then
                table.insert(choices, choice)
            end
        end
    end
    return room:askForChoice(player, skillName, table.concat(choices, '+'))
end

-- 是否可以发动整肃
function canBeAskedForRectification(player)
    for _, choice in ipairs(RECTIFICATION_CHOICES) do
        if player:getMark(choice) == 0 then
            return true
        end
    end
    return false
end

-- 询问整肃，暴露的外部接口
function askForRectification(from, to, skillName, isFromChoose, ignoreChosen)
    local room = from:getRoom()
    local chooser = isFromChoose and from or to
    local choice = askForRectificationChoice(chooser, skillName, to, ignoreChosen)
    local msgType = isFromChoose and '#Rectification-Choose' or '#Rectification-Self-Choose'
    rinsan.sendLogMessage(room, msgType, {
        ['from'] = from,
        ['to'] = to,
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
            if tonumber(leijinTable[i]) >= tonumber(leijinTable[i + 1]) then
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

local function findPlayerByName(room, name)
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:objectName() == name then
            return p
        end
    end
    return nil
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

local function askForBonus(player, chooser)
    local room = player:getRoom()
    chooser = chooser or player
    local choices = {}
    if player:isWounded() then
        table.insert(choices, 'rectification:recover')
    end
    table.insert(choices, 'rectification:draw')
    local choice = room:askForChoice(chooser, 'RectificationBonus', table.concat(choices, '+'))
    if choice == 'rectification:draw' then
        player:drawCards(2, 'RectificationBonus')
    else
        rinsan.recover(player, 1)
    end
end

-- 首先获取对应的 Marks
local function getRectificationMarks(player)
    local marks = {}
    for i = 1, #RECTIFICATION_CHOICES, 1 do
        local markPrefix = string.format('%s-%s', RECTIFICATION_CHOICES[i], player:objectName())
        for _, mark in sgs.list(player:getMarkNames()) do
            -- 必须显式 plain
            if string.find(mark, markPrefix, 1, true) and player:getMark(mark) > 0 then
                table.insert(marks, mark)
            end
        end
    end
    return marks
end

-- 整肃成功的不同对应
local RECTIFICATION_BONUS_FUNCS = {
    ['LuaHoufeng'] = function(from, to)
        askForBonus(from)
        askForBonus(to)
    end,
    ['LuaZhengjun'] = function(from, _)
        local room = from:getRoom()
        local other = room:askForPlayerChosen(from, room:getOtherPlayers(from), 'RectificationBonus',
            'RectificationBonus-choose', true)
        askForBonus(from)
        if other then
            room:doAnimate(rinsan.ANIMATE_INDICATE, from:objectName(), other:objectName())
            askForBonus(other, from)
        end
    end,
    ['LuaYanji'] = function(from, _)
        askForBonus(from)
    end,
}

-- 默认 2 为整肃成功语音，3 为失败语音
local function doRectification(player)
    local room = player:getRoom()
    -- 获取所有涉及到整肃的标记
    local marks = getRectificationMarks(player)
    for _, mark in ipairs(marks) do
        local items = mark:split('-')
        local choice = items[1] -- 整肃类型
        -- 整肃执行者即为 player，无需从 mark 中获取
        local fromName = items[3] -- 整肃发起者
        local from = findPlayerByName(room, fromName)
        if not from then
            goto next_mark
        end
        local skillName = items[4] -- 整肃技能名称
        local success = RECTIFICATION_CHECK_FUNCTIONS[choice](player)
        room:notifySkillInvoked(from, skillName)
        if success then
            room:broadcastSkillInvoke(skillName, 2)
            rinsan.sendLogMessage(room, '#Rectification-Success', {
                ['from'] = player,
                ['to'] = from,
                ['arg'] = skillName .. 'Rectification',
            })
            local bonusFunc = RECTIFICATION_BONUS_FUNCS[skillName]
            if bonusFunc then
                bonusFunc(from, player)
            end
        else
            rinsan.sendLogMessage(room, '#Rectification-Failure', {
                ['from'] = player,
                ['to'] = from,
                ['arg'] = skillName .. 'Rectification',
            })
            room:broadcastSkillInvoke(skillName, 3)
        end
        ::next_mark::
    end
end

LuaRectificationCheck = sgs.CreateTriggerSkill {
    name = 'LuaRectificationCheck',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().from == sgs.Player_Discard then
            doRectification(player)
            player:removeTag(DISCARD_TAG)
            player:removeTag(SUIT_TAG)
            player:removeTag(NUMBER_TAG)
            rinsan.clearAllMarksContains(player, 'RectificationPackage')
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

table.insert(hiddenSkills, LuaRectificationCheck)
table.insert(hiddenSkills, LuaRectificationDiscardPhaseRecord)
table.insert(hiddenSkills, LuaRectificationPlayPhaseRecord)

rinsan.addHiddenSkills(hiddenSkills)

-- luacheck: pop
