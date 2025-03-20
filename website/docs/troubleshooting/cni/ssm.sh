#!/bin/bash
COMMAND_ID=$(aws ssm send-command \
    --instance-ids $1 \
    --document-name "AWS-RunShellScript" \
    --comment "Demo run shell script on Linux Instances" \
    #--parameters "{\"commands\":[\"sudo -Hiu root bash << END\",\"tail -n $3 /var/log/aws-routed-eni/$2.log | grep $4\", \"END\"]}" \
    --parameters '{"commands":["sudo -Hiu root bash << END","tail -n '$3' /var/log/aws-routed-eni/'$2'.log | grep '$4'", "END"]}' \
    --output text \
    --query "Command.CommandId")

STATUS=InProgress
while [ "$STATUS" == "InProgress" ]; do
    STATUS=$(aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id $1 \
        --output text \
        --query "Status")
done

aws ssm list-command-invocations \
    --command-id "$COMMAND_ID" \
    --details \
    --output text \
    --query "CommandInvocations[].CommandPlugins[].Output"
