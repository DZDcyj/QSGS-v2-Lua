-- this script to store the basic configuration for game program itself
-- and it is a little different from config.ini

config = {
	big_font = 56,
	small_font = 27,
	tiny_font = 18,
	kingdoms = { "wei", "shu", "wu", "qun", "god" },
	kingdom_colors = {
		wei = "#547998",
		shu = "#D0796C",
		wu = "#4DB873",
		qun = "#8A807A",
		god = "#96943D",
	},

	skill_type_colors = {
		compulsoryskill = "#0000FF",--真蓝色
		limitedskill = "#FF0000",--真红色
		wakeskill = "#800080",--骗紫色
		lordskill = "#FFA500",--大神色
		oppphskill = "#008000",--一次色
		changeskill = "#FFC0CB",--粉红色
	},

	package_names = {
		"StandardCard",
		"StandardExCard",
		"Maneuvering",
		"LimitationBroken",
		"SPCard",
		"Nostalgia",
		"New3v3Card",
		"New3v3_2013Card",
		"New1v1Card",
		"YitianCard",
	  	"Joy",
		"Disaster",
		"JoyEquip",
		"Godlailailai",

		"Standard",
		"Wind",
		"Fire",
		"Thicket",
		"Mountain",
		"God",
		"YJCM",
		"YJCM2012",
		"YJCM2013",
		"YJCM2014",
		"YJCM2015",
		"Assassins",
		"Special3v3",
		"Special3v3Ext",
		"Special1v1",
		"Special1v1Ext",
		"SP",
		"OL",
		"TaiwanSP",
		"TaiwanYJCM" ,
		"Miscellaneous",
		"BGM",
		"BGMDIY",
		"Ling",
		"Hegemony",
		"HFormation",
		"HMomentum",
		"HegemonySP",
		"JSP",
		"NostalStandard",
		"NostalWind",
		"NostalYJCM",
		"NostalYJCM2012",
		"NostalYJCM2013",
		"JianGeDefense",
		"BossMode",
		"Yitian",
		"Wisdom",
		"Test",
		"Dong"
	},

	hidden_ai_generals = {
		"bf_lingtong",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
		"huanghao",
	},

	hulao_generals = {
		"package:nostal_standard",
		"package:wind",
		"package:nostal_wind",
		"zhenji", "zhugeliang", "sunquan", "sunshangxiang",
		"-zhangjiao", "-zhoutai", "-caoren", "-yuji",
		"-nos_yuji"
	},

	xmode_generals = {
		"package:nostal_standard",
		"package:wind",
		"package:fire",
		"package:nostal_wind",
		"zhenji", "zhugeliang", "sunquan", "sunshangxiang",
		"-nos_huatuo",
		"-zhangjiao", "-zhoutai", "-caoren", "-yuji",
		"-nos_zhangjiao", "-nos_yuji"
	},

	easy_text = {
		"太慢了，做两个俯卧撑吧！",
		"快点吧，我等的花儿都谢了！",
		"高，实在是高！",
		"好手段，可真不一般啊！",
		"哦，太菜了。水平有待提高。",
		"你会不会玩啊？！",
		"嘿，一般人，我不使这招。",
		"呵，好牌就是这么打地！",
		"杀！神挡杀神！佛挡杀佛！",
		"你也忒坏了吧？！"
	},

	roles_ban = {
	},

	kof_ban = {
		"sunquan",
	},

	bossmode_ban = {
		"caopi",
		"manchong",
		"xusheng",
		"yuji",
		"caiwenji",
		"zuoci",
		"lusu",
		"bgm_diaochan",
		"shenguanyu",
		"nos_yuji",
		"nos_zhuran"
	},

	basara_ban = {
		"dongzhuo",
		"zuoci",
		"shenzhugeliang",
		"shenlvbu",
		"bgm_lvmeng",
		"zhanggongqi"
	},

	god_ban = {
		"shenguanyu",
		"shencaocao",
		"shenlvmeng",
		"shenzhugeliang",
		"shenzhouyu",
		"shenzhaoyun",
		"shensimayi",
		"shenlvbu",
		"kanze",
		"bgm_diaochan",
		"caiwenji",
		"wangyun",
		"zuoci",
		"yuji",
		"daqiao",
		"nos_daoqiao",
		"xuhuang",
		"ol_xuhuang",
		"ol_jiaxu",
		"jsp_guanyu",
		"sp_guanyu",
		"lingju",
		"st_yuanshu",
		"buzhi",
		"mayunlu",
		"ol_mayunlu",
		"huanghao",
		"chengyu",
		"guohuanghou",
		"zhangrang",
		"diaochan",
		"nos_diaochan",
		"xiaoqiao",
		"ol_xiaoqiao",
		"erqiao",
		"fazheng",
		"manchong",
		"hanhaoshihuan",
	},

	hegemony_ban = {
		"shenguanyu", "shenlvmeng", "shenzhouyu", "shenzhugeliang", "shencaocao", "shenlvbu", "shencaocao", "shensimayi", "tw_xiahouba",
		--[[--界限突破+标准
		"caocao+xiahoudun", "nos_caocao+xiahoudun",
		"guojia+dengai",
		"nos_huanggai+zhoutai",
		"zhenji+nos_wangyi", "zhenji+caoang",
		"sunshangxiang+liuzan",
		"luxun+guyong",
		"nos_luxun+guyong",
		"heg_luxun+buzhi",
		--神话再临
		"ol_weiyan+jsp_sunshangxiang",
		"wolong+zhangsong",
		"yanliangwenchou+miheng",
		"dengai+caoang",
		--一将成名
		"chengong+jushou",
		"liubiao+kongrong", "ol_liubiao+kongrong",
		"guyong+buzhi",
		"liaohua+jiangwanfeiyi",
		"guansuo+jiangwanfeiyi",
		"nos_zhuran+ol_xusheng",
		"jushou+heg_yuji",
		"guotupangji+liuxie",
		"liuchen+maliang",
		--SP
		"liuxie+kongrong",]]--
	},

	pairs_ban = {
		"zuoci", "xiahoushi", "zhaoxiang", "nos_zhangchunhua", "nos_fuhuanghou", "liuzan",
		--界限突破+标准
		"xiahoudun+jiangwanfeiyi",
		"guojia+wolong", "nos_guojia+wolong", "xizhicai+wolong",
		"zhenji+nos_huangyueying", "zhenji+sunshangxiang", "zhenji+nos_zhangjiao", "zhenji+zhangjiao", "zhenji+ol_zhangjiao", "zhenji+nos_wangyi", "zhenji+liuxie", "zhenji+caoang",
		"lidian+yuanshao", "ol_lidian+yuanshao", 
		"zhangfei+nos_huanggai", "nos_zhangfei+nos_huanggai", "zhangfei+fuwan", "nos_zhangfei+fuwan", "zhangfei+jsp_machao", "nos_zhangfei+jsp_machao",
		"xiahouba+nos_huanggai", "xiahouba+jsp_machao", "xiahouba+fuwan",
		"huangyueying+nos_huanggai", "huangyueying+sunshangxiang", "huangyueying+yanliangwenchou",
		"nos_huangyueying+nos_huanggai", "nos_huangyueying+sunshangxiang",
		"zhangsong+nos_huanggai", "zhangsong+sunshangxiang", "zhangsong+sp_sunshangxiang", "zhangsong+jsp_sunshangxiang",
		"sunquan+kongrong",
		"lvmeng+liubiao", "lvmeng+ol_liubiao", "lvmeng+jiangwanfeiyi",
		"nos_lvmeng+liubiao", "nos_lvmeng+ol_liubiao", "nos_lvmeng+jiangwanfeiyi",
		"bgm_lvmeng+liubiao", "bgm_lvmeng+ol_liubiao", "bgm_lvmeng+jiangwanfeiyi",
		"huanggai+dongzhuo", "huanggai+wangyi", "huanggai+jushou", "huanggai+shenzhouyu", "huanggai+ol_weiyan",
		"nos_huanggai+st_huaxiong", "nos_huanggai+shenzhouyu", "nos_huanggai+ol_weiyan", "nos_huanggai+weiyan", "nos_huanggai+zhoutai", "nos_huanggai+dongzhuo", "nos_huanggai+yuanshao", "nos_huanggai+yanliangwenchou", "nos_huanggai+guanxingzhangbao", "nos_huanggai+nos_guanxingzhangbao", "nos_huanggai+huaxiong", "nos_huanggai+xiahouba", "nos_huanggai+wutugu", "nos_huanggai+zhuling", "nos_huanggai+jushou",
		"luxun+guyong",
		"nos_luxun+guyong", 
		"heg_luxun+buzhi", "heg_luxun+kongrong",
		"huatuo+guojia", "huatuo+nos_guojia", "huatuo+xizhicai", "huatuo+xunyu", "huatuo+chengyu", "huatuo+manchong", "huatuo+caopi", "huatuo+nos_caocao", "huatuo+caocao", "huatuo+nos_caochong", "huatuo+caochong", "huatuo+caorui", "huatuo+ol_caorui", "huatuo+jiangwanfeiyi", "huatuo+ol_jiangwanfeiyi",
		"nos_huatuo+guojia", "nos_huatuo+nos_guojia", "nos_huatuo+xizhicai", "nos_huatuo+xunyu", "nos_huatuo+chengyu", "nos_huatuo+manchong", "nos_huatuo+caopi", "nos_huatuo+nos_caocao", "nos_huatuo+caocao", "nos_huatuo+nos_caochong", "nos_huatuo+caochong", "nos_huatuo+caorui", "nos_huatuo+ol_caorui", "nos_huatuo+jiangwanfeiyi", "nos_huatuo+ol_jiangwanfeiyi",
		--神话再临
		"shencaocao+caozhi", "shencaocao+yanliangwenchou", "shencaocao+wolong", "shencaocao+tw_zumao", "shencaocao+tw_caoang",
		"shenlvbu+nos_liru", "shenlvbu+huanggai", "shenlvbu+yuanshao",
		"huangzhong+xusheng", "ol_huangzhong+xusheng", "ol_huangzhong+ol_machao", "ol_huangzhong+tadun",
		"ol_weiyan+jsp_sunshangxiang",
		"xiaoqiao+zhangchunhua", "ol_xiaoqiao+zhangchunhua",
		"zhangjiao+dengai", "nos_zhangjiao+dengai", "ol_zhangjiao+dengai",
		"wolong+zhangsong",
		"zhanghe+yuanshu", "zhanghe+liubiao", "zhanghe+ol_liubiao",
		"dengai+zhugejin", "dengai+caoang",
		--一将成名
		"xushu+yujin",
		"chengong+jushou",
		"zhangchunhua+guyong", "zhangchunhua+liuchen", "zhangchunhua+erqiao", "zhangchunhua+heg_luxun", "zhangchunhua+zhugeke", "zhangchunhua+sunhao",
		"liaohua+guotupangji", "liaohua+jiangwanfeiyi", "liaohua+kanze", "liaohua+miheng", "liaohua+lusu", "liaohua+huanggai",
		"guansuo+guotupangji", "guansuo+jiangwanfeiyi", "guansuo+kanze", "guansuo+miheng", "guansuo+lusu", "guansuo+huanggai",
		"liubiao+kongrong", "ol_liubiao+kongrong", "ol_liubiao+diy_wangyuanji",
		"guyong+buzhi", "guyong+kongrong",
		"nos_zhuran+hetaihou", "nos_zhuran+ol_xusheng",
		"jushou+tw_zumao", "jushou+tw_caoang", "jushou+heg_yuji",
		"guotupangji+liuxie", "guotupangji+diy_wangyuanji",
		"quancong+diy_wangyuanji",
		"liuchen+maliang", "liuchen+luxun", "liuchen+nos_luxun", "liuchen+zhangchunhua",
		--SP
		"liuxie+kongrong",
		--OL
		"wanglang+jianyong", "wutugu+xushi", "wutugu+sunru",
	},

	couple_lord = "caocao",
	couple_couples = {
		"caopi|caozhi+zhenji",
		"simayi|shensimayi+zhangchunhua",
		"diy_simazhao+diy_wangyuanji",
		"liubei|bgm_liubei+ganfuren|mifuren|sp_sunshangxiang|jsp_sunshangxiang",
		"liushan+xingcai",
		"zhangfei|bgm_zhangfei+xiahoushi|xiahoujuan",
		"zhugeliang|wolong|shenzhugeliang+huangyueying",
		"menghuo+zhurong",
		"zhouyu|shenzhouyu+xiaoqiao",
		"lvbu|shenlvbu+diaochan|bgm_diaochan",
		"sunjian+wuguotai",
		"sunce|heg_sunce+daqiao|bgm_daqiao",
		"sunquan+bulianshi",
		"liuxie|diy_liuxie|as_liuxie+fuhuanghou|as_fuhuanghou",
		"luxun|heg_luxun+sunru",
		"liubiao+caifuren",
	},

	convert_pairs = {
		"caiwenji->sp_caiwenji",
		"caopi->heg_caopi",
		"sp_dingfeng->dingfeng",
		"fazheng->ol_fazheng",
		"guanxingzhangbao->ol_guanxingzhangbao",
		"sp_hetaihou->hetaihou",
		"jiaxu->sp_jiaxu",
		"liubei->tw_liubei",
		"madai->heg_madai",
		"nos_caocao->tw_caocao",
		"nos_daqiao->wz_nos_daqiao|tw_daqiao",
		"nos_diaochan->sp_diaochan|heg_diaochan|tw_diaochan",
		"nos_ganning->tw_ganning",
		"nos_guanyu->tw_guanyu",
		"nos_guojia->tw_guojia",
		"nos_huanggai->tw_huanggai",
		"nos_huangyueying->heg_huangyueying|tw_huangyueying",
		"nos_luxun->tw_luxun",
		"nos_lvbu->heg_lvbu|tw_lvbu",
		"nos_lvmeng->tw_lvmeng",
		"nos_machao->sp_machao|tw_machao",
		"nos_simayi->tw_simayi|pr_nos_simayi",
		"nos_xiahoudun->tw_xiahoudun",
		"nos_xuchu->tw_xuchu",
		"nos_zhangfei->tw_zhangfei",
		"nos_zhangliao->tw_zhangliao",
		"nos_zhaoyun->tw_zhaoyun",
		"nos_zhouyu->heg_zhouyu|sp_heg_zhouyu|tw_zhouyu",
		"sp_panfeng->panfeng",
		"pangde->sp_pangde",
		"shencaocao->pr_shencaocao",
		"shenlvbu->sp_shenlvbu",
		"sunquan->tw_sunquan",
		"sunshangxiang->sp_sunshangxiang|tw_sunshangxiang",
		"xiaoqiao->wz_xiaoqiao|heg_xiaoqiao|sp_heg_xiaoqiao|tw_xiaoqiao",
		"xushu->ol_xushu",
		"yuanshu->tw_yuanshu",
		"sp_yuejin->yuejin",
		"zhenji->sp_zhenji|heg_zhenji|tw_zhenji",
		"zhugeke->diy_zhugeke",
		"zhugeliang->heg_zhugeliang|tw_zhugeliang",
		"zhugejin->sp_zhugejin" ,
		"sp_ganfuren->ganfuren"
	},

	removed_hidden_generals = {
	},

	extra_hidden_generals = {
	},

	removed_default_lords = {
	},

	extra_default_lords = {
	},

	bossmode_default_boss = {
		"boss_chi+boss_mei+boss_wang+boss_liang",
		"boss_niutou+boss_mamian",
		"boss_heiwuchang+boss_baiwuchang",
		"boss_luocha+boss_yecha"
	},

	bossmode_endless_skills = {
		"bossguimei", "bossdidong", "nosenyuan", "bossshanbeng+bossbeiming+huilei+bossmingbao",
		"bossluolei", "bossguihuo", "bossbaolian", "mengjin", "bossmanjia+bazhen",
		"bossxiaoshou", "bossguiji", "fankui", "bosslianyu", "nosjuece",
		"bosstaiping+shenwei", "bosssuoming", "bossxixing", "bossqiangzheng",
		"bosszuijiu", "bossmodao", "bossqushou", "yizhong", "kuanggu",
		"bossmojian", "bossdanshu", "shenji", "wushuang", "wansha"
	},

	bossmode_exp_skills = {
		"mashu:15",
		"tannang:25",
		"yicong:25",
		"feiying:30",
		"yingyang:30",
		"zhenwei:40",
		"nosqicai:40",
		"nosyingzi:40",
		"zongshi:40",
		"qicai:45",
		"wangzun:45",
		"yingzi:50",
		"kongcheng:50",
		"nosqianxun:50",
		"weimu:50",
		"jie:50",
		"huoshou:50",
		"hongyuan:55",
		"dangxian:55",
		"xinzhan:55",
		"juxiang:55",
		"wushuang:60",
		"xunxun:60",
		"zishou:60",
		"jingce:60",
		"shengxi:60",
		"zhichi:60",
		"bazhen:60",
		"yizhong:65",
		"jieyuan:70",
		"mingshi:70",
		"tuxi:70",
		"guanxing:70",
		"juejing:75",
		"jiangchi:75",
		"bosszuijiu:80",
		"shelie:80",
		"gongxin:80",
		"fenyong:85",
		"kuanggu:85",
		"yongsi:90",
		"zhiheng:90",
	},

	jiange_defense_kingdoms = {
		loyalist = "shu",
		rebel = "wei",
	},

	jiange_defense_machine = {
		wei = "jg_machine_tuntianchiwen+jg_machine_shihuosuanni+jg_machine_fudibian+jg_machine_lieshiyazi",
		shu = "jg_machine_yunpingqinglong+jg_machine_jileibaihu+jg_machine_lingjiaxuanwu+jg_machine_chiyuzhuque",
	},

	jiange_defense_soul = {
		wei = "jg_soul_caozhen+jg_soul_simayi+jg_soul_xiahouyuan+jg_soul_zhanghe",
		shu = "jg_soul_liubei+jg_soul_zhugeliang+jg_soul_huangyueying+jg_soul_pangtong",
	}
}
