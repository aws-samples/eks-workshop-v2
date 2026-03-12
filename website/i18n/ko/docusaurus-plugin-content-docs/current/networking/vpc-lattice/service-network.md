---
title: "Service network"
sidebar_position: 20
tmdTranslationSourceHash: '77a0c2e01a564b5ed3915581bc649046'
---

Gateway API 컨트롤러는 VPC Lattice 서비스 네트워크를 자동으로 생성하고 Kubernetes 클러스터 VPC를 연결하도록 구성되었습니다. 서비스 네트워크는 서비스 검색 및 연결성을 자동으로 구현하고, 서비스 컬렉션에 액세스 및 관측 가능성 정책을 적용하는 데 사용되는 논리적 경계입니다. VPC 내에서 HTTP, HTTPS 및 gRPC 프로토콜을 통한 애플리케이션 간 연결성을 제공합니다. 현재 컨트롤러는 HTTP 및 HTTPS를 지원합니다.

`Gateway`를 생성하기 전에, Kubernetes 리소스 모델을 통해 사용 가능한 로드 밸런싱 구현 유형을 [GatewayClass](https://gateway-api.sigs.k8s.io/concepts/api-overview/#gatewayclass)로 공식화해야 합니다. Gateway API를 수신하는 컨트롤러는 사용자가 자신의 `Gateway`에서 참조할 수 있는 연결된 `GatewayClass` 리소스에 의존합니다:

::yaml{file="manifests/modules/networking/vpc-lattice/controller/gatewayclass.yaml" paths="metadata.name,spec.controllerName"}

1. `GatewayClass` 이름을 `amazon-vpc-lattice`로 설정하여 `Gateway` 리소스에서 참조할 수 있도록 합니다
2. `controllerName`을 `application-networking.k8s.aws/gateway-api-controller`로 설정하여 이 클래스의 게이트웨이를 관리하는 AWS Gateway API 컨트롤러를 지정합니다

`GatewayClass`를 생성해 보겠습니다:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/gatewayclass.yaml
```

다음 YAML은 VPC Lattice **Service Network**와 연결된 Kubernetes `Gateway` 리소스를 생성합니다.

::yaml{file="manifests/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml" paths="metadata.name,spec.gatewayClassName,spec.listeners.0"}

1. `metadata.name`을 `EKS_CLUSTER_NAME` 환경 변수로 설정하여 Gateway 식별자를 EKS 클러스터 이름으로 설정합니다
2. `gatewayClassName`을 `amazon-vpc-lattice`로 설정하여 앞서 정의한 VPC Lattice GatewayClass를 참조합니다
3. 이 구성은 `listener`가 포트 `80`에서 `HTTP` 트래픽을 수신하도록 지정합니다

다음 명령어로 적용합니다:

```bash
$ cat ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml \
  | envsubst | kubectl apply -f -
```

`eks-workshop` 게이트웨이가 생성되었는지 확인합니다:

```bash
$ kubectl get gateway -n checkout
NAME                CLASS                ADDRESS   PROGRAMMED   AGE
eks-workshop        amazon-vpc-lattice             True         29s
```

게이트웨이가 생성되면 VPC Lattice 서비스 네트워크를 찾습니다. 상태가 `Reconciled`가 될 때까지 기다립니다(약 5분 정도 걸릴 수 있습니다).

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

이제 [AWS 콘솔](https://console.aws.amazon.com/vpc/home#ServiceNetworks)의 Lattice 리소스 아래 VPC 콘솔에서 연결된 **Service Network**가 생성된 것을 확인할 수 있습니다.

![Checkout Service Network](/docs/networking/vpc-lattice/servicenetwork.webp)

