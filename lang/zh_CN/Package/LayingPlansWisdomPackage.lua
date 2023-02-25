-- translation for LayingPlansWisdomPackage

return {
    ['LayingPlansWisdomPackage'] = '始计篇-信包',
    ['ExZhouchu'] = '周处',
    ['&ExZhouchu'] = '周处',
    ['#ExZhouchu'] = '英情天逸',
    ['LuaXianghai'] = '乡害',
    [':LuaXianghai'] = '锁定技，场上所有其他角色的手牌上限-1，你手牌区所有装备牌均视为【酒】',
    ['LuaChuhai'] = '除害',
    ['luachuhai'] = '除害',
    [':LuaChuhai'] = '<font color="purple"><b>使命技</b></font>，出牌阶段限一次，你可以摸一张牌，并与一名角色拼点且你的拼点牌点数+X（X为4减去你装备区的装备数），\
    若你赢：1.你观看其手牌，然后从牌堆或弃牌堆中获得其手牌中拥有的牌类型各一张；\
    2.当你本阶段对该角色造成伤害后，你将牌堆或弃牌堆中的一张你未装备类别的装备牌置入你的装备区\
    成功：当一张装备牌进入你的装备区后，若你的装备区里的牌数不小于3，你将体力值回复至体力上限，然后获得技能“彰名”，失去技能“乡害”\
    失败：当你于“除害”拼点中拼点结果不大于6且没赢，使命失败',
    ['#LuaChuhaiSuccess'] = '%from 的装备数达到了 %arg，“%arg2”<font color="green"><b>成功</b></font>',
    ['#LuaChuhaiFailure'] = '%from 的拼点数为 %arg 且拼点失败，“%arg2”<font color="red"><b>失败</b></font>',
    ['#LuaChuhaiPindian'] = '%from 的“%arg”被触发，拼点数增加 %arg2',
    ['LuaZhangming'] = '彰名',
    [':LuaZhangming'] = '锁定技，①你使用的梅花牌不能被响应；\
    ②每回合限一次，你对其他角色造成伤害后，其随机弃置一张手牌，然后你从牌堆或弃牌堆中获得每种类别的牌各一张（不包含其弃置的牌的类别；你以此法获得的牌不计入你本回合的手牌上限）',
    ['ExShenTaishici'] = '神太史慈',
    ['&ExShenTaishici'] = '神太史慈',
    ['#ExShenTaishici'] = '义信天武',
    ['LuaDulie'] = '笃烈',
    [':LuaDulie'] = '锁定技，当你成为体力值大于你的其他角色使用【杀】的目标时，你进行一次判定，若结果为红桃，取消之',
    ['LuaPowei'] = '破围',
    ['luapowei'] = '破围',
    ['@LuaPowei'] = '围',
    [':LuaPowei'] = '<font color="purple"><b>使命技</b></font>，①游戏开始时，所有其他角色获得“围”标记；\
    ②回合结束时，所有其他角色的“围”标记移动给除你以外的下家角色；\
    ③当有“围”标记的角色受到伤害后，移去其的“围”标记；\
    ④有“围”标记的角色的回合开始时，你可以选择一项：1.弃置一张手牌，对其造成1点伤害；2.若其体力值不大于你，获得其一张手牌。选择完成后，本回合你视为在其攻击范围内。\
    成功：回合开始时，若没有角色拥有“围”标记，你获得技能“神著”；\
    失败：当你进入濒死状态时，你将体力值回复至1点，移去所有的“围”标记，然后弃置你装备区里的所有牌',
    ['#LuaPoweiSuccess'] = '场上角色均已没有“围”标记，%from“%arg”<font color="green"><b>成功</b></font>',
    ['#LuaPoweiFailure'] = '%from 在条件达成前进入濒死状态，“%arg”<font color="red"><b>失败</b></font>',
    ['LuaPowei_ask'] = '你可以发动“破围”',
    ['~LuaPoweiHelper'] = '选择一张手牌或者选择当前回合角色→点击“确定”',
    ['LuaShenzhu'] = '神著',
    [':LuaShenzhu'] = '锁定技，当你使用非转化且非虚拟的【杀】结算结束后，你选择一项：1.摸一张牌，然后若此时是你的出牌阶段，你本阶段使用【杀】的次数上限+1；2.摸三张牌，然后你本回合不能再使用【杀】',
    ['LuaShenzhu1'] = '摸一张牌，若在出牌阶段则本回合内使用【杀】次数+1',
    ['LuaShenzhu2'] = '摸三张牌，然后本回合内不能再使用【杀】',
    ['ExShenSunce'] = '神孙策',
    ['&ExShenSunce'] = '神孙策',
    ['#ExShenSunce'] = '踞江鬼雄',
    ['LuaYingba'] = '英霸',
    [':LuaYingba'] = '出牌阶段限一次，你可以令一名体力上限大于1的其他角色减1点体力上限并获得“平定”标记，然后你减1点体力上限。你对拥有“平定”标记的角色使用牌无距离限制',
    ['luayingba'] = '英霸',
    ['@LuaPingding'] = '平定',
    ['LuaFuhai'] = '覆海',
    [':LuaFuhai'] = '锁定技，拥有“平定”标记的角色不能响应你对其使用的牌。当你使用牌指定有“平定”标记的角色为目标时，若本回合你以此法获得的牌数小于2，你摸一张牌。当拥有“平定”标记的角色死亡时，你加X点体力上限并摸X张牌（X为其拥有的“平定”标记数）',
    ['LuaPinghe'] = '冯河',
    ['luapinghe'] = '冯河',
    [':LuaPinghe'] = '锁定技，你的手牌上限为你已损失的体力值。当你受到其他角色造成的伤害时，若你有手牌且体力上限大于1，你防止此伤害，然后你减1点体力上限并将一张手牌交给一名其他角色，然后若你拥有“英霸”，你令伤害来源获得1个“平定”标记',
    ['LuaPingheGive'] = '“冯河”被触发，你须交给其他角色一张手牌',
    ['~LuaPinghe'] = '选择一张手牌→选择一名其他角色→点击“确定”',
    ['ExYanghu'] = '羊祜',
    ['&ExYanghu'] = '羊祜',
    ['#ExYanghu'] = '鹤德璋声',
    ['LuaMingfa'] = '明伐',
    [':LuaMingfa'] = '①结束阶段，你可以展示一张牌，你的下个回合的首个出牌阶段开始时，若你未失去此牌（不包括使用装备而失去），你可以用此牌与一名其他角色进行拼点，\
    若你：赢，你获得其一张牌，并随机获得牌堆中一张点数为X的牌（X为你拼点的牌的点数-1）；没赢，本回合你不能对其他角色使用牌\
    ②当你拼点的牌亮出后，你令此牌的点数+2',
    ['LuaMingfa-choose'] = '你可以选择一名其他角色，用 %src[%arg%arg2] 与其拼点',
    ['@LuaMingfa-show'] = '你可以展示一张牌，下个出牌阶段你可以用其拼点',
    ['#LuaMingfaPindian'] = '%from 的“%arg”被触发，拼点数增加 %arg2',
    ['LuaRongbei'] = '戎备',
    [':LuaRongbei'] = '限定技，出牌阶段，你可以选择一名装备区里有空置装备栏的角色，令其每个空置的装备栏随机获得并使用一张装备牌',
    ['@LuaRongbei'] = '戎备',
    ['luarongbei'] = '戎备',
}