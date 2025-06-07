-- 袖里乾坤老友季 卡牌包
-- Created by DZDcyj at 2025/6/7
module('extensions.OldFriendCardPackage', package.seeall)
extension = sgs.Package('OldFriendCardPackage', sgs.Package_CardPack)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local skillList = sgs.SkillList()

-- 玄剑
xuanjian_sword = sgs.CreateWeapon {
    name = 'xuanjian_sword',
    class_name = 'XuanjianSword',
    range = 3,
    suit = sgs.Card_Spade,
    number = 9,
}

xuanjian_sword:setParent(extension)

-- 共砺接口
local function gongliZhugeAvailable(youxushu)
    -- TODO：后续友诸葛亮上线时增加判断
    return false
end

-- 玄剑选牌
local function filterXuanjianCards(source, selected, to_select)
    if gongliZhugeAvailable(source) then
        -- 共砺生效：一张牌即可
        return #selected < 1 and not to_select:isEquipped()
    end
    -- 需要的花色数
    local requiredSuitCount = 1
    -- 判断已选择卡牌是否满足花色数
    local xuanjian_suits = {}
    for _, cd in ipairs(selected) do
        local suit = cd:getSuitString()
        if not table.contains(xuanjian_suits, suit) then
            table.insert(xuanjian_suits, suit)
        end
    end

    -- 是否是装备牌、能否弃置
    if to_select:isEquipped() or source:isJilei(to_select) then
        return false
    end

    -- 要么是已选中花色，要么是不够花色
    return table.contains(xuanjian_suits, to_select:getSuitString()) or #xuanjian_suits < requiredSuitCount
end

-- 判断玄剑选牌合法性
local function checkXuanjianCards(source, cards)
    if gongliZhugeAvailable(source) then
        -- 共砺生效：一张牌即可
        return #cards == 1 and not cards[1]:isEquipped()
    end

    -- 需要的花色数
    local requiredSuitCount = 1

    -- 判断已选择卡牌是否满足花色数
    local xuanjian_suits = {}
    for _, cd in ipairs(cards) do
        local suit = cd:getSuitString()
        if not table.contains(xuanjian_suits, suit) then
            table.insert(xuanjian_suits, suit)
        end
    end
    if #xuanjian_suits < requiredSuitCount then
        return false
    end

    local ids = {}
    for _, cd in ipairs(cards) do
        table.insert(ids, cd:getEffectiveId())
    end

    -- 判断所有手牌是否已被选中
    for _, cd in sgs.qlist(source:getHandcards()) do
        local suit = cd:getSuitString()
        if table.contains(xuanjian_suits, suit) and not table.contains(ids, cd:getEffectiveId()) then
            return false
        end
    end

    return true
end

xuanjian_sword_skill = sgs.CreateViewAsSkill {
    name = 'xuanjian_sword',
    n = 999,
    view_filter = function(self, selected, to_select)
        return filterXuanjianCards(sgs.Self, selected, to_select)
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        if not checkXuanjianCards(sgs.Self, cards) then
            return nil
        end
        local card = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        for _, cd in ipairs(cards) do
            card:addSubcard(cd)
        end
        card:setSkillName(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getMark('Equips_Nullified_to_Yourself') == 0
    end,
}

if not sgs.Sanguosha:getSkill('xuanjian_sword') then
    skillList:append(xuanjian_sword_skill)
end

sgs.Sanguosha:addSkills(skillList)
