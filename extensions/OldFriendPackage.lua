-- 袖里乾坤老友季 武将包
-- Created by DZDcyj at 2025/6/8
module('extensions.OldFriendPackage', package.seeall)
extension = sgs.Package('OldFriendPackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')
local gongli = require('extensions.GongliCommonMethod')

-- 隐藏技能添加
local hiddenSkills = {}

-- General 定义如下
-- sgs.General(package, name, kingdom, max_hp, male, hidden, never_shown, start_hp)
-- 分别代表：扩展包、武将名、国籍、最大体力值、是否男性、是否在选将框中隐藏、是否完全不可见、初始血量

-- 友徐庶
YouXushu = sgs.General(extension, 'YouXushu', 'qun', 3, true, true)

-- 获取/失去启诲标记提示
local function sendQihuiMarkChangeLog(youxushu, change_num)
    local log_type = change_num > 0 and '#GainQihuiMark' or '#LoseQihuiMark'
    change_num = math.abs(change_num)
    rinsan.sendLogMessage(youxushu:getRoom(), log_type, {
        ['from'] = youxushu,
        ['arg'] = change_num,
        ['arg2'] = 'LuaQihui',
    })
end

-- 失去对应类型的启诲标记
local function loseQihuiMark(youxushu, qihui_type)
    local room = youxushu:getRoom()
    room:removePlayerMark(youxushu, '@LuaQihui-' .. qihui_type)
end

-- 获得对应类型的启诲标记
local function gainQihuiMark(youxushu, qihui_type)
    local room = youxushu:getRoom()
    room:addPlayerMark(youxushu, '@LuaQihui-' .. qihui_type)
    sendQihuiMarkChangeLog(youxushu, 1)
end

-- 获取启诲标记数
local function getQihuiMarkNum(youxushu)
    local card_types = {'basic', 'trick', 'equip'}
    local mark_num = 0
    for _, card_type in ipairs(card_types) do
        local mark = youxushu:getMark('@LuaQihui-' .. card_type)
        mark_num = mark_num + mark
    end
    return mark_num
end

-- 失去对应数量的启诲标记
local function loseMultiQihuiMark(youxushu, lose_num)
    local room = youxushu:getRoom()
    local card_types = {'basic', 'trick', 'equip'}
    local marks = {}
    for _, card_type in ipairs(card_types) do
        local mark = youxushu:getMark('@LuaQihui-' .. card_type)
        if mark > 0 then
            table.insert(marks, card_type)
        end
    end
    if lose_num > #marks then
        return
    end
    if lose_num == #marks then
        for _, card_type in ipairs(card_types) do
            loseQihuiMark(youxushu, card_type)
        end
        sendQihuiMarkChangeLog(youxushu, -lose_num)
        return
    end
    for _ = 1, lose_num, 1 do
        local choice = room:askForChoice(youxushu, 'LuaQihui', table.concat(marks, '+'))
        table.removeAll(marks, choice)
        loseQihuiMark(youxushu, choice)
    end
    sendQihuiMarkChangeLog(youxushu, -lose_num)
end

