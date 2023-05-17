-- 限定-祈福包
-- Created by DZDcyj at 2023/5/2

module('extensions.PrayFortunePackage', package.seeall)
extension = sgs.Package('PrayFortunePackage')

-- 引入封装函数包
local rinsan = require('QSanguoshaLuaFunction')

-- 赵襄
ExTenYearZhaoxiang = sgs.General(extension, 'ExTenYearZhaoxiang', 'shu', '4', false, true)

LuaFanghunVS = sgs.CreateOneCardViewAsSkill {
    name = 'LuaFanghun',
    response_or_use = true,
    view_filter = function(self, card)
        local usereason = sgs.Sanguosha:getCurrentCardUseReason()
        if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return card:isKindOf('Jink')
        elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or
            (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == 'slash' then
                return card:isKindOf('Jink')
            else
                return card:isKindOf('Slash')
            end
        end
        return false
    end,
    view_as = function(self, card)
        if card:isKindOf('Slash') then
            local jink = sgs.Sanguosha:cloneCard('jink', card:getSuit(), card:getNumber())
            jink:addSubcard(card)
            jink:setSkillName(self:objectName())
            return jink
        elseif card:isKindOf('Jink') then
            local slash = sgs.Sanguosha:cloneCard('slash', card:getSuit(), card:getNumber())
            slash:addSubcard(card)
            slash:setSkillName(self:objectName())
            return slash
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return player:getMark('@LuaFanghun') > 0 and sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getMark('@LuaFanghun') > 0 and (pattern == 'slash' or pattern == 'jink')
    end,
}

LuaFanghun = sgs.CreateTriggerSkill {
    name = 'LuaFanghun',
    view_as_skill = LuaFanghunVS,
    events = {sgs.TargetConfirmed, sgs.TargetSpecified, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player)) then
            if use.card and use.card:isKindOf('Slash') then
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:gainMark('@LuaFanghun')
            end
        else
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:getSkillName() == self:objectName() then
                player:loseMark('@LuaFanghun')
                player:drawCards(1, self:objectName())
            end
        end
    end,
}

-- 获取可扶汉的武将 Table
-- 暂时没有排除已获得所有技能的武将
local function getFuhanShuGenerals(general_num)
    local general_names = sgs.Sanguosha:getLimitedGeneralNames()
    local shu_generals = {}
    for _, name in ipairs(general_names) do
        local general = sgs.Sanguosha:getGeneral(name)
        if general:getKingdom() == 'shu' then
            if not table.contains(shu_generals, name) then
                table.insert(shu_generals, name)
            end
        end
    end
    local available_generals = {}
    local i = 0
    while i < general_num do
        i = i + 1
        local index = random(1, #shu_generals)
        local selected = shu_generals[index]
        table.insert(available_generals, selected)
        table.removeOne(shu_generals, shu_generals[index])
    end
    return available_generals
end

LuaFuhan = sgs.CreateTriggerSkill {
    name = 'LuaFuhan',
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = '@LuaFuhan',
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local x = player:getMark('@LuaFanghun')
            if x > 0 then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:loseAllMarks('@LuaFanghun')
                    player:loseMark('@LuaFuhan')
                    player:drawCards(x, self:objectName())
                    local shu_generals = getFuhanShuGenerals(math.max(4, room:alivePlayerCount()))
                    local index = 0
                    while index < 2 and #shu_generals > 0 and
                        room:askForChoice(player, self:objectName(), 'LuaFuhan+cancel') ~= 'cancel' do
                        index = index + 1
                        local generals = table.concat(shu_generals, '+')
                        local general = room:askForGeneral(player, generals)
                        local target = sgs.Sanguosha:getGeneral(general)
                        local skills = target:getVisibleSkillList()
                        local skillnames = {}
                        for _, skill in sgs.qlist(skills) do
                            if not skill:inherits('SPConvertSkill') and not player:hasSkill(skill:objectName()) and
                                not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and
                                skill:getFrequency() ~= sgs.Skill_Limited then
                                table.insert(skillnames, skill:objectName())
                            end
                        end
                        local choices = table.concat(skillnames, '+')
                        local skill = room:askForChoice(player, self:objectName(), choices)
                        room:acquireSkill(player, skill, true)
                        skillnames = {}
                        for _, left_skill in sgs.qlist(skills) do
                            if not left_skill:inherits('SPConvertSkill') and
                                not player:hasSkill(left_skill:objectName()) and not left_skill:isLordSkill() and
                                left_skill:getFrequency() ~= sgs.Skill_Wake and left_skill:getFrequency() ~=
                                sgs.Skill_Limited then
                                table.insert(skillnames, left_skill:objectName())
                            end
                        end
                        if #skillnames == 0 then
                            table.removeOne(shu_generals, general)
                        end
                    end
                    local hasMinHp = true
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getHp() < player:getHp() then
                            hasMinHp = false
                            break
                        end
                    end
                    if hasMinHp and player:isWounded() then
                        rinsan.recover(player)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, player)
        return rinsan.RIGHT(self, player) and player:getMark('@LuaFuhan') > 0
    end,
}

ExTenYearZhaoxiang:addSkill(LuaFanghun)
ExTenYearZhaoxiang:addSkill(LuaFuhan)

-- 关索
ExTenYearGuansuo = sgs.General(extension, 'ExTenYearGuansuo', 'shu', '4', true)

LuaZhengnan = sgs.CreateTriggerSkill {
    name = 'LuaZhengnan',
    frequency = sgs.Skill_Frequent,
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:getMark(self:objectName() .. player:objectName()) == 0 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(dying.who, self:objectName() .. player:objectName())
                if player:isWounded() then
                    rinsan.recover(player)
                end
                player:drawCards(1, self:objectName())
                local gainableSkills = rinsan.getGainableSkillTable(player, {'LuaDangxian', 'wusheng', 'LuaZhiman'})
                -- gainnableSkills 代表可以获得的剩余技能，若为0，则代表已经获取了三个技能，走摸牌流程
                if #gainableSkills == 0 then
                    player:drawCards(3, self:objectName())
                else
                    local choice = room:askForChoice(player, self:objectName(), table.concat(gainableSkills, '+'))
                    room:acquireSkill(player, choice)
                end
            end
        end
    end,
}

LuaZhiman = sgs.CreateTriggerSkill {
    name = 'LuaZhiman',
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:objectName() == player:objectName() then
            return false
        end
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:doAnimate(rinsan.ANIMATE_INDICATE, player:objectName(), damage.to:objectName())
            if not damage.to:isAllNude() then
                local id = room:askForCardChosen(player, damage.to, 'hej', self:objectName())
                player:obtainCard(sgs.Sanguosha:getCard(id), false)
            end
            return true
        end
        return false
    end,
}

ExTenYearGuansuo:addSkill(LuaZhengnan)
ExTenYearGuansuo:addSkill('xiefang')
ExTenYearGuansuo:addRelateSkill('LuaDangxian')
ExTenYearGuansuo:addRelateSkill('wusheng')
ExTenYearGuansuo:addRelateSkill('LuaZhiman')
rinsan.addSingleHiddenSkill(LuaZhiman)
