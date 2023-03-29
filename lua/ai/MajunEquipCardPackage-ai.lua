-- 马钧装备包 AI
-- Created by DZDcyj at 2023/3/29

-- 是否发动先天八卦阵
-- 均照搬八卦 AI
sgs.ai_skill_invoke.xiantian_eightdiagram = function(self, data)
    local dying = 0
    local handang = self.room:findPlayerBySkillName('nosjiefan')
    for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
        if aplayer:getHp() < 1 and not aplayer:hasSkill('nosbuqu') then
            dying = 1
            break
        end
    end
    if handang and self:isFriend(handang) and dying > 0 then
        return false
    end

    local heart_jink = false
    for _, card in sgs.qlist(self.player:getCards('he')) do
        if card:getSuit() == sgs.Card_Heart and isCard('Jink', card, self.player) then
            heart_jink = true
            break
        end
    end

    if self:hasSkills('tiandu|leiji|nosleiji|gushou') then
        if self.player:hasFlag('dahe') and not heart_jink then
            return true
        end
        if sgs.hujiasource and not self:isFriend(sgs.hujiasource) and
            (sgs.hujiasource:hasFlag('dahe') or self.player:hasFlag('dahe')) then
            return true
        end
        if sgs.lianlisource and not self:isFriend(sgs.lianlisource) and
            (sgs.lianlisource:hasFlag('dahe') or self.player:hasFlag('dahe')) then
            return true
        end
        if self.player:hasFlag('dahe') and handang and self:isFriend(handang) and dying > 0 then
            return true
        end
    end
    if self.player:getHandcardNum() == 1 and self:getCardsNum('Jink') == 1 and self.player:hasSkills('zhiji|beifa') and
        self:needKongcheng() then
        local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
        if self.player:getHp() > enemy_num and enemy_num <= 1 then
            return false
        end
    end
    if handang and self:isFriend(handang) and dying > 0 then
        return false
    end
    if self.player:hasFlag('dahe') then
        return false
    end
    if sgs.hujiasource and (not self:isFriend(sgs.hujiasource) or sgs.hujiasource:hasFlag('dahe')) then
        return false
    end
    if sgs.lianlisource and (not self:isFriend(sgs.lianlisource) or sgs.lianlisource:hasFlag('dahe')) then
        return false
    end
    if self:getDamagedEffects(self.player, nil, true) or self:needToLoseHp(self.player, nil, true, true) then
        return false
    end
    if self:getCardsNum('Jink') == 0 then
        return true
    end
    local zhangjiao = self.room:findPlayerBySkillName('guidao')
    if zhangjiao and self:isEnemy(zhangjiao) then
        if getKnownCard(zhangjiao, self.player, 'black', false, 'he') > 1 then
            return false
        end
        if self:getCardsNum('Jink') > 1 and getKnownCard(zhangjiao, self.player, 'black', false, 'he') > 0 then
            return false
        end
    end
    if self:getCardsNum('Jink') > 0 and self.player:getPile('incantation'):length() > 0 then
        return false
    end
    return true
end

function sgs.ai_armor_value.xiantian_eightdiagram(player, self)
    local haszj = self:hasSkills('guidao', self:getEnemies(player))
    if haszj then
        return 2
    end
    if player:hasSkills('tiandu|leiji|nosleiji|noszhenlie|gushou') then
        return 6
    end

    if self.role == 'loyalist' and self.player:getKingdom() == 'wei' and not self.player:hasSkill('bazhen') and
        getLord(self.player) and getLord(self.player):hasLordSkill('hujia') then
        return 5
    end

    return 4
end

-- 照搬原版仁王盾
function sgs.ai_armor_value.jingang_renwang_shield(player, self)
    if player:hasSkill('yizhong') then
        -- 比毅重强一些
        return 2.5
    end
    if player:hasSkill('bazhen') then
        return 0
    end
    if player:hasSkills('leiji|nosleiji') and getKnownCard(player, self.player, 'Jink', true) > 1 and
        player:hasSkill('guidao') and getKnownCard(player, self.player, 'black', false, 'he') > 0 then
        return 0
    end
    return 4.5
end

-- 桐油百韧甲
function sgs.ai_armor_value.tongyou_vine(player, self)
    if self:needKongcheng(player) and player:getHandcardNum() == 1 then
        return player:hasSkill('kongcheng') and 5 or 3.8
    end
    if self:hasSkills(sgs.lose_equip_skill, player) then
        return 3.8
    end
    if not self:damageIsEffective(player, sgs.DamageStruct_Fire) then
        return 6
    end
    if self.player:hasSkill('sizhan') then
        return 4.9
    end
    if player:hasSkill('jujian') and not player:getArmor() and #(self:getFriendsNoself(player)) > 0 and
        player:getPhase() == sgs.Player_Play then
        return 3
    end
    if player:hasSkill('diyyicong') and not player:getArmor() and player:getPhase() == sgs.Player_Play then
        return 3
    end

    local fslash = sgs.Sanguosha:cloneCard('fire_slash')
    local tslash = sgs.Sanguosha:cloneCard('thunder_slash')
    if player:isChained() and (not self:isGoodChainTarget(player, self.player, nil, nil, fslash) or
        not self:isGoodChainTarget(player, self.player, nil, nil, tslash)) then
        return -2
    end

    for _, enemy in ipairs(self:getEnemies(player)) do
        if (enemy:canSlash(player) and enemy:hasWeapon('fan')) or
            enemy:hasSkills('huoji|longhun|shaoying|zonghuo|wuling') or
            (enemy:hasSkill('yeyan') and enemy:getMark('@flame') > 0) then
            return -2
        end
        if getKnownCard(enemy, player, 'FireSlash', true) >= 1 or getKnownCard(enemy, player, 'FireAttack', true) >= 1 or
            getKnownCard(enemy, player, 'fan') >= 1 then
            return -2
        end
    end

    if (#self.enemies < 3 and sgs.turncount > 2) or player:getHp() <= 2 then
        return 5
    end
    if player:hasSkill('xiansi') and player:getPile('counter'):length() > 1 then
        return 3
    end
    return 0
end
