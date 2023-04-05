---
title: Canary/Traffic Split
sidebar_position: 40
weight: 5
---

One of the *Retail Store*'s services is *ui*. At the time being, we only have one deployment version for the *ui* service. 

To practice this lab, you need to have mutiple deployment of a service, and you will do that with the *ui* service.

```bash
$ kubectl delete deployment ui -n ui
$ kubectl apply -n ui -f /manifests/ui/deployment-canary.yaml
```

```file
../manifests/ui/deployment-canary.yaml
```

Now you have three different versions for the ui service.

```bash
$ kubectl get deployment,pod -n ui
```
Output:
```bash
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ui-v1   1/1     1            1           4h6m
deployment.apps/ui-v2   1/1     1            1           4h5m
deployment.apps/ui-v3   1/1     1            1           81s

NAME                         READY   STATUS    RESTARTS   AGE
pod/ui-v1-5b476c4744-28ghv   2/2     Running   0          4h4m
pod/ui-v2-5b476c4744-q6sxx   2/2     Running   0          4h4m
pod/ui-v3-5b476c4744-ptw94   2/2     Running   0          81s
```

Now, you have the *ui* comes in three different pod versions, which are created from three separate deployments. All versions labeled with following labels, which are used with the selector of the *ui** service.

      app.kubernetes.io/component: service
      app.kubernetes.io/instance: ui
      app.kubernetes.io/name: ui

```bash
$ kubectl get pods -n ui -l app.kubernetes.io/name=ui
```
Output:
```bash
NAME                     READY   STATUS    RESTARTS   AGE
ui-v1-5b476c4744-28ghv   2/2     Running   0          4h12m
ui-v2-5b476c4744-q6sxx   2/2     Running   0          4h12m
ui-v3-5b476c4744-ptw94   2/2     Running   0          9m5s
```

As a result, when you hit the home page, kubernetes will just distribute traffic equally to all versions as you see in the output of the following loop command. 
```bash
$ for i in {1..6}; do curl -s $ISTIO_IG_HOSTNAME/home | grep "ui-v" & sleep 1; done
```

Output:
```bash
[1] 1926
          <div class="container" style="text-align: center">ui-v2-5b476c4744-q6sxx</div>
[1]+  Done                    curl -s $ISTIO_IG_HOSTNAME/home | grep --color=auto "ui-v"
[1] 2025
          <div class="container" style="text-align: center">ui-v2-5b476c4744-q6sxx</div>
[1]+  Done                    curl -s $ISTIO_IG_HOSTNAME/home | grep --color=auto "ui-v"
[1] 2030
          <div class="container" style="text-align: center">ui-v1-5b476c4744-28ghv</div>
[1]+  Done                    curl -s $ISTIO_IG_HOSTNAME/home | grep --color=auto "ui-v"
[1] 2040
          <div class="container" style="text-align: center">ui-v1-5b476c4744-28ghv</div>
[1]+  Done                    curl -s $ISTIO_IG_HOSTNAME/home | grep --color=auto "ui-v"
[1] 2095
          <div class="container" style="text-align: center">ui-v1-5b476c4744-28ghv</div>
[1]+  Done                    curl -s $ISTIO_IG_HOSTNAME/home | grep --color=auto "ui-v"
[1] 2113
          <div class="container" style="text-align: center">ui-v3-5b476c4744-ptw94</div>
[1]+  Done                    curl -s $ISTIO_IG_HOSTNAME/home | grep --color=auto "ui-v"
