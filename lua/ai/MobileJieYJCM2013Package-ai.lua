-- 手杀-界一将成名2013 AI
-- Created by DZDcyj at 2023/9/30
-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 界朱然
-- 胆守
sgs.ai_skill_discard['LuaDanshou'] = function(self, discard_num, min_num, optional, include_equip)
    local current = self.room:getCurrent()
    -- 不对队友发动胆守伤害
    if self:isFriend(current) then
        return {}
    end

    -- 如果啥都没有，则不丢牌
    if self.player:isNude() then
        return {}
    end

    -- 如果手牌数较少，且较弱
    if self:isWeak() and self.player:getHandcardNum() < 3 then
        return {}
    end

    -- 如果造成不了伤害也别丢牌了
    if not self:damageIsEffective(current, sgs.DamageStruct_Normal, self.player) then
        return {}
    end

    -- 如果需要空城，且正好全弃牌
    if self.player:getCards('he'):length() >= discard_num and self.player:getHandcardNum() <= discard_num and
        self:needKongcheng(self.player, true) then
        local to_discard = {}
        local cards = sgs.QList2Table(self.player:getCards('he'))
        self:sortByKeepValue(cards)
        for _, cd in ipairs(cards) do
            table.insert(to_discard, cd:getId())
        end
        return to_discard
    end

    -- 弃牌数超过 2/3 牌数量，不弃牌
    if self.player:getCards('he'):length() * 2 / 3 < discard_num then
        return {}
    end

    local to_discard = {}
    local cards = sgs.QList2Table(self.player:getCards('he'))
    self:sortByKeepValue(cards)
    for i = 1, discard_num, 1 do
        table.insert(to_discard, cards[i]:getId())
    end
    return to_discard
end

-- 界满宠
-- 峻刑发动
sgs.ai_use_value['LuaJunxing'] = 10
sgs.ai_use_priority['LuaJunxing'] = 1.2

local LuaJunxing_skill = {}
LuaJunxing_skill.name = 'LuaJunxing'

table.insert(sgs.ai_skills, LuaJunxing_skill)

-- 是否发动过“峻刑”，如果没有，进行选择
LuaJunxing_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:isKongcheng() and not self.player:hasUsed('#LuaJunxing') then
        return sgs.Card_Parse('#LuaJunxing:.:')
    end
end

