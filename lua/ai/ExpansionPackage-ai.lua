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
    targets = sgs.QList2Table(targets)
    self:sort(targets)
    for _, target in ipairs(targets) do
        if
            self:isFriend(target) and not target:hasSkill('zishu') and not target:hasSkill('manjuan') and
                not target:hasSkill('LuaZishu') and
                not self:needKongcheng(target, true)
         then
            return target
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

-- 精械
-- 暂不考虑加强防具
sgs.ai_skill_cardask['LuaJingxie-Invoke'] = function(self, data, pattern)
    local dying = data:toDying()
    local peaches = 1 - dying.who:getHp()
    local armors = {}
    if self:getCardsNum('Peach') + self:getCardsNum('Analeptic') < peaches then
        for _, acard in sgs.qlist(self.player:getCards('h')) do
            if acard:isKindOf('Armor') then
                table.insert(armors, acard)
            end
        end
        if #armors > 0 then
            self:sortByKeepValue(armors, true)
            return armors[1]
        end
        if self.player:getArmor() then
            return '$' .. self.player:getArmor():getEffectiveId()
        end
    end
    return nil
end

-- 巧思
sgs.ai_use_value['LuaQiaosiStartCard'] = 100
sgs.ai_use_priority['LuaQiaosiStartCard'] = 10

local LuaQiaosi_skill = {}
LuaQiaosi_skill.name = 'LuaQiaosi'

table.insert(sgs.ai_skills, LuaQiaosi_skill)

-- 是否发动过“巧思”，如果没有，进行选择
LuaQiaosi_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:hasUsed('#LuaQiaosiStartCard') then
        return sgs.Card_Parse('#LuaQiaosiStartCard:.:')
    end
end

sgs.ai_skill_use_func['#LuaQiaosiStartCard'] = function(card, use, self)
    local card_str = '#LuaQiaosiStartCard:.:'
    local acard = sgs.Card_Parse(card_str)
    assert(acard)
    use.card = acard
end

-- 马钧转一转
-- 主要转法：
-- 126：2锦囊+2装备+酒/杀
-- 136：2锦囊+2装备+杀/酒
-- 146：2锦囊+2装备+闪/桃
-- 156：2锦囊+2装备+桃/闪
-- 236：酒杀/杀杀/酒酒+2装备
-- 145：闪桃/闪闪/桃桃+2锦囊
sgs.ai_skill_choice['LuaQiaosi'] = function(self, choices)
    local items = choices:split('+')
    -- 目前考虑默认转126，自身较弱时转156
    if table.contains(items, 'king') then
        return 'king'
    elseif table.contains(items, 'general') then
        return 'general'
    else
        if self:isWeak() then
            if table.contains(items, 'scholar') then
                return 'scholar'
            end
        else
            if table.contains(items, 'merchant') then
                return 'merchant'
            end
        end
    end
    return items[1]
end

-- 巧思给牌
sgs.ai_skill_use['@@LuaQiaosi!'] = function(self, prompt, method)
    local target
    self:sort(self.friends_noself)
    for _, friend in ipairs(self.friends_noself) do
        if
            not friend:hasSkill('zishu') and not friend:hasSkill('manjuan') and not friend:hasSkill('LuaZishu') and
                not self:needKongcheng(friend, true)
         then
            target = friend
            break
        end
    end
    local x = self.player:getMark('LuaQiaosiCardsNum')
    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    local to_give = {}
    local index = 0
    while index < x do
        index = index + 1
        table.insert(to_give, cards[index]:getEffectiveId())
    end
    if target then
        return '#LuaQiaosiCard:' .. table.concat(to_give, '+') .. ':->' .. target:objectName()
    end
    return '#LuaQiaosiCard:' .. table.concat(to_give, '+') .. ':.'
end

-- 界满宠
-- 峻刑
sgs.ai_use_value['LuaJunxingCard'] = 10
sgs.ai_use_priority['LuaJunxingCard'] = 1.2

local LuaJunxing_skill = {}
LuaJunxing_skill.name = 'LuaJunxing'

