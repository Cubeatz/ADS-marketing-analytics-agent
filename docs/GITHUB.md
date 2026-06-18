## 推送到 GitHub

本地已忽略含密钥的配置（`config/accounts.json`、`workspace.json` 等），可安全推送代码。

### 首次关联 GitHub

```powershell
# 1. 登录 GitHub（浏览器授权，只需一次）
gh auth login

# 2. 创建远程仓库并推送（默认私有仓库 marketing-analytics-agent）
powershell -ExecutionPolicy Bypass -File scripts\setup-github.ps1
```

公开仓库：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup-github.ps1 -Visibility public
```

### 仓库地址

https://github.com/Cubeatz/ADS-marketing-analytics-agent

### 克隆到远端电脑

```powershell
git clone https://github.com/Cubeatz/ADS-marketing-analytics-agent.git
cd ADS-marketing-analytics-agent
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```
