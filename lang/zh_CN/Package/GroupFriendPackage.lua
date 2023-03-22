-- translation for GroupFriend Package

return {
    ['GroupFriendPackage'] = '群友包',
    ['#swapSeat'] = '%from 和 %to 交换了座位',
    ['Cactus'] = '仙人掌',
    ['&Cactus'] = '仙人掌',
    ['#Cactus'] = '海呐百川',
    ['LuaBaipiao'] = '白嫖',
    [':LuaBaipiao'] = '锁定技，当你的牌不因使用、打出、重铸、交给其他角色、更换装备而失去时：若该牌被其他人获得，你摸一张牌，否则你获得一名角色区域内的一张牌',
    ['LuaBaipiao-invoke'] = '你须选择一名角色白嫖',
    ['Fuhua'] = '浮华',
    ['&Fuhua'] = '浮华',
    ['#Fuhua'] = '憨态',
    ['LuaGeidian'] = '给点',
    [':LuaGeidian'] = '<font color = "green"><b>出牌阶段对每名角色限一次</b></font>，你可以令一名其他角色交给你一张牌\
    当你于此阶段发动“给点”超过X次时，该角色视为对你使用一张杀（X为你失去的体力值且至少为1）',
    ['@LuaGeidian-ask'] = '请选择一张牌交给 %src，或点击“取消”给出随机一张牌',
    ['luageidian'] = '给点',
    ['LuaWanneng'] = '万能',
    [':LuaWanneng'] = '<font color = "green"><b>每回合限一次</b></font>，你可以视为使用/打出一张基本牌或非延时类锦囊，或视为重铸一张【铁索连环】',
    ['LuaXiaosa'] = '潇洒',
    [':LuaXiaosa'] = '<font color = "green"><b>每轮限一次</b></font>，当你成为其他角色使用的基本牌或非延时锦囊牌的目标时，你可以令此牌无效',
    ['luawanneng'] = '万能',
    ['wanneng_slash'] = '万能',
    ['wanneng_saveself'] = '万能',
    ['LuaMasochism'] = '受虐',
    [':LuaMasochism'] = '锁定技，当你不处于濒死状态时，以你为目标的【桃】失效',
    ['Rinsan'] = '磷酸',
    ['&Rinsan'] = '磷酸',
    ['#Rinsan'] = '妹抖',
    ['LuaZibao'] = '自爆',
    [':LuaZibao'] = '当你不因此技能造成伤害时，你可以失去一点体力，令该伤害+X；当你受到伤害后，你可以失去一点体力，对伤害来源造成X点伤害。（X为你失去的体力值）',
    ['LuaSoutu'] = '搜图',
    [':LuaSoutu'] = '<font color = "green"><b>其他角色的出牌阶段限一次</b></font>，该角色可以交给你一张手牌，然后你观看牌堆顶的3张牌，获得与此牌类型/点数/花色一致的牌\
    然后你可以将任意数量的手牌交给该角色',
    ['LuaSoutuVS'] = '搜图',
    [':LuaSoutuVS'] = '<font color = "green"><b>出牌阶段限一次</b></font>，你可以交给其一张手牌，然后其观看牌堆顶的3张牌，获得与此牌类型/点数/花色一致的牌，然后将任意牌交给你',
    ['luasoutu'] = '搜图送牌',
    ['LuaSoutuGoBack'] = '请交出任意张牌，若不想交出，点击“取消”即可',
    ['SPFuhua'] = 'SP浮华',
    ['&SPFuhua'] = '浮华',
    ['#SPFuhua'] = '憨态Plus',
    ['LuaYangjing'] = '养精',
    [':LuaYangjing'] = '锁定技，出牌阶段结束时，若你未于此阶段使用过【杀】，或当你的一张【杀】被弃置后，你获得一枚“精”标记；你的攻击范围和【杀】造成的伤害+X。你使用的【杀】结算完毕后，移除所有“精”标记',
    ['LuaTuci'] = '突刺',
    [':LuaTuci'] = '锁定技，当你使用【杀】指定目标后，若你与该角色的距离小于你的攻击范围，则此【杀】无视目标的防具且不能被【闪】响应',
    ['@LuaJing'] = '精',
    ['#LuaYangjingDamageUp'] = '%from 执行“<font color="yellow"><b>养精</b></font>”的效果，%card 的伤害值 + %arg',
    ['#LuaYangjingDamageUpVirtualCard'] = '%from 执行“<font color="yellow"><b>养精</b></font>”的效果，\
    <font color = "yellow"><b>杀[无色]</b></font> 的伤害值 + %arg',
    ['SPCactus'] = 'SP仙人掌',
    ['&SPCactus'] = '仙人掌',
    ['#SPCactus'] = '心狠手辣',
    ['LuaNosJuesha'] = '绝杀',
    [':LuaNosJuesha'] = '当一名角色进入濒死阶段时，你可以令其失去一点体力，每次濒死结算限一次',
    ['LuaJuesha'] = '绝杀',
    [':LuaJuesha'] = '当一名角色进入濒死阶段时，你可以令第一张目标含有该角色的【桃】或【酒】失效',
    ['LuaMouhai'] = '谋害',
    [':LuaMouhai'] = '结束阶段，你可以对一名体力值不小于你或者体力值为1的角色造成一点伤害',
    ['LuaMouhai-choose'] = '你可以发动“谋害”<br/> <b>操作提示</b>: 选择一名体力值不小于你或体力值为1的角色→点击确定<br/>',
    ['LuaChuanyi'] = '传艺',
    ['luachuanyi'] = '传艺',
    [':LuaChuanyi'] = '每名角色限一次，准备阶段，你可以失去一点体力上限并选择一名角色，令该角色获得“谋害”或“绝杀”',
    ['LuaChuanyi-choose'] = '你可以发动“传艺”，令一名其他角色获得“%src”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>',
    ['LuaChuanyiGiveUp'] = '本局游戏不再发动',
    ['Qiumu'] = '秋目',
    ['&Qiumu'] = '秋目',
    ['#Qiumu'] = '秋目',
    ['LuaPaozhuan'] = '抛砖',
    [':LuaPaozhuan'] = '当其他角色获得你的牌时，你可对其造成一点伤害',
    ['LuaYinyu'] = '引玉',
    [':LuaYinyu'] = '一名角色的出牌阶段开始时，你可以展示一张手牌并交给该角色。若如此做，该角色在出牌阶段使用与此牌类型一致的牌时，你可令其摸一张牌',
    ['@LuaYinyu-show'] = '你可以展示一张手牌发动“引玉”',
    ['SPRinsan'] = 'SP磷酸',
    ['&SPRinsan'] = 'SP磷酸',
    ['#SPRinsan'] = '工口上手',
    ['LuaQingyu'] = '情欲',
    [':LuaQingyu'] = '锁定技，出牌阶段，你使用牌没有距离与次数限制；当你于出牌阶段造成伤害后，你需执行以下一项：1.若你的手牌上限大于0，令你本回合的手牌上限-1，然后摸一张牌；2.令本回合手牌上限+1',
    ['LuaJiaoxie'] = '缴械',
    ['LuaQingyuChoice1'] = '本回合内手牌上限 -1，摸一张牌',
    ['LuaQingyuChoice2'] = '本回合内手牌上限 +1',
    [':LuaJiaoxie'] = '当你受到有来源的伤害后，若伤害来源没有被“缴械”，你可以废除其装备区，该角色的下一个回合开始时恢复装备区；若该角色处于出牌阶段，所有结算结束后该角色结束出牌阶段',
    ['LuaShulian'] = '熟练',
    [':LuaShulian'] = '锁定技，你不是延时类锦囊的合法目标；锁定技，你的非锁定技不会失效',
    ['LuaShulian-choose'] = '你可以选择一名角色，废除他的判定区',
    ['LuaShulian-forbid'] = '熟练教导',
    ['LuaShulianForbidden'] = '熟练',
    ['Anan'] = '暗暗',
    ['&Anan'] = '暗暗',
    ['#Anan'] = '榨汁姬',
    ['LuaZhazhi'] = '榨汁',
    [':LuaZhazhi'] = '一名其他角色的出牌阶段开始时，若你的武将牌正面向上，你可以翻面并展示该角色的所有手牌。然后该角色选择以下一项执行：1.将手牌中所有杀和黑色锦囊牌当作一张杀对你使用；2.本回合造成的所有伤害-1',
    ['#LuaZhazhi'] = '%from 的“<font color="yellow"><b>榨汁</b></font>”生效，伤害值由 %arg2 减为 %arg',
    ['LuaZhazhiChoice1'] = '将所有【杀】和黑色锦囊牌当作【杀】使用',
    ['LuaZhazhiChoice2'] = '本回合造成的所有伤害-1',
    ['LuaJueding'] = '绝顶',
    [':LuaJueding'] = '锁定技，当你的武将牌背面向上时，你不能使用和打出牌；当你受到伤害时，若你的武将牌背面朝上，你将武将牌翻回正面',
    ['#LuaJuedingDisable'] = '%from 的“%arg”被触发，将不能再使用打出牌',
    ['#LuaJuedingAvailable'] = '%from 的“%arg”被触发，将可以使用打出牌',
    ['Erenlei'] = '饿人类',
    ['&Erenlei'] = '饿人类',
    ['#Erenlei'] = '哔哔机',
    ['LuaShaika'] = '晒卡',
    ['luashaika'] = '晒卡',
    [':LuaShaika'] = '锁定技，当一张牌进入弃牌堆后，本回合内与此牌同名的卡牌不能以此法弃置\
    出牌阶段每名角色限一次，你可以弃置至少一张牌且其中包含锦囊牌，并指定一名其他角色，该角色选择以下一项执行：\
    1.弃置X+1张牌（X为你以此法弃置的牌数）\
    2.受到你造成的一点伤害',
    ['@LuaShaika'] = '%src 对你发动了“晒卡”，你需要弃置 %arg 张牌，或者点击“取消”受到一点伤害',
    ['LuaChutou'] = '出头',
    [':LuaChutou'] = '锁定技，当你的牌不因此技能而弃置时，你摸一张牌。当你摸牌后手牌数为全场唯一最多时，你弃置一张牌',
    ['Yaoyu'] = '西行寺妖羽',
    ['&Yaoyu'] = '妖羽',
    ['#Yaoyu'] = '孤星',
    ['LuaYingshi'] = '影噬',
    [':LuaYingshi'] = '锁定技，当一名角色死亡后，你恢复一点体力。你杀死一名角色后须执行以下一项：1.增加一点体力上限并摸3张牌，2.减一点体力上限并获得该角色的一个技能。（不能为觉醒技）',
    ['LuaYingshiChoice1'] = '增加一点体力上限并摸三张牌',
    ['LuaYingshiChoice2'] = '失去一点体力上限并获得其一个觉醒技以外的技能',
    ['LuaWangming'] = '亡命',
    [':LuaWangming'] = '锁定技，当其他角色因你造成的伤害而进入濒死状态时，其直接死亡',
    ['Shayu'] = '纱羽',
    ['&Shayu'] = '纱羽',
    ['#Shayu'] = '机屑人',
    ['LuaTianfa'] = '天罚',
    [':LuaTianfa'] = '锁定技，每名角色的回合结束后，你从牌堆中随机展示一张牌并将其置入弃牌堆。若这张牌为黑桃2～9，则该角色受到3点无伤害来源的雷属性伤害。当你死亡时，你令一名其他角色获得该技能',
    ['@LuaTianfa-choose'] = '请选择一名其他角色获得“天罚”',
    ['LuaZhixie'] = '智屑',
    ['luazhixie'] = '智屑',
    [':LuaZhixie'] = '你可以将锦囊牌当成铁索连环使用或重铸；结束阶段，你可以横置至多X名角色（X为你出牌阶段发动智屑的次数）',
    ['@LuaZhixie'] = '你可以发动“智屑”，横置至多 %arg 名角色',
    ['~LuaZhixie'] = '选择若干名角色→点击确定',
    ['LuaJixie'] = '机械',
    [':LuaJixie'] = '锁定技，当你受到雷属性伤害时，你摸一张牌，然后本次伤害-1',
    ['Yeniao'] = '夜鸟',
    ['&Yeniao'] = '夜鸟',
    ['#Yeniao'] = '魅魔酱',
    ['LuaFumo'] = '附魔',
    [':LuaFumo'] = '你可以将至少两张牌当作【杀】使用。若你使用的牌中包含有：\
    1. 杀，则你可以额外选择X个目标（X为【杀】的数量）\
    2. 有红色牌，则该杀无距离限制\
    3. 有黑色牌，该杀伤害+1\
    4. 有锦囊牌，你弃置目标2张牌\
    5. 有装备牌，该【杀】无法使用【闪】响应',
    ['@LuaFumo'] = '你可以发动“附魔”选择额外的目标，还可以选择至多 %arg 名角色',
    ['Linxi'] = '文爻林夕',
    ['&Linxi'] = '林夕',
    ['#Linxi'] = '安汐之镜',
    ['LuaTaose'] = '桃色',
    [':LuaTaose'] = '出牌阶段限一次，你可以将一张红桃牌交给一名其他角色，然后获得该角色每个区域各一张牌。若该角色为异性，则视为你对其使用一张【杀】，且此【杀】造成的伤害+1',
    ['luataose'] = '桃色',
    ['Ajie'] = '阿杰',
    ['&Ajie'] = '阿杰',
    ['#Ajie'] = '嘉心糖',
    ['LuaJiaren'] = '嘉人',
    [':LuaJiaren'] = '结束阶段，你可以判定，若如此做，直到你的下一个回合开始前，你不是与判定牌花色相同【杀】的合法目标',
    ['#LuaJiarenForbidSlash'] = '%from 的“%arg”生效，在其下回合开始前不再是%arg2杀的合法目标',
    ['LuaFabing'] = '发病',
    [':LuaFabing'] = '锁定技，你属性杀的基础伤害+1',
    ['LuaChengsheng'] = '成圣',
    [':LuaChengsheng'] = '目标含有你的锦囊生效时，你可以摸一张牌。若你回合内发动该技能，你可以跳过弃牌阶段',
    ['Shatang'] = '砂糖',
    ['&Shatang'] = '砂糖',
    ['#Shatang'] = '捷足先登',
    ['LuaXiandeng'] = '先登',
    [':LuaXiandeng'] = '锁定技，游戏第一个回合由你执行；出牌阶段，你使用的第一张杀不计入次数且无距离限制',
    ['#LuaXiandeng'] = '%from 的“%arg”被触发，将执行第一个回合',
    ['LuaZhiyuan'] = '支援',
    [':LuaZhiyuan'] = '<font color = "green"><b>每回合每个选项限一次</b></font>，准备阶段与结束阶段，你可以令任意名手牌数不大于体力值的角色各摸1张牌，或令一名手牌数大于体力值的角色回复1点体力',
    ['luazhiyuan'] = '支援',
    ['@LuaZhiyuan'] = '你可以发动“支援”，令若干角色摸牌或一名角色回复体力',
    ['~LuaZhiyuan'] = '选择若干名合法角色→点击“确定”',
    ['Dalaojiang'] = '大佬酱',
    ['&Dalaojiang'] = '大佬酱',
    ['#Dalaojiang'] = '奆佬酱',
    ['LuaYishi'] = '易势',
    [':LuaYishi'] = '转换技，当你受到伤害或对其他角色造成伤害时，你可以：①令本次伤害＋1；②令本次伤害—1',
    [':LuaYishi1'] = '转换技，当你受到伤害或对其他角色造成伤害时，你可以：①令本次伤害＋1；<font color=\"#01A5AF\"><s>②令本次伤害—1</font></s>',
    [':LuaYishi2'] = '转换技，当你受到伤害或对其他角色造成伤害时，你可以：<font color=\"#01A5AF\"><s>①令本次伤害＋1</font></s>；②令本次伤害—1',
    ['LuaYishiFrom:prompt'] = '你可以发动“易势”，令对 %src 造成的伤害 %arg',
    ['LuaYishiTo:prompt'] = '你可以发动“易势”，令受到的伤害 %arg',
    ['#LuaYishi'] = '%from 发动了“%arg”, %to 受到的伤害 %arg2',
    ['LuaManyan'] = '蔓延',
    [':LuaManyan'] = '锁定技，当你打出牌或使用牌结算完毕后，若有角色与横置的角色距离为1，你需横置其中的一名角色；若没有，你执行以下一项：1.对一名横置的角色造成1点火属性伤害，2.横置一名角色',
    ['@LuaManyan-choose'] = '你须横置一名与横置角色距离为1的角色',
    ['LuaManyanFireDamage'] = '对一名横置的角色造成1点火属性伤害',
    ['LuaManyanChain'] = '横置一名角色',
    ['@LuaManyanChain-choose'] = '你须选择一名未横置的角色横置之',
    ['@LuaManyanFireDamage-choose'] = '你须选择一名横置的角色，对其造成一点火属性伤害',
}
