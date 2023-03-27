-- translation for ExpansionCard Package

return {
    ['ExpansionCardPackage'] = '扩展卡牌包',
    ['indirect_combination'] = '奇正相生',
    [':indirect_combination'] = '锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：你为其指定正兵或奇兵，然后其可以打出一张【杀】或【闪】\
    若奇兵目标没有打出【杀】，你对其造成1点伤害\
    若正兵目标没有打出【闪】，你获得其一张牌',
    ['indirect_combination-card'] = '%src 使用了【奇正相生】，请打出一张【%arg】',
    ['Direct'] = '正兵',
    [':Direct'] = '若其没有打出一张【闪】，则你获得其一张牌',
    ['Indirect'] = '奇兵',
    [':Indirect'] = '若其没有打出一张【杀】，则你对其造成一点伤害',
    ['ResponseSlash'] = '打出一张【杀】',
    [':ResponseSlash'] = '防止此【奇正相生】使用者对你造成一点伤害',
    ['ResponseJink'] = '打出一张【闪】',
    [':ResponseJink'] = '防止此【奇正相生】使用者获得你的一张牌',
    ['#DirectFailed'] = '%to 没有打出【%arg】，%from 将获得其一张牌',
    ['#IndirectFailed'] = '%to 没有打出【%arg】，%from 将对其造成一点伤害',
}
