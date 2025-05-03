-- 扩展包 AI
-- Created by DZDcyj at 2021/8/21
-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 漫卷效果技能组
local LuaManjuanEffectSkills = {'manjuan', 'zishu', 'LuaZishu'}

-- 玩家是否有漫卷效果（漫卷、自书等）
function playerHasManjuanEffect(player)
    return player:hasSkills(table.concat(LuaManjuanEffectSkills, '|'))
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
    if armor and rinsan.canBeUpgrade(armor) then
        return sgs.Card_Parse('#LuaJingxie:' .. armor:getEffectiveId() .. ':')
    end
    if weapon and weapon:objectName() == 'crossbow' then
        return sgs.Card_Parse('#LuaJingxie:' .. weapon:getEffectiveId() .. ':')
    end
end

sgs.ai_skill_use_func['#LuaJingxie'] = function(cd, use, self)
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

-- 李傕
-- 李傕暂不考虑【亦算】
sgs.ai_skill_invoke.LuaYisuan = function(self, data)
    return false
end

-- 狼袭
sgs.ai_skill_playerchosen['LuaLangxi'] = function(self, targets)
    self:updatePlayers()
    local realTargets = {}
    for _, p in sgs.qlist(targets) do
        -- damageIsEffective 函数封装了对应的判断逻辑
        if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            table.insert(realTargets, p)
        end
    end
    if #realTargets == 0 then
        return nil
    end
    self:sort(realTargets, 'hp')
    return realTargets[1]
end

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
        local random = rinsan.random(0, 1)
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
                            not enemy:containsTrick('YanxiaoCard') and not self.room:isProhibited(self.player, enemy, judge) and
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
                            not self.room:isProhibited(self.player, friend, judge) and not friend:getJudgingArea():isEmpty() then
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
    local rand = rinsan.random(1, 100)
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
    local target = data:toPlayer()
    -- 不对友军发动
    if self:isFriend(target) then
        return false
    end
    -- 如果自身较弱，且对面打不到自己，就保命
    if self:isWeak() and (not target:inMyAttackRange(self.player)) then
        return false
    end
    -- 判断场上是否有讨灭标记
    local currTaomieTarget
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getMark('@LuaTaomie') > 0 then
            currTaomieTarget = p
            break
        end
    end
    -- 如果存在讨灭标记角色
    if currTaomieTarget then
        -- 如果之前打到友军，就换到这里
        if self:isFriend(currTaomieTarget) then
            return true
        end
        -- 判断防御值
        if sgs.getDefense(currTaomieTarget) > sgs.getDefense(target) then
            return true
        end
        return false
    end
    return true
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
    if self:isFriend(target) then
        return 'cancel'
    end
    if target:hasArmorEffect('silver_lion') then
        -- 有白银狮子效果，只拿牌
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

        if not target and assistTarget and not playerHasManjuanEffect(assistTarget) and assistTarget:getCardCount(true) > 0 and
            not self:needKongcheng(assistTarget, true) then
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
        isDummy = true,
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
            local dummy_use = {
                isDummy = true,
            }
            -- 引入是否会使用卡牌判断，避免纯靠颜色
            self:useCardByClassName(cd, dummy_use)
            if not dummy_use.card then
                if cd:isBlack() then
                    blackCount = blackCount + 1
                elseif cd:isRed() then
                    redCount = redCount + 1
                end
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
    local canInvokeShuangxiong = self.player:hasFlag('LuaShuangxiongRed') or self.player:hasFlag('LuaShuangxiongBlack')
    if not canInvokeShuangxiong then
        return nil
    end
    local mark = 2
    if self.player:hasFlag('LuaShuangxiongRed') then
        mark = 1
    end

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

