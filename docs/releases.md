# EKS Workshop - Releases

The EKS Workshop will publish a new version on the last Friday of each month containing all PRs merged to the `main` branch during that time. This will update the content on https://eksworkshop.com and publish a new version to Workshop Studio for AWS events. The changes for the release each month will be publish as a GitHub Release with a corresponding changelog.

There may be releases published off-schedule for specific events like re:Invent and Kubecon, as well as updates made during the month for critical bug fixes.

Each release will have a corresponding GitHub milestone associated with it to track the changes that will be released during that interval. This allows contributors to understand when their contribution will be published, and users of the workshop to understand what changes will be published ahead of time.

## Milestones

GitHub allows the associating of both issues and pull requests to milestones for tracking. In general the pattern for this repository is:

1. Associate with an issue if it exists while PR is being developed
2. Replacing the issue with the PR in the milestone once created

Currently the release notes generator only recognizes PRs, associated issues with not generate an entry.

PRs should be named like so:

```
<type>: <name>
```

For example:

```
feat: This is my pull request
```

The following types will be recognized by the release notes generator:

| Type   | Release Notes Section | Purpose                                                                                    |
| ------ | --------------------- | ------------------------------------------------------------------------------------------ |
| new    | New labs              | A net-new lab has been added in this PR                                                    |
| update | Updated labs          | The content of an existing lab has changed                                                 |
| fix    | Fixes                 | A simple fix that has not changed the flow/structure of a lab                              |
| feat   | Features              | Adds or updates functionality not related to a specific lab (for example website, testing) |

The generator will also pick up `content/` labels applied to the PRs to categorize PRs according to the top level module that they are related to. For example `content/security` would result in:

```
[Security] This is my pull request @author (#PR ID)
```

This is not relevant to all PRs so only use this capability where it makes sense.

## Triggering a release

Closing a milestone will automatically trigger its corresponding release process through GitHub actions. This will:

1. Generate release notes
2. Create a tag prefixed with `release-`
3. Create a GitHub release referencing (1) and (2)
