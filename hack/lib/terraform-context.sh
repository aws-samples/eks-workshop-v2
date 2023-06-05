terraform_dir="$SCRIPT_DIR/../$terraform_context"

export ASSUME_ROLE=$(terraform -chdir=$terraform_dir output -raw iam_role_arn)

terraform -chdir=$terraform_dir output -raw environment_variables > ${TEMP:-/tmp}/eks-workshop-shell-env
