-- translation for Expansion Package

return {
    ['ExpansionPackage'] = '扩展武将包',
    -- 通用
    ['#choose'] = '%from 选择了 %arg',
    ['#LuaSkillInvalidateCard'] = '%from 的“%arg2”效果被触发，【%arg】对其无效',
    ['#test'] = '%arg',
    -- 武将相关
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
        3.你随机获得其一张手牌和一张装备区里的牌',
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
    [':LuaYingyuan'] = '相同牌名的牌每回合限一次，当你于回合内使用的牌置入弃牌堆后，你可以将之交给一名其他角色。',
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
    [':LuaJingxie'] = '出牌阶段，你可以展示你手牌区或装备区里的一张防具牌或【诸葛连弩】，然后升级此牌；\
    当你进入濒死状态时，你可以重铸一张防具牌，然后将体力值回复至1点',
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
    [':LuaTunchu'] = '摸牌阶段，若你没有“粮”，你可以额外摸两张牌，然后将任意张手牌置于你的武将牌上，称为“粮”，若你的武将牌上有“粮”，你不能使用【杀】',
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
    [':LuaShouye'] = '每回合限一次，当你成为其他角色使用牌的唯一目标后，你可以与其进行对策：若你对策成功，则此牌对你无效，且此牌进入弃牌堆时改为由你获得',
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
    ['luajieyuediscard'] = '保留一张手牌和一张装备区内的牌',
    ['luajieyuedraw'] = '令发动“节钺”的角色摸三张牌',
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
    ['ExGongsunkang'] = '公孙康',
    ['&ExGongsunkang'] = '公孙康',
    ['#ExGongsunkang'] = '沸流腾蛟',
    ['LuaJuliao'] = '据辽',
    [':LuaJuliao'] = '锁定技，其他角色计算与你的距离始终+X（X为场上势力数-1）',
    ['LuaTaomie'] = '讨灭',
    ['@LuaTaomie'] = '讨灭',
    ['@LuaTaomie-give'] = '你可以将这张牌交给除你和 %src 以外的角色，或点击“取消”留给自己',
    [':LuaTaomie'] = '当你受到伤害后或你造成伤害后，你可以令伤害来源或受伤角色获得“讨灭”标记(如场上已有标记则转移给该角色);\
        你和拥有“讨灭”标记的角色互相视为在对方的攻击范围内。\
        当你对有标记的角色造成伤害时，选择一项: 1.此伤害+1; 2.你获得其区域内的一张牌并可将之交给另一名角色; 3.依次执行前两项并于伤害结算后弃置其“讨灭”标记',
    ['addDamage'] = '令此伤害+1',
    ['getOneCard'] = '获得其区域内的一张牌',
    ['removeMark'] = '执行前两项并移除其讨灭标记',
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
    [':LuaPaiyi'] = '出牌阶段每名角色各限一次，你可以移去一张“权”，令一名角色摸两张牌。若该角色的手牌比你多，则你对其造成1点伤害',
    ['ExStarXuhuang'] = '星徐晃',
    ['&ExStarXuhuang'] = '星徐晃',
    ['#ExStarXuhuang'] = '沉详性严',
    ['LuaZhiyan'] = '治严',
    [':LuaZhiyan'] = '出牌阶段各限一次，你可以选择一项执行对应效果：\
    1.你可以将手牌数摸至体力上限，然后本回合不能对其他角色使用牌\
    2.你可以将X张手牌交给一名其他角色（X为你的手牌数减去体力值）',
    ['luazhiyangive'] = '治严',
    ['luazhiyandraw'] = '治严',
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
    ['JieJiaxu'] = '界贾诩',
    ['&JieJiaxu'] = '界贾诩',
    ['#JieJiaxu'] = '冷酷的毒士',
    ['LuaWansha'] = '完杀',
    [':LuaWansha'] = '锁定技，你的回合内，只有你和处于濒死状态的角色才能使用【桃】；一名角色的濒死结算中，除你和濒死角色外的其他角色非锁定技无效',
    ['#LuaWanshaOne'] = '%from 的“%arg”被触发，只能 %from 自救',
    ['#LuaWanshaTwo'] = '%from 的“%arg”被触发，只有 %from 和 %to 才能救 %to',
    ['#LuaWanshaSkillInvalid'] = '%from 的“%arg”被触发，%to 的非锁定技失效',
    ['LuaLuanwu'] = '乱武',
    [':LuaLuanwu'] = '限定技，出牌阶段，你可以令所有其他角色除非对各自距离最小的另一名角色使用一张【杀】，否则失去1点体力',
    ['lualuanwu'] = '乱武',
    ['LuaJiejiaxuWeimu'] = '帷幕',
    [':LuaJiejiaxuWeimu'] = '锁定技，你不能成为黑色锦囊牌的目标；当你于回合内受到伤害时，防止此伤害',
    ['#LuaJiejiaxuWeimu'] = '%from 的“%arg2”被触发，防止了 %arg 点伤害',
    ['JieXiahoudun'] = '界夏侯惇',
    ['&JieXiahoudun'] = '界夏侯惇',
    ['#JieXiahoudun'] = '独眼的罗刹',
    ['LuaQingjian'] = '清俭',
    [':LuaQingjian'] = '每回合限一次，当你于摸牌阶段外获得牌后，你可将任意张手牌扣置于武将牌上；\
    下个任意角色的结束阶段，你将这些牌交给其他角色，然后若你以此法交出的牌大于一张，则你摸一张牌',
    ['LuaQingjian-Storage'] = '你可以发动“清俭”，将任意张手牌置于武将牌上',
    ['LuaQingjian-Give'] = '你须发动“清俭”，将剩余的 %arg 张“清俭”牌交给其他角色',
    ['~LuaQingjian'] = '选择合适的牌→选择合适的目标→点击“确定”',
    ['luaqingjiansto'] = '清俭',
    ['luaqingjiangive'] = '清俭',
    ['ExSunhanhua'] = '孙寒华',
    ['&ExSunhanhua'] = '孙寒华',
    ['#ExSunhanhua'] = '挣绽的青莲',
    ['LuaChongxu'] = '冲虚',
    ['luachongxu'] = '冲虚',
    [':LuaChongxu'] = '出牌阶段限一次，你可以进行一次“飞升”，然后你可以将“飞升”的分数分配给来升级“妙剑”、升级“莲华”或摸牌',
    ['LuaMiaojianLevelUp'] = '升级“妙剑”',
    ['LuaLianhuaLevelUp'] = '升级“莲华”',
    ['LuaChongxuDraw'] = '摸一张牌',
    ['LuaMiaojian'] = '妙剑',
    ['luamiaojian'] = '妙剑',
    [':LuaMiaojian'] = '出牌阶段限一次，你可以将一张【杀】当【杀】或将一张锦囊牌当【无中生有】使用，你以此法使用的【杀】在被【闪】响应后，该角色若有手牌则需弃置一张手牌，否则此【杀】依然生效',
    [':LuaMiaojian2'] = '出牌阶段限一次，你可以将一张基本牌当【杀】或将一张非基本牌当【无中生有】使用，你以此法使用的【杀】在被【闪】响应后，该角色若有手牌则需弃置一张手牌，否则此【杀】依然生效',
    [':LuaMiaojian3'] = '出牌阶段限一次，你可以视为使用一张【杀】或【无中生有】，你以此法使用的【杀】在被【闪】响应后，该角色若有手牌则需弃置一张手牌，否则此【杀】依然生效',
    ['LuaLianhua'] = '莲华',
    [':LuaLianhua'] = '当你成为其他角色使用【杀】的目标时，你摸一张牌',
    [':LuaLianhua2'] = '当你成为其他角色使用【杀】的目标时，你摸一张牌，然后你进行一次判定，若为黑桃，取消之',
    [':LuaLianhua3'] = '当你成为其他角色使用【杀】的目标时，你摸一张牌，然后除非使用者弃置一张牌，否则取消之',
    ['ExMaojie'] = '毛玠',
    ['&ExMaojie'] = '毛玠',
    ['#ExMaojie'] = '清公素履',
    ['LuaBingqing'] = '秉清',
    [':LuaBingqing'] = '当你于出牌阶段内使用与你本阶段使用过且结算结束的牌花色均不相同牌结算结束后，若你本阶段使用过且结算结束的牌的花色数为：两种，你可以令一名角色摸两张牌；三种，你可以弃置一名角色区域内的一张牌；四种，你可以对一名其他角色造成1点伤害',
    ['LuaBingqing-invoke2'] = '你可以发动“秉清”令一名角色摸两张牌',
    ['LuaBingqing-invoke3'] = '你可以发动“秉清”弃置一名角色区域内的一张牌',
    ['LuaBingqing-invoke4'] = '你可以发动“秉清”对一名其他角色造成一点伤害',
    ['ExPeixiu'] = '裴秀',
    ['&ExPeixiu'] = '裴秀',
    ['#ExPeixiu'] = '晋国开秘',
    ['LuaXingtu'] = '行图',
    [':LuaXingtu'] = '锁定技，你使用牌结算结束后记录此牌点数。你使用牌时，若此牌点数为记录点数的约数，你摸一张牌。你使用点数为记录点数的倍数的牌无次数限制',
    ['LuaJuezhi'] = '爵制',
    [':LuaJuezhi'] = '出牌阶段，你可以弃置至少两张牌，然后随机获得牌堆中一张点数为X的牌（X为你弃置的牌的点数之和除以13的余数，若余数为0，则X为13）',
    ['luajuezhi'] = '爵制',
    ['JieGongsunzan'] = '界公孙瓒',
    ['&JieGongsunzan'] = '界公孙瓒',
    ['#JieGongsunzan'] = '白马将军',
    ['JieYicong'] = '义从',
    [':JieYicong'] = '锁定技，你计算与其他角色的距离-X（X为你的体力值-1）；其他角色计算与你的距离+Y（Y为你已损失的体力值-1）',
    ['ExCaosong'] = '曹嵩',
    ['&ExCaosong'] = '曹嵩',
    ['#ExCaosong'] = '舆金贾权',
    ['LuaYijin'] = '亿金',
    [':LuaYijin'] = '锁定技，①游戏开始时，你获得6个不同的“金”（回合开始时，若你没有“金”，你死亡）；\
    ②出牌阶段开始时，你交给一名没有“金”的其他角色1个“金”并令其获得对应效果，然后其下个回合结束后移去此“金”',
    ['LuaYijin-invoke'] = '你须选择一名其他角色，令其获得你选择的“金”：“%src”',
    ['#LuaYijinTransfer'] = '%from 将“%arg”交给了 %to',
    ['@LuaYijin1'] = '膴仕',
    [':@LuaYijin1'] = '摸牌阶段多摸四张牌、出牌阶段使用【杀】的次数上限+1',
    ['#LuaYijin1'] = '%from 的“%arg”效果被触发，额外摸了 %arg2 张牌',
    ['@LuaYijin2'] = '厚任',
    [':@LuaYijin2'] = '回合结束时，回复3点体力',
    ['#LuaYijin2'] = '%from 的“%arg”效果被触发，回复了 %arg2 点体力',
    ['@LuaYijin3'] = '通神',
    [':@LuaYijin3'] = '受到非雷电伤害时，防止之',
    ['#LuaYijin3'] = '%from 的“%arg”效果被触发，防止了即将受到的伤害',
    ['@LuaYijin4'] = '金迷',
    [':@LuaYijin4'] = '跳过下一个出牌阶段和弃牌阶段',
    ['#LuaYijin4'] = '%from 的“%arg”效果被触发，跳过了 %arg2 阶段',
    ['@LuaYijin5'] = '贾凶',
    [':@LuaYijin5'] = '出牌阶段开始时失去1点体力，本回合手牌上限-3',
    ['#LuaYijin5'] = '%from 的“%arg”效果被触发，失去了 %arg2 点体力',
    ['@LuaYijin6'] = '拥蔽',
    [':@LuaYijin6'] = '准备阶段，跳过下一个摸牌阶段',
    ['#LuaYijin6'] = '%from 的“%arg”效果被触发，跳过了 %arg2 阶段',
    ['LuaGuanzong'] = '惯纵',
    [':LuaGuanzong'] = '出牌阶段限一次，你可以令一名其他角色视为对另一名你选择的其他角色造成过1点伤害',
    ['#LuaGuanzong'] = '%from 执行“%arg”的效果，视为对 %to 造成了 %arg2 点伤害',
    ['ExTongquJiakui'] = '贾逵重制',
    ['&ExTongquJiakui'] = '贾逵',
    ['#ExTongquJiakui'] = '肃齐万里',
    ['LuaTongqu'] = '通渠',
    [':LuaTongqu'] = '①游戏开始时，你获得1个“渠”标记（有“渠”的角色：进入濒死状态时移去“渠”标记；摸牌阶段多摸一张牌并将一张牌交给另一名有“渠”的角色或弃置之，若以此法给出的牌为装备牌，获得牌的角色使用之）；\
    ②准备阶段，你可以失去1点体力，令一名没有“渠”标记的角色获得1个“渠”标记',
    ['luatongqu'] = '通渠',
    ['#LuaTongqu'] = '%from 的“%arg”效果被触发，额外摸了 %arg2 张牌',
    ['LuaTongqu-Give'] = '你可以失去一点体力，选择一名没有“渠”标记的角色令其获得一个“渠”标记',
    ['LuaTongqu-Invoke'] = '“通渠”被触发，你须弃置或交给一名其他有“渠”标记的角色一张牌',
    ['~LuaTongqu'] = '选择一张牌→选择一名其他角色（可选）→点击“确定”',
    ['@LuaTongqu'] = '渠',
    ['LuaWanlanTongqu'] = '挽澜',
    [':LuaWanlanTongqu'] = '当一名角色受到会令其进入濒死状态的伤害时，你可以弃置装备区里的所有牌（至少一张），防止此伤害',
    ['#LuaWanlanTongqu'] = '%from 发动了“%arg”，防止了 %to 即将受到的 %arg2 点伤害',
    ['JieWolong'] = '界卧龙诸葛',
    ['&JieWolong'] = '界诸葛亮',
    ['#JieWolong'] = '卧龙',
    ['LuaBazhen'] = '八阵',
    [':LuaBazhen'] = '锁定技，若你的装备区里没有防具牌，视为你装备着【八卦阵】；当你的八卦阵判定失败时，你摸一张牌',
    ['LuaHuoji'] = '火计',
    [':LuaHuoji'] = '出牌阶段，你可以将一张红色牌当【火攻】使用；\
    当你使用【火攻】时，你令目标角色改为随机展示一张手牌，然后你可以弃置一张与其展示牌颜色相同的手牌并对其造成1点火焰伤害；\
    当你因【火攻】需要弃置牌时，你可以观看牌堆顶的4张牌，选择其中一张与展示牌花色相同的牌代替【火攻】需要弃置的牌，然后将剩余的牌放回牌堆顶',
    ['@LuaHuoji-Discard'] = '%src 展示的牌的颜色为 %arg，请弃置一张与其颜色相同的手牌',
    ['LuaKanpo'] = '看破',
    [':LuaKanpo'] = '你可以将一张黑色牌当【无懈可击】使用；你使用的【无懈可击】不能被响应',
    ['LuaCangzhuo'] = '藏拙',
    [':LuaCangzhuo'] = '锁定技，若你本回合未使用过锦囊牌，你的锦囊牌不计入手牌上限',
    ['JieZhurong'] = '界祝融',
    ['&JieZhurong'] = '界祝融',
    ['#JieZhurong'] = '野性的女王',
    ['illustrator:JieZhurong'] = 'alien',
    ['LuaJuxiang'] = '巨象',
    [':LuaJuxiang'] = '锁定技，【南蛮入侵】对你无效；当其他角色使用的【南蛮入侵】结算结束后置入弃牌堆时，你获得之',
    ['LuaLieren'] = '烈刃',
    [':LuaLieren'] = '当你使用【杀】指定一名角色为目标后，你可以与其拼点，若你：赢，你获得该角色的一张牌；没赢，你与其交换双方拼点的牌',
}
