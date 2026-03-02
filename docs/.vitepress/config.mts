import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "跑步指南",
  description: "一本关于跑步的线上书籍",
  lang: 'zh-CN',
  themeConfig: {
    nav: [
      { text: '首页', link: '/' },
      { text: '指南', link: '/guide/' }
    ],
    sidebar: [
      {
        text: '开始',
        items: [
          { text: '简介', link: '/guide/' },
          { text: '快速开始', link: '/guide/getting-started' }
        ]
      }
    ],
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
    }
  }
})
