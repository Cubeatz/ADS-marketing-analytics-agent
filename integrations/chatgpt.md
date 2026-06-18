# ChatGPT 配置说明

ChatGPT 不支持项目内的 Agent 规则文件，需通过 UI 手动添加 MCP。

## 步骤

1. 订阅 ChatGPT Plus / Pro / Business / Enterprise
2. 设置 → Connectors → 启用 Developer mode
3. 添加 MCP Server：

| 名称 | URL |
|------|-----|
| Meta Ads | `https://mcp.facebook.com/ads` |
| AppsFlyer | `https://mcp.appsflyer.com/auth/mcp` |

4. Google Ads 官方 MCP 为本地 stdio 服务，**ChatGPT 无法直接连接**。可选方案：
   - 改用 Cursor / Codex / Antigravity 查 Google 数据
   - 或在 ChatGPT 中只连 Meta + AppsFlyer，Google 数据从导出的 CSV 分析

## 对话时粘贴 Agent 指令

每次新对话开头粘贴 `AGENTS.md` 中的「硬性约束」和「标准工作流」段落，或说：

> 你是营销数据分析助手，只读分析，不修改广告。读我上传的 config 和 reports 文件，按 AGENTS.md 规则生成日报。

## 飞书推送

ChatGPT 无法直接运行 `scripts/send-feishu-daily.ps1`。可让 Agent 生成 `data-summary.json` 内容后，在远端电脑手动运行推送脚本。
