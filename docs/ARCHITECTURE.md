# 系统架构

## 设计原则

1. **只读分析** — 不修改任何广告平台数据
2. **无数据库** — JSON 配置 + 文件报告，非技术人员零运维
3. **多 IDE 兼容** — 同一项目，各 IDE 独立 MCP 配置
4. **官方直连** — 不经 Markifact 等第三方中转

## 架构图

```mermaid
flowchart TB
    subgraph users [使用者]
        U[非技术运营人员]
    end

    subgraph ides [AI 客户端 任选其一]
        Cursor
        Codex
        Antigravity
        Claude
        Windsurf
        VSCode
    end

    subgraph project [项目文件夹 共享]
        Rules[".cursor/rules 或 AGENTS.md"]
        Config["config/*.json"]
        Reports["reports/YYYY-MM-DD/"]
        Scripts["scripts/send-feishu-daily.*"]
    end

    subgraph mcp_local [本机 MCP]
        G["google-ads-mcp\n(官方, stdio)"]
    end

    subgraph mcp_remote [官方远程 MCP]
        M["mcp.facebook.com/ads"]
        A["mcp.appsflyer.com"]
    end

    subgraph apis [官方 API]
        GAPI[Google Ads API]
        MAPI[Meta Marketing API]
        AAPI[AppsFlyer Report API]
    end

    subgraph notify [报告投递]
        Feishu[飞书 Webhook]
        Docx[DOCX 文件]
    end

    U --> ides
    ides --> Rules
    ides --> Config
    ides --> G
    ides --> M
    ides --> A
    G --> GAPI
    M --> MAPI
    A --> AAPI
    ides --> Reports
    Reports --> Scripts
    Scripts --> Feishu
    Scripts --> Docx
```

## 数据流（日报）

```
1. Agent 读 config/accounts.json
2. MCP 拉数（Google / Meta / AppsFlyer）
3. 按 field-mapping.json 统一字段名
4. 按 thresholds.json 计算疲劳 & 预算信号
5. 写 reports/{date}/daily-report.md
6. 写 reports/{date}/data-summary.json
7. deliver-report：飞书已配置 → Webhook；否则 → DOCX
```

## 存储说明（无数据库）

| 类型 | 位置 | 说明 |
|------|------|------|
| 原始 JSON | `temp/raw/{date}/{platform}/{category}/` | MCP 拉数，按类别分文件夹 |
| 清洗数据 | `temp/processed/{date}/...` | 对齐后中间文件 |
| 缓存 | `temp/cache/{date}/{platform}/` | 避免重复查询 |
| 日志 | `temp/logs/{date}/` | fetch.log |
| 导出 | `temp/exports/{date}/...` | 可选 CSV |
| 日报 md | `reports/{date}/` | Agent 生成 |
| 缓存 | `cache/`（可选） | 旧版兼容 |

详见 [TEMP-LAYOUT.md](TEMP-LAYOUT.md)。

## IDE 配置隔离

各 IDE 的 MCP 配置安装在**用户目录**，项目内只放模板：

- 项目共享：`config/`、`reports/`、`AGENTS.md`
- IDE 私有：`~/.cursor/`、`~/.codex/`、`~/.gemini/antigravity/` 等

这样同一文件夹可在 Cursor 和 Codex 之间切换，数据不重复。
