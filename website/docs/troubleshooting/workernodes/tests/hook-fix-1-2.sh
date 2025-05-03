set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 5

  output_message=$(aws kms get-key-policy --key-id ${NEW_KMS_KEY_ID} | jq -r '.Policy | fromjson')

  if [[ $output_message == *"kms:*"* ]]; then
    # Found "kms:*" in the policy - this is what we want, so exit successfully
    echo "Success: Found policy with 'kms:*' as expected"    
    exit 0
  fi  

  # If we get here, it means we didn't find "kms:*" when we should have
  >&2 echo "KMS policy does not contain 'kms:*' when it should"
  exit 1
}

"$@"
