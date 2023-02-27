-- 始计篇-智包 AI
-- Created by DZDcyj at 2023/2/27

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

-- 七哀具体发动
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

-- 善檄选择交的牌
sgs.ai_skill_discard['LuaShanxi'] = function(self, discard_num, min_num, optional, include_equip)
    -- 诈降
    if not self:isWeak() and self.player:hasSkill('zhaxiang') then
        return {}
    end
    -- 让 SmartAI 处理
    return nil
end

-- 善檄更新 AI 敌友判断
sgs.ai_playerchosen_intention['LuaShanxi'] = function(self, from, to)
    sgs.updateIntention(from, to, -50)
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
local LuaLimitHuishi_skill = {}
LuaLimitHuishi_skill.name = 'LuaLimitHuishi'

table.insert(sgs.ai_skills, LuaLimitHuishi_skill)

LuaLimitHuishi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMaxHp() < 4 or self.player:getLostHp() < 2 then
        return nil
    end
    if self.player:getMark('@LuaLimitHuishi') == 0 then
        return nil
    end
    if (#self.friends <= #self.enemies and sgs.turncount > 2 and self.player:getLostHp() > 1) or
        (sgs.turncount > 1 and self:isWeak()) or (not self:needBear()) then
        return sgs.Card_Parse('#LuaLimitHuishiCard:.:')
    end
end

sgs.ai_skill_use_func['#LuaLimitHuishiCard'] = function(card, use, self)
    local card_str = '#LuaLimitHuishiCard:.:'
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
