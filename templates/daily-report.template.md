# 营销日报 — {{DATE}}

> 报告时区：{{TIMEZONE}} | 生成时间：{{GENERATED_AT}}

---

## 1. 总览

| App | Google 花费 | Meta 花费 | AF 安装 | 综合 CPI | 综合 ROAS | 状态 |
|-----|------------|----------|---------|---------|----------|------|
{{OVERVIEW_TABLE_ROWS}}

---

## 2. Google Ads

### 2.1 核心指标（{{GOOGLE_PERIOD}}）

| 指标 | 数值 | 环比 |
|------|------|------|
| 花费 | {{GOOGLE_SPEND}} | {{GOOGLE_SPEND_WOW}} |
| 展示 | {{GOOGLE_IMPRESSIONS}} | {{GOOGLE_IMPRESSIONS_WOW}} |
| 点击 | {{GOOGLE_CLICKS}} | {{GOOGLE_CLICKS_WOW}} |
| 转化/安装 | {{GOOGLE_CONVERSIONS}} | {{GOOGLE_CONVERSIONS_WOW}} |
| CPA/CPI | {{GOOGLE_CPA}} | {{GOOGLE_CPA_WOW}} |

### 2.2 Top Campaigns

| Campaign | 花费 | 安装 | CPI | 备注 |
|----------|------|------|-----|------|
{{GOOGLE_TOP_CAMPAIGNS}}

### 2.3 预算信号

{{GOOGLE_BUDGET_SIGNALS}}

---

## 3. Meta Ads

### 3.1 核心指标（{{META_PERIOD}}）

| 指标 | 数值 | 环比 |
|------|------|------|
| 花费 | {{META_SPEND}} | {{META_SPEND_WOW}} |
| 展示 | {{META_IMPRESSIONS}} | {{META_IMPRESSIONS_WOW}} |
| 安装 | {{META_INSTALLS}} | {{META_INSTALLS_WOW}} |
| CPI | {{META_CPI}} | {{META_CPI_WOW}} |
| 平均频次 | {{META_FREQUENCY}} | {{META_FREQUENCY_WOW}} |

### 3.2 Top Ad Sets

| Ad Set | 花费 | 安装 | CPI | 频次 | 备注 |
|--------|------|------|-----|------|------|
{{META_TOP_ADSETS}}

### 3.3 素材疲劳清单

| Ad | 投放天数 | 频次 | CTR 变化 | 等级 | 建议 |
|----|---------|------|---------|------|------|
{{CREATIVE_FATIGUE_TABLE}}

---

## 4. AppsFlyer 归因

### 4.1 渠道安装分布（{{AF_PERIOD}}）

| 渠道 | 安装 | 花费 | CPI | 占比 |
|------|------|------|-----|------|
{{AF_CHANNEL_TABLE}}

### 4.2 SKAN / SSOT（如可用）

{{AF_SKAN_SUMMARY}}

---

## 5. 跨平台对比

| 指标 | Google 自报 | Meta 自报 | AppsFlyer | 最大差异 |
|------|------------|----------|-----------|---------|
| 安装 | {{CMP_GOOGLE_INSTALLS}} | {{CMP_META_INSTALLS}} | {{CMP_AF_INSTALLS}} | {{CMP_INSTALLS_GAP}} |
| 花费 | {{CMP_GOOGLE_SPEND}} | {{CMP_META_SPEND}} | {{CMP_AF_SPEND}} | {{CMP_SPEND_GAP}} |
| CPI | {{CMP_GOOGLE_CPI}} | {{CMP_META_CPI}} | {{CMP_AF_CPI}} | {{CMP_CPI_GAP}} |

**差异解读：** {{ATTRIBUTION_INTERPRETATION}}

---

## 6. 行动建议（仅建议，不自动执行）

{{ACTION_ITEMS}}

---

## 附录

- 数据来源：Google Ads MCP / Meta Ads MCP / AppsFlyer MCP
- 配置文件：`config/accounts.json`、`config/thresholds.json`
- 结构化数据：`reports/{{DATE}}/data-summary.json`
