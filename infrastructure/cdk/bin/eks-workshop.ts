#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { DefaultStackSynthesizer } from 'aws-cdk-lib';
import 'source-map-support/register';
import { EksWorkshopStack } from '../lib/eks-workshop-stack';

const app = new cdk.App();
new EksWorkshopStack(app, 'EksWorkshopStack', {
  /* Uncomment the next line to specialize this stack for the AWS Account
   * and Region that are implied by the current CLI configuration. */
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION,
  },
  synthesizer: new DefaultStackSynthesizer({
    generateBootstrapVersionRule: false
  }),
  sourceZipFile: process.env.ZIPFILE || 'eks-workshop-tf-stack.zip',
  sourceZipFileChecksum: process.env.ZIPFILE_CHECKSUM || '',
});
