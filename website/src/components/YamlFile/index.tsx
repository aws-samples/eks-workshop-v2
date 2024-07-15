import React, { Component, type ReactNode } from "react";
import CodeBlock from "@theme/CodeBlock";

import styles from "./styles.module.css";

export function YamlAnnotation({ children, sequence }) {
  console.log(sequence);
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

export default function YamlFile({ children, title }) {
  return (
    <div className={styles.yamlBlock}>
      <CodeBlock language="yaml" title={title} showLineNumbers>
        {children}
      </CodeBlock>
    </div>
  );
}
