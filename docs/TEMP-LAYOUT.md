# temp 目录分层规范

平台拉取的数据不能全部堆在一个文件夹里，必须按 **类型 → 日期 → 平台 → 数据类别** 分层。

Agent 会在拉数或生成日报前自动创建当天所需目录，用户不需要手动创建。操作日志不放在 `temp/`，而是单独放在 `logs/{date}/`，方便排查定时任务和授权问题。

## 总览

```text
temp/
├─ raw/          MCP 原始 JSON
├─ processed/    清洗对齐后的中间数据
├─ cache/        查询缓存
├─ logs/         拉数日志
└─ exports/      可选 CSV 导出
```

每一类下面再分日期、平台、数据类别。`cache` 和 `logs` 可以更简单。

## raw：原始 MCP 响应

```text
temp/raw/{YYYY-MM-DD}/
├─ google_ads/
│  ├─ account/
│  ├─ campaigns/
│  ├─ ad_groups/
│  ├─ keywords/
│  └─ metrics/
├─ meta_ads/
│  ├─ account/
│  ├─ campaigns/
│  ├─ adsets/
│  ├─ ads/
│  ├─ creatives/
│  └─ insights/
└─ appsflyer/
   ├─ attribution/
   ├─ skan/
   ├─ cohorts/
   └─ events/
```

命名示例：

- `temp/raw/2026-06-17/google_ads/campaigns/daily_performance.json`
- `temp/raw/2026-06-17/meta_ads/ads/creative_fatigue_7d.json`
- `temp/raw/2026-06-17/appsflyer/attribution/installs_by_source.json`

## processed：清洗后的中间数据

```text
temp/processed/{YYYY-MM-DD}/
├─ google_ads/metrics/normalized.json
├─ meta_ads/insights/normalized.json
├─ appsflyer/attribution/normalized.json
└─ blended/comparison/platform_gap.json
```

## cache：短期缓存

```text
temp/cache/{YYYY-MM-DD}/
├─ google_ads/
├─ meta_ads/
└─ appsflyer/
```

同一查询 1 小时内重复时，Agent 可以优先读缓存，避免重复拉数。

## logs：操作日志

`temp/logs/{date}/` 保存拉数过程中的临时日志，例如 MCP 响应错误、清洗错误等。

```text
temp/logs/{YYYY-MM-DD}/
├─ fetch.log
├─ errors.log
└─ delivery.log
```

全局操作日志单独保存：

```text
logs/{YYYY-MM-DD}/
├─ run.log
├─ auth-check.log
├─ errors.log
└─ delivery.log
```

全局操作日志统一使用 `[YYYY-MM-DD HH:mm:ss] [LEVEL] EVENT_TYPE key=value ...`。`LEVEL` 参考 log4j2：`TRACE`、`DEBUG`、`INFO`、`WARN`、`ERROR`、`FATAL`；授权重试写 `WARN`，三次失败停止写 `ERROR`。

## exports：可选导出

```text
temp/exports/{YYYY-MM-DD}/
├─ google_ads/campaigns/summary.csv
├─ meta_ads/ads/top_ads.csv
└─ appsflyer/attribution/channels.csv
```

## Agent 写入规则

1. 每次 MCP 调用结果写入对应 `raw/{date}/{platform}/{category}/` 下的独立文件。
2. 字段对齐、合并后的结果写入 `processed/`。
3. 查询缓存写入 `cache/`。
4. 拉数临时日志写入 `temp/logs/`。
5. 定时任务、授权检查、投递结果等操作日志写入 `logs/{date}/`。
6. 生成报告时优先读取 `processed/`；没有 processed 时才从 raw 现算。

## 清理

`preferences.keep_temp_days` 默认 30 天。超过保留天数的 `temp/` 日期目录可以由 Agent 清理。

`preferences.keep_logs_days` 默认 30 天。Agent 每次创建当天 `logs/{date}/` 时，会清理超过保留天数的旧日志目录。
