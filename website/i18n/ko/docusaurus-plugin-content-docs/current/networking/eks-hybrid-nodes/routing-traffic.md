---
title: "하이브리드 노드로 트래픽 라우팅"
sidebar_position: 10
sidebar_custom_props: { "module": false }
weight: 25 # used by test framework
tmdTranslationSourceHash: 6788556a7a4a9439c02c3c9fc4d89018
---

이제 하이브리드 노드 인스턴스가 클러스터에 연결되었으므로,
아래의 `Deployment` 및 `Ingress` 매니페스트를 사용하여 샘플 워크로드를
배포할 수 있습니다:

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kustomize/deployment.yaml" paths="spec.template.spec.affinity.nodeAffinity"}

1. `nodeAffinity` 규칙을 사용하여 Kubernetes 스케줄러에게 `eks.amazonaws.com/compute-type=hybrid` 레이블과 값을 가진 클러스터 노드를 _선호_하도록 지시합니다.

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kustomize/ingress.yaml" paths="spec.ingressClassName"}

1. `ingress` 리소스는 워크로드 Pod로 트래픽을 라우팅하도록 AWS Load Balancer (ALB)를 구성합니다.

워크로드를 배포해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize
namespace/nginx-remote created
service/nginx created
deployment.apps/nginx created
ingress.networking.k8s.io/nginx created
```

Pod가 하이브리드 노드에 성공적으로 스케줄링되었는지 확인해 보겠습니다:

```bash
$ kubectl get pods -n nginx-remote -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName'
NAME                     NODE
nginx-787d665f9b-2bcms   mi-027504c0970455ba5
nginx-787d665f9b-hgrnp   mi-027504c0970455ba5
nginx-787d665f9b-kv4x9   mi-027504c0970455ba5
```

좋습니다! 세 개의 nginx Pod가 예상대로 하이브리드 노드에서 실행되고 있습니다.

:::tip
ALB 프로비저닝에는 몇 분이 걸릴 수 있습니다. 계속하기 전에 다음 명령으로 로드 밸런서 프로비저닝이 완료되었는지 확인하세요:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-nginxrem-nginx`) == `true`]' --query 'LoadBalancers[0].State.Code'
"active"
```

:::

ALB가 활성화되면 Ingress와 연결된 `Address`를 확인하여 ALB의 URL을 가져올 수 있습니다:

```bash
$ export ADDRESS=$(kubectl get ingress -n nginx-remote nginx -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}") && echo $ADDRESS
k8s-nginxrem-nginx-03efa1e84c-012345678.us-west-2.elb.amazonaws.com
```

ALB URL을 통해 명령줄이나 웹 브라우저에 주소를 입력하여 배포에 액세스할 수 있습니다. ALB는 Ingress 규칙에 따라 적절한 Pod로 트래픽을 라우팅합니다.

```bash test=false
$ curl $ADDRESS
Connected to 10.53.0.5 on mi-027504c0970455ba5
```

curl 또는 브라우저의 출력에서 `mi-` 접두사가 있는 하이브리드 노드에서 실행 중인 로드 밸런서로부터 요청을 받는 Pod의 `10.53.0.X` IP 주소를 확인할 수 있습니다.

curl 명령을 다시 실행하거나 브라우저를 몇 번 새로고침하면 각 요청에서 Pod IP가 변경되고 노드 이름은 동일하게 유지되는 것을 확인할 수 있습니다. 모든 Pod가 동일한 원격 노드에 스케줄링되어 있기 때문입니다.

```bash test=false
$ curl -s $ADDRESS
Connected to 10.53.0.5 on mi-027504c0970455ba5
$ curl -s $ADDRESS
Connected to 10.53.0.11 on mi-027504c0970455ba5
$ curl -s $ADDRESS
Connected to 10.53.0.84 on mi-027504c0970455ba5
```

하이브리드 노드에 워크로드를 성공적으로 배포하고, ALB를 통해 액세스하도록 구성했으며, 트래픽이 원격 노드에서 실행 중인 Pod로 올바르게 라우팅되고 있음을 확인했습니다.

EKS Hybrid Nodes로 더 많은 사용 사례를 살펴보기 전에 약간의 정리를 해보겠습니다.

```bash timeout=300 wait=30
$ kubectl delete -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize --ignore-not-found=true
```

