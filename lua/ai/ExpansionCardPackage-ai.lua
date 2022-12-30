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
    if not self:isFriend(to) then
        return false
    end
    -- 随机吧，50%概率使用
    return rinsan.random(1, 10) >= 5
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
