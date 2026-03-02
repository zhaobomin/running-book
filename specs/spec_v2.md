# 跑步指南书籍优化规范 v2

## 第一阶段完成情况 ✅

### 已完成任务

1. ✅ `docs/guide/index.md` - 已优化
   - 添加"关于本书"提示框，说明内容来源
   - 添加"详细学习建议"表格，包含阶段、重点内容和时长

2. ✅ `docs/guide/getting-started.md` - 已大幅优化
   - 扩展装备选购指南，添加跑鞋选购误区提示
   - 添加必备配件表格
   - 扩展8周训练计划表格（从3周扩展到8周完整计划）
   - 添加安全提醒章节（跑前检查、跑步中注意、天气应对）
   - 添加常见问题章节（Q&A格式）
   - 添加SMART目标设定原则

3. ✅ `docs/index.md` - 首页配置正常
   - hero配置完整
   - features配置正确，6个功能区块

4. ✅ 格式一致性检查 - 通过
   - 所有章节格式统一
   - 表格结构一致
   - 标题层级正确

5. ✅ 内部链接检查 - 通过
   - 所有相对链接正确
   - 所有章节导航链接正确

---

## 第二阶段完成情况 ✅

### 已完成任务

| 任务 | 状态 | 说明 |
|------|------|------|
| 检查 contents/ 与 docs/ 内容同步 | ✅ 完成 | 创建 `docs/advanced/20-weather.md`，更新 index.md |
| 开发"跑步APP和工具推荐"章节 | ✅ 完成 | 创建 `docs/advanced/21-apps-tools.md` |
| 添加半马全马配速参考表 | ✅ 已有 | 章节中已包含完整配速表 |

### 新增文件

1. `docs/advanced/20-weather.md` - 跑步与天气
   - 高温、低温、雨天、大风、雾霾、高海拔跑步策略
   - 装备清单
   - 安全预警信号

2. `docs/advanced/21-apps-tools.md` - 跑步APP和工具推荐
   - 主流跑步APP对比（Strava、NRC、Keep、悦跑圈等）
   - 运动手表推荐（Garmin、Apple Watch、华为、高驰等）
   - 心率带、耳机、腰包等配件推荐

### 更新文件

1. `docs/advanced/index.md` - 添加新章节链接
2. `docs/advanced/19-race-strategy.md` - 更新导航链接
3. `docs/advanced/20-weather.md` - 更新导航链接

---

## 章节结构（更新后）

```
docs/
├── index.md                    # 首页配置
├── guide/
│   ├── index.md               # 简介 ✅ 已优化
│   └── getting-started.md     # 快速开始 ✅ 已优化
├── training/
│   ├── index.md
│   ├── 01-beginner.md         # 新手入门 ✅ 含配速表
│   ├── 02-5k-10k.md
│   ├── 03-half-marathon.md    # 半马 ✅ 含配速表
│   └── 04-full-marathon.md    # 全马 ✅ 含配速表
├── technique/
│   ├── index.md
│   ├── 05-posture.md
│   ├── 06-cadence.md
│   └── 07-breathing.md
├── strength/
│   ├── index.md
│   ├── 08-core.md
│   ├── 09-lower-body.md
│   └── 10-warmup-stretch.md
├── injury/
│   ├── index.md
│   ├── 11-common-injuries.md
│   ├── 12-prevention.md
│   └── 13-knee-protection.md
├── nutrition/
│   ├── index.md
│   ├── 14-diet.md
│   ├── 15-fueling.md
│   └── 16-recovery-sleep.md
└── advanced/
    ├── index.md               # ✅ 已更新
    ├── 17-speed.md
    ├── 18-heart-rate.md
    ├── 19-race-strategy.md    # ✅ 已更新导航
    ├── 20-weather.md          # ✅ 新增
    └── 21-apps-tools.md       # ✅ 新增
```

---

## 第三阶段：后续优化建议

### 待执行任务列表

#### 1. 交叉引用优化（中优先级）

- [ ] 在各章节末尾添加"相关章节"链接
- [ ] 在训练计划章节添加技术、力量训练的交叉引用
- [ ] 在伤病预防章节添加核心训练的交叉引用

#### 2. 视觉优化（低优先级）

- [ ] 检查所有表格在移动端的显示效果
- [ ] 为关键概念添加图表说明（如心率区间图）
- [ ] 添加训练计划周历模板

#### 3. 内容审核标准（低优先级）

- [ ] 所有训练计划数据来源标注
- [ ] 医学/健康建议添加免责声明
- [ ] 配速/心率数据与权威来源核对

---

## 执行总结

### 第一阶段
- ✅ 审核并优化 `docs/guide/index.md`
- ✅ 大幅扩展 `docs/guide/getting-started.md`
- ✅ 验证首页配置正常
- ✅ 格式一致性检查通过
- ✅ 内部链接检查通过

### 第二阶段
- ✅ 同步 contents/ 与 docs/ 内容（创建天气章节）
- ✅ 开发跑步APP和工具推荐章节
- ✅ 确认配速表已存在

### 当前状态
**书籍共 21 个章节，结构完整，内容充实。**

---

## 更新日志

- 2026-03-02: 完成第一阶段审核与优化
- 2026-03-02: 完成第二阶段内容扩展，新增2个章节