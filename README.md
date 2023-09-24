# QSGS-v2-Lua
![LuaCheck](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/lua-check.yml/badge.svg)
## 介绍
这是基于太阳神三国杀 QSanguosha-v2-20190208 编写的武将，使用 Lua 作为开发语言，基于源码的限制，某些功能可能无法完全 Lua 化

## 配置方法
如果您想一边配置一边直接在日神杀环境测试，可以采取如下方案：
1. 在日神杀目录下（即 QSanguosha-v2-20190208）打开 Git Bash
2. 执行命令 git init .
3. git remote add origin git@github.com:DZDcyj/QSGS-v2-Lua.git
4. git pull origin master

或者直接使用 git clone 方式在对应目录下进行

> 注意：如果已经提前使用过 Release 包或者 Download Zip 方式进行过文件的操作，为避免造成大量的文件冲突，请先在一个新的空文件夹进行 git 操作，然后将已有的文件进行复制

执行完毕后，将会拉取对应的 lua 文件到 extensions 目录下，便可在日神杀内使用了。

## 开发建议与指南
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
```Lua
for _, callback in ipairs(sgs.ai_damage_effect) do
    if type(callback) == "function" then
        -- 在最后添加 damage 参数，以传入伤害值
        local is_effective = callback(self, to, nature, from, damage)
        if not is_effective then return false end
    end
end
```

## 当前收录的包和角色
为节省篇幅，请移步[这里](./Generals.md)

## 补充说明

### 关于禁用源码级别的包
您可以在 config.lua 里找到 package_names 配置项，里面存放着对应的包名，根据需要可以注释掉（不建议删除），如下图所示

![image](https://github.com/DZDcyj/QSGS-v2-Lua/assets/42711105/9a61c73b-8494-42d6-af52-b43a2727c716)

**请勿将该配置项的更改提交到仓库中**

> 目前已知问题：小型场景会在禁用**Test**后闪退

### 关于 extra.lua

游戏自带的`extra.lua`文件包含了大量其他的 lua 扩展包武将，但不可避免的存在有 bug，在此列出并提供参考修改方案

> 现在已将 extra.lua 纳入仓库进行管理，无需手动进行操作
