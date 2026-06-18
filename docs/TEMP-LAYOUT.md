# temp 目录分层规范

**禁止**把平台拉取的数据全部堆在一个文件夹里。必须按下面层级存放。

## 总览

```
temp/
├── raw/              # ① MCP 原始 JSON
├── processed/        # ② 清洗对齐后的中间数据
├── cache/            # ③ 查询缓存（按平台，无 category 子层）
├── logs/             # ④ 拉数日志（按日期，无平台子层）
└── exports/          # ⑤ 可选 CSV 导出
```

每一类之下再分：**日期 → 平台 → 数据类别**（cache/logs 略简）。

---

## ① raw — 原始 MCP 响应

```
temp/raw/{YYYY-MM-DD}/
├── google_ads/
│   ├── account/          ← 账户信息、customer 列表
│   ├── campaigns/        ← campaign 层级 GAQL / search 结果
│   ├── ad_groups/
│   ├── keywords/
│   └── metrics/          ← 汇总指标快照
├── meta_ads/
│   ├── account/
│   ├── campaigns/
│   ├── adsets/
│   ├── ads/
│   ├── creatives/
│   └── insights/         ← insights API 原始块
└── appsflyer/
    ├── attribution/      ← 按渠道安装、花费
    ├── skan/
    ├── cohorts/
    └── events/
```

**命名示例：**
- `temp/raw/2026-06-17/google_ads/campaigns/daily_performance.json`
- `temp/raw/2026-06-17/meta_ads/ads/creative_fatigue_7d.json`
- `temp/raw/2026-06-17/appsflyer/attribution/installs_by_source.json`

---

## ② processed — 清洗后中间数据

```
temp/processed/{YYYY-MM-DD}/
├── google_ads/
│   └── metrics/normalized.json
├── meta_ads/
│   └── insights/normalized.json
├── appsflyer/
│   └── attribution/normalized.json
└── blended/              # 跨平台（shared_categories）
    └── comparison/platform_gap.json
```

---

## ③ cache — 短期缓存

```
temp/cache/{YYYY-MM-DD}/
├── google_ads/
├── meta_ads/
└── appsflyer/
```

单文件建议带查询 hash 或时间戳，例如 `campaigns_abc123.json`。

---

## ④ logs — 操作日志

```
temp/logs/{YYYY-MM-DD}/
├── fetch.log             # 每次 MCP 拉数记录
├── errors.log            # 失败与重试
└── delivery.log          # 飞书/DOCX 投递记录
```

---

## ⑤ exports — 可选导出

```
temp/exports/{YYYY-MM-DD}/
├── google_ads/campaigns/summary.csv
├── meta_ads/ads/top_ads.csv
└── appsflyer/attribution/channels.csv
```

---

## Agent 写入规则

1. 每次 MCP 调用结果 → 写入对应 **raw/{date}/{platform}/{category}/** 下独立文件
2. 字段对齐、合并后 → **processed/** 对应路径
3. 同一查询 1 小时内重复 → 可读 **cache/**，命中则跳过 MCP
4. 每次拉数开始/结束 → 追加 **logs/{date}/fetch.log**
5. 生成报告前 → 优先读 processed，若无则从 raw 现算

## 初始化目录

```powershell
powershell -ExecutionPolicy Bypass -File scripts\ensure-temp-dirs.ps1 -Date 2026-06-17
```

或 onboard 完成后自动创建当日骨架。

## 清理

`preferences.keep_temp_days`（默认 30）天前的 `temp/` 下各日期文件夹可整目录删除。
