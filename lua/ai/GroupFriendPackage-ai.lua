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
        if self:hasSkills(sgs.masochism_skill, self.player) and
            (self.player:getHp() > 1 or self:getCardsNum('Peach') > 0 or self:getCardsNum('Analeptic') > 0) then
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
    self:sort(targets, 'defense')
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

-- 传艺
sgs.ai_skill_choice['LuaChuanyi'] = function(self, choices)
    -- 选最后一个：本局游戏不再发动
    local items = choices:split('+')
    return items[#items]
end
sgs.ai_skill_playerchosen.LuaChuanyi = function(self, targetlist)
    -- AI 不指定目标
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

-- 榨汁伤害判断
LuaZhazhiDamageEffect = function(self, to, nature, from, damageValue)
    local count = damageValue or 1
    for _, mark in sgs.list(from:getMarkNames()) do
        if string.find(mark, 'LuaZhazhiDebuff') then
            count = count - from:getMark(mark)
        end
    end
    return count > 0
end

-- 不知道为什么不能直接定义 sgs.ai_damage_effect 对应的函数，只能如这般插入
table.insert(sgs.ai_damage_effect, LuaZhazhiDamageEffect)

-- 白嫖
sgs.ai_skill_playerchosen.LuaBaipiao = function(self, targetlist)
    local targets = sgs.QList2Table(targetlist)
    self:sort(targets)
    local friends, enemies = {}, {}
    for _, target in ipairs(targets) do
        -- 如果队友或自己头上有兵/乐，则拿走
        if self:isFriend(target) and (target:containsTrick('indulgence') or target:containsTrick('supply_shortage')) then
            table.insert(friends, target)
        end

        -- 如果敌人有牌，则考虑纳入
        if not self:isFriend(target) and not target:isAllNude() then
            table.insert(enemies, target)
        end
    end
    if #friends > 0 then
        self:sort(friends, 'defense')
        return friends[1]
    end
    if #enemies > 0 then
        self:sort(enemies, 'defense')
        return enemies[1]
    end
    if not self.player:isAllNude() then
        return self.player
    end
    return nil
end

-- 缴械
sgs.ai_skill_invoke.LuaJiaoxie = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    return false
end

-- 情欲
sgs.ai_skill_choice['LuaQingyu'] = function(self, choices)
    -- 选项为 LuaQingyuChoice1 LuaQingyuChoice2 cancel
    -- 对应 摸牌、加上限、取消
    local items = choices:split('+')
    -- 手牌数少就摸牌
    if table.contains(items, 'LuaQingyuChoice1') then
        if self.player:getHandcardNum() < self.player:getMaxCards() then
            return 'LuaQingyuChoice1'
        end
    end
    return 'LuaQingyuChoice2'
end

-- 影噬
sgs.ai_skill_choice['LuaYingshi'] = function(self, choices)
    -- AI 只选择加血上限
    -- 选项1、2分别为加上限/扣血上限获得技能
    return choices:split('+')[1]
end

-- 智屑
-- 将锦囊牌当作连环使用
local LuaZhixie_skill = {}
LuaZhixie_skill.name = 'LuaZhixie'
table.insert(sgs.ai_skills, LuaZhixie_skill)
LuaZhixie_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)

    local card
    self:sortByUseValue(cards, true)
    local slash = self:getCard('FireSlash') or self:getCard('ThunderSlash') or self:getCard('Slash')
    if slash then
        local dummy_use = {
            isDummy = true,
        }
        self:useBasicCard(slash, dummy_use)
        if not dummy_use.card then
            slash = nil
        end
    end

    for _, acard in ipairs(cards) do
        if acard:getTypeId() == sgs.Card_TypeTrick then
            local shouldUse = true
            if self:getUseValue(acard) > sgs.ai_use_value.IronChain then
                local dummy_use = {
                    isDummy = true,
                }
                self:useTrickCard(acard, dummy_use)
                if dummy_use.card then
                    shouldUse = false
                end
            end
            if shouldUse and (not slash or slash:getEffectiveId() ~= acard:getEffectiveId()) then
                card = acard
                break
            end
        end
    end

    if not card then
        return nil
    end

    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    local card_str = ('iron_chain:LuaZhixie[club:%s]=%d'):format(number, card_id)
    local skillcard = sgs.Card_Parse(card_str)
    assert(skillcard)
    return skillcard
end

sgs.ai_cardneed.LuaZhixie = function(to, card)
    return card:getTypeId() == sgs.Card_TypeTrick and to:getHandcardNum() <= 2
end

-- 智屑
-- 回合结束选择角色横置
sgs.ai_skill_use['@@LuaZhixie'] = function(self, prompt, method)
    local x = self.player:getMark('LuaZhixie')
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isChained() then
            table.insert(targets, enemy:objectName())
        end
        if #targets >= x then
            break
        end
    end
    if #targets > 0 then
        return '#LuaZhixieCard:.:->' .. table.concat(targets, '+')
    end
    return '.'
end

-- 机械减伤害
LuaJixieDamageEffect = function(self, to, nature, from, damageValue)
    local count = damageValue or 1
    if to:hasSkill('LuaJixie') and nature == sgs.DamageStruct_Thunder then
        return count > 1
    end
    return true
end

table.insert(sgs.ai_damage_effect, LuaJixieDamageEffect)

sgs.ai_skill_invoke.LuaChengsheng = true

-- 砂糖
-- 支援敌友判断
sgs.ai_card_intention.LuaZhiyuanCard = function(self, card, from, tos)
    for _, to in ipairs(tos) do
        sgs.updateIntention(from, to, -50)
    end
end
