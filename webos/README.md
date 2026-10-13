# LibreTV for LG webOS

把 LibreTV 打包成 LG webOS 电视应用。

LibreTV 是需要服务端运行的 Next.js 站点（含搜索 / 代理 API），无法整体塞进电视，因此这里的 webOS 应用是一个**薄壳**：

1. 启动后读取（或让你输入）LibreTV 服务器地址；
2. 探测服务器可达后，全屏跳转到该地址。

所以你需要先在局域网内（NAS / 软路由 / 树莓派 / VPS 均可）部署好 LibreTV，参见仓库根目录 [README](../README.md) 的 Docker 部署。

## 一、成为 webOS 开发者（免费）

安装自己打包的应用，需要「开发者账号 + 电视开发者模式」，不需要付费，也不需要 root。

### 1. 注册 LG 开发者账号

1. 打开 <https://webostv.developer.lge.com/>，点击右上角 **Sign In → Sign Up**。
2. 用邮箱注册并完成邮件验证（个人开发者即可，不需要公司资质）。

### 2. 电视上开启开发者模式

1. 电视联网，打开 **LG Content Store**，搜索 **Developer Mode** 并安装。
   （找不到时先确认电视地区；部分地区商店没有这个应用，可在 设置 → 通用 → 位置 里切换地区后重试）
2. 打开 **Developer Mode** 应用，用第 1 步的开发者账号登录。
3. 把 **Dev Mode Status** 打开，电视会重启。
4. 重启后再次打开 Developer Mode 应用，把 **Key Server** 也打开。
5. 记下界面上显示的 **电视 IP** 和 **Passphrase（口令）**。

> ⏱ 开发者模式每 **50 小时** 过期一次。到期前打开 Developer Mode 应用点 **Extend** 即可续期；
> 过期后已装的应用会无法打开，续期后恢复。

### 3. 电脑上安装 webOS CLI

需要 Node.js，然后：

```bash
npm install -g @webos-tools/cli
```

把电视添加为设备（`<电视IP>` 换成上一步看到的 IP，电视名字随意，这里叫 `tv`）：

```bash
ares-setup-device --add tv -i "host=<电视IP>" -i "port=9922" -i "username=prisoner"
ares-novacom --device tv --getkey      # 按提示输入电视上显示的 Passphrase
ares-device-info --device tv           # 能打印出电视信息即配置成功
```

电脑和电视必须在同一局域网。

## 二、打包并安装

```bash
cd webos
./build.sh --url http://192.168.1.10:8080     # 换成你的 LibreTV 服务器地址
```

产物：`webos/out/org.libretv.webos_1.0.0_all.ipk`。

- 不带 `--url` 也可以，首次启动时用遥控器在电视上输入地址。
- `build.sh` 优先使用已安装的 `ares-package`，没有则通过 `npx` 临时拉取。

安装并启动：

```bash
ares-install --device tv out/org.libretv.webos_1.0.0_all.ipk
ares-launch  --device tv org.libretv.webos
```

之后在电视的应用列表里就能看到 **LibreTV**。卸载：`ares-install --device tv --remove org.libretv.webos`。

## 三、使用说明

| 场景 | 操作 |
| --- | --- |
| 首次启动 | 输入服务器地址（可省略 `http://`），按 **连接** |
| 之后启动 | 显示 3 秒「即将连接」，期间按遥控器 **确定** 键可修改服务器地址，否则自动进入 |
| 服务器连不上 | 自动回到地址输入页并提示 |
| 返回键 | 在站内等同浏览器后退；在启动页退出应用 |

> 进入站点后页面来自你的服务器，修改地址需要重新启动应用并在 3 秒内按确定键。

## 四、常见问题

- **`ares-setup-device` / `ares-novacom` 连不上**：检查电视与电脑是否同网段，Key Server 是否已打开，口令是否输入正确（区分大小写）。
- **应用打不开 / 提示过期**：开发者模式 50 小时到期，进 Developer Mode 应用点 Extend。
- **想免续期**：需要电视已 root 并安装 Homebrew Channel（<https://www.webosbrew.org/>），不同机型 / 固件的可行性差异很大，风险自负，本项目不提供此流程。
- **播放卡顿 / 不兼容**：webOS 内置 Chromium 版本随系统而异（webOS 4.x 约 Chrome 53，5.x 约 68，6.x 约 79，更新的版本更高）。LibreTV 使用较新的前端栈，系统越旧越可能出现页面或播放器无法运行；本壳尚未在真机上逐版本验证，建议优先在 webOS 6 及以上使用。
- **只能用魔术遥控的指针操作**：站点界面为鼠标 / 触屏设计，尚未做方向键焦点导航。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `appinfo.json` | webOS 应用清单（应用 ID `org.libretv.webos`） |
| `index.html` | 启动页：输入 / 记忆服务器地址、探活、跳转 |
| `config.js` | 默认服务器地址（可由 `build.sh --url` 覆盖） |
| `icon.png` `largeIcon.png` `splash.png` | 图标与启动画面（取自 `public/icons`） |
| `build.sh` | 打包脚本，输出到 `out/`（已 gitignore） |
