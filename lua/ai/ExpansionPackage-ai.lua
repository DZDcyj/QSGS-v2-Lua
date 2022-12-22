-- 扩展包 AI
-- Created by DZDcyj at 2021/8/21
-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 漫卷效果技能组
local LuaManjuanEffectSkills = {'manjuan', 'zishu', 'LuaZishu'}

function playerHasManjuanEffect(player)
    return player:hasSkills(table.concat(LuaManjuanEffectSkills, '|'))
end

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

-- 节钺
sgs.ai_skill_use['@@LuaJieyue'] = function(self, prompt, method)
    local player = self.player
    local final_card
    local min_value = 999
    for _, cd in sgs.qlist(player:getCards('he')) do
        local curr_value = self:getUseValue(cd)
        if curr_value < min_value then
            final_card = cd
            min_value = curr_value
        end
    end
    if not final_card then
        return '.'
    end

    local target
    if #self.friends_noself > 0 then
        -- 给最弱的友方
        self:sort(self.friends_noself, 'defense')
        target = self.friends_noself[1]
    end
    if target then
        return '#LuaJieyueCard:' .. final_card:getEffectiveId() .. ':->' .. target:objectName()
    end

    if #self.enemies > 0 then
        -- 给最强的敌方
        self:sort(self.enemies, 'defense', true)
        target = self.enemies[1]
    end
    if target then
        -- 如果对面牌很少就别送了
        if target:getHandcardNum() <= 1 and target:getEquips():length() <= 1 then
            return '.'
        end
        return '#LuaJieyueCard:' .. final_card:getEffectiveId() .. ':->' .. target:objectName()
    end

    return '.'
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
        if self:isFriend(target) and not playerHasManjuanEffect(target) and not self:needKongcheng(target, true) then
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
        if not playerHasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
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
        if self:isFriend(target) and (not playerHasManjuanEffect(target)) and not self:needKongcheng(target, true) then
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
        if not self:isFriend(p) or playerHasManjuanEffect(p) or self:needKongcheng(p, true) then
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
            if playerHasManjuanEffect(enemy) then
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

        -- 如果队友有掉装备的技能且没有漫卷类型技能，例如枭姬，则选他
        for _, friend in ipairs(self.friends_noself) do
            if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards('e'):length() > 0 and
                not playerHasManjuanEffect(friend) then
                target = friend
                break
            end
        end
        if not target then
            -- 配合邓艾等屯田
            for _, friend in ipairs(self.friends_noself) do
                if (friend:hasSkills('LuaTuntian+LuaZaoxian') or friend:hasSkills('tuntian+zaoxian')) and
                    not playerHasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
        end
        if not target then
            -- 如果队友要掉装备则可以，例如藤甲、白银狮子
            for _, friend in ipairs(self.friends_noself) do
                if self:needToThrowArmor(friend) and not playerHasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
        end
        if not target then
            -- 选择敌方有漫卷的安排
            for _, enemy in ipairs(self.enemies) do
                if playerHasManjuanEffect(enemy) then
                    return enemy
                end
            end
        end

        if not target and assistTarget and not playerHasManjuanEffect(assistTarget) and assistTarget:getCardCount(true) >
            0 and not self:needKongcheng(assistTarget, true) then
            target = assistTarget
        end

        -- 那没办法，英魂总得安排一个人，要不就把你给安排了吧！
        -- 小制衡总归有好处
        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if friend:getCards('he'):length() > 0 and not playerHasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
        end

        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if not playerHasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
        end
    elseif #self.friends > 1 then
        self:sort(self.friends_noself, 'chaofeng')
        for _, friend in ipairs(self.friends_noself) do
            if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards('e'):length() > 0 and
                not playerHasManjuanEffect(friend) then
                target = friend
                break
            end
        end
        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if (friend:hasSkills('LuaTuntian+LuaZaoxian') or friend:hasSkills('tuntian+zaoxian')) and
                    not playerHasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
        end
        if not target then
            for _, friend in ipairs(self.friends_noself) do
                if self:needToThrowArmor(friend) and not playerHasManjuanEffect(friend) then
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
    if not target and assistTarget and not playerHasManjuanEffect(assistTarget) and
        not self:needKongcheng(assistTarget, true) then
        target = assistTarget
    end

    if not target then
        target = self:findPlayerToDraw(false, n)
    end

    if not target then
        for _, friend in ipairs(self.friends_noself) do
            if not playerHasManjuanEffect(friend) then
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
                    not self:needToThrowArmor(enemy) and
                    not (enemy:hasSkills('LuaTuntian+LuaZaoxian') or enemy:hasSkills('tuntian+zaoxian')) then
                    target = enemy
                    break
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if not enemy:isNude() and
                        not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards('e'):length() > 0) and
                        not self:needToThrowArmor(enemy) and
                        not ((enemy:hasSkills('LuaTuntian+LuaZaoxian') or enemy:hasSkills('tuntian+zaoxian')) and x < 3 and
                            enemy:getCards('he'):length() < 2) then
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
    local target
    if x == 0 then
        if #self.enemies > 0 then
            self:sort(self.enemies, 'defense')
            for _, enemy in ipairs(self.enemies) do
                if self.player:canSlash(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
                    target = enemy
                    break
                end
            end
            if target then
                return string.format('#LuaShanjiaCard:.:->%s', target:objectName())
            end
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
            for _, enemy in ipairs(self.enemies) do
                if self.player:canSlash(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
                    target = enemy
                    break
                end
            end
            if target then
                return string.format('#LuaShanjiaCard:%s:->%s', table.concat(to_discard, '+'), target:objectName())
            end
        end
        return string.format('#LuaShanjiaCard:%s:.', table.concat(to_discard, '+'))
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
        if getCardsNum('Analeptic', player) > 0 then
            if self:isFriend(player) then
                good = good + 1.0 / hp
            else
                bad = bad + 1.0 / hp
            end
        end
        local has_slash = (getCardsNum('Slash', player) > 0)
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
                good = good + math.max(getCardsNum('Peach', player), 1)
            else
                bad = bad + math.max(getCardsNum('Peach', player), 1)
            end
        end
        if getCardsNum('Jink', player) == 0 then
            local lost_value = 0
            if self:hasSkills(sgs.masochism_skill, player) then
                lost_value = player:getHp() / 2
            end
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

-- 界邓艾
-- 屯田
sgs.ai_skill_invoke.LuaTuntian = function(self, data)
    if self.player:hasSkill('LuaZaoxian') and #self.enemies == 1 and self.room:alivePlayerCount() == 2 and
        self.player:getMark('LuaZaoxian') == 0 and self:hasSkills('noswuyan|qianxun', self.enemies[1]) then
        return false
    end
    return true
end

sgs.ai_slash_prohibit.LuaTuntian = function(self, from, to, card)
    if self:isFriend(to) then
        return false
    end
    if not to:hasSkill('LuaZaoxian') then
        return false
    end
    if from:hasSkill('tieji') or self:canLiegong(to, from) then
        return false
    end
    local enemies = self:getEnemies(to)
    if #enemies == 1 and self.room:alivePlayerCount() == 2 and
        self:hasSkills('noswuyan|qianxun|weimu|LuaWeimu|LuaJiejiaxuWeimu', enemies[1]) then
        return false
    end
    if getCardsNum('Jink', to, from) < 1 or sgs.card_lack[to:objectName()]['Jink'] == 1 or self:isWeak(to) then
        return false
    end
    if to:getHandcardNum() >= 3 and to:hasSkill('LuaZaoxian') then
        return true
    end
    return false
end

-- 急袭
local LuaJixi_skill = {}
LuaJixi_skill.name = 'LuaJixi'
table.insert(sgs.ai_skills, LuaJixi_skill)
LuaJixi_skill.getTurnUseCard = function(self)
    if self.player:getPile('field'):isEmpty() or
        (self.player:getHandcardNum() >= self.player:getHp() + 2 and self.player:getPile('field'):length() <=
            self.room:getAlivePlayers():length() / 2 - 1) then
        return
    end
    for i = 0, self.player:getPile('field'):length() - 1, 1 do
        local snatch = sgs.Sanguosha:getCard(self.player:getPile('field'):at(i))
        local snatch_str = ('snatch:LuaJixi[%s:%s]=%d'):format(snatch:getSuitString(), snatch:getNumberString(),
            self.player:getPile('field'):at(i))
        local LuaJixisnatch = sgs.Card_Parse(snatch_str)

        for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if (self.player:distanceTo(player, 1) <= 1 +
                sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, LuaJixisnatch)) and
                not self.room:isProhibited(self.player, player, LuaJixisnatch) and
                self:hasTrickEffective(LuaJixisnatch, player) then

                local suit = snatch:getSuitString()
                local number = snatch:getNumberString()
                local card_id = snatch:getEffectiveId()
                local card_str = ('snatch:LuaJixi[%s:%s]=%d'):format(suit, number, card_id)
                local newSnatch = sgs.Card_Parse(card_str)
                assert(newSnatch)
                return newSnatch
            end
        end
    end
end

sgs.ai_view_as.LuaJixi = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == 'field' then
        return ('snatch:LuaJixi[%s:%s]=%d'):format(suit, number, card_id)
    end
end

-- 李丰
-- 始终发动屯储
sgs.ai_skill_invoke.LuaTunchu = function(self, data)
    return true
end

-- 始终不置于武将牌上
sgs.ai_skill_use['@@LuaTunchu'] = function(self, prompt, method)
    return '.'
end

-- 输粮
-- 仅向队友发动
sgs.ai_skill_use['@@LuaShuliang'] = function(self, prompt, method)
    local current = self.room:getCurrent()
    if current:isFriend() then
        return '#LuaShuliangCard:.:->' .. current:objectName()
    end
    return '.'
end

-- 审配
-- 守邺发动
sgs.ai_skill_invoke.LuaShouye = function(self, data)
    local use = data:toCardUse()
    local card = use.card
    -- 判断牌是否为好牌，不是就发动
    if card:isKindOf('AmazingGrace') or card:isKindOf('GodSalvation') or card:isKindOf('ExNihilo') then
        return false
    end
    return true
end

-- 守邺选项
sgs.ai_skill_choice.LuaShouye = function(self, choices)
    local items = choices:split('+')
    return items[math.random(1, #items)]
end

-- 烈直
sgs.ai_skill_use['@@LuaLiezhi'] = function(self, prompt, method)
    self:sort(self.enemies, 'defense')
    local LuaLiezhi_mark = math.min(2, self.room:getOtherPlayers(self.player):length())
    local targets = {}

    local zhugeliang = self.room:findPlayerBySkillName('kongcheng')
    local luxun = self.room:findPlayerBySkillName('lianying') or self.room:findPlayerBySkillName('noslianying')
    local dengai = self.room:findPlayerBySkillName('tuntian')
    local jiedengai = self.room:findPlayerBySkillName('LuaTuntian')
    local jiangwei = self.room:findPlayerBySkillName('zhiji')
    local zhijiangwei = self.room:findPlayerBySkillName('beifa')

    local add_player = function(player, isfriend)
        if player:isNude() or player:objectName() == self.player:objectName() then
            return #targets
        end
        if self:objectiveLevel(player) == 0 and player:isLord() and sgs.current_mode_players['rebel'] > 1 then
            return #targets
        end

        local f = false
        for _, c in ipairs(targets) do
            if c == player:objectName() then
                f = true
                break
            end
        end

        if not f then
            table.insert(targets, player:objectName())
        end

        if isfriend and isfriend == 1 then
            self.player:setFlags('LuaLiezhi_isfriend_' .. player:objectName())
        end
        return #targets
    end

    local parseLuaLiezhiCard = function()
        if #targets == 0 then
            return '.'
        end
        local s = table.concat(targets, '+')
        return '#LuaLiezhiCard:.:->' .. s
    end

    local lord = self.room:getLord()
    if lord and self:isEnemy(lord) and sgs.turncount <= 1 and not lord:isKongcheng() then
        if add_player(lord) == LuaLiezhi_mark then
            return parseLuaLiezhiCard()
        end
    end

    if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark('zhiji') == 0 and jiangwei:getHandcardNum() == 1 and
        self:getEnemyNumBySeat(self.player, jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
        if add_player(jiangwei, 1) == LuaLiezhi_mark then
            return parseLuaLiezhiCard()
        end
    end

    if dengai and self:isFriend(dengai) and
        (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0) and dengai:hasSkill('zaoxian') and
        dengai:getMark('zaoxian') == 0 and dengai:getPile('field'):length() == 2 and add_player(dengai, 1) ==
        LuaLiezhi_mark then
        return parseLuaLiezhiCard()
    end

    if jiedengai and self:isFriend(jiedengai) and
        (not self:isWeak(jiedengai) or self:getEnemyNumBySeat(self.player, jiedengai) == 0) and
        jiedengai:hasSkill('LuaZaoxian') and jiedengai:getMark('zaoxian') == 0 and jiedengai:getPile('field'):length() ==
        2 and add_player(jiedengai, 1) == LuaLiezhi_mark then
        return parseLuaLiezhiCard()
    end

    if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and
        self:getEnemyNumBySeat(self.player, zhugeliang) > 0 then
        if zhugeliang:getHp() <= 2 then
            if add_player(zhugeliang, 1) == LuaLiezhi_mark then
                return parseLuaLiezhiCard()
            end
        else
            local flag = string.format('%s_%s_%s', 'visible', self.player:objectName(), zhugeliang:objectName())
            local cards = sgs.QList2Table(zhugeliang:getHandcards())
            if #cards == 1 and (cards[1]:hasFlag('visible') or cards[1]:hasFlag(flag)) then
                if cards[1]:isKindOf('TrickCard') or cards[1]:isKindOf('Slash') or cards[1]:isKindOf('EquipCard') then
                    if add_player(zhugeliang, 1) == LuaLiezhi_mark then
                        return parseLuaLiezhiCard()
                    end
                end
            end
        end
    end

    if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, luxun) > 0 then
        local flag = string.format('%s_%s_%s', 'visible', self.player:objectName(), luxun:objectName())
        local cards = sgs.QList2Table(luxun:getHandcards())
        if #cards == 1 and (cards[1]:hasFlag('visible') or cards[1]:hasFlag(flag)) then
            if cards[1]:isKindOf('TrickCard') or cards[1]:isKindOf('Slash') or cards[1]:isKindOf('EquipCard') then
                if add_player(luxun, 1) == LuaLiezhi_mark then
                    return parseLuaLiezhiCard()
                end
            end
        end
    end

    if zhijiangwei and self:isFriend(zhijiangwei) and zhijiangwei:getHandcardNum() == 1 and
        self:getEnemyNumBySeat(self.player, zhijiangwei) <= (zhijiangwei:getHp() >= 3 and 1 or 0) then
        local isGood
        for _, enemy in ipairs(self.enemies) do
            local def = sgs.getDefenseSlash(enemy)
            local slash = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
            local eff = self:slashIsEffective(slash, enemy, zhijiangwei) and sgs.isGoodTarget(enemy, self.enemies, self)
            if zhijiangwei:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, zhijiangwei) and eff and def <
                4 then
                isGood = true
            end
        end
        if isGood and add_player(zhijiangwei, 1) == LuaLiezhi_mark then
            return parseLuaLiezhiCard()
        end
    end

    local goodSkills = {'jijiu', 'qingnang', 'xinzhan', 'leiji', 'jieyin', 'beige', 'kanpo', 'liuli', 'qiaobian',
                        'zhiheng', 'guidao', 'longhun', 'xuanfeng', 'tianxiang', 'noslijian', 'lijian'}

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        local x = p:getHandcardNum()
        local good_target = true
        local cards = sgs.QList2Table(p:getHandcards())
        local flag = string.format('%s_%s_%s', 'visible', self.player:objectName(), p:objectName())
        for _, card in ipairs(cards) do
            if (card:hasFlag('visible') or card:hasFlag(flag)) and
                (card:isKindOf('Peach') or card:isKindOf('Nullification') or card:isKindOf('Analeptic')) then
                if add_player(p) == LuaLiezhi_mark then
                    return parseLuaLiezhiCard()
                end
            end
        end
        if p:hasSkills(table.concat(goodSkills, '|')) then
            if add_player(p) == LuaLiezhi_mark then
                return parseLuaLiezhiCard()
            end
        end
        if x == 1 and self:needKongcheng(p) then
            good_target = false
        end
        if x >= 2 and p:hasSkill('tuntian') and p:hasSkill('zaoxian') then
            good_target = false
        end
        if x >= 2 and p:hasSkill('LuaTuntian') and p:hasSkill('LuaZaoxian') then
            good_target = false
        end
        if good_target and add_player(p) == LuaLiezhi_mark then
            return parseLuaLiezhiCard()
        end
    end

    local others = self.room:getOtherPlayers(self.player)
    for _, other in sgs.qlist(others) do
        if self:objectiveLevel(other) >= 0 and not (other:hasSkill('tuntian') and other:hasSkill('zaoxian')) and
            add_player(other) == LuaLiezhi_mark then
            return parseLuaLiezhiCard()
        end
    end

    for _, other in sgs.qlist(others) do
        if self:objectiveLevel(other) >= 0 and not (other:hasSkill('tuntian') and other:hasSkill('zaoxian')) and
            math.random(0, 5) <= 1 and not self:hasSkills('qiaobian') then
            add_player(other)
        end
    end

    return parseLuaLiezhiCard()
end

sgs.ai_card_intention.LuaLiezhiCard = function(self, card, from, tos)
    local lord = getLord(self.player)
    local LuaLiezhi_lord = false
    if sgs.evaluatePlayerRole(from) == 'neutral' and sgs.evaluatePlayerRole(tos[1]) == 'neutral' and
        (not tos[2] or sgs.evaluatePlayerRole(tos[2]) == 'neutral') and lord and not lord:isKongcheng() and
        not (self:needKongcheng(lord) and lord:getHandcardNum() == 1) and self:hasLoseHandcardEffective(lord) and
        not (lord:hasSkill('tuntian') and lord:hasSkill('zaoxian')) and from:aliveCount() >= 4 then
        sgs.updateIntention(from, lord, -80)
        return
    end
    if from:getState() == 'online' then
        for _, to in ipairs(tos) do
            if not (to:hasSkill('kongcheng') or to:hasSkill('lianying') or to:hasSkill('zhiji') or
                (to:hasSkill('tuntian') and to:hasSkill('zaoxian')) or
                ((to:hasSkill('LuaTuntian') and to:hasSkill('LuaZaoxian')))) then
                sgs.updateIntention(from, to, 80)
            end
        end
    else
        for _, to in ipairs(tos) do
            if lord and to:objectName() == lord:objectName() then
                LuaLiezhi_lord = true
            end
            local intention = from:hasFlag('LuaLiezhi_isfriend_' .. to:objectName()) and -5 or 80
            sgs.updateIntention(from, to, intention)
        end
        if sgs.turncount == 1 and not LuaLiezhi_lord and lord and not lord:isKongcheng() and
            from:getRoom():alivePlayerCount() > 2 then
            sgs.updateIntention(from, lord, -80)
        end
    end
end

-- 界钟会
-- 权计发动
sgs.ai_skill_invoke.LuaQuanji = function(self, data)
    local current = self.room:getCurrent()
    local current_available = current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive
    if not current_available then
        return true
    end
    local juece_effect = (not self:isFriend(current)) and current:hasSkill('juece')
    local manjuan_effect = hasManjuanEffect(self.player) or playerHasManjuanEffect(self.player)
    if self.player:isKongcheng() then
        if manjuan_effect or juece_effect then
            return false
        end
    elseif self.player:getHandcardNum() == 1 then
        if manjuan_effect and juece_effect then
            return false
        end
    end
    return true
end

sgs.ai_skill_discard.LuaQuanji = function(self)
    local to_discard = {}
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)

    table.insert(to_discard, cards[1]:getEffectiveId())

    return to_discard
end

sgs.ai_skill_choice.LuaZili = function(self, choice)
    -- 列表项
    -- zilirecover 回血
    -- zilidraw 摸牌
    local items = choice:split('+')
    if self.player:getHp() < self.player:getMaxHp() - 1 then
        return items[1]
    end
    return items[2]
end

-- 排异
local LuaPaiyi_skill = {}
LuaPaiyi_skill.name = 'LuaPaiyi'
table.insert(sgs.ai_skills, LuaPaiyi_skill)
LuaPaiyi_skill.getTurnUseCard = function(self)
    if self.player:getPile('power'):isEmpty() then
        return nil
    end
    local room = self.room
    local all_used = true
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if not p:hasFlag('LuaPaiyiUsed') then
            all_used = false
            break
        end
    end
    if all_used then
        return nil
    end
    -- 保留一定的权数量
    local extraMaxCard = self.player:getHandcardNum() > self.player:getHp() and 1 or 0
    local maxCards = self.player:getMaxCards() + extraMaxCard
    if self.player:getPile('power'):length() <= maxCards then
        return sgs.Card_Parse('#LuaPaiyiCard:' .. self.player:getPile('power'):first() .. ':')
    end
    return nil
end

sgs.ai_skill_use_func['#LuaPaiyiCard'] = function(card, use, self)
    local target
    self:sort(self.friends_noself, 'defense')
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHandcardNum() < 2 and friend:getHandcardNum() + 1 < self.player:getHandcardNum() and
            not self:needKongcheng(friend, true) and not playerHasManjuanEffect(friend) and
            not friend:hasFlag('LuaPaiyiUsedFlag') then
            target = friend
        end
        if target then
            break
        end
    end
    if not target then
        if not self.player:hasFlag('LuaPaiyiUsedFlag') and self.player:getHandcardNum() < self.player:getHp() +
            self.player:getPile('power'):length() - 1 then
            target = self.player
        end
    end
    self:sort(self.friends_noself, 'hp')
    self.friends_noself = sgs.reverse(self.friends_noself)
    if not target then
        for _, friend in ipairs(self.friends_noself) do
            if friend:getHandcardNum() + 2 > self.player:getHandcardNum() and
                (self:getDamagedEffects(friend, self.player) or self:needToLoseHp(friend, self.player, nil, true)) and
                not playerHasManjuanEffect(friend) and not friend:hasFlag('LuaPaiyiUsedFlag') then
                target = friend
            end
            if target then
                break
            end
        end
    end
    self:sort(self.enemies, 'defense')
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if playerHasManjuanEffect(enemy) and
                not (self:hasSkills(sgs.masochism_skill, enemy) and not self.player:hasSkill('jueqing')) and
                self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and
                not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy)) and enemy:getHandcardNum() >
                self.player:getHandcardNum() and not enemy:hasFlag('LuaPaiyiUsedFlag') then
                target = enemy
            end
            if target then
                break
            end
        end
        if not target then
            for _, enemy in ipairs(self.enemies) do
                if not (self:hasSkills(sgs.masochism_skill, enemy) and not self.player:hasSkill('jueqing')) and
                    not enemy:hasSkills(sgs.cardneed_skill .. '|jijiu|tianxiang|buyi') and
                    self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(enemy) and
                    not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy)) and
                    enemy:getHandcardNum() + 2 > self.player:getHandcardNum() and not enemy:hasSkill('manjuan') and
                    not enemy:hasFlag('LuaPaiyiUsedFlag') then
                    target = enemy
                end
                if target then
                    break
                end
            end
        end
    end

    if target then
        use.card = sgs.Card_Parse('#LuaPaiyiCard:' .. self.player:getPile('power'):first() .. ':')
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_card_intention.LuaPaiyiCard = function(self, card, from, tos)
    local to = tos[1]
    if to:objectName() == from:objectName() then
        return
    end
    if not playerHasManjuanEffect(to) and
        ((to:getHandcardNum() < 2 and to:getHandcardNum() + 1 < from:getHandcardNum() and
            not self:needKongcheng(to, true)) or
            (to:getHandcardNum() + 2 > from:getHandcardNum() and
                (self:getDamagedEffects(to, from) or self:needToLoseHp(to, from)))) then
        return
    end
    sgs.updateIntention(from, to, 60)
