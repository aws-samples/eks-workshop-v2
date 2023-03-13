#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { EksWorkshopLabStack } from '../lib/lab-stack';
import { DefaultStackSynthesizer } from 'aws-cdk-lib';

const app = new cdk.App();
new EksWorkshopLabStack(app, 'EksWorkshopLabStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION,
  },
  synthesizer: new DefaultStackSynthesizer({
    generateBootstrapVersionRule: false
  }),
});
