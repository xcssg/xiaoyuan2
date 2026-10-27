# 乌市职专墙

乌市职专墙 · 校园社区 Flutter 客户端 + Node/SQLite 后端。

当前版本：V1.01（`version: 1.0.1+2`）

## 功能

- 注册：算术验证码、真实姓名、班级，可选是否公开姓名与班级
- 社区：寻物 / 吐槽 / 表白 / 找人四个板块，发帖、评论、点赞、匿名
- 个人中心：编辑头像与昵称、查看积分、班级与姓名展示、装扮预览
- 成长体系：每日任务获取积分，积分商店兑换头像框、昵称颜色、专属称号
- 公告：管理员发布公告，重要公告进入应用时弹窗，阅读 3 秒后可关闭
- 管理后台：真实数据统计、用户管理、贴吧管理、称号授予、公告与任务维护、关于文案编辑

## 项目结构

- `lib/` Flutter Android 客户端
- `server/` Node 22 + SQLite API
- `.github/workflows/build-apk.yml` GitHub Actions 自动打包 APK

## 线上服务

- API 地址：`https://wszz.154.12.88.52.sslip.io`
- 香港服务器，Caddy 自动 HTTPS，systemd 守护
- 数据保存在服务器 SQLite，所有用户共享同一套内容

## 打包 APK

```bash
flutter pub get
flutter build apk --release
```

或在 GitHub Actions 中运行 **Build Android APK**。

如果更换了服务器域名，可在 GitHub 仓库的 **Settings → Variables** 添加
`API_BASE_URL`，重新打包时会自动注入。

## 本地启动服务端

```bash
cd server
npm install
npm start
```

默认监听 `127.0.0.1:8080`，数据库文件为 `server/data.sqlite`。
# xiaoyuan
# xiaoyuan2
