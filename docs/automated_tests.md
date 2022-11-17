# EKS Workshop - Automated End-to-End Tests

Automated end-to-end tests are used to ensure the stability of the workshop content over time, and are integrated in to the Pull Request process to allow validation of PRs before they are merged. This document outlines how to use automated tests in various scenarios.

## Running tests

This section documents running the tests locally as well as via PRs.

### Locally

You should run the tests locally before raising a PR, this can be done with some convenience scripts.

To use this utility you must:
- Have some AWS credentials available in your current shell session (ie. you `aws` CLI must work)

First, ensure you have the workshop infrastructure running in your AWS account:

```
make create-infrastructure
```

Then run `make test` specifying the top-level module that you wish to test. This limits the tests to the a specific directory relative to `website/docs`. For example to test only the content for the autoscaling module located at `website/docs/autoscaling' the command would be:

```
➜  eks-workshop-v2 git:(main) ✗ make test module="autoscaling"
bash hack/run-tests.sh
Generating temporary AWS credentials...
Building container images...
sha256:62fb5cc6e348d854a59a5e00429554eab770adc24150753df2e810355e678899
sha256:a6b3c8675c79804587b5e4d5b8dfc5cfd6d01b40c89ee181ad662902e0cb650d
Running test suite...
Added new context arn:aws:eks:us-west-2:111111111:cluster/eksw-env-cluster-eks to /root/.kube/config
✔ Generating test cases
✔ Building Mocha suites

Executing tests...


EKS Workshop
    Autoscaling
      - Autoscaling
      Workloads
        - Workloads
        Horizontal Pod Autoscaler
          - Horizontal Pod Autoscaler
          ✔ Configure HPA
          ✔ Generate load
        Cluster Proportional Autoscaler
          - Cluster Proportional Autoscaler
          ✔ Installing CPA
          ✔ Autoscaling CoreDNS
      Compute
        - Compute
        Cluster Autoscaler (CA)
          ✔ Cluster Autoscaler (CA)
          ✔ Enable CA
          ✔ Scale with CA
          ✔ Clean Up
        Karpenter
          ✔ Karpenter
          ✔ Set up the Provisioner
          ✔ Automatic Node Provisioning
          ✔ Remove Provisioner
        Cluster Over-Provisioning
          ✔ Cluster Over-Provisioning
          ✔ Introduction
          ✔ Setting up Over-Provisioning
          ✔ Scale a workload


  13 passing (2m)
  8 pending

