-- 蒲元装备包
-- Created by DZDcyj at 2023/4/25
module('extensions.PuyuanEquipCardPackage', package.seeall)
extension = sgs.Package('PuyuanEquipCardPackage', sgs.Package_CardPack)

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

local function weaponTrigger(self, target)
    local weapon = target:getWeapon()
    return target and weapon and weapon:objectName() == self:objectName()
end

local globalTrigger = function(self, target)
    return true
end

local skillList = sgs.SkillList()

-- 混毒弯匕
poison_knife = sgs.CreateWeapon {
    name = 'poison_knife',
    class_name = 'PoisonKnife',
    range = 1,
    suit = sgs.Card_Spade,
    number = 1,
}

poison_knife:setParent(extension)

poison_knife_skill = sgs.CreateTriggerSkill {
    name = 'poison_knife',
    events = {sgs.TargetSpecified},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            for _, t in sgs.qlist(use.to) do
                local data2 = sgs.QVariant()
                data2:setValue(t)
                if room:askForSkillInvoke(player, self:objectName(), data2) then
                    room:addPlayerMark(player, self:objectName() .. '-Clear')
                    local x = math.min(5, player:getMark(self:objectName() .. '-Clear'))
                    room:loseHp(t, x)
                end
            end
        end
    end,
    can_trigger = weaponTrigger,
}

if not sgs.Sanguosha:getSkill('poison_knife') then
    skillList:append(poison_knife_skill)
end

-- 天雷刃
thunder_blade = sgs.CreateWeapon {
    name = 'thunder_blade',
    class_name = 'ThunderKnife',
    range = 4,
    suit = sgs.Card_Spade,
    number = 1,
}

thunder_blade:setParent(extension)

thunder_blade_skill = sgs.CreateTriggerSkill {
    name = 'thunder_blade',
    events = {sgs.TargetSpecified},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            for _, t in sgs.qlist(use.to) do
                local data2 = sgs.QVariant()
                data2:setValue(t)
                if room:askForSkillInvoke(player, self:objectName(), data2) then
                    local judge = rinsan.createJudgeStruct({
                        ['pattern'] = '.|black',
                        ['reason'] = self:objectName(),
                        ['who'] = t,
                        ['play_animation'] = true,
                    })
                    room:judge(judge)
                    if judge:isGood() then
                        if judge.card:getSuit() == sgs.Card_Spade then
                            rinsan.doDamage(room, player, t, 3, sgs.DamageStruct_Thunder)
                            return
                        end
                        rinsan.doDamage(room, player, t, 1, sgs.DamageStruct_Thunder)
                        rinsan.recover(player, 1)
                        player:drawCards(1, self:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = weaponTrigger,
}

if not sgs.Sanguosha:getSkill('thunder_blade') then
    skillList:append(thunder_blade_skill)
end

-- 水波剑
ripple_sword = sgs.CreateWeapon {
    name = 'ripple_sword',
    class_name = 'RippleSword',
    range = 2,
    suit = sgs.Card_Club,
    number = 1,
    on_uninstall = function(self, player)
        if player:isAlive() and player:hasArmorEffect(self:objectName()) then
            rinsan.recover(player)
        end
    end,
}

ripple_sword:setParent(extension)

ripple_sword_skill = sgs.CreateTriggerSkill {
    name = 'ripple_sword',
    events = {sgs.PreCardUsed},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if player:getMark(self:objectName() .. '-Clear') > 1 then
            return false
        end
        local use = data:toCardUse()
        if (not use.card) or (use.card:isKindOf('AOE') or use.card:isKindOf('GlobalEffect')) then
            return false
        end
        if use.card:isNDTrick() or use.card:isKindOf('Slash') then
            if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
                return false
            end
            local available_targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if use.to:contains(p) or room:isProhibited(player, p, use.card) then
                    goto nextPlayer
                end
                if use.card:targetFixed() then
                    available_targets:append(p)
                else
                    if use.card:targetFilter(sgs.PlayerList(), p, player) then
                        available_targets:append(p)
                    end
                end
                ::nextPlayer::
            end
            if available_targets:isEmpty() then
                return false
            end
            local prompt = '@RippleSword-add:::' .. use.card:objectName()
            local extra = room:askForPlayerChosen(player, available_targets, self:objectName(), prompt, true)
            if not extra then
                return false
            end
            rinsan.skill(self, room, player)
            room:addPlayerMark(player, self:objectName() .. '-Clear')
            use.to:append(extra)
            rinsan.sendLogMessage(room, '#QiaoshuiAdd', {
                ['from'] = player,
                ['arg'] = self:objectName(),
                ['to'] = extra,
                ['card_str'] = use.card:toString(),
            })
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), extra:objectName())
            room:sortByActionOrder(use.to)
            data:setValue(use)
        end
    end,
    can_trigger = weaponTrigger,
}

if not sgs.Sanguosha:getSkill('ripple_sword') then
    skillList:append(ripple_sword_skill)
end

-- 红缎枪
red_satin_spear = sgs.CreateWeapon {
    name = 'red_satin_spear',
    class_name = 'RedSatinSpear',
    range = 3,
    suit = sgs.Card_Heart,
    number = 1,
}

red_satin_spear:setParent(extension)