end

-- 留赞-十周年
-- 力激 
local LuaLiji_skill = {}
LuaLiji_skill.name = 'LuaLiji'
table.insert(sgs.ai_skills, LuaLiji_skill)
LuaLiji_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then
        return nil
    end
    if self.player:usedTimes('#LuaLijiCard') >= self.player:getMark('LuaLijiAvailableTimes') then
        return nil
    end
    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    return sgs.Card_Parse('#LuaLijiCard:' .. cards[1]:getEffectiveId() .. ':')
end

sgs.ai_skill_use_func['#LuaLijiCard'] = function(card, use, self)
    local target
    if #self.enemies <= 0 then
        return
    end
    self:sort(self.enemies, 'defense')
    for _, enemy in ipairs(self.enemies) do
        if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
            target = enemy
            break
        end
    end
    if target then
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByKeepValue(cards)
        use.card = sgs.Card_Parse('#LuaLijiCard:' .. cards[1]:getEffectiveId() .. ':')
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_card_intention.LuaLijiCard = function(self, card, from, tos)
    local to = tos[1]
    sgs.updateIntention(from, to, -80)
end

-- 神郭嘉
-- 慧识
local LuaHuishi_skill = {}
LuaHuishi_skill.name = 'LuaHuishi'

table.insert(sgs.ai_skills, LuaHuishi_skill)

