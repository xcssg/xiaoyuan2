# 乌市职专墙

乌市职专墙 · 校园社区 Flutter 客户端 + Node/SQLite 后端。

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
