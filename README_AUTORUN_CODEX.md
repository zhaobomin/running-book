# 自动化写书（本地）
1) 把你的第一版书稿（md/docx/txt/pdf 等）放到 contents/
2) 如果你已有分章 Markdown，可放到 docs/
3) 运行：
   - scripts_codex/init.sh          # 初始化（生成目录/风格/约束/评分与初始改进计划）
   - scripts_codex/daily.sh         # 手动跑一轮每日迭代
   - scripts_codex/install_cron.sh  # 安装每天定时跑