LuaXiaxing = sgs.CreateTriggerSkill {
    name = 'LuaXiaxing',
    events = {sgs.GameStart, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            local xuanjian
            for i = 0, 10000 do
                local cd = sgs.Sanguosha:getEngineCard(i)
                if cd == nil then
                    break
                end
                if cd:objectName() == 'xuanjian_sword' then
                    xuanjian = cd
                    break
                end
            end
            if not xuanjian then
                return false
            end
            -- 获取【玄剑】
            local xuanjian_id = xuanjian:getEffectiveId()
            local newIds = sgs.IntList()
            local drawPile = room:getDrawPile()
            newIds:append(xuanjian_id)

            -- 若牌堆、弃牌堆、场上均不存在【玄剑】
            -- 新增判断私家牌堆
            local xuanjian_exists = false
            for _, id in sgs.qlist(drawPile) do
                local cd = sgs.Sanguosha:getCard(id)
                if cd:objectName() == 'xuanjian_sword' then
                    xuanjian_exists = true
                    break
                end
            end
            for _, id in sgs.qlist(room:getDiscardPile()) do
                local cd = sgs.Sanguosha:getCard(id)
                if cd:objectName() == 'xuanjian_sword' then
                    xuanjian_exists = true
                    break
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                for _, cd in sgs.qlist(p:getCards('hej')) do
                    if cd:objectName() == 'xuanjian_sword' then
                        xuanjian_exists = true
                        break
                    end
                end

                -- 检查玩家的私家牌堆
                for _, pile in sgs.list(p:getPileNames()) do
                    for _, cid in sgs.qlist(p:getPile(pile)) do
                        local cd = sgs.Sanguosha:getCard(cid)
                        if cd:objectName() == 'xuanjian_sword' then
                            xuanjian_exists = true
                            break
                        end
                    end
                    if xuanjian_exists then
                        break
                    end
                end
            end
            -- 则将【玄剑】添加至牌堆中
            if not xuanjian_exists then
                drawPile:prepend(xuanjian_id)
                room:setCardMapping(xuanjian_id, nil, sgs.Player_DrawPile)
            end
            room:doBroadcastNotify(rinsan.FixedCommandType['S_COMMAND_UPDATE_PILE'], tostring(drawPile:length()))
            room:obtainCard(player, xuanjian, false)
            -- 使用【玄剑】
            room:useCard(sgs.CardUseStruct(xuanjian, player, player))
        end
        local move = data:toMoveOneTime()
        local xuanjian
        if move.to_place == sgs.Player_DiscardPile then
            for _, id in sgs.qlist(move.card_ids) do
                local cd = sgs.Sanguosha:getCard(id)
                if cd:objectName() == 'xuanjian_sword' then
                    xuanjian = cd
                    break
                end
            end
        end
        if not xuanjian or getQihuiMarkNum(player) < 2 then
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            loseMultiQihuiMark(player, 2)
            player:obtainCard(xuanjian, false)
        end
        return false
    end,
}

LuaQihui = sgs.CreateTriggerSkill {
    name = 'LuaQihui',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use_card
        if event == sgs.CardUsed then
            use_card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                use_card = data:toCardResponse().m_card
            end
        end
        if (not use_card) or (use_card:isKindOf('SkillCard')) then
            return false
        end
        if player:getMark('LuaQihui-NoLimit') > 0 then
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                use.m_addHistory = false
                data:setValue(use)
            end
        end
        room:setPlayerMark(player, 'LuaQihui-NoLimit', 0)
        local type = use_card:getType()
        if player:getMark('@LuaQihui-' .. type) > 0 then
            return false
        end
        gainQihuiMark(player, type)
        if getQihuiMarkNum(player) == 3 then
            room:notifySkillInvoked(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName())
            loseMultiQihuiMark(player, 2)
            local qihui_choices = {'LuaQihui-choice1', 'LuaQihui-choice2', 'LuaQihui-choice3'}
            local qihui_choice = room:askForChoice(player, self:objectName(), table.concat(qihui_choices, '+'))
            if qihui_choice == qihui_choices[1] then
                rinsan.recover(player, 1)
                room:filterCards(player, player:getCards('he'), true)
                local card = room:askForCard(player, '.', 'LuaQihui-Recast', data, sgs.Card_MethodRecast)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), card:objectName(), '')
                if card then
                    room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, reason)
                    rinsan.sendLogMessage(room, '#UseCard_Recase', {
                        ['from'] = player,
                        ['card_str'] = card:getEffectiveId(),
                    })
                    room:broadcastSkillInvoke('@recast')
                    player:drawCards(1, 'recast')
                end
            elseif qihui_choice == qihui_choices[2] then
                player:drawCards(2, self:objectName())
            elseif qihui_choice == qihui_choices[3] then
                room:addPlayerMark(player, 'LuaQihui-NoLimit')
            end
        end
        return false
    end,
}

LuaQihuiTargetMod = sgs.CreateTargetModSkill {
    name = '#LuaQihuiTargetMod',
    frequency = sgs.Skill_Compulsory,
    pattern = '.',
    residue_func = function(self, from, card)
        if from:getMark('LuaQihui-NoLimit') > 0 then
            return 1000
        end
        return 0
    end,
}

LuaYouXushu_Gongli = sgs.CreateTriggerSkill {
    name = 'LuaYouXushu_Gongli',
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                card = data:toCardResponse().m_card
            end
        end
        if card and card:getSkillName() == 'xuanjian_sword' then
            local youzhugeliang = gongli.gongliSkillInvokable(player, self:objectName(), 'YouZhugeliang')
            local youpangtong = gongli.gongliSkillInvokable(player, self:objectName(), 'YouPangtong')
            if youzhugeliang or youpangtong then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
            end
        end
        return false
    end,
}

table.insert(hiddenSkills, LuaQihuiTargetMod)

YouXushu:addSkill(LuaXiaxing)
YouXushu:addSkill(LuaQihui)
YouXushu:addSkill(LuaYouXushu_Gongli)

rinsan.addHiddenSkills(hiddenSkills)

