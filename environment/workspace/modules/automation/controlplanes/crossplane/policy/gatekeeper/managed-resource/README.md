### Block Managed Resource creation that is not part of a composition

This example Gatekeeper policy denies requests for managed resources if they are not part of a composite resource.

Examples and test cases are available under the `samples` directory. Tests can be ran using the [gator cli](https://open-policy-agent.github.io/gatekeeper/website/docs/gator/).

To run tests for this example run:
```bash
cd environment/workspace/modules/automation/controlplanes/crossplane/policy/gatekeeper/managed-resource
gator verify . -v
```
