---
name: marketing-analytics
description: >-
  营销只读数据分析工作流：Google Ads + Meta Ads + AppsFlyer 日报、素材疲劳、
  预算建议、归因对比、飞书推送或 DOCX 导出。无数据库，读 config/ 下 JSON 配置。
disable-model-invocation: false
---

# 营销数据分析 Skill

## 何时启用

- 用户说「首次配置」「初始化」「设置 agent」
- `config/workspace.json` 不存在或未完成 onboarding
- 营销日报 / 数据分析 / 素材疲劳 / 归因对比等

## 配置文件

| 文件 | 作用 |
|------|------|
| `config/workspace.json` | **总配置**（平台、目录、时间、投递） |
| `config/accounts.json` | App 与各平台账户 ID |
| `config/field-mapping.json` | 跨平台指标字段对照 |
| `config/thresholds.json` | 分析阈值 |
| `config/feishu.json` | 飞书 Webhook |

首次使用前，从 `*.example.json` 复制并填写，或运行 `scripts/onboard.ps1`。

## 工作流 0：首次引导（优先）

若 `workspace.json` → `onboarding.completed` 不为 true：

0. **环境检查**：`scripts/check-environment.ps1 -Quiet`（齐全则静默；缺 Python 则提示安装并停止）
1. **一键引导**：`scripts/start.ps1`；或 **逐题**问卷 `onboard.ps1`
2. 第 2–8 题可跳过（Z = 默认）；第 1 题不可跳过
3. 第 1 题只展示已支持平台（A–G）；若用户手输无效字母（如 H）则提示重选；**单选题**选错须重选
4. 校验：`python scripts/parse_onboarding_answers.py --validate-only`

## 工作流 A：生成日报

```
0. 检查 workspace onboarding 已完成
1. ensure-temp-dirs → 创建 temp/raw|processed|cache|logs|exports 全部分类子目录
2. 读 workspace + accounts，对每个启用平台 MCP 拉数
3. 原始 JSON → temp/raw/{date}/{platform}/{category}/（每类独立文件，禁止混放）
4. 清洗 → temp/processed/；日志 → temp/logs/{date}/fetch.log
5. 分析 → reports/{date}/
6. deliver-report 按 delivery.mode 投递
```

## 工作流 B：素材疲劳分析

读取 `config/thresholds.json` → `creative_fatigue`：

| 等级 | 条件（满足任一） |
|------|------------------|
| 观察 | frequency ≥ 2.5 且 CTR 7日环比降 ≥ 10% |
| 预警 | frequency ≥ 3.5 且 CTR 7日环比降 ≥ 15% |
| 严重 | frequency ≥ 4.5 或 CTR 7日环比降 ≥ 25% |

输出表格：Ad 名称 | 投放天数 | Frequency | CTR 变化 | 等级 | 建议

建议仅文字：「考虑轮换素材 / 缩小受众 / 降低预算」，不执行任何操作。

## 工作流 C：预算建议

读取 `config/thresholds.json` → `budget`：

| 信号 | 条件 | 建议 |
|------|------|------|
| 预算不足 | 利用率 ≥ 90% 且 IS lost to budget > 15%（Google） | 建议加预算 XX% |
| 预算浪费 | 利用率 < 50% 且 CPA 高于账户均值 30%+ | 建议减预算或暂停 |
| 正常 | 其他 | 维持观察 |

## 工作流 D：归因差异

使用 `config/field-mapping.json` 对齐字段后对比：

```
差异% = (平台自报 - AppsFlyer) / AppsFlyer × 100
```

| 差异范围 | 解读 |
|----------|------|
| ±10% 以内 | 正常波动 |
| 10–30% | 关注（归因窗口 / 时区 / SKAN 延迟） |
| >30% | 需排查（追踪链接、事件映射、重复计数） |

## 报告投递（飞书 / DOCX）

统一入口 `scripts/deliver-report.ps1` 或 `deliver-report.sh`：

1. `config/feishu.json` 中 `enabled=true` 且 `webhook_url` 有效 → 飞书推送
2. 否则 → 生成 Word（`docx_fallback`）

**DOCX 输出配置**（`config/feishu.json`）：

```json
"docx_fallback": {
  "enabled": true,
  "output_dir": "reports/{date}",
  "filename": "daily-report.docx",
  "custom_output_dir": "C:/Users/运营/Desktop/营销日报"
}
```

`custom_output_dir` 留空则输出到项目内 `reports/{date}/daily-report.docx`。

Windows:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\deliver-report.ps1 -Date 2026-06-17
```

macOS/Linux:
```bash
bash scripts/deliver-report.sh 2026-06-17
```

仅导出 DOCX:
```bash
python scripts/export-report-docx.py --date 2026-06-17
```

## MCP 查询参考

### Google Ads（只读 GAQL 示例）

```
SELECT campaign.name, metrics.cost_micros, metrics.impressions,
       metrics.clicks, metrics.conversions, metrics.cost_per_conversion
FROM campaign
WHERE segments.date DURING LAST_7_DAYS
  AND campaign.status = 'ENABLED'
```

### Meta Ads（insights 参数）

- level: campaign / adset / ad
- fields: spend, impressions, clicks, ctr, cpm, frequency, actions, action_values
- date_preset: yesterday / last_7d

### AppsFlyer

- 按 MCP 可用工具查询：installs by media_source, cost, revenue, SKAN data
- 时间范围与 Google/Meta 对齐后再做对比

## 输出质量要求

- 数字保留 2 位小数（金额、百分比）
- 每条建议说明 **依据**（哪条数据、哪个阈值）
- 非技术人员能读懂，避免 API 字段原名堆砌（用 field-mapping 里的 display_name）
