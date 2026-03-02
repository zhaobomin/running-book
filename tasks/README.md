# 跑步指南 - 持续优化系统

> 自动化任务执行系统，持续优化书籍内容

## 📁 文件结构

```
tasks/
├── auto-run.py           # 自动任务执行脚本（核心）
├── auto-run.sh           # Bash 版本
├── generate-tasks.py     # 任务生成器
├── schedule.sh           # 调度脚本
├── tasks.json            # 当前任务列表
├── command.md            # 命令参考
├── execution.log         # 执行日志
└── generator.log         # 生成器日志
```

## 🚀 快速开始

### 方式一：一次性执行

```bash
# 1. 生成优化任务
python3 tasks/generate-tasks.py

# 2. 执行任务
python3 tasks/auto-run.py
```

### 方式二：一键执行（推荐）

```bash
# 生成任务 + 执行任务
./tasks/schedule.sh
```

### 方式三：自定义任务

```bash
# 编辑 tasks/tasks.json，写入你的任务
echo '["优化 docs/guide/index.md"]' > tasks/tasks.json

# 执行任务
python3 tasks/auto-run.py
```

## 🔄 工作原理

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 任务生成 (generate-tasks.py)                             │
│    - 分析项目内容                                           │
│    - 识别需要优化的部分                                     │
│    - 生成结构化任务                                         │
│    ↓                                                         │
│ 2. 任务执行 (auto-run.py)                                   │
│    - 读取 tasks.json 中的任务                                │
│    - 调用 Claude 执行任务                                    │
│    - 提取 Claude 返回的子任务                                │
│    - 子任务插入头部优先执行                                   │
│    ↓                                                         │
│ 3. Git 自动提交                                             │
│    - 检查文件变更                                           │
│    - git add .                                              │
│    - git commit -m "update: 任务内容"                       │
│    - git push                                               │
│    ↓                                                         │
│ 4. 循环执行                                                 │
│    - 直到没有新任务                                         │
└─────────────────────────────────────────────────────────────┘
```

## 📋 任务类型

### 1. 内容审核 (Content Audit)
- 审核章节内容完整性
- 识别需要扩展的章节
- 检查内容质量

### 2. 格式规范 (Format Standardization)
- 统一标题层级
- 统一列表格式
- 统一表格格式

### 3. 内容扩展 (Content Expansion)
- 添加 FAQ 常见问题
- 添加训练日志模板
- 添加自查清单
- 添加案例故事

### 4. 链接检查 (Link Check)
- 检查内部链接
- 修复无效链接
- 添加导航链接

### 5. 质量提升 (Quality Improvement)
- 添加数据引用
- 优化语言表达
- 添加图示描述

### 6. 新内容 (New Content)
- 添加新章节
- 添加新话题
- 扩展现有内容

## 📅 定期执行

### 手动执行

```bash
# 每周执行一次
./tasks/schedule.sh
```

### 自动执行（使用 cron）

```bash
# 编辑 crontab
crontab -e

# 添加每周一早上 9 点执行
0 9 * * 1 cd /Users/zhaobomin/Documents/projects/running-book && ./tasks/schedule.sh
```

### 自动执行（使用 launchd，macOS 推荐）

创建 `~/Library/LaunchAgents/com.runningbook.scheduler.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.runningbook.scheduler</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/zhaobomin/Documents/projects/running-book/tasks/schedule.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>1</integer>
    </dict>
    <key>WorkingDirectory</key>
    <string>/Users/zhaobomin/Documents/projects/running-book</string>
</dict>
</plist>
</plist>
```

加载服务：

```bash
launchctl load ~/Library/LaunchAgents/com.runningbook.scheduler.plist
```

## 📊 查看日志

```bash
# 查看执行日志
cat tasks/execution.log

# 查看生成器日志
cat tasks/generator.log

# 查看调度日志
cat tasks/scheduler.log

# 实时查看日志
tail -f tasks/execution.log
```

## 🛠️ 自定义任务

### 编辑 tasks.json

```json
[
  "优化 docs/training/01-beginner.md，添加 FAQ 部分",
  "为 docs/technique/05-posture.md 添加跑姿自查清单",
  "审核所有章节的格式一致性"
]
```

### 运行任务

```bash
python3 tasks/auto-run.py
```

## ⚙️ 配置说明

### Python 版本 (auto-run.py)

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `TASKS_FILE` | 任务文件路径 | `tasks/tasks.json` |
| `LOG_FILE` | 日志文件路径 | `tasks/execution.log` |

### Bash 版本 (auto-run.sh)

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `TASKS_FILE` | 任务文件路径 | `tasks/tasks.json` |
| `LOG_FILE` | 日志文件路径 | `tasks/execution.log` |

## 🎯 最佳实践

1. **定期执行**：建议每周执行一次，保持内容持续优化
2. **审查日志**：定期查看执行日志，了解优化进度
3. **手动干预**：遇到问题时，可以手动编辑 tasks.json 调整任务
4. **版本控制**：所有变更都会自动提交到 Git，便于回滚
5. **渐进优化**：不要一次性完成所有优化，分阶段进行

## 🔧 故障排查

### 问题：任务没有被执行

**解决方案**：
1. 检查 `tasks/tasks.json` 是否存在且有内容
2. 检查 `claude` 命令是否可用
3. 查看日志文件了解详细错误

### 问题：Git 提交失败

**解决方案**：
1. 检查 Git 是否已配置
2. 检查是否有 push 权限
3. 检查是否有未解决的冲突

### 问题：子任务没有被提取

**解决方案**：
1. 检查 Claude 的输出格式
2. 调整 `extract_tasks` 函数的正则表达式
3. 在 System Prompt 中明确要求列表格式

## 📈 持续改进建议

1. **添加更多任务类型**：根据项目需求扩展任务生成器
2. **优化任务提取**：改进 `extract_tasks` 函数，支持更多格式
3. **添加任务优先级**：在 tasks.json 中支持优先级字段
4. **添加任务依赖**：支持任务间的依赖关系
5. **添加进度追踪**：记录每个任务的执行状态

## 📞 支持

如有问题，请查看：
- 执行日志：`tasks/execution.log`
- 生成器日志：`tasks/generator.log`
- 调度日志：`tasks/scheduler.log`

---

*最后更新：2026-03-02*
