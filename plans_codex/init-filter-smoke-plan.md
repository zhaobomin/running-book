# 初始化改进计划：init-filter-smoke（2026-03-02）

范围：已读取 `docs/` 全部 Markdown；`contents/` 目录未发现（需确认）
目标：仅做“初始化治理 + 计划”，不重写整本书。

## Top 15 问题清单（按严重程度）

1. `contents/` 目录缺失，关键输入不完整（阻断项）  
   - 位置：仓库根目录（预期 `contents/`）

2. 章节内存在整块重复（高严重）  
   - 位置：`docs/nutrition/16-recovery-sleep.md:484`（第二套“七、常见问题”重复出现）

3. 章节内存在整段重复（高严重）  
   - 位置：`docs/technique/06-cadence.md:604`（步频训练进阶计划重复）

4. 医疗内容未全书统一固定免责声明（高严重）  
   - 位置示例：`docs/training/01-beginner.md:279`（有就医条目但无统一固定句）

5. 医疗/伤病章节虽有触发条件，但口径分散（高严重）  
   - 位置示例：`docs/injury/11-common-injuries.md:310`、`docs/injury/12-prevention.md:453`、`docs/injury/13-knee-protection.md:279`

6. 量化断言未配套来源（高严重）  
   - 位置示例：`docs/training/01-beginner.md:112`（3.5% vs 10.2%）、`docs/injury/12-prevention.md:422`（30-50%）

7. “研究表明”类措辞未统一做证据落地（高严重）  
   - 位置示例：`docs/training/02-5k-10k.md:9`、`docs/training/03-half-marathon.md:131`、`docs/training/04-full-marathon.md:157`

8. 时间敏感信息未标注“截至日期”（中高）  
   - 位置：`docs/advanced/21-apps-tools.md:158`（品牌对比、设备推荐）

9. 术语口径跨章有差异且未标注条件（中高）  
   - 位置示例：`docs/training/01-beginner.md:165` vs `docs/technique/05-posture.md:60`（步频建议范围差异）

10. 标题编号不连续（中）  
   - 位置：`docs/strength/10-warmup-stretch.md:326`（“第八部分”前缺“第七部分”）

11. 编辑痕迹进入正文（中）  
   - 位置：`docs/advanced/17-speed.md:677`、`docs/injury/12-prevention.md:471`（“本次修改摘要”）

12. 高强度训练建议存在绝对化措辞（中）  
   - 位置示例：`docs/advanced/17-speed.md:3`（“必须练速度”）

13. 比赛/资格规则有时效风险（中）  
   - 位置：`docs/training/04-full-marathon.md:54`（BQ 资格信息未加时间戳）

14. 气象章节存在硬阈值，证据链不统一（中）  
   - 位置：`docs/advanced/20-weather.md:296`（AQI 分级建议）

15. 章节体量过大，自动化改写风险高（中）  
   - 位置：`docs/technique/06-cadence.md`、`docs/nutrition/16-recovery-sleep.md`

## 未来 7 天改进路线图（每天最多改 2-3 章）

### Day 1
- 章节：`docs/technique/06-cadence.md`、`docs/nutrition/16-recovery-sleep.md`
- 任务：去重、修复编号、收敛 FAQ，补统一免责声明与就医触发段。

### Day 2
- 章节：`docs/injury/11-common-injuries.md`、`docs/injury/12-prevention.md`、`docs/injury/13-knee-protection.md`
- 任务：统一红旗信号、停训/就医阈值模板，未证据化内容标“需确认”。

### Day 3
- 章节：`docs/training/01-beginner.md`、`docs/training/02-5k-10k.md`
- 任务：量化断言补来源或标“需确认”，统一核心术语定义。

### Day 4
- 章节：`docs/training/03-half-marathon.md`、`docs/training/04-full-marathon.md`
- 任务：补“前置条件 + 回退规则 + 就医触发”，处理时效信息标注。

### Day 5
- 章节：`docs/nutrition/14-diet.md`、`docs/nutrition/15-fueling.md`
- 任务：统一 `g/kg`、补水口径；补特殊人群边界（需确认项单列）。

### Day 6
- 章节：`docs/advanced/17-speed.md`、`docs/advanced/18-heart-rate.md`、`docs/advanced/19-race-strategy.md`
- 任务：降绝对化措辞，补适用/禁忌人群与降负荷流程。

### Day 7
- 章节：`docs/advanced/20-weather.md`、`docs/advanced/21-apps-tools.md`
- 任务：动态信息加“截至日期，需复核”，修复链接和引用一致性。

## 每天验收标准（可检查）

### Day 1 验收
- `docs/technique/06-cadence.md` 不再出现重复“步频训练进阶计划”主标题。
- `docs/nutrition/16-recovery-sleep.md` 仅保留一组“七、常见问题”。

### Day 2 验收
- 三章均出现统一“非医疗建议”固定句。
- 三章均出现统一“何时就医（红旗）”小节。

### Day 3 验收
- 两章中出现“研究表明/数据显示/%”的段落均有来源或“需确认”标签。
- 术语“轻松跑/节奏跑/间歇跑”定义不冲突。

### Day 4 验收
- 半马/全马两章均包含“回退规则”清单。
- BQ/赛事规则段均带日期标注或“需确认”。

### Day 5 验收
- 营养单位统一为 `g/kg`，液体统一 `ml`。
- 肠胃敏感/慢病场景出现替代方案或“需确认”。

### Day 6 验收
- 三章均新增“不适合人群”或“谨慎人群”提醒。
- “必须/绝对/唯一”词频下降并仅保留安全禁令场景。

### Day 7 验收
- 工具推荐出现“截至 YYYY-MM-DD，需复核”。
- 气象阈值段补来源或“需确认”。

## 风险与不确定性清单（需作者确认）

1. `contents/` 是否存在未提交原稿或参考资料？
2. 本书是否覆盖慢病/中老年人群，还是仅健康成人？
3. 引用标准是科普级还是出版审校级（需精确文献）？
4. APP/设备推荐是否保留品牌导向，还是改为原则优先？
5. 是否要求默认中国大陆语境（单位、赛事、平台）？
6. 固定免责声明是否需要法务版模板？
7. 后续每日自动优化优先级：先去重合规，还是先内容增强？
