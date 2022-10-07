import * as cdk from 'aws-cdk-lib';
import { aws_iam as iam, aws_s3 as s3, CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
import * as events from 'aws-cdk-lib/aws-events';
import { LambdaFunction as LambdaTarget } from 'aws-cdk-lib/aws-events-targets';
import { ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';
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

export interface EventEngineStackProps extends StackProps {
  sourceZipFile: string
  sourceZipFileChecksum: string
}

export class EventEngineStack extends Stack {
  constructor(scope: Construct, id: string, props: EventEngineStackProps) {
    super(scope, id, props);

    // These parameters are supplied by Event Engine. We'll
    // take advantage of them to locate the Zip file containing this
    // source code.
    const assetBucketName = new cdk.CfnParameter(this, 'EEAssetsBucket', {
      default: 'BucketNameNotSet',
      type: 'String'
    });

    const assetPrefix = new cdk.CfnParameter(this, 'EEAssetsKeyPrefix', {
      default: 'KeyPrefixNotSet',
      type: 'String'
    });

    const teamRoleArn = new cdk.CfnParameter(this, 'EETeamRoleArn', {
      default: 'RoleArnNotSet',
      type: 'String'
    });

    // We supply the value of this parameter ourselves via the ZIPFILE
    // environment variable. It will be automatically rendered into the
    // generated YAML template.
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

    const resourceName = 'Admin';
    const codebuildProject = new codebuild.Project(this, 'StackDeployProject', {
      role: codeBuildRole,
      environment: {
        buildImage: codebuild.LinuxBuildImage.STANDARD_6_0,
        computeType: codebuild.ComputeType.MEDIUM,
      },
      source: codebuild.Source.s3({
        bucket: assetBucket,
        path: props.sourceZipFile,
      }),
      environmentVariables: {
        'TF_STATE_S3_BUCKET': { value: tfStateBackendBucket.bucketName },
        'C9_OWNER_ROLE': { value: `arn:aws:sts::${this.account}:assumed-role/${resourceName}/umishaq-Isengard` }
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
      buildspecOverride: event.RequestType === 'Delete' ? 'buildspec-destroy.yml' : 'buildspec.yml',
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
          name: 'CLOUD9_ENVIRONMENT_ID',
          value: event.ResourceProperties.Cloud9EnvironmentId
        },
        {
          name: 'BUILD_ROLE_ARN',
          value: event.ResourceProperties.BuildRoleArn
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
        Cloud9EnvironmentId: 'workspace.environmentId',
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
