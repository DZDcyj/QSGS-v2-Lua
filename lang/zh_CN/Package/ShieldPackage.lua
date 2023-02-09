-- translation for ShieldPackage

return {
    ['ShieldPackage'] = '谋攻包',
    ['#GainShield'] = '%from 获得了 %arg 点护甲',
    ['#LoseShield'] = '%from 失去了 %arg 点护甲',
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
    ['ExMouYujin'] = '谋于禁',
    ['&ExMouYujin'] = '谋于禁',
    ['#ExMouYujin'] = '威严毅重',
    ['LuaMouXiayuan'] = '狭援',
    [':LuaMouXiayuan'] = '<font color="green"><b>每轮限一次</b></font>，当其他角色受到伤害后，若此次伤害令其失去了全部的“护甲”，你可以弃置两张手牌，令其重新获得失去的“护甲”',
    ['LuaMouXiayuan-Discard'] = '你可以弃置两张手牌，令 %src 恢复 %arg 点护甲',
    ['LuaMouJieyue'] = '节钺',
    [':LuaMouJieyue'] = '结束阶段，你可以令一名其他角色获得1点“护甲”，然后其可以交给你一张牌',
    ['LuaMouJieyue-choose'] = '你可以发动“节钺”，令一名其他角色获得一点“护甲”，然后其可选择交给你一张牌',
    ['LuaMouJieyue-Give'] = '你可以交给 %src 一张牌'
}
