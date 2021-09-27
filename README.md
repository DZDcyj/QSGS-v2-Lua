# QSGS-v2-Lua
![LuaCheck](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/lua-check.yml/badge.svg)

[![国内镜像流水线构建状态](https://rinkosanvsky.coding.net/badges/QSGS-v2-Lua/job/824702/build.svg)](https://rinkosanvsky.coding.net/p/QSGS-v2-Lua/ci/job)
## 介绍
这是基于太阳神三国杀 QSanguosha-v2-20190208 编写的武将，使用 Lua 作为开发语言，基于源码的限制，某些功能可能无法完全 Lua 化

## 额外说明
本仓库现已经同步到国内镜像，欢迎加入。

目前采取的策略是国内镜像同步更新 Github master 分支，因此主要负责还是在 Github 侧

有问题欢迎及时反馈

国内镜像地址在这里：

https://e.coding.net/rinkosanvsky/QSGS-v2-Lua/QSGS-v2-Lua.git

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

同时，本仓库启用了**保护分支**，因此任何对`master`分支的直接推送都是会被拒绝的，请在开发时新建相应的分支，开发完毕后 push 到仓库，在可以合并时创建 Pull Request。

### 仓库设置
本仓库的 Pull Request 有如下设定：
- Require pull request reviews before merging（合并前必需拉取请求审查）
    - Dismiss stale pull request approvals when new commits are pushed（推送新提交时忽略旧拉取请求批准）
    - Require review from Code Owners（需要代码所有者审查）

这意味着如果要进行合并，您的最后一次提交必须通过代码所有者的审查，并且通过的审查将会在下一次提交之后失效。

- Require status checks to pass before merging（合并前必需状态检查通过）
    - Require branches to be up to date before merging（要求分支在合并前保持最新）

这意味着如果要进行合并，最新的提交需要通过状态检查，也即是内置的 Actions 里的 Lua-Check 和基于 luacheck 的代码规范检查。

现在也引入了 Coding 侧的规范检查，可能的话，将会对代码的圈复杂度做出要求，但目前并不影响流水线的通过

Coding 侧相较于 Github Action，对规范的要求会更高，还请知悉

**注意，如果存在与主分支的冲突或者落后于主分支，请使用变基（rebase）而非合并（merge）的方式更新分支**

- Require conversation resolution before merging（在合并前需要对话解决）

这意味着如果要进行合并，您必须解决掉所有 Review 提出的问题。在 Review 的过程中，审查员可能会对您提交的代码的部分进行评论，要求做出对应的修改，请在解决对应问题之后，将对应的问题标记为已解决，以进行后续的合并检查。

- Require signed commits（必需签名提交）

这意味着如果要进行合并，您的这条分支上的所有提交必须经过签名认证。关于这一步，请在您`Account Settings`里的`SSH and GPG keys`里设置对应的 GPG 密钥，并在每次 commit 时进行签名。如果正常签名，在您的提交记录上将会显示出`Verified`的标志，任何一次没有签名的提交都会阻拦合并的流程。

- Require linear history（必需线性历史记录）

这意味着在进行合并时，我们使用了压缩提交的方式（Squash Merge），这意味着将会把该分支上的所有提交压缩为一次提交，您可以在没有冲突的情况下自行进行合并。在合并完成之后，请务必删除源分支。如果存在冲突或者您希望由我来进行合并，请在评论进行说明。

## 文件目录
### extensions
这个目录下放有代码源文件，单个文件里包含有文本和代码（日后会分离）

## 当前收录的包和角色
### 群友包
- 蒂蒂
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
- 林夕

### 扩展武将包
PS: 为了导入资源和避免已有武将冲突，在界限突破外的武将内部名称中以`Ex`作前缀

- 王元姬
- 徐荣
- 曹婴
- 李傕
- 曹纯
- 马良
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
