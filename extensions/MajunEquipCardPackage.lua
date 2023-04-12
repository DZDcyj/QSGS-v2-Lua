-- 马钧装备包
-- Created by DZDcyj at 2023/3/29
module('extensions.MajunEquipCardPackage', package.seeall)
extension = sgs.Package('MajunEquipCardPackage', sgs.Package_CardPack)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local skillList = sgs.SkillList()

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
        if pattern ~= 'jink' then
            return false
        end
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
            room:setEmotion(player, 'armor/eight_diagram')
            room:judge(judge)
            room:setCardFlag(armor_id, '-using')
            if judge:isGood() then
                local jink = sgs.Sanguosha:cloneCard('jink', sgs.Card_NoSuit, 0)
                jink:setSkillName(self:objectName())
                room:provide(jink)
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasArmorEffect(self:objectName())
    end,
}

if not sgs.Sanguosha:getSkill('xiantian_eightdiagram') then
    skillList:append(xiantian_eightdiagram_skill)
end

for i = 1, 2, 1 do
    local card = xiantian_eightdiagram:clone()
    card:setSuit((i % 2 == 0) and sgs.Card_Spade or sgs.Card_Club)
    card:setNumber(2)
    card:setParent(extension)
end

-- 仁王金刚盾
jingang_renwang_shield = sgs.CreateArmor {
    name = 'jingang_renwang_shield',
    class_name = 'renwang_shield',
}

local jingang_renwang = jingang_renwang_shield:clone()
jingang_renwang:setSuit(sgs.Card_Club)
jingang_renwang:setNumber(2)
jingang_renwang:setParent(extension)

jingang_renwang_shield_skill = sgs.CreateTriggerSkill {
    name = 'jingang_renwang_shield',
    events = {sgs.SlashEffected},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        if effect.slash:isBlack() or effect.slash:getSuit() == sgs.Card_Heart then
            rinsan.sendLogMessage(room, '#ArmorNullify', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['arg2'] = effect.slash:objectName(),
            })
            room:setEmotion(player, 'armor/renwang_shield')
            effect.to:setFlags('Global_NonSkillNullify')
            return true
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasArmorEffect(self:objectName())
    end,
}

if not sgs.Sanguosha:getSkill('jingang_renwang_shield') then
    skillList:append(jingang_renwang_shield_skill)
end

-- 照月狮子盔
zhaoyue_silver_lion = sgs.CreateArmor {
    name = 'zhaoyue_silver_lion',
    class_name = 'silver_lion',
    on_uninstall = function(self, player)
        if player:isAlive() and player:hasArmorEffect(self:objectName()) then
            local room = player:getRoom()
            room:setEmotion(player, 'armor/silver_lion')
            rinsan.recover(player)
            player:drawCards(2, self:objectName())
        end
    end,
}

local zhaoyue = zhaoyue_silver_lion:clone()
zhaoyue:setSuit(sgs.Card_Club)
zhaoyue:setNumber(1)
zhaoyue:setParent(extension)

zhaoyue_silver_lion_skill = sgs.CreateTriggerSkill {
    name = 'zhaoyue_silver_lion',
    events = {sgs.DamageInflicted},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage > 1 then
            room:setEmotion(player, 'armor/silver_lion')
            rinsan.sendLogMessage(room, '#SilverLion', {
                ['from'] = player,
                ['arg'] = damage.damage,
                ['arg2'] = self:objectName(),
            })
            damage.damage = 1
            data:setValue(damage)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasArmorEffect(self:objectName())
    end,
}

if not sgs.Sanguosha:getSkill('zhaoyue_silver_lion') then
    skillList:append(zhaoyue_silver_lion_skill)
end

-- 桐油百韧甲
tongyou_vine = sgs.CreateArmor {
    name = 'tongyou_vine',
    class_name = 'TongyouVine',
}

tongyou_vine_skill = sgs.CreateTriggerSkill {
    name = 'tongyou_vine',
    events = {sgs.DamageInflicted, sgs.SlashEffected, sgs.CardEffected, sgs.ChainStateChange},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire then
                room:setEmotion(player, 'armor/vineburn')
                rinsan.sendLogMessage(room, '#TongyouVineDamage', {
                    ['from'] = player,
                    ['arg'] = damage.damage,
                    ['arg2'] = damage.damage + 1,
                })
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.ChainStateChange then
            if not player:isChained() then
                room:setEmotion(player, 'armor/vine')
                rinsan.sendLogMessage(room, '#TongyouVineChain', {
                    ['from'] = player,
                    ['arg'] = self:objectName(),
                })
                return true
            end
        else
            local effect, card
            if event == sgs.CardEffected then
                effect = data:toCardEffect()
                card = effect.card
                if not card:isKindOf('AOE') then
                    return false
                end
            else
                effect = data:toSlashEffect()
                card = effect.slash
                if effect.nature ~= sgs.DamageStruct_Normal then
                    return false
                end
            end
            room:setEmotion(player, 'armor/vine')
            rinsan.sendLogMessage(room, '#ArmorNullify', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['arg2'] = card:objectName(),
            })
            effect.to:setFlags('Global_NonSkillNullify')
            return true
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasArmorEffect(self:objectName())
    end,
}

for i = 1, 2, 1 do
    local card = tongyou_vine:clone()
    card:setSuit((i % 2 == 0) and sgs.Card_Spade or sgs.Card_Club)
    card:setNumber(2)
    card:setParent(extension)
end

if not sgs.Sanguosha:getSkill('tongyou_vine') then
    skillList:append(tongyou_vine_skill)
end

sgs.Sanguosha:addSkills(skillList)
