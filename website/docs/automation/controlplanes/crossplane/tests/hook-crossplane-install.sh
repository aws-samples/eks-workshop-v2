before() {

set -x
aws iam detach-role-policy  --role-name crossplane-provider-aws --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" || true
aws iam delete-role --role-name crossplane-provider-aws || true

}

after() {
 echo "noop"
}

"$@"
