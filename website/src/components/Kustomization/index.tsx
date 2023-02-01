import React, {type ReactNode} from 'react';
import CodeBlock from '@theme/CodeBlock';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

import styles from './styles.module.css';

interface Props {
  children: ReactNode;
  kustomize: string;
  complete: string,
  path: string,
  resource: string,
  diff: string,
}

export default function Kustomization({
  children,
  kustomize,
  complete,
  path,
  resource,
  diff,
}: Props): JSX.Element {

  let kustomizeDecoded = atob(kustomize)
  let completeDecoded = atob(complete)
  let diffDecoded = atob(diff)

  let diffWorking = diffDecoded.split('\n');
  diffWorking.splice(0, 5)

  diffWorking = diffWorking.map(function (element) { 
    if(element.startsWith("@@")) {
      return "[...]"
    }

    return element;
  })

  const diffTrimmed = diffWorking.join('\n')

  return (
    <Tabs>
    <TabItem value="kustomize" label="Kustomize Patch" default>
      <CodeBlock
        title={path}
        language="yaml">
        {kustomizeDecoded}
      </CodeBlock>
    </TabItem>
    <TabItem value="complete" label={resource}>
      <CodeBlock
        language="yaml">
        {completeDecoded}
      </CodeBlock>
    </TabItem>
    <TabItem value="diff" label="Diff">
      <CodeBlock
        language="diff">
        {diffTrimmed}
      </CodeBlock>
    </TabItem>
  </Tabs>
  );
}
