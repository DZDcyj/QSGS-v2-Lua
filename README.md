# QSGS-v2-Lua

![LuaCheck](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/lua-check.yml/badge.svg)
[![CodeQL](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/github-code-scanning/codeql)
![Latest Release](https://img.shields.io/github/v/release/DZDcyj/QSGS-v2-Lua.svg)

## 介绍

这是基于太阳神三国杀 QSanguosha-v2-20190208 编写的武将，使用 Lua 作为开发语言，基于源码的限制，某些功能可能无法完全 Lua 化

## 配置方法

如果您想一边配置一边直接在日神杀环境测试，可以采取如下方案:

1. 在任意目录下执行 `git clone git@github.com:DZDcyj/QSGS-v2-Lua.git`
2. 将 QSGS-v2-Lua 文件夹下的所有文件和子目录（包括隐藏文件和子目录）复制到日神杀（即 QSanguosha-v2-20190208）目录下，当提示同名文件时，选择覆盖文件
3. 在日神杀目录下打开 Git Bash，执行如下命令将当前 Git 仓库配置为大小写敏感

    ```bash
    git config core.ignorecase false
    ```

4. 执行 git status，若出现以下内容则表明配置完成

    ```bash
    On branch master
    Your branch is up to date with 'origin/master'.

    nothing to commit, working tree clean
    ```

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

> 建议开发时将武将包和卡牌包拆分到不同的文件

### image

这个目录下放有卡牌和头像的图片资源，包含皮肤等资源

### lang

这个目录下主要放有对应的文本文字，例如技能语音、描述，武将信息等

### lua

这个目录下放有 AI 文件以及抽离出来的公共方法调用部分

添加 AI 伤害判断后，smart-ai 文件需要同步更新

**更新方式:** 请在 smart-ai.lua 文件中修改如下代码

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

禁用时有如下注意事项，还请知悉

1. 小型场景会在禁用 Test（测试包）后闪退，原因在于测试包里有士兵（男、女）武将，小型场景会预先分配，导致闪退
2. 若要进行联机，请保证使用**相同的配置**，否则可能会出现卡牌 ID 与实际不一致的情况

**重要:** 请勿将该配置项的更改提交到仓库中

### 关于 extra.lua

游戏自带的`extra.lua`文件包含了大量其他的 lua 扩展包武将，但不可避免的存在有 bug，在此列出并提供参考修改方案

> 现在已将 extra.lua 纳入仓库进行管理，无需手动进行操作
