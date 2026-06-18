# 首次使用引导

## 一键启动（推荐）

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```

流程：**环境检查**（齐全则静默）→ **字母问卷** → **安装 MCP** → 提示下一步。

参数示例：

```powershell
# 跳过 MCP 安装（只做问卷）
powershell -ExecutionPolicy Bypass -File scripts\start.ps1 -SkipInstall

# 指定 IDE
powershell -ExecutionPolicy Bypass -File scripts\start.ps1 -Ide codex
```

macOS/Linux：`bash scripts/start.sh`

## 第 0 步：环境检查

向导会在开始前自动检查本机环境；也可单独运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-environment.ps1 -Quiet
```

| 结果 | 行为 |
|------|------|
| Python 3.10+ 已安装 | 无输出，继续配置 |
| 未安装 Python | 显示安装说明，退出；装好 Python 后重新运行 `onboard.ps1` |

导出 Word 还需 `pip install -r requirements.txt`；连接广告 MCP 还需 Node.js / pipx（见 `docs/SETUP.md`），这些**不阻断**首次问卷。

## 新问卷结构（v1.2）

| 题 | 内容 |
|----|------|
| 1 | 平台（多选） |
| 2 | **一次性 / 定时** ← 决定后面是否问报告时间 |
| 3 | 投递方式 |
| 4–6 | 报告时间、工作日、自动运行（**仅定时**） |
| 7 | **桌面 marketing-analytics-agent 文件夹**（可自定义） |
| 8–9 | 货币、飞书 |

### 一次性（2A）

自动跳过 4–6 题，并继续追问数据范围：

- 先问：**单天** 还是 **多天**
- 若选多天：问“哪几天”，默认 **前 3 天**
- 若选单天：问“哪一天”，默认 **昨天**

### 定时（2B）

继续问每天几点生成、是否仅工作日、是否配置计划任务自动运行。

### 目录（第 7 题）

- 默认在**桌面**创建 `marketing-analytics-agent`
- 若该文件夹**已有历史数据**，会询问是否**继续使用**；选「否」则填写新路径
- 其内仍按原规范分子目录：`temp/`、`reports/`、`output/documents/` 等

```powershell
powershell -ExecutionPolicy Bypass -File scripts\onboard.ps1
python scripts/parse_onboarding_answers.py --interactive
```

示例：`1AB 2A 3A 7A 8A 9A`（全选推荐项 A；Z 等同 A）
