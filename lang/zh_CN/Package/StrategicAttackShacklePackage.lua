-- translation for StrategicAttackShacklePackage

return {
    ['StrategicAttackShacklePackage'] = '谋攻篇-虞包',
    ['ExMouYujin'] = '谋于禁',
    ['&ExMouYujin'] = '谋于禁',
    ['#ExMouYujin'] = '威严毅重',
    ['LuaMouXiayuan'] = '狭援',
    [':LuaMouXiayuan'] = '<font color="green"><b>每轮限一次</b></font>，当其他角色受到伤害后，若此次伤害令其失去了全部的“护甲”，你可以弃置两张手牌，令其重新获得失去的“护甲”',
    ['LuaMouXiayuan-Discard'] = '你可以弃置两张手牌，令 %src 恢复 %arg 点护甲',
    ['LuaMouJieyue'] = '节钺',
    [':LuaMouJieyue'] = '结束阶段，你可以令一名其他角色获得1点“护甲”，然后其摸两张牌并交给你两张牌',
    ['LuaMouJieyue-choose'] = '你可以发动“节钺”，令一名其他角色获得一点“护甲”，然后其摸两张牌并交给你两张牌',
    ['LuaMouJieyue-Give'] = '你需交给 %src 两张牌',
    ['ExMouLvmeng'] = '谋吕蒙',
    ['&ExMouLvmeng'] = '谋吕蒙',
    ['#ExMouLvmeng'] = '苍江一笠',
    ['LuaMouKeji'] = '克己',
    ['luamoukejilosehp'] = '克己',
    ['luamoukejidis'] = '克己',
    -- 使用+会导致文本替换不成功
    [':LuaMouKeji'] = '①<font color="green"><b>出牌阶段每个选项各限一次</b></font>，你可以选择一项：1.弃置一张手牌，获得1点“护甲”；2.失去1点体力，获得2点“护甲”\
    ②你的手牌上限＋X（X为你的护甲值）\
    ③你使用的【桃】目标只能为处于濒死状态的自己',
    [':LuaMouKejiAwake'] = '①<font color="green"><b>出牌阶段限一次</b></font>，你可以选择一项：1.弃置一张手牌，获得1点“护甲”；2.失去1点体力，获得2点“护甲”\
    ②你的手牌上限＋X（X为你的护甲值）\
    ③你使用的【桃】目标只能为处于濒死状态的自己',
    ['LuaMouDujiang'] = '渡江',
    [':LuaMouDujiang'] = '觉醒技，准备阶段，若你的“护甲”值不小于3，你获得技能“夺荆”',
    ['#LuaMouDujiang'] = '%from 的护甲值为 %arg，触发“%arg2”觉醒',
    ['LuaMouDuojing'] = '夺荆',
    [':LuaMouDuojing'] = '当你使用【杀】指定一名角色为目标时，你可以失去1点“护甲”，令此【杀】无视该角色的防具，然后你获得该角色的一张牌且你本阶段使用【杀】的次数上限+1',
    ['ExMouCaoren'] = '谋曹仁',
    ['&ExMouCaoren'] = '谋曹仁',
    ['#ExMouCaoren'] = '大将军',
    ['LuaMouJushou'] = '据守',
    [':LuaMouJushou'] = '①出牌阶段限一次，若你的武将牌正面朝上，你可以翻面，然后你弃置至多两张牌并获得等量的“护甲”\
    ②当你受到伤害后，若你的武将牌背面朝上，你可以选择一项：1.翻面；2.获得1点“护甲”\
    ③当你的武将牌从背面翻至正面时，你摸等同于你“护甲”值的牌',
    ['LuaMouJushouDiscard'] = '你可以弃置至多 2 张牌并获得等量的护甲',
    ['luamoujushou'] = '据守',
    ['GainShield'] = '获得一点护甲',
    ['TurnOver'] = '翻面',
    ['LuaMouJiewei'] = '解围',
    [':LuaMouJiewei'] = '出牌阶段限一次，你可以失去1点“护甲”并选择一名其他角色，你观看其手牌并获得其中一张',
    ['luamoujiewei'] = '解围',
    ['ExMouGanning'] = '谋甘宁',
    ['&ExMouGanning'] = '谋甘宁',
    ['#ExMouGanning'] = '兴王定霸',
    ['LuaQixi'] = '奇袭',
    [':LuaQixi'] = '你可以将黑色牌当作【过河拆桥】使用，你使用的非转化非虚拟【过河拆桥】可以弃置目标区域内所有的牌',
    ['LuaFenwei'] = '奋威',
    [':LuaFenwei'] = '限定技，当一张锦囊牌指定至少两个目标后，你可以令此牌对其中任意名目标角色无效，然后你从牌堆中获得X张【过河拆桥】（X为你以此法选择的角色数，且至多为4）',
    ['luafenwei'] = '奋威',
    ['@LuaFenwei'] = '你可以发动“奋威”',
    ['~LuaFenwei'] = '选择若干名角色→点击确定',
    ['ExMouHuangzhong'] = '谋黄忠',
    ['&ExMouHuangzhong'] = '谋黄忠',
    ['#ExMouHuangzhong'] = '没金铩羽',
    ['LuaLiegong'] = '烈弓',
    [':LuaLiegong'] = '①你使用【杀】时可以选择距离不大于此【杀】点数的角色为目标；\
    ②当你使用牌时，或成为其他角色使用牌的目标后，若此牌的花色未被记录，记录此花色；\
    ③当你使用【杀】指定一名角色为唯一目标后，你可以展示牌堆顶的X张牌（X为你已记录的花色数-1，且至少为0），其中每有一张已记录的花色的牌，此【杀】的伤害便+1，且其不能使用已记录的花色的牌响应此【杀】，然后此【杀】结算结束后，清除所有已记录的花色',
    ['@LuaLiegong-jink'] = '%src 使用了【杀】，请使用一张未被其“烈弓”记录过花色的【闪】',
    ['#LuaLiegongInvalidJink'] = '由于已被记录花色，%from 使用的 %card 无效',
    ['ExMouHuanggai'] = '谋黄盖',
    ['&ExMouHuanggai'] = '谋黄盖',
    ['#ExMouHuanggai'] = '轻身为国',
    ['LuaMouKurou'] = '苦肉',
    [':LuaMouKurou'] = '【苦肉】①出牌阶段开始时，你可以交给一名其他角色一张牌。若你给出的牌为【桃】或【酒】，则你失去2点体力，否则你失去1点体力\
    ②当你失去1点体力后，你获得2点“护甲”',
    ['luamoukurou'] = '苦肉',
    ['@LuaMouKurou'] = '你可以发动“苦肉”，将一张牌交给其他角色并失去体力',
    ['~LuaMouKurou'] = '选择一张手牌→选择一名其他角色→点击确定',
    ['LuaMouZhaxiang'] = '诈降',
    [':LuaMouZhaxiang'] = '锁定技，①摸牌阶段，你多摸X张牌；\
    ②你每回合使用的前X张牌无距离与次数限制且不能被响应（X为你已损失的体力值）',
}
