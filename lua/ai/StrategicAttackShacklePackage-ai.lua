-- 谋攻篇-虞包 AI
-- Created by DZDcyj at 2023/2/8

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 谋于禁节钺给牌
sgs.ai_skill_discard['LuaMouJieyue'] = function(self, discard_num, min_num, optional, include_equip)
    -- 空城就别给了
    if self.player:isKongcheng() then
        return {}
    end
    -- 始终给最低保留价值的牌
    local cards = sgs.QList2Table(self.player:getCards('he'))
    self:sortByKeepValue(cards, true)
    return {cards[1]:getEffectiveId(), cards[2]:getEffectiveId()}
end

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