-- 界贾诩
-- 乱武
LuaLuanwu_skill = {
    name = 'LuaLuanwu',
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
    -- 队友使用的先不发动
    if self:isFriend(use.from) then
        return false
    end
    -- 判断牌是否为好牌，不是就发动
    if card:isKindOf('Peach') or card:isKindOf('AmazingGrace') or card:isKindOf('GodSalvation') or card:isKindOf('ExNihilo') then
        return false
    end
    return true
end

-- 守邺选项
sgs.ai_skill_choice.LuaShouye = function(self, choices)
    local items = choices:split('+')
    return items[rinsan.random(1, #items)]
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

    if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0) and
        dengai:hasSkill('zaoxian') and dengai:getMark('zaoxian') == 0 and dengai:getPile('field'):length() == 2 and
        add_player(dengai, 1) == LuaLiezhi_mark then
        return parseLuaLiezhiCard()
    end

    if jiedengai and self:isFriend(jiedengai) and
        (not self:isWeak(jiedengai) or self:getEnemyNumBySeat(self.player, jiedengai) == 0) and
        jiedengai:hasSkill('LuaZaoxian') and jiedengai:getMark('zaoxian') == 0 and jiedengai:getPile('field'):length() == 2 and
        add_player(jiedengai, 1) == LuaLiezhi_mark then
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
            if zhijiangwei:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, zhijiangwei) and eff and def < 4 then
                isGood = true
            end
        end
        if isGood and add_player(zhijiangwei, 1) == LuaLiezhi_mark then
            return parseLuaLiezhiCard()
        end
    end

    local goodSkills = {'jijiu', 'qingnang', 'xinzhan', 'leiji', 'jieyin', 'beige', 'kanpo', 'liuli', 'qiaobian', 'zhiheng',
                        'guidao', 'longhun', 'xuanfeng', 'tianxiang', 'noslijian', 'lijian'}

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
            rinsan.random(0, 5) <= 1 and not self:hasSkills('qiaobian') then
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
        if p:getMark('LuaPaiyi_biu') == 0 then
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
            not self:needKongcheng(friend, true) and not playerHasManjuanEffect(friend) and friend:getMark('LuaPaiyi_biu') ==
            0 then
            target = friend
        end
        if target then
            break
        end
    end
    if not target then
        if self.player:getMark('LuaPaiyi_biu') == 0 and self.player:getHandcardNum() < self.player:getHp() +
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
                not playerHasManjuanEffect(friend) and friend:getMark('LuaPaiyi_biu') == 0 then
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
                self.player:getHandcardNum() and enemy:getMark('LuaPaiyi_biu') == 0 then
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
                    not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy)) and enemy:getHandcardNum() +
                    2 > self.player:getHandcardNum() and not enemy:hasSkill('manjuan') and enemy:getMark('LuaPaiyi_biu') == 0 then
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
        ((to:getHandcardNum() < 2 and to:getHandcardNum() + 1 < from:getHandcardNum() and not self:needKongcheng(to, true)) or
            (to:getHandcardNum() + 2 > from:getHandcardNum() and
                (self:getDamagedEffects(to, from) or self:needToLoseHp(to, from)))) then
        return
    end
    sgs.updateIntention(from, to, 60)
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
    sgs.updateIntention(from, to, 80)
end

