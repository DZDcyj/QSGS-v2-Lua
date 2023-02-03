-- 扩展卡牌包
-- Created by DZDcyj at 2022/12/29
module('extensions.ExpansionCardPackage', package.seeall)
extension = sgs.Package('ExpansionCardPackage', sgs.Package_CardPack)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 奇正相生
indirect_combination = sgs.CreateTrickCard {
    name = 'indirect_combination',
    class_name = 'IndirectCombination',
    subtype = 'single_target_trick',
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    filter = function(self, selected, to_select)
        return rinsan.checkFilter(selected, to_select, rinsan.EQUAL, 0)
    end,
    feasible = function(self, targets)
        return #targets == 1
    end,
    -- 无需覆写 on_use，否则会造成一系列结算问题
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local data = sgs.QVariant()
        data:setValue(effect)
        -- 正兵或奇兵
        local choice = room:askForChoice(source, self:objectName(), 'Direct+Indirect', data)
        local card = room:askForCard(target, 'Slash,Jink|.|.|.',
            string.format('indirect_combination-card:%s', source:objectName()), sgs.QVariant(), sgs.Card_MethodResponse)
        rinsan.sendLogMessage(room, '#choose', {
            ['from'] = source,
            ['arg'] = choice
        })
        if choice == 'Direct' then
            -- 正兵
            if (not card) or (not card:isKindOf('Jink')) then
                if target:isNude() then
                    return
                end
                rinsan.sendLogMessage(room, '#DirectFailed', {
                    ['from'] = source,
                    ['to'] = target,
                    ['arg'] = 'jink'
                })
                local card_id = room:askForCardChosen(source, target, 'he', self:objectName(), false,
                    sgs.Card_MethodNone)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
                room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, false)
            end
        elseif choice == 'Indirect' then
            -- 奇兵
            if (not card) or (not card:isKindOf('Slash')) then
                rinsan.sendLogMessage(room, '#IndirectFailed', {
                    ['from'] = source,
                    ['to'] = target,
                    ['arg'] = 'slash'
                })
                rinsan.doDamage(room, source, target, 1, sgs.DamageStruct_Normal, self)
            end
        end
    end
}

for i = 2, 9, 1 do
    local card = indirect_combination:clone()
    card:setSuit((i % 2 == 0) and sgs.Card_Spade or sgs.Card_Club)
    card:setNumber(i)
    card:setParent(extension)
end
