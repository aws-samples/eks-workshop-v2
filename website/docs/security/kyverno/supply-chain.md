---
title: "Supply Chain Security(Image Signing & Verification) on Amazon EKS using AWS KMS & CoSign with Kyverno"
sidebar_position: 136
---

Supply chains require more than one linked process, and their security relies on the validation and verification of each process. Preventing supply chain attacks is a rapidly developing field and consensus on “best practices” and security has been lacking. The Cloud Native Computing Foundation [(CNCF) Security Technical Advisory Group (TAG)](https://github.com/cncf/tag-security) has published a new paper, [Software Supply Chain Security Best Practices](https://project.linuxfoundation.org/hubfs/CNCF_SSCP_v1.pdf), designed to provide the cloud native and open source communities with a holistic approach to architect a secure supply chain regardless of whether they are a software producer or consumer.

The approach outlined by the CNCF Security TAG group has four key elements:

1. **Verification** – Establishing and verifying “trust” at every step in the process through a combination of code-signing, metadata, and cryptographic validation.

2. **Automation** – Leveraging automation helps to ensure that processes are deterministic, reinforcing the attestation and verification mechanisms we rely on for supply chain security. Everything that can be automated should be automated and documented.

3. **Authorization** in Controlled Environments – Every step in the software build and supply chain process should be clearly defined with a limited scope. Next, deriving from this design, every operator within the supply chain (human or machine) must have a clearly defined role with minimum permission.

4. **Secure Authentication** – Finally, every entity in our system must engage in “mutual authentication.” This means that no human, software process, or machine should be trusted to be who they say they are. They must demonstrate through a hardened technique (such as multi-factor authentication) that they are in fact who they purport to be.

These principles can be operationalized across first-party source code repositories, third-party dependencies, build pipelines, artifact repositories, and deployments. Each of these stages involves different considerations and requirements, and comes with its own set of best practices.

In this post, using Cosign with AWS KMS we are first going to generate a signed and verified public/private key. Then we will deploy Kyverno ImageVerify policy on an existing Amazon EKS cluster. This policy will check the signature of container images and ensure it’s only allowed to deploy/run containers that have been signed against the provided AWS KMS public key.


## Cosign Overview
___

[Cosign](https://github.com/sigstore/cosign) is a new open source tool to manage the process of signing and verifying container images. It is developed as part of the [sigstore](https://sigstore.dev/) project and aims “to make signatures invisible infrastructure”. With images signed by Cosign, users do not need to change their infrastructure to store the public signing key. With Cosign, the signatures directly appear as tags of the image, linked to the associated image via the digest.

Since Cosign supports using a KMS provider to generate and sign keys, in this blog we will use [AWS KMS.](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)

## Step 1: Generate keys using AWS KMS
___

To generate keys using a KMS provider, use the cosign ```generate-key-pair``` command with the ```--kms``` flag.

```
cosign generate-key-pair --kms awskms:///alias/image-signing-cosign
```

> Above command needs **Administrative access** to create KMS keys in the account. It might also through such as "Error: creating key: retrieving PublicKey from cache: getting public key: operation error KMS: GetPublicKey, https response error StatusCode: 400". We can ignore the same. It takes a little while for KMS to create the Key and setup alias for the same.

We can check our KMS key creation status using the below command:

```
aws kms list-aliases | grep -i image-signing-cosign
```

Sample Output:

```
 "AliasName": "alias/image-signing-cosign",
 "AliasArn": "arn:aws:kms:us-east-1:xxxxxxxxxxxx:alias/image-signing-cosign"
```

The public key can be retrieved later with:

```
cosign public-key --key awskms:///alias/image-signing-cosign
```


```text
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAETW6Ja+nNUCWdvzUulvB81PHUovkb
LoSVgmMqxZeZAcNTrkbEn+vW1oyUJKCMSmp/QwUmB4DazTWxPxRJRaB/4A==
-----END PUBLIC KEY-----
```

## Step 2: Build and Sign a Container Image using Cosign
___

We will use an sample ECR repository named, ```supply-chain-security```. You can create the same using the below command:

```
aws ecr create-repository --repository-name supply-chain-security
```


```json
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:xxxxxxxxxxxx:repository/supply-chain-security",
        "registryId": "xxxxxxxxxxxx",
        "repositoryName": "supply-chain-security",
        "repositoryUri": "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security",
        "createdAt": 1695466162.0,
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```

Use the following steps to authenticate and push an image to your repository.

Retrieve an authentication token and authenticate your Docker client to your registry.

```
aws ecr get-login-password —region us-east-1 | docker login —username AWS —password-stdin <AWS Account ID>.dkr.ecr.us-east-1.amazonaws.com
```

> Replace the Account ID with your own Workshop AWS AccountID. You should get output as ```Login Succeeded```

For this example, we will use an “nginx” image. Tag your image so you can push the image to the repository and then push it, by running the following commands (substituting your AWS Account ID as indicated):

```
docker tag nginx:latest <AWS Account ID>.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security:latest
docker push <AWS Account ID>.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security:latest
```

```
The push refers to repository [xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security]
563c64030925: Pushed 
6fb960878295: Pushed 
e161c3f476b5: Pushed 
8a7e12012e6f: Pushed 
d0a62f56ef41: Pushed 
4713cb24eeff: Pushed 
511780f88f80: Pushed 
latest: digest: sha256:48a84a0728cab8ac558f48796f901f6d31d287101bc8b317683678125e0d2d35 size: 1778
```


After pushing the image to Amazon ECR, sign the image using the public key named “image-signing-cosign” we created in step 1. Run the following cosign command to sign the “supply-chain-security” image and re-upload it to your AWS repository:

```
cosign sign --key awskms:///alias/image-signing-cosign --upload=true <AWS Account ID>.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security:latest
```

It will have a sample output as below. It will ask for confirmation of the correct tag, & confirmation for the operation.

```text
WARNING: Image reference xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security:latest uses a tag, not a digest, to identify the image to sign.
    This can lead you to sign a different image than the intended one. Please use a
    digest (example.com/ubuntu@sha256:abc123...) rather than tag
    (example.com/ubuntu:latest) for the input to cosign. The ability to refer to
    images by tag will be removed in a future release.

WARNING: "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security" appears to be a private repository, please confirm uploading to the transparency log at "https://rekor.sigstore.dev"
Are you sure you would like to continue? [y/N] y

        The sigstore service, hosted by sigstore a Series of LF Projects, LLC, is provided pursuant to the Hosted Project Tools Terms of Use, available at https://lfprojects.org/policies/hosted-project-tools-terms-of-use/.
        Note that if your submission includes personal data associated with this signed artifact, it will be part of an immutable record.
        This may include the email address associated with the account with which you authenticate your contractual Agreement.
        This information will be used for signing this artifact and will be stored in public transparency logs and cannot be removed later, and is subject to the Immutable Record notice at https://lfprojects.org/policies/hosted-project-tools-immutable-records/.

By typing 'y', you attest that (1) you are not submitting the personal data of any other person; and (2) you understand and agree to the statement and the Agreement terms at the URLs listed above.
Are you sure you would like to continue? [y/N] y
tlog entry created with index: 38102819
Pushing signature to: xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security
```

Next, run this command to list your container images and verify your container against the public key:

```
aws ecr list-images --repository-name supply-chain-security
```

Sample Output:

```
{
    "imageIds": [
        {
            "imageDigest": "sha256:8200a9a862156e1fedd2bbcf88245aaee37951bca5bb18620878663e4e7c8878",
            "imageTag": "sha256-48a84a0728cab8ac558f48796f901f6d31d287101bc8b317683678125e0d2d35.sig"
        },
        {
            "imageDigest": "sha256:48a84a0728cab8ac558f48796f901f6d31d287101bc8b317683678125e0d2d35",
            "imageTag": "latest"
        }
    ]
}
```

## Step 3: Apply Image Verification Policy using Kyverno
___

Out of the many available Kyverno rules, we will be using Kyverno “verifyImages”, which performs the following actions:

It validates signatures for matching images using Cosign.
It mutates image references with the digest returned by Cosign.
Using an image digest guarantees immutability of images and hence improves security.

The rule is executed in the mutating admission controller, but runs after resources are mutated to allow policies to mutate image registries and other configurations, before the image signature is verified.

We will Install an image validation policy file named `verify-image.yaml`. Be sure to make sure that you have added the correct public key.

```
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image
  annotations:
    policies.kyverno.io/title: Verify Image
    policies.kyverno.io/category: Software Supply Chain Security, EKS Best Practices
    policies.kyverno.io/severity: medium
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/minversion: 1.7.0
    policies.kyverno.io/description: >-
      Using the Cosign project, OCI images may be signed to ensure supply chain
      security is maintained. Those signatures can be verified before pulling into
      a cluster. This policy checks the signature of an image repo called
      ghcr.io/kyverno/test-verify-image to ensure it has been signed by verifying
      its signature against the provided public key. This policy serves as an illustration for
      how to configure a similar rule and will require replacing with your image(s) and keys.      
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: verify-image
      match:
        any:
        - resources:
            kinds:
              - Pod
      verifyImages:
      - image: "*"
        attestors:
        - entries:
          - keys:
              publicKeys: |
                -----BEGIN PUBLIC KEY-----
                MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAETW6Ja+nNUCWdvzUulvB81PHUovkb
                LoSVgmMqxZeZAcNTrkbEn+vW1oyUJKCMSmp/QwUmB4DazTWxPxRJRaB/4A==
                -----END PUBLIC KEY-----
```

We will create the Policy using `Kubectl apply -f <file_name>`. Sample Output below.

```text
clusterpolicy.kyverno.io/verify-image created
```

Try running a signed test image as a deployment from the Amazon ECR repository:

```
kubectl run signed --image=<AWS Account ID>.dkr.ecr.us-east-1.amazonaws.com/supply-chain-security:latest
```

> Replace `AWS Account ID` with your AWS Account ID above

The Pod will be successfully created. 

```
pod/signed created
```

Try running an unsigned image that matches the configured rule:

```
kubectl run deployment unsigned --image=public.ecr.aws/b3u2a5x0/nginx:latest
```

It will be rejected due to signature mismatch. You should expect the below as an sample output for the above request.

```
Error from server: admission webhook "mutate.kyverno.svc-fail" denied the request: 

resource Pod/default/deployment was blocked due to the following policies 

verify-image:
  verify-image: |-
    failed to verify image public.ecr.aws/b3u2a5x0/nginx:latest: .attestors[0].entries[0].keys: no matching signatures:
    invalid signature when validating ASN.1 encoded signature
```


We will delete the KMS Keys. As we do not need it for the rest of the Labs.

```
aws kms delete-alias --alias-name "alias/image-signing-cosign"
```

We will also delete the ECR repository created in this lab.

```
aws ecr delete-repository --repository-name supply-chain-security --force
```

In this Lab, we outlined how to integrate Cosign with AWS KMS. Then we ensured supply chain security is maintained using Kyverno ImageVerify policy on an existing Amazon EKS cluster. Kyverno policy checks the signature of our ECR repository to ensure it has been signed by verifying its signature against the provided AWS KMS public key.
