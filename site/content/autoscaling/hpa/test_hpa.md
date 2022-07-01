---
title: "Scale an Application with HPA"
weight: 20
---

## Deploy a Sample App

We will deploy an application and expose as a service on TCP port 80.

The application is a custom-built image based on the php-apache image. The index.php page performs calculations to generate CPU load. More information can be found [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/#run-expose-php-apache-server)

```bash
kubectl create deployment php-apache --image=us.gcr.io/k8s-artifacts-prod/hpa-example
kubectl set resources deploy php-apache --requests=cpu=200m
kubectl expose deploy php-apache --port 80

kubectl get pod -l app=php-apache

```

## Create an HPA resource

This HPA scales up when CPU exceeds 50% of the allocated container resource.

```bash
kubectl autoscale deployment php-apache `#The target average CPU utilization` \
    --cpu-percent=50 \
    --min=1 `#The lower limit for the number of pods that can be set by the autoscaler` \
    --max=10 `#The upper limit for the number of pods that can be set by the autoscaler`
```

View the HPA using kubectl. You probably will see `<unknown>/50%` for 1-2 minutes and then you should be able to see `0%/50%`

```bash
kubectl get hpa
```

The output is similar to:

{{< output >}}
NAME         REFERENCE               TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   <unknown>/50%   1         10        0          6s
{{< /output >}}

## Generate load to trigger scaling

```bash
kubectl run load-generator --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

Watch the HPA with the following command

```bash
kubectl get hpa php-apache --watch
```

You will see HPA scale the pods from 1 up to our configured maximum (10) until the CPU average is below our target (50%)

![Scale Up](/images/scaling-hpa-results.png)

You can now stop (_Ctrl + C_) load test that was running in the other terminal. You will notice that HPA will slowly bring the replica count to min number based on its configuration. You should also get out of load testing application by pressing _Ctrl + D_.
