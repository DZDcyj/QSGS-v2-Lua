-- translation for LayingPlansWisdomPackage

return {
    ['LayingPlansWisdomPackage'] = '始计篇-智包',
    ['ExBianfuren'] = '卞夫人',
    ['&ExBianfuren'] = '卞夫人',
    ['#ExBianfuren'] = '内助贤后',
    ['LuaWanwei'] = '挽危',
    [':LuaWanwei'] = '每轮限一次，当一名其他角色进入濒死状态时，或出牌阶段内你可以选择一名其他角色，你可以令其回复X+1点体力（若不足使其脱离濒死，改为回复至1点体力），然后你失去X点体力（X为你的体力值）',
    ['luawanwei'] = '挽危',
    ['LuaYuejian'] = '约俭',
    [':LuaYuejian'] = '你的手牌上限等于体力上限；当你进入濒死状态时，你可以弃置两张牌，回复1点体力',
    ['LuaYuejian-Discard'] = '你可以弃置两张牌发动“约俭”回复一点体力',
    ['ExSunshao'] = '孙邵',
    ['&ExSunshao'] = '孙邵',
    ['#ExSunshao'] = '创基抉政',
    ['LuaDingyi'] = '定仪',
    [':LuaDingyi'] = '锁定技，游戏开始时，你令全场角色均获得一项效果：\
    1.摸牌阶段的额定摸牌数+1；\
    2.手牌上限+2；\
    3.攻击范围+1；\
    4.脱离濒死状态时回复1点体力',
    ['LuaDingyi1'] = '摸牌阶段的额定摸牌数+1',
    ['LuaDingyi2'] = '手牌上限+2',
    ['LuaDingyi3'] = '攻击范围+1',
    ['LuaDingyi4'] = '脱离濒死状态时回复1点体力',
    ['#LuaDingyi1'] = '%from 的“%arg”效果被触发，额外摸了 %arg2 张牌',
    ['#LuaDingyi4'] = '%from 的“%arg”效果被触发，回复了 %arg2 点体力',
    ['LuaZuici'] = '罪辞',
    [':LuaZuici'] = '当你受到受“定仪”影响的角色造成的伤害后，你可以令其失去“定仪”效果，然后其从牌堆中获得你选择的一张智囊牌',
    ['LuaFubi'] = '辅弼',
    [':LuaFubi'] = '每轮限一次，出牌阶段，你可以选择一名角色并选择一项：1.更换其拥有的“定仪”效果；2.弃置一张牌，令其拥有的“定仪”效果翻倍（直到下一轮的你的下一个回合开始）',
    ['luafubi'] = '辅弼',
    ['ExDuyu'] = '杜预',
    ['&ExDuyu'] = '杜预',
    ['#ExDuyu'] = '文成武德',
    ['LuaWuku'] = '武库',
    [':LuaWuku'] = '锁定技，当一名角色使用装备牌时，若“武库”标记小于3，你获得1个“武库”标记',
    ['@wuku'] = '武库',
    ['LuaSanchen'] = '三陈',
    [':LuaSanchen'] = '觉醒技，结束阶段，若“武库”数大于2，你加1点体力上限，回复1点体力，然后获得“灭吴”',
    ['#LuaSanchen'] = '%from 的“武库”数为 %arg，触发“%arg2”觉醒',
    ['LuaMiewu'] = '灭吴',
    ['luamiewu'] = '灭吴',
    [':LuaMiewu'] = '每回合限一次，你可以弃1个“武库”，将一张牌当任意一张基本牌或锦囊牌使用或打出；若如此做，你摸一张牌',
    ['miewu_slash'] = '灭吴',
    ['miewu_saveself'] = '灭吴',
    ['ExWangcan'] = '王粲',
    ['&ExWangcan'] = '王粲',
    ['#ExWangcan'] = '七子之冠',
    ['LuaQiai'] = '七哀',
    ['luaqiai'] = '七哀',
    [':LuaQiai'] = '出牌阶段限一次，你可以将一张非基本牌交给一名其他角色，令其选择一项：1.你回复1点体力；2.你摸两张牌',
    ['letdraw2'] = '令其摸两张牌',
    ['letrecover'] = '令其回复一点体力',
    ['LuaShanxi'] = '善檄',
    [':LuaShanxi'] = '出牌阶段开始时，你可以令一名其他角色获得“檄”标记（如场上已有标记则转移给该角色）。拥有“檄”的角色，其每次恢复体力后，若未处于濒死状态，则其需交给你两张牌，否则流失一点体力',
    ['LuaShanxi-give'] = '请交给 %src 两张牌，否则你将失去一点体力',
    ['LuaShanxi-choose'] = '你可以选择一名其他角色，令其获得“檄”',
    ['ExShenXunyu'] = '神荀彧',
    ['&ExShenXunyu'] = '神荀彧',
    ['#ExShenXunyu'] = '洞心先识',
    ['LuaTianzuo'] = '天佐',
    [':LuaTianzuo'] = '锁定技，游戏开始时，将8张【奇正相生】加入牌堆；【奇正相生】对你无效',
    ['$LuaTianzuo'] = '%card 被置入摸牌堆',
    ['LuaLingce'] = '灵策',
    [':LuaLingce'] = '锁定技，当一名角色使用非虚拟且非转化的锦囊牌时，若此牌的牌名属于智囊牌名、“定汉”已记录的牌名或【奇正相生】，你摸一张牌',
    ['LuaDinghan'] = '定汉',
    [':LuaDinghan'] = '当你成为锦囊牌的目标时，你记录此牌名，然后取消之。回合开始时，你可以在“定汉”记录中增加或移除一种锦囊牌牌名',
    ['LuaDinghanAdd'] = '定汉增加牌名',
    ['LuaDinghanRemove'] = '定汉移除牌名',
    ['#LuaDinghanAdd'] = '%from 为“%arg”增加牌名【%arg2】',
    ['#LuaDinghanRemove'] = '%from 为“%arg”移除牌名【%arg2】',
    ['ExShenGuojia'] = '神郭嘉',
    ['&ExShenGuojia'] = '神郭嘉',
    ['#ExShenGuojia'] = '星月奇佐',
    ['LuaHuishi'] = '慧识',
    [':LuaHuishi'] = '出牌阶段限一次，若你的体力上限小于10，你可以进行判定：若结果与此阶段内以此法进行判定的结果的花色均不同，且此时你的体力上限小于10，你可以重复此流程并加1点体力上限，然后你可以将所有生效的判定牌交给一名角色。\
    若其手牌数为全场最多，你减1点体力上限',
    ['luahuishi'] = '慧识',
    ['LuaHuishi-choose'] = '你可以选择一名角色获得这些牌，或点击“取消”将牌留给自己',
    ['LuaTianyi'] = '天翊',
    [':LuaTianyi'] = '觉醒技，准备阶段，若全场角色在本局游戏中均受到过伤害，你加2点体力上限，回复1点体力，然后令一名角色获得“佐幸”',
    ['LuaTianyi-choose'] = '请选择一名角色获得“佐幸”',
    ['#LuaTianyi'] = '场上角色均已受到过伤害，%from 的“%arg”被触发',
    ['LuaLimitHuishi'] = '辉逝',
    [':LuaLimitHuishi'] = '限定技，出牌阶段，你可以选择一名角色，其摸四张牌。若如此做，你减2点体力上限',
    ['lualimithuishi'] = '辉逝',
    ['@LuaLimitHuishi'] = '辉逝',
    ['LuaZuoxing'] = '佐幸',
    [':LuaZuoxing'] = '出牌阶段限一次，若神郭嘉存活且体力上限大于1，你可令神郭嘉减1点体力上限。然后你可视为使用一张普通锦囊牌',
    ['luazuoxing'] = '佐幸',
    ['ExXunchen'] = '荀谌',
    ['&ExXunchen'] = '荀谌',
    ['#ExXunchen'] = '谋刃略锋',
    ['LuaWeipo'] = '危迫',
    [':LuaWeipo'] = '①每回合限一次，出牌阶段，你可以选择一名角色并指定一张【兵临城下】或智囊的牌名，令其获得1个记录此牌名的“危迫”标记直到你的下个回合开始；\
    ②拥有“危迫”标记的角色的出牌阶段，其可以移去1个“危迫”标记，并弃置一张【杀】，然后从游戏外或牌堆中随机获得一张此标记记录牌名的牌',
    ['luaweipo'] = '危迫',
    ['LuaWeipoVS'] = '危迫',
    [':LuaWeipoVS'] = '你可以移去1个“危迫”标记，并弃置一张【杀】，然后从游戏外或牌堆中随机获得一张“危迫”标记记录牌名的牌',
    ['luaweipovs'] = '危迫',
    ['#LuaWeipoTarget'] = '%from 为 %to 指定“%arg”牌名【%arg2】',
    ['LuaChenshi'] = '陈势',
    [':LuaChenshi'] = '当其他角色使用【兵临城下】指定目标后/成为【兵临城下】的目标后，其可以交给你一张牌，然后将牌堆顶三张牌中不为【杀】的牌/的【杀】置入弃牌堆',
    ['LuaChenshi-From-Give'] = '你可以交给 %src 一张牌，将牌堆顶三张牌中不为【杀】的牌置入弃牌堆',
    ['LuaChenshi-To-Give'] = '你可以交给 %src 一张牌，将牌堆顶三张牌中的【杀】置入弃牌堆',
    ['LuaMoushi'] = '谋识',
    [':LuaMoushi'] = '锁定技，当你受到伤害时，若对你造成伤害的牌与本局游戏内上次对你造成伤害的牌花色相同，防止此伤害',
    ['$LuaMoushi'] = '%from 的“%arg”被触发，防止了 %card 造成的伤害',
    ['ExFeiyi'] = '费祎',
    ['&ExFeiyi'] = '费祎',
    ['#ExFeiyi'] = '蜀汉名相',
    ['LuaJianyu'] = '谏喻',
    [':LuaJianyu'] = '每轮限一次，出牌阶段，你可以选择两名角色，直到你的下回合开始，当其中一名角色于其的出牌阶段内使用牌指定另一名角色为目标时，你令后者摸一张牌',
    ['luajianyu'] = '谏喻',
    ['LuaShengxi'] = '生息',
    [':LuaShengxi'] = '①准备阶段，你可以从游戏外或牌堆中获得一张【调剂盐梅】；\
    ②结束阶段，若你本回合使用过牌且没有造成过伤害，你可以从牌堆中获得一张智囊牌或摸一张牌',
    ['LuaShengxiZhinang'] = '获得一张智囊牌',
    ['LuaShengxiDraw'] = '摸一张牌',
    ['ExChenzhen'] = '陈震',
    ['&ExChenzhen'] = '陈震',
    ['#ExChenzhen'] = '歃盟使节',
    ['LuaShameng'] = '歃盟',
    [':LuaShameng'] = '出牌阶段限一次，你可以弃置两张颜色相同的手牌，令一名其他角色摸两张牌，然后你摸三张牌',
    ['luashameng'] = '歃盟',
    ['ExLuotong'] = '骆统',
    ['&ExLuotong'] = '骆统',
    ['#ExLuotong'] = '辨明大义',
    ['LuaQinzheng'] = '勤政',
    [':LuaQinzheng'] = '锁定技，你每使用或打出三张牌时，你随机获得一张【杀】或【闪】﹔每使用或打出五张牌时，你随机获得一张【桃】或【酒】﹔每使用或打出八张牌时，你随机获得一张【无中生有】或【决斗】',
}
