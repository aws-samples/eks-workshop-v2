---
title: Fargate에서 스케줄링
sidebar_position: 12
---
그렇다면 왜 `checkout` 서비스가 이미 Fargate에서 실행되고 있지 않을까요? 레이블을 확인해 봅시다:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq '.items[0].metadata.labels'
```

Looks like our Pod is missing the label `fargate=yes`, so lets fix that by updating the deployment for that service so the Pod spec includes the label needed for the profile to schedule it on Fargate.

```kustomization
modules/fundamentals/fargate/enabling/deployment.yaml
Deployment/checkout
```

kustomization을 클러스터에 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/enabling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

이로 인해 `checkout` 서비스의 Pod 스펙이 업데이트되고 새로운 배포가 트리거되어 모든 Pod가 교체될 것입니다. 새로운 Pod가 스케줄링될 때, Fargate 스케줄러는 kustomization에 의해 적용된 새 레이블을 우리의 대상 프로필과 매칭하고 개입하여 우리의 Pod가 Fargate가 관리하는 용량에서 스케줄링되도록 할 것입니다.

이것이 작동했는지 어떻게 확인할 수 있을까요? 새로 생성된 Pod를 설명하고 `Events` 섹션을 살펴봅시다:

```bash
$ kubectl describe pod -n checkout -l fargate=yes
[...]
Events:
  Type     Reason           Age    From               Message
  ----     ------           ----   ----               -------
  Warning  LoggingDisabled  10m    fargate-scheduler  Disabled logging because aws-logging configmap was not found. configmap "aws-logging" not found
  Normal   Scheduled        9m48s  fargate-scheduler  Successfully assigned checkout/checkout-78fbb666b-fftl5 to fargate-ip-10-42-11-96.us-west-2.compute.internal
  Normal   Pulling          9m48s  kubelet            Pulling image "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.4.0"
  Normal   Pulled           9m5s   kubelet            Successfully pulled image "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.4.0" in 43.258137629s
  Normal   Created          9m5s   kubelet            Created container checkout
  Normal   Started          9m4s   kubelet            Started container checkout
```

`fargate-scheduler`의 이벤트는 무슨 일이 일어났는지에 대한 통찰력을 제공합니다. 이 실습 단계에서 우리가 주로 관심을 가져야 할 항목은 이유가 `Scheduled`인 이벤트입니다. 이를 자세히 살펴보면 이 Pod를 위해 프로비저닝된 Fargate 인스턴스의 이름을 알 수 있습니다. 위의 예에서는 `fargate-ip-10-42-11-96.us-west-2.compute.internal`입니다.

`kubectl`을 사용하여 이 노드를 검사하면 이 Pod에 대해 프로비저닝된 컴퓨팅에 대한 추가 정보를 얻을 수 있습니다:

```bash
$ NODE_NAME=$(kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].spec.nodeName')
$ kubectl describe node $NODE_NAME
Name:               fargate-ip-10-42-11-96.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/compute-type=fargate
                    failure-domain.beta.kubernetes.io/region=us-west-2
                    failure-domain.beta.kubernetes.io/zone=us-west-2b
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-42-11-96.us-west-2.compute.internal
                    kubernetes.io/os=linux
                    topology.kubernetes.io/region=us-west-2
                    topology.kubernetes.io/zone=us-west-2b
[...]
이는 기본 컴퓨팅 인스턴스의 특성에 대한 여러 가지 통찰력을 제공합니다:

* `eks.amazonaws.com/compute-type` 레이블은 Fargate 인스턴스가 프로비저닝되었음을 확인합니다
* 또 다른 레이블인 `topology.kubernetes.io/zone`은 pod가 실행 중인 가용 영역을 지정합니다
* `System Info` 섹션(위에 표시되지 않음)에서 인스턴스가 Amazon Linux 2를 실행 중이며, `container`, `kubelet`, `kube-proxy`와 같은 시스템 컴포넌트의 버전 정보도 볼 수 있습니다
