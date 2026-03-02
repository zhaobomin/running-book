#!/usr/bin/env python3
"""
持续优化任务生成器
定期分析项目状态，生成新的优化任务
"""

import json
import os
from datetime import datetime
import glob

TASKS_FILE = "tasks/tasks.json"
DOCS_DIR = "docs"
LOG_FILE = "tasks/generator.log"

def log(message):
    """记录日志"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(log_line + "\n")

def load_tasks():
    """加载当前任务列表"""
    if os.path.exists(TASKS_FILE):
        with open(TASKS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def save_tasks(tasks):
    """保存任务列表"""
    with open(TASKS_FILE, "w", encoding="utf-8") as f:
        json.dump(tasks, f, ensure_ascii=False, indent=2)

def get_all_md_files():
    """获取所有 markdown 文件"""
    md_files = []
    for root, dirs, files in os.walk(DOCS_DIR):
        for file in files:
            if file.endswith('.md'):
                md_files.append(os.path.join(root, file))
    return md_files

def analyze_file_content(filepath):
    """分析文件内容"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        lines = content.split('\n')
        word_count = len(content)
        has_tables = '|' in content
        has_code_blocks = '```' in content
        has_faq = 'FAQ' in content or '常见问题' in content
        has_examples = '示例' in content or '案例' in content
        
        return {
            'lines': len(lines),
            'words': word_count,
            'has_tables': has_tables,
            'has_code_blocks': has_code_blocks,
            'has_faq': has_faq,
            'has_examples': has_examples
        }
    except Exception as e:
        log(f"分析文件 {filepath} 出错: {e}")
        return None

def generate_optimization_tasks():
    """生成优化任务"""
    log("开始分析项目内容...")
    
    md_files = get_all_md_files()
    log(f"找到 {len(md_files)} 个 markdown 文件")
    
    tasks = []
    
    # 1. 内容审核任务
    tasks.append({
        'category': 'content_audit',
        'priority': 'high',
        'description': '审核所有章节内容，识别需要优化的部分',
        'subtasks': [
            '审核核心章节（训练计划、跑步技术）的内容完整性',
            '审核进阶章节（伤病预防、营养恢复）的内容质量',
            '识别内容较简洁、需要扩展的章节',
            '检查是否有重复或矛盾的内容'
        ]
    })
    
    # 2. 格式规范任务
    tasks.append({
        'category': 'format_standardization',
        'priority': 'high',
        'description': '统一所有章节的格式规范',
        'subtasks': [
            '统一标题层级（H1-H4）',
            '统一列表格式（- 或数字）',
            '统一表格格式',
            '检查并统一代码块格式'
        ]
    })
    
    # 3. 内容扩展任务
    tasks.append({
        'category': 'content_expansion',
        'priority': 'medium',
        'description': '为章节添加增强内容',
        'subtasks': [
            '为核心章节添加 FAQ 常见问题部分',
            '为训练计划章节添加训练日志模板',
            '为技术章节添加自查清单',
            '为营养章节添加食谱示例',
            '为伤病预防章节添加自查流程图'
        ]
    })
    
    # 4. 链接检查任务
    tasks.append({
        'category': 'link_check',
        'priority': 'medium',
        'description': '检查并修复所有内部链接',
        'subtasks': [
            '检查所有章节间的导航链接',
            '检查首页和索引页的链接',
            '修复无效链接',
            '为每个章节添加上一篇/下一篇导航'
        ]
    })
    
    # 5. 内容质量提升任务
    tasks.append({
        'category': 'quality_improvement',
        'priority': 'low',
        'description': '持续提升内容质量',
        'subtasks': [
            '添加案例故事，增强可读性',
            '添加数据和研究引用，增强科学性',
            '优化语言表达，提高可读性',
            '添加图片描述或 ASCII 图示'
        ]
    })
    
    # 6. 新内容添加任务
    tasks.append({
        'category': 'new_content',
        'priority': 'low',
        'description': '添加新的有价值内容',
        'subtasks': [
            '添加跑者心理建设章节',
            '添加装备选购指南',
            '添加不同季节的跑步建议',
            '添加跑步与饮食的详细搭配'
        ]
    })
    
    return tasks

def format_tasks_for_claude(tasks):
    """将任务格式化为 Claude 可理解的格式"""
    task_descriptions = []
    
    for i, task in enumerate(tasks, 1):
        priority_emoji = {'high': '🔴', 'medium': '🟡', 'low': '🟢'}
        emoji = priority_emoji.get(task['priority'], '⚪')
        
        desc = f"{emoji} 任务 {i}: {task['description']}\n"
        desc += f"   子任务：\n"
        for subtask in task['subtasks']:
            desc += f"   - {subtask}\n"
        
        task_descriptions.append(desc)
    
    return "\n".join(task_descriptions)

def main():
    """主函数"""
    log("=== 持续优化任务生成器启动 ===")
    
    # 生成优化任务
    tasks = generate_optimization_tasks()
    log(f"生成了 {len(tasks)} 类优化任务")
    
    # 格式化任务
    formatted_tasks = format_tasks_for_claude(tasks)
    
    # 创建主任务
    main_task = f"""持续优化跑步指南书籍 - 第 {datetime.now().strftime('%Y%m%d')} 轮

任务目标：
1. 审核并优化现有内容
2. 添加增强内容（FAQ、模板、示例）
3. 统一格式规范
4. 检查并修复链接

{formatted_tasks}

请按照优先级顺序执行，每完成一个任务后，如果有后续工作，请以列表形式输出子任务。"""
    
    # 保存任务
    save_tasks([main_task])
    log("任务已保存到 tasks/tasks.json")
    
    log("=== 任务生成完成 ===")
    print("\n" + "="*60)
    print("任务已生成！现在可以运行：")
    print("  python3 tasks/auto-run.py")
    print("="*60)

if __name__ == "__main__":
    main()
