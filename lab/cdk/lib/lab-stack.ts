import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { aws_iam as iam, aws_s3 as s3, CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as ssm from 'aws-cdk-lib/aws-ssm'

export class EksWorkshopLabStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const ssmDocument = new ssm.CfnDocument(this, 'BootstrapDocument', {
      documentType: 'Command',
      documentFormat: 'YAML',
      content: 
      content: `schemaVersion: '2.2'
description: Bootstrap Cloud9 Instance
mainSteps:
- action: aws:runShellScript
  name: Cloud9Bootstrap
  inputs:
    runCommand:
    - |
      set -e
      
      STR=$(cat /etc/os-release)
      SUB="VERSION_ID=\"2\""
      
      marker_file="/root/resized.mark"
      
      if [[ ! -f "$marker_file" ]]; then
        if [ $(readlink -f /dev/xvda) = "/dev/xvda" ]
        then
          sudo growpart /dev/xvda 1
          if [[ "$STR" == *"$SUB"* ]]
          then
            sudo xfs_growfs -d /
          else
            sudo resize2fs /dev/xvda1
          fi
        else
          sudo growpart /dev/nvme0n1 1
          if [[ "$STR" == *"$SUB"* ]]
          then
            sudo xfs_growfs -d /
          else
            sudo resize2fs /dev/nvme0n1p1
          fi
        fi
      fi
      
      touch $marker_file
      
      sudo yum install -y git`  
    })

    const bootstrapCloud9Function = new lambda.Function(this, 'BootstrapCloud9Function', {
      code: lambda.Code.fromInline(`
const AWS = require('aws-sdk');

exports.handler = async function (event, context) {
  console.log(JSON.stringify(event, null, 4));
  try {
    
    await respond(response, context, 'SUCCESS', {}, 'build');
  } catch(error) {
    console.error(error);
    await respond(event, context, 'FAILED', { Error: error });
  }
};
      `),
      handler: 'index.handler',
      runtime: lambda.Runtime.PYTHON_3_9,
      timeout: cdk.Duration.minutes(15)
    });
    bootstrapCloud9Function.addToRolePolicy(new iam.PolicyStatement({
      actions: ['ssm:SendCommand'],
      resources: [cdk.Fn.join("",[
        "arn:aws:ssm:",
        cdk.Stack.of(this).region,
        ":",
        cdk.Stack.of(this).account,
        ":document/",
        ssmDocument.ref
      ])]
    }));
  }
}
