# QSGS-v2-Lua
![LuaCheck](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/lua-check.yml/badge.svg)
## 介绍
这是基于太阳神三国杀 QSanguosha-v2-20190208 编写的武将，使用 Lua 作为开发语言，基于源码的限制，某些功能可能无法完全 Lua 化

## 额外说明
~~本仓库现已经同步到国内镜像，欢迎加入。~~

由于国内镜像仓库被封禁，现已经移动到私有 GitLab 镜像仓库
（2022/09/11 更新）

目前采取的策略是 GitLab 同步更新 Github master 分支，因此主要负责还是在 Github 侧

有问题欢迎及时反馈

## 配置方法
如果您想一边配置一边直接在日神杀环境测试，可以采取如下方案：
1. 在日神杀目录下（即 QSanguosha-v2-20190208）打开 Git Bash
2. 执行命令 git init .
3. git remote add origin git@github.com:DZDcyj/QSGS-v2-Lua.git
4. git pull origin master

执行完毕后，将会拉取对应的 lua 文件到 extensions 目录下，便可在日神杀内使用了。

## 开发建议与指南
在进行开发之前，请先在您的环境下配置 Git：

Windows 环境下请在如下链接下载即可：

[Git 官方网址](https://git-scm.com/)

macOS 环境下请在 homebrew 里进行操作：
```bash
$ brew install git
```

如果您对 Git 的操作不够熟悉，可以参考如下指南：

[Git 廖雪峰教程](https://www.liaoxuefeng.com/wiki/896043488029600)

在 Windows 或者 macOS 环境下，可以使用`SourceTree`等可视化 Git Gui 工具来辅助进行操作。

[SourceTree 官网](https://www.sourcetreeapp.com/)

如果在 Git 操作上存在有问题，随时可以问我，我会尽快进行回复

如果有新的想法、建议，抑或是发现当前存在的一些 bug，请在`Issue`里提出，我会尽快回复以推进进程。

关于详细的贡献指南，请参考[这里](.github/CONTRIBUTING.md)

## 文件目录
### .github
这个目录下主要放有与 Github 相关的配置文件，包含 Issue 模板、工作流文件、CodeOwner 配置等，请勿轻易修改此文件夹下的内容

### audio
这个目录下主要放有技能语音文件，通常以`技能名+序号.ogg`的格式命名

### extensions
这个目录下放有代码源文件

### image
这个目录下放有卡牌和头像的图片资源，包含皮肤等资源

### lang
这个目录下主要放有对应的文本文字，例如技能语音、描述，武将信息等

### lua
这个目录下放有 AI 文件以及抽离出来的公共方法调用部分

添加 AI 伤害判断后，smart-ai 文件需要同步更新

**请在 smart-ai.lua 文件中添加如下代码**
```
for _, callback in ipairs(sgs.ai_damage_effect) do
    if type(callback) == "function" then
        -- 在最后添加 damage 参数，以传入伤害值
        local is_effective = callback(self, to, nature, from, damage)
        if not is_effective then return false end
    end
end
```

## 当前收录的包和角色
### 群友包
- 仙人掌
- 浮华
- 磷酸
- SP 浮华
- SP 仙人掌
- 秋目
- SP 磷酸
- 暗暗
- 饿人类
- 西行寺妖羽
- 纱羽
- 夜鸟
- 文爻林夕
- 阿杰

### 扩展武将包
PS: 为了导入资源和避免已有武将冲突，在界限突破外的武将内部名称中以`Ex`作前缀

- 王元姬
- 徐荣
- 曹婴
- 李傕
- 马良
- 曹纯
- 贾逵
- 界徐盛
- 界马岱
- 马钧
- 伊籍
- 李丰
- 赵统赵广
- 界颜良文丑
- 界凌统
- 审配
- 杨彪
- 骆统
- 张翼
- 界李儒
- 界满宠
- 界廖化
- 界朱然
- 界于禁
- 留赞-十周年
- 王粲
- 周处
- 界孙策
- 杜预
- 陈震
- 公孙康
- 张济
- 董承-十周年
- 王朗-十周年
- 赵襄-十周年
- 界钟会
- 星徐晃
- 关索-十周年
- 星甘宁
- 界曹植
- 界陈群
- 界荀彧
- 苏飞
- 神赵云
- 朱灵
- 郭照
- 界邓艾
- 界张角
- 袁谭袁尚
- 谋黄忠
- 谋甘宁
- 界贾诩
- OL 界荀彧
- 神郭嘉
- 界夏侯惇

## 补充说明
游戏自带的`extra.lua`文件包含了大量其他的 lua 扩展包武将，但不可避免的存在有 bug，在此列出并提供参考修改方案

### 转换技导致部分技能触发多次
#### 原因
系转换技相关的`ChangeCheck`方法中使用了`ChangeHero`方法，调用该方法时将`invokeStart`参数传递为`true`，使得`sgs.EventAcquireSkill`时机触发，并进行相关询问

#### 参考修改方案
将`ChangeHero`方法的对应参数改为`false`

对应函数原型如下：
```C++
void Room::changeHero(ServerPlayer *player, const QString &new_general, bool full_state, bool invokeStart,
    bool isSecondaryHero, bool sendLog)
```
### 岑昏【极奢】不发动
#### 原因
系源代码中使用了未定义的变量`room`所致

#### 参考修改方案
在`extra.lua`的相关代码中添加获取`room`语句即可：
```
on_phasechange = function(self, player)
    local invoke = false
    -- 这里使用了未定义的 room，添加即可
    local room = player:getRoom()
    for _, p in sgs.qlist(room:getAlivePlayers()) do
	if not invoke then
		invoke = not p:isChained()
	end
    end
    if invoke and player:getPhase() == sgs.Player_Finish and player:isKongcheng() and player:getHp() > 0 then
	player:getRoom():askForUseCard(player, "@@jishe", "@jishe")
    end
end
```

