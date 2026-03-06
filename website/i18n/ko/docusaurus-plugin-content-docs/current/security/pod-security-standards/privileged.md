---
title: "Privileged PSS 프로파일"
sidebar_position: 61
tmdTranslationSourceHash: '260e8ab341719985f9ce028e79bddcd1'
---

가장 허용적이며 알려진 권한 상승을 허용하는 Privileged 프로파일을 살펴보는 것으로 PSS를 시작하겠습니다.

Kubernetes 버전 1.23부터 기본적으로 모든 PSA 모드(즉, enforce, audit 및 warn)가 클러스터 수준에서 privileged PSS 프로파일에 대해 활성화됩니다. 즉, 기본적으로 PSA는 모든 네임스페이스에서 Privileged PSS 프로파일(즉, 제한이 없음)을 가진 Deployment 또는 Pod를 허용합니다. 이러한 기본 설정은 클러스터에 대한 영향을 줄이고 애플리케이션에 대한 부정적인 영향을 줄입니다. 앞으로 살펴보겠지만, Namespace 레이블을 사용하여 더 제한적인 설정을 선택할 수 있습니다.

기본적으로 `pss` 네임스페이스에 명시적으로 추가된 PSA 레이블이 없는지 확인할 수 있습니다:

```bash
$ kubectl describe ns pss
Name:         pss
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=pss
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

보시다시피 `pss` 네임스페이스에는 PSA 레이블이 첨부되어 있지 않습니다.

또한 `pss` 네임스페이스에서 현재 실행 중인 Deployment와 Pod를 확인해 보겠습니다.

```bash
$ kubectl -n pss get deployment
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
pss    1/1     1            1           5m24s
$ kubectl -n pss get pod
NAME                     READY   STATUS    RESTARTS   AGE
pss-ddb8f87dc-8z6l9    1/1     Running   0          5m24s
```

pss Pod의 YAML은 현재 보안 구성을 보여줍니다:

```bash
$ kubectl -n pss get deployment pss -o yaml | yq '.spec.template.spec'
containers:
  - image: public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.1
    imagePullPolicy: IfNotPresent
    name: pss
    ports:
      - containerPort: 80
        protocol: TCP
    resources: {}
    securityContext:
      readOnlyRootFilesystem: false
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
dnsPolicy: ClusterFirst
restartPolicy: Always
schedulerName: default-scheduler
securityContext: {}
terminationGracePeriodSeconds: 30
```

위의 Pod 보안 구성에서 Pod 수준의 `securityContext`는 nil입니다. 컨테이너 수준에서는 `securityContext`가 `readOnlyRootFilesystem`이 false로 설정되도록 구성되어 있습니다. Deployment와 Pod가 이미 실행 중이라는 사실은 PSA(기본적으로 Privileged PSS 프로파일로 구성됨)가 위의 Pod 보안 구성을 허용했음을 나타냅니다.

그러나 이 PSA가 허용하는 다른 보안 제어는 무엇일까요? 이를 확인하기 위해 위의 Pod 보안 구성에 더 많은 권한을 추가하고 `pss` 네임스페이스에서 PSA가 여전히 허용하는지 확인해 보겠습니다. 특히 Pod에 `privileged`와 `runAsUser:0` 플래그를 추가해 보겠습니다. 이는 모니터링 에이전트 및 서비스 메시 사이드카와 같이 일반적으로 필요한 워크로드에 대해 호스트 리소스에 액세스할 수 있음을 의미하며, `root` 사용자로 실행할 수 있도록 허용합니다:

```kustomization
modules/security/pss-psa/privileged-workload/deployment.yaml
Deployment/pss
```

Kustomize를 실행하여 위의 변경 사항을 적용하고 PSA가 위의 보안 권한으로 Pod를 허용하는지 확인합니다.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/privileged-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

`pss` 네임스페이스에서 위의 보안 권한으로 Deployment와 Pod가 다시 생성되었는지 확인해 보겠습니다

```bash
$ kubectl -n pss get pod
NAME                      READY   STATUS    RESTARTS   AGE
pss-64c49f848b-gmrtt      1/1     Running   0          9s

$ kubectl -n pss exec $(kubectl -n pss get pods -o name) -- whoami
root
```

이는 Privileged PSS 프로파일에 대해 활성화된 기본 PSA 모드가 허용적이며 필요한 경우 Pod가 상승된 보안 권한을 요청할 수 있도록 허용함을 보여줍니다.

위의 보안 권한은 Privileged PSS 프로파일에서 허용되는 제어의 전체 목록이 아닙니다. 각 PSS 프로파일에서 허용/불허되는 세부 보안 제어에 대해서는 [문서](https://kubernetes.io/docs/concepts/security/pod-security-standards/)를 참조하십시오.

