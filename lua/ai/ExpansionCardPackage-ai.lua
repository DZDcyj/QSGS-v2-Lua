-- 扩展卡牌包 AI
-- Created by DZDcyj at 2022/12/29
-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function hasTrickEffective(self, card, to, from)
    if card:isKindOf('IndirectCombination') and to:hasSkill('LuaTianzuo') then
        return false
    end
    return self:hasTrickEffective(card, to, from)
end

-- AI 是否使用【无懈可击】对抗【奇正相生】
sgs.ai_nullification['IndirectCombination'] = function(self, trick, from, to, positive)
    -- positive 参数为 true 时，响应的是对应的【奇正相生】
    -- 为 false 时，则为对应的【无懈可击】
    local null_num = self:getCardsNum('Nullification')
    if positive then
        if self:isFriend(to) then
            -- 没牌还不怕伤害，不用交
            if to:isNude() and not self:damageIsEffective(to, sgs.DamageStruct_Normal, from) then
                return false
            end
            -- 友方威胁牌、价值牌、最后一张手牌、友方较弱->命中
            if self:getDangerousCard(to) or self:getValuableCard(to) or self:isWeak(to) then
                return true
            end
            -- 三七开使用概率
            return rinsan.random(1, 10) <= 3
        end
    else
        -- 是否使用【无懈可击】对抗【无懈可击】
        if not self:isEnemy(to) then
            return false
        end
        if self:isEnemy(to) and (self:isWeak(to) or null_num > 1 or self:getOverflow() > 0 or not self:isWeak()) then
            return true
        end
    end
    return false
end

sgs.ai_skill_choice['indirect_combination'] = function(self, choices, data)
    -- 虽然按理来讲应该根据情形判断优劣
    -- 但是偶尔还是简单粗暴最好
    local effect = data:toCardEffect()
    local target = effect.to
    -- 空城就直接怼
    if target:isNude() then
        return 'Indirect'
    end
    local items = choices:split('+')
    return items[rinsan.random(1, #items)]
end

-- 【奇正相生】防御方
sgs.ai_skill_choice['indirect_combination_defense'] = function(self, choices, data)
    local effect = data:toCardEffect()
    local source = effect.from
    if self:getDangerousCard(self.player) then
        if not self:isWeak() then
            -- 有关键牌且不怕掉血就出【闪】
            if sgs.card_lack[self.player:objectName()]['Jink'] > 0 then
                -- 如果十分滴缺【闪】
                self.player:setTag('NoResponseForIndirectCombination', sgs.QVariant(true))
            end
            return 'ResponseJink'
        end
    else
        -- 如果没有什么关键牌就出【杀】
        if self:isWeak() then
            return 'ResponseSlash'
        end
    end

    -- 随机
    local items = choices:split('+')
    return items[rinsan.random(1, #items)]
end

-- 奇正相生出牌
sgs.ai_skill_cardask['indirect_combination-card'] = function(self, data, pattern)
    -- 某些情况下直接不出
    if self.player:getTag('NoResponseForIndirectCombination'):toBool() then
        self.player:removeTag('NoResponseForIndirectCombination')
        return '.'
    end
    -- 交由默认处理
    return nil
end

function SmartAI:useCardIndirectCombination(card, use)
    local target
    self:sort(self.enemies, 'defense')
    for _, p in ipairs(self.enemies) do
        if hasTrickEffective(self, card, p, use.from) and
            self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            target = p
            break
        end
    end
    if target then
        use.card = card
        if use.to then
            use.to:append(target)
            return
        end
    end
    local enemies = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(enemies, 'defense')
    for _, p in ipairs(enemies) do
        if not self:isFriend(p) and hasTrickEffective(self, card, p, use.from) and
            (self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) or not p:isKongcheng()) then
            target = p
            break
        end
    end
    if target then
        use.card = card
        if use.to then
            use.to:append(target)
            return
        end
    end
end

sgs.ai_use_value.IndirectCombination = 7.8
sgs.ai_keep_value.IndirectCombination = 3.36
sgs.ai_use_priority.IndirectCombination = 4.6

sgs.ai_card_intention.IndirectCombination = function(self, card, from, tos)
    sgs.updateIntentions(from, tos, 80)
end
