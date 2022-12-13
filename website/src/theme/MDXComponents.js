import React from 'react';
// Import the original mapper
import MDXComponents from '@theme-original/MDXComponents';
import Terminal from '@site/src/components/Terminal';
import BrowserWindow from '@site/src/components/BrowserWindow'
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
import CodeBlock from '@theme/CodeBlock';
import Kustomization from '@site/src/components/Kustomization';

export default {
  // Re-use the default mapping
  ...MDXComponents,

  terminal: Terminal,
  browser: BrowserWindow,
  kustomization: Kustomization,
};