LuaHuishi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMaxHp() >= 10 then
        return nil
    end
    if not self.player:hasUsed('#LuaHuishiCard') then
        return sgs.Card_Parse('#LuaHuishiCard:.:')
    end
    return nil
end

sgs.ai_skill_use_func['#LuaHuishiCard'] = function(card, use, self)
    local card_str = '#LuaHuishiCard:.:'
    local acard = sgs.Card_Parse(card_str)
    assert(acard)
    use.card = acard
end

-- 有什么不继续判定的必要吗
sgs.ai_skill_invoke.LuaHuishi = function(self, data)
    return true
end

-- 无脑给自己
sgs.ai_skill_playerchosen['LuaHuishiCard'] = function(self, targets)
    return nil
end

sgs.ai_use_value['LuaHuishiCard'] = 100
sgs.ai_use_priority['LuaHuishiCard'] = 10

-- 无脑给自己
sgs.ai_skill_playerchosen['LuaTianyi'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets)
    for _, target in ipairs(targets) do
        if target:objectName() == self.player:objectName() then
            return target
        end
    end
end

-- 辉逝
-- 无脑给自己
local LuaHuishiLimit_skill = {}
LuaHuishiLimit_skill.name = 'LuaHuishiLimit'

table.insert(sgs.ai_skills, LuaHuishiLimit_skill)

