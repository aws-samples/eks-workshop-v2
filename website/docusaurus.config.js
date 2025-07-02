// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

import * as path from "path";
import { themes as prismThemes } from "prism-react-renderer";

import remarkCodeTerminal from "./src/remark/code-terminal.js";
import remarkTime from "./src/remark/time.js";
import remarkIncludeCode from "./src/remark/include-code.js";
import remarkIncludeKustomization from "./src/remark/include-kustomization.js";
import remarkParameters from "./src/remark/parameters.js";
import remarkIncludeYaml from "./src/remark/include-yaml.js";

//require("dotenv").config({ path: ".kustomize-env" });

const rootDir = path.dirname(require.resolve("./package.json"));
const manifestsDir = `${rootDir}/..`;
const kustomizationsDir = `${manifestsDir}/manifests`;

const manifestsRef = process.env.MANIFESTS_REF || "main";
const manifestsOwner = process.env.MANIFESTS_OWNER || "aws-samples";
const manifestsRepository =
  process.env.MANIFESTS_REPOSITORY || "eks-workshop-v2";

const labTimesEnabled = process.env.LAB_TIMES_ENABLED || false;

const baseUrl = process.env.BASE_URL || "";

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "EKS Workshop",
  tagline:
    "Practical exercises to learn about Amazon Elastic Kubernetes Service",
  url: "https://www.eksworkshop.com",
  baseUrl: `/${baseUrl}`,
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/favicon.png",
  noIndex: process.env.ENABLE_INDEX !== "1",
  customFields: {
    showNotification: process.env.SHOW_NOTIFICATION === "1",
  },

  organizationName: "aws-samples",
  projectName: "eks-workshop-v2",

  plugins: [
    "docusaurus-plugin-sass",
    [
      "docusaurus-lunr-search",
      {
        disableVersioning: true,
      },
    ],
  ],

  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve("./sidebars.js"),
          remarkPlugins: [remarkCodeTerminal],
          beforeDefaultRemarkPlugins: [
            [remarkTime, { enabled: labTimesEnabled, factor: 1.25 }],
            [
              remarkParameters,
              {
                replacements: {
                  MANIFESTS_REF: manifestsRef,
                  MANIFESTS_OWNER: manifestsOwner,
                  MANIFESTS_REPOSITORY: manifestsRepository,
                  KUBERNETES_VERSION: "1.31",
                  KUBERNETES_NODE_VERSION: "1.31-eks-036c24b",
                },
              },
            ],
            [remarkIncludeYaml, { manifestsDir }],
            [remarkIncludeCode, { manifestsDir }],
            [remarkIncludeKustomization, { manifestsDir: kustomizationsDir }],
          ],
          editUrl:
            "https://github.com/aws-samples/eks-workshop-v2/tree/main/website",
          exclude: [
            "security/guardduty/runtime-monitoring/reverse-shell.md"
          ],
        },
        theme: {
          customCss: require.resolve("./src/css/custom.scss"),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      colorMode: {
        defaultMode: "light",
        disableSwitch: false,
      },
      metadata: [
        {
          name: "google-site-verification",
          content: "aRMa1ddI7Lc-CtAWPgifuH7AhmyC1CVAEpg2d9jyTpQ",
        },
      ],
      image: "img/meta.jpg",
      navbar: {
        title: "EKS Workshop",
        logo: {
          alt: "Amazon Web Services",
          src: "img/logo.svg",
        },
        items: [
          {
            type: "doc",
            docId: "introduction/index",
            position: "left",
            label: "Intro",
          },
          {
            type: "doc",
            docId: "fundamentals/index",
            position: "left",
            label: "Fundamentals",
          },
          {
            type: "doc",
            docId: "autoscaling/index",
            position: "left",
            label: "Autoscaling",
          },
          {
            type: "doc",
            docId: "observability/index",
            position: "left",
            label: "Observability",
          },
          {
            type: "doc",
            docId: "security/index",
            position: "left",
            label: "Security",
          },
          {
            type: "doc",
            docId: "networking/index",
            position: "left",
            label: "Networking",
          },
          {
            type: "doc",
            docId: "automation/index",
            position: "left",
            label: "Automation",
          },
          {
            type: "doc",
            docId: "aiml/index",
            position: "left",
            label: "AI/ML",
          },
          {
            type: "doc",
            docId: "troubleshooting/index",
            position: "left",
            label: "Troubleshooting",
          },
          {
            href: "https://github.com/aws-samples/eks-workshop-v2",
            position: "right",
            className: "header-github-link",
            "aria-label": "GitHub repository",
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
            title: "Community",
            items: [
              {
                label: "GitHub",
                href: "https://github.com/aws-samples/eks-workshop-v2",
              },
            ],
          },
          {
            title: "Other",
            items: [
              {
                label: "Site Terms",
                href: "https://aws.amazon.com/terms/?nc1=f_pr",
              },
              {
                label: "Privacy",
                href: "https://aws.amazon.com/privacy/?nc1=f_pr",
              },
            ],
          },
        ],
        copyright: `© ${new Date().getFullYear()}, Amazon Web Services, Inc. or its affiliates. All rights reserved.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ["diff"],
        magicComments: [
          // Remember to extend the default highlight class name as well!
          {
            className: "theme-code-block-highlighted-line",
            line: "highlight-next-line",
            block: { start: "highlight-start", end: "highlight-end" },
          },
          {
            className: "code-block-highlighted-line-even",
            block: {
              start: "annotated-highlight-start-even",
              end: "annotated-highlight-end-even",
            },
          },
          {
            className: "code-block-highlighted-line-odd",
            block: {
              start: "annotated-highlight-start-odd",
              end: "annotated-highlight-end-odd",
            },
          },
          {
            className: "code-block-highlight",
            line: "HIGHLIGHT",
          },
          {
            className: "code-block-annotation",
            line: "highlight-annotation",
          },
        ],
      },
    }),
};

export default config;
