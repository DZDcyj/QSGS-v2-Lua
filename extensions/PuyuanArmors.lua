-- 蒲元武器包
-- Created by DZDcyj at 2022/1/2
module('extensions.PuyuanArmors', package.seeall)
extension = sgs.Package('PuyuanArmors', sgs.Package_CardPack)

Hongduanqiang = sgs.CreateWeapon {
    name = 'Hongduanqiang',
    class_name = 'Hongduanqiang',
    suit = sgs.Card_Heart,
    number = 1,
    range = 3,
    on_install = function(self, player)
        local room = player:getRoom()
        room:acquireSkill(player, 'Hongduanqiang_skill', false)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, 'Hongduanqiang_skill', true)
    end
}

Hongduanqiang_skill = sgs.CreateTriggerSkill {
    name = 'Hongduanqiang_skill',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if data:toDamage().card and data:toDamage().card:isKindOf('Slash') then
            if room:askForSkillInvoke(player, 'Hongduanqiang') then
                local judge = sgs.JudgeStruct()
                judge.pattern = '.|red'
                judge.good = true
                judge.reason = 'Hongduanqiang'
                judge.who = player
                judge.play_animation = true
                room:judge(judge)
                if judge:isGood() then
                    room:recover(player, sgs.RecoverStruct(player, nil, 1))
                end
            end
        end
        return false
    end
}

Liecuiren = sgs.CreateWeapon {
    name = 'Liecuiren',
    class_name = 'Liecuiren',
    suit = sgs.Card_Diamond,
    number = 1,
    range = 2,
    on_install = function(self, player)
        local room = player:getRoom()
        room:acquireSkill(player, 'Liecuiren_skill', false)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, 'Liecuiren_skill', true)
    end
}

Liecuiren_skill = sgs.CreateTriggerSkill {
    name = 'Liecuiren_skill',
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf('Slash') then
            local use = room:askForCard(player, 'Slash, Weapon|.|.|hand', '@Liecuiren', data, 'Liecuiren')
            if use then
                damage.damage = damage.damage + 1
                local msg = sgs.LogMessage()
                msg.type = '#LuaDamageupOne'
                msg.from = player
                msg.arg = self:objectName()
                msg.card_str = damage.card:toString()
                room:sendLog(msg)
                data:setValue(damage)
            end
        end
        return false
    end
}

Shuibojian = sgs.CreateWeapon {
    name = 'Shuibojian',
    class_name = 'Shuibojian',
    suit = sgs.Card_Club,
    number = 1,
    range = 2,
    on_install = function(self, player)
        local room = player:getRoom()
        room:acquireSkill(player, 'Shuibojian_skill', false)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, 'Shuibojian_skill', true)
    end
}

Shuibojian_skill = sgs.CreateTriggerSkill {
    name = 'Shuibojian_skill',
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isNDTrick() or use.card:isKindOf('Slash') then
            local available_targets = sgs.SPlayerList()
            if (not use.card:isKindOf('AOE')) and (not use.card:isKindOf('nullification')) and
                (not use.card:isKindOf('GlobalEffect')) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not use.to:contains(p) then
                        if (use.card:targetFixed()) then
                            if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
                                available_targets:append(p)
                            end
                        else
                            if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
                                available_targets:append(p)
                            end
                        end
                    end
                end
            end
            if not available_targets:isEmpty() then
                player:setTag('ShuibojianCard', sgs.QVariant(use.card:objectName()))
                local extra = room:askForPlayerChosen(player, available_targets, self:objectName(), '@Shuibojian', true,
                    false)
                if extra then
                    use.to:append(extra)
                    data:setValue(use)
                end
                player:setTag('ShuibojianCard', sgs.QVariant())
            end
        end
        return false
    end
}

Hunduwandao = sgs.CreateWeapon {
    name = 'Hunduwandao',
    class_name = 'Hunduwandao',
    suit = sgs.Card_Spade,
    number = 1,
    range = 1,
    on_install = function(self, player)
        local room = player:getRoom()
        room:acquireSkill(player, 'Hunduwandao_skill', false)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, 'Hunduwandao_skill', true)
    end
}

Hunduwandao_skill = sgs.CreateTriggerSkill {
    name = 'Hunduwandao_skill',
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            if use.to:length() == 1 and use.card:isBlack() then
                local data2 = sgs.QVariant()
                local splayer
                for _, p in sgs.qlist(use.to) do
                    data2:setValue(p)
                    splayer = p
                end
                if room:askForSkillInvoke(player, 'Hunduwandao', data2) then
                    local log = sgs.LogMessage()
                    log.from = player
                    log.type = '#InvokeSkill'
                    log.arg = 'Hunduwandao'
                    room:sendLog(log)
                    if splayer then
                        splayer:obtainCard(use.card)
                        room:loseHp(splayer, 1)
                        local nullified_list = use.nullified_list
                        for _, p in sgs.qlist(use.to) do
                            table.insert(nullified_list, p:objectName())
                        end
                        use.nullified_list = nullified_list
                        data:setValue(use)
                    end
                end
            end
        end
        return false
    end
}

Tianleiren = sgs.CreateWeapon {
    name = 'Tianleiren',
    class_name = 'Tianleiren',
    suit = sgs.Card_Spade,
    number = 1,
    range = 4,
    on_install = function(self, player)
        local room = player:getRoom()
        room:acquireSkill(player, 'Tianleiren_skill', false)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, 'Tianleiren_skill', true)
    end
}

Tianleiren_skill = sgs.CreateTriggerSkill {
    name = 'Tianleiren_skill',
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf('Slash') then
            if use.to:length() == 1 then
                local data2 = sgs.QVariant()
                local splayer
                for _, p in sgs.qlist(use.to) do
                    data2:setValue(p)
                    splayer = p
                end
                if room:askForSkillInvoke(player, 'Tianleiren', data2) then
                    local log = sgs.LogMessage()
                    log.from = player
                    log.type = '#InvokeSkill'
                    log.arg = 'Tianleiren'
                    room:sendLog(log)
                    if splayer then
                        local judge = sgs.JudgeStruct()
                        judge.pattern = '.|spade|2~9'
                        judge.good = true
                        judge.reason = 'Tianleiren'
                        judge.who = splayer
                        judge.play_animation = true
                        room:judge(judge)
                        if judge:isGood() then
                            local damage = sgs.DamageStruct()
                            damage.nature = sgs.DamageStruct_Thunder
                            damage.to = splayer
                            damage.damage = 3
                            room:damage(damage)
                            local nullified_list = use.nullified_list
                            for _, p in sgs.qlist(use.to) do
                                table.insert(nullified_list, p:objectName())
                            end
                            use.nullified_list = nullified_list
                            data:setValue(use)
                        end
                    end
                end
            end
        end
        return false
    end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill('Hongduanqiang_skill') then
    skills:append(Hongduanqiang_skill)
end
if not sgs.Sanguosha:getSkill('Liecuiren_skill') then
    skills:append(Liecuiren_skill)
end
if not sgs.Sanguosha:getSkill('Shuibojian_skill') then
    skills:append(Shuibojian_skill)
end
if not sgs.Sanguosha:getSkill('Hunduwandao_skill') then
    skills:append(Hunduwandao_skill)
end
if not sgs.Sanguosha:getSkill('Tianleiren_skill') then
    skills:append(Tianleiren_skill)
end

sgs.Sanguosha:addSkills(skills)

Hongduanqiang:setParent(extension)
Liecuiren:setParent(extension)
Shuibojian:setParent(extension)
Hunduwandao:setParent(extension)
Tianleiren:setParent(extension)
