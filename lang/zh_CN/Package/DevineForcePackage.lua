-- translation for DevineForcePackage

return {
    ['DevineForcePackage'] = '神·武包',
    ['ExTenYearShenJiangwei'] = '神姜维',
    ['&ExTenYearShenJiangwei'] = '神姜维',
    ['#ExTenYearShenJiangwei'] = '怒麟布武',
    ['LuaTianren'] = '天任',
    [':LuaTianren'] = '锁定技，①当一张或多张基本牌或普通锦囊牌不是因使用而置入弃牌堆后，你获得等量个“天任”标记；\
    ②当你获得“天任”标记后，若“天任”标记数不小于你的体力上限，你移去体力上限数个“天任”标记，加1点体力上限并摸两张牌，然后你重复此流程直到“天任”标记数小于你的体力上限',
    ['#LuaTianren'] = '%from 的“%arg”被触发，获得 %arg2 个“%arg”标记',
    ['@LuaTianren'] = '天任',
    ['LuaJiufa'] = '九伐',
    [':LuaJiufa'] = '当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张',
    ['LuaPingxiang'] = '平襄',
    [':LuaPingxiang'] = '限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限，失去技能“九伐”且本局游戏内你的手牌上限等于体力上限。然后你视为使用至多九张不计入次数限制的【火杀】',
    ['@LuaPingxiang'] = '平襄',
    ['@LuaPingxiang-invoke'] = '你还可以发动至多 %arg 次“平襄”，视为使用一张不计入次数限制的【火杀】',
    ['luapingxiang'] = '平襄',
    ['~LuaPingxiang'] = '选择若干名合法角色→点击“确定”',
    ['ExTenYearShenZhangfei'] = '神张飞',
    ['&ExTenYearShenZhangfei'] = '神张飞',
    ['#ExTenYearShenZhangfei'] = '两界大巡环使',
    ['LuaShencai'] = '神裁',
    [':LuaShencai'] = '出牌阶段限一次，你可以令一名其他角色进行一次判定且你获得判定牌，若判定牌包含以下内容，则你可以令其获得下列对应效果（覆盖之前的效果），否则该角色获得1个“死”标记且你获得其区域内的一张牌。\
    （有“死”标记的角色：1.其手牌上限减少其“死”标记数；2.其回合结束时，若其“死”标记数大于场上存活角色数，其死亡）\
    体力-“笞”-受到伤害后失去等量体力\
    武器-“杖”-不能响应【杀】\
    打出-“徒”-失去手牌后（因此技能除外）随机弃置一张手牌\
    距离-“流”-结束阶段，将武将牌翻面',
    ['luashencai'] = '神裁',
    ['LuaXunshi'] = '巡使',
    [':LuaXunshi'] = '锁定技，①你的多目标锦囊牌均视为无色【杀】；\
    ②当你使用无色牌时，此牌无距离与次数限制（使用时，可以额外指定任意个目标），然后你每个出牌阶段内发动“神裁”的次数上限+1（至多加至5）',
    ['@LuaShencai-Chi'] = '笞',
    ['@LuaShencai-Zhang'] = '杖',
    ['@LuaShencai-Tu'] = '徒',
    ['@LuaShencai-Liu'] = '流',
    ['@LuaShencai-Death'] = '死',
    ['#LuaShencai-Chi'] = '%from 的“%arg2”标记效果被触发，失去 %arg 点体力',
    ['#LuaShencai-Zhang'] = '%from 的“%arg”标记效果被触发，无法响应此杀',
    ['#LuaShencai-Tu'] = '%from 的“%arg”标记效果被触发，随机弃置一张手牌',
    ['#LuaShencai-Liu'] = '%from 的“%arg”标记效果被触发，将武将牌翻面',
    ['#LuaShencai-Death'] = '%from 的“%arg”标记效果被触发，直接死亡',
}