red_satin_spear_skill = sgs.CreateTriggerSkill {
    name = 'red_satin_spear',
    events = {sgs.Damage},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') then
            if player:getMark(self:objectName() .. '-Clear') == 0 then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:addPlayerMark(player, self:objectName() .. '-Clear')
                    local judge = rinsan.createJudgeStruct({
                        ['pattern'] = '.',
                        ['reason'] = self:objectName(),
                        ['who'] = player,
                        ['play_animation'] = true,
                    })
                    room:judge(judge)
                    if judge.card:isRed() then
                        rinsan.recover(player)
                    elseif judge.card:isBlack() then
                        player:drawCards(2, self:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = weaponTrigger,
}

if not sgs.Sanguosha:getSkill('red_satin_spear') then
    skillList:append(red_satin_spear_skill)
end

-- 烈淬刃
quench_blade = sgs.CreateWeapon {
    name = 'quench_blade',
    class_name = 'QuenchBlade',
    range = 2,
    suit = sgs.Card_Diamond,
    number = 1,
}

quench_blade:setParent(extension)

quench_blade_skill_vs = sgs.CreateOneCardViewAsSkill {
    name = 'quench_blade',
    view_filter = function(self, to_select)
        return to_select:objectName() ~= sgs.Self:getWeapon():objectName() and (not sgs.Self:isJilei(to_select))
    end,
    view_as = function(self, card)
        local dummy = sgs.Sanguosha:cloneCard('slash', sgs.Card_NoSuit, 0)
        dummy:addSubcard(card)
        dummy:setSkillName(self:objectName());
        return dummy
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == '@quench_blade'
    end,
}

quench_blade_skill = sgs.CreateTriggerSkill {
    name = 'quench_blade',
    events = {sgs.DamageCaused},
    global = true,
    view_as_skill = quench_blade_skill_vs,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') then
            if player:getMark(self:objectName() .. '-Clear') < 2 then
                local card
                if player:getCardCount(true) >= 2 then
                    card = room:askForCard(player, '@quench_blade', '@quench_blade:' .. damage.to:objectName(), data,
                        self:objectName());
                end
                if card then
                    room:addPlayerMark(player, self:objectName() .. '-Clear')
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end
    end,
    can_trigger = weaponTrigger,
}

quench_blade_target_mod = sgs.CreateTargetModSkill {
    name = 'quench_blade_target_mod',
    frequency = sgs.Skill_Compulsory,
    residue_func = function(self, player)
        if player:getWeapon() and player:getWeapon():objectName() == 'quench_blade' then
            return 1
        else
            return 0
        end
    end,
}

if not sgs.Sanguosha:getSkill('quench_blade') then
    skillList:append(quench_blade_skill)
end

if not sgs.Sanguosha:getSkill('quench_blade_target_mod') then
    skillList:append(quench_blade_target_mod)
end

local PUYUAN_EQUIPS = {
    [1] = 'poison_knife',
    [2] = 'thunder_blade',
    [3] = 'ripple_sword',
    [4] = 'red_satin_spear',
    [5] = 'quench_blade',
}

local function isPuyuanEquip(card)
    return table.contains(PUYUAN_EQUIPS, card:objectName())
end

-- 将蒲元装备包移出游戏
local function removePuyuanEquipsFromPile(room)
    -- 被 Ban 了就不用操作
    if rinsan.isPackageBanned('PuyuanEquipCardPackage') then
        return
    end
    local drawPile = room:getDrawPile()
    local ids = {}
    for _, id in sgs.qlist(drawPile) do
        local cd = sgs.Sanguosha:getCard(id)
        if isPuyuanEquip(cd) then
            table.insert(ids, id)
        end
    end
    for _, id in ipairs(ids) do
        drawPile:removeOne(id)
        room:setCardMapping(id, nil, sgs.Player_DiscardPile)
    end
    room:doBroadcastNotify(rinsan.FixedCommandType['S_COMMAND_UPDATE_PILE'], tostring(drawPile:length()))
end

-- 游戏开始、进入弃牌堆后移除装备牌
LuaMoveOutPuyuanEquips = sgs.CreateTriggerSkill {
    name = 'LuaMoveOutPuyuanEquips',
    events = {sgs.GameStart, sgs.BeforeCardsMove},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            local ids = sgs.IntList()
            if move.to_place == sgs.Player_DiscardPile then
                for _, id in sgs.qlist(move.card_ids) do
                    local cd = sgs.Sanguosha:getCard(id)
                    if isPuyuanEquip(cd) then
                        ids:append(id)
                    end
                end
            end
            if ids:isEmpty() then
                return false
            end
            local places = {}
            for _, id in sgs.qlist(ids) do
                if move.card_ids:contains(id) then
                    places[id] = move.from_places:at(listIndexOf(move.card_ids, id))
                    move.from_places:removeAt(listIndexOf(move.card_ids, id))
                    move.card_ids:removeOne(id)
                    data:setValue(move)
                end
            end
            rinsan.moveOutCardFromGame(ids, player, sgs.Player_PlaceUnknown, sgs.Player_PlaceUnknown, places)
            return false
        end
        if not room:getTag('PuyuanEquipsRemoved'):toBool() then
            removePuyuanEquipsFromPile(room)
            room:setTag('PuyuanEquipsRemoved', sgs.QVariant(true))
        end
        return false
    end,
    can_trigger = globalTrigger,
}

if not sgs.Sanguosha:getSkill('LuaMoveOutPuyuanEquips') then
    skillList:append(LuaMoveOutPuyuanEquips)
end

sgs.Sanguosha:addSkills(skillList)
