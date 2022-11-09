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

-- 界马岱
-- 是否给队友摸牌
sgs.ai_skill_invoke.LuaQianxiDraw = function(self, data)
    local target = data:toPlayer()
    return self:isFriend(target)
end

-- 应援选择目标
sgs.ai_skill_playerchosen['LuaYingyuan'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets)
    for _, target in ipairs(targets) do
        if self:isFriend(target) and not target:hasSkill('zishu') and not target:hasSkill('manjuan') and
            not target:hasSkill('LuaZishu') and not self:needKongcheng(target, true) then
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
        if self:getDamagedEffects(target, self.player, true) or
            (target:getArmor() and not target:getArmor():isKindOf('SilverLion')) then
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
-- 加强连弩和防具，但不考虑加强未装备的
sgs.ai_use_value['LuaJingxieCard'] = 10
sgs.ai_use_priority['LuaJingxieCard'] = 90

local LuaJingxie_skill = {}
LuaJingxie_skill.name = 'LuaJingxie'

table.insert(sgs.ai_skills, LuaJingxie_skill)

LuaJingxie_skill.getTurnUseCard = function(self, inclusive)
    local armor = self.player:getArmor()
    local weapon = self.player:getWeapon()
    if armor and self.player:getMark(armor:objectName()) == 0 then
        return sgs.Card_Parse('#LuaJingxieCard:' .. armor:getEffectiveId() .. ':')
    end
    if weapon and weapon:objectName() == 'crossbow' and self.player:getMark('crossbow') == 0 then
        return sgs.Card_Parse('#LuaJingxieCard:' .. weapon:getEffectiveId() .. ':')
    end
end

sgs.ai_skill_use_func['#LuaJingxieCard'] = function(cd, use, self)
    use.card = cd
end

-- 濒死使用
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
        if not friend:hasSkill('zishu') and not friend:hasSkill('manjuan') and not friend:hasSkill('LuaZishu') and
            not self:needKongcheng(friend, true) then
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
        if enemy:faceUp() and not enemy:hasSkill('zhaxiang') then
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
        -- damageIsEffective 函数封装了对应的判断逻辑
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
        nature = sgs.DamageStruct_Fire
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

-- 凌统

-- 比装备数量
sgs.ai_compare_funcs['equipcard'] = function(a, b, self)
    local c1 = a:getEquips():length()
    local c2 = b:getEquips():length()
    if c1 == c2 then
        return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
    else
        return c1 < c2
    end
end

