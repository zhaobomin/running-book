import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "跑步指南",
  description: "一本关于跑步的线上书籍",
  lang: 'zh-CN',
  themeConfig: {
    nav: [
      { text: '首页', link: '/' },
      { text: '训练计划', link: '/training/' },
      { text: '跑步技术', link: '/technique/' },
      { text: '力量训练', link: '/strength/' },
      { text: '伤病预防', link: '/injury/' },
      { text: '营养恢复', link: '/nutrition/' },
      { text: '进阶话题', link: '/advanced/' }
    ],
    sidebar: {
      '/training/': [
        {
          text: '训练计划',
          items: [
            { text: '训练指南', link: '/training/' },
            { text: '新手入门训练计划', link: '/training/01-beginner' },
            { text: '5K/10K 训练方案', link: '/training/02-5k-10k' },
            { text: '半马训练指南', link: '/training/03-half-marathon' },
            { text: '全马训练指南', link: '/training/04-full-marathon' }
          ]
        }
      ],
      '/technique/': [
        {
          text: '跑步技术',
          items: [
            { text: '技术指南', link: '/technique/' },
            { text: '正确的跑步姿势', link: '/technique/05-posture' },
            { text: '步频与步幅', link: '/technique/06-cadence' },
            { text: '呼吸技巧', link: '/technique/07-breathing' }
          ]
        }
      ],
      '/strength/': [
        {
          text: '力量训练',
          items: [
            { text: '力量训练指南', link: '/strength/' },
            { text: '跑者核心训练', link: '/strength/08-core' },
            { text: '下肢力量训练', link: '/strength/09-lower-body' },
            { text: '跑前热身与跑后拉伸', link: '/strength/10-warmup-stretch' }
          ]
        }
      ],
      '/injury/': [
        {
          text: '伤病预防',
          items: [
            { text: '伤病预防指南', link: '/injury/' },
            { text: '常见跑步伤病', link: '/injury/11-common-injuries' },
            { text: '伤病预防策略', link: '/injury/12-prevention' },
            { text: '跑者膝盖保护', link: '/injury/13-knee-protection' }
          ]
        }
      ],
      '/nutrition/': [
        {
          text: '营养恢复',
          items: [
            { text: '营养恢复指南', link: '/nutrition/' },
            { text: '跑者饮食指南', link: '/nutrition/14-diet' },
            { text: '长距离补给策略', link: '/nutrition/15-fueling' },
            { text: '恢复与睡眠', link: '/nutrition/16-recovery-sleep' }
          ]
        }
      ],
      '/advanced/': [
        {
          text: '进阶话题',
          items: [
            { text: '进阶话题指南', link: '/advanced/' },
            { text: '速度训练方法', link: '/advanced/17-speed' },
            { text: '心率训练', link: '/advanced/18-heart-rate' },
            { text: '比赛策略', link: '/advanced/19-race-strategy' }
          ]
        }
      ],
      '/': [
        {
          text: '开始',
          items: [
            { text: '简介', link: '/guide/' },
            { text: '快速开始', link: '/guide/getting-started' }
          ]
        }
      ]
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/yourusername/running-book' }
    ],
    footer: {
      message: '基于 VitePress 构建',
      copyright: 'Copyright © 2024-present'
    },
    outline: {
      label: '目录',
      level: [2, 3]
    },
    docFooter: {
      prev: '上一页',
      next: '下一页'
    },
    lastUpdated: {
      text: '最后更新于',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'short'
      }
    },
    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: '搜索文档',
            buttonAriaLabel: '搜索文档'
          },
          modal: {
            noResultsText: '无法找到相关结果',
            resetButtonTitle: '清除查询条件',
            footer: {
              selectText: '选择',
              navigateText: '切换'
            }
          }
        }
      }
    }
  }
})