sgs.ai_skill_use_func['#LuaJunxing'] = function(_card, use, self)
    -- 简单处理，丢最不值钱的一张手牌
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    -- 如果有队友翻面，翻队友
    for _, friend in ipairs(self.friends_noself) do
        if not friend:faceUp() then
            use.card = sgs.Card_Parse('#LuaJunxing:' .. cards[1]:getEffectiveId() .. ':')
            if use.to then
                use.to:append(friend)
            end
            return
        end
    end
    -- 选敌人防御最低且未被翻面的
    self:sort(self.enemies, 'defense')
    for _, enemy in ipairs(self.enemies) do
        if enemy:faceUp() and not enemy:hasSkill('zhaxiang') then
            use.card = sgs.Card_Parse('#LuaJunxing:' .. cards[1]:getEffectiveId() .. ':')
            if use.to then
                use.to:append(enemy)
            end
            return
        end
    end
    -- 随机选择一名正面朝上敌人作为目标
    local face_up_enemies = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:faceUp() and not enemy:hasSkill('zhaxiang') then
            table.insert(face_up_enemies, enemy)
        end
    end
    use.card = sgs.Card_Parse('#LuaJunxing:' .. cards[1]:getEffectiveId() .. ':')
    if use.to then
        use.to:append(face_up_enemies[rinsan.random(1, #face_up_enemies)])
    end
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

-- 御策弃牌部分援引满宠，不作额外的处理
-- 御策展示部分
sgs.ai_skill_cardask['@LuaYuce-show'] = function(self, data)
    local damage = self.room:getTag('CurrentDamageStruct'):toDamage()
    if not damage.from or damage.from:isDead() then
        return '.'
    end
    if self:isFriend(damage.from) then
        return self.player:handCards():first()
    end
    local flag = string.format('%s_%s_%s', 'visible', self.player:objectName(), damage.from:objectName())
    local types = {sgs.Card_TypeBasic, sgs.Card_TypeEquip, sgs.Card_TypeTrick}
    for _, card in sgs.qlist(damage.from:getHandcards()) do
        if card:hasFlag('visible') or card:hasFlag(flag) then
            table.removeOne(types, card:getTypeId())
        end
        if #types == 0 then
            break
        end
    end
    if #types == 0 then
        types = {sgs.Card_TypeBasic}
    end
    for _, card in sgs.qlist(self.player:getHandcards()) do
        for _, cardtype in ipairs(types) do
            if card:getTypeId() == cardtype then
                return card
            end
        end
    end
    return self.player:getHandcards():first()
end

-- 界李儒
-- 绝策
sgs.ai_skill_playerchosen['LuaJuece'] = function(self, targets)
    self:updatePlayers()
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isFriend(p) or not self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            table.removeOne(targets, p)
        end
    end
    if #targets == 0 then
        return nil
    end
    self:sort(targets, 'hp')
    return targets[1]
end

-- 灭计
local LuaMieji_skill = {}
LuaMieji_skill.name = 'LuaMieji'
table.insert(sgs.ai_skills, LuaMieji_skill)
LuaMieji_skill.getTurnUseCard = function(self)
    if self.player:hasUsed('#LuaMiejiCard') or self.player:isKongcheng() then
        return
    end
    return sgs.Card_Parse('#LuaMiejiCard:.:')
end

sgs.ai_skill_use_func['#LuaMiejiCard'] = function(_card, use, self)
    local room = self.room
    local nextAlive = self.player:getNextAlive()
    local hasLightning, hasIndulgence, hasSupplyShortage
    local tricks = nextAlive:getJudgingArea()
    if not tricks:isEmpty() and not nextAlive:containsTrick('YanxiaoCard') and not nextAlive:hasSkill('qianxi') then
        local trick = tricks:at(tricks:length() - 1)
        if self:hasTrickEffective(trick, nextAlive) then
            if trick:isKindOf('Lightning') then
                hasLightning = true
            elseif trick:isKindOf('Indulgence') then
                hasIndulgence = true
            elseif trick:isKindOf('SupplyShortage') then
                hasSupplyShortage = true
            end
        end
    end

    local putcard = nil
    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if card:isBlack() and card:isKindOf('TrickCard') then
            if hasLightning and card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
                if self:isEnemy(nextAlive) then
                    putcard = card
                    break
                else
                    goto continue_point
                end
            end
            if hasSupplyShortage and card:getSuit() == sgs.Card_Club then
                if self:isFriend(nextAlive) then
                    putcard = card
                    break
                else
                    goto continue_point
                end
            end
            if hasIndulgence then
                if sgs.Sanguosha:getCard(room:drawCard()):getSuit() == sgs.Card_Heart and self:isFriend(nextAlive) then
                    return
                end
                if self:isFriend(nextAlive) then
                    putcard = card
                    break
                else
                    goto continue_point
                end
            end
            if not putcard then
                putcard = card
                break
            end
            ::continue_point::
        end
    end

    local target
    for _, enemy in ipairs(self.enemies) do
        if self:needKongcheng(enemy) and enemy:getHandcardNum() <= 2 then
            goto continue_point
        end
        if not enemy:isNude() then
            target = enemy
            break
        end
        ::continue_point::
    end
    if not target then
        for _, friend in ipairs(self.friends_noself) do
            if self:needKongcheng(friend) and friend:getHandcardNum() < 2 and not friend:isKongcheng() then
                target = friend
                break
            end
        end
    end

    if putcard and target then
        use.card = sgs.Card_Parse('#LuaMiejiCard:' .. putcard:getEffectiveId() .. ':')
        if use.to then
            use.to:append(target)
        end
        return
    end
end

sgs.ai_use_priority['LuaMiejiCard'] = sgs.ai_use_priority.Dismantlement + 1

sgs.ai_card_intention.LuaMiejiCard = function(self, card, from, tos)
    for _, to in ipairs(tos) do
        if self:needKongcheng(to) and to:getHandcardNum() <= 2 then
            goto continue_point
        end
        sgs.updateIntention(from, to, 10)
        ::continue_point::
    end
end

-- 焚城
local LuaFencheng_skill = {}
LuaFencheng_skill.name = 'LuaFencheng'
table.insert(sgs.ai_skills, LuaFencheng_skill)
LuaFencheng_skill.getTurnUseCard = function(self)
    if self.player:getMark('@burn') == 0 then
        return false
    end
    return sgs.Card_Parse('#LuaFenchengCard:.:')
end

sgs.ai_skill_use_func['#LuaFenchengCard'] = function(card, use, self)
    local value = 0
    local neutral = 0
    local damage = {
        from = self.player,
        damage = 2,
        nature = sgs.DamageStruct_Fire,
    }
    local lastPlayer = self.player
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        damage.to = p
        if self:damageIsEffective_(damage) then
            if sgs.evaluatePlayerRole(p, self.player) == 'neutral' then
                neutral = neutral + 1
            end
            local v = 4
            if (self:getDamagedEffects(p, self.player) or self:needToLoseHp(p, self.player)) and
                self:getCardsNum('Peach', p, self.player) + p:getHp() > 2 then
                v = v - 6
            elseif lastPlayer:objectName() ~= self.player:objectName() and lastPlayer:getCardCount(true) <
                p:getCardCount(true) then
                v = v - 4
            elseif lastPlayer:objectName() == self.player:objectName() and not p:isNude() then
                v = v - 4
            end
            if self:isFriend(p) then
                value = value - v - p:getHp() + 2
            elseif self:isEnemy(p) then
                value = value + v + p:getLostHp() - 1
            end
            if p:isLord() and p:getHp() <= 2 and
                (self:isEnemy(p, lastPlayer) and p:getCardCount(true) <= lastPlayer:getCardCount(true) or
                    lastPlayer:objectName() == self.player:objectName() and (not p:canDiscard(p, 'he') or p:isNude())) then
                if not self:isEnemy(p) then
                    if self:getCardsNum('Peach') + self:getCardsNum('Peach', p, self.player) + p:getHp() <= 2 then
                        return
                    end
                else
                    use.card = card
                    return
                end
            end
        end
    end

    if neutral > self.player:aliveCount() / 2 then
        return
    end
    if value > 0 then
        use.card = card
    end
end

sgs.ai_use_priority['LuaFenchengCard'] = 9.1
