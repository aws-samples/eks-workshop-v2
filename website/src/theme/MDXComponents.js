import React from "react";
// Import the original mapper
import MDXComponents from "@theme-original/MDXComponents";
import Terminal from "@site/src/components/Terminal";
import BrowserWindow from "@site/src/components/BrowserWindow";
import Kustomization from "@site/src/components/Kustomization";
import LaunchButton from "@site/src/components/LaunchButton";
import ReactPlayer from "react-player";

export default {
  // Re-use the default mapping
  ...MDXComponents,

  Terminal: Terminal,
  Browser: BrowserWindow,
  Kustomization: Kustomization,
  LaunchButton: LaunchButton,
  ReactPlayer: ReactPlayer,
};
