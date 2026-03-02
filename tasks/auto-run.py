#!/usr/bin/env python3
"""
自动任务执行脚本
1. 通过 claude -p 生成任务列表
2. 格式化并存储任务
3. 循环执行任务，直到没有新任务
"""

import json
import subprocess
import re
import os
from datetime import datetime

TASKS_FILE = "tasks/tasks.json"
LOG_FILE = "tasks/execution.log"

os.makedirs("tasks", exist_ok=True)

def log(message):
    """记录日志"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(log_line + "\n")

def load_tasks():
    """加载任务列表"""
    if os.path.exists(TASKS_FILE):
        with open(TASKS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def save_tasks(tasks):
    """保存任务列表"""
    with open(TASKS_FILE, "w", encoding="utf-8") as f:
        json.dump(tasks, f, ensure_ascii=False, indent=2)

def extract_tasks(text):
    """从文本中提取任务"""
    tasks = []
    
    # 更灵活的任务提取模式
    patterns = [
        r'^\s*[-*]\s+(.+)$',               # - 或 * 开头
        r'^\s*\d+[.)]\s+(.+)$',              # 数字编号
        r'^\s*\[ \]\s+(.+)$',               # [ ] 待办
        r'^\s*任务\s*\d*[:：]?\s*(.+)$',       # 任务：开头
        r'^\s*子任务\s*[:：]?\s*(.+)$',      # 子任务：开头
    ]
    
    # 提取包含任务的区块
    lines = text.split('\n')
    in_task_section = False
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # 检测任务区块开始
        if any(keyword in line for keyword in ['任务', '子任务', '待办', 'TODO']):
            in_task_section = True
        
        # 尝试匹配任务格式
        for pattern in patterns:
            match = re.match(pattern, line)
            if match:
                task = match.group(1).strip()
                if task and not task.startswith('#') and not task.startswith('//'):
                    tasks.append(task)
                break
    
    # 如果没有提取到任务，尝试提取所有以连字符或星号开头的行
    if not tasks:
        for line in lines:
            line = line.strip()
            if line.startswith('- ') or line.startswith('* '):
                task = line[2:].strip()
                if task and not task.startswith('#'):
                    tasks.append(task)
    
    return tasks

def run_claude(prompt):
    """执行 claude 命令"""
    try:
        system_prompt = """你是一个任务执行助手。在完成任务后，如果还有后续工作需要完成，请以列表形式输出子任务。

子任务格式要求：
- 使用 - 或 * 开头
- 每个子任务占一行
- 简洁明确，便于后续执行

示例：
- 完成训练计划章节的编写
- 添加跑步技术章节内容
- 审核并优化现有内容

请先完成当前任务，然后根据需要输出子任务列表。

"""
        
        full_prompt = system_prompt + prompt
        cmd = ["claude", "-p", "--dangerously-skip-permissions", full_prompt]
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        return result.stdout + result.stderr
    except Exception as e:
        log(f"执行 claude 命令出错: {e}")
        return ""

def git_pull_and_handle_conflicts():
    """执行 git pull 并处理冲突"""
    try:
        log("执行: git pull")
        result = subprocess.run(["git", "pull"], capture_output=True, text=True)
        
        if result.returncode != 0:
            log("Git pull 失败，检查是否有冲突...")
            
            # 检查是否有冲突
            status_result = subprocess.run(["git", "status"], capture_output=True, text=True)
            if "conflict" in status_result.stdout.lower():
                log("发现冲突，尝试自动解决...")
                
                # 尝试使用 theirs 策略解决冲突
                try:
                    log("执行: git checkout --theirs .")
                    subprocess.run(["git", "checkout", "--theirs", "."], check=True)
                    log("冲突已自动解决（使用远程版本）")
                except Exception as e:
                    log(f"自动解决冲突失败: {e}")
                    log("调用 Claude 解决冲突...")
                    
                    # 调用 Claude 解决冲突
                    conflict_files = subprocess.run(["git", "diff", "--name-only", "--diff-filter=U"], 
                                                 capture_output=True, text=True).stdout.strip()
                    
                    if conflict_files:
                        prompt = f"""我在运行 git pull 时遇到了冲突，请帮我解决。\n\n冲突文件：\n{conflict_files}\n\n请提供解决冲突的步骤。"""
                        
                        # 调用 Claude
                        try:
                            cmd = ["claude", "-p", "--dangerously-skip-permissions", prompt]
                            result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
                            log("Claude 提供的冲突解决建议:")
                            log(result.stdout)
                        except Exception as e:
                            log(f"调用 Claude 失败: {e}")
            else:
                log(f"Git pull 失败，原因: {result.stderr}")
        else:
            log("Git pull 成功")
    except Exception as e:
        log(f"Git pull 操作异常: {e}")

def git_commit_and_push(task):
    """执行 git 操作：add, commit, push"""
    try:
        log("检查 git 变更...")
        
        # 检查是否有变更
        result = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
        if not result.stdout.strip():
            log("没有文件变更，跳过 git 提交")
            return
        
        # git add .
        log("执行: git add .")
        subprocess.run(["git", "add", "."], check=True)
        
        # git commit
        commit_msg = f"update: {task[:50]}..." if len(task) > 50 else f"update: {task}"
        log(f"执行: git commit -m \"{commit_msg}\"")
        subprocess.run(["git", "commit", "-m", commit_msg], check=True)
        
        # git push
        log("执行: git push")
        subprocess.run(["git", "push"], check=True)
        
        log("Git 操作完成")
    except subprocess.CalledProcessError as e:
        log(f"Git 操作出错: {e}")
    except Exception as e:
        log(f"Git 操作异常: {e}")

def main():
    """主循环"""
    log("开始执行任务循环")
    
    tasks = load_tasks()
    
    while True:
        if not tasks:
            log("任务列表为空，生成新任务...")
            
            # 提供具体的任务生成提示
            prompt = "请为跑步指南书籍生成优化任务，包括但不限于：\n1. 内容审核与优化\n2. 格式规范检查\n3. 内容扩展与补充\n4. 数据和研究引用\n5. 语言表达优化\n6. 新内容添加\n\n请以列表形式输出具体任务。"
            log("执行: claude -p --dangerously-skip-permissions \"生成跑步指南优化任务\"")
            output = run_claude(prompt)
            
            new_tasks = extract_tasks(output)
            
            if new_tasks:
                log(f"提取到 {len(new_tasks)} 个新任务")
                tasks = new_tasks + tasks
                save_tasks(tasks)
            else:
                log("未提取到新任务，结束循环")
                break
        
        if not tasks:
            log("没有更多任务，结束循环")
            break
        
        task = tasks.pop(0)
        save_tasks(tasks)
        
        # 执行 git pull 并处理冲突
        git_pull_and_handle_conflicts()
        
        log(f"执行任务: {task}")
        log(f"执行: claude -p --dangerously-skip-permissions \"{task}\"")
        output = run_claude(task)
        
        new_tasks = extract_tasks(output)
        
        if new_tasks:
            log(f"提取到 {len(new_tasks)} 个新任务，插入到任务列表头部")
            tasks = new_tasks + tasks
            save_tasks(tasks)
        
        git_commit_and_push(task)
        log(f"任务完成，剩余任务数: {len(tasks)}")
    
    log("所有任务执行完成")

if __name__ == "__main__":
    main()
