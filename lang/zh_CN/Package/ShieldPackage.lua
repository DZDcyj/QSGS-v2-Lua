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
    ['LuaMouJieyue-Give'] = '你可以交给 %src 一张牌',
    ['ExMouHuaxiong'] = '谋华雄',
    ['&ExMouHuaxiong'] = '谋华雄',
    ['#ExMouHuaxiong'] = '跋扈雄狮',
    ['LuaMouYaowu'] = '耀武',
    [':LuaMouYaowu'] = '锁定技，当你受到【杀】造成的伤害时，若此【杀】：为红色，伤害来源回复1点体力或摸一张牌；不为红色，你摸一张牌',
    ['LuaMouYangwei'] = '扬威',
    [':LuaMouYangwei'] = '出牌阶段限一次，你可以摸两张牌且本阶段获得“威”标记，然后此技能失效直到下个回合的结束阶段\
    “威”标记效果：使用【杀】的次数上限+1、使用【杀】无距离限制且无视防具',
    ['luamouyangwei'] = '扬威',
    ['@LuaWei'] = '威',
    ['ExMouSunshangxiang'] = '谋孙尚香',
    ['&ExMouSunshangxiang'] = '谋孙尚香',
    ['#ExMouSunshangxiang'] = '骄豪明俏',
    ['LuaMouLiangzhu'] = '良助',
    [':LuaMouLiangzhu'] = '<font color="#D0796C"><b>蜀势力技</b></font>，出牌阶段限一次，你可以将其他角色装备区内的一张牌置于你的武将牌上，称为“妆”，然后令拥有“助”标记的角色选择回复一点体力或摸两张牌',
    ['@LuaMouLiangzhu'] = '助',
    ['LuaMouLiangzhuPile'] = '妆',
    ['LuaMouLiangzhuChoice1'] = '回复1点体力',
    ['LuaMouLiangzhuChoice2'] = '摸2张牌',
    ['luamouliangzhu'] = '良助',
    ['LuaMouJieyin'] = '结姻',
    [':LuaMouJieyin'] = '<font color="purple"><b>使命技</b></font>，①游戏开始时，你令一名其他角色获得“助”标记；\
    ②出牌阶段开始时，有“助”标记的角色选择一项：1.若其有手牌，交给你两张手牌（不足则全给），然后其获得1点“护甲”；2.令你将“助”标记移动给另一名其他角色或移去之（若其不为第一次失去“助”标记，你只能选择移去之）\
    失败：当“助”标记被移去时，你回复1点体力并获得你武将牌上的所有“妆”，然后你将势力修改为“吴”并减1点体力上限',
    ['LuaMouJieyinChoice1'] = '交给其两张手牌',
    ['LuaMouJieyinChoice2'] = '令其移动或移除“助”标记',
    ['LuaMouJieyin-give'] = '请交给 %src 两张手牌',
    ['LuaMouJieyinMoveTo'] = '请选择一名角色作为“助”标记的移动目标',
    ['#LuaMouJieyinWake'] = '“%arg”标记被移除，%from“%arg”<font color="red"><b>失败</b></font>',
    ['LuaMouJieyin-invoke'] = '请选择一名其他角色，令其获得“助”标记',
    ['$LuaMouJieyinGot'] = "%from 获得所有“%arg”：%card",
    ['LuaMouXiaoji'] = '枭姬',
    [':LuaMouXiaoji'] = '<font color="#4DB873"><b>吴势力技</b></font>，当你失去装备区里的一张牌时，你摸两张牌，然后你可以弃置场上的一张牌',
    ['LuaMouXiaojiChoose'] = '你可以选择一名角色，弃置其区域内的一张牌'
}
