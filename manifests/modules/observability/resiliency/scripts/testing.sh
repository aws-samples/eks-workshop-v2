ZONE_EXP_ID=$(aws fis create-experiment-template \
  --cli-input-json '{
    "description": "publicdocument-azfailure",
    "targets": {},
    "actions": {
      "azfailure": {
        "actionId": "aws:ssm:start-automation-execution",
        "parameters": {
          "documentArn": "arn:aws:ssm:us-west-2::document/AWSResilienceHub-SimulateAzOutageInAsgTest_2020-07-23",
          "documentParameters": "{
            \"AutoScalingGroupName\":\"'$ASG_NAME'\",
            \"CanaryAlarmName\":\"eks-workshop-canary-alarm\",
            \"AutomationAssumeRole\":\"'$FIS_ROLE_ARN'\",
            \"IsRollback\":\"false\",
            \"TestDurationInMinutes\":\"2\"
          }",
          "maxDuration": "PT6M"
        }
      }
    },
    "stopConditions": [
      {
        "source": "none"
      }
    ],
    "roleArn": "'$FIS_ROLE_ARN'",
    "tags": {
      "ExperimentSuffix": "'$RANDOM_SUFFIX'"
    }
  }' \
  --output json | jq -r '.experimentTemplate.id')