-- 旋风
sgs.ai_skill_use['@@LuaXuanfeng'] = function(self, prompt, method)
    -- 只有一个敌人，且符合条件，就直接对其发动【旋风】
    if #self.enemies == 1 and self.player:canDiscard(self.enemies[1], 'he') then
        return '#LuaXuanfengCard:.:->' .. self.enemies[1]:objectName()
    end

    local equipped_targets, no_equip_targets = {}, {}
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isNude() and self.player:canDiscard(enemy, 'he') then
            if enemy:hasEquip() then
                table.insert(equipped_targets, enemy)
            else
                table.insert(no_equip_targets, enemy)
            end
        end
    end

    local targets = {}

    -- 优先拆有装备的
    if #equipped_targets > 0 then
        self:sort(equipped_targets, 'equipcard')
        table.insert(targets, equipped_targets[1])
        if equipped_targets[1]:getEquips():length() <= 1 and #equipped_targets > 1 then
            table.insert(targets, equipped_targets[2])
        end
    end

    -- 如果只有一个或没有有装备的敌人，考虑手牌
    if #targets <= 1 then
        -- 如果只有第一个空城带单装备的，直接引入第二目标
        if targets[1]:isKongcheng() and #no_equip_targets > 0 then
            table.insert(targets, no_equip_targets[1])
        end

        -- 随机选择是否引入
        local random = math.random(0, 1)
        -- 如果没有目标就直接考虑引入
        if (random == 1 or #targets == 0) and #no_equip_targets > 0 then
            table.insert(targets, no_equip_targets[1])
        end
    end

    -- 输出结果
    if #targets > 0 then
        local output_targets = {}
        for _, output in ipairs(targets) do
            table.insert(output_targets, output:objectName())
        end
        return '#LuaXuanfengCard:.:->' .. table.concat(output_targets, '+')
    end
    return '.'
end

-- 旋风选择伤害目标
sgs.ai_skill_playerchosen['LuaXuanfeng'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, 'defense')
    for _, target in ipairs(targets) do
        if self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then
            return target
        end
    end
    return nil
end

-- 凌统暂不考虑使用【勇进】（太阴间了）

-- 王元姬
-- 谦冲
sgs.ai_skill_choice['LuaQianchong'] = function(self, choices, data)
    local items = choices:split('+')
    -- 分别为基本、锦囊、装备

    -- 统计顺手牵羊和杀的数量
    local snatchesCount, slashCount = self:getCardsNum('Snatch'), self:getCardsNum('Slash')

    -- 无限距离锦囊牌，当顺手较多的时候，使用锦囊
    if snatchesCount > slashCount then
        return items[2]
    end
    return items[1]
end

-- 王朗-十周年
-- 鼓舌
local LuaGushe_skill = {}
LuaGushe_skill.name = 'LuaGushe'
table.insert(sgs.ai_skills, LuaGushe_skill)
LuaGushe_skill.getTurnUseCard = function(self)
    -- 防止自爆
    if self.player:getMark('@LuaGushe') >= 6 or self.player:isKongcheng() then
        return
    end
    if self.player:getMark('LuaGusheWin') >= 7 - self.player:getMark('@LuaGushe') then
        return
    end
    for _, enemy in ipairs(self.enemies) do
        if self.player:canPindian(enemy, 'LuaGushe') then
            return sgs.Card_Parse('#LuaGusheCard:.:')
        end
    end
end

sgs.ai_skill_use_func['#LuaGusheCard'] = function(_card, use, self)
    local cards = sgs.QList2Table(self.player:getCards('h'))
    self:sortByUseValue(cards, true)
    self:sort(self.enemies, 'handcard')
    for _, enemy in ipairs(self.enemies) do
        if self.player:canPindian(enemy, 'LuaGushe') then
            if use.to and use.to:length() < 3 then
                use.to:append(enemy)
            end
        end
    end
    for _, card in ipairs(cards) do
        if not card:isKindOf('Peach') and not card:isKindOf('ExNihilo') and not card:isKindOf('Jink') or
            (card:getNumber() <= self.player:getMark('@LuaGushe')) then
            use.card = sgs.Card_Parse('#LuaGusheCard:' .. card:getId() .. ':')
        end
    end
end

sgs.ai_use_value['LuaGusheCard'] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority['LuaGusheCard'] = sgs.ai_use_priority.ExNihilo - 0.1

-- 杨彪
-- 让节
-- 移动牌目标
sgs.ai_skill_use['@@LuaRangjie'] = function(self, prompt, method)
    local source
    local target
    self:sort(self.friends, 'defense')
    -- 移掉队友头上的兵乐
    for _, friend in ipairs(self.friends) do
        local judges = friend:getJudgingArea()
        if not judges:isEmpty() then
            for _, judge in sgs.qlist(judges) do
                if not judge:isKindOf('YanxiaoCard') then
                    source = friend
                    for _, enemy in ipairs(self.enemies) do
                        -- 敌人必须有对应的判定区
                        if enemy:hasJudgeArea() and not enemy:containsTrick(judge:objectName()) and
                            not enemy:containsTrick('YanxiaoCard') and
                            not self.room:isProhibited(self.player, enemy, judge) and
                            not (enemy:hasSkill('hongyan') or judge:isKindOf('Lightning')) then
                            target = enemy
                            break
                        end
                    end
                    if target then
                        break
                    end
                end
            end
        end
    end

    if source and target then
        return '#LuaRangjieCard:.:->' .. source:objectName() .. '+' .. target:objectName()
    end

    -- 将对面头上的言笑牌移过来
    for _, enemy in ipairs(self.enemies) do
        local judges = enemy:getJudgingArea()
        if enemy:containsTrick('YanxiaoCard') then
            source = enemy
            for _, judge in sgs.qlist(judges) do
                if judge:isKindOf('YanxiaoCard') then
                    for _, friend in ipairs(self.friends) do
                        if friend:hasJudgeArea() and not friend:containsTrick(judge:objectName()) and
                            not self.room:isProhibited(self.player, friend, judge) and
                            not friend:getJudgingArea():isEmpty() then
                            target = friend
                            break
                        end
                    end
                    if target then
                        break
                    end
                    for _, friend in ipairs(self.friends) do
                        if friend:hasJudgeArea() and not friend:containsTrick(judge:objectName()) and
                            not self.room:isProhibited(self.player, friend, judge) then
                            target = friend
                            break
                        end
                    end
                    if target then
                        break
                    end
                end
            end
        end
    end

    if source and target then
        return '#LuaRangjieCard:.:->' .. source:objectName() .. '+' .. target:objectName()
    end

    -- 处理装备
    -- 把对面装备移过来
    for _, enemy in ipairs(self.enemies) do
        if enemy:hasEquip() then
            source = enemy
        end
    end

    for _, friend in ipairs(self.friends) do
        if source and ((source:getWeapon() and not friend:getWeapon() and friend:hasEquipArea(0)) or
            (source:getArmor() and not friend:getArmor() and friend:hasEquipArea(1)) or
            (source:getDefensiveHorse() and not friend:getDefensiveHorse() and friend:hasEquipArea(2)) or
            (source:getOffensiveHorse() and not friend:getOffensiveHorse() and friend:hasEquipArea(3)) or
            (source:getTreasure() and not friend:getTreasure() and friend:hasEquipArea(4))) then
            target = friend
        end
    end

    if source and target then
        return '#LuaRangjieCard:.:->' .. source:objectName() .. '+' .. target:objectName()
    end

    return '.'
end

sgs.ai_skill_cardchosen['LuaRangjie'] = function(self, who, flags, method)
    local disabled_ids = self.room:getTag('LuaRangjieDisabledIntList'):toIntList()
    -- 优先选择判定区
    -- 如果是队友，则把头上的言笑之外的牌移走
    if self:isFriend(who) then
        for _, cd in sgs.qlist(who:getCards('j')) do
            if (not cd:isKindOf('YanxiaoCard')) and (not disabled_ids:contains(cd:getEffectiveId())) then
                return cd
            end
        end
    else
        -- 移走对面的言笑牌
        for _, cd in sgs.qlist(who:getCards('j')) do
            if cd:isKindOf('YanxiaoCard') and (not disabled_ids:contains(cd:getEffectiveId())) then
                return cd
            end
        end
    end

    if not self:isFriend(who) then
        -- 移走对面的装备
        -- 以 +1 马、防具、-1 马、武器、宝物·的顺序判断
        local defensiveHorse = who:getDefensiveHorse()
        if defensiveHorse and not disabled_ids:contains(defensiveHorse:getEffectiveId()) then
            return defensiveHorse
        end

        local armor = who:getArmor()
        if armor and not disabled_ids:contains(armor:getEffectiveId()) then
            return armor
        end

        local offensiveHorse = who:getOffensiveHorse()
        if offensiveHorse and not disabled_ids:contains(offensiveHorse:getEffectiveId()) then
            return offensiveHorse
        end

        local weapon = who:getWeapon()
        if weapon and not disabled_ids:contains(weapon:getEffectiveId()) then
            return weapon
        end

        local treasure = who:getTreasure()
        if treasure and not disabled_ids:contains(treasure:getEffectiveId()) then
            return treasure
        end
    end
    return nil
end

-- 选择摸牌
sgs.ai_skill_choice['LuaRangjie'] = function(self, choices)
    -- choices 分别为obtainBasic、obtainTrick、obtainEquip、以及 cancel

    -- 如果当前回合角色有离魂且未发动，同时自身比较虚弱，则不摸牌
    for _, enemy in ipairs(self.enemies) do
        if enemy:hasSkill('lihun') and self.room:getCurrent():objectName() == enemy:objectName() and
            not enemy:hasUsed('LihunCard') and self:isWeak() then
            return 'cancel'
        end
    end

    -- 如果自己快没了就摸基本，看有无桃酒
    if self:isWeak() then
        return 'obtainBasic'
    end

    -- 正常情况下，基本、锦囊、装备以 442 概率分配
    local rand = math.random(1, 100)
    if rand > 80 then
        return 'obtainEquip'
    elseif rand > 40 then
        return 'obtainTrick'
    end
    return 'obtainBasic'
end

-- 杨彪暂不考虑使用【义争】

-- 伊籍
-- 急援
sgs.ai_skill_invoke.LuaJiyuan = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return true
    end
    return false
end

-- 机捷
local LuaJijie_skill = {}
LuaJijie_skill.name = 'LuaJijie'

table.insert(sgs.ai_skills, LuaJijie_skill)

LuaJijie_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:hasUsed('#LuaJijieCard') then
        return sgs.Card_Parse('#LuaJijieCard:.:')
    end
end

sgs.ai_skill_use_func['#LuaJijieCard'] = function(card, use, self)
    local card_str = '#LuaJijieCard:.:'
    local acard = sgs.Card_Parse(card_str)
    assert(acard)
    use.card = acard
end

sgs.ai_skill_playerchosen['LuaJijie'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets)
    for _, target in ipairs(targets) do
        if self:isFriend(target) and
            (not target:hasSkill('zishu') and not target:hasSkill('manjuan') and not target:hasSkill('LuaZishu')) and
            not self:needKongcheng(target, true) then
            return target
        end
    end
    return nil
end

sgs.ai_use_value['LuaJijieCard'] = 100
sgs.ai_use_priority['LuaJijieCard'] = 10

-- 界廖化
-- 伏枥
sgs.ai_skill_invoke.LuaFuli = function(self, data)
    local dying = data:toDying()
    local peaches = 1 - dying.who:getHp()
    -- 如果手上桃酒数量不够，则发动伏枥
    if self:getCardsNum('Peach') + self:getCardsNum('Analeptic') < peaches then
        return true
    end
    return false
end

-- 公孙康
-- 讨灭只对非友军发动
sgs.ai_skill_invoke.LuaTaomie = function(self, data)
    local currTaomieTarget
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getMark('@LuaTaomie') > 0 then
            currTaomieTarget = p
            break
        end
    end
    -- 如果场上已有讨灭标记，则判断血量
    if currTaomieTarget then
        local target = data:toPlayer()
        if target:getHp() < currTaomieTarget:getHp() then
            return true
        else
            return false
        end
    end
    return not self:isFriend(data:toPlayer())
end

-- 讨灭给牌
sgs.ai_skill_playerchosen['LuaTaomie'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    -- 除去会丢掉牌的、不是队友的
    for _, p in ipairs(targets) do
        if not self:isFriend(p) or p:hasSkill('LuaZishu') or p:hasSkill('manjuan') or p:hasSkill('zishu') or
            self:needKongcheng(p, true) then
            table.removeOne(targets, p)
        end
    end
    if #targets > 0 then
        self:sort(targets, 'defense')
        return targets[1]
    end
    return nil
end

sgs.ai_skill_choice['LuaTaomie'] = function(self, choices, data)
    -- 选项为：加伤害、拿牌、加伤害+拿牌
    local items = choices:split('+')
    local target = data:toPlayer()
    local armor = target:getArmor()
    if armor and armor:objectName() == 'silver_lion' then
        -- 有白银狮子，只拿牌
        if table.contains(items, 'getOneCard') then
            return 'getOneCard'
        end
        return 'cancel'
    end
    return items[#items - 1]
end

-- 界孙策
-- 英魂
sgs.ai_skill_use['@@LuaYinghun'] = function(self, prompt, method)
    local x = self.player:getLostHp()
    local n = x - 1

    self:updatePlayers()

    -- 摸1弃1，如果对面有漫卷，就安排
    if x == 1 and #self.friends_noself == 0 then
        for _, enemy in ipairs(self.enemies) do
            if enemy:hasSkill('manjuan') then
                return '#LuaYinghunCard:.:->' .. enemy:objectName()
            end
        end
        return '.'
    end

    local target
    local assistTarget = self:AssistTarget()

    if x == 1 then
        self:sort(self.friends_noself, 'handcard')
        self.friends_noself = sgs.reverse(self.friends_noself)

        -- 如果队友有掉装备的技能且没有漫卷，例如枭姬，则选他
        for _, friend in ipairs(self.friends_noself) do
            if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards('e'):length() > 0 and
                not friend:hasSkill('manjuan') then
                target = friend
                break
            end
        end
        if not target then
            -- 配合邓艾等屯田
            for _, friend in ipairs(self.friends_noself) do
                if friend:hasSkills('tuntian+zaoxian') and not friend:hasSkill('manjuan') then
                    target = friend
                    break
                end
            end
        end
        if not target then
            -- 如果队友要掉装备则可以，例如藤甲、白银狮子
            for _, friend in ipairs(self.friends_noself) do
                if self:needToThrowArmor(friend) and not friend:hasSkill('manjuan') then
                    target = friend
                    break
                end
            end
        end
        if not target then
            -- 选择敌方有漫卷的安排
            for _, enemy in ipairs(self.enemies) do
                if enemy:hasSkill('manjuan') then
                    return enemy
                end
            end
        end

        if not target and assistTarget and not assistTarget:hasSkill('manjuan') and assistTarget:getCardCount(true) > 0 and
            not self:needKongcheng(assistTarget, true) then
            target = assistTarget
        end

        -- 那没办法，英魂总得安排一个人，要不就把你给安排了吧！
        -- 小制衡总归有好处
        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if friend:getCards('he'):length() > 0 and not friend:hasSkill('manjuan') then
                    target = friend
                    break
                end
            end
        end

        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if not friend:hasSkill('manjuan') then
                    target = friend
                    break
                end
            end
        end
    elseif #self.friends > 1 then
        self:sort(self.friends_noself, 'chaofeng')
        for _, friend in ipairs(self.friends_noself) do
            if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards('e'):length() > 0 and
                not friend:hasSkill('manjuan') then
                target = friend
                break
            end
        end
        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if friend:hasSkills('tuntian+zaoxian') and not friend:hasSkill('manjuan') then
                    target = friend
                    break
                end
            end
        end
        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if self:needToThrowArmor(friend) and not friend:hasSkill('manjuan') then
                    target = friend
                    break
                end
            end
        end
        if not target and #self.enemies > 0 then
            local wf
            if self.player:isLord() then
                if self:isWeak() and (self.player:getHp() < 2 and self:getCardsNum('Peach') < 1) then
                    wf = true
                end
            end
            if not wf then
                for _, friend in ipairs(self.friends_noself) do
                    if self:isWeak(friend) then
                        wf = true
                        break
                    end
                end
            end

            if not wf then
                self:sort(self.enemies, 'chaofeng')
                for _, enemy in ipairs(self.enemies) do
                    if enemy:getCards('he'):length() == n and not self:doNotDiscard(enemy, 'nil', true, n) then
                        target = enemy
                        break
                    end
                end
                if not target then
                    for _, enemy in ipairs(self.enemies) do
                        if enemy:getCards('he'):length() >= n and not self:doNotDiscard(enemy, 'nil', true, n) and
                            self:hasSkills(sgs.cardneed_skill, enemy) then
                            target = enemy
                            break
                        end
                    end
                end
            end
        end
    end
    if not target and assistTarget and not assistTarget:hasSkill('manjuan') and
        not self:needKongcheng(assistTarget, true) then
        target = assistTarget
    end

    if not target then
        target = self:findPlayerToDraw(false, n)
    end

    if not target then
        for _, friend in ipairs(self.friends_noself) do
            if not friend:hasSkill('manjuan') then
                target = friend
                break
            end
        end
    end

    if not target and x > 1 and #self.enemies > 0 then
        self:sort(self.enemies, 'handcard')
        for _, enemy in ipairs(self.enemies) do
            if enemy:getCards('he'):length() >= n and not self:doNotDiscard(enemy, 'nil', true, n) then
                target = enemy
                break
            end
        end
        if not target then
            self.enemies = sgs.reverse(self.enemies)
            for _, enemy in ipairs(self.enemies) do
                if not enemy:isNude() and
                    not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards('e'):length() > 0) and
                    not self:needToThrowArmor(enemy) and not enemy:hasSkills('tuntian+zaoxian') then
                    target = enemy
                    break
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if not enemy:isNude() and
                        not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards('e'):length() > 0) and
                        not self:needToThrowArmor(enemy) and
                        not (enemy:hasSkills('tuntian+zaoxian') and x < 3 and enemy:getCards('he'):length() < 2) then
                        target = enemy
                        break
                    end
                end
            end
        end
    end

    if target then
        return '#LuaYinghunCard:.:->' .. target:objectName()
    end
    return '.'
end

sgs.ai_skill_choice['LuaYinghun'] = function(self, choices, data)
    -- 友军多摸，否则多弃
    if self:isFriend(data:toPlayer()) then
        return 'dxt1'
    end
    return 'd1tx'
end

-- 曹纯
-- 始终发动缮甲
sgs.ai_skill_invoke.LuaShanjia = true

sgs.ai_skill_use['@@LuaShanjia!'] = function(self, prompt, method)
    local x = 3 - self.player:getMark('@luashanjia')
    if x == 0 then
        if #self.enemies > 0 then
            self:sort(self.enemies, 'defense')
            return '#LuaShanjiaCard:.:->' .. self.enemies[1]:objectName()
        end
        return '#LuaShanjiaCard:.:.'
    else
        local to_discard = {}
        if self.player:getEquips():length() < x then
            local cards = sgs.QList2Table(self.player:getCards('he'))
            self:sortByUseValue(cards, true)
            for i = 1, x, 1 do
                table.insert(to_discard, cards[i]:getId())
            end
        else
            local cards = sgs.QList2Table(self.player:getEquips())
            self:sortByKeepValue(cards, true)
            for i = 1, x, 1 do
                table.insert(to_discard, cards[i]:getId())
            end
        end
        local can_slash = true
        for _, id in ipairs(to_discard) do
            local cd = sgs.Sanguosha:getCard(id)
            if cd:isKindOf('BasicCard') or cd:isKindOf('TrickCard') then
                can_slash = false
                break
            end
        end
        if can_slash then
            self:sort(self.enemies, 'defense')
            return '#LuaShanjiaCard:' .. table.concat(to_discard, '+') .. ':->' .. self.enemies[1]:objectName()
        end
        return '#LuaShanjiaCard:' .. table.concat(to_discard, '+') .. ':'
    end
end

-- 界曹植
-- 酒诗
sgs.ai_cardsview['LuaJiushi'] = function(self, class_name, player)
    if class_name == 'Analeptic' then
        if player:hasSkill('LuaJiushi') and player:faceUp() then
            return ('analeptic:LuaJiushi[no_suit:0]=.')
        end
    end
end

-- 背面朝上时始终发动酒诗翻回来
sgs.ai_skill_invoke.LuaJiushi = function(self, data)
    return not self.player:faceUp()
end

-- 落英
sgs.ai_skill_invoke.LuaLuoying = function(self)
    if self.player:hasFlag('DimengTarget') then
        local another
        for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if player:hasFlag('DimengTarget') then
                another = player
                break
            end
        end
        if not another or not self:isFriend(another) then
            return false
        end
    end
    return not self:needKongcheng(self.player, true)
end

-- 落英移除不需要的牌，仅在需要空城时选择，默认全拿走
sgs.ai_skill_askforag['LuaLuoying'] = function(self, card_ids)
    if self:needKongcheng(self.player, true) then
        return card_ids[1]
    else
        return -1
    end
end

-- 界颜良文丑
-- 双雄
sgs.ai_skill_invoke.LuaShuangxiong = function(self, data)
    -- 拥有此 Flag 代表为收牌确认
    if self.player:hasFlag('LuaShuangxiongDamaged') then
        return true
    end
    if self:needBear() then
        return false
    end
    if self.player:isSkipped(sgs.Player_Play) or
        (self.player:getHp() < 2 and not (self:getCardsNum('Slash') > 1 and self.player:getHandcardNum() >= 3)) or
        #self.enemies == 0 then
        return false
    end
    local duel = sgs.Sanguosha:cloneCard('duel')

    local dummy_use = {
        isDummy = true
    }
    self:useTrickCard(duel, dummy_use)

    return self.player:getHandcardNum() >= 3 and dummy_use.card
end

sgs.ai_cardneed.LuaShuangxiong = function(to, card, self)
    return not self:willSkipDrawPhase(to)
end

sgs.ai_skill_askforag['LuaShuangxiong'] = function(self, card_ids)
    local card1, card2 = sgs.Sanguosha:getCard(card_ids[1]), sgs.Sanguosha:getCard(card_ids[2])
    if card1:sameColorWith(card2) then
        if self:getUseValue(card1) > self:getUseValue(card2) then
            return card_ids[1]
        end
        return card_ids[2]
    else
        local blackCount, redCount = 0, 0
        for _, cd in sgs.qlist(self.player:getHandcards()) do
            if cd:isBlack() then
                blackCount = blackCount + 1
            elseif cd:isRed() then
                redCount = redCount + 1
            end
        end
        if blackCount > redCount then
            if card1:isRed() then
                return card_ids[1]
            else
                return card_ids[2]
            end
        else
            if card1:isBlack() then
                return card_ids[1]
            else
                return card_ids[2]
            end
        end
    end
end

local LuaShuangxiong_skill = {}
LuaShuangxiong_skill.name = 'LuaShuangxiong'
table.insert(sgs.ai_skills, LuaShuangxiong_skill)
LuaShuangxiong_skill.getTurnUseCard = function(self)
    if self.player:getMark('LuaShuangxiong') == 0 then
        return nil
    end
    local mark = self.player:getMark('LuaShuangxiong')

    local cards = self.player:getCards('h')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)

    local card
    for _, acard in ipairs(cards) do
        if (acard:isRed() and mark == 2) or (acard:isBlack() and mark == 1) then
            card = acard
            break
        end
    end

    if not card then
        return nil
    end
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    local card_str = ('duel:LuaShuangxiong[%s:%s]=%d'):format(suit, number, card_id)
    local skillcard = sgs.Card_Parse(card_str)
    assert(skillcard)
    return skillcard
