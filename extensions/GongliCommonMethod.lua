-- 日神杀 共砺 技能通用封装模块
-- Created by DZDcyj at 2025/6/7
module('GongliCommonMethod', package.seeall)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 忽略本文件中未引用 global variable 的警告
-- luacheck: push ignore 131

-- 判断本人是否是对应友武将
local function isYouGeneral(source, youGeneralName)
    return source:getGeneralName() == generalName or source:getGeneral2Name() == generalName
end

-- 总对外接口，是否可以发动共砺
-- source: 发动技能的武将
-- gongli_skill: 共砺技能名称
-- gongli_friend: 共砺友武将名称
-- 返回值：如果可以发动共砺，则返回 true，否则返回 false
function gongliSkillInvokable(source, gongli_skill, gongli_friend)
    -- 如果自身没有共砺技能，那必然不能发动
    if not source:hasSkill(gongli_skill) then
        return false
    end
    -- 如果本人即是友武将，即可发动
    if isYouGeneral(source, gongli_friend) then
        return true
    end
    -- 判断其他的同阵营友武将
    for _, you_general in sgs.qlist(rinsan.getOtherPlayersWithGivenGeneralName(source, gongli_friend)) do
        if rinsan.isSameCamp(source, you_general) then
            return true
        end
    end
    return false
end

-- 共砺支持的模式
local GONGLI_SUPPORT_MODES = {
    ['06_3v3'] = true, -- 3v3 模式
    ['04_1v3'] = true, -- 虎牢关
    ['04_boss'] = true, -- 闯关模式
    ['05_ol'] = true, -- 神武在世
    ['08_defense'] = true, -- 守卫剑阁
}

-- 对外接口，是否为可以发动共砺技能的模式
function checkModeWhetherGongliAvailable(room)
    local mode = room:getMode()
    if GONGLI_SUPPORT_MODES[mode] then
        return true
    end
    -- 如果不是支持模式，则可能是小型场景下的斗地主/绝境之战
    local lord = room:getLord()
    -- 地主拥有 LuaDizhu 标记
    local isLandLordMode = lord and lord:getMark('LuaDizhu') > 0
    local isImpassableMode = lord and lord:getMark('LuaBoss') > 0
    return isLandLordMode or isImpassableMode
end

-- luacheck: pop
