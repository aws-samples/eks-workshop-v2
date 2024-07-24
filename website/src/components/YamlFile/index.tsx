import React, { Component, type ReactNode } from "react";
import CodeBlock from "@theme/CodeBlock";

import styles from "./styles.module.css";

export function YamlAnnotation({ children, sequence }) {
  return (
    <div className={styles.annotationContainer}>
      <div>
        <div className={styles.annotationSequence}>
          {String.fromCharCode(64 + parseInt(sequence))}
        </div>
      </div>

      <div className={styles.annotationChildren}>{children}</div>
    </div>
  );
}

interface Props {
  children: ReactNode;
  title: string;
  zoomed: string;
}

export default function YamlFile({ children, title, zoomed }: Props) {
  const zoomedVal = zoomed === "true";
  const realTitle = zoomedVal ? undefined : title;
  return (
    <div className={styles.yamlBlock}>
      <CodeBlock language="yaml" title={realTitle} showLineNumbers={!zoomedVal}>
        {children}
      </CodeBlock>
    </div>
  );
}
