-- 群友包 AI
-- Created by DZDcyj at 2021/9/10

-- 晒卡弃牌/掉血
sgs.ai_skill_discard['LuaShaika'] = function(self, discard_num, min_num, optional, include_equip)
    -- 如果要弃置的牌大于总牌数，则不弃牌
    if discard_num > self.player:getCardCount(true) then
        return {}
    end
    -- 如果要弃置的牌数量大于总牌数的二分之一，并且当前状态良好，则直接选择不弃牌
    if discard_num > self.player:getCardCount(true) / 2 and not self.player:isWeak() then
        return {}
    end
    local room = self.player:getRoom()
    -- 如果当前角色没有绝情
    if not room:getCurrent():hasSkill('jueqing') then
        -- 如果可以卖血
        if
            self:hasSkills(sgs.masochism_skill, self.player) and
                (self.player:getHp() > 1 or self:getCardsNum('Peach') > 0 or self:getCardsNum('Analeptic') > 0)
         then
            return {}
        end
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

-- 搜图送牌
local LuaSoutu_skill = {}
LuaSoutu_skill.name = 'LuaSoutuVS'

table.insert(sgs.ai_skills, LuaSoutu_skill)

LuaSoutu_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:hasUsed('#LuaSoutuCard') then
        return sgs.Card_Parse('#LuaSoutuCard:.:')
    end
end

sgs.ai_skill_use_func['#LuaSoutuCard'] = function(card, use, self)
    local target = nil
    if self.player:isKongcheng() then
        return
    end
    for _, friend in ipairs(self.friends_noself) do
        if friend:hasSkill('LuaSoutu') then
            target = friend
            break
        end
    end
    if target then
        local cards = self.player:getHandcards()
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards, true)
        local card_str = string.format('#LuaSoutuCard:%s:', cards[1]:getEffectiveId())
        local acard = sgs.Card_Parse(card_str)
        assert(acard)
        use.card = acard
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_use_value['LuaSoutuCard'] = 100
sgs.ai_use_priority['LuaSoutuCard'] = 10

-- 谋害
sgs.ai_skill_playerchosen.LuaMouhai = function(self, targetlist)
    local targets = sgs.QList2Table(targetlist)
    self:sort(targets)
    local friends, enemies = {}, {}
    for _, target in ipairs(targets) do
        if not self:cantbeHurt(target, self.player) and self:damageIsEffective(target, nil, self.player) then
            if self:isEnemy(target) then
                table.insert(enemies, target)
            elseif self:isFriend(target) then
                table.insert(friends, target)
            end
        end
    end
    for _, enemy in ipairs(enemies) do
        if not self:getDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy, self.player) then
            return enemy
        end
    end
    for _, friend in ipairs(friends) do
        if self:getDamagedEffects(friend, self.player) and self:needToLoseHp(friend, self.player) then
            return friend
        end
    end
    return nil
end

-- 绝杀
sgs.ai_skill_invoke.LuaJuesha = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    return false
end

sgs.ai_skill_playerchosen.LuaChuanyi = function(self, targetlist)
    -- AI 永不发动传艺
    return nil
end

-- 引玉给牌
sgs.ai_skill_cardask['@LuaYinyu-show'] = function(self, data)
    local target = data:toPlayer()
    if target:objectName() == self.player:objectName() then
        local cards = self.player:getCards('h')
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards, true)
        return cards[1]
    end
    if not self:isFriend(target) then
        return '.'
    end
    if self:isWeak() then
        return '.'
    end
    if self.player:getHandcardNum() <= math.min(self.player:getMaxCards(), 2) then
        return '.'
    end
    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    return cards[1]
end

-- 引玉
sgs.ai_skill_invoke.LuaYinyu = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return true
    end
    return false
end

-- 抛砖
sgs.ai_skill_invoke.LuaPaozhuan = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return false
    end
    return true
end

-- 榨汁
sgs.ai_skill_invoke.LuaZhazhi = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return false
    end
    if
        self:getCardsNum('Slash', target) < 1 and self.player:getHp() > 1 and not self:canHit(self.player, target) and
            not (target:hasWeapon('double_sword') and self.player:getGender() ~= target:getGender())
     then
        return true
    end
    if
        sgs.card_lack[target:objectName()]['Slash'] == 1 or self:needLeiji(self.player, target) or
            self:getDamagedEffects(self.player, target, true) or
            self:needToLoseHp(self.player, target, true)
     then
        return true
    end
    if self:getOverflow() and self:getCardsNum('Jink') > 1 then
        return true
    end
    if target:isWeak() then
        return true
    end
    return not self:isWeak()
end
