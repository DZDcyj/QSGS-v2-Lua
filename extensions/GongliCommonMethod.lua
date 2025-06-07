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

-- luacheck: pop
