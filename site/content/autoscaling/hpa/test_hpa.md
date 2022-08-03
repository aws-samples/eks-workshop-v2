---
title: "Scale an Application with HPA"
weight: 20
---

## Deploy a Sample App

We will deploy an application and expose as a service on TCP port 80.

The application is a custom-built image based on the php-apache image. The index.php page performs calculations to generate CPU load. More information can be found [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/#run-expose-php-apache-server)

```bash timeout=120
kubectl create deployment php-apache --image=us.gcr.io/k8s-artifacts-prod/hpa-example
kubectl wait --for=condition=available --timeout=60s deployment/php-apache

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

```bash hook=hpa-pod-scaleout
kubectl run load-generator --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

Watch the HPA with the following command

```bash test=false
kubectl get hpa php-apache --watch
```

You will see HPA scale the pods from 1 up to our configured maximum (10) until the CPU average is below our target (50%)

{{< output >}}
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%    1         10        1          27s
php-apache   Deployment/php-apache   139%/50%   1         10        1          45s
php-apache   Deployment/php-apache   435%/50%   1         10        3          60s
php-apache   Deployment/php-apache   273%/50%   1         10        6          75s
php-apache   Deployment/php-apache   116%/50%   1         10        9          90s
php-apache   Deployment/php-apache   74%/50%    1         10        9          105s
php-apache   Deployment/php-apache   86%/50%    1         10        9          2m
php-apache   Deployment/php-apache   91%/50%    1         10        9          2m16s
php-apache   Deployment/php-apache   71%/50%    1         10        9          2m31s
php-apache   Deployment/php-apache   64%/50%    1         10        9          2m46s
php-apache   Deployment/php-apache   59%/50%    1         10        9          3m1s
php-apache   Deployment/php-apache   63%/50%    1         10        9          3m16s
php-apache   Deployment/php-apache   59%/50%    1         10        9          3m31s
php-apache   Deployment/php-apache   44%/50%    1         10        9          3m46s
php-apache   Deployment/php-apache   44%/50%    1         10        9          4m1s
php-apache   Deployment/php-apache   50%/50%    1         10        9          4m16s
php-apache   Deployment/php-apache   47%/50%    1         10        9          4m31s
php-apache   Deployment/php-apache   48%/50%    1         10        9          4m46s
php-apache   Deployment/php-apache   45%/50%    1         10        9          5m1s
{{< /output >}}

## Stop the load test

```bash timeout=180
kubectl delete pod load-generator
```

Once the load generator is stopped, you will notice that HPA will slowly bring the replica count to min number based on its configuration. 
