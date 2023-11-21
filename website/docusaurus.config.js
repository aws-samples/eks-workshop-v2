// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

var path = require('path');

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');
const remarkCodeTerminal = require('./src/remark/code-terminal');
const remarkTime = require('./src/remark/time');
const remarkIncludeCode = require('./src/remark/include-code');
const remarkIncludeKustomization = require('./src/remark/include-kustomization');
const remarkParameters = require('./src/remark/parameters');

require('dotenv').config({ path: '.kustomize-env' })

const rootDir = path.dirname(require.resolve('./package.json'));
const manifestsDir = `${rootDir}/..`;
const kustomizationsDir = `${manifestsDir}/manifests`

const manifestsRef = process.env.MANIFESTS_REF || 'main'
const manifestsOwner = process.env.MANIFESTS_OWNER || 'aws-samples'
const manifestsRepository = process.env.MANIFESTS_REPOSITORY || 'eks-workshop-v2'

const labTimesEnabled = process.env.LAB_TIMES_ENABLED || false;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'EKS Workshop',
  tagline:
    'Practical exercises to learn about Amazon Elastic Kubernetes Service',
  url: 'https://www.eksworkshop.com',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.png',
  noIndex: process.env.ENABLE_INDEX !== "1",

  organizationName: 'aws-samples',
  projectName: 'eks-workshop-v2',

  plugins: ['docusaurus-plugin-sass'],

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
            [remarkTime, {enabled: labTimesEnabled, factor: 1.25}]
          ],
          beforeDefaultRemarkPlugins: [
            [remarkParameters, {
              replacements: {
                MANIFESTS_REF: manifestsRef,
                MANIFESTS_OWNER: manifestsOwner,
                MANIFESTS_REPOSITORY: manifestsRepository,
                KUBERNETES_VERSION: '1.27',
                KUBERNETES_NODE_VERSION: '1.27.3-eks-48e63af'
              }
            }], 
            [remarkIncludeCode, { manifestsDir }],
            [remarkIncludeKustomization, { manifestsDir: kustomizationsDir }]
          ],
          editUrl: 'https://github.com/aws-samples/eks-workshop-v2/tree/main/website',
          exclude: [
            'security/guardduty/runtime-monitoring/reverse-shell.md'
          ]
        },
        theme: {
          customCss: require.resolve('./src/css/custom.scss'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      announcementBar: {
        id: 'upgrade-1.27',
        content:
          '🚩 EKS Workshop upgraded to EKS 1.27 on 17th November. If you have an existing lab environment please see the <a target="_blank" rel="noopener noreferrer" href="/docs/misc/major-upgrade">major upgrade instructions</a>. 🚩',
        backgroundColor: '#0972d3',
        textColor: '#fff',
      },
      colorMode: {
        defaultMode: 'light',
        disableSwitch: false,
      },
      image: 'img/meta.png',
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
            docId: 'fundamentals/index',
            position: 'left',
            label: 'Fundamentals',
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
            docId: 'automation/index',
            position: 'left',
            label: 'Automation',
          },
          {
            type: 'doc',
            docId: 'aiml/index',
            position: 'left',
            label: 'AIML',
          },
          {
            href: 'https://github.com/aws-samples/eks-workshop-v2',
            position: 'right',
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      tableOfContents: {
        minHeadingLevel: 4,
        maxHeadingLevel: 5,
      },
      docs: {
        sidebar: {
          autoCollapseCategories: false,
        },
      },
      footer: {
        links: [
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/aws-samples/eks-workshop-v2',
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
        darkTheme: darkCodeTheme,
        magicComments: [
          // Remember to extend the default highlight class name as well!
          {
            className: 'theme-code-block-highlighted-line',
            line: 'highlight-next-line',
            block: { start: 'highlight-start', end: 'highlight-end' },
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
