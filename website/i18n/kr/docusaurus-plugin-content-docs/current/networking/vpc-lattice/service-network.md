---
title: "Service network"
sidebar_position: 20
---

The Gateway API controller has been configured to create a VPC Lattice service network and associate a Kubernetes cluster VPC with it automatically. A service network is a logical boundary that’s used to automatically implement service discovery and connectivity as well as apply access and observability policies to a collection of services. It offers inter-application connectivity over HTTP, HTTPS, and gRPC protocols within a VPC. As of today, the controller supports HTTP and HTTPS.

Before creating a `Gateway`, we need to formalize the types of load balancing implementations that are available via the Kubernetes resource model with a [GatewayClass](https://gateway-api.sigs.k8s.io/concepts/api-overview/#gatewayclass). The controller that listens to the Gateway API relies on an associated `GatewayClass` resource that the user can reference from their `Gateway`:

```file
manifests/modules/networking/vpc-lattice/controller/gatewayclass.yaml
```

Lets create the `GatewayClass`:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/gatewayclass.yaml
```

The following YAML will create a Kubernetes `Gateway` resource which is associated with a VPC Lattice **Service Network**.

```file
manifests/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml
```

Apply it with the following command:

```bash
$ cat ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml \
  | envsubst | kubectl apply -f -
```

Verify that `eks-workshop` gateway is created:

```bash
$ kubectl get gateway -n checkout
NAME                CLASS                ADDRESS   PROGRAMMED   AGE
eks-workshop        amazon-vpc-lattice             True         29s
```

Once the gateway is created, find the VPC Lattice service network. Wait until the status is `Reconciled` (this could take about five minutes).

```bash
$ kubectl describe gateway ${EKS_CLUSTER_NAME} -n checkout
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
status:
   conditions:
      message: 'aws-gateway-arn: arn:aws:vpc-lattice:us-west-2:1234567890:servicenetwork/sn-03015ffef38fdc005'
      reason: Programmed
      status: "True"

$ kubectl wait --for=condition=Programmed gateway/${EKS_CLUSTER_NAME} -n checkout
```

Now you can see the associated **Service Network** created in the VPC console under the Lattice resources in the [AWS console](https://console.aws.amazon.com/vpc/home#ServiceNetworks).

![Checkout Service Network](assets/servicenetwork.webp)
