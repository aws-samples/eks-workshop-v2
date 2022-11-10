before() {
  
aws iam delete-role-policy --role-name ack-iam-controller --policy-name ack-iam-recommended-policy || true
aws iam delete-role --role-name ack-iam-controller || true
aws iam delete-role --role-name ack-ec2-controller || true
aws iam delete-role --role-name ack-rds-controller || true
aws iam delete-role --role-name ack-mq-controller || true

}

after() {
 echo "noop"
}

"$@"