# Claude Code 项目指令

本项目的 Agent 行为定义见 [AGENTS.md](./AGENTS.md)。

核心原则：

- 服务对象是非技术广告投放人员。
- 配置、安装、拉数和投递尽量由 Agent 自动完成。
- 不要把命令直接丢给用户复制。
- 只读分析，不修改广告账户。
- 不使用数据库，配置在 `config/`，报告输出到 `reports/` 和 `output/documents/`。

平台凭证来源见 [各平台凭证配置指南](docs/PLATFORM-CREDENTIALS.md)。IDE/MCP 差异见 [IDE 支持矩阵](docs/IDE-MATRIX.md)。
