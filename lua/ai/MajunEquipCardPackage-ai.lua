-- 马钧装备包 AI

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
