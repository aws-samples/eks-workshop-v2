import React, {useEffect, useState, type ReactNode} from 'react';
import CodeBlock from '@theme/CodeBlock';
import Details from '@theme/Details'
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

import fs from 'fs';

import styles from './styles.module.css';



interface Props {
  children: ReactNode;
  name: string,
  repository: string;
  chart: string,
  version: string,
  link: string,
  namespace: string,
  values: string,
}

export default function BlueprintsAddon({
  children,
  name,
  repository,
  chart,
  version,
  link,
  namespace,
  values
}: Props): JSX.Element {

  let valuesDecoded = atob(values)

  return (
    <Details summary={<summary>How was <b>{name}</b> installed?</summary>}>
    <div>
    <p>
      The <b>{name}</b> component was pre-installed using an addon for the <a href="https://github.com/aws-ia/terraform-aws-eks-blueprints">EKS Blueprints for Terraform</a>, which you can see <a href={link}>here</a>.
    </p>
    <p>
      The equivalent helm chart installation would look something like this:
    </p>
      <CodeBlock language="bash">
{`$ helm repo add ${name} ${repository}

$ cat <<EOF | helm install ${name} ${chart} --version ${version} --namespace ${namespace} --values -
${valuesDecoded}
EOF`}
    </CodeBlock>
    </div>
    </Details>
  );
}
