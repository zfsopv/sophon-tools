# spicoclaw — Sophon AI Agent Gateway (PicoClaw 定制版)

Sophon 设备 AI agent 服务的出厂部署包。把 PicoClaw（定制版）作为 systemd 服务托管，
替代旧的「由 bmssm 手工 spawn」方式。

## 交付内容

| 组件 | 说明 |
|------|------|
| `sophpicoclaw.service` | AI agent gateway（端口 18790），`Restart=on-failure`，systemd 保活 |
| `sophpicoclaw-launcher.service` | Web 控制台（端口 18800，供 sophliteos AI Agent 页面 iframe），`Restart=on-failure` |
| 安装位置 | `/opt/sophon/picoclaw/bin/`（二进制）、`/opt/sophon/picoclaw/.picoclaw/`（配置） |

## 构建

```bash
# arm64（默认）
bash release.sh
# 指定版本与架构
bash release.sh arm64 0.3.1
bash release.sh all 0.3.1
# 自定义二进制来源
PICOCLAW_BIN_DIR=/path/to/bin bash release.sh arm64 0.3.1
```

产物：`output/spicoclaw/spicoclaw_<version>_<arch>.deb`

## 二进制来源

预编译二进制放在 `binary/<arch>/`（`picoclaw`、`picoclaw-launcher`），
来自 ZeroClaw 定制构建（SE7 定制版，支持 vision 图片描述）。可用 `PICOCLAW_BIN_DIR` 覆盖。

## 安装

```bash
dpkg -i spicoclaw_0.3.1_arm64.deb
```

postinst 自动：
1. 建运行目录 `/opt/sophon/picoclaw/.picoclaw/{logs,workspace}`
2. 归属 `linaro`（与运行身份一致）
3. `systemctl enable --now sophpicoclaw sophpicoclaw-launcher`

## 验证

```bash
systemctl status sophpicoclaw sophpicoclaw-launcher
curl http://127.0.0.1:18790/health   # {"status":"ok",...}
curl -I http://127.0.0.1:18800/       # 302（Web 控制台）
```

## 迁移说明

- 旧部署在 `/home/linaro/picoclaw-deploy/` + `/home/linaro/.picoclaw/`，由 bmssm 拉起。
- 新部署：二进制在 `/opt/sophon/picoclaw/bin/`，配置在 `/opt/sophon/picoclaw/.picoclaw/`，
  由 systemd 托管（`sophpicoclaw` / `sophpicoclaw-launcher`），与 bmssm cgroup 解耦。
- 数据目录 `/data/picoclaw/workspace` 保留（由 config.json 的 `agents.defaults.workspace` 指定）。
- bmssm 侧 `restartPicoclaw()` 已改为 `systemctl restart sophpicoclaw.service`，
  `devproxyKeyPath()` 优先探测 `/opt/sophon/picoclaw/.picoclaw/devproxy.key`。
