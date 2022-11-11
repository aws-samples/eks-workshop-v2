before() {

set -x
aws iam delete-role-policy --role-name ack-iam-controller --policy-name ack-iam-recommended-policy || true
aws iam delete-role --role-name ack-iam-controller || true

aws iam detach-role-policy  --role-name ack-mq-controller --policy-arn "arn:aws:iam::aws:policy/AmazonEC2FullAccess" || true
aws iam delete-role --role-name ack-ec2-controller || true

aws iam detach-role-policy  --role-name ack-mq-controller --policy-arn "arn:aws:iam::aws:policy/AmazonRDSFullAccess" || true
aws iam delete-role --role-name ack-rds-controller || true

aws iam detach-role-policy  --role-name ack-mq-controller --policy-arn "arn:aws:iam::aws:policy/AmazonEC2FullAccess" || true
aws iam detach-role-policy  --role-name ack-mq-controller --policy-arn "arn:aws:iam::aws:policy/AmazonMQFullAccess" || true
aws iam delete-role --role-name ack-mq-controller || true

}

after() {
 echo "noop"
}

"$@"
