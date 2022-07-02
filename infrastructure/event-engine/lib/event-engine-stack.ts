import { aws_iam as iam, aws_s3 as s3, CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import { ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

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

    const assetBucket = s3.Bucket.fromBucketName(this, 'SourceBucket', assetBucketName.valueAsString);

    const codeBuildRole = new iam.Role(this, 'CodeBuildRole', { assumedBy: new ServicePrincipal('codebuild.amazonaws.com') });
    // TODO: Develop this into fine-grained policy and replace the managed poweruser policy.
    // const codeBuildPolicy = new iam.Policy(this, 'CodeBuildPolicy', {
    //   statements: [
    //     new iam.PolicyStatement({
    //       actions: ['*'],
    //       resources: ['*']
    //     })
    //   ]
    // });
    codeBuildRole.addManagedPolicy(iam.ManagedPolicy.fromManagedPolicyName(this, 'PowerUserManagedIAMPolicy', 'PowerUserAccess'));
    new CfnOutput(this, 'CodeBuildRoleArn', { value: codeBuildRole.roleArn });
    
    const tfStateBackendBucket = new s3.Bucket(this, 'TFStateBackendBucket', {
      versioned: true,
    });
    tfStateBackendBucket.grantReadWrite(codeBuildRole); 
    
    new CfnOutput(this, 'TFStateBucketArn', { value: tfStateBackendBucket.bucketArn});
  }
}
