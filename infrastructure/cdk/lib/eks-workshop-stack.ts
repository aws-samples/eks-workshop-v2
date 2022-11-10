import * as cdk from 'aws-cdk-lib';
import { aws_iam as iam, aws_s3 as s3, CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
import * as events from 'aws-cdk-lib/aws-events';
import { LambdaFunction as LambdaTarget } from 'aws-cdk-lib/aws-events-targets';
import { ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';
import * as yaml from 'yaml';
// This function is based on the cfnresponse JS module that is published
// by CloudFormation. It's an async function that makes coding much easier.
const respondFunction = `
const respond = async function(event, context, responseStatus, responseData, physicalResourceId, noEcho) {
  return new Promise((resolve, reject) => {
    var responseBody = JSON.stringify({
        Status: responseStatus,
        Reason: "See the details in CloudWatch Log Stream: " + context.logGroupName + " " + context.logStreamName,
        PhysicalResourceId: physicalResourceId || context.logStreamName,
        StackId: event.StackId,
        RequestId: event.RequestId,
        LogicalResourceId: event.LogicalResourceId,
        NoEcho: noEcho || false,
        Data: responseData
    });

    console.log("Response body:\\n", responseBody);

    var https = require("https");
    var url = require("url");

    var parsedUrl = url.parse(event.ResponseURL);
    var options = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: parsedUrl.path,
        method: "PUT",
        headers: {
            "content-type": "",
            "content-length": responseBody.length
        }
    };

    var request = https.request(options, function(response) {
        console.log("Status code: " + response.statusCode);
        console.log("Status message: " + response.statusMessage);
        resolve();
    });

    request.on("error", function(error) {
        console.log("respond(..) failed executing https.request(..): " + error);
        resolve();
    });

    request.write(responseBody);
    request.end();
  });
};
`;

export interface EksWorkshopStackProps extends StackProps {
  sourceZipFile: string
  sourceZipFileChecksum: string
}

export class EksWorkshopStack extends Stack {
  constructor(scope: Construct, id: string, props: EksWorkshopStackProps) {
    super(scope, id, props);

    const clusterId = new cdk.CfnParameter(this, 'ClusterId', {
      default: 'default',
      type: 'String'
    });

    const assetBucketName = new cdk.CfnParameter(this, 'AssetBucketName', {
      default: 'BucketNameNotSet',
      type: 'String'
    });

    const assetPrefix = new cdk.CfnParameter(this, 'AssetBucketPrefix', {
      default: 'KeyPrefixNotSet',
      type: 'String'
    });

    const cloud9AdditionalRoleArn = new cdk.CfnParameter(this, 'Cloud9AdditionalRoleArn', {
      default: '',
      type: 'String'
    });

    const sourceZipFile = new cdk.CfnParameter(this, 'SourceZipFile', {
      default: props.sourceZipFile,
      type: 'String'
    });

    const sourceZipFileChecksum = new cdk.CfnParameter(this, 'SourceZipFileChecksum', {
      default: props.sourceZipFileChecksum,
      type: 'String'
    });

    const codeBuildRole = new iam.Role(this, 'CodeBuildRole', { assumedBy: new ServicePrincipal('codebuild.amazonaws.com') });
    // TODO: Develop this into fine-grained policy and replace the managed admin policy.
    codeBuildRole.addManagedPolicy(iam.ManagedPolicy.fromManagedPolicyArn(this, 'AdminManagedIAMPolicy', 'arn:aws:iam::aws:policy/AdministratorAccess'));
    new CfnOutput(this, 'CodeBuildRoleArn', { value: codeBuildRole.roleArn });

    const assetBucket = s3.Bucket.fromBucketName(this, 'SourceBucket', assetBucketName.valueAsString);
    assetBucket.grantRead(codeBuildRole);
    
    const tfStateBackendBucket = new s3.Bucket(this, 'TFStateBackendBucket', {
      versioned: true,
    });
    tfStateBackendBucket.grantReadWrite(codeBuildRole);

    const codebuildProject = new codebuild.Project(this, 'StackDeployProject', {
      role: codeBuildRole,
      environment: {
        buildImage: codebuild.LinuxBuildImage.STANDARD_6_0,
        computeType: codebuild.ComputeType.MEDIUM,
      },
      buildSpec: codebuild.BuildSpec.fromObjectToYaml(buildSpecYaml),
      environmentVariables: {
        'TF_STATE_S3_BUCKET': { value: tfStateBackendBucket.bucketName },
        'CLUSTER_ID': { value: clusterId.valueAsString },
        'C9_ADDITIONAL_ROLE': { value: cloud9AdditionalRoleArn.valueAsString },
        'REPOSITORY_ARCHIVE_LOCATION': { value: `s3://${assetBucketName.valueAsString}/${assetPrefix.valueAsString}${sourceZipFile.valueAsString}` }
      },
      timeout: cdk.Duration.minutes(90),
    });

    const startBuildFunction = new lambda.Function(this, 'StartBuildFunction', {
      code: lambda.Code.fromInline(respondFunction + `
const AWS = require('aws-sdk');

exports.handler = async function (event, context) {
  console.log(JSON.stringify(event, null, 4));
  try {
    const projectName = event.ResourceProperties.ProjectName;
    const codebuild = new AWS.CodeBuild();

    console.log(\`Starting new build of project \${projectName}\`);

    const { build } = await codebuild.startBuild({
      projectName,
      // Pass CFN related parameters through the build for extraction by the
      // completion handler.
      //buildspecOverride: event.RequestType === 'Delete' ? 'infrastructure/buildspec-destroy.yml' : 'infrastructure/buildspec.yml',
      environmentVariablesOverride: [
        {
          name: 'CFN_RESPONSE_URL',
          value: event.ResponseURL
        },
        {
          name: 'CFN_STACK_ID',
          value: event.StackId
        },
        {
          name: 'CFN_REQUEST_ID',
          value: event.RequestId
        },
        {
          name: 'CFN_LOGICAL_RESOURCE_ID',
          value: event.LogicalResourceId
        },
        {
          name: 'REQUESTED_ACTION',
          value: event.RequestType
        }
      ]
    }).promise();
    console.log(\`Build id \${build.id} started - resource completion handled by EventBridge\`);
  } catch(error) {
    console.error(error);
    await respond(event, context, 'FAILED', { Error: error });
  }
};
      `),
      handler: 'index.handler',
      runtime: lambda.Runtime.NODEJS_14_X,
      timeout: cdk.Duration.minutes(1)
    });
    startBuildFunction.addToRolePolicy(new iam.PolicyStatement({
      actions: ['codebuild:StartBuild'],
      resources: [codebuildProject.projectArn]
    }));


    const reportBuildFunction = new lambda.Function(this, 'ReportBuildFunction', {
      code: lambda.Code.fromInline(respondFunction + `
const AWS = require('aws-sdk');

exports.handler = async function (event, context) {
  console.log(JSON.stringify(event, null, 4));

  const projectName = event['detail']['project-name'];

  const codebuild = new AWS.CodeBuild();

  const buildId = event['detail']['build-id'];
  const { builds } = await codebuild.batchGetBuilds({
    ids: [ buildId ]
  }).promise();

  console.log(JSON.stringify(builds, null, 4));

  const build = builds[0];
  // Fetch the CFN resource and response parameters from the build environment.
  const environment = {};
  build.environment.environmentVariables.forEach(e => environment[e.name] = e.value);

  const response = {
    ResponseURL: environment.CFN_RESPONSE_URL,
    StackId: environment.CFN_STACK_ID,
    LogicalResourceId: environment.CFN_LOGICAL_RESOURCE_ID,
    RequestId: environment.CFN_REQUEST_ID
  };

  if (event['detail']['build-status'] === 'SUCCEEDED') {
    await respond(response, context, 'SUCCESS', {}, 'build');
  } else {
    await respond(response, context, 'FAILED', { Error: 'Build failed' });
  }
};
      `),
      handler: 'index.handler',
      runtime: lambda.Runtime.NODEJS_14_X,
      timeout: cdk.Duration.minutes(1)
    });
    reportBuildFunction.addToRolePolicy(new iam.PolicyStatement({
      actions: [
        'codebuild:BatchGetBuilds',
        'codebuild:ListBuildsForProject'
      ],
      resources: [codebuildProject.projectArn]
    }));

    // Trigger the CloudFormation notification function upon build completion.
    const buildCompleteRule = new events.Rule(this, 'BuildCompleteRule', {
      description: 'Build complete',
      eventPattern: {
        source: ['aws.codebuild'],
        detailType: ['CodeBuild Build State Change'],
        detail: {
          'build-status': ['SUCCEEDED', 'FAILED', 'STOPPED'],
          'project-name': [codebuildProject.projectName]
        }
      },
      targets: [
        new LambdaTarget(reportBuildFunction)
      ]
    });

    // Kick off the build (CDK deployment).
    const clusterStack = new cdk.CustomResource(this, 'ClusterStack', {
      serviceToken: startBuildFunction.functionArn,
      properties: {
        ProjectName: codebuildProject.projectName,
        BuildRoleArn: codeBuildRole.roleArn,
        // This isn't actually used by the custom resource. We use a change in
        // the checksum as a way to signal to CloudFormation that the input has
        // changed and therefore the stack should be redeployed.
        ZipFileChecksum: sourceZipFileChecksum.valueAsString,
      }
    });
    clusterStack.node.addDependency(buildCompleteRule, reportBuildFunction);
    
    new CfnOutput(this, 'TFStateBucketArn', { value: tfStateBackendBucket.bucketArn });
  }
}

const buildSpecYaml = yaml.parse(`
version: 0.2

env:
  shell: bash
  variables:
    TF_STATE_S3_BUCKET: NOT_SET
    CLUSTER_ID: NOT_SET
    C9_ADDITIONAL_ROLE: ''
    REPOSITORY_ARCHIVE_LOCATION: NOT_SET
    REQUESTED_ACTION: 'Create'

phases:
  install:
    on-failure: ABORT
    runtime-versions:
      nodejs: 16
    commands:
      - echo "===================================================\${TF_STATE_S3_BUCKET}==================================================="
      - sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl unzip
      - curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      - sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      - sudo apt-get update && sudo apt-get install terraform=1.2.2
      
  pre_build:
    on-failure: ABORT
    commands:
      - aws s3 cp $REPOSITORY_ARCHIVE_LOCATION /tmp/repository.zip
      - unzip -o -q /tmp/repository.zip -d $CODEBUILD_SRC_DIR
      - cd $CODEBUILD_SRC_DIR/infrastructure/terraform
      - terraform init --backend-config="bucket=\${TF_STATE_S3_BUCKET}" --backend-config="key=terraform.tfstate" --backend-config="region=\${AWS_REGION}"
  build:
    on-failure: ABORT
    commands:
      - |
        set -e
        
        cd $CODEBUILD_SRC_DIR/infrastructure/terraform

        export TF_VAR_cluster_id="\${CLUSTER_ID}"

        if [[ $REQUESTED_ACTION == 'Delete' ]]; then
          terraform state rm module.core.module.ide[0].aws_cloud9_environment_membership.user[0] || true
          
          terraform destroy -target=module.core.module.cluster.module.eks-blueprints-kubernetes-addons --auto-approve
          terraform destroy -target=module.core.module.cluster.module.eks-blueprints-kubernetes-csi-addon --auto-approve
          terraform destroy -target=module.core.module.cluster.module.descheduler --auto-approve

          terraform destroy -target=module.core.module.cluster.module.eks-blueprints --auto-approve

          terraform destroy --auto-approve
        else
          terraform apply -auto-approve -var "repository_archive_location=\${REPOSITORY_ARCHIVE_LOCATION}" -var "cloud9_additional_role=\${C9_ADDITIONAL_ROLE}"
        fi
`)