end

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

-- 界贾诩
-- 乱武
LuaLuanwu_skill = {
    name = 'LuaLuanwu'
}
table.insert(sgs.ai_skills, LuaLuanwu_skill)

LuaLuanwu_skill.getTurnUseCard = function(self)
    if self.player:getMark('@chaos') <= 0 then
        return
    end
    return sgs.Card_Parse('#LuaLuanwuCard:.:')
end

sgs.ai_skill_use_func['#LuaLuanwuCard'] = function(card, use, self)
    local good, bad = 0, 0
    local lord = self.room:getLord()
    if lord and self.role ~= 'rebel' and self:isWeak(lord) then
        return
    end
    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isWeak(player) then
            if self:isFriend(player) then
                bad = bad + 1
            else
                good = good + 1
            end
        end
    end
    if good == 0 then
        return
    end

    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local hp = math.max(player:getHp(), 1)
        if self:getCardsNum('Analeptic', player) > 0 then
            if self:isFriend(player) then
                good = good + 1.0 / hp
            else
                bad = bad + 1.0 / hp
            end
        end

        local has_slash = (self:getCardsNum('Slash', player) > 0)
        local can_slash = false
        if not can_slash then
            for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
                if player:distanceTo(p) <= player:getAttackRange() then
                    can_slash = true
                    break
                end
            end
        end
        if not has_slash or not can_slash then
            if self:isFriend(player) then
                good = good + math.max(self:getCardsNum('Peach', player), 1)
            else
                bad = bad + math.max(self:getCardsNum('Peach', player), 1)
            end
        end

        if self:getCardsNum('Jink', player) == 0 then
            local lost_value = 0
            if self:hasSkills(sgs.masochism_skill, player) then
                lost_value = player:getHp() / 2
            end
            local hp = math.max(player:getHp(), 1)
            if self:isFriend(player) then
                bad = bad + (lost_value + 1) / hp
            else
                good = good + (lost_value + 1) / hp
            end
        end
    end

    if good > bad then
        use.card = card
    end
end

sgs.dynamic_value.damage_card.LuaLuanwuCard = true

-- 帷幕减伤害
LuaWeimuDamageEffect = function(self, to, nature, from, damageValue)
    if to:hasSkill('LuaJiejiaxuWeimu') then
        return to:getPhase() == sgs.Player_NotActive
    end
    return true
end

table.insert(sgs.ai_damage_effect, LuaWeimuDamageEffect)
