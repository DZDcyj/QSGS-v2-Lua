-- 扩展包 AI
-- Created by DZDcyj at 2021/8/21

-- 灭计弃牌
sgs.ai_skill_discard['LuaMieji'] = function(self, discard_num, min_num, optional, include_equip)
    min_num = min_num or discard_num
    local exchange = self.player:hasFlag('Global_AIDiscardExchanging')
    self:assignKeep(true)

    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local to_discard, temp = {}, {}

    local least = min_num
    if discard_num - min_num > 1 then
        least = discard_num - 1
    end
    for _, card in ipairs(cards) do
        if exchange or not self.player:isJilei(card) and not card:isKindOf('TrickCard') then
            if self:getKeepValue(card) >= 4.1 then
                table.insert(temp, card:getEffectiveId())
            else
                table.insert(to_discard, card:getEffectiveId())
            end
        end
        if (self.player:hasSkill('qinyin') and #to_discard >= least) or #to_discard >= discard_num then
            break
        end
    end
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
            if (self.player:hasSkill('qinyin') and #to_discard >= least) or #to_discard >= discard_num then
                break
            end
        end
    end
    return to_discard
end

-- 节钺选择
sgs.ai_skill_choice['LuaJieyue'] = function(self, choices, data)
    local items = choices:split('+')
    local target = data:toPlayer()
    if self:isFriend(target) then
        return items[2]
    end
    if self.player:getCardCount(true) <= 3 then
        return items[1]
    end
    local count = 0
    for _, card in sgs.qlist(self.player:getHandcards()) do
        count = count + 1
        if self:isValuableCard(card) then
            count = count + 0.5
        end
    end
    local equip_val_table = {2, 2.5, 1, 1.5, 2.2}
    for i = 0, 4, 1 do
        if self.player:getEquip(i) then
            if i == 1 and self:needToThrowArmor() then
                count = count - 1
            else
                count = count + equip_val_table[i + 1]
                if self.player:hasSkills(sgs.lose_equip_skill) then
                    count = count + 0.5
                end
            end
        end
    end
    if count < 4 then
        return items[1]
    end
    return items[2]
end

-- 节钺选择保留的牌
sgs.ai_skill_cardchosen['LuaJieyue'] = function(self, who, flags)
    local cards = self.player:getCards(flags)
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards, true)
    return cards[1]
end

-- 善檄选择交的牌
sgs.ai_skill_discard['LuaShanxi'] = function(self, discard_num, min_num, optional, include_equip)
    -- 诈降
    if not self:isWeak() and self.player:hasSkill('zhaxiang') then
        return {}
    end
    -- 让 SmartAI 处理
    return nil
end

-- 峻刑弃牌
sgs.ai_skill_discard['LuaJunxing'] = function(self, discard_num, min_num, optional, include_equip)
    -- 如果当前背面朝上，则不弃牌
    if not self.player:faceUp() then
        return {}
    end
    -- 如果要弃置的牌大于总牌数，则不弃牌
    if discard_num > self.player:getCardCount(true) then
        return {}
    end
    -- 如果当前状态不好，则直接选择不弃牌
    if self:isWeak() then
        return {}
    end
    local to_discard, temp = {}, {}
    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    -- 遍历手牌和装备区，将价值较低的牌先列入准备弃置的列表
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) then
            local place = self.room:getCardPlace(card:getEffectiveId())
            if place == sgs.Player_PlaceEquip then
                table.insert(temp, card:getEffectiveId())
            elseif self:getKeepValue(card) >= 4.1 then
                table.insert(temp, card:getEffectiveId())
            else
                table.insert(to_discard, card:getEffectiveId())
            end
        end
        -- 待弃牌数量足够，则直接弃牌
        if #to_discard == discard_num then
            return to_discard
        end
    end
    -- 如果先前的列表不够弃置
    if #to_discard < discard_num then
        for _, id in ipairs(temp) do
            table.insert(to_discard, id)
            if #to_discard == discard_num then
                break
            end
        end
    end
    return to_discard
end

-- 是否发动破军
sgs.ai_skill_invoke.LuaPojun = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    return false
end

-- 破军扣的牌数
sgs.ai_skill_choice.LuaPojun = function(self, choices)
    local items = choices:split('+')
    -- 选择扣置最大的牌数
    return items[#items]
end

-- 应援选择目标
sgs.ai_skill_playerchosen['LuaYingyuan'] = function(self, targets)
    self:sort(self.friends)
    for _, friend in ipairs(self.friends) do
        if
            not friend:hasSkill('zishu') and not friend:hasSkill('manjuan') and not friend:hasSkill('LuaZishu') and
                not self:needKongcheng(friend, true)
         then
            return friend
        end
    end
end

-- 是否发动制蛮
sgs.ai_skill_invoke.LuaZhiman = function(self, data)
    local damage = data:toDamage()
    local target = damage.to
    if self:isFriend(target) then
        if damage.damage == 1 and self:getDamagedEffects(target, self.player) then
            return false
        end
        return true
    else
        if self:hasHeavySlashDamage(self.player, damage.card, target) then
            return false
        end
        if self:isWeak(target) then
            return false
        end
        if self:doNotDiscard(target, 'e', true) then
            return false
        end
        if
            self:getDamagedEffects(target, self.player, true) or
                (target:getArmor() and not target:getArmor():isKindOf('SilverLion'))
         then
            return true
        end
        if self:getDangerousCard(target) then
            return true
        end
        if target:getDefensiveHorse() then
            return true
        end
        return false
    end
end

-- 征南选择
sgs.ai_skill_choice['LuaZhengnan'] = function(self, choices)
    local items = choices:split('+')
    if #items == 1 then
        return items[1]
    else
        if table.contains(items, 'LuaDangxian') then
            return 'LuaDangxian'
        end
        if table.contains(items, 'zhiman') then
            return 'LuaZhiman'
        end
        if table.contains(items, 'wusheng') then
            return 'wusheng'
        end
    end
    return items[1]
end