-- 掠命选项
sgs.ai_skill_choice.LuaLveming = function(self, choices)
    local items = choices:split('+')
    return items[rinsan.random(1, #items)]
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
            if not friend:hasFlag('LuaDingpinSucceed') and friend:getHp() >= 2 and (not playerHasManjuanEffect(friend)) then
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

    local willUseHandcard = false
    -- 判断是否还要用牌
    for _, cd in sgs.qlist(self.player:getHandcards()) do
        local dummy_use = {
            isDummy = true,
        }
        self:useCardByClassName(cd, dummy_use)
        if dummy_use.card then
            willUseHandcard = true
            break
        end
    end

    -- 同时可行
    if LuaZhiyanDrawAvailable and LuaZhiyanGiveAvailable then
        if not willUseHandcard then
            -- 不再使用手牌则先摸
            return sgs.Card_Parse('#LuaZhiyanDrawCard:.:')
        end
    end
    if LuaZhiyanGiveAvailable then
        return sgs.Card_Parse('#LuaZhiyanGiveCard:.:')
    elseif LuaZhiyanDrawAvailable and (not willUseHandcard) then
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

-- 铁骑谋弈选项
sgs.ai_skill_choice['LuaMouTieji'] = function(self, choices, data)
    local items = choices:split('+')
    -- 空城就嗯摸，反正大伙儿都知道你会选摸牌，就算选了偷牌也没用
    if table.contains(items, 'LuaMouTiejiAttack2') then
        local target = data:toPlayer()
        if target:isNude() then
            return 'LuaMouTiejiAttack2'
        end
    end
    if table.contains(items, 'LuaMouTiejiDefense2') then
        if self.player:isNude() then
            return 'LuaMouTiejiDefense2'
        end
    end
    return items[rinsan.random(1, #items)]
end

sgs.ai_skill_invoke.LuaMouTieji = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    return false
end

-- 文鸯势力选项
sgs.ai_skill_choice['LuaWenyangKingdomChoose'] = function(self, choices)
    local items = choices:split('+')
    return items[math.random(1, #items)]
end

-- 张翼
-- 执义
sgs.ai_skill_choice['LuaZhiyi'] = function(self, choices)
    local items = choices:split('+')
    if table.contains(items, 'peach') then
        -- 有桃就吃
        return 'peach'
    end
    local slashes = {}
    for _, item in ipairs(items) do
        if string.find(item, 'slash') then
            table.insert(slashes, item)
        end
    end
    if #slashes > 0 then
        -- 遍历敌人，然后选打伤害最高的
        self:sort(self.enemies, 'defense')
        local maxDamage, maxSlash = -1, ''
        local victim
        for _, enemy in ipairs(self.enemies) do
            for _, slash in ipairs(slashes) do
                local dummy = sgs.Sanguosha:cloneCard(slash, sgs.Card_NoSuit, -1)
                local nature = getDamageType(dummy)
                if not self:damageIsEffective(enemy, nature, self.player) then
                    goto nextSlash
                end
                if self.player:canSlash(enemy, dummy, true) then
                    local currDamage = self:AtomDamageCount(enemy, self.player, nature, dummy)
                    -- 判断是否会有断肠等风险
                    if rinsan.hasDeathSkillRisk(self.player, enemy) and currDamage >= enemy:getHp() then
                        goto nextEnemy
                    end
                    if currDamage > maxDamage then
                        maxDamage = currDamage
                        maxSlash = slash
                        victim = enemy
                    end
                end
                ::nextSlash::
            end
            ::nextEnemy::
        end
        if maxDamage > 0 and victim then
            -- 选中最大目标
            local data = sgs.QVariant()
            data:setValue(victim)
            self.player:setTag('LuaZhiyiSlashTarget', data)
            return maxSlash
        end
    end
    return 'luazhiyidraw'
end

-- 执义选择杀目标
sgs.ai_skill_playerchosen['LuaZhiyi'] = function(self, targets, data)
    targets = sgs.QList2Table(targets)
    -- 如果已经有预选角色，直接用
    local prechoose = self.player:getTag('LuaZhiyiSlashTarget'):toPlayer()
    if prechoose then
        for _, p in ipairs(targets) do
            if p:objectName() == prechoose:objectName() then
                return p
            end
        end
    end
    local slash = self.player:getTag('LuaZhiyiSlashType'):toString()
    self:sort(targets, 'defense')
    local maxDamage = -1
    local victim
    for _, enemy in ipairs(targets) do
        if not self:isEnemy(enemy) then
            goto nextEnemy
        end
        local dummy = sgs.Sanguosha:cloneCard(slash, sgs.Card_NoSuit, -1)
        if self.player:canSlash(enemy, dummy, true) then
            local currDamage = self:AtomDamageCount(enemy, self.player, getDamageType(dummy), dummy)
            -- 判断是否会有断肠等风险
            if rinsan.hasDeathSkillRisk(self.player, enemy) and currDamage >= enemy:getHp() then
                goto nextEnemy
            end
            if currDamage > maxDamage then
                maxDamage = currDamage
                victim = enemy
            end
        end
        ::nextEnemy::
    end
    if maxDamage > 0 and victim then
        return victim
    end
    return targets[random(1, #targets)]
end

-- 通渠给牌
sgs.ai_skill_use['@@LuaTongqu!'] = function(self, prompt, method)
    local target
    self:sort(self.friends_noself)
    for _, friend in ipairs(self.friends_noself) do
        if not playerHasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
            target = friend
            break
        end
    end
    local x = 1
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
        return '#LuaTongqu:' .. table.concat(to_give, '+') .. ':->' .. target:objectName()
    end
    return '#LuaTongqu:' .. table.concat(to_give, '+') .. ':.'
end

-- 助势选择
sgs.ai_skill_choice['LuaZhushi'] = function(self, choices, data)
    local caomao = data:toPlayer()
    return self:isFriend(caomao) and 'LuaZhushiDraw' or 'cancel'
end

-- 毅谋给牌选择
sgs.ai_skill_askforyiji['LuaYimou'] = function(self, card_ids)
    local available_friends = {}
    for _, friend in ipairs(self.friends_noself) do
        if not friend:hasSkill("manjuan") and not self:isLihunTarget(friend) then
            table.insert(available_friends, friend)
        end
    end

    local toGive, allcards = {}, {}
    local keep
    for _, id in ipairs(card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
            keep = true
        else
            table.insert(toGive, card)
        end
        table.insert(allcards, card)
    end

    local cards = #toGive > 0 and toGive or allcards
    self:sortByKeepValue(cards, true)
    local id = cards[1]:getId()

    local card, friend = self:getCardNeedPlayer(cards)
    if card and friend and table.contains(available_friends, friend) then
        return friend, card:getId()
    end

    if #available_friends > 0 then
        self:sort(available_friends, "handcard")
        for _, afriend in ipairs(available_friends) do
            if not self:needKongcheng(afriend, true) then
                return afriend, id
            end
        end
        self:sort(available_friends, "defense")
        return available_friends[1], id
    end

    -- 没有友方，选择最差的牌给随机一人
    local all_players = self.room:getOtherPlayers(self.player)
    local all_players_table = sgs.QList2Table(all_players)

    self:sortByKeepValue(cards)
    id = cards[1]:getId()

    return all_players_table[rinsan.random(1, #all_players_table)], id
end

-- 遣信选择
sgs.ai_skill_choice['LuaQianxin'] = function(self, choices, data)
    local items = choices:split('+')
    local target = data:toPlayer()
    -- 队友无脑选摸牌
    if self:isFriend(target) then
        return items[1]
    end
    -- 非队友根据情况选择
    -- 选择保命
    if self:isWeak() then
        return items[1]
    end
    -- 如果觉得可以趁机直接干掉，就选掉上限
    if (not self:needBear()) and self:isWeak(zhangrang) then
        return items[1]
    end
    -- 随机
    return items[rinsan.random(1, 2)]
end

-- 战烈弃牌
sgs.ai_skill_discard['LuaZhanlieDiscard'] = function(self, discard_num, min_num, optional, method)
    local cards = self.player:getCards('he')
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards, true)
    local to_discard = {}
    local jink_num = self:getCardsNum('Jink')
    local chosen_card
    for i = 1, discard_num do
        chosen_card = cards[i]
        table.insert(to_discard, cards[i]:getEffectiveId())
    end
    -- 没有闪的情况下，不弃牌
    if jink_num == 0 then
        return {}
    elseif jink_num == 1 then
        -- 只有一张闪，若当前最差的牌为闪，则不弃牌
        return (not chosen_card:isKindOf('Jink')) and to_discard or {}
    end
    return to_discard
end
