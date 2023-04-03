-- translation for LayingPlansCouragePackage

return {
    ['LayingPlansCouragePackage'] = '始计篇-勇包',
    ['ExSunyi'] = '孙翊',
    ['&ExSunyi'] = '孙翊',
    ['#ExSunyi'] = '骁悍激躁',
    ['LuaZaoli'] = '躁厉',
    [':LuaZaoli'] = '锁定技，①你于出牌阶段内只能使用或打出本回合进入你手牌区的牌；\
    ②当你使用或打出手牌时，若你的“厉”标记数小于4，你获得1个“厉”标记；\
    ③回合开始时，若你有“厉”标记，你移去所有“厉”标记并弃置任意张牌（若有牌则至少弃置一张牌），然后你摸X张牌（X为你移去的“厉”标记数与弃置牌数之和）。若你移去的“厉”标记数大于2，你失去1点体力',
    ['@LuaZaoli'] = '厉',
    ['LuaZaoli-discard'] = '你须弃置至少一张牌',
    ['ExZongyu'] = '宗预',
    ['&ExZongyu'] = '宗预',
    ['#ExZongyu'] = '御严无惧',
    ['LuaZhibian'] = '直辩',
    [':LuaZhibian'] = '准备阶段，你可以与一名角色拼点，若你：赢，你可以选择一项：\
    1.将其场上的一张牌移至你的对应区域；\
    2.回复1点体力；\
    背水：跳过你的下个摸牌阶段；\
    没赢，你失去1点体力',
    ['@LuaZhibian'] = '你可以发动“直辩”选择一名角色进行拼点',
    ['LuaZhibianChoice1'] = '将其场上的一张牌移至你的对应区域',
    ['LuaZhibianChoice2'] = '回复1点体力',
    ['LuaYuyan'] = '御严',
    [':LuaYuyan'] = '锁定技，当你成为体力值大于你的角色使用非转化、非虚拟【杀】的目标时，其选择一项：1.交给你一张点数大于此【杀】的牌；2.取消之',
    ['@Yuyan-give'] = '%src 的“御严”被触发，请交给其一张点数大于 %arg 的手牌，否则【杀】将取消其作为目标',
    ['LastStand'] = '背水',
    ['ExWenyang'] = '文鸯',
    ['&ExWenyang'] = '文鸯',
    ['#ExWenyang'] = '独骑破军',
    ['LuaQuedi'] = '却敌',
    ['luaquedi'] = '却敌',
    [':LuaQuedi'] = '<font color="green"><b>每回合限一次</b></font>，当你使用【杀】或【决斗】指定唯一目标后，你可以选择一项：\
    1.弃置一张基本牌，然后此【杀】或【决斗】伤害+1；\
    2.获得其一张手牌；\
    背水：你减1点体力上限',
    ['LuaQuedi_ask'] = '你可以发动“却敌”',
    ['~LuaQuedi'] = '选择一名其他角色→选择一张基本牌→点击“确定”',
    ['LuaChuifeng'] = '椎锋',
    ['luachuifeng'] = '椎锋',
    [':LuaChuifeng'] = '<font color="#547998"><b>魏势力技</b></font>，<font color="green"><b>出牌阶段限两次</b></font>，你可以失去一点体力，视为使用一张【决斗】。\
    当你受到此【决斗】的伤害时，你防止此伤害，然后此技能于此阶段内失效',
    ['#LuaChuifeng'] = '%from 的“%arg”被触发，防止了 %card 带来的伤害',
    ['LuaChongjian'] = '冲坚',
    ['luachongjian'] = '冲坚',
    [':LuaChongjian'] = '<font color="#4DB873"><b>吴势力技</b></font>，你可以将一张装备牌当【酒】或无距离限制且无视目标防具的【杀】使用。\
    当你以此法使用【杀】对一名角色造成伤害后，你获得其装备区里的X张牌（X为伤害值）',
    ["@LuaChongjian"] = "请选择 %src 的目标",
    ['~LuaChongjian'] = '选择若干其他角色→点击“确定”',
    ['LuaChoujue'] = '仇决',
    [':LuaChoujue'] = '锁定技，当一名角色死亡后，若杀死其的角色为你，你加1点体力上限，摸两张牌，然后“却敌”于此回合内的发动次数上限+1',
    ['LuaWenyangKingdomChoose'] = '文鸯选择势力',
    ['ExGaolan'] = '高览',
    ['&ExGaolan'] = '高览',
    ['#ExGaolan'] = '绝击坚营',
    ['LuaJungong'] = '峻攻',
    [':LuaJungong'] = '出牌阶段，你可以弃置X张牌或失去X点体力，视为使用一张无距离与次数限制且不计入使用次数的【杀】（X为你本阶段此前发动过此技能的次数+1），然后当此【杀】造成伤害后，本回合此技能失效',
    ['luajungong'] = '峻攻',
    ['LuaDengli'] = '等力',
    [':LuaDengli'] = '当你使用【杀】指定一名角色为目标时，或当你成为其他角色使用【杀】的目标时，若你与其体力值相等，你可以摸一张牌',
}
