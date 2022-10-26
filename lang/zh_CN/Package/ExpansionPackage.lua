-- translation for Expansion Package

return {
    ['ExpansionPackage'] = '扩展武将包',
    ['ExWangyuanji'] = '王元姬',
    ['&ExWangyuanji'] = '王元姬',
    ['#ExWangyuanji'] = '清雅抑华',
    ['LuaQianchong'] = '谦冲',
    [':LuaQianchong'] = '锁定技，若你的装备区所有牌为黑色，则你拥有“帷幕”；若你的装备区所有牌为红色，则你拥有“明哲”；\
    出牌阶段开始时，若你不满足上述条件，则你选择一种类型的牌，本回合使用此类型的牌无次数和距离限制',
    ['#LuaQianchongChoice'] = '%from 选择了 %arg，本回合其使用 %arg 无距离次数限制',
    ['LuaWeimu'] = '帷幕',
    [':LuaWeimu'] = '锁定技，你不是黑色锦囊牌的合法目标',
    ['LuaMingzhe'] = '明哲',
    [':LuaMingzhe'] = '当你于回合外因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌',
    ['LuaShangjian'] = '尚俭',
    [':LuaShangjian'] = '锁定技，任意角色的结束阶段开始时，若你于本回合内失去的牌不大于体力值，你摸等量的牌',
    ['ExXurong'] = '徐荣',
    ['&ExXurong'] = '徐荣',
    ['#ExXurong'] = '玄菟战魔',
    ['LuaXionghuo'] = '凶镬',
    [':LuaXionghuo'] = '游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，你对有此标记的角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”标记并随机执行一项：\
        1.受到1点火焰伤害且本回合不能对你使用【杀】\
        2.失去1点体力且本回合手牌上限-1\
        3.你获得其一张手牌和一张装备区里的牌',
    ['@baoli'] = '暴戾',
    ['luaxionghuo'] = '凶镬',
    ['LuaShajue'] = '杀绝',
    [':LuaShajue'] = '锁定技，其他角色进入濒死状态时，若其体力小于0，则你获得一个“暴戾”标记，并获得使其进入濒死状态的牌',
    ['ExCaoying'] = '曹婴',
    ['&ExCaoying'] = '曹婴',
    ['#ExCaoying'] = '龙城凤鸣',
    ['LuaLingren'] = '凌人',
    [':LuaLingren'] = '出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一个目标的手牌是否有基本牌、锦囊牌或装备牌。\
    至少猜对一项则此牌伤害+1；至少猜对两项则你摸两张牌；猜对三项则你获得“奸雄”和“行殇”直到你下回合开始',
    ['BasicCardGuess'] = '基本牌',
    ['TrickCardGuess'] = '锦囊牌',
    ['EquipCardGuess'] = '装备牌',
    ['Have'] = '有',
    ['NotHave'] = '没有',
    ['LuaLingren-choose'] = '你可以发动“凌人”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>',
    ['LuaFujian'] = '伏间',
    [':LuaFujian'] = '锁定技，结束阶段开始时，你随机观看一名其他角色的手牌',
    ['LuaJianxiong'] = '奸雄',
    [':LuaJianxiong'] = '当你受到伤害后，你可以摸一张牌并获得造成此伤害的牌',
    ['LuaXingshang'] = '行殇',
    [':LuaXingshang'] = '当其他角色死亡时，你可以获得其所有牌',
    ['ExLijue'] = '李傕',
    ['&ExLijue'] = '李傕',
    ['#ExLijue'] = '兵道诡谲',
    ['LuaYisuan'] = '亦算',
    [':LuaYisuan'] = '出牌阶段限一次，当你使用的锦囊牌进入弃牌堆时，你可以减一点体力上限，从弃牌堆获得之',
    ['LuaLangxi'] = '狼袭',
    [':LuaLangxi'] = '准备阶段开始时，你可以对一名体力值小于等于你的角色造成0-2点随机伤害',
    ['LuaLangxi-choose'] = '你可以发动“狼袭”<br/> <b>操作提示</b>: 选择一名体力值不大于你的角色→点击确定<br/>',
    ['ExCaochun'] = '曹纯',
    ['&ExCaochun'] = '曹纯',
    ['#ExCaochun'] = '虎豹骑首',
    ['LuaShanjia'] = '缮甲',
    [':LuaShanjia'] = '出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（本局游戏你每失去过一张装备区里的牌，便少弃置一张），若你本次没有弃置基本牌或锦囊牌，可视为使用一张【杀】（不计入次数限制）',
    ['luashanjia'] = '缮甲',
    ['LuaShanjia_throw'] = '请弃置若干张牌',
    ['~LuaShanjia'] = '选择若干张牌→选择出【杀】目标（如果有）→点击确定',
    ['@luashanjia'] = '缮甲',
    ['ExMaliang'] = '马良',
    ['&ExMaliang'] = '马良',
    ['#ExMaliang'] = '白眉智士',
    ['LuaZishu'] = '自书',
    [':LuaZishu'] = '锁定技，你的回合外，你获得的牌均会在当前回合结束后置入弃牌堆；你的回合内，当你不因此技能效果获得牌时，摸一张牌',
    ['LuaYingyuan'] = '应援',
    [':LuaYingyuan'] = '<font color="green"><b>相同牌名的牌每回合限一次</b></font>，当你于回合内使用的牌置入弃牌堆后，你可以将之交给一名其他角色。',
    ['@LuaYingyuanTo'] = '你可以选择一名其他角色，将 %src 交给他',
    ['ExJiakui'] = '贾逵',
    ['&ExJiakui'] = '贾逵',
    ['#ExJiakui'] = '肃齐万里',
    ['LuaZhongzuo'] = '忠佐',
    [':LuaZhongzuo'] = '一名角色的回合结束时，若你于此回合内造成过或受到过伤害，则你可令一名角色摸两张牌。若你选择的角色已受伤，则你摸一张牌',
    ['@LuaZhongzuoChoose'] = '你可以选择一名角色发动“忠佐”，令其摸两张牌，若他已受伤，则你摸一张牌',
    ['LuaWanlan'] = '挽澜',
    [':LuaWanlan'] = '限定技，一名角色进入濒死状态时，你可弃置所有手牌令该角色回复体力至1点，然后你对当前回合角色造成一点伤害',
    ['@LuaWanlan'] = '挽澜',
    ['JieXusheng'] = '界徐盛',
    ['&JieXusheng'] = '界徐盛',
    ['#JieXusheng'] = '江东的铁壁',
    ['LuaPojun'] = '破军',
    [':LuaPojun'] = '当你使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值）；若如此做，当前回合结束阶段开始时，该角色获得这些牌。\
    你使用【杀】对手牌数与装备数均不大于你的角色造成伤害时，此伤害+1',
    ['#LuaPojunDamageUp'] = '%from 执行“<font color="yellow"><b>破军</b></font>”的效果，\
    %card 的伤害值 + <font color = "yellow"><b>1</b></font>',
    ['#LuaPojunDamageUpVirtualCard'] = '%from 执行“<font color="yellow"><b>破军</b></font>”的效果，\
        <font color = "yellow"><b>杀[无色]</b></font> 的伤害值 + <font color = "yellow"><b>1</b></font>',
    ['JieMadai'] = '界马岱',
    ['&JieMadai'] = '界马岱',
    ['#JieMadai'] = '临危受命',
    ['LuaMashu'] = '马术',
    [':LuaMashu'] = '锁定技，你计算与其他角色的距离-1；若你于出牌阶段未使用【杀】造成过伤害，你于结束阶段结束时，可以视为使用一张无距离限制的【杀】',
    ['@LuaMashuSlashTo'] = '你可以发动“马术”，视为对其他一名角色使用一张【杀】',
    ['LuaQianxi'] = '潜袭',
    [':LuaQianxi'] = '一名角色的回合开始时，若你与其的距离不大于1，你可以令其选择是否让你摸一张牌；若如此做，你须弃置一张手牌并指定一名距离为1的角色，令其本回合内不能使用和打出和你弃置的牌颜色相同的手牌',
    ['@LuaQianxi-choose'] = '请选择一名其他角色',
    ['@LuaQianxi-discard'] = '请弃置一张手牌',
    ['LuaQianxiDraw'] = '潜袭摸牌',
    ['#LuaQianxiDrawAccept'] = '%from 同意让 %to 摸牌',
    ['#LuaQianxiDrawRefuse'] = '%from 拒绝让 %to 摸牌',
    ['ExMajun'] = '马钧',
    ['&ExMajun'] = '马钧',
    ['#ExMajun'] = '没渊瑰璞',
    ['luajingxie'] = '精械',
    ['LuaJingxie'] = '精械',
    [':LuaJingxie'] = '出牌阶段，你可以展示一张防具牌或是【诸葛连弩】，若其在你的手牌中，你使用之，然后根据其牌名，在该装备还在装备区时你获得以下效果：\
        【诸葛连弩】：你的攻击范围+2\
        【八卦阵】：当你进行【八卦阵】判定时，梅花牌视为红桃牌\
        【仁王盾】：黑色【杀】和红桃【杀】对你无效\
        【白银狮子】：当其从你的装备区失去时，你摸2张牌\
        【藤甲】：防止你进入横置状态\
        当你进入濒死状态后，你可以重铸一张防具牌，若如此做，你将体力值回复至1',
    ['#LuaJingxie-Renwang'] = '%from 的“<font color="yellow"><b>精械</b></font>”被触发， %to 的【%arg】对其无效',
    ['LuaJingxie-Invoke'] = '你可以重铸一张防具牌，将体力值回复至1',
    ['luaqiaosistart'] = '巧思',
    ['LuaQiaosi'] = '巧思',
    ['luaqiaosi'] = '巧思',
    [':LuaQiaosi'] = '出牌阶段限一次，你可以表演“水转百戏图”来赢取相应的牌，然后你选择一项：1.弃置等量的牌；2.将等量的牌交给一名其他角色',
    ['LuaQiaosi_give'] = '你发动“巧思”处置 %src 张牌，选择交给其他角色或弃置',
    ['king'] = '君王',
    ['merchant'] = '商人',
    ['farmer'] = '农民',
    ['artisan'] = '工匠',
    ['scholar'] = '学者',
    ['~LuaQiaosi'] = '选择对应数量手牌→选择一名其他角色（可不选）→点击确定',
    ['ExYiji'] = '伊籍',
    ['&ExYiji'] = '伊籍',
    ['#ExYiji'] = '礼仁同渡',
    ['LuaJijie'] = '机捷',
    [':LuaJijie'] = '出牌阶段限一次，你可以观看牌堆底的一张牌，然后将其交给任意角色',
    ['luajijie'] = '机捷',
    ['@LuaJijiePlayer-Chosen'] = '你可选择一名其他角色交给其这张牌，或是点击取消将其交给自己',
    ['LuaJiyuan'] = '急援',
    [':LuaJiyuan'] = '当一名角色进入濒死状态或你交给一名其他角色牌时，你可令该角色摸一张牌',
    ['ExLifeng'] = '李丰',
    ['&ExLifeng'] = '李丰',
    ['#ExLifeng'] = '继父尽事',
    ['LuaTunchu'] = '屯储',
    [':LuaTunchu'] = '摸牌阶段，若你没有“粮”，你可以额外摸两张牌，若如此做，然后将任意张手牌置于你的武将牌上，称为“粮”，若你的武将牌上有“粮”，你不能使用【杀】',
    ['@LuaTunchu'] = '你可以发动“屯储”',
    ['~LuaTunchu'] = '选择若干张手牌→点击确定',
    ['luatunchu'] = '屯储',
    ['LuaLiang'] = '粮',
    ['LuaShuliang'] = '输粮',
    [':LuaShuliang'] = '一名角色的结束阶段开始时，若其手牌数小于体力值，你可以将一张“粮”置入弃牌堆，然后该角色摸两张牌',
    ['luashuliang'] = '输粮',
    ['@LuaShuliang'] = '你可以发动“输粮”，令当前回合角色摸2张牌',
    ['~LuaShuliang'] = '选择一张“粮”→点击确定',
    ['ExZhaotongZhaoguang'] = '赵统赵广',
    ['&ExZhaotongZhaoguang'] = '赵统赵广',
    ['#ExZhaotongZhaoguang'] = '身继龙魂',
    ['LuaYizan'] = '翊赞',
    [':LuaYizan'] = '你可以将一张基本牌和其他一张牌当任意基本牌使用或打出',
    [':LuaYizan2'] = '你可以将一张基本牌当任意基本牌使用或打出',
    ['LuaLongyuan'] = '龙渊',
    [':LuaLongyuan'] = '觉醒技，准备阶段开始时，若你已经已累计发动过3或更多次“翊赞”，你将“翊赞”改为“你可以将一张基本牌当任意基本牌使用或打出”',
    ['#LuaLongyuan'] = '%from 累计发动过 %arg 次“<font color="yellow"><b>翊赞</b></font>”，触发“%arg2”觉醒',
    ['yizan_slash'] = '翊赞',
    ['yizan_saveself'] = '翊赞',
    ['JieYanliangWenchou'] = '界颜良文丑',
    ['&JieYanliangWenchou'] = '界颜良文丑',
    ['#JieYanliangWenchou'] = '虎狼兄弟',
    ['LuaShuangxiong'] = '双雄',
    [':LuaShuangxiong'] = '摸牌阶段，你可以改为展示牌堆顶两张牌，获得其中一张牌，然后本回合你可以将与任意一张与该牌不同颜色的一张手牌当【决斗】使用；\
    当你因“双雄”受到伤害后，你可以获得此次【决斗】中其他角色打出的【杀】',
    ['JieLingtong'] = '界凌统',
    ['&JieLingtong'] = '界凌统',
    ['#JieLingtong'] = '豪情烈胆',
    ['LuaXuanfeng'] = '旋风',
    [':LuaXuanfeng'] = '当你于弃牌阶段弃置过至少两张牌，或当你失去装备区里的牌后，你可以弃置至多两名其他角色的共计两张牌。然后若此时是你的回合内，你可以对其中一名角色造成1点伤害',
    ['LuaXuanfengDamage-choose'] = '你可以对其中一名角色造成一点伤害',
    ['@xuanfeng-card'] = '你可以发动“旋风”，弃置至多两名其他角色的两张牌',
    ['~LuaXuanfeng'] = '选择一至两名其他角色→点击确定',
    ['luaxuanfeng'] = '旋风',
    ['throwone'] = '弃置该角色一张牌',
    ['throwtwo'] = '弃置该角色两张牌',
    ['LuaYongjin'] = '勇进',
    [':LuaYongjin'] = '限定技，出牌阶段，你可以移动场上的至多三张装备牌',
    ['@LuaYongjin'] = '你还可以发动至多 %arg 次“勇进”',
    ['@LuaYongjinMark'] = '勇进',
    ['~LuaYongjin'] = '选择移动装备的来源角色→选择要移动到的角色→点击确定',
    ['luayongjin'] = '勇进',
    ['@luayongjin'] = '勇进',
    ['ExShenpei'] = '审配',
    ['&ExShenpei'] = '审配',
    ['#ExShenpei'] = '正南义北',
    ['LuaLiezhi'] = '烈直',
    [':LuaLiezhi'] = '准备阶段，你可以选择至多两名其他角色，依次弃置其区域内的一张牌；若你受到伤害，则直至你的下个结束阶段时，此技能失效',
    ['lualiezhi'] = '烈直',
    ['@LuaLiezhi'] = '你可以发动“烈直”，弃置至多两名其他角色区域内各一张牌',
    ['~LuaLiezhi'] = '选择一至两名其他角色→点击确定',
    ['LuaShouye'] = '守邺',
    [':LuaShouye'] = '<font color="green"><b>每回合限一次</b></font>，当你成为其他角色使用牌的唯一目标后，你可以与其进行对策：若你对策成功，则此牌对你无效，且你获得此牌',
    ['syjg1'] = '全力攻城',
    ['syjg2'] = '分兵围城',
    ['syfy1'] = '开城诱敌',
    ['syfy2'] = '奇袭粮道',
    ['#ShouyeSucceed'] = '%from 守邺 <font color="yellow"><b>成功</b></font>',
    ['#ShouyeFailed'] = '%from 守邺 <font color="yellow"><b>失败</b></font>',
    ['ExYangbiao'] = '杨彪',
    ['#ExYangbiao'] = '德彰海內',
    ['&ExYangbiao'] = '杨彪',
    ['LuaZhaohan'] = '昭汉',
    [':LuaZhaohan'] = '锁定技，你的前四个准备阶段开始时加1点体力上限并回复1点体力，之后的三个准备阶段开始时减1点体力上限',
    ['LuaRangjie'] = '让节',
    [':LuaRangjie'] = '当你受到1点伤害后，你可以选择一项：1.移动场上一张牌；2.从牌堆中获得一张你指定类型的牌。然后你摸一张牌',
    ['@LuaRangjie'] = '你可以发动“让节”移动场上的一张牌，或是点击“取消”选择从牌堆中获取类型对应的牌',
    ['~LuaRangjie'] = '选择移动牌的来源角色→选择要移动到的角色→点击确定',
    ['moveOneCard'] = '移动场上的一张牌',
    ['obtainBasic'] = '从牌堆中获得基本牌',
    ['obtainTrick'] = '从牌堆中获得锦囊牌',
    ['obtainEquip'] = '从牌堆中获得装备牌',
    ['@LuaRangjieMoveFrom'] = '请选择你要移动牌的来源角色',
    ['@LuaRangjieMoveTo'] = '请选择此牌的目标角色',
    ['LuaYizheng'] = '义争',
    [':LuaYizheng'] = '出牌阶段限一次，你可以与一名体力值不大于你的角色拼点，若你：赢，其跳过下个摸牌阶段；没赢，你减1点体力上限',
    ['luayizheng'] = '义争',
    ['ExLuotong'] = '骆统',
    ['&ExLuotong'] = '骆统',
    ['#ExLuotong'] = '辨明大义',
    ['LuaQinzheng'] = '勤政',
    [':LuaQinzheng'] = '锁定技，你每使用或打出三张牌时，你随机获得一张【杀】或【闪】﹔每使用或打出五张牌时，你随机获得一张【桃】或【酒】﹔每使用或打出八张牌时，你随机获得一张【无中生有】或【决斗】',
    ['ExZhangyi'] = '张翼',
    ['&ExZhangyi'] = '张翼',
    ['#ExZhangyi'] = '亢锐怀忠',
    ['LuaZhiyi'] = '执义',
    [':LuaZhiyi'] = '锁定技，若你于一个回合内使用或打出过基本牌，则本回合的结束阶段，你选择一项：1.视为你使用一张你本回合使用或打出过的基本牌；2.摸一张牌',
    ['LuaZhiyiSlashTo'] = '请选择一名角色作为【杀】的目标',
    ['luazhiyidraw'] = '摸一张牌',
    ['JieLiru'] = '界李儒',
    ['&JieLiru'] = '界李儒',
    ['#JieLiru'] = '魔仕',
    ['LuaJuece'] = '绝策',
    [':LuaJuece'] = '结束阶段，你可以对本回合失去过牌的一名其他角色造成1点伤害',
    ['@LuaJueceDamageTo'] = '你可以选择一名在本回合内失去过牌的其他角色，对其造成一点伤害',
    ['LuaMieji'] = '灭计',
    ['luamieji'] = '灭计',
    ['@LuaMiejiDiscard'] = '请交出一张锦囊牌或者弃置两张非锦囊牌（先弃置第一张）',
    ['@LuaMiejiDiscardNonTrick'] = '请弃置一张非锦囊牌',
    [':LuaMieji'] = '出牌阶段限一次，你可以将一张黑色锦囊牌置于牌堆顶，令一名其他角色选择一项：1.交给你一张锦囊牌；2.依次弃置两张非锦囊牌（不足则弃置一张）',
    ['LuaFencheng'] = '焚城',
    [':LuaFencheng'] = '限定技，出牌阶段，你可以令所有其他角色依次选择一项：1. 弃置至少X张牌（若上一名进行选择的角色以此法弃置过牌，X为其以此法弃置的牌数+1，否则X为1）；2. 受到你造成的2点火焰伤害',
    ['luafencheng'] = '焚城',
    ['JieManchong'] = '界满宠',
    ['&JieManchong'] = '界满宠',
    ['#JieManchong'] = '政法兵谋',
    ['LuaJunxing'] = '峻刑',
    [':LuaJunxing'] = '出牌阶段限一次，你可以弃置任意张手牌并令一名其他角色选择一项：1.弃置等量的牌并失去1点体力；2.翻面，然后摸等量的牌',
    ['luajunxing'] = '峻刑',
    ['@LuaJunxing'] = '你可以弃置 %arg 张牌并失去一点体力，或者点击“取消”翻面并摸取等量的牌',
    ['LuaYuce'] = '御策',
    [':LuaYuce'] = '当你受到伤害后，你可以展示一张手牌，然后除非伤害来源弃置与你展示的牌类别不同的一张手牌，否则你回复1点体力',
    ['@LuaYuce-show'] = '你可以发动“御策”展示一张手牌',
    ['#addmaxhp'] = '%from 增加了 %arg 点体力上限',
    ['JieLiaohua'] = '界廖化',
    ['&JieLiaohua'] = '界廖化',
    ['#JieLiaohua'] = '历经沧桑',
    ['LuaDangxian'] = '当先',
    [':LuaDangxian'] = '锁定技，回合开始时，你从弃牌堆获得一张【杀】并执行一个额外的出牌阶段',
    ['#LuaDangxianExtraPhase'] = '%from 将执行一个额外的出牌阶段',
    ['LuaFuli'] = '伏枥',
    [':LuaFuli'] = '限定技，当你处于濒死状态时，你可以将体力回复至X点（X为全场势力数）。然后若你的体力值全场唯一最大，你翻面',
    ['JieZhuran'] = '界朱然',
    ['&JieZhuran'] = '界朱然',
    ['#JieZhuran'] = '不动之督',
    ['LuaDanshou'] = '胆守',
    [':LuaDanshou'] = '其他角色的结束阶段，若你本回合未成为过其使用牌的目标，你摸一张牌；否则你可以弃置X张牌，对其造成1点伤害（X为你本回合成为其使用牌的目标的次数）',
    ['@LuaDanshou'] = '你可以弃置 %arg 张牌对当前回合角色造成一点伤害',
    ['JieYujin'] = '界于禁',
    ['&JieYujin'] = '界于禁',
    ['#JieYujin'] = '弗克其终',
    ['LuaJieyue'] = '节钺',
    [':LuaJieyue'] = '结束阶段，你可将一张牌交给一名其他角色，令其选择一项：1.保留一张手牌和一张装备区内的牌，然后弃置其余的牌；2.令你摸三张牌',
    ['luajieyue'] = '节钺',
    ['@LuaJieyue'] = '你可以发动“节钺”，令一名其他角色选择弃牌或者让你摸牌',
    ['~LuaJieyue'] = '选择一张牌→选择一名其他角色→点击确定',
    ['ExTenYearLiuzan'] = '留赞-十周年',
    ['&ExTenYearLiuzan'] = '留赞',
    ['#ExTenYearLiuzan'] = '啸天亢声',
    ['LuaFenyin'] = '奋音',
    [':LuaFenyin'] = '锁定技，你的回合内，当一张牌进入弃牌堆后，若此回合内没有此花色的牌进入过弃牌堆，你摸一张牌',
    ['LuaLiji'] = '力激',
    [':LuaLiji'] = '<font color="green"><b>出牌阶段限零次</b></font>，你可以弃置一张牌，然后对一名其他角色造成1点伤害\
        你的回合内，本回合进入弃牌堆的牌每次达到“八”的倍数张时（全场角色小于5时改为“四”的倍数），此技能使用次数+1',
    ['lualiji'] = '力激',
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
    ['#test'] = '%arg',
    ['ExZhouchu'] = '周处',
    ['&ExZhouchu'] = '周处',
    ['#ExZhouchu'] = '英情天逸',
    ['LuaXianghai'] = '乡害',
    [':LuaXianghai'] = '锁定技，场上所有其他角色的手牌上限-1，你手牌区所有装备牌均视为【酒】',
    ['LuaChuhai'] = '除害',
    ['luachuhai'] = '除害',
    [':LuaChuhai'] = '出牌阶段限一次，你可以摸一张牌，然后与一名其他角色拼点，若你赢，你观看其手牌，然后从牌堆或弃牌堆中获得其从手牌中拥有的牌类型各一张\
    当你于此阶段对其造成伤害后，将牌堆或弃牌堆中一张空置装备栏对应类型的装备牌置入你的装备区',
    ['JieSunce'] = '界孙策',
    ['&JieSunce'] = '界孙策',
    ['#JieSunce'] = '江东的小霸王',
    ['LuaJiang'] = '激昂',
    [':LuaJiang'] = '当你使用【决斗】或红色【杀】指定目标后，或成为【决斗】或红色【杀】的目标后，你可以摸一张牌',
    ['LuaHunzi'] = '魂姿',
    [':LuaHunzi'] = '觉醒技，准备阶段，若你的体力值不大于2，你减1点体力上限，回复1点体力，然后获得“英姿”和“英魂”',
    ['#LuaHunzi'] = '%from 的体力值为 %arg，触发“%arg2”觉醒',
    ['LuaYinghun'] = '英魂',
    [':LuaYinghun'] = '准备阶段，若你已受伤，你可以选择一名其他角色并选择一项：1.令其摸X张牌，然后弃置一张牌；2.令其摸一张牌，然后弃置X张牌（X为你已损失的体力值）',
    ['LuaYingzi'] = '英姿',
    [':LuaYingzi'] = '锁定技，摸牌阶段，你多摸一张牌；你的手牌上限为X（X为你的体力上限）',
    ['luayinghun'] = '英魂',
    ['@yinghun'] = '你可以发动“英魂”',
    ['~LuaYinghun'] = '选择一名其他角色→点击确定',
    ['d1tx'] = '令其摸1张牌，然后弃置X张牌',
    ['dxt1'] = '令其摸X张牌，然后弃置1张牌',
    ['LuaYinghunCard'] = '英魂',
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
    [':LuaMiewu'] = '<font color="green"><b>每回合限一次</b></font>，你可以弃1个“武库”，将一张牌当任意一张基本牌或锦囊牌使用或打出；若如此做，你摸一张牌',
    ['miewu_slash'] = '灭吴',
    ['miewu_saveself'] = '灭吴',
    ['ExChenzhen'] = '陈震',
    ['&ExChenzhen'] = '陈震',
    ['#ExChenzhen'] = '歃盟使节',
    ['LuaShameng'] = '歃盟',
    [':LuaShameng'] = '出牌阶段限一次，你可以弃置两张颜色相同的手牌，令一名其他角色摸两张牌，然后你摸三张牌',
    ['luashameng'] = '歃盟',
    ['ExGongsunkang'] = '公孙康',
    ['&ExGongsunkang'] = '公孙康',
    ['#ExGongsunkang'] = '沸流腾蛟',
    ['LuaJuliao'] = '据辽',
    [':LuaJuliao'] = '锁定技，其他角色计算与你的距离始终+X（X为场上势力数-1）',
    ['LuaTaomie'] = '讨灭',
    ['@LuaTaomie'] = '讨灭',
    ['@LuaTaomie-give'] = '你可以将这张牌交给除 %src 以外的角色',
    [':LuaTaomie'] = '当你受到伤害后或你造成伤害后，你可以令伤害来源或受伤角色获得“讨灭”标记(如场上已有标记则转移给该角色);\
        当你对有标记的角色造成伤害时，选择一项: 1.此伤害+1; 2.你获得其区域内的一张牌并可将之交给另一名角色; 3.依次执行前两项并于伤害结算后弃置其“讨灭”标记',
    ['addDamage'] = '令此伤害+1',
    ['getOneCard'] = '获得其区域内的一张牌',
    ['removeMark'] = '执行前两项并移除其讨灭标记',
    ['#choose'] = '%from 选择了 %arg',
    ['ExZhangji'] = '张济',
    ['&ExZhangji'] = '张济',
    ['#ExZhangji'] = '平阳侯',
    ['LuaLveming'] = '掠命',
    [':LuaLveming'] = '出牌阶段限一次，你可以令装备区里的牌少于你的一名角色选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；不同，你随机获得其区域里的一张牌',
    ['lualveming'] = '掠命',
    ['LuaTunjun'] = '屯军',
    [':LuaTunjun'] = '限定技，出牌阶段，你可以令一名角色随机使用牌堆中的X张类型不同的装备牌（不替换已有装备，X为你发动过“掠命”的次数）',
    ['@LuaTunjun'] = '屯军',
    ['luatunjun'] = '屯军',
    ['ExTenYearDongcheng'] = '董承-十周年',
    ['&ExTenYearDongcheng'] = '董承',
    ['#ExTenYearDongcheng'] = '扬义誓诛',
    ['LuaXuezhao'] = '血诏',
    ['luaxuezhao'] = '血诏',
    [':LuaXuezhao'] = '出牌阶段限一次，你可弃置一张手牌并选择至多X名其他角色（X为你的体力值）。这些角色依次选择是否交给你一张牌\
    若选择是，该角色摸一张牌且你本回合可多使用一张【杀】；若选择否，该角色本回合无法响应你使用的牌',
    ['@LuaXuezhao-give'] = '%src 发动了“血诏”，请交给 %src 一张手牌，否则你本回合无法响应 %src 使用的牌',
    ['ExTenYearWanglang'] = '王朗-十周年',
    ['&ExTenYearWanglang'] = '王朗',
    ['#ExTenYearWanglang'] = '凤鹛',
    ['LuaGushe'] = '鼓舌',
    ['luagushe'] = '鼓舌',
    ['@LuaGushe'] = '饶舌',
    ['@LuaGusheDiscard'] = '你需要弃置一张牌或者点击取消让 %src 摸一张牌',
    [':LuaGushe'] = '出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。若你没赢，获得1个“饶舌”标记\
    当你一回合内累计7-X（X为鼓舌标记数）次拼点赢时，本回合此技能失效\
        锁定技，当你的饶舌标记达到7时，你死亡',
    ['@LuaGushePindian'] = '请选择一张手牌进行拼点',
    ['LuaJici'] = '激词',
    [':LuaJici'] = '锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。当你死亡时，杀死你的角色弃置7-X张牌并失去1点体力',
    ['ExTenYearZhaoxiang'] = '赵襄-十周年',
    ['&ExTenYearZhaoxiang'] = '赵襄',
    ['#ExTenYearZhaoxiang'] = '拾梅鹊影',
    ['LuaFanghun'] = '芳魂',
    [':LuaFanghun'] = '当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记来发动“龙胆”并摸一张牌',
    ['@LuaFanghun'] = '梅影',
    ['LuaFuhan'] = '扶汉',
    ['@LuaFuhan'] = '扶汉',
    [':LuaFuhan'] = '限定技，回合开始时，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活角色数且至少为4）蜀势力武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）\
    若此时你是体力值最低的角色，你回复1点体力',
    ['JieZhonghui'] = '界钟会',
    ['&JieZhonghui'] = '界钟会',
    ['#JieZhonghui'] = '桀骜的野心家',
    ['LuaQuanji'] = '权计',
    [':LuaQuanji'] = '出牌阶段结束时，若你的手牌数大于体力值，或当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为权。锁定技，你的手牌上限+X（X为权的数量）',
    ['LuaZili'] = '自立',
    [':LuaZili'] = '觉醒技，准备阶段，若“权”的数量不小于3，你选择一项：1.回复1点体力；2.摸两张牌。然后减1点体力上限，获得“排异”',
    ['#LuaZili'] = '%from 的“权”数达到 %arg，触发“<font color="yellow"><b>自立</b></font>”觉醒',
    ['zilirecover'] = '回复一点体力',
    ['zilidraw'] = '摸两张牌',
    ['LuaPaiyi'] = '排异',
    ['luapaiyi'] = '排异',
    [':LuaPaiyi'] = '<font color="green"><b>出牌阶段每名角色限一次</b></font>，你可以移去一张“权”，令一名角色摸两张牌。若该角色的手牌比你多，则你对其造成1点伤害',
    ['ExStarXuhuang'] = '星徐晃',
    ['&ExStarXuhuang'] = '星徐晃',
    ['#ExStarXuhuang'] = '沉详性严',
    ['LuaZhiyan'] = '治严',
    [':LuaZhiyan'] = '<font color="green"><b>出牌阶段各限一次</b></font>，你可以选择一项执行对应效果：\
    1.你可以将手牌数摸至体力上限，然后本回合不能对其他角色使用牌\
    2.你可以将X张手牌交给一名其他角色（X为你的手牌数减去体力值）',
    ['luazhiyangive'] = '治严',
    ['luazhiyandraw'] = '治严',
    ['ExTenYearGuansuo'] = '关索-十周年',
    ['&ExTenYearGuansuo'] = '关索',
    ['#ExTenYearGuansuo'] = '倜傥子侠',
    ['LuaZhengnan'] = '征南',
    [':LuaZhengnan'] = '<font color="green"><b>每名角色限一次</b></font>，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择以下一项执行：\
    1. 获得“武圣”、“当先”和“制蛮”中一个你未拥有的技能\
    2. 摸三张牌',
    ['LuaZhiman'] = '制蛮',
    [':LuaZhiman'] = '当你对其他角色造成伤害时，你可以防止此伤害，然后获得其区域里的一张牌',
    ['ExStarGanning'] = '星甘宁',
    ['&ExStarGanning'] = '星甘宁',
    ['#ExStarGanning'] = '铃震没羽',
    ['LuaJinfan'] = '锦帆',
    [':LuaJinfan'] = '弃牌阶段开始时，你可以将任意张手牌置于武将牌上，称为“铃”（每种花色的“铃”至多各一张）。当你需要使用或打出手牌时，你可以将“铃”视为你的牌使用或打出\
    当你的“铃”离开你的武将牌上时，你从牌堆中获得一张花色相同的牌',
    ['luajinfan'] = '锦帆',
    ['&luajinfanpile'] = '铃',
    ['@LuaJinfan'] = '你可以发动“锦帆”，将任意张不同花色手牌作为“铃”置于武将牌上',
    ['~LuaJinfan'] = '选择若干张手牌→点击确定',
    ['LuaSheque'] = '射却',
    [':LuaSheque'] = '一名其他角色的准备阶段，若其装备区有牌，你可以对其使用一张【杀】，此【杀】无视防具',
    ['@LuaSheque'] = '你可以对 %src 使用一张无视距离和防具的【杀】',
    ['JieCaozhi'] = '界曹植',
    ['&JieCaozhi'] = '界曹植',
    ['#JieCaozhi'] = '八斗之才',
    ['LuaLuoying'] = '落英',
    [':LuaLuoying'] = '当其他角色的一张梅花牌因弃置或判定而置入弃牌堆时，你可以获得之\
    ☆操作提示：当发动技能后会有即将获得牌的确认框，点击去掉不希望获得的牌，最后点击确定即可获得剩下的牌',
    ['LuaJiushi'] = '酒诗',
    [':LuaJiushi'] = '当你需要【酒】时，若你的武将牌正面向上，你可以翻面视为使用一张【酒】，当你于武将牌背面朝上状态受到伤害后，你可以翻面并获得牌堆中的一张随机锦囊',
    [':LuaJiushi2'] = '当你需要【酒】时，若你的武将牌正面向上，你可以翻面视为使用一张【酒】，当你于武将牌背面朝上状态受到伤害后，你可以翻面；当你翻面时，你获得牌堆中的一张锦囊',
    ['LuaChengzhang'] = '成章',
    [':LuaChengzhang'] = '觉醒技，准备阶段开始时，若你造成伤害与受伤害值之和累积7点或以上，则你回复1点体力并摸1张牌，然后修改【酒诗】',
    ['#LuaChengzhang'] = '%from 累计造成和受到伤害之和为 %arg，触发“%arg2”觉醒',
    ['JieChenqun'] = '界陈群',
    ['&JieChenqun'] = '界陈群',
    ['#JieChenqun'] = '万世臣表',
    ['LuaDingpin'] = '定品',
    [':LuaDingpin'] = '出牌阶段，你可以弃置一张牌（不能是你本回合以此法弃置过的类型）并选择一名角色，令其进行判定，若结果为：\
    黑色：该角色摸X张牌（X为当前体力值且最大为3），然后你于此回合内不能对其发动“定品”\
    红桃：你此次发动定品弃置的牌不计入弃置过的类型\
    方块：你翻面',
    ['luadingpin'] = '定品',
    ['LuaFaen'] = '法恩',
    [':LuaFaen'] = '当一名角色翻面或横置后，你可以令其摸一张牌',
    ['JieXunyu'] = '界荀彧',
    ['&JieXunyu'] = '界荀彧',
    ['#JieXunyu'] = '王佐之才',
    ['LuaQuhu'] = '驱虎',
    [':LuaQuhu'] = '出牌阶段限一次，你可以与体力值大于自己的一名角色拼点：若你赢，令该角色对其攻击范围内的另一名角色造成1点伤害；若你没赢，其对你造成1点伤害',
    ['luaquhu'] = '驱虎',
    ['LuaJieming'] = '节命',
    [':LuaJieming'] = '当你受到1点伤害后，可以令一名角色摸两张牌，然后若其手牌数小于其体力上限，你摸一张牌',
    ['ExSufei'] = '苏飞',
    ['&ExSufei'] = '苏飞',
    ['#ExSufei'] = '诤友投明',
    ['LuaZhengjian'] = '诤荐',
    [':LuaZhengjian'] = '锁定技，结束阶段，你令一名角色获得“诤荐”标记。你的下个回合开始时，该角色摸X张牌并清除“诤荐”标记（X为其获得标记后使用或打出牌的数量，至多为其体力上限且不大于5）',
    ['@LuaZhengjian-choose'] = '请选择一名角色，令其获得“诤荐”标记',
    ['LuaGaoyuan'] = '告援',
    [':LuaGaoyuan'] = '当你成为【杀】的目标时，你可以弃置一张牌，将此【杀】转移给有“诤荐”标记的角色（不能是此【杀】的使用者）',
    ['@LuaGaoyuan'] = '你可以弃置一张牌发动“告援”，将【杀】的目标转移给 %src',
    ['ExShenZhaoyun'] = '神赵云',
    ['&ExShenZhaoyun'] = '神赵云',
    ['#ExShenZhaoyun'] = '神威如龙',
    ['LuaJuejing'] = '绝境',
    [':LuaJuejing'] = '锁定技，你的手牌上限+2；当你进入或脱离濒死状态时，你摸一张牌',
    ['LuaLonghun'] = '龙魂',
    [':LuaLonghun'] = '你可以将至多两张花色相同的牌按下列规则使用或打出：红桃当【桃】；方块当火【杀】；梅花当【闪】；黑桃当【无懈可击】。\
    若你以此法使用了两张红色牌，则此牌回复值或伤害值+1。若你以此法使用了两张黑色牌，则你弃置当前回合角色一张牌',
    ['LuaLonghunTwo'] = '龙魂',
    ['#LuaLonghunAddDamage'] = '%from 的“<font color="yellow"><b>龙魂</b></font>”被触发，伤害值从 %arg 增加至 %arg2',
    ['ExZhuling'] = '朱灵',
    ['&ExZhuling'] = '朱灵',
    ['#ExZhuling'] = '良将之亚',
    ['LuaZhanyi'] = '战意',
    ['luazhanyi'] = '战意',
    [':LuaZhanyi'] = '出牌阶段限一次，你可以弃置一张牌并失去1点体力，然后你根据牌的种类获得以下效果直到出牌阶段结束。\
    基本牌：你可以将一张基本牌当成任意基本牌使用，你第一次因基本牌造成的伤害量或回复量+1；\
    锦囊牌：你摸三张牌且使用锦囊不能被【无懈可击】响应；\
    装备牌：你使用【杀】指定一名角色为目标后，该角色须弃置两张牌，然后你选择其中一张获得之',
    ['zhanyi_slash'] = '战意',
    ['zhanyi_saveself'] = '战意',
    ['ExGuozhao'] = '郭照',
    ['&ExGuozhao'] = '郭照',
    ['#ExGuozhao'] = '碧海青天',
    ['LuaPianchong'] = '偏宠',
    [':LuaPianchong'] = '摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，2.你每失去一张黑色牌时摸一张红色牌',
    ['LuaPianchongChoice1'] = '失去红牌摸黑牌',
    ['LuaPianchongChoice2'] = '失去黑牌摸红牌',
    ['LuaZunwei'] = '尊位',
    ['luazunwei'] = '尊位',
    [':LuaZunwei'] = '出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同',
    ['LuaZunweiChoice1'] = '将手牌数摸至与该角色相同（最多摸五张）',
    ['LuaZunweiChoice2'] = '随机使用牌堆中的装备牌至与该角色相同',
    ['LuaZunweiChoice3'] = '将体力回复至与该角色相同',
    ['JieDengai'] = '界邓艾',
    ['&JieDengai'] = '界邓艾',
    ['#JieDengai'] = '矫然的壮士',
    ['LuaTuntian'] = '屯田',
    [':LuaTuntian'] = '当你于回合外失去牌后，或于回合内因弃置而失去【杀】后，你可以进行判定，若结果：为红桃，你获得此判定牌；不为红桃，你将判定牌置于你的武将牌上，称为“田”\
    你计算与其他角色的距离-X（X为“田”的数量）',
    ['LuaZaoxian'] = '凿险',
    [':LuaZaoxian'] = '觉醒技，准备阶段，若“田”的数量大于等于3，你减1点体力上限，然后获得“急袭”。此回合结束后，你获得一个额外回合',
    ['#LuaZaoxianExtraTurn'] = '%from 的“%arg”被触发，将进行额外的一个回合',
    ['LuaJixi'] = '急袭',
    [':LuaJixi'] = '你可以将一张“田”当【顺手牵羊】使用',
    ['JieZhangjiao'] = '界张角',
    ['&JieZhangjiao'] = '界张角',
    ['#JieZhangjiao'] = '太平道人',
    ['LuaLeiji'] = '雷击',
    [':LuaLeiji'] = '当你使用或打出【闪】或【闪电】时，你可以进行判定；当你不因“暴虐”进行判定后，若判定结果为：黑桃，你可以选择一名其他角色，对其造成2点雷电伤害；梅花，你回复1点体力，然后你可以选择一名其他角色，对其造成1点雷电伤害',
    ['LuaGuidao'] = '鬼道',
    [':LuaGuidao'] = '当一名角色的判定牌生效前，你可以打出一张黑色牌替换之；若你打出的牌是黑桃2~9，则你摸一张牌',
    ['@LuaLeiji-choose-damage'] = '你可以选择一名其他角色，对其造成 %src 点雷电伤害',
    ['ExYuantanYuanshang'] = '袁谭袁尚',
    ['&ExYuantanYuanshang'] = '袁谭袁尚',
    ['#ExYuantanYuanshang'] = '兄弟阋墙',
    ['LuaNeifa'] = '内伐',
    [':LuaNeifa'] = '出牌阶段开始时，你可以摸两张牌或获得场上的一张牌，然后弃置一张牌。\
    若弃置的牌是基本牌，本回合你不能使用锦囊牌和装备牌且【杀】的使用次数+X且目标+1\
    若弃置的牌不是基本牌，本回合你不能使用基本牌，使用的普通锦囊牌的目标+1或-1，本回合前两次使用装备牌时摸X张牌（X为发动内伐时手牌中不能使用的牌且最多为5）',
    ['luaneifa'] = '内伐',
    ['@LuaNeifa'] = '你可以发动“内伐”',
    ['~LuaNeifa'] = '选择至多一名角色→点击确定',
    ['@LuaNeifa-discard'] = '请弃置一张牌',
    ['LuaNeifa-invoke'] = '你可以选择一名角色，使其成为或不再是 %src 的目标',
    ['#LuaNeifaAppend'] = '%to 成为了 %card 的目标',
    ['#LuaNeifaRemove'] = '%to 不再是 %card 的目标',
    ['ExMouHuangzhong'] = '谋黄忠',
    ['&ExMouHuangzhong'] = '谋黄忠',
    ['#ExMouHuangzhong'] = '没金铩羽',
    ['LuaLiegong'] = '烈弓',
    [':LuaLiegong'] = '①你使用【杀】时可以选择距离不大于此【杀】点数的角色为目标；\
    ②当你使用牌时，或成为其他角色使用牌的目标后，若此牌的花色未被记录，记录此花色；\
    ③当你使用【杀】指定一名角色为唯一目标后，你可以展示牌堆顶的X张牌（X为你已记录的花色数-1，且至少为0），其中每有一张已记录的花色的牌，此【杀】的伤害便+1，且其不能使用已记录的花色的牌响应此【杀】，然后此【杀】结算结束后，清除所有已记录的花色',
    ['@LuaLiegong-jink'] = '%src 使用了【杀】，请使用一张未被其“烈弓”记录过花色的【闪】',
    ['#LuaLiegongInvalidJink'] = '由于已被记录花色，%from 使用的 %card 无效',
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
    ['JieJiaxu'] = '界贾诩',
    ['&JieJiaxu'] = '界贾诩',
    ['#JieJiaxu'] = '冷酷的毒士',
    ['LuaWansha'] = '完杀',
    [':LuaWansha'] = '锁定技，你的回合内，只有你和处于濒死状态的角色才能使用【桃】；一名角色的濒死结算中，除你和濒死角色外的其他角色非锁定技无效',
    ['#LuaWanshaOne'] = '%from 的“%arg”被触发，只能 %from 自救',
    ['#LuaWanshaTwo'] = '%from 的“%arg”被触发，只有 %from 和 %to 才能救 %to',
    ['LuaLuanwu'] = '乱武',
    [':LuaLuanwu'] = '限定技，出牌阶段，你可以令所有其他角色除非对各自距离最小的另一名角色使用一张【杀】，否则失去1点体力',
    ['lualuanwu'] = '乱武',
    ['LuaJiejiaxuWeimu'] = '帷幕',
    [':LuaJiejiaxuWeimu'] = '锁定技，你不能成为黑色锦囊牌的目标；当你于回合内受到伤害时，防止此伤害',
    ['#LuaJiejiaxuWeimu'] = '%from 的“%arg2”被触发，防止了 %arg 点伤害',
    ['OLJieXunyu'] = 'OL界荀彧',
    ['&OLJieXunyu'] = '界荀彧',
    ['#OLJieXunyu'] = '王佐之才',
    ['LuaOLJieming'] = '节命',
    [':LuaOLJieming'] = '当你受到1点伤害后或死亡时，你可以令一名角色摸X张牌，然后将手牌弃至X张（X为其体力上限且最多为5）',
    ['ExShenGuojia'] = '神郭嘉',
    ['&ExShenGuojia'] = '神郭嘉',
    ['#ExShenGuojia'] = '星月奇佐',
    ['LuaHuishi'] = '慧识',
    [':LuaHuishi'] = '出牌阶段限一次，若你的体力上限小于10，你可以进行判定：若结果与此阶段内以此法进行判定的结果的花色均不同，且此时你的体力上限小于10，你可以重复此流程并加1点体力上限，然后你可以将所有生效的判定牌交给一名角色。\
    若其手牌数为全场最多，你减1点体力上限',
    ['luahuishi'] = '慧识',
    ['LuaHuishi-choose'] = '你可以选择一名角色获得这些牌，或点击“取消”将牌留给自己',
    ['#addMaxHp'] = '%from 增加了 %arg 点体力上限',
    ['LuaTianyi'] = '天翊',
    [':LuaTianyi'] = '觉醒技，准备阶段，若全场角色在本局游戏中均受到过伤害，你加2点体力上限，回复1点体力，然后令一名角色获得“佐幸”',
    ['LuaTianyi-choose'] = '请选择一名角色获得“佐幸”',
    ['#LuaTianyi'] = '场上角色均已受到过伤害，%from 的“%arg”被触发',
    ['LuaHuishiLimit'] = '辉逝',
    [':LuaHuishiLimit'] = '限定技，出牌阶段，你可以选择一名角色，其摸四张牌。若如此做，你减2点体力上限',
    ['luahuishilimit'] = '辉逝',
    ['@LuaHuishiLimit'] = '辉逝',
    ['LuaZuoxing'] = '佐幸',
    ['luazuoxing'] = '佐幸',
    [':LuaZuoxing'] = '出牌阶段限一次，若神郭嘉存活且体力上限大于1，你可令神郭嘉减1点体力上限。然后你可视为使用一张普通锦囊牌',
    ['JieXiahoudun'] = '界夏侯惇',
    ['&JieXiahoudun'] = '界夏侯惇',
    ['#JieXiahoudun'] = '独眼的罗刹',
    ['LuaQingjian'] = '清俭',
    [':LuaQingjian'] = '<font color="green"><b>每回合限一次</b></font>，当你于摸牌阶段外获得牌后，你可将任意张手牌扣置于武将牌上；\
    下个任意角色的结束阶段，你将这些牌交给其他角色，然后若你以此法交出的牌大于一张，则你摸一张牌',
    ['LuaQingjian-Storage'] = '你可以发动“清俭”，将任意张手牌置于武将牌上',
    ['LuaQingjian-Give'] = '你须发动“清俭”，将剩余的 %arg 张“清俭”牌交给其他角色',
    ['~LuaQingjian'] = '选择合适的牌→选择合适的目标→点击“确定”',
    ['luaqingjiansto'] = '清俭',
    ['luaqingjiangive'] = '清俭'
}
