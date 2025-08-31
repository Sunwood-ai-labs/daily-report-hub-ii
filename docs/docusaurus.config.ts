import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Daily Report Hub',
  tagline: 'AI駆動の開発活動分析プラットフォーム',
  favicon: 'img/favicon-Pteranodon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://sunwood-ai-labs.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/daily-report-hub/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'sunwood-ai-labs', // Usually your GitHub org/user name.
  projectName: 'daily-report-hub', // Usually your repo name.
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  // Mermaid設定を追加
  markdown: {
    mermaid: true,
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/sunwood-ai-labs/daily-report-hub/tree/main/',
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/sunwood-ai-labs/daily-report-hub/tree/main/',
          // Useful options to enforce blogging best practices
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'warn',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  // Mermaidテーマを追加
  themes: ['@docusaurus/theme-mermaid'],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/Pteranodon-social-card.jpg',
    navbar: {
      title: 'Daily Report Hub',
      logo: {
        alt: 'Daily Report Hub Logo',
        // src: 'img/logo.svg',
        src: 'img/Pteranodon.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'ドキュメント',
        },
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'アクティビティ',
        },
        {to: '/blog', label: 'ブログ', position: 'left'},
        {
          href: 'https://github.com/sunwood-ai-labs/daily-report-hub',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/intro',
            },
            {
              label: 'Activities',
              to: '/docs/activities',
            },
          ],
        },
        {
          title: 'Features',
          items: [
            {
              label: 'Auto Report Generation',
              to: '/docs/intro',
            },
            {
              label: 'AI Analytics (Coming Soon)',
              to: '/docs/intro',
            },
            {
              label: 'Multi-Repository Support',
              to: '/docs/intro',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'Blog',
              to: '/blog',
            },
            {
              label: 'GitHub',
              href: 'https://github.com/sunwood-ai-labs/daily-report-hub',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Daily Report Hub. Built with Docusaurus & Enhanced by AI.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['diff'],
    },
    // Mermaidテーマ設定（オプション）
    mermaid: {
      theme: {light: 'neutral', dark: 'forest'},
      options: {
        maxTextSize: 90000, // テキストサイズ制限を大幅に増加
        maxEdges: 2000,     // エッジ数制限も増加（必要に応じて）
        maxWidth: 1000,     // 図の最大幅を設定
        maxHeight: 1000,    // 図の最大高さを設定
      },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;