-- 协力包
-- Created by DZDcyj at 2023/7/30
module('extensions.UniteEffortsPackage', package.seeall)
extension = sgs.Package('UniteEffortsPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 忽略本文件中未引用 global variable 的警告
-- luacheck: push ignore 131

local hiddenSkills = {}

-- 协力选项
local UNITE_EFFORTS_CHOICES = {
    [1] = 'UniteEffortsPackage_Tongchou', -- 同仇
    [2] = 'UniteEffortsPackage_Bingjin', -- 并进
    [3] = 'UniteEffortsPackage_Shucai', -- 疏财
    [4] = 'UniteEffortsPackage_Luli', -- 戮力
}

local SEPARATOR = '|'
local DAMAGE_TAG = 'UniteEffortsPackage_Damage_Count'
local DRAW_TAG = 'UniteEffortsPackage_Draw_Count'
local USE_TAG = 'UniteEffortsPackage_Play_Suit'
local DISCARD_TAG = 'UniteEffortsPackage_Discard_Suit'

-- 发动时 Flag，避免回合结束后清除记录 Tag
local INVOKING_MARK = 'LuaUniteEffortsSkillInvoked'

-- 获取角色对应协力 tagName 的 table
local function getUniteEffortsStringTable(player, tagName)
    local tag = player:getTag(tagName)
    if tag then
        local str = tag:toString()
        return str:split(SEPARATOR)
    end
    return {}
end

local function setUniteEffortsStringTable(player, tagName, strTable)
    player:setTag(tagName, sgs.QVariant(table.concat(strTable, SEPARATOR)))
end

-- 增加 tag 对应 Int 值
local function increaseTagCount(player, tagName, count)
    count = count or 1
    local tag = player:getTag(tagName)
    local curr = 0
    if tag then
        curr = player:getTag(tagName):toInt()
    end
    player:setTag(tagName, sgs.QVariant(curr + count))
end

-- 询问协力选项
local function askForUniteEffortsChoice(player, skillName, to, ignoreChosen)
    local room = player:getRoom()
    skillName = skillName or ''
    local choices = {}
    if ignoreChosen then
        choices = UNITE_EFFORTS_CHOICES
    else
        for _, choice in ipairs(UNITE_EFFORTS_CHOICES) do
            if to:getMark(choice) == 0 then
                table.insert(choices, choice)
            end
        end
    end
    return room:askForChoice(player, skillName, table.concat(choices, '+'))
end

-- 对外暴露接口: 是否可以发动协力
function canBeAskedForUniteEfforts(player, ignoreChosen)
    if ignoreChosen then
        return true
    end
    for _, choice in ipairs(UNITE_EFFORTS_CHOICES) do
        if player:getMark(choice) == 0 then
            return true
        end
    end
    return false
end

-- 获取备份 Tag 名称
local function getBackupTagName(name)
    return name .. '_Backup'
end

-- 启动备份
local function setUpBackupTag(player)
    local discardData = getUniteEffortsStringTable(player, DISCARD_TAG)
    local useData = getUniteEffortsStringTable(player, USE_TAG)
    setUniteEffortsStringTable(player, getBackupTagName(DISCARD_TAG), discardData)
    setUniteEffortsStringTable(player, getBackupTagName(USE_TAG), useData)

    local drawCount = player:getTag(DRAW_TAG):toInt()
    local damageCount = player:getTag(DAMAGE_TAG):toInt()
    player:setTag(getBackupTagName(DRAW_TAG), sgs.QVariant(drawCount))
    player:setTag(getBackupTagName(DAMAGE_TAG), sgs.QVariant(damageCount))
end

-- 本回合记录备份
local function prepareUniteEfforts(player)
    setUpBackupTag(player)
    player:getRoom():addPlayerMark(player, INVOKING_MARK)
end

-- 询问协力，暴露的外部接口
function askForUniteEfforts(from, to, skillName, isFromChoose, ignoreChosen)
    -- 在此之前需要启动备份当前回合记录
    prepareUniteEfforts(from)
    local room = from:getRoom()
    local chooser = isFromChoose and from or to
    local choice = askForUniteEffortsChoice(chooser, skillName, to, ignoreChosen)
    local msgType = isFromChoose and '#UniteEfforts-Choose' or '#UniteEfforts-Self-Choose'
    rinsan.sendLogMessage(room, msgType, {
        ['from'] = from,
        ['to'] = to,
        ['arg'] = choice,
        ['arg2'] = ':' .. choice,
    })
    -- 标记协力类型
    room:addPlayerMark(to, choice)
    -- 标记协力发起者
    -- 标记规则：协力选项-协助者-发起者-技能名称
    local mark = string.format('%s-%s-%s-%s', choice, to:objectName(), from:objectName(), skillName)
    room:addPlayerMark(to, mark)
end

-- 清除所有记录值
local function clearAllUniteEffortsTags(player)
    player:removeTag(DISCARD_TAG)
    player:removeTag(USE_TAG)
    player:removeTag(DRAW_TAG)
    player:removeTag(DAMAGE_TAG)
end

-- 更新 Table
local function updateTableTag(player, tagName)
    local tagData = player:getTag(getBackupTagName(tagName))
    if tagData then
        local tagTable = getUniteEffortsStringTable(player, tagName)
        local backupTable = getUniteEffortsStringTable(player, getBackupTagName(tagName))
        for _, suit in ipairs(backupTable) do
            table.removeOne(tagTable, suit)
        end
        setUniteEffortsStringTable(player, tagName, tagTable)
        player:removeTag(getBackupTagName(tagName))
    end
end

-- 更新记录数
local function updateIntTag(player, tagName)
    local tagData = player:getTag(getBackupTagName(tagName))
    if tagData then
        local backupCount = tagData:toInt()
        local currCount = player:getTag(tagName):toInt()
        player:setTag(tagName, sgs.QVariant(math.max(0, currCount - backupCount)))
    end
end

-- 更新现有记录（移除本回合之前的）
local function removeBackupTagRecord(player)
    updateTableTag(player, DISCARD_TAG)
    updateTableTag(player, USE_TAG)
    updateIntTag(player, DRAW_TAG)
    updateIntTag(player, DAMAGE_TAG)
end

-- 协力检查函数
local UNITE_EFFORTS_CHECK_FUNCTIONS = {
    ['UniteEffortsPackage_Tongchou'] = function(invoker, collaborator)
        -- 同仇: 你与其造成的伤害值之和不小于 4
        local invokerDamageCount = invoker:getTag(DAMAGE_TAG):toInt()
        local collaboratorDamageCount = collaborator:getTag(DAMAGE_TAG):toInt()
        local result = invokerDamageCount + collaboratorDamageCount
        return result >= 4
    end,
    ['UniteEffortsPackage_Bingjin'] = function(invoker, collaborator)
        -- 并进: 你与其总计摸过至少 8 张牌
        local invokerDamageCount = invoker:getTag(DRAW_TAG):toInt()
        local collaboratorDamageCount = collaborator:getTag(DRAW_TAG):toInt()
        local result = invokerDamageCount + collaboratorDamageCount
        return result >= 8
    end,
    ['UniteEffortsPackage_Shucai'] = function(invoker, collaborator)
        -- 疏财: 你与其弃置的牌中包含 4 种花色
        local invokerDiscard = getUniteEffortsStringTable(invoker, DISCARD_TAG)
        local collaboratorDiscard = getUniteEffortsStringTable(collaborator, DISCARD_TAG)
        local suits = {}
        for _, suit in ipairs(invokerDiscard) do
            if not table.contains(suits, suit) then
                table.insert(suits, suit)
            end
        end
        for _, suit in ipairs(collaboratorDiscard) do
            if not table.contains(suits, suit) then
                table.insert(suits, suit)
            end
        end
        return #suits >= 4
    end,
    ['UniteEffortsPackage_Luli'] = function(invoker, collaborator)
        -- 勠力: 你与其使用或打出的牌中包含 4 种花色
        local invokerUse = getUniteEffortsStringTable(invoker, USE_TAG)
        local collaboratorUse = getUniteEffortsStringTable(collaborator, USE_TAG)
        local suits = {}
        for _, suit in ipairs(invokerUse) do
            if not table.contains(suits, suit) then
                table.insert(suits, suit)
            end
        end
        for _, suit in ipairs(collaboratorUse) do
            if not table.contains(suits, suit) then
                table.insert(suits, suit)
            end
        end
        return #suits >= 4
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

-- 首先获取对应的 Marks
local function getUniteEffortsMarks(player)
    local marks = {}
    for i = 1, #UNITE_EFFORTS_CHOICES, 1 do
        local markPrefix = string.format('%s-%s', UNITE_EFFORTS_CHOICES[i], player:objectName())
        for _, mark in sgs.list(player:getMarkNames()) do
            -- 必须显式 plain
            if string.find(mark, markPrefix, 1, true) and player:getMark(mark) > 0 then
                table.insert(marks, mark)
            end
        end
    end
    return marks
end

-- 基础失败（提示失败消息）
local function UNITE_BASIC_FAILED_FUNC(invoker, collaborator, skillName)
    local room = invoker:getRoom()
    rinsan.sendLogMessage(room, '#UniteEfforts-Failure', {
        ['from'] = invoker,
        ['to'] = collaborator,
        ['arg'] = skillName .. 'UniteEfforts',
    })
end

-- 基础成功（提示成功消息）
local function UNITE_BASIC_BONUS_FUNC(invoker, collaborator, skillName)
    local room = invoker:getRoom()
    rinsan.sendLogMessage(room, '#UniteEfforts-Success', {
        ['from'] = invoker,
        ['to'] = collaborator,
        ['arg'] = skillName .. 'UniteEfforts',
    })
end

-- 协力成功的不同对应
local UNITE_EFFORTS_BONUS_FUNCS = {
    ['LuaXieji'] = function(invoker, collaborator)
        UNITE_BASIC_BONUS_FUNC(invoker, collaborator, 'LuaXieji')
        local room = invoker:getRoom()
        room:askForUseCard(invoker, '@@LuaXieji', '@LuaXieji')
    end,
}

-- 协力即时成功的不同对应
local UNITE_EFFORTS_INSTANT_BONUS_FUNCS = {}

-- 协力失败不同对应
local UNITE_EFFORTS_FAILED_FUNCS = {
    ['LuaXieji'] = UNITE_BASIC_FAILED_FUNC,
}

local function doUniteEfforts(player)
    local room = player:getRoom()

    -- 获取所有涉及到协力的标记
    local marks = getUniteEffortsMarks(player)
    for _, mark in ipairs(marks) do
        local items = mark:split('-')
        local choice = items[1] -- 协力类型
        -- 协力协助者即为 player，无需从 mark 中获取
        local fromName = items[3] -- 协力发起者
        local from = findPlayerByName(room, fromName)
        if not from then
            goto next_mark
        end
        local skillName = items[4] -- 协力技能名称
        local checkFunc = UNITE_EFFORTS_CHECK_FUNCTIONS[choice]
        if not checkFunc then
            goto next_mark
        end
        local success = checkFunc(from, player)
        room:notifySkillInvoked(from, skillName)
        if success then
            local bonusFunc = UNITE_EFFORTS_BONUS_FUNCS[skillName]
            if bonusFunc then
                -- 成功通常更多自定义的情况，不传 skillName 亦可
                bonusFunc(from, player)
            end
        else
            local failFunc = UNITE_EFFORTS_FAILED_FUNCS[skillName]
            if failFunc then
                -- 多传 skillName 参数用于适配基础失败方法
                failFunc(from, player, skillName)
            end
        end
        ::next_mark::
    end
end

-- 即时成功检查接口
local function doUniteEffortsInstantCheck(player)
    local room = player:getRoom()

    -- 获取所有涉及到协力的标记
    local marks = getUniteEffortsMarks(player)
    for _, mark in ipairs(marks) do
        local items = mark:split('-')
        local choice = items[1] -- 协力类型
        -- 协力协助者即为 player，无需从 mark 中获取
        local fromName = items[3] -- 协力发起者
        local from = findPlayerByName(room, fromName)
        if not from then
            goto next_mark
        end
        local skillName = items[4] -- 协力技能名称
        local checkFunc = UNITE_EFFORTS_CHECK_FUNCTIONS[choice]
        if not checkFunc then
            goto next_mark
        end
        local success = checkFunc(from, player)
        if success then
            -- 不在即时成功处进行默认提示，自行在 BONUS_FUNC 中体现，包括对应的标记之类的
            -- PS: 目前只有谋赵云有即时的，考虑在 BONUS_FUNC 中判断是否已成功进行标记
            local bonusFunc = UNITE_EFFORTS_INSTANT_BONUS_FUNCS[skillName]
            if bonusFunc then
                bonusFunc(from, player)
            end
        end
        ::next_mark::
    end
end

-- 使用、打出牌记录
LuaUniteEffortsUseResponseRecord = sgs.CreateTriggerSkill {
    name = 'LuaUniteEffortsUseResponseRecord',
    events = {sgs.CardUsed, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and (not card:isKindOf('SkillCard')) then
            local suitTable = getUniteEffortsStringTable(player, USE_TAG)
            local suit = card:getSuitString()
            table.insert(suitTable, suit)
            setUniteEffortsStringTable(player, USE_TAG, suitTable)
            doUniteEffortsInstantCheck(player)
        end
        return false
    end,
    can_trigger = rinsan.targetAliveTrigger,
}

-- 弃牌记录
LuaUniteEffortsDiscardRecord = sgs.CreateTriggerSkill {
    name = 'LuaUniteEffortsDiscardRecord',
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
        local discardSuitTable = getUniteEffortsStringTable(player, DISCARD_TAG)
        for _, id in sgs.qlist(move.card_ids) do
            local cd = sgs.Sanguosha:getCard(id)
            table.insert(discardSuitTable, cd:getSuitString())
        end
        setUniteEffortsStringTable(player, DISCARD_TAG, discardSuitTable)
        doUniteEffortsInstantCheck(player)
        return false
    end,
    can_trigger = rinsan.targetAliveTrigger,
}

-- 摸牌记录
LuaUniteEffortsDrawRecord = sgs.CreateTriggerSkill {
    name = 'LuaUniteEffortsDrawRecord',
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag('FirstRound'):toBool() and move.to and move.to:objectName() == player:objectName() then
            local x = 0
            for index, id in sgs.qlist(move.card_ids) do
                local owner = room:getCardOwner(id)
                if move.from_places:at(index) == sgs.Player_DrawPile and owner and owner:objectName() == player:objectName() and
                    room:getCardPlace(id) == sgs.Player_PlaceHand then
                    x = x + 1
                end
            end
            if x > 0 then
                increaseTagCount(player, DRAW_TAG, x)
                doUniteEffortsInstantCheck(player)
            end
        end
        return false
    end,
    can_trigger = rinsan.targetAliveTrigger,
}

-- 造成伤害记录
LuaUniteEffortsDamageRecord = sgs.CreateTriggerSkill {
    name = 'LuaUniteEffortsDamageRecord',
    events = {sgs.Damage},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage > 0 then
            increaseTagCount(player, DAMAGE_TAG, damage.damage)
            doUniteEffortsInstantCheck(player)
        end
        return false
    end,
    can_trigger = rinsan.targetAliveTrigger,
}

LuaUniteEffortsCheck = sgs.CreateTriggerSkill {
    name = 'LuaUniteEffortsCheck',
    events = {sgs.EventPhaseChanging},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            doUniteEfforts(player)
            if player:getMark(INVOKING_MARK) > 0 then
                room:setPlayerMark(player, INVOKING_MARK, 0)
                removeBackupTagRecord(player)
            else
                clearAllUniteEffortsTags(player)
            end
            rinsan.clearAllMarksContains(player, 'UniteEffortsPackage')
        end
    end,
    can_trigger = rinsan.targetTrigger,
}

table.insert(hiddenSkills, LuaUniteEffortsUseResponseRecord)
table.insert(hiddenSkills, LuaUniteEffortsDiscardRecord)
table.insert(hiddenSkills, LuaUniteEffortsDrawRecord)
table.insert(hiddenSkills, LuaUniteEffortsDamageRecord)
table.insert(hiddenSkills, LuaUniteEffortsCheck)

rinsan.addHiddenSkills(hiddenSkills)

-- luacheck: pop
