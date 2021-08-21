# QSGS-v2-Lua

TODO: 这个标志目前只显示 master 分支的状态，之后会更新状态为单独的分支
![LuaCheck](https://github.com/DZDcyj/QSGS-v2-Lua/actions/workflows/lua_check.yml/badge.svg)

## 介绍
这是基于太阳神三国杀 QSanguosha-v2-20190208 编写的武将，使用 Lua 作为开发语言，基于源码的限制，某些功能可能无法完全 Lua 化

## 配置方法
如果你想一边配置一边直接在日神杀环境测试，可以采取如下方案：
1. 在日神杀目录下（即 QSanguosha-v2-20190208）打开 Git Bash
2. 执行命令 git init .
3. git remote add origin git@gitee.com:cyjdtxz/QSGS-v2-Lua.git
4. git pull origin master

执行完毕后，将会拉取对应的 lua 文件到 extensions 目录下，便可在日神杀内使用了。

## 开发建议
我个人建议在开发时自己新建对应分支，开发完毕后 push 到仓库，可以合并时选择创建 Pull Request。

当然你也可以直接在 master 分支上开发，但我设置了保护分支和评审模式，push 之后会自动新开分支并创建对应的 Pull Request。

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