success
```

When you start testing your content you should likely test your module in isolation but prior to raising a PR you should check that the top-level module your content is a part of runs in its entirety.

For example if you are working on content at `website/docs/autoscaling/compute/karpenter` you should start by testing like so:

```
make test module="autoscaling/compute/karpenter"
```

But prior to raising a PR should verify the autoscaling module in its entirety:

```
make test module="autoscaling/compute/karpenter"
```

You can pass extra flag to the test framework by using environment variable `AWS_EKS_WORKSHOP_TEST_FLAGS`

```
AWS_EKS_WORKSHOP_TEST_FLAGS="--debug" make test module="gitops"
```

Finally, once you are done if needed you can destroy the infrastructure:

```
make destroy-infrastructure
```

### Pull Requests

**Note:** This section is for repository maintainers

By default the end-to-end tests will not run against a PR because:
- The PR should be reviewed first
- Tests take time to execute so only selective modules should be run

The first thing to do is to assess which top-level modules should be tested, which are the directories contained in `website/docs` (`observability`, `autoscaling` etc). Each of the top level modules has a corresponding label which can be applied to PRs, for example if you want to test the Security module there is a label `content/security`, Observability has the label `content/observability` and so on.

If you do not apply any content labels then only the Introduction and Cleanup modules will be run, which can be useful for just testing Terraform changes. Note: The Introduction and Cleanup modules will **always** be run.

Once you have added the required `content/*` labels to the PR then apply the label `automation/e2e-tests`. This label is what triggers the tests to run against the PR, and it will detect all of the content labels previously added to determine what tests to run.

The test suite will generally take **at least** 30 minutes to complete but will generally be more.

As long as the `automation/e2e-tests` label is applied the test suite will re-run any time there is a push to the branch associated with the PR. Removing the label will stop this behavior.

## Writing tests

The automated tests primarily work by extracting all of the `bash` code snippets out of the Markdown files and executing them in order. It is aware of `weight` and `sidebar_position` so does not need any further help to figure this out. This means that by adhering to the recommendations in the style guide your commands will have tests generated for them without any further action from you.

Any commands that return an error code will be marked as a failed unit test case.

Note: The framework will only extract commands from `bash` sections that are prefixed with `$ `, see the [style guide](./style_guide.md) section on 'Command blocks' for more information.

Take the following Markdown example:

````
# Some example

This is some example content to demonstrate testing.

```bash
$ ls -la
Some example output
```
````

In this case the test framework will pull out and run `ls -la`, ignoring `Some example output`.

### Hooks

The test framework introduces the concept of 'hooks', which are used to decorate test cases with additional logic or assertions that should not be shown to the end-user of the content. Most coding unit test frameworks have similar concepts, for example [hooks in Mocha](https://mochajs.org/#hooks).

This is especially important when operating with an asynchronous system such as Kubernetes, where running `kubectl apply [...]` can often involve waiting several minutes for something to happen after the command returns success. For example creating a `Service` of type `LoadBalancer`.

Hooks are introduced to a `bash` snippet using the optional `hook` annotation, which uses a convention to pick up bash script from a directory relative to the Markdown file.

For example take this case where the Markdown is in `my-content.md`:

````
# Some example hook

This is some example content to demonstrate testing with hooks.

Lets tell the user to create a file with `touch`:

```bash hook=example
$ touch /tmp/my-file
Some example output
```
````

The directory structure might look like this:

```
--- website
    `-- docs
        `-- my-modules
            |-- tests
            |   |-- hook-example.sh
            `-- my-content.md
```

The framework will automatically look in the `tests` directory for a file called `hook-${hook-name}.sh`, and will execute it before and after the `bash` snippet. The only argument passed is `before` or `after` to provide context which it is getting called.

Here is an example implementation of a hook file `hook-example.sh` that checks `/tmp/my-file` doesn't exist when the test starts and was created after the `bash` snippet in the Markdown is completed.

```
set -Eeuo pipefail

before() {
  if [[ -f /tmp/my-file ]]; then
    # Try to provide an error message where possible to help understanding failure
    echo 'Error: Expected file to not be present'
    # Exit with a non-zero code for failure
    exit 1
  fi

  # Otherwise let the hook exit naturally
}

after() {
  if [[ ! -f /tmp/my-file ]]; then
    echo 'Error: Expected file does not exist'
    exit 1
  fi
}

"$@"
```

### Other annotations

The framework includes support for a number of annotations that can be added to the `code` fence blocks in Markdown to customize the behavior for certain shell code snippets.

For example, if there are `bash` segments you do not want to run you can indicate they should be skipped:

````
```bash test=false
$ echo "This won't get run"
```
````

For cases where theres a concerned a script might run for too long or not finish, you can specify a timeout in seconds (default is 60 seconds):

````
```bash timeout=120
$ echo "This test case will fail"
$ sleep 150
```
````

Here is a complete list of the available annotations:

| Annotation  | Description  | Default |
|-------------|--------------|---------|
| test        | This script block should be executed as a test                                                                                                                                        | true    |
| timeout     | Time limit in seconds before the script block will be marked as failed                                                                                                                | 120     |
| hook        | Name of the hook to execute for this script section                                                                                                                                   |         |
| hookTimeout | Time limit in seconds for the hooks to complete before the script block will be marked as failed                                                                                      | 300     |
| expectError | Ignore any errors that occur when the script block is executed                                                                                                                        | false   |


### What if my module can't be tested?

This is not something we generally want to accept in to the workshop content as any manual testing represents significant toil in terms of maintenance when it comes to content changes and other events like upgrading EKS versions. PRs raised that do not have adequate considerations for testing will generally not be accepted.

However, in some cases it is necessary to prevent a module or chapter from being tested. In that case you can place a file called `.notest` in the directory which should be excluded. This will cause the framework to ignore that directry and any sub-directories automatically.
