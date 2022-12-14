from __future__ import print_function
import boto3
import logging
import time

logger = logging.getLogger(__name__)

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    ssm = boto3.client('ssm')

    instance_id = event['instance_id']

    iam_instance_profile = {
        'Arn': event['instance_profile_arn'],
        'Name': event['instance_profile_name']
    }

    response = ec2.describe_iam_instance_profile_associations(
        Filters=[
            {
                'Name': 'instance-id',
                'Values': [instance_id],
            },
        ],
    )

    if len(response['IamInstanceProfileAssociations']) > 0:
      for association in response['IamInstanceProfileAssociations']:
        if association['State'] == 'associated':
          print("{} is active with state {}".format(association['AssociationId'], association['State']))
          ec2.replace_iam_instance_profile_association(AssociationId=association['AssociationId'], IamInstanceProfile=iam_instance_profile)
    else:
      ec2.associate_iam_instance_profile(IamInstanceProfile=iam_instance_profile, InstanceId=instance_id)

    instance = ec2.describe_instances(Filters=[{'Name': 'instance-id', 'Values': [instance_id]}])['Reservations'][0]['Instances'][0]

    block_volume_id = instance['BlockDeviceMappings'][0]['Ebs']['VolumeId']

    block_device = ec2.describe_volumes(VolumeIds=[block_volume_id])['Volumes'][0]

    if block_device['Size'] != int(event['disk_size']):
      ec2.modify_volume(VolumeId=block_volume_id,Size=int(event['disk_size']))

    # Wait some time for IAM profile to apply
    time.sleep(10)

    for i in range(1, 30):
        response = ssm.describe_instance_information(Filters=[{'Key': 'InstanceIds', 'Values': [instance_id]}])
        if len(response["InstanceInformationList"]) > 0 and \
                response["InstanceInformationList"][0]["PingStatus"] == "Online" and \
                response["InstanceInformationList"][0]["InstanceId"] == instance_id:
            break
        time.sleep(10)

    ssm_document = event['ssm_document']

    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName=ssm_document)

    command_id = response['Command']['CommandId']

    waiter = ssm.get_waiter('command_executed')

    waiter.wait(
        CommandId=command_id,
        InstanceId=instance_id,
        WaiterConfig={
            'Delay': 10,
            'MaxAttempts': 30
        }
    )
