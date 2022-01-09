-- translation for ImpassePackage

return {
    ['ImpassePackage'] = '绝境之战包',
    ['LuaSilve'] = '思略',
    [':LuaSilve'] = '锁定技，摸牌阶段，你摸X张牌（X为你当前的体力值）',
    [':LuaSilveBaozou'] = '锁定技，你摸牌阶段放弃摸牌，改为依次从其他存活角色处获得一张牌',
    ['LuaKedi'] = '克敌',
    [':LuaKedi'] = '你受到伤害后可以摸X张牌（X为你当前体力值）',
    [':LuaKediBaozou'] = '你受到伤害后可以摸X张牌（X为场上存活的角色数）',
    ['LuaJishi'] = '济世',
    [':LuaJishi'] = '锁定技，回合开始阶段，若你的手牌不大于X，你可以从除你以外每名角色那获得一张手牌，若目标角色无手牌，则失去一点体力（X为你当前体力值）',
    [':LuaJishiBaozou'] = '锁定技，回合开始阶段，若你的手牌不大于X，你可以从除你以外每名角色那获得一张手牌，若目标角色无手牌，则失去两点体力（X为存活的角色数与你当前体力上限之和）；你的手牌上限为存活的角色数',
    ['LuaDaji'] = '大吉',
    [':LuaDaji'] = '锁定技，回合结束阶段，你摸X张牌（X为你的体力值），当你受到大于一的伤害时，伤害值减一',
    -- DZDcyj 按：这里不能用 -1 替代中文汉字，否则技能描述替换不能正常执行
    [':LuaDajiBaozou'] = '锁定技，回合结束阶段，你摸X张牌；当你受到大于一的伤害时，伤害值减一；你的回合外，若你已受伤，则你为锦囊牌的唯一目标时，该锦囊对你无效（X为存活角色数）',
    ['LuaGuzhan'] = '孤战',
    [':LuaGuzhan'] = '锁定技，当你没装备武器时使用【杀】无次数限制',
    ['LuaJizhan'] = '激战',
    [':LuaJizhan'] = '锁定技，出牌阶段，你每对其他角色造成一点伤害回复一点体力；当手牌小于存活的角色数时，你将手牌摸至存活的角色数',
    ['LuaDuduan'] = '独断',
    [':LuaDuduan'] = '锁定技，你不是延时类锦囊牌的合法目标',
    ['LuaBoss'] = '绝境',
    [':LuaBoss'] = '你是这局游戏的boss',
    ['@baozou'] = '暴走',
    ['LuaBaozou'] = '暴走',
    [':LuaBaozou'] = '锁定技，当你的的体力值不大于3时，你进入暴走状态，获得X枚暴走标记，X为当前存活的角色数。然后判定区内的牌全部进入弃牌堆，体力上限变为3，获得技能【孤战】【激战】和【独断】\
    当你于暴走状态使用牌指定目标后，在此牌结算完毕前，其他角色的防具失效\
    锁定技，进入暴走状态后，你于回合开始时失去一枚暴走标记',
    ['#LuaImpasseLordKill'] = '%from 杀死了 %to，摸 %arg 张牌',
    ['#LuaImpasseRebelKill'] = '%from 杀死了 %to，需弃置所有手牌',
    ['#LuaImpasseLordLoseMaxHp'] = '%from 杀死了 %to，失去了 %arg 点体力上限',
    ['#LuaImpasseLordLoseMark'] = '%from 的暴走标记数 %arg 大于存活反贼数 %arg2，需要失去一枚暴走标记'
}
