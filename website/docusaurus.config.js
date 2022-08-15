// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

var path = require('path');

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');
const remarkCodeTerminal = require('./src/remark/code-terminal');
const remarkIncludeCode = require('./src/remark/include-code');
const remarkIncludeKustomization = require('./src/remark/include-kustomization');

const manifestsDir = `${path.dirname(require.resolve('./package.json'))}/../environment/workspace/modules`

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'EKS Workshop',
  tagline: 'Practical exercises to learn about Amazon Elastic Kubernetes Service',
  url: 'https://eksworkshop-v2-next.netlify.app',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.png',

  organizationName: 'aws-samples',
  projectName: 'eks-workshop-v2',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          remarkPlugins: [
            remarkCodeTerminal, 
          ],
          beforeDefaultRemarkPlugins: [
            [remarkIncludeCode, {manifestsDir}],
            [remarkIncludeKustomization, {manifestsDir}]
          ],
          editUrl:
            'https://github.com/aws-samples/eks-workshop-v2/main/website',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'EKS Workshop',
        logo: {
          alt: 'Amazon Web Services',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'doc',
            docId: 'introduction/index',
            position: 'left',
            label: 'Introduction',
          },
          {
            type: 'doc',
            docId: 'exposing/index',
            position: 'left',
            label: 'Exposing applications',
          },
          {
            type: 'doc',
            docId: 'security/index',
            position: 'left',
            label: 'Security',
          },
          {
            type: 'doc',
            docId: 'networking/index',
            position: 'left',
            label: 'Networking',
          },
          {
            type: 'doc',
            docId: 'storage/index',
            position: 'left',
            label: 'Stateful services',
          },
          {
            type: 'doc',
            docId: 'autoscaling/index',
            position: 'left',
            label: 'Autoscaling',
          },
          {
            type: 'doc',
            docId: 'observability/index',
            position: 'left',
            label: 'Observability',
          },
          {
            href: 'https://github.com/aws-samples/eks-workshop-v2',
            position: 'right',
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
          }
        ],
      },
      tableOfContents: {
        minHeadingLevel: 4,
        maxHeadingLevel: 5,
      },
      docs: {
        sidebar: {
          autoCollapseCategories: true,
        },
      },
      footer: {
        links: [
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub',
                href: 'https://twitter.com/docusaurus',
              },
            ],
          },
          {
            title: 'Other',
            items: [
              {
                label: 'Site Terms',
                href: 'https://aws.amazon.com/terms/?nc1=f_pr',
              },
              {
                label: 'Privacy',
                href: 'https://aws.amazon.com/privacy/?nc1=f_pr',
              },
            ],
          },
        ],
        copyright: `© ${new Date().getFullYear()}, Amazon Web Services, Inc. or its affiliates. All rights reserved.`,
      },
      prism: {
        theme: lightCodeTheme,
        magicComments: [
          // Remember to extend the default highlight class name as well!
          {
            className: 'theme-code-block-highlighted-line',
            line: 'highlight-next-line',
            block: {start: 'highlight-start', end: 'highlight-end'},
          },
          {
            className: 'code-block-highlight',
            line: 'HIGHLIGHT',
          },
        ],
      },
    }),
};

module.exports = config;
