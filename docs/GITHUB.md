# GitHub 使用说明

这份文档给技术维护者使用。普通广告投放用户不需要操作 GitHub。

本项目的 `.gitignore` 已排除可能包含密钥的本地配置，例如：

- `config/accounts.json`
- `config/workspace.json`
- `config/feishu.json`
- `config/onboarding-extras.json`
- `temp/`
- `reports/`
- `output/`

## 首次关联 GitHub

维护者可以使用 GitHub CLI 登录并创建远端仓库：

```powershell
gh auth login
powershell -ExecutionPolicy Bypass -File scripts\setup-github.ps1
```

公开仓库：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup-github.ps1 -Visibility public
```

## 仓库地址

https://github.com/Cubeatz/ADS-marketing-analytics-agent

## 克隆到另一台电脑

技术维护者可以克隆仓库；广告投放用户应直接让 Agent 完成首次配置。

```powershell
git clone https://github.com/Cubeatz/ADS-marketing-analytics-agent.git
cd ADS-marketing-analytics-agent
```
