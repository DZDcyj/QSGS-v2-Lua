-- 马钧装备包
-- Created by DZDcyj at 2023/3/29
module('extensions.MajunEquipCardPackage', package.seeall)
extension = sgs.Package('MajunEquipCardPackage', sgs.Package_CardPack)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 元戎精械弩
yuanrong_crossbow = sgs.CreateWeapon {
    name = 'yuanrong_crossbow',
    class_name = 'crossbow',
    range = 3,
}

for i = 1, 2, 1 do
    local card = yuanrong_crossbow:clone()
    card:setSuit((i % 2 == 0) and sgs.Card_Diamond or sgs.Card_Club)
    card:setNumber(1)
    card:setParent(extension)
end

-- 先天八卦阵
xiantian_eightdiagram = sgs.CreateArmor {
    name = 'xiantian_eightdiagram',
    class_name = 'XiantianEightDiagram',
}

xiantian_eightdiagram_skill = sgs.CreateTriggerSkill {
    name = 'xiantian_eightdiagram',
    events = {sgs.CardAsked},
    global = true,
    priority = -2,
    on_trigger = function(self, event, player, data, room)
        local pattern = data:toStringList()[1]
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local armor_id = player:getArmor():getId()
            room:setCardFlag(armor_id, 'using')
            local judge = rinsan.createJudgeStruct({
                ['pattern'] = '.|spade',
                ['who'] = player,
                ['play_animation'] = true,
                ['reason'] = self:objectName(),
                ['good'] = false,
            })
            room:judge(judge)
            room:setCardFlag(armor_id, '-using')
            if judge:isGood() then
                room:setEmotion(player, 'armor/eight_diagram')
                local jink = sgs.Sanguosha:cloneCard('jink', sgs.Card_NoSuit, 0)
                jink:setSkillName(self:objectName())
                room:provide(jink)
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target:hasArmorEffect(self:objectName())
    end,
}

local skillList = sgs.SkillList()
if not sgs.Sanguosha:getSkill('xiantian_eightdiagram') then
    skillList:append(xiantian_eightdiagram_skill)
end

for i = 1, 2, 1 do
    local card = xiantian_eightdiagram:clone()
    card:setSuit((i % 2 == 0) and sgs.Card_Spade or sgs.Card_Club)
    card:setNumber(2)
    card:setParent(extension)
end

sgs.Sanguosha:addSkills(skillList)