LuaHuishiLimit_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMaxHp() < 4 or self.player:getLostHp() < 2 then
        return nil
    end
    if self.player:getMark('@LuaHuishiLimit') == 0 then
        return nil
    end
    if (#self.friends <= #self.enemies and sgs.turncount > 2 and self.player:getLostHp() > 1) or
        (sgs.turncount > 1 and self:isWeak()) or (not self:needBear()) then
        return sgs.Card_Parse('#LuaHuishiLimitCard:.:')
    end
end

sgs.ai_skill_use_func['#LuaHuishiLimitCard'] = function(card, use, self)
    local card_str = '#LuaHuishiLimitCard:.:'
    local acard = sgs.Card_Parse(card_str)
    assert(acard)
    use.card = acard
    if use.to then
        use.to:append(self.player)
    end
end

-- 佐幸
local LuaZuoxing_skill = {}
LuaZuoxing_skill.name = 'LuaZuoxing'
table.insert(sgs.ai_skills, LuaZuoxing_skill)
LuaZuoxing_skill.getTurnUseCard = function(self)
    local shenguojia = rinsan.availableShenGuojiaExists(self.player) and self.player or nil
    if not shenguojia then
        for _, p in sgs.qlist(self.player:getAliveSiblings()) do
            if rinsan.availableShenGuojiaExists(p) then
                shenguojia = p
                break
            end
        end
    end
    if not shenguojia or (self:isFriend(shenguojia) and shenguojia:getMaxHp() < 3) then
        return nil
    end
    local aoename = 'savage_assault|archery_attack'
    local aoenames = aoename:split('|')
    local aoe
    local good, bad = 0, 0
    local LuaZuoxingtrick = 'snatch|dismantlement|savage_assault|archery_attack|ex_nihilo|god_salvation'
    local LuaZuoxingtricks = LuaZuoxingtrick:split('|')
    local aoe_available, ge_available, ex_available = true, true, true
    for i = 1, #LuaZuoxingtricks do
        local forbiden = LuaZuoxingtricks[i]
        forbid = sgs.Sanguosha:cloneCard(forbiden, sgs.Card_NoSuit)
        if self.player:isCardLimited(forbid, sgs.Card_MethodUse, true) or not forbid:isAvailable(self.player) then
            if forbid:isKindOf('AOE') then
                aoe_available = false
            end
            if forbid:isKindOf('GlobalEffect') then
                ge_available = false
            end
            if forbid:isKindOf('ExNihilo') then
                ex_available = false
            end
        end
    end
    if self.player:hasUsed('#LuaZuoxingCard') then
        return
    end
    for _, friend in ipairs(self.friends) do
        if friend:isWounded() then
            good = good + 10 / friend:getHp()
            if friend:isLord() then
                good = good + 10 / friend:getHp()
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy:isWounded() then
            bad = bad + 10 / enemy:getHp()
            if enemy:isLord() then
                bad = bad + 10 / enemy:getHp()
            end
        end
    end

    local godsalvation = sgs.Sanguosha:cloneCard('god_salvation', sgs.Card_NoSuit, 0)
    if self.player:getHandcardNum() < 3 then
        if aoe_available then
            for i = 1, #aoenames do
                local newLuaZuoxing = aoenames[i]
                aoe = sgs.Sanguosha:cloneCard(newLuaZuoxing)
                if self:getAoeValue(aoe) > 0 then
                    local parsed_card = sgs.Card_Parse('#LuaZuoxingCard:.:' .. newLuaZuoxing)
                    return parsed_card
                end
            end
        end
        if ge_available and self:willUseGodSalvation(godsalvation) then
            local parsed_card = sgs.Card_Parse('#LuaZuoxingCard:.:' .. 'god_salvation')
            return parsed_card
        end
        if ex_available and self:getCardsNum('Jink') == 0 and self:getCardsNum('Peach') == 0 then
            local parsed_card = sgs.Card_Parse('#LuaZuoxingCard:.:' .. 'ex_nihilo')
            return parsed_card
        end
    end

    if aoe_available then
        for i = 1, #aoenames do
            local newLuaZuoxing = aoenames[i]
            aoe = sgs.Sanguosha:cloneCard(newLuaZuoxing)
            if self:getAoeValue(aoe) > -5 then
                local parsed_card = sgs.Card_Parse('#LuaZuoxingCard:.:' .. newLuaZuoxing)
                return parsed_card
            end
        end
    end

    if self:getCardsNum('Jink') == 0 and self:getCardsNum('Peach') == 0 and self:getCardsNum('Analeptic') == 0 and
        self:getCardsNum('Nullification') == 0 and self.player:getHandcardNum() <= 3 then
        if ge_available and self:willUseGodSalvation(godsalvation) and self.player:isWounded() then
            local parsed_card = sgs.Card_Parse('#LuaZuoxingCard:.:' .. 'god_salvation')
            return parsed_card
        end
        if ex_available then
            local parsed_card = sgs.Card_Parse('#LuaZuoxingCard:.:' .. 'ex_nihilo')
            return parsed_card
        end
    end
    local zuoxingCard = LuaZuoxingtricks[rinsan.random(1, #LuaZuoxingtricks)]
    return sgs.Card_Parse('#LuaZuoxingCard:.:' .. zuoxingCard)
end

sgs.ai_skill_use_func['#LuaZuoxingCard'] = function(card, use, self)
    local userstring = card:toString()
    userstring = (userstring:split(':'))[4]
    local LuaZuoxingcard = sgs.Sanguosha:cloneCard(userstring, sgs.Card_NoSuit, 0)
    LuaZuoxingcard:setSkillName('LuaZuoxing')
    self:useTrickCard(LuaZuoxingcard, use)
    if use.card then
        for _, acard in sgs.qlist(self.player:getHandcards()) do
            if isCard('Peach', acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded() and
                not self:needToLoseHp(self.player) then
                use.card = acard
                return
            end
        end
        use.card = card
    end
end

-- 略高于慧识
sgs.ai_use_value['LuaZuoxingCard'] = 110
sgs.ai_use_priority['LuaZuoxingCard'] = 20

-- 是否应该发动烈弓
local function shouldInvokeLiegong(room, from, to, slash)
    if not from or not to then
        self.room:writeToConsole(debug.traceback())
        return false
    end
    if not from:hasSkill('jueqing') and (to:hasArmorEffect('silver_lion') and not IgnoreArmor(from, to)) then
        return false
    end
    local jiaren_zidan = room:findPlayerBySkillName('jgchiying')
    if jiaren_zidan and jiaren_zidan:getRole() == to:getRole() then
        return false
    end
    -- 标记太少也没必要发动
    if rinsan.getLiegongSuitNum(from) <= 2 then
        return false
    end
    return true
end

-- 获取 from 可见 to 的实体【闪】数量
local function getJinkNum(from, to)
    local heartJink, diamondJink = 0, 0
    local flag = string.format('%s_%s_%s', 'visible', from:objectName(), to:objectName())
    local cards = sgs.QList2Table(to:getHandcards())
    for _, cd in ipairs(cards) do
        if (cd:hasFlag('visible') or cd:hasFlag(flag)) and cd:isKindOf('Jink') then
            if cd:getSuit() == sgs.Card_Heart then
                heartJink = heartJink + 1
            elseif cd:getSuit() == sgs.Card_Diamond then
                diamondJink = diamondJink + 1
            end
        end
    end
    return heartJink, diamondJink
end

-- 是否可以用【闪】相应对应的【杀】
local function targetCanUseJink(source, target)
    -- 【万能】和【卫境】可以出无色闪
    if target:hasSkill('LuaWanneng') and target:getMark('LuaWanneng') == 0 then
        return true
    end
    if target:hasSkill('weijing') and target:getMark('weijing_lun') == 0 then
        return true
    end
    -- 【翊赞】在未觉醒状态下可以无色
    if target:hasSkill('LuaYizan') and target:getMark('LuaLongyuan') == 0 then
        return true
    end
    -- 【倾国】、【蛊惑】、觉醒后【翊赞】、【龙胆】可以四种花色转换，因此判断 4
    if target:hasSkills('qingguo|guhuo|LuaYizan|longdan|kofqingguo') then
        if rinsan.getLiegongSuitNum(source) >= 4 then
            return true
        end
    end
    -- 【龙魂】可以转换梅花
    if target:hasSkills('LuaLonghun|longhun') then
        if rinsan.getLiegongSuitNum(source) >= 4 or
            (rinsan.getLiegongSuitNum(source) == 3 and source:getMark('@LuaLiegongSpade') == 0) then
            return true
        end
    end

    -- 如果不曾拥有上述技能，则单独判断是否有对应颜色的闪
    local heartJink, diamondJink = getJinkNum(source, target)
    if heartJink > 0 and source:getMark('@LuaLiegongHeart') == 0 then
        return true
    end

    if diamondJink > 0 and source:getMark('@LuaLiegongDiamond') == 0 then
        return true
    end

    -- 最稳妥的，如果都有就一定闪不了了
    if source:getMark('@LuaLiegongDiamond') > 0 and source:getMark('@LuaLiegongHeart') > 0 then
        -- 八卦有概率，保险起见还是9：1概率
        if target:hasArmorEffect('eight_diagram') then
            local randomNum = rinsan.random(1, 10)
            if randomNum == 10 then
                return true
            end
        end
        return false
    end

    -- 赌一赌，73开概率
    return rinsan.random(1, 10) > 7
end

-- 谋黄忠
-- 是否发动烈弓
sgs.ai_skill_invoke.LuaLiegong = function(self, data)
    local use = data:toCardUse()
    local source = self.player
    local target = use.to:at(0)
    local slash = use.card
    if self:isFriend(target) then
        return false
    end
    -- 保守估计，如果对面可以出闪就不发动
    if targetCanUseJink(source, target) then
        return false
    end
    return shouldInvokeLiegong(self.room, self.player, target, slash)
end

-- 张济
-- 暂不考虑屯军

-- 掠命
local LuaLveming_skill = {}
LuaLveming_skill.name = 'LuaLveming'
table.insert(sgs.ai_skills, LuaLveming_skill)
LuaLveming_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed('#LuaLvemingCard') then
        return nil
    end
    return sgs.Card_Parse('#LuaLvemingCard:.:')
end

sgs.ai_skill_use_func['#LuaLvemingCard'] = function(card, use, self)
    local target
    if #self.enemies <= 0 then
        return
    end
    self:sort(self.enemies, 'defense')
    local selfEquipLength = self.player:getEquips():length()
    for _, enemy in ipairs(self.enemies) do
        if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not enemy:isNude() and
            enemy:getEquips():length() < selfEquipLength then
            target = enemy
            break
        end
    end
    if target then
        use.card = sgs.Card_Parse('#LuaLvemingCard:.:')
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_card_intention.LuaLvemingCard = function(self, card, from, tos)
    local to = tos[1]
    sgs.updateIntention(from, to, -80)
end

-- 掠命选项
sgs.ai_skill_choice.LuaLveming = function(self, choices)
    local items = choices:split('+')
    return items[math.random(1, #items)]
end

sgs.ai_use_value['LuaLvemingCard'] = 19.6
sgs.ai_use_priority['LuaLvemingCard'] = 15.3

-- 界陈群
-- 定品
local LuaDingpin_skill = {}
LuaDingpin_skill.name = 'LuaDingpin'
table.insert(sgs.ai_skills, LuaDingpin_skill)
LuaDingpin_skill.getTurnUseCard = function(self, inclusive)
    sgs.ai_use_priority['LuaDingpinCard'] = 0
    local cardTypes = {'basic', 'trick', 'equip'}
    local all_unavailable = true
    for _, cardType in ipairs(cardTypes) do
        if not self.player:hasFlag('LuaDingpinCard' .. cardType) then
            all_unavailable = false
            break
        end
    end
    if all_unavailable then
        return
    end
    if not self.player:canDiscard(self.player, 'h') then
        return false
    end
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if not p:hasFlag('LuaDingpinSucceed') and p:getHp() >= 2 then
            if not self:toTurnOver(self.player) then
                sgs.ai_use_priority['LuaDingpinCard'] = 8.9
            end
            return sgs.Card_Parse('#LuaDingpinCard:.:')
        end

    end
end
sgs.ai_skill_use_func['#LuaDingpinCard'] = function(_card, use, self)
    local cards = {}
    local cardType = {}
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if not self.player:hasFlag('LuaDingpinCard' .. card:getType()) then
            table.insert(cards, card)
            if not table.contains(cardType, card:getTypeId()) then
                table.insert(cardType, card:getTypeId())
            end
        end
    end
    for _, id in sgs.qlist(self.player:getPile('wooden_ox')) do
        local card = sgs.Sanguosha:getCard(id)
        if not self.player:hasFlag('LuaDingpinCard' .. card:getType()) then
            table.insert(cards, card)
            if not table.contains(cardType, card:getTypeId()) then
                table.insert(cardType, card:getTypeId())
            end
        end
    end
    if #cards == 0 then
        return
    end
    self:sortByUseValue(cards, true)
    if self:isValuableCard(cards[1]) then
        return
    end

    if #cardType > 1 or not self:toTurnOver(self.player) then
        self:sort(self.friends)
        for _, friend in ipairs(self.friends) do
            if not friend:hasFlag('LuaDingpinSucceed') and friend:getHp() >= 2 then
                use.card = sgs.Card_Parse('#LuaDingpinCard:' .. cards[1]:getEffectiveId() .. ':')
                if use.to then
                    use.to:append(friend)
                end
                return
            end
        end
    end
end

sgs.ai_use_priority['LuaDingpinCard'] = 0
sgs.ai_card_intention['LuaDingpinCard'] = -10

-- 法恩
sgs.ai_skill_invoke.LuaFaen = function(self, data)
    local player = data:toPlayer()
    if self:needKongcheng(player, true) then
        return not self:isFriend(player)
    end
    return self:isFriend(player)
end

sgs.ai_choicemade_filter.skillInvoke.LuaFaen = function(self, player, promptlist)
    local target = findPlayerByObjectName(self.room, promptlist[#promptlist - 1])
    if not target then
        return
    end
    local yes = promptlist[#promptlist] == 'yes'
    if self:needKongcheng(target, true) then
        sgs.updateIntention(player, target, yes and 10 or -10)
    else
        sgs.updateIntention(player, target, yes and -10 or 10)
    end
end

-- 陈震
-- 歃盟
local LuaShameng_skill = {}
LuaShameng_skill.name = 'LuaShameng'
table.insert(sgs.ai_skills, LuaShameng_skill)
LuaShameng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed('#LuaShamengCard') or self.player:getHandcardNum() < 2 then
        return nil
    end
    local red, black = 0, 0
    for _, cd in sgs.qlist(self.player:getHandcards()) do
        if cd:isRed() then
            red = red + 1
        elseif cd:isBlack() then
            black = black + 1
        end
    end
    if red > 1 or black > 1 then
        return sgs.Card_Parse('#LuaShamengCard:.:')
    end
    return nil
end

sgs.ai_skill_use_func['#LuaShamengCard'] = function(_card, use, self)
    -- 选目标
    self:sort(self.friends_noself)
    local target
    for _, friend in ipairs(self.friends_noself) do
        if not playerHasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
            target = friend
            break
        end
    end

    if not target then
        return
    end

    -- 首先判断整体
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    if #cards >= 2 then
        if cards[1]:sameColorWith(cards[2]) then
            local use_cards = {}
            table.insert(use_cards, cards[1]:getEffectiveId())
            table.insert(use_cards, cards[2]:getEffectiveId())
            use.card = sgs.Card_Parse(string.format('#LuaShamengCard:%s:', table.concat(use_cards, '+')))
            if use.to then
                use.to:append(target)
                return
            end
        end
    end

    -- 单独判断红黑
    local redCards, blackCards = {}, {}
    for _, cd in sgs.qlist(self.player:getHandcards()) do
        if cd:isRed() then
            table.insert(redCards, cd)
        elseif cd:isBlack() then
            table.insert(blackCards, cd)
        end
    end
    -- 都不满足条件，返回
    if #redCards < 2 and #blackCards < 2 then
        return
    end

    self:sortByUseValue(redCards, true)
    self:sortByUseValue(blackCards, true)

    -- 红色够牌
    if #blackCards < 2 then
        -- 最不值的都有价值，返回
        if self:isValuableCard(redCards[1]) then
            return
        end
        local use_cards = {}
        table.insert(use_cards, redCards[1]:getEffectiveId())
        table.insert(use_cards, redCards[2]:getEffectiveId())
        use.card = sgs.Card_Parse(string.format('#LuaShamengCard:%s:', table.concat(use_cards, '+')))
        if use.to then
            use.to:append(target)
            return
        end
    end
    -- 黑色够牌
    if #redCards < 2 then
        -- 最不值的都有价值，返回
        if self:isValuableCard(blackCards[1]) then
            return
        end
        local use_cards = {}
        table.insert(use_cards, blackCards[1]:getEffectiveId())
        table.insert(use_cards, blackCards[2]:getEffectiveId())
        use.card = sgs.Card_Parse(string.format('#LuaShamengCard:%s:', table.concat(use_cards, '+')))
        if use.to then
            use.to:append(target)
            return
        end
    end
    -- 单独处理两个都有
    if #redCards < 2 or #blackCards < 2 then
        return
    end
    local redValue = self:getUseValue(redCards[1]) + self:getUseValue(redCards[2])
    local blackValue = self:getUseValue(blackCards[1]) + self:getUseValue(blackCards[2])
    local useRed = (redValue < blackValue) and not self:isValuableCard(redCards[1])
    local useBlack = (redValue >= blackValue) and not self:isValuableCard(blackCards[1])
    if useRed and useBlack then
        -- 一般而言红色牌更有价值
        if redValue - blackValue > 1 then
            useRed = false
        end
    end
    if useBlack then
        local use_cards = {}
        table.insert(use_cards, blackCards[1]:getEffectiveId())
        table.insert(use_cards, blackCards[2]:getEffectiveId())
        use.card = sgs.Card_Parse(string.format('#LuaShamengCard:%s:', table.concat(use_cards, '+')))
        if use.to then
            use.to:append(target)
            return
        end
    end
    if useRed then
        local use_cards = {}
        table.insert(use_cards, redCards[1]:getEffectiveId())
        table.insert(use_cards, redCards[2]:getEffectiveId())
        use.card = sgs.Card_Parse(string.format('#LuaShamengCard:%s:', table.concat(use_cards, '+')))
        if use.to then
            use.to:append(target)
            return
        end
    end
end

-- 星徐晃
-- 治严
local LuaZhiyan_skill = {}
LuaZhiyan_skill.name = 'LuaZhiyan'
table.insert(sgs.ai_skills, LuaZhiyan_skill)
LuaZhiyan_skill.getTurnUseCard = function(self, inclusive)
    local LuaZhiyanDrawAvailable = not self.player:hasUsed('#LuaZhiyanDrawCard') and self.player:getMaxHp() >
                                       self.player:getHandcardNum()
    local LuaZhiyanGiveAvailable = not self.player:hasUsed('#LuaZhiyanGiveCard') and self.player:getHandcardNum() >
                                       self.player:getHp()
    if (not LuaZhiyanDrawAvailable) and (not LuaZhiyanGiveAvailable) then
        return nil
    end

    -- 可摸可给的情况下，优先给出去，因此先判断能不能给
    if LuaZhiyanGiveAvailable and not self.player:isKongcheng() then
        return sgs.Card_Parse('#LuaZhiyanGiveCard:.:')
    elseif LuaZhiyanDrawAvailable then
        return sgs.Card_Parse('#LuaZhiyanDrawCard:.:')
    end
    return nil
end
-- 治严给牌
sgs.ai_skill_use_func['#LuaZhiyanGiveCard'] = function(_card, use, self)
    -- 选目标
    self:sort(self.friends_noself)
    local target
    local giveToNonFriend
    -- 优先友军
    for _, friend in ipairs(self.friends_noself) do
        if not playerHasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
            target = friend
            break
        end
    end
    -- 其次扔废牌给马良或者星SP庞统一类的
    if not target then
        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if not self:isFriend(p) and playerHasManjuanEffect(p) then
                target = p
                giveToNonFriend = true
                break
            end
        end
    end

    if not target then
        return
    end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    if giveToNonFriend and self:isValuableCard(cards[1]) then
        return
    end
    local x = self.player:getHandcardNum() - self.player:getHp()
    if x <= 0 then
        return
    end
    local i = 1
    local use_cards = {}
    while i <= x do
        table.insert(use_cards, cards[i]:getEffectiveId())
        i = i + 1
    end
    use.card = sgs.Card_Parse(string.format('#LuaZhiyanGiveCard:%s:', table.concat(use_cards, '+')))
    if use.to then
        use.to:append(target)
    end
end

-- 治严摸牌
sgs.ai_skill_use_func['#LuaZhiyanDrawCard'] = function(_card, use, self)
    -- 要是还有会使用的手牌，就暂时不摸
    for _, cd in sgs.qlist(self.player:getHandcards()) do
        local dummy_use = {
            isDummy = true
        }
        self:useCardByClassName(cd, dummy_use)
        if dummy_use.card then
            return
        end
    end
    use.card = sgs.Card_Parse('#LuaZhiyanDrawCard:.:')
end

-- 治严给牌
sgs.ai_use_value['LuaZhiyanGiveCard'] = 9
sgs.ai_use_priority['LuaZhiyanGiveCard'] = 8.3

-- 获取牌可造成伤害类型，暂不考虑其他技能造成的影响
local function getDamageType(card)
    if card:isKindOf('ThunderSlash') then
        return sgs.DamageStruct_Thunder
    elseif card:isKindOf('FireSlash') or card:isKindOf('FireAttack') then
        return sgs.DamageStruct_Fire
    end
    return sgs.DamageStruct_Normal
end

-- 曹婴
-- 凌人选择目标
sgs.ai_skill_playerchosen['LuaLingren'] = function(self, targets)
    local card = self.player:getTag('LuaLingrenAIData'):toCard()
    targets = sgs.QList2Table(targets)
    self:sort(targets, 'defense')
    for _, target in ipairs(targets) do
        if not self:isFriend(target) and self:damageIsEffective(target, getDamageType(card), self.player) then
            return target
        end
    end
    return nil
end

sgs.ai_skill_choice['BasicCardGuess'] = function(self, choices, data)
    local result = data:toIntList()
    local basic, unknown, basicRemain = result:at(0), result:at(3), result:at(4)
    local totalRemain = result:at(4) + result:at(5) + result:at(6)
    local turnCount = result:at(7)
    if basic > 0 then
        return 'Have'
    elseif unknown == 0 then
        return 'NotHave'
    end
    -- 计算剩余牌中有基本牌概率
    local probably = rinsan.calculateProbably(unknown, basicRemain, totalRemain, rinsan.BASIC_CARD, turnCount)
    return rinsan.random(1, 100) <= (probably * 100) and 'Have' or 'NotHave'
end

sgs.ai_skill_choice['TrickCardGuess'] = function(self, choices, data)
    local result = data:toIntList()
    local trick, unknown, trickRemain = result:at(1), result:at(3), result:at(5)
    local totalRemain = result:at(4) + result:at(5) + result:at(6)
    local turnCount = result:at(7)
    if trick > 0 then
        return 'Have'
    elseif unknown == 0 then
        return 'NotHave'
    end
    -- 计算剩余牌中有锦囊牌概率
    local probably = rinsan.calculateProbably(unknown, trickRemain, totalRemain, rinsan.TRICK_CARD, turnCount)
    return rinsan.random(1, 100) <= (probably * 100) and 'Have' or 'NotHave'
end

sgs.ai_skill_choice['EquipCardGuess'] = function(self, choices, data)
    local result = data:toIntList()
    local equip, unknown, equipRemain = result:at(2), result:at(3), result:at(6)
    local totalRemain = result:at(4) + result:at(5) + result:at(6)
    local turnCount = result:at(7)
    if equip > 0 then
        return 'Have'
    elseif unknown == 0 then
        return 'NotHave'
    end
    -- 计算剩余牌中有装备牌概率
    local probably = rinsan.calculateProbably(unknown, equipRemain, totalRemain, rinsan.EQUIP_CARD, turnCount)
    return rinsan.random(1, 100) <= (probably * 100) and 'Have' or 'NotHave'
end

-- 奸雄在不需要空城时发动
sgs.ai_skill_invoke.LuaJianxiong = function(self, data)
    return not self:needKongcheng(self.player, true)
end

-- 行殇默认发动
sgs.ai_skill_invoke.LuaXingshang = true

-- 王粲
-- 七哀
local LuaQiai_skill = {}
LuaQiai_skill.name = 'LuaQiai'
table.insert(sgs.ai_skills, LuaQiai_skill)
LuaQiai_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed('#LuaQiaiCard') then
        return nil
    end
    return sgs.Card_Parse('#LuaQiaiCard:.:')
end

sgs.ai_skill_use_func['#LuaQiaiCard'] = function(_card, use, self)
    local cards = {}
    for _, cd in sgs.qlist(self.player:getHandcards()) do
        if not cd:isKindOf('BasicCard') then
            table.insert(cards, cd)
        end
    end
    if #cards == 0 then
        return
    end
    self:sortByUseValue(cards, true)
    if self:isValuableCard(cards[1]) then
        return
    end

    -- 优先扔队友
    local target
    for _, friend in ipairs(self.friends_noself) do
        if not playerHasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
            target = friend
            break
        end
    end
    if target then
        use.card = sgs.Card_Parse(string.format('#LuaQiaiCard:%s:', cards[1]:getEffectiveId()))
        if use.to then
            use.to:append(target)
        end
        return
    end

    -- 其次选中立
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if not self:isEnemy(p) then
            target = p
            break
        end
    end
    if target then
        use.card = sgs.Card_Parse(string.format('#LuaQiaiCard:%s:', cards[1]:getEffectiveId()))
        if use.to then
            use.to:append(target)
        end
        return
    end
end

-- 善檄选择目标
sgs.ai_skill_playerchosen['LuaShanxi'] = function(self, targets)
    local result
    targets = sgs.QList2Table(targets)
    self:sort(targets, 'hp')
    for _, target in ipairs(targets) do
        if self:isEnemy(target) then
            result = target
            break
        end
    end
    if result then
        return result
    end
    for _, target in ipairs(targets) do
        if not self:isFriend(target) then
            result = target
            break
        end
    end
    return result
end

-- 七哀选择
sgs.ai_skill_choice['LuaQiai'] = function(self, choices, data)
    local items = choices:split('+')
    if #items == 1 then
        return items[1]
    end
    -- 存在两个分别是摸牌和回血
    local target = data:toPlayer()
    if self:isFriend(target) then
        -- 如果是队友，那么就在他不需要输出的时候让他回血
        if target:getLostHp() > 1 and target:getHandcardNum() >= target:getMaxCards() / 2 then
            return items[2]
        end
        return items[1]
    end
    -- 非友随机
    return items[random(1, #items)]
end