table.insert(sgs.ai_skills, LuaJunxing_skill)

-- 是否发动过“峻刑”，如果没有，进行选择
LuaJunxing_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:isKongcheng() and not self.player:hasUsed('#LuaJunxingCard') then
        return sgs.Card_Parse('#LuaJunxingCard:.:')
    end
end

sgs.ai_skill_use_func['#LuaJunxingCard'] = function(_card, use, self)
    -- 简单处理，丢最不值钱的一张手牌
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    -- 如果有队友翻面，翻队友
    for _, friend in ipairs(self.friends_noself) do
        if not friend:faceUp() then
            use.card = sgs.Card_Parse('#LuaJunxingCard:' .. cards[1]:getEffectiveId() .. ':')
            if use.to then
                use.to:append(friend)
            end
            return
        end
    end
    -- 选敌人防御最低且未被翻面的
    self:sort(self.enemies, 'defense')
    for _, enemy in ipairs(self.enemies) do
        if self:isWeak(enemy) and enemy:faceUp() and not enemy:hasSkill('zhaxiang') then
            use.card = sgs.Card_Parse('#LuaJunxingCard:' .. cards[1]:getEffectiveId() .. ':')
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
    use.card = sgs.Card_Parse('#LuaJunxingCard:' .. cards[1]:getEffectiveId() .. ':')
    if use.to then
        use.to:append(face_up_enemies[math.random(1, #face_up_enemies)])
    end
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

-- 李傕
-- 李傕暂不考虑【亦算】
sgs.ai_skill_invoke.LuaYisuan = function(self, data)
    return false
end

-- 狼袭
sgs.ai_skill_playerchosen['LuaLangxi'] = function(self, targets)
    self:updatePlayers()
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            table.removeOne(targets, p)
        end
    end
    if #targets == 0 then
        return nil
    end
    self:sort(targets, 'hp')
    return targets[1]
end

-- 绝策
sgs.ai_skill_playerchosen['LuaJuece'] = function(self, targets)
    self:updatePlayers()
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
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
    local damage = {from = self.player, damage = 2, nature = sgs.DamageStruct_Fire}
    local lastPlayer = self.player
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        damage.to = p
        if self:damageIsEffective_(damage) then
            if sgs.evaluatePlayerRole(p, self.player) == 'neutral' then
                neutral = neutral + 1
            end
            local v = 4
            if
                (self:getDamagedEffects(p, self.player) or self:needToLoseHp(p, self.player)) and
                    self:getCardsNum('Peach', p, self.player) + p:getHp() > 2
             then
                v = v - 6
            elseif
                lastPlayer:objectName() ~= self.player:objectName() and
                    lastPlayer:getCardCount(true) < p:getCardCount(true)
             then
                v = v - 4
            elseif lastPlayer:objectName() == self.player:objectName() and not p:isNude() then
                v = v - 4
            end
            if self:isFriend(p) then
                value = value - v - p:getHp() + 2
            elseif self:isEnemy(p) then
                value = value + v + p:getLostHp() - 1
            end
            if
                p:isLord() and p:getHp() <= 2 and
                    (self:isEnemy(p, lastPlayer) and p:getCardCount(true) <= lastPlayer:getCardCount(true) or
                        lastPlayer:objectName() == self.player:objectName() and
                            (not p:canDiscard(p, 'he') or p:isNude()))
             then
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

-- 凌统
-- 旋风
sgs.ai_skill_use['@@LuaXuanfeng'] = function(self, prompt, method)
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isNude() and self.player:canDiscard(enemy, 'he') then
            table.insert(targets, enemy:objectName())
        end
        -- 优先多目标选择
        if #targets >= 2 then
            break
        end
    end
    if #targets > 0 then
        self:sort(targets, 'defense')
        return '#LuaXuanfengCard:.:->' .. table.concat(targets, '+')
    end
    return '.'
end

-- 旋风选择伤害目标
sgs.ai_skill_playerchosen['LuaXuanfeng'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, 'defense')
    return targets[1]
end

-- 凌统暂不考虑使用【勇进】（太阴间了）
