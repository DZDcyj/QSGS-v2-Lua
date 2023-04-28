-- 蒲元装备包 AI
-- Created by DZDcyj at 2023/4/27
-- 是否发动混毒弯匕
sgs.ai_skill_invoke.poison_knife = function(self, data)
    local target = data:toPlayer()
    local toLoseHp = math.min(5, self.player:getMark('poison_knife-Clear') + 1)
    if not self:isFriend(target) then
        -- 如果对面没有这种失去体力受益技能，就嗯造
        if not target:hasSkills('LuaMouKurou|zhaxiang') then
            return true
        end
        -- 如果失去体力值大于对面的体力值，也就是需要至少2桃才能救回的情况下，发动
        if toLoseHp > target:getHp() then
            return true
        end
        return false
    end
    -- 队友情况
    if target:hasSkills('LuaMouKurou|zhaxiang') then
        if not self:isWeak(target) then
            return true
        end
    end
    return false
end

-- 天雷刃
sgs.ai_skill_invoke.thunder_blade_skill = function(self, data)
    -- 无脑对非队友发动就完事了
    local target = data:toPlayer()
    return not self:isFriend(target)
end

-- 水波剑选择目标
sgs.ai_skill_playerchosen['ripple_sword'] = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets)
    local use = self.player:getTag('AI-RippleSwordData'):toCardUse()
    local card = use.card
    if card:isKindOf('ExNihilo') then
        local friend = self:findPlayerToDraw(false, 2)
        if friend then
            return friend
        end
    elseif card:isKindOf('Snatch') or card:isKindOf('Dismantlement') then
        local trick = sgs.Sanguosha:cloneCard(use.card:objectName(), use.card:getSuit(), use.card:getNumber())
        local dummy_use = {
            isDummy = true,
            to = sgs.SPlayerList(),
            current_targets = {},
        }
        for _, p in sgs.qlist(use.to) do
            table.insert(dummy_use.current_targets, p:objectName())
        end
        self:useCardSnatchOrDismantlement(trick, dummy_use)
        if dummy_use.card and dummy_use.to:length() > 0 then
            return dummy_use.to:first()
        end
    else
        local slash = sgs.Sanguosha:cloneCard(use.card:objectName(), use.card:getSuit(), use.card:getNumber())
        local dummy_use = {
            isDummy = true,
            to = sgs.SPlayerList(),
            current_targets = {},
        }
        for _, p in sgs.qlist(use.to) do
            table.insert(dummy_use.current_targets, p:objectName())
        end
        self:useCardSlash(slash, dummy_use)
        if dummy_use.card and dummy_use.to:length() > 0 then
            return dummy_use.to:first()
        end
    end
    return nil
end

-- 红缎枪
sgs.ai_skill_invoke.red_satin_spear = function(self, data)
    -- 无脑发动就完事了
    return true
end

-- 烈淬刃
sgs.ai_skill_cardask['@quench_blade'] = function(self, data, pattern, target)
    local damage = data:toDamage()
    if self:isFriend(damage.to) then
        return '.'
    end
    if self.player:isNude() then
        return '.'
    end
    if self:isWeak() or self.player:getCardCount(true) < 2 then
        return '.'
    end
    local cards = {}
    for _, cd in sgs.qlist(self.player:getCards('he')) do
        if cd:objectName() ~= 'quench_blade' then
            table.insert(cards, cd)
        end
    end
    self:sortByKeepValue(cards, true)
    return string.format('$%s', cards[1]:getEffectiveId())
end

function sgs.ai_weapon_value.quench_blade(self, enemy)
	if not enemy then return end
	local value = 2.5
	if enemy:getHandcardNum() < 1 and not enemy:hasArmorEffect('silver_lion') then value = 4.5 end
	return value
end

function sgs.ai_weapon_value.red_satin_spear(self, enemy, player)
	return 3.5
end

function sgs.ai_weapon_value.poison_knife(self, enemy)
    local mark = self.player:getMark('poison_knife-Clear')
    local value = 2
    if enemy:hasSkills('LuaMouKurou|zhaxiang') then
        if mark < enemy:getHp() then
            value = value - 1
        end
    end
    if self.player:hasSkills(sgs.double_slash_skill) then
        value = value + 1
    end
    return value
end

function sgs.ai_weapon_value.thunder_blade(self, enemy)
    local value = 6
    for _, friend in ipairs(self.friends) do
        if friend:hasSkill('zhuji') then
            value = value + 1
        end
    end
    if self.player:hasSkill('zhuji') then
        value = value + 2
    end
    if enemy:hasSkill('hongyan') and (not self.player:isWounded()) then
        value = value - 2
    end
    if not self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) then
        value = value - 4
    end
    if enemy:hasSkills(sgs.wizard_harm_skill) then
        value = value - 3
    end
    return value
end
