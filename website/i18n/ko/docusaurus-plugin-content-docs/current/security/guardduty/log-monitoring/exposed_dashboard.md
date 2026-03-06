---
title: "노출된 Kubernetes 대시보드"
sidebar_position: 523
tmdTranslationSourceHash: 'bf5de5c93b37a21ed7af7bdbc6a9f938'
---

이 결과는 EKS 클러스터 대시보드가 Load Balancer 서비스에 의해 인터넷에 노출되었음을 알려줍니다. 노출된 대시보드는 클러스터의 관리 인터페이스를 인터넷에서 공개적으로 액세스할 수 있게 만들며, 존재할 수 있는 인증 및 액세스 제어 격차를 악의적인 행위자가 악용할 수 있도록 허용합니다.

이를 시뮬레이션하기 위해 Kubernetes 대시보드 컴포넌트를 설치해야 합니다. [릴리스 노트](https://github.com/kubernetes/dashboard/releases/tag/v2.7.0)에 따라 EKS 클러스터 vVAR::KUBERNETES_VERSION과 호환되는 최신 버전인 대시보드 버전 v2.7.0을 사용할 것입니다.
그 후 Service 타입 `LoadBalancer`를 사용하여 대시보드를 인터넷에 노출할 수 있으며, 이는 AWS 계정에 Network Load Balancer(NLB)를 생성합니다.

다음 명령을 실행하여 Kubernetes 대시보드 컴포넌트를 설치하세요. 이렇게 하면 `kubernetes-dashboard`라는 새 Namespace가 생성되고 모든 리소스가 그곳에 배포됩니다.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
$ kubectl -n kubernetes-dashboard rollout status deployment/kubernetes-dashboard
$ kubectl -n kubernetes-dashboard get pods
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-64bcc67c9c-tt9vl   1/1     Running   0          66s
kubernetes-dashboard-5c8bd6b59-945zj         1/1     Running   0          66s
```

이제 새로 생성된 `kubernetes-dashboard` Service를 `LoadBalancer` 타입으로 패치해 보겠습니다.

```bash
$ kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p='{"spec": {"type": "LoadBalancer"}}'
```

몇 분 후 NLB가 생성되고 `kubernetes-dashboard` Service에 공개적으로 액세스 가능한 주소가 표시됩니다.

```bash
$ kubectl -n kubernetes-dashboard get svc
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP      172.20.8.169     <none>                                                                    8000/TCP        3m
kubernetes-dashboard        LoadBalancer   172.20.218.132   ad0fbc5914a2c4d1baa8dcc32101196b-2094501166.us-west-2.elb.amazonaws.com   443:32762/TCP   3m1s
```

[GuardDuty Findings 콘솔](https://console.aws.amazon.com/guardduty/home#/findings)로 돌아가면 `Policy:Kubernetes/ExposedDashboard` 결과를 볼 수 있습니다. 다시 한 번 시간을 내어 결과 세부 정보, 조치 및 Detective 조사를 분석하세요.

![Exposed dashboard finding](/docs/security/guardduty/log-monitoring/exposed-dashboard.webp)

다음 명령을 실행하여 Kubernetes 대시보드 컴포넌트를 제거하세요:

```bash
$ kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

