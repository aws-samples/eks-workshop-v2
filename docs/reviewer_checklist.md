# EKS Workshop - Reviewer Checklist

This is the reviewer checklist for pull requests, over time as many of these checks as possible will be automated.

## Pull Request hygiene

- [ ] Pull request has an appropriate title (see [releases](./releases.md))
- [ ] Pull request has an appropriate `content` label, otherwise use `content/other`
- [ ] Pull request has been assigned to the correct GitHub Milestone
- [ ] All review checks are passing

## Style

See style guide for expanded explanations.

- [ ] `prepare-environment` command has been used correctly, changes to the cluster outlined are accurate
- [ ] Verified `bash` blocks are formatted correctly, for example using `$`
- [ ] All `kubectl` commands use `~/environment` paths where appropriate
- [ ] `kubectl wait` or alternatives have been used where appropriate
- [ ] There are no explicit references to pods with generated names like `kubectl get pod-abnasd`
- [ ] Any references to external manifests are pinned to a version
- [ ] `$EKS_CLUSTER_NAME` is used instead of hard-coded cluster names, including referencing other infrastructure that may use the cluster name
- [ ] Avoided use of interactive `kubectl exec` or multiple terminal windows (or tests skipped)

## AWS infrastructure

- [ ] All Terraform resources created have names that prefixed with the EKS cluster name (`var.addon_context.eks_cluster_id`)

## Tests

- [ ] `bash` blocks that run commands that are intended to error use `expectError=true`
- [ ] The suite hook is present to run `prepare-environment` after the lab

## Lab cleanup

- [ ] Resources created in the content are conditionally cleaned up

## Misc

- [ ] Generated lab timing has been created (new lab) or updated (updated lab) if needed
- [ ] Relevant updates have been made to the [lab IAM policy](../lab/iam-policy-labs.json)
- [ ] Images should be in `webp